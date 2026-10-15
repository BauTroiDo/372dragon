local class = require "class"
local define = require "define"
local packet_def = require "game.packet"
local script_base = require "script_base"
local Jiebang = class("Jiebang", script_base)
Jiebang.script_id = 998525

local UnbindMats = {
    [7] = 38008210,
    [8] = 38008210
}

function Jiebang:DoUnbind(selfId)
    local scene = self:get_scene()
    if not scene then
        self:notify_tips(selfId, "Cảnh sai")
        return
    end
    local human = scene:get_obj_by_id(selfId)
    if not human then
        self:notify_tips(selfId, "Đối tượng người chơi sai")
        return
    end
    local bag = human:get_prop_bag_container()
    local item = bag:get_item(0)
    if item == nil then
        self:notify_tips(selfId, "Ô đầu không có đạo cụ")
        return
    end
    if not self:IsEquipItem(item:get_index()) then
        self:notify_tips(selfId, "Ô đầu không phải trang bị")
        return
    end
    local req_level = self:GeEquipReqLevel(item:get_index())
    if req_level < 60 then
        self:notify_tips(selfId, "Trang bị chưa đủ cấp 60")
        return
    end
    if not self:LuaFnGetEquipArtisanal(selfId, 0) then
        self:notify_tips(selfId, "Trang bị này không phải đồ thủ công")
        return
    end
    if not item:is_bind() and not item:is_ebind() then
        self:notify_tips(selfId, "Trang bị chưa khóa, khỏi gỡ khóa")
        return
    end
    if self:GetGemEmbededCount(selfId, 0) > 0 then
        self:notify_tips(selfId, "Trang bị đã khảm bảo thạch, không gỡ khóa được")
        return
    end
    if self:LuaFnGetEquipEnhanceLevel(selfId, 0) > 0 then
        self:notify_tips(selfId, "Trang bị đã cường hóa, không gỡ khóa được")
        return
    end
    local equip_data = item:get_equip_data()
    if equip_data:get_diaowen_id() > 0 or equip_data:get_diaowen_material_count() > 0 then
        self:notify_tips(selfId, "Trang bị đã điêu văn, không gỡ khóa được")
        return
    end
    local quality = equip_data:get_quality()
    local mat = UnbindMats[quality]
    if mat == nil then
        self:notify_tips(selfId, "Phẩm chất trang bị này không hỗ trợ gỡ khóa")
        return
    end
    if self:LuaFnGetAvailableItemCount(selfId, mat) <= 0 then
        self:notify_tips(selfId, "Không có nguyên liệu gỡ khóa")
        return
    end
    if not self:LuaFnDelAvailableItem(selfId, mat, 1) then
        self:notify_tips(selfId, "Gỡ khóa thất bại")
        return
    end

    -- 直接解绑，不依赖 LuaFnItemUnbind
    item:set_is_bind(false)
    local msg = packet_def.GCItemInfo.new()
    msg.bagIndex = 0
    msg.item = item:copy_raw_data()
    scene:send2client(selfId, msg)
    self:notify_tips(selfId, "Gỡ khóa thành công")
end

return Jiebang