local skynet = require "skynet"
-- [DBG_ZDZD] log rate-limit: same obj_id+reason at most once per 30s
local _zdzd_log_last = {}
local function zdzd_log(reason, obj_id, ...)
    local key = tostring(obj_id) .. ":" .. reason
    local now = os.time()
    if _zdzd_log_last[key] and now - _zdzd_log_last[key] < 30 then
        return
    end
    _zdzd_log_last[key] = now
end

local profile = require "skynet.profile"
local class = require "class"
local utils = require "utils"
local define = require "define"
local packet_def = require "game.packet"
local configenginer = require "configenginer":getinstance()
local skillenginer = require "skillenginer":getinstance()
local actionenginer = require "actionenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local abilityenginer = require "abilityenginer":getinstance()
local item_operator = require "item_operator":getinstance()
local talentenginer = require "talentenginer":getinstance()
local equip_dress_bonus = require "equip_dress_bonus"
local ride_huayu_bonus = require "ride_huayu_bonus"
local targeting_and_depleting_params = require "scene.skill.targeting_and_depleting_params"
local action_params = require "scene.action.action_params"
local menpai_logic = require "menpai"
local ai_character = require"scene.ai.character"
local obj_base = require "scene.obj.base"
local character = class("character", obj_base)
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local DAMAGE_TYPE = DI_DamagesByValue_T.enum_DAMAGE_TYPE
local DAMAGE_TYPE_RATE = DI_DamagesByValue_T.enum_DAMAGE_TYPE_RATE
local DAMAGE_TYPE_POINT = DI_DamagesByValue_T.enum_DAMAGE_TYPE_POINT
local DAMAGE_TYPE_BACK = DI_DamagesByValue_T.enum_DAMAGE_TYPE_BACK

function character:ctor(data)
    self.guid = data.guid
    self.obj_id = data.obj_id
    self.base_attrib = data.base_attrib
    self.detail_attrib = data.detail_attrib
    self.equip_list = data.equip_list
    self.prop_bag_list = data.prop_bag_list
    self.prop_bag_size = data.prop_bag_size
    self.material_bag_size = data.material_bag_size
    self.targeting_and_depleting_params = targeting_and_depleting_params.new()
    self.skill_info = {}
    self.action_params = action_params.new()
    self.logic_count = 0
    self.action_time = 0
    self.impact_list = data.impact_list or {}
    self.character_logic = define.ENUM_CHARACTER_LOGIC.CHARACTER_LOGIC_IDLE
    self.impact_sn_seed = 0
    self.data_id = 0
    self.locked_target = nil
    self.auto_repeat_cool_down = 0
    self.do_ai_logic_time = 0
    self.character_logic_stopped = true
    self.menpai_heartbeat_time = 0
    self.target_id = define.INVAILD_ID
    self.die_timer = nil
    self.refresh_attrib_timer = 0
    self.logic_move_dist = 0
    self.last_logic_move_dir = 0
    self.dir = 0
    self.defer_self_arrive_once = nil
    self.deferred_self_arrive = nil
    --print("ai_character =", ai_character)
    self.cool_down_times = data.cool_down_times or {}
    self.ai = ai_character.new()
end

function character:init()
    self.ai:init(self)
end

function character:get_scene() return self.scene end

function character:get_scene_id() return self.sceneid end

function character:get_script_enginer() return self.scene.scriptenginer end

function character:get_guid() return self.db:get_db_attrib("guid") end

function character:get_obj_id() return self.obj_id end


function character:get_base_attribs() return self.db:get_base_attribs() end

function character:get_detail_attribs() return self.db:get_detail_attribs() end

function character:get_speed() return self:get_attrib("speed") end

function character:get_data_id()
    return self.data_id
end

function character:set_name(name)
    self.db:set_db_attrib({name = name})
end

function character:set_hp(hp)
    assert(hp >= 0, hp)
    hp = math.ceil(hp)
    self.db:set_db_attrib({ hp = hp })
end

function character:set_mp(mp)
    assert(mp >= 0, mp)
    mp = math.ceil(mp)
    self.db:set_db_attrib({ mp = mp })
end

function character:set_level(level)
    level = math.ceil(level)
    self.db:set_db_attrib({ level = level })
end

function character:set_rage(rage)
	if rage > self:get_rage() then
		if self:impact_have_impact_of_specific_impact_id(7589) then
			return
		end
	end
    self.db:set_db_attrib({ rage = rage })
end

function character:set_strike_point(point)
    self.db:set_db_attrib({ strike_point = point })
end

function character:get_strike_point()
    return self.db:get_db_attrib("strike_point")
end

function character:set_datura_flower(point)
    self.db:set_db_attrib({ datura_flower = point })
end

function character:set_temp_camp_id(id)
    self.db:set_not_gen_attrib({ camp_id = id})
end

function character:get_datura_flower()
    return self:get_attrib("datura_flower") or 0
end

function character:get_mp()
    return self:get_attrib("mp") or 0
end

function character:get_rage()
    return self:get_attrib("rage") or 0 
end

function character:get_obj_chuanci()
	return self.db:get_chuanci()
end

function character:get_obj_fangchuan()
	return self.db:get_fangchuan()
end

function character:get_chuanci_damage(sender,is_critical_hit)
	local fangchuan = self:get_obj_fangchuan()
	local chuanci = sender:get_obj_chuanci()
	chuanci = chuanci - fangchuan
	if chuanci > 0 then
		local obj_type = self:get_obj_type()
		if obj_type == "human" then
			chuanci = math.ceil(chuanci * define.CHUANCI_INFO.DAMAGE_HUMAN)
		elseif obj_type == "pet" then
			chuanci = math.ceil(chuanci * define.CHUANCI_INFO.DAMAGE_PET)
		else
			chuanci = math.ceil(chuanci * define.CHUANCI_INFO.DAMAGE_MONSTER)
		end
		if is_critical_hit and define.CHUANCI_INFO.IS_CRITICAL_HIT == 1 then
			chuanci = chuanci * 2
		end
	else
		chuanci = 0
	end
	return chuanci
end

function character:get_attack_traits_type()
    return define.MENPAI_ATTRIBUTE.MATTRIBUTE_WUMENPAI
end

function character:is_moving()
    return self:get_character_logic() == define.ENUM_CHARACTER_LOGIC.CHARACTER_LOGIC_MOVE
end

function character:is_alive_in_deed()
    return self:get_hp() > 0
end

function character:get_reputation()
    return self.db:get_db_attrib("reputation")
end

function character:set_reputation(reputation)
    self.db:set_db_attrib({ reputation = reputation })
end

function character:is_die()
    return self:get_hp() <= 0
end

function character:is_can_view(obj)
    if obj == self then
        return true
    end
    if obj:get_obj_type() == "pet" then
        if obj:get_owner() == self then
            return true
        end
    end
    if obj:get_obj_type() == "itembox" then
        return obj:is_can_view_me(self)
    elseif obj:get_obj_type() == "special" then
        local detect_level = self.db:get_attrib("detect_level") or 0
        local stealth_level = obj:get_stealth_level()
        local owner = self:get_scene():get_obj_by_id(obj:get_owner_obj_id())
        return detect_level >= stealth_level or self:is_teammate(owner) or owner == self
    else
        local detect_level = self.db:get_attrib("detect_level") or 0
        local stealth_level = obj:get_stealth_level()
        if self:get_obj_type() == "human" then
            -- return detect_level >= stealth_level or self:is_teammate(obj) or self:is_raidmate(obj)
            return detect_level >= stealth_level or self:is_teammate(obj)
        end
        return detect_level >= stealth_level
    end
end

function character:get_stealth_level()
    return self.db:get_attrib("stealth_level") or 0
end

function character:update_character_view_wg()
    local view = self:get_view()
    for obj in pairs(view) do
        if obj:get_obj_type() == "human"
		and obj:get_obj_id() ~= self:get_obj_id() then
			obj:mark_data_dirty_flag("exterior_head_id")
			obj:send_refresh_attrib()
		end
    end
end

function character:update_character_view()
    local view = self:get_view()
    for obj in pairs(view) do
        obj:stealth_level_update()
    end
    self:stealth_level_update()
    local stealth_objs = self:get_obj_can_not_view()
    for obj in pairs(stealth_objs) do
        self:on_other_stealth_level_update(obj)
    end
end

function character:get_db()
    return self.db
end

function character:set_die_time(timer)
    self.die_timer = timer
end

function character:set_top_monster()

end

function character:empty_top_monster()

end

function character:update(delta_time)
    local is = self:is_character_logic_stopped()
	-- if self:get_obj_type() == "human" then
		-- skynet.logi("obj_id =", self:get_obj_id(), ";is_character_logic_stopped =", is)
	-- end
    self:update_action_time(delta_time)
    self:update_impact(delta_time)
    self:update_cool_down(delta_time)
    self:menpai_heartbeat(delta_time)
    if not is then
        local logic = self:get_character_logic()
		-- if self:get_obj_type() == "human" then
			-- skynet.logi("name =", self:get_name(), ";logic =", logic)
		-- end
        local result = true
        if logic == define.ENUM_CHARACTER_LOGIC.CHARACTER_LOGIC_IDLE then

        elseif logic == define.ENUM_CHARACTER_LOGIC.CHARACTER_LOGIC_MOVE then
            result = self:logic_move(delta_time)
        elseif logic == define.ENUM_CHARACTER_LOGIC.CHARACTER_LOGIC_FLY then
            result = self:logic_fly(delta_time)
        elseif logic == define.ENUM_CHARACTER_LOGIC.CHARACTER_LOGIC_USE_SKILL then
            result = self:logic_use_skill(delta_time)
        elseif logic == define.ENUM_CHARACTER_LOGIC.CHARACTER_LOGIC_USE_ABILITY then
            result = self:logic_use_ability(delta_time)
        end
        if not result then
            self:stop_character_logic(true)
        end
    end
    self.ai:logic(delta_time)
    local auto_repeat_cool_down = self:get_auto_repeat_cool_down()
    if auto_repeat_cool_down > 0 then
        self:set_auto_repeat_cool_down(auto_repeat_cool_down - delta_time)
    end
    self.refresh_attrib_timer = self.refresh_attrib_timer + delta_time
    if self.refresh_attrib_timer > define.ATTR_REFESH_TIME then
        self.refresh_attrib_timer = 0
        self:send_refresh_attrib()
    end
	-- local scene = self:get_scene()
	-- local obj_type = self:get_obj_type()
	-- self.update_top_timer = self.update_top_timer + delta_time
	-- if self.update_top_timer > 1000 then
		-- self.update_top_timer = 0
		-- if self:get_obj_id() == scene:get_dmg_top_monid()
		-- and obj_type == "monster" then
			-- scene:set_dmg_top_list(self:get_damage_member())
		-- end
	-- end
	
	-- if self.die_timer then
		-- assert(obj_type == "monster" or obj_type == "pet", self:get_obj_type())
		-- if self.die_timer > delta_time then
			-- self.die_timer = self.die_timer - delta_time
		-- else
			-- self.die_timer = nil
			-- if obj_type == "monster" or obj_type == "pet" then
				-- scene:delete_temp_monster(self)
			-- end
		-- end
	-- end
end

function character:send_refresh_attrib()

end

function character:menpai_heartbeat(delta_time)
    if self:get_obj_type() ~= "human" then
        return
    end
    self.menpai_heartbeat_time = self.menpai_heartbeat_time + delta_time
    if self.menpai_heartbeat_time > define.MENPAI_HEART_BEAT_TICK then
        menpai_logic:on_heart_beat(self, delta_time)
        self.menpai_heartbeat_time = 0
    end
end

function character:update_cool_down(delta_time)
    for id, cool_down_time in pairs(self.cool_down_times) do
        cool_down_time = cool_down_time - delta_time
        --self.cool_down_times[id] = cool_down_time
        if cool_down_time <= 0 then
            self.cool_down_times[id] = nil
        else
            self.cool_down_times[id] = cool_down_time
        end
    end
end

function character:update_cool_down_by_cool_down_id(cool_down_id, time)
    cool_down_id = tostring(cool_down_id)
    if self.cool_down_times[cool_down_id] then
        self.cool_down_times[cool_down_id] = self.cool_down_times[cool_down_id] - time
        self.cool_down_times[cool_down_id] = self.cool_down_times[cool_down_id] < 0 and 0 or self.cool_down_times[cool_down_id]
        self:send_cool_down_time()
    end
end

function character:get_cool_down_by_cool_down_id(cool_down_id)
    cool_down_id = tostring(cool_down_id)
    return self.cool_down_times[cool_down_id] or 0
end

function character:send_cool_down_time()
end

function character:logic_move(utime)
    if self:is_die() then
        return false
    end
    if self:is_limit_move() then
        return false
    end
    local pos = self.move.targetPos[1]
    if pos == nil then
        return false
    end
    local cur_pos = self:get_world_pos()
    local tar_pos = pos
    local speed = self:get_speed()
    assert(speed > 0.1 and speed < 20.0, speed)
    local move_dist = speed * utime / 1000
    if move_dist <= 0.01 then
        return true
    end
    profile.start()
    local dist_to_tar = utils.my_sqrt(cur_pos, tar_pos)
    while true do
        if move_dist > dist_to_tar then
            if #(self.move.targetPos) == 1 then
                local pos_must_to = {}
                pos_must_to.x = tar_pos.x
                pos_must_to.y = tar_pos.y
                local dir = utils.my_angle(self:get_world_pos(), pos_must_to)
                self:set_dir(dir)
                self:set_world_pos(pos_must_to)
                self:stop_character_logic(false)
                break
            else
                move_dist = move_dist - dist_to_tar
                cur_pos = tar_pos
                self:set_world_pos(cur_pos)
                table.remove(self.move.targetPos, 1)
                tar_pos = self.move.targetPos[1]
                dist_to_tar = utils.my_sqrt(cur_pos, tar_pos)
            end
        else
            local cur = {}
            if dist_to_tar > 0.01 then
                cur.x = cur_pos.x + (move_dist * (tar_pos.x - cur_pos.x)) / dist_to_tar
                cur.y = cur_pos.y + (move_dist * (tar_pos.y - cur_pos.y)) / dist_to_tar
            else
                cur.x = tar_pos.x
                cur.y = tar_pos.y
            end
            local dir = utils.my_angle(self:get_world_pos(), tar_pos)
            self:set_dir(dir)
            self:set_world_pos(cur)
            break
        end
    end
    self:impact_on_logic_move(move_dist)
    self:check_need_update_view(move_dist)
    self.last_logic_move_dir = self:get_dir()
    local move_ts_diff =  profile.stop()
    self:get_scene():inc_move_use_time(move_ts_diff)
    return true
end

function character:check_need_update_view(move_dist)
    self.logic_move_dist = self.logic_move_dist + move_dist
    if self.logic_move_dist > define.AOI_RADIS / 5 then
        self.logic_move_dist = 0
        local view = self:get_view()
        local my_pos = self:get_world_pos()
        local scene = self:get_scene()
        local need_delete_objs = {}
        for o in pairs(view) do
            local pos = o:get_world_pos()
            local distsq = scene:calculate_dist_sq(pos, {x = my_pos.x, y = my_pos.y})
            if distsq > define.MAX_VIEW_DIST_SQ then
                table.insert(need_delete_objs, o)
            end
        end
        for _, o in ipairs(need_delete_objs) do
            scene:delaoiobj(o, self)
            scene:delaoiobj(self, o)
        end
    end
end

function character:logic_fly(utime)
    if self:is_die() then
        return false
    end
    local pos = self.move.targetPos[1]
    if pos == nil then
        return false
    end
    local cur_pos = self:get_world_pos()
    local tar_pos = pos
    local speed = self:get_speed()
    assert(speed > 0.1 and speed < 20.0, speed)
    local move_dist = speed * utime / 1000
    if move_dist <= 0.01 then
        return true
    end
    local dist_to_tar = utils.my_sqrt(cur_pos, tar_pos)
    while true do
        if move_dist > dist_to_tar then
            if #(self.move.targetPos) == 1 then
                local pos_must_to = {}
                pos_must_to.x = tar_pos.x
                pos_must_to.y = tar_pos.y
                local dir = utils.my_angle(self:get_world_pos(), pos_must_to)
                self:set_dir(dir)
                self:set_world_pos(pos_must_to)
                self:stop_character_logic(false)
                break
            else
                move_dist = move_dist - dist_to_tar
                cur_pos = tar_pos
                table.remove(self.move.targetPos, 1)
                tar_pos = self.move.targetPos[1]
                dist_to_tar = utils.my_sqrt(cur_pos, tar_pos)
            end
        else
            local cur = {}
            if dist_to_tar > 0.01 then
                cur.x = cur_pos.x + (move_dist * (tar_pos.x - cur_pos.x)) / dist_to_tar
                cur.y = cur_pos.y + (move_dist * (tar_pos.y - cur_pos.y)) / dist_to_tar
            else
                cur.x = tar_pos.x
                cur.y = tar_pos.y
            end
            local dir = utils.my_angle(self:get_world_pos(), tar_pos)
            self:set_dir(dir)
            self:set_world_pos(cur)
            break
        end
    end
    self:impact_on_logic_move(move_dist)
    self:check_need_update_view(move_dist)
    return true
end

function character:logic_use_ability(delta_time)
    local ability_opera = self:get_ability_opera()
    ability_opera.cur_time = ability_opera.cur_time + delta_time
    --print("logic_use_ability cur_time =", ability_opera.cur_time, ";max_time =", ability_opera.max_time)
    if ability_opera.cur_time >= ability_opera.max_time then
        self:stop_character_logic(false)
        local ability = abilityenginer:get_ability(ability_opera.ability_id)
        local res = ability:on_proc_over(self)
        if res ~= define.OPERATE_RESULT.OR_OK then
			if res then
				local msg = packet_def.GCAbilityResult.new()
				msg.ability = ability_opera.ability_id
				msg.prescription = ability_opera.pres_id
				msg.result = res
				-- assert(msg.resilt)
				self:get_scene():send2client(self, msg)
			end
        end
    end
    return true
end

function character:logic_use_skill(...)
    if not self:is_alive() then
        return false
    end
    return actionenginer:on_heart_beat(self, ...)
end

function character:is_character_logic_stopped()
    return self.character_logic_stopped
end

function character:do_move(handle, pos_tar)
    -- CYS-MOUNT-FLIGHT
    if require('cys_mount_flight').changing(self) then return define.OPERATE_RESULT.OR_BUSY end
    local now = skynet.now()
    local stop_move = false
    local stop_logic_count = self:get_logic_count()
    local old_move_copy = nil
    if not self:is_character_logic_stopped() then
        if self:get_character_logic() ~= define.ENUM_CHARACTER_LOGIC.CHARACTER_LOGIC_MOVE then
            self:stop_character_logic(true)
        else
            stop_move = true
            old_move_copy = self.move
            self:stop_character_logic(false)
        end
    end
    if self:get_speed() < 0.1 then
        return define.OPERATE_RESULT.OR_LIMIT_MOVE
    end
    if self:is_limit_move() then
        return define.OPERATE_RESULT.OR_LIMIT_MOVE
    end
    if not self:is_alive() then
        return define.OPERATE_RESULT.OR_DIE
    end
    if handle ~= -1 then
        self:set_logic_count(handle)
    else
        self:add_logic_count()
    end
    local world_pos = self:get_world_pos()
    local cur_tar_pos = pos_tar[1]
    local dir = utils.my_angle(world_pos, cur_tar_pos)
	self:set_dir(dir)

    if not stop_move then
        actionenginer:interrupt_current_action(self)
    end

    local client_pos = self._client_world_pos
    self._client_world_pos = nil
    -- GCCharMove reserves at most 16 path nodes. Keep the authoritative
    -- movement state and the client packet on the same bounded path.
    local final_path = {}
    for i = 1, math.min(#pos_tar, 0x10) do
        final_path[i] = table.clone(pos_tar[i])
    end
    local start_pos = client_pos or { x = world_pos.x, y = world_pos.y }
    self.move = {}
    self.move.targetPos = final_path
    self.move.handle = self:get_logic_count()
    self.move.start_time = now
    self.move.start_pos = start_pos
    self.move.target_nodes = table.clone(final_path)
    self.move.speed = self:get_speed()
    self:set_character_logic(define.ENUM_CHARACTER_LOGIC.CHARACTER_LOGIC_MOVE)
    local msg = packet_def.GCCharMove.new()
    msg.m_objID = self:get_obj_id()
    msg.start_time = now * 10
    msg.handleID = self:get_logic_count()
    msg.size = #final_path
    msg.path = final_path
    if stop_move then
        msg.flag = msg.flag | 0x4
        -- 用旧移动的手柄号，告诉客户端"中断的是哪个移动"
        -- char_move 已经把 logic_count 设置为新 handle，所以必须从 old_move_copy 取旧的
        msg.stop_logic_count = old_move_copy and old_move_copy.handle or stop_logic_count
        local is_team_follower = self.get_team_follow_flag
            and self:get_team_follow_flag()
            and self.get_is_team_leader
            and not self:get_is_team_leader()
        if is_team_follower then
            msg.stop_pos = { x = world_pos.x, y = world_pos.y }
        else
            local estop = self:_extrapolate_old_path(old_move_copy, now)
            if estop then
                msg.stop_pos = estop
            elseif client_pos then
                msg.stop_pos = client_pos
            else
                msg.stop_pos = { x = world_pos.x, y = world_pos.y }
            end
        end
    else
        msg.flag = msg.flag & ~0x4
    end

    self:get_scene():broadcast(self, msg, true)
    self:impact_on_move()
    return define.OPERATE_RESULT.OR_OK
end

function character:_extrapolate_old_path(old_move, now)
    if not old_move or not old_move.target_nodes or #old_move.target_nodes == 0 then
        return nil
    end
    local st = old_move.start_time
    local sp = old_move.start_pos
    local speed = old_move.speed
    if not st or not sp or not speed then
        return nil
    end
    local elapsed = now - st
    if elapsed <= 0 then
        return { x = sp.x, y = sp.y }
    end
    local total_dist = speed * elapsed / 100
    local cur = sp
    local remaining = total_dist
    for _, nxt in ipairs(old_move.target_nodes) do
        local seg = utils.my_sqrt(cur, nxt)
        if remaining >= seg then
            remaining = remaining - seg
            cur = nxt
        else
            if seg > 0.001 then
                local r = remaining / seg
                return { x = cur.x + r * (nxt.x - cur.x), y = cur.y + r * (nxt.y - cur.y) }
            else
                return { x = cur.x, y = cur.y }
            end
        end
    end
    return { x = cur.x, y = cur.y }
end

function character:do_fly(handle, pos_tar)
    if not self:is_character_logic_stopped() then
        if self:get_character_logic() ~= define.ENUM_CHARACTER_LOGIC.CHARACTER_LOGIC_MOVE then
            self:stop_character_logic(true)
        else
            self:stop_character_logic(false)
        end
    end
    if not self:is_alive() then
        return define.OPERATE_RESULT.OR_DIE
    end
    if handle ~= -1 then
        self:set_logic_count(handle)
    else
        self:add_logic_count()
    end
    actionenginer:interrupt_current_action(self)
    self.move = {}
    self.move.targetPos = pos_tar
    self.move.handle = self:get_logic_count()
    self:set_character_logic(define.ENUM_CHARACTER_LOGIC.CHARACTER_LOGIC_FLY)
    return define.OPERATE_RESULT.OR_OK
end

function character:do_idle()
    self.character_logic = define.ENUM_CHARACTER_LOGIC.CHARACTER_LOGIC_IDLE
end

function character:do_stop()
    if not actionenginer:can_do_next_action(self) then
        actionenginer:interrupt_current_action(self)
    end
    if not self:is_character_logic_stopped() then
        self:stop_character_logic(true)
    end
    self:set_action_time(0)
    self.character_logic = define.ENUM_CHARACTER_LOGIC.CHARACTER_LOGIC_IDLE
    return define.OPERATE_RESULT.OR_OK
end

function character:do_jump()
    actionenginer:interrupt_current_action(self)
end

function character:do_use_ability()
    if not self:is_character_logic_stopped() then
        self:stop_character_logic(true)
    end
    self:add_logic_count()
    local msg = packet_def.GCAbilityAction.new()
    msg.m_objID = self:get_obj_id()
    msg.logic_count = self:get_logic_count()
    local ability_opera = self:get_ability_opera()
    msg.ability = ability_opera.ability_id
    msg.prescription = ability_opera.pres_id
    msg.target_obj_id = ability_opera.obj
    msg.begin_or_end = 1
    self:get_scene():send2client(self, msg)
    self:set_character_logic(define.ENUM_CHARACTER_LOGIC.CHARACTER_LOGIC_USE_ABILITY)
    ability_opera.cur_time = 0
    return define.OPERATE_RESULT.OR_OK
end

function character:do_use_item(bag_index, target_obj_id, target_pos, target_pet_guid, target_item_bag_index)
    -- CYS-MOUNT-FLIGHT
    local flight=require 'cys_mount_flight'
    if flight.active(self) or flight.active(self:get_scene():get_obj_by_id(target_obj_id)) then return define.OPERATE_RESULT.OR_BUSY end
    if not self:is_character_logic_stopped() then
        self:stop_character_logic(true)
    end
    local params = self:get_targeting_and_depleting_params()
    params:reset()
    local item = self:get_prop_bag_container():get_item(bag_index)
    if item == nil then
        return false
    end
    local item_config = item:get_base_config()
    self:add_logic_count()
    params:set_target_bag_index(target_item_bag_index)
    params:set_deplted_item_guid(item:get_guid())
    params:set_bag_index_of_deplted_item(bag_index)
    params:set_item_index_of_deplted_item(item:get_index())
    params:set_activated_script(item_config.script_id)
    params:set_activated_skill(item_config.skill_id)
    params:set_target_obj(target_obj_id)
    params:set_target_pet_guid(target_pet_guid)
    params:set_target_position(target_pos)
    params:set_skill_level(1)

    local ret = self:get_scene():get_skill_enginer():activated_item(self)
    if not ret then
        local code = params:get_errorcode()
        return code
    end
    if self:get_character_logic() ~= define.ENUM_CHARACTER_LOGIC.CHARACTER_LOGIC_USE_SKILL and self:is_character_logic_stopped() then
        self:set_character_logic(define.ENUM_CHARACTER_LOGIC.CHARACTER_LOGIC_USE_SKILL)
    end
    if actionenginer:can_do_next_action(self) then
        if self:get_character_logic() == define.ENUM_CHARACTER_LOGIC.CHARACTER_LOGIC_USE_SKILL or self:is_character_logic_stopped() then
            self:stop_character_logic(false)
        end
    end
    return define.OPERATE_RESULT.OR_OK
end

function character:do_activite_monster(skill_id, target_obj_id, target_pos)
	-- skynet.logi("character:do_activite_monster skill_id = ",skill_id)
    if not self:is_character_logic_stopped() then
        self:stop_character_logic(true)
    end
    local params = self:get_targeting_and_depleting_params()
    params:reset()
    local monster = self:get_scene():get_obj_by_id(target_obj_id)
    if not monster then
        return define.OPERATE_RESULT.OR_NO_TARGET
    end
    local script_id = monster:get_script_id()
    if script_id == define.INVAILD_ID then
        return define.OPERATE_RESULT.OR_NO_SCRIPT
    end
    local activate_time = monster:get_active_time()
    self:add_logic_count()
    params:set_activated_script(script_id)
    params:set_activated_skill(skill_id)
    params:set_active_time(activate_time)
    params:set_target_obj(target_obj_id)
    params:set_target_pet_guid(target_pet_guid)
    params:set_target_position(target_pos)
    params:set_skill_level(1)

    local ret = self:get_scene():get_skill_enginer():activated_monster(self)
    if not ret then
        local code = params:get_errorcode()
        return code
    end
    if self:get_character_logic() ~= define.ENUM_CHARACTER_LOGIC.CHARACTER_LOGIC_USE_SKILL and self:is_character_logic_stopped() then
        self:set_character_logic(define.ENUM_CHARACTER_LOGIC.CHARACTER_LOGIC_USE_SKILL)
    end
    if actionenginer:can_do_next_action(self) then
        if self:get_character_logic() == define.ENUM_CHARACTER_LOGIC.CHARACTER_LOGIC_USE_SKILL or self:is_character_logic_stopped() then
            self:stop_character_logic(false)
        end
    end
    return define.OPERATE_RESULT.OR_OK
end

function character:activate_item()

end

function character:get_skill_level()
    local level = self:get_level()
    return  (level // 10 + 1)
end

function character:prepare_deferred_self_arrive()
    local world_pos = self:get_world_pos()
    self.defer_self_arrive_once = true
    self.deferred_self_arrive = {
        handleid = self:get_logic_count(),
        world_pos = { x = world_pos.x, y = world_pos.y },
    }
end

function character:clear_deferred_self_arrive()
    self.defer_self_arrive_once = nil
    self.deferred_self_arrive = nil
end

function character:flush_deferred_self_arrive()
    local arrive = self.deferred_self_arrive
    self:clear_deferred_self_arrive()
    if not arrive then
        return
    end
    local msg = packet_def.GCArrive.new()
    msg.m_objID = self:get_obj_id()
    msg.handleid = arrive.handleid
    msg.world_pos = arrive.world_pos
    self:get_scene():send2client(self, msg)
end

function character:do_use_skill(skill_id, id_tar, pos_tar, dir_tar, guid_tar, script_arg_1, script_arg_2, script_arg_3,charge_time)
    local template = self:get_skill_template(skill_id)
    local deferred_self_arrive = false
    if not self:is_character_logic_stopped() then
        if self:get_character_logic() == define.ENUM_CHARACTER_LOGIC.CHARACTER_LOGIC_MOVE
        and self:get_obj_type() == "human"
        and template
        and template.auto_shot_skill_flag then
            self:prepare_deferred_self_arrive()
            deferred_self_arrive = true
        else
            self:clear_deferred_self_arrive()
        end
        self:stop_character_logic(true)
    else
        self:clear_deferred_self_arrive()
    end
    local params = self:get_targeting_and_depleting_params()
    self:add_logic_count()
    local level = self:get_skill_level(skill_id)
    if self:get_obj_type() == "human" then
        level = self:get_skill_level(skill_id)
    end
    local ret = self:get_scene():get_skill_enginer():process_skill_request(self, skill_id, level,  id_tar, pos_tar, dir_tar, guid_tar, script_arg_1, script_arg_2, script_arg_3,charge_time)
    if not ret then
        local code = params:get_errorcode()
        if deferred_self_arrive then
            self:flush_deferred_self_arrive()
        else
            self:clear_deferred_self_arrive()
        end
        if code < 0 and self:get_obj_type() == "human" then
            self:send_operate_result_msg(code)
        end
        return code
    end
    self:clear_deferred_self_arrive()
    if self:get_character_logic() ~= define.ENUM_CHARACTER_LOGIC.CHARACTER_LOGIC_USE_SKILL and self:is_character_logic_stopped() then
        self:set_character_logic(define.ENUM_CHARACTER_LOGIC.CHARACTER_LOGIC_USE_SKILL)
    end
    if actionenginer:can_do_next_action(self) then
        if self:get_character_logic() == define.ENUM_CHARACTER_LOGIC.CHARACTER_LOGIC_USE_SKILL or self:is_character_logic_stopped() then
            self:stop_character_logic(false)
        end
    end
    return define.OPERATE_RESULT.OR_OK
end

function character:get_skill_info()
    return self.skill_info
end

function character:get_targeting_and_depleting_params()
    return self.targeting_and_depleting_params
end

function character:is_alive()
    return self:get_hp() > 0
end

function character:get_skill_template(skill_id)
    return skillenginer:get_skill_template(skill_id)
end

function character:can_use_this_skill_in_this_status(skill_id)
    -- CYS-MOUNT-FLIGHT
    if require('cys_mount_flight').active(self) then return false end
    -- print("character:can_use_this_skill_in_this_status skill_id =", skill_id)
    local template = self:get_skill_template(skill_id)
	if not template then
		return false
	end
    if skill_id ~= 74 then
        if template.disable_by_flag_1 then
            local can_action_1 = self:get_attrib("can_action_1")
            -- print("can_action_1 =", can_action_1)
            if can_action_1 == 0 then
                return false
            end
        end
        if template.disable_by_flag_2 then
            local can_action_2 = self:get_attrib("can_action_2")
            -- print("can_action_2 =", can_action_2)
            if can_action_2 == 0 then
                return false
            end
        end
    end
    if template.disable_by_flag_3 then
        local ride_model = self:get_attrib("ride_model") or define.INVAILD_ID
        -- print("ride_model =", ride_model)
        if ride_model ~= define.INVAILD_ID then
            return false
        end
    end
    if self:impact_forbidden_this_skill(skill_id) then
        return false
    end
    return true
end

function character:impact_forbidden_this_skill()
    return false
end

function character:is_skill_cool_down(skill_id)
    local template = self:get_scene():get_skill_enginer():get_skill_template(skill_id)
    if template == nil then
        return false
    end
    local cool_down_id = template.cool_down_id
    if cool_down_id == define.INVAILD_ID or template.auto_shot_skill_flag then
        local auto_repat_cool_down = self:get_auto_repeat_cool_down()
        -- 额外检查 cool_down_times 中以 skill_id 为 key 的冷却（天赋970 set_cool_down 写入）
        local skill_cd = self.cool_down_times[tostring(skill_id)] or 0
        if auto_repat_cool_down > 0 or skill_cd > 0 then
            return false
        end
        return true
    elseif not self:is_cool_downed(cool_down_id) then
        return false
    end
    return true
end

function character:is_cool_downed(id)
    id = tostring(id)
    local time = self.cool_down_times[id] or 0
    return time <= 0
end

function character:have_skill(skill_id)
    return true
end

function character:refix_skill(skill_info)
	local _skill_id = skill_info:get_skill_id()
	local effect_value,feature_rate
	if skill_info:get_skill_id() == 248 then
		local cool_down_time = skill_info:get_cool_down_time()
		if cool_down_time > 0 then
			effect_value,feature_rate = self:get_dw_jinjie_effect_details(6)
			if effect_value > 0 then
				cool_down_time = cool_down_time - effect_value
				if cool_down_time < 0 then
					cool_down_time = 0
				end
				skill_info:set_cool_down_time(cool_down_time)
				-- self:features_effect_notify_client(6)
			end
		end
	else
		effect_value,feature_rate = self:get_dw_jinjie_effect_details(18)
		if effect_value > 0 then
			local accuracy_rate_up = skill_info:get_accuracy_rate_up()
			effect_value = effect_value / feature_rate + accuracy_rate_up
			skill_info:set_accuracy_rate_up(effect_value)
			-- self:features_effect_notify_client(18)
		end
		effect_value,feature_rate = self:get_dw_jinjie_effect_details(17)
		if effect_value > 0 then
			local critical_rate = skill_info:get_mind_attack_rate_up()
			effect_value = effect_value / feature_rate / 100 + critical_rate
			skill_info:set_mind_attack_rate_up(effect_value)
			-- self:features_effect_notify_client(17)
		end
	end
    self:impact_refix_skill(skill_info)
    local r, err = pcall(self.talent_refix_skill_info, self, skill_info)
    if not r then
        skynet.loge("talent_refix_skill_info error =", err)
    end
    self.skill_info = skill_info
end

function character:talent_refix_skill_info()

end

function character:impact_refix_skill(skill_info)
    local list = self:get_impact_list()
    for _, imp in ipairs(list) do
        local logic = impactenginer:get_logic(imp)
        if logic then
            logic:refix_skill(imp, self, skill_info)
        end
    end
end

function character:on_use_skill_success_fully(skill_info)
    require('cys_dual_souls').combat(self)
    require("cy_four_combat.hooks").on_use_skill_successfully(self, skill_info)
    self:impact_on_use_skill_success_fully(skill_info)
    local r, err = pcall(self.talent_on_use_skill_success_fully, self, skill_info)
    if not r then
        skynet.loge("talent_on_use_skill_success_fully error =", err)
    end
end

function character:is_enemy(other)
    local other_repuation = other:get_reputation()
    local self_repuation = self:get_reputation()
    --print("character:is_enemy other_repuation =", other_repuation, ";self_repuation =", self_repuation)
    local both_monster = self:get_obj_type() == "monster" and other:get_obj_type() == "monster"
    return  other_repuation ~= self_repuation and not both_monster
end

function character:is_party(other)

end

function character:is_friend(other)
    if other == nil then
        return false
    end
    if self == other then
        return true
    end
    if self:is_teammate(other) then
        if (not self:is_enemy(other))  then
            return true
        end
    else
        if (not self:is_enemy(other))  then
            return true
        end
    end
    if other:get_obj_type() == "pet" then
        local owner = other:get_owner()
        if owner then
            return self:is_friend(owner)
        end
    end
    return false
end

function character:is_teammate()
    return false
end

function character:is_active_obj()
    return true
end

function character:get_character_logic()
    return self.character_logic
end


function character:set_character_logic(logic)
    self.character_logic = logic
    self.character_logic_stopped = logic == define.ENUM_CHARACTER_LOGIC.CHARACTER_LOGIC_IDLE
end

function character:is_character_logic_use_skill()
    return self.character_logic == define.ENUM_CHARACTER_LOGIC.CHARACTER_LOGIC_USE_SKILL
end

function character:stop_character_logic(...)
    self.character_logic_stopped = true
    self:on_stop_character_logic(...)
    self:set_character_logic(define.ENUM_CHARACTER_LOGIC.CHARACTER_LOGIC_IDLE)
end

function character:on_stop_character_logic(abortive)
    local logic = self.character_logic
    --print("on_stop_character_logic obj_id =", self:get_obj_id(), ";logic =", logic, ";abortive =", abortive)
    if logic == define.ENUM_CHARACTER_LOGIC.CHARACTER_LOGIC_MOVE then
        if abortive then
            local msg = packet_def.GCArrive.new()
            msg.m_objID = self:get_obj_id()
            msg.handleid = self:get_logic_count()
            msg.world_pos = self:get_world_pos()
            local sendself = not self.defer_self_arrive_once
            self.defer_self_arrive_once = nil
            self:get_scene():broadcast(self, msg, sendself)
        end
        self.move = nil
    elseif logic == define.ENUM_CHARACTER_LOGIC.CHARACTER_LOGIC_USE_SKILL then
        if abortive then
            local msg = packet_def.GCCharStopAction.new()
            msg.m_objID = self:get_obj_id()
            msg.logic_count = self:get_logic_count()
            local params = self:get_action_params()
            msg.stop_time = params:get_continuance()
            self:get_scene():broadcast(self, msg, true)
        end
    end
end

function character:can_view_me(obj)
    if obj == self then
        return true
    end
    local view = self.view
    return view[obj] ~= nil
end

function character:get_action_time()
    return self.action_time
end

function character:set_action_time(action_time)
    self.action_time = action_time
end

function character:update_action_time(delta_time)
    self.action_time = self.action_time - delta_time
    self.action_time = self.action_time < 0 and 0 or self.action_time
end

function character:update_impact(delta_time)
    local list = self:get_impact_list()
    for _, imp in ipairs(list) do
        local logic = impactenginer:get_logic(imp)
        if logic then
            if (self:is_unbreakable() and imp:get_stand_flag() == define.ENUM_BEHAVIOR_TYPE.BEHAVIOR_TYPE_HOSTILITY) then
                --print("character:update_impact 1")
            else
                --print("character:update_impact 2")
                logic:heart_beat(imp, self, delta_time)
            end
        end
    end
end

function character:get_hit()
    return self:get_attrib("attrib_hit")
end

function character:get_miss()
    return self:get_attrib("attrib_miss")
end

function character:get_specific_obj_in_same_scene_by_id(id)
    return self:get_scene():get_obj_by_id(id)
end

function character:get_action_params()
    return self.action_params
end

function character:get_attack_cool_down_time()
    return self.db:get_attrib("attack_cool_down_time")
end

function character:set_action_logic(logic)
    self.action_logic = logic
end

function character:get_action_logic()
    return self.action_logic
end

function character:set_logic_count(logic_count)
    self.logic_count = logic_count
end

function character:add_logic_count()
    self.logic_count = self.logic_count + 1
    self.logic_count = self.logic_count > define.INT32_MAX and 1 or self.logic_count
end

function character:set_cool_down(id, cool_down_time)
    id = tostring(id)
    self.cool_down_times[id] = cool_down_time
end

function character:get_cool_down(id)
    id = tostring(id)
   return self.cool_down_times[id] or 0
end

function character:get_cool_downs()
    return self.cool_down_times
end

function character:set_dir(dir)
    self.db:set_db_attrib({ dir = dir})
end

function character:get_dir()
    return self.db:get_attrib("dir")
end

function character:on_action_start()
    self:impact_on_action_start()
end

function character:on_critical_hit_target(skill_id, obj_tar)
    self:impact_on_critical_hit_target(skill_id, obj_tar)
    local r, err = pcall(self.talent_on_critical_hit_target, self, skill_id, obj_tar)
    if not r then
        skynet.loge("talent_on_critical_hit_target error =", err)
    end
end

function character:talent_on_critical_hit_target(skill_id, obj_tar)
end

function character:on_be_critical_hit(skill_id, sender)
    self:impact_on_be_critical_hit(skill_id, sender)
    self:talent_on_be_critical_hit(skill_id, sender)
end

function character:talent_on_be_critical_hit(skill_id, sender)

end

function character:get_auto_repeat_cool_down()
    return self.auto_repeat_cool_down
end

function character:set_auto_repeat_cool_down(cooldown)
    self.auto_repeat_cool_down = cooldown
    --print("character:set_auto_repeat_cool_down cooldown =", self.auto_repeat_cool_down)
end

function character:get_attack_physics()
    return self:get_attrib("attrib_att_physics") or 0
end

function character:get_attack_magic()
    return self:get_attrib("attrib_att_magic") or 0
end

function character:get_attack_cold()
    return (self:get_attrib("att_cold") or 0) + require("cy_four_combat.guigu_auras").bonus(self,4260,1)
end

function character:get_attack_fire()
    return (self:get_attrib("att_fire") or 0) + require("cy_four_combat.guigu_auras").bonus(self,4260,2)
end

function character:get_attack_light()
    return (self:get_attrib("att_light") or 0) + require("cy_four_combat.guigu_auras").bonus(self,4260,3)
end

function character:get_attack_posion()
    return (self:get_attrib("att_poison") or 0) + require("cy_four_combat.guigu_auras").bonus(self,4260,4)
end

function character:get_defence_physics()
    return self:get_attrib("attrib_def_physics") or 0
end

function character:get_defence_magic()
    return self:get_attrib("attrib_def_magic") or 0
end

function character:get_defence_cold()
    return self:get_attrib("def_cold") or 0
end

function character:get_defence_fire()
    return self:get_attrib("def_fire") or 0
end

function character:get_defence_light()
    return self:get_attrib("def_light") or 0
end

function character:get_defence_posion()
    return self:get_attrib("def_poison") or 0
end

function character:get_reduce_def_cold()
    return self:get_attrib("reduce_def_cold") or 0
end

function character:get_reduce_def_fire()
    return self:get_attrib("reduce_def_fire") or 0
end

function character:get_reduce_def_light()
    return self:get_attrib("reduce_def_light") or 0
end

function character:get_reduce_def_posion()
    return self:get_attrib("reduce_def_poison") or 0
end

function character:get_reduce_def_cold_low_limit()
    return (self:get_attrib("reduce_def_cold_low_limit") or 0) + require("cy_four_combat.guigu_auras").bonus(self,4251,1)
end

function character:get_reduce_def_fire_low_limit()
    return (self:get_attrib("reduce_def_fire_low_limit") or 0) + require("cy_four_combat.guigu_auras").bonus(self,4251,2)
end

function character:get_reduce_def_light_low_limit()
    return (self:get_attrib("reduce_def_light_low_limit") or 0) + require("cy_four_combat.guigu_auras").bonus(self,4251,3)
end

function character:get_reduce_def_posion_low_limit()
    return (self:get_attrib("reduce_def_poison_low_limit") or 0) + require("cy_four_combat.guigu_auras").bonus(self,4251,4)
end

function character:get_logic_count()
    return self.logic_count
end

function character:get_level()
    return self:get_attrib("level")
end

function character:get_impact_list()
    return self.impact_list
end

function character:is_unbreakable()
    return self:get_attrib("unbreakable") == 1
end

function character:get_mind_attack()
    return self:get_attrib("mind_attack")
end

function character:get_mind_defend()
    return self:get_attrib("mind_defend")
end

function character:replace_mutually_exclusive_impact(imp)
    local list = self:get_impact_list()
    for _, current in ipairs(list) do
        if (imp:get_mutex_id() == current:get_mutex_id() and current:get_mutex_id() ~= define.INVAILD_ID) or current:get_data_index() == imp:get_data_index() then
            if impactenginer:can_impactA_replace_impactB(imp, current) then
                self:replace_impact(current, imp)
                return true
            else
                local msg = packet_def.GCCharSkill_Missed.new()
                msg.reciver = self:get_obj_id()
                msg.sender = imp:get_caster_obj_id()
                msg.flag = define.MissFlag_T.FLAG_IMMU
                msg.skill_id = imp:get_skill_id()
                msg.sender_logic_count = imp:get_caster_logic_count()
                return true
            end
        end
    end
end

function character:replace_impact(current, imp)
    self:add_impact_sns_seed()
    imp:set_sn(self.impact_sn_seed)
    self:on_impact_fade_out(current)
    local list = self:get_impact_list()
    for i, exist in ipairs(list) do
        if exist:get_sn() == current:get_sn() then
            list[i] = imp
            break
        end
    end
    self:on_impact_activated(imp)
end

function character:register_impact(imp)
    local scene = self:get_scene()
    local logic = scene:get_impact_enginer():get_logic(imp)
    if not logic then
        return true
    end
    if self:is_unbreakable() and define.ENUM_BEHAVIOR_TYPE.BEHAVIOR_TYPE_HOSTILITY == imp:get_stand_flag() then
        local is_shihuibao_impact = imp:get_impact_id() == 219
        -- local is_only_transfer_protect = self:only_tarnsfer_protect()
        local is_only_transfer_protect = true
        if is_shihuibao_impact and is_only_transfer_protect then

        else
            return true
        end
    end
    if self:is_stealth_immu(imp) and define.ENUM_BEHAVIOR_TYPE.BEHAVIOR_TYPE_AMITY ~= imp:get_stand_flag()  then
        return true
    end
    local is = imp:get_is_over_timed()
    if is then
        if not self:replace_mutually_exclusive_impact(imp) then
            self:add_new_impact(imp)
        end
    else
        self:on_impact_activated(imp)
    end
end

function character:dispel_hostility_impact()
    local list = self:get_impact_list()
    for i = #list, 1, -1 do
        local imp = list[i]
        if imp:is_can_be_dispeled() and imp:get_stand_flag() == define.ENUM_BEHAVIOR_TYPE.BEHAVIOR_TYPE_HOSTILITY then
            self:on_impact_fade_out(imp)
            self:remove_impact(imp)
        end
    end
end

function character:add_new_impact(imp)
    local list = self:get_impact_list()
    if #list < define.MAX_IMPACT_NUM then
        self:add_impact_sns_seed()
        imp:set_sn(self.impact_sn_seed)
        table.insert(list, imp)
        self:on_impact_activated(imp)
    end
end

function character:remove_impact(imp)
    local list = self:get_impact_list()
	local imp_sn = imp:get_sn()
	for i, current in ipairs(list) do
		if current:get_sn() == imp_sn then
			local logic = impactenginer:get_logic(imp)
			if logic then
				logic:mark_modified_attr_dirty(imp, self)
			end
			table.remove(list, i)
			break
		end
	end
	self:refresh_attrib_after_remove_impact()
end

-- transform-model 17/09: gửi lại thuộc tính SAU KHI impact đã rời danh sách.
-- Mọi đường gỡ buff đều là `on_impact_fade_out(imp)` rồi mới `remove_impact(imp)`, mà `on_impact_fade_out`
-- gọi `send_refresh_attrib` lúc impact CÒN trong danh sách ⇒ các thuộc tính kiểu `replace`
-- (model_id 变身, ride_model 骑乘, can_move, stealth_level…) vẫn ra giá trị của lúc còn buff và client
-- giữ nguyên hình biến thân cho tới lần refresh tình cờ sau đó. Chỉ gửi khi thật sự còn ô refix bẩn
-- (cờ vừa được `mark_modified_attr_dirty` đặt) nên không thêm gói nào cho các impact không sửa thuộc tính.
function character:refresh_attrib_after_remove_impact()
	if self:get_obj_type() ~= "human" then
		return
	end
	local db = self.db
	if db and db.has_attrib_refix_dirty and db:has_attrib_refix_dirty() then
		self:send_refresh_attrib()
	end
end

function character:set_impact_sn_seed(count)
    self.impact_sn_seed = count
end

function character:add_impact_sns_seed()
    self.impact_sn_seed = self.impact_sn_seed + 1
end

function character:on_impact_get_combat_result()

end

function character:on_impact_activated(imp)
    local scene = self:get_scene()
    local logic = scene:get_impact_enginer():get_logic(imp)
    if not logic then
        return true
    end
    if imp:get_is_over_timed() then
        logic:mark_modified_attr_dirty(imp, self)
    end
    logic:on_active(imp, self)
    -- print("character:on_impact_activated imp =", imp:get_data_index(), ";obj_id =", self:get_obj_id())
    if imp:get_is_over_timed() then
        if imp:get_impact_id() ~= define.INVAILD_ID then
            local msg = packet_def.GCDetailBuff.new()
            msg.reciver = self:get_obj_id()
            msg.sender = imp:get_caster_obj_id()
            msg.buffer_id = imp:get_impact_id()
            msg.skill_id = imp:get_skill_id()
            msg.logic_count = imp:get_caster_logic_count()
            msg.continuance = imp:get_continuance()
            msg.enable = 1
            msg.sn = imp:get_sn()
            scene:send2client(self, msg)
        end
        local msg = packet_def.GCCharBuff.new()
        msg.sender = imp:get_caster_obj_id()
        msg.buffer_id = imp:get_impact_id()
        msg.enable = 1
        msg.reciver = self:get_obj_id()
        msg.sn = imp:get_sn()
        msg.logic_count = imp:get_caster_logic_count()
        scene:broadcast(self, msg, true)
    else
        local msg = packet_def.GCCharDirectImpact.new()
        msg.reciver = self:get_obj_id()
        msg.sender = imp:get_caster_obj_id()
        msg.skill_id = imp:get_skill_id()
        msg.impact_id = imp:get_impact_id()
        msg.logic_count = define.INVAILD_ID
        local sender = self:get_scene():get_obj_by_id(msg.sender)
        if sender then
            msg.logic_count = sender:get_logic_count()
        end
        if msg.impact_id ~= define.INVAILD_ID then
            scene:broadcast(self, msg, true)
        end
    end
end

function character:unregister_impact_by_sn(sn)
    local impact_list = self:get_impact_list()
    for i, imp in ipairs(impact_list) do
        if imp:get_sn() == sn then
            if imp:is_can_be_cancled() then
                self:on_impact_fade_out(imp)
                self:remove_impact(imp)
            end
            break
        end
    end
end

function character:unregister_impact_by_skill_id_and_impact_id(skill_id, impact_id)
    local impact_list = self:get_impact_list()
    for i, imp in ipairs(impact_list) do
        if imp:get_skill_id() == skill_id and imp:get_impact_id() == impact_id then
            if imp:is_can_be_cancled() then
                self:on_impact_fade_out(imp)
                self:remove_impact(imp)
            end
        end
    end
end

function character:on_impact_fade_out(imp)
    if imp:get_is_over_timed() then
        local scene = self:get_scene()
        if self:get_obj_type() == "human" then
            local msg = packet_def.GCDetailBuff.new()
            msg.enable = 0
            msg.sn = imp:get_sn() or 0
            scene:send2client(self, msg)
        end
        if imp:get_impact_id() ~= define.INVAILD_ID then
            local msg = packet_def.GCCharBuff.new()
            msg.sender = imp:get_caster_obj_id()
            msg.buffer_id = imp:get_impact_id()
            msg.enable = 0
            msg.reciver = self:get_obj_id()
            msg.sn = imp:get_sn() or 0
            msg.logic_count = imp:get_caster_logic_count()
            scene:broadcast(self, msg, true)
        end
        local logic = impactenginer:get_logic(imp)
        if logic then
            logic:on_fade_out(imp, self)
        end
    end
    self:imp_on_impact_fade_out(imp)
    self:talent_on_impact_fade_out(imp)
    if self:get_obj_type() == "human" then
        self:send_refresh_attrib()
    end
end

function character:imp_on_impact_fade_out(imp)

end

function character:talent_on_impact_fade_out(imp)

end

function character:on_be_skill(sender, skill_id, behaviortype)
    if define.ENUM_BEHAVIOR_TYPE.BEHAVIOR_TYPE_HOSTILITY == behaviortype then
        if sender:get_obj_type() == "human" and sender:is_enemy(self) then
            sender:set_cur_target_id(self:get_obj_id())
            local template = skillenginer:get_skill_template(skill_id)
            if template.enable_or_disable_pet_attack == 1 then
                local pet = sender:get_pet()
                if pet then
                    pet:get_ai():baby_to_idle()
                end
            else
                sender:baby_to_attack()
            end
        end
    end
    self.ai:on_be_skill(sender, skill_id, behaviortype)
    local r, err = pcall(self.impact_on_be_skill, self, sender, skill_id, behaviortype)
    if not r then
        skynet.loge("impact_on_be_skill error =", err)
    end
    local r2, err2 = pcall(self.talent_on_be_skill, self, sender, skill_id, behaviortype)
    if not r2 then
        skynet.loge("talent_on_be_skill error =", err2)
    end
end

function character:talent_on_be_skill(sender, skill_id, behaviortype)
end

function character:on_new_obj_enter_view(obj)
    --print("on_new_obj_enter_view my_id =", self:get_obj_id(), ";obj_id =", obj:get_obj_id())
    local scene = self:get_scene()
    scene:on_new_obj_enter_view(self, obj)
end

function character:on_obj_leave_view(obj)
    local ret = packet_def.GCDelObject.new()
    ret.m_objID = obj:get_obj_id()
    ret.m_idScene = self.scene:get_id()
    self.scene:send2client(self, ret)
    character.super.on_obj_leave_view(self, obj)
end

function character:on_be_hit(sender, skill)
    require('cys_dual_souls').combat(self)
    --skynet.error("[DEBUG:on_be_hit] 被攻击回调触发, objid=", self:get_obj_id())
    local r, err = pcall(self.talent_on_be_hit, self, sender, skill)
    if not r then
        skynet.loge("talent_on_be_hit error =", err)
    end
    --skynet.error("[DEBUG:on_be_hit] 准备调用 impact_on_be_hit")
    local r2, err2 = pcall(self.impact_on_be_hit, self, sender, skill)
    if not r2 then
        skynet.loge("impact_on_be_hit error =", err2)
    end
end

function character:talent_on_be_hit()

end

function character:impact_on_use_skill_success_fully(skill_info)
    local impacts = self:get_impact_list()
    for i = #impacts, 1, -1 do
        local impact = impacts[i]
        local logic = impactenginer:get_logic(impact)
        logic:on_use_skill_success_fully(impact)
    end
end

function character:talent_on_use_skill_success_fully(skill_info)
end

function character:impact_refix_skill_launch_rate(args)
    local impacts = self:get_impact_list()
    for i = #impacts, 1, -1 do
        local impact = impacts[i]
        local logic = impactenginer:get_logic(impact)
        logic:refix_skill_launch_rate(impact, args)
    end
end

function character:on_hit_target(reciver, skill)
    self:impact_on_hit_target(reciver, skill)
end

function character:on_skill_miss(sender, skill_id)

end

function character:on_skill_miss_target(reciver, skill_id)

end

function character:is_stealth_immu(imp)
    local caster_obj_id = imp:get_caster_obj_id()
    local caster_obj = self:get_scene():get_obj_by_id(caster_obj_id)
    if not caster_obj then
        return false
    end
    if caster_obj:is_can_view(self) then
        return false
    end
    local skill_id = imp:get_skill_id()
    if skill_id == nil then
        return false
    end
    local template = skillenginer:get_skill_template(skill_id)
    if template == nil then
        return false
    end
    local targeting_logic = template.targeting_logic
    local is_single_skill = targeting_logic == define.ENUM_TARGET_LOGIC.TARGET_SPECIFIC_UNIT
    return is_single_skill
end

function character:impact_on_damages(damages, caster_obj_id, is_critical, skill_id, imp)
    local impacts = self:get_impact_list()
    skill_id = skill_id or define.INVAILD_ID
    for i = #impacts, 1, -1 do
        local impact = impacts[i]
        local logic = impactenginer:get_logic(impact)
        if impact:is_fade_out_when_unit_on_damage() then
            self:on_impact_fade_out(impact)
            self:remove_impact(impact)
        else
            logic:on_damages(impact, self, damages, caster_obj_id, is_critical, skill_id, imp)
        end
    end
end

function character:impact_on_move()
    local impacts = self:get_impact_list()
    for i = #impacts, 1, -1 do
        local impact = impacts[i]
        if impact:is_fade_out_when_unit_on_move() then
            self:on_impact_fade_out(impact)
            self:remove_impact(impact)
        end
    end
end

function character:impact_on_action_start()
    local impacts = self:get_impact_list()
    for i = #impacts, 1, -1 do
        local impact = impacts[i]
        if impact:is_fade_out_when_unit_on_action_start() then
            self:on_impact_fade_out(impact)
            self:remove_impact(impact)
        end
    end
end

function character:impact_on_offline()
    local impacts = self:get_impact_list()
    for i = #impacts, 1, -1 do
        local impact = impacts[i]
        if impact:is_fade_out_when_unit_offline() then
            self:on_impact_fade_out(impact)
            self:remove_impact(impact)
        end
    end
end

function character:impact_on_die()
    local impacts = self:get_impact_list()
    for i = #impacts, 1, -1 do
        local impact = impacts[i]
        local logic = impactenginer:get_logic(impact)
        if logic then
            logic:on_die(impact, self)
        end
    end
end

function character:impact_on_logic_move(dist)
    local impacts = self:get_impact_list()
    for i = #impacts, 1, -1 do
        local impact = impacts[i]
        local logic = impactenginer:get_logic(impact)
        if logic then
            logic:on_logic_move(impact, self, dist)
        end
    end
end

function character:impact_on_critical_hit_target(skill_id, obj_tar)
    local impacts = self:get_impact_list()
    for i = #impacts, 1, -1 do
        local impact = impacts[i]
        local logic = impactenginer:get_logic(impact)
        if logic then
            logic:on_critical_hit_target(impact, self, obj_tar, skill_id)
        end
    end
end

function character:impact_on_be_critical_hit(skill_id, sender)
    local impacts = self:get_impact_list()
    for i = #impacts, 1, -1 do
        local impact = impacts[i]
        local logic = impactenginer:get_logic(impact)
        if logic then
            logic:on_be_critical_hit(impact, self, sender, skill_id)
        end
    end
end

function character:impact_on_hit_target(reciver, skill)
    local impacts = self:get_impact_list()
    for i = #impacts, 1, -1 do
        local impact = impacts[i]
        local logic = impactenginer:get_logic(impact)
        if logic then
            logic:on_hit_target(impact, self, reciver, skill)
        end
    end
end

function character:impact_on_be_hit(sender, skill)
    local impacts = self:get_impact_list()
    --skynet.error("[DEBUG:impact_on_be_hit] 进入, impact数量=", #impacts)
    for i = #impacts, 1, -1 do
        local imp = impacts[i]
        --skynet.error("[DEBUG:impact_on_be_hit] 检查impact data_index=", imp:get_data_index(), " logic_id=", imp:get_logic_id())
        local logic = impactenginer:get_logic(imp)
        if logic then
            --skynet.error("[DEBUG:impact_on_be_hit] 调用 logic:on_be_hit, logic_id=", imp:get_logic_id())
            logic:on_be_hit(imp, self, sender, skill)
        end
    end
end

function character:impact_on_be_skill(sender, skill_id, behaviortype)
    local impacts = self:get_impact_list()
    for i = #impacts, 1, -1 do
        local imp = impacts[i]
        local logic = impactenginer:get_logic(imp)
        if logic then
            logic:on_be_skill(imp, self, sender, skill_id, behaviortype)
        end
    end
end

function character:impact_on_damage_target(damages, target, skill_id, imp)
    local impacts = self:get_impact_list()
    for i = #impacts, 1, -1 do
        local impact = impacts[i]
        local logic = impactenginer:get_logic(impact)
        if logic then
            logic:on_damage_target(impact, self, target, damages, skill_id, imp)
        end
    end
end
function character:impact_on_die_check()
	local value
	local is_die = false
    local impacts = self:get_impact_list()
    for i = #impacts, 1, -1 do
        local imp = impacts[i]
		value = imp:get_logic_id()
		if value == 519 or value == 503 then
			local logic = impactenginer:get_logic(imp)
			if logic then
				if logic:on_die_check(imp,self) then
					is_die = true
				end
			end
		end
    end
	return is_die
end

function character:on_damage_target(target, damages, skill_id, imp)
    self:impact_on_damage_target(damages, target, skill_id, imp)
    if self:get_obj_type()=='human' then require('cy_lingpai_combat').proc(self,target,skill_id) end
end

function character:talent_on_damage_target()

end

function character:impact_on_be_heal(skill_id, sender, health)
    local impacts = self:get_impact_list()
    for i = #impacts, 1, -1 do
        local impact = impacts[i]
        local logic = impactenginer:get_logic(impact)
        if logic then
            logic:on_be_heal(impact, self, sender, health, skill_id)
        end
    end
end

function character:on_health_increment(hp_modifys)
    local impacts = self:get_impact_list()
    for i = #impacts, 1, -1 do
        local impact = impacts[i]
        local logic = impactenginer:get_logic(impact)
        if logic then
            logic:on_health_increment(impact,hp_modifys)
        end
    end
end

function character:on_be_heal(skill_id, sender, health)
    self:impact_on_be_heal(skill_id, sender, health)
end
function character:health_increment(hp_modify, sender, is_critical_hit, imp, param_skill)
	if self:is_die() then
		return
	end
	if hp_modify ~= 0 and self:is_active_obj() then
		local selfId = self:get_obj_id()
		local targetId = sender and sender:get_obj_id() or define.INVAILD_ID
		local logic_count = 0
		local skill_id = define.INVAILD_ID
		if imp then
			skill_id = imp:get_skill_id() or define.INVAILD_ID
			logic_count = imp:get_caster_logic_count()
		end
		local cc_skill = skill_id
		if cc_skill == define.INVAILD_ID then
			cc_skill = param_skill or define.INVAILD_ID
		end
		local max_hp = self:get_attrib("hp_max")
		local old_hp = self:get_attrib("hp")
		if hp_modify > 0 then
			local health = { hp_modify = hp_modify }
			self:impact_on_be_heal(skill_id, sender, health)
			-- self:on_be_heal(skill_id, sender, health)
			hp_modify = health.hp_modify
			if hp_modify > 0 then
				local check_restore_hp = false
				if self:get_obj_type() == "human" then
					local restore_hp_rate,restore_hp_value,restore_hp_reset_time = self:get_limit_restore_hp()
					if restore_hp_reset_time > 0 and restore_hp_rate > 0 then
						check_restore_hp = true
						local max_restore_hp = max_hp * restore_hp_rate / 100
						if max_restore_hp < hp_modify + restore_hp_value then
							hp_modify = max_restore_hp - restore_hp_value
							if hp_modify <= 0 then
								-- local msg = string.format("本场景%d秒内至多可恢复%d%%血量。",restore_hp_reset_time,restore_hp_rate)
								-- self:notify_tips("治疗受限")
								return
							end
						end
					end
				end
				hp_modify = math.ceil(hp_modify)
				local back_hp_modify = hp_modify
				local now_hp = old_hp + hp_modify
				if now_hp > max_hp then
					now_hp = max_hp
					hp_modify = max_hp - old_hp
				end
				if hp_modify > 0 then
					local msg = packet_def.GCDetailHealsAndDamages.new()
					msg.reciver = selfId
					msg.sender = targetId
					msg.logic_count = logic_count
					msg.dirty_flags = msg.dirty_flags | 1
					msg.is_critical_hit = is_critical_hit and 1 or 0
					msg.hp_modification = hp_modify
					self:broadcast_heal_and_damage_msg(sender, msg)
					self:set_hp(now_hp)
					if old_hp <= 0 and now_hp > 0 then
						self:on_relive(sender)
					end
					if check_restore_hp then
						self:set_restore_hp_value(hp_modify)
					end
				end
				if now_hp == max_hp then
					return back_hp_modify - (now_hp - old_hp)
				end
			end
		else
			hp_modify = -1 * hp_modify
			local damages = {hp_damage = hp_modify}
			local chuanci = 0
			if cc_skill ~= -1 then
				chuanci = self:get_chuanci_damage(sender,is_critical_hit)
				if chuanci > 0 then
					damages.chuanci = chuanci
				end
			end
			
			for _,key in ipairs(DAMAGE_TYPE_RATE) do
				damages[key] = 100
			end
			for _,key in ipairs(DAMAGE_TYPE_POINT) do
				damages[key] = 0
			end
			for _,key in ipairs(DAMAGE_TYPE_BACK) do
				damages[key] = {}
			end
			for _,key in pairs(DAMAGE_TYPE) do
				damages[key] = 0
			end
			damages[DAMAGE_TYPE.IDX_DAMAGE_DIRECHT] = hp_modify
			self:on_damages(damages, targetId, is_critical_hit, skill_id, imp)
		end
	end
end

function character:health_increment_damages(hp_modify,recover_hp_count,sender,imp,skill_id)
    if self:is_active_obj() and hp_modify ~= 0 then
		local selfId = self:get_obj_id()
		local targetId = sender and sender:get_obj_id() or define.INVAILD_ID
		local logic_count = 0
		if imp then
			logic_count = imp:get_caster_logic_count()
		end
		local max_hp = self:get_attrib("hp_max")
		local old_hp = self:get_attrib("hp")
		local value
		if hp_modify > 0 then
			local check_restore_hp = false
			if self:get_obj_type() == "human" then
				local restore_hp_rate,restore_hp_value,restore_hp_reset_time = self:get_limit_restore_hp()
				if restore_hp_reset_time > 0 and restore_hp_rate > 0 then
					check_restore_hp = true
					local max_restore_hp = max_hp * restore_hp_rate / 100
					if max_restore_hp < hp_modify + restore_hp_value then
						hp_modify = max_restore_hp - restore_hp_value
						if hp_modify <= 0 then
							-- local msg = string.format("本场景%d秒内至多可恢复%d%%血量。",restore_hp_reset_time,restore_hp_rate)
							-- self:notify_tips("治疗受限")
							return
						end
					end
				end
			end
			hp_modify = math.ceil(hp_modify)
			local sub_hp_modify = hp_modify
			for i,j in ipairs(recover_hp_count) do
				value = math.ceil(j)
				if value > 0 then
					local msg = packet_def.GCDetailHealsAndDamages.new()
					msg.reciver = selfId
					msg.sender = targetId
					msg.logic_count = logic_count
					msg.dirty_flags = msg.dirty_flags | 1
					msg.is_critical_hit = 0
					sub_hp_modify = sub_hp_modify - value
					if sub_hp_modify <= 0 then
						value = value + sub_hp_modify
						msg.hp_modification = value
						self:broadcast_heal_and_damage_msg(sender, msg)
						break
					else
						msg.hp_modification = value
						self:broadcast_heal_and_damage_msg(sender, msg)
					end
				end
			end
			local now_hp = old_hp + hp_modify
			-- now_hp = math.ceil(now_hp)
			if now_hp > max_hp then
				now_hp = max_hp
				hp_modify = max_hp - old_hp
			end
			self:set_hp(now_hp)
			if old_hp <= 0 and now_hp > 0 then
				self:on_relive(sender)
			end
			if check_restore_hp then
				self:set_restore_hp_value(hp_modify)
			end
		else
			local is_die = false
			hp_modify = math.ceil(hp_modify)
			local now_hp = old_hp + hp_modify
			now_hp = now_hp < 0 and 0 or now_hp
			-- now_hp = math.ceil(now_hp)
			if old_hp > 0 and now_hp <= 0 then
				if self:impact_on_die_check() then
					if old_hp == 1 then
						return
					end
					now_hp = 1
				else
					is_die = true
				end
			end
			local lock_hp = 0 - old_hp + 1
			hp_modify = hp_modify < lock_hp and lock_hp or hp_modify
			if self:get_obj_type() == "monster" then
				self:back_monster_damage(hp_modify,sender)
			end
			
			local sub_hp_modify = hp_modify
			for i,j in ipairs(recover_hp_count) do
				if sub_hp_modify + j < 0 then
					value = -1 * j
					sub_hp_modify = sub_hp_modify + value
				else
					value = sub_hp_modify
					sub_hp_modify = 0
				end
				local msg = packet_def.GCDetailHealsAndDamages.new()
				msg.reciver = selfId
				msg.sender = targetId
				msg.logic_count = logic_count
				msg.hp_modification = math.ceil(value)
				msg.is_critical_hit = 0
				msg.dirty_flags = msg.dirty_flags | 1
				self:broadcast_heal_and_damage_msg(sender, msg)
				if sub_hp_modify <= 0 then
					break
				end
			end
			if sender and sender:get_obj_type() == "human" then
				local actscene = sender:get_mission_data_by_script_id(611)
				if actscene > 0 and actscene == sender:get_mission_data_by_script_id(612)
				and selfId + 1 == sender:get_mission_data_by_script_id(613) then
					local damage_rate = self:get_obj_type() == "human" and 1 or 5
					local addamage = math.abs(hp_modify * damage_rate)
					sender:set_mission_data_by_script_id(614,sender:get_mission_data_by_script_id(614) + addamage)
				end
			end
			self:set_hp(now_hp)
			if is_die then
				if targetId ~= define.INVAILD_ID then
					self:on_die(targetId)
				else
					self:on_die(selfId)
				end
				self:on_die(targetId)
				if sender and sender:get_obj_type() == "human" then
					if skill_id == 811 then
						self:soul_separated_kill_blindness(sender)
					elseif skill_id == 801 then -- [FIX] 901 向死而生
						self:toward_death_kill_heal(sender)
					elseif skill_id == 796 then
						local talent_config = configenginer:get_config("sect_desc")
						local talent = sender:get_talent()
						local logic,t_config,level,study_talent_id
						for i = 1, #talent.study do
							study_talent_id = talent.study[i].id
							if study_talent_id == 641 
							or study_talent_id == 642
							or study_talent_id == 704 then
								local logic = talentenginer:get_logic_id(study_talent_id)
								if logic then
									t_config = talent_config[study_talent_id]
									if t_config then
										level = talent.study[i].level
										level = level == 0 and 1 or level
										if sender then
											logic:on_die(t_config, level, sender, self, skill_id)
										end
									end
								end
							end
						end
					else
						local talent_config = configenginer:get_config("sect_desc")
						local talent = sender:get_talent()
						local logic,t_config,level,study_talent_id
						for i = 1, #talent.study do
							study_talent_id = talent.study[i].id
							if study_talent_id == 704 then
								local logic = talentenginer:get_logic_id(study_talent_id)
								if logic then
									t_config = talent_config[study_talent_id]
									if t_config then
										level = talent.study[i].level
										level = level == 0 and 1 or level
										if sender then
											logic:on_die(t_config, level, sender, self, skill_id)
										end
									end
								end
							end
						end
					end
				end
			end
		end
	end
end

function character:on_damages(damages, caster_obj_id, is_critical, skill_id, imp)
	if damages.damage_rate and self:is_active_obj() then
		if self:is_die() then
			return
		end
		local scene = self:get_scene()
		
		local damage_point_refix = 0
		local self_ismonster = false
		local self_ishuman = 5
		local mytype = self:get_obj_type()
		if mytype == "human" then
			self_ishuman = 1
			damage_point_refix = damage_point_refix - self:item_value(define.ITEM_ATTRIBUTE.IATTRIBUTE_POINT_REDUCE_DAMAGE)
			local _,special_rate = self:damage_rate()
			if special_rate > 0 then
				for _,key in ipairs(DAMAGE_TYPE_RATE) do
					damages[key] = damages[key] - special_rate
				end
			end
		elseif mytype == "monster" then
			self_ismonster = true
			if self:get_active_time() > 0 then
				return
			end
		end
		
		local selfId = self:get_obj_id()
		local targetId = caster_obj_id
		local logic_count = 0
		if imp then
			logic_count = imp:get_caster_logic_count()
		end
		local sender = scene:get_obj_by_id(caster_obj_id)
		if not sender then
			if imp then
				targetId = imp:get_caster_obj_id() or -1
				sender = scene:get_obj_by_id(targetId)
			else
				targetId = -1
			end
		end
		if damages.mp_damage and damages.mp_damage > 0 then
			local mp_damage = damages.mp_damage * -1
			self:mana_increment(mp_damage, sender, is_critical, imp)
		end
		if damages.rage_damage and damages.rage_damage > 0 then
			local rage_damage = damages.rage_damage
			self:rage_increment(rage_damage, sender, is_critical, imp)
		end
		local imm_dmg_rate = 100
		-- if damages.flag_immu then
			-- self:show_skill_missed(selfId,targetId,skill_id,self:get_logic_count(),define.MISS_FLAG.FLAG_IMMU)
			-- return
		-- elseif damages.imm_dmg_rate then
		if damages.imm_dmg_rate then
			imm_dmg_rate = imm_dmg_rate - damages.imm_dmg_rate
			-- if damages.imm_dmg_rate >= 100 then
				-- self:show_skill_missed(selfId,targetId,skill_id,self:get_logic_count(),define.MISS_FLAG.FLAG_IMMU)
				-- return
			-- else
				-- imm_dmg_rate = imm_dmg_rate - damages.imm_dmg_rate
			-- end
		end
		local key
		local damage_top_objid = selfId + 1
		local sender_ishuman = 0
		if sender then
			targetId = sender:get_obj_id()
			if sender:get_obj_type() == "human" then
				local special_rate = sender:damage_rate()
				if special_rate > 0 then
					for _,key in ipairs(DAMAGE_TYPE_RATE) do
						damages[key] = damages[key] + special_rate
					end
				end
				sender_ishuman = 1
				damage_point_refix = damage_point_refix + sender:item_value(define.ITEM_ATTRIBUTE.IATTRIBUTE_POINT_ADD_DAMAGE) + sender:get_mission_data_by_script_id(622)
				local effect_value,feature_rate = sender:get_dw_jinjie_effect_details(16)
				--10%
				if effect_value > 0 and math.random(100) % 10 == 5 then
					local chengxu_hp_rate = effect_value / feature_rate
					local chengxu_mp_rate = chengxu_hp_rate / 3
					sender:features_effect_notify_client(16)
					key = DAMAGE_TYPE_BACK[8]
					table.insert(damages[key],{rate = chengxu_hp_rate})
					key = DAMAGE_TYPE_BACK[6]
					table.insert(damages[key],{rate = chengxu_mp_rate})
				end
				effect_value,feature_rate = sender:get_dw_jinjie_effect_details(14)
				if effect_value > 0 and math.random(100) <= 6 then
					local jiqu_rate = effect_value / feature_rate
					if self_ismonster then
						jiqu_rate = jiqu_rate / 5
					end
					sender:features_effect_notify_client(14)
					key = DAMAGE_TYPE_BACK[4]
					table.insert(damages[key],{rate = jiqu_rate,maxhp = 0.05})
					damages.recover_hp_rate_enable = true
				end
				
			else
				sender_ishuman = 5
			end
		end
		-- 武境武诀点PvP伤害修正：攻击方攻击武诀 vs 防御方守御武诀
		-- 互选门派匹配时，差值每1点=1%增伤/免伤，单槽上限5%
		if sender_ishuman == 1 and self_ishuman == 1 and sender.get_dfeng_attack_slots and self.get_dfeng_defence_slots then
			local dfeng_rate = 0
			local atk_slots = sender:get_dfeng_attack_slots()
			local def_slots = self:get_dfeng_defence_slots()
			for _, atk in ipairs(atk_slots) do
				if atk.school > 0 then
					for _, def in ipairs(def_slots) do
						if def.school == atk.school then
							local diff = atk.xdd - def.xdd
							if diff > 0 then
								dfeng_rate = dfeng_rate + math.min(diff, 5)
							elseif diff < 0 then
								dfeng_rate = dfeng_rate - math.min(-diff, 5)
							end
							break
						end
					end
				end
			end
			if dfeng_rate ~= 0 then
				damages.dfeng_damage_rate = dfeng_rate
			end
		end
		local hp_modify = 0
		local key
		-- local ts = {"外功伤害:","内功伤害","冰攻伤害:","火攻伤害:","玄攻伤害:","毒攻伤害:","直接伤害:"}
		if not damages.direcht_rate then
			for i,j in ipairs(DAMAGE_TYPE_RATE) do
				key = DAMAGE_TYPE_POINT[i]
				if i < 7 then
					hp_modify = hp_modify + damages[i - 1] * damages[j] / 100 + damages[key]
					-- skynet.logi(ts[i],damages[i - 1],"加成:",damages[j],"%","额外增加:",damages[key])
				else
					hp_modify = hp_modify + damages[i - 1] + damages[key]
					-- skynet.logi(ts[i],damages[i - 1],"加成:所有加成不算入","额外增加:",damages[key])
				end
			end
		else
			for i,j in ipairs(DAMAGE_TYPE_RATE) do
				key = DAMAGE_TYPE_POINT[i]
				hp_modify = hp_modify + damages[i - 1] * damages[j] / 100 + damages[key]
				-- skynet.logi(ts[i],damages[i - 1],"加成:",damages[j],"%","额外增加:",damages[key])
			end
		end
		hp_modify = hp_modify + damage_point_refix
        -- HJ05: StdImpact101 changes combined damage once, round half up.
        if damages.cys_nuhuo_rate and hp_modify > 0 then
            hp_modify = hp_modify + math.floor(hp_modify * damages.cys_nuhuo_rate / 100 + 0.5)
        end
		
		local chuanci = damages.chuanci or 0
		if hp_modify <= 0 and chuanci <= 0 then
			return
		end
		
		hp_modify = hp_modify * imm_dmg_rate / 100
		
		-- 应用武诀点增伤/免伤
		if damages.dfeng_damage_rate and damages.dfeng_damage_rate ~= 0 then
			hp_modify = hp_modify * (100 + damages.dfeng_damage_rate) / 100
		end
		
		local hp_damage_all = hp_modify + chuanci
		-- 经脉：手少阳增伤（最终总伤害乘数）
		if sender and sender:get_obj_type() == "human" then
			local ok, rate = pcall(sender.item_value, sender, 80)
			if ok and rate and rate > 0 then
				local mul = (10000 + rate) / 10000
				hp_damage_all = hp_damage_all * mul
				hp_modify = hp_modify * mul
			end
		end
		-- 经脉：足太阴减伤（最终总伤害乘数）
		if self and self:get_obj_type() == "human" then
			local ok, rate = pcall(self.item_value, self, 86)
			if ok and rate and rate > 0 then
				local mul = (10000 - rate) / 10000
				hp_damage_all = hp_damage_all * mul
				hp_modify = hp_modify * mul
			end
			local huayu_reduce = ride_huayu_bonus.get_damage_reduce_rate(self)
			if huayu_reduce > 0 then
				local mul = (100 - math.min(huayu_reduce, 100)) / 100
				hp_damage_all = hp_damage_all * mul
				hp_modify = hp_modify * mul
			end
		end
		if self and self:get_obj_type() == "human" then
			local reduce = equip_dress_bonus.get_jinyi_damage_reduce_permyriad(self)
			if reduce and reduce > 0 then
				local mul = (10000 - reduce) / 10000
				hp_damage_all = hp_damage_all * mul
				hp_modify = hp_modify * mul
			end
		end
		local cy_before = hp_damage_all
		hp_damage_all = require("cy_four_combat.hooks").final_damage(self, sender, hp_damage_all, is_critical)
		hp_modify = hp_modify + (hp_damage_all - cy_before)
		hp_damage_all = hp_damage_all < 0 and 0 or hp_damage_all
		
		local back_damage = 0
		local logic,back_value
		key = DAMAGE_TYPE_BACK[1]
		for _,ii in ipairs(damages[key]) do
			logic = impactenginer:get_logic_for_id(ii:get_logic_id())
			if logic then
				back_value = logic:on_damages_back(ii, self, hp_damage_all, sender,is_critical) or 0
				back_damage = back_damage + back_value
			end
		end
		key = DAMAGE_TYPE_BACK[2]
		for _,tt in ipairs(damages[key]) do
			logic = talentenginer:get_logic_for_id(tt.talent.id)
			if logic then
				back_value = logic:on_damages_back_talent(tt.talent,tt.level,self,sender,hp_damage_all,skill_id) or 0
				back_damage = back_damage + back_value
			end
		end
		
		hp_damage_all = hp_damage_all - back_damage
		-- skynet.logi("hp_damage_all = ",hp_damage_all)
		if hp_damage_all <= 0 then
			return
		end
		
		hp_modify = hp_modify - back_damage
		-- skynet.logi("hp_modify = ",hp_modify)
		-- skynet.logi("chuanci = ",chuanci)
		
		if hp_modify < 0 then
			chuanci = chuanci + hp_modify
			hp_modify = 0
		end
		-- skynet.logi("chuanci = ",chuanci)
		local recover_dmg_rate = 0
		local recover_dmg_rate_count = {}
		
		local recover_hp_rate = 0
		local recover_hp_rate_count = {}
		
		local recover_mp_rate = 0
		local recover_mp_rate_count = {}
		
		local add_dmg_mp_rate = 0
		local add_dmg_mp_rate_count = {}
		
		local recover_nq_rate = 0
		local recover_nq_rate_count = {}
		
		local add_dmg_hp_rate = 0
		local add_dmg_hp_rate_count = {}
		
		
		local value,maxvalue
		if sender_ishuman > 0 then
			local sender_maxhp = sender:get_max_hp()
			
			key = DAMAGE_TYPE_BACK[3]
			for i,j in ipairs(damages[key]) do
				value = math.ceil(hp_damage_all * j.rate / 100)
				if j.maxhp then
					maxvalue = math.ceil(sender_maxhp * j.maxhp)
					value = value > maxvalue and maxvalue or value
				elseif j.max_damage then
					maxvalue = math.ceil(value * j.max_damage)
					value = value > maxvalue and maxvalue or value
				end
				recover_dmg_rate = recover_dmg_rate + value
				table.insert(recover_dmg_rate_count,value)
			end
			
			key = DAMAGE_TYPE_BACK[4]
			if not damages.imm_recover_hp and not damages.flag_immu then
				-- sub_recover_hp_rate 默认0=关闭回血，recover_hp_rate_enable=true 可由天赋精确启用
				local sub_recover_hp_rate = 0
				if damages.recover_hp_rate_enable then
					sub_recover_hp_rate = 100
				end
				if damages.sub_recover_hp_rate then
					sub_recover_hp_rate = sub_recover_hp_rate - damages.sub_recover_hp_rate
				end
				if sub_recover_hp_rate > 0 then
					for i,j in ipairs(damages[key]) do
						value = hp_damage_all * j.rate / 100
						value = value * sub_recover_hp_rate / 100
						if j.maxhp then
							maxvalue = sender_maxhp * j.maxhp
							value = value > maxvalue and maxvalue or value
						end
						recover_hp_rate = recover_hp_rate + value
						table.insert(recover_hp_rate_count,value)
					end
				end
			end
			
			key = DAMAGE_TYPE_BACK[5]
			for i,j in ipairs(damages[key]) do
				value = hp_damage_all * j.rate / 100
				-- if j.xiqu_rate then
					-- maxvalue = value * j.xiqu_rate
					-- value = value > maxvalue and maxvalue or value
				-- end
				recover_mp_rate = recover_mp_rate + value
				table.insert(recover_mp_rate_count,value)
			end

			key = DAMAGE_TYPE_BACK[6]
			for i,j in ipairs(damages[key]) do
				value = hp_damage_all * j.rate / 100
				add_dmg_mp_rate = add_dmg_mp_rate - value
				table.insert(add_dmg_mp_rate_count,-1 * value)
			end

			key = DAMAGE_TYPE_BACK[7]
			for i,j in ipairs(damages[key]) do
				value = hp_damage_all * j.rate / 100
				recover_nq_rate = recover_nq_rate + value
				table.insert(recover_nq_rate_count,value)
			end
			
			key = DAMAGE_TYPE_BACK[8]
			for i,j in ipairs(damages[key]) do
				value = hp_damage_all * j.rate / 100
				add_dmg_hp_rate = add_dmg_hp_rate + value
				table.insert(add_dmg_hp_rate_count,value)
			end

		end
		
		hp_damage_all = -1 * hp_damage_all - add_dmg_hp_rate
		hp_modify = -1 * hp_modify
		
		local max_hp = self:get_attrib("hp_max")
		local old_hp = self:get_attrib("hp")
		
		local is_die = false
		local now_hp =  math.ceil(old_hp + hp_damage_all)
		now_hp = now_hp < 0 and 0 or now_hp
		if old_hp > 0 and now_hp == 0 then
			if self:impact_on_die_check() then
				if old_hp == 1 then
					return
				end
				now_hp = 1
			else
				is_die = true
			end
		end
		-- -lock_hp
		local lock_hp = now_hp - old_hp
		if hp_modify < lock_hp then
			hp_modify = lock_hp
			chuanci = 0
			add_dmg_hp_rate = 0
		else
			-- +lock_hp
			lock_hp = hp_modify - lock_hp
			if chuanci > lock_hp then
				chuanci = lock_hp
				add_dmg_hp_rate = 0
			else
				lock_hp = lock_hp - chuanci
				if add_dmg_hp_rate > lock_hp then
					add_dmg_hp_rate = lock_hp
				end
			end
		end
		hp_damage_all = math.ceil(old_hp - now_hp)
		-- All floating damage components must share the actual HP-loss budget.
		-- The values above are theoretical damage; lethal overkill has already
		-- been clamped by now_hp and must not leak into client damage numbers.
		local display_damage_left = hp_damage_all
		local base_damage = math.min(math.max(0, math.ceil(-hp_modify)), display_damage_left)
		hp_modify = -base_damage
		display_damage_left = display_damage_left - base_damage
		chuanci = math.min(math.max(0, math.ceil(chuanci)), display_damage_left)
		display_damage_left = display_damage_left - chuanci
		add_dmg_hp_rate = math.min(math.max(0, math.ceil(add_dmg_hp_rate)), display_damage_left)
		if hp_modify < 0 then
			local msg = packet_def.GCDetailHealsAndDamages.new()
			msg.reciver = selfId
			msg.sender = targetId
			msg.logic_count = logic_count
			msg.hp_modification = hp_modify
			msg.is_critical_hit = is_critical and 1 or 0
			msg.dirty_flags = msg.dirty_flags | 1
			self:broadcast_heal_and_damage_msg(sender, msg)
		end
		if chuanci > 0 then
			local msg = packet_def.GCDetailHealsAndDamages.new()
			msg.reciver = selfId
			msg.sender = targetId
			msg.logic_count = logic_count
			value = math.ceil(-1 * chuanci - 100000)
			msg.mp_modification = value
			msg.dirty_flags = msg.dirty_flags | 2
			if define.CHUANCI_INFO.IS_CRITICAL_HIT == 1 then
				msg.is_critical_hit = is_critical and 1 or 0
			else
				msg.is_critical_hit = 0
			end
			self:broadcast_heal_and_damage_msg(sender, msg)
		end
		if add_dmg_hp_rate > 0 then
			local add_damage_left = add_dmg_hp_rate
			for _, j in ipairs(add_dmg_hp_rate_count) do
				local display_value = math.min(math.max(0, math.ceil(j)), add_damage_left)
				if display_value <= 0 then
					break
				end
				local msg = packet_def.GCDetailHealsAndDamages.new()
				msg.reciver = selfId
				msg.sender = targetId
				msg.logic_count = logic_count
				value = -display_value
				msg.hp_modification = value
				msg.is_critical_hit = 0
				msg.dirty_flags = msg.dirty_flags | 1
				self:broadcast_heal_and_damage_msg(sender, msg)
				add_damage_left = add_damage_left - display_value
			end
		end
		if sender_ishuman > 0 then
			if sender_ishuman == 1 then
				local actscene = sender:get_mission_data_by_script_id(611)
				if actscene > 0 and actscene == sender:get_mission_data_by_script_id(612)
				and selfId == sender:get_mission_data_by_script_id(613) then
					local addamage = hp_damage_all * self_ishuman
					sender:set_mission_data_by_script_id(614,sender:get_mission_data_by_script_id(614) + addamage)
				end
				if recover_mp_rate ~= 0 then
					sender:mana_increment_damages(recover_mp_rate,recover_mp_rate_count,sender,imp)
				end
				if recover_nq_rate > 0 then
					sender:rage_increment_damages(recover_nq_rate,recover_nq_rate_count)
				end
			end
			if recover_hp_rate > 0 then
				sender:health_increment_damages(recover_hp_rate,recover_hp_rate_count,sender,imp,skill_id)
			end
			if recover_dmg_rate > 0 then
				sender:health_increment_damages(-1 * recover_dmg_rate,recover_dmg_rate_count,sender,imp,skill_id)
			end
		end
		if add_dmg_mp_rate < 0 and sender_ishuman == 1 then
			self:mana_increment_damages(add_dmg_mp_rate,add_dmg_mp_rate_count,sender,imp)
		end
		if self_ismonster then
			self:back_monster_damage(hp_damage_all,sender)
		end
		self:set_hp(now_hp)
		if is_die then
			if targetId ~= -1 then
				self:on_die(targetId)
			else
				self:on_die(selfId)
			end
			if sender_ishuman == 1 then
				if skill_id == 811 then
					self:soul_separated_kill_blindness(sender)
				elseif skill_id == 801 then -- [FIX] 901 向死而生
					self:toward_death_kill_heal(sender)
				elseif skill_id == 796 then
					local talent_config = configenginer:get_config("sect_desc")
					local talent = sender:get_talent()
					local logic,t_config,level,study_talent_id
					for i = 1, #talent.study do
						study_talent_id = talent.study[i].id
						if study_talent_id == 641 
						or study_talent_id == 642
						or study_talent_id == 704 then
							local logic = talentenginer:get_logic_id(study_talent_id)
							if logic then
								t_config = talent_config[study_talent_id]
								if t_config then
									level = talent.study[i].level
									level = level == 0 and 1 or level
									if sender then
										logic:on_die(t_config, level, sender, self, skill_id)
									end
								end
							end
						end
					end
				else
					local talent_config = configenginer:get_config("sect_desc")
					local talent = sender:get_talent()
					local logic,t_config,level,study_talent_id
					for i = 1, #talent.study do
						study_talent_id = talent.study[i].id
						if study_talent_id == 704 then
							local logic = talentenginer:get_logic_id(study_talent_id)
							if logic then
								t_config = talent_config[study_talent_id]
								if t_config then
									level = talent.study[i].level
									level = level == 0 and 1 or level
									if sender then
										logic:on_die(t_config, level, sender, self, skill_id)
									end
								end
							end
						end
					end
				end
			end
		else
			if self:get_character_logic() == define.ENUM_CHARACTER_LOGIC.CHARACTER_LOGIC_USE_SKILL then
				local params = self:get_action_params()
				local continuance = params:on_damages()
				if continuance and continuance ~= 0 then
					local msg = packet_def.GCCharModifyAction.new()
					msg.m_objID = selfId
					msg.logic_count = self:get_logic_count()
					msg.modify_time = continuance
					scene:send2client(self,msg)
				end
			end
		end
	end
end

function character:gm_kill_obj(targetId)
	if self:is_active_obj() then
		if self:is_die() then
			return
		end
		local sender = self:get_scene():get_obj_by_id(targetId)
		if sender then
			if sender:get_obj_type() == "pet" then
				local hm_sender = sender:get_owner()
				targetId = hm_sender:get_obj_id()
			end
		else
			targetId = self:get_obj_id()
		end
		self:set_hp(0)
		self:on_die(targetId)
		return true
	end
end

function character:rage_increment_damages(rage_modify,rage_modify_count)
    rage_modify = math.ceil(rage_modify)
    if self:is_active_obj() and rage_modify ~= 0 then
        local max_rage = self:get_attrib("rage_max") or 0
        if rage_modify >= 0 then
            local now_rage = self:get_attrib("rage") + rage_modify
            now_rage = now_rage > max_rage and max_rage or now_rage
            self:set_rage(now_rage)
        else
            local old_rage = self:get_attrib("rage")
            local now_rage = old_rage + rage_modify
            now_rage = now_rage < 0 and 0 or now_rage
            self:set_rage(now_rage)
        end
    end
end

function character:mana_increment_damages(mp_modify,mp_modify_count,sender,imp)
    mp_modify = math.ceil(mp_modify)
    if self:is_active_obj() and mp_modify ~= 0 then
		local selfId = self:get_obj_id()
		local targetId = sender and sender:get_obj_id() or define.INVAILD_ID
		
		local logic_count = 0
		if imp then
			logic_count = imp:get_caster_logic_count()
		end
		local value
		for i,j in ipairs(mp_modify_count) do
			value = math.ceil(j)
			if value ~= 0 then
				local msg = packet_def.GCDetailHealsAndDamages.new()
				msg.reciver = selfId
				msg.sender = targetId
				msg.logic_count = logic_count
				msg.mp_modification = value
				msg.dirty_flags = msg.dirty_flags | 2
				msg.is_critical_hit = 0
				self:broadcast_heal_and_damage_msg(sender, msg)
			end
		end
        local max_mp = self:get_attrib("mp_max") or 0
        if mp_modify >= 0 then
            local now_mp = self:get_attrib("mp") + mp_modify
            now_mp = now_mp > max_mp and max_mp or now_mp
            self:set_mp(now_mp)
        else
            local old_mp = self:get_attrib("mp")
            local now_mp = old_mp + mp_modify
            now_mp = now_mp < 0 and 0 or now_mp
            self:set_mp(now_mp)
        end
    end
end


function character:on_teleport(world_pos)
	if self:is_die() then
		return
	end
    local scene = self:get_scene()
    local dist = scene:cal_dist(self:get_world_pos(), world_pos)
    self:impact_on_logic_move(dist)
    self:set_world_pos(world_pos)
    scene:char_world_pos_changed(self)
    local msg = packet_def.GCObjTeleport.new()
    msg.m_objID = self:get_obj_id()
    msg.world_pos = world_pos
    scene:broadcast(self, msg, true)
end

function character:broadcast_heal_and_damage_msg(sender, msg)
    local scene = self:get_scene()
    if self:get_obj_type() == "human" then
        scene:send2client(self, msg)
    end
    if self:get_obj_type() == "pet" then
        local creator = self:get_creator()
        scene:send2client(creator, msg)
    end
    if sender and sender ~= self then
        if sender:get_obj_type() == "human" then
            scene:send2client(sender, msg)
        end
        if sender:get_obj_type() == "pet" then
            local creator = sender:get_creator()
            scene:send2client(creator, msg)
        end
    end
end

function character:get_hp()
    return self.db:get_attrib("hp")
end

function character:get_mp()
    return self.db:get_attrib("mp")
end

function character:get_max_hp()
    return self.db:get_attrib("hp_max")
end

function character:get_max_mp()
    return self.db:get_attrib("mp_max")
end

function character:get_max_rage()
    return self.db:get_attrib("rage_max")
end

function character:inc_data_id()
    self.data_id = self.data_id + 1
    if self.data_id == 0xff then
        self.data_id = 0
    end
    return self.data_id
end

function character:refix_impact(imp, reciver)
    self:impact_refix_imp(imp, reciver)
    local r, err = pcall(self.talent_refix_impact, self, imp, reciver)
    if not r then
        skynet.loge("talent_refix_impact error =", err)
    end
end

function character:impact_refix_imp(imp)
    local list = self:get_impact_list()
    for _, current in ipairs(list) do
        local logic = impactenginer:get_logic(current)
        if logic then
            if current:get_is_over_timed() then
                logic:refix_impact(current, self, imp)
            end
        end
    end
end

function character:trigger_talent_cost(id,cost)
	if self:get_obj_type() == "human" then
		local talent = self:get_talent()
		for i = 1, #talent.study do
			local study_talent = talent.study[i]
			if study_talent.id == id then
                local logic = talentenginer:get_logic(study_talent)
				if logic then
					local talent_config = configenginer:get_config("sect_desc")
					talent_config = talent_config[id]
					if talent_config then
						local level = study_talent.level
						level = level == 0 and 1 or level
						logic:trigger_talent_cost(talent_info, level, cost, self)
					end
				end
			end
		end
	end
end

function character:have_talent(id)
	if self:get_obj_type() == "human" then
		local talent = self:get_talent()
		for i = 1, #talent.study do
			local study_talent = talent.study[i]
			if study_talent.id == id then
				local talent_config = configenginer:get_config("sect_desc")
				talent_config = talent_config[id]
				if talent_config then
					local level = study_talent.level
					level = level == 0 and 1 or level
					local params = talent_config.params[level]
					if params then
						return params[1] or 0
					end
				end
			end
		end
	end
	return 0
end

function character:talent_refix_impact(imp, reciver)
    local sender = self:get_scene():get_obj_by_id(imp:get_caster_obj_id())
    if sender then
        if sender:get_obj_type() == "human" then
			local talent_config = configenginer:get_config("sect_desc")
            local talent = sender:get_talent()
            for i = 1, #talent.study do
                local study_talent = talent.study[i]
                local logic = talentenginer:get_logic(study_talent)
                if logic then
                    talent_info = talent_config[study_talent.id]
                    if talent_info then
                        local level = study_talent.level
                        level = level == 0 and 1 or level
					logic:refix_impact(talent_info, level, imp, sender, reciver)
                    end
                end
            end
        end
    end
end

function character:impact_refix_critical_rate(critical_rate, skill_info)
    local impacts = self:get_impact_list()
    for i = #impacts, 1, -1 do
        local impact = impacts[i]
        local logic = impactenginer:get_logic(impact)
        critical_rate = logic:refix_critical_rate(impact, critical_rate, skill_info, self)
    end
    return critical_rate
end

function character:dispel_Impact_in_specific_collection(collection_id, dispel_level, dispel_count, skilltab)
    local list = self:get_impact_list()
    local dispeld = 0
	if skilltab and #skilltab > 0 then
		for _, imp in ipairs(list) do
			if dispeld == dispel_count then
				break
			end
			if imp:is_can_be_dispeled() then
				if imp:get_skill_level() <= dispel_level then
					local istrue = false
					local skill_id = imp:get_skill_id()
					for _,skill in ipairs(skilltab) do
						if skill == skill_id then
							istrue = true
							break
						end
					end
					if not istrue then
						if impactenginer:is_impact_in_collection(imp, collection_id) then
							dispeld = dispeld + 1
							self:on_impact_fade_out(imp)
							self:remove_impact(imp)
						end
					end
				end
			end
		end
	else
		for _, imp in ipairs(list) do
			if dispeld == dispel_count then
				break
			end
			if imp:is_can_be_dispeled() then
				if imp:get_skill_level() <= dispel_level then
					if impactenginer:is_impact_in_collection(imp, collection_id) then
						dispeld = dispeld + 1
						self:on_impact_fade_out(imp)
						self:remove_impact(imp)
					end
				end
			end
		end
	end
    return dispeld
end
--预留，调用多时再使用
-- function character:talent_on_die(targetId)
	-- if targetId and targetId ~= -1 then
		-- local sender = self:get_scene():get_obj_by_id(targetId)
		-- if sender then
			-- if sender:get_obj_type() == "human" then
				-- local talent_config = configenginer:get_config("sect_desc")
				-- local talent = sender:get_talent()
				-- for i = 1, #talent.study do
					-- local study_talent = talent.study[i]
					-- local logic = talentenginer:get_logic(study_talent)
					-- if logic then
						-- talent_info = talent_config[study_talent.id]
						-- if talent_info then
							-- local level = study_talent.level
							-- level = level == 0 and 1 or level
							-- if sender then
								-- logic:refix_impact(talent_info, level, sender, self)
							-- end
						-- end
					-- end
				-- end
			-- end
		-- end
	-- end
-- end

function character:on_die(targetId)
    if not actionenginer:can_do_next_action(self) then
        actionenginer:interrupt_current_action(self)
    end
    self:impact_on_die()
	--预留，调用多时再使用
    -- local r, err = pcall(self.talent_on_die, self, targetId)
    -- if not r then
        -- skynet.loge("talent_on_die error =", err)
    -- end
    self.ai:on_die(targetId)
end

function character:on_relive()

end

function character:on_filtrate_impact(imp)
    require("cy_four_combat.phase3").on_filtrate(self, imp)
    local list = self:get_impact_list()
    for _, current in ipairs(list) do
        local logic = impactenginer:get_logic(current)
        local result = logic:on_filtrate_impact(current, self, imp)
        if result == define.MissFlag_T.FLAG_IMMU then
            return define.MissFlag_T.FLAG_IMMU
        elseif result == define.MissFlag_T.FLAG_ABSORB then
            return define.MissFlag_T.FLAG_ABSORB
        end
    end

    -- 兽魂控制免疫概率检查（仅对拥有 item_value 的人物角色生效）
    if self.item_value and imp:get_stand_flag() == define.ENUM_BEHAVIOR_TYPE.BEHAVIOR_TYPE_HOSTILITY then
        local COLLECTION_RESIST_MAP = {
            [52] = define.ITEM_ATTRIBUTE.IATTRIBUTE_POINT_JIAN_SU_RESIST,    -- 减速
            [53] = define.ITEM_ATTRIBUTE.IATTRIBUTE_POINT_DIAN_XUE_RESIST,   -- 封穴
            [54] = define.ITEM_ATTRIBUTE.IATTRIBUTE_POINT_MA_BI_RESIST,      -- 麻痹
            [64] = define.ITEM_ATTRIBUTE.IATTRIBUTE_POINT_SAN_GONG_RESIST,   -- 散功
            [72] = define.ITEM_ATTRIBUTE.IATTRIBUTE_POINT_FENG_YIN_RESIST,   -- 封印
            [55] = define.ITEM_ATTRIBUTE.IATTRIBUTE_POINT_SHI_MING_RESIST,   -- 失明
        }
        for collection_id, resist_attr in pairs(COLLECTION_RESIST_MAP) do
            if impactenginer:is_impact_in_collection(imp, collection_id) then
                local resist_value = self:item_value(resist_attr)
                if resist_value and resist_value > 0 then
                    if math.random(10000) <= resist_value then
                        return define.MissFlag_T.FLAG_IMMU
                    end
                end
                break  -- 已匹配到集合，无需继续
            end
        end
    end

    return define.MissFlag_T.FLAG_NORMAL
end

function character:get_ai()
    return self.ai
end

function character:get_ai_state()
    return self:get_ai():get_state():get_estate()
end

function character:can_use_skill_now()
    if self:get_action_time() > 0 then
        return false
    end
    if not actionenginer:can_do_next_action(self) then
        return false
    end
    return true
end

function character:is_limit_move()
    local can_move = self:get_attrib("can_move")
    return can_move == 0
end

function character:can_move()
    return not self:is_limit_move()
end

function character:can_ignore_disturb()
    return self:get_attrib("can_ignore_disturb") == 1
end

function character:direct_move_to(tar)
    self:do_move(-1, { tar })
end

function character:fly_to(tar)
    self:do_fly(-1, { tar })
end

function character:set_locked_target(obj_id)
    self.locked_target = obj_id
    self:on_lock_target(obj_id)
end

function character:on_lock_target()

end

function character:get_locked_target()
    return self.locked_target
end

function character:mana_increment(mp_modify, sender, is_critical, imp)
    mp_modify = math.ceil(mp_modify)
    if self:is_active_obj() and mp_modify ~= 0 then
        local msg = packet_def.GCDetailHealsAndDamages.new()
        msg.reciver = self:get_obj_id()
        if sender then
            msg.sender = sender:get_obj_id()
        else
            msg.sender = define.INVAILD_ID
        end
        if imp then
            msg.logic_count = imp:get_caster_logic_count()
        else
            msg.logic_count = 0
        end
        msg.mp_modification = mp_modify
        msg.dirty_flags = msg.dirty_flags | 2
        msg.is_critical_hit = 0
        self:broadcast_heal_and_damage_msg(sender, msg)
        local max_mp = self:get_attrib("mp_max") or 0
        if mp_modify >= 0 then
            local now_mp = self:get_attrib("mp") + mp_modify
            now_mp = now_mp > max_mp and max_mp or now_mp
            self:set_mp(now_mp)
        else
            local old_mp = self:get_attrib("mp")
            local now_mp = old_mp + mp_modify
            now_mp = now_mp < 0 and 0 or now_mp
            self:set_mp(now_mp)
			return old_mp - now_mp
        end
    end
end

function character:rage_increment(rage_modify)
    rage_modify = math.ceil(rage_modify)
    if self:is_active_obj() and rage_modify ~= 0 then
        local max_rage = self:get_attrib("rage_max") or 0
        if rage_modify >= 0 then
			local now_rage = self:get_attrib("rage") + rage_modify
			now_rage = now_rage > max_rage and max_rage or now_rage
			self:set_rage(now_rage)
        else
            local old_rage = self:get_attrib("rage")
            local now_rage = old_rage + rage_modify
            now_rage = now_rage < 0 and 0 or now_rage
            self:set_rage(now_rage)
			return old_rage - now_rage
        end
    end
end

function character:strike_point_increment(strike_point_modify, sender)
    if self:is_active_obj() and strike_point_modify ~= 0 then
        local msg = packet_def.GCDetailHealsAndDamages.new()
        msg.reciver = self:get_obj_id()
        if sender then
            msg.sender = sender:get_obj_id()
            msg.logic_count = sender:get_logic_count()
        else
            msg.sender = define.INVAILD_ID
            msg.logic_count = 0
        end
        msg.strike_point_modification = strike_point_modify
        msg.dirty_flags = msg.dirty_flags | 8
        msg.is_critical_hit = 0
		-- for key, value in pairs(msg) do  
			-- skynet.logi("strike_point_increment>>键是:", key,";值是: ",value)
		-- end
		
        self:broadcast_heal_and_damage_msg(sender, msg)
        local max_strike_point= self:get_attrib("strike_point_max") or 0
        if strike_point_modify >= 0 then
            local now_strike_point = self:get_attrib("strike_point") + strike_point_modify
            now_strike_point = now_strike_point > max_strike_point and max_strike_point or now_strike_point
            self:set_strike_point(now_strike_point)
        else
            local old_strike_point = self:get_attrib("strike_point")
            local now_strike_point = old_strike_point + strike_point_modify
            now_strike_point = now_strike_point < 0 and 0 or now_strike_point
            self:set_strike_point(now_strike_point)
        end
    end
end

function character:datura_flower_increment(datura_flower_modify, sender)
    if self:is_active_obj() and datura_flower_modify ~= 0 then
        local msg = packet_def.GCDetailHealsAndDamages.new()
        msg.reciver = self:get_obj_id()
        if sender then
            msg.sender = sender:get_obj_id()
            msg.logic_count = sender:get_logic_count()
        else
            msg.sender = define.INVAILD_ID
            msg.logic_count = 0
        end
        msg.strike_point_modification = datura_flower_modify
        msg.dirty_flags = msg.dirty_flags | 8
        msg.is_critical_hit = 0
		
		-- for key, value in pairs(msg) do  
			-- skynet.logi("datura_flower_increment>>键是:", key,";值是: ",value)
		-- end
		
        self:broadcast_heal_and_damage_msg(sender, msg)
        local max_datura_flower= self:get_attrib("datura_flower_max") or 6
        if datura_flower_modify >= 0 then
            local now_datura_flower = self:get_attrib("datura_flower") + datura_flower_modify
            now_datura_flower = now_datura_flower > max_datura_flower and max_datura_flower or now_datura_flower
            self:set_datura_flower(now_datura_flower)
        else
            local old_datura_flowe = self:get_attrib("datura_flower")
            local now_datura_flower = old_datura_flowe + datura_flower_modify
            now_datura_flower = now_datura_flower < 0 and 0 or now_datura_flower
            self:set_datura_flower(now_datura_flower)
			old_datura_flowe = old_datura_flowe - now_datura_flower
			local r, err = pcall(self.trigger_talent_cost, self, 874, old_datura_flowe)
			if not r then
				skynet.loge("trigger_talent_cost error =", err)
			end
        end
    end
end

function character:on_heal_target(skill_id, hp_modify, healed_obj_id)
    if type(hp_modify) ~= "number" or hp_modify <= 0 or healed_obj_id == nil then
        return
    end
    local obj_type = self:get_obj_type()
    if obj_type ~= "human" and obj_type ~= "pet" then
        return
    end
    local position = self:get_world_pos()
    local operate = {
        obj = self,
        x = position.x,
        y = position.y,
        radious = 50,
        check_can_view = true
    }
    local heal_hate = math.max(1, math.ceil(hp_modify * 0.5))
    for _, nearby in ipairs(self:get_scene():scan(operate)) do
        if nearby:get_obj_type() == "monster" and nearby:is_alive() then
            local ai = nearby:get_ai()
            if ai:is_already_exist(healed_obj_id) then
                ai:add_hate(self:get_obj_id(), heal_hate)
            end
        end
    end
end

function character:set_relive_info(is_skill_relive, relive_info)
    assert(relive_info)
    if is_skill_relive then
        self.skill_relive_info = relive_info
        self.can_skill_relive = true
    else
        self.relive_info = relive_info
    end
    self:get_ai():on_relive_info_changed(is_skill_relive)
end

function character:clear_skill_relive_info()
    self.skill_relive_info = nil
    self.can_skill_relive = false
end

function character:get_relive_info(is_skill_relive)
    if is_skill_relive then
        return self.skill_relive_info
    end
    return self.relive_info
end

function character:can_action_flag_1()
    local flag = self:get_attrib("can_action_1") == 1
    return flag
end

function character:can_action_flag_2()
    local flag = self:get_attrib("can_action_2") == 1
    return flag
end

function character:get_owner()
    return nil
end

function character:get_camp_id()
    return self:get_attrib("camp_id")
end

function character:is_enemy_camp(other)
    local owner_1 = self:get_owner()
    local owner_2 = other:get_owner()
    if owner_1 or owner_2 then
        if owner_1 == other or owner_2 == self or owner_1 == owner_2 then
            return false
        end
    end
    local relation = self:calc_relation_type(self:get_obj_type(), other:get_obj_type(), self:get_camp_id(), other:get_camp_id())
    return relation == define.ENUM_RELATION.RELATION_ENEMY
end

function character:calc_relation_type(otype_1, otype_2, camp_1, camp_2)
    local camp_and_stand = configenginer:get_config("camp_and_stand")
    local row = camp_and_stand[camp_1]
    if otype_1 == "human" and camp_1 > 8 and otype_2 == "human" then
        row = nil
    end
    if camp_1 == define.INVAILD_ID or camp_2 == define.INVAILD_ID then
        return define.ENUM_RELATION.RELATION_ENEMY
    end
    if row and row[camp_2] == 1 then
        return define.ENUM_RELATION.RELATION_ENEMY
    end
    if otype_1 == "human" and otype_2 == "human" then
        if camp_1 ~= camp_2 then
            return define.ENUM_RELATION.RELATION_ENEMY
        end
    end
    if otype_1 == "monster" and otype_2 == "monster" then
        if camp_1 ~= camp_2 then
            return define.ENUM_RELATION.RELATION_ENEMY
        end
    end
    if camp_1 > 15 and camp_2 > 15 then
        if camp_1 ~= camp_2 then
            return define.ENUM_RELATION.RELATION_ENEMY
        end
    end
    return define.ENUM_RELATION.RELATION_FRIEND
end

function character:mark_attrib_refix_dirty(key)
    self.db:mark_attrib_refix_dirty(key)
end

function character:impact_clean_all_impact_when_pet_dead(guid)
    local impacts = self:get_impact_list()
    for i = #impacts, 1, -1 do
        local imp = impacts[i]
        if imp:get_caster_obj_id() == guid then
            self:on_impact_fade_out(imp)
            self:remove_impact(imp)
        end
    end
end

function character:impact_clean_when_unequip(equip)
    require('cys_dual_souls').unequip(self,equip)
    if equip then
		local empty_buffs = {
			[5980] = true,
			[5981] = true,
		}
        if item_operator:is_lingyu_equip(equip:get_index()) then
            self:impact_clean_when_unequip_lingwu_equip(equip,empty_buffs)
        else
            self:impact_clean_when_unequip_common_equip(equip,empty_buffs)
        end
        self:impact_clean_when_unequip_diaowen_equip(equip,empty_buffs)
		local impacts = self:get_impact_list()
		for i = #impacts, 1, -1 do
			local imp = impacts[i]
			if empty_buffs[imp:get_data_index()] then
				self:on_impact_fade_out(imp)
				self:remove_impact(imp)
			end
		end
    end
end

function character:impact_clean_when_unequip_diaowen_equip(equip,empty_buffs)
    local std_impact = equip:get_diaowen_std_impact()
    if std_impact ~= define.INVAILD_ID then
		empty_buffs[std_impact] = true
    end
end

function character:impact_clean_when_unequip_common_equip(equip,empty_buffs)
    local impact_id = equip:get_base_config().skill_id
    if impact_id ~= define.INVAILD_ID then
		empty_buffs[impact_id] = true
    end
end

function character:impact_clean_when_unequip_lingwu_equip(lingwu,empty_buffs)
    if lingwu then
        local ling_yu_base = configenginer:get_config("ling_yu_base")
        local ling_yu_set = configenginer:get_config("ling_yu_set")
        local ling_yu_set_effect = configenginer:get_config("ling_yu_set_effect")
        local base = ling_yu_base[lingwu:get_index()]
        local set = base.set
        local set_conf = ling_yu_set[set]
        for i = 1, #set_conf.id do
            local id = set_conf.id[i]
            local effect = ling_yu_set_effect[id]
            if effect.add_impact ~= define.INVAILD_ID then
                local impact_id = effect.add_impact
                if impact_id ~= define.INVAILD_ID then
					empty_buffs[impact_id] = true
                end
            end
        end
    end
end

function character:impact_clean_all_impact_when_unequip_dark()
    local impacts = self:get_impact_list()
    for i = #impacts, 1, -1 do
        local imp = impacts[i]
        if imp:get_skill_id() == define.ANQI_SKILL[90].id then
            self:on_impact_fade_out(imp)
            self:remove_impact(imp)
        end
    end
end

function character:impact_get_first_impact_of_specific_data_index(data_index)
    local impacts = self:get_impact_list()
    for i = #impacts, 1, -1 do
        local imp = impacts[i]
        if imp:get_data_index() == data_index then
            return imp
        end
    end
end

function character:impact_get_first_impact_of_specific_data_index_2(data_index1,data_index2)
	local buffid
    local impacts = self:get_impact_list()
    for i = #impacts, 1, -1 do
        local imp = impacts[i]
		buffid = imp:get_data_index()
        if buffid >= data_index1 and buffid <= data_index2 then
            return imp
        end
    end
end

function character:impact_empty_continuance_elapsed(id)
    local impacts = self:get_impact_list()
    for i = #impacts, 1, -1 do
        local imp = impacts[i]
		if imp:get_data_index() == id then
			imp:set_continuance_elapsed(0)
			return true
		end
    end
end

function character:impact_get_first_impact_of_specific_impact_id(id)
    local impacts = self:get_impact_list()
    for i = #impacts, 1, -1 do
        local imp = impacts[i]
        if imp:get_impact_id() == id then
            return imp
        end
    end
end

function character:impact_set_first_impact_of_specific_impact_id(id,key,value)
    local impacts = self:get_impact_list()
    for i = #impacts, 1, -1 do
        local imp = impacts[i]
        if imp:get_impact_id() == id then
            local logic = impactenginer:get_logic(imp)
            if logic then
                logic:set_refix_key_value(imp,key,value)
            end
        end
    end
end

function character:impact_get_first_impact_of_specific_class_id(id)
    local impacts = self:get_impact_list()
    for i = #impacts, 1, -1 do
        local imp = impacts[i]
        if imp:get_class_id() == id then
            return imp
        end
    end
end

function character:impact_have_impact_of_specific_impact_id(id)
    return self:impact_get_first_impact_of_specific_impact_id(id) ~= nil
end

function character:empty_qing_huan_yin(selfId)
    local impacts = self:get_impact_list()
    for i = #impacts, 1, -1 do
        local imp = impacts[i]
        if imp:get_mutex_id() == 47015 and imp:get_caster_obj_id() == selfId then
			local level = imp:get_data_index() - 47014
            self:on_impact_fade_out(imp)
            self:remove_impact(imp)
			if level >= 1 and level <= 5 then
				return level
			end
        end
    end
end

function character:impact_have_impact_of_specific_mutex_id(id)
    return self:impact_get_mutex_id(id) ~= nil
end

function character:impact_get_first_impact_in_specific_collection(id)
    local impacts = self:get_impact_list()
    for i = #impacts, 1, -1 do
        local imp = impacts[i]
        if impactenginer:is_impact_in_collection(imp, id) then
            return imp
        end
    end
end

function character:impact_get_mutex_id(id)
    local impacts = self:get_impact_list()
    for i = #impacts, 1, -1 do
        local imp = impacts[i]
        if imp:get_mutex_id() == id then
            return imp
        end
    end
end

function character:impact_reduce_continuance_in_specific_collection(id, reduce_time)
    local impacts = self:get_impact_list()
    for i = #impacts, 1, -1 do
        local imp = impacts[i]
        if impactenginer:is_impact_in_collection(imp, id) then
            local logic = impactenginer:get_logic(imp)
            if logic then
                logic:reduce_continuance(imp, self, reduce_time)
            end
        end
    end
end

function character:impact_reset_duration(id)
    local impacts = self:get_impact_list()
    for i = #impacts, 1, -1 do
        local imp = impacts[i]
        if impactenginer:is_impact_in_collection(imp, id) then
			imp:set_continuance_elapsed(0)
        end
    end
end

function character:impact_cancel_impact_in_specific_collection(id)
    local impacts = self:get_impact_list()
    for i = #impacts, 1, -1 do
        local imp = impacts[i]
        if impactenginer:is_impact_in_collection(imp, id) then
            self:on_impact_fade_out(imp)
            self:remove_impact(imp)
        end
    end
end

function character:impact_have_impact_in_specific_collection(id)
    local impacts = self:get_impact_list()
    for i = #impacts, 1, -1 do
        local imp = impacts[i]
        if impactenginer:is_impact_in_collection(imp, id) then
            return true
        end
    end
    return false
end

function character:get_get_collection_state_count(id,isdel)
	local del_impact = {}
    local impacts = self:get_impact_list()
	local count = 0
	if not isdel then
		for i = #impacts, 1, -1 do
			local imp = impacts[i]
			if impactenginer:is_impact_in_collection(imp, id) then
				count = count + 1
			end
		end
	else
		for i = #impacts, 1, -1 do
			local imp = impacts[i]
			if impactenginer:is_impact_in_collection(imp, id) then
				table.insert(del_impact,imp:get_data_index())
				count = count + 1
				self:on_impact_fade_out(imp)
				self:remove_impact(imp)
			end
		end
	end
    return count,del_impact
end


function character:impact_cancel_impact_in_specific_impact_id(id)
    local imp = self:impact_get_first_impact_of_specific_impact_id(id)
    if imp then
        self:on_impact_fade_out(imp)
        self:remove_impact(imp)
    end
end

function character:impact_cancel_impact_in_specific_data_index(data_index)
    local imp =self:impact_get_first_impact_of_specific_data_index(data_index)
    if imp then
        self:on_impact_fade_out(imp)
        self:remove_impact(imp)
    end
end

function character:on_deplete_strike_points(point)

end

function character:set_target_id(id)
    self.target_id = id
end

function character:get_target_id()
    return self.target_id
end

function character:set_title(title)
    self.db:set_db_attrib({title = { str = title}})
end

function character:is_can_relive()
    return self.can_skill_relive
end

function character:get_can_relive()
    return self.can_skill_relive
end

function character:skill_create_obj_specail(world_pos, trap_data_index,skill_id)
    local scene = self:get_scene()
    if scene then
        local initer = { 
		owner_obj_id = self:get_obj_id(),
		data_id = trap_data_index,
		world_pos = world_pos,
		skill_id = skill_id
		}
        local obj_special = scene:create_special_obj(initer)
        return obj_special
    end
end

function character:skill_charge(to, skillid)
    local msg = packet_def.GCCharCharge.new()
    self:add_logic_count()
    msg.logic_count = self:get_logic_count()
    msg.m_objID = self:get_obj_id()
    msg.from = self:get_world_pos()
    msg.to = to
	if skillid then
		msg.unknow = 0
		msg.nSkillId = skillid
	-- else
		-- self.unknow = 1
		-- msg.nSkillId = 0
	end
    self:get_scene():broadcast(self, msg, true)
    self:set_world_pos(to)
end

function character:skill_exec_from_script(skill_id, id_tar, x, z, dir, pass_check)
    local params = self:get_targeting_and_depleting_params()
    local ai = self:get_ai()
    ai:stop()
    params:set_ignore_condition_check_flag(pass_check)
    ai:use_skill(skill_id, id_tar, x, z, dir, define.INVAILD_ID)
end

function character:refix_skill_cool_down_time(skill_info, cool_down_time)
    return cool_down_time
end

function character:refix_miss_rate()
    local rate = 0
    rate = rate + self:impact_refix_miss_rate()
	local effect_value,feature_rate = self:get_dw_jinjie_effect_details(26)
	if effect_value > 0 then
		rate = rate + effect_value / feature_rate
		-- self:features_effect_notify_client(26)
	end
    return rate
end

function character:target_refix_accuracy_rate(obj_tar)
    local rate = 0
    rate = rate + self:impact_target_refix_accuracy_rate(obj_tar)
    return rate
end

function character:impact_refix_miss_rate()
    local rate = 0
    local list = self:get_impact_list()
    for _, imp in ipairs(list) do
        local logic = impactenginer:get_logic(imp)
        if logic then
            rate = rate + logic:refix_miss_rate(imp, self)
        end
    end
    return rate
end

function character:impact_target_refix_accuracy_rate(obj_tar)
    local rate = 0
    local list = self:get_impact_list()
    for _, imp in ipairs(list) do
        local logic = impactenginer:get_logic(imp)
        if logic then
            rate = rate + logic:target_refix_accuracy_rate(imp, self, obj_tar)
        end
    end
    return rate
end

function character:impact_qingyan_check(value)
    local list = self:get_impact_list()
    for _, imp in ipairs(list) do
		if imp:get_mutex_id() == 47015 then
			local add_index = imp:get_data_index() + value
			if add_index > 47019 then
				add_index = 47019
			end
			return add_index
		end
	end
	local add_index = 47015 + value
	if add_index > 47019 then
		add_index = 47019
	end
	return add_index
end

function character:ais_is_can_skill(skill)
    if not self:is_skill_cool_down(skill) then
        return 0
    end
    local ai = self:get_ai()
    local cur_enemy_id = ai:get_cur_enemy_id()
    local cur_enemy = self:get_scene():get_obj_by_id(cur_enemy_id)
    local template = skillenginer:get_skill_template(skill)
    if template.optimal_range_min == define.INVAILD_ID and template.optimal_range_max == define.INVAILD_ID then
        return 1
    end
    if not cur_enemy then
        return 1
    end
    local pos_tar = cur_enemy:get_world_pos()
    local pos_me = self:get_world_pos()
    local dist = math.sqrt((pos_tar.x - pos_me.x) * (pos_tar.x - pos_me.x) + (pos_tar.y - pos_me.y) * (pos_tar.y - pos_me.y))
    if (template.optimal_range_min == define.INVAILD_ID or dist >= template.optimal_range_min) 
    and (template.optimal_range_max == define.INVAILD_ID or dist <= template.optimal_range_max) then
        return 1
    else
        ai:set_skill_id(skill)
        return 0
    end
end

function character:ais_to_skill(skill)
    local ai = self:get_ai()
    local cur_enemy_id = ai:get_cur_enemy_id()
    local cur_enemy = self:get_scene():get_obj_by_id(cur_enemy_id)
    if not cur_enemy then
        return 0
    end
    local pos_tar = cur_enemy:get_world_pos()
    local result = ai:use_skill(skill, cur_enemy_id, pos_tar.x, pos_tar.y, 0, cur_enemy:get_guid())
    ai:set_skill_id(skill)
    if result == define.OPERATE_RESULT.OR_OK then
        return 1
    elseif result == define.OPERATE_RESULT.OR_COOL_DOWNING then
        ai:set_next_skill_id(skill)
        return 0
    end
    return 0
end

function character:ais_call_other_monster_by_group()
    local ai = self:get_ai()
    local cur_enemy_id = ai:get_cur_enemy_id()
    local cur_enemy = self:get_scene():get_obj_by_id(cur_enemy_id)
    if not cur_enemy then
        return 0
    end
    local group_id = self:get_group_id()
    local objs = self:get_view()
    for obj in pairs(objs) do
        if obj:get_obj_type() == "monster" then
            if obj:get_group_id() == group_id then
                local other_ai = obj:get_ai()
                if other_ai:get_cur_enemy_id() == define.INVAILD_ID then
                    other_ai:add_primary_enemy(cur_enemy:get_obj_id())
                    other_ai:to_approach_tar()
                end
            end
        end
    end
end

function character:get_game_flag_key(key)
	return 0
end

function character:ais_rand()
    return math.random(1, 100) - 1
end

function character:GetAIScriptTimes(id)
    return self:get_ai():GetAIScriptTimes(id)
end

function character:SetAIScriptTimes(id, times)
    self:get_ai():SetAIScriptTimes(id, times)
end

function character:show_skill_missed(selfId,targetid,skill_id,ogic_count,flag)
	if not selfId or selfId == -1 then
		return
	end
	local msg = packet_def.GCCharSkill_Missed.new()
	msg.reciver = selfId
	msg.sender = targetid or -1
	msg.flag = flag
	msg.skill_id = skill_id or -1
	msg.sender_logic_count = ogic_count or 0
	self:get_scene():broadcast(self, msg, true)
end

function character:show_buff_effect(selfId,targetid,skill_id,ogic_count,impact_id)
	if not targetid or targetid < 1 then
		return
	elseif not selfId or selfId < 1 then
		return
	elseif not impact_id or impact_id < 0 then
		return
	end
	local msg = packet_def.GCCharDirectImpact.new()
	msg.reciver = targetid
	msg.sender = selfId
	msg.skill_id = skill_id or -1
	msg.impact_id = impact_id
	msg.logic_count = ogic_count or 0
	self:get_scene():broadcast(self, msg, true)
end
function character:empty_all_control(control_empty_effect)
    local impacts = self:get_impact_list()
    for i = #impacts, 1, -1 do
        local imp = impacts[i]
		if impactenginer:is_impact_in_collection_ex(imp,control_empty_effect) then
            self:on_impact_fade_out(imp)
            self:remove_impact(imp)
        end
    end
end
-- function character:get_is_stealth_flag()
	-- return self:stealth_flag
-- end

-- function character:set_is_stealth_flag()
	-- if self:stealth_flag then
		-- self:stealth_flag = false
	-- else
		-- self:stealth_flag = true
	-- end
-- end

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


function character:soul_separated_kill_blindness(sender) -- [FIX]
    -- [FIX] 902 执掌黄泉：skill 811（魂离魄散）击杀目标后，按概率额外增加命魂拘获数
    if not sender or sender:get_obj_type() ~= "human" then return end
    local talent_config = configenginer:get_config("sect_desc")
    local talent = sender:get_talent()
    if not talent or not talent.study then return end
    for i = 1, #talent.study do
        local study_talent_id = talent.study[i].id
        if study_talent_id == 902 then
            local logic = talentenginer:get_logic_id(study_talent_id)
            if logic then
                local t_config = talent_config[study_talent_id]
                if t_config then
                    local lv = talent.study[i].level
                    lv = (lv == 0) and 1 or lv
                    local params = t_config.params[lv]
                    if params then
                        local chance = params[1] or 0
                        local bonus  = params[2] or 0
                        if chance > 0 and bonus > 0 and math.random(100) <= chance then
                            -- [FIX] 额外增加命魂拘获计数，供后续技能伤害加成判断使用
                            local skill_info = sender:get_skill_info()
                            if skill_info then
                                local cur = skill_info:get_consume_life_soul_count()
                                skill_info:set_consume_life_soul_count(cur + bonus)
                            end
                        end
                    end
                end
            end
            break
        end
    end
end

-- [FIX] 901 向死而生：skill 801击杀目标后，按概率回复施法者2%最大血量
function character:toward_death_kill_heal(sender)
    if not sender or sender:get_obj_type() ~= "human" then return end
    local talent_config = configenginer:get_config("sect_desc")
    local talent = sender:get_talent()
    if not talent or not talent.study then return end
    for i = 1, #talent.study do
        local study_talent_id = talent.study[i].id
        if study_talent_id == 901 then
            local logic = talentenginer:get_logic_id(study_talent_id)
            if logic then
                local t_config = talent_config[study_talent_id]
                if t_config then
                    local lv = talent.study[i].level
                    lv = (lv == 0) and 1 or lv
                    local params = t_config.params[lv]
                    if params then
                        local chance = params[1] or 0
                        if chance > 0 and math.random(100) <= chance then
                            local max_hp = sender:get_max_hp()
                            local recover_hp = math.ceil(max_hp * 2 / 100)
                            if recover_hp > 0 then
                                sender:health_increment(recover_hp, sender, false, nil)
                            end
                        end
                    end
                end
            end
            break
        end
    end
end

function character:get_obj_type()
    return "platform"
end

-- [audit 2026-09-10] Mac dinh an toan cho quai/tran thu: lualib/cy_four_combat goi cac ham chi human
-- moi co (get_menpai, get_xinfa, get_team_info, get_cy_four_resource, item_value, notify_tips) tren
-- moi obj dinh impact -> log "[OBJ_UPDATE] ... attempt to call a nil value (method 'get_menpai')".
-- human/pet dinh nghia ham rieng se ghi de cac mac dinh nay.
if character.get_menpai == nil then
    function character:get_menpai() return define.INVAILD_ID end
end
if character.get_xinfa == nil then
    function character:get_xinfa(_) return nil end
end
if character.get_team_info == nil then
    function character:get_team_info() return nil end
end
if character.get_cy_four_resource == nil then
    function character:get_cy_four_resource(_) return 0 end
end
if character.set_cy_four_resource == nil then
    function character:set_cy_four_resource(_, _) end
end
if character.item_value == nil then
    function character:item_value(_) return 0 end
end
if character.notify_tips == nil then
    function character:notify_tips(_) end
end

return character
