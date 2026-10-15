# -*- coding: utf-8 -*-
"""CONG "CHOT DO KHONG DUOC LOT VAO BAN CHOI" (fps-move, 20/09/2026).

LUAT (Timeline/handoff/LUAT-CHUNG-CHO-NHANH.md muc 2): moi dong log chan doan tren duong nong
(moi khung / moi goi / moi lan di chuyen) PHAI nam sau mot cong tac moi truong MAC DINH TAT.
Luat do ton tai duoi dang loi dan => da bi vi pham: stage-play-5 ghi 124.132 dong CYS-RINGSIZE
trong 19 phut, va playbuild-5 con DEM chinh cac dau do lam bang chung ban va co mat.
Tep nay bien luat thanh CONG: dua cho no log cua MOT LUOT CHAY ban choi (khong bat bien chan doan
nao), no dem so dong cua TUNG TIEN TO tren TUNG PHUT va DO neu tien to nao vuot nguong.

HOC TU CAY SONG (QUY TAC 0): client_GL ghi log luc chay vao client_GL/Bin64/LogDirectory/
Fairy_<ngay>_<pid>_0.log (dinh dang "HH:MM:SS: [Process ID: N] : ..."). Cong nay doc duoc CA dinh
dang do, de do cay song bang CUNG mot thuoc (xem --baseline trong ban giao fps-move).

CONG NAY KIEM DUOC GI - va KHONG kiem duoc gi:
  KIEM DUOC  : trong luot chay NAY, tien to nao ghi qua day (mac dinh > 600 dong/phut).
  KHONG KIEM : chot nao KHONG ban trong luot nay (nguoi choi khong danh nhau => chot dan im).
               XANH chi co nghia "luot nay khong thay", khong phai "ma sach". Luot chay phai cham
               dung cac duong nong: vao the gioi, dung yen, di chuyen, danh, mo khung.
  KHONG DO DUOC (ma thoat 2, KHONG BAO GIO tinh la XANH): tep rong / khong co moc gio / luot
               chay ngan hon --min-seconds / thieu dau hieu --require (vi du chua vao the gioi).

DUNG:
  python Tools/pipeline/probe_gate_check.py <log-hoac-thu-muc> [...] [--threshold 600]
         [--require REGEX] [--min-seconds 60] [--all] [--json out.json] [--top 25]
         [--new-prefixes <Bin64 ban CU> <Bin64 ban MOI>]
  --new-prefixes: liet ke cac tien to CYS-* CO trong binary ban moi ma KHONG co trong ban cu (= chot moi cua dot nay)
  va doi chieu voi log: DO / IM (thay, duoi nguong) / CHUA THAY (luot nay khong cham toi => CHUA chung minh gi).
  Day la thuoc chua cho diem mu cua cong: "chot khong ban trong luot nay thi XANH".
  python Tools/pipeline/probe_gate_check.py --selftest [--user-log <WXRender.log phien 14:30>]
Thu muc => tu lay WXRender.log, WXClient.log, UISystem.log, Fairy_*.log, Game_*.log, CEGUI.log.
Ma thoat: 0 XANH, 1 DO, 2 KHONG DO DUOC.
"""
import json
import os
import re
import sys

THRESHOLD = 600          # dong / phut / tien to. Dang ky truoc trong brief cua dieu phoi (20/09).
MIN_SECONDS = 60
MIN_LINES = 50

# Moc gio cua bon loai log. Doc muc BYTE: WXRender.log va Fairy_*.log la GBK.
TS_PATTERNS = [
    # Ogre / Fairy:  "14:32:25: msg"   |   "19:13:06: [Process ID: 25196] : msg"
    (re.compile(rb'^(\d\d):(\d\d):(\d\d): (?:\[Process ID: \d+\] : )?'), 'ogre'),
    # TDU_Log:       "[20_14:30:17]: msg" (ta)   |   "[11_19:29:42] msg" (client_GL Game_*.log, khong co ':')
    (re.compile(rb'^\[(\d\d)_(\d\d):(\d\d):(\d\d)\]:? '), 'tdu'),
    # CEGUI:         "20/09/2026 14:31:38 (InfL1)\tmsg"
    (re.compile(rb'^(\d\d)/(\d\d)/(\d{4}) (\d\d):(\d\d):(\d\d) \([A-Za-z0-9]+\)\s'), 'cegui'),
]

# Ho tien to cua TA (chot do cua CY-Source). Chi ho nay bi CONG chan; phan con lai chi canh bao
# (tru khi --all), vi cay song cung co cac dot log NAP tai nguyen hop le (xem ban giao).
OURS = [
    re.compile(rb'^(CYS-[A-Za-z0-9_]+)'),
    re.compile(rb'^(CYS_[A-Za-z0-9_]+)'),
    re.compile(rb'^(CYS [A-Za-z0-9_]+)'),
    re.compile(rb'^(Cys[A-Z][A-Za-z0-9]+)'),
    re.compile(rb'^(LuaApiGen)'),
]
DIGITS = re.compile(rb'\d+')


def split_ts(line):
    """-> (day, hh, mm, ss, msg) hoac None."""
    for rx, kind in TS_PATTERNS:
        m = rx.match(line)
        if not m:
            continue
        g = m.groups()
        if kind == 'ogre':
            day, hh, mm, ss = 0, int(g[0]), int(g[1]), int(g[2])
        elif kind == 'tdu':
            day, hh, mm, ss = int(g[0]), int(g[1]), int(g[2]), int(g[3])
        else:
            day, hh, mm, ss = int(g[0]), int(g[3]), int(g[4]), int(g[5])
        if hh > 23 or mm > 59 or ss > 59:
            return None
        return day, hh, mm, ss, line[m.end():]
    return None


def key_of(msg):
    """-> (khoa, la_cua_ta)."""
    for rx in OURS:
        m = rx.match(msg)
        if m:
            return m.group(1).decode('ascii', 'replace'), True
    head = msg[:48].split(b':', 1)[0][:40]
    head = DIGITS.sub(b'#', head)
    head = bytes(c if 32 <= c < 127 else 63 for c in head).strip()
    return '~' + head.decode('ascii', 'replace'), False


def scan_file(path):
    """Dem theo TUNG DONG. -> dict thong ke cua mot tep."""
    per_min = {}      # key -> {minute: n}
    per_sec = {}      # key -> {second: n}   (chi de mo ta dinh: ~60-240/s = moi khung)
    ours = set()
    total = stamped = 0
    first = last = None
    with open(path, 'rb') as f:
        for raw in f:
            total += 1
            line = raw.rstrip(b'\r\n')
            if not line:
                continue
            t = split_ts(line)
            if t is None:
                continue
            day, hh, mm, ss, msg = t
            stamped += 1
            sec = ((day * 24 + hh) * 60 + mm) * 60 + ss
            if first is None:
                first = sec
            last = sec
            k, mine = key_of(msg)
            if mine:
                ours.add(k)
            per_min.setdefault(k, {})
            per_min[k][sec // 60] = per_min[k].get(sec // 60, 0) + 1
            per_sec.setdefault(k, {})
            per_sec[k][sec] = per_sec[k].get(sec, 0) + 1
    span = 0
    if first is not None:
        span = last - first
        if span < 0:                      # log Ogre khong co ngay: qua nua dem
            span += 86400
    return {'path': path, 'lines': total, 'stamped': stamped, 'span_s': span,
            'per_min': per_min, 'per_sec': per_sec, 'ours': ours}


def fmt_minute(m):
    return '%02d:%02d' % ((m // 60) % 24, m % 60)


def judge(stat, threshold, gate_all):
    rows = []
    for k, mins in stat['per_min'].items():
        peak_min = max(mins, key=lambda x: mins[x])
        peak = mins[peak_min]
        over = sum(1 for v in mins.values() if v > threshold)
        secs = stat['per_sec'][k]
        rows.append({'key': k, 'ours': k in stat['ours'], 'total': sum(mins.values()),
                     'peak_per_min': peak, 'peak_minute': fmt_minute(peak_min),
                     'minutes_over': over, 'peak_per_sec': max(secs.values())})
    rows.sort(key=lambda r: -r['peak_per_min'])
    red = [r for r in rows if r['peak_per_min'] > threshold and (r['ours'] or gate_all)]
    warn = [r for r in rows if r['peak_per_min'] > threshold and not (r['ours'] or gate_all)]
    return rows, red, warn


RX_BIN_PREFIX = re.compile(rb'CYS-[A-Z][A-Z0-9_]{2,}')


def binary_prefixes(bin_dir):
    """-> {tien to: [ten tep]} doc BYTE THO cac .exe/.dll trong mot thu muc Bin64."""
    found = {}
    for n in sorted(os.listdir(bin_dir)):
        if not n.lower().endswith(('.exe', '.dll')):
            continue
        with open(os.path.join(bin_dir, n), 'rb') as f:
            data = f.read()
        for tok in set(RX_BIN_PREFIX.findall(data)):
            found.setdefault(tok.decode('ascii'), []).append(n)
    return found


def expand(paths):
    names = ('WXRender.log', 'WXClient.log', 'UISystem.log', 'CEGUI.log')
    out = []
    for p in paths:
        if os.path.isdir(p):
            for n in sorted(os.listdir(p)):
                if n in names or re.match(r'(?i)^(Fairy|Game)_.*\.log$', n):
                    out.append(os.path.join(p, n))
        else:
            out.append(p)
    return out


def run(paths, threshold=THRESHOLD, require=None, min_seconds=MIN_SECONDS, gate_all=False,
        top=25, out=sys.stdout, json_path=None, new_prefix_dirs=None):
    files = expand(paths)
    w = lambda s='': out.write(s + '\n')
    w('CONG CHOT DO - nguong %d dong/phut/tien to%s' % (threshold, ' (chan CA tien to khong phai cua ta)' if gate_all else ''))
    report = {'threshold': threshold, 'files': [], 'verdict': None}
    if not files:
        w('  KHONG DO DUOC: khong co tep log nao trong %s' % paths)
        report['verdict'] = 'KHONG DO DUOC'
        return 2, report
    unmeasurable, any_red = [], False
    seen = {}            # tien to -> (tong, dinh/phut) gop moi tep
    required_hit = require is None
    rx_req = re.compile(require.encode('utf-8')) if require else None
    for path in files:
        if not os.path.isfile(path):
            unmeasurable.append('%s: khong ton tai' % path)
            continue
        if rx_req is not None and not required_hit:
            with open(path, 'rb') as f:
                if rx_req.search(f.read()):
                    required_hit = True
        st = scan_file(path)
        rows, red, warn = judge(st, threshold, gate_all)
        for r in rows:
            t, pk = seen.get(r['key'], (0, 0))
            seen[r['key']] = (t + r['total'], max(pk, r['peak_per_min']))
        w('')
        w('  %s' % path)
        w('    %d dong, %d co moc gio, trai %d s (%.1f phut)' % (st['lines'], st['stamped'], st['span_s'], st['span_s'] / 60.0))
        if st['stamped'] < MIN_LINES or st['span_s'] < min_seconds:
            why = 'chi %d dong co moc gio / %d s (can >= %d dong va >= %d s)' % (st['stamped'], st['span_s'], MIN_LINES, min_seconds)
            w('    KHONG DO DUOC: ' + why)
            unmeasurable.append('%s: %s' % (path, why))
        w('    %-34s %4s %9s %9s %6s %8s %7s' % ('tien to', 'cua', 'tong', 'dinh/ph', 'luc', 'ph>ng', 'dinh/s'))
        for r in rows[:top]:
            flag = 'DO ' if r in red else ('cb ' if r in warn else '   ')
            w('  %s %-34s %4s %9d %9d %6s %8d %7d' % (flag, r['key'][:34], 'TA' if r['ours'] else '-', r['total'],
                                                       r['peak_per_min'], r['peak_minute'], r['minutes_over'], r['peak_per_sec']))
        any_red = any_red or bool(red)
        report['files'].append({'path': path, 'lines': st['lines'], 'stamped': st['stamped'], 'span_s': st['span_s'],
                                'red': red, 'warn': warn, 'rows': rows[:top]})
    w('')
    if new_prefix_dirs:
        old_dir, new_dir = new_prefix_dirs
        old_p, new_p = binary_prefixes(old_dir), binary_prefixes(new_dir)
        fresh = sorted(k for k in new_p if k not in old_p)
        w('  CHOT MOI cua ban dung nay (co trong %s, khong co trong %s): %d' % (new_dir, old_dir, len(fresh)))
        report['new_prefixes'] = []
        for k in fresh:
            t, pk = seen.get(k, (0, 0))
            status = 'DO' if pk > threshold else ('IM' if t else 'CHUA THAY')
            w('    %-10s %-26s %-34s tong %7d  dinh %6d/phut' % (status, k, ','.join(new_p[k])[:34], t, pk))
            report['new_prefixes'].append({'key': k, 'binaries': new_p[k], 'total': t, 'peak_per_min': pk, 'status': status})
        unseen = [x['key'] for x in report['new_prefixes'] if x['status'] == 'CHUA THAY']
        if unseen:
            w('    => %d chot moi CHUA THAY trong luot nay: luot chay chua cham toi chung, CHUA chung minh chung im.' % len(unseen))
        w('')
    if not required_hit:
        unmeasurable.append('khong tep nao khop --require %r (luot chay chua toi trang thai can do)' % require)
    if any_red:
        for fr in report['files']:
            for r in fr['red']:
                w('  DO: %-28s dinh %d dong/phut luc %s (%d phut vuot nguong, dinh %d dong/giay)  [%s]' % (
                    r['key'], r['peak_per_min'], r['peak_minute'], r['minutes_over'], r['peak_per_sec'], os.path.basename(fr['path'])))
        w('  => DO. Chot do tren duong nong dang ghi vao ban choi. Dua no ra sau cong tac moi truong MAC DINH TAT')
        w('     (getenv MOT lan roi nho), hoac sua cai vong lap dang lam no ban lien tuc. DUNG noi nguong.')
        report['verdict'] = 'DO'
        code = 1
    elif unmeasurable:
        for u in unmeasurable:
            w('  KHONG DO DUOC: ' + u)
        w('  => KHONG DO DUOC (khong phai XANH).')
        report['verdict'] = 'KHONG DO DUOC'
        code = 2
    else:
        w('  => XANH: khong tien to nao cua ta vuot %d dong/phut trong luot nay.' % threshold)
        report['verdict'] = 'XANH'
        code = 0
    if any_red and unmeasurable:
        for u in unmeasurable:
            w('  (kem) KHONG DO DUOC: ' + u)
    if json_path:
        with open(json_path, 'w', encoding='utf-8') as f:
            json.dump(report, f, ensure_ascii=False, indent=1)
    return code, report


# ---------------------------------------------------------------------------------------------
def _synth(path, kind, minutes, per_minute, noise=True, gbk=False):
    """Log tong hop: `per_minute` = {tien to: so dong moi phut}."""
    with open(path, 'wb') as f:
        for m in range(minutes):
            hh, mm = 14 + (30 + m) // 60, (30 + m) % 60
            lines = []
            if noise:
                for i in range(40):
                    body = b'Texture: Loading jpg_%d.dds.' % i
                    if gbk:
                        body = b'Mesh: Loading \xb4\xf3\xc0\xed/\xc3\xc5_%d.mesh.' % i   # byte GBK that
                    lines.append((i % 60, body))
            for pre, n in per_minute.items():
                for i in range(n):
                    lines.append((i * 60 // max(n, 1), pre.encode('ascii') + b': probe i=%d' % i))
            lines.sort(key=lambda x: x[0])
            for ss, body in lines:
                if kind == 'ogre':
                    f.write(b'%02d:%02d:%02d: ' % (hh, mm, ss) + body + b'\r\n')
                elif kind == 'fairy':
                    f.write(b'%02d:%02d:%02d: [Process ID: 4242] : ' % (hh, mm, ss) + body + b'\r\n')
                elif kind == 'tdu':
                    f.write(b'[20_%02d:%02d:%02d]: ' % (hh, mm, ss) + body + b'\r\n')
                else:
                    f.write(b'20/09/2026 %02d:%02d:%02d (InfL1)\t' % (hh, mm, ss) + body + b'\r\n')


def selftest(user_log=None):
    import io
    import tempfile
    d = tempfile.mkdtemp(prefix='probe_gate_')
    cases = []

    def case(label, want, paths, **kw):
        buf = io.StringIO()
        code, rep = run(paths, out=buf, **kw)
        ok = code == want
        cases.append(ok)
        print('  %-5s %-66s ma=%d (can %d)' % ('DAT' if ok else 'HONG', label, code, want))
        if not ok:
            print(buf.getvalue())
        return rep

    p = os.path.join
    _synth(p(d, 'clean.log'), 'ogre', 5, {'CYS-SKY': 12, 'CYS shadow': 12})
    case('DOI CHUNG AM: log sach (ogre) => XANH', 0, [p(d, 'clean.log')])
    _synth(p(d, 'clean_tdu.log'), 'tdu', 5, {'CYS-ACCEL': 30, 'CYS world': 12})
    case('DOI CHUNG AM: log sach (TDU_Log) => XANH', 0, [p(d, 'clean_tdu.log')])
    _synth(p(d, 'clean_cegui.log'), 'cegui', 5, {'CYS-MESHWIN': 9})
    case('DOI CHUNG AM: log sach (CEGUI) => XANH', 0, [p(d, 'clean_cegui.log')])
    _synth(p(d, 'spam.log'), 'ogre', 5, {'CYS-RINGSIZE': 3600})
    rep = case('DOI CHUNG DUONG: 3600 dong/phut (moi khung) => DO', 1, [p(d, 'spam.log')])
    names = [r['key'] for fr in rep['files'] for r in fr['red']]
    ok = names == ['CYS-RINGSIZE']
    cases.append(ok)
    print('  %-5s %-66s %s' % ('DAT' if ok else 'HONG', '  ... va CHI tien to do bi goi ten', names))
    _synth(p(d, 'edge600.log'), 'ogre', 3, {'CYS-EDGE': 600})
    case('BIEN: dung 600 dong/phut => XANH (nguong la ">")', 0, [p(d, 'edge600.log')])
    _synth(p(d, 'edge601.log'), 'ogre', 3, {'CYS-EDGE': 601})
    case('BIEN: 601 dong/phut => DO', 1, [p(d, 'edge601.log')])
    _synth(p(d, 'gbk.log'), 'ogre', 3, {'CYS-SKY': 5}, gbk=True)
    case('byte GBK trong dong khong lam hong phep dem => XANH', 0, [p(d, 'gbk.log')])
    _synth(p(d, 'fairy.log'), 'fairy', 3, {'CYS-X': 700})
    case('dinh dang cay song "[Process ID: N]" van doc duoc => DO', 1, [p(d, 'fairy.log')])
    open(p(d, 'empty.log'), 'wb').close()
    case('PHEP DO KHONG CHAY: tep rong => KHONG DO DUOC (khong XANH)', 2, [p(d, 'empty.log')])
    with open(p(d, 'nots.log'), 'wb') as f:
        f.write(b'CYS-RINGSIZE: khong co moc gio\r\n' * 5000)
    case('PHEP DO KHONG CHAY: 5000 dong KHONG moc gio => KHONG DO DUOC', 2, [p(d, 'nots.log')])
    _synth(p(d, 'short.log'), 'ogre', 1, {'CYS-SKY': 5})
    case('PHEP DO KHONG CHAY: luot chay < 60 s => KHONG DO DUOC', 2, [p(d, 'short.log')])
    case('PHEP DO KHONG CHAY: tep khong ton tai => KHONG DO DUOC', 2, [p(d, 'khong-co.log')])
    case('--require khong khop (chua vao the gioi) => KHONG DO DUOC', 2, [p(d, 'clean.log')], require='GCEnterScene')
    case('--require khop => XANH', 0, [p(d, 'clean.log')], require='CYS-SKY')
    _synth(p(d, 'foreign.log'), 'ogre', 3, {'Texture': 900})
    case('tien to KHONG phai cua ta vuot nguong => chi canh bao, XANH', 0, [p(d, 'foreign.log')])
    case('... va --all thi DO', 1, [p(d, 'foreign.log')], gate_all=True)
    case('DO thang KHONG DO DUOC khi co ca hai', 1, [p(d, 'spam.log'), p(d, 'empty.log')])
    # --new-prefixes: hai thu muc "Bin64" gia; ban moi them ba chot, mot cai on, mot cai im, mot cai khong ban.
    os.mkdir(p(d, 'old')); os.mkdir(p(d, 'new'))
    with open(p(d, 'old', 'Game.exe'), 'wb') as f:
        f.write(b'MZ\0\0CYS-OLDPROBE: x=%d\0')
    with open(p(d, 'new', 'Game.exe'), 'wb') as f:
        f.write(b'MZ\0\0CYS-OLDPROBE: x=%d\0CYS-QUIET: once\0CYS-NEVERFIRES: y\0')
    with open(p(d, 'new', 'Render.dll'), 'wb') as f:
        f.write(b'MZ\0\0CYS-RINGSIZE: dummy type=\0')
    _synth(p(d, 'np.log'), 'ogre', 3, {'CYS-RINGSIZE': 3600, 'CYS-QUIET': 2, 'CYS-OLDPROBE': 5})
    rep = case('--new-prefixes: van DO vi chot moi on', 1, [p(d, 'np.log')], new_prefix_dirs=(p(d, 'old'), p(d, 'new')))
    got = {x['key']: x['status'] for x in rep.get('new_prefixes', [])}
    want_np = {'CYS-RINGSIZE': 'DO', 'CYS-QUIET': 'IM', 'CYS-NEVERFIRES': 'CHUA THAY'}
    ok = got == want_np
    cases.append(ok)
    print('  %-5s %-66s %s' % ('DAT' if ok else 'HONG', '  ... chot moi: DO / IM / CHUA THAY dung tung cai; chot CU khong bi liet ke', got))
    if user_log:
        rep = case('LOG THAT: phien nguoi dung 14:30 stage-play-5 => PHAI DO', 1, [user_log])
        names = [r['key'] for fr in rep['files'] for r in fr['red']]
        ok = 'CYS-RINGSIZE' in names
        cases.append(ok)
        print('  %-5s %-66s %s' % ('DAT' if ok else 'HONG', '  ... va CYS-RINGSIZE nam trong danh sach DO', names))
    else:
        print('  (bo qua ca LOG THAT: khong co --user-log)')
    bad = cases.count(False)
    print('selftest: %d/%d' % (len(cases) - bad, len(cases)))
    return 0 if bad == 0 else 1


def main(argv):
    if '--selftest' in argv:
        user = None
        if '--user-log' in argv:
            user = argv[argv.index('--user-log') + 1]
        return selftest(user)
    kw = {}
    paths = []
    it = iter(argv)
    for a in it:
        if a == '--threshold':
            kw['threshold'] = int(next(it))
        elif a == '--require':
            kw['require'] = next(it)
        elif a == '--min-seconds':
            kw['min_seconds'] = int(next(it))
        elif a == '--json':
            kw['json_path'] = next(it)
        elif a == '--top':
            kw['top'] = int(next(it))
        elif a == '--all':
            kw['gate_all'] = True
        elif a == '--new-prefixes':
            kw['new_prefix_dirs'] = (next(it), next(it))
        else:
            paths.append(a)
    if not paths:
        print(__doc__)
        return 2
    code, _ = run(paths, **kw)
    return code


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
