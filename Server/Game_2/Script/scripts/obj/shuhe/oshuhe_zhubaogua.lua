local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oshuhe_zhubaogua = class("oshuhe_zhubaogua", script_base)
oshuhe_zhubaogua.script_id = 001192
oshuhe_zhubaogua.g_shoptableindex = 13
function oshuhe_zhubaogua:OnDefaultEvent(selfId, targetId)
    self:DispatchShopItem(selfId, targetId, self.g_shoptableindex)
end

return oshuhe_zhubaogua
