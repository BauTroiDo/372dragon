"""Owned test15 fixture. Full BSON backup and exact restore; private CY only."""
import argparse,copy,json,subprocess
from pathlib import Path
from bson import json_util
from cs3b_menpai import provision
from give_item import connected,scan
LOG=Path('/mnt/c/TLBB/085/CY-Source/Build/Logs/2026-09-28-hj05-fixes')
ROOT=Path('/home/ubuntu/cys-test-20260913')

def soul_template():
    # Use the actual pet_equip_data constructor, not a fabricated schema.
    program=r'''
local root=arg[1];package.path=root..'/GameServer/lualib/?.lua;'..package.path
package.cpath=root..'/GameServer/luaclib/?.so;'..package.cpath
package.loaded.skynet={getenv=function()end};local f=assert(io.open(root..'/GameServer/lualib/item.lua'))
local s=f:read('a');f:close();local a=assert(s:find('local pet_equip_data = class',1,true));local b=assert(s:find('\nlocal task_data = class',a,true))
local env=setmetatable({class=require 'class',define=require 'define'},{__index=_G})
local p=assert(load(s:sub(a,b-1)..'\nreturn pet_equip_data',nil,'t',env))().new()
p:set_pet_equip_type(1);p:set_level(1);p:set_pet_soul_quanlity(2)
p:set_pet_soul_level(0);p:set_pet_soul_exp(0);p.pet_equip_unknow_8=100
local function encode(v)
 if type(v)=='string' then return string.format('%q',v) end
 if type(v)=='number' or type(v)=='boolean' then return tostring(v) end
 assert(type(v)=='table','constructor contains a nonserializable field')
 local out={}
 if #v>0 then for i=1,#v do out[#out+1]=encode(v[i])end;return '['..table.concat(out,',')..']' end
 for k,x in pairs(v)do out[#out+1]=string.format('%q',k)..':'..encode(x)end
 return '{'..table.concat(out,',')..'}'
end
print(encode(p))
'''
    return json.loads(subprocess.check_output(['lua','-',str(ROOT)],input=program.encode()))

def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('mode',choices=['seed','inspect','restore','verify']);a=p.parse_args()
    assert not connected(),'Private client still connected'
    backup=LOG/'test15-original.json'
    with provision().database() as client:
        col=client.tlbb.character;d=col.find_one({'attrib.guid':200016});assert d
        if a.mode=='seed':
            if backup.exists():
                assert d==json_util.loads(backup.read_text(encoding='utf8')),'Fixture already changed; restore first'
            else: backup.write_text(json_util.dumps(d),encoding='utf8')
            top,samples=scan(col);bag={}
            soul=soul_template();soul.update(item_index=70600000,status=2,rule=1,count=1,lay_count=1,
                guid={'world':254,'server':254,'mask':0,'series':top+201})
            bag['1']=soul
            material=copy.deepcopy(samples[3]);material.update(item_index=38002520,status=2,count=2,lay_count=2)
            material['guid']={'world':254,'server':254,'mask':0,'series':top+202};material['unknow_20'][0]=2;bag['2']=material
            fields={'prop_bag_list':bag,'attrib.sceneid':12,'sceneid':12,'attrib.world_pos':{'x':77.0,'y':89.0},
                'attrib.hp':5000,'attrib.mp':3000}
            col.update_one({'_id':d['_id']},{'$set':fields})
            print('Seeded test15 soul life100/material2; complete BSON preserved')
        elif a.mode=='inspect':
            rows=d.get('prop_bag_list',{})
            proof={'soul':[{k:v.get(k) for k in ('item_index','pet_equip_unknow_8','guid')} for v in rows.values() if v.get('item_index')==70600000],
                'materials':sum(v.get('count',0) for v in rows.values() if v.get('item_index')==38002520)}
            (LOG/'fixture-after.json').write_text(json.dumps(proof,indent=2));print(json.dumps(proof))
            assert len(proof['soul'])==1 and proof['soul'][0]['pet_equip_unknow_8']==200 and proof['materials']==1
        else:
            old=json_util.loads(backup.read_text(encoding='utf8'));assert old['_id']==d['_id'] and old['attrib']['guid']==200016
            if a.mode=='restore': col.replace_one({'_id':d['_id']},old)
            assert col.find_one({'_id':d['_id']})==old
            (LOG/('fixture-'+a.mode+'.json')).write_text(json.dumps({'full_bson_equal':True,'guid':200016,'read_only':a.mode=='verify'}))
            print('PASS exact BSON',a.mode,'test15')
if __name__=='__main__':main()
