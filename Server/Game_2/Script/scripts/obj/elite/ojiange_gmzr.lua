local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ojiange_gmzr = class("ojiange_gmzr", script_base)

function ojiange_gmzr:OnDefaultEvent(selfId, targetId) end

function ojiange_gmzr:OnDie(selfId, killerId) end

return ojiange_gmzr
