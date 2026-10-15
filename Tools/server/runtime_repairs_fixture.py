"""Current full BSON fixture: private test15 only, restore after all GUI probes."""
from pathlib import Path
import argparse,copy,json
from bson import json_util
from cs3b_menpai import provision
from give_item import connected,scan
LOG=Path('/mnt/c/TLBB/085/CY-Source/Build/Logs/2026-10-01-runtime-fixes')
p=argparse.ArgumentParser();p.add_argument('mode',choices=['backup','seed','purchase','restore','verify']);a=p.parse_args()
rt=provision();assert not connected();LOG.mkdir(exist_ok=True)
if a.mode in ('seed','restore'):
 spec=next(s for s in rt.role_specs() if s['name']=='Game');assert not rt.owned_processes(spec)
with rt.database() as c:
 col=c.tlbb.character;d=col.find_one({'attrib.guid':200016});assert d
 path=LOG/'original-test15.json'
 if a.mode=='backup':
  assert not path.exists();path.write_text(json_util.dumps(d),encoding='utf8');print('Saved fresh full BSON test15')
 else:
  saved=json_util.loads(path.read_text(encoding='utf8'));assert saved['_id']==d['_id']
  if a.mode=='seed':
   top,samples=scan(col);bag=copy.deepcopy(saved.get('prop_bag_list',{}))
   for slot,failed in ((0,1),(20,0),(21,3)):
    row=copy.deepcopy(samples[1]);row.update(item_index=10102001,equip_type=0,quality=2,status=2,creator='',
      enhancement_level=0,qualifications=[0]*6,dur=80,max_dur=125,unknow_7=failed,
      slot_count=0,gem_count=0,list_2=[0]*4,diaowen_id=0,diaowen_material_count=0,
      attr_types=[],attr_type=0,attr_count=0,attr_values=[],count=1,lay_count=1)
    row['guid']={'world':254,'server':254,'mask':0,'series':top+slot+1000};bag[str(slot+1)]=row
   fields={'sceneid':2,'attrib.sceneid':2,'world_pos':{'x':271.,'y':135.},'attrib.world_pos':{'x':271.,'y':135.},
       'attrib.ride':-1,'attrib.hp':5000,'attrib.mp':3000,'attrib.money':10000,'prop_bag_list':bag}
   col.replace_one({'_id':d['_id']},saved);col.update_one({'_id':d['_id']},{'$set':fields})
   seed=col.find_one({'_id':d['_id']});(LOG/'seed-test15.json').write_text(json_util.dumps(seed),encoding='utf8')
   print('Seeded three repair-counter instances; original BSON preserved')
  elif a.mode=='purchase':
   seed=json_util.loads((LOG/'seed-test15.json').read_text(encoding='utf8'))
   def count(doc):return sum(int(x.get('count',x.get('lay_count',0))) for x in doc['prop_bag_list'].values() if x['item_index']==30602001)
   assert d['attrib']['money']==10000+7-100,d['attrib']['money']
   assert count(d)==count(seed)+1,(count(d),count(seed))
   for slot in ('1','21','22'):assert d['prop_bag_list'][slot]['unknow_7']==seed['prop_bag_list'][slot]['unknow_7']
   (LOG/'purchase-persisted.json').write_text(json.dumps(dict(passed=True,money=d['attrib']['money'],quantity=count(d),repair_counters=[1,0,3])))
   print('PASS persisted GM +7, shop -100, one item added, repair counters unchanged')
  else:
   if a.mode=='restore':col.replace_one({'_id':d['_id']},saved)
   assert col.find_one({'_id':d['_id']})==saved
   (LOG/(a.mode+'.json')).write_text(json.dumps(dict(full_bson_equal=True,guid=200016)))
   print('PASS exact original BSON',a.mode)
