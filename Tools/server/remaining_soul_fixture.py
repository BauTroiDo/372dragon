"""Own test15, actual item constructor, complete BSON backup and restoration."""
import argparse,copy,json
from bson import json_util
from cs3b_menpai import provision
from give_item import connected,scan
from hj05_fixture import soul_template
from remaining_shop_fixture import LOG

def main():
    p=argparse.ArgumentParser();p.add_argument('mode',choices=['seed','inspect','restore','verify']);a=p.parse_args()
    assert not connected(),'Private client connected'
    rt=provision();game=next(s for s in rt.role_specs() if s['name']=='Game')
    if a.mode in ('seed','restore'):assert not rt.owned_processes(game),'Quiesce private Game first'
    backup=LOG/'soul-test15-original.json'
    with rt.database() as client:
        col=client.tlbb.character;d=col.find_one({'attrib.guid':200016});assert d
        if a.mode=='seed':
            assert client.world_10.shop.count_documents({'name':'CYSShop','owner_guid':200016})==0,'Restore shop fixture first'
            if backup.exists():assert d==json_util.loads(backup.read_text()),'Restore prior soul fixture first'
            else:backup.write_text(json_util.dumps(d),encoding='utf8')
            top,samples=scan(col);bag={};soul=soul_template()
            soul.update(item_index=70600005,pet_soul_quanlity=1,status=2,rule=1,count=1,lay_count=1,
                guid={'world':254,'server':254,'mask':0,'series':top+211},
                pet_soul_attr=[{'type':t,'value':1} for t in (0,1,2,3,22)]+[{'type':-1,'value':0}])
            bag['1']=soul
            for i,(id,n) in enumerate(((38002533,5),(38002636,2)),2):
                item=copy.deepcopy(samples[3]);item.update(item_index=id,status=2,count=n,lay_count=n)
                item['guid']={'world':254,'server':254,'mask':0,'series':top+210+i};item['unknow_20'][0]=n;bag[str(i)]=item
            fields={'prop_bag_list':bag,'attrib.money':100000,
                'sceneid':12,'attrib.sceneid':12,'attrib.world_pos':{'x':77.,'y':89.},'attrib.hp':5000,'attrib.mp':3000}
            col.update_one({'_id':d['_id']},{'$set':fields})
            (LOG/'soul-seed.json').write_text(json.dumps({'bag':bag,'money':100000},indent=2))
            print('Seeded test15 genuine quality1 soul, five washers/two color locks; complete BSON preserved')
        elif a.mode=='inspect':
            rows=list(d.get('prop_bag_list',{}).values());souls=[x for x in rows if x.get('item_index')==70600005]
            assert len(souls)==1;s=souls[0];seed=json.loads((LOG/'soul-seed.json').read_text())['bag']['1']
            counts={id:sum(x.get('count',0) for x in rows if x.get('item_index')==id) for id in (38002533,38002636)}
            attrs=s['pet_soul_attr'];assert len(attrs)==6 and attrs[5]=={'type':-1,'value':0}
            assert any(x['type']==22 for x in attrs[:5]) and len({x['type'] for x in attrs[:5]})==5
            assert s['guid']==seed['guid'] and counts=={38002533:3,38002636:1} and d['attrib']['money']==50000
            result={'passed':True,'guid':s['guid'],'attrs':attrs,'money':50000,'counts':counts}
            (LOG/'soul-persist-proof.json').write_text(json.dumps(result,indent=2));print(json.dumps(result))
        else:
            old=json_util.loads(backup.read_text());assert old['_id']==d['_id']
            if a.mode=='restore':col.replace_one({'_id':old['_id']},old)
            assert col.find_one({'_id':old['_id']})==old
            (LOG/f'soul-{a.mode}.json').write_text(json.dumps({'full_bson_equal':True,'guid':200016}))
            print('PASS complete original BSON',a.mode)
if __name__=='__main__':main()
