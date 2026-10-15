local class = require "class"
local base = require "scripts.obj.cy4.cy4_npc"
local npc = class("cy4_tangmen_npc09", base)
npc.script_id = 980025
npc.cfg = {name="Đường Nhược Hề",faction=11,faction_name="Đường Môn",role="ability_teacher",ability=2,ability_name="Bách Thảo Thức Biện"}
return npc
