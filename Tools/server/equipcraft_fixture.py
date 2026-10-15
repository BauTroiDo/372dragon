"""Private test15 only. Full original BSON retained and restored exactly."""
from pathlib import Path
import argparse,copy
from bson import json_util
from cs3b_menpai import provision
from give_item import connected,scan
LOG=Path('/mnt/c/TLBB/085/CY-Source/Build/Logs/2026-09-24-equipcraft')
p=argparse.ArgumentParser();p.add_argument('mode',choices=['seed','refresh','inspect','verify','restore']);a=p.parse_args()
assert not connected(),'Private client connected'
with provision().database() as c:
 col=c.tlbb.character;d=col.find_one({'attrib.guid':200016});assert d
 backup=LOG/'test15-original.json'
 if a.mode=='restore':
  old=json_util.loads(backup.read_text(encoding='utf8'));assert old['_id']==d['_id'];col.replace_one({'_id':d['_id']},old)
  assert col.find_one({'_id':d['_id']})==old;print('PASS full BSON restored exactly');raise SystemExit
 if a.mode in ['inspect','verify']:
  bag=d['prop_bag_list'];rows=[r for r in bag.values() if isinstance(r,dict)]
  print({'level':d['attrib']['level'],'money':d['attrib'].get('money'),'jiaozi':d['attrib'].get('jiaozi'),'items':[{k:v for k,v in r.items() if k in ['item_index','lay_count','creator','diaowen_id','diaowen_material_count','quality']} for r in rows]})
  if a.mode=='verify':
   assert bag['1']['creator']=='ThoRen&W01' and bag['1']['diaowen_id']==0 and bag['2']['diaowen_id']==0
   def count(id):return sum(r.get('lay_count',r.get('count',1)) for r in rows if r['item_index']==id)
   for id,n in [(20800031,245),(30110271,2),(30110272,1),(30503149,1),(20310166,248),(30503150,1),(30120028,0),(20310169,0),(20502009,0)]:assert count(id)==n,(id,count(id),n)
   assert d['attrib']['money']+d['attrib'].get('jiaozi',0)==9700000
   print('PASS persistent costs, nine material totals and single outputs')
  raise SystemExit
 if a.mode=='seed':assert not backup.exists();backup.write_text(json_util.dumps(d),encoding='utf8')
 else:assert backup.exists()
 top,samples=scan(col)
 def serials(v):
  if isinstance(v,dict):
   if isinstance(v.get('guid'),dict):yield v['guid'].get('series',0)
   for x in v.values():yield from serials(x)
  elif isinstance(v,list):
   for x in v:yield from serials(x)
 top=max(top,max((max(serials(x),default=0) for x in col.find({})),default=0));bag={}
 for n,(id,count) in enumerate([(10413017,1),(10413017,1),(20800031,250),(30110271,2),(30503149,2),(20310166,250),(30503150,2),(30120028,1),(20310169,20),(20502009,20)],1):
  cls=id//10000000;row=copy.deepcopy(samples[cls]);row.update(item_index=id,count=count,lay_count=count,status=3)
  row['guid']={'world':254,'server':254,'mask':0,'series':top+n}
  if cls==1:
   row.update(equip_type=0,quality=6,status=19,creator='ThoRen',enhancement_level=3,qualifications=[0]*6,dur=100,max_dur=125,slot_count=0,gem_count=0,list_2=[0]*4,
    diaowen_id=0,diaowen_material_count=0,dw_advance_level=0,dw_rankexp=0,dw_featuresid=0,reshuffle_count=0,qihedu=0,
    attr_types=[0,44],attr_type=(1<<0)|(1<<44),attr_count=2,attr_values=[1000,100])
  if cls==2:row['unknow_19'][0]=count
  if cls==3:row['unknow_20'][0]=count
  bag[str(n)]=row
 fields={'attrib.level':100,'attrib.money':10000000,'attrib.jiaozi':0,'attrib.sceneid':12,'sceneid':12,'attrib.world_pos':{'x':77.0,'y':89.0},'attrib.hp':5000,'attrib.mp':3000,'prop_bag_list':bag}
 col.update_one({'_id':d['_id']},{'$set':fields});print('Prepared level100, two armors, eight native crafting materials; original BSON preserved')
