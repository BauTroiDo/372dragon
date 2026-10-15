# -*- coding: utf-8 -*-
"""wardrobe: doi chieu bang DBC InterfaceEx (801) voi tep layout/script CO THAT tren dia.

Cau hoi phai tra loi: "thieu .layout.xml => khung mo ra TRONG" dung hay sai?

Bo do nay KHONG tra loi cau do mot minh. No chi cung cap DANH SACH CO THAT de
phep do live co cho ma ban vao:
  - khung nao CO dong DBC (tuc la CUIWindowMng thuc su tao CUIWindowItem cho no)
  - khung nao dong DBC tro toi mot tep layout KHONG TON TAI
  - khung nao co .lua nhung KHONG co dong DBC (=> khong bao gio duoc tao)

DOI CHUNG AM bat buoc: script phai bao duoc mot khung "binh thuong" la BINH THUONG.
Neu moi khung deu ra "thieu" thi chinh bo do sai duong dan, khong phai du lieu hong.

Dinh dang DBC: Tools/ui-fit/dbc_sources.py::read_column (magic 00CCBBDD).
"""

import os
import struct
import sys

MAGIC = b'\x00\xcc\xbb\xdd'


def read_dbc(path):
    """Doc ca bang -> (kinds, rows) voi rows[r][c] = int hoac str."""
    raw = open(path, 'rb').read()
    if raw[:4] != MAGIC:
        raise ValueError('%s khong phai DBC nhi phan' % path)
    _, nf, nr, ns = struct.unpack_from('<Iiii', raw, 0)
    kinds = struct.unpack_from('<%dI' % nf, raw, 16)
    base = 16 + 4 * nf
    cells = struct.unpack_from('<%dI' % (nf * nr), raw, base)
    pool = raw[base + 4 * nf * nr: base + 4 * nf * nr + ns]

    def s(off):
        if off >= len(pool):
            return ''
        e = pool.find(b'\0', off)
        b = pool[off:e if e >= 0 else len(pool)]
        try:
            return b.decode('utf-8')
        except UnicodeDecodeError:
            return b.decode('gb18030', 'replace')

    rows = []
    for r in range(nr):
        row = []
        for c in range(nf):
            v = cells[r * nf + c]
            if kinds[c] == 2:
                row.append(s(v))
            else:
                row.append(struct.unpack('<i', struct.pack('<I', v))[0])
        rows.append(row)
    return kinds, rows


def main():
    if len(sys.argv) < 3:
        print('dung: wardrobe_frame_audit.py <duong dan Data> <tep ket qua>')
        return 2
    data = sys.argv[1]
    out = sys.argv[2]
    dbc = os.path.join(data, 'ConfigFolder', 'InterfaceEx.txt')
    iface = os.path.join(data, 'InterfaceFolder')

    kinds, rows = read_dbc(dbc)
    lines = []
    lines.append('# wardrobe: doi chieu InterfaceEx (DBC 801) voi tep tren dia')
    lines.append('data      = %s' % data)
    lines.append('dbc       = %s' % dbc)
    lines.append('cot       = %d, dong = %d' % (len(kinds), len(rows)))
    lines.append('')

    # Duong dan trong DBC la dang "Schema\\X.layout.xml" hoac "InterfaceFolder\\X\\X.layout.xml"?
    # Khong suy - in 5 dong dau nguyen van de nguoi doc tu thay.
    lines.append('## 5 dong dau nguyen van (de kiem dang duong dan, KHONG suy tu ten cot)')
    for r in rows[:5]:
        lines.append('  %r' % (r[:5],))
    lines.append('')

    missing_layout = []
    missing_script = []
    ok = 0
    seen = {}
    for r in rows:
        name, layout, script = r[1], r[2], r[3]
        seen[name] = (layout, script)
        lp = os.path.join(iface, layout.replace('\\', os.sep)) if layout else ''
        sp = os.path.join(iface, script.replace('\\', os.sep)) if script else ''
        has_l = bool(layout) and os.path.isfile(lp)
        has_s = bool(script) and os.path.isfile(sp)
        if not has_l:
            missing_layout.append((r[0], name, layout))
        if not has_s:
            missing_script.append((r[0], name, script))
        if has_l and has_s:
            ok += 1

    lines.append('## Tong ket theo TUNG DONG')
    lines.append('dong DBC                      : %d' % len(rows))
    lines.append('du ca layout + script tren dia: %d' % ok)
    lines.append('dong tro toi layout KHONG CO  : %d' % len(missing_layout))
    lines.append('dong tro toi script KHONG CO  : %d' % len(missing_script))
    lines.append('')

    lines.append('## Dong DBC tro toi layout KHONG TON TAI (tung dong)')
    for i, n, l in missing_layout:
        lines.append('  id=%-6d %-34s layout=%s' % (i, n, l))
    lines.append('')

    lines.append('## Dong DBC tro toi script KHONG TON TAI (tung dong)')
    for i, n, s_ in missing_script:
        lines.append('  id=%-6d %-34s script=%s' % (i, n, s_))
    lines.append('')

    # Chieu nguoc: thu muc co .lua nhung KHONG co dong DBC.
    lua_only = []
    no_layout_on_disk = []
    if os.path.isdir(iface):
        for d in sorted(os.listdir(iface)):
            dp = os.path.join(iface, d)
            if not os.path.isdir(dp):
                continue
            has_lua = os.path.isfile(os.path.join(dp, d + '.lua'))
            has_lay = os.path.isfile(os.path.join(dp, d + '.layout.xml'))
            if has_lua and not has_lay:
                no_layout_on_disk.append(d)
            if has_lua and d not in seen:
                lua_only.append(d)

    lines.append('## Thu muc co <ten>.lua nhung KHONG co <ten>.layout.xml tren dia (tung dong)')
    lines.append('so luong: %d' % len(no_layout_on_disk))
    for d in no_layout_on_disk:
        in_dbc = 'CO dong DBC -> layout=%s' % seen[d][0] if d in seen else 'KHONG co dong DBC'
        lines.append('  %-34s %s' % (d, in_dbc))
    lines.append('')

    lines.append('## Thu muc co .lua nhung KHONG co dong DBC nao mang ten do (tung dong)')
    lines.append('so luong: %d' % len(lua_only))
    for d in lua_only:
        lines.append('  %s' % d)
    lines.append('')

    # DOI CHUNG AM: mot khung chac chan binh thuong phai ra "du ca hai".
    lines.append('## DOI CHUNG AM (bo do phai biet TRUOT)')
    for probe in ('Shop', 'SelfEquip', 'DressClosetFrame', 'KHUNG_KHONG_TON_TAI_XYZ'):
        if probe in seen:
            l, s_ = seen[probe]
            lp = os.path.join(iface, l.replace('\\', os.sep))
            lines.append('  %-28s dong DBC CO, layout=%s ton tai=%s' % (probe, l, os.path.isfile(lp)))
        else:
            lines.append('  %-28s KHONG co dong DBC  <- phai thay dong nay cho KHUNG_KHONG_TON_TAI_XYZ' % probe)

    txt = '\n'.join(lines) + '\n'
    with open(out, 'w', encoding='utf-8') as f:
        f.write(txt)
    print(txt)
    return 0


if __name__ == '__main__':
    sys.exit(main())
