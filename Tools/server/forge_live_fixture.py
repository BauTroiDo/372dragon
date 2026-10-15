"""Reversible test15 forge fixture; private server, entire character backup."""
from pathlib import Path
import argparse,copy,json,datetime
from bson import json_util
from cs3b_menpai import provision
from give_item import connected,scan
p=argparse.ArgumentParser(description=__doc__);p.add_argument('mode',choices=['seed','reset','verify','verify-cancel','restore']);p.add_argument('--backup',type=Path,required=True);a=p.parse_args()
assert not connected(),'private clients still connected'
with provision().database() as c:
    col=c.tlbb.character;d=col.find_one({'attrib.guid':200016});assert d
    if a.mode in ('seed','reset'):
        if a.mode=='seed':
            assert not a.backup.exists();a.backup.parent.mkdir(parents=True,exist_ok=True)
            a.backup.write_text(json_util.dumps(d),encoding='utf8')
        else:
            original=json_util.loads(a.backup.read_text(encoding='utf8'));assert original['_id']==d['_id']
            assert d['prop_bag_list']['19']['guid']['series']==2309202601
        _,samples=scan(col);equip=copy.deepcopy(d['equip_list']['1']);material=copy.deepcopy(samples[3])
        equip.update(item_index=10106000,visual=2061,status=2,enhancement_level=2)
        equip['guid']={'world':254,'server':254,'mask':0,'series':2309202601}
        material.update(item_index=30900005,count=30,lay_count=30,status=2)
        material['guid']={'world':254,'server':254,'mask':0,'series':2309202602};material['unknow_20'][0]=30
        col.update_one({'_id':d['_id']},{'$set':{'attrib.level':81,'attrib.menpai':3,'attrib.sceneid':12,'sceneid':12,
            'attrib.world_pos':{'x':77.0,'y':89.0},'attrib.hp':5000,'attrib.mp':3000,
            'attrib.money':1000000,'attrib.jiaozi':0,'prop_bag_list':{'19':equip,'20':material},'cys_forge':False}})
        print('Seeded test15: bag18 weapon +2, bag19 30 essences, 1000000 money, full backup saved')
    elif a.mode in ('verify','verify-cancel'):
        items=d['prop_bag_list'];e=items['19'];m=items['20']
        assert e['enhancement_level']==(9 if a.mode=='verify' else 0),e.get('enhancement_level')
        assert m['count']==(21 if a.mode=='verify' else 28),m['count']
        assert not d.get('cys_forge')
        assert e['status']&4==0,'pending lock persisted'
        spent=1691 if a.mode=='verify' else 247
        assert d['attrib']['money']==1000000-spent and d['attrib']['jiaozi']==0
        report={'mode':a.mode,'checked_at':datetime.datetime.now().isoformat(),'level':e['enhancement_level'],
                'material_count':m['count'],'money':d['attrib']['money'],'jiaozi':d['attrib']['jiaozi'],
                'spent':spent,'pending':False,'locked':False,'passed':True}
        (a.backup.parent/f'db-{a.mode}.json').write_text(json.dumps(report,indent=2),encoding='utf8')
        print('PASS persistent result, exact material consumption, no pending attempt, item unlocked:',a.mode)
        print('Money remaining:',d['attrib']['money'],'jiaozi:',d['attrib']['jiaozi'])
    else:
        saved=json_util.loads(a.backup.read_text(encoding='utf8'));assert saved['_id']==d['_id']
        col.replace_one({'_id':d['_id']},saved);assert col.find_one({'_id':d['_id']})==saved
        print('Restored entire test15 BSON and verified exact equality')
