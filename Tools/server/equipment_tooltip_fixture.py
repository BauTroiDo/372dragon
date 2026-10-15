"""Reversible tooltip fixture on private test15 only; preserve complete original BSON."""
from pathlib import Path
import argparse,copy
from bson import json_util
from cs3b_menpai import provision
from give_item import connected,scan
LOG=Path('/mnt/c/TLBB/085/CY-Source/Build/Logs/2026-09-24-equipment-tooltips')
p=argparse.ArgumentParser();p.add_argument('mode',choices=['seed','refresh','restore']);a=p.parse_args()
assert not connected(),'Close private clients first'
with provision().database() as c:
 col=c.tlbb.character;d=col.find_one({'attrib.guid':200016});assert d
 backup=LOG/'test15-original.json'
 if a.mode=='restore':
  saved=json_util.loads(backup.read_text(encoding='utf8'));assert saved['_id']==d['_id']
  col.replace_one({'_id':d['_id']},saved);assert col.find_one({'_id':d['_id']})==saved
  print('PASS complete test15 BSON restored exactly');raise SystemExit
 if a.mode=='seed':
  assert not backup.exists(),'Do not overwrite original fixture'
  backup.write_text(json_util.dumps(d),encoding='utf8')
 else:assert backup.exists()
 top,samples=scan(col)
 def serials(v):
  if isinstance(v,dict):
   if isinstance(v.get('guid'),dict):yield int(v['guid'].get('series',0))
   for a in v.values():yield from serials(a)
  elif isinstance(v,list):
   for a in v:yield from serials(a)
 top=max(top,max((max(serials(v),default=0) for v in col.find({})),default=0))
 bag={}
 for n in range(1,4):
  row=copy.deepcopy(samples[1]);row.update(item_index=10102001,equip_type=0,quality=8 if n==1 else 2,
   status=0x73 if n==1 else 2,creator='ThoRen&SQ119&ZF3' if n==1 else '',qihedu=119 if n==1 else 0,
   enhancement_level=9 if n==1 else 3 if n==3 else 0,qualifications=[100,50,200,150,1,255] if n==1 else [0]*6,
   dur=100,max_dur=125,slot_count=4 if n==1 else 0,gem_count=3 if n==1 else 0,
   list_2=[50101001,0,50101002,50102001] if n==1 else [0]*4,
   diaowen_id=19 if n==1 else 0,diaowen_material_count=2 if n==1 else 0,
   reshuffle_count=7 if n==1 else 0,dw_advance_level=5 if n==1 else 0,dw_rankexp=12,dw_featuresid=0,
   count=1,lay_count=1)
  bits=[0,3,6,7,9,10,12,13,15,16,42,43,44,45,46,54] if n==1 else []
  row.update(attr_types=bits,attr_type=sum(1<<b for b in bits),attr_count=len(bits),attr_values=[100+i for i in range(len(bits))])
  row['guid']={'world':254,'server':254,'mask':0,'series':top+n};bag[str(n)]=row
 fields={'attrib.sceneid':12,'sceneid':12,'attrib.world_pos':{'x':77.0,'y':89.0},'attrib.hp':5000,'attrib.mp':3000,
         'prop_bag_list':{k:v for k,v in bag.items() if k!='3'},'equip_list.1':bag['3']}
 col.update_one({'_id':d['_id']},{'$set':fields})
 print('Prepared advanced bag, plain same-ID bag, +3 equipped; complete original BSON saved')
