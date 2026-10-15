"""Private test15 only; preserve and restore complete BSON, including soul cooldowns."""
from pathlib import Path
import argparse,copy,json,sys
from bson import json_util
sys.path.insert(0,'/mnt/c/TLBB/085/CY-Source/Tools/server')
from cs3b_menpai import provision
from give_item import connected
LOG=Path('/mnt/c/TLBB/085/CY-Source/Build/Logs/2026-09-25-dual-souls')
p=argparse.ArgumentParser();p.add_argument('mode',choices=['seed','reset','verify','restore']);a=p.parse_args()
assert not connected(),'Private clients connected'
with provision().database() as c:
 col=c.tlbb.character;d=col.find_one({'attrib.guid':200016});assert d
 backup=LOG/'test15-original.json'
 if a.mode=='restore':
  original=json_util.loads(backup.read_text());assert d['_id']==original['_id'];col.replace_one({'_id':d['_id']},original)
  assert col.find_one({'_id':d['_id']})==original
  (LOG/'restore-result.json').write_text('{"full_bson_equal":true}');print('PASS complete BSON restore');raise SystemExit
 if a.mode=='verify':
  assert d['equip_list']['19']['item_index']==10156901 and d['equip_list']['40']['item_index']==10156902
  identities=[]
  def walk(x):
   if isinstance(x,dict):
    if 'item_index' in x and 'guid' in x and x['item_index'] in (10156901,10156902):identities.append(x['guid'])
    for v in x.values():walk(v)
   elif isinstance(x,list):
    for v in x:walk(v)
  walk(d);assert len(identities)==2 and identities[0]!=identities[1]
  result={'equips':{k:v['item_index'] for k,v in d['equip_list'].items()},'cooldown':d.get('cool_down_times',{}),'unique_souls':2}
  (LOG/'persistent-result.json').write_text(json.dumps(result,indent=2));print('PASS independent saved items and unique GUIDs');raise SystemExit
 if a.mode=='seed':
  assert not backup.exists();LOG.mkdir(parents=True,exist_ok=True);backup.write_text(json_util.dumps(d))
 else:d=json_util.loads(backup.read_text());col.replace_one({'_id':d['_id']},d)
 equips=copy.deepcopy(d.get('equip_list',{}));equips.pop('19',None);equips.pop('40',None)
 col.update_one({'_id':d['_id']},{'$set':{'equip_list':equips,'prop_bag_list':{},'attrib.level':100,'attrib.hp':5000,'attrib.mp':3000,'attrib.sceneid':12,'sceneid':12,'attrib.world_pos':{'x':77.0,'y':89.0},'world_pos':{'x':77.0,'y':89.0},'attrib.ride':-1,'attrib.wuhun_show_flag':1,'game_flag.cys_assault_hidden':0,'game_flag.cys_soul_combat_until':0,'impact_list':[],'cool_down_times':{}}})
 print('Seeded empty test15 bag; GUI grants the two souls through the real item initializer; full BSON backup retained')
