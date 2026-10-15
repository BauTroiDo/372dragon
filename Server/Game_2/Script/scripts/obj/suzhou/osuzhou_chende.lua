local class = require "class"
local define = require "define"
local script_base = require "script_base"
local osuzhou_chende = class("osuzhou_chende", script_base)
function osuzhou_chende:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{SGCX_20231227_68}")
    self:AddNumText("Sửa thủ công không tẩy lại được", 6, 1)
    self:AddNumText("#{SGCX_20231227_39}", 6, 11)
    self:AddNumText("#{SGCX_20231227_40}", 11, 8888)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end
function osuzhou_chende:OnEventRequest(selfId, targetId, arg, index)
    local nNumText = index
	if nNumText == 0 then
		self:OnDefaultEvent(selfId, targetId)
		return
	end
	if nNumText == 1 then
		self:BeginEvent(self.script_id)
		self:AddText("    Xin đặt đồ thủ công cần sửa vào ô đạo cụ đầu.")
		self:AddNumText("Được, ta đặt xong rồi", 6, 2)
		self:AddNumText("Làm phiền rồi", 11, 0)
		self:EndEvent()
		self:DispatchEventList(selfId, targetId)
		return
	elseif nNumText == 2 then
		local ret = self:LuaFnRefreshEquipArtisanal(selfId,0)
		if ret == 0 then
			self:BeginEvent(self.script_id)
			self:AddText("Sửa thành công, có thể tẩy lại thủ công.")
			self:EndEvent()
			self:DispatchEventList(selfId, targetId)
		elseif ret == 1 then
			self:BeginEvent(self.script_id)
			self:AddText("Ô đầu không có đạo cụ.")
			self:EndEvent()
			self:DispatchEventList(selfId, targetId)
		elseif ret == 2 then
			self:BeginEvent(self.script_id)
			self:AddText("Đạo cụ ô đầu là đồ thủ công, khỏi sửa.")
			self:EndEvent()
			self:DispatchEventList(selfId, targetId)
		elseif ret == 3 then
			self:BeginEvent(self.script_id)
			self:AddText("Xin đặt đồ thủ công cần sửa vào ô đạo cụ đầu.")
			self:EndEvent()
			self:DispatchEventList(selfId, targetId)
		elseif ret == 4 then
			self:BeginEvent(self.script_id)
			self:AddText("Xin đặt đồ thủ công cần sửa vào ô đạo cụ đầu..")
			self:EndEvent()
			self:DispatchEventList(selfId, targetId)
		elseif ret == 5 then
			self:BeginEvent(self.script_id)
			self:AddText("Ô đạo cụ đầu không phải trang bị..")
			self:EndEvent()
			self:DispatchEventList(selfId, targetId)
		end
		return
	end
    if nNumText == 11 then
        self:BeginUICommand()
        self:UICommand_AddInt(targetId)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 88882001)
        return
    end
    if nNumText == 8888 then
        self:BeginEvent(self.script_id)
        self:AddText("#{SGCX_20231227_41}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
end
local wash_equip_config = {
    [7] = 38003056,
    [8] = 38003055
}
local valid_ep = {1, 2, 3, 4, 5, 6, 7, 12, 14, 15}
function osuzhou_chende:RefreshEquipAttr(selfId, BagIndex)
	if not self:LuaFnGetEquipArtisanal(selfId,BagIndex) then
        self:notify_tips(selfId, "#{SGCX_20231227_32}")
        return
    end
    local item_index = self:GetBagItemIndex(selfId, BagIndex)
	local equip_point = self:IsEquipItem(item_index)
	if not equip_point then
        self:notify_tips(selfId, "#{SGCX_20231227_32}")
        return
    end
	local eqlevel = self:GeEquipReqLevel(item_index)
	if eqlevel < 60 then
        self:notify_tips(selfId, "#{SGCX_20231227_32}")
        return
    end
	local open_equip = false
	for i,j in ipairs(valid_ep) do
		if j == equip_point then
			open_equip = true
			break
		end
	end
	if not open_equip then
        self:notify_tips(selfId, "Trang bị này không hỗ trợ tẩy lại.")
        return
    end
    local quality = self:GetBagItemQuality(selfId, BagIndex)
    local need_item = wash_equip_config[quality]
    if not need_item then
        self:notify_tips(selfId, "#{SGCX_20231227_33}")
        return
    end
	-- if self:LuaFnGetEquipReshuffleCount(selfId,BagIndex) >= 3 then
        -- self:notify_tips(selfId,"#{SGCX_20231227_31}")
        -- return
    -- end
    local item_count = self:LuaFnGetAvailableItemCount(selfId, need_item)
    if item_count < 1 then
        self:notify_tips(selfId, string.format("Thiếu %s", self:GetItemName(need_item)))
        return
    end
	local HumanMoney = self:GetMoney(selfId ) + self:GetMoneyJZ(selfId)
    if HumanMoney < 200000 then
        self:notify_tips(selfId, "Mỗi lần tẩy lại cần 20 Giao Tử")
        return
    end
	local del = self:LuaFnDelAvailableItem(selfId, need_item, 1)
	if not del then
        return
    end
	del = self:LuaFnCostMoneyWithPriority(selfId, 200000)
	if not del then
        self:notify_tips(selfId, "Trừ tiền thất bại")
        return
    end
	-- if not self:GetBagItemIsBind(selfId,BagIndex) then
	-- 	self:LuaFnItemBind(selfId,BagIndex)
	-- end
    self:LuaFnRefreshEquipAttr(selfId,BagIndex)
end

function osuzhou_chende:DiscardNewEquipAttr(selfId, BagPos)
    self:LuaFnFinishRefreshEquipAttr(selfId, BagPos, false)
end

function osuzhou_chende:SwitchEquipAttr(selfId, BagPos)
    -- self:LuaFnFinishRefreshEquipAttr(selfId, BagPos, true, true)			--开放重洗计数
    self:LuaFnFinishRefreshEquipAttr(selfId, BagPos, true)
end

return osuzhou_chende
