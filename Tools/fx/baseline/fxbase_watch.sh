#!/usr/bin/env bash
# CYS-FXBASE: while the batches run, compare every batch as soon as both of its runs exist (rep 1; b00b-calib rep 3),
# then rebuild the overall report. One line per finished comparison. Exits when everything is compared or after 4 h.
set -u
ROOT=/c/TLBB/085/CY-Source
LOGS=$ROOT/Build/Logs/2026-09-19-fx-cy-baseline
LOGSW=C:/TLBB/085/CY-Source/Build/Logs/2026-09-19-fx-cy-baseline   # Windows form for python
cd "$ROOT" || exit 2
export PYTHONIOENCODING=utf-8 PYTHONUTF8=1
deadline=$(( $(date +%s) + 4 * 3600 ))
batches=$(python -c "import json;print(' '.join(b['batch'] for b in json.load(open('$LOGSW/batches/batches.json',encoding='utf-8'))))")
while [ "$(date +%s)" -lt "$deadline" ]; do
  pending=0
  for spec in "b00b-calib:3" $(for b in $batches; do echo "$b:1"; done); do
    b=${spec%%:*}; r=${spec##*:}
    cyd=$LOGS/cy/$b-r$r; od=$LOGS/ours/$b-r$r; cmp=$LOGS/compare/$b/compare.json
    if [ -f "$cyd/run.json" ] && [ -f "$od/run.json" ]; then
      if [ ! -f "$cmp" ] || [ "$cmp" -ot "$od/run.json" ] || [ "$cmp" -ot "$cyd/run.json" ]; then
        python Tools/fx/baseline/fxbase_compare.py batch "$b" --cy-rep "$r" --our-rep "$r" > "$LOGS/compare-$b.txt" 2>&1
        rc=$?
        echo "$(date +%H:%M:%S) $b r$r: compare rc=$rc; $(head -1 "$LOGS/compare-$b.txt" | cut -c1-150)"
        [ $rc -ne 0 ] && tail -1 "$LOGS/compare-$b.txt" | cut -c1-200
        done_list=$(for s in "b00b-calib" $batches; do [ -f "$LOGS/compare/$s/compare.json" ] && printf '%s,' "$s"; done)
        python Tools/fx/baseline/fxbase_report.py --batches "${done_list%,}" --out "$LOGS/compare/all" > "$LOGS/report-build.txt" 2>&1
      fi
    else
      pending=1
    fi
  done
  [ "$pending" = 0 ] && { echo "$(date +%H:%M:%S) WATCH DONE: everything compared"; exit 0; }
  sleep 60
done
echo "$(date +%H:%M:%S) WATCH TIMEOUT"
