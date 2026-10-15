local class = require "class"
local define = require "define"
local script_base = require "script_base"
local charged_38000087 = class("charged_38000087", script_base)
charged_38000087.script_id = 889903
charged_38000087.iteminfo = {30310022,30309996,10124415,10124860,10124578,10142287,10142303,10142235,38008100,38008143,38008146}
function charged_38000087:OnDefaultEvent(selfId)
	local nStateData_1 = self:GetMissionDataEx(selfId,400)
	local nStateData_2 = self:GetMissionDataEx(selfId,401)
	local nStateData_3 = self:GetMissionDataEx(selfId,402)
	local nStateData_4 = self:GetMissionDataEx(selfId,403)
	self:BeginEvent(self.script_id)
	self:AddText("   Hộp quà tự chọn, quy tắc: trân thú chọn 1/2, thời trang tọa kỵ 1/3, danh hiệu 1/3, lỡ đóng cửa sổ thì mở lại chọn tiếp, thiếu hiệp chọn xong tọa kỵ sẽ phát toàn bộ thưởng đã chọn, kèm thêm 100 Võ Đạo Huyền Nguyên Đan.")
	if nStateData_1 == 0 then
		self:AddNumText("Nhận lồng trân thú siêu cấp: Xảo Xảo",6,1)
		self:AddNumText("Nhận lồng trân thú siêu cấp: An Kỳ Nhi",6,2)
	elseif nStateData_1 > 0 and nStateData_2 == 0 then
		self:AddNumText("Nhận thời trang: Đoạn Kiều Tàn Tuyết",6,3)
		self:AddNumText("Nhận thời trang: Thượng Nguyên Thanh Gia Cảnh",6,4)
		self:AddNumText("Nhận thời trang: Dạ Vũ Thính Trúc",6,5)
	elseif nStateData_1 > 0 and nStateData_2 > 0 and nStateData_3 == 0 then
		self:AddNumText("Nhận tọa kỵ: Phượng Thê Vân Đài",6,6)
		self:AddNumText("Nhận tọa kỵ: Alpaca",6,7)
		self:AddNumText("Nhận tọa kỵ: Thập Quang Luyến Vũ",6,8)
	elseif nStateData_1 > 0 and nStateData_2 > 0 and nStateData_3 > 0 and nStateData_4 == 0 then
		self:AddNumText("Nhận danh hiệu: Anh Hùng Đại Hội·Nhất Phương Tiêu Dao",6,9)
		self:AddNumText("Nhận danh hiệu: Tái Ngoại Tuyệt Trần·Kinh Minh Giả",6,10)
		self:AddNumText("Nhận danh hiệu: Phá Sát Độ Ách·Hành Giả",6,11)
	end
	self:EndEvent()
	self:DispatchEventList(selfId,-1)
end
function charged_38000087:OnEventRequest(selfId, targetId, arg, index)
	local eventID = index
	local nStateData_1 = self:GetMissionDataEx(selfId,400)
	local nStateData_2 = self:GetMissionDataEx(selfId,401)
	local nStateData_3 = self:GetMissionDataEx(selfId,402)
	local nStateData_4 = self:GetMissionDataEx(selfId,403)
	local nBagsPos = self:LuaFnGetPropertyBagSpace(selfId)
	local nBagMaterial = self:LuaFnGetMaterialBagSpace(selfId)
	if nStateData_1 > 0 and nStateData_2 > 0 and nStateData_3 > 0 and nStateData_4 > 0 then
		self:notify_tips(selfId,"Mỗi người chỉ nhận một lần.")
		return
	end
	if eventID >= 1 and eventID <= 2 then
		if nBagsPos < 5 then
			self:notify_tips(selfId,"Xin đảm bảo ô đạo cụ có năm chỗ trống.")
			return
		end
		self:BeginAddItem()
			self:AddItem(self.iteminfo[eventID],1,true)
			self:AddItem(38002397,300,true)
			self:AddItem(38002499,300,true)
		if not self:EndAddItem(selfId) then
			self:NotifyTips(selfId,"Xin đảm bảo ô đạo cụ có năm chỗ trống.")
			return
		end
		self:AddItemListToHuman(selfId)
		self:notify_tips(selfId,"Nhận Võ Đạo Huyền Nguyên Đan 300 viên.")
		self:notify_tips(selfId,"Nhận rương Thần Hồn Đàn 300 cái.")
		self:notify_tips(selfId,"Nhận được"..self:GetItemName(self.iteminfo[eventID]))
		self:LuaFnSendSpecificImpactToUnit(selfId,selfId,selfId,18,0)
		self:SetMissionDataEx(selfId,400,self:GetDayTime())
		self:BeginEvent(self.script_id)
		self:AddText("   Hộp quà tự chọn, quy tắc: trân thú chọn 1/2, thời trang tọa kỵ 1/3, danh hiệu 1/3, lỡ đóng cửa sổ thì mở lại chọn tiếp, thiếu hiệp chọn xong tọa kỵ sẽ phát toàn bộ thưởng đã chọn, kèm thêm 100 Võ Đạo Huyền Nguyên Đan.")
		self:AddNumText("Nhận thời trang: Đoạn Kiều Tàn Tuyết",6,3)
		self:AddNumText("Nhận thời trang: Thượng Nguyên Thanh Gia Cảnh",6,4)
		self:AddNumText("Nhận thời trang: Dạ Vũ Thính Trúc",6,5)
		self:EndEvent()
		self:DispatchEventList(selfId,-1)
		return
	end
	if eventID >= 3 and eventID <= 5 then
		if nBagsPos < 1 then
			self:notify_tips(selfId,"Xin đảm bảo ô đạo cụ có một chỗ trống.")
			return
		end
		self:BeginAddItem()
		self:AddItem(self.iteminfo[eventID],1,true)
		if not self:EndAddItem(selfId) then
			self:NotifyTips(selfId,"Xin đảm bảo ô đạo cụ có một chỗ trống.")
			return
		end
		self:AddItemListToHuman(selfId)
		self:notify_tips(selfId,"Nhận được"..self:GetItemName(self.iteminfo[eventID]))
		self:LuaFnSendSpecificImpactToUnit(selfId,selfId,selfId,18,0)
		self:SetMissionDataEx(selfId,401,self:GetDayTime())
		self:BeginEvent(self.script_id)
		self:AddText("   Hộp quà tự chọn, quy tắc: trân thú chọn 1/2, thời trang tọa kỵ 1/3, danh hiệu 1/3, lỡ đóng cửa sổ thì mở lại chọn tiếp, thiếu hiệp chọn xong tọa kỵ sẽ phát toàn bộ thưởng đã chọn, kèm thêm 100 Võ Đạo Huyền Nguyên Đan.")
		self:AddNumText("Nhận tọa kỵ: Phượng Thê Vân Đài",6,6)
		self:AddNumText("Nhận tọa kỵ: Alpaca",6,7)
		self:AddNumText("Nhận tọa kỵ: Thập Quang Luyến Vũ",6,8)
		self:EndEvent()
		self:DispatchEventList(selfId,-1)
		return
	end
	if eventID >= 6 and eventID <= 8 then
		if nBagsPos < 1 then
			self:notify_tips(selfId,"Xin đảm bảo ô đạo cụ có một chỗ trống.")
			return
		end
		self:BeginAddItem()
		self:AddItem(self.iteminfo[eventID],1,true)
		if not self:EndAddItem(selfId) then
			self:NotifyTips(selfId,"Xin đảm bảo ô đạo cụ có một chỗ trống.")
			return
		end
		self:AddItemListToHuman(selfId)
		self:notify_tips(selfId,"Nhận được"..self:GetItemName(self.iteminfo[eventID]))
		self:LuaFnSendSpecificImpactToUnit(selfId,selfId,selfId,18,0)
		self:SetMissionDataEx(selfId,402,self:GetDayTime())
		self:BeginEvent(self.script_id)
		self:AddText("   Hộp quà tự chọn, quy tắc: trân thú chọn 1/2, thời trang tọa kỵ 1/3, danh hiệu 1/3, lỡ đóng cửa sổ thì mở lại chọn tiếp, thiếu hiệp chọn xong tọa kỵ sẽ phát toàn bộ thưởng đã chọn, kèm thêm 100 Võ Đạo Huyền Nguyên Đan.")
		self:AddNumText("Nhận danh hiệu: Anh Hùng Đại Hội·Nhất Phương Tiêu Dao",6,9)
		self:AddNumText("Nhận danh hiệu: Tái Ngoại Tuyệt Trần·Kinh Minh Giả",6,10)
		self:AddNumText("Nhận danh hiệu: Phá Sát Độ Ách·Hành Giả",6,11)
		self:EndEvent()
		self:DispatchEventList(selfId,-1)
		return
	end
	if eventID >= 9 then
		if nBagsPos < 1 then
			self:notify_tips(selfId,"Xin đảm bảo ô đạo cụ có một chỗ trống.")
			return
		end
		self:BeginAddItem()
		self:AddItem(self.iteminfo[eventID],1,true)
		if not self:EndAddItem(selfId) then
			self:NotifyTips(selfId,"Xin đảm bảo ô đạo cụ có một chỗ trống.")
			return
		end
		self:AddItemListToHuman(selfId)
		self:notify_tips(selfId,"Nhận được"..self:GetItemName(self.iteminfo[eventID]))
		self:LuaFnSendSpecificImpactToUnit(selfId,selfId,selfId,18,0)
		self:SetMissionDataEx(selfId,403,self:GetDayTime())
		self:LuaFnDelAvailableItem(selfId,38000087,1)
		self:BeginUICommand()
		self:EndUICommand()
		self:DispatchUICommand(selfId, 1000)
	end
end
function charged_38000087:IsSkillLikeScript(selfId)
    return 0
end

return charged_38000087
