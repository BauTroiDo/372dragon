"""Owned test15 only: retain a complete BSON snapshot before power-system checks."""
from pathlib import Path
import argparse,copy,json
from bson import json_util
from cs3b_menpai import provision
from give_item import connected,scan
LOG=Path('/mnt/c/TLBB/085/CY-Source/Build/Logs/2026-09-24-power')
p=argparse.ArgumentParser();p.add_argument('mode',choices=['inspect','seed','reset','restore']);a=p.parse_args()
assert not connected(),'Close private clients first'
with provision().database() as c:
    col=c.tlbb.character;d=col.find_one({'attrib.guid':200016});assert d
    backup=LOG/'test15-original.json'
    if a.mode=='inspect':
        _,samples=scan(col)
        print('attributes', {k:d['attrib'].get(k) for k in ['level','gongli','money','money_jz','exp']})
        print('samples', {k:v.get('item_index') for k,v in samples.items()})
        print('soul sample',json_util.dumps(samples.get(7)))
        print('equipment',json_util.dumps(d.get('equip_list',{}).get('19')))
        print('ShenDing', d.get('cys_shending'));print('cultivation',d.get('xiulian_list'))
        for k,v in d.get('prop_bag_list',{}).items():
            if v.get('item_index') in [70600000,38002530,38002515,38002532,38000945]:print('item',k,v.get('item_index'),v.get('count'),v.get('pet_equip'))
        raise SystemExit
    if a.mode=='restore':
        old=json_util.loads(backup.read_text());assert old['_id']==d['_id'];col.replace_one({'_id':d['_id']},old)
        assert col.find_one({'_id':d['_id']})==old;print('PASS exact BSON restore test15');raise SystemExit
    if a.mode=='seed':
        assert not backup.exists(),'Do not overwrite an earlier fixture snapshot'
        backup.write_text(json_util.dumps(d),encoding='utf8')
    else:
        old=json_util.loads(backup.read_text());assert old['_id']==d['_id']
    top,samples=scan(col);bag={}
    # Class7 is created by the actual GM receive-item path in the live probe.
    for slot,(id,count) in enumerate([(38002530,30),(38002515,4),(38002532,4),(38000945,2)],1):
        row=copy.deepcopy(samples[3]);row.update(item_index=id,count=count,lay_count=count,status=2)
        row['guid']={'world':254,'server':254,'mask':0,'series':top+100+slot};row['unknow_20'][0]=count;bag[str(slot)]=row
    wh=copy.deepcopy(d['equip_list']['19']);wh.update(wh_level=90,wh_grow_rate=600,wh_hecheng_level=3,wh_ex_attr_number=1)
    for slot in (5,6):
        piece=copy.deepcopy(wh);piece.update(wh_hecheng_level=1,count=1,lay_count=1)
        piece['guid']={'world':254,'server':254,'mask':0,'series':top+100+slot};bag[str(slot)]=piece
    fields={'attrib.level':100,'attrib.exp':1000000,'attrib.gongli':10000,'attrib.money':10000000,'attrib.menpai':3,
        'attrib.hp':5000,'attrib.mp':3000,'attrib.sceneid':12,'sceneid':12,'attrib.world_pos':{'x':77.0,'y':89.0},
        'equip_list.19':wh,'prop_bag_list':bag,'xiulian_list':[{'level':9 if i==0 else 0,'upper_limit':10} for i in range(15)],
        'cys_shending':{'dust':5000,'con':0,'attack':0,'con_gold':0,'attack_gold':0,'ice':0,'fire':0,'light':0,'poison':0}}
    col.update_one({'_id':d['_id']},{'$set':fields});print('Prepared test15; original complete BSON preserved')
