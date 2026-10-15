"""Full test15 BSON backup/restore; functional soul materials and persistence assertions."""
from pathlib import Path
import argparse,copy
from bson import json_util
from cs3b_menpai import provision
from give_item import connected,scan
LOG=Path('/mnt/c/TLBB/085/CY-Source/Build/Logs/2026-09-25-wuhun-appearance')
p=argparse.ArgumentParser();p.add_argument('mode',choices=['seed','reset','verify','restore']);a=p.parse_args()
assert not connected(),'Private client connected'
with provision().database() as c:
 col=c.tlbb.character;d=col.find_one({'attrib.guid':200016});assert d
 backup=LOG/'test15-original.json'
 if a.mode=='restore':
  old=json_util.loads(backup.read_text(encoding='utf8'));assert old['_id']==d['_id'];col.replace_one({'_id':d['_id']},old)
  assert col.find_one({'_id':d['_id']})==old
  (LOG/'restore-result.json').write_text('{"full_bson_equal":true}',encoding='utf8')
  print('PASS full BSON restored exactly');raise SystemExit
 if a.mode=='verify':
  u=d['huanhun'];assert u['1']['level']==1 and u['1']['grade']==1 and u['3']['level']==1
  assert d['attrib']['huanhun_qian_index']==1 and d['attrib']['huanhun_kun_index']==3 and d['attrib']['wuhun_yy_flag']==1
  assert d['attrib']['wuhun_show_flag']==1
  total=d['attrib']['money']+d['attrib'].get('jiaozi',0);assert total==8960000,total
  counts={r['item_index']:r.get('lay_count',r.get('count')) for r in d['prop_bag_list'].values()}
  for key,value in {20800001:50,20800005:50,20800013:98}.items():assert counts[key]==value,(key,counts[key],value)
  assert d['equip_list']['19']['item_index']==10156001
  assert not any(r['item_index']==10156001 for r in d['prop_bag_list'].values())
  (LOG/'persistent-result.json').write_text(json_util.dumps({'huanhun':u,'money_total':total,'materials':counts}),encoding='utf8')
  print('PASS persisted Càn/Khôn, YY, show, equipment, gold and exact material costs');raise SystemExit
 if a.mode=='seed':assert not backup.exists();backup.write_text(json_util.dumps(d),encoding='utf8')
 else:
  d=json_util.loads(backup.read_text(encoding='utf8'));col.replace_one({'_id':d['_id']},d)
 top,samples=scan(col);bag={}
 for n,item in enumerate([20800001,20800005,20800013],1):
  row=copy.deepcopy(samples[2]);row.update(item_index=item,count=100,lay_count=100,status=3)
  row['guid']={'world':254,'server':254,'mask':0,'series':top+n};row['unknow_19'][0]=100
  # Native material tab occupies positions 100..199 (DB keys 101..200).
  bag[str(100+n)]=row
 col.update_one({'_id':d['_id']},{'$set':{'attrib.level':100,'attrib.money':10000000,'attrib.jiaozi':0,'attrib.sceneid':12,'sceneid':12,
 'attrib.world_pos':{'x':77.0,'y':89.0},'attrib.ride':-1,'attrib.hp':5000,'attrib.mp':3000,'impact_list':[],'prop_bag_list':bag,'huanhun':{},
 'attrib.huanhun_qian_index':0,'attrib.huanhun_kun_index':0,'attrib.wuhun_yy_flag':0,'attrib.wuhun_show_flag':1}})
 print('Prepared private test15; complete original BSON retained')
