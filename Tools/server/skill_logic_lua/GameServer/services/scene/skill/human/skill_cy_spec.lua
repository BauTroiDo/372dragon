-- skill-logic (CY-Source 16/09/2026): bộ chạy logic kỹ năng CY theo đặc tả dữ liệu (lualib/cy_skill_logic_spec.lua).
--
-- Vì sao cần: skillenginer GL không có 91 技能逻辑ID của CY; server-impact cho chúng rơi về scene.skill.human.skill_cy_generic
-- (skill_0 + áp mọi ô nhãn impact CY lên "đích đoán theo nhãn"). Generic đúng phần lớn ô nhưng KHÔNG biết:
--   * ô nào phải lên BẢN THÂN còn ô nào lên MỤC TIÊU khi nhãn không chứa 自己/自身;
--   * ô xác suất kiểu 中毒几率% / 召唤概率% (generic chỉ nhận hậu tố 的概率/的发生几率);
--   * quét AOE có số người + bán kính riêng (对周围生效目标人数, 傀儡周围生效人数, 次目标个数…);
--   * bẫy (陷阱id, 脚下生成陷阱ID…), biến thân theo giới tính (变身男/女buff), giảm hồi chiêu, thuấn di,
--     hệ số theo số 魂 của 恶人谷.
-- Module này đọc nhãn 参数说明 của chính SkillData CY (skill_info.cy_raw_params do cfghelper lưu) và làm đúng
-- các việc trên theo đặc tả; nhãn nào đặc tả không nói tới vẫn để lớp generic xử lý như cũ.
--
-- An toàn: mọi thao tác phụ đều bọc pcall; thiếu API/thiếu dòng StandardImpact thì bỏ qua, không ném lỗi
-- (bẫy đã gặp: một traceback trong effect_on_unit_once làm kỹ năng "trừ MP, đặt hồi chiêu rồi sập").
--
-- skill-logic-3 (17/09/2026) thêm năm khối: `multi_hit` (204 六把飞剑 + hệ số giảm dần theo số lần trúng),
-- `lifesteal` (149 hút máu theo sát thương THỰC), `chain` (769 chuỗi lan theo nhịp dẫn), `state`
-- (144 phát dòng trạng thái mà SkillData không trỏ tới) và `trap.per_target/chance_ladder` (736 ba mức tóe).
-- Trạng thái nhiều nhịp KHÔNG được để trên `self`: skillenginer chỉ tạo MỘT đối tượng logic cho mỗi
-- 技能逻辑ID và dùng chung cả cảnh (skillenginer.lua:576) — nó nằm trong lualib/cy_skill_chain.lua.
--
-- skill-logic-4 (17/09/2026): khối `trap` gọi thêm `scene.special_obj.trap:activate_at_once` sau khi tạo bẫy
-- — ô `是否即刻生效一次` của SpecialObjData (bẫy 3064 「万箭齐发」 của logic 736 có 陷阱专用标记 = 0 nên
-- không có đường nổ nào khác). Xem Docs/specs/server/skill-logic_vi.md mục 15.
--
-- skill-logic-5 (17/09/2026): khối `trap` thêm ô `descriptor` — gán `obj._custom_descriptor` cho bẫy vừa tạo
-- (trap.lua:19-33 ưu tiên bảng này hơn `data.descriptor`), để ô `效果N` của bẫy lấy theo CẤP của chiêu.
-- Dùng cho 736 万箭齐发: bẫy 3064 có `效果1 = -1` trong bảng — và bảng CY cũng thế — vì "100% 万箭齐发伤害"
-- của tip là dòng `伤害效果` của đúng cấp đang dùng (37316…37331). Xem mục 17 của đặc tả.
-- Cùng lượt: khối `resist_cast` (208 中冲剑·刃影) — mỗi hệ mà kháng của mục tiêu không cao hơn 减抗 của
-- bản thân thì gửi thêm ô `附加效果1` của chiêu 六脉神剑 hệ đó, lấy ở CÙNG cấp (đọc lúc chạy qua
-- skillenginer, không ghi cứng ID).
local skynet = require "skynet"
local class = require "class"
local define = require "define"
local impact = require "scene.skill.impact"
local skill_0 = require "scene.skill.human.skill_0"
local skill_cy_generic = require "scene.skill.human.skill_cy_generic"
local spec_table = require "cy_skill_logic_spec"
-- skill-summon 17/09: thực thể triệu hồi (图腾/召唤物). Nạp bằng pcall — nếu module này hỏng thì CHỈ mất
-- phần triệu hồi, không kéo theo cả skill_cy_spec (skillenginer sẽ bỏ đăng ký cả 76 logic nếu require ném).
local ok_summon, summon = pcall(require, "cy_skill_summon")
if not ok_summon then
    skynet.logi("[skill_cy_spec] khong nap duoc cy_skill_summon", summon)
    summon = nil
end
-- skill-logic-3 17/09: chuỗi lan theo nhịp (769), hút máu theo sát thương thực (149), hệ số giảm dần (204).
-- Nạp bằng pcall vì cùng lý do với cy_skill_summon.
local ok_chain, chain = pcall(require, "cy_skill_chain")
if not ok_chain then
    skynet.logi("[skill_cy_spec] khong nap duoc cy_skill_chain", chain)
    chain = nil
end

local skill_cy_spec = class("skill_cy_spec", skill_cy_generic)

-- class.lua (luaclass) chỉ chép HÀM của lớp cha → chép tay các trường (IMPACT_NUMBER…), xem menpai-fix mục 2.
for key, value in pairs(skill_cy_generic) do
    if type(value) ~= "function" and rawget(skill_cy_spec, key) == nil then
        skill_cy_spec[key] = value
    end
end
for key, value in pairs(skill_0) do
    if type(value) ~= "function" and rawget(skill_cy_spec, key) == nil then
        skill_cy_spec[key] = value
    end
end

skill_cy_spec.spec_table = spec_table

local INVALID = define.INVAILD_ID

-- skill-logic-5: ghi log MỘT LẦN cho mỗi khoá (đúng cách `cy_four_combat/engine.lua bridge:descriptor` làm).
-- Không đặt trên `self`: skillenginer dùng chung MỘT đối tượng logic cho cả cảnh (bẫy 13.10).
local logged = {}
local function log_once(key, ...)
    if logged[key] then
        return
    end
    logged[key] = true
    skynet.logi(...)
end

local function num(v)
    return tonumber(v)
end

-- giá trị của một ô 参数说明 theo nhãn chính xác
local function param(raw, label)
    if type(raw) ~= "table" or label == nil then
        return nil
    end
    for _, p in ipairs(raw) do
        if p[1] == label then
            return num(p[2])
        end
    end
    return nil
end

-- MỌI giá trị của cùng một nhãn (799 có hai ô 生效一次给傀儡加效果 trong cùng một dòng)
local function param_all(raw, label)
    local out = {}
    if type(raw) ~= "table" or label == nil then
        return out
    end
    for _, p in ipairs(raw) do
        if p[1] == label then
            local v = num(p[2])
            if v ~= nil then
                out[#out + 1] = v
            end
        end
    end
    return out
end

-- <nhãn hoặc số> → số
local function value_of(raw, v)
    if type(v) == "number" then
        return v
    end
    return param(raw, v)
end

function skill_cy_spec:get_spec(skill_info)
    local id = skill_info and skill_info.get_logic_id and skill_info:get_logic_id()
    return id and self.spec_table[id] or nil
end

-- skill_0 mặc định gửi ô 1 = impacts.self cho MỤC TIÊU khi effect_once[1] rỗng, và gửi mọi ô
-- |生效一次的附加效果N cho mục tiêu. Đặc tả có thể chuyển vài ô sang bản thân → chặn ở đây, áp lại ở dưới.
function skill_cy_spec:get_activate_once_impact_by_index(skill_info, index)
    local sp = self:get_spec(skill_info)
    if sp and sp.self_idx then
        for _, i in ipairs(sp.self_idx) do
            if i == index then
                return INVALID
            end
        end
    end
    if sp and sp.teleport and sp.teleport.idx == index then
        return INVALID              -- ô thuấn di được áp riêng (kèm toạ độ) ở apply_teleport
    end
    local value = skill_info:get_activate_once_impact_by_index(index)
    if not value and index == 1 and not sp then
        local imps = skill_info:get_activate_once_impacts()
        value = imps and imps.self
    end
    return value or INVALID
end

function skill_cy_spec:get_activate_each_tick_impact_by_index(skill_info, index)
    local sp = self:get_spec(skill_info)
    if sp and sp.tick_self_idx then
        for _, i in ipairs(sp.tick_self_idx) do
            if i == index then
                return INVALID
            end
        end
    end
    return skill_info:get_activate_each_tick_impact_by_index(index) or INVALID
end

-- ------------------------------------------------------------------ tiện ích
function skill_cy_spec:send(obj_me, reciver, data_index, is_critical, opt)
    if not reciver or type(data_index) ~= "number" or data_index < 0 then
        return false
    end
    local scene = obj_me:get_scene()
    local engine = scene and scene:get_impact_enginer()
    if not engine then
        return false
    end
    local imp = impact.new()
    imp:clean_up()
    if not engine:init_impact_from_data(data_index, imp) then
        return false
    end
    opt = opt or {}
    if opt.duration and opt.duration > 0 then
        imp:set_continuance(opt.duration)
    end
    if opt.rate and opt.rate ~= 100 then
        local dmg = require "scene.skill.impact_logic.std_impact_003"
        if imp:get_logic_id() == dmg.ID then
            for _, key in ipairs(dmg.enum_DAMAGE_TYPE_RATE) do
                imp:add_rate_params(key, opt.rate - 100)
            end
        end
    end
    if opt.pos then
        local logic = engine:get_logic(imp)
        if logic and logic.set_impact_x then
            logic:set_impact_x(imp, opt.pos.x)
            logic:set_impact_y(imp, opt.pos.y)
        end
    end
    local params = obj_me:get_targeting_and_depleting_params()
    self:register_impact_event(reciver, obj_me, imp, params:get_delay_time(), is_critical)
    return true
end

function skill_cy_spec:roll(raw, chance)
    if chance == nil then
        return true
    end
    local p = value_of(raw, chance)
    if p == nil or p <= 0 then
        return p == nil
    end
    return math.random(100) <= p
end

-- quét đơn vị quanh một điểm, lọc theo phe, giới hạn số lượng
function skill_cy_spec:scan_side(obj_me, center, radius, count, side)
    local scene = obj_me:get_scene()
    if not scene or not center then
        return {}
    end
    local ok, list = pcall(scene.scan, scene, {
        obj = obj_me, scene = scene, x = center.x, y = center.y,
        radious = radius or 5, target_logic_by_stand = 1, check_can_view = true,
    })
    if not ok or type(list) ~= "table" then
        return {}
    end
    local out = {}
    for _, nb in ipairs(list) do
        if self:is_character_obj(nb:get_obj_type()) and nb:is_alive() then
            local enemy = obj_me:is_enemy(nb)
            local take = (side == 'enemy' and enemy) or (side == 'ally' and not enemy) or side == nil or side == 'any'
            if take then
                out[#out + 1] = nb
                if count and #out >= count then
                    break
                end
            end
        end
    end
    return out
end

-- số tập ID (IDCollections) mà đối tượng đang mang impact — dùng chung với condition_cy của menpai-fix
function skill_cy_spec:has_collection(obj, collection_id)
    if type(collection_id) ~= "number" or collection_id < 0 then
        return false
    end
    local ok, cond = pcall(require, "scene.skill.condition_cy")
    if not ok or not cond or not cond.count_impacts then
        return false
    end
    local ok2, n = pcall(cond.count_impacts, obj, collection_id)
    return ok2 and (n or 0) > 0
end

local function world_pos(obj)
    local ok, p = pcall(obj.get_world_pos, obj)
    return ok and p or nil
end

-- con rối 离人偶 của 桃花岛 (cy_four_combat giữ thực thể này) — dùng cho aoe around='doll' và impacts to='doll'
function skill_cy_spec:doll_obj(obj_me)
    local ok, cb = pcall(require, "cy_four_combat.callbacks")
    local doll_id = ok and cb and cb.get_doll_id and cb.get_doll_id(obj_me) or -1
    if doll_id and doll_id > 0 then
        local ok2, obj = pcall(obj_me.get_specific_obj_in_same_scene_by_id, obj_me, doll_id)
        if ok2 and obj then
            return obj
        end
    end
    return nil
end

function skill_cy_spec:doll_pos(obj_me)
    local obj = self:doll_obj(obj_me)
    return obj and world_pos(obj) or nil
end

function skill_cy_spec:dest_pos(obj_me, sp)
    local params = obj_me:get_targeting_and_depleting_params()
    local to = sp and sp.teleport and sp.teleport.to
    if to == 'doll' then
        local ok, cb = pcall(require, "cy_four_combat.callbacks")
        local doll = ok and cb and cb.get_doll_id and cb.get_doll_id(obj_me) or -1
        if doll and doll > 0 then
            local obj = obj_me:get_specific_obj_in_same_scene_by_id(doll)
            if obj then
                return world_pos(obj)
            end
        end
        return nil
    end
    if to == 'target' then
        local tid = params:get_target_obj()
        if tid and tid ~= INVALID and tid ~= obj_me:get_obj_id() then
            local obj = obj_me:get_specific_obj_in_same_scene_by_id(tid)
            if obj then
                return world_pos(obj)
            end
        end
        return nil
    end
    local pos = params:get_target_position()
    if pos and pos.x and pos.y and not (pos.x == 0 and pos.y == 0) then
        return {x = pos.x, y = pos.y}
    end
    return nil
end

-- ------------------------------------------------------------------ các khối của đặc tả
function skill_cy_spec:apply_impacts(obj_me, obj_tar, is_critical, raw, list, first)
    for _, e in ipairs(list or {}) do
        local values = e.all and param_all(raw, e.label) or {param(raw, e.label)}
        -- to='doll' (skill-logic-3): gửi cho CHÍNH con rối; chưa có rối thì về bản thân như trước
        local to_self = (e.to == 'self') or (e.to == 'doll')
        local reciver = obj_tar
        if e.to == 'doll' then
            reciver = self:doll_obj(obj_me) or obj_me
        elseif e.to == 'self' then
            reciver = obj_me
        end
        for _, v in ipairs(values) do
            if v and v >= 0 and (not to_self or first) and self:roll(raw, e.chance) then
                local rate = nil
                if e.rate_add then
                    local add = value_of(raw, e.rate_add)
                    rate = add and (100 + add) or nil
                end
                self:send(obj_me, reciver, v, is_critical,
                          {duration = value_of(raw, e.duration), rate = rate})
            end
        end
    end
end

function skill_cy_spec:apply_aoe(obj_me, obj_tar, is_critical, raw, sp, first)
    if not first then
        return
    end
    for _, e in ipairs(sp.aoe or {}) do
        local v = param(raw, e.label)
        local pass = true
        if e.only_critical then
            local flag = value_of(raw, e.only_critical)
            pass = is_critical and (flag == nil or flag > 0)
        end
        if v and v >= 0 and pass and self:roll(raw, e.chance) then
            local center = (e.around == 'target') and world_pos(obj_tar)
                or (e.around == 'doll') and (self:doll_pos(obj_me) or world_pos(obj_me))
                or world_pos(obj_me)
            local cnt = value_of(raw, e.count)
            local rad = value_of(raw, e.radius) or 5
            if cnt == nil or cnt < 0 then
                cnt = 6
            end
            local rate = nil
            if e.rate_add then                      -- 799: "对效果1伤害的修正" → hệ số = 100 + giá trị ô
                local add = value_of(raw, e.rate_add)
                rate = add and (100 + add) or nil
            end
            for _, nb in ipairs(self:scan_side(obj_me, center, rad, cnt, e.side)) do
                self:send(obj_me, nb, v, is_critical, {rate = rate})
            end
        end
    end
end

function skill_cy_spec:apply_trap(obj_me, obj_tar, raw, sp, first, tick)
    for _, e in ipairs(sp.trap or {}) do
        -- per_target (skill-logic-3 736): đặt bẫy cho TỪNG mục tiêu trúng, không chỉ mục tiêu đầu
        if (e.tick or false) == (tick or false) and (first or e.per_target) then
            local v = param(raw, e.label)
            local chance = e.chance
            if e.chance_ladder then
                -- 736 万箭齐发: lần tóe thứ k dùng mức xác suất thứ k, tối đa `max` lần trong MỘT lượt
                self._trap_n = self._trap_n or {}
                local n = self._trap_n[e.label] or 0
                if n >= (e.max or #e.chance_ladder) or not e.chance_ladder[n + 1] then
                    v = nil
                else
                    chance = e.chance_ladder[n + 1]
                end
            end
            if v and v > 0 and self:roll(raw, chance) then
                if e.chance_ladder then
                    self._trap_n[e.label] = (self._trap_n[e.label] or 0) + 1
                end
                local pos = (e.at == 'target') and world_pos(obj_tar)
                    or (e.at == 'dest') and self:dest_pos(obj_me, sp)
                    or (e.at == 'doll') and (self:doll_pos(obj_me) or world_pos(obj_me))
                    or world_pos(obj_me)
                if pos then
                    local ok, obj = pcall(obj_me.skill_create_obj_specail, obj_me, {x = pos.x, y = pos.y}, v,
                                         obj_me:get_skill_info():get_skill_id())
                    if ok and obj and e.register_ms then
                        pcall(self.register_active_obj, self, obj, obj_me, e.register_ms,
                              obj_me:get_skill_info():get_skill_id())
                    end
                    -- skill-logic-5 17/09: ô hiệu ứng của bẫy lấy theo CẤP của chiêu, không lấy từ bảng.
                    -- `trap.lua:19-33` (`get_impact` / `impact_activate_odds`) ưu tiên `obj._custom_descriptor`
                    -- trước `data.descriptor`; `std_impact_543` đã dùng đúng kiểu này cho 飞剑 của 归一剑.
                    -- Vì sao phải làm ở Lua (trap-data mục 4(c)): một dòng SpecialObjData chỉ có MỘT ô `效果1`,
                    -- trong khi tip 2901 nói "100% 万箭齐发伤害" = dòng `伤害效果` của CHÍNH cấp đang dùng
                    -- (37316…37331, mỗi cấp một ID). Ghi cứng vào bảng sẽ đúng 1 cấp và sai 15 cấp còn lại.
                    -- PHẢI đặt TRƯỚC `activate_at_once` — bẫy 3064 nổ ngay trong lời gọi đó.
                    if ok and obj and e.descriptor then
                        local d = {}
                        for key, lab in pairs(e.descriptor) do
                            local dv = value_of(raw, lab)
                            if dv and dv >= 0 then
                                d[key] = dv
                            end
                        end
                        if next(d) ~= nil then
                            obj._custom_descriptor = d
                            log_once('trap' .. tostring(v) .. ':' .. tostring(d['效果1']),
                                     "[skill_cy_spec] bay", v, "mang _custom_descriptor 效果1 =", d['效果1'])
                        end
                    end
                    -- skill-logic-4 17/09: ô `是否即刻生效一次` của SpecialObjData. Bẫy 3064 「万箭齐发」
                    -- (của 2901, logic 736) có 陷阱专用标记 = 0 nên KHÔNG có đường nổ nào khác.
                    -- Chỉ gọi ở đây (nơi chính ta tạo bẫy) để không đổi hành vi các bẫy do đường khác đặt.
                    if ok and obj then
                        pcall(function()
                            local trap_logic = require "scene.special_obj.trap"
                            if trap_logic and trap_logic.activate_at_once then
                                trap_logic:activate_at_once(obj)
                            end
                        end)
                    end
                    if not ok then
                        skynet.logi("[skill_cy_spec] tao bay loi", v, obj)
                    end
                end
            end
        end
    end
end

-- skill-logic-5 (17/09/2026) — 208 中冲剑·刃影 (大理 826).
-- Ô 附加效果1 của CHÍNH chiêu con, ở CÙNG cấp với chiêu đang tung. Đọc lúc chạy, không ghi cứng ID nào:
-- một dòng của 6 chiêu 六脉神剑 có 16 cấp, ghi cứng sẽ đúng một cấp và sai 15 cấp còn lại.
-- `require` đặt trong hàm để không tạo vòng nạp với skillenginer (nó nạp chính module này).
function skill_cy_spec:child_skill_impact(skill_id, level, label)
    local ok, id = pcall(function()
        local se = require("skillenginer"):getinstance()
        local tmpl = se.get_skill_template and se:get_skill_template(skill_id)
        if not tmpl then
            return nil
        end
        local info_id = se:get_skill_info_id_by_level(tmpl, level)
        local info = info_id and se:get_skill_info(info_id)
        return info and param(info.cy_raw_params, label)
    end)
    if ok and type(id) == "number" and id > 0 then
        return id
    end
    return nil
end

-- "命中后，目标每有一种抗性不高于自身对应减抗，则对目标释放一次对应属性的六脉神剑技能".
-- "抗性" = `obj_tar:get_defence_<hệ>()`, "自身对应减抗" = `obj_me:get_reduce_def_<hệ>()` — đúng cặp mà
-- `combat_core:cold/fire/light/poison_damage` dùng (`resit = defence - reduce_def`). Server chỉ có bốn
-- `get_reduce_def_*` nên ánh xạ là 4 hệ, xem note của dòng [208] trong cy_skill_logic_spec.
function skill_cy_spec:apply_resist_cast(obj_me, obj_tar, is_critical, sp)
    local rc = sp.resist_cast
    if not rc or not obj_tar then
        return
    end
    local level = 1
    local ok_lv, lv = pcall(function()
        local p = obj_me.get_targeting_and_depleting_params and obj_me:get_targeting_and_depleting_params()
        return p and p.get_skill_level and p:get_skill_level()
    end)
    if ok_lv and type(lv) == "number" and lv >= 1 then
        level = math.floor(lv)
    end
    for _, e in ipairs(rc.by_elem or {}) do
        local ok, hit, def, red = pcall(function()
            local fd, fr = obj_tar[e.defence], obj_me[e.reduce]
            if type(fd) ~= "function" or type(fr) ~= "function" then
                return false            -- thiếu API (quái/thú) → bỏ hệ đó, không ném
            end
            local d, r = fd(obj_tar), fr(obj_me)
            return type(d) == "number" and type(r) == "number" and d <= r, d, r
        end)
        local id = (ok and hit) and self:child_skill_impact(e.skill, level, rc.impact_label) or nil
        if id then
            self:send(obj_me, obj_tar, id, is_critical)
        end
        -- một dòng cho mỗi (hệ, kết quả) trong đời tiến trình — đủ để đo live mà không làm ngập log
        log_once('rc' .. tostring(e.elem) .. ':' .. tostring(ok and hit) .. ':' .. tostring(id),
                 "[skill_cy_spec] 208 he", e.elem, "抗性", def, "减抗", red, "cap", level,
                 "chieu", e.skill, "->", id or (ok and hit and "khong doc duoc 附加效果1" or "bo"))
    end
end

function skill_cy_spec:apply_gender(obj_me, is_critical, raw, sp, first)
    if not first or not sp.gender then
        return
    end
    -- giới tính = human:get_model(): script_base.lua:9944 HumanZhuanXing (đổi giới tính) lật model 0 ↔ 1
    local ok, model = pcall(function() return obj_me.get_model and obj_me:get_model() end)
    local label = (ok and model == 1) and sp.gender.female or sp.gender.male
    local v = param(raw, label)
    if v == nil or v < 0 then                 -- không đọc được model → dùng ô nam
        v = param(raw, sp.gender.male)
    end
    self:send(obj_me, obj_me, v, is_critical)
end

function skill_cy_spec:apply_cooldown(obj_me, is_critical, raw, sp, first)
    if not first then
        return
    end
    local cr = sp.cooldown_reduce
    if cr then
        local id = value_of(raw, cr.id)
        local ms = value_of(raw, cr.ms)
        if id and id >= 0 and ms and ms > 0 and obj_me.update_cool_down_by_cool_down_id then
            pcall(obj_me.update_cool_down_by_cool_down_id, obj_me, id, ms)
        end
    end
    local cc = sp.cooldown_on_crit
    if cc and is_critical then
        local lo, hi = value_of(raw, cc.min), value_of(raw, cc.max)
        local cd_id = obj_me:get_skill_info():get_cool_down_id()
        if lo and hi and hi >= lo and cd_id and obj_me.update_cool_down_by_cool_down_id then
            pcall(obj_me.update_cool_down_by_cool_down_id, obj_me, cd_id, math.random(lo, hi) * 1000)
        end
    end
end

function skill_cy_spec:apply_teleport(obj_me, obj_tar, is_critical, raw, sp, first)
    local tp = sp.teleport
    if not tp or not first then
        return
    end
    local v = tp.label and param(raw, tp.label)
    if v == nil and tp.idx then
        v = obj_me:get_skill_info():get_activate_once_impact_by_index(tp.idx)
    end
    v = num(v)
    if v == nil or v < 0 then
        return
    end
    local pos = self:dest_pos(obj_me, sp)
    if not pos then
        return
    end
    if tp.keep then
        local keep = value_of(raw, tp.keep) or 0
        local me = world_pos(obj_me)
        if me and keep > 0 then
            local dx, dy = pos.x - me.x, pos.y - me.y
            local d = math.sqrt(dx * dx + dy * dy)
            if d > keep then
                local k = (d - keep) / d
                pos = {x = me.x + dx * k, y = me.y + dy * k}
            end
        end
    end
    local reciver = (tp.on == 'target') and obj_tar or obj_me
    self:send(obj_me, reciver, v, is_critical, {pos = pos})
end

-- số impact thuộc tập (không chỉ có/không) — PublicA::xyzServerScanTargetIsImpactInCollectionEx
function skill_cy_spec:count_collection(obj, collection_id)
    if type(collection_id) ~= "number" or collection_id < 0 then
        return 0
    end
    local ok, cond = pcall(require, "scene.skill.condition_cy")
    if not ok or not cond or not cond.count_impacts then
        return 0
    end
    local ok2, n = pcall(cond.count_impacts, obj, collection_id)
    return (ok2 and n) or 0
end

-- 恶人谷: đếm số loại 魂 mà mục tiêu (mặc định) hoặc BẢN THÂN (on = 'self') đang mang → hệ số cho impact gốc
function skill_cy_spec:apply_souls(obj_me, obj_tar, is_critical, raw, sp)
    local s = sp.souls
    if not s then
        return
    end
    local holder = (s.on == 'self') and obj_me or obj_tar
    local n = 0
    if s.count_by == 'each' then                      -- một tập gộp: đếm SỐ impact trong tập
        for _, setlabel in ipairs(s.sets or {}) do
            n = n + self:count_collection(holder, param(raw, setlabel))
        end
        n = math.min(n, 3)
    else
        for _, setlabel in ipairs(s.sets or {}) do
            if self:count_collection(holder, param(raw, setlabel)) > 0 then
                n = n + 1
            end
        end
    end
    if s.min_sets and n < s.min_sets then
        return
    end
    local base = param(raw, s.base)
    if base and base >= 0 then
        local mult = n > 0 and s.mult and value_of(raw, s.mult[n]) or nil
        self:send(obj_me, obj_tar, base, is_critical, {rate = mult})
    end
    for _, ps in ipairs(s.per_set or {}) do
        if self:count_collection(holder, param(raw, ps.set)) > 0 then
            self:send(obj_me, obj_tar, param(raw, ps.label), is_critical)
        end
    end
end

function skill_cy_spec:apply_souls_pick(obj_me, obj_tar, is_critical, raw, sp, first)
    local s = sp.souls_pick
    if not s or not first then
        return
    end
    local n = 0
    for _, setlabel in ipairs(s.sets or {}) do
        if self:count_collection(obj_me, param(raw, setlabel)) > 0 then
            n = n + 1
        end
    end
    for _, cid in ipairs(s.set_ids or {}) do          -- tập ghi thẳng (dòng SkillData của chiêu này không có ô tập)
        if self:count_collection(obj_me, cid) > 0 then
            n = n + 1
        end
    end
    if n < 1 then
        return
    end
    local v = param(raw, s.labels[math.min(n, #s.labels)])
    if v == nil or v < 0 then
        return
    end
    if s.on_self then
        self:send(obj_me, obj_me, v, is_critical)
    end
    if s.aoe then
        for _, nb in ipairs(self:scan_side(obj_me, world_pos(obj_me), s.aoe.radius, s.aoe.count, s.aoe.side)) do
            self:send(obj_me, nb, v, is_critical)
        end
    end
end

-- 鬼谷 陨星造化: chọn ô theo số mục tiêu trúng của lượt
function skill_cy_spec:apply_by_target_count(obj_me, obj_tar, is_critical, raw, sp)
    local b = sp.by_target_count
    if not b then
        return
    end
    local params = obj_me:get_targeting_and_depleting_params()
    local cnt = params.get_target_count and params:get_target_count() or 1
    local idx = math.max(1, math.min((cnt or 1) - (b.base or 3) + 1, #(b.damage or {})))
    for _, list in ipairs({b.damage, b.control}) do
        if list and list[idx] then
            self:send(obj_me, obj_tar, param(raw, list[idx]), is_critical)
        end
    end
end

function skill_cy_spec:apply_hp_branch(obj_me, obj_tar, is_critical, raw, sp)
    local h = sp.hp_branch
    if not h or not obj_tar then
        return
    end
    local ok, hp = pcall(obj_tar.get_hp, obj_tar)
    local ok2, mx = pcall(obj_tar.get_max_hp, obj_tar)
    local label = h.above
    if ok and ok2 and mx and mx > 0 and (hp * 100 / mx) < (h.pct or 40) then
        label = h.below
    end
    self:send(obj_me, obj_tar, param(raw, label), is_critical)
end

-- ------------------------------------------------------------------ nhiều đòn + giảm dần (skill-logic-3 17/09)
-- 大理 204 少商剑·刃影: "发射6把飞剑，每把飞剑随机对目标周围5米内的一名敌对目标造成伤害，
-- 同一目标重复受到攻击时伤害逐次递减15%". Bộ đếm trúng nằm trong BIẾN CỤC BỘ của một lần tung
-- (skillenginer chỉ tạo MỘT đối tượng logic dùng chung cả cảnh — không được giữ trạng thái trên self).
function skill_cy_spec:apply_multi_hit(obj_me, obj_tar, is_critical, raw, sp, first)
    local mh = sp.multi_hit
    if not mh or not first then
        return 0
    end
    local v = param(raw, mh.label)
    if v == nil or v < 0 then
        return 0
    end
    local count = value_of(raw, mh.count) or 1
    if count < 1 then
        count = 1
    elseif count > 16 then
        count = 16
    end
    local center = (mh.around == 'self') and world_pos(obj_me) or world_pos(obj_tar)
    local pool = self:scan_side(obj_me, center, value_of(raw, mh.radius) or 5, nil, mh.side)
    if mh.include_center ~= false and obj_tar then
        local found = false
        for _, o in ipairs(pool) do
            if o == obj_tar then
                found = true
                break
            end
        end
        if not found then
            table.insert(pool, 1, obj_tar)
        end
    end
    if #pool == 0 then
        return 0
    end
    local decay = value_of(raw, mh.decay)
    local hits, sent = {}, 0
    for _ = 1, count do
        local nb = pool[math.random(#pool)]
        local rate = chain and chain.decay_rate(hits, nb, decay) or nil
        self:send(obj_me, nb, v, is_critical, {rate = rate})
        sent = sent + 1
    end
    return sent
end

-- ------------------------------------------------------------------ hút máu theo SÁT THƯƠNG THỰC (149)
function skill_cy_spec:apply_lifesteal(obj_me, obj_tar, raw, sp)
    local ls = sp.lifesteal
    if not ls or not chain or not obj_tar or obj_tar == obj_me then
        return false
    end
    local pct = value_of(raw, ls.pct)
    if not pct or pct <= 0 then
        return false
    end
    local params = obj_me:get_targeting_and_depleting_params()
    local delay = (params.get_delay_time and params:get_delay_time()) or 0
    local si = obj_me:get_skill_info()
    return chain.lifesteal(obj_me, obj_tar, pct, delay, si and si:get_skill_id() or INVALID)
end

-- ------------------------------------------------------------------ trạng thái dữ liệu không trỏ tới (144)
function skill_cy_spec:apply_state(obj_me, is_critical, raw, sp, first)
    local st = sp.state
    if not st or not first then
        return false
    end
    local key = value_of(raw, st.key)
    local id = key and st.map and st.map[key] or nil
    if id == nil then
        return false
    end
    return self:send(obj_me, obj_me, id, is_critical)
end

-- ------------------------------------------------------------------ chuỗi lan theo NHỊP DẪN (769)
function skill_cy_spec:chain_key(obj_me)
    local si = obj_me:get_skill_info()
    local lg = (si and si.get_logic_id and si:get_logic_id()) or 0
    return string.format("cychain%d", lg)
end

function skill_cy_spec:apply_chain_begin(obj_me, obj_tar, is_critical, raw, sp, first)
    local c = sp.chain
    if not c or not chain or not first or not obj_tar then
        return false
    end
    chain.chain_begin(obj_me, self:chain_key(obj_me), obj_tar)
    local v = c.link_main and param(raw, c.link_main)
    if v and v >= 0 then
        self:send(obj_me, obj_tar, v, is_critical)
    end
    return true
end

function skill_cy_spec:apply_chain_tick(obj_me, obj_tar, is_critical, raw, sp, first)
    local c = sp.chain
    if not c or not chain or not first then
        return 0
    end
    local key = self:chain_key(obj_me)
    local st = chain.chain_get(obj_me, key)
    if not st then
        if not obj_tar then
            return 0
        end
        -- nạp lại module giữa chừng / lỡ nhịp đầu: bắt đầu chuỗi từ mục tiêu hiện tại
        st = chain.chain_begin(obj_me, key, obj_tar)
        if not st then
            return 0
        end
    end
    local before = {}
    for _, o in ipairs(st.links or {}) do
        before[o] = true
    end
    local links = chain.chain_tick(obj_me, key, {
        max_links = c.max_links, max_ticks = c.max_ticks,
        break_main = value_of(raw, c.break_main), break_other = value_of(raw, c.break_other),
        scan = function(center, radius)
            return self:scan_side(obj_me, world_pos(center), radius, nil, 'enemy')
        end,
    })
    local link_other = c.link_other and param(raw, c.link_other)
    local n = 0
    for i, nb in ipairs(links) do
        if i > 1 and link_other and link_other >= 0 and not before[nb] then
            self:send(obj_me, nb, link_other, is_critical)          -- hiệu ứng "nối dây" cho mắt vừa nối
        end
        local label = c.ladder and c.ladder[math.min(i, #c.ladder)]
        local v = label and param(raw, label)
        if v and v >= 0 then
            self:send(obj_me, nb, v, is_critical)                   -- nấc sát thương theo THỨ TỰ NỐI
            n = n + 1
        end
    end
    return n
end

-- ------------------------------------------------------------------ triệu hồi (skill-summon 17/09)
-- Vị trí đặt thực thể: 'self' = dưới chân chủ, 'target' = mục tiêu đang nhắm, 'dest' = điểm client gửi,
-- 'doll' = con rối 离人偶. Mọi nhánh rơi về chỗ đứng của chủ khi không lấy được toạ độ.
function skill_cy_spec:summon_pos(obj_me, at)
    local params = obj_me:get_targeting_and_depleting_params()
    if at == 'doll' then
        local p = self:doll_pos(obj_me)
        if p then
            return p
        end
    end
    if at == 'target' then
        local tid = params:get_target_obj()
        if tid and tid ~= INVALID and tid ~= obj_me:get_obj_id() then
            local obj = obj_me:get_specific_obj_in_same_scene_by_id(tid)
            local p = obj and world_pos(obj)
            if p then
                return p
            end
        end
    end
    if at == 'target' or at == 'dest' or at == 'doll' then
        local pos = params:get_target_position()
        if pos and pos.x and pos.y and not (pos.x == 0 and pos.y == 0) then
            return {x = pos.x, y = pos.y}
        end
    end
    return world_pos(obj_me)
end

-- Chạy MỘT LẦN cho mỗi lần tung chiêu (gọi từ activate_once), không phải cho từng mục tiêu:
-- thực thể triệu hồi của CY luôn là một, và chiêu như 诸葛神弩 (目标逻辑 7) có thể không trúng ai
-- ⇒ effect_on_unit_once không bao giờ chạy.
function skill_cy_spec:apply_summon(obj_me, sp)
    if not sp or not sp.summon or not summon then
        return 0
    end
    local skill_info = obj_me:get_skill_info()
    local raw = skill_info and skill_info.cy_raw_params
    local skill_id = skill_info and skill_info:get_skill_id() or INVALID
    local logic_id = skill_info and skill_info.get_logic_id and skill_info:get_logic_id() or 0
    local made = 0
    for i, e in ipairs(sp.summon) do
        local idx, mid, hp = 1, nil, nil
        if e.ids and #e.ids > 0 then
            idx = math.random(#e.ids)                       -- CY 千机变: "随机设置1种枢甲造物"
            mid = value_of(raw, e.ids[idx])
            hp = e.hps and value_of(raw, e.hps[idx])
        else
            mid = value_of(raw, e.id)
            hp = e.hp and value_of(raw, e.hp)
        end
        if mid and mid > 0 then
            local atk = nil
            if e.attack then
                local scale = e.attack.scale
                if type(scale) == 'table' then
                    scale = scale[idx] or scale[1]
                end
                atk = {scale = value_of(raw, scale), radius = value_of(raw, e.attack.radius),
                       count = value_of(raw, e.attack.count), around = e.attack.around,
                       heal_owner = e.attack.heal_owner}
            end
            local obj = summon.spawn(obj_me, {
                monster_id = mid,
                pos = self:summon_pos(obj_me, e.at),
                hp = hp,
                life_ms = value_of(raw, e.life),
                interval = e.attack and value_of(raw, e.attack.interval) or value_of(raw, e.interval),
                delay = value_of(raw, e.delay),
                name = e.name,
                unbreakable = e.unbreakable,
                base_ai = e.base_ai,
                key = string.format("cy%d#%d", logic_id, i),
                skill_id = skill_id,
                self_impact = e.self_impact and value_of(raw, e.self_impact) or nil,
                data = {attack = atk},
                on_tick = atk and summon.attack_tick or nil,
            })
            if obj then
                made = made + 1
            end
        end
    end
    return made
end

-- ------------------------------------------------------------------ 星阵 鬼谷 (skill-logic-4 17/09)
-- 761–765 KHÔNG tự dựng thực thể. Chúng chỉ gửi cho CHÍNH người tung một "impact mầm"
-- (`逻辑ID 8090`, `脚本ID = 808253`, `总持续时间 = 1 ms`); khi impact đó tắt, native logic 90 của
-- cy_four_combat (`native.fade_90` → `callbacks.script_on_impact_fade`) đọc dải ID của mầm để biết
-- là trận nào và bậc mấy, rồi gọi `guigu_installation.spawn` — đúng một thực thể.
-- Mốc vị trí đã do `timers:on_use_skill_successfully` (chạy TRƯỚC activate_once, base.lua:98/103) đặt.
-- BẬC = ô mầm thứ mấy trong dải; dải chỉ có 12 mức còn CY có 16 cấp tâm pháp, mà
-- `guigu_installation.lua:22` có `assert(tier >= 1 and tier <= 12)` ⇒ PHẢI kẹp về 12,
-- nếu không 4067 + 15 = 4082 rơi sang dải 破军 (4080–4091): vừa sai trận vừa có thể nổ assert.
function skill_cy_spec:skill_level(obj_me)
    local ok, params = pcall(obj_me.get_targeting_and_depleting_params, obj_me)
    local lv = ok and params and params.get_skill_level and params:get_skill_level() or nil
    if lv == nil then
        local si = obj_me:get_skill_info()
        local ok2, v = pcall(function() return si.get_skill_level and si:get_skill_level() end)
        lv = ok2 and v or nil
    end
    return math.tointeger(tonumber(lv) or 1) or 1
end

function skill_cy_spec:seed_data_index(obj_me, sd)
    local tiers = sd.tiers or 12
    local lv = self:skill_level(obj_me)
    if lv < 1 then
        lv = 1
    elseif lv > tiers then
        lv = tiers                     -- kẹp: dải mầm chỉ 12 mức, CY có 16 cấp
    end
    return sd.first + lv - 1
end

function skill_cy_spec:apply_seed(obj_me, sp)
    local sd = sp and sp.seed
    if not sd or type(sd.first) ~= "number" then
        return 0
    end
    local id = self:seed_data_index(obj_me, sd)
    -- CHỈ gửi cho người tung: thực thể là việc của cy_four_combat, gửi cho ai khác sẽ ra nhiều trận
    return self:send(obj_me, obj_me, id, false) and 1 or 0
end

-- nhãn nào đặc tả đã dùng (hoặc cố ý bỏ) thì lớp generic không áp lại
function skill_cy_spec.consumed_labels(sp)
    local out = {}
    local function add(x)
        if type(x) == "string" then
            out[x] = true
        end
    end
    for _, key in ipairs({'impacts', 'tick', 'aoe', 'trap'}) do
        for _, e in ipairs(sp[key] or {}) do
            add(e.label)
            add(e.chance)
            add(e.duration)
            add(e.count)
            add(e.radius)
            add(e.only_critical)
            add(e.rate_add)
            for _, x in ipairs(e.chance_ladder or {}) do add(x) end
        end
    end
    -- skill-logic-3 17/09
    if sp.multi_hit then
        add(sp.multi_hit.label)
        add(sp.multi_hit.count)
        add(sp.multi_hit.radius)
        add(sp.multi_hit.decay)
    end
    if sp.lifesteal then
        add(sp.lifesteal.pct)
    end
    if sp.state then
        add(sp.state.key)
    end
    if sp.chain then
        add(sp.chain.break_main)
        add(sp.chain.break_other)
        add(sp.chain.link_main)
        add(sp.chain.link_other)
        for _, x in ipairs(sp.chain.ladder or {}) do add(x) end
    end
    for _, l in ipairs(sp.consume or {}) do
        add(l)
    end
    if sp.gender then
        add(sp.gender.male)
        add(sp.gender.female)
    end
    if sp.teleport then
        add(sp.teleport.label)
        add(sp.teleport.keep)
    end
    if sp.cooldown_reduce then
        add(sp.cooldown_reduce.id)
        add(sp.cooldown_reduce.ms)
    end
    if sp.cooldown_on_crit then
        add(sp.cooldown_on_crit.min)
        add(sp.cooldown_on_crit.max)
    end
    for _, s in ipairs({sp.souls, sp.souls_pick}) do
        if s then
            add(s.base)
            for _, x in ipairs(s.sets or {}) do add(x) end
            for _, x in ipairs(s.labels or {}) do add(x) end
            for _, x in pairs(s.mult or {}) do add(x) end
            for _, ps in ipairs(s.per_set or {}) do add(ps.set); add(ps.label) end
        end
    end
    if sp.by_target_count then
        for _, x in ipairs(sp.by_target_count.damage or {}) do add(x) end
        for _, x in ipairs(sp.by_target_count.control or {}) do add(x) end
    end
    if sp.hp_branch then
        add(sp.hp_branch.above)
        add(sp.hp_branch.below)
    end
    for _, e in ipairs(sp.summon or {}) do
        add(e.id)
        add(e.hp)
        add(e.self_impact)
        for _, x in ipairs(e.ids or {}) do add(x) end
        for _, x in ipairs(e.hps or {}) do add(x) end
    end
    return out
end

-- ------------------------------------------------------------------ vòng đời
function skill_cy_spec:activate_once(obj_me)
    self._first_once = true
    self._trap_n = nil            -- bộ đếm bẫy theo mức xác suất chỉ sống trong MỘT lượt (736)
    local ok, ret = pcall(skill_cy_generic.activate_once, self, obj_me)
    self._first_once = nil
    self._trap_n = nil
    if not ok then
        skynet.logi("[skill_cy_spec] activate_once loi", ret)
        ret = false
    end
    -- Triệu hồi chạy NGOÀI vòng mục tiêu: chiêu 目标逻辑 7 (诸葛神弩) có thể không trúng ai, khi đó
    -- effect_on_unit_once không hề được gọi (skill:activate_once bỏ qua nhánh khi target_count == 0).
    local oks, err = pcall(function()
        local sp = self:get_spec(obj_me:get_skill_info())
        if sp and sp.summon then
            self:apply_summon(obj_me, sp)
        end
        -- 星阵 鬼谷 (skill-logic-4): cùng lý do với triệu hồi — 3438/3439/3447/3451/3453 có
        -- 目标选择逻辑 = 7 (điểm đất), không trúng ai thì effect_on_unit_once KHÔNG BAO GIỜ chạy.
        if sp and sp.seed then
            self:apply_seed(obj_me, sp)
        end
    end)
    if not oks then
        skynet.logi("[skill_cy_spec] trieu hoi loi", err)
    end
    return ret
end

function skill_cy_spec:activate_each_tick(obj_me)
    self._first_tick = true
    local ok, ret = pcall(skill_cy_generic.activate_each_tick, self, obj_me)
    self._first_tick = nil
    if not ok then
        skynet.logi("[skill_cy_spec] activate_each_tick loi", ret)
        return false
    end
    return ret
end

function skill_cy_spec:generic_pass(obj_me, obj_tar, is_critical, raw, skip)
    local scene = obj_me:get_scene()
    local engine = scene and scene:get_impact_enginer()
    local params = obj_me:get_targeting_and_depleting_params()
    local target_is_enemy = obj_tar and obj_tar ~= obj_me and obj_me:is_enemy(obj_tar)
    for _, e in ipairs(skill_cy_generic.extra_impacts(raw, engine and engine.std_impact_config or {})) do
        if not skip[e.label] and (not e.chance or math.random(100) <= e.chance) then
            local reciver = obj_tar
            if e.to_self or (e.stand > 0 and target_is_enemy) then
                reciver = obj_me
            elseif e.stand < 0 and not target_is_enemy then
                reciver = nil
            end
            if reciver then
                local imp = impact.new()
                imp:clean_up()
                if engine and engine:init_impact_from_data(e.data_index, imp) then
                    self:register_impact_event(reciver, obj_me, imp, params:get_delay_time(), is_critical)
                end
            end
        end
    end
end

function skill_cy_spec:effect_on_unit_once(obj_me, obj_tar, is_critical)
    skill_0.effect_on_unit_once(self, obj_me, obj_tar, is_critical)
    local skill_info = obj_me:get_skill_info()
    local raw = skill_info and skill_info.cy_raw_params
    local sp = self:get_spec(skill_info)
    if not raw then
        return
    end
    if not sp then
        return skill_cy_generic.effect_on_unit_once(self, obj_me, obj_tar, is_critical)
    end
    local first = self._first_once and true or false
    -- ô |生效一次的附加效果N bị chuyển sang bản thân
    for _, i in ipairs(sp.self_idx or {}) do
        if first then
            self:send(obj_me, obj_me, num(skill_info:get_activate_once_impact_by_index(i)), is_critical)
        end
    end
    self:apply_impacts(obj_me, obj_tar, is_critical, raw, sp.impacts, first)
    self:apply_aoe(obj_me, obj_tar, is_critical, raw, sp, first)
    self:apply_trap(obj_me, obj_tar, raw, sp, first, false)
    self:apply_multi_hit(obj_me, obj_tar, is_critical, raw, sp, first)
    self:apply_resist_cast(obj_me, obj_tar, is_critical, sp)
    self:apply_state(obj_me, is_critical, raw, sp, first)
    self:apply_chain_begin(obj_me, obj_tar, is_critical, raw, sp, first)
    if sp.lifesteal and not sp.lifesteal.tick then
        -- `tick = true` (149) nghĩa là sát thương nằm ở ô 引导周期 ⇒ chỉ hút máu theo nhịp, tránh đo hai lần
        self:apply_lifesteal(obj_me, obj_tar, raw, sp)
    end
    self:apply_gender(obj_me, is_critical, raw, sp, first)
    self:apply_teleport(obj_me, obj_tar, is_critical, raw, sp, first)
    self:apply_cooldown(obj_me, is_critical, raw, sp, first)
    self:apply_souls(obj_me, obj_tar, is_critical, raw, sp)
    self:apply_souls_pick(obj_me, obj_tar, is_critical, raw, sp, first)
    self:apply_by_target_count(obj_me, obj_tar, is_critical, raw, sp)
    self:apply_hp_branch(obj_me, obj_tar, is_critical, raw, sp)
    self._first_once = false
    self:generic_pass(obj_me, obj_tar, is_critical, raw, skill_cy_spec.consumed_labels(sp))
end

function skill_cy_spec:effect_on_unit_each_tick(obj_me, obj_tar, is_critical)
    skill_0.effect_on_unit_each_tick(self, obj_me, obj_tar, is_critical)
    local skill_info = obj_me:get_skill_info()
    local raw = skill_info and skill_info.cy_raw_params
    local sp = self:get_spec(skill_info)
    if not raw or not sp then
        return
    end
    local first = self._first_tick and true or false
    for _, i in ipairs(sp.tick_self_idx or {}) do
        if first then
            self:send(obj_me, obj_me, num(skill_info:get_activate_each_tick_impact_by_index(i)), is_critical)
        end
    end
    self:apply_impacts(obj_me, obj_tar, is_critical, raw, sp.tick, first)
    self:apply_trap(obj_me, obj_tar, raw, sp, first, true)
    -- skill-logic-3: chuỗi lan chạy theo NHỊP DẪN của chính engine (769: 引导间隔 800 ms = 0,8 s của tip)
    self:apply_chain_tick(obj_me, obj_tar, is_critical, raw, sp, first)
    if sp.lifesteal and sp.lifesteal.tick then
        self:apply_lifesteal(obj_me, obj_tar, raw, sp)
    end
    self._first_tick = false
end

return skill_cy_spec
