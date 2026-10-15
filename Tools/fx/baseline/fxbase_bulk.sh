#!/usr/bin/env bash
# CYS-FXBASE (fx-cy-baseline 19/09): run a list of batches one after another through the slot protocol (fxbase_slot.sh:
# one slot hold = CY batch + CY-Source batch), >= 60 s between two of our CY runs, skipping batches that already have
# both run directories for the given rep. usage: fxbase_bulk.sh <rep> <auto|cy|ours|both> b01 b02 ...  (or ... all)
set -u
ROOT=/c/TLBB/085/CY-Source
LOGS=$ROOT/Build/Logs/2026-09-19-fx-cy-baseline
REP=${1:?rep}
FORCE=${2:?what: auto|cy|ours|both}
shift 2
if [ "${1:-}" = all ]; then
  set -- $(python -c "import json;print(' '.join(b['batch'] for b in json.load(open('C:/TLBB/085/CY-Source/Build/Logs/2026-09-19-fx-cy-baseline/batches/batches.json',encoding='utf-8'))))")
fi
for b in "$@"; do
  if [ -f "$LOGS/cy/$b-r$REP/run.json" ] && [ -f "$LOGS/ours/$b-r$REP/run.json" ]; then
    echo "$(date +%H:%M:%S) $b r$REP: da co ca hai lo, bo qua"; continue
  fi
  what=both
  [ -f "$LOGS/cy/$b-r$REP/run.json" ] && what=ours
  [ -f "$LOGS/ours/$b-r$REP/run.json" ] && [ "$what" = both ] && what=cy
  [ "$FORCE" != auto ] && what=$FORCE
  if [ "$what" = cy ] && [ -f "$LOGS/cy/$b-r$REP/run.json" ]; then echo "$(date +%H:%M:%S) $b r$REP: CY da co, bo qua"; continue; fi
  if [ "$what" = ours ] && [ -f "$LOGS/ours/$b-r$REP/run.json" ]; then echo "$(date +%H:%M:%S) $b r$REP: ta da co, bo qua"; continue; fi
  echo "$(date +%H:%M:%S) $b r$REP: bat dau ($what)"
  bash "$ROOT/Tools/fx/baseline/fxbase_slot.sh" "$b" "$REP" 60 "$what" > "$LOGS/slot-$b-r$REP.txt" 2>&1
  rc=$?
  echo "$(date +%H:%M:%S) $b r$REP: xong rc=$rc; $(grep -c 'shot ' "$LOGS/cy/$b-r$REP/run.log" 2>/dev/null || echo 0) anh CY; $(ls "$LOGS/ours/$b-r$REP"/cys-replay-*.png 2>/dev/null | wc -l) anh ta"
  sleep 45
done
echo "$(date +%H:%M:%S) BULK DONE"
