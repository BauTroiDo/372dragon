local class = require "class"
local define = require "define"
local script_base = require "script_base"
local city0_building11 = class("city0_building11", script_base)
city0_building11.script_id = 805018
city0_building11.g_BuildingID13 = 2

function city0_building11:OnDefaultEvent(selfId, targetId)
    local guildid = self:GetHumanGuildID(selfId)
    local cityguildid = self:GetCityGuildID(selfId)
    local strText
    if (guildid ~= cityguildid) then
        self:BeginEvent(self.script_id)
        strText = "    Không phải người của ta, tửu nhục xin kiếu tiếp đãi."
        self:AddText(strText)
        self:EndEvent()
        self:DispatchMissionTips(selfId)
        return
    end
    self:BeginEvent(self.script_id)
    strText = "    Lão hủ là chưởng quán của tửu điếm, hòa khí sinh tài, mọi người đều là người một bang, có việc gì liên quan đến nấu nướng, cứ tới tìm ta."
    self:AddText(strText)
    self:AddNumText("Mua công thức nấu ăn", 7, 6)
    self:AddNumText("#Giới Thiệu##tửu quán#", 11, 7)
    self:CallScriptFunction(define.CITY_BUILDING_ABILITY_SCRIPT, "AddCityLifeAbilityOpt", selfId, self.script_id, self.g_BuildingID13, 8)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function city0_building11:OnEventRequest(selfId, targetId, arg, index)
    if arg ~= self.script_id then
        self:CallScriptFunction(define.CITY_BUILDING_ABILITY_SCRIPT, "OnDefaultEvent",  selfId, targetId, arg, self.script_id, self.g_BuildingID13)
        return
    end
    if index == 1 then
        self:CityBuildingChange(selfId, self.g_BuildingID13, 0)
    elseif index == 2 then
        self:CityBuildingChange(selfId, self.g_BuildingID13, 1)
    elseif index == 3 then
        self:CityBuildingChange(selfId, self.g_BuildingID13, 2)
    elseif index == 4 then
        self:CityBuildingChange(selfId, self.g_BuildingID13, 3)
    elseif index == 5 then
        self:CityBuildingChange(selfId, self.g_BuildingID13, 4)
    elseif index == 6 then
        self:BeginUICommand()
        self:UICommand_AddInt(targetId)
        self:UICommand_AddInt(self.g_BuildingID13)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 104)
    elseif index == 7 then
        self:BeginEvent(self.script_id)
        self:AddText("#{City_Intro_JiuSi}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif index == 8 then
        self:BeginEvent(self.script_id)
        self:CallScriptFunction(define.CITY_BUILDING_ABILITY_SCRIPT, "OnEnumerate", self, selfId, targetId, self.g_BuildingID13)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    end
end

return city0_building11
