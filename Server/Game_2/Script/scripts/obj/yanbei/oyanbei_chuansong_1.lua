local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oyanbei_chuansong_1 = class("oyanbei_chuansong_1", script_base)
oyanbei_chuansong_1.script_id = 019030
oyanbei_chuansong_1.g_city0 = 206
oyanbei_chuansong_1.g_city1 = 224
oyanbei_chuansong_1.g_city2 = 598
oyanbei_chuansong_1.g_city3 = 616
function oyanbei_chuansong_1:OnDefaultEvent(selfId, targetId)
    local strCity0Name = self:CityGetCityName(selfId, self.g_city0)
    local strCity1Name = self:CityGetCityName(selfId, self.g_city1)
    local strCity2Name = self:CityGetCityName(selfId, self.g_city2)
    local strCity3Name = self:CityGetCityName(selfId, self.g_city3)
    self:BeginEvent(self.script_id)
    self:AddText("Có gì ta có thể giúp ngươi của không?")
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

function oyanbei_chuansong_1:OnEventRequest(selfId, targetId, arg, index)
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

return oyanbei_chuansong_1
