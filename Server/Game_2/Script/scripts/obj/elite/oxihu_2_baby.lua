local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oxihu_2_baby = class("oxihu_2_baby", script_base)

function oxihu_2_baby:OnDefaultEvent(selfId, targetId) end

function oxihu_2_baby:OnDie(selfId, killerId) end

return oxihu_2_baby
