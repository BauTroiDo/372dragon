"""Private test15 mount-flight fixture; full BSON backup and exact restoration."""
from pathlib import Path
import argparse
from bson import json_util
from cs3b_menpai import provision
from give_item import connected
LOG=Path('/mnt/c/TLBB/085/CY-Source/Build/Logs/2026-09-24-mount-flight')
p=argparse.ArgumentParser();p.add_argument('mode',choices=['seed','refresh','inspect','restore']);p.add_argument('--scene',type=int,default=12);p.add_argument('--ride',type=int,default=96);p.add_argument('--log',type=Path,default=LOG);a=p.parse_args()
LOG=a.log.resolve();assert LOG.is_relative_to(Path('/mnt/c/TLBB/085/CY-Source/Build/Logs'));LOG.mkdir(parents=True,exist_ok=True)
assert not connected(),'Private clients connected'
with provision().database() as c:
 col=c.tlbb.character;d=col.find_one({'attrib.guid':200016});assert d
 backup=LOG/'test15-original.json'
 if a.mode=='restore':
  old=json_util.loads(backup.read_text(encoding='utf8'));assert old['_id']==d['_id'];col.replace_one({'_id':d['_id']},old)
  assert col.find_one({'_id':d['_id']})==old;print('PASS full BSON restored exactly');raise SystemExit
 if a.mode=='inspect':
  print({k:d['attrib'].get(k) for k in ['guid','level','sceneid','world_pos','ride']});print('rides',d.get('exterior',{}).get('rides'));raise SystemExit
 if a.mode=='seed':assert not backup.exists();backup.write_text(json_util.dumps(d),encoding='utf8')
 else:assert backup.exists()
 rows=Path('/home/ubuntu/cys-test-20260913/configs/Exterior_Ride.txt').read_bytes().decode('gbk').splitlines()
 row=next(r.split('\t') for r in rows[2:] if r.split('\t')[0]==str(a.ride));assert int(row[10]) in [94,21,271]
 mounts=[{'id':i,'term':-1,'terminable':0} for i in sorted({96,1,a.ride})]
 fields={'attrib.level':100,'attrib.ride':a.ride,'attrib.sceneid':a.scene,'sceneid':a.scene,'attrib.world_pos':{'x':77.0,'y':89.0},'attrib.hp':5000,'attrib.mp':3000,'exterior.rides':mounts,'impact_list':[]}
 col.update_one({'_id':d['_id']},{'$set':fields});print('Prepared test15 mount',a.ride,'model',row[10],'scene',a.scene,'original BSON preserved')
