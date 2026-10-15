#!/bin/bash
# chỉ đọc: in "<file log Game2 mới nhất> <kích thước byte>"
R=/home/ubuntu/cys-test-20260913
NEW=$(ls -t $R/log/*/Game2_*.log 2>/dev/null | head -1)
echo "$NEW $(stat -c %s "$NEW")"
