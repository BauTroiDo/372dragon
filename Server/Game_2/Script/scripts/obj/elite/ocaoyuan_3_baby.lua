local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ocaoyuan_3_baby = class("ocaoyuan_3_baby", script_base)
function ocaoyuan_3_baby:OnDefaultEvent(selfId, targetId) end
function ocaoyuan_3_baby:OnDie(selfId, killerId) end
return ocaoyuan_3_baby
