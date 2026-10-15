local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oJiaofei_chuansong = class("oJiaofei_chuansong", script_base)
function oJiaofei_chuansong:OnEnterArea(selfId)
    self:CallScriptFunction((400900), "TransferFunc", selfId, 5, 200, 52)
end

function oJiaofei_chuansong:OnTimer(selfId)
    local StandingTime = self:QueryAreaStandingTime(selfId)
    if StandingTime >= 5000 then
        self:OnEnterArea(selfId)
        self:ResetAreaStandingTime(selfId, 0)
    end
end

function oJiaofei_chuansong:OnLeaveArea(selfId)
end

return oJiaofei_chuansong
