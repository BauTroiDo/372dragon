local class = require "class"
local base = require "scripts.obj.cy4.cy4_npc"
local npc = class("cy4_congren_npc04", base)
npc.script_id = 980089
npc.cfg = {name="Thất Thúc",faction=14,faction_name="Tuyệt Tình Cốc",role="quest_giver",text="Ta là Thất Thúc, phụ trách nhiệm vụ sư môn của Tuyệt Tình Cốc. Hiện nhiệm vụ sư môn của bổn phái CHƯA mở tại máy chủ này. Trong lúc chờ, ngươi có thể luyện võ, học khinh công, học nghề và sắm toạ kỵ môn phái.",points={{label="Hỏi về việc học võ",x=231,z=170,tip="Vân Kiêu",desc="Hãy tìm Vân Kiêu để học tâm pháp và bí tịch."},{label="Hỏi về khinh công",x=281,z=170,tip="Lăng Xước",desc="Hãy tìm Lăng Xước để học khinh công."},{label="Hỏi về toạ kỵ",x=115,z=249,tip="Lộ Mạn",desc="Hãy tìm Lộ Mạn để mua toạ kỵ môn phái."}}}
return npc
