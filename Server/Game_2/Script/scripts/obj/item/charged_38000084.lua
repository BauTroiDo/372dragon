local class = require "class"
local define = require "define"
local script_base = require "script_base"
local charged_38000084 = class("charged_38000084", script_base)
charged_38000084.script_id = 892683
local items = {
	30309088,
	30309098,
	30310021,
	30310065,
	30310088
}
function charged_38000084:OnDefaultEvent(selfId)
	local nStateData_1 = self:GetMissionDataEx(selfId,401)
	self:BeginEvent(self.script_id)
	self:AddText("   Hộp quà tự chọn, quy tắc: trứng trân thú thượng phẩm chọn 1/5, lỡ đóng cửa sổ thì mở lại chọn tiếp, thiếu hiệp chọn xong trứng sẽ phát toàn bộ thưởng đã chọn, kèm thêm 200 Võ Đạo Huyền Nguyên Đan, 200 rương Thần Hồn Đàn và Hồng Gai (phong cách Toái Mộng).")
	if nStateData_1 == 0 then
		self:AddNumText("Trứng Trân thú thượng phẩm: Hiệp Lộ Phùng",6,1)
		self:AddNumText("Trứng Trân thú thượng phẩm: An Kỳ Nhi",6,2)
		self:AddNumText("Trứng Trân thú thượng phẩm: Xảo Xảo",6,3)
		self:AddNumText("Trứng Trân thú Thượng Phẩm: Thất Thải Huy Tuấn",6,4)
		self:AddNumText("Trứng Trân thú Thượng phẩm: Loan Phượng Hòa Minh",6,5)
	end
	self:EndEvent()
	self:DispatchEventList(selfId,-1)
end

function charged_38000084:OnEventRequest(selfId, targetId, arg, index)
	local eventID = index
	local nStateData_1 = self:GetMissionDataEx(selfId,401)
	local nBagsPos = self:LuaFnGetPropertyBagSpace(selfId)
	if nStateData_1 > 0 then
		self:notify_tips(selfId,"Mỗi người chỉ nhận một lần.")
		return
	end
	if eventID >= 1 and eventID <= 5 then
		if nBagsPos < 4 then
			self:notify_tips(selfId,"Xin đảm bảo ô đạo cụ có bốn chỗ trống.")
			return
		end
		self:BeginAddItem()
		self:AddItem(38002397,200,true)
		self:AddItem(38002499,200,true)
		self:AddItem(10125552,1,true)
		self:AddItem(items[eventID],1,true)
		if not self:EndAddItem(selfId) then
			self:NotifyTips(selfId,"Xin đảm bảo ô đạo cụ có bốn chỗ trống.")
			return
		end
		self:AddItemListToHuman(selfId)
		self:notify_tips(selfId,"Nhận Võ Đạo Huyền Nguyên Đan 200 viên.")
		self:notify_tips(selfId,"Nhận rương Thần Hồn Đàn 200 cái.")
		self:notify_tips(selfId,"Nhận Hồng Gai (phong cách Toái Mộng) 1 món.")
		self:LuaFnSendSpecificImpactToUnit(selfId,selfId,selfId,18,0)
		self:SetMissionDataEx(selfId,401,self:GetDayTime())
		self:LuaFnDelAvailableItem(selfId,38000084,1)
	end
	self:BeginUICommand()
	self:EndUICommand()
	self:DispatchUICommand(selfId, 1000)
end
function charged_38000084:IsSkillLikeScript(selfId)
    return 0
end

return charged_38000084
