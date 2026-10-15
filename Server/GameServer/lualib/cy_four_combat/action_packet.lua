-- GCCharDoAction: client CY/GL co reader ID 786, ba so int32 co dau (obj / action / target).
--
-- taohua-doll 17/09/2026 — HAI loi do duoc tren server that (pass11,
-- Build\Logs\2026-09-17-coord\pass11\w3-doll-c\live\m13\s3820-124206-a1-serverlog.txt):
--
-- 1. [DA SUA O DAY] Ban cu dat ham `msg:bos` NGAY TRONG bang goi. `scenecore:send2client`
--    (services/scene/scenecore.lua:9464) chuyen goi SANG DICH VU KHAC bang `skynet.send`, ma
--    skynet.pack khong serialize duoc `function` => "Unsupport type function to serialize".
--    Loi nem ngay tren duong `hooks.on_use_skill_successfully` (khong duoc bao pcall o
--    obj/character.lua:1054) nen HUY luon lan tung: 3820 棹歌中流 ra `sends = 0`, 26 traceback.
--    Goi PHAI la bang du lieu thuan — chinh agent gan lai `bos` qua metatable cua lop da dang ky:
--    `lualib/net.lua:183-190`  `local p=self.packets[xyid]; setmetatable(data,{__index=p.p.new()}); data:bos()`.
--    (Doi chung: `packet.GCMissionModify.new()` co `rawget(inst,'bos') == nil`, chi 2 truong du lieu.)
--
-- 2. [NGOAI PHAM VI FILE NAY — chua sua duoc] `game.packet` cua server KHONG co lop nao mang
--    `xy_id = 786`. Do that bang cach `net:register_packets` dung (duyet gia tri `xy_id`, khong grep ten):
--    514 lop, 785 = GCStallItemPrice, 787 = CGPetExteriorCollectionRequest, **786 TRONG**.
--    => Du bang co thuan, `net:send2client` van no tiep o `self.packets[786]` = nil trong dich vu agent.
--    Muon bat hoat anh 傀儡 thi phai dang ky lop `GCCharDoAction` (obj_id / action_id / target_id,
--    ba `<i4`, dung ba ten truong nay vi `net:send2client` doc chung qua `__index`) trong
--    `services/game/packet_domains/**` — KHONG thuoc `cy_four_combat`.
--    Trong khi cho: `M.send` TU CHOI gui, tra `false` + ghi log MOT LAN, **khong nem**. Hoat anh la
--    phan trang tri; sat thuong / impact / keo muc tieu cua 3809 / 3820 / 3822 van chay binh thuong.
--    Khi lop duoc dang ky, ham nay tu dong gui lai — khong phai sua them dong nao.
--    Giu `do_action` ton tai la CO Y: `tao.capabilities` doi phuong thuc nay, thieu no thi
--    `phase2.prepare` se `block` han ba chieu 3809 / 3820 / 3822 (con te hon mat hoat anh).
local M = {}

M.XY_ID = 786

function M.new(obj, action, target)
    assert(math.tointeger(obj) and obj > 0 and obj <= 2147483647, 'object ID')
    assert(action == 0 or action == 165 or action == 166 or action == 167, 'verified doll action')
    assert(math.tointeger(target) and target > 0 and target <= 2147483647, 'target ID')
    -- Bang DU LIEU THUAN. Dung dat function vao day (ghi chu 1).
    return {xy_id = M.XY_ID, obj_id = obj, action_id = action, target_id = target}
end

-- Chuoi byte that cua goi. De o day de lop packet dang ky sau nay dung chung mot khuon,
-- va de kiem doi chieu ma khong phai gui goi.
function M.bytes(msg)
    return string.pack('<i4i4i4', msg.obj_id, msg.action_id, msg.target_id)
end

-- Lop packet cho XY_ID da duoc dang ky chua? Kiem y het `net:register_packets` (lualib/net.lua:35-48):
-- duyet `pairs(game.packet)` va doc GIA TRI `xy_id`. Khong grep theo ten lop — ten co the duoc ghep
-- bang string.format nen grep am tinh la ket qua SAI.
function M.writer_registered()
    if M._registered == nil then
        local ok, packet = pcall(require, 'game.packet')
        local found = false
        if ok and type(packet) == 'table' then
            for _, v in pairs(packet) do
                if type(v) == 'table' and v.xy_id == M.XY_ID then
                    found = true
                    break
                end
            end
        end
        M._registered = found
        if not found then
            local oks, skynet = pcall(require, 'skynet')
            if oks and skynet and skynet.logw then
                skynet.logw('[cy_four] bo qua GCCharDoAction: game.packet chua co lop xy_id', M.XY_ID,
                            '- xem lualib/cy_four_combat/action_packet.lua ghi chu 2')
            end
        end
    end
    return M._registered
end

function M.send(obj, action, target)
    local scene = obj:get_scene()
    if not scene or scene:get_obj_by_id(obj:get_obj_id()) ~= obj then return false, 'no_scene' end
    assert(obj._cy_four_summon and obj._cy_four_summon.source_script == 808281, 'owned CY doll required')
    if not M.writer_registered() then return false, 'packet_class_missing' end
    scene:broadcast(obj, M.new(obj:get_obj_id(), action, target), true)
    return true
end

return M
