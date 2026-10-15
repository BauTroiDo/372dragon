local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oerhai_2_baby = class("oerhai_2_baby", script_base)

function oerhai_2_baby:OnDefaultEvent(selfId, targetId) end

function oerhai_2_baby:OnDie(selfId, killerId) end

return oerhai_2_baby
