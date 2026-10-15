"""Read-only evidence for the proposed Vo hon / Chien hon redesign.

Reads the published CY tables and private server source, never player records.
Writes only the requested JSON report. No gameplay or schema mutation.
"""
from pathlib import Path
import argparse, collections, hashlib, json, re, sys

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'Tools/game'))
from dbc_inventory import Table

SERVER = Path('//wsl.localhost/TLBB/home/ubuntu/cys-test-20260913')
PLAY = ROOT / 'Build/world-gui/stage-play-21'

def sha(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()

def client_table(name):
    candidates = [PLAY / ('Overlay/'+side+'/ConfigFolder') / (name+'.txt') for side in ('Post','Pre')]
    candidates.append(ROOT/'Assets/CanonicalCY/Data/ConfigFolder'/(name+'.txt'))
    return Table(next(p for p in candidates if p.is_file()))

def main(out):
    kfs = client_table('KFSSkillLevelup')
    client = client_table('SkillTemplate_V1')
    server = Table(SERVER/'configs/SkillTemplate_V1.txt')
    details = Table(SERVER/'configs/SkillData_V1.txt')
    assert server.names and details.names
    column = lambda table, name: table.names.index(name)
    passive = column(server, '主动技能还是被动技能')
    learned = column(server, '使用前是否需要学会')
    first = column(server, '心法1级对应的实际技能ID')
    logic = column(details, '技能逻辑ID')
    by_client = {r[0]: r for r in client.rows}
    by_server = {r[0]: r for r in server.rows}
    by_detail = {r[0]: r for r in details.rows}
    by_kfs = {r[0]: r for r in kfs.rows}
    roots = []; coverage = set()
    for row in kfs.rows:
        if row[4] != 1: continue
        sid = row[0]; chain = []; current = sid
        while current != -1:
            assert current not in chain
            chain.append(current); coverage.add(current)
            assert current in by_server and current in by_client
            assert by_server[current][passive] == by_client[current][21]
            current = by_kfs[current][1]
        s = by_server[sid]
        slot = 2 if 1385 <= sid <= 1535 else 3 if 1541 <= sid <= 1619 else 1
        roots.append({'template_id': sid, 'name': by_client[sid][2], 'existing_slot': slot,
                      'passive': s[passive] == 1, 'requires_learned': s[learned] == 1,
                      'rank_ids': chain, 'rank1_skill_data_id': s[first],
                      'rank1_logic': by_detail[s[first]][logic]})
    assert coverage == set(by_kfs)
    files = [ROOT/'Src/Client/WXClient/Object/Character/Obj_PlayerOther.cpp',
             ROOT/'Src/Client/WXClient/Network/CysWuhunNet.cpp',
             ROOT/'Tools/server/cys_wuhun_appearance.lua',
             SERVER/'GameServer/services/scene/obj/human.lua',
             SERVER/'GameServer/services/scene/human.lua',
             SERVER/'GameServer/services/scene/scenecore.lua',
             SERVER/'GameServer/lualib/db/human_attrib.lua',
             SERVER/'GameServer/lualib/cy_equipment_skills.lua',
             SERVER/'GameServer/lualib/skillenginer.lua',
             SERVER/'GameServer/lualib/define.lua']
    result = {'scope': 'static audit; no live combat test; no player data read or changed',
              'game_sha256': sha(PLAY/'Bin64/Game.exe'),
              'stage_manifest_sha256': sha(PLAY/'Bin64/game_data_stage.json'),
              'source_hashes': {str(p): sha(p) for p in files},
              'tables': {str(t.path): t.sha256 for t in (kfs, client, server, details)},
              'skill_root_count': len(roots), 'skill_rank_count': len(coverage),
              'root_counts_by_slot': dict(collections.Counter(r['existing_slot'] for r in roots)),
              'passive_roots': sum(r['passive'] for r in roots),
              'active_roots': sum(not r['passive'] for r in roots),
              'roots': roots}
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(result, ensure_ascii=False, indent=2)+'\n', encoding='utf8')
    print(json.dumps({k: v for k, v in result.items() if k.endswith('count') or k.endswith('roots') and k != 'roots'}, ensure_ascii=False))
    for r in roots:
        print(r['existing_slot'], r['template_id'], r['name'], 'passive' if r['passive'] else 'active', 'logic='+str(r['rank1_logic']))

if __name__ == '__main__':
    sys.stdout.reconfigure(encoding='utf8')
    parser = argparse.ArgumentParser()
    parser.add_argument('--out', type=Path, default=ROOT/'Docs/evidence/dual-souls-audit-20260925.json')
    main(parser.parse_args().out)
