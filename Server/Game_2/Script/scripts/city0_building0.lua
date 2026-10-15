local class = require "class"
local define = require "define"
local script_base = require "script_base"
local city0_building0 = class("city0_building0", script_base)
city0_building0.script_id = 805007
city0_building0.g_BuildingID15 = 6

function city0_building0:OnDefaultEvent(selfId, targetId)
    local guildid = self:GetHumanGuildID(selfId)
    local cityguildid = self:GetCityGuildID(selfId)
    local strText
    if (guildid ~= cityguildid) then
        self:BeginEvent(self.script_id)
        strText = "    Không phải người của ta, thần binh lợi khí xin kiếu ngoại bán."
        self:AddText(strText)
        self:EndEvent()
        self:DispatchMissionTips(selfId)
        return
    end
    self:BeginEvent(self.script_id)
    strText = "    Ta là chưởng quỹ tiệm vũ khí, bảo kiếm xứng anh hùng, mọi chuyện về danh binh thiên hạ, đều có thể tìm ta, người một nhà mà."
    self:AddText(strText)
    self:AddNumText("Thần Bí Tiệm", 7, 8)
    self:AddNumText("Uỷ thác chế tạo", 6, 9)
    self:AddNumText("Giới thiệu tửu quán", 11, 7)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function city0_building0:OnEventRequest(selfId, targetId, arg, index)
    if index == 1 then
        self:CityBuildingChange(selfId, self.g_BuildingID15, 0)
    elseif index == 2 then
        self:CityBuildingChange(selfId, self.g_BuildingID15, 1)
    elseif index == 3 then
        self:CityBuildingChange(selfId, self.g_BuildingID15, 2)
    elseif index == 4 then
        self:CityBuildingChange(selfId, self.g_BuildingID15, 3)
    elseif index == 5 then
        self:CityBuildingChange(selfId, self.g_BuildingID15, 4)
    elseif index == 6 then
        self:BeginUICommand()
        self:UICommand_AddInt(targetId)
        self:UICommand_AddInt(self.g_BuildingID15)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 104)
    elseif index == 7 then
        self:BeginEvent(self.script_id)
        self:AddText("#{City_Intro_WuJuFang}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif index == 8 then
        self:BeginEvent(self.script_id)
        self:AddText("Chức năng này sắp được mở")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif index == 9 then
        self:BeginEvent(self.script_id)
        self:AddText("Chức năng này sắp được mở")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    end
end

return city0_building0
