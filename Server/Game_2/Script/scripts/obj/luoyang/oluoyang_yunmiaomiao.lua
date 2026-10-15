--洛阳NPC
--云渺渺
--普通
local class = require "class"
local script_base = require "script_base"
local oluoyang_yunmiaomiao = class("oluoyang_yunmiaomiao", script_base)
oluoyang_yunmiaomiao.shoptableindex = 17
local g_miscEventId = 311111
function oluoyang_yunmiaomiao:OnDefaultEvent(selfId, targetId)
	self:BeginEvent(self.script_id)
    self:AddText("#{OBJ_luoyang_0026}")
    self:AddNumText("Mua vật phẩm Trân thú",7,0)
    self:AddNumText("Trân thú học Kỹ năng",6,1)
    self:AddNumText("Trân thú Hoàn Đồng",6,2)
    self:AddNumText("Gia hạn tuổi thọ Trân thú",6,3)
    self:AddNumText("#Trân thú#W thuần dưỡng",6,4)
    self:AddNumText("Trân thú tẩy điểm",6,99)
    self:AddNumText("Trân thú Kỹ năng Thăng cấp",6,34)
    self:AddNumText("Trân thú liên quan tửu quán", 11, 10 )
	self:EndEvent()
	self:DispatchEventList(selfId,targetId)
end

function oluoyang_yunmiaomiao:OnEventRequest(selfId, targetId, arg, index)
    print("oluoyang_yunmiaomiao:OnEventRequest index =", index)
	if index == 100 then
		self:OnDefaultEvent(selfId, targetId)
		return
	elseif index == 99 then
		local phid,plid = self:LuaFnGetCurrentPetGUID(selfId)
		if not phid or not plid then
			self:BeginEvent(self.script_id)
			self:AddText("    Xin cho trân thú cần tẩy điểm xuất chiến")
			self:AddNumText("Trở về trang chủ",11,100)
			self:EndEvent()
			self:DispatchEventList(selfId,targetId)
		else
			local curpoint = self:LuaFnGetPetAllocationPoint(selfId, phid, plid)
			if curpoint > 0 then
				self:BeginEvent(self.script_id)
				self:AddText("    Ngươi sẽ phân cho trân thú xuất chiến#G"..tostring(curpoint).."#Wđiểm tiềm năng sẽ đặt lại, xin xác nhận!")
				self:AddNumText("Không sai, chính là nó",6,101)
				self:AddNumText("A, khoan đã, để ta cân nhắc",11,100)
				self:EndEvent()
				self:DispatchEventList(selfId,targetId)
			else
				self:BeginEvent(self.script_id)
				self:AddText("    Trân thú xuất chiến chưa ghi phân bổ tiềm năng, không đặt lại được")
				self:AddNumText("Được, lần sau ta mang trân thú bắt đầu phân từ giờ tới",11,100)
				self:EndEvent()
				self:DispatchEventList(selfId,targetId)
			end
		end
		return
	elseif index == 101 then
		self:OnDefaultEvent(selfId, targetId)
		local lsdcount = self:LuaFnGetAvailableItemCount(selfId, 30503021)
		if lsdcount < 1 then
			self:notify_tips(selfId,"Ngươi không có"..self:GetItemName(30503021))
			return
		end
		local phid,plid = self:LuaFnGetCurrentPetGUID(selfId)
		if phid and plid then
			local del = self:LuaFnDelAvailableItem(selfId, 30503021, 1)
			if del then
				self:LuaFnResetPetPoint(selfId, phid, plid)
			else
				self:notify_tips(selfId,self:GetItemName(30503021).."Khấu trừ thất bại")
			end
		else
			self:notify_tips(selfId,"Xin cho trân thú cần tẩy điểm xuất chiến")
		end
		return
	end
    if index == 11 then
        self:BeginEvent(self.script_id)
        self:AddText("#{function_help_057}#r")
        self:EndEvent()
        self:DispatchEventList(selfId,targetId)
        return
    end
    if index == 12 then
        self:BeginEvent(self.script_id)
        self:AddText("#{function_help_058}#r")
        self:EndEvent()
        self:DispatchEventList(selfId,targetId)
        return
    end
    if index == 34 then
        self:BeginUICommand()
        self:UICommand_AddInt(selfId)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 19823)
        return
    elseif index<= 6 then
        local sel = index
        self:CallScriptFunction(g_miscEventId, "OnEnumerate", self, selfId, targetId, sel)
        return
    elseif index == 7 then
        self:LuaFnGetPetProcreateInfo(selfId);
        return
    end
    if index == 0 then
        self:DispatchShopItem(selfId,targetId, self.g_shoptableindex )
    end
end

return oluoyang_yunmiaomiao