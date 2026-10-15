"""One owned offline test15 character; fresh full BSON backup for this batch."""
from pathlib import Path
import argparse,json
from bson import json_util
from cs3b_menpai import provision
from give_item import connected
LOG=Path('/mnt/c/TLBB/085/CY-Source/Build/Logs/2026-09-29-cangjingge')
def main():
 p=argparse.ArgumentParser();p.add_argument('mode',choices=['seed','restore','verify']);a=p.parse_args()
 assert not connected(),'Private client connected'
 rt=provision();game=next(s for s in rt.role_specs() if s['name']=='Game')
 if a.mode!='verify':assert not rt.owned_processes(game),'Stop private Game before fixture writes'
 with rt.database() as client:
  col=client.tlbb.character;doc=col.find_one({'attrib.guid':200016});assert doc
  b=LOG/'test15-original.json'
  if a.mode=='seed':
   if b.exists():assert doc==json_util.loads(b.read_text()),'Restore prior fixture before reseed'
   else:b.write_text(json_util.dumps(doc),encoding='utf8')
   col.update_one({'_id':doc['_id']},{'$set':{'sceneid':18,'attrib.sceneid':18,'attrib.world_pos':{'x':264.0,'y':258.0},'attrib.hp':5000,'attrib.mp':3000}})
   print('Seeded test15 near event entry; complete fresh BSON retained');return
  old=json_util.loads(b.read_text())
  if a.mode=='restore':col.replace_one({'_id':old['_id']},old)
  assert col.find_one({'_id':old['_id']})==old
  (LOG/(a.mode+'.json')).write_text(json.dumps(dict(full_bson_equal=True,guid=200016)))
  print('PASS complete original BSON',a.mode)
if __name__=='__main__':main()
