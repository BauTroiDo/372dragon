local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oerhai_1_baby = class("oerhai_1_baby", script_base)

function oerhai_1_baby:OnDefaultEvent(selfId, targetId) end

function oerhai_1_baby:OnDie(selfId, killerId) end

return oerhai_1_baby
