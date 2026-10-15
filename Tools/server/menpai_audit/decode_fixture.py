#!/usr/bin/env python3
"""menpai-audit: tóm tắt chiến đấu từ fixture PGWORLD1 của CysNetBot --record 1 (chỉ gói S->C, không in body thô).

Bản ghi: u8 c2s, u16 id, u16 idx, u32 size, body (Tests/net/make_world_fixture.py). Bố cục gói: Registry/protocol/packets.yaml.
  decode_fixture.py <fixture> <my_obj_id> [--json]
"""
import json, struct, sys, collections


def records(path):
    with open(path, 'rb') as f:
        data = f.read()
    off = 0
    if data[:8].startswith(b'PGWORLD'):
        off = 8
    while off + 9 <= len(data):
        c2s, xid, idx, size = struct.unpack_from('<BHHI', data, off)
        off += 9
        body = data[off:off + size]
        off += size
        if len(body) != size:
            break
        yield bool(c2s), xid, body


def main():
    path, me = sys.argv[1], int(sys.argv[2])
    cast = int(sys.argv[3]) if len(sys.argv) > 3 else None
    out = {'my_obj': me, 'skill_sends': [], 'dmg_by_me': [], 'heal_by_me': [], 'dmg_to_me': [], 'mp_by_me': [], 'crit': 0,
           'direct_impacts': [], 'buffs_on_self': collections.Counter(), 'buffs_on_other': collections.Counter(), 'operate_results': collections.Counter(),
           'study': [], 'frames': 0}
    for c2s, xid, b in records(path):
        if c2s:
            continue
        out['frames'] += 1
        try:
            if xid == 1692:
                dirty, rec, snd, logic = struct.unpack_from('<BIiI', b, 0)
                o = 13
                hp = mp = None
                if dirty & 1:
                    hp, = struct.unpack_from('<i', b, o); o += 4
                if dirty & 2:
                    mp, = struct.unpack_from('<i', b, o); o += 4
                if dirty & 4:
                    o += 4
                if dirty & 8:
                    o += 4
                crit = b[o] if o < len(b) else 0
                if hp is not None:
                    if snd == me and rec != me and hp < 0:
                        out['dmg_by_me'].append(-hp); out['crit'] += 1 if crit else 0
                    elif snd == me and hp > 0:
                        out['heal_by_me'].append(hp)
                    elif rec == me and hp < 0:
                        out['dmg_to_me'].append(-hp)
                if mp is not None and snd == me and rec != me:
                    out['mp_by_me'].append(mp)
            elif xid == 676:
                rec, snd, logic, imp, skill = struct.unpack_from('<IiiHi', b, 0)
                if snd == me or rec == me:
                    out['direct_impacts'].append({'to_self': rec == me, 'impact': imp, 'skill': skill})
            elif xid == 153:
                rec, flag, buf, enable, snd = struct.unpack_from('<IihIi', b, 0)
                if enable and (snd == me or rec == me):
                    (out['buffs_on_self'] if rec == me else out['buffs_on_other'])[buf] += 1
            elif xid == 331:
                obj, logic, skill, tgt = struct.unpack_from('<IIIi', b, 0)
                if obj == me:
                    out['skill_sends'].append({'skill': skill, 'target': tgt})
            elif xid == 7:
                r, = struct.unpack_from('<i', b, 0)
                out['operate_results'][r] += 1
            elif xid == 137:
                money, exp, xf, lv = struct.unpack_from('<IIHH', b, 0)
                out['study'].append({'spare_money': money, 'spare_exp': exp, 'xinfa': xf, 'now_level': lv})
        except struct.error:
            pass
    s = {'frames': out['frames'], 'skill_sends': len(out['skill_sends']), 'dmg_hits': len(out['dmg_by_me']), 'dmg_sum': sum(out['dmg_by_me']),
         'dmg_max': max(out['dmg_by_me']) if out['dmg_by_me'] else 0, 'dmg_list': out['dmg_by_me'][:12], 'crit': out['crit'],
         'heal_sum': sum(out['heal_by_me']), 'dmg_taken': sum(out['dmg_to_me']),
         'direct_impacts': sorted({(d['impact'], d['to_self']) for d in out['direct_impacts']}),
         'direct_impacts_of_skill': sorted({(d['impact'], d['to_self']) for d in out['direct_impacts'] if cast is not None and d['skill'] == cast}),
         'my_skill_sends_of_skill': sum(1 for s in out['skill_sends'] if cast is not None and s['skill'] == cast),
         'buffs_self': dict(out['buffs_on_self']), 'buffs_other': dict(out['buffs_on_other']),
         'operate_results': dict(out['operate_results']), 'study': out['study']}
    print(json.dumps(s, ensure_ascii=False, default=str))


if __name__ == '__main__':
    main()

