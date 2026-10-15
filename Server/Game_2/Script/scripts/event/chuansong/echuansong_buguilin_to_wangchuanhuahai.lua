local class = require "class"
local script_base = require "script_base"
local chuan_song = class("chuan_song", script_base)

function chuan_song:on_enter_area(scene, obj)
     -- CYS-NAVMIN 19/09: dich (232,112) canh 574 nam trong tam giac BI CHAN cua navmesh (sau 7.60 o). Nhanh nay hien KHONG toi duoc — cua chan: C2 (tep khong co trong scripts.lua; buguilin_area.ini dung script 400216/400217 cung khong co). MUON MO LAI: SUA TOA DO TRUOC, lay tu nguon co tham quyen (vi tri quai/NPC trong <map>_monster.ini, diem hoi sinh, hay mot dich da kiem), KHONG tu tinh tu .path. Chi tiet: Timeline/handoff/transfer-navmesh.md muc 3.6 + Build/Logs/2026-09-19-transfer-navmesh/97-bai-min.tsv
     self:CallScriptFunction((400900), "TransferFunc", obj:get_obj_id(), 574,232,112)
end

return chuan_song
