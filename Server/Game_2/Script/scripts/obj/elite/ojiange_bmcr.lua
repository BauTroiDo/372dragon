local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ojiange_bmcr = class("ojiange_bmcr", script_base)

function ojiange_bmcr:OnDefaultEvent(selfId, targetId) end

function ojiange_bmcr:OnDie(selfId, killerId) end

return ojiange_bmcr
