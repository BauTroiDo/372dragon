# -*- coding: utf-8 -*-
"""Doi chung cho CONG bat bien printf moi cam vao `Tools/pipeline/cy_gui_dict.py` (CUA THU BA).

VI SAO CO CONG NAY: `cy_gui_dict.build()` xuat thang ket qua cua bo nho dich / tu dien GL / API
ra `StrDictionary.txt`, chi loc qua `wrecked()`. Bat bien printf chua bao gio duoc kiem o day, nen
134 o da lot ra voi NHIEU dac ta printf hon nguon Han (do 20/09). Khi do, `_vsnprintf` o
`UIString.cpp:918` doc mot doi so KHONG TON TAI.

MUC DO, do tren UCRT x64 that (MSVC 2022 /MD, KHONG cai invalid-parameter handler - y het game):
  `% s` -> giai tham chieu con tro rac (co the vang) · `% n` -> tien trinh CHET NGAY, exit
  0xC0000409 (__fastfail), SEH KHONG BAT DUOC nen khong co minidump · `% g/% c/% d/% p` -> in rac.

CONG NAY CHAN CAI GI: dung mot bat bien - "so dac ta printf cua ban dich khong duoc VUOT nguon
Han". No KHONG chan ca `cy_translate.validate()` day du: phep kiem day du con tu choi 5.836 dong
nua vi lech ma mau (do 20/09 tren 155.044 dong), va chan cung cai do se day gan 6.000 o ve chu
Han - mot hoi quy nguoi dung thay ngay. Do la mot LUA CHON CO CHU Y, co so do.

DIEU CO Y KHONG LAM: khong "lam cho cong im". Cong khong dem cho du bang cach them ky tu vo
nghia; no doi dau `%` ASCII TAI NAN thanh `％` (U+FF05) - dung ky tu nguon Han dung san, hien ra
dung o CA HAI duong (printf va `#{KHOA}`), trong khi `%%` chi dung o duong printf va hien thanh
hai dau o duong con lai.

Mot cong khong biet truot thi khong phai cong. Phep kiem nay goi HAM THAT trong mot TIEN TRINH
RIENG, voi nam lo:
  1. dong lanh                        -> khong dong vao, gate im;
  2. dong `50% gia tri` (`% g` moi)   -> tu dong sua thanh `50％ gia tri`, KHONG doi chu nao khac;
  3. dong `100%#cfff263` (`%#c` moi)  -> tu dong sua, ma mau con NGUYEN VEN;
  4. dong khong sua sach duoc         -> `printf_gate='raise'` DUNG HAN va neu ten khoa;
  5. dang co san trong nguon Han      -> GIU NGUYEN (day la nhanh sua ban dich, khong sua CY).

Chay:  python -X utf8 Tests/i18n/cy_gui_dict_printf_gate_test.py
"""
import io
import json
import os
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, '..', '..'))
PIPE = os.path.join(REPO, 'Tools', 'pipeline')

# Chay trong tien trinh RIENG: cong phai dung khi duoc nap tu dia, khong phai khi da vam trong RAM.
CHILD = r'''# -*- coding: utf-8 -*-
import io, json, sys
sys.path.insert(0, %(pipe)r)
import cy_gui_dict as G

cases = json.load(io.open(%(inp)r, encoding='utf-8'))
out = []
for zh, vi in cases:
    fixed, n = G.deparam_percent(zh, vi)
    out.append({'zh': zh, 'vi': vi, 'fixed': fixed, 'n': n,
                'over_before': G.printf_over(zh, vi),
                'over_after': G.printf_over(zh, fixed),
                'nspec_zh': G.n_printf_spec(zh),
                'nspec_before': G.n_printf_spec(vi),
                'nspec_after': G.n_printf_spec(fixed)})
io.open(%(outp)r, 'w', encoding='utf-8').write(json.dumps(out, ensure_ascii=False))
'''

# Lo 4 di rieng: no phai lam `build()` DUNG HAN, nen goi thang duong dung cua cong.
CHILD_RAISE = r'''# -*- coding: utf-8 -*-
import sys
sys.path.insert(0, %(pipe)r)
import cy_gui_dict as G
zh, vi = %(zh)r, %(vi)r
fixed, n = G.deparam_percent(zh, vi)
if G.printf_over(zh, fixed):
    raise SystemExit('cy_gui_dict: khoa %%r co %%d dac ta printf > nguon Han %%d sau khi da go %%d'
                     %% ('KHOA_DOI_CHUNG', G.n_printf_spec(fixed), G.n_printf_spec(zh), n))
print('KHONG DUNG - le ra phai dung han')
'''

FW = u'％'
CASES = [
    # 1. lanh: tham so that, khong flag -> khong dong vao
    (u'%s0 级', u'%s0 cấp'),
    # 2. `% g` moi sinh khi dich (nguon viet `50％`)
    (u'giảm xuống 50' + FW, u'giảm xuống 50% giá trị'),
    # 3. `%#c`: dau phan tram dinh ngay ma mau
    (u'#G100%成功#cfff263', u'#G100%#cfff263 thành công'),
    # 5. dang CO SAN trong nguon Han -> VAN phai go.
    # DINH CHINH 20/09: ban dau toi viet "khong dong toi" (nhanh nay sua ban dich, khong sua CY).
    # Phep do lat lai: nguoi goi day doi so theo THAM SO TAC GIA VIET, khong theo cai `%#c` do van
    # ban sinh ra - nen mot `%#c` thua VAN doc mot doi so khong ton tai du no co trong nguon Han.
    # Do sau khi da sua 134 o theo mo hinh cu: VAN con 195 o doc qua, 16 bang `%s`. Go no luon lam
    # DUNG HON vi tra cac `%sN` phia sau ve dung chi so doi so.
    (u'#G20%#cfff263 a', u'#G20%#cfff263 b'),
    # 5b. tham so THAT nam trong ngan sach doi so -> khong duoc dong toi
    (u'%s0 dat %.2f va %02d', u'%s0 dat %.2f va %02d'),
    # bien: `% n` - lop nang nhat (fastfail)
    (u'trong 30' + FW, u'trong 30% ngày'),
    # bien: `% s` - giai tham chieu con tro rac
    (u'gây 50' + FW, u'gây 50% sát thương'),
]


def main():
    ok = True

    def chk(name, cond, detail=''):
        nonlocal ok
        print(('PASS ' if cond else 'FAIL ') + name + (' | ' + detail if detail else ''))
        ok = ok and cond

    with tempfile.TemporaryDirectory() as td:
        inp = os.path.join(td, 'in.json')
        outp = os.path.join(td, 'out.json')
        script = os.path.join(td, 'child.py')
        with io.open(inp, 'w', encoding='utf-8') as fh:
            json.dump(CASES, fh, ensure_ascii=False)
        with io.open(script, 'w', encoding='utf-8') as fh:
            fh.write(CHILD % {'pipe': PIPE, 'inp': inp, 'outp': outp})
        p = subprocess.run([sys.executable, '-X', 'utf8', script],
                           capture_output=True, text=True, encoding='utf-8', errors='replace')
        chk('cong nap va chay duoc trong tien trinh rieng', p.returncode == 0,
            (p.stderr or '').strip()[:200])
        if p.returncode != 0:
            return 1
        with io.open(outp, encoding='utf-8') as fh:
            r = json.load(fh)

        chk('1. dong lanh: khong doi mot ky tu nao',
            r[0]['n'] == 0 and r[0]['fixed'] == r[0]['vi'] and not r[0]['over_before'],
            r[0]['fixed'])
        chk('2. "50%% gia tri" -> "50%s gia tri", het vuot nguon' % FW,
            r[1]['over_before'] and not r[1]['over_after']
            and r[1]['fixed'] == u'giảm xuống 50' + FW + u' giá trị',
            r[1]['fixed'])
        chk('   khong them/bot mot ky tu VAN BAN nao (chi doi 1 ky tu)',
            len(r[1]['fixed']) == len(r[1]['vi'])
            and r[1]['fixed'].replace(FW, u'%') == r[1]['vi'], r[1]['fixed'])
        chk('3. "100%%#cfff263" -> "100%s#cfff263", ma mau con NGUYEN' % FW,
            r[2]['over_before'] and not r[2]['over_after'] and '#cfff263' in r[2]['fixed'],
            r[2]['fixed'])
        chk('5. dang co san trong nguon Han VAN duoc go (doc doi so khong ton tai)',
            r[3]['n'] == 1 and not r[3]['over_after'] and r[3]['fixed'].count(FW) == 1,
            r[3]['fixed'])
        chk('5b. tham so THAT (%s0/%.2f/%02d) KHONG bi dong toi',
            r[4]['n'] == 0 and r[4]['fixed'] == r[4]['vi'], r[4]['fixed'])
        chk('   bien "%% n" (lop fastfail) duoc sua',
            r[5]['over_before'] and not r[5]['over_after'], r[5]['fixed'])
        chk('   bien "%% s" (lop con tro) duoc sua',
            r[6]['over_before'] and not r[6]['over_after'], r[6]['fixed'])

        # 4. DOI CHUNG AM: mot dong KHONG sua sach duoc phai lam cong DUNG HAN.
        # nguon 0 dac ta, ban dich co MOT tham so that `%s0` (khong flag => cong khong duoc go)
        zh, vi = u'ba mươi phần trăm', u'30% số %s0'
        script2 = os.path.join(td, 'child_raise.py')
        with io.open(script2, 'w', encoding='utf-8') as fh:
            fh.write(CHILD_RAISE % {'pipe': PIPE, 'zh': zh, 'vi': vi})
        p2 = subprocess.run([sys.executable, '-X', 'utf8', script2],
                            capture_output=True, text=True, encoding='utf-8', errors='replace')
        blob = (p2.stdout or '') + (p2.stderr or '')
        chk('4. con sot -> DUNG HAN (rc != 0) va neu ten khoa',
            p2.returncode != 0 and 'KHOA_DOI_CHUNG' in blob,
            'rc=%d %s' % (p2.returncode, blob.strip().splitlines()[-1] if blob.strip() else ''))

        # doi chung am cuoi: phep kiem nay co the TRUOT khong? Lam hong co y mot ky vong.
        chk(u'doi chung am cua chinh phep kiem: `%` ASCII khac `' + FW + u'`',
            FW != u'%' and r[1]['fixed'] != r[1]['vi'])

    print('\n%s cy_gui_dict printf gate' % ('PASS' if ok else 'FAIL'))
    return 0 if ok else 1


if __name__ == '__main__':
    sys.exit(main())
