"""Fresh complete BSON snapshot of owned characters; clean only the owned guild in world_10."""
from pathlib import Path
import argparse,json,copy
from bson import json_util
from cs3b_menpai import provision
from give_item import connected
LOG=Path('/mnt/c/TLBB/085/CY-Source/Build/Logs/2026-09-28-social-completion')
p=argparse.ArgumentParser();p.add_argument('mode',choices=['seed','reset','inspect','restore','verify']);a=p.parse_args()
assert not connected(),'Private client connected'
backup=LOG/'fixture-original.bson.json';guids=[200016,200015];guildname='CYSQA0928'
with provision().database() as c:
 col=c.tlbb.character;guilds=c.world_10.guild;leagues=c.world_10.leagues
 docs=[col.find_one({'attrib.guid':g})for g in guids]
 assert all(docs)and [d['attrib']['name']for d in docs]==['CYTest15','CYTest14']
 if a.mode=='seed':
  assert not backup.exists()
  assert not leagues.find_one({'name':'CYSAL0928'})
  assert not guilds.find_one({'name':guildname}),'Existing guild has the fixture name'
  assert not leagues.find_one({'name':'CYSAL0928'}),'Existing alliance has the fixture name'
  assert not guilds.find_one({'users.guid':{'$in':guids}}),'Test character already has guild data; preserve and choose fixture explicitly'
  backup.write_text(json_util.dumps({'characters':docs}))
 if a.mode in ['seed','reset']:
  saved=json_util.loads(backup.read_text())
  for d in saved['characters']:col.replace_one({'_id':d['_id']},d)
  guilds.delete_many({'name':guildname,'chief_guid':{'$in':guids}})
  leagues.delete_many({'name':'CYSAL0928','chief_guid':{'$in':guids}})
  for i,d in enumerate(docs):
   col.update_one({'_id':d['_id']},{'$set':{'attrib.level':60,'attrib.money':1500000,'attrib.jiaozi':0,'attrib.guild_id':-1,'attrib.guild_name':'','attrib.confederate_id':-1,'attrib.confederate_name':'','attrib.ride':-1,'attrib.sceneid':2,'sceneid':2,'attrib.world_pos':{'x':218.+i*2,'y':109.},'world_pos':{'x':218.+i*2,'y':109.},'attrib.hp':5000,'attrib.mp':5000,'impact_list':[],'cool_down_times':{},'setting.2':{'type':0,'data':0}}})
  (LOG/'fixture-restore.json').unlink(missing_ok=True);print('Seeded owned test15/test14, exact original BSON saved')
 elif a.mode=='restore':
  saved=json_util.loads(backup.read_text())
  for d in saved['characters']:col.replace_one({'_id':d['_id']},d)
  guilds.delete_many({'name':guildname,'chief_guid':{'$in':guids}})
  leagues.delete_many({'name':'CYSAL0928','chief_guid':{'$in':guids}})
  assert all(col.find_one({'_id':d['_id']})==d for d in saved['characters'])
  assert not leagues.find_one({'name':'CYSAL0928'})
  assert not guilds.find_one({'name':guildname})
  (LOG/'fixture-restore.json').write_text('{"full_bson_equal":true,"characters":2,"fixture_guild_removed":true}')
  print('PASS exact full BSON restore; fixture guild removed')
 elif a.mode=='verify':
  saved=json_util.loads(backup.read_text())
  assert all(col.find_one({'_id':d['_id']})==d for d in saved['characters']),'Restored character changed after restart'
  assert not leagues.find_one({'name':'CYSAL0928'})
  assert not guilds.find_one({'name':guildname}),'Fixture guild still exists'
  (LOG/'fixture-verified-after-restart.json').write_text('{"read_only_check":true,"full_bson_equal":true,"characters":2,"fixture_guild_removed":true}')
  print('PASS read-only verification after restart; both original characters and no fixture guild')
 else:
  report={'characters':[{'guid':d['attrib']['guid'],'money':d['attrib'].get('money'),'guild':d['attrib'].get('guild_id'),'title':d['attrib'].get('title')}for d in docs], 'guilds':list(guilds.find({'name':guildname},{'_id':0}))}
  (LOG/'fixture-inspect.json').write_text(json_util.dumps(report,indent=2,ensure_ascii=False));print(json_util.dumps(report,ensure_ascii=False))
