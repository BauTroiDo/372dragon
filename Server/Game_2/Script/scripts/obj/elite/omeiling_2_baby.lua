local class = require "class"
local define = require "define"
local script_base = require "script_base"
local omeiling_2_baby = class("omeiling_2_baby", script_base)

function omeiling_2_baby:OnDefaultEvent(selfId, targetId) end

function omeiling_2_baby:OnDie(selfId, killerId) end

return omeiling_2_baby
