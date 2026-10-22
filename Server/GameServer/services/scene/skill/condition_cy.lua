

















local define = require "define"

local M = {}

M.TYPE = {TAO_EMPATHY = 16, JUE_BLADE = 17, UNIT_NOT_HAVE = 18, TARGET_COUNT = 19, UNIT_HAVE = 20, TIANJI = 21}
M.MENPAI_TAO, M.MENPAI_JUE = 13, 14
M.TAO_SKILL_COLLECTION = 340
M.RES_EMPATHY, M.RES_BLADE = 328, 331
M.JUE_BLADE_DEPLETE = {[4530] = true, [4533] = true, [4534] = true, [4538] = true}

local function collections()
    return require "cy_idcollections"
end

local function ok(obj, result, errcode)
    local params = obj:get_targeting_and_depleting_params()
    params:set_errcode(result and define.OPERATE_RESULT.OR_OK or (errcode or define.OPERATE_RESULT.OR_U_CANNT_DO_THIS_RIGHT_NOW))
    return result
end

local function is_human(obj)
    return obj and obj.get_obj_type and obj:get_obj_type() == "human"
end

function M.in_collection(id, collection_id)
    local c = collections()[collection_id]
    return c ~= nil and id ~= nil and c.ids[id] == true
end

-- PublicA::xyzServerScanTargetIsImpactInCollectionEx: số impact có MutexID ∈ tập
function M.count_impacts(obj, collection_id)
    local n = 0
    if not obj or not obj.get_impact_list then
        return 0
    end
    for _, imp in ipairs(obj:get_impact_list() or {}) do
        if M.in_collection(imp:get_mutex_id(), collection_id) then
            n = n + 1
        end
    end
    return n
end

local function skill_id(obj)
    local info = obj:get_skill_info()
    return info and info:get_skill_id()
end

local function packed(v, base)
    v = math.tointeger(v) or 0
    if v < 0 then v = 0 end
    return v // base, v % base
end

local function resource(obj, id)
    return obj.get_cy_four_resource and obj:get_cy_four_resource(id) or 0
end

local function doll_id(obj)
    local okc, cb = pcall(require, "cy_four_combat.callbacks")
    if okc and cb and cb.get_doll_id then
        return cb.get_doll_id(obj)
    end
    return -1
end

local function resources_bridge(obj)
    local scene = obj:get_scene()
    local engine = scene and scene:get_impact_enginer()
    local bridge = engine and engine.cy_four_bridge
    if bridge and bridge.config and bridge.config.gameplay_enabled == false then
        return nil
    end
    return bridge and bridge.resources
end

-- tiêu hao như native: dồn vào hàng chờ của bridge (trừ khi dùng kỹ năng thành công, có hoàn talent 共情), không có bridge thì trừ ngay
local function queue_cost(obj, kind, need)
    local info = obj:get_skill_info()
    local res = resources_bridge(obj)
    if res and res.pending then
        local p = res.pending[obj]
        if not p or p.info ~= info then
            p = {info = info, id = info:get_skill_id(), data_id = info._cy_four_data_id, costs = {}}
            res.pending[obj] = p
        end
        p.costs[kind == "empathy" and 8016 or 8017] = {kind = kind, need = need}
        return true
    end
    local field, base = kind == "empathy" and M.RES_EMPATHY or M.RES_BLADE, kind == "empathy" and 10000 or 10
    local cap, current = packed(resource(obj, field), base)
    obj:set_cy_four_resource(field, cap * base + math.max(0, current - need))
    return true
end

local logics = {}

-- 16 消耗能量（条件+消耗）— 桃花岛 共情
logics[M.TYPE.TAO_EMPATHY] = {
    applies = function(obj)
        return is_human(obj) and obj:get_menpai() == M.MENPAI_TAO and M.in_collection(skill_id(obj), M.TAO_SKILL_COLLECTION)
    end,
    condition = function(self, obj, data)
        if not self.applies(obj) then
            return ok(obj, true)
        end
        local _, current = packed(resource(obj, M.RES_EMPATHY), 10000)
        if current < (tonumber(data.params[1]) or 0) then
            return ok(obj, false)
        end
        return ok(obj, doll_id(obj) > 0)
    end,
    deplete = function(self, obj, data)
        if self.applies(obj) then
            queue_cost(obj, "empathy", math.max(0, tonumber(data.params[1]) or 0))
        end
        return ok(obj, true)
    end,
}

-- 17 刀意需求 — 绝情谷
logics[M.TYPE.JUE_BLADE] = {
    condition = function(_, obj, data)
        if not is_human(obj) or obj:get_menpai() ~= M.MENPAI_JUE then
            return ok(obj, true)
        end
        local _, current = packed(resource(obj, M.RES_BLADE), 10)
        return ok(obj, current >= (tonumber(data.params[1]) or 0))
    end,
    deplete = function(_, obj, data)
        if is_human(obj) and obj:get_menpai() == M.MENPAI_JUE and M.JUE_BLADE_DEPLETE[skill_id(obj)] then
            queue_cost(obj, "blade", math.max(0, tonumber(data.params[1]) or 0))
        end
        return ok(obj, true)
    end,
}

-- 18 自身不可携带的buff集合 (九阴/九阳/移花接木/蒙面巾/拘魂…)
logics[M.TYPE.UNIT_NOT_HAVE] = {
    condition = function(_, obj, data)
        if not is_human(obj) then
            return ok(obj, true)
        end
        return ok(obj, M.count_impacts(obj, tonumber(data.params[1])) == 0)
    end,
}

-- 19 mục tiêu phải có ≥ p1 impact thuộc tập p0
logics[M.TYPE.TARGET_COUNT] = {
    condition = function(_, obj, data)
        if not is_human(obj) then
            return ok(obj, true)
        end
        local params = obj:get_targeting_and_depleting_params()
        local tid = params:get_target_obj()
        if not tid or tid == 0 or tid == define.INVAILD_ID then
            return ok(obj, true)
        end
        local tar = obj:get_scene():get_obj_by_id(tid)
        if not tar then
            return ok(obj, true)
        end
        return ok(obj, M.count_impacts(tar, tonumber(data.params[1])) >= (tonumber(data.params[2]) or 0))
    end,
}

-- 20 图腾数量 — bản thân phải có impact thuộc tập p0
logics[M.TYPE.UNIT_HAVE] = {
    condition = function(_, obj, data)
        if not is_human(obj) then
            return ok(obj, true)
        end
        return ok(obj, M.count_impacts(obj, tonumber(data.params[1])) > 0)
    end,
}

-- 21 需要天机点: native không kiểm/không trừ (CDCore mặc định 1)
logics[M.TYPE.TIANJI] = {}

M.logics = logics

-- ConDepLogic_T-tương thích cho condition_delplete_core.logics
local function wrap(t)
    return {
        ConditionCheck = function(_, obj, data)
            if t.condition then
                return t.condition(t, obj, data)
            end
            return ok(obj, true)
        end,
        Deplete = function(_, obj, data)
            if t.deplete then
                return t.deplete(t, obj, data)
            end
            return true
        end,
    }
end

-- CDCore_T native: kiểu không có trong switch → đạt, không tiêu hao (thay assert làm sập chiêu)
M.default_logic = {
    ConditionCheck = function(_, obj)
        return ok(obj, true)
    end,
    Deplete = function()
        return true
    end,
}

function M.install(core)
    for id, t in pairs(logics) do
        core.logics[id] = wrap(t)
    end
    core.cy_default_logic = M.default_logic
    return core
end

return M
