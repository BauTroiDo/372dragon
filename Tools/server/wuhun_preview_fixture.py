"""Isolated test15 preview check: full BSON backup, controlled bag, exact restore."""
from pathlib import Path
import argparse
from bson import json_util
from cs3b_menpai import provision
from give_item import connected
p=argparse.ArgumentParser();p.add_argument('mode',choices=['seed','reset','restore']);p.add_argument('--log',type=Path,default=Path('/mnt/c/TLBB/085/CY-Source/Build/Logs/2026-09-25-wuhun-preview'));a=p.parse_args()
log=a.log.resolve();assert log.is_relative_to(Path('/mnt/c/TLBB/085/CY-Source/Build/Logs'));log.mkdir(parents=True,exist_ok=True)
assert not connected(),'Private clients connected'
with provision().database() as client:
 col=client.tlbb.character;doc=col.find_one({'attrib.guid':200016});assert doc
 backup=log/'test15-original.json'
 if a.mode=='restore':
  old=json_util.loads(backup.read_text(encoding='utf8'));assert old['_id']==doc['_id']
  col.replace_one({'_id':doc['_id']},old);assert col.find_one({'_id':doc['_id']})==old
  print('PASS exact full BSON restore test15')
 else:
  if a.mode=='seed':
   assert not backup.exists(),'Never overwrite original fixture'
   backup.write_text(json_util.dumps(doc),encoding='utf8')
  else:
   old=json_util.loads(backup.read_text(encoding='utf8'));assert old['_id']==doc['_id']
   col.replace_one({'_id':doc['_id']},old);doc=old
  assert doc['equip_list']['19']['item_index']==10156001
  col.update_one({'_id':doc['_id']},{'$set':{'prop_bag_list':{},'attrib.sceneid':12,'sceneid':12,
   'attrib.world_pos':{'x':77.0,'y':89.0},'attrib.ride':-1,'impact_list':[],'attrib.hp':5000,'attrib.mp':3000}})
  print('Prepared private test15; original BSON preserved')
