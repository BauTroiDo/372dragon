local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ocaoyuan_2_baby = class("ocaoyuan_2_baby", script_base)
function ocaoyuan_2_baby:OnDefaultEvent(selfId, targetId) end
function ocaoyuan_2_baby:OnDie(selfId, killerId) end
return ocaoyuan_2_baby
