#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""CYS-FXFINISH (fx-finish, 20/09/2026) - cham A/B cho bản vá "decal nằm phẳng".

Vi sao KHONG cham bang CY (khac han fxcy2_projector_ab.py):
    fx-cy-2 cham canh `=1` bang "lech tam vet so voi CY phai 0-20 px" va truot (180-193 px).
    Muc 3 cua nhiem vu da tra loi cau hoi goc: vet trong khung hinh CY DUNG LA
    aura_rune_projector* (cung vat lieu Game/AuraRune0, cung net ve vang, cung thoi diem), NHUNG
    CY chi to MOT MANH TU GIAC canh THANG nen den, con ta to TOAN BO dau chan hinh tron
    alpha-blend. Lay tam/be ngang cua hai thu khac loai do lam thuoc do nhau la SAI PHAM TRU.
    Bo cham nay vi vay cham TA-so-TA: canh CYS_FXPROJ=0 so canh CYS_FXPROJ=1, va lay moc tu hai
    hieu ung doi chung NAM TRONG CUNG LUOT (REAL13, Serg02 - khong phai Projector, bam cung
    diem gan 脚下光圈点).

Nguong da dang ky TRUOC khi chay:
    Build\\Logs\\2026-09-20-fx-finish\\nguong-dang-ky-truoc.txt  (cung so voi cac hang duoi day)

Dung:
    python Tools/fx/fxfinish_flat_ab.py --batch b09 --rep0 6 --rep1 7
    python Tools/fx/fxfinish_flat_ab.py --selftest
"""

import argparse
import json
import os
import re
import sys

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, 'baseline'))

# BAY DA SAP NGAY TRONG LUOT CHAY THU CUA CHINH BO DO NAY (cung ho voi bay 1 cua projsize):
# fxbase_compare.py tu suy ROOT tu vi tri TEP CUA NO. Chay ban trong mot WORKTREE thi ROOT thanh
# worktree, va Build\Logs\2026-09-19-fx-cy-baseline o do RONG => bo do bao "thu muc=False" cho ca
# hai canh, tuc bao INVALID vi mot ly do hoan toan gia. Kho anh cua lo b09 la TAI NGUYEN CHUNG
# cua CAY CHINH; ghim cung duong ve cay chinh, dung de no tuong doi theo worktree.
CYS_MAIN = r'C:\TLBB\085\CY-Source'

# ---------------------------------------------------------------------------------------------
# NGUONG - DANG KY TRUOC KHI CHAY. Khong duoc sua sau khi co so lieu.
# The trong WXClient.log la "fx-<fid>" (parse_our_run: tag = label.rsplit('-',1)[0]).
PROJ_TAGS = ['fx-A01', 'fx-A02', 'fx-A03', 'fx-A04']
# fx-REAL13 bam DUNG diem gan cua nhom Projector (脚下光圈点) => dung lam MOC.
# fx-Serg02 bam 身体受击点 (diem chiu don tren than), KHAC diem gan => chi dung lam doi chung
# "ban va khong dung vao thu khac", KHONG dung lam moc.
ANCHOR_TAG = 'fx-REAL13'
# fx-Serg02 CHI de IN RA, KHONG lam o cham: fx-cy-2 muc 5c da do chinh no tren hai luot CUNG
# binary va duoc D = 4,70 ("khong lap lai duoc ngay ca voi chinh minh"); o luot thu r4/r5 no
# khong he duoc ve o canh 0. Mot doi chung khong lap lai duoc thi khong phai doi chung.
CTRL_TAGS = ['fx-REAL13']
INFO_TAGS = ['fx-Serg02']

MIN_SHOTS = 30            # A1
MIN_DRAWN_PIXELS = 3000   # A5: mot khung duoc coi la "co ve"
MIN_DRAWN_FRAMES = 3      # A5

#
# PHIEN BAN 2 (13:2x). Ban 1 da chay THU tren hai luot CO SAN cua fx-cy-2 (ours\b09-r4 = fix 0,
# r5 = fix 1, MOT BINARY KHAC) va chinh luot thu do bat duoc mot o DAT SAI cua ban 1:
#   o D3 cu = "|tam cum canh 1 - MOC| <= 70 px" truot 4/4 (do 100-130 px) DU anh cho thay decal
#   nam dung duoi chan NPC. Ly do: MOC lay tu fx-REAL13 (buff_fengxue_01) la mot hieu ung HAT,
#   hat BAY LEN, nen tam dam may hat nam CAO HON diem gan khoang 100 px theo truc Y (hop bao cua
#   no o luot thu: [651,186,786,262], trong khi decal mat dat o y ~325). Tuc o D3 cu do "chenh
#   lech hinh hoc giua mot dam hat va mot decal mat dat", khong do "decal co dung tam khong".
# Sua: bo o theo KHOANG CACH TUYET DOI theo ca hai truc; thay bang hai o do dung dieu can noi:
#   D3a = ban va co THAT SU doi cho decal khong (so tam canh 1 voi tam canh 0 cua CHINH the do)
#   D3b = decal canh 1 co can NGANG vao diem gan khong (chi truc X: hat bay len lam hong truc Y,
#         KHONG lam hong truc X, vi dam hat quanh vong chan van can ngang vao diem gan)
# Chi tiet va so lieu cua luot thu: Build\Logs\2026-09-20-fx-finish\dry-run-tren-luot-fxcy2-r4-r5.txt
# va PHU LUC 2 cua nguong-dang-ky-truoc.txt. Moi con so moi deu suy tu HINH HOC, khong phai tu
# viec "cho no xanh": nguong X = 60 px ~ 0,7 be ngang nhan vat o camera nay (hop HUD loai tru
# nhan vat rong 85 px, fxbase_compare.py:42).
C1_SHARE_MAX = 0.65       # canh 0: cum lon nhat <= 65 % mat na (vo vun)
C2_NCOMP_MIN = 4.0        # canh 0: >= 4 cum lien thong (vo vun)
C_MIN_TAGS = 3            # canh 0: it nhat 3/4 the co khung "co ve" (the thu tu ve gan nhu khong
                          # co gi khi loi con day - do CUNG la trieu chung, khong phai loi do)

D1_SHARE_MIN = 0.75       # canh 1: mot cum chiem >= 75 %
D2_ASPECT_LO = 1.20       # canh 1: hop bao cum lon nhat (hinh tron tren dat -> elip ~1,5)
D2_ASPECT_HI = 1.90
# PHIEN BAN 3 (13:4x) - o D3a cua ban 2 CUNG BI CHINH LUOT THU BAC BO, ghi lai thay vi lang le bo:
#   D3a = "ban va phai DOI CHO decal >= 120 px" do duoc 7,7 / 44,4 / 60,4 px => SAI.
#   Su that: ban va gan nhu KHONG doi cho decal; no lam decal LIEN MACH va NAM PHANG.
#   Con so "lech tam 198-213 px" cua fx-cy-2 luon luon la TA-so-CY, chua bao gio la
#   TA-CHUA-VA so TA-DA-VA. Do la mot dinh chinh THAT cho cach ke chuyen cua fx-cy-2.
#   => bo han D3a. Thay bang D5 (ty so dien tich), con so nay da duoc du doan TRONG BAN 1
#   ("du doan viet truoc: e1/e0 >= 2") khi chua nhin thay gi.
D3B_DX_MAX = 60.0         # canh 1: |x(TAM HOP BAO cum) - x(moc)| <= 60 px (can ngang vao diem gan)
D5_AREA_RATIO_MIN = 2.0   # dien tich to duoc e1/e0 >= 2 (du doan cua ban 1, viet truoc khi do)
D4_CTRL_OFFSET_MAX = 40.0  # doi chung: tam dich <= 40 px giua hai canh
D4_CTRL_AREA_TOL = 0.25    # doi chung: dien tich lech <= 25 % giua hai canh

MIN_COMPONENT = 200        # cum nho hon thi khong dem vao so cum (chi de in ra)


# ---------------------------------------------------------------------------------------------
def largest_component(mask):
    """Tra ve (share, aspect, centroid, bbox, n_components) cua cum lien thong LON NHAT.

    share = diem anh cum lon nhat / tong diem anh mat na.
    Dung 8-lien-thong: mot vet keo let cheo qua cac manh nen van la nhieu cum roi rac, con mot
    decal tron thi la mot cum. Neu mat na rong -> tra ve None.
    """
    import cv2
    m = np.ascontiguousarray(mask.astype(np.uint8))
    total = int(m.sum())
    if total == 0:
        return None
    n, _lab, stats, cents = cv2.connectedComponentsWithStats(m, connectivity=8)
    best_i, best_n = -1, 0
    ncomp = 0
    for i in range(1, n):
        a = int(stats[i, cv2.CC_STAT_AREA])
        if a >= MIN_COMPONENT:
            ncomp += 1
        if a > best_n:
            best_n, best_i = a, i
    if best_i < 0:
        return None
    x = int(stats[best_i, cv2.CC_STAT_LEFT])
    y = int(stats[best_i, cv2.CC_STAT_TOP])
    w = int(stats[best_i, cv2.CC_STAT_WIDTH])
    h = int(stats[best_i, cv2.CC_STAT_HEIGHT])
    aspect = (max(w, h) / float(min(w, h))) if min(w, h) > 0 else 999.0
    return {
        'share': best_n / float(total),
        'aspect': aspect,
        'centroid': [float(cents[best_i][0]), float(cents[best_i][1])],
        'bbox': [x, y, x + w, y + h],
        'pixels': best_n,
        'total': total,
        'ncomp': ncomp,
    }


def dist(a, b):
    return float(np.hypot(a[0] - b[0], a[1] - b[1]))


def med(xs):
    return float(np.median(xs)) if len(xs) else None


# ---------------------------------------------------------------------------------------------
def measure_run(batch, rep):
    """Do MOT luot cua phia `ours`. Tra ve dict theo the."""
    import fxbase_compare as F
    F.ROOT = CYS_MAIN
    F.LOGS = os.path.join(CYS_MAIN, 'Build', 'Logs', '2026-09-19-fx-cy-baseline')
    F.FONT = os.path.join(CYS_MAIN, 'NotoSansSC-Regular.ttf')
    d = os.path.join(F.LOGS, 'ours', '%s-r%d' % (batch, rep))
    if not os.path.isdir(d):
        return {'dir': d, 'exists': False}
    run, base, stable = F.side_run('ours', batch, rep)
    shots = sorted(
        [s for s in run['shots'].values() if s.get('offset_ms') is not None],
        key=lambda s: (s['tag'], s['offset_ms']))
    per = {}
    for s in shots:
        tag = s['tag']
        if tag not in PROJ_TAGS + CTRL_TAGS + INFO_TAGS:
            continue
        m, mask = F.fx_metrics(F.load(s['file']), base, stable=stable)
        if m['pixels'] < MIN_DRAWN_PIXELS:
            continue
        lc = largest_component(mask)
        if lc is None:
            continue
        per.setdefault(tag, []).append({
            'offset_ms': s['offset_ms'], 'area': m['area'], 'pixels': m['pixels'],
            'mask_centroid': m['centroid'], 'lc': lc,
        })
    nshots = len([p for p in os.listdir(d) if p.startswith('cys-replay-') and p.endswith('.png')])
    manifest = None
    mp = os.path.join(d, 'manifest.json')
    if os.path.exists(mp):
        try:
            manifest = json.load(open(mp, encoding='utf-8-sig'))
        except Exception:
            manifest = None
    return {'dir': d, 'exists': True, 'nshots': nshots, 'manifest': manifest, 'per': per,
            'errors': count_errors(os.path.join(d, 'WXClient.log')),
            'render_log': os.path.join(d, 'WXRender.log')}


def count_errors(path):
    """Dem dong ERROR. Doc muc BYTE: WXClient.log/WXRender.log la GBK (bai hoc 19/09)."""
    if not os.path.exists(path):
        return None
    n = 0
    with open(path, 'rb') as f:
        for line in f:
            if b'ERROR' in line:
                n += 1
    return n


PROJ_LINE = re.compile(rb'CYS-FXFINISH projector:.*?fix=(\d)')
CREATE_LINE = re.compile(rb'CYS-FXFINISH create:.*?near_frustum=([\d.eE+-]+)\s+near_elem=([\d.eE+-]+)')


def scan_render_log(path):
    """Doc muc BYTE. Tra ve (so dong fix=0, so dong fix=1, danh sach (near_frustum, near_elem))."""
    f0 = f1 = 0
    creates = []
    if not os.path.exists(path):
        return f0, f1, creates, False
    with open(path, 'rb') as fh:
        for line in fh:
            m = PROJ_LINE.search(line)
            if m:
                if m.group(1) == b'0':
                    f0 += 1
                else:
                    f1 += 1
            c = CREATE_LINE.search(line)
            if c:
                try:
                    creates.append((float(c.group(1)), float(c.group(2))))
                except ValueError:
                    pass
    return f0, f1, creates, True


# ---------------------------------------------------------------------------------------------
def anchor_of(run):
    """Moc = trung vi tam mat na cua fx-REAL13 - hieu ung DUY NHAT trong lo b09 bam dung diem gan
    脚下光圈点 cua nhom Projector. KHONG lay fx-Serg02 lam du phong: no bam 身体受击点 (tren than),
    mot diem gan KHAC, nen no khong phai moc cho vong duoi chan."""
    rows = run.get('per', {}).get(ANCHOR_TAG) or []
    if len(rows) >= 2:
        xs = [r['mask_centroid'][0] for r in rows]
        ys = [r['mask_centroid'][1] for r in rows]
        return [med(xs), med(ys)], ANCHOR_TAG
    return None, None


def score(run0, run1, want_sha=None, out=None):
    L = []
    ok = True
    invalid = False

    def say(s):
        L.append(s)

    def gate(name, passed, detail, hard_invalid=False):
        nonlocal ok, invalid
        say('%-4s %-7s %s' % (name, 'DAT' if passed else 'KHONG', detail))
        if not passed:
            ok = False
            if hard_invalid:
                invalid = True

    say('CYS-FXFINISH - cham A/B "decal nam phang", TA so TA (khong lay CY lam moc)')
    say('=' * 96)
    say('')
    say('--- CONG A: phep do co THAT SU chay khong ---')

    for tag, r in (('canh 0', run0), ('canh 1', run1)):
        gate('A1', r.get('exists') and (r.get('nshots') or 0) >= MIN_SHOTS and r.get('manifest') is not None,
             '%s: thu muc=%s anh=%s manifest=%s' % (tag, r.get('exists'), r.get('nshots'),
                                                    'CO' if r.get('manifest') else 'THIEU'),
             hard_invalid=True)

    m0, m1 = run0.get('manifest') or {}, run1.get('manifest') or {}
    same_bin = (m0.get('game_sha256') and m0.get('game_sha256') == m1.get('game_sha256')
                and m0.get('render_sha256') == m1.get('render_sha256'))
    detail = 'game %s / %s ; render %s / %s' % (
        str(m0.get('game_sha256'))[:16], str(m1.get('game_sha256'))[:16],
        str(m0.get('render_sha256'))[:16], str(m1.get('render_sha256'))[:16])
    if want_sha:
        same_bin = same_bin and m0.get('game_sha256') == want_sha[0] and m0.get('render_sha256') == want_sha[1]
        detail += ' ; khop sha da dang ky: %s' % (m0.get('game_sha256') == want_sha[0]
                                                  and m0.get('render_sha256') == want_sha[1])
    gate('A1b', bool(same_bin), 'CUNG MOT binary tren hai canh: ' + detail, hard_invalid=True)

    e0 = str((m0.get('env') or {}).get('CYS_FXPROJ'))
    e1 = str((m1.get('env') or {}).get('CYS_FXPROJ'))
    gate('A2', e0 == '0' and e1 == '1', 'env CYS_FXPROJ: canh0=%s canh1=%s' % (e0, e1), hard_invalid=True)

    gate('A3', run0.get('errors') == 0 and run1.get('errors') == 0,
         'so dong ERROR trong WXClient.log: canh0=%s canh1=%s (dem TRUOC khi mo minidump)'
         % (run0.get('errors'), run1.get('errors')))

    s0 = scan_render_log(run0.get('render_log', ''))
    s1 = scan_render_log(run1.get('render_log', ''))
    gate('A4', s0[3] and s1[3] and s0[0] > 0 and s0[1] == 0 and s1[1] > 0 and s1[0] == 0,
         'dong "CYS-FXFINISH projector": canh0 fix=0/%d fix=1/%d | canh1 fix=0/%d fix=1/%d'
         % (s0[0], s0[1], s1[0], s1[1]), hard_invalid=True)

    det = []
    n0_ok = 0
    e1_ok = True
    for t in PROJ_TAGS:
        n0 = len(run0.get('per', {}).get(t) or [])
        n1 = len(run1.get('per', {}).get(t) or [])
        det.append('%s %d/%d' % (t, n0, n1))
        if n0 >= MIN_DRAWN_FRAMES:
            n0_ok += 1
        if n1 < MIN_DRAWN_FRAMES:
            e1_ok = False
    # Canh 1 phai co du CA BON the. Canh 0 chi doi >= 3/4: khi loi con day thi co the co mot the
    # gan nhu khong ve duoc gi (luot thu r4/r5: fx-A04 chi 1.933 px) - do LA trieu chung cua loi,
    # khong phai loi cua phep do.
    gate('A5', e1_ok and n0_ok >= C_MIN_TAGS,
         'khung "co ve" (>=%d px) canh0/canh1: %s (canh 0 co %d/4 the, can >= %d)'
         % (MIN_DRAWN_PIXELS, ' '.join(det), n0_ok, C_MIN_TAGS), hard_invalid=True)

    say('')
    say('--- CONG B: muc 2, thu tu setFOVy / setNearClipDistance ---')
    creates = s0[2] + s1[2]
    bad = [c for c in creates if abs(c[0] - c[1]) > 1e-3]
    gate('B1', len(creates) > 0 and not bad,
         '%d dong create; near_frustum == near_elem o %d/%d dong%s'
         % (len(creates), len(creates) - len(bad), len(creates),
            ('; CA KHAC: %s' % bad[:5]) if bad else ' => doi thu tu la KHONG DOI GI hom nay'))

    # MOC lay tu CANH 0 va dung CHUNG cho ca hai canh (phu luc 12:58, truoc khi co so lieu).
    # Neu lay moc rieng theo tung canh thi mot ban va lam XE DICH chinh hieu ung doi chung se
    # keo moc di theo => o D4 khong bao gio bat duoc, va bo do bao "INVALID" thay vi "ban va lam
    # hong thu khac". Selftest ca 11 da bat dung loi nay cua chinh bo do.
    anchor0, at0 = anchor_of(run0)
    anchor1, at1 = anchor_of(run1)
    a0 = a1 = anchor0
    say('')
    say('--- MOC (tam the doi chung o CANH 0, dung chung cho ca hai canh) ---')
    say('    moc = %s (tu %s); moc rieng cua canh 1 = %s (tu %s)' % (anchor0, at0, anchor1, at1))
    if anchor0 and anchor1:
        say('    [thong tin] hai canh cho moc lech %.1f px - neu so nay lon VA D4 truot thi nghi'
            ' CAMERA hai luot khac nhau truoc khi nghi ban va' % dist(anchor0, anchor1))
    if not anchor0:
        gate('ANC', False, 'khong dung duoc moc: thieu the doi chung o canh 0', hard_invalid=True)

    def tag_stats(run, tag):
        rows = run.get('per', {}).get(tag) or []
        if not rows:
            return None
        return {
            'n': len(rows),
            'share': med([r['lc']['share'] for r in rows]),
            'aspect': med([r['lc']['aspect'] for r in rows]),
            'area': med([r['area'] for r in rows]),
            'ncomp': med([r['lc']['ncomp'] for r in rows]),
            'lc_centroid': [med([r['lc']['centroid'][0] for r in rows]),
                            med([r['lc']['centroid'][1] for r in rows])],
            'mask_centroid': [med([r['mask_centroid'][0] for r in rows]),
                              med([r['mask_centroid'][1] for r in rows])],
            'bbox': rows[len(rows) // 2]['lc']['bbox'],
        }

    say('')
    say('--- SO LIEU THO (nhin bang mat truoc khi tin o cham) ---')
    say('%-10s %-5s %7s %7s %8s %5s %9s %8s  %s'
        % ('the', 'canh', 'share', 'aspect', 'area', 'ncum', 'tam cum', 'dx(moc)', 'bbox cum lon nhat'))
    stats = {}
    for tag in PROJ_TAGS + CTRL_TAGS + INFO_TAGS:
        for edge, run in ((0, run0), (1, run1)):
            st = tag_stats(run, tag)
            stats[(tag, edge)] = st
            if st is None:
                say('%-10s %-5d %s' % (tag, edge, '(khong co khung nao co ve)'))
                continue
            dx = (st['lc_centroid'][0] - a0[0]) if a0 else float('nan')
            say('%-10s %-5d %7.3f %7.2f %8.5f %5.0f %4.0f,%4.0f %8.1f  %s'
                % (tag, edge, st['share'], st['aspect'], st['area'], st['ncomp'],
                   st['lc_centroid'][0], st['lc_centroid'][1], dx, st['bbox']))
    say('')
    for tag in PROJ_TAGS + CTRL_TAGS + INFO_TAGS:
        p, q = stats.get((tag, 0)), stats.get((tag, 1))
        if p and q and p['area'] > 0:
            say('    ty so dien tich e1/e0 cho %-7s = %.2f' % (tag, q['area'] / p['area']))

    say('')
    say('--- CONG C: canh doi chung PHAI tai hien duoc loi ---')
    sh0 = [stats[(t, 0)]['share'] for t in PROJ_TAGS if stats.get((t, 0))]
    nc0 = [stats[(t, 0)]['ncomp'] for t in PROJ_TAGS if stats.get((t, 0))]
    gate('C1', len(sh0) >= C_MIN_TAGS and med(sh0) <= C1_SHARE_MAX,
         'trung vi share canh 0 = %s tren %d the (phai <= %.2f: vet bi vo vun)'
         % ('%.3f' % med(sh0) if sh0 else 'n/a', len(sh0), C1_SHARE_MAX))
    gate('C2', len(nc0) >= C_MIN_TAGS and med(nc0) >= C2_NCOMP_MIN,
         'trung vi so cum canh 0 = %s (phai >= %.0f)'
         % ('%.1f' % med(nc0) if nc0 else 'n/a', C2_NCOMP_MIN))

    say('')
    say('--- CONG D: loi khang dinh cua ban va (canh 1) ---')
    for tag in PROJ_TAGS:
        st = stats.get((tag, 1))
        if st is None:
            gate('D1', False, '%s: khong co khung nao co ve o canh 1' % tag)
            continue
        gate('D1', st['share'] >= D1_SHARE_MIN,
             '%s share=%.3f (>= %.2f)' % (tag, st['share'], D1_SHARE_MIN))
        gate('D2', D2_ASPECT_LO <= st['aspect'] <= D2_ASPECT_HI,
             '%s aspect=%.2f (trong [%.2f; %.2f])' % (tag, st['aspect'], D2_ASPECT_LO, D2_ASPECT_HI))
        # Vi tri cua decal lay tu TAM HOP BAO, KHONG tu tam cuong do: hoa van rune la mot VONG
        # thung ruot, trong suot tung cho va QUAY (rotate_anim 0.3 trong all.material), nen tam
        # cuong do lech theo pha quay (fx-A04 o luot thu: tam cuong do x=779 nhung tam hop bao
        # x=725). Tam hop bao cua mot vong tron thi khong phu thuoc pha quay.
        bcx = 0.5 * (st['bbox'][0] + st['bbox'][2])
        dx = abs(bcx - a0[0]) if a0 else float('nan')
        gate('D3b', dx <= D3B_DX_MAX,
             '%s |x(tam hop bao) - x(moc)| = %.1f px (<= %.0f) - can NGANG vao diem gan'
             % (tag, dx, D3B_DX_MAX))
        p = stats.get((tag, 0))
        if p is None:
            say('D5   --      %s: canh 0 khong ve gi => bo qua o ty so dien tich' % tag)
        elif p['area'] > 0:
            r = st['area'] / p['area']
            gate('D5', r >= D5_AREA_RATIO_MIN,
                 '%s dien tich e1/e0 = %.2f (>= %.1f)' % (tag, r, D5_AREA_RATIO_MIN))

    for tag in CTRL_TAGS:
        p, q = stats.get((tag, 0)), stats.get((tag, 1))
        if p is None or q is None:
            gate('D4', False, '%s: thieu du lieu mot canh' % tag)
            continue
        # So TAM cua chinh the do giua HAI CANH (khong so voi moc: fx-Serg02 bam mot diem gan
        # KHAC nen no khong bao gio o gan moc). O nay hoi dung mot cau: "ban va co lam xe dich
        # hieu ung KHONG-PHAI-Projector nao khong?"
        dd = dist(p['mask_centroid'], q['mask_centroid'])
        rel = abs(q['area'] - p['area']) / p['area'] if p['area'] > 0 else 9.0
        gate('D4', dd <= D4_CTRL_OFFSET_MAX and rel <= D4_CTRL_AREA_TOL,
             '%s doi chung: tam dich %.1f px giua hai canh (<= %.0f), lech dien tich %.1f %% (<= %.0f %%)'
             % (tag, dd, D4_CTRL_OFFSET_MAX, rel * 100.0, D4_CTRL_AREA_TOL * 100.0))

    say('')
    if invalid:
        say('KET LUAN: KHONG DUNG DUOC (INVALID) - mot cong A/ANC truot, day khong phai "khong dat"')
    elif ok:
        say('KET LUAN: DAT - moi o da dang ky truoc deu qua')
    else:
        say('KET LUAN: KHONG DAT - BAO SAI, khong noi nguong, KHONG commit')

    text = '\n'.join(L)
    if out:
        with open(out, 'w', encoding='utf-8') as f:
            f.write(text + '\n')
    return (0 if (ok and not invalid) else (2 if invalid else 1)), text


# ---------------------------------------------------------------------------------------------
# SELFTEST - bo do phai biet phan biet DAT / KHONG DAT / INVALID truoc khi dung no.
def _blank():
    return np.zeros((720, 1280), dtype=bool)


def _ellipse(mask, cx, cy, rx, ry):
    yy, xx = np.ogrid[:mask.shape[0], :mask.shape[1]]
    mask |= (((xx - cx) / float(rx)) ** 2 + ((yy - cy) / float(ry)) ** 2) <= 1.0
    return mask


def _streaks(mask, cx, cy, n=6, step=45):
    for i in range(n):
        x0 = int(cx + i * step)
        y0 = int(cy + i * step * 0.4)
        mask[y0:y0 + 10, x0:x0 + 60] = True
    return mask


def selftest():
    checks = []

    # 1. hinh elip day 400x260 -> mot cum, share 1,0, aspect ~1,54 => qua D1/D2
    m = _ellipse(_blank(), 640, 360, 200, 130)
    lc = largest_component(m)
    checks.append(('1 elip day: share ~1 va aspect trong [1.20;1.90]',
                   lc['share'] > 0.99 and D2_ASPECT_LO <= lc['aspect'] <= D2_ASPECT_HI, lc))

    # 2. sau vet keo let roi rac -> share thap => qua C1
    m = _streaks(_blank(), 300, 200)
    lc = largest_component(m)
    checks.append(('2 vet vo vun: share <= %.2f va ncomp >= 5' % C1_SHARE_MAX,
                   lc['share'] <= C1_SHARE_MAX and lc['ncomp'] >= 5, lc))

    # 3. CA AM: elip dep nhung lech 200 px theo truc X khoi moc -> D3b phai truot
    m = _ellipse(_blank(), 840, 360, 200, 130)
    lc = largest_component(m)
    checks.append(('3 CA AM elip lech 200 px theo X: |dx| > %.0f' % D3B_DX_MAX,
                   abs(lc['centroid'][0] - 640.0) > D3B_DX_MAX, lc['centroid']))

    # 4. CA AM: elip qua dai (aspect 2,6) -> D2 phai truot
    m = _ellipse(_blank(), 640, 360, 260, 100)
    lc = largest_component(m)
    checks.append(('4 CA AM elip aspect 2.6: ngoai [%.2f;%.2f]' % (D2_ASPECT_LO, D2_ASPECT_HI),
                   not (D2_ASPECT_LO <= lc['aspect'] <= D2_ASPECT_HI), lc['aspect']))

    # 5. CA AM TU KIEM BO DO: hai cum noi nhau bang mot cau 1 px -> share ~1 (qua D1) nhung
    #    aspect phai bat duoc. Day la ca "luat cum gan neo nhat da HONG" cua projsize doi sang
    #    ngon ngu cua bo do nay.
    m = _blank()
    _ellipse(m, 500, 360, 90, 60)
    _ellipse(m, 900, 360, 90, 60)
    m[359:361, 500:900] = True
    lc = largest_component(m)
    checks.append(('5 CA AM hai cum bi cau noi: share cao nhung aspect bat duoc',
                   lc['share'] > 0.95 and not (D2_ASPECT_LO <= lc['aspect'] <= D2_ASPECT_HI), lc['aspect']))

    # 6. mat na rong -> None, khong duoc ra so rac
    checks.append(('6 mat na rong tra ve None', largest_component(_blank()) is None, None))

    # 7. CA AM: luot chua he chay -> INVALID, khong phai "khong dat"
    rc, txt = score({'exists': False, 'dir': 'x'}, {'exists': False, 'dir': 'y'})
    checks.append(('7 CA AM luot chua chay -> INVALID (rc=2)', rc == 2 and 'INVALID' in txt, rc))

    # 8. CA AM: chay nham canh (log canh 0 lai mang fix=1) -> A4 truot -> INVALID
    r0 = _fake_run(0, fix_in_log=1)
    r1 = _fake_run(1, fix_in_log=1)
    rc, txt = score(r0, r1)
    checks.append(('8 CA AM ca hai luot deu fix=1 -> A4 truot, INVALID', rc == 2 and 'A4' in txt, rc))

    # 9. CA AM: hai canh chay hai binary khac nhau -> A1b truot -> INVALID
    r0 = _fake_run(0)
    r1 = _fake_run(1)
    r1['manifest']['game_sha256'] = 'deadbeef' * 8
    rc, txt = score(r0, r1)
    checks.append(('9 CA AM hai binary khac nhau -> A1b truot, INVALID', rc == 2, rc))

    # 10. Luot "hoan hao" dung theo mo hinh -> DAT. Neu ca nay khong xanh thi bo do khong bao
    #     gio cho DAT duoc, tuc no vo dung.
    r0 = _fake_run(0)
    r1 = _fake_run(1)
    rc, txt = score(r0, r1)
    checks.append(('10 luot mo hinh dung ky vong -> DAT (rc=0)', rc == 0, rc))

    # 11. CA AM: ban va lam xe dich CA hieu ung doi chung -> D4 truot -> KHONG DAT (rc=1)
    r0 = _fake_run(0)
    r1 = _fake_run(1, ctrl_shift=100.0)
    rc, txt = score(r0, r1)
    checks.append(('11 CA AM doi chung bi xe dich 100 px -> D4 truot (rc=1)', rc == 1, rc))

    # 12. CA AM: near_frustum != near_elem -> B1 phai BAO RA chu khong im lang
    r0 = _fake_run(0, near=(100.0, 50.0))
    r1 = _fake_run(1, near=(100.0, 50.0))
    rc, txt = score(r0, r1)
    checks.append(('12 CA AM near khac nhau -> B1 truot va in ra', rc == 1 and 'B1' in txt
                   and 'CA KHAC' in txt, rc))

    # 13. CA AM: decal canh 1 tron dep nhung dien tich KHONG he tang (ban va tro) -> D5 truot.
    r0 = _fake_run(0)
    r1 = _fake_run(1, area_e1=0.0130)
    rc, txt = score(r0, r1)
    checks.append(('13 CA AM dien tich khong tang -> D5 truot', rc == 1 and 'D5' in txt, rc))

    # 14. CA AM TU KIEM BO DO: tam cuong do lech 200 px nhung TAM HOP BAO dung -> D3b van DAT.
    #     Ca nay khoa dung cai vua doi (dung tam hop bao) de nguoi sau khong lang le doi lai.
    r0 = _fake_run(0)
    r1 = _fake_run(1, proj_dx=200.0)
    rc, txt = score(r0, r1)
    checks.append(('14 tam cuong do lech 200 px nhung hop bao dung -> D3b van DAT',
                   'D3b  DAT' in txt, rc))

    npass = sum(1 for c in checks if c[1])
    for name, good, det in checks:
        print('%-4s %s' % ('PASS' if good else 'FAIL', name))
        if not good:
            print('        chi tiet: %r' % (det,))
    print('selftest: %d/%d' % (npass, len(checks)))
    return 0 if npass == len(checks) else 1


class _FakeLog(object):
    """Gia mot WXRender.log de selftest khong can tep that."""

    def __init__(self, fix, near):
        self.fix = fix
        self.near = near


_FAKE_LOGS = {}


def _fake_run(edge, fix_in_log=None, ctrl_shift=0.0, near=(100.0, 100.0), proj_dx=0.0,
              area_e1=0.0980):
    """Dung mot luot tong hop dung theo mo hinh da dang ky, de bo do tu kiem duoc."""
    key = 'FAKE:%d:%s:%s:%s:%s:%s' % (edge, fix_in_log, ctrl_shift, near, proj_dx, area_e1)
    _FAKE_LOGS[key] = _FakeLog(edge if fix_in_log is None else fix_in_log, near)
    anchor = (640.0, 360.0)
    per = {}
    for t in PROJ_TAGS:
        rows = []
        for k in range(5):
            if edge == 0:
                lc = {'share': 0.30, 'aspect': 2.4, 'centroid': [anchor[0] + 195.0, anchor[1] + 45.0],
                      'bbox': [700, 340, 1100, 500], 'pixels': 900, 'total': 3000, 'ncomp': 7}
                mc = [anchor[0] + 198.0, anchor[1] + 46.0]
                area = 0.0120
            else:
                # Mo hinh theo DUNG hinh dang cua luot thu r4/r5: decal nam THAP hon moc ~105 px
                # (moc la dam hat bay len) nhung CAN NGANG vao moc.
                lc = {'share': 0.96, 'aspect': 1.52,
                      'centroid': [anchor[0] + 6.0 + proj_dx, anchor[1] + 105.0],
                      'bbox': [440, 230, 840, 490], 'pixels': 60000, 'total': 62500, 'ncomp': 1}
                mc = [anchor[0] + 5.0 + proj_dx, anchor[1] + 104.0]
                area = area_e1
            rows.append({'offset_ms': 300 + k * 700, 'area': area, 'pixels': lc['total'],
                         'mask_centroid': mc, 'lc': lc})
        per[t] = rows
    for t in CTRL_TAGS:
        rows = []
        for k in range(4):
            mc = [anchor[0] + 2.0 + (ctrl_shift if edge == 1 else 0.0), anchor[1] - 1.0]
            lc = {'share': 0.9, 'aspect': 1.3, 'centroid': mc, 'bbox': [600, 320, 680, 400],
                  'pixels': 5000, 'total': 5500, 'ncomp': 1}
            rows.append({'offset_ms': 300 + k * 700, 'area': 0.0008, 'pixels': 5500,
                         'mask_centroid': mc, 'lc': lc})
        per[t] = rows
    return {
        'dir': 'FAKE-%d' % edge, 'exists': True, 'nshots': 46, 'errors': 0, 'per': per,
        'render_log': key,
        'manifest': {'game_sha256': 'a' * 64, 'render_sha256': 'b' * 64,
                     'env': {'CYS_FXPROJ': str(edge), 'CYS_FXPROJ_LOG': '1'}},
    }


_real_scan = scan_render_log


def _scan_or_fake(path):
    if path in _FAKE_LOGS:
        fl = _FAKE_LOGS[path]
        f0 = 4 if fl.fix == 0 else 0
        f1 = 4 if fl.fix == 1 else 0
        return f0, f1, [fl.near] * 4, True
    return _real_scan(path)


scan_render_log = _scan_or_fake


# ---------------------------------------------------------------------------------------------
def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--batch', default='b09')
    ap.add_argument('--rep0', type=int, help='rep cua canh CYS_FXPROJ=0')
    ap.add_argument('--rep1', type=int, help='rep cua canh CYS_FXPROJ=1')
    ap.add_argument('--game-sha')
    ap.add_argument('--render-sha')
    ap.add_argument('--out')
    ap.add_argument('--selftest', action='store_true')
    a = ap.parse_args()
    if a.selftest:
        return selftest()
    if a.rep0 is None or a.rep1 is None:
        ap.error('can --rep0 va --rep1')
    r0 = measure_run(a.batch, a.rep0)
    r1 = measure_run(a.batch, a.rep1)
    want = (a.game_sha, a.render_sha) if (a.game_sha and a.render_sha) else None
    rc, text = score(r0, r1, want_sha=want, out=a.out)
    print(text)
    return rc


if __name__ == '__main__':
    sys.exit(main())
