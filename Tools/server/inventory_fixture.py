"""Reversible inventory fixture; only private test15/GUID200016 while offline."""
import argparse
import copy
from pathlib import Path
from bson import json_util
from cs3b_menpai import provision
from give_item import connected, scan

p=argparse.ArgumentParser(description=__doc__)
p.add_argument('mode',choices=['seed','restore','verify','inspect'])
p.add_argument('--backup',type=Path,required=True)
p.add_argument('--full',action='store_true',help='Fill all 20 base slots for a rejected-purchase control')
a=p.parse_args()
assert not connected(), 'private client still connected'
fields=['prop_bag_list','material_bag_list','equip_list','mission_data','attrib','skill_list','impact_list']
with provision().database() as client:
    col=client.tlbb.character
    d=col.find_one({'attrib.guid':200016});assert d
    if a.mode=='seed':
        state={k:copy.deepcopy(d.get(k)) for k in fields}
        assert not a.backup.exists(), 'use a fresh backup after restoring the previous fixture'
        a.backup.parent.mkdir(parents=True,exist_ok=True)
        a.backup.write_text(json_util.dumps(state),encoding='utf-8')
        _,samples=scan(col)
        if 2 not in samples:
            samples[2]=copy.deepcopy(samples[3]);samples[2].pop('unknow_20',None);samples[2]['unknow_19']=[0]*32
        equipment=copy.deepcopy(d['equip_list'])
        model=copy.deepcopy(equipment['19'])
        equipment.pop('10',None);equipment.pop('11',None)
        # Separate GUID namespace from the running generator; every fixture row
        # is removed by restore. Never advance/rewind the real GUID counter.
        bag={}
        def put(pos,id,count=1):
            row=copy.deepcopy(model if id//10000000==1 else samples[id//10000000])
            row.update(item_index=id,count=count,lay_count=count,status=2)
            row['guid']={'world':254,'server':254,'mask':0,'series':20001600+pos}
            if id//10000000==1:row.update(equip_type=0,attr_count=0,attr_type=0,attr_types=[],attr_values=[],visual=0)
            if id//10000000==3:row['unknow_20'][0]=count
            if id//10000000==2:row['unknow_19'][0]=count
            bag[str(pos+1)]=row
        put(0,10141025);put(1,10141035);put(2,10141021)
        put(18,30602002,9);put(19,30602002,7)
        put(100,20310181,3);put(119,20310181,4)
        if a.full:
            for pos in range(20):put(pos,10141021)
            put(19,30602002,9)
        col.update_one({'_id':d['_id']},{'$set':{'prop_bag_list':bag,'equip_list':equipment}})
        print('seeded test15: FULL base20, potions9, material7' if a.full else
              'seeded test15: base20, material20, bags +20/+20/+4, potions16, material7')
    elif a.mode=='restore':
        state=json_util.loads(a.backup.read_text(encoding='utf-8'));assert state['attrib']['guid']==200016
        col.update_one({'_id':d['_id']},{'$set':state})
        after=col.find_one({'_id':d['_id']});assert all(after.get(k)==state[k] for k in fields)
        print('restored and verified test15 inventory/equipment/missions/attributes/skills/impacts')
    elif a.mode=='verify':
        state=json_util.loads(a.backup.read_text(encoding='utf-8'));assert state['attrib']['guid']==200016
        assert all(d.get(k)==state[k] for k in fields), 'test15 differs from the original backup'
        print('PASS read-only comparison: all 7 test15 fields equal original backup')
    else:
        rows=lambda value:{k:{f:v.get(f) for f in ['item_index','guid','lay_count','count']} for k,v in value.items()}
        print(json_util.dumps({'bag':rows(d['prop_bag_list']),'bags_equipped':{k:v.get('item_index') for k,v in d['equip_list'].items() if k in ('10','11')},
                              'money':{k:v for k,v in d['attrib'].items() if k in ('money','jiaozi','yuanbao','bind_yuanbao')}},indent=2))
