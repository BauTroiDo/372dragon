-- server-impact (CY-Source 15/09/2026): logic kỹ năng dự phòng cho SkillData CY có 技能逻辑ID chưa cài trong skynet GL.
-- Trước đây skillenginer gán skill_0 → chỉ áp các nhãn cfghelper nhận (|生效一次的附加效果N…); nhãn CY mới
-- (附加效果1, 伤害效果, |给目标的基础效果1, 自身获得效果, 变身男buff…) bị bỏ → kỹ năng không có tác dụng.
-- skill_cy_generic = skill_0 + áp mọi cặp (nhãn, DataIndex) thô mà:
--   * nhãn là nhãn impact (có 效果/buff, không phải 几率/集合/陷阱/次数/…),
--   * nhãn KHÔNG nằm trong danh sách cfghelper đã xử lý (skill_cy_generic_known.lua, sinh máy từ cfghelper.lua),
--   * DataIndex có trong StandardImpact.
-- Đích: nhãn nói "自己/自身/给自己/激活/变身…" → người dùng; impact tích cực (影响性质 > 0) mà mục tiêu là địch → người dùng;
-- impact tiêu cực mà mục tiêu không phải địch → bỏ; còn lại → mục tiêu. Nhãn "<X>的概率 / <X>的发生几率" = xác suất % cho <X>.
local class = require "class"
local define = require "define"
local impact = require "scene.skill.impact"
local skill_0 = require "scene.skill.human.skill_0"
local known = require "scene.skill.human.skill_cy_generic_known"
local skill_cy_generic = class("skill_cy_generic", skill_0)

-- menpai-fix (15/09/2026): lualib/class.lua (luaclass) chỉ chép HÀM của lớp cha → trường số/bảng của skill_0
-- (IMPACT_NUMBER = 17, SkillInfoDescriptorIndex) thành nil ở lớp con → skill_0.lua:72 "bad 'for' limit (nil)" mọi lần dùng.
-- Chép mọi trường không phải hàm mà lớp con chưa có. 17 ô = số ô effect_once cfghelper.read_skill_data điền (1..17)
-- ≥ 15 cặp 参数说明/参数值 của SkillData CY → vòng đọc impact phủ đủ mọi ô CY.
for key, value in pairs(skill_0) do
    if type(value) ~= "function" and rawget(skill_cy_generic, key) == nil then
        skill_cy_generic[key] = value
    end
end

local EXCLUDE = {"几率", "概率", "集合", "陷阱", "次数", "数目", "上限", "半径", "时间", "距离", "类型", "百分", "%", "权重",
                 "层数", "脚本", "冷却", "范围", "说明", "宽度", "步长", "技能ID", "阈值", "倍率", "系数"}
local SELF_WORDS = {"自己", "自身", "给自己", "对自己", "激活", "变身", "霸体", "免控", "无敌"}
local IMPACT_WORDS = {"效果", "buff", "BUFF", "Buff"}

local function has_any(s, words)
    for _, w in ipairs(words) do
        if string.find(s, w, 1, true) then
            return true
        end
    end
    return false
end

function skill_cy_generic.is_impact_label(label)
    if type(label) ~= "string" or label == "" then
        return false
    end
    return has_any(label, IMPACT_WORDS) and not has_any(label, EXCLUDE)
end

function skill_cy_generic.is_self_label(label)
    return has_any(label, SELF_WORDS)
end

-- "<X>的概率" / "<X>的发生几率" → X
function skill_cy_generic.prob_base(label)
    if type(label) ~= "string" then
        return nil
    end
    for _, suffix in ipairs({"的发生几率", "的概率", "的几率"}) do
        if #label > #suffix and string.sub(label, -#suffix) == suffix then
            return string.sub(label, 1, #label - #suffix)
        end
    end
    return nil
end

-- danh sách (DataIndex, về_bản_thân, xác_suất) cần áp thêm; tách riêng để test đơn vị
function skill_cy_generic.extra_impacts(raw, config)
    local out = {}
    if type(raw) ~= "table" then
        return out
    end
    local prob = {}
    for _, p in ipairs(raw) do
        local base_label = skill_cy_generic.prob_base(p[1])
        if base_label then
            prob[base_label] = tonumber(p[2])
        end
    end
    for _, p in ipairs(raw) do
        local label, value = p[1], tonumber(p[2])
        if value and value >= 0 and not known[label] and skill_cy_generic.is_impact_label(label) and config[value] then
            out[#out + 1] = {data_index = value, to_self = skill_cy_generic.is_self_label(label), chance = prob[label],
                             stand = tonumber(config[value].stand_flag) or 0, label = label}
        end
    end
    return out
end

function skill_cy_generic:effect_on_unit_once(obj_me, obj_tar, is_critical)
    skill_0.effect_on_unit_once(self, obj_me, obj_tar, is_critical)
    local skill_info = obj_me:get_skill_info()
    local raw = skill_info and skill_info.cy_raw_params
    if not raw then
        return
    end
    local scene = obj_me:get_scene()
    local impactenginer = scene:get_impact_enginer()
    local params = obj_me:get_targeting_and_depleting_params()
    local target_is_enemy = obj_tar and obj_tar ~= obj_me and obj_me:is_enemy(obj_tar)
    for _, e in ipairs(skill_cy_generic.extra_impacts(raw, impactenginer.std_impact_config or {})) do
        if not e.chance or math.random(100) <= e.chance then
            local reciver = obj_tar
            if e.to_self or (e.stand > 0 and target_is_enemy) then
                reciver = obj_me
            elseif e.stand < 0 and not target_is_enemy then
                reciver = nil
            end
            if reciver then
                local imp = impact.new()
                imp:clean_up()
                if impactenginer:init_impact_from_data(e.data_index, imp) then
                    self:register_impact_event(reciver, obj_me, imp, params:get_delay_time(), is_critical)
                end
            end
        end
    end
end

return skill_cy_generic
