# Recovery Notes

## 복구 원칙

1. 복구 기록과 과거 합성 로그에서 확인되는 6-state 개발 구현은 `recovered_6state`에 보존합니다.
2. 최종 학술대회 논문이 명시한 4-state FSM은 `refined_4state`에 구현합니다.
3. 두 버전은 공통 데이터패스를 사용하되 제어 흐름과 결과 출처를 섞지 않습니다.
4. 원문 전체 소스가 확인되지 않은 값은 원본 복구로 꾸미지 않고 기능 재구성 항목으로 표시합니다.
5. 논문 보고값, 과거 합성 로그와 현재 regression 결과는 서로 다른 조건의 결과로 분리합니다.

## 검토한 최종 산출물

- `2025 추계학술대회 논문_이승열.hwp`
- `2025 추계학술대회 논문_이승열-수정 (2).hwp.pdf`
- `이승열-포스터.pptx`

최종 PDF와 포스터는 4-state FSM, 세 UN의 병렬 구조, 네 가지 Logic case, Artix-7 합성 표와 트리 레벨별 cycle 결과를 공통으로 설명합니다. 세부 근거와 수치 계산은 [`paper-reference.md`](paper-reference.md)에 정리했습니다.

## 논문에서 직접 확인된 내용

- 논문 제목: `병렬 구조 기반 결정트리 하드웨어 설계 및 분석`
- 영문 제목: `Parallel Decision Tree Hardware Design and Analysis`
- 학술대회: 2025 한국스마트미디어학회 추계학술대회
- 한 입력 벡터에 대해 UN1~UN3이 현재 노드와 좌·우 자식 노드를 병렬 계산합니다.
- 세 UN은 공통 I-Memory와 하나의 외부 AD-Memory를 공유합니다.
- 각 UN은 A-Memory, C-Memory, 비교 연산부(M2), Decision 기능을 포함합니다.
- Logic은 node/leaf 조합의 네 가지 case를 처리합니다.
- 논문 상태 코드는 `001 LOAD → 010 COMPARE → 011 DECISION → 100 DONE`입니다.
- Xilinx Artix-7 합성 결과는 13.10 ns 주기에서 WNS > 0을 보고합니다.
- 논문 표의 cycle 결과는 LV2 `6→4`, LV3 `9→8`, LV4 `12→8`, 평균 speedup `1.37×`입니다.

## 복구 기록에서 직접 확인된 내용

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
- Logic은 `UN1_direction=0`일 때 UN2, `1`일 때 UN3 결과를 선택합니다.
- 최종 Logic 수정본은 `class != INVALID_CLASS`로 leaf 해결 여부를 판정합니다.
- 테스트 트리의 내부 노드는 `0,1,2,3,5,6,7,12`입니다.
- 과거 Vivado 합성 기록에는 `Controller.state`가 six-state one-hot으로 인코딩된 로그가 있습니다.

따라서 이 저장소는 6-state를 논문의 명시된 FSM이라고 부르지 않습니다. 6-state는 복구 근거에 남은 개발 구현, 4-state는 최종 논문 명세를 반영한 구현으로 구분합니다.

## 기능 동등 복구로 재구성한 내용

원문 코드 블록과 메모리 초기화 전체는 대화 검색에서 그대로 추출되지 않았습니다. 따라서 다음 항목은 구조 검증을 위해 재구성했습니다.

- AD-Memory의 자식 연결:
  - `0→(1,2)`, `1→(3,4)`, `2→(5,6)`, `3→(7,8)`
  - `5→(9,10)`, `6→(11,12)`, `7→(13,14)`, `12→(15,16)`
- A-Memory는 각 내부 노드에서 한 특성만 비교하는 one-hot Q4.4 계수를 사용합니다.
- C-Memory class map은 `2'b11`을 invalid 값으로 예약하고 class 0~2를 사용합니다.
- I-Memory의 37개 벡터는 아홉 leaf 경로를 반복해서 모두 검증하도록 구성했습니다.
- 6-state 상태 역할 중 `IDLE`과 `ADVANCE`는 과거 파형 설명(`100 DONE` 다음 `101`, 배치 중에는 `001`로 복귀)을 기준으로 복원했습니다.

이 재구성 값들은 원 논문의 학습 데이터 정확도나 기존 합성 수치를 재현하기 위한 데이터가 아닙니다. 병렬 탐색 제어, leaf/node 판정, batch 진행, 6-state/4-state 기능 동등성을 재검증하기 위한 회귀 데이터입니다.

## 상태별 완료 기준

### Recovered 6-state

`done`은 DECIDE에서 class가 확정되는 상승 에지에 설정되며, 출력 파형상 `state=100 (DONE)`인 한 클록 동안 유효합니다. `101 (ADVANCE)`은 결과 계산 시간이 아니라 다음 벡터 준비/배치 종료 상태입니다.

### Paper-aligned 4-state

`done`은 DECISION에서 class가 확정되는 상승 에지에 설정되며, `state=100 (DONE)` 동안 유효합니다. 다음 벡터 진행과 종료 판정을 DONE에 통합하여 별도 ADVANCE 상태를 제거했습니다.

## 결과 출처 구분

| 출처 | LUT | FF | 주기/타이밍 | 의미 |
|---|---:|---:|---|---|
| 과거 Vivado post-synthesis 로그 | 3,120 | 2,526 | 10 ns target, WNS -3.083 ns | 개발 중간 기록 |
| 최종 논문 표 | 2,884 | 2,516 | 13.10 ns, WNS > 0 | 병렬 UN3 논문 보고값 |
| 현재 repository regression | - | - | 293→255 batch cycles | 복구 RTL의 기능·cycle 비교 |

세 결과는 수정 시점, 입력과 검증 도구가 다르므로 직접적인 재현 관계를 주장하지 않습니다.
