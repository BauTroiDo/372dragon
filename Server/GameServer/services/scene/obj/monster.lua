-- 怪物类模块
-- 继承自 character 类，实现游戏中的怪物对象
local skynet = require "skynet"
local class = require "class"
local define = require "define"
local packet_def = require "game.packet"
local configenginer = require "configenginer":getinstance()
local scriptenginer = require "scriptenginer":getinstance()
local ai_monster = require "scene.ai.monster"
local character = require "scene.obj.character"
local monster_db_attr = require "db.monster_attrib"
local db_impact = require "db.impact_data"
local monster = class("monster", character)

-- 构造函数
-- @param data 怪物初始化数据，包含 dataid、patrol_id、script_id 等属性
function monster:ctor(data)
	self.dataid = data.dataid  -- 怪物数据ID
    self.patrol_id = data.patrol_id or define.INVAILD_ID  -- 巡逻路径ID
    self.script_id = data.script_id  -- 脚本ID
    self.ai_script = data.ai_script  -- AI脚本
    self.respawn_time = data.respawn_time  -- 重生时间
    self.group_id = data.group_id  -- 怪物组ID
    self.active_time = data.active_time  -- 激活时间
    self.fight_with_npc_flag = 0  -- 是否与NPC战斗标志
    self.script_timer = nil  -- 脚本定时器
	self.interaction_type = data.interaction_type or 0  -- 交互类型
	self.need_skill = data.need_skill or -1  -- 需要的技能ID
	self.scene_params = {}  -- 场景参数
	self.update_top_timer = 1000  -- 更新伤害排行榜的计时器
	self.die_timer = nil  -- 死亡计时器
	self.is_top_monster = nil  -- 是否为排行榜怪物
	self.is_unconstrained_monster = nil  -- 是否为不受限怪物
    self.owners = setmetatable({}, {__mode = "kv"})  -- 怪物归属者列表（弱引用）
    self.db = monster_db_attr.new(self, data.db_attribs)  -- 怪物数据库属性
    self.impacts = db_impact.new()  -- 状态效果管理器
    self.impacts:set_obj(self)
    self:reset()  -- 重置怪物状态
end

-- 初始化怪物
function monster:init()
    self.super.init(self)  -- 调用父类初始化
    self.ai:on_init()  -- 初始化AI
end

-- 设置死亡计时器
-- @param timer 死亡倒计时时间
function monster:set_die_time(timer)
    self.die_timer = timer
end

-- 设置为排行榜怪物
function monster:set_top_monster()
    self.is_top_monster = true
end

-- 清除排行榜怪物标志
function monster:empty_top_monster()
    self.is_top_monster = nil
end

-- 更新怪物状态（每帧调用）
-- @param ... delta_time 时间增量
function monster:update(...)
	local scene = self:get_scene()
    local sceneid = scene:get_id()
    -- 主城中的怪物，如果不是不受限怪物或巡逻怪物，则不更新
    if define.MAIN_CITY[sceneid] then
        if not self.is_unconstrained_monster and not self:is_patrol_monster() then
            return
        end
    end
    local script_id = self:get_script_id()
    if script_id ~= define.INVAILD_ID and scriptenginer:have_function(script_id, "OnHeartBeat") then
        self.ai:call_ai_script("OnHeartBeat", self:get_obj_id(), ...)  -- 调用AI心跳脚本
    end
    --self.ai:call_ai_script("OnHeartBeat", self:get_obj_id(), ...)  -- 调用AI心跳脚本
    self:check_script_timer(...)  -- 检查脚本定时器
    self.super.update(self, ...)  -- 调用父类更新
	local delta_time = ...
	-- 如果是排行榜怪物，每秒更新一次伤害排行榜
	if self.is_top_monster then
		if self.update_top_timer <= delta_time then
			self.update_top_timer = self.update_top_timer + 1000
			scene:set_dmg_top_list(self:get_obj_id(),self:get_damage_member())
		else
			self.update_top_timer = self.update_top_timer - delta_time
		end
	end
	-- 检查死亡计时器
	if self.die_timer then
		if self.die_timer > delta_time then
			self.die_timer = self.die_timer - delta_time
		else
			self.die_timer = nil
			scene:delete_temp_monster(self)  -- 删除临时怪物
		end
	end
end

-- 检查脚本定时器
-- @param delta_time 时间增量
function monster:check_script_timer(delta_time)
    if self.script_timer then
        self.script_timer_step = self.script_timer_step or 0 + delta_time
        if self.script_timer_step >= self.script_timer then
            self.script_timer_step = 0
            self.ai:call_ai_script("OnCharacterTimer", self:get_obj_id(), self:get_model(), self.script_timer)
        end
    end
end

-- 获取AOI（感兴趣区域）模式
-- @return "m" 主城模式，"wm" 野外模式
function monster:get_aoi_mode()
    local id = self:get_scene():get_id()
    if define.MAIN_CITY[id] then
        return "m"  -- 主城模式
    else
        return "wm"  -- 野外模式
    end
end

-- 获取怪物组ID
-- @return 怪物组ID
function monster:get_group_id()
    return self.group_id
end

-- 获取激活时间
-- @return 激活时间
function monster:get_active_time()
    return self.active_time
end

-- 发送属性刷新消息
function monster:send_refresh_attrib()
    self.db:send_refresh_attrib()
end

-- 重置怪物状态
function monster:reset()
    self.cys_rewards_dispatched = nil
    self:set_attrib({occupant_guid = define.INVAILD_ID, team_occipant_guid = define.INVAILD_ID,raid_occipant_guid = define.INVAILD_ID})  -- 重置归属者
    self.damage_member_list = {}  -- 清空伤害成员列表
    self.misions_toggle = {}  -- 清空任务开关
    local config_info = configenginer:get_config("config_info")
    self.position_range = config_info.Monster.DefaultPositionRange  -- 设置位置范围
    self.respawn_pos = table.clone(self:get_world_pos())  -- 记录重生位置
    self.owner_drop_item_list = setmetatable({}, { __mode = "kv" })  -- 归属者掉落物品列表
    self.owners = setmetatable({}, {__mode = "kv"})  -- 归属者列表
    self:set_hp(self:get_max_hp())  -- 恢复满血
    self.ai = ai_monster.new()  -- 创建AI实例
    self.ai:init(self)  -- 初始化AI
end

-- 当对象进入视野时调用
-- @param obj 进入视野的对象
function monster:on_obj_enter_view(obj)
    self.super.on_obj_enter_view(self, obj)
end

-- 设置属性
-- @param ... 属性键值对
function monster:set_attrib(...)
    self.db:set_attrib(...)
end

-- 获取状态效果列表
-- @return 状态效果列表
function monster:get_impact_list()
    return self.impacts:get_list()
end

-- 获取详细属性
-- @return 详细属性表
function monster:get_detail_attribs()
    return self.db:get_detail_attribs()
end

-- 获取怪物名称
-- @return 怪物名称
function monster:get_name()
    return self.db:get_attrib("name")
end

-- 获取怪物模型ID
-- @return 模型ID
function monster:get_model()
    return self.db:get_attrib("model")
end

-- 获取脚本ID
-- @return 脚本ID
function monster:get_script_id()
    return self.script_id
end

-- 获取重生位置
-- @return 重生位置坐标
function monster:get_respawn_pos()
    local pos = self.respawn_pos
    if pos and pos.x ~= nil and pos.y ~= nil then
        return pos
    end
    local world_pos = self:get_world_pos()
    if world_pos and world_pos.x ~= nil and world_pos.y ~= nil then
        self.respawn_pos = table.clone(world_pos)
        return self.respawn_pos
    end
    skynet.loge("monster:get_respawn_pos invalid world_pos, obj_id =", self:get_obj_id(), "dataid =", self.dataid)
    return { x = 0, y = 0 }
end

-- 获取位置范围
-- @return 位置范围
function monster:get_pos_range()
    return self.position_range
end

-- 获取对象类型
-- @return "monster"
function monster:get_obj_type()
     return "monster"
end

-- 获取潜行等级
-- @return 潜行等级
function monster:get_stealth_level()
    return self.db:get_attrib("stealth_level")
end

-- 获取移动速度
-- @return 移动速度
function monster:get_speed()
    return self.db:get_attrib("speed")
end

-- 获取基础AI类型
-- @return AI类型
function monster:get_base_ai()
    return self.db:get_attrib("base_ai")
end

-- 获取AI脚本
-- @return AI脚本
function monster:get_ai_script()
    return self.ai_script
end

-- 获取攻击特征类型
-- @return 10（怪物类型）
function monster:get_attack_traits_type() return 10 end

-- 获取攻击动画时间
-- @return 攻击动画时间
function monster:get_attack_anim_time()
    return self.db:get_attrib("attack_anim_time")
end

-- 获取基础经验值
-- @return 基础经验值
function monster:get_base_exp()
    return self.db:get_attrib("base_exp")
end

-- 设置怪物组ID
-- @param id 怪物组ID
function monster:set_group_id(id)
    self.group_id = id
end

-- 获取怪物组ID
-- @return 怪物组ID
function monster:get_group_id()
    return self.group_id
end

-- 设置与NPC战斗标志
-- @param flag 是否与NPC战斗
function monster:set_fight_with_npc_flag(flag)
    self.fight_with_npc_flag = flag
end

-- 设置AI类型
-- @param ai_type AI类型
function monster:set_ai_type(ai_type)
    self.db:set_attrib({ base_ai = ai_type, ai_type = ai_type})
    if self.ai then
        self.ai:set_ai_type(ai_type)
    end
end

-- 设置AI脚本
-- @param ai_script AI脚本
function monster:set_ai_script(ai_script)
    self.ai_script = ai_script
end

-- 获取与NPC战斗标志
-- @return 是否与NPC战斗
function monster:get_fight_with_npc_flag()
    return self.fight_with_npc_flag
end

-- 设置脚本定时器
-- @param delta_time 定时器时间间隔
function monster:set_script_timer(delta_time)
	if delta_time and delta_time > 0 then
		self.script_timer = delta_time
	else
		self.script_timer = nil
	end
end

-- 默认事件处理
-- @param who 触发事件的对象
function monster:default_event(who)
    self:get_script_enginer():call(self:get_script_id(), "OnDefaultEvent", who,
                                   self:get_obj_id())
end

-- 事件请求处理
-- @param who 请求对象
-- @param ... 额外参数
function monster:event_request(who, ...)
    self:get_script_enginer():call(self:get_script_id(), "OnEventRequest", who,
                                   self:get_obj_id(), ...)
end

-- 获取AI类型
-- @return AI类型
function monster:get_ai_type() return self.db:get_attrib("ai_type") end

-- 判断是否为NPC
-- @return 是否为NPC
function monster:is_npc()
    return self.db:get_attrib("is_npc")
end

-- 判断是否为敌人
-- @param other 目标对象
-- @return 是否为敌人
function monster:is_enemy(other)
    if self:get_obj_id() == other:get_obj_id() then
        return false  -- 自己不是敌人
    end
    if self:get_reputation() == 0 then
        return false  -- 声望为0的不是敌人
    end
    if other:get_reputation() == self:get_reputation() then
        return false  -- 相同声望的不是敌人
    end
    if other:get_obj_type() == "monster" then
        if self:get_fight_with_npc_flag() == 0 then
            return false  -- 怪物之间不战斗（除非设置了标志）
        end
    end
    if other:get_obj_type() == "pet" then
        local owner = other:get_owner()
        if owner and owner:get_obj_id() == self:get_obj_id() then
            return false  -- 自己的宠物不是敌人
        end
        if owner == nil then
            return false  -- 无主宠物不是敌人
        end
        return self:is_enemy(owner)  -- 判断宠物主人是否为敌人
    end
    return self:is_enemy_camp(other)  -- 判断阵营是否为敌
end

-- 怪物死亡处理
-- @param ... 额外参数
function monster:on_die(...)
	if self.is_top_monster then
		self:get_scene():empty_dmg_top_monid()  -- 清空排行榜怪物ID
	end
    self.super.on_die(self, ...)  -- 调用父类死亡处理
    self:on_die_after(...)  -- 死亡后处理
end

-- 添加归属者掉落物品
-- @param obj 归属者对象
-- @param item 物品ID
function monster:add_owner_drop_item(obj, item)
    local list = self.owner_drop_item_list[obj] or {}
    table.insert(list, item)
    self.owner_drop_item_list[obj] = list
end

-- 修正归属者GUID
-- 根据伤害列表确定怪物的归属者
function monster:refix_occupant_guid()
    if self:get_occupant_guid() == define.INVAILD_ID
	and self:get_raid_occipant_guid() == define.INVAILD_ID
	and self:get_team_occipant_guid() == define.INVAILD_ID then
        local damage_list = {}
        -- 收集伤害列表
        for obj_guid, damage in pairs(self.damage_member_list) do
            table.insert(damage_list, { obj_guid = obj_guid, damage = damage })
        end
        if #damage_list > 0 then
            -- 按伤害从高到低排序
            table.sort(damage_list, function(l1, l2)
                return l1.damage > l2.damage
            end)
            -- 设置伤害最高的为归属者
            local attacker_obj_guid = damage_list[1].obj_guid
            local attacker = self:get_scene():get_obj_by_guid(attacker_obj_guid)
            if attacker then
                self:set_occipant_guid(attacker_obj_guid)
				local raid_id = attacker:get_raid_id()
				local team_id = attacker:get_team_id()
                self:set_team_occipant_guid(team_id)
				self:set_raid_occipant_guid(raid_id)
            end
        end
    end
end

-- 计算归属者列表
-- @return 队长, 归属者列表
function monster:caculate_owner_list()
    self.owners = {}
    local seen = {}
    local config_info = configenginer:get_config("config_info")
    local position = self:get_world_pos()
    local operate = {obj = self, x = position.x, y = position.y, radious = config_info.Human.CanGetExpRange}
    local nearbys = self:get_scene():scan(operate)  -- 扫描附近对象
    local team_leader
	local occupant_guid = self:get_occupant_guid()
	local team_occipant_guid = self:get_team_occipant_guid()
	local raid_occipant_guid = self:get_raid_occipant_guid()
	local kill_call = false
    -- 遍历附近玩家，确定归属者
    for _, n in ipairs(nearbys) do
        if n:get_obj_type() == "human" and not n:is_die() and not seen[n:get_guid()] then
            seen[n:get_guid()] = true
            if n:get_guid() == occupant_guid then
				table.insert(self.owners, n)  -- 归属者
                n:on_kill_object(self)  -- 调用击杀回调
				kill_call = true
				-- [FIX team-live 2026-09-17] 归属者本身就是队长时，原代码不会记录 team_leader，
				-- 于是 dispatch_exp 读到 exp_mode = 0（队伍分配模式失效），dispatch_good_bad 也整段不执行。
				-- 实测：exp_mode=1，队长击杀 -> 178/178（错）；队员击杀 -> 238/119（对）。
				if team_occipant_guid ~= define.INVAILD_ID and n.get_team_id and n:get_team_id() == team_occipant_guid then
					local owner_team_info = n.get_team_info and n:get_team_info()
					if owner_team_info and owner_team_info.is_leader and owner_team_info:is_leader() then
						team_leader = n
					end
				end
			elseif raid_occipant_guid ~= define.INVAILD_ID then
				if n:get_raid_id() == raid_occipant_guid then
					table.insert(self.owners, n)  -- 同副本成员
				end
			elseif team_occipant_guid ~= define.INVAILD_ID then
				if n:get_team_id() == team_occipant_guid then
					table.insert(self.owners, n)  -- 同队成员
					if n:get_team_info():is_leader() then
						team_leader = n  -- 记录队长
					end
				end
            end
        end
    end
	-- 如果归属者不在附近，也要调用击杀回调
	if not kill_call then
		local obj = self:get_scene():get_obj_by_guid(occupant_guid)
		if obj then
			obj:on_kill_object(self)
		end
	end
    return team_leader,self.owners
end

-- 死亡后处理
-- 分配经验、善恶值、好友度、掉落物品等
function monster:on_die_after()
    if self.cys_rewards_dispatched then return end
    self.cys_rewards_dispatched = true
    self:get_scene():after_monster_die(self)  -- 场景死亡后处理
    self:refix_occupant_guid()  -- 修正归属者
    local team_leader = self:caculate_owner_list()  -- 计算归属者列表
	if self:get_raid_occipant_guid() == -1 then
		self:dispatch_exp(self.owners, team_leader)  -- 分配经验
		self:dispatch_good_bad(team_leader, self.owners)  -- 分配善恶值
		self:dispatch_friend_point(self.owners)  -- 增加好友度
		self:dispatch_item_box(self.owners)  -- 分配掉落物品
		self:dispatch_kill_monster_count(self.owners)  -- 更新击杀计数
	end
    self.damage_member_list = {}  -- 清空伤害列表
end

-- 计算基础经验值
-- @param level 怪物等级
-- @param killer_level 击杀者等级
-- @param exp 基础经验
-- @return 计算后的经验值
function monster:caculate_base_exp(level, killer_level, exp)
    local exp_attenuation = self:get_scene():get_config_enginer():get_config(
                                "exp_attenuation")
    local delta = level - killer_level
    local rate = exp_attenuation[delta]  -- 根据等级差获取经验衰减率
    local config_info = configenginer:get_config("config_info")
    return math.ceil(exp * rate * config_info.Exp.ExpParam)
end

-- 分配经验值
-- @param owners 归属者列表
-- @param team_leader 队长
function monster:dispatch_exp(owners, team_leader)
    local base_exp = self:get_base_exp()
	local scene_exp_rate = self:get_scene():get_scene_exp_rate()
	if scene_exp_rate ~= 0 then
		scene_exp_rate = scene_exp_rate + 1
		base_exp = base_exp * scene_exp_rate  -- 应用场景经验倍率
	end
	if base_exp <= 0 then
		return
	end
    -- 单人击杀
    if #owners == 1 then
        local add_exp = self:caculate_base_exp(self:get_level(), owners[1]:get_level(), base_exp)
        local pet = owners[1]:get_pet()
        local pet_add_exp = 0
        if pet then
            pet_add_exp = self:caculate_base_exp(self:get_level(), pet:get_level(), base_exp)
        end
        owners[1]:add_exp(add_exp, pet_add_exp, true)
    -- 多人击杀
    elseif #owners > 1 then
        local exp_mode = 0
        local sharing_member = team_leader or owners[1]
        if sharing_member then
            local team_info = sharing_member:get_team_info()
            if team_info then
                exp_mode = team_info:get_exp_mode()  -- 获取队伍经验分配模式
            end
        end
        local occupant_guid = self:get_occupant_guid()
        local team_exp_rate = { 1.0, 0.65, 0.54, 0.50, 0.49, 0.48 }  -- 组队经验比例表（1~6人）
        local rate = team_exp_rate[math.min(#owners, 6)] or 0.48
        local exp = base_exp * rate  -- 计算每人经验
        for _, o in ipairs(owners) do
            local add = self:caculate_base_exp(self:get_level(), o:get_level(), exp)
            -- 根据经验分配模式调整经验
            if exp_mode == 1 then
                if o:get_guid() == occupant_guid then
                    add = add + add * (#owners - 1) / 3  -- 归属者获得额外经验
                else
                    add = add * 2 / 3  -- 其他成员经验减少
                end
            end
            local pet_add_exp = 0
             local pet = o:get_pet()
            if pet then
                pet_add_exp = self:caculate_base_exp(self:get_level(), pet:get_level(), exp)
            end
            o:add_exp(add, pet_add_exp, true)
        end
    end
end

-- 分配善恶值（带新手的队长获得额外善恶值）
-- @param team_leader 队长
-- @param owners 归属者列表
function monster:dispatch_good_bad(team_leader, owners)
    if team_leader then
        local config_info = configenginer:get_config("config_info")
        if team_leader:get_level() >= config_info.GoodBad.LevelNeeded then
            local vaild_newbie_member_count = 0
            local vaild_prentice_member_count = 0
            local MemberLevelLimit = config_info.GoodBad.MemberLevelLimit
            local MemberLevel = config_info.GoodBad.MemberLevel
            local GoodBadRadius = config_info.GoodBad.GoodBadRadius
            local LevelDis = config_info.GoodBad.LevelDis
            local BonusPerMember = config_info.GoodBad.BonusPerMember
            local BonusPerPrentice = config_info.GoodBad.BonusPerPrentice
            local leader_level = team_leader:get_level()
            -- 统计有效新手和徒弟数量
            for _, o in ipairs(owners) do
                if o ~= team_leader then
                    local level = o:get_level()
                    local diff = leader_level - level
                    if diff >= LevelDis then
                        local dist = self:get_scene():cal_dist(o:get_world_pos(), team_leader:get_world_pos())
                        if dist <= GoodBadRadius then
                            if level < MemberLevelLimit and level >= MemberLevel then
                                vaild_newbie_member_count = vaild_newbie_member_count + 1
                                if team_leader:is_prentice_relation(o) then
                                    vaild_prentice_member_count = vaild_prentice_member_count + 1
                                end
                            end
                        end
                    end
                end
            end
            -- 计算并添加善恶值
            local add_good_bad_value = vaild_newbie_member_count * BonusPerMember + vaild_prentice_member_count * BonusPerPrentice
            team_leader:add_good_bad_value(add_good_bad_value)
        end
    end
end

-- 分配好友度（好友之间互相增加好友度）
-- @param owners 归属者列表
function monster:dispatch_friend_point(owners)
    for i = 1, #owners do
        for j = i + 1, #owners do
            if owners[i]:is_friend_relation(owners[j]) and owners[j]:is_friend_relation(owners[i]) then
                owners[i]:inc_friend_point(owners[j])
                owners[j]:inc_friend_point(owners[i])
            end
        end
    end
end

-- 分配击杀怪物计数
-- @param owners 归属者列表
function monster:dispatch_kill_monster_count(owners)
    local owners_count = #owners
    local count = 1
    if owners_count > 1 then
        count = 1 / owners_count * 0.8  -- 多人击杀时计数减少
    end
    for _, owner in ipairs(owners) do
        owner:update_kill_monster_count(count)
    end
end

-- 计算掉落规则
-- @return 掉落物品列表
function monster:caculate_drop_ruler()
    local scene = self:get_scene()
    local item_drop_manager = scene:get_item_drop_manager()
    return item_drop_manager:caculate_drop_item_box(self:get_model())
end

-- 分配掉落物品箱
-- @param owners 归属者列表
function monster:dispatch_item_box(owners)
    -- 为每个归属者创建掉落物品箱
    for _, o in ipairs(owners) do
        if o:can_be_dispatch_item_box() then
            local drop_items = self:caculate_drop_ruler()
            self:add_drop_item(o, drop_items)
            if #drop_items > 0 then
                local conf = {}
                conf.owner_guid = o:get_guid()
                conf.monster_id = self:get_obj_id()
                conf.world_pos = self:get_world_pos()
                conf.drop_items = drop_items
                self:get_scene():create_item_box(conf)
            end
        end
    end

    -- 处理归属者专属掉落物品
    local owner_drop_item_list = {}
    for o in pairs(self.owner_drop_item_list) do
        table.insert(owner_drop_item_list, { owner = o, item_list = self.owner_drop_item_list[o]})
    end
    for i = #owner_drop_item_list, 1, -1 do
        local drop_items = {}
        local owner = owner_drop_item_list[i].owner
        self:add_drop_item(owner, drop_items)
        if #drop_items > 0 then
            local conf = {}
            conf.owner_guid = owner:get_guid()
            conf.monster_id = self:get_obj_id()
            conf.world_pos = self:get_world_pos()
            conf.drop_items = drop_items
            self:get_scene():create_item_box(conf)
        end
    end
end

-- 添加掉落物品到列表
-- @param o 归属者对象
-- @param drop_items 掉落物品列表
function monster:add_drop_item(o, drop_items)
    if self.owner_drop_item_list[o] then
        for _, itemid in ipairs(self.owner_drop_item_list[o]) do
            table.insert(drop_items, 1, { id = itemid, count = 1, drop_class = define.INVAILD_ID})
        end
    end
    self.owner_drop_item_list[o] = nil  -- 清空该归属者的掉落列表
end

-- 愤怒值增加（空实现）
function monster:rage_increment()

end

-- 设置归属者GUID
-- @param guid 归属者GUID
function monster:set_occipant_guid(guid)
    self:set_attrib({occupant_guid = guid})
end

-- 设置队伍归属者ID
-- @param team_id 队伍ID
function monster:set_team_occipant_guid(team_id)
    self:set_attrib({team_occipant_guid = team_id})
end

-- 设置副本归属者ID
-- @param raid_id 副本ID
function monster:set_raid_occipant_guid(raid_id)
    self:set_attrib({raid_occipant_guid = raid_id})
end

-- 获取归属者GUID
-- @return 归属者GUID
function monster:get_occupant_guid()
    return self:get_attrib("occupant_guid")
end

-- 获取队伍归属者ID
-- @return 队伍ID
function monster:get_team_occipant_guid()
    return self:get_attrib("team_occipant_guid")
end

-- 获取副本归属者ID
-- @return 副本ID
function monster:get_raid_occipant_guid()
    return self:get_attrib("raid_occipant_guid")
end

-- 获取归属者列表
-- @return 归属者列表
function monster:get_owners()
    return self.owners
end

-- 怪物受到伤害处理
-- @param damages 伤害数据
-- @param caster_obj_id 施法者对象ID
-- @param is_critical 是否暴击
-- @param skill_id 技能ID
-- @param imp 状态效果
function monster:on_damages(damages, caster_obj_id, is_critical, skill_id, imp)
    local scene = self:get_scene()
    local sender = scene:get_obj_by_id(caster_obj_id)
    
    if sender and sender:is_character_obj() then
        sender:on_damage_target(self, damages, skill_id, imp)  -- 通知施法者造成伤害
    end
    self:impact_on_damages(damages, caster_obj_id, is_critical, skill_id, imp)  -- 处理状态效果
	-- 检查免疫
	if damages.flag_immu then
		self:show_skill_missed(self:get_obj_id(),caster_obj_id,skill_id,self:get_logic_count(),define.MISS_FLAG.FLAG_IMMU)
		return
	elseif damages.imm_dmg_rate and damages.imm_dmg_rate >= 100 then
		self:show_skill_missed(self:get_obj_id(),caster_obj_id,skill_id,self:get_logic_count(),define.MISS_FLAG.FLAG_IMMU)
		return
	end
    character.on_damages(self, damages, caster_obj_id, is_critical, skill_id,imp)  -- 调用父类伤害处理
end

-- 记录怪物伤害（用于确定归属者）
-- @param hp_modify HP变化量（正数为受到的伤害）
-- @param sender 攻击者
function monster:back_monster_damage(hp_modify,sender)
    if hp_modify > 0 then
        local attacker = sender
        if attacker then
            local obj_type = attacker:get_obj_type()
            if obj_type == "human" or obj_type == "pet" then
                self.ai:add_hate(attacker:get_obj_id(), hp_modify)
                if attacker:get_obj_type() == "pet" then
                    attacker = attacker:get_owner()  -- 宠物伤害记在主人身上
                end
				local raid_id = attacker:get_raid_id()
				local team_id = attacker:get_team_id()
				local att_guid = attacker:get_guid()
                local his_damage = self.damage_member_list[att_guid] or 0
                his_damage = his_damage + hp_modify
                self.damage_member_list[att_guid] = his_damage
                -- 如果伤害超过怪物最大血量的10%，且没有归属者，则设置归属者
                if self:get_occupant_guid() == define.INVAILD_ID
				and self:get_raid_occipant_guid() == define.INVAILD_ID
				and self:get_team_occipant_guid() == define.INVAILD_ID then
                    if his_damage > self:get_max_hp() * 0.1 then
                        self:set_occipant_guid(att_guid)
                        self:set_team_occipant_guid(team_id)
                        self:set_raid_occipant_guid(raid_id)
                    end
                end
            end
        end
    end
end
-- function monster:gm_kill_obj(targetId)
    -- local sender = self:get_scene():get_obj_by_id(targetId)
	-- if sender then
		-- local hp_modify = self:get_attrib("hp")
		-- self:back_monster_damage(hp_modify,sender)
	-- end
	-- return character.gm_kill_obj(self,targetId)
-- end


-- function monster:health_increment(hp_modify, sender, is_critical_hit, imp)
    -- if hp_modify < 0 then
        -- local abs_damage = math.abs(hp_modify)
        -- if abs_damage > 0 then
            -- local attacker = sender
            -- if attacker then
                -- local obj_type = attacker:get_obj_type()
                -- if obj_type == "human" or obj_type == "pet" then
                    -- if attacker:get_obj_type() == "pet" then
                        -- attacker = attacker:get_owner()
                    -- end
                    -- local team_id = attacker:get_team_id()
					-- local att_guid = attacker:get_guid()
                    -- local his_damage = self.damage_member_list[attacker:get_obj_id()] or 0
                    -- his_damage = his_damage + abs_damage
                    -- self.damage_member_list[att_guid] = his_damage
                    -- local occupant_guid = self:get_occupant_guid()
                    -- local team_occupant_guid = self:get_team_occipant_guid()
                    -- if occupant_guid == define.INVAILD_ID and team_occupant_guid == define.INVAILD_ID then
                        -- if his_damage > self:get_max_hp() * 0.1 then
                            -- self:set_occipant_guid(att_guid)
                            -- self:set_team_occipant_guid(team_id)
                        -- end
                    -- end
                -- end
            -- end
        -- end
    -- end
    -- -- self.super.health_increment(self, hp_modify, sender, is_critical_hit, imp)
    -- character.health_increment(self, hp_modify, sender, is_critical_hit, imp)
-- end

-- 获取重生时间
-- @return 重生时间
function monster:get_respawn_time() return self.respawn_time end

-- 怪物重生
function monster:respawn()
    self.cys_rewards_dispatched = nil
    self:set_hp(self:get_max_hp())  -- 恢复满血
    self:set_world_pos(self:get_respawn_pos())  -- 移动到重生位置
    self:set_occipant_guid(define.INVAILD_ID)  -- 清空归属者
    self:set_team_occipant_guid(define.INVAILD_ID)
    self:set_raid_occipant_guid(define.INVAILD_ID)
    self.damage_member_list = {}  -- 清空伤害列表
    self.owner_drop_item_list = setmetatable({}, { __mode = "kv" })  -- 清空掉落列表
    self.owners = setmetatable({}, {__mode = "kv"})  -- 清空归属者列表
    self.misions_toggle = {}  -- 清空任务开关
    self.ai:respawn()  -- AI重生
end

-- 设置巡逻路径ID
-- @param id 巡逻路径ID
function monster:set_patrol_id(id)
    local patrol = self:get_scene():get_patrol_path_by_index(id)
    if patrol then
        self.patrol_id = id
        if self:is_patrol_monster() then
            self:get_ai():start_patrol()  -- 开始巡逻
        end
    end
end

-- 获取巡逻路径ID
-- @return 巡逻路径ID
function monster:get_patrol_id()
    return self.patrol_id
end

-- 判断是否为巡逻怪物
-- @return 是否为巡逻怪物
function monster:is_patrol_monster()
    return self.patrol_id >= 0
end

-- 设置魔法值（空实现）
function monster:set_mp()
end

-- 设置最大生命值
-- @param hp_max 最大生命值
function monster:set_hp_max(hp_max)
    assert(hp_max > 0)
    assert(hp_max < define.UINT32_MAX)
    self.db:set_db_attrib({ hp_max = hp_max})
end

-- 设置精神攻击力
-- @param mind_attack 精神攻击力
function monster:set_mind_attack(mind_attack)
    assert(mind_attack > 0)
    assert(mind_attack < define.UINT32_MAX)
    self.db:set_db_attrib({ mind_attack = mind_attack})
end

-- 设置命中属性
-- @param attrib_hit 命中值
function monster:set_attrib_hit(attrib_hit)
    assert(attrib_hit > 0)
    assert(attrib_hit < define.UINT32_MAX)
    self.db:set_db_attrib({ attrib_hit = attrib_hit})
end

-- 设置闪避属性
-- @param attrib_miss 闪避值
function monster:set_attrib_miss(attrib_miss)
    assert(attrib_miss > 0)
    assert(attrib_miss < define.UINT32_MAX)
    self.db:set_db_attrib({ attrib_miss = attrib_miss})
end

-- 设置物理攻击属性
-- @param attrib_att_physics 物理攻击值
function monster:set_attrib_att_physics(attrib_att_physics)
    assert(attrib_att_physics > 0)
    assert(attrib_att_physics < define.UINT32_MAX)
    self.db:set_db_attrib({ attrib_att_physics = attrib_att_physics})
end

-- 设置物理防御属性
-- @param attrib_def_physics 物理防御值
function monster:set_attrib_def_physics(attrib_def_physics)
    assert(attrib_def_physics > 0)
    assert(attrib_def_physics < define.UINT32_MAX)
    self.db:set_db_attrib({ attrib_def_physics = attrib_def_physics})
end

-- 设置魔法攻击属性
-- @param attrib_att_magic 魔法攻击值
function monster:set_attrib_att_magic(attrib_att_magic)
    assert(attrib_att_magic > 0)
    assert(attrib_att_magic < define.UINT32_MAX)
    self.db:set_db_attrib({ attrib_att_magic = attrib_att_magic})
end

-- 设置魔法防御属性
-- @param attrib_def_magic 魔法防御值
function monster:set_attrib_def_magic(attrib_def_magic)
    assert(attrib_def_magic > 0)
    assert(attrib_def_magic < define.UINT32_MAX)
    self.db:set_db_attrib({ attrib_def_magic = attrib_def_magic})
end

-- 设置冰属性攻击
-- @param att_cold 冰属性攻击值
function monster:set_att_cold(att_cold)
    assert(att_cold >= 0)
    assert(att_cold < define.UINT32_MAX)
    self.db:set_db_attrib({ att_cold = att_cold})
end

-- 设置冰属性防御
-- @param def_cold 冰属性防御值
function monster:set_def_cold(def_cold)
    assert(def_cold >= 0)
    assert(def_cold < define.UINT32_MAX)
    self.db:set_db_attrib({ def_cold = def_cold})
end

-- 设置火属性攻击
-- @param att_fire 火属性攻击值
function monster:set_att_fire(att_fire)
    assert(att_fire >= 0)
    assert(att_fire < define.UINT32_MAX)
    self.db:set_db_attrib({ att_fire = att_fire})
end

-- 设置火属性防御
-- @param def_fire 火属性防御值
function monster:set_def_fire(def_fire)
    assert(def_fire >= 0)
    assert(def_fire < define.UINT32_MAX)
    self.db:set_db_attrib({ def_fire = def_fire})
end

-- 设置雷属性攻击
-- @param att_light 雷属性攻击值
function monster:set_att_light(att_light)
    assert(att_light >= 0)
    assert(att_light < define.UINT32_MAX)
    self.db:set_db_attrib({ att_light = att_light})
end

-- 设置雷属性防御
-- @param def_light 雷属性防御值
function monster:set_def_light(def_light)
    assert(def_light >= 0)
    assert(def_light < define.UINT32_MAX)
    self.db:set_db_attrib({ def_light = def_light})
end

-- 设置毒属性攻击
-- @param att_poison 毒属性攻击值
function monster:set_att_poison(att_poison)
    assert(att_poison >= 0)
    assert(att_poison < define.UINT32_MAX)
    self.db:set_db_attrib({ att_poison = att_poison})
end

-- 设置毒属性防御
-- @param def_poison 毒属性防御值
function monster:set_def_poison(def_poison)
    assert(def_poison >= 0)
    assert(def_poison < define.UINT32_MAX)
    self.db:set_db_attrib({ def_poison = def_poison})
end

-- 获取属性值
-- @param attr 属性名
-- @return 属性值
function monster:get_attrib(attr)
    return self.db:get_attrib(attr)
end

-- 获取朝向
-- @return 朝向
function monster:get_dir()
    return self:get_attrib("dir")
end

-- 标记为不可破坏
function monster:mark_unbreakable_flag()
    self:set_attrib({ unbreakable = 1 })
end

-- 清除不可破坏标志
function monster:clear_unbreakable_flag()
    self:set_attrib({ unbreakable = 0 })
end

-- 设置临时阵营ID
-- @param id 阵营ID
function monster:set_temp_camp_id(id)
    self.db:set_db_attrib({ camp_id = id})
end

-- 创建新对象数据包（用于客户端同步）
-- @return 数据包对象
function monster:create_new_obj_packet()
    if self:is_moving() then
        -- 移动中的怪物数据包
        local msg = packet_def.GCNewMonster_Move.new()
        msg.m_objID = self:get_obj_id()
        msg.guid = self:get_model()
        msg.world_pos = self:get_world_pos()
        msg.dir = self:get_dir()
        msg.speed = self:get_speed()
        msg.handle = self.move.handle
        msg.path = self.move.targetPos
        return msg
    else
        -- 静止的怪物数据包
        local msg = packet_def.GCNewMonster.new()
        msg.guid = self:get_guid()
        msg.m_objID = self:get_obj_id()
        msg.dir = self:get_dir()
        msg.unknow_1 = 1656600794
        msg.unknow_10 = 2518342987
        msg.unknow_11 = 1190194235
        msg.unknow_12 = 955012720
        msg.unknow_13 = 65009746
        msg.unknow_15 = 2623905260
        msg.unknow_16 = 2705976078
        msg.unknow_17 = 2927752741
        msg.unknow_18 = 4194946202
        msg.speed = self:get_speed()
        msg.unknow_2 = 1149116311
        msg.unknow_20 = 1869628498
        msg.unknow_21 = 2696114389
        msg.unknow_22 = 2333910085
        msg.unknow_23 = 1643806583
        msg.unknow_24 = 8374
        msg.unknow_25 = {0, 0, 0, 0, 0, 0, 0, 0}
        msg.unknow_3 = 1111842826
        msg.unknow_4 = 622429864
        msg.unknow_6 = 290492800
        msg.unknow_7 = 38247240
        msg.unknow_8 = 537823071
        msg.unknow_9 = 1784045101
        msg.worldPos = table.clone(self:get_world_pos())
        return msg
    end
end

-- 设置创建时间
-- @param time 创建时间
function monster:set_create_time(time)
    self.create_time = time
end

-- 获取创建时间
-- @return 创建时间
function monster:get_create_time()
    return self.create_time
end

-- 状态效果消失时调用
-- @param imp 状态效果对象
function monster:on_impact_fade_out(imp)
    self.ai:call_ai_script("OnImpactFadeOut", self:get_obj_id(), imp:get_data_index())
    self.super.on_impact_fade_out(self, imp)
end

-- AI脚本接口：设置巡逻路径ID
-- @param patrol_id 巡逻路径ID
function monster:AIS_SetPatrolID(patrol_id)
    self:set_patrol_id(patrol_id)
end

-- AI脚本接口：设置基础AI类型
-- @param _ 未使用参数
-- @param _ 未使用参数
-- @param ai_type AI类型
function monster:AIS_SetBaseAIType(_, _, ai_type)
    self:set_ai_type(ai_type)
end

-- AI脚本接口：设置声望ID
-- @param reputation_id 声望ID
function monster:AIS_SetReputationID_CodingRefix(reputation_id)
    self:set_reputation(reputation_id)
end

-- AI脚本接口：设置与NPC战斗标志
-- @param flag 是否与NPC战斗
function monster:AIS_SetMonsterFightWithNpcFlag(flag)
    self:set_fight_with_npc_flag(flag)
end

-- 设置附近玩家列表
-- @param humans 玩家列表
function monster:set_near_humans(humans)
    self.near_humans = humans
end

-- 获取附近玩家列表
-- @return 玩家列表
function monster:get_near_humans()
    return self.near_humans
end

-- 获取进阶效果详情（空实现）
-- @param id 效果ID
-- @return 0
function monster:get_dw_jinjie_effect_details(id)
    return 0
end

-- 获取交互类型
-- @return 交互类型
function monster:get_interaction_type()
    return self.interaction_type
end

-- 获取需要的技能ID
-- @return 技能ID
function monster:get_need_skill()
    return self.need_skill
end

-- 获取伤害成员列表
-- @return 伤害成员列表
function monster:get_damage_member()
    return self.damage_member_list
end

-- 获取场景参数
-- @param index 参数索引
-- @return 参数值
function monster:get_scene_params(index)
	return self.scene_params[index] or 0
end

-- 设置场景参数
-- @param index 参数索引
-- @param value 参数值
function monster:set_scene_params(index,value)
	if not index then
		return
	end
	self.scene_params[index] = value
end

-- 设置为不受限怪物
-- @param value 是否为不受限怪物
function monster:set_unconstrained_monster(value)
	self.is_unconstrained_monster = value
end

return monster
