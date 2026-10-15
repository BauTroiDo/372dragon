local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ojingji_Npc_1 = class("ojingji_Npc_1", script_base)
ojingji_Npc_1.script_id = 125011
ojingji_Npc_1.g_eventList = {}
ojingji_Npc_1.g_shoptableindex = 14

function ojingji_Npc_1:OnDefaultEvent(selfId, targetId)
    self:DispatchShopItem(selfId, targetId, self.g_shoptableindex)
end

return ojingji_Npc_1
