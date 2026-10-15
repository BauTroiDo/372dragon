#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""CYS-FXBASE (fx-cy-baseline 19/09): CY 3.71 vs CY-Source, effect by effect, by NUMBERS.

Inputs per batch: the CY run (Build/Logs/2026-09-19-fx-cy-baseline/cy/<batch>-rN: run.log, oracle/oracle.log, PNGs) and
the CY-Source run (ours/<batch>-rN: WXClient.log, cys-replay-*.png). Both sides played the same impact on the same NPC
at the same second; every CY capture gets its REAL offset after the packet (run.log epoch ms - oracle.log epoch ms),
and is paired with the CY-Source capture nearest in time (exact offsets, CYS_SFX_SHOT_MS).

Per frame, against the no-effect baseline of the SAME side (tag base0), inside the analysis region (HUD masked):
  mask   = |luma(frame) - luma(base)| > T  or  max_c |c(frame) - c(base)| > T2   (T from the side's own noise floor)
  area   = mask fraction of the region          energy = mean max(0, luma(frame) - luma(base))
  bright = mean luma inside the mask            sat    = share of mask pixels with a channel >= 250
  hue12  = chroma-weighted 12-bin hue histogram of the mask pixels
  bbox / centroid of the mask (after registering CY-Source onto CY by the baseline shift dx,dy)
Per pair: log2 area ratio, log2 energy ratio, hue L1 (0..1), |sat diff|, centroid distance (px), bbox IoU.
Per effect: peak area per side, median pair divergence D = |log2 area| + |log2 energy| + 2*hueL1 + (1 - IoU),
verdict from thresholds calibrated on the controls (see report).

usage: fxbase_compare.py batch <batch> [--cy-rep 1] [--our-rep 1] [--out compare/<batch>]
       fxbase_compare.py selftest
       fxbase_compare.py report --batches b00-calib,b01,... --out compare/all
"""
import argparse
import glob
import json
import math
import os
import re
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..'))
LOGS = os.path.join(ROOT, 'Build', 'Logs', '2026-09-19-fx-cy-baseline')
FONT = os.path.join(ROOT, 'NotoSansSC-Regular.ttf')
W, H = 1280, 720
# analysis region = frame minus HUD (CY 3.71 and the CY GUI of CY-Source at 1280x720): top bar, bottom bar,
# minimap + right buttons, bottom-left chat. Same rectangles on both sides.
HUD = [(0, 0, W, 110), (0, 620, W, H), (1040, 0, W, 230), (1130, 0, W, 470), (0, 470, 300, H),
       # the player character at the frame centre (CY: head only; CY-Source: full body that changes idle pose between
       # captures, b00b REAL13 +1.5 s) - excluded on BOTH sides; the NPC target stands 3.5 m away, up-left of it
       (600, 280, 685, 445)]
T_LUMA, T_CHAN = 18.0, 26.0
NEAR_MS = 600        # max |dt| when pairing a CY capture with a CY-Source capture (PrintWindow can land ~0.5 s late)


def load(path):
    im = Image.open(path).convert('RGB')
    if im.size != (W, H):
        raise SystemExit('%s is %s, expected %dx%d' % (path, im.size, W, H))
    return np.asarray(im).astype(np.int16)


def luma(a):
    return 0.299 * a[..., 0] + 0.587 * a[..., 1] + 0.114 * a[..., 2]


def region_mask():
    m = np.ones((H, W), bool)
    for x0, y0, x1, y1 in HUD:
        m[y0:y1, x0:x1] = False
    return m


REGION = region_mask()


def shift(a, dx, dy):
    """Shift an image by (dx, dy) pixels (positive = right/down), filling with the edge value."""
    out = np.roll(np.roll(a, dy, axis=0), dx, axis=1)
    if dy > 0:
        out[:dy] = out[dy:dy + 1]
    elif dy < 0:
        out[dy:] = out[dy - 1:dy]
    if dx > 0:
        out[:, :dx] = out[:, dx:dx + 1]
    elif dx < 0:
        out[:, dx:] = out[:, dx - 1:dx]
    return out


def register(base_cy, base_ours, limit=140):
    """(dx, dy) so that shift(ours, dx, dy) lines up with CY: phase correlation of gradient magnitude in the region."""
    def grad(a):
        g = luma(a).astype(np.float64)
        gx = np.abs(np.diff(g, axis=1, prepend=g[:, :1]))
        gy = np.abs(np.diff(g, axis=0, prepend=g[:1]))
        m = (gx + gy) * REGION
        m -= m.mean()
        return m
    a, b = grad(base_cy), grad(base_ours)
    fa, fb = np.fft.fft2(a), np.fft.fft2(b)
    r = fa * np.conj(fb)
    r /= np.abs(r) + 1e-9
    c = np.real(np.fft.ifft2(r))
    # restrict to +-limit
    cand = []
    for dy in range(-limit, limit + 1):
        row = c[dy % H]
        for dx in range(-limit, limit + 1):
            cand.append((row[dx % W], dx, dy))
    peak = max(cand)
    return int(peak[1]), int(peak[2]), float(peak[0])


def dilate(m, r=2):
    out = m.copy()
    for dy in range(-r, r + 1):
        for dx in range(-r, r + 1):
            if dx or dy:
                out |= np.roll(np.roll(m, dy, axis=0), dx, axis=1)
    return out


def unstable_mask(frames, base, t_luma=T_LUMA * 0.5, t_chan=T_CHAN * 0.5):
    """Pixels that move between the no-effect captures of one side (idle animations, shadows, blinking text):
    max deviation from the median baseline above half the effect threshold, dilated by 2 px."""
    u = np.zeros((H, W), bool)
    for f in frames:
        d = f - base
        dl = luma(f) - luma(base)
        u |= (np.abs(dl) > t_luma) | (np.abs(d).max(axis=2) > t_chan)
    return dilate(u) & REGION


def fx_metrics(frame, base, t_luma=T_LUMA, t_chan=T_CHAN, stable=None):
    d = frame - base
    dl = luma(frame) - luma(base)
    mask = ((np.abs(dl) > t_luma) | (np.abs(d).max(axis=2) > t_chan)) & REGION
    if stable is not None:
        mask &= stable
        dl = np.where(stable, dl, 0)
    n = int(mask.sum())
    area = n / float(REGION.sum())
    energy = float(np.maximum(dl, 0)[REGION].mean())
    if n:
        px = frame[mask]
        bright = float(luma(px).mean())
        sat = float((px.max(axis=1) >= 250).mean())
        mx, mn = px.max(axis=1).astype(np.float64), px.min(axis=1).astype(np.float64)
        chroma = mx - mn
        r, g, b = px[:, 0].astype(np.float64), px[:, 1].astype(np.float64), px[:, 2].astype(np.float64)
        hue = np.zeros(n)
        nz = chroma > 0
        rr = (mx == r) & nz
        gg = (mx == g) & nz & ~rr
        bb = nz & ~rr & ~gg
        hue[rr] = ((g[rr] - b[rr]) / chroma[rr]) % 6
        hue[gg] = (b[gg] - r[gg]) / chroma[gg] + 2
        hue[bb] = (r[bb] - g[bb]) / chroma[bb] + 4
        hist, _ = np.histogram(hue, bins=12, range=(0, 6), weights=chroma)
        hs = float(hist.sum())
        hue12 = (hist / hs).tolist() if hs > 0 else [0.0] * 12
        ys, xs = np.nonzero(mask)
        bbox = [int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1]
        centroid = [float(xs.mean()), float(ys.mean())]
        chroma_mean = float(chroma.mean())
    else:
        bright = sat = chroma_mean = 0.0
        hue12 = [0.0] * 12
        bbox = None
        centroid = None
    return {'area': area, 'pixels': n, 'energy': energy, 'bright': bright, 'sat': sat, 'chroma': chroma_mean,
            'hue12': hue12, 'bbox': bbox, 'centroid': centroid}, mask


def iou(a, b):
    if not a or not b:
        return 0.0
    ix0, iy0, ix1, iy1 = max(a[0], b[0]), max(a[1], b[1]), min(a[2], b[2]), min(a[3], b[3])
    inter = max(0, ix1 - ix0) * max(0, iy1 - iy0)
    ua = (a[2] - a[0]) * (a[3] - a[1]) + (b[2] - b[0]) * (b[3] - b[1]) - inter
    return inter / float(ua) if ua > 0 else 0.0


def pair_metrics(mc, mo, eps=2e-4):
    """mo must come from the REGISTERED CY-Source frame."""
    la = math.log2((mo['area'] + eps) / (mc['area'] + eps))
    le = math.log2((mo['energy'] + 0.05) / (mc['energy'] + 0.05))
    hue_l1 = 0.5 * float(np.abs(np.array(mc['hue12']) - np.array(mo['hue12'])).sum()) if (mc['pixels'] and mo['pixels']) else (1.0 if (mc['pixels'] or mo['pixels']) else 0.0)
    cd = math.hypot(mc['centroid'][0] - mo['centroid'][0], mc['centroid'][1] - mo['centroid'][1]) if (mc['centroid'] and mo['centroid']) else None
    io = iou(mc['bbox'], mo['bbox'])
    d = abs(la) + abs(le) + 2.0 * hue_l1 + (1.0 - io)
    # Dpf = D without the position term: what two runs of the SAME engine at different yaws can be compared on
    dpf = abs(la) + abs(le) + 2.0 * hue_l1
    return {'log2_area': la, 'log2_energy': le, 'hue_l1': hue_l1, 'sat_diff': abs(mc['sat'] - mo['sat']),
            'centroid_px': cd, 'iou': io, 'D': d, 'Dpf': dpf}


# ----------------------------------------------------------------------------------------------------- run parsing
def parse_cy_run(d):
    """CY shots with their real offset after the packet; tags; camera."""
    log = open(os.path.join(d, 'run.log'), encoding='utf-8', errors='replace').read().splitlines()
    olog = open(os.path.join(d, 'oracle', 'oracle.log'), encoding='utf-8', errors='replace').read().splitlines()
    t0 = None
    tags = {}
    for line in olog:
        m = re.match(r'\s*(\d+) wallclock t0=([\d.]+)', line)
        if m:
            t0 = float(m.group(2))
        m = re.match(r'\s*(\d+) timeline (\S+): ', line)
        if m and t0 is not None:
            tags[m.group(2)] = t0 * 1000.0 + int(m.group(1))
    if t0 is None:
        raise SystemExit('no wallclock line in %s (oracle without the CYS-FXBASE note?)' % d)
    shots = {}
    for line in log:
        m = re.search(r'shot (\S+) via (\w+) t0=(\d+) dt=(\d+)', line)
        if m:
            name = m.group(1)
            tag = name.rsplit('-', 1)[0]
            shots[name] = {'file': os.path.join(d, name + '.png'), 'method': m.group(2), 'epoch_ms': int(m.group(3)),
                           'capture_ms': int(m.group(4)), 'tag': tag,
                           'offset_ms': (int(m.group(3)) - tags[tag]) if tag in tags else None}
    cam = None
    cf = os.path.join(d, 'cam-c0.json')
    if os.path.exists(cf):
        c = json.load(open(cf, encoding='utf-8')).get('candidates') or []
        cam = c[0] if c else None
    return {'dir': d, 'tags': tags, 'shots': shots, 'camera': cam, 'oracle_t0': t0}


def parse_our_run(d):
    log = open(os.path.join(d, 'WXClient.log'), encoding='utf-8', errors='replace').read().splitlines()
    shots = {}
    offsets = {}
    cams = []
    for line in log:
        m = re.search(r'CYS scenario: shot (\S+) at \+(\d+) ms after tag', line)
        if m:
            offsets[m.group(1)] = int(m.group(2))
        m = re.search(r'capture=(\S+) file=\S*[\\/]([^\\/]+\.png)', line)
        if m and m.group(1) in offsets:
            label = m.group(1)
            path = os.path.join(d, m.group(2))
            if os.path.exists(path):
                shots[label] = {'file': path, 'offset_ms': offsets[label], 'tag': label.rsplit('-', 1)[0]}
        m = re.search(r'CYS camera: (.+?) mode=(\S+) pitch_deg=([\d.\-]+).*dir_deg=([\d.\-]+) dist_m=([\d.]+) zoom=([\d.\-]+).*eye=\(([^)]*)\) look=\(([^)]*)\).*fov=([\d.]+)', line)
        if m:
            cams.append({'label': m.group(1), 'mode': m.group(2), 'pitch': float(m.group(3)), 'dir': float(m.group(4)),
                         'dist_m': float(m.group(5)), 'zoom': float(m.group(6)), 'eye': m.group(7), 'look': m.group(8), 'fov': float(m.group(9))})
    return {'dir': d, 'shots': shots, 'cameras': cams}


def batch_meta(batch):
    return json.load(open(os.path.join(LOGS, 'batches', batch + '.batch.json'), encoding='utf-8'))


# ----------------------------------------------------------------------------------------------------- sheets
def font(size):
    try:
        return ImageFont.truetype(FONT, size)
    except OSError:
        return ImageFont.load_default()


def crop_box(bboxes, pad=40):
    xs0 = [b[0] for b in bboxes if b]
    if not xs0:
        return (300, 110, 1130, 620)
    x0 = max(0, min(b[0] for b in bboxes if b) - pad)
    y0 = max(0, min(b[1] for b in bboxes if b) - pad)
    x1 = min(W, max(b[2] for b in bboxes if b) + pad)
    y1 = min(H, max(b[3] for b in bboxes if b) + pad)
    # keep at least 320x240 around the centre
    cx, cy = (x0 + x1) // 2, (y0 + y1) // 2
    x0, x1 = min(x0, cx - 160), max(x1, cx + 160)
    y0, y1 = min(y0, cy - 120), max(y1, cy + 120)
    return (max(0, x0), max(0, y0), min(W, x1), min(H, y1))


def to_img(a):
    return Image.fromarray(np.clip(a, 0, 255).astype(np.uint8))


def sheet(rows, box, out, title):
    """rows: list of (label, cy_frame, our_frame(registered), cy_mask, our_mask, text)."""
    x0, y0, x1, y1 = box
    cw, ch = x1 - x0, y1 - y0
    scale = min(1.0, 420.0 / max(cw, 1))
    tw, th = int(cw * scale), int(ch * scale)
    cols = 4
    sh = Image.new('RGB', (cols * (tw + 6) + 6, len(rows) * (th + 40) + 40), (18, 18, 18))
    d = ImageDraw.Draw(sh)
    f, fs = font(16), font(13)
    d.text((6, 4), title, fill=(255, 255, 0), font=f)
    for i, (label, cy, ours, mc, mo, text) in enumerate(rows):
        y = 40 + i * (th + 40)
        tiles = [to_img(cy[y0:y1, x0:x1]), to_img(ours[y0:y1, x0:x1]),
                 Image.fromarray((mc[y0:y1, x0:x1] * 255).astype(np.uint8)).convert('RGB'),
                 Image.fromarray((mo[y0:y1, x0:x1] * 255).astype(np.uint8)).convert('RGB')]
        for j, t in enumerate(tiles):
            sh.paste(t.resize((tw, th), Image.BILINEAR), (6 + j * (tw + 6), y + 20))
        d.text((6, y + 2), '%s   CY 3.71 | CY-Source | mask CY | mask CY-Source' % label, fill=(255, 255, 255), font=fs)
        d.text((6, y + th + 22), text, fill=(200, 200, 200), font=fs)
    sh.save(out)


# ----------------------------------------------------------------------------------------------------- batch
def compare_batch(batch, cy_rep, our_rep, out, dxdy=None):
    meta = batch_meta(batch)
    cy_dir = os.path.join(LOGS, 'cy', '%s-r%d' % (batch, cy_rep))
    # the CY run must be healthy (reached the world, no minimised captures, tags matched in time, camera steady): a run
    # that fails fxbase_cyok.py is refused here rather than scored (its later tags show other effects)
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    import fxbase_cyok
    import io
    _buf, _old = io.StringIO(), sys.stdout
    sys.stdout = _buf
    try:
        ok_rc = fxbase_cyok.main_dir(cy_dir)
    finally:
        sys.stdout = _old
    if ok_rc != 0:
        raise SystemExit('CY run %s is not usable: %s' % (cy_dir, _buf.getvalue().strip()))
    cy = parse_cy_run(cy_dir)
    ours = parse_our_run(os.path.join(LOGS, 'ours', '%s-r%d' % (batch, our_rep)))
    os.makedirs(out, exist_ok=True)
    # the two runs must share the camera: CY yaw read from memory (cam-c0.json) vs the yaw the replay applied
    # (WXClient.log "CYS camera: scenario set ... dir_deg="); every CY run drags a different yaw, so a CY run may only be
    # compared with the CY-Source run that was fed ITS camera
    cy_yaw = (cy['camera'] or {}).get('yaw_deg')
    our_yaw = next((c['dir'] for c in ours['cameras'] if c['label'] == 'scenario set'), None)
    if cy_yaw is None or our_yaw is None or abs(float(cy_yaw) - float(our_yaw)) > 0.6:
        raise SystemExit('camera mismatch: CY yaw %s vs CY-Source dir %s (%s vs %s) - not comparable' % (cy_yaw, our_yaw, cy['dir'], ours['dir']))
    # baseline of each side = per-pixel MEDIAN of all its no-effect captures (base0-*, base1-*): a transient that is in
    # a minority of them (CY NPC spawn effect in b00 base0) drops out; noise floor = every base capture vs that median
    cy_bases = sorted([s for s in cy['shots'].values() if s['tag'] in ('base0', 'base1')], key=lambda s: s['file'])
    our_bases = sorted([s for s in ours['shots'].values() if s['tag'] in ('base0', 'base1')], key=lambda s: s['file'])
    if not cy_bases:
        raise SystemExit('CY run has no base captures')
    if not our_bases:
        raise SystemExit('CY-Source run has no base captures')
    base_cy = np.median(np.stack([load(s['file']) for s in cy_bases]), axis=0).astype(np.int16)
    base_ours_raw = np.median(np.stack([load(s['file']) for s in our_bases]), axis=0).astype(np.int16)
    if dxdy is None:
        dx, dy, peak = register(base_cy, base_ours_raw)
    else:
        dx, dy, peak = dxdy[0], dxdy[1], None
    base_ours = shift(base_ours_raw, dx, dy)
    cy_base_frames = [load(s['file']) for s in cy_bases]
    our_base_frames = [shift(load(s['file']), dx, dy) for s in our_bases]
    stable_cy = REGION & ~unstable_mask(cy_base_frames, base_cy)
    stable_ours = REGION & ~unstable_mask(our_base_frames, base_ours)
    unstable_frac = {'cy': 1.0 - stable_cy.sum() / float(REGION.sum()), 'ours': 1.0 - stable_ours.sum() / float(REGION.sum())}
    # noise floor, HELD OUT: the unstable set is learnt from the base0 captures only and the floor is measured on the
    # base1 captures (and vice versa); a floor measured on the frames the mask was learnt from would be 0 by construction
    noise = {'cy': [], 'ours': []}
    for side, bases, frames, base in (('cy', cy_bases, cy_base_frames, base_cy), ('ours', our_bases, our_base_frames, base_ours)):
        for learn_tag, test_tag in (('base0', 'base1'), ('base1', 'base0')):
            learn = [f for s_, f in zip(bases, frames) if s_['tag'] == learn_tag]
            if not learn:
                continue
            st = REGION & ~unstable_mask(learn, base)
            for s_, f in zip(bases, frames):
                if s_['tag'] != test_tag:
                    continue
                m, _ = fx_metrics(f, base, stable=st)
                noise[side].append({'name': os.path.basename(s_['file']), 'learned_from': learn_tag, 'area': m['area'], 'energy': m['energy']})
    floor = {side: (max([n['area'] for n in v]) if v else 0.0) for side, v in noise.items()}
    results = []
    pairs_rows = []
    for item in meta['items']:
        tag = item['tag']
        # a CY capture counts only inside its own window [0, interval): when the runner fell behind the timeline
        # (b00b-calib-r2: a 15 s camera scan during a concurrent build) later captures carry the NEXT effect and are
        # labelled with the old tag; those are reported as stale, never scored
        window_ms = float(meta.get('interval_s', 4.5)) * 1000.0
        all_cy = [s for s in cy['shots'].values() if s['tag'] == tag and s['offset_ms'] is not None]
        stale = [s for s in all_cy if not (0 <= s['offset_ms'] < window_ms)]
        cy_shots = sorted([s for s in all_cy if 0 <= s['offset_ms'] < window_ms], key=lambda s: s['offset_ms'])
        our_shots = sorted([s for s in ours['shots'].values() if s['tag'] == tag], key=lambda s: s['offset_ms'])
        pairs = []
        rows = []
        peak_cy = peak_ours = 0.0
        cy_frames = {}
        for s in our_shots:
            fr = shift(load(s['file']), dx, dy)
            m, _ = fx_metrics(fr, base_ours, stable=stable_ours)
            peak_ours = max(peak_ours, m['area'])
        for s in cy_shots:
            fr = load(s['file'])
            mc, mask_c = fx_metrics(fr, base_cy, stable=stable_cy)
            peak_cy = max(peak_cy, mc['area'])
            if not our_shots:
                continue
            best = min(our_shots, key=lambda o: abs(o['offset_ms'] - s['offset_ms']))
            dt = best['offset_ms'] - s['offset_ms']
            fo = shift(load(best['file']), dx, dy)
            mo, mask_o = fx_metrics(fo, base_ours, stable=stable_ours)
            pm = pair_metrics(mc, mo)
            pm.update({'cy_shot': os.path.basename(s['file']), 'cy_offset_ms': s['offset_ms'], 'our_shot': os.path.basename(best['file']),
                       'our_offset_ms': best['offset_ms'], 'dt_ms': dt, 'cy': mc, 'ours': mo, 'paired': abs(dt) <= NEAR_MS})
            pairs.append(pm)
            rows.append(('%s CY +%d ms / ours +%d ms (dt %+d)' % (tag, s['offset_ms'], best['offset_ms'], dt), fr, fo, mask_c, mask_o,
                         'area CY %.4f ours %.4f | energy %.2f / %.2f | hueL1 %.2f | IoU %.2f | sat %.3f/%.3f | D %.2f' % (
                             mc['area'], mo['area'], mc['energy'], mo['energy'], pm['hue_l1'], pm['iou'], mc['sat'], mo['sat'], pm['D'])))
            pairs_rows.append('\t'.join(str(x) for x in [batch, item['fid'], tag, s['offset_ms'], best['offset_ms'], dt, '%.5f' % mc['area'], '%.5f' % mo['area'],
                                                        '%.3f' % mc['energy'], '%.3f' % mo['energy'], '%.3f' % pm['hue_l1'], '%.3f' % pm['iou'],
                                                        '%.4f' % mc['sat'], '%.4f' % mo['sat'], '%.3f' % pm['D']]))
        ok_pairs = [p for p in pairs if p['paired']]
        # a pair where NEITHER side draws anything (both areas under the drawn floor) carries no information about the
        # effect (both agree on "nothing"): it is not folded into D (b06 Sgs05: two such pairs at 2.2/3.0 s pushed a
        # matching effect to D 2.3). Pairs with exactly one side drawing do count.
        floor_pair = max(3 * floor['cy'], 3 * floor['ours'], 0.0006)
        info = [p for p in ok_pairs if max(p['cy']['area'], p['ours']['area']) > floor_pair]
        steady = [p for p in info if p['cy_offset_ms'] >= 700]   # 0.8 / 1.5 / 3.0 s captures; 0.3 s = onset
        onset = [p for p in info if p['cy_offset_ms'] < 700]
        D_steady = float(np.median([p['D'] for p in (steady if len(steady) >= 2 else (info if info else ok_pairs))])) if ok_pairs else None
        D_onset = float(np.median([p['D'] for p in onset])) if onset else None
        # drawn = peak area above 3x the held-out noise floor of that side and above 0.06 % of the region;
        # TINY = the larger side stays under 0.25 % (a chest flame, a few sparks): one-sided verdicts are weak there
        # one common floor for both sides (the larger of the two held-out floors), otherwise two equal tiny peaks get
        # opposite decisions (b05 Sxy02: 0.0008 vs 0.0009 with floors 0.00005 / 0.00084)
        drawn_floor = max(3 * floor['cy'], 3 * floor['ours'], 0.0006)
        cy_drawn = peak_cy > drawn_floor
        ours_drawn = peak_ours > drawn_floor
        tiny = max(peak_cy, peak_ours) < 0.0025
        if not cy_shots:
            verdict = 'KHONG SO DUOC: CY khong co anh' + (' trong cua so (%d anh tre)' % len(stale) if stale else '')
        elif not our_shots:
            verdict = 'KHONG SO DUOC: CY-Source khong co anh'
        elif not cy_drawn and not ours_drawn:
            verdict = 'CA HAI TRONG'
        elif cy_drawn and not ours_drawn:
            verdict = 'MOT BEN RAT NHO (chi CY)' if tiny else 'CHI CY VE'
        elif ours_drawn and not cy_drawn:
            verdict = 'MOT BEN RAT NHO (chi ta)' if tiny else 'CHI TA VE'
        elif tiny:
            verdict = 'CA HAI RAT NHO'   # both drawn, both under 0.25 % of the region: comparable only weakly
        else:
            D = D_steady if D_steady is not None else float('nan')
            verdict = 'GIONG' if D < 0.9 else ('LECH NHE' if D < 1.6 else 'LECH')
        res = {'fid': item['fid'], 'effect': item['effect'], 'impact': item['impact'], 'bind': item['bind'], 'tag': tag,
               'cy_shots': len(cy_shots), 'cy_shots_stale': len(stale), 'our_shots': len(our_shots), 'pairs': len(ok_pairs),
               'peak_area_cy': peak_cy, 'peak_area_ours': peak_ours, 'cy_drawn': cy_drawn, 'ours_drawn': ours_drawn,
               # D_median = the verdict number: median over the STEADY pairs (CY capture >= 1 s after the packet) when
               # there are at least two, else over all pairs; D_onset = median over the pairs before 1 s (start latency
               # / fade-in differences are reported, not folded into the verdict)
               'D_median': D_steady, 'D_onset': D_onset, 'pairs_steady': len(steady), 'D_all_median': (float(np.median([p['D'] for p in ok_pairs])) if ok_pairs else None),
               'Dpf_median': (float(np.median([p['Dpf'] for p in (steady if len(steady) >= 2 else (info if info else ok_pairs))])) if ok_pairs else None),
               'log2_area_median': (float(np.median([p['log2_area'] for p in ok_pairs])) if ok_pairs else None),
               'log2_energy_median': (float(np.median([p['log2_energy'] for p in ok_pairs])) if ok_pairs else None),
               'hue_l1_median': (float(np.median([p['hue_l1'] for p in ok_pairs])) if ok_pairs else None),
               'iou_median': (float(np.median([p['iou'] for p in ok_pairs])) if ok_pairs else None),
               'sat_cy_max': max([p['cy']['sat'] for p in pairs], default=0.0), 'sat_ours_max': max([p['ours']['sat'] for p in pairs], default=0.0),
               'verdict': verdict, 'pairs_detail': pairs}
        results.append(res)
        if rows:
            box = crop_box([p['cy']['bbox'] for p in pairs] + [p['ours']['bbox'] for p in pairs])
            sheet(rows, box, os.path.join(out, '%s.png' % item['fid']), '%s  %s  (impact %d, bind %s)  %s' % (item['fid'], item['effect'], item['impact'], item['bind'], verdict))
    summary = {'batch': batch, 'cy_run': cy['dir'], 'our_run': ours['dir'], 'register': {'dx': dx, 'dy': dy, 'peak': peak},
               'noise': noise, 'floor_area': floor, 'unstable_fraction': unstable_frac, 'base_frames': {'cy': len(cy_bases), 'ours': len(our_bases)}, 'cy_camera': cy['camera'], 'our_cameras': ours['cameras'][:2],
               'thresholds': {'t_luma': T_LUMA, 't_chan': T_CHAN, 'near_ms': NEAR_MS}, 'results': results}
    with open(os.path.join(out, 'compare.json'), 'w', encoding='utf-8') as f:
        json.dump(summary, f, ensure_ascii=False, indent=1)
    with open(os.path.join(out, 'pairs.tsv'), 'w', encoding='utf-8', newline='\n') as f:
        f.write('batch\tfid\ttag\tcy_offset_ms\tour_offset_ms\tdt_ms\tarea_cy\tarea_ours\tenergy_cy\tenergy_ours\thue_l1\tiou\tsat_cy\tsat_ours\tD\n')
        f.write('\n'.join(pairs_rows) + '\n')
    with open(os.path.join(out, 'effects.tsv'), 'w', encoding='utf-8', newline='\n') as f:
        f.write('fid\teffect\timpact\tbind\tcy_shots\tour_shots\tpairs\tpeak_area_cy\tpeak_area_ours\tlog2_area\tlog2_energy\thue_l1\tiou\tsat_cy\tsat_ours\tD\tverdict\n')
        for r in results:
            f.write('\t'.join(str(x) for x in [r['fid'], r['effect'], r['impact'], r['bind'], r['cy_shots'], r['our_shots'], r['pairs'],
                                               '%.5f' % r['peak_area_cy'], '%.5f' % r['peak_area_ours'],
                                               '' if r['log2_area_median'] is None else '%.2f' % r['log2_area_median'],
                                               '' if r['log2_energy_median'] is None else '%.2f' % r['log2_energy_median'],
                                               '' if r['hue_l1_median'] is None else '%.2f' % r['hue_l1_median'],
                                               '' if r['iou_median'] is None else '%.2f' % r['iou_median'],
                                               '%.4f' % r['sat_cy_max'], '%.4f' % r['sat_ours_max'],
                                               '' if r['D_median'] is None else '%.2f' % r['D_median'], r['verdict']]) + '\n')
    print('%s: register dx=%d dy=%d peak=%s; unstable cy=%.4f ours=%.4f; noise floor area cy=%.5f ours=%.5f' % (batch, dx, dy, peak, unstable_frac['cy'], unstable_frac['ours'], floor['cy'], floor['ours']))
    for r in results:
        print('  %-7s %-40s cy %d/ours %d shots, pairs %d, peak area %.4f/%.4f, D %s -> %s' % (
            r['fid'], r['effect'][:40], r['cy_shots'], r['our_shots'], r['pairs'], r['peak_area_cy'], r['peak_area_ours'],
            '-' if r['D_median'] is None else '%.2f' % r['D_median'], r['verdict']))
    return summary


# ----------------------------------------------------------------------------------------------------- crosscheck
def crosscheck(batch, cy_rep, our_rep, out):
    """Negative control on REAL frames: every CY capture of effect i is scored against the CY-Source capture of the SAME
    offset of every OTHER effect j (wrong pairing). If the metric can tell effects apart, the matched D (i, i) must be
    smaller than the mismatched D (i, j) for almost every drawn effect."""
    meta = batch_meta(batch)
    cy = parse_cy_run(os.path.join(LOGS, 'cy', '%s-r%d' % (batch, cy_rep)))
    ours = parse_our_run(os.path.join(LOGS, 'ours', '%s-r%d' % (batch, our_rep)))
    cy_bases = sorted([s for s in cy['shots'].values() if s['tag'] in ('base0', 'base1')], key=lambda s: s['file'])
    our_bases = sorted([s for s in ours['shots'].values() if s['tag'] in ('base0', 'base1')], key=lambda s: s['file'])
    base_cy = np.median(np.stack([load(s['file']) for s in cy_bases]), axis=0).astype(np.int16)
    base_ours = np.median(np.stack([load(s['file']) for s in our_bases]), axis=0).astype(np.int16)
    st_cy = REGION & ~unstable_mask([load(s['file']) for s in cy_bases], base_cy)
    st_ours = REGION & ~unstable_mask([load(s['file']) for s in our_bases], base_ours)
    # one metric set per effect and side at the 0.8 s and 1.5 s captures
    per = {}
    for item in meta['items']:
        tag = item['tag']
        cs = [s for s in cy['shots'].values() if s['tag'] == tag and s['offset_ms'] is not None and 600 <= s['offset_ms'] <= 2000]
        os_ = [s for s in ours['shots'].values() if s['tag'] == tag and 600 <= s['offset_ms'] <= 2000]
        if not cs or not os_:
            continue
        per[item['fid']] = ([fx_metrics(load(s['file']), base_cy, stable=st_cy)[0] for s in sorted(cs, key=lambda s: s['offset_ms'])],
                            [fx_metrics(load(s['file']), base_ours, stable=st_ours)[0] for s in sorted(os_, key=lambda s: s['offset_ms'])])
    fids = list(per)
    rows, wins, total = [], 0, 0
    for i in fids:
        mc = per[i][0]
        if max(m['area'] for m in mc) < 0.002:
            continue   # CY did not draw this one: no matched signal to protect
        matched = float(np.median([pair_metrics(a, b)['D'] for a, b in zip(mc, per[i][1])]))
        others = []
        for j in fids:
            if j == i or max(m['area'] for m in per[j][1]) < 0.002:
                continue
            others.append((j, float(np.median([pair_metrics(a, b)['D'] for a, b in zip(mc, per[j][1])]))))
        if not others:
            continue
        best_wrong = min(others, key=lambda x: x[1])
        ok = matched < best_wrong[1]
        wins += ok
        total += 1
        rows.append('%s matched D %.2f | closest wrong pairing %s D %.2f | %s' % (i, matched, best_wrong[0], best_wrong[1], 'OK' if ok else 'MISS'))
    os.makedirs(out, exist_ok=True)
    with open(os.path.join(out, 'crosscheck-%s.txt' % batch), 'w', encoding='utf-8') as f:
        f.write(chr(10).join(rows) + chr(10) + 'matched beats every wrong pairing: %d / %d' % (wins, total) + chr(10))
    print(chr(10).join(rows))
    print('%s: matched D < every wrong pairing for %d / %d drawn effects' % (batch, wins, total))
    return wins, total


# ----------------------------------------------------------------------------------------------------- repeat
def side_run(side, batch, rep):
    if side == 'cy':
        r = parse_cy_run(os.path.join(LOGS, 'cy', '%s-r%d' % (batch, rep)))
    else:
        r = parse_our_run(os.path.join(LOGS, 'ours', '%s-r%d' % (batch, rep)))
    bases = sorted([s for s in r['shots'].values() if s['tag'] in ('base0', 'base1')], key=lambda s: s['file'])
    frames = [load(s['file']) for s in bases]
    base = np.median(np.stack(frames), axis=0).astype(np.int16)
    stable = REGION & ~unstable_mask(frames, base)
    return r, base, stable


def compare_repeat(side, batch, rep_a, rep_b, out):
    """Two runs of the SAME side and batch: every capture of run A is paired with the nearest-in-time capture of run B
    of the same tag; D of those pairs = what "identical engine, identical effect" looks like through this metric."""
    meta = batch_meta(batch)
    ra, base_a, st_a = side_run(side, batch, rep_a)
    rb, base_b, st_b = side_run(side, batch, rep_b)
    os.makedirs(out, exist_ok=True)
    rows, per_effect = [], []
    for item in meta['items']:
        tag = item['tag']
        sa = sorted([s for s in ra['shots'].values() if s['tag'] == tag and s.get('offset_ms') is not None], key=lambda s: s['offset_ms'])
        sb = sorted([s for s in rb['shots'].values() if s['tag'] == tag and s.get('offset_ms') is not None], key=lambda s: s['offset_ms'])
        ds, drawn_a, drawn_b = [], 0.0, 0.0
        for s in sa:
            ma, _ = fx_metrics(load(s['file']), base_a, stable=st_a)
            drawn_a = max(drawn_a, ma['area'])
            if not sb:
                continue
            b = min(sb, key=lambda o: abs(o['offset_ms'] - s['offset_ms']))
            mb, _ = fx_metrics(load(b['file']), base_b, stable=st_b)
            drawn_b = max(drawn_b, mb['area'])
            pm = pair_metrics(ma, mb)
            pm.update({'a': os.path.basename(s['file']), 'b': os.path.basename(b['file']), 'dt_ms': b['offset_ms'] - s['offset_ms'], 'area_a': ma['area'], 'area_b': mb['area']})
            ds.append(pm)
            rows.append('	'.join(str(x) for x in [item['fid'], tag, s['offset_ms'], b['offset_ms'], '%.5f' % ma['area'], '%.5f' % mb['area'], '%.3f' % pm['hue_l1'], '%.3f' % pm['iou'], '%.3f' % pm['D']]))
        ds_info = [d for d in ds if max(d['area_a'], d['area_b']) > 0.0006]
        per_effect.append({'fid': item['fid'], 'effect': item['effect'], 'peak_a': drawn_a, 'peak_b': drawn_b,
                           'D_median': float(np.median([d['D'] for d in ds_info])) if ds_info else None,
                           'Dpf_median': float(np.median([d['Dpf'] for d in ds_info])) if ds_info else None, 'pairs': len(ds_info)})
    NL, TAB = chr(10), chr(9)
    with open(os.path.join(out, 'repeat-%s-r%d-r%d.tsv' % (side, rep_a, rep_b)), 'w', encoding='utf-8', newline=NL) as f:
        f.write(TAB.join(['fid', 'tag', 'offset_a', 'offset_b', 'area_a', 'area_b', 'hue_l1', 'iou', 'D']) + NL + NL.join(rows) + NL)
    drawn = [e for e in per_effect if e['D_median'] is not None and max(e['peak_a'], e['peak_b']) > 0.003]
    summary = {'side': side, 'batch': batch, 'reps': [rep_a, rep_b], 'effects': per_effect,
               'D_drawn_median': float(np.median([e['D_median'] for e in drawn])) if drawn else None,
               'D_drawn_max': max([e['D_median'] for e in drawn]) if drawn else None,
               'Dpf_drawn_median': float(np.median([e['Dpf_median'] for e in drawn])) if drawn else None,
               'Dpf_drawn_max': max([e['Dpf_median'] for e in drawn]) if drawn else None, 'drawn_effects': len(drawn)}
    json.dump(summary, open(os.path.join(out, 'repeat-%s-r%d-r%d.json' % (side, rep_a, rep_b)), 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    print('%s %s r%d vs r%d: %d drawn effects, D median %s max %s | Dpf (no position term) median %s max %s' % (side, batch, rep_a, rep_b, len(drawn),
          '-' if summary['D_drawn_median'] is None else '%.2f' % summary['D_drawn_median'], '-' if summary['D_drawn_max'] is None else '%.2f' % summary['D_drawn_max'],
          '-' if summary['Dpf_drawn_median'] is None else '%.2f' % summary['Dpf_drawn_median'], '-' if summary['Dpf_drawn_max'] is None else '%.2f' % summary['Dpf_drawn_max']))
    for e in per_effect:
        print('  %-7s peak %.4f / %.4f  D %s  Dpf %s' % (e['fid'], e['peak_a'], e['peak_b'], '-' if e['D_median'] is None else '%.2f' % e['D_median'], '-' if e['Dpf_median'] is None else '%.2f' % e['Dpf_median']))
    return summary


# ----------------------------------------------------------------------------------------------------- self-test
def selftest():
    """The metric must (1) give 0 on identical frames, (2) grow with a deliberate difference, in the right direction."""
    rng = np.random.default_rng(7)
    base = (rng.integers(40, 120, size=(H, W, 3))).astype(np.int16)
    base = (base + shift(base, 3, 0) + shift(base, 0, 3)) // 3   # some structure for the registration test

    def blob(img, cx, cy, r, colour, gain=1.0):
        out = img.copy()
        yy, xx = np.mgrid[0:H, 0:W]
        w = np.exp(-((xx - cx) ** 2 + (yy - cy) ** 2) / (2.0 * r * r)) * gain
        for c in range(3):
            out[..., c] = np.clip(out[..., c] + (w * colour[c]).astype(np.int16), 0, 255)
        return out

    checks = []
    # blobs sit at (880,380), sigma 40 (mask radius ~80 px): inside the analysis region, clear of the player rectangle
    # 1. identical -> 0
    fa = blob(base, 880, 380, 40, (200, 60, 200))
    ma, _ = fx_metrics(fa, base)
    pm = pair_metrics(ma, ma)
    checks.append(('identical frames -> D 0, IoU 1, hue 0', pm['D'] == 0.0 and pm['iou'] == 1.0 and pm['hue_l1'] == 0.0, pm))
    # 2. no effect vs no effect -> area 0
    m0, _ = fx_metrics(base, base)
    checks.append(('baseline vs itself -> area 0', m0['area'] == 0.0 and m0['pixels'] == 0, m0))
    # 3. same blob, half size -> log2 area ~ -2 (area of a gaussian mask scales with r^2), D large
    fb = blob(base, 880, 380, 20, (200, 60, 200))
    mb, _ = fx_metrics(fb, base)
    pm = pair_metrics(ma, mb)
    checks.append(('half radius -> log2 area about -2 (%.2f), D > 1' % pm['log2_area'], -2.6 < pm['log2_area'] < -1.4 and pm['D'] > 1.0, pm))
    # 4. same blob, other colour (green instead of purple) -> hue L1 large, area/energy ~ same
    fc = blob(base, 880, 380, 40, (60, 200, 60))
    mc_, _ = fx_metrics(fc, base)
    pm = pair_metrics(ma, mc_)
    checks.append(('other hue -> hue_l1 > 0.8 (%.2f), |log2 area| < 0.3 (%.2f)' % (pm['hue_l1'], pm['log2_area']), pm['hue_l1'] > 0.8 and abs(pm['log2_area']) < 0.3, pm))
    # 5. same blob moved 400 px (the gaussian mask of sigma 60 reaches ~150 px, so a 120 px move still overlaps: that
    #    was a wrong expectation of the first self-test, not a metric fault) -> IoU 0, centroid ~400
    #    (the blob must stay inside the analysis region x 300..1130: sigma 60 -> mask radius ~121 px, so 700 -> 1000)
    fd = blob(base, 480, 380, 40, (200, 60, 200))   # 400 px to the left, still inside the region
    md, _ = fx_metrics(fd, base)
    pm = pair_metrics(ma, md)
    checks.append(('moved 400 px -> IoU < 0.05 (%.2f), centroid 385..415 (%.1f)' % (pm['iou'], pm['centroid_px']), pm['iou'] < 0.05 and 385 < pm['centroid_px'] < 415, pm))
    # 5b. moved 40 px -> IoU still high (> 0.5) but centroid ~40: the two numbers answer different questions
    fd2 = blob(base, 920, 380, 40, (200, 60, 200))
    md2, _ = fx_metrics(fd2, base)
    pm = pair_metrics(ma, md2)
    checks.append(('moved 40 px -> IoU > 0.5 (%.2f), centroid 35..45 (%.1f)' % (pm['iou'], pm['centroid_px']), pm['iou'] > 0.5 and 35 < pm['centroid_px'] < 45, pm))
    # 6. dimmer (gain 0.4) -> log2 energy negative, area smaller
    fe = blob(base, 880, 380, 40, (200, 60, 200), gain=0.4)
    me, _ = fx_metrics(fe, base)
    pm = pair_metrics(ma, me)
    checks.append(('40%% brightness -> log2 energy < -0.8 (%.2f)' % pm['log2_energy'], pm['log2_energy'] < -0.8, pm))
    # 7. one side empty -> hue_l1 1, area ratio very negative
    pm = pair_metrics(ma, m0)
    checks.append(('one side empty -> log2 area < -5 (%.2f)' % pm['log2_area'], pm['log2_area'] < -5 and pm['iou'] == 0.0, pm))
    # 8. registration recovers a known shift of the other side (dx 12, dy -40)
    other = shift(base, -12, 40)   # "ours" is the same scene displaced; register must return (12, -40)
    dx, dy, pk = register(base, other)
    checks.append(('registration recovers (12,-40): got (%d,%d)' % (dx, dy), (dx, dy) == (12, -40), {'peak': pk}))
    # 9. HUD region excluded: a blob entirely inside the top bar counts 0
    ff = blob(base, 640, 40, 20, (255, 255, 255))
    mf, _ = fx_metrics(ff, base)
    checks.append(('blob inside the HUD mask -> area 0', mf['area'] == 0.0, mf))
    ok = all(c[1] for c in checks)
    for name, passed, m in checks:
        print('%s  %s' % ('PASS' if passed else 'FAIL', name))
    print('selftest %s (%d/%d)' % ('PASS' if ok else 'FAIL', sum(1 for c in checks if c[1]), len(checks)))
    return 0 if ok else 1


# ----------------------------------------------------------------------------------------------------- report
def report(batches, out):
    os.makedirs(out, exist_ok=True)
    rows = []
    for b in batches:
        p = os.path.join(LOGS, 'compare', b, 'compare.json')
        if not os.path.exists(p):
            print('missing', p)
            continue
        s = json.load(open(p, encoding='utf-8'))
        for r in s['results']:
            r = dict(r)
            r['batch'] = b
            r['register'] = s['register']
            r['floor'] = s['floor_area']
            rows.append(r)
    with open(os.path.join(out, 'table.tsv'), 'w', encoding='utf-8', newline='\n') as f:
        f.write('fid\teffect\tbatch\tverdict\tD\tlog2_area\tlog2_energy\thue_l1\tiou\tpeak_area_cy\tpeak_area_ours\tsat_cy\tsat_ours\tpairs\n')
        for r in sorted(rows, key=lambda r: (r['D_median'] is None, -(r['D_median'] or 0))):
            f.write('\t'.join(str(x) for x in [r['fid'], r['effect'], r['batch'], r['verdict'],
                                               '' if r['D_median'] is None else '%.2f' % r['D_median'],
                                               '' if r['log2_area_median'] is None else '%.2f' % r['log2_area_median'],
                                               '' if r['log2_energy_median'] is None else '%.2f' % r['log2_energy_median'],
                                               '' if r['hue_l1_median'] is None else '%.2f' % r['hue_l1_median'],
                                               '' if r['iou_median'] is None else '%.2f' % r['iou_median'],
                                               '%.5f' % r['peak_area_cy'], '%.5f' % r['peak_area_ours'], '%.4f' % r['sat_cy_max'], '%.4f' % r['sat_ours_max'], r['pairs']]) + '\n')
    counts = {}
    for r in rows:
        counts[r['verdict']] = counts.get(r['verdict'], 0) + 1
    json.dump({'rows': len(rows), 'verdicts': counts}, open(os.path.join(out, 'summary.json'), 'w', encoding='utf-8'), indent=1)
    print('rows', len(rows), counts)


def main():
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest='cmd')
    b = sub.add_parser('batch')
    b.add_argument('batch')
    b.add_argument('--cy-rep', type=int, default=1)
    b.add_argument('--our-rep', type=int, default=1)
    b.add_argument('--out')
    b.add_argument('--dxdy', help='dx,dy override for the registration')
    sub.add_parser('selftest')
    cc = sub.add_parser('crosscheck')
    cc.add_argument('batch')
    cc.add_argument('--cy-rep', type=int, default=1)
    cc.add_argument('--our-rep', type=int, default=1)
    cc.add_argument('--out', default=os.path.join(LOGS, 'compare', 'crosscheck'))
    rp = sub.add_parser('repeat')
    rp.add_argument('side', choices=('cy', 'ours'))
    rp.add_argument('batch')
    rp.add_argument('--reps', default='1,2')
    rp.add_argument('--out')
    r = sub.add_parser('report')
    r.add_argument('--batches', required=True)
    r.add_argument('--out', default=os.path.join(LOGS, 'compare', 'all'))
    a = ap.parse_args()
    if a.cmd == 'selftest':
        return selftest()
    if a.cmd == 'batch':
        out = a.out or os.path.join(LOGS, 'compare', a.batch)
        dxdy = tuple(int(v) for v in a.dxdy.split(',')) if a.dxdy else None
        compare_batch(a.batch, a.cy_rep, a.our_rep, out, dxdy)
        return 0
    if a.cmd == 'crosscheck':
        crosscheck(a.batch, a.cy_rep, a.our_rep, a.out)
        return 0
    if a.cmd == 'repeat':
        ra, rb = [int(v) for v in a.reps.split(',')]
        compare_repeat(a.side, a.batch, ra, rb, a.out or os.path.join(LOGS, 'compare', a.batch))
        return 0
    if a.cmd == 'report':
        report([x.strip() for x in a.batches.split(',') if x.strip()], a.out)
        return 0
    ap.print_help()
    return 2


if __name__ == '__main__':
    sys.exit(main())
