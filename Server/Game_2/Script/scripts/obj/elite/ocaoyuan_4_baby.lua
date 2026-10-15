local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ocaoyuan_4_baby = class("ocaoyuan_4_baby", script_base)
function ocaoyuan_4_baby:OnDefaultEvent(selfId, targetId) end
function ocaoyuan_4_baby:OnDie(selfId, killerId) end
return ocaoyuan_4_baby
