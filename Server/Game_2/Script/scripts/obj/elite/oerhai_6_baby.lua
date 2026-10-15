local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oerhai_6_baby = class("oerhai_6_baby", script_base)

function oerhai_6_baby:OnDefaultEvent(selfId, targetId) end

function oerhai_6_baby:OnDie(selfId, killerId) end

return oerhai_6_baby
