local class = require "class"
local define = require "define"
local scriptenginer = require "scriptenginer":getinstance()
local skillenginer = require "skillenginer":getinstance()
local state_list =require "scene.ai.states.state_list":getinstance()
local character = class("character")
local RANDOM_TIME = 2000
local RANDOM_DIST = 6

function character:ctor()
    self.state = nil
    self.obj_character = nil
    self.interval_time = RANDOM_TIME
    self.ai_script_times = {}
end

function character:init(obj_character)
    self.obj_character = obj_character
    self.state = state_list:get_state("idle")
end

function character:get_state()
    return self.state
end

function character:obj_move(target)
    local obj_character = self:get_character()
    if obj_character:is_limit_move() then
        return define.OPERATE_RESULT.OR_LIMIT_MOVE
    end
    if obj_character:is_die() then
        return define.OPERATE_RESULT.OR_DIE
    end
    local start = obj_character:get_world_pos()
    local path = obj_character:get_scene():get_map():findpath(start, target)
    if #path == 0 then
        return
    end
    return self.state:move(self, define.INVAILD_ID, path)
end

function character:obj_use_item(...)
    return self.state:obj_use_item(self, ...)
end

function character:obj_active_monster(...)
    return self.state:obj_active_monster(self, ...)
end

function character:obj_use_skill(...)
    return self.state:obj_use_skill(self, ...)
end

function character:jump()
    return self.state:jump(self)
end

function character:stop()
    return self.state:stop(self)
end

function character:stall()
    return self.state:stall(self)
end

function character:use_ability()
    return self.state:use_ability(self)
end

function character:move_to_pos(target)
    local obj_character = self:get_character()
    if obj_character:is_limit_move() then
        return
    end
    if obj_character:is_die() then
        return
    end
    local start = obj_character:get_world_pos()
    local path = obj_character:get_scene():get_map():findpath(start, target)
    if path == nil then
        return
    end
    -- findpath 在起点和终点位于同一导航多边形时可能返回空表
    -- 此时直接构造一条到目标点的直线路径，避免 do_move 收到空 path 导致 size=0
    if #path == 0 then
        path = { {x = target.x, y = target.y} }
    end
	return self:move(-1, path);
end

function character:move(handle, pos_tar, line)
    local obj_character = self:get_character()
    if obj_character:is_limit_move() then
        return define.OPERATE_RESULT.OR_LIMIT_MOVE
    end
    return self.state:move(self, handle, pos_tar)
end

function character:use_skill(...)
    -- print("ai.character:use_skill =", ...)
    return self.state:use_skill(self, ...)
end

function character:use_item(...)
    return self.state:use_item(self, ...)
end

function character:can_use_skill()
    return self.state:can_use_skill(self)
end

function character:can_use_item()
    return self.state:can_use_item(self)
end

function character:logic(delta_time)
    return self.state:logic(self, delta_time)
end

function character:call_ai_script(...)
    if self:get_character():get_obj_type() == "monster" then
        local script_id = self:get_character():get_script_id()
        if script_id and script_id ~= define.INVAILD_ID then
            scriptenginer:call(script_id, ...)
        end
    end
end

function character:trigger_script_f(from, to)
    if to == "go_home" then
        self:call_ai_script("OnLeaveCombat", self:get_character():get_obj_id())
    else
        if from == "idle" then
            if to == "combat" or to == "approach" then
                self:call_ai_script("OnEnterCombat", self:get_character():get_obj_id())
            end
        end
    end
end

function character:change_state(to)
    local now = self.state:get_state_name()
    if now == to then
        return
    end
    -- print("change_state name =", self:get_character():get_name(), ";state =", to)
    self.state = state_list:get_state(to)
    self:trigger_script_f(now, to)
    assert(self.state, to)
end

function character:ai_logic_terror(delta_time)
    local obj_character = self:get_character()
    if RANDOM_TIME == self.interval_time or self.interval_time <= 0 then
        -- print("character:ai_logic_terror move self.interval_time =", self.interval_time)
        local len = math.random(RANDOM_DIST)
        local pos = self:get_rand_pos_of_circle(obj_character:get_world_pos(), len)
        self:obj_move(pos)
        self.interval_time = math.random(RANDOM_TIME)
    else
        -- print("character:ai_logic_terror not self.interval_time =", self.interval_time, ";delta_time =", delta_time)
        self.interval_time = self.interval_time - delta_time
    end
end

function character:ai_logic_idle()
end

function character:ai_logic_dead()
end

function character:ai_logic_combat()
end

function character:ai_logic_flee()
end

function character:ai_logic_patrol()
end

function character:ai_logic_go_home()
end

function character:ai_logic_service()
end

function character:ai_logic_approach()
end

function character:ai_logic_sit()
end

function character:ai_logic_team_follow()

end

function character:on_die(...)
    self:call_ai_script("OnDie", self:get_character():get_obj_id(), ...)
    return self.state:on_die(self, ...)
end

function character:on_relive(...)
    return self.on_relive(self, ...)
end

function character:on_damage(...)
    return self.state:on_damage(self, ...)
end

function character:on_be_skill(...)
    return self.state:on_be_skill(self, ...)
end

function character:event_on_be_skill(...)

end

function character:set_ai_state(state)
    self.state = state
end

function character:get_ai_state()
    return self.state
end

function character:get_character()
    return self.obj_character
end

function character:get_rand_pos_of_circle(pos, radio)
    local vx = math.random(10)
    local dir = math.random(2)
    if dir == 1 then
        vx = -1 * vx
    end
    local vy = math.sqrt(100 - vx * vx)
    dir = math.random(2)
    if dir == 1 then
        vy = -1 * vy
    end
    -- print("get_rand_pos_of_circle vx =", vx, ";vy =", vy)
    return { x = (vx / 10) * radio + pos.x, y = (vy / 10) * radio + pos.y}
end

function character:is_character_obj(tar)
	local obj_type = tar:get_obj_type()
    return obj_type == "human" or obj_type == "monster" or obj_type == "pet"
end

function character:my_sqrt(cur, tar)
    return math.sqrt((tar.x - cur.x) * (tar.x - cur.x) + (tar.y - cur.y) * (tar.y - cur.y) )
end

function character:ReSetNeedGoDist()

end

function character:GetAIScriptTimes(id)
    return self.ai_script_times[id] or define.INVAILD_ID
end

function character:SetAIScriptTimes(id, time)
    self.ai_script_times[id] = time
end

function character:GetSkillID()
    return self:get_skill_id()
end

function character:set_skill_id(id)
    self.skill_id = id
end

function character:GetNeedGoDist(skill)
    local cur_enemy_id = self:get_cur_enemy_id()
    local cur_enemy = self:get_character():get_scene():get_obj_by_id(cur_enemy_id)
    local template = skillenginer:get_skill_template(skill)
    if template then
        local pos_tar = cur_enemy:get_world_pos()
        local pos_me = self:get_character():get_world_pos()
        local dist = math.sqrt((pos_tar.x - pos_me.x) * (pos_tar.x - pos_me.x) + (pos_tar.y - pos_me.y) * (pos_tar.y - pos_me.y))
        if dist > template.optimal_range_max then
            return dist - template.optimal_range_max
        end
        if dist < template.optimal_range_min then
            return dist - template.optimal_range_min
        end
    end
    return -1.0
end

function character:get_skill_id()
    return self.skill_id or 0
end


function character:aiscript_call(fn, ...)
    local f = self[fn]
    assert(f, fn)
    local r, err = pcall(f, self, ...)
    if not r then
        print("aiscript_call r =", r, ";error =", err)
    end
    --print("aiscript_call func =", fn, ";args =", ...,  ";result =", err)
    return err
end

return character