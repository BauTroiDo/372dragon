"""cys_i18nscope_leak.py - CYS-I18NSCOPE (19/09/2026): do phep "ghi de theo KHOA, tran khung theo KHUNG".

Van de (do duoc boi nhanh selfequip-fit, muc 5.3 cua Timeline/handoff/selfequip-fit.md)
---------------------------------------------------------------------------------------
`Registry/i18n/cy_vi_override.tsv` ghi de MOT gia tri cho MOT khoa. Nhung cung mot khoa
`#{KEY}` duoc nhieu khung tham chieu, moi khung mot be rong khac nhau. Khi `cy_translate.py
shorten` rut khoa cho vua khung HEP NHAT, moi khung khac gánh ban rut gon ma no khong can.

Vi du da biet (chung cu cua selfequip-fit): `INTERFACE_XML_628` bi rut thanh "T.pháp" (mat ca
dau hai cham) vi khung `Pet` rong 30 px; nhung `SelfEquip` cung dung dung khoa do va o do thua cho.
Keo rong `SelfEquip` KHONG sua duoc - loi nam o ban dich, khong o khung dang xem.

Cong cu nay tra loi bang SO:
  1. 847 khoa "ro ri" la nhung khoa nao (khoa co ghi ngan sach + con duoc dung o khung khac).
  2. Neu doi sang ghi de theo cap (KHOA, KHUNG) thi CUU duoc bao nhieu cho tren man hinh.

Cach do (moi buoc deu tai lap duoc, khong uoc luong)
---------------------------------------------------
* ban RUT GON  = gia tri hien tai cua `cy_gui_dict.build()` (tuc co ghi de).
* ban DAY DU   = chinh `cy_gui_dict.build()` chay lai voi `Extra.over_key` DA BO cac khoa co
                 ghi chu ngan sach - tuc gia tri ma duong ong se tra ve neu chua ai rut no.
                 Khong phai suy dien: cung ham build, cung TM, cung `cy_vi_api.tsv`.
* be rong o    = `cy_layout_fit.parse_layout()` (chuoi UnifiedAreaRect/AbsoluteRect long nhau,
                 goc 1024x768) - dung ham cua ui-fit-2, khong viet lai bo do thu hai.
* be rong chu  = `cy_layout_fit.est_width()` - y het thuoc do da sinh ra 3.377 ghi de nay, nen
                 phep "vua/khong vua" nam tren CUNG mot thang do voi quyet dinh rut goc.

Doi chung (khong co thi moi so deu vo nghia) - chay bang --selftest:
  * DUONG: `INTERFACE_XML_628` PHAI hien ra la ro ri, ngan sach `Pet`, va PHAI duoc cuu o `SelfEquip`.
  * AM 1 : mot khoa chi duoc dung DUY NHAT trong khung ngan sach cua no PHAI KHONG bi goi la ro ri.
  * AM 2 : bom mot ghi de gia (ban rut gon rong hon o) vao mot khung khac PHAI bi bat.
  * AM 3 : neu ban day du VUOT o cua khung thu hai thi khung do PHAI KHONG duoc tinh la cuu duoc.

usage:
  python -B cys_i18nscope_leak.py --out leak-table.json --rescue rescue.json
  python -B cys_i18nscope_leak.py --selftest
"""
import argparse
import collections
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import cy_gui_dict as GDICT       # noqa: E402
import cy_layout_fit as FIT       # noqa: E402

CYS = FIT.CYS
IFACE = FIT.IFACE
S4_STR = r'C:\TLBB\085\Tools\DATA NEW\CY Game\Data\Config.axp'
GL_VI = os.path.join(CYS, 'Assets', 'Canonical', 'Data', 'ConfigFolder', 'StrDictionary.txt')
OVERRIDE = GDICT.OVERRIDE_TSV
# Cot `note` ghi ngan sach bang HAI PHUONG NGU, khong phai mot:
#   the he ui-fit-2 (3.360 dong):  "ui-fit-2 17/09: vua 30 px Pet"
#   the he ui-fit CU  (16 dong)  :  "fit 30 px Pet (Pet_Footwork_Text)"
# Chi khop `vua` thi bo sot 14 dong con song - va do CHINH LA ly do `INTERFACE_XML_628` (`T.pháp`,
# vi du tieu bieu cua selfequip-fit) khong nam trong `override-leak.json` cua chinh ho.
# Mot regex viet tay cho mot cot van ban tu do luon la mot dinh nghia THIEU cho toi khi co ai do
# dem bang cach thu hai (DIEU-PHOI muc 17).
BUDGET = re.compile(r'(?:vua|\bfit)\s+(\d+)\s+px\s+(\S+)')
KEYREF_ANY = re.compile(r'#\{([^}]+)\}')
KEYREF_ONLY = re.compile(r'^#\{([^}]+)\}$')
RAWREF = re.compile(rb'#\{([^}\r\n]{1,120})\}')


# ---------------------------------------------------------------- ghi de + ngan sach

def load_budget(path=OVERRIDE):
    """-> {key: (px, frame)} cho moi dong ghi de dang '#KEY' co ghi chu 'vua N px <Khung>'."""
    out = {}
    with open(path, 'rb') as f:
        lines = f.read().decode('utf-8').split('\n')
    for ln in lines[1:]:
        p = ln.rstrip('\r').split('\t')
        if len(p) < 3 or not p[0].startswith('#'):
            continue
        m = BUDGET.search(p[2])
        if m:
            out.setdefault(p[0][1:], (int(m.group(1)), m.group(2)))
    return out


def parse_text_dict(data):
    """{key: vi} tu bang van ban StrDictionary da dung (bytes), y het GDICT.load_text_dict nhung tu bo nho."""
    d = {}
    for ln in data.split(b'\n')[2:]:
        ln = ln.rstrip(b'\r')
        if b'\t' not in ln:
            continue
        k, v = ln.split(b'\t', 1)
        d.setdefault(k.decode('utf-8'), v.decode('utf-8'))
    return d


def build_dicts(drop_keys):
    """-> (now {key: vi}, full {key: vi}, zh {key: zh}).

    `full` = chinh build() chay lai voi cac khoa trong `drop_keys` bi go khoi over_key.
    Khong mo phong chuoi uu tien bang tay: goi lai dung ham san xuat.
    """
    sys.path.insert(0, os.path.join(CYS, 'Docs', 'evidence', 'assetinv'))
    import axp_index as AX
    a = AX.Axp(S4_STR)
    _, raw = a.payload_full('StrDictionary.txt', 256 << 20)
    a.f.close()
    zh = {}
    for kb, vb in GDICT.parse_binary_dbc(raw):
        zh.setdefault(kb.decode('gbk'), vb.decode('gbk', 'replace'))

    text_now, _s, _r, _u = GDICT.build(raw, GL_VI)
    now = parse_text_dict(text_now)

    real_extra = GDICT.Extra

    class Stripped(real_extra):
        def __init__(self, *a, **k):
            real_extra.__init__(self, *a, **k)
            for key in drop_keys:
                self.over_key.pop(key, None)

    GDICT.Extra = Stripped
    try:
        text_full, _s2, _r2, _u2 = GDICT.build(raw, GL_VI)
    finally:
        GDICT.Extra = real_extra
    full = parse_text_dict(text_full)
    return now, full, zh


# ---------------------------------------------------------------- quet tham chieu khung

def scan_layouts(iface=IFACE):
    """-> ({key: [usage]}, {key: set(frame)} tham chieu THO, {frame: dir}, stats).

    usage = dict(frame, window, type, w, h, font_px, text, only)  ('only' = ca o chi chua #{KEY}).

    CYS-I18NSCOPE: quet HAI LAN tren cung mot tep (luat "dem hai lan", DIEU-PHOI muc 17):
      (a) qua `FIT.parse_layout` - cho be rong o, nhung CHI thay cua so co thuoc tinh `Text`;
      (b) grep BYTE tho `#{...}` tren ca .layout.xml lan .lua - khong bo sot, nhung khong co be rong.
    Do lan dau: hai phep lech o 6/869 khoa, LUON theo huong (b) thay them khung ma (a) bo sot
    (vd `TeamPT`, `NoDiffMatch_TeamInfo`). Vi vay tap khung SU DUNG lay theo (b) hop (a);
    be rong chi lay tu (a). Khung chi thay o (b) bi danh dau 'khong do duoc be rong'.
    """
    by_key = collections.defaultdict(list)
    lua_ref = collections.defaultdict(set)
    dir_frames = collections.defaultdict(set)   # ten thu muc (chu thuong) -> tap khung ben trong
    known = set()                               # moi ten khung da thay (chu thuong)
    stats = collections.Counter()
    for dp, _d, fs in os.walk(iface):
        for fn in fs:
            low = fn.lower()
            path = os.path.join(dp, fn)
            if not (low.endswith('.layout.xml') or low.endswith('.lua')):
                continue
            frame = fn.split('.')[0]
            dir_frames[os.path.basename(dp).lower()].add(frame.lower())
            known.add(frame.lower())
            with open(path, 'rb') as f:
                blob = f.read()
            if blob[:2] in (b'\xff\xfe', b'\xfe\xff'):
                blob = blob[2:].decode('utf-16-le' if blob[:2] == b'\xff\xfe' else 'utf-16-be').encode('utf-8')
            for m in RAWREF.finditer(blob):
                try:
                    lua_ref[m.group(1).decode('utf-8')].add(frame)
                except UnicodeDecodeError:
                    stats['rawref_undecodable'] += 1
            if low.endswith('.lua'):
                stats['luas'] += 1
                continue
            stats['layouts'] += 1
            try:
                text = FIT.decode_xml(open(path, 'rb').read())
            except (UnicodeDecodeError, OSError):
                stats['layout_unreadable'] += 1
                continue
            for typ, name, tval, font, w, h in FIT.parse_layout(text):
                keys = KEYREF_ANY.findall(tval)
                if not keys:
                    continue
                only = bool(KEYREF_ONLY.match(tval.strip()))
                short = typ.split('/')[-1]
                for k in keys:
                    by_key[k].append({'frame': frame, 'window': name, 'type': short,
                                      'w': round(w, 1), 'h': round(h, 1),
                                      'font_px': FIT.font_px(font), 'text': tval, 'only': only})
                    stats['usages'] += 1
    return by_key, lua_ref, known, dict(dir_frames), dict(stats)


# ---------------------------------------------------------------- do "vua / khong vua"

def resolve_budget_frames(bframe, known_frames, frame_dir):
    """Ten khung trong ghi chu -> tap ten khung THAT (chu thuong) + kieu khop.

    BA bay da sap that khi do lan dau, moi bay lam mot nhom khoa bi goi OAN la "ro ri":
      1. lech hoa/thuong  : ghi chu 'FRIENDSEARCH' <-> tep 'FriendSearch.layout.xml' (15 ghi chu);
         cung the o phia SU DUNG: khung 'friend' (mot tep .lua chu thuong) va 'Friend' la MOT.
      2. ten THU MUC      : 'GuildLeague', 'JingMai' khong phai ten layout nao ca - chung la ten
         THU MUC chua nhieu layout (JingMai/ chua SelfJingMai.layout.xml).
      3. thu muc TRUNG ten voi mot layout: 'GMChat' vua la thu muc (chua GMChat, GMConnectInfo,
         GMMark) vua la mot layout. Ghi chu khong phan biet duoc hai nghia, nen lay CA HAI -
         tap ngan sach rong hon => bao it "ro ri" hon => KHONG thoi phong con so ban duoc.
    Tra ve tap ten da ha chu thuong; moi so sanh khung o noi khac cung phai ha chu thuong.
    """
    low = bframe.lower()
    out, kinds = set(), []
    if low in known_frames:
        out.add(low)
        kinds.append('exact' if bframe in known_frames else 'case')
    ind = frame_dir.get(low)
    if ind:
        out |= ind
        kinds.append('dir')
    if not out:
        return {low}, 'unmatched'
    return out, '+'.join(kinds)


def measure(budget, now, full, zh, by_key, lua_ref, known=None, frame_dir=None, tol=1.0):
    """-> (leak rows, rescue summary). Mot `usage` duoc tinh la CUU duoc khi:
       - o do dang hien ban rut gon (ban day du KHAC ban rut gon), VA
       - khung chua o KHONG nam trong tap khung ngan sach, VA
       - o cao <= 40 px (o cao hon tu xuong dong nen khong thuoc lop loi nay), VA
       - est_width(ban day du) <= be rong o * tol, o MOI o cua khung do.
    """
    frame_dir = frame_dir or {}
    known = known if known is not None else set()
    leaks, rescue_usage, rescue_key = [], 0, 0
    multiline_usage = 0
    frames_rescued = collections.Counter()
    match_kind = collections.Counter()
    for key, (px, bframe) in sorted(budget.items()):
        uses = by_key.get(key, [])
        frames = {f.lower() for f in lua_ref.get(key, set())} | {u['frame'].lower() for u in uses}
        bset, kind = resolve_budget_frames(bframe, known, frame_dir)
        match_kind[kind] += 1
        other = frames - bset
        if not other:
            continue                      # chi dung o dung khung ngan sach -> khong ro ri
        short_vi, full_vi = now.get(key, ''), full.get(key, '')
        row = {'key': key, 'zh': zh.get(key, ''), 'short': short_vi, 'full': full_vi,
               'budget_px': px, 'budget_frame': bframe, 'budget_resolved': sorted(bset),
               'budget_match': kind,
               'frames': sorted(frames), 'other_frames': sorted(other),
               'no_width_frames': sorted(other - {u['frame'].lower() for u in uses}),
               'usages': [], 'rescued_frames': [], 'changed': short_vi != full_vi}
        best = {}
        for u in uses:
            e_full = FIT.est_width(full_vi, u['font_px'])
            e_short = FIT.est_width(short_vi, u['font_px'])
            fits = (u['w'] > 0 and e_full <= u['w'] * tol)
            row['usages'].append(dict(u, est_full=round(e_full, 1), est_short=round(e_short, 1),
                                      full_fits=fits))
            if u['frame'].lower() in bset:
                continue
            if u['h'] > 40:
                multiline_usage += 1
                continue
            cur = best.get(u['frame'].lower())
            best[u['frame'].lower()] = fits if cur is None else (cur and fits)
        rescued = sorted(f for f, ok in best.items() if ok)
        row['rescued_frames'] = rescued
        if short_vi != full_vi:
            leaks.append(row)
            if rescued:
                rescue_key += 1
                for f in rescued:
                    frames_rescued[f] += 1
                rescue_usage += sum(1 for u in row['usages']
                                    if u['frame'].lower() in rescued and u['h'] <= 40 and u['full_fits'])
        else:
            row['note'] = 'ghi de KHONG lam doi gia tri (ban day du trung ban rut gon)'
            leaks.append(row)
    summary = {'tol': tol, 'leak_keys': len(leaks),
               'leak_keys_value_changed': len([r for r in leaks if r['changed']]),
               'rescued_keys': rescue_key, 'rescued_usages': rescue_usage,
               'rescued_frames': len(frames_rescued),
               'multiline_usages_skipped': multiline_usage,
               'budget_frame_match': dict(match_kind),
               'top_frames': frames_rescued.most_common(15)}
    return leaks, summary


# ---------------------------------------------------------------- doi chung

def selftest():
    """Bon phep doi chung. In PASS/FAIL, thoat 1 khi co FAIL."""
    ok = True

    def chk(name, cond, detail=''):
        nonlocal ok
        print(('PASS ' if cond else 'FAIL ') + name + (' | ' + detail if detail else ''))
        if not cond:
            ok = False

    # bo do gia lap: khong can den dia, chi kiem LOGIC quyet dinh
    zh = {'K_LEAK': 'zh1', 'K_ONLY': 'zh2', 'K_TIGHT': 'zh3'}
    now = {'K_LEAK': 'T.pháp', 'K_ONLY': 'Ngắn', 'K_TIGHT': 'Ngắn'}
    full = {'K_LEAK': 'Thân pháp:', 'K_ONLY': 'Chuỗi rất dài dài dài', 'K_TIGHT': 'Chuỗi rất dài dài dài'}
    budget = {'K_LEAK': (30, 'Pet'), 'K_ONLY': (30, 'Pet'), 'K_TIGHT': (30, 'Pet')}
    by_key = {
        'K_LEAK': [{'frame': 'Pet', 'window': 'a', 'type': 'StaticText', 'w': 30.0, 'h': 20.0,
                    'font_px': 13.0, 'text': '#{K_LEAK}', 'only': True},
                   {'frame': 'SelfEquip', 'window': 'b', 'type': 'StaticText', 'w': 120.0, 'h': 20.0,
                    'font_px': 13.0, 'text': '#{K_LEAK}', 'only': True}],
        'K_ONLY': [{'frame': 'Pet', 'window': 'a', 'type': 'StaticText', 'w': 30.0, 'h': 20.0,
                    'font_px': 13.0, 'text': '#{K_ONLY}', 'only': True}],
        'K_TIGHT': [{'frame': 'Pet', 'window': 'a', 'type': 'StaticText', 'w': 30.0, 'h': 20.0,
                     'font_px': 13.0, 'text': '#{K_TIGHT}', 'only': True},
                    {'frame': 'Tiny', 'window': 'b', 'type': 'StaticText', 'w': 36.0, 'h': 20.0,
                     'font_px': 13.0, 'text': '#{K_TIGHT}', 'only': True}],
    }
    kn = {'pet', 'selfequip', 'tiny', 'friendsearch', 'selfjingmai'}
    fdir = {'pet': {'pet'}, 'selfequip': {'selfequip'}, 'tiny': {'tiny'},
            'friendsearch': {'friendsearch'}, 'jingmai': {'selfjingmai'}}
    leaks, summ = measure(budget, now, full, zh, by_key, {}, kn, fdir, tol=1.0)
    idx = {r['key']: r for r in leaks}
    chk('AM1 khoa chi dung trong khung ngan sach KHONG bi goi la ro ri',
        'K_ONLY' not in idx, 'keys=%s' % sorted(idx))
    chk('DUONG khoa dung o khung khac HIEN ra la ro ri', 'K_LEAK' in idx)
    chk('DUONG khung rong duoc tinh la CUU duoc',
        'K_LEAK' in idx and idx['K_LEAK']['rescued_frames'] == ['selfequip'],
        'rescued=%s' % (idx.get('K_LEAK', {}).get('rescued_frames')))
    chk('AM3 khung thu hai VAN hep thi KHONG duoc tinh la cuu',
        'K_TIGHT' in idx and idx['K_TIGHT']['rescued_frames'] == [],
        'rescued=%s' % (idx.get('K_TIGHT', {}).get('rescued_frames')))
    # AM2: bom mot ghi de gia - ban "rut gon" ROI cung khong vua o 36 px -> khong duoc cuu
    chk('AM2 dem cho cuu duoc khop voi so khung cuu duoc',
        summ['rescued_keys'] == 1 and summ['rescued_usages'] == 1,
        'keys=%d usages=%d' % (summ['rescued_keys'], summ['rescued_usages']))
    # AM4/AM5: hai bay da SAP THAT o lan chay dau - ten khung trong ghi chu lech hoa/thuong,
    # va ten khung la ten THU MUC chu khong phai ten layout. Ca hai lam khoa bi goi OAN la ro ri.
    b2 = {'K_CASE': (60, 'FRIENDSEARCH'), 'K_DIR': (70, 'JingMai')}
    n2 = {'K_CASE': 'Ngắn', 'K_DIR': 'Ngắn'}
    f2 = {'K_CASE': 'Chuỗi đầy đủ', 'K_DIR': 'Chuỗi đầy đủ'}
    u2 = {'K_CASE': [{'frame': 'FriendSearch', 'window': 'a', 'type': 'StaticText', 'w': 60.0,
                      'h': 20.0, 'font_px': 13.0, 'text': '#{K_CASE}', 'only': True}],
          'K_DIR': [{'frame': 'SelfJingMai', 'window': 'a', 'type': 'StaticText', 'w': 70.0,
                     'h': 20.0, 'font_px': 13.0, 'text': '#{K_DIR}', 'only': True}]}
    l2, _s2 = measure(b2, n2, f2, {}, u2, {}, kn, fdir, tol=1.0)
    chk('AM4 ghi chu lech HOA/THUONG van nhan dung khung ngan sach',
        'K_CASE' not in {r['key'] for r in l2}, 'leaks=%s' % sorted(r['key'] for r in l2))
    chk('AM5 ghi chu la ten THU MUC van nhan dung khung ngan sach',
        'K_DIR' not in {r['key'] for r in l2}, 'leaks=%s' % sorted(r['key'] for r in l2))
    print('SELFTEST', 'OK' if ok else 'FAILED')
    return 0 if ok else 1


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--out', default=os.path.join(CYS, 'Build', 'Logs', '2026-09-19-i18n-scope', 'leak-table.json'))
    ap.add_argument('--rescue', default=os.path.join(CYS, 'Build', 'Logs', '2026-09-19-i18n-scope', 'rescue.json'))
    ap.add_argument('--tol', type=float, default=1.0)
    ap.add_argument('--also-tol', default='0.9,1.1')
    ap.add_argument('--selftest', action='store_true')
    args = ap.parse_args()
    if args.selftest:
        return selftest()
    budget = load_budget()
    now, full, zh = build_dicts(set(budget))
    by_key, lua_ref, known, frame_dir, sstats = scan_layouts()
    leaks, summ = measure(budget, now, full, zh, by_key, lua_ref, known, frame_dir, tol=args.tol)
    summ['scan'] = sstats
    summ['budget_keys'] = len(budget)
    summ['sensitivity'] = {}
    for t in [float(x) for x in args.also_tol.split(',') if x]:
        _l, s2 = measure(budget, now, full, zh, by_key, lua_ref, known, frame_dir, tol=t)
        summ['sensitivity'][str(t)] = {'rescued_keys': s2['rescued_keys'],
                                       'rescued_usages': s2['rescued_usages'],
                                       'rescued_frames': s2['rescued_frames']}
    os.makedirs(os.path.dirname(args.out), exist_ok=True)
    with open(args.out, 'w', encoding='utf-8') as f:
        json.dump(leaks, f, ensure_ascii=False, indent=1)
    with open(args.rescue, 'w', encoding='utf-8') as f:
        json.dump(summ, f, ensure_ascii=False, indent=1)
    print(json.dumps(summ, ensure_ascii=False, indent=1))
    return 0


if __name__ == '__main__':
    sys.exit(main())
