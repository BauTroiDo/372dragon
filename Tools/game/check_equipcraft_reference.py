"""Check workshop constants against unmodified CY tables and donor Lua."""
from pathlib import Path
import hashlib,json,re
from dbc_inventory import Table
ROOT=Path(__file__).resolve().parents[2]
CY=ROOT.parent/'Tools/DATA NEW/DataCY31-08-26'
rates=ROOT/'Assets/CanonicalCY/Data/ConfigFolder/ZhiZunEquipRate.txt'
donor=CY/'tlbb15/Public/Data/Script/NewHJ_Script/EquipmentRelated/JingTong/EquipEducationClient.lua'
lua=(ROOT/'Tools/server/cys_equipcraft.lua').read_text(encoding='utf8')
cpp=(ROOT/'Src/Client/WXClient/Network/CysEquipmentTooltipFormat.h').read_text(encoding='utf8')
original=donor.read_bytes().decode('gbk')
rows=Table(rates).rows
assert rows==Table(CY/'Config/ZhiZunEquipRate.txt').rows and len(rows)==10
expected=[[r[stage]//100 for r in rows] for stage in [1,2]]
def matrix(s,pattern):
    m=re.search(pattern,s,re.S);assert m,pattern
    return [[int(x) for x in re.findall(r'\d+',group)] for group in m.groups()]
assert matrix(lua,r'local soul_bonus=\{\{([^}]+)\},\{([^}]+)\}\}')==expected
assert matrix(cpp,r'values\[2\]\[10\]=\{\{([^}]+)\},\{([^}]+)\}\}')==expected
costs=matrix(original,r'x900113_g_LevelupNeedItemCount\s*=\s*\{\s*\[\s*0\s*\]\s*=\s*\{([^}]+)\}\s*,\s*\[\s*1\s*\]\s*=\s*\{([^}]+)\}')
assert matrix(lua,r'local soul_cost=\{\{([^}]+)\},\{([^}]+)\}\}')==costs
palette={r[0]:r[2].upper() for r in Table(ROOT.parent/'client_GL/Data/ConfigFolder/SystemColour.txt').rows}
for id,colour in [(2000,'C8C8C8'),(2001,'00FF00'),(2002,'00CCFF'),(2003,'FF53FF'),(2004,'B3DB35')]:
    assert palette[id]==colour,(id,palette[id])
    assert '#c'+colour in cpp
record={'result':'PASS','rates_percent':expected,'material_count':costs,'sources':[]}
for p in [rates,donor,ROOT.parent/'client_GL/Data/ConfigFolder/SystemColour.txt']:
    record['sources'].append({'path':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()})
out=ROOT/'Build/Logs/2026-09-24-equipcraft/reference.json';out.parent.mkdir(parents=True,exist_ok=True);out.write_text(json.dumps(record,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
print('PASS CY rate table, both source/client percentage arrays, donor costs and GL tooltip palette')
