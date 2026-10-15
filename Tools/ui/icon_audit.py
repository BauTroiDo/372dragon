#!/usr/bin/env python3
"""CYS-ICON - doi chieu HAI CHIEU giua bieu tuong DU LIEU TRO TOI va bieu tuong CO MAT.

CHI DOC. Khong ghi vao Assets/, khong sua bang nao.

Cau hoi: "day du icon chua?" -> khong phai "co bao nhieu tep anh" ma la
         "bao nhieu tham chieu bieu tuong KHONG giai duoc thanh mot anh that".

Hai duong giai ten cua client (doc tu ma, khong suy tu ten cot):
  A1  CUIIconsManager::Initial  (Src/Client/CEGUISystem/UIIconsMng.cpp:23-49)
      duyet MOI Imageset da dang ky, GIU lai nhung imageset co TEN TEP TEXTURE bat dau bang
      5 ky tu "Icons", roi nhet moi <Image Name=...> vao MOT map phang theo TEN ANH.
      GetIconFullName(ten) tra "set:<imageset> image:<ten>"; ten khong co trong map thi tra
      dung chuoi "set:X image:X" (UIIconsMng.cpp:54) -> CEGUI giai ra anh NULL -> O TRONG.
      std::map::insert GIU BAN DAU khi trung khoa -> ten trung bi bo, ghi lai chu khong gop.
  A2  PropertyHelper::stringToImage (Src/ThirdParty/CEGUI-0.4.1/CEGUI/src/CEGUIPropertyHelper.cpp:134)
      sscanf(" set:%127s image:%127s") roi tra cuu ImagesetManager. Dung khi o du lieu / thuoc tinh
      layout DA la mot chuoi "set:S image:I" day du. Pham vi la MOI imageset, khong rieng ho Icons.
      %s BO QUA khoang trang dau -> "image:  Foo" van hop le (17 dong CY dung dang nay).

Ba lop thieu khac nhau, dem tep khong phan biet duoc:
  1. o du lieu tro toi mot TEN ANH khong ton tai            -> MISSING
  2. o du lieu tro toi mot IMAGESET khong ton tai           -> NO_SUCH_SET
  3. imageset co, anh co, nhung TEP TEXTURE khong co tren dia -> ca imageset trang

Moi con so lay tu --out <file>.json, khong tu bang in ra man hinh.
Moi ten tep va moi o chuoi doc o MUC BYTE (latin1 round-trip), khong bao gio qua cp1252/utf-8.

Dung:
  python -B Tools/ui/icon_audit.py --data Assets/CanonicalCY/Data --out Build/Logs/<ngay>/icon-audit.json
"""
import argparse
import json
import os
import re
import struct
from collections import Counter
from pathlib import Path

TYPE_NAMES = ('INT', 'FLOAT', 'STRING', 'UINT', 'DWORDTIME')

# (tep, cot icon, cot id, cot ten, nguoi choi gap o dau)
# Cot lay tu chu thich `// [N]` tren truong szIcon/szIconName cua ban ghi:
#   Src/Engine/Interface/TDDBC_Struct.h va Src/Shared/Common/GameStruct_Skill.h
# Ten tep lay tu bang bang cua CDataBaseSystem: Src/Client/WXClient/DBC/GMDataBase.cpp:147+
DBC_TABLES = [
    ('EquipBase.txt',           18,  0,  13, 'trang bi + trang phuc + toa ky + huyen suc (tui do, cua hang)'),
    ('CommonItem.txt',           5,  0,   6, 'vat pham thuong (tui do, cua hang)'),
    ('GemInfo.txt',              5,  0,   7, 'ngoc / kham nam'),
    ('StoreMapItem.txt',         5,  0,   6, 'ban do kho bau'),
    ('WhiteEquipBase.txt',      88,  0,  -1, 'trang bi trang'),
    ('GreenEquipBase.txt',      20,  0,  -1, 'trang bi luc'),
    ('BlueEquipBase.txt',       86,  0,  -1, 'trang bi lam'),
    ('SkillTemplate_V1.txt',     3,  0,   2, 'ky nang chien dau (khung ky nang, thanh phim tat)'),
    ('XinFa_V1.txt',             4,  0,   2, 'tam phap'),
    ('Ability.txt',             11,  0,   1, 'ky nang doi song'),
    ('ChatMood.txt',            10,  0,   1, 'dong tac chat'),
    ('AttackTraits.txt',         2,  0,   1, 'dac tinh tan cong tran thu'),
    ('ImpactSEData_V1.txt',      3,  0,  -1, 'buff / trang thai'),
    ('MonsterAttrExTable.txt',  42,  0,   1, 'anh dai dien quai / NPC'),
]

RX_SET = re.compile(rb'<Imageset\s+Name="([^"]*)"\s+Filename="([^"]*)"')
RX_FILE = re.compile(rb'<Imageset\b[^>]*?\bImagefile="([^"]*)"')
RX_IMG = re.compile(rb'<Image\s+Name="([^"]*)"')
# sscanf(" set:%127s image:%127s") - xem CEGUIPropertyHelper.cpp:141
RX_FULL = re.compile(r'^\s*set:(\S+)\s*image:\s*(\S+)')
RX_UIREF = re.compile(rb'set:\s*([^\s"\'<>]+)\s*image:\s*([^\s"\'<>]+)')
RX_TEMPLATE = re.compile(r'[%.\[\]()$]')
RX_PAGE = re.compile(r'^(.*?)(\d*)_(\d+)$')


class Table:
    """Bang DBC nhi phan 00CCBBDD, chi doc. O STRING tra ve BYTE THO, khong giai ma."""

    def __init__(self, path):
        raw = Path(path).read_bytes()
        if raw[:4] != b'\x00\xcc\xbb\xdd':
            raise ValueError('khong phai DBC nhi phan: %s' % path)
        _, fields, records, strings = struct.unpack_from('<Iiii', raw, 0)
        self.fields, self.records = fields, records
        kinds = struct.unpack_from('<%dI' % fields, raw, 16)
        self.types = [TYPE_NAMES[k] if k < len(TYPE_NAMES) else 'T%d' % k for k in kinds]
        base = 16 + 4 * fields
        self.cells = struct.unpack_from('<%dI' % (fields * records), raw, base)
        self.pool = raw[base + 4 * fields * records: base + 4 * fields * records + strings]

    def cell(self, r, c):
        v = self.cells[r * self.fields + c]
        t = self.types[c]
        if t == 'STRING':
            if v >= len(self.pool):
                return b''
            e = self.pool.find(b'\0', v)
            return self.pool[v:e] if e >= 0 else self.pool[v:]
        if t == 'FLOAT':
            return struct.unpack('<f', struct.pack('<I', v))[0]
        if t == 'INT':
            return struct.unpack('<i', struct.pack('<I', v))[0]
        return v

    def typestr(self):
        return ''.join({'INT': 'I', 'FLOAT': 'F', 'STRING': 'S', 'UINT': 'U',
                        'DWORDTIME': 'D'}.get(t, '?') for t in self.types)


def build_supply(data):
    """A1 + A2 + kiem tra tep texture co that (muc byte)."""
    IF = data / 'InterfaceFolder'
    raw = (IF / 'Schema' / 'WoWLookSkin.scheme.xml').read_bytes()
    files = set()
    root_b = os.fsencode(str(IF))
    for dp, _dn, fns in os.walk(root_b):
        for f in fns:
            files.add(os.path.join(dp, f)[len(root_b) + 1:].replace(b'\\', b'/').lower())
    icons, pairs = {}, {}
    dup, missing_xml, missing_tex, zero_tex = 0, [], [], []
    rows = 0
    for m in RX_SET.finditer(raw):
        rows += 1
        setname = m.group(1).decode('latin1')
        rel = m.group(2).decode('latin1').replace('\\', '/')
        p = IF / rel
        if not p.exists():
            missing_xml.append((setname, rel))
            continue
        b = p.read_bytes()
        mf = RX_FILE.search(b)
        tex = mf.group(1) if mf else b''
        imgs = set(x.group(1).decode('latin1') for x in RX_IMG.finditer(b))
        pairs.setdefault(setname, set()).update(imgs)
        texkey = tex.replace(b'\\', b'/').lower()
        if tex and texkey not in files:
            missing_tex.append({'set': setname, 'texture': tex.decode('latin1'), 'images': len(imgs)})
        elif tex and (IF / tex.decode('latin1').replace('\\', '/')).stat().st_size == 0:
            zero_tex.append(setname)
        if tex[:5] == b'Icons':
            for im in imgs:
                if im in icons:
                    dup += 1
                else:
                    icons[im] = setname
    return {'scheme_rows': rows, 'imagesets': len(pairs), 'icon_names': len(icons),
            'icon_dup_dropped': dup, 'pairs_total': sum(len(v) for v in pairs.values()),
            'missing_xml': missing_xml, 'missing_texture': missing_tex,
            'zero_byte_texture': zero_tex, 'files_indexed': len(files)}, icons, pairs


def classify(cell, icons, pairs):
    """-> (verdict, cause, proposed) theo dung duong giai cua client."""
    if cell == '' or cell == '-1':
        return 'NONE', '', None
    m = RX_FULL.match(cell)
    if m:
        st, im = m.group(1), m.group(2)
        if st not in pairs:
            return 'BAD', 'NO_SUCH_SET', None
        if im not in pairs[st]:
            fam = re.match(r'^(.*?)\d*$', im.split('_')[0]).group(1)
            sfam = re.match(r'^(.*?)\d*$', st).group(1)
            return 'BAD', 'CROSS_FAMILY' if fam != sfam else 'NO_SUCH_IMAGE', None
        return 'OK', '', None
    if cell in icons:
        return 'OK', '', None
    mm = RX_PAGE.match(cell)
    if mm:
        fam, page, idx = mm.group(1), mm.group(2), int(mm.group(3))
        cur = fam + page
        if cur not in pairs:
            return 'BAD', 'NO_SUCH_SET', None
        n, p = idx, int(page) if page else 0
        for _ in range(40):                       # trang 16 o: tim trang ke tiep cung ho
            c = '%s%s' % (fam, p if p else '')
            cnt = len(pairs.get(c, ()))
            if not cnt:
                break
            if n <= cnt:
                cand = '%s_%d' % (c, n)
                if c == cur:
                    break
                return ('BAD', 'PAGE_OVERFLOW', cand) if cand in pairs[c] else ('BAD', 'NO_SUCH_IMAGE', None)
            n -= cnt
            p = (p or 1) + 1
    return 'BAD', 'NO_SUCH_IMAGE', None


def scan_dbc(data, icons, pairs):
    cfg = data / 'ConfigFolder'
    out, bad = [], []
    for fn, ic, idc, namec, where in DBC_TABLES:
        p = cfg / fn
        if not p.exists():
            out.append({'file': fn, 'error': 'khong co tep'})
            continue
        t = Table(p)
        if ic >= t.fields or t.types[ic] != 'STRING':
            out.append({'file': fn, 'error': 'COT SAI: [%d] la %s, types=%s'
                        % (ic, t.types[ic] if ic < t.fields else 'ngoai bang', t.typestr())})
            continue
        c = Counter()
        for r in range(t.records):
            cell = t.cell(r, ic).decode('latin1')
            v, cause, prop = classify(cell, icons, pairs)
            c[v if v != 'BAD' else cause] += 1
            if v == 'BAD':
                bad.append({'file': fn, 'id': t.cell(r, idc), 'cell': cell,
                            'cause': cause, 'proposed': prop})
        out.append({'file': fn, 'where': where, 'icon_col': ic, 'types': t.typestr(),
                    'rows': t.records, 'OK': c['OK'], 'NONE': c['NONE'],
                    'BAD': t.records - c['OK'] - c['NONE'],
                    'by_cause': {k: v for k, v in c.items() if k not in ('OK', 'NONE')}})
    return out, bad


def scan_ui(data, pairs):
    """Tham chieu viet thang trong tep giao dien.
    HARD = layout/looknfeel: luon la chuoi nguyen van -> hong la chac chan.
    SOFT = lua: nhieu chuoi la khuon printf hoac nua cua phep noi -> CHAN TREN, co duong tinh gia.
    """
    IF = data / 'InterfaceFolder'

    def run(pats, drop_templates):
        tot, bad, where, skipped = 0, Counter(), {}, 0
        for pat in pats:
            for p in IF.rglob(pat):
                b = p.read_bytes()
                for m in RX_UIREF.finditer(b):
                    st = m.group(1).decode('latin1')
                    im = m.group(2).decode('latin1')
                    tot += 1
                    if st in pairs and im in pairs[st]:
                        continue
                    if drop_templates and (RX_TEMPLATE.search(st) or RX_TEMPLATE.search(im)):
                        skipped += 1
                        continue
                    k = (st, im, 'NO_SUCH_SET' if st not in pairs else 'NO_SUCH_IMAGE')
                    bad[k] += 1
                    where.setdefault(k, str(p.relative_to(IF)))
        return {'refs': tot, 'broken_occ': sum(bad.values()), 'broken_distinct': len(bad),
                'skipped_templates': skipped,
                'rows': [{'set': k[0], 'image': k[1], 'why': k[2], 'n': v, 'file': where[k]}
                         for k, v in bad.most_common()]}
    return {'hard': run(['*.layout.xml', '*.looknfeel.xml'], True),
            'soft_upper_bound': run(['*.lua'], True)}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--data', default='Assets/CanonicalCY/Data')
    ap.add_argument('--out', required=True, help='tep json - LAY SO O DAY, khong lay o bang in ra')
    a = ap.parse_args()
    data = Path(a.data).resolve()
    supply, icons, pairs = build_supply(data)
    dbc, bad = scan_dbc(data, icons, pairs)
    ui = scan_ui(data, pairs)
    tot = Counter()
    for x in dbc:
        for k in ('rows', 'OK', 'NONE', 'BAD'):
            tot[k] += x.get(k, 0)
    res = {'data': str(data), 'supply': supply, 'dbc': dbc, 'dbc_total': dict(tot),
           'dbc_bad_rows': bad, 'ui': ui,
           'grand_total_refs': tot['rows'] + ui['hard']['refs'],
           'grand_total_broken': tot['BAD'] + ui['hard']['broken_occ']}
    Path(a.out).parent.mkdir(parents=True, exist_ok=True)
    Path(a.out).write_text(json.dumps(res, ensure_ascii=False, indent=1), encoding='utf-8')

    print('DINH NGHIA DEM: rows = ban ghi cua bang nhi phan (khong co dong tieu de);')
    print('  OK = giai ra mot anh that; NONE = o rong hoac "-1" (co y khong co icon);')
    print('  BAD = giai ra anh NULL -> nguoi choi thay O TRONG.')
    print()
    print('CUNG: %d dong scheme -> %d imageset, %d ten icon (ho Icons), %d cap (set,image)'
          % (supply['scheme_rows'], supply['imagesets'], supply['icon_names'], supply['pairs_total']))
    print('      imageset thieu tep texture: %d | texture 0 byte: %d | imageset.xml thieu: %d'
          % (len(supply['missing_texture']), len(supply['zero_byte_texture']), len(supply['missing_xml'])))
    print()
    print('%-26s %7s %7s %7s %7s  %s' % ('BANG', 'rows', 'NONE', 'OK', 'BAD', 'nguoi choi gap o dau'))
    for x in dbc:
        if 'error' in x:
            print('%-26s  !! %s' % (x['file'], x['error']))
            continue
        print('%-26s %7d %7d %7d %7d  %s' % (x['file'], x['rows'], x['NONE'], x['OK'], x['BAD'], x['where']))
    print('%-26s %7d %7d %7d %7d' % ('TONG', tot['rows'], tot['NONE'], tot['OK'], tot['BAD']))
    print()
    print('GIAO DIEN (chuoi nguyen van trong layout/looknfeel): %d tham chieu, %d hong'
          % (ui['hard']['refs'], ui['hard']['broken_occ']))
    print('GIAO DIEN (lua, CHAN TREN, co duong tinh gia)      : %d tham chieu, %d hong'
          % (ui['soft_upper_bound']['refs'], ui['soft_upper_bound']['broken_occ']))
    print()
    print('TONG CONG: %d tham chieu, %d hong (%.3f%%)'
          % (res['grand_total_refs'], res['grand_total_broken'],
             100.0 * res['grand_total_broken'] / max(1, res['grand_total_refs'])))
    print('json:', a.out)


if __name__ == '__main__':
    main()
