"""Owned test15, current full BSON backup; never reuse an earlier task's state."""
from pathlib import Path
import argparse,json,copy
from bson import json_util
from cs3b_menpai import provision
from give_item import connected,scan
LOG=Path('/mnt/c/TLBB/085/CY-Source/Build/Logs/2026-09-26-runtime-polish')
p=argparse.ArgumentParser();p.add_argument('mode',choices=['seed','reset','gift','battle','restore','verify']);a=p.parse_args()
assert not connected(),'Private client connected'
with provision().database() as c:
 col=c.tlbb.character;d=col.find_one({'attrib.guid':200016});assert d
 backup=LOG/'fixture-original.bson.json'
 if a.mode=='restore':
  saved=json_util.loads(backup.read_text());assert saved['_id']==d['_id'];col.replace_one({'_id':d['_id']},saved);assert col.find_one({'_id':d['_id']})==saved
  (LOG/'fixture-restore.json').write_text('{"full_bson_equal":true}');print('PASS exact full fixture restore');raise SystemExit
 if a.mode=='verify':
  print({k:d['attrib'].get(k) for k in ['level','exp','menpai','sceneid']});raise SystemExit
 if a.mode=='seed':assert not backup.exists();backup.write_text(json_util.dumps(d))
 else:saved=json_util.loads(backup.read_text());col.replace_one({'_id':d['_id']},saved);d=saved
 fields={'attrib.exp':11694,'attrib.level':15,'attrib.menpai':0,'attrib.sceneid':2,'sceneid':2,'attrib.world_pos':{'x':271.0,'y':135.0},'world_pos':{'x':271.0,'y':135.0},'attrib.ride':-1,'impact_list':[],'cool_down_times':{}}
 if a.mode in ['gift','battle']:
  top,samples=scan(col);item=copy.deepcopy(samples[3]);count=2 if a.mode=='gift' else 3
  item.update(item_index=38007057 if a.mode=='gift' else 30001001,count=count,lay_count=count,status=2)
  item['guid']={'world':254,'server':254,'mask':0,'series':top+1};item['unknow_20'][0]=count
  # Persisted container keys are one-based; client bag positions are zero-based.
  fields['prop_bag_list']={'1' if a.mode=='gift' else '100':item}
  if a.mode=='gift':fields['attrib.level']=95
 if a.mode=='battle':
  # New characters have no saved assist settings; use the deployed module's
  # defaults before selecting the bounded test scenario.
  cfg=copy.deepcopy(d.get('cys_assist')) or [[1]*17,[0,0,0],[1,1,1],[50]*3,[50]*4,[1,1,50,50,0,0],[1,1,0,0,0,0,0,0,0,0],[0]*3,[1]*3,[50]*3,[0]*3]
  assert len(cfg)==11
  cfg[8]=[0,0,0];cfg[1]=[0,0,0];cfg[2]=[1,1,1]
  fields.update({'attrib.level':81,'attrib.exp':1000,'attrib.menpai':3,'attrib.sceneid':6,'sceneid':6,
   'attrib.world_pos':{'x':40.0,'y':150.0},'world_pos':{'x':40.0,'y':150.0},'attrib.hp':50,'attrib.mp':3000,
   'skill_list':[0,1,2,3,21,22,34,35,43,371,374],
   'xinfa_list':[{'m_nXinFaID':i,'m_nXinFaLevel':60} for i in range(19,25)],'cys_assist':cfg})
 col.update_one({'_id':d['_id']},{'$set':fields});print('Prepared test15',a.mode,'level',fields['attrib.level'],'EXP',fields['attrib.exp'],'original BSON preserved')
