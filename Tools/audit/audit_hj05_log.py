"""Read-only evidence for the user-supplied HJ 0.5 fix log. Never deploys or touches DB."""
from pathlib import Path
import collections, datetime, hashlib, json, re, subprocess

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'Build/Logs/2026-09-28-hj05-audit'
ATTACHMENT = Path('C:/TLBB/085/.codex-remote-attachments/01a0cb73-9baa-7e93-bbf5-873f314a71da/863a49b4-ada6-4933-a7ea-5799f47e64b9/1-HJ-05-hualuo-Bug-fix-log-3.txt')
SERVER = Path('//wsl.localhost/TLBB/home/ubuntu/cys-test-20260913')
LINUX = '/home/ubuntu/cys-test-20260913'
WS = '/mnt/c/TLBB/085/CY-Source'

def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()

def main():
    OUT.mkdir(parents=True, exist_ok=True)
    counts = collections.Counter(); items=[]
    for line in ATTACHMENT.read_text(encoding='utf-8-sig').splitlines():
        m = re.match(r'^(\d+(?:\.5)?)[. ]\s*(.+?)\s*$', line.strip())
        if not m:
            assert not line.strip(), repr(line)
            continue
        number, desc = m.groups(); counts[number]+=1
        key = number if number != '121' else f'121{"a" if counts[number]==1 else "b"}'
        items.append(dict(key=key, original_number=number, text=desc))
    (OUT/'items.json').write_text(json.dumps(items,ensure_ascii=False,indent=2),encoding='utf-8')
    def run(name, command):
        p=subprocess.run(command,capture_output=True,timeout=180)
        output=(p.stdout+p.stderr).decode('utf-8','replace')
        (OUT/(name+'.txt')).write_text(output,encoding='utf-8')
        return dict(name=name,exit=p.returncode,tail=output.splitlines()[-3:],command=command)
    base=['wsl','-d','TLBB','-u','root','--']
    tests=[('pet_integrity_tests',[LINUX,LINUX+'/GameServer/lualib']),
           ('pvp_integrity_tests',[LINUX,LINUX+'/GameServer/lualib']),
           ('test_equipcraft',[LINUX,LINUX]),
           ('test_equipment_passives',[LINUX,LINUX]),
           ('test_gameplay_audit',[LINUX,LINUX]),
           ('test_quest_rewards',[LINUX,LINUX]),
           ('test_runtime_gifts',[LINUX+'/GameServer/lualib']),
           ('social_trade_test',[LINUX,LINUX]),
           ('social_city_test',[LINUX+'/GameServer/lualib/cys_social_city.lua'])]
    results=[]
    for name,args in tests:
        result=run(name,base+['lua',WS+'/Tools/server/'+name+'.lua',*args])
        results.append(result);print(name,result['exit'],result['tail'])
    results.append(run('equipment-routes',base+['python3',WS+'/Tools/server/audit_equipment_routes.py',LINUX]))
    results.append(run('targeted-probes',base+['lua',WS+'/Tools/audit/hj05_probes.lua',LINUX]))
    results.append(run('server-status',base+['python3',WS+'/Tools/server/provision_test_wsl.py','status']))
    sources=['GameServer/lualib/item.lua','GameServer/lualib/pet_attrib.lua',
        'GameServer/lualib/db/pet_attrib.lua','GameServer/lualib/db/human_attrib.lua',
        'GameServer/services/scene/obj/human.lua','GameServer/services/scene/scenecore.lua',
        'GameServer/lualib/impactenginer.lua','GameServer/lualib/talentenginer.lua',
        'GameServer/services/scene/ai/human.lua','GameServer/lualib/db/pet_detail.lua',
        'GameServer/lualib/cys_social_city.lua','GameServer/lualib/cy_four_combat/release.lua']
    report=dict(utc=datetime.datetime.now(datetime.timezone.utc).isoformat(),
        attachment=str(ATTACHMENT),attachment_sha256=sha(ATTACHMENT),count=len(items),
        duplicate_numbers={k:v for k,v in counts.items() if v>1},
        game_sha256=sha(ROOT/'Build/world-gui/stage-play-21/Bin64/Game.exe'),
        server_root=str(SERVER),runtime_sources={p:sha(SERVER/p) for p in sources},
        tests=results,note='Isolated actual-source checks with mocked actors/transport; no gameplay writes, no restart, no GUI reproduction.')
    (OUT/'evidence.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
    print('ITEMS',len(items),'RESULTS',[(r['name'],r['exit']) for r in results])

if __name__=='__main__':main()
