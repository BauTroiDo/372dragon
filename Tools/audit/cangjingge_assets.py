"""Read-only GL/CY asset and schema survey for the missing Cangjingge family."""
from pathlib import Path
import json,sys
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'Tools/game'))
from dbc_inventory import Table
LIVE=Path('//wsl.localhost/TLBB/home/ubuntu/cys-test-20260913')
GL=ROOT.parent/'client_GL/Data/ConfigFolder'
CY=ROOT/'Assets/CanonicalCY/Data/ConfigFolder'
out=ROOT/'Build/Logs/2026-09-29-cangjingge';out.mkdir(exist_ok=True)
monster=Table(LIVE/'configs/cys_gl_only/MonsterAttrExTable.txt')
gl=Table(GL/'CharModelEx.txt');cy=Table(CY/'CharModelEx.txt')
rows=[r for r in monster.rows if 13565<=int(r[0])<=13600 or 49285<=int(r[0])<=49289]
models=sorted({int(r[44]) for r in rows})
result={'monster_columns':list(enumerate(monster.names or monster.types)),
        'gl_columns':list(enumerate(gl.names or gl.types)),'cy_columns':list(enumerate(cy.names or cy.types)),
        'monster_groups':{str(i):[dict(id=r[0],name=r[1],level=r[3],skill=r[70]) for r in rows if int(r[44])==i] for i in models},
        'models':{str(i):{'gl':[r for r in gl.rows if int(r[0])==i], 'cy_same_id':[r for r in cy.rows if int(r[0])==i]} for i in models}}
for i,group in result['models'].items():
    strings={v for r in group['gl'] for v in r[1:] if isinstance(v,str) and v and not v.lstrip('-').replace('.','',1).isdigit()}
    group['cy_asset_matches']=[r for r in cy.rows if any(isinstance(v,str) and v in strings for v in r[1:])][:12]
(out/'asset-survey.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf8')
print(json.dumps(result,ensure_ascii=False,indent=1))
