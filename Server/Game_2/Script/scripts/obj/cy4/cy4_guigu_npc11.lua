local class = require "class"
local base = require "scripts.obj.cy4.cy4_npc"
local npc = class("cy4_guigu_npc11", base)
npc.script_id = 980044
npc.cfg = {name="Trận Linh Thạch · Địa",faction=12,faction_name="Quỷ Cốc",role="formation_stone",text="Đây là Trận Linh Thạch · Địa của Quỷ Cốc. Ba trận linh thạch Thiên · Địa · Nhân nối với nhau, đệ tử cấp 10 trở lên có thể mượn trận mà dịch chuyển.",stones={{label="Trận Linh Thạch · Thiên",x=39,z=43},{label="Trận Linh Thạch · Nhân",x=160,z=47}}}
return npc
