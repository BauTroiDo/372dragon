local skynet = require "skynet"
local class = require "class"
local define = require "define"
local base = require "scene.skill.base"
local skill_2 = require "scene.skill.human.skill_2"
local impact = require "scene.skill.impact"
local skill_840 = class("skill_840", skill_2)

function skill_840:get_instant_transport_impact(skill_info)
    local v = skill_info:get_instant_transport_impact()
    if v == nil or v < 0 then   -- skill-logic: SkillData CY 4516 dùng nhãn 瞬移BUFFid, cfghelper không đọc
        v = require("cy_skill_extra").value(skill_info, "瞬移BUFFid")
    end
    return v
end

-- 荡千军 (Đãng Thiên Quân, Tuyệt Tình Cốc). Mô tả gốc (SkillData 35642): "瞬移至指定位置并在该位置
-- 放置半径6米的刀域，并对终点6米范围内最多3名敌方目标造成直接伤害和2秒麻痹，同时增加持续20秒的刀印效果".
-- Trong gói CY, 5724 chỉ là chiêu KÍCH HOẠT (không có nhóm động tác); đòn chém thật là
-- 5771 荡千军（副） (động tác 11096 + hiệu ứng, 目标逻辑 4 = vùng quanh bản thân, 60678 + 60835 + 60735)
-- do Serverhook gọi sau khi thuấn di; Đao Vực là vật thể bẫy (SpecialObjData) sống 10 s tại điểm đáp.
-- Bản port này làm đúng chuỗi đó:
--   1. activate_once: áp impact thuấn di (瞬移效果 = 61148, logic 9) lên CHÍNH MÌNH, toạ độ = điểm đến
--      (ưu tiên đơn vị mục tiêu, dừng cách DUNG_CACH m; không có thì điểm chỉ định).
--   2. Sau TRE_PHO ms (đã tới nơi): đặt Đao Vực (bẫy DAO_VUC, hiệu ứng vòng 10 s, chưa có hiệu ứng
--      cộng thêm) rồi tự dùng chiêu 5771 qua đường chuẩn (character:do_use_skill) để client phát động
--      tác/hiệu ứng và server áp hiệu ứng lên tối đa 3 địch quanh điểm đến.
--   Hiệu ứng 效果N của chính 5724 (nếu còn trong bảng) vẫn được áp như skill_2 để không mất dữ liệu.
-- Chưa port: các cộng thêm trong Đao Vực (+5% chính xác với người chơi, hoàn hồi chiêu 扫千机/制六合,
-- lan cứng đờ 10%) và +1 Đao Ý khi khống chế trúng.

local CHIEU_PHO = 5771
local DAO_VUC = 2102        -- SpecialObjData: 荡千军刀域, loại 4, 10 s, bán kính 6, không kích hoạt
local DUNG_CACH = 1.0
local TRE_PHO = 15          -- đơn vị 10 ms (skynet.timeout) = 150 ms, sau 动作时间 100 ms của 5724
local THU_LAI_TOI_DA = 3
local LOG = true

local function log(...)
    if LOG then
        skynet.logi("[skill_840]", ...)
    end
end

local function hop_le(pos)
    return pos ~= nil and pos.x ~= nil and pos.y ~= nil and not (pos.x == 0 and pos.y == 0)
end

local function diem_den(obj_me, params)
    local tar_id = params:get_target_obj()
    if tar_id and tar_id ~= define.INVAILD_ID and tar_id ~= obj_me:get_obj_id() then
        local obj_tar = obj_me:get_specific_obj_in_same_scene_by_id(tar_id)
        if obj_tar and obj_tar.get_world_pos then
            local me, tp = obj_me:get_world_pos(), obj_tar:get_world_pos()
            local dx, dy = tp.x - me.x, tp.y - me.y
            local d = math.sqrt(dx * dx + dy * dy)
            if d <= DUNG_CACH then
                return nil, "da_o_sat"
            end
            local k = (d - DUNG_CACH) / d
            return { x = me.x + dx * k, y = me.y + dy * k }, "muc_tieu"
        end
    end
    local pos = params:get_target_position()
    if hop_le(pos) then
        return { x = pos.x, y = pos.y }, "vi_tri"
    end
    return nil, "khong_co"
end

local function gom_hieu_ung(skill_info)
    local ra, seen = {}, {}
    local function them(v)
        if type(v) == "number" and v > 0 and not seen[v] then
            seen[v] = true
            ra[#ra + 1] = v
        end
    end
    local desc = skill_info:get_descriptor() or {}
    for i = 1, 3 do
        them(desc[string.format("效果%d", i)])
    end
    local imps = skill_info.impacts or {}
    local once = imps.effect_once or {}
    for i = 1, 17 do
        them(once[i])
    end
    them(once.target)
    return ra
end

-- Đặt Đao Vực tại điểm đáp (vật thể bẫy sống 10 s, chỉ hiệu ứng vòng).
local function dat_dao_vuc(obj_me, diem)
    local ok, trap = pcall(obj_me.skill_create_obj_specail, obj_me, { x = diem.x, y = diem.y }, DAO_VUC, 5724)
    if not ok then
        log("dao vuc LOI:", trap)
        return nil
    end
    log("dao vuc", DAO_VUC, "obj=", trap and trap:get_obj_id(), "tai", diem.x, diem.y)
    return trap
end

-- Phát chiêu phụ 5771 sau khi đã tới nơi; thử lại vài lần nếu còn bận động tác.
local function phat_chieu_pho(obj_me, scene, tar_id, dest, lan)
    if not obj_me:is_alive() or obj_me:get_scene() ~= scene then
        log("bo chieu pho: nguoi dung chet/roi scene")
        return
    end
    if lan == 1 then
        dat_dao_vuc(obj_me, dest)
    end
    local ok, ret = pcall(obj_me.do_use_skill, obj_me, CHIEU_PHO, tar_id, dest, 0, obj_me:get_guid())
    if not ok then
        log("chieu pho LOI:", ret)
        return
    end
    log("chieu pho", CHIEU_PHO, "lan", lan, "ket qua", ret)
    if ret == define.OPERATE_RESULT.OR_BUSY and lan < THU_LAI_TOI_DA then
        skynet.timeout(TRE_PHO, function() phat_chieu_pho(obj_me, scene, tar_id, dest, lan + 1) end)
    end
end

function skill_840:activate_once(obj_me)
    local skill_info = obj_me:get_skill_info()
    local params = obj_me:get_targeting_and_depleting_params()
    local value = self:get_instant_transport_impact(skill_info)
    local dest, why = diem_den(obj_me, params)
    local me = obj_me:get_world_pos()
    local tar_id = params:get_target_obj()
    log("activate_once skill=", skill_info:get_skill_id(), "impact=", value, "tar=", tar_id,
        "me=", me.x, me.y, "dest=", dest and dest.x, dest and dest.y, why)
    local scene = obj_me:get_scene()
    if dest and type(value) == "number" and value > 0 then
        local impactenginer = scene:get_impact_enginer()
        local imp = impact.new()
        local ok = impactenginer:init_impact_from_data(value, imp)
        local logic = impactenginer:get_logic(imp)
        if ok and logic and logic.set_impact_x then
            logic:set_impact_x(imp, dest.x)
            logic:set_impact_y(imp, dest.y)
            self:register_impact_event(obj_me, obj_me, imp, define.MIN_DELAY_TIME, false)
            log("da dang ky thuan di", value, "->", dest.x, dest.y)
        else
            log("KHONG dang ky duoc thuan di: init=", ok, "logic=", logic ~= nil)
        end
    end
    local ret = base.activate_once(self, obj_me)
    -- chuỗi sau: Đao Vực + đòn chém 5771 tại điểm đến (không thuấn di thì làm tại chỗ)
    local diem = dest or { x = me.x, y = me.y }
    skynet.timeout(TRE_PHO, function() phat_chieu_pho(obj_me, scene, tar_id, diem, 1) end)
    return ret
end

function skill_840:effect_on_unit_once(obj_me, obj_tar, is_critical)
    local skill_info = obj_me:get_skill_info()
    local params = obj_me:get_targeting_and_depleting_params()
    local scene = obj_me:get_scene()
    local impactenginer = scene:get_impact_enginer()
    local ds = gom_hieu_ung(skill_info)
    if #ds == 0 then
        return
    end
    log("effect_on_unit_once tar=", obj_tar:get_obj_id(), "impacts=", table.concat(ds, ","), "delay=", params:get_delay_time())
    for _, value in ipairs(ds) do
        local imp = impact.new()
        impactenginer:init_impact_from_data(value, imp)
        self:register_impact_event(obj_tar, obj_me, imp, params:get_delay_time(), is_critical)
    end
end

log("module loaded")
return skill_840
