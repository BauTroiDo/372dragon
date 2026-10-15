local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ocaoyuan_1_baby = class("ocaoyuan_1_baby", script_base)
function ocaoyuan_1_baby:OnDefaultEvent(selfId, targetId) end
function ocaoyuan_1_baby:OnDie(selfId, killerId) end
return ocaoyuan_1_baby
