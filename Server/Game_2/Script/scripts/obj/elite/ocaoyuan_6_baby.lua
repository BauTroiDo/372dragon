local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ocaoyuan_6_baby = class("ocaoyuan_6_baby", script_base)
function ocaoyuan_6_baby:OnDefaultEvent(selfId, targetId) end
function ocaoyuan_6_baby:OnDie(selfId, killerId) end
return ocaoyuan_6_baby
