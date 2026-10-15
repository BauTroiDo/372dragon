"""Fresh full backup of the owned test15; seed/inspect/restore private CY only."""
from pathlib import Path
import argparse,copy,json
from bson import json_util
from cs3b_menpai import provision
from give_item import connected,scan
LOG=Path('/mnt/c/TLBB/085/CY-Source/Build/Logs/2026-09-26-quest-craft-combat')
p=argparse.ArgumentParser();p.add_argument('mode',choices=['seed','reset','inspect','verify','restore']);a=p.parse_args()
assert not connected(),'Private client connected'
with provision().database() as c:
 col=c.tlbb.character;d=col.find_one({'attrib.guid':200016});assert d
 backup=LOG/'fixture-original.bson.json'
 if a.mode=='verify':
  bag=d['prop_bag_list'];counts={};guids=[]
  for item in bag.values():
   id=item['item_index'];counts[id]=counts.get(id,0)+item.get('lay_count',item.get('count',1));guids.append(tuple(sorted(item['guid'].items())))
  expected={30506001:1,10200001:1,10200011:1,30101001:10,10101000:1,20103001:25,20103061:10,20103097:12,20308001:1}
  assert counts==expected,(counts,expected)
  assert len(guids)==len(set(guids))
  identified=next(i for i in bag.values()if i['item_index']==10200001)
  crafted=next(i for i in bag.values()if i['item_index']==10200011)
  assert identified['status']&2 and not crafted['status']&2
  assert next(x['m_nXinFaLevel']for x in d['xinfa_list']if x['m_nXinFaID']==1)==2
  # Fixture costs: XinFa 1 -> 2 consumes 27 EXP + 10; quest 1401 grants 700 EXP + 1.
  assert d['attrib']['exp']==1000673,d['attrib']['exp']
  assert d['attrib']['money']+d['attrib']['money_jz']==999991,d['attrib']['money']
  assert d['attrib']['vigor']==480
  result={'passed':True,'item_counts':counts,'unique_guids':len(guids),'identified_status':identified['status'],'crafted_status':crafted['status'],'xinfa':2,'exp':d['attrib']['exp'],'money_total':999991,'vigor':480}
  (LOG/'fixture-verified.json').write_text(json.dumps(result,indent=2));print(json.dumps(result));raise SystemExit
 if a.mode=='restore':
  saved=json_util.loads(backup.read_text());assert saved['_id']==d['_id'];col.replace_one({'_id':d['_id']},saved)
  assert col.find_one({'_id':d['_id']})==saved
  (LOG/'fixture-restore.json').write_text('{"full_bson_equal":true}');print('PASS exact full BSON restore');raise SystemExit
 if a.mode=='inspect':
  report={'attrib':{k:d['attrib'].get(k)for k in ['level','exp','menpai','vigor','stamina','money','money_jz']},'xinfa':d.get('xinfa_list'),
   'abilities':d.get('ability_list'),'items':{k:{n:v.get(n)for n in ['item_index','count','lay_count','status','guid']}for k,v in d.get('prop_bag_list',{}).items()}}
  (LOG/'fixture-after.json').write_text(json.dumps(report,ensure_ascii=False,indent=2));print(json.dumps(report,ensure_ascii=False));raise SystemExit
 # A prior successful restore must not authorize publishing a newly seeded run.
 (LOG/'fixture-restore.json').unlink(missing_ok=True)
 sample_file=LOG/'crafted-equipment-sample.json'
 if not sample_file.exists():
  sample=next((v for v in d.get('prop_bag_list',{}).values() if v.get('item_index')==10200011),None)
  if sample:sample_file.write_text(json_util.dumps(sample))
 if a.mode=='seed':assert not backup.exists();backup.write_text(json_util.dumps(d))
 else:
  saved=json_util.loads(backup.read_text());assert saved['_id']==d['_id'];col.replace_one({'_id':d['_id']},saved);d=saved
 top,samples=scan(col);bag={}
 for pos,id,count in [(0,30506001,2),(100,20103001,50),(101,20103061,20),(102,20103097,24),(103,20308001,2)]:
  family=id//10000000;item=copy.deepcopy(samples[family]);top+=1
  item.update(item_index=id,count=count,lay_count=count,status=0,guid={'world':254,'server':254,'mask':0,'series':top})
  item['unknow_19'if family==2 else'unknow_20'][0]=count;bag[str(pos+1)]=item
 # Separate unidentified weapon, in addition to the authored crafted output.
 equipment=json_util.loads(sample_file.read_text());top+=1
 equipment.update(item_index=10200001,status=0,guid={'world':254,'server':254,'mask':0,'series':top})
 bag['2']=equipment
 fields={'attrib.level':60,'attrib.exp':1000000,'attrib.menpai':0,'attrib.sceneid':2,'sceneid':2,
  'attrib.world_pos':{'x':218.0,'y':109.0},'world_pos':{'x':218.0,'y':109.0},'attrib.ride':-1,
  'attrib.vigor':500,'attrib.stamina':500,'attrib.hp':5000,'attrib.mp':5000,'attrib.money':1000000,'attrib.money_jz':0,
  'impact_list':[],'cool_down_times':{},'ability_list':[{'id':4,'exp':0,'level':1}],
  'prescriptions':{'1':2},'xinfa_list':[{'m_nXinFaID':i,'m_nXinFaLevel':1}for i in range(1,7)],'prop_bag_list':bag}
 col.update_one({'_id':d['_id']},{'$set':fields});print('Seeded test15 crafting/xinfa; fresh full BSON preserved')
