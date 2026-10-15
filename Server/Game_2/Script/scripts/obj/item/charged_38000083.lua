local class = require "class"
local define = require "define"
local script_base = require "script_base"
local charged_38000083 = class("charged_38000083", script_base)
charged_38000083.script_id = 892682

function charged_38000083:OnDefaultEvent(selfId)
	local nStateData_1 = self:GetMissionDataEx(selfId,400)
	self:BeginEvent(self.script_id)
	self:AddText("   Hộp quà tự chọn, quy tắc: tọa kỵ chọn 1/2, lỡ đóng cửa sổ thì mở lại chọn tiếp, thiếu hiệp chọn xong tọa kỵ sẽ phát toàn bộ thưởng đã chọn, kèm thêm 100 Võ Đạo Huyền Nguyên Đan, 100 rương Thần Hồn Đàn và Hồng Gai (phong cách Toái Mộng).")
	if nStateData_1 == 0 then
		self:AddNumText("Tọa kỵ: Thự Quang Huỳnh Dực",6,1)
		self:AddNumText("Tọa kỵ: Dạ Hà Xích Vũ",6,2)
	end
	self:EndEvent()
	self:DispatchEventList(selfId,-1)
end

function charged_38000083:OnEventRequest(selfId, targetId, arg, index)
	local eventID = index
	local nStateData_1 = self:GetMissionDataEx(selfId,400)
	local nBagsPos = self:LuaFnGetPropertyBagSpace(selfId)
	if nStateData_1 > 0 then
		self:notify_tips(selfId,"Mỗi người chỉ nhận một lần.")
		return
	end
	if eventID >= 1 and eventID <= 2 then
		if nBagsPos < 4 then
			self:notify_tips(selfId,"Xin đảm bảo ô đạo cụ có bốn chỗ trống.")
			return
		end
		self:BeginAddItem()
		self:AddItem(38002397,100,true)
		self:AddItem(38002499,100,true)
		self:AddItem(10125552,1,true)
		if eventID == 1 then
			self:AddItem(10142467,1,true)
		else
			self:AddItem(10142449,1,true)
		end
		if not self:EndAddItem(selfId) then
			self:NotifyTips(selfId,"Xin đảm bảo ô đạo cụ có bốn chỗ trống.")
			return
		end
		self:AddItemListToHuman(selfId)
		self:notify_tips(selfId,"Nhận Võ Đạo Huyền Nguyên Đan 100 viên.")
		self:notify_tips(selfId,"Nhận rương Thần Hồn Đàn 100 cái.")
		self:notify_tips(selfId,"Nhận Hồng Gai (phong cách Toái Mộng) 1 món.")
		self:LuaFnSendSpecificImpactToUnit(selfId,selfId,selfId,18,0)
		self:SetMissionDataEx(selfId,400,self:GetDayTime())
		self:LuaFnDelAvailableItem(selfId,38000083,1)
	end
	self:BeginUICommand()
	self:EndUICommand()
	self:DispatchUICommand(selfId, 1000)
end
function charged_38000083:IsSkillLikeScript(selfId)
    return 0
end

return charged_38000083
