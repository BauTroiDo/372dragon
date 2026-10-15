"""Read-only CY data audit for the skill-book pages and starter combat weapons."""
from pathlib import Path
import json, sys
sys.stdout.reconfigure(encoding='utf8')
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'Tools/redteam'))
from rt_dbc import Dbc
cfg=ROOT/'Assets/CanonicalCY/Data/ConfigFolder'
x=Dbc(cfg/'XinFa_V1.txt');s=Dbc(cfg/'SkillTemplate_V1.txt');e=Dbc(cfg/'EquipBase.txt');c=Dbc(cfg/'SystemColour.txt')
hidden=set(range(788,801))|set(range(821,835))|set(range(4465,4467))|set(range(4533,4537))|set(range(4528,4530))|set(range(4742,4747))|set(range(5189,5194))
rows=[]
for sect in list(range(9))+list(range(10,16)):
    pages=[x.i(r,0) for r in range(x.nR) if x.i(r,1)==sect]
    assert len(pages)==8,(sect,pages)
    counts=[sum(s.i(r,1)==sect and s.i(r,10)==page and s.i(r,20)==0 and s.i(r,0) not in hidden for r in range(s.nR)) for page in pages]
    assert all(1<=n<=5 for n in counts),(sect,counts)
    rows.append(dict(sect=sect,pages=pages,visible=counts))
weapons=[10100001,10101001,10102001,10103001,10104001,10105001,10106001,10107001,10108001,10116001,10117001]
for id in weapons:
    r=next(r for r in range(e.nR) if e.i(r,0)==id)
    assert e.i(r,5)==0 and e.i(r,11)==10 and e.i(r,6)>0,id
palette=[dict(id=c.i(r,0),name=c.s(r,1).decode('utf8',errors='replace'),font=c.s(r,2).decode(),outline=c.s(r,3).decode()) for r in range(c.nR) if 1<=c.i(r,0)<=13]
print(json.dumps(dict(passed=True,factions=rows,starter_weapons=weapons,palette=palette),ensure_ascii=False,indent=2))
