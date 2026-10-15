local class = require "class"
local base = require "scripts.obj.cy4.cy4_npc"
local npc = class("cy4_guigu_npc04", base)
npc.script_id = 980037
npc.cfg = {name="Vương Huyền Phong",faction=12,faction_name="Quỷ Cốc",role="quest_giver",text="Ta là Vương Huyền Phong, phụ trách nhiệm vụ sư môn của Quỷ Cốc. Hiện nhiệm vụ sư môn của bổn phái CHƯA mở tại máy chủ này. Trong lúc chờ, ngươi có thể luyện võ, học khinh công, học nghề và sắm toạ kỵ môn phái.",points={{label="Hỏi về việc học võ",x=92,z=55,tip="Lý Kế Long",desc="Hãy tìm Lý Kế Long để học tâm pháp và bí tịch."},{label="Hỏi về khinh công",x=106,z=56,tip="Ngô Bành",desc="Hãy tìm Ngô Bành để học khinh công."},{label="Hỏi về toạ kỵ",x=150,z=150,tip="Tô Cầm",desc="Hãy tìm Tô Cầm để mua toạ kỵ môn phái."}}}
return npc
