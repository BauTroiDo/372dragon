local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local city0_building9 = class("city0_building9", script_base)
city0_building9.script_id = 805016
city0_building9.g_BuildingID11 = 10
city0_building9.g_shenyi_scriptId = 64
city0_building9.g_pet_dem_ScriptId = 701603

function city0_building9:OnDefaultEvent(selfId, targetId)
    local guildid = self:GetHumanGuildID(selfId)
    local cityguildid = self:GetCityGuildID(selfId)
    local strText
    if (guildid ~= cityguildid) then
        self:BeginEvent(self.script_id)
        strText = "    Lão Lô Hoàng Liên ta đã từng thề, không phải huynh đệ trong bang ta, người ngoài dù bệnh chết ta cũng không chữa!"
        self:AddText(strText)
        self:EndEvent()
        self:DispatchMissionTips(selfId)
        return
    end
    self:BeginEvent(self.script_id)
    strText = "    Ta là chưởng quầy y xá, thầy thuốc như cha mẹ, huống hồ đều là người trong bang, nếu có hứng thú với y thuật, hãy đến trao đổi nhiều hơn."
    self:AddText(strText)
    if self:CityGetBuildingLevel(selfId, ScriptGlobal.CITY_BUILDING_YISHE) >= 3 then
        self:AddNumText("#GY Tế", 6, 0)
    end
    self:AddNumText("Mua dược phương Chế Dược", 7, 6)
    self:AddNumText("Y xá tửu quán", 11, 7)
    self:CallScriptFunction(define.CITY_BUILDING_ABILITY_SCRIPT, "AddCityLifeAbilityOpt", selfId, self.g_scriptId, self.g_BuildingID11, 8)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function city0_building9:OnEventRequest(selfId, targetId, arg, index)
    if arg == self.g_pet_dem_ScriptId then
        self:CallScriptFunction(self.g_pet_dem_ScriptId, "OnDefaultEvent", selfId, targetId, index)
        return
    end
    if arg == self.g_shenyi_scriptId then
        self:CallScriptFunction(self.g_shenyi_scriptId, "OnEventRequest",  selfId, targetId, index)
        return
    end
    if arg ~= self.g_scriptId then
        self:CallScriptFunction(define.CITY_BUILDING_ABILITY_SCRIPT, "OnDefaultEvent", selfId, targetId, arg, self.script_id,  self.g_BuildingID11)
        return
    end
    if index == 0 then
        self:CallScriptFunction(self.g_shenyi_scriptId, "UpdateEventList", selfId, targetId)
    elseif index == 1 then
        self:CityBuildingChange(selfId, self.g_BuildingID11, 0)
    elseif index == 2 then
        self:CityBuildingChange(selfId, self.g_BuildingID11, 1)
    elseif index == 3 then
        self:CityBuildingChange(selfId, self.g_BuildingID11, 2)
    elseif index == 4 then
        self:CityBuildingChange(selfId, self.g_BuildingID11, 3)
    elseif index == 5 then
        self:CityBuildingChange(selfId, self.g_BuildingID11, 4)
    elseif index == 6 then
        self:BeginUICommand()
        self:UICommand_AddInt(targetId)
        self:UICommand_AddInt(self.g_BuildingID11)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 104)
    elseif index == 7 then
        self:BeginEvent(self.script_id)
        self:AddText("#{City_Intro_YiShe}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif index == 8 then
        self:BeginEvent(self.script_id)
        self:CallScriptFunction(define.CITY_BUILDING_ABILITY_SCRIPT, "OnEnumerate", selfId, targetId, self.g_BuildingID11)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    end
end

return city0_building9
