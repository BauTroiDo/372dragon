local class = require "class"
local define = require "define"
local script_base = require "script_base"
local omeiling_5_baby = class("omeiling_5_baby", script_base)

function omeiling_5_baby:OnDefaultEvent(selfId, targetId) end

function omeiling_5_baby:OnDie(selfId, killerId) end

return omeiling_5_baby
