local inventory_guard = require "cys_inventory_guard"
-- 引入必要的模块和依赖
local skynet = require "skynet"           -- Skynet框架
local gbk = require "wire_charset"                 -- GBK编码处理
local profile = require "skynet.profile"  -- 性能分析
local define = require "define"           -- 游戏常量定义
local menpai_registry = require "menpai_registry"
local class = require "class"             -- 类定义模块
local utils = require "utils"             -- 工具函数
local impactenginer = require "impactenginer":getinstance()      -- 效果引擎
local configenginer = require "configenginer":getinstance()      -- 配置引擎
local actionenginer = require "actionenginer":getinstance()      -- 动作引擎
local skillenginer = require "skillenginer":getinstance()       -- 技能引擎
local talentenginer = require "talentenginer":getinstance()      -- 天赋引擎
local petmanager = require "petmanager":getinstance()           -- 宠物管理器
local shopenginer = require "shopenginer":getinstance()         -- 商店引擎
local human_item_logic = require "human_item_logic"              -- 玩家物品逻辑
local packet_def = require "game.packet"                         -- 数据包定义
local team_info_cls = require "teaminfo"                         -- 队伍信息类
local raid_info_cls = require "raidinfo"                         -- 副本信息类
local exchange_box_cls = require "exchange_box"                  -- 交换箱类
local Item_cls = require "item"                                  -- 物品类
local pet_guid = require "pet_guid"                              -- 宠物GUID
local shop_guid = require "shop_guid"                            -- 商店GUID
local item_container = require "item_container"                  -- 物品容器
local pet_container = require "pet_container"                    -- 宠物容器
local stall_bax = require "stallbox"                             -- 摆摊箱
local human_bag_container = require "human_bag_container"        -- 玩家背包容器
local attacker_or_pk_delaction_list = require "attacker_or_pk_delaction_list"  -- 攻击者/PK声明列表
local wild_war_guilds = require "wild_war_guilds"                -- 野外战帮派
local human_db_attr = require "db.human_attrib"                   -- 玩家数据库属性
local exterior_bonus = require "exterior_bonus"                  -- 外观属性加成
local equip_dress_bonus = require "equip_dress_bonus"
local pet_detail = require "pet_detail"                         -- 宠物详情
local db_impact = require "db.impact_data"                       -- 数据库效果数据
local menpai_logic = require "menpai"                            -- 门派逻辑
local ai_human = require "scene.ai.human"                        -- 玩家AI
local character = require "scene.obj.character"                   -- 角色基类
local human = class("human", character)  -- 定义玩家类，继承自角色类

-- 玩家构造函数
-- @param data 玩家初始化数据
function human:ctor(data)
    self.cy_four_resources = require("cy_four_combat.storage").load(data.cy_four_resources)
    self.game_flag = data.game_flag  -- 游戏标志位
	-- self.update_world_data_tick = 1000  -- 更新世界数据的时间间隔（已注释）
	self.check_item_time = math.random(60000,120000)  -- 检查物品有效性的随机时间（60-120秒）
	self.player_tick = 5000  -- 玩家心跳时间间隔（5秒）
	self.restore_hp_tick = 0  -- 恢复生命值计时器
	self.restore_hp_rate = 0  -- 恢复生命值速率
	self.restore_hp_value = 0  -- 恢复生命值数量
	self.restore_hp_reset_time = 0  -- 恢复生命值重置时间
    self.xinfa_list = data.xinfa_list  -- 心法列表
    -- CYS-POWER-SYSTEMS: state persists independently of equipment and derived attributes.
    self.cys_shending=require("cys_shending").init(data.cys_shending)
    self.cys_shending_revision=math.random(1,2147483646)
    self.xiulian_list = data.xiulian_list  -- 修炼列表
    self.skill_list = data.skill_list  -- 技能列表
    self.cys_assist = data.cys_assist -- CYS-ASSIST storage: active state is never persisted.
    self.talent = data.talent  -- 天赋数据
    self.ability_list = data.ability_list  -- 生活技能列表
    self.prescriptions = data.prescriptions  -- 配方数据
    self.setting = data.setting  -- 玩家设置
    self.relation_list = data.relation or {}  -- 关系列表
    self.agent = data.agent  -- 玩家代理
	-- 初始化外观数据
	if data.exterior then
		self.exterior = data.exterior
		if not self.exterior.poss then
			self.exterior.poss = {}  -- 姿态列表
		end
		if not self.exterior.headinfo then
			self.exterior.headinfo = {}  -- 头饰信息
		end
		if not self.exterior.backinfo then
			self.exterior.backinfo = {}  -- 背饰信息
		end
		if not self.exterior.weapon_visuals then
			self.exterior.weapon_visuals = {}  -- 武器外观
		end
	else
		self.exterior = {headinfo = {},backinfo = {},poss = {},weapon_visuals = {}}
	end
			--[id] = (exp << 16) | (lv << 8) | id  -- 物品ID编码格式
			--[equip point] = {id = id,finedraw = finedraw}  -- 装备点数据格式
	   -- self.dw_jinjie = data.dw_jinjie or {features = {},effect = {}}  -- 进阶数据（已注释）
	   self.dw_jinjie = data.dw_jinjie or {features = {}}  -- 进阶数据
	self.dw_jinjie.effect = {}  -- 进阶效果
	   self.fashion_bag_list = data.fashion_bag_list  -- 时装背包列表
	   self.chedifulu_data = data.chedifulu_data  -- 彻地符数据
	   self.double_exp_info = data.double_exp_info  -- 双倍经验信息
	   self.huanhun = data.huanhun or {}  -- 幻魂数据
	   self:set_char_shop_guids(data.shop_guids or {})  -- 设置商店GUID
	   self.titles = data.titles or {}  -- 称号列表
	   self.id_titles = data.id_titles or {}  -- ID称号列表
	   self.mission_data = data.mission_data  -- 任务数据
	   self.dungeonsweep = data.dungeonsweep  -- 副本扫荡数据
	   self.week_active = data.week_active  -- 周活跃度数据
	self.limit_shop = self.limit_shop or {}  -- 限购商店数据
	   self.mystery_shop_info = data.mystery_shop_info or {}  -- 神秘商店信息
	   self.jiyuan_shop_info = data.jiyuan_shop_info or {}  -- 祭元商店信息
	   self.wanshige_shop_info = data.wanshige_shop_info or {}  -- 万事阁商店信息
	   self.rmb_chat_face_info = data.rmb_chat_face_info or { id = 0, dates = {0, 0, 0, 0}}  -- 人民币聊天表情信息
	   self.attackers_list = attacker_or_pk_delaction_list.new(data.attackers_list)
	   self.pk_declaration_list = attacker_or_pk_delaction_list.new(data.pk_declaration_list)  -- PK声明列表
	   self.wild_war_guilds = wild_war_guilds.new()  -- 野外战帮派
	   self.ai = ai_human.new()  -- 玩家AI
	   self.shop = nil  -- 当前商店
	   self.guid_of_call_up_pet = pet_guid.new()  -- 召唤宠物的GUID
	   self.attr_msg_to_team_inteval_count = 0  -- 属性消息发送间隔计数
	   self.begin_send_refresh_attrib = false  -- 开始发送刷新属性标志
	   self.ai:init(self)  -- 初始化AI
	   self:reset_ability_opera()  -- 重置生活技能操作
	   self:init_equip_continer(data)  -- 初始化装备容器
	   self:init_pet_container(data)  -- 初始化宠物容器
	   self.db = human_db_attr.new(self, data.lv1_attrib, data.attrib)  -- 初始化数据库属性
	   -- self.db:init()  -- 初始化数据库（已注释）
	   self.impacts = db_impact.new()  -- 初始化效果数据
	   self.impacts:set_obj(self)  -- 设置效果对象
	   self.impacts:init_from_db_data(data)  -- 从数据库数据初始化效果
	   -- print("human:ctor aaaa")  -- 调试输出（已注释）
	   self:init_contaioners(data)  -- 初始化容器
    -- CYS-FORGE 23/09 recover a charged unfinished attempt after reload.
    require("cys_forge").recover(self,data.cys_forge)
	   -- print("human:ctor bbbb")  -- 调试输出（已注释）
	   self.team_info = team_info_cls.new(self)  -- 初始化队伍信息
	self.raid_info = raid_info_cls.new(self)  -- 初始化副本信息
	   self.stall_box = stall_bax.new()  -- 初始化摆摊箱
	   self.stall_box:init(self)  -- 初始化摆摊箱
	   -- print("human:ctor cccc")  -- 调试输出（已注释）
	   self.exchange_box = exchange_box_cls.new()  -- 初始化交换箱
	   self.exchange_box:init(self)  -- 初始化交换箱
	   self:fix_skills()  -- 修复技能数据
	   self:fix_prescription()  -- 修复配方数据
	   self:fix_abilitys()  -- 修复生活技能数据
	   self:fix_mission_flag()  -- 修复任务标志
	   self:fix_mission_data()  -- 修复任务数据
	   -- print("human:ctor dddd")  -- 调试输出（已注释）
	   self:fix_mission_data_ex()  -- 修复扩展任务数据
	   self:fix_dungeonsweep()  -- 修复副本扫荡数据
	   self:fix_week_active()  -- 修复周活跃度数据
	   self:fix_talent()  -- 修复天赋数据
	   self:fix_xiulian_list()  -- 修复修炼列表
	   self:fix_id_titles()  -- 修复ID称号
	   self:fix_titles()  -- 修复称号
	   self:fix_exterior_ranse()  -- 修复外观染色
	   self:fix_pk_mode_change_times()  -- 修复PK模式切换时间
	   self:fix_cool_down_times()  -- 修复冷却时间
	   self:fix_impact_continuance()  -- 修复效果持续时间
	   self.db:init()  -- 初始化数据库
	   self:check_cur_title_have()  -- 检查当前称号是否存在
	   local r, err = pcall(self.talent_on_active, self)  -- 激活天赋
	   if not r then
	       skynet.loge("talent_on_active error =", err)  -- 记录错误日志
	   end
	   -- print("human:ctor finish")  -- 调试输出（已注释）
end

-- 修复PK模式切换时间
function human:fix_exterior_poss_mode()
    local exterior_pet_soul_id = self.db:get_db_attrib("exterior_pet_soul_id") or 0
    if exterior_pet_soul_id <= 0 then
        return
    end
    for _, poss in ipairs(self.exterior.poss or {}) do
        if poss.id == exterior_pet_soul_id then
            return
        end
    end

    local equip_pet_soul_id = 0
    local soul_melting_pet_guid = self.db:get_attrib("soul_melting_pet_guid")
    if soul_melting_pet_guid and not soul_melting_pet_guid:is_null() then
        local pet_detail = self:get_pet_bag_container():get_pet_by_guid(soul_melting_pet_guid)
        local exterior_poss = configenginer:get_config("exterior_poss")[exterior_pet_soul_id]
        local models = exterior_poss and exterior_poss.models
        if pet_detail and models then
            local equip_model = pet_detail:get_pet_soul_melting_model()
            for i = 1, 3 do
                if models[i] == equip_model then
                    equip_pet_soul_id = exterior_pet_soul_id
                    break
                end
            end
        end
    end
    self.db:set_db_attrib({
        exterior_pet_soul_id = 0,
        exterior_equip_pet_soul_id = equip_pet_soul_id,
    })
end

function human:fix_pk_mode_change_times()
	self:fix_exterior_poss_mode()
	local limit_pk_mode = define.LIMIT_PK_MODE_ON_SCENE[self:get_scene_id()]  -- 获取场景限制的PK模式
	if limit_pk_mode then
        self.db:set_db_attrib_nil("want_change_pk_mode")  -- 清除想要切换PK模式的标志
        self.db:set_db_attrib_nil("change_pk_mode_delay")  -- [audit 2026-09-03] key = nil trong table constructor khong xoa duoc
        self.db:set_db_attrib({ pk_mode = limit_pk_mode.pk_id })  -- 设置为场景限制的PK模式
		-- local msg = string.format("该场景只允许%s模式。",limit_pk_mode.pk_name)  -- 提示消息（已注释）
		-- self:notify_tips(msg)  -- 发送提示（已注释）
	else
		local now = os.time()  -- 当前时间
		local logout_time = self:get_logout_time()  -- 登出时间
		local diff = now - logout_time  -- 时间差
		self:check_pk_mode_can_change(diff * 1000)  -- 检查PK模式是否可以切换
	end
end

-- 修复冷却时间
function human:fix_cool_down_times()
    local now = os.time()  -- 当前时间
    local logout_time = self:get_logout_time()  -- 登出时间
    local diff = now - logout_time  -- 时间差
    self:update_cool_down(diff * 1000)  -- 更新冷却时间
end

-- 修复效果持续时间
function human:fix_impact_continuance()
    local now = os.time()  -- 当前时间
    local logout_time = self:get_logout_time()  -- 登出时间
    local diff = now - logout_time  -- 时间差
    if diff > 0 then
        local impactenginer = self:get_scene():get_impact_enginer()  -- 获取效果引擎
        local delta_time = diff * 1000  -- 时间差（毫秒）
        local list = self:get_impact_list()  -- 获取效果列表
        for _, imp in ipairs(list) do
            if imp:is_counter_when_offline() then  -- 如果效果在离线时继续计算
                local logic = impactenginer:get_logic(imp)  -- 获取效果逻辑
                if logic then
                    if (self:is_unbreakable() and imp:get_stand_flag() == define.ENUM_BEHAVIOR_TYPE.BEHAVIOR_TYPE_HOSTILITY) then
                        -- 如果处于无敌状态且效果为敌对行为，则不处理
                    else
                        logic:heart_beat(imp, self, delta_time)  -- 执行效果心跳
                    end
                end
            end
        end
    end
end

-- 修复外观染色数据
function human:fix_exterior_ranse()
    if not self.exterior.ranse then
        self.exterior.ranse = {}  -- 初始化染色数据
        for i = 1, 50 do
            self.exterior.ranse[i] = { 0, 0, 0 }  -- 每个部位3个颜色值
        end
    end
end


-- 修复ID称号数据
function human:fix_id_titles()
    self.id_titles = self.id_titles or {}  -- 确保ID称号列表存在
end

-- 修复称号数据
function human:fix_titles()
    for i, title in ipairs(self.titles) do
        if title.id == define.INVAILD_ID then  -- 移除无效的称号
            table.remove(self.titles, i)
        end
    end
end

-- 修复技能数据
function human:fix_skills()
    do
        local skill_id = 43  -- 基础技能ID
        if not self:have_skill(skill_id) then
            self:add_skill(skill_id)  -- 添加基础技能
        end
    end
end

-- 修复配方数据
function human:fix_prescription()
    do
        local pres_id = 398  -- 配方ID
        if not self:is_prescription_have_learnd(pres_id) then
            self:study_prescription(pres_id, 1)  -- 学习配方
        end
    end
    do
        local pres_id = 558  -- 配方ID
        if not self:is_prescription_have_learnd(pres_id) then
            self:study_prescription(pres_id, 1)  -- 学习配方
        end
    end
    do
        local pres_id = 559  -- 配方ID
        if not self:is_prescription_have_learnd(pres_id) then
            self:study_prescription(pres_id, 1)  -- 学习配方
        end
    end
    do
        local pres_id = 560  -- 配方ID
        if not self:is_prescription_have_learnd(pres_id) then
            self:study_prescription(pres_id, 1)  -- 学习配方
        end
    end
end

-- 修复生活技能数据
function human:fix_abilitys()
    do
        local ability_id = 26  -- 生活技能ID
        if not self:have_ability(ability_id) then
            self:study_ability(ability_id, 0, 1)  -- 学习生活技能
        end
    end
    do
        local ability_id = 51  -- 生活技能ID
        if not self:have_ability(ability_id) then
            self:study_ability(ability_id, 0, 1)  -- 学习生活技能
        end
    end
end

-- 修复天赋数据
function human:fix_talent()
    if not self.talent then
        self.talent = {
            type = define.INVAILD_ID,  -- 天赋类型
            understand_point = 0,  -- 领悟点数
            study = {  -- 学习列表
            }
        }
        for i = 1, 21 do
            table.insert(self.talent.study, { id = define.INVAILD_ID, level = 0})  -- 初始化21个天赋槽位
        end
    end
	if #self.talent.study < 21 then  -- 如果天赋槽位不足21个
		for i = #self.talent.study + 1,21 do
            table.insert(self.talent.study, { id = define.INVAILD_ID, level = 0})  -- 补充槽位
		end
	end
    -- 标记特定任务为已完成
    do
        local id_mission = 2025  -- 任务ID
        local index = (id_mission >> 5) + 1  -- 计算索引
        self.mission_data.mission_have_done_flags[index] = (self.mission_data.mission_have_done_flags[index] or 0) | (0x00000001 << (id_mission & 0x0000001F))  -- 设置完成标志
    end
    do
        local id_mission = 2080  -- 任务ID
        local index = (id_mission >> 5) + 1
        self.mission_data.mission_have_done_flags[index] = (self.mission_data.mission_have_done_flags[index] or 0) | (0x00000001 << (id_mission & 0x0000001F))
    end
    do
        local id_mission = 2211  -- 任务ID
        local index = (id_mission >> 5) + 1
        self.mission_data.mission_have_done_flags[index] = (self.mission_data.mission_have_done_flags[index] or 0) | (0x00000001 << (id_mission & 0x0000001F))
    end
    do
        local id_mission = 2359  -- 任务ID
        local index = (id_mission >> 5) + 1
        self.mission_data.mission_have_done_flags[index] = (self.mission_data.mission_have_done_flags[index] or 0) | (0x00000001 << (id_mission & 0x0000001F))
    end
end

-- 修复副本扫荡数据
function human:fix_dungeonsweep()
    local dungeonsweep = self.dungeonsweep or {}
    dungeonsweep.sweep_counts = dungeonsweep.sweep_counts or {}
    dungeonsweep.campaign_counts = dungeonsweep.campaign_counts or {}
    dungeonsweep.sec_kill_data = dungeonsweep.sec_kill_data or { item_list = {} }
    dungeonsweep.sec_kill_data.item_list = dungeonsweep.sec_kill_data.item_list or {}
    -- 已结算且没有待处理奖励的旧记录不应在重新登录后继续显示“扫荡中”。
    if #dungeonsweep.sec_kill_data.item_list == 0
        and dungeonsweep.sec_kill_data.have_next ~= 1 then
        dungeonsweep.sec_kill_data = { item_list = {} }
    end
    self.dungeonsweep = dungeonsweep
end

-- 修复周活跃度数据
function human:fix_week_active()
    local week_active = self.week_active or {}
    week_active.can_get = week_active.can_get or {}
    week_active.getd = week_active.getd or {}
    week_active.activity_finish_count = week_active.activity_finish_count or {}
    local active_config = configenginer:get_config("week_active") or {}
    for i = 1, 0x2A do
        local configs = active_config[i] or {}
        local raw_progress = math.max(0, math.floor(tonumber(week_active.can_get[i]) or 0))
        local finish_count = math.max(
            0, math.floor(tonumber(week_active.activity_finish_count[i]) or 0))
        local max_target = configs[#configs] and configs[#configs].target or 0

        -- Older saves packed completed stages into bytes. Prefer the separately
        -- persisted real count, and decode the old value only when necessary.
        if raw_progress > max_target and #configs > 0 then
            local legacy_progress = 0
            for index, active in ipairs(configs) do
                local legacy_flag = (raw_progress >> ((index - 1) * 8)) & 0xFF
                if legacy_flag ~= 0 then
                    legacy_progress = math.max(legacy_progress, active.target)
                end
            end
            finish_count = math.max(finish_count, legacy_progress)
        else
            finish_count = math.max(finish_count, raw_progress)
        end
        week_active.activity_finish_count[i] = finish_count
        week_active.can_get[i] = finish_count

        local claimed = math.max(0, math.floor(tonumber(week_active.getd[i]) or 0))
        if claimed > #configs and #configs > 0 then
            local legacy_claimed = 0
            for index = 1, #configs do
                if ((claimed >> ((index - 1) * 8)) & 0xFF) ~= 0 then
                    legacy_claimed = index
                end
            end
            claimed = legacy_claimed
        end
        week_active.getd[i] = math.min(#configs, claimed)
    end
    week_active.day_get = math.max(0, math.floor(tonumber(week_active.day_get) or 0))
    week_active.week_get = math.max(0, math.floor(tonumber(week_active.week_get) or 0))
    week_active.get_award_index = math.min(10, math.max(
        0, math.floor(tonumber(week_active.get_award_index) or 0)))
    self.week_active = week_active
end

-- 修复任务标志
function human:fix_mission_flag()
    local mission_flag = self.mission_data.mission_flag or {}
    self.mission_data.mission_flag = mission_flag  -- 确保任务标志存在
end

-- 修复任务数据
function human:fix_mission_data()
    local mission_datas = self.mission_data.mission_datas
    for i = #mission_datas, define.MAX_CHAR_MISSION_DATA_NUM do
        mission_datas[i] = mission_datas[i] or 0  -- 填充任务数据
    end
end

-- 修复扩展任务数据
function human:fix_mission_data_ex()
    local mission_datas_ex = self.mission_data.mission_datas_ex
    mission_datas_ex = mission_datas_ex or {}
    self.mission_data.mission_datas_ex = mission_datas_ex  -- 确保扩展任务数据存在
end

-- 检查当前称号是否存在
function human:check_cur_title_have()
    local title = self.db:get_db_attrib("title")
    if title and title.id then
        if title.new_title_id then
            local id = title.new_title_id
            if not self:check_have_id_title(id) then
                self:set_current_title( { id = 0, str = ""})  -- 称号不存在，清除当前称号
            else
                self:set_current_title(title)  -- 设置当前称号
            end
        else
            local id = title.id
            title = self:get_title_by_id(id)
            if title == nil then
                self:set_current_title( { id = 0, str = ""})  -- 称号不存在，清除当前称号
            else
                self:set_current_title(title)  -- 设置当前称号
            end
        end
    end
end

-- 初始化装备容器
function human:init_equip_continer(data)
    self.equip_container = item_container.new()
    self.equip_container:init(define.HUMAN_EQUIP.HEQUIP_CAPACITY, data.equip_list,define.CONTAINER_INDEX.HUMAN_SELF)  -- 初始化装备容器
end

-- 初始化宠物容器
function human:init_pet_container(data)
    self.pet_bag_container = pet_container.new()
    local pet_bag_size = define.DEFAULT_PET_NUM + (data.attrib.pet_num_extra or 0)  -- 计算宠物背包大小
    self.pet_bag_container:init(pet_bag_size, data.pet_bag_list,define.CONTAINER_INDEX.HUMAN_PET_BAG,self)  -- 初始化宠物容器
end

-- 初始化所有容器
function human:init_contaioners(data)
	local sceneId = self.sceneid  -- 场景ID
	local selfId = data.obj_id  -- 玩家对象ID
    self.prop_bag_container = human_bag_container.new()  -- 道具背包容器
    -- CYS-TEMBANK: distinct persistent storage, never a bank alias.
    self.cys_tembank = item_container.new()
    self.cys_tembank:init(120,data.cys_tembank_items,define.CONTAINER_INDEX.HUMAN_BANK)
    self.cys_tembank_revision=((data.cys_tembank_revision or 0)%2147483646)+1
    self.bank_bag_container = item_container.new()  -- 银行容器
    self.pet_bank_container = pet_container.new()  -- 宠物银行容器
    self.sold_out_container = item_container.new()  -- 已售出物品容器
    self.fasion_bag_container = item_container.new()  -- 时装容器

    self.fasion_bag_container:init(100, data.fashion_bag_list,define.CONTAINER_INDEX.HUMAN_FASION)  -- 初始化时装容器
    local bag_size = self:get_bag_size()  -- 获取背包大小
    local bank_bag_size = self:get_bank_bag_size()  -- 获取银行背包大小
    local pet_bank_bag_size = self:get_pet_bank_bag_size()  -- 获取宠物银行背包大小
    self.prop_bag_container:init(bag_size, data.prop_bag_list,define.CONTAINER_INDEX.HUMAN_BAG)  -- 初始化道具背包
    self.bank_bag_container:init(bank_bag_size, data.bank_bag_list,define.CONTAINER_INDEX.HUMAN_BANK)  -- 初始化银行背包
    self.pet_bank_container:init(pet_bank_bag_size, data.pet_bank_list,define.CONTAINER_INDEX.HUMAN_PET_BANK)  -- 初始化宠物银行
    self.sold_out_container:init(define.SOLD_OUT_SIZE, {},define.CONTAINER_INDEX.HUMAN_SOLD_OUT)  -- 初始化已售出物品容器
end


-- 上线时检查物品有效性定时器
function human:on_line_check_item_valid_timer()
	local update_fasion = false  -- 是否更新时装
	local update_equip = false  -- 是否更新装备
	local scene = self:get_scene()  -- 获取场景
	local name = self:get_name()  -- 获取玩家名称
	
	local del_msg = "#WNhững #G#{_ITEM%d}#W đã quá hạn trong #G%s#W của ngươi, đã bị xóa。"  -- 删除物品的消息模板
	local curtime = os.time()  -- 当前时间
	
	local item,ret
	local item_index,guid
	
	-- 检查装备容器
	local container = self.equip_container
	local delitempos,deltime_tip = container:on_line_check_item_valid_timer()
	if #delitempos > 0 then
		local container_name = define.CONTAINER_NAME[define.CONTAINER_INDEX.HUMAN_SELF]  -- 容器名称
		for _,pos in ipairs(delitempos) do
			if pos ~= define.HUMAN_EQUIP.HEQUIP_UNKNOW1
			and pos ~= define.HUMAN_EQUIP.HEQUIP_UNKNOW2 then  -- 跳过未知装备点
				item = container:get_item(pos)
				if item then
					item_index = item.item_index
					guid = item.guid
					container:set_item(pos,nil)  -- 移除过期物品
					ret = packet_def.GCUnEquipResult.new()  -- 创建卸装备结果消息
					ret.result = 1
					ret.bagIndex = 255
					ret.equipPoint = pos
					ret.item_guid = guid
					ret.item_index = item_index
					scene:send2client(self, ret)  -- 发送消息给客户端
					local mail = {}  -- 创建邮件
					mail.guid = define.INVAILD_ID
					mail.source = ""
					mail.portrait_id = define.INVAILD_ID
					mail.dest = name
					mail.flag = define.MAIL_TYPE.MAIL_TYPE_SYSTEM
					mail.create_time = curtime
					mail.content = string.format(del_msg,container_name,item_index)  -- 邮件内容
					skynet.send(".world", "lua", "send_mail", mail)  -- 发送邮件
					-- 处理特殊装备点的效果
					if pos == define.HUMAN_EQUIP.HEQUIP_CAP then  -- 帽子
						local env = skynet.getenv("env")
						if define.ADD_EQUIP_BUFF[env] then
							for _,dy_info in ipairs(define.ADD_EQUIP_BUFF[env]) do
								if dy_info[define.HUMAN_EQUIP.HEQUIP_CAP] then
									if item_index >= dy_info[define.HUMAN_EQUIP.HEQUIP_CAP].MINID
									and item_index == dy_info[define.HUMAN_EQUIP.HEQUIP_CAP].MAXID then
										self:impact_cancel_impact_in_specific_data_index(dy_info[define.HUMAN_EQUIP.HEQUIP_CAP].BUFFID)  -- 取消装备buff
									end
								end
							end
						end
					elseif pos == define.HUMAN_EQUIP.HEQUIP_WEAPON then  -- 武器
						self:set_fashion_depot_index(define.INVAILD_ID)
						update_fasion = true
					elseif equipPoint == define.HUMAN_EQUIP.HEQUIP_ANQI then  -- 暗器
						obj_me:impact_clean_all_impact_when_unequip_dark()
					elseif equipPoint == define.HUMAN_EQUIP.HEQUIP_WUHUN then  -- 武魂
						obj_me:send_skill_list()
					end
					update_equip = true
				end
			end
		end
	end
	
	-- 检查道具背包
	container = self.prop_bag_container
	delitempos,deltime_tip = container:on_line_check_item_valid_timer()
	if #delitempos > 0 then
		local container_name = define.CONTAINER_NAME[define.CONTAINER_INDEX.HUMAN_BAG]
		for _,pos in ipairs(delitempos) do
			item = container:get_item(pos)
			if item then
				container:set_item(pos,nil)  -- 移除过期物品
				ret = packet_def.GCItemInfo.new()  -- 创建物品信息消息
				ret.bag_type = define.BAG_TYPE.bag
				ret.bagIndex = pos
				ret.item = Item_cls.new():copy_raw_data()
				ret.bag_type = define.BAG_TYPE.bag
				scene:send2client(self, ret)  -- 发送消息给客户端
				local mail = {}  -- 创建邮件
				mail.guid = define.INVAILD_ID
				mail.source = ""
				mail.portrait_id = define.INVAILD_ID
				mail.dest = name
				mail.flag = define.MAIL_TYPE.MAIL_TYPE_SYSTEM
				mail.create_time = curtime
				mail.content = string.format(del_msg,container_name,item.item_index)  -- 邮件内容
				skynet.send(".world", "lua", "send_mail", mail)  -- 发送邮件
			end
		end
	end
	
	-- 检查时装背包
	container = self.fasion_bag_container
	delitempos,deltime_tip = container:on_line_check_item_valid_timer()
	if #delitempos > 0 then
		local container_name = define.CONTAINER_NAME[define.CONTAINER_INDEX.HUMAN_FASION]
		update_fasion = true
		for _,pos in ipairs(delitempos) do
			item = container:get_item(pos)
			if item then
				container:set_item(pos,nil)  -- 移除过期物品
				local mail = {}  -- 创建邮件
				mail.guid = define.INVAILD_ID
				mail.source = ""
				mail.portrait_id = define.INVAILD_ID
				mail.dest = name
				mail.flag = define.MAIL_TYPE.MAIL_TYPE_SYSTEM
				mail.create_time = curtime
				mail.content = string.format(del_msg,container_name,item.item_index)  -- 邮件内容
				skynet.send(".world", "lua", "send_mail", mail)  -- 发送邮件
			end
		end
	end
	
	-- 检查银行背包
	container = self.bank_bag_container
	delitempos,deltime_tip = container:on_line_check_item_valid_timer()
	if #delitempos > 0 then
		local container_name = define.CONTAINER_NAME[define.CONTAINER_INDEX.HUMAN_BANK]
		for _,pos in ipairs(delitempos) do
			item = container:get_item(pos)
			if item then
				container:set_item(pos,nil)  -- 移除过期物品
				local mail = {}  -- 创建邮件
				mail.guid = define.INVAILD_ID
				mail.source = ""
				mail.portrait_id = define.INVAILD_ID
				mail.dest = name
				mail.flag = define.MAIL_TYPE.MAIL_TYPE_SYSTEM
				mail.create_time = curtime
				mail.content = string.format(del_msg,container_name,item.item_index)  -- 邮件内容
				skynet.send(".world", "lua", "send_mail", mail)  -- 发送邮件
			end
		end
	end
	
	-- 更新装备和时装
	if update_equip then
		self:item_flush()  -- 刷新物品效果
		local selfId = self:get_obj_id()
		-- scene:broad_char_equioment(self)  -- 广播装备信息（已注释）
		self:get_scene():ask_char_equipment(selfId,selfId)  -- 请求装备信息
	end
	if update_fasion then
		scene:send_char_fashion_depot_data(self)  -- 发送时装仓库数据
	end
end


-- 检查物品有效性定时器
function human:check_item_valid_timer()
	-- skynet.logi("human:check_item_valid_timer()")  -- 调试日志（已注释）
	local update_fasion = false  -- 是否更新时装
	local update_equip = false  -- 是否更新装备
	local scene = self:get_scene()  -- 获取场景
	local name = self:get_name()  -- 获取玩家名称
	
	local del_msg = "#WNhững #G#{_ITEM%d}#W đã quá hạn trong #G%s#W của ngươi, đã bị xóa。"  -- 删除物品的消息模板
	local curtime = os.time()  -- 当前时间
	
	local item,ret
	local item_index,guid
	
	-- 检查装备容器
	local container = self.equip_container
	local delitempos = container:check_item_valid_timer()
	if #delitempos > 0 then
		local container_name = define.CONTAINER_NAME[define.CONTAINER_INDEX.HUMAN_SELF]  -- 容器名称
		for _,pos in ipairs(delitempos) do
			if pos ~= define.HUMAN_EQUIP.HEQUIP_UNKNOW1
			and pos ~= define.HUMAN_EQUIP.HEQUIP_UNKNOW2 then  -- 跳过未知装备点
				item = container:get_item(pos)
				if item then
					item_index = item.item_index
					guid = item.guid
					container:set_item(pos,nil)  -- 移除过期物品
					ret = packet_def.GCUnEquipResult.new()  -- 创建卸装备结果消息
					ret.result = 1
					ret.bagIndex = 255
					ret.equipPoint = pos
					ret.item_guid = guid
					ret.item_index = item_index
					scene:send2client(self, ret)  -- 发送消息给客户端
					local mail = {}  -- 创建邮件
					mail.guid = define.INVAILD_ID
					mail.source = ""
					mail.portrait_id = define.INVAILD_ID
					mail.dest = name
					mail.flag = define.MAIL_TYPE.MAIL_TYPE_SYSTEM
					mail.create_time = curtime
					mail.content = string.format(del_msg,container_name,item_index)  -- 邮件内容
					skynet.send(".world", "lua", "send_mail", mail)  -- 发送邮件
					-- 处理特殊装备点的效果
					if pos == define.HUMAN_EQUIP.HEQUIP_CAP then  -- 帽子
						local env = skynet.getenv("env")
						if define.ADD_EQUIP_BUFF[env] then
							for _,dy_info in ipairs(define.ADD_EQUIP_BUFF[env]) do
								if dy_info[define.HUMAN_EQUIP.HEQUIP_CAP] then
									if item_index >= dy_info[define.HUMAN_EQUIP.HEQUIP_CAP].MINID
									and item_index == dy_info[define.HUMAN_EQUIP.HEQUIP_CAP].MAXID then
										self:impact_cancel_impact_in_specific_data_index(dy_info[define.HUMAN_EQUIP.HEQUIP_CAP].BUFFID)  -- 取消装备buff
									end
								end
							end
						end
					elseif pos == define.HUMAN_EQUIP.HEQUIP_WEAPON then  -- 武器
						self:set_fashion_depot_index(define.INVAILD_ID)
						update_fasion = true
					elseif equipPoint == define.HUMAN_EQUIP.HEQUIP_ANQI then  -- 暗器
						obj_me:impact_clean_all_impact_when_unequip_dark()
					elseif equipPoint == define.HUMAN_EQUIP.HEQUIP_WUHUN then  -- 武魂
						obj_me:send_skill_list()
					end
					update_equip = true
				end
			end
		end
	
	end
	
	-- 检查道具背包
	container = self.prop_bag_container
	delitempos = container:check_item_valid_timer()
	if #delitempos > 0 then
		local container_name = define.CONTAINER_NAME[define.CONTAINER_INDEX.HUMAN_BAG]
		for _,pos in ipairs(delitempos) do
			item = container:get_item(pos)
			if item then
				container:set_item(pos,nil)  -- 移除过期物品
				ret = packet_def.GCItemInfo.new()  -- 创建物品信息消息
				ret.bag_type = define.BAG_TYPE.bag
				ret.bagIndex = pos
				ret.item = Item_cls.new():copy_raw_data()
				ret.bag_type = define.BAG_TYPE.bag
				scene:send2client(self, ret)  -- 发送消息给客户端
				local mail = {}  -- 创建邮件
				mail.guid = define.INVAILD_ID
				mail.source = ""
				mail.portrait_id = define.INVAILD_ID
				mail.dest = name
				mail.flag = define.MAIL_TYPE.MAIL_TYPE_SYSTEM
				mail.create_time = curtime
				mail.content = string.format(del_msg,container_name,item.item_index)  -- 邮件内容
				skynet.send(".world", "lua", "send_mail", mail)  -- 发送邮件
			end
		end
	end
	
	-- 检查时装背包
	container = self.fasion_bag_container
	delitempos = container:check_item_valid_timer()
	if #delitempos > 0 then
		local container_name = define.CONTAINER_NAME[define.CONTAINER_INDEX.HUMAN_FASION]
		update_fasion = true
		for _,pos in ipairs(delitempos) do
			item = container:get_item(pos)
			if item then
				container:set_item(pos,nil)  -- 移除过期物品
				local mail = {}  -- 创建邮件
				mail.guid = define.INVAILD_ID
				mail.source = ""
				mail.portrait_id = define.INVAILD_ID
				mail.dest = name
				mail.flag = define.MAIL_TYPE.MAIL_TYPE_SYSTEM
				mail.create_time = curtime
				mail.content = string.format(del_msg,container_name,item.item_index)  -- 邮件内容
				skynet.send(".world", "lua", "send_mail", mail)  -- 发送邮件
			end
		end
	end
	
	-- 检查银行背包
	container = self.bank_bag_container
	delitempos = container:check_item_valid_timer()
	if #delitempos > 0 then
		local container_name = define.CONTAINER_NAME[define.CONTAINER_INDEX.HUMAN_BANK]
		for _,pos in ipairs(delitempos) do
			item = container:get_item(pos)
			if item then
				container:set_item(pos,nil)  -- 移除过期物品
				local mail = {}  -- 创建邮件
				mail.guid = define.INVAILD_ID
				mail.source = ""
				mail.portrait_id = define.INVAILD_ID
				mail.dest = name
				mail.flag = define.MAIL_TYPE.MAIL_TYPE_SYSTEM
				mail.create_time = curtime
				mail.content = string.format(del_msg,container_name,item.item_index)  -- 邮件内容
				skynet.send(".world", "lua", "send_mail", mail)  -- 发送邮件
			end
		end
	end
	
	-- 更新装备和时装
	if update_equip then
		self:item_flush()  -- 刷新物品效果
		local selfId = self:get_obj_id()
		-- scene:broad_char_equioment(self)  -- 广播装备信息（已注释）
		self:get_scene():ask_char_equipment(selfId,selfId)  -- 请求装备信息
	end
	if update_fasion then
		scene:send_char_fashion_depot_data(self)  -- 发送时装仓库数据
	end
end

-- 获取道具背包大小
function human:get_prop_bag_size()
    -- CYS-ROUND2 23/09 Fixed region: props 0..99, materials 100..199.
    return 100
end

-- 获取材料背包大小
function human:get_material_bag_size()
    -- CYS-ROUND2 23/09 Fixed region: props 0..99, materials 100..199.
    return 100
end

-- 获取背包大小
function human:get_bag_size()
    local size = {}
    size.prop = self:get_prop_bag_size()  -- 道具背包大小
    size.material = self:get_material_bag_size()  -- 材料背包大小
    size.task = 20  -- 任务背包大小（固定20格）
    return size
end

-- 获取银行背包大小
function human:get_bank_bag_size()
    return self.db:get_db_attrib("bank_bag_size") or 20  -- 返回银行背包大小，默认20格
end

-- 设置银行背包大小
function human:set_bank_bag_size(size)
    self.db:set_db_attrib({bank_bag_size = size})  -- 保存银行背包大小
    local container = self:get_bank_bag_container()
    container:resize(size)  -- 调整容器大小
end

-- 获取宠物银行背包大小
function human:get_pet_bank_bag_size()
    return self.db:get_db_attrib("pet_bank_bag_size") or 2  -- 返回宠物银行背包大小，默认2格
end

-- 设置宠物银行背包大小
function human:set_pet_bank_bag_size(size)
    self.db:set_db_attrib({pet_bank_bag_size = size})  -- 保存宠物银行背包大小
    local container = self:get_pet_bank_container()
    container:resize(size)  -- 调整容器大小
end

-- 背包大小改变时的处理
function human:on_bag_size_changed()
    local size = self:get_bag_size()  -- 获取背包大小
    local updates = self.prop_bag_container:set_size(size)  -- 设置背包大小并获取更新的格子
	if updates and #updates > 0 then
		local scene = self:get_scene()
		for i,j in ipairs(updates) do
			local msg = packet_def.GCItemInfo.new()  -- 创建物品信息消息
			msg.unknow_1 = 1
			msg.item = Item_cls.new():copy_raw_data()
			msg.bagIndex = j
			scene:send2client(self, msg)  -- 发送消息给客户端
		end
	end
    self:send_bag_size(self.prop_bag_container:get_size())  -- 发送背包大小
end

-- 发送背包大小
function human:send_bag_size(size)
    local msg = packet_def.GCBagSizeChange.new()  -- 创建背包大小改变消息
    msg.prop_size = size.prop  -- 道具背包大小
    msg.material_size = size.material  -- 材料背包大小
    self:get_scene():send2client(self, msg)  -- 发送消息给客户端
end

-- 获取额外宠物数量
function human:get_pet_num_extra()
    return self.db:get_db_attrib("pet_num_extra") or 0  -- 返回额外宠物数量，默认0
end

-- 设置额外宠物数量
function human:set_pet_num_extra(num)
    assert(type(num) == "number", num)  -- 断言num是数字类型
    num = math.floor(num)  -- 向下取整
    self.db:set_db_attrib({pet_num_extra = num })  -- 保存额外宠物数量
    local container = self:get_pet_bag_container()
    local new_size = define.DEFAULT_PET_NUM + num
    container:resize(new_size)
end

-- 获取宠物背包大小
function human:get_pet_bag_size()
    local extra_num = self:get_pet_num_extra()  -- 获取额外宠物数量
    return define.DEFAULT_PET_NUM + extra_num  -- 返回默认宠物数量+额外数量
end

-- 获取当前目标ID
function human:get_cur_target_id()
    return self.cur_target_id  -- 返回当前目标ID
end

-- 设置当前目标ID
function human:set_cur_target_id(id)
    self.cur_target_id = id  -- 设置当前目标ID
end

-- 获取当前宠物
function human:get_current_pet()
    return self.pet  -- 返回当前宠物
end

-- 获取银行存款
function human:get_bank_save_money()
    return self.db:get_attrib("bank_save_money")  -- 返回银行存款
end

-- 获取装备外观
function human:get_equip_visuals()
    local equip_visuals = {}
    -- local equip_container = self:get_equip_container()  -- 获取装备容器（已注释）
	
	-- local local_get_equip_visual = function(eq_point,flag)  -- 获取装备外观的本地函数（已注释）
		-- local equipid,gemid,visual = define.INVAILD_ID,define.INVAILD_ID,0
		-- local gemid2,gemid3 = define.INVAILD_ID,define.INVAILD_ID
        -- local equip = equip_container:get_item(eq_point)
		-- if equip then
			-- local equip_data = equip:get_equip_data()
			-- visual = equip_data:get_visual()
			-- if visual > 0 then
				-- equipid = equip:get_index()
				-- gemid = equip_data:get_slot_gem(1)
				-- if gemid <= 0 then
					-- gemid = define.INVAILD_ID
				-- end
				-- if flag then
					-- gemid2 = equip_data:get_slot_gem(2)
					-- if gemid2 <= 0 then
						-- gemid2 = define.INVAILD_ID
					-- end
					-- gemid3 = equip_data:get_slot_gem(3)
					-- if gemid3 <= 0 then
						-- gemid3 = define.INVAILD_ID
					-- end
				-- end
			-- else
				-- visual = 0
			-- end
		-- end
		-- return equipid,gemid,visual,gemid2,gemid3
	-- end
    -- 获取武器外观
    do
		local visual,index,gemid = self:get_cur_weapon_visual(self:get_scene_id())
        equip_visuals.weapon = { item_index = index, gem_id = gemid, visual = visual }
    end
    -- 获取帽子外观
    do
		-- local equipid,gemid,visual = local_get_equip_visual(define.HUMAN_EQUIP.HEQUIP_CAP)  -- 已注释
        -- equip_visuals.cap = { item_index = equipid, gem_id = gemid, visual = visual }
        equip_visuals.cap = self:get_game_flag_keys_visual(define.HUMAN_EQUIP.HEQUIP_CAP)
    end
    -- 获取护甲外观
    do
		-- local equipid,gemid,visual = local_get_equip_visual(define.HUMAN_EQUIP.HEQUIP_ARMOR)  -- 已注释
        -- equip_visuals.armour = { item_index = equipid, gem_id = gemid, visual = visual }
        equip_visuals.armour = self:get_game_flag_keys_visual(define.HUMAN_EQUIP.HEQUIP_ARMOR)
    end
    -- 获取护腕外观
    do
		-- local equipid,gemid,visual = local_get_equip_visual(define.HUMAN_EQUIP.HEQUIP_GLOVE)  -- 已注释
        -- equip_visuals.cuff = { item_index = equipid, gem_id = gemid, visual = visual }
        equip_visuals.cuff = self:get_game_flag_keys_visual(define.HUMAN_EQUIP.HEQUIP_GLOVE)
    end
    -- 获取鞋子外观
    do
		-- local equipid,gemid,visual = local_get_equip_visual(define.HUMAN_EQUIP.HEQUIP_BOOT)  -- 已注释
        -- equip_visuals.foot = { item_index = equipid, gem_id = gemid, visual = visual }
        equip_visuals.foot = self:get_game_flag_keys_visual(define.HUMAN_EQUIP.HEQUIP_BOOT)
    end
    -- 获取时装外观
    do
		-- local equipid,gemid,visual,gemid_2,gemid_3 = local_get_equip_visual(define.HUMAN_EQUIP.HEQUIP_FASHION,true)  -- 已注释
        -- equip_visuals.fashion = { item_index = equipid, visual = visual, gem_1 = gemid, gem_2 = gemid_2, gem_3 = gemid_3 }
        equip_visuals.fashion = self:get_game_flag_keys_visual(define.HUMAN_EQUIP.HEQUIP_FASHION)
    end
    equip_visuals.exterior_back_id, equip_visuals.exterior_back_pos = self:get_exterior_back_visual_id()
    equip_visuals.exterior_head_id, equip_visuals.exterior_head_pos = self:get_exterior_head_visual_id()
    return equip_visuals  -- 返回装备外观数据
end

-- 设置曼陀罗花最大数量
-- @param count 最大数量
function human:set_datura_flower_max(count)
    self.db:set_db_attrib({ datura_flower_max = count })
end

-- 设置银行存款
-- @param money 存款金额
-- @param reason 原因
-- @param extra 额外信息
function human:set_bank_save_money(money, reason, extra)
    assert(money >= 0 )
    money = math.floor(money)
    money = money > define.INT32_MAX and define.INT32_MAX or money
    local before = self:get_bank_save_money()
    self.db:set_db_attrib({ bank_save_money = money })
    self:log_money_rec(reason, "银行金币", before, money - before, extra)
end

-- 解锁头部外观
-- @param id 头部外观ID
function human:unlock_exterior_head(id)
    if id == define.INVAILD_ID then
        return false
    end
    local heads = self.exterior.heads
    local find = false
    for _, h in ipairs(heads) do
        if h.id == id then
            find = true
            break
        end
    end
    if not find then
        table.insert(heads, { id = id, term = -1})
        self:send_exterior_info()
        return true
    end
    return false
end

-- 解锁面部外观
-- @param id 面部外观ID
function human:unlock_exterior_face(id)
    if id == define.INVAILD_ID then
        return false
    end
    local faces = self.exterior.faces
    local find = false
    for _, h in ipairs(faces) do
        if h.id == id then
            find = true
            break
        end
    end
    if not find then
        table.insert(faces, { id = id, term = -1})
        self:send_exterior_info()
        return true
    end
    return false
end

-- 解锁发型外观
-- @param id 发型外观ID
function human:unlock_exterior_hair(id)
    if id == define.INVAILD_ID then
        return false
    end
    local hairs = self.exterior.hairs
    local find = false
    for _, h in ipairs(hairs) do
        if h.id == id then
            find = true
            break
        end
    end
    if not find then
        table.insert(hairs, { id = id, term = -1})
        self:send_exterior_info()
        return true
    end
    return false
end

-- 解锁姿态外观
-- @param id 姿态外观ID
function human:unlock_exterior_poss(id)
    if id == define.INVAILD_ID then
        return false
    end
    local poss = self.exterior.poss
    local find = false
    for _, h in ipairs(poss) do
        if h.id == id then
            find = true
            break
        end
    end
    if not find then
        table.insert(poss, { id = id, term = -1})
        self:send_exterior_poss_info(poss[#poss])
        return true
    end
    return false
end

-- 解锁外观染色
-- @param soul_id 灵魂ID
-- @param index 索引
-- @param color_value 颜色值
-- @param target_id 目标ID
function human:unlock_exterior_ranse(soul_id, index, color_value, target_id)
    local ranse = self.exterior.ranse
    ranse[soul_id][index] = color_value
    self:send_exterior_ranse(2, target_id)
end

-- 发送外观染色信息
-- @param type 类型
-- @param target_id 目标ID
function human:send_exterior_ranse(type, target_id)
    local msg = packet_def.GCPetSoulRanSe.new()
    msg.type = type
    msg.list = self.exterior.ranse
    msg.select = self:get_exterior_ranse_select()
    msg.target_id = target_id or define.INVAILD_ID
    self:get_scene():send2client(self, msg)
    -- local ret = packet_def.GCOrnamentsDataUpdate.new()
	-- ret.op_target = 2
	-- ret.op_code = 1
	-- ret.OrnamentsBackUnit = self:get_exterior_back_info()
	-- ret.OrnamentsBackUnitNum = #ret.OrnamentsBackUnit
	-- ret.OrnamentsHeadUnit = self:get_exterior_head_info()
	-- ret.OrnamentsHeadUnitNum = #ret.OrnamentsHeadUnit
	-- ret.CurOrnamentsBackId,ret.CurOrnamentsBackPos = self:get_exterior_back_visual_id()
	-- ret.CurOrnamentsHeadId,ret.CurOrnamentsHeadPos = self:get_exterior_head_visual_id()
	-- self:get_scene():send2client(self, ret)
end

-- 设置外观染色ID
-- @param id 染色ID
function human:set_exterior_ranse_id(id)
    self.db:set_db_attrib({ exterior_ranse_id = id})
end

-- 根据染色ID设置外观染色选择
-- @param pet_soul_id 宠物灵魂ID
-- @param ranse_id 染色ID
function human:set_exterior_ranse_model_level(level)
    self.db:set_db_attrib({ exterior_ranse_model_level = level})
end

function human:get_exterior_ranse_model_level()
    return self.db:get_db_attrib("exterior_ranse_model_level") or 0
end

function human:get_exterior_ranse_plan_index(pet_soul_id, ranse_id)
    local colors = self.exterior.ranse[pet_soul_id] or {}
    for i = 1, 5 do
        if colors[i] == ranse_id then
            return i
        end
    end
end

function human:is_exterior_ranse_plan_unlocked(plan_index)
    if not plan_index then
        return false
    end
    local max_plan_count = math.min(3 + (equip_dress_bonus.get_soul_color_slot_bonus(self) or 0), 5)
    return plan_index >= 1 and plan_index <= max_plan_count
end

function human:set_exterior_ranse_select_by_ranse_id(pet_soul_id, ranse_id)
    local select = 0
    local ranse = self.exterior.ranse[pet_soul_id]
    if ranse_id ~= 0 then
        for i = 1, 5 do
            if ranse[i] == ranse_id then
                select = i
                break
            end
        end
    end
    self.db:set_db_attrib({ exterior_ranse_select = select })
end

-- 获取外观染色选择
function human:get_exterior_ranse_select()
    return self.db:get_db_attrib("exterior_ranse_select") or 0
end

-- 获取外观染色ID
function human:get_exterior_ranse_id()
    return self.db:get_db_attrib("exterior_ranse_id") or 0
end

-- 获取珍藏/外观分享方案数据
function human:get_share_plan()
    if not self.exterior.share_plan then
        self.exterior.share_plan = {
            plan_id = 0,
            tag = {},
            dress_a = {},
            dress_b = {},
            weapon_a = {},
            weapon_b = {},
            ride_a = {},
            ride_b = {},
        }
        for i = 1, 6 do
            self.exterior.share_plan.tag[i] = -1
            self.exterior.share_plan.dress_a[i] = -1
            self.exterior.share_plan.dress_b[i] = -1
            self.exterior.share_plan.weapon_a[i] = -1
            self.exterior.share_plan.weapon_b[i] = -1
            self.exterior.share_plan.ride_a[i] = -1
            self.exterior.share_plan.ride_b[i] = -1
        end
    end
    return self.exterior.share_plan
end

-- 保存珍藏/外观分享方案数据
function human:save_share_plan(category, data)
    local plan = self:get_share_plan()

    if category == "tag" then
        for i = 1, 6 do
            plan.tag[i] = data.tag[i] or -1
        end
    elseif category == "dress" then
        -- dress_a = VecIndex (槽位索引), dress_b = ExteriorID (时装外观ID)
        for i = 1, 6 do
            plan.dress_a[i] = data.dress_a[i] or -1  -- 槽位索引
            plan.dress_b[i] = data.dress_b[i] or -1  -- 外观ID
        end
    elseif category == "ride" then
        for i = 1, 6 do
            plan.ride_a[i] = data.ride[i] or -1
        end
    elseif category == "weapon" then
        for i = 1, 6 do
            plan.weapon_a[i] = data.weapon[i] or -1
        end
    elseif category == "plan_id" then
        plan.plan_id = data.plan_id or 0
    end
end

-- 获取资料页时装数据 (独立于 share_plan，供客户端 ProfileData("DRESS") 读取)
function human:get_profile_dress()
    if not self.exterior.profile_dress then
        self.exterior.profile_dress = {
            idx = {},  -- VecIndex槽位索引
            id = {},   -- ExteriorID外观ID
        }
        for i = 1, 6 do
            self.exterior.profile_dress.idx[i] = -1
            self.exterior.profile_dress.id[i] = -1
        end
    end
    return self.exterior.profile_dress
end

-- 保存资料页时装数据
function human:save_profile_dress(idx_list, id_list)
    local pd = self:get_profile_dress()
    for i = 1, 6 do
        pd.idx[i] = idx_list[i] or -1
        pd.id[i] = id_list[i] or -1
    end
end

-- 发送外观姿态信息
-- @param poss 姿态数据
function human:send_exterior_poss_info(poss)
    local msg = packet_def.GCExteriorInfo.new()
    msg.extrior_count = 1
    msg.extrior_list = {}
    table.insert(msg.extrior_list, { id = poss.id, remindtime = poss.term, unknow_3 = 0})
    msg.type = 7
    msg.unknow_2 = 1
    self:get_scene():send2client(self, msg)
end

-- 重置生活技能操作
function human:reset_ability_opera()
    self.ability_opera = {
        ability_id = 0,
        pres_id = 0,
        obj = define.INVAILD_ID,
        max_time = 0,
        cur_time = 0,
        mat_index = define.INVAILD_ID,
        mat_bag_index = define.INVAILD_ID
    }
end

-- 获取生活技能操作
function human:get_ability_opera()
    return self.ability_opera
end

-- 获取保存数据
function human:get_cy_four_resource(id)
    return require("cy_four_combat.storage").get(self,id)
end
function human:set_cy_four_resource(id,value)
    return require("cy_four_combat.storage").set(self,id,value)
end

function human:get_save_data()
    return {
        cys_forge = self.cys_forge or false,
        lv1_attrib = self.db:get_lv1_attrib(),
        attrib = self.db:get_db_save_attrib(),
        impact_list = self.impacts:get_list(),
        world_pos = self.world_pos,
        sceneid = self.sceneid,
        double_exp_info = self.double_exp_info,
        equip_list = self:get_equip_container():get_save_data(),
        prop_bag_list = self:get_prop_bag():get_save_data(),
        pet_bag_list = self:get_pet_bag_container():get_save_data(),
        pet_bank_list = self:get_pet_bank_container():get_save_data(),
        bank_bag_list = self:get_bank_bag_container():get_save_data(),
        cys_tembank_items = self.cys_tembank:get_save_data(),
        cys_tembank_revision = self.cys_tembank_revision,
        fashion_bag_list = self:get_fasion_bag_container():get_save_data(),
        chedifulu_data = self.chedifulu_data,
        material_bag_size = self.material_bag_size,
        exterior = self.exterior,
        rmb_chat_face_info = self.rmb_chat_face_info,
        skill_list = self:get_skill_list(),
        xinfa_list = self:get_xinfa_list(),
        talent = self:get_talent(),
        cys_assist = self.cys_assist,
        xiulian_list = self:get_xiulian_list(),
        cys_shending = self.cys_shending,
        ability_list = self:get_ability_list(),
        prescriptions = self:get_prescriptions(),
        mission_data = self.mission_data,
        dungeonsweep = self.dungeonsweep,
        week_active = self.week_active,
        setting = self.setting,
        cool_down_times = self.cool_down_times,
        huanhun = self.huanhun or {},
        attackers_list = self.attackers_list:get_save_data() or {},
        pk_declaration_list = self.pk_declaration_list:get_save_data() or {},
        shop_guids = self.shop_guids or {},
        titles = self.titles or {},
        id_titles = self.id_titles or {},
        mystery_shop_info = self.mystery_shop_info,
        jiyuan_shop_info = self.jiyuan_shop_info,
        wanshige_shop_info = self.wanshige_shop_info,
		limit_shop = self.limit_shop,
		-- relation = self.relation_list,
        cy_four_resources = require("cy_four_combat.storage").snapshot(self),
		game_flag = self.game_flag,
		dw_jinjie = self.dw_jinjie,
		
    }
end

-- 更新玩家状态
-- @param ... 时间增量
function human:update(...)
    self:check_pk_mode_can_change(...)
    self.attr_msg_to_team_inteval_count = self.attr_msg_to_team_inteval_count + 1
    if self.attr_msg_to_team_inteval_count > 9 then
        self.attr_msg_to_team_inteval_count = 0
        self:sync_team_member_info()
        self:sync_raid_member_info()
    end
    self:send_refresh_cool_down_time(...)
    self:update_double_exp_info(...)
    self:update_ve_recover(...)
    self:update_mission_timers(...)
    self.attackers_list:on_heart_beat(...)
    self.pk_declaration_list:on_heart_beat(...)
    character.update(self, ...)
	local delta_time = ...
	if self.player_tick > delta_time then
		self.player_tick = self.player_tick - delta_time
	else
		self.player_tick = self.player_tick + 5000
		local selfId = self:get_obj_id()
		self:get_scene():get_script_engienr():call(define.UPDATE_CLIENT_ICON_SRIPTID,"OnPlayerTick",-1 * selfId)
	end
	
	if self.check_item_time > delta_time then
		self.check_item_time = self.check_item_time - delta_time
	else
		self.check_item_time = math.random(60000,120000)
		self:check_item_valid_timer()
	end
	if self.restore_hp_reset_time > 0 then
		if self.restore_hp_tick > delta_time then
			self.restore_hp_tick = self.restore_hp_tick - delta_time
		else
			self.restore_hp_value = 0
			self.restore_hp_tick = self.restore_hp_reset_time * 1000
		end
	end
    --self:log_views()
end

-- 设置恢复生命值重置时间
-- @param ntime 重置时间
-- @param nrate 恢复速率
function human:set_restore_hp_reset_time(ntime,nrate)
	if ntime >= 0 and nrate >= 0 then
		self.restore_hp_rate = nrate
		self.restore_hp_reset_time = ntime
	end
end

-- 获取限制恢复生命值数据
function human:get_limit_restore_hp()
	return self.restore_hp_rate,self.restore_hp_value,self.restore_hp_reset_time
end

-- 设置恢复生命值数量
-- @param value 恢复值
function human:set_restore_hp_value(value)
	self.restore_hp_value = self.restore_hp_value + value
end

-- 记录视野对象数量
function human:log_views()
    local view_obj_count = 0
    for k in pairs(self.view) do
        view_obj_count = view_obj_count + 1
    end
    -- skynet.logi("view_obj_count =", view_obj_count)
end

-- 获取攻击者列表
function human:get_attackers()
    return self.attackers_list
end

-- 获取PK声明列表
function human:get_pk_declaration_list()
    return self.pk_declaration_list
end

-- 获取野外战帮派列表
function human:get_wild_war_guilds()
    return self.wild_war_guilds
end

-- 获取帮派ID
function human:get_guild_id()
    return self.db:get_db_attrib("guild_id") or define.INVAILD_ID
end

-- 获取帮派名称
function human:get_guild_name()
    return self.db:get_db_attrib("guild_name") or ""    
end

-- 获取联盟ID
function human:get_confederate_id()
    return self.db:get_db_attrib("confederate_id") or define.INVAILD_ID
end

-- 开始商店交互
-- @param shop 商店对象
function human:begin_shop(shop)
    self.shop = shop
    self.shop_cfg_version = shopenginer:get_shop_cfg_version()
end

-- 结束商店交互
function human:end_shop()
    self.shop = nil
end

-- 从商店买回物品
-- @param request 购买请求
function human:buy_back(request)
    local msg = packet_def.GCShopBuy.new()
    msg.result = msg.BUY_RESULT.BUY_BACK_OK
    local sold_out_container = self:get_sold_out_container()
    local index = sold_out_container:get_index_by_guid(request.item_guid)
    if index == nil then
        msg.result = msg.BUY_RESULT.BUY_BAG_FULL
        self:get_scene():send2client(self, msg)
        return
    end
    local item = sold_out_container:get_item(index)
    if not item then
        msg.result = msg.BUY_RESULT.BUY_BAG_FULL
        self:get_scene():send2client(self, msg)
        return
    end

    -- 先从回购列表移除，防止重复发包卡物品
    sold_out_container:set_item(index, nil)

    local price = item:get_base_config().base_price * item:get_lay_count()
    local money = self:get_money()
    if money < price then
        -- 金币不足，物品放回回购列表
        sold_out_container:set_item(index, item)
        msg.result = msg.BUY_RESULT.BUY_MONEY_FAIL
        self:get_scene():send2client(self, msg)
        return
    end

    local bag_index = self:get_prop_bag_container():get_empty_item_index(item:get_place_bag())
    if bag_index == define.INVAILD_ID then
        -- 背包满，物品放回回购列表
        sold_out_container:set_item(index, item)
        msg.result = msg.BUY_RESULT.BUY_BAG_FULL
        self:get_scene():send2client(self, msg)
        return
    end

    -- 扣钱、物品进背包
    self:set_money(money - price, "从商店买回道具")
    self:get_prop_bag_container():set_item(bag_index, item)

    local collection = "human_buy_back"
    local doc = {
        name = self:get_name(),
        guid = self:get_guid(),
        param = {act_name = "回购道具", fun_name = "human:buy_back"},
        item_index = item:get_index(),
        item_count = item:get_lay_count(),
        is_bind = item:is_bind(),
        date_time = utils.get_day_time()
    }
    skynet.send(".logdb", "lua", "insert", { collection = collection, doc = doc })

    self:send_sold_out_list()
    item = self:get_prop_bag_container():get_item(bag_index)

    local equip_info = packet_def.GCNotifyEquip.new()
    equip_info.bag_index = bag_index
    equip_info.item = item:copy_raw_data()
    self:get_scene():send2client(self, equip_info)

    local item_info = packet_def.GCItemInfo.new()
    item_info.bagIndex = bag_index
    item_info.unknow_1 = item and 0 or 1
    item_info.item = item and item:copy_raw_data() or Item_cls.new():copy_raw_data()
    self:get_scene():send2client(self, item_info)

    msg.index = index
    msg.item_index = item:get_index()
    msg.item_count = item:get_lay_count()
    msg.count = 1
    self:get_scene():send2client(self, msg)
end

-- 向商店出售物品
-- @param sell_bag_index 出售物品的背包索引
function human:shop_sell(sell_bag_index)
    -- CYS-INV sell lock
    local bag = self:get_prop_bag_container()
    local source = inventory_guard.accepts(bag, sell_bag_index) and bag:get_item(sell_bag_index)
    if not source or source:is_lock() then return end
    local item = self:get_prop_bag_container():get_item(sell_bag_index)
    if item then
        local can_sell = item:can_sell()
        if not can_sell then
            self:notify_tips(string.format("%s不能出售", item:get_name()))
            return
        end
        local extra_config = item:get_extra_config()
        local price = item:get_base_config().sell_price * item:get_lay_count()
        local sold_out_container = self:get_sold_out_container()
        local bag_index = sold_out_container:get_empty_item_index()
        if bag_index == define.INVAILD_ID then
            sold_out_container:remove_item(0)
            bag_index = sold_out_container:get_empty_item_index()
        end
        assert(bag_index ~= define.INVAILD_ID, bag_index)
        local logpram = {}
        human_item_logic:move_item_from_bag_to_container_with_index(logpram, self, sold_out_container, sell_bag_index, bag_index)
        if extra_config and extra_config.sell_money_type == 0 then
            local money = self:get_money()
            money = money + price
            self:set_money(money, "物品出售给商店获得金币", { item = item:copy_raw_data() })
        else
            local money = self:get_money()
            money = money + price
            self:set_jiaozi(money, "物品出售给商店获得交子", { item = item:copy_raw_data() } )
        end
    
        item = self:get_prop_bag_container():get_item(sell_bag_index)
        local msg = packet_def.GCItemInfo.new()
        msg.bagIndex = sell_bag_index
        msg.unknow_1 = item and 0 or 1
        msg.item = item and item:copy_raw_data() or Item_cls.new():copy_raw_data()
        self:get_scene():send2client(self, msg)
    
        self:send_sold_out_list()
        msg = packet_def.GCShopSell.new()
        msg.result = msg.SELL_RESULT.SELL_OK
        self:get_scene():send2client(self, msg)
    end
end

-- 执行跳跃动作
function human:do_jump()
    if self:is_limit_move() then
        return define.OPERATE_RESULT.OR_LIMIT_MOVE
    end
    actionenginer:interrupt_current_action(self)
    local msg = packet_def.GCCharJump.new()
    msg.m_objID = self:get_obj_id()
    self:get_scene():broadcast(self, msg, false)
    return define.OPERATE_RESULT.OR_OK
end

-- 中断当前生活技能操作
function human:interrupt_current_ability_opera()

end

-- 执行商店购买
-- @param index 商品索引
-- @param buy_num 购买数量
function human:do_shop(index, buy_num)
    -- CYS-INV shop quantities
    if not self.shop or not inventory_guard.integer(index, 1, 200)
        or not inventory_guard.integer(buy_num, 1, 65535) then return end
    local goods = self.shop:get_merchadise_by_index(index)
    if not goods or not inventory_guard.integer(goods.pnum, 1, 65535)
        or not inventory_guard.integer(goods.price, 0, 2147483647)
        or goods.pnum * buy_num > 65535 or goods.price * buy_num > 2147483647 then return end
    local opening_shop = self.shop
	if self.shop_cfg_version ~= shopenginer:get_shop_cfg_version() then
		self:notify_tips("商店配置已更新，请重新打开商店。")
		self:end_shop()
		return
	end
	local scene = self:get_scene()
	local sceneId = scene:get_id()
    local merchandise = self.shop:get_merchadise_by_index(index)
	local itemid = merchandise.id
	local have_count,is_special
	local shop_id = self.shop.shop_id
	local limit_shop_human = define.LIMIT_SHOP_HUMAN[shop_id]
	if limit_shop_human then
		if self:get_game_flag_key(limit_shop_human) == 0 then
			self:notify_tips("该商店你无法购买。")
			return
		end
	end
	local shop_flag = 0
	local buy_name = "商店购买"
	local update_interval = define.REGION_LIMITED_SHOP[shop_id]
	if update_interval then
		shop_flag = 1
		buy_name = "全区限购"
		local ranking_addr = skynet.localname(define.CACHE_NODE)
		if not ranking_addr then
			self:notify_tips("服务未启动，请通知GM处理。")
			return
		elseif define.IS_KUAFU_SCENE[sceneId] then
			self:notify_tips(selfId,"跨服不可购买。")
			return
		end
		if merchandise.pmax ~= -1 then
			local world_id = self:get_server_id()
			local count = skynet.call(define.CACHE_NODE,"lua","get_limit_shop_buy_count",world_id,update_interval,shop_id,itemid)
			if count + buy_num > merchandise.pmax then
				self:notify_tips("可购买次数不足")
				return
			end
		end
	elseif define.LIMIT_SHOP[shop_id] then
		shop_flag = 2
		buy_name = "个人限购"
		local count = self:get_limit_shop_buy_count(shop_id,itemid)
		if not count then
			self:notify_tips("请重新登陆游戏，你尚未初始化该商店数据。")
			return
		elseif merchandise.pmax ~= -1 then
			if count + buy_num > merchandise.pmax then
				self:notify_tips("可购买次数不足")
				return
			end
		end
	else
		have_count,is_special = self:check_shop_goods_buy(shop_id, itemid, merchandise, buy_num)
		if is_special then
			shop_flag = 3
			buy_name = "个人限购"
		end
		if not have_count then
			self:notify_tips("可购买次数不足")
			return
		end
	end
    local shop_type = self.shop.shop_type
    local msg = packet_def.GCShopBuy.new()
    local cost_money = merchandise.price * buy_num
    if self:check_cost_money_by_shop_type(shop_type, cost_money) then
        local is_bind = define.BIND_YUANBAO_SHOPS[shop_id] or false
        local item_count = buy_num * merchandise.pnum
        local logparam = { reason = buy_name, user_name = self:get_name(), user_guid = self:get_guid() }
        local ok = human_item_logic:create_multi_item_to_bag(logparam, self, itemid, item_count, is_bind, shop_type, nil, nil, function()
            return self.shop == opening_shop and self.shop_cfg_version == shopenginer:get_shop_cfg_version()
                and self:check_cost_money_by_shop_type(shop_type, cost_money)
        end)
        if ok then
            msg.result = msg.BUY_RESULT.BUY_OK
            msg.index = index
            msg.item_index = itemid
            msg.item_count = item_count
            msg.count = item_count
            msg.flag = 1
            msg.price = cost_money
            msg.unknow_11 = 10
            msg.unknow_2 = 0
            msg.shop_id = shop_id
            msg.unknow_8 = -1
            msg.unknow_9 = 100
			local extra = {
				buyitem = itemid,
				buynum = item_count,
			}
            self:cost_money_by_shop_type(shop_type, cost_money,extra)
			if shop_flag == 1 then
				local world_id = self:get_server_id()
				local buy_counts = skynet.call(define.CACHE_NODE,"lua","set_limit_shop_buy_count",world_id,shop_id,itemid,buy_num)
				if buy_counts then
					local msg = packet_def.GCMSShopBuyInfo.new()
					msg.size = 0
					msg.unknow_1 = {}
					msg.unknow_2 = {}
					for id, count in pairs(buy_counts) do
						table.insert(msg.unknow_1, tonumber(id))
						table.insert(msg.unknow_2, count)
						msg.size = msg.size + 1
					end
					scene:send2client(self, msg)
				else
					local collection = "log_error_limit_shops"
					local doc = {
						fun_name = "human:do_shop",
						name = self:get_name(),
						guid = self:get_guid(),
						itemid = itemid,
						buy_num = buy_num,
						prize = cost_money
					}
					skynet.send(".logdb", "lua", "insert", { collection = collection, doc = doc})
				end
			elseif shop_flag == 2 then
				self:set_limit_shop_buy_count(shop_id,itemid,buy_num)
			elseif shop_flag == 3 then
				self:on_shop_goods_buy(shop_id, itemid, buy_num)
			end
        else
            msg.result = msg.BUY_RESULT.BUY_BAG_FULL
        end
    else
        msg.result = msg.BUY_RESULT.BUY_RMB_FAIL
    end
    scene:send2client(self, msg)
end

-- 检查商店商品购买限制
-- @param shop_id 商店ID
-- @param goods_id 商品ID
-- @param merchandise 商品信息
-- @param buy_num 购买数量
function human:check_shop_goods_buy(shop_id, goods_id, merchandise, buy_num)
    local this_shop = shopenginer:get_static_shop_mgr():get_shop_by_id(shop_id)
    if this_shop.is_yuanbao_shop == 2 then
        local buy_count = self:get_mystery_shop_count_by_id(goods_id)
        return merchandise.pmax == define.INVAILD_ID or (buy_count + buy_num) <= merchandise.pmax,true
    end
    return true,false
end

-- 商店商品购买处理
-- @param shop_id 商店ID
-- @param goods_id 商品ID
-- @param buy_num 购买数量
function human:on_shop_goods_buy(shop_id, goods_id, buy_num)
    local this_shop = shopenginer:get_static_shop_mgr():get_shop_by_id(shop_id)
    if this_shop.is_yuanbao_shop == 2 then
        local insertd = false
        for _, info in ipairs(self.mystery_shop_info) do
            if info.goods_id == goods_id then
                info.count = info.count + buy_num
                insertd = true
                break
            end
        end
        if not insertd then
            table.insert(self.mystery_shop_info, { goods_id = goods_id, count = buy_num})
        end
        self:send_mystery_shop_info()
    end
end

-- 根据ID获取神秘商店购买次数
-- @param id 商品ID
function human:get_mystery_shop_count_by_id(id)
    for _, msi in ipairs(self.mystery_shop_info) do
        if msi.goods_id == id then
            return msi.count
        end
    end
    return 0
end

-- 万事阁商店购买处理
-- @param item_id 物品ID
-- @param camp 阵营
function human:on_wanshige_shop_buy(item_id, camp)
    self.wanshige_shop_info.item_list = self.wanshige_shop_info.item_list or {}
    self.wanshige_shop_info.item_list[tostring(item_id)] = (self.wanshige_shop_info.item_list[tostring(item_id)] or 0) + 1
    self:send_shengwang_info(camp)
end

-- 检查并重置万事阁数据
function human:check_reset_wanshige_data()
    local reset_week_day = self.wanshige_shop_info.reset_week_day
    local week_day = os.date("%w") + 1
    if reset_week_day ~= week_day then
        self.wanshige_shop_info.item_list = {}
        self.wanshige_shop_info.reset_week_day = week_day
    end
end

-- 根据ID获取万事阁商店购买次数
-- @param id 物品ID
function human:get_wanshige_shop_count_by_id(id)
    return self.wanshige_shop_info.item_list[tostring(id)] or 0
end

-- 祭元商店购买处理
-- @param item_id 物品ID
-- @param targetId 目标ID
function human:on_jiyuan_shop_buy(item_id, targetId)
    item_id = tostring(item_id)
    self.jiyuan_shop_info.item_list = self.jiyuan_shop_info.item_list or {}
    self.jiyuan_shop_info.item_list[item_id] = (self.jiyuan_shop_info.item_list[item_id] or 0) + 1
    self:send_jiyuan_shop_info(targetId)
	return self.jiyuan_shop_info.item_list[item_id]
end

-- 发送祭元商店信息
-- @param targetId 目标ID
function human:send_jiyuan_shop_info(targetId)
    local item_list = {}
    for item_id, count in pairs(self.jiyuan_shop_info.item_list or {}) do
        table.insert(item_list, { id = tonumber(item_id), count = count})
    end
    local msg = packet_def.GCJiYuanShopInfo.new()
    msg.item_id = item_list[1] and item_list[1].id or 0
    msg.item_count = item_list[1] and item_list[1].count or 0
    msg.m_objID = targetId
    self:get_scene():send2client(self, msg)
end

-- 检查祭元商店信息
function human:check_jiyuan_shop_info()
    local reset_week = self.jiyuan_shop_info.reset_week
    local week = os.date("%W")
    if reset_week ~= week then
        self.jiyuan_shop_info.item_list = {}
        self.jiyuan_shop_info.reset_week = week
    end
end

-- 根据ID获取祭元商店购买次数
-- @param id 物品ID
function human:get_jiyuan_shop_count_by_id(id)
    self.jiyuan_shop_info.item_list = self.jiyuan_shop_info.item_list or {}
    return self.jiyuan_shop_info.item_list[tostring(id)] or 0
end

-- 发送声望信息
-- @param camp 阵营
function human:send_shengwang_info(camp)
    local player_camp = self:get_mission_data_by_script_id(854) or 0
    local msg = packet_def.GCShengWangInfo.new()
    msg.unknow_1 = 3
    msg.unknow_10 = 0
    msg.camp = camp
    msg.unknow_3 = 6
    msg.player_camp = player_camp
    msg.show_wanshige = player_camp == camp and 1 or 0
    msg.unknow_6 = 1
    msg.unknow_7 = 0
    msg.list_1 = { 5, 3, 8 }
    msg.list_2 = { 0, 0, 0 }
    msg.item_list = {}
    for id, count in pairs(self.wanshige_shop_info.item_list or {}) do
        --table.insert(msg.item_list, { id = tonumber(id), count = count})
    end
    self:get_scene():send2client(self, msg)
end

-- 发送神秘商店信息
function human:send_mystery_shop_info()
    local msg = packet_def.GCMSShopBuyInfo.new()
    msg.size = #self.mystery_shop_info
    msg.unknow_1 = {}
    msg.unknow_2 = {}
    for _, info in ipairs(self.mystery_shop_info) do
        table.insert(msg.unknow_1, info.goods_id)
        table.insert(msg.unknow_2, info.count)
    end
    self:get_scene():send2client(self, msg)
end

-- 发送地宫商店信息
function human:send_digong_shop_info()
    local msg = packet_def.GCDiGongShopInfo.new()
    self:get_scene():send2client(self, msg)
end

-- 重置神秘商店信息
function human:reset_mystery_shop_info()
    self.mystery_shop_info = {}
end

-- 计算商店商品最大购买次数
-- @param shop_id 商店ID
-- @param goods_id 商品ID
-- @param pmax 原始最大购买次数
function human:cal_shop_goods_pmax(shop_id, goods_id, pmax)
    if pmax == define.INVAILD_ID then
        return pmax
    end
    local day = self.shop_goods_buy.day
    local day_shop_buy = day[tostring(shop_id)] or {}
    pmax = pmax - (day_shop_buy[tostring(goods_id)] or 0)
    pmax = pmax < 0 and 0 or pmax
    return pmax
end

-- 根据商店类型检查货币是否足够
-- @param shop_type 商店类型
-- @param cost 消费金额
function human:check_cost_money_by_shop_type(shop_type, cost)
    if shop_type == 5 then
        local yuanbao = self:get_yuanbao()
        return yuanbao >= cost
    elseif shop_type == 9 then
        local config_info = configenginer:get_config("config_info")
        local yuanbao_buy = tonumber(config_info.YuanBaoShop.YuanbaoBuy) or 1
        if yuanbao_buy == 1 then
            local yuanbao = self:get_bind_yuanbao() + self:get_yuanbao()
            return yuanbao >= cost
        else
            local bind_yuanbao = self:get_bind_yuanbao()
            if bind_yuanbao < cost then
                self:notify_tips("绑定元宝不足，无法购买。")
                return false
            end
            return true
        end
	elseif shop_type == 21 then
		local haveryd = self:get_mission_data_by_script_id(535)
		if haveryd >= cost then
			return true
		end
		self:notify_tips("荣誉点不足，你当前拥有荣誉点:"..tostring(haveryd).."。")
		return false
    elseif shop_type == 8 then
        return self:check_money_with_priority(cost)
    else
        local money = self:get_money()
        return money >= cost
    end
end

-- 记录货币变化日志
-- @param reason 原因
-- @param coin_type 货币类型
-- @param before 变化前数量
-- @param num 变化数量
-- @param extra 额外信息
function human:log_money_rec(reason, coin_type, before, num, extra)
    extra = extra or {}
    local collection = "log_money_rec"
    local doc = {
        coin_type = coin_type,
        day_time = utils.get_day_time(),
        unix_time = os.time(),
        guid = self:get_guid(),
        name = self:get_name(),
        reason = reason,
        before = before,
        num = num,
        extra = extra,
        world_id = self:get_server_id(),
        process_id = tonumber(skynet.getenv "process_id")
    }
    skynet.send(".logdb", "lua", "insert", { collection = collection, doc = doc})
end

-- 根据商店类型扣除货币
-- @param shop_type 商店类型
-- @param cost 消费金额
-- @param extra 额外信息
function human:cost_money_by_shop_type(shop_type, cost, extra)
    extra = extra or {}
    extra.shop_type = extra.shop_type
    if shop_type == 5 then
        local yuanbao = self:get_yuanbao()
        self:set_yuanbao(yuanbao - cost, "商店购买消费", extra)
        local val = self:get_mission_data_by_script_id(389) or 0
        self:set_mission_data_by_script_id(389, val + cost)
        self:add_mission_huoyuezhi(8, cost)
    elseif shop_type == 9 then
        local config_info = configenginer:get_config("config_info")
        local yuanbao_buy = tonumber(config_info.YuanBaoShop.YuanbaoBuy) or 1
        local yuanbao = self:get_bind_yuanbao()
        if yuanbao < cost then
            if yuanbao_buy == 1 then
                self:set_bind_yuanbao(0, "商店购买消费", extra)
                local left = cost - yuanbao   
                yuanbao = self:get_yuanbao()
                self:set_yuanbao(yuanbao - left, "商店购买消费-绑元不足支付", extra)
                local val = self:get_mission_data_by_script_id(389) or 0
                self:set_mission_data_by_script_id(389, val + left)
                self:add_mission_huoyuezhi(8, left)
            else
                self:notify_tips("绑定元宝不足，无法购买。")
                return
            end
        else
            self:set_bind_yuanbao(yuanbao - cost, "商店购买消费", extra)
        end
        self:add_mission_huoyuezhi(9, 1)
	elseif shop_type == 21 then
		local curvalue = self:get_mission_data_by_script_id(535)
		local subvalue = curvalue - cost
		self:set_mission_data_by_script_id(535, subvalue)
		self:log_money_rec(subvalue, "荣誉点商店购买消费", curvalue,subvalue - curvalue,extra)
    elseif shop_type == 8 then
        self:cost_money_with_priority(cost, "商店购买消费", extra)
    else
        local money = self:get_money()
        self:set_money(money - cost, "商店购买消费", extra)
    end
end

-- 获取效果列表
function human:get_impact_list()
    return self.impacts:get_list()
end

-- 获取摆摊箱
function human:get_stall_box()
    return self.stall_box
end

-- 获取交换箱
function human:get_exchange_box()
    return self.exchange_box
end

-- 获取道具背包
function human:get_prop_bag()
    return self.prop_bag_container
end

-- 获取银行背包容器
function human:get_bank_bag_container()
    return self.bank_bag_container
end

-- 获取宠物背包容器
function human:get_pet_bag_container()
    return self.pet_bag_container
end

-- 获取宠物银行容器
function human:get_pet_bank_container()
    return self.pet_bank_container
end

-- 获取已售出物品容器
function human:get_sold_out_container()
    return self.sold_out_container
end

-- 获取装备容器
function human:get_equip_container()
    return self.equip_container
end

-- 获取道具背包容器
function human:get_prop_bag_container()
    return self.prop_bag_container
end

-- 获取时装容器
function human:get_fasion_bag_container()
    return self.fasion_bag_container
end

-- 更新时装buff
-- @param fasionid 时装ID
-- @param buff_flag buff标志
function human:update_fasion_buff(fasionid,buff_flag)
	local env = skynet.getenv("env")
	if define.ADD_EQUIP_BUFF[env] then
		for _,dy_info in ipairs(define.ADD_EQUIP_BUFF[env]) do
			if dy_info[define.HUMAN_EQUIP.HEQUIP_FASHION] then
				local fasion_buff = dy_info[define.HUMAN_EQUIP.HEQUIP_FASHION].BUFFID
				local list = self:get_impact_list()
				local istrue
				if fasionid >= dy_info[define.HUMAN_EQUIP.HEQUIP_FASHION].MINID
				and fasionid <= dy_info[define.HUMAN_EQUIP.HEQUIP_FASHION].MAXID then
					if buff_flag then
						istrue = false
						for _, imp in ipairs(list) do
							if imp:get_data_index() == fasion_buff then
								istrue = true
								break
							end
						end
						if not istrue then
							impactenginer:send_impact_to_unit(self, fasion_buff, self, 100, false, 0)
						end
					else
						for _, imp in ipairs(list) do
							if imp:get_data_index() == fasion_buff then
								self:on_impact_fade_out(imp)
								self:remove_impact(imp)
								break
							end
						end
					end
				end
			end
		end
	end
end

-- 获取门派
function human:get_menpai()
    return self.db:get_attrib("menpai")
end

-- 获取攻击特征类型
function human:get_attack_traits_type()
    return require('cy_pvp').trait(self:get_menpai())
end

-- 获取装备列表
function human:get_equip_list()
    return self.equip_container:copy_raw_data()
end

-- 获取指定装备点的装备
-- @param equip_point 装备点
function human:get_equip(equip_point)
    return self.equip_container:get_item(equip_point)
end

-- 获取武魂外观
function human:get_wuhun_wg()
    return self.huanhun
end

-- 发送武魂外观信息
-- @param who 接收者
-- @param type 类型
-- @param id ID
function human:send_wuhun_wg(who, type, id)
    -- type = 2
    local msg = packet_def.GCWuhunWG.new()
	msg.type = type
    -- if type == 2 then
        -- msg.type = 2
        -- msg.huanhun_id = huanhun_id
    -- else
        -- msg.type = 0
        -- msg.wg = 0
    -- end
    local huanhun_unlock_count = 0
    msg.unlockd = {}
	local huanhun_id = 0
    for i = 1, 6 do
        local data = self.huanhun[tostring(i)] or self.huanhun[i]
        if data then
            table.insert(msg.unlockd, {
                id = i,
                level = tonumber(data.level) or 1,
                grade = tonumber(data.grade) or 0,
                today_count = tonumber(data.today_count) or 0,
            })
            huanhun_unlock_count = huanhun_unlock_count + 1
            huanhun_id = i
        end
    end
    if type == 2 then
        msg.huanhun_id = id or huanhun_id
    else
        msg.wg = id or 0
    end
	
    -- msg.huanhun_id = huanhun_id or 0
    msg.huanhun_unlock_count = huanhun_unlock_count
    self.scene:send2client(who, msg)
end

-- 获取技能等级
-- @param skill_id 技能ID
function human:get_skill_level(skill_id)
    local template = skillenginer:get_skill_template(skill_id)
    assert(template, tostring(skill_id))
    local xinfa_id = template.xinfa
    local xinfa = self:get_xinfa(xinfa_id)
    if xinfa then
        return math.ceil(xinfa.m_nXinFaLevel / 10) + 1
    else
        return character.get_skill_level(self, skill_id)
    end
end

-- 添加领悟技能
-- @param skill 技能
function human:add_lingwu_skill(skill)

end

-- 获取物品背包列表
function human:get_item_bag_list()
    return self.prop_bag_container:copy_raw_data()
end

-- 获取时装背包列表
function human:get_fasion_bag_list()
    return self.fasion_bag_container:copy_raw_data()
end

-- 获取心法列表
function human:get_xinfa_list()
    return self.xinfa_list
end

-- 获取天赋数据
function human:get_talent()
    return self.talent
end

-- 获取指定心法
-- @param id 心法ID
function human:get_xinfa(id)
    for _, xinfa in ipairs(self.xinfa_list) do
        if xinfa.m_nXinFaID == id then
            return xinfa
        end
    end
end

-- 学习心法
-- @param id 心法ID
-- @param level 等级
function human:study_xinfa(id, level)
    for _, xinfa in ipairs(self.xinfa_list) do
        if xinfa.m_nXinFaID == id then
            xinfa.m_nXinFaLevel = level
            break
        end
    end
    self.db:mark_all_attr_dirty() -- Minimum xinfa changes cultivation multipliers.
    local learn_new_skill = self:on_study_xinfa(id, level)
    if learn_new_skill then
        self:send_skill_list()
    end
end

-- 学习心法后的处理
-- @param id 心法ID
-- @param level 等级
function human:on_study_xinfa(id, level)
    local skills = {}
    local learn_new_skill = false
    local menpai = self:get_attrib("menpai")
    if id == define.MENPAI_7_XINFA[menpai] or id == define.MENPAI_8_XINFA[menpai] then
        return
    end
    local templates = skillenginer:get_skill_templates()
    for _, template in pairs(templates) do
        if template.class_by_user == 0 and template.xinfa == id
            and (template.xinfa_level_require or 0) <= level then
            skills[template.id] = true
        end
    end
    for skill in pairs(skills) do
        local find = false
        local exist_skills = self:get_skill_list()
        for _, es in ipairs(exist_skills) do
            if skill == es then
                find = true
                break
            end
        end
        if not find then
            self:add_skill(skill)
            learn_new_skill = true
        end
    end
    return learn_new_skill
end

-- 获取生活技能列表
function human:get_ability_list()
    return self.ability_list
end

-- 获取配方列表
function human:get_prescriptions()
    return self.prescriptions
end

-- 检查是否拥有生活技能
-- @param id 生活技能ID
function human:have_ability(id)
    return self:get_ability(id) ~= nil
end

-- 获取指定生活技能
-- @param id 生活技能ID
function human:get_ability(id)
    for _, ability in ipairs(self.ability_list) do
        if ability.id == id then
            return ability
        end
    end
end

-- 学习生活技能
-- @param id 生活技能ID
-- @param exp 经验值
-- @param level 等级
function human:cy_four_crafting_learn(faction)
    return require("cy_four_crafting").learn(self, faction)
end

function human:cy_four_training_quote(faction, kind, id)
    return require("cy_four_training").quote(self, faction, kind, id)
end

function human:cy_four_training_perform(faction, kind, id, previous)
    return require("cy_four_training").perform(self, faction, kind, id, previous)
end

function human:study_ability(id, exp, level)
    local to_set_ability
    for _, ability in ipairs(self.ability_list) do
        if ability.id == id then
            to_set_ability = ability
            break
        end
    end
    if to_set_ability then
        to_set_ability.level = level
    else
        table.insert(self.ability_list, { id = id, exp = exp, level = level})
    end
    self:on_study_ability(id, level)
end

-- 增加生活技能经验
-- @param id 生活技能ID
-- @param exp 经验值
function human:add_ability_exp(id, exp)
    local ability = self:get_ability(id)
    ability.exp = ability.exp + exp
end

-- 设置生活技能经验
-- @param id 生活技能ID
-- @param exp 经验值
-- @param exp_top 经验上限
function human:set_ability_exp(id, exp, exp_top)
    local ability = self:get_ability(id)
    ability.exp = exp
    local msg = packet_def.GCAbilityExp.new()
    msg.ability = id
    msg.exp = exp
    msg.exp_top = exp_top or 0
    self:get_scene():send2client(self, msg)
end

-- 获取生活技能经验
-- @param id 生活技能ID
function human:get_ability_exp(id)
    local ability = self:get_ability(id)
    return ability.exp
end

-- 学习配方
-- @param id 配方ID
-- @param flag 标志（true=学习，false=放弃）
function human:study_prescription(id, flag)
    if id < 0 or id > define.MAX_ABILITY_PRESCRIPTION_NUM then
        assert(false, id)
        return
    end
    local index = (id >> 3) + 1
    local bit = 0x01 << id % 8
    --print("human:study_prescription id =", id, ";index =", index, ";bit =", bit)
    index = tostring(index)
    if flag then
        self.prescriptions[index] = (self.prescriptions[index] or 0) | bit
    else
        self.prescriptions[index] = (self.prescriptions[index] or 0)  & ~bit
    end
    local msg = packet_def.GCPrescription.new()
    msg.id = id
    msg.learn_or_abandon = flag and 1 or 0
    self.scene:send2client(self, msg)
end

-- 检查配方是否已学习
-- @param id 配方ID
function human:is_prescription_have_learnd(id)
    if id < 0 or id > define.MAX_ABILITY_PRESCRIPTION_NUM then
        assert(false, id)
        return false
    end
    local index = (id >> 3) + 1
    local bit = 0x01 << id % 8
    index = tostring(index)
    return (self.prescriptions[index] or 0) & bit == bit
end

-- 发送生活技能列表
function human:send_ability_list()
    local ability_list = self:get_ability_list()
    local prescriptions = self:get_prescriptions()
    local ret = packet_def.GCDetailAbilityInfo.new()
    ret.m_aAbility = {}
    ret.m_uAbilityIDList = {}
    for _, ability in ipairs(ability_list) do
        local ab = { m_Exp = ability.exp, m_Level = ability.level}
        table.insert(ret.m_aAbility, ab)
        table.insert(ret.m_uAbilityIDList, ability.id)
    end
    ret.m_objID = self:get_obj_id()
    ret.m_wNumAbility = #ability_list
    ret.m_aPrescr = {}
    for i = 1, 0x100 do
        i = tostring(i)
        table.insert(ret.m_aPrescr, prescriptions[i] or 0)
    end
    self:get_scene():send2client(self, ret)
end

-- 停止角色逻辑
-- @param ... 参数
function human:stop_character_logic(...)
    self.character_logic_stopped = true
    self:on_stop_character_logic(...)
    self:set_character_logic(define.ENUM_CHARACTER_LOGIC.CHARACTER_LOGIC_IDLE)
end


-- 学习生活技能后的处理
-- @param id 生活技能ID
-- @param level 等级
function human:on_study_ability(id, level)
    local msg = packet_def.GCAbilityLevel.new()
    msg.id = id
    msg.level = level
    self.scene:send2client(self, msg)
end

-- 清空心法列表
function human:clear_xinfa_list()
    self.xinfa_list = {}
end

-- 获取技能列表
function human:get_skill_list()
    return self.skill_list
end

-- 获取武魂技能列表
function human:get_wuhun_skills()
    local soul=self:get_equip_container():get_item(18)
    if soul and require('cys_dual_souls').definition(soul:get_index()) then return require('cys_dual_souls').skills(self,18) end
    local result={}
    local item=self:get_equip_container():get_item(define.HUMAN_EQUIP.HEQUIP_WUHUN)
    if not item or item:get_equip_data():get_wh_life()<=0 then return result end
    local ed=item:get_equip_data();local skills=ed:get_wh_skill()
    for i,required in ipairs({40,70,90})do
        if ed:get_wh_level()>=required and require('cy_equipment_skills').wuhun_valid(skills[i],i) then
            result[#result+1]=skills[i]
        end
    end
    return result
end

-- 获取装备附加技能列表
function human:get_equip_add_skills()
    local skills = {}
    local equip_add_skills = self.db:get_equip_add_skills()
    for sk in pairs(equip_add_skills) do
        if sk ~= define.INVAILD_ID then
            table.insert(skills, sk)
        end
    end
    return skills
end

-- 获取所有技能列表
function human:get_total_skills_list()
    local total = {}
    for _,id in ipairs(self:get_skill_list())do
        if id<274 or id>276 then total[#total+1]=id end
    end
    local shenbing = self:get_equip_container():get_item(define.HUMAN_EQUIP.SHENBING)
    if shenbing then
        local shenbing_skill = shenbing:get_equip_data():get_fwq_change_skill()
		if shenbing_skill ~= -1 then
			table.insert(total, shenbing_skill)
		end
	end
    local dark=self:get_equip_container():get_item(define.HUMAN_EQUIP.HEQUIP_ANQI)
    if dark then
        local ed=dark:get_equip_data();local helper=require('cy_equipment_skills')
        for i,required in ipairs({40,70,90})do
            if ed:get_aq_xiulian()>=required and helper.dark_kind(i,ed:get_aq_skill(i)) then
                local id=273+i
                local found=false;for _,owned in ipairs(total)do if owned==id then found=true end end
                if not found then total[#total+1]=id end
            end
        end
    end
    for _,id in ipairs(require('cys_dual_souls').skills(self,39)) do total[#total+1]=id end
    local wh_skills = self:get_wuhun_skills()
    local equip_skills = self:get_equip_add_skills()
    for _, sk in ipairs(wh_skills) do
        table.insert(total, sk)
    end
    for _, sk in ipairs(equip_skills) do
        table.insert(total, sk)
    end
    return total
end

-- 检查是否拥有技能
-- @param skill 技能ID
function human:have_skill(skill)
    local skills = self:get_total_skills_list()
    for _, id in ipairs(skills) do
        if id == skill then
            return true
        end
    end
    return false
end

-- 清除门派技能
function human:clear_menpai_skills()
    for i = #self.skill_list, 1, -1 do
        local skill = self.skill_list[i]
        local template = skillenginer:get_skill_template(skill)
        if template.menpai ~= define.INVAILD_ID then
            table.remove(self.skill_list, i)
        end
    end
end

-- 检查是否可以立即使用技能
function human:can_use_skill_now()
    if self:get_action_time() > 0 then
        return false
    end
    if not actionenginer:can_do_next_action(self) then
        return false
    end
    return true
end

-- 获取对象类型
function human:get_obj_type()
    return "human"
end

-- 获取代理
function human:get_agent()
    return self.agent
end

-- 获取外观列表
function human:get_exterior_list()
    return self.exterior
end

-- 获取数据库对象
function human:get_db()
    return self.db
end

-- 获取坐骑
function human:get_ride()
    return self.db:get_attrib("ride")
end

-- 获取坐骑模型
function human:get_ride_model()
    return self.db:get_attrib("ride_model")
end

-- 获取模型ID
function human:get_model_id()
    return self.db:get_attrib("model_id")
end

-- 获取物品属性值
-- @param ia 物品属性
function human:item_value(ia)
    return self.db:get_item_effect(ia)
end
function human:damage_rate()
    return self.db:get_damage_rate()
end
-- 设置服务器ID
-- @param server_id 服务器ID
function human:set_server_id(server_id)
    self.db:set_not_gen_attrib({ server_id = server_id })
end

-- 获取服务器ID
function human:get_server_id()
    return self.db:get_attrib("server_id")
end

-- 设置帮派ID
-- @param guild_id 帮派ID
function human:set_guild_id(guild_id)
    self.db:set_db_attrib({ guild_id = guild_id })
end

-- 设置帮派名称
-- @param guild_name 帮派名称
function human:set_guild_name(guild_name)
    self.db:set_db_attrib({ guild_name = guild_name })
end

-- 设置联盟ID
-- @param confederate_id 联盟ID
function human:set_confederate_id(confederate_id)
    self.db:set_db_attrib({ confederate_id = confederate_id })
end

-- 设置联盟名称
-- @param confederate_name 联盟名称
function human:set_confederate_name(confederate_name)
    self.db:set_db_attrib({ confederate_name = confederate_name })
end

-- 获取联盟名称
function human:get_confederate_name()
    return self.db:get_db_attrib("confederate_name")
end

-- 获取帮派ID
function human:get_guild()
    return self.db:get_db_attrib("guild_id")
end

-- 获取帮派用户信息
function human:get_guild_uinfo()
    local guinfo = {}
    guinfo.guid = self:get_guid()
    guinfo.name = self:get_name()
    guinfo.level = self:get_level()
    guinfo.menpai = self:get_menpai()
    return guinfo
end

-- 获取荣誉值
function human:get_honour()
    return self.db:get_db_attrib("honour") or 0
end

-- 设置荣誉值
-- @param honour 荣誉值
function human:set_honour(honour)
    self.db:set_db_attrib({ honour = honour})
end

-- 设置坐骑
-- @param ride 坐骑
function human:set_ride(ride)
    -- CYS-MOUNT-FLIGHT
    if require('cys_mount_flight').active(self) then self:notify_tips('Hãy hạ cánh trước khi đổi thú cưỡi.');return end
    -- print("human:set_ride m_objID =", self.m_objID, ";ride =", ride)
    self.db:set_db_attrib({ride = ride})
    exterior_bonus.refresh_bonus(self)
end

-- 获取坐骑模型
function human:get_ride_model()
    return self.db:get_attrib("ride_model")
end

-- 设置发色
-- @param hair_color 发色
function human:set_hair_color_ex(hair_color)
	-- if self:get_hair_color() ~= hair_color then
		-- local guid = self:get_guid()
        -- skynet.send(".world", "lua", "update_uinfo", guid, {hair_color = hair_color})
	-- end
    self.db:set_db_attrib({ hair_color = hair_color})
end

-- 添加发色
-- @param hair_color 发色
function human:add_hair_color(hair_color)
    -- self.db:set_db_attrib({ hair_color = hair_color})
	self:set_hair_color_ex(hair_color)
    self:save_hair_color(hair_color)
end

-- 设置发色
-- @param hair_index 发色索引
function human:set_hair_color(hair_index)
    local my_hair_colors = self.exterior.hair_colors or {}
    local hair_color = my_hair_colors[hair_index]
    if hair_color or hair_index == 1 then
        hair_color = hair_color or { value = 0 }
		self:set_hair_color_ex(hair_color.value)
        -- self.db:set_db_attrib({ hair_color = hair_color.value})
        self:set_exterior_hair_color_index(hair_index)
    end
end

-- 根据颜色值获取发色索引
-- @param color_value 颜色值
function human:get_hair_color_index_by_color_value(color_value)
    local my_hair_colors = self.exterior.hair_colors or {}
    local my_hair_colors = self.exterior.hair_colors or {}
    my_hair_colors[1] = my_hair_colors[1] or { value = 0 }
    for i = 1, 20 do
        local hc = my_hair_colors[i]
        if hc and hc.value == color_value then
            return i
        end
    end
end

-- 保存发色
-- @param hair_color 发色
function human:save_hair_color(hair_color)
    local index = 1
    local my_hair_colors = self.exterior.hair_colors or {}
    my_hair_colors[1] = my_hair_colors[1] or { value = 0 }
    for i = 1, 20 do
        local hc = my_hair_colors[i]
        if i ~= 1 and (hc == nil or hc.value == 0) then
            index = i
            break
        end
    end
    self.exterior.hair_colors = my_hair_colors
    self.exterior.hair_colors[index] = { value = hair_color }
    self:set_exterior_hair_color_index(index)
    self:send_exterior_info(5)
end

-- 获取武器外观等级
-- @param visual 外观ID
function human:get_weapon_visual_level(visual)
    local my_exterior_weapon_visuals = self.exterior.weapon_visuals or {}
    local visual_data = self:get_exterior_weapon_visual_data(visual)
	if visual_data then
		return visual_data.level
	end
	return -1
end

-- 设置武器外观等级
-- @param visual 外观ID
-- @param level 等级
function human:set_weapon_visual_level(visual,level)
	for i,j in ipairs(self.exterior.weapon_visuals) do
		if j.id == visual then
			j.level = level
			self:send_exterior_info()
			break
		end
	end
end

-- 激活武器外观
-- @param visual 外观ID
function human:active_weapon_visual(visual)
    local my_exterior_weapon_visuals = self.exterior.weapon_visuals or {}
    local visual_data = self:get_exterior_weapon_visual_data(visual)
    if visual_data == nil then
        table.insert(my_exterior_weapon_visuals, { id = visual, level = 0, term = define.INVAILD_ID})
    end
    self.exterior.weapon_visuals = my_exterior_weapon_visuals
    -- 武器外观收藏列表变动，刷新外观属性加成
    exterior_bonus.refresh_bonus(self)
end


-- 设置外观武器外观ID
-- @param index 索引
-- @param level 等级
function human:set_exterior_weapon_visual_id(index,level)
    self.db:set_db_attrib({exterior_weapon_visual_id = index})
	level = level or 0
    self.db:set_db_attrib({exterior_weapon_selcet_level = level})
    self:get_scene():broad_char_equioment(self,define.HUMAN_EQUIP.HEQUIP_WEAPON)
	local visual,eqid = 0,-1
	if index > 0 then
		local exterior_weapon_visual = configenginer:get_config("exterior_weapon_visual")
		exterior_weapon_visual = exterior_weapon_visual[index]
		if exterior_weapon_visual then
			local visuals = exterior_weapon_visual["外观ID"]
			if visuals and visuals[level + 1] then
				visual = visuals[level + 1]
				eqid = exterior_weapon_visual["道具ID"]
			end
		end
	end
	self.game_flag.hs_visual = visual
	self.game_flag.hs_index = eqid
	exterior_bonus.refresh_bonus(self)
end

-- 获取外观武器外观ID
function human:get_exterior_weapon_visual_id()
    local index = self.db:get_db_attrib("exterior_weapon_visual_id") or 0
	local select_level = self.db:get_db_attrib("exterior_weapon_selcet_level") or 0
    return index,select_level
end

-- 获取外观武器外观数据
-- @param id 外观ID
function human:get_exterior_weapon_visual_data(id)
    local my_exterior_weapon_visuals = self.exterior.weapon_visuals or {}
    for _, visual in ipairs(my_exterior_weapon_visuals) do
        if visual.id == id then
            return visual
        end
    end
end

-- 获取外观武器外观
function human:get_exterior_weapon_visual()
    local exterior_weapon_visual = configenginer:get_config("exterior_weapon_visual")
    local id,select_level = self:get_exterior_weapon_visual_id()
    local visual = self:get_exterior_weapon_visual_data(id)
    if visual and select_level <= visual.level then
        exterior_weapon_visual = exterior_weapon_visual[visual.id]
		if exterior_weapon_visual then
			local visuals = exterior_weapon_visual["外观ID"]
			if visuals then
				return visuals[select_level + 1],exterior_weapon_visual["道具ID"]
			end
		end
    end
end

-- 设置神兵状态
-- @param change 状态变化
function human:set_shenbind_status(change)
	local scene = self:get_scene()
	local sceneId = scene:get_id()
	local selfId = self:get_obj_id()
	local msg = packet_def.GCSecWeaponAddSkillList.new()
	msg.selfId = selfId
	if change > 0 then
		local shenbing = self:get_equip_container():get_item(define.HUMAN_EQUIP.SHENBING)
		if shenbing then
			self:set_game_flag_key("sb_change",change)
			local equip_data = shenbing:get_equip_data()
			local fwq_passive_skill = equip_data:get_fwq_passive_skill()
			self:set_game_flag_key("fwq_passive_skill",fwq_passive_skill)
			local fwq_skill_list_1 = equip_data:get_fwq_skill_list_1()
			local fwq_skill_list_2 = equip_data:get_fwq_skill_list_2()
			local fwq_list_2 = equip_data:get_fwq_list_2()
			msg.skillId = {
			fwq_passive_skill,
			fwq_skill_list_1[1],
			fwq_skill_list_1[2],
			-1,-1,-1,4435}
			for i,j in ipairs(fwq_skill_list_2) do
				if fwq_list_2[i] == 1 then
					msg.skillId[2 + i] = j
				end
			end
			msg.commonskillA = fwq_skill_list_1[1]
			msg.commonskillB = fwq_skill_list_1[2]
			msg.is_hide = 0
			msg.is_update = 1
			scene:send2client(self, msg)
			self.ai:update_auto_use_skill(fwq_passive_skill)
		else
			self:set_game_flag_key("sb_change",0)
			self:set_game_flag_key("fwq_passive_skill",0)
			msg.skillId = {-1,-1,-1,-1,-1,-1,-1}
			msg.commonskillA = -1
			msg.commonskillB = -1
			msg.is_hide = 1
			msg.is_update = 1
			scene:send2client(self, msg)
			self.ai:update_auto_use_skill()
		end
	else
		self:set_game_flag_key("sb_change",0)
		self:set_game_flag_key("fwq_passive_skill",0)
		msg.skillId = {-1,-1,-1,-1,-1,-1,-1}
		msg.commonskillA = -1
		msg.commonskillB = -1
		msg.is_hide = 1
		msg.is_update = 1
		scene:send2client(self, msg)
		self.ai:update_auto_use_skill()
	end
	-- msg.is_update = 1
	-- scene:send2client(self, msg)
    local ret = packet_def.GCCharEquipment.new()
    ret.m_objID = self:get_obj_id()
    ret.flag = 0
	local visual,item_index,gemid = self:get_cur_weapon_visual(sceneId)
	ret:set_weapon(item_index,gemid,visual)
	scene:send2client(self, ret)
	scene:broadcast(self, ret, true)
end
-- 获取当前武器外观
-- @param sceneId 场景ID
function human:get_cur_weapon_visual(sceneId)
	local equip_container = self:get_equip_container()
	local sb_change = self:get_game_flag_key("sb_change")
	if sb_change > 0 then
		local sb_is_alive = true
		local sb_on_scene = self:get_game_flag_key("sb_on_scene")
		if sb_on_scene ~= sceneId then
			sb_is_alive = false
			self:set_game_flag_key("sb_on_scene",sceneId)
			local list = self:get_impact_list()
			for _, imp in ipairs(list) do
				if imp:get_data_index() == sb_change then
					sb_is_alive = true
					break
				end
			end
		end
		if sb_is_alive then
			local shenbing = equip_container:get_item(define.HUMAN_EQUIP.SHENBING)
			if shenbing then
				local equip_data = shenbing:get_equip_data()
				local sb_visual = equip_data:get_visual()
				local sb_actid = equip_data:get_action()
				local sb_gem = equip_data:get_slot_gem(1)
				if sb_visual > 0 and sb_actid > 0 then
					self:set_game_flag_keys_visual(define.HUMAN_EQUIP.HEQUIP_WEAPON,
					{
					[define.WG_KEY_A] = sb_actid,
					[define.WG_KEY_B] = sb_gem,
					[define.WG_KEY_C] = sb_visual
					})
					return sb_visual,sb_actid,sb_gem
				end
			else
				sb_is_alive = false
			end
		end
		if not sb_is_alive then
			local msg = packet_def.GCSecWeaponAddSkillList.new()
			msg.selfId = self:get_obj_id()
			msg.skillId = {-1,-1,-1,-1,-1,-1,-1}
			msg.commonskillA = -1
			msg.commonskillB = -1
			msg.is_hide = 1
			msg.is_update = 1
			self:get_scene():send2client(self, msg)
			self.ai:update_auto_use_skill()
		end
	end
	local weapon = equip_container:get_item(define.HUMAN_EQUIP.HEQUIP_WEAPON)
	if not weapon then
		self:set_game_flag_keys_visual(define.HUMAN_EQUIP.HEQUIP_WEAPON,
		{
		[define.WG_KEY_A] = -1,
		[define.WG_KEY_B] = -1,
		[define.WG_KEY_C] = 0
		})
		return 0,-1,-1
	end
	local weap_exterior_visual,weapon_id = self:get_exterior_weapon_visual()
	if weap_exterior_visual then
		self:set_game_flag_keys_visual(define.HUMAN_EQUIP.HEQUIP_WEAPON,
		{
		[define.WG_KEY_A] = weapon_id,
		[define.WG_KEY_B] = -1,
		[define.WG_KEY_C] = weap_exterior_visual
		})
		return weap_exterior_visual,weapon_id,-1
	end
	local equip_data = weapon:get_equip_data()
	local visual = equip_data:get_visual()
	local index = weapon:get_index()
	local gemid = equip_data:get_slot_gem(1)
	if gemid == 0 then
		gemid = -1
	end
		self:set_game_flag_keys_visual(define.HUMAN_EQUIP.HEQUIP_WEAPON,
		{
		[define.WG_KEY_A] = index,
		[define.WG_KEY_B] = gemid,
		[define.WG_KEY_C] = visual
		})
	return visual,index,gemid
end

-- 设置外观脸型索引
-- @param index 索引
function human:set_exterior_face_style_index(index)
    self.db:set_db_attrib({exterior_face_style_index = index})
end

-- 获取外观脸型索引
function human:get_exterior_face_style_index()
    return self.db:get_db_attrib("exterior_face_style_index")
end

-- 设置外观发型索引
-- @param index 索引
function human:set_exterior_hair_style_index(index)
    self.db:set_db_attrib({exterior_hair_style_index = index})
end

-- 获取外观发型索引
function human:get_exterior_hair_style_index()
    return self.db:get_db_attrib("exterior_hair_style_index")
end

-- 设置外观发色索引
-- @param index 索引
function human:set_exterior_hair_color_index(index)
    self.db:set_db_attrib({exterior_hair_color_index = index})
end

-- 获取外观发色索引
function human:get_exterior_hair_color_index()
    local index = self.db:get_db_attrib("exterior_hair_color_index")
    index = index or 0
    index = index == 0 and 1 or index
    return index
end

-- 设置外观头像索引
-- @param index 索引
function human:set_exterior_portrait_index(index)
    self.db:set_db_attrib({exterior_portrait_index = index})
end

-- 获取外观头像索引
function human:get_exterior_portrait_index()
    return self.db:get_db_attrib("exterior_portrait_index")
end

-- 设置外观宠物灵魂ID
-- @param id 宠物灵魂ID
function human:set_exterior_pet_soul_id(id)
    self.db:set_db_attrib({exterior_pet_soul_id = id})
end

-- 获取外观宠物灵魂ID
-- @param ids 宠物灵魂ID
function human:get_exterior_pet_soul_id(ids)
    return self.db:get_db_attrib("exterior_pet_soul_id")
end

function human:set_exterior_equip_pet_soul_id(id)
    self.db:set_db_attrib({exterior_equip_pet_soul_id = id})
end

function human:get_exterior_equip_pet_soul_id()
    return self.db:get_db_attrib("exterior_equip_pet_soul_id") or 0
end

-- 设置时装仓库索引
-- @param index 索引
function human:set_fashion_depot_index(index)
    self.db:set_db_attrib({fashion_depot_index = index})
end

-- 获取时装仓库索引
function human:get_fashion_depot_index()
    return self.db:get_attrib("fashion_depot_index")
end

-- 获取宠物灵魂融合等级
function human:get_pet_soul_melting_level()
    local soul_melting_pet_guid = self.db:get_attrib("soul_melting_pet_guid")
    if soul_melting_pet_guid:is_null() then
        return define.INVAILD_ID
    end
    local pet_detail = self:get_pet_bag_container():get_pet_by_guid(soul_melting_pet_guid)
    if pet_detail == nil then
        return define.INVAILD_ID
    end
    return pet_detail:get_pet_soul_melting_level()
end

-- 设置宠物灵魂融合模型
-- @param model 模型
function human:set_pet_soul_melting_model(model)
    self.db:set_db_attrib({ pet_soul_melting_model = model})
end


-- self.exterior.headinfo = self.exterior.headinfo or {}
-- self.exterior.backinfo = self.exterior.backinfo or {}
-- 获取外观头饰信息
function human:get_exterior_head_info()
	return self.exterior.headinfo
end

-- 根据ID获取外观头饰
-- @param id 头饰ID
function human:get_exterior_head_by_id(id)
	for i,j in ipairs(self.exterior.headinfo) do
		if j.id == id then
			return j
		end
	end
end

-- 获取外观背饰信息
function human:get_exterior_back_info()
	return self.exterior.backinfo
end

-- 根据ID获取外观背饰
-- @param id 背饰ID
function human:get_exterior_back_by_id(id)
	for i,j in ipairs(self.exterior.backinfo) do
		if j.id == id then
			return j
		end
	end
end

-- 设置外观头饰位置
-- @param id 头饰ID
-- @param posx X坐标
-- @param posy Y坐标
-- @param posz Z坐标
function human:set_exterior_head_pos(id,posx,posy,posz)
	for i,j in ipairs(self.exterior.headinfo) do
		if j.id == id then
			j.x = posx
			j.y = posy
			j.z = posz
			return true
		end
	end
end

-- 设置外观背饰位置
-- @param id 背饰ID
-- @param posx X坐标
-- @param posy Y坐标
-- @param posz Z坐标
function human:set_exterior_back_pos(id,posx,posy,posz)
	for i,j in ipairs(self.exterior.backinfo) do
		if j.id == id then
			j.x = posx
			j.y = posy
			j.z = posz
			return true
		end
	end
end

-- 设置外观头饰ID
-- @param add 头饰数据
function human:set_exterior_head_id(add)
	for i,j in ipairs(self.exterior.headinfo) do
		if j.id == add.id then
			return false
		end
	end
	table.insert(self.exterior.headinfo,add)
	return true
end

-- 设置外观背饰ID
-- @param add 背饰数据
function human:set_exterior_back_id(add)
	for i,j in ipairs(self.exterior.backinfo) do
		if j.id == id then
			return false
		end
	end
	table.insert(self.exterior.backinfo,add)
	return true
end

-- 获取外观头饰外观ID
function human:get_exterior_head_visual_id()
    local index = self.db:get_db_attrib("exterior_head_id") or 0
	local pos = self.db:get_db_attrib("exterior_head_pos") or 0
    return index,pos
end

-- 设置外观头饰外观ID
-- @param id 头饰ID
-- @param pos 位置
function human:set_exterior_head_visual_id(id,pos)
    self.db:set_db_attrib({exterior_head_id = id})
    self.db:set_db_attrib({exterior_head_pos = pos})
end

-- 获取外观背饰外观ID
function human:get_exterior_back_visual_id()
    local index = self.db:get_db_attrib("exterior_back_id") or 0
	local pos = self.db:get_db_attrib("exterior_back_pos") or 0
    return index,pos
end

-- 设置外观背饰外观ID
-- @param id 背饰ID
-- @param pos 位置
function human:set_exterior_back_visual_id(id,pos)
    self.db:set_db_attrib({exterior_back_id = id})
    self.db:set_db_attrib({exterior_back_pos = pos})
end

-- 设置头像ID
-- @param id 头像ID
function human:set_portrait_id(id)
	-- if self:get_portrait_id() ~= id then
		-- local guid = self:get_guid()
        -- skynet.send(".world", "lua", "update_uinfo", guid, {portrait_id = id})
	-- end
    self.db:set_db_attrib({portrait_id = id})
    skynet.error("[human] set_portrait_id id="..tostring(id).." guid="..tostring(self:get_guid()))
    self:send_exterior_info()
end

-- 获取头像ID
function human:get_portrait_id()
    return self.db:get_db_attrib("portrait_id")
end

-- 设置脸型
-- @param id 脸型ID
function human:set_face_style(id)
	-- if self:get_face_style() ~= id then
		-- local guid = self:get_guid()
        -- skynet.send(".world", "lua", "update_uinfo", guid, {face_id = id})
	-- end
    self.db:set_db_attrib({face_style = id})
    skynet.error("[human] set_face_style id="..tostring(id).." guid="..tostring(self:get_guid()))
    self:send_exterior_info()
end

-- 设置发型
-- @param id 发型ID
function human:set_hair_style(id)
	-- if self:get_hair_style() ~= id then
		-- local guid = self:get_guid()
        -- skynet.send(".world", "lua", "update_uinfo", guid, {hair_id = id})
	-- end
    self.db:set_db_attrib({hair_style = id})
    skynet.error("[human] set_hair_style id="..tostring(id).." guid="..tostring(self:get_guid()))
    self:send_exterior_info()
end

-- 获取金币数量
function human:get_money()
    return self:get_attrib("money")
end

-- 获取交子数量
function human:get_jiaozi()
    return self:get_attrib("jiaozi")
end

-- 设置心情
-- @param mood 心情
function human:set_mood(mood)
    self.relation_list.mood = mood or "还没想好"
    local cur_title = self:get_cur_title()
    if cur_title and cur_title.id == define.TITILE.MOOD then
        self:set_title(define.TITILE.MOOD, mood)
    end
end

-- 获取心情
function human:get_mood()
    return self.relation_list.mood or "还没想好"
end

-- 设置金币数量
-- @param money 金币数量
-- @param reason 原因
-- @param extra 额外信息
function human:set_money(money, reason, extra)
    if money < 0 then
        return false
    end
    money = math.ceil(money)
    money = money > define.INT32_MAX and define.INT32_MAX or money
    money = money < 0 and 0 or money
    local before = self:get_money()
    self.db:set_db_attrib({money = money})
    self:log_money_rec(reason, "金币", before, money - before, extra)
    return true
end

-- 设置交子数量
-- @param money 交子数量
-- @param reason 原因
-- @param extra 额外信息
function human:set_jiaozi(money, reason, extra)
    if money < 0 then
        return false
    end
    money = money > define.INT32_MAX and define.INT32_MAX or money
    money = money < 0 and 0 or money
    money = math.ceil(money)
    local before = self:get_jiaozi()
    self.db:set_db_attrib({jiaozi = money})
    self:log_money_rec(reason, "交子", before, money - before, extra)
    return true
end

-- 获取元宝数量
function human:get_yuanbao()
    return self:get_attrib("yuanbao")
end

-- 设置元宝数量
-- @param yuanbao 元宝数量
-- @param reason 原因
-- @param extra 额外信息
-- @param top_true 是否更新排行榜
function human:set_yuanbao(yuanbao, reason, extra, top_true)
    if yuanbao < 0 then
		assert(false,"human:set_yuanbao 设置元宝数为负值。")
        return
    end
    local oldyb = self:get_yuanbao()
    yuanbao = yuanbao > define.INT32_MAX and define.INT32_MAX or yuanbao
    self.db:set_db_attrib({yuanbao = yuanbao})
	local sub_yb = yuanbao - oldyb
    self:log_money_rec(reason, "元宝", oldyb, sub_yb, extra)
	if not top_true and sub_yb < 0 then
		local params = {
			guid = self:get_guid(),
			name = self:get_name(),
			menpai = self:get_menpai(),
			money_yb = -1 * sub_yb,
			money_yb_old = self.game_flag.mingdong_yb or 0,
			need_point = 0,
			need_point_old = self.game_flag.mingdong_point or 0,
			over_date = self.game_flag.mingdong_date or 0,
			end_time = self.game_flag.mingdong_time or 0,
		}
		local world_id = self:get_server_id()
		local ok, loading, money_yb, need_point, over_date, end_time = pcall(function()
			return skynet.call(define.CACHE_NODE, "lua", "update_mingdong_top", world_id, params)
		end)

		if not ok then
			skynet.error("update_mingdong_top 排行服务未成功启动:", loading)
			loading, money_yb, need_point, over_date, end_time = nil, nil, nil, nil, nil
		else
			if loading == 1 then
				self.game_flag.mingdong_yb = money_yb
				self.game_flag.mingdong_point = need_point
				if over_date then
					self.game_flag.mingdong_date = over_date
				end
				if end_time then
					self.game_flag.mingdong_time = end_time
				end
			end
		end
		-- local loading,money_yb,need_point,over_date,end_time = skynet.call(define.CACHE_NODE,"lua","update_mingdong_top",world_id,params)
	end
    return true
end

-- 扣除元宝
-- @param count 扣除数量
-- @param reason 原因
-- @param extra 额外信息
-- @param top_true 是否更新排行榜
function human:cost_yuanbao(count, reason, extra,top_true)
	assert(count >= 1,count)
    local yuanbao = self:get_yuanbao()
    if yuanbao < count then
        return false
    end
    yuanbao = yuanbao - count
    self:set_yuanbao(yuanbao, reason, extra,top_true)
    return true
end

-- 增加元宝
-- @param count 增加数量
-- @param reason 原因
-- @param extra 额外信息
function human:add_yuanbao(count, reason, extra)
    if count < 0 then
        return false
    end
    local yuanbao = self:get_yuanbao()
    yuanbao = yuanbao + count
    self:set_yuanbao(yuanbao, reason, extra)
    return true
end

-- 设置门派
-- @param menpai 门派ID
function human:set_menpai(menpai)
    if menpai ~= menpai_registry.NONE_ID then
        local ready, reason = menpai_registry.check_ready(define, menpai, function(name)
            return configenginer:get_config(name)
        end)
        if not ready then return false, reason end
    end
    self.db:set_db_attrib({menpai = menpai})
    local reputation = define.MENPAI_REPUTATIONS[menpai]
    self.db:set_db_attrib({reputation = reputation})
    return true
end

-- 设置经验值
-- @param exp 经验值
function human:set_exp(exp)
    if exp < 0 then
        return false
    end
    exp = exp > define.INT32_MAX and define.INT32_MAX or exp
    self.db:set_db_attrib({exp = exp})
    return true
end

-- 获取经验值
function human:get_exp()
    return self.db:get_db_attrib("exp")
end

-- 更新经验值
-- @param exp 经验值
function human:update_exp(exp)
    self.db:set_db_attrib({exp = exp})
end

-- 获取队伍GUID
function human:get_team_guid()
    return define.INVAILD_ID
end

-- 增加经验值
-- @param add_exp 增加的经验值
-- @param pet_add_exp 宠物增加的经验值
-- @param is_from_monster 是否来自怪物
function human:add_exp(add_exp, pet_add_exp, is_from_monster)
    local scale = 1
	local count = self:get_today_kill_monster_count()
	local env = skynet.getenv("env")
	local value = define.HEAVY_ANTI_ADDICTION_KILL_MONSTER_COUNT[env] or define.HEAVY_ANTI_ADDICTION_KILL_MONSTER_COUNT["moren"]
	if count >= value then
		return
	end
	value = define.MILD_ANTI_ADDICTION_KILL_MONSTER_COUNT[env] or define.MILD_ANTI_ADDICTION_KILL_MONSTER_COUNT["moren"]
	if count >= value then
		scale = 0.5
	end
    -- add_exp = math.ceil(add_exp * scale)
    add_exp = math.ceil(add_exp * scale)
    pet_add_exp =  math.ceil(pet_add_exp * scale)
    local award_exp = 0
    local pet_award_exp = 0
    local wujing_mult = 1  -- 武境灵丹倍率（函数级作用域，五五分配段也需使用）
    if is_from_monster then
		-- local env_exp_rate = define.ADD_EXP_RATE[env] or 0
		local mult = self:get_double_exp_mult()
		-- mult = mult + env_exp_rate
		local pet_exp_mult = self:get_pet_exp_mult()
		-- pet_exp_mult = pet_exp_mult + env_exp_rate
		-- 【武境灵丹】检测BUFF 85，人物经验×2，不影响珍兽
		local impact_list = self:get_impact_list()
		if impact_list then
			for _, imp in ipairs(impact_list) do
				if imp:get_data_index() == 85 then
					wujing_mult = 2
					break
				end
			end
		end
		local human_mult = mult * wujing_mult
        award_exp = math.ceil(add_exp * human_mult - add_exp)
        pet_award_exp = math.ceil(pet_add_exp * (mult + pet_exp_mult) - pet_add_exp)
        -- pet_award_exp = math.ceil(pet_add_exp * pet_exp_mult - pet_add_exp)
    end
    -- 巅峰(DFeng)经验五五分配: 开启武境时，经验一半给自身，一半给武境
    -- MD 965 = 巅峰开启标记(MD_DFeng_Open), 值为1时才分配经验
    local dfeng_base_exp = 0
    local dfeng_bonus_exp = 0
    if is_from_monster and add_exp > 0 and self:get_mission_data_by_script_id(965) == 1 then
	
        -- 五五分配：一半给武境，一半给自身
        local dfeng_base = math.floor(add_exp / 2)
        local dfeng_mult = wujing_mult * (self:get_double_exp_mult() or 1)  -- 武境灵丹×经验倍率丹（玄灵丹等）
        local dfeng_exp = math.floor(dfeng_base * dfeng_mult)
        add_exp = add_exp - dfeng_base  -- 自身保留原始一半（不受武境灵丹影响）
        award_exp = math.floor(award_exp / 2)  -- 奖励经验也减半
        dfeng_base_exp = dfeng_exp  -- 标记DFeng基础经验，用于GCDetailExp包
        local dfeng_script_ok, dfeng_script_err = xpcall(function()
            local scene = self:get_scene()
            local selfId = self:get_obj_id()
            scene:get_script_engienr():call(502161, "AddWuJingExp", selfId, 0, dfeng_exp)
        end, debug.traceback)
        if not dfeng_script_ok then
            skynet.loge("[DFeng] add_exp script ERROR: ", tostring(dfeng_script_err))
        end
        -- 脚本执行完毕后，调用通用刷新函数发送属性包刷新客户端UI
        self:refresh_dfeng_attrib()
    end
    add_exp, award_exp = self:add_my_exp(add_exp, award_exp)
    local anqi_exp, anqi_award_exp = self:add_aq_exp(math.ceil(add_exp / 100), math.ceil(award_exp / 100))
    if self.pet then
        self.pet:add_exp(pet_add_exp + pet_award_exp)
    end
	local scene = self:get_scene()
	
	-- local showexp_rate = self:get_mission_data_by_script_id(615)
	-- if showexp_rate > 0 then
		-- local env = skynet.getenv("env")
		-- if env == "publish_xrx" then
			-- local sceneId = scene:get_id()
			-- if define.MONSTER_EXP_UP_SCENE[sceneId] then
				-- showexp_rate = showexp_rate + define.MONSTER_EXP_UP_SCENE[sceneId]
			-- end
		-- end
		-- add_exp = math.ceil(add_exp / showexp_rate)
		-- award_exp = math.ceil(award_exp / showexp_rate)
		-- pet_add_exp = math.ceil(pet_add_exp / showexp_rate)
		-- pet_award_exp = math.ceil(pet_award_exp / showexp_rate)
		-- anqi_exp = math.ceil(anqi_exp / showexp_rate)
		-- anqi_award_exp = math.ceil(anqi_award_exp / showexp_rate)
	-- end
    local msg = packet_def.GCDetailExp.new()
    msg.exp = add_exp
    msg.award_exp = award_exp
    msg.bb_exp = pet_add_exp
    msg.bb_award_exp = pet_award_exp
    msg.anqi_exp = anqi_exp
    msg.anqi_award_exp = anqi_award_exp
    -- DFeng经验: reserved_1=基础经验, reserved_2=奖励经验
    -- 客户端条件: exp>0 && award_exp<=0 && reserved_1>0 && reserved_2<=0 → 单行显示(DFJY_250710_6)
    -- 否则多行: 有奖励时DFJY_250710_8(reserved_1,reserved_2), 无奖励时DFJY_250710_24(reserved_1)
    msg.reserved_1 = dfeng_base_exp
    msg.reserved_2 = dfeng_bonus_exp
    scene:send2client(self, msg)
end

-- 增加暗器经验
-- @param add_exp 增加的经验值
-- @param award_exp 奖励经验值
function human:add_aq_exp(add_exp, award_exp)
    local container = self:get_equip_container()
    local anqi = container:get_item(define.HUMAN_EQUIP.HEQUIP_ANQI)
    if anqi then
        if anqi:get_equip_data():get_aq_xiulian() >= self:get_level() then
            return 0, 0
        end
        add_exp, award_exp = anqi:get_equip_data():add_exp(add_exp, award_exp)
        local msg = packet_def.GCItemInfo.new()
        msg.bagIndex = define.HUMAN_EQUIP.HEQUIP_ANQI
        msg.item = anqi:copy_raw_data()
        msg.bag_type = define.BAG_TYPE.equip
        self:get_scene():send2client(self, msg)
        local aq_xiulian = anqi:get_equip_data():get_aq_xiulian()
        if add_exp == 0 and (aq_xiulian ~= define.HUMAN_MAX_LEVEL - 1) then
            self:notify_tips("#{FBSJ_081209_04}")
        end
        return add_exp, award_exp
    end
    return 0, 0
end

-- 增加自身经验
-- @param add_exp 增加的经验值
-- @param award_exp 奖励经验值
function human:add_my_exp(add_exp, award_exp)
    -- CYS-ROUND2 23/09 Report only EXP actually credited; never add the notification twice.
    add_exp=math.max(0,math.floor(add_exp or 0))
    award_exp=math.max(0,math.floor(award_exp or 0))
    local before=self:get_exp()
    local exp = before + add_exp + award_exp
    local player_exp_level = configenginer:get_config("player_exp_level")
    local level = self:get_level()
    local level_exp = player_exp_level[level]
    if exp >= level_exp and level < 10 then
        exp = exp - level_exp
        level = level + 1
        self:set_level(level)
        self:on_level_up(level)
        local config_info = configenginer:get_config("config_info")
        local lever_up_flag = tonumber(config_info.LeverUpflag.LeverUpflag) or 1
        if lever_up_flag == 1 then
            local hp_max = self:get_attrib("hp_max")
            local mp_max = self:get_attrib("mp_max")
            self:set_hp(hp_max)
            self:set_mp(mp_max)
        end

        local msg = packet_def.GCLevelUpResult.new()
        msg.remind_exp = exp
        msg.result = 0
        self:get_scene():send2client(self, msg)

        msg = packet_def.GCLevelUp.new()
        msg.m_objID = self:get_obj_id()
        msg.level = level
        self:get_scene():broadcast(self, msg, true)
        -- self:on_level_up(level)
    end
    level_exp = player_exp_level[level]
    local cap=math.floor(3.5 * level_exp)
    -- Keep already earned overflow after changing the policy; block new gains
    -- until EXP is spent below the cap. Automatic level-up has already spent EXP.
    local limit=math.max(cap, math.min(before,exp-add_exp-award_exp))
    local lost=math.max(0,exp-limit)
    if exp > limit then
        exp = limit
        self:notify_tips("EXP tích lũy đã đạt giới hạn 3,5 lần. Hãy lên cấp hoặc dùng EXP để nhận thêm.")
    end
    self:update_exp(exp)
    self:send_refresh_attrib()
    local accepted=math.max(0,add_exp+award_exp-lost)
    local normal=math.min(add_exp,accepted)
    return normal,accepted-normal
end

-- 获取升级剩余点数增加量
-- @param level 等级
function human:get_level_up_point_remain_add(level)
    for i = #define.LEVEL_POINT_REMAIN, 1, -1 do
        local p = define.LEVEL_POINT_REMAIN[i]
        if level >= p.level then
            return p.add_point
        end
    end
    return 0
end

-- 升级处理
-- @param level 等级
function human:on_level_up(level)
    local attr_level_up = configenginer:get_config("attr_level_up_table")
    local menpai = self:get_attrib("menpai")
    local attr_up = attr_level_up[level]
	--attr_up[str][恶人谷] = value
    local chn = define.ENUM_MENPAI_CHN[menpai]
    for attr, v in pairs(attr_up) do
        if v[chn] then
            local v_chn = v[chn]
            local key = attr
            local add = 0
            if type(v_chn) == "table" then
                add = v_chn[1]
            else
                add = v_chn
            end
            local e = self.db:get_lv1_attrib()[key] or 0
            local new = e + add
            self.db:set_lv1_attrib({ [key] = new })
        end
    end
    do
        local key = "point_remain"
        local add_point_remain = self:get_level_up_point_remain_add(level)
        local e = self.db:get_lv1_attrib()[key] or 0
        local new = e + add_point_remain
        self.db:set_lv1_attrib({ [key] = new })
    end
    self:update_vigor_stamina_max()
    self.db:mark_all_attr_dirty()
    local config_info = configenginer:get_config("config_info")
    local lever_up_flag = tonumber(config_info.LeverUpflag.LeverUpflag) or 1
    if lever_up_flag == 1 then
        self:set_hp(self:get_max_hp())
        self:set_mp(self:get_max_mp())
        self:set_rage(self:get_max_rage())
    end
    self:get_scene():get_script_engienr():call(define.SCENE_SCRIPT_ID, "OnSceneHumanLevelUp", self:get_obj_id(), level)
    local guild_id = self:get_guild_id()
    if guild_id ~= define.INVAILD_ID then
        skynet.send(".Guildmanager", "lua", "on_guild_human_level_up", guild_id, self:get_guid(), level)
    end
end

-- 更新活力和体力最大值
function human:update_vigor_stamina_max()
    local value = self:get_level() * 6
    value = value > 600 and 600 or value
    self.db:set_db_attrib({ vigor_max = value, stamina_max = value })
end

-- 更新任务数据值
-- @param md 任务数据索引
function human:update_md_value(md)
	local msg = packet_def.GCMissionModify.new()
	msg.m_nFlag = 1
	msg.mission_id = (define.MD_SCRIPT_TO_CLIENT and define.MD_SCRIPT_TO_CLIENT[md]) or md
	msg.mission_index = self.mission_data.mission_datas[md + 1] or 0
	self:get_scene():send2client(self, msg)
end

-- 登录处理
function human:on_login()
	self:on_line_check_item_valid_timer()
    local logout_time = self:get_logout_time()
    if logout_time == 0 then
        self:on_fist_login()
    end
    self:get_scene():get_script_engienr():call(define.SCENE_SCRIPT_ID, "OnScenePlayerLogin", self:get_obj_id(), os.time())
	for md,val in pairs(self.mission_data.mission_datas) do
		if md > 0 and val ~= 0 then
			local msg = packet_def.GCMissionModify.new()
			msg.m_nFlag = 1
			local script_id = md - 1
			msg.mission_id = (define.MD_SCRIPT_TO_CLIENT and define.MD_SCRIPT_TO_CLIENT[script_id]) or script_id
			msg.mission_index = val
			self:get_scene():send2client(self, msg)
		end
	end
    -- 补发武境高位mission(含零值) + 刷新756/320
    self:sync_dfeng_learn_md_to_client()
    self:refresh_dfeng_attrib()
    self:schedule_dfeng_learn_resync("on_login")
end

-- 首次登录处理
function human:on_fist_login()
    self:get_scene():get_script_engienr():call(define.SCENE_SCRIPT_ID, "OnScenePlayerFirstLogin", self:get_obj_id(), os.time())
end

-- 获取登出时间
function human:get_logout_time()
    return self.db:get_attrib("logout_time") or 0
end

-- 设置登出时间
-- @param logout_time 登出时间
function human:set_logout_time(logout_time)
    self.db:set_db_attrib({ logout_time = logout_time})
end

-- 获取宠物
function human:get_pet()
    return self.pet
end

-- 设置助手ID
function human:set_assistant_id()

end

-- 获取助手ID
function human:get_assistant_id()

end

-- 创建新对象数据包
function human:create_new_obj_packet()
    if self:is_moving() then
        local msg = packet_def.GCNewPlayer_Move.new()
        msg.m_objID = self:get_obj_id()
        msg.guid = self:get_guid()
        msg.m_posWorld = self:get_world_pos()
        msg.dir = self:get_dir()
        msg.speed = self:get_speed()
        msg.handle = self.move.handle
        msg.path = self.move.targetPos
        msg.m_wEquipVer = 67336
        return msg
    else
        local msg = packet_def.GCNewPlayer.new()
        msg.m_fDir = self:get_dir()
        msg.m_fMoveSpeed = self:get_speed()
        msg.m_objID = self:get_obj_id()
        msg.m_posWorld = self:get_world_pos()
        msg.m_wEquipVer = 67336
        msg.unknow_1 = 280108829
        msg.unknow_2 = 0
        return msg
    end
end

-- 获取玩家名称
function human:get_name()
    return self.db:get_attrib("name")
end

-- 获取玩家GUID
function human:get_guid()
    return self.db:get_attrib("guid")
end

-- 设置世界坐标
-- @param world_pos 世界坐标
function human:set_world_pos(world_pos)
    self.db:set_db_attrib({ world_pos = world_pos })
    self:get_scene():char_world_pos_changed(self)
end

-- 设置切换场景信息
-- @param sceneid 场景ID
-- @param world_pos 世界坐标
function human:set_switch_scene_info(sceneid,world_pos)
    self.db:set_db_attrib({ sceneid = sceneid, world_pos = world_pos })
end


-- 获取世界坐标
function human:get_world_pos()
    return self.db:get_attrib("world_pos")
end

-- 获取场景ID
function human:get_scene_id()
    return self.db:get_attrib("sceneid")
end

-- 设置属性
-- @param ... 属性参数
function human:set_attrib(...)
    self.db:set_attrib(...)
end

-- 设置冷却时间
-- @param id 技能/状态ID
-- @param cool_down_time 冷却时间
function human:set_cool_down(id, cool_down_time)
	local index = tonumber(id)
	if index < define.OTHER_SKILL_OR_STATUS_COOLDOWN then
		local msg = packet_def.GCCooldownUpdate.new()
		msg.m_nNumCooldown = 1
		msg.m_aCooldowns = {}
		msg.m_aCooldowns[1] = { m_nID = index, m_nCooldown = cool_down_time, m_nCooldownElapsed = 0}
		self:get_scene():send2client(self, msg)
	end
    character.set_cool_down(self, id, cool_down_time)
end

-- 更新冷却时间
-- @param id 技能/状态ID
-- @param value 时间增量
function human:update_cool_down_time(id, value)
    local cool_down_time = self:get_cool_down(id) - value
	if cool_down_time < 0 then
		cool_down_time = 0
	end
	local index = tonumber(id)
	if index < define.OTHER_SKILL_OR_STATUS_COOLDOWN then
		local msg = packet_def.GCCooldownUpdate.new()
		msg.m_nNumCooldown = 1
		msg.m_aCooldowns = {}
		msg.m_aCooldowns[1] = { m_nID = index, m_nCooldown = cool_down_time, m_nCooldownElapsed = 0}
		self:get_scene():send2client(self, msg)
	end
    character.set_cool_down(self, id, cool_down_time)
end

-- 获取技能连招操作
function human:get_skill_combo_operation()
    return self.skill_comb_operation
end

-- 发送默认技能连招操作
function human:send_default_skill_combo_operation()
    local combo_list = {764, 764, 787, 0, 1}
    local cur_comb = 0
    local tempnum = 0
    local skill_id = 764
    local msg = packet_def.GCComboSkillOperation.new()
    msg.cur_comb = cur_comb
    msg.skill_id = skill_id
    msg.tempnum = tempnum
    msg.combo_list = combo_list
    self:get_scene():send2client(self, msg)
end

-- 添加技能连招操作
-- @param skill_id 技能ID
function human:add_skill_combo_operation(skill_id)
    if self.skill_comb_operation == nil then
        self.skill_comb_operation = { skill_id = skill_id}
        self.skill_comb_operation.cur_comb = 1
        local msg = packet_def.GCComboSkillOperation.new()
        msg.cur_comb = 1
        msg.skill_id = skill_id
        msg.tempnum = 1
        self:get_scene():send2client(self, msg)
    else
        local msg = packet_def.GCComboSkillOperation.new()
        msg.cur_comb = 4
        msg.skill_id = skill_id
        msg.tempnum = 0
        self:get_scene():send2client(self, msg)
        self.skill_comb_operation = nil
    end
end

-- 连招技能冷却
-- @param skill_id 技能ID
function human:combo_skill_cool_downd(skill_id)
    if self.skill_comb_operation and self.skill_comb_operation.cur_comb == 1 then
        local msg = packet_def.GCComboSkillOperation.new()
        msg.cur_comb = 2
        msg.skill_id = skill_id
        msg.tempnum = -1
        self:get_scene():send2client(self, msg)
        self.skill_comb_operation = nil
    end
end

-- 获取命中值
function human:get_hit()
    return self.db:get_attrib("attrib_hit")
end

-- 获取闪避值
function human:get_miss()
    return self.db:get_attrib("attrib_miss")
end

-- 获取速度
function human:get_speed()
    return self.db:get_attrib("speed")
end

-- 获取基础属性
function human:get_base_attribs()
    return self.db:get_base_attribs()
end

-- 获取详细属性
function human:get_detail_attribs()
    return self.db:get_detail_attribs()
end

-- 获取属性
-- @param attr 属性名
function human:get_attrib(attr)
    return self.db:get_attrib(attr)
end

-- 受到伤害处理
-- @param damages 伤害数据
-- @param caster_obj_id 施法者对象ID
-- @param is_critical 是否暴击
-- @param skill_id 技能ID
-- @param imp 效果
function human:on_damages(damages, caster_obj_id, is_critical, skill_id, imp)
	local effect_value,feature_rate = self:get_dw_jinjie_effect_details(13)
	if effect_value > 0 then
		if math.random(100) <= effect_value / feature_rate then
			damages.flag_immu = true
			self:features_effect_notify_client(13)
			return
		end
	end
	
    local scene = self:get_scene()
    local sender = scene:get_obj_by_id(caster_obj_id)
    if sender and sender:is_character_obj() then
        sender:on_damage_target(self, damages, skill_id, imp)
    end
    self:impact_on_damages(damages, caster_obj_id, is_critical, skill_id, imp)
    local r, err = pcall(self.talent_on_damages, self, damages, caster_obj_id, is_critical, skill_id, imp)
    if not r then
        skynet.loge("talent_on_damages error =", err)
    end
    self:menpai_on_damage(damages.hp_damage)
	if damages.flag_immu then
		self:show_skill_missed(self:get_obj_id(),caster_obj_id,skill_id,self:get_logic_count(),define.MISS_FLAG.FLAG_IMMU)
		return
	elseif damages.imm_dmg_rate then
		if damages.imm_dmg_rate >= 100 then
			self:show_skill_missed(self:get_obj_id(),caster_obj_id,skill_id,self:get_logic_count(),define.MISS_FLAG.FLAG_IMMU)
			return
		end
	end
	
    character.on_damages(self, damages, caster_obj_id, is_critical, skill_id, imp)
end

-- 门派受到伤害处理
-- @param damage 伤害值
function human:menpai_on_damage(damage)
    damage = math.abs(damage)
    menpai_logic:on_damage(self, damage)
end


-- 对目标造成伤害处理
-- @param target 目标对象
-- @param damages 伤害数据
-- @param skill_id 技能ID
-- @param imp 效果
function human:on_damage_target(target, damages, skill_id, imp)
    if target:get_obj_type() == "human" then
        local want_change_pk_mode = self.db:get_db_attrib("want_change_pk_mode")
        if want_change_pk_mode then
            self.db:set_db_attrib({ change_pk_mode_delay = define.PK_MODE_CHANGE_DELAY} )
        end
    end
    self:menpai_on_damage_target(damages.hp_damage)
    local r, err = pcall(self.talent_on_damage_target, self, target, damages, skill_id, imp)
    if not r then
        skynet.loge("talent_on_damage_target skill_id =", skill_id,"error = ",err)
    end
    character.on_damage_target(self, target, damages, skill_id, imp)
end

-- 门派对目标造成伤害处理
-- @param damage 伤害值
function human:menpai_on_damage_target(damage)
    damage = math.abs(damage)
    menpai_logic:on_damage_target(self, damage)
end

-- 命中目标处理
-- @param reciver 接收者
-- @param skill 技能
function human:on_hit_target(reciver, skill)
    --skynet.error("[DEBUG:on_hit_target] sender=", self:get_obj_id(), " reciver=", reciver and reciver:get_obj_id() or "nil", " skill=", skill)
    if reciver:get_obj_type() == "human" then
        local want_change_pk_mode = self.db:get_db_attrib("want_change_pk_mode")
        if want_change_pk_mode then
            self.db:set_db_attrib({ change_pk_mode_delay = define.PK_MODE_CHANGE_DELAY})
        end
    end
    local r, err = pcall(self.talent_on_hit_target, self, reciver, skill)
    if not r then
        skynet.loge("talent_on_hit_target error =", err)
    end
    character.on_hit_target(self, reciver, skill)
    menpai_logic:on_hit_target(self, skill)
    local weapon_broken = self:on_weapon_abrasion()
    local wh_no_life = self:on_wh_abrasion()
    if weapon_broken or wh_no_life then
        self:item_flush()
    end
end

-- 装备耐久度修改
-- @param modify 修改值
function human:equip_dur_modify(modify)
    self:on_weapon_abrasion(modify)
    self:on_armor_abrasion(modify)
end

-- 武器磨损处理
-- @param point 磨损点数
function human:on_weapon_abrasion(point)
    local refresh_attrib = false
    local conifg_info = configenginer:get_config("config_info")
    local equip_container = self:get_equip_container()
    local weapon = equip_container:get_item(define.HUMAN_EQUIP.HEQUIP_WEAPON)
    if weapon then
        local damage_point = weapon:get_equip_data():get_damage_point()
        damage_point = damage_point + 1
        local dur = weapon:get_equip_data():get_dur()
        if (damage_point >= conifg_info.Global.EquipmentDamagePoint and dur > 0) or point then
            damage_point = 0
            point = point or 1
            dur = dur - point
            dur = dur < 0 and 0 or dur
            weapon:get_equip_data():set_dur(dur)
            local raw_data = weapon:copy_raw_data()
            local msg = packet_def.GCDetailEquipList.new()
            msg.m_objID = self:get_obj_id()
            msg.m_mode = 1
            msg.itemList = {
                [define.HUMAN_EQUIP.HEQUIP_WEAPON] = raw_data
            }
            self:get_scene():send2client(self, msg)
            if dur == 0 then
                refresh_attrib = true
            end
        end
        weapon:get_equip_data():set_damage_point(damage_point)
    end
    return refresh_attrib
end

-- 武魂磨损处理
function human:on_wh_abrasion()
    local refresh_attrib = false
    local conifg_info = configenginer:get_config("config_info")
    local equip_container = self:get_equip_container()
    local wh = equip_container:get_item(define.HUMAN_EQUIP.HEQUIP_WUHUN)
    if wh then
        local damage_point = wh:get_equip_data():get_damage_point()
        damage_point = damage_point + 1
        local life = wh:get_equip_data():get_wh_life()
        if damage_point >= conifg_info.Global.EquipmentDamagePoint and life > 0 then
            damage_point = 0
            life = life - 1
            life = life < 0 and 0 or life
            wh:get_equip_data():set_wh_life(life)
            local raw_data = wh:copy_raw_data()
            local msg = packet_def.GCDetailEquipList.new()
            msg.m_objID = self:get_obj_id()
            msg.m_mode = 1
            msg.itemList = {
                [define.HUMAN_EQUIP.HEQUIP_WUHUN] = raw_data
            }
            self:get_scene():send2client(self, msg)
            if life == 0 then
                refresh_attrib = true
            end
        end
        wh:get_equip_data():set_damage_point(damage_point)
    end
    return refresh_attrib
end

-- 被击中处理
function human:on_be_hit(sender, skill)
    character.on_be_hit(self, sender, skill)
    local armor_broken = self:on_armor_abrasion()
    if armor_broken then
        self:item_flush()
    end
end

-- 护甲磨损处理
-- @param point 磨损点数
function human:on_armor_abrasion(point)
    local modifed = false
    local refresh_attrib = false
    local msg = packet_def.GCDetailEquipList.new()
    msg.m_objID = self:get_obj_id()
    msg.m_mode = 1
    local conifg_info = configenginer:get_config("config_info")
    local equip_container = self:get_equip_container()
    for i = define.HUMAN_EQUIP.HEQUIP_CAP, define.HUMAN_EQUIP.HEQUIP_SHOULDER do
        if not define.NOT_ABRASION_EQUIP[i] then
            local equip = equip_container:get_item(i)
            if equip then
                local damage_point = equip:get_equip_data():get_damage_point()
                damage_point = damage_point + 1
                local dur = equip:get_equip_data():get_dur()
                if (damage_point >= conifg_info.Global.EquipmentDamagePoint and dur > 0) or point then
                    damage_point = 0
                    point = point or 1
                    dur = dur - point
                    dur = dur < 0 and 0 or dur
                    equip:get_equip_data():set_dur(dur)
                    modifed = true
                    local raw_data = equip:copy_raw_data()
                    msg.itemList = {
                        [i] = raw_data
                    }
                    if dur == 0 then
                        refresh_attrib = true
                    end
                end
                equip:get_equip_data():set_damage_point(damage_point)
            end
        end
    end
    if modifed then
        self:get_scene():send2client(self, msg)
    end
    return refresh_attrib
end

-- 被技能攻击处理
-- @param sender 施法者
-- @param skill_id 技能ID
-- @param behaviortype 行为类型
function human:on_be_skill(sender, skill_id, behaviortype)
    character.on_be_skill(self, sender, skill_id, behaviortype)
    if behaviortype ~= define.ENUM_BEHAVIOR_TYPE.BEHAVIOR_TYPE_HOSTILITY then
        return
    end
    self:on_be_hostility_skill(sender, skill_id, behaviortype)
end

-- 被敌对技能攻击处理
-- @param sender 施法者
-- @param skill_id 技能ID
-- @param behaviortype 行为类型
function human:on_be_hostility_skill(sender, skill_id, behaviortype)
    if sender:get_obj_type() ~= "human" and sender:get_obj_type() ~= "pet" then
        return
    end
    if sender:get_obj_type() == "pet" then
        sender = sender:get_owner()
    end
    if sender == self then
        return
    end
    local attack_guid = sender:get_guid()
    local my_guid = self:get_guid()
    local sender_pk_declaration_list = sender:get_pk_declaration_list()
    if sender_pk_declaration_list:is_exist(my_guid) then
        sender_pk_declaration_list:add(my_guid)
    end
    if self:is_enemy(sender) then
        return
    end
    self.db:set_not_gen_attrib({ cur_attacker = attack_guid})
    self.attackers_list:add(attack_guid)
    self:notify_tips("遭受到不明攻击，您现在进入自卫状态！")
end

-- 获取坐骑最大速度加成
function human:get_riders_max_speed_up()
    local exterior_ride = configenginer:get_config("exterior_ride")
    local rides = self.exterior.rides
    local speed_up = 0
    for _, ride in ipairs(rides) do
        local id = ride.id
        local conf = exterior_ride[id]
        if conf then
            if speed_up < conf.speed_up then
                speed_up = conf.speed_up
            end
        end
    end
    return speed_up
end

-- 修改设置
-- @param key 键
-- @param value 值
function human:modify_setting(key, value)
    key = tostring(key)
    self.setting[key] = { data = value, type = 1}
end

-- 获取设置
function human:get_setting()
    return self.setting
end

-- 根据类型获取设置
-- @param type 类型
function human:get_setting_by_type(type)
    local st = tostring(type)
    return self.setting[st]
end

-- 检查设置标志是否为真
-- @param st 设置类型
-- @param shift 位移
function human:setting_flag_is_true(st, shift)
    st = st + 1
    local setting = self:get_setting_by_type(st)
    setting = setting or { data = 0 }
    return (setting.data & (1 << shift) == (1 << shift))
end

-- 获取空设置
-- @param start 起始索引
-- @param stop 结束索引
-- @param ignore 忽略值
function human:get_empty_setting(start, stop, ignore)
    for i = start, stop do
        i = tostring(i)
        if not self.setting[i] then
            return i
        end
        if ignore and self.setting[i].data == ignore.data  and self.setting[i].type == ignore.type then
            return i
        end
    end
end

-- 发送操作结果消息
-- @param result 结果
function human:send_operate_result_msg(result)
    local msg = packet_def.GCOperateResult.new()
    msg.result = result
    self:get_scene():send2client(self, msg)
end

-- 发送提示消息
-- @param msg 消息内容
function human:notify_tips(msg)
    -- 2026-09-10: msg khong phai chuoi (so/nil) lam iostream:write nem loi -> ep ve chuoi va ghi log 1 dong
    if type(msg) ~= "string" then
        skynet.logw("[notify_tips] msg khong phai string:", tostring(msg), debug.traceback("", 2))
        msg = tostring(msg or "")
    end
    local m_nCmdID = 5
    local ret = packet_def.GCScriptCommand.new()
    ret.m_nCmdID = m_nCmdID
    ret.event = {}
    ret.event.str = gbk.fromutf8(msg)
    ret.event.len = string.len(ret.event.str)
    self.scene:send2client(self, ret)
end

-- 使用鉴定卷轴
-- @param ident_bag_index 鉴定卷轴背包索引
-- @param equip_bag_index 装备背包索引
function human:use_ident_scroll(ident_bag_index, equip_bag_index)
    return require('cys_identify').use(self, ident_bag_index, equip_bag_index)
end

-- 使用元宝票
-- @param bag_index 背包索引
function human:use_yuanbao_piao(bag_index)
    local bag_container = self:get_prop_bag_container()
    local item = bag_container:get_item(bag_index)
    assert(item, bag_index)
	if item:get_index() ~= define.YUANBAO_PIAO then
		self:notify_tips("请使用元宝票。")
		return define.USEITEM_RESULT.USEITEM_SUCCESS
	end
	local count = item:get_param(0,"uint")
	if count < 1 or count > 50000 then
		self:notify_tips("非法元宝票。")
		return define.USEITEM_RESULT.USEITEM_SUCCESS
	end
	if item:get_item_record_data_forindex("count") ~= count then
		self:notify_tips("非法元宝票。。")
		return define.USEITEM_RESULT.USEITEM_SUCCESS
	end
	local change_guid = item:get_item_record_data_forindex("change_guid")
	if not change_guid then
		self:notify_tips("非法元宝票。。。")
		return define.USEITEM_RESULT.USEITEM_SUCCESS
	end
	local change_name = item:get_item_record_data_forindex("change_name")
	local change_time = item:get_item_record_data_forindex("change_time")
	bag_container:set_item(bag_index, nil)
    local msg = packet_def.GCItemInfo.new()
    msg.bagIndex = bag_index
    msg.unknow_1 = 1
    msg.item = Item_cls.new():copy_raw_data()
    self:get_scene():send2client(self, msg)
    item = bag_container:get_item(bag_index)
	if item then
		self:notify_tips("元宝票扣除失败。")
		return define.USEITEM_RESULT.USEITEM_SUCCESS
	end
	local use_name = self:get_name()
	local use_guid = self:get_guid()
	local use_time = os.date("%y-%m-%d %H:%M:%S")
	skynet.send(".logdb", "lua", "update", {
		collection = "log_yuanbaopiao_value",
		selector = {guid = change_guid},
		update = {["$inc"] = {use_yuanbao = count}},
		upsert = true,
		multi = false,
	})
	self:add_yuanbao(count, "使用元宝票")
	local doc = { 
		logname = "使用元宝票",
		change_name = change_name,
		change_guid = change_guid,
		change_time = change_time,
		use_name = use_name,
		use_guid = use_guid,
		use_time = use_time,
		yuanbao = count,
	}
	skynet.send(".logdb", "lua", "insert", { collection = "log_yuanbaopiao", doc = doc})
	
	self:notify_tips("你获得"..tostring(count).."元宝。")
    return define.USEITEM_RESULT.USEITEM_SUCCESS
end

-- 分割物品
-- @param split 分割参数
function human:split_item(split)
    local msg = packet_def.GCSplitItemResult.new()
    msg.container = split.container
    if split.container == packet_def.CGSplitItem.Container.BAG_CON then
        local container = self:get_prop_bag_container()
        local item = container:get_item(split.position)
        if item == nil or item:is_empty() then
            msg.item = Item_cls.new():copy_raw_data()
            msg.result = msg.RESULT.RESULT_FALSE
            self.scene:send2client(self, msg)
            return
        end
        local empty_index = container:get_empty_item_index(item:get_place_bag())
        if empty_index == define.INVAILD_ID then
            msg.item = Item_cls.new():copy_raw_data()
            msg.result = msg.RESULT.RESULT_FALSE
            self.scene:send2client(self, msg)
            return
        end
        local ret = human_item_logic:split_item(container, split.position, split.num, container, empty_index)
        if ret then
            msg.item = container:get_item(empty_index):copy_raw_data()
            msg.result = msg.RESULT.RESULT_SUCCEED
            msg.is_null = 0
            msg.con_index = empty_index
            self.scene:send2client(self, msg)

            msg = packet_def.GCItemInfo.new()
            msg.bagIndex = split.position
            msg.item = item:copy_raw_data()
            self.scene:send2client(self, msg)
        else
            msg.item = Item_cls.new():copy_raw_data()
            msg.result = msg.RESULT.RESULT_FALSE
            self.scene:send2client(self, msg)
        end
    else

    end
end

-- 是否新手复活
function human:is_new_player_relive()
    return false
end

-- 设置复活脚本ID
-- @param script_id 脚本ID
function human:set_on_relive_script_id(script_id)
    self.on_relive_script_id = script_id
end

-- 切换场景
-- @param to 目标场景ID
-- @param world_pos 世界坐标
function human:change_scene(to, world_pos)
    self:get_scene():notify_change_scene(self:get_obj_id(), to, world_pos.x, world_pos.y)
end

-- 验证物品
function human:verify_item()
    local params = self:get_targeting_and_depleting_params()
    local bag_index = params:get_bag_index_of_deplted_item()
    local item = self:get_prop_bag_container():get_item(bag_index)
    local item_index = params:get_item_index_of_deplted_item()
    if item == nil or item:get_index() ~= item_index then
        if human_item_logic:calc_bag_item_count(self, item_index) > 0 then
            local exist_bag_index = human_item_logic:get_item_pos_by_type(self, item_index)
            if exist_bag_index ~= define.INVAILD_ID then
                params:set_bag_index_of_deplted_item(exist_bag_index)
                item = self:get_prop_bag_container():get_item(exist_bag_index)
            end
        end
    end
    if item then
        if item:get_index() == params:get_item_index_of_deplted_item() then
            local this_item_config = item:get_base_config()
            if this_item_config.script_id == params:get_activated_script() then
                if this_item_config.skill_id == params:get_activated_skill() then
                    return 1
                end
            end
        end
    end
    self:send_operate_result_msg(define.OPERATE_RESULT.OR_CAN_NOT_FIND_SPECIFIC_ITEM)
end

-- 消耗使用的物品
-- @param selfId 玩家ID
function human:depleting_used_item(selfId)
    return self:skill_deplte_item(selfId)
end

-- 技能消耗物品
function human:skill_deplte_item()
    local skill_info = self:get_skill_info()
    local params = self:get_targeting_and_depleting_params()
    local item_guid = params:get_deplted_item_guid()
    local item_index = params:get_item_index_of_deplted_item()
    local bag_index = params:get_bag_index_of_deplted_item()
    if bag_index == define.INVAILD_ID then
        if item_index ~= define.INVAILD_ID then
            bag_index = human_item_logic:get_item_pos_by_type(item_index)
        end
    end
    if bag_index == define.INVAILD_ID then
        return false
    end
    local item = self:get_prop_bag_container():get_item(bag_index)
    if item == nil then
        return false
    end
    if item:get_index() ~= item_index then
        return false
    end
    if not item:is_ruler(define.ITEM_RULER_LIST.IRL_CANUSE) then
        return false
    end
    if item:is_cos_self() then
        local lay_count = item:get_lay_count()
        if lay_count < 1 then
            return false
        end
        local logparam = {}
        local ret =  human_item_logic:dec_item_lay_count(logparam, self, bag_index, 1)
		return ret
    end
    return true
end

-- 设置临时PK模式
-- @param mode PK模式
function human:set_temp_pk_mode(mode)
    self.db:set_attrib({ pk_mode = mode})
end

-- 设置PVP规则
-- @param rule PVP规则
function human:set_pvp_rule(rule)
    self.db:set_not_gen_attrib({ pk_min_level = rule.pk_min_level, pvp_rule = rule.pvp_rule })
end

-- 设置彻地符数据
-- @param index 索引
-- @param sceneid 场景ID
-- @param position 位置
function human:set_chedifulu_data(index, sceneid, position)
    self.chedifulu_data = self.chedifulu_data or {}
    index = tostring(index)
    self.chedifulu_data[index] = { sceneid = sceneid, x = math.ceil(position.x), y = math.ceil(position.y) }
    self:send_chedifulu_data(index)
end

-- 获取彻地符数据
-- @param index 索引
function human:get_chedifulu_data(index)
    self.chedifulu_data = self.chedifulu_data or {}
    index = tostring(index)
    return self.chedifulu_data[index]
end

-- 发送彻地符数据
-- @param index 索引
function human:send_chedifulu_data(index)
    self.chedifulu_data = self.chedifulu_data or {}
    local msg = packet_def.GCCheDiFuLuData.new()
    msg.list = {}
    if index then
        local data = self.chedifulu_data[index]
        if data then
            local l = {}
            l.index = tonumber(index)
            l.sceneid = data.sceneid
            l.x = data.x
            l.y = data.y
            table.insert(msg.list, l)
        end
    else
        for i = 1, define.CHEDIFULU_DATA_SIZE do
            local data = self.chedifulu_data[tostring(i - 1)]
            if data then
                local l = {}
                l.index = i - 1
                l.sceneid = data.sceneid
                l.x = data.x
                l.y = data.y
                table.insert(msg.list, l)
            end
        end
    end
    msg.size = #msg.list
    self:get_scene():send2client(self, msg)
end

-- 发送人民币聊天表情信息
function human:send_rmb_chat_face_info()
    local msg = packet_def.GCRMBChatFaceInfo.new()
    msg.id = self.rmb_chat_face_info.id
    msg.dates = self.rmb_chat_face_info.dates
    self:get_scene():send2client(self, msg)
end

-- 发送人民币聊天动作信息
function human:send_rmb_chat_action_info()
    local msg = packet_def.GCRMBChatActionInfo.new()
    msg.list_1 = { 0, 0, 0, 0 }
    msg.list_2 = { 0, 0, 0, 0 }
    msg.unknow_1 = 0
    msg.unknow_2 = 0
    msg.unknow_3 = 0
    self:get_scene():send2client(self, msg)
end

-- 发送任务列表
function human:send_mission_list()
    local msg = packet_def.GCMissionList.new()
    msg.m_objID = self:get_obj_id()
    msg.m_uMissionListFlags = 0
    for i = 1, define.MAX_CHAR_MISSION_NUM do
        if self.mission_data.char_missions[i] then 
            msg.m_uMissionListFlags = msg.m_uMissionListFlags | 1 << (i - 1)
        end
    end
    msg.char_missions = self.mission_data.char_missions
    msg.mission_have_done_flags = self.mission_data.mission_have_done_flags
    msg.mission_datas = {}
    for i = 1, 200 do
        local index = define.MD_2_CLIENT[i]
        if index then
            msg.mission_datas[i] = self:get_mission_data_by_script_id(index)
        else
            msg.mission_datas[i] = 0
        end
    end
    self:get_scene():send2client(self, msg)
    -- CYS: the fixed 200-slot list does not include combat MD602/603.
    -- Resend authoritative totals on login and every scene list refresh.
    self:set_mission_data_by_script_id(602,self.db:get_chuanci())
    self:set_mission_data_by_script_id(603,self.db:get_fangchuan())
    require('cys_shending').sync(self)
    -- GCMissionList只含前200条mission，武境高位mission(1299-1314)不在列表中
    -- 客户端收到后可能重建mission缓存导致高位mission清零，需立即补发
    self:sync_dfeng_learn_md_to_client()
end

-- 发送设置
function human:send_setting()
    local msg = packet_def.GCRetSetting.new()
    local setting = self:get_setting()
    for i = 1, 0x60 do
        msg.setting[i] = setting[tostring(i)]
    end
    self:get_scene():send2client(self, msg)
end

-- 获取称号是否隐藏
function human:get_title_is_hide()
    local type = define.SETTING_TYPE.SETTING_TYPE_SHOW_OR_HIDE_TITLE
    local setting = self.setting[tostring(type + 1)]
    return setting and setting.data == 1
end

-- 设置彻地符数据选择索引
-- @param index 索引
function human:set_chedifulu_data_select_index(index)
    self.chedifulu_data = self.chedifulu_data or {}
    self.chedifulu_data.select_index = tostring(index)
end

-- 获取彻地符数据选择索引
function human:get_chedifulu_data_select_index()
    self.chedifulu_data = self.chedifulu_data or {}
    return self.chedifulu_data.select_index
end

-- 更新彻地符使用次数
-- @param value 变化值
function human:update_chedifulu_use_times(value)
    self.chedifulu_data = self.chedifulu_data or {}
    local use_times = self.chedifulu_data.use_times or 20
    use_times = use_times + value
    use_times = math.floor(use_times)
    self.chedifulu_data.use_times = use_times
end

-- 获取彻地符使用次数
function human:get_chedifulu_use_times()
    self.chedifulu_data = self.chedifulu_data or {}
    local use_times = self.chedifulu_data.use_times or 20
    return use_times
end

-- 发送已售出物品列表
function human:send_sold_out_list()
    local container = self:get_sold_out_container()
    local msg = packet_def.GCShopSoldList.new()
    msg.item_list = {}
    for i = 0, define.SOLD_OUT_SIZE - 1 do
        local item = container:get_item(i)
        if item then
            local ei = {}
            ei.price = item:get_base_config().base_price * 2 * item:get_lay_count()
            ei.item = item:get_stream()
            table.insert(msg.item_list, ei)
        end
    end
    msg.merchandise_num = #msg.item_list
    self:get_scene():send2client(self, msg)
end

-- 添加心法
-- @param xinfa_id 心法ID
function human:add_xinfa(xinfa_id)
    local xinfa = self:get_xinfa(xinfa_id)
    assert(xinfa == nil, xinfa_id)
    table.insert(self.xinfa_list,  {m_nXinFaID = xinfa_id, m_nXinFaLevel = 1})
    self:send_xinfa_list()
end

-- 发送心法列表
function human:send_xinfa_list()
    local xinfa_list = self:get_xinfa_list()
    local msg = packet_def.GCDetailXinFaList.new()
    msg.m_aXinFa = xinfa_list
    msg.m_objID = self:get_obj_id()
    msg.m_wNumXinFa = #xinfa_list
    msg.unknow = 26
    self.scene:send2client(self, msg)
end

-- 添加技能
-- @param skill 技能ID
function human:add_skill(skill)
    local have_skill = self:have_skill(skill)
    if not have_skill then
        table.insert(self.skill_list, skill)
    end
	-- self:send_skill_list()
end

-- 删除技能
-- @param id 技能ID
function human:del_skill(id)
    for i, skill in ipairs(self.skill_list) do
        if skill == id then
            table.remove(self.skill_list, i)
        end
    end
    self:send_skill_list()
end

-- 发送技能列表
function human:send_skill_list()
    local skill_list = self:get_total_skills_list()
    local msg = packet_def.GCDetailSkillList.new()
    msg.m_objID = self:get_obj_id()
    msg.m_aSkill = skill_list
    msg.m_wNumSkill = #skill_list
    self.scene:send2client(self, msg)
end

-- 增加金币
-- @param money 金币数量
-- @param reason 原因
-- @param extra 额外信息
function human:add_money(money, reason, extra)
    assert(money > 0)
    money = math.ceil(money)
    money = self:get_money() + money
    self:set_money(money, reason, extra)
end

-- 增加交子
-- @param money 交子数量
-- @param reason 原因
-- @param extra 额外信息
function human:add_jiaozi(money, reason, extra)
    assert(money > 0)
    money = math.ceil(money)
    local jiaozi = self:get_jiaozi() or 0
    money = jiaozi + money
    self:set_jiaozi(money, reason, extra)
end

-- 获取等级最大金币
function human:get_lv_max_money()
    local lv_max_money = configenginer:get_config("lv_max_money")
    local level = self:get_level()
    return lv_max_money[level]
end

-- 增加绑定元宝
-- @param value 元宝数量
-- @param reason 原因
-- @param extra 额外信息
function human:add_bind_yuanbao(value, reason, extra)
    assert(value > 0)
    value = math.ceil(value)
    value = self:get_bind_yuanbao() + value
    self:set_bind_yuanbao(value, reason, extra)
end

-- 获取绑定元宝数量
function human:get_bind_yuanbao()
    return self.db:get_db_attrib("bind_yuanbao")
end

-- 设置绑定元宝数量
-- @param bind_yuanbao 绑定元宝数量
-- @param reason 原因
-- @param extra 额外信息
-- @param not_record 是否不记录
function human:set_bind_yuanbao(bind_yuanbao, reason, extra,not_record)
    if bind_yuanbao < 0 then
        return false
    end
    local before = self:get_bind_yuanbao()
    bind_yuanbao = bind_yuanbao > define.INT32_MAX and define.INT32_MAX or bind_yuanbao
    self.db:set_db_attrib({ bind_yuanbao = bind_yuanbao})
    self:log_money_rec(reason, "绑定元宝", before, bind_yuanbao - before, extra)
	if not not_record and bind_yuanbao < before then
		local subvalue = before - bind_yuanbao
		local have = self:get_game_flag_key("cost_bind_yuanbao")
		self:set_game_flag_key("cost_bind_yuanbao",have + subvalue)
	end
end

-- 扣除绑定元宝
-- @param value 扣除数量
-- @param reason 原因
-- @param extra 额外信息
-- @param not_record 是否不记录
function human:cost_bind_yuanbao(value, reason, extra,not_record)
    assert(value >= 0)
    value = math.ceil(value)
	local have = self:get_bind_yuanbao()
    local sub_have = have - value
	if sub_have < 0 then
		sub_have = 0
	end
    self:set_bind_yuanbao(sub_have, reason, extra,not_record)
end

-- 是否为攻击者
-- @param other 其他对象
function human:is_attackers(other)
    return self.attackers_list:is_exist(other:get_guid())
end

-- 是否在PK声明列表中
-- @param other 其他对象
function human:is_in_pk_declaration_list(other)
    return self.pk_declaration_list:is_exist(other:get_guid())
end

-- 是否为野外战帮派
-- @param other 其他对象
function human:is_wild_war_guild(other)
    return self.wild_war_guilds:is_exist(other:get_guild_id())
end

-- 是否被反击击杀
-- @param killer 击杀者
function human:is_counter_killed(killer)
    if killer:get_obj_type() ~= "human" then
        return false
    end
    local pk_mode = killer:get_pk_mode()
    if pk_mode == define.PK_MODE.PERSONAL 
	or pk_mode == define.PK_MODE.TEAM 
	or pk_mode == define.PK_MODE.RAID 
	or pk_mode == define.PK_MODE.BANG_HUI then
        return false
    end
    if self:is_in_pk_declaration_list(killer) then
        return true
    end
    if self:is_wild_war_guild(killer) then
        return true
    end
    -- if killer:is_attackers(self) then
        -- return true
    -- end
    return false
end

-- 是否为敌对玩家
-- @param other 其他玩家
function human:is_enemy_human(other)
    -- HJ05 #100/#101: self is never hostile. Personal PK cannot override
    -- shared-party protection in normal or cross-server instances.
    if not other or self == other then return false end
    local scene = self.get_scene and self:get_scene()
    local kind = scene and scene:get_type()
    if kind == 1 or kind == 4 then
        local party = self:get_team_id()
        if type(party) == 'number' and party >= 0 and party == other:get_team_id() then return false end
    end
    -- CYS-PVP scene permission: safe zones and level protection apply to both sides.
    local rule = self.db:get_attrib('pvp_rule') or 0
    local minimum = math.max(self.db:get_attrib('pk_min_level') or 10000, other.db:get_attrib('pk_min_level') or 10000)
    if (rule & 14) == 0 or self:get_level() < minimum or other:get_level() < minimum then
        return false
    end
    -- [FIX] 允许和平模式下反击攻击过自己的人
    if self:is_attackers(other) then
        return true
    end
    if (rule & 8) ~= 0 and self:is_in_pk_declaration_list(other) then
        return true
    end
    -- [FIX] 允许和平模式下攻击对自己宣战的人
    if (rule & 8) ~= 0 and other:is_in_pk_declaration_list(self) then
        return true
    end
    if self:is_wild_war_guild(other) then
        return true
    end
    if other:is_wild_war_guild(self) then
        return true
    end
    if (rule & 4) ~= 0 and self:is_enemy_camp(other) then
        return true
    end
    if (rule & 2) == 0 then return false end
    local pk_mode = self.db:get_db_attrib("pk_mode")
    if pk_mode == define.PK_MODE.PERSONAL then
        return true
    elseif pk_mode == define.PK_MODE.TEAM then
        local team_id = other:get_team_id()
        local my_team_id = self:get_team_id()
        if my_team_id == define.INVAILD_ID then
            return true
        else
            return my_team_id ~= team_id
        end
    elseif pk_mode == define.PK_MODE.BANG_HUI then
        if other:get_server_id() ~= self:get_server_id() then
            return true
        end
        local guild_id = other:get_guild_id()
        guild_id = guild_id or define.INVAILD_ID
        local my_guild_id = self:get_guild_id()
        my_guild_id = my_guild_id or define.INVAILD_ID
        local confederate_id = other:get_confederate_id()
        confederate_id = confederate_id or define.INVAILD_ID
        local my_confederate_id = self:get_confederate_id()
        my_confederate_id = my_confederate_id or define.INVAILD_ID
        if my_guild_id == define.INVAILD_ID then
            return true
        end
        if my_guild_id ~= guild_id then
            if my_confederate_id == define.INVAILD_ID then
                return true
            end
            return my_confederate_id ~= confederate_id
        end
    elseif pk_mode == define.PK_MODE.RAID then
        local my_raid_id = self:get_raid_id()
        if my_raid_id == define.INVAILD_ID then
            return true
        else
            return my_raid_id ~= other:get_raid_id()
        end
    elseif pk_mode == define.PK_MODE.GOD_AND_EVIL then
        if other:get_pk_value() > 0 then
            return true
        end
    end
    return false
end

-- 是否为敌人
-- @param other 其他对象
function human:is_enemy(other)
    if self:get_obj_id() == other:get_obj_id() then
        return false
    end
	local obj_type = other:get_obj_type()
    if obj_type == "monster" then
        if other:get_reputation() == 0 then
            return false
        end
    elseif obj_type == "pet" then
        local owner = other:get_owner()
        if owner and owner:get_obj_id() == self:get_obj_id() then
            return false
        end
        if not owner then
            return false
        end
        assert(other ~= owner)
        -- return self:is_enemy(owner)
		return self:is_enemy_human(owner)
    elseif obj_type == "human" then
        return self:is_enemy_human(other)
    end
    return self:is_enemy_camp(other)
end

-- 是否为队友
-- @param other 其他对象
function human:is_teammate(other)
    if not other then
        return false
    end
    if other:get_obj_type() ~= "human" then
        return false
    end
	local other_raid_id = other:get_raid_id()
	if other_raid_id == define.INVAILD_ID then
		local other_team_id = other:get_team_id()
		if other_team_id == define.INVAILD_ID then
			return false
		end
		return other_team_id == self:get_team_id()
	else
		return other_raid_id == self:get_raid_id()
	end
	return false
end

-- 是否为副本队友
-- @param other 其他对象
function human:is_raidmate(other)
    if not other then
        return false
    end
    if other:get_obj_type() ~= "human" then
        return false
    end
	local other_raid_id = other:get_raid_id()
    if other_raid_id == define.INVAILD_ID then
        return false
    end
    return other_raid_id == self:get_raid_id()
end

-- 是否为伙伴
-- @param other 其他对象
function human:is_partner(other)
    if self:get_obj_id() == other:get_obj_id() then
        return true
    end
    local team_id = self:get_team_id()
    if team_id == define.INVAILD_ID then
        return false
    end
    local team_id_tar = define.INVAILD_ID
    if other:get_obj_type() == "human" then
        team_id_tar = other:get_team_id()
    elseif other:get_obj_type() == "pet" then
        local owner = other:get_owner()
        if owner and owner:get_obj_type() == "human" then
            team_id_tar = owner:get_team_id()
        end
    end
    if team_id_tar == define.INVAILD_ID then
        return false
    end
    return team_id_tar == team_id
end

function human:get_model()
    return self.db:get_attrib("model")
end

function human:set_model(model)
    self.db:set_db_attrib({ model = model })
end

function human:get_face_style()
    return self.db:get_attrib("face_style")
end

function human:get_hair_style()
    return self.db:get_attrib("hair_style")
end

function human:get_hair_color()
    return self.db:get_attrib("hair_color")
end

function human:get_team_id()
    return self.db:get_attrib("team_id")
end

function human:get_raid_id()
    return self.db:get_attrib("raid_id")
end

function human:get_team_info()
    return self.team_info
end

function human:get_is_team_leader()
    return self.db:get_attrib("is_team_leader") == 1
end

function human:get_team_follow_flag()
    return self.db:get_attrib("team_follow_flag") == 1
end

function human:set_team_follow_flag(flag)
    flag = flag and 1 or 0
    self.db:set_not_gen_attrib({ team_follow_flag = flag})
end

function human:add_team_follow_member(follow_member)
    local teaminfo = self:get_team_info()
    teaminfo:add_followd_member(follow_member)
end

function human:get_team_follow_speed()
    return self.db:get_attrib("team_follow_speed")
end

function human:set_team_follow_speed(speed)
    self.db:set_not_gen_attrib( { team_follow_speed = speed } )
end

function human:get_team_follow_speed_up()
    return self.db:get_attrib("team_follow_speed_up")
end

function human:set_team_follow_speed_up(team_follow_speed_up)
    self.db:set_not_gen_attrib( { team_follow_speed_up = team_follow_speed_up } )
end

function human:out_of_team_follow_range()

end

function human:in_team_follow_range()

end

function human:update_raid_info_by_raid_list(msg)
    local raid_info = self.raid_info
	if not raid_info then
		return
	end
	local sceneId = self.scene:get_id()
	local guid = self:get_guid()
	-- A full roster replaces removed members and assistant roles.
	raid_info:clean_up()
	raid_info:set_raid_id(msg.m_RaidID)
	raid_info:set_my_scene_id(sceneId)
	raid_info:set_my_guid(guid)
	local mb,obj
	for _,list in ipairs(msg.member_list) do
		for _,member in ipairs(list) do
			mb = {
				guid = member.guid,
				m_Position = member.m_Position,
				sceneid = member.sceneid,
				m_objID = define.INVAILD_ID,
			}
			if mb.guid == guid then
				mb.m_objID = self:get_obj_id()
			elseif mb.sceneid == sceneId then
				obj = self.scene:get_obj_by_id(member.m_objID)
				if obj and obj:get_guid() == mb.guid then
					mb.m_objID = obj:get_obj_id()
				end
			end
			raid_info:add_member(mb)
		end
	end
	-- self.attr_msg_to_team_inteval_count = 0
	-- self:sync_raid_member_info()
end

function human:update_raid_info(msg)
	-- skynet.logi("update_raid_info = ",self:get_name(),"msg = ",table.tostr(msg))
    local bNotifyTeamInfoFlag = false
	local raid_info = self.raid_info
	if not raid_info then
		return bNotifyTeamInfoFlag
	end
    local name = self:get_name()
    if msg.return_type == define.RAID_RESULT.RAID_RESULT_MEMBERENTER
        or msg.return_type == define.RAID_RESULT.RAID_RESULT_REFRESH then
        if not raid_info:has_raid() then
            raid_info:set_raid_id(msg.raid_id)
            raid_info:set_my_scene_id(self.scene:get_id())
            raid_info:set_my_guid(self:get_guid())
        end
        local mb = {}
        mb.guid = msg.guid
        mb.m_Position = msg.m_Position
        mb.sceneid = msg.sceneid
        if mb.guid == self:get_guid() then
            mb.m_objID = self:get_obj_id()
        elseif mb.sceneid == self.scene:get_id() then
            local obj = self.scene:get_obj_by_id(msg.m_objID)
            if obj then
                mb.m_objID = obj:get_obj_id()
            end
            bNotifyTeamInfoFlag = true
        else
            mb.m_objID = define.INVAILD_ID
            bNotifyTeamInfoFlag = true
        end
        -- msg.guid_ex = mb.m_objID
        raid_info:add_member(mb)
    elseif msg.return_type == define.RAID_RESULT.RAID_RESULT_ENTERSCENE then
        if msg.guid == self:get_guid() then
			-- if not raid_info:has_raid() then
				-- raid_info:set_raid_id(msg.raid_id)
				-- raid_info:set_my_scene_id(self.scene:get_id())
				-- raid_info:set_my_guid(self:get_guid())
			-- end
            -- raid_info:enter_scene(msg.guid, msg.sceneid , self:get_obj_id())
        else
            local oid = define.INVAILD_ID
            if msg.sceneid == self:get_scene():get_id() then
                local other = self:get_scene():get_obj_by_guid(msg.guid)
                if other then
                    oid = other:get_obj_id()
                end
            end
            raid_info:enter_scene(msg.guid, msg.sceneid, oid)
            bNotifyTeamInfoFlag = true
        end
    elseif msg.return_type == define.RAID_RESULT.RAID_RESULT_MEMBERLEAVE
        or msg.return_type == define.RAID_RESULT.RAID_RESULT_KICK
        or msg.return_type == define.RAID_RESULT.RAID_RESULT_LEADERLEAVE then
            -- if self.raid_info:is_full() then
            -- end
            if self:get_guid() == msg.guid then
                raid_info:dis_miss()
            else
				raid_info:del_member(msg.guid)
                -- if msg.return_type == define.RAID_RESULT.RAID_RESULT_LEADERLEAVE then
                    -- raid_info:change_raid_position()
                -- end
            end
            bNotifyTeamInfoFlag = true
    elseif msg.return_type == define.RAID_RESULT.RAID_RESULT_DISMISS then
		raid_info:dis_miss()
        bNotifyTeamInfoFlag = true
    elseif msg.return_type == define.RAID_RESULT.RAID_RESULT_APPOINT then
        raid_info:appoint(msg.guid_ex,msg.m_Position)
        bNotifyTeamInfoFlag = true
    elseif msg.return_type == define.RAID_RESULT.RAID_RESULT_STARTCHANGESCENE then
        raid_info:start_change_scene(msg.guid)
        if self:get_guid() == msg.guid then
        else
            bNotifyTeamInfoFlag = true
        end
    elseif msg.return_type == define.RAID_RESULT.RAID_RESULT_MEMBEROFFLINE then
        raid_info:member_offline(msg.guid)
        bNotifyTeamInfoFlag = true
    end
    return bNotifyTeamInfoFlag
end

function human:stop_team_follow_self()
    local teaminfo = self:get_team_info()
    if self:get_team_follow_flag() then
        self:get_ai():push_command_stop_team_follow()
    end
    self:set_team_follow_flag(false)
    if teaminfo then
        teaminfo:clear_followed_members()
    end
    local msg = packet_def.GCReturnTeamFollow.new()
    msg.return_type = define.TEAM_FOLLOW_RESULT.TF_RESULT_STOP_FOLLOW
    msg.guid = self:get_guid()
    self:get_scene():send2client(self, msg)
end


function human:update_team_info(msg)
    local bNotifyTeamInfoFlag = false
	if not self.team_info then
		return bNotifyTeamInfoFlag
	end
    local name = self:get_name()
    if msg.return_type == define.TEAM_RESULT.TEAM_RESULT_MEMBERENTERTEAM
        or msg.return_type == define.TEAM_RESULT.TEAM_RESULT_TEAMREFRESH then
        if not self.team_info:has_team() then
            self.team_info:set_team_id(msg.team_id)
            self.team_info:set_my_scene_id(self.scene:get_id())
            self.team_info:set_my_guid(self:get_guid())
            self.team_info:set_team_leader(msg.leader_guid)
        end
        local mb = {}
        mb.guid = msg.guid
        mb.sceneid = msg.sceneid
        if mb.guid == self:get_guid() then
            mb.m_objID = self:get_obj_id()
        elseif mb.sceneid == self.scene:get_id() then
            local obj = self.scene:get_obj_by_id(msg.guid_ex)
            if obj then
                mb.m_objID = obj:get_obj_id()
            end
            bNotifyTeamInfoFlag = true
        else
            mb.m_objID = define.INVAILD_ID
            bNotifyTeamInfoFlag = true
        end
        msg.guid_ex = mb.m_objID
        self.team_info:add_member(mb)
        -- 新成员入队后重新广播跟随列表，保持客户端UI同步
        if self:get_team_follow_flag() and self:get_is_team_leader() then
            local team_leader = self.scene:get_obj_by_guid(self:get_guid())
            if team_leader then
                local msg2 = packet_def.GCTeamFollowList.new()
                msg2.m_objID = team_leader:get_obj_id()
                local count = team_leader:get_team_info():get_followed_members_count()
                for i = 1, count do
                    local fd = team_leader:get_team_info():get_followed_member(i)
                    table.insert(msg2.guids, fd.guid)
                end
                self.scene:broadcast(team_leader, msg2, true)
            end
        end
    elseif msg.return_type == define.TEAM_RESULT.TEAM_RESULT_ENTERSCENE then
        if msg.guid == self:get_guid() then
            if not self.team_info:has_team() then
                self.team_info:set_team_id(msg.team_id)
                self.team_info:set_my_scene_id(self.scene:get_id())
                self.team_info:set_my_guid(self:get_guid())
                self.team_info:set_team_leader(msg.leader_guid)
            end
            self.team_info:enter_scene(msg.guid, msg.sceneid , self:get_obj_id())
        else
            local oid = define.INVAILD_ID
            if msg.sceneid == self:get_scene():get_id() then
                local other = self:get_scene():get_obj_by_guid(msg.guid)
                if other then
                    oid = other:get_obj_id()
                end
            end
            self.team_info:enter_scene(msg.guid, msg.sceneid, oid)
            bNotifyTeamInfoFlag = true
        end
    elseif msg.return_type == define.TEAM_RESULT.TEAM_RESULT_MEMBERLEAVETEAM
        or msg.return_type == define.TEAM_RESULT.TEAM_RESULT_TEAMKICK
        or msg.return_type == define.TEAM_RESULT.TEAM_RESULT_LEADERLEAVETEAM then
            if self.team_info:is_full() then
            end
            if self:get_guid() == msg.guid then
                if self:get_team_follow_flag() then
                    self:stop_team_follow()
                end
                self.team_info:dis_miss()
                self.db:set_not_gen_attrib({is_in_team = 0})
                self.db:set_not_gen_attrib({is_team_leader = 0})
                self.db:set_not_gen_attrib({team_id = define.INVAILD_ID})
            else
                self.team_info:del_member(msg.guid)
                if msg.return_type == define.TEAM_RESULT.TEAM_RESULT_LEADERLEAVETEAM then
                    self.team_info:appoint(msg.leader_guid)
                    if self:get_team_follow_flag() then
                        self:stop_team_follow()
                    end
                end
            end
            bNotifyTeamInfoFlag = true
    elseif msg.return_type == define.TEAM_RESULT.TEAM_RESULT_TEAMDISMISS then
        if self:get_team_follow_flag() then
            self:stop_team_follow()
        end
        local teaminfo = self:get_team_info()
        teaminfo:set_team_id(define.INVAILD_ID)
        teaminfo:set_team_leader(define.INVAILD_ID)
        bNotifyTeamInfoFlag = true
    elseif msg.return_type == define.TEAM_RESULT.TEAM_RESULT_TEAMAPPOINT then
        if self:get_team_follow_flag() then
            self:stop_team_follow()
        end
        self.team_info:appoint(msg.guid_ex)
        bNotifyTeamInfoFlag = true
    elseif msg.return_type == define.TEAM_RESULT.TEAM_RESULT_STARTCHANGESCENE then
        self.team_info:start_change_scene(msg.guid)
        if self:get_guid() == msg.guid then
        else
            bNotifyTeamInfoFlag = true
        end
    elseif msg.return_type == define.TEAM_RESULT.TEAM_RESULT_MEMBEROFFLINE then
        self.team_info:member_offline(msg.guid)
        bNotifyTeamInfoFlag = true
    end
    return bNotifyTeamInfoFlag
end

function human:stop_team_follow()
    local teaminfo = self:get_team_info()
    if not teaminfo:has_team() then
        return
    end
    local team_leader
    if self:get_team_follow_flag() then
        if self:get_is_team_leader() then
            team_leader = self
            local cross_scene_guids = {}
            local followd_member_count = teaminfo:get_followed_members_count()
            for i = followd_member_count, 1, -1 do
                local followd_member = teaminfo:get_followed_member(i)
                if followd_member and followd_member.guid ~= self:get_guid() then
                    local member = self:get_scene():get_obj_by_guid(followd_member.guid)
                    if member then
                        member:get_team_info():clear_followed_members()
                        member:get_ai():push_command_stop_team_follow()
                        member:set_team_follow_flag(false)

                        local msg = packet_def.GCReturnTeamFollow.new()
                        msg.return_type = define.TEAM_FOLLOW_RESULT.TF_RESULT_STOP_FOLLOW
                        msg.guid = member:get_guid()
                        self:get_scene():send2client(member, msg)
                    else
                        table.insert(cross_scene_guids, followd_member.guid)
                    end
                end
            end
            teaminfo:clear_followed_members()
            self:get_ai():push_command_stop_team_follow()
            self:set_team_follow_flag(false)
            local msg = packet_def.GCReturnTeamFollow.new()
            msg.return_type = define.TEAM_FOLLOW_RESULT.TF_RESULT_STOP_FOLLOW
            msg.guid = self:get_guid()
            self:get_scene():send2client(self, msg)
            if #cross_scene_guids > 0 then
                self:get_scene():send_world(self, "lua", "notify_stop_team_follow", cross_scene_guids)
            end
        else
            local team_leader_guid = teaminfo:get_team_leader()
            team_leader = self:get_scene():get_obj_by_guid(team_leader_guid)
            local guid = self:get_guid()
            local cross_scene_guids = {}
            teaminfo:del_followd_member(guid)
            self:get_ai():push_command_stop_team_follow()
            self:set_team_follow_flag(false)

            local followd_member_count = teaminfo:get_followed_members_count()
            for i = followd_member_count, 1, -1 do
                local followd_member = teaminfo:get_followed_member(i)
                if followd_member then
                    local member = self:get_scene():get_obj_by_guid(followd_member.guid)
                    if member then
                        member:get_team_info():del_followd_member(guid)
                    else
                        table.insert(cross_scene_guids, followd_member.guid)
                    end
                end
            end
            teaminfo:clear_followed_members()
            local msg = packet_def.GCReturnTeamFollow.new()
            msg.return_type = define.TEAM_FOLLOW_RESULT.TF_RESULT_STOP_FOLLOW
            msg.guid = self:get_guid()
            self:get_scene():send2client(self, msg)
            if team_leader then
                self:get_scene():send2client(team_leader, msg)
            end
            if #cross_scene_guids > 0 then
                self:get_scene():send_world(self, "lua", "notify_del_team_follow_member", cross_scene_guids, guid)
            end
        end
    end
    if team_leader then
        local msg = packet_def.GCTeamFollowList.new()
        msg.m_objID = team_leader:get_obj_id()
        local leader_teaminfo = team_leader:get_team_info()
        local followd_team_member_count = leader_teaminfo:get_followed_members_count()
        for i = 1, followd_team_member_count do
            local followd_member = leader_teaminfo:get_followed_member(i)
            if followd_member then
                table.insert(msg.guids, followd_member.guid)
            end
        end
        self:get_scene():broadcast(team_leader, msg, true)
    end
    self:get_scene():send_world(self, "lua", "leave_team_follow", self:get_guid())
end

function human:update_team_info_by_team_list(msg)
    local t=self:get_team_info()
    if not t then return end
    if msg.member_size==0 then
        t:clean_up()
        self:send_refresh_attrib()
        return true
    end
    -- A roster is a replacement, not an append: removed members cannot keep EXP/follow privileges.
    local leader=msg.leader_guid or msg.member_list[1].guid
    local keep=t:get_team_id()==msg.team_id and t:get_team_leader()==leader
    if not keep then t:clean_up()end
    t.members={};t.scene_members={}
    t:set_my_guid(self:get_guid());t:set_my_scene_id(self.scene:get_id())
    for _,m in ipairs(msg.member_list)do t:add_member(m)end
    t:set_team_id(msg.team_id);t:set_team_leader(leader);t:set_exp_mode(msg.exp_mode)
    self:send_refresh_attrib()
    return true
end

function human:update_team_option(msg)
    local teaminfo = self:get_team_info()
	if not teaminfo then
		return
	end
    teaminfo:set_option(msg)
end

function human:item_flush()
    self.db:item_effect_flush()
end

function human:send_refresh_attrib()
    self.db:send_refresh_attrib()
end

function human:mark_data_dirty_flag(param)
    self.db:mark_data_dirty_flag(param)
end

function human:sync_raid_member_info()
    local raid_info = self.raid_info
    if not raid_info then
        return
    end
    if not raid_info:has_raid() then
        return
    end
	local near_count = raid_info:get_scene_member_count()
	-- skynet.logi("near_count = ",near_count)
    if near_count < 1 then
        return
    end
    local msg = packet_def.GCRaidMemberInfo.new()
	msg.flag = 0
	msg.m_RaidID = raid_info:get_raid_id()
    msg.guid = self:get_attrib("guid")
    self.last_sync_raid_member_info = self.last_sync_raid_member_info or {}
    local menpai = self:get_attrib("menpai")
    if self.last_sync_raid_member_info.menpai ~= menpai then
        msg:set_menpai(menpai)
        self.last_sync_raid_member_info.menpai = menpai
    end
    local level = self:get_attrib("level")
    if self.last_sync_raid_member_info.level ~= level then
        msg:set_level(level)
        self.last_sync_raid_member_info.level = level
    end
    local world_pos = self:get_attrib("world_pos")
    self.last_sync_raid_member_info.world_pos = self.last_sync_raid_member_info.world_pos or {}
    if self.last_sync_raid_member_info.world_pos.x ~= world_pos.x or self.last_sync_raid_member_info.world_pos.y ~= world_pos.y then
        msg:set_world_pos(world_pos)
        self.last_sync_raid_member_info.world_pos = world_pos
    end
    local hp = self:get_attrib("hp")
    if self.last_sync_raid_member_info.hp ~= hp then
        msg:set_hp(hp)
        self.last_sync_raid_member_info.hp = hp
    end
    local hp_max = self:get_attrib("hp_max")
    if self.last_sync_raid_member_info.hp_max ~= hp_max then
        msg:set_hp_max(hp_max)
        self.last_sync_raid_member_info.hp_max = hp_max
    end
	
    local die = self:is_die()
    if self.last_sync_raid_member_info.die ~= die then
        msg:set_is_die(die)
        self.last_sync_raid_member_info.die = die
    end
    local hair_id = self:get_attrib("hair_id")
    if self.last_sync_raid_member_info.hair_id ~= hair_id then
        msg:set_hair_id(hair_id)
        self.last_sync_raid_member_info.hair_id = hair_id
    end
    local hair_color = self:get_attrib("hair_color")
    if self.last_sync_raid_member_info.hair_color ~= hair_color then
        msg:set_hair_color(hair_color)
        self.last_sync_raid_member_info.hair_color = hair_color
    end
    local portrait_id = self:get_attrib("portrait_id")
    if self.last_sync_raid_member_info.portrait_id ~= portrait_id then
        msg:set_portrait_id(portrait_id)
        self.last_sync_raid_member_info.portrait_id = portrait_id
    end
	local check_wg = function(tbl1,tbl2)
		if tbl1.visual ~= tbl2.visual then
			return true
		elseif tbl1.item_index ~= tbl2.item_index then
			return true
		end
		return
	end
	local weapon = self:get_game_flag_keys_visual(define.HUMAN_EQUIP.HEQUIP_WEAPON)
    if check_wg(self.last_sync_raid_member_info.weapon or {},weapon) then
        msg:set_weapon(weapon)
        self.last_sync_raid_member_info.weapon = weapon
    end
	local cap = self:get_game_flag_keys_visual(define.HUMAN_EQUIP.HEQUIP_CAP)
    if check_wg(self.last_sync_raid_member_info.cap or {},cap) then
        msg:set_cap(cap)
        self.last_sync_raid_member_info.cap = cap
    end
	local armour = self:get_game_flag_keys_visual(define.HUMAN_EQUIP.HEQUIP_ARMOR)
    if check_wg(self.last_sync_raid_member_info.armour or {},armour) then
        msg:set_armour(armour)
        self.last_sync_raid_member_info.armour = armour
    end
	local cuff = self:get_game_flag_keys_visual(define.HUMAN_EQUIP.HEQUIP_GLOVE)
    if check_wg(self.last_sync_raid_member_info.cuff or {},cuff) then
        msg:set_cuff(cuff)
        self.last_sync_raid_member_info.cuff = cuff
    end
	local foot = self:get_game_flag_keys_visual(define.HUMAN_EQUIP.HEQUIP_BOOT)
    if check_wg(self.last_sync_raid_member_info.foot or {},foot) then
        msg:set_foot(foot)
        self.last_sync_raid_member_info.foot = foot
    end
	local fashion = self:get_game_flag_keys_visual(define.HUMAN_EQUIP.HEQUIP_FASHION)
    if check_wg(self.last_sync_raid_member_info.fashion or {},fashion) then
        msg:set_fashion(fashion)
        self.last_sync_raid_member_info.fashion = fashion
    end
    if msg.flag ~= 0 then
        msg.data_index = 0
		local scene = self:get_scene()
        for i = near_count, 1, -1 do
            local oid = raid_info:get_scene_member_obj_id(i)
            local raidmate = scene:get_obj_by_id(oid)
            if raidmate then
                scene:send2client(raidmate, msg)
            else
                raid_info:del_scene_member(oid)
            end
        end
    end
end

function human:sync_team_member_info()
    local team_info = self:get_team_info()
    if not team_info then
        return
    end
	-- skynet.logi("sync_team_member_info:has_team = ",team_info:has_team(),"count = ",team_info:get_team_member_count())
    if not team_info:has_team() then
        return
    end
    local msg = packet_def.GCTeamMemberInfo.new()
    msg.guid = self:get_attrib("guid")
    local sync_self = false
    self.last_sync_team_member_info = self.last_sync_team_member_info or {}
    local menpai = self:get_attrib("menpai")
    if self.last_sync_team_member_info.menpai ~= menpai then
        msg:set_menpai(menpai)
        self.last_sync_team_member_info.menpai = menpai
    end
    local level = self:get_attrib("level")
    if self.last_sync_team_member_info.level ~= level then
        msg:set_level(level)
        self.last_sync_team_member_info.level = level
    end
    local world_pos = self:get_attrib("world_pos")
    self.last_sync_team_member_info.world_pos = self.last_sync_team_member_info.world_pos or {}
    if self.last_sync_team_member_info.world_pos.x ~= world_pos.x or self.last_sync_team_member_info.world_pos.y ~= world_pos.y then
        msg:set_world_pos(world_pos)
        self.last_sync_team_member_info.world_pos = world_pos
    end
    local hp = self:get_attrib("hp")
    if self.last_sync_team_member_info.hp ~= hp then
        msg:set_hp(hp)
        self.last_sync_team_member_info.hp = hp
    end
    local hp_max = self:get_attrib("hp_max")
    if self.last_sync_team_member_info.hp_max ~= hp_max then
        msg:set_hp_max(hp_max)
        self.last_sync_team_member_info.hp_max = hp_max
    end
    local check_wg = function(tbl1, tbl2)
        if tbl1.visual ~= tbl2.visual then
            return true
        elseif tbl1.item_index ~= tbl2.item_index then
            return true
        end
    end
    local function sync_visual(cache_key, equip_point, setter)
        local visual = self:get_game_flag_keys_visual(equip_point)
        local cached = self.last_sync_team_member_info[cache_key]
        if cached == nil then
            self.last_sync_team_member_info[cache_key] = visual
        elseif check_wg(cached, visual) then
            setter(msg, visual)
            sync_self = true
            self.last_sync_team_member_info[cache_key] = visual
        end
    end
    sync_visual("weapon", define.HUMAN_EQUIP.HEQUIP_WEAPON, msg.set_weapon)
    sync_visual("cap", define.HUMAN_EQUIP.HEQUIP_CAP, msg.set_cap)
    sync_visual("armour", define.HUMAN_EQUIP.HEQUIP_ARMOR, msg.set_armour)
    sync_visual("cuff", define.HUMAN_EQUIP.HEQUIP_GLOVE, msg.set_cuff)
    sync_visual("foot", define.HUMAN_EQUIP.HEQUIP_BOOT, msg.set_foot)
    sync_visual("fashion", define.HUMAN_EQUIP.HEQUIP_FASHION, msg.set_fashion)
    local function sync_value(cache_key, value, setter)
        local cached = self.last_sync_team_member_info[cache_key]
        if cached == nil then
            self.last_sync_team_member_info[cache_key] = value
        elseif cached ~= value then
            setter(msg, value)
            sync_self = true
            self.last_sync_team_member_info[cache_key] = value
        end
    end
    sync_value("face_style", self:get_face_style() or 0, msg.set_face_style)
    sync_value("hair_style", self:get_hair_style() or 0, msg.set_hair_style)
    sync_value("hair_color", self:get_hair_color() or 0, msg.set_hair_color)
    local function sync_exterior(cache_key, exterior_id, exterior_pos, setter)
        exterior_id = exterior_id or 0
        exterior_pos = exterior_pos or 0
        local cached = self.last_sync_team_member_info[cache_key]
        if cached == nil then
            self.last_sync_team_member_info[cache_key] = { id = exterior_id, pos = exterior_pos }
        elseif cached.id ~= exterior_id or cached.pos ~= exterior_pos then
            setter(msg, exterior_id, exterior_pos)
            sync_self = true
            self.last_sync_team_member_info[cache_key] = { id = exterior_id, pos = exterior_pos }
        end
    end
    local exterior_back_id, exterior_back_pos = self:get_exterior_back_visual_id()
    sync_exterior("exterior_back", exterior_back_id, exterior_back_pos, msg.set_exterior_back)
    local exterior_head_id, exterior_head_pos = self:get_exterior_head_visual_id()
    sync_exterior("exterior_head", exterior_head_id, exterior_head_pos, msg.set_exterior_head)
    local pet_soul_melting_model = self:get_attrib("pet_soul_melting_model") or define.INVAILD_ID
    if self.last_sync_team_member_info.pet_soul_melting_model == nil then
        self.last_sync_team_member_info.pet_soul_melting_model = pet_soul_melting_model
    elseif self.last_sync_team_member_info.pet_soul_melting_model ~= pet_soul_melting_model then
        msg:set_pet_soul_melting_model(pet_soul_melting_model)
        sync_self = true
        self.last_sync_team_member_info.pet_soul_melting_model = pet_soul_melting_model
    end
    local ride_model = self:get_ride_model() or define.INVAILD_ID
    if self.last_sync_team_member_info.ride_model == nil then
        self.last_sync_team_member_info.ride_model = ride_model
    elseif self.last_sync_team_member_info.ride_model ~= ride_model then
        msg:set_ride_model(ride_model)
        sync_self = true
        self.last_sync_team_member_info.ride_model = ride_model
    end
    if msg.flag ~= 0 then
        msg.data_index = 0
        if sync_self then
            self:get_scene():send2client(self, msg)
        end
        for i = team_info:get_scene_member_count(), 1, -1 do
            local oid = team_info:get_scene_member_obj_id(i)
            local teammate = self:get_scene():get_obj_by_id(oid)
            if teammate then
                self:get_scene():send2client(teammate, msg)
            else
                team_info:del_scene_member(oid)
            end
        end
    end
end

function human:send_refresh_cool_down_time()
    local cool_downd = {}
    for id, cool_down_time in pairs(self.cool_down_times) do
        if cool_down_time < 0 then
            cool_downd[id] = true
        end
    end
    for id in pairs(cool_downd) do
        self.cool_down_times[id] = nil
        self:on_skill_cool_down(id)
    end
end

function human:on_skill_cool_down(id)
    if self.skill_comb_operation and self.skill_comb_operation.skill_id then
        local skill_id = self.skill_comb_operation.skill_id
        local template = skillenginer:get_skill_template(skill_id)
        if template.cool_down_id == tonumber(id) then
            self:combo_skill_cool_downd(skill_id)
        end
    end
end

function human:update_ve_recover(delta_time)
    if self.ve_recover_timer then
        if self.ve_recover_timer > 0 then
            self.ve_recover_timer = self.ve_recover_timer - delta_time
        else
            self.ve_recover_timer = nil
            local vigor = self:get_vigor()
            local vigor_max = self:get_vigor_max()
            vigor = vigor + 1
            vigor = vigor > vigor_max and vigor_max or vigor

            local energy = self:get_stamina()
            local energy_max = self:get_stamina_max()
            energy = vigor + 1
            energy = energy > energy_max and energy_max or energy

            self:set_vigor(vigor)
            self:set_stamina(energy)
        end
    else
        local config_info = configenginer:get_config("config_info")
        self.ve_recover_timer = tonumber(config_info.Human.HumanVERecoverInterval)
    end
end

function human:update_double_exp_info(delta_time)
    local double_exp_info = self.double_exp_info
    if not double_exp_info.is_lock then
        if double_exp_info.free_time > 0 then
            double_exp_info.free_time = double_exp_info.free_time - delta_time / 1000
            return
        else
            double_exp_info.free_time = 0 
        end
        if double_exp_info.money_time > 0 then
            double_exp_info.money_time = double_exp_info.money_time - delta_time / 1000
            return
        else
            double_exp_info.money_time = 0 
        end
    end
end

function human:wash_some_points(ntype, point)
    local base_lv1_attrs = self:get_level_lv1_base_attr()
    local key
    if ntype == 1 then
        key = "str"
    elseif ntype == 2 then
        key = "spr"
    elseif ntype == 3 then
        key = "con"
    elseif ntype == 4 then
        key = "int"
    elseif ntype == 5 then
        key = "dex"
    end
    assert(key, ntype)
    local lv1_attrib = self.db:get_lv1_attrib()
    point = point > (lv1_attrib[key] - base_lv1_attrs[key]) and (lv1_attrib[key] - base_lv1_attrs[key]) or point
    self.db:set_lv1_attrib({ [key] = lv1_attrib[key] - point })
    self.db:set_lv1_attrib({ ["point_remain"] = lv1_attrib["point_remain"] + point })
    self:item_flush()
    return point
end

function human:get_level_lv1_base_attr()
    local level = self:get_level()
    local wash_point_level = define.DEFAULT_WASHPOINT_LEVEL
    local attr_level_up = configenginer:get_config("attr_level_up_table")
    local menpai = self:get_attrib("menpai")
    local chn = define.ENUM_MENPAI_CHN[menpai]
    local lv1_attrs = {}
    for i = 0, level do
        local attr_up = attr_level_up[i]
		--attr_up[力量][恶人谷] = value
        for attr, v in pairs(attr_up) do
            if v[chn] then
                local v_chn = v[chn]
                local key = attr
                local add = 0
                if type(v_chn) == "table" then
                    add = v_chn[1]
                else
                    add = v_chn
                end
                local e = lv1_attrs[key] or 0
                local new = e + add
                lv1_attrs[key] = new
            end
        end
        local key = "point_remain"
        local add_point_remain = self:get_level_up_point_remain_add(i)
        local e = lv1_attrs[key] or 0
        local new = e + add_point_remain
        lv1_attrs[key] = new
    end
    return lv1_attrs
end

function human:wash_points()
    local lv1_attrs = self:get_level_lv1_base_attr()
    for attr, value in pairs(lv1_attrs) do
        self.db:set_lv1_attrib({ [attr] = value })
    end
    self:item_flush()
end

function human:get_lv1_point_remain()
    return self.db:get_lv1_attrib().point_remain
end

function human:set_lv1_point_remain(value)
    self.db:set_lv1_attrib({ ["point_remain"] = value })
end

function human:change_menpai_points()
    self:wash_points()
    self.db:mark_all_attr_dirty()
end

function human:manual_attr(manual)
    assert(manual.str >= 0, manual.str)
    assert(manual.spr >= 0, manual.spr)
    assert(manual.con >= 0, manual.con)
    assert(manual.int >= 0, manual.int)
    assert(manual.dex >= 0, manual.dex)
    local lv1_attribs = self.db:get_lv1_attrib()
    local point_remain = lv1_attribs.point_remain
    local total = manual.str + manual.spr + manual.con + manual.int + manual.dex
    if total > point_remain then
        return define.ATTR_RESUlT.ATTR_RESULT_NOT_ENOUGH_REMAIN_POINT
    end
    self.db:set_lv1_attrib({ point_remain = point_remain - total})
    self.db:set_lv1_attrib({ str = lv1_attribs.str + manual.str })
    self.db:set_lv1_attrib({ spr = lv1_attribs.spr + manual.spr })
    self.db:set_lv1_attrib({ con = lv1_attribs.con + manual.con })
    self.db:set_lv1_attrib({ int = lv1_attribs.int + manual.int })
    self.db:set_lv1_attrib({ dex = lv1_attribs.dex + manual.dex })
    self:send_refresh_attrib()
    return define.ATTR_RESUlT.ATTR_RESUlT_SUCCESS
end

function human:add_ride_buff(ride_buffs)
	local list = self:get_impact_list()
	local istrue
	for buff,flag in pairs(ride_buffs) do
		-- skynet.logi("buff = ",buff)
		-- skynet.logi("flag = ",flag)
		if flag == 1 then
			istrue = false
			for _, imp in ipairs(list) do
				if imp:get_data_index() == buff then
					istrue = true
					break
				end
			end
			if not istrue then
				impactenginer:send_impact_to_unit(self, buff, self, 100, false, 0)
			end
		else
			for _, imp in ipairs(list) do
				if imp:get_data_index() == buff then
					self:on_impact_fade_out(imp)
					self:remove_impact(imp)
					break
				end
			end
		end
	end
end

function human:send_exterior_info(open_type)

    local now = os.time()
	
    local exterior_ride = configenginer:get_config("exterior_ride")
    local mail = {
        guid = define.INVAILD_ID,
        source = "",
        portrait_id = define.INVAILD_ID,
        dest = self:get_name(),
        flag = define.MAIL_TYPE.MAIL_TYPE_SYSTEM,
        create_time = now
    }
	
    local my_exterior_weapon_visuals = self.exterior.weapon_visuals or {}
    local msg = packet_def.GCExteriorInfo.new()
    local msg_term = packet_def.GCExteriorInfo.new()
    msg.type = open_type or 0
    msg.unknow_2 = 0
    msg.unknow_3 = 1
    msg.weapon_visual_count = #my_exterior_weapon_visuals
    msg.list_1 = {}
    msg.weapon_visuals = {}
    msg.hair_colors = {}
    msg.extrior_list = {}
    msg_term.type = open_type
    msg_term.unknow_2 = 0
    msg_term.extrior_list = {}
    for i = 1, msg.weapon_visual_count do
        local visual = my_exterior_weapon_visuals[i] or { id = 0, term = define.INVAILD_ID, level = 0}
        table.insert(msg.weapon_visuals, visual)
    end
    local my_faces = self.exterior.faces
    msg.list_1[define.Exterior_Type.Face] = {list = {}}
    msg.list_1[define.Exterior_Type.Face].size = #my_faces
    for i = 1, msg.list_1[define.Exterior_Type.Face].size do
        local face = my_faces[i]
        table.insert(msg.list_1[define.Exterior_Type.Face].list, {
            unknow_1 = face.id,
            unknow_2 = face.term,
            unknow_3 = 0
        })
    end
    local my_hairs = self.exterior.hairs
    msg.list_1[define.Exterior_Type.Hair] = {list = {}}
    msg.list_1[define.Exterior_Type.Hair].size = #my_hairs
    for i = 1, msg.list_1[define.Exterior_Type.Hair].size do
        local hair = my_hairs[i]
        table.insert(msg.list_1[define.Exterior_Type.Hair].list, {
            unknow_1 = hair.id,
            unknow_2 = hair.term,
            unknow_3 = 0
        })
    end
    local my_heads = self.exterior.heads
    msg.list_1[define.Exterior_Type.Head] = {list = {}}
    msg.list_1[define.Exterior_Type.Head].size = #my_heads
    for i = 1, msg.list_1[define.Exterior_Type.Head].size do
        local head = my_heads[i]
        table.insert(msg.list_1[define.Exterior_Type.Head].list, {
            unknow_1 = head.id,
            unknow_2 = head.term,
            unknow_3 = 0
        })
    end
	local cur_rideid = self:get_ride()
	local del_iscur = false
	
	local ride_dy_info = {}
	local ride_buffs = {}
	local env = skynet.getenv("env")
	if define.ADD_EQUIP_BUFF[env] then
		for _,dy_info in ipairs(define.ADD_EQUIP_BUFF[env]) do
			if dy_info[define.HUMAN_EQUIP.HEQUIP_RIDER] then
				table.insert(ride_dy_info,dy_info[define.HUMAN_EQUIP.HEQUIP_RIDER])
				local buff_id = dy_info[define.HUMAN_EQUIP.HEQUIP_RIDER].BUFFID
				ride_buffs[buff_id] = 0
			end
		end
	end
    local my_rides = self.exterior.rides
    msg.list_1[define.Exterior_Type.Ride] = {list = {}}
	for i = #my_rides,1,-1 do
		local ride = my_rides[i]
		if ride.term == -1 then
			table.insert(msg.list_1[define.Exterior_Type.Ride].list, {
				unknow_1 = ride.id,
				unknow_2 = -1,
				unknow_3 = 0
			})
			for _,have in ipairs(ride_dy_info) do
				if ride.id >= have.MINID and ride.id <= have.MAXID then
					local buff_id = have.BUFFID
					ride_buffs[buff_id] = 1
				end
			end
		elseif ride.term > now then
			table.insert(msg.list_1[define.Exterior_Type.Ride].list, {
				unknow_1 = ride.id,
				unknow_2 = -1,
				unknow_3 = 0
				-- unknow_1 = ride.id,
				-- unknow_2 = ride.term - now,
				-- unknow_3 = 1
			})
            table.insert(msg_term.extrior_list, {id = ride.id, remindtime = ride.term - now, unknow_3 = i})
			for _,have in ipairs(ride_dy_info) do
				if ride.id >= have.MINID and ride.id <= have.MAXID then
					local buff_id = have.BUFFID
					ride_buffs[buff_id] = 1
				end
			end
		else
			local del_ride = table.remove(my_rides,i)
			local del_rideid = del_ride.id
			if del_rideid == cur_rideid then
				del_iscur = true
			end
            if exterior_ride[del_rideid] and exterior_ride[del_rideid].name then
                local del_mail = string.contact_args("#{YXQ_221123_01", exterior_ride[del_ride.id].name) .. "}"
               if del_mail then
					mail.content = del_mail
					skynet.send(".world", "lua", "send_mail", mail)
				end
            end
		end
	end
    msg.list_1[define.Exterior_Type.Ride].size = #my_rides
    -- for i = 1, msg.list_1[define.Exterior_Type.Ride].size do
        -- local ride = my_rides[i]
        -- table.insert(msg.list_1[define.Exterior_Type.Ride].list, {
            -- unknow_1 = ride.id,
            -- unknow_2 = -1,
            -- unknow_3 = 0
        -- })
        -- if ride.term > now then
            -- table.insert(msg_term.extrior_list, {id = ride.id, remindtime = ride.term - now, unknow_3 = i})
        -- end
    -- end
    local my_poss = self.exterior.poss
    msg.list_1[define.Exterior_Type.Poss] = {list = {}}
    msg.list_1[define.Exterior_Type.Poss].size = #my_poss
    for i = 1, msg.list_1[define.Exterior_Type.Poss].size do
        local pos = my_poss[i]
        table.insert(msg.list_1[define.Exterior_Type.Poss].list, {
            unknow_1 = pos.id,
            unknow_2 = -1,
            unknow_3 = 0
        })
    end
    local my_hair_colors = self.exterior.hair_colors or {}
    -- GCExteriorInfo 这里发送的是方案数量；当前选中项由人物发色属性同步。
    local hair_color_count = 1
    for i = 2, 20 do
        local hair_color = my_hair_colors[i]
        if not hair_color or hair_color.value == nil or hair_color.value == 0 then
            break
        end
        hair_color_count = i
    end
    msg.exterior_hair_color_index = hair_color_count
    for i = 1, 20 do
        local hair_color = my_hair_colors[i] or { value = 0 }
        msg.hair_colors[i] = hair_color
    end
	--flagwg
    if open_type == 6 then
		local visual_id,visual_level = self:get_exterior_weapon_visual_id()
		local BackId,BackPos = self:get_exterior_back_visual_id()
		local HeadId,HeadPos = self:get_exterior_head_visual_id()
		local soul_ranse = -1
		local exterior_pet_soul_id = self:get_exterior_pet_soul_id()
		if exterior_pet_soul_id and exterior_pet_soul_id > 0 then
			soul_ranse = exterior_pet_soul_id * 10 + (self:get_exterior_ranse_select() or 0)
		end
		msg.exterior_back_id = BackId
		msg.exterior_back_pos = BackPos
		msg.exterior_head_id = HeadId
		msg.exterior_head_pos = HeadPos
		msg.extrior_weapon_visual_id = visual_id
		msg.extrior_weapon_visual_level = visual_level
		msg.extrior_soul_ranse = soul_ranse
	end
    msg.extrior_count = #msg.extrior_list
    self:get_scene():send2client(self, msg)
    if open_type == define.Exterior_Type.Ride then
		-- msg_term.exterior_back_id = BackId
		-- msg_term.exterior_back_pos = BackPos
		-- msg_term.exterior_head_id = HeadId
		-- msg_term.exterior_head_pos = HeadPos
        msg_term.extrior_count = #msg_term.extrior_list
        self:get_scene():send2client(self, msg_term)
    end
	
	
	if del_iscur then
		self.db:set_attrib({ride = -1})
        local imp = self:impact_get_first_impact_of_specific_class_id(99)
		if imp then
			self:on_impact_fade_out(imp)
			self:remove_impact(imp)
		end
	end
	self:add_ride_buff(ride_buffs)
end

function human:have_this_head_image(id)
    local heads = self.exterior.heads
    for _, v in ipairs(heads) do
        if v.id == id then
            return true
        end
    end
    return false
end

function human:have_this_face_style(id)
    local faces = self.exterior.faces
    for _, v in ipairs(faces) do
        if v.id == id then
            return true
        end
    end
    return false
end

function human:have_this_hair_style(id)
    local hairs = self.exterior.hairs
    for _, v in ipairs(hairs) do
        if v.id == id then
            return true
        end
    end
    return false
end

function human:have_this_ride(index)
    local rides = self.exterior.rides
    for _, v in ipairs(rides) do
        if v.id == index then
            return true
        end
    end
    return false
end

function human:reverse_ride(index)
	local isdel
    local rides = self.exterior.rides
    for i, v in ipairs(rides) do
        if v.id == index then
			isdel = table.remove(rides,i)
			break
        end
    end
	if isdel then
		if self:get_ride() == index then
			self.db:set_attrib({ride = -1})
			local imp = self:impact_get_first_impact_of_specific_class_id(99)
			if imp then
				self:on_impact_fade_out(imp)
				self:remove_impact(imp)
			end
		end
		self:send_exterior_info()
		-- 坐骑从收藏列表删除，刷新外观属性加成
		exterior_bonus.refresh_bonus(self)
	end
    return isdel
end


function human:add_expiration_time(index, add)
    local now = os.time()
    local istrue = false
    local add_finish = false
    local rides = self.exterior.rides
    local function update_ride(ride, add)
        if add == -1 then
            ride.term = -1
            ride.terminable = 0
        else
            if ride.term < now then
                ride.term = now + add
            else
                ride.term = ride.term + add
            end
            ride.terminable = 1
        end
    end
    for i = #rides, 1, -1 do
        local v = rides[i]
        if v.id == index then
            if v.term ~= -1 then
                update_ride(v, add)
                add_finish = true
            end
            istrue = true
        end
    end
    if not istrue then
        local ride = { id = index, term = now + add, terminable = 1 }
        if add == -1 then
            ride.term = -1
            ride.terminable = 0
        end
        table.insert(rides, ride)
        add_finish = true
    end
    return add_finish
end


function human:get_double_exp_info()
    return self.double_exp_info
end

function human:send_double_exp_info()
    local msg = packet_def.GCDoubleExpInfo.new()
    msg.available_hour = self.double_exp_info.available_hour
    msg.is_lock = self.double_exp_info.is_lock and 1 or 0
    msg.money_time = math.floor(self.double_exp_info.money_time)
    msg.total_time = math.floor(self.double_exp_info.money_time) + math.floor(self.double_exp_info.free_time)
    msg.rtime = self.double_exp_info.rtime
    self:get_scene():send2client(self, msg)
end

-- 发送巅峰(DFeng)系统详细属性到客户端
-- 参数说明:
--   dfeng_menpai: 巅峰门派选择
--   dfeng_level: 巅峰等级
--   dfeng_exp: 巅峰经验(格式1)
--   dfeng_data4: 巅峰数据4
--   dfeng_levelup_data: 巅峰升级相关数据
--   dfeng_exp_value: 巅峰经验值(客户端GetDFengExp读取此值)
--   dfeng_attack_xdd: 百分比伤害加成
--   dfeng_defence_xdd: 百分比减伤
function human:send_dfeng_detail_attrib(params)
    local msg = packet_def.GCDetailAttrib.new()
    msg.m_objID = self:get_obj_id()
    if params.dfeng_menpai ~= nil then
        msg:set_dfeng_menpai(params.dfeng_menpai)
    end
    if params.dfeng_level ~= nil then
        msg:set_dfeng_level(params.dfeng_level)
    end
    if params.dfeng_exp ~= nil then
        msg:set_dfeng_exp(params.dfeng_exp)
    end
    if params.dfeng_data4 ~= nil then
        msg:set_dfeng_data4(params.dfeng_data4)
    end
    if params.dfeng_levelup_data ~= nil then
        msg:set_dfeng_levelup_data(params.dfeng_levelup_data)
    end
    if params.dfeng_exp_value ~= nil then
        msg:set_dfeng_exp_value(params.dfeng_exp_value)
    end
    if params.dfeng_attack_xdd ~= nil then
        msg:set_dfeng_attack_xdd(params.dfeng_attack_xdd)
    end
    if params.dfeng_defence_xdd ~= nil then
        msg:set_dfeng_defence_xdd(params.dfeng_defence_xdd)
    end
    -- 心络攻击加成 → CData[10728], 触发UI事件1655
    if params.dfeng_essence_attack ~= nil then
        msg:set_dfeng_essence_attack(params.dfeng_essence_attack)
    end
    self:get_scene():send2client(self, msg)
end

-- 发送GCCharBaseAttrib DFeng字段 (packet 756)
-- DFeng flags写入new_flags[13] (客户端offset 0x29)
-- 客户端收到每个packed值后做 %100//100 解包写入两个CData槽位:
--   bit 0x01 → CData[10640]  (GetDFengExp实际读此)         → 填 cur_exp
--   bit 0x02 → CData[10644]  (GetDFengLevelupTimes实际读此) → 填 cur_levelup_data
--   bit 0x04 → CData[10648]  (预留)                              → (可选)
--   bit 0x08 → CData[10652]  (GetDFengLevel)                → 填 cur_level
-- 以下每个bit的packed值由客户端解包写入两个CData槽(%100和/100分别写):
--   bit 0x10(ad1) → %100→CData[10660], /100→CData[10668]  → Defence交叉栀1
--   bit 0x20(ad2) → %100→CData[10664], /100→CData[10672]  → Attack1直传
--   bit 0x40(ad3) → %100→CData[10676], /100→CData[10684]  → Defence交叉栀2
--   bit 0x80(ad4) → %100→CData[10680], /100→CData[10688]  → Attack2直传
-- flags2:
--   bit 0x01(ad5) → %100→CData[10692], /100→CData[10700]  → Defence交叉栀3
--   bit 0x02(ad6) → %100→CData[10696], /100→CData[10704]  → Attack3直传
--   bit 0x04(ad7) → CData[10656]  (GetDFengEssenceLevel)
-- 注意: GCCharBaseAttrib不触发UI事件, UI刷新依赖GCDetailAttrib的event 1540/1582
function human:send_dfeng_base_attrib(params)
    local msg = packet_def.GCCharBaseAttrib.new()
    msg.m_objID = self:get_obj_id()
    if params.dfeng_level ~= nil then
        msg.dfeng_base_flags = (msg.dfeng_base_flags or 0) | 0x2
        msg.dfeng_base_level = params.dfeng_level
    end
    if params.dfeng_exp ~= nil then
        msg.dfeng_base_flags = (msg.dfeng_base_flags or 0) | 0x8
        msg.dfeng_base_exp = params.dfeng_exp
    end
    if params.dfeng_levelup_data ~= nil then
        msg.dfeng_base_flags = (msg.dfeng_base_flags or 0) | 0x1
        msg.dfeng_base_levelup_data = params.dfeng_levelup_data
    end
    -- IDA确认正确bit映射(交叉打包):
    -- ad1(bit0x10): %100→CData[10660]=DefXDD3, /100→CData[10668]=DefMenPai1
    -- ad2(bit0x20): %100→CData[10664]=AtkMenPai1, /100→CData[10672]=AtkXDD1
    -- ad3(bit0x40): %100→CData[10676]=DefXDD1, /100→CData[10684]=DefMenPai2
    -- ad4(bit0x80): %100→CData[10680]=AtkMenPai2, /100→CData[10688]=AtkXDD2
    -- ad5(f2 0x01): %100→CData[10692]=DefXDD2, /100→CData[10700]=DefMenPai3
    -- ad6(f2 0x02): %100→CData[10696]=AtkMenPai3, /100→CData[10704]=AtkXDD3
    -- ad7(f2 0x04): EssenceLevel → CData[10656]
    if params.dfeng_attack_defence1 and params.dfeng_attack_defence1 >= 0 then
        msg.dfeng_base_flags = (msg.dfeng_base_flags or 0) | 0x10
        msg.dfeng_base_attack_defence1 = params.dfeng_attack_defence1
    end
    if params.dfeng_attack_defence2 and params.dfeng_attack_defence2 >= 0 then
        msg.dfeng_base_flags = (msg.dfeng_base_flags or 0) | 0x20
        msg.dfeng_base_attack_defence2 = params.dfeng_attack_defence2
    end
    if params.dfeng_attack_defence3 and params.dfeng_attack_defence3 >= 0 then
        msg.dfeng_base_flags = (msg.dfeng_base_flags or 0) | 0x40
        msg.dfeng_base_attack_defence3 = params.dfeng_attack_defence3
    end
    if params.dfeng_attack_defence4 and params.dfeng_attack_defence4 >= 0 then
        msg.dfeng_base_flags = (msg.dfeng_base_flags or 0) | 0x80
        msg.dfeng_base_attack_defence4 = params.dfeng_attack_defence4
    end
    if params.dfeng_attack_defence5 and params.dfeng_attack_defence5 >= 0 then
        msg.dfeng_base_flags2 = (msg.dfeng_base_flags2 or 0) | 0x01
        msg.dfeng_base_attack_defence5 = params.dfeng_attack_defence5
    end
    if params.dfeng_attack_defence6 and params.dfeng_attack_defence6 >= 0 then
        msg.dfeng_base_flags2 = (msg.dfeng_base_flags2 or 0) | 0x02
        msg.dfeng_base_attack_defence6 = params.dfeng_attack_defence6
    end
    if params.dfeng_essence_level ~= nil then
        msg.dfeng_base_flags2 = (msg.dfeng_base_flags2 or 0) | 0x04
        msg.dfeng_base_attack_defence7 = params.dfeng_essence_level
    end
    -- flags2 bit 0x08 -> CData[10708-10720] (4xDWORD) + UI事件1656
    if params.dfeng_kw_data ~= nil then
        msg.dfeng_base_flags2 = (msg.dfeng_base_flags2 or 0) | 0x08
        msg.dfeng_base_kw_data1 = params.dfeng_kw_data[1] or 0
        msg.dfeng_base_kw_data2 = params.dfeng_kw_data[2] or 0
        msg.dfeng_base_kw_data3 = params.dfeng_kw_data[3] or 0
        msg.dfeng_base_kw_data4 = params.dfeng_kw_data[4] or 0
    end
    -- flags2 bit 0x10 -> CData[10724] 心络总等级
    if params.dfeng_kw_total_level ~= nil then
        msg.dfeng_base_flags2 = (msg.dfeng_base_flags2 or 0) | 0x10
        msg.dfeng_base_kw_total_level = params.dfeng_kw_total_level
    end
    -- ad2=atk1(直传school+xdd*100) → Client: GetAttackMenPai1()=%100, GetAttackMenPaiXDD1()=/100
    -- ad4=atk2 → GetAttackMenPai2/XDD2, ad6=atk3 → GetAttackMenPai3/XDD3
    -- ad1=def_cross(DefXDD3+DefSchool1*100), ad3=def_cross, ad5=def_cross
    self:get_scene():send2client(self, msg)
end

-- 检查DFeng升级（支持多级连续升级）
-- 从 configenginer 读取 dfeng_point_info 获取经验阈值，按当前等级每10级循环使用1-10档配置
-- 迁移自 edali_Martial_Arts.lua:CheckDFengLevelUp
function human:dfeng_check_levelup()
    local open = self:get_mission_data_by_script_id(965) or 0
    if open < 1 then return false end
    
    -- 周标识: week_id = year%100 * 100 + floor((yday-1)/7)
    -- MD 970 打包格式: week_id * 10000 + 武境周升级次数 * 100 + 通脉周升级次数
    -- local now = os.time()
    -- local now_t = os.date("*t", now)
    -- local week_id = (now_t.year % 100) * 100 + math.floor((now_t.yday - 1) / 7)
    
    -- if stored_week ~= week_id then
    --     -- 新的一周，重置武境/通脉周计数和经验
    --     dfeng_weekly = 0
    --     essence_weekly = 0
    --     self:set_mission_data_by_script_id(960, 0)
    --     stored_week = week_id
    --     self:set_mission_data_by_script_id(970, stored_week * 10000)
    -- end
    
    local dfeng_point_info = configenginer:get_config("dfeng_point_info")
    
    local bLevelUp = false
    for i = 1, 200 do
        local nLevel = self:get_mission_data_by_script_id(961) or 0
        local nExp = self:get_mission_data_by_script_id(960) or 0
        
        if nLevel >= 200 then
            if nExp > 0 then
                self:set_mission_data_by_script_id(960, 0)
            end
            break
        end

        local nExpIndex = nLevel + 1
        local nExpNeed = tonumber(dfeng_point_info[nExpIndex]) or tonumber(dfeng_point_info[(nLevel % 10) + 1]) or 250000000
        
        if nExp >= nExpNeed then
            self:set_mission_data_by_script_id(961, nLevel + 1)
            self:set_mission_data_by_script_id(960, nExp - nExpNeed)
            bLevelUp = true
            self:notify_tips("恭喜！巅峰等级升至" .. (nLevel + 1) .. "级！")
        else
            break
        end
    end
    
    return bLevelUp
end

-- 通用DFeng属性刷新函数
-- 从MissionData读取最新经验/等级/升级次数，发送756包和320包刷新客户端UI
function human:refresh_dfeng_attrib()
    -- Open标记在MD[965]（利用客户端gap位置）
    local dfeng_open = self:get_mission_data_by_script_id(965) or 0
    if dfeng_open < 1 then
        return
    end
    
    -- 先检查是否需要升级（支持GM设置经验后自动升级）
    if dfeng_open >= 1 then
        self:dfeng_check_levelup()
    end
    
    -- 刷新属性加成（DFeng等级变化后需要重算属性）
    self:item_flush()
    self:send_refresh_attrib()
    
    -- DFeng核心MD历史上可能残留-1，显示和发包都按0处理。
    local cur_exp = math.max(0, self:get_mission_data_by_script_id(960) or 0)
    local cur_level = math.max(0, self:get_mission_data_by_script_id(961) or 0)
    local cur_levelup_data = math.max(0, self:get_mission_data_by_script_id(962) or 0)
    
    -- GCCharBaseAttrib: 756包发送levelup_data + level + exp
    -- 注意：字段名和语义是反的（IDA确认），这些映射是正确的不要改：
    -- dfeng_levelup_data(bit 0x1) → CData[10640] → GetDFengExp → 填 cur_exp
    -- dfeng_level(bit 0x2) → CData[10644] → GetDFengEssenceLevel → 填 cur_levelup_data(通脉等级)
    -- dfeng_exp(bit 0x8) → CData[10652] → 内部数据 → 填 cur_level(武境等级)
    -- dfeng_essence_level(f2 0x04) → CData[10656] → GetDFengLevel → 填 cur_levelup_data(通脉等级)
    
    -- 从MissionData读取6个独立攻防条目
    -- 每条格式: school + xdd * 100（2值打包，与客户端getter格式一致）
    local raw_atk1 = self:get_mission_data_by_script_id(963)
    local raw_def1 = self:get_mission_data_by_script_id(964)
    local raw_atk2 = self:get_mission_data_by_script_id(966)
    local raw_def2 = self:get_mission_data_by_script_id(967)
    local raw_atk3 = self:get_mission_data_by_script_id(968)
    local raw_def3 = self:get_mission_data_by_script_id(969)
    local atk1_data = math.max(0, raw_atk1 or 0)  -- MD_DFeng_Attack1
    local def1_data = math.max(0, raw_def1 or 0)  -- MD_DFeng_Defence1
    local atk2_data = math.max(0, raw_atk2 or 0)  -- MD_DFeng_Attack2
    local def2_data = math.max(0, raw_def2 or 0)  -- MD_DFeng_Defence2
    local atk3_data = math.max(0, raw_atk3 or 0)  -- MD_DFeng_Attack3
    local def3_data = math.max(0, raw_def3 or 0)  -- MD_DFeng_Defence3
    
    -- 计算攻防修为总点数（仅按等级计算，不扣除已分配）
    -- 注意：客户端UI自己会用GetAttackMenPaiXDD1-3减去已分配点数，所以320包发送TOTAL
    local attack_xdd = 0
    local attack_levels = {10,30,50,70,90,110,130,150,170,190}
    for i = 1, 10 do
        if cur_level >= attack_levels[i] then attack_xdd = attack_xdd + 2 end
    end
    
    local defence_xdd = 0
    local defence_levels = {20,40,60,80,100,120,140,160,180,200}
    for i = 1, 10 do
        if cur_level >= defence_levels[i] then defence_xdd = defence_xdd + 2 end
    end
    
    -- 解包Defence MDs（格式: school + xdd*100）用于交叉打包
    local def1_school = def1_data % 100
    local def1_xdd   = math.floor(def1_data / 100)
    local def2_school = def2_data % 100
    local def2_xdd   = math.floor(def2_data / 100)
    local def3_school = def3_data % 100
    local def3_xdd   = math.floor(def3_data / 100)
    
    -- IDA确认: Defence值在客户端CData中交叉排列，需要跨槽打包
    -- Attack值直接传（school+xdd*100 → bit偶数位 0x20/0x80/f2_0x02）
    -- Defence值交叉打包（bit奇数位 0x10/0x40/f2_0x01）
    local def_cross_bit10  = def3_xdd   + def1_school * 100  -- →CData[10660]=DefXDD3, CData[10668]=DefMenPai1
    local def_cross_bit40  = def1_xdd   + def2_school * 100  -- →CData[10676]=DefXDD1, CData[10684]=DefMenPai2
    local def_cross_f2bit01= def2_xdd   + def3_school * 100  -- →CData[10692]=DefXDD2, CData[10700]=DefMenPai3
    
    -- 心络攻击加成: 每个孔位独立读取修习模式(active)和选择的元素(sel)
    -- active: 1=专脉→attr_bonus, 2=二脉→attr_value1, 3=三脉→attr_value2, 4=四属性→attr_value3
    -- 元素选择存在 MD 976-985, 通过 get_dfeng_kw_slot_attrs 读取
    local kw_total_level = 0
    local kw_info = configenginer:get_config("dfeng_essence_kw_info")
    local kw_element_attack = {0, 0, 0, 0}  -- 1=冰 2=火 3=玄 4=毒
    local bonus_fields = { "attr_bonus", "attr_value1", "attr_value2", "attr_value3" }
    for i = 1, 20 do
        local level = self:get_dfeng_kw_slot_level(i)
        kw_total_level = kw_total_level + level
        local active = self:get_dfeng_kw_slot_active(i)
        if level > 0 and active >= 1 and active <= 4 and kw_info and kw_info[i] then
            local cfg = kw_info[i][level]
            local bonus_field = bonus_fields[active]
            if cfg and bonus_field and cfg[bonus_field] then
                local bonus = cfg[bonus_field]
                local sel1, sel2, sel3 = self:get_dfeng_kw_slot_attrs(i)
                if active == 1 then
                    if sel1 >= 1 and sel1 <= 4 then kw_element_attack[sel1] = kw_element_attack[sel1] + bonus end
                elseif active == 2 then
                    if sel1 >= 1 and sel1 <= 4 then kw_element_attack[sel1] = kw_element_attack[sel1] + bonus end
                    if sel2 >= 1 and sel2 <= 4 then kw_element_attack[sel2] = kw_element_attack[sel2] + bonus end
                elseif active == 3 then
                    if sel1 >= 1 and sel1 <= 4 then kw_element_attack[sel1] = kw_element_attack[sel1] + bonus end
                    if sel2 >= 1 and sel2 <= 4 then kw_element_attack[sel2] = kw_element_attack[sel2] + bonus end
                    if sel3 >= 1 and sel3 <= 4 then kw_element_attack[sel3] = kw_element_attack[sel3] + bonus end
                elseif active == 4 then
                    for e = 1, 4 do kw_element_attack[e] = kw_element_attack[e] + bonus end
                end
            end
        end
    end
    
    self:send_dfeng_base_attrib({
        dfeng_levelup_data = cur_exp,
        dfeng_level = cur_levelup_data,
        dfeng_exp = cur_level,
        dfeng_essence_level = cur_levelup_data,  -- f2 0x04 → CData[10656] → GetDFengEssenceLevel = 通脉等级
        dfeng_attack_defence1 = def_cross_bit10,   -- bit0x10: DefXDD3+DefSchool1*100
        dfeng_attack_defence2 = atk1_data,          -- bit0x20: Attack1 直传
        dfeng_attack_defence3 = def_cross_bit40,    -- bit0x40: DefXDD1+DefSchool2*100
        dfeng_attack_defence4 = atk2_data,          -- bit0x80: Attack2 直传
        dfeng_attack_defence5 = def_cross_f2bit01,  -- f2 0x01: DefXDD2+DefSchool3*100
        dfeng_attack_defence6 = atk3_data,          -- f2 0x02: Attack3 直传
        dfeng_kw_total_level = kw_total_level,      -- f2 0x10 → CData[10724] 心络总等级
        dfeng_kw_data = kw_element_attack,           -- f2 0x08 → CData[10708-10720] 冰/火/玄/毒攻击
    })
    
    -- GCDetailAttrib: 320包设置CData显示值 + 触发UI刷新事件
    self:send_dfeng_detail_attrib({
        dfeng_exp_value = cur_level,
        dfeng_level = cur_levelup_data,   -- CData[10628], 与756包dfeng_level语义一致=通脉等级
        dfeng_exp = cur_exp,
        dfeng_levelup_data = cur_exp,
        dfeng_attack_xdd = attack_xdd,
        dfeng_defence_xdd = defence_xdd,
        dfeng_essence_attack = kw_element_attack[1] + kw_element_attack[2] + kw_element_attack[3] + kw_element_attack[4],
    })
end

-- 武境高位mission统一补发
-- GCMissionList只含前200条mission，武境相关的MD(960-975 → client_id 1299-1314)
-- 不在列表中，客户端收到GCMissionList后可能清空这些高位mission缓存
-- 此函数用于在 send_mission_list/on_enter_scene/on_login 后重新补发
-- 客户端 GetAttackMenPai1() 等旧getter读 CDetailAttrib[0x1995..0x19AD]，数据来源就是这些mission
local DFENG_SYNC_MDS = {960,961,962,963,964,965,966,967,968,969,970,971,972,973,974,975}

function human:sync_dfeng_learn_md_to_client()
    for _, sid in ipairs(DFENG_SYNC_MDS) do
        local val = self:get_mission_data_by_script_id(sid)
        if val and val < 0 then
            -- 武境高位MD使用DWORD下发，负值会导致writeuint溢出，登录同步前归零。
            self.mission_data.mission_datas[sid + 1] = 0
        end
        self:update_md_value(sid)
    end
end

-- 获取攻击武诀数据 (返回3组 {school, xdd})
-- MD格式: school + xdd*100, school=门派ID(1-15), xdd=已分配武诀点数
local DFENG_ATK_SIDS = {963, 966, 968}
function human:get_dfeng_attack_slots()
    local slots = {}
    for i, sid in ipairs(DFENG_ATK_SIDS) do
        local raw = math.max(0, self:get_mission_data_by_script_id(sid) or 0)
        slots[i] = { school = raw % 100, xdd = math.floor(raw / 100) }
    end
    return slots
end

-- 获取守御武诀数据 (返回3组 {school, xdd})
local DFENG_DEF_SIDS = {964, 967, 969}
function human:get_dfeng_defence_slots()
    local slots = {}
    for i, sid in ipairs(DFENG_DEF_SIDS) do
        local raw = math.max(0, self:get_mission_data_by_script_id(sid) or 0)
        slots[i] = { school = raw % 100, xdd = math.floor(raw / 100) }
    end
    return slots
end

-- 客户端在登录/过图后会分阶段重建mission缓存，高位DFeng mission(1299~1314)
-- 可能被后续流程覆盖。这里做多次延迟补发，确保Peak_Learn/SelfPeak打开时仍能读到旧getter链数据。
function human:schedule_dfeng_learn_resync(reason)
    local scene = self:get_scene()
    if not scene then
        return
    end

    local retries = {5, 15, 30}
    for _, delay in ipairs(retries) do
        skynet.timeout(delay, function()
            if self:get_scene() ~= scene then
                return
            end
            self:sync_dfeng_learn_md_to_client()
        end)
    end
end

-- 发送GCDFengEssenceSynKongWeiData(758): 武境心络孔位数据
-- IDA确认: Execute写入CData[14380+12*i], 触发UI事件1654
-- 每个slot 12字节: slot_level(2) + 6×attr(6) + reserved(2) + extra(2)
-- page_or_selected: -1=全部显示, 其他值=指定页/孔位
function human:send_dfeng_essence_kongwei(page_or_selected, slots)
    local msg = packet_def.GCDFengEssenceSynKongWeiData.new()
    msg.page_or_selected = page_or_selected or -1
    if slots then
        for i = 1, 20 do
            if slots[i] then
                msg.slots[i] = slots[i]
            end
        end
    else
        if self.ensure_dfeng_essence_kongwei_unlocked then
            self:ensure_dfeng_essence_kongwei_unlocked()
        end
        for i = 1, 20 do
            local level = self:get_dfeng_kw_slot_level(i)
            local active = self:get_dfeng_kw_slot_active(i)
            local sel1, sel2, sel3 = self:get_dfeng_kw_slot_attrs(i)
            -- slot_level ushort: 低字节=等级, 高字节=属性类型
            msg.slots[i].slot_level = level | (active << 8)
            -- 根据active类型填充attr字段(sel必须>=1, 0会导致客户端strTable[0]崩溃)
            if active == 1 then
                msg.slots[i].attr_zhuanmai = math.max(1, sel1)
            elseif active == 2 then
                msg.slots[i].attr_ermai_1 = math.max(1, sel1)
                msg.slots[i].attr_ermai_2 = math.max(1, sel2)
            elseif active == 3 then
                msg.slots[i].attr_sanmai_1 = math.max(1, sel1)
                msg.slots[i].attr_sanmai_2 = math.max(1, sel2)
                msg.slots[i].attr_sanmai_3 = math.max(1, sel3)
            elseif active == 4 then
                msg.slots[i].attr_zhuanmai = 1
                msg.slots[i].attr_ermai_1 = 2
                msg.slots[i].attr_ermai_2 = 3
                msg.slots[i].attr_sanmai_1 = 4
            end
        end
    end
    self:get_scene():send2client(self, msg)
end

-- 心络孔位等级读写 (MD 971-975, 每个MD存4个孔位, byte packed)
-- 每个byte: 低4位=等级(0-8), 高4位=属性类型(0-4)
function human:get_dfeng_kw_slot_level(slot_index)
    if slot_index < 1 or slot_index > 20 then return 0 end
    local md_idx = 971 + math.floor((slot_index - 1) / 4)
    local byte_shift = ((slot_index - 1) % 4) * 8
    local packed = self:get_mission_data_by_script_id(md_idx) or 0
    return (packed >> byte_shift) & 0x0F  -- 低4位=等级
end

function human:set_dfeng_kw_slot_level(slot_index, level)
    if slot_index < 1 or slot_index > 20 then return end
    level = math.max(0, math.min(8, level))
    local md_idx = 971 + math.floor((slot_index - 1) / 4)
    local byte_shift = ((slot_index - 1) % 4) * 8
    local packed = self:get_mission_data_by_script_id(md_idx) or 0
    packed = packed & ~(0x0F << byte_shift)  -- 清除低4位
    packed = packed | (level << byte_shift)   -- 写入等级
    self:set_mission_data_by_script_id(md_idx, packed)
end

-- 心络孔位属性类型读写 (0=未选择, 1=专脉, 2=二脉, 3=三脉, 4=四属性)
function human:get_dfeng_kw_slot_active(slot_index)
    if slot_index < 1 or slot_index > 20 then return 0 end
    local md_idx = 971 + math.floor((slot_index - 1) / 4)
    local byte_shift = ((slot_index - 1) % 4) * 8
    local packed = self:get_mission_data_by_script_id(md_idx) or 0
    return ((packed >> byte_shift) >> 4) & 0x0F  -- 高4位=属性类型
end

function human:set_dfeng_kw_slot_active(slot_index, active)
    if slot_index < 1 or slot_index > 20 then return end
    active = math.max(0, math.min(4, active))
    local md_idx = 971 + math.floor((slot_index - 1) / 4)
    local byte_shift = ((slot_index - 1) % 4) * 8
    local packed = self:get_mission_data_by_script_id(md_idx) or 0
    packed = packed & ~(0xF0 << byte_shift)          -- 清除高4位
    packed = packed | ((active << 4) << byte_shift)   -- 写入属性类型
    self:set_mission_data_by_script_id(md_idx, packed)
end

-- 心络孔位元素选择读写 (MD 976-985, 每个MD存2个孔位的元素选择)
-- 每个孔位16位: (sel3 << 8) | (sel2 << 4) | sel1
function human:get_dfeng_kw_slot_attrs(slot_index)
    if slot_index < 1 or slot_index > 20 then return 0, 0, 0 end
    local md_idx = 976 + math.floor((slot_index - 1) / 2)
    local shift = ((slot_index - 1) % 2) * 16
    local packed = self:get_mission_data_by_script_id(md_idx) or 0
    local val = (packed >> shift) & 0xFFFF
    local sel1 = val & 0x0F
    local sel2 = (val >> 4) & 0x0F
    local sel3 = (val >> 8) & 0x0F
    return sel1, sel2, sel3
end

function human:set_dfeng_kw_slot_attrs(slot_index, sel1, sel2, sel3)
    if slot_index < 1 or slot_index > 20 then return end
    sel1 = math.max(0, math.min(4, sel1 or 0))
    sel2 = math.max(0, math.min(4, sel2 or 0))
    sel3 = math.max(0, math.min(4, sel3 or 0))
    local md_idx = 976 + math.floor((slot_index - 1) / 2)
    local shift = ((slot_index - 1) % 2) * 16
    local packed = self:get_mission_data_by_script_id(md_idx) or 0
    packed = packed & ~(0xFFFF << shift)
    local val = sel1 | (sel2 << 4) | (sel3 << 8)
    packed = packed | (val << shift)
    self:set_mission_data_by_script_id(md_idx, packed)
end

-- 按当前通脉等级补齐已解锁但未初始化的心络孔位
function human:ensure_dfeng_essence_kongwei_unlocked()
    local cur_essence_level = self:get_mission_data_by_script_id(962) or 0
    local unlock_count = math.floor(cur_essence_level / 10)
    unlock_count = math.max(0, math.min(20, unlock_count))

    local changed = false
    for slot_index = 1, unlock_count do
        local level = self:get_dfeng_kw_slot_level(slot_index)
        if level <= 0 then
            self:set_dfeng_kw_slot_level(slot_index, 1)
            changed = true
        end

        local active = self:get_dfeng_kw_slot_active(slot_index)
        if active <= 0 then
            active = 1
            self:set_dfeng_kw_slot_active(slot_index, active)
            changed = true
        end

        local sel1, sel2, sel3 = self:get_dfeng_kw_slot_attrs(slot_index)
        if sel1 <= 0 or sel2 <= 0 or sel3 <= 0 then
            if active == 4 then
                self:set_dfeng_kw_slot_attrs(slot_index, 1, 2, 3)
            else
                self:set_dfeng_kw_slot_attrs(slot_index, 1, 1, 1)
            end
            changed = true
        end
    end

    return changed
end

-- 计算心络总等级
function human:get_dfeng_kw_total_level()
    local total = 0
    for i = 1, 20 do
        total = total + self:get_dfeng_kw_slot_level(i)
    end
    return total
end

function human:set_exp_rate(value)
	self.double_exp_info.exp_rate = value
end

function human:get_double_exp_mult()
    local double_exp_info = self.double_exp_info
	local exp_rate = double_exp_info.exp_rate or 0
	if exp_rate > 0 then
		return exp_rate
	end
    if not double_exp_info.is_lock then
        if double_exp_info.free_time > 0 then
            return 2
        end
        if double_exp_info.money_time > 0 then
            return 2
        end
    end
    return 1
end

function human:get_pet_exp_mult()
    local value = self.db:get_attrib("pet_exp_multiple") or 0
    return value
end

function human:add_pet_by_data_id(data_id, is_rmb, growth_rate, pet_guid_low)
    local guid = pet_guid.new()
    local spouse_guid = pet_guid.new()
    if pet_guid_low then
        guid:set(self:get_guid(), pet_guid_low)
    else
        guid:set(self:get_guid(), skynet.now() * 10 + math.random(10) % 10)
    end
    local attrib = { guid = guid, spouse_guid = spouse_guid, data_id = data_id}
    local lv1_attrib = {}
    local pet = pet_detail.new()
    pet:init_from_data({ skills = {activate = {}, positive = {}}, equips = {}, lv1_attrib = lv1_attrib, attrib = attrib}, self)
    petmanager:make_capture_pet_attrib(pet, is_rmb, growth_rate, false, true)
    -- CYS-PET: truoc day bo qua ket qua cua add_pet va luon tra true, nen script trung van bao
    -- "thanh cong" khi tui thu day (da tieu hao vat pham). Tra ve ket qua THAT.
    if not self:add_pet(pet) then
        return false
    end
    return true, guid.m_uHighSection, guid.m_uLowSection
end

function human:add_pet(pet)
    local container = self:get_pet_bag_container()
    local empty_index = container:get_empty_item_index()
    -- CYS-PET 17/09/2026: truoc day la assert(empty_index ~= define.INVAILD_ID). Tui thu day thi
    -- assert lam hong CA SCENE chu khong rieng nguoi choi do. Moi nguoi goi deu doc gia tri tra ve,
    -- nen tra false la du: capture_pet -> skill_10 gui CAPTUREFALID, add_pet_by_data_id tra false.
    if empty_index == define.INVAILD_ID then
        skynet.loge(string.format("[PET_BAG_FULL] guid= %s khong con o trong tui tran thu (size= %s)",
                                  tostring(self:get_guid()), tostring(container:get_size())))
        return false
    end
    container:set_item(empty_index, pet)
    local guid = pet:get_attrib("guid")
    self:send_pets_detail(self)
    self:on_add_pet(pet)
    return true, guid.m_uHighSection, guid.m_uLowSection
end

function human:send_pets_detail(who, type)
    local container = self:get_pet_bag_container()
    local size = container:get_size()
    for i = 0, size - 1 do
        local pet = container:get_item(i)
        if pet then
            self:send_pet_detail(pet, who, type)
        end
    end
end

function human:send_pet_detail(pet, who, type)
    pet:send_refresh_attrib(who, true, type)
end

function human:set_guid_of_call_up_pet(guid)
    self.guid_of_call_up_pet = guid
end

function human:get_guid_of_call_up_pet()
    return self.guid_of_call_up_pet
end

function human:can_take(pet)
    local human_level = self:get_level()
    local take_level = pet:get_take_level()
    if human_level < take_level then
        return false
    end
    local wuxing = pet:get_wuxing()
    local extra_take_level = math.ceil(wuxing / 2)
    local level = pet:get_level()
    return human_level > (level - 5 - extra_take_level)
end

function human:test_call_up_pet(guid)
    local container = self:get_pet_bag_container()
    local pet = container:get_pet_by_guid(guid)
    if pet == nil then
        return define.OPERATE_RESULT.OR_ERROR
    end
    if pet:is_in_exchange() then
        return define.OPERATE_RESULT.OR_ERROR
    end
    if not self:can_use_skill_now() then
        return define.OPERATE_RESULT.OR_BUSY
    end
    if pet:get_hp() <= 0 then
        return define.OPERATE_RESULT.OR_NOT_ENOUGH_HP
    end
    --[[if not self:can_take(pet) then
        return define.OPERATE_RESULT.OR_NEED_HIGH_LEVEL
    end]]
    local config_info = configenginer:get_config("config_info")
    if pet:get_happiness() < config_info.Pet.PetCallUpHappiness then
        return define.OPERATE_RESULT.OR_NEED_HAPPINESS
    end
    if pet:get_life() <= 0 then
        return define.OPERATE_RESULT.OR_NEED_LIFE
    end
    return define.OPERATE_RESULT.OR_OK
end

function human:recall_pet()
    local old_guid = self.guid_of_call_up_pet
    self.guid_of_call_up_pet = pet_guid.new()
    self:set_current_pet_guid(self.guid_of_call_up_pet)
    if self.pet then
        self:impact_clean_all_impact_when_pet_dead(self.pet:get_obj_id())
        self.pet:impact_clean_all_impact_when_pet_dead(self.pet:get_obj_id())
        -- 在 release 前重刷 pet_detail 属性，清除兽魂扩展属性并发送给客户端
        if not old_guid:is_null() then
            local container = self:get_pet_bag_container()
            local pet_detail = container:get_pet_by_guid(old_guid)
            if pet_detail then
                local pet_db = pet_detail.db
                -- 临时将 pet_attrib.pet 指向 pet_detail(get_obj_id()=nil → is_fighting=false)
                pet_db:set_pet(pet_detail)
                pet_db:item_effect_flush()
                pet_db:mark_all_attr_dirty()
                -- 恢复指向场景对象，send_refresh_attrib 需要场景对象的 get_scene/get_obj_id
                pet_db:set_pet(self.pet)
                self.pet.send_all = false
                self.pet:send_refresh_attrib(false)
            end
        end
    end
    self:release_pet()
    return define.OPERATE_RESULT.OR_OK
end

function human:set_current_pet_guid(guid)
    self.db:set_db_attrib({pet_guid = guid})
end

function human:get_current_pet_guid()
    return self:get_attrib("pet_guid") or define.INVAILD_ID
end

function human:is_my_spouse()

end

function human:create_pet()
    if self.guid_of_call_up_pet:is_null() then
        return define.OPERATE_RESULT.OR_ERROR
    end
    local container = self:get_pet_bag_container()
    local pet_item = container:get_pet_by_guid(self.guid_of_call_up_pet)
    if pet_item == nil then
        return define.OPERATE_RESULT.OR_ERROR
    end
    local scene = self:get_scene()
    if scene == nil then
        return define.OPERATE_RESULT.OR_ERROR
    end
    local world_pos = table.clone(self:get_world_pos())
    world_pos.x = world_pos.x - 1
    local pet = scene:create_pet(pet_item:get_obj_data(), self:get_obj_id(), world_pos)
    self.pet = pet
    return define.OPERATE_RESULT.OR_OK
end

function human:release_pet()
    if self.pet then
        petmanager:remove_pet(self.pet:get_obj_id())
        self.pet = nil
    end
end

function human:call_up_pet()
    local container = self:get_pet_bag_container()
    local pet = container:get_pet_by_guid(self.guid_of_call_up_pet)
    if not pet or pet:is_lock() or pet:is_in_exchange() then
        return define.OPERATE_RESULT.OR_PETINEXCHANGE_CANNOT_GOFIGHT
    end
    self:release_pet()
    local result = self:create_pet()
    if result < 0 then
        return result
    end
    self:set_current_pet_guid(self.guid_of_call_up_pet)
    self:impact_on_call_up_pet_success()
    return define.OPERATE_RESULT.OR_OK
end

function human:test_pet_soul_melting(guid)
    local pet = guid and self:get_pet_bag_container():get_pet_by_guid(guid)
    if not pet or pet:is_lock() or pet:is_in_exchange() then return define.OPERATE_RESULT.OR_ERROR end
    if not self:can_use_skill_now() then return define.OPERATE_RESULT.OR_BUSY end
    if pet:get_hp() <= 0 then return define.OPERATE_RESULT.OR_NOT_ENOUGH_HP end
    if pet:get_life() <= 0 then return define.OPERATE_RESULT.OR_NEED_LIFE end
    return define.OPERATE_RESULT.OR_OK
end

function human:remelting_pet_soul()
    local soul_melting_pet = self:get_pet_bag_container():get_item_by_guid(self.guid_of_soul_melting_pet)
    if soul_melting_pet then
        self:impact_clean_when_remelting_pet_soul(soul_melting_pet)
    end
    self.guid_of_soul_melting_pet = pet_guid.new()
    self:set_current_soul_melting_pet_guid(self.guid_of_soul_melting_pet)
    self:item_flush()
    return define.OPERATE_RESULT.OR_OK
end

function human:impact_clean_when_remelting_pet_soul(pet)
    if not pet then return end
    local soul = pet:get_equip_container():get_item(define.PET_EQUIP.PEQUIP_SOUL)
    if not soul then return end
    local base = soul:get_pet_soul_base()
    local table = configenginer:get_config('pet_soul_skill')
    local conf = base and table[base.skill]
    if not conf or not conf.melting_impacts then return end
    local level = (soul:get_pet_equip_data():get_pet_soul_level() or 0) + 1
    for _, row in ipairs(conf.melting_impacts) do
        if define.PET_SOUL_BASE_ATTR_2_IA[row.desc] == define.ITEM_ATTRIBUTE.IATTRIBUTE_QIONGQI_MELTING_IMPACT then
            local id = define.QIONGQI_IMPACT[level]
            if id then
                local impact = self:impact_get_first_impact_of_specific_data_index(id)
                if impact then self:on_impact_fade_out(impact);self:remove_impact(impact) end
            end
        end
    end
end

function human:on_impact_get_combat_result(imp, combat_core, defencer)
    self:impact_on_impact_get_combat_result(imp, combat_core, defencer)
    self:talent_on_impact_get_combat_result(imp, combat_core, defencer)
end

function human:impact_on_impact_get_combat_result(imp, combat_core, defencer)
    local list = self:get_impact_list()
    for _, current in ipairs(list) do
        local logic = impactenginer:get_logic(current)
        if logic then
            logic:on_impact_get_combat_result(current, imp, combat_core, self, defencer)
        end
    end
end

function human:talent_on_impact_get_combat_result(imp, combat_core, defencer)
    local talent = self:get_talent()
    local talent_config = configenginer:get_config("sect_desc")
    for i = 1, #talent.study do
        local study_talent = talent.study[i]
        local logic = talentenginer:get_logic(study_talent)
        if logic then
            local config = talent_config[study_talent.id]
            if config then
                local level = study_talent.level
                level = level == 0 and 1 or level
                logic:on_impact_get_combat_result(config, level, imp, combat_core, self, defencer)
            end
        end
    end
end

function human:talent_on_impact_fade_out(imp)
    local talent = self:get_talent()
    local talent_config = configenginer:get_config("sect_desc")
    for i = 1, #talent.study do
        local study_talent = talent.study[i]
        local logic = talentenginer:get_logic(study_talent)
        if logic then
            local config = talent_config[study_talent.id]
            if config then
                local level = study_talent.level
                level = level == 0 and 1 or level
                logic:on_impact_fade_out(config, level, imp, self)
            end
        end
    end
end

function human:set_current_soul_melting_pet_guid(guid)
    self.db:set_db_attrib({soul_melting_pet_guid = guid})
end

function human:get_current_soul_melting_pet_guid()
    return self:get_attrib("soul_melting_pet_guid")
end

function human:set_guid_of_soul_melting_pet(guid)
    self.guid_of_soul_melting_pet = guid
end

function human:get_guid_of_soul_melting_pet()
    return self.guid_of_soul_melting_pet
end

function human:pet_soul_melting()
    local container = self:get_pet_bag_container()
    local pet = container:get_pet_by_guid(self.guid_of_soul_melting_pet)
    if pet == nil then
        return define.OPERATE_RESULT.OR_ERROR
    end
    if pet:is_in_exchange() then
        return define.OPERATE_RESULT.OR_ERROR
    end
    self.db:set_db_attrib({ soul_melting_pet_guid = self.guid_of_soul_melting_pet })
    self:item_flush()
    return define.OPERATE_RESULT.OR_OK
end

function human:baby_to_attack()
    if self.pet == nil then
        return
    end
    if not self.pet:is_alive() then
        return
    end
    local target_id = self:get_cur_target_id()
    self.pet:set_target_id(target_id)
    local pet_ai = self.pet:get_ai()
    pet_ai:baby_to_attack(pet_ai)
end

function human:on_register_to_scene()
    self:set_guid_of_call_up_pet(self:get_current_pet_guid())
    if not self.guid_of_call_up_pet:is_null() then
        local result = self:create_pet()
        if result < 0 then
            self:send_operate_result_msg(result)
        end
    end
    self:set_guid_of_soul_melting_pet(self:get_current_soul_melting_pet_guid())
    if not self.guid_of_soul_melting_pet:is_null() then
        self:pet_soul_melting()
    end
    if not self:is_alive() then
        self:get_ai():relive(false)
    end
    -- DFeng数据已移至on_enter_scene下发(客户端场景加载完成后)
    -- 原因: on_register_to_scene在init_human阶段执行,此时客户端尚未完成场景加载
    -- 客户端所有GC包Execute函数有场景同步检查,此时发送的包会被丢弃
end

function human:clean_up_pet()
    self.pet = nil
end

function human:free_pet_to_nature(logparam, guid)
    local pet = guid and self:get_pet_bag_container():get_pet_by_guid(guid)
    if not pet or pet:is_lock() or pet:is_in_exchange() or pet:have_equip()
        or guid == self:get_current_pet_guid()
        or guid == self:get_current_soul_melting_pet_guid() then
        return define.OPERATE_RESULT.OR_ERROR
    end
    for _, slot in pairs(pet.elf_slots or {}) do
        if (slot.activated or 0) ~= 0 then return define.OPERATE_RESULT.OR_ERROR end
    end
    return self:remove_pet(logparam, guid) and define.OPERATE_RESULT.OR_OK or define.OPERATE_RESULT.OR_ERROR
end

function human:remove_pet(logparam, guid)
    -- CYS-PET remove soul state before removing its owner record.
    if not self:get_pet_bag_container():get_pet_by_guid(guid) then return false end
    if self:get_current_soul_melting_pet_guid() == guid then self:remelting_pet_soul() end
    if self:get_current_pet_guid() == guid then
        self:recall_pet()
    end
    local container = self:get_pet_bag_container()
    local pet_list = container:get_item_data()
    for i = 0, container:get_size() - 1 do
        local pet = pet_list[i]
        if pet and pet:get_guid() == guid then
            container:erase_item(i)
            local msg = packet_def.GCRemovePet.new()
            msg.guid = guid
            self:get_scene():send2client(self, msg)
            return true
        end
    end
    return false
end

function human:cy_commit_equipment_skill_roll(pos,pending,materials,cost)
    return require('cy_equipment_skills').commit_roll(self,pos,pending,materials,cost)
end

function human:cy_replace_equipment_skill_roll(pos,kind)
    return require('cy_equipment_skills').commit_replace(self,pos,kind)
end

function human:cy_longwen_skill_operation(pos,operation,selection)
    return require('cy_equipment_passives').lw_operation(self,pos,operation,selection)
end

function human:cy_lingpai_operation(operation,pos,group)
    local helper=require 'cy_lingpai'
    if operation=='learn' then return helper.learn(self,pos) end
    if operation=='switch' then return helper.switch(self,pos,group) end
    if operation=='sync' then helper.sync(self);return true end
    return false
end

function human:set_temp_aq_skills(skills)
    self.temp_aq_skills = skills
end

function human:get_temp_aq_skills()
    return self.temp_aq_skills
end

function human:set_temp_wh_skills(skills)
    self.temp_wh_skills = skills
end

function human:get_temp_wh_skills()
    return self.temp_wh_skills
end

function human:set_temp_pet_soul_attr_data(bag_index,attr)
    self.temp_pet_soul_attr_data=bag_index and {bag_index=bag_index,attr=attr} or nil
end

function human:get_temp_pet_soul_attr_data()
    return self.temp_pet_soul_attr_data
end

function human:set_temp_super_attrs(super_attrs)
    self.temp_super_attrs = super_attrs
end

function human:get_temp_super_attrs()
    return self.temp_super_attrs
end

function human:set_temp_equip_attrs(item_guid, equip_attrs)
    self.temp_equip_attrs = { item_guid = item_guid, equip_attrs = equip_attrs }
end

function human:get_temp_equip_attrs()
    return self.temp_equip_attrs
end

function human:clear_temp_equip_attrs()
    self.temp_equip_attrs = nil
end

function human:get_pk_mode()
    return self.db:get_db_attrib("pk_mode")
end

function human:change_pk_mode(mode)
    -- CYS-PVP mode: reject malformed/unsupported modes before DB writes.
    if not require('cy_pvp').mode(mode) then return false end
	local limit_pk_mode = define.LIMIT_PK_MODE_ON_SCENE[self:get_scene_id()]
	-- [DIAG_RIDE_PK] ghi lai nhanh nao duoc chon
	skynet.logi("[DIAG_RIDE_PK] PK_APPLY mode_moi=", tostring(mode),
		" mode_cu=", tostring(self.db:get_db_attrib("pk_mode")),
		" scene=", tostring(self:get_scene_id()),
		" bi_gioi_han=", tostring(limit_pk_mode ~= nil))
	if limit_pk_mode then
        self.db:set_db_attrib_nil("want_change_pk_mode")
        self.db:set_db_attrib_nil("change_pk_mode_delay")  -- [audit 2026-09-03] key = nil trong table constructor khong xoa duoc
        self.db:set_db_attrib({ pk_mode = limit_pk_mode.pk_id })
		local msg = string.format("该场景只允许%s模式。",limit_pk_mode.pk_name)
		self:notify_tips(msg)
	else
		local old_mode = self.db:get_db_attrib("pk_mode")
		if (old_mode == define.PK_MODE.TEAM or old_mode == define.PK_MODE.RAID or old_mode == define.PK_MODE.PERSONAL or old_mode == define.PK_MODE.BANG_HUI or old_mode == define.PK_MODE.GOD_AND_EVIL)
			and (mode == define.PK_MODE.PEACE)  then
			self.db:set_db_attrib({ want_change_pk_mode = mode, change_pk_mode_delay = define.PK_MODE_CHANGE_DELAY})
			self:send_operate_result_msg(define.OPERATE_RESULT.OR_PVP_MODE_SWITCH_DELAY)
		else
			self.db:set_db_attrib_nil("want_change_pk_mode")
			self.db:set_db_attrib_nil("change_pk_mode_delay")  -- [audit 2026-09-03]
			self.db:set_db_attrib({ pk_mode = mode })
		end
	end
end

function human:check_pk_mode_can_change(delay)
    local want_change_pk_mode = self.db:get_db_attrib("want_change_pk_mode")
    if want_change_pk_mode then
        local change_pk_mode_delay = self.db:get_db_attrib("change_pk_mode_delay") or define.PK_MODE_CHANGE_DELAY
        change_pk_mode_delay = change_pk_mode_delay - delay
        if change_pk_mode_delay <= 0 then
            self.db:set_db_attrib_nil("want_change_pk_mode")
            self.db:set_db_attrib({ pk_mode = want_change_pk_mode, change_pk_mode_delay = 0})
        else
            self.db:set_db_attrib({ change_pk_mode_delay = change_pk_mode_delay })
        end
    end
end
function human:set_huanhun_qk(qk, index)
    assert(index >= 0, index <= 6)
    if qk == 0 then
        if self:get_attrib("huanhun_kun_index") == index then
            self.db:set_db_attrib({ huanhun_kun_index = 0 })
        end
        self.db:set_db_attrib({ huanhun_qian_index = index })
    elseif qk == 1 then
        if self:get_attrib("huanhun_qian_index") == index then
            self.db:set_db_attrib({ huanhun_qian_index = 0 })
        end
        self.db:set_db_attrib({ huanhun_kun_index = index })
    else
        assert(false)
    end
    local wuhun = self:get_equip_container():get_item(define.HUMAN_EQUIP.HEQUIP_WUHUN)
    if wuhun then
        local msg = packet_def.GCCharEquipment.new()
        msg.m_objID = self:get_obj_id()
        msg.flag = 0
        local visual, item_index = self:get_wuhun_visual()
		msg:set_wuhun(item_index,visual)
        self.scene:broadcast(self, msg, true)
        self:item_flush()
    end
end
function human:update_wuhun_visual()
    local wuhun = self:get_equip_container():get_item(define.HUMAN_EQUIP.HEQUIP_WUHUN)
    if wuhun then
        local msg = packet_def.GCCharEquipment.new()
        msg.m_objID = self:get_obj_id()
        msg.flag = 0
        local visual, item_index = self:get_wuhun_visual()
		msg:set_wuhun(item_index,visual)
        self.scene:broadcast(self, msg, true)
    end
end
function human:send_wuhun_show_state(show)
    show = show == 1 and 1 or 0
    self:set_attrib({ wuhun_show_flag = show })
    local msg = packet_def.GCCharEquipment.new()
    msg.m_objID = self:get_obj_id()
    msg.flag = 0
    local visual, item_index = self:get_wuhun_visual()
    msg:set_wuhun(item_index, visual)
    self.scene:broadcast(self, msg, true)
end
function human:get_wuhun_visual()
    local w=self:get_equip_container():get_item(define.HUMAN_EQUIP.HEQUIP_WUHUN)
    local visual,item=require('cys_wuhun_appearance').visual(w and w:get_index(),w and w:get_equip_data():get_wh_hecheng_level(),
        self:get_attrib('wuhun_show_flag'),self:get_attrib('wuhun_yy_flag'),self:get_attrib('huanhun_qian_index'),self:get_attrib('huanhun_kun_index'),self.huanhun)
    self:set_game_flag_keys_visual(define.HUMAN_EQUIP.HEQUIP_WUHUN,{[define.WG_KEY_A]=item,[define.WG_KEY_B]=-1,[define.WG_KEY_C]=visual})
    return visual,item
end

function human:active_wuhun_wg(id)
    id = tostring(id)
    assert(self.huanhun[id] == nil, id)
    self.huanhun[id] = { level = 1, grade = 0, today_count = 0}
    self:item_flush()
end

function human:active_rmb_chat_info(id, date)
    self.rmb_chat_face_info.id = id
    self.rmb_chat_face_info.dates[1] = date
    self:send_rmb_chat_face_info()
end

function human:get_mission_data_by_script_id(id)
    return self.mission_data.mission_datas[id + 1] or 0
end
--0 <= id <= 1279
function human:get_mission_flag_index_and_shift(id)
    local shift
    local script_id
    if id < 0x140 then
        local index
        if id >= 0x28 then
            index = (id - 40) // 0x1C
        else 
            index = id >> 2
        end
        local MF_1 = define.MF[1]
        index = index + 1
        script_id = MF_1[index]
        if id >= 0x28 then
            shift = (id - 40) % 0x1C + 4
        else
            shift = id & 3
        end
    else
        local index
        local MF_2 = define.MF[2]
        shift = (id - 64) & 0x1F
        index = (id - 320) >> 5
        index = index + 1
        script_id = MF_2[index]
    end
    return script_id, shift
end

function human:get_mission_flag_by_script_id(id)
    local script_id, shift = self:get_mission_flag_index_and_shift(id)
    local val = self:get_mission_data_by_script_id(script_id)
    return val & (1 << shift)
end

function human:set_mission_flag_by_script_id(id, val)
    local script_id, shift = self:get_mission_flag_index_and_shift(id)
    local old = self:get_mission_data_by_script_id(script_id)
    if val == 1 then
        old = old | (1 << shift)
    else
        old = old & (~(1 << shift))
    end
    self:set_mission_data_by_script_id(script_id, old)
end

function human:get_mission_data_ex_by_script_id(id)
    local key = tostring(id + 1)
    return self.mission_data.mission_datas_ex[key] or 0 
end

function human:set_mission_data_ex_by_script_id(id, val)
    local key = tostring(id + 1)
    self.mission_data.mission_datas_ex[key] = val
end

function human:set_mission_data_by_script_id(id, val)
	if not id then
		return
	end
    self.mission_data.mission_datas[id + 1] = val
    local msg = packet_def.GCMissionModify.new()
    msg.m_nFlag = 1
    msg.mission_id = (define.MD_SCRIPT_TO_CLIENT and define.MD_SCRIPT_TO_CLIENT[id]) or id
    msg.mission_index = val
    self:get_scene():send2client(self, msg)
    -- DFeng MD(960-985)变更时自动刷新756/320包，使DFeng UI立即更新
    -- 960-970: 经验/等级/攻防数据  971-975: 孔位等级/active  976-985: 孔位元素选择
    -- 重入锁防止递归: refresh_dfeng_attrib → dfeng_check_levelup → set_mission_data_by_script_id
    if id >= 960 and id <= 985 and not self._dfeng_refreshing then
        self._dfeng_refreshing = true
        local ok, err = xpcall(function() self:refresh_dfeng_attrib() end, debug.traceback)
        self._dfeng_refreshing = nil
        if not ok then
            skynet.loge("[DFeng] auto refresh error: ", tostring(err))
        end
    end
end

function human:send_zdzd_config()
end

function human:mission_abandon(index)
    for i, mission in ipairs(self.mission_data.char_missions) do
        if mission.index == index then
            table.remove(self.mission_data.char_missions, i)
            local msg = packet_def.GCMissionRemove.new()
            msg.id = mission.id
            self:get_scene():send2client(self, msg)
            return
        end
    end
end

function human:save_restore_scene_and_pos(sn)
    local sceneid = self:get_scene_id()
    local world_pos = self:get_world_pos()
    if sceneid < 10000 then
        self.db:set_db_attrib({ restore_scene_and_pos = { sceneid = sceneid, world_pos = world_pos, sn = sn} })
    end
end

function human:change_restore_scene_and_pos(sceneid, world_pos)
    self.db:set_db_attrib({ restore_scene_and_pos = { sceneid = sceneid, world_pos = world_pos } })
    skynet.send(self:get_agent(), "lua", "change_restore_scene_and_pos", sceneid, world_pos)
end

function human:is_have_mission(mission_id)
    return self:get_mission_index(mission_id) ~= define.INVAILD_ID
end

function human:get_mission_index(mission_id)
    for i, mission in ipairs(self.mission_data.char_missions) do
        if mission.id == mission_id then
            return i
        end
    end
    return define.INVAILD_ID
end

function human:get_mission_by_id(mission_id)
    for i, mission in ipairs(self.mission_data.char_missions) do
        if mission.id == mission_id then
            return mission
        end
    end
end

function human:get_mission_param(mission_index, index)
	assert(index,index)
    index = index + 1
    local mission = self.mission_data.char_missions[mission_index]
	assert(mission,mission_index)
    return mission.params[index]
end

function human:set_mission_by_index(mission_index, index, value)
    assert(value)
    index = index + 1
    value = math.floor(value)
    local mission = self.mission_data.char_missions[mission_index]
    mission.params[index] = value
    local msg = packet_def.GCMissionModify.new()
    msg.m_nFlag = 0
    msg.m_aMissionData = mission
    self:get_scene():send2client(self, msg)
end

function human:del_mission(mission_id)
    local index = self:get_mission_index(mission_id)
    if index ~= define.INVAILD_ID then
        local mission = self.mission_data.char_missions[index]
        table.remove(self.mission_data.char_missions, index)
        local msg = packet_def.GCMissionRemove.new()
        msg.id = mission.id
        self:get_scene():send2client(self, msg)
    end
    return true
end

function human:del_all_mission()
    for i = #self.mission_data.char_missions, 1, -1 do
        local mission = self.mission_data.char_missions[i]
        local mission_id = mission.id
        self:del_mission(mission_id)
    end
end

function human:add_mission(id, script_id, killObjEvent, enterAreaEvent, itemChangeEvent)
    if #self.mission_data.char_missions >= define.MAX_CHAR_MISSION_NUM then
        return false, define.OPERATE_RESULT.OR_MISSION_LIST_FULL
    end
    local index = self:get_mission_index(id)
    if index ~= define.INVAILD_ID then
        return false, define.OPERATE_RESULT.OR_MISSION_HAVE
    end
    local char_mission = { id = id, index = script_id, yFlag = 0, params = {0, 0, 0, 0, 0, 0, 0, 0} }
    if killObjEvent == 1 then
        char_mission.yFlag = char_mission.yFlag | 0x1 << 0
    end
    if enterAreaEvent == 1 then
        char_mission.yFlag = char_mission.yFlag | 0x1 << 1
    end
    if itemChangeEvent == 1 then
        char_mission.yFlag = char_mission.yFlag | 0x1 << 2
    end
    table.insert(self.mission_data.char_missions, char_mission)
    index = #self.mission_data.char_missions
    self:on_add_mission(index)
    return true
end

function human:reset_mission_event()

end

function human:get_script_id_by_mission_id(mission_id)
    local char_missions = self.mission_data.char_missions or {}
    for _, cm in ipairs(char_missions) do
        if cm.id == mission_id then
            return cm.index
        end
    end
end

function human:on_add_mission(index)
    local msg = packet_def.GCMissionAdd.new()
    local mission = self.mission_data.char_missions[index]
    msg.id = mission.id
    msg.index = mission.index
    msg.yFlag = mission.yFlag
    msg.params = mission.params
    self:get_scene():send2client(self, msg)
end

function human:set_mission_event(mission_id, event)
    local index = self:get_mission_index(mission_id)
    if index == define.INVAILD_ID then
        return define.OPERATE_RESULT.OR_ERROR
    end
    local mission = self.mission_data.char_missions[index]
    if mission == nil then
        return define.OPERATE_RESULT.OR_ERROR
    end
    if event == define.TASK_EVENT.TASK_EVENT_KILLOBJ then
        mission.yFlag = mission.yFlag | 0x1 << 0
    elseif event == define.TASK_EVENT.TASK_EVENT_ENTERAREA then
        mission.yFlag = mission.yFlag | 0x1 << 1
    elseif event == define.TASK_EVENT.TASK_EVENT_ITEMCHANGED then
        mission.yFlag = mission.yFlag | 0x1 << 2
    elseif event == define.TASK_EVENT.TASK_EVENT_PETCHANGED then
        mission.yFlag = mission.yFlag | 0x1 << 3
    elseif event == define.TASK_EVENT.TASK_EVENT_LOCKTARGET then
        mission.yFlag = mission.yFlag | 0x1 << 4
    end
end

function human:is_mission_full()
    return #self.mission_data.char_missions >= define.MAX_CHAR_MISSION_NUM
end

function human:is_mission_have_done(id_mission)
    local index = (id_mission >> 5)  + 1
    assert(index <= define.MAX_CHAR_MISSION_FLAG_LEN, index)
    if index <= define.MAX_CHAR_MISSION_FLAG_LEN then
        local flag = self.mission_data.mission_have_done_flags[index] or 0
        return ( flag & (0x00000001 << (id_mission & 0x0000001F))) ~= 0
    else
        return false
    end
end

function human:set_mission_have_done(id_mission, done)
    local index = (id_mission >> 5)  + 1
    assert(index <= define.MAX_CHAR_MISSION_FLAG_LEN, index)
    if index <= define.MAX_CHAR_MISSION_FLAG_LEN then
        if done then
            self.mission_data.mission_have_done_flags[index] = (self.mission_data.mission_have_done_flags[index] or 0) | (0x00000001 << (id_mission & 0x0000001F))
        else
            self.mission_data.mission_have_done_flags[index] = (self.mission_data.mission_have_done_flags[index] or 0) & (0x00000000 << (id_mission & 0x0000001F))
        end
    end
    local msg = packet_def.GCMissionHaveDoneFlag.new()
    msg.mission_id = id_mission
    msg.flag = done and 1 or 0
    self:get_scene():send2client(self, msg)
end

function human:get_mission_have_done(id_mission)
    local index = (id_mission >> 5)  + 1
    assert(index <= define.MAX_CHAR_MISSION_FLAG_LEN, index)
    if index <= define.MAX_CHAR_MISSION_FLAG_LEN then
        local value = self.mission_data.mission_have_done_flags[index] or 0
        local bit = (0x00000001 << (id_mission & 0x0000001F))
        return (value & bit) == bit
    end
    return false
end

function human:get_mission_count()
    return #self.mission_data.char_missions
end

function human:on_kill_object(obj)
    assert(self.scene:get_obj_by_id(obj:get_obj_id()), obj:get_obj_id())
    if obj:get_obj_type() ~= "monster" then
        return
    end
    -- [2026-09-17] CYS: ban sao nguoi choi da roi canh van co the con trong AOI cua quai,
    -- caculate_owner_list se goi on_kill_object tren ban sao do. Luc ay scene.objs[obj_id]
    -- da nil nen moi hook (791010, nhiem vu) doc obj nil. Bo qua va ghi log mot lan.
    local cys_my_id = self:get_obj_id()
    if not cys_my_id or self.scene:get_obj_by_id(cys_my_id) ~= self then
        if not self._kill_stale_logged then
            self._kill_stale_logged = true
            local ok_guid, my_guid = pcall(self.get_guid, self)
            skynet.logw("[KILL_STALE] bo qua on_kill_object: obj nguoi choi khong con trong canh",
                " obj_id=", tostring(cys_my_id),
                " guid=", tostring(ok_guid and my_guid or "?"),
                " scene=", tostring(self.scene:get_id()),
                " detached=", tostring(self._scene_detached),
                " leaving=", tostring(self._leaving),
                " monster=", tostring(obj:get_model()))
        end
        return
    end
    -- [2026-09-11] Phong Hon Luc (791010): dem so quai da giet
    do
        local se = self:get_scene() and self:get_scene():get_script_engienr()
        if se and se:have_function(791010, "OnKillMonster") then
            se:call(791010, "OnKillMonster", self:get_obj_id(), obj:get_model())
        end
    end
    for _, mission in ipairs(self.mission_data.char_missions) do
        if mission.yFlag & 0x1 == 0x1 then
            local toggle = obj.misions_toggle[mission.id] == nil
            if toggle then
                obj.misions_toggle[mission.id] = true
                local script = mission.index
                self:get_scene():get_script_engienr():call(script, "OnKillObject", self:get_obj_id(), obj:get_model(), obj:get_obj_id())
            end
        end
    end
end

function human:on_pick_up_item(item, bag_index)
    for _, mission in ipairs(self.mission_data.char_missions) do
        local script = mission.index
        self:get_scene():get_script_engienr():call(script, "PickupItem", self:get_obj_id(), item:get_index(), bag_index)
    end
end

function human:on_add_pet(pet)
    for _, mission in ipairs(self.mission_data.char_missions) do
        if mission.yFlag & (0x1 << 3) == (0x1 << 3) then
            local script = mission.index
            self:get_scene():get_script_engienr():call(script, "OnPetChanged", self:get_obj_id(), pet:get_data_index())
        end
    end
end

function human:on_lock_target(target_id)
    --[[
    local obj_tar = self:get_scene():get_obj_by_id(target_id)
    if obj_tar and obj_tar:get_obj_type() ~= "human" then
        if target_id ~= define.INVAILD_ID then
            for _, mission in ipairs(self.mission_data.char_missions) do
                if mission.yFlag & (0x1 << 4) == (0x1 << 4) then
                    local script = mission.index
                    self:get_scene():get_script_engienr():call(script, "OnLockedTarget", self:get_obj_id(), target_id)
                end
            end
        end
    end]]
end

function human:get_copy_scene_sn()
    local restore = self.db:get_attrib("restore_scene_and_pos") or {}
    return restore.sn
end

function human:reset_mission_cache_data()
    self.mission_cache_data = {}
end

function human:set_mission_cache_data(id, val)
    self.mission_cache_data[id] = val
end

function human:get_mission_cache_data(id)
    return self.mission_cache_data[id]
end

function human:capture_pet(logparam, pet)
    if pet:get_owner() then
        self:send_operate_result_msg(define.OPERATE_RESULT.OR_INVALID_TARGET)
        return false
    end
    -- CYS-PET 17/09/2026: chot y het nhanh TRUNG (script_base:TryCreatePet). Khong co chot thi
    -- add_pet nem assert va lam hong ca scene. Tu choi EM: bao nguoi choi + ma loi, skill_10 se
    -- gui GCManipulatePetRet ret = MANIPULATEPET_RET_CAPTUREFALID.
    if self:get_pet_bag_container():cal_item_space() < 1 then
        self:notify_tips("Túi Trân thú đã đầy, không thể thu phục thêm.")
        self:send_operate_result_msg(define.OPERATE_RESULT.OR_BAG_OUT_OF_SPACE)
        return false
    end
    local result = petmanager:create_guid_of_pet(self, pet)
    if not result then
        return false
    end
    result = self:add_pet(pet:get_detail())
    if not result then
        return false
    end
    return true
end

function human:get_shop_guids()
    return self.shop_guids
end

function human:set_shop_guid(index, shg)
    self.shop_guids = self.shop_guids or {}
    local sg = shop_guid.new()
    sg:set(shg)
    self.shop_guids[index] = sg
end

function human:set_char_shop_guids(sgs)
    for i = 1, 2 do
        local sg = sgs[i]
        self:set_shop_guid(i, sg or shop_guid.new())
    end
end

function human:get_shop_guid_by_index(index)
    return self.shop_guids[index]
end

function human:check_have_id_title(id)
    for _, title in ipairs(self.id_titles) do
        if title.id == id then
            return true
        end
    end
    return false
end

function human:get_id_titles()
    return self.id_titles
end

function human:del_conflict_titles(new_id)
    local char_title_new = configenginer:get_config("char_title_new")
    local new_title = char_title_new[new_id]
    for i = #self.id_titles, 1, -1 do
        local id = self.id_titles[i].id
        local title = char_title_new[id]
        if title then
            if new_title["Type"] == title["Type"] then
                table.remove(self.id_titles, i)
            end
        end
    end
end

function human:add_id_title(id)
    local config=configenginer:get_config('char_title_new')
    if not config or not config[id] or self:have_id_title(id) then return false end
    self:del_conflict_titles(id)
    table.insert(self.id_titles,{id=id})
    self.db:mark_all_attr_dirty()
    self:set_cur_title_by_id_title(id)
    self:update_titles_to_client()
    return true
end

function human:have_id_title(id)
    for i = #self.id_titles, 1, -1 do
        if self.id_titles[i].id == id then
            return true
        end
    end
    return false
end

function human:set_title(id,titlestr)
    if id==define.INVAILD_ID or type(titlestr)~='string' then return false end
    for _,title in ipairs(self.titles)do
        if title.id==id then title.str=titlestr;self:set_current_title(title);self:update_titles_to_client();return true end
    end
    local title={id=id,str=titlestr}
    table.insert(self.titles,title)
    self:set_current_title(title)
    self:update_titles_to_client()
    return true
end

function human:set_current_title(title)
    self.db:set_db_attrib({ title = title})
end

function human:get_current_title()
    return self.db:get_db_attrib("title")
end

function human:get_title_by_id(id)
    for _, title in ipairs(self.titles) do
        if title.id == id then
            return title
        end
    end
end

function human:set_cur_title_by_id(id)
    local title = self:get_title_by_id(id)
    if title then
        self:set_current_title(title)
    end
end

function human:set_cur_title_by_id_title(id)
    if self:check_have_id_title(id) then
        local char_title_new = configenginer:get_config("char_title_new")
        char_title_new = char_title_new and char_title_new[id]
        if not char_title_new then return false end
        local title = { str = string.format("#%d", id), new_title_id = id, id = char_title_new["Type"]}
        self:set_current_title(title)
    end
end

function human:get_cur_title()
    local title = self.db:get_db_attrib("title")
    return title
end

function human:update_titles_to_client()
    local msg = packet_def.GCCharAllTitles.new()
    msg.m_objID = self:get_obj_id()
    msg.m_nTitleId = #self.id_titles
    msg.m_TitleIdList = self.id_titles
    msg.m_nTitleStr = #self.titles
    msg.m_TitleStrList = self.titles
    self:get_scene():send2client(self, msg)
end

function human:up_xinfa_level(level)
    local xinfa_list = self:get_xinfa_list()
    for _, xinfa in ipairs(xinfa_list) do
        self:study_xinfa(xinfa.m_nXinFaID, level)
        local msg = packet_def.GCStudyXinfa.new()
        msg.spare_exp = self:get_attrib("exp")
        msg.spare_money = self:get_attrib("money")
        msg.now_level = level
        msg.xinfa = xinfa.m_nXinFaID
        self:get_scene():send2client(self, msg)
    end
end

function human:get_min_xinfa_level()
    local xinfa_list = self:get_xinfa_list()
    local menpai = self:get_menpai()
    xinfa_list = table.clone(xinfa_list)
    for i = #xinfa_list, 1, -1 do
        local xinfa = xinfa_list[i]
        if xinfa.m_nXinFaID == define.MENPAI_7_XINFA[menpai] or xinfa.m_nXinFaID == define.MENPAI_8_XINFA[menpai] then
            table.remove(xinfa_list, i)
        end
    end
    table.sort(xinfa_list, function(x1, x2) return x1.m_nXinFaLevel < x2.m_nXinFaLevel end )
    if #xinfa_list > 0 then
        return xinfa_list[1].m_nXinFaLevel
    end
    return 0
end

function human:fix_xiulian_list()
    self.xiulian_list=require("cys_xiulian").init(self.xiulian_list)
end

function human:get_xiulian_list()
    return self.xiulian_list
end

function human:get_xiulian_level(index)
    local xiulian = self.xiulian_list[index]
    assert(xiulian, index)
    return xiulian.level
end

function human:get_max_level_xiulian_level()
    local max_level
    for _, xiulian in pairs(self.xiulian_list) do
        if max_level == nil or max_level < xiulian.level then
            max_level = xiulian.level
        end
    end
    return max_level // 10 + 1
end

function human:get_xiulian_upper_limit(index)
    local xiulian = self.xiulian_list[index]
    assert(xiulian, index)
    return xiulian.upper_limit
end

function human:xiulian_can_level_up(index)
    local level = self:get_xiulian_level(index)
    local upper_limit = self:get_xiulian_upper_limit(index)
    return level < upper_limit
end

function human:xiulian_level_up(index)
    local xiulian = self.xiulian_list[index]
    assert(xiulian, index)
    xiulian.level = xiulian.level + 1
    self:send_xiulian_list()
    self:item_flush()
end

function human:xiulian_upper_limit_up(index, count)
    local xiulian = self.xiulian_list[index]
    assert(xiulian, index)
    xiulian.upper_limit = xiulian.upper_limit + count
    self:send_xiulian_list()
end

function human:send_xiulian_list()
    local ret = packet_def.GCDetailXiulianList.new()
    ret.unknow_2 = 54
    ret.xiulian = self:get_xiulian_list()
    self:get_scene():send2client(self, ret)
end

function human:reset_talent(show_type)
    local r, err = pcall(self.talent_on_remove, self)
    if not r then
        skynet.loge("talent_on_remove error =", err)
    end
    local talent = self:get_talent()
    talent.type = define.INVAILD_ID
    talent.study = {}
    for i = 1, 21 do
        talent.study[i] = { id = define.INVAILD_ID, level = 0 }
    end
    talent.study[1].id = define.INVAILD_ID
    talent.study[1].level = 1
    talent.understand_point = talent.understand_point + (talent.cost_point or 0)
    talent.cost_point = 0
	for i = define.MD_WDDAO_FOUR_1,define.MD_WDDAO_FOUR_4 do
		self:set_mission_data_by_script_id(i,0)
	end
    self:send_talent(show_type or 0)
end

function human:send_talent(show_type)
    show_type = show_type or 2
    local talent = self:get_talent()
    local msg = packet_def.GCSectDetail.new()
    msg.list = talent.study
    msg.understand_point = talent.understand_point
    msg.show_type = show_type
    msg.talent_type = talent.type
    self:get_scene():send2client(self, msg)
end

function human:check_can_study_sect(talent_id)
    local sect_info = configenginer:get_config("sect_info")
    sect_info = sect_info[talent_id]
	if not sect_info then
		self:notify_tips("武道技能不存在")
		return false
	end
    local study = self:find_study_talent(talent_id)
    study = study or { id = talent_id, level = 0 }
    if study.level == sect_info["最大等级"] then
        self:notify_tips("已点满")
        return false
    end
    local cost_point = sect_info["消耗"][study.level + 1]
    local talent = self:get_talent()
    if talent.understand_point < cost_point then
        self:notify_tips("武道领悟点不足")
        return false
    end
    if not self:check_can_study_pre_talent(talent_id) then
        self:notify_tips("需先学习前置武道")
        return false
    end
    if not self:check_talent_level(talent_id) then
        self:notify_tips("武道修行等级不足")
        return false
    end
    if not self:check_talent_conflict(talent_id) then
        self:notify_tips("不可同时修行")
        return false
    end
    return true
end

function human:check_talent_conflict(talent_id)
    local talent = self:get_talent()
    local sect_info = configenginer:get_config("sect_info")
    local cur_sect_info = sect_info[talent_id]
    local cur_layer = cur_sect_info["Layer"]
    for i, study in ipairs(talent.study) do
        local sect = sect_info[study.id]
        if study.id ~= talent_id and study.id ~= define.INVAILD_ID then
            local study_layer = sect["Layer"]
            if study_layer == cur_layer then
                return false
            end
        end
    end
    return true
end

function human:check_talent_level(talent_id)
    local talent = self:get_talent()
    local sect_info = configenginer:get_config("sect_info")
    sect_info = sect_info[talent_id]
    local level_require = sect_info["LevelRequire"]
    local cur_level = self:get_talent_level()
    return cur_level >= level_require
end

function human:check_can_study_pre_talent(talent_id)
    local talent = self:get_talent()
    local sect_info = configenginer:get_config("sect_info")
    sect_info = sect_info[talent_id]
    local pre_talent_id = sect_info["PreTalent"]
    local pre_talent_level = sect_info["PreTalentLevel"]
    local study = self:find_study_talent(pre_talent_id)
    study = study or { id = talent_id, level = 0 }
    if study.level < pre_talent_level then
        return false
    end
    return true
end

function human:study_sect(talent_id)
    if not self:check_can_study_sect(talent_id) then
        return
    end
    local talent = self:get_talent()
    local study = self:get_study_talent(talent_id)
    local sect_info = configenginer:get_config("sect_info")
    sect_info = sect_info[talent_id]
    local cost_point = sect_info["消耗"][study.level + 1]
    talent.understand_point = talent.understand_point - cost_point
    talent.cost_point = (talent.cost_point or 0) + cost_point
    study.level = study.level + 1
	
	if sect_info.Layer > 13 then
		local md_id = sect_info.Layer - 14 + define.MD_WDDAO_FOUR_1
		self:set_mission_data_by_script_id(md_id,talent_id * 10 + study.level)
	end

    -- 学习天赋后立即激活，使 on_active 中的技能授予等逻辑即时生效
    local r, err = pcall(function()
        local logic = talentenginer:get_logic(study)
        if logic then
            local talent_config = configenginer:get_config("sect_desc")
            talent_config = talent_config[talent_id]
            if talent_config then
                logic:on_active(talent_config, study.level, self)
            end
        end
    end)
    if not r then
        skynet.loge("study_sect on_active error =", err)
    end

    self:send_talent(0)
	local selfId = self:get_obj_id()
	self:show_buff_effect(selfId,selfId,-1,self:get_logic_count(),49)
end

function human:get_study_talent(talent_id)
    local talent = self:get_talent()
    for _, study in ipairs(talent.study) do
        if study.id == talent_id then
            return study
        elseif study.id == define.INVAILD_ID then
            study.id = talent_id
            return study
        end
    end
end

function human:find_study_talent(talent_id)
    local talent = self:get_talent()
    for _, study in ipairs(talent.study) do
        if study.id == talent_id then
            return study
        end
    end
end

function human:get_talent_level()
    local level = 0
    local talent = self:get_talent()
    for i, study in ipairs(talent.study) do
        if i ~= 1 then
            level = level + study.level
        end
    end
    return level
end

function human:get_talent_level_by_id(talent_id)
    local talent = self:get_talent()
    for _, study in ipairs(talent.study) do
        if study.id == talent_id then
            return study.level
        end
    end
    return 0
end

function human:get_gong_li()
    local gongli = self.db:get_db_attrib("gongli")
    if gongli == nil then
        gongli = 100
        self:set_gong_li(gongli)
    end
    return gongli
end

function human:set_gong_li(gongli)
    self.db:set_db_attrib({ gongli = gongli})
end

function human:cost_gong_li(count)
    local gongli = self:get_gong_li()
    gongli = gongli - count
    gongli = gongli < 0 and 0 or gongli
    self:set_gong_li(gongli)
end

function human:on_team_id_changed()
    self:update_character_view()
end

function human:on_raid_id_changed()
    self:update_character_view()
end

function human:on_detect_level_changed()
    self:update_character_view()
end

function human:get_sweep_count(index)
    return self.dungeonsweep.sweep_counts[tostring(index)] or 0
end

function human:get_sweep_counts()
    return self.dungeonsweep.sweep_counts
end

function human:send_sweep_count()
    local msg = packet_def.GCRetSecKillNum.new()
    msg.list = self:get_sweep_counts()
    self:get_scene():send2client(self, msg)
end

function human:add_sweep_count(index, count)
    index = math.floor(tonumber(index) or 0)
    count = math.max(0, math.floor(tonumber(count) or 0))
    if index < 1 or count <= 0 then
        return false
    end
    local sweep_count = self:get_sweep_count(index)
    local limit = index >= 1 and index <= 6 and 120 or 80
    self.dungeonsweep.sweep_counts[tostring(index)] = math.min(limit, sweep_count + count)
    self:send_sweep_count()
    return true
end

function human:cost_sweep_count(index, count)
    count = math.max(0, math.floor(tonumber(count) or 0))
    local sweep_count = self:get_sweep_count(index)
    if count <= 0 or sweep_count < count then
        return false
    end
    self.dungeonsweep.sweep_counts[tostring(index)] = sweep_count - count
    self:send_sweep_count()
    return true
end

function human:set_sweep_point(index, count)
    count = math.max(0, math.floor(tonumber(count) or 0))
    self.dungeonsweep.sweep_counts[tostring(index)] = count
end

function human:set_sec_kill_data(data)
    data = data or { item_list = {} }
    data.item_list = data.item_list or {}
    self.dungeonsweep.sec_kill_data = data
    self:send_sec_kill_data()
end

function human:send_sec_kill_data()
    local sec_kill_data = self.dungeonsweep.sec_kill_data or { item_list = {} }
    local msg = packet_def.GCRetSecKillData.new()
    msg.fuben_index = sec_kill_data.fuben_index
    msg.boss_id = sec_kill_data.boss_id
    msg.have_next = sec_kill_data.have_next
    msg.item_list = sec_kill_data.item_list
    self:get_scene():send2client(self, msg)
end

function human:get_sec_kill_item_by_index(index)
    local item_list = self.dungeonsweep.sec_kill_data.item_list or {}
    for _, item in ipairs(item_list) do
        if item.index == index then
            return item
        end
    end
end

function human:get_sec_kill_item_count()
    local item_list = self.dungeonsweep.sec_kill_data.item_list or {}
    return #item_list
end

function human:get_sec_kill_item_by_i(i)
    local item_list = self.dungeonsweep.sec_kill_data.item_list or {}
    return item_list[i]
end

function human:remove_sec_kill_item(index, is_discard)
    local item_list = self.dungeonsweep.sec_kill_data.item_list or {}
    local removed = false
    for i, item in ipairs(item_list) do
        if item.index == index then
            table.remove(item_list, i)
            removed = true
            break
        end
    end
    if not removed then
        return false
    end
    local msg = packet_def.GCSecKillRemoveItem.new()
    msg.is_discard = is_discard
    msg.index = index
    self:get_scene():send2client(self, msg)
    if #item_list == 0 and self.dungeonsweep.sec_kill_data.have_next ~= 1 then
        self.dungeonsweep.sec_kill_data = { item_list = {} }
        self:send_sec_kill_data()
    end
    return true
end

function human:remove_all_sec_kill_item()
    local data = self.dungeonsweep.sec_kill_data or {}
    data.item_list = {}
    if data.have_next == 1 then
        self.dungeonsweep.sec_kill_data = data
    else
        self.dungeonsweep.sec_kill_data = { item_list = {} }
    end
    self:send_sec_kill_data()
end

function human:get_campaign_count(index)
    return self.dungeonsweep.campaign_counts[tostring(index)] or 0
end

function human:get_campaign_counts()
    return self.dungeonsweep.campaign_counts
end

function human:set_campaign_count(index, count)
    self.dungeonsweep.campaign_counts[tostring(index)] = count
    self:send_campaign_count()
end

function human:reset_campaign_count()
    self.dungeonsweep.campaign_counts = {}
end

function human:get_pk_value()
    return self.db:get_db_attrib("pk_value") or 0
end

function human:set_pk_value(value)
    value = value > define.INT32_MAX and define.INT32_MAX or value
    self.db:set_db_attrib({pk_value = value})
end

function human:send_campaign_count()
    local msg = packet_def.GCRetCampaignCount.new()
    msg.list_1 = self:get_campaign_counts()
    msg.list_2 = {}
    msg.list_3 = {}
    msg.unknow_1 = 3
    self:get_scene():send2client(self, msg)
end

function human:send_week_active()
    local msg = packet_def.GCZhouHuoYueInfo.new()
    msg.can_get = self.week_active.can_get
    msg.getd = self.week_active.getd
    msg.day_get = self.week_active.day_get
    msg.week_get = self.week_active.week_get
    msg.get_award_index = self.week_active.get_award_index
    msg.level = self:get_level()
    msg.unknow_4 = 0
    self:get_scene():send2client(self, msg)
end

function human:get_week_active()
    return self.week_active
end

function human:get_week_active_day()
    return self.week_active.day_get
end

function human:send_cool_down_time()
    local cool_down_times = self.cool_down_times or {}
    local cool_down_times_array = {}
	local index
    for id, time in pairs(cool_down_times) do
		index = tonumber(id)
		if index < define.OTHER_SKILL_OR_STATUS_COOLDOWN then
			table.insert(cool_down_times_array, { m_nID = index, m_nCooldown = time, m_nCooldownElapsed = 0})
		end
	end
	if #cool_down_times_array > 0 then
		local msg = packet_def.GCCooldownUpdate.new()
		msg.m_nNumCooldown = #cool_down_times_array
		msg.m_aCooldowns = cool_down_times_array
		self:get_scene():send2client(self, msg)
	end
end

function human:challenge_refresh_skill_cool_down()
    self.challenge_store_skill_cool_down = table.clone(self.cool_down_times)
    local cool_down_times_array = {}
    self.cool_down_times = {}
	local index
    for id, time in pairs(self.challenge_store_skill_cool_down) do
		index = tonumber(id)
		if index < define.OTHER_SKILL_OR_STATUS_COOLDOWN then
			if time > 0 then
				table.insert(cool_down_times_array, { m_nID = index, m_nCooldown = 0, m_nCooldownElapsed = 0})
			end
		end
    end
	if #cool_down_times_array > 0 then
		local msg = packet_def.GCCooldownUpdate.new()
		msg.m_nNumCooldown = #cool_down_times_array
		msg.m_aCooldowns = cool_down_times_array
		self:get_scene():send2client(self, msg)
	end
end

function human:challenge_restore_skill_cool_down()
    if self.challenge_store_skill_cool_down then
        local cool_down_times_array = {}
		local index
        for id, time in pairs(self.cool_down_times) do
            if time > 0 then
                if self.challenge_store_skill_cool_down[id] == nil then
					index = tonumber(id)
					if index < define.OTHER_SKILL_OR_STATUS_COOLDOWN then
						table.insert(cool_down_times_array, { m_nID = index, m_nCooldown = 0, m_nCooldownElapsed = 0})
                    end
					self.cool_down_times[id] = 0
                end
            end
        end
        for id, time in pairs(self.challenge_store_skill_cool_down) do
            if time > 0 then
				index = tonumber(id)
				if index < define.OTHER_SKILL_OR_STATUS_COOLDOWN then
					table.insert(cool_down_times_array, { m_nID = index, m_nCooldown = time, m_nCooldownElapsed = 0})
                end
				self.cool_down_times[id] = time
            end
        end
		if #cool_down_times_array > 0 then
			local msg = packet_def.GCCooldownUpdate.new()
			msg.m_nNumCooldown = #cool_down_times_array
			msg.m_aCooldowns = cool_down_times_array
			self:get_scene():send2client(self, msg)
			self.challenge_store_skill_cool_down = nil
		end
    end
end

function human:talent_on_hit_target(reciver, skill_id)
	local talent_config = configenginer:get_config("sect_desc")
    local talent = self:get_talent()
    for i = 1, #talent.study do
        local study_talent = talent.study[i]
        local logic = talentenginer:get_logic(study_talent)
        --skynet.error("[DEBUG:talent_on_hit_target] i=", i, " talent_id=", study_talent.id, " level=", study_talent.level, " has_logic=", logic and "yes" or "no")
        if logic then
            local talents = talent_config[study_talent.id]
            if talents then
                local level = study_talent.level
                level = level == 0 and 1 or level
                logic:on_hit_target(talents, level, self, reciver, skill_id)
            end
        end
    end
end

function human:talent_on_damage_target(target, damages, skill_id, imp)
    if skill_id and target then
		local talent_config = configenginer:get_config("sect_desc")
        local talent = self:get_talent()
        for i = 1, #talent.study do
            local study_talent = talent.study[i]
            local logic = talentenginer:get_logic(study_talent)
            if logic then
                local talents = talent_config[study_talent.id]
                if talents then
                    local level = study_talent.level
                    level = level == 0 and 1 or level
                    logic:on_damage_target(talents, level, study_talent.id, self, target, damages, skill_id, imp)
                end
            end
        end
    end
end

function human:talent_study_sect(talent_id)
	local talent_config = configenginer:get_config("sect_desc")
	local talent = self:get_talent()
	for i = 1, #talent.study do
		local study_talent = talent.study[i]
		if study_talent.id == talent_id then
			local logic = talentenginer:get_logic_id(talent_id)
			if logic then
				local talents = talent_config[talent_id]
				if talents then
					local level = study_talent.level
					level = level == 0 and 1 or level
					logic:study_sect(talents, level, talent_id, self)
				end
			end
		end
	end
end

function human:update_kill_monster_count(count)
    local today_kill_monster_count = self:get_today_kill_monster_count()
    today_kill_monster_count = today_kill_monster_count + count
    self:on_today_kill_monster_count_change(today_kill_monster_count)
    self.db:set_db_attrib({ today_kill_monster_count = today_kill_monster_count })
end

function human:on_today_kill_monster_count_change(count)
	local env = skynet.getenv("env")
	local value = define.HEAVY_ANTI_ADDICTION_KILL_MONSTER_COUNT[env] or define.HEAVY_ANTI_ADDICTION_KILL_MONSTER_COUNT["moren"]
	if count >= value then
		self:notify_tips("#{MPCG_191029_304}")
		return
	end
	local value2 = define.MILD_ANTI_ADDICTION_KILL_MONSTER_COUNT[env] or define.MILD_ANTI_ADDICTION_KILL_MONSTER_COUNT["moren"]
	if count >= value2 then
		local msg = string.format("杀怪数大于%d时将进入沉迷状态，收益减半；杀怪数大于%d时将进入严重沉迷状态，无法获得任何收益。",value2,value)
		self:notify_tips(msg)
		return
	end
end

function human:get_today_kill_monster_count()
    return self.db:get_attrib("today_kill_monster_count") or 0
end

function human:set_today_kill_monster_count(count)
    self:on_today_kill_monster_count_change(count)
    count = count > define.UINT32_MAX and define.UINT32_MAX or count
    self.db:set_db_attrib({ today_kill_monster_count = count })
end

function human:can_be_dispatch_item_box()
	local env = skynet.getenv("env")
	local count = define.MILD_ANTI_ADDICTION_KILL_MONSTER_COUNT[env] or define.MILD_ANTI_ADDICTION_KILL_MONSTER_COUNT["moren"]
    return self:get_today_kill_monster_count() < count
end

function human:get_vigor()
    return self.db:get_db_attrib("vigor") or 0
end

function human:set_vigor(vigor)
    self.db:set_db_attrib({ vigor = vigor})
end

function human:get_vigor_max()
    return self.db:get_db_attrib("vigor_max") or 0
end

function human:get_stamina()
    return self.db:get_db_attrib("stamina") or 0
end

function human:set_stamina(stamina)
    self.db:set_db_attrib({ stamina = stamina})
end

function human:get_stamina_max()
    return self.db:get_db_attrib("stamina_max") or 0
end

function human:can_change_menpai(menpai)
    local get_config = function(name) return configenginer:get_config(name) end
    local ready, reason = menpai_registry.check_ready(define, menpai, get_config)
    if not ready then return false, reason end
    local source = self:get_menpai()
    if not menpai_registry.is_legacy(menpai) or (type(source) == "number" and not menpai_registry.is_legacy(source)) then -- CS3b
        local plan, plan_reason = menpai_registry.plan_transition(define, source, menpai,
            self:get_xinfa_list(), self:get_skill_list(), get_config)
        if not plan then return false, plan_reason end
        return true, reason, plan
    end
    return true, reason
end

function human:change_menpai(menpai)
    -- Validate and build extension lists before touching any player state.
    local ready, reason, plan = self:can_change_menpai(menpai)
    if not ready then return false, reason end
    if plan then
        self.xinfa_list = plan.xinfa_list
        self.skill_list = plan.skill_list
    else
        self:change_menpai_change_xinfa(menpai)
        self:change_menpai_change_skills(menpai)
    end
    self:change_menpai_abilitys(menpai)
    self:reset_talent(2)
    self.db:set_db_attrib({ menpai = menpai })
    -- 同步 reputation，与 set_menpai() 保持一致
    local reputation = define.MENPAI_REPUTATIONS[menpai]
    if reputation then
        self.db:set_db_attrib({reputation = reputation})
    end
    self:change_menpai_points()
    self:item_flush()
    self:set_hp(self:get_max_hp())
    self:set_mp(self:get_max_mp())
    self:send_refresh_attrib()
    self:send_xinfa_list()
    self:send_skill_list()
    self:send_ability_list()
    local owned_skills = {}
    for _, skill in ipairs(self.skill_list) do
        owned_skills[skill] = true
    end

    local quick_start = define.SETTING_TYPE.SETTING_TYPE_K1
    local quick_stop = define.SETTING_TYPE.SETTING_TYPE_K9
    for i = quick_start, quick_stop do
        local key = tostring(i)
        local setting = self.setting[key]
        if setting and setting.type == 1 and not owned_skills[setting.data] then
            self.setting[key] = nil
        end
    end

    local default_quick_skills = {}
    for _, skill in ipairs(self.skill_list) do
        local template = skillenginer:get_skill_template(skill)
        if template and template.direct_study_up
            and template.target_logic_by_stand == 1
            and not template.is_passive
            and template.xinfa ~= define.INVAILD_ID
            and template.xinfa_level_require <= 1 then
            table.insert(default_quick_skills, skill)
        end
    end
    table.sort(default_quick_skills)
    local protected_settings = {}
    for i = 1, math.min(2, #default_quick_skills) do
        local key = tostring(quick_start + i - 1)
        local skill = default_quick_skills[i]
        self:modify_setting(key, skill)
        protected_settings[key] = skill
    end
    self.menpai_quick_setting_guard = {
        expires_at = skynet.now() + 300,
        skills = protected_settings,
    }
    self:send_setting()
    return true
end

function human:change_menpai_change_xinfa(target_menpai)
    local xinfa_v1 = configenginer:get_config("xinfa_v1")
    local menpai = self:get_menpai()
    local xinfa_levels = {}
    for _, id in ipairs(menpai_registry.xinfa_ids(xinfa_v1, menpai)) do
        local v1 = xinfa_v1[id]
        if v1.menpai == menpai then
            local xinfa = self:get_xinfa(id)
            if xinfa then
                table.insert(xinfa_levels, xinfa.m_nXinFaLevel)
            end
        end
    end
    self.xinfa_list = {}
    for _, id in ipairs(menpai_registry.xinfa_ids(xinfa_v1, target_menpai)) do
        local v1 = xinfa_v1[id]
        if v1.menpai == target_menpai then
            if #xinfa_levels > 0 then
                local xinfa = { m_nXinFaID = id , m_nXinFaLevel = table.remove(xinfa_levels, 1) }
                table.insert(self.xinfa_list, xinfa)
            end
        end
    end
end

function human:change_menpai_change_skills(target_menpai)
    local menpai = self:get_menpai()
    local menpai_7_skills = define.MENPAI_7_SKILLS[menpai]
    local convert_qinggong_skill = false
    local skills_7 = {}
    for i = #self.skill_list, 1, -1 do
        local skill = self.skill_list[i]
        local template = skillenginer:get_skill_template(skill)
        if template.menpai == menpai then
            local skill_7_index = menpai_7_skills[skill]
            if skill_7_index then
                skills_7[skill_7_index] = true
            else
                table.remove(self.skill_list, i) 
                if skill == define.QINGGONG_SKILL[menpai] then
                    convert_qinggong_skill = true
                end
            end
        end
    end
    local target_menpai_7_skills = define.MENPAI_7_SKILLS[target_menpai]
    local convert_target_menpai_7_skills = {}
    for skill, index in pairs(target_menpai_7_skills) do
        convert_target_menpai_7_skills[index] = skill
    end
    for i, xinfa in ipairs(self.xinfa_list) do
        if i == 7 then
            for i = 1, 3 do
                if skills_7[i] then
                    self:add_skill(convert_target_menpai_7_skills[i])
                end
            end
        else
            local id = xinfa.m_nXinFaID
            local level = xinfa.m_nXinFaLevel
            self:on_study_xinfa(id, level)
        end
    end
    if convert_qinggong_skill then
        local skill = define.QINGGONG_SKILL[target_menpai]
        self:add_skill(skill)
    end
    table.sort(self.skill_list, function(sk1, sk2)
        return sk1 < sk2
    end)
    local yuangong_skill = define.MENPAI_JINZHAN_YUANGONG_SKILL[target_menpai]
    if yuangong_skill then
        self:add_skill(yuangong_skill)
    end
end

function human:change_menpai_abilitys(target_menpai)
    local menpai = self:get_menpai()
    local ABILITYS = define.MENPAI_ABILITYS[menpai]
    if ABILITYS then
        for i, id in ipairs(ABILITYS) do
            local ability = self:get_ability(id)
            if ability then
                ability.id = define.MENPAI_ABILITYS[target_menpai][i]
            end
        end
    end
end

function human:get_relation_info()
    return skynet.call(self:get_agent(), "lua", "get_relation_list")
end

function human:set_relation_info(realtion_list)
    self.relation_list = relation_list
    skynet.send(self:get_agent(), "lua", "set_realtion_list", realtion_list)
end

function human:set_relation_list_from_agent(relation_list)
    self.relation_list = relation_list
end

function human:relation_on_be_human_kill(killer)
    local agent = self:get_agent()
    skynet.send(agent, "lua", "relation_on_be_human_kill", killer:get_name())
end

function human:check_right_limit_exchange()
    local agent = self:get_agent()
    return skynet.call(agent, "lua", "check_right_limit_exchange")
end

function human:set_agree_swear_list(otherId)
    self.agree_swear_list = self.agree_swear_list or {}
    self.agree_swear_list[otherId] = true
end

function human:get_agree_swear_list()
    return self.agree_swear_list or {}
end

function human:get_master_level()
    return self.db:get_db_attrib("master_level") or 0
end

function human:set_master_level(master_level)
    self.db:set_db_attrib({ master_level = master_level})    
end

function human:get_prentice_supply_exp()
    return self.db:get_db_attrib("prentice_supply_exp") or 0
end

function human:add_prentice_pro_exp(add_exp)
    local exp = self:get_prentice_supply_exp()
    exp = exp + add_exp
    self.db:set_db_attrib({ prentice_supply_exp = exp })
end

function human:get_good_bad_value()
    return self.db:get_db_attrib("good_bad_value") or 0
end

function human:set_good_bad_value(value)
    value = math.floor(value)
    self.db:set_db_attrib({ good_bad_value = value})
end

function human:get_master_moral_point()
    return self.db:get_db_attrib("master_moral_point") or 0
end

function human:set_jiebai_name(jiebai_name)
    self.db:set_db_attrib({ jiebai_name = jiebai_name})
end

function human:get_jiebai_name()
    return self.db:get_db_attrib("jiebai_name") or ""
end

function human:set_meng_hui(meng_hui)
    if meng_hui > 0 and meng_hui < 5 then
        self.db:set_not_gen_attrib({menghui = meng_hui})
    end
end

function human:get_meng_hui()
    return self.db:get_attrib("menghui") or 0
end

function human:set_marry_info(marry_target_guid, is_accept)
    self.marry_info = self.marry_info or {}
    self.marry_info.target_guid = marry_target_guid
    self.marry_info.is_accept = is_accept
end

function human:get_marry_info()
    return self.marry_info
end

function human:on_bus(bus_id)
    self:get_ai():change_state("by_bus")
    self.db:set_attrib({ bus_id = bus_id})
end

function human:off_bus()
    self:get_ai():change_state("idle")
    self.db:set_attrib( { bus_id = define.INVAILD_ID })
end

function human:has_mount()
    return self:impact_get_first_impact_in_specific_collection(66) ~= nil
end

function human:has_dride()
    return false
end

function human:has_change_mode()
    local model_id = self.db:get_attrib("model_id") or define.INVAILD_ID
    return model_id ~= define.INVAILD_ID
end

function human:start_mission_timer(mission_id)
    local mission_timers = self.mission_timers or {}
    self.mission_timers = mission_timers
    table.insert(self.mission_timers, mission_id)
end

function human:stop_mission_timer(mission_id)
    local mission_timers = self.mission_timers or {}
    self.mission_timers = mission_timers
    for i, id in ipairs(self.mission_timers) do
        if id == mission_id then
            table.remove(self.mission_timers, i)
            break
        end
    end
end

function human:update_mission_timers(...)
    if self.mission_timers then
        for i = #self.mission_timers, 1, -1 do
            local mission_id = self.mission_timers[i]
            local mission = self:get_mission_by_id(mission_id)
            local script_id = mission.index or define.INVAILD_ID
            if script_id and script_id ~= define.INVAILD_ID then
                self:get_scene():get_script_engienr():call(script_id, "OnTimer", self:get_obj_id())
            end
        end
    end
end

function human:cost_money_with_priority(cost, reason, extra)
		assert(cost >= 1,cost)
    local money = self:get_money()
    local jiaozi = self:get_jiaozi()
    local cost_jiaozi = 0
    local cost_money = 0
    if jiaozi >= cost then
        self:set_jiaozi(jiaozi - cost, reason, extra)
        cost_jiaozi = cost
    else
        local diff = cost - jiaozi
        self:set_jiaozi(0, reason, extra)
        self:set_money(money - diff, reason, extra)
        cost_jiaozi = jiaozi
        cost_money = diff
    end
    return true, cost_jiaozi, cost_money
end

function human:cost_money(cost, reason, extra)
    local money = self:get_money()
    assert(cost > 0, cost)
    money = money - cost
    money = money < 0 and 0 or money
    self:set_money(money, reason, extra)
end

function human:check_money_with_priority(cost)
    local money = self:get_money()
    local jiaozi = self:get_jiaozi()
    return money + jiaozi >= cost
end

function human:set_wild_war_list(wild_war_list)
    self:get_wild_war_guilds():set_list(wild_war_list)
end

function human:is_friend_relation(other)
    local realtion_list = self.relation_list
    local friend_group = realtion_list.friends
    local relation = self:get_relation_by_guid_in_group(other:get_guid(), friend_group)
    return relation ~= nil
end

function human:is_prentice_relation(other)
    local realtion_list = self.relation_list
    local prentice_guid = realtion_list.prentice_guid or {}
    for _, guid in ipairs(prentice_guid) do
        if guid == other:get_guid() then
            return true
        end
    end
    return false
end

function human:get_relation_by_guid_in_group(guid, group)
    for _, relation in ipairs(group) do
        if relation.guid == guid then
            return relation
        end
    end
end

function human:add_good_bad_value(add)
    if add ~= 0 then
        local value = self:get_good_bad_value()
        value = value + add
        local config_info = configenginer:get_config("config_info")
        local MaxGoodBadValue = config_info.GoodBad.MaxGoodBadValue
        value = value > MaxGoodBadValue and MaxGoodBadValue or value
        self:set_good_bad_value(value)
        local msg = packet_def.GCNotifyGoodBad.new()
        msg.mode = 0
        msg.bonus = add
        self:get_scene():send2client(self, msg)
    end
end

function human:inc_friend_point(other)
    local realtion_list = self.relation_list
    local friend_group = realtion_list.friends
    local relation = self:get_relation_by_guid_in_group(other:get_guid(), friend_group)
    relation.friend_point = (relation.friend_point or 0) + 1
    skynet.send(self:get_agent(), "lua", "set_realtion_list", realtion_list)
end

function human:refix_skill_cool_down_time(skill_info, cool_down_time)
    local r, err = pcall(self.talent_refix_skill_cool_down_time, self, skill_info, cool_down_time)
    if r then
        cool_down_time = err
    else
        skynet.logw("talent_refix_skill_cool_down_time error =", err)
    end
    return cool_down_time
end

function human:talent_refix_skill_cool_down_time(skill_info, cool_down_time)
    local skill_info = self:get_skill_info()
    local _sid = skill_info and skill_info:get_skill_id() or -1
    local talent = self:get_talent()
    for i = 1, #talent.study do
        local study_talent = talent.study[i]
        local logic = talentenginer:get_logic(study_talent)
        if logic then
            local talent_config = configenginer:get_config("sect_desc")
            talent_config = talent_config[study_talent.id]
            if talent_config then
                local level = study_talent.level
                level = level == 0 and 1 or level
                cool_down_time = logic:refix_skill_cool_down_time(talent_config, level, study_talent.id, skill_info, cool_down_time)
            end
        end
    end
    return cool_down_time
end

function human:talent_on_use_skill_success_fully(skill_info)
    local skill_info = self:get_skill_info()
    local talent = self:get_talent()
    for i = 1, #talent.study do
        local study_talent = talent.study[i]
        local logic = talentenginer:get_logic(study_talent)
        if logic then
            local talent_config = configenginer:get_config("sect_desc")
            talent_config = talent_config[study_talent.id]
            if talent_config then
                local level = study_talent.level
                level = level == 0 and 1 or level
                cool_down_time = logic:on_use_skill_success_fully(talent_config, level, skill_info, self)
            end
        end
    end
end

function human:talent_on_critical_hit_target(skill_id, obj_tar)
    local skill_info = self:get_skill_info()
    local talent = self:get_talent()
    for i = 1, #talent.study do
        local study_talent = talent.study[i]
        local logic = talentenginer:get_logic(study_talent)
        if logic then
            local talent_config = configenginer:get_config("sect_desc")
            talent_config = talent_config[study_talent.id]
            if talent_config then
                local level = study_talent.level
                level = level == 0 and 1 or level
                cool_down_time = logic:on_critical_hit_target(talent_config, level, self, obj_tar, skill_id)
            end
        end
    end
end

function human:talent_refix_skill_id(skill_id)
    local talent = self:get_talent()
    for i = 1, #talent.study do
        local study_talent = talent.study[i]
        local logic = talentenginer:get_logic(study_talent)
        if logic and logic.refix_skill_id then
            local talent_config = configenginer:get_config("sect_desc")
            talent_config = talent_config[study_talent.id]
            if talent_config then
                local level = study_talent.level
                level = level == 0 and 1 or level
                local new_id = logic:refix_skill_id(talent_config, level, skill_id)
                if new_id then
                    skill_id = new_id
                end
            end
        end
    end
    return skill_id
end

function human:talent_refix_skill_info(skill_info)
    local _sid = skill_info:get_skill_id()
    local talent = self:get_talent()
    for i = 1, #talent.study do
        local study_talent = talent.study[i]
        local logic = talentenginer:get_logic(study_talent)
        if logic then
            local talent_config = configenginer:get_config("sect_desc")
            talent_config = talent_config[study_talent.id]
            if talent_config then
                local level = study_talent.level
                level = level == 0 and 1 or level
                logic:refix_skill_info(talent_config, level, skill_info, self)
            end
        end
    end
end

function human:impact_forbidden_this_skill(skill_id)
    local impactenginer = self:get_scene():get_impact_enginer()
    local impacts = self:get_impact_list()
    for i = #impacts, 1, -1 do
        local impact = impacts[i]
        local logic = impactenginer:get_logic(impact)
        if logic:forbidden_this_skill(impact, skill_id) then
            return true
        end
    end
    return false
end

function human:on_skill_miss(sender, skill_id)
    self:impact_on_skill_miss(sender, skill_id)
    local r, err = pcall(self.talent_on_skill_miss, self, sender, skill_id)
    if not r then
        skynet.loge("talent_on_skill_miss error =", err)
    end
end

function human:on_skill_miss_target(reciver, skill_id, cast_token)
    -- Outgoing miss is distinct from evading another actor's attack.
    local engine = self:get_scene():get_impact_enginer()
    for _,impact in ipairs(self:get_impact_list()) do
        local logic = engine:get_logic(impact)
        if logic and logic.on_miss_target then
            logic:on_miss_target(impact, self, reciver, skill_id, cast_token)
        end
    end
    local r, err = pcall(self.talent_on_skill_miss_target, self, reciver, skill_id)
    if not r then
        skynet.loge("talent_on_skill_miss error =", err)
    end
end

function human:impact_on_skill_miss(sender, skill_id)
    local impactenginer = self:get_scene():get_impact_enginer()
    local impacts = self:get_impact_list()
    for i = #impacts, 1, -1 do
        local impact = impacts[i]
        local logic = impactenginer:get_logic(impact)
        logic:on_skill_miss(impact, sender)
    end
end

function human:impact_on_call_up_pet_success()
    local impactenginer = self:get_scene():get_impact_enginer()
    local impacts = self:get_impact_list()
    for i = #impacts, 1, -1 do
        local impact = impacts[i]
        local logic = impactenginer:get_logic(impact)
        logic:on_call_up_pet_success(impact, self, self.pet)
    end
end

function human:talent_on_skill_miss(sender, skill_id)
    local talent = self:get_talent()
    for i = 1, #talent.study do
        local study_talent = talent.study[i]
        local logic = talentenginer:get_logic(study_talent)
        if logic then
            local talent_config = configenginer:get_config("sect_desc")
            talent_config = talent_config[study_talent.id]
            if talent_config then
                local level = study_talent.level
                level = level == 0 and 1 or level
                logic:on_skill_miss(talent_config, level, sender, self, skill_id)
            end
        end
    end
end

function human:talent_on_skill_miss_target(reciver, skill_id)
    local talent = self:get_talent()
    for i = 1, #talent.study do
        local study_talent = talent.study[i]
        local logic = talentenginer:get_logic(study_talent)
        if logic then
            local talent_config = configenginer:get_config("sect_desc")
            talent_config = talent_config[study_talent.id]
            if talent_config then
                local level = study_talent.level
                level = level == 0 and 1 or level
                logic:on_skill_miss_target(talent_config, level, self, reciver, skill_id)
            end
        end
    end
end

function human:talent_on_damages(damages, caster_obj_id, is_critical, skill_id, imp)
    local talent = self:get_talent()
    for i = 1, #talent.study do
        local study_talent = talent.study[i]
        local logic = talentenginer:get_logic(study_talent)
        if logic then
            local talent_config = configenginer:get_config("sect_desc")
            talent_config = talent_config[study_talent.id]
            if talent_config then
                local level = study_talent.level
                level = level == 0 and 1 or level
                logic:on_damages(talent_config, level, damages, self, caster_obj_id, is_critical, skill_id, imp)
            end
        end
    end
end

function human:talent_on_be_hit(sender, skill)
    local talent = self:get_talent()
    for i = 1, #talent.study do
        local study_talent = talent.study[i]
        local logic = talentenginer:get_logic(study_talent)
        if logic then
            local talent_config = configenginer:get_config("sect_desc")
            talent_config = talent_config[study_talent.id]
            if talent_config then
                local level = study_talent.level
                level = level == 0 and 1 or level
                logic:on_be_hit(talent_config, level, self, sender, skill)
            end
        end
    end
end

function human:talent_on_be_critical_hit(skill_id, sender)
    local talent = self:get_talent()
    for i = 1, #talent.study do
        local study_talent = talent.study[i]
        local logic = talentenginer:get_logic(study_talent)
        if logic then
            local talent_config = configenginer:get_config("sect_desc")
            talent_config = talent_config[study_talent.id]
            if talent_config then
                local level = study_talent.level
                level = level == 0 and 1 or level
                logic:on_be_critical_hit(talent_config, level, self, sender, skill)
            end
        end
    end
end

function human:talent_on_be_skill(sender, skill_id, behaviortype)
    local talent = self:get_talent()
    for i = 1, #talent.study do
        local study_talent = talent.study[i]
        local logic = talentenginer:get_logic(study_talent)
        if logic then
            local talent_config = configenginer:get_config("sect_desc")
            talent_config = talent_config[study_talent.id]
            if talent_config then
                local level = study_talent.level
                level = level == 0 and 1 or level
                logic:on_be_skill(talent_config, level, self, sender, skill_id, behaviortype)
            end
        end
    end
end

function human:talent_on_active()
    local talent = self:get_talent()
    for i = 1, #talent.study do
        local study_talent = talent.study[i]
        local logic = talentenginer:get_logic(study_talent)
        if logic then
            local talent_config = configenginer:get_config("sect_desc")
            talent_config = talent_config[study_talent.id]
            if talent_config then
                local level = study_talent.level
                level = level == 0 and 1 or level
                logic:on_active(talent_config, level, self)
            end
        end
    end
end

function human:talent_on_remove()
    local talent = self:get_talent()
    for i = 1, #talent.study do
        local study_talent = talent.study[i]
        local logic = talentenginer:get_logic(study_talent)
        if logic then
            local talent_config = configenginer:get_config("sect_desc")
            talent_config = talent_config[study_talent.id]
            if talent_config then
                local level = study_talent.level
                level = level == 0 and 1 or level
                logic:on_remove(talent_config, level, self)
            end
        end
    end
end

function human:talent_on_stealth_level_update()
    local talent = self:get_talent()
    if talent then
        for i = 1, #talent.study do
            local study_talent = talent.study[i]
            local logic = talentenginer:get_logic(study_talent)
            if logic then
                local talent_config = configenginer:get_config("sect_desc")
                talent_config = talent_config[study_talent.id]
                if talent_config then
                    local level = study_talent.level
                    level = level == 0 and 1 or level
                    logic:on_stealth_level_update(talent_config, level, self)
                end
            end
        end
    end
end

function human:get_skill_template(skill_id)
    local template = human.super.get_skill_template(self, skill_id)
    return self:talent_on_get_skill_template(template)
end

function human:talent_on_get_skill_template(template)
    template = table.clone(template)
    local talent = self:get_talent()
    if talent then
        for i = 1, #talent.study do
            local study_talent = talent.study[i]
            local logic = talentenginer:get_logic(study_talent)
            if logic then
                local talent_config = configenginer:get_config("sect_desc")
                talent_config = talent_config[study_talent.id]
                if talent_config then
                    local level = study_talent.level
                    level = level == 0 and 1 or level
                    logic:on_get_skill_template(talent_config, level, self, template)
                end
            end
        end
    end
    return template
end

function human:set_talent_trigger_time(name)
    local talents_trigger_time = self.talents_trigger_time or {}
    talents_trigger_time[name] = os.time()
    self.talents_trigger_time = talents_trigger_time
end

function human:get_talent_trigger_time(name)
    local talents_trigger_time = self.talents_trigger_time or {}
    return talents_trigger_time[name]
end

function human:get_top_up_point()
    return skynet.call(self:get_agent(), "lua", "get_top_up_point")
end

function human:cost_top_up_point(cost)
    return skynet.call(self:get_agent(), "lua", "cost_top_up_point", cost)
end

function human:get_prerechage_money(...)
    return skynet.call(self:get_agent(), "lua", "get_prerechage_money", ...)
end

function human:on_enter_scene()
    -- CYS-MOUNT-FLIGHT
    require('cys_mount_flight').reset(self)
    self.begin_send_refresh_attrib = true
    -- 补发武境高位mission(960-975 → client 1299-1314) + 刷新756/320
    self:sync_dfeng_learn_md_to_client()
    self:refresh_dfeng_attrib()
    self:schedule_dfeng_learn_resync("on_enter_scene")
    -- 恢复外观属性加成缓存
    exterior_bonus.refresh_bonus(self)
    -- 不在过图时发758, 避免触发REFRESH_DFENG_POMAI导致客户端自动弹出心络UI
end

function human:is_begin_send_refresh_attrib()
    return self.begin_send_refresh_attrib
end

function human:set_near_team_members(members)
    self.near_team_members = members
end

function human:get_near_team_members()
    return self.near_team_members
end

function human:add_mission_huoyuezhi(type, count, sync_client)
    type = tonumber(type)
    count = math.floor(tonumber(count) or 1)
    if type == nil or type ~= math.floor(type) or type < 1 or type > 0x2A
        or count <= 0 then
        return false
    end
    local week_active = configenginer:get_config("week_active")[type]
    if week_active == nil then return false end

    local data = self:get_week_active()
    local old_num = math.max(tonumber(data.activity_finish_count[type]) or 0,
        tonumber(data.can_get[type]) or 0)
    local num = math.min(0x7FFFFFFF, old_num + count)
    data.activity_finish_count[type] = num
    -- The client compares this value directly with Weekactive.Target.
    data.can_get[type] = num
    -- GCZhouHuoYueInfo 会让客户端直接打开周活跃界面；任务完成时只记录进度。
    -- 仅由玩家主动打开/领取奖励的流程调用 send_week_active 刷新界面。
    if sync_client == true then
        self:send_week_active()
    end
    -- [2026-09-11] Phong Hon Luc (791010): diem tich luy theo hoat dong
    do
        local se = self:get_scene() and self:get_scene():get_script_engienr()
        if se and se:have_function(791010, "OnHuoYueActivity") then
            se:call(791010, "OnHuoYueActivity", self:get_obj_id(), type)
        end
    end
    return true
end

function human:set_is_first_login(is_first_login)
    self.is_first_login = is_first_login
end

function human:get_is_first_login()
    return self.is_first_login
end

function human:set_enter_scene_time()
    self.enter_scene_time = os.time()
end

function human:get_enter_scene_time()
    return self.enter_scene_time
end

function human:get_enter_scene_time_diff()
    return os.time() - self.enter_scene_time
end

function human:get_talent_by_skill_id(skill_id)
    local talent = self:get_talent()
    local talent_config = configenginer:get_config("sect_desc")
    for i = 1, #talent.study do
        local study_talent = talent.study[i]
        local logic = talentenginer:get_logic(study_talent)
        if logic then
            local config = talent_config[study_talent.id]
            if config then
                local level = study_talent.level
                level = level == 0 and 1 or level
                local add_skill_id = logic:get_add_skill(config, level)
                if add_skill_id == skill_id then
                    return study_talent
                end
            end
        end
    end
end

function human:get_dw_jinjie_features()
	local features = {}
	for idx,value in pairs(self.dw_jinjie.features) do
		local level = (value >> 8) & 0xFF
		local nexp = (value >> 16) & 0xFF
		if level > 0 or nexp > 0 then
			features[idx] = value
		end
	end
	return features
end
function human:get_dw_jinjie_features_value(id)
	local index = tostring(id)
	return self.dw_jinjie.features[index]
end
function human:set_dw_jinjie_features_value(id,value)
	local index = tostring(id)
	self.dw_jinjie.features[index] = value
	self.db:send_refresh_attrib("dw_jinjie")
end

function human:set_dw_jinjie_feature_details(id,level,nexp)
	local index = tostring(id)
	self.dw_jinjie.features[index] = (nexp << 16) | (level << 8) | id
	self.db:send_refresh_attrib("dw_jinjie")
end

function human:get_dw_jinjie_feature_details(id)
	local idx = tostring(id)
	local value = self.dw_jinjie.features[idx]
	if value then
		local index = value & 0xFF
		local level = (value >> 8) & 0xFF
		local nexp = (value >> 16) & 0xFF
		if index == id and (level > 0 or nexp > 0) then
			return level,nexp
		end
	end
end

function human:set_dw_jinjie_effect_details(equip_point,dw_featuresid,dw_advance_level)
	local index = tostring(equip_point)
	local oldid = 0
	if self.dw_jinjie.effect[index] then
		oldid = self.dw_jinjie.effect[index].id
	end
	if dw_featuresid > 0 then
		dw_advance_level = dw_advance_level // 5
		self.dw_jinjie.effect[index] = {id = dw_featuresid,finedraw = dw_advance_level}
	else
		self.dw_jinjie.effect[index] = nil
	end
	if dw_featuresid == 5
	or dw_featuresid == 11
	or oldid == 5
	or oldid == 11 then
		self:item_flush()
	end
end

function human:set_dw_jinjie_effect(effect)
	self.dw_jinjie.effect = effect or {}
end

function human:get_dw_jinjie_effect_details(id)
	local effect_value = 0
	local level = self:get_dw_jinjie_feature_details(id)
	if level and level > 0 then
		local dw_jinjie_texing = configenginer:get_config("dw_jinjie_texing")
		local texing = dw_jinjie_texing[id]
		if texing then
			local minlv
			for _,j in pairs(self.dw_jinjie.effect) do
				if j.id == id then
					minlv = math.min(level,j.finedraw)
					if minlv > 0 then
						effect_value = effect_value + texing.feature_list[minlv]
						if effect_value >= texing.feature_max then
							effect_value = texing.feature_max
							break
						end
					end
				end
			end
			return effect_value,texing.feature_rate,texing.add_feature_max
		end
	end
	return effect_value
end

function human:features_effect_notify_client(id,objid)
	objid = objid or self:get_obj_id()
	local msg = packet_def.GCDiaowenFeatureSkill.new()
	msg.objId = objid
	msg.effect_id = id
	self:get_scene():broadcast(self, msg, true)
end
-- function human:set_login_user(value)
    -- self.game_flag.login_user = value
-- end
function human:update_game_flag_key_cd(key,ntime)
	local value = (self.game_flag[key] or 0) - ntime
	if value < 0 then
		value = 0
	end
	self.game_flag[key] = value
end
function human:get_game_flag_key(key)
	return self.game_flag[key] or 0
end
function human:set_game_flag_key(key,value)
	self.game_flag[key] = value
end
function human:get_game_flag_keys(keys)
	local values = {}
	for key,value in pairs(keys) do
		values[key] = self.game_flag[key] or 0
	end
	return values
end
function human:set_game_flag_keys(values)
	for key,value in pairs(values) do
		self.game_flag[key] = value
		-- skynet.logi(key," = ",table.tostr(values))
	end
	-- if self.game_flag[key] ~= value then
		-- local guid = self:get_guid()
        -- skynet.send(".world", "lua", "update_uinfo", guid, {[key] = value})
	-- end
	-- self.game_flag[key] = value
end
function human:set_game_flag_keys_visual(eq_point,value)
	local key = string.format("equip_%d_visual",eq_point)
	self.game_flag[key] = value
	-- skynet.logi(key," = ",table.tostr(value))
end
--define.HUMAN_EQUIP_VISUALS_KEY
function human:get_game_flag_keys_visual(eq_point)
	local key = string.format("equip_%d_visual",eq_point)
	local values = {}
	if eq_point == define.HUMAN_EQUIP.HEQUIP_FASHION then
		values = {[define.WG_KEY_A] = -1,[define.WG_KEY_D] = -1,[define.WG_KEY_E] = -1,[define.WG_KEY_F] = -1,[define.WG_KEY_C] = 0}
	else
		values = {[define.WG_KEY_A] = -1,[define.WG_KEY_B] = -1,[define.WG_KEY_C] = 0}
	end
	if self.game_flag[key] then
		for key,value in pairs(self.game_flag[key]) do
			values[key] = value
		end
	end
	return values
end

function human:del_limit_shop(shopid)
	local index = tostring(shopid)
	if self.limit_shop[index] then
		self.limit_shop[index] = nil
	end
end
function human:reset_limit_shop(shopid,ntime)
	local index = tostring(shopid)
	if self.limit_shop[index] then
		if self.limit_shop[index].ntime ~= ntime then
			self.limit_shop[index] = {ntime = ntime,item_buy = {}}
		end
	else
		self.limit_shop[index] = {ntime = ntime,item_buy = {}}
	end
end
function human:get_limit_shop_buy_count(shopid,itemid)
	local index = tostring(shopid)
	if self.limit_shop[index] then
		if self.limit_shop[index].item_buy then
			for _,info in ipairs(self.limit_shop[index].item_buy) do
				if info.goods_id == itemid then
					return info.count
				end
			end
			return 0
		end
	end
end
function human:set_limit_shop_buy_count(shopid,itemid,buy_num)
	local index = tostring(shopid)
	if self.limit_shop[index] then
		if self.limit_shop[index].item_buy then
			local have_date = false
			for _,info in ipairs(self.limit_shop[index].item_buy) do
				if info.goods_id == itemid then
					info.count = info.count + buy_num
					have_date = true
					break
				end
			end
			if not have_date then
				table.insert(self.limit_shop[index].item_buy,{ goods_id = itemid, count = buy_num})
			end
		end
	end
end

function human:update_chonglou_sash(imp)
    local list = self:get_impact_list()
	for i, current in ipairs(list) do
		if current:get_mutex_id() == 5982 then
			local logic = impactenginer:get_logic(current)
			if logic then
				logic:reset_calculate_total_damage_taken(current,0)
			end
		end
	end
end

function human:remove_impact(imp,checking)
    local list = self:get_impact_list()
	local imp_sn = imp:get_sn()
	if not checking then
		local have_chonglou_impact
		local have_control
		for i, current in ipairs(list) do
			if current:get_sn() == imp_sn then
				local logic = impactenginer:get_logic(imp)
				if logic then
					logic:mark_modified_attr_dirty(imp, self)
				end
				table.remove(list, i)
				-- break
			elseif current:get_mutex_id() == 5982 then
				have_chonglou_impact = current
			elseif current:get_chonglou_sash() then
				have_control = true
			end
		end
		if have_chonglou_impact then
			if not have_control then
				local logic = impactenginer:get_logic(have_chonglou_impact)
				if logic then
					logic:set_calculate_total_damage_taken(have_chonglou_impact)
				end
			end
		end
	else
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
	end
	-- transform-model 17/09: xem `character:refresh_attrib_after_remove_impact` — human ghi đè
	-- `remove_impact` nên phải gọi lại ở đây, nếu không các thuộc tính kiểu `replace` (变身/骑乘/can_move…)
	-- vẫn giữ giá trị của lúc CÒN buff sau khi buff hết hạn.
	self:refresh_attrib_after_remove_impact()
end

require('cys_currency').install(human)
return require('cys_guild').installHuman(human)
