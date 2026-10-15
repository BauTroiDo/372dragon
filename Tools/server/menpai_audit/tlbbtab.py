# Đọc bảng text TLBB (GBK, dòng 1 kiểu, dòng 2 tên cột, từ dòng 3 dữ liệu). Cột trùng tên -> list.
import collections

R = '/home/ubuntu/cys-test-20260913'


def load(path, enc='gbk'):
    with open(path, 'rb') as f:
        raw = f.read()
    lines = raw.split(b'\n')
    names = [c.decode(enc, 'replace').strip() for c in lines[1].rstrip(b'\r').split(b'\t')]
    rows = []
    for ln in lines[2:]:
        ln = ln.rstrip(b'\r')
        if not ln.strip() or ln.startswith(b'#'):
            continue
        cells = [c.decode(enc, 'replace') for c in ln.split(b'\t')]
        d = collections.OrderedDict()
        for i, n in enumerate(names):
            v = cells[i] if i < len(cells) else ''
            if n in d:
                if not isinstance(d[n], list):
                    d[n] = [d[n]]
                d[n].append(v)
            else:
                d[n] = v
        d['__cells'] = cells
        rows.append(d)
    return names, rows


def num(v, default=None):
    try:
        f = float(v)
        return int(f) if f == int(f) else f
    except Exception:
        return default
