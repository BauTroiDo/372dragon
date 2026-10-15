"""Read-only census; reports data gaps without inventing quest/crafting rules."""
from pathlib import Path
import argparse, collections, json, re, subprocess, sys
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'Tools/game'))
from dbc_inventory import Table
p=argparse.ArgumentParser();p.add_argument('--root',type=Path,required=True);p.add_argument('--out',type=Path,required=True);a=p.parse_args()
R=a.root;out=a.out;out.mkdir(parents=True,exist_ok=True)
scripts=R/'Game_2/Script/scripts'
registry=(R/'Game_2/Script/scripts/scripts.lua').read_text(encoding='utf8')
registered={int(i):s for i,s in re.findall(r'\[(\d+)\]\s*=\s*["\']([^"\']+)',registry)}
syntax=[];missions=[];source={}
for f in scripts.rglob('*.lua'):
    text=f.read_text(encoding='utf8',errors='replace');source[f]=text
    proc=subprocess.run(['luac5.4','-p',str(f)],capture_output=True,text=True)
    if proc.returncode:syntax.append({'file':str(f.relative_to(R)),'error':proc.stderr.strip()})
    if not re.search(r'function \w+:On(?:Accept|Submit)\(',text):continue
    ids=[int(x) for x in re.findall(r'\.(?:g_MissionId|g_MissionID)\s*=\s*(\d+)',text)]
    sid=re.search(r'\.(?:script_id|g_ScriptId)\s*=\s*(\d+)',text)
    path='scripts.'+str(f.relative_to(scripts).with_suffix('')).replace('/','.').replace('\\','.')
    regs=[i for i,s in registered.items()if s==path]
    methods=re.findall(r'function \w+:(\w+)\(',text)
    missions.append({'path':str(f.relative_to(R)),'mission_ids':ids,'declared_script':int(sid[1])if sid else None,
        'registered_ids':regs,'callbacks':[n for n in methods if n in ('OnAccept','OnSubmit','CheckAccept','CheckSubmit')],
        'delegates':sorted(set(int(x)for x in re.findall(r'CallScriptFunction\(\s*(\d+)',text))),
        'prerequisites':sorted(set(int(x)for x in re.findall(r'\.g_MissionIdPre\s*=\s*(\d+)',text)))})
tables={n:{row[0]:row for row in Table(R/'configs'/f'{n}.txt').rows} for n in ('EquipBase','CommonItem','GemInfo','ItemCompound','Ability')}
items=set(tables['EquipBase'])|set(tables['CommonItem'])|set(tables['GemInfo'])
if (R/'configs/PetEquipBase.txt').exists():items.update(row[0]for row in Table(R/'configs/PetEquipBase.txt').rows)
recipes=[]
for id,row in sorted(tables['ItemCompound'].items()):
    gaps=[]
    if row[4]not in tables['Ability']:gaps.append('ability missing')
    if row[2]>0 and row[2]not in items:gaps.append('output item missing')
    if row[2]<=0:gaps.append('script-dependent output')
    for n in range(6,16,2):
        if row[n]>0 and row[n]not in items:gaps.append('material missing '+str(row[n]))
    if row[27]>0 and row[27]not in registered:gaps.append('recipe script missing')
    recipes.append({'id':id,'ability':row[4],'script':row[27],'output':row[2],'count':row[3],'issues':gaps})
traits=Table(R/'configs/AttackTraits.txt').rows
mapping={**{i:i for i in range(10)},10:16,11:17,12:18,13:19,14:20,15:15}
byid={r[0]:r for r in traits}
matrix=[{'menpai':m,'trait':t,'name':byid[t][1],'physical':byid[t][3]/1e6,'magic':byid[t][4]/1e6,
    'cold':byid[t][5]/1e6,'fire':byid[t][6]/1e6,'mystic':byid[t][7]/1e6,'poison':byid[t][8]/1e6}for m,t in mapping.items()]
xinfas={r[0]:r[1]for r in Table(R/'configs/XinFa_V1.txt').rows}
skilldata={r[0]for r in Table(R/'configs/SkillData_V1.txt').rows}
templates=Table(R/'configs/SkillTemplate_V1.txt');cols=templates.names
school_skills=[]
for row in templates.rows:
 school=row[cols.index('门派')];book=row[cols.index('心法ID')]
 if school<0 or school>15:continue
 levels=[v for n,v in zip(cols,row) if re.match('心法\\d+级对应的实际技能ID',n)and v>=0]
 school_skills.append({'id':row[0],'school':school,'xinfa':book,'required_xinfa':row[cols.index('技能的心法等级限制')],
  'xinfa_missing':book>=0 and book not in xinfas,'missing_skilldata':sorted(set(levels)-skilldata)})
report={'script_count':len(source),'syntax_errors':syntax,'mission_scripts':missions,'recipes':recipes,'element_coefficients':matrix,'school_skills':school_skills,
    'summary':{'mission_scripts':len(missions),'unregistered_mission_scripts':sum(not x['registered_ids']for x in missions),
               'recipes':len(recipes),'recipes_with_data_dependencies':sum(bool(x['issues'])for x in recipes),'syntax_errors':len(syntax)}}
(out/'data-audit.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf8')
print(json.dumps(report['summary'],ensure_ascii=False))
for e in syntax[:10]:print(e)
print('Recipe dependency counts:',dict(collections.Counter(i for r in recipes for i in r['issues'])))
