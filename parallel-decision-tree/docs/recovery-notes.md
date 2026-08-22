# Recovery Notes

## 복구 원칙

1. 학술대회 당시 실제 동작한 6-state 구조는 `recovered_6state`에 보존합니다.
2. 논문에 적힌 네 상태만 사용하는 구조는 `refined_4state`로 분리합니다.
3. 폐기된 중간 top은 섞지 않습니다.
4. 원문 전체 소스가 확인되지 않은 값은 복구 사실처럼 꾸미지 않고 재구성 항목으로 표시합니다.

## 기록에서 직접 확인된 내용

- 원본 구성 파일명:
  - `top_prefetch_un3.v`
  - `I_Memory_ext.v`
  - `ad_ro.v`
  - `decision_tree.v`
  - `logic_param_prefetch.v`
  - `tb_top_prefetch_depth4_scenario.v`
- 주요 파라미터:
  - `ATTR_NUM=4`
  - `ATTR_NUM_ENC=2`
  - `WORD_LEN=8`
  - `ND_NUM_ENC=5`
  - `CLASS_ENC=2`
  - `MAX_ND=32`
  - `ADDER_TREE_DEPTH=2`
  - `STATE_ENC=3`
  - `IN_NUM_ENC=6`
  - `IN_NUM=37`
  - `FRAC_BITS=4`
- 세 UN은 외부 I-Memory의 동일 벡터와 하나의 공유 AD-Memory를 사용합니다.
- Logic은 `UN1_direction=0`일 때 UN2, `1`일 때 UN3 결과를 선택합니다.
- 최종 Logic 수정본은 `class != INVALID_CLASS`로 leaf 해결 여부를 판정합니다.
- 테스트 트리의 내부 노드는 `0,1,2,3,5,6,7,12`입니다.
- 6-state RTL은 Vivado 합성 시 `Controller.state`가 six-state one-hot으로 인코딩된 기록이 있습니다.
- 논문에 적힌 상태 코드는 `001(load) → 010(compare) → 011(decision) → 100(done)`입니다.

## 기능 동등 복구로 재구성한 내용

원문 코드 블록과 메모리 초기화 전체는 대화 검색에서 그대로 추출되지 않았습니다. 따라서 다음 항목은 구조 검증을 위해 재구성했습니다.

- AD-Memory의 자식 연결:
  - `0→(1,2)`, `1→(3,4)`, `2→(5,6)`, `3→(7,8)`
  - `5→(9,10)`, `6→(11,12)`, `7→(13,14)`, `12→(15,16)`
- A-Memory는 각 내부 노드에서 한 특성만 비교하는 one-hot Q4.4 계수를 사용합니다.
- C-Memory class map은 `2'b11`을 invalid 값으로 예약하고 class 0~2를 사용합니다.
- I-Memory의 37개 벡터는 아홉 leaf 경로를 반복해서 모두 검증하도록 구성했습니다.
- 6-state 상태 역할 중 `IDLE`과 `ADVANCE`는 당시 파형 설명(`100 done` 다음 `101`, 배치 중에는 `001`로 복귀)을 기준으로 복원했습니다.

이 재구성 값들은 원 논문의 학습 데이터 정확도나 기존 합성 수치를 재현하기 위한 데이터가 아닙니다. 병렬 탐색 제어, leaf/node 판정, batch 진행, 6-state/4-state 기능 동등성을 재검증하기 위한 회귀 데이터입니다.

## 상태별 완료 기준

### Recovered 6-state

`done`은 DECIDE에서 class가 확정되는 상승 에지에 설정되며, 출력 파형상 `state=100(DONE)`인 한 클록 동안 유효합니다. `101(ADVANCE)`은 결과 계산 시간이 아니라 다음 벡터 준비/배치 종료 상태입니다.

### Refined 4-state

`done`은 DECISION에서 class가 확정되는 상승 에지에 설정되며, `state=100(DONE)` 동안 유효합니다. 다음 벡터 진행과 종료 판정을 DONE에 통합하여 별도 ADVANCE 상태를 제거했습니다.

## 과거 합성 기록의 두 수치 집합

대화의 post-synthesis 로그와 최종 논문 표는 실행 조건/수정 시점이 달라 값이 일치하지 않습니다.

| 출처 | LUT | FF | 주기/타이밍 |
|---|---:|---:|---|
| Vivado post-synthesis 대화 로그 | 3,120 | 2,526 | 10 ns 목표, WNS -3.083 ns |
| 최종 논문 표 | 2,884 | 2,516 | 13.10 ns |

두 기록은 그대로 병기하며 어느 한쪽을 새 복구본의 합성 결과라고 주장하지 않습니다.
