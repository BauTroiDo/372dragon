"""Owned test15/test14 only; fresh full BSON backup and exact restoration."""
from pathlib import Path
import argparse,json,copy
from bson import json_util
from cs3b_menpai import provision
from give_item import connected
LOG=Path('/mnt/c/TLBB/085/CY-Source/Build/Logs/2026-09-28-settings-friends-titles')
p=argparse.ArgumentParser();p.add_argument('mode',choices=['seed','reset','inspect','verify1','verify2','restore']);a=p.parse_args()
assert not connected(),'Private game session connected'
backup=LOG/'fixture-original.bson.json'
with provision().database() as c:
 col=c.tlbb.character
 docs=[col.find_one({'attrib.guid':g})for g in (200016,200015)]
 assert all(docs) and [d['attrib']['name']for d in docs]==['CYTest15','CYTest14']
 if a.mode in ('seed','reset'):
  if a.mode=='seed':assert not backup.exists();backup.write_text(json_util.dumps(docs))
  saved=json_util.loads(backup.read_text())
  for d in saved:col.replace_one({'_id':d['_id']},d)
  (LOG/'fixture-restore.json').unlink(missing_ok=True)
  common={'relation':{'friends':[],'black':[],'enemies':[],'temp':[],'mood':''},'setting.2':{'type':0,'data':0}}
  for d in docs:col.update_one({'_id':d['_id']},{'$set':copy.deepcopy(common)})
  col.update_one({'_id':docs[0]['_id']},{'$set':{'id_titles':[{'id':1043},{'id':1000}],
   'titles':[{'id':14,'str':'CY Community Test'}],'attrib.title':{'id':0,'str':''},
   'attrib.sceneid':2,'sceneid':2,'attrib.world_pos':{'x':218.,'y':109.},'world_pos':{'x':218.,'y':109.},
   'attrib.ride':-1,'attrib.hp':5000,'attrib.mp':5000,'impact_list':[],'cool_down_times':{}}})
  print('Seeded owned test15/test14; full original BSON backed up')
 elif a.mode=='restore':
  saved=json_util.loads(backup.read_text())
  for d in saved:col.replace_one({'_id':d['_id']},d)
  assert all(col.find_one({'_id':d['_id']})==d for d in saved)
  (LOG/'fixture-restore.json').write_text('{"full_bson_equal":true,"characters":2}')
  print('PASS full BSON equality for both test characters')
 else:
  d=docs[0];report={k:d.get(k)for k in ['relation','id_titles','titles']};report['title']=d['attrib'].get('title');report['game_setting']=d.get('setting',{}).get('2')
  (LOG/('fixture-'+a.mode+'.json')).write_text(json.dumps(report,ensure_ascii=False,indent=2))
  if a.mode=='verify1':
   assert report['title']['str']=='#1043',report['title']
   assert len(report['relation']['friends'])==1 and report['relation']['friends'][0]['group']==2
   assert report['game_setting']['data'] & 1
  if a.mode=='verify2':assert report['title']['str']=='' and len(report['relation']['friends'])==0
  print(json.dumps(report,ensure_ascii=False))
