-- skill-logic (CY-Source 16/09/2026): logic impact 115 — "sát thương bằng N % đòn ĐÁNH THƯỜNG".
--
-- Đây là cách CY diễn đạt các mô tả kiểu "造成100%普通攻击伤害" / "造成80%普攻伤害" trong tip kỹ năng:
-- KHÔNG phải một ô tham số của StandardImpact (không có cột "% phổ công"), mà là một dòng StandardImpact
-- riêng mang 逻辑ID = 115 với tham số 0 = 伤害量缩放系数.
--
-- MÃ CY (tlbb15 Server, tháo mã ở Build/re/skill-logic/stdimpact115_*.asm.txt — chỉ đọc file, không chạy binary):
--   StdImpact115_T::InitFromData @0xa5f204: imp[+0x2c] = round(修正步长0 × imp.level) + 参数值0
--       (+0x2c là ô sát thương ĐẦU TIÊN của _OWN_IMPACT — chính ô mà StdImpact003_T::RefixPowerByRate
--        @0xa440c8 nhân với (100+rate)/100, theo bằng chứng của impact-data).
--   StdImpact115_T::OnActive  @0xa5f2f8:
--       1. mục tiêu còn sống, có cảnh; tìm người gây (GetSpecificObjInSameSceneByID theo imp[+0x0c]);
--       2. loại đối tượng người gây phải ∈ {1,2,3} (human/pet/monster) — `(type-1) u< 3`;
--       3. CombatCore::Reset; ImpactCore::InitImpactFromData(core, **DataIndex 0**, &newImp, mục_tiêu, 0)
--          — dòng 0 của StandardImpact là "普通攻击的伤害效果，这一行永远不能删除或者改变.这是缺省效果";
--       4. nếu newImp có 逻辑ID == 3 → CombatCore::Reset + GetResultImpact(cc, người_gây, mục_tiêu, &newImp, 0x64);
--       5. newImp[+8] = imp[+8] (chép ID kỹ năng) rồi EventCore::RegisterImpactEvent(cảnh, mục_tiêu, người_gây, newImp, 0, -1).
--   StdImpact115_T::IsOverTimed @0xa5f538 và ::IsIntervaled @0xa5f53e đều `mov eax,0; ret` → hiệu ứng tức thời.
--
-- [SL] Bước nhân 伤害量缩放系数: bản tlbb15 truyền HẰNG 0x64 (=100) cho GetResultImpact và không đọc lại
-- imp[+0x2c] trong bốn phương thức của lớp này. Nhưng dữ liệu CY đặt hệ số khác nhau theo cấp
-- (撼岳群攻效果 43918–43923 = 100/110/125/145/170/200) và tip ghi rõ "N % 普通攻击伤害", nên ở đây áp hệ số
-- bằng ĐÚNG phép nhân của RefixPowerByRate. Hệ số 100 cho kết quả trùng khít bản tlbb15.
local class = require "class"
local base = require "scene.skill.impact_logic.base"
local impact = require "scene.skill.impact"
local combat_core = require "scene.skill.combat_core"
local std_impact_003 = require "scene.skill.impact_logic.std_impact_003"

local std_impact_115 = class("std_impact_115", base)

std_impact_115.ID = 115
std_impact_115.NORMAL_ATTACK_DATA_INDEX = 0        -- dòng StandardImpact của đòn đánh thường (CY: DataIndex 0)
std_impact_115.SCALE_LABEL = "伤害量缩放系数"

function std_impact_115:is_over_timed()
    return false
end

function std_impact_115:is_intervaled()
    return false
end

function std_impact_115:get_scale(imp)
    local v = tonumber(imp.params and imp.params[self.SCALE_LABEL])
    if v == nil or v <= 0 then
        return 100
    end
    return v
end

-- tách riêng để test đơn vị: dựng impact đánh thường đã qua CombatCore + nhân hệ số
function std_impact_115:make_normal_attack(imp, obj, caster)
    local scene = obj:get_scene()
    local engine = scene and scene:get_impact_enginer()
    if not engine then
        return nil
    end
    local new = impact.new()
    new:clean_up()
    if not engine:init_impact_from_data(self.NORMAL_ATTACK_DATA_INDEX, new) then
        return nil
    end
    if new:get_logic_id() == std_impact_003.ID then
        local cc = combat_core.new()
        cc:get_result_impact(caster, obj, new)
        local scale = self:get_scale(imp)
        if scale ~= 100 then
            std_impact_003.refix_power_by_rate(std_impact_003, new, scale - 100)
        end
    end
    new:set_caster_obj_id(imp:get_caster_obj_id())
    new:set_skill_id(imp:get_skill_id())
    new:set_skill_level(imp:get_skill_level())
    if imp:is_critical_hit() then
        new:mark_critical_hit_flag()
    end
    return new
end

function std_impact_115:on_active(imp, obj)
    if not imp or not obj or not obj:is_alive() then
        return
    end
    local scene = obj:get_scene()
    if not scene then
        return
    end
    local caster_id = imp:get_caster_obj_id()
    local caster = caster_id and scene:get_obj_by_id(caster_id)
    if not caster then
        return
    end
    local t = caster.get_obj_type and caster:get_obj_type()
    if not (t == "human" or t == "pet" or t == "monster") then     -- native: (GetObjType()-1) u< 3
        return
    end
    local new = self:make_normal_attack(imp, obj, caster)
    if not new then
        return
    end
    -- native đăng ký sự kiện impact lên mục tiêu; phía Lua, std_impact_003.on_active là chỗ
    -- biến các ô 物理伤害/魔法伤害/… đã tính thành obj:on_damages (đúng một nhịp, không trễ).
    std_impact_003.on_active(std_impact_003, new, obj)
end

return std_impact_115
