#!/usr/bin/env bash
# CYS-FXBASE (fx-cy-baseline 19/09): take the shared Game.exe slot by the queue protocol (DIEU-PHOI-19-09 muc 18):
#   append our name at the END of Build/game-slot-queue.txt, log the reason, run only when the FIRST line is ours and no
#   Game.exe is alive, then delete OUR first line only and log the hand-back. One slot hold = CY batch + CY-Source batch.
# usage: fxbase_slot.sh <batch> [rep] [max-wait-minutes] [cy|ours|both]
set -u
ROOT=/c/TLBB/085/CY-Source
QUEUE=$ROOT/Build/game-slot-queue.txt
QLOG=$ROOT/Build/game-slot-queue.log
ME=fx-cy-baseline
BATCH=${1:?batch}
REP=${2:-1}
MAX_MIN=${3:-40}
WHAT=${4:-both}
LOGS=$ROOT/Build/Logs/2026-09-19-fx-cy-baseline
# FXBASE_MODE=continuous (default) | enable : which override table both sides load for this run
MODE=${FXBASE_MODE:-continuous}
TDIR=tables; [ "$MODE" = enable ] && TDIR=tables-enable
CYTABLE="C:/TLBB/085/CY-Source/Build/re/fx-cy-baseline/$TDIR/cy/ImpactSEData_V1.txt"
OURTABLE="C:/TLBB/085/CY-Source/Build/re/fx-cy-baseline/$TDIR/ours/ImpactSEData_V1.txt"
cd "$ROOT" || exit 2
before=$(grep -v '^[[:space:]]*$' "$QUEUE" 2>/dev/null | tr -d '\r' | paste -sd, -)
[ -z "$before" ] && before='(trong)'
printf '%s\n' "$ME" >> "$QUEUE"
echo "$(date '+%Y-%m-%d %H:%M:%S') $ME: them vao CUOI hang doi (hang doi truoc do: $before); ly do: bo anh chuan CY cho 141 hieu ung, lo $BATCH-r$REP che do $MODE (CY 3.71 ban sao rieng <=150 s + replay stage-fxbase <=130 s, cung mot lan giu khe); dieu phoi 19/09 xac nhan khe rong" >> "$QLOG"
deadline=$(( $(date +%s) + MAX_MIN * 60 ))
while :; do
  head_line=$(grep -v '^[[:space:]]*$' "$QUEUE" 2>/dev/null | head -1 | tr -d '\r')
  running=$(tasklist //FI "IMAGENAME eq Game.exe" 2>/dev/null | grep -c "^Game.exe")
  if [ "$head_line" = "$ME" ] && [ "$running" = "0" ]; then
    echo "TOI LUOT luc $(date +%H:%M:%S) (dong dau=$head_line, Game.exe=0)"; break
  fi
  if [ "$(date +%s)" -ge "$deadline" ]; then
    echo "CHUA TOI LUOT sau ${MAX_MIN} phut (dong dau=$head_line, Game.exe=$running)"; exit 3
  fi
  sleep 20
done
rc1=0; rc2=0
if [ "$WHAT" = both ] || [ "$WHAT" = cy ]; then
  powershell -NoProfile -ExecutionPolicy Bypass -File "$ROOT/Tools/fx/baseline/fxbase_cy_batch.ps1" -Batch "$BATCH" -Rep "$REP" -Table "$CYTABLE" > "$LOGS/cy-$BATCH-r$REP.stdout.txt" 2>&1; rc1=$?
  tail -8 "$LOGS/cy-$BATCH-r$REP.stdout.txt"
  for i in 1 2 3 4 5 6; do [ "$(tasklist //FI "IMAGENAME eq Game.exe" 2>/dev/null | grep -c '^Game.exe')" = "0" ] && break; sleep 5; done
  sleep 20
fi
if [ "$WHAT" = both ] || [ "$WHAT" = ours ]; then
  powershell -NoProfile -ExecutionPolicy Bypass -File "$ROOT/Tools/fx/baseline/fxbase_replay_run.ps1" -Batch "$BATCH" -Rep "$REP" -Table "$OURTABLE" > "$LOGS/ours-$BATCH-r$REP.stdout.txt" 2>&1; rc2=$?
  tail -12 "$LOGS/ours-$BATCH-r$REP.stdout.txt"
fi
for i in 1 2 3 4 5 6; do [ "$(tasklist //FI "IMAGENAME eq Game.exe" 2>/dev/null | grep -c '^Game.exe')" = "0" ] && break; sleep 5; done
python - "$QUEUE" "$ME" <<'PY'
import sys
p, me = sys.argv[1], sys.argv[2]
lines = open(p, encoding='utf-8').read().splitlines()
if lines and lines[0].strip() == me:
    rest = lines[1:]
    open(p, 'w', encoding='utf-8', newline='\n').write(('\n'.join(rest) + '\n') if rest else '')
    print('KHE DA TRA: xoa dong dau', me, '; dong dau moi =', rest[0] if rest else '(trong)')
else:
    print('KHONG XOA: dong dau khong phai', me, '=', lines[:1])
PY
echo "$(date '+%Y-%m-%d %H:%M:%S') $ME: tra khe sau $BATCH-r$REP (cy rc=$rc1, ours rc=$rc2)" >> "$QLOG"
echo "rc cy=$rc1 ours=$rc2"
