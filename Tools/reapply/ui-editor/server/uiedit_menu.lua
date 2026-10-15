-- CYS-UIEDIT 20/09/2026 (nhanh `ui-editor-2`) — NUA SERVER cua "NPC de mo cac khung con loi".
--
-- Cai dat: chep tep nay vao  Game_2/Script/scripts/obj/uiedit_menu.lua
-- roi them MOT dong vao `odali_zhongzhipai1:OnDefaultEvent`. Xem `README_vi.md` canh ben.
--
-- DIEU LAM CHO CACH NAY AN TOAN BAT THUONG: server o day KHONG CO MOT DONG LOGIC NAO.
-- No chi cung cap NHAN. Muc menu nao chua dau hieu `@UIEDIT:<TenKhung>` deu bi CLIENT nuot ngay
-- trong `CUIDataPool::SendSelectEvent` va khong bao gio di ra server — nen KHONG can
-- `OnEventRequest`, khong can `script_id` rieng, va khong co duong nao de mot cu bam sai lam hong
-- du lieu nhan vat.
--
-- Vi sao phai di duong nay chu khong dung `OpenWindow()`: `OpenWindow("X")` cua Lua chi day su kien
-- `OPEN_WINDOW`; khung nao khong tu `RegisterEvent("OPEN_WINDOW")` va so khop `arg0` thi khong bao
-- gio mo. Chi 45/2.043 tep `.lua` cua `InterfaceFolder` co duong do, va trong danh sach khung dich
-- cua bo sua thi **0 khung** co. Dung bai hoc cua loi bam `Q`: khung nam im vi chua ai mo duoc no.

local M = {}

-- ===================================================================================
-- CONG TAC. `false` = tep nay khong lam gi ca, ke ca khi da chep vao server.
-- Tat di khi choi binh thuong ma khong muon thay menu nay tren NPC trong trot.
-- ===================================================================================
M.enabled = true

-- Khong co cong GM: quyet dinh 20/09 cua nguoi dung/dieu phoi, VA NO CO DIEU KIEN —
-- day la server RIENG cua MOT nguoi, khong co nguoi choi khac. Them mot cong quyen la
-- them mot thu co the hong ma khong doi lai duoc gi.
-- >>> NEU SAU NAY CO NGUOI CHOI KHAC THI PHAI THEM CONG, hoac dat M.enabled = false. <<<

-- `MAX_EVENT_LIST_ITEM_COUNT` = 16 (Src/Shared/Common/ScriptCommandStruct.h:114) va dong `AddText`
-- cua chinh NPC cung tinh la mot muc, nen danh sach nay KHONG duoc qua ~12 dong.
-- Danh sach day du 56 khung van phai dung `PgDn`/`PgUp` trong game.
--
-- Thu tu lay tu `Tools/reapply/ui-editor/data/ui_edit_targets.tsv`: chin widget dau chiu TOAN BO
-- lop DBC (~10.000 gia tri tran, rieng ba dong dau la 8.939 = 89,4 %), roi hai nhom "chi keo o moi
-- sua duoc" da ghim.
M.targets = {
    { "ActionSkill",            "Khung ky nang (4.737 cho tran, o 154,8 px)" },
    { "CommonSkill",            "Ky nang thuong (2.829 cho tran, o 96,8 px)" },
    { "ActionSkillsStudy",      "Hoc ky nang (1.373 cho tran, o 160,8 px)" },
    { "LifeSkill",              "Ky nang sinh hoat (o 68,9 px - hep nhat)" },
    { "Fenxian",                "Phan tuyen (384 cho tran)" },
    { "MiniMap",                "Ban do nho (368 cho tran)" },
    { "Synthesize",             "Che tao (o 250 px)" },
    { "LoginCreateRole",        "Tao nhan vat (toc/mat, o 111 px)" },
    { "SelfEquip",              "Hang 17 the - MOI o dung 35 px" },
    { "SeventhFestivalTopList", "That tich: 2 o can +30 va +27 px" },
    { "ValentineRoseTopList",   "Hoa hong: 2 o can +51 va +24 px" },
}

-- `type = 12` va mot `index` rieng cho tung dong: chep dung hinh dang loi goi da chay that o
-- `cy4_training_npc.lua` (`npc:AddNumText("Mua bi tich va yeu quyet", 12, 10)`). Hai so nay chi de
-- khung hoi thoai phan biet cac dong voi nhau; chung KHONG bao gio den server vi client da nuot muc.
local FIRST_INDEX = 7001

-- Goi GIUA `BeginEvent` va `EndEvent` cua NPC chu. Khong tu mo/dong su kien, khong tu dispatch.
function M.menu(npc, selfId)
    if not M.enabled then return end
    for i, t in ipairs(M.targets) do
        npc:AddNumText(t[2] .. " @UIEDIT:" .. t[1], 12, FIRST_INDEX + i)
    end
end

return M
