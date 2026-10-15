local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oxihu_4_baby = class("oxihu_4_baby", script_base)

function oxihu_4_baby:OnDefaultEvent(selfId, targetId) end

function oxihu_4_baby:OnDie(selfId, killerId) end

return oxihu_4_baby
