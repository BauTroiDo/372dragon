-- skill-summon (CY-Source 17/09/2026): bộ chạy THỰC THỂ TRIỆU HỒI cho hệ kỹ năng CY.
--
-- Vì sao có file này: nhóm logic "cần thực thể native" của skill-logic (mục 3 của Docs/specs/server/skill-logic_vi.md)
-- lâu nay bị coi là không làm được. Nhưng server riêng ĐÃ có đủ API, và bản thân dự án đã dùng chúng cho
-- 鬼谷 星阵 / 桃花岛 傀儡:
--   * scenecore:create_temp_monster(monster_id, x, y, base_ai, ai_script, script_id, param_dir) -> obj_id
--     (services/scene/scenecore.lua:849) — trả obj_id, không có thì trả nil (không ném lỗi).
--   * monster:set_temp_camp_id / set_die_time / mark_unbreakable_flag / set_attrib{hp_max} / set_name.
--   * lualib/cy_four_combat/summon_runtime.lua đã chứng minh cách gắn nhịp: bọc obj.update của CHÍNH thực thể
--     (không đụng vòng update toàn cục) và tự xoá khi chủ biến mất. Module này làm y hệt nhưng ĐỘC LẬP và
--     bọc pcall toàn bộ (summon_runtime dùng assert — một assert trong đường kỹ năng làm "trừ MP, đặt hồi
--     chiêu rồi sập", đúng bẫy đã ghi ở mục 8 của đặc tả).
--
-- Mô hình: thực thể triệu hồi là MỐC NEO, không phải người đánh.
--   * Quan hệ địch/ta luôn tính theo CHỦ (owner:is_enemy) — quái triệu hồi có 友好值 = 0 trong
--     MonsterAttrExTable nên engine coi nó trung lập hai chiều (monster:is_enemy trả false khi
--     get_reputation() == 0, và human:is_enemy(monster) cũng trả false) ⇒ không ai đánh được nó, nó cũng
--     không tự đánh ai. Đây chính là "狂猿无法被攻击" của tip CY, có sẵn từ dữ liệu.
--   * Sát thương ghi cho CHỦ và tính bằng "N % đòn ĐÁNH THƯỜNG" — đúng cơ chế CY đã bẻ ở logic impact 115
--     (StdImpact115_T::OnActive @0xa5f2f8): dựng impact từ StandardImpact DataIndex 0
--     (普通攻击的伤害效果) qua CombatCore rồi nhân hệ số bằng RefixPowerByRate. Không có công thức tự chế.
--
-- An toàn: MỌI lời gọi ra ngoài đều pcall; thiếu API thì bỏ qua và trả nil/0 chứ không ném lỗi.
local skynet = require "skynet"
local define = require "define"
local impact = require "scene.skill.impact"
local combat_core = require "scene.skill.combat_core"
local std_impact_003 = require "scene.skill.impact_logic.std_impact_003"

local M = {}

M.NORMAL_ATTACK_DATA_INDEX = 0        -- dòng StandardImpact của đòn đánh thường (CY: DataIndex 0)
M.MAX_LIFE_MS = 60000                 -- trần vòng đời: thực thể triệu hồi của CY dài nhất là 30 s
M.MAX_TICK_ERRORS = 5                 -- lỗi liên tiếp trong nhịp → ngắt nhịp, không spam log
M.MIN_INTERVAL_MS = 100

-- [chủ] = { [thực thể] = khoá }, khoá yếu hai tầng: bảng này KHÔNG được giữ đối tượng sống
-- (bẫy 11.2 của đặc tả: đừng gắn trạng thái vào đối tượng bị đóng gói, đừng tạo vòng tham chiếu).
local registry = setmetatable({}, {__mode = "k"})
M.registry = registry

local function num(v)
    return tonumber(v)
end

local function pos_ok(p)
    return type(p) == "table" and type(p.x) == "number" and type(p.y) == "number"
        and p.x == p.x and p.y == p.y and math.abs(p.x) < math.huge and math.abs(p.y) < math.huge
end
M.pos_ok = pos_ok

function M.world_pos(obj)
    if not obj or not obj.get_world_pos then
        return nil
    end
    local ok, p = pcall(obj.get_world_pos, obj)
    if ok and pos_ok(p) then
        return {x = p.x, y = p.y}
    end
    return nil
end

function M.hp(obj)
    if not obj or not obj.get_hp then
        return nil
    end
    local ok, v = pcall(obj.get_hp, obj)
    return ok and num(v) or nil
end

local function scene_of(obj)
    if not obj or not obj.get_scene then
        return nil
    end
    local ok, s = pcall(obj.get_scene, obj)
    return ok and s or nil
end
M.scene_of = scene_of

-- Chủ còn hợp lệ? (cùng cảnh, vẫn là đúng đối tượng mang obj_id đó, còn sống)
-- Bản sao ý của cy_four_combat/summon_runtime.resolve_owner, nhưng không assert.
function M.owner_alive(tag)
    local owner = tag and tag.owner
    local scene = tag and tag.scene
    if not owner or not scene or not scene.get_obj_by_id then
        return nil
    end
    local ok, cur = pcall(scene.get_obj_by_id, scene, tag.owner_obj_id)
    if not ok or cur ~= owner then
        return nil
    end
    if scene_of(owner) ~= scene then
        return nil
    end
    if owner.is_alive then
        local ok2, alive = pcall(owner.is_alive, owner)
        if ok2 and not alive then
            return nil
        end
    end
    return owner
end

function M.kill(obj, ms)
    if obj and obj.set_die_time then
        pcall(obj.set_die_time, obj, ms or 200)
        return true
    end
    return false
end

-- Xoá các thực thể cũ của cùng một chiêu (CY chỉ cho phép một 图腾/一只狂猿 mỗi lần tung).
function M.despawn(owner, key)
    local list = registry[owner]
    if not list then
        return 0
    end
    local n = 0
    for obj, k in pairs(list) do
        if key == nil or k == key then
            M.kill(obj, 1)
            list[obj] = nil
            n = n + 1
        end
    end
    return n
end

function M.count(owner, key)
    local list = registry[owner]
    if not list then
        return 0
    end
    local n = 0
    for _, k in pairs(list) do
        if key == nil or k == key then
            n = n + 1
        end
    end
    return n
end

-- --------------------------------------------------------------------- nhịp
-- Bọc obj.update của CHÍNH thực thể (giống summon_runtime.attach) — không đụng vòng update của cảnh.
function M.attach(obj, tag, on_tick)
    if not obj or type(obj.update) ~= "function" then
        return false
    end
    local original = obj.update
    tag.age = 0
    tag.interval = num(tag.interval)
    if tag.interval and tag.interval < M.MIN_INTERVAL_MS then
        tag.interval = M.MIN_INTERVAL_MS
    end
    -- delay = thời gian tới NHỊP ĐẦU (CY 千机变: 3 s sau mới kích hoạt)
    tag.elapsed = (tag.interval and num(tag.delay)) and (tag.interval - tag.delay) or 0
    obj.update = function(self, delta, ...)
        if type(delta) == "number" and delta > 0 and not tag.dead then
            tag.age = tag.age + delta
            local owner = M.owner_alive(tag)
            if not owner or tag.age > tag.max_life then
                tag.dead = true
                M.kill(self, 1)
            elseif on_tick and tag.interval then
                tag.elapsed = tag.elapsed + delta
                if tag.elapsed >= tag.interval then
                    tag.elapsed = tag.elapsed - tag.interval
                    local ok, err = pcall(on_tick, self, owner, tag)
                    if not ok then
                        tag.errors = (tag.errors or 0) + 1
                        if tag.errors == 1 then
                            skynet.logi("[cy_skill_summon] nhip loi", tag.monster_id, tostring(err))
                        end
                        if tag.errors >= M.MAX_TICK_ERRORS then
                            tag.interval = nil
                        end
                    else
                        tag.errors = 0
                    end
                end
            end
        end
        return original(self, delta, ...)
    end
    return true
end

-- --------------------------------------------------------------------- tạo
-- opt: monster_id, pos{x,y}, hp, life_ms, interval, delay, name, unbreakable, key, skill_id,
--      self_impact (DataIndex áp lên chính thực thể, vd 无敌效果id), data (bảng tuỳ ý cho on_tick), on_tick
function M.spawn(owner, opt)
    if not owner or type(opt) ~= "table" then
        return nil, "no_owner"
    end
    local monster_id = num(opt.monster_id)
    if not monster_id or monster_id <= 0 or monster_id ~= math.floor(monster_id) or monster_id > 65535 then
        return nil, "bad_monster_id"          -- ID quái đi trên wire 2 byte
    end
    local scene = scene_of(owner)
    if not scene or type(scene.create_temp_monster) ~= "function" or type(scene.get_obj_by_id) ~= "function" then
        return nil, "no_scene_api"
    end
    local pos = pos_ok(opt.pos) and {x = opt.pos.x, y = opt.pos.y} or M.world_pos(owner)
    if not pos then
        return nil, "no_pos"
    end
    if opt.key then
        M.despawn(owner, opt.key)
    end
    local ok, obj_id = pcall(scene.create_temp_monster, scene, monster_id, pos.x, pos.y,
                             opt.base_ai, define.INVAILD_ID, define.INVAILD_ID)
    if not ok then
        skynet.logi("[cy_skill_summon] create_temp_monster loi", monster_id, tostring(obj_id))
        return nil, "create_error"
    end
    if not obj_id then
        return nil, "no_monster_row"          -- create_monster_data trả nil khi thiếu dòng MonsterAttrEx
    end
    local ok2, obj = pcall(scene.get_obj_by_id, scene, obj_id)
    if not ok2 or not obj then
        return nil, "no_obj"
    end

    if owner.get_camp_id then
        local okc, camp = pcall(owner.get_camp_id, owner)
        if okc and camp and obj.set_temp_camp_id then
            pcall(obj.set_temp_camp_id, obj, camp)
        end
    end
    local hp = num(opt.hp)
    if hp and hp > 0 and obj.set_attrib then
        pcall(obj.set_attrib, obj, {hp_max = hp})
        if obj.set_hp then
            pcall(obj.set_hp, obj, hp)
        end
    end
    if opt.name and obj.set_name then
        pcall(obj.set_name, obj, opt.name)
    end
    if opt.unbreakable and obj.mark_unbreakable_flag then
        pcall(obj.mark_unbreakable_flag, obj)
    end
    if obj.set_unconstrained_monster then
        -- monster:update bỏ qua quái trong MAIN_CITY nếu không có cờ này → thực thể sẽ "đứng hình"
        pcall(obj.set_unconstrained_monster, obj, true)
    end

    local life = num(opt.life_ms) or M.MAX_LIFE_MS
    if life > M.MAX_LIFE_MS then
        life = M.MAX_LIFE_MS
    end
    if life < 1000 then
        life = 1000
    end
    M.kill(obj, life)

    local tag = {
        owner = owner,
        owner_obj_id = owner.get_obj_id and owner:get_obj_id() or define.INVAILD_ID,
        scene = scene,
        key = opt.key,
        monster_id = monster_id,
        skill_id = opt.skill_id or define.INVAILD_ID,
        interval = opt.interval,
        delay = opt.delay,
        max_life = life + 2000,
        data = opt.data or {},
    }
    M.attach(obj, tag, opt.on_tick)

    if opt.self_impact then
        M.send_impact(obj, owner, opt.self_impact, tag.skill_id)
    end

    local list = registry[owner]
    if not list then
        list = setmetatable({}, {__mode = "k"})
        registry[owner] = list
    end
    list[obj] = opt.key or true
    return obj, tag
end

-- --------------------------------------------------------------------- tác dụng
-- Gửi một dòng StandardImpact bất kỳ từ `caster` lên `target` ngoài ngữ cảnh kỹ năng.
function M.send_impact(target, caster, data_index, skill_id)
    local idx = num(data_index)
    if not target or idx == nil or idx < 0 then
        return false
    end
    local scene = scene_of(target)
    local engine = scene and scene.get_impact_enginer and scene:get_impact_enginer()
    local event = scene and scene.get_event_enginer and scene:get_event_enginer()
    if not engine or not event then
        return false
    end
    local imp = impact.new()
    imp:clean_up()
    if not engine:init_impact_from_data(idx, imp) then
        return false
    end
    imp:set_skill_id(skill_id or define.INVAILD_ID)
    local ok = pcall(event.register_impact_event, event, target, caster, imp, 0, skill_id or define.INVAILD_ID)
    return ok
end

-- Sát thương = `scale` % đòn ĐÁNH THƯỜNG của `caster`, ghi cho `caster`.
-- Đúng đường của std_impact_115 (mã CY StdImpact115_T::OnActive @0xa5f2f8) — xem đầu file.
-- Trả về số máu thật sự mất của mục tiêu (đo bằng chênh lệch HP) để phần "hồi máu cho chủ" có số thật.
function M.normal_attack(caster, target, scale, skill_id, critical)
    if not caster or not target then
        return 0
    end
    local scene = scene_of(target)
    local engine = scene and scene.get_impact_enginer and scene:get_impact_enginer()
    if not engine then
        return 0
    end
    local imp = impact.new()
    imp:clean_up()
    if not engine:init_impact_from_data(M.NORMAL_ATTACK_DATA_INDEX, imp) then
        return 0
    end
    if imp:get_logic_id() == std_impact_003.ID then
        local cc = combat_core.new()
        cc:get_result_impact(caster, target, imp)
        local rate = num(scale) or 100
        if rate ~= 100 then
            std_impact_003.refix_power_by_rate(std_impact_003, imp, rate - 100)
        end
    end
    if caster.get_obj_id then
        imp:set_caster_obj_id(caster:get_obj_id())
    end
    imp:set_skill_id(skill_id or define.INVAILD_ID)
    if critical then
        imp:mark_critical_hit_flag()
    end
    local before = M.hp(target)
    std_impact_003.on_active(std_impact_003, imp, target)
    local after = M.hp(target)
    if before and after and before > after then
        return before - after
    end
    return 0
end

-- Quét địch THEO GÓC NHÌN CỦA CHỦ quanh một điểm (thực thể triệu hồi có 友好值 = 0 nên tự nó không có phe).
function M.scan_enemies(owner, center, radius, count)
    if not owner or not pos_ok(center) then
        return {}
    end
    local scene = scene_of(owner)
    if not scene or type(scene.scan) ~= "function" then
        return {}
    end
    local ok, list = pcall(scene.scan, scene, {
        obj = owner, scene = scene, x = center.x, y = center.y,
        radious = radius or 5, target_logic_by_stand = 1, check_can_view = true,
    })
    if not ok or type(list) ~= "table" then
        return {}
    end
    local out = {}
    for _, nb in ipairs(list) do
        local t = nb.get_obj_type and nb:get_obj_type()
        if (t == "human" or t == "monster" or t == "pet") and nb ~= owner then
            local alive = true
            if nb.is_alive then
                local oka, v = pcall(nb.is_alive, nb)
                alive = (not oka) or (v and true or false)
            end
            local oke, foe = pcall(owner.is_enemy, owner, nb)
            if alive and oke and foe then
                out[#out + 1] = nb
                if count and count > 0 and #out >= count then
                    break
                end
            end
        end
    end
    return out
end

function M.heal(owner, amount, skill_id)
    local v = num(amount)
    if not owner or not v or v <= 0 or not owner.health_increment then
        return false
    end
    return (pcall(owner.health_increment, owner, math.floor(v), owner, false, nil,
                  skill_id or define.INVAILD_ID))
end

-- Gói hình ảnh "thực thể nhắm và bắn mục tiêu" (giống guigu_adapter.target_visual).
-- Nếu client/gói không có thì tắt hẳn, không thử lại.
function M.show_hit(summon, owner, target, skill_id)
    if M.visual_off or not summon or not target then
        return false
    end
    local ok = pcall(function()
        local packet_def = require "game.packet"
        local msg = packet_def.GCTargetListAndHitFlags.new()
        msg.data_type = 0
        msg.m_objID = summon:get_obj_id()
        msg.logic_count = summon.get_logic_count and summon:get_logic_count() or 0
        msg.skill_or_special_obj_id = skill_id or define.INVAILD_ID
        msg.target_pos = target:get_world_pos()
        msg.unknow_1 = 0
        msg.size = 1
        msg.target_list = {target:get_obj_id()}
        local scene = scene_of(summon)
        if scene and scene.broadcast then
            scene:broadcast(summon, msg, true)
        end
    end)
    if not ok then
        M.visual_off = true
    end
    return ok
end

-- --------------------------------------------------------------------- nhịp mặc định
-- tag.data.attack = {scale, radius, count, around = 'summon'|'owner', heal_owner = <phần trăm>}
function M.attack_tick(summon, owner, tag)
    local a = tag and tag.data and tag.data.attack
    if not a then
        return
    end
    local center = (a.around == "owner") and M.world_pos(owner) or M.world_pos(summon)
    if not center then
        return
    end
    local targets = M.scan_enemies(owner, center, num(a.radius) or 5, num(a.count) or 1)
    local total = 0
    for _, t in ipairs(targets) do
        total = total + M.normal_attack(owner, t, a.scale, tag.skill_id, false)
        M.show_hit(summon, owner, t, tag.skill_id)
    end
    if total > 0 and a.heal_owner then
        M.heal(owner, total * (num(a.heal_owner) or 100) / 100, tag.skill_id)
    end
    return total
end

return M
