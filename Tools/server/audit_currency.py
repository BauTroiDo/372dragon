from pathlib import Path
import json,re
from cs3b_menpai import provision
root=Path('/home/ubuntu/cys-test-20260913')
out=Path('/mnt/c/TLBB/085/CY-Source/Build/Logs/2026-09-26-vothach');out.mkdir(parents=True,exist_ok=True)
with provision().database() as c:
 rows=[]
 for d in c.tlbb.character.find({}, {'attrib':1}):
  a=d['attrib'];v={k:a.get(k,0) for k in ['money','jiaozi','yuanbao','bind_yuanbao','zengdian','bank_save_money']}
  rows.append({'guid':a['guid'],**v})
 report={'characters':len(rows),'max_vo_thach':max((r['money']+r['jiaozi'] for r in rows),default=0),'max_yuanbao':max((r['yuanbao']+r['bind_yuanbao']+r['zengdian'] for r in rows),default=0),'nonzero_zengdian':sum(r['zengdian']!=0 for r in rows),'overflow_guids':[r['guid'] for r in rows if r['money']+r['jiaozi']>2147483647 or r['yuanbao']+r['bind_yuanbao']+r['zengdian']>2147483647]}
 (out/'wallet-audit.json').write_text(json.dumps(report,indent=2));print(json.dumps(report))
contexts=[]
for p in (root/'Game_2').rglob('*.lua'):
 lines=p.read_text(errors='replace').splitlines()
 for i,s in enumerate(lines):
  if 'GetMoneyJZ(' in s and 'GetMoney(' not in s and not s.lstrip().startswith('--'):
   contexts.append({'path':str(p.relative_to(root)),'line':i+1,'text':'\n'.join(lines[max(0,i-2):i+9])})
(out/'legacy-jiaozi-context.json').write_text(json.dumps(contexts,ensure_ascii=False,indent=2))
print('Standalone legacy Jiaozi contexts:',len(contexts))
