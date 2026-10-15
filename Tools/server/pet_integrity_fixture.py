"""Reversible private test15 Pet fixture. Run in WSL after a clean private restart."""
import argparse,copy
from pathlib import Path
from bson import json_util
from cs3b_menpai import provision
from give_item import connected,scan
p=argparse.ArgumentParser(description=__doc__)
p.add_argument('mode',choices=['seed','reset','restore','verify','inspect'])
p.add_argument('--backup',type=Path,required=True)
p.add_argument('--awakening',action='store_true')
a=p.parse_args()
assert not connected(), 'private clients still connected'
with provision().database() as client:
    col=client.tlbb.character;d=col.find_one({'attrib.guid':200016});assert d
    if a.mode=='seed':
        assert not a.backup.exists(), 'backup already exists'
        a.backup.parent.mkdir(parents=True,exist_ok=True)
        a.backup.write_text(json_util.dumps(d),encoding='utf-8')
    if a.mode in ('seed','reset'):
        original=json_util.loads(a.backup.read_text(encoding='utf-8'));assert original['_id']==d['_id']
        pet=copy.deepcopy(original['pet_bag_list']['3'])
        pet['attrib'].update(name='CYS-PET',guid={'m_uHighSection':200016,'m_uLowSection':22092201},
                             level=20,wuxing=0,lingxing=100,gengu=5,hp=200,life_span=60000,happiness=100,
                             str_perception=1000,spr_perception=1000,con_perception=1000,dex_perception=1000,int_perception=1000)
        pet['skills']={'activate':{},'positive':{}};pet['equips']={};pet['elf_slots']={};pet['cool_down_times']={}
        pet['lv1_attrib']={'str':10,'spr':10,'con':10,'dex':10,'int':10,'point_remain':20}
        _,samples=scan(col);bag={}
        if 2 not in samples:
            samples[2]=copy.deepcopy(samples[3]);samples[2].pop('unknow_20',None);samples[2]['unknow_19']=[0]*32
        for pos,item in enumerate([30402005,30503043,30502000]):
            row=copy.deepcopy(samples[3]);row.update(item_index=item,count=2,lay_count=2,status=2)
            row['guid']={'world':254,'server':254,'mask':0,'series':22092200+pos}
            row['unknow_20'][0]=2;bag[str(pos+1)]=row
        if a.awakening:
            pet['attrib'].update(wuxing=5,lingxing=0)
            for pos,item in [(3,30502005),(4,20310116)]:
                row=copy.deepcopy(samples[item//10000000]);row.update(item_index=item,count=2,lay_count=2,status=2)
                row['guid']={'world':254,'server':254,'mask':0,'series':22092200+pos}
                row['unknow_20' if item//10000000==3 else 'unknow_19'][0]=2
                bag[str(pos+1)]=row
        attr=copy.deepcopy(original['attrib']);attr.update(jiaozi=1000000,money=0,yuanbao=1000000,
            pet_guid={'m_uHighSection':0,'m_uLowSection':0},soul_melting_pet_guid={'m_uHighSection':0,'m_uLowSection':0})
        col.update_one({'_id':d['_id']},{'$set':{'pet_bag_list':{'1':pet},'prop_bag_list':bag,'attrib':attr}})
        print('seeded private test15 Pet 3019, empty skills, 20 points,',
              'savvy5/unawakened' if a.awakening else 'savvy0/awakened level0', 'books/materials x2')
    elif a.mode=='restore':
        original=json_util.loads(a.backup.read_text(encoding='utf-8'));assert original['_id']==d['_id'] and original['attrib']['guid']==200016
        col.replace_one({'_id':d['_id']},original)
        assert col.find_one({'_id':d['_id']})==original
        print('restored and verified entire test15 character document')
    elif a.mode=='verify':
        original=json_util.loads(a.backup.read_text(encoding='utf-8'));assert d==original
        print('PASS complete test15 document equals original backup')
    elif a.mode=='inspect':
        print(json_util.dumps({'pets':d['pet_bag_list'],'bag':{k:(v['item_index'],v.get('count'),v.get('lay_count')) for k,v in d['prop_bag_list'].items()},
                              'money':{k:d['attrib'][k] for k in ['jiaozi','money','yuanbao','soul_melting_pet_guid','pet_guid']}},indent=2))
