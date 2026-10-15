local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local banghuishouling_die = class("banghuishouling_die", script_base)
-- local gbk = require "wire_charset"
banghuishouling_die.script_id = 999985
--开启场景与活动号
banghuishouling_die.needsceneId = 313
banghuishouling_die.needsactId = 397

banghuishouling_die.openflag = 1
function banghuishouling_die:OnDie(objId,killerId)
end
return banghuishouling_die