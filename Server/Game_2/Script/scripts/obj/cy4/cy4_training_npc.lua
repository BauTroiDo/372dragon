-- Common menu extension for the four existing school teachers and Dali guides.
local config = require "cy_four_training_config"
local M = {}
local TRAINING_ROLES = {xinfa_teacher=true, Dali_inbound_travel=true, qinggong_teacher=true, ability_teacher=true}

function M.qinggong_menu(npc, selfId)
    if npc:GetMenPai(selfId) ~= npc.cfg.faction then return end
    npc:AddNumText("Học khinh công môn phái",12,11)
end

function M.ability_menu(npc, selfId, i)
    if npc:GetMenPai(selfId) ~= npc.cfg.faction then return end
    local school = config.factions[npc.cfg.faction]
    local row = school and school.abilities[i]
    if not row then return end
    npc:AddNumText("Học và nâng cấp "..row.name,12,19+i)
    if i == 1 then
        npc:AddNumText("Học công thức theo cấp nghề (đã gồm trong học phí)",12,30)
        npc:AddNumText("Mua nguyên liệu chế tạo",12,31)
    end
end
local pending = setmetatable({}, {__mode="k"})

function M.menu(npc, selfId)
    local c = npc.cfg
    if c.role ~= "xinfa_teacher" and c.role ~= "Dali_inbound_travel" then return end
    if npc:GetMenPai(selfId) ~= c.faction then return end
    if c.role == "Dali_inbound_travel" then npc:AddNumText("Học tâm pháp",12,13) end
    npc:AddNumText("Mua bí tịch và yếu quyết",12,10)
    npc:AddNumText("Học khinh công môn phái",12,11)
    npc:AddNumText("Học và nâng cấp nghề môn phái",12,12)
    npc:AddNumText("Học công thức theo cấp nghề (đã gồm trong học phí)",12,30)
    npc:AddNumText("Mua nguyên liệu chế tạo",12,31)
    npc:AddNumText("Mua vũ khí môn phái",12,32)
end

local function show(npc, selfId, targetId, kind, id)
    local human = npc:get_scene():get_obj_by_id(selfId)
    local q, reason = human:cy_four_training_quote(npc.cfg.faction, kind, id)
    pending[human] = nil
    if not q then npc:Say(selfId,targetId,reason); return end
    pending[human] = {faction=npc.cfg.faction,kind=kind,id=id,previous=q.previous,
        target=targetId,script=npc.script_id,expires=os.time()+60}
    npc:BeginEvent(npc.script_id)
    npc:AddText("Học "..q.name.." cấp "..q.level.." cần #{_EXCHG"..q.money
        .."} và "..q.exp.." kinh nghiệm. Tiền được trừ từ giao tử trước.")
    npc:AddNumText("Xác nhận học",6,22)
    npc:AddNumText("Trở về",8,23)
    npc:EndEvent()
    npc:DispatchEventList(selfId,targetId)
end

function M.event(npc,selfId,targetId,index)
    if index ~= 10 and index ~= 11 and index ~= 12 and index ~= 13
        and index ~= 20 and index ~= 21 and index ~= 22 and index ~= 23 and index ~= 30 and index ~= 31
        and index ~= 32 then return false end
    local c = npc.cfg
    if not TRAINING_ROLES[c.role] then return true end
    if npc:GetMenPai(selfId) ~= c.faction then
        npc:Say(selfId,targetId,"Ta chỉ truyền dạy cho đệ tử "..c.faction_name.."."); return true
    end
    local school = assert(config.factions[c.faction])
    if index == 30 then
        local human = npc:get_scene():get_obj_by_id(selfId)
        local ok, message = human:cy_four_crafting_learn(c.faction)
        npc:Say(selfId,targetId,message)
    elseif index == 31 then
        npc:DispatchShopItem(selfId,targetId,require("cy_four_crafting_config").material_shop)
    elseif index == 32 then
        npc:DispatchShopItem(selfId,targetId,school.weapon_shop)
    elseif index == 10 then
        npc:DispatchShopItem(selfId,targetId,school.shop)
    elseif index == 11 then
        show(npc,selfId,targetId,"qinggong",school.qinggong)
    elseif index == 12 then
        npc:BeginEvent(npc.script_id)
        npc:AddText("Chọn nghề muốn học hoặc nâng cấp. Mỗi lần học tăng một cấp theo bảng chi phí môn phái.")
        for i,row in ipairs(school.abilities) do npc:AddNumText(row.name,12,19+i) end
        npc:EndEvent();npc:DispatchEventList(selfId,targetId)
    elseif index == 13 then
        npc:DispatchXinfaLevelInfo(selfId,targetId,c.faction)
    elseif index == 20 or index == 21 then
        show(npc,selfId,targetId,"ability",school.abilities[index-19].id)
    elseif index == 22 then
        local human = npc:get_scene():get_obj_by_id(selfId)
        local q = pending[human];pending[human] = nil -- consume before a service call/yield
        if not q or q.target ~= targetId or q.script ~= npc.script_id or q.faction ~= c.faction
            or q.expires < os.time() then
            npc:Say(selfId,targetId,"Hãy chọn lại nội dung muốn học.");return true
        end
        local ok, message = human:cy_four_training_perform(c.faction,q.kind,q.id,q.previous)
        npc:Say(selfId,targetId,message)
    elseif index == 23 then
        pending[npc:get_scene():get_obj_by_id(selfId)] = nil
        npc:OnDefaultEvent(selfId,targetId)
    end
    return true
end

return M
