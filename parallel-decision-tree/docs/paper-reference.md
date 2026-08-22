# Paper Reference

## Publication

- **Korean title:** 병렬 구조 기반 결정트리 하드웨어 설계 및 분석
- **English title:** Parallel Decision Tree Hardware Design and Analysis
- **Authors:** SeungYeol Lee, Chung-Soo Lim
- **Venue:** 2025 한국스마트미디어학회 추계학술대회
- **Target:** Xilinx Artix-7 FPGA

## Reviewed Source Material

- Final two-page conference paper PDF
- HWP manuscript
- Eight-slide poster presentation

The source files were reviewed to document the paper specification and are not redistributed in this repository.

## Proposed Architecture

The work parallelizes the traversal of a **single input vector**, rather than only processing multiple vectors in parallel.

1. UN1 evaluates the current parent node.
2. UN2 and UN3 speculatively evaluate the left and right child nodes.
3. Logic uses the UN1 branch direction and the child node/leaf types to select the next node or class.
4. Shared I-Memory and AD-Memory reduce duplicated data and keep the three UNs aligned.

Each Universal Node includes attribute/threshold storage, child-class information, comparison logic and decision logic.

## Paper-Specified FSM

```text
001 LOAD → 010 COMPARE → 011 DECISION → 100 DONE
```

The final paper and poster both present this four-state flow. The repository's `refined_4state` implementation follows this specification. The separately preserved `recovered_6state` implementation is identified as a development/recovery version, not as the paper-specified FSM.

## Four Logic Cases

| Case | Left Child | Right Child | Behavior |
|---:|---|---|---|
| 1 | Node | Node | Continue with the selected child node |
| 2 | Node | Leaf | Select next node or class by direction |
| 3 | Leaf | Node | Select class or next node by direction |
| 4 | Leaf | Leaf | Select class and finish traversal |

## Paper-Reported Synthesis Results

| Metric | Single UN | Parallel UN3 | Ratio |
|---|---:|---:|---:|
| LUT | 1,247 | 2,884 | 2.31× |
| FF | 2,309 | 2,516 | 1.09× |
| Clock period | 13.10 ns | 13.10 ns | same |
| Effective frequency | 76.3 MHz | 76.3 MHz | same |
| Total on-chip power | 0.084 W | 0.229 W | 2.73× |

The paper states that the 13.10 ns timing constraint is met with WNS > 0. These values are historical paper results and have not yet been reproduced from the reconstructed RTL.

## Paper-Reported Traversal Cycles

| Tree Level | Single | Parallel | Speedup | Cycle Reduction |
|---|---:|---:|---:|---:|
| LV2 | 6 | 4 | 1.500× | 33.3% |
| LV3 | 9 | 8 | 1.125× | 11.1% |
| LV4 | 12 | 8 | 1.500× | 33.3% |
| Reported average | - | - | 1.37× | - |

### Metric Normalization

The Korean abstract describes a maximum `50%` reduction, while the published cycle table shows a maximum `1.5×` speedup. These are not mathematically identical:

```text
speedup = old cycles / new cycles
cycle reduction = (old cycles - new cycles) / old cycles
```

For `6→4` or `12→8`, the exact values are `1.5× speedup` and `33.3% cycle reduction`. The repository therefore uses the table-derived values in portfolio-facing summaries and preserves the original wording only as a source note.

## Verification Evidence in the Poster

The poster describes ModelSim-based checks for:

- input loading from I-Memory;
- simultaneous UN1–UN3 operation;
- all four Logic cases;
- class agreement with a Python reference model;
- synchronized output timing.

The current repository adds a reproducible Icarus Verilog regression with 37 vectors and direct 6-state/4-state equivalence checks. This is new repository evidence and is not presented as the original ModelSim result.

## Future Work Recorded in the Sources

- Improve AD-Memory addressing to reduce the four-cycle traversal to three cycles.
- Extend the parallel width beyond three UNs.
- Explore Decision Tree Ensemble and Random Forest structures.
