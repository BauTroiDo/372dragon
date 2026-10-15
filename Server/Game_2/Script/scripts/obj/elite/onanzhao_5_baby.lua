local class = require "class"
local define = require "define"
local script_base = require "script_base"
local onanzhao_5_baby = class("onanzhao_5_baby", script_base)

function onanzhao_5_baby:OnDefaultEvent(selfId, targetId) end

function onanzhao_5_baby:OnDie(selfId, killerId) end

return onanzhao_5_baby
