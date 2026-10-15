local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oerhai_3_baby = class("oerhai_3_baby", script_base)

function oerhai_3_baby:OnDefaultEvent(selfId, targetId) end

function oerhai_3_baby:OnDie(selfId, killerId) end

return oerhai_3_baby
