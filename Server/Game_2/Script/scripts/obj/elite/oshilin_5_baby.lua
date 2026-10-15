local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oshilin_5_baby = class("oshilin_5_baby", script_base)

function oshilin_5_baby:OnDefaultEvent(selfId, targetId) end

function oshilin_5_baby:OnDie(selfId, killerId) end

return oshilin_5_baby
