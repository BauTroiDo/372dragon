-- packet_domains/cy_combat.lua
-- Lớp gói do CY thêm, KHÔNG thuộc bộ sinh `split_packet.py` (vì vậy để ở file riêng:
-- `core/combat/movement/...` đều mang dòng "由 split_packet.py 自动生成，勿手动修改";
-- sinh lại bộ đó sẽ không xoá file này, chỉ cần giữ dòng `require` trong `services/game/packet.lua`).
--
-- skill-logic-5 (17/09/2026). Vì sao cần:
--   `lualib/cy_four_combat/action_packet.lua` (con rối 离人偶 của 桃花岛) gửi gói `xy_id = 786`
--   qua `scenecore:broadcast → :send2client → skynet.send(agent,"lua","send2client",xy_id,tbl)`.
--   Trong dịch vụ agent, `net:send2client` (lualib/net.lua:180-190) làm
--       local p = self.packets[xyid]; local msg = p.p.new(); setmetatable(data,{__index=msg}); data:bos()
--   nên KHÔNG có lớp mang `xy_id = 786` thì nổ ngay ở `p.p` trên `nil`.
--   Đo trước lượt này (taohua-doll, `Build\Logs\2026-09-17-taohua-doll\71-packet786.txt`, cách đo đúng của
--   `net:register_packets`: duyệt `pairs(game.packet)` đọc GIÁ TRỊ `xy_id`, không grep theo tên):
--   **514 lớp**, 785 = `GCStallItemPrice`, 787 = `CGPetExteriorCollectionRequest`, **786 TRỐNG**.
--
-- Khuôn byte: ba `<i4` liền nhau theo thứ tự `obj_id`, `action_id`, `target_id` (12 byte).
--   [DK] `/home/ubuntu/GameServer/lualib/cy_four_combat/action_packet.lua:1` (bản port gốc của cy_four_combat)
--        ghi: "GCCharDoAction: current GL reader 0x1406830e0, ID 786, three signed int32s";
--        `lualib/cy_four_combat/action_packet.lua` trên server riêng giữ đúng khuôn đó ở `M.bytes`
--        (`string.pack('<i4i4i4', obj_id, action_id, target_id)`).
--   `bostream:writeint` (lualib/iostream.lua:184) dùng `string.pack("i4", n)` = `<i4` trên x86-64
--        ⇒ ba lần `writeint` cho ĐÚNG 12 byte của `M.bytes`, không lệch một byte nào.
--
-- TÊN TRƯỜNG PHẢI GIỮ NGUYÊN (`obj_id` / `action_id` / `target_id`): `net:send2client` không sao chép
-- dữ liệu, nó chỉ gắn metatable rồi gọi `bos` của lớp này trên CHÍNH bảng do `cy_four_combat` dựng.
local M = {}

function M.bind(packet, bistream, bostream, gbk, define)

    -- Hằng XYID. Đặt ở đây, KHÔNG sửa `services/game/packet_ids.lua` (file đó cũng do `split_packet.py` sinh).
    -- `net:register_packets` chỉ phân biệt `type(v) == "table"` (lớp gói) với `type(v) == "number"` (hằng id),
    -- nên thêm hằng ở đây tương đương với thêm vào `packet_ids.lua`.
    packet.XYID_GC_CHAR_DO_ACTION = packet.XYID_GC_CHAR_DO_ACTION or 786

    -- GCCharDoAction — server → client: "vật thể X diễn động tác Y hướng về Z".
    -- cy_four_combat dùng cho con rối 离人偶: action 165 (高唐云散), 166 (劝君酒), 167 (棹歌中流 / thu hồi),
    -- 0 = về tư thế đứng yên.
    packet.GCCharDoAction = {
        xy_id = packet.XYID_GC_CHAR_DO_ACTION,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCCharDoAction })
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.obj_id = 0
            self.action_id = 0
            self.target_id = 0
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.obj_id = stream:readint()
            self.action_id = stream:readint()
            self.target_id = stream:readint()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeint(self.obj_id)
            stream:writeint(self.action_id)
            stream:writeint(self.target_id)
            return stream:get()
        end
    }
end

return M
