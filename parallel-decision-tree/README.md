# Parallel Decision Tree Hardware

FPGA에서 현재 노드(UN1)와 두 자식 노드(UN2, UN3)를 병렬 계산하는 결정트리 분류기입니다. 학술대회 당시 사용한 6-state RTL의 기능 동등 복구본과, 논문에 기술한 상태 흐름으로 정리한 refined 4-state RTL을 함께 제공합니다.

> 이 저장소는 잃어버린 소스의 바이트 단위 원본이 아닙니다. 채팅 기록, 최종 논문, 합성 결과에서 확인된 구조를 기준으로 재구성한 검증 가능한 복구본입니다. 원문으로 확인된 내용과 재구성된 메모리 값은 [`docs/recovery-notes.md`](docs/recovery-notes.md)에 구분했습니다.

## 핵심 구조

- 하나의 `I_Memory_ext`가 동일한 입력 벡터를 UN1~UN3에 공급합니다.
- 하나의 `ad_ro`가 현재 노드와 두 자식 노드의 주소를 동시에 읽습니다.
- UN1은 현재 노드, UN2와 UN3은 좌·우 자식 노드를 병렬 계산합니다.
- `logic_param_prefetch`는 UN1의 방향에 따라 UN2 또는 UN3 결과만 선택합니다.
- 선택 결과가 leaf이면 class를 출력하고, node이면 그 주소로 다음 병렬 탐색을 반복합니다.

## 디렉터리

```text
parallel-decision-tree/
├── rtl/
│   ├── common/
│   │   ├── I_Memory_ext.v
│   │   ├── ad_ro.v
│   │   ├── decision_tree.v
│   │   └── logic_param_prefetch.v
│   ├── recovered_6state/
│   │   └── top_prefetch_un3.v
│   └── refined_4state/
│       └── top_prefetch_un3_4state.v
├── tb/
│   ├── tb_top_prefetch_depth4_scenario.v
│   └── tb_refined_4state_equivalence.v
├── scripts/run_iverilog.sh
└── docs/recovery-notes.md
```

## FSM 비교

| 버전 | 상태 | 역할 |
|---|---|---|
| Recovered 6-state | `000 IDLE` | 시작 대기 |
|  | `001 LOAD` | 벡터와 루트 노드 준비 |
|  | `010 PREFETCH` | UN1~UN3 결과 동기화 |
|  | `011 DECIDE` | Logic에서 class/next node 선택 |
|  | `100 DONE` | 한 벡터의 결과 유효 구간 |
|  | `101 ADVANCE` | 다음 벡터로 이동 또는 배치 종료 |
| Refined 4-state | `001 LOAD` | 대기 및 벡터 준비 |
|  | `010 COMPARE` | UN1~UN3 병렬 계산과 결과 동기화 |
|  | `011 DECISION` | class/next node 선택 |
|  | `100 DONE` | 결과 확정 및 다음 벡터 제어 |

4-state 버전은 `active` 플래그로 LOAD 상태의 대기/실행 여부를 구분합니다. 별도의 숨은 FSM 상태는 없습니다.

## 테스트

Icarus Verilog가 설치된 Linux 환경에서 다음 명령을 실행합니다.

```bash
bash parallel-decision-tree/scripts/run_iverilog.sh
```

테스트 항목:

1. `tb_top_prefetch_depth4_scenario`
   - 37개 입력 벡터 분류
   - 예상 class 일치 확인
   - `done`이 반드시 `state=100`에서만 발생하는지 확인
2. `tb_refined_4state_equivalence`
   - 6-state와 4-state의 37개 결과 전수 비교
   - 4-state 배치 완료 사이클이 6-state보다 감소했는지 확인

GitHub Actions에서도 같은 회귀 테스트를 자동 실행합니다.

## 논문에서 보고한 결과

최종 논문 표에 기록된 값이며, 이 복구 RTL을 새로 합성한 결과와 혼동하지 않습니다.

| 항목 | 단일 UN | 병렬 UN3 |
|---|---:|---:|
| LUT | 1,247 | 2,884 |
| FF | 2,309 | 2,516 |
| 동작 주기 | 13.10 ns | 13.10 ns |
| Power | 0.084 W | 0.229 W |

트리 레벨별 보고 사이클은 LV2 `6→4`, LV3 `9→8`, LV4 `12→8`이며 평균 실행시간 개선은 1.37배, 최대 단축은 50%입니다.

## 합성 기준

- Vivado 2023.2
- Xilinx Artix-7 `xc7a35tcpg236-1`
- 당시 목표 클록 10 ns (100 MHz)

과거 post-synthesis 기록에는 WNS `-3.083 ns`, TNS `-36.841 ns`, WHS `+0.142 ns`, WPWS `+3.750 ns`가 남아 있습니다. 이는 타이밍 최적화 전 기록으로 보존하며, timing met을 주장하지 않습니다.
