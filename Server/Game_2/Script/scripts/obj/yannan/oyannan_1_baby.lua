local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oyannan_1_baby = class("oyannan_1_baby", script_base)

function oyannan_1_baby:OnDefaultEvent(selfId, targetId) end

function oyannan_1_baby:OnDie(selfId, killerId) end

return oyannan_1_baby
