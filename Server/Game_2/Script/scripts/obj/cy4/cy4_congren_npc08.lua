local class = require "class"
local base = require "scripts.obj.cy4.cy4_npc"
local npc = class("cy4_congren_npc08", base)
npc.script_id = 980092
npc.cfg = {name="Lộ Nguyên",faction=14,faction_name="Tuyệt Tình Cốc",role="mount_guide",mount_shop=414}
return npc
