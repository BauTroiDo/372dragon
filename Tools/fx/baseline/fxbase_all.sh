#!/usr/bin/env bash
# CYS-FXBASE: compare every batch that has both runs (given rep for CY and CY-Source; b00b-calib uses the reps given
# separately) and rebuild the overall report. usage: fxbase_all.sh [rep=1] [b00b_cy_rep=1] [b00b_our_rep=2]
set -u
ROOT=/c/TLBB/085/CY-Source
LOGS=$ROOT/Build/Logs/2026-09-19-fx-cy-baseline
REP=${1:-1}
B00CY=${2:-1}
B00OURS=${3:-2}
cd "$ROOT" || exit 2
export PYTHONIOENCODING=utf-8 PYTHONUTF8=1
done_list=""
if [ -f "$LOGS/cy/b00b-calib-r$B00CY/run.json" ] && [ -f "$LOGS/ours/b00b-calib-r$B00OURS/run.json" ]; then
  python Tools/fx/baseline/fxbase_compare.py batch b00b-calib --cy-rep "$B00CY" --our-rep "$B00OURS" > "$LOGS/compare-b00b-calib.txt" 2>&1 && done_list="b00b-calib"
  tail -n +2 "$LOGS/compare-b00b-calib.txt" | head -3
fi
for b in $(python -c "import json;print(' '.join(x['batch'] for x in json.load(open('C:/TLBB/085/CY-Source/Build/Logs/2026-09-19-fx-cy-baseline/batches/batches.json',encoding='utf-8'))))"); do
  if [ -f "$LOGS/cy/$b-r$REP/run.json" ] && [ -f "$LOGS/ours/$b-r$REP/run.json" ]; then
    python Tools/fx/baseline/fxbase_compare.py batch "$b" --cy-rep "$REP" --our-rep "$REP" > "$LOGS/compare-$b.txt" 2>&1 && done_list="$done_list,$b"
    head -1 "$LOGS/compare-$b.txt"
  fi
done
done_list=${done_list#,}
echo "compared: $done_list"
python Tools/fx/baseline/fxbase_report.py --batches "$done_list" --out "$LOGS/compare/all"
