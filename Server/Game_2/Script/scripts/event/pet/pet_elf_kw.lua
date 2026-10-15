--珍兽觉醒(开悟) — 一重觉醒(首次开槽) + 二重~五重觉醒(珍兽明慧)
--NPC: 衡台 (script_id=888832)

local class = require "class"
local define = require "define"
local script_base = require "script_base"
local pet_elf_kw = class("pet_elf_kw", script_base)

local pet_guid_cls = require "pet_guid"
local skynet = require "skynet"

--初始兽灵基础ID: PetJL.txt 前3条 (70700000=内,70700001=外,70700002=平)
local INIT_ELF_BASE_ID = 70700000

-- MonsterAttrExTable "攻击特性ID" → PetJL初始兽灵偏移量
-- 客户端 LuaFnGetPetAttackType: 12=内功→0, 11=外功→1, 13=平衡→2
-- 同时兼容已转换值(0/1/2), 防止数据源不一致
local ATTACK_TYPE_MAP = {
    [12] = 0, [11] = 1, [13] = 2,
    [0]  = 0, [1]  = 1, [2]  = 2,
}

---------------------------------------------------------------
-- 觉醒配置表 (与客户端 Kunwu_Kaiwu2.lua 完全对齐)
-- 索引 = 目标觉醒等级 (1=一重, 2=二重, ..., 5=五重)
-- 客户端数组:
--   g_NeedMoney    = {200000, 300000, 400000, 600000, 800000}
--   g_NeedSumLevel = {0,      3,      7,      12,     18     }
--   g_NeedSavvy    = {5,      5,      6,      6,      7      }
--   g_NeedLX       = {3,      3,      5,      5,      7      }
-- sum_level: 已缔约(非默认)兽灵等级总和 (IDA确认: extra ∉ {70700000~70700002} 才计入)
---------------------------------------------------------------
local KW_CONFIG = {
    [1] = { savvy = 5, lx = 3, money = 200000, sum_level = 0,  name = "Nhất Trọng" },
    [2] = { savvy = 5, lx = 3, money = 300000, sum_level = 3,  name = "Nhị Trọng" },
    [3] = { savvy = 6, lx = 5, money = 400000, sum_level = 7,  name = "Tam Trọng" },
    [4] = { savvy = 6, lx = 5, money = 600000, sum_level = 12, name = "Tứ Trọng" },
    [5] = { savvy = 7, lx = 7, money = 800000, sum_level = 18, name = "Ngũ Trùng" },
}

---------------------------------------------------------------
-- 判断精灵槽是否为默认兽灵 (IDA逆向 LuaFnIsPetElfDefault @ 0x1402BC2C0)
-- 逻辑: slot.extra ∈ {70700000, 70700001, 70700002} → 默认
---------------------------------------------------------------
local function is_default_elf(slot)
    local extra = slot.extra or 0
    return (extra >= INIT_ELF_BASE_ID and extra <= INIT_ELF_BASE_ID + 2)
end

---------------------------------------------------------------
-- 计算已缔约(非默认)兽灵等级总和
-- 与客户端 Kunwu_Kaiwu2.lua L203-212 对齐
---------------------------------------------------------------
local function calc_elf_level_sum(pet_detail)
    local sum = 0
    for i = 1, 5 do
        local slot = pet_detail:get_elf_slot(i)
        if slot and slot.activated == 1 then
            if not is_default_elf(slot) then
                sum = sum + (slot.level or 0)
            end
        end
    end
    return sum
end

function pet_elf_kw:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{KWCC_241219_05}")
    self:AddNumText("#{KWCC_241219_06}", 6, 1)--珍兽觉醒(一重)
    self:AddNumText("#{KWCC_241219_07}", 6, 2)--提升觉醒等级(二重~五重)
    self:AddNumText("#gFF0FA0 Thú Linh Kế Thừa", 6, 7)      --兽灵继承
    self:AddNumText("Truyền tống về Côn Ngô", 6, 3)
    self:AddNumText("#GHọc tập Nộ Ý Chước Tâm", 6, 4)       --学习怒意灼心技能
    --self:AddNumText("遗忘怒意灼心", 6, 6)       --遗忘怒意灼心技能
    self:AddNumText("Về phương pháp Thú Linh trợ chiến", 11, 5)   --兽灵助战说明
    self:AddNumText("#{KWCC_241219_10}", 11, 99) --离开
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function pet_elf_kw:OnEventRequest(selfId, targetId, arg, index)
    if index == 1 then
        -- 打开一重觉醒UI (88883201 → Kunwu_Kaiwu)
        self:BeginUICommand()
        self:UICommand_AddInt(targetId)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 88883201)
        return
    elseif index == 2 then
        -- 打开二重~五重觉醒UI (88883202 → Kunwu_Kaiwu2)
        self:BeginUICommand()
        self:UICommand_AddInt(targetId)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 88883202)
        return
    elseif index == 7 then
        -- 打开兽灵继承UI (88883203 → Kunwu_KaiwuTransfer)
        local obj = self.scene:get_obj_by_id(selfId)
        if obj and obj:get_level() < 65 then
            self:notify_tips(selfId, "#{KWCC_241219_46}")
            return
        end
        self:BeginUICommand()
        self:UICommand_AddInt(targetId)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 88883203)
        return
    elseif index == 3 then
        -- 传送回昆吾 (场景1349, 坐标121,102)
        self:CallScriptFunction((400900), "TransferFunc", selfId, 1349, 121, 102)
        return
    elseif index == 4 then
        -- 学习怒意灼心：直接对当前出战珍兽操作
        self:DoLearnNYZX(selfId)
        return
    elseif index == 6 then
        -- 遗忘怒意灼心：移除人物技能5100
        self:DoForgetNYZX(selfId)
        return
    elseif index == 5 then
        -- 关于兽灵助战之法：展示帮助文本
		self:BeginEvent(self.script_id)
		self:AddText("#{ZSCZ_241217_23}")
		self:EndEvent()
		self:DispatchEventList(selfId, targetId)
        return
    elseif index == 99 then
		self:BeginEvent(self.script_id)
		self:AddText("#{ZSCZ_241217_23}")
		self:EndEvent()
		self:DispatchEventList(selfId, targetId)
        return
    end
end

--[[
    客户端 Kunwu_Kaiwu_OK_Clicked 通过 XSCRIPT 回调:
    ScriptID  = 888832
    Function  = "DoKW_I"
    Param[0]  = npcServerId
    Param[1]  = petGUID_H
    Param[2]  = petGUID_L
]]
function pet_elf_kw:DoKW_I(selfId, npcServerId, petGUID_H, petGUID_L)
    local obj = self.scene:get_obj_by_id(selfId)
    if not obj then return end

    --等级检查
    if obj:get_level() < 65 then
        self:notify_tips(selfId, "Không đủ cấp, cần trên 65.")
        return
    end

    --查找珍兽
    local container = obj:get_pet_bag_container()
    local guid = pet_guid_cls.new()
    guid:set(petGUID_H, petGUID_L)
    local pet_detail = container:get_pet_by_guid(guid)
    if not pet_detail then
        self:notify_tips(selfId, "Không tìm thấy trân thú tương ứng.")
        return
    end

    --已觉醒检查(本功能只做一重)
    local kw_level = pet_detail:get_kw_level()
    if kw_level >= 1 then
        self:notify_tips(selfId, "Trân thú đã giác tỉnh nhất trùng, giác tỉnh cao hơn xin chọn 「Trân Thú Minh Tuệ」.")
        return
    end

    local cfg = KW_CONFIG[1]

    --悟性检查
    local wuxing = pet_detail:get_wuxing()
    if wuxing < cfg.savvy then
        self:notify_tips(selfId, string.format("Giác tỉnh nhất trùng cần ngộ tính %d, hiện %d.", cfg.savvy, wuxing))
        return
    end

    --灵性检查
    local lingxing = pet_detail:get_ling_xing()
    if lingxing < cfg.lx then
        self:notify_tips(selfId, string.format("Giác tỉnh nhất trùng cần linh tính %d, hiện %d.", cfg.lx, lingxing))
        return
    end

    --金币检查
    if obj:get_money() < cfg.money then
        self:notify_tips(selfId, string.format("Giác tỉnh nhất trùng cần %d kim tệ, không đủ.", cfg.money))
        return
    end

    --扣除金币
    obj:cost_money(cfg.money, "Trân thú giác tỉnh nhất trùng")

    --按珍兽攻击类型确定初始兽灵
    local raw_attack_type = pet_detail:get_attrib("attack_type")
    skynet.error(string.format("[KW_I] attack_type=%s (%s)", tostring(raw_attack_type), type(raw_attack_type)))
    raw_attack_type = raw_attack_type or 12
    local elf_offset = ATTACK_TYPE_MAP[raw_attack_type] or 0
    local init_item_id = INIT_ELF_BASE_ID + elf_offset
    skynet.error(string.format("[KW_I] elf_offset=%d → init_item_id=%d", elf_offset, init_item_id))

    --初始化5个槽位并激活第1个
    pet_detail:init_elf_slots(init_item_id)
    pet_detail:set_kw_level(1)

    --刷新珍兽属性到客户端
    pet_detail:send_refresh_attrib(obj, true)

    self:notify_tips(selfId, "Giác tỉnh nhất trùng thành công! Ô thú linh đầu đã mở.")
    skynet.error(string.format("[KW_I] Giác tỉnh nhất trùng xong player=%s", obj:get_name()))
end

---------------------------------------------------------------
-- DoKW_II - 珍兽明慧: 二重~五重觉醒 (激活第2~5个精灵槽)
--
-- 客户端 Kunwu_Kaiwu2_OK_Clicked 通过 XSCRIPT 回调:
--   ScriptID  = 888832
--   Function  = "DoKW_II"
--   Param[0]  = npcServerId
--   Param[1]  = petGUID_H
--   Param[2]  = petGUID_L
--
-- 校验规则 (与 Kunwu_Kaiwu2.lua 完全对齐):
--   1. 人物等级 >= 65
--   2. 珍兽存在
--   3. 当前觉醒等级 >= 1 且 < 5
--   4. 悟性 >= KW_CONFIG[next].savvy
--   5. 灵性 >= KW_CONFIG[next].lx
--   6. 已缔约兽灵等级总和 >= KW_CONFIG[next].sum_level
--      (IDA: LuaFnIsPetElfDefault 判定 extra ∈ {70700000~70700002} 为默认, 不计入)
--   7. 金币 >= KW_CONFIG[next].money
--   8. 扣金币 → 激活下一个槽位 → 更新 kw_level → 刷新客户端
---------------------------------------------------------------
function pet_elf_kw:DoKW_II(selfId, npcServerId, petGUID_H, petGUID_L)
    skynet.error(string.format("[KW_II] ENTER: selfId=%s npc=%s pet=%s_%s",
        tostring(selfId), tostring(npcServerId),
        tostring(petGUID_H), tostring(petGUID_L)))

    local obj = self.scene:get_obj_by_id(selfId)
    if not obj then return end

    -- 1. 等级检查
    if obj:get_level() < 65 then
        self:notify_tips(selfId, "Không đủ cấp, cần trên 65.")
        return
    end

    -- 2. 查找珍兽
    local container = obj:get_pet_bag_container()
    local guid = pet_guid_cls.new()
    guid:set(petGUID_H, petGUID_L)
    local pet_detail = container:get_pet_by_guid(guid)
    if not pet_detail then
        self:notify_tips(selfId, "Không tìm thấy trân thú tương ứng.")
        return
    end

    -- 3. 觉醒等级检查
    local kw_level = pet_detail:get_kw_level()
    if kw_level < 1 then
        self:notify_tips(selfId, "Trân thú chưa giác tỉnh nhất trùng, xin giác tỉnh trước.")
        return
    end
    if kw_level >= 5 then
        self:notify_tips(selfId, "Trân thú đã giác tỉnh ngũ trùng, không tiếp được.")
        return
    end

    local next_level = kw_level + 1
    local cfg = KW_CONFIG[next_level]
    if not cfg then
        self:notify_tips(selfId, "Cấu hình giác tỉnh bất thường.")
        return
    end

    -- 4. 悟性检查
    local wuxing = pet_detail:get_wuxing()
    if wuxing < cfg.savvy then
        self:notify_tips(selfId, string.format("%s giác tỉnh cần ngộ tính %d, hiện %d.",
            cfg.name, cfg.savvy, wuxing))
        return
    end

    -- 5. 灵性检查
    local lingxing = pet_detail:get_ling_xing()
    if lingxing < cfg.lx then
        self:notify_tips(selfId, string.format("%s giác tỉnh cần linh tính %d, hiện %d.",
            cfg.name, cfg.lx, lingxing))
        return
    end

    -- 6. 已缔约兽灵等级总和检查
    local level_sum = calc_elf_level_sum(pet_detail)
    if level_sum < cfg.sum_level then
        self:notify_tips(selfId, string.format("%s giác tỉnh cần tổng cấp thú linh %d, hiện %d.",
            cfg.name, cfg.sum_level, level_sum))
        return
    end

    -- 7. 金币检查
    if obj:get_money() < cfg.money then
        self:notify_tips(selfId, string.format("%s giác tỉnh cần %d kim tệ, không đủ.",
            cfg.name, cfg.money))
        return
    end

    -- ===== 所有验证通过 =====

    -- 扣除金币
    obj:cost_money(cfg.money, string.format("Trân thú giác tỉnh %s", cfg.name))

    -- 激活下一个精灵槽 (kw_level 是已激活的槽数, 下一个槽的1-based索引 = kw_level+1)
    pet_detail:set_elf_slot_field(next_level, "activated", 1)
    pet_detail:set_kw_level(next_level)

    -- 刷新珍兽属性到客户端
    pet_detail:send_refresh_attrib(obj, true)

    self:notify_tips(selfId, string.format("%s giác tỉnh thành công! Ô thú linh thứ %d đã mở.", cfg.name, next_level))
    skynet.error(string.format("[KW_II] %s giác tỉnh xong player=%s kw=%d→%d level_sum=%d",
        cfg.name, obj:get_name(), kw_level, next_level, level_sum))
end

---------------------------------------------------------------
-- DoLearnNYZX - 学习怒意灼心 (SkillTemplate ID=5100)
--
-- 检查顺序：
--   1. 玩家等级 >= 65
--   2. 天地之炼任务检查 (TODO: 待补充任务ID)
--   3. 遍历珍兽背包，至少有一只觉醒等级 >= 5
--   4. 检查玩家自身技能列表，避免重复学习
--   5. add_skill 学习人物技能 + send_skill_list 同步客户端
---------------------------------------------------------------
function pet_elf_kw:DoLearnNYZX(selfId)
    local SKILL_ID = 5100  -- 怒意灼心 SkillTemplate ID

    local obj = self.scene:get_obj_by_id(selfId)
    if not obj then return end

    -- 1. 等级检查
    if obj:get_level() < 65 then
        self:notify_tips(selfId, "Cấp độ không đủ cấp 65, không thể tiến hành Thao tác này.")
        return
    end

    -- 2. 天地之炼任务检查
    -- TODO: 补充天地之炼任务ID后替换下方 TDZL_MISSION_ID
    -- local TDZL_MISSION_ID = 0
    -- if self:IsMissionHaveDone(selfId, TDZL_MISSION_ID) <= 0 then
    --     self:notify_tips(selfId, "需完成「天地之炼」任务后才可领取此技能。")
    --     return
    -- end

    -- 3. 遍历珍兽背包，检查是否有任意一只觉醒等级 >= 5
    local container = obj:get_pet_bag_container()
    local pet_size = container:get_size()
    local has_kw5 = false
    for i = 0, pet_size - 1 do
        local pet = container:get_item(i)
        if pet then
            local lv = pet:get_kw_level()
            if lv and lv >= 5 then
                has_kw5 = true
                break
            end
        end
    end
    if not has_kw5 then
        self:notify_tips(selfId, "Cần mang theo ít nhất một Trân thú Giác Tỉnh cấp 5 mới có thể nhận Kỹ năng này.")
        return
    end

    -- 4. 检查玩家自身是否已有技能5100，避免重复学习
    local player_skills = obj:get_skill_list()
    if player_skills then
        for _, sk in ipairs(player_skills) do
            if sk == SKILL_ID then
                self:notify_tips(selfId, "Ngươi đã học Nộ Ý Chước Tâm, khỏi học lại.")
                return
            end
        end
    end

    -- ===== 所有验证通过，教学人物技能 =====
    -- add_skill 将技能加入玩家技能列表，send_skill_list 同步到客户端快捷栏
    obj:add_skill(SKILL_ID)
    obj:send_skill_list()

    self:notify_tips(selfId, "Ngươi học được mới củaKỹ năng: Nộ Ý Chước Tâm.")
    skynet.error(string.format("[NYZX] Học Nộ Ý Chước Tâm xong (kỹ năng nhân vật) player=%s skill=%d",
        obj:get_name(), SKILL_ID))
end

---------------------------------------------------------------
-- DoForgetNYZX：遗忘怒意灼心人物技能
--   1. 获取玩家对象
--   2. 遍历玩家技能列表，检查是否已有技能5100
--   3. 未学会则提示无需遗忘
--   4. 已学会则 del_skill 移除 + send_skill_list 同步客户端
---------------------------------------------------------------
function pet_elf_kw:DoForgetNYZX(selfId)
    local SKILL_ID = 5100  -- 怒意灼心 SkillTemplate ID

    local obj = self.scene:get_obj_by_id(selfId)
    if not obj then return end

    -- 检查玩家是否已有技能5100
    local has_skill = false
    local player_skills = obj:get_skill_list()
    if player_skills then
        for _, sk in ipairs(player_skills) do
            if sk == SKILL_ID then
                has_skill = true
                break
            end
        end
    end

    if not has_skill then
        self:notify_tips(selfId, "Ngươi chưa học Nộ Ý Chước Tâm, khỏi quên.")
        return
    end

    -- ===== 验证通过，移除人物技能 =====
    -- del_skill 将技能从玩家技能列表移除，send_skill_list 同步到客户端
    obj:del_skill(SKILL_ID)
    obj:send_skill_list()

    self:notify_tips(selfId, "Đã quên kỹ năng: Nộ Ý Chước Tâm.")
    skynet.error(string.format("[NYZX] Quên Nộ Ý Chước Tâm xong (kỹ năng nhân vật) player=%s skill=%d",
        obj:get_name(), SKILL_ID))
end

---------------------------------------------------------------
-- KaiWuTransfer - 兽灵继承
-- 将源珍兽的全部兽灵槽位数据（觉醒等级+5个槽位）继承给目标珍兽，
-- 源珍兽重置为未觉醒状态。
--
-- 客户端 Kunwu_KaiwuTransfer 通过 CGExecuteScript 回调:
--   ScriptID  = 888832
--   Function  = "KaiWuTransfer"
--   Param[0]  = npcServerId
--   Param[1]  = srcGUID_H
--   Param[2]  = srcGUID_L
--   Param[3]  = dstGUID_H
--   Param[4]  = dstGUID_L
--   Param[5]  = confirmed (0=请求确认, 1=已确认执行)
--
-- 继承费用: 按源珍兽觉醒等级阶梯收费（与客户端 g_NeedMoney 一致）
---------------------------------------------------------------
local TRANSFER_MONEY = { 100000, 150000, 200000, 300000, 400000 }

function pet_elf_kw:KaiWuTransfer(selfId, npcServerId, srcGUID_H, srcGUID_L, dstGUID_H, dstGUID_L, confirmed)
    skynet.error(string.format("[KW_TRANSFER] ENTER: selfId=%s npc=%s src=%s_%s dst=%s_%s confirmed=%s",
        tostring(selfId),
        tostring(npcServerId),
        tostring(srcGUID_H), tostring(srcGUID_L),
        tostring(dstGUID_H), tostring(dstGUID_L),
        tostring(confirmed)))

    local obj = self.scene:get_obj_by_id(selfId)
    if not obj then return end

    -- 1. 等级检查
    if obj:get_level() < 65 then
        self:notify_tips(selfId, "Không đủ cấp, cần trên 65.")
        return
    end

    -- 2. 查找源珍兽和目标珍兽
    local container = obj:get_pet_bag_container()

    local src_guid = pet_guid_cls.new()
    src_guid:set(srcGUID_H, srcGUID_L)
    local src_detail = container:get_pet_by_guid(src_guid)
    if not src_detail then
        self:notify_tips(selfId, "Không tìm thấy trân thú gốc.")
        return
    end

    local dst_guid = pet_guid_cls.new()
    dst_guid:set(dstGUID_H, dstGUID_L)
    local dst_detail = container:get_pet_by_guid(dst_guid)
    if not dst_detail then
        self:notify_tips(selfId, "Không tìm thấy trân thú đích.")
        return
    end

    -- 3. 源珍兽已觉醒检查
    local src_kw_level = src_detail:get_kw_level()
    if src_kw_level < 1 then
        self:notify_tips(selfId, "Trân thú gốc chưa giác tỉnh, không kế thừa thú linh được.")
        return
    end

    -- 4. 不能是同一只珍兽
    if srcGUID_H == dstGUID_H and srcGUID_L == dstGUID_L then
        self:notify_tips(selfId, "Trân thú gốc và đích không được là một con.")
        return
    end

    -- 5. 攻击类型一致检查
    local src_raw_type = src_detail:get_attrib("attack_type")
    local dst_raw_type = dst_detail:get_attrib("attack_type")
    local src_type = ATTACK_TYPE_MAP[src_raw_type] or 0
    local dst_type = ATTACK_TYPE_MAP[dst_raw_type] or 0
    skynet.error(string.format("[KW_TRANSFER] src_attack_type=%s(%d) dst_attack_type=%s(%d)",
        tostring(src_raw_type), src_type, tostring(dst_raw_type), dst_type))
    if src_type ~= dst_type then
        self:notify_tips(selfId, "Hai trân thú khác loại công kích, không kế thừa thú linh được.")
        return
    end

    -- 6. 目标珍兽悟性/灵性检查（需满足源珍兽觉醒等级对应的要求）
    local cfg = KW_CONFIG[src_kw_level]
    if not cfg then
        self:notify_tips(selfId, "Cấu hình giác tỉnh bất thường.")
        return
    end
    local dst_wuxing = dst_detail:get_wuxing()
    if dst_wuxing < cfg.savvy then
        self:notify_tips(selfId, string.format("Ngộ tính trân thú đích không đủ, cần %d, hiện %d.", cfg.savvy, dst_wuxing))
        return
    end
    local dst_lingxing = dst_detail:get_ling_xing()
    if dst_lingxing < cfg.lx then
        self:notify_tips(selfId, string.format("Linh tính trân thú đích không đủ, cần %d, hiện %d.", cfg.lx, dst_lingxing))
        return
    end

    -- 7. 金币检查
    local transfer_cost = TRANSFER_MONEY[src_kw_level] or 400000
    if obj:get_money() < transfer_cost then
        self:notify_tips(selfId, string.format("Kế thừa thú linh cần %d kim tệ, không đủ.", transfer_cost))
        return
    end

    -- 8. 二次确认：若 confirmed ~= 1，则打开确认UI
    if confirmed ~= 1 then
        self:BeginUICommand()
        self:UICommand_AddInt(npcServerId)
        self:UICommand_AddInt(srcGUID_H)
        self:UICommand_AddInt(srcGUID_L)
        self:UICommand_AddInt(dstGUID_H)
        self:UICommand_AddInt(dstGUID_L)
        self:UICommand_AddInt(1)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 88883203)
        return
    end

    -- ===== 所有验证通过，执行继承 =====
    skynet.error(string.format("[KW_TRANSFER] Bắt đầu kế thừa player=%s src_kw=%d src_type=%d dst_type=%d cost=%d",
        obj:get_name(), src_kw_level, src_type, dst_type, transfer_cost))

    -- 扣除金币（先扣费再改数据）
    obj:cost_money(transfer_cost, "Kế thừa thú linh")

    -- 初始化目标珍兽兽灵槽位（若未觉醒则先 init）
    local dst_kw_level = dst_detail:get_kw_level()
    if dst_kw_level == 0 then
        local dst_elf_offset = ATTACK_TYPE_MAP[dst_raw_type] or 0
        dst_detail:init_elf_slots(INIT_ELF_BASE_ID + dst_elf_offset)
    end

    -- 复制全部5个兽灵槽位数据
    for i = 1, 5 do
        local src_slot = src_detail:get_elf_slot(i)
        if src_slot then
            dst_detail:set_elf_slot_field(i, "activated", src_slot.activated)
            dst_detail:set_elf_slot_field(i, "level",     src_slot.level)
            dst_detail:set_elf_slot_field(i, "skill",     src_slot.skill)
            dst_detail:set_elf_slot_field(i, "attrs",     src_slot.attrs)
            dst_detail:set_elf_slot_field(i, "extra",     src_slot.extra)
            dst_detail:set_elf_slot_field(i, "exp",       src_slot.exp)
        end
    end

    -- 设置目标珍兽觉醒等级
    dst_detail:set_kw_level(src_kw_level)

    -- 重置源珍兽为彻底未觉醒状态（直接清空所有槽位字段，不填入默认兽灵ID）
    for i = 1, 5 do
        src_detail:set_elf_slot_field(i, "activated", 0)
        src_detail:set_elf_slot_field(i, "level",     0)
        src_detail:set_elf_slot_field(i, "skill",     0)
        src_detail:set_elf_slot_field(i, "attrs",     {0, 0xFF, 0xFF, 0xFF, 0xFF})
        src_detail:set_elf_slot_field(i, "extra",     0)  -- 关键：清空兽灵物品ID，防止客户端显示默认兽灵图标
        src_detail:set_elf_slot_field(i, "exp",       0)
    end
    src_detail:set_kw_level(0)

    -- 刷新两只珍兽属性到客户端
    src_detail:send_refresh_attrib(obj, true)
    dst_detail:send_refresh_attrib(obj, true)

    self:notify_tips(selfId, "Kế thừa thú linh thành công! Dữ liệu đã chuyển sang trân thú đích.")
    skynet.error(string.format("[KW_TRANSFER] Kế thừa xong player=%s kw=%d trân thú gốc đã đặt lại",
        obj:get_name(), src_kw_level))
end

return pet_elf_kw
