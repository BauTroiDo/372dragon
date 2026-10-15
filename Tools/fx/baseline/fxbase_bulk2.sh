#!/usr/bin/env bash
# CYS-FXBASE: like fxbase_bulk.sh but a run that did not reach the world (CY: no "wait matched IN WORLD"; CY-Source:
# fewer than 40 captures) is moved aside (<dir>-failed-<hhmmss>) and retried, at most 2 retries per batch and side.
# usage: fxbase_bulk2.sh <rep> <auto|cy|ours|both> b01 b02 ...  (or ... all)
set -u
ROOT=/c/TLBB/085/CY-Source
LOGS=$ROOT/Build/Logs/2026-09-19-fx-cy-baseline
REP=${1:?rep}
FORCE=${2:?what: auto|cy|ours|both}
shift 2
if [ "${1:-}" = all ]; then
  set -- $(python -c "import json;print(' '.join(b['batch'] for b in json.load(open('C:/TLBB/085/CY-Source/Build/Logs/2026-09-19-fx-cy-baseline/batches/batches.json',encoding='utf-8'))))")
fi
cy_ok() { [ -f "$LOGS/cy/$1-r$2/run.log" ] && python "$ROOT/Tools/fx/baseline/fxbase_cyok.py" "C:/TLBB/085/CY-Source/Build/Logs/2026-09-19-fx-cy-baseline/cy/$1-r$2" > /dev/null 2>&1; }
ours_ok() { [ -f "$LOGS/ours/$1-r$2/run.json" ] && [ "$(ls "$LOGS/ours/$1-r$2"/cys-replay-*.png 2>/dev/null | wc -l)" -ge 40 ]; }
for b in "$@"; do
  for attempt in 1 2 3; do
    what=$FORCE
    if [ "$FORCE" = auto ]; then
      what=both; cy_ok "$b" "$REP" && what=ours; ours_ok "$b" "$REP" && { [ "$what" = both ] && what=cy || what=none; }
    fi
    if [ "$what" = cy ] && cy_ok "$b" "$REP"; then what=none; fi
    if [ "$what" = ours ] && ours_ok "$b" "$REP"; then what=none; fi
    if [ "$what" = both ]; then cy_ok "$b" "$REP" && what=ours; ours_ok "$b" "$REP" && { [ "$what" = both ] && what=cy || what=none; }; fi
    if [ "$what" = none ]; then echo "$(date +%H:%M:%S) $b r$REP: da du, bo qua"; break; fi
    # move aside a failed (incomplete) run directory so the slot scripts can write a fresh one
    if [ "$what" = cy ] || [ "$what" = both ]; then
      if [ -d "$LOGS/cy/$b-r$REP" ] && ! cy_ok "$b" "$REP"; then mv "$LOGS/cy/$b-r$REP" "$LOGS/cy/$b-r$REP-failed-$(date +%H%M%S)"; echo "$(date +%H:%M:%S) $b r$REP: lo CY hong, dat sang mot ben"; fi
    fi
    if [ "$what" = ours ] || [ "$what" = both ]; then
      if [ -d "$LOGS/ours/$b-r$REP" ] && ! ours_ok "$b" "$REP"; then mv "$LOGS/ours/$b-r$REP" "$LOGS/ours/$b-r$REP-failed-$(date +%H%M%S)"; echo "$(date +%H:%M:%S) $b r$REP: lo ta hong, dat sang mot ben"; fi
    fi
    echo "$(date +%H:%M:%S) $b r$REP: bat dau ($what, lan $attempt)"
    bash "$ROOT/Tools/fx/baseline/fxbase_slot.sh" "$b" "$REP" 60 "$what" > "$LOGS/slot-$b-r$REP-$attempt.txt" 2>&1
    echo "$(date +%H:%M:%S) $b r$REP: xong rc=$?; $(grep -c 'shot ' "$LOGS/cy/$b-r$REP/run.log" 2>/dev/null || echo 0) anh CY; $(ls "$LOGS/ours/$b-r$REP"/cys-replay-*.png 2>/dev/null | wc -l) anh ta"
    sleep 45
    ok=1
    { [ "$what" = cy ] || [ "$what" = both ]; } && ! cy_ok "$b" "$REP" && ok=0
    { [ "$what" = ours ] || [ "$what" = both ]; } && ! ours_ok "$b" "$REP" && ok=0
    [ "$ok" = 1 ] && break
    echo "$(date +%H:%M:%S) $b r$REP: lan $attempt KHONG DU (CY ok=$(cy_ok "$b" "$REP" && echo 1 || echo 0), ta ok=$(ours_ok "$b" "$REP" && echo 1 || echo 0))"
  done
done
echo "$(date +%H:%M:%S) BULK2 DONE"
