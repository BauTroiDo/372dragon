#!/usr/bin/env python3
"""Convert a scene JSON or scenario log to CYS_WORLD_SCENARIO for offline replay.

Usage: cy_scenario_replay.py <scenario.json | scenario.log> <out.txt>
The input describes scene coordinates, character, NPCs, impacts and a timed action list.
"""
import json
import sys
from pathlib import Path


def load(path):
    text = Path(path).read_text(encoding='utf-8', errors='replace')
    if path.lower().endswith('.json'):
        return json.loads(text)
    for line in text.splitlines():
        head, sep, body = line.partition(': {')
        if sep and ' scenario ' in head:
            return json.loads('{' + body)
    raise SystemExit('no scenario line in ' + path)


def convert(sc):
    me = int(sc.get('my_obj_id', 1001))
    scene = sc['scene']
    x, z = float(scene['x']), float(scene['z'])
    for step in sc.get('timeline', []):
        if 'teleport' in step:
            x, z = float(step['teleport'][0]), float(step['teleport'][1])
            break
    out = ['# CYS_WORLD_SCENARIO from scene scenario "%s" (Tools/game/cy_scenario_replay.py)' % sc.get('name', '?'),
           'scene id=%d x=%g z=%g obj=%d name=%s' % (int(scene['id']), x, z, me, sc.get('character', {}).get('name', ''))]
    for npc in sc.get('npcs', []):
        out.append('at=0 npc obj=%d race=%d x=%g z=%g dir=%g level=%d name=%s' % (
            npc['obj'], npc['id'], npc['x'], npc['z'], npc.get('dir', 0.0), npc.get('level', 1), npc.get('name', '')))
    for obj, ids in sorted(sc.get('impacts', {}).items()):
        out.append('at=0 impactlist obj=%d ids=%s' % (int(obj), ','.join(str(i) for i in ids)))
    logic = 100
    for step in sc.get('timeline', []):
        t = int(round(float(step['t']) * 1000))
        tag = step.get('tag')
        acts = []
        if 'skill' in step:
            logic += 1
            caster = int(step.get('caster', me))
            target = int(step.get('target', -1))
            acts.append((t, 'skill caster=%d target=%d skill=%d logic=%d' % (caster, target, step['skill'], logic)))
            if step.get('impact'):
                acts.append((t + 600, 'impact target=%d sender=%d id=%d logic=%d' % (target, caster, step['impact'], logic)))
            if step.get('damage'):
                acts.append((t + 600, 'damage target=%d sender=%d hp=%d logic=%d' % (target, me, -int(step['damage']), logic)))
        if 'impact_list' in step:
            obj = int(step['impact_list'])
            ids = sc.get('impacts', {}).get(str(obj), [])
            acts.append((t, 'impactlist obj=%d ids=%s' % (obj, ','.join(str(i) for i in ids))))
        if 'direct_impact' in step:
            acts.append((t, 'impact target=%d sender=%d id=%d logic=0' % (
                int(step.get('target', -1)), int(step.get('caster', me)), step['direct_impact'])))
        if not acts and 'teleport' not in step:
            continue
        # Emit the tag before the actions in the same replay frame.
        if tag and (acts or 'teleport' in step):
            out.append('at=%d tag %s' % (t, tag))
        for at, text in acts:
            out.append('at=%d %s' % (at, text))
    return out


def main():
    if len(sys.argv) != 3:
        raise SystemExit(__doc__)
    lines = convert(load(sys.argv[1]))
    Path(sys.argv[2]).write_bytes(('\n'.join(lines) + '\n').encode('utf-8'))
    print('%s: %d lines' % (sys.argv[2], len(lines)))


if __name__ == '__main__':
    main()
