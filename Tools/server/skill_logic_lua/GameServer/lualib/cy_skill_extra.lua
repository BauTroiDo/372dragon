-- skill-logic (CY-Source 16/09/2026): 20 ô nhãn CY mà logic kỹ năng ĐÃ CÀI không đọc.
--
-- Đo bằng Build/Logs/2026-09-16-skill-logic/scripts/03-unread-labels.py (kỹ năng 15 phái, cấp kỹ năng 1–4):
--   logic 0   skill_0    |生效一次的附加效果（对自己）  ×4  — 454 含笑半步癫 (星宿), impact 21733
--   logic 80  skill_80   |生效一次的附加效果            ×4  — 347 飞龙在天 (丐帮), impact 21634–21637
--   logic 260 skill_260  给自己的buff                  ×4  — 544 定海神针 (逍遥), impact 54899
--   logic 840 skill_840  瞬移BUFFid                    ×4  — 4516 荡千军 (绝情谷), impact 49583
--   logic 704 skill_704  新增效果id / 效果作用对象      ×2+2 — 2005 中冲剑·无助1级 (大理), 2040 灭此朝食·缓行1级 (少林)
--
-- cfghelper:read_skill_data không có nhãn nào trong số này nên giá trị bị bỏ; các module trên chỉ đọc
-- t.impacts/t.descriptor. Ở đây đọc thẳng t.cy_raw_params (cặp nhãn/giá trị thô của SkillData CY).
-- Năm nhãn này cũng được thêm vào skill_cy_generic_known.lua để lớp generic KHÔNG áp lại (tránh gấp đôi).
--
-- 效果作用对象: CY ghi 1 cho cả hai dòng dùng 新增效果id; [SL] 1 = bản thân, khác = mục tiêu
-- (không có mã native cho logic 704 trong tlbb15 — LogicManager<SkillLogic_T,691>::Init không có ô 705).
local impact = require "scene.skill.impact"

local M = {}

M.SELF, M.TARGET = 'self', 'target'

-- nhãn → đích cố định
M.EXTRA = {
    ['|生效一次的附加效果（对自己）'] = M.SELF,
    ['|生效一次的附加效果'] = M.TARGET,
    ['给自己的buff'] = M.SELF,
    ['新增效果id'] = 'by_object',            -- đích lấy từ ô 效果作用对象
    ['瞬移BUFFid'] = 'teleport',             -- impact thuấn di cho bản thân, toạ độ = điểm đến
}

-- nhãn chỉ là tham số của nhãn khác (không phải impact)
M.AUX = {['效果作用对象'] = true}

function M.value(skill_info, label)
    local raw = skill_info and skill_info.cy_raw_params
    if type(raw) ~= "table" then
        return nil
    end
    for _, p in ipairs(raw) do
        if p[1] == label then
            return tonumber(p[2])
        end
    end
    return nil
end

-- Logic có đặc tả riêng (cy_skill_logic_spec) tự lo nhãn của nó → không áp thêm ở đây,
-- nếu không 瞬移BUFFid (logic 841) và 给自己的buff (logic 206) sẽ bị áp hai lần.
function M.has_spec(skill_info)
    local id = skill_info and skill_info.get_logic_id and skill_info:get_logic_id()
    if id == nil then
        return false
    end
    local ok, spec = pcall(require, "cy_skill_logic_spec")
    return ok and type(spec) == "table" and spec[id] ~= nil
end

-- danh sách {data_index, đích} cần áp thêm; tách riêng để test đơn vị
function M.list(skill_info)
    local out = {}
    local raw = skill_info and skill_info.cy_raw_params
    if type(raw) ~= "table" or M.has_spec(skill_info) then
        return out
    end
    for _, p in ipairs(raw) do
        local to = M.EXTRA[p[1]]
        local v = tonumber(p[2])
        if to and v and v >= 0 then
            if to == 'by_object' then
                to = (M.value(skill_info, '效果作用对象') == 1) and M.SELF or M.TARGET
            end
            out[#out + 1] = {data_index = v, to = to, label = p[1]}
        end
    end
    return out
end

-- áp các ô trên. `logic` = module logic kỹ năng (để dùng register_impact_event), `dest` = điểm đến cho 'teleport'.
function M.apply(logic, obj_me, obj_tar, is_critical, dest)
    local skill_info = obj_me:get_skill_info()
    local list = M.list(skill_info)
    if #list == 0 then
        return 0
    end
    local scene = obj_me:get_scene()
    local engine = scene and scene:get_impact_enginer()
    if not engine then
        return 0
    end
    local params = obj_me:get_targeting_and_depleting_params()
    local n = 0
    for _, e in ipairs(list) do
        local reciver = (e.to == M.TARGET) and obj_tar or obj_me
        if e.to == 'teleport' then
            reciver = obj_me
        end
        if reciver then
            local imp = impact.new()
            imp:clean_up()
            if engine:init_impact_from_data(e.data_index, imp) then
                if e.to == 'teleport' then
                    local pos = dest
                    if not pos then
                        local p = params:get_target_position()
                        if p and p.x and p.y and not (p.x == 0 and p.y == 0) then
                            pos = {x = p.x, y = p.y}
                        end
                    end
                    local lg = engine:get_logic(imp)
                    if pos and lg and lg.set_impact_x then
                        lg:set_impact_x(imp, pos.x)
                        lg:set_impact_y(imp, pos.y)
                    elseif not pos then
                        goto continue
                    end
                end
                logic:register_impact_event(reciver, obj_me, imp, params:get_delay_time(), is_critical)
                n = n + 1
            end
        end
        ::continue::
    end
    return n
end

return M
