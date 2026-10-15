"""Whole-character reversible fixture; private test15 only, offline."""
from pathlib import Path
import argparse,copy
from bson import json_util
from cs3b_menpai import provision
from give_item import connected,scan
p=argparse.ArgumentParser(description=__doc__)
p.add_argument('mode',choices=['seed','items','jue','verify-bars','verify-items','restore']);p.add_argument('--backup',type=Path,required=True)
a=p.parse_args();assert not connected(),'private clients still connected'
with provision().database() as c:
 col=c.tlbb.character;d=col.find_one({'attrib.guid':200016});assert d
 if a.mode in ('seed','items'):
  if a.mode=='seed':
   assert not a.backup.exists();a.backup.parent.mkdir(parents=True,exist_ok=True)
   a.backup.write_text(json_util.dumps(d),encoding='utf8')
  else:assert a.backup.exists()
  _,samples=scan(col);bag={}
  for pos,count in [(18,2),(19,1)]:
   row=copy.deepcopy(samples[3]);row.update(item_index=30001001,count=count,lay_count=count,status=2)
   row['guid']={'world':254,'server':254,'mask':0,'series':20001600+pos};row['unknow_20'][0]=count
   bag[str(pos+1)]=row
  col.update_one({'_id':d['_id']},{'$set':{'attrib.menpai':3,'attrib.level':81,
   'attrib.sceneid':12,'attrib.world_pos':{'x':77.0,'y':89.0},'attrib.hp':50,'attrib.mp':1000,
   'skill_list':[0,1,2,3,21,22,34,35,43,374],
   'xinfa_list':[{'m_nXinFaID':i,'m_nXinFaLevel':60} for i in range(19,25)],
   'sceneid':12,'prop_bag_list':bag,'setting':{}}})
  print('Seeded owned test15, Wudang374, six xinfa60, three potions; complete restore point saved')
 elif a.mode=='jue':
  assert a.backup.exists()
  equip=copy.deepcopy(d['equip_list']);weapon=copy.deepcopy(equip['1'])
  weapon.update(item_index=10116001,visual=2214,dur=100,max_dur=100)
  equip['1']=weapon
  col.update_one({'_id':d['_id']},{'$set':{'attrib.menpai':14,'attrib.level':81,
   'attrib.sceneid':6,'attrib.world_pos':{'x':40.0,'y':150.0},'attrib.hp':5000,'attrib.mp':3000,
   'skill_list':[0,1,2,3,21,22,34,35,43,4515,4516,4517],
   'xinfa_list':[{'m_nXinFaID':i,'m_nXinFaLevel':60} for i in range(105,111)],
   'sceneid':6,'equip_list':equip,'setting':{}}})
  print('Seeded Jue4515, xinfa105..110, faction starter weapon10116001, combat field6')
 elif a.mode=='verify-bars':
  print('setting containers:',[k for k in d if 'setting' in k])
  settings=d.get('setting',{})
  for i in range(50):
   entry=settings.get(str(i+3));assert entry and entry.get('data')==35,(i,entry)
  print('PASS fifty saved slots are template35, settings3..52 (one-based Mongo keys)')
 elif a.mode=='verify-items':
  assert d['setting']['3']['data']==30001001,d['setting']['3']
  assert not [v for v in d['prop_bag_list'].values() if v.get('item_index')==30001001]
  print('PASS server consumed three and preserved shortcut item identity after exhaustion')
 else:
  saved=json_util.loads(a.backup.read_text(encoding='utf8'));assert saved['_id']==d['_id']
  col.replace_one({'_id':d['_id']},saved);assert col.find_one({'_id':d['_id']})==saved
  print('Restored complete test15 character; exact equality verified')
