local class = require "class"
local base = require "scripts.obj.cy4.cy4_npc"
local npc = class("cy4_tangmen_npc08", base)
npc.script_id = 980024
npc.cfg = {name="Đường Thanh Thu",faction=11,faction_name="Đường Môn",role="quest_giver",text="Ta là Đường Thanh Thu, phụ trách nhiệm vụ sư môn của Đường Môn. Hiện nhiệm vụ sư môn của bổn phái CHƯA mở tại máy chủ này. Trong lúc chờ, ngươi có thể luyện võ, học khinh công, học nghề và sắm toạ kỵ môn phái.",points={{label="Hỏi về việc học võ",x=38,z=75,tip="Đường Nhạc Xung",desc="Hãy tìm Đường Nhạc Xung để học tâm pháp và bí tịch."},{label="Hỏi về khinh công",x=88,z=111,tip="Đường Xuân",desc="Hãy tìm Đường Xuân để học khinh công."},{label="Hỏi về toạ kỵ",x=169,z=33,tip="Đường Tự Cơ",desc="Hãy tìm Đường Tự Cơ để mua toạ kỵ môn phái."}}}
return npc
