"""Reversible join-at-NPC fixture, restricted to private test15/GUID 200016."""
from pathlib import Path
import argparse, copy, json
from bson import json_util
from cs3b_menpai import provision
from give_item import connected

p=argparse.ArgumentParser(description=__doc__)
p.add_argument('mode',choices=['seed','seed-book','verify','restore'])
p.add_argument('--backup',type=Path,required=True)
a=p.parse_args()
assert not connected(), 'private clients must be disconnected'
with provision().database() as client:
    col=client.tlbb.character
    d=col.find_one({'attrib.guid':200016});assert d
    if a.mode in ('seed','seed-book'):
        assert not a.backup.exists(), 'restore point already exists'
        a.backup.parent.mkdir(parents=True,exist_ok=True)
        a.backup.write_text(json_util.dumps(d),encoding='utf8')
        if a.mode=='seed-book':
            # Include one temporary borrowed attack: it must remain usable but
            # must not overflow Murong's permanent xinfa page.
            col.update_one({'_id':d['_id']},{'$set':{'attrib.menpai':10,
                'skill_list':[0,1,2,3,21,22,34,35,43,760,788],'xinfa_list':{}}})
            print('seeded test15 Murong skill book with a borrowed attack; full restore point saved')
            raise SystemExit(0)
        attrib=copy.deepcopy(d['attrib'])
        attrib.update(menpai=9,reputation=12,level=15,sceneid=12,world_pos={'x':77.0,'y':89.0})
        col.update_one({'_id':d['_id']},{'$set':{'attrib':attrib,'prop_bag_list':{},'xinfa_list':[],
                        'skill_list':[0,1,2,3,21,22,34,35,43]}})
        print('seeded test15: level15, unjoined, Wudang teacher, empty prop bag; full restore point saved')
    elif a.mode=='verify':
        items=[v for v in d.get('prop_bag_list',{}).values() if isinstance(v,dict)]
        ids=[v.get('item_index') for v in items]
        assert d['attrib']['menpai']==3, 'NPC did not join Wudang'
        assert ids.count(10102001)==1 and ids.count(10124004)==1 and ids.count(30501001)==1,ids
        assert len(d['xinfa_list'])==6 and len(d['skill_list'])>9
        print(json.dumps(dict(passed=True,guid=200016,menpai=3,items=ids,xinfa_count=len(d['xinfa_list']),skill_count=len(d['skill_list']))))
    else:
        saved=json_util.loads(a.backup.read_text(encoding='utf8'))
        assert saved['_id']==d['_id'] and saved['attrib']['guid']==200016
        col.replace_one({'_id':d['_id']},saved)
        assert col.find_one({'_id':d['_id']})==saved
        print('restored complete original test15 record; exact equality verified')
