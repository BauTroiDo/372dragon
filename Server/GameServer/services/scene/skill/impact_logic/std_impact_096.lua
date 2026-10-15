-- 破天式飞剑状态 (继承std_impact_014状态行为 + 周期性创建飞剑SpecialObj)
local class = require "class"
local define = require "define"
local skynet = require "skynet"
local std_impact_014 = require "scene.skill.impact_logic.std_impact_014"
local configenginer = require "configenginer":getinstance()
local std_impact_096 = class("std_impact_096", std_impact_014)

local DEBUG_POTIANSHI = skynet.getenv("debug_potianshi") == "1"
local function dlog(...) if DEBUG_POTIANSHI then skynet.logi(...) end end

-- 检查角色的飞剑相关武道并写入 sword_obj 标志
local function apply_talent_flags(sword_obj, obj)
    if not obj.get_talent then return end
    local talent = obj:get_talent()
    if not talent or not talent.study then return end
    local sect_desc = configenginer:get_config("sect_desc")
    if not sect_desc then return end
    for _, t in ipairs(talent.study) do
        if t.id == 956 then
            local cfg = sect_desc[956]
            if cfg and cfg.params then
                local lv = t.level == 0 and 1 or t.level
                sword_obj._search_range = cfg.params[lv] and cfg.params[lv][1] or 0
                sword_obj._prefer_player = true
            end
        elseif t.id == 959 then
            local cfg = sect_desc[959]
            if cfg and cfg.params then
                local lv = t.level == 0 and 1 or t.level
                sword_obj._paralyze_extend = cfg.params[lv] and cfg.params[lv][1] or 0
            end
        elseif t.id == 946 then
            -- 踏破虚空：飞剑追击敌对目标
            --sword_obj._chasing = true
        end
    end
end

function std_impact_096:is_over_timed()
    return true
end

function std_impact_096:is_intervaled()
    return true
end

function std_impact_096:get_special_obj_data_id(imp)
    return imp.params["特殊对象数据ID"] or define.INVAILD_ID
end

function std_impact_096:get_max_sword_count(imp)
    return imp.params["飞剑最大数量"] or 10
end

function std_impact_096:on_active(imp, obj)
    dlog("[PoTianShi] on_active called, impact_id=", imp:get_data_index())
    dlog("[PoTianShi] params=", imp.params["特殊对象数据ID"], " max=", imp.params["飞剑最大数量"])
    std_impact_014.on_active(self, imp, obj)
    imp._sword_count = 0
    self:create_sword(imp, obj)
end

function std_impact_096:create_sword(imp, obj)
    local data_id = self:get_special_obj_data_id(imp)
    dlog("[PoTianShi] create_sword data_id=", data_id, " count=", imp._sword_count)
    if data_id == define.INVAILD_ID then
        dlog("[PoTianShi] create_sword ABORT: data_id is INVALID")
        return
    end
    local special_obj_data = configenginer:get_config("special_obj_data")
    if not special_obj_data then
        dlog("[PoTianShi] create_sword ABORT: special_obj_data config is nil")
        return
    end
    if not special_obj_data[data_id] then
        dlog("[PoTianShi] create_sword ABORT: no entry for data_id=", data_id)
        return
    end
    local max_count = self:get_max_sword_count(imp)
    local count = imp._sword_count or 0
    if count >= max_count then
        dlog("[PoTianShi] create_sword ABORT: reached max count=", count, "/", max_count)
        return
    end
    local skill_id = imp:get_skill_id()
    local pos = obj:get_world_pos()
    dlog("[PoTianShi] creating SpecialObj data_id=", data_id, " skill_id=", skill_id)
    -- 检测武道：在同一循环中处理，不会同时命中（易势 vs 谋定不同分支）
    if obj.get_talent then
        local talent = obj:get_talent()
        if talent and talent.study then
            for _, t in ipairs(talent.study) do
                if t.id == 946 then
                    local scene = obj:get_scene()
                    if scene then
                        local chase_radius = 15
                        local operate = {scaner = obj, obj = obj, x = pos.x, y = pos.y, target_logic_by_stand = 1, radious = chase_radius, count = 30}
                        local enemies = scene:scan(operate)
                        if #enemies > 0 then
                            local idx = math.random(#enemies)
                            pos = enemies[idx]:get_world_pos()
                            dlog("[PoTianShi] 踏破虚空: chase to enemy at (", pos.x, ",", pos.y, ")")
                        end
                    end
                    break
                elseif t.id == 956 then
                    local scene = obj:get_scene()
                    if scene then
                        local operate = {scaner = obj, obj = obj, x = pos.x, y = pos.y, target_logic_by_stand = 1, radious = 15, count = 10}
                        for _, e in ipairs(scene:scan(operate)) do
                            if e:get_obj_type() == "human" then
                                pos = e:get_world_pos()
                                dlog("[PoTianShi] 飞剑逐踪: spawn at human (", pos.x, ",", pos.y, ")")
                                break
                            end
                        end
                    end
                    break
                end
            end
        end
    end
    local sword_obj = obj:skill_create_obj_specail(pos, data_id, skill_id)
    if sword_obj then
        local sword_rate = imp.params["飞剑伤害百分比"] or 0
        sword_obj._potianshi_rate = sword_rate
        apply_talent_flags(sword_obj, obj)
        self:register_active_obj(sword_obj, obj, 500, skill_id)
        imp._sword_count = count + 1
        dlog("[PoTianShi] sword created OK, count=", imp._sword_count, " rate=", sword_rate, "%")
    else
        dlog("[PoTianShi] create_sword FAILED: skill_create_obj_specail returned nil")
    end
end

function std_impact_096:on_interval_over(imp, obj)
    dlog("[PoTianShi] on_interval_over, sword_count=", imp._sword_count)
    self:create_sword(imp, obj)
end

function std_impact_096:on_fade_out(imp, obj)
    dlog("[PoTianShi] on_fade_out, total swords=", imp._sword_count)
    std_impact_014.on_fade_out(self, imp, obj)
    imp._sword_count = nil
end

-- 外部调用：在角色身上查找飞剑状态并额外创建一把飞剑
-- opts.no_paralyze = true 表示该飞剑不附带麻痹
-- opts.paralyze_rate = N   自定义麻痹概率(如50)
-- 返回 true/false
function std_impact_096:create_extra_sword(obj, opts)
    local impacts = obj:get_impact_list()
    for i = #impacts, 1, -1 do
        local imp = impacts[i]
        if imp:get_logic_id() == 96 then
            local data_id = self:get_special_obj_data_id(imp)
            if data_id == define.INVAILD_ID then return false end
            local special_obj_data = configenginer:get_config("special_obj_data")
            if not special_obj_data or not special_obj_data[data_id] then return false end
            local skill_id = imp:get_skill_id()
            local pos = obj:get_world_pos()
            local sword_obj = obj:skill_create_obj_specail(pos, data_id, skill_id)
            if sword_obj then
                local sword_rate = imp.params["飞剑伤害百分比"] or 0
                sword_obj._potianshi_rate = sword_rate
                if opts then
                    sword_obj._no_paralyze = opts.no_paralyze or false
                    sword_obj._paralyze_rate = opts.paralyze_rate
                end
                apply_talent_flags(sword_obj, obj)
                self:register_active_obj(sword_obj, obj, 500, skill_id)
                imp._sword_count = (imp._sword_count or 0) + 1
                dlog("[PoTianShi] extra sword created, no_paralyze=", opts and opts.no_paralyze or false)
                return true
            end
            return false
        end
    end
    return false
end

return std_impact_096
