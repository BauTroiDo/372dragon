#!/bin/bash
# chỉ đọc: phần log Game2 từ offset $2 của file $1 -> đếm traceback/lỗi + trích dòng (ghi ra $3)
F="$1"; OFF="$2"; OUT="$3"
NEW=$(ls -t /home/ubuntu/cys-test-20260913/log/*/Game2_*.log 2>/dev/null | head -1)
{
  if [ "$NEW" != "$F" ]; then echo "# log rotated: $F -> $NEW"; tail -c +$((OFF+1)) "$F"; cat "$NEW"; else tail -c +$((OFF+1)) "$F"; fi
} > /dev/shm/menpai_audit_seg.txt
TB=$(grep -aciE 'traceback|stack traceback' /dev/shm/menpai_audit_seg.txt)
ERR=$(grep -aciE 'attempt to|nil value|\[error\]|error:|assert' /dev/shm/menpai_audit_seg.txt)
LINES=$(wc -l < /dev/shm/menpai_audit_seg.txt)
echo "lines=$LINES traceback=$TB error=$ERR"
{
  echo "lines=$LINES traceback=$TB error=$ERR"
  grep -aiE -B2 -A8 'traceback|attempt to|nil value|\[error\]|error:|assert' /dev/shm/menpai_audit_seg.txt | cut -c1-400 | head -80
  echo "== guid/skill"
  grep -aiE 'skill|impact' /dev/shm/menpai_audit_seg.txt | grep -aviE 'CGAskDetail' | cut -c1-300 | head -20
} > "$OUT"
rm -f /dev/shm/menpai_audit_seg.txt
