--兽灵育灵(鉴定/缔约/合成)
--NPC: 四时山君 (script_id=888830)

local class = require "class"
local define = require "define"
local script_base = require "script_base"
local packet_def = require "game.packet"
local human_item_logic = require "human_item_logic"
local item_cls = require "item"
local configenginer = require "configenginer":getinstance()
local skynet = require "skynet"
local pet_guid_cls = require "pet_guid"

local pet_elf_yc = class("pet_elf_yc", script_base)

-- 鉴定费用(金币)
local IDENTIFY_COST = 50000

-- 鉴定石道具ID
local IDENTIFY_STONE = 38003463

-- 缔约费用(金币)
local PUTINELF_COST = 200000

-- 合成产出: 品阶 → 固灵仙露 item_id
local COMPOUND_RESULT = {
    [1] = 38003475,  -- 1阶固灵仙露
    [2] = 38003476,  -- 2阶固灵仙露
    [3] = 38003477,  -- 3阶固灵仙露
    [4] = 38003478,  -- 4阶固灵仙露
    [5] = 38003479,  -- 5阶固灵仙露
    [6] = 38003480,  -- 6阶固灵仙露
}

-- 昆吾月莲(替代品): item_id → 对应品阶
local REPLACED_ITEMS = {
    [38003753] = 1, [38003754] = 2, [38003755] = 3,
    [38003756] = 4, [38003757] = 5, [38003758] = 6,
}

-- 合成费用(金币): 按品阶
local COMPOUND_COST = { 20000, 25000, 30000, 35000, 40000, 50000 }

---------------------------------------------------------------
-- [2025-03-21] attack_type 编码映射表
-- 背景 (IDA反编译确认):
--   服务端 pet_detail:get_attrib("attack_type") 返回 MonsterAttrExTable 原始值: 12/11/13
--   PetJL.txt 使用 PetJL 权威编码: 0=内功, 1=外功, 2=平衡
--   客户端 C++ LuaFnGetPetAttackType (0x1402BC3F0) 汇编级映射:
--     attack_type==12 → xorps xmm1,xmm1 → push 0.0 (内功)
--     attack_type==11 → movsd xmm1,[1.0] → push 1.0 (外功)
--     attack_type==13 → movsd xmm1,[2.0] → push 2.0 (平衡)
--   客户端全程使用 0/1/2 比较, 服务端必须做同样映射
-- 用途: 将 pet 的原始 attack_type 转换为 PetJL 编码后再与兽灵比较
---------------------------------------------------------------
local ATTACK_TYPE_MAP = {
    [12] = 0, [11] = 1, [13] = 2,  -- MonsterAttrExTable 原始值 → PetJL 编码
    [0]  = 0, [1]  = 1, [2]  = 2,  -- 兼容已映射值 (防止数据源不一致)
}

---------------------------------------------------------------
-- [2025-03-21] 保级替换所需道具
-- 背景: 客户端 LuaFnGetPetElfLevelKeepNeedItem(level) 从 s_pPetElfLevelDBC (DBC#396) 查询
--   服务端无此DBC, 此表为合理近似 (按兽灵等级区间分档)
--   客户端 Kunwu_JL_Inlay.lua L380 已向玩家展示具体需求
-- 结构: KEEP_LEVEL_ITEMS[level] = { item_id, count }
--   道具使用固灵仙露系列: 38003475(1阶)~38003480(6阶)
---------------------------------------------------------------
local KEEP_LEVEL_ITEMS = {}
for lv = 2,  5 do KEEP_LEVEL_ITEMS[lv] = { 38003475, 1 } end  -- 等级2~5:  1阶×1
for lv = 6, 10 do KEEP_LEVEL_ITEMS[lv] = { 38003476, 1 } end  -- 等级6~10: 2阶×1
for lv = 11,15 do KEEP_LEVEL_ITEMS[lv] = { 38003477, 1 } end  -- 等级11~15:3阶×1
for lv = 16,20 do KEEP_LEVEL_ITEMS[lv] = { 38003478, 1 } end  -- 等级16~20:4阶×1

---------------------------------------------------------------
-- [2025-03-21] 固灵仙露映射表: 品阶 → item_id
-- 与客户端 g_ExpItem 一致 (Kunwu_JL_Levelup.lua L40-47)
-- 升级时从背包自动消耗, 不放入材料槽
---------------------------------------------------------------
local EXP_ITEMS = {
    [1] = 38003475,  -- 1阶固灵仙露
    [2] = 38003476,  -- 2阶固灵仙露
    [3] = 38003477,  -- 3阶固灵仙露
    [4] = 38003478,  -- 4阶固灵仙露
    [5] = 38003479,  -- 5阶固灵仙露
    [6] = 38003480,  -- 6阶固灵仙露
}

---------------------------------------------------------------
-- [2025-03-21] 昆吾月莲映射表: 品阶 → item_id
-- 与客户端 g_ReplacedItem 一致 (Kunwu_JL_Levelup.lua L31-38)
-- 可替代同阶兽灵作为升级副材料
---------------------------------------------------------------
local MOONLOTUS_ITEMS = {
    [1] = 38003481,  -- 1级昆吾月莲
    [2] = 38003482,  -- 2级昆吾月莲
    [3] = 38003483,  -- 3级昆吾月莲
    [4] = 38003484,  -- 4级昆吾月莲
    [5] = 38003485,  -- 5级昆吾月莲
    [6] = 38003486,  -- 6级昆吾月莲
}

---------------------------------------------------------------
-- [2025-03-21] 兽灵保级符映射表: 品阶 → item_id
-- 客户端 LuaFnGetPetElfProtectNeedItem(curLv) 从 DBC#396 查询
-- 升级失败时使用, 防止等级回退
---------------------------------------------------------------
local PROTECT_ITEMS = {
    [1] = 38003512,  -- 兽灵保级符·1阶
    [2] = 38003513,  -- 兽灵保级符·2阶
    [3] = 38003514,  -- 兽灵保级符·3阶
    [4] = 38003515,  -- 兽灵保级符·4阶
    [5] = 38003516,  -- 兽灵保级符·5阶
    [6] = 38003517,  -- 兽灵保级符·6阶
}

---------------------------------------------------------------
-- [2025-03-21] 兽灵升级配置表 (对应客户端 DBC#396 s_pPetElfLevelDBC)
-- 客户端从 DBC 查询, 服务端无此 DBC, 用此 Lua 表替代
-- [当前等级] = { qual, count, money, lx, odds, exp, safe }
--   qual:  所需材料品阶 (1~6, 对应固灵仙露/兽灵/月莲的阶数)
--   count: 副材料数量 (兽灵或月莲, 放入 3 个材料槽)
--   money: 金币费用
--   lx:    珍兽灵性需求
--   odds:  成功率百分比 (1~100)
--   exp:   固灵仙露消耗数量
--   safe:  是否为保底节点 (失败不掉级)
-- 品阶分段: 1-3→1阶, 4-6→2阶, 7-9→3阶, 10-12→4阶, 13-15→5阶, 16-19→6阶
-- 保底节点: 4/7/10/13/16 (gpt分析.txt)
---------------------------------------------------------------
local ELF_LEVEL_CONFIG = {
    --  lv    qual  count  money     lx   odds  exp   safe
    [1]  = { qual=1, count=1, money=100000,  lx=3,  odds=100, exp=1, safe=false },
    [2]  = { qual=1, count=1, money=100000,  lx=3,  odds=90,  exp=1, safe=false },
    [3]  = { qual=1, count=1, money=100000,  lx=3,  odds=80,  exp=1, safe=false },
    [4]  = { qual=2, count=1, money=150000,  lx=5,  odds=70,  exp=1, safe=true  },
    [5]  = { qual=2, count=1, money=150000,  lx=5,  odds=60,  exp=1, safe=false },
    [6]  = { qual=2, count=1, money=200000,  lx=5,  odds=50,  exp=2, safe=false },
    [7]  = { qual=3, count=2, money=200000,  lx=7,  odds=50,  exp=2, safe=true  },
    [8]  = { qual=3, count=2, money=250000,  lx=7,  odds=40,  exp=2, safe=false },
    [9]  = { qual=3, count=2, money=300000,  lx=7,  odds=35,  exp=2, safe=false },
    [10] = { qual=4, count=2, money=300000,  lx=9,  odds=35,  exp=2, safe=true  },
    [11] = { qual=4, count=2, money=350000,  lx=9,  odds=30,  exp=3, safe=false },
    [12] = { qual=4, count=2, money=400000,  lx=9,  odds=25,  exp=3, safe=false },
    [13] = { qual=5, count=2, money=400000,  lx=11, odds=25,  exp=3, safe=true  },
    [14] = { qual=5, count=3, money=450000,  lx=11, odds=20,  exp=3, safe=false },
    [15] = { qual=5, count=3, money=500000,  lx=11, odds=15,  exp=3, safe=false },
    [16] = { qual=6, count=3, money=500000,  lx=13, odds=15,  exp=3, safe=true  },
    [17] = { qual=6, count=3, money=550000,  lx=13, odds=12,  exp=4, safe=false },
    [18] = { qual=6, count=3, money=600000,  lx=13, odds=10,  exp=4, safe=false },
    [19] = { qual=6, count=3, money=600000,  lx=13, odds=8,   exp=4, safe=false },
}

-- 最大兽灵等级
local ELF_MAX_LEVEL = 20

-- 获取底层配置: pet_jl_attr[level][attr_key] = value, pet_jl_attr.attr_pool = {有效attr_key列表}
local function get_pet_jl_config()
    -- [修复] configenginer 已经是 getinstance() 返回的实例, 无需再调用一次
    return configenginer:get_config("pet_jl_attr")
end

---------------------------------------------------------------
-- NPC对话
---------------------------------------------------------------
function pet_elf_yc:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("Chào mừng tới Dục Linh Điện, ta giúp được giám định, đính ước, hợp thành thú linh.")
    self:AddNumText("Giám định Thú Linh", 6, 1)
    self:AddNumText("Đế ước Thú Linh", 6, 3)
    self:AddNumText("Hợp thành thú linh", 6, 4)
    self:AddNumText("Thú Linh Thăng cấp", 6, 5)
    --self:AddNumText("[调试]查看兽灵数据", 6, 2)
    self:AddNumText("#{SHXT_20211230_55}", 11, 99) --离开
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function pet_elf_yc:OnEventRequest(selfId, targetId, arg, index)
    if index == 1 then
        -- 打开兽灵鉴定UI (88883001)
        self:BeginUICommand()
        self:UICommand_AddInt(targetId)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 88883001)
        return
    elseif index == 2 then
        self:DebugElfInfo(selfId)
        return
    elseif index == 3 then
        -- 打开兽灵缔约UI (88883002)
        self:BeginUICommand()
        self:UICommand_AddInt(targetId)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 88883002)
        return
    elseif index == 4 then
        -- 打开兽灵合成UI (88883007)
        self:BeginUICommand()
        self:UICommand_AddInt(targetId)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 88883007)
        return
    elseif index == 5 then
        -- 打开兽灵升级UI (88883003)
        self:BeginUICommand()
        self:UICommand_AddInt(targetId)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 88883003)
        return
    end
end

---------------------------------------------------------------
-- 从属性池中随机选取 count 个不重复的 attr_key
---------------------------------------------------------------
local function pick_random_attrs(attr_pool, count)
    local pool = {}
    for i, v in ipairs(attr_pool) do
        pool[i] = v
    end
    local result = {}
    for i = 1, count do
        local idx = math.random(1, #pool)
        result[i] = pool[idx]
        table.remove(pool, idx)
    end
    return result
end

---------------------------------------------------------------
-- DoElfIdentify - 兽灵鉴定
-- 客户端 XSCRIPT 参数:
--   param[0] = npcServerId
--   param[1] = elfBagIndex       (兽灵在背包的位置)
--   param[2] = perfectBagIndex   (鉴定石背包位置, -1=无)
--   param[3] = 1
--
-- 物品数据布局 (IDA逆向):
--   客户端 item_data 布局: [0-7]=guid, [8-11]=item_index, [12]=rule, [13]=status, [14-25]=unknow_4
--   set_param(2, v, "uchar") -> unknow_4[3] -> client item_data[16] = identified (must == 1)
--   set_param(3, v, "uchar") -> unknow_4[4] -> client item_data[17] = level/品阶 (PetElfAttrDBC lookup key)
--   set_param(4, v, "uchar") -> unknow_4[5] -> client item_data[18] = attr_key[0]
--   set_param(5, v, "uchar") -> unknow_4[6] -> client item_data[19] = attr_key[1]
--   set_param(6, v, "uchar") -> unknow_4[7] -> client item_data[20] = attr_key[2]
--   set_param(7, v, "uchar") -> unknow_4[8] -> client item_data[21] = attr_key[3]
--   set_param(8, v, "uchar") -> unknow_4[9] -> client item_data[22] = attr_key[4]
--   pet_equip_type 必须 == 6 (ELF), 否则客户端 IsPetElf 返回 false
---------------------------------------------------------------
function pet_elf_yc:DoElfIdentify(selfId, npcServerId, elfBagIndex, perfectBagIndex)
    local obj = self.scene:get_obj_by_id(selfId)
    if not obj then return end

    -- 等级检查
    if obj:get_level() < 65 then
        self:notify_tips(selfId, "Không đủ cấp, cần trên 65.")
        return
    end

    -- 获取背包容器
    local container = obj:get_prop_bag_container()

    -- 获取兽灵物品
    local item = container:get_item(elfBagIndex)
    if not item or item:is_empty() then
        self:notify_tips(selfId, "Xin hãy đặt thú linh vào.")
        return
    end

    -- 检查是否为兽灵道具 (item_index 7070xxxx)
    local item_index = item:get_index()
    if math.floor(item_index / 10000) ~= 7070 then
        self:notify_tips(selfId, "Vật phẩm này không phải thú linh.")
        return
    end

    -- 检查是否已鉴定 (param pos 2 -> unknow_4[3] -> client item_data[16])
    local identified = item:get_param(2, "uchar")
    if identified == 1 then
        self:notify_tips(selfId, "Thú linh này đã giám định rồi.")
        return
    end

    -- 获取PetJL配置 (attack_type, grade, skill_pool)
    local pet_jl = configenginer:get_config("pet_jl")
    local jl_entry = pet_jl and pet_jl[item_index]
    if not jl_entry then
        self:notify_tips(selfId, "Cấu hình thú linh bất thường.")
        return
    end

    -- 金币检查
    local money = obj:get_money()
    if money < IDENTIFY_COST then
        self:notify_tips(selfId, "Không đủ kim tệ.")
        return
    end

    -- 如果放入了鉴定石, 验证并消耗
    if perfectBagIndex and perfectBagIndex >= 0 then
        local stone = container:get_item(perfectBagIndex)
        if not stone or stone:is_empty() then
            self:notify_tips(selfId, "Giám định thạch vô hiệu.")
            return
        end
        if stone:get_index() ~= IDENTIFY_STONE then
            self:notify_tips(selfId, "Xin đặt đúng giám định thạch.")
            return
        end
        -- 消耗1个鉴定石
        self:LuaFnDelAvailableItem(selfId, IDENTIFY_STONE, 1)
    end

    -- 扣除金币
    obj:cost_money(IDENTIFY_COST, "Giám định Thú Linh")

    -- 获取属性配置数据 (PetJLAttr.txt)
    local pet_jl_config = get_pet_jl_config()
    if not pet_jl_config or not pet_jl_config.attr_pool then
        self:notify_tips(selfId, "Nạp cấu hình bất thường, xin báo quản trị.")
        return
    end

    -- 确定鉴定属性条数:
    -- 无鉴定符: 随机2~5条
    -- 有鉴定符(38003463): 保底4条(随机4~5条)
    local attr_count = math.random(2, 5)
    if perfectBagIndex and perfectBagIndex >= 0 then
        attr_count = math.random(4, 5)
    end

    -- 随机不重复属性键
    local attrs = pick_random_attrs(pet_jl_config.attr_pool, attr_count)

    -- 设置鉴定标记: param pos 2 -> unknow_4[3] -> client item_data[16] = 1
    item:set_param(2, 1, "uchar")

    -- 设置品阶(grade): 从PetJL配置读取
    -- param pos 3 -> unknow_4[4] -> client item_data[17]
    -- C++ tooltip通过 raw_data[17] 作为品阶查 PetElfAttrDBC 获取属性数值
    local elf_grade = jl_entry.grade or 1
    item:set_param(3, elf_grade, "uchar")

    -- 设置技能ID: param pos 10 -> unknow_4[11..12] -> client raw_data[24..25] (WORD)
    -- 从兽灵系列对应的技能池随机选取
    local skill_pool = jl_entry.skill_pool or {}
    local skill_id = item:get_param(10, "ushort")
    if not skill_id or skill_id <= 0 then
        if #skill_pool > 0 then
            skill_id = skill_pool[math.random(1, #skill_pool)]
        else
            skill_id = 8  -- fallback: 拼命
        end
    end
    item:set_param(10, skill_id, "ushort")

    -- 设置属性键: param pos 4..8 -> unknow_4[5..9] -> client item_data[18..22]
    -- 未使用的槽位填0xFF(客户端跳过>=66的值)
    for i = 1, 5 do
        if i <= attr_count then
            item:set_param(3 + i, attrs[i], "uchar")
        else
            item:set_param(3 + i, 0xFF, "uchar")
        end
    end

    -- 设置equip_data: attr_type(位掩码) + attr_values(实际数值)
    -- 按品阶查PetJLAttr获取对应等级的属性值
    local level_data = pet_jl_config[elf_grade] or pet_jl_config[1] or {}
    -- 按attr_key排序, 确保attr_values顺序与位掩码匹配
    local sorted = {}
    for i, key in ipairs(attrs) do
        table.insert(sorted, { key = key, value = level_data[key] or 0 })
    end
    table.sort(sorted, function(a, b) return a.key < b.key end)

    local attr_type = 0
    local attr_values = {}
    local attr_types = {}
    for _, a in ipairs(sorted) do
        if a.key <= 57 then
            attr_type = attr_type | (1 << a.key)
            table.insert(attr_values, a.value)
            table.insert(attr_types, a.key)
        end
    end

    local ped = item:get_pet_equip_data()
    ped:set_pet_equip_type(define.PET_EQUIP_TYPE.ELF)  -- 必须=6, 客户端IsPetElf检查
    ped:set_attr_count(#attr_values)
    ped:set_attr_value(attr_values)
    ped:set_attr_type(attr_type)
    ped:set_attr_types(attr_types)

    -- 刷新物品信息给客户端 (GCItemInfo + copy_raw_data)
    self:LuaFnRefreshItemInfo(selfId, elfBagIndex)

    skynet.error(string.format("[DoElfIdentify] player=%s item=%d grade=%d skill=%d attrs=%d keys={%s}",
        obj:get_name(), item_index, elf_grade, skill_id, attr_count,
        table.concat(attrs, ",")))

    self:notify_tips(selfId, "Giám định thành công!")
end

---------------------------------------------------------------
-- PutInElf - 缔约(将兽灵装入珍兽精灵槽)
--
-- [2025-03-21 完善] 修复内容:
--   1. attack_type 比较: 原始值12/11/13 → PetJL编码0/1/2 映射后比较
--   2. 保级替换(mode1): 验证并消耗保级道具(固灵仙露)
--   3. 增加调试日志 [PutInElf] 前缀
--
-- 客户端 XSCRIPT 参数 (Kunwu_JL_Inlay.lua L634-647):
--   ScriptID  = 888830
--   Function  = "PutInElf"
--   param[0] = npcServerId
--   param[1] = petGUID_H
--   param[2] = petGUID_L
--   param[3] = slotIndex (0-based: 0~4, 客户端 g_CurElfIndex-1)
--   param[4] = elfBagIndex (兽灵在背包的位置)
--   param[5] = changeMode (0=正常, 1=保留等级, 2=重置等级)
--   param[6] = ybBuy (元宝购买确认)
--   param[7] = 1 (flag)
--
-- 校验规则 (gpt分析.txt L136-155, 与客户端 Kunwu_JL_Inlay.lua 一致):
--   1. 人物等级 >= 65
--   2. 珍兽存在
--   3. 槽位索引 0~4 合法, 且槽位已激活 (activated==1)
--   4. 背包兽灵存在, 7070xxxx, 已鉴定
--   5. 攻击类型一致 (PetJL编码: 0=内,1=外,2=平)
--   6. 技能类型匹配: 槽1~4=被动(use_type==1), 槽5=主动(use_type==2)
--   7. 同技能不重复
--   8. 高级替换需选模式: mode1=保级(消耗道具), mode2=重置
--   9. 金币 >= 200000
---------------------------------------------------------------
function pet_elf_yc:PutInElf(selfId, npcServerId, petGUID_H, petGUID_L, slotIndex, elfBagIndex, changeMode, ybBuy, flag)
    -- [PutInElf] 入口参数日志 (便于排查客户端XSCRIPT传参问题)
    skynet.error(string.format(
        "[PutInElf] ENTER: selfId=%s npc=%s pet=%s_%s slot=%s bag=%s mode=%s yb=%s flag=%s",
        tostring(selfId), tostring(npcServerId),
        tostring(petGUID_H), tostring(petGUID_L),
        tostring(slotIndex), tostring(elfBagIndex),
        tostring(changeMode), tostring(ybBuy), tostring(flag)))

    local obj = self.scene:get_obj_by_id(selfId)
    if not obj then return end

    -- 等级检查
    if obj:get_level() < 65 then
        self:notify_tips(selfId, "Không đủ cấp, cần trên 65.")
        return
    end

    -- 查找珍兽
    local container = obj:get_pet_bag_container()
    local guid = pet_guid_cls.new()
    guid:set(petGUID_H, petGUID_L)
    local pet_detail = container:get_pet_by_guid(guid)
    if not pet_detail then
        self:notify_tips(selfId, "Không tìm thấy trân thú tương ứng.")
        return
    end

    -- 槽位索引转换 (客户端发送0-based, 内部使用1-based)
    local slot_idx = slotIndex + 1
    if slot_idx < 1 or slot_idx > 5 then
        self:notify_tips(selfId, "Ô tinh linh không hợp lệ.")
        return
    end

    -- 检查槽位是否已激活
    local slot = pet_detail:get_elf_slot(slot_idx)
    if slot.activated ~= 1 then
        self:notify_tips(selfId, "Ô tinh linh chưa kích hoạt, xin nâng cấp giác tỉnh trước.")
        return
    end

    -- 获取背包中的兽灵物品
    local bag = obj:get_prop_bag_container()
    local item = bag:get_item(elfBagIndex)
    if not item or item:is_empty() then
        self:notify_tips(selfId, "Xin hãy đặt thú linh vào.")
        return
    end

    -- 验证是兽灵道具
    local item_index = item:get_index()
    if math.floor(item_index / 10000) ~= 7070 then
        self:notify_tips(selfId, "Vật phẩm này không phải thú linh.")
        return
    end

    -- 验证已鉴定
    local identified = item:get_param(2, "uchar")
    if identified ~= 1 then
        self:notify_tips(selfId, "Thú linh chưa giám định, xin giám định trước.")
        return
    end

    -- 获取兽灵技能ID
    local elf_skill = item:get_param(10, "ushort")
    if not elf_skill or elf_skill <= 0 then
        self:notify_tips(selfId, "Dữ liệu kỹ năng thú linh bất thường.")
        return
    end

    -- [2025-03-21 修复] 攻击类型匹配检查
    -- BUG: 原代码直接比较 pet_detail:get_attrib("attack_type") (=12/11/13)
    --       和 pet_jl[item].attack_type (=0/1/2), 永远不匹配, 缔约永远失败
    -- FIX: 用 ATTACK_TYPE_MAP 将 pet 的 12/11/13 映射为 0/1/2 再比较
    local pet_jl = configenginer:get_config("pet_jl")
    local jl_entry = pet_jl and pet_jl[item_index]
    if not jl_entry then
        self:notify_tips(selfId, "Cấu hình thú linh bất thường.")
        return
    end
    local raw_pet_atk = pet_detail:get_attrib("attack_type") or 12
    local pet_attack_type = ATTACK_TYPE_MAP[raw_pet_atk] or 0
    local elf_attack_type = jl_entry.attack_type or 0
    skynet.error(string.format("[PutInElf] attack_type check: raw_pet=%s → mapped=%d, elf=%d",
        tostring(raw_pet_atk), pet_attack_type, elf_attack_type))
    if elf_attack_type ~= pet_attack_type then
        self:notify_tips(selfId, "Loại công kích thú linh không khớp trân thú.")
        return
    end

    -- 技能类型(被动/主动)与槽位匹配检查
    local pet_elf_skill_cfg = configenginer:get_config("pet_elf_skill")
    local skill_cfg = pet_elf_skill_cfg and pet_elf_skill_cfg[elf_skill]
    local use_type = skill_cfg and skill_cfg.use_type or 0
    if slot_idx <= 4 then
        -- 前4槽: 只能放被动兽灵 (use_type == 1)
        if use_type ~= 1 then
            self:notify_tips(selfId, "4 ô đầu chỉ đặt được thú linh bị động.")
            return
        end
    else
        -- 第5槽: 只能放主动兽灵 (use_type == 2)
        if use_type ~= 2 then
            self:notify_tips(selfId, "Ô thứ 5 chỉ đặt được thú linh chủ động.")
            return
        end
    end

    -- 同技能不能重复缔约
    local elf_slots = pet_detail:get_elf_slots()
    for i = 1, 5 do
        if i ~= slot_idx then
            local existing_slot = elf_slots[i]
            if existing_slot and existing_slot.skill == elf_skill then
                self:notify_tips(selfId, "Trân thú đã đính ước thú linh cùng kỹ năng, không trùng được.")
                return
            end
        end
    end

    -- [2025-03-21 完善] 替换模式处理
    -- 背景: 客户端 Kunwu_JL_Inlay_OK_Clicked (L620-630):
    --   当 pet_elf_level > 1 且 elf_skill != pet_elf_skill 时, 要求玩家选择:
    --     changeMode=1 保留等级(需消耗保级道具)
    --     changeMode=2 重置等级(不需道具)
    --   客户端UI已展示所需道具/数量 (Kunwu_JL_Inlay.lua L380-391)
    local existing_skill = slot.skill or 0
    local existing_level = slot.level or 1
    local new_level = 1  -- 默认缔约等级为1
    if existing_skill > 0 and existing_level > 1 and existing_skill ~= elf_skill then
        -- 已有高等级兽灵且技能不同: 必须选择替换模式
        if changeMode == 1 then
            -- 模式1: 保留等级, 需要消耗保级道具 (固灵仙露)
            -- 客户端通过 LuaFnGetPetElfLevelKeepNeedItem(level) 查询 s_pPetElfLevelDBC
            -- 服务端用 KEEP_LEVEL_ITEMS 近似表
            local keep_req = KEEP_LEVEL_ITEMS[existing_level]
            if keep_req then
                local need_item_id = keep_req[1]
                local need_count   = keep_req[2]
                local have_count = self:LuaFnGetItemCount(selfId, need_item_id)
                if have_count < need_count then
                    self:notify_tips(selfId, string.format(
                        "Thay bảo cấp cần đạo cụ (ID:%d)×%d, đang có %d.",
                        need_item_id, need_count, have_count))
                    return
                end
                -- 消耗保级道具
                self:LuaFnDelAvailableItem(selfId, need_item_id, need_count)
                skynet.error(string.format("[PutInElf] Tiêu hao bảo cấp: item=%d count=%d level=%d",
                    need_item_id, need_count, existing_level))
            end
            new_level = existing_level
        elseif changeMode == 2 then
            -- 模式2: 重置等级, 不需要额外道具
            new_level = 1
        else
            self:notify_tips(selfId, "Xin chọn chế độ thay thế.")
            return
        end
        skynet.error(string.format("[PutInElf] Thay: old_skill=%d old_lv=%d → new_skill=%d mode=%d new_lv=%d",
            existing_skill, existing_level, elf_skill, changeMode, new_level))
    elseif existing_skill > 0 and existing_skill == elf_skill then
        -- 同技能替换: 保持当前等级 (无需选模式, 客户端不弹选择框)
        new_level = existing_level
    end

    -- 金币检查
    if obj:get_money() < PUTINELF_COST then
        self:notify_tips(selfId, "Không đủ kim tệ, cần" .. PUTINELF_COST .. "Kim tệ.")
        return
    end

    -- 扣除金币
    obj:cost_money(PUTINELF_COST, "Đế ước Thú Linh")

    -- 读取兽灵属性键 (param pos 4..8)
    local attrs = {}
    for i = 1, 5 do
        attrs[i] = item:get_param(3 + i, "uchar")
    end

    -- 更新精灵槽数据
    pet_detail:set_elf_slot_field(slot_idx, "skill", elf_skill)
    pet_detail:set_elf_slot_field(slot_idx, "attrs", attrs)
    pet_detail:set_elf_slot_field(slot_idx, "level", new_level)
    pet_detail:set_elf_slot_field(slot_idx, "extra", item_index)
    pet_detail:set_elf_slot_field(slot_idx, "exp", 0)

    -- 删除背包中的兽灵物品
    local logparam = { reason = "Đế ước Thú Linh", func_name = "PutInElf", script_id = self.script_id }
    human_item_logic:erase_item_by_bag_index(logparam, obj, elfBagIndex)

    -- 刷新珍兽属性到客户端
    pet_detail:send_refresh_attrib(obj, true)

    skynet.error(string.format("[PutInElf] player=%s pet_guid=%d_%d slot=%d skill=%d item=%d level=%d",
        obj:get_name(), petGUID_H, petGUID_L, slot_idx, elf_skill, item_index, new_level))

    self:notify_tips(selfId, "Đính ước thành công!")
end

---------------------------------------------------------------
-- PetElfTP - 兽灵升级(将已缔约的兽灵提升等级)
--
-- [2025-03-21 新增] 功能说明:
--   升级已缔约到珍兽精灵槽的兽灵, 消耗副材料+固灵仙露+金币
--   有概率失败, 失败回退1级, 保底节点不掉级
--
-- 客户端 XSCRIPT 参数 (Kunwu_JL_Levelup.lua L960-974):
--   ScriptID  = 888830
--   Function  = "PetElfTP"
--   param[0] = npcServerId
--   param[1] = petGUID_H
--   param[2] = petGUID_L
--   param[3] = slotIndex (0-based: 0~4, 客户端 g_CurElfIndex-1)
--   param[4] = bagIndex1 (材料1背包位置, 兽灵或昆吾月莲)
--   param[5] = bagIndex2 (材料2背包位置, -1=无)
--   param[6] = bagIndex3 (材料3背包位置, -1=无)
--   param[7] = check_protect (0/1 使用保护道具防掉级)
--   param[8] = YBPay_Confirm (0/1 元宝购买确认)
--
-- 结果通知 (Kunwu_JL_Fail.lua, UI_COMMAND 88883010):
--   param[0] = ok (0=失败, 1=成功)
--   param[1] = petGUID_H
--   param[2] = petGUID_L
--   param[3] = elfIndex (1-based)
--   param[4] = old_level
--   param[5] = new_level
--
-- 校验规则:
--   1. 人物等级 >= 65
--   2. 珍兽存在
--   3. 槽位 0~4 合法, 且已激活, 且有已缔约兽灵 (skill>0)
--   4. 当前等级 < 20
--   5. 副材料: 兽灵需 已鉴定+品阶/攻击类型/技能三重匹配;
--             昆吾月莲需品阶匹配
--   6. 副材料总数 >= ELF_LEVEL_CONFIG[lv].count
--   7. 固灵仙露 (对应阶) 数量 >= ELF_LEVEL_CONFIG[lv].exp
--   8. 珍兽灵性 >= ELF_LEVEL_CONFIG[lv].lx
--   9. 金币 >= ELF_LEVEL_CONFIG[lv].money
--  10. (可选) 保护道具检查
--  11. 概率判定: math.random(1,100) <= odds
--  12. 结果: 成功+1, 失败且安全节点不变, 失败且保护不变, 否则-1
---------------------------------------------------------------
function pet_elf_yc:PetElfTP(selfId, npcServerId, petGUID_H, petGUID_L, slotIndex, bagIndex1, bagIndex2, bagIndex3, check_protect, ybConfirm)
    -- [PetElfTP] 入口参数日志
    skynet.error(string.format(
        "[PetElfTP] ENTER: selfId=%s npc=%s pet=%s_%s slot=%s bag1=%s bag2=%s bag3=%s protect=%s yb=%s",
        tostring(selfId), tostring(npcServerId),
        tostring(petGUID_H), tostring(petGUID_L),
        tostring(slotIndex), tostring(bagIndex1),
        tostring(bagIndex2), tostring(bagIndex3),
        tostring(check_protect), tostring(ybConfirm)))

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

    -- 3. 槽位验证 (客户端发送0-based, 内部使用1-based)
    local slot_idx = slotIndex + 1
    if slot_idx < 1 or slot_idx > 5 then
        self:notify_tips(selfId, "Ô tinh linh không hợp lệ.")
        return
    end
    local slot = pet_detail:get_elf_slot(slot_idx)
    if slot.activated ~= 1 then
        self:notify_tips(selfId, "Ô tinh linh này chưa kích hoạt.")
        return
    end
    local cur_skill = slot.skill or 0
    if cur_skill <= 0 then
        self:notify_tips(selfId, "Ô này chưa đính ước thú linh, xin đính ước trước.")
        return
    end

    -- 4. 等级上限检查
    local cur_level = slot.level or 1
    if cur_level >= ELF_MAX_LEVEL then
        self:notify_tips(selfId, "Thú linh đã cấp tối đa.")
        return
    end

    -- 5. 获取升级配置
    local cfg = ELF_LEVEL_CONFIG[cur_level]
    if not cfg then
        self:notify_tips(selfId, "Cấu hình thăng cấp bất thường.")
        return
    end
    local need_qual  = cfg.qual
    local need_count = cfg.count
    local need_money = cfg.money
    local need_lx    = cfg.lx
    local odds       = cfg.odds
    local need_exp   = cfg.exp
    local is_safe    = cfg.safe

    -- 6. 验证副材料 (3个材料槽: bagIndex1, bagIndex2, bagIndex3)
    local bag = obj:get_prop_bag_container()
    local bag_indices = { bagIndex1, bagIndex2, bagIndex3 }
    local material_count = 0  -- 有效副材料总数

    -- 加载配置用于兽灵验证
    local pet_jl = configenginer:get_config("pet_jl")
    local pet_elf_skill_cfg = configenginer:get_config("pet_elf_skill")
    -- 珍兽槽位的攻击类型 (从 extra 字段获取 item_index → pet_jl → attack_type)
    local slot_item_index = slot.extra or 0
    local slot_jl_entry = pet_jl and pet_jl[slot_item_index]
    local slot_elf_type = slot_jl_entry and slot_jl_entry.attack_type or 0

    local moonlotus_item_id = MOONLOTUS_ITEMS[need_qual]
    local elf_bag_indices = {}       -- 兽灵材料背包位置 (整格删除, 每个算1)
    local has_moonlotus = false      -- 材料槽中是否有昆吾月莲

    for i = 1, 3 do
        local bi = bag_indices[i]
        if bi and bi >= 0 then
            local item = bag:get_item(bi)
            if item and not item:is_empty() then
                local item_index = item:get_index()

                if math.floor(item_index / 10000) == 7070 then
                    -- 兽灵物品: 验证 已鉴定 + 品阶 + 攻击类型 + 技能
                    local identified = item:get_param(2, "uchar")
                    if identified ~= 1 then
                        self:notify_tips(selfId, string.format("Ô nguyên liệu %d: thú linh chưa giám định.", i))
                        return
                    end
                    local jl_entry = pet_jl and pet_jl[item_index]
                    if not jl_entry then
                        self:notify_tips(selfId, string.format("Ô nguyên liệu %d: cấu hình thú linh bất thường.", i))
                        return
                    end
                    -- 品阶检查
                    local elf_qual = jl_entry.grade or 0
                    if elf_qual ~= need_qual then
                        self:notify_tips(selfId, string.format("Ô nguyên liệu %d: phẩm giai không khớp (cần bậc %d).", i, need_qual))
                        return
                    end
                    -- 攻击类型检查 (兽灵 attack_type 已是 PetJL 编码 0/1/2)
                    local elf_type = jl_entry.attack_type or 0
                    if elf_type ~= slot_elf_type then
                        self:notify_tips(selfId, string.format("Ô nguyên liệu %d: loại công kích không khớp.", i))
                        return
                    end
                    -- 技能检查
                    local elf_skill = item:get_param(10, "ushort")
                    if elf_skill ~= cur_skill then
                        self:notify_tips(selfId, string.format("Ô nguyên liệu %d: kỹ năng không khớp.", i))
                        return
                    end
                    material_count = material_count + 1  -- 兽灵: 每个算1
                    table.insert(elf_bag_indices, bi)

                elseif item_index == moonlotus_item_id then
                    -- 昆吾月莲: 品阶已匹配 (通过 moonlotus_item_id)
                    has_moonlotus = true
                else
                    self:notify_tips(selfId, string.format("Ô nguyên liệu %d: không phải nguyên liệu thăng cấp hợp lệ.", i))
                    return
                end
            end
        end
    end

    -- 昆吾月莲: 用 LuaFnGetItemCount 统计背包总数 (与客户端 GetBagItemNum 对齐)
    -- 客户端按堆叠数计入, 服务端直接查背包总持有量, 效果一致
    local moonlotus_needed = need_count - #elf_bag_indices
    local moonlotus_have = 0
    if moonlotus_needed > 0 then
        if not has_moonlotus then
            self:notify_tips(selfId, string.format("Nguyên liệu phụ không đủ, cần %d cái cùng phẩm giai.", need_count))
            return
        end
        moonlotus_have = self:LuaFnGetItemCount(selfId, moonlotus_item_id)
        material_count = material_count + moonlotus_have
    end

    if material_count < need_count then
        self:notify_tips(selfId, string.format("Nguyên liệu phụ không đủ, cần %d cái cùng phẩm giai.", need_count))
        return
    end

    skynet.error(string.format("[PetElfTP] Nguyên liệu qua kiểm: count=%d/%d qual=%d",
        material_count, need_count, need_qual))

    -- 7. 固灵仙露检查
    local exp_item_id = EXP_ITEMS[need_qual]
    if not exp_item_id then
        self:notify_tips(selfId, "Cấu hình Cố Linh Tiên Lộ bất thường.")
        return
    end
    local exp_have = self:LuaFnGetItemCount(selfId, exp_item_id)
    if exp_have < need_exp then
        self:notify_tips(selfId, string.format("Cố Linh Tiên Lộ không đủ (cần bậc %d ×%d, đang có %d).",
            need_qual, need_exp, exp_have))
        return
    end

    -- 8. 灵性检查
    local pet_lx = pet_detail:get_attrib("lingxing") or 0
    if pet_lx < need_lx then
        self:notify_tips(selfId, string.format("Linh tính trân thú không đủ (cần %d, hiện %d).", need_lx, pet_lx))
        return
    end

    -- 9. 金币检查
    if obj:get_money() < need_money then
        self:notify_tips(selfId, string.format("Không đủ kim tệ, cần %d kim tệ.", need_money))
        return
    end

    -- 10. 保护道具检查 (可选)
    -- 保级符按品阶分: PROTECT_ITEMS[need_qual], 每次消耗1个
    local protect_item_id = PROTECT_ITEMS[need_qual]
    local PROTECT_ITEM_COUNT = 1
    local use_protect = (check_protect == 1)
    if use_protect then
        if not protect_item_id then
            self:notify_tips(selfId, "Phẩm giai này không có cấu hình Bảo Cấp Phù.")
            return
        end
        local protect_have = self:LuaFnGetItemCount(selfId, protect_item_id)
        if protect_have < PROTECT_ITEM_COUNT then
            self:notify_tips(selfId, "Không đủ Bảo Cấp Phù.")
            return
        end
    end

    -- ===== 所有验证通过, 开始消耗 =====

    -- 消耗副材料
    local logparam = { reason = "Thú Linh Thăng cấp", func_name = "PetElfTP", script_id = self.script_id }
    -- 兽灵: 不可堆叠, 整格删除
    for _, bi in ipairs(elf_bag_indices) do
        human_item_logic:erase_item_by_bag_index(logparam, obj, bi)
    end
    -- 昆吾月莲: 用 LuaFnDelAvailableItem 按数量扣除 (自动处理堆叠)
    if moonlotus_needed > 0 then
        self:LuaFnDelAvailableItem(selfId, moonlotus_item_id, moonlotus_needed)
    end

    -- 消耗固灵仙露
    self:LuaFnDelAvailableItem(selfId, exp_item_id, need_exp)

    -- 扣除金币
    obj:cost_money(need_money, "Thú Linh Thăng cấp")

    -- 消耗保级符 (如果使用)
    if use_protect then
        self:LuaFnDelAvailableItem(selfId, protect_item_id, PROTECT_ITEM_COUNT)
    end

    -- ===== 概率判定 =====
    local roll = math.random(1, 100)
    local success = (roll <= odds)
    local new_level = cur_level

    if success then
        new_level = cur_level + 1
    else
        -- 失败处理
        if is_safe or use_protect then
            -- 安全节点或使用保护: 等级不变
            new_level = cur_level
        else
            -- 普通失败: 回退1级, 最低为1
            new_level = math.max(1, cur_level - 1)
        end
    end

    skynet.error(string.format("[PetElfTP] roll=%d odds=%d success=%s safe=%s protect=%s",
        roll, odds, tostring(success), tostring(is_safe), tostring(use_protect)))

    -- ===== 更新数据 =====
    pet_detail:set_elf_slot_field(slot_idx, "level", new_level)

    -- 刷新珍兽属性到客户端
    pet_detail:send_refresh_attrib(obj, true)

    -- ===== 通知客户端结果 (88883010 Kunwu_JL_Fail) =====
    local ok_flag = success and 1 or 0
    self:BeginUICommand()
    self:UICommand_AddInt(ok_flag)          -- param[0]: 0=失败, 1=成功
    self:UICommand_AddInt(petGUID_H)        -- param[1]: petGUID_H
    self:UICommand_AddInt(petGUID_L)        -- param[2]: petGUID_L
    self:UICommand_AddInt(slot_idx)         -- param[3]: elfIndex (1-based)
    self:UICommand_AddInt(cur_level)        -- param[4]: old_level
    self:UICommand_AddInt(new_level)        -- param[5]: new_level
    self:EndUICommand()
    self:DispatchUICommand(selfId, 88883010)

    -- 文字提示
    if success then
        self:notify_tips(selfId, string.format("Thăng cấp thành công! Thú linh lên cấp %d.", new_level))
    else
        if new_level < cur_level then
            self:notify_tips(selfId, string.format("Thăng cấp thất bại, thú linh lùi về cấp %d.", new_level))
        else
            self:notify_tips(selfId, "Thăng cấp thất bại, nhưng cấp không đổi.")
        end
    end

    skynet.error(string.format("[PetElfTP] player=%s pet_guid=%d_%d slot=%d old_lv=%d new_lv=%d success=%s",
        obj:get_name(), petGUID_H, petGUID_L, slot_idx, cur_level, new_level, tostring(success)))
end

---------------------------------------------------------------
-- DoCompound - 兽灵合成 (5只同阶兽灵/昆吾月莲 → 1个对应阶固灵仙露)
-- 客户端 XSCRIPT 参数 (Kunwu_JL_Gather.lua):
--   param[0] = npcServerId
--   param[1] = elfBagIndex1
--   param[2] = elfBagIndex2
--   param[3] = elfBagIndex3
--   param[4] = elfBagIndex4
--   param[5] = elfBagIndex5
--   param[6] = payMode (0=金币, 1=元宝)
--   param[7] = 1
--
-- 规则 (gpt分析.txt L184-195):
--   用5只同阶兽灵转化成对应品阶的固灵仙露
--   昆吾月莲可替代同阶兽灵
---------------------------------------------------------------
function pet_elf_yc:DoCompound(selfId, npcServerId, bagIdx1, bagIdx2, bagIdx3, bagIdx4, bagIdx5, payMode, flag)
    local obj = self.scene:get_obj_by_id(selfId)
    if not obj then return end

    -- 等级检查
    if obj:get_level() < 65 then
        self:notify_tips(selfId, "Không đủ cấp, cần trên 65.")
        return
    end

    local bag = obj:get_prop_bag_container()
    local bag_indices = { bagIdx1, bagIdx2, bagIdx3, bagIdx4, bagIdx5 }

    -- 检查重复背包位置
    for i = 1, 5 do
        if not bag_indices[i] or bag_indices[i] < 0 then
            self:notify_tips(selfId, "Xin đặt 5 thú linh cùng phẩm giai hoặc Côn Ngô Nguyệt Liên.")
            return
        end
        for j = i + 1, 5 do
            if bag_indices[i] == bag_indices[j] then
                self:notify_tips(selfId, "Không đặt vật phẩm trùng nhau được.")
                return
            end
        end
    end

    -- 验证所有5个物品, 检查品阶一致性
    local pet_jl = configenginer:get_config("pet_jl")
    local grade = nil
    local has_bind = false

    for i = 1, 5 do
        local item = bag:get_item(bag_indices[i])
        if not item or item:is_empty() then
            self:notify_tips(selfId, "Không đủ nguyên liệu.")
            return
        end

        local item_idx = item:get_index()
        local item_grade = 0

        if REPLACED_ITEMS[item_idx] then
            -- 昆吾月莲替代品
            item_grade = REPLACED_ITEMS[item_idx]
        elseif math.floor(item_idx / 10000) == 7070 then
            -- 兽灵物品
            local jl_entry = pet_jl and pet_jl[item_idx]
            item_grade = jl_entry and jl_entry.grade or 0
        else
            self:notify_tips(selfId, "第" .. i .. "vật phẩm không phải thú linh hoặc Côn Ngô Nguyệt Liên.")
            return
        end

        if item_grade <= 0 or item_grade > 6 then
            self:notify_tips(selfId, "Phẩm giai bất thường.")
            return
        end

        if grade == nil then
            grade = item_grade
        elseif grade ~= item_grade then
            self:notify_tips(selfId, "Mọi nguyên liệu phải cùng phẩm giai.")
            return
        end

        -- 检查绑定状态 (任一绑定则产出也绑定)
        if item.get_is_bind and item:get_is_bind() then
            has_bind = true
        end
    end

    -- 检查合成产出
    local result_item_id = COMPOUND_RESULT[grade]
    if not result_item_id then
        self:notify_tips(selfId, "Công thức hợp thành bất thường.")
        return
    end

    -- 金币检查
    local cost = COMPOUND_COST[grade] or 50000
    if obj:get_money() < cost then
        self:notify_tips(selfId, "Không đủ kim tệ, cần" .. cost .. "Kim tệ.")
        return
    end

    -- 扣除金币
    obj:cost_money(cost, "Hợp thành thú linh")

    -- 删除5个材料物品
    local logparam = { reason = "Hợp thành thú linh", func_name = "DoCompound", script_id = self.script_id }
    for i = 1, 5 do
        human_item_logic:erase_item_by_bag_index(logparam, obj, bag_indices[i])
    end

    -- 创建产出物品: 对应品阶的固灵仙露
    local bag_index = self:TryRecieveItemWithCount(selfId, result_item_id, 1, has_bind)

    skynet.error(string.format("[DoCompound] player=%s grade=%d result=%d bind=%s",
        obj:get_name(), grade, result_item_id, tostring(has_bind)))

    self:notify_tips(selfId, "Hợp thành thành công! Nhận Cố Linh Tiên Lộ.")
end

---------------------------------------------------------------
-- DebugElfInfo - 调试: 打印角色身上所有兽灵装备数据
-- 1. 扫描背包中的兽灵物品(7070xxxx)
-- 2. 扫描珍兽身上装备的兽灵物品
-- 3. 扫描珍兽精灵槽(elf_slots)数据
---------------------------------------------------------------
function pet_elf_yc:DebugElfInfo(selfId)
    local obj = self.scene:get_obj_by_id(selfId)
    if not obj then return end

    local tips = self.notify_tips
    local log_lines = {}
    local function send(msg)
        tips(self, selfId, msg)
        table.insert(log_lines, msg)
    end

    local player_name = obj.get_name and obj:get_name() or tostring(selfId)
    send("===== Debug dữ liệu thú linh [" .. player_name .. "] =====")

    -- 辅助: 打印单个兽灵物品的详细数据
    local function dump_elf_item(item, label)
        local item_index = item:get_index()
        -- 读取 unknow_4 原始数据
        local identified = item:get_param(2, "uchar")
        local level = item:get_param(3, "uchar")           -- 品阶: unknow_4[4]
        local keys = {}
        for i = 1, 5 do
            keys[i] = item:get_param(3 + i, "uchar")
        end
        local skill_id = item:get_param(10, "ushort")       -- 技能ID: unknow_4[11..12]
        -- 读取 pet_equip_data
        local ped = item:get_pet_equip_data()
        local pet_type = ped and ped:get_pet_equip_type() or "nil"
        local attr_count = ped and ped.attr_count or "nil"
        local attr_values_str = "nil"
        if ped and ped.attr_values then
            local vs = {}
            for i, v in ipairs(ped.attr_values) do
                vs[i] = tostring(v)
            end
            attr_values_str = table.concat(vs, ",")
        end
        local attr_type = ped and ped.attr_type or "nil"
        local attr_types_str = "nil"
        if ped and ped.attr_types then
            local ts = {}
            for i, v in ipairs(ped.attr_types) do
                ts[i] = tostring(v)
            end
            attr_types_str = table.concat(ts, ",")
        end

        send(string.format("%s [%d]", label, item_index))
        send(string.format("  Dấu giám định=%d, phẩm giai=%d, skill_id=%d",
            identified, level, skill_id))
        send(string.format("  attr_keys={%d,%d,%d,%d,%d}",
            keys[1], keys[2], keys[3], keys[4], keys[5]))
        send(string.format("  pet_equip_type=%s, attr_count=%s",
            tostring(pet_type), tostring(attr_count)))
        send(string.format("  attr_type=%s, attr_types={%s}",
            tostring(attr_type), attr_types_str))
        send(string.format("  attr_values={%s}", attr_values_str))
    end

    -- 1. 扫描背包
    local bag = obj:get_prop_bag_container()
    local bag_count = 0
    send("----- Thú linh trong túi -----")
    for i = 0, 200 do  -- 遍历背包格子
        local ok, item = pcall(bag.get_item, bag, i)
        if not ok then break end
        if item and not item:is_empty() then
            local idx = item:get_index()
            if math.floor(idx / 10000) == 7070 then
                bag_count = bag_count + 1
                dump_elf_item(item, string.format("Túi [%d]", i))
            end
        end
    end
    if bag_count == 0 then
        send("  Túi không có vật phẩm thú linh")
    end

    -- 2. 扫描珍兽装备 + 精灵槽
    local pet_container = obj:get_pet_bag_container()
    local pet_size = pet_container:get_size()
    local pet_elf_count = 0
    send("----- Trang bị trân thú & ô tinh linh -----")
    for pi = 0, pet_size - 1 do
        local pet = pet_container:get_item(pi)
        if pet then
            local pet_name = pet.get_name and pet:get_name() or ("Trân thú#" .. pi)
            -- 检查装备槽
            local equip_container = pet:get_equip_container()
            for ei = define.PET_EQUIP.PEQUIP_CAP, define.PET_EQUIP.PEQUIP_SOUL do
                local equip = equip_container:get_item(ei)
                if equip and not equip:is_empty() then
                    local idx = equip:get_index()
                    if math.floor(idx / 10000) == 7070 then
                        pet_elf_count = pet_elf_count + 1
                        dump_elf_item(equip, string.format("%s ô trang bị[%d]", tostring(pet_name), ei))
                    end
                end
            end
            -- 检查精灵槽(elf_slots)
            local elf_slots = pet.elf_slots or (pet.get_elf_slots and pet:get_elf_slots()) or {}
            if #elf_slots > 0 then
                send(string.format("%s ô tinh linh:", tostring(pet_name)))
                for si = 1, 5 do
                    local slot = elf_slots[si]
                    if slot then
                        local attrs_str = "nil"
                        if slot.attrs then
                            local as = {}
                            for j = 1, 5 do
                                as[j] = tostring(slot.attrs[j] or "?")
                            end
                            attrs_str = table.concat(as, ",")
                        end
                        send(string.format("  Ô %d: activated=%s lv=%s attrs={%s} exp=%s skill=%s extra=%s",
                            si,
                            tostring(slot.activated or 0),
                            tostring(slot.level or 0),
                            attrs_str,
                            tostring(slot.exp or 0),
                            tostring(slot.skill or 0),
                            tostring(slot.extra or 0)))
                    else
                        send(string.format("  Ô %d: (trống)", si))
                    end
                end
            end
        end
    end
    if pet_elf_count == 0 then
        send("  Trân thú không mang trang bị thú linh")
    end

    send("===== Kết thúc debug =====")

    -- 同时输出到服务端日志
    local log_text = table.concat(log_lines, "\n")
    skynet.error("[ELF_DEBUG] " .. player_name .. " (id=" .. tostring(selfId) .. ")\n" .. log_text)
end

return pet_elf_yc
