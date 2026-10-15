local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oxihu_3_baby = class("oxihu_3_baby", script_base)

function oxihu_3_baby:OnDefaultEvent(selfId, targetId) end

function oxihu_3_baby:OnDie(selfId, killerId) end

return oxihu_3_baby
