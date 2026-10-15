local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local odali_ouyean = class("odali_ouyean", script_base)
odali_ouyean.script_id = 002053
odali_ouyean.g_eventList = {713511, 713570, 713610}

function odali_ouyean:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{SBFW_20230707_20}")
    self:AddNumText("Nhận Ngũ Uẩn Thiên Duyên Hạp", 6, 121)
    self:AddNumText("#{SBFW_20230707_21}", 6, 21)
    self:AddNumText("#{SBFW_20230707_256}", 6, 22)
    self:AddNumText("#{SBFW_20230707_257}", 6, 23)
    -- self:AddNumText("#{SBFW_20230707_26}", 6, 26)
    self:AddNumText("#{SBFW_20230707_29}", 11, 91)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function odali_ouyean:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function odali_ouyean:OnEventRequest(selfId, targetId, arg, index)
	if index == 0 then
		self:UpdateEventList(selfId, targetId)
		return
	end
    if index == 121 then
        local val = self:GetMissionDataEx(selfId, ScriptGlobal.MDEX_GET_QIQINGREN_GIFT)
        if val == 0 then
            self:BeginAddItem()
            self:AddItem(38002985, 1)
            local ret = self:EndAddItem(selfId)
            if ret then
                self:AddItemListToHuman(selfId)
                self:SetMissionDataEx(selfId, ScriptGlobal.MDEX_GET_QIQINGREN_GIFT, 1)
            else
                self:notify_tips(selfId, "Túi hành trang không đủ chỗ")
            end
        else
            self:notify_tips(selfId, "Ngươi đã nhận Ngũ Uẩn Thiên Duyên Hạp rồi")
        end
        return
    end
    if index == 21 then
        self:BeginUICommand()
        self:UICommand_AddInt(targetId)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 88881201)
        return
    end
    if index == 22 then
        self:BeginUICommand()
        self:UICommand_AddInt(targetId)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 88881202)
        return
    end
    if index == 23 then
        self:BeginEvent(self.script_id)
        local str = self:ContactArgs("#{SBFW_20230707_260", 2, 3) .. "}"
        self:AddText(str)
        self:AddNumText("#{SBFW_20230707_261}", 6, 24)
        self:AddNumText("#{SBFW_20230707_262}", 6, 25)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if index == 24 then
        local cost_material_ids = { 38002944 }
        if self:LuaFnMtl_GetCostNum(selfId, cost_material_ids) < 10 then
            self:notify_tips(selfId, "Không đủ mảnh Thất Tình")
            return
        end
        self:BeginAddItem()
        self:AddItem(38002985, 1 , true)
        local ret = self:EndAddItem(selfId)
        if not ret then
            self:MsgBox(selfId, targetId, "  Túi đồ của ngươi không đủ chỗ trống, hãy thu xếp lại rồi đến tìm ta.")
            return
        end
        self:LuaFnMtl_CostMaterial(selfId, 10, cost_material_ids)
        self:AddItemListToHuman(selfId)
        return
    end
    if index == 25 then
        local cost_material_ids = { 38002945 }
        if self:LuaFnMtl_GetCostNum(selfId, cost_material_ids) < 20 then
            self:notify_tips(selfId, "Không đủ Thất Tình Thạch")
            return
        end
        self:BeginAddItem()
        self:AddItem(38002986, 1 , true)
        local ret = self:EndAddItem(selfId)
        if not ret then
            self:MsgBox(selfId, targetId, "  Túi đồ của ngươi không đủ chỗ trống, hãy thu xếp lại rồi đến tìm ta.")
            return
        end
        self:LuaFnMtl_CostMaterial(selfId, 20, cost_material_ids)
        self:AddItemListToHuman(selfId)
        return
    end
    -- if index == 26 then
        -- self:BeginUICommand()
        -- self:UICommand_AddInt(targetId)
        -- self:EndUICommand()
        -- self:DispatchUICommand(selfId, 88881205)
        -- return
    -- end
	if index >= 91 and index <= 95 then
		self:BeginEvent(self.script_id)
		if index == 91 then
			self:AddNumText("#{SBFW_20230707_236}", 11, 92)
			self:AddNumText("#{SBFW_20230707_237}", 11, 93)
			self:AddNumText("#{SBFW_20230707_238}", 11, 94)
			self:AddNumText("#{SBFW_20230707_239}", 11, 95)
		elseif index == 92 then
			self:AddText("#{SBFW_20230707_31}")
		elseif index == 93 then
			self:AddText("#{SBFW_20230707_241}")
		elseif index == 94 then
			self:AddText("#{SBFW_20230707_242}")
		elseif index == 95 then
			self:AddText("#{SBFW_20230707_243}")
		end
		self:AddNumText("#{SBFW_20230707_240}", 8, 0)
		self:EndEvent()
		self:DispatchEventList(selfId, targetId)
		return
	end
end

function odali_ouyean:ShenBingLevelUp(selfId, targetId, BagPos)
	if self:FixLegacyShenBinData(selfId,BagPos) then
        self:notify_tips(selfId, "Thần binh có dữ liệu cũ, đã tự sửa, xin thao tác lại là được.")
        return
    end
	if not self:CheckHnmanLevel(selfId) then
		return
	end
    local zhuqing_level = self:GetShenBingZhuQingLevel(selfId, BagPos)
	if not zhuqing_level then
		return
	end
    local cost_material_id, cost_material_count, cost_money = self:GetShenBingLevelConfig(zhuqing_level)
    if not cost_material_id then
        self:notify_tips(selfId, "Cấp chú tình Thất Tình Nhận đã tối đa")
        return
    end
    if self:GetMoneyJZ(selfId) + self:GetMoney(selfId) < cost_money then
        self:notify_tips(selfId, "Xin lỗi, kim tiền trên người ngươi không đủ, không thể tiếp tục")
        return
    end
	if self:LuaFnGetAvailableItemCount(selfId,cost_material_id) < cost_material_count then
		self:notify_tips(selfId, "#{SBFW_20230707_51}")
		return
	end
	self:LuaFnDelAvailableItem(selfId,cost_material_id,cost_material_count)
    self:LuaFnCostMoneyWithPriority(selfId, cost_money)
    zhuqing_level = zhuqing_level + 1
	self:LuaFnItemBind(selfId,BagPos)
    self:SetShenBinZhuQingLevel(selfId, BagPos, zhuqing_level)
    self:notify_tips(selfId, "#{SBFW_20230707_53}")
	self:ShowObjBuffEffect(selfId,selfId,-1,18)
end

local MeltingConfigs = {
    [4] = { id = 38002944, count = 2},
    [5] = { id = 38002945, count = 2 },
    [6] = { id = 38002945, count = 5 },
}
function odali_ouyean:ShenBingMelt(selfId, targetId, BagPos)
	if self:FixLegacyShenBinData(selfId,BagPos) then
        self:notify_tips(selfId, "Thần binh có dữ liệu cũ, đã tự sửa, xin thao tác lại là được.")
        return
    end
	if not self:CheckHnmanLevel(selfId) then
		return
	end
    if self:LuaFnIsBagItemExpensive(selfId, BagPos) then
        self:notify_tips(selfId, "Vật quý không phân giải được")
        return
    end
    local zhuqing_level = self:GetShenBingZhuQingLevel(selfId, BagPos)
    if zhuqing_level > 1 then
        self:notify_tips(selfId, "Cấp chú tình lớn hơn 1 không phân giải được")
        return
    end
    local star = self:GetShenBingStar(selfId, BagPos)
    local Config = MeltingConfigs[star]
    if Config == nil then
        self:notify_tips(selfId, "Phân giải Thất Tình Nhận, xin kiểm cấu hình")
        return
    end
    self:BeginAddItem()
    self:AddItem(Config.id, Config.count , true)
    local ret = self:EndAddItem(selfId)
    if not ret then
        self:MsgBox(selfId, targetId, "  Túi đồ của ngươi không đủ chỗ trống, hãy thu xếp lại rồi đến tìm ta.")
        return
    end
    self:LuaFnEraseItem(selfId, BagPos)
    self:AddItemListToHuman(selfId)
    self:notify_tips(selfId, "Phân giải vũ khí phụ thành công")
	self:ShowObjBuffEffect(selfId,selfId,-1,18)
end

function odali_ouyean:ShenBingTransition(selfId, targetId, BagPosFrom, BagPosTo,box1,box2)
	if self:FixLegacyShenBinData(selfId,BagPosFrom) then
        self:notify_tips(selfId, "Thần binh gốc có dữ liệu cũ, đã tự sửa, xin thao tác lại là được.")
        return
	elseif self:FixLegacyShenBinData(selfId,BagPosTo) then
        self:notify_tips(selfId, "Thần binh gốc có dữ liệu cũ, đã tự sửa, xin thao tác lại là được.")
        return
    end
	if not BagPosFrom or BagPosFrom == BagPosTo then
		return
	end
	if not self:CheckHnmanLevel(selfId) then
		return
	end
	local cost_money = 100000
    if self:GetMoneyJZ(selfId) + self:GetMoney(selfId) < cost_money then
        self:notify_tips(selfId, "Xin lỗi, kim tiền trên người ngươi không đủ, không thể tiếp tục")
        return
    end
	self:CheckShenBinTransition(selfId, BagPosFrom, BagPosTo, cost_money)
    self:notify_tips(selfId, "#{SBFW_20230707_147}")
	self:ShowObjBuffEffect(selfId,selfId,-1,18)
end
function odali_ouyean:CheckHnmanLevel(selfId)
	if self:GetLevel(selfId) < 65 then
		self:notify_tips(selfId, "#{SBFW_20230707_46}")
		return
	end
	return true
end

return odali_ouyean
