local class = require "class"
local define = require "define"
local script_base = require "script_base"
local omeiling_1_baby = class("omeiling_1_baby", script_base)

function omeiling_1_baby:OnDefaultEvent(selfId, targetId) end

function omeiling_1_baby:OnDie(selfId, killerId) end

return omeiling_1_baby
