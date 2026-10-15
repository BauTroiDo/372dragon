local skynet = require "skynet"
local class = require "class"
local define = require "define"
local pet_guid = require "pet_guid"
local configenginer = require "configenginer":getinstance()
local actionenginer = require "actionenginer":getinstance()
local skillenginer = require "skillenginer":getinstance()
local ai_character = require "scene.ai.character"
local pet = class("pet", ai_character)
local BODYSTAYTIME = 5000
local REFOLLOW_DISTSQR_A = 9
local REFOLLOW_DISTSQR_B = 64
local REFOLLOW_DISTSQR_C = 400
local REFOLLOW_DISTSQR_TELEPORT = 900

function pet:init(...)
    self.super.init(self, ...)
    self:reset()
end

local REFOLLOW_TARGET_DIST = 1.5
local REFOLLOW_RESEND_DISTSQR = 0.04
local REFOLLOW_HEIGHT_TELEPORT = 3.0
local REFOLLOW_OWNER_MOVE_DISTSQR = 0.25

function pet:reset()
    self.skill_id = 0
    self.next_skill_id = define.INVAILD_ID
    self.ai_command = { type = define.E_COMMAND_TYPE.E_COMMAND_TYPE_INVALID }
    self.last_owner_pos = nil
    self.last_target_pos = nil
    self:change_state("idle")
end

function pet:calc_follow_pos(owner)
    local pos = owner:get_world_pos()
    if self.last_owner_pos then
        local dx = pos.x - self.last_owner_pos.x
        local dy = pos.y - self.last_owner_pos.y
        if dx * dx + dy * dy < REFOLLOW_OWNER_MOVE_DISTSQR then
            if self.last_target_pos then
                return self.last_target_pos
            end
        end
    end
    self.last_owner_pos = { x = pos.x, y = pos.y }
    local dir = owner:get_dir() - define.HALF_PI
    local x = pos.x + math.sin(dir) * REFOLLOW_TARGET_DIST
    local y = pos.y + math.cos(dir) * REFOLLOW_TARGET_DIST
    return { x = x, y = y }
end

function pet:baby_go(pos_tar)
    local target_pos = pos_tar
    if self.last_target_pos then
        local dx = target_pos.x - self.last_target_pos.x
        local dy = target_pos.y - self.last_target_pos.y
        if dx * dx + dy * dy < REFOLLOW_RESEND_DISTSQR then
            if not self:get_character():is_moving() then
                local cpos = self:get_character():get_world_pos()
                local cx = target_pos.x - cpos.x
                local cy = target_pos.y - cpos.y
                if cx * cx + cy * cy < REFOLLOW_RESEND_DISTSQR then
                    return
                end
            else
                return
            end
        else
            if self:get_character():is_moving() and dx * dx + dy * dy < 0.25 then
                return
            end
        end
    end
    self.last_target_pos = target_pos
    self:move_to_pos(target_pos)
end

function pet:baby_to_attack()
    self:change_state("combat")
end

function pet:baby_to_idle()
    self:change_state("idle")
    self:get_character():set_target_id(define.INVAILD_ID)
end

function pet:event_on_die()
    if self:get_character():is_die() then
        self:after_die()
        self.body_timer = BODYSTAYTIME
        self:change_state("dead")
    end
end

function pet:after_die()
    local character = self:get_character()
    local owner = character:get_owner()
    if owner then
        owner:impact_clean_all_impact_when_pet_dead(character:get_obj_id())
        character:impact_clean_all_impact_when_pet_dead(character:get_obj_id())
        -- 在 clean_up 前重刷 pet_detail 属性，清除兽魂扩展属性并发送给客户端
        local call_up_guid = owner:get_guid_of_call_up_pet()
        if call_up_guid and not call_up_guid:is_null() then
            local container = owner:get_pet_bag_container()
            local pet_detail = container:get_pet_by_guid(call_up_guid)
            if pet_detail then
                local pet_db = pet_detail.db
                -- 临时将 pet_attrib.pet 指向 pet_detail(get_obj_id()=nil → is_fighting=false)
                pet_db:set_pet(pet_detail)
                pet_db:item_effect_flush()
                pet_db:mark_all_attr_dirty()
                -- 恢复指向场景对象，send_refresh_attrib 需要场景对象的 get_scene/get_obj_id
                pet_db:set_pet(character)
                character.send_all = false
                character:send_refresh_attrib(false)
            end
        end
        owner:clean_up_pet()
        owner:set_current_pet_guid(pet_guid.new())
        owner:send_operate_result_msg(define.OPERATE_RESULT.OR_PET_DIE)
    end
end

function pet:ai_logic_idle(utime)
    local character = self:get_character()
    if character:get_creator() == nil then
    else
        if not character:is_moving() then
            self:process_skill_in_cache(false)
        end
        self:change_move_mode()
    end
end

function pet:change_move_mode()
    local character = self:get_character()
    local onwer = character:get_owner()
    if not onwer then return end
    local dist_sqr = self:calc_dist_sqrt_of_to_owner()
    local height_diff = math.abs((onwer:get_world_pos().z or 0) - (character:get_world_pos().z or 0))
    if height_diff > REFOLLOW_HEIGHT_TELEPORT then
        if character:can_move() then
            character:on_teleport(self:calc_follow_pos(onwer))
            character:set_move_mode(define.ENUM_MOVE_MODE.MOVE_MODE_WALK)
        end
        return
    end
    if dist_sqr > REFOLLOW_DISTSQR_TELEPORT then
        if character:can_move() then
            character:on_teleport(self:calc_follow_pos(onwer))
            character:set_move_mode(define.ENUM_MOVE_MODE.MOVE_MODE_WALK)
        end
        return
    end
    if dist_sqr > REFOLLOW_DISTSQR_B then
        character:set_move_mode(define.ENUM_MOVE_MODE.MOVE_MODE_SPRINT)
    elseif dist_sqr > REFOLLOW_DISTSQR_A then
        character:set_move_mode(define.ENUM_MOVE_MODE.MOVE_MODE_RUN)
    else
        character:set_move_mode(define.ENUM_MOVE_MODE.MOVE_MODE_WALK)
    end
    self:baby_go(self:calc_follow_pos(onwer))
end

function pet:calc_dist_sqrt_of_to_owner()
    local character = self:get_character()
    if character then
        local onwer = character:get_owner()
        if onwer then
            local delta_x = onwer:get_world_pos().x - character:get_world_pos().x
            local delta_y = onwer:get_world_pos().y - character:get_world_pos().y
            return delta_x * delta_x + delta_y * delta_y
        end
    end
    return 0
end

function pet:ai_logic_dead(utime)
    if self.body_timer then
        if self.body_timer > 0 then
            self.body_timer = self.body_timer - utime
        else
            self.body_timer = nil
            local character = self:get_character()
            character:get_scene():delete_obj(character)
            character:set_hp(character:get_max_hp())
            character:send_refresh_attrib()
            if self:get_character():is_can_relive() then
                local owner = self:get_character():get_owner()
                if owner then
                    owner:call_up_pet()
                end
            end
        end
    end
end

function pet:ai_logic_combat()
    local character = self:get_character()
    local owner = character:get_owner()
    if owner then
        if owner.get_cur_target_id and owner:get_cur_target_id() == define.INVAILD_ID then
            self:change_state("idle")
            character:set_target_id(define.INVAILD_ID)
            return
        end
        local delta_x = owner:get_world_pos().x - character:get_world_pos().x
        local delta_y = owner:get_world_pos().y - character:get_world_pos().y
        local dist_owner_sq = delta_x * delta_x + delta_y * delta_y
        if dist_owner_sq > REFOLLOW_DISTSQR_C then
            self:change_state("idle")
            character:set_target_id(define.INVAILD_ID)
            return
        end
    end
    if self:is_combat_over() then
        self:change_state("idle")
        character:set_target_id(define.INVAILD_ID)
        return
    end
    local target_id = character:get_target_id()
    local target_obj = target_id ~= define.INVAILD_ID and character:get_scene():get_obj_by_id(target_id)
    if not target_obj or not target_obj:is_alive() or target_obj:is_friend(character) then
        self:change_state("idle")
        character:set_target_id(define.INVAILD_ID)
        return
    end
    if not character:can_use_skill_now() then
        return
    end
    if character:is_moving() then
        return
    end
    if not self:process_skill_in_cache(true) then
        local pos_tar = target_obj:get_world_pos()
        self:use_skill(0, target_id, pos_tar.x, pos_tar.y)
    end
end

function pet:set_skill_param_in_cache(param)
    self.skill_param_in_cache = param
end

function pet:get_skill_param_in_cache()
    return self.skill_param_in_cache
end

function pet:push_command_use_skill(skill_id,id_tar, x, y, dir, guid_tar)
    local param = {
        skill_id = skill_id,
        id_tar = id_tar,
        pos_tar = { x = x, y = y},
        dir = dir,
        guid_tar = guid_tar
    }
    local character = self:get_character()
    if character:client_can_use_skill(skill_id) then
        self:set_skill_param_in_cache(param)
        return define.OPERATE_RESULT.OR_OK
    else
        local owner = character:get_owner()
        if owner and owner:get_obj_type() == "human" then
            return define.OPERATE_RESULT.OR_WARNING
        end
    end
end

function pet:get_impact_refix_skill_launch_rate(args)
    local character = self:get_character()
    return character:impact_refix_skill_launch_rate(args)
end

function pet:process_skill_in_cache(is_in_attack_state)
    local character = self:get_character()
    if not character:can_use_skill_now() then
        return false
    end
    local owner = character:get_owner()
    if owner == nil then
        return false
    end
    local skill_param = self:get_skill_param_in_cache()
    if skill_param then
        local ret = self:use_skill(skill_param.skill_id, skill_param.id_tar, skill_param.pos_tar.x, skill_param.pos_tar.y, skill_param.guid_tar)
        self:set_skill_param_in_cache(nil)
        if ret < 0 then
            owner:send_operate_result_msg(ret)
        end
        return true
    end
    local skill_cache = character:get_skill_cache()
    for i = #skill_cache, 1, -1 do
        local cache = skill_cache[i]
        local cool_down = character:is_skill_cool_down(cache)
        if cool_down then
            local template = skillenginer:get_skill_template(cache)
            if template == nil then
                return false
            end
            local operate_mode = template.operate_mode
            local type_of_skill = template.type_of_skill
            if is_in_attack_state then
                local rate = template.pet_rate_of_skill
                rate = rate == -1 and 100 or rate
                local pet_ai_stratety_table = configenginer:get_config("pet_ai_stratety_table")
                local ai_type = character:get_ai_type()
                if type_of_skill == define.INVAILD_ID then
                    type_of_skill = 1
                end
                print("type_of_skill =", type_of_skill, ";ai_type =", ai_type)
                local launch_rate = pet_ai_stratety_table[type_of_skill][ai_type]
                local luanch_rate_refix_args = { id = cache, value = launch_rate}
                self:get_impact_refix_skill_launch_rate(luanch_rate_refix_args)
                local use_skill_rate = rate * luanch_rate_refix_args.value
                if math.random(100) < use_skill_rate then
                    if define.PET_SKILL_OPERATEMODE.PET_SKILL_OPERATE_AISTRATEGY == operate_mode and (define.PET_TYPE_AISKILL.PET_TYPE_AISKILL_PHYSICATTACK == type_of_skill or define.PET_TYPE_AISKILL.PET_TYPE_AISKILL_MAGICATTACK == type_of_skill) then
                        local obj_tar = character:get_scene():get_obj_by_id(character:get_target_id())
                        if obj_tar == nil or not obj_tar:is_alive() then
                            character:set_target_id(define.INVAILD_ID)
                            return false
                        end
                        local pos_tar = obj_tar:get_world_pos()
                        local result = self:use_skill(cache, obj_tar:get_obj_id(), pos_tar.x, pos_tar.y)
                        if result == define.OPERATE_RESULT.OR_OK then
                            return true
                        end
                    end
                end
            end
            --print("operate_mode =", operate_mode)
            if define.PET_SKILL_OPERATEMODE.PET_SKILL_OPERATE_INCEACEATTR == operate_mode then
                local pos_tar = character:get_world_pos()
                local result = self:use_skill(cache, character:get_obj_id(), pos_tar.x, pos_tar.y)
                if result == define.OPERATE_RESULT.OR_OK then
                    table.remove(skill_cache, i)
                    return true
                end
            end
            if define.PET_SKILL_OPERATEMODE.PET_SKILL_OPERATE_AISTRATEGY == operate_mode then
                if define.PET_TYPE_AISKILL.PET_TYPE_AISKILL_PROTECTEOWNER == type_of_skill then
                    local have_impact = owner:impact_have_impact_of_specific_impact_id(template.impact_id_of_skill)
                    if not have_impact then
                        local pos_tar = owner:get_world_pos()
                        local result = self:use_skill(cache, pos_tar.x, pos_tar.y)
                        if define.OPERATE_RESULT.OR_OK == result then
                            return true
                        end
                    end
                end
            end
        end
    end
    return false
end

function pet:is_combat_over()
    local character = self:get_character()
    local creator = character:get_creator()
    if creator == nil then
        --skynet.error("[DBG_PET] is_combat_over: reason=creator_nil")
        return true
    end
    if creator:get_attrib("stealth_level") > 0 then
        --skynet.error("[DBG_PET] is_combat_over: reason=stealth")
        return true
    end
    local target_id = character:get_target_id()
    if target_id ~= define.INVAILD_ID then
        local obj = character:get_scene():get_obj_by_id(target_id)
        if obj and obj:is_character_obj() and not obj:is_friend() then
            if not obj:is_can_view(creator) then
                --skynet.error("[DBG_PET] is_combat_over: reason=target_not_visible")
                return true
            end
            local dist_x = obj:get_world_pos().x - character:get_world_pos().x
            local dist_y = obj:get_world_pos().y - character:get_world_pos().y
            local dist_sq = dist_x * dist_x + dist_y * dist_y
            if dist_sq > define.REFOLLOW_DISTSQR_C then
                --skynet.error("[DBG_PET] is_combat_over: reason=target_too_far, dist_sq=", dist_sq)
                return true
            end
        end
    end
    --skynet.error("[DBG_PET] is_combat_over: result=false, target_id=", character:get_target_id())
    return false
end

function pet:on_relive_info_changed()
    if self:get_character():is_can_relive() then
    end
end

function pet:relive(is_skill_relive)
    local relive_info = self:get_character():get_relive_info(is_skill_relive)
    if relive_info then
        if relive_info.hp_recover_rate then
            local hp = math.floor(self:get_character():get_max_hp() * relive_info.hp_recover_rate)
            self:get_character():set_hp(hp)
        end
    end
    if self:get_character():get_hp() <= 0 then
        self:get_character():set_hp(1)
    end
    self:get_character():clear_skill_relive_info()
    self:change_state("idle")
end

--local orig_change_state = pet.change_state
--function pet:change_state(new_state)
    --local cur = self.state and self.state:get_state_name() or "unknown"
    --skynet.error("[DBG_PET] change_state: ", cur, " -> ", new_state)
    --return orig_change_state(self, new_state)
--end

return pet
