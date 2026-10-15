local class  = require "class"
local skynet = require "skynet"
local base   = require "scene.skill.impact_logic.base"

local std_impact_548 = class("std_impact_548", base)

-- 20个参数映射表：idx=StandardImpact参数编号, key=imp.params缓存键, refix=get_refix_xxx后缀
local PARAM_MAP = {
    {idx = 1,  key = "pct_str",           refix = "str"},
    {idx = 2,  key = "pct_spr",           refix = "spr"},
    {idx = 3,  key = "pct_con",           refix = "con"},
    {idx = 4,  key = "pct_int",           refix = "int"},
    {idx = 5,  key = "pct_dex",           refix = "dex"},
    {idx = 6,  key = "pct_att_p",         refix = "attrib_att_physics"},
    {idx = 7,  key = "pct_att_m",         refix = "attrib_att_magic"},
    {idx = 8,  key = "pct_hit",           refix = "attrib_hit"},
    {idx = 9,  key = "pct_miss",          refix = "attrib_miss"},
    {idx = 10, key = "pct_mind_attack",   refix = "mind_attack"},
    {idx = 11, key = "pct_def_cold",      refix = "def_cold"},
    {idx = 12, key = "pct_def_fire",      refix = "def_fire"},
    {idx = 13, key = "pct_def_poison",    refix = "def_poison"},
    {idx = 14, key = "pct_def_light",     refix = "def_light"},
    {idx = 15, key = "pct_hp_max",        refix = "hp_max"},
    {idx = 16, key = "pct_reduce_damage",      refix = "reduce_damage"},
    {idx = 17, key = "pct_reduce_cold_low",   refix = "reduce_def_cold_low_limit"},
    {idx = 18, key = "pct_reduce_fire_low",   refix = "reduce_def_fire_low_limit"},
    {idx = 19, key = "pct_reduce_light_low",  refix = "reduce_def_light_low_limit"},
    {idx = 20, key = "pct_reduce_poison_low", refix = "reduce_def_poison_low_limit"},
}

function std_impact_548:is_over_timed()
    return true
end

function std_impact_548:on_active(imp, obj)
    if not obj then return end
    local has_any = false
    for _, entry in ipairs(PARAM_MAP) do
        local v = imp:get_param_by_index(entry.idx) or 0
        imp.params[entry.key] = v
        if v ~= 0 then has_any = true end
    end
    -- 调试日志：输出所有非零属性加成
    local debug_parts = {}
    for _, entry in ipairs(PARAM_MAP) do
        local v = imp.params[entry.key] or 0
        if v ~= 0 then
            table.insert(debug_parts, string.format("%s=%d", entry.key, math.floor(v)))
        end
    end
    if #debug_parts > 0 then
        skynet.error(string.format("[IMPACT_548] on_active: target=%s impact_id=%s 兽灵属性加成: %s",
            tostring(obj:get_name()), tostring(imp:get_impact_id()), table.concat(debug_parts, ", ")))
    else
        skynet.error(string.format("[IMPACT_548] on_active: target=%s impact_id=%s (无非零属性参数)",
            tostring(obj:get_name()), tostring(imp:get_impact_id())))
    end
    if has_any then
        self:mark_modified_attr_dirty(imp, obj)
        if obj.send_refresh_attrib then
            obj:send_refresh_attrib()
        end
    end
end

function std_impact_548:on_fade_out(imp, obj)
    -- 调试日志：输出正在移除的属性加成
    local debug_parts = {}
    for _, entry in ipairs(PARAM_MAP) do
        local v = imp.params[entry.key] or 0
        if v ~= 0 then
            table.insert(debug_parts, string.format("%s=%d", entry.key, math.floor(v)))
        end
    end
    if #debug_parts > 0 then
        skynet.error(string.format("[IMPACT_548] on_fade_out: target=%s 移除兽灵属性加成: %s",
            obj and tostring(obj:get_name()) or "nil", table.concat(debug_parts, ", ")))
    else
        skynet.error(string.format("[IMPACT_548] on_fade_out: target=%s",
            obj and tostring(obj:get_name()) or "nil"))
    end
    for _, entry in ipairs(PARAM_MAP) do
        imp.params[entry.key] = 0
    end
    if obj then
        self:mark_modified_attr_dirty(imp, obj)
        if obj.send_refresh_attrib then
            obj:send_refresh_attrib()
        end
    end
end

-- 动态生成所有 get_refix_xxx 方法
for _, entry in ipairs(PARAM_MAP) do
    std_impact_548["get_refix_" .. entry.refix] = function(self, imp, args, obj)
        local v = imp.params[entry.key] or 0
        if v ~= 0 then
            args.point = (args.point or 0) + v
            skynet.error(string.format("[IMPACT_548] get_refix_%s: +%d (兽灵加成)",
                entry.refix, math.floor(v)))
        end
    end
end


return std_impact_548
