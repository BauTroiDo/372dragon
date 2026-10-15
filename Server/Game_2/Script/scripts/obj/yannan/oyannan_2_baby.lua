local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oyannan_2_baby = class("oyannan_2_baby", script_base)

function oyannan_2_baby:OnDefaultEvent(selfId, targetId) end

function oyannan_2_baby:OnDie(selfId, killerId) end

return oyannan_2_baby
