#!/usr/bin/env bash
set -eu

PROJECT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
COMMON_RTL="$PROJECT_DIR/rtl/common/I_Memory_ext.v $PROJECT_DIR/rtl/common/ad_ro.v $PROJECT_DIR/rtl/common/decision_tree.v $PROJECT_DIR/rtl/common/logic_param_prefetch.v"
SIX_RTL="$PROJECT_DIR/rtl/recovered_6state/top_prefetch_un3.v"
FOUR_RTL="$PROJECT_DIR/rtl/refined_4state/top_prefetch_un3_4state.v"

mkdir -p "$BUILD_DIR"
cd "$PROJECT_DIR"

iverilog -g2012 -Wall \
  -s tb_top_prefetch_depth4_scenario \
  -o "$BUILD_DIR/tb_6state.out" \
  $COMMON_RTL "$SIX_RTL" "$PROJECT_DIR/tb/tb_top_prefetch_depth4_scenario.v"
vvp "$BUILD_DIR/tb_6state.out"

iverilog -g2012 -Wall \
  -s tb_refined_4state_equivalence \
  -o "$BUILD_DIR/tb_equivalence.out" \
  $COMMON_RTL "$SIX_RTL" "$FOUR_RTL" "$PROJECT_DIR/tb/tb_refined_4state_equivalence.v"
vvp "$BUILD_DIR/tb_equivalence.out"
