# -*- coding: utf-8 -*-
"""scenes-lo2: SINH ke hoach dong DBC `data/scenes-lo2-rows.json` cho 17 ban do nhap tu GL.

NGUON 24 cot: bang client GL `Assets/Canonical/Data/ConfigFolder/SceneDefineEx.txt` (text, 24 cot,
ten tieng Viet - dung la bang cua client_GL). Da doi chieu 17/09 voi bang SERVER
`R/configs/SceneDefineEx.txt` (GBK): 19/19 dong nguon GIONG NHAU o moi cot tru cot chu [1]/[22]
(`Build/Logs/2026-09-17-scenes-lo2/13-server-facts.json`), nen lay ban tieng Viet la dung y
"noi dung 24 cot tu bang server" ma khong phai dich lai ten.

LUAT DUNG DONG (giong maps-all / maps-instance):
  cot 0  = ID canh cua SERVER TA (SceneInfo.ini [sceneN]) hoac ID client_res (3xxx)
  cot 11..14 = 0  (khong ve bieu tuong ban do the gioi trung)
  cot 24 = 0      (CY 3.71 them cot nay; 762/792 dong hien la 0)

TRUONG HOP DAC BIET - huashan (canh 125 华山绝顶): KHONG bang nao co dong `huashan.scene`
(GL table, server SDE, CY DBC deu khong). `clientres=168` cua canh 125 tro `huashan_10.scene`
nhung do la HINH HOC KHAC: navmesh server `huashan.path` (sha a065941e, 267.241 B) BANG GL
`huashan.path` va KHAC `huashan_10.path` (CY 92e88862 / GL 842b3988). => dong 125 phai tro
`huashan.Scene`; 24 cot con lai lay theo mau dong 168 (cung ten 华山绝顶, cung 256x256), ten
tieng Viet 'Tuyệt đỉnh Hoa Sơn' la ten CY goc cua dong 168 (ref-dbc-692), hien thi 'Đỉnh Hoa Sơn'.

  python -X utf8 72-make-rows-lo2.py            -> ghi data/scenes-lo2-rows.json
"""
import json
import os

HERE = os.path.dirname(os.path.abspath(__file__))
CYS = os.path.abspath(os.path.join(HERE, '..', '..', '..'))
GL_TABLE = os.path.join(CYS, 'Assets', 'Canonical', 'Data', 'ConfigFolder', 'SceneDefineEx.txt')
OUT = os.path.join(HERE, 'data', 'scenes-lo2-rows.json')
INT_COLS = {0, 2, 3, 8, 9, 11, 12, 13, 14, 15, 16, 24}

# ID canh server ta -> (ID dong nguon trong bang GL, ghi chu)
KE_HOACH = [
    (410, 546, 'shengsileitai 生死擂台 type=0 - doi chung cho huashan'),
    (49, 81, 'zhulin 竹林 type=1 active, 81 quai (maps-instance 4.4)'),
    (48, 80, 'yewai 野外匪寨 type=1 active (maps-instance 4.4)'),
    (189, 230, 'jiaofei 镜湖匪寨 type=1 active (maps-instance 4.4)'),
    (190, 236, 'yanziwu 燕子坞 type=1 active (maps-instance 4.4)'),
    (539, 281, 'PhoenixMaze 凤凰陵墓 type=1 active (maps-instance 4.4)'),
    (3080, 80, 'client_res yewai (g_ClientRes 80 -> 3080, maps-instance 7.1)'),
    (3081, 81, 'client_res zhulin (g_ClientRes 81 -> 3081, maps-instance 7.1)'),
    (113, 156, 'huanjing_1 三春幻境 type=1 active=0 (trang tri)'),
    (114, 157, 'huanjing_2 三夏幻境 type=1 active=0'),
    (115, 158, 'huanjing_3 三秋幻境 type=1 active=0'),
    (116, 159, 'huanjing_4 三冬幻境 type=1 active=0'),
    (117, 160, 'bianguan_1 边关阵地山头 type=1 active=0, 11 quai'),
    (118, 161, 'bianguan_2 type=1 active=0, 11 quai'),
    (119, 162, 'bianguan_3 type=1 active=0, 11 quai'),
    (120, 163, 'bianguan_4 type=1 active=0, 11 quai'),
    (404, 266, 'dumuchang 毒障泽地 type=1 active=0'),
    (405, 267, 'huomuchang 熔岩之地 type=1 active=0'),
]


def decode(b):
    try:
        return b.decode('utf-8')
    except UnicodeDecodeError:
        return b.decode('gbk', 'replace')


def doc_gl():
    rows = {}
    for line in open(GL_TABLE, 'rb').read().split(b'\n'):
        line = line.rstrip(b'\r')
        c = line.split(b'\t')
        if not c or not c[0].strip().isdigit():
            continue
        vals = [decode(x).strip() for x in c[:24]]
        rows[int(vals[0])] = vals
    return rows


def dong(target, vals24, nguon):
    cells = []
    for c in range(24):
        v = vals24[c]
        cells.append(int(v) if c in INT_COLS else v)
    cells[0] = target
    for c in (11, 12, 13, 14):
        cells[c] = 0
    cells.append(0)  # cot 24
    return {'id': target, 'cells': cells, 'nguon': nguon}


def main():
    gl = doc_gl()
    rows = []
    # huashan: dung tu mau dong 168 (huashan_10), thay 4 o tep + cot 10 + ten
    m = list(gl[168])
    hs = dong(125, m, 'DUNG TAY tu mau GL/CY dong 168 (huashan_10) - xem docstring; tep = huashan.*')
    # 18/09 sau luot client s125-huashan-b: 'Tuyệt đỉnh Hoa Sơn' (ten CY goc cua dong 168) bi khung tieu de
    # minimap CY cat mat dau ("yệt đỉnh Hoa S"); dung ten ngan hon, trung voi cot [22] cua chinh dong nay.
    hs['cells'][1] = 'Đỉnh Hoa Sơn'
    hs['cells'][4] = 'huashan.Scene'
    hs['cells'][5] = 'huashan.path'
    hs['cells'][6] = 'huashan.WCollision'
    hs['cells'][10] = 'huashan'
    hs['cells'][22] = 'Đỉnh Hoa Sơn'
    hs['ghi_chu'] = ('canh 125 华山绝顶 type=0, 37 quai; clientres=168 tro huashan_10 la hinh hoc khac '
                     '(navmesh server = GL huashan.path a065941e). Mau 168: nBackSound 140, nCol9 20000, '
                     'Sign14, MiniMap_Icon3/HuaShanZhiDian_Normal.')
    rows.append(hs)
    for target, src, note in KE_HOACH:
        if src not in gl:
            raise SystemExit('bang GL khong co dong %d' % src)
        r = dong(target, gl[src], 'bang client GL (Assets/Canonical) dong %d: %s' % (src, note))
        rows.append(r)
    rows.sort(key=lambda r: r['id'])
    kh = {'schema': 1, 'dot': '2026-09-17-scenes-lo2', 'zero_wmap': True,
          'nguon_bang': 'Assets/Canonical/Data/ConfigFolder/SceneDefineEx.txt (GL client, 24 cot, text)',
          'doi_chieu_server': 'Build/Logs/2026-09-17-scenes-lo2/13-server-facts.json (19/19 dong giong bang server o moi cot tru [1]/[22])',
          'cong_cu': 'Tools/reapply/scenedef/72-dbc-pool-rows.py apply --rows <file nay>',
          'rows': rows}
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    json.dump(kh, open(OUT, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    print('ghi %s: %d dong' % (OUT, len(rows)))
    for r in rows:
        c = r['cells']
        print('  %5d %-28s %3dx%-3d %-22s %-20s %-22s snd=%-5d c9=%-6d %-7s %s' % (
            c[0], c[1], c[2], c[3], c[4], c[5], c[6], c[8], c[9], c[17], c[22]))


if __name__ == '__main__':
    main()
