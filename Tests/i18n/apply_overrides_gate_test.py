# -*- coding: utf-8 -*-
"""Doi chung cho CONG `validate()` moi cam vao `Tools/ui-fit/apply_overrides.py`.

VI SAO CO CONG NAY: duong ong rut ngan cua `ui-fit-2` sinh du lieu vao
`Registry/i18n/cy_vi_override.tsv` ma KHONG he chay `cy_translate.validate()`. Do duoc 20/09:
62/3.339 dong da vao Registry voi tui token LECH so voi chu Han nguon - trong do 6 dong THEM ma
dieu khien (engine NUOT chu), 1 dong lech CHI SO tham so, 5 dong mat han mot `%sN`, 1 dong mat
the `#{_INFOMAP...}`.

Mot cong khong biet truot thi khong phai cong. Phep kiem nay chay `apply_overrides.py --dry`
that (tien trinh rieng, tren mot ban sao Registry trong thu muc tam) voi ba lo dong:

  1. lo LANH                      -> rc 0, cong cho qua;
  2. lo co mot dong THEM ma `#T`  -> rc khac 0 VA in ra dung ten khoa do;
  3. lo hong + `--allow-token-drift` -> rc 0 (co cua thoat CO Y, nhung phai go tay).

Chay:  python -X utf8 Tests/i18n/apply_overrides_gate_test.py
"""
import io
import os
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, '..', '..'))
TOOL = os.path.join(REPO, 'Tools', 'ui-fit', 'apply_overrides.py')
OVERRIDE = os.path.join(REPO, 'Registry', 'i18n', 'cy_vi_override.tsv')

# Khoa that cua CY 3.71, chu Han nguon `关闭装备属性比较` (khong co mot ma dieu khien nao).
BAD_KEY = 'ZBBJ_100816_03'
# Khoa that, nguon `确定`.
GOOD_KEY = 'SFDJ_240117_55'


def rows_file(path, rows):
    with io.open(path, 'w', encoding='utf-8', newline='\n') as fh:
        fh.write('ident\tvi\tnote\n')
        for k, v in rows:
            fh.write('#%s\t%s\tphep kiem cong\n' % (k, v))


def run(rows_path, override, extra=()):
    cmd = [sys.executable, '-X', 'utf8', TOOL, '--rows', rows_path,
           '--override', override, '--dry'] + list(extra)
    p = subprocess.run(cmd, capture_output=True, text=True, encoding='utf-8', errors='replace')
    return p.returncode, (p.stdout or '') + (p.stderr or '')


def main():
    ok = True

    def chk(name, cond, detail=''):
        nonlocal ok
        print(('PASS ' if cond else 'FAIL ') + name + (' | ' + detail if detail else ''))
        ok = ok and cond

    with tempfile.TemporaryDirectory() as td:
        over = os.path.join(td, 'cy_vi_override.tsv')
        with io.open(OVERRIDE, encoding='utf-8', newline='') as fh:
            data = fh.read()
        with io.open(over, 'w', encoding='utf-8', newline='') as fh:
            fh.write(data)

        good = os.path.join(td, 'good.tsv')
        rows_file(good, [(GOOD_KEY, 'Xác nhận')])
        rc, out = run(good, over)
        chk('lo LANH duoc cho qua', rc == 0, 'rc=%d %s' % (rc, out.strip().splitlines()[-1:]))

        bad = os.path.join(td, 'bad.tsv')
        rows_file(bad, [(GOOD_KEY, 'Xác nhận'), (BAD_KEY, 'Đóng so sánh #T.bị# #Chỉ số#')])
        rc2, out2 = run(bad, over)
        chk('lo co dong THEM ma dieu khien bi TU CHOI', rc2 != 0, 'rc=%d' % rc2)
        chk('bao dung ten khoa hong', BAD_KEY in out2,
            out2.strip().splitlines()[-1] if out2.strip() else '')
        chk('KHONG ghi gi khi bi tu choi',
            io.open(over, encoding='utf-8', newline='').read() == data)

        rc3, _o3 = run(bad, over, ['--allow-token-drift'])
        chk('cua thoat CO Y (--allow-token-drift) van di qua duoc', rc3 == 0, 'rc=%d' % rc3)

    print('KET QUA:', 'OK' if ok else 'FAILED')
    return 0 if ok else 1


if __name__ == '__main__':
    sys.exit(main())
