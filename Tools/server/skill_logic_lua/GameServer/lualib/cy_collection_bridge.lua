-- skill-logic-4 (CY-Source 17/09/2026): ĐIỀU KIỆN / TIÊU HAO của kỹ năng tra TẬP ID theo bảng CY.
--
-- VÌ SAO **[DK]**
-- `impactenginer:is_impact_in_collection` (lualib/impactenginer.lua:194) tra `configs/IDCollections.txt`
-- — bản **GL/HJS, 375 dòng**. SkillData của CY 3.71 lại trỏ tới **IDCollections của CY (532 dòng,
-- lualib/cy_idcollections.lua)**. Hai bảng dùng CHUNG dãy số nhưng khác nghĩa, nên mọi ô điều kiện/tiêu hao
-- kiểu "tập ID" của chiêu CY hoặc **im lặng sai** hoặc **không bao giờ đạt**:
--
--   tập | GL (configs/IDCollections.txt) | CY (cy_idcollections.lua)      | hậu quả
--   ----|-------------------------------|--------------------------------|------------------------------
--   499 | KHÔNG CÓ DÒNG                 | 回天术九阳状态 {2631}            | 827–830 ·九阳 KHÔNG BAO GIỜ dùng được
--   376 | 拘魂天 {6510}                  | 斩情诀BUFF {151}                | 832–834 ·九阴 KHÔNG BAO GIỜ dùng được
--   388 | 失魂天+AB {467,477}            | 所有门派姿态buff {105,117,…}     | 驱散 của 28 chiêu 姿态 gỡ nhầm 灼烧
--   389 | 失魂命+AB {476,477}            | 所有门派姿态下技能buff {106,109,…}| như trên
--   128 | 心剑交融BUFF借力 {19001}        | 心剑交融BUFF借力 {1529}          | 777 gỡ nhầm
--
-- Hậu quả dây chuyền của 388/389: vì trạng thái 姿态 CŨ không được gỡ, nên khi người chơi đổi 姿态,
-- `character:replace_mutually_exclusive_impact` (obj/character.lua:1385) thấy cùng 互斥ID mà
-- `can_impactA_replace_impactB` (= `ưu tiên mới >= ưu tiên cũ`) sai ⇒ **bỏ im lặng** impact mới
-- (nhánh else chỉ DỰNG gói `GCCharSkill_Missed` rồi `return true`, không hề gửi).
-- Đó chính là "2912 催箭式 / 3446 意纵横 gửi chiêu mà không có GCCharBuff":
--   催箭式 ưu tiên 10 < 震箭式 90 (cùng 互斥 105); 意纵横 120 < 逍遥游 131 (cùng 互斥 150).
-- Bằng chứng số: Build\Logs\2026-09-17-skill-logic-4\{04-stance-mutex,07-dispel-collections,08-stance-cover,
-- 12-dispel-blast2,13-condition-collections}.txt.
--
-- PHẠM VI: chỉ ba logic điều kiện/tiêu hao đọc tập ID từ SkillData và chưa CY-hoá:
--   0  C_UNIT_MUST_HAVE_IMPACT   (550 ô khớp cả hai bảng + 128 ô CHỈ có ở bảng CY)
--   2  C_TARGET_MUST_HAVE_IMPACT (2 ô)
--   9  D_CANCEL_SPECIFIC_IMPACT  (912 ô — toàn bộ chỉ dùng tập 128/388/389)
-- Các kiểu 16/18/19/20 đã do `scene.skill.condition_cy` lo (đọc thẳng cy_idcollections).
-- KHÔNG đụng `impactenginer:is_impact_in_collection` — nó còn phục vụ std_impact_*/talent của GL.
--
-- LUẬT KHỚP (hợp — union, không bao giờ biến một kết quả "đúng" của GL thành "sai"):
--   * giữ nguyên kết quả bảng GL;
--   * cộng thêm kết quả bảng CY theo đúng bảng kiểu của `define.CollectionIdType`
--     (0 = 瞬发效果ID khi impact là hiệu ứng duy trì, 1/5 = 互斥ID, 2 = 逻辑ID, 3 = 技能ID);
--   * VỚI KIỂU 互斥 (1/5) khớp THÊM 瞬发效果ID (chỉ khi `is_over_timed`): các dòng StandardImpact do CY
--     thêm trên server riêng giữ **互斥ID cũ của GL** nhưng mang **ID CY ở cột 瞬发效果ID**
--     (逍遥游 42276: 互斥 150 / SEid 3651; 意纵横 42325: 互斥 150 / SEid 3653; 战可得威 45196: SEid 4159 —
--     cả ba SEid đều nằm trong tập CY 388, còn 150 thì không). Đo bán kính ảnh hưởng của luật thêm này:
--     **chỉ 4 nhóm, 112 dòng 持续性** (逍遥游, 意纵横, 战可得威, 经脉逆行) — `12-dispel-blast2.txt`.
--
-- Công tắc: đặt `M.ENABLED = false` (một dòng) để trả mọi thứ về hành vi cũ mà không cần gỡ bản vá.
local define = require "define"

local M = {}

M.ENABLED = true

-- define.CollectionIdType: 0 BUFF(瞬发效果ID) | 1 MUTEX | 2 IMPACT_LOGIC | 3 SKILL | 4 SKILL_LOGIC | 5 DIRECT(互斥)
local T = define.CollectionIdType or {TYPE_BUFF_ID = 0, TYPE_IMPACT_MUTEX_ID = 1,
                                      TYPE_IMPACT_LOGIC_ID = 2, TYPE_SKILL_ID = 3,
                                      TYPE_SKILL_LOGIC_ID = 4, TYPE_DIRECT_IMPACT_ID = 5}
local INVALID = define.INVAILD_ID

function M.table()
    local ok, t = pcall(require, "cy_idcollections")
    if ok and type(t) == "table" then
        return t
    end
    return nil
end

function M.row(collection_id)
    collection_id = tonumber(collection_id)
    if collection_id == nil or collection_id == INVALID then
        return nil
    end
    local t = M.table()
    local row = t and t[collection_id]
    if type(row) == "table" and type(row.ids) == "table" then
        return row
    end
    return nil
end

local function get(imp, name)
    local f = imp and imp[name]
    if type(f) ~= "function" then
        return nil
    end
    local ok, v = pcall(f, imp)
    if not ok then
        return nil
    end
    return tonumber(v)
end

-- Chặt hơn `is_impact_in_collection` một chút: bỏ cả giá trị 0 (bảng CY có dòng chứa ID 0, vd tập 59
-- 大理攻击技能). Luật của module này là HỢP nên chặt hơn chỉ có thể cho ÍT kết quả thêm, không bao giờ sai.
local function member(ids, v)
    return v ~= nil and v ~= INVALID and v > 0 and ids[v] == true
end

-- `get_is_over_timed` trả BOOLEAN nên không dùng chung với `get` (vốn tonumber)
local function over_timed(imp)
    local f = imp and imp.get_is_over_timed
    if type(f) ~= "function" then
        return false
    end
    local ok, v = pcall(f, imp)
    return ok and v and true or false
end

-- một impact có thuộc dòng tập CY hay không
function M.match(imp, row)
    if not imp or not row then
        return false
    end
    local ty = tonumber(row.type)
    local ids = row.ids
    local over = over_timed(imp)
    if ty == T.TYPE_BUFF_ID then
        -- như is_impact_in_collection: chỉ hiệu ứng duy trì mới so bằng 瞬发效果ID
        return over and member(ids, get(imp, "get_impact_id")) and true or false
    elseif ty == T.TYPE_IMPACT_LOGIC_ID then
        return member(ids, get(imp, "get_logic_id"))
    elseif ty == T.TYPE_SKILL_ID then
        return member(ids, get(imp, "get_skill_id"))
    elseif ty == T.TYPE_IMPACT_MUTEX_ID or ty == T.TYPE_DIRECT_IMPACT_ID then
        if member(ids, get(imp, "get_mutex_id")) then
            return true
        end
        -- cầu nối cho dòng CY của server riêng (xem đầu file)
        return over and member(ids, get(imp, "get_impact_id")) and true or false
    end
    return false
end

local function impact_list(obj)
    if not obj or type(obj.get_impact_list) ~= "function" then
        return nil
    end
    local ok, list = pcall(obj.get_impact_list, obj)
    return (ok and type(list) == "table") and list or nil
end

-- bản thân/đối tượng có impact thuộc tập CY không
function M.has(obj, collection_id)
    local row = M.row(collection_id)
    local list = row and impact_list(obj)
    if not list then
        return false
    end
    for _, imp in ipairs(list) do
        if M.match(imp, row) then
            return true
        end
    end
    return false
end

-- gỡ mọi impact thuộc tập CY (đúng cách của character:impact_cancel_impact_in_specific_collection)
function M.cancel(obj, collection_id)
    local row = M.row(collection_id)
    local list = row and impact_list(obj)
    if not list then
        return 0
    end
    local n = 0
    for i = #list, 1, -1 do
        local imp = list[i]
        if M.match(imp, row) then
            pcall(obj.on_impact_fade_out, obj, imp)
            pcall(obj.remove_impact, obj, imp)
            n = n + 1
        end
    end
    return n
end

local function set_ok(obj)
    local f = obj and obj.get_targeting_and_depleting_params
    if type(f) ~= "function" then
        return
    end
    local ok, params = pcall(f, obj)
    if ok and params and params.set_errcode then
        pcall(params.set_errcode, params, define.OPERATE_RESULT.OR_OK)
    end
end

local function target_of(obj)
    local f = obj and obj.get_targeting_and_depleting_params
    if type(f) ~= "function" then
        return nil
    end
    local ok, params = pcall(f, obj)
    if not ok or not params or not params.get_target_obj then
        return nil
    end
    local ok2, tid = pcall(params.get_target_obj, params)
    if not ok2 or not tid or tid == INVALID then
        return nil
    end
    local ok3, scene = pcall(obj.get_scene, obj)
    if not ok3 or not scene or not scene.get_obj_by_id then
        return nil
    end
    local ok4, tar = pcall(scene.get_obj_by_id, scene, tid)
    return ok4 and tar or nil
end

-- bọc một logic điều kiện đã có: GL trước, bảng CY sau (chỉ THÊM kết quả đúng)
local function wrap_have(prev, holder)
    return {
        ConditionCheck = function(_, obj, data)
            local ok, r = pcall(prev.ConditionCheck, prev, obj, data)
            if ok and r then
                return true
            end
            if not M.ENABLED then
                return ok and r or false
            end
            local who = (holder == 'target') and target_of(obj) or obj
            local ok2, hit = pcall(M.has, who, data.params and data.params[1])
            if ok2 and hit then
                set_ok(obj)
                return true
            end
            return ok and r or false
        end,
        Deplete = function(_, obj, data)
            local ok, r = pcall(prev.Deplete, prev, obj, data)
            return ok and r or true
        end,
    }
end

local function wrap_cancel(prev)
    return {
        ConditionCheck = function(_, obj, data)
            local ok, r = pcall(prev.ConditionCheck, prev, obj, data)
            if ok then
                return r
            end
            return true
        end,
        Deplete = function(_, obj, data)
            local ok, r = pcall(prev.Deplete, prev, obj, data)           -- giữ nguyên phép gỡ theo bảng GL
            if M.ENABLED then
                pcall(M.cancel, obj, data.params and data.params[1])     -- cộng thêm phép gỡ theo bảng CY
            end
            return ok and r or true
        end,
    }
end

function M.install(core)
    if not core or type(core.logics) ~= "table" or core.__cy_collection_bridge then
        return core
    end
    local D = define.ConditionAndDepleteID
    local pairs_to_wrap = {
        {D.C_UNIT_MUST_HAVE_IMPACT, 'self', wrap_have},
        {D.C_TARGET_MUST_HAVE_IMPACT, 'target', wrap_have},
        {D.D_CANCEL_SPECIFIC_IMPACT, 'self', wrap_cancel},
    }
    for _, e in ipairs(pairs_to_wrap) do
        local id, holder, wrap = e[1], e[2], e[3]
        local prev = id and core.logics[id]
        if prev then
            core.logics[id] = (wrap == wrap_cancel) and wrap(prev) or wrap(prev, holder)
        end
    end
    core.__cy_collection_bridge = true
    return core
end

return M
