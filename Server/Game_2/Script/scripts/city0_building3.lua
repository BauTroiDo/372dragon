local class = require "class"
local define = require "define"
local script_base = require "script_base"
local city0_building3 = class("city0_building3", script_base)
city0_building3.script_id = 805008
city0_building3.g_BuildingID4 = 11

function city0_building3:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddNumText("Cửa hàng công thức", 7, 6)
    self:CallScriptFunction(define.CITY_BUILDING_ABILITY_SCRIPT,"AddCityLifeAbilityOpt", selfId, self.script_id, self.g_BuildingID4, 7)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function city0_building3:OnEventRequest(selfId, targetId, arg, index)
    if arg ~= self.script_id then
        self:CallScriptFunction(define.CITY_BUILDING_ABILITY_SCRIPT, "OnDefaultEvent",selfId, targetId, self.script_id, self.g_BuildingID4)
        return
    end
    if index == 1 then
        self:CityBuildingChange(selfId, self.g_BuildingID4, 0)
    elseif index == 2 then
        self:CityBuildingChange(selfId, self.g_BuildingID4, 1)
    elseif index == 3 then
        self:CityBuildingChange(selfId, self.g_BuildingID4, 2)
    elseif index == 4 then
        self:CityBuildingChange(selfId, self.g_BuildingID4, 3)
    elseif index == 5 then
        self:CityBuildingChange(selfId, self.g_BuildingID4, 4)
    elseif index == 6 then
        self:BeginUICommand()
        self:UICommand_AddInt(targetId)
        self:UICommand_AddInt(self.g_BuildingID4)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 104)
    elseif index == 7 then
        self:BeginEvent(self.script_id)
        self:CallScriptFunction(define.CITY_BUILDING_ABILITY_SCRIPT, "OnEnumerate", self, selfId, targetId, self.g_BuildingID4)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    end
end

return city0_building3
