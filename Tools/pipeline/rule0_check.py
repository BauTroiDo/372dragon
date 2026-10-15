# -*- coding: utf-8 -*-
"""QUY TAC 0 — cong kiem ban giao: nhanh co THAT SU hoc tu phien ban song khong?

Nguoi dung dat luat 20/09 ("hoc tap truoc khi chinh sua hay thay doi, tu phan bien, neu ap dung
duoc thi moi ap dung") va nhac lai "hoc tap de sua chua". Tai lieu goc: Docs/08-BAY-VA-QUY-TAC_vi.md
muc QUY TAC 0.

VI SAO CAN MOT CONG, KHONG CHI MOT LOI DAN: trong phien nay moi luat chi ton tai duoi dang loi khuyen
deu bi vi pham it nhat mot lan, ke ca boi chinh nguoi viet ra no. Cai song sot la cai da thanh script
chan duong (cys_stage_datatree_check.py, dll_cluster_check.py, 85-stage-data-guard.py).

CONG NAY KIEM DUOC GI — va KHONG kiem duoc gi:
  KIEM DUOC  : ban giao co trich dan duong dan CU THE toi cay song khong, va co muc phan bien khong.
  KHONG KIEM : trich dan do co DUNG khong, doc co ky khong. Mot nhanh quyet gian lan van gian lan duoc.
               Cong nay chi lam viec "quen mat" tro nen KHONG THE, chu khong lam viec "noi doi" thanh
               khong the. Ghi ro de khong ai doc ket qua PASS rong hon nghia that cua no.

DUNG:
  python Tools/pipeline/rule0_check.py <duong-dan-ban-giao.md> [...]
  python Tools/pipeline/rule0_check.py --order <ban-giao.md>   (kiem them THU TU MUC: hoc truoc, va sau)
  python Tools/pipeline/rule0_check.py --selftest
"""
import re
import sys

# Ba cay song, deu CHI DOC. Bat ca dang Windows lan dang WSL/posix, ca dang co escape trong markdown.
LIVE_PATTERNS = [
    r'(?i)(?:C:)?[\\/]*TLBB[\\/]+085[\\/]+client(?![_A-Za-z0-9])',
    r'(?i)(?:C:)?[\\/]*TLBB[\\/]+085[\\/]+client_GL',
    r'(?i)\bclient_GL[\\/]',
    r'(?i)\bclient[\\/](?:Bin|Data|Patch)',
    r'(?i)DATA\s+NEW[\\/]+CY\s+Game',
    r'(?i)\bCY\s+Game[\\/]',
]

# Muc phan bien: phai co dau hieu nhanh da HOI "tien de con dung khong", khong chi chep.
CRITIQUE_PATTERNS = [
    r'(?i)ph[ảa]n\s*bi[ệe]n',
    r'(?i)ti[ềe]n\s*đ[ềe]',
    r'(?i)kh[ôo]ng\s+[áa]p\s+d[ụu]ng\s+đ[ưu][ợo]c',
    r'(?i)b[áa]c\s+b[ỏo]',
]

MIN_LIVE_HITS = 2


def scan(text):
    live = []
    for p in LIVE_PATTERNS:
        for m in re.finditer(p, text):
            s = m.group(0).strip()
            if s not in live:
                live.append(s)
    crit = [p for p in CRITIQUE_PATTERNS if re.search(p, text)]
    return live, crit


def verdict(text):
    live, crit = scan(text)
    ok_live = len(live) >= MIN_LIVE_HITS
    ok_crit = len(crit) >= 1
    return ok_live and ok_crit, live, crit


# --- thu tu muc (20/09 15:40): HOC + VI SAI phai dung TRUOC nguyen nhan / ban va -------------------
# Nguoi dung nhac lan thu tu: "hoc hoi va phan bien thay vi tu mo". Dinh nghia "tu mo" = neu gia thuyet
# ve ma cua ta truoc khi doc cay song. Ban giao phan anh trinh tu lam viec, nen kiem thu tu TIEU DE.
LEARN_HEAD = re.compile(r'(?i)c[âa]y\s*s[ốo]ng|phi[êe]n\s*b[ảa]n\s*s[ốo]ng|vi\s*sai')
DIAG_HEAD = re.compile(r'(?i)nguy[êe]n\s*nh[âa]n|ch[ẩa]n\s*[đd]o[áa]n|b[ảa]n\s*v[áa]|[đd][ãa]\s*v[áa]')


def order_verdict(text):
    """(ok, ly_do). Tieu de = dong bat dau bang '#'."""
    first_learn = first_diag = None
    for i, line in enumerate(text.splitlines()):
        if not line.lstrip().startswith('#'):
            continue
        if first_learn is None and LEARN_HEAD.search(line):
            first_learn = i
        if first_diag is None and DIAG_HEAD.search(line):
            first_diag = i
    if first_learn is None:
        return False, 'khong co muc "CAY SONG LAM THE NAO" / "BANG VI SAI"'
    if first_diag is not None and first_diag < first_learn:
        return False, 'muc nguyen nhan/ban va (dong %d) dung TRUOC muc cay song (dong %d)' % (
            first_diag + 1, first_learn + 1)
    return True, 'muc cay song o dong %d%s' % (
        first_learn + 1, '' if first_diag is None else ', truoc muc nguyen nhan/ban va (dong %d)' % (first_diag + 1))


def check_file(path, order=False):
    try:
        with open(path, encoding='utf-8', errors='replace') as f:
            text = f.read()
    except OSError as e:
        print('  KHONG DOC DUOC: %s (%s)' % (path, e))
        return False
    ok, live, crit = verdict(text)
    print('  %-8s %s' % ('DAT' if ok else 'KHONG DAT', path))
    print('        trich dan cay song: %d (can >=%d) %s' % (len(live), MIN_LIVE_HITS, live[:4]))
    print('        dau hieu phan bien: %d (can >=1) %s' % (len(crit), len(crit) and 'co' or 'KHONG CO'))
    if not ok:
        print('        => Ban giao phai co: (a) duong dan CU THE toi client/client_GL/CY Game da doc,')
        print('           (b) mot muc noi ro tien de nao CON DUNG va tien de nao DA DOI o cay ta.')
    if order:
        ook, why = order_verdict(text)
        print('        thu tu muc        : %s (%s)' % ('DAT' if ook else 'KHONG DAT', why))
        ok = ok and ook
    return ok


SELFTEST = [
    # (nhan, van ban, ky vong)
    ('du ca hai', r'Doc client\Data\InterfaceFolder\SceneMap.lua va client_GL\Data\... '
                  r'Phan bien: tien de m_nXCount=1 da doi o cay ta.', True),
    ('thieu phan bien', r'Doc client\Data\... va client_GL\Data\... roi vá theo.', False),
    ('thieu trich dan', 'Toi da phan bien ky tien de truoc khi vá.', False),
    ('chi MOT trich dan', r'Doc client_GL\Data\x. Phan bien: tien de con dung.', False),
    ('rong', '', False),
    # doi chung AM: nhac ten cay ma KHONG phai duong dan thi khong duoc tinh
    ('noi ten suong, khong duong dan', 'Toi co tham khao client va CY Game. Da phan bien tien de.', False),
    # dang WSL/posix
    ('dang posix', '/mnt/c/TLBB/085/client_GL/Data/a va /mnt/c/TLBB/085/client/Bin64/Game.exe. '
                   'Phan bien: tien de doi.', True),
    ('bac bo cung tinh la phan bien', r'client_GL\Data\a, client\Bin\b. Toi bac bo gia thuyet do.', True),
]


ORDER_SELFTEST = [
    ('hoc truoc, va sau',
     '\n'.join(['# X', '## Cay song lam the nao', '..', '## Bang vi sai', '..', '## Nguyen nhan', '..', '## Ban va']),
     True),
    ('va TRUOC hoc',
     '\n'.join(['# X', '## Nguyen nhan', '..', '## Cay song lam the nao']), False),
    ('khong co muc hoc',
     '\n'.join(['# X', '## Nguyen nhan', '..', '## Ban va']), False),
    ('chi co muc hoc',
     '\n'.join(['# X', '## Phien ban song lam gi']), True),
    # doi chung AM: chu "cay song" nam trong THAN BAI chu khong phai tieu de thi KHONG duoc tinh
    ('cay song chi o than bai',
     '\n'.join(['# X', '## Nguyen nhan', 'toi co doc cay song']), False),
    ('co dau tieng Viet',
     '\n'.join(['# X', '## CÂY SỐNG LÀM THẾ NÀO', '## BẢNG VI SAI', '## NGUYÊN NHÂN']), True),
]


def selftest():
    bad = 0
    for label, text, want in ORDER_SELFTEST:
        got, why = order_verdict(text)
        mark = 'ok ' if got == want else 'SAI'
        if got != want:
            bad += 1
        print('  %s [thu tu] %-26s mong=%-5s duoc=%-5s (%s)' % (mark, label, want, got, why))
    for label, text, want in SELFTEST:
        got, live, crit = verdict(text)
        mark = 'ok ' if got == want else 'SAI'
        if got != want:
            bad += 1
        print('  %s %-32s mong=%-5s duoc=%-5s live=%d crit=%d' %
              (mark, label, want, got, len(live), len(crit)))
    print('selftest: %d/%d' % (len(SELFTEST) + len(ORDER_SELFTEST) - bad, len(SELFTEST) + len(ORDER_SELFTEST)))
    return bad == 0


def main(argv):
    if not argv or argv[0] == '--selftest':
        ok = selftest()
        if not argv:
            print('\ndung: python Tools/pipeline/rule0_check.py <ban-giao.md> [...]')
        return 0 if ok else 1
    order = '--order' in argv
    argv = [a for a in argv if a != '--order']
    allok = True
    print('QUY TAC 0 - cong kiem ban giao%s' % (' (kem THU TU MUC)' if order else ''))
    for p in argv:
        if not check_file(p, order=order):
            allok = False
    print('KET QUA: %s' % ('DAT' if allok else 'KHONG DAT'))
    return 0 if allok else 1


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
