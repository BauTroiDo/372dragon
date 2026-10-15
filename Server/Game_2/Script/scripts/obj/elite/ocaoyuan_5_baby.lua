local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ocaoyuan_5_baby = class("ocaoyuan_5_baby", script_base)
function ocaoyuan_5_baby:OnDefaultEvent(selfId, targetId) end
function ocaoyuan_5_baby:OnDie(selfId, killerId) end
return ocaoyuan_5_baby
