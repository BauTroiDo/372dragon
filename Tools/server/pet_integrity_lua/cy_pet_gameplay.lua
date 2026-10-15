-- Authoritative, non-yielding commit paths for Pet books/upgrades.
local M = {}
local rules = require 'cy_pet_rules'
local define = require 'define'
local guid_cls = require 'pet_guid'
local config = require 'configenginer':getinstance()
local skills = require 'skillenginer':getinstance()
local items = require 'human_item_logic'

function M.resolve(script, selfId, high, low, resting)
    if not rules.integer(high, 0, 4294967295) or not rules.integer(low, 0, 4294967295) then return nil end
    local human = script.scene:get_obj_by_id(selfId)
    if not human then return nil end
    local guid = guid_cls.new(); guid:set(high, low)
    local pet = human:get_pet_bag_container():get_pet_by_guid(guid)
    if not pet or pet:is_lock() or pet:is_in_exchange() then return nil end
    if resting and (guid == human:get_current_pet_guid() or guid == human:get_current_soul_melting_pet_guid()) then return nil end
    return pet, human, guid
end

-- Config access may yield on its FIRST load. All config is fetched BEFORE
-- resolving the object and inventory. Once resolved, commit uses local setters
-- and send-only notifications. No GUID generation / RPC can split this step.
function M.consume(human, slot, id, money)
    if not rules.integer(slot, 0, 199) or not rules.integer(money, 0, 2147483647) then return false end
    local bag = human:get_prop_bag_container()
    if bag.get_size then
        local size=bag:get_size()
        if type(size)=='table' and (slot<100 and slot>=size.prop or slot>=100 and slot>=100+size.material) then return false end
    end
    local item = bag:get_item(slot)
    if not item or item:get_index() ~= id or item:is_lock() or item:get_lay_count() < 1 then return false end
    if not human:check_money_with_priority(money) then return false end
    local ok = items:dec_item_lay_count({}, human, slot, 1)
    if not ok then return false end
    if money > 0 then human:cost_money_with_priority(money, 'CY Pet') end
    return true
end

local function material(human, ids)
    local bag=human:get_prop_bag_container()
    for _,id in ipairs(ids) do
        for pos=0,199 do
            local item=bag:get_item(pos)
            if item and item:get_index()==id and not item:is_lock() and item:get_lay_count()>0 then return pos,id end
        end
    end
end

function M.savvy(script,selfId,high,low,quick,assist_high,assist_low)
    local data=config:get_config('cy_pet_rules_data')
    local attrs=config:get_config('pet_attr_table')
    local pet,human,guid=M.resolve(script,selfId,high,low,true)
    if not pet then return false end
    local level=pet:get_wuxing()
    if not rules.integer(level,0,9) then return false end
    if quick then
        local price=data.quick_savvy[level]
        if not rules.integer(price,1,2147483647) or human:get_yuanbao()<price then return false end
        -- cost_yuanbao stores currency before its ranking RPC yields. Store
        -- the Pet first: both authoritative changes precede that first yield.
        pet:set_wuxing(10)
        human:cost_yuanbao(price,'CY Pet quick savvy')
        human:send_pet_detail(pet,human);return true
    end
    local prefix=assist_high~=nil and 'Compound_' or 'GenGu_'
    local cost=data[prefix..'cost_savvy'..level]
    local chance=data[(assist_high~=nil and 'Compound_succrate_savvy' or 'GenGu_success_savvy')..level]
    local down=data['Compound_leveldown_savvy'..level]
    if not rules.integer(cost,1,2147483647) or not rules.integer(chance,0,1000)
        or not rules.integer(down,0,level) or not human:check_money_with_priority(cost) then return false end
    if assist_high~=nil then
        local assist,owner,aguid=M.resolve(script,selfId,assist_high,assist_low,true)
        if not assist or owner~=human or aguid==guid or assist:have_equip() then return false end
        local mainrow,arow=attrs[pet:get_data_index()],attrs[assist:get_data_index()]
        local gengu=assist:get_attrib('gengu')
        if not mainrow or not arow or arow.is_baby_type or arow.is_var_type
            or arow.take_level<mainrow.take_level or not gengu or gengu<=0 or gengu<level then return false end
        -- Retain any Pet with extra systems rather than destroy its payload.
        for _,slot in pairs(assist.elf_slots or {}) do if (slot.activated or 0)~=0 then return false end end
        if not human:remove_pet({},aguid) then return false end
        human:cost_money_with_priority(cost,'CY Pet savvy compound')
    else
        -- CY consumes the bound low-grade pill before its unbound equivalent.
        local ids=level<3 and {30504038,30502000} or level<6 and {30502001} or {30502002}
        local pos,id=material(human,ids)
        if not pos or not M.consume(human,pos,id,cost) then return false end
    end
    local won=math.random(1000)<=chance
    pet:set_wuxing(won and level+1 or level-down)
    human:send_pet_detail(pet,human)
    return true,won
end

function M.lingxing(script,selfId,high,low,quick)
    local data=config:get_config('cy_pet_rules_data')
    local pet,human=M.resolve(script,selfId,high,low,true)
    if not pet or human:get_level()<15 or not pet:have_huan_hua() then return false end
    local level=pet:get_ling_xing()
    if not rules.integer(level,0,9) then return false end
    local rows=data.lingxing[pet:get_data_index()]
    local chance=rules.lingxing_chance(rows,pet:get_attrib('main_perception'),level)
    if not rules.integer(chance,0,100) then return false end
    if quick then
        local price=data.quick_lingxing[level]
        if not rules.integer(price,1,2147483647) or human:get_yuanbao()<price then return false end
        pet:set_ling_xing(10)
        human:cost_yuanbao(price,'CY Pet quick lingxing')
        human:send_pet_detail(pet,human);return true
    end
    local cost=data.lingxing_cost[level+1]
    local pos,id=material(human,data.lingxing_material)
    if not pos or not M.consume(human,pos,id,cost) then return false end
    local won=math.random(100)<=chance
    if won then pet:set_ling_xing(level+1) end
    human:send_pet_detail(pet,human)
    return true,won
end

function M.awaken(script,selfId,high,low,keep_model)
    local attrs=config:get_config('pet_attr_table')
    local rows=config:get_config('pet_huan_hua_table')
    local pet,human=M.resolve(script,selfId,high,low,true)
    if not pet or not rules.integer(keep_model,0,1) or pet:have_huan_hua()
        or pet:have_equip() or pet:get_wuxing()<5 then return false end
    local id=pet:get_data_index();local attr=attrs[id];local row=rows[id]
    if not attr or not row or not (attr.is_baby_type or attr.is_var_type)
        or keep_model==0 and attr.take_level<85 then return false end
    local target=row[keep_model==1 and 1 or 2]
    if not rules.integer(target,1,2147483647) or not attrs[target]
        or not rules.integer(row.cost,0,2147483647) then return false end
    for _,slot in pairs(pet.elf_slots or {}) do if (slot.activated or 0)~=0 then return false end end
    local pos,item=material(human,{30502005,30502006})
    if not pos or not M.consume(human,pos,item,row.cost) then return false end
    pet:set_huan_huad();pet:set_data_index(target)
    human:send_pet_detail(pet,human)
    return true
end

function M.study(script, selfId, execute)
    local books = config:get_config('pet_skill_book')
    local templates = config:get_config('skill_template')
    local rows = config:get_config('pet_study_skill_table')
    local data = config:get_config('cy_pet_rules_data')
    local attrs = config:get_config('pet_attr_table')
    local high = script:LuaFnGetHighSectionOfTargetPetGuid(selfId)
    local low = script:LuaFnGetLowSectionOfTargetPetGuid(selfId)
    local pet, human = M.resolve(script, selfId, high, low, true)
    if not pet then return false end
    local slot = script:LuaFnGetBagIndexOfUsedItem(selfId)
    if not rules.integer(slot, 0, 99) then return false end
    local item = human:get_prop_bag_container():get_item(slot)
    if not item or item:is_lock() or item:get_lay_count() < 1 then return false end
    local skillid = books[item:get_index()]
    if not skillid or not templates[skillid] then return false end
    -- Validation must not roll or replace a skill during the skill's condition
    -- check. Its one random decision is made only at activation time.
    local rng = execute and math.random or function() return 1 end
    local index, extend = rules.study(pet, skillid, function(id) return templates[id] end,
        rows, define.PET_SKILL_OPERATEMODE.PET_SKILL_OPERATE_NEEDOWNER, rng)
    local attr = attrs[pet:get_data_index()]
    local take_level = attr and attr.take_level
    local cost = extend and data.cost_ExtendCortrolByPlayer or data['cost_takelevel' .. tostring(take_level)]
    if index == nil or not rules.integer(cost, 0, 2147483647) or not human:check_money_with_priority(cost) then return false end
    if not execute then return true end
    if not M.consume(human, slot, item:get_index(), cost) then return false end
    pet:set_skill_by_index(index, skillid)
    human:send_pet_detail(pet, human)
    return true
end

function M.upgrade_info(script, selfId, high, low, index)
    local rows = config:get_config('pet_skill_level_up')
    local templates = config:get_config('skill_template')
    local pet, human = M.resolve(script, selfId, high, low, true)
    if not pet or not rules.integer(index, 0, 11) then return nil end
    local current = pet:get_skill_by_index(index)
    local row = current and rows[current]
    if not row then return nil end
    local target, item, cost, broadcast = row['升级后的珍兽技能ID'], row['需要消耗的物品ID'], row['需要消耗的金钱'], row['是否广播']
    if not templates[target] or target == current or not rules.integer(item, 1, 2147483647)
        or not rules.integer(cost, 0, 2147483647) then return nil end
    return pet, human, current, target, item, cost, broadcast
end

function M.upgrade(script, selfId, high, low, index, slot)
    local pet, human, current, target, item, cost = M.upgrade_info(script, selfId, high, low, index)
    if not pet or not M.consume(human, slot, item, cost) then return false end
    pet:set_skill_by_index(index, target)
    human:send_pet_detail(pet, human)
    return true
end

function M.upgrade_quick(script,selfId,high,low,index)
    local data=config:get_config('cy_pet_rules_data')
    local templates=config:get_config('skill_template')
    local pet,human=M.resolve(script,selfId,high,low,true)
    if not pet or not rules.integer(index,0,11) then return false end
    local row=data.skill_upgrade[pet:get_skill_by_index(index)]
    local target,price=row and row[5],row and row[6]
    if not templates[target] or not rules.integer(price,1,2147483647)
        or target==pet:get_skill_by_index(index) or human:get_yuanbao()<price then return false end
    pet:set_skill_by_index(index,target)
    human:cost_yuanbao(price,'CY Pet quick skill')
    human:send_pet_detail(pet,human)
    return true
end

return M
