local skynet = require "skynet"
local class = require "class"
local define = require "define"
local configenginer = require "configenginer":getinstance()
local skillenginer = require "skillenginer":getinstance()
local scriptenginer = require "scriptenginer":getinstance()
local GameTable = require "gametable":getinstance()
local ai_character = require "scene.ai.character"
local monster = class("monster", ai_character)
local BASE_HATE = 1
local HOSTILE_ACTION_HATE = 1

-- 怪物 AI：
-- 在通用角色 AI 之上增加巡逻、扫描仇恨、执行 AI 脚本与回出生点等怪物专属行为。

function monster:init(...)
    self.super.init(self, ...)
    local monster_ai_table = configenginer:get_config("monster_ai_table")
    local ai_type = self:get_character():get_ai_type()
    local ai_key = string.format("AI%d", ai_type)
    self.ai_table = monster_ai_table[ai_key]
    self.params = { bool = {}, int = {}, string = {}}
    self:reset()
    self:to_idle()
    self.patrol_endpoint_operators = {}
end

function monster:set_ai_type(ai_type)
    local monster_ai_table = configenginer:get_config("monster_ai_table")
    self.ai_table = monster_ai_table[string.format("AI%d", ai_type)]
end

function monster:on_init()
    local script_id = self:get_character():get_script_id()
    if script_id ~= define.INVAILD_ID and scriptenginer:have_function(script_id, "OnInit") then
        self:call_ai_script("OnInit", self:get_character():get_obj_id())
    end
end

function monster:reset()
    -- reset 用于出生、重置仇恨、回点等场景，确保怪物回到一套可重复利用的初始状态。
    self:set_cur_enemy_id(define.INVAILD_ID)
    self.enemys = {}
    self.enemy_hate = {}
    self.forced_enemy_id = define.INVAILD_ID
    self.skill_id = 0
    self.next_skill_id = define.INVAILD_ID
    self.next_scan_time = nil
    self.is_patrol_passtive_direct = true
    self.ai_command = { type = define.E_COMMAND_TYPE.E_COMMAND_TYPE_INVALID }
    self:change_state("idle")
end

function monster:set_next_skill_id(skill)
    self.next_skill_id = skill
end

function monster:get_int_param_by_index(i)
    return self.params.int[i] or 0
end

function monster:set_int_param_by_index(i, v)
    self.params.int[i] = v
end

function monster:get_string_param_by_index(i)
    return self.params.string[i] or ""
end

function monster:set_string_param_by_index(i, v)
    self.params.string[i] = v
end

function monster:get_bool_param_by_index(i)
    return self.params.bool[i] or 0
end

function monster:set_bool_param_by_index(i, v)
    self.params.bool[i] = v
end

function monster:start_rand_move()
    self.is_prepare_move = false
    local state_name = self.state:get_state_name()
    if state_name ~= "idle" then
        -- print("start_rand_move state obj_id =", self:get_character():get_obj_id(), ";state_name =", state_name)
        return
    end
	local character = self:get_character()
    local respwan_pos = character:get_respawn_pos() or character:get_world_pos()
    if not respwan_pos or respwan_pos.x == nil or respwan_pos.y == nil then
        return
    end
    local radious = character:get_pos_range() or 0
    radious = math.floor(radious)
    if radious <= 0 then
        return
    end
    local dist = { x = respwan_pos.x, y = respwan_pos.y }
    dist.x = dist.x + math.random(radious) - math.random(radious)
    dist.y = dist.y + math.random(radious) - math.random(radious)
    character:direct_move_to(dist)
end

function monster:execute_ai_script(state)
    local id = self:get_character():get_ai_script()
    if id ~= define.INVAILD_ID then
        -- AI 脚本走配置表解析后的 GameTable，便于策划按状态写流程脚本。
        local ai_script = GameTable:get_ai_script(id)
        if not ai_script then
            -- [audit 2026-09-11] ai_file khong ton tai (vd 97 o yerengou) -> dung AI co ban, khong assert moi tick
            return false
        end
        return ai_script:ProcessScript(state, self)
    end
    return false
end

function monster:ai_logic_idle(delta_time)
    -- 空闲态优先做扫描敌人；没有仇恨时再按配置决定是否随机游走。
    if self:scan_enemy(delta_time) then
        return true
    end
    if self:ai_param(define.MONSTER_AI_PRAM.AIPARAM_RANDMOVETIME) > 0 and not self:get_character():is_moving() and not self:has_enemy() then
        if self.rand_move_timer == nil then
            self.rand_move_timer = self:ai_param(define.MONSTER_AI_PRAM.AIPARAM_RANDMOVETIME) + math.random(self:ai_param(define.MONSTER_AI_PRAM.AIPARAM_RANDMOVETIME))
        end
        self.rand_move_timer = self.rand_move_timer - delta_time
        if self.rand_move_timer <= 0 then
            self.rand_move_timer = nil
            self:start_rand_move()
        end
    end
    self:execute_ai_script(define.ENUM_AISTATE.SIDLE)
end

function monster:start_patrol(convoy_npc)
    local character = self:get_character()
    self.convoy_npc = convoy_npc
    self.continue_patrol = true
    -- patrol_id 对应场景里预配置的巡逻路径点列。
    local patrol_path_index = character:get_patrol_id()
    local tar = self:get_patrols_point(patrol_path_index)
    if character:get_scene():is_can_go(character:get_world_pos(), tar) then
        self:monster_go(tar)
    end
    self:change_state("patrol")
end

function monster:ai_logic_patrol(delta_time)
    if self:scan_enemy(delta_time) then
        return true
    end
    if not self.convoy_npc and not self.continue_patrol then
        self:stop()
        return
    end
    local character = self:get_character()
    if not character:is_patrol_monster() then
        self:stop()
        return
    end
    if not character:is_moving() then
        self.settle_time = self.settle_time or 0
        if self.settle_time > 0 then
            self.settle_time = self.settle_time - delta_time
            return
        end
        self.index_of_passd = self.index_of_move_to
        local patrol_path_index = character:get_patrol_id()
        local tar = self:get_patrols_point(patrol_path_index)
        self:monster_go(tar)
    end
    self:execute_ai_script(define.ENUM_AISTATE.SPATROL)
end

function monster:get_patrols_point(patrol_path_index)
    self.index_of_move_to = self.index_of_move_to or 1
    local character = self:get_character()
    local patrol = character:get_scene():get_patrol_path_by_index(patrol_path_index)
    local path = patrol.path
    if self.is_patrol_passtive_direct then
        -- 正向巡逻走到末点后，可选择折返或结束整段巡逻。
        if self.index_of_move_to == #path then
            if patrol.is_turn_back then
                local curpos = path[self.index_of_move_to]
                local startpos = path[1]
                if curpos.x == startpos.x and curpos.y == startpos.y then
                    self.index_of_move_to = 1
                else
                    self.index_of_move_to = self.index_of_move_to - 1
                    self.is_patrol_passtive_direct = false
                end
            else
                self.continue_patrol = false
                self:on_patrol_endpoint()
            end
        else
            self.index_of_move_to = self.index_of_move_to + 1
        end
    else
        if self.index_of_move_to <= 1 then
            self.index_of_move_to = 1
            self.is_patrol_passtive_direct = true
        else
            self.index_of_move_to = self.index_of_move_to - 1
        end
    end
    self.index_of_move_to = self.index_of_move_to > #path and #path or self.index_of_move_to
    self.index_of_move_to = self.index_of_move_to < 1 and 1 or self.index_of_move_to
    return path[self.index_of_move_to]
end

function monster:on_patrol_endpoint()
    local character = self:get_character()
    local operators = self.patrol_endpoint_operators
    for _, operator in pairs(operators) do
        local op = operator.operator
        local f = character[op]
        assert(f, op)
        f(character, table.unpack(operator.args))
    end
end

function monster:monster_go(tar)
    local result = self:obj_move(tar)
    self:members_go(tar)
    if result ~= define.OPERATE_RESULT.OR_OK then
        self:get_character():direct_move_to(tar)
    end
    return define.OPERATE_RESULT.OR_OK
end

function monster:members_go(tar)

end

function monster:is_active_attack()
    return self:ai_param(define.MONSTER_AI_PRAM.AIPARAM_SCANTIME) > 0
end

function monster:is_can_not_be_attacked()
    return self:ai_param(define.MONSTER_AI_PRAM.AIPARAM_CANNOTATTACK) == 1
end

function monster:scan_enemy(delta_time)
    if self:ai_param(define.MONSTER_AI_PRAM.AIPARAM_SCANTIME) > 0  and not self:has_enemy() then
        if self.next_scan_time == nil then
            self.next_scan_time = self:ai_param(define.MONSTER_AI_PRAM.AIPARAM_SCANTIME)
            return false
        end
        self.next_scan_time = self.next_scan_time - delta_time
        if self.next_scan_time > 0 then
            return false
        end
		local character = self:get_character()
        local position = character:get_world_pos()
        local radious = self:ai_param(define.MONSTER_AI_PRAM.AIPARAM_SCANENEMYDIST) / 1000
        -- scan 先做 AOI/半径裁剪，再在这里补阵营与对象类型过滤。
        local operate = {obj = character, x = position.x, y = position.y, radious = radious, target_logic_by_stand = 1, check_can_view = true}
        local nearbys = character:get_scene():scan(operate)
        local nearest_id = define.INVAILD_ID
        local nearest_dist
        for _, nb in ipairs(nearbys) do
            if self:is_character_obj(nb) then
               if character:is_enemy(nb) and nb:is_alive() then
                    local dist = self:my_sqrt(position, nb:get_world_pos())
                    if nearest_dist == nil or dist < nearest_dist then
                        nearest_dist = dist
                        nearest_id = nb:get_obj_id()
                    end
               end
            end
        end
        if nearest_id ~= define.INVAILD_ID then
            self:add_enemy(nearest_id, BASE_HATE)
            self:set_cur_enemy_id(nearest_id)
        end
        self.next_scan_time = nil
        if self:has_enemy() then
            self:to_approach_tar()
            return true
        end
    end
    return false
end

function monster:has_enemy()
    local cur_enemy_id = self:get_cur_enemy_id()
    if cur_enemy_id == define.INVAILD_ID then
        cur_enemy_id = self:get_next_enemy()
        if cur_enemy_id == define.INVAILD_ID then
            return false
        end
        self:set_cur_enemy_id(cur_enemy_id)
    end
    return true
end

function monster:ai_param(param)
    if self.ai_table then
        return self.ai_table[param] or define.INVAILD_ID
    end
    return define.INVAILD_ID
end

function monster:event_on_be_skill(sender, skill_id, behaviortype)
    local param = self:ai_param(define.MONSTER_AI_PRAM.AIPARAM_STRIKEBACK)
    -- skynet.logi("monster:event_on_be_skill(sender, behaviortype)", sender:get_obj_id(), behaviortype, ";obj_id =", self:get_character():get_obj_id(),"param = ",param)
    if param < 0 then
        return
    end
    if self.state:get_state_name() == "go_home" then
        return
    end
	local character = self:get_character()
    if character == sender or not sender:is_alive() then
        return
    end
    if behaviortype ~= define.ENUM_BEHAVIOR_TYPE.BEHAVIOR_TYPE_HOSTILITY then
        return
    end
    local sender_id = sender:get_obj_id()
    local cur_enemy_id = self:get_cur_enemy_id()
    self:add_hate(sender_id, HOSTILE_ACTION_HATE)
    if cur_enemy_id == define.INVAILD_ID then
        self:set_cur_enemy_id(sender_id)
        self:to_approach_tar()
    elseif cur_enemy_id == sender_id then
        if character:is_character_logic_stopped() then
            self:execute_ai_script(define.ENUM_AISTATE.ONBESKILLSECTION)
        end
        return
    else
        self:change_primary_enemy()
    end
end

function monster:event_on_die()
    self:change_state("dead")
end

function monster:get_cur_enemy_id()
    return self.cur_enemy_id or define.INVAILD_ID
end

function monster:get_primary_enemy_id()
    return self:get_next_enemy()
end

function monster:is_already_exist(obj_id)
    for _, e in ipairs(self.enemys) do
        if e == obj_id then
            return true
        end
    end
    return false
end

function monster:is_need_change_enemy()
    return self:get_next_enemy() ~= self:get_cur_enemy_id()
end

function monster:set_cur_enemy_id(obj_id)
    self.cur_enemy_id = obj_id
end

function monster:add_enemy(obj_id, hate)
    if obj_id == nil or obj_id == define.INVAILD_ID then
        return false
    end
    if not self:is_already_exist(obj_id) then
        table.insert(self.enemys, obj_id)
    end
    self.enemy_hate[obj_id] = (self.enemy_hate[obj_id] or 0) + (hate or 0)
    return true
end

function monster:add_hate(obj_id, hate)
    if not self:add_enemy(obj_id, hate) then
        return false
    end
    if self.forced_enemy_id == define.INVAILD_ID then
        self:change_primary_enemy()
    end
    return true
end

function monster:del_enemy(obj_id)
    for i, e in ipairs(self.enemys) do
        if e == obj_id then
            table.remove(self.enemys, i)
            self.enemy_hate[obj_id] = nil
            if self.forced_enemy_id == obj_id then
                self.forced_enemy_id = define.INVAILD_ID
            end
            break
        end
    end
end

function monster:del_all_enemy()
    self.enemys = {}
    self.enemy_hate = {}
    self.forced_enemy_id = define.INVAILD_ID
end
function monster:add_primary_enemy(obj_id)
    self:get_next_enemy()
    local highest_hate = 0
    for _, hate in pairs(self.enemy_hate) do
        if hate > highest_hate then
            highest_hate = hate
        end
    end
    if not self:add_enemy(obj_id, 0) then
        return
    end
    self.enemy_hate[obj_id] = highest_hate + BASE_HATE
    self:set_cur_enemy_id(obj_id)
    self.to_attack_world_pos = self:get_character():get_world_pos()
    self:to_approach_tar()
end

function monster:change_primary_enemy(excluded_id)
    local enemy_id = self:get_next_enemy(excluded_id)
    if enemy_id == define.INVAILD_ID or enemy_id == self:get_cur_enemy_id() then
        return
    end
    self:set_cur_enemy_id(enemy_id)
    self:to_approach_tar()
end

function monster:force_primary_enemy(obj_id)
    if not self:add_enemy(obj_id, BASE_HATE) then
        return
    end
    self.forced_enemy_id = obj_id
    self:set_cur_enemy_id(obj_id)
    self:to_approach_tar()
end

function monster:release_forced_enemy(obj_id)
    if self.forced_enemy_id ~= obj_id then
        return
    end
    self.forced_enemy_id = define.INVAILD_ID
    local enemy_id = self:get_next_enemy()
    self:set_cur_enemy_id(enemy_id)
    if enemy_id ~= define.INVAILD_ID then
        self:to_approach_tar()
    end
end

function monster:is_valid_enemy(obj_id)
    if obj_id == nil or obj_id == define.INVAILD_ID then
        return false
    end
    local character = self:get_character()
    local obj = character:get_scene():get_obj_by_id(obj_id)
    return obj ~= nil
        and self:is_character_obj(obj)
        and obj:is_alive()
        and character:is_can_view(obj)
end

function monster:get_next_enemy(excluded_id)
    for i = #self.enemys, 1, -1 do
        local obj_id = self.enemys[i]
        if not self:is_valid_enemy(obj_id) then
            table.remove(self.enemys, i)
            self.enemy_hate[obj_id] = nil
            if self.forced_enemy_id == obj_id then
                self.forced_enemy_id = define.INVAILD_ID
            end
        end
    end
    if self.forced_enemy_id ~= define.INVAILD_ID
        and self.forced_enemy_id ~= excluded_id
        and self:is_already_exist(self.forced_enemy_id) then
        return self.forced_enemy_id
    end
    local selected = define.INVAILD_ID
    local selected_hate = -1
    for _, obj_id in ipairs(self.enemys) do
        if obj_id ~= excluded_id then
            local hate = self.enemy_hate[obj_id] or 0
            if hate > selected_hate then
                selected = obj_id
                selected_hate = hate
            end
        end
    end
    return selected
end

function monster:to_idle()
    --self:get_character():clear_unbreakable_flag()
    local character = self:get_character()
    character:clear_unbreakable_flag()
    self:reset()
    if character:is_patrol_monster() then
        self:start_patrol()
    else
        self:change_state("idle")
    end
    return true
end

function monster:to_go_home()
	-- skynet.logi("monster:to_go_home()")
	local character = self:get_character()
    local tar = character:get_respawn_pos()
    self:del_all_enemy()
    --self:get_character():mark_unbreakable_flag()
    local result = self:obj_move(tar)
    if result ~= define.OPERATE_RESULT.OR_OK then
        character:direct_move_to(tar)
    end
    self:change_state("go_home")
end

function monster:is_to_go_home()
	-- skynet.logi("monster:is_to_go_home()")
	local character = self:get_character()
    local obj = character:get_scene():get_obj_by_id(self:get_cur_enemy_id())
    local cur_enemy_id = self:get_cur_enemy_id()
    if obj == nil or not self:is_character_obj(obj) then
        self:del_enemy(cur_enemy_id)
        cur_enemy_id = self:get_next_enemy()
        if cur_enemy_id == define.INVAILD_ID then
            self:to_go_home()
            return true
        end
        self:set_cur_enemy_id(cur_enemy_id)
        obj = character:get_scene():get_obj_by_id(cur_enemy_id)
        if obj == nil or not self:is_character_obj(obj) then
            self:to_go_home()
            return true
        end
    end
    if not character:is_patrol_monster() then
        local dist = self:my_sqrt(character:get_respawn_pos(), obj:get_world_pos())
        if (not obj:is_alive()) or dist > (self:ai_param(define.MONSTER_AI_PRAM.AIPARAM_RETURN) / 1000) then
            self:del_enemy(cur_enemy_id)
            cur_enemy_id = self:get_next_enemy()
            if cur_enemy_id == define.INVAILD_ID then
                self:to_go_home()
                return true
            end
            self:set_cur_enemy_id(cur_enemy_id)
        end
    end
    return false
end

function monster:to_approach_tar()
	-- skynet.logi("monster:to_approach_tar()")
    -- print("monster to_approach_tar")
	local character = self:get_character()
    if character:get_speed() == 0 then
        return
    end
    if character:get_character_logic() == define.ENUM_CHARACTER_LOGIC.CHARACTER_LOGIC_USE_SKILL then
        return
    end
    local enemy = self:get_cur_enemy_id()
    local enemy_obj = character:get_scene():get_obj_by_id(enemy)
    if not enemy_obj or
     not self:is_character_obj(enemy_obj)
     or not enemy_obj:is_alive()
     or not character:is_can_view(enemy_obj) then
        self:del_enemy(enemy)
        enemy = self:get_next_enemy()
        self:set_cur_enemy_id(enemy)
        if enemy == define.INVAILD_ID then
            self:to_go_home()
        end
        return
    end
    if self:ai_param(define.MONSTER_AI_PRAM.AIPARAM_STRIKEBACK) == 1 then
		local max_range
		if self:execute_ai_script(define.ENUM_AISTATE.SKILLSECTION) then
			self:to_attack()
			return
		else
			local template = skillenginer:get_skill_template(self.skill_id)
			if not template then
				return
			end
			max_range = template.optimal_range_max
		end
		if max_range == define.INVAILD_ID then
			return
		end
		local tar = table.clone(character:get_world_pos())
		local enemy_obj_pos = enemy_obj:get_world_pos()
		local vx = tar.x - enemy_obj_pos.x
		local vy = tar.y - enemy_obj_pos.y
		local dist = math.sqrt(vx * vx + vy * vy)
		dist = math.floor(dist)
		if dist < define.ZERO_VALUE then
			return
		end
		local cos = vx / dist
		local sin = vy / dist
		-- print("to_approach_tar dist =", dist, ";max_range =", max_range)
		if dist < max_range then
			tar.x = enemy_obj_pos.x + cos * dist
			tar.y = enemy_obj_pos.y + sin * dist
		else
			tar.x = enemy_obj_pos.x + cos * max_range
			tar.y = enemy_obj_pos.y + sin * max_range
		end
		local result = self:obj_move(tar)
		if result ~= define.OPERATE_RESULT.OR_OK then
			character:direct_move_to(tar)
		end
	end
    self:change_state("approach")
end

function monster:to_attack()
    self:change_state("combat")
end

function monster:ai_logic_go_home()
	local character = self:get_character()
    local dist = self:my_sqrt(character:get_world_pos(), character:get_respawn_pos())
    if dist < define.ZERO_VALUE then
        self:to_idle()
        character:reset()
    end
    self:execute_ai_script(define.ENUM_AISTATE.SRETURN)
end

function monster:ai_logic_approach()
	-- skynet.logi("monster:ai_logic_approach()")
    local cur_enemy_id = self:get_cur_enemy_id()
	local character = self:get_character()
    local enemy_obj = character:get_scene():get_obj_by_id(cur_enemy_id)
    if not enemy_obj 
	or not self:is_character_obj(enemy_obj) 
	or not enemy_obj:is_alive()
	or not character:is_can_view(enemy_obj) then
        self:del_enemy(cur_enemy_id)
        self:set_cur_enemy_id(self:get_next_enemy())
        cur_enemy_id = self:get_cur_enemy_id() or define.INVAILD_ID
        if cur_enemy_id == define.INVAILD_ID then
            self:to_go_home()
        end
        return
    end
    if self:ai_param(define.MONSTER_AI_PRAM.AIPARAM_STRIKEBACK) ~= 1 then
        return
    end
    if self:is_to_go_home() then
        return
    end
    local pos_my = character:get_world_pos()
    local pos_tar = enemy_obj:get_world_pos()
    local vx = pos_my.x - pos_tar.x
    local vy = pos_my.y - pos_tar.y
    local dist = math.sqrt(vx * vx + vy * vy)
    local template = skillenginer:get_skill_template(self.skill_id)
    if not template then
        return
    end
    local max_range = template.optimal_range_max
    dist = math.floor(dist)
    -- print("ai_logic_approach dist =", dist, ";max_range =", max_range)
    if dist <= max_range then
        self:to_attack()
    elseif not character:is_moving() then
        self:to_approach_tar()
    end
    self:execute_ai_script(define.ENUM_AISTATE.SAPPROACH)
end

function monster:ai_logic_combat()
	-- skynet.logi("monster:ai_logic_combat()")
	local character = self:get_character()
    local cur_enemy_id = self:get_cur_enemy_id()
    local enemy_obj = character:get_scene():get_obj_by_id(cur_enemy_id)
    if not enemy_obj
        or not self:is_character_obj(enemy_obj)
        or not enemy_obj:is_alive()
        or not character:is_can_view(enemy_obj) then
        self:del_enemy(cur_enemy_id)
        self:set_cur_enemy_id(self:get_next_enemy())
        cur_enemy_id = self:get_cur_enemy_id() or define.INVAILD_ID
        if cur_enemy_id == define.INVAILD_ID then
            self:to_go_home()
        end
        return
    end
    if character:is_moving() or not character:can_use_skill_now() then
        return
    end
    if enemy_obj:is_unbreakable() then
        local next_enemy = self:get_next_enemy(cur_enemy_id) or define.INVAILD_ID
        if next_enemy ~= define.INVAILD_ID then
            local next_obj = character:get_scene():get_obj_by_id(next_enemy)
            if next_obj and self:is_character_obj(next_obj) and not next_obj:is_unbreakable() then
                self:set_cur_enemy_id(next_enemy)
                self:to_approach_tar()
                return
            end
        end
    end
    if enemy_obj:get_obj_type() == "human" and enemy_obj:get_assistant_id() then
        self:add_enemy(enemy_obj:get_assistant_id())
        if self:is_need_change_enemy() then
            self:set_cur_enemy_id(enemy_obj:get_assistant_id())
            self:to_approach_tar()
            return
        end
    end
    if self.ai_command.type ~= define.E_COMMAND_TYPE.E_COMMAND_TYPE_INVALID then
        self:execute_command()
        return
    end
    local pos_tar = enemy_obj:get_world_pos()
    if self.next_skill_id ~= define.INVAILD_ID then
        self:use_skill(self.next_skill_id, cur_enemy_id, pos_tar.x, pos_tar.y)
        self.next_skill_id = define.INVAILD_ID
    end
    if self:execute_ai_script(define.ENUM_AISTATE.SATTACK) then
        return
    end
    if self:execute_ai_script(define.ENUM_AISTATE.SKILLSECTION) then
        return
    end
    -- print("monster use skill")
    local result = self:use_skill(0, cur_enemy_id, pos_tar.x, pos_tar.y)
    if result == define.OPERATE_RESULT.OR_OUT_RANGE then
		-- skynet.logi("ai_logic_combat")
        self.skill_id = 0
        self:to_approach_tar()
    end
end

function monster:respawn()
    self:reset()
end

function monster:add_patrol_endpoint_operator(operator, ...)
    table.insert(self.patrol_endpoint_operators, { operator = operator, args = { ... }})
end

return monster
