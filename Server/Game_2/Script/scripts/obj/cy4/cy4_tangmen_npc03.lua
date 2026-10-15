local class = require "class"
local base = require "scripts.obj.cy4.cy4_npc"
local npc = class("cy4_tangmen_npc03", base)
npc.script_id = 980020
npc.cfg = {name="Đường Nhạc Thiên",faction=11,faction_name="Đường Môn",role="head",text="Ta là Đường Nhạc Thiên, chưởng môn Đường Môn. Bổn phái mới mở cửa thu nhận đệ tử; các sư đệ sư muội cứ chuyên tâm luyện võ, học khinh công và nghề nghiệp của bổn phái. Nhiệm vụ sư môn và cống hiến sẽ được mở sau.",points={{label="Hỏi về việc học võ",x=38,z=75,tip="Đường Nhạc Xung",desc="Hãy tìm Đường Nhạc Xung để học tâm pháp và bí tịch."},{label="Hỏi về khinh công",x=88,z=111,tip="Đường Xuân",desc="Hãy tìm Đường Xuân để học khinh công."},{label="Hỏi về toạ kỵ",x=169,z=33,tip="Đường Tự Cơ",desc="Hãy tìm Đường Tự Cơ để mua toạ kỵ môn phái."}}}
return npc
