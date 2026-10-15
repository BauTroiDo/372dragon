"""Tự chọn bản chuẩn cho các model có nhiều phiên bản (thay cho việc người dùng duyệt tay).

Luật (theo thứ tự):
  1. Bỏ bản không đầy đủ (complete != ok) và bản giữ chỗ (<= 6 đỉnh hoặc texture 空模型).
  2. ĐỒNG THUẬN: nếu một phiên bản được >= 2 nguồn (S1/S2/S3) dùng chung còn bản khác chỉ 1 nguồn
     -> chọn bản đồng thuận (bắt được: boss 2026 trong client_GL là model tạm; 包袱 bị CY đổi
     thành túi Thất Tịch theo mùa; bướm/giáo băng của CY bản thô hơn).
  3. Còn lại: điểm chất lượng = 2*log2(1+đỉnh) + 1.5*log2(1+texture lớn nhất) + 0.3*log2(1+KB texture)
     + 0.5*log2(1+số animation) - 5*(có lỗi thiếu file); bản S1 được giữ nếu kém bản tốt nhất < 15 %.
  4. Hoà: S1 > S3 > S2 (S1 đã chạy trong game; S3 cùng bố cục bảng HJ).

Vào: Assets/Staging/review/<đợt>/data.json (review.py sinh).
Ra:  Registry/selections/<đợt>.yaml (+ .tsv giải thích từng quyết định).
"""
import csv
import json
import math
import os
import sys

ROOT = r'C:\TLBB\085\CY-Source'
BATCH = sys.argv[1] if len(sys.argv) > 1 else '2026-09-12-variants'
DATA = os.path.join(ROOT, r'Assets\Staging\review', BATCH, 'data.json')
OUT = os.path.join(ROOT, r'Registry\selections')
ORDER = {'S1': 0, 'S3': 1, 'S2': 2}


def placeholder(col):
    m = col.get('metrics') or {}
    if (m.get('verts') or 0) <= 6:
        return True
    return any('空模型' in (t.get('tex') or '') for t in col.get('textures') or [])


def quality(col):
    m = col.get('metrics') or {}
    q = (2.0 * math.log2(1 + (m.get('verts') or 0)) + 1.5 * math.log2(1 + (m.get('max_tex_px') or 0))
         + 0.3 * math.log2(1 + (m.get('tex_kb') or 0)) + 0.5 * math.log2(1 + (m.get('anims') or 0)))
    if col.get('problems'):
        q -= 5
    return q


def decide(o):
    cols = {s: c for s, c in (o.get('cols') or {}).items() if s in ORDER and c and c.get('present')}
    ok = {s: c for s, c in cols.items() if (c.get('metrics') or {}).get('complete') == 'ok' and not placeholder(c)}
    if not ok:
        return 'S1' if 'S1' in cols else sorted(cols, key=ORDER.get)[0], 'không có bản đầy đủ -> giữ nguyên'
    groups = {}
    for s, c in ok.items():
        groups.setdefault(c.get('vid') or s, []).append(s)
    if len(groups) == 1:
        s = sorted(ok, key=ORDER.get)[0]
        return s, 'mọi bản đầy đủ giống nhau'
    big = [g for g in groups.values() if len(g) >= 2]
    if len(big) == 1:
        members = sorted(big[0], key=ORDER.get)
        return members[0], 'đồng thuận %s' % '='.join(members)
    scores = {s: quality(c) for s, c in ok.items()}
    best = max(scores, key=lambda s: (scores[s], -ORDER[s]))
    if 'S1' in scores and scores['S1'] >= 0.85 * scores[best]:
        return 'S1', 'điểm S1 %.1f ~ tốt nhất %s %.1f -> giữ S1' % (scores['S1'], best, scores[best])
    return best, 'điểm cao nhất %s %.1f (%s)' % (best, scores[best],
                                            ', '.join('%s %.1f' % (k, v) for k, v in sorted(scores.items())))


def q(s):
    return '"' + s.replace('\\', '\\\\').replace('"', '\\"') + '"'


def main():
    objs = json.load(open(DATA, encoding='utf-8'))
    os.makedirs(OUT, exist_ok=True)
    rows, stats = [], {}
    for o in objs:
        pick, why = decide(o)
        rows.append((o['obj'], pick, why, o.get('default', '')))
        stats[pick] = stats.get(pick, 0) + 1
    ypath = os.path.join(OUT, BATCH + '.yaml')
    with open(ypath, 'w', encoding='utf-8', newline='\n') as f:
        f.write('# Lựa chọn bản chuẩn, sinh TỰ ĐỘNG bởi Tools/pipeline/auto_select.py (người dùng yêu cầu hạn chế duyệt tay).\n')
        f.write('# Luật: bỏ bản thiếu/giữ chỗ -> đồng thuận >= 2 nguồn -> điểm chất lượng (giữ S1 nếu kém < 15%%) -> S1>S3>S2.\n')
        f.write('# Nguồn: %s\n' % DATA.replace('\\', '/'))
        for obj, pick, why, _ in rows:
            f.write('%s: %s  # %s\n' % (q(obj), pick, why))
    with open(os.path.join(OUT, BATCH + '.tsv'), 'w', encoding='utf-8-sig', newline='') as f:
        w = csv.writer(f, delimiter='\t')
        w.writerow(['obj', 'pick', 'reason', 'old_hint'])
        w.writerows(rows)
    changed = [r for r in rows if r[1] != 'S1']
    print('objects', len(rows), 'picks', stats, 'switch away from S1:', len(changed))
    print('differs from old hint:', sum(1 for r in rows if r[3] and r[1] != r[3]))
    for r in changed[:25]:
        print('  %s -> %s (%s)' % r[:3])
    print('->', ypath)


if __name__ == '__main__':
    main()
