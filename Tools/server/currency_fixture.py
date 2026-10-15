from pathlib import Path
import argparse,json,re
from bson import json_util
from cs3b_menpai import provision
from give_item import connected
LOG=Path('/mnt/c/TLBB/085/CY-Source/Build/Logs/2026-09-26-vothach')
p=argparse.ArgumentParser();p.add_argument('mode',choices=['seed','reset','verify','restore']);p.add_argument('--run',default='gui-01');a=p.parse_args()
assert not connected(),'Private client connected'
with provision().database() as c:
 col=c.tlbb.character;d=col.find_one({'attrib.guid':200016});assert d
 backup=LOG/'fixture-original.bson.json'
 if a.mode=='restore':
  saved=json_util.loads(backup.read_text());assert saved['_id']==d['_id'];col.replace_one({'_id':d['_id']},saved);assert col.find_one({'_id':d['_id']})==saved
  (LOG/'fixture-restore.json').write_text('{"full_bson_equal":true}');print('PASS exact full fixture restore');raise SystemExit
 if a.mode=='verify':
  s=(LOG/a.run/'WXClient.log').read_text(errors='replace');match=re.search(r'CYS-CURRENCY: PURCHASE item=(\d+) price=(\d+) before=(\d+) after=(\d+)',s);assert match
  item,cost,before,after=map(int,match.groups());assert before==230745 and after==before-cost and d['attrib']['money']==after
  rows=list(d['prop_bag_list'].values());assert len(rows)==1 and rows[0]['item_index']==item and rows[0].get('lay_count',1)==1
  x=d['attrib'];assert x['yuanbao']==345 and x['jiaozi']==0 and x['bind_yuanbao']==0 and x.get('zengdian',0)==0
  (LOG/'fixture-persistent.json').write_text(json.dumps({'valid':True,'item':item,'count':1,'cost':cost,'vo_thach':after,'yuanbao':345}));print('PASS exact purchase, one item, canonical wallets persisted');raise SystemExit
 if a.mode=='seed':assert not backup.exists();backup.write_text(json_util.dumps(d))
 else:saved=json_util.loads(backup.read_text());col.replace_one({'_id':d['_id']},saved)
 fields={'prop_bag_list':{},'attrib.money':230000,'attrib.jiaozi':745,'attrib.yuanbao':300,'attrib.bind_yuanbao':45,'attrib.zengdian':0,
  'attrib.level':100,'attrib.sceneid':2,'sceneid':2,'attrib.world_pos':{'x':271.0,'y':135.0},'world_pos':{'x':271.0,'y':135.0},'attrib.ride':-1,'impact_list':[],'cool_down_times':{}}
 col.update_one({'_id':d['_id']},{'$set':fields});print('Seeded owned test15; legacy wallets deliberately test on-load conversion')
