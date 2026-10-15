local class = require "class"
local base = require "scripts.obj.cy4.cy4_npc"
local npc = class("cy4_taohuadao_npc03", base)
npc.script_id = 980066
npc.cfg = {name="Lý Trường Cát",faction=13,faction_name="Đào Hoa Đảo",role="guide",sign=500076}
return npc
