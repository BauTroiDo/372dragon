# -*- coding: utf-8 -*-
"""bullet-fx (19/09/2026): MO PHONG CHINH XAC EffectManager::parseEffectFile tren all.effect.

VI SAO CAN: Src/Engine/WXCore/EffectSystem/WXEffectManager.cpp:596 `parseEffectFile` **return**
(bo ca phan con lai cua tep, KHONG bao gi ra man hinh choi) khi gap:
  (a) dong o muc goc khong phai dung `effect <ten>` (split theo "\t " phai ra DUNG 2 phan tu);
  (b) dong `element` co < 2 phan tu.
=> mot dong hong o giua tep lam MOI template phia sau BIEN MAT im lang. Do la bay da ghi trong
   tri nho du an ("them hieu ung vao all.effect: dong chu thich lam parser chet im lang").

DINH NGHIA DEM (neu ro de doi chieu duoc):
  "template ton tai voi engine" = `createEffectTemplate(ten)` DA chay truoc khi parser dung.
  So nay phai bang so dong `effect <ten>` dem tho CHI KHI parser chay het tep.
  Hai so lech nhau = do dai phan bi cat.

MO PHONG DUNG NGUYEN VAN NGU NGHIA CUA ENGINE:
  - DataStream::getLine  -> tach theo '\n', bo '\r' cuoi, roi StringUtil::trim (2 dau, " \t\r\n").
  - bo qua dong rong va dong bat dau bang "//" (kiem tren chuoi DA trim).
  - StringUtil::split(line, "\t ") -> bo dau phan cach lien tiep, khong gioi han so lan tach.
  - skipToNextOpenBrace / skipToNextCloseBrace: doc toi khi dong == "{" / "}".
  - createEffectTemplate: ten TRUNG -> OGRE_EXCEPT (nem) -> tinh la loi nghiem trong.

DUNG:
  python -B Tools/fx/bullet/effect_parse_sim.py --file <all.effect> --out <file>.json
  python -B Tools/fx/bullet/effect_parse_sim.py --selftest        # doi chung am: phep do co biet truot khong
"""
import argparse
import hashlib
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
CYS = os.path.abspath(os.path.join(HERE, '..', '..', '..'))
DEFAULT = os.path.join(CYS, 'Assets', 'CanonicalCY', 'Data', 'EffectFolder', 'all.effect')
DELIMS = b' \t'


def dec(bs):
    try:
        return bs.decode('utf-8')
    except UnicodeDecodeError:
        return bs.decode('gbk', 'replace')


def split_ws(b):
    """Ogre StringUtil::split(str, "\t ") tren byte: bo phan cach lien tiep."""
    out, cur = [], bytearray()
    for ch in b:
        if ch in DELIMS:
            if cur:
                out.append(bytes(cur))
                cur = bytearray()
        else:
            cur.append(ch)
    if cur:
        out.append(bytes(cur))
    return out


def lines_of(raw):
    """DataStream::getLine: tach '\n', bo '\r' cuoi, StringUtil::trim hai dau."""
    for ln in raw.split(b'\n'):
        yield ln.strip(b' \t\r\n')


class Sim(object):
    def __init__(self, raw):
        self.lines = list(lines_of(raw))
        self.i = 0

    def eof(self):
        return self.i >= len(self.lines)

    def get(self):
        ln = self.lines[self.i] if self.i < len(self.lines) else b''
        self.i += 1
        return ln

    def skip_to(self, brace):
        line = b''
        while not self.eof() and line != brace:
            line = self.get()


def parse(raw):
    """Tra ve (templates_theo_thu_tu, ket_qua) — mo phong parseEffectFile."""
    s = Sim(raw)
    made, seen = [], set()
    stop = None
    depth_effect = None
    while not s.eof():
        lineno = s.i + 1
        line = s.get()
        if len(line) == 0 or line[:2] == b'//':
            continue
        if depth_effect is None:
            v = split_ws(line)
            if len(v) != 2 or v[0] != b'effect':
                stop = {'reason': 'Bad effect system name line', 'line_no': lineno,
                        'line': dec(line)[:200], 'parts': len(v)}
                break
            name = dec(v[1])
            if name in seen:
                stop = {'reason': 'DUPLICATE effect template (OGRE_EXCEPT nem)',
                        'line_no': lineno, 'line': dec(line)[:200], 'parts': len(v)}
                break
            seen.add(name)
            made.append(name)
            depth_effect = name
            s.skip_to(b'{')
        else:
            if line == b'}':
                depth_effect = None
            elif line[:7] == b'element':
                v = split_ws(line)
                if len(v) < 2:
                    stop = {'reason': 'Bad effect system element line', 'line_no': lineno,
                            'line': dec(line)[:200], 'parts': len(v)}
                    break
                s.skip_to(b'{')
                # parseNewElement doc tiep toi dau '}' cua element
                s.skip_to(b'}')
            else:
                pass  # parseEffectAttrib: chi ghi log, KHONG dung parser
    return made, stop, len(s.lines), s.i


def naive_count(raw):
    """Dem tho: moi dong bat dau bang 'effect ' — so doi chieu doc lap."""
    n = 0
    for ln in lines_of(raw):
        if ln[:7] == b'effect ' or ln[:7] == b'effect\t':
            n += 1
    return n


def selftest():
    """Doi chung am: phep do PHAI phat hien duoc loi khi loi con do."""
    ok = b'effect a\n{\n\telement Particle\n\t{\n\t\tX 1\n\t}\n}\n' \
         b'effect b\n{\n}\n' \
         b'effect c\n{\n}\n'
    cases = []
    made, stop, _, _ = parse(ok)
    cases.append(('sach: 3 template, khong dung', made == ['a', 'b', 'c'] and stop is None))
    bad = ok.replace(b'effect b\n', b'effect b co dau cach\n')
    made2, stop2, _, _ = parse(bad)
    cases.append(('ten co dau cach -> DUNG, mat phan sau',
                  made2 == ['a'] and stop2 is not None and stop2['parts'] == 5))
    dup = b'effect a\n{\n}\neffect a\n{\n}\n'
    made3, stop3, _, _ = parse(dup)
    cases.append(('ten trung -> nem', made3 == ['a'] and stop3 is not None and 'DUPLICATE' in stop3['reason']))
    noise = b'rac o muc goc\neffect a\n{\n}\n'
    made4, stop4, _, _ = parse(noise)
    cases.append(('rac o muc goc -> DUNG ngay dong 1', made4 == [] and stop4 and stop4['line_no'] == 1))
    cmt = b'// chu thich\neffect a\n{\n}\n'
    made5, stop5, _, _ = parse(cmt)
    cases.append(('// chu thich hop le -> khong dung', made5 == ['a'] and stop5 is None))
    # dem tho phai BANG so template khi parser chay het, va LON HON khi bi cat
    cases.append(('dem tho == mo phong khi sach', naive_count(ok) == len(made)))
    cases.append(('dem tho > mo phong khi bi cat', naive_count(bad) > len(made2)))
    bad_el = b'effect a\n{\n\telement\n\t{\n\t}\n}\neffect b\n{\n}\n'
    made6, stop6, _, _ = parse(bad_el)
    cases.append(('element thieu tham so -> DUNG',
                  made6 == ['a'] and stop6 is not None and 'element' in stop6['reason']))
    bad_ = all(v for _, v in cases)
    for name, v in cases:
        print('%-46s %s' % (name, 'PASS' if v else 'FAIL'))
    print('selftest: %d/%d PASS' % (sum(1 for _, v in cases if v), len(cases)))
    return 0 if bad_ else 1


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--file', default=DEFAULT)
    ap.add_argument('--out')
    ap.add_argument('--selftest', action='store_true')
    a = ap.parse_args()
    if a.selftest:
        sys.exit(selftest())

    raw = open(a.file, 'rb').read()
    made, stop, total_lines, consumed = parse(raw)
    naive = naive_count(raw)
    res = {
        'schema': 1,
        'file': os.path.abspath(a.file),
        'sha256': hashlib.sha256(raw).hexdigest(),
        'byte': len(raw),
        'total_lines': total_lines,
        'lines_consumed_before_stop': consumed,
        'templates_created_by_engine': len(made),
        'naive_effect_lines': naive,
        'thieu_do_bi_cat': naive - len(made),
        'stopped': stop,
        'first_5': made[:5],
        'last_5': made[-5:],
    }
    if a.out:
        os.makedirs(os.path.dirname(os.path.abspath(a.out)), exist_ok=True)
        json.dump({**res, 'templates': made}, open(a.out, 'w', encoding='utf-8'),
                  ensure_ascii=False, indent=1)
    print(json.dumps(res, ensure_ascii=False, indent=1))


if __name__ == '__main__':
    main()
