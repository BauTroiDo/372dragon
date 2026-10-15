local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ocaoyun_Boss = class("ocaoyun_Boss", script_base)
ocaoyun_Boss.script_id = 311011
function ocaoyun_Boss:OnDie(selfId, killerId) end

function ocaoyun_Boss:OnCharacterTimer(selfId, dataId, nowtime) end

return ocaoyun_Boss
