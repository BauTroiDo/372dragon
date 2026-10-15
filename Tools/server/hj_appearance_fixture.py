"""Offline private test15 fixture; retain and restore the complete original BSON."""
from pathlib import Path
import argparse,json
from bson import json_util
from cs3b_menpai import provision
from give_item import connected
LOG=Path('/mnt/c/TLBB/085/CY-Source/Build/Logs/2026-09-25-hj-import')
p=argparse.ArgumentParser();p.add_argument('mode',choices=['seed','sex','position','verify','restore']);p.add_argument('--sex',type=int,choices=[0,1],default=1);a=p.parse_args()
assert not connected(),'A private client is connected'
server=provision()
for spec in reversed(server.role_specs()):
 if spec['name'] in ('Mongo','MQTT'):continue
 owned=server.owned_processes(spec);assert len(owned)<=1
 if owned:server.stop_owned(spec,owned[0])
with server.database() as c:
 col=c.tlbb.character;d=col.find_one({'attrib.guid':200016});assert d
 backup=LOG/'test15-original.json'
 if a.mode=='restore':
  old=json_util.loads(backup.read_text(encoding='utf8'));assert d['_id']==old['_id'];col.replace_one({'_id':d['_id']},old)
  assert col.find_one({'_id':d['_id']})==old
  (LOG/'restore-result.json').write_text('{"full_bson_equal":true}',encoding='utf8');print('PASS complete original BSON restored');raise SystemExit
 if a.mode=='verify':
  catalog=json.loads(Path('/mnt/c/TLBB/085/CY-Source/Registry/hj-appearance-catalog.json').read_text(encoding='utf8'))
  fashion=d['equip_list']['16']['item_index'] if '16' in d.get('equip_list',{}) else None
  # Persist the finite cosmetic state only; no credentials or unrelated account data.
  result={'attrib':{k:v for k,v in d['attrib'].items() if k.startswith('exterior_') or k in ('ride','face_style','hair_style','portrait_id','model')},
          'exterior':d.get('exterior',{}),'equip_items':{k:v['item_index'] for k,v in d.get('equip_list',{}).items()}}
  assert any(x>=10129000 and x<10130000 for x in result['equip_items'].values()),result['equip_items']
  assert result['attrib']['ride']>=2000
  fields={2:'faces',3:'hairs',4:'heads',5:'headinfo',6:'backinfo',7:'weapon_visuals',9:'rides'}
  for cat,field in fields.items():
   row=catalog['families'][str(cat)][-1]['variants'][-1]
   assert any(x['id']==row['native'] for x in d['exterior'].get(field,[])),(cat,field,row['native'])
  for cat,field in [(2,'exterior_face_style_index'),(3,'exterior_hair_style_index'),(4,'exterior_portrait_index')]:
   row=catalog['families'][str(cat)][-1]['variants'][-1]
   assert d['attrib'][field]==row['native'],field
  (LOG/'persistent-result.json').write_text(json.dumps(result,ensure_ascii=False,indent=1),encoding='utf8');print('PASS HJ outfit and mount persisted');raise SystemExit
 if a.mode=='seed':
  assert not backup.exists();backup.write_text(json_util.dumps(d),encoding='utf8')
  col.update_one({'_id':d['_id']},{'$set':{'attrib.level':100,'attrib.sceneid':12,'sceneid':12,'attrib.world_pos':{'x':77.0,'y':89.0},
   'attrib.ride':-1,'attrib.hp':5000,'attrib.mp':3000,'impact_list':[]}})
 else:assert backup.exists()
 updates={} if a.mode=='position' else {'attrib.model':a.sex}
 if a.mode in ('sex','position'):
  updates.update({'attrib.sceneid':12,'sceneid':12,'attrib.world_pos':{'x':77.0,'y':89.0}})
 if a.mode=='sex':
  # Sex, face, hair and portrait must stay consistent at character selection.
  # Resolve the same owned HJ entry's opposite-sex resources, not its old IDs.
  import struct
  # Read the two integer columns directly; the resource importer depends on
  # Windows archive helpers and is intentionally not imported into WSL.
  raw=Path('/mnt/c/TLBB/085/CY-Source/Assets/Imported/HJ20260910/ConfigFolder/CharHead.txt').read_bytes()
  assert raw[:4]==b'\x00\xcc\xbb\xdd'
  nf,nr,pool=struct.unpack_from('<III',raw,4);assert nf>=9
  assert struct.unpack_from('<I',raw,16+8*4)[0]==0
  portraits={struct.unpack_from('<i',raw,16+nf*4+i*nf*4)[0]:
             struct.unpack_from('<i',raw,16+nf*4+i*nf*4+8*4)[0] for i in range(nr)}
  catalog=json.loads(Path('/mnt/c/TLBB/085/CY-Source/Registry/hj-appearance-catalog.json').read_text(encoding='utf8'))
  for cat,field,target in [(2,'exterior_face_style_index','face_style'),(3,'exterior_hair_style_index','hair_style'),(4,'exterior_portrait_index','portrait_id')]:
   native=d['attrib'].get(field)
   row=next(x for x in catalog['categories'][str(cat)] if x['native']==native)
   value=row['visual'][a.sex]
   if cat==4:value=portraits[value]
   updates['attrib.'+target]=value
 col.update_one({'_id':d['_id']},{'$set':updates})
 print('Prepared private test15 sex',a.sex,'with full BSON backup; private gameplay services stopped')
