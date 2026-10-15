local class = require "class"
local define = require "define"
local script_base = require "script_base"
local onanzhao_1_baby = class("onanzhao_1_baby", script_base)

function onanzhao_1_baby:OnDefaultEvent(selfId, targetId) end

function onanzhao_1_baby:OnDie(selfId, killerId) end

return onanzhao_1_baby
