# -*- coding: utf-8 -*-
"""cys_i18nscope_codefix.py - CYS-I18NSCOPE: dong 62 ban rut gon LECH TUI TOKEN so voi nguon Han.

Boi canh: duong ong rut ngan cua `ui-fit-2` KHONG chay `cy_translate.validate()`. Do duoc tren
3.339 ghi de con ngan sach: **62 dong** lech tui token so voi chu Han nguon. Hau qua khong deu
nhau, nen tep nay xep theo MUC NGUY HIEM chu khong theo so luong:

  A. THEM ma dieu khien nguon khong co (6 dong)  -> engine NUOT chu, nguoi choi mat han mot doan
     van ban ma khong co dau hieu gi. Dung lop loi `#H` ma ban dich TAY tung mac (`#您…` - o do
     `#` la ky tu thuong, nhung `#Hôm` lam `#H` khop `#[A-Za-z]`).
  B. LECH CHI SO tham so (1 dong)                -> `%s0级` bi rut thanh `%s c0`: engine thay `%s`
     va van ban " c0", tuc doi so bi lay sai cho.
  C. MAT `%sN` (5 dong)                          -> mat han mot GIA TRI tren man hinh.
  D. MAT the `#{_INFO...}` (1 dong)              -> mat cho bam tu tim duong. Du an da tung xoa
     nham mot the `_INFOMAP` va phai tim lai (DIEU-PHOI muc 21).
  E. MAT ma mau/dinh dang (49 dong)              -> chu van du, chi sai mau.

A-D sua TAY (bang duoi), moi dong qua `validate()` + be rong that.
E sua MAY bang bon luat VI TRI (R1-R4) - ma mau co be rong 0 nen khong the lam tran khung;
rui ro duy nhat la dat sai mau, va R1-R4 chep dung cau truc cuc bo cua nguon de giam thieu.
Dong nao khong qua duoc CA HAI cong thi KHONG ghi, va duoc liet ke de nguoi doc xu ly.

usage:
  python -B cys_i18nscope_codefix.py check          # do va in bang, khong ghi gi
  python -B cys_i18nscope_codefix.py apply          # ghi vao Registry/i18n/cy_vi_override.tsv
  python -B cys_i18nscope_codefix.py --selftest
"""
import argparse
import collections
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
import cy_gui_dict as GDICT            # noqa: E402
import cy_translate as CT              # noqa: E402
import cys_i18nscope_leak as LEAK      # noqa: E402
import cys_i18nscope_collide_fix as CF  # noqa: E402

TOK = GDICT.TOK
OVERRIDE = GDICT.OVERRIDE_TSV
LOGS = os.path.join(LEAK.CYS, 'Build', 'Logs', '2026-09-19-i18n-scope')
ARG = re.compile(r'^%\d*[a-zA-Z]\d?$')
NOTE = 'i18n-scope 20/09: va lech tui token so voi nguon Han (%s)'

# ---------------------------------------------------------------------------------------------
# A-D: sua TAY. key -> (ban moi, ly do). Chu Han nguon lay tu chinh tu dien CY, khong chep tay.
HAND = {
    # --- A. THEM ma dieu khien => engine nuot chu ---
    'ZBBJ_100816_03': ('Đóng so sánh trang bị',
                       'A: viet tat "trang bi" thanh "#T.bi#" sinh ma #T va #C, engine nuot chu'),
    'ZMB_230124_247': ('#RĐoàn Dự#W huyết mạch loạn, nhấn #GTrận Xích Huyết#W nhận thêm',
                       'A: ban cu boc them mot cum trong #R...#W ma nguon khong co'),
    'ZMB_230124_248': ('#RĐoàn Dự#W kinh lạc Thái Âm loạn, nhấn #GTrận Thái Âm#W nhận thêm',
                       'A: ban cu boc them mot cum trong #R...#W ma nguon khong co'),
    'ZMB_230124_249': ('#RĐoàn Dự#W huyệt Thiếu Dương loạn, nhấn #GTrận Thiếu Dương#W nhận thêm',
                       'A: ban cu boc them mot cum trong #R...#W ma nguon khong co'),
    'YSXY_211110_02': ('#Y#uChính sách bảo mật CY',
                       'A: bo `#n` cuoi - nguon khong dong the #u, giu dung hanh vi CY'),
    'YSXY_211110_09': ('#W#uChính sách bảo mật CY',
                       'A: bo `#n` cuoi - nguon khong dong the #u, giu dung hanh vi CY'),
    # --- B. lech CHI SO tham so ---
    # O 30 px khong co cach nao vua ca `%s0` lan mot chu; giu `%s0` (tham so SONG) va bo
    # chu "cap" - co che (KHOA, KHUNG) tra lai dang day du o khung rong hon khi can.
    'JYGZ_160714_237': ('%s0',
                        'B: ban cu `%s c0` - `%s0` bi cat thanh `%s` + van ban "c0"'),
    # --- C. MAT `%sN` => mat han mot GIA TRI tren man hinh ---
    'FQBS_140508_27': ('#cfff263Khảm đá trả góp hiệu lực đến #G%s0#cfff263.',
                       'C: ban cu mat han NGAY het hieu luc (%s0)'),
    'LZZHD_130520_45': ('#cfff263Tiêu #G%s0#cfff263 NB, nhận KN: #G%s1',
                        'C: ban cu mat han SO kinh nghiem (%s1)'),
    'MGCQ_151230_13': ('#cfff263Còn lại trước khi công bố Bảng tặng hoa và Bảng nhận hoa '
                       'Diệu Thế Truyền Tình: #G%s0',
                       'C: ban cu mat han DONG HO dem nguoc (%s0)'),
    'GEHJ_181026_24': ('#cfff263Truyền #G1#cfff263 được #G1#cfff263 thưởng, '
                       'còn #G%s0/%s1#cfff263.',
                       'C: ban cu mat han SO mon con lai (%s0/%s1)'),
    'BWDH_180804_27': ('#c6a3906Mùa giải hết #c1f941e%s0#c6a3906/#c1f941e%s1'
                       '#c6a3906/#c1f941e%s2#c6a3906!',
                       'C: ban cu mat han THANG va NGAY (%s1, %s2)'),
    # --- D. MAT the #{_INFO...} => mat cho bam tu tim duong ---
    # The giu NGUYEN BYTE ke ca ten Han ben trong: do la TAI trong toa do ma CysInfoLink doc
    # (CysInfoLink.h), khong phai van ban hien ra. Du an da tung xoa nham mot the _INFOMAP.
    'ZHHD1_181128_292': ('#LĐến #MLạc Dương#{_INFOMAP242,269,0,景年}'
                         '#NCảnh Niên#L nhận thưởng.',
                         'D: ban cu mat the _INFOMAP (cho bam tu tim duong) va ten NPC'),
    # --- E nhung phai sua TAY: ban dich GOP hai doan mau, R5 se phai DOI MAU mot doan dang hien
    #     => tra lai chinh chu bi rut, khong phai doi mau.
    'CYZJ_150212_12': ('#cfff263Trong túi có #G%s0#cfff263 bùa #GĐúc Vàng Nguyên Cam#cfff263.',
                       'E: tra lai mau #G cho TEN VAT PHAM (ban cu de ten cung mau voi cau)'),
    'ZMB_230124_253': ('Theo #Gmàu#W Kim Chung Tráo mà dùng #GTrường Tập Kiếm#W '
                       'hoặc #GTấn Công Kiếm#W.',
                       'E: ban cu bo han ve "hoac Tan Cong Kiem" - mat mot nua chi dan'),
    'ZPRW_180928_242': ('#GĐến #GTinh Túc Hải#{_INFOAIM142,55,16,丁春秋}#RĐinh Xuân Thu#G.',
                        'E: tra lai #G cho TEN BAN DO (nguon to rieng)'),
    'ZPRW_180928_243': ('#GĐến #GTinh Túc Hải#{_INFOAIM142,55,16,丁春秋}#RĐinh Xuân Thu#G.',
                        'E: tra lai #G cho TEN BAN DO (nguon to rieng)'),
}

# Nam dong CO Y de MO. Chung deu la lop E (chi sai MAU, khong mat chu), va dong lai se phai tra
# mot trong hai gia khong dang: hoac SINH THEM tran khung, hoac don mot ma mau rong xuong cuoi de
# `validate()` dem du ma khong sua gi that. Ghi ro ban sua da soan va con thieu bao nhieu px:
#   QXLS_150724_103  '#cfff263Cần #G%s0#cfff263 cái #GĐồng Tâm Kết'  200 px / o 170 px  (-30)
#   MGCQ_151230_103  '#cfff263Cần #G%s0#cfff263 cái #GTình Nhân Kết' 201 px / o 150 px  (-51)
#   QRPHB_150113_119 '#cfff263Cần #G%s0#cfff263 Ngọc Si Tình'        163 px / o 139 px  (-24)
#   QXLS_150724_107  '#cfff263Cần #G%s0#cfff263 cái #GĐịnh Tình'     166 px / o 139 px  (-27)
#   CYRM_140825_02   doan van nhieu dong, thieu #cfff263 x3 + #G x3: ban dich da bo han may menh
#                    de - tra lai la viec DICH, khong phai viec dat ma mau.
# Ca nam se dong duoc khi cong cu keo khung (muc 21) noi bon o kia them ~30-51 px.


# ---------------------------------------------------------------------------------------------
def segs(s):
    """[(kind, text)] voi kind in {'t','k'} - van ban thuong / token."""
    out, i = [], 0
    for m in TOK.finditer(s):
        if m.start() > i:
            out.append(('t', s[i:m.start()]))
        out.append(('k', m.group(0)))
        i = m.end()
    if i < len(s):
        out.append(('t', s[i:]))
    return out


def repair(zh, vi):
    """Bon luat VI TRI, chi them ma mau/dinh dang, khong bao gio them/bo van ban.

    R1 nguon mo dau bang ma X ma vi khong  -> them X len dau.
    R2 nguon ket thuc bang ma X ma vi khong -> them X vao cuoi.
    R3 nguon co `X %sN` ma vi co `%sN` khong co X ngay truoc -> chen X truoc `%sN`.
    R4 nguon co `%sN X` ma vi co `%sN` khong co X ngay sau  -> chen X sau `%sN`.
    Moi luat chi chay khi ma do dang THIEU trong vi (so voi tui token cua nguon).
    """
    def missing(v):
        a = collections.Counter(TOK.findall(zh))
        b = collections.Counter(TOK.findall(v))
        return a - b
    sz = segs(zh)
    out = vi
    # R3/R4: quanh tung tham so
    for i, (kind, val) in enumerate(sz):
        if kind != 'k' or not ARG.match(val):
            continue
        before = sz[i - 1][1] if i and sz[i - 1][0] == 'k' else None
        after = sz[i + 1][1] if i + 1 < len(sz) and sz[i + 1][0] == 'k' else None
        if before and not ARG.match(before) and missing(out).get(before) and val in out:
            j = out.find(val)
            if not out[:j].endswith(before):
                out = out[:j] + before + out[j:]
        if after and not ARG.match(after) and missing(out).get(after) and val in out:
            j = out.find(val) + len(val)
            if not out[j:].startswith(after):
                out = out[:j] + after + out[j:]
    # R1 / R2
    first = sz[0][1] if sz and sz[0][0] == 'k' else None
    if first and not ARG.match(first) and missing(out).get(first) and not out.startswith(first):
        out = first + out
    last = sz[-1][1] if sz and sz[-1][0] == 'k' else None
    if last and not ARG.match(last) and missing(out).get(last) and not out.endswith(last):
        out = out + last
    return out


def rebuild(zh, vi):
    """R5 - dung lai DAY MA MAU cua ban dich theo DUNG THU TU cua nguon.

    R1-R4 chi vá được chỗ nào có mốc (đầu, cuối, quanh tham số). Phần còn lại là ca bản dịch đã
    GỘP hai đoạn màu của nguồn thành một, nên mã thừa ra không còn chỗ bám. R5 dựng lại:

      * giữ NGUYÊN mọi ký tự văn bản và mọi `%sN` của bản dịch, đúng thứ tự (kiểm bằng khẳng định);
      * cắt bản dịch tại chính những chỗ nó đang đổi màu -> các "đoạn" t1..tm;
      * phát lại dãy mã của NGUỒN c1..cn theo đúng thứ tự: c1 t1 c2 t2 ... ; mã dư (n > m) dồn về
        cuối - một mã màu không có chữ theo sau thì không vẽ ra gì, nên vô hại.

    Nhờ dựng theo cấu trúc, túi token BẰNG nguồn => `validate()` qua. Điều R5 KHÔNG hứa là màu
    rơi đúng đoạn khi bản dịch gộp đoạn; nó chỉ hứa thứ tự màu của nguồn được giữ. Đó là lý do
    R5 chỉ chạy cho lớp E (chỉ thiếu mã màu) và mọi dòng nó sinh ra đều được liệt kê để người đọc
    soi lại - không dòng nào có `%sN` hay `#{...}` bị đụng tới.
    """
    codes = [v for k, v in segs(zh) if k == 'k' and not ARG.match(v) and not v.startswith('#{')]
    keep = [v for k, v in segs(vi) if k == 't' or ARG.match(v) or v.startswith('#{')]
    chunks, cur = [], ''
    for k, v in segs(vi):
        if k == 'k' and not ARG.match(v) and not v.startswith('#{'):
            if cur:
                chunks.append(cur)
            cur = ''
        else:
            cur += v
    if cur:
        chunks.append(cur)
    out = ''
    for i, ch in enumerate(chunks):
        if i < len(codes):
            out += codes[i]
        out += ch
    out += ''.join(codes[len(chunks):])
    assert ''.join(keep) == ''.join(chunks), 'R5 lam mat van ban'
    return out


def chunk_colours(s):
    """[(ma dang hieu luc, doan van ban)] da GOP cac doan lien nhau cung mau.

    Phai gop: chen mot ma mau Y NGAY TRUOC doan dang da mang chinh mau do lam doan bi CAT DOI
    nhung KHONG doi mot diem anh nao. Neu so khong gop thi phep kiem se bao "doi mau" oan va
    chan mat nhung ban va dung.
    """
    out, cur = [], None
    for k, v in segs(s):
        if k == 'k' and not ARG.match(v) and not v.startswith('#{'):
            cur = v
        elif v:
            if out and out[-1][0] == cur:
                out[-1] = (cur, out[-1][1] + v)
            else:
                out.append((cur, v))
    return out


def recolours(before, after, zh=None):
    """True khi ban sua DOI MAU cua mot doan van ban dang hien - tuc doi thu nguoi choi nhin thay.

    Mot ngoai le duy nhat, va no la SUA chu khong phai doi: doan dang KHONG co ma nao (mau mac
    dinh, `None`) duoc nhan ma ma NGUON quy dinh cho no. Do la tra lai thu da bi rut mat, khong
    phai quyet dinh tham my moi.
    """
    a, b = chunk_colours(before), chunk_colours(after)
    if a == b:
        return False
    if zh is not None and len(a) == len(b):
        src = chunk_colours(zh)
        for i, ((ca, ta), (cb, tb)) in enumerate(zip(a, b)):
            if ta != tb:
                return True
            if ca == cb:
                continue
            if ca is None and i < len(src) and cb == src[i][0]:
                continue
            return True
        return False
    return True


def classify(zh, vi):
    a = collections.Counter(TOK.findall(zh))
    b = collections.Counter(TOK.findall(vi))
    plus, minus = b - a, a - b
    if plus and minus:
        return 'B'
    if plus:
        return 'A'
    if any(t.startswith('#{') for t in minus):
        return 'D'
    if any(ARG.match(t) for t in minus):
        return 'C'
    return 'E'


def gather():
    budget = LEAK.load_budget()
    now, _full, zh = LEAK.build_dicts(set(budget))
    gather.now = now
    rows = []
    for k in budget:
        z, v = zh.get(k), now.get(k)
        if z is None or v is None:
            continue
        err = CT.validate(z, v)
        if not err:
            continue
        rows.append({'key': k, 'zh': z, 'vi': v, 'err': err, 'cls': classify(z, v),
                     'budget_px': budget[k][0], 'budget_frame': budget[k][1]})
    return rows


def build_fixes(rows):
    """-> (fixes [(key, vi_moi, ly_do, cls)], con_lai [row])."""
    fixes, left = [], []
    for r in rows:
        if r['key'] in HAND:
            vi, why = HAND[r['key']]
            fixes.append((r['key'], vi, why, r['cls']))
            continue
        cand = repair(r['zh'], r['vi'])
        if cand != r['vi'] and not CT.validate(r['zh'], cand) and not recolours(r['vi'], cand, r['zh']):
            fixes.append((r['key'], cand, 'E: tra lai ma dinh dang bang luat vi tri R1-R4',
                          r['cls']))
            continue
        # R5 chi duoc dung khi no KHONG doi mau cua mot doan van ban nao dang hien. Neu no doi,
        # do la mot quyet dinh THAY DOI THU NGUOI CHOI NHIN THAY - phai co nguoi doc, khong phai
        # mot luat vi tri. (Va tuyet doi khong don mot ma mau rong xuong cuoi chi de `validate()`
        # dem du: nhu the la LAM CHO CONG IM, khong phai sua loi.)
        cand5 = rebuild(r['zh'], r['vi']) if r['cls'] == 'E' else r['vi']
        if cand5 != r['vi'] and not CT.validate(r['zh'], cand5) and not recolours(r['vi'], cand5, r['zh']):
            fixes.append((r['key'], cand5, 'E: dung lai day ma theo thu tu nguon (R5), 0 doan doi mau',
                          r['cls']))
            continue
        if cand5 != r['vi'] and not CT.validate(r['zh'], cand5):
            r = dict(r, r5=cand5, r5_recolour=True)
        left.append(r)
    return fixes, left


def width_gate(fixes, now):
    """-> [(key, vi, why, cls, box_w, text_w, ok)] tren o HEP NHAT cua moi khung dung khoa.

    Cong KHONG doi "phai vua o" ma doi "KHONG TE HON HIEN TAI": nguong la
    `max(be rong o, be rong ban dang chay)`. Ly do do duoc: vai khoa o day ban DANG CHAY da tran
    san (vi du `JYGZ_160714_237` o 30 px), nen doi hoi vua tuyet doi se chan dung nhung ban va
    SUA LOI MAT CHU chi vi cai khung von da hep - tuc lay mot loi bo cuc de chan mot loi mat du
    lieu. Chan dung viec la: khong SINH THEM tran.
    """
    import ceguitext
    boxes = CF.narrowest_boxes(os.path.join(LOGS, 'm-final2', 'overflow.csv'))
    fonts = CF.load_fonts()
    dic = ceguitext.load_dictionary(os.path.join(CF.DATA, 'ConfigFolder', 'StrDictionary.txt'))
    out = []
    for key, vi, why, cls in fixes:
        b = boxes.get(key)
        w = ok = None
        if b:
            w, _s = CF.text_px(fonts, dic, vi, b[3])
            cur, _s2 = CF.text_px(fonts, dic, now.get(key, ''), b[3])
            ok = w <= max(b[0], cur) + 0.5
        out.append((key, vi, why, cls, b[0] if b else None, w, ok))
    return out


def selftest():
    ok = True

    def chk(n, c, d=''):
        nonlocal ok
        print(('PASS ' if c else 'FAIL ') + n + (' | ' + d if d else ''))
        ok = ok and c
    # R1
    zh, vi = '#cfff263需要#G%s0#cfff263个', '#G%s0'
    r = repair(zh, vi)
    chk('R1/R3 tra lai ma mo dau + ma quanh tham so', CT.validate(zh, r) is None, 'ra %r' % r)
    # R2
    zh2, vi2 = '#L共受礼：#M%s0#L', '#LQuà: #M%s0'
    chk('R2 tra lai ma ket thuc', CT.validate(zh2, repair(zh2, vi2)) is None,
        'ra %r' % repair(zh2, vi2))
    # AM 1: khong duoc dong vao VAN BAN
    chk('AM khong them/bo mot ky tu van ban nao',
        TOK.sub('', repair(zh, vi)) == TOK.sub('', vi),
        '%r vs %r' % (TOK.sub('', repair(zh, vi)), TOK.sub('', vi)))
    # AM 2: khi vi THEM ma (lop A) thi R1-R4 KHONG duoc "sua" cho qua cong
    zh3, vi3 = '关闭装备属性比较', 'Đóng so sánh #T.bị#'
    chk('AM lop A (them ma) KHONG duoc tu dong qua cong',
        CT.validate(zh3, repair(zh3, vi3)) is not None)
    # AM 3: dong da dung thi khong doi
    zh4, vi4 = '#G%s0#W', '#GXin#W'
    chk('AM dong da dung tui token thi giu nguyen', repair(zh4, vi4) == vi4)
    # phan loai
    chk('phan loai dung 5 lop',
        (classify('关闭', 'a#T') == 'A' and classify('%s0级', '%s c0') == 'B'
         and classify('#G%s0', '#G') == 'C' and classify('#{_INFOMAP1,2,3,x}a', 'a') == 'D'
         and classify('#G%s0#W', '#G%s0') == 'E'))
    print('SELFTEST', 'OK' if ok else 'FAILED')
    return 0 if ok else 1


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('cmd', nargs='?', default='check', choices=('check', 'apply'))
    ap.add_argument('--selftest', action='store_true')
    a = ap.parse_args()
    if a.selftest:
        return selftest()
    rows = gather()
    print('dong khong qua validate():', len(rows), dict(collections.Counter(r['cls'] for r in rows)))
    fixes, left = build_fixes(rows)
    gated = width_gate(fixes, gather.now)
    bad = [g for g in gated if g[6] is False]
    print('sua duoc: %d (tay %d, may %d) | chua sua duoc: %d | tran o: %d'
          % (len(gated), sum(1 for g in gated if g[0] in HAND),
             sum(1 for g in gated if g[0] not in HAND), len(left), len(bad)))
    for g in gated:
        if g[3] in ('A', 'B', 'C', 'D') or g[6] is False:
            print('  %-4s %-20s %-6s %-6s %r' % (g[3], g[0],
                                                 ('%.0f' % g[4]) if g[4] is not None else '-',
                                                 ('%.0f' % g[5]) if g[5] is not None else '-',
                                                 g[1][:52]))
    with io.open(os.path.join(LOGS, 'codefix-plan.json'), 'w', encoding='utf-8') as f:
        json.dump({'fixes': [{'key': g[0], 'vi': g[1], 'why': g[2], 'cls': g[3],
                              'box_w': g[4], 'text_w': g[5], 'fits': g[6]} for g in gated],
                   'left': left}, f, ensure_ascii=False, indent=1)
    if left:
        print('CON LAI (can nguoi doc):')
        for r in left[:12]:
            print('    %-4s %-20s %r -> %r' % (r['cls'], r['key'], r['zh'][:30], r['vi'][:34]))
    if a.cmd != 'apply':
        print('(chua ghi gi - dung `apply` de ghi)')
        return 0
    if bad:
        print('TU CHOI GHI: con dong tran o')
        return 1
    stamp = datetime.datetime.now().strftime('%Y%m%d-%H%M%S')
    shutil.copy2(OVERRIDE, OVERRIDE + '.bak-i18n-scope-' + stamp)
    with io.open(OVERRIDE, encoding='utf-8', newline='') as f:
        lines = f.read().split('\n')
    idx = {}
    for i, ln in enumerate(lines):
        p = ln.split('\t')
        if i and p and p[0].startswith('#'):
            idx.setdefault(p[0][1:], i)
    n = 0
    for key, vi, why, _c, _b, _w, _f in gated:
        row = '#%s\t%s\t%s' % (key, vi, NOTE % why)
        if key in idx:
            lines[idx[key]] = row
            n += 1
    with io.open(OVERRIDE, 'w', encoding='utf-8', newline='') as f:
        f.write('\n'.join(lines))
    print('da thay %d dong | sao luu .bak-i18n-scope-%s' % (n, stamp))
    return 0


if __name__ == '__main__':
    sys.exit(main())
