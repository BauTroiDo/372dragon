"""Owned private test15 fixture; new full BSON backup and exact restore."""
from pathlib import Path
import argparse,copy,json
from bson import json_util
from cs3b_menpai import provision
from give_item import connected,scan
LOG=Path('/mnt/c/TLBB/085/CY-Source/Build/Logs/2026-09-25-smart-equip')
p=argparse.ArgumentParser();p.add_argument('mode',choices=['seed','reset','verify','restore']);a=p.parse_args()
assert not connected(),'Private client connected'
with provision().database() as c:
 col=c.tlbb.character;d=col.find_one({'attrib.guid':200016});assert d
 backup=LOG/'test15-original.json';LOG.mkdir(parents=True,exist_ok=True)
 if a.mode=='restore':
  saved=json_util.loads(backup.read_text());assert saved['_id']==d['_id'];col.replace_one({'_id':d['_id']},saved)
  assert col.find_one({'_id':d['_id']})==saved
  (LOG/'restore-result.json').write_text('{"full_bson_equal":true}');print('PASS full BSON restore');raise SystemExit
 if a.mode=='verify':
  expected={1:10102001,2:10110000,7:10122001,12:10122001,13:10123001,14:10123001,19:10156901,40:10156902}
  assert {int(k):v['item_index'] for k,v in d['equip_list'].items()}==expected
  rows=list(d['equip_list'].values())+list(d['prop_bag_list'].values())
  ids=[tuple(r['guid'].get(k,0) for k in ['world','server','mask','series']) for r in rows]
  assert len(ids)==12 and len(set(ids))==12
  seed=json.loads((LOG/'seed-items.json').read_text())
  for original in seed:
   row=next(r for r in rows if r['guid']==original['guid'])
   for key in ['item_index','enhancement_level','creator','qualifications','list_2']:
    assert row.get(key)==original.get(key),(key,row.get(key),original.get(key))
   # The GUI ends with real combat, which can consume durability legitimately.
   assert 0<=row['dur']<=original['dur']
  (LOG/'persistent-result.json').write_text(json.dumps({'items':len(ids),'unique':len(set(ids)),'metadata_preserved':True}))
  print('PASS 12 unique items, correct slots, metadata preserved');raise SystemExit
 if a.mode=='seed':assert not backup.exists();backup.write_text(json_util.dumps(d))
 else:original=json_util.loads(backup.read_text());col.replace_one({'_id':d['_id']},original);d=original
 top,samples=scan(col)
 def serials(v):
  if isinstance(v,dict):
   if isinstance(v.get('guid'),dict):yield v['guid'].get('series',0)
   for x in v.values():yield from serials(x)
  elif isinstance(v,list):
   for x in v:yield from serials(x)
 top=max(top,max((max(serials(x),default=0) for x in col.find({})),default=0));bag={}
 for n,(item,level,dur) in enumerate([(10102001,9,100),(10102001,0,100),(10122001,9,100),(10122001,0,100),(10122001,9,100),(10123001,9,100),(10123001,0,100),(10110000,9,100),(10110000,9,0),(10413017,3,100)],1):
  row=copy.deepcopy(samples[1]);row.update(item_index=item,equip_type=0,quality=2,status=3,creator='SmartEquip'+str(n),enhancement_level=level,
   qualifications=[0]*6,dur=dur,max_dur=125,slot_count=0,gem_count=0,list_2=[0]*4,diaowen_id=0,diaowen_material_count=0,dw_advance_level=0,
   dw_rankexp=0,dw_featuresid=0,reshuffle_count=0,qihedu=0,attr_types=[],attr_type=0,attr_count=0,attr_values=[],count=1,lay_count=1)
  row['guid']={'world':254,'server':254,'mask':0,'series':top+n};bag[str(n)]=row
 (LOG/'seed-items.json').write_text(json.dumps(list(bag.values())))
 fields={'equip_list':{},'prop_bag_list':bag,'attrib.menpai':3,'skill_list':[0,1,2,3,21,22,34,35,43,371],'xinfa_list':[{'m_nXinFaID':i,'m_nXinFaLevel':100} for i in range(19,25)],'attrib.level':100,'attrib.hp':5000,'attrib.mp':3000,'attrib.ride':-1,'attrib.sceneid':12,'sceneid':12,
  'attrib.world_pos':{'x':77.0,'y':89.0},'world_pos':{'x':77.0,'y':89.0},'impact_list':[],'cool_down_times':{},'game_flag.cys_soul_combat_until':0,
  'cys_shending':{'dust':0,'con':1,'attack':1,'con_gold':0,'attack_gold':0,'ice':6,'fire':4,'light':0,'poison':0}}
 col.update_one({'_id':d['_id']},{'$set':fields});print('Seeded ten identified equip instances; full BSON retained')
