"""Native row locks and color guarantees; preserve previously published fixes."""
from inventory_integrity import function
RELS=['GameServer/lualib/item.lua','GameServer/lualib/cys_petsoul.lua',
      'GameServer/lualib/script_base.lua','Game_2/Script/scripts/cys_petsoul.lua',
      'Game_2/Script/scripts/obj/suzhou/osuzhou_yunshenshen.lua']

def once(s,a,b):
    assert s.count(a)==1,(a,s.count(a))
    return s.replace(a,b)

def patch(rel,s):
    if rel.endswith('/item.lua'):
        return function(s,'pet_equip_data:gen_soul_attr','''function pet_equip_data:gen_soul_attr(lock_value, lock_color_count)
    return require('cys_soul_reforge').generate(self:get_pet_soul_quanlity(),self.pet_soul_attr,
        lock_value,lock_color_count,define.PET_SOUL_ATTRS,configenginer:get_config('pet_soul_extension'))
end''')
    if rel=='GameServer/lualib/cys_petsoul.lua':
        s=once(s,"text[#text+1]=i..'. '..desc", "text[#text+1]=require('cys_soul_reforge').text_color(ext[type],a.value)..i..'. '..desc")
        s=once(s,'function M.action(s,h,op,pos,revision,material)',
            'function M.action(s,h,op,pos,revision,material,lock_value,color_pos)')
        s=once(s,'        local parts=plan(h,materials,1)', '''        local reforge=require 'cys_soul_reforge'
        lock_value=lock_value or 0;color_pos=color_pos or -1
        local locks,count=reforge.locks(lock_value,quality,e:get_pet_soul_attr())
        if not locks then return fail(s,h,pos,'Chỉ khóa được loại thuộc tính đang có trên Thú hồn.') end
        local cost_count=reforge.costs[count];local color_count=0;local color
        if color_pos~=-1 then
            if not guard.integer(color_pos,0,199) or color_pos==pos then return fail(s,h,pos,'Ô vật phẩm khóa màu không hợp lệ.') end
            color=h:get_prop_bag_container():get_item(color_pos)
            local allowed=color and reforge.colors[color:get_index()]
            color_count=allowed and allowed[quality]
            if not color_count or color:is_empty() or color:is_lock() then return fail(s,h,pos,'Vật phẩm khóa màu không phù hợp với phẩm Thú hồn.') end
        end
        local parts=plan(h,materials,cost_count)''')
        s=once(s,"'Tẩy thuộc tính cần 1 Thối Hồn Dịch/Thúy Hồn Thủy phù hợp và 50000 vàng/giao tử.'",
            "'Tẩy thuộc tính cần '..cost_count..' nguyên liệu phù hợp và 50000 Võ Thạch hạ phẩm.'")
        s=once(s,'local attrs=e:gen_soul_attr(0,0);','local attrs=e:gen_soul_attr(lock_value,color_count);')
        s=once(s,"        bound=consume(h,parts);h:cost_money_with_priority(50000,'Pet soul reforge')",'''        if color then parts[#parts+1]={pos=color_pos,n=1,id=color:get_index(),bind=color:is_bind()} end
        bound=consume(h,parts);h:cost_money_with_priority(50000,'Pet soul reforge')''')
        s=once(s,'s:GetMissionData(h:get_obj_id(),counter)+1','s:GetMissionData(h:get_obj_id(),counter)+cost_count')
        return s.replace('vàng/giao tử','Võ Thạch hạ phẩm')
    if rel=='Game_2/Script/scripts/cys_petsoul.lua':
        return s.replace('id,op,pos,revision,material','id,op,pos,revision,material,lock_value,color_pos').replace('self,h,op,pos,revision,material)','self,h,op,pos,revision,material,lock_value,color_pos)')
    if rel.endswith('/script_base.lua'):
        return function(s,'script_base:PetSoulXiShuXing',change=lambda b:once(once(b,
            'function script_base:PetSoulXiShuXing(selfId, BagPos, LockValue, LockColorCount)',
            'function script_base:PetSoulXiShuXing(selfId, BagPos, LockValue, LockColorCount, prepared)'),
            'local pet_soul_attr = item:get_pet_equip_data():gen_soul_attr(LockValue, LockColorCount)',
            '''local pet_soul_attr = prepared or item:get_pet_equip_data():gen_soul_attr(LockValue, LockColorCount)
    if type(pet_soul_attr)~='table' or #pet_soul_attr~=6 then return false end'''))
    if rel.endswith('/osuzhou_yunshenshen.lua'):
        def native(b):
            b=once(b,'    local equip_type = self:GetPetEquipType(selfId, BagPosSoul)', '''    local h=self.scene:get_obj_by_id(selfId)
    if not h or h:is_die() or h._leaving or self:IsPilferLockFlag(selfId) then return end
    local guard=require 'cys_inventory_guard'
    if not guard.integer(BagPosSoul,0,199) or (BagPosL~=-1 and not guard.integer(BagPosL,0,199)) then return end
    local equip_type = self:GetPetEquipType(selfId, BagPosSoul)''')
            b=once(b,'    local cost_count, cost_money = self:GetXiShuXingCostMaterialCount(LockValue), 50000', '''    local item=h:get_prop_bag_container():get_item(BagPosSoul)
    local reforge=require 'cys_soul_reforge'
    local locks,count=reforge.locks(LockValue,quanlity,item:get_pet_equip_data():get_pet_soul_attr())
    if not locks then self:notify_tips(selfId,'Không thể khóa dòng thuộc tính trống hoặc bị ẩn.');return end
    local cost_count,cost_money=reforge.costs[count],50000
    local bound=false''')
            b=once(b,'                table.insert(mat_slots, { pos = i, count = slot_count })',
                '                table.insert(mat_slots, { pos = i, count = slot_count, bind=self:GetBagItemIsBind(selfId,i) })')
            b=once(b,'    self:SetMissionData(selfId, define.MD_ENUM.MD_COST_CHU_HUN_YE, cost_chu_hun_ye)', '''    if BagPosL~=define.INVAILD_ID and LockColorCount==0 then
        self:notify_tips(selfId,'Vật phẩm khóa màu không phù hợp với phẩm Thú hồn.');return
    end
    local prepared=item:get_pet_equip_data():gen_soul_attr(LockValue,LockColorCount)
    if type(prepared)~='table' or #prepared~=6 then return end
    self:SetMissionData(selfId, define.MD_ENUM.MD_COST_CHU_HUN_YE, cost_chu_hun_ye)''')
            b=once(b,'        self:LuaFnDecItemLayCount(selfId, slot.pos, dec)',
                '        self:LuaFnDecItemLayCount(selfId, slot.pos, dec)\n        bound=bound or slot.bind')
            b=once(b,'        self:LuaFnDecItemLayCount(selfId, BagPosL, 1)',
                '        bound=bound or self:GetBagItemIsBind(selfId,BagPosL)\n        self:LuaFnDecItemLayCount(selfId, BagPosL, 1)')
            b=once(b,'    local ret = self:PetSoulXiShuXing(selfId, BagPosSoul, LockValue, LockColorCount)',
                '    if bound then item:set_is_bind(true) end\n    local ret = self:PetSoulXiShuXing(selfId, BagPosSoul, LockValue, LockColorCount, prepared)')
            return b
        return function(s,'osuzhou_yunshenshen:OnPetSoulXiShuXing',change=native)
    raise AssertionError(rel)
