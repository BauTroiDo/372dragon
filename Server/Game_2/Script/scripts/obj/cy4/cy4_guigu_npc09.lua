local class = require "class"
local base = require "scripts.obj.cy4.cy4_npc"
local npc = class("cy4_guigu_npc09", base)
npc.script_id = 980042
npc.cfg = {name="Trận Linh Thạch · Thiên",faction=12,faction_name="Quỷ Cốc",role="formation_stone",text="Đây là Trận Linh Thạch · Thiên của Quỷ Cốc. Ba trận linh thạch Thiên · Địa · Nhân nối với nhau, đệ tử cấp 10 trở lên có thể mượn trận mà dịch chuyển.",stones={{label="Trận Linh Thạch · Nhân",x=160,z=47},{label="Trận Linh Thạch · Địa",x=95,z=141}}}
return npc
