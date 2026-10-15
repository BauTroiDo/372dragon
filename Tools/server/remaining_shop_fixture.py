"""Private test14/test15 and one temporary shop. Whole BSON backup/restore."""
import argparse,copy,json
from pathlib import Path
from bson import json_util
from cs3b_menpai import provision
from give_item import connected
LOG=Path('/mnt/c/TLBB/085/CY-Source/Build/Logs/2026-09-28-hj05-remaining')
IDS=[200015,200016]
SG={'world':1,'server':2,'scene':12,'pollpos':65000}
QUERY={'guid.world':1,'guid.server':2,'guid.scene':12,'guid.pollpos':65000}
def main():
    ap=argparse.ArgumentParser();ap.add_argument('mode',choices=['quiesce','seed','inspect','verify-purchase','restore','verify']);a=ap.parse_args()
    assert not connected(),'A private client is connected'
    runtime=provision();spec=next(s for s in runtime.role_specs() if s['name']=='Game')
    processes=runtime.owned_processes(spec)
    if a.mode=='quiesce':
        assert len(processes)<=1
        if processes:runtime.stop_owned(spec,processes[0])
        print('Stopped verified private Game; Mongo remains available for fixture restoration')
        return
    if a.mode in ('seed','restore'):assert not processes,'Quiesce private Game before fixture mutation'
    LOG.mkdir(parents=True,exist_ok=True)
    with provision().database() as client:
        db=client.world_10;chars=client.tlbb.character
        if a.mode=='seed':
            for guid in IDS:
                doc=chars.find_one({'attrib.guid':guid});assert doc
                b=LOG/f'shop-char-{guid}-original.json'
                if b.exists():assert doc==json_util.loads(b.read_text()),'Restore current fixture first'
                else:b.write_text(json_util.dumps(doc),encoding='utf8')
            assert db.shop.count_documents(QUERY)==0,'Fixture shop GUID already exists'
            owner=json_util.loads((LOG/'shop-char-200016-original.json').read_text())
            base=next(iter(owner['pet_bag_list'].values()));pet=copy.deepcopy(base)
            pet['attrib'].update(name='CYS-Shop-Pet',guid={'m_uHighSection':200016,'m_uLowSection':22092851},level=20,wuxing=0,lingxing=100,gengu=5,hp=200,life_span=60000,happiness=100,
                str_perception=1234,spr_perception=2345,con_perception=3456,dex_perception=4567,int_perception=5678)
            pet['skills']={'activate':{},'positive':{}};pet['equips']={};pet['elf_slots']={}
            for guid in IDS:
                values={'sceneid':12,'attrib.sceneid':12,'attrib.world_pos':{'x':77.,'y':89.},'attrib.hp':5000,'attrib.mp':3000,'attrib.money':10000,
                    'attrib.pet_guid':{'m_uHighSection':0,'m_uLowSection':0},'attrib.soul_melting_pet_guid':{'m_uHighSection':0,'m_uLowSection':0},
                    'pet_bag_list':{'1':pet} if guid==200016 else {}}
                chars.update_one({'attrib.guid':guid},{'$set':values})
            shop=dict(guid=SG,status=2,type=1,owner_guid=200016,owner_name='CYTest15',name='CYSShop',desc='CYS fixture',max_base_money=1000,base_money=1000,profit_money=0,
                founded_day=260928,stall_opend_num=1,stall_on_sal_num=0,sale_out_price=0,partner_list=[],exchange_record=[],manager_record=[],serial=0,
                stall_list_data=[dict(status=2 if i==0 else 0,item_list={},item_price={},item_serials={},item_is_on_sale={}) for i in range(10)])
            db.shop.insert_one(shop);(LOG/'shop-seed.json').write_text(json_util.dumps(shop),encoding='utf8')
            print('Seeded owned test14/test15 and temporary shop; full original BSON retained')
        elif a.mode in ('inspect','verify-purchase'):
            shop=db.shop.find_one(QUERY);assert shop
            result={'characters':[],'profit':shop['profit_money'],'shop_pet_count':sum(len(s.get('item_list',{})) for s in shop['stall_list_data'])}
            for guid in IDS:
                d=chars.find_one({'attrib.guid':guid});pets=list(d.get('pet_bag_list',{}).values())
                result['characters'].append({'guid':guid,'money':d['attrib']['money'],'pets':[p['attrib']['guid'] for p in pets],
                    'aptitudes':[p['attrib']['str_perception'] for p in pets]})
            (LOG/'shop-after.json').write_text(json.dumps(result,indent=2));print(json.dumps(result))
            if a.mode=='verify-purchase':
                buyer,owner=result['characters']
                assert buyer['money']==9500 and owner['money']==10000
                assert buyer['pets']==[{'m_uHighSection':200016,'m_uLowSection':22092851}]
                assert buyer['aptitudes']==[1234] and owner['pets']==[]
                assert result['shop_pet_count']==0 and result['profit']==490
                (LOG/'shop-purchase-proof.json').write_text(json.dumps({'passed':True,**result},indent=2))
                print('PASS persisted buyer debit, seller proceeds, original GUID once, aptitude unchanged')
        else:
            for guid in IDS:
                old=json_util.loads((LOG/f'shop-char-{guid}-original.json').read_text())
                if a.mode=='restore':chars.replace_one({'_id':old['_id']},old)
                assert chars.find_one({'_id':old['_id']})==old
            seed=json_util.loads((LOG/'shop-seed.json').read_text())
            if a.mode=='restore':
                rows=list(db.shop.find(QUERY))
                assert all(r['name']=='CYSShop' and r['owner_guid']==200016 for r in rows)
                (LOG/'shop-fixture-deleted.json').write_text(json_util.dumps(rows),encoding='utf8')
                for r in rows:db.shop.delete_one({'_id':r['_id'],**QUERY})
            assert db.shop.count_documents(QUERY)==0
            (LOG/f'shop-{a.mode}.json').write_text(json.dumps({'full_bson_equal':True,'fixture_shop_absent':True}))
            print('PASS full original BSON '+a.mode)
if __name__=='__main__':main()
