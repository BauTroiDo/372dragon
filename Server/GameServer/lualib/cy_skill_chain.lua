-- skill-logic-3 (CY-Source 17/09/2026): ba cơ chế "có trạng thái" cho hệ kỹ năng CY.
--
--   1. CHUỖI LAN theo thời gian (鬼谷 769 火烧连营): mục tiêu chính + tối đa 6 mục tiêu nối thêm,
--      mỗi nấc một dòng StandardImpact riêng, đứt dây khi mục tiêu rời tầm.
--   2. HÚT MÁU theo SÁT THƯƠNG THỰC (峨嵋 149 金顶绵掌·九阴 |回血百分比): engine Lua đăng ký impact
--      qua `skynet.fork` rồi mới trừ máu, nên không có số sát thương tại chỗ → đo bằng CHÊNH LỆCH HP
--      của mục tiêu sau khi impact đã chạy (đúng cách `cy_skill_summon.normal_attack` đã làm cho 886).
--   3. BỘ ĐẾM TRÚNG theo từng mục tiêu trong MỘT lượt (大理 204 少商剑·刃影 衰减系数百分比).
--
-- Vì sao là file riêng: `skillenginer` chỉ tạo **một** đối tượng logic cho mỗi 技能逻辑ID và dùng chung cho
-- cả cảnh (`skillenginer.lua:576 self.skill_logics[skill.logic_id] = mod.new()`), nên KHÔNG được giữ trạng
-- thái nhiều nhịp trên `self` của lớp logic. Trạng thái ở đây nằm trong bảng khoá yếu theo NGƯỜI TUNG.
--
-- An toàn (bẫy mục 8 + 11 của đặc tả):
--   * mọi lời gọi ra ngoài bọc `pcall`; thiếu API thì trả 0/nil chứ không ném;
--   * bảng `chains` khoá yếu theo chủ, KHÔNG gắn trạng thái lên đối tượng impact (tránh vòng tham chiếu
--     làm `serialize can't pack too depth table`);
--   * mọi ô tham số đọc ra đều `or 0` / kiểm nil trước khi tính (bẫy `math.floor(nil)` của std_impact_011).
local skynet = require "skynet"
local define = require "define"

local M = {}

M.MAX_TICKS = 40                  -- trần cứng số nhịp của một chuỗi (769 dài nhất 8 s / 0,8 s = 10 nhịp)
M.MAX_LINKS = 16                  -- trần cứng số mắt xích
M.SETTLE_MS = 400                 -- chờ thêm sau 延迟时间 để impact đã trừ máu xong rồi mới đo HP
M.MAX_WAIT_MS = 5000

-- [chủ] = { [khoá] = state } — khoá yếu theo chủ: bảng này không giữ ai sống
local chains = setmetatable({}, {__mode = "k"})
M.chains = chains

local function num(v)
    return tonumber(v)
end

local function pos_ok(p)
    return type(p) == "table" and type(p.x) == "number" and type(p.y) == "number"
        and p.x == p.x and p.y == p.y
end

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

function M.dist(a, b)
    local pa, pb = M.world_pos(a), M.world_pos(b)
    if not pa or not pb then
        return nil
    end
    local dx, dy = pa.x - pb.x, pa.y - pb.y
    return math.sqrt(dx * dx + dy * dy)
end

function M.hp(obj)
    if not obj or not obj.get_hp then
        return nil
    end
    local ok, v = pcall(obj.get_hp, obj)
    return ok and num(v) or nil
end

function M.alive(obj)
    if not obj then
        return false
    end
    if not obj.is_alive then
        return true
    end
    local ok, v = pcall(obj.is_alive, obj)
    return (not ok) or (v and true or false)
end

local function scene_of(obj)
    if not obj or not obj.get_scene then
        return nil
    end
    local ok, s = pcall(obj.get_scene, obj)
    return ok and s or nil
end
M.scene_of = scene_of

-- Hẹn giờ trong service cảnh. skynet.timeout đếm bằng 1/100 s (xem scenecore.lua: `remove_time_ms / 10`).
function M.after(ms, fn)
    local t = num(ms) or 0
    if t < 0 then
        t = 0
    end
    if t > M.MAX_WAIT_MS then
        t = M.MAX_WAIT_MS
    end
    local ok = pcall(skynet.timeout, math.max(1, math.floor(t / 10)), function()
        local ok2, err = pcall(fn)
        if not ok2 then
            skynet.logi("[cy_skill_chain] hen gio loi", tostring(err))
        end
    end)
    return ok
end

-- Chủ còn hợp lệ? (cùng cảnh, đúng đối tượng mang obj_id đó, còn sống) — cùng ý với cy_skill_summon.owner_alive.
function M.owner_alive(owner, scene, owner_obj_id)
    if not owner or not scene or not scene.get_obj_by_id then
        return false
    end
    local ok, cur = pcall(scene.get_obj_by_id, scene, owner_obj_id)
    if not ok or cur ~= owner then
        return false
    end
    if scene_of(owner) ~= scene then
        return false
    end
    return M.alive(owner)
end

-- ------------------------------------------------------------------ 1. hút máu theo sát thương THỰC
-- Đo HP mục tiêu trước, chờ `delay_ms + SETTLE_MS` rồi đo lại; hồi cho chủ `pct` % phần máu đã mất.
-- Trả về true nếu đã hẹn được phép đo (không phải "đã hồi máu").
function M.lifesteal(owner, target, pct, delay_ms, skill_id)
    local p = num(pct) or 0
    if not owner or not target or p <= 0 then
        return false
    end
    local before = M.hp(target)
    if not before then
        return false
    end
    local scene = scene_of(owner)
    local owner_obj_id = owner.get_obj_id and owner:get_obj_id() or define.INVAILD_ID
    return M.after((num(delay_ms) or 0) + M.SETTLE_MS, function()
        if not M.owner_alive(owner, scene, owner_obj_id) then
            return
        end
        local after = M.hp(target)
        if not after or after >= before then
            return
        end
        M.heal(owner, (before - after) * p / 100, skill_id)
    end)
end

function M.heal(owner, amount, skill_id)
    local v = num(amount)
    if not owner or not v or v < 1 or not owner.health_increment then
        return false
    end
    return (pcall(owner.health_increment, owner, math.floor(v), owner, false, nil,
                  skill_id or define.INVAILD_ID))
end

-- ------------------------------------------------------------------ 2. bộ đếm trúng theo từng mục tiêu
-- Dùng TRONG MỘT lượt tung (bảng do người gọi tạo rồi vứt) — 大理 204: lần trúng thứ n của cùng một mục
-- tiêu chịu hệ số `100 × (1 − decay/100)^(n−1)`. `decay` là ô 衰减系数百分比 của chính SkillData.
function M.decay_rate(hits, obj, decay)
    if not obj then
        return 100
    end
    local key = (obj.get_obj_id and obj:get_obj_id()) or obj
    local n = (hits[key] or 0) + 1
    hits[key] = n
    local d = num(decay) or 0
    if d <= 0 or n <= 1 then
        return 100
    end
    if d >= 100 then
        return n > 1 and 1 or 100
    end
    local rate = 100 * ((100 - d) / 100) ^ (n - 1)
    if rate < 1 then
        rate = 1
    end
    return math.floor(rate + 0.5)
end

-- ------------------------------------------------------------------ 3. chuỗi lan theo thời gian
local function state_of(owner, key, create)
    local list = chains[owner]
    if not list then
        if not create then
            return nil
        end
        list = {}
        chains[owner] = list
    end
    local st = list[key]
    if not st and create then
        st = {}
        list[key] = st
    end
    return st
end

function M.chain_clear(owner, key)
    local list = chains[owner]
    if list then
        list[key] = nil
    end
end

-- Bắt đầu (hoặc đặt lại) chuỗi cho một lần tung. `main` = mục tiêu chính.
function M.chain_begin(owner, key, main)
    if not owner or not main then
        return nil
    end
    local st = state_of(owner, key, true)
    st.links = {main}
    st.ticks = 0
    st.scene = scene_of(owner)
    st.owner_obj_id = owner.get_obj_id and owner:get_obj_id() or define.INVAILD_ID
    return st
end

function M.chain_get(owner, key)
    return state_of(owner, key, false)
end

-- Một nhịp của chuỗi. `cfg`:
--   max_links   = số mắt xích NỐI THÊM tối đa (tổng = max_links + 1)
--   break_main  = mục tiêu chính rời chủ quá bấy nhiêu mét → ĐỨT cả chuỗi
--   break_other = mắt xích rời mục tiêu CHÍNH quá bấy nhiêu mét → rời khỏi chuỗi
--   max_ticks   = trần số nhịp
--   scan        = hàm (center_obj, radius) → danh sách địch của chủ quanh đó
-- Trả về danh sách mắt xích còn sống theo THỨ TỰ NỐI (chỉ số = nấc sát thương), rỗng nghĩa là chuỗi dừng.
function M.chain_tick(owner, key, cfg)
    local st = state_of(owner, key, false)
    if not st or type(st.links) ~= "table" then
        return {}
    end
    cfg = cfg or {}
    st.ticks = (st.ticks or 0) + 1
    local max_ticks = math.min(num(cfg.max_ticks) or M.MAX_TICKS, M.MAX_TICKS)
    if st.ticks > max_ticks or not M.owner_alive(owner, st.scene, st.owner_obj_id) then
        M.chain_clear(owner, key)
        return {}
    end

    local main = st.links[1]
    local break_main = num(cfg.break_main)
    if not M.alive(main) or scene_of(main) ~= st.scene then
        M.chain_clear(owner, key)
        return {}
    end
    if break_main and break_main > 0 then
        local d = M.dist(owner, main)
        if d and d > break_main then           -- "被链接的目标离开攻击范围后会断开链接"
            M.chain_clear(owner, key)
            return {}
        end
    end

    local break_other = num(cfg.break_other)
    local kept, seen = {main}, {[main] = true}
    for i = 2, #st.links do
        local o = st.links[i]
        local keep = o ~= nil and not seen[o] and M.alive(o) and scene_of(o) == st.scene
        if keep and break_other and break_other > 0 then
            local d = M.dist(main, o)
            keep = (d == nil) or (d <= break_other)
        end
        if keep then
            kept[#kept + 1] = o
            seen[o] = true
        end
    end

    local max_links = math.min(num(cfg.max_links) or 0, M.MAX_LINKS)
    if #kept < max_links + 1 and type(cfg.scan) == "function" then
        local ok, list = pcall(cfg.scan, main, break_other or 5)
        if ok and type(list) == "table" then
            for _, nb in ipairs(list) do
                if not seen[nb] and nb ~= owner and M.alive(nb) then
                    kept[#kept + 1] = nb
                    seen[nb] = true
                    break                        -- "每0.8秒额外链接目标附近一名敌对目标" — mỗi nhịp một mắt
                end
            end
        end
    end

    st.links = kept
    return kept
end

return M
