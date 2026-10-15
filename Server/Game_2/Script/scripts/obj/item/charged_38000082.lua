local class = require "class"
local define = require "define"
local script_base = require "script_base"
local charged_38000082 = class("charged_38000082", script_base)
charged_38000082.script_id = 892681
charged_38000082.iteminfo = {30310021,30309098,10124415,10124860,10124578,10124876,10125333,10142287,10142303,10142235,10142101,10142023,38008100,38008143,38008146,38008142}
charged_38000082.menpainame = 
{
	"Kẻ lăng vân Thiếu Lâm",
	"Lăng Vân giả Minh Giáo",
	"Lăng Vân Giả Cái Bang",
	"Lăng Vân giả Võ Đang",
	"Kẻ Lăng Vân Nga Mi",
	"Lăng Vân giả Tinh Túc",
	"Lăng Vân Giả Thiên Long",
	"Lăng Vân Giả Thiên Sơn",
	"Lăng Vân Giả Tiêu Dao",
	"无门派",
	"Kẻ Lăng Vân Mạn Đà Sơn Trang",
}
charged_38000082.menpaititle = {38008120,38008124,38008127,38008121,38008122,38008123,38008125,38008128,38008126,-1,38008139}
function charged_38000082:OnDefaultEvent(selfId)
	local nStateData_1 = self:GetMissionDataEx(selfId,400)
	local nStateData_2 = self:GetMissionDataEx(selfId,401)
	local nStateData_3 = self:GetMissionDataEx(selfId,402)
	local nStateData_4 = self:GetMissionDataEx(selfId,403)
	local menpaiID = self:GetMenPai(selfId)
	self:BeginEvent(self.script_id)
	self:AddText("   Hộp quà tự chọn, quy tắc: trân thú chọn 1/2, thời trang tọa kỵ 1/5, danh hiệu 1/5, lỡ đóng cửa sổ thì mở lại chọn tiếp, thiếu hiệp chọn xong tọa kỵ sẽ phát toàn bộ thưởng đã chọn, kèm thêm 200 Võ Đạo Huyền Nguyên Đan.")
	if nStateData_1 == 0 then
		self:AddNumText("Nhận trứng trân thú thượng phẩm: Xảo Xảo",6,1)
		self:AddNumText("Nhận trứng trân thú thượng phẩm: An Kỳ Nhi",6,2)
	elseif nStateData_1 > 0 and nStateData_2 == 0 then
		self:AddNumText("Nhận thời trang: Đoạn Kiều Tàn Tuyết",6,3)
		self:AddNumText("Nhận thời trang: Thượng Nguyên Thanh Gia Cảnh",6,4)
		self:AddNumText("Nhận thời trang: Dạ Vũ Thính Trúc",6,5)
		self:AddNumText("Nhận thời trang: Tinh Hà Lạc Tuyết",6,6)
		self:AddNumText("Nhận thời trang: Phù Quang Tận Nhiễm【phong cách Tinh Triều】",6,7)
	elseif nStateData_1 > 0 and nStateData_2 > 0 and nStateData_3 == 0 then
		self:AddNumText("Nhận tọa kỵ: Phượng Thê Vân Đài",6,8)
		self:AddNumText("Nhận tọa kỵ: Alpaca",6,9)
		self:AddNumText("Nhận tọa kỵ: Thập Quang Luyến Vũ",6,10)
		self:AddNumText("Nhận tọa kỵ: Liệt Diễm Truy Phong",6,11)
		self:AddNumText("Nhận tọa kỵ: Phượng Hoàng Tòa",6,12)
	elseif nStateData_1 > 0 and nStateData_2 > 0 and nStateData_3 > 0 and nStateData_4 == 0 then
		self:AddNumText("Nhận danh hiệu: Anh Hùng Đại Hội·Nhất Phương Tiêu Dao",6,13)
		self:AddNumText("Nhận danh hiệu: Tái Ngoại Tuyệt Trần·Kinh Minh Giả",6,14)
		self:AddNumText("Nhận danh hiệu: Phá Sát Độ Ách·Hành Giả",6,15)
		self:AddNumText("Nhận danh hiệu: Tái Ngoại Tuyệt Trần·Lăng Tiêu Khách",6,16)
		self:AddNumText("Nhận danh hiệu:"..self.menpainame[menpaiID + 1],6,17)
	end
	self:EndEvent()
	self:DispatchEventList(selfId,-1)
end
function charged_38000082:OnEventRequest(selfId, targetId, arg, index)
	local eventID = index
	local nStateData_1 = self:GetMissionDataEx(selfId,400)
	local nStateData_2 = self:GetMissionDataEx(selfId,401)
	local nStateData_3 = self:GetMissionDataEx(selfId,402)
	local nStateData_4 = self:GetMissionDataEx(selfId,403)
	local menpaiID = self:GetMenPai(selfId)
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
			self:AddItem(38002397,500,true)
			self:AddItem(38002499,500,true)
		if not self:EndAddItem(selfId) then
			self:NotifyTips(selfId,"Xin đảm bảo ô đạo cụ có năm chỗ trống.")
			return
		end
		self:AddItemListToHuman(selfId)
		self:notify_tips(selfId,"Nhận Võ Đạo Huyền Nguyên Đan 500 viên.")
		self:notify_tips(selfId,"Nhận rương Thần Hồn Đàn 500 cái.")
		self:notify_tips(selfId,"Nhận được"..self:GetItemName(self.iteminfo[eventID]))
		self:LuaFnSendSpecificImpactToUnit(selfId,selfId,selfId,18,0)
		self:SetMissionDataEx(selfId,400,self:GetDayTime())
		self:BeginEvent(self.script_id)
		self:AddText("   Hộp quà tự chọn, quy tắc: trân thú chọn 1/2, thời trang tọa kỵ 1/5, danh hiệu 1/5, lỡ đóng cửa sổ thì mở lại chọn tiếp, thiếu hiệp chọn xong tọa kỵ sẽ phát toàn bộ thưởng đã chọn, kèm thêm 200 Võ Đạo Huyền Nguyên Đan.")
		self:AddNumText("Nhận thời trang: Đoạn Kiều Tàn Tuyết",6,3)
		self:AddNumText("Nhận thời trang: Thượng Nguyên Thanh Gia Cảnh",6,4)
		self:AddNumText("Nhận thời trang: Dạ Vũ Thính Trúc",6,5)
		self:AddNumText("Nhận thời trang: Tinh Hà Lạc Tuyết",6,6)
		self:AddNumText("Nhận thời trang: Phù Quang Tận Nhiễm【phong cách Tinh Triều】",6,7)
		self:EndEvent()
		self:DispatchEventList(selfId,-1)
		return
	end
	if eventID >= 3 and eventID <= 7 then
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
		self:AddText("   Hộp quà tự chọn, quy tắc: trân thú chọn 1/2, thời trang tọa kỵ 1/5, danh hiệu 1/5, lỡ đóng cửa sổ thì mở lại chọn tiếp, thiếu hiệp chọn xong tọa kỵ sẽ phát toàn bộ thưởng đã chọn, kèm thêm 200 Võ Đạo Huyền Nguyên Đan.")
		self:AddNumText("Nhận tọa kỵ: Phượng Thê Vân Đài",6,8)
		self:AddNumText("Nhận tọa kỵ: Alpaca",6,9)
		self:AddNumText("Nhận tọa kỵ: Thập Quang Luyến Vũ",6,10)
		self:AddNumText("Nhận tọa kỵ: Liệt Diễm Truy Phong",6,11)
		self:AddNumText("Nhận tọa kỵ: Phượng Hoàng Tòa",6,12)
		self:EndEvent()
		self:DispatchEventList(selfId,-1)
		return
	end
	if eventID >= 8 and eventID <= 12 then
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
		self:AddText("   Hộp quà tự chọn, quy tắc: trân thú chọn 1/2, thời trang tọa kỵ 1/5, danh hiệu 1/5, lỡ đóng cửa sổ thì mở lại chọn tiếp, thiếu hiệp chọn xong tọa kỵ sẽ phát toàn bộ thưởng đã chọn, kèm thêm 200 Võ Đạo Huyền Nguyên Đan.")
		self:AddNumText("Nhận danh hiệu: Anh Hùng Đại Hội·Nhất Phương Tiêu Dao",6,13)
		self:AddNumText("Nhận danh hiệu: Tái Ngoại Tuyệt Trần·Kinh Minh Giả",6,14)
		self:AddNumText("Nhận danh hiệu: Phá Sát Độ Ách·Hành Giả",6,15)
		self:AddNumText("Nhận danh hiệu: Tái Ngoại Tuyệt Trần·Lăng Tiêu Khách",6,16)
		self:AddNumText("Nhận danh hiệu:"..self.menpainame[menpaiID + 1],6,17)
		self:EndEvent()
		self:DispatchEventList(selfId,-1)
		return
	end
	if eventID >= 13 and eventID <= 16 then
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
		self:LuaFnDelAvailableItem(selfId,38000082,1)
	end
	if eventID == 17 then
		if nBagsPos < 1 then
			self:notify_tips(selfId,"Xin đảm bảo ô đạo cụ có một chỗ trống.")
			return
		end
		self:BeginAddItem()
		self:AddItem(self.menpaititle[menpaiID + 1],1,true)
		if not self:EndAddItem(selfId) then
			self:NotifyTips(selfId,"Xin đảm bảo ô đạo cụ có một chỗ trống.")
			return
		end
		self:AddItemListToHuman(selfId)
		self:notify_tips(selfId,"Nhận được"..self:GetItemName(self.menpaititle[menpaiID + 1]))
		self:LuaFnSendSpecificImpactToUnit(selfId,selfId,selfId,18,0)
		self:SetMissionDataEx(selfId,403,self:GetDayTime())
		self:LuaFnDelAvailableItem(selfId,38000082,1)
	end
	self:BeginUICommand()
	self:EndUICommand()
	self:DispatchUICommand(selfId, 1000)
end
function charged_38000082:IsSkillLikeScript(selfId)
    return 0
end

return charged_38000082
