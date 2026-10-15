local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oshilin_2_baby = class("oshilin_2_baby", script_base)

function oshilin_2_baby:OnDefaultEvent(selfId, targetId) end

function oshilin_2_baby:OnDie(selfId, killerId) end

return oshilin_2_baby
