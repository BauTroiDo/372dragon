local class = require "class"
local define = require "define"
local script_base = require "script_base"
local onanzhao_2_baby = class("onanzhao_2_baby", script_base)

function onanzhao_2_baby:OnDefaultEvent(selfId, targetId) end

function onanzhao_2_baby:OnDie(selfId, killerId) end

return onanzhao_2_baby
