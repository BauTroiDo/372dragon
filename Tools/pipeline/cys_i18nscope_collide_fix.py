# -*- coding: utf-8 -*-
"""cys_i18nscope_collide_fix.py - CYS-I18NSCOPE 19/09/2026: dong cac nhom VA CHAM NGHIA cung-khung.

Va cham nghia = hai khai niem KHAC NHAU rut ve CUNG mot chuoi tieng Viet, va ca hai deu hien
trong CUNG mot khung => nguoi choi khong co cach nao phan biet. `selfequip-fit` do duoc 61 nhom,
sua 1 (`Thể lực:`/`Tinh lực:`), con 60.

Nhanh nay KHONG sua hang loat bang may (dung canh bao cua selfequip-fit: phan lon la LANH, vi du
`Xác nhận` <- 确认/确定 la binh thuong). Moi dong duoi day la mot quyet dinh TAY, co chu Han nguon
kem theo, va phai qua HAI cong truoc khi duoc ghi:

  1. `cy_translate.validate(zh, vi)` - cung cong ma moi ban dich may phai qua. Bat "printf them dac
     ta", "con chu Han", "tui token lech" (TOK da va `%\\d*[a-zA-Z]\\d?` de bat lech CHI SO tham so).
     Luat cua du an: dich TAY khong an toan hon dich may.
  2. Be rong THAT: `Tools/ui-fit/ceguitext.py` (FreeType, dung font, dung co chu) do chuoi moi tren
     O HEP NHAT trong MOI khung tham chieu khoa do. Vuot => bao FAIL, khong ghi.

usage:
  python -B cys_i18nscope_collide_fix.py check     # do va in bang, khong ghi gi
  python -B cys_i18nscope_collide_fix.py apply     # ghi vao Registry/i18n/cy_vi_override.tsv (co .bak)
  python -B cys_i18nscope_collide_fix.py --selftest
"""
import argparse
import collections
import csv
import datetime
import io
import json
import os
import re
import shutil
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, '..', 'ui-fit'))
import cy_gui_dict as GDICT          # noqa: E402
import cy_translate as CT            # noqa: E402

CYS = os.path.abspath(os.path.join(HERE, '..', '..'))
DATA = os.path.join(CYS, 'Assets', 'CanonicalCY', 'Data')
LOGS = os.path.join(CYS, 'Build', 'Logs', '2026-09-19-i18n-scope')
OVERRIDE = GDICT.OVERRIDE_TSV
NOTE = 'i18n-scope 19/09: va cham nghia cung-khung (%s)'

# ---------------------------------------------------------------------------------------------
# BANG QUYET DINH TAY. Moi dong: khoa -> (ban Viet moi, chu Han nguon, ly do).
# "giu" nghia la khoa kia trong nhom GIU NGUYEN - chi mot ve duoc doi, du de phan biet.
FIXES = [
    # --- 1. AcceSetup: 5 o phim tat mat chu so phan biet (khong phai loi rut gon - ban dich lam mat)
    ('SFJN_130608_06', 'Kỹ năng/VP trên 06', '上方技能/物品06', 'so thu tu bi mat khi dich'),
    ('SFJN_130608_07', 'Kỹ năng/VP trên 07', '上方技能/物品07', 'so thu tu bi mat khi dich'),
    ('SFJN_130608_08', 'Kỹ năng/VP trên 08', '上方技能/物品08', 'so thu tu bi mat khi dich'),
    ('SFJN_130608_09', 'Kỹ năng/VP trên 09', '上方技能/物品09', 'so thu tu bi mat khi dich'),
    ('SFJN_130608_10', 'Kỹ năng/VP trên 10', '上方技能/物品10', 'so thu tu bi mat khi dich'),
    # --- 3/4/28/29 (BYFUR_160531_15/4/18/5) DE MO CO Y, xem OPEN duoi day.
    # --- 17. nhan truong "Môn phái:" bi nuot, con lai dung ten mon phai => trung voi o gia tri
    ('INTERFACE_XML_450', 'Phái: C.Bang', '门派:丐帮', 'nhan truong bi mat, trung voi gia tri'),
    # --- 20. NGUY HIEM: "Huy" (取消) va "Tieu huy" (销毁) trong cung hop xoa nhiem vu
    ('INTERFACE_XML_758', 'Xóa', '销毁', 'huy bo <-> tieu huy trong cung hop xoa'),
    # --- 24. bon loai dau gia khac nhau cung mot chu
    ('FMPM_220815_03', 'ĐG P.Minh', '凤鸣拍卖', 'bon loai dau gia khac nhau'),
    ('SCBHPM_20220815_05', 'ĐG Bang', '帮会拍卖', 'bon loai dau gia khac nhau'),
    ('SCBHPM_20220815_26', 'Ra giá', '竞拍', 'canh gia <-> dau gia'),
    # --- 25. NGUY HIEM: hai nut nguoc nghia trong khung tuyen chien
    ('BHJM_140520_108', '#cfff262Nghênh', '#cfff262接战', 'nhan chien <-> phat dong tuyen chien'),
    ('KVKBH_140124_23', '#cfff262Tuyên', '#cfff262发起宣战', 'phat dong tuyen chien'),
    # --- 30/31. hai o "ten" khac nhau trong cung khung tim tran thu
    ('INTERFACE_XML_1146', 'Tên TT:', '珍兽名称：', 'ten nguoi choi <-> ten tran thu'),
    # --- 42. hai NPC khac nhau rut ve mot ten, va ca hai ten deu SAI (Tiet Thu / Tran Huong)
    ('SYCY_201225_231', '#MLạc Dương#NTiết Thư#L', '#M洛阳#N薛书#L', 'ten NPC 薛书 = Tiet Thu'),
    ('SYCY_201225_251', '#MLạc Dương#NTiết Thư#L', '#M洛阳#N薛书#L', 'ten NPC 薛书 = Tiet Thu'),
    ('SYCY_201225_256', '#MLạc Dương#NTiết Thư#L', '#M洛阳#N薛书#L', 'ten NPC 薛书 = Tiet Thu'),
    ('SYCY_201225_291', '#MLạc Dương#NTiết Thư#L', '#M洛阳#N薛书#L', 'ten NPC 薛书 = Tiet Thu'),
    ('SYCY_201225_236', '#MLạc Dương#NTrần Hương#L', '#M洛阳#N陈香#L', 'ten NPC 陈香 = Tran Huong'),
    ('SYCY_201225_271', '#MLạc Dương#NTrần Hương#L', '#M洛阳#N陈香#L', 'ten NPC 陈香 = Tran Huong'),
    ('SYCY_201225_281', '#MLạc Dương#NTrần Hương#L', '#M洛阳#N陈香#L', 'ten NPC 陈香 = Tran Huong'),
    ('SYCY_201225_306', '#MLạc Dương#NTrần Hương#L', '#M洛阳#N陈香#L', 'ten NPC 陈香 = Tran Huong'),
    # --- 43. hai muc khac nhau cua cung mot bang so sanh
    ('CXYH_140813_32', '#cfff263Hiệu quả sau LH', '#cfff263炼魂后效果', 'hieu qua <-> thuoc tinh'),
    ('CXYH_140813_34', '#cfff263Thuộc tính sau LH', '#cfff263炼魂后的属性', 'hieu qua <-> thuoc tinh'),
    # --- 45/46. "Huy" (取消) <-> "Vo hieu" (作废) tren hai nut canh nhau
    ('ZDPT_XML_23', 'Bỏ', '作废', 'huy bo <-> vo hieu hoa phieu'),
    # --- 49 + lop loi TM cung ho: 8 chu Han don le deu tra ve MOT chuoi URL nap tien
    ('YDSS_15018_205', 'Phong', '风', 'TM tra ve chuoi URL nap tien cho chu Han don'),
    ('YDSS_15018_210', 'Phùng', '逢', 'TM tra ve chuoi URL nap tien cho chu Han don'),
    ('YDSS_15018_218', 'Thân', '身', 'TM tra ve chuoi URL nap tien cho chu Han don'),
    ('YDSS_15018_223', 'Phi', '飞', 'TM tra ve chuoi URL nap tien cho chu Han don'),
    ('YDSS_15018_224', 'Dực', '翼', 'TM tra ve chuoi URL nap tien cho chu Han don'),
    ('YDSS_15018_239', 'Trừ', '除', 'TM tra ve chuoi URL nap tien cho chu Han don'),
    ('WHGBSX_091015_09', 'Phong', '风', 'TM tra ve chuoi URL nap tien cho chu Han don'),
    ('FHCL_240708_372', 'Phong', '风', 'TM tra ve chuoi URL nap tien cho chu Han don'),
    ('WHYH_161121_113', 'Phong', '风', 'TM tra ve chuoi URL nap tien cho chu Han don'),
    ('ZYXT_120528_195', 'Giày', '鞋', 'TM tra ve chuoi URL nap tien cho chu Han don'),
    # --- 58. hai gian hang khac nhau cung mot ten
    ('IMXZ_20100813_07', 'H.Trang', '炫装商城', 'hai gian hang khac nhau'),
    ('YBSD_081225_007', 'H.Tượng', '形象广场', 'hai gian hang khac nhau'),
    # --- 59. ba hop qua khac nhau, ten hop bi nuot, chi con gia
    ('HCYL_150304_37', '#cfff263Chú Kim Ngự Lễ: 4000NB', '#cfff263铸金御礼售价4000元宝', 'ten hop qua bi mat'),
    ('HCYL_150304_38', '#cfff263Trác Khắc Ngự Lễ: 4000NB', '#cfff263琢刻御礼售价4000元宝', 'ten hop qua bi mat'),
    ('HCYL_160307_05', '#cfff263Tinh Kim Ngự Lễ: 4000NB', '#cfff263精金御礼售价4000元宝', 'ten hop qua bi mat'),
    # --- 60. danh tu "tran phap" <-> dong tu "khoi tran"
    ('JBLC_150528_295', 'Khởi', '启阵', 'tran phap (danh tu) <-> khoi tran (dong tu)'),
]
# Khoa CHI CAN XOA ghi de (ban day du da vua san o chinh khung ngan sach - xem stale-overrides.json)
# Nhom PHAI de MO: cach viet DUNG nghia khong vua o hep nhat => day chinh la ca can co che
# ghi de theo cap (KHOA, KHUNG). Do that 19/09 (ceguitext, SongTiBmp12/12):
#   BYFUR_160531_4 庭院桌 -> 'Bàn sân' 60 px : VUA o hai khung va cham (60 px) nhung TRAN o
#   BYFUR_160531_5 庭院凳 -> 'Ghế sân' 60 px : khung thu ba `BieYeFurnitureBank` (55 px).
# Viet tat cho vua ca ba ('Bàn SV'/'Ghế SV', 53 px) thi nguoi choi khong doc duoc - dung cai
# ma nhanh nay sinh ra de chong. Khong ep mot ban dich xau chi de bang co so 0 nhom con lai.
OPEN = [('BYFUR_160531_4', '庭院桌', 'Bàn sân 60 px > 55 px o BieYeFurnitureBank'),
        ('BYFUR_160531_5', '庭院凳', 'Ghế sân 60 px > 55 px o BieYeFurnitureBank')]

DROP = [('CPSJ_260112_22', '#G%s0#cfff263阶', 'hau to "Tang/Bac" bi rut mat; ban day du VUA o 58 px')]


def narrowest_boxes(measure_csv):
    """{key: (box_w, layout, widget, font, pt)} - o HEP NHAT trong MOI khung tham chieu khoa."""
    rx = re.compile(r'^#\{([^}]+)\}$')
    out = {}
    with open(measure_csv, encoding='utf-8', newline='') as fh:
        for r in csv.DictReader(fh):
            m = rx.match((r['raw'] or '').strip())
            if not m:
                continue
            w = float(r['box_w'])
            cur = out.get(m.group(1))
            if cur is None or w < cur[0]:
                out[m.group(1)] = (w, r['layout'], r['widget'], r['font'], int(r['pt']))
    return out


def load_fonts():
    import ceguitext
    ui = os.path.join(DATA, 'InterfaceFolder')
    return ceguitext.load_fonts(os.path.join(ui, 'Schema'), ui, 65001)


def text_px(fonts, dictionary, text, font_name):
    """Be rong hien thi THAT: bo markup y nhu engine (expand_markup) roi cong advance (FreeType)."""
    import ceguitext
    fn = fonts.get(font_name) or fonts.get('SongTiBmp12')
    shown, _lost = ceguitext.expand_markup(text, dictionary)
    return fn.extent(shown), shown


def check(fixes=FIXES):
    import ceguitext
    boxes = narrowest_boxes(os.path.join(LOGS, 'm-short', 'overflow.csv'))
    fonts = load_fonts()
    dic = ceguitext.load_dictionary(os.path.join(DATA, 'ConfigFolder', 'StrDictionary.txt'))
    rows, bad = [], 0
    for key, vi, zh, why in fixes:
        err = CT.validate(zh, vi)
        b = boxes.get(key)
        w = fit = shown = None
        if b:
            w, shown = text_px(fonts, dic, vi, b[3])
            fit = w <= b[0] + 0.5
        rows.append({'key': key, 'vi': vi, 'zh': zh, 'why': why, 'validate': err,
                     'box_w': b[0] if b else None, 'frame': b[1].split('/')[0] if b else None,
                     'widget': b[2] if b else None, 'font': b[3] if b else None,
                     'shown': shown, 'text_w': w, 'fits': fit})
        if err or fit is False:
            bad += 1
    return rows, bad


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('cmd', nargs='?', default='check', choices=('check', 'apply'))
    ap.add_argument('--selftest', action='store_true')
    args = ap.parse_args()
    if args.selftest:
        # doi chung: mot ban dich CO Y hong phai bi validate() chan, va mot chuoi qua rong phai FAIL
        bad_vi = [('X', '#Hôm nay', '#您', 'doi chung: # la ky tu thuong ben nguon')]
        err = CT.validate(bad_vi[0][2], bad_vi[0][1])
        print(('PASS' if err else 'FAIL'), 'validate() chan ban dich sinh ma dieu khien moi:', err)
        err2 = CT.validate('确定', 'Xác nhận')
        print(('PASS' if not err2 else 'FAIL'), 'validate() cho qua ban dich lanh:', err2)
        err3 = CT.validate('%s0 diem', '%s0 %s1 diem')
        print(('PASS' if err3 else 'FAIL'), 'validate() chan khi them mot tham so:', err3)
        return 0 if (err and not err2 and err3) else 1
    rows, bad = check()
    print('%-22s %-30s %-7s %-7s %-6s %s' % ('khoa', 'ban Viet moi', 'chu px', 'o px', 'vua?', 'validate'))
    for r in rows:
        print('%-22s %-30s %-7s %-7s %-6s %s' % (
            r['key'], r['vi'][:30], r['text_w'] if r['text_w'] is not None else '-',
            r['box_w'] if r['box_w'] is not None else 'khong o',
            'OK' if r['fits'] else ('KHONG' if r['fits'] is False else '-'),
            r['validate'] or 'ok'))
    print('\ntong %d dong, %d dong HONG (validate loi hoac tran o)' % (len(rows), bad))
    with open(os.path.join(LOGS, 'collide-fix-check.json'), 'w', encoding='utf-8') as f:
        json.dump(rows, f, ensure_ascii=False, indent=1)
    if args.cmd != 'apply':
        return 0
    if bad:
        print('TU CHOI GHI: con dong hong, sua bang quyet dinh truoc.')
        return 1
    stamp = datetime.datetime.now().strftime('%Y%m%d-%H%M%S')
    shutil.copy2(OVERRIDE, OVERRIDE + '.bak-i18n-scope-' + stamp)
    with io.open(OVERRIDE, encoding='utf-8', newline='') as f:
        lines = f.read().split('\n')
    idx = {}
    for i, ln in enumerate(lines):
        p = ln.split('\t')
        if p and p[0].startswith('#'):
            idx.setdefault(p[0][1:], i)
    added = replaced = dropped = 0
    for key, vi, zh, why in FIXES:
        row = '#%s\t%s\t%s' % (key, vi, NOTE % why)
        if key in idx:
            lines[idx[key]] = row
            replaced += 1
        else:
            lines.append(row)
            added += 1
    for key, _zh, why in DROP:
        if key in idx:
            del lines[idx[key]]
            idx = {}
            for i, ln in enumerate(lines):
                p = ln.split('\t')
                if p and p[0].startswith('#'):
                    idx.setdefault(p[0][1:], i)
            dropped += 1
    while lines and lines[-1] == '':
        lines.pop()
    with io.open(OVERRIDE, 'w', encoding='utf-8', newline='') as f:
        f.write('\n'.join(lines) + '\n')
    print('ghi xong: them %d, thay %d, xoa %d | sao luu %s' % (added, replaced, dropped, stamp))
    return 0


if __name__ == '__main__':
    sys.exit(main())
