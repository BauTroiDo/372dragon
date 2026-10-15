local class = require "class"
local define = require "define"
local script_base = require "script_base"
local mantuo_yepopo = class("mantuo_yepopo", script_base)
mantuo_yepopo.script_id = 015043
function mantuo_yepopo:OnDefaultEvent(selfId, targetId)
    self:DispatchShopItem(selfId, targetId, 216)
end

return mantuo_yepopo
