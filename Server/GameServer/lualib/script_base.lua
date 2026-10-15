local pet_gameplay = require "cy_pet_gameplay"
local skynet = require "skynet"
local datacenter = require "skynet.datacenter"
local gbk = require "wire_charset"
local define = require "define"
local menpai_registry = require "menpai_registry"
local utils = require "utils"
local ScriptGlobal = require "scripts.ScriptGlobal"
local iostream = require "iostream"
local packet_def = require "game.packet"
local human_item_logic = require "human_item_logic"
local actionenginer = require "actionenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local configenginer = require "configenginer":getinstance()
local skillenginer = require "skillenginer":getinstance()
local shopenginer = require "shopenginer":getinstance()
local eventenginer = require "eventenginer":getinstance()
local playershopmanager = require "playershopmanager":getinstance()
local commisionshopmanager = require "commisionshopmanager":getinstance()
local petmanager = require "petmanager":getinstance()
local item_operator = require "item_operator":getinstance()
local item_cls = require "item"
local exterior_bonus = require "exterior_bonus"
local equip_dress_bonus = require "equip_dress_bonus"
local pet_guid_cls = require "pet_guid"
local class = require "class"
local script_base = class("script_base")

function script_base:set_scene(scene)
    self.scene = scene
end

function script_base:get_scene()
    return self.scene
end

function script_base:get_scene_id()
    return self:get_scene():get_id()
end

function script_base:GetName(targetId)
    local obj = self.scene.objs[targetId]
    assert(obj, targetId)
    return obj:get_name()
end

function script_base:LuaFnGetName(targetId)
    local obj = self.scene.objs[targetId]
    assert(obj, targetId)
    return obj:get_name()
end

function script_base:LuaFnGetGUID(selfId)
    local human = self:get_scene():get_obj_by_id(selfId)
    return human:get_guid()
end

function script_base:GetHp(targetId)
    local obj = self.scene.objs[targetId]
    return obj:get_attrib("hp")
end

function script_base:GetMaxHp(targetId)
    local obj = self.scene.objs[targetId]
    return obj:get_attrib("hp_max")
end

function script_base:RestoreHp(targetId)
    local obj = self.scene.objs[targetId]
    local max_hp = self:GetMaxHp(targetId)
    obj:set_hp(max_hp)
end

function script_base:GetRage(targetId)
    local obj = self.scene.objs[targetId]
    return obj:get_attrib("rage")
end

function script_base:GetMaxRage(targetId)
    local obj = self.scene.objs[targetId]
    return obj:get_attrib("rage_max")
end

function script_base:RestoreRage(targetId)
    local obj = self.scene.objs[targetId]
    local max_rage = self:GetMaxRage(targetId)
    obj:set_rage(max_rage)
end

function script_base:GetMp(targetId)
    local obj = self.scene.objs[targetId]
    return obj:get_attrib("mp")
end

function script_base:GetMaxMp(targetId)
    local obj = self.scene.objs[targetId]
    return obj:get_attrib("mp_max")
end

function script_base:RestoreMp(targetId)
    local obj = self.scene.objs[targetId]
    local max_mp = self:GetMaxMp(targetId)
    obj:set_mp(max_mp)
end

function script_base:RestoreRage(targetId)
    local obj = self.scene.objs[targetId]
    local max_rage = self:GetMaxRage(targetId)
    obj:set_rage(max_rage)
end

function script_base:GetSex(targetId)
    local obj = self.scene.objs[targetId]
    return obj:get_attrib("model")
end

function script_base:LuaFnGetSex(selfId)
    return self:GetSex(selfId)
end

function script_base:GetMenPai(targetId)
    local obj = self.scene.objs[targetId]
    return obj:get_menpai()
end

function script_base:LuaFnGetMenPai(targetId)
    return self:GetMenPai(targetId)
end

function script_base:GetLevel(selfId)
    local obj = self.scene.objs[selfId]
    return obj:get_attrib("level")
end

function script_base:GetMoney(selfId)
    local obj = self.scene.objs[selfId]
    return obj:get_attrib("money")
end

function script_base:LuaFnGetMoney(selfId)
    return self:GetMoney(selfId)
end

function script_base:GetYuanBao(selfId)
    local obj = self.scene.objs[selfId]
    return obj:get_yuanbao()
end

function script_base:GetBindYuanBao(selfId)
    return self.scene:get_obj_by_id(selfId):get_yuanbao()
end

function script_base:GetBankBagSize(selfId)
    local human = self:get_scene():get_obj_by_id(selfId)
    return human:get_bank_bag_size()
end

function script_base:SetBankBagSize(selfId, size)
    local human = self:get_scene():get_obj_by_id(selfId)
    human:set_bank_bag_size(size)
end

function script_base:GetPetBankBagSize(selfId)
    local human = self:get_scene():get_obj_by_id(selfId)
    return human:get_pet_bank_bag_size()
end

function script_base:SetPetBankBagSize(selfId, size)
    local human = self:get_scene():get_obj_by_id(selfId)
    human:set_pet_bank_bag_size(size)
end

function script_base:BeginEvent(script_id)
    self:reset()
    self.script_id = script_id
end

function script_base:LuaFnGetPropertyBagSpace(selfId)
    local obj = self.scene.objs[selfId]
    return obj:get_prop_bag_container():cal_item_space("prop")
end

function script_base:LuaFnJoinMenpai(selfId, menpai)
    local obj = self.scene.objs[selfId]
    if not obj then return false, "character_not_found" end
    local ready, reason = menpai_registry.check_join(define, menpai, obj:get_skill_list(), function(name)
        return configenginer:get_config(name)
    end)
    if not ready then return false, reason end
    -- CYS-STARTER: reserve all joining gifts before changing faction or skills.
    if obj:get_menpai() == menpai then return false, "already_joined" end
    local gifts_ok, starter = require("menpai_starter").prepare(self, obj, menpai)
    if not gifts_ok then return false, starter end
    local changed, change_reason = obj:set_menpai(menpai)
    if not changed then return false, change_reason end
    obj:change_menpai_points()
    obj:send_refresh_attrib()
    obj:clear_xinfa_list()
    local xinfa_list = obj:get_xinfa_list()
    local xinfa_v1 = configenginer:get_config("xinfa_v1")
    for _, id in ipairs(menpai_registry.xinfa_ids(xinfa_v1, menpai)) do
        local xinfa = xinfa_v1[id]
        if xinfa.menpai == menpai then
            if id ~= define.MENPAI_7_XINFA[menpai] and id ~= define.MENPAI_8_XINFA[menpai]  then
                table.insert(xinfa_list, {m_nXinFaID = id, m_nXinFaLevel = 1})
            end
        end
    end
    local msg = packet_def.GCDetailXinFaList.new()
    msg.m_aXinFa = xinfa_list
    msg.m_objID = obj:get_obj_id()
    msg.m_wNumXinFa = #xinfa_list
    msg.unknow = 26
    self.scene:send2client(selfId, msg)

    obj:clear_menpai_skills()
    local skill_list = obj:get_skill_list()
    local templates = skillenginer:get_skill_templates()
    for _, template in pairs(templates) do
        if (template.menpai == menpai and template.direct_study_up) then
            table.insert(skill_list, template.id)
        end
    end
    local yuangong_skill = define.MENPAI_JINZHAN_YUANGONG_SKILL[menpai]
    if yuangong_skill then
        obj:add_skill(yuangong_skill)
    end
    msg = packet_def.GCDetailSkillList.new()
    msg.m_objID = obj:get_obj_id()
    msg.m_aSkill = skill_list
    msg.m_wNumSkill = #skill_list
    self.scene:send2client(selfId, msg)


    local hp_max = obj:get_attrib("hp_max")
    local mp_max = obj:get_attrib("mp_max")
    obj:set_hp(hp_max)
    obj:set_mp(mp_max)

    local quick_setting_skills = {}
    for _, skill in ipairs(skill_list) do
        local template = skillenginer:get_skill_template(skill)
        if template.target_logic_by_stand == 1 and not template.is_passive then
            if template.xinfa ~= define.INVAILD_ID then
                local xinfa = obj:get_xinfa(template.xinfa)
                --print("xinfa =", table.tostr(xinfa), ";skill =", skill, ";template.xinfa_level_require =", template.xinfa_level_require)
                if xinfa and xinfa.m_nXinFaLevel >= template.xinfa_level_require then
                    table.insert(quick_setting_skills, skill)
                end
            end
        end
    end
    for _, skill in ipairs(quick_setting_skills) do
        local key = obj:get_empty_setting(define.SETTING_TYPE.SETTING_TYPE_K1, define.SETTING_TYPE.SETTING_TYPE_K9, {data = 0, type = 1})
        -- print("skill =", skill, ";key =", key)
        if key then
            obj:modify_setting(key, skill)
        end
    end
    obj:send_setting()
    if starter then
        self:AddItemListToHuman(selfId)
        obj:notify_tips("Đã nhận vũ khí Tân thủ của môn phái trong túi đồ.")
        skynet.logi("CYS-STARTER granted", obj:get_guid(), menpai, require("menpai_starter").weapons[menpai])
    end
    return true
end

function script_base:LuaFnSetXinFaLevel(selfId, xinfa, level)
    local obj = self.scene.objs[selfId]
    obj:study_xinfa(xinfa, level)
    local msg = packet_def.GCStudyXinfa.new()
    msg.spare_exp = obj:get_attrib("exp")
    msg.spare_money = obj:get_attrib("money")
    msg.now_level = level
    msg.xinfa = xinfa
    self.scene:send2client(selfId, msg)
end

function script_base:DispatchXinfaLevelInfo(selfId, targetId, menpai)
    local msg = packet_def.GCXinfaStudyInfo.new()
    msg.teacher = targetId
    msg.menpai = menpai
    self.scene:send2client(selfId, msg)
end

function script_base:DispatchShopItem(selfId, targetID, shop_id)
    local obj = self.scene.objs[selfId]
	if not obj or obj:get_obj_type() ~= "human" then
		return
	end
	local limit_shop_human = define.LIMIT_SHOP_HUMAN[shop_id]
	if limit_shop_human then
		if obj:get_game_flag_key(limit_shop_human) == 0 then
			obj:notify_tips("该商店你无法打开。")
			return
		end
	end
    local shop_mgr = shopenginer:get_static_shop_mgr()
    if not shop_mgr then
        skynet.logw("[script_base] static_shop_mgr chua san sang, scene=", tostring(self.scene and self.scene.id), " shop_id=", tostring(shop_id))
        return
    end
    local this_shop = shop_mgr:get_shop_by_id(shop_id)
	if not this_shop then
		return
	end
    obj:begin_shop(this_shop)
    local msg = packet_def.GCShopMerchandiseList.new()
    msg.m_objID = targetID
    msg.shop_type = this_shop.shop_type
    msg.merchandise_num = #this_shop.merchadise_list
    msg.shop_id = shop_id
    msg.sold_type = 1
    msg.is_yuanbao_shop = this_shop.is_yuanbao_shop
    msg.unique_id = shop_mgr:get_unique_id()
    for i = 1, msg.merchandise_num do
        local merchadise = {}
        local this_goods =  this_shop.merchadise_list[i]
        merchadise.id = this_goods.id
        merchadise.pnum = this_goods.pnum
        merchadise.yuanbao_price = this_goods.price
        merchadise.c_pmax = this_goods.pmax
        merchadise.pmax = this_goods.pmax
        merchadise.price = this_goods.price
        if merchadise.price ~= 0 then
            merchadise.discount = math.floor(this_goods.discount / merchadise.price * 100)
        else
            merchadise.discount = 100
        end
        table.insert(msg.merchadise_list, merchadise)
    end
    -- print("script_base:DispatchShopItem msg =", table.tostr(msg))
    self.scene:send2client(selfId, msg)
    obj:send_sold_out_list()
	if define.REGION_LIMITED_SHOP[shop_id] then
		local ranking_addr = skynet.localname(define.CACHE_NODE)
		if not ranking_addr then
			return
		elseif define.IS_KUAFU_SCENE[self.scene:get_id()] then
			return
		end
		local world_id = self:LuaFnGetServerID(selfId)
		local buy_counts = skynet.call(define.CACHE_NODE,"lua","update_limit_shop_buy_count",world_id,shop_id)
		if buy_counts then
			local msg = packet_def.GCMSShopBuyInfo.new()
			msg.size = 0
			msg.unknow_1 = {}
			msg.unknow_2 = {}
			for id, count in pairs(buy_counts) do
				table.insert(msg.unknow_1, tonumber(id))
				table.insert(msg.unknow_2, count)
				msg.size = msg.size + 1
			end
			if msg.size > 0 then
				self.scene:send2client(obj, msg)
			end
		end
		
    elseif this_shop.is_yuanbao_shop == 2 then
		obj:send_mystery_shop_info()
	end
end

function script_base:BuyMerchadiseByItemIndex(selfId, ItemIndex)
    local human = self.scene:get_obj_by_id(selfId)
    local shop_mgr = shopenginer:get_static_shop_mgr()
    if not shop_mgr then return end
    local sp, index, merchadise = shop_mgr:get_shop_by_shop_type_and_item_index(5, ItemIndex)
    if sp then
        human:begin_shop(sp)
        return index, merchadise
    end
end

function script_base:GetMerchadiseByItemIndex(selfId, ItemIndex)
    local human = self.scene:get_obj_by_id(selfId)
    local shop_mgr = shopenginer:get_static_shop_mgr()
    if not shop_mgr then return end
    local sp, index, merchadise = shop_mgr:get_shop_by_shop_type_and_item_index(5, ItemIndex)
    if sp then
        human:begin_shop(sp)
        return index, merchadise
    end
end

function script_base:DispatchYuanbaoShopItem(selfId, shop_id)
    local obj = self.scene.objs[selfId]
	if not obj or obj:get_obj_type() ~= "human" then
		return
	end
	local limit_shop_human = define.LIMIT_SHOP_HUMAN[shop_id]
	if limit_shop_human then
		if obj:get_game_flag_key(limit_shop_human) == 0 then
			obj:notify_tips("该商店你无法打开。")
			return
		end
	end
    local shop_mgr = shopenginer:get_static_shop_mgr()
    if not shop_mgr then
        skynet.logw("[script_base] static_shop_mgr chua san sang, scene=", tostring(self.scene and self.scene.id), " shop_id=", tostring(shop_id))
        return
    end
    local this_shop = shop_mgr:get_shop_by_id(shop_id)
	if not this_shop then
		return
	end
    obj:begin_shop(this_shop)
    local msg = packet_def.GCShopMerchandiseList.new()
    msg.m_objID = -1
    msg.shop_type = this_shop.shop_type
    msg.merchandise_num = #this_shop.merchadise_list
    msg.shop_id = shop_id
    msg.sold_type = -1
    msg.is_yuanbao_shop = 1--this_shop.is_yuanbao_shop
    msg.unique_id = shop_mgr:get_unique_id()
    for i = 1, msg.merchandise_num do
        local merchadise = {}
        local this_goods =  this_shop.merchadise_list[i]
        merchadise.id = this_goods.id
        merchadise.pnum = this_goods.pnum
        merchadise.yuanbao_price = this_goods.price
        merchadise.c_pmax = this_goods.pmax
        merchadise.pmax = this_goods.pmax
        merchadise.price = this_goods.price
        if merchadise.price ~= 0 then
            merchadise.discount = math.floor(this_goods.discount / merchadise.price * 100)
        else
            merchadise.discount = 100
        end
        table.insert(msg.merchadise_list, merchadise)
    end
    print("script_base:DispatchYuanbaoShopItem msg =", table.tostr(msg))
    self.scene:send2client(selfId, msg)
    msg = packet_def.GCShopSoldList.new()
    msg.merchandise_num = 0
    self.scene:send2client(selfId, msg)
end

function script_base:DispatchNpcYuanbaoShopItem(selfid, targetid, shop_id)
    self:DispatchYuanbaoShopItem(selfid, shop_id)
end

function script_base:reset()
    self.event = {}
    self.strs = {}
    self.indexs = {}
    self.types = {}
    self.script_ids = {}
    self.size = 0
    self.flags = {}
    self.items = {}
    self.m_aBonus = {}
    self.item_count = 0
    self.unknow_4_2 = define.INVAILD_ID
end

function script_base:AddText(txt)
    self.size = self.size + 1
    self.flags[self.size] = 2
    self.types[self.size] = 0
    self.indexs[self.size] = 0
    table.insert(self.strs, txt)
    table.insert(self.script_ids, self.script_id)
end

function script_base:AddNumText(txt, type, index)
    self.size = self.size + 1
    self.flags[self.size] = 1
    table.insert(self.strs, txt)
    table.insert(self.types, type)
    table.insert(self.indexs, index)
    table.insert(self.script_ids, self.script_id)
end

function script_base:TAddNumText(mission_index, ...)
    self.script_id = mission_index
    self:AddNumText(...)
end

function script_base:AddNumTextWithTarget(target, txt, type, index)
    self.size = self.size + 1
    self.flags[self.size] = 1
    table.insert(self.strs, txt)
    table.insert(self.types, type)
    table.insert(self.indexs, index)
    table.insert(self.script_ids, target)
end

-- CYS-QUEST (npc-quest): event-list texts > 255 bytes (CY Game.exe limit, GCScriptCommand reader 0x1408471d0)
-- are sent as items of <= 254 bytes + "\31"; the CY-Source client joins them. Docs/specs/net/npc-quest_vi.md.
local CYS_TEXT_MAX = 255
local CYS_CONT = "\31"

local function cys_split_text(s)
    if #s <= CYS_TEXT_MAX then return { s } end
    local out = {}
    local pos = 1
    while #s - pos + 1 > CYS_TEXT_MAX do
        local cut = pos + CYS_TEXT_MAX - 2 -- last byte of a 254-byte chunk
        -- never inside a UTF-8 sequence
        while cut > pos and (string.byte(s, cut + 1) or 0) >= 0x80 and (string.byte(s, cut + 1) or 0) < 0xC0 do
            cut = cut - 1
        end
        -- prefer ending after a space (readable even without the client join)
        local sp = cut
        while sp > pos + 127 and string.sub(s, sp, sp) ~= " " do sp = sp - 1 end
        if string.sub(s, sp, sp) == " " then cut = sp end
        out[#out + 1] = string.sub(s, pos, cut) .. CYS_CONT
        pos = cut + 1
    end
    out[#out + 1] = string.sub(s, pos)
    return out
end

function script_base:EndEvent()
    local spare = 16 - self.size
    for i = 1, self.size do
        local str = gbk.fromutf8(self.strs[i])
        local parts = { str }
        if self.flags[i] ~= 1 and #str > CYS_TEXT_MAX then
            parts = cys_split_text(str)
            while #parts - 1 > spare do table.remove(parts) end -- no free slot: keep what fits (as before: lost)
            spare = spare - (#parts - 1)
            if #parts > 0 then parts[#parts] = string.gsub(parts[#parts], CYS_CONT .. "$", "") end
        end
        for _, part in ipairs(parts) do
            local e = {}
            e.flag = self.flags[i]
            e.str = part
            e.type = self.types[i]
            e.index = self.indexs[i]
            e.script_id = self.script_ids[i] or self.script_id
            e.len = string.len(e.str)
            e.split = -1
            table.insert(self.event, e)
        end
    end
end

function script_base:TEndEvent()
    self:EndEvent()
end

function script_base:BeginUICommand()
    self.ui_command_args = { int = {}, str = {}}
end

function script_base:UICommand_AddInt(value)
    table.insert(self.ui_command_args.int, value)
end

function script_base:UICommand_AddStr(value)
    value = gbk.fromutf8(value) .. string.char(0)
    table.insert(self.ui_command_args.str, value)
end

function script_base:EndUICommand()

end

function script_base:DispatchUICommand(selfId, index)
    local msg = packet_def.GCUICommand.new()
    msg.m_Param = {}
    msg.m_Param.m_IntCount = #self.ui_command_args.int
    msg.m_Param.m_StrCount = #self.ui_command_args.str
    msg.m_Param.m_aIntValue = self.ui_command_args.int
    msg.m_Param.m_aStrValue = table.concat(self.ui_command_args.str)
    msg.m_Param.m_aStrOffset = {}
    local len = 0
    for i = 1, msg.m_Param.m_StrCount do
        local str_len = string.len(self.ui_command_args.str[i])
        len = str_len + len
        table.insert(msg.m_Param.m_aStrOffset, len - 1)
        print("DispatchUICommand str_len =", str_len)
    end
    msg.m_nUIIndex = index
    print("DispatchUICommand m_aStrOffset =", table.tostr(msg.m_Param.m_aStrOffset))
    self.scene:send2client(selfId, msg)
end

function script_base:DispatchEventList(selfId, targetId)
    local m_nCmdID = 0
    local ret = packet_def.GCScriptCommand.new()
    ret.m_nCmdID = m_nCmdID
    ret.event = self.event
    ret.target_id = targetId or define.INVAILD_ID
    ret.size = #ret.event
    self.scene:send2client(selfId, ret)
    self:reset()
end

function script_base:TDispatchEventList(...)
    self:DispatchEventList(...)
end

function script_base:DispatchMissionTips(selfId)
    local m_nCmdID = 5
    local ret = packet_def.GCScriptCommand.new()
    ret.m_nCmdID = m_nCmdID
    ret.event = {}
    ret.event.str = gbk.fromutf8(table.concat(self.strs, " "))
    ret.event.len = string.len(ret.event.str)
    self.scene:send2client(selfId, ret)
end

function script_base:DispatchMissionInfo(selfId, targetId, script_id, mission_id)
    local m_nCmdID = 1
    local ret = packet_def.GCScriptCommand.new()
    ret.m_nCmdID = m_nCmdID
    ret.event = self.event
    ret.target_id = targetId or define.INVAILD_ID
    ret.size = #ret.event
    ret.m_objID = script_id
    ret.m_idMission = mission_id
    ret.m_yBonusCount = #self.m_aBonus
    self.scene:send2client(selfId, ret)
end

function script_base:DispatchMissionDemandInfo(selfId, targetId, script_id, mission_id, done)
    local m_nCmdID = 3
    local ret = packet_def.GCScriptCommand.new()
    ret.m_nCmdID = m_nCmdID
    ret.event = self.event
    ret.target_id = targetId or define.INVAILD_ID
    ret.size = #ret.event
    ret.m_objID = script_id
    ret.m_idMission = mission_id
    ret.m_yDemandCount = 0
    ret.done = done
    self.scene:send2client(selfId, ret)
end

function script_base:GetBagItem(selfId, idBagPos)
    local obj = self.scene:get_obj_by_id(selfId)
    return obj:get_prop_bag_container():get_item(idBagPos)
end

function script_base:GetBagItemLayCount(selfId, BagPos)
    local obj = self.scene:get_obj_by_id(selfId)
    local item = obj:get_prop_bag_container():get_item(BagPos)
    if not item then
        return 0
    end
    return item:get_lay_count()
end

function script_base:GetBagItemIsBind(selfId, BagPos)
    local obj = self.scene:get_obj_by_id(selfId)
    local item = obj:get_prop_bag_container():get_item(BagPos)
    if not item then
        return false
    end
    return item:is_bind()
end

function script_base:GetBagItemIndex(selfId, BagPos)
    local obj = self.scene:get_obj_by_id(selfId)
    local item = obj:get_prop_bag_container():get_item(BagPos)
    if not item then
        return define.INVAILD_ID
    end
    return item:get_index()
end

function script_base:LuaFnIsItemAvailable(selfId, ItemPos)
    local item = self:GetBagItem(selfId, ItemPos)
    if not item then
        return false
    end
    return (not item:is_empty()) and (not item:is_lock())
end

function script_base:LuaFnItemBind(selfId, BagPos)
    local item = self:GetBagItem(selfId, BagPos)
    item:set_is_bind(true)

    local msg = packet_def.GCItemInfo.new()
    msg.bagIndex = BagPos
    msg.item = item:copy_raw_data()
    self:get_scene():send2client(selfId, msg)
end

function script_base:TryRecieveItem(selfId, ItemId, is_bind, quality, extra)
    local obj = self.scene:get_obj_by_id(selfId)
    local shoptype = 0
    local logparam = { reason = "脚本发放", user_name = obj:get_name(), user_guid = obj:get_guid(), func_name = "TryRecieveItem", script_id = self.script_id }
    local _, bag_index = human_item_logic:create_multi_item_to_bag(logparam, obj, ItemId, 1, is_bind, shoptype, quality, extra)
    return bag_index
end

function script_base:GetBagItemQuality(selfId, BagPos)
    local obj = self.scene:get_obj_by_id(selfId)
    local container = obj:get_prop_bag_container()
    local item = container:get_item(BagPos)
    if item == nil then
        return 0
    end
    if item:get_serial_class() == define.ITEM_CLASS.ICLASS_EQUIP then
        return item:get_equip_data():get_quality()
    elseif item:get_serial_class() == define.ITEM_CLASS.ICLASS_PET_EQUIP then
        return item:get_pet_equip_data():get_quality()
    else
        return 0
    end
end

function script_base:TryRecieveItemWithCount(selfId, ItemId, count, is_bind, param, way)
    local obj = self.scene:get_obj_by_id(selfId)
    local  quality = nil
    way = way or 0
    local logparam = { reason = "脚本发放", user_name = obj:get_name(), user_guid = obj:get_guid(), func_name = "TryRecieveItemWithCount", script_id = self.script_id, param = param }
    local _, bag_index = human_item_logic:create_multi_item_to_bag(logparam, obj, ItemId, count, is_bind, way, quality, param)
    return bag_index
end

function script_base:LuaFnStilettoCostExe(selfId, id, idBagPosStuff, slot_type,idBagPos)
    local obj = self.scene:get_obj_by_id(selfId)
	if not obj then
		return -99
	end
    local item = self:GetBagItem(selfId, idBagPos)
    if not item then
        return -98
    end
	local equip_data = item:get_equip_data()
    local slot_count = equip_data:get_slot_count()
	if slot_count >= 4 then
		return -97
	end
    local slot_cost = configenginer:get_config("slot_cost")
    local this_slot_cost = slot_cost[id]
    if not this_slot_cost then
        return -1
    end
    local cost = this_slot_cost.cost[slot_type]
    if not cost then
        return -1
    end
    local item_cost = cost.item
	if item_cost.id < 1 or item_cost.count < 1 then
		return -2
	end
    local stuff_item = self:GetBagItem(selfId, idBagPosStuff)
	if not stuff_item then
		return -2
	end
	local stuff_item_id = stuff_item:get_index()
    if stuff_item_id < item_cost.id and stuff_item_id > 20109015 then
		if stuff_item_id ~= 20310111 then
			return -2
		end
        -- return -2
    end
    local money = math.ceil(cost.money)
	if money < 1 then
		return -3
	end
    if stuff_item_id == 20310111 then
        money = 10000
    end
    local my_money = self:GetMoney(selfId) + self:GetMoneyJZ(selfId)
    if my_money < money then
        return -3
    end
    local logparam = {}
    local ret = human_item_logic:dec_item_lay_count(logparam, obj, idBagPosStuff, item_cost.count)
    if not ret then
        return -4
    end
    self:LuaFnCostMoneyWithPriority(selfId, money)
	item:set_is_bind(true)
	if slot_count < 3 then
		if math.random(100) % 2 == 0 then
			return -5
		end
	end
	equip_data:add_slot()
    local msg = packet_def.GCItemInfo.new()
    msg.bagIndex = idBagPos
    msg.item = item:copy_raw_data()
    self.scene:send2client(obj, msg)
    return 1
end

function script_base:LuaFnDecItemLayCount(selfId, BagPos, count)
    local obj = self.scene:get_obj_by_id(selfId)
    local logparam = {}
    return human_item_logic:dec_item_lay_count(logparam, obj, BagPos, count)
end

function script_base:AddBagItemSlot(selfId, idBagPos)
    local obj = self.scene:get_obj_by_id(selfId)
    local item = self:GetBagItem(selfId, idBagPos)
    if item == nil then
        return -3
    end
    local equip_data = item:get_equip_data()
    if equip_data == nil then
        return -3
    end
    local slot_count = equip_data:get_slot_count()
    if slot_count == nil or slot_count >= 3 then
        return -4
    end
    equip_data:add_slot()
    local msg = packet_def.GCItemInfo.new()
    msg.bagIndex = idBagPos
    msg.item = item:copy_raw_data()
    self.scene:send2client(obj, msg)
    return 1
end

function script_base:AddBagItemSlotFour(selfId, idBagPos)
    local obj = self.scene:get_obj_by_id(selfId)
    local item = self:GetBagItem(selfId, idBagPos)
    if item == nil then
        return -3
    end
    local equip_data = item:get_equip_data()
    if equip_data == nil then
        return -3
    end
    local slot_count = equip_data:get_slot_count()
    if slot_count == nil or slot_count >= 4 then
        return -4
    end
    equip_data:add_slot()
    local msg = packet_def.GCItemInfo.new()
    msg.bagIndex = idBagPos
    msg.item = item:copy_raw_data()
    self.scene:send2client(obj, msg)
    return 1
end

function script_base:LuaFnSendSpecificImpactToUnit(selfId, sender_id, reciver_id, impact_id, delaytime)
    local obj_me = self.scene:get_obj_by_id(selfId)
    local sender = self.scene:get_obj_by_id(sender_id)
    local reciver = self.scene:get_obj_by_id(reciver_id)
	if not reciver or not sender then
		return
	end
    impactenginer:send_impact_to_unit(reciver, impact_id, sender, delaytime, false, 0)
end

function script_base:MsgBox(selfId, targetId, str )
	self:BeginEvent(self.script_id)
        self:AddText(str)
        self:EndEvent()
    self:DispatchEventList(selfId, targetId )
end

function script_base:QueryHumanAbilityLevel(selfId, id)
    local human = self.scene:get_obj_by_id(selfId)
    assert(id)
    local ability = human:get_ability(id)
    return ability and ability.level or 0
end

function script_base:SetHumanAbilityLevel(selfId, id, level)
    local human = self.scene:get_obj_by_id(selfId)
    human:study_ability(id, 0, level)
end

function script_base:SetAbilityOperaTime(selfId, maxTime)
    local human = self.scene:get_obj_by_id(selfId)
    local abiltiy_opera = human:get_ability_opera()
    assert(type(maxTime) == "number", maxTime)
    abiltiy_opera.max_time = maxTime
end

function script_base:SetPrescription(selfId, id, flag)
    local human = self.scene:get_obj_by_id(selfId)
    human:study_prescription(id, flag)
end

function script_base:LuaFnIsPrescrLearned(selfId, id)
    local human = self.scene:get_obj_by_id(selfId)
    return human:is_prescription_have_learnd(id)
end

function script_base:IsPrescrLearned(selfId, id)
    return self:LuaFnIsPrescrLearned(selfId, id)
end

function script_base:GetMoneyJZ(selfId)
    local human = self.scene:get_obj_by_id(selfId)
    return human:get_attrib("jiaozi") or 0
end

function script_base:CostMoney(selfId, cost_money)
    assert(cost_money > 0, cost_money)
    local human = self.scene:get_obj_by_id(selfId)
    human:cost_money(cost_money, "CostMoney")
end

function script_base:CheckMoney(selfId,need_money)
    local human = self.scene:get_obj_by_id(selfId)
	assert(human,selfId)
	local have = (human:get_attrib("jiaozi") or 0) + human:get_attrib("money")
    if have >= need_money then
		return true
	end
	human:notify_tips("#{no_money}")
end

function script_base:LuaFnCostMoneyWithPriority(selfId, need_money)
    assert(need_money > 0, need_money)
    local human = self.scene:get_obj_by_id(selfId)
    return human:cost_money_with_priority(need_money, "LuaFnCostMoneyWithPriority")
end

function script_base:LuaFnCostYuanBao(selfId, count)
	assert(count >= 1,count)
    local human = self.scene:get_obj_by_id(selfId)
    human:cost_yuanbao(count, "LuaFnCostYuanBao")
end

function script_base:LuaFnCostBindYuanBao(selfId, count)
	assert(count >= 1,count)
    local human = self.scene:get_obj_by_id(selfId)
    human:cost_bind_yuanbao(count, "LuaFnCostBindYuanBao")
end

function script_base:BankBegin(selfId, targetId)
    local human = self.scene:get_obj_by_id(selfId)
    local msg = packet_def.GCBankBegin.new()
    msg.npc = targetId
    self.scene:send2client(human, msg)
end

function script_base:PetBankBegin(selfId, targetId)
    local human = self.scene:get_obj_by_id(selfId)
    require('cys_pet_bank').open(self.scene,human,targetId)
    local msg = packet_def.GCBankBegin.new()
    msg.unknow = 1
    msg.npc = targetId
    self.scene:send2client(human, msg)
    local pet_bag_size = human:get_pet_bag_size()
    local pet_bank_bag_size = human:get_pet_bank_bag_size()
    self:SendPacketStream(selfId, 5, { pet_bag_size, 0, 0, 0, pet_bank_bag_size, 0, 0, 0, 1 })
end

function script_base:CallScriptFunction(script_id, func_name, seflId, targetId, ...)
    return self:get_scene():get_script_engienr():call(script_id, func_name, seflId, targetId, ...)
end

function script_base:GetHumanMaxLevelLimit()
    return define.HUMAN_MAX_LEVEL
end

function script_base:SetPlayerDefaultReliveInfo(...)
    local args = { ... }
    local selfId, hp_percent, mp_percent, rage_percent, sceneid, x, y
    if #args == 7 then
        selfId, hp_percent, mp_percent, rage_percent, sceneid, x, y = table.unpack(args)
    elseif #args == 6 then
        selfId, hp_percent, mp_percent, rage_percent, x, y = table.unpack(args)
        sceneid = self:get_scene_id()
    else
        assert(false)
    end
    local human = self.scene:get_obj_by_id(selfId)
	assert(human,"script_base:SetPlayerDefaultReliveInfo 对象异常")
	if sceneid == 77 then
		local index = math.random(1,#define.SIWANG)
		sceneid = define.SIWANG[index] and define.SIWANG[index] or sceneid
	end
    local relive = {}
    relive.hp_recover_rate = hp_percent
    relive.mp_recover_rate = mp_percent
    relive.rage_recover_rate = rage_percent
    relive.sceneid = sceneid
    relive.world_pos = { x = x, y = y}
    human:set_relive_info(false, relive)
end

function script_base:SetPlayerDefaultReliveInfoEx(...)
    local args = { ... }
    local script_id = table.remove(args, #args)
    self:SetPlayerDefaultReliveInfo(table.unpack(args))
    local selfId = args[1]
    local human = self.scene:get_obj_by_id(selfId)
	assert(human,"script_base:SetPlayerDefaultReliveInfoEx 对象异常")
    human:set_on_relive_script_id(script_id)
end

function script_base:change_scene(selfId, sceneid, x, y)
    local human = self.scene:get_obj_by_id(selfId)
	assert(human,"script_base:change_scene 对象异常")
    human:get_scene():notify_change_scene(selfId, sceneid, x, y)
end

function script_base:LuaFnVerifyUsedItem(selfId)
    local human = self.scene:get_obj_by_id(selfId)
	assert(human,"script_base:LuaFnVerifyUsedItem 对象异常")
    return human:verify_item()
end

function script_base:LuaFnSendOResultToPlayer(selfId, result)
    local human = self.scene:get_obj_by_id(selfId)
	assert(human,"script_base:LuaFnSendOResultToPlayer 对象异常")
    return human:send_operate_result_msg(result)
end

function script_base:CheckSkillOnMonsterBox(selfId,targetId,skill_id)
    local human = self.scene:get_obj_by_id(selfId)
	assert(human,"script_base:CheckSkillOnMonsterBox 对象异常")
	local monster = self.scene:get_obj_by_id(targetId)
	if not monster then
		human:send_operate_result_msg(define.OPERATE_RESULT.OR_INVALID_TARGET)
		return
	elseif monster:is_die() then
		human:notify_tips("#{BJX_210720_27}")
		return
	elseif monster:get_obj_type() ~= "monster" then
		human:send_operate_result_msg(define.OPERATE_RESULT.OR_INVALID_TARGET)
		return
	elseif monster:get_need_skill() ~= skill_id then
		human:send_operate_result_msg(define.OPERATE_RESULT.OR_INVALID_SKILL)
		return
	end
	return true
end

function script_base:LuaFnSendAbilitySuccessMsg(selfId, ability_id, pres_id, product, result_num)
    local human = self.scene:get_obj_by_id(selfId)
	assert(human,"script_base:LuaFnSendAbilitySuccessMsg 对象异常")
    local msg = packet_def.GCAbilitySucc.new()
    msg.ability = ability_id
    msg.prescription = pres_id
    msg.item_index = product
    msg.num = result_num or 1
    human:get_scene():send2client(human, msg)
end

function script_base:LuaFnGetBagIndexOfUsedItem(selfId)
    local human = self.scene:get_obj_by_id(selfId)
	assert(human,"script_base:LuaFnGetBagIndexOfUsedItem 对象异常")
    local params = human:get_targeting_and_depleting_params()
    return params:get_bag_index_of_deplted_item()
end
function script_base:LuaFnCheckUseItem_UI(selfId,needitem)
	if not needitem or #needitem < 1 then
		return -1
	end
    local human = self.scene:get_obj_by_id(selfId)
    local params = human:get_targeting_and_depleting_params()
	local useid = params:get_item_index_of_deplted_item_uicall()
	if useid == define.INVAILD_ID then
		return -1
	end
	local usepos = params:get_bag_index_of_deplted_item_uicall()
	if usepos == define.INVAILD_ID then
		return -1
	end
	params:reset()
    local item = human:get_prop_bag_container():get_item(usepos)
	if not item then
		return -1
	elseif item:get_index() ~= useid then
		return -1
	end
	for _,j in ipairs(needitem) do
		if j == useid then
			return usepos
		end
	end
	return -1
end

function script_base:GetBagItemParam(selfId, bag_index, start, vtype)
    local human = self.scene:get_obj_by_id(selfId)
    local item = human:get_prop_bag_container():get_item(bag_index)
    return item:get_param(start, vtype)
end

function script_base:IncreaseHp(selfId, add_hp)
    local human = self.scene:get_obj_by_id(selfId)
    human:health_increment(add_hp, nil, false)
end

function script_base:IncreaseMp(selfId, add_mp)
    local human = self.scene:get_obj_by_id(selfId)
    human:mana_increment(add_mp, nil, false)
end

function script_base:SetBagItemParam(selfId, bag_index, start, value, vtype, update)
    local human = self.scene:get_obj_by_id(selfId)
	assert(human,"SetBagItemParam 对象不存在。")
    local item = human:get_prop_bag_container():get_item(bag_index)
	assert(item,"SetBagItemParam 道具不存在。")
    item:set_param(start, value, vtype)
	if update then
		local msg = packet_def.GCItemInfo.new()
		msg.bagIndex = bag_index
		msg.unknow_1 = 0
		msg.item = item:copy_raw_data()
		self.scene:send2client(selfId, msg)
	end
end

function script_base:EraseItem(selfId, bag_index)
    local human = self.scene:get_obj_by_id(selfId)
	assert(human,"EraseItem 对象不存在。")
    local container = human:get_prop_bag_container()
    local item = container:get_item(bag_index)
	if item then
		container:set_item(bag_index, nil)
		item = container:get_item(bag_index)
		if not item then
			local msg = packet_def.GCItemInfo.new()
			msg.bagIndex = bag_index
			msg.unknow_1 = 1
			msg.item = item_cls.new():copy_raw_data()
			self.scene:send2client(selfId, msg)
			return true
		end
	end
end

function script_base:LuaFnRefreshItemInfo(selfId, bag_index)
    local human = self.scene:get_obj_by_id(selfId)
    local container = human:get_prop_bag_container()
    local item = container:get_item(bag_index)
    local msg = packet_def.GCItemInfo.new()
    msg.bagIndex = bag_index
    msg.unknow_1 = item and 0 or 1
    msg.item = item and item:copy_raw_data() or item_cls.new():copy_raw_data()
    self.scene:send2client(selfId, msg)
end

function script_base:LuaFnDepletingUsedItem(selfId)
    local human = self.scene:get_obj_by_id(selfId)
    return human:depleting_used_item()
end

function script_base:GetPosition(selfId)
    local human = self.scene:get_obj_by_id(selfId)
    return human:get_world_pos()
end

function script_base:GetSceneID()
    return self.scene:get_id()
end

function script_base:SetCheDiFuLuData(selfId, index, sceneid, position)
    local human = self.scene:get_obj_by_id(selfId)
    human:set_chedifulu_data(index, sceneid, position)
end

function script_base:GetCheDiFuLuData(selfId, index)
    local human = self.scene:get_obj_by_id(selfId)
    return human:get_chedifulu_data(index)
end

function script_base:SetCheDiFuLuDataSelectIndex(selfId, Index)
    local human = self.scene:get_obj_by_id(selfId)
    human:set_chedifulu_data_select_index(Index)
end

function script_base:GetCheDiFuLuDataSelectIndex(selfId)
    local human = self.scene:get_obj_by_id(selfId)
    return human:get_chedifulu_data_select_index()
end

function script_base:UpdateCheDiFuLuUseTimes(selfId, BagPos, change_count)
    local human = self:get_scene():get_obj_by_id(selfId)
    local bag_container = human:get_prop_bag_container()
    local item = bag_container:get_item(BagPos)
    assert(item:get_index() == 30008121 or item:get_index() == 30008125, item:get_index())
    local count = self:GetBagItemParam(selfId, BagPos, 3, "uchar")
    local init = self:GetBagItemParam(selfId, BagPos, 4, "uchar")
    if init == 0 then
        count = 20
    end
    count = count + change_count
    count = count > 50 and 50 or count
    self:SetBagItemParam(selfId, BagPos, 3, count, "uchar")
    self:SetBagItemParam(selfId, BagPos, 4, 1, "uchar")
    local msg = packet_def.GCItemInfo.new()
    msg.bagIndex = BagPos
    msg.item = item:copy_raw_data()
    msg.bag_type = define.BAG_TYPE.bag
    self:get_scene():send2client(selfId, msg)
    self:BeginUICommand()
    self:UICommand_AddInt(count)
    self:EndUICommand()
    self:DispatchUICommand(selfId, 1122361)
end

function script_base:AuditPetSkillLevelUpAndCompound()

end

function script_base:GetCheDiFuLuUseTimes(selfId, BagPos)
    local count = self:GetBagItemParam(selfId, BagPos, 3, "uchar")
    local init = self:GetBagItemParam(selfId, BagPos, 4, "uchar")
    if init == 0 then
        count = 20
    end
    return count
end

function script_base:TelePort(selfId, x, y)
    local human = self.scene:get_obj_by_id(selfId)
	assert(human,"TelePort 对象缺失。")
    human:on_teleport( {x = x, y = y} )
end

function script_base:LuaFnHaveImpactOfSpecificDataIndex(selfId, data_index)
    local human = self.scene:get_obj_by_id(selfId)
	assert(human,"LuaFnHaveImpactOfSpecificDataIndex 对象缺失。")
    local list = human:get_impact_list()
    for _, imp in ipairs(list) do
        if imp:get_data_index() == data_index then
            return true
        end
    end
    return false
end

function script_base:LuaFnHaveImpactOfSpecificMutexId(selfId, mutex_id)
    local human = self.scene:get_obj_by_id(selfId)
	assert(human,"LuaFnHaveImpactOfSpecificMutexId 对象缺失。")
    local list = human:get_impact_list()
    for _, imp in ipairs(list) do
        if imp:get_mutex_id() == mutex_id then
            return true
        end
    end
    return false
end

function script_base:SetHumanExpRate(selfId,exp_rate)
    local human = self.scene:get_obj_by_id(selfId)
	assert(human,"SetHumanExpRate 对象缺失。")
	if not exp_rate or exp_rate < 0 then
		return
	end
	exp_rate = exp_rate / 100
	human:set_exp_rate(exp_rate)
end

function script_base:GetHumanDoubleExpMult(selfId)
    local human = self.scene:get_obj_by_id(selfId)
	assert(human,"GetHumanDoubleExpMult 对象缺失。")
	return human:get_double_exp_mult()
end

function script_base:ResetLimitShop(selfId,nshopid,nflag,ndate)
    local human = self.scene:get_obj_by_id(selfId)
	assert(human,"ResetLimitShop 对象缺失。")
	if not nshopid then
		for shopid,shop_flag in pairs(define.LIMIT_SHOP) do
			if shop_flag == nflag then
				human:reset_limit_shop(shopid,ndate)
			end
		end
	else
		if define.LIMIT_SHOP[nshopid] == nflag then
			human:reset_limit_shop(nshopid,ndate)
		end
	end
end

-- 2026-09-11: được 54 script Game_2 gọi (team.lua, allwar, guild...) nhưng chưa từng được định nghĩa -> lỗi nil method
function script_base:NotifyFailTips(selfId, tip)
    if tip and tip ~= "" then
        self:notify_tips(selfId, tip)
    end
end

function script_base:notify_tips(selfId, msg)
    local human = self.scene:get_obj_by_id(selfId)
    human:notify_tips(msg)
end

function script_base:GetDressSoulColorSlotBonus(selfId)
    local human = self.scene:get_obj_by_id(selfId)
    if not human then
        return 0
    end
    return equip_dress_bonus.get_soul_color_slot_bonus(human)
end

function script_base:HaveXinFa(selfId, xinfa_id)
    local human = self.scene:get_obj_by_id(selfId)
    local xinfa = human:get_xinfa(xinfa_id)
    return xinfa and xinfa.m_nXinFaLevel or define.INVAILD_ID
end

function script_base:AddXinFa(selfId, xinfa)
    local human = self.scene:get_obj_by_id(selfId)
    human:add_xinfa(xinfa)
end

function script_base:HaveSkill(selfId, skill)
    local human = self.scene:get_obj_by_id(selfId)
    return human:have_skill(skill)
end

function script_base:AddSkill(selfId, skill)
    local human = self.scene:get_obj_by_id(selfId)
    human:add_skill(skill)
    human:send_skill_list()
end

function script_base:DelSkill(selfId, skill)
    local human = self.scene:get_obj_by_id(selfId)
    human:del_skill(skill)
end

function script_base:LuaFnGetItemIndexOfUsedItem(selfId)
    local human = self.scene:get_obj_by_id(selfId)
    local params = human:get_targeting_and_depleting_params()
    return params:get_item_index_of_deplted_item()
end

function script_base:GetHumanWorldX(selfId)
    local human = self.scene:get_obj_by_id(selfId)
    return human:get_world_pos().x
end

function script_base:GetHumanWorldZ(selfId)
    local human = self.scene:get_obj_by_id(selfId)
    return human:get_world_pos().y
end

function script_base:AddMoney(selfId, money, addlog)
    local human = self.scene:get_obj_by_id(selfId)
	local loginfo = addlog or "AddMoney"
    human:add_money(money, loginfo)
end

function script_base:AddMoneyJZ(selfId, jiaozi, addlog)
    local human = self.scene:get_obj_by_id(selfId)
	local loginfo = addlog or "AddMoneyJZ"
    human:add_jiaozi(jiaozi, loginfo)
end

function script_base:AddBindYuanBao(selfId, yuanbao, addlog)
    local human = self.scene:get_obj_by_id(selfId)
	local loginfo = addlog or "AddBindYuanBao"
    human:add_bind_yuanbao(yuanbao, loginfo)
end

function script_base:Msg2Player(selfId, str, chat_type)
    print("script_base:Msg2Player", selfId, str, chat_type)
    local human = self.scene:get_obj_by_id(selfId)
    local msg = packet_def.GCChat.new()
    msg.ChatType = chat_type
    msg.Sourceid = selfId
    msg:set_source_name(human:get_name())
    str = gbk.fromutf8(str)
    msg:set_content(str)
    self.scene:send2client(human, msg)
end

function script_base:GetWorldPos(selfId)
    local human = self.scene:get_obj_by_id(selfId)
	assert(human,"script_base:GetWorldPos 缺失对象。")
    local world_pos = human:get_world_pos()
    return world_pos.x, world_pos.y
end

function script_base:LuaFnCreateMonster(monster_id, x, y, base_ai, ai_script, script_id, param_dir)
    return self.scene:create_temp_monster(monster_id, x, y, base_ai, ai_script, script_id, param_dir)
end

function script_base:SetCharacterDieTime(selfId, die_time)
    local obj = self.scene:get_obj_by_id(selfId)
	assert(obj,"script_base:SetCharacterDieTime 对象不存在。")
	if obj:get_obj_type() == "human" then
		skynet.logi("欲定时删除玩家 selfId = ", selfId, "stack =", debug.traceback())
		return
	end
    obj:set_die_time(die_time)
end

function script_base:SetCharacterTimer(selfId, delta_time)
    local obj = self.scene:get_obj_by_id(selfId)
    obj:set_script_timer(delta_time)
end

function script_base:SetUnitReputationID(selfId, monster_id, reputation)
    local obj = self.scene:get_obj_by_id(monster_id)
    obj:set_reputation(reputation)
end

function script_base:SetLevel(selfId, level)
    local obj = self.scene:get_obj_by_id(selfId)
    obj:set_level(level)
end

local SYSTEM_MESSAGE_PREFIX = "@*;SrvMsg;SCA:"

local function has_system_message_content(message)
    if type(message) ~= "string" then
        return false
    end

    local content = string.trim(message)
    if string.sub(content, 1, #SYSTEM_MESSAGE_PREFIX) == SYSTEM_MESSAGE_PREFIX then
        content = string.trim(string.sub(content, #SYSTEM_MESSAGE_PREFIX + 1))
    end

    return content ~= "" and content ~= "0" and content ~= "-1"
end

function script_base:BroadMsgByChatPipe(selfId, strText, chatType)
    if chatType == define.ENUM_CHAT_TYPE.CHAT_TYPE_SYSTEM and not has_system_message_content(strText) then
        return
    end
    local obj = self.scene:get_obj_by_id(selfId)
    local msg = packet_def.GCChat.new()
    msg.ChatType = chatType
    msg.Sourceid = selfId
    msg.unknow_2 = 1
    -- 正文长度保护: 防止超长transfer串导致客户端读包错位
    if string.len(strText) > 320 then
        strText = string.sub(strText, 1, 320)
    end
    msg:set_content(strText)
    if msg.ChatType == define.ENUM_CHAT_TYPE.CHAT_TYPE_GUILD then
        local guild_id = obj:get_guild_id()
        self:get_scene():send_guild(obj, "lua", "multicast", guild_id, msg.xy_id, msg)
    elseif msg.ChatType == define.ENUM_CHAT_TYPE.CHAT_TYPE_LEAGUE then
        local league_id = obj:get_confederate_id()
        self:get_scene():send_guild(obj, "lua", "league_multicast", league_id, msg.xy_id, msg)
    else
        local svrtype = skynet.getenv "svrtype"
        if svrtype == "Span" then
            local cluster = require "skynet.cluster"
            local nodes = utils.get_cluster_specific_server_by_server_alias(".world")
            for _, N in ipairs(nodes) do
                cluster.send(N, ".world", "multicast", msg)
            end
        else
            skynet.send(".world", "lua", "multicast", msg)
        end
    end
end

function script_base:GetTeamLeader(selfId)
    local obj = self.scene:get_obj_by_id(selfId)
    local team_info = obj:get_team_info()
    local leader = team_info:leader()
    return leader and leader.m_objID or define.INVAILD_ID
end

function script_base:GetTeamSize(selfId)
    local obj = self.scene:get_obj_by_id(selfId)
    return obj:get_team_info():get_team_member_count()
end

function script_base:LuaFnGetTeamSize(selfId)
    return self:GetTeamSize(selfId)
end

function script_base:GetNearHumanCount(selfId)
    local config_info = configenginer:get_config("config_info")
    local obj = self.scene:get_obj_by_id(selfId)
    if obj == nil then
        return 0
    end
    local position = obj:get_world_pos()
    local operate = {obj = obj, x = position.x, y = position.y, radious = config_info.Human.CanGetExpRange}
    local nearbys = self:get_scene():scan(operate)
    local humans = setmetatable({}, {__mode = "kv"})
    for _, n in ipairs(nearbys) do
        if n:get_obj_type() == "human" then
            table.insert(humans, n)
        end
    end
    obj:set_near_humans(humans)
    return #humans
end

function script_base:GetNearHuman(selfId, i)
    local monster = self:get_scene():get_obj_by_id(selfId)
    local humans = monster:get_near_humans()
    return humans[i]:get_obj_id()
end

function script_base:GetNearTeamCount(selfId)
    local config_info = configenginer:get_config("config_info")
    local obj = self.scene:get_obj_by_id(selfId)
    if obj:get_obj_type() == "pet" then
        obj = obj:get_owner()
    end
    if not obj then
        return 0
    end
	local team_id = obj:get_team_id()
	if team_id == define.INVAILD_ID then
		return 0
	end
    local position = obj:get_world_pos()
    local operate = {obj = obj, x = position.x, y = position.y, radious = config_info.Human.CanGetExpRange}
    local nearbys = self:get_scene():scan(operate)
    -- print("caculate_owner_list nearbys =", #nearbys)
	local owners = {selfId}
	local obj_id
    -- local owners = setmetatable({}, {__mode = "kv"})
    for _, n in ipairs(nearbys) do
        if n:get_obj_type() == "human" then
            -- print("script_base:GetNearTeamCount n =", n:get_name(), ";n:get_team_id() =", n:get_team_id(), ";obj:get_team_id() =", obj:get_team_id())
            obj_id = n:get_obj_id()
			if obj_id ~= selfId and n:get_team_id() == team_id then
                table.insert(owners,obj_id)
            end
        end
    end
    -- for i, o in ipairs(owners) do
        -- if o:get_obj_id() == selfId then
            -- table.insert(owners, 1, table.remove(owners, i))
            -- break
        -- end
    -- end
    obj:set_near_team_members(owners)
    return #owners
end

function script_base:GetNearTeamMember(selfId,i,back_flag)
	local scene = self:get_scene()
    local human = scene:get_obj_by_id(selfId)
	assert(human,"script_base:GetNearTeamMember 对象缺失。")
    local owners = human:get_near_team_members()
	human = scene:get_obj_by_id(owners[i])
	if back_flag then
		if human then
			return owners[i]
		else
			return -1
		end
	end
	assert(human,"script_base:GetNearTeamMember 获取的队伍成员对象已离开场景。")
	return owners[i]
    -- return owners[i]:get_obj_id()
end

function script_base:LuaFnGetSceneSafeLevel()
    local sceneid = self.scene:get_id()
    local scene_attr = configenginer:get_config("scene_attr")
    return scene_attr[sceneid].safe_level
end

function script_base:GetSceneName(nsceneid)
	local sceneid = nsceneid
	if not sceneid then
		sceneid = self.scene:get_id()
	end
    -- local sceneid = self.scene:get_id()
    local scene_attr = configenginer:get_config("scene_attr")
    return scene_attr[sceneid].name
end

function script_base:LuaFnGetSceneType()
    return self.scene:get_type()
end

function script_base:GetSceneType()
    return self.scene:get_type()
end

function script_base:GetBagPosByItemSn(selfId, itemSn)
    local obj = self.scene:get_obj_by_id(selfId)
    return obj:get_prop_bag_container():get_item_pos_by_type(itemSn)
end

function script_base:GetBagItemTransfer(selfId, BagPos)
    local obj = self.scene:get_obj_by_id(selfId)
    local item = obj:get_prop_bag_container():get_item(BagPos)
    return item:get_transfer()
end

function script_base:GetItemQuality(product_id)
    return human_item_logic:get_serial_quality(product_id)
end

function script_base:GetDressColorRate(selfId, pos)
    local obj = self.scene:get_obj_by_id(selfId)
    local item = obj:get_prop_bag_container():get_item(pos)
    local item_index = item:get_index()
    local dress_color_rate = configenginer:get_config("dress_color_rate")
    return dress_color_rate[item_index]
end

function script_base:GetItemTableIndexByIndex(selfId, pos)
    local obj = self.scene:get_obj_by_id(selfId)
    local item = obj:get_prop_bag_container():get_item(pos)
    if item == nil then
        return define.INVAILD_ID
    end
    return item:get_index()
end

function script_base:GetItemEquipPoint(item_index)
    local equip_base = configenginer:get_config("equip_base")
    return equip_base[item_index].equip_point
end

function script_base:GeEquipReqLevel(ItemIndex)
    local equip_base = configenginer:get_config("equip_base")
    return equip_base[ItemIndex].level
end

function script_base:LuaFnGetAvailableItemCount(selfId, item_index)
    local obj = self.scene:get_obj_by_id(selfId)
    return human_item_logic:calc_bag_item_count(obj, item_index)
end

function script_base:LuaFnSetEquipVisual(selfId, pos, visual)
    assert(visual)
    local obj = self.scene:get_obj_by_id(selfId)
    local item = obj:get_prop_bag_container():get_item(pos)
    item:get_equip_data():set_visual(visual)
    self:LuaFnRefreshItemInfo(selfId, pos)
end

function script_base:LuaFnGetEquipVisual(selfId, pos)
    local obj = self.scene:get_obj_by_id(selfId)
    local item = obj:get_prop_bag_container():get_item(pos)
    return item:get_equip_data():get_visual()
end

function script_base:LuaFnDelAvailableItem(selfId, item_index, count)
    local obj = self.scene:get_obj_by_id(selfId)
    local logparam = {}
    return human_item_logic:del_available_item(logparam, obj, item_index, count)
end

function script_base:HaveThisHeadImage(selfId, id)
    local obj = self.scene:get_obj_by_id(selfId)
    return obj:have_this_head_image(id)
end

function script_base:HaveThisFaceStyle(selfId, id)
    local obj = self.scene:get_obj_by_id(selfId)
    return obj:have_this_face_style(id)
end

function script_base:HaveThisHairStyle(selfId, id)
    local obj = self.scene:get_obj_by_id(selfId)
    return obj:have_this_hair_style(id)
end

function script_base:HaveThisRide(selfId, id)
    local obj = self.scene:get_obj_by_id(selfId)
    return obj:have_this_ride(id)
end

function script_base:ChangePlayerHeadImage(selfId, id)
    local exterior_head = configenginer:get_config("exterior_head")
    local obj = self.scene:get_obj_by_id(selfId)
    local ret = obj:unlock_exterior_head(id)
    local sex = obj:get_attrib("model")
    local this_head = exterior_head[id]
    local this_sex_head = this_head[sex]
    local portrait_id = this_sex_head
    obj:set_exterior_portrait_index(id)
    obj:set_portrait_id(portrait_id)
    return ret
end

function script_base:ChangePlayerFaceModel(selfId, id)
    local exterior_face = configenginer:get_config("exterior_face")
    local obj = self.scene:get_obj_by_id(selfId)
    local ret = obj:unlock_exterior_face(id)
    local sex = obj:get_attrib("model")
    local this_face = exterior_face[id]
    local this_sex_face = this_face[sex]
    local face_style = this_sex_face
    obj:set_exterior_face_style_index(id)
    obj:set_face_style(face_style)
    return ret
end

function script_base:ChangePlayerHairModel(selfId, id)
    local exterior_hair = configenginer:get_config("exterior_hair")
    local obj = self.scene:get_obj_by_id(selfId)
    local ret = obj:unlock_exterior_hair(id)
    local sex = obj:get_attrib("model")
    local this_hair = exterior_hair[id]
    local this_sex_hair = this_hair[sex]
    local hair_style = this_sex_hair
    obj:set_exterior_hair_style_index(id)
    obj:set_hair_style(hair_style)
    -- 与外观界面保持相同顺序：先更新发型，再同步该角色保存的发色方案。
    obj:send_refresh_attrib()
    obj:send_exterior_info(5)
    return ret
end

function script_base:UnlockPlayerPoss(selfId, id)
    local exterior_poss = configenginer:get_config("exterior_poss")
    local human = self:get_scene():get_obj_by_id(selfId)
    local ret = human:unlock_exterior_poss(id)
    return ret
end

function script_base:GetExteriorPossConfig(id)
    local exterior_poss = configenginer:get_config("exterior_poss")
    exterior_poss = exterior_poss[id]
    return exterior_poss.CostMoney, exterior_poss.MaterialId, exterior_poss.MaterialCount
end

function script_base:ChangePlayerRide(selfId, ride)
    local obj = self.scene:get_obj_by_id(selfId)
    obj:set_ride(ride)
end
function script_base:DelPlayerRide(selfId, ride)
    local obj = self.scene:get_obj_by_id(selfId)
	if not obj:have_this_ride(ride) then
		self:notify_tips(selfId,"你没有此坐骑")
		return
    elseif not obj:reverse_ride(ride) then
		self:notify_tips(selfId,"坐骑删除失败")
	end
end

function script_base:GetChangeFaceItemIdAndItemCount(styleId)
    local exterior_face = configenginer:get_config("exterior_face")
    local char_face_geo = configenginer:get_config("char_face_geo")
    local face = exterior_face[styleId]
    local face_style = face[0]
    local geo = char_face_geo[face_style]
    return geo.cost_item_id, geo.cost_item_count, geo.cost_money
end

function script_base:GetChangeHairItemIdAndItemCount(styleId)
    local exterior_hair = configenginer:get_config("exterior_hair")
    local char_hair_geo = configenginer:get_config("char_hair_geo")
    local hair = exterior_hair[styleId]
    local geo = char_hair_geo[hair[0]]
    return geo.cost_item_id, geo.cost_item_count, geo.cost_money
end

function script_base:LuaFnGetItemPosByItemDataID(selfId, itemIndex)
    local obj = self.scene:get_obj_by_id(selfId)
    return human_item_logic:get_item_pos_by_type(obj, itemIndex)
end

function script_base:LuaFnGetExteriorRideIDByVisual(visual)
    -- CYS-RIDE-FINISH: CY co 10 模型索引 dung chung cho 2-3 dong ride (紫电 47/232, 玄天狐 173/仿·175 ...).
    -- pairs() tra dong NGAU NHIEN => cung mot item cap ride khac nhau moi lan. Chon xac dinh:
    -- uu tien 门派 == -1 (ai cung dung duoc), roi id nho nhat (47 nam trong RideCollection, 232 thi khong).
    local exterior_ride = configenginer:get_config("exterior_ride")
    local best
    for _, er in pairs(exterior_ride) do
        if er.model == visual then
            if not best
            or ((er.menpai == -1) and (best.menpai ~= -1))
            or (((er.menpai == -1) == (best.menpai == -1)) and er.id < best.id) then
                best = er
            end
        end
    end
    return best and best.id
end

function script_base:CheckHaveExteriorRide(selfId,index)
    local obj = self.scene:get_obj_by_id(selfId)
	if not obj then return end
	return obj:have_this_ride(index)
end

function script_base:LuaFnReverseExteriorRideToItemEx(selfId,index)
    local obj = self.scene:get_obj_by_id(selfId)
	if not obj then return end
    local exterior_ride = configenginer:get_config("exterior_ride")
	if exterior_ride[index] then
		local itemid = exterior_ride[index].back_item
		local itemname = self:GetItemName(itemid)
		if itemname == -1 then
			return itemname
		end
		-- local del_ride = obj:reverse_ride(ride)
		-- if del_ride.term ~= -1 then
			-- local now = os.time()
			
			
			
			
		-- del_ride.term > now then
		
		if obj:reverse_ride(ride) then
			
		
		
		
		
		
			return itemid,itemname
		else
			return -2
		end
	end
	return -3
end

function script_base:LuaFnAddRideRxpirationTime(selfId, index, add)
    local obj = self.scene:get_obj_by_id(selfId)
    local ret = obj:add_expiration_time(index, add)
    obj:send_exterior_info()
    -- 坐骑收藏列表变动，刷新外观属性加成
    exterior_bonus.refresh_bonus(obj)
    return ret
end

function script_base:GetEquipCanAddRxpirationTime(selfId, BagPos)
    local obj = self.scene:get_obj_by_id(selfId)
	if not obj then return end
    local item = obj:get_prop_bag_container():get_item(BagPos)
	if not item then return end
    return item:get_can_add_expairation_time()
end

function script_base:LuaFnGetCurrentTime()
    return os.time()
end

function script_base:DEGetPreTime(selfId)
    local obj = self.scene:get_obj_by_id(selfId)
    local double_exp_info = obj:get_double_exp_info()
    return double_exp_info.rtime
end

function script_base:DEResetWeeklyFreeTime(selfId)
    local obj = self.scene:get_obj_by_id(selfId)
    local double_exp_info = obj:get_double_exp_info()
    double_exp_info.rtime = os.time()
    double_exp_info.available_hour = 5
    double_exp_info.free_time = 0
end

function script_base:DEIsLock(selfId)
    local obj = self.scene:get_obj_by_id(selfId)
    local double_exp_info = obj:get_double_exp_info()
    return double_exp_info.is_lock
end

function script_base:DEGetFreeTime(selfId)
    local obj = self.scene:get_obj_by_id(selfId)
    local double_exp_info = obj:get_double_exp_info()
    return double_exp_info.free_time
end

function script_base:DEGetMoneyTime(selfId)
    local obj = self.scene:get_obj_by_id(selfId)
    local double_exp_info = obj:get_double_exp_info()
    return double_exp_info.money_time
end

function script_base:DESetLock(selfId, is_lock)
    local obj = self.scene:get_obj_by_id(selfId)
    local double_exp_info = obj:get_double_exp_info()
    double_exp_info.is_lock = is_lock
end

function script_base:SendDoubleExpToClient(selfId)
    local obj = self.scene:get_obj_by_id(selfId)
    obj:send_double_exp_info()
end

function script_base:DEGetCount(selfId)
    local obj = self.scene:get_obj_by_id(selfId)
    local double_exp_info = obj:get_double_exp_info()
    return double_exp_info.available_hour
end

function script_base:WithDrawFreeDoubleExpTime(selfId, hour)
    local obj = self.scene:get_obj_by_id(selfId)
    local double_exp_info = obj:get_double_exp_info()
    if double_exp_info.available_hour >= hour then
        double_exp_info.available_hour = double_exp_info.available_hour - hour
        double_exp_info.free_time = double_exp_info.free_time + hour * 60 * 60
    end
end

function script_base:DEGetMoneyTime(selfId)
    local obj = self.scene:get_obj_by_id(selfId)
    local double_exp_info = obj:get_double_exp_info()
    return double_exp_info.money_time
end

function script_base:DESetMoneyTime(selfId, money_time)
    local obj = self.scene:get_obj_by_id(selfId)
    local double_exp_info = obj:get_double_exp_info()
    double_exp_info.money_time = money_time
end

function script_base:TryCreatePet(selfId, count)
    local obj = self.scene:get_obj_by_id(selfId)
    local space_count = obj:get_pet_bag_container():cal_item_space()
    return space_count >= count
end

function script_base:GetIsPetID(data_id)
    local pet_attr_table = configenginer:get_config("pet_attr_table")
    return pet_attr_table[data_id]
end


function script_base:GetPetTakeLevel(data_id)
    local pet_attr_table = configenginer:get_config("pet_attr_table")
    return pet_attr_table[data_id].take_level
end

function script_base:LuaFnCreatePetToHuman(selfId, pet_data_id, is_rmb, grow_rate, petGUID_L)
    local obj = self.scene:get_obj_by_id(selfId)
    return obj:add_pet_by_data_id(pet_data_id, is_rmb, grow_rate, petGUID_L)
end

function script_base:LuaFnGetHighSectionOfTargetPetGuid(selfId)
    local obj = self.scene:get_obj_by_id(selfId)
    local params = obj:get_targeting_and_depleting_params()
    local pet_guid = params:get_target_pet_guid()
    return pet_guid.m_uHighSection
end

function script_base:LuaFnGetLowSectionOfTargetPetGuid(selfId)
    local obj = self.scene:get_obj_by_id(selfId)
    local params = obj:get_targeting_and_depleting_params()
    local pet_guid = params:get_target_pet_guid()
    return pet_guid.m_uLowSection
end

function script_base:LuaFnGetPetHP(selfId, petGUID_H, petGUID_L)
    local obj = self.scene:get_obj_by_id(selfId)
    local container = obj:get_pet_bag_container()
    local guid = pet_guid_cls.new()
    guid:set(petGUID_H, petGUID_L)
    local pet_detail = container:get_pet_by_guid(guid)
    return pet_detail:get_hp()
end

function script_base:LuaFnGetPetLevelByGUID(selfId, petGUID_H, petGUID_L)
    local obj = self.scene:get_obj_by_id(selfId)
    local container = obj:get_pet_bag_container()
    local guid = pet_guid_cls.new()
    guid:set(petGUID_H, petGUID_L)
    local pet_detail = container:get_pet_by_guid(guid)
    return pet_detail:get_level()
end

function script_base:LuaFnGetPetSpouseGUIDByGUID(selfId, petGUID_H, petGUID_L)
    local obj = self.scene:get_obj_by_id(selfId)
    local container = obj:get_pet_bag_container()
    local guid = pet_guid_cls.new()
    guid:set(petGUID_H, petGUID_L)
    local pet_detail = container:get_pet_by_guid(guid)
    local spouse_guid = pet_detail:get_spouse_guid()
    return spouse_guid.m_uHighSection, spouse_guid.m_uLowSection
end

function script_base:LuaFnGetPetTypeByGUID(selfId, petGUID_H, petGUID_L)
    local obj = self.scene:get_obj_by_id(selfId)
    local container = obj:get_pet_bag_container()
    local guid = pet_guid_cls.new()
    guid:set(petGUID_H, petGUID_L)
    local pet_detail = container:get_pet_by_guid(guid)
    return self:GetPetTypeByDetail(pet_detail)
end

function script_base:GetPetTypeByDetail(pet_detail)
    if pet_detail == nil then
        return define.INVAILD_ID
    end
    local pet_data_id = pet_detail:get_data_index()
    local pet_attr_table = configenginer:get_config("pet_attr_table")
    local pet_attr = pet_attr_table and pet_attr_table[pet_data_id]
    if pet_attr then
        if pet_attr.is_var_type then
            return define.PET_TYPE.PET_TYPE_VARIANCE
        elseif pet_attr.is_baby_type then
            return define.PET_TYPE.PET_TYPE_BABY
        else
            return define.PET_TYPE.PET_TYPE_WILENESS
        end
    end
    return pet_detail:get_by_type()
end

function script_base:LuaFnGetPetDataIDByGUID(selfId, petGUID_H, petGUID_L)
    local obj = self.scene:get_obj_by_id(selfId)
    local container = obj:get_pet_bag_container()
    local guid = pet_guid_cls.new()
    guid:set(petGUID_H, petGUID_L)
    local pet_detail = container:get_pet_by_guid(guid)
    return pet_detail:get_data_index()
end

function script_base:LuaFnGetPetHuanTongCost(take_level)
    local pet_huantong_cost = configenginer:get_config("pet_huantong_cost")
    pet_huantong_cost = pet_huantong_cost[take_level]
    return pet_huantong_cost["升级经验"]
end

function script_base:LuaFnGetPetMaxHP(selfId, petGUID_H, petGUID_L)
    local obj = self.scene:get_obj_by_id(selfId)
    local container = obj:get_pet_bag_container()
    local guid = pet_guid_cls.new()
    guid:set(petGUID_H, petGUID_L)
    local pet_detail = container:get_pet_by_guid(guid)
    return pet_detail:get_max_hp()
end
function script_base:LuaFnGetPetAllocationPoint(selfId, petGUID_H, petGUID_L)
    local obj = self.scene:get_obj_by_id(selfId)
    local container = obj:get_pet_bag_container()
    local guid = pet_guid_cls.new()
    guid:set(petGUID_H, petGUID_L)
    local pet_detail = container:get_pet_by_guid(guid)
	return pet_detail:petaddpoint()
end
function script_base:LuaFnResetPetPoint(selfId, petGUID_H, petGUID_L)
    local obj = self.scene:get_obj_by_id(selfId)
    local container = obj:get_pet_bag_container()
    local guid = pet_guid_cls.new()
    guid:set(petGUID_H, petGUID_L)
    local pet_detail = container:get_pet_by_guid(guid)
	local isok = pet_detail:reseting_attr()
	if isok == 0 then
		self:notify_tips(selfId,"珍兽潜能点重置成功")
	else
		self:notify_tips(selfId,"该珍兽没有记录的配置点数")
	end
end

function script_base:LuaFnGetPetGrowRateByGUID(selfId, petGUID_H, petGUID_L)
    local grow_rate = self:LuaFnGetPeGrowthRate(selfId, petGUID_H, petGUID_L) * 1000
    local pet_attr_table = configenginer:get_config("pet_attr_table")
    local data_id = self:GetPetDataID(selfId, petGUID_H, petGUID_L)
    pet_attr_table = pet_attr_table[data_id]
    assert(pet_attr_table, data_id)
    local growth_rate_table = pet_attr_table.growth_rate
    for i = 5, 1, -1 do
        local gr = growth_rate_table[i]
        if math.floor(grow_rate) >= gr then
            return i
        end
    end
    return 1
end

function script_base:GetPetPerceptionLevel(selfId, petGUID_H, petGUID_L)
    local obj = self.scene:get_obj_by_id(selfId)
    local container = obj:get_pet_bag_container()
    local guid = pet_guid_cls.new()
    guid:set(petGUID_H, petGUID_L)
    local pet_detail = container:get_pet_by_guid(guid)
    local collection = define.PET_SOUL_MELTING_INFLUENCE_PERCEPTION[0]
    local max_perception = pet_detail:get_max_perception_in_collection(collection)
    local pet_attr_table = configenginer:get_config("pet_attr_table")
    local data_id = self:GetPetDataID(selfId, petGUID_H, petGUID_L)
    pet_attr_table = pet_attr_table[data_id]
    local std_percption = { pet_attr_table.str_perception, 
    pet_attr_table.con_perception, pet_attr_table.spr_perception, 
    pet_attr_table.dex_perception, pet_attr_table.int_perception}
    local max_std_percption
    for i = 1, 5 do
        if max_std_percption == nil or std_percption[i] > max_std_percption then
            max_std_percption = std_percption[i]
        end
    end
    local diff = (max_perception - max_std_percption) / max_std_percption
    local level = math.ceil((diff) / 0.61 * 10)
    print("level =", level)
    return level
end

function script_base:LuaFnSetPetTitle(selfId, petGUID_H, petGUID_L, nTitle)
    local obj = self.scene:get_obj_by_id(selfId)
    local container = obj:get_pet_bag_container()
    local guid = pet_guid_cls.new()
    guid:set(petGUID_H, petGUID_L)
    local pet_detail = container:get_pet_by_guid(guid)
    local result = pet_detail:set_title(nTitle)
    pet_detail:send_refresh_attrib(nil, false)
    return result
end

function script_base:LuaFnGetPetTitleAttr(selfId, petHid, petLid, nTitle)
    local pet_title = configenginer:get_config("pet_title")
    pet_title = pet_title[nTitle]
    if pet_title then
        return true, pet_title["Level"], pet_title["Name"],  pet_title["Level"]
    end
end

function script_base:LuaFnGetPeGrowthRate(selfId, petGUID_H, petGUID_L)
    local obj = self.scene:get_obj_by_id(selfId)
    local container = obj:get_pet_bag_container()
    local guid = pet_guid_cls.new()
    guid:set(petGUID_H, petGUID_L)
    local pet_detail = container:get_pet_by_guid(guid)
    return pet_detail:get_growth_rate()
end

function script_base:LuaFnGetPetLife(selfId, petGUID_H, petGUID_L)
    local obj = self.scene:get_obj_by_id(selfId)
    local container = obj:get_pet_bag_container()
    local guid = pet_guid_cls.new()
    guid:set(petGUID_H, petGUID_L)
    local pet_detail = container:get_pet_by_guid(guid)
    return pet_detail:get_life()
end

function script_base:LuaFnGetPetHappiness(selfId, petGUID_H, petGUID_L)
    local obj = self.scene:get_obj_by_id(selfId)
    local container = obj:get_pet_bag_container()
    local guid = pet_guid_cls.new()
    guid:set(petGUID_H, petGUID_L)
    local pet_detail = container:get_pet_by_guid(guid)
    return pet_detail:get_happiness()
end

function script_base:LuaFnPetCanUseFood(selfId, bagIndex)
    return true
end

function script_base:LuaFnIsPetAvailable()
    return true
end

function script_base:LuaFnSetPetHP(selfId, petGUID_H, petGUID_L, hp)
    local obj = self.scene:get_obj_by_id(selfId)
    local container = obj:get_pet_bag_container()
    local guid = pet_guid_cls.new()
    guid:set(petGUID_H, petGUID_L)
    local pet_detail = container:get_pet_by_guid(guid)
    pet_detail:set_hp(hp)
    pet_detail:send_refresh_attrib()
    if guid == obj:get_current_pet_guid() then
        local pet = obj:get_pet()
        if pet then
            pet:mark_attrib_refix_dirty("hp")
        end
    end
end

function script_base:LuaFnSetPetLife(selfId, petGUID_H, petGUID_L, life_span)
    local obj = self.scene:get_obj_by_id(selfId)
    local container = obj:get_pet_bag_container()
    local guid = pet_guid_cls.new()
    guid:set(petGUID_H, petGUID_L)
    local pet_detail = container:get_pet_by_guid(guid)
    pet_detail:set_life(life_span)
    pet_detail:send_refresh_attrib()
    if guid == obj:get_current_pet_guid() then
        local pet = obj:get_pet()
        if pet then
            pet:mark_attrib_refix_dirty("life_span")
        end
    end
end

function script_base:LuaFnSetPetHappiness(selfId, petGUID_H, petGUID_L, happiness)
    local obj = self.scene:get_obj_by_id(selfId)
    local container = obj:get_pet_bag_container()
    local guid = pet_guid_cls.new()
    guid:set(petGUID_H, petGUID_L)
    local pet_detail = container:get_pet_by_guid(guid)
    pet_detail:set_happiness(happiness)
    pet_detail:send_refresh_attrib()
    if guid == obj:get_current_pet_guid() then
        local pet = obj:get_pet()
        if pet then
            pet:mark_attrib_refix_dirty("happiness")
        end
    end
end

function script_base:LuaFnGetPetObjIdByGUID(selfId, petGUID_H, petGUID_L, happiness)
    local obj = self.scene:get_obj_by_id(selfId)
    local container = obj:get_pet_bag_container()
    local guid = pet_guid_cls.new()
    guid:set(petGUID_H, petGUID_L)
    if obj:get_current_pet_guid() == guid then
        local pet = obj:get_pet()
        if pet then
            return pet:get_obj_id()
        end
    end
end

function script_base:LuaFnGetPetObjByGUID(selfId, petGUID_H, petGUID_L)
    local obj = self.scene:get_obj_by_id(selfId)
    local container = obj:get_pet_bag_container()
    local guid = pet_guid_cls.new()
    guid:set(petGUID_H, petGUID_L)
    if obj:get_current_pet_guid() == guid then
        return obj:get_pet()
    end
end

function script_base:GetPetName(data_id)
    local pet_attr_table = configenginer:get_config("pet_attr_table")
    return pet_attr_table[data_id].name
end

function script_base:GetPetTransString(selfId, petGUID_H, petGUID_L)
    local obj = self.scene:get_obj_by_id(selfId)
    local container = obj:get_pet_bag_container()
    local guid = pet_guid_cls.new()
    guid:set(petGUID_H, petGUID_L)
    local pet_detail = container:get_pet_by_guid(guid)
    return pet_detail:get_transfer()
end

function script_base:LuaFnGetPetTransferByGUID(...)
    return self:GetPetTransString(...)
end

function script_base:HaveDarkEquiped(selfId)
    local obj = self.scene:get_obj_by_id(selfId)
    local container = obj:get_equip_container()
    return container:get_item(define.HUMAN_EQUIP.HEQUIP_ANQI) ~= nil
end

function script_base:IsDarkNeedLevelUpByNpcNow(selfId)
    local obj = self.scene:get_obj_by_id(selfId)
    local container = obj:get_equip_container()
    local anqi = container:get_item(define.HUMAN_EQUIP.HEQUIP_ANQI)
    if anqi == nil then
        return false
    end
    local xiulian = anqi:get_equip_data():get_aq_xiulian()
    return (xiulian > 30) and (xiulian % 10 == 9)
end

function script_base:GetDarkLevel(selfId)
    local obj = self.scene:get_obj_by_id(selfId)
    local container = obj:get_equip_container()
    local anqi = container:get_item(define.HUMAN_EQUIP.HEQUIP_ANQI)
    if anqi == nil then
        return 0
    end
    return anqi:get_equip_data():get_aq_xiulian()
end

function script_base:DarkLevelUp(selfId)
    local obj = self.scene:get_obj_by_id(selfId)
    local container = obj:get_equip_container()
    local anqi = container:get_item(define.HUMAN_EQUIP.HEQUIP_ANQI)
    if anqi == nil then
        return false
    end
    local result = anqi:get_equip_data():dark_level_up()
    if result then
        local msg = packet_def.GCItemInfo.new()
        msg.bagIndex = define.HUMAN_EQUIP.HEQUIP_ANQI
        msg.item = anqi:copy_raw_data()
        msg.bag_type = define.BAG_TYPE.equip
        obj:get_scene():send2client(obj, msg)
    end
    return result
end

function script_base:DarkOperateResult(selfId, arg1, arg2, arg3)
    local obj = self.scene:get_obj_by_id(selfId)
    local msg = packet_def.GCDarkResult.new()
    msg.unknow_1 = arg1
    msg.unknow_2 = arg2
    if arg1 == 0 then
        msg.unknow_3 = arg3 - 1
    elseif arg1 == 3 then
        msg.unknow_4 = arg3
    end
    obj:get_scene():send2client(obj, msg)
end

function script_base:GenDarkSkillForBagItem(selfId, pos)
    return require('cy_equipment_skills').generate(self,selfId,pos,17)
end

function script_base:RefreshDarkSkills(selfId, pos)
    return require('cy_equipment_skills').replace(self,selfId,pos,17)
end

function script_base:GetDarkCleanTimes(selfId, BagPos)
    local obj = self.scene:get_obj_by_id(selfId)
    local container = obj:get_prop_bag_container()
    local anqi = container:get_item(BagPos)
    if anqi == nil then
        return false
    end
    local xidian = anqi:get_equip_data():get_aq_xi_dian()
    return xidian
end

function script_base:GetDarkTotalCleanTimes(selfId, BagPos)
    local obj = self.scene:get_obj_by_id(selfId)
    local container = obj:get_prop_bag_container()
    local anqi = container:get_item(BagPos)
    if anqi == nil then
        return false
    end
    local xiulian = anqi:get_equip_data():get_aq_xiulian()
    return (xiulian - 1) * 3
end

function script_base:GetDarkAttrForBagItem(selfId, BagPos, attr_index)
    local obj = self.scene:get_obj_by_id(selfId)
    local container = obj:get_prop_bag_container()
    local anqi = container:get_item(BagPos)
    if anqi == nil then
        return false
    end
    return anqi:get_equip_data():get_aq_attr(attr_index)
end

function script_base:SetDarkCleanTimes(selfId, BagPos, xi_dian)
    local obj = self.scene:get_obj_by_id(selfId)
    local container = obj:get_prop_bag_container()
    local anqi = container:get_item(BagPos)
    if anqi == nil then
        return false
    end
    return anqi:get_equip_data():set_aq_xi_dian(xi_dian)
end

function script_base:AdjustDarkAttrForBagItem(selfId, BagPos, attr_from)
    local obj = self.scene:get_obj_by_id(selfId)
    local container = obj:get_prop_bag_container()
    local anqi = container:get_item(BagPos)
    if anqi == nil then
        return define.INVAILD_ID
    end
    local attr_to
    local attr_list = { 1, 2, 3, 4, 5}
    table.remove(attr_list, attr_from)
    attr_to = attr_list[math.random(#attr_list)]
    local from = anqi:get_equip_data():get_aq_attr(attr_from)
    if from <= 1 then
        return define.INVAILD_ID
    end
    anqi:get_equip_data():set_aq_attr(attr_from, from - 1)
    local to = anqi:get_equip_data():get_aq_attr(attr_to)
    anqi:get_equip_data():set_aq_attr(attr_to, to + 1)
    local msg = packet_def.GCItemInfo.new()
    msg.bagIndex = BagPos
    msg.item = anqi:copy_raw_data()
    obj:get_scene():send2client(obj, msg)
    return attr_to
end

function script_base:ResetDarkQualityForBagItem(selfId, BagPos, resettype)
    local obj = self.scene:get_obj_by_id(selfId)
    local container = obj:get_prop_bag_container()
    local anqi = container:get_item(BagPos)
    if anqi == nil then
        return false
    end
    local equip_base = configenginer:get_config("equip_base")
    equip_base = equip_base[anqi:get_index()]
    local base = equip_base["品阶"]
    local n = math.random(50)
    if n == 1 or n == 2 then 
        n = math.random(60)
    elseif n == 3 then
        n = math.random(60, 80)
    elseif n == 4 then
        n = math.random(80, 100)
    elseif n == 50 then
        n = math.random(120, 200)
    else
        n = math.random(100, 120)
    end
    n = n - 1
    local aq_grow_rate = anqi:get_equip_data():get_aq_grow_rate()
    local new = base + n
    if new > aq_grow_rate then
        anqi:get_equip_data():set_aq_grow_rate(new)
        anqi:get_equip_data():anqi_upgrade_skill(true)
        local msg = packet_def.GCItemInfo.new()
        msg.bagIndex = BagPos
        msg.item = anqi:copy_raw_data()
        obj:get_scene():send2client(obj, msg)
        return true
    end
    return false
end

function script_base:ResetDarkForBagItem(selfId, BagPos)
    local obj = self.scene:get_obj_by_id(selfId)
    local container = obj:get_prop_bag_container()
    local anqi = container:get_item(BagPos)
    if anqi == nil then
        return false
    end
    local equip_base = configenginer:get_config("equip_base")
    equip_base = equip_base[anqi:get_index()]
    if equip_base.equip_point ~= define.HUMAN_EQUIP.HEQUIP_ANQI then
        return false
    end
    anqi:get_equip_data():set_aq_xiulian(1)
    anqi:get_equip_data():set_aq_exp(0)
    anqi:get_equip_data():set_aq_xi_dian(0)
    for i = 1, 3 do
        anqi:get_equip_data():set_aq_skill(i, 0)
    end
    for i = 1, 5 do
        anqi:get_equip_data():set_aq_attr(i, 1)
    end
    anqi:get_equip_data():set_attr_count(5)
    local msg = packet_def.GCItemInfo.new()
    msg.bagIndex = BagPos
    msg.item = anqi:copy_raw_data()
    obj:get_scene():send2client(obj, msg)
    return true
end

function script_base:LuaFnIsPetAvailableByGUIDNoPW(selfId, petGUID_H, petGUID_L)
    local obj = self.scene:get_obj_by_id(selfId)
    local container = obj:get_pet_bag_container()
    local guid = pet_guid_cls.new()
    guid:set(petGUID_H, petGUID_L)
    local pet_detail = container:get_pet_by_guid(guid)
    return pet_detail ~= nil
end

function script_base:LuaFnIsPetAvailableByGUID(selfId, petGUID_H, petGUID_L)
    local obj = self.scene:get_obj_by_id(selfId)
    local container = obj:get_pet_bag_container()
    local guid = pet_guid_cls.new()
    guid:set(petGUID_H, petGUID_L)
    local pet_detail = container:get_pet_by_guid(guid)
    return pet_detail ~= nil
end

function script_base:GetPetSkillLevelupTbl(selfId, high, low, index)
    local pet, human, current, target, item, cost, broadcast = pet_gameplay.upgrade_info(self, selfId, high, low, index)
    if not pet then return -1 end
    return current, target, item, cost, broadcast
end

function script_base:LuaFnPetSkillUp(selfId, high, low, index, target)
    local pet, human, current, expected = pet_gameplay.upgrade_info(self, selfId, high, low, index)
    if not pet or target ~= expected then return false end
    pet:set_skill_by_index(index, target)
    human:send_pet_detail(pet, human)
    return true
end

function script_base:LuaFnGetCurrentPetGUID(selfId)
    local obj = self.scene:get_obj_by_id(selfId)
    local guid = obj:get_current_pet_guid()
	if guid == define.INVAILD_ID then
		return
	end
    return guid.m_uHighSection, guid.m_uLowSection
end

function script_base:LuaFnGetItemTableIndexByIndex(selfId, BagPos)
    local obj = self.scene:get_obj_by_id(selfId)
	if not obj then
		return define.INVAILD_ID
	end
	if not BagPos or BagPos < 0 then
		obj:notify_tips("位置异常。")
		return define.INVAILD_ID
	end
    local item = obj:get_prop_bag_container():get_item(BagPos)
    if not item then
        return define.INVAILD_ID
    end
    return item:get_index()
end

function script_base:GetItemPetEquipID(selfId,BagPos)
    local obj = self.scene:get_obj_by_id(selfId)
    assert(obj, selfId)
	if not BagPos or BagPos < 0 then
		obj:notify_tips("位置异常。")
		return define.INVAILD_ID
	end
    local item = obj:get_prop_bag_container():get_item(BagPos)
	if not item then
		obj:notify_tips("没有珍兽装备。")
		return define.INVAILD_ID
	end
	if not item:is_pet_equip() then
		obj:notify_tips("不是珍兽装备。")
		return define.INVAILD_ID
	end
	return item:get_index()
end

function script_base:GetItemGemID(selfId,BagPos)
    local obj = self.scene:get_obj_by_id(selfId)
    assert(obj, selfId)
	if not BagPos or BagPos < 0 then
		obj:notify_tips("位置异常。")
		return define.INVAILD_ID
	end
    local item = obj:get_prop_bag_container():get_item(BagPos)
	if not item then
		obj:notify_tips("没有宝石。")
		return define.INVAILD_ID
	end
	if not item:is_gem() then
		obj:notify_tips("不是宝石。")
		return define.INVAILD_ID
	end
	return item:get_index()
end

function script_base:GetItemQuestID(selfId,BagPos)
    local obj = self.scene:get_obj_by_id(selfId)
    assert(obj, selfId)
	if not BagPos or BagPos < 0 then
		obj:notify_tips("位置异常。")
		return define.INVAILD_ID
	end
    local item = obj:get_prop_bag_container():get_item(BagPos)
	if not item then
		obj:notify_tips("没有任务品。")
		return define.INVAILD_ID
	end
	if not item:is_quest() then
		obj:notify_tips("不是任务品。")
		return define.INVAILD_ID
	end
	return item:get_index()
end

function script_base:GetItemMaterialID(selfId,BagPos)
    local obj = self.scene:get_obj_by_id(selfId)
    assert(obj, selfId)
	if not BagPos or BagPos < 0 then
		obj:notify_tips("位置异常。")
		return define.INVAILD_ID
	end
    local item = obj:get_prop_bag_container():get_item(BagPos)
	if not item then
		obj:notify_tips("没有材料。")
		return
	end
	if not item:is_material() then
		obj:notify_tips("不是材料。")
		return -1
	end
	return item:get_index()
end

function script_base:GetItemBaseID(selfId,BagPos)
    local obj = self.scene:get_obj_by_id(selfId)
    assert(obj, selfId)
	if not BagPos or BagPos < 0 then
		obj:notify_tips("位置异常。")
		return define.INVAILD_ID
	end
    local item = obj:get_prop_bag_container():get_item(BagPos)
	if not item then
		obj:notify_tips("没有道具。")
		return define.INVAILD_ID
	end
	if not item:is_base() then
		obj:notify_tips("不是道具。")
		return define.INVAILD_ID
	end
	return item:get_index()
end

function script_base:GetItemEquipID(selfId,BagPos)
    local obj = self.scene:get_obj_by_id(selfId)
    assert(obj, selfId)
	if not BagPos or BagPos < 0 then
		obj:notify_tips("位置异常。")
		return define.INVAILD_ID
	end
    local item = obj:get_prop_bag_container():get_item(BagPos)
	if not item then
		obj:notify_tips("没有装备。")
		return define.INVAILD_ID
	end
	if not item:is_equip() then
		obj:notify_tips("不是装备。")
		return define.INVAILD_ID
	end
	return item:get_index()
end

function script_base:GetPetBookSkillID(PetBookId)
    local pet_skill_book = configenginer:get_config("pet_skill_book")
    local skill_id = pet_skill_book[PetBookId]
    skill_id = skill_id or define.INVAILD_ID
    return skill_id
end

function script_base:PetStudySkill(selfId, petGUID_H, petGUID_L, skillId)
    local obj = self.scene:get_obj_by_id(selfId)
    local guid = pet_guid_cls.new()
    guid:set(petGUID_H, petGUID_L)
    local container = obj:get_pet_bag_container()
    local pet_detail = container:get_pet_by_guid(guid)
    if pet_detail == nil then
        return false
    end
    local ret = pet_detail:skill_modify_study(skillId)
    obj:send_pet_detail(pet_detail, obj)
    return ret
end

function script_base:GetPetSavvy(selfId, petGUID_H, petGUID_L)
    local obj = self.scene:get_obj_by_id(selfId)
    local guid = pet_guid_cls.new()
    guid:set(petGUID_H, petGUID_L)
    local container = obj:get_pet_bag_container()
    local pet_detail = container:get_pet_by_guid(guid)
    if pet_detail == nil then
        return define.INVAILD_ID
    end
    return pet_detail:get_wuxing()
end

function script_base:GetCostOfGenGuBySavvy(savvy)
    if savvy == 0 then
        return 100
    elseif savvy == 1 then
        return 110
    elseif savvy == 2 then
        return 121
    elseif savvy == 3 then
        return 133
    elseif savvy == 4 then
        return 146
    elseif savvy == 5 then
        return 161
    elseif savvy == 6 then
        return 177
    elseif savvy == 7 then
        return 194
    elseif savvy == 8 then
        return 214
    elseif savvy == 9 then
        return 235
    end
end

function script_base:GetSuccrateOfGenGuBySavvy(savvy)
    if savvy == 0 then
        return 100
    elseif savvy == 1 then
        return 85
    elseif savvy == 2 then
        return 75
    elseif savvy == 3 then
        return 60
    elseif savvy == 4 then
        return 20
    elseif savvy == 5 then
        return 31
    elseif savvy == 6 then
        return 31
    elseif savvy == 7 then
        return 3
    elseif savvy == 8 then
        return 7
    elseif savvy == 9 then
        return 10
    end
end

function script_base:GetLeveldownOfCompoundBySavvy(savvy)
    if savvy == 4 or savvy == 7 or savvy == 9 then
        return 0
    else
        return 1
    end
end

function script_base:SetPetSavvy(selfId, petGUID_H, petGUID_L, nSavvyNeed)
    local obj = self.scene:get_obj_by_id(selfId)
    local guid = pet_guid_cls.new()
    guid:set(petGUID_H, petGUID_L)
    local container = obj:get_pet_bag_container()
    local pet_detail = container:get_pet_by_guid(guid)
    if pet_detail == nil then
        return false
    end
    pet_detail:set_wuxing(nSavvyNeed)
    obj:send_pet_detail(pet_detail, obj)
    return true
end

function script_base:GetPetType(selfId, petGUID_H, petGUID_L)
    local obj = self.scene:get_obj_by_id(selfId)
    local guid = pet_guid_cls.new()
    guid:set(petGUID_H, petGUID_L)
    local container = obj:get_pet_bag_container()
    local pet_detail = container:get_pet_by_guid(guid)
    return self:GetPetTypeByDetail(pet_detail)
end

function script_base:GetPetDataID(selfId, petGUID_H, petGUID_L)
    local obj = self.scene:get_obj_by_id(selfId)
    local guid = pet_guid_cls.new()
    guid:set(petGUID_H, petGUID_L)
    local container = obj:get_pet_bag_container()
    local pet_detail = container:get_pet_by_guid(guid)
    if pet_detail == nil then
        return define.INVAILD_ID
    end
    return pet_detail:get_data_index()
end

function script_base:GetPetHuanHuaData(data_id)
    local pet_huan_hua_table = configenginer:get_config("pet_huan_hua_table")
    pet_huan_hua_table = pet_huan_hua_table[data_id]
    if pet_huan_hua_table == nil then
        return define.INVAILD_ID
    end
    return pet_huan_hua_table[1], pet_huan_hua_table[2], pet_huan_hua_table.cost
end

function script_base:GetPetHaveHuanHua(selfId, petGUID_H, petGUID_L)
    local obj = self.scene:get_obj_by_id(selfId)
    local guid = pet_guid_cls.new()
    guid:set(petGUID_H, petGUID_L)
    local container = obj:get_pet_bag_container()
    local pet_detail = container:get_pet_by_guid(guid)
    if pet_detail == nil then
        return false
    end
    return pet_detail:have_huan_hua()
end

function script_base:PetHuanHua(selfId, petGUID_H, petGUID_L, data_id)
    local obj = self.scene:get_obj_by_id(selfId)
    local guid = pet_guid_cls.new()
    guid:set(petGUID_H, petGUID_L)
    local container = obj:get_pet_bag_container()
    local pet_detail = container:get_pet_by_guid(guid)
    if pet_detail == nil then
        return false
    end
    pet_detail:set_huan_huad()
    pet_detail:set_data_index(data_id)
    obj:send_pet_detail(pet_detail, obj)
end

function script_base:GetPetByType(selfId, petGUID_H, petGUID_L)
    local obj = self.scene:get_obj_by_id(selfId)
    local guid = pet_guid_cls.new()
    guid:set(petGUID_H, petGUID_L)
    local container = obj:get_pet_bag_container()
    local pet_detail = container:get_pet_by_guid(guid)
    if pet_detail == nil then
        return define.INVAILD_ID
    end
    return self:GetPetTypeByDetail(pet_detail)
end

function script_base:GetPetSex(selfId, petGUID_H, petGUID_L)
    local obj = self.scene:get_obj_by_id(selfId)
    local guid = pet_guid_cls.new()
    guid:set(petGUID_H, petGUID_L)
    local container = obj:get_pet_bag_container()
    local pet_detail = container:get_pet_by_guid(guid)
    if pet_detail == nil then
        return define.INVAILD_ID
    end
    return pet_detail:get_sex()
end

function script_base:GetPetVariances(selfId, petGUID_H, petGUID_L)
    local obj = self.scene:get_obj_by_id(selfId)
    local guid = pet_guid_cls.new()
    guid:set(petGUID_H, petGUID_L)
    local container = obj:get_pet_bag_container()
    local pet_detail = container:get_pet_by_guid(guid)
    local variances = {}
    if pet_detail == nil then
        return variances
    end
    local data_index = pet_detail:get_data_index()
    local pet_attr_table = configenginer:get_config("pet_attr_table")
    local this_pet_attr_table = pet_attr_table[data_index]
    if not this_pet_attr_table then
        return variances
    end
    local pet_type = this_pet_attr_table.type
    for i = data_index - 1, (data_index - 8), -1 do
        local cur_pet_attr_table = pet_attr_table[i]
        if cur_pet_attr_table and cur_pet_attr_table.type == pet_type then
            if cur_pet_attr_table.is_var_type then
                table.insert(variances, i)
            end
        end
    end
    table.sort(variances, function(a, b)
        return a < b
    end)
    return variances,data_index
end

function script_base:GetPetLevel(selfId, petGUID_H, petGUID_L)
    local obj = self.scene:get_obj_by_id(selfId)
    local guid = pet_guid_cls.new()
    guid:set(petGUID_H, petGUID_L)
    local container = obj:get_pet_bag_container()
    local pet_detail = container:get_pet_by_guid(guid)
    if pet_detail == nil then
        return define.INVAILD_ID
    end
    return pet_detail:get_level()
end

function script_base:GetPetPropagateLevel(selfId, petGUID_H, petGUID_L)
    local obj = self.scene:get_obj_by_id(selfId)
    local guid = pet_guid_cls.new()
    guid:set(petGUID_H, petGUID_L)
    local container = obj:get_pet_bag_container()
    local pet_detail = container:get_pet_by_guid(guid)
    if pet_detail == nil then
        return define.INVAILD_ID
    end
    return pet_detail:get_propagate_level()
end

function script_base:SetPetPropagateLevel(selfId, petGUID_H, petGUID_L, level)
    local obj = self.scene:get_obj_by_id(selfId)
    local guid = pet_guid_cls.new()
    guid:set(petGUID_H, petGUID_L)
    local container = obj:get_pet_bag_container()
    local pet_detail = container:get_pet_by_guid(guid)
    if pet_detail == nil then
        return false
    end
    pet_detail:set_propagate_level(level)
    return true
end

function script_base:SetPetsSpouseGUID(selfId, petGUID_H, petGUID_L, SpouseGUID_H, SpouseGUID_L)
    local obj = self.scene:get_obj_by_id(selfId)
    local guid = pet_guid_cls.new()
    guid:set(petGUID_H, petGUID_L)
    local container = obj:get_pet_bag_container()
    local pet_detail = container:get_pet_by_guid(guid)
    local spouse_guid = pet_guid_cls.new()
    spouse_guid:set(SpouseGUID_H, SpouseGUID_L)
    local spouse_detail = container:get_pet_by_guid(spouse_guid)
    if pet_detail == nil or spouse_detail == nil then
        return false
    end
    pet_detail:set_spouse_guid(spouse_guid)
    spouse_detail:set_spouse_guid(guid)
    return true
end

function script_base:GetPetSpouseGUID(selfId, petGUID_H, petGUID_L)
    local obj = self.scene:get_obj_by_id(selfId)
    local guid = pet_guid_cls.new()
    guid:set(petGUID_H, petGUID_L)
    local container = obj:get_pet_bag_container()
    local pet_detail = container:get_pet_by_guid(guid)
    if pet_detail == nil then
        return false
    end
    return true, pet_detail:get_spouse_guid()
end

function script_base:GetPetLingXing(selfId, petGUID_H, petGUID_L)
    local obj = self.scene:get_obj_by_id(selfId)
    local guid = pet_guid_cls.new()
    guid:set(petGUID_H, petGUID_L)
    local container = obj:get_pet_bag_container()
    local pet_detail = container:get_pet_by_guid(guid)
    if pet_detail == nil then
        return define.INVAILD_ID
    end
    return pet_detail:get_ling_xing()
end

function script_base:SetPetLingXing(selfId, petGUID_H, petGUID_L, lingxing)
    local obj = self.scene:get_obj_by_id(selfId)
    local guid = pet_guid_cls.new()
    guid:set(petGUID_H, petGUID_L)
    local container = obj:get_pet_bag_container()
    local pet_detail = container:get_pet_by_guid(guid)
    if pet_detail == nil then
        return define.INVAILD_ID
    end
    pet_detail:set_ling_xing(lingxing)
    obj:send_pet_detail(pet_detail, obj)
end

function script_base:GetPetEquipType(selfId, BagPos)
    local obj = self.scene:get_obj_by_id(selfId)
    local container = obj:get_prop_bag_container()
    local item = container:get_item(BagPos)
    if item == nil then
        return define.INVAILD_ID
    end
    if item:get_serial_class() ~= define.ITEM_CLASS.ICLASS_PET_EQUIP then
        return define.INVAILD_ID
    end
    return item:get_pet_equip_data():get_pet_equip_type()
end

function script_base:GetPetSoulLevel(selfId, BagPos)
    local obj = self.scene:get_obj_by_id(selfId)
    local container = obj:get_prop_bag_container()
    local item = container:get_item(BagPos)
    if item == nil then
        return define.INVAILD_ID
    end
    if item:get_serial_class() ~= define.ITEM_CLASS.ICLASS_PET_EQUIP then
        return define.INVAILD_ID
    end
    return item:get_pet_equip_data():get_level()
end

function script_base:GetPetSoullGrade(selfId, BagPos)
    local obj = self.scene:get_obj_by_id(selfId)
    local container = obj:get_prop_bag_container()
    local item = container:get_item(BagPos)
    if item == nil then
        return define.INVAILD_ID
    end
    if item:get_serial_class() ~= define.ITEM_CLASS.ICLASS_PET_EQUIP then
        return define.INVAILD_ID
    end
    return item:get_pet_equip_data():get_pet_soul_level()
end

function script_base:GetPetSoulLevelUpCost(level, quanlity)
    local pet_soul_level_cost = configenginer:get_config("pet_soul_level_cost")
    pet_soul_level_cost = pet_soul_level_cost[level]
    quanlity = quanlity + 1
    return pet_soul_level_cost.cost_count[quanlity], pet_soul_level_cost.cost_money[quanlity]
end

function script_base:GetPetSoulQuanlity(selfId, BagPos)
    local obj = self.scene:get_obj_by_id(selfId)
    local container = obj:get_prop_bag_container()
    local item = container:get_item(BagPos)
    if item == nil then
        return define.INVAILD_ID
    end
    if item:get_serial_class() ~= define.ITEM_CLASS.ICLASS_PET_EQUIP then
        return define.INVAILD_ID
    end
    return item:get_pet_equip_data():get_pet_soul_quanlity()
end

function script_base:PetSoulLevelUp(selfId, BagPos)
    local obj = self.scene:get_obj_by_id(selfId)
    local container = obj:get_prop_bag_container()
    local item = container:get_item(BagPos)
    if item == nil then
        return false
    end
    if item:get_serial_class() ~= define.ITEM_CLASS.ICLASS_PET_EQUIP then
        return false
    end
    local level = item:get_pet_equip_data():get_level()
    item:get_pet_equip_data():set_level(level + 1)
    local msg = packet_def.GCItemInfo.new()
    msg.bagIndex = BagPos
    msg.item = item:copy_raw_data()
    obj:get_scene():send2client(obj, msg)
    return true
end

function script_base:PetSoulXiShuXing(selfId, BagPos, LockValue, LockColorCount, prepared)
    local obj = self.scene:get_obj_by_id(selfId)
    local container = obj:get_prop_bag_container()
    local item = container:get_item(BagPos)
    if item == nil then
        return false
    end
    if item:get_serial_class() ~= define.ITEM_CLASS.ICLASS_PET_EQUIP then
        return false
    end
    local pet_soul_attr = prepared or item:get_pet_equip_data():gen_soul_attr(LockValue, LockColorCount)
    if type(pet_soul_attr)~='table' or #pet_soul_attr~=6 then return false end
    obj:set_temp_pet_soul_attr_data(BagPos, pet_soul_attr)
    -- CYS-SOUL-IDENTITY: a bag slot is not an item identity.
    local g=item:get_guid()
    obj:get_temp_pet_soul_attr_data().guid={world=g.world,server=g.server,series=g.series}
    local msg = packet_def.GCPetSoulXiShuXing.new()
    msg.result = 1
    msg.shuxings = pet_soul_attr
    obj:get_scene():send2client(obj, msg)
    self:notify_tips(selfId, "#{SHCX_20211229_22}")
    return true
end

function script_base:GetPetSoulBloodAddExp(selfId, BagPosSoul, BagPosM)
    local pet_soul_base = configenginer:get_config("pet_soul_base")
    local obj = self.scene:get_obj_by_id(selfId)
    local container = obj:get_prop_bag_container()
    local item = container:get_item(BagPosSoul)
    if item == nil then
        return define.INVAILD_ID
    end
    if item:get_serial_class() ~= define.ITEM_CLASS.ICLASS_PET_EQUIP then
        return define.INVAILD_ID
    end
    pet_soul_base = pet_soul_base[item:get_index()]
    if pet_soul_base == nil then
        return define.INVAILD_ID
    end
    local item_m = container:get_item(BagPosM)
    if item_m == nil then
        return define.INVAILD_ID
    end
    if pet_soul_base.material == item_m:get_index() then
        return 20
    else
        return 10
    end
end

function script_base:PetSoulAddExp(selfId, BagPos, exp)
    local obj = self.scene:get_obj_by_id(selfId)
    local container = obj:get_prop_bag_container()
    local item = container:get_item(BagPos)
    if item == nil then
        return false
    end
    if item:get_serial_class() ~= define.ITEM_CLASS.ICLASS_PET_EQUIP then
        return false
    end
    item:add_exp(exp)
    local msg = packet_def.GCItemInfo.new()
    msg.bagIndex = BagPos
    msg.item = item:copy_raw_data()
    obj:get_scene():send2client(obj, msg)
    return true
end

function script_base:AddRadioItemBonus(item_index, count)
    self.item_count = (self.item_count or 0) + 1
    local item = { item_index = item_index, flag = 4, count = count}
    table.insert(self.items, item)
end

function script_base:AddItemBonus(item_index, count)
    self.item_count = (self.item_count or 0) + 1
    local item = { item_index = item_index, flag = 4, count = count}
    table.insert(self.items, item)
end

function script_base:AddMoneyBonus(count)
    self.item_count = (self.item_count or 0) + 1
    local item = { flag = 1, item_index = count}
    table.insert(self.items, item)
end

function script_base:AddMoneyJZBonus(count)
    self.item_count = (self.item_count or 0) + 1
    local item = { flag = 0, item_index = count}
    table.insert(self.items, item)
end

function script_base:AddRandItemBonus()
    self.item_count = (self.item_count or 0) + 1
    local item = { item_index = item_index, flag = 5, count = count}
    table.insert(self.items, item)
end

function script_base:AddItemDemand()
    self.item_count = (self.item_count or 0) + 1
    local item = { item_index = item_index, flag = 4, count = count}
    table.insert(self.items, item)
end

function script_base:DispatchMissionContinueInfo(selfId, targetId, script_id, mission_id)
    local ret = packet_def.GCScriptCommand.new()
    ret.m_nCmdID = 4
    ret.event = self.event
    ret.target_id = targetId
    ret.size = #ret.event
    ret.m_objID = script_id or self.script_id
    ret.m_idMission = mission_id
    ret.item_count = self.item_count
    ret.items = self.items
    self.scene:send2client(selfId, ret)
end

function script_base:LuaFnGetAvailableItemsCount(selfId, ...)
    local All_Count = 0
    for _, item_index in ipairs({ ... }) do
        All_Count = All_Count + self:LuaFnGetAvailableItemCount(selfId, item_index)
    end
    return All_Count
end

function script_base:BeginAddItem()
    local batch=require('cys_script_item_batches').get(self)
    batch.items={};batch.prepared=nil
end

function script_base:LuaFnBeginAddItem()
    self:BeginAddItem()
end

function script_base:AddItem(ItemIndex,Count,is_bind,param)
    local batch=require('cys_script_item_batches').get(self);batch.prepared=nil
    table.insert(batch.items,{item_index=ItemIndex,count=Count,is_bind=is_bind,param=param})
end

function script_base:LuaFnAddItem(ItemIndex, Count)
    self:AddItem(ItemIndex, Count)
end

function script_base:LuaFnEndAddItemIgnoreFatigueState(selfId)
    return self:EndAddItem(selfId)
end

function script_base:LuaFnAddItemListToHumanIgnoreFatigueState(selfId)
    return self:AddItemListToHuman(selfId)
end

function script_base:EndAddItem(selfId,emptytab,way)
    local ok=require('cys_script_reward').prepare(self,selfId,way)
    if not ok then
        local human=self.scene:get_obj_by_id(selfId)
        if human then human:notify_tips('Không thể nhận đủ vật phẩm. Hãy kiểm tra chỗ trống trong túi.')end
    end
    if emptytab or not ok then self:BeginAddItem()end
    return ok
end

function script_base:LuaFnEndAddItem(selfId)
    return self:EndAddItem(selfId)
end

function script_base:AddItemListToHuman(selfId,way)
    return require('cys_script_reward').commit(self,selfId,way)
end

function script_base:LuaFnDelAllAvailableItems(selfId,count,...)
    local human=self.scene:get_obj_by_id(selfId)
    return human_item_logic:del_available_items({},human,count,{...})
end

function script_base:PetEquipSuitUpInfo(material_item)
    local pet_equip_suit_up_info = configenginer:get_config("pet_equip_suit_up_info")
    pet_equip_suit_up_info = pet_equip_suit_up_info[material_item]
    if pet_equip_suit_up_info == nil then
        return define.INVAILD_ID
    end
    return pet_equip_suit_up_info.product_equip, pet_equip_suit_up_info.material, pet_equip_suit_up_info.material_count, pet_equip_suit_up_info.cost_money
end

function script_base:LuaFnIsItemLocked(selfId, BagPos)
    local obj = self.scene:get_obj_by_id(selfId)
    local item = obj:get_prop_bag_container():get_item(BagPos)
    if item == nil then
        return false
    end
    return item:is_lock()
end

function script_base:LuaFnGetItemBindStatus(selfId, ItemPos)
    local obj = self.scene:get_obj_by_id(selfId)
    local item = obj:get_prop_bag_container():get_item(ItemPos)
    assert(item, ItemPos)
    return item:is_bind()
end

function script_base:GetBagPosByItemSnAvailableBind(selfId, itemTableIndex, bind)
    local obj = self.scene:get_obj_by_id(selfId)
    assert(obj, selfId)
    local BagPos = human_item_logic:get_bag_pos_by_item_sn_available_bind(obj, itemTableIndex, bind)
    return BagPos
end

function script_base:LuaFnIsIdentd(selfId, ItemPos)
    local obj = self.scene:get_obj_by_id(selfId)
    assert(obj, selfId)
    local Item = obj:get_prop_bag_container():get_item(ItemPos)
    assert(Item, ItemPos)
    return Item:is_identd()
end

function script_base:LuaFnReSetItemApt(selfId, ItemPos)
    local obj = self.scene:get_obj_by_id(selfId)
    assert(obj, selfId)
    local Item = obj:get_prop_bag_container():get_item(ItemPos)
    assert(Item, ItemPos)
    Item:set_qidentd(Item:get_index())
    local msg = packet_def.GCItemInfo.new()
    msg.bagIndex = ItemPos
    msg.item = Item:copy_raw_data()
    self.scene:send2client(selfId, msg)
    return 1
end

function script_base:LuaFnReSetPetEquipApt(selfId, ItemPos)
    local obj = self.scene:get_obj_by_id(selfId)
    assert(obj, selfId)
    local Item = obj:get_prop_bag_container():get_item(ItemPos)
    assert(Item, ItemPos)
    Item:set_pet_equip_qidentd()
    local msg = packet_def.GCItemInfo.new()
    msg.bagIndex = ItemPos
    msg.item = Item:copy_raw_data()
    self.scene:send2client(selfId, msg)
    return 1
end

function script_base:GetItemApt(selfId, ItemPos, apt_index)
    local obj = self.scene:get_obj_by_id(selfId)
    assert(obj, selfId)
    local Item = obj:get_prop_bag_container():get_item(ItemPos)
    return Item:get_equip_data():get_apt(apt_index)
end

function script_base:LuaFnIsJudgeApt(selfId, ItemPos)
    local obj = self.scene:get_obj_by_id(selfId)
    assert(obj, selfId)
    local Item = obj:get_prop_bag_container():get_item(ItemPos)
    return Item:get_equip_data():is_judge_aptd()
end

function script_base:LuaFnEraseItem(selfId, ItemPos)
    return self:EraseItem(selfId, ItemPos)
end

function script_base:LuaFnEraseItemTimes(selfId, ItemPos, MaxValue)
    local used_value = self:GetBagItemParam(selfId, ItemPos, 8)
    used_value = used_value + 1
    self:SetBagItemParam(selfId, ItemPos, 4, MaxValue)
    self:SetBagItemParam(selfId, ItemPos, 8, used_value)
    if used_value == MaxValue then
        self:EraseItem(selfId, ItemPos)
    else
        local obj = self.scene:get_obj_by_id(selfId)
        assert(obj, selfId)
        local Item = obj:get_prop_bag_container():get_item(ItemPos)
        local msg = packet_def.GCItemInfo.new()
        msg.bagIndex = ItemPos
        msg.unknow_1 = Item and 0 or 1
        msg.item = Item and Item:copy_raw_data() or item_cls.new():copy_raw_data()
        self.scene:send2client(selfId, msg)
    end
    return true, MaxValue - used_value
end


-- function script_base:LuaFnGetEquipEnhanceLevel(selfId, equipoint)
    -- local obj = self.scene:get_obj_by_id(selfId)
    -- assert(obj, selfId)
    -- local Item = obj:get_equip_container():get_item(equipoint)
    -- if Item == nil then
        -- return 0
    -- end
    -- local enchance_level = Item:get_equip_data():get_enhancement_level()
	-- return enchance_level
-- end
function script_base:LuaFnEquipEnhanceCheck(selfId, itemidx1, itemidx2)
    local obj = self.scene:get_obj_by_id(selfId)
    assert(obj, selfId)
    local Item = obj:get_prop_bag_container():get_item(itemidx1)
    assert(Item, itemidx1)
    if Item:is_lock() then
        return -2
    end
    local Item2 = obj:get_prop_bag_container():get_item(itemidx2)
    assert(Item2, itemidx1)
    if Item2:is_lock() then
        return -3
    end
    local config = Item:get_next_enhance_config()
    if not config then
        return -4
    end
    local cost_money = config.cost_money
    local money = self:GetMoney(selfId) + self:GetMoneyJZ(selfId)
    if money < cost_money then
        return -5,cost_money
    end
    return 0
end
function script_base:LuaFnUpdateEquipEnhanceInfo(selfId, equip_pos)
    local obj = self.scene:get_obj_by_id(selfId)
	assert(obj, selfId)
    local Equip = obj:get_prop_bag_container():get_item(equip_pos)
	assert(Equip, equip_pos)
	local equipid = Equip:get_index()
	local equip_base = configenginer:get_config("equip_base")
	if not equip_base[equipid] then
		return
	end
	local e_point = Equip:get_base_config().equip_point
	local istrue = define.CHUANCIGONGFANG[e_point]
	if not istrue then
		return
	end
	istrue = istrue - 601
    local enchance_level = Equip:get_equip_data():get_enhancement_level()
	local configleft,configright
	local qhrate = 0
	if enchance_level > 0 then
		configleft = Equip:get_enhance_config()
	end
	if enchance_level < 99 then
		configright = Equip:get_next_enhance_config()
		qhrate = configright.odd
	end
	local addatt_left,addatt_right = 0,0
	local ccleft,ccright = 0,0
	local configs = configenginer:get_config("equip_enhanceex")
    -- self:notify_tips(selfId, "isoka:"..tostring(117043021))
	local enchance_level_down = enchance_level + 1
	if istrue == 2 then
		if configleft then
			addatt_left = configleft.bonus[define.ITEM_ATTRIBUTE.IATTRIBUTE_RATE_DEFENCE_EP]
			ccleft = configs[enchance_level].fangchuan
		end
		if configright then
			addatt_right = configright.bonus[define.ITEM_ATTRIBUTE.IATTRIBUTE_RATE_DEFENCE_EP]
			ccright = configs[enchance_level_down].fangchuan
		end
	else
		if configleft then
			addatt_left = configleft.bonus[define.ITEM_ATTRIBUTE.IATTRIBUTE_RATE_ATTACK_EP]
			ccleft = configs[enchance_level].chuangci
		end
		if configright then
			addatt_right = configright.bonus[define.ITEM_ATTRIBUTE.IATTRIBUTE_RATE_ATTACK_EP]
			ccright = configs[enchance_level_down].chuangci
		end
	end
	local losecount = Equip:get_param(9, "ushort")
	local currate = 0
	local subrate = 10000
	local needcount = 10000
	if qhrate > 0 then
		currate = qhrate * losecount
		currate = currate > 10000 and 10000 or currate
		subrate = 10000 - currate
		needcount = math.ceil(subrate / qhrate)
	end
	self.ui_command_args = { 
		int = {
			117043021,
			losecount,
			needcount,
			addatt_left,
			addatt_right,
			ccleft,
			ccright,
			istrue,
			qhrate,
		}, 
		str = {}
	}
	self:DispatchUICommand(selfId, 117043021)
end
function script_base:MoveEnhanceLevel(selfId,equippos1,equippos2)
    local obj = self.scene:get_obj_by_id(selfId)
    assert(obj, selfId)
    local Equip1 = obj:get_prop_bag_container():get_item(equippos1)
	if not Equip1 then
		return 1
	end
    local Equip2 = obj:get_prop_bag_container():get_item(equippos2)
	if not Equip2 then
		return 2
	end
	local equipid1 = Equip1:get_index()
	local equipid2 = Equip2:get_index()
	local equip_base = configenginer:get_config("equip_base")
	if not equip_base[equipid1] then
		return 3
	elseif not equip_base[equipid2] then
		return 4
	end
	local qhlv1 = Equip1:get_equip_data():get_enhancement_level()
	if qhlv1 < 1 then
		return 5
	end
	local needmoney = qhlv1 * 50000
	if needmoney > 1000000 then
		needmoney = 1000000
	end
	local mymoney = obj:get_attrib("money") or 0
	local mymoneyjz = obj:get_attrib("jiaozi") or 0
	if mymoney + mymoneyjz < needmoney then
		return 6,needmoney
	end
	local qhlv2 = Equip2:get_equip_data():get_enhancement_level()
	if qhlv2 >= qhlv1 then
		return 7
	end
	local equiplv1 = Equip1:get_base_config().level
	local equiplv2 = Equip2:get_base_config().level
	if (equiplv1 < 40 and equiplv2 >= 40) or (equiplv2 < 40 and equiplv1 >= 40) then
		return 8
	end
	local point1 = Equip1:get_base_config().equip_point
	local point2 = Equip2:get_base_config().equip_point
	if point1 ~= point2 then
		return 9
	end
	local equipbind1 = Equip1:is_bind()
	local equipbind2 = Equip2:is_bind()
	local delmoney = obj:cost_money_with_priority(needmoney, "强化转移消耗金币")
    if not delmoney then
        return 10
    end
	if equipbind1 or equipbind2 then
		if not equipbind1 then
			self:LuaFnItemBind(selfId,equippos1) 
		end
		if not equipbind2 then
			self:LuaFnItemBind(selfId,equippos2) 
		end
	end
	local losecount = Equip1:get_param(9, "ushort")
	Equip1:get_equip_data():set_enhancement_level(0)
	Equip1:set_param(9, 0, "ushort")
    local msg = packet_def.GCItemInfo.new()
    msg.bagIndex = equippos1
    msg.item = Equip1:copy_raw_data()
    self.scene:send2client(obj, msg)
	Equip2:get_equip_data():set_enhancement_level(qhlv1)
	Equip2:set_param(9, losecount, "ushort")
	msg = packet_def.GCItemInfo.new()
    msg.bagIndex = equippos2
    msg.item = Equip2:copy_raw_data()
    self.scene:send2client(obj, msg)
	return 0
end
function script_base:LuaFnEquipEnhance(selfId, equip_bagpos, item_bagpos, qhl_count)
    qhl_count = qhl_count or 0
    local obj = self.scene:get_obj_by_id(selfId)
    assert(obj, selfId)
    local Equip = obj:get_prop_bag_container():get_item(equip_bagpos)
	if not Equip then
		return 1
	end
	local equipid = Equip:get_index()
	local equipbind = Equip:is_bind()
	local equiplv = Equip:get_base_config().level
	local equip_base = configenginer:get_config("equip_base")
	if not equip_base[equipid] then
		return 18
	end
	local point = Equip:get_base_config().equip_point
	if point == define.HUMAN_EQUIP.HEQUIP_RIDER
	or point == define.HUMAN_EQUIP.HEQUIP_UNKNOW1
	or point == define.HUMAN_EQUIP.HEQUIP_UNKNOW2
	or point == define.HUMAN_EQUIP.HEQUIP_FASHION
	or point == define.HUMAN_EQUIP.HEQUIP_WUHUN
	or point == define.HUMAN_EQUIP.LINGWU_JING
	or point == define.HUMAN_EQUIP.LINGWU_CHI
	or point == define.HUMAN_EQUIP.LINGWU_JIA
	or point == define.HUMAN_EQUIP.LINGWU_GOU
	or point == define.HUMAN_EQUIP.LINGWU_DAI
	or point == define.HUMAN_EQUIP.LINGWU_DI then
	-- or point == define.HUMAN_EQUIP.SHENBING
	-- or point == define.HUMAN_EQUIP.HEQUIP_ALL
		return 17
	end
    if Equip:is_lock() then
		return 2
    end
	local qhlv = Equip:get_equip_data():get_enhancement_level()
	if qhlv >= 99 then
		return 3
	end
    local downlvinfo = Equip:get_next_enhance_config()
	if not downlvinfo then
		return 4
	end
	local mymoney = obj:get_attrib("money") or 0
	local mymoneyjz = obj:get_attrib("jiaozi") or 0
	if mymoney + mymoneyjz < downlvinfo.cost_money then
		return 13,downlvinfo.cost_money
	end
    local Item = obj:get_prop_bag_container():get_item(item_bagpos)
	if not Item then
		return 5
	end
	if Item:is_empty() or Item:is_lock() then
		return 6
	end
	local itemid = Item:get_index()
	local itemname = self:GetItemName(itemid)
	itemname = gbk.fromutf8(itemname)
	local itembind = Item:is_bind()
	if (equipid == 10423024) or (equipid == 10422016) then --重楼玉，重楼戒
		if itembind then
			return 12
		end
	end
	if qhlv < 9 then
		if equiplv < 40 then
			if itemid ~= 30900005 then
				return 7
			end
			local logparam = {}
			local isok = human_item_logic:dec_item_lay_count(logparam, obj, item_bagpos, 1)
			if not isok then
				return 8
			end
		else
			if itemid == 30900006 then
				local logparam = {}
				local isok = human_item_logic:dec_item_lay_count(logparam, obj, item_bagpos, 1)
				if not isok then
					return 9
				end
			elseif itemid == 30900045 then
				local use_value = Item:get_param(8, nil) or 0
				if use_value >= qhl_count then
					self:EraseItem(selfId, item_bagpos)
					return 10
				end
				use_value = use_value + 1
				if use_value == qhl_count then
					self:EraseItem(selfId, item_bagpos)
				else
					Item:set_param(4, qhl_count, nil)
					Item:set_param(8, use_value, nil)
					local msg = packet_def.GCItemInfo.new()
					msg.bagIndex = item_bagpos
					msg.unknow_1 = Item and 0 or 1
					msg.item = Item:copy_raw_data()
					self.scene:send2client(selfId, msg)
				end
			else
				return 11
			end
		end
	else
		if itemid ~= 38008160 and itemid ~= 38008161 then
			return 14
		end
		local logparam = {}
		local isok = human_item_logic:dec_item_lay_count(logparam, obj, item_bagpos, 1)
		if not isok then
			return 15
		end
	end
	local delmoney = obj:cost_money_with_priority(downlvinfo.cost_money, "强化消耗金币")
    if not delmoney then
        return 16
    end
	if itembind and not equipbind then
		self:LuaFnItemBind(selfId,equip_bagpos) 
	end
    local succ = false
	local losecount = Equip:get_param(9, "ushort")
	losecount = losecount + 1
	local currate = downlvinfo.odd * losecount
	-- CYS-ENH 17/09/2026 (server-data): MOT lan quay, dung bang `ItemEnhance` cot `成功率`.
	-- Ban cu quay HAI lan (`sjrate <= currate` roi `sjrate > 10000 - currate`), moi lan cung xac suat
	-- currate/10000, nen ti le that la BINH PHUONG cot bang (cap 1: 0,62 % thay vi 7,88 %).
	-- Chinh server cung mau thuan: LuaFnUpdateEquipEnhanceInfo gui `qhrate` va `needcount` cho khung
	-- 117043021 theo cong thuc chi dung khi quay MOT lan. Xem Tools/server/enhance_rate.py.
	local trycount = losecount
	local sjrate = math.random(10000)
	if sjrate <= currate then
		succ = true
		qhlv = qhlv + 1
		losecount = 0
		Equip:get_equip_data():set_enhancement_level(qhlv)
	end
	skynet.error(string.format("[CYS-ENH] rolls=1 odd=%d try=%d currate=%d r1=%d succ=%s qhlv=%d", downlvinfo.odd, trycount, currate, sjrate, tostring(succ), qhlv))
	Equip:set_param(9, losecount, "ushort")
    local msg = packet_def.GCItemInfo.new()
    msg.bagIndex = equip_bagpos
    msg.item = Equip:copy_raw_data()
    self.scene:send2client(obj, msg)
	self:LuaFnUpdateEquipEnhanceInfo(selfId,equip_bagpos)
	if succ and qhlv >= 5 then
		-- local szTranItm = self:GetBagItemTransfer(selfId, equip_bagpos)
		local szTranItm = Equip:get_transfer()
		local name = obj:get_name()
		name = gbk.fromutf8(name)
		local szMsg = string.format( "#W#{_INFOUSR%s}#{EQ_1}%s#{EQ_2}%d#{EQ_3}#{_INFOMSG%s}#{EQ_4}", name, itemname, qhlv, szTranItm )
		-- szMsg = gbk.fromutf8(szMsg)
		-- local msg = packet_def.GCChat.new()
		-- msg.ChatType = 4
		-- msg.Sourceid = selfId
		-- msg.unknow_2 = 1
		-- msg:set_content(szMsg)
		self:BroadMsgByChatPipe(selfId, szMsg, 4)
	end
	return 0,qhlv,succ
end
function script_base:GetBagItemLevel(selfId, BagPos)
    local obj = self.scene:get_obj_by_id(selfId)
    assert(obj, selfId)
    local Item = obj:get_prop_bag_container():get_item(BagPos)
    assert(Item, BagPos)
    return Item:get_base_config().level
end

function script_base:LuaFnGetEquipEnhanceLevel(selfId, BagPos)
    local obj = self.scene:get_obj_by_id(selfId)
    assert(obj, selfId)
    local Item = obj:get_prop_bag_container():get_item(BagPos)
    assert(Item, BagPos)
    return Item:get_equip_data():get_enhancement_level()
end

function script_base:LuaFnSetEquipEnhanceLevel(selfId, BagPos, level)
    local obj = self.scene:get_obj_by_id(selfId)
    assert(obj, selfId)
    local Item = obj:get_prop_bag_container():get_item(BagPos)
    assert(Item, BagPos)
    Item:get_equip_data():set_enhancement_level(level)
    local msg = packet_def.GCItemInfo.new()
    msg.bagIndex = BagPos
    msg.item = Item:copy_raw_data()
    self.scene:send2client(obj, msg)
end

function script_base:LuaFnGetBagEquipType(selfId, BagPos)
    if type(BagPos)~='number' or BagPos~=math.floor(BagPos) or BagPos<0 or BagPos>254 then return -1 end
    local obj=self.scene:get_obj_by_id(selfId)
    local item=obj and obj:get_prop_bag_container():get_item(BagPos)
    if not item or item:get_serial_class()~=1 then return -1 end
    local base=item:get_base_config()
    return base and base.equip_point or -1
end

function script_base:LuaFnLockCheck(selfId, BagPos, need_money )
    local obj = self.scene:get_obj_by_id(selfId)
    assert(obj, selfId)
    local Item = obj:get_prop_bag_container():get_item(BagPos)
    assert(Item, BagPos)
    if Item:is_ebind() then
        return -3
    end
    return 0
end

function script_base:LuaFnEquipLock(selfId, BagPos)
    local obj = self.scene:get_obj_by_id(selfId)
    assert(obj, selfId)
    local Item = obj:get_prop_bag_container():get_item(BagPos)
    assert(Item, BagPos)
    if Item:is_ebind() then
        return -3
    end
    Item:set_is_ebind(true)
    local msg = packet_def.GCItemInfo.new()
    msg.bagIndex = BagPos
    msg.item = Item:copy_raw_data()
    self.scene:send2client(obj, msg)
    return 0
end

function script_base:LuaFnIsItemEquipLock(selfId, BagPos)
    local obj = self.scene:get_obj_by_id(selfId)
    assert(obj, selfId)
    local Item = obj:get_prop_bag_container():get_item(BagPos)
    assert(Item, BagPos)
    return Item:is_ebind()
end

function script_base:LuaFnUnLockCheck(selfId, BagPos, need_money )
    local obj = self.scene:get_obj_by_id(selfId)
    assert(obj, selfId)
    local Item = obj:get_prop_bag_container():get_item(BagPos)
    assert(Item, BagPos)
    if not Item:is_ebind() then
        return -3
    end
    return 0
end

function script_base:LuaFnEquipUnLock(selfId, BagPos)
    local obj = self.scene:get_obj_by_id(selfId)
    assert(obj, selfId)
    local Item = obj:get_prop_bag_container():get_item(BagPos)
    assert(Item, BagPos)
    if Item:is_ebind() then
        return -3
    end
    Item:set_is_ebind(false)
    local msg = packet_def.GCItemInfo.new()
    msg.bagIndex = BagPos
    msg.item = Item:copy_raw_data()
    self.scene:send2client(obj, msg)
    return 0
end

function script_base:LuaFnIsPetGrowRateByGUID(selfId, petHid, petLid)
    local obj = self.scene:get_obj_by_id(selfId)
    assert(obj, selfId)
    local container = obj:get_pet_bag_container()
    local guid = pet_guid_cls.new()
    guid:set(petHid, petLid)
    local pet_detail = container:get_pet_by_guid(guid)
    return pet_detail:get_growth_rate_queryd()
end

function script_base:LuaFnGetPetGrowRateLevelByGUID(selfId, petHid, petLid)
    local obj = self.scene:get_obj_by_id(selfId)
    assert(obj, selfId)
    local container = obj:get_pet_bag_container()
    local guid = pet_guid_cls.new()
    guid:set(petHid, petLid)
    local pet_detail = container:get_pet_by_guid(guid)
    pet_detail:set_growth_rate_queryd()
    obj:send_pet_detail(pet_detail, obj)
    return pet_detail:get_growth_rate_level()
end

function script_base:PetPropagate(selfId, petHid, petLid, lock_growth_rate, lock_perception, quick)
    local obj = self.scene:get_obj_by_id(selfId)
    assert(obj, selfId)
    local container = obj:get_pet_bag_container()
    local guid = pet_guid_cls.new()
    guid:set(petHid, petLid)
    local pet_detail = container:get_pet_by_guid(guid)
    local result = petmanager:propagate(pet_detail, lock_growth_rate, lock_perception, quick)
    local growth_rate_level = pet_detail:get_growth_rate_level()
    obj:send_pet_detail(pet_detail, obj)
    return result, growth_rate_level
end

function script_base:IsItemDark()

end

function script_base:GetBagGemCount(selfId, BagPos)
    local obj = self.scene:get_obj_by_id(selfId)
    assert(obj, selfId)
    local Item = obj:get_prop_bag_container():get_item(BagPos)
    assert(Item, BagPos)
    return Item:get_equip_data():get_slot_count()
end

function script_base:GemEnchasing(selfId, GemBagIndex, EquipBagIndex, location)
    local obj = self.scene:get_obj_by_id(selfId)
    assert(obj, selfId)
    local GemItm = obj:get_prop_bag_container():get_item(GemBagIndex)
    assert(GemItm, GemBagIndex)
    local Equip = obj:get_prop_bag_container():get_item(EquipBagIndex)
    assert(Equip, EquipBagIndex)
    Equip:get_equip_data():gem_embed(location, GemItm:get_index())
    -- 强制同步 gem_count 为 gem_list 实际数量，防止计数器虚增
    do
        local _gem_list = Equip:get_equip_data():get_gem_list()
        local _real_count = 0
        for _i = 1, 4 do
            if _gem_list[_i] and _gem_list[_i] ~= 0 then
                _real_count = _real_count + 1
            end
        end
        Equip:get_equip_data():set_gem_count(_real_count)
    end
    local logparam = {}
    local del = human_item_logic:dec_item_lay_count(logparam, obj, GemBagIndex, 1)
	if not del then
		return false
	end
    local msg = packet_def.GCItemInfo.new()
    msg.bagIndex = EquipBagIndex
    msg.item = Equip:copy_raw_data()
    self.scene:send2client(obj, msg)
    return true
end

function script_base:GetGemEmbededCount(selfId, EquipBagIndex)
    local obj = self.scene:get_obj_by_id(selfId)
    assert(obj, selfId)
    local Item = obj:get_prop_bag_container():get_item(EquipBagIndex)
    assert(Item, EquipBagIndex)
    -- 遍历 list_2 统计实际已镶嵌数量，避免依赖 gem_count 计数器（该计数器可能因宝石升级等操作虚增）
    local gem_list = Item:get_equip_data():get_gem_list()
    local count = 0
    for i = 1, 4 do
        if gem_list[i] and gem_list[i] ~= 0 then
            count = count + 1
        end
    end
    return count
end

function script_base:LuaFnGetItemType(gemIdx)
    local gem_info = configenginer:get_config("gem_info")
    local gem = gem_info[gemIdx]
    assert(gem, gemIdx)
    return gem.type
end

function script_base:GetDiaoWenInfoByTupu(itemTableIndex)
    local diaowen_infos = configenginer:get_config("diaowen_info")
    for _, dw in pairs(diaowen_infos) do
        if dw.tupu_material == itemTableIndex then
            return dw
        end
    end
end

function script_base:GetDiaoWenInfoByProduct(itemTableIndex)
    local diaowen_infos = configenginer:get_config("diaowen_info")
    for _, dw in pairs(diaowen_infos) do
        if dw.product == itemTableIndex then
            return dw
        end
    end
end

function script_base:GetDiaoWenRuleByProduct(rule_id)
    local diaowen_rules = configenginer:get_config("diaowen_rule")
    for id, rules in pairs(diaowen_rules) do
        if id == rule_id then
            return rules
        end
    end
end

function script_base:GetDiaoWenInfoByIndex(id)
    local diaowen_infos = configenginer:get_config("diaowen_info")
    return diaowen_infos[id]
end

function script_base:LuaFnMtl_GetCostNum(selfId, materials)
    local num = 0
	local haveitem = {}
	local itemcount
    for _, item_index in ipairs(materials) do
		itemcount = self:LuaFnGetAvailableItemCount(selfId, item_index)
		if itemcount > 0 then
			num = num + itemcount
			table.insert(haveitem,item_index)
		end
    end
    return num,haveitem
end

function script_base:LuaFnMtl_CostMaterial(selfId,count,materials)
    local human=self.scene:get_obj_by_id(selfId)
    local ok=human_item_logic:del_available_items({},human,count,materials)
    return ok,{}
end

function script_base:GetItemName(item_index)
	if not item_index or item_index < 10000000 then
		return -1
	end
	local itemclass = item_index // 10000000
	local config
	if itemclass == define.ITEM_CLASS.ICLASS_EQUIP then
		local equip_base = configenginer:get_config("equip_base")
		config = equip_base[item_index]
	elseif itemclass == define.ITEM_CLASS.ICLASS_STOREMAP
	or itemclass == define.ITEM_CLASS.ICLASS_MATERIAL
	or itemclass == define.ITEM_CLASS.ICLASS_TASK then
		local common_item = configenginer:get_config("common_item")
		config = common_item[item_index]
	elseif itemclass == define.ITEM_CLASS.ICLASS_GEM then
		local gem_info = configenginer:get_config("gem_info")
		config = gem_info[item_index]
	elseif itemclass == define.ITEM_CLASS.ICLASS_PET_EQUIP then
		local pet_equip_base = configenginer:get_config("pet_equip_base")
		config = pet_equip_base[item_index]
	else
		return -1
	end
	if not config then
		return -1
	end
    return config.name or -1
end

function script_base:DiaoWenShiKe(selfId, BagPos, itemTableIndex)
    local obj = self.scene:get_obj_by_id(selfId)
    assert(obj, selfId)
    local Item = obj:get_prop_bag_container():get_item(BagPos)
    assert(Item, BagPos)
    local dw_config = self:GetDiaoWenInfoByProduct(itemTableIndex)
    Item:get_equip_data():diaowen_shike(dw_config.id)
    local msg = packet_def.GCItemInfo.new()
    msg.bagIndex = BagPos
    msg.item = Item:copy_raw_data()
    self.scene:send2client(obj, msg)
end

function script_base:GetEquipDiaoWenData(selfId, BagPos)
    local obj = self.scene:get_obj_by_id(selfId)
    assert(obj, selfId)
    local Item = obj:get_prop_bag_container():get_item(BagPos)
    assert(Item, BagPos)
    local id = Item:get_equip_data():get_diaowen_id()
    local materials_count = Item:get_equip_data():get_diaowen_material_count()
    return id, materials_count
end

function script_base:SetEquipDiaoWenData(selfId, BagPos, diaowen_id, diaowen_material_count)
    local obj = self.scene:get_obj_by_id(selfId)
    assert(obj, selfId)
    local Item = obj:get_prop_bag_container():get_item(BagPos)
    assert(Item, BagPos)
    Item:get_equip_data():set_diaowen_id(diaowen_id)
    Item:get_equip_data():set_diaowen_material_count(diaowen_material_count)
    local msg = packet_def.GCItemInfo.new()
    msg.bagIndex = BagPos
    msg.item = Item:copy_raw_data()
    self.scene:send2client(obj, msg)
end

function script_base:DiaowenDivert(selfId,src_pos,dsc_pos)
    local obj = self.scene:get_obj_by_id(selfId)
    assert(obj, selfId)
	local prop_bag_container = obj:get_prop_bag_container()
	local src_item = prop_bag_container:get_item(src_pos)
	local dsc_item = prop_bag_container:get_item(dsc_pos)
	if not src_item or not dsc_item then
		return
	end
	local src_equip_data = src_item:get_equip_data()
	local dsc_equip_data = dsc_item:get_equip_data()
	local src_dw = src_equip_data:get_diaowen_id()
	local src_material_count = src_equip_data:get_diaowen_material_count()
	local dw_advance_level,dw_featuresid,dw_rankexp = src_equip_data:get_dw_jinjie_details()
	src_equip_data:set_diaowen_id(0)
	src_equip_data:set_diaowen_material_count(0)
	src_equip_data:set_dw_jinjie_details(0,0,0)
	dsc_equip_data:set_diaowen_id(src_dw)
	dsc_equip_data:set_diaowen_material_count(src_material_count)
	dsc_equip_data:set_dw_jinjie_details(dw_advance_level,dw_rankexp,dw_featuresid)
    local msg = packet_def.GCItemInfo.new()
    msg.bagIndex = src_pos
    msg.item = src_item:copy_raw_data()
    self.scene:send2client(obj, msg)
    msg = packet_def.GCItemInfo.new()
    msg.bagIndex = dsc_pos
    msg.item = dsc_item:copy_raw_data()
    self.scene:send2client(obj, msg)
end

function script_base:SetDiaoWenFineDraw(selfId, BagPos)
    local obj = self.scene:get_obj_by_id(selfId)
    assert(obj, selfId)
    local Item = obj:get_prop_bag_container():get_item(BagPos)
    assert(Item, BagPos)
	local dw_advance_level = 1
	local dw_rankexp = 0
	Item:set_is_bind(true)
	Item:get_equip_data():set_dw_jinjie_details(dw_advance_level,dw_rankexp,0)
    local msg = packet_def.GCItemInfo.new()
    msg.bagIndex = BagPos
    msg.item = Item:copy_raw_data()
    self.scene:send2client(obj, msg)
	return true
end
function script_base:GetDiaoWenFineDraw(selfId,BagPos,is_eqpoint)
    local obj = self.scene:get_obj_by_id(selfId)
    assert(obj, selfId)
	local Item
	if is_eqpoint then
		Item = obj:get_equip_container():get_item(BagPos)
	else
		Item = obj:get_prop_bag_container():get_item(BagPos)
	end
    assert(Item, BagPos)
	local equip_data = Item:get_equip_data()
    local dwid = equip_data:get_diaowen_id()
	local diaowen_infos = configenginer:get_config("diaowen_info")
	local dwlv = 0
	if diaowen_infos[dwid] then
		dwlv = diaowen_infos[dwid].level
	end
	local dw_advance_level,dw_rankexp = equip_data:get_dw_jinjie_finedraw()
    return dwlv, dw_advance_level, dw_rankexp
end

function script_base:AddDiaoWenFineDrawExp(selfId, BagPos, dwlv, dw_advance_level, addexp)
    local obj = self.scene:get_obj_by_id(selfId)
    assert(obj, selfId)
    local Item = obj:get_prop_bag_container():get_item(BagPos)
    assert(Item, BagPos)
	local dw_jinjie_info = configenginer:get_config("dw_jinjie_info")
	local maxlv = dwlv * 5
	local needexp = dw_jinjie_info[dw_advance_level].needexp
	while addexp >= needexp do
		if dw_advance_level >= maxlv or needexp == -1 then
			addexp = 0
			break
		end
		dw_advance_level = dw_advance_level + 1
		addexp = addexp - needexp
		needexp = dw_jinjie_info[dw_advance_level].needexp
	end
	Item:set_is_bind(true)
	Item:get_equip_data():set_dw_jinjie_finedraw(dw_advance_level,addexp)
    local msg = packet_def.GCItemInfo.new()
    msg.bagIndex = BagPos
    msg.item = Item:copy_raw_data()
    self.scene:send2client(obj, msg)
end

function script_base:GetDiaoWenFineDrawNeedExp(selfId, dw_advance_level, tarlevel)
	local needexp = 0
	local dw_jinjie_info = configenginer:get_config("dw_jinjie_info")
	for i = dw_advance_level,tarlevel do
		needexp = needexp + dw_jinjie_info[i].needexp
	end
	return needexp
end

function script_base:SetDiaoWenFineDrawDetails(selfId, BagPos, dw_advance_level, addexp)
    local obj = self.scene:get_obj_by_id(selfId)
    assert(obj, selfId)
    local Item = obj:get_prop_bag_container():get_item(BagPos)
    assert(Item, BagPos)
	Item:set_is_bind(true)
	Item:get_equip_data():set_dw_jinjie_finedraw(dw_advance_level,addexp)
    local msg = packet_def.GCItemInfo.new()
    msg.bagIndex = BagPos
    msg.item = Item:copy_raw_data()
    self.scene:send2client(obj, msg)
end

-- function script_base:EmptyDiaoWenJinJie(selfId, BagPos)
    -- local obj = self.scene:get_obj_by_id(selfId)
    -- assert(obj, selfId)
    -- local Item = obj:get_prop_bag_container():get_item(BagPos)
    -- assert(Item, BagPos)
	-- Item:set_is_bind(true)
	-- Item:get_equip_data():set_dw_jinjie_details(0,0,0)
    -- local msg = packet_def.GCItemInfo.new()
    -- msg.bagIndex = BagPos
    -- msg.item = Item:copy_raw_data()
    -- self.scene:send2client(obj, msg)
-- end

function script_base:EmptyDiaoWenJinJie(selfId,BagPos,costyb,additem,additem2,addcount2,cost_is_bind)
    local obj = self.scene:get_obj_by_id(selfId)
    assert(obj, selfId)
    local Item = obj:get_prop_bag_container():get_item(BagPos)
    assert(Item, BagPos)
	-- local guid = obj:get_guid()
	-- local name = obj:get_name()
	-- local timer = os.date("%y%m%d %H:%M:%S")
	if costyb > 0 then
		if cost_is_bind then
			obj:cost_bind_yuanbao(costyb, "EmptyDiaoWenJinJie", "雕纹精会复旧")
		else
			if not obj:cost_yuanbao(costyb, "EmptyDiaoWenJinJie","雕纹精会复旧") then
				obj:notify_tips("元宝扣除失败。")
				return
			end
		end
	else
		if addcount2 > 0 then
			obj:notify_tips("error。")
			return
		end
	end
	Item:set_is_bind(true)
	Item:get_equip_data():set_dw_jinjie_details(0,0,0)
	local msg = packet_def.GCItemInfo.new()
	msg.bagIndex = BagPos
	msg.item = Item:copy_raw_data()
	self.scene:send2client(obj, msg)
	if addcount2 > 0 then
		local newpos = self:TryRecieveItem(selfId,additem2)
		if not newpos ~= -1 then
			local container = obj:get_prop_bag_container()
			Item = container:get_item(newpos)
			if Item then
				Item:set_is_bind(true)
				Item:set_param(4,addcount2,"int")
				msg = packet_def.GCItemInfo.new()
				msg.bagIndex = newpos
				msg.item = Item:copy_raw_data()
				self.scene:send2client(obj, msg)
			end
		end
	end
	newpos = self:TryRecieveItem(selfId,additem)
	if not newpos ~= -1 then
		local container = obj:get_prop_bag_container()
		Item = container:get_item(newpos)
		if Item then
			Item:set_is_bind(true)
			msg = packet_def.GCItemInfo.new()
			msg.bagIndex = newpos
			msg.item = Item:copy_raw_data()
			self.scene:send2client(obj, msg)
		end
	end
	obj:notify_tips("#{DWJJ_240329_114}")
end

function script_base:LuaFnAddJCSJ(selfId,jcsj_id,add_count)
    local obj = self.scene:get_obj_by_id(selfId)
    assert(obj, selfId)
	local newpos = self:TryRecieveItem(selfId,jcsj_id)
	if not newpos ~= -1 then
		local container = obj:get_prop_bag_container()
		Item = container:get_item(newpos)
		if Item then
			Item:set_is_bind(true)
			Item:set_param(4,add_count,"int")
			msg = packet_def.GCItemInfo.new()
			msg.bagIndex = newpos
			msg.item = Item:copy_raw_data()
			self.scene:send2client(obj, msg)
		end
	end
end

function script_base:GetDiaoWenJinJieFeaturesDetails(dw_featuresid,dw_featureslevel)
	local dw_jinjie_texing = configenginer:get_config("dw_jinjie_texing")
	dw_jinjie_texing = dw_jinjie_texing[dw_featuresid]
	if dw_jinjie_texing and dw_jinjie_texing.itemid ~= 0 then
		local dw_jinjie_texing_shengji = configenginer:get_config("dw_jinjie_texing_shengji")
		dw_jinjie_texing_shengji = dw_jinjie_texing_shengji[dw_featureslevel]
		if dw_jinjie_texing_shengji then
			return dw_jinjie_texing_shengji.nexp,dw_jinjie_texing_shengji.money,dw_jinjie_texing_shengji.mjc_count,dw_jinjie_texing.itemid
		else
			return 0
		end
	end
	return -1
end
	
function script_base:LuaFnGetFeaturesDetails(selfId,dw_featuresid)
    local obj = self.scene:get_obj_by_id(selfId)
    assert(obj, selfId)
	local level,nexp = obj:get_dw_jinjie_feature_details(dw_featuresid)
	return level,nexp
end

function script_base:LuaFnSetFeaturesDetails(selfId,dw_featuresid,dw_featureslevel,dw_featuresexp)
    local obj = self.scene:get_obj_by_id(selfId)
    assert(obj, selfId)
	obj:set_dw_jinjie_feature_details(dw_featuresid,dw_featureslevel,dw_featuresexp)
end

function script_base:UnDiaoWenFeatures(selfId,eqpoint)
    local obj = self.scene:get_obj_by_id(selfId)
    assert(obj, selfId)
    local container = obj:get_equip_container()
	local equip = container:get_item(eqpoint)
	if equip then
		local equip_data = equip:get_equip_data()
		local dw_featuresid,dw_advance_level = equip_data:get_dw_jinjie_featuresid()
		if dw_featuresid > 0 then
			equip_data:set_dw_jinjie_featuresid(0)
			obj:set_dw_jinjie_effect_details(eqpoint,0,dw_advance_level)
			local raw_data = equip:copy_raw_data()
			-- local msg = packet_def.GCItemInfo.new()
			-- msg.bagIndex = eqpoint
			-- msg.item = raw_data
			-- msg.bag_type = define.BAG_TYPE.equip
			-- obj:get_scene():send2client(obj, msg)
			
			local msg = packet_def.GCDetailEquipList.new()
			msg.m_objID = selfId
			msg.m_mode = 1
			msg.itemList = {[eqpoint] = raw_data}
			obj:get_scene():send2client(obj,msg)
			return true
		end
	end
end

function script_base:UseDiaoWenFeatures(selfId,eqpoint,dw_featureId)
    local obj = self.scene:get_obj_by_id(selfId)
    assert(obj, selfId)
    local container = obj:get_equip_container()
	local equip = container:get_item(eqpoint)
	if equip then
		local equip_data = equip:get_equip_data()
		local level = obj:get_dw_jinjie_feature_details(dw_featureId)
		if level and level > 0 then
			local _,dw_advance_level = equip_data:get_dw_jinjie_featuresid()
			equip_data:set_dw_jinjie_featuresid(dw_featureId)
			obj:set_dw_jinjie_effect_details(eqpoint,dw_featureId,dw_advance_level)
			local raw_data = equip:copy_raw_data()
			-- local msg = packet_def.GCItemInfo.new()
			-- msg.bagIndex = eqpoint
			-- msg.item = raw_data
			-- msg.bag_type = define.BAG_TYPE.equip
			-- obj:get_scene():send2client(obj, msg)
			local msg = packet_def.GCDetailEquipList.new()
			msg.m_objID = selfId
			msg.m_mode = 1
			msg.itemList = {[eqpoint] = raw_data}
			obj:get_scene():send2client(obj,msg)
		end
	end
end

function script_base:IsPilferLockFlag(selfId)
    return false
end

function script_base:GetEquipWuHunData(selfId, BagPos)
    local obj = self.scene:get_obj_by_id(selfId)
    assert(obj, selfId)
    local container = obj:get_prop_bag_container()
    if BagPos == nil then
        container = obj:get_equip_container()
        BagPos = define.HUMAN_EQUIP.HEQUIP_WUHUN
    end
    local Item = container:get_item(BagPos)
    if not Item or Item:get_serial_class()~=1 or Item:get_base_config().equip_point~=18 then return nil end
    local wh = {}
    wh.hecheng_level = Item:get_equip_data():get_wh_hecheng_level()
    wh.life = Item:get_equip_data():get_wh_life()
    wh.grow_rate = Item:get_equip_data():get_wh_grow_rate()
    wh.skill = Item:get_equip_data():get_wh_skill()
    wh.ex_attr_number = Item:get_equip_data():get_wh_ex_attr_number()
    wh.ex_attr = Item:get_equip_data():get_wh_ex_attr()
    wh.level = Item:get_equip_data():get_wh_level()
    return wh
end

function script_base:SetEquipWuHunData(selfId, BagPos, data)
    local obj = self.scene:get_obj_by_id(selfId)
    assert(obj, selfId)
    local Item = obj:get_prop_bag_container():get_item(BagPos)
    assert(Item, BagPos)
    local dirty = false
    if data.hecheng_level then
        dirty = true
        Item:get_equip_data():set_wh_hecheng_level(data.hecheng_level )
    end
    if data.life then
        dirty = true
        Item:get_equip_data():set_wh_life(data.life)
    end
    if data.grow_rate then
        dirty = true
        Item:get_equip_data():set_wh_grow_rate(data.grow_rate)
    end
    if data.skill then
        for i, v in pairs(data.skill) do
            dirty = true
            Item:get_equip_data():set_wh_skill(i, v)
        end
    end
    if data.ex_attr_number then
        dirty = true
        Item:get_equip_data():set_wh_ex_attr_number(data.ex_attr_number)
    end
    if data.ex_attr then
        for i, v in pairs(data.ex_attr) do
            dirty = true
            Item:get_equip_data():set_wh_ex_attr(i, v)
        end
    end
    if dirty then
        local msg = packet_def.GCItemInfo.new()
        msg.bagIndex = BagPos
        msg.item = Item:copy_raw_data()
        self.scene:send2client(obj, msg)
    end
end

function script_base:GetKfsSlotConfig()
    local kfs_slot = configenginer:get_config("kfs_slot")
    return kfs_slot
end

function script_base:GetKfsAttrExBookConfig()
    local kfs_attr_ex_book = configenginer:get_config("kfs_attr_ex_book")
    return kfs_attr_ex_book
end

function script_base:GetKfsAttrExConfig()
    local kfs_attr_ext = configenginer:get_config("kfs_attr_ext")
    return kfs_attr_ext
end

function script_base:GetKfsSkillLevelUpConfig()
    local kfs_skill_level_up = configenginer:get_config("kfs_skill_level_up")
    return kfs_skill_level_up
end

function script_base:AddWuHunExp(selfId, exp)
    local obj = self.scene:get_obj_by_id(selfId)
    assert(obj, selfId)
    local Item = obj:get_equip_container():get_item(define.HUMAN_EQUIP.HEQUIP_WUHUN)
    if Item == nil then
        return false
    end
    local my_level = obj:get_level()
    if Item:get_equip_data():get_wh_level() > obj:get_level() then
        return false
    end
    local result = Item:get_equip_data():add_wh_exp(exp, my_level)
    if not result then
        return false
    end
    local msg = packet_def.GCItemInfo.new()
    msg.bag_type = define.BAG_TYPE.equip
    msg.bagIndex = define.HUMAN_EQUIP.HEQUIP_WUHUN
    msg.item = Item:copy_raw_data()
    self.scene:send2client(obj, msg)
    return true
end

function script_base:WuHunUnstandSkill(selfId, BagPos, i)
    local obj = self.scene:get_obj_by_id(selfId)
    assert(obj, selfId)
    local Item = obj:get_prop_bag_container():get_item(BagPos)
    assert(Item, BagPos)
    Item:get_equip_data():wh_understand_skill(i)
    obj:send_skill_list()
    local msg = packet_def.GCItemInfo.new()
    msg.bagIndex = BagPos
    msg.item = Item:copy_raw_data()
    self.scene:send2client(obj, msg)
end

function script_base:GenWuHunSkillForBagItem(selfId, pos)
    return require('cy_equipment_skills').generate(self,selfId,pos,18)
end

function script_base:ReplaceKfsSkill(selfId, pos)
    return require('cy_equipment_skills').replace(self,selfId,pos,18)
end

function script_base:GetSkillName(skill)
    local template = skillenginer:get_skill_template(skill)
    return template.name
end

function script_base:SetMissionData(selfId, index, data)
    local obj = self.scene:get_obj_by_id(selfId)
    obj:set_mission_data_by_script_id(index, data)
end

function script_base:UpdateMissionData(selfId,md_tbl)
	md_tbl = md_tbl or {}
    local obj = self.scene:get_obj_by_id(selfId)
	for md in ipairs(md_tbl) do
		obj:update_md_value(md)
	end
end

function script_base:RefreshPetSoulAttr(selfId)
    local obj = self.scene:get_obj_by_id(selfId)
    local container = obj:get_prop_bag_container()
    local data = obj:get_temp_pet_soul_attr_data()
    if data == nil then
        return false
    end
    local soul = container:get_item(data.bag_index)
    if soul == nil then
        return false
    end
    if data.attr == nil then
        return false
    end
    local g=soul:get_guid();local old=data.guid
    if soul:is_empty() or soul:is_lock() or soul:get_serial_class()~=7 or not old or old.world~=g.world or old.server~=g.server or old.series~=g.series then
        obj:set_temp_pet_soul_attr_data(nil);return false
    end
    soul:get_pet_equip_data():set_pet_soul_attr(data.attr)
    obj:set_temp_pet_soul_attr_data(nil)
    local msg = packet_def.GCItemInfo.new()
    msg.bagIndex = data.bag_index
    msg.item = soul:copy_raw_data()
    obj:get_scene():send2client(obj, msg)

    local msg = packet_def.GCPetSoulXiShuXing.new()
    msg.result = 2
    msg.shuxings = data.attr
    obj:get_scene():send2client(obj, msg)
    return true
end

function script_base:GetWuHunWgConfig(id)
    local wuhun_wg = configenginer:get_config("wuhun_wg")
    return wuhun_wg[id]
end

function script_base:GetWuHunWg(selfId)
    local obj = self.scene:get_obj_by_id(selfId)
	assert(obj,"script_base:GetWuHunWg 缺失对象。")
    return table.clone(obj:get_wuhun_wg())
end

function script_base:UnLockWuHunWg(selfId, id)
    local obj = self.scene:get_obj_by_id(selfId)
	assert(obj,"script_base:GetWuHunWg 缺失对象。")
    obj:active_wuhun_wg(id)
    obj:send_wuhun_wg(selfId, 2, id)
end

function script_base:SetWuHunWgQKIndex(selfId, qk, index)
    local obj = self.scene:get_obj_by_id(selfId)
	assert(obj,"script_base:GetWuHunWg 缺失对象。")
    obj:set_huanhun_qk(qk, index)
end

function script_base:SetWuHunWgVisualFlag(selfId,wg_flag)
    local obj = self.scene:get_obj_by_id(selfId)
	assert(obj,"script_base:GetWuHunWg 缺失对象。")
	obj:set_attrib({wuhun_yy_flag = wg_flag})
	obj:send_refresh_attrib()
	obj:update_wuhun_visual()
end

function script_base:SetWuHunShowState(selfId,show)
    local obj = self.scene:get_obj_by_id(selfId)
	assert(obj,"script_base:SetWuHunShowState missing object")
	obj:send_wuhun_show_state(show)
end

function script_base:GetWuHunWgLevelConfig()
    local wuhun_wg_level = configenginer:get_config("wuhun_wg_level")
    return wuhun_wg_level
end

function script_base:GetWuHunWgIndex(selfId, id)
    local obj = self.scene:get_obj_by_id(selfId)
    local wg = obj:get_wuhun_wg()
    local s_huanhun_id = tostring(id)
    if wg[s_huanhun_id] == nil then
        return 0
    end
    return id * 10000 + wg[s_huanhun_id].level * 100 + wg[s_huanhun_id].grade
end

function script_base:WuHunWgLevelUp(selfId, id)
    local obj = self.scene:get_obj_by_id(selfId)
	assert(obj,"script_base:GetWuHunWg 缺失对象。")
    local wg = obj:get_wuhun_wg()
    local s_huanhun_id = tostring(id)
    assert(wg[s_huanhun_id], s_huanhun_id)
    if wg[s_huanhun_id].grade == 10 then
        wg[s_huanhun_id].grade = 0
        wg[s_huanhun_id].level = wg[s_huanhun_id].level + 1
    else
        wg[s_huanhun_id].grade = wg[s_huanhun_id].grade + 1
    end
    obj:item_flush()
    obj:send_wuhun_wg(selfId, 2, id)
end

function script_base:LuaFnObjId2Guid(selfId)
    local obj = self.scene:get_obj_by_id(selfId)
    return obj:get_guid()
end

function script_base:LuaFnCreateCopyScene(config)
    config.source = skynet.self()
    local dest_scene_id = skynet.call(".Copyscenemanager", "lua", "select", config)
    return dest_scene_id
end

function script_base:LuaFnGetCopySceneData_TeamLeader(...)
    local args = { ... }
    if #args == 1 then
        local dest_scene_id = args[1]
        if dest_scene_id == define.INVAILD_ID then
            return define.INVAILD_ID
        end
        local scene = string.format(".SCENE_%d", dest_scene_id)
        return skynet.call(scene, "lua", "get_team_leader")
    else
        return self.scene:get_team_leader()
    end
end

function script_base:LuaFnGetCopySceneData_Param(...)
    local args = { ... }
    if #args == 2 then
        local dest_scene_id = args[1]
        local index = args[2]
        if dest_scene_id == define.INVAILD_ID then
            return define.INVAILD_ID
        end
        local scene = string.format(".SCENE_%d", dest_scene_id)
        return skynet.call(scene, "lua", "get_param", index)
    else
        local index = args[1]
        return self.scene:get_param(index)
    end
end

function script_base:GetMissionData(selfId, script_id)
    local obj = self.scene:get_obj_by_id(selfId)
    return obj:get_mission_data_by_script_id(script_id)
end

function script_base:GetMissionFlag(selfId, script_id)
    local obj = self.scene:get_obj_by_id(selfId)
    return obj:get_mission_flag_by_script_id(script_id)
end

function script_base:GetMissionDataEx(selfId, script_id)
    local obj = self.scene:get_obj_by_id(selfId)
    return obj:get_mission_data_ex_by_script_id(script_id)
end
function script_base:GetKillEffective(selfId,targetId,addtime)
    local obj = self.scene:get_obj_by_id(targetId)
	if not obj then
		return "",false
	end
	local playername = obj:get_name()
	local curtime = os.time()
	local newtime = curtime + addtime
	local exdata,expos,extime
	local maxtime = 0
	local exposbf
	for i = ScriptGlobal.MDEX_KILL0,ScriptGlobal.MDEX_KILL9 do
		exdata = obj:get_mission_data_ex_by_script_id(i)
		extime = obj:get_mission_data_ex_by_script_id(i + 10)
		if exdata == selfId then
			if curtime > extime then
				obj:set_mission_data_ex_by_script_id(i + 10, newtime)
				return playername,true
			end
		elseif not expos then
			if exdata == 0 then
				expos = i
			elseif curtime > extime then
				expos = i
			elseif maxtime <= extime then
				maxtime = extime
				exposbf = i
			end
		end
	end
	if expos then
		obj:set_mission_data_ex_by_script_id(expos, selfId)
		obj:set_mission_data_ex_by_script_id(expos + 10, newtime)
		return playername,true
	elseif exposbf then
		obj:set_mission_data_ex_by_script_id(exposbf, selfId)
		obj:set_mission_data_ex_by_script_id(exposbf + 10, newtime)
		return playername,true
	end
	return playername,false
end

function script_base:SetMissionFlag(selfId, index, data)
    local obj = self.scene:get_obj_by_id(selfId)
    obj:set_mission_flag_by_script_id(index, data)
end

function script_base:SetMissionDataEx(selfId, index, data)
    local obj = self.scene:get_obj_by_id(selfId)
    obj:set_mission_data_ex_by_script_id(index, data)
end

function script_base:LuaFnChangeMenPai(selfId, targetMenPai)
    local human = self.scene:get_obj_by_id(selfId)
    if not human then return false, "character_not_found" end
    local ready, reason = human:can_change_menpai(targetMenPai)
    if not ready then return false, reason end
    actionenginer:interrupt_current_action(human)
    return human:change_menpai(targetMenPai)
end

function script_base:LuaFnHasTeam(selfId)
    local obj = self.scene:get_obj_by_id(selfId)
    if not obj or not obj.get_team_id then
        return false
    end
    local team_id = obj:get_team_id()
    print("script_base:LuaFnHasTeam obj_name =", obj:get_name(), ";team_id =", team_id)
    return team_id ~= define.INVAILD_ID
end

function script_base:LuaFnGetTeamSceneMemberCount(selfId)
    local obj = self.scene:get_obj_by_id(selfId)
    return obj:get_team_info():get_scene_member_count()
end

function script_base:LuaFnGetTeamSceneMember(selfId, i)
    local obj = self.scene:get_obj_by_id(selfId)
    return obj:get_team_info():get_scene_member_obj_id(i)
end

function script_base:LuaFnIsCanDoScriptLogic(selfId)
    return true
end

function script_base:NewWorld(selfId, dest_scene_id, sn, x, y, client_res)
	local sceneId = self:get_scene_id()
    assert(dest_scene_id and dest_scene_id ~= define.INVAILD_ID and dest_scene_id ~= sceneId, "传送的目标场景不正确")
    assert(x ~= nil, "传送的目标X坐标不能为空")
    assert(y ~= nil, "传送的目标Y坐标不能为空")
    local obj = self.scene:get_obj_by_id(selfId)
    assert(obj, selfId)
    if sn then
        obj:save_restore_scene_and_pos(sn)
    end
    client_res = client_res or self.scene:get_specifi_scene_client_res(dest_scene_id)
    self.scene:notify_change_scene(selfId, dest_scene_id, x, y, client_res)
    self:LogEnterCopyScene(obj, dest_scene_id, sn, x, y, client_res)
end

function script_base:LogEnterCopyScene(obj, dest_scene_id, sn, x, y, client_res)
    if sn then
        local collection = "enter_copy_scene_rec"
        local address = skynet.localname(string.format(".SCENE_%d", dest_scene_id))
        address = skynet.address(address)
        local doc = {
            name = obj:get_name(),
            guid = obj:get_guid(),
            dest_scene_id = dest_scene_id,
            address = address,
            sn = sn,
            x = x,
            y = y,
            client_res = client_res,
            time = os.time(),
            date_time = utils.get_day_time(),
            tid = obj:get_team_id(),
            process_id = tonumber(skynet.getenv "process_id")
        }
        if sn then
            skynet.send(".logdb", "lua", "insert", { collection = collection, doc = doc})
        end
    end
end

function script_base:GetTeamId(selfId)
    local obj = self.scene:get_obj_by_id(selfId)
    return obj:get_team_id()
end

function script_base:GetRaidId(selfId)
    local obj = self.scene:get_obj_by_id(selfId)
    return obj:get_raid_id()
end

function script_base:GetUnitCampID(selfId)
    local obj = self.scene:get_obj_by_id(selfId)
    return obj:get_camp_id()
end

function script_base:SetUnitCampID(selfId, camp_id)
    local obj = self.scene:get_obj_by_id(selfId)
    obj:set_temp_camp_id(camp_id)
    print("SetUnitCampID obj_id =", selfId, ";camp_id =", camp_id)
end

function script_base:LuaFnAddMissionHuoYueZhi(selfId, type)
    local human = self:get_scene():get_obj_by_id(selfId)
    human:add_mission_huoyuezhi(type)
end

function script_base:LuaFnAddMissionHuoYueZhiSilent(selfId, type)
    local human = self:get_scene():get_obj_by_id(selfId)
    return human:add_mission_huoyuezhi(type, 1, false)
end

function script_base:LuaFnRestMysteryShopInfo(selfId)
    local human = self:get_scene():get_obj_by_id(selfId)
    human:reset_mystery_shop_info()
end

function script_base:LuaFnResetWeekActiveDay(selfId)
    local human = self:get_scene():get_obj_by_id(selfId)
    local week_active = human:get_week_active()
    for i = 1, 0x2A do
        week_active.can_get[i] = 0
        week_active.getd[i] = 0
        week_active.activity_finish_count[i] = 0
    end
    week_active.day_get = 0
end

function script_base:LuaFnResetWeekActiveWeek(selfId)
    local human = self:get_scene():get_obj_by_id(selfId)
    local week_active = human:get_week_active()
    week_active.week_get = 0
    week_active.get_award_index = 0
end

function script_base:WeekActiveAddHuoYueZhi(selfId, id)
    id = tonumber(id)
    if id == nil or id ~= math.floor(id) then return false end
    local human = self:get_scene():get_obj_by_id(selfId)
    if human == nil then return false end
    local week_active = configenginer:get_config("week_active")
    local index
    local type
    for t, was in pairs(week_active) do
        for i, wa in ipairs(was) do
            if wa.id == id then
                index = i
                type = t
                break
            end
        end
        if index ~= nil then break end
    end
    if index == nil or type == nil then return false end

    local data = human:get_week_active()
    data.can_get[type] = math.max(0, math.floor(tonumber(data.can_get[type]) or 0))
    data.getd[type] = math.max(0, math.floor(tonumber(data.getd[type]) or 0))
    local active = week_active[type][index]
    if index ~= data.getd[type] + 1 then
        return false
    end
    if data.can_get[type] < active.target then
        return false
    end
    local num = math.max(0, math.floor(tonumber(active.award_num) or 0))
    data.getd[type] = index
    data.day_get = math.min(0x7FFFFFFF, (tonumber(data.day_get) or 0) + num)
    data.week_get = math.min(0x7FFFFFFF, (tonumber(data.week_get) or 0) + num)
    if num > 0 then
        self:CallScriptFunction(998526, "AddPoint", selfId, num)
    end
    return true
end

function script_base:GetWeekActiveGetAwardIndex(selfId)
    local human = self:get_scene():get_obj_by_id(selfId)
    local weekactive = human:get_week_active()
    return weekactive.get_award_index
end

function script_base:SetWeekActiveGetAwardIndex(selfId, index)
    local human = self:get_scene():get_obj_by_id(selfId)
    local weekactive = human:get_week_active()
    weekactive.get_award_index = index
end

function script_base:GetWeekActiveHuoYue(selfId)
    local human = self:get_scene():get_obj_by_id(selfId)
    local weekactive = human:get_week_active()
    return weekactive.week_get
end

function script_base:LuaFnSetCopySceneData_Param(...)
    local args = { ... }
    if #args == 3 then
        local destsceneId, i, v = table.unpack(args)
        if destsceneId == define.INVAILD_ID then
            return define.INVAILD_ID
        end
        local scene = string.format(".SCENE_%d", destsceneId)
        return skynet.call(scene, "lua", "set_param", i, v)
    else
        local i, v = table.unpack(args)
        return self.scene:set_param(i, v)
    end
end

function script_base:LuaFnSetSceneData_Param(...)
    self:LuaFnSetCopySceneData_Param(...)
end

function script_base:LuaFnGetSceneData_Param(...)
    return self:LuaFnGetCopySceneData_Param(...)
end

function script_base:LuaFnGetCopyScene_HumanCount()
    return self.scene:get_human_count()
end

function script_base:LuaFnGetCopyScene_HumanObjId(i)
    return self.scene:get_human_obj_id(i)
end

function script_base:LuaFnIsObjValid(selfId)
    local obj = self.scene:get_obj_by_id(selfId)
    return obj ~= nil
end

function script_base:LuaFnGuid2ObjId(guid)
    local obj = self.scene:get_obj_by_guid(guid)
    if not obj then
        return define.INVAILD_ID
    end
    return obj:get_obj_id()
end

function script_base:LuaFnGetCopySceneData_Sn(destsceneid)
    local scene = string.format(".SCENE_%d", destsceneid)
    if destsceneid == define.INVAILD_ID then
        return define.INVAILD_ID
    end
    return skynet.call(scene, "lua", "get_sn")
end

function script_base:SetPvpAuthorizationFlagByID(selfId, mode)
    local obj = self.scene:get_obj_by_id(selfId)
    obj:change_pk_mode(mode)
end

function script_base:SetPlayerPvpMode(selfId, mode)
    local obj = self.scene:get_obj_by_id(selfId)
    obj:change_pk_mode(mode)
end

function script_base:SetPlayerPvpRule(selfId, rule)
    local pvp_rule = configenginer:get_config("pvp_rule")
    pvp_rule = pvp_rule[rule]
    local obj = self.scene:get_obj_by_id(selfId)
    obj:set_pvp_rule(pvp_rule)
end

function script_base:GetDayTime()
    local date = os.date("*t")
    return (date.year % 100) * 1000 + date.yday
end

function script_base:LuaFnGenCopySceneSN()
    return skynet.call(".Copyscenemanager", "lua", "gen_sn")
end

function script_base:LuaFnGetWorldPos(selfId)
    return self:GetWorldPos(selfId)
end

function script_base:IsCaptain(selfId)
    local obj = self.scene:get_obj_by_id(selfId)
    return obj:get_is_team_leader()
end

function script_base:LuaFnIsTeamLeader(selfId)
    return self:IsCaptain(selfId)
end

function script_base:LuaFnGetFollowedMembersCount(selfId)
    local human = self.scene:get_obj_by_id(selfId)
	assert(human,"script_base:LuaFnGetFollowedMembersCount 对象不存在。")
    return human:get_team_info():get_followed_members_count()
end

function script_base:GetFollowedMember(selfId, index)
    local human = self.scene:get_obj_by_id(selfId)
	assert(human,"script_base:GetFollowedMember 对象不存在。")
    local followd_member = human:get_team_info():get_followed_member(index)
    if not followd_member then return define.INVAILD_ID end
    followd_member = self.scene:get_obj_by_guid(followd_member.guid)
    if followd_member and followd_member:get_team_id() ~= human:get_team_id() then return define.INVAILD_ID end
    if followd_member then
        return followd_member:get_obj_id()
    end
    return define.INVAILD_ID
end

function script_base:SetObjDir(selfId, dir)
    local obj = self.scene:get_obj_by_id(selfId)
end

function script_base:SetMonsterFightWithNpcFlag(selfId, flag)
    local obj = self.scene:get_obj_by_id(selfId)
	assert(obj,"script_base:SetMonsterFightWithNpcFlag 对象不存在。")
    obj:set_fight_with_npc_flag(flag)
end

function script_base:SetCharacterTitle(selfId, title)
    local obj = self.scene:get_obj_by_id(selfId)
	assert(obj,"script_base:SetCharacterTitle 对象不存在。")
    obj:set_title(title)
end

function script_base:GetMonsterCount()
    return self.scene:get_monster_count()
end

function script_base:GetMonsterObjID(i)
    return self.scene:get_monster_obj_id(i)
end

function script_base:GetMonsterDataID(selfId)
    local obj = self.scene:get_obj_by_id(selfId)
	assert(obj,"script_base:GetMonsterDataID 对象不存在。")
    return obj:get_model()
end

function script_base:CurSceneHaveMonster(data_id)
    local monster_count = self:GetMonsterCount()
    for i = 1, monster_count do
        local objid = self:GetMonsterObjID(i)
        if data_id == self:GetMonsterDataID(objid) then
            return true
        end
    end
    return false
end

function script_base:LuaFnIsCharacterLiving(selfId)
    local obj = self.scene:get_obj_by_id(selfId)
	assert(obj,"script_base:LuaFnIsCharacterLiving 对象不存在。")
    return obj:is_alive()
end

function script_base:GetCharacterType(selfId)
    local obj = self.scene:get_obj_by_id(selfId)
	assert(obj,"script_base:GetCharacterType 对象不存在。")
    return obj:get_obj_type()
end

function script_base:GetPetCreator(selfId)
    local obj = self.scene:get_obj_by_id(selfId)
	assert(obj,"script_base:GetPetCreator 对象不存在。")
    assert(obj:get_obj_type() == "pet")
    return obj:get_owner_obj_id()
end

function script_base:AddGlobalCountNews(message, transferd)
    local selfId = define.INVAILD_ID
    if not transferd then
        message = gbk.fromutf8(message)
    end
    self:BroadMsgByChatPipe(selfId, message, 4)
end
function script_base:AddGlobalCountNews_Fun(scriptid,funname,message)
	if not scriptid or scriptid < 1 or scriptid > 999999 then
		return
	elseif not funname or funname == "" then
		return
	elseif not message or message == "" then
		return
	end
	local script_str = string.format("%06d",scriptid)
	message = gbk.fromutf8(message)
	local strText = "@*;SrvMsg;SCA:#{_NEWMSG_"..script_str..funname.."}"..message
	local msg = packet_def.GCChat.new()
	msg.ChatType = 4
	msg.Sourceid = define.INVAILD_ID
	msg.unknow_2 = 1
	msg:set_content(strText)
	skynet.send(".world", "lua", "multicast", msg)
end

function script_base:MonsterAI_GetBoolParamByIndex(selfId, i)
    local obj = self.scene:get_obj_by_id(selfId)
	if not obj then
		skynet.logi("script_base:MonsterAI_GetBoolParamByIndex selfId = ", selfId, "stack =", debug.traceback())
		assert(false)
	end
    local ai = obj:get_ai()
    local v = ai:get_bool_param_by_index(i)
    return v
end

function script_base:MonsterAI_GetIntParamByIndex(selfId, i)
    local obj = self.scene:get_obj_by_id(selfId)
	assert(obj,"script_base:MonsterAI_GetIntParamByIndex 对象不存在。")
    local ai = obj:get_ai()
    local v = ai:get_int_param_by_index(i)
    return v
end

function script_base:MonsterAI_SetIntParamByIndex(selfId, i, v)
    local obj = self.scene:get_obj_by_id(selfId)
	assert(obj,"script_base:MonsterAI_SetIntParamByIndex 对象不存在。")
    local ai = obj:get_ai()
    ai:set_int_param_by_index(i, v)
end

function script_base:MonsterAI_GetStringParamByIndex(selfId, i)
    local obj = self.scene:get_obj_by_id(selfId)
	assert(obj,"script_base:MonsterAI_GetStringParamByIndex 对象不存在。")
    local ai = obj:get_ai()
    local v = ai:get_string_param_by_index(i)
    return v
end

function script_base:MonsterAI_SetStringParamByIndex(selfId, i, v)
    local obj = self.scene:get_obj_by_id(selfId)
	assert(obj,"script_base:MonsterAI_SetStringParamByIndex 对象不存在。")
    local ai = obj:get_ai()
    ai:set_string_param_by_index(i, v)
end

function script_base:MonsterAI_SetBoolParamByIndex(selfId, i, v)
    local obj = self.scene:get_obj_by_id(selfId)
	assert(obj,"script_base:MonsterAI_SetBoolParamByIndex 对象不存在。")
    local ai = obj:get_ai()
    ai:set_bool_param_by_index(i, v)
end

function script_base:LuaFnDeleteMonster(selfId)
    local obj = self.scene:get_obj_by_id(selfId)
	assert(obj,"script_base:LuaFnDeleteMonster 对象不存在。")
	if obj:get_obj_type() == "human" then
		skynet.logi("欲直接删除玩家:selfId = ", selfId, "stack =", debug.traceback())
		return
	end
	
    self.scene:delete_temp_monster(obj)
end

function script_base:LuaFnCancelSpecificImpact(selfId, data_index)
    local obj = self.scene:get_obj_by_id(selfId)
	assert(obj,"script_base:LuaFnCancelSpecificImpact 对象不存在。")
    obj:impact_cancel_impact_in_specific_data_index(data_index)
end

function script_base:LuaFnCancelImpactInSpecificImpact(selfId, id)
    local human = self.scene:get_obj_by_id(selfId)
	assert(human,"script_base:LuaFnCancelImpactInSpecificImpact 对象不存在。")
    human:impact_cancel_impact_in_specific_collection(id)
end

function script_base:LuaFnHaveImpactInSpecificCollection(selfId, id)
    local human = self.scene:get_obj_by_id(selfId)
	assert(human,"script_base:LuaFnHaveImpactInSpecificCollection 对象不存在。")
    return human:impact_have_impact_in_specific_collection(id)
end

function script_base:MonsterNewTalk(selfId, str)
    local monster = self:get_scene():get_obj_by_id(selfId)
	if not monster then
		return
	end
    local msg = packet_def.GCMonsterSpeak.new()
    msg.m_objID = selfId
    msg.speek_content = str
    monster:get_scene():broadcast(monster, msg, false)
end

function script_base:MonsterTalk(...)
    local args = { ... }
    local selfId, sceneName, str
    if #args == 2 then
        selfId = args[1]
        sceneName = ""
        str = args[2]
    else
        selfId = args[1]
        sceneName = args[2]
        str = args[3]
    end
    local monster_name = ""
    if selfId ~= define.INVAILD_ID then
        local monster = self:get_scene():get_obj_by_id(selfId)
        if monster then
            monster_name = monster:get_name()
        end
    end
    local strText = string.format("@*;npctalk;%s;%s;7575;0;%s", monster_name, sceneName, str)
    strText = gbk.fromutf8(strText)
    local msg = packet_def.GCChat.new()
    msg.ChatType = 2
    msg.Sourceid = selfId
    msg.unknow_2 = 1
    msg:set_content(strText)
    self:get_scene():broadcastall(msg)
end

function script_base:LuaFnUnitUseSkill(selfId, skill_id, targetId, x, z, dir, pass_check)
    local obj = self.scene:get_obj_by_id(selfId)
    pass_check = pass_check == 1
    obj:skill_exec_from_script(skill_id, targetId, x, z, dir, pass_check)
end

function script_base:GetMonsterCurEnemy(selfId)
    local obj = self.scene:get_obj_by_id(selfId)
    local ai = obj:get_ai()
    return ai:get_cur_enemy_id()
end

function script_base:SetCharacterName(selfId, name)
    local obj = self.scene:get_obj_by_id(selfId)
    obj:set_name(name)
end

function script_base:CreateSpecialObjByDataIndex(selfId, data_index, x, y, continuance)
    local obj = self.scene:get_obj_by_id(selfId)
    local world_pos = { x = x, y = y}
    local obj_special = obj:skill_create_obj_specail(world_pos, data_index)
    if continuance then
        obj_special:set_continuance(continuance)
    end
end

function script_base:LuaFnCreateSpecialObjByDataIndex(...)
    return self:CreateSpecialObjByDataIndex(...)
end

function script_base:LuaFnNpcChat()

end

function script_base:LuaFnSetSceneWeather(weather, time)
    self.scene:set_weather(weather, time)
end

function script_base:LuaFnGetSceneWeather()
    return self.scene:get_weather() or define.INVAILD_ID
end

function script_base:SetPatrolId(selfId, id)
    local obj = self.scene:get_obj_by_id(selfId)
    obj:set_patrol_id(id)
end

function script_base:GetPatrolId(selfId)
    local obj = self.scene:get_obj_by_id(selfId)
    return obj:get_patrol_id()
end

function script_base:IsEquipKfs(selfId)
    local obj = self.scene:get_obj_by_id(selfId)
    assert(obj, selfId)
    local container = obj:get_equip_container()
    local BagPos = define.HUMAN_EQUIP.HEQUIP_WUHUN
    local Item = container:get_item(BagPos)
    return Item ~= nil
end

function script_base:IsHaveMission(selfId, mission_id)
    local obj = self.scene:get_obj_by_id(selfId)
    assert(obj, selfId)
    return obj:is_have_mission(mission_id)
end

function script_base:GetMissionIndexByID(selfId, mission_id)
    local obj = self.scene:get_obj_by_id(selfId)
    assert(obj, selfId)
    return obj:get_mission_index(mission_id)
end

function script_base:GetMissionParam(selfId, mission_index, index)
    local obj = self.scene:get_obj_by_id(selfId)
    assert(obj, selfId)
    return obj:get_mission_param(mission_index, index)
end

function script_base:SetMissionByIndex(selfId, mission_index, index, value)
    local obj = self.scene:get_obj_by_id(selfId)
    assert(obj, selfId)
    return obj:set_mission_by_index(mission_index, index, value)
end

function script_base:DelMission(selfId, mission_id)
    local obj = self.scene:get_obj_by_id(selfId)
    assert(obj, selfId)
    return obj:del_mission(mission_id)
end

function script_base:DelAllMission(selfId)
    local obj = self.scene:get_obj_by_id(selfId)
    assert(obj, selfId)
    return obj:del_all_mission()
end

function script_base:AddMission(selfId, mission_id, script_id, killObjEvent, enterAreaEvent, itemChangeEvent)
    local obj = self.scene:get_obj_by_id(selfId)
    assert(obj, selfId)
    return obj:add_mission(mission_id, script_id, killObjEvent, enterAreaEvent, itemChangeEvent)
end

function script_base:AddMissionEx(selfId, mission_id, script_id)
    local obj = self.scene:get_obj_by_id(selfId)
    assert(obj, selfId)
    return obj:add_mission(mission_id, script_id, 0, 0, 0)
end

function script_base:SetMissionEvent(selfId, mission_id, event_id)
    local obj = self.scene:get_obj_by_id(selfId)
    assert(obj, selfId)
    obj:set_mission_event(mission_id, event_id)
end

function script_base:GetHumanMenpaiPoint(selfId)
    return 0
end

function script_base:SetHumanMenpaiPoint(selfId, point)

end

function script_base:StartOneActivity(actId,on_time,noticetype,second,minute,hour)
    self.scene:add_activity(actId,on_time,second,minute,hour)
end

function script_base:CheckActiviyValidity(actId)
    local activity = self.scene.running_activitys[actId]
    if not activity then
        return false
    end
    return activity.tick_time < activity.on_time
end

function script_base:GetActivityTickTime(actId)
    local activity = self.scene.running_activitys[actId]
    if not activity then
        return 0
    end
    return activity.tick_time
end

function script_base:StopOneActivity(actId)
    self.scene.running_activitys[actId] = nil
end

function script_base:HaveActivity(actId)
	if self.scene.running_activitys[actId] then
		return true
	end
end
function script_base:SetActivityTick(actId,key)
	local Activity = self.scene.running_activitys[actId]
	if Activity then
		Activity[key] = true
	end
end
function script_base:DelActivityTick(actId,key)
	local Activity = self.scene.running_activitys[actId]
	if Activity then
		Activity[key] = nil
	end
end

function script_base:GetActivityParamEx(actId,index)
    return self.scene:get_activity_scene_param_on_key(actId,index)
end

function script_base:GetActivityParam(actId, index)
    return self.scene:get_activity_param(actId, index)
end

function script_base:SetActivityParam(actId, index, value)
    self.scene:set_activity_param(actId, index, value)
end

function script_base:IsMissionFull(selfId)
    local obj = self.scene:get_obj_by_id(selfId)
    assert(obj, selfId)
    return obj:is_mission_full()
end

function script_base:GetHumanGUID(selfId)
    local obj = self.scene:get_obj_by_id(selfId)
    assert(obj, selfId)
    return obj:get_guid()
end

function script_base:IsCanEnterCopyScene(copysceneid, selfId)
    if copysceneid == define.INVAILD_ID then
        return false
    end
    local scene = string.format(".SCENE_%d", copysceneid)
    local sn = skynet.call(scene, "lua", "get_sn")
    local obj = self.scene:get_obj_by_id(selfId)
    assert(obj, selfId)
    local restore_sn = obj:get_copy_scene_sn()
    return restore_sn == sn
end

function script_base:IsAuthorizedCopyScenePlayer(selfId, team_param_index, mission_id, mission_scene_param_index)
    local owner_team_id = self:LuaFnGetCopySceneData_Param(team_param_index)
    local current_team_id = self:GetTeamId(selfId)
    if not owner_team_id or owner_team_id < 0 or current_team_id ~= owner_team_id then
        return false
    end
    if mission_id then
        if not self:IsHaveMission(selfId, mission_id) then
            return false
        end
        local mission_index = self:GetMissionIndexByID(selfId, mission_id)
        if not mission_index or mission_index < 0 then
            return false
        end
        local mission_scene_id = self:GetMissionParam(selfId, mission_index, mission_scene_param_index)
        if mission_scene_id ~= self:get_scene_id() then
            return false
        end
    end
    return true
end

function script_base:IsCopySceneOwnerTeamMember(selfId, copy_scene_id, team_param_index)
    local owner_team_id = self:LuaFnGetCopySceneData_Param(copy_scene_id, team_param_index)
    local current_team_id = self:GetTeamId(selfId)
    return owner_team_id and owner_team_id >= 0 and current_team_id == owner_team_id
end

function script_base:OnPlayerLeave(selfId)
end

function script_base:LuaFnGetDRideFlag(selfId)
    return false
end

function script_base:IsTeamFollow(selfId)
    local human = self.scene:get_obj_by_id(selfId)
    return human:get_team_follow_flag()
end

function script_base:LuaFnGetLevel(selfId)
    return self:GetLevel(selfId)
end

function script_base:GetCharacterLevel(selfId)
    return self:GetLevel(selfId)
end

function script_base:IsMissionHaveDone(selfId, mission_id)
    local human = self:get_scene():get_obj_by_id(selfId)
    return human:get_mission_have_done(mission_id)
end

function script_base:GetItemCount(selfId, item_index)
    return self:LuaFnGetAvailableItemCount(selfId, item_index)
end

function script_base:IsShutout()
    return false
end

function script_base:GetConfigInfo()

end

function script_base:LuaFnOpenPWBox()
    return 0
end

function script_base:LuaFnSendScriptMail(reciver, param_1, param_2, param_3, param_4, param_5)
    local mail = {}
    mail.guid = define.INVAILD_ID
    mail.source = ""
    mail.portrait_id = define.INVAILD_ID
    mail.dest = reciver
    mail.content = ""
    mail.flag = define.MAIL_TYPE.MAIL_TYPE_SCRIPT
    mail.create_time = os.time()
    mail.param_1 = param_1
    mail.param_2 = param_2
    mail.param_3 = param_3
    mail.param_4 = param_4
    mail.param_5 = param_5
    skynet.send(".world", "lua", "send_mail", mail)
end

function script_base:LuaFnAskNpcScriptMail(selfId, type)
    local human = self:get_scene():get_obj_by_id(selfId)
    if type == ScriptGlobal.MAIL_COMMISIONSHOP then
        local reciver = human:get_name()
        local merchadises = commisionshopmanager:get_sold_out_merchadise_by_name(reciver)
        for _, merchadise in ipairs(merchadises) do
            local price = math.floor(merchadise.price * (100 - 2) / 100) 
            self:LuaFnSendScriptMail(reciver, ScriptGlobal.MAIL_COMMISIONSHOP, 2, merchadise.serial, price)
        end
        local timeout_merchadises = commisionshopmanager:get_time_out_merchadise_by_name(reciver)
        for _, merchadise in ipairs(timeout_merchadises) do
            self:LuaFnSendScriptMail(reciver, ScriptGlobal.MAIL_COMMISIONSHOP, 0, merchadise.serial, merchadise.name)
        end
    end
end

function script_base:GetCommisionShop(selfId, targetId, Grade)
    local human = self:get_scene():get_obj_by_id(selfId)
    local msg = packet_def.GCPacketStream.new()
    msg.id = 1
    local cs = packet_def.CommisionShop.new()
    cs.merchadise_list = commisionshopmanager:get_merchadise_list_by_grade(Grade)
    cs.grade = Grade
    cs.target_id = targetId
    msg.args = cs:bos()
    self:get_scene():send2client(human, msg)
end

local CommisionShopGrades = {
    [0] = 50,
    [1] = 200,
    [2] = 500,
}

local CommisionShopIds = {
    ["汀汀"] = 0,
    ["冬冬"] = 1,
}
function script_base:CommisionShopSell(selfId, targetId, Grade, Price)
    local name = CommisionShopGrades[Grade]
    assert(name, Grade)
    local human = self:get_scene():get_obj_by_id(selfId)
    local yuanbao = human:get_yuanbao()
    if yuanbao < name then
        return false
    end
    local empty_index = commisionshopmanager:get_empty_index_by_grade(Grade)
    if empty_index == nil then
        return false
    end
    human:set_yuanbao(yuanbao - name,"寄售元宝",nil,true)
    local merchadise = {}
    merchadise.name = name
    merchadise.price = Price
    merchadise.type = Grade
    merchadise.seller = human:get_name()
    commisionshopmanager:set_item_by_grade_with_index(Grade, empty_index, merchadise)
    local npc = self:get_scene():get_obj_by_id(targetId)
    local shopId = CommisionShopIds[npc:get_name()] or 0
    return true, shopId, 0, name, Price
end

function script_base:CommisionShopBuy(selfId, targetId, Grade, SerialNumber)
    local human = self:get_scene():get_obj_by_id(selfId)
    local merchadise = commisionshopmanager:get_merchadise_by_serial(SerialNumber)
    if merchadise == nil then
        return false
    end
    local money = human:get_money()
    local yuanbao = human:get_yuanbao()
    local price = merchadise.price
    assert(price > 0, price)
    if money < price then
        return false
    end
    human:set_money(money - price, "CommisionShopBuy")
    human:add_yuanbao(merchadise.name, "CommisionShopBuy")
    commisionshopmanager:mark_merchadise_sold_out_by_serial(SerialNumber)
    local npc = self:get_scene():get_obj_by_id(targetId)
    local shopId = CommisionShopIds[npc:get_name()] or 0
    return true, shopId, 0, merchadise.name, price, merchadise.seller
end

function script_base:GetCommisionShopItem(shopId, itemserial)
    local merchadise = commisionshopmanager:get_merchadise_by_serial(itemserial)
    if merchadise == nil then
        return false
    end
    return true, merchadise.type, merchadise.name, merchadise.price, merchadise.seller 
end

function script_base:CSAddYuanbao(selfId, count, log)
    local human = self:get_scene():get_obj_by_id(selfId)
    human:add_yuanbao(count, "脚本增加元宝", log)
end

function script_base:CSAddBankMoney(selfId, count, log)
    local human = self:get_scene():get_obj_by_id(selfId)
    human:add_money(count, "脚本调用添加金币")
end

function script_base:LogCommisionDeal()

end

function script_base:DecCommisionNum()

end

function script_base:GetHumanGuildID(selfId)
    local human = self:get_scene():get_obj_by_id(selfId)
    return human:get_guild_id()
end

function script_base:GetCityGuildID()
    return self.scene:get_guild_id()
end

function script_base:CityMoveToPort(selfId)
    local city_id = self.scene:get_city_id()
    local city_info = configenginer:get_config("city_info")
    city_info = city_info[city_id]
    local scene_id = city_info["入口场景ID"]
    local x = city_info["入口X坐标"]
    local y = city_info["入口Y坐标"]
    self:CallScriptFunction((400900), "TransferFunc", selfId, scene_id, x, y)
end

function script_base:CityGetBuildingLevel()
    return 1
end

function script_base:GetGuildContriTitle()
    return ""
end

function script_base:CityGetSelfCityID(selfId)
    local human = self:get_scene():get_obj_by_id(selfId)
    local guild_id = human:get_guild_id()
    local guild = skynet.call(".Guildmanager", "lua", "get_guild_by_id", guild_id)
    if guild == nil then
        return define.INVAILD_ID    
    end
    return guild.city_id or define.INVAILD_ID
end

function script_base:GetTeamMemberCount(selfId)
    return self:GetTeamSize(selfId)
end

function script_base:SetMonsterGroupID(selfId, id)
    local obj = self.scene:get_obj_by_id(selfId)
    assert(obj, selfId)
    assert(obj:get_obj_type() == "monster")
    obj:set_group_id(id)
end

function script_base:GetMonsterGroupID(selfId)
    local obj = self.scene:get_obj_by_id(selfId)
    assert(obj, selfId)
    assert(obj:get_obj_type() == "monster")
    return obj:get_group_id()
end

function script_base:LuaFnAuditQuest()

end

function script_base:LuaFnAddSalaryPoint()

end

function script_base:GetMonsterNamebyDataId(data_id)
    local monster_attr_ex = configenginer:get_config("monster_attr_ex")
    monster_attr_ex = monster_attr_ex[data_id]
    return monster_attr_ex.name
end

function script_base:GetMissionCount(selfId)
    local obj = self.scene:get_obj_by_id(selfId)
    assert(obj, selfId)
    return obj:get_mission_count()
end

function script_base:GetLastPatrolPoint(index)
    local point = self.scene:get_last_partrol_point(index)
    return point.x, point.y
end

function script_base:GetQuarterTime()
    local date = os.date("*t")
    local ke = (date.hour * 60 + date.min) // 15
    return ke
end

function script_base:LuaFnGetTaskItemBagSpace(selfId)
    local obj = self.scene:get_obj_by_id(selfId)
    assert(obj, selfId)
    local container = obj:get_prop_bag_container()
    return container:cal_item_space("task")
end

function script_base:AddExp(selfId, exp)
    local obj = self.scene:get_obj_by_id(selfId)
    assert(obj, selfId)
    obj:add_exp(exp, 0)
end

function script_base:LuaFnAddExp(selfId, exp)
    self:AddExp(selfId, exp)
end

function script_base:AddMonsterDropItem(selfId, humanObjId, item)
    local obj = self.scene:get_obj_by_id(selfId)
    local human = self.scene:get_obj_by_id(humanObjId)
    obj:add_owner_drop_item(human, item)
end

function script_base:LuaFnAuditGPS()

end

function script_base:LuaFnGetUnitPosition(selfId)
    return self:GetWorldPos(selfId)
end

function script_base:GetCommonItemGrade(itemIndex)
    local common_item = configenginer:get_config("common_item")
    common_item = common_item[itemIndex]
    return common_item.grade
end

function script_base:SetPos(selfId, opx, opy)
    self:TelePort(selfId, opx, opy)
end

function script_base:MissionLog()

end

function script_base:HaveItem()
    return true
end

function script_base:HaveItemInBag(selfId, item_index)
    return self:LuaFnGetAvailableItemCount(selfId, item_index) > 0
end

function script_base:DelItem(selfId, item_index, count)
    return self:LuaFnDelAvailableItem(selfId, item_index, count or 1)
end

function script_base:Abandon_Necessary(selfId)

end

function script_base:ResetMissionCacheData(selfId)
    local obj = self.scene:get_obj_by_id(selfId)
    obj:reset_mission_cache_data()
end

function script_base:SetMissionCacheData(selfId, id, val)
    local obj = self.scene:get_obj_by_id(selfId)
    obj:set_mission_cache_data(id, val)
end

function script_base:GetMissionCacheData(selfId, id)
    local obj = self.scene:get_obj_by_id(selfId)
    return obj:get_mission_cache_data(id)
end

function script_base:CreatePetOnScene(petDataID, posX, posZ)
    return self.scene:create_wild_pet(petDataID, posX, posZ)
end

function script_base:SetPetCaptureProtect(petObjID, occupantGuid)
    local obj = self.scene:get_obj_by_id(petObjID)
    print("SetPetCaptureProtect obj =", obj, ";petObjID =", petObjID)
    obj:set_capture_protect(occupantGuid)
end

function script_base:LuaFnAuditPetCreate()

end

function script_base:LuaFnGetOccupantGUID(selfId)
    local obj = self.scene:get_obj_by_id(selfId)
    return obj:get_occupant_guid() 
end

function script_base:GuildCreate(selfId, targetId)
    local obj = self.scene:get_obj_by_id(selfId)
    local guild_id = obj:get_guild_id() or define.INVAILD_ID
	if ScriptGlobal.is_internal_test then
		obj:notify_tips("内测中，无法创建帮会")
        return
	end
    if guild_id ~= define.INVAILD_ID then
        obj:notify_tips("您已加入一个帮会，无法创建帮会")
        return
    end
    local level = obj:get_level()
    if level < 40 then
        obj:notify_tips("等级达到40级才能创建帮会")
        return
    end
    local msg = packet_def.GCGuildApply.new()
    msg.m_NpcId = targetId
    obj:get_scene():send2client(obj, msg)
end

function script_base:GuildList(selfId)
    local guild_list = skynet.call(".Guildmanager", "lua", "get_guild_list")
    local obj = self.scene:get_obj_by_id(selfId)
    local msg = packet_def.GCGuild.new()
    msg.packet_type = 57
    msg.askid = 0
    msg.start_index = 1
    msg.camp = define.INVAILD_ID
    msg.guild_count = #guild_list
    msg.guild_list = guild_list
    obj:get_scene():send2client(obj, msg)
end

function script_base:CityApply(selfId)
    local city_info = configenginer:get_config("city_info")
    local msg = packet_def.GCCityList.new()
    msg.city_list = {}
    for i = 1, 0x36 do
        msg.city_list[i] = 2
    end
    local city_list = skynet.call(".Dynamicscenemanager", "lua", "get_city_list")
    for _, city in ipairs(city_list) do
        local id = city.id
        local this_city_info = city_info[id]
        local enter_group = this_city_info["入口组"] + 1
        msg.city_list[enter_group] = msg.city_list[enter_group] - 1
    end
    self:get_scene():send2client(selfId, msg)
end

function script_base:LuaFnGetAbilityLevelUpConfig(id, level)
    return self:LuaFnGetAbilityLevelUpConfig2(id, level)
end

function script_base:LuaFnGetAbilityLevelUpConfig2(id, level)
    local ability = configenginer:get_config("ability")
    ability = ability[id]
    local config2name = ability["升级需求和消耗表"]
    local fullname
    config2name = string.gsub(config2name, "%.txt", "")
    if config2name == "menpaishenghuo" then
        fullname = config2name
    else
        print("LuaFnGetAbilityLevelUpConfig2 ability =", table.tostr(ability))
        print("LuaFnGetAbilityLevelUpConfig2 config2name =", fullname)
        fullname = "ability_level_up_" .. config2name
        print("LuaFnGetAbilityLevelUpConfig2 fullname =", fullname)
    end
    local config2 = configenginer:get_config(fullname)
    local level_config = config2[level]
    return true, level_config["需求金钱"], level_config["需求经验"], 
        level_config["技能熟练度限制"], level_config["技能熟练度限制(客户端显示)"], 
        level_config["本级熟练度的上限"], level_config["等级限制"], level_config["NPC需求金钱"], 
        level_config["NPC需求经验"]
end

function script_base:LuaFnAuditLearnLifeAbility()

end

function script_base:GetBasicBagStartPos()
    return 0
end

function script_base:GetBasicBagEndPos()
    return 99
end

function script_base:LuaFnGetMaterialStartBagPos()
    return 100
end

function script_base:LuaFnAuditAbility()

end

function script_base:LuaFnAuditShenQi()

end

function script_base:AuditShiTuZongDongYuan()

end

function script_base:SetAbilityExp(selfId, AbilityId, exp, exp_top)
    local human = self:get_scene():get_obj_by_id(selfId)
    human:set_ability_exp(AbilityId, exp, exp_top)
end

function script_base:GetAbilityExp(selfId, AbilityId)
    local human = self:get_scene():get_obj_by_id(selfId)
    return human:get_ability_exp(AbilityId)
end

function script_base:LuaFnGetShenqiUpgradeInfo(weaponID, MenpaiID)
    local super_weapon_up = configenginer:get_config("super_weapon_up")
    super_weapon_up = super_weapon_up[weaponID]
    local nNeedMoney = super_weapon_up["花费金币"]
    local nMaterial_1 = super_weapon_up["神兵符"]
    local nMaterial_2 = super_weapon_up["辅助材料1"]
    local nMaterial_3 = super_weapon_up["辅助材料2"]
    local nNewItemID
    if MenpaiID == define.MENPAI_ATTRIBUTE.MATTRIBUTE_SHAOLIN then
        nNewItemID = super_weapon_up["少林"]
    elseif MenpaiID == define.MENPAI_ATTRIBUTE.MATTRIBUTE_MINGJIAO then
        nNewItemID = super_weapon_up["明教"]
    elseif MenpaiID == define.MENPAI_ATTRIBUTE.MATTRIBUTE_GAIBANG then
        nNewItemID = super_weapon_up["丐帮"]
    elseif MenpaiID == define.MENPAI_ATTRIBUTE.MATTRIBUTE_WUDANG then
        nNewItemID = super_weapon_up["武当"]
    elseif MenpaiID == define.MENPAI_ATTRIBUTE.MATTRIBUTE_EMEI then
        nNewItemID = super_weapon_up["峨眉"]
    elseif MenpaiID == define.MENPAI_ATTRIBUTE.MATTRIBUTE_XINGXIU then
        nNewItemID = super_weapon_up["星宿"]
    elseif MenpaiID == define.MENPAI_ATTRIBUTE.MATTRIBUTE_DALI then
        nNewItemID = super_weapon_up["天龙"]
    elseif MenpaiID == define.MENPAI_ATTRIBUTE.MATTRIBUTE_TIANSHAN then
        nNewItemID = super_weapon_up["天山"]
    elseif MenpaiID == define.MENPAI_ATTRIBUTE.MATTRIBUTE_XIAOYAO then
        nNewItemID = super_weapon_up["逍遥"]
    elseif MenpaiID == define.MENPAI_ATTRIBUTE.MATTRIBUTE_WUMENPAI then
        nNewItemID = super_weapon_up["无门派"]
    elseif MenpaiID == define.MENPAI_ATTRIBUTE.MATTRIBUTE_MANTUOSHANZHUANG then
        nNewItemID = super_weapon_up["曼陀"]
    elseif MenpaiID == define.MENPAI_ATTRIBUTE.MATTRIBUTE_ERENGU then
        nNewItemID = super_weapon_up["恶人谷"]
    elseif MenpaiID == define.MENPAI_ATTRIBUTE.MATTRIBUTE_GUSU then
        nNewItemID = super_weapon_up["慕容"]
    end
    assert(nNewItemID, nNewItemID)
    return nNewItemID, nNeedMoney, nMaterial_1, nMaterial_2, nMaterial_3
end

function script_base:LuaFnRewashEquipAttr(selfId, nEquipPos, nNewItemID)
    local human = self.scene:get_obj_by_id(selfId)
    local container = human:get_prop_bag_container()
    local item = container:get_item(nEquipPos)
    assert(item, nEquipPos)
    local params,attr_types,values = item_operator:gen_equip_attrs(nNewItemID,1)
	params.attr_types = attr_types
	params.values = values
	params.new_item_index = nNewItemID
	params.item_guid = item:get_guid()
	params.quality = 6
    human:set_temp_super_attrs(params)
    local msg = packet_def.GCRefreshSuperAttr.new()
    msg.bagIndex = nEquipPos
    msg.attr_count = #attr_types
    msg.attr_type = params.attr_type
    msg.attr_values = values
    msg.item_index = nNewItemID
    human:get_scene():send2client(human, msg)
end

function script_base:LuaFnDarkUpGrade(selfId, nPos, nNewBPSZID)
    local human = self.scene:get_obj_by_id(selfId)
    local container = human:get_prop_bag_container()
    local anqi = container:get_item(nPos)
    assert(anqi, nPos)
    anqi:set_index(nNewBPSZID)
    local equip_base = anqi:get_base_config()
    if equip_base.equip_point ~= define.HUMAN_EQUIP.HEQUIP_ANQI then
        return false
    end
    local grow_rate = anqi:get_equip_data():get_aq_grow_rate()
    anqi:get_equip_data():set_aq_grow_rate(grow_rate + 400)
    anqi:get_equip_data():set_aq_xiulian(1)
    anqi:get_equip_data():set_aq_exp(0)
    anqi:get_equip_data():set_aq_xi_dian(0)
    for i = 1, 3 do
        anqi:get_equip_data():set_aq_skill(i, 0)
    end
    for i = 1, 5 do
        anqi:get_equip_data():set_aq_attr(i, 1)
    end
    anqi:get_equip_data():set_attr_count(5)
    local msg = packet_def.GCItemInfo.new()
    msg.bagIndex = nPos
    msg.item = anqi:copy_raw_data()
    human:get_scene():send2client(human, msg)
end

function script_base:RefreshSuperAttr(selfId, nEquipPos)
    local human = self.scene:get_obj_by_id(selfId)
    local container = human:get_prop_bag_container()
    local equip = container:get_item(nEquipPos)
    if not equip then
        return false
    end
    local super_attrs = human:get_temp_super_attrs()
	human:set_temp_super_attrs()
	if not super_attrs then
		human:notify_tips("替换失败，炼魂属性已取消")
		return
	end
	if equip:get_guid() ~= super_attrs.item_guid then
		human:notify_tips("替换失败，源炼魂神器不符")
		return
	end
	equip:set_index(super_attrs.new_item_index)
	local equip_data = equip:get_equip_data()
	equip_data:set_attr_count(#super_attrs.values)
	equip_data:set_attr_value(super_attrs.values)
	equip_data:set_attr_type(super_attrs.attr_type)
	equip_data:set_attr_types(super_attrs.attr_types)
    equip_data:set_quality(super_attrs.quality)
	equip_data:set_max_dur(super_attrs.max_dur)
	equip_data:set_visual(super_attrs.visual)
	equip:set_rule(super_attrs.rule)
	-- equip = bag_container:get_item(BagPos)
	local msg = packet_def.GCItemInfo.new()
	msg.bagIndex = nEquipPos
	msg.unknow_1 = 0
	msg.item = equip:copy_raw_data()
    human:get_scene():send2client(human, msg)
    return true
end

function script_base:LuaFnGetTargetObjID(selfId)
    local obj = self.scene:get_obj_by_id(selfId)
    local params = obj:get_targeting_and_depleting_params()
    return params:get_target_obj()
end

function script_base:LuaFnUnitIsFriend(selfId, targetId)
    local obj = self.scene:get_obj_by_id(selfId)
    local tar = self.scene:get_obj_by_id(targetId)
    return obj:is_friend(tar)
end

function script_base:AddHumanHairColor(selfId, color_value)
    local human = self.scene:get_obj_by_id(selfId)
	if not human then return end
    human:add_hair_color(color_value)
end

function script_base:SetHumanHairColor(selfId, hair_index)
    local human = self.scene:get_obj_by_id(selfId)
	if not human then return end
    human:set_hair_color(hair_index)
end

function script_base:GetWeaponlevelUpCost(selfId,visual,level)
    local exterior_weapon_levelup = configenginer:get_config("exterior_weapon_levelup")
	local needmoney,needitem,needcount = 0,0,0
	local have_weapon = exterior_weapon_levelup[visual]
	if have_weapon then
		local have_level = have_weapon[level]
		if have_level then
			needmoney,needitem,needcount = have_level[1],have_level[2],have_level[3]
		end
	end
	return needmoney,needitem,needcount
end

function script_base:GetWeaponVisualMaxLevel(selfId,visual)
    local exterior_weapon_visual = configenginer:get_config("exterior_weapon_visual")
	local visuals = exterior_weapon_visual[visual]["外观ID"]
	local maxlevel = define.INVAILD_ID
	if visuals then
		for i = 1,#visuals do
			if visuals[i] ~= define.INVAILD_ID then
				maxlevel = i - 1
			else
				break
			end
		end
	end
	return maxlevel
end

function script_base:GetWeaponVisualLevel(selfId,visual)
    local human = self.scene:get_obj_by_id(selfId)
    return human:get_weapon_visual_level(visual)
end

function script_base:SetWeaponVisualLevel(selfId,visual,level)
    local human = self.scene:get_obj_by_id(selfId)
	if not human then return end
	human:set_weapon_visual_level(visual,level)
end

function script_base:ActiveWeaponVisual(selfId, visual)
    local human = self.scene:get_obj_by_id(selfId)
    human:active_weapon_visual(visual)
end

function script_base:GetMonsterOwnerCount(selfId)
    local obj = self.scene:get_obj_by_id(selfId)
    local owners = obj:get_owners()
    return #owners
end

function script_base:GetMonsterOwnerID(selfId, i)
    local obj = self.scene:get_obj_by_id(selfId)
    local owners = obj:get_owners()
    return owners[i]:get_obj_id()
end

function script_base:SetTimer(playerId, ScriptId, func_name, delta_time)
    self.scene:set_timer(playerId, ScriptId, func_name, delta_time)
end

function script_base:CheckTimer(Index)
    return self.scene:check_timer(Index)
end

function script_base:ApplyPlayerShop(selfId, targetId)
    local human = self.scene:get_obj_by_id(selfId)
    local com_factor = playershopmanager:get_com_factor()
    local cost = 300000 * com_factor * 2 * 1.03
    local msg = packet_def.GCPlayerShopError.new()
    if human:get_level() < 30 then
        msg.error_code = define.PLAYER_SHOP_ERR.ERR_NOT_ENOUGH_LEVEL
        human:get_scene():send2client(human, msg)
        return
    end
    local shop_guids = human:get_shop_guids()
    local has_item = false
    local has_pet = false
    for _, guid in ipairs(shop_guids) do
        local shop = playershopmanager:get_player_shop_by_guid(guid)
        if shop then
            if shop:get_owner_guid() == human:get_guid() and shop:get_type() == shop.TYPE.ITEM then
                has_item = true
            end
            if shop:get_owner_guid() == human:get_guid() and shop:get_type() == shop.TYPE.PET then
                has_pet = true
            end
        end
    end
    if has_item and has_pet then
        msg.error_code = define.PLAYER_SHOP_ERR.ERR_ALREADY_HAVE_ENOUGH_SHOP
        human:get_scene():send2client(human, msg)
        return
    end
    msg = packet_def.GCPlayerShopApply.new()
    msg.com_factor = com_factor
    msg.cost = cost
    msg.npc_id = targetId
    if not has_item and not has_pet then
        msg.type = msg.TYPE.TYPE_BOTH
    elseif not has_item then 
        msg.type = msg.TYPE.TYPE_ITEM
    elseif not has_pet then
        msg.type = msg.TYPE.TYPE_PET
    end
    human:get_scene():send2client(human, msg)
end

function script_base:DispatchPlayerShopList(selfId, targetId)
    local human = self:get_scene():get_obj_by_id(selfId)
    local playershops = playershopmanager:get_player_shops()
    local msg = packet_def.GCPlayerShopAcquireShopList.new()
    msg.npc_id = targetId
    msg.com_factor = playershopmanager:get_com_factor()
    msg.shop_infos = playershopmanager:get_shop_infos()
    self:get_scene():send2client(human, msg)
end

function script_base:GetGuildPos(selfId)
    local human = self:get_scene():get_obj_by_id(selfId)
    local self_guild_info = skynet.call(".Guildmanager", "lua", "get_my_guild_info_in_guild", human:get_guid(), human:get_guild_id())
    if self_guild_info then
        return self_guild_info.position
    end
    return define.INVAILD_ID
end

function script_base:LuaFnGetHumanGuildLeagueID(selfId)
    local human = self:get_scene():get_obj_by_id(selfId)
    return human:get_confederate_id()
end

function script_base:GetHour()
    local date = os.date("*t")
    return date.hour
end

function script_base:GetMinute()
    local date = os.date("*t")
    return date.min
end

function script_base:GetWeek()
	local weekday = os.date("%w")
	weekday = tonumber(weekday)
	weekday = weekday == 0 and 7 or weekday
	return weekday
end

function script_base:GetObjCreateTime(selfId)
    local obj = self:get_scene():get_obj_by_id(selfId)
    return obj:get_create_time()
end

function script_base:LuaFnSetTeamExpAllotMode()

end

function script_base:CheckAllXinFaLevel_Ex(selfId,level)
    local human = self:get_scene():get_obj_by_id(selfId)
	if not human then
		return -1
	elseif human:get_obj_type() ~= "human" then
		return -2
	end
	local mpid = human:get_menpai()
	if not mpid or mpid < 0 or mpid == 9 or not define.ENUM_MENPAI_CHN[mpid] then
		return -3
	end
	local mp_xinfa = {}
    local xinfa_v1 = configenginer:get_config("xinfa_v1")
    for _, id in ipairs(menpai_registry.xinfa_ids(xinfa_v1, mpid)) do
        local xinfa = xinfa_v1[id]
        if xinfa.menpai == mpid then
            if id ~= define.MENPAI_7_XINFA[mpid] and id ~= define.MENPAI_8_XINFA[mpid] then
                table.insert(mp_xinfa,id)
            end
        end
    end
	for _,xf_id in ipairs(mp_xinfa) do
		local xinfa = human:get_xinfa(xf_id)
		if not xinfa then
			return -4
		elseif xinfa.m_nXinFaLevel < level then
			return -5
		end
	end
	return 1
end
function script_base:LuaFnGetXinFaLevel(selfId, xf_id)
    local human = self:get_scene():get_obj_by_id(selfId)
    local xinfa = human:get_xinfa(xf_id)
    return xinfa.m_nXinFaLevel
end

function script_base:SetNPCAIType(selfId, ai_type)
    local monster = self:get_scene():get_obj_by_id(selfId)
    monster:set_ai_type(ai_type)
end

function script_base:AuditXinSanHuanCreateFuben()

end

function script_base:AuditPMFCreateBoss()

end

function script_base:LuaFnAuditHDXianCaoZhengDuo()

end


function script_base:LuaFnGetShopName(selfId, index)
    local shop_name = ""
    local human = self:get_scene():get_obj_by_id(selfId)
    local shop_guid = human:get_shop_guid_by_index(index)
    if shop_guid then
        local shop = playershopmanager:get_player_shop_by_guid(shop_guid)
        if shop then
            shop_name = shop:get_name()
        end
    end
    return shop_name
end

function script_base:LuaFnOpenPlayerShop(selfId, targetId, index)
    local human = self:get_scene():get_obj_by_id(selfId)
	assert(human,"LuaFnOpenPlayerShop 对象缺失。")
	local save_lv = human:get_game_flag_key("save_lv")
	local agent = human:get_game_flag_key("agent")
	local guid = human:get_guid()
	local game_save_lv,game_agent = skynet.call(".gamed", "lua", "check_save_lv", guid)
	if save_lv ~= game_save_lv then
		local collection = "log_save_lv_change"
		local doc = { 
			fun_name = "LuaFnOpenPlayerShop",
			error_msg = "服务ID异常_请求操作商会",
			guid = guid,
			name = human:get_name(),
			curlv = game_save_lv,
			game_agent = game_agent,
			datalv = save_lv,
			data_agent = agent,
			sceneid = self:GetSceneID(),
			date_time = utils.get_day_time()
		}
		skynet.send(".logdb", "lua", "insert", { collection = collection, doc = doc })
		human:notify_tips("角色数据异常，请重新登陆游戏再进行操作。")
		return
	end
    local shop_guid = human:get_shop_guid_by_index(index)
    if shop_guid then
        local shop = playershopmanager:get_player_shop_by_guid(shop_guid)
        if shop then
            local sign = 1
            local stall_index = 1
            local is_manager = true
            shop:send_item_list(human, stall_index, sign, is_manager)
        end
    end
end

function script_base:ContactArgs(str, ...)
    local count = #{ ... }
    local ostream = iostream.bostream
    local os = ostream.new()
    os:write(str, string.len(str))
    os:write("*", 1)
    os:writeuchar(count)
    local oss = ostream.new()
    local oss_len = 0
    for _, v in ipairs({ ... }) do
        oss:write("*", 1)
        oss_len = oss_len + 1
        v = tostring(v)
        local len = string.len(v)
        local gbk_v = gbk.fromutf8(v)
        local gbk_l = string.len(gbk_v)
        oss:writeuchar(gbk_l)
        oss_len = oss_len + 1
        oss:write(v, len)
        oss_len = oss_len + gbk_l
    end
    local str = oss:get()
    local len = string.len(str)
    os:writeuchar(oss_len + 3)
    os:write(str, len)
    return os:get()
end

function script_base:ContactArgsNotTransfer(str, ...)
    local count = #{ ... }
    local ostream = iostream.bostream
    local os = ostream.new()
    os:write(str, string.len(str))
    os:write("*", 1)
    os:writeuchar(count)
    local oss = ostream.new()
    local oss_len = 0
    for _, v in ipairs({ ... }) do
        oss:write("*", 1)
        oss_len = oss_len + 1
        v = tostring(v)
        local len = string.len(v)
        local gbk_l = string.len(v)
        oss:writeuchar(gbk_l)
        oss_len = oss_len + 1
        oss:write(v, len)
        oss_len = oss_len + gbk_l
    end
    local str = oss:get()
    local len = string.len(str)
    os:writeuchar(oss_len + 3)
    os:write(str, len)
    return os:get()
end

function script_base:GetXiuLianDetail(selfId, mjid, level)
    local menpai = self:GetMenPai(selfId)
    local xiulian_detail = configenginer:get_config("xiulian_detail")
    for _, details in ipairs(xiulian_detail) do
        if details.BOOKLEVEL == level and details.BOOKID == menpai then
            return details[mjid]
        end
    end
end

function script_base:GetXiuLianLevel(selfId, mjId)
    local human = self:get_scene():get_obj_by_id(selfId)
    return human:get_xiulian_level(mjId)
end

function script_base:XiuLianCanLevelUp(selfId, mjId)
    local human = self:get_scene():get_obj_by_id(selfId)
    return human:xiulian_can_level_up(mjId)
end

function script_base:LuaFnCostExp(selfId, cost_exp)
    assert(cost_exp > 0, cost_exp)
    local human = self:get_scene():get_obj_by_id(selfId)
    local exp = human:get_exp()
    exp = exp - cost_exp
    exp = exp < 0 and 0 or exp
    human:set_exp(exp)
end

function script_base:XiuLianLevelUp(selfId, mjId)
    local human = self:get_scene():get_obj_by_id(selfId)
    human:xiulian_level_up(mjId)
end

function script_base:GetGongLi(selfId)
    local human = self:get_scene():get_obj_by_id(selfId)
    return human:get_gong_li()
end

function script_base:LuaFnCostGongLi(selfId, count)
    local human = self:get_scene():get_obj_by_id(selfId)
    human:cost_gong_li(count)
end

function script_base:SetGongLi(selfId, count)
    assert(count > 0, count)
    local human = self:get_scene():get_obj_by_id(selfId)
    human:set_gong_li(count)
end

function script_base:GetExp(selfId)
    local human = self:get_scene():get_obj_by_id(selfId)
    return human:get_exp()
end

function script_base:GetTime2Day()
    local str = os.date("%Y%m%d")
    return tonumber(str)
end

function script_base:GetDiffTime2Day(diff)
    local now = os.time() + diff
    local str = os.date("%Y%m%d", now)
    return tonumber(str)
end

function script_base:GetDiffTime2DayEx(date_value,diff)
    local str = tostring(date_value)
    local year = tonumber(string.sub(str, 1, 4))
    local month = tonumber(string.sub(str, 5, 6))
    local day = tonumber(string.sub(str, 7, 8))
    local now = os.time({
        year = year,
        month = month,
        day = day,
        hour = 0,
        min = 0,
        sec = 0
    })
	now = now + diff
    str = os.date("%Y%m%d", now)
    return tonumber(str)
end

function script_base:GetTime2Day2()
    local str = os.date("%y%m%d%H%M")
    return tonumber(str)
end

function script_base:GetDiffTime2Day2(diff)
    local now = os.time() + diff
    local str = os.date("%y%m%d%H%M", now)
    return tonumber(str)
end

function script_base:GetTime2Week()
    local str = os.date("%Y%W")
    return tonumber(str)
end

function script_base:GetXiuLianLevelUpperLimit(selfId, mjId)
    local human = self:get_scene():get_obj_by_id(selfId)
    return human:get_xiulian_upper_limit(mjId)
end

function script_base:XiuLianLevelUpperLimitUp(selfId, mjId, count)
    local human = self:get_scene():get_obj_by_id(selfId)
    human:xiulian_upper_limit_up(mjId, count)
end

function script_base:MissionCom(selfId, mission_id)
    local human = self:get_scene():get_obj_by_id(selfId)
    human:set_mission_have_done(mission_id, true)
end

function script_base:IsCanNewWorld()
    return true
end

function script_base:GetTalentCostPoint(selfId)
    local human = self:get_scene():get_obj_by_id(selfId)
    local talent = human:get_talent()
    return talent.cost_point
end

function script_base:GetTalentType(selfId)
    local human = self:get_scene():get_obj_by_id(selfId)
    local talent = human:get_talent()
    return talent.type
end

function script_base:SelectTalentType(selfId, talent_type, talent_posstive)
    local human = self:get_scene():get_obj_by_id(selfId)
    human:reset_talent()
    local talent = human:get_talent()
    talent.type = talent_type
    talent.study[1].id = talent_posstive
    talent.study[1].level = 1
    human:talent_on_active()
    human:send_talent(2)
end

function script_base:LuaFnAddTalentUnderstandPoint(selfId, count)
    assert(count > 0, count)
    local human = self:get_scene():get_obj_by_id(selfId)
    local talent = human:get_talent()
    talent.understand_point = talent.understand_point + count
    human:send_talent(1)
end

function script_base:NotifyTalent(selfId)
    local human = self:get_scene():get_obj_by_id(selfId)
    human:send_talent(0)
end

function script_base:MoneyToJiaozi(selfId, count)
    return true -- Vo Thach has no separate bound wallet.
end

function script_base:SetAIScriptID(selfId, ai_script_id)
    local monster = self:get_scene():get_obj_by_id(selfId)
    monster:set_ai_script(ai_script_id)
end

function script_base:NpcToIdle(selfId)
    local monster = self:get_scene():get_obj_by_id(selfId)
    monster:get_ai():change_state("idle")
end

function script_base:QueryAreaStandingTime(areaId, selfId)
    local human = self:get_scene():get_obj_by_id(selfId)
    local area = self:get_scene():get_obj_by_id(areaId)
end

function script_base:LuaFnAddSweepPointByID(selfId, index, count)
    local human = self:get_scene():get_obj_by_id(selfId)
    human:add_sweep_count(index, count)
end

function script_base:GetSweepCount(selfId, index)
    local human = self:get_scene():get_obj_by_id(selfId)
    return human:get_sweep_count(index)
end

function script_base:SetSweepCount(selfId, index, point)
    local human = self:get_scene():get_obj_by_id(selfId)
    human:set_sweep_point(index, point)
end

function script_base:CostSweepPoint(selfId, index, count)
    local human = self:get_scene():get_obj_by_id(selfId)
    return human:cost_sweep_count(index, count)
end

function script_base:SetSecKillData(selfId, data)
    local human = self:get_scene():get_obj_by_id(selfId)
    human:set_sec_kill_data(data)
end

function script_base:DungeonDone(selfId, index)
    local human = self:get_scene():get_obj_by_id(selfId)
    local count = human:get_campaign_count(index)
    human:set_campaign_count(index, count + 1)
end

function script_base:GetCampaignCount(selfId, index)
    local human = self:get_scene():get_obj_by_id(selfId)
    return human:get_campaign_count(index)
end

function script_base:AddPrimaryEnemy(selfId, enmeyId)
    local obj = self:get_scene():get_obj_by_id(selfId)
    obj:get_ai():add_primary_enemy(enmeyId)
end

function script_base:GetCurEnemy(selfId)
    local obj = self:get_scene():get_obj_by_id(selfId)
    return obj:get_ai():get_cur_enemy_id()
end

function script_base:IsInDist(selfId, targetId, dist_limit)
    local obj_me = self:get_scene():get_obj_by_id(selfId)
    local obj_tar = self:get_scene():get_obj_by_id(targetId)
    assert(obj_me, selfId)
    assert(obj_tar, targetId)
    local my_pos = obj_me:get_world_pos()
    local tar_pos = obj_tar:get_world_pos()
    local dist = math.sqrt((my_pos.x - tar_pos.x) * (my_pos.x - tar_pos.x) + (my_pos.y - tar_pos.y) * (my_pos.y - tar_pos.y))
    return dist < dist_limit
end

function script_base:LuaFnSetNpcIntParameter(selfId, Index, val)
    self:MonsterAI_SetIntParamByIndex(selfId, Index, val)
end

function script_base:LuaFnGetNpcIntParameter(selfId, Index)
    return self:MonsterAI_GetIntParamByIndex(selfId, Index)
end

function script_base:LuaFnGmKillObj(selfId, targetId)
    local obj = self:get_scene():get_obj_by_id(selfId)
	assert(obj,"script_base:LuaFnGmKillObj 对象不存在。")
	return obj:gm_kill_obj(targetId)
    -- local damage = obj:get_hp() * 10
    -- local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
	-- local DAMAGE_TYPE = DI_DamagesByValue_T.enum_DAMAGE_TYPE
	-- local DAMAGE_TYPE_RATE = DI_DamagesByValue_T.enum_DAMAGE_TYPE_RATE
	-- local DAMAGE_TYPE_POINT = DI_DamagesByValue_T.enum_DAMAGE_TYPE_POINT
	-- local DAMAGE_TYPE_BACK = DI_DamagesByValue_T.enum_DAMAGE_TYPE_BACK
	
	-- local damages = {hp_damage = damage}
	-- for _,key in ipairs(DAMAGE_TYPE_RATE) do
		-- damages[key] = 100
	-- end
	-- for _,key in ipairs(DAMAGE_TYPE_POINT) do
		-- damages[key] = 0
	-- end
	-- for _,key in ipairs(DAMAGE_TYPE_BACK) do
		-- damages[key] = {}
	-- end
	-- for _,key in pairs(DAMAGE_TYPE) do
		-- damages[key] = 0
	-- end
	-- damages[DAMAGE_TYPE.IDX_DAMAGE_DIRECHT] = damage
    -- obj:on_damages(damages, obj:get_obj_id(), false, define.INVAILD_ID)
end

function script_base:EnableDynamicRegion(id, data_index, x, y, dir)
    local msg = packet_def.GCSetDynamicRegion.new()
    msg.id = id
    msg.data_index = data_index
    msg.world_pos.x = x
    msg.world_pos.y = y
    msg.dir = dir
    msg.enable = 1
    self:get_scene():broadcastall(msg)
end

function script_base:DisableDynamicRegion(id, data_index)
    local msg = packet_def.GCSetDynamicRegion.new()
    msg.id = id
    msg.data_index = data_index
    msg.world_pos.x = 0
    msg.world_pos.y = 0
    msg.dir = 0
    msg.enable = 0
    self:get_scene():broadcastall(msg)
end

function script_base:SetCharacterDir(selfId, dir)
    local character = self:get_scene():get_obj_by_id(selfId)
    character:set_dir(dir)
end

function script_base:DoNpcTalk(selfId, id, content)
    local msg = packet_def.GCNpcTalk.new()
    msg.id = id
    msg.content = content
    self:get_scene():send2client(selfId, msg)
end

function script_base:DelayCallFunction(delay, func_name, ...)
    eventenginer:register_delay_callback_function(delay, self, func_name, ...)
end

function script_base:SkillCharge(selfId, x, z)
    local obj = self:get_scene():get_obj_by_id(selfId)
    if obj then
        local to  = { x = x, y = z}
        obj:skill_charge(to)
    end
end

function script_base:DispatchWeekActive(selfId)
    local human = self:get_scene():get_obj_by_id(selfId)
    human:send_week_active()
end

function script_base:DispatchShengWangInfo(selfId, camp)
    local human = self:get_scene():get_obj_by_id(selfId)
    human:send_shengwang_info(camp)
end

function script_base:OnWanShiGeExchange(selfId, camp, ItemId)
    local human = self:get_scene():get_obj_by_id(selfId)
    human:on_wanshige_shop_buy(ItemId, camp)
end

function script_base:OnJiYuanShopBuy(selfId, ItemId, targetId)
    local human = self:get_scene():get_obj_by_id(selfId)
	if not human then return end
    return human:on_jiyuan_shop_buy(ItemId, targetId)
end

function script_base:LuaFnCheckResetJiYuanShop(selfId)
    local human = self:get_scene():get_obj_by_id(selfId)
    human:check_jiyuan_shop_info()
end

function script_base:GetLingWuClass(item_index)
    local ling_yu_base = configenginer:get_config("ling_yu_base")
    ling_yu_base = ling_yu_base[item_index]
    if ling_yu_base == nil then
        return define.INVAILD_ID
    end
    return ling_yu_base.class
end

function script_base:LingWuWash(selfId, BagPosLingWu, lock_count)
    local human = self:get_scene():get_obj_by_id(selfId)
    local bag_container = human:get_prop_bag_container()
    local item = bag_container:get_item(BagPosLingWu)
    if item == nil then
        return false
    end
    item:get_equip_data():wash_ling_yu_attrs_enhancement_level(lock_count)
    local msg = packet_def.GCItemInfo.new()
    msg.bagIndex = BagPosLingWu
    msg.item = item:copy_raw_data()
    self.scene:send2client(human, msg)
end

function script_base:LingWuSwitch(selfId, BagPosLingWu)
    local human = self:get_scene():get_obj_by_id(selfId)
    local bag_container = human:get_prop_bag_container()
    local item = bag_container:get_item(BagPosLingWu)
    if item == nil then
        return false
    end
    item:get_equip_data():switch_ling_yu_attrs_enhancement_level(lock_count)
    local msg = packet_def.GCItemInfo.new()
    msg.bagIndex = BagPosLingWu
    msg.item = item:copy_raw_data()
    self.scene:send2client(human, msg)
end

function script_base:GetLingWuAttrCount(selfId, BagPosLingWu)
    local human = self:get_scene():get_obj_by_id(selfId)
    local bag_container = human:get_prop_bag_container()
    local item = bag_container:get_item(BagPosLingWu)
    if item == nil then
        return 0
    end
    local ling_yu_attrs = item:get_equip_data():get_ling_yu_attr_types()
    local count = 0
    for _, attr in ipairs(ling_yu_attrs) do
        if attr ~= define.INVAILD_ID then
            count = count + 1
        end
    end
    return count
end

function script_base:LuaFnLingWuTransition(selfId, BagPosFrom, BagPosTo)
    local human = self:get_scene():get_obj_by_id(selfId)
    local bag_container = human:get_prop_bag_container()
    local item_from = bag_container:get_item(BagPosFrom)
    if item_from == nil then
        return false
    end
    local item_to = bag_container:get_item(BagPosTo)
    if item_to == nil then
        return false
    end
    local ling_yu_attrs_enhancement_level = item_from:get_equip_data():get_ling_yu_attrs_enhancement_level()
    item_from:get_equip_data():set_ling_yu_attrs_enhancement_level({0, 0, 0})
    item_to:get_equip_data():set_ling_yu_attrs_enhancement_level(ling_yu_attrs_enhancement_level)
    local msg = packet_def.GCItemInfo.new()
    msg.bagIndex = BagPosFrom
    msg.item = item_from:copy_raw_data()
    self.scene:send2client(human, msg)
    msg = packet_def.GCItemInfo.new()
    msg.bagIndex = BagPosTo
    msg.item = item_to:copy_raw_data()
    self.scene:send2client(human, msg)
end

function script_base:LuaFnItemUnbind(selfId, BagPos)
    local human = self:get_scene():get_obj_by_id(selfId)
    local bag_container = human:get_prop_bag_container()
    local item = bag_container:get_item(BagPos)
    if item == nil then
        return false
    end
    item:set_is_bind(false)
    local msg = packet_def.GCItemInfo.new()
    msg.bagIndex = BagPos
    msg.item = item:copy_raw_data()
    self.scene:send2client(human, msg)
end

function script_base:DispatchXBWRankCharts(selfId, index)
    local human = self:get_scene():get_obj_by_id(selfId)
    local guid = human:get_guid()
    local msg = packet_def.WGCRetQueryXBWRankCharts.new()
    local top_list = require "jianzong_ranklist"[index]
    msg.status = 2
    msg.type = index
    msg.guid = guid
    msg.rank_count = 200
    msg.top_list = top_list
    self:get_scene():send2client(human, msg)
end

function script_base:LuaFnAuditShengShouOpenBigBox()

end

function script_base:LuaFnIsUnbreakable(selfId)
    local human = self:get_scene():get_obj_by_id(selfId)
    return human:is_unbreakable()
end

function script_base:LuaFnIsConceal(selfId)
    local human = self:get_scene():get_obj_by_id(selfId)
    return human:get_stealth_level() > 0
end

function script_base:DropBoxEnterScene(PosX, PosY)
    local conf = {}
    conf.world_pos = { x = PosX, y = PosY}
    conf.monster_id = define.INVAILD_ID
    conf.owner_guid = define.INVAILD_ID
    conf.drop_items = {}
    local item_box_id = self:get_scene():create_item_box(conf)
    return item_box_id
end

function script_base:ItemBoxEnterScene(PosX, PosY, box_type, quality, count, item_index, way)
    print("ItemBoxEnterScene box_type =", box_type)
    assert(PosX ~= nil)
    assert(PosY ~= nil)
    local conf = {}
    conf.world_pos = { x = PosX, y = PosY}
    conf.monster_id = define.INVAILD_ID
    conf.owner_guid = define.INVAILD_ID
    conf.item_box_type = box_type
    conf.drop_items = {}
    if item_index and count then
        table.insert(conf.drop_items, {id = item_index, count = count, way = way})
    end
    local item_box_id = self:get_scene():create_item_box(conf)
    return item_box_id
end

function script_base:AddItemToBox(item_box_id, quality, item_count, item_index, way)
    local item_box = self:get_scene():get_obj_by_id(item_box_id)
    item_box:add_item(item_index, item_count, quality, way)
end

function script_base:GetItemSnByDropRateOfItemTable()
    local drop_rate_of_item_table = configenginer:get_config("drop_rate_of_item_table")
    local sum = 0
    for _, conf in ipairs(drop_rate_of_item_table) do
        sum = sum + conf["掉落概率"]
    end
    local num = math.random(1, sum)
    local cur = 0
    for _, conf in ipairs(drop_rate_of_item_table) do
        cur = cur + conf["掉落概率"]
        if cur >= num then
            return conf["物品ID"], conf["名称$1$"], conf["是否发送消息"]
        end
    end
end

function script_base:LuaFnChallengeRefreshSkillCoolDown(selfId)
    local human = self:get_scene():get_obj_by_id(selfId)
    human:challenge_refresh_skill_cool_down()
end

function script_base:LuaFnChallengeRestoreSkillCoolDown(selfId)
    local human = self:get_scene():get_obj_by_id(selfId)
    human:challenge_restore_skill_cool_down()
end

function script_base:SetKillMonsterCount(selfId, count)
    local human = self:get_scene():get_obj_by_id(selfId)
    human:set_today_kill_monster_count(count)
end

function script_base:GetPKValue(selfId)
    local human = self:get_scene():get_obj_by_id(selfId)
    return human:get_pk_value()
end

function script_base:SetPKValue(selfId, value)
    local human = self:get_scene():get_obj_by_id(selfId)
    return human:set_pk_value(value)
end

function script_base:SendPacketStream(selfId, id, stream)
    local human = self:get_scene():get_obj_by_id(selfId)
    local msg = packet_def.GCPacketStream.new()
    msg.id = id
    msg.args = stream
    self:get_scene():send2client(human, msg)
end

function script_base:LuaFnSetLifeTimeAttrRefix_MaxHP(selfId, max_hp)
    local monster = self:get_scene():get_obj_by_id(selfId)
    monster:set_hp_max(max_hp)
end

function script_base:LuaFnSetLifeTimeAttrRefix_CriticalAttack(selfId, mind_attack)
    local monster = self:get_scene():get_obj_by_id(selfId)
    monster:set_mind_attack(mind_attack)
end

function script_base:LuaFnSetLifeTimeAttrRefix_Hit(selfId, attrib_hit)
    local monster = self:get_scene():get_obj_by_id(selfId)
    monster:set_attrib_hit(attrib_hit)
end

function script_base:LuaFnSetLifeTimeAttrRefix_Miss(selfId, attrib_miss)
    local monster = self:get_scene():get_obj_by_id(selfId)
    monster:set_attrib_miss(attrib_miss)
end

function script_base:LuaFnSetLifeTimeAttrRefix_AttackPhysics(selfId, attrib_att_physics)
    local monster = self:get_scene():get_obj_by_id(selfId)
    monster:set_attrib_att_physics(attrib_att_physics)
end

function script_base:LuaFnSetLifeTimeAttrRefix_DefencePhysics(selfId, attrib_def_physics)
    local monster = self:get_scene():get_obj_by_id(selfId)
    monster:set_attrib_def_physics(attrib_def_physics)
end

function script_base:LuaFnSetLifeTimeAttrRefix_AttackMagic(selfId, attrib_att_magic)
    local monster = self:get_scene():get_obj_by_id(selfId)
    monster:set_attrib_att_magic(attrib_att_magic)
end

function script_base:LuaFnSetLifeTimeAttrRefix_DefenceMagic(selfId, attrib_def_magic)
    local monster = self:get_scene():get_obj_by_id(selfId)
    monster:set_attrib_def_magic(attrib_def_magic)
end

function script_base:LuaFnSetLifeTimeAttrRefix_AttackCold(selfId, att_cold)
    local monster = self:get_scene():get_obj_by_id(selfId)
    monster:set_att_cold(att_cold)
end

function script_base:LuaFnSetLifeTimeAttrRefix_ResistCold(selfId, def_cold)
    local monster = self:get_scene():get_obj_by_id(selfId)
    monster:set_def_cold(def_cold)
end

function script_base:LuaFnSetLifeTimeAttrRefix_AttackFire(selfId, att_fire)
    local monster = self:get_scene():get_obj_by_id(selfId)
    monster:set_att_fire(att_fire)
end

function script_base:LuaFnSetLifeTimeAttrRefix_ResistCold(selfId, def_fire)
    local monster = self:get_scene():get_obj_by_id(selfId)
    monster:set_def_fire(def_fire)
end

function script_base:LuaFnSetLifeTimeAttrRefix_AttackLight(selfId, att_light)
    local monster = self:get_scene():get_obj_by_id(selfId)
    monster:set_att_light(att_light)
end

function script_base:LuaFnSetLifeTimeAttrRefix_ResistLight(selfId, def_light)
    local monster = self:get_scene():get_obj_by_id(selfId)
    monster:set_def_light(def_light)
end

function script_base:LuaFnSetLifeTimeAttrRefix_AttackPoison(selfId, att_poison)
    local monster = self:get_scene():get_obj_by_id(selfId)
    monster:set_att_poison(att_poison)
end

function script_base:LuaFnSetLifeTimeAttrRefix_ResistPoison(selfId, def_poison)
    local monster = self:get_scene():get_obj_by_id(selfId)
    monster:set_def_poison(def_poison)
end

function script_base:LuaFnGetMaxBaseHp(selfId)
    local monster = self:get_scene():get_obj_by_id(selfId)
    local data_index = monster:get_model()
    local monster_attr_ex = configenginer:get_config("monster_attr_ex")
    monster_attr_ex = monster_attr_ex[data_index]
    return monster_attr_ex.hp_max
end

function script_base:LuaFnGetBaseCriticalAttack(selfId)
    local monster = self:get_scene():get_obj_by_id(selfId)
    local data_index = monster:get_model()
    local monster_attr_ex = configenginer:get_config("monster_attr_ex")
    monster_attr_ex = monster_attr_ex[data_index]
    return monster_attr_ex.mind_attack
end

function script_base:LuaFnGetBaseHit(selfId)
    local monster = self:get_scene():get_obj_by_id(selfId)
    local data_index = monster:get_model()
    local monster_attr_ex = configenginer:get_config("monster_attr_ex")
    monster_attr_ex = monster_attr_ex[data_index]
    return monster_attr_ex.attrib_hit
end

function script_base:LuaFnGetBaseMiss(selfId)
    local monster = self:get_scene():get_obj_by_id(selfId)
    local data_index = monster:get_model()
    local monster_attr_ex = configenginer:get_config("monster_attr_ex")
    monster_attr_ex = monster_attr_ex[data_index]
    return monster_attr_ex.attrib_miss
end

function script_base:LuaFnGetBaseAttackPhysics(selfId)
    local monster = self:get_scene():get_obj_by_id(selfId)
    local data_index = monster:get_model()
    local monster_attr_ex = configenginer:get_config("monster_attr_ex")
    monster_attr_ex = monster_attr_ex[data_index]
    return monster_attr_ex.attrib_att_physics
end

function script_base:LuaFnGetBaseDefencePhysics(selfId)
    local monster = self:get_scene():get_obj_by_id(selfId)
    local data_index = monster:get_model()
    local monster_attr_ex = configenginer:get_config("monster_attr_ex")
    monster_attr_ex = monster_attr_ex[data_index]
    return monster_attr_ex.attrib_def_physics
end

function script_base:LuaFnGetBaseAttackMagic(selfId)
    local monster = self:get_scene():get_obj_by_id(selfId)
    local data_index = monster:get_model()
    local monster_attr_ex = configenginer:get_config("monster_attr_ex")
    monster_attr_ex = monster_attr_ex[data_index]
    return monster_attr_ex.attrib_att_magic
end

function script_base:LuaFnGetBaseDefenceMagic(selfId)
    local monster = self:get_scene():get_obj_by_id(selfId)
    local data_index = monster:get_model()
    local monster_attr_ex = configenginer:get_config("monster_attr_ex")
    monster_attr_ex = monster_attr_ex[data_index]
    return monster_attr_ex.attrib_def_magic
end

function script_base:LuaFnGetBaseAttackCold(selfId)
    local monster = self:get_scene():get_obj_by_id(selfId)
    local data_index = monster:get_model()
    local monster_attr_ex = configenginer:get_config("monster_attr_ex")
    monster_attr_ex = monster_attr_ex[data_index]
    return monster_attr_ex.att_cold
end

function script_base:LuaFnGetBaseResistCold(selfId)
    local monster = self:get_scene():get_obj_by_id(selfId)
    local data_index = monster:get_model()
    local monster_attr_ex = configenginer:get_config("monster_attr_ex")
    monster_attr_ex = monster_attr_ex[data_index]
    return monster_attr_ex.def_cold
end

function script_base:LuaFnGetBaseAttackFire(selfId)
    local monster = self:get_scene():get_obj_by_id(selfId)
    local data_index = monster:get_model()
    local monster_attr_ex = configenginer:get_config("monster_attr_ex")
    monster_attr_ex = monster_attr_ex[data_index]
    return monster_attr_ex.att_fire
end

function script_base:LuaFnGetBaseResistFire(selfId)
    local monster = self:get_scene():get_obj_by_id(selfId)
    local data_index = monster:get_model()
    local monster_attr_ex = configenginer:get_config("monster_attr_ex")
    monster_attr_ex = monster_attr_ex[data_index]
    return monster_attr_ex.def_fire
end

function script_base:LuaFnGetBaseAttackLight(selfId)
    local monster = self:get_scene():get_obj_by_id(selfId)
    local data_index = monster:get_model()
    local monster_attr_ex = configenginer:get_config("monster_attr_ex")
    monster_attr_ex = monster_attr_ex[data_index]
    return monster_attr_ex.att_light
end

function script_base:LuaFnGetBaseResistLight(selfId)
    local monster = self:get_scene():get_obj_by_id(selfId)
    local data_index = monster:get_model()
    local monster_attr_ex = configenginer:get_config("monster_attr_ex")
    monster_attr_ex = monster_attr_ex[data_index]
    return monster_attr_ex.def_light
end

function script_base:LuaFnGetBaseAttackPosion(selfId)
    local monster = self:get_scene():get_obj_by_id(selfId)
    local data_index = monster:get_model()
    local monster_attr_ex = configenginer:get_config("monster_attr_ex")
    monster_attr_ex = monster_attr_ex[data_index]
    return monster_attr_ex.att_poison
end

function script_base:LuaFnGetBaseResistPosion(selfId)
    local monster = self:get_scene():get_obj_by_id(selfId)
    local data_index = monster:get_model()
    local monster_attr_ex = configenginer:get_config("monster_attr_ex")
    monster_attr_ex = monster_attr_ex[data_index]
    return monster_attr_ex.def_poison
end

function script_base:GetPetNumOfReproductions(selfId, petGUID_H, petGUID_L)
    local obj = self.scene:get_obj_by_id(selfId)
    local container = obj:get_pet_bag_container()
    local guid = pet_guid_cls.new()
    guid:set(petGUID_H, petGUID_L)
    local pet_detail = container:get_pet_by_guid(guid)
    return pet_detail:get_remain_procreate_count()
end

function script_base:SetPetNumOfReproductions(selfId, petGUID_H, petGUID_L, num)
    local obj = self.scene:get_obj_by_id(selfId)
    local container = obj:get_pet_bag_container()
    local guid = pet_guid_cls.new()
    guid:set(petGUID_H, petGUID_L)
    local pet_detail = container:get_pet_by_guid(guid)
    return pet_detail:set_remain_procreate_count(num)
end

function script_base:GetHumanEnergy(selfId)
    local obj = self.scene:get_obj_by_id(selfId)
    return obj:get_stamina()
end

function script_base:SetHumanEnergy(selfId, curEnergy)
    local human = self.scene:get_obj_by_id(selfId)
    assert(type(curEnergy) == "number", curEnergy)
    human:set_stamina(curEnergy)
end

function script_base:GetHumanVigor(selfId)
    local obj = self.scene:get_obj_by_id(selfId)
    return obj:get_vigor()
end

function script_base:GetMissionFlag()
    return 0
end

function script_base:AuditChangeGem()

end

function script_base:LuaFnAuditCaoYun()

end

function script_base:LuaFnDispatchAllTitle(selfId)
    local human = self:get_scene():get_obj_by_id(selfId)
    human:update_titles_to_client()
end

function script_base:DispatchAllTitle(selfId)
    return self:LuaFnDispatchAllTitle(selfId)
end

function script_base:LuaFnAddNewAgname(selfId,id,isupdate)
    local human = self:get_scene():get_obj_by_id(selfId)
	if not human then return end
	if id >= 0 then
		human:add_id_title(id)
	end
	if not isupdate then
		human:update_titles_to_client()
	end
end

function script_base:LuaFnDelNewAgname(selfId,id,isupdate)
    local human = self:get_scene():get_obj_by_id(selfId)
	if not human then return end
	if id >= 0 then
		human:del_conflict_titles(id)
		local curtitle = human:get_cur_title()
		if curtitle and curtitle.new_title_id == id then
			human:set_current_title( { id = 0, str = ""})
		end
	end
	if not isupdate then
		human:update_titles_to_client()
	end
end

function script_base:LuaFnHaveAgname(selfId, id)
    local human = self:get_scene():get_obj_by_id(selfId)
    return human:have_id_title(id)
end

function script_base:LuaFnGetHumanShimenRandom(selfId)
    return math.random(16) - 1
end

function script_base:LuaFnAuditShiMenRenWu()

end

function script_base:LuaFnAuditShiMenRenWu_Day()

end

function script_base:GetMoneyBonusByLevel(level)
    local shimen_level_money_bonus_table = configenginer:get_config("shimen_level_money_bonus_table")
    shimen_level_money_bonus = shimen_level_money_bonus_table[level]
    return shimen_level_money_bonus["金钱获得"]
end

function script_base:GetExpBonusByLevel(level)
    local shimen_level_money_bonus_table = configenginer:get_config("shimen_level_money_bonus_table")
    shimen_level_money_bonus = shimen_level_money_bonus_table[level]
    return shimen_level_money_bonus["经验获得"]
end

function script_base:LuaFnAwardTitle(selfId, title_index, title_id)
    local human = self:get_scene():get_obj_by_id(selfId)
    local char_title = configenginer:get_config("char_title")
    for _, title in pairs(char_title) do
        if title["逻辑类型(程序用)"] == title_index and title_id == title["ID"] then
            local title_str = title["名称$1$"]
            human:set_title(title_index, title_str)
            human:update_titles_to_client()
        end
    end
end

function script_base:LuaFnAwardSpouseTitle(selfId, titlestr)
    local human = self:get_scene():get_obj_by_id(selfId)
    local title_index = define.TITILE.SPOUSE
    human:set_title(title_index, titlestr)
end

function script_base:AwardJieBaiTitle(selfId, titlestr)
    local human = self:get_scene():get_obj_by_id(selfId)
    local title_index = define.TITILE.JIEBAI
    human:set_title(title_index, titlestr)
end

function script_base:AwardShiTuTitle(selfId, titlestr)
    local human = self:get_scene():get_obj_by_id(selfId)
    local title_index = define.TITILE.SHITU
    human:set_title(title_index, titlestr)
end

function script_base:AwardMasterTitle(selfId, titlestr)
    local human = self:get_scene():get_obj_by_id(selfId)
    local title_index = define.TITILE.MASTER
    human:set_title(title_index, titlestr)
end

function script_base:SetCurTitle(selfId, title_index)
    local human = self:get_scene():get_obj_by_id(selfId)
    local title = human:get_title_by_id(title_index)
    human:set_current_title(title)
end

function script_base:LuaFnSetPrivateInfo()

end

function script_base:LuaFnAuditLuckyTurnTable()

end

function script_base:GetPetNumExtra(selfId)
    local human = self:get_scene():get_obj_by_id(selfId)
    return human:get_pet_num_extra()
end

function script_base:SetPetNumExtra(selfId, num)
    local human = self:get_scene():get_obj_by_id(selfId)
    human:set_pet_num_extra(num)
    return true
end

function script_base:GetPetNumMax(selfId)
    local human = self:get_scene():get_obj_by_id(selfId)
    return human:get_pet_bag_size()
end

function script_base:GetRandomQuestionsIndex(question_type)
    local questions = configenginer:get_config("questions")
    local type_questions = {}
    for _, question in ipairs(questions) do
        if question.sztype == question_type then
            table.insert(type_questions, question)
        end
    end
    local num = math.random(#type_questions)
    local question = type_questions[num]
    return question.id
end

function script_base:GetQuestionsRecord(id)
    local questions = configenginer:get_config("questions")
    local question = questions[index]
    for _, question in ipairs(questions) do
        if question.id == id then
            return question.con, question.opt0, question.opt1, question.opt2, 
            question.opt3, question.opt4, question.opt5, question.key0, question.key1, 
            question.key2, question.key3, question.key4, question.key5, question.sztype
        end
    end
end

function script_base:LuaFnSendSystemMail(dest, content)
    local mail = {}
    mail.guid = define.INVAILD_ID
    mail.source = ""
    mail.portrait_id = define.INVAILD_ID
    mail.dest = dest
    mail.content = content
    mail.flag = define.MAIL_TYPE.MAIL_TYPE_SYSTEM
    mail.create_time = os.time()
    skynet.send(".world", "lua", "send_mail", mail)
end

function script_base:LuaFnSendMailToGUID(guid, msg)
    local mail = {}
    mail.guid = define.INVAILD_ID
    mail.source = ""
    mail.portrait_id = define.INVAILD_ID
    mail.dest_guid = guid
    mail.content = msg
    mail.flag = define.MAIL_TYPE.MAIL_TYPE_SYSTEM
    mail.create_time = os.time()
    skynet.send(".world", "lua", "send_mail_to_guid", mail)
end

function script_base:LuaFnSendMailToAllFriend(selfId, msg, _, expect_guid)
    local human = self:get_scene():get_obj_by_id(selfId)
    local relation_info = human:get_relation_info()
    local friends = relation_info.friends or {}
    local mail = {}
    mail.guid = human:get_guid()
    mail.source = human:get_name()
    mail.portrait_id = human:get_portrait_id()
    mail.content = msg
    mail.flag = define.MAIL_TYPE.MAIL_TYPE_NORMAL
    mail.create_time = os.time()
    for _, friend in ipairs(friends) do
        if friend.guid ~= expect_guid then
            mail.dest_guid = friend.guid
            skynet.send(".world", "lua", "send_mail_to_guid", mail)
        end
    end
end

function script_base:LuaFnChuShiMail()

end

function script_base:GetGameTime()
    return os.time()
end

function script_base:GetHonour(selfId)
    local human = self:get_scene():get_obj_by_id(selfId)
    return human:get_honour()
end

function script_base:ScriptGlobal_AuditGeneralLog()
    
end

function script_base:LuaFnGetWorldGlobalData()

end

function script_base:GetTodayWeek()
    local now = os.time()
    return tonumber(os.date("%w", now))
end

function script_base:GetCurTitle(selfId)
    local human = self:get_scene():get_obj_by_id(selfId)
    local title = human:get_cur_title()
    if title then
        return title.id
    else
        return define.INVAILD_ID
    end
end

function script_base:GetGuildWarApply(guild_id)
    return skynet.call(".Guildmanager", "lua", "get_guild_war_apply", guild_id)
end

function script_base:SetGuildWarApplySceneID(guild_id, sceneid)
    skynet.send(".Guildmanager", "lua", "set_guild_war_apply_scene_id", guild_id, sceneid)
end

function script_base:GetGuildIntNum(guild_id, index)
    return skynet.call(".Guildmanager", "lua", "get_guild_int_num", guild_id, index)
end

function script_base:SetGuildIntNum(guild_id, index, num)
    skynet.send(".Guildmanager", "lua", "set_guild_int_num", guild_id, index, num)
end

-- function script_base:LuaFnGetGuildName(selfId)
    -- local human = self:get_scene():get_obj_by_id(selfId)
    -- return human:get_guild_name()
-- end

function script_base:SetHumanGuildInt(selfId, Index, Val)
    local human = self:get_scene():get_obj_by_id(selfId)
    human:set_guild_int_param_by_index(Index, Val)
end

function script_base:GetHumanGuildInt(selfId, Index)
    local human = self:get_scene():get_obj_by_id(selfId)
    human:get_guild_int_param_by_index(Index)
end

function script_base:GetGuildWarPoint(index)
    local guild_war_point = configenginer:get_config("guild_war_point")
    local war_point = guild_war_point[index]
    if war_point then
        return war_point["积分"]
    end
    return 0
end

function script_base:LuaFnDispelAllHostileImpacts(selfId)
    local human = self:get_scene():get_obj_by_id(selfId)
	if not human then return end
    local impact_list = human:get_impact_list()
    for i = #impact_list, 1, -1 do
        local imp = impact_list[i]
        if imp:get_stand_flag() == define.ENUM_BEHAVIOR_TYPE.BEHAVIOR_TYPE_HOSTILITY then
            if imp:is_can_be_dispeled() then
                self:on_impact_fade_out(imp)
                self:remove_impact(imp)
            end
        end
    end
end

function script_base:NotifyGuildBattle()

end

function script_base:LuaFnSetHumanMarryInfo(selfId, marryTargetGUID, isAccept)
    local human = self:get_scene():get_obj_by_id(selfId)
    human:set_marry_info(marryTargetGUID, isAccept)
end

function script_base:LuaFnGetHumanMarryInfo(selfId)
    local human = self:get_scene():get_obj_by_id(selfId)
    local marry_info = human:get_marry_info()
    if marry_info then
        return (marry_info.is_accept or 0), (marry_info.target_guid or define.INVAILD_ID)
    else
        return 0, define.INVAILD_ID
    end
end

function script_base:LuaFnIsSweared(selfId)
    local human = self:get_scene():get_obj_by_id(selfId)
    local relation_info = human:get_relation_info()
    return #(relation_info.brother_guid or {})
end

function script_base:LuaFnIsBrother(selfId, otherId)
    local human = self:get_scene():get_obj_by_id(selfId)
    local other = self:get_scene():get_obj_by_id(otherId)
    local relation_info = human:get_relation_info()
    local brother_guid = relation_info.brother_guid or {}
    for _, guid in ipairs(brother_guid) do
        if other:get_guid() == guid then
            return true
        end
    end
    return false
end

function script_base:LuaFnGetBrotherGuid(selfId, i)
    local human = self:get_scene():get_obj_by_id(selfId)
    local relation_info = human:get_relation_info()
    local brother_guid = relation_info.brother_guid or {}
    return (brother_guid[i])
end

function script_base:LuaFnGetFriendPointByGUID(selfId, guid)
    local human = self:get_scene():get_obj_by_id(selfId)
    local relation_info = human:get_relation_info()
    for _, friend in ipairs(relation_info.friends) do
        if friend.guid == guid then
            return friend.friend_point
        end
    end
    return 0
end

function script_base:LuaFnSetFriendPointByGUID(selfId, guid, friend_point)
    local human = self:get_scene():get_obj_by_id(selfId)
    local relation_info = human:get_relation_info()
    for _, friend in ipairs(relation_info.friends) do
        if friend.guid == guid then
            friend.friend_point = friend_point
            break
        end
    end
    human:set_relation_info(relation_info)
end

function script_base:LuaFnUnswear(selfId, guid)
    local human = self:get_scene():get_obj_by_id(selfId)
    local relation_info = human:get_relation_info()
    local brother_guid = relation_info.brother_guid or {}
    for i = #brother_guid, 1, -1 do
        if brother_guid[i] == guid then
            table.remove(brother_guid, i)
            break
        end
    end
    local friends = relation_info.friends or {}
    relation_info.friends = friends
    self:ModifyRelationType(friends, guid, define.RELATION_TYPE.RELATION_TYPE_FRIEND)
    human:set_relation_info(relation_info)
end

function script_base:LuaFnGetFriendName(selfId, guid)
    local human = self:get_scene():get_obj_by_id(selfId)
    local relation_info = human:get_relation_info()
    for _, friend in ipairs(relation_info.friends) do
        if friend.guid == guid then
            return friend.name
        end
    end
    return ""
end

function script_base:LuaFnDrawJieBaiName(selfId, TeamSize)
    local msg = packet_def.GCByname.new()
    msg.type = 0x11
    msg.num = TeamSize
    self:get_scene():send2client(selfId, msg)
end

function script_base:LuaFnChangeJieBaiName(selfId)
    local human = self:get_scene():get_obj_by_id(selfId)
    local msg = packet_def.GCByname.new()
    msg.type = 0x13
    msg.data = human:get_jiebai_name()
    self:get_scene():send2client(selfId, msg)
end

function script_base:LuaFnGetJieBaiName(selfId)
    local human = self:get_scene():get_obj_by_id(selfId)
    return human:get_jiebai_name()
end

function script_base:LuaFnIsSpouses(selfId, otherId)
    local human = self:get_scene():get_obj_by_id(selfId)
    local other = self:get_scene():get_obj_by_id(otherId)
    local relation_info = human:get_relation_info()
    local spouses = relation_info.spouses or define.INVAILD_ID
    return spouses == other:get_guid()
end

function script_base:LuaFnIsMarried(selfId)
    local human = self:get_scene():get_obj_by_id(selfId)
    local relation_info = human:get_relation_info()
    local spouses = relation_info.spouses or define.INVAILD_ID
    return spouses ~= define.INVAILD_ID
end

function script_base:LuaFnMarry(selfId, targetId, marryLevel)
    local human = self:get_scene():get_obj_by_id(selfId)
    local my_relation = human:get_relation_info()
    local other = self:get_scene():get_obj_by_id(targetId)
    local other_relation = other:get_relation_info()
    my_relation.spouses = other:get_guid()
    my_relation.marry_level = marryLevel
    other_relation.spouses = human:get_guid()
    other_relation.marry_level = marryLevel
    local my_friends = my_relation.friends or {}
    my_relation.friends = my_friends
    local other_friends = other_relation.friends or {}
    other_relation.friends = other_friends
    self:ModifyRelationType(my_friends, other:get_guid(), define.RELATION_TYPE.RELATION_TYPE_MARRY)
    self:ModifyRelationType(other_friends, human:get_guid(), define.RELATION_TYPE.RELATION_TYPE_MARRY)
    human:set_relation_info(my_relation)
    other:set_relation_info(other_relation)
end

function script_base:LuaFnUnMarry(selfId, targetId)
    local human = self:get_scene():get_obj_by_id(selfId)
    local my_relation = human:get_relation_info()
    local other = self:get_scene():get_obj_by_id(targetId)
    local other_relation = other:get_relation_info()
    my_relation.spouses = define.INVAILD_ID
    other_relation.spouses = define.INVAILD_ID
    local my_friends = my_relation.friends or {}
    my_relation.friends = my_friends
    local other_friends = other_relation.friends or {}
    other_relation.friends = other_friends
    self:ModifyRelationType(my_friends, other:get_guid(), define.RELATION_TYPE.RELATION_TYPE_FRIEND)
    self:ModifyRelationType(other_friends, human:get_guid(), define.RELATION_TYPE.RELATION_TYPE_FRIEND)
    human:set_relation_info(my_relation)
    other:set_relation_info(other_relation)
end

function script_base:LuaFnDivorce(selfId)
    local human = self:get_scene():get_obj_by_id(selfId)
    local relation_info = human:get_relation_info()
    local spouses = relation_info.spouses or define.INVAILD_ID
    local my_friends = relation_info.friends or {}
    relation_info.friends = my_friends
    self:ModifyRelationType(my_friends, spouses, define.RELATION_TYPE.RELATION_TYPE_FRIEND)
    relation_info.spouses = define.INVAILD_ID
    human:set_relation_info(relation_info)
end

function script_base:LuaFnGetSpouseGUID(selfId)
    local human = self:get_scene():get_obj_by_id(selfId)
    local relation_info = human:get_relation_info()
    local spouses = relation_info.spouses or define.INVAILD_ID
    return spouses 
end

function script_base:LuaFnIsMaster(selfId, otherId)
    local human = self:get_scene():get_obj_by_id(selfId)
    local other = self:get_scene():get_obj_by_id(otherId)
    local relation_info = human:get_relation_info()
    local master = relation_info.master or define.INVAILD_ID
    return master == other:get_guid()
end

function script_base:LuaFnIsPrentice(selfId, otherId)
    local human = self:get_scene():get_obj_by_id(selfId)
    local other = self:get_scene():get_obj_by_id(otherId)
    local relation_info = human:get_relation_info()
    local prentice_guid = relation_info.prentice_guid or {}
    for _, guid in ipairs(prentice_guid) do
        if guid == other:get_guid() then
            return true
        end
    end
    return false
end

function script_base:LuaFnIsFriend(selfId, otherId)
    local human = self:get_scene():get_obj_by_id(selfId)
    local other = self:get_scene():get_obj_by_id(otherId)
    local relation_info = human:get_relation_info()
    local friends = relation_info.friends or {}
    for _, friend in ipairs(friends) do
        if friend.guid == other:get_guid() then
            return true
        end
    end
    return false
end

function script_base:LuaFnGetFriendPoint(selfId, otherId)
    local human = self:get_scene():get_obj_by_id(selfId)
    local other = self:get_scene():get_obj_by_id(otherId)
    local relation_info = human:get_relation_info()
    local friends = relation_info.friends or {}
    for _, friend in ipairs(friends) do
        if friend.guid == other:get_guid() then
            return friend.friend_point
        end
    end
    return 0
end

function script_base:LuaFnTeamSnapshort()

end

function script_base:LuaFnAgreeSwear(selfId, otherId)
    local human = self:get_scene():get_obj_by_id(selfId)
    human:set_agree_swear_list(otherId)
end

function script_base:LuaFnIfAllTeamAgreeSwear(selfId)
    local human = self:get_scene():get_obj_by_id(selfId)
    local agree_swear_list = human:get_agree_swear_list()
    local TeamSizeSameScene = self:LuaFnGetTeamSceneMemberCount(selfId)
    local all_agree = true
    for i = 1, TeamSizeSameScene do
        local theID = self:LuaFnGetTeamSceneMember(selfId, i)
        local mem = self:get_scene():get_obj_by_id(theID)
        if mem == nil or agree_swear_list[theID] == nil then
            all_agree = false
        end
    end
    return all_agree
end

function script_base:LuaFnVerifyTeamWithSnapshort()

end

function script_base:ModifyRelationType(friends, guid, relation_type)
    for _, friend in ipairs(friends) do
        if friend.guid == guid then
            friend.relation_type = relation_type
            break    
        end
    end
end

function script_base:LuaFnAllTeamSwear(selfId)
    local human = self:get_scene():get_obj_by_id(selfId)
    local relation_info = human:get_relation_info()
    local friends = relation_info.friends or {}
    relation_info.friends = friends
    local brother_guid = relation_info.brother_guid or {}
    relation_info.brother_guid = brother_guid
    local TeamSizeSameScene = self:LuaFnGetTeamSceneMemberCount(selfId)
    for i = 1, TeamSizeSameScene do
        local theID = self:LuaFnGetTeamSceneMember(selfId, i)
        local mem = self:get_scene():get_obj_by_id(theID)
        if mem then
            table.insert(brother_guid, mem:get_guid())
            self:ModifyRelationType(friends, mem:get_guid(), define.RELATION_TYPE.RELATION_TYPE_BROTHER)
        end
    end
    human:set_relation_info(relation_info)
end

function script_base:LuaFnHaveMaster(selfId)
    local human = self:get_scene():get_obj_by_id(selfId)
    local relation_info = human:get_relation_info()
    local master = relation_info.master or define.INVAILD_ID
    return master ~= define.INVAILD_ID
end

function script_base:LuaFnGetMasterGUID(selfId)
    local human = self:get_scene():get_obj_by_id(selfId)
    local relation_info = human:get_relation_info()
    local master = relation_info.master or define.INVAILD_ID
    return master
end

function script_base:LuaFnBetrayMaster(selfId)
    local human = self:get_scene():get_obj_by_id(selfId)
    local relation_info = human:get_relation_info()
    local friends = relation_info.friends or {}
    relation_info.friends = friends
    local master = relation_info.master or define.INVAILD_ID
    self:ModifyRelationType(friends, master, define.RELATION_TYPE.RELATION_TYPE_FRIEND)
    relation_info.master = define.INVAILD_ID
    human:set_relation_info(relation_info)
end

function script_base:LuaFnGetmasterLevel(selfId)
    local human = self:get_scene():get_obj_by_id(selfId)
    return human:get_master_level()
end

function script_base:LuaFnSetmasterLevel(selfId, masterLevel)
    local human = self:get_scene():get_obj_by_id(selfId)
    human:set_master_level(masterLevel)
end

function script_base:LuaGetPrenticeSupplyExp(selfId)
    local human = self:get_scene():get_obj_by_id(selfId)
    return human:get_prentice_supply_exp()
end

function script_base:LuaFnIsPasswordSetup()
    return false
end

function script_base:LuaFnIsPasswordUnlocked()
    return true
end

function script_base:LuaFnSetItemCreator(selfId, BagPos, Name)
    local human = self:get_scene():get_obj_by_id(selfId)
    local bag_container = human:get_prop_bag_container()
    local item = bag_container:get_item(BagPos)
    if item == nil then
        return false
    end
    item:set_item_creator(Name)
end

function script_base:LuaFnGetItemCreator(selfId, BagPos)
    local human = self:get_scene():get_obj_by_id(selfId)
    local item = human:get_prop_bag_container():get_item(BagPos)
    if not item then
        return ""
    end
    return item:get_item_creator()
end

function script_base:LuaFnGetItemPrice(itemId)
    local common_item = configenginer:get_config("common_item")
    common_item = common_item[itemId]
    return common_item.base_price
end

function script_base:LuaFnExpAssign()

end

function script_base:LuaAddPrenticeProExp(selfId, PrenticeGuid, Exps)
    local human = self:get_scene():get_obj_by_id(selfId)
    human:add_prentice_pro_exp(Exps)
end

function script_base:LuaFnGetPrenticeGUID(selfId, index)
    local human = self:get_scene():get_obj_by_id(selfId)
    local relation_info = human:get_relation_info()
    local prentice_guid = relation_info.prentice_guid or {}
    return prentice_guid[index] or define.INVAILD_ID
end

function script_base:LuaFnExpelPrentice(selfId, guid)
    local human = self:get_scene():get_obj_by_id(selfId)
    local relation_info = human:get_relation_info()
    local prentice_guid = relation_info.prentice_guid or {}
    for i = #prentice_guid, 1, -1 do
        if prentice_guid[i] == guid then
            table.remove(prentice_guid, i)
            break
        end
    end
    local friends = relation_info.friends or {}
    relation_info.friends = friends
    self:ModifyRelationType(friends, guid, define.RELATION_TYPE.RELATION_TYPE_FRIEND)
    human:set_relation_info(relation_info)
end

function script_base:LuaFnFinishAprentice(selfId, targetId)
    local human = self:get_scene():get_obj_by_id(selfId)
    local my_relation = human:get_relation_info()
    local other = self:get_scene():get_obj_by_id(targetId)
    local other_relation = other:get_relation_info()
    my_relation.master = define.INVAILD_ID
    local prentice_guid = other_relation.prentice_guid or {}
    for i = #prentice_guid, 1, -1 do
        if prentice_guid[i] == human:get_guid() then
            table.remove(prentice_guid, i)
            break
        end
    end

    local my_friends = my_relation.friends or {}
    my_relation.friends = my_friends
    self:ModifyRelationType(my_friends, other:get_guid(), define.RELATION_TYPE.RELATION_TYPE_FRIEND)

    local other_friends = other_relation.friends or {}
    other_relation.friends = other_friends
    self:ModifyRelationType(other_friends, human:get_guid(), define.RELATION_TYPE.RELATION_TYPE_FRIEND)

    human:set_relation_info(my_relation)
    other:set_relation_info(other_relation)
end

function script_base:LuaFnAprentice(selfId, targetId)
    local human = self:get_scene():get_obj_by_id(selfId)
    local my_relation = human:get_relation_info()
    local other = self:get_scene():get_obj_by_id(targetId)
    local other_relation = other:get_relation_info()
    local prentice_guid = my_relation.prentice_guid or {}
    my_relation.master = other:get_guid()
    other_relation.prentice_guid = prentice_guid
    table.insert(prentice_guid, human:get_guid())

    local my_friends = my_relation.friends or {}
    my_relation.friends = my_friends
    self:ModifyRelationType(my_friends, other:get_guid(), define.RELATION_TYPE.RELATION_TYPE_PRENTICE)
    
    local other_friends = other_relation.friends or {}
    other_relation.friends = other_friends
    self:ModifyRelationType(other_friends, human:get_guid(), define.RELATION_TYPE.RELATION_TYPE_MASTER)
    
    human:set_relation_info(my_relation)
    other:set_relation_info(other_relation)
end

function script_base:LuaFnGetPrenticeCount(selfId)
    local human = self:get_scene():get_obj_by_id(selfId)
    local relation_info = human:get_relation_info()
    local prentice_guid = relation_info.prentice_guid or {}
    return #prentice_guid
end

function script_base:LuaFnIsStalling(selfId)
    local human = self:get_scene():get_obj_by_id(selfId)
    local stall_box = human:get_stall_box()
    return stall_box:get_stall_is_open()
end

function script_base:LuaFnAuditMasterExp()

end

function script_base:IsLocked()
    return false
end

function script_base:CityGetAttr(selfId, Attr)
    local human = self:get_scene():get_obj_by_id(selfId)
    if human == nil then
        return 0
    end
    return skynet.call(".Guildmanager", "lua", "city_get_attr", human:get_guild_id(), Attr, human:get_guid())
end

function script_base:CityChangeAttr(selfId, Attr, Change)
    local human = self:get_scene():get_obj_by_id(selfId)
    return skynet.call(".Guildmanager", "lua", "city_change_attr", human:get_guid(), human:get_guild_id(), Attr, Change)
end

function script_base:LuaFnGetThisMonth()
    local now = os.time()
    return tonumber(os.date("%m", now))
end

function script_base:LuaFnGetDayOfThisMonth()
    local now = os.time()
    return tonumber(os.date("%d", now))
end

function script_base:LuaFnSetHumanGoodBadValue(selfId, value)
    local human = self:get_scene():get_obj_by_id(selfId)
    human:set_good_bad_value(value)
end

function script_base:LuaFnGetHumanGoodBadValue(selfId)
    local human = self:get_scene():get_obj_by_id(selfId)
    return human:get_good_bad_value()
end

function script_base:LuaFnGetMasterMoralPoint(selfId)
    local human = self:get_scene():get_obj_by_id(selfId)
    return human:get_master_moral_point()
end

function script_base:GetItemInfoByItemId(item_index)
    local tmp = item_cls.new()
    tmp.item_index = item_index
    local base = tmp:get_base_config()
    assert(base, item_index)
    return item_index, base.name, base.desc
end

function script_base:LuaFnAuditItemCreate()

end

function script_base:SetItemBoxMaxGrowTime(selfId, maxTime)
    local itembox = self:get_scene():get_obj_by_id(selfId)
    assert(type(maxTime) == "number", maxTime)
    itembox:set_max_grow_time(maxTime)
end

function script_base:SetItemBoxOwner(selfId, owner)
    local itembox = self:get_scene():get_obj_by_id(selfId)
    itembox:set_owner_guid(owner)
end

function script_base:GetItemBoxOwner(selfId)
    local itembox = self:get_scene():get_obj_by_id(selfId)
    return itembox:get_owner_guid()
end

function script_base:GetItemBoxWorldPosX(selfId)
    local itembox = self:get_scene():get_obj_by_id(selfId)
    local world_pos = itembox:get_world_pos()
    return world_pos.x
end

function script_base:GetItemBoxWorldPosZ(selfId)
    local itembox = self:get_scene():get_obj_by_id(selfId)
    local world_pos = itembox:get_world_pos()
    return world_pos.y
end

function script_base:SetItemBoxPickOwnerTime(selfId, pick_owner_time)
    local itembox = self:get_scene():get_obj_by_id(selfId)
    itembox:set_pick_owner_time(pick_owner_time)
end

function script_base:EnableItemBoxPickOwnerTime(selfId)
    local itembox = self:get_scene():get_obj_by_id(selfId)
    itembox:enable_pick_owner_time()
end

function script_base:LuaFnGetItemBoxGrowPointType(selfId)
    local item_box = self:get_scene():get_obj_by_id(selfId)
    return item_box:get_type()
end

function script_base:GetItemBoxRequireAbilityID(selfId)
    local item_box = self:get_scene():get_obj_by_id(selfId)
    local item_box_type = item_box:get_type()
    local grow_point = configenginer:get_config("grow_point")
    grow_point = grow_point[item_box_type]
    assert(grow_point, item_box_type)
    return grow_point["对应生活技能ID"]
end

function script_base:LuaFnGetItemCount(selfId, itemTableIndex)
    local human = self:get_scene():get_obj_by_id(selfId)
    local count = 0
    count = count + human_item_logic:calc_bag_item_count(human, itemTableIndex)
    local equip_container = human:get_equip_container()
    count = count + equip_container:get_item_count_by_type(itemTableIndex)
    return count
end

function script_base:LuaFnBusGetObjIDByGUID(guid)
    local bus = self:get_scene():get_obj_by_guid(guid)
    return bus:get_obj_id()
end

function script_base:LuaFnBusAddPassenger_Shuttle(busId, selfId, targetId)
    local bus = self:get_scene():get_obj_by_id(busId)
    local human = self:get_scene():get_obj_by_id(selfId)
    local npc = self:get_scene():get_obj_by_id(targetId)
    if bus:is_moving() then
        return
    end
    local bus_world_pos = bus:get_world_pos()
    local npc_world_pos = npc:get_world_pos()
    local dist = self:get_scene():cal_dist(bus_world_pos, npc_world_pos)
    if dist > 6 then
        return
    end
    if bus:is_full() then
        return define.OPERATE_RESULT.OR_BUS_PASSENGERFULL
    end
    if human:has_mount() then
        return define.OPERATE_RESULT.OR_BUS_HASMOUNT
    end
    if human:get_pet() then
        return define.OPERATE_RESULT.OR_BUS_HASPET
    end
    if human:get_team_follow_flag() then
        return define.OPERATE_RESULT.OR_BUS_CANNOT_TEAM_FOLLOW
    end
    if human:has_dride() then
        return define.OPERATE_RESULT.OR_BUS_CANNOT_DRIDE
    end
    if human:has_change_mode() then
        return define.OPERATE_RESULT.OR_BUS_CANNOT_CHANGE_MODEL
    end
    bus:passengers_on(human:get_obj_id())
    return define.OPERATE_RESULT.OR_OK
end

function script_base:LuaFnCreateBusByPatrolPathId(dataId, PatrolId, Athwart)
    local obj = self:get_scene():create_bus_with_patrol_id(dataId, PatrolId, Athwart)
    if obj == nil then
        return define.INVAILD_ID
    end
    return obj:get_obj_id()
end

function script_base:LuaFnBusAddPassengerList(bus_id, targetId, pos_1, pos_2, objId_1, objId_2)
    local bus = self:get_scene():get_obj_by_id(bus_id)
    local npc = self:get_scene():get_obj_by_id(targetId)
    local obj_1 = self:get_scene():get_obj_by_id(objId_1)
    local obj_2 = self:get_scene():get_obj_by_id(objId_2)
    if bus:is_moving() then
        return
    end
    if bus:has_poisition() < 2 then
        return define.OPERATE_RESULT.OR_BUS_PASSENGERFULL
    end
    if obj_1:has_mount() or obj_2:has_mount() then
        return define.OPERATE_RESULT.OR_BUS_HASMOUNT
    end
    if obj_1:get_pet() or obj_2:get_pet() then
        return define.OPERATE_RESULT.OR_BUS_HASPET
    end
    if obj_1:get_team_follow_flag() or obj_2:get_team_follow_flag() then
        return define.OPERATE_RESULT.OR_BUS_CANNOT_TEAM_FOLLOW
    end
    if obj_1:has_dride() or obj_2:has_dride() then
        return define.OPERATE_RESULT.OR_BUS_CANNOT_DRIDE
    end
    if obj_1:has_change_mode() or obj_2:has_change_mode() then
        return define.OPERATE_RESULT.OR_BUS_CANNOT_CHANGE_MODEL
    end
    bus:passengers_on(obj_1:get_obj_id())
    bus:passengers_on(obj_2:get_obj_id())
    return define.OPERATE_RESULT.OR_OK
end

function script_base:LuaFnBusStart(busId)
    local bus = self:get_scene():get_obj_by_id(busId)
    if bus == nil then
        return false
    end
    if bus:is_moving() then
        return false
    end
    bus:start()
    return true
end

function script_base:LuaFnBusRemoveAllPassenger(busId)
    local bus = self:get_scene():get_obj_by_id(busId)
    if bus == nil then
        return false
    end
    bus:passengers_off()
    return true
end

function script_base:LuaFnDeleteBus(busId)
    local bus = self:get_scene():get_obj_by_id(busId)
    self.scene:delete_temp_bus(bus)
end

function script_base:StartMissionTimer(selfId, MissionId)
    local human = self:get_scene():get_obj_by_id(selfId)
    human:start_mission_timer(MissionId)
end

function script_base:StopMissionTimer(selfId, MissionId)
    local human = self:get_scene():get_obj_by_id(selfId)
    human:stop_mission_timer(MissionId)
end

function script_base:FindCopySceneIDByCopySceneParams(copy_scene_type, _, index, val)
    local dest_scene_id = skynet.call(".Copyscenemanager", "lua", "find_copy_scene_id_by_copy_scene_params", copy_scene_type, index, val)
    return dest_scene_id
end

function script_base:CheckPlayerCanApplyCity(selfId)
    local human = self:get_scene():get_obj_by_id(selfId)
    return skynet.call(".Guildmanager", "lua", "check_player_can_apply_city", human:get_guid(), human:get_guild_id())
end

function script_base:LuaFnGetMaterialStartBagPos()
    return 100
end

function script_base:LuaFnGetHumanGuildLeagueName(selfId)
    local human = self:get_scene():get_obj_by_id(selfId)
    return human:get_confederate_name()
end

function script_base:LuaFnSetWorldGlobalData(index, val)
    skynet.send(".world", "lua", "set_global_data", index, val)
end

function script_base:LuaFnGetWorldGlobalData(index)
    return skynet.call(".world", "lua", "get_global_data", index)
end

function script_base:GetPlayerPvpMode(selfId)
    local human = self:get_scene():get_obj_by_id(selfId)
    return human:get_pk_mode()
end

function script_base:LuaFnGetGuildName(selfId)
    local human = self:get_scene():get_obj_by_id(selfId)
    return human:get_guild_name()
end

function script_base:LuaFnGetHumanPKValue(selfId)
    local human = self:get_scene():get_obj_by_id(selfId)
    if human and human:get_obj_type() == "human" then
        return human:get_pk_value()
    else
        return 0
    end
end

function script_base:GetHumanGuildName(selfId)
    return self:LuaFnGetGuildName(selfId)
end

function script_base:GetLeagueGuildsIDandName(league_id)
    local guild_infos = skynet.call(".Guildmanager", "lua", "get_league_guilds_id_and_name", league_id)
    return guild_infos
end

function script_base:CityMoveTo(selfId)
    local human = self:get_scene():get_obj_by_id(selfId)
    local city_id = self:CityGetSelfCityID(selfId)
    local ok, scene_id = pcall(skynet.call, ".Dynamicscenemanager", "lua", "check_city_running", city_id)
    local name = ok and scene_id and skynet.localname(string.format(".SCENE_%d", scene_id))
    if name and human then
        self:CallScriptFunction((400900), "TransferFunc", selfId, scene_id, 100, 60)
    else
        self:notify_tips(selfId, "帮会城市异常,暂时不能进入")
        skynet.loge("attemp enter unload city scene city_id =", city_id, ", scene_id =", scene_id)
    end
end

function script_base:IsPhoenixPlainBaZhu(selfId)
	local query_x = {delflag = 1,score = 10000}
	local backData = skynet.call(".db", "lua", "findOne", {collection = "phoenixplain_rec",query = query_x})
	if backData then
		if self:GetMissionData(selfId,ScriptGlobal.MD_SHOUHUA) == backData.index
		and self:GetMissionDataEx(selfId,ScriptGlobal.MDEX_FH_TIME) == backData.opentime
		and self:GetMissionDataEx(selfId,ScriptGlobal.MDEX_FH_PARTICIPATIONTIME) >= backData.needtime then
			return true
		end
	end
	return false
end
function script_base:GetPhoenixPlainData(delflag,index,value)
	local query_x = {delflag = delflag}
	if index == 1 then
		query_x["index"] = value
	elseif index == 2 then
		query_x["score"] = value
	elseif index == 3 then
		query_x["name"] = value
	end
	local backData = skynet.call(".db", "lua", "findOne", {collection = "phoenixplain_rec",query = query_x})
	return backData
end
function script_base:AddPhoenixPlainData(secinfo_jifen,secinfo_killplayer)
	for i = 1,2 do
		local istrue = skynet.call(".db", "lua", "findOne", {collection = "phoenixplain_rec",query = {delflag = i}})
		if istrue then
			skynet.send(".db", "lua", "delete", { collection = "phoenixplain_rec", selector = {delflag = i}})
		end
	end
	for i,j in ipairs(secinfo_jifen) do
		skynet.send(".db", "lua", "insert", { collection = "phoenixplain_rec", doc = j})
	end
	for i,j in ipairs(secinfo_killplayer) do
		skynet.send(".db", "lua", "insert", { collection = "phoenixplain_rec", doc = j})
	end
end
--[[
    score_list = { 
    { 
        league_id = 同盟id, guild_id_1 = 帮会1ID,  guild_id_2 = 帮会2ID,  
        guild_id_3 = 帮会3ID, crystal_hold_score = 占领水晶分数, 
        flag_capture_score = 旗子分数, league_name = 同盟名称， 
        guild_name_1 = 帮会1名称, guild_name_2 = 帮会2名称, guild_name_3 = 帮会3名称 } 
}
]]

function script_base:NotifyAllScore(score_list)
	local msg = packet_def.GCPhoenixPlainWarScore.new()
	msg.score_list = score_list
	self:get_scene():broadcastall(msg)
end
function script_base:LuaFnDispatchPhoenixPlainWarScore(score_list)
	if self:IsWarScene() then
		-- assert(self:get_scene_id() == 191, self:get_scene_id())
		local msg = packet_def.GCPhoenixPlainWarScore.new()
		msg.score_list = score_list
		self:get_scene():broadcastall(msg)
	end
end

function script_base:SceneBroadcastMsg(msg)
    if not has_system_message_content(msg) then
        return
    end
    local packet = packet_def.GCChat.new()
	packet.ChatType = 4
	packet.Sourceid = define.INVAILD_ID
	packet.unknow_2 = 1
    local Contex = msg
	Contex = gbk.fromutf8(Contex)
	packet:set_content("@*;SrvMsg;SCA:" .. Contex)
    self:get_scene():broadcastall(packet)
end
function script_base:SceneBroadcastMsgEx(msg)
    if not has_system_message_content(msg) then
        return
    end
    local packet = packet_def.GCChat.new()
	packet.ChatType = 4
	packet.Sourceid = define.INVAILD_ID
	packet.unknow_2 = 1
    local Contex = msg
	Contex = gbk.fromutf8(Contex)
	packet:set_content(Contex)
    self:get_scene():broadcastall(packet)
end

function script_base:DispatchPhoenixPlainWarCampInfo()
    assert(self:get_scene_id() == 191, self:get_scene_id())
    local camp_infos = { xs = {}, ys = {}, names = {}}
    local camp_groups = {}
    local objs = self:get_scene():get_objs()
    for _, obj in pairs(objs) do
        if obj:get_obj_type() == "human" then
            local camp_id = obj:get_camp_id()
            local one_camp_group = camp_groups[camp_id] or { objs = {}, camp_infos = { xs = {}, ys = {}, names = {}} }
            if #one_camp_group.objs < 400 then
                local world_pos = obj:get_world_pos()
                local name = obj:get_name()
                table.insert(one_camp_group.objs, obj)
                table.insert(one_camp_group.camp_infos.xs, world_pos.x)
                table.insert(one_camp_group.camp_infos.ys, world_pos.y)
                table.insert(one_camp_group.camp_infos.names, name)
            else
                print("objs count is too big count =", #one_camp_group.objs)
            end
            camp_groups[camp_id] = one_camp_group
        end
    end
    for camp_id, group in pairs(camp_groups) do
        local msg = packet_def.GCPhoenixPlainWarCampInfo.new()
        msg.camp_infos = group.camp_infos
        msg.count = #group.objs
        self:get_scene():broadcast_to_objs(group.objs, msg)
    end
end
--[[
crystal_pos = { 
{ 
    --第一个水晶
    [1] = 
    {
        world_pos = {x = -1, y = -1}, --水晶位置
        league_id = -1, --占领水晶同盟id
        guild_id = -1, --占领水晶帮会id
        league_name = "", --占领水晶同盟名称
        hp = 0, -- 写死传0
    },
    --第二个水晶
    [2] = 
    {
        world_pos = {x = -1, y = -1}, --水晶位置
        league_id = -1, --占领水晶同盟id
        guild_id = -1, --占领水晶帮会id
        league_name = "", --占领水晶同盟名称
        hp = 0, -- 写死传0
    },
    --第三个水晶
    [3] = 
    {
        world_pos = {x = -1, y = -1}, --水晶位置
        league_id = -1, --占领水晶同盟id
        guild_id = -1, --占领水晶帮会id
        league_name = "", --占领水晶同盟名称
        hp = 0, -- 写死传0
    },
    --第四个水晶
    [4] = 
    {
        world_pos = {x = -1, y = -1}, --水晶位置
        league_id = -1, --占领水晶同盟id
        guild_id = -1, --占领水晶帮会id
        league_name = "", --占领水晶同盟名称
        hp = 0, -- 写死传0
    },
}
]]

function script_base:NotifyCrystalOne(index,flag_name,flag_pos)
	if not index or index < 0 or index > 4 then
		return
	elseif not flag_name or not flag_pos then
		return
	end
    local msg = packet_def.GCPhoenixPlainWarCrystalPos.new()
	msg.crystal_poss =  
	{ 
		--第一个水晶
		[1] = 
		{
			world_pos = {x = -1, y = -1}, --水晶位置
			league_id = -1, --占领水晶同盟id
			guild_id = -1, --占领水晶帮会id
			league_name = "", --占领水晶同盟名称
			hp = 0, -- 写死传0
		},
		--第二个水晶
		[2] = 
		{
			world_pos = {x = -1, y = -1}, --水晶位置
			league_id = -1, --占领水晶同盟id
			guild_id = -1, --占领水晶帮会id
			league_name = "", --占领水晶同盟名称
			hp = 0, -- 写死传0
		},
		--第三个水晶
		[3] = 
		{
			world_pos = {x = -1, y = -1}, --水晶位置
			league_id = -1, --占领水晶同盟id
			guild_id = -1, --占领水晶帮会id
			league_name = "", --占领水晶同盟名称
			hp = 0, -- 写死传0
		},
		--第四个水晶
		[4] = 
		{
			world_pos = {x = -1, y = -1}, --水晶位置
			league_id = -1, --占领水晶同盟id
			guild_id = -1, --占领水晶帮会id
			league_name = "", --占领水晶同盟名称
			hp = 0, -- 写死传0
		},
	}
	if index ~= 0 then
		msg.crystal_poss[index] = {
			world_pos = flag_pos,
			league_id = index,
			guild_id = index,
			league_name = flag_name,
			hp = 0,
		}
	end
    self:get_scene():broadcastall(msg)
end


function script_base:DispatchPhoenixPlainWarCrystalPos(crystal_pos)
	if self:IsWarScene() then
    -- assert(self:get_scene_id() == 191, self:get_scene_id())
    local msg = packet_def.GCPhoenixPlainWarCrystalPos.new()
    msg.crystal_poss = crystal_pos
    self:get_scene():broadcastall(msg)
	end
end

--[[
flag_pos = { 
{ 
    world_pos = { x = 0, y = 0}, --地图上旗子的位置
    hold_name = "", --手里拿着旗子的玩家
    hold_guild_name = "", --手里拿着旗子的玩家的同盟
}
]]
function script_base:EmptyPlainWarFlagPos()
	local msg = packet_def.GCPhoenixPlainWarFlagPos.new()
	msg.world_pos = { x = 0, y = 0}
	msg.hold_flag_name = ""
	msg.hold_flag_guild_name = ""
	self:get_scene():broadcastall(msg)
end
function script_base:DispatchPhoenixPlainWarFlagPos(flag_pos)
	if self:IsWarScene() then
    -- assert(self:get_scene_id() == 191, self:get_scene_id())
		local msg = packet_def.GCPhoenixPlainWarFlagPos.new()
		msg.world_pos = flag_pos.world_pos
		msg.hold_flag_name = flag_pos.hold_name
		msg.hold_flag_guild_name = flag_pos.hold_guild_name
		self:get_scene():broadcastall(msg)
	end
end
function script_base:IsWarScene()
	local sceneId = self:get_scene_id()
	if sceneId == 191
	or sceneId == 313
	or sceneId == 314
	or sceneId == 315
	or sceneId == 713
	or sceneId == 714
	or sceneId == 715
	or sceneId == self:LuaFnGetCopySceneData_Param(0,66) then
		return true
	end
	return false
end
function script_base:SetHp(selfId, hp)
    local obj = self:get_scene():get_obj_by_id(selfId)
    obj:set_hp(hp)
end

function script_base:SetMp(selfId, mp)
    local obj = self:get_scene():get_obj_by_id(selfId)
    obj:set_mp(mp)
end

function script_base:IsEquipItem(itemindex)
    -- local item = item_cls.new()
    -- item:set_index(itemindex)
    -- return item:is_equip()
    local equip_base = configenginer:get_config("equip_base")
	local base = equip_base[itemindex]
	if base then
		return base.equip_point
	end
end

function script_base:GetScriptIDByMissionID(selfId, mission_id)
    local human = self:get_scene():get_obj_by_id(selfId)
    return human:get_script_id_by_mission_id(mission_id) or define.INVAILD_ID
end

function script_base:TIsHaveContinue(missionIndex)
    local mission = self:TGetMissionByMissionIndex(missionIndex)
    return mission["是否有Continue"]
end

function script_base:TGetLootItemInfo(mission_index)
    local mission = self:TGetMissionByMissionIndex(mission_index)
    local kill_data_count = mission["击杀种类数（最多5）"]
    return kill_data_count, mission["怪物名称1$1$"],
    mission["是否寻找随机物品"], 
    mission["掉落物品1"],  mission["掉落概率1"], mission["掉落数量1"], 
    mission["怪物名称2$1$"], mission["掉落物品2"],  mission["掉落概率2"], mission["掉落数量2"], 
    mission["怪物名称3$1$"], mission["掉落物品3"],  mission["掉落概率3"], mission["掉落数量3"], 
    mission["怪物名称4$1$"], mission["掉落物品4"],  mission["掉落概率4"], mission["掉落数量4"], 
    mission["怪物名称5$1$"], mission["掉落物品5"],  mission["掉落概率5"], mission["掉落数量5"]
end

function script_base:TGetAwardItem(mission_index)
    local mission = self:TGetMissionByMissionIndex(mission_index)
    local awards = {
        { id = mission["固定物品奖励1"], count = mission["固定物品个数1"]}, 
        { id = mission["固定物品奖励2"], count = mission["固定物品个数2"]}, 
        { id = mission["固定物品奖励3"], count = mission["固定物品个数3"]}, 
        { id = mission["固定物品奖励4"], count = mission["固定物品个数4"]}, 
        { id = mission["固定物品奖励5"], count = mission["固定物品个数5"]} 
    }
    local count = 0
    for _, award in ipairs(awards) do
        local id = award.id or 0
        if id ~= 0 then
            count = count + 1
        end
    end
    return count, 
        awards[1].id, awards[1].count,
        awards[2].id, awards[2].count,
        awards[3].id, awards[3].count,
        awards[4].id, awards[4].count,
        awards[5].id, awards[5].count
end

function script_base:TGetRadioItem(mission_index)
    local mission = self:TGetMissionByMissionIndex(mission_index)
    local awards = {
        { id = mission["可选物品奖励1"], count = mission["可选物品奖励个数1"]}, 
        { id = mission["可选物品奖励2"], count = mission["可选物品奖励个数2"]}, 
        { id = mission["可选物品奖励3"], count = mission["可选物品奖励个数3"]}, 
        { id = mission["可选物品奖励4"], count = mission["可选物品奖励个数4"]}, 
        { id = mission["可选物品奖励5"], count = mission["可选物品奖励个数5"]} 
    }
    local count = 0
    for _, award in ipairs(awards) do
        local id = award.id or define.INVAILD_ID
        if id ~= define.INVAILD_ID then
            count = count + 1
        end
    end
    return count, 
        awards[1].id, awards[1].count,
        awards[2].id, awards[2].count,
        awards[3].id, awards[3].count,
        awards[4].id, awards[4].count,
        awards[5].id, awards[5].count
end

function script_base:TGetHideItem(mission_index)
    local mission = self:TGetMissionByMissionIndex(mission_index)
    local awards = {
        { id = mission["隐藏奖励物品1"], count = mission["隐藏奖励个数1"]}, 
        { id = mission["隐藏奖励物品2"], count = mission["隐藏奖励个数2"]}, 
        { id = mission["隐藏奖励物品3"], count = mission["隐藏奖励个数3"]}
    }
    local count = 0
    for _, award in ipairs(awards) do
        local id = award.id or define.INVAILD_ID
        if id ~= define.INVAILD_ID then
            count = count + 1
        end
    end
    return count, 
        awards[1].id, awards[1].count,
        awards[2].id, awards[2].count,
        awards[3].id, awards[3].count
end

function script_base:TGetAwardMoney(mission_index)
    local mission = self:TGetMissionByMissionIndex(mission_index)
    return mission["金钱奖励"]
end

function script_base:TGetAwardExp(mission_index)
    local mission = self:TGetMissionByMissionIndex(mission_index)
    return mission["经验奖励"]
end

function script_base:TGetMissionByMissionIndex(mission_index)
    local mission_loot_item = configenginer:get_config("mission_loot_item")
    mission_loot_item = mission_loot_item[mission_index]
    if mission_loot_item then
        return mission_loot_item
    end
    local mission_delivery = configenginer:get_config("mission_delivery")
    mission_delivery = mission_delivery[mission_index]
    if mission_delivery then
        return mission_delivery
    end
    local mission_enter_area = configenginer:get_config("mission_enter_area")
    mission_enter_area = mission_enter_area[mission_index]
    if mission_enter_area then
        return mission_enter_area
    end
    local mission_husong = configenginer:get_config("mission_husong")
    mission_husong = mission_husong[mission_index]
    if mission_husong then
        return mission_husong
    end
    local mission_kill_monster = configenginer:get_config("mission_kill_monster")
    mission_kill_monster = mission_kill_monster[mission_index]
    if mission_kill_monster then
        return mission_kill_monster
    end
end

function script_base:TGetRelationShipAwardInfo(mission_index)
    local mission = self:TGetMissionByMissionIndex(mission_index)
    return mission["关系值存储位置"], mission["关系值奖励"], mission["关系值奖励提示$1$"]
end

function script_base:TGetRelationShipPunishInfo(mission_index)
    local mission = self:TGetMissionByMissionIndex(mission_index)
    return mission["关系值存储位置"], mission["放弃任务关系值惩罚"], mission["关系值惩罚提示$1$"]
end

function script_base:TGetAcceptNpcInfo(mission_index)
    local mission = self:TGetMissionByMissionIndex(mission_index)
    return mission["接受任务场景ID"], mission["接受任务NpcName$1$"]
end

function script_base:TGetMissionDesc(mission_index)
    local mission = self:TGetMissionByMissionIndex(mission_index)
    return mission["任务目标$1$"], mission["任务详细描述$1$"], mission["任务继续信息$1$"], mission["任务完成信息$1$"]
end

function script_base:TGetMissionIdByIndex(mission_index)
    local mission = self:TGetMissionByMissionIndex(mission_index)
    assert(mission, mission_index)
    return mission["MissionId"]
end

function script_base:TGetMissionName(mission_index)
    local mission = self:TGetMissionByMissionIndex(mission_index)
    return mission["任务名称$1$"]
end

function script_base:GetNextMissionIndex(mission_index)
    local mission = self:TGetMissionByMissionIndex(mission_index)
    return mission["后续任务INDEX"]
end

function script_base:TGetCheckInfo(mission_index)
    local mission = self:TGetMissionByMissionIndex(mission_index)
    return mission["任务需求等级"], mission["前续任务Id1"], 
    mission["前续任务Id2"], mission["前续任务Id3"]
end

function script_base:TGetKillInfo(mission_index)
    local mission = self:TGetMissionByMissionIndex(mission_index)
    return mission["击杀种类数（最多8）"], mission["怪物名称1$1$"], mission["击杀数量1"],
    mission["怪物名称2$1$"], mission["击杀数量2"],
    mission["怪物名称3$1$"], mission["击杀数量3"],
    mission["怪物名称4$1$"], mission["击杀数量4"],
    mission["怪物名称5$1$"], mission["击杀数量5"],
    mission["怪物名称6$1$"], mission["击杀数量6"],
    mission["怪物名称7$1$"], mission["击杀数量7"],
    mission["怪物名称8$1$"], mission["击杀数量8"]
end

function script_base:TGetCompleteNpcInfo(mission_index)
    local mission = self:TGetMissionByMissionIndex(mission_index)
    return mission["完成任务场景ID"], mission["完成任务NpcName$1$"]
end

function script_base:TGetEnterAreaInfo(mission_index)
    local mission_enter_area = configenginer:get_config("mission_enter_area")
    mission_enter_area = mission_enter_area[mission_index]
    return mission_enter_area["进入区域总数"],
        mission_enter_area["区域所在场景1"], mission_enter_area["区域1"],
        mission_enter_area["区域所在场景2"], mission_enter_area["区域2"],
        mission_enter_area["区域所在场景3"], mission_enter_area["区域3"]
end

function script_base:TGetEnterAreaDesc(mission_index)
    local mission_enter_area = configenginer:get_config("mission_enter_area")
    mission_enter_area = mission_enter_area[mission_index]
    return mission_enter_area["进入区域是否有对白"], mission_enter_area["进入区域的对白$1$"], mission_enter_area["进入区域的提示$1$"]
end

function script_base:TGetHusongPatrolPath(mission_index)
    local mission_husong = configenginer:get_config("mission_husong")
    mission_husong = mission_husong[mission_index]
    return mission_husong["护送路线ID"]
end

function script_base:TGetHusongAIType(mission_index)
    local mission_husong = configenginer:get_config("mission_husong")
    mission_husong = mission_husong[mission_index]
    return mission_husong["AI类型"]
end

function script_base:TGetTargetNpcInfo(mission_index)
    local mission = self:TGetMissionByMissionIndex(mission_index)
    return mission["任务目标场景ID"] or mission["护送目标的场景号"], mission["任务目标NPC$1$"] or mission["护送目标的名字$1$"], mission["任务目标NPC是否动态"] == 1, mission["任务目标NPC对白$1$"]
end

function script_base:TGetSongXinInfo(mission_index)
    local mission_delivery = configenginer:get_config("mission_delivery")
    mission_delivery = mission_delivery[mission_index]
    return mission_delivery["送物种类数量（最多5）"], 
    mission_delivery["第一个物品ID"], mission_delivery["第一个物品数量"], mission_delivery["第一个物品是否在接任务时由NPC给予"],
    mission_delivery["第二个物品ID"], mission_delivery["第二个物品数量"], mission_delivery["第二个物品是否在接任务时由NPC给予"],
    mission_delivery["第三个物品ID"], mission_delivery["第三个物品数量"], mission_delivery["第三个物品是否在接任务时由NPC给予"],
    mission_delivery["第四个物品ID"], mission_delivery["第四个物品数量"], mission_delivery["第四个物品是否在接任务时由NPC给予"],
    mission_delivery["MissionItem_HashTable列号"], mission_delivery["第五个物品数量"], mission_delivery["第五个物品是否在接任务时由NPC给予"]
end

function script_base:TGetLimitedTimeInfo(mission_index)
    local mission = self:TGetMissionByMissionIndex(mission_index)
    return mission["放弃任务后禁止接任务的时间存储位置"], mission["禁止的时间长度，秒"], mission["时间限制内接任务的提示$1$"]
end

function script_base:TGetDuologue(id)
    local stiry_telling_duo_logue = configenginer:get_config("stiry_telling_duo_logue")
    return stiry_telling_duo_logue["对话内容$1$"]
end

function script_base:GetMonsterIdByName(monster_name)
    local objs = self:get_scene():get_objs()
    for _, obj in pairs(objs) do
        if obj:get_name() == monster_name then
            return obj:get_obj_id()
        end
    end
end

function script_base:GetMonsterRespawnPos(selfId)
    local monster = self:get_scene():get_obj_by_id(selfId)
    local pos = monster:get_respawn_pos()
    return pos.x, pos.y
end

function script_base:AddNpcPatrolEndPointOperator(selfId, operator, ...)
    local monster = self:get_scene():get_obj_by_id(selfId)
    monster:get_ai():add_patrol_endpoint_operator(operator, ...)
end

function script_base:GetNPCAIType(selfId)
    local monster = self:get_scene():get_obj_by_id(selfId)
    return monster:get_base_ai()
end

function script_base:GetUnitReputationID(selfId, targetId)
    local monster = self:get_scene():get_obj_by_id(targetId)
    return monster:get_reputation()
end

function script_base:ResetMissionEvent(selfId, mission_id, event)
    local human = self:get_scene():get_obj_by_id(selfId)
    human:reset_mission_event(mission_id, event)
end

function script_base:TIsMissionRoundable(mission_index)
    local mission = self:TGetMissionByMissionIndex(mission_index)
    return mission["是否循环任务"] == 1
end

function script_base:GetHighRepairPrice(selfId, ItemPos)
    local price = 10000
    local human = self:get_scene():get_obj_by_id(selfId)
    local bag_container = human:get_prop_bag_container()
    local item = bag_container:get_item(ItemPos)
    local dur = item:get_equip_data():get_dur()
    local max_dur = item:get_equip_data():get_max_dur()
    local dur_diff = max_dur - dur
    return price + dur_diff * 150
end

function script_base:DoHighRepair(selfId, ItemPos, price)
    local human = self:get_scene():get_obj_by_id(selfId)
    local bag_container = human:get_prop_bag_container()
    local item = bag_container:get_item(ItemPos)
    if item == nil then
        return -5
    end
    if not item:is_equip() then
        return -5
    end
    local dur = item:get_equip_data():get_dur()
    local max_dur = item:get_equip_data():get_max_dur()
    if dur >= max_dur then
        return -6
    end
    if not human:check_money_with_priority(price) then
        return -2
    end
    local repaire_fail_times = item:get_equip_data():get_repaire_fail_times()
    if repaire_fail_times >= 3 then
        return -1
    end
    local is_fail = math.random(10) == 1
    if is_fail then
        item:get_equip_data():set_repaire_fail_times(repaire_fail_times + 1)
        self:LuaFnRefreshItemInfo(selfId, ItemPos)
        return -4
    end
    item:get_equip_data():set_dur(max_dur)
    human:cost_money_with_priority(price, "高级装备修理")
    self:LuaFnRefreshItemInfo(selfId, ItemPos)
    return 0
end

function script_base:DoShenQiRepaire(selfId, EquipPos, MaterialPos)
    local human = self:get_scene():get_obj_by_id(selfId)
    local bag_container = human:get_prop_bag_container()
    local equip = bag_container:get_item(EquipPos)
    if not equip:is_equip() then
        return -5
    end
    local dur = equip:get_equip_data():get_dur()
    local max_dur = equip:get_equip_data():get_max_dur()
    if dur >= max_dur then
        return -6
    end
    equip:get_equip_data():set_dur(max_dur)
    self:LuaFnRefreshItemInfo(selfId, EquipPos)
    return 0
end

function script_base:LuaFnFaileTimes(selfId, ItemPos, MaterialPos, type)
    local human = self:get_scene():get_obj_by_id(selfId)
    local bag_container = human:get_prop_bag_container()
    local equip = bag_container:get_item(ItemPos)
    if equip == nil then
        return -1
    end
    local material = bag_container:get_item(MaterialPos)
    if material == nil then
        return -1
    end
    if self:LuaFnIsItemLocked(selfId, ItemPos) then
        return -2
    end
    if not self:LuaFnIsItemAvailable(selfId, MaterialPos) then
        return -3
    end
    local repaire_fail_times = equip:get_equip_data():get_repaire_fail_times()
    if repaire_fail_times <= 0 then
        return -4
    end
    if type == 0 then
        equip:get_equip_data():set_repaire_fail_times(0)
    else
        equip:get_equip_data():set_repaire_fail_times(repaire_fail_times - 1)
    end
    self:LuaFnRefreshItemInfo(selfId, ItemPos)
    return 0
end

function script_base:IsPermitAreetAddMenpai()
    return false
end

function script_base:CityGetCityName(selfId, scene_id)
    local city_name = skynet.call(".Dynamicscenemanager", "lua", "get_city_name", scene_id)
    return city_name or ""
end

function script_base:CityMoveToScene(selfId, scene_id, x, y)
    local human = self:get_scene():get_obj_by_id(selfId)
    local ok, ready_scene_id = pcall(skynet.call, ".Dynamicscenemanager", "lua", "ensure_city_scene", scene_id)
    if not ok or tonumber(ready_scene_id) ~= tonumber(scene_id) then
        self:notify_tips(selfId, "帮会城市异常,暂时不能进入")
        skynet.loge("attemp enter unload city scene scene_id =", scene_id)
        return
    end
    scene_id = ready_scene_id
    local name = skynet.localname(string.format(".SCENE_%d", scene_id))
    if name and human then
        self:CallScriptFunction((400900), "TransferFunc", selfId, scene_id, x, y)
    else
        self:notify_tips(selfId, "帮会城市异常,暂时不能进入")
        skynet.loge("attemp enter unload city scene scene_id =", scene_id)
    end
end

function script_base:GetTopUpPoint(selfId)
    local human = self:get_scene():get_obj_by_id(selfId)
    return human:get_top_up_point()
end

function script_base:CostTopUpPoint(selfId, cost)
    local human = self:get_scene():get_obj_by_id(selfId)
    return human:cost_top_up_point(cost)
end

function script_base:GetOneMissionNpc(group)
    -- CY's argument is a membership column, not a row ID. Keep the direct
    -- lookup in GetNpcInfoByNpcId separate from this random group lookup.
    local config = configenginer:get_config("mission_npc_hash_table")
    local ids = config.index[group]
    local id = ids and #ids > 0 and ids[math.random(1, #ids)] or nil
    local row = id and config.data[id] or nil
    if not row then return -1, "", "", -1, 0, 0, "", -1, -1 end
    return id, row["NPC名称$1$"], row["场景名称$1$"],
        row["场景ID"], row["坐标X"], row["坐标Z"],
        row["NPC描述$1$"], row["性别"], row["等级"]
end

function script_base:GetNpcInfoByNpcId(npc_id)
    local mission_npc_hash_table = configenginer:get_config("mission_npc_hash_table")
    local mission_npc = mission_npc_hash_table.data[npc_id]
    if mission_npc then
        return npc_id, mission_npc["NPC名称$1$"], mission_npc["场景名称$1$"],
        mission_npc["场景ID"], mission_npc["坐标X"], mission_npc["坐标Z"],
        mission_npc["NPC描述$1$"], mission_npc["性别"], mission_npc["等级"]
    else
        return define.INVAILD_ID, ""
    end
end

function script_base:GetOneMissionBonusItem(itemHashIndex)
    local mission_item_hash_table = configenginer:get_config("mission_item_hash_table")
    local sum = 0
    for _, conf in ipairs(mission_item_hash_table.award[itemHashIndex]) do
        sum = sum + conf.conf
    end
    local num = math.random(1, sum)
    local cur = 0
    for _, conf in ipairs(mission_item_hash_table.award[itemHashIndex]) do
        cur = cur + conf.conf
        if cur >= num then
            local id = conf.id
            local data = mission_item_hash_table.data[id]
            return data["物品编号"], data["物品名称$1$"], data["物品描述$1$"]
        end
    end
end

function script_base:GetOneMissionItem(itemHashIndex)
    local mission_item_hash_table = configenginer:get_config("mission_item_hash_table")
    local sum = 0
    for _, conf in ipairs(mission_item_hash_table.use[itemHashIndex]) do
        sum = sum + conf.conf
    end
    local num = math.random(1, sum)
    local cur = 0
    for _, conf in ipairs(mission_item_hash_table.use[itemHashIndex]) do
        cur = cur + conf.conf
        if cur >= num then
            local id = conf.id
            local data = mission_item_hash_table.data[id]
            return data["物品编号"], data["物品名称$1$"], data["物品描述$1$"]
        end
    end
end

function script_base:GetOneMissionPet(petHashIndex)
    local mission_pet_hash_table = configenginer:get_config("mission_pet_hash_table")
    local sum = 0
    for _, conf in ipairs(mission_pet_hash_table.index[petHashIndex]) do
        sum = sum + conf.conf
    end
    local num = math.random(1, sum)
    local cur = 0
    for _, conf in ipairs(mission_pet_hash_table.index[petHashIndex]) do
        cur = cur + conf.conf
        if cur >= num then
            local id = conf.id
            local data = mission_pet_hash_table.data[id]
            return data["珍兽编号"], data["珍兽名称$1$"], data["珍兽描述$1$"]
        end
    end
end

function script_base:LuaFnGetPetCount(selfId)
    local human = self:get_scene():get_obj_by_id(selfId)
    local pet_bag_container = human:get_pet_bag_container()
    local num = 0
    for i = 0, (pet_bag_container:get_size() - 1) do
        local item = pet_bag_container:get_item(i)
        if item then
            num = num + 1
        end
    end
    return num
end

function script_base:LuaFnGetPet_DataID(selfId, index)
    local human = self:get_scene():get_obj_by_id(selfId)
    local pet_bag_container = human:get_pet_bag_container()
    local num = 0
    for i = 0, (pet_bag_container:get_size() - 1) do
        local item = pet_bag_container:get_item(i)
        if item then
            num = num + 1
            if num == index then
                return item:get_data_index()
            end
        end
    end
end

function script_base:LuaFnGetPet_Level(selfId, index)
    local human = self:get_scene():get_obj_by_id(selfId)
    local pet_bag_container = human:get_pet_bag_container()
    local num = 0
    for i = 0, (pet_bag_container:get_size() - 1) do
        local item = pet_bag_container:get_item(i)
        if item then
            num = num + 1
            if num == index then
                return item:get_level()
            end
        end
    end
end

function script_base:LuaFnGetPet_HP(selfId, index)
    local human = self:get_scene():get_obj_by_id(selfId)
    local pet_bag_container = human:get_pet_bag_container()
    local num = 0
    for i = 0, (pet_bag_container:get_size() - 1) do
        local item = pet_bag_container:get_item(i)
        if item then
            num = num + 1
            if num == index then
                return item:get_hp()
            end
        end
    end
end

function script_base:LuaFnGetPet_MaxHP(selfId, index)
    local human = self:get_scene():get_obj_by_id(selfId)
    local pet_bag_container = human:get_pet_bag_container()
    local num = 0
    for i = 0, (pet_bag_container:get_size() - 1) do
        local item = pet_bag_container:get_item(i)
        if item then
            num = num + 1
            if num == index then
                return item:get_max_hp()
            end
        end
    end
end

function script_base:LuaFnGetPetGUID(selfId, index)
    local human = self:get_scene():get_obj_by_id(selfId)
    local pet_bag_container = human:get_pet_bag_container()
    local num = 0
    for i = 0, (pet_bag_container:get_size() - 1) do
        local item = pet_bag_container:get_item(i)
        if item then
            num = num + 1
            if num == index then
                local guid = item:get_guid()
                return guid.m_uHighSection, guid.m_uLowSection
            end
        end
    end
end

function script_base:LuaFnSetPetHP(selfId, petGUID_H, petGUID_L, hp)
    local obj = self.scene:get_obj_by_id(selfId)
    local container = obj:get_pet_bag_container()
    local guid = pet_guid_cls.new()
    guid:set(petGUID_H, petGUID_L)
    local pet_detail = container:get_pet_by_guid(guid)
    return pet_detail:set_hp(hp)
end

function script_base:LuaFnSetPetData(selfId, petGUID_H, petGUID_L, key, value)
    local obj = self.scene:get_obj_by_id(selfId)
    local container = obj:get_pet_bag_container()
    local guid = pet_guid_cls.new()
    guid:set(petGUID_H, petGUID_L)
    local pet_detail = container:get_pet_by_guid(guid)
    pet_detail:set_db_attrib({ [key] = value})
    obj:send_pets_detail(obj)
end

function script_base:LuaFnDeletePet(selfId, index)
    local human = self:get_scene():get_obj_by_id(selfId)
    local pet_bag_container = human:get_pet_bag_container()
    local num = 0
    for i = 0, (pet_bag_container:get_size() - 1) do
        local item = pet_bag_container:get_item(i)
        if item then
            num = num + 1
            if num == index then
                pet_bag_container:erase_item(i)
                local msg = packet_def.GCRemovePet.new()
                msg.guid = item:get_guid()
                self:get_scene():send2client(human, msg)
                return
            end
        end
    end
end

function script_base:LuaFnDeletePetByGUID(selfId, petGUID_H, petGUID_L)
    local human = self:get_scene():get_obj_by_id(selfId)
    local pet_bag_container = human:get_pet_bag_container()
    local guid = pet_guid_cls.new()
    guid:set(petGUID_H, petGUID_L)
    local index = pet_bag_container:get_index_by_pet_guid(guid)
    if index then
        pet_bag_container:erase_item(index)
        local msg = packet_def.GCRemovePet.new()
        msg.guid = guid
        self:get_scene():send2client(human, msg)
        return true
    end
    return false
end

function script_base:IsWhiteEquip(ItemIndex)
    local white_equip_base = configenginer:get_config("white_equip_base")
    return white_equip_base[ItemIndex] ~= nil
end

function script_base:LuaFnGetMaterialBagSpace(selfId)
    local human = self:get_scene():get_obj_by_id(selfId)
    local prop_bag_container = human:get_prop_bag_container()
    return prop_bag_container:get_empty_index_count("material")
end

function script_base:GetMoneyMultipleByRound(round)
    local shimen_round_multiple_table = configenginer:get_config("shimen_round_multiple_table")
    shimen_round_multiple_table = shimen_round_multiple_table[round]
    return shimen_round_multiple_table["金钱倍率"]
end

function script_base:GetExpMultipleByRound(round)
    local shimen_round_multiple_table = configenginer:get_config("shimen_round_multiple_table")
    shimen_round_multiple_table = shimen_round_multiple_table[round]
    return shimen_round_multiple_table["经验倍率"]
end

function script_base:GetHuashanV()
    return define.MENPAI_ATTRIBUTE.MATTRIBUTE_WUMENPAI
end

function script_base:LuaFnAuditPlayerBehavior()

end

function script_base:ResetKillMonsterCount(selfId)
    local human = self:get_scene():get_obj_by_id(selfId)
    human:set_today_kill_monster_count(0)
end

function script_base:ResetCampaignCount(selfId)
    local human = self:get_scene():get_obj_by_id(selfId)
    human:reset_campaign_count()
end

function script_base:CalMonsterDropItems(model_id)
    local scene = self:get_scene()
    local item_drop_manager = scene:get_item_drop_manager()
    return item_drop_manager:caculate_drop_item_box(model_id)
end

function script_base:CalMonsterAwardExp(model_id)
    local monster_attr_ex = configenginer:get_config("monster_attr_ex")
    monster_attr_ex = monster_attr_ex[model_id]
    return monster_attr_ex.base_exp
end

function script_base:ParserIniFile(ini)
    local scene_config_env = skynet.getenv"scene_config_env"
    local fullname = string.format("%s/%s", scene_config_env, ini)
    local reader = require"inireader".new()
    local r, ini_file = pcall(reader.load, reader, fullname)
    if r then
        return ini_file
    end
end

function script_base:LuaFnWashSomePoints(selfId, ntype, point)
    local human = self:get_scene():get_obj_by_id(selfId)
    return human:wash_some_points(ntype, point)
end

function script_base:LuaFnWashPoints(selfId)
    local human = self:get_scene():get_obj_by_id(selfId)
    return human:wash_points()
end

function script_base:LuaFnAuditShengShouOpenSmallBox()

end

function script_base:ActiveRmbChatInfo(selfId, id, date)
    local human = self:get_scene():get_obj_by_id(selfId)
    human:active_rmb_chat_info(id, date)
end

function script_base:TransferNowTime()
    local t = os.date("*t")
    return ((t.year - 2000) << 26) | ((t.month - 1 & 0xF) << 22) | ((t.day & 0x1F) << 17) | ((t.hour & 0x1F) << 12) | ((t.min & 0x3F) << 6) | (t.sec & 0x3F)
end

function script_base:DeTransferNowTime(val)
    local sec = (val & 0x3F)
    local min = ((val >> 6) & 0x3F)
    local hour = ((val >> 12) & 0x1F)
    local day = ((val >> 17) & 0x1F)
    local month = ((val >> 22) & 0xF)
    local year = ((val >> 26))
    local time = os.time({year = year + 2000, month = month + 1, day = day, hour = hour, min = min, sec = sec})
    return time
end

function script_base:GetPetMedicineHCCompound(id)
    local pet_medicine_hc_compound = configenginer:get_config("pet_medicine_hc_compound")
    pet_medicine_hc_compound = pet_medicine_hc_compound[id]
    return pet_medicine_hc_compound["合成后的灵兽丹ID（暂不开放的填 -1）"], pet_medicine_hc_compound["需要消耗的金钱"]
end

function script_base:GetHumanMaxXiulianLevel(selfId)
    local human = self:get_scene():get_obj_by_id(selfId)
    return human:get_max_level_xiulian_level()
end

function script_base:GetZhanLingAwardConfig(level, Type)
    local zhanling_info = configenginer:get_config("zhanling_info")
    zhanling_info = zhanling_info[level]
    return zhanling_info.ItemID[Type], zhanling_info.ItemCount[Type]
end

function script_base:GetZhanLingEndDate(date)
    local zhanling_time_info = configenginer:get_config("zhanling_time_info")
    for _, zt in ipairs(zhanling_time_info) do
        if date >= zt.Begin and date <= zt.End then
            return zt.End
        end
    end
end

function script_base:UpXinfaLevel(selfId, level)
    local human = self:get_scene():get_obj_by_id(selfId)
    human:up_xinfa_level(level)
end

function script_base:DispatchJiYuanShopInfo(selfId, targetId)
    local human = self:get_scene():get_obj_by_id(selfId)
    human:send_jiyuan_shop_info(targetId)
end

function script_base:LuaFnIsRiding(selfId)
    local human = self:get_scene():get_obj_by_id(selfId)
    return human:get_ride_model() ~= define.INVAILD_ID
end

function script_base:LuaFnIsModelOrMount(selfId)
    local human = self:get_scene():get_obj_by_id(selfId)
    return human:get_model_id() ~= define.INVAILD_ID
end

function script_base:IsCanChangeUserName()
    return true
end

function script_base:LuaFnIsEnemy(selfId, targetId)
    local obj_me = self:get_scene():get_obj_by_id(selfId)
    local obj_tar = self:get_scene():get_obj_by_id(targetId)
    if obj_me == nil or obj_tar == nil then
        return false
    end
    return obj_me:is_enemy(obj_tar)
end

function script_base:LuaFnCheckResetWanShiGeData(selfId)
    local obj_me = self:get_scene():get_obj_by_id(selfId)
    obj_me:check_reset_wanshige_data()
end

function script_base:LuaFnGetMysteryShopCountByID(selfId, item_id)
    local obj_me = self:get_scene():get_obj_by_id(selfId)
    return obj_me:get_mystery_shop_count_by_id(item_id)
end

function script_base:LuaFnGetWanShiGeShopCountByID(selfId, item_id)
    local obj_me = self:get_scene():get_obj_by_id(selfId)
    return obj_me:get_wanshige_shop_count_by_id(item_id)
end

function script_base:LuaFnGetJiYuanShopCountByID(selfId, item_id)
    local obj_me = self:get_scene():get_obj_by_id(selfId)
    return obj_me:get_jiyuan_shop_count_by_id(item_id)
end

function script_base:LuaFnAuditDaTu()

end

function script_base:LOGI(...)
    skynet.logi(...)
end

function script_base:LuaFnSendGuajiQuestion()

end

function script_base:GetPetSoulSmashResult(selfId, BagPos)
    local obj_me = self:get_scene():get_obj_by_id(selfId)
    local prop_bag_container = obj_me:get_prop_bag_container()
    local soul = prop_bag_container:get_item(BagPos)
    local quanlity = soul:get_pet_equip_data():get_pet_soul_quanlity()
    local pet_soul_level = soul:get_pet_equip_data():get_pet_soul_level()
    local pet_soul_exp = soul:get_pet_equip_data():get_pet_soul_exp()
    local pet_soul_base = configenginer:get_config("pet_soul_base")
    pet_soul_base = pet_soul_base[soul:get_index()]
    for i = 1, pet_soul_level do
        pet_soul_exp = pet_soul_exp + pet_soul_base.exps[i]
    end
    local material_id = pet_soul_base.material
    local count = math.floor(pet_soul_exp / 20)
    if quanlity == 2 then
        count = count + 40
    elseif quanlity == 1 then
        count = count + 30
    else
        count = count + 20
    end
    return material_id, count, soul:is_bind()
end

function script_base:LuaFnGetDestSceneHumanCount(id)
    local count = datacenter.get("scene_human_count", tostring(id))
    return count or 0
end

function script_base:LuaFnGetPetContainerSpaceCount(selfId)
    local obj_me = self:get_scene():get_obj_by_id(selfId)
    local container = obj_me:get_pet_bag_container()
    return container:get_empty_index_count()
end

function script_base:GetPetSoulPossPaintConfig(PetSoulId)
    local exterior_ranse = configenginer:get_config("exterior_ranse")
    exterior_ranse = exterior_ranse[PetSoulId]
    return exterior_ranse
end

function script_base:UnlockExteriorRanSe(selfId, soul_id, index, color_value)
    local human = self:get_scene():get_obj_by_id(selfId)
    local ret = human:unlock_exterior_ranse(soul_id, index, color_value)
    return ret
end

function script_base:ShowPetSoulRanse(selfId, targetId)
    local human = self:get_scene():get_obj_by_id(selfId)
    human:send_exterior_ranse(3, targetId)
end

function script_base:GetShenBingLevelConfig(level)
    local shenbing_level = configenginer:get_config("shenbing_level")
    shenbing_level = shenbing_level[level]
    if not shenbing_level then
        return
    end
    return shenbing_level["MaterialID"], shenbing_level["MaterialCount"], shenbing_level["CostMoney"]
end

function script_base:GetShenBingZhuQingLevel(selfId, BagPos)
    local human = self:get_scene():get_obj_by_id(selfId)
    assert(human,"对象不存在。")
    local prop_bag_container = human:get_prop_bag_container()
    local item = prop_bag_container:get_item(BagPos)
	if not item then
		human:notify_tips("位置上没有道具。")
		return
	end
	local shenbing = configenginer:get_config("shenbing")
	shenbing = shenbing[item:get_index()]
	if not shenbing then
		human:notify_tips("未开放神兵ID。")
		return
	end
    -- assert(item:get_equip_data():get_equip_type() == 4, item:get_index())
    return item:get_equip_data():get_fwq_zhuqing()
end

function script_base:SetShenBinZhuQingLevel(selfId, BagPos, level)
    local human = self:get_scene():get_obj_by_id(selfId)
    assert(human,"对象不存在。")
    local prop_bag_container = human:get_prop_bag_container()
    local item = prop_bag_container:get_item(BagPos)
	if not item then
		human:notify_tips("位置上没有道具。")
		return
	end
	local equip_data = item:get_equip_data()
    assert(equip_data:get_equip_type() == 4, item:get_index())
    equip_data:set_fwq_zhuqing(level)
	local shenbing_level = configenginer:get_config("shenbing_level")
	shenbing_level = shenbing_level[level]
	if shenbing_level then
		equip_data:set_fwq_live_time(shenbing_level.LiveTime * 1000)
	end
    self:LuaFnRefreshItemInfo(selfId, BagPos)
end

function script_base:GetShenBinSkillUpgradeRequirement(selfId, BagPos, g_CurSel)
    local human = self:get_scene():get_obj_by_id(selfId)
    assert(human,"对象不存在。")
    local prop_bag_container = human:get_prop_bag_container()
    local item = prop_bag_container:get_item(BagPos)
	if not item then
		human:notify_tips("位置上没有道具。")
		return
	end
	local shenbing = configenginer:get_config("shenbing")
	shenbing = shenbing[item:get_index()]
	if not shenbing then
		human:notify_tips("未开放神兵ID。")
		return
	end
	local skill_id
	local equip_data = item:get_equip_data()
	if g_CurSel > 2 then
		local index = g_CurSel - 2
		local fwq_list_2 = equip_data:get_fwq_list_2()
		if fwq_list_2[index] == 0 then
			human:notify_tips("#{SBFW_20230707_170}")
			return
		end
		local skill_list_2 = equip_data:get_fwq_skill_list_2()
		skill_id = skill_list_2[index]
	else
		local skill_list_1 = equip_data:get_fwq_skill_list_1()
		skill_id = skill_list_1[g_CurSel]
	end
	if not skill_id then
		human:notify_tips("技能不存在。")
		return
	end
	shenbing = configenginer:get_config("shenbing_skill_up")
	shenbing = shenbing[skill_id]
	if not shenbing then
		human:notify_tips("技能不存在于升级表中。")
		return
	elseif shenbing.newid == -1 then
		human:notify_tips("#{SBFW_20230707_171}")
		return
	end
	return shenbing.newid,skill_id,shenbing.level,shenbing.needitem,shenbing.needitem_count,shenbing.needmoney
end

function script_base:SetShenBinSkillUpgrade(selfId, BagPos, g_CurSel, old_id, new_id)
    local human = self:get_scene():get_obj_by_id(selfId)
    assert(human,"对象不存在。")
    local prop_bag_container = human:get_prop_bag_container()
    local item = prop_bag_container:get_item(BagPos)
	if not item then
		human:notify_tips("位置上没有道具。")
		return
	end
	local shenbing = configenginer:get_config("shenbing")
	shenbing = shenbing[item:get_index()]
	if not shenbing then
		human:notify_tips("未开放神兵ID。")
		return
	end
	local skill_id,index
	local equip_data = item:get_equip_data()
	if g_CurSel > 2 then
		index = g_CurSel - 2
		local fwq_list_2 = equip_data:get_fwq_list_2()
		if fwq_list_2[index] == 0 then
			human:notify_tips("#{SBFW_20230707_170}")
			return
		end
		local skill_list_2 = equip_data:get_fwq_skill_list_2()
		skill_id = skill_list_2[index]
	else
		local skill_list_1 = equip_data:get_fwq_skill_list_1()
		skill_id = skill_list_1[g_CurSel]
	end
	if not skill_id then
		human:notify_tips("技能不存在。")
		return
	elseif skill_id ~= old_id then
		human:notify_tips("升级技能不符。")
		return
	end
	if index then
		equip_data:set_fwq_skill_list_2_value(index,new_id)
	else
		equip_data:set_fwq_skill_list_1_value(g_CurSel,new_id)
	end
    self:LuaFnRefreshItemInfo(selfId, BagPos)
end

function script_base:CheckShenBinSkillUnlock(selfId, BagPos, g_CurSel)
    local human = self:get_scene():get_obj_by_id(selfId)
    assert(human,"对象不存在。")
    local prop_bag_container = human:get_prop_bag_container()
    local item = prop_bag_container:get_item(BagPos)
	if not item then
		human:notify_tips("位置上没有道具。")
		return
	end
	local shenbing = configenginer:get_config("shenbing")
	shenbing = shenbing[item:get_index()]
	if not shenbing then
		human:notify_tips("未开放神兵ID。")
		return
	end
	local equip_data = item:get_equip_data()
	local fwq_list_2 = equip_data:get_fwq_list_2()
	if fwq_list_2[g_CurSel] ~= 0 then
		human:notify_tips("#{SBFW_20230707_158}")
		return
	end
    return equip_data:get_fwq_zhuqing()
end

function script_base:SetShenBinSkillUnlock(selfId, BagPos, g_CurSel)
    local human = self:get_scene():get_obj_by_id(selfId)
    assert(human,"对象不存在。")
    local prop_bag_container = human:get_prop_bag_container()
    local item = prop_bag_container:get_item(BagPos)
	if not item then
		human:notify_tips("位置上没有道具。")
		return
	end
	local shenbing = configenginer:get_config("shenbing")
	shenbing = shenbing[item:get_index()]
	if not shenbing then
		human:notify_tips("未开放神兵ID。")
		return
	end
	local equip_data = item:get_equip_data()
	local fwq_list_2 = equip_data:get_fwq_list_2()
	if fwq_list_2[g_CurSel] ~= 0 then
		human:notify_tips("#{SBFW_20230707_158}")
		return
	end
	equip_data:set_fwq_list_2_value(g_CurSel,1)
    self:LuaFnRefreshItemInfo(selfId, BagPos)
end

function script_base:CheckShenBinSkillSelect(selfId, BagPos, g_Sel_Skill_Index_1,g_Sel_Skill_Index_2)
    local human = self:get_scene():get_obj_by_id(selfId)
    assert(human,"对象不存在。")
    local prop_bag_container = human:get_prop_bag_container()
    local item = prop_bag_container:get_item(BagPos)
	if not item then
		human:notify_tips("位置上没有道具。")
		return
	end
	local shenbing_common_skill = configenginer:get_config("shenbing_common_skill")
	shenbing_common_skill = shenbing_common_skill[item:get_index()]
	if not shenbing_common_skill then
		human:notify_tips("未开放神兵ID。")
		return
	end
	local equip_data = item:get_equip_data()
	local skill_list_1 = equip_data:get_fwq_skill_list_1()
	local list_1_skill_id = skill_list_1[1]
	local list_2_skill_id = skill_list_1[2]
	local left_tbl,right_tbl = {},{}
	for _,j in ipairs(shenbing_common_skill.up) do
		for k,v in ipairs(j) do
			if v == list_1_skill_id then
				for i = 1,4 do
					table.insert(left_tbl,shenbing_common_skill.up[i][k])
				end
				break
			end
		end
	end
	for _,j in ipairs(shenbing_common_skill.down) do
		for k,v in ipairs(j) do
			if v == list_2_skill_id then
				for i = 1,4 do
					table.insert(right_tbl,shenbing_common_skill.down[i][k])
				end
				break
			end
		end
	end
	if #left_tbl ~= 4 then
		human:notify_tips("技能索引出错。")
		table.insert(left_tbl,"left_tbl")
		local collection = "log_shenbing"
		local doc = {
			fun_name = "CheckShenBinSkillSelect",
			name = human:get_name(),
			guid = human:get_guid(),
			params = left_tbl,
			date_time = os.date("%y-%m-%d %H:%M:%S")
		}
		self:SetGameLog(collection,doc)
		return
	elseif #right_tbl ~= 4 then
		human:notify_tips("技能索引出错。")
		table.insert(right_tbl,"right_tbl")
		local collection = "log_shenbing"
		local doc = {
			fun_name = "CheckShenBinSkillSelect",
			name = human:get_name(),
			guid = human:get_guid(),
			params = right_tbl,
			date_time = os.date("%y-%m-%d %H:%M:%S")
		}
		self:SetGameLog(collection,doc)
		return
	end
	if left_tbl[g_Sel_Skill_Index_1] == list_1_skill_id and right_tbl[g_Sel_Skill_Index_2] == list_2_skill_id then
		human:notify_tips("#{SBFW_20230707_152}")
		return
	end
	return left_tbl[g_Sel_Skill_Index_1],right_tbl[g_Sel_Skill_Index_2]
end

function script_base:SetShenBinSkillSelect(selfId, BagPos, list_1_skill_id,list_2_skill_id)
    local human = self:get_scene():get_obj_by_id(selfId)
    assert(human,"对象不存在。")
    local prop_bag_container = human:get_prop_bag_container()
    local item = prop_bag_container:get_item(BagPos)
	if not item then
		human:notify_tips("位置上没有道具。")
		return
	end
	local shenbing = configenginer:get_config("shenbing")
	shenbing = shenbing[item:get_index()]
	if not shenbing then
		human:notify_tips("未开放神兵ID。")
		return
	end
	local equip_data = item:get_equip_data()
	equip_data:set_fwq_skill_list_1({list_1_skill_id,list_2_skill_id})
    self:LuaFnRefreshItemInfo(selfId, BagPos)
end

function script_base:CheckShenBinTransition(selfId, BagPos1, BagPos2, cost_money)
    local human = self:get_scene():get_obj_by_id(selfId)
    assert(human,"对象不存在。")
    local prop_bag_container = human:get_prop_bag_container()
    local item1 = prop_bag_container:get_item(BagPos1)
	if not item1 then
		human:notify_tips("#{SBFW_20230707_142}")
		return
	end
	local shenbing = configenginer:get_config("shenbing")
	local shenbing1 = shenbing[item1:get_index()]
	if not shenbing1 then
		human:notify_tips("源装备未开放神兵ID。")
		return
	end
	local shenbing_skill_up = configenginer:get_config("shenbing_skill_up")
	local equip_data1 = item1:get_equip_data()
	local lv1 = equip_data1:get_fwq_zhuqing()
	local list_1_skill_lv = {0,0}
	local list_2_skill_lv = {0,0,0}
	local skill_list_1 = equip_data1:get_fwq_skill_list_1()
	local skill_list_2 = equip_data1:get_fwq_skill_list_2()
	for i,j in ipairs(skill_list_1) do
		if shenbing_skill_up[j] then
			list_1_skill_lv[i] = shenbing_skill_up[j].level
		end
	end
	for i,j in ipairs(skill_list_2) do
		if shenbing_skill_up[j] then
			list_2_skill_lv[i] = shenbing_skill_up[j].level
		end
	end
	local istrue = false
	if lv1 > 1 then
		istrue = true
	else
		for i,j in ipairs(list_1_skill_lv) do
			if j > 1 then
				istrue = true
				break
			end
		end
		if not istrue then
			for i,j in ipairs(list_2_skill_lv) do
				if j > 1 then
					istrue = true
					break
				end
			end
		end
	end
	if not istrue then
		human:notify_tips("#{SBFW_20230707_144}")
		return
	end
    local item2 = prop_bag_container:get_item(BagPos2)
	if not item2 then
		human:notify_tips("#{SBFW_20230707_143}")
		return
	end
	local shenbing2 = shenbing[item2:get_index()]
	if not shenbing2 then
		human:notify_tips("目标装备未开放神兵ID。")
		return
	end
	local equip_data2 = item2:get_equip_data()
	local fwq_list_2_fu = equip_data2:get_fwq_list_2()
	local skill_list_1_fu = equip_data2:get_fwq_skill_list_1()
	local skill_list_2_fu = equip_data2:get_fwq_skill_list_2()
	local list_1_skill_lv_fu = {0,0}
	local list_2_skill_lv_fu = {0,0,0}
	for i,j in ipairs(skill_list_1_fu) do
		if shenbing_skill_up[j] then
			list_1_skill_lv_fu[i] = list_1_skill_lv[i] - shenbing_skill_up[j].level
		end
	end
	for i,j in ipairs(skill_list_2_fu) do
		if shenbing_skill_up[j] then
			list_2_skill_lv_fu[i] = list_2_skill_lv[i] - shenbing_skill_up[j].level
		end
	end
	human:cost_money_with_priority(cost_money, "LuaFnCostMoneyWithPriority")
	item1:set_is_bind(true)
	item2:set_is_bind(true)
	equip_data1:set_fwq_zhuqing(1)
	equip_data1:set_fwq_list_2({0,0,0})
	equip_data1:set_fwq_skill_list_1({ shenbing1.Skill_2, shenbing1.Skill_3 })
	equip_data1:set_fwq_skill_list_2({ shenbing1.Skill_4, shenbing1.Skill_5, shenbing1.Skill_6 })
    local msg = packet_def.GCItemInfo.new()
    msg.bagIndex = BagPos1
    msg.unknow_1 = 0
    msg.item = item1:copy_raw_data()
    self.scene:send2client(selfId, msg)
	
	equip_data2:set_fwq_zhuqing(lv1)
	for i,j in ipairs(list_2_skill_lv) do
		if j > 1 then
			fwq_list_2_fu[i] = 1
		end
	end
	for i,j in ipairs(skill_list_1_fu) do
		skill_list_1_fu[i] = j + list_1_skill_lv_fu[i]
	end
	for i,j in ipairs(skill_list_2_fu) do
		skill_list_2_fu[i] = j + list_2_skill_lv_fu[i]
	end
	equip_data2:set_fwq_list_2(fwq_list_2_fu)
	equip_data2:set_fwq_skill_list_1(skill_list_1_fu)
	equip_data2:set_fwq_skill_list_2(skill_list_2_fu)
    msg = packet_def.GCItemInfo.new()
    msg.bagIndex = BagPos2
    msg.unknow_1 = 0
    msg.item = item2:copy_raw_data()
    self.scene:send2client(selfId, msg)
end

function script_base:FixLegacyShenBinData(selfId,BagPos)
    local human = self:get_scene():get_obj_by_id(selfId)
    assert(human,"对象不存在。")
    local prop_bag_container = human:get_prop_bag_container()
    local item = prop_bag_container:get_item(BagPos)
	if not item then
		human:notify_tips("位置上没有道具。")
		return
	end
	local shenbing_id = item:get_index()
	local shenbing = configenginer:get_config("shenbing")
	shenbing = shenbing[shenbing_id]
	if not shenbing then
		human:notify_tips("未开放神兵ID。")
		return
	end
	local equip_data = item:get_equip_data()
	if equip_data:get_fwq_change_skill() == -1 then
		local zhuqing = equip_data:get_fwq_zhuqing()
		local shenbing_level = configenginer:get_config("shenbing_level")
		shenbing_level = shenbing_level[zhuqing]
		if shenbing_level then
			equip_data:set_fwq_live_time(shenbing_level.LiveTime * 1000)
		else
			equip_data:set_fwq_zhuqing(1)
			equip_data:set_fwq_live_time(8000)
		end
		local shenbing_visual = configenginer:get_config("shenbing_visual")
        shenbing_visual = shenbing_visual[shenbing_id]
		if shenbing_visual then
			equip_data:set_visual(shenbing_visual.visual)
			equip_data:set_action(shenbing_visual.action)
		else
			equip_data:set_visual(0)
			equip_data:set_action(-1)
		end
		equip_data:set_fwq_change_skill(shenbing.Change_skill)
		equip_data:set_fwq_passive_skill(shenbing.Skill_1)
		equip_data:set_fwq_list_2({0,0,0})
		equip_data:set_fwq_skill_list_1({ shenbing.Skill_2, shenbing.Skill_3 })
		equip_data:set_fwq_skill_list_2({ shenbing.Skill_4, shenbing.Skill_5, shenbing.Skill_6 })
		local msg = packet_def.GCItemInfo.new()
		msg.bagIndex = BagPos
		msg.unknow_1 = 0
		msg.item = item:copy_raw_data()
		self.scene:send2client(selfId, msg)
		return true
	end
end

function script_base:LuaFnIsBagItemExpensive(selfId, BagPos)
    local human = self:get_scene():get_obj_by_id(selfId)
    local prop_bag_container = human:get_prop_bag_container()
    local item = prop_bag_container:get_item(BagPos)
    return item:is_expensive()
end

function script_base:GetShenBingStar(selfId, BagPos)
    local human = self:get_scene():get_obj_by_id(selfId)
    local prop_bag_container = human:get_prop_bag_container()
    local item = prop_bag_container:get_item(BagPos)
    assert(item:get_equip_data():get_equip_type() == 4, item:get_index())
    return item:get_equip_data():get_fwq_star()
end

function script_base:DispatchTJCPVPCnmData(selfId)
    local msg = packet_def.GCTJCPVPCmnData.new()
    local count = self:LuaFnGetAvailableItemCount(selfId, 38002808)
    msg.buy_counts[5] = count
    self:get_scene():send2client(selfId, msg)
end

function script_base:HumanZhuanXing(selfId, sex)
    local human = self:get_scene():get_obj_by_id(selfId)
    assert(human:get_obj_type() == "human", human:get_obj_type())
    local model = human:get_model()
    if model == 0 then
        human:set_model(1)
    else
        human:set_model(0)
    end
    local hair_style = human:get_exterior_hair_style_index()
    local face_style = human:get_exterior_face_style_index()
    local portrait_id = human:get_exterior_portrait_index()
    self:ChangePlayerHairModel(selfId, hair_style)
    self:ChangePlayerFaceModel(selfId, face_style)
    self:ChangePlayerHeadImage(selfId, portrait_id)
    human:send_refresh_attrib()
    return true
end
function script_base:GetRanking(ranking_id)
    local world_id = self:get_scene():get_world_id()
    local ranking = skynet.call(".ranking", "lua", "get_ranking", world_id, ranking_id)
    return ranking
end

function script_base:GetMyRanking(selfId, ranking_id)
    local human = self:get_scene():get_obj_by_id(selfId)
    local guid = human:get_guid()
    local world_id = self:get_scene():get_world_id()
    return skynet.call(".ranking", "lua", "get_my_ranking", world_id, ranking_id, guid)
end

function script_base:SaveRankingValue(selfId, ranking_id, value)
    local human = self:get_scene():get_obj_by_id(selfId)
    local guid = human:get_guid()
    local name = human:get_name()
    local world_id = self:get_scene():get_world_id()
    return skynet.call(".ranking", "lua", "save_value", world_id, ranking_id, guid, name, value)
end

function script_base:LuaFnAwardFreshManEquipWithGemList(selfId, menpaiID)
    local gem_list = ScriptGlobal.MENPAI_FRESH_MAN_GEM_LIST[menpaiID]
    if gem_list == nil then
        return false, "门派新玩家奖励配置异常"
    end
    self:BeginAddItem()
	for equip_point, item_id in pairs(ScriptGlobal.MENPAI_FRESH_MAN_EQUIP_LIST) do
		self:AddItem(item_id, 1, true, { gem_list = gem_list[equip_point] })
	end
	if not self:EndAddItem(selfId, nil, 116) then
		return false, "背包空间不足"
	end
	if not self:AddItemListToHuman(selfId, 116) then return false, "reward_bag_changed" end
    return true
end

function script_base:LuaFnGetPreRechargeMoney(selfId, period)
    local human = self:get_scene():get_obj_by_id(selfId)
    local begin = os.time(period.begin)
    local stop = os.time(period.stop)
    return human:get_prerechage_money(begin, stop)
end

function script_base:CallDestSceneFunction(dest_scene_id, script_id, func, ...)
    local scene = string.format(".SCENE_%d", dest_scene_id)
    return skynet.call(scene, "lua", "char_excute_Script", script_id, func, ...)
end

function script_base:CallDestSceneFunctionEx(dest_scene_id, script_id, func, ...)
    local scene = string.format(".SCENE_%d", dest_scene_id)
    return skynet.send(scene, "lua", "char_excute_Script", script_id, func, ...)
end


function script_base:StartProfile()
	self:get_scene():start_profile()
	local skynet = require "skynet"
	skynet.timeout(1000, function()
		self:get_scene():stop_profile()
	end)
end

function script_base:DBLog(selfId, log_tag, log)
    local obj = self:get_scene():get_obj_by_id(selfId)
    local collection = "db_log_rec"
    local doc = {
        name = obj:get_name(),
        guid = obj:get_guid(),
        address = skynet.self(),
        log_tag = log_tag,
        log = log,
        time = os.time(),
        date_time = utils.get_day_time(),
        process_id = tonumber(skynet.getenv "process_id")
    }
    skynet.send(".logdb", "lua", "insert", { collection = collection, doc = doc})
end

function script_base:SetSceneChiJiFlag(dest_scene_id)
    local scene = string.format(".SCENE_%d", dest_scene_id)
    print("SetSceneChiJiFlag scene =", scene)
    skynet.call(scene, "lua", "set_chiji_flag")
end

function script_base:SetCanGetAwards(selfId, awards_name, awards_list)
    local human = self:get_scene():get_obj_by_id(selfId)
    if human then
        local guid = human:get_guid()
        local doc = { type = 1, guid = guid, award_name = awards_name, award_list = awards_list, status = 0, unix_time = os.time(), data_time = utils.get_day_time()}
        skynet.send(".char_db", "lua", "insert", { collection = "can_get_awards", doc = doc})
    end
end

function script_base:ChangeRestoreSceneAndPos(selfId, scene_id, x, z)
    local human = self:get_scene():get_obj_by_id(selfId)
    human:change_restore_scene_and_pos(scene_id, { x = x, y = z})
end


function script_base:ReSetEequipQuality(selfId, bagIndex, quality)
    local human = self:get_scene():get_obj_by_id(selfId)
    local prop_bag_container = human:get_prop_bag_container()
    local equip = prop_bag_container:get_item(bagIndex)
    if equip:is_equip() then
        local equip_data = equip:get_equip_data()
        equip_data:set_quality(quality)
    end
end

function script_base:BitIsTrue(value, bit_pos)
	return ((0x1 << (bit_pos - 1) & value) ~= 0)
end

function script_base:MarkBitTrue(value, bit_pos)
	return (value | 0x1 << (bit_pos - 1))
end

function script_base:MarkBitFalse(value, bit_pos)
    return (value & ~(0x1 << (bit_pos - 1)))
end

function script_base:LuaFnAddPointRemain(selfId, count)
    assert(count > 0)
    local human = self:get_scene():get_obj_by_id(selfId)
    local point_remain = human:get_lv1_point_remain()
    point_remain = point_remain + count
    human:set_lv1_point_remain(point_remain)
end

function script_base:LuaFnEquipAddAttr(selfId, BagPos, attr, val)
    local human = self:get_scene():get_obj_by_id(selfId)
    local prop_bag_container = human:get_prop_bag_container()
    local item = prop_bag_container:get_item(BagPos)
    if not item:is_equip() then
        return -1
    end
    local attr_count = item:get_equip_data():get_attr_count()
    if attr_count > 0x10 then
        return -2
    end
    item:get_equip_data():add_attr(attr, val)
    self:LuaFnRefreshItemInfo(selfId, BagPos)
    return 0
end

function script_base:LuaFnChangeEquipItemIndex(selfId, BagPos, item)
    local human = self:get_scene():get_obj_by_id(selfId)
    local prop_bag_container = human:get_prop_bag_container()
    local item = prop_bag_container:get_item(BagPos)
    if not item:is_equip() then
        return -1
    end
    local config = configenginer:get_config("equip_base")[item]
    if config == nil then
        return -2
    end
    item:set_index(item)
    self:LuaFnRefreshItemInfo(selfId, BagPos)
    return 0
end

function script_base:LuaFnGetServerID(selfId)
    local human = self:get_scene():get_obj_by_id(selfId)
	assert(human,"script_base:LuaFnGetServerID 对象缺失")
    return human:get_server_id()
end

--数组工具集
function script_base:MathCilCompute_1_Out(nData)
	local nFinalData = 0
	for i = 1,8 do
		nFinalData = nFinalData + nData[i] * 10 ^ (i - 1)
	end
	return nFinalData
end

function script_base:MathCilCompute_1_In(nData)
	local nTab = {}
	for i = 1,8 do
		nTab[i] = math.floor(nData/10 ^ (i - 1)) % 10
	end
	return nTab
end

--
function script_base:MathCilCompute_1_InEx(nData)
	local nTab = {}
	for i = 1,10 do
		nTab[i] = math.floor(nData/10 ^ (i - 1)) % 10
	end
	return nTab
end

function script_base:MathCilCompute_1_OutEx(nData)
	local nFinalData = 0
	for i = 1,10 do
		nFinalData = nFinalData + nData[i] * 10 ^ (i - 1)
	end
	return nFinalData
end
--
function script_base:MathCilCompute_4_Out(nData)
	local nFinalData = 0
	for i = 1,4 do
		nFinalData = nFinalData + nData[i] * 10 ^ (2 * (i - 1))
	end
	return nFinalData
end

function script_base:MathCilCompute_4_In(nData)
	local nTab = {}
	for i = 1,4 do
		nTab[i] = math.floor(nData/10 ^ (2 * (i - 1))) % 100
	end
	return nTab
end
--online ceshi!!!!!
-- function script_base:PlayerIsOnline(guid)
	-- return self.guid2agent[guid]
-- end
function script_base:SetDebugLog(...)
	local value = {...}
	if #value > 1 then
		local doc_x = {
			delflag = 1,
			debugid = value[1],
			date_time = os.date("%y-%m-%d %H:%M:%S")
		}
		for i = 2,#value do
			doc_x["info"..i] = value[i]
		end
		local collection_x = "log_debug"
		skynet.send(".logdb", "lua", "insert", { collection = collection_x, doc = doc_x})
	end
end
function script_base:DelDebugLog(index,delflag)
	local selector_x = {}
	if index == 1 then
		selector_x["delflag"] = delflag
	elseif index == 2 then
		selector_x["debugid"] = delflag
	end
    local collection_x = "log_debug"
  skynet.send(".logdb", "lua", "delete", { collection = collection_x, selector = selector_x})
end
function script_base:LuaFnIsActivityMonster(selfId,targetId,msgflag)
	if not selfId or not targetId then
		return false
	end
    local sceneId = self.scene:get_id()
    local scene_attr = configenginer:get_config("scene_attr")
	local scenename = scene_attr[sceneId].name
	local obj = self.scene:get_obj_by_id(targetId)
	if not obj then
		skynet.logi("not obj targetId = ",targetId,
		"scenename = ",scenename,
		"sceneId = ",sceneId)
		return false
	end
	local objtype = obj:get_obj_type()
	if objtype ~= "monster" then
		skynet.logi("objtype = ",objtype,
		"targetId = ",targetId,
		"scenename = ",scenename,
		"sceneId = ",sceneId)
		self:LuaFnDeleteMonster(targetId)
		return false
	end
	if self:LuaFnGetNpcIntParameter(targetId,1) ~= sceneId then
		local objname = obj:get_name()
		skynet.logi("非活动创建npc = ",objname,
		"targetId = ",targetId,
		"scenename = ",scenename,
		"sceneId = ",sceneId)
		-- self:LuaFnDeleteMonster(targetId)
		if msgflag then
			self:notify_tips(selfId, "非活动创建")
		end
		return false
	end
	local actId = self:LuaFnGetNpcIntParameter(targetId,2)
	if not actId or actId < 1 then
		local objname = obj:get_name()
		skynet.logi("非活动创建npc = ",objname,
		"targetId = ",targetId,
		"scenename = ",scenename,
		"sceneId = ",sceneId)
		-- self:LuaFnDeleteMonster(targetId)
		if msgflag then
			self:notify_tips(selfId, "非活动创建")
		end
		return false
	end
	actId = actId - 1
    local activity = self.scene.running_activitys[actId]
    if activity == nil then
        return false
    end
   if activity.tick_time < activity.on_time then
		return true
	end
	if msgflag then
		local objname = obj:get_name()
		skynet.logi("活动已结束,非活动创建npc = ",objname,
		"targetId = ",targetId,
		"scenename = ",scenename,
		"sceneId = ",sceneId)
		-- self:LuaFnDeleteMonster(targetId)
		self:notify_tips(selfId, "活动已结束")
	end
    -- if not self:CheckActiviyValidity(actId) then
        -- self:LuaFnDeleteMonster(targetId)
		-- self:notify_tips(selfId, "活动已结束")
        -- return false
    -- end
	return false
end

function script_base:LuaFnGetIsActivityID(actId)
	if not actId or actId < 0 or actId > 1000 then
		return false
	end
	local activity_notice = configenginer:get_config("activity_notice")
	local istrue = activity_notice[actId]
	if not istrue then
		return false
	end
	local sceneId = self.scene:get_id()
	if istrue.sceneid == sceneId then
		return true
	else
		if istrue.ruler >= 0 then
			local activity_ruler = configenginer:get_config("activity_ruler")
			istrue = activity_ruler[actId]
			if istrue then
				for i,j in ipairs(istrue.sceneids) do
					if j == sceneId then
						return true
					end
				end
			end
		end
	end
	return false
end
function script_base:SetCsLog(actname,params)
	local doc_x = {
		actname = actname,
		params = params,
		date_time = os.date("%y-%m-%d %H:%M:%S")
	}
    local collection_x = "log_debug"
    skynet.send(".logdb", "lua", "insert", { collection = collection_x, doc = doc_x})
end
function script_base:SetLog(selfId,actname,info1,info2,info3)
	local human = self:get_scene():get_obj_by_id(selfId)
	local guid = human:get_guid()
	local name = human:get_name()
	local obj = self.scene.objs[selfId]
	local level = obj:get_attrib("level")
	--local _,accountname = skynet.call(".gamed", "lua", "query_roler_account", string.format("%x", guid))
	local accountname = "暂不获取"
	local doc_x = {
		gm_name = name,
		gm_guid = guid,
		gm_level = level,
		gm_account = accountname,
		actname = actname,
		info1 = info1,
		info2 = info2,
		info3 = info3,
		date_time = os.date("%y-%m-%d %H:%M:%S")
	}
    local collection_x = "log_newhuodong"
    skynet.send(".logdb", "lua", "insert", { collection = collection_x, doc = doc_x})
end
function script_base:SetGmToolLog(selfId,selectname,object,isok)
	local human = self:get_scene():get_obj_by_id(selfId)
	local guid = human:get_guid()
	local name = human:get_name()
	local obj = self.scene.objs[selfId]
	local level = obj:get_attrib("level")
	local _,accountname = skynet.call(".gamed", "lua", "query_roler_account", string.format("%x", guid))
	local doc_x = {
		gm_name = name,
		gm_guid = guid,
		gm_level = level,
		gm_account = accountname,
		selectname = selectname,
		object = object,
		isok = isok,
		date_time = os.date("%y-%m-%d %H:%M:%S")
	}
    local collection_x = "log_gmtool"
    skynet.send(".logdb", "lua", "insert", { collection = collection_x, doc = doc_x})
end
function script_base:DelGmToolLog(gm_account)
	local selector_x = {gm_account = gm_account}
    local collection_x = "log_gmtool"
  skynet.send(".logdb", "lua", "delete", { collection = collection_x, selector = selector_x})
end

function script_base:ReSetEequipQuality(selfId, bagIndex, quality)
    local human = self:get_scene():get_obj_by_id(selfId)
    local prop_bag_container = human:get_prop_bag_container()
    local equip = prop_bag_container:get_item(bagIndex)
    if equip:is_equip() then
        local equip_data = equip:get_equip_data()
        equip_data:set_quality(quality)
    end
end

function script_base:BitIsTrue(value, bit_pos)
	return ((0x1 << (bit_pos - 1) & value) ~= 0)
end

function script_base:MarkBitTrue(value, bit_pos)
	return (value | 0x1 << (bit_pos - 1))
end

function script_base:LuaFnAddPointRemain(selfId, count)
    assert(count > 0)
    local human = self:get_scene():get_obj_by_id(selfId)
    local point_remain = human:get_lv1_point_remain()
    point_remain = point_remain + count
    human:set_lv1_point_remain(point_remain)
end

function script_base:LuaFnEquipAddAttr(selfId, BagPos, attr, val)
    local human = self:get_scene():get_obj_by_id(selfId)
    local prop_bag_container = human:get_prop_bag_container()
    local item = prop_bag_container:get_item(BagPos)
    if not item:is_equip() then
        return -1
    end
    local attr_count = item:get_equip_data():get_attr_count()
    if attr_count > 0x10 then
        return -2
    end
    item:get_equip_data():add_attr(attr, val)
    self:LuaFnRefreshItemInfo(selfId, BagPos)
    return 0
end

function script_base:LuaFnChangeEquipItemIndex(selfId, BagPos, item)
    local human = self:get_scene():get_obj_by_id(selfId)
    local prop_bag_container = human:get_prop_bag_container()
    local item = prop_bag_container:get_item(BagPos)
    if not item:is_equip() then
        return -1
    end
    local config = configenginer:get_config("equip_base")[item]
    if config == nil then
        return -2
    end
    item:set_index(item)
    self:LuaFnRefreshItemInfo(selfId, BagPos)
    return 0
end

-- function script_base:LuaFnGetServerID(selfId)
    -- local human = self:get_scene():get_obj_by_id(selfId)
    -- return human:get_server_id()
-- end
function script_base:LuaFnCheckRefreshEquipID_Attr(selfId,BagPos,Newid)
    local human = self:get_scene():get_obj_by_id(selfId)
	if not human then
		return 1
	end
    local bag_container = human:get_prop_bag_container()
    local equip = bag_container:get_item(BagPos)
    if not equip then
        return 2
    end
    local equip_base = configenginer:get_config("equip_base")
	local base = equip_base[equip:get_index()]
	if not base then
		return 3
	end
	local basenew = equip_base[Newid]
	if not basenew then
		return 4
	elseif base.equip_point ~= basenew.equip_point then
		return 5
	end
	return 0
end
function script_base:LuaFnRefreshEquipID_Attr(selfId,BagPos,Newid,n_flag)
    local human = self:get_scene():get_obj_by_id(selfId)
	if not human then
		return 1
	end
    local bag_container = human:get_prop_bag_container()
    local equip = bag_container:get_item(BagPos)
    if not equip then
        return 2
    end
    local equip_base = configenginer:get_config("equip_base")
	local base = equip_base[equip:get_index()]
	if not base then
		return 3
	end
	local basenew = equip_base[Newid]
	if not basenew then
		return 4
	elseif base.equip_point ~= basenew.equip_point then
		return 5
	end
	local params,attr_types,values
	if n_flag == 1 then
		params,attr_types,values = item_operator:gen_equip_attrs_special_weapon(Newid,1)
	else
		params,attr_types,values = item_operator:gen_equip_attrs(Newid,1)
	end
    -- local attr_type, attr_types, values = item_operator:refresh_equip_attr(equip,true)
    -- if not attr_type then
        -- return 6
    -- end
	equip:set_is_bind(true)
	equip:set_index(Newid)
	equip:get_equip_data():set_attr_count(#values)
	equip:get_equip_data():set_attr_value(values)
	equip:get_equip_data():set_attr_type(params.attr_type)
	equip:get_equip_data():set_attr_types(attr_types)
    equip:get_equip_data():set_quality(params.quality)
	equip:get_equip_data():set_max_dur(params.max_dur)
	equip:get_equip_data():set_visual(params.visual)
	equip:set_rule(params.rule)
	equip = bag_container:get_item(BagPos)
	local msg = packet_def.GCItemInfo.new()
	msg.bagIndex = BagPos
	msg.unknow_1 = equip and 0 or 1
	msg.item = equip and equip:copy_raw_data() or item_cls.new():copy_raw_data()
	self.scene:send2client(selfId, msg)
	return 0
end
function script_base:LuaFnRefreshEquipAttr_SpecialWeapon(selfId, BagPos)
    local human = self:get_scene():get_obj_by_id(selfId)
    local bag_container = human:get_prop_bag_container()
    local equip = bag_container:get_item(BagPos)
	equip:set_is_bind(true)
	local eqid = equip:get_index()
	local params,attr_types,values = item_operator:gen_equip_attrs_special_weapon(eqid,1)
    local equip_attrs = { attr_type = params.attr_type, attr_types = attr_types, attr_values = values }
    human:set_temp_equip_attrs(equip:get_guid(), equip_attrs)
    local msg = packet_def.GCRefreshEquipAttr.new()
    msg.type = 2
    msg.attr_count = #attr_types
    msg.attr_type = params.attr_type
    msg.attr_values = values
    msg.item_index = eqid
    human:get_scene():send2client(human, msg)
    return true
end


function script_base:LuaFnGetEquipArtisanal(selfId,BagPos)
    local human = self:get_scene():get_obj_by_id(selfId)
	assert(human,"LuaFnGetEquipArtisanal::对象缺失。")
    local bag_container = human:get_prop_bag_container()
    local item = bag_container:get_item(BagPos)
	if not item then return end
	return item:get_item_record_data_forindex("artisanal")
end

function script_base:LuaFnRefreshEquipArtisanal(selfId,BagPos,Menpai)
    local human = self:get_scene():get_obj_by_id(selfId)
	assert(human,"LuaFnRefreshEquipArtisanal::对象缺失。")
    local bag_container = human:get_prop_bag_container()
    local equip = bag_container:get_item(BagPos)
    if not equip then
        return 1
    end
	local create_mp = equip:get_item_record_data_forindex("artisanal")
	if create_mp then
		return 2
	end
    local equip_base = configenginer:get_config("equip_base")
	local eqid = equip:get_index()
	local base = equip_base[eqid]
	if not base then
		return 5
	end
	local creator = equip:get_item_creator()
	if not creator or creator == "" then
		return 3
	end
	local backid = 4
    local prescription_list = configenginer:get_config("item_compound")
	for _,info in pairs(prescription_list) do
		if info.ResultID == eqid then
			backid = 0
			break
		end
	end
	if backid == 0 then
		equip:set_item_record_data_forindex("artisanal",Menpai or 9)
	end
	return backid
end

function script_base:LuaFnGetEquipReshuffleCount(selfId,BagPos)
    local human = self:get_scene():get_obj_by_id(selfId)
	assert(human,"LuaFnGetEquipArtisanal::对象缺失。")
    local bag_container = human:get_prop_bag_container()
    local equip = bag_container:get_item(BagPos)
	if not equip then return end
	return equip:get_equip_data():get_reshuffle_count()
end

function script_base:LuaFnRefreshEquipAttr(selfId, BagPos,add_count,isreset)
    local human = self:get_scene():get_obj_by_id(selfId)
    local bag_container = human:get_prop_bag_container()
    local equip = bag_container:get_item(BagPos)
    local attr_type, attr_types, values = item_operator:refresh_equip_attr(equip,isreset)
    if not attr_type then
        return false
    end
    local equip_attrs = { attr_type = attr_type, attr_types = attr_types, attr_values = values }
    human:set_temp_equip_attrs(equip:get_guid(), equip_attrs)
	if add_count then
		local equip_data = equip:get_equip_data()
		local reshuffle_count = equip_data:get_reshuffle_count() + 1
		if reshuffle_count > 255 then
			reshuffle_count = 255
		end
		equip_data:set_reshuffle_count(reshuffle_count)
		self:LuaFnRefreshItemInfo(selfId, BagPos)
	end
    local msg = packet_def.GCRefreshEquipAttr.new()
    msg.type = 2
    msg.attr_count = #attr_types
    msg.attr_type = attr_type
    msg.attr_values = values
    msg.item_index = equip:get_index()
    human:get_scene():send2client(human, msg)
    return true
end

function script_base:LuaFnFinishRefreshEquipAttr(selfId, BagPos, replace)
    local human = self:get_scene():get_obj_by_id(selfId)
    local bag_container = human:get_prop_bag_container()
    local equip = bag_container:get_item(BagPos)
    local temp_equip_attrs = human:get_temp_equip_attrs()
	if not temp_equip_attrs then
		human:notify_tips("替换重洗属性失败，重洗属性已被取消。")
		return
	end
    human:clear_temp_equip_attrs()
    if equip:get_guid() ~= temp_equip_attrs.item_guid then
		human:notify_tips("替换重洗属性失败，重洗的装备不符。")
        return
    end
    local equip_attrs = temp_equip_attrs.equip_attrs
    local attr_type = equip_attrs.attr_type
    local attr_types = equip_attrs.attr_types
    local attr_values = equip_attrs.attr_values
    if replace then
        equip:get_equip_data():set_attr_type(attr_type)
        equip:get_equip_data():set_attr_types(attr_types)
        equip:get_equip_data():set_attr_value(attr_values)
        equip:get_equip_data():set_attr_count(#attr_values)
        self:LuaFnRefreshItemInfo(selfId, BagPos)
    end
    local msg = packet_def.GCRefreshEquipAttr.new()
    msg.type = 1
    msg.attr_count = #attr_types
    msg.attr_type = attr_type
    msg.attr_values = attr_values
    msg.item_index = equip:get_index()
    human:get_scene():send2client(human, msg)
end

function script_base:JoinMengHui(selfId, menghui)
    local human = self:get_scene():get_obj_by_id(selfId)
    human:set_meng_hui(menghui)
end

function script_base:LuaFnGetIsActivityID(actId)
	if not actId or actId < 0 or actId > 1000 then
		return false
	end
	local activity_notice = configenginer:get_config("activity_notice")
	local istrue = activity_notice[actId]
	if not istrue then
		return false
	end
	local sceneId = self.scene:get_id()
	if istrue.sceneid == sceneId then
		return true
	else
		if istrue.ruler >= 0 then
			local activity_ruler = configenginer:get_config("activity_ruler")
			istrue = activity_ruler[actId]
			if istrue then
				for i,j in ipairs(istrue.sceneids) do
					if j == sceneId then
						return true
					end
				end
			end
		end
	end
	return false
end

function script_base:LuaFnIsItemExists(itemId)
	local equip_base = configenginer:get_config("equip_base")
	if equip_base[itemId] then
		return 1
	end
	local common_item = configenginer:get_config("common_item")
	if common_item[itemId] then
		return 2
	end
	local gem_info = configenginer:get_config("gem_info")
	if gem_info[itemId] then
		return 3
	end
	return 0
end

function script_base:WGCRetQueryQingRenJieTopList(selfId)
    local msg = packet_def.WGCRetQueryQingRenJieTopList.new()
	for i = 1,20 do
		msg.rank_list_1[i] = {
			count = 0,
			guid = 0,
			guild_name = " ",
			name = " ",
			unknow_1 = 0,
			unknow_2 = -1,
			unknow_3 = -1
		}
		msg.rank_list_2[i] = {
			count = 0,
			guid = 0,
			guild_name = " ",
			name = " ",
			unknow_1 = 0,
			unknow_2 = -1,
			unknow_3 = -1
		}
	end
    msg.unknow_1 = 270213680
    msg.unknow_2 = 0
    msg.unknow_3 = 16
    msg.unknow_4 = 0
    msg.unknow_5 = 1
    self:get_scene():send2client(selfId, msg)
end


function script_base:LuaFnActivityBoxCheck(sceneId,selfId,scenetime,curtime)
	local exida,exidb
	local human = self.scene:get_obj_by_id(selfId)
	if human then
		local lsexa,lsexb
		local exdata
		for i = 551,570,2 do
			if human:get_mission_data_ex_by_script_id(i) == sceneId then
				if scenetime == human:get_mission_data_ex_by_script_id(i + 1) then
					human:notify_tips("该传送你已使用过，不可重复操作。")
					self:BeginUICommand()
					self:DispatchUICommand(selfId,410142021)
					return
				end
				exida = i
				exidb = i + 1
				break
			elseif human:get_mission_data_ex_by_script_id(i + 1) < curtime then
				lsexa,lsexb = i,i + 1
			end
		end
		if not exida or not exidb then
			if lsexa and lsexb then
				exida,exidb = lsexa,lsexb
			else
				human:notify_tips("暂没有传送位置可用，请稍后再尝试。")
				return
			end
		end
		return exida,exidb
	end
end
function script_base:LuaFnGetWorldGlobalDataEx(wid)
	local haveid = skynet.call(".db", "lua", "findOne", {collection = "world_value_ex",query = {wid = wid}})
	if haveid then
		return haveid.value
	end
	return 0
end
function script_base:LuaFnSetWorldGlobalDataEx(wid,value)
	skynet.send(".db", "lua", "update",{collection = "world_value_ex",selector = {wid = wid},update = {["$set"] = {value = value}},upsert = true,multi = false})
end
function script_base:LuaFnGetPlayerAccount(guid)
	local query_tbl = {char_list = {["$elemMatch"] = {["$eq"] = guid}}}
    local response = skynet.call(".char_db", "lua", "findOne", {collection = "account",query = query_tbl, selector = {uid = 1}})
	if response then
		return response.uid
	end
end
function script_base:LuaFnGetPlayerIsOnline(guid)
    local response = skynet.call(".char_db", "lua", "findOne", { collection = "character", query = {["attrib.guid"] = guid} })
	if response then
		return response.is_online
	end
end

--【docname】
--".db" = world 库
--".char_db" = tlbb 库

--【doclist】
--"money_card"
-- addData = {
			-- docindex = "moneycard",
			-- createtimer = "",
			-- cardguid = "",
			-- playerguid = 0,
			-- playername = "",
			-- awardtimer = "",
			-- awardtimer_two = "",
			-- awardinfo = {...},awardinfo = "尚未激活"
-- }

function script_base:LuaFnSetAddDocData(docname,doclist,addData)
  skynet.send(docname, "lua", "insert", { collection = doclist, doc = addData})
end
function script_base:LuaFnGetDocData(docname,doclist,docindex,findname,findflag,findvalue,backflag)
	local query_x = {docindex = docindex}
	if findflag and findvalue then
		query_x[findflag] = findvalue
	end
	local backdata
	if backflag then
		backdata = skynet.call(docname, "lua", findname, {collection = doclist,query = query_x,selector = backflag})
	else
		backdata = skynet.call(docname, "lua", findname, {collection = doclist,query = query_x})
	end
	return backdata
end
function script_base:LuaFnUpdateDocData(docname,doclist,docindex,updatedata,updateflag,updatevalue)
	local selector_x = {docindex = docindex}
	if updateflag and updatevalue then
		selector_x[updateflag] = updatevalue
	end
	
	local update_x = {
		["$set"] = updatedata
	}
	skynet.send(docname, "lua", "update", { collection = doclist, selector = selector_x,update = update_x,upsert = false,multi = false})
end
function script_base:LuaFnDelDocData(docname,doclist,docindex,delflag,delvalue)
	local selector_x = {docindex = docindex}
	if delflag and delvalue then
		selector_x[delflag] = delvalue
	end
	skynet.send(docname, "lua", "delete", {collection = doclist, selector = selector_x})
end
function script_base:LuaFnDelDocDataEx(docname,doclist,docindex,delflag,delvalue)
	local selector_x = {docindex = docindex}
	if delflag and delvalue then
		selector_x[delflag] = delvalue
	end
	skynet.call(docname, "lua", "delete", {collection = doclist, selector = selector_x})
	local data = skynet.call(docname, "lua", "findOne", {collection = doclist,query = selector_x})
	if not data then
		return  true
	end
	return false
end


-- addData = {
			-- actname = "yexihu_boss",
			-- opentime = 0,
			-- closetime = self.LongTime,
			-- topid = 0,
			-- topvalue = 0,
			-- playerguid = 0,
			-- playername = scenename,
			-- leaguename = "战场配置在warini",
			-- warini = {...},
-- }
function script_base:SetActivityWar(addData)
  skynet.send(".db", "lua", "insert", { collection = "activity_war_rec", doc = addData})
end
function script_base:GetActivityWar(actname,findflag,findvalue,findname,backflag)
	local query_x = {actname = actname}
	if findflag and findvalue then
		query_x[findflag] = findvalue
	end
	local backdata
	if backflag then
		backdata = skynet.call(".db", "lua", findname, {collection = "activity_war_rec",query = query_x,selector = backflag})
	else
		backdata = skynet.call(".db", "lua", findname, {collection = "activity_war_rec",query = query_x})
	end
	return backdata
end
function script_base:UpdateActivityWar(actname,updateflag,updatevalue,updatedata)
	local selector_x = {actname = actname}
	if updateflag and updatevalue then
		selector_x[updateflag] = updatevalue
	end
	
	local update_x = {
		["$set"] = updatedata
	}
	skynet.send(".db", "lua", "update", { collection = "activity_war_rec", selector = selector_x,update = update_x,upsert = false,multi = false})
end
function script_base:DelActivityWar(actname,delflag,delvalue)
	local selector_x = {actname = actname}
	if delflag and delvalue then
		selector_x[delflag] = delvalue
	end
	skynet.send(".db", "lua", "delete", {collection = "activity_war_rec", selector = selector_x})
end


function script_base:LuaFnGetSubTime(nyear,nmonth,day,nhour,nmin)
	local cuttime = os.time()
	local overtime = os.time{  
		year = nyear,  
		month = nmonth,  
		day = day,  
		hour = nhour,  
		min = nmin,
		sec = 0
	}
	local subtime = overtime - cuttime
	local backtimeinfo = "已结束"
	if subtime > 0 then
		local dayx = math.floor(subtime / 86400)
		subtime = subtime - dayx * 86400
		local hourx = math.floor(subtime / 3600)
		subtime = subtime - hourx * 3600
		local minx = math.floor(subtime / 60)
		subtime = math.floor(subtime - minx * 60)
		if dayx > 0 then
			backtimeinfo = string.format("剩余时间:%d天%02d时%02d分%02d秒",dayx,hourx,minx,subtime)
		elseif hourx > 0 then
			backtimeinfo = string.format("剩余时间:%02d时%02d分%02d秒",hourx,minx,subtime)
		elseif minx > 0 then
			backtimeinfo = string.format("剩余时间:%02d分%02d秒",minx,subtime)
		else
			backtimeinfo = string.format("剩余时间:%02d秒",subtime)
		end
	end
    return backtimeinfo
end
function script_base:CheckUseFlowerCD(selfId,targetId)
	local selfobj = self.scene.objs[selfId]
	local tarobj = self.scene.objs[targetId]
    assert(tarobj,"script_base:UpdateHuaBang selfobj 对象缺失。")
    assert(selfobj,"script_base:UpdateHuaBang tarobj 对象缺失。")
	local curtime = os.time()
	local havecd = self:GetMissionDataEx(selfId,ScriptGlobal.MDEX_USE_TOP_ITEM_CD)
	if curtime < havecd then
		self:notify_tips(selfId,"#{QXHB_20210701_163}")
		return
	end
	havecd = self:GetMissionDataEx(targetId,ScriptGlobal.MDEX_USE_TOP_ITEM_CD)
	if curtime < havecd then
		self:notify_tips(selfId,"目标收花过于频繁，请稍后再尝试。")
		return
	end	
	self:SetMissionDataEx(selfId,ScriptGlobal.MDEX_USE_TOP_ITEM_CD,curtime + 1)
	self:SetMissionDataEx(targetId,ScriptGlobal.MDEX_USE_TOP_ITEM_CD,curtime + 1)
	return true
end
function script_base:CheckTopOpenUiCD(selfId,addtime)
	local curtime = os.time()
	local havecd = self:GetMissionDataEx(selfId,ScriptGlobal.MDEX_TOP_CD)
	if curtime < havecd then
		self:notify_tips(selfId,"#{QXHB_20210701_163}")
		return
	end
	self:SetMissionDataEx(selfId,ScriptGlobal.MDEX_TOP_CD,curtime + addtime)
	return true
end
function script_base:CheckTopPreviewCD(selfId,addtime)
	local curtime = os.time()
	local havecd = self:GetMissionDataEx(selfId,ScriptGlobal.MDEX_TOP_PREVIEW_CD)
	if curtime < havecd then
		self:notify_tips(selfId,"#{QXHB_20210701_163}")
		return
	end
	self:SetMissionDataEx(selfId,ScriptGlobal.MDEX_TOP_PREVIEW_CD,curtime + addtime)
	return true
end
function script_base:CheckTopClaimAwardCD(selfId,addtime)
	local curtime = os.time()
	local havecd = self:GetMissionDataEx(selfId,ScriptGlobal.MDEX_CLAIM_AWARD_CD)
	if curtime < havecd then
		self:notify_tips(selfId,"#{QXHB_20210701_163}")
		return
	end
	self:SetMissionDataEx(selfId,ScriptGlobal.MDEX_CLAIM_AWARD_CD,curtime + addtime)
	return true
end
function script_base:GetCurrentServerEnvironment()
	local env = skynet.getenv("env")
	return env
end

function script_base:LuaFnFixLimitShop(selfId,shopid,key,value)
	local scene = self:get_scene()
	local sceneId = scene:get_id()
	if define.IS_KUAFU_SCENE[sceneId] then
		self:notify_tips(selfId,"跨服不可操作。")
		return -3
	end
	local world_id = self:LuaFnGetServerID(selfId)
	return skynet.call(define.CACHE_NODE,"lua","fix_limit_shops",world_id,shopid,key,value)
end

function script_base:LuaFnGetActivity()
	local scene = self:get_scene()
	local sceneId = scene:get_id()
	local world_id = 0
	if not define.IS_KUAFU_SCENE[sceneId] then
		world_id = scene:get_world_id()
	end
	return skynet.call(define.CACHE_NODE,"lua","get_activity",world_id)
end
function script_base:LuaFnGetActivityEx(actId)
	local scene = self:get_scene()
	local sceneId = scene:get_id()
	local world_id = 0
	if not define.IS_KUAFU_SCENE[sceneId] then
		world_id = scene:get_world_id()
	end
	return skynet.call(define.CACHE_NODE,"lua","get_activity_ex",world_id,actId)
end
function script_base:GetActivityForAct(actId)
	local scene = self:get_scene()
	local sceneId = scene:get_id()
	local world_id = 0
	if not define.IS_KUAFU_SCENE[sceneId] then
		world_id = scene:get_world_id()
	end
	return skynet.call(define.CACHE_NODE,"lua","get_activity_for_act",world_id,actId)
end
function script_base:GetActivityForScene()
	local scene = self:get_scene()
	local sceneId = scene:get_id()
	local world_id = 0
	if not define.IS_KUAFU_SCENE[sceneId] then
		world_id = scene:get_world_id()
	end
	return skynet.call(define.CACHE_NODE,"lua","get_activity_for_scene",world_id,sceneId)
end
function script_base:GetActivityKey(actId,key,tar_sceneId)
	local scene = self:get_scene()
	local sceneId = scene:get_id()
	if tar_sceneId then
		sceneId = tar_sceneId
	end
	local world_id = 0
	if not define.IS_KUAFU_SCENE[sceneId] then
		world_id = scene:get_world_id()
	end
	return skynet.call(define.CACHE_NODE,"lua","get_activity_key",world_id,sceneId,actId,key)
end
function script_base:SetActivityKey(actId,key,value)
	local scene = self:get_scene()
	local sceneId = scene:get_id()
	local world_id = 0
	if not define.IS_KUAFU_SCENE[sceneId] then
		world_id = scene:get_world_id()
	end
	return skynet.send(define.CACHE_NODE,"lua","set_activity_key",world_id,sceneId,actId,key,value)
end
function script_base:HaveHuaBangAward(world_id,migration,guid)
	local scene = self:get_scene()
	local sceneId = scene:get_id()
	if define.IS_KUAFU_SCENE[sceneId] then
		return 0
	end
	return skynet.call(define.CACHE_NODE,"lua","have_huabang_award",world_id,migration,guid)
end
function script_base:ClaimHuaBangAward(world_id,migration,top,guid)
	local scene = self:get_scene()
	local sceneId = scene:get_id()
	if define.IS_KUAFU_SCENE[sceneId] then
		return
	end
	return skynet.call(define.CACHE_NODE,"lua","claim_huabang_award",world_id,migration,top,guid)
end
function script_base:GetHuaBangData(world_id,migration,migration_2)
	local scene = self:get_scene()
	local sceneId = scene:get_id()
	if define.IS_KUAFU_SCENE[sceneId] then
		return {},{}
	end
	return skynet.call(define.CACHE_NODE,"lua","get_huabang_migration_data",world_id,migration,migration_2)
end
function script_base:HuaBangCheck(selfId,all_migration)
	local scene = self:get_scene()
	local sceneId = scene:get_id()
	if define.IS_KUAFU_SCENE[sceneId] then
		return -1
	end
	local world_id = self:LuaFnGetServerID(selfId)
	return skynet.call(define.CACHE_NODE,"lua","get_huabang_rank_state",world_id,all_migration)
end
function script_base:UpdateHuaBang(selfId,targetId,nCount,mdid,mdvalue)
	local selfobj = self.scene.objs[selfId]
	local tarobj = self.scene.objs[targetId]
    assert(tarobj,"script_base:UpdateHuaBang selfobj 对象缺失。")
    assert(selfobj,"script_base:UpdateHuaBang tarobj 对象缺失。")
	local migration,overdate,uiflag,_,endtime = self:HuaBangCheck(selfId)
	if migration >= 1 and migration <= 3 then
		local have_top = false
		local today = tonumber(os.date("%Y%m%d"))
		if today < overdate then
			have_top = true
		elseif today == overdate then
			local times = os.date("*t")
			local nowtime = times.hour * 60 + times.min
			if nowtime < endtime then
				have_top = true
			end
		end
		
		if have_top then
			local song_md = 615 + migration
			local shou_md = 618 + migration
			local newdate = overdate % 10000 * 10000 + endtime
			local self_song,self_shou = 0,0
			local addmdcount = 0
			if self:GetMissionData(selfId,ScriptGlobal.MD_QIXITIME) ~= newdate then
				self_song = nCount
				addmdcount = mdvalue
				self:SetMissionData(selfId,ScriptGlobal.MD_QIXITIME,newdate)
			else
				self_song = self:GetMissionData(selfId,song_md) + nCount
				self_shou = self:GetMissionData(selfId,shou_md)
				addmdcount = self:GetMissionData(selfId,mdid) + mdvalue
			end
			self:SetMissionData(selfId,song_md,self_song)
			self:SetMissionData(selfId,shou_md,self_shou)
			self:SetMissionData(selfId,mdid,addmdcount)
			if selfId ~= targetId then
				local tar_song,tar_shou = 0,0
				if self:GetMissionData(targetId,ScriptGlobal.MD_QIXITIME) ~= newdate then
					tar_shou = nCount
					self:SetMissionData(targetId,ScriptGlobal.MD_QIXITIME,newdate)
				else
					tar_song = self:GetMissionData(targetId,song_md)
					tar_shou = self:GetMissionData(targetId,shou_md) + nCount
				end
				self:SetMissionData(targetId,song_md,tar_song)
				self:SetMissionData(targetId,shou_md,tar_shou)
				if nCount > 0 then
					local targuid = tarobj:get_guid()
					local tarname = tarobj:get_name()
					local selfguid = selfobj:get_guid()
					local selfname = selfobj:get_name()
					local world_id = self:LuaFnGetServerID(selfId)
					local curhb_shou,curhb_song = skynet.call(define.CACHE_NODE,"lua","update_flower_top",self_song,selfguid,selfname,tar_shou,targuid,tarname,world_id)
					local nyear = overdate // 10000
					overdate = overdate % 10000
					local nmonth = overdate // 100
					overdate = overdate % 100
					local nhour = endtime // 60
					local nminue = endtime - nhour * 60
					local subtime = self:LuaFnGetSubTime(nyear,nmonth,overdate,nhour,nminue)
					local uiid
					if uiflag == 2 then
						uiflag = 4
						uiid = 89139602
					else
						uiflag = 3
						uiid = 89297404
					end
					self:BeginUICommand()
					self:UICommand_AddInt(migration)
					self:UICommand_AddInt(self_song)--nSendNum
					self:UICommand_AddInt(self_shou) --nReceiveNum
					self:UICommand_AddStr(subtime)
					self:EndUICommand()
					self:DispatchUICommand(selfId,uiid)
					self:BeginUICommand()
					self:UICommand_AddInt(migration)
					self:UICommand_AddInt(tar_song)--nSendNum
					self:UICommand_AddInt(tar_shou) --nReceiveNum
					self:UICommand_AddStr(subtime)
					self:EndUICommand()
					self:DispatchUICommand(targetId,uiid)
					if #curhb_shou > 0 and #curhb_song > 0 then
						local datax,dataz = {},{}
						local topinfo_shou,topinfo_song
						for i = 1,20 do
							topinfo_song = curhb_song[i]
							if topinfo_song then
								datax[i] = {
								count = topinfo_song.flower,
								guid = topinfo_song.charguid,
								guild_name = topinfo_song.guildname,
								name = topinfo_song.charname,
								unknow_1 = 0,
								unknow_2 = -1,
								unknow_3 = -1
								}
							else
								datax[i] = {
								count = 0,
								guid = 0,
								guild_name = " ",
								name = " ",
								unknow_1 = 0,
								unknow_2 = -1,
								unknow_3 = -1
								}
							end
							topinfo_shou = curhb_shou[i]
							if topinfo_shou then
								dataz[i] = {
								count = topinfo_shou.flower,
								guid = topinfo_shou.charguid,
								guild_name = topinfo_shou.guildname,
								name = topinfo_shou.charname,
								unknow_1 = 0,
								unknow_2 = -1,
								unknow_3 = -1
								}
							else
								dataz[i] = {
								count = 0,
								guid = 0,
								guild_name = " ",
								name = " ",
								unknow_1 = 0,
								unknow_2 = -1,
								unknow_3 = -1
								}
							end
						end
						
						local scene = self:get_scene()
						local msg = packet_def.WGCRetQueryQingRenJieTopList.new()
						msg.rank_list_1 = dataz
						msg.rank_list_2 = datax
						msg.unknow_1 = 270213680
						msg.unknow_2 = 0
						msg.unknow_3 = 16
						msg.unknow_4 = 0
						msg.unknow_5 = uiflag
						scene:send2client(selfId, msg)
						
						local msg = packet_def.WGCRetQueryQingRenJieTopList.new()
						msg.rank_list_1 = dataz
						msg.rank_list_2 = datax
						msg.unknow_1 = 270213680
						msg.unknow_2 = 0
						msg.unknow_3 = 16
						msg.unknow_4 = 0
						msg.unknow_5 = uiflag
						scene:send2client(targetId, msg)
					end
				end
			end
		end
	end
end

function script_base:ResetHuaBang(selfId,overdate,endtime,uiflag,is_new)
	local scene = self:get_scene()
	local sceneId = scene:get_id()
	if define.IS_KUAFU_SCENE[sceneId] then
		self:notify_tips(selfId,"跨服不可操作花榜。")
		return -3
	end
	local world_id = self:LuaFnGetServerID(selfId)
	return skynet.call(define.CACHE_NODE,"lua","start_huabang",world_id,overdate,endtime,uiflag,is_new)
end
function script_base:CloseHuaBangEx(selfId)
	local scene = self:get_scene()
	local sceneId = scene:get_id()
	if define.IS_KUAFU_SCENE[sceneId] then
		self:notify_tips(selfId,"跨服不可操作花榜。")
		return
	end
	local world_id = self:LuaFnGetServerID(selfId)
	return skynet.call(define.CACHE_NODE,"lua","close_huabang",world_id)
end
function script_base:GetClientIconDisplay(selfId)
	local human = self.scene.objs[selfId]
    assert(human,"script_base:UpdateHuaBang selfobj 对象缺失。")
	local scene = self:get_scene()
	local sceneId = scene:get_id()
	local world_id = human:get_server_id()
	local guid = human:get_guid()
	return skynet.call(define.CACHE_NODE,"lua","get_celient_icon_display",sceneId,selfId,guid,world_id)
end

function script_base:StartJingPai(world_id,open_params)
	local scene = self:get_scene()
	local sceneId = scene:get_id()
	if define.IS_KUAFU_SCENE[sceneId] then
		return
	end
	return skynet.call(define.CACHE_NODE,"lua","start_jingpai",world_id,open_params)
end

function script_base:CloseJingPaiEx(world_id)
	local scene = self:get_scene()
	local sceneId = scene:get_id()
	if define.IS_KUAFU_SCENE[sceneId] then
		return
	end
	return skynet.call(define.CACHE_NODE,"lua","close_jingpai",world_id)
end
function script_base:JingPaiCheck(world_id)
	local scene = self:get_scene()
	local sceneId = scene:get_id()
	if define.IS_KUAFU_SCENE[sceneId] then
		return -1
	end
	return skynet.call(define.CACHE_NODE,"lua","get_jingpai_state",world_id)
end
function script_base:GetJingPaiData(selfId,migration)
	if migration == 0 then
		return {}
	end
	local scene = self:get_scene()
	local sceneId = scene:get_id()
	if define.IS_KUAFU_SCENE[sceneId] then
		return {}
	end
	local world_id = self:LuaFnGetServerID(selfId)
	return skynet.call(define.CACHE_NODE,"lua","get_jingpai_migration_data",world_id,migration)
end
function script_base:HaveJingPaiAward(world_id,migration,index,guid,haveyb)
	local scene = self:get_scene()
	local sceneId = scene:get_id()
	if define.IS_KUAFU_SCENE[sceneId] then
		return 0
	end
	return skynet.call(define.CACHE_NODE,"lua","have_jingpai_award",world_id,migration,index,guid,haveyb)
end
function script_base:ClaimJingPaiAward(world_id,migration,index,guid)
	local scene = self:get_scene()
	local sceneId = scene:get_id()
	if define.IS_KUAFU_SCENE[sceneId] then
		return 0
	end
	return skynet.call(define.CACHE_NODE,"lua","claim_jingpai_award",world_id,migration,index,guid)
end
function script_base:TakeBackBidYuanBao(world_id,guid,haveyb)
	-- local scene = self:get_scene()
	-- local sceneId = scene:get_id()
	-- if define.IS_KUAFU_SCENE[sceneId] then
		-- return -1
	-- end
	return skynet.call(define.CACHE_NODE,"lua","jingpai_take_back_bid_yuanbao",world_id,guid,haveyb)
end
function script_base:GetJingPaiSpecialItem(world_id)
	local scene = self:get_scene()
	local sceneId = scene:get_id()
	if define.IS_KUAFU_SCENE[sceneId] then
		return 0
	end
	return skynet.call(define.CACHE_NODE,"lua","get_jingpai_special_item",world_id)
end
function script_base:GetJingPaiItemConfig(world_id,index)
	local scene = self:get_scene()
	local sceneId = scene:get_id()
	if define.IS_KUAFU_SCENE[sceneId] then
		return 0
	end
	return skynet.call(define.CACHE_NODE,"lua","get_jingpai_item_config",world_id,index)
end
function script_base:SubmitJingPaiBid(world_id,index,prize,guid,name,end_time)
	local scene = self:get_scene()
	local sceneId = scene:get_id()
	if define.IS_KUAFU_SCENE[sceneId] then
		return
	end
	return skynet.call(define.CACHE_NODE,"lua","submit_jingpai_bid",world_id,index,prize,guid,name,end_time)
end
function script_base:GetDateToTime(params)
	local back_time = {}
	local year,month,day,hour,min,sec,value,timer
	local cur_time = os.time()
	local times = os.date("*t")
	for i,j in ipairs(params) do
		value = j.date
		if value then
			year = value // 10000
			value = value % 10000
			month = value // 100
			day = value % 100
		else
			year = times.year
			month = times.month
			day = times.day
		end
		if j.minute_time then
			hour = j.minute_time // 60
			min = j.minute_time - hour * 60
		else
			hour = j.hour or times.hour
			min = j.min or times.min
		end
		sec = j.sec or 0
		timer = os.time({year = year, month = month, day = day, hour = hour, min = min, sec = sec})
		if j.add_time then
			timer = timer + j.add_time
		end
		timer = timer - cur_time
		local n_day,n_hour,n_sec = 0,0,0
		if timer > 0 then 
			n_day = timer // 86400
			timer = timer % 86400
			n_hour = timer // 3600
			n_sec = timer % 3600
		end
		back_time[i] = {year = year,month = month,day = day,hour = hour,min = min,n_day = n_day,n_hour = n_hour,n_sec = n_sec}
	end
	return back_time,times.year,times.month,times.day
end		

function script_base:ResetMingDong(selfId,...)
	local scene = self:get_scene()
	local sceneId = scene:get_id()
	if define.IS_KUAFU_SCENE[sceneId] then
		self:notify_tips(selfId,"跨服不可操作名动。")
		return -3
	end
	local world_id = self:LuaFnGetServerID(selfId)
	return skynet.call(define.CACHE_NODE,"lua","start_mingdong",world_id,...)
end
function script_base:MingDongClose(selfId)
	local scene = self:get_scene()
	local sceneId = scene:get_id()
	if define.IS_KUAFU_SCENE[sceneId] then
		self:notify_tips(selfId,"跨服不可操作名动。")
		return
	end
	local world_id = self:LuaFnGetServerID(selfId)
	return skynet.call(define.CACHE_NODE,"lua","close_mingdong",world_id)
end

function script_base:SetMingDongCondition(selfId,need_yb,need_point)
	local scene = self:get_scene()
	local sceneId = scene:get_id()
	if define.IS_KUAFU_SCENE[sceneId] then
		self:notify_tips(selfId,"跨服不可操作名动。")
		return
	end
	local world_id = self:LuaFnGetServerID(selfId)
	return skynet.call(define.CACHE_NODE,"lua","set_mingdong_condition",world_id,need_yb,need_point)
end

function script_base:UpdateMingDongTop(selfId,yuanbao,point)
	local human = self:get_scene():get_obj_by_id(selfId)
	assert(human,"script_base:UpdateMingDongTop 对象缺失。")
	local scene = self:get_scene()
	local sceneId = scene:get_id()
	if define.IS_KUAFU_SCENE[sceneId] then
		self:notify_tips(selfId,"跨服不可操作名动。")
		return
	end
	local params = {
		guid = human:get_guid(),
		name = human:get_name(),
		menpai = human:get_menpai(),
		money_yb = yuanbao or 0,
		money_yb_old = human:get_game_flag_key("mingdong_yb"),
		need_point = point or 0,
		need_point_old = human:get_game_flag_key("mingdong_point"),
		over_date = human:get_game_flag_key("mingdong_date"),
		end_time = human:get_game_flag_key("mingdong_time"),
	}
	local world_id = human:get_server_id()
	local loading,money_yb,need_point,over_date,end_time = skynet.call(define.CACHE_NODE,"lua","update_mingdong_top",world_id,params)
	if loading == 1 then
		human:set_game_flag_key("mingdong_yb",money_yb)
		human:set_game_flag_key("mingdong_point",need_point)
		if over_date then
			human:set_game_flag_key("mingdong_date",over_date)
		end
		if end_time then
			human:set_game_flag_key("mingdong_time",end_time)
		end
	end
end
function script_base:SetMingDongLimitPlayer(selfId,guid,name,is_add)
	local scene = self:get_scene()
	local sceneId = scene:get_id()
	if define.IS_KUAFU_SCENE[sceneId] then
		self:notify_tips(selfId,"跨服不可操作名动。")
		return
	end
	local world_id = self:LuaFnGetServerID(selfId)
	return skynet.call(define.CACHE_NODE,"lua","set_mingdong_top_limit",world_id,guid,name,is_add)
end

function script_base:GetMingDongTop(selfId)
	local scene = self:get_scene()
	local sceneId = scene:get_id()
	if define.IS_KUAFU_SCENE[sceneId] then
		self:notify_tips(selfId,"跨服不可操作名动。")
		return {}
	end
	local world_id = self:LuaFnGetServerID(selfId)
	return skynet.call(define.CACHE_NODE,"lua","get_mingdong_top",world_id)
end

function script_base:GetPlayerMingDongPoint(selfId)
	local human = self:get_scene():get_obj_by_id(selfId)
	assert(human,"script_base:UpdateMingDongTop 对象缺失。")
	return human:get_game_flag_key("mingdong_yb"),human:get_game_flag_key("mingdong_point")
end
function script_base:CheckMingdongTopClaimAward(selfId)
	local scene = self:get_scene()
	local sceneId = scene:get_id()
	if define.IS_KUAFU_SCENE[sceneId] then
		self:notify_tips(selfId,"跨服不可操作名动。")
		return 0,0
	end
	local world_id = self:LuaFnGetServerID(selfId)
	local guid = self:LuaFnGetGUID(selfId)
	return skynet.call(define.CACHE_NODE,"lua","check_mingdong_top_claim_award",world_id,guid)
end
function script_base:MingdongTopClaimAward(selfId,topid)
	local scene = self:get_scene()
	local sceneId = scene:get_id()
	if define.IS_KUAFU_SCENE[sceneId] then
		self:notify_tips(selfId,"跨服不可操作名动。")
		return -1
	end
	local world_id = self:LuaFnGetServerID(selfId)
	local guid = self:LuaFnGetGUID(selfId)
	return skynet.call(define.CACHE_NODE,"lua","mingdong_top_claim_award",world_id,topid,guid)
end

function script_base:LuaFnIsActivityMonster(selfId,targetId,msgflag)
	if not selfId or not targetId then
		return false
	end
    local sceneId = self.scene:get_id()
    local scene_attr = configenginer:get_config("scene_attr")
	local scenename = scene_attr[sceneId].name
	local obj = self.scene:get_obj_by_id(targetId)
	if not obj then
		skynet.logi("not obj targetId = ",targetId,
		"scenename = ",scenename,
		"sceneId = ",sceneId)
		return false
	end
	local objtype = obj:get_obj_type()
	if objtype ~= "monster" then
		skynet.logi("objtype = ",objtype,
		"targetId = ",targetId,
		"scenename = ",scenename,
		"sceneId = ",sceneId)
		self:LuaFnDeleteMonster(targetId)
		return false
	end
	if self:LuaFnGetNpcIntParameter(targetId,1) ~= sceneId then
		local objname = obj:get_name()
		skynet.logi("非活动创建npc = ",objname,
		"targetId = ",targetId,
		"scenename = ",scenename,
		"sceneId = ",sceneId)
		-- self:LuaFnDeleteMonster(targetId)
		if msgflag then
			self:notify_tips(selfId, "非活动创建")
		end
		return false
	end
	local actId = self:LuaFnGetNpcIntParameter(targetId,2)
	if not actId or actId < 1 then
		local objname = obj:get_name()
		skynet.logi("非活动创建npc = ",objname,
		"targetId = ",targetId,
		"scenename = ",scenename,
		"sceneId = ",sceneId)
		-- self:LuaFnDeleteMonster(targetId)
		if msgflag then
			self:notify_tips(selfId, "非活动创建")
		end
		return false
	end
	actId = actId - 1
    local activity = self.scene.running_activitys[actId]
    if activity == nil then
        return false
    end
   if activity.tick_time < activity.on_time then
		return true
	end
	if msgflag then
		local objname = obj:get_name()
		skynet.logi("活动已结束,非活动创建npc = ",objname,
		"targetId = ",targetId,
		"scenename = ",scenename,
		"sceneId = ",sceneId)
		-- self:LuaFnDeleteMonster(targetId)
		self:notify_tips(selfId, "活动已结束")
	end
    -- if not self:CheckActiviyValidity(actId) then
        -- self:LuaFnDeleteMonster(targetId)
		-- self:notify_tips(selfId, "活动已结束")
        -- return false
    -- end
	return false
end

function script_base:LuaFnGetObjParam(selfId,index)
	local obj = self:get_scene():get_obj_by_id(selfId)
	assert(obj,"script_base:LuaFnGetObjParam 缺失对象")
	if obj:get_obj_type() == "monster" then
		return obj:get_scene_params(index)
	end
end

function script_base:LuaFnSetObjParam(selfId,index,value)
	local obj = self:get_scene():get_obj_by_id(selfId)
	assert(obj,"script_base:LuaFnSetObjParam 缺失对象")
	if obj:get_obj_type() == "monster" then
		return obj:set_scene_params(index,value)
	end
end

function script_base:LuaFnGetExteriorHeadByID(selfId,id)
	local human = self:get_scene():get_obj_by_id(selfId)
	assert(human,"script_base:LuaFnGetExteriorHeadByID 缺失对象")
	return human:get_exterior_head_by_id(id)
end
function script_base:LuaFnGetExteriorBackByID(selfId,id)
	local human = self:get_scene():get_obj_by_id(selfId)
	assert(human,"script_base:LuaFnGetExteriorBackByID 缺失对象")
	return human:get_exterior_back_by_id(id)
end
function script_base:LuaFnGetExteriorHeadPos(selfId,id,posx,posy,posz)
	if not id or not posx or not posy or not posz then
		return
	end
	local human = self:get_scene():get_obj_by_id(selfId)
	assert(human,"script_base:LuaFnGetExteriorHeadPos 缺失对象")
	local exterior_ts = configenginer:get_config("exterior_ts")
	if not exterior_ts[id] then
		return
	end
	if posx < exterior_ts[id].minx or posx > exterior_ts[id].maxx then
		return
	elseif posy < exterior_ts[id].miny or posy > exterior_ts[id].maxy then
		return
	elseif posz < exterior_ts[id].minz or posz > exterior_ts[id].maxz then
		return
	end
	return human:set_exterior_head_pos(id,posx,posy,posz)
end
function script_base:LuaFnGetExteriorBackPos(selfId,id,posx,posy,posz)
	if not id or not posx or not posy or not posz then
		return
	end
	local human = self:get_scene():get_obj_by_id(selfId)
	assert(human,"script_base:LuaFnGetExteriorBackByID 缺失对象")
	local exterior_bg = configenginer:get_config("exterior_bg")
	if not exterior_bg[id] then
		return
	end
	if posx < exterior_bg[id].minx or posx > exterior_bg[id].maxx then
		return
	elseif posy < exterior_bg[id].miny or posy > exterior_bg[id].maxy then
		return
	elseif posz < exterior_bg[id].minz or posz > exterior_bg[id].maxz then
		return
	end
	return human:set_exterior_back_pos(id,posx,posy,posz)
end
function script_base:ScriptGlobal_Format(index,...)
	if not index then
		return "缺少字典索引"
	end
	index = string.sub(index,1,-2)
	local msg = string.contact_args(index,...)
	msg = msg.."}"
	return msg
end

function script_base:MaterialNotEnoughTip(selfId,itemid,count)
	local human = self:get_scene():get_obj_by_id(selfId)
	assert(human,"script_base:GiveItemTip 缺失对象")
	local itemname = self:GetItemName(itemid)
	local msg = string.format("您的%s不足%d个，无法进行后续操作。",itemname,count)
	human:notify_tips(msg)
end

function script_base:GiveItemTip(selfId,itemid,count,effectId)
	local human = self:get_scene():get_obj_by_id(selfId)
	assert(human,"script_base:GiveItemTip 缺失对象")
	local itemname = self:GetItemName(itemid)
	local msg = string.contact_args("#{OBCS_200916_04",count,itemname).."}"
	human:notify_tips(msg)
	if effectId then
		local scene = self:get_scene()
		local logic_count = human:get_logic_count()
		human:show_buff_effect(selfId,selfId,-1,logic_count,effectId)
	end
end

function script_base:BuyItemTip(selfId,itemid,count,effectId)
	local human = self:get_scene():get_obj_by_id(selfId)
	assert(human,"script_base:GiveItemTip 缺失对象")
	local itemname = self:GetItemName(itemid)
	local msg = string.contact_args("#{SDHDRW_220808_08",count,itemname).."}"
	human:notify_tips(msg)
	if effectId then
		local scene = self:get_scene()
		local logic_count = human:get_logic_count()
		human:show_buff_effect(selfId,selfId,-1,logic_count,effectId)
	end
end


function script_base:ActivateExteriorHeadID(selfId,bagpos,itemid)
	local human = self:get_scene():get_obj_by_id(selfId)
	assert(human,"script_base:ActivateExteriorHeadID 缺失对象")
	local exterior_ts = configenginer:get_config("exterior_ts")
	local add
	local id,x,y,z,state,tip
    local nTempList = {
        --[物品ID] = {实际发饰ID物品,过期时间}
        [38003345] = {38003383,24}, -- 护耳绒帽
        [38003558] = {38003567,24}, -- 烁影浮光3天
        [38003559] = {38003567,24}, -- 烁影浮光7天
        [38003560] = {38003567,24}, -- 烁影浮光15天
        [38003561] = {38003567,24}, -- 烁影浮光30天
        [38003562] = {38003567,24}, -- 烁影浮光45天
        [38003566] = {38003567,24}, -- 烁影浮光5天
        [38003659] = {38003657,24}, -- 兰若幽帘30天
        [38003711] = {38003696,24}, -- 五载同行30天
        [38003729] = {38003723,24}  -- 熊赳赳15天
    }
    local nNewItemID = itemid
    if nTempList[itemid] then
        nNewItemID = nTempList[itemid][1]
    end


	for i,j in ipairs(exterior_ts) do
		if j.itemid == nNewItemID then
			add = {
				id = j.id,
				x = j.defx,
				y = j.defy,
				z = j.defz,
				state = 4,
				tip = 0,
				ntime = -1
			}
			break
		end
	end
	if add then
		if self:LuaFnGetExteriorHeadByID(selfId,id) then
			self:notify_tips(selfId,"该发饰已激活。")
			return
		end
		self:LuaFnDecItemLayCount(selfId, bagpos, 1)
		return human:set_exterior_head_id(add)
	end
	self:notify_tips(selfId,"发饰不存在。")
end
function script_base:ActivateExteriorBackID(selfId,bagpos,itemid)
	local human = self:get_scene():get_obj_by_id(selfId)
	assert(human,"script_base:ActivateExteriorBackID 缺失对象")
	local exterior_bg = configenginer:get_config("exterior_bg")
	local add
	local nTempList = {
		[38003270] = 38003260,
		[38003564] = 38003563,
		[38003565] = 38003563,
		[38003695] = 38003563,
		[38003583] = 38003574,
		[38003584] = 38003575,
		[38003658] = 38003656,
		[38003887] = 38003886,
		[38003888] = 38003886,
	}
	local nNewItemID = itemid
	if nTempList[itemid] then
		nNewItemID = nTempList[itemid]
	end
	for _,j in pairs(exterior_bg) do
		if j.itemid == nNewItemID then
			add = {
				id = j.id,
				x = j.defx,
				y = j.defy,
				z = j.defz,
				state = 4,
				tip = 0,
				ntime = -1
			}
			break
		end
	end
	if add then
		if self:LuaFnGetExteriorBackByID(selfId,add.id) then
			self:notify_tips(selfId,"背饰已激活。")
			return
		end
		self:LuaFnDecItemLayCount(selfId, bagpos, 1)
		return human:set_exterior_back_id(add)
	end
	self:notify_tips(selfId,"背饰不存在。")
end


function script_base:GetDwJinJieParamEx(selfId,pos,maxnum)
    local human = self:get_scene():get_obj_by_id(selfId)
	if not human then
		return 1
	end
	local container = human:get_prop_bag_container()
	local item = container:get_item(pos)
	if not item then
		return 2
	end
	local record_data = item:get_item_record_data()
	if not record_data then
		return 3
	end
	local backcount = 0
	if not record_data.count or record_data.count ~= maxnum then
		local dw_jinjie_zx_gif_box = configenginer:get_config("dw_jinjie_zx_gif_box")
		local zx_gif_box = table.clone(dw_jinjie_zx_gif_box)
		if maxnum > #zx_gif_box then
			return 4
		end
		record_data = {count = maxnum}
		for i = 1,maxnum do
			local index = math.random(1,#zx_gif_box)
			local removeinfo = table.remove(zx_gif_box,index)
			index = tostring(i)
			record_data[index] = removeinfo.id
		end
		item:set_is_bind(true)
		item:set_item_record_data(record_data)
	end
	return record_data
end

function script_base:GetDwJinJieZxBoxInfo(selfId)
	if selfId then
		local human = self:get_scene():get_obj_by_id(selfId)
		assert(human,"script_base:GetDwJinJieZxBoxInfo 缺失对象")
		if not human:get_mission_have_done(2269) then
			human:set_mission_have_done(2269,true)
		end
	else
		local dw_jinjie_zx_gif_box = configenginer:get_config("dw_jinjie_zx_gif_box")
		return table.clone(dw_jinjie_zx_gif_box)
	end
end

function script_base:GetDwJinJieZxBoxItem(selfId,id)
	local dw_jinjie_zx_gif_box = configenginer:get_config("dw_jinjie_zx_gif_box")
	for _,j in ipairs(dw_jinjie_zx_gif_box) do
		if j.id == id then
			return j.itemid
		end
	end
end

function script_base:SetGameLog(collection,doc)
	collection = collection or "log_error_setgamelog"
	doc = doc or {}
	skynet.send(".logdb", "lua", "insert", { collection = collection, doc = doc})
end

function script_base:SetAutoReviveOrEscape(value)
	self:get_scene():set_auto_revive_or_escape(value)
end

function script_base:SetSceneExpRate(value)
	self:get_scene():set_scene_exp_rate(value)
end

function script_base:SetReStoreHpCD(selfId,ntime,nrate)
    local human = self:get_scene():get_obj_by_id(selfId)
	assert(human,"script_base:GetItemParamEx 缺失对象")
	if not ntime or not nrate then
		return
	end
	human:set_restore_hp_reset_time(ntime,nrate)
end

function script_base:GetItemParamEx(selfId,pos,index,isequip)
    local human = self:get_scene():get_obj_by_id(selfId)
	assert(human,"script_base:GetItemParamEx 缺失对象")
	local container
	if isequip then
		container = human:get_equip_container()
	else
		container = human:get_prop_bag_container()
	end
	local item = container:get_item(pos)
	assert(item,"script_base:GetItemParamEx 道具为空")
	return item:get_item_record_data_forindex(index)
end

function script_base:SetItemParamEx(selfId,pos,index,value,isequip)
    local human = self:get_scene():get_obj_by_id(selfId)
	assert(human,"script_base:SetItemParamEx 缺失对象")
	local container
	if isequip then
		container = human:get_equip_container()
	else
		container = human:get_prop_bag_container()
	end
	local item = container:get_item(pos)
	assert(item,"script_base:SetItemParamEx 道具为空")
	item:set_item_record_data_forindex(index,value)
	return true
end

function script_base:ShowObjSkillMissed(selfId,targetid,skill_id,flag)
	local scene = self:get_scene()
    local obj = scene:get_obj_by_id(selfId)
	assert(obj,"script_base:ShowSkillMissed 缺失对象")
	local logic_count = 0
	if obj:get_obj_type() == "human" then
		logic_count = obj:get_logic_count()
	end
	obj:show_skill_missed(selfId,targetid,skill_id,logic_count,flag)
	-- local msg = packet_def.GCCharSkill_Missed.new()
	-- msg.reciver = targetid
	-- msg.sender = selfId
	-- msg.flag = flag
	-- msg.skill_id = -1
	-- -- msg.sender_logic_count = obj:get_logic_count()
	-- msg.sender_logic_count = 0
	-- scene:broadcast(obj, msg, true)
end

function script_base:ShowObjBuffEffect(selfId,targetid,skill_id,impact_id)
	local scene = self:get_scene()
    local obj = scene:get_obj_by_id(selfId)
	assert(obj,"script_base:ShowObjBuffEffect 缺失对象")
	local logic_count = 0
	if obj:get_obj_type() == "human" then
		logic_count = obj:get_logic_count()
	end
	obj:show_buff_effect(selfId,targetid,skill_id,logic_count,impact_id)
	
	
	
	-- local msg = packet_def.GCCharDirectImpact.new()
	-- msg.reciver = targetid
	-- msg.sender = selfId
	-- msg.skill_id = -1
	-- msg.impact_id = impact_id
	-- -- msg.logic_count = obj:get_logic_count()
	-- msg.logic_count = define.INVAILD_ID
	-- scene:broadcast(obj, msg, true)
end

function script_base:CheckEquipTL(selfId,item_index)
    local obj = self.scene:get_obj_by_id(selfId)
    assert(obj, selfId)
    local equip_base = configenginer:get_config("equip_base")
	equip_base = equip_base[item_index]
	if not equip_base then
		obj:notify_tips("装备不存在。")
		return
	elseif equip_base["品质规则"] > 9 then
		obj:notify_tips("此类装备不可操作。")
		return
	end
	local equip_point = equip_base.equip_point
	if equip_point == define.HUMAN_EQUIP.HEQUIP_RIDER
	or equip_point == define.HUMAN_EQUIP.HEQUIP_UNKNOW1
	or equip_point == define.HUMAN_EQUIP.HEQUIP_UNKNOW2
	or equip_point >= define.HUMAN_EQUIP.HEQUIP_FASHION then
		obj:notify_tips("此类型装备不可操作。")
		return
	end
	return true
end

function script_base:GetEquipQHD(selfId,BagPos)
    local obj = self.scene:get_obj_by_id(selfId)
    assert(obj, selfId)
	if not BagPos or BagPos < 0 then
		obj:notify_tips("位置异常。")
		return define.INVAILD_ID
	end
    local item = obj:get_prop_bag_container():get_item(BagPos)
	if not item then
		obj:notify_tips("没有装备。")
		return define.INVAILD_ID
	end
	if not item:is_equip() then
		obj:notify_tips("不是装备。")
		return define.INVAILD_ID
	end
	return item:get_index(),item:get_equip_data():get_qihedu()
end

function script_base:SetEquipQHD(selfId,BagPos,qhd,add_qhd)
    local obj = self.scene:get_obj_by_id(selfId)
    assert(obj, selfId)
	if not BagPos or BagPos < 0 then
		obj:notify_tips("位置异常。")
		return define.INVAILD_ID
	end
    local item = obj:get_prop_bag_container():get_item(BagPos)
	if not item then
		obj:notify_tips("没有装备。")
		return define.INVAILD_ID
	end
	if not item:is_equip() then
		obj:notify_tips("不是装备。")
		return define.INVAILD_ID
	end
	item:set_is_bind(true)
	item:get_equip_data():set_qihedu(qhd)
	item.status = item.status | define.ITEM_EXT_INFO.IEL_CREATOR
	item_operator:gen_equip_qh_attrs(item,add_qhd)
	local msg = packet_def.GCItemInfo.new()
	msg.bagIndex = BagPos
	msg.item = item:copy_raw_data()
	self.scene:send2client(obj, msg)
end

function script_base:SetEquipJinJie(selfId,BagPos,qhd,add_qhd)
    local obj = self.scene:get_obj_by_id(selfId)
    assert(obj, selfId)
	if not BagPos or BagPos < 0 then
		obj:notify_tips("位置异常。")
		return define.INVAILD_ID
	end
    local item = obj:get_prop_bag_container():get_item(BagPos)
	if not item then
		obj:notify_tips("没有装备。")
		return define.INVAILD_ID
	end
	if not item:is_equip() then
		obj:notify_tips("不是装备。")
		return define.INVAILD_ID
	end
	item:set_is_bind(true)
	local equip_data = item:get_equip_data()
	equip_data:set_qihedu(qhd)
	local xx = equip_data:get_quality() + 1
	xx = xx > 9 and 9 or xx
	equip_data:set_quality(xx)
	item_operator:gen_equip_qh_attrs(item,add_qhd)
	local msg = packet_def.GCItemInfo.new()
	msg.bagIndex = BagPos
	msg.item = item:copy_raw_data()
	self.scene:send2client(obj, msg)
end

function script_base:EmptyEquipQHD(selfId,BagPos,qhd)
    local obj = self.scene:get_obj_by_id(selfId)
    assert(obj, selfId)
	if not BagPos or BagPos < 0 then
		obj:notify_tips("位置异常。")
		return
	end
    local item = obj:get_prop_bag_container():get_item(BagPos)
	if not item then
		obj:notify_tips("没有装备。")
		return
	end
	if not item:is_equip() then
		obj:notify_tips("不是装备。")
		return
	end
	if item_operator:qh_reset_equip_attrs(item) then
		item:set_is_bind(true)
		local equip_data = item:get_equip_data()
		equip_data:set_qihedu(0)
		local msg = packet_def.GCItemInfo.new()
		msg.bagIndex = BagPos
		msg.item = item:copy_raw_data()
		self.scene:send2client(obj, msg)
		return true
	end
end

function script_base:LuaFnRefreshEquipAttr_QH(selfId, BagPos)
    local human = self:get_scene():get_obj_by_id(selfId)
    local bag_container = human:get_prop_bag_container()
    local equip = bag_container:get_item(BagPos)
	equip:set_is_bind(true)
	local equip_data = equip:get_equip_data()
	local qhd = equip_data:get_qihedu()
	local quality = equip_data:get_quality()
	local item_index = equip:get_index()
    local attr_type, attr_types, values = item_operator:refresh_equip_attr_qh(item_index,quality,qhd)
    if not attr_type then
        return false
    end
    local equip_attrs = { attr_type = attr_type, attr_types = attr_types, attr_values = values }
    human:set_temp_equip_attrs(equip:get_guid(), equip_attrs)
    local msg = packet_def.GCRefreshEquipAttr.new()
    msg.type = 2
    msg.attr_count = #attr_types
    msg.attr_type = attr_type
    msg.attr_values = values
    msg.item_index = equip:get_index()
    human:get_scene():send2client(human, msg)
    return true
end

function script_base:GetHumanGameFlag(selfId,key)
    local human = self:get_scene():get_obj_by_id(selfId)
	assert(human,"GetHumanGameFlag 对象缺失。")
	return human:get_game_flag_key(key)
end

function script_base:SetHumanGameFlag(selfId,key,value)
    local human = self:get_scene():get_obj_by_id(selfId)
	assert(human,"SetHumanGameFlag 对象缺失。")
	human:set_game_flag_key(key,value)
end

function script_base:LuaFnCheckPetShelizi(selfId,PetGuidH,PetGuidL)
    local human = self.scene:get_obj_by_id(selfId)
	assert(human,"LuaFnCheckPetShelizi 对象缺失。")
    local container = human:get_pet_bag_container()
    local guid = pet_guid_cls.new()
    guid:set(PetGuidH, PetGuidL)
    local pet_detail = container:get_pet_by_guid(guid)
    local pet_type = self:GetPetTypeByDetail(pet_detail)
	if not pet_detail then
		return 0
	elseif human:get_current_pet_guid() == guid then
		return -1
    elseif pet_type ~= define.PET_TYPE.PET_TYPE_BABY and pet_type ~= define.PET_TYPE.PET_TYPE_VARIANCE then
        return -6
	elseif pet_detail:get_level() < 30 then
		return -2
	elseif not pet_detail:get_growth_rate_queryd() then
		return -3
	elseif pet_detail:have_huan_hua() then
		return -4
	elseif pet_detail:have_equip() then
		return -5
	end
	return 1
end

function script_base:LuaFnGetPetNeedExp(selfId,level)
    local pet_level_up_table = configenginer:get_config("pet_level_up_table")
	local value = pet_level_up_table[level] or 0
	return math.ceil(value)
end

function script_base:GetPetLevelAllExperience(selfId,level,max_exp,min_level)
	local all_exp = 0
    local pet_level_up_table = configenginer:get_config("pet_level_up_table")
	min_level = min_level or 1
	for i = min_level,level do
		all_exp = all_exp + (pet_level_up_table[i] or 0)
		if all_exp > max_exp then
			all_exp = max_exp
			break
		end
	end
	return math.ceil(all_exp)
end
function script_base:GetPetMaxLevelByExp(level,nexp)
    local pet_level_up_table = configenginer:get_config("pet_level_up_table")
	local need_exp
	for i = level,define.PET_LEVEL_NUM do
		need_exp = pet_level_up_table[i] or 0
		if nexp >= need_exp then
			nexp = nexp - need_exp
		else
			return i,nexp
		end
	end
end

-- Converted gameplay uses these legacy spellings.
require("script_legacy_compat").install(script_base)
return require('cys_social_city').install(script_base)
