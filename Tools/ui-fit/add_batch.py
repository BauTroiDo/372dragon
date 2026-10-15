# -*- coding: utf-8 -*-
"""ui-fit-2: noi mot lo ban rut ngan viet tay (khoa|chuoi|ghi chu, moi dong mot khoa) vao data/short_vi.tsv.

  python Tools/ui-fit/add_batch.py <batch.txt> [...]

Khoa da co trong short_vi.tsv thi dong MOI thay dong cu (lo sau sua lo truoc). Dong trong / bat dau '#' bi bo qua.
"""
import io
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
TSV = os.path.join(HERE, "data", "short_vi.tsv")


def main():
    cur = []
    if os.path.exists(TSV):
        with io.open(TSV, "r", encoding="utf-8") as fh:
            cur = [l.rstrip("\r\n") for l in fh]
    if not cur:
        cur = ["khoa\tchuoi_ngan\tghi_chu"]
    index = {}
    for i, line in enumerate(cur):
        if i == 0:
            continue
        index[line.split("\t", 1)[0]] = i
    added = replaced = 0
    for path in sys.argv[1:]:
        with io.open(path, "r", encoding="utf-8") as fh:
            for line in fh:
                line = line.rstrip("\r\n")
                if not line or line.startswith("#"):
                    continue
                parts = line.split("|")
                if len(parts) < 2:
                    raise SystemExit("dong sai dinh dang: %r" % line)
                key, val = parts[0].strip(), parts[1]
                note = parts[2] if len(parts) > 2 else ""
                row = "%s\t%s\t%s" % (key, val, note)
                if key in index:
                    cur[index[key]] = row
                    replaced += 1
                else:
                    index[key] = len(cur)
                    cur.append(row)
                    added += 1
    with io.open(TSV, "w", encoding="utf-8", newline="\n") as fh:
        fh.write("\n".join(cur) + "\n")
    print("short_vi.tsv: them %d, thay %d, tong %d" % (added, replaced, len(cur) - 1))


if __name__ == "__main__":
    main()
