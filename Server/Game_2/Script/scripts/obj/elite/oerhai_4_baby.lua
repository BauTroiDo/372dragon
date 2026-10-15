local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oerhai_4_baby = class("oerhai_4_baby", script_base)

function oerhai_4_baby:OnDefaultEvent(selfId, targetId) end

function oerhai_4_baby:OnDie(selfId, killerId) end

return oerhai_4_baby
