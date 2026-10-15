local class = require "class"
local define = require "define"
local packet_def = require "game.packet"
local impactenginer = require "impactenginer":getinstance()
local monster_attrib = class("monster_attrib")

local must_be_positive = {
    attrib_att_magic = true,
    attrib_att_physics = true,
    attrib_def_magic = true,
    attrib_def_physics = true,
    attrib_hit = true,
    attrib_miss = true,
    hp = true,
    hp_max = true,
    mp = true,
    mp_max = true,
    mind_attack = true,
    mind_defend = true,
    datura_flower = true,
    att_cold = true,
    reduce_def_cold = true,
    att_fire = true,
    reduce_def_fire = true,
    att_light = true,
    reduce_def_light = true,
    att_poison = true,
    reduce_def_poison = true,
    str = true,
    spr = true,
    con = true,
    int = true,
    dex = true,
    exp = true,
    hp_re_speed = true,
    mp_re_speed = true,
}

local base_attribs = {
    name = true,
    title = true,
    model = true,
    portrait_id = true,
    model_id = true,
    guid = true,
    level = true,
    owner_id = true,
    team_id = true,
    speed = true,
    rage = true,
    stealth_level = true,
    is_sit = true,
    hp = true,
    mp = true,
    hp_max = true,
    mp_max = true,
    reputation = true,
    camp_id = true,
    team_occipant_guid = true,
    raid_occipant_guid = true,
}

local detail_attribs = {
    attrib_att_magic = true,
    attrib_att_physics = true,
    attrib_def_magic = true,
    attrib_def_physics = true,
    attrib_hit = true,
    attrib_miss = true,
    hp = true,
    hp_max = true,
    mp = true,
    mp_max = true,
    level = true,
    mind_attack = true,
    mind_defend = true,
    att_cold = true,
    def_cold = true,
    reduce_def_cold = true,
    att_fire = true,
    def_fire = true,
    reduce_def_fire = true,
    att_light = true,
    def_light = true,
    reduce_def_light = true,
    att_poison = true,
    def_poison = true,
    reduce_def_poison = true,
    speed = true,
    fashion_depot_index = true,
    can_action_1 = true,
    can_action_2 = true,
    reputation = true,
    model_id = true
}

local refix_by_other = {
    mp = function(self, value)
        local mp_max = self:get_attrib("mp_max")
        if mp_max < value then
            value = mp_max
        end
        return value
    end,
    hp = function(self, value)
        local hp_max = self:get_attrib("hp_max")
        if hp_max < value then
            value = hp_max
        end
        return value
    end,
}
function monster_attrib:ctor(monster, attribs)
    self.monster = monster
    attribs.can_move = 1
    attribs.can_action_1 = 1
    attribs.can_action_2 = 1
    attribs.unbreakable = 0
    attribs.stealth_level = 0
    attribs.can_ignore_disturb = 0
    self.db_attribs = attribs
    self.attribs = {}
    self.attribs_refix = {}
    self.dirty_flags = {}
    self.refix_dirty_flags = {}
    self.item_effect = {}
    self.item_effect = {}
    self.dirty_datas = {}
    self:mark_all_attr_dirty()
end

function monster_attrib:mark_all_attr_dirty()
    for key in pairs(detail_attribs) do
        self.dirty_flags[key] = true
    end
    for key in pairs(base_attribs) do
        self.dirty_flags[key] = true
    end
end

function monster_attrib:mark_attrib_dirty(key)
    self.dirty_flags[key] = true
end

function monster_attrib:get_dirty_flags (key)
    return self.dirty_flags[key] ~= nil or self.refix_dirty_flags[key] ~= nil
end

function monster_attrib:clear_dirty_flag(key)
    self.dirty_flags[key] = nil
end

function monster_attrib:get_base_attrib(key)
    if refix_by_other[key] then
        local value = refix_by_other[key](self, self.db_attribs[key])
        if must_be_positive[key] then
            assert(value >= 0)
        end
        self:set_db_attrib({[key] = value})
    end
    local value = self.db_attribs[key]
    return value
end

function monster_attrib:set_attrib_refix(key, value)
    self.attribs_refix[key] = value
end

function monster_attrib:get_exist_attrib_refix(key)
    return self.attribs_refix[key]
end

function monster_attrib:get_attrib_refix_dirty(key)
    return self.refix_dirty_flags[key]
end

function monster_attrib:clear_attrib_refix_dirty(key)
    self.refix_dirty_flags[key] = nil
end

function monster_attrib:mark_attrib_refix_dirty(key)
    --print("monster_attrib:mark_attrib_refix_dirty", key)
    self.refix_dirty_flags[key] = true
end

function monster_attrib:imp_get_attrib_refix(key)
    local value = { rate = 0, point = 0}
    local monster = self:get_monster()
    local impacts = monster:get_impact_list()
    for _, imp in ipairs(impacts) do
        local logic = impactenginer:get_logic(imp)
        if logic then
            logic:get_refix(imp, key, value, monster)
        end
    end
    return value
end

function monster_attrib:get_attrib_refix(key)
    if self:get_attrib_refix_dirty(key) then
        local value = self:imp_get_attrib_refix(key)
        self:set_attrib_refix(key, value)
        self:clear_attrib_refix_dirty(key)
    end
    return self:get_exist_attrib_refix(key)
end

function monster_attrib:get_attrib(key)
    if self:get_dirty_flags(key) then
        local value
        local base = self:get_base_attrib(key)
        value = base
        if type(base) == "number" then
            local impact_skill_refix
            impact_skill_refix = self:get_attrib_refix(key)
            if impact_skill_refix and impact_skill_refix.rate then
                base = math.ceil(base * (100 + impact_skill_refix.rate) / 100)
            end
            if impact_skill_refix and impact_skill_refix.point then
                impact_skill_refix.point = impact_skill_refix.point
                base = base + impact_skill_refix.point
            end
            if impact_skill_refix and impact_skill_refix.replace then
                base = impact_skill_refix.replace
            end
            value = base
            --print("monster_attrib:get_attrib(key)", key, " value =", value)
        end
        if must_be_positive[key] then
            value = value or 0
            if value < 0 then
                value = 0
            end
        end
        self:set_attrib({[key] = value})
        self:clear_dirty_flag(key)
    end
    return self:get_exist_attrib(key)
end

function monster_attrib:get_exist_attrib(key)
    local value = self.attribs[key] or self.db_attribs[key]
    return value
end

function monster_attrib:set_attrib(set_list)
    for key, value in pairs(set_list) do
        local old = self:get_exist_attrib(key)
        if old ~= value or self.attribs[key] == nil then
            self.dirty_datas[key] = true
        end
        self.attribs[key] = value
    end
end

function monster_attrib:get_base_attribs()
    local ret = {}
    for key in pairs(base_attribs) do
        ret[key] = self:get_attrib(key)
    end
    return ret
end

function monster_attrib:get_detail_attribs()
    local ret = {}
    for key in pairs(detail_attribs) do
        ret[key] = self:get_attrib(key)
    end
    return ret
end

function monster_attrib:get_db_attrib(key)
    return self.db_attribs[key]
end

function monster_attrib:get_monster()
    return self.monster
end

function monster_attrib:set_db_attrib(set_list)
    for key, value in pairs(set_list) do
        self:mark_attrib_dirty(key)
        local old = self:get_exist_attrib(key)
        if old ~= value then
            self.dirty_datas[key] = true
        end
        self.db_attribs[key] = value
    end
end

function monster_attrib:refresh_dirty_attribs()
    local dirty_flags = {}
    for key in pairs(self.dirty_flags) do
        dirty_flags[key] = true
    end
    for key in pairs(self.refix_dirty_flags) do
        dirty_flags[key] = true
    end
    for key in pairs(dirty_flags) do
        self:get_attrib(key)
    end
end

function monster_attrib:send_refresh_attrib()
    self:refresh_dirty_attribs()
    local send_refresh_base_attrib = false
    local refresh_base_attrib
    if next(self.dirty_datas) then
        refresh_base_attrib = packet_def.GCCharBaseAttrib.new()
        for key in pairs(self.dirty_datas) do
            local fn = string.format("set_%s", key)
            local f = refresh_base_attrib[fn]
            if f then
                local value = self:get_attrib(key)
                if key == "camp_id" and value <= 15 then
                    f(refresh_base_attrib, define.INVAILD_ID)
                else
                    f(refresh_base_attrib, value)
                end
                send_refresh_base_attrib = true
            end
            if self.dirty_datas.hp or self.dirty_datas.hp_max then
                local hp_percent = math.ceil(self:get_attrib("hp") / self:get_attrib("hp_max") * 100)
                refresh_base_attrib:set_hp_percent(hp_percent)
            end
            if self.dirty_datas.mp or self.dirty_datas.mp_max then
                refresh_base_attrib:set_mp_percent(0)
            end
        end
        if self.dirty_datas.stealth_level then
            self:get_monster():stealth_level_update()
        end
        self.dirty_datas = {}
    end
    local monster = self:get_monster()
    if send_refresh_base_attrib then
        local data_id = monster:inc_data_id()
        refresh_base_attrib:set_data_id(data_id)
        refresh_base_attrib.m_objID = monster:get_obj_id()
        monster:get_scene():broadcast(monster, refresh_base_attrib)
    end
end
function monster_attrib:get_chuanci()
	return 0
end

function monster_attrib:get_fangchuan()
	return 0
end

return monster_attrib
