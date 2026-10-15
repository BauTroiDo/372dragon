local class = require "class"
local base = require "scripts.obj.cy4.cy4_npc"
local npc = class("cy4_taohuadao_npc07", base)
npc.script_id = 980070
npc.cfg = {name="Hoàng Trí Tâm",faction=13,faction_name="Đào Hoa Đảo",role="mount_guide",mount_shop=413}
return npc
