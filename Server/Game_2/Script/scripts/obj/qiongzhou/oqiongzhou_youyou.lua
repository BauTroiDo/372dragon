local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oqiongzhou_youyou = class("oqiongzhou_youyou", script_base)
function oqiongzhou_youyou:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Ô ô... nơi này có rất nhiều Cá sấu a, chẳng lẽ Tử Khâm ca ca Thiên Thiên đều sống trong Khuyên cảnh như vậy sao?")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oqiongzhou_youyou:OnDie(selfId, killerId) end

return oqiongzhou_youyou
