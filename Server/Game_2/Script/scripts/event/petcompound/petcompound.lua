--珍兽繁殖
local class = require "class"
local script_base = require "script_base"
local petcompound = class("petcompound", script_base)

function petcompound:OnDefaultEvent(selfId, targetId)
    self:LuaFnCallPetCompoundUI(selfId, targetId, 150)
end

function petcompound:OnEnumerate()
end

return petcompound