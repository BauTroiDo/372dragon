local root=assert(arg[1]);local stage=assert(arg[2])
package.path=stage..'/GameServer/lualib/?.lua;'..root..'/GameServer/lualib/?.lua;'..package.path
local M=require 'cy_equipment_passives'
local pass,fail=0,0
local function test(name,ok,detail)
    if ok then pass=pass+1 else fail=fail+1 end
    print((ok and 'PASS' or 'FAIL')..'\t'..name..'\t'..(detail or ''))
end
local roots={{1},{21,31,41,51},{11,61,71,81}}
local count=0;local good=true
for slot,types in ipairs(roots)do for _,first in ipairs(types)do for rank=1,10 do
    local ids={0,0,0};ids[slot]=first+rank-1
    local code=M.lw_encode('CYTest',ids);local read=M.lw_decode(code)
    good=good and read[slot]==ids[slot];count=count+1
end end end
test('all_90_extension_rows_roundtrip',good,'rows='..count)
test('malformed_state',not M.lw_decode('&LW99199499'))
test('GL_item_control',M.kind(10157000)==nil and M.kind(10157001)==19 and M.kind(10158005)==20)
local sent,spent,consumed,item,bag,human,mat,ed
local function reset()
    sent,spent,consumed=0,0,0
    ed={set_equip_type=function(self,v)self.type=v end}
    item={id=10157001,creator='CYTest&LW00000000',get_index=function(self)return self.id end,
        get_serial_class=function()return 1 end,get_serial_type=function()return 1 end,
        is_lock=function(self)return self.locked end,get_equip_data=function()return ed end,
        get_item_creator=function(self)return self.creator end,set_item_creator=function(self,v)self.creator=v end,
        set_is_bind=function(self,v)self.bound=v end,copy_raw_data=function(self)return {creator=self.creator}end}
    mat={id=20310181,n=500,is_lock=function(self)return self.locked end,get_index=function(self)return self.id end,
        get_lay_count=function(self)return self.n end,is_bind=function(self)return self.bound end}
    bag={get_item=function(_,p)return p==0 and item or p==1 and mat end,ipairs=function(_,page)return next,page=='prop' and {[1]=mat} or {},nil end}
    human={money=1000000,get_prop_bag_container=function()return bag end,get_money=function(self)return self.money end,get_jiaozi=function()return 0 end,
        cost_money_with_priority=function(self,n)self.money=self.money-n;spent=spent+n end,
        get_scene=function()return {send2client=function()sent=sent+1 end}end}
end
package.loaded['game.packet']={GCItemInfo={new=function()return {}end}}
package.loaded.human_item_logic={dec_item_lay_count=function(_,_,_,p,n,id)
    assert(p==1 and mat.id==id and mat.n>=n);mat.n=mat.n-n;consumed=consumed+n;return true end}
reset();test('learn_hp',M.lw_operation(human,0,4,0) and spent==10000 and consumed==10 and sent==1 and M.lw_decode(item.creator)[1]==1)
test('reject_duplicate_hp',not M.lw_operation(human,0,4,0) and spent==10000 and consumed==10)
test('upgrade_hp',M.lw_operation(human,0,7,0) and spent==20000 and consumed==30 and M.lw_decode(item.creator)[1]==2)
reset();mat.locked=true;test('locked_material',not M.lw_operation(human,0,4,0) and spent==0 and consumed==0)
reset();item.locked=true;test('locked_target',not M.lw_operation(human,0,4,0) and spent==0 and consumed==0)
reset();human.money=9999;test('insufficient_money',not M.lw_operation(human,0,4,0) and spent==0 and consumed==0)
reset();mat.n=9;test('insufficient_material',not M.lw_operation(human,0,4,0) and spent==0 and consumed==0)
reset();test('unlearned_upgrade',not M.lw_operation(human,0,7,0) and spent==0)
reset();item.id=10158005;test('wrong_equipment',not M.lw_operation(human,0,4,0) and spent==0)
reset();test('empty_bag',not M.lw_operation(human,2,4,0) and spent==0)
reset();mat.id=20310189;mat.bound=true;test('alternate_material_binding',M.lw_operation(human,0,4,0) and consumed==10 and item.bound==true)
reset();item.creator='CYTest&LW10000000';test('max_level',not M.lw_operation(human,0,7,0) and spent==0)
reset();mat.id=20310182;test('learn_resist_fire',M.lw_operation(human,0,6,2) and M.lw_decode(item.creator)[2]==31)
test('switch_resist_ice',M.lw_operation(human,0,6,1) and M.lw_decode(item.creator)[2]==21)
mat.id=20310183;test('learn_attack_poison',M.lw_operation(human,0,5,4) and M.lw_decode(item.creator)[3]==81)
local values={};local attrib={cal_item_effect=function(_,id,value)values[id]=(values[id] or 0)+value end}
M.apply_attributes(attrib,item,19)
test('applied_exact_CY_values',values[8]==2 and values[15]==40 and values[1]==nil)
values={};M.apply_attributes(attrib,item,20);test('wrong_slot_no_effect',next(values)==nil)
item.id=10158005;M.apply_attributes(attrib,item,19);test('RL_not_LW_effect',next(values)==nil)
print(string.format('SUMMARY pass=%d fail=%d',pass,fail));os.exit(fail==0 and 0 or 1)
