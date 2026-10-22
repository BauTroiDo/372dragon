#!/usr/bin/env python3
# -*- coding: utf-8 -*-
'Both sides get byte-identical packet content (GCCharImpactListUpdate obj=2002 ids=[impact]) at the same second;\ncapture offsets: CY = plan tail (real time is measured afterwards), CY-Source = CYS_SFX_SHOT_MS (exact).\n\nusage: fxbase_scenario.py --plan <tables/plan.json> --batch <name> --fids B10,T01,... [--interval 4.5] [--late]\n                          --out <dir>\nwrites <out>/<batch>.cy.json, <out>/<batch>.replay.txt, <out>/<batch>.batch.json, <out>/<batch>.tail.txt\n'
import argparse
import json
import os
import sys

NPCS = {'muren': {'obj': 2002, 'id': 346, 'name': '木人', 'level': 30, 'x': 158.0, 'z': 155.0, 'dir': 0.0},
        'daocaoren': {'obj': 2003, 'id': 305, 'name': '稻草人', 'level': 1, 'x': 158.0, 'z': 155.0, 'dir': 0.0}}
NPC = NPCS['muren']
ME = 1001
NEAR = (160.5, 152.5)
# base0 at 14 s, first effect at 18 s: the CY camera read-back (camread c0, a 1.8 GB memory scan) runs right after the
# camera set-up (+8 s after IN WORLD) and blocks the runner loop for ~4 s (b00-calib-r2: it delayed base0 past the first
# impact, whose enable effect then leaked into the base frames), so both must sit after it
T_NEAR, T_BASE0, T_FIRST = 3, 14, 18
BASE_SHOTS = [0.5, 1.0, 1.5, 2.0]
# CY shots after every tag (seconds); CY-Source shots (ms) dense enough to pick the nearest frame to each CY capture
# FOUR captures per effect on BOTH sides (fx-perf 19/09: every CY-Source capture freezes the main thread 196 ms at 1280x720,
# so 8-9 captures cost 1.6-1.8 s of every 4.5 s window and dropped the fps the user saw; CY's PrintWindow is external).
# 0.3 = onset (reported apart, D_onset), 0.8 = peak, 1.5 = steady, 3.0 = tail: the verdict takes the pairs >= 0.8 s.
CY_SHOTS = [0.3, 0.8, 1.5, 3.0]
CY_SHOTS_LATE = [0.3, 3.5, 4.5, 6.5, 8.0]   # T01 starts at 3.15 s, B10 at 6.1 s: sparser, same length
# CY captures land at +0.31..0.33 / +0.83 / +1.53 / +3.03 s (fast runner, b00-calib-r2), so CY-Source captures at the
# nominal offsets plus a few in between are enough for the nearest-in-time pairing (|dt| <= 450 ms)
# same four offsets as CY (at most 8 per tag: CysWorldReplay.cpp labels them "abcdefgh"[min(i, 7)])
OUR_SHOTS = [300, 800, 1500, 3000]
OUR_SHOTS_LATE = [300, 3500, 4500, 6500, 8000]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--plan', required=True)
    ap.add_argument('--batch', required=True)
    ap.add_argument('--fids', required=True, help='comma list of plan fids; "13" = the real row 13 (positive control)')
    ap.add_argument('--interval', type=float, default=4.5)
    ap.add_argument('--late', action='store_true', help='late-start effects: 9 s per effect, shots up to 8 s')
    ap.add_argument('--out', required=True)
    ap.add_argument('--npc', choices=sorted(NPCS), default='muren')
    ap.add_argument('--cy-shots', default='', help='override the CY capture offsets (s), e.g. 0.12,0.2,0.3,0.45,0.6,0.8,1.2,2.0')
    ap.add_argument('--our-shots', default='', help='override the CY-Source capture offsets (ms, at most 8)')
    a = ap.parse_args()
    global NPC
    NPC = NPCS[a.npc]
    plan = {p['fid']: p for p in json.load(open(a.plan, encoding='utf-8'))}
    interval = 9.0 if a.late else a.interval
    cy_shots = CY_SHOTS_LATE if a.late else CY_SHOTS
    our_shots = OUR_SHOTS_LATE if a.late else OUR_SHOTS
    if a.cy_shots:
        cy_shots = [float(v) for v in a.cy_shots.split(',')]
    if a.our_shots:
        our_shots = [int(v) for v in a.our_shots.split(',')][:8]
    items = []
    for fid in [f.strip() for f in a.fids.split(',') if f.strip()]:
        if fid == '13':
            items.append({'fid': 'REAL13', 'impact': 13, 'effect': 'buff_fengxue_01', 'bind': '脚下光圈点'})
        elif fid in plan:
            items.append(dict(plan[fid]))
        else:
            sys.exit('unknown fid ' + fid)
    timeline = [{'t': T_NEAR, 'teleport': list(NEAR), 'tag': 'near'},
                {'t': T_BASE0, 'impact_list': NPC['obj'], 'ids': [], 'tag': 'base0'}]
    t = T_FIRST
    tags = []
    for it in items:
        tag = 'fx-' + it['fid']
        timeline.append({'t': t, 'impact_list': NPC['obj'], 'ids': [it['impact']], 'tag': tag})
        tags.append({'tag': tag, 't': t, 'fid': it['fid'], 'impact': it['impact'], 'effect': it['effect'], 'bind': it['bind']})
        t += interval
    timeline.append({'t': t, 'impact_list': NPC['obj'], 'ids': [], 'tag': 'base1'})
    t_end = t
    sc = {'name': 'fxbase-' + a.batch, 'account': 'oracle', 'my_obj_id': ME,
          'scene': {'id': 2, 'res': 2, 'x': 160.0, 'z': 150.0, 'server_time': 0},
          'character': {'guid': 200001, 'sex': 0, 'name': 'CYOracle', 'level': 90, 'menpai': 9, 'hair_color': 0,
                        'hair': 0, 'face': 0, 'equips': [], 'visuals': [], 'model_id': -1},
          'echo_move': True, 'npcs': [dict(NPC)],
          'world_time': {'time': 0, 'counter': 43200000, 'interval': 0, 'note': '12:00 frozen'},
          'impacts': {str(NPC['obj']): []},
          'timeline': timeline,
          'cys_fxbase': {'batch': a.batch, 'interval_s': interval, 'late': a.late, 'npc': a.npc, 'items': tags}}
    os.makedirs(a.out, exist_ok=True)
    base = os.path.join(a.out, a.batch)
    with open(base + '.cy.json', 'w', encoding='utf-8') as f:
        json.dump(sc, f, ensure_ascii=False, indent=1)
    # replay text (Tools/game/cy_scenario_replay.py conventions; position = first teleport)
    lines = ['# CYS_WORLD_SCENARIO fxbase batch %s (Tools/fx/baseline/fxbase_scenario.py)' % a.batch,
             'scene id=2 x=%g z=%g obj=%d name=CYOracle' % (NEAR[0], NEAR[1], ME),
             'at=0 npc obj=%d race=%d x=%g z=%g dir=%g level=%d name=%s' % (NPC['obj'], NPC['id'], NPC['x'], NPC['z'], NPC['dir'], NPC['level'], NPC['name']),
             'at=0 impactlist obj=%d ids=' % NPC['obj']]
    for step in timeline:
        if 'teleport' in step:
            continue
        ms = int(round(step['t'] * 1000))
        lines.append('at=%d tag %s' % (ms, step['tag']))
        lines.append('at=%d impactlist obj=%d ids=%s' % (ms, step['impact_list'], ','.join(str(i) for i in step['ids'])))
    with open(base + '.replay.txt', 'w', encoding='utf-8', newline='\n') as f:
        f.write('\n'.join(lines) + '\n')
    # CY plan tail: wait for every tag in oracle.log, then shots at fixed offsets
    tail = ['+8:camread:c0,%g,%g' % NEAR]   # blocks ~4 s; base0 (t=14) waits behind it
    for step in timeline:
        if 'teleport' in step:
            continue
        tag = step['tag']
        shots = BASE_SHOTS if tag.startswith('base') else cy_shots

        tail.append('+0:wait:timeline %s:' % tag)
        for k, s in enumerate(shots):
            tail.append('+%g:shot:%s-%s' % (s, tag, 'abcdefgh'[k]))
    tail.append('+2.5:camread:c1,%g,%g' % NEAR)
    with open(base + '.tail.txt', 'w', encoding='ascii', newline='\n') as f:
        f.write(';'.join(tail) + '\n')
    meta = {'batch': a.batch, 'interval_s': interval, 'late': a.late, 'npc': a.npc, 'npc_obj': NPC['obj'], 'items': tags, 't_end_s': t_end,
            'cy_shots_s': cy_shots, 'our_shots_ms': our_shots, 'our_shot_env': ','.join(str(m) for m in our_shots),
            'cy_json': base + '.cy.json', 'replay_txt': base + '.replay.txt', 'tail': base + '.tail.txt'}
    with open(base + '.batch.json', 'w', encoding='utf-8') as f:
        json.dump(meta, f, ensure_ascii=False, indent=1)
    print('%s: %d effects, last tag at t=%g s (world +%g s), files %s.*' % (a.batch, len(items), t_end, t_end + 2, base))


if __name__ == '__main__':
    main()
