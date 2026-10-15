#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""i18n-scope: doi `#{KHOA}` -> `#{KHOA@Khung}` trong DUNG nhung tep layout duoc chon.

VI SAO CAN (giong 80-ui-fit-strings.py): `Tools/pipeline/build_canonical_cy.py` dung lai
`Assets/CanonicalCY/Data/InterfaceFolder` tu cac .axp cua CY 3.71 va XOA moi sua doi trong do.
Tep nay la CONG THUC de ap lai.

VI SAO LAM THE NAY: ghi de ban dich la theo KHOA, nhung tran khung la theo KHUNG. Mot khoa bi rut
ngan vi khung HEP NHAT dung no; moi khung khac ganh ban rut gon ma no khong can. Duc them mot khoa
`KHOA@Khung` mang ban DAY DU roi cho rieng khung do tro toi khoa moi thi:
  - khung hep KHONG bi dong toi (khoa goc giu nguyen ban rut gon) => mot dot hong chi anh huong
    dung nhung khung no sua;
  - KHONG doi mot dong C++ va KHONG doi dinh dang bang (StrDictionary van 2 cot).
Gia tri cua khoa moi den tu `Registry/i18n/cy_vi_frame_override.tsv` qua `cy_gui_dict.build()`.

LUAT SO MOT cua mang UI van giu: KHONG noi container theo ty le (2.381 o luoi phu thuoc nhau).
Tep nay chi doi TEN KHOA trong thuoc tinh Text; khong dong vao UnifiedSize/UnifiedPosition/
AbsoluteSize/AbsolutePosition - `verify` kiem dieu do bang cach so byte cua moi thuoc tinh hinh hoc.

Dung:
  python -X utf8 Tools/reapply/i18n-scope/82-frame-keys.py plan
  python -X utf8 Tools/reapply/i18n-scope/82-frame-keys.py apply [--limit N] [--bak <thu muc>]
  python -X utf8 Tools/reapply/i18n-scope/82-frame-keys.py verify
  python -X utf8 Tools/reapply/i18n-scope/82-frame-keys.py revert --bak <thu muc>
  python -X utf8 Tools/reapply/i18n-scope/82-frame-keys.py selftest

`apply` idempotent: chay lan hai khong doi gi. Moi lan ghi deu sao luu ban goc truoc.
"""
import argparse
import hashlib
import json
import os
import re
import shutil
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, '..', '..', '..'))
UI = os.path.join(ROOT, 'Assets', 'CanonicalCY', 'Data', 'InterfaceFolder')
PATCHES = os.path.join(HERE, 'data', 'frame-key-patches.json')
DEFAULT_BAK = os.path.join(ROOT, 'Build', 'Logs', '2026-09-19-i18n-scope', 'reapply-bak')
# thuoc tinh hinh hoc: `verify` khang dinh chung KHONG DOI mot byte nao
GEOM = re.compile(rb'<Property\s+Name="(UnifiedSize|UnifiedPosition|UnifiedAreaRect|AbsoluteSize'
                  rb'|AbsolutePosition|AbsoluteRect|Size|Position)"\s+Value="([^"]*)"')


def load_patches(path=PATCHES):
    with open(path, encoding='utf-8') as fh:
        return json.load(fh)['layouts']


def read(p):
    with open(p, 'rb') as fh:
        return fh.read()


def geom_fingerprint(data):
    return hashlib.sha256(b'|'.join(m.group(0) for m in GEOM.finditer(data))).hexdigest()


def patch_bytes(data, pairs):
    """-> (data moi, {(key, frame): so lan doi}, {(key, frame): so lan DA doi tu truoc})."""
    done, already = {}, {}
    for key, frame in pairs:
        old = ('#{%s}' % key).encode('utf-8')
        new = ('#{%s@%s}' % (key, frame)).encode('utf-8')
        already[(key, frame)] = data.count(new)
        n = data.count(old)
        if n:
            data = data.replace(old, new)
        done[(key, frame)] = n
    return data, done, already


def walk(patches, limit=0):
    items = sorted(patches.items())
    return items[:limit] if limit else items


def targets(rel):
    """Tep phai sua cho mot khung: layout truoc, roi `.lua` cung ten trong cung thu muc.

    Do duoc 20/09: 8/268 cap KHONG nam trong `.layout.xml` - cot `source` cua overflow.csv ghi
    `lua`, tuc chinh script cua khung do dat chuoi luc chay (vi du `PetSkillStudy.lua` dat
    `#{INTERFACE_XML_789}` cho `PetSkillStudy_Static3`). Chi nhan `.lua` CUNG TEN voi layout, de
    khong dong vao mot script dung chung cho nhieu khung.
    """
    p = os.path.join(UI, rel.replace('/', os.sep))
    lua = p[:-len('.layout.xml')] + '.lua' if p.endswith('.layout.xml') else None
    return [x for x in (p, lua) if x and os.path.exists(x)]


def cmd_plan(args):
    patches = load_patches()
    tot = hit = miss = 0
    for rel, pairs in walk(patches, args.limit):
        ts = targets(rel)
        if not ts:
            print('THIEU TEP:', rel)
            miss += 1
            continue
        seen = {(k, f): 0 for k, f in (tuple(x) for x in pairs)}
        for t in ts:
            data = read(t)
            _d, done, already = patch_bytes(data, pairs)
            for kf, n in done.items():
                seen[kf] += n + already[kf]
        for kf, n in sorted(seen.items()):
            tot += 1
            if n:
                hit += 1
            else:
                miss += 1
                print('KHONG THAY #{%s} trong %s (va .lua cung ten)' % (kf[0], rel))
    print('cap (khoa, khung): %d | tim thay %d | khong thay %d | tep %d'
          % (tot, hit, miss, len(walk(patches, args.limit))))
    return 1 if miss else 0


def cmd_apply(args):
    patches = load_patches()
    bak = args.bak or DEFAULT_BAK
    os.makedirs(bak, exist_ok=True)
    wrote = same = 0
    changed = []
    for rel, pairs in walk(patches, args.limit):
        for t in targets(rel):
            data = read(t)
            new, done, _al = patch_bytes(data, pairs)
            if new == data:
                same += 1
                continue
            if geom_fingerprint(new) != geom_fingerprint(data):
                raise SystemExit('TU CHOI: %s doi thuoc tinh hinh hoc - khong duoc phep' % t)
            trel = os.path.relpath(t, UI)
            b = os.path.join(bak, trel)
            os.makedirs(os.path.dirname(b), exist_ok=True)
            if not os.path.exists(b):
                shutil.copy2(t, b)
            with open(t, 'wb') as fh:
                fh.write(new)
            wrote += 1
            changed.append({'file': trel.replace(os.sep, '/'),
                            'pairs': [[k, f, n] for (k, f), n in sorted(done.items()) if n],
                            'sha_before': hashlib.sha256(data).hexdigest()[:16],
                            'sha_after': hashlib.sha256(new).hexdigest()[:16]})
    with open(os.path.join(bak, 'applied.json'), 'w', encoding='utf-8') as fh:
        json.dump(changed, fh, ensure_ascii=False, indent=1)
    print('da ghi %d tep | da co san %d | sao luu %s' % (wrote, same, bak))
    return 0


def cmd_verify(args):
    patches = load_patches()
    bad = 0
    for rel, pairs in walk(patches, args.limit):
        blobs = {t: read(t) for t in targets(rel)}
        for key, frame in (tuple(x) for x in pairs):
            new = ('#{%s@%s}' % (key, frame)).encode('utf-8')
            old = ('#{%s}' % key).encode('utf-8')
            if sum(d.count(new) for d in blobs.values()) == 0:
                print('HONG %s: thieu #{%s@%s}' % (rel, key, frame))
                bad += 1
            for t, d in blobs.items():
                if d.count(old):
                    print('HONG %s: con #{%s} chua doi' % (os.path.relpath(t, UI), key))
                    bad += 1
    print('verify: hong=%d' % bad)
    return 1 if bad else 0


def cmd_prune(args):
    """Bo khoi ban va VA khoi Registry nhung cap khong tim thay `#{KHOA}` o dau ca.

    Do duoc 20/09: 1/268 cap nhu the (`INTERFACE_XML_789` @ `equiprepair`) - bo do
    `measure_ui_text` truy duoc chuoi cua o qua mot duong khac (khong phai layout, cung khong
    phai `.lua` cung ten), nen o do KHONG the tro sang khoa moi. De lai thi Registry sinh mot
    dong tu dien khong ai dung toi, va `verify` do vinh vien.
    """
    patches = load_patches()
    drop = []
    for rel, pairs in sorted(patches.items()):
        blobs = [read(t) for t in targets(rel)]
        keep = []
        for key, frame in (tuple(x) for x in pairs):
            old = ('#{%s}' % key).encode('utf-8')
            new = ('#{%s@%s}' % (key, frame)).encode('utf-8')
            if any(d.count(old) or d.count(new) for d in blobs):
                keep.append([key, frame])
            else:
                drop.append((key, frame))
        patches[rel] = keep
    patches = {k: v for k, v in patches.items() if v}
    with open(PATCHES, 'w', encoding='utf-8') as fh:
        json.dump({'layouts': patches}, fh, ensure_ascii=False, indent=1)
    reg = os.path.join(ROOT, 'Registry', 'i18n', 'cy_vi_frame_override.tsv')
    gone = 0
    if drop and os.path.exists(reg):
        dropset = set(drop)
        with open(reg, encoding='utf-8', newline='') as fh:
            lines = fh.read().split('\n')
        keep = [lines[0]]
        for ln in lines[1:]:
            p = ln.rstrip('\r').split('\t')
            if len(p) >= 2 and (p[0], p[1]) in dropset:
                gone += 1
                continue
            keep.append(ln)
        with open(reg, 'w', encoding='utf-8', newline='') as fh:
            fh.write('\n'.join(keep))
    print('bo %d cap khong va duoc | xoa %d dong Registry' % (len(drop), gone))
    for k, f in drop:
        print('    %s @ %s' % (k, f))
    print('CHAY LAI: python -B Tools/pipeline/cy_i18n_apply.py apply')
    return 0


def cmd_revert(args):
    bak = args.bak or DEFAULT_BAK
    n = 0
    for dp, _d, fs in os.walk(bak):
        for fn in fs:
            if not (fn.endswith('.layout.xml') or fn.endswith('.lua')):
                continue
            src = os.path.join(dp, fn)
            rel = os.path.relpath(src, bak)
            shutil.copy2(src, os.path.join(UI, rel))
            n += 1
    print('da tra lai %d tep tu %s' % (n, bak))
    return 0


def cmd_selftest(_args):
    ok = True

    def chk(n, c, d=''):
        nonlocal ok
        print(('PASS ' if c else 'FAIL ') + n + (' | ' + d if d else ''))
        ok = ok and c
    src = (b'<Window Type="T" Name="W">\n'
           b'<Property Name="UnifiedSize" Value="{{0,60},{0,16}}" />\n'
           b'<Property Name="Text" Value="#{K1}" />\n'
           b'<Property Name="Tooltip" Value="#{K1}" />\n'
           b'<Property Name="Text" Value="#{K1X}" />\n</Window>\n')
    out, done, already = patch_bytes(src, [['K1', 'fr']])
    chk('doi CA HAI cho cua khoa', done[('K1', 'fr')] == 2, 'n=%d' % done[('K1', 'fr')])
    chk('KHONG dung vao khoa co tien to trung (#{K1X})', b'#{K1X}' in out)
    chk('khong dong vao thuoc tinh hinh hoc',
        geom_fingerprint(out) == geom_fingerprint(src))
    out2, done2, already2 = patch_bytes(out, [['K1', 'fr']])
    chk('idempotent: chay lan hai khong doi gi', out2 == out and done2[('K1', 'fr')] == 0
        and already2[('K1', 'fr')] == 2)
    # doi chung am: neu ai do doi thuoc tinh hinh hoc thi dau van tay PHAI khac
    hacked = out.replace(b'{{0,60},{0,16}}', b'{{0,90},{0,16}}')
    chk('DOI CHUNG AM: dau van tay hinh hoc BIET doi khi hinh hoc bi sua',
        geom_fingerprint(hacked) != geom_fingerprint(out))
    print('SELFTEST', 'OK' if ok else 'FAILED')
    return 0 if ok else 1


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('cmd', choices=('plan', 'apply', 'verify', 'prune', 'revert', 'selftest'))
    ap.add_argument('--bak', default='')
    ap.add_argument('--limit', type=int, default=0, help='chi lam N tep dau (ap theo dot nho)')
    a = ap.parse_args()
    return {'plan': cmd_plan, 'apply': cmd_apply, 'verify': cmd_verify, 'prune': cmd_prune,
            'revert': cmd_revert, 'selftest': cmd_selftest}[a.cmd](a)


if __name__ == '__main__':
    sys.exit(main())
