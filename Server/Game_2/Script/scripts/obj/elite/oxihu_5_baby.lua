local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oxihu_5_baby = class("oxihu_5_baby", script_base)

function oxihu_5_baby:OnDefaultEvent(selfId, targetId) end

function oxihu_5_baby:OnDie(selfId, killerId) end

return oxihu_5_baby
