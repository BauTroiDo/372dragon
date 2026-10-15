"""Current full BSON backup for the October 1 diagnostic, private test15 only."""
from pathlib import Path
import argparse,json
from bson import json_util
from cs3b_menpai import provision
from give_item import connected
LOG=Path('/mnt/c/TLBB/085/CY-Source/Build/Logs/2026-10-01-runtime-audit')
p=argparse.ArgumentParser();p.add_argument('mode',choices=['backup','shop','restore','verify']);a=p.parse_args()
rt=provision();assert not connected();LOG.mkdir(exist_ok=True)
if a.mode in ('shop','restore'):
 spec=next(s for s in rt.role_specs() if s['name']=='Game');assert not rt.owned_processes(spec)
with rt.database() as c:
 col=c.tlbb.character;d=col.find_one({'attrib.guid':200016});assert d
 path=LOG/'original-test15.json'
 if a.mode=='backup':
  assert not path.exists();path.write_text(json_util.dumps(d),encoding='utf8')
  print(json.dumps(dict(scene=d.get('sceneid'),level=d['attrib'].get('level'),position=d['attrib'].get('world_pos'),bag_slots=len(d.get('prop_bag_list',{})))))
 else:
  saved=json_util.loads(path.read_text(encoding='utf8'));assert saved['_id']==d['_id']
  if a.mode=='shop':
   col.replace_one({'_id':d['_id']},saved)
   col.update_one({'_id':d['_id']},{'$set':{'sceneid':2,'attrib.sceneid':2,'world_pos':{'x':271.0,'y':135.0},'attrib.world_pos':{'x':271.0,'y':135.0},'attrib.ride':-1,'attrib.hp':5000,'attrib.mp':3000}})
   print('Prepared owned test15 near NPC shop; original BSON preserved')
  else:
   if a.mode=='restore':col.replace_one({'_id':d['_id']},saved)
   assert col.find_one({'_id':d['_id']})==saved
   (LOG/(a.mode+'.json')).write_text(json.dumps(dict(full_bson_equal=True,guid=200016)))
   print('PASS exact original BSON',a.mode)
