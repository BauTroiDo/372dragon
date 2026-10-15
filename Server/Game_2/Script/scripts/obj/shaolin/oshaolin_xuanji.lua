--少林NPC
--玄寂
--普通
local gbk = require "wire_charset"
local define = require "define"
local class = require "class"
local script_base = require "script_base"
local oshaolin_xuanji = class("oshaolin_xuanji", script_base)
oshaolin_xuanji.script_id = 9003
local MenPaiPet =
{
	[1] = {["id"] = 3030, ["name"] = "狗", ["itemList"] = {{["id"] = 30601001,["num"] = 20 },{["id"] = 30602001,["num"] = 20}}},
	[2] = {["id"] = 3040, ["name"] = "Nhím", ["itemList"] = {{["id"] = 30601001,["num"] = 20}, {["id"] = 30604001, ["num"] = 20}}},
	[3] = {["id"] = 3050, ["name"] = "Hầu Tử", ["itemList"] = {{["id"] = 30601001, ["num"] = 20}, {["id"] = 30605001, ["num"] = 20}}},
}
function oshaolin_xuanji:OnDefaultEvent(selfId, targetId)
	local menpai = self:GetMenPai(selfId)
    self:BeginEvent(self.script_id)
        self:AddText("  Lão nạp Huyền Tịch, thí chủ tìm lão nạp có việc chi chăng?")
        if menpai == 9 then
            self:AddNumText("#GGia nhập Môn phái", 6, 0)
        end
		if menpai == 0 then
			self:AddNumText("Đổi danh hiệu", 3, 8)
			self:AddNumText("Đổi vật phẩm", 3, 7)
			if self:GetMissionDataEx(selfId, 134) < 1 then
				self:AddNumText("Nhận Trang bị", 4, 100)
			end
			if self:GetMissionDataEx(selfId, 135) < 1 then
				self:AddNumText("Lĩnh thưởng Trân thú", 4, 101)
			end
			if self:GetMissionDataEx(selfId, 133) < 1 then
				self:AddNumText("Lĩnh thưởng Môn phái Thời Trang", 4, 102)
			end
		end
        self:AddNumText("Môn phái tửu quán", 8, 1)
        self:AddNumText("Làm sao học tập Kỹ năng Môn phái", 8, 6)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oshaolin_xuanji:OnEventRequest(selfId, targetId, arg, index)
	local nMenPai = self:GetMenPai(selfId)
	if index == 0 then
		if nMenPai ~= 9 then
			self:MsgBox(selfId, targetId, "   Ngươi đã bái nhập Môn phái Khác.")
			return
		end
		if nMenPai == 0 then
			self:MsgBox(selfId,targetId,"#{event_shaolin_0001}")
			return
		end
		self:BeginEvent(self.script_id)
		self:AddText(" #{MenpaiInfo_000}")
		self:AddNumText("Ta xác định muốn bái nhập Thiếu Lâm phái", 6,3)
		self:AddNumText("Ta tạm thời còn không muốn bái nhập Môn phái", 8,1000)
		self:EndEvent()
		self:DispatchEventList(selfId, targetId)
	elseif index == 1 then
		self:MsgBox(selfId, targetId, " #{OBJ_shaolin_0003}")
	elseif index == 6 then
		self:MsgBox(selfId, targetId, " #{MPJN_090728_04}")
	elseif index == 3 then
		if self:GetLevel(selfId) < 10 then
			self:MsgBox(selfId, targetId, "Thiếu hiệp hãy đợi đến cấp 10 rồi đến bái sư học nghệ nhé!")
			return
		end
		self:BeginAddItem()
		self:AddItem(10124000,1)
		self:AddItem(30501001,20,true)
		local ret = self:EndAddItem(selfId)
		if not ret then
			self:MsgBox(selfId, targetId, "  Túi đồ của ngươi không đủ chỗ trống, hãy thu xếp lại rồi đến tìm ta.")
			return
		end
		if self:GetMenPai(selfId) == 9 then
			if not self:LuaFnJoinMenpai(selfId, 0) then return end -- CYS-STARTER
			self:LuaFnSetXinFaLevel(selfId,1,10)
			self:LuaFnSetXinFaLevel(selfId,2,1)
			self:LuaFnSetXinFaLevel(selfId,3,1)
			self:LuaFnSetXinFaLevel(selfId,4,1)
			self:LuaFnSetXinFaLevel(selfId,5,10)
			self:LuaFnSetXinFaLevel(selfId,6,1)
			self:AddItemListToHuman(selfId)
			self:notify_tips(selfId, "Ngươi đã gia nhập Thiếu Lâm phái!")
			self:notify_tips(selfId, "Ngươi nhận được" .. self:GetItemName(10124000) .. "。")
			self:notify_tips(selfId, "Nhận được 20 mai Môn phái Triệu Tập Lệnh.")
			self:CallScriptFunction(210268, "CheckMenPai", selfId)
		end
	elseif index == 100 then
		if self:GetMissionDataEx(selfId, 134) > 0 then
			self:MsgBox(selfId, targetId, "Ngươi đã lĩnh qua rồi.")
			return
		end
		if nMenPai == 9 then
			self:MsgBox(selfId, targetId, "  Ngươi còn chưa gia nhập Môn phái.")
			return
		end
		if nMenPai ~= 0 then
			self:MsgBox(selfId, targetId, "  Ngươi không phải đệ tử bổn môn!")
			return
		end
		self:BeginAddItem()
		self:AddItem(10430010, 1,true)
		self:AddItem(10443010, 1,true)
		local ret = self:EndAddItem(selfId)
		if not ret then
			self:MsgBox(selfId, targetId, "  Túi đồ của ngươi không đủ chỗ trống, hãy thu xếp lại rồi đến tìm ta.")
			return
		end
		self:AddItemListToHuman(selfId)
		self:notify_tips(selfId, "Ngươi nhận được" .. self:GetItemName(10430010) .. "。")
		self:notify_tips(selfId, "Ngươi nhận được" .. self:GetItemName(10443010) .. "。")
		self:SetMissionDataEx(selfId, 134, self:GetDayTime())
	elseif index == 101 then
		if self:GetMissionDataEx(selfId, 135) > 0 then
			self:MsgBox(selfId, targetId, "Ngươi đã lĩnh qua rồi.")
			return
		end
		if nMenPai == 9 then
			self:MsgBox(selfId, targetId, "  Ngươi còn chưa gia nhập Môn phái.")
			return
		end
		if nMenPai ~= 0 then
			self:MsgBox(selfId, targetId, "  Ngươi không phải đệ tử bổn môn!")
			return
		end
		local nRandom = math.random(#MenPaiPet)
		local itemList = MenPaiPet[nRandom]["itemList"]
		if not itemList then
			return
		end
		self:BeginAddItem()
		for i, item in pairs(itemList) do
			self:AddItem(item["id"], item["num"])
		end
		local ret = self:EndAddItem(selfId)
		if not ret then
			self:MsgBox(selfId, targetId, "    Khi tặng ngươi Trân thú, ta cũng muốn tặng ngươi đồ chơi Trân thú và thức ăn của Trân thú, thỉnh chừa ra hai ô trống trong túi đồ rồi hãy đến tìm ta.")
			return
		end
		local Isok, petGUID_H, petGUID_L = self:LuaFnCreatePetToHuman(selfId,MenPaiPet[nRandom]["id"], true)
		if not Isok then
			self:MsgBox(selfId, targetId, "  Ngươi không thể mang thêm Trân Thú nữa. Ngươi có thể chọn thả Trân Thú để trống một ô Trân Thú.#r  Mở giao diện Trân Thú, chọn Trân Thú ngươi muốn vứt bỏ trong danh sách Trân Thú, nhấp vào thả để từ bỏ Trân Thú này.")
			return
		end
		self:notify_tips(selfId, "Ngươi nhận được một con." .. MenPaiPet[nRandom]["name"] .. "。")
		self:MsgBox(selfId, targetId, "  Xem Trân Thú của ngươi đi, ngươi đã nhận được phần thưởng Trân Thú.")
		self:AddItemListToHuman(selfId)
		self:SetMissionDataEx(selfId, 135, self:GetDayTime())
	elseif index == 102 then
		if self:GetMissionDataEx(selfId, 133) > 0 then
			self:MsgBox(selfId, targetId, "    Ngài đã lĩnh qua Môn phái Thời Trang, không thể lĩnh lại lần nữa.")
			return
		end
		if self:GetItemCount(selfId, 10124000) > 0 then
			self:MsgBox(selfId, targetId, "    Ngươi đã có Thời Trang Môn phái, không thể nhận thêm lần nữa.")
			return
		end
		self:BeginAddItem()
		self:AddItem(10124000, 1)
		local ret = self:EndAddItem(selfId)
		if not ret then
			self:MsgBox(selfId, targetId, "  Túi đồ của ngươi không đủ chỗ trống, hãy thu xếp lại rồi đến tìm ta.")
			return
		end
		self:notify_tips(selfId, "Ngươi nhận được" .. self:GetItemName(10124000) .. "。")
		self:AddItemListToHuman(selfId)
		self:SetMissionDataEx(selfId, 133, self:GetDayTime())
	elseif index == 1000 then
		self:BeginUICommand()
		self:EndUICommand()
		self:DispatchUICommand(selfId, 1000)
	end
end
function oshaolin_xuanji:MsgBox(selfId, targetId, msg)
	self:BeginEvent(self.script_id)
	self:AddText(msg)
	self:EndEvent()
	self:DispatchEventList(selfId, targetId)
end
return oshaolin_xuanji