local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oxihu_1_baby = class("oxihu_1_baby", script_base)

function oxihu_1_baby:OnDefaultEvent(selfId, targetId) end

function oxihu_1_baby:OnDie(selfId, killerId) end

return oxihu_1_baby
