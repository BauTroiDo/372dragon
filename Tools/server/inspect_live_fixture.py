"""Reversible two-player inspection fixture, private test13/test15 only."""
from pathlib import Path
import argparse,copy,json
from bson import json_util
from cs3b_menpai import provision
from give_item import connected
p=argparse.ArgumentParser(description=__doc__);p.add_argument('mode',choices=['seed','restore']);p.add_argument('--backup',type=Path,required=True);a=p.parse_args()
assert not connected(),'disconnect private clients first'
with provision().database() as client:
    col=client.tlbb.character
    docs=[col.find_one({'attrib.guid':g}) for g in [200014,200016]]
    assert all(docs)
    if a.mode=='seed':
        assert not a.backup.exists()
        a.backup.parent.mkdir(parents=True,exist_ok=True);a.backup.write_text(json_util.dumps(docs),encoding='utf8')
        peer,viewer=docs
        pos=copy.deepcopy(peer['attrib']['world_pos']);pos['x']+=1
        col.update_one({'_id':viewer['_id']},{'$set':{'attrib.sceneid':peer['attrib']['sceneid'],'attrib.world_pos':pos}})
        print(json.dumps({'scene':peer['attrib']['sceneid'],'peer':peer['attrib'].get('name'),'viewer':viewer['attrib'].get('name'),'saved':True},ensure_ascii=False))
    else:
        saved=json_util.loads(a.backup.read_text(encoding='utf8'))
        assert {d['attrib']['guid'] for d in saved}=={200014,200016}
        for d in saved:
            col.replace_one({'_id':d['_id']},d);assert col.find_one({'_id':d['_id']})==d
        print('Both complete original character records restored; exact equality verified')
