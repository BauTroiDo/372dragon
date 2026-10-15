"""Idempotent, guarded conversion in the CY private database only."""
from pathlib import Path
import argparse,json,datetime
from bson import json_util
from cs3b_menpai import provision
from give_item import connected
LOG=Path('/mnt/c/TLBB/085/CY-Source/Build/Logs/2026-09-26-vothach')
p=argparse.ArgumentParser();p.add_argument('mode',choices=['check','apply']);a=p.parse_args()
assert not connected(),'Private client connected'
with provision().database() as c:
 col=c.tlbb.character;docs=list(col.find({}));plans=[]
 for d in docs:
  x=d['attrib'];m=x.get('money',0)+x.get('jiaozi',0);y=x.get('yuanbao',0)+x.get('bind_yuanbao',0)+x.get('zengdian',0)
  assert 0<=m<=2147483647 and 0<=y<=2147483647
  plans.append((d,{'attrib.money':m,'attrib.jiaozi':0,'attrib.yuanbao':y,'attrib.bind_yuanbao':0,'attrib.zengdian':0}))
 if a.mode=='apply':
  backup=LOG/'currency-before.bson.json'
  if not backup.exists():backup.write_text(json_util.dumps(docs))
  for d,fields in plans:
   query={'_id':d['_id']}
   for k in fields:
    key=k.split('.')[1];query[k]=d['attrib'].get(key,{'$exists':False})
   result=col.update_one(query,{'$set':fields});assert result.matched_count==1,'Concurrent wallet change'
   after=col.find_one({'_id':d['_id']})
   for k,v in fields.items():assert after['attrib'][k.split('.')[1]]==v
   expected=json_util.loads(json_util.dumps(d));expected['attrib'].update({k.split('.')[1]:v for k,v in fields.items()})
   assert after==expected,'Non-wallet data changed'
  (LOG/'migration-result.json').write_text(json.dumps({'characters':len(plans),'conserved':True,'non_wallet_unchanged':True,'backup':str(backup),'at':datetime.datetime.now().isoformat()}))
 print('PASS',a.mode,len(plans),'characters; exact sum, range safe, no non-wallet changes')
