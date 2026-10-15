"""Reversible equipment-skills fixture: ONLY test15/GUID200016, private Mongo."""
import argparse, copy, json, pathlib, sys
from bson import json_util
from cs3b_menpai import provision
from give_item import connected, scan

p=argparse.ArgumentParser();p.add_argument('mode',choices=['seed','inspect','restore']);p.add_argument('--backup',type=pathlib.Path,required=True);p.add_argument('--ui-dark',action='store_true');a=p.parse_args()
assert not connected(), 'close private test clients before fixture access'
fields=['prop_bag_list','material_bag_list','equip_list','mission_data','attrib','skill_list','impact_list']
with provision().database() as client:
    col=client.tlbb.character;d=col.find_one({'attrib.guid':200016});assert d
    if a.mode=='seed':
        state={k:copy.deepcopy(d.get(k)) for k in fields}
        if a.backup.exists():
            assert json_util.loads(a.backup.read_text(encoding='utf8'))==state, 'restore point differs; refusing reseed'
        else:
            a.backup.parent.mkdir(parents=True,exist_ok=True);a.backup.write_text(json_util.dumps(state),encoding='utf8')
        top,samples=scan(col);bag=copy.deepcopy(d['prop_bag_list'])
        if 2 not in samples:
            # item.lua material_data ctor/copy_raw_data (1223..1238): same item
            # envelope, with unknow_19 instead of store_map_data's unknow_20.
            samples[2]=copy.deepcopy(samples[3]);samples[2].pop('unknow_20',None);samples[2]['unknow_19']=[0]*32
        assert all(str(i+1) not in bag for i in [13,15,16,17,18,19])
        soul=copy.deepcopy(d['equip_list']['19']);assert soul['item_index']==10156001
        def put(pos,id,count=1,model=None):
            global top
            row=copy.deepcopy(model or samples[id//10000000]);top+=1
            row.update(item_index=id,lay_count=count,count=count)
            row['guid']['series']=top;row['status']=2
            if id//10000000!=1 and isinstance(row.get('unknow_20'),list):row['unknow_20'][0]=count
            if id//10000000==2:row['unknow_19'][0]=count
            bag[str(pos+1)]=row;return row
        wh=put(13,10156001,model=soul);wh.update(wh_level=90,wh_skill=[1361,1385,1541],wh_life=300)
        for pos,id,creator in [(15,10157001,'&LW00000000'),(16,10158005,'&LP10000000000000000000')]:
            row=put(pos,id,model=soul);row.update(equip_type=0,creator=creator,attr_count=0,attr_type=0,attr_types=[],attr_values=[],visual=0)
        put(17,20310181,30);put(18,30700213,1);put(19,38000971,1)
        missions=copy.deepcopy(d['mission_data']);missions['cy_rl_learned']=0;missions['cy_rl_ready_at']=0
        if a.ui_dark:
            wh.update(item_index=10155001,equip_type=1,aq_xiulian=90,aq_exp=0,aq_grow_rate=1000,
                      aq_attr=[0]*5,aq_skill=[0,0,0],aq_xidian=0,attr_count=0,attr_type=0,attr_types=[],attr_values=[])
            bag['16']['creator']='&LW02000000'
            bag['17']['creator']='&LP1000000000000000000G'
            put(17,30700213,1);put(18,30503118,1)
            other=put(19,10156001,model=soul);other.update(wh_level=90,wh_skill=[1361,1385,1541],wh_life=300)
            missions['cy_rl_learned']=64
        col.update_one({'_id':d['_id']},{'$set':{'prop_bag_list':bag,'attrib.money':1000000,'attrib.jiaozi':0,'mission_data':missions}})
        print('seeded test15 slots 13,15,16,17,18,19; saved restore point')
    elif a.mode=='restore':
        state=json_util.loads(a.backup.read_text(encoding='utf8'));assert state['attrib']['guid']==200016
        col.update_one({'_id':d['_id']},{'$set':state})
        after=col.find_one({'_id':d['_id']});assert all(after.get(k)==state[k] for k in fields)
        print('restored and verified test15 equipment, inventory, money, missions, skills, impacts')
    else:
        print(json.dumps({'money':d['attrib'].get('money'),'jiaozi':d['attrib'].get('jiaozi'),
            'learned':d['mission_data'].get('cy_rl_learned'),
            'items':{k:{f:r.get(f) for f in ['item_index','creator','wh_level','wh_skill','aq_xiulian','aq_skill','lay_count']} for k,r in d['prop_bag_list'].items() if r.get('item_index') in [10155001,10156001,10157001,10158005,20310181,30700213,30503118,38000971]}},ensure_ascii=False))
