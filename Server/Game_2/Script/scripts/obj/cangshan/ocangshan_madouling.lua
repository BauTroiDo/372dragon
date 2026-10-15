local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ocangshan_madouling = class("ocangshan_madouling", script_base)
ocangshan_madouling.script_id = 025007
ocangshan_madouling.g_shoptableindex = 147
function ocangshan_madouling:OnDefaultEvent(selfId, targetId)
   -- self:DispatchShopItem(selfId, targetId, self.g_shoptableindex)
end

return ocangshan_madouling
