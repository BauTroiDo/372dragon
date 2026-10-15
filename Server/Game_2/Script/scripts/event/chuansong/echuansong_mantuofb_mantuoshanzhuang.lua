local class = require "class"
local define = require "define"
local script_base = require "script_base"
local echuansong_mantuofb_mantuoshanzhuang = class("echuansong_mantuofb_mantuoshanzhuang", script_base)
function echuansong_mantuofb_mantuoshanzhuang:OnEnterArea(selfId)
    self:CallScriptFunction((400900), "TransferFunc", selfId, 184, 129, 108)
end

function echuansong_mantuofb_mantuoshanzhuang:OnTimer(selfId)
    StandingTime = self:QueryAreaStandingTime(selfId)
    if StandingTime >= 5000 then
        self:OnEnterArea(selfId)
        self:ResetAreaStandingTime(selfId, 0)
    end
end

function echuansong_mantuofb_mantuoshanzhuang:OnLeaveArea(selfId)
end

return echuansong_mantuofb_mantuoshanzhuang
