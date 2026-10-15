local gbk = require "wire_charset"
local skynet = require "skynet"
local define = require "define"

-- [DBG_ZDZD] 日志限频：同一 obj_id+reason 每30秒最多输出一次
local _zdzd_log_last = {}
local function zdzd_log(reason, obj_id, ...)
    local key = tostring(obj_id) .. ":" .. reason
    local now = os.time()
    if _zdzd_log_last[key] and now - _zdzd_log_last[key] < 30 then
        return
    end
    _zdzd_log_last[key] = now
end
local packet_def = require "game.packet"
local class = require "class"
local skillenginer = require "skillenginer":getinstance()
local actionenginer = require "actionenginer":getinstance()
local configenginer = require "configenginer":getinstance()
local scriptenginer = require "scriptenginer":getinstance()
local base = require "scene.ai.character"
local human_item_logic = require "human_item_logic"
local equip_dress_bonus = require "equip_dress_bonus"
local human = class("human", base)

-- CYS-ASSIST executor
function human:logic(delta_time)
    require("cys_battle_assist").tick(self:get_character(),delta_time)
    return self.super.logic(self,delta_time)
end

function human:ctor()
    self.param_ai_use_skill = {
	auto_use_skill = define.INVAILD_ID,
	queued_skill = define.INVAILD_ID,
	auto_shoot_target_obj_id = define.INVAILD_ID
	}
    self.param_use_item = { bagindex = define.INVAILD_ID}
    self.team_follow_speed_tick = 0
    self.team_follow_base_speed = nil
end

function human:init(...)
    self.super.init(self, ...)
    self:init_auot_shot_skill()
end

function human:init_auot_shot_skill()
	local character = self:get_character()
	local skill_enginer = character:get_scene():get_skill_enginer()
    local skills = character:get_skill_list()
    table.sort(skills, function(a, b)
        return a < b
    end)
    for _, skill in ipairs(skills) do
        if skill ~= 0 then
            local template = skill_enginer:get_skill_template(skill)
            if template then
                if template.auto_shot_skill_flag then
                    self.auot_shot_skill_id = skill
                    break
                end
            end
        end
    end
    if not self.auot_shot_skill_id then
        self.auot_shot_skill_id = 0
    end
end

function human:relive(is_skill_relive)
    -- print("human:relive is_skill_relive =", is_skill_relive)
    local character = self:get_character()
    local msg = packet_def.GCPlayerRelive.new()
    character:get_scene():send2client(character, msg)
	if not character:is_die() then
		return
	end
	local cur_scene_id = character:get_scene():get_id()
    local relive_info = character:get_relive_info(is_skill_relive)
    if relive_info then
        if relive_info.hp_recover_rate then
            local hp = math.floor(character:get_max_hp() * relive_info.hp_recover_rate)
			hp = hp <= 0 and 1 or hp
            character:set_hp(hp)
		else
			character:set_hp(1)
        end
        if relive_info.mp_recover_rate then
            local mp = math.floor(character:get_max_mp() * relive_info.mp_recover_rate)
            character:set_mp(mp)
        end
        if relive_info.rage_recover_rate then
            local rage = math.floor(character:get_max_rage() * relive_info.rage_recover_rate)
            character:set_rage(rage)
        end
        -- local cur_scene_id = character:get_scene():get_id()
        if relive_info.sceneid and relive_info.sceneid ~= cur_scene_id then
            character:change_scene(relive_info.sceneid, relive_info.world_pos)
        else
            character:on_teleport(relive_info.world_pos)
        end
	else
		character:set_hp(1)
		-- CYS-RELIVEPT 20/09/2026: luoi an toan cuoi cung dung CHUNG mot noi an toan voi
		-- scene.lua va msgagent.lua (define.DEFAULT_SCENEID_AND_WORLD_POS = canh 2 Dai Ly 160,150).
		-- 085 goc KHONG co nhanh nay: AI_Human.cpp:452-457 het relive_info thi hoi sinh TAI CHO.
		-- Ta khong hoi sinh tai cho (1 mau giua bay quai = vong lap chet), nhung cung khong nem
		-- nguoi choi xuong Dia Phu - noi impact 59901 khoa ca di lan danh, thoi han -1, khong mat
		-- khi dang xuat. HOAN TAC: doi lai thanh math.random(1,#define.SIWANG) va toa do 20,38.
		local d = define.DEFAULT_SCENEID_AND_WORLD_POS
		if cur_scene_id ~= d.sceneid then
            character:change_scene(d.sceneid,{x = d.world_pos.x,y = d.world_pos.y})
        else
            character:on_teleport({x = d.world_pos.x,y = d.world_pos.y})
        end
    end
    character:clear_skill_relive_info()
    self:change_state("idle")
	return true
end

function human:ai_logic_dead(delta_time)
    if self.dead_timer then
        self.dead_timer = self.dead_timer - delta_time
        if self.dead_timer < 0 then
            self.dead_timer = nil
            self:relive(false)
        end
    end
    if not self:get_character():is_die() then
        self:change_state("idle")
    end
end

function human:calc_horizontal_offset(member_index)
    if member_index == 1 then
        return 0
    end
    local side = 1
    if member_index % 2 == 1 then
        side = -1
    end
    return side * math.floor(member_index / 2) * 2.0
end

function human:find_scene_leader(character, leader_guid)
    local scene = character:get_scene()
    local leader_obj = scene:get_obj_by_guid(leader_guid)
    if leader_obj then
        return leader_obj, leader_obj:get_world_pos(), leader_obj:get_dir()
    end
    return nil
end

function human:calc_formation_pos(leader_pos, leader_dir, member_index)
    local offset = self:calc_horizontal_offset(member_index)
    local perp_x = math.cos(leader_dir)
    local perp_y = -math.sin(leader_dir)
    local pos = {}
    pos.x = leader_pos.x - math.sin(leader_dir) * 2.0 + perp_x * offset
    pos.y = leader_pos.y - math.cos(leader_dir) * 2.0 + perp_y * offset
    return pos
end

function human:calc_follow_speed(dist, base_speed)
    -- 单一连续指数曲线，无分区、无跳变
    -- dist≤2.2时停止，超过后平滑加速
    -- 2.2m:   0%  (静止)
    -- 2.5m:  13%  (起步)
    -- 3m:    33%
    -- 5m:    91%  (基本匹配)
    -- 10m:  154%  (加速追赶)
    -- 20m:  178%  (最大)
    if dist <= 2.2 then
        return 0, false
    end
    local d = dist - 2.2
    local factor = 1.8 * (1 - math.exp(-d * 0.25))
    local speed = base_speed * math.min(factor, 1.8)
    local boosted = speed > base_speed * 1.05
    return speed, boosted
end

function human:ai_logic_team_follow(delta_time)
    self.team_follow_cross_scene_tick = self.team_follow_cross_scene_tick or 0
    self.team_follow_check_tick = self.team_follow_check_tick or 0
    self.team_follow_speed_tick = self.team_follow_speed_tick or 0
    self.team_follow_position_sync_tick = self.team_follow_position_sync_tick or 0

    local character = self:get_character()
    local stopd = character:is_character_logic_stopped()
    local team_info = character:get_team_info()
    local guide = team_info:get_my_guide()
    
    if not guide then
        self.team_follow_position_sync_tick = 0
        local leader_guid = team_info:get_team_leader()
        if not leader_guid or leader_guid == define.INVAILD_ID then
            if character:get_team_follow_flag() then
                character:stop_team_follow()
            else
                self:stop()
                self:change_state("idle")
            end
            return
        end
        
        if self.team_follow_cross_scene_tick < 3000 then
            self.team_follow_cross_scene_tick = self.team_follow_cross_scene_tick + delta_time
            return
        end
        self.team_follow_cross_scene_tick = 0
        
        local character_self = character
        local leader_guid_val = leader_guid
        skynet.fork(function()
            local ok, leader_info = pcall(skynet.call, ".world", "lua", "get_member_scene_info", leader_guid_val)
            if ok and leader_info and leader_info.sceneid and leader_info.sceneid ~= define.INVAILD_ID then
                local my_scene_id = character_self:get_scene():get_id()
                if leader_info.sceneid ~= my_scene_id then
                    local target_pos = leader_info.world_pos or {x = 0, y = 0}
                    character_self:change_scene(leader_info.sceneid, target_pos)
                end
            end
        end)
        return
    end

    -- guide 存在，重置跨场景等待计时器，避免引导目标闪烁时累积导致过早传送
    self.team_follow_cross_scene_tick = 0
    self.team_follow_position_sync_tick = self.team_follow_position_sync_tick + delta_time

    -- 位置按前一名队员链式跟随，基础速度统一取队长，避免追赶加速沿队列放大。
    self.team_follow_speed_tick = self.team_follow_speed_tick + delta_time
    if self.team_follow_speed_tick > 500 then
        self.team_follow_speed_tick = 0
        local speed_source = self:find_scene_leader(character, team_info:get_team_leader()) or guide
        local leader_speed = speed_source:get_speed()
        if leader_speed and leader_speed > 0 then
            self.team_follow_base_speed = leader_speed
        end
    end

    -- 计算队员编号：followed_members[1]=队长，队员从2开始
    local member_index = 1
    local count = team_info:get_followed_members_count()
    
    for i = 1, count do
        local mb = team_info:get_followed_member(i)
        if mb and mb.guid == character:get_guid() then
            member_index = i - 1
            break
        end
    end
    
    if member_index < 1 then member_index = 1 end

    -- 统一停止距离0.8米，避免队长微小移动导致队员频繁启停抽搐
    local stop_dist = 0.8

    if stopd or character:get_character_logic() == define.ENUM_CHARACTER_LOGIC.CHARACTER_LOGIC_IDLE then
        -- 队长静止或自己已停止：检查是否需要开始移动
        self.team_follow_check_tick = 0
        self.team_follow_position_sync_tick = 0
        local guide_world_pos = guide:get_world_pos()
        local my_world_pos = character:get_world_pos()
        local my_target_pos = self:get_guide_to_pos(guide_world_pos, guide:get_dir(), member_index)
        local dist = self:my_sqrt(my_world_pos, my_target_pos)

        if dist > stop_dist then
            self:follow_move(character, my_target_pos, dist, member_index)
        elseif character:get_character_logic() ~= define.ENUM_CHARACTER_LOGIC.CHARACTER_LOGIC_IDLE then
            self:stop()
        end
    else
        -- 自己正在移动中：每300ms检查一次是否需要调整路径
        self.team_follow_check_tick = self.team_follow_check_tick + delta_time
        if self.team_follow_check_tick > 300 then
            self.team_follow_check_tick = 0
            local guide_world_pos = guide:get_world_pos()
            local my_world_pos = character:get_world_pos()
            local my_target_pos = self:get_guide_to_pos(guide_world_pos, guide:get_dir(), member_index)
            local dist = self:my_sqrt(my_world_pos, my_target_pos)

            if dist > stop_dist then
                local cur_move = character.move
                local cur_dest = cur_move and cur_move.targetPos and cur_move.targetPos[#cur_move.targetPos]
                local dest_dist = cur_dest and self:my_sqrt(cur_dest, my_target_pos) or 999
                local position_sync_due = self.team_follow_position_sync_tick >= 1000

                -- 只有目标偏移超过2米才重新寻路，否则保持当前移动避免抽搐
                if dest_dist > 2 or position_sync_due then
                    self.team_follow_position_sync_tick = 0
                    self:follow_move(character, my_target_pos, dist, member_index)
                end
            else
                self.team_follow_position_sync_tick = 0
            end
        end
    end
end

function human:get_guide_to_pos(guide_pos, guide_dir, member_index)
    local character = self:get_character()
    local team_info = character:get_team_info()

    if member_index == 1 then
        -- M1跟在队长身后1.5米
        local to_pos = {}
        to_pos.x = guide_pos.x - math.sin(guide_dir) * 1.5
        to_pos.y = guide_pos.y - math.cos(guide_dir) * 1.5
        return to_pos
    end

    -- M2+跟在前一个队员身后1.0米
    local prev_member = team_info:get_followed_member(member_index)
    if prev_member then
        local scene = character:get_scene()
        if scene then
            local prev_obj = scene:get_obj_by_guid(prev_member.guid)
            if prev_obj then
                local prev_pos = prev_obj:get_world_pos()
                local prev_dir = prev_obj:get_dir()
                local to_pos = {}
                to_pos.x = prev_pos.x - math.sin(prev_dir) * 1.0
                to_pos.y = prev_pos.y - math.cos(prev_dir) * 1.0
                return to_pos
            end
        end
    end

    -- 兜底：跟队长
    local to_pos = {}
    to_pos.x = guide_pos.x - math.sin(guide_dir) * 1.5
    to_pos.y = guide_pos.y - math.cos(guide_dir) * 1.5
    return to_pos
end


function human:get_param_ai_use_skill()
    return self.param_ai_use_skill
end

function human:update_auto_use_skill(fwq_passive_skill)
	local auto_active_skill = self.param_ai_use_skill.auto_use_skill or define.INVAILD_ID
	if auto_active_skill ~= define.INVAILD_ID then
		local character = self:get_character()
		if fwq_passive_skill then
			self.param_ai_use_skill.auto_use_skill = fwq_passive_skill
		else
			local have_weapon = character:get_equip(define.HUMAN_EQUIP.HEQUIP_WEAPON)
			if have_weapon then
				self.param_ai_use_skill.auto_use_skill = self.auot_shot_skill_id
			else
				self.param_ai_use_skill.auto_use_skill = 0
			end
		end
		auto_active_skill = self.param_ai_use_skill.auto_use_skill
		-- if not character:is_skill_cool_down(auto_active_skill) then
			-- return
		-- end
		-- if not character:can_use_this_skill_in_this_status(auto_active_skill) then
			-- local msg = packet_def.GCCharStopAction.new()
			-- msg.m_objID = character:get_obj_id()
			-- msg.logic_count = character:get_logic_count()
			-- local params = character:get_action_params()
			-- msg.stop_time = params:get_continuance()
			-- scene:broadcast(character, msg, true)
			-- self.param_ai_use_skill = { auto_use_skill = define.INVAILD_ID, queued_skill = define.INVAILD_ID, auto_shoot_target_obj_id = define.INVAILD_ID }
			-- self:change_state("idle")
			-- return
		-- end
		local ret = self:obj_use_skill(auto_active_skill, self.param_ai_use_skill.auto_shoot_target_obj_id
		, {x = 0,y = 0}, 0, define.INVAILD_ID)
			
		
		-- local obj_tar = scene:get_obj_by_id(self.param_ai_use_skill.auto_shoot_target_obj_id)
		-- if obj_tar and not character:is_can_view(obj_tar) then
			-- local msg = packet_def.GCCharStopAction.new()
			-- msg.m_objID = character:get_obj_id()
			-- msg.logic_count = character:get_logic_count()
			-- local params = character:get_action_params()
			-- msg.stop_time = params:get_continuance()
			-- scene:broadcast(character, msg, true)
			-- self.param_ai_use_skill = { auto_use_skill = define.INVAILD_ID, queued_skill = define.INVAILD_ID, auto_shoot_target_obj_id = define.INVAILD_ID }
			-- self:change_state("idle")
			-- return
		-- end
		-- if obj_tar and ret == define.OPERATE_RESULT.OR_OK and character:is_enemy(obj_tar) then

		-- else
			-- self.param_ai_use_skill.auto_use_skill = define.INVAILD_ID
			-- self.param_ai_use_skill.auto_shoot_target_obj_id = define.INVAILD_ID
		-- end
	
		
		
		
		
	end
end

function human:resume_zdzd_auto_combat(character, scene)
    if not character or not scene or not character.zdzd_enabled then
        return false
    end

    local target_id = self:find_nearest_enemy(character, scene)
    if not target_id or target_id == define.INVAILD_ID then
        self.param_ai_use_skill.auto_shoot_target_obj_id = define.INVAILD_ID
        character:set_locked_target(define.INVAILD_ID)
        return false
    end

    local auto_active_skill = self.param_ai_use_skill.auto_use_skill or define.INVAILD_ID
    if auto_active_skill == define.INVAILD_ID then
        local have_weapon = character:get_equip(define.HUMAN_EQUIP.HEQUIP_WEAPON)
        if have_weapon then
            self.param_ai_use_skill.auto_use_skill = self.auot_shot_skill_id
        else
            self.param_ai_use_skill.auto_use_skill = 0
        end
    end

    self.param_ai_use_skill.auto_shoot_target_obj_id = target_id
    character:set_locked_target(target_id)
    return true
end

function human:ai_logic_combat()
    -- print("human:ai_logic_comba")
	local character = self:get_character()
    if character:can_use_skill_now() then
		local scene = character:get_scene()
        local current_skill = define.INVAILD_ID
        local auto_active_skill = self.param_ai_use_skill.auto_use_skill or define.INVAILD_ID
		-- skynet.logi("auto_active_skill = ",auto_active_skill)
        local queued_skill = self.param_ai_use_skill.queued_skill or define.INVAILD_ID
        local bagindex = self.param_use_item.bag_index or define.INVAILD_ID
        local position = {x = 0, y = 0}
        -- print("auto_active_skill =", auto_active_skill, ";queued_skill =", queued_skill, ";bagindex =", bagindex)
        if bagindex ~= define.INVAILD_ID then
            if character:get_obj_type() == "human" then
                local item = character:get_prop_bag_container():get_item(bagindex)
                if item == nil then
                    self.param_use_item = {}
                    return
                end
                local config = item:get_base_config()
                local script_id = config.script_id
                local skill_id = config.skill_id
                if not character:is_skill_cool_down(skill_id) then
                    character:send_operate_result_msg(define.OPERATE_RESULT.OR_COOL_DOWNING)
                    self.param_use_item = {}
                    return
                end
                if not character:can_use_this_skill_in_this_status(skill_id) then
                    character:send_operate_result_msg(define.OPERATE_RESULT.OR_U_CANNT_DO_THIS_RIGHT_NOW)
                    self.param_use_item = {}
                    return
                end
                if script_id == define.INVAILD_ID then

                else
                    self:obj_use_item(self.param_use_item.bag_index,
                        self.param_use_item.target_obj_id,
                        self.param_use_item.target_pos,
                        self.param_use_item.target_pet_guid,
                        self.param_use_item.target_bag_index)
                end
                self.param_use_item = {}
            end
        elseif queued_skill ~= define.INVAILD_ID then
            if not self:check_target_vaild(queued_skill, self.param_ai_use_skill.queued_target_obj_id) then
                self.param_ai_use_skill = { auto_use_skill = define.INVAILD_ID, queued_skill = define.INVAILD_ID, auto_shoot_target_obj_id = define.INVAILD_ID }
                self:change_state("idle")
                character:set_locked_target(define.INVAILD_ID)
                return
            end
            if not character:is_skill_cool_down(queued_skill) then
                character:send_operate_result_msg(define.OPERATE_RESULT.OR_COOL_DOWNING)
                self.param_ai_use_skill = { auto_use_skill = define.INVAILD_ID, queued_skill = define.INVAILD_ID, auto_shoot_target_obj_id = define.INVAILD_ID }
                return
            end
            if not character:can_use_this_skill_in_this_status(queued_skill) then
                character:send_operate_result_msg(define.OPERATE_RESULT.OR_U_CANNT_DO_THIS_RIGHT_NOW)
                self.param_ai_use_skill.queued_skill = define.INVAILD_ID
                return
            end
            local target_obj_id = self.param_ai_use_skill.queued_target_obj_id
            local target_obj = scene:get_obj_by_id(target_obj_id)
            if target_obj and not character:is_can_view(target_obj) then
                local msg = packet_def.GCCharStopAction.new()
                msg.m_objID = character:get_obj_id()
                msg.logic_count = character:get_logic_count()
                local params = character:get_action_params()
                msg.stop_time = params:get_continuance()
                scene:broadcast(character, msg, true)
                self.param_ai_use_skill.queued_skill = define.INVAILD_ID
                self:change_state("idle")
                return
            end
            if target_obj and target_obj:get_obj_type() == "monster"
			and target_obj:get_active_time() > 0 then
				if target_obj:get_interaction_type() ~= 1000 then
					self:obj_active_monster(queued_skill, target_obj_id, self.param_ai_use_skill.queued_target_position )
				else
					local script_id = target_obj:get_script_id()
					self:obj_use_skill(queued_skill,target_obj_id, self.param_ai_use_skill.queued_target_position,
						self.param_ai_use_skill.queued_target_direction, self.param_ai_use_skill.queued_target_guid,
						target_obj_id, queued_skill, script_id
					)
				end
			else
                self:obj_use_skill(queued_skill, target_obj_id, self.param_ai_use_skill.queued_target_position,
                    self.param_ai_use_skill.queued_target_direction, self.param_ai_use_skill.queued_target_guid,
                    self.param_ai_use_skill.queued_script_arg_1, self.param_ai_use_skill.queued_script_arg_2, self.param_ai_use_skill.queued_script_arg_3
                )
            end
            self.param_ai_use_skill.queued_skill = define.INVAILD_ID
            character:set_locked_target(target_obj_id)
        elseif auto_active_skill ~= define.INVAILD_ID then
            if auto_active_skill >= 836 and auto_active_skill <= 846 then
                skynet.error("[DBG:COMBAT] auto_active_skill=", auto_active_skill, " obj_id=", character:get_obj_id())
            end
			-- local fwq_passive_skill = character:get_game_flag_key("fwq_passive_skill")
			-- if fwq_passive_skill > 0 then
				-- auto_active_skill = fwq_passive_skill
			-- elseif auto_active_skill ~= self.auot_shot_skill_id and auto_active_skill ~= 0 then
				-- auto_active_skill = self.auot_shot_skill_id
			-- end
			-- skynet.logi("auto_active_skill = ",auto_active_skill)
            -- print("auto_shoot_target_obj_id =", self.param_ai_use_skill.auto_shoot_target_obj_id)
            if not self:check_target_vaild(auto_active_skill, self.param_ai_use_skill.auto_shoot_target_obj_id) then
                -- 目标失效，检查是否开启了自动战斗
                if character.zdzd_enabled then
                    local new_target_id = self:find_nearest_enemy(character, scene)
                    if new_target_id and new_target_id ~= define.INVAILD_ID then
                        self.param_ai_use_skill.auto_shoot_target_obj_id = new_target_id
                        character:set_locked_target(new_target_id)
                    else
                        self.param_ai_use_skill.auto_shoot_target_obj_id = define.INVAILD_ID
                        character:set_locked_target(define.INVAILD_ID)
                    end
                else
                    self.param_ai_use_skill.auto_use_skill = define.INVAILD_ID
                    self.param_ai_use_skill.auto_shoot_target_obj_id = define.INVAILD_ID
                    character:set_locked_target(define.INVAILD_ID)
                    self:change_state("idle")
                end
                return
            end
            if not character:is_skill_cool_down(auto_active_skill) then
                if auto_active_skill >= 836 and auto_active_skill <= 846 then
                    skynet.error("[DBG:COMBAT] BLOCKED auto_active_skill=", auto_active_skill, " obj_id=", character:get_obj_id(), " - cooldown")
                end
                return
            end
            if not character:can_use_this_skill_in_this_status(auto_active_skill) then
                -- 当前状态不能使用技能，保持自动战斗状态，等下一帧重试
                return
            end
            local ret = self:obj_use_skill(auto_active_skill, self.param_ai_use_skill.auto_shoot_target_obj_id
            , position, 0, define.INVAILD_ID)
            local obj_tar = scene:get_obj_by_id(self.param_ai_use_skill.auto_shoot_target_obj_id)
            -- print("auto_active_skill ret =", ret, ";obj_tar =", obj_tar, ";is_enemy =", character:is_enemy(obj_tar))
            if obj_tar and not character:is_can_view(obj_tar) then
                local msg = packet_def.GCCharStopAction.new()
                msg.m_objID = character:get_obj_id()
                msg.logic_count = character:get_logic_count()
                local params = character:get_action_params()
                msg.stop_time = params:get_continuance()
                scene:broadcast(character, msg, true)
                -- 目标不可见，检查是否开启了自动战斗
                if character.zdzd_enabled then
                    local new_target_id = self:find_nearest_enemy(character, scene)
                    if new_target_id and new_target_id ~= define.INVAILD_ID then
                        self.param_ai_use_skill.auto_shoot_target_obj_id = new_target_id
                        character:set_locked_target(new_target_id)
                    else
                        self.param_ai_use_skill.auto_shoot_target_obj_id = define.INVAILD_ID
                        character:set_locked_target(define.INVAILD_ID)
                    end
                else
                    self.param_ai_use_skill.auto_use_skill = define.INVAILD_ID
                    self.param_ai_use_skill.auto_shoot_target_obj_id = define.INVAILD_ID
                    character:set_locked_target(define.INVAILD_ID)
                    self:change_state("idle")
                end
                return
            end
            if obj_tar and ret == define.OPERATE_RESULT.OR_OK and character:is_enemy(obj_tar) then

            else
                -- 技能失败或目标非敌人，检查是否开启了自动战斗
                if character.zdzd_enabled then
                    local new_target_id = self:find_nearest_enemy(character, scene)
                    if new_target_id and new_target_id ~= define.INVAILD_ID then
                        self.param_ai_use_skill.auto_shoot_target_obj_id = new_target_id
                        character:set_locked_target(new_target_id)
                    else
                        self.param_ai_use_skill.auto_shoot_target_obj_id = define.INVAILD_ID
                        character:set_locked_target(define.INVAILD_ID)
                    end
                else
                    self.param_ai_use_skill.auto_use_skill = define.INVAILD_ID
                    self.param_ai_use_skill.auto_shoot_target_obj_id = define.INVAILD_ID
                    character:set_locked_target(define.INVAILD_ID)
                    self:change_state("idle")
                end
            end
        else
            if not self:resume_zdzd_auto_combat(character, scene) then
                self:change_state("idle")
            end
        end
    end
end

function human:event_on_be_skill(character, skill_id, good_effect)
    if character:get_obj_type() == "human" then
        if good_effect == define.ENUM_BEHAVIOR_TYPE.BEHAVIOR_TYPE_AMITY then
            self:get_character():set_assistant_id(character:get_obj_id())
        end
    end
end

function human:event_on_die(killer)
    self:change_state("dead")
    self:after_die(killer)
end


function human:push_command_die_result(resultcode)
	local character = self:get_character()
    if character:get_obj_type() == "human" then
		local isok
        if resultcode == define.ENUM_DIE_RESULT_CODE.DIE_RESULT_CODE_OUT_GHOST then
            isok = self:relive(false)
        elseif resultcode == define.ENUM_DIE_RESULT_CODE.DIE_RESULT_CODE_RELIVE then
            isok = self:relive(true)
        elseif resultcode == define.ENUM_DIE_RESULT_CODE.DIE_RESULT_CODE_NEW_PLAYER then
            isok = self:relive(true)
        end
        if isok and self.on_relive_script_id then
            scriptenginer:call(self.on_relive_script_id, "OnRelive", character:get_obj_id())
        end
    end
end

function human:push_command_call_of_result(resultcode)
    if self:get_character():get_obj_type() == "human" then
        if resultcode == define.ENUM_CALLOF_RESULT_CODE.CALLOF_RESULT_CODE_ACCEPT then
            self:accept_call_of()
        elseif resultcode == define.ENUM_CALLOF_RESULT_CODE.CALLOF_RESULT_CODE_REFUSE then
            self:refuse_call_of()
        end
    end
end

function human:push_command_jump()
    if self:get_character():get_obj_type() ~= "human" then
        return define.OPERATE_RESULT.OR_ERROR
    end
    self:jump()
    self.param_ai_use_skill = {}
    return 0
end

function human:jump()
    return self.state:jump(self)
end

function human:push_command_mood_state(moodstate)
	local character = self:get_character()
    if character:get_obj_type() == "human" then
        character:set_mood_state(moodstate)
    end
end

function human:push_command_idle()
    self.param_ai_use_skill = {}
	local character = self:get_character()
    actionenginer:interrupt_current_action(character)
    character:interrupt_current_ability_opera()
    return self:stop()
end

function human:push_command_stall()
    local result = self:stall()
    return result
end

function human:stall(ai)
    return self.state:stall(ai)
end

function human:push_command_use_ability()
    local result = self:use_ability()
    if define.OPERATE_RESULT.OR_OK ~= result then
		local character = self:get_character()
        if character:get_obj_type() == "human" then
            character:send_operate_result_msg(result)
        end
    end
    return result
end

function human:push_command_default_event(npc_id)
    if self:get_state_name() == "team_follow" then
        return
    end
    local character = self:get_character()
    local npc = character:get_scene():get_obj_by_id(npc_id)
    if npc == nil then
        return
    end
    if npc:get_obj_type() == "human" then
        return
    end
    if self:get_character_logic() == define.ENUM_CHARACTER_LOGIC.CHARACTER_LOGIC_MOVE then
        self:stop()
    end
    if npc:get_obj_type() == "monster" then
        local ai = npc:get_ai()
        if ai:is_convoy_npc() then
            return
        else
            ai:start_service()
            ai:stop()
        end
    end
    local ores = self:validate_event(npc)
    if ores ~= define.OPERATE_RESULT.OR_OK then
        return
    end
    npc:default_event(character)
    return define.OPERATE_RESULT.OR_OK
end

function human:push_command_event_request(npc_id, ...)
    if self:get_state_name() == "team_follow" then
        return
    end
    local character = self:get_character()
    local npc = character:get_scene():get_obj_by_id(npc_id)
    if npc == nil then
        return
    end
    if npc:get_obj_type() == "human" then
        return
    end
    if self:get_character_logic() == define.ENUM_CHARACTER_LOGIC.CHARACTER_LOGIC_MOVE then
        self:stop()
    end
    if npc:get_obj_type() == "monster" then
        local ai = npc:get_ai()
        if ai:is_convoy_npc() then
            return
        else
            ai:start_service()
            ai:stop()
        end
    end
    local ores = self:validate_event(npc)
    if ores ~= define.OPERATE_RESULT.OR_OK then
        return
    end
    npc:event_request(character, ...)
    return define.OPERATE_RESULT.OR_OK
end

function human:push_command_move(handle, path, line)
    require("cys_battle_assist").stop(self:get_character(), "Đã dừng tự chiến đấu theo lệnh di chuyển.")
    local result = self:move(handle, path, line)
    if result >= 0 then
        -- 使用路径终点而非首点，让嬍物的跟随目标是主人的最终目的地
        local pos_tar = path[#path]
        self:baby_go(pos_tar)
        self.param_ai_use_skill = {}
        self:team_member_to_move()
    end
end

function human:push_command_use_skill(skill_id, ...)
	local character = self:get_character()
    if not character:is_character_logic_use_skill() then
        if skill_id == define.INVAILD_ID then
            if self:get_ai_state():get_state_name() == "combat" then
                self:change_state("idle")
            end
        else
            -- local can = character:can_use_skill_now()
            local result = self:use_skill(skill_id, ...)
            -- skynet.logi("push_command_use_skill result =", result)
            if result == define.OPERATE_RESULT.OR_OK then
                -- skynet.logi("can_use_skill_now is =", can)
                self:change_state("combat")
                -- if not self:is_enter_combat_state(skill_id, ...) then
                --     --self:push_skill_to_queue(skill_id, ...)
                --     local id_tar, x, y, dir, guid_tar = ...
                --     local pos_tar = { x = x, y = y }
                --     character:do_use_skill(skill_id, id_tar, pos_tar, dir, guid_tar)
                -- end
                -- 先保留原逻辑的副作用（锁敌、设置 auto_use_skill）
                local enter_combat = self:is_enter_combat_state(skill_id, ...)
                -- 不管是否进入战斗，都直接执行技能
                local id_tar, x, y, dir, guid_tar, script_arg_1, script_arg_2, script_arg_3 = ...
                local pos_tar = { x = x, y = y }
                local ret = character:do_use_skill(skill_id, id_tar, pos_tar, dir, guid_tar,script_arg_1, script_arg_2, script_arg_3)
                -- 如果直接执行成功，清除 auto_use_skill 防止心跳里二次触发
                -- if enter_combat and ret == define.OPERATE_RESULT.OR_OK then
                --     self.param_ai_use_skill.auto_use_skill = define.INVAILD_ID
                --     self.param_ai_use_skill.auto_shoot_target_obj_id = define.INVAILD_ID
                -- end
            end
            return result
        end
    else
        print("char is use skill")
    end
end

function human:push_command_use_item(...)
    local result = self:use_item(...)
    if result == define.OPERATE_RESULT.OR_OK then
        self:change_state("combat")
        self:push_item_to_queue(...)
    end
    return result
end

function human:push_command_mission_accept(npc_id, mission_id)
    self:stop()
    local character = self:get_character()
    assert(character:get_obj_type() == "human", "mission accept need human")
    if not character:get_scene():on_mission_check(character, mission_id) then
        return define.OPERATE_RESULT.OR_OK
    end
    if npc_id ~= define.INVAILD_ID then

    else

    end
end

function human:push_command_mission_abandon(mission_id)
    scriptenginer:call(mission_id, "OnAbandon", self:get_character():get_obj_id())
    return define.OPERATE_RESULT.OR_OK
end

function human:push_command_stop_team_follow()
    local character = self:get_character()
    if character:get_team_follow_flag() then
        self:stop_team_follow()
    else
        return define.OPERATE_RESULT.OR_OK
    end
end

function human:push_command_mission_refuse()

end

function human:push_command_mission_submit()

end

function human:push_command_mission_check()

end

function human:push_command_mission_continue()

end

function human:push_command_team_follow()
    -- CYS-MOUNT-FLIGHT
    if require('cys_mount_flight').active(self:get_character()) then return define.OPERATE_RESULT.OR_BUSY end
    return self:start_team_follow()
end

function human:start_team_follow()
    local character = self:get_character()
    self:change_state("team_follow")
    local team_info = character:get_team_info()
    local team_leader_guid = team_info:get_team_leader()
    local team_leader = character:get_scene():get_obj_by_guid(team_leader_guid)
    if team_leader then
        self.team_follow_base_speed = team_leader:get_speed()
    end
    if not self.team_follow_base_speed or self.team_follow_base_speed <= 0 then
        self.team_follow_base_speed = character:get_speed()
    end
    if not self.team_follow_base_speed or self.team_follow_base_speed <= 0 then
        self.team_follow_base_speed = 5
    end
    character:set_team_follow_speed(self.team_follow_base_speed)
    self.team_follow_speed_tick = 0
    self.team_follow_check_tick = 0
end


function human:stop_team_follow()
    self:stop()
    self:change_state("idle")
    local character = self:get_character()
    character:set_team_follow_speed(character:get_speed())
    character:set_team_follow_speed_up(false)
    character:send_refresh_attrib()
    return define.OPERATE_RESULT.OR_OK
end

function human:team_member_to_move()

end

function human:is_enter_combat_state(skill_id, id_tar)
	local character = self:get_character()
    if not character then
        return false
    end
    if skill_id == define.INVAILD_ID then
        return false
    end
    if not character:is_alive() then
        return false
    end
    local template = character:get_scene():get_skill_enginer():get_skill_template(skill_id)
    if not template then
        return false
    end
    if id_tar == define.INVAILD_ID then
        return false
    end
    character:set_locked_target(id_tar)
    -- skynet.logi("is_enter_combat_state template.auto_shot_skill_flag =", template.auto_shot_skill_flag)
    if template.auto_shot_skill_flag then
		local have_weapon = character:get_equip(define.HUMAN_EQUIP.HEQUIP_WEAPON)
		if skill_id == 0 and have_weapon then
			self.param_ai_use_skill.auto_use_skill = self.auot_shot_skill_id
		else
			self.param_ai_use_skill.auto_use_skill = skill_id
		end
		-- skynet.logi("human:is_enter_combat_state id_tar =",id_tar)
        self.param_ai_use_skill.auto_shoot_target_obj_id = id_tar
        return true
    end
    return false
end

function human:push_skill_to_queue(skill_id, obj_tar, x, y, dir, guid_tar, script_arg_1, script_arg_2, script_arg_3)
    -- skynet.logi("push_skill_to_queue skill_id =", skill_id, ";obj_tar =", obj_tar)
    local template = skillenginer:get_skill_template(skill_id)
    if not template then
        return
    end
    if template.auto_shot_skill_flag then
        return
    end
    local character = self:get_character()
    if character then
        local params = character:get_targeting_and_depleting_params()
        if not actionenginer:can_do_next_action(character) then
            if skill_id == params:get_activated_skill() then
                return
            end
        end
        -- print("template.enable_or_disable_auto_shot =", template.enable_or_disable_auto_shot )
        if template.enable_or_disable_auto_shot == 1 then
            self.param_ai_use_skill.auto_use_skill = define.INVAILD_ID
			-- skynet.logi("human:push_skill_to_queue define.INVAILD_ID =",define.INVAILD_ID)
            self.param_ai_use_skill.auto_shoot_target_obj_id = define.INVAILD_ID
            local pet = character:get_pet()
            if pet then
                pet:get_ai():baby_to_idle()
            end
        elseif template.enable_or_disable_auto_shot == 0 then
            print("pass")
        elseif character:get_obj_id() ~= obj_tar then
            self.param_ai_use_skill.auto_use_skill = self.auot_shot_skill_id
			-- skynet.logi("human:push_skill_to_queue obj_tar =",obj_tar)
            self.param_ai_use_skill.auto_shoot_target_obj_id = obj_tar
        end
        self.param_ai_use_skill.queued_skill = skill_id
        self.param_ai_use_skill.queued_target_guid = guid_tar
        self.param_ai_use_skill.queued_target_direction = dir
        self.param_ai_use_skill.queued_target_position = { x = x, y = y}
        self.param_ai_use_skill.queued_target_obj_id = obj_tar
        self.param_ai_use_skill.queued_script_arg_1 = script_arg_1
        self.param_ai_use_skill.queued_script_arg_2 = script_arg_2
        self.param_ai_use_skill.queued_script_arg_3 = script_arg_3
        
    end
end

function human:push_item_to_queue(bag_index, target_obj_id, target_pos, target_pet_guid, target_item_bag_index)
    local character = self:get_character()
    local params = character:get_targeting_and_depleting_params()
    if not character:get_scene():get_action_enginer():can_do_next_action(character) then
        if bag_index == params:get_bag_index_of_deplted_item() then
            return
        end
    end
    self.param_use_item.bag_index = bag_index
    self.param_use_item.target_item_bag_index = target_item_bag_index
    self.param_use_item.target_obj_id = target_obj_id
    self.param_use_item.target_pos = target_pos
    self.param_use_item.target_pet_guid = target_pet_guid
    -- print("human:push_item_to_queue", bag_index, target_item_bag_index, target_obj_id, target_pos, target_pet_guid)
end

function human:get_follow_pos()

end

function human:follow_move(character, to_pos, dist, member_index)
    local config_info = configenginer:get_config("config_info")
    local follow_dist = config_info.Team.AvailableFollowDist

    character:in_team_follow_range()

    -- 计算基础速度，确保 > 0（Lua 中 0 是 truthy，不能用 or 兜底）
    local base_speed = self.team_follow_base_speed
    if not base_speed or base_speed <= 0 then
        base_speed = character:get_team_follow_speed()
    end
    if not base_speed or base_speed <= 0 then
        base_speed = character:get_speed()
    end
    if not base_speed or base_speed <= 0 then
        base_speed = 5
    end
    local new_speed = base_speed
    local new_speed_up = false

    -- 落后时加速追赶，距离越远加速越高，全程不瞬移
    if dist > 3 then
        local boost = 1.1
        if dist > 20 then
            boost = 2.0
        elseif dist > follow_dist then
            boost = 1.5
        elseif dist > 8 then
            boost = 1.3
        elseif dist > 5 then
            boost = 1.2
        end

        new_speed = math.min(base_speed * boost, base_speed * 3.0)
        new_speed_up = true
    end
    
    if math.abs(character:get_team_follow_speed() - new_speed) > 0.1 or character:get_team_follow_speed_up() ~= new_speed_up then
        character:set_team_follow_speed(new_speed)
        character:set_team_follow_speed_up(new_speed_up)
        character:send_refresh_attrib()
    end
    
    local result = self:move_to_pos(to_pos)
    if result == define.OPERATE_RESULT.OR_OK then
        self:baby_go(to_pos)
    end
end



function human:after_die(idKiller)
    self:leave_team_follow_after_die()
    self:relase_pet_after_die()
    self:can_relive_after_die()
    local character = self:get_character()
    local killer = character:get_scene():get_obj_by_id(idKiller)
    if killer and killer:get_obj_type() == "pet" then
        local owner = killer:get_owner()
        if owner then
            idKiller = owner:get_obj_id()
        end
    end
    self:add_killer_pk_value(idKiller)
    self:pentalty_after_die(idKiller)
    self:on_be_kill(idKiller)
    character:get_scene():on_player_die(character:get_obj_id(), idKiller)
end

function human:on_be_kill(idKiller)
    local character = self:get_character()
    local scene = character:get_scene()
    local killer = scene:get_obj_by_id(idKiller)
	
    if not killer or killer == character or killer:get_obj_type() ~= "human" then
        return
    end
    self:on_be_human_kill(killer)
end

function human:add_killer_pk_value(idKiller)
    local character = self:get_character()
    local scene = character:get_scene()
    local killer = scene:get_obj_by_id(idKiller)
    if not killer or killer == character or killer:get_obj_type() ~= "human" then
        return
    end
    if not scene:is_allow_add_pk_value() then
        return
    end
    if not character:is_attackers(killer) and not killer:is_in_pk_declaration_list(character) then
        return
    end
    if character:get_pk_value() > 0 then
        return
    end
    if character:is_wild_war_guild(killer) then
        return
    end
    local value = killer:get_pk_value()
    value = value < 0 and 0 or value
    value = value + 1
    killer:set_pk_value(value)
end

function human:on_be_human_kill(killer)
    local character = self:get_character()
    self:send_be_human_kill_mail(character, killer)
    self:send_kill_human_mail(character, killer)
    self:relation_on_be_human_kill(killer)
end

function human:send_be_human_kill_mail(character, killer)
    local mail = {}
    mail.guid = define.INVAILD_ID
    mail.source = ""
    mail.portrait_id = define.INVAILD_ID
    mail.dest = character:get_name()
    mail.content = string.format("您被玩家 %s 杀死了", killer:get_name())
    mail.flag = define.MAIL_TYPE.MAIL_TYPE_SYSTEM
    mail.create_time = os.time()
    character:get_scene():send_world(character, "lua", "send_mail", mail)
end

function human:send_kill_human_mail(character, killer)
    local mail = {}
    mail.guid = define.INVAILD_ID
    mail.source = ""
    mail.portrait_id = define.INVAILD_ID
    mail.dest = killer:get_name()
    mail.content = string.format("您杀死了玩家 %s", character:get_name())
    mail.flag = define.MAIL_TYPE.MAIL_TYPE_SYSTEM
    mail.create_time = os.time()
    character:get_scene():send_world(character, "lua", "send_mail", mail)
end

function human:relation_on_be_human_kill(killer)
    local character = self:get_character()
    local scene = character:get_scene()
    local pvp_rule = scene:get_pvp_rule()
    if pvp_rule == 2 or pvp_rule == 6 then
        character:relation_on_be_human_kill(killer)
    end
end

function human:leave_team_follow_after_die()
    local character = self:get_character()
    if character:get_team_follow_flag() then
        character:stop_team_follow()
    end
end

function human:relase_pet_after_die()
    local character = self:get_character()
    character:recall_pet()
end

function human:can_relive_after_die()
    self.param_ai_use_skill = {}
    local config_info = configenginer:get_config("config_info")
    local character = self:get_character()
    local can_relive = character:is_can_relive()
	local resultcode = can_relive and 1 or 0
    local is_new_player_relive = self:get_character():is_new_player_relive()
	-- if character:get_scene():get_auto_revive_or_escape() then
		-- self:push_command_die_result(resultcode)
		-- return
	-- end
    local msg = packet_def.GCPlayerDie.new()
    msg.new_player = is_new_player_relive and 1 or 0
    msg.can_relive = resultcode
    msg.utime = config_info.Human.OutGhostTime
    self.dead_timer = config_info.Human.OutGhostTime
    character:get_scene():send2client(character, msg)
end

function human:pentalty_after_die(idKiller)
    local character = self:get_character()
    -- 替身傀儡（30008029）：背包中有未加锁的，消耗1个免除全部死亡惩罚
    local TISHENKUILEI_ID = 30008029
    local container = character:get_prop_bag_container()
    local tishenkuilei_bag_index = nil
    for i, slot_item in container:ipairs("prop") do
        if slot_item and not slot_item:is_empty()
            and slot_item:get_index() == TISHENKUILEI_ID
            and not slot_item:is_lock() then
            tishenkuilei_bag_index = i
            break
        end
    end
    if tishenkuilei_bag_index ~= nil then
        local logparam = { reason = "替身傀儡免除死亡惩罚", user_name = character:get_name(), user_guid = character:get_guid() }
        local consume_ok = human_item_logic:dec_item_lay_count(logparam, character, tishenkuilei_bag_index, 1)
        if consume_ok then
            character:notify_tips("替身傀儡替你挡下了死亡惩罚，消耗替身傀儡x1")
            return
        end
    end
    local penalty_id = self:pentalty_type_after_die(idKiller)
    local die_penalty = configenginer:get_config("die_penalty")
    local penalty_info = die_penalty[penalty_id]
    if penalty_info == nil then
        return
    end
    local is_counter_killed = self:is_counter_killed(character, idKiller)
    self:pentalty_exp_after_die(penalty_info, character, is_counter_killed)
    self:pentalty_equip_dur_after_die(penalty_info, character, is_counter_killed)
    local limit_exchange = character:check_right_limit_exchange()
    -- if limit_exchange then
        -- return
    -- end
    local die_drop_items = { drop_money = 0 }
    self:pentalty_money_after_die(penalty_info, character, die_drop_items)
    self:pentalty_item_drop_after_die(penalty_info, character, die_drop_items)
    if limit_exchange then
        return
    end
    self:create_die_lose_items_box(character, die_drop_items)
end

function human:create_die_lose_items_box(character, die_drop_items)
    if die_drop_items.drop_money > 0 or #die_drop_items > 0 then
        local conf = {}
        local world_pos = character:get_world_pos()
        conf.world_pos = { x = world_pos.x, y = world_pos.y}
        conf.monster_id = define.INVAILD_ID
        conf.owner_guid = define.INVAILD_ID
        conf.drop_items = {}
        local item_box_id = character:get_scene():create_item_box(conf)
        local item_box = character:get_scene():get_obj_by_id(item_box_id)
        if item_box then
            local container = item_box:get_container()
            local log_param = {}
            local is_bind = false
            if die_drop_items.drop_money > 0 then
                local item_operator = require "item_operator":getinstance()
                local way = 0
                local r, bag_index = item_operator:create_item_with_quality(log_param, 30001000, container, is_bind, way)
                if r then
                    local item = container:get_item(bag_index)
                    if item then
                        item:set_param(0, die_drop_items.drop_money, "uint")
                    end
                end
            end
            if #die_drop_items > 0 then
                for _, item in ipairs(die_drop_items) do
                    local bag_index = container:get_empty_item_index()
                    if bag_index ~= define.INVAILD_ID then
                        container:set_item(bag_index, item)
                    end
                end
            end
        end
    end
end

function human:is_counter_killed(character, idKiller)
    local killer = character:get_scene():get_obj_by_id(idKiller)
    if killer and killer ~= character and killer:get_obj_type() == "human" then
        return character:is_counter_killed(killer)
    else
        return false
    end
end

function human:pentalty_type_after_die(idKiller)
    local character = self:get_character()
    local scene_type = character:get_scene():get_type()
    local pk_value_index
    if character:get_level() < 10 then
        pk_value_index = 0
    else
        local pk_value = character:get_pk_value()
        if pk_value < define.ENUM_PK_VALUE_RANGE.PK_VALUE_RANGE_1 then
            pk_value_index = 1
        elseif pk_value < define.ENUM_PK_VALUE_RANGE.PK_VALUE_RANGE_20 then
            pk_value_index = 2
        elseif pk_value < define.ENUM_PK_VALUE_RANGE.PK_VALUE_RANGE_40 then
            pk_value_index = 3
        elseif pk_value < define.ENUM_PK_VALUE_RANGE.PK_VALUE_RANGE_60 then
            pk_value_index = 4
        elseif pk_value < define.ENUM_PK_VALUE_RANGE.PK_VALUE_RANGE_80 then
            pk_value_index = 5
        else
            pk_value_index = 6
        end
    end
    local killer = character:get_scene():get_obj_by_id(idKiller)
    local obj_type = killer and killer ~= character and killer:get_obj_type() or "environment"
    local die_type
    if character:get_scene():get_pvp_rule() == 9 then
        die_type = define.ENUM_HUMAN_DIE_TYPE.HUMAN_DIE_TYPE_INTERCHANGE
    else
        if obj_type == "human" then
            die_type = define.ENUM_HUMAN_DIE_TYPE.HUMAN_DIE_TYPE_PLAYER_KILL
        elseif obj_type == "pet" then
            local owner = killer:get_owner()
            if owner and owner ~= character and owner:get_obj_type() == "human" then
                die_type = define.ENUM_HUMAN_DIE_TYPE.HUMAN_DIE_TYPE_PLAYER_KILL
            else
                die_type = define.ENUM_HUMAN_DIE_TYPE.HUMAN_DIE_TYPE_MONSTER_KILL
            end
        else
            die_type = define.ENUM_HUMAN_DIE_TYPE.HUMAN_DIE_TYPE_MONSTER_KILL
        end
    end
    return scene_type * 100 + pk_value_index * 10 + die_type
end

function human:pentalty_exp_after_die(penalty_info, character, is_counter_killed)
    local min_exp_modify
    local max_exp_modify
    local percent_exp_min
    local percent_exp_max
    if is_counter_killed then
        percent_exp_min = (penalty_info.percent_exp_min or 0) < 10 and 10 or penalty_info.percent_exp_min
        percent_exp_max = (penalty_info.percent_exp_max or 0) < 10 and 10 or penalty_info.percent_exp_max
    else
        percent_exp_min = penalty_info.percent_exp_min
        percent_exp_max = penalty_info.percent_exp_max
    end
    if percent_exp_min then
        min_exp_modify = math.floor(character:get_exp() * percent_exp_min / 100)
    else
        min_exp_modify = penalty_info.exp_min
    end
    if percent_exp_max then
        max_exp_modify = math.floor(character:get_exp() * percent_exp_max / 100)
    else
        max_exp_modify = penalty_info.exp_max
    end
    if max_exp_modify >= min_exp_modify then
        local modify
        if max_exp_modify ~= min_exp_modify then
            modify = math.random(min_exp_modify, max_exp_modify)
        else
            modify = min_exp_modify
        end
        if character:get_exp() > modify then
            character:set_exp(character:get_exp() - modify)
        else
            character:set_exp(0)
        end
        if modify > 0 then
            local NotifyMsg = string.format("@*;SrvMsg;DIE_LOSE_EXP_MSG;%u", modify)
            local msg = packet_def.GCChat.new()
            msg.ChatType = define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA
            msg:set_content(NotifyMsg)
            msg.unknow_2 = 1
            msg:set_source_name(character:get_name())
            character:get_scene():send2client(character, msg)
        end
    end
end

function human:pentalty_money_after_die(penalty_info, character, die_drop_items)
    local min_money_modify
    local max_money_modify
    if penalty_info.percent_money_min then
        min_money_modify = math.floor(character:get_money() * penalty_info.percent_money_min / 100)
    else
        min_money_modify = penalty_info.money_min
    end
    if penalty_info.percent_money_max then
        max_money_modify = math.floor(character:get_money() * penalty_info.percent_money_max / 100)
    else
        max_money_modify = penalty_info.money_max
    end
    if max_money_modify >= min_money_modify then
        local modify
        if max_money_modify ~= min_money_modify then
            modify = math.random(min_money_modify, max_money_modify)
        else
            modify = min_money_modify
        end
        if character:get_money() > modify then
            character:set_money(character:get_money() - modify, "死亡惩罚-扣钱")
        else
            character:set_money(0, "死亡惩罚-扣钱")
        end
        if modify > 0 then
            local NotifyMsg = string.format("@*;SrvMsg;DIE_LOSE_MONEY_MSG;%u", modify)
            local msg = packet_def.GCChat.new()
            msg.ChatType = define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA
            msg:set_content(NotifyMsg)
            msg.unknow_2 = 1
            msg:set_source_name(character:get_name())
            character:get_scene():send2client(character, msg)
			local limit_exchange = character:check_right_limit_exchange()
            if character:get_pk_value() > 0 then
				if limit_exchange then
					die_drop_items.drop_money = 1
				else
					die_drop_items.drop_money = math.ceil(modify * 0.8)
				end
            end
        end
    end
end

function human:pentalty_equip_dur_after_die(penalty_info, character, is_counter_killed)
    local protect_rate = equip_dress_bonus.get_xiuyi_no_durability_loss_rate(character)
    if protect_rate > 0 and math.random(10000) <= protect_rate then
        character:notify_tips("#{SZTJ_251014_09}")
        return
    end
    local min_dur_modify = 0
    local max_dur_modify = 0
    if penalty_info.percent_equip_dur_min then
        min_dur_modify = penalty_info.percent_equip_dur_min
    end
    if penalty_info.percent_equip_dur_max then
        max_dur_modify = penalty_info.percent_equip_dur_max
    end
    if max_dur_modify >= min_dur_modify then
        local modify
        if max_dur_modify ~= min_dur_modify then
            modify = math.random(min_dur_modify, max_dur_modify)
        else
            modify = min_dur_modify
        end
        if is_counter_killed then
            modify = modify < 5 and 5 or modify
        else
            modify = modify < 2 and 2 or modify
        end
        if modify > 0 then
            character:equip_dur_modify(modify)
        end
    end
end

function human:pentalty_item_drop_after_die(penalty_info, character, die_drop_items)
    if penalty_info == nil then
        return
    end
    if penalty_info.percent_item_min and penalty_info.percent_item_max then
        local item_drop_percent
        if penalty_info.percent_item_min ~= penalty_info.percent_item_max then
            item_drop_percent = math.random(100) % (penalty_info.percent_item_max - penalty_info.percent_item_min) + penalty_info.percent_item_min
        else
            item_drop_percent = penalty_info.percent_item_min
        end
        if 0 < item_drop_percent then
            local prop_bag_container = character:get_prop_bag_container()
            local pos = prop_bag_container:get_rand_not_expensive_item_pos()
            if pos ~= define.INVAILD_ID then
                local item = prop_bag_container:get_item(pos)
                if item then
                    local name = item:get_name()
                    local content = string.format("由于您受到了死亡的巨大打击，您包裹内的%s已经丢失", name)
                    local mail = {}
                    mail.guid = define.INVAILD_ID
                    mail.source = ""
                    mail.portrait_id = define.INVAILD_ID
                    mail.dest = character:get_name()
                    mail.content = content
                    mail.flag = define.MAIL_TYPE.MAIL_TYPE_SYSTEM
                    mail.create_time = os.time()
                    skynet.send(".world", "lua", "send_mail", mail)

                    local msg = packet_def.GCDiscardItemResult.new()
                    msg.item_index = item:get_index()
                    msg.opt = packet_def.CGDiscardItem.OPT.FromBag
                    msg.bag_index = pos
                    msg.result = define.DISCARDITEM_RESULT.DISCARDITEM_SUCCESS
                    character:get_scene():send2client(character, msg)

                    prop_bag_container:erase_item(pos)
					
					local limit_exchange = character:check_right_limit_exchange()
					if limit_exchange then
						return
					end
                    if not item:is_bind() then
                        table.insert(die_drop_items, item)
                    end
                end
            end
        end
    end
end

function human:pentalty_equip_drop_after_die(penalty_info, character)

end

function human:on_relive_info_changed()
    if "dead" == self:get_ai_state():get_state_name() then
		local character = self:get_character()
        local config_info = configenginer:get_config("config_info")
        local can_relive = character:get_can_relive()
        local is_new_player_relive = character:is_new_player_relive()
        local msg = packet_def.GCPlayerDie.new()
        msg.can_relive = can_relive and 1 or 0
        msg.new_player = is_new_player_relive and 1 or 0
        msg.utime = config_info.Human.OutGhostTime
        character:get_scene():send2client(character, msg)
    end
end

function human:on_call_of_info_changed()

end

function human:accept_call_of()

end

function human:result_call_of()

end

function human:force_interrupt_skill()

end

function human:validate_event()

end

-- 自动战斗寻敌：在角色周围搜索最近的可攻击敌方目标
function human:find_nearest_enemy(character, scene)
    local position = character:get_world_pos()
    -- 读取自动战斗配置：mission_id 513 的 bit0 = 不攻击玩家, bit1 = 使用远程打怪
    local zdzd_flags = character:get_mission_data_by_script_id(513) or 0
    local no_attack_player = (zdzd_flags & 1) == 1
    local use_long_range = (zdzd_flags & 2) == 2
    -- 远程打怪模式搜索范围更大
    local radious = use_long_range and 25 or 15
    local operate = {
        obj = character,
        x = position.x,
        y = position.y,
        radious = radious,
        target_logic_by_stand = 1,
        check_can_view = true
    }
    local ok, nearbys = pcall(scene.scan, scene, operate)
    if not ok or not nearbys then
        return define.INVAILD_ID
    end
    local best_id = define.INVAILD_ID
    local best_dist = math.huge
    for _, nb in ipairs(nearbys) do
        if self:is_character_obj(nb)
            and nb:is_alive()
            and character:is_enemy(nb)
            and character:is_can_view(nb)
            and (not no_attack_player or nb:get_obj_type() ~= "human") then
            local nb_pos = nb:get_world_pos()
            local dx = nb_pos.x - position.x
            local dy = nb_pos.y - position.y
            local dist = dx * dx + dy * dy
            if dist < best_dist then
                best_dist = dist
                best_id = nb:get_obj_id()
            end
        end
    end
    return best_id
end

function human:check_target_vaild(skill_id, id_tar)
	local character = self:get_character()
	local scene = character:get_scene()
    local teamplate = scene:get_skill_enginer():get_skill_template(skill_id)
    if not teamplate then
		character:send_operate_result_msg(define.OPERATE_RESULT.OR_INVALID_SKILL)
        return false
    end
    if teamplate.select_type == define.ENUM_SELECT_TYPE.SELECT_TYPE_CHARACTER then
        local tar = scene:get_obj_by_id(id_tar)
        if not tar then
			character:send_operate_result_msg(define.OPERATE_RESULT.OR_NO_TARGET)
            return false
        end
        if not self:is_character_obj(tar) then
			character:send_operate_result_msg(define.OPERATE_RESULT.OR_INVALID_TARGET)
            return false
		elseif teamplate.menpai ~= -1
		and tar:get_obj_type() == "monster"
		and tar:get_active_time() > 0 then
		-- and tar:get_interaction_type() ~= 0 then
			character:send_operate_result_msg(define.OPERATE_RESULT.OR_INVALID_TARGET)
			return false
        end
        local state = teamplate.target_must_in_special_state
        local must_alive = state == 0 or state == -1
        local must_dead = state == 1 or state == -1
        -- print("must_alive =", must_alive, ";must_dead =", must_dead, ";tar:is_alive() =", tar:is_alive())
        if must_alive then
            if tar:is_alive() then
                return true
            end
			-- character:send_operate_result_msg(define.OPERATE_RESULT.OR_TARGET_DIE)
        end
        if must_dead then
            if not tar:is_alive() then
                return true
            end
			-- character:send_operate_result_msg(define.OPERATE_RESULT.OR_INVALID_TARGET)
        end
        return false
    else
        return true
    end
end

function human:baby_go(pos_tar)
    local character = self:get_character()
    local pet = character:get_pet()
    if pet == nil then
        return
    end
    local pet_ai = pet:get_ai()
    pet_ai:baby_go(pos_tar)
end

function human:set_guild_int_param_by_index(index, val)
    local guild_int_param_by_index = self.guild_int_param_by_index or {}
    self.guild_int_param_by_index = guild_int_param_by_index
    self.guild_int_param_by_index[index] = val
end

function human:get_guild_int_param_by_index(index)
    local guild_int_param_by_index = self.guild_int_param_by_index or {}
    self.guild_int_param_by_index = guild_int_param_by_index
    return self.guild_int_param_by_index[index] or 0
end

return human
