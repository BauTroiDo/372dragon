local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ojiange_sdby = class("ojiange_sdby", script_base)

function ojiange_sdby:OnDefaultEvent(selfId, targetId) end

function ojiange_sdby:OnDie(selfId, killerId) end

return ojiange_sdby
