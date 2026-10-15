"""Reversible owned-character fixtures for round2; run offline in private WSL only."""
from pathlib import Path
import argparse,copy
from bson import json_util
from cs3b_menpai import provision
from give_item import connected,scan
p=argparse.ArgumentParser();p.add_argument('mode',choices=['gm','restore-gm','combat','portal','stack','verify-stack']);p.add_argument('--scene',type=int,default=6);p.add_argument('--x',type=float,default=40);p.add_argument('--z',type=float,default=150);a=p.parse_args()
assert not connected(),'private client still connected'
log=Path('/mnt/c/TLBB/085/CY-Source/Build/Logs/2026-09-23-round2')
guid=200001 if a.mode in ('gm','restore-gm') else 200016
backup=log/('test00-original.json' if guid==200001 else 'test15-original.json')
with provision().database() as c:
 col=c.tlbb.character;d=col.find_one({'attrib.guid':guid});assert d
 if a.mode=='gm':
  if not backup.exists():backup.write_text(json_util.dumps(d),encoding='utf8')
  col.update_one({'_id':d['_id']},{'$set':{'attrib.sceneid':12,'sceneid':12,'attrib.world_pos':{'x':77.0,'y':89.0},'attrib.hp':5000,'attrib.mp':3000}})
 elif a.mode=='restore-gm':
  saved=json_util.loads(backup.read_text(encoding='utf8'));assert saved['_id']==d['_id'];col.replace_one({'_id':d['_id']},saved);assert col.find_one({'_id':d['_id']})==saved
 elif a.mode=='verify-stack':
  rows=[(k,v) for k,v in d['prop_bag_list'].items() if v.get('item_index')==30001001]
  assert len(rows)==1 and rows[0][0]=='100',rows
  row=rows[0][1];assert row['lay_count']==250 and row['count']==250 and row['unknow_20'][0]==250,row
  print('PASS persisted stack at slot99: one GUID, 250 items')
 else:
  assert backup.exists()
  fields={'attrib.sceneid':a.scene,'sceneid':a.scene,'attrib.world_pos':{'x':a.x,'y':a.z},'attrib.hp':5000,'attrib.mp':3000}
  if a.mode=='combat':fields['attrib.exp']=1000
  if a.mode=='stack':
   top,samples=scan(col)
   for other in col.find({},{'equip_list':1,'cys_tembank':1}):
    def serials(value):
     if isinstance(value,dict):
      if isinstance(value.get('guid'),dict):yield int(value['guid'].get('series',0))
      for child in value.values():yield from serials(child)
     elif isinstance(value,list):
      for child in value:yield from serials(child)
    top=max(top,max(serials(other),default=0))
   bag={}
   for offset,count in enumerate((249,1)):
    row=copy.deepcopy(samples[3]);row.update(item_index=30001001,count=count,lay_count=count,status=2)
    row['guid']={'world':254,'server':254,'mask':0,'series':top+1+offset};row['unknow_20'][0]=count
    bag[str(19+offset)]=row
   fields.update({'prop_bag_list':bag,'attrib.sceneid':12,'sceneid':12,'attrib.world_pos':{'x':77.0,'y':89.0}})
  col.update_one({'_id':d['_id']},{'$set':fields})
 print('PASS owned fixture',a.mode,'guid',guid,'complete backup preserved')
