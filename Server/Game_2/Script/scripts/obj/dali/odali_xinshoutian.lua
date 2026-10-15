local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local odali_xinshoutian = class("odali_xinshoutian", script_base)
odali_xinshoutian.script_id = 002030
--用新任务老任务取消
odali_xinshoutian.g_eventList = {
    210240,
    210200,
	210238,
    210258,
    210262,
    210263,
    210266,
    210275,
    210276,
    210277,
    210278,
    210267,
	210269,
	210279,
	210268,
    1018700,
}
local YuanXiaoRechage_NameList = {
}
local YuanXiao_Gift = {
    {
		money = 0,
		prize = {
            {itemid = 20501003,num = 10},
            {itemid = 20502003,num = 10},
            {itemid = 30505187,num = 1},
			{itemid = 30505294,num = 1},
			{itemid = 30900056,num = 3},
			{itemid = 38002494,num = 10},
			{itemid = 30008130,num = 5},
		}
	}
}


local AddRepairInfo = {


}


function odali_xinshoutian:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    local PlayerName = self:GetName(selfId)
    local PlayerSex = self:GetSex(selfId)
    local nLevel = self:GetLevel(selfId)
	--local md = ScriptGlobal.MDEX_GUANWANG_YUYUE_GET_AWARD
    if PlayerSex == 0 then
        PlayerSex = "Muội muội"
    else
        PlayerSex = "Huynh đệ"
    end
    local IsNew = self:GetMissionFlag(selfId, ScriptGlobal.MF_Dialog_01)
    if IsNew == 0 then
        self:AddText("  " .. PlayerName .. PlayerSex .. "#{OBJ_dali_0011}")
        self:SetMissionFlag(selfId, ScriptGlobal.MF_Dialog_01, 1)
    elseif IsNew == 1 then
        if self:GetLevel(selfId) >= 10 and self:GetMenPai(selfId) == ScriptGlobal.MP_WUMENPAI then
            self:AddText("  " .. PlayerName .. PlayerSex .. "#{OBJ_dali_0054}")
        else
            self:AddText("  " .. PlayerName .. PlayerSex .. "#{OBJ_dali_0012}")
        end
    end
	--if self:GetMissionDataEx(selfId,700) == 0 then
		--self:AddNumText("#G领取5W点数卡", 1,30001)
	--end
	--local myPoint = self:GetYuanXiaoExchange(selfId)
	--myPoint = math.floor(myPoint)
	--if myPoint >= 500 and self:GetMissionDataEx(selfId,152) == 0 then
	--	self:AddNumText("端午充值礼包", 6,40001)
	--end
    --self:AddNumText("兽魂回收", 6,12345)
    self:AddNumText("Nhận bù Phi Hoàng Thạch", 6,60000)
	--self:AddNumText("修复角色隐身", 6,90000)
	--if md == 0 then
    --self:AddNumText("#G首区大礼包", 1, 70000)
	--end
    --self:AddNumText("#G回馈玩家礼包", 6, 70002)
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function odali_xinshoutian:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function odali_xinshoutian:OnEventRequest(selfId, targetId, arg, index)
	if not index or index < 1 then
		self:UpdateEventList(selfId, targetId)
		return
	elseif index == 12345 then
		local delcount = 0
		for i,j in ipairs(AddRepairInfo) do
			local pos = self:LuaFnGetItemPosByItemDataID(selfId, j.petsoul)
			if pos and pos ~= -1 then
				delcount = delcount + 1
				self:EraseItem(selfId, pos)
				self:SetLog(selfId,"Thu hồi thú hồn","ID:"..tostring(j.petsoul),self:GetItemName(j.petsoul),"Thu hồi thành công")
			end
		end
		self:BeginEvent(self.script_id)
		if delcount == 0 then
			self:AddText("Túi không có thú hồn tương ứng.")
		else
			self:AddText("Thu hồi thành công.")
		end
		self:EndEvent()
		self:DispatchEventList(selfId,targetId)
		return
	end
    for i, findId in pairs(self.g_eventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId, arg, index)
            return
        end
    end 
	--免费礼包 记得配置里面数组
	--[[if index == 30001 then
		if self:GetMissionDataEx(selfId,700) > 0 then
			self:notify_tips(selfId,"你已经领取过补偿礼包了。")
			return
		end
		local AwardInfo = {
		--{38003158,10},
		--{20310174,20},
		{38008155,1},
		}
		local itemName
		self:BeginEvent(self.script_id)
		self:AddText("  恭喜您得到一个礼盒，请我们看看里面有什么吧！")
		for i,j in ipairs(AwardInfo) do
			itemName = self:GetItemName(j[1])
			self:AddText("#G"..itemName.."#W * #G"..tostring(j[2]))
		end
		self:AddNumText("还不赖,勉为其难收下了", 6,30002)
		self:AddNumText("稍后再来取走", 11,0)
		self:EndEvent()
		self:DispatchEventList(selfId, targetId)
		return
	elseif index == 30002 then
		if self:GetMissionDataEx(selfId,700) > 0 then
			self:notify_tips(selfId,"你已经领取过补偿礼包了。")
			return
		end
		local AwardInfo = {
		--{38003158,10},
		--{20310174,20},
		{38008155,1},
		}
        self:BeginAddItem()
		for i,j in ipairs(AwardInfo) do
			self:AddItem(j[1],j[2],true)
		end
		local ret = self:EndAddItem(selfId)
        if not ret then
			self:BeginAddItem()
            self:notify_tips(selfId,"背包空间不足")
            return 
        end
		self:SetMissionDataEx(selfId,700,1)
		self:AddItemListToHuman(selfId)
		self:BeginEvent(self.script_id)
		self:AddText("  好的，礼包已经发放给你咯！")
		self:AddNumText("我知道了", 11,0)
		self:EndEvent()
		self:DispatchEventList(selfId, targetId)
		return
    end--]]
	--500元礼包 记得配置里面数组
	if index == 40001 then

    end
    if index == 60000 then
        local nFlag = self:GetMissionDataEx(selfId,139)
        if nFlag > 0 then
            self:notify_tips(selfId,"Mỗi người chỉ nhận bù Phi Hoàng Thạch một lần.")
            return
        end
        self:BeginAddItem()
        self:AddItem(10155004, 1, true)
        local ret = self:EndAddItem(selfId)
        if not ret then
            self:notify_tips(selfId,"Xin đảm bảo ô đạo cụ túi có một chỗ trống.")
            return 
        end
        self:AddItemListToHuman(selfId)
        self:notify_tips(selfId,"Ngươi nhận 1 ám khí: Phi Hoàng Thạch, xem túi!")
        self:SetMissionDataEx(selfId,139,self:GetDayTime())
    end
    if index == 90000 then
        if  self:LuaFnHaveAgname(selfId, 1348) then
            self:LuaFnDelNewAgname(selfId, 1348)
            self:notify_tips(selfId,"Sửa thành công, xin đổi cảnh lại")

        end
    end
    local PlayerName = self:GetName(selfId)
    if index == 70000 then
        local YuanXiaoMoney = YuanXiaoRechage_NameList[PlayerName] or self:GetYuanXiaoExchange(selfId)
        --YuanXiaoMoney = YuanXiaoMoney >= 5000 and YuanXiaoMoney or 0
        self:ShowYuanXiaoGiftContent(selfId, YuanXiaoMoney, targetId)
		return
    end
    if index == 80001 then
        local YuanXiaoMoney = YuanXiaoRechage_NameList[PlayerName] or self:GetYuanXiaoExchange(selfId)
        self:GetwYuanXiaoGiftAward(selfId, YuanXiaoMoney, targetId)
        return
    end
    if index == 70001 then
        local YuanXiaoMoney = YuanXiaoRechage_NameList[PlayerName] or self:GetYuanXiaoExchange(selfId)
        --YuanXiaoMoney = YuanXiaoMoney >= 5000 and YuanXiaoMoney or 0
        self:GetwYuanXiaoGiftAward(selfId, YuanXiaoMoney, targetId)
		return
    end
    if index == 70002 then
        local YuanXiaoMoney = 0
        self:ShowYuanXiaoGiftContent(selfId, YuanXiaoMoney, targetId)
		return
    end
end

function odali_xinshoutian:GetYuanXiaoExchange(selfId)
    local guid = self:LuaFnGetGUID(selfId)
    local skynet = require "skynet"
    local pipeline = {}
    local query_tbl = {["guid"] = guid, ["time"] = {["$gte"] = 1718031600}}
	local step = {["$group"] = {_id = false, ["total"] = {["$sum"] = "$cost"}}}
    table.insert(pipeline, {["$match"] = query_tbl})
    table.insert(pipeline, step)
    local coll_name = "toppoint_cost"
    local result = skynet.call(".char_db", "lua", "runCommand", "aggregate",  coll_name, "pipeline", pipeline, "cursor", {},  "allowDiskUse", false)
    if result and result.ok == 1 then
        if result.cursor and result.cursor.firstBatch then
            local r = result.cursor.firstBatch[1]
            if r then
				return r["total"] // 200
            end
        end
    end
	return 0
end

function odali_xinshoutian:ShowYuanXiaoGiftContent(selfId, Money, targetId)
    local md = ScriptGlobal.MDEX_GUANWANG_YUYUE_GET_AWARD
    if Money < 500 then
        md = ScriptGlobal.MDEX_GUANWANG_YUYUE_GET_AWARD
    end
	local val = self:GetMissionDataEx(selfId, md)
	if val ~= 0 then
		self:BeginEvent(self.script_id)
		self:AddText("Thưởng lễ bao khu đầu đã nhận")
		self:EndEvent()
		self:DispatchEventList(selfId,targetId)
		return
	end
	local gift_config = self:GetYuanXiaoGiftContent(Money)
	if gift_config == nil then
		self:BeginEvent(self.script_id)
		self:AddText(string.format("Số nạp quà đặt trước trên web của bạn là %d tệ, không có quà để nhận", Money))
		self:EndEvent()
		self:DispatchEventList(selfId,targetId)
		return
	end
	local prize = gift_config.prize
	self:BeginEvent(self.script_id)
	local content = "Nội dung lễ bao khu đầu bạn nhận được:"
	self:AddText(content)
	for _, p in ipairs(prize) do
        if p.itemid then
            local item_name = self:GetItemName(p.itemid)
            if p.soul_level then
                self:AddText(item_name .. " " .. p.soul_level + 1 .. "Bậc X" .. p.num)
            else
                self:AddText(item_name .. "X" .. p.num)
            end
        end
	end
	self:AddText("Lễ bao khu đầu chỉ nhận được 1")
	self:AddNumText("Xác nhận lĩnh",6, 70001)
	self:EndEvent()
	self:DispatchEventList(selfId,targetId)
end

function odali_xinshoutian:GetwYuanXiaoGiftAward(selfId, Money, targetId)
    -- local md = ScriptGlobal.MDEX_GUANWANG_YUYUE_GET_AWARD
    -- if Money < 500 then
        -- md = ScriptGlobal.MDEX_GUANWANG_YUYUE_GET_AWARD
    -- end
	-- local val = self:GetMissionDataEx(selfId, md)
	-- if val ~= 0 then
		-- self:BeginEvent(self.script_id)
		-- self:AddText("首区礼包奖励已领取")
		-- self:EndEvent()
		-- self:DispatchEventList(selfId,targetId)
		-- return
	-- end
	-- local gift_config = self:GetYuanXiaoGiftContent(Money)
	-- if gift_config == nil then
		-- self:BeginEvent(self.script_id)
		-- self:AddText(string.format("您当前回馈礼包充值数额为%d元, 没有礼包可以领取", Money))
		-- self:EndEvent()
		-- self:DispatchEventList(selfId,targetId)
		-- return
	-- end
	-- local material_count = self:LuaFnGetMaterialBagSpace(selfId)
	-- local prop_count = self:LuaFnGetPropertyBagSpace(selfId)
	-- if prop_count < 4 then
		-- self:notify_tips( selfId, "道具栏请保证4格以上空间" )
		-- return
	-- end
	-- if material_count < 3 then
		-- self:notify_tips( selfId, "材料栏请保证3格以上空间" )
		-- return
	-- end
	-- self:SetMissionDataEx(selfId, md, 1)
	-- self:BeginAddItem()
	-- local pet_soul_level
	-- for i,item in pairs(gift_config.prize) do
        -- if item.title_id then
            -- if not self:LuaFnHaveAgname(selfId, item.title_id) then
                -- self:LuaFnAddNewAgname(selfId, item.title_id)
            -- end
        -- else
            -- self:AddItem(item.itemid, item.num, true)
            -- if item.soul_level then
                -- pet_soul_level = item.soul_level
            -- end
        -- end
	-- end
	-- if not self:EndAddItem(selfId) then
		-- self:NotifyTips( selfId, "背包空间不足" )
		-- return
	-- end
	-- self:AddItemListToHuman(selfId)
	-- if pet_soul_level then
		-- local BagPos = self:GetBagPosByItemSn(selfId, 70600015)
		-- self:SetPetSoulLevel(selfId, BagPos, pet_soul_level)
	-- end
	-- self:BeginEvent(self.script_id)
	-- self:AddText("首区推广礼包奖励领取成功")
	-- self:EndEvent()
	-- self:DispatchEventList(selfId,targetId)
end

function odali_xinshoutian:GetYuanXiaoGiftContent(nPreMoney)
	local gifts = {prize = {}}
	for i = #YuanXiao_Gift, 1, -1 do
		local gift = YuanXiao_Gift[i]
		if gift.money <= nPreMoney then
			for _, p in ipairs(gift.prize) do
				table.insert(gifts.prize, p)
			end
		end
	end
	if #gifts.prize == 0 then
		return
	end
	return gifts
end

function odali_xinshoutian:SetPetSoulLevel(selfId, BagPos, level)
	local human = self:get_scene():get_obj_by_id(selfId)
	local prop_bag_container = human:get_prop_bag_container()
	local item = prop_bag_container:get_item(BagPos)
	item:get_pet_equip_data():set_pet_soul_level(level)
	self:LuaFnRefreshItemInfo(selfId, BagPos)
end

function odali_xinshoutian:OnMissionAccept(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            local ret = self:CallScriptFunction(missionScriptId, "CheckAccept", selfId)
            if ret > 0 then
                self:CallScriptFunction(missionScriptId, "OnAccept", selfId)
            end
            return
        end
    end
end
function odali_xinshoutian:LuaFnDelNewAgname(selfId, del_id)
    local human = self:get_scene():get_obj_by_id(selfId)
    local id_titles = human.id_titles
	for i = #id_titles, 1, -1 do
		local title = id_titles[i]
		if title.id == del_id then
			table.remove(id_titles, i)
			break
		end
	end
    human:update_titles_to_client()
end
function odali_xinshoutian:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function odali_xinshoutian:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
            return
        end
    end
end

function odali_xinshoutian:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
            return
        end
    end
end

function odali_xinshoutian:OnDie(selfId, killerId)
end

function odali_xinshoutian:OnCharacterTimer(selfId, dataId, nowtime)
end

return odali_xinshoutian
