"""Read-only comparison of the GL event's monster family with native CY rows."""
from pathlib import Path
import hashlib,importlib.util,json
ROOT=Path(__file__).resolve().parents[2]
LIVE=Path('//wsl.localhost/TLBB/home/ubuntu/cys-test-20260913')
spec=importlib.util.spec_from_file_location('npc_rows',ROOT/'Tools/reapply/npcdata/80-monsterattr-rows.py')
m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
t=m.dbc_read(ROOT/'Assets/CanonicalCY/Data/ConfigFolder/MonsterAttrExTable.txt')
pool=t['pool']
def name(row):
    off=row[1];return pool[off:pool.find(b'\0',off)].decode('gb18030')
def rows(path):
    out={}
    for line in path.read_bytes().decode('gb18030').splitlines():
        r=line.split('\t')
        if len(r)>60 and r[0].isdigit():out[int(r[0])]=r
    return out
gl=rows(LIVE/'configs/cys_gl_only/MonsterAttrExTable.txt')
cy=rows(LIVE/'configs/MonsterAttrExTable.txt')
result=[]
for i in range(13565,13601):
    if i not in gl:continue
    r=gl[i];matches=[a for a in t['rows'] if name(a)==r[1]]
    result.append(dict(gl_id=i,name=r[1],gl_level=r[3],source_id_present_in_cy_server=i in cy,
        source_id_present_in_cy_client=any(a[0]==i for a in t['rows']),
        matches=[dict(cy_id=a[0],level=a[3],server_present=a[0] in cy,server_name=cy.get(a[0],['',''])[1]) for a in matches]))
out=ROOT/'Build/Logs/2026-09-28-hj05-cangjingge';out.mkdir(exist_ok=True)
(out/'ids.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf8')
paths=[LIVE/'configs/cys_gl_only/MonsterAttrExTable.txt',LIVE/'configs/MonsterAttrExTable.txt',
       ROOT/'Assets/CanonicalCY/Data/ConfigFolder/MonsterAttrExTable.txt',
       LIVE/'Game_2/Script/scripts/obj/DynamicNPC/bg_CangJingGe.lua',
       LIVE/'Game_2/Script/scripts/obj/DynamicNPC/FB_cangjinge_FB.lua']
summary=dict(read_only_runtime=True,source_ids=len(result),
    missing_server=sum(not r['source_id_present_in_cy_server'] for r in result),
    missing_client=sum(not r['source_id_present_in_cy_client'] for r in result),
    native_name_matches=sum(bool(r['matches']) for r in result),
    sources=[dict(path=str(p),sha256=hashlib.sha256(p.read_bytes()).hexdigest()) for p in paths],
    assessment='NPC 13565 has native CY twin 549, but the other monster families have no exact native-name match. Remapping only the entry NPC cannot repair the instance. No runtime file changed.')
(out/'summary.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2),encoding='utf8')
print(json.dumps(summary,ensure_ascii=False,indent=1))
