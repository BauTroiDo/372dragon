"""Owned bank fixture; shares this turn's immutable full test15 backup."""
import argparse,copy,json
from bson import json_util
from cs3b_menpai import provision
from give_item import connected
from hj05_fixture import LOG
p=argparse.ArgumentParser();p.add_argument('mode',choices=['seed','inspect']);a=p.parse_args()
assert not connected()
original=json_util.loads((LOG/'test15-original.json').read_text(encoding='utf8'))
with provision().database() as client:
    col=client.tlbb.character;d=col.find_one({'attrib.guid':200016});assert d['_id']==original['_id']
    if a.mode=='seed':
        assert d==original,'Restore full fixture before seeding bank'
        base=original['pet_bag_list']['3'];pets=[]
        for i in range(4):
            pet=copy.deepcopy(base)
            pet['attrib'].update(name='CYS-BANK-'+str(i+1),guid={'m_uHighSection':200016,'m_uLowSection':22092801+i},
                level=20,wuxing=0,lingxing=100,gengu=5,hp=200,life_span=60000,happiness=100,
                str_perception=1234+i,spr_perception=2345+i,con_perception=3456+i,dex_perception=4567+i,int_perception=5678+i)
            pet['skills']={'activate':{},'positive':{}};pet['equips']={};pet['elf_slots']={};pet['cool_down_times']={}
            pets.append(pet)
        attr=copy.deepcopy(original['attrib']);attr.update(pet_bank_bag_size=10,
            pet_guid={'m_uHighSection':0,'m_uLowSection':0},soul_melting_pet_guid={'m_uHighSection':0,'m_uLowSection':0},
            sceneid=12,world_pos={'x':77.,'y':89.},hp=5000,mp=3000)
        seed={'pet_bag_list':{'1':pets[0],'2':pets[1]},'pet_bank_list':{'3':pets[2],'8':pets[3]}}
        (LOG/'bank-seed.json').write_text(json_util.dumps(seed),encoding='utf8')
        col.update_one({'_id':d['_id']},{'$set':dict(seed,attrib=attr,sceneid=12)})
        print('Seeded four unique pets; bank slots 2/7; complete original retained')
    else:
        seen={};rows=[]
        for container in ['pet_bag_list','pet_bank_list']:
            for slot,pet in d[container].items():
                attr=pet['attrib'];guid=attr['guid'];key=(guid['m_uHighSection'],guid['m_uLowSection'])
                assert key not in seen;seen[key]=True
                rows.append(dict(container=container,slot=slot,guid=key,str_perception=attr['str_perception'],lingxing=attr['lingxing']))
        assert len(seen)==4
        # mode5 deposits pet1, swaps pet2 with pet3, then withdraws pet1.
        expected={'pet_bag_list':{22092801,22092803},'pet_bank_list':{22092802,22092804}}
        for container,ids in expected.items():assert {x['attrib']['guid']['m_uLowSection'] for x in d[container].values()}==ids
        for row in rows:assert row['str_perception']==1234+row['guid'][1]-22092801 and row['lingxing']==100
        (LOG/'bank-after.json').write_text(json.dumps(rows,indent=2));print('PASS four GUIDs unique, expected ownership, aptitude/lingxing preserved')
