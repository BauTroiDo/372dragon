local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oqiongzhou_chuansong_2 = class("oqiongzhou_chuansong_2", script_base)
oqiongzhou_chuansong_2.script_id = 035031
oqiongzhou_chuansong_2.g_city0 = 256
oqiongzhou_chuansong_2.g_city1 = 274
oqiongzhou_chuansong_2.g_city2 = 648
oqiongzhou_chuansong_2.g_city3 = 666
function oqiongzhou_chuansong_2:OnDefaultEvent(selfId, targetId)
    local strCity0Name = self:CityGetCityName(selfId, self.g_city0)
    local strCity1Name = self:CityGetCityName(selfId, self.g_city1)
    local strCity2Name = self:CityGetCityName(selfId, self.g_city2)
    local strCity3Name = self:CityGetCityName(selfId, self.g_city3)
    self:BeginEvent(self.script_id)
    self:AddText("Có gì ta có thể giúp ngươi chăng?")
    if (strCity0Name ~= "") then
        self:AddNumText("Thành Thị 1  " .. strCity0Name, 9, 0)
    end
    if (strCity1Name ~= "") then
        self:AddNumText("Thành Thị 2  " .. strCity1Name, 9, 1)
    end
    if (strCity2Name ~= "") then
        self:AddNumText("Thành Thị 3  " .. strCity2Name, 9, 2)
    end
    if (strCity3Name ~= "") then
        self:AddNumText("Thành Thị 4  " .. strCity3Name, 9, 3)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oqiongzhou_chuansong_2:OnEventRequest(selfId, targetId, arg, index)
    if (index == 0) then
        self:CityMoveToScene(selfId, self.g_city0, 99, 152)
    elseif (index == 1) then
        self:CityMoveToScene(selfId, self.g_city1, 99, 152)
    elseif (index == 2) then
        self:CityMoveToScene(selfId, self.g_city2, 99, 152)
    elseif (index == 3) then
        self:CityMoveToScene(selfId, self.g_city3, 99, 152)
    end
end

return oqiongzhou_chuansong_2
