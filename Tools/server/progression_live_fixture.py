"""Owned test15 fixture; complete BSON backup, exact restoration after live checks."""
from pathlib import Path
import argparse,copy
from bson import json_util
from cs3b_menpai import provision
from give_item import connected,scan
R=Path('/home/ubuntu/cys-test-20260913');LOG=Path('/mnt/c/TLBB/085/CY-Source/Build/Logs/2026-09-24-progression')
p=argparse.ArgumentParser();p.add_argument('mode',choices=['cap','battle','wide-exp','restore','inspect']);a=p.parse_args()
assert not connected()
with provision().database() as c:
    col=c.tlbb.character;d=col.find_one({'attrib.guid':200016});assert d
    backup=LOG/'test15-original.json'
    if not backup.exists():backup.write_text(json_util.dumps(d),encoding='utf8')
    if a.mode=='restore':
        old=json_util.loads(backup.read_text());assert old['_id']==d['_id'];col.replace_one({'_id':d['_id']},old)
        assert col.find_one({'_id':d['_id']})==old;print('PASS exact BSON restore test15');raise SystemExit
    if a.mode=='inspect':
        print({k:d['attrib'].get(k) for k in ['level','exp','hp','mp','menpai','sceneid']})
        print('assist',d.get('cys_assist'));raise SystemExit
    fields={'attrib.hp':5000,'attrib.mp':3000,'attrib.menpai':3,
        'xinfa_list':[{'m_nXinFaID':i,'m_nXinFaLevel':100} for i in range(19,25)]}
    if a.mode=='cap':
        exp={int(row.split()[0]):int(row.split()[1]) for row in (R/'configs/PlayerExpLevel.txt').read_text().splitlines()[2:] if row.strip()}
        fields.update({'attrib.level':199,'attrib.exp':exp[199]*3,'attrib.sceneid':12,'sceneid':12,'attrib.world_pos':{'x':77.0,'y':89.0}})
    elif a.mode=='wide-exp':
        fields.update({'attrib.level':149,'attrib.exp':3000000000,'attrib.sceneid':12,'sceneid':12,'attrib.world_pos':{'x':77.0,'y':89.0}})
    else:
        _,samples=scan(col);potion=copy.deepcopy(samples[3]);potion.update(item_index=30001001,count=3,lay_count=3,status=2)
        potion['guid']={'world':254,'server':254,'mask':0,'series':2409202698};potion['unknow_20'][0]=3
        cfg=copy.deepcopy(d.get('cys_assist'));assert cfg and len(cfg)==11
        cfg[8]=[0,0,0];cfg[1]=[0,0,0];cfg[2]=[1,1,1]
        fields.update({'attrib.level':81,'attrib.exp':1000,'attrib.menpai':3,'attrib.sceneid':6,'sceneid':6,'attrib.world_pos':{'x':40.0,'y':150.0},
            'skill_list':[0,1,2,3,21,22,34,35,43,371,374],
            'xinfa_list':[{'m_nXinFaID':i,'m_nXinFaLevel':60} for i in range(19,25)],
            'attrib.hp':50,'prop_bag_list':{'99':potion},'cys_assist':cfg})
    col.update_one({'_id':d['_id']},{'$set':fields});print('Prepared test15',a.mode,'complete original preserved')
