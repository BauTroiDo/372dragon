local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oyanwanggumu_guodihui = class("oyanwanggumu_guodihui", script_base)
oyanwanggumu_guodihui.script_id = 040000
oyanwanggumu_guodihui.g_shoptableindex = 148

function oyanwanggumu_guodihui:OnDefaultEvent(selfId, targetId)
    --self:DispatchShopItem(selfId, targetId, self.g_shoptableindex)
end

return oyanwanggumu_guodihui
