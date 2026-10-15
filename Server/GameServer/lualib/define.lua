local define = {}

--[场景id] = 指定的PK编号 不可切换  0和平 1个人 2善恶 3组队 4帮或盟 5团队
define.LIMIT_PK_MODE_ON_SCENE = {
	 [1324] = {pk_id = 1,pk_name = "个人混战"},

}
--洛阳分流  define.LUOYANG 某场景中人数
-- 满 define.LUOYANG_MAXHUMAN 去下一个分流场景，
-- 不足时全去一个场景，
-- 都超过时 去人数最少的场景
define.LUOYANG_MAXHUMAN = 250
define.LUOYANG = {
	[0] = true,
	[1311] = true,
	[1315] = true,
	--[1316] = true,
}

define.SIWANG = {77,1500,2218}
define.SHENBING_CHANGE_SKILL = {
	[3938] = 47302,
	[3939] = 47303,
	[3940] = 47304,
	[3941] = 47305,
	[3942] = 47306,
	[3943] = 47307,
	[4566] = 47308,
}



--服务器定义，重要
define.WORLD_IDS = {
	[10] = "Game_tlbb_2",
	[11] = "Game_tlbb_3",
	[12] = "Game_tlbb_5",
	[13] = "Game_tlbb_7",
	[14] = "Game_tlbb_10",
	[15] = "Game_tlbb_11",
	[16] = "Game_tlbb_12",
	[17] = "Game_tlbb_13",
}
--跨服场景定义 重要  开放的话记得定义到这里，不然跨节点获取数据会报错，如果非跨服排行，非跨服活动之类
define.IS_KUAFU_SCENE = {
	[1297] = true,
	[1298] = true,
	[1299] = true,
	[1300] = true,
	[1301] = true,
	
}
--额外增加经验的场景   [场景ID] = 额外增加的经验倍数
define.MONSTER_EXP_UP_SCENE = {
	--[159] = 15,
	--[160] = 15,
	--[161] = 15,
	--[162] = 15,
	--[401] = 15,
}

define.CACHE_NODE = ".ranking"

define.FLOWER_TOP_NAME = {
	{"凛冬初遇","新雪有约","寒夜相拥"},
	--{"心间一滴泪","只待意中人","爱你一万年"},
	{"一见钟情","两情相悦","花好月圆"},
}


define.MAIL_JINGPAI_BACK_YUANBAO = 13 --竞拍有流拍元宝时提示
define.MAIL_UPDATE_MINGDONG_TOP = 14 --更新名动



define.UPDATE_CLIENT_ICON_SRIPTID = 999994

define.CONTAINER_INDEX = {
	HUMAN_BAG = 1,
	HUMAN_BANK = 2,
	HUMAN_SELF = 3,
	HUMAN_FASION = 4,
	HUMAN_SHANGHUI_ITEM = 5,
	HUMAN_PET_EQUIP = 6,
	
	
	
	HUMAN_RIDE = 90,
	HUMAN_SOLD_OUT = 91,
	HUMAN_CHANGE_ITEM = 92,
	HUMAN_CHANGE_PET = 93,
	
	HUMAN_SHANGHUI_PET = 94,
	HUMAN_STALL_ITEM = 95,
	HUMAN_STALL_PET = 96,
	ITEM_BOX = 97,
	HUMAN_PET_BAG = 98,
	HUMAN_PET_BANK = 99,
}
define.CONTAINER_CHANGE_FLAG_MAX = 6
--容器名称
define.CONTAINER_NAME = {
	[define.CONTAINER_INDEX.HUMAN_BAG] = "背包",
	[define.CONTAINER_INDEX.HUMAN_BANK] = "银行",
	[define.CONTAINER_INDEX.HUMAN_SELF] = "身上",
	[define.CONTAINER_INDEX.HUMAN_FASION] = "易容阁衣柜",
	[define.CONTAINER_INDEX.HUMAN_CHANGE_ITEM] = "商会",
	-- [define.CONTAINER_INDEX.HUMAN_SOLD_OUT] = "商店回购",
	-- [define.CONTAINER_INDEX.HUMAN_BAG] = "易容阁坐骑",
}

define.HUMAN_EQUIP = {
    HEQUIP_WEAPON = 0, -- 武器	WEAPON
    HEQUIP_CAP = 1, -- 帽子	DEFENCE
    HEQUIP_ARMOR = 2, -- 盔甲	DEFENCE
    HEQUIP_GLOVE = 3, -- 手套 		
    HEQUIP_BOOT = 4, -- 鞋	DEFENCE 
    HEQUIP_SASH = 5, -- 腰带	ADORN
    HEQUIP_RING_1 = 6, -- 戒子_1 ADORN
    HEQUIP_NECKLACE = 7, -- 项链	ADORN
    HEQUIP_RIDER = 8, -- 骑乘	ADORN
    HEQUIP_UNKNOW1 = 9, -- 行囊
    HEQUIP_UNKNOW2 = 10, -- 格箱
    HEQUIP_RING_2 = 11, -- 戒子_2 ADORN
    HEQUIP_AMULET_1 = 12, -- 护符_1
    HEQUIP_AMULET_2 = 13, -- 护符_2
    HEQUIP_CUFF = 14, -- 护腕	DEFENCE
    HEQUIP_SHOULDER = 15, -- 护肩
    HEQUIP_FASHION = 16, -- 时装
    HEQUIP_ANQI = 17, -- 暗器
    HEQUIP_WUHUN = 18, -- 武魂
    HEQUIP_TOTAL = 19,

    LINGWU_JING = 19,
    LINGWU_CHI = 20,
    LINGWU_JIA = 21,
    LINGWU_GOU = 22,
    LINGWU_DAI = 23,
    LINGWU_DI = 24,

    SHENBING = 37,
    HEQUIP_ALL = 38, -- preserve legacy sentinel semantics
    HEQUIP_CHIENHON = 39,
    HEQUIP_CAPACITY = 40
	
}
define.WG_KEY_A = "item_index"
define.WG_KEY_B = "gem_id"
define.WG_KEY_C = "visual"
define.WG_KEY_D = "gem_1"
define.WG_KEY_E = "gem_2"
define.WG_KEY_F = "gem_3"



--不需要时 将 表留空就行
define.ADD_EQUIP_BUFF = {
	["debug"] = {
		 {
			-- [define.HUMAN_EQUIP.HEQUIP_CAP] = {MINID = 10410034,MAXID = 10410034,BUFFID = 5979},
			-- --Exterior_Ride.txt  里面的ID
			-- [define.HUMAN_EQUIP.HEQUIP_RIDER] = {MINID = 132,MAXID = 135,BUFFID = 5971},
			-- -- 冰夷华裳
			--[define.HUMAN_EQUIP.HEQUIP_FASHION] = {MINID = 10126034,MAXID = 10126133,BUFFID = 5969},
            [define.HUMAN_EQUIP.HEQUIP_RIDER] = {MINID = 264,MAXID = 264,BUFFID = 63000}, -- CYS-RIDE-FINISH: 174 (GL 飒露紫) -> 264 (CY, cung mesh) -- server-impact: ID impact GL → dải riêng (xem lualib/cys_gl_impact_remap.lua)
		},
    },
	["publish_yu"] = {
		{
			-- [define.HUMAN_EQUIP.HEQUIP_CAP] = {MINID = 10410034,MAXID = 10410034,BUFFID = 5979},
			-- --Exterior_Ride.txt  里面的ID
			-- [define.HUMAN_EQUIP.HEQUIP_RIDER] = {MINID = 132,MAXID = 135,BUFFID = 5971},
			-- -- 冰夷华裳
			--[define.HUMAN_EQUIP.HEQUIP_FASHION] = {MINID = 10126034,MAXID = 10126133,BUFFID = 5969},
            [define.HUMAN_EQUIP.HEQUIP_RIDER] = {MINID = 264,MAXID = 264,BUFFID = 63000}, -- CYS-RIDE-FINISH: 174 (GL 飒露紫) -> 264 (CY, cung mesh) -- server-impact: ID impact GL → dải riêng (xem lualib/cys_gl_impact_remap.lua)
		},
    }

}


--限制字符
define.LIMITSTRING = {
	"€",
	"￥",
}
define.CHUANCI_INFO = {
	DAMAGE_HUMAN = 1,			--穿刺对玩家伤害比例
	DAMAGE_MONSTER = 5,			--穿刺对怪物伤害比例
	DAMAGE_PET = 5,				--穿刺对珍兽伤害比例
	IS_CRITICAL_HIT = 1,		--穿刺是否暴击
}
--穿刺伤害仅由门派普攻触发
define.CHUANCI_SKILL = {
	[281] = true,	--少林 伏虎拳
	[311] = true,	--明教 摧心掌
	[341] = true,	--丐帮 蟠龙击
	[371] = true,	--武当 八卦掌
	[401] = true,	--峨嵋 貂蝉拜月
	[431] = true,	--星宿 蓝砂手
	[461] = true,	--天龙 正阳手
	[491] = true,	--天山 雁南飞
	[521] = true,	--逍遥 落英剑
	[760] = true,	--曼陀山庄 余音袅袅
	[788] = true,	--恶人谷 剜心镰
	[812] = true,	--慕容 参合指
}
define.MAX_CHAR_NUMBER = 3
define.PET_EQUIP = {
    PEQUIP_CAP = 0,
    PEQUIP_ARMOR = 1,
    PEQUIP_GLOVE = 2,
    PEQUIP_NECKLACE = 3,
    PEQUIP_AMULET = 4,
    PEQUIP_SOUL = 5
}

define.PET_EQUIP_TYPE = {NORMAL = 0, SOUL = 1, ELF = 6}

define.CHUANCIGONGFANG = {
    [define.HUMAN_EQUIP.HEQUIP_WEAPON] = 602,
    [define.HUMAN_EQUIP.HEQUIP_RING_1] = 602,
    [define.HUMAN_EQUIP.HEQUIP_NECKLACE] = 602,
    [define.HUMAN_EQUIP.HEQUIP_RING_2] = 602,
    [define.HUMAN_EQUIP.HEQUIP_AMULET_1] = 602,
    [define.HUMAN_EQUIP.HEQUIP_AMULET_2] = 602,
    [define.HUMAN_EQUIP.HEQUIP_CUFF] = 602,
    [define.HUMAN_EQUIP.HEQUIP_ANQI] = 602,
    [define.HUMAN_EQUIP.HEQUIP_WUHUN] = 602,
    [define.HUMAN_EQUIP.HEQUIP_TOTAL] = 602,
    [define.HUMAN_EQUIP.SHENBING] = 602,
    [define.HUMAN_EQUIP.HEQUIP_ALL] = 602,
	
    [define.HUMAN_EQUIP.HEQUIP_CAP] = 603,
    [define.HUMAN_EQUIP.HEQUIP_ARMOR] = 603,
    [define.HUMAN_EQUIP.HEQUIP_GLOVE] = 603,
    [define.HUMAN_EQUIP.HEQUIP_BOOT] = 603,
    [define.HUMAN_EQUIP.HEQUIP_SASH] = 603,
    [define.HUMAN_EQUIP.HEQUIP_SHOULDER] = 603,
}


define.NOT_ABRASION_EQUIP = {
    [define.HUMAN_EQUIP.HEQUIP_RIDER] = true,
    [define.HUMAN_EQUIP.HEQUIP_UNKNOW1] = true,
    [define.HUMAN_EQUIP.HEQUIP_UNKNOW2] = true,
    [define.HUMAN_EQUIP.HEQUIP_FASHION] = true,
    [define.HUMAN_EQUIP.HEQUIP_ANQI] = true,
    [define.HUMAN_EQUIP.HEQUIP_WUHUN] = true,
}

define.MENPAI_ATTRIBUTE = {
    MATTRIBUTE_SHAOLIN = 0, -- 少林
    MATTRIBUTE_MINGJIAO = 1, -- 明教
    MATTRIBUTE_GAIBANG = 2, -- 丐帮
    MATTRIBUTE_WUDANG = 3, -- 武当
    MATTRIBUTE_EMEI = 4, -- 峨嵋
    MATTRIBUTE_XINGXIU = 5, -- 星宿
    MATTRIBUTE_DALI = 6, -- 大理
    MATTRIBUTE_TIANSHAN = 7, -- 天山
    MATTRIBUTE_XIAOYAO = 8, -- 逍遥
    MATTRIBUTE_WUMENPAI = 9,
    MATTRIBUTE_MANTUOSHANZHUANG = 16, ---曼陀山庄 (CS3b: CY không có, ô 16 TẮT)
    MATTRIBUTE_ERENGU = 15, ---恶人谷 (CS3b: số CY)
    MATTRIBUTE_GUSU = 10, ---慕容 (CS3b: số CY)
}

define.MENPAI_ABILITYS = {
    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_SHAOLIN]    = { 11, 29},
    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_MINGJIAO]   = { 12, 30},
    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_GAIBANG]    = { 13, 31},
    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_WUDANG]     = { 18, 36},
    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_EMEI]       = { 15, 35},
    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_XINGXIU]    = { 16, 34},
    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_DALI]       = { 17, 33},
    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_TIANSHAN]   = { 14, 32},
    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_XIAOYAO]    = { 19, 37},
    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_MANTUOSHANZHUANG]    = { 52, 53},
    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_ERENGU]    = { 66, 67},
    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_GUSU]       = { 68, 69},
}

define.MENPAI_7_SKILLS = {
    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_SHAOLIN]    = { [301] = 1, [305] = 2, [306] = 3,},
    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_MINGJIAO]   = { [331] = 1, [334] = 2, [335] = 3,},
    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_GAIBANG]    = { [361] = 1, [364] = 2, [365] = 3,},
    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_WUDANG]     = { [391] = 1, [394] = 2, [395] = 3,},
    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_EMEI]       = { [421] = 1, [424] = 2, [426] = 3,},
    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_XINGXIU]    = { [451] = 1, [454] = 2, [455] = 3,},
    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_DALI]       = { [481] = 1, [487] = 2, [488] = 3,},
    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_TIANSHAN]   = { [511] = 1, [515] = 2, [516] = 3,},
    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_XIAOYAO]    = { [541] = 1, [544] = 2, [545] = 3,},
    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_MANTUOSHANZHUANG]  = { [50785] = 1, [50784] = 2, [50786] = 3,}, -- CS3b: dải riêng, tắt
    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_ERENGU]  = { [4643] = 1, [4644] = 2, [4645] = 3,}, -- CS3b: ID CY (无我三界/判指阴阳/魂离魄散, 心法 119)
    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_GUSU]    = { [784] = 1, [785] = 2, [781] = 3,}, -- CS3b: CY 慕容 心法 70 星璇剑典: 破天式/凌神式/化气式 (GL 830-832 thuộc 心法 69 ở CY)
}

define.QINGGONG_SKILL = {
    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_SHAOLIN]    = 23,
    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_MINGJIAO]   = 24,
    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_GAIBANG]    = 25,
    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_WUDANG]     = 26,
    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_EMEI]       = 27,
    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_XINGXIU]    = 28,
    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_DALI]       = 29,
    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_TIANSHAN]   = 30,
    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_XIAOYAO]    = 31,
    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_MANTUOSHANZHUANG] = 50110, -- CS3b: dải riêng, tắt
    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_ERENGU] = 4648, -- CS3b: ID CY
    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_GUSU]   = 110, -- CS3b: ID CY (慕容轻功)
}

define.MENPAI_7_XINFA = {
    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_SHAOLIN]    = 55,
    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_MINGJIAO]   = 56,
    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_GAIBANG]    = 57,
    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_WUDANG]     = 58,
    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_EMEI]       = 59,
    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_XINGXIU]    = 60,
    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_DALI]       = 61,
    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_TIANSHAN]   = 62,
    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_XIAOYAO]    = 63,
    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_MANTUOSHANZHUANG]    = 1070, -- CS3b: dải riêng, tắt
    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_ERENGU]    = 119, -- CS3b: ID CY
    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_GUSU]       = 70, -- CS3b: ID CY
}

define.MENPAI_8_XINFA = {
    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_SHAOLIN]    = 72,
    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_MINGJIAO]   = 73,
    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_GAIBANG]    = 74,
    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_WUDANG]     = 75,
    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_EMEI]       = 76,
    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_XINGXIU]    = 77,
    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_DALI]       = 78,
    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_TIANSHAN]   = 79,
    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_XIAOYAO]    = 80,
    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_MANTUOSHANZHUANG]    = 1071, -- CS3b: dải riêng, tắt
    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_ERENGU]    = 120, -- CS3b: ID CY
    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_GUSU]       = 71, -- CS3b: ID CY
}

define.MENPAI_JINZHAN_YUANGONG_SKILL = {
    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_SHAOLIN]    = 4742, -- CS3b: ID CY
    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_MINGJIAO]   = 4743, -- CS3b: ID CY
    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_GAIBANG]    = 4744, -- CS3b: ID CY
    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_TIANSHAN]   = 4745, -- CS3b: ID CY
    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_GUSU] = 4746, -- CS3b: ID CY
}

define.MENPAI_REPUTATIONS = {
    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_SHAOLIN] = 1,
    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_MINGJIAO] = 2,
    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_GAIBANG] = 3,
    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_WUDANG] = 4,
    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_EMEI] = 5,
    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_XINGXIU] = 6,
    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_DALI] = 7,
    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_TIANSHAN] = 8,
    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_XIAOYAO] = 9,
    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_WUMENPAI] = 12,
    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_MANTUOSHANZHUANG] = 32,
    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_ERENGU] = 36,
    [define.MENPAI_ATTRIBUTE.MATTRIBUTE_GUSU]   = 37,
}

define.ITEM_EXT_INFO = {
    IEI_BIND_INFO = 0x00000001, -- 绑定信息
    IEI_IDEN_INFO = 0x00000002, -- 鉴定信息
    IEI_PLOCK_INFO = 0x00000004, -- 二级密码已经处理
    IEI_BLUE_ATTR = 0x00000008, -- 是否有蓝属性
    IEL_CREATOR = 0x00000010, -- 是否有创造者
    IEI_QIDEN_INFO = 0x00000020, -- 是否鉴定资质
    IEI_EBIND_INFO = 0x00000040 -- 是否刻铭
}

define.ITEM_CLASS = {
    ICLASS_EQUIP = 1, -- 武器WEAPON、防具DEFENCE、饰物ADORN
    ICLASS_MATERIAL = 2,
    ICLASS_STOREMAP = 3, -- 藏宝图
    ICLASS_TASK = 4,
    ICLASS_GEM = 5, -- 宝石
    ICLASS_PET_EQUIP = 7
}

define.UseEquipResultCode = {
    USEEQUIP_SUCCESS = 1,
    USEEQUIP_LEVEL_FAIL = 2,
    USEEQUIP_TYPE_FAIL = 3,
    USEEQUIP_IDENT_FAIL = 4,
    USEEQUIP_JOB_FAIL = 5
}

define.OPERATE_RESULT = {
    OR_OK = 0, -- 成功
    OR_ERROR = -1, -- 未知错误
    OR_DIE = -2, -- 你已死亡
    OR_INVALID_SKILL = -3, -- 无效技能
    OR_TARGET_DIE = -4, -- 目标已死亡
    OR_LACK_MANA = -5, -- MANA不足
    OR_COOL_DOWNING = -6, -- 冷确时间未到
    OR_NO_TARGET = -7, -- 没有目标
    OR_INVALID_TARGET = -8, -- 无效目标
    OR_OUT_RANGE = -9, -- 超出范围
    OR_IN_RANGE = -10, -- 距离太近
    OR_NO_PLATFORM = -11, -- 没有操作平台
    OR_OUT_PLATFORM = -12, -- 离操作平台太远
    OR_NO_TOOL = -13, -- 没有操作工具
    OR_STUFF_LACK = -14, -- 缺少材料
    OR_BAG_OUT_OF_SPACE = -15, -- 背包缺少空间
    OR_WARNING = -16, -- 理论上这些错误将被客户端过滤，所以如果出现，可能来自于一些外挂
    OR_BUSY = -17, -- 正在做其它事情
    OR_MISSION_HAVE = -18, -- 已经拥有该任务
    OR_MISSION_LIST_FULL = -19, -- 任务记录已满
    OR_MISSION_NOT_FIND = -20, -- 没找到该任务
    OR_EXP_LACK = -21, -- 熟练度不够
    OR_CHAR_DO_NOT_KNOW_THIS_SKILL = -22, -- 角色还不会这种技能
    OR_NO_SCRIPT = -23, -- 目标角色无脚本
    OR_NOT_ENOUGH_HP = -24, -- 没有足够的生命值
    OR_NOT_ENOUGH_RAGE = -25, -- 没有足够的怒气值
    OR_NOT_ENOUGH_STRIKE_POINT = -26, -- 没有足够的连击点
    OR_NOT_ENOUGH_ITEM = -27, -- 没有足够的道具
    OR_NOT_ENOUGH_VIGOR = -28, -- 没有足够的活力
    OR_NO_LEVEL = -29, -- 技能等级不够
    OR_CANNOT_UPGRADE = -30, -- 宝石无法再升级
    OR_FAILURE = -31, -- 操作失败
    OR_GEM_CONFLICT = -32, -- 一件装备上不允许装备同类型的宝石
    OR_NEED_IN_FURY_STANCE = -33, -- 需要在狂暴状态下使用
    OR_INVALID_TARGET_POS = -34, -- 无效目标点
    OR_GEM_SLOT_LACK = -35, -- 缺乏宝石插口
    OR_LIMIT_MOVE = -36, -- 无法移动
    OR_LIMIT_USE_SKILL = -37, -- 无法使用技能
    OR_INACTIVE_SKILL = -38, -- 使用尚未激活的技能
    OR_TOO_MUCH_HP = -39, -- HP大于限定数值
    OR_NEED_A_WEAPON = -40, -- 需要一把武器
    OR_NEED_HIGH_LEVEL_XINFA = -41, -- 等级不够
    OR_NEED_LEARN_SKILL_FIRST = -42, -- 尚未学会此技能
    OR_NEED_MENPAI_FOR_LEVELUP = -43, -- 你必须拜师进入一个门派才能继续升级
    OR_U_CANNT_DO_THIS_RIGHT_NOW = -44, -- 你现在无法这样做
    OR_ROBOT_TIMEOUT = -45, -- 挂机时间超时
    OR_NEED_HAPPINESS = -46, -- 你的宠物快乐度不足60，不能出战，需要驯养
    OR_NEED_HIGH_LEVEL = -47, -- 你的等级不够
    OR_CANNOT_GETEXP = -48, -- 你的宠物已无法得到经验
    OR_NEED_LIFE = -49, -- 你的宠物寿命为0，无法再召唤，请为其增加寿命
    OR_EXP_FULL = -50, -- 您的经验已经到达上限
    OR_TOO_MANY_TRAPS = -51, -- 无法设置更多的此类陷阱
    OR_PET_PLACARD_ISSUE_FAILED = -52, -- 发布失败
    OR_PET_PLACARD_NOT_APPOINT_PET = -53, -- 未指定宠物
    OR_PET_PLACARD_ONLY_CAN_ISSUE_ONE = -54, -- 对不起，同时只能发布一只宠
    OR_PET_PLACARD_NEED_PET_TYPE = -55, -- 对不起，你的宠好像不是宝宝哦
    OR_PET_PLACARD_NEED_PET_LEVEL = -56, -- 对不起，你的宠级别还不够哦
    OR_PET_PLACARD_NEED_PET_HAPPINESS = -57, -- 对不起，你的宠快乐值不够高
    OR_PET_PLACARD_NEED_PET_LIFE = -58, -- 对不起，你的宠寿命不够
    OR_NEED_IN_STEALTH_MODE = -59, -- 需要在隐身状态下使用
    OR_NOT_ENOUGH_ENERGY = -60, -- 对不起，你的精力不足
    OR_CAN_NOT_MOVE_STALL_OPEN = -61, -- 无法在摆摊中移动
    OR_NEED_IN_SHIELD_MODE = -62, -- 需要在护体保护下
    OR_PET_DIE = -63, -- 你的宠物已经死亡
    OR_PET_HADRECALL_NEEDHAPPINESS = -64, -- 你的宠物快乐度不足60，已被收回
    OR_PET_HADRECALL_NEEDLIFE = -65, -- 你的宠物寿命为0，已被收回
    OR_GEM_NOT_FIT_EQUIP = -66, -- 这种宝石不能镶嵌在这种装备上
    OR_GEM_NO_FOUR_SLOT = -76, -- 装备未达到四孔条件，无法镶嵌第四孔
    OR_GEM_ENCHASE_FOUR = -77, -- 已镶嵌宝石超过3颗，无法继续使用极限镶嵌
    OR_GEM_NEED_STUFF = -78, -- 缺少镶嵌符（辅助材料）
    OR_GEM_NOT_ENCHASE = -79, -- 红宝石或血精石不能镶嵌至第四孔
    OR_CANNOT_ASK_PETDETIAL = -67, -- 你无法察看该宠物的信息
    OR_VARIANCEPET_CANNOT_RETURNTOCHILD = -68, -- 变异宠不能进行还童
    OR_COMBAT_CANNOT_RETURNTOCHILD = -69, -- 出战宠不能进行还童
    OR_IMPASSABLE_ZONE = -70, -- 不可走区域
    OR_NEED_SETMINORPASSWORD = -71, -- 需要设置 二级密码
    OR_NEED_UNLOCKMINORPASSWORD = -72, -- 需要解锁 二级密码
    OR_PETINEXCHANGE_CANNOT_GOFIGHT = -73, -- 正在交易的宠物无法出战
    OR_HASSPOUSE_CANNOT_RETURNTOCHILD = -74, -- 已经有配偶的宠物不能还童
    OR_CAN_NOT_FIND_SPECIFIC_ITEM = -75, -- 缺少指定物品
    OR_CUT_PATHROUTE = -1000, -- 不是错误，只是截短路径

    OR_HEALTH_IS_FULL = -159, -- 生命值已满
    OR_MANA_IS_FULL = -160, -- 内力值已满
    OR_SOMETHING_IN_THE_WAY = -161, -- 行进方向上有障碍物
    OR_PVP_MODE_SWITCH_DELAY = -162, -- 从现在起，如果十分钟内不参与PK，您将自动进入和平模式

    OR_BUS_PASSENGERFULL						= -200;	-- 目标已无空间
	OR_BUS_HASPASSENGER							= -201;	-- 你已经在车上了
	OR_BUS_NOTINBUS								= -202;	-- 你并不在车上
	OR_BUS_RUNNING								= -203;	-- 车已经出站
	OR_BUS_HASMOUNT								= -204;	-- 你已经在坐骑上了
	OR_BUS_HASPET								= -205;	-- 宠物不能乘坐
	OR_BUS_CANNOT_TEAM_FOLLOW					= -206;	-- 不能是组队跟随状态
	OR_BUS_CANNOT_DRIDE							= -207;	-- 不能是双人骑乘状态
	OR_BUS_CANNOT_CHANGE_MODEL					= -208;	-- 不能是变身状态

    OR_NO_PET_PROPAGATE = -302 -- 没有宠物在繁殖
}

define.SYSTEM_USE_SKILL = {
    MELEE_ATTACK = 0,
    CAPTURE_PET = 1,
    CALL_UP_PET = 2,
    SYSTEM_RESERVED_3 = 3,
    SYSTEM_RESERVED_4 = 4,
    SYSTEM_RESERVED_5 = 5,
    SYSTEM_RESERVED_6 = 6,
    SYSTEM_RESERVED_7 = 7,
    SHADOW_GUARD = 8,
    XIAOYAO_TRAPS = 9
}

define.CONDITION_AND_DEPLETE_TERM_NUMBER = 3

-- CYS-ATKRANGE: khoi phuc theo ban goc 0.85 (Server/Common/GameDefine2.h:920-921).
-- So cua CY 3.71 CHUA DO: hang nay chi ton tai phia server, client khong bao gio tham chieu
-- nen khong de lai byte nao trong binary CY, va du an khong giu hien vat server CY.
-- Chi tiet: Timeline/handoff/atk-range.md muc 8b.
define.AcceptableDistanceError_NS = {ADE_FOR_HUMAN = 2, ADE_FOR_NPC = 1}

define.BAG_TYPE = {bag = 0, equip = 1}

define.ENUM_TARGET_LOGIC = {
    TARGET_LOGIC_INVALID = -1,
    TARGET_SELF = 0, -- 只对自己有效
    TARGET_MY_PET = 1, -- 只对自己的宠物有效
    TARGET_MY_SHADOW_GUARD = 2, -- 只对自己的分身有效
    TARGET_MY_MASTER = 3, -- 只对自己的主人有效，宠物专用
    TARGET_AE_AROUND_SELF = 4, -- --以自己为中心，范围有效
    TARGET_SPECIFIC_UNIT = 5, -- 瞄准的对象有效
    TARGET_AE_AROUND_UNIT = 6, -- 以瞄准的对象为中心，范围有效
    TARGET_AE_AROUND_POSITION = 7, -- 以瞄准的位置点为中心，范围有效
    TARGET_LOGIC_NUMBERS = 8, -- 逻辑总数
    TARGET_AE_AROUND_UNIT_NEW = 10, -- 瞄准的对象有效
}

define.ENUM_BEHAVIOR_TYPE = {
    BEHAVIOR_TYPE_HOSTILITY = -1, -- 敌对行为
    BEHAVIOR_TYPE_NEUTRALITY = 0, -- 中立行为
    BEHAVIOR_TYPE_AMITY = 1 -- 友好行为
}

define.ENUM_SKILL_CLASS_BY_USER_TYPE = -- 技能的使用者分类
{
    A_SKILL_FOR_PLAYER = 0,
    A_SKILL_FOR_MONSTER = 1,
    A_SKILL_FOR_PET = 2,
    A_SKILL_FOR_ITEM = 3
}

define.ENUM_SKILL_TYPE = {
    SKILL_TYPE_INVALID = -1,
    SKILL_TYPE_GATHER = 0,
    SKILL_TYPE_LEAD = 1,
    SKILL_TYPE_LAUNCH = 2,
    SKILL_TYPE_PASSIVE = 3,
    SKILL_TYPE_NUMBERS = 4
}

define.SystemUseImpactID_T = {IMP_DAMAGES_OF_ATTACKS = 0, IMP_NOTYPE_DAMAGE = 1}

define.ITEM_ATTRIBUTE = {
    IATTRIBUTE_POINT_MAXHP = 0, -- 按点数增加HP的上限
    IATTRIBUTE_RATE_MAXHP = 1, -- 按百分比增加HP的上限
    IATTRIBUTE_RESTORE_HP = 2, -- 加快HP的回复速度

    IATTRIBUTE_POINT_MAXMP = 3, -- 按点数增加MP的上限
    IATTRIBUTE_RATE_MAXMP = 4, -- 按百分比增加MP的上限
    IATTRIBUTE_RESTORE_MP = 5, -- 加快MP的回复速度

    IATTRIBUTE_COLD_ATTACK = 6, -- 冰攻击
    IATTRIBUTE_COLD_RESIST = 7, -- 冰抵抗
    IATTRIBUTE_COLD_TIME = 8, -- 减少冰冻迟缓时间
    IATTRIBUTE_FIRE_ATTACK = 9, -- 火攻击
    IATTRIBUTE_FIRE_RESIST = 10, -- 火抵抗
    IATTRIBUTE_FIRE_TIME = 11, -- 减少火烧持续时间
    IATTRIBUTE_LIGHT_ATTACK = 12, -- 电攻击
    IATTRIBUTE_LIGHT_RESIST = 13, -- 电抵抗
    IATTRIBUTE_LIGHT_TIME = 14, -- 减少电击眩晕时间
    IATTRIBUTE_POISON_ATTACK = 15, -- 毒攻击
    IATTRIBUTE_POISON_RESIST = 16, -- 毒抵抗
    IATTRIBUTE_POISON_TIME = 17, -- 减少中毒时间
    IATTRIBUTE_RESIST_ALL = 18, -- 按百分比抵消所有属性攻击

    IATTRIBUTE_ATTACK_P = 19, -- 物理攻击
    IATTRIBUTE_RATE_ATTACK_P = 20, -- 按百分比增加物理攻击
    IATTRIBUTE_RATE_ATTACK_EP = 21, -- 对装备基础物理攻击百分比加成
    IATTRIBUTE_DEFENCE_P = 22, -- 物理防御
    IATTRIBUTE_RATE_DEFENCE_P = 23, -- 按百分比增加物理防御
    IATTRIBUTE_RATE_DEFENCE_EP = 24, -- 对装备基础物理防御百分比加成
    IATTRIBUTE_IMMUNITY_P = 25, -- 按百分比抵消物理伤害

    IATTRIBUTE_ATTACK_M = 26, -- 魔法攻击
    IATTRIBUTE_RATE_ATTACK_M = 27, -- 按百分比增加魔法攻击
    IATTRIBUTE_RATE_ATTACK_EM = 28, -- 对装备基础魔法攻击百分比加成
    IATTRIBUTE_DEFENCE_M = 29, -- 魔法防御
    IATTRIBUTE_RATE_DEFENCE_M = 30, -- 按百分比增加魔法防御
    IATTRIBUTE_RATE_DEFENCE_EM = 31, -- 对装备基础内功防御百分比加成
    IATTRIBUTE_IMMUNITY_M = 32, -- 按百分比抵消内功伤害

    IATTRIBUTE_ATTACK_SPEED = 33, -- 攻击速度
    IATTRIBUTE_SKILL_TIME = 34, -- 技能冷却速度

    IATTRIBUTE_HIT = 35, -- 命中
    IATTRIBUTE_MISS = 36, -- 闪避
    IATTRIBUTE_2ATTACK_RATE = 37, -- 会心一击（双倍攻击）的百分比
    IATTRIBUTE_NO_DEFENCE_RATE = 38, -- 无视对方防御的概率

    IATTRIBUTE_SPEED_RATE = 39, -- 移动速度百分比

    IATTRIBUTE_DAMAGE_RET = 40, -- 伤害反射
    IATTRIBUTE_DAMAGE2MANA = 41, -- 伤害由内力抵消

    IATTRIBUTE_STR = 42, -- 增加力量
    IATTRIBUTE_SPR = 43, -- 增加灵气
    IATTRIBUTE_CON = 44, -- 增加体制
    IATTRIBUTE_INT = 45, -- 增加定力
    IATTRIBUTE_DEX = 46, -- 增加身法
    IATTRIBUTE_LUK = 47, -- 增加悟性
    IATTRIBUTE_ALL = 48, -- 增加所有的人物一级属性

    IATTRIBUTE_HP_THIEVE = 49, -- 生命偷取(从伤害里)
    IATTRIBUTE_MP_THIEVE = 50, -- 内力偷取(从伤害里)

    IATTRIBUTE_2ATTACK_DEFENCE = 51, -- 会心防御
    -- IATTRIBUTE_MIND_DEFENT = 52, -- 增加某个随机技能
    -- IATTRIBUTE_MIND_DEFENT = 53, -- 随机技能发动概率

    IATTRIBUTE_REDUCE_TARGET_COLD_RESIST = 54, -- 忽略目标冰抗
    IATTRIBUTE_REDUCE_TARGET_FIRE_RESIST = 55, -- 忽略目标火抗
    IATTRIBUTE_REDUCE_TARGET_LIGHT_RESIST = 56, -- 忽略目标玄抗
    IATTRIBUTE_REDUCE_TARGET_POISON_RESIST = 57, -- 忽略目标毒抗
    IATTRIBUTE_BASE_ATTACK_P = 58, -- 基础外功攻击
    IATTRIBUTE_BASE_MAGIC_P = 59, -- 基础内功攻击
    IATTRIBUTE_BASE_DEFENCE_P = 60, -- 基础外功防御
    IATTRIBUTE_BASE_DEFENCE_M = 61, -- 基础内功防御
    IATTRIBUTE_BASE_HIT = 62, -- 基础命中
    IATTRIBUTE_BASE_MISS = 63, -- 基础闪避

    IATTRIBUTE_POINT_ADD_DAMAGE = 64, -- 按点数增加伤害
    IATTRIBUTE_POINT_REDUCE_DAMAGE = 65, -- 按点数减少伤害

    IATTRIBUTE_POINT_ATTACK_P_ATTACK_M = 165, -- 增加内外功攻击
    IATTRIBUTE_POINT_JIAN_SU_RESIST = 66, -- 概率免疫减速
    IATTRIBUTE_POINT_DIAN_XUE_RESIST = 67, -- 概率免疫封穴
    IATTRIBUTE_POINT_MA_BI_RESIST = 68, -- 概率免疫麻痹
    IATTRIBUTE_POINT_SAN_GONG_RESIST = 69, -- 概率免疫散功
    IATTRIBUTE_POINT_FENG_YIN_RESIST = 70, -- 概率免疫封印
    IATTRIBUTE_POINT_SHI_MING_RESIST = 71, -- 概率免疫失明
    IATTRIBUTE_POINT_ADD_DAMAGE_RATE = 72, -- 百分比增加伤害
    IATTRIBUTE_POINT_REDUCE_DAMAGE_RATE = 73, -- 百分比减少伤害

    IATTRIBUTE_RATE_BASE_HIT = 75, -- 百分比增加基础命中
    IATTRIBUTE_RATE_BASE_MISS = 76, -- 百分比增加基础闪避

    IATTRIBUTE_QIONGQI_MELTING_IMPACT = 77,
    IATTRIBUTE_JIUWEI_MELTING_ATTACK_PET_EXTRA_DAMAGE = 78,

    IATTRIBUTE_POINT_ADD_ATTACK_MAGIC_DAMAGE_RATE = 79,
    IATTRIBUTE_POINT_ADD_ATTACK_PHYSIC_DAMAGE_RATE = 80,
    IATTRIBUTE_POINT_ADD_ATTACK_COLD_DAMAGE_RATE = 81,
    IATTRIBUTE_POINT_ADD_ATTACK_FIRE_DAMAGE_RATE = 82,
    IATTRIBUTE_POINT_ADD_ATTACK_LIGHT_DAMAGE_RATE = 83,
    IATTRIBUTE_POINT_ADD_ATTACK_POISION_DAMAGE_RATE = 84,

    IATTRIBUTE_POINT_ADD_MAGIC_DEFENCE_RATE = 85,
    IATTRIBUTE_POINT_ADD_PHYSIC_DEFENCE_RATE = 86,
    IATTRIBUTE_POINT_ADD_COLD_DEFENCE_RATE = 87,
    IATTRIBUTE_POINT_ADD_FIRE_DEFENCE_RATE = 88,
    IATTRIBUTE_POINT_ADD_LIGHT_DEFENCE_RATE = 89,
    IATTRIBUTE_POINT_ADD_POISION_DEFENCE_RATE = 90,

    IATTRIBUTE_PET_EQUIP_SET_STD_IMPACT = 100, -- 宠物套装buff       

    IATTRIBUTE_RATE_STR_PERCEPTION = 201, -- 按点数增加力量资质
    IATTRIBUTE_RATE_SPR_PERCEPTION = 202, -- 按点数增加灵气资质
    IATTRIBUTE_RATE_CON_PERCEPTION = 203, -- 按点数增加体力资质
    IATTRIBUTE_RATE_DEX_PERCEPTION = 204, -- 按点数增加定力资质
    IATTRIBUTE_RATE_INT_PERCEPTION = 205, -- 按点数增加身法资质

    IATTRIBUTE_EQUIP_STD_IMPACT = 300,
    IATTRIBUTE_EQUIP_WEAPON_STD_IMPACT = 300 + define.HUMAN_EQUIP.HEQUIP_WEAPON, -- 武器技能效果
    IATTRIBUTE_EQUIP_NECKLACE_STD_IMPACT = 300 +
        define.HUMAN_EQUIP.HEQUIP_NECKLACE, -- 项链技能效果
    IATTRIBUTE_EQUIP_RING_1_STD_IMPACT = 300 + define.HUMAN_EQUIP.HEQUIP_RING_1, -- 戒指1技能效果
    IATTRIBUTE_EQUIP_RING_2_STD_IMPACT = 300 + define.HUMAN_EQUIP.HEQUIP_RING_2, -- 项链技能效果
    IATTRIBUTE_EQUIP_AMULET_1_STD_IMPACT = 300 +
        define.HUMAN_EQUIP.HEQUIP_AMULET_1, -- 戒指1技能效果
    IATTRIBUTE_EQUIP_AMULET_2_STD_IMPACT = 300 +
        define.HUMAN_EQUIP.HEQUIP_AMULET_2 -- 项链技能效果
}

define.PET_SOUL_EXTENSION_2_IA = {
    [0] = define.ITEM_ATTRIBUTE.IATTRIBUTE_POINT_MAXHP,
    [1] = define.ITEM_ATTRIBUTE.IATTRIBUTE_STR,
    [2] = define.ITEM_ATTRIBUTE.IATTRIBUTE_SPR,
    [3] = define.ITEM_ATTRIBUTE.IATTRIBUTE_CON,
    [4] = define.ITEM_ATTRIBUTE.IATTRIBUTE_INT,
    [5] = define.ITEM_ATTRIBUTE.IATTRIBUTE_DEX,
    [6] = define.ITEM_ATTRIBUTE.IATTRIBUTE_POINT_ATTACK_P_ATTACK_M,
    [7] = define.ITEM_ATTRIBUTE.IATTRIBUTE_HIT,
    [8] = define.ITEM_ATTRIBUTE.IATTRIBUTE_MISS,
    [9] = define.ITEM_ATTRIBUTE.IATTRIBUTE_2ATTACK_RATE,
    [10] = define.ITEM_ATTRIBUTE.IATTRIBUTE_LUK,
    [11] = define.ITEM_ATTRIBUTE.IATTRIBUTE_COLD_RESIST,
    [12] = define.ITEM_ATTRIBUTE.IATTRIBUTE_FIRE_RESIST,
    [13] = define.ITEM_ATTRIBUTE.IATTRIBUTE_LIGHT_RESIST,
    [14] = define.ITEM_ATTRIBUTE.IATTRIBUTE_POISON_RESIST,

    [15] = define.ITEM_ATTRIBUTE.IATTRIBUTE_POINT_JIAN_SU_RESIST,
    [16] = define.ITEM_ATTRIBUTE.IATTRIBUTE_POINT_DIAN_XUE_RESIST,
    [17] = define.ITEM_ATTRIBUTE.IATTRIBUTE_POINT_MA_BI_RESIST,
    [18] = define.ITEM_ATTRIBUTE.IATTRIBUTE_POINT_SAN_GONG_RESIST,

    [19] = define.ITEM_ATTRIBUTE.IATTRIBUTE_POINT_FENG_YIN_RESIST,
    [20] = define.ITEM_ATTRIBUTE.IATTRIBUTE_POINT_SHI_MING_RESIST,

    [21] = define.ITEM_ATTRIBUTE.IATTRIBUTE_POINT_REDUCE_DAMAGE,
    [22] = define.ITEM_ATTRIBUTE.IATTRIBUTE_POINT_ADD_DAMAGE,
}

define.KFS_EXT_ATTR_VALUE_RATE = {
    [1] = 1,
    [2] = 1.902857142857143,
    [3] = 2.697297297297297,
    [4] = 3.375634517766497,
    [5] = 3.967142857142857,
    [6] = 4.435555555555556,
    [7] = 4.8176
}

define.CHN_ATTR_SHIFT = {
    [define.ITEM_ATTRIBUTE.IATTRIBUTE_ALL] = "增加所有的人物一级属性",
    [define.ITEM_ATTRIBUTE.IATTRIBUTE_RATE_MAXHP] = "百分比增加HP的上限",
    [define.ITEM_ATTRIBUTE.IATTRIBUTE_RATE_MAXMP] = "百分比增加MP的上限",
	
	
    [define.ITEM_ATTRIBUTE.IATTRIBUTE_STR] = "力量",
    [define.ITEM_ATTRIBUTE.IATTRIBUTE_SPR] = "灵气",
    [define.ITEM_ATTRIBUTE.IATTRIBUTE_CON] = "体力",
    [define.ITEM_ATTRIBUTE.IATTRIBUTE_INT] = "定力",
    [define.ITEM_ATTRIBUTE.IATTRIBUTE_DEX] = "身法",

    [define.ITEM_ATTRIBUTE.IATTRIBUTE_ATTACK_P] = "外功攻击",
    [define.ITEM_ATTRIBUTE.IATTRIBUTE_ATTACK_M] = "内功攻击",
    [define.ITEM_ATTRIBUTE.IATTRIBUTE_DEFENCE_P] = "外功防御",
    [define.ITEM_ATTRIBUTE.IATTRIBUTE_DEFENCE_M] = "内功防御",

    [define.ITEM_ATTRIBUTE.IATTRIBUTE_POINT_MAXHP] = "增加HP的上限",
    [define.ITEM_ATTRIBUTE.IATTRIBUTE_POINT_MAXMP] = "增加MP的上限",

    [define.ITEM_ATTRIBUTE.IATTRIBUTE_COLD_ATTACK] = "冰攻击",
    [define.ITEM_ATTRIBUTE.IATTRIBUTE_COLD_RESIST] = "冰抵抗",
    [define.ITEM_ATTRIBUTE.IATTRIBUTE_REDUCE_TARGET_COLD_RESIST] = "降低目标冰抵抗",

    [define.ITEM_ATTRIBUTE.IATTRIBUTE_FIRE_ATTACK] = "火攻击",
    [define.ITEM_ATTRIBUTE.IATTRIBUTE_FIRE_RESIST] = "火抵抗",
    [define.ITEM_ATTRIBUTE.IATTRIBUTE_REDUCE_TARGET_FIRE_RESIST] = "降低目标火抵抗",

    [define.ITEM_ATTRIBUTE.IATTRIBUTE_LIGHT_ATTACK] = "玄攻击",
    [define.ITEM_ATTRIBUTE.IATTRIBUTE_LIGHT_RESIST] = "玄抵抗",
    [define.ITEM_ATTRIBUTE.IATTRIBUTE_REDUCE_TARGET_LIGHT_RESIST] = "降低目标玄抵抗",

    [define.ITEM_ATTRIBUTE.IATTRIBUTE_POISON_ATTACK] = "毒攻击",
    [define.ITEM_ATTRIBUTE.IATTRIBUTE_POISON_RESIST] = "毒抵抗",
    [define.ITEM_ATTRIBUTE.IATTRIBUTE_REDUCE_TARGET_POISON_RESIST] = "降低目标毒抵抗",

    [define.ITEM_ATTRIBUTE.IATTRIBUTE_COLD_TIME] = "降低目标冰抵抗下限",
    [define.ITEM_ATTRIBUTE.IATTRIBUTE_FIRE_TIME] = "降低目标火抵抗下限",
    [define.ITEM_ATTRIBUTE.IATTRIBUTE_LIGHT_TIME] = "降低目标玄抵抗下限",
    [define.ITEM_ATTRIBUTE.IATTRIBUTE_POISON_TIME] = "降低目标毒抵抗下限",

    [define.ITEM_ATTRIBUTE.IATTRIBUTE_HIT] = "命中",
    [define.ITEM_ATTRIBUTE.IATTRIBUTE_MISS] = "闪避",
    [define.ITEM_ATTRIBUTE.IATTRIBUTE_2ATTACK_RATE] = "会心",
    [define.ITEM_ATTRIBUTE.IATTRIBUTE_LUK] = "会心防御",

    [define.ITEM_ATTRIBUTE.IATTRIBUTE_BASE_HIT] = "基础命中",
    [define.ITEM_ATTRIBUTE.IATTRIBUTE_BASE_MISS] = "基础闪避",

    [define.ITEM_ATTRIBUTE.IATTRIBUTE_2ATTACK_DEFENCE] = "会心防御"
}

define.EQUIP_BASE_ATTRIB = {
    ["基础外功攻击"] = define.ITEM_ATTRIBUTE.IATTRIBUTE_BASE_ATTACK_P,
    ["基础内功攻击"] = define.ITEM_ATTRIBUTE.IATTRIBUTE_BASE_MAGIC_P,
    ["基础外功防御"] = define.ITEM_ATTRIBUTE.IATTRIBUTE_BASE_DEFENCE_P,
    ["基础内功防御"] = define.ITEM_ATTRIBUTE.IATTRIBUTE_BASE_DEFENCE_M,
    ["基础命中"] = define.ITEM_ATTRIBUTE.IATTRIBUTE_BASE_HIT,
    ["基础闪避"] = define.ITEM_ATTRIBUTE.IATTRIBUTE_BASE_MISS
}

define.EQUIP_BASE_ATTR_BASE_ATTR_RATE = {
    [define.ITEM_ATTRIBUTE.IATTRIBUTE_BASE_ATTACK_P] = define.ITEM_ATTRIBUTE
        .IATTRIBUTE_RATE_ATTACK_EP,
    [define.ITEM_ATTRIBUTE.IATTRIBUTE_BASE_MAGIC_P] = define.ITEM_ATTRIBUTE
        .IATTRIBUTE_RATE_ATTACK_EM,
    [define.ITEM_ATTRIBUTE.IATTRIBUTE_BASE_DEFENCE_P] = define.ITEM_ATTRIBUTE
        .IATTRIBUTE_RATE_DEFENCE_EP,
    [define.ITEM_ATTRIBUTE.IATTRIBUTE_BASE_DEFENCE_M] = define.ITEM_ATTRIBUTE
        .IATTRIBUTE_RATE_DEFENCE_EM,
    [define.ITEM_ATTRIBUTE.IATTRIBUTE_BASE_HIT] = define.ITEM_ATTRIBUTE
        .IATTRIBUTE_RATE_BASE_HIT,
    [define.ITEM_ATTRIBUTE.IATTRIBUTE_BASE_MISS] = define.ITEM_ATTRIBUTE
        .IATTRIBUTE_RATE_BASE_MISS
}

define.MISS_FLAG = {
    FLAG_NORMAL = 0,
    FLAG_MISS = 1,
    FLAG_IMMU = 2,
    FLAG_ABSORB = 3,
    FLAG_COUNTERACT = 4,
    FLAG_TRANSFERED = 5
}

define.SETTING_MENPAI_SKILLID = {
	[0] = {281,291,295},
	[1] = {311,321,325},
	[2] = {341,351,355},
	[3] = {371,381,385},
	[4] = {401,404,415},
	[5] = {431,441,445},
	[6] = {461,471,475},
	[7] = {491,501,505},
	[8] = {521,522,535},
--9是无门派
	[10] = {760,771,775}, -- CS3b: 慕容 CY (柳拂衣/重云掩日/剑锁江山, GL đã dùng đúng ID CY cho 曼陀)
	[16] = {}, -- CS3b: 曼陀 tắt
	[15] = {4622,4633,4637}, -- CS3b: 恶人谷, ID CY

}

define.SETTING_TYPE = {
    SETTING_TYPE_NONE = 0,
    SETTING_TYPE_GAME = 1, -- 联系人设置, bit含义见 enum GAME_SETTING_FLAG
    SETTING_TYPE_K0 = 2, -- 0号快捷栏设置
    SETTING_TYPE_K1 = 3, -- 1号快捷栏设置
    SETTING_TYPE_K2 = 3, -- 2号快捷栏设置
    SETTING_TYPE_K3 = 4, -- 3号快捷栏设置
    SETTING_TYPE_K4 = 5, -- 4号快捷栏设置
    SETTING_TYPE_K5 = 6, -- 5号快捷栏设置
    SETTING_TYPE_K6 = 7, -- 6号快捷栏设置
    SETTING_TYPE_K7 = 8, -- 7号快捷栏设置
    SETTING_TYPE_K8 = 9, -- 8号快捷栏设置
    SETTING_TYPE_K9 = 10, -- 9号快捷栏设置
    SETTING_TYPE_K10 = 11, -- 右边0号快捷栏设置
    SETTING_TYPE_K11 = 12, -- 右边1号快捷栏设置
    SETTING_TYPE_K12 = 13, -- 右边2号快捷栏设置
    SETTING_TYPE_K13 = 14, -- 右边3号快捷栏设置
    SETTING_TYPE_K14 = 15, -- 右边4号快捷栏设置
    SETTING_TYPE_K15 = 16, -- 右边5号快捷栏设置
    SETTING_TYPE_K16 = 17, -- 右边6号快捷栏设置
    SETTING_TYPE_K17 = 18, -- 右边7号快捷栏设置
    SETTING_TYPE_K18 = 19, -- 右边8号快捷栏设置
    SETTING_TYPE_K19 = 20, -- 右边9号快捷栏设置

    SETTING_TYPE_CHAT_TAB1_PART1 = 21, -- 聊天自定义tab1设置第一部分
    SETTING_TYPE_CHAT_TAB1_PART2 = 22, -- 聊天自定义tab1设置第二部分
    SETTING_TYPE_CHAT_TAB2_PART1 = 23, -- 聊天自定义tab2设置第一部分
    SETTING_TYPE_CHAT_TAB2_PART2 = 24, -- 聊天自定义tab2设置第二部分
    SETTING_TYPE_CHAT_TAB3_PART1 = 25, -- 聊天自定义tab3设置第一部分
    SETTING_TYPE_CHAT_TAB3_PART2 = 26, -- 聊天自定义tab3设置第二部分
    SETTING_TYPE_CHAT_TAB4_PART1 = 27, -- 聊天自定义tab4设置第一部分
    SETTING_TYPE_CHAT_TAB4_PART2 = 28, -- 聊天自定义tab4设置第二部分

    SETTING_TYPE_SHOW_OR_HIDE_TITLE = 94,
}

define.ENUM_CHARACTER_LOGIC = {
    CHARACTER_LOGIC_INVALID = -1,
    CHARACTER_LOGIC_IDLE = 0,
    CHARACTER_LOGIC_MOVE = 1,
    CHARACTER_LOGIC_USE_SKILL = 2,
    -- CHARACTER_LOGIC_DEAD,
    -- CHARACTER_LOGIC_SIT,
    CHARACTER_LOGIC_USE_ABILITY = 3, -- 使用生活技能
    CHARACTER_LOGIC_FLY = 4
}

define.MissFlag_T = {
    FLAG_NORMAL = 0,
    FLAG_MISS = 1,
    FLAG_IMMU = 2,
    FLAG_ABSORB = 3,
    FLAG_COUNTERACT = 4,
    FLAG_TRANSFERED = 5
}

define.ENUM_DIE_RESULT_CODE = {
    DIE_RESULT_CODE_INVALID = -1,
    DIE_RESULT_CODE_OUT_GHOST = 0, -- 释放灵魂
    DIE_RESULT_CODE_RELIVE = 1, -- 接受复活
    DIE_RESULT_CODE_NEW_PLAYER = 2, -- 接受复活
    DIE_RESULT_CODE_NUMBERS = 3
}

define.ENUM_CALLOF_RESULT_CODE = {
    CALLOF_RESULT_CODE_INVALID = -1,
    CALLOF_RESULT_CODE_ACCEPT = 0, -- 接受
    CALLOF_RESULT_CODE_REFUSE = 1, -- 拒绝
    CALLOF_RESULT_CODE_NUMBERS = 2
}

define.ENUM_SELECT_TYPE = {
    SELECT_TYPE_INVALID = -1,
    SELECT_TYPE_NONE = 0, -- 无需选择
    SELECT_TYPE_CHARACTER = 1, -- 角色
    SELECT_TYPE_POS = 2, -- 位置
    SELECT_TYPE_DIR = 3, -- 方向
    SELECT_TYPE_SELF = 4, -- 对自己进行操作
    SELECT_TYPE_HUMAN_GUID = 5, -- 玩家
    SELECT_TYPE_NUMBERS = 6
}

define.ITEMBOX_TYPE = {ITYPE_DROPBOX = -1, ITYPE_GROWPOINT = 0}

define.ITEM_DATA_TYPE = {IDT_ITEM = 0, IDT_PET = 1}

define.ITEM_OPERATOR_ERROR = -- 此枚举结构内的数据必须都为负数
{
    ITEMOE_SUCCESS = 0, -- 成功
    ITEMOE_UNKNOW = -1, -- 未知的异常错误
    ITEMOE_DESTOPERATOR_HASITEM = -2, -- 容器的目标位置已经有物品了
    ITEMOE_SOUROPERATOR_LOCK = -3, -- 源容器中的物品被上锁了
    ITEMOE_DESTOPERATOR_LOCK = -4, -- 目标容器中的物品被上锁了
    ITEMOE_DESTOPERATOR_FULL = -5, -- 目标容器已经满了
    ITEMOE_SOUROPERATOR_EMPTY = -6, -- 源容器里的物品是空的
    ITEMOE_DESTOPERATOR_EMPTY = -7, -- 目标容器的物品是空的
    ITEMOE_CREATEITEM_FAIL = -8, -- 物品产生失败
    ITEMOE_CREATEGUID_FAIL = -9, -- 物品GUID创建失败
    ITEMOE_DIFF_ITEM_DATA = -10 -- 不同类型物品数据不能操作

}

define.ITEM_RULER_LIST = {
    IRL_DISCARD = 0, -- 丢弃
    IRL_TILE = 1, -- 重叠
    IRL_SHORTCUT = 2, -- 快捷
    IRL_CANSELL = 3, -- 出售
    IRL_CANEXCHANGE = 4, -- 交易
    IRL_CANUSE = 5, -- 使用
    IRL_PICKBIND = 6, -- 拾取绑定
    IRL_EQUIPBIND = 7, -- 装备绑定
    IRL_UNIQUE = 8, -- 是否唯一
    IRL_NEED_IDENT = 10 -- 是否需要鉴定
}

define.EQUIP_QUALITY = {
    EQUIP_QUALITY = 0,
    EQUALITY_NORMAL = 1, -- 普通百色装备
    EQUALITY_BLUE = 2, -- 蓝色装备
    EQUALITY_YELLOW = 3, -- 黄色装备
    EQUALITY_GREEN = 4, -- 绿色套装
    EQUALITY_NUMBER = 5 -- 装备品质数量
}

define.ANQI_ATTR = {"力量", "灵气", "体力", "定力", "身法"}

define.ANQI_SKILL = {
    [40] = {id = 274, index = 1},
    [70] = {id = 275, index = 2},
    [90] = {id = 276, index = 3}
}

define.MAX_CHAR_SKILL_LEVEL = 12
define.MIN_ACTION_TIME = 50
define.INVAILD_ID = -1
define.MAX_IMPACT_NUM = 60
define.Exterior_Type = {Face = 1, Hair = 2, Head = 3, Ride = 4, Poss = 5, WeaponVisual = 8}
define.Exterior_Tbpos_Reset = 8421504
define.Exterior_Tbpos_Min = 0
define.Exterior_Tbpos_Max = 16777215

define.IMPACT_FEATURE_LPC = {
	[40] = {27,32},
	[47] = {28,33},
	[42] = {29,34},
	[72] = {30,35},
	[44] = {31,36},
}

define.EQUIP_ATTR = {
    ["增加HP的上限"] = 0,
    ["百分比增加HP的上限"] = 1,
    ["加快HP的回复速度"] = 2,
    ["增加MP的上限"] = 3,
    ["百分比增加MP的上限"] = 4,
    ["加快MP的回复速度"] = 5,
    ["冰攻击"] = 6,
    ["冰抵抗"] = 7,
    ["减少冰冻迟缓时间"] = 8,
    ["火攻击"] = 9,
    ["火抵抗"] = 10,
    ["减少火烧持续时间"] = 11,
    ["玄攻击"] = 12,
    ["玄抵抗"] = 13,
    ["减少玄击眩晕时间"] = 14,
    ["毒攻击"] = 15,
    ["毒抵抗"] = 16,
    ["减少中毒时间"] = 17,
    ["按百分比抵消所有属性攻击"] = 18,
    ["外功攻击"] = 19,
    ["按百分比增加外功攻击"] = 20,
    ["对装备基础外功攻击百分比加成"] = 21,
    ["外功防御"] = 22,
    ["按百分比增加外功防御"] = 23,
    ["对装备基础外功防御百分比加成"] = 24,
    ["按百分比抵消外功伤害"] = 25,
    ["内功攻击"] = 26,
    ["按百分比增加内功攻击"] = 27,
    ["对装备基础内功攻击百分比加成"] = 28,
    ["内功防御"] = 29,
    ["按百分比增加内功防御"] = 30,
    ["对装备基础内功防御百分比加成"] = 31,
    ["按百分比抵消内功伤害"] = 32,
    ["攻击速度(两次攻击间隔时间)"] = 33,
    ["内功冷却速度"] = 34,
    ["命中"] = 35,
    ["闪避"] = 36,
    ["会心"] = 37,
    ["无视对方防御比率"] = 38,
    ["移动速度百分比"] = 39,
    ["伤害反射"] = 40,
    ["伤害由内力抵消"] = 41,
    ["力量"] = 42,
    ["灵气"] = 43,
    ["体力"] = 44,
    ["定力"] = 45,
    ["身法"] = 46,
    ["会心防御"] = 47,
    ["增加所有的人物一级属性"] = 48,
    ["生命偷取"] = 49,
    ["内力偷取"] = 50,
    ["增加某个技能等级"] = 51,
    ["增加所有技能等级"] = 52,
    ["特殊技能发动概率"] = 53,
    ["降低目标冰抵抗"] = 54,
    ["降低目标火抵抗"] = 55,
    ["降低目标玄抵抗"] = 56,
    ["降低目标毒抵抗"] = 57,

    ["降低目标冰抵抗下限"] = 8,
    ["降低目标火抵抗下限"] = 11,
    ["降低目标玄抵抗下限"] = 14,
    ["降低目标毒抵抗下限"] = 17
}

define.MONSTER_AI_PRAM = {
    AIPARAM_SCANTIME = "AIPARAM0", -- 如果此值大于0，则为主动攻击，值的含义就是扫描间隔 如果小于等于0，则为非主动攻击
    AIPARAM_RANDMOVETIME = "AIPARAM1", -- 随机移动位置的时间间隔（毫秒）
    AIPARAM_CANNOTATTACK = "AIPARAM2", -- 无法攻击的对象(已经废弃, 是否无敌是以MonsterAttrExTable.txt表中为主)
    AIPARAM_RETURN = "AIPARAM3", -- 如果此值大于0，则当怪物距离出生地大于此值时，怪物放弃追赶
    AIPARAM_SCANENEMYDIST = "AIPARAM4", -- 扫描敌人的最大距离
    AIPARAM_SCANTEAMMATEDIST = "AIPARAM5", -- 扫描队友的最大距离
    AIPARAM_RESETTARGET_DIST = "AIPARAM6", -- 如果当前的移动目标和敌人的位置之间的距离大于此数值 则需要重新设定移动目标
    AIPARAM_PATROLTIME = "AIPARAM7", -- 巡逻的时间间隔，若小于等于0，则不进行巡逻
    AIPARAM_STRIKEBACK = "AIPARAM8" -- 是否会还击
}

define.ENUM_STATE = {
    -- common state
    ESTATE_INVALID = -1,
    ESTATE_IDLE = 0,
    ESTATE_DEAD = 1,
    ESTATE_TERROR = 2,
    -- monster state
    ESTATE_APPROACH = 3,
    ESTATE_SERVICE = 4,
    ESTATE_GOHOME = 5,
    ESTATE_COMBAT = 6,
    ESTATE_PATROL = 7,
    ESTATE_FLEE = 8,
    -- human state
    ESTATE_SIT = 9,
    ESTATE_TEAMFOLLOW = 10,
    ESTATE_STALL = 11,
    ESTATE_BY_BUS = 12,

    ESTATE_NUMBER = 13
};

define.ENUM_AISTATE = {
    SIDLE = define.ENUM_STATE.ESTATE_IDLE, -- 空闲状态
    SAPPROACH = define.ENUM_STATE.ESTATE_APPROACH, -- 靠近状态
    SATTACK = define.ENUM_STATE.ESTATE_COMBAT, -- 攻击状态
    SFOLLOW = define.ENUM_STATE.ESTATE_TEAMFOLLOW, -- 跟随状态
    SRETURN = define.ENUM_STATE.ESTATE_GOHOME, -- 放弃追赶
    SPATROL = define.ENUM_STATE.ESTATE_PATROL, -- 巡逻	
    SFLEE = define.ENUM_STATE.ESTATE_FLEE, -- 逃跑状态

    SKILLSECTION = define.ENUM_STATE.ESTATE_NUMBER + 1, -- 技能段
    ONBESKILLSECTION = define.ENUM_STATE.ESTATE_NUMBER + 2, -- 被攻击段
    ONDAMAGESECTION = define.ENUM_STATE.ESTATE_NUMBER + 3, -- 受到伤害段
    ONDEADSECTION = define.ENUM_STATE.ESTATE_NUMBER + 4 -- 死亡段
}

define.E_COMMAND_TYPE = {
    E_COMMAND_TYPE_INVALID = -1,
    E_COMMAND_TYPE_TOIDLE = 0,
    E_COMMAND_TYPE_TOFLEE = 1,
    E_COMMAND_TYPE_TOATTACK = 2,

    E_COMMAND_TYPE_NUM = 3
}

define.ENUM_MENPAI_CHN = {
    [0] = "少林",
    [1] = "明教",
    [2] = "丐帮",
    [3] = "武当",
    [4] = "峨嵋",
    [5] = "星宿",
    [6] = "大理",
    [7] = "天山",
    [8] = "逍遥",
    [9] = "无门派",
    [16] = "曼陀" , -- CS3b: tắt
	[15] = "恶人谷",
    [10] = "慕容",
}

define.ENUM_SELECT_TYPE = {
    SELECT_TYPE_INVALID = -1,
    SELECT_TYPE_NONE = 0, -- 无需选择
    SELECT_TYPE_CHARACTER = 1, -- 角色
    SELECT_TYPE_POS = 2, -- 位置
    SELECT_TYPE_DIR = 3, -- 方向
    SELECT_TYPE_SELF = 4, -- 对自己进行操作
    SELECT_TYPE_HUMAN_GUID = 4, -- 玩家
    SELECT_TYPE_NUMBERS = 5
}

define.CollectionIdType = {
    TYPE_BUFF_ID = 0,
    TYPE_IMPACT_MUTEX_ID = 1,
    TYPE_IMPACT_LOGIC_ID = 2,
    TYPE_SKILL_ID = 3,
    TYPE_SKILL_LOGIC_ID = 4,
    TYPE_DIRECT_IMPACT_ID = 5
}

define.AbilityClass = {
    ABILITY_CLASS_INVALID = -1, -- 非法
    ABILITY_CLASS_NOUSE = 0, -- 占位技能
    ABILITY_CLASS_COOKING = 1, -- 烹饪
    ABILITY_CLASS_PHARMACY = 2, -- 制药
    ABILITY_CLASS_INLAY = 3, -- 镶嵌
    ABILITY_CLASS_FOUNDRY = 4, -- 铸造
    ABILITY_CLASS_TAILOR = 5, -- 缝纫
    ABILITY_CLASS_ARTWORK = 6, -- 工艺
    ABILITY_CLASS_GATHERMINE = 7, -- 采矿
    ABILITY_CLASS_GATHERMEDIC = 8, -- 采药
    ABILITY_CLASS_FISH = 9, -- 钓鱼
    ABILITY_CLASS_PLANT = 10, -- 种植
    ABILITY_CLASS_SHAOLINDRUG = 11, -- 少林制药（开光）
    ABILITY_CLASS_HOLYFIRE = 12, -- 明教（圣火术）
    ABILITY_CLASS_BREWING = 13, -- 丐帮（酿酒）
    ABILITY_CLASS_THICKICE = 14, -- 天山（玄冰术）
    ABILITY_CLASS_INSECTCULTURING = 15, -- 大理（制蛊）
    ABILITY_CLASS_POISON = 16, -- 星宿（制毒）
    ABILITY_CLASS_INCANTATION = 17, -- 峨嵋（制符）
    ABILITY_CLASS_ALCHEMY = 18, -- 武当（炼丹）
    ABILITY_CLASS_THAUMATURGY = 19, -- 逍遥（奇门遁甲）
    ABILITY_CLASS_ENGINEERING = 20, -- 工程学
    ABILITY_CLASS_FIGHTGHOST = 21, -- 驱鬼
    ABILITY_CLASS_SEARCHTSTORE = 22, -- 挖宝
    ABILITY_CLASS_TRADE = 23, -- 跑商
    ABILITY_CLASS_HAGGLE = 24, -- 杀价
    ABILITY_CLASS_EXCESSPROFIT = 25, -- 热卖
    ABILITY_CLASS_PROCESSING = 26, -- 处理用到的进度条
    ABILITY_CLASS_PHARMACOLOGY = 27, -- 药理
    ABILITY_CLASS_REGIMEN = 28, -- 养生法
    ABILITY_CLASS_BUDDHOLOGY = 29, -- 佛法
    ABILITY_CLASS_FIREMAKING = 30, -- 采火术
    ABILITY_CLASS_BEGSKILL = 31, -- 莲花落
    ABILITY_CLASS_ICEMAKING = 32, -- 采冰术
    ABILITY_CLASS_VENATIONFORMULA = 33, -- 经脉百诀
    ABILITY_CLASS_INSECTENTICING = 34, -- 引虫术
    ABILITY_CLASS_MENTALTELEPATHY = 35, -- 灵心术
    ABILITY_CLASS_TAOISM = 36, -- 道法
    ABILITY_CLASS_BODYBUILDING = 37, -- 六艺风骨
    ABILITY_CLASS_DINGWEIFU = 39,

    ABILITY_CLASS_REFOUNDRY = 46, -- 精炼
    ABILITY_CLASS_RETAILOR = 47, -- 精制
    ABILITY_CLASS_REARTWORK = 48, -- 精工

    ABILITY_CLASS_GUILD_GATHERMINE = 51, -- 帮会宣战采矿

    ABILITY_CLASS_LINGWU_1 = 54, --天鉴铸法·无忌
    ABILITY_CLASS_LINGWU_2 = 55, --天鉴铸法·守心
    ABILITY_CLASS_LINGWU_3 = 56,  --天鉴铸法·破阵

    ABILITY_CLASS_NEWPENGREN = 59,
    ABILITY_CLASS_NEWZHIYAO = 60,
    ABILITY_CLASS_GONGJVXILIAN = 61,
    ABILITY_CLASS_GONGCHENG = 62,
    ABILITY_CLASS_NEW_CAIYAO = 63,
    ABILITY_CLASS_NEW_CAIKUANG = 64,
}

define.COMMON_ITEM_TYPE = {
    COMMON_ITEM_TYPE = 0,
    COMITEM_COIDENT = 5, -- 通用鉴定卷轴
    COMITEM_WPIDENT = 6, -- 武器鉴定卷轴
    COMITEM_ARIDENT = 7, -- 防具鉴定卷轴
    COMITEM_NCIDENT = 8 -- 项链鉴定卷轴
}

define.COMMON_ITEM_QUAL = {
    COMITEM_QUAL_MIS = 5 -- 杂物
}

define.USEITEM_RESULT = {
    USEITEM_SUCCESS = 0,
    USEITEM_CANNT_USE = 1,
    USEITEM_LEVEL_FAIL = 2,
    USEITEM_TYPE_FAIL = 3,
    USEITEM_TARGET_TYPE_FAIL = 4,
    USEITEM_SKILL_FAIL = 5,
    USEITEM_IDENT_TYPE_FAIL = 6, -- 卷轴类型错误
    USEITEM_IDENT_TARGET_TYPE_FAIL = 7, -- 目标类型错误
    USEITEM_IDENT_LEVEL_FAIL = 8, -- 卷轴等级不够

    USEITEM_INVALID = 9
}

define.DISCARDITEM_RESULT = {DISCARDITEM_SUCCESS = 0, DISCARDITEM_FAIL = 1}



define.RAID_ERROR = {
	RAID_ERROR_INVITEDESTHASRAID=0 ,		--邀请对象已经加入一个团队
	RAID_ERROR_INVITEDHASINRAID=1,			--您邀请的玩家已经在您的团队中
	RAID_ERROR_INVITEDTARGETNOTONLINE=2,		--您只能邀请在线的玩家加入团队
	RAID_ERROR_RAID_NOTEXIST_OR_LEADEROUT=3,	--该团队已解散，或团长已离团。
	RAID_ERROR_INVITEREFUSE=4,				--对方拒绝了你的邀请
	RAID_ERROR_FULL=5,						--团队已满。
	RAID_ERROR_FULL_CANTINVITE=6,				--团队已满，无法加入新成员。

	RAID_RESERVER=7,

	RAID_ERROR_KICKNOTLEADER=8,				--只有团长或助理才能踢人
	RAID_ERROR_KICKLEADER=9,					--不能请离团长！
	RAID_ERROR_KICK_ASSISTANT=10,				--不能请离和你同职位的助理！	

	RAID_ERROR_TARGET_IN_OTHERRAID=11,			--对方已经加入一个团队
	RAID_ERROR_TARGET_NOT_IN_RAID=12,			--对方不属于某个团队
	RAID_ERROR_APPLYLEADERREFUSE=13,			--团长拒绝你加入团队
	RAID_ERROR_APPLY_FULL=14,					--团队已满。
	RAID_ERROR_APPOINTSOURNOLEADER=15,			--团长已换人，请重新申请入团。	
	RAID_ERROR_NOT_IN_RAID=16,					--你不在团队中。
	RAID_ERROR_TARGET_NOT_IN_YOUR_RAID=17,		--对方不在你的团队中。	
	RAID_ERROR_TARGET_NOT_IN_YOUR_RAID_2=18,	--对方不在你的团队中。	
	RAID_ERROR_NOT_LEADER=19,					--你已不是团长了。	
	RAID_ERROR_ASSISTANT_MAX=20,				--团长助理的名额最多为2人，无法继续任命团长助理。	
	RAID_ERROR_APPOINT_FAIL=21,				--任命失败
	RAID_ERROR_APPLYLEADERCANTANSWER=22,		--团长目前无法答复

	RAID_RESERVER_2=23,
	RAID_RESERVER_3=24,
	RAID_ERROR_FULL_CANTAPPLY=25,				--团队已满，无法加入新成员。
	RAID_ERROR_TARGETNOTONLINE=26,				--对方已经离线，加入失败。
	RAID_ERROR_APPLYTOOMUCH=27,				--已有太多人向该玩家提出了申请入团，请稍等。
	RAID_ERROR_INVITETOOMUCH=28,				--已有太多人向该玩家提出了入团邀请，请稍等。
	RAID_ERROR_APPLYALREADYIN=29,				--你已经对该玩家提出了申请入团，请稍等。
	RAID_ERROR_INVITEALREADYIN=30,				--你已经对该玩家提出了入团邀请，请稍等。
	RAID_ERROR_ADDMEMFAILED=31,				--申请入队的玩家处于异常状态，添加团员失败！
	RAID_ERROR_ADDMEMFAILED_INVITEERR=32,		--邀请人异常，加入团队失败
	RAID_ERROR_CHANGE_POISTION_1=33,			--调整团员位置失败。
	RAID_ERROR_CHANGE_POISTION_2=34,			--调整团员位置失败。
	RAID_ERROR_CHANGE_POISTION_3=35,			--调整团员位置失败。
	RAID_ERROR_CHANGE_POISTION_4=36,			--调整团员位置失败。

	RAID_RESERVER_4=37,
	RAID_RESERVER_5=38,
	RAID_RESERVER_6=39,
	RAID_RESERVER_7=40,
	RAID_RESERVER_8=41,					--你已经加入一支队伍了
	RAID_ERROR_NUMBER=42,				--对方已经加入一支队伍了
}

define.RAID_EVENT_ID = {
	RAID_EVENT_CREATE = 0,				--转为团队
	RAID_EVENT_ADD_NEWMEM = 1,			--加入一个新团队
	RAID_EVENT_RET_RAIDINFO = 2,		--返回团队信息
	RAID_EVENT_NUMBER = 3				--团队结果类型的最大值
}

define.RAID_POISTION = {
	RAID_POISTION_LEADER = 0,	--团长
	RAID_POISTION_ASSISTANT = 1,	--助理
	RAID_POISTION_MEMBER = 2,		--普通团员
}

define.RAID_RESULT = {
	RAID_RESULT_MEMBERENTER = 0,		--成员加入团队
	RAID_RESULT_MEMBERLEAVE = 1,			--成员离开团队
	RAID_RESULT_LEADERLEAVE = 2,			--团长离开团队
	RAID_RESULT_KICK = 3,					--踢除成员
	RAID_RESULT_APPOINT = 4,				--任命新职务
	RAID_RESULT_STARTCHANGESCENE = 5,		--开始切换场景
	RAID_RESULT_ENTERSCENE = 6,				--团队成员进入新场景
	RAID_RESULT_REFRESH = 7,				--重新请求团队信息的回复
	RAID_RESULT_MEMBEROFFLINE = 8,			--玩家离线
	RAID_RESULT_DISMISS = 9,				--团队解散
	RAID_RESULT_NUMBER = 10,				--团队结果类型的最大值
}

define.TEAM_RESULT = {
    TEAM_RESULT_MEMBERENTERTEAM = 0, -- 成员加入队伍
    TEAM_RESULT_MEMBERLEAVETEAM = 1, -- 普通成员离开队伍
    TEAM_RESULT_LEADERLEAVETEAM = 2, -- 队长离开队伍
    TEAM_RESULT_TEAMDISMISS = 3, -- 队伍解散
    TEAM_RESULT_TEAMKICK = 4, -- 踢除队员
    TEAM_RESULT_TEAMAPPOINT = 5, -- 任命新队长
    TEAM_RESULT_TEAMREFRESH = 6, -- 重新请求队伍信息的回复
    TEAM_RESULT_STARTCHANGESCENE = 7, -- 开始切换场景
    TEAM_RESULT_ENTERSCENE = 8, -- 队友进入新场景
    TEAM_RESULT_REFRESHSERVERINFO = 9, -- 玩家跳转场景后，给服务器刷新队伍消息
    TEAM_RESULT_MEMBEROFFLINE = 10, -- 玩家下线

    TEAM_RESULT_NUMBER = 11 -- 队伍结果类型的最大值
}

define.TEAM_ERROR = {
    TEAM_ERROR_INVITEDESTHASTEAM = 0, -- 邀请对象已经属于某个组了
    TEAM_ERROR_INVITEREFUSE = 1, -- 被邀请人拒绝加入
    TEAM_ERROR_INVITETEAMFULL = 2, -- 邀请人的队伍人数已经满了
    TEAM_ERROR_INVITELEADERREFUSE = 3, -- 队长拒绝新成员被邀请加入
    TEAM_ERROR_DISMISSNOTLEADER = 4, -- 解散队伍的人不是队长
    TEAM_ERROR_KICKNOTLEADER = 5, -- 踢人者不是队长
    TEAM_ERROR_APPLYSOURHASTEAM = 6, -- 申请人已经属于某个组了
    TEAM_ERROR_APPLYDESTHASNOTTEAM = 7, -- 被申请者不属于某个组
    TEAM_ERROR_APPLYLEADERREFUSE = 8, -- 队长不同意申请人加入队伍
    TEAM_ERROR_APPLYTEAMFULL = 9, -- 被申请人的队伍人数已经满了
    TEAM_ERROR_APPLYLEADERGUIDERROR = 10, -- 被申请人所在队伍的队长GUID发生变化
    TEAM_ERROR_APPOINTSOURNOTEAM = 11, -- 旧队长不是队伍成员
    TEAM_ERROR_APPOINTDESTNOTEAM = 12, -- 新队长不是队伍成员
    TEAM_ERROR_APPOINTNOTSAMETEAM = 13, -- 任命时两个人不属于同一个队伍
    TEAM_ERROR_APPOINTSOURNOLEADER = 14, -- 旧队长不是队伍的队长了
    TEAM_ERROR_APPLYLEADERCANTANSWER = 15, -- 队长目前无法答复
    TEAM_ERROR_INVITERNOTINTEAM = 16, -- 邀请人不在队长的队伍中
    TEAM_ERROR_APPLYWHENINTEAM = 17, -- 申请人在有队伍的情况下申请入队
    TEAM_ERROR_TEAMFULL = 18, -- 队伍人数已满。
    TEAM_ERROR_REFUSEINVITESETTING = 19, -- 被邀请人设置了拒绝邀请
    TEAM_ERROR_TARGETNOTONLINE = 20 -- 对方已经离线，加入失败。
}

define.ENUM_CHAT_TYPE = {
    CHAT_TYPE_INVALID = -1,
    CHAT_TYPE_NORMAL = 0, -- 普通说话消息
    CHAT_TYPE_TEAM = 1, -- 队聊消息
    CHAT_TYPE_SCENE = 2, -- 场景消息
    CHAT_TYPE_TELL = 3, -- 私聊消息
    CHAT_TYPE_SYSTEM = 4, -- 系统消息
    CHAT_TYPE_CHANNEL = 5, -- 自建聊天频道消息
    CHAT_TYPE_GUILD = 6, -- 帮派消息
    CHAT_TYPE_MENPAI = 7, -- 门派消息
    MSG2PLAYER_PARA = 8, -- 仅客户端使用的消息
    CHAT_TYPE_SPEAKER = 10, -- 小喇叭
    CHAT_TYPE_CITY = 11, --同城聊天
    CHAT_TYPE_LEAGUE = 12, --同盟聊天
    CHAT_RAID = 14, --团队团聊
    CHAT_RAID_TEAM = 15, --团队小队
    CHAT_TYPE_MAIL = 18,    -- 邮件聊天
    CHAT_TYPE_MAIL_RET = 24,
    CHAT_TYPE_TELL_RET = 25
}
--修改跟随
-- define.TEAM_FOLLOW_RESULT = {
    -- TF_RESULT_REFUSE_FOLLOW = 0, -- 队员拒绝跟随队长
    -- TF_RESULT_ENTER_FOLLOW = 1, -- 队员进入组队跟随状态
    -- TF_RESULT_STOP_FOLLOW = 2, -- 队员退出组队跟随状态
    -- TF_RESULT_FOLLOW_FLAG = 3 -- 通知客户端进入组队跟随状态的标记（ENTER_FOLLOW 的 quiet 模式）
-- }

define.TEAM_LIST_TYPE = {CREATE = 0, JOIN = 1, REFRESH = 2}

define.ATTR_RESUlT = {
    ATTR_RESUlT_SUCCESS = 0,
    ATTR_RESULT_NOT_ENOUGH_REMAIN_POINT = 1,
    ATTR_RESULT_NO_SUCH_ATTR = 2,
    ATTR_RESUlT_NO_POINT = 3
}

define.PET_TYPE = {
    PET_TYPE_INVALID = -1,
    PET_TYPE_BABY = 0,
    PET_TYPE_VARIANCE = 1,
    PET_TYPE_WILENESS = 2
}

define.PET_AI_TYPE = {
    PET_AI_INVALID = -1,
    PET_AI_COWARDICE = 0, -- 胆小
    PET_AI_WARINESS = 1, -- 谨慎
    PET_AI_LOYALISM = 2, -- 忠诚
    PET_AI_CANNINESS = 3, -- 精明
    PET_AI_VALOUR = 4 -- 勇猛
}

define.ENUM_MANIPULATE_TYPE = {
    MANIPULATE_INVALID = -1, -- 无效
    MANIPULATE_CREATEPET = 0, -- 召唤宠物
    MANIPULATE_DELETEPET = 1, -- 收回宠物
    MANIPULATE_FREEPET = 2, -- 放生宠物
    MANIPULATE_ASKOTHERPETINFO = 3, -- 察看其他玩家的宠物信息(宠物征友等用...)
    MANIPULATE_SOUL_MELTING = 4, -- 兽魂融合
    MANIPULATE_SOUL_SEPARATE = 5 -- 兽魂分离
}

define.ENUM_MANIPULATEPET_RET = {
    MANIPULATEPET_RET_INVALID = -1,
    MANIPULATEPET_RET_CAPTUREFALID = 0, -- 捕捉失败
    MANIPULATEPET_RET_CAPTURESUCC = 1, -- 捕捉成功
    MANIPULATEPET_RET_CALLUPFALID = 2, -- 召唤失败
    MANIPULATEPET_RET_CALLUPSUCC = 3, -- 召唤成功
    MANIPULATEPET_RET_FREEFALID = 4, -- 放生失败
    MANIPULATEPET_RET_FREESUCC = 5, -- 放生成功
    MANIPULATEPET_RET_RECALLFALID = 6, -- 收回失败
    MANIPULATEPET_RET_RECALLSUCC = 7, -- 收回成功
    MANIPULATEPET_RET_SOULMELTINGFAILED = 8, -- 融魂失败
    MANIPULATEPET_RET_SOULMELTINGSUCC = 9 -- 融魂成功
}

define.PET_SKILL_OPERATEMODE = {
    PET_SKILL_OPERATE_INVALID = -1, -- INVALID
    PET_SKILL_OPERATE_NEEDOWNER = 0, -- 需要主人触发
    PET_SKILL_OPERATE_AISTRATEGY = 1, -- 由AI来触发
    PET_SKILL_OPERATE_INCEACEATTR = 2, -- 增强宠物属性
    PET_SKILL_OPERATE_NUMBERS = 3
}

define.PET_TYPE_AISKILL = {
    PET_TYPE_AISKILL_INVALID = -1, -- INVALID
    PET_TYPE_AISKILL_PHYSICATTACK = 0, -- 物功型
    PET_TYPE_AISKILL_MAGICATTACK = 1, -- 法功型
    PET_TYPE_AISKILL_PROTECTEOWNER = 2, -- 护主型
    PET_TYPE_AISKILL_DEFENCE = 3, -- 防御型
    PET_TYPE_AISKILL_REVENGE = 4 -- 复仇型
}

-- 关系
define.ENUM_RELATION = {
    RELATION_INVALID = -1,
    RELATION_ENEMY = 0, -- 敌对
    RELATION_FRIEND = 1 -- 友好
}

define.ENUM_MOVE_MODE = {
    MOVE_MODE_HOBBLE = 0, -- 蹒跚
    MOVE_MODE_WALK = 1, -- 走
    MOVE_MODE_RUN = 2, -- 跑
    MOVE_MODE_SPRINT = 3 -- 疾跑
}

define.ENUM_PET_SKILL_INDEX = {
    PET_SKILL_INDEX_INVALID = -1,
    PET_SKILL_INDEX_CONTROL_BY_PLAYER1 = 1,
    PET_SKILL_INDEX_CONTROL_BY_PLAYER2 = 2,
    PET_SKILL_INDEX_CONTROL_BY_AI1 = 3,
    PET_SKILL_INDEX_CONTROL_BY_AI2 = 4,
    PET_SKILL_INDEX_CONTROL_BY_AI3 = 5,
    PET_SKILL_INDEX_CONTROL_BY_AI4 = 6,
    PET_SKILL_INDEX_CONTROL_BY_AI5 = 7
}

define.SYSTEM_USE_IMPACT_ID = {
    IMP_DAMAGES_OF_ATTACKS = 0,
    IMP_NOTYPE_DAMAGE = 1
}

define.PK_MODE = {
    PEACE = 0,
    PERSONAL = 1,
    GOD_AND_EVIL = 2,
    TEAM = 3,
    BANG_HUI = 4,
    RAID = 5
}

define.ASKCREATECHAR_RESULT = {
    ASKCREATECHAR_SUCCESS = 0, -- 成功
    ASKCREATECHAR_SERVER_BUSY = 1, -- 服务器忙，重试
    ASKCREATECHAR_OP_TIMES = 2, -- 操作过于频繁
    ASKCREATECHAR_FULL = 3, -- 角色已经满了
    ASKCREATECHAR_SAME_NAME = 4, -- 角色重名
    ASKCREATECHAR_OP_ERROR = 5, -- 错误操作流程
    ASKCREATECHAR_INTERNAL_ERROR = 6, -- 内部错误
    ASKCREATECHAR_INVALID_NAME = 8 -- 角色名错误 (client case 8 = INVALID_STRING_IN_NAME; 7 khong co nhanh -> "Loi khong xac dinh" 360)
}

define.WUHUN_SKILLS = {
    [1] = {1361, 1367, 1373, 1379, 3669, 4973},
    [2] = {
        1385, 1391, 1397, 1403, 1409, 1415, 1421, 1427, 1433, 1439, 1451, 1457,
        1463, 1469, 1475, 1481, 1487, 1493, 1499, 1505, 1511, 1517, 1523, 1529,
        1535
    },
    [3] = {
        1541, 1547, 1553, 1559, 1565, 1571, 1577, 1583, 1589, 1595, 1601, 1607,
        1613, 1619
    }
}

define.FINGER_REQUEST_TYPE = {
    FREQ_NONE = 0,
    FREQ_GUID = 1, -- GUID 查找玩家
    FREQ_NAME = 2, -- 昵称查找
    FREQ_ADVANCED = 3 -- 高级查找
}

define.KFS_BASE_ATTRS = {
    [0] = {
        [define.ITEM_ATTRIBUTE.IATTRIBUTE_STR] = 2,
        [define.ITEM_ATTRIBUTE.IATTRIBUTE_SPR] = 1,
        [define.ITEM_ATTRIBUTE.IATTRIBUTE_CON] = 1,
        [define.ITEM_ATTRIBUTE.IATTRIBUTE_INT] = 1,
        [define.ITEM_ATTRIBUTE.IATTRIBUTE_DEX] = 1
    },
    [1] = {
        [define.ITEM_ATTRIBUTE.IATTRIBUTE_STR] = 1,
        [define.ITEM_ATTRIBUTE.IATTRIBUTE_SPR] = 2,
        [define.ITEM_ATTRIBUTE.IATTRIBUTE_CON] = 1,
        [define.ITEM_ATTRIBUTE.IATTRIBUTE_INT] = 1,
        [define.ITEM_ATTRIBUTE.IATTRIBUTE_DEX] = 1
    }
}

define.KFS_GROW_LEVEL = {550, 600, 650, 700, 750, 800, 850, 900}

define.PET_SOUL_MELTING_COF = {
    [0] = 1 / 64000000,
    [1] = 1 / 64000000,
    [2] = 1 / 64000000,
    [3] = 1 / 64000000,
    [4] = 1 / 64000000,
    [5] = 1 / 30250000,
    [6] = 1 / 100000000,
    [7] = 1 / 30250000,
    [8] = 1 / 30250000,
    [9] = 1 / 30250000,
    [10] = 1 / 30250000,
    [11] = 1 / 64000000,
    [12] = 1 / 64000000,
    [13] = 1 / 64000000,
    [14] = 1 / 64000000,
    [15] = 1 / 64000000,
    [16] = 1 / 64000000,
    [17] = 1 / 64000000,
    [18] = 1 / 64000000,
    [19] = 1 / 64000000,
    [20] = 1 / 64000000,
    [21] = 1 / 64000000,
    [22] = 1 / 64000000
}

define.PET_SOUL_MELTING_INFLUENCE_PERCEPTION = {
    [0] = {
        "str_perception", "spr_perception", "con_perception", "dex_perception",
        "int_perception"
    },
    [1] = {"str_perception"},
    [2] = {"spr_perception"},
    [3] = {"con_perception"},
    [4] = {"dex_perception"},
    [5] = {"int_perception"},
    [6] = {"str_perception", "spr_perception"},
    [7] = {
        "str_perception", "spr_perception", "con_perception", "dex_perception",
        "int_perception"
    },
    [8] = {"dex_perception"},
    [9] = {
        "str_perception", "spr_perception", "con_perception", "dex_perception",
        "int_perception"
    },
    [10] = {"int_perception"},
    [11] = {"str_perception", "spr_perception"},
    [12] = {"str_perception", "spr_perception"},
    [13] = {"str_perception", "spr_perception"},
    [14] = {"str_perception", "spr_perception"},
    [15] = {"str_perception", "spr_perception"},
    [16] = {"str_perception", "spr_perception"},
    [17] = {"str_perception", "spr_perception"},
    [18] = {"str_perception", "spr_perception"},
    [19] = {"str_perception", "spr_perception"},
    [20] = {"str_perception", "spr_perception"},
    [21] = {"con_perception"},
    [22] = {"str_perception", "spr_perception"}
}

define.PET_SOUL_MELTING_ATTR_2_IA = {
    [0] = define.ITEM_ATTRIBUTE.IATTRIBUTE_POINT_MAXHP,
    [1] = define.ITEM_ATTRIBUTE.IATTRIBUTE_STR,
    [2] = define.ITEM_ATTRIBUTE.IATTRIBUTE_SPR,
    [3] = define.ITEM_ATTRIBUTE.IATTRIBUTE_CON,
    [4] = define.ITEM_ATTRIBUTE.IATTRIBUTE_INT,
    [5] = define.ITEM_ATTRIBUTE.IATTRIBUTE_DEX,
    [6] = define.ITEM_ATTRIBUTE.IATTRIBUTE_POINT_ATTACK_P_ATTACK_M,
    [7] = define.ITEM_ATTRIBUTE.IATTRIBUTE_HIT,
    [8] = define.ITEM_ATTRIBUTE.IATTRIBUTE_MISS,
    [9] = define.ITEM_ATTRIBUTE.IATTRIBUTE_2ATTACK_RATE,
    [10] = define.ITEM_ATTRIBUTE.IATTRIBUTE_LUK,
    [11] = define.ITEM_ATTRIBUTE.IATTRIBUTE_COLD_RESIST,
    [12] = define.ITEM_ATTRIBUTE.IATTRIBUTE_FIRE_RESIST,
    [13] = define.ITEM_ATTRIBUTE.IATTRIBUTE_LIGHT_RESIST,
    [14] = define.ITEM_ATTRIBUTE.IATTRIBUTE_POISON_RESIST,
    [15] = define.ITEM_ATTRIBUTE.IATTRIBUTE_POINT_JIAN_SU_RESIST,
    [16] = define.ITEM_ATTRIBUTE.IATTRIBUTE_POINT_DIAN_XUE_RESIST,
    [17] = define.ITEM_ATTRIBUTE.IATTRIBUTE_POINT_MA_BI_RESIST,
    [18] = define.ITEM_ATTRIBUTE.IATTRIBUTE_POINT_SAN_GONG_RESIST,
    [19] = define.ITEM_ATTRIBUTE.IATTRIBUTE_POINT_FENG_YIN_RESIST,
    [20] = define.ITEM_ATTRIBUTE.IATTRIBUTE_POINT_SHI_MING_RESIST,
    [21] = define.ITEM_ATTRIBUTE.IATTRIBUTE_POINT_REDUCE_DAMAGE,
    [22] = define.ITEM_ATTRIBUTE.IATTRIBUTE_POINT_ADD_DAMAGE
}

define.PET_SOUL_BASE_ATTR_2_IA = {
    ["提高主人的冰攻击%d点"] = define.ITEM_ATTRIBUTE
        .IATTRIBUTE_COLD_ATTACK,
    ["提高主人的毒攻击%d点"] = define.ITEM_ATTRIBUTE
        .IATTRIBUTE_POISON_ATTACK,
    ["提高主人的玄攻击%d点"] = define.ITEM_ATTRIBUTE
        .IATTRIBUTE_LIGHT_ATTACK,
    ["提高主人的火攻击%d点"] = define.ITEM_ATTRIBUTE
        .IATTRIBUTE_FIRE_ATTACK,

    ["提高主人的忽略目标冰抗%d点"] = define.ITEM_ATTRIBUTE
        .IATTRIBUTE_REDUCE_TARGET_COLD_RESIST,
    ["提高主人的忽略目标毒抗%d点"] = define.ITEM_ATTRIBUTE
        .IATTRIBUTE_REDUCE_TARGET_POISON_RESIST,
    ["提高主人的忽略目标玄抗%d点"] = define.ITEM_ATTRIBUTE
        .IATTRIBUTE_REDUCE_TARGET_LIGHT_RESIST,
    ["提高主人的忽略目标火抗%d点"] = define.ITEM_ATTRIBUTE
        .IATTRIBUTE_REDUCE_TARGET_FIRE_RESIST,

    ["提高主人的血上限%d点"] = define.ITEM_ATTRIBUTE
        .IATTRIBUTE_POINT_MAXHP,
    ["提高主人的命中%d点"] = define.ITEM_ATTRIBUTE
        .IATTRIBUTE_HIT,
    ["提高主人的闪避%d点"] = define.ITEM_ATTRIBUTE.IATTRIBUTE_MISS,
    ["提高主人的会心%d点"] = define.ITEM_ATTRIBUTE
        .IATTRIBUTE_2ATTACK_RATE,
    ["提高主人的会心防御%d点"] = define.ITEM_ATTRIBUTE
        .IATTRIBUTE_LUK,

    ["提高主人的外功攻击%d点"] = define.ITEM_ATTRIBUTE
        .IATTRIBUTE_ATTACK_P,
    ["提高主人的内功攻击%d点"] = define.ITEM_ATTRIBUTE
        .IATTRIBUTE_ATTACK_M,

    ["提高主人的外功防御%d点"] = define.ITEM_ATTRIBUTE
        .IATTRIBUTE_DEFENCE_P,
    ["提高主人的内功防御%d点"] = define.ITEM_ATTRIBUTE
        .IATTRIBUTE_DEFENCE_M,

    ["提高主人的体力%d点"] = define.ITEM_ATTRIBUTE.IATTRIBUTE_CON,
    ["主人攻击时有2%%几率震慑敌人的魂魄，使之麻痹%s秒"] = define.ITEM_ATTRIBUTE
        .IATTRIBUTE_QIONGQI_MELTING_IMPACT,
    ["提高主人对珍兽造成的伤害%d%%"] = define.ITEM_ATTRIBUTE
        .IATTRIBUTE_JIUWEI_MELTING_ATTACK_PET_EXTRA_DAMAGE
}

define.QIONGQI_IMPACT = {
    45415,
    45416,
    45417,
    45418,
    45419,
    45420,
}

define.PET_SOUL_ATTRS = {
    0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20,
    21, 22
}

define.ConditionAndDepleteID = {
    CD_INVALID = -1,
    C_UNIT_MUST_HAVE_IMPACT = 0,
    C_UNIT_HP_MUST_LESS_THAN_BY_RATE = 1,
    C_TARGET_MUST_HAVE_IMPACT = 2,
    C_TARGET_LEVEL_MUST_LESS_THAN_BY_VALUE = 3,
    CD_MANA_BY_VALUE = 4,
    CD_MANA_BY_RATE = 5,
    CD_RAGE_BY_RATE = 6,
    CD_STRIKE_POINT_BY_SEGMENT = 7,
    D_ALL_RAGE = 8,
    D_CANCEL_SPECIFIC_IMPACT = 9,
    C_TARGET_MUST_BE_MY_SPOUSE = 10,
    CD_HP_BY_RATE = 11,
    C_HP_BY_RATE = 12,
    CD_HP_BY_VALUE = 13,
    CD_FLOWER_BY_VALUE = 14,
    C_UNIT_MUST_NOT_HAVE_IMPACT = 16,
}

define.RELATION_REQUEST_TYPE = {
    REQ_NONE = 0,
    REQ_RELATIONLIST = 1,
    REQ_RELATIONINFO = 2,
    REQ_VIEWPLAYER = 3, -- 查看玩家
    REQ_ADDFRIEND = 4,
    REQ_ADDTOBLACKLIST = 5,
    REQ_TEMPFRIEND_TO_FRIEND = 6,
    REQ_TEMPFRIEND_ADDTO_BLACKLIST = 7,
    REQ_TRANSITION = 8,
    REQ_DELFRIEND = 9,
    REQ_DELFROMBLACKLIST = 10,
    REQ_NEWGOODFRIEND = 11, -- 增加一个亲密好友
    REQ_RELATIONONLINE = 12, -- 请求在线玩家列表
    REQ_MODIFYMOOD = 13, -- 修改自己的心情
    REQ_MODIFYSETTINGS = 14, -- 修改联系人设置
    REQ_NOTIFY_ADDTEMPFRIEND = 15 -- 通知对方被加为临时好友
}

define.RELATION_TYPE = {
    RELATION_TYPE_NONE = 0, -- 空
    RELATION_TYPE_FRIEND = 1, -- 好友
    RELATION_TYPE_BROTHER = 2, -- 结拜
    RELATION_TYPE_MARRY = 3, -- 结婚
    RELATION_TYPE_BLACKNAME = 4, -- 黑名单
    RELATION_TYPE_TEMPFRIEND = 5, -- 临时好友
    RELATION_TYPE_STRANGER = 6, -- 陌生人关系
    RELATION_TYPE_PRENTICE = 7, -- 徒弟关系
    RELATION_TYPE_MASTER = 8, -- 师傅关系
    RELATION_TYPE_ENEMIES = 9, -- 仇人关系
    RELATION_TYPE_SIZE = 10, -- 关系种类
}

define.RELATION_RETURN_TYPE = {
    RET_NONE = 0,
    RET_RELATIONLIST = 1,
    RET_RELATIONINFO = 2,
    RET_VIEWPLAYER = 3, -- 查看玩家
    RET_TARGETNOTONLINE = 4, -- 目标不在线（用于向 World 询问某关系人的信息没有找到时的反馈）
    RET_ADDFRIEND = 5,
    RET_ADDTOBLACKLIST = 6,
    RET_TEMPFRIEND_TO_FRIEND = 7,
    RET_TEMPFRIEND_ADDTO_BLACKLIST = 8,
    RET_TRANSITION = 9,
    RET_DELFRIEND = 10,
    RET_DELFROMBLACKLIST = 11,
    RET_ADDFRIENDNOTIFY = 12, -- 通知好友已经被加了
    RET_ONLINELIST = 13, -- 在线好友列表
    RET_RELATIONONLINE = 14, -- 好友上线
    RET_RELATIONOFFLINE = 15, -- 好友下线
    RET_NEWMOOD = 23, -- 新的心情
    RET_NOTIFY_ADDTEMPFRIEND = 24, -- 通知对方被加为临时好友
    RET_ERR_START = 25,
    RET_ERR_TARGETNOTEXIST = 26, -- 目标不存在或不在线
    RET_ERR_GROUPISFULL = 27, -- 好友组已满
    RET_ERR_ISFRIEND = 28, -- 已经是好友
    RET_ERR_ISBLACKNAME = 29, -- 已经被加入黑名单
    RET_ERR_CANNOTTRANSITION = 30, -- 不能转换
    RET_ERR_ISNOTFRIEND = 31, -- 不是好友
    RET_ERR_ISNOTINBLACKLIST = 32, -- 不在黑名单
    RET_ERR_SPOUSETOBLACKLIST = 33, -- 将配偶加入黑名单
    RET_ERR_MASTERTOBLACKLIST = 34, -- 将师傅加入黑名单
    RET_ERR_PRENTICETOBLACKLIST = 35, -- 将徒弟加入黑名单
    RET_ERR_BROTHERTOBLACKLIST = 36, -- 将结拜兄弟加入黑名单
    RET_ERR_DELSPOUSE = 37, -- 删除配偶
    RET_ERR_DELMASTER = 38, -- 删除师傅
    RET_ERR_DELPRENTICE = 39, -- 删除徒弟
    RET_ERR_DELBROTHER = 40, -- 删除结义兄弟
    RET_ERR_PASSWDMISMATCH = 41, -- 密码不匹配
    RET_ERR_CANNOT_ADDFRIEND = 42, -- 拒绝加为好友
    RET_ERR_CANNOTRECEIVEMAIL = 43, -- 拒绝接收任何邮件
    RET_ERR_NOTRECVSTRANGEMAIL = 44, -- 拒收陌生人邮件
    RET_ERR_ISENEMY = 45, -- 非相同阵营
    RET_ERR_RELATIONUNKNOWN = 46 -- 未知错误
}

define.SCENE_STATUS = {
    SCENE_STATUS_SLEEP = 0, -- 没有设置的场景状态，即没有场景数据、处于休眠的状态
    SCENE_STATUS_SELECT = 1, -- 场景被检索，处于待装载状态
    SCENE_STATUS_LOAD = 2, -- 需要读取场景资源文件的状态
    SCENE_STATUS_INIT = 3, -- 需要初始场景数据的状态
    SCENE_STATUS_RUNNING = 4 -- 正常运行的场景状态
}

define.MD_ENUM = {
    MD_TIAOZHAN_SCRIPT			= 28,
    MD_CHENGXIONGDATU_DAYCOUNT	= 49,
    MD_MIDAUTUMN_SCORE			= 54,		--中秋积分
    MD_ThiefSoldierInvade		= 63,		--贼兵入侵积分
    MD_LAST_QIJU_DAY			= 78,		--棋局活动的最后日期
    MD_RELATION_MUWANQING       = 92,		-- 木婉清任务
    MD_RELATION_ZHONGLING       = 93,		-- 钟灵任务
    MD_RELATION_DUANYANQING	    = 94,	    -- 段延庆任务
    MD_RELATION_DUANYU          = 95,		-- 段誉任务
    MD_RELATION_AZHU            = 96,		-- 阿朱任务
    MD_RELATION_ABI	            = 97,		-- 阿碧任务
    MD_RELATION_WANGYUYAN       = 98,		-- 王语嫣任务
    MD_RELATION_XIAOFENG        = 99,		-- 萧峰任务
    MD_RELATION_AZI	            = 100,		-- 阿紫任务
    MD_RELATION_MURONGFU		= 101,		-- 慕容复任务
    MD_RELATION_XUZHU			= 102,		-- 虚竹任务
    MD_RELATION_JIUMOZHI		= 103,		-- 鸠摩智任务
    MD_RELATION_YINCHUAN		= 104,		-- 银川公主任务
    MD_ROUNDMISSION1            = 113, -- 一个也不能跑再也不能随便放弃啦~！
    MD_ROUNDMISSION2            = 115,
    MD_ROUNDMISSION3            = 116,
    MD_ROUNDMISSION1_TIMES      = 147, -- 一个也不能跑每天接取的次数
    MD_ROUNDMISSION2_TIMES      = 148,
    MD_ROUNDMISSION3_TIMES      = 149,
    MD_JQXH_ZHONGLING_LIMITI	= 153,		-- 同上
    MD_JQXH_DUANYANQING_LIMITI	= 154,		-- 同上
    MD_JQXH_DUANYU_LIMITI		= 155,		-- 同上
    MD_JQXH_AZHU_LIMITI		    = 156,		-- 同上
    MD_JQXH_ABI_LIMITI			= 157,		-- 同上
    MD_JQXH_WANGYUYAN_LIMITI	= 158,		-- 同上
    MD_JQXH_XIAOFENG_LIMITI		= 159,		-- 同上
    MD_JQXH_AZI_LIMITI			= 160,		-- 同上
    MD_JQXH_MURONGFU_LIMITI		= 161,		-- 同上
    MD_JQXH_XUZHU_LIMITI		= 162,		-- 同上
    MD_JQXH_JIUMOZHI_LIMITI	    = 163,		-- 同上
    MD_JQXH_YINCHUAN_LIMITI		= 164,		-- 同上
    MD_RELATION_QIANHONGYU      = 165,
    MD_CUJU_PRE_TIME            = 193,
    MD_MISSHENBING_WEAPONLEVEL	= 194, -- 血欲神兵任务扣除的武器等级
    MD_YANZIWU_TIMES			= 195,  -- 每天进入燕子坞的次数
    MD_PRE_YANZIWU_TIME		    = 196,  -- 上一次去燕子坞的时间
    MD_QIANXUN_SELECT_MISSIONTYPE = 209,	-- 玩家所选的千寻任务类型
    MD_XINGYUN_DATA = 211,	-- 玩家是否参与抽奖和3个奖品的类型
    MD_XINGYUN_TIME_INFO = 213,	-- 幸运轮盘时间信息
    MD_50WAN_TIME_INFO = 214,	-- 50万同庆时间信息
    MD_HANYUBED_USEBOOK_LASTDAY = 210,
    MD_HANYUBED_CANADDEXP_COUNT = 212,
    MD_CHUNJIE_BIANPAO_DAYTIME = 220,		--上次领取鞭炮时间
    MD_SHAXING_DAYTIME = 517,			--杀星副本当日次数
    MD_PIAOMIAOFENG_LASTTIME = 232,
    MD_PIAOMIAOFENG_SMALL_LASTTIME = 234,
    MD_CHENGXIONGDATU_DAYTIME = 278,		--逞凶打图 时间数据
    MD_XINSANHUAN_1_LAST	= 241, --新三环任务第一环黄金之链任务的最后放弃时间
    MD_XINSANHUAN_1_DAYTIME	= 227, --新三环任务第一环黄金之链任务的当日次数
    MD_XINSANHUAN_2_LAST	= 228, --新三环任务第二环玄佛珠任务的最后放弃时间
    MD_XINSANHUAN_2_DAYTIME	= 229, --新三环任务第二环玄佛珠任务的当日次数
    MD_XINSANHUAN_3_LAST	= 230, --新三环任务第三环熔岩之地任务的最后放弃时间
    MD_XINSANHUAN_3_DAYTIME	= 231, --新三环任务第三环熔岩之地任务的当日次数
    MD_TOPCHONGZHI_EXCHYUANBAO = 388, --一掷豪礼千金情兑换元宝数量
    MD_TOPCHONGZHI_COSTYUANBAO = 389, --一掷豪礼千金情消耗元宝数量 tips:此处需底层埋点
    MD_TOPCHONGZHI_BUTTONSTATE = 390, --一掷豪礼千金情是否领取奖励记录
    MD_COST_CHU_HUN_YE = 505,
    MD_GETD_HUANG_SHOU_JIA_COUNT = 506,
    MD_GETD_HUANG_SHOU_ZHEN_COUNT = 507,
    MD_GETD_HUANG_SHOU_JUE_COUNT = 508,
    MD_COST_CHU_HUN_SUI = 509, --消耗淬魂髓
    MD_GETD_SHEN_SHOU_JIA_COUNT = 510,
    MD_GETD_SHEN_SHOU_ZHEN_COUNT = 511,
    MD_GETD_SHEN_SHOU_JUE_COUNT = 512,
    MD_COST_DI_JIE_SHU_YU_QUAN = 513,
    MD_COST_TIAN_JIE_SHU_YU_QUAN = 514,
    MD_GETD_DI_JIE_SHU_YU_QUAN = 515,
    MD_GETD_TIAN_JIE_SHU_YU_QUAN = 516,
    MD_SERVER_TIME = 386,
    MD_SERVER_WEEK_TIME = 387,
}

define.SCENE_ENUM = {
    SCENE_LUOYANG = 0, -- 洛阳
    SCENE_SUZHOU = 1, -- 苏州
    SCENE_DALI = 2, -- 大理
    SCENE_SONGSHAN = 3, -- 嵩山
    SCENE_TAIHU = 4, -- 太湖
    SCENE_JINGHU = 5, -- 镜湖
    SCENE_WULIANG = 6, -- 无量山
    SCENE_JIANGE = 7, -- 剑阁
    SCENE_DUNHUANG = 8, -- 敦煌
    SCENE_SHAOLIN = 9, -- 少林寺
    SCENE_GAIBANG = 10, -- 丐帮总舵
    SCENE_PRISON = 151, -- 监狱
    SCENE_LOULAN = 186 -- 楼兰--add by xindefeng
}

define.AI_SCRIPT_OP = {
    ANDOROP = 0,
    RELATIONOP = 1,
    TODOOP = 2,
    PARAMOP = 3,
    OTHEROP = 4,
}

define.GUILD_ERROR_TYPE =
{
	-- 创建部分
	GUILD_ERROR_NOTHING				= 0,	-- 没什么错误……
	GUILD_ERROR_WANTING				= -1,	-- 不符合创建条件，只给出错误符，具体的错误描述由脚本发送
	GUILD_ERROR_INVALID_NAME		= -2,	-- 名字非法
	GUILD_ERROR_DUPLICATED_NAME		= -3,	-- 重名
	GUILD_ERROR_GUILD_FULL			= -4,	-- 不能创建更多帮会

	-- 加入部分
	GUILD_ERROR_MEMBER_FULL			= -5,	-- 帮会满员了
	GUILD_ERROR_PROPOSER_FULL		= -6,	-- 申请人已满
	GUILD_ERROR_IN_GUILD			= -7,	-- 玩家已加入帮会
	GUILD_ERROR_NOT_EXIST			= -8,	-- 帮会不存在

	-- 权限操作
	GUILD_ERROR_UNAUTHORIZED		= -9,	-- 没有权限
	GUILD_ERROR_NO_VACANCY			= -10,	-- 0001，任免职务，没有职位空缺
	GUILD_ERROR_NO_QUALIFICATION	= -11,	-- 0002，调整权限，被调整人员（职位）不够资格
	GUILD_ERROR_CASHBOX_FULL		= -12,	-- 0007，存入金额，帮会金库已满

	GUILD_ERROR_ALREADY_MEMBER		= -13,	-- 此人已经是帮会成员
	GUILD_ERROR_MEMBER_NOT_EXIST	= -14,	-- 此人不在帮会中

	--禅让
	GUILD_ERROR_NO_ASS_CHIEF		= -15,	-- 没有副帮主
	GUILD_ERROR_GUILD_ALREADY_EXIST = -16,	--	帮会已存在

	--这个职位人数已满，不能任命
	GUILD_ERROR_POS_FULL			= -17,	--这个职位人数已满，不能任命

	GUILD_ERROR_ALREADY_IN_PROPOSER_LIST = -18,		--申请人已经在申请列表中了

	GUILD_ERROR_INVALID_CAMP			= -19,		--申请人的阵营非法

	-- 解散部分
	GUILD_ERROR						= -64,	-- 不明错误
}

define.GUILD_RETURN_TYPE    =
{
	GUILD_RETURN_INVALID			= -1,
	-- 创建部分
	GUILD_RETURN_CREATE = 0,					-- 创建成功
	GUILD_RETURN_RESPONSE = 1,					-- 响应成功
	-- 加入部分
	GUILD_RETURN_JOIN = 2,						-- 加入申请列表等待批准
	-- 权限操作
	GUILD_RETURN_PROMOTE = 3,					-- 0001，任免职务，升职
	GUILD_RETURN_DEMOTE = 4,					-- 0001，任免职务，降职
	GUILD_RETURN_AUTHORIZE = 5,					-- 0002，调整权限，授权
	GUILD_RETURN_DEPRIVE_AUTHORITY = 6,			-- 0002，调整权限，解除权限
	GUILD_RETURN_RECRUIT = 7,					-- 0003，接收帮众
	GUILD_RETURN_EXPEL = 8,						-- 0004，开除帮众
	GUILD_RETURN_DEMISE = 9,					-- 0005，禅让
	GUILD_RETURN_WITHDRAW = 10,					-- 0006，支取金额
	GUILD_RETURN_DEPOSIT = 11,					-- 0007，存入金额
	GUILD_RETURN_LEAVE = 12,						-- 0008，离开帮会
	GUILD_RETURN_REJECT = 13,					-- 0009，拒绝申请
	GUILD_RETURN_FOUND = 14,						-- 正式成立（人数达到）
	GUILD_RETURN_DISMISS = 15,					-- 解散帮会
	GUILD_RETURN_CHANGEDESC = 16,				-- 修改帮会宗旨
	GUILD_RETURN_NAME = 17,						-- 刷新帮会名
	GUILD_RETURN_SIZE = 18,
};

define.GUILD_PACKET_TYPE =
{
	GUILD_PACKET_INVALID			= -1,
	GUILD_PACKET_CG_ASKLIST         = 0,		-- 询问帮会列表(UCHAR)
	GUILD_PACKET_CG_CREATE          = 1,			-- 创建帮会
	GUILD_PACKET_CG_JOIN            = 2,			-- 加入帮会
	GUILD_PACKET_CG_ASKINFO         = 3,		-- 询问帮会信息
	GUILD_PACKET_CG_APPOINT         = 4,		-- 帮会任免
	GUILD_PACKET_CG_ADJUSTAUTHORITY = 5,        -- 调整帮会权限
	GUILD_PACKET_CG_RECRUIT         = 6,		-- 帮会收人
	GUILD_PACKET_CG_EXPEL           = 7,		-- 帮会踢人
	GUILD_PACKET_CG_WITHDRAW        = 8,		-- 提取帮资
	GUILD_PACKET_CG_DEPOSIT         = 9,		-- 存入帮资
	GUILD_PACKET_CG_LEAVE           = 10,		-- 离开帮会
	GUILD_PACKET_CG_DISMISS         = 11,		-- 解散帮会
	GUILD_PACKET_CG_DEMISE          = 12,		-- 解散帮会

	GUILD_PACKET_CG_CHANGEDESC      = 13,		-- 更改帮会宗旨

	GUILD_PACKET_CG_GW_SEPARATOR    = 14,	    -- 分隔符
}

define.GUILD_POISTION = {
    CHIEF = 9,
    ASS_CHIEF = 8,
    HR = 7,
    INDUSTRY = 6,
    AGRI = 5,
    COM = 4,
    ELITE_MEMBER = 3,
    MASSES = 2,
    PREPARE = 1,
}

define.GUILD_POISTION_NAME = {
    [define.GUILD_POISTION.CHIEF] = "帮主",
    [define.GUILD_POISTION.ASS_CHIEF] = "副帮主",
    [define.GUILD_POISTION.HR] = "内务使",
    [define.GUILD_POISTION.INDUSTRY] = "工务使",
    [define.GUILD_POISTION.AGRI] = "弘化使",
    [define.GUILD_POISTION.COM] = "商人",
    [define.GUILD_POISTION.ELITE_MEMBER] = "精英",
    [define.GUILD_POISTION.MASSES] = "帮众",
}

define.GUILD_AUTHORITY =
{
	GUILD_AUTHORITY_INVALID			= 0,

	GUILD_AUTHORITY_ASSIGN			= 0x1,		-- 职务调动权
	GUILD_AUTHORITY_AUTHORIZE		= 0x2,		-- 权限调整权
	GUILD_AUTHORITY_RECRUIT			= 0x4,		-- 接收帮众权
	GUILD_AUTHORITY_EXPEL			= 0x8,		-- 开除帮众权
	GUILD_AUTHORITY_DEMISE			= 0x10,		-- 禅让权
	GUILD_AUTHORITY_WITHDRAW		= 0x20,		-- 支取帮资权
	GUILD_AUTHORITY_DEPOSIT			= 0x40,		-- 存入金额权
	GUILD_AUTHORITY_LEAVE			= 0x80,		-- 离开帮会权（这个权限有点多余）

	GUILD_AUTHORITY_NUMBER			= 8,	-- 权限数量
	GUILD_AUTHORITY_CHIEFTAIN		= 0x7F,	-- 没有离开帮会的权限
}

define.TASK_EVENT =
{
	TASK_EVENT_KILLOBJ		= 0,	--杀死怪物
	TASK_EVENT_ENTERAREA	= 1,	--进入事件区
	TASK_EVENT_ITEMCHANGED	= 2,	--物品变化
	TASK_EVENT_PETCHANGED	= 3,	--宠物变化
    TASK_EVENT_LOCKTARGET   = 4,    --锁定目标
}

define.ENUM_MISSION_BONUS_TYPE =
{
	MISSION_BONUS_TYPE_INVALID	= -1,
	MISSION_BONUS_TYPE_MONEY    = 0,	-- 金钱
	MISSION_BONUS_TYPE_ITEM     = 1,	-- 物品
	MISSION_BONUS_TYPE_ITEM_RAND= 2,	-- 随机物品
	MISSION_BONUS_TYPE_ITEM_RADIO = 3,	-- 多选1物品
	MISSION_BONUS_TYPE_EXP      = 4,	-- 奖励经验
}

define.TEAM_FOLLOW_RESULT =
{
	TF_RESULT_REFUSE_FOLLOW = 0,	-- 队员拒绝跟随队长
	TF_RESULT_ENTER_FOLLOW  = 1,    -- 队员进入组队跟随状态
	TF_RESULT_STOP_FOLLOW   = 2,	-- 队员退出组队跟随状态
	TF_RESULT_FOLLOW_FLAG   = 3,	-- 通知客户端进入组队跟随状态的标记（ENTER_FOLLOW 的 quiet 模式）
}

define.TEAM_FOLLOW_ERROR =
{
	TF_ERROR_TOO_FAR            = 0,	-- 离队长太远了（而不能跟随）
	TF_ERROR_IN_TEAM_FOLLOW     = 1,	-- 已经处于组队跟随状态（而不能做某些操作）
	TF_ERROR_STALL_OPEN         = 2,	-- 正在摆摊
	TF_ERROR_NOT_IN_FOLLOW_MODE = 3,	-- 队伍目前不处于跟随状态
}

define.GAME_SETTING_FLAG =
{
	GSF_CANNOT_ADD_FRIEND			= 0,		-- 拒绝添加好友
	GSF_CANNOT_RECV_MAIL			= 1,		-- 拒绝接收邮件
	GSF_CANNOT_RECV_STRANGER_MAIL	= 2,		-- 拒绝接收陌生人邮件
	GSF_REFUSE_TEAM_INVITE			= 3,		-- 拒绝组队邀请

	GSF_REFUSE_LOOK_SPOUSE_INFO		= 16,		-- 拒绝查看配偶资料
	GSF_REFUSE_TRADE				= 17,		-- 拒绝交易
	GSF_CLOSE_POPUP					= 18,		-- 关闭当前泡泡框
	GSF_MANUAL_LEVEL_UP				= 19,		-- 手动升级
    GSF_AUTO_ACCEPT_TEAM_FOLLOW     = 24
};

define.EXCHANGE_ERR =
{
    ERR_ERR = 0,
    ERR_SELF_IN_EXCHANGE = 1,
    ERR_TARGET_IN_EXCHANGE = 2,
    ERR_DROP = 3,
    ERR_ALREADY_LOCKED = 4,
    ERR_ILLEGAL = 5,
    ERR_NOT_ENOUGHT_ROOM_SELF = 6,
    ERR_NOT_ENOUGHT_ROOM_OTHER = 7,
    ERR_NOT_ENOUGHT_EXROOM = 8,
    ERR_NOT_ENOUGHT_MONEY_SELF = 9,
    ERR_NOT_ENOUGHT_MONEY_OTHER = 10,
    ERR_TOO_FAR = 11,
    ERR_REFUSE_TRADE = 12,
    ERR_PET_LEVEL_TOO_HIGH = 13,
};

define.MAIL_TYPE =
{
	MAIL_TYPE_NORMAL = 0, --普通邮件
	MAIL_TYPE_SYSTEM = 1, --系统邮件
	MAIL_TYPE_SCRIPT = 2 , --脚本邮件，服务器端接收到此邮件后会调用一个脚本
	MAIL_TYPE_NORMAL2 = 3 , --系统给玩家代发
}

define.PLAYER_SHOP_ERR =
{
    ERR_ERR = 0,
    ERR_ILLEGAL = 1,
    ERR_CLOSE = 2,
    ERR_NOT_ENOUGH_LEVEL = 3,
    ERR_NAME_ALREADY_EXISTED = 4,
    ERR_ALREADY_HAVE_ENOUGH_SHOP = 5,
    ERR_NOT_ENOUGH_MONEY_TO_NEW = 6,
    ERR_NOT_ENOUGH_SHOP_IN_POOL = 7,
    ERR_NOT_ENOUGH_ROOM_IN_STALL = 8,
    ERR_ALREADY_LOCK = 9,
    ERR_NEED_NEW_COPY = 10,
    ERR_NOT_ENOUGH_ROOM = 11,
    ERR_NOT_ENOUGH_MONEY = 12,
    ERR_SHOP_ALREADY_EXIST = 13,
    ERR_SHOP_SUCCESS_SELL = 14,
    ERR_SHOP_SUCCESS_CHANGE_DESC = 15,
    ERR_SHOP_SUCCESS_CHANGE_NAME = 16,
    ERR_PET_LEVEL_TOO_HIGH = 17,
    ERR_SHOP_BASE_MONEY_TOO_LOW = 18,
    ERR_SHOP_SALE_OUT_SERIAL_IS_CHANGED = 19,
    ERR_SHOP_STILL_STALL_OPEN = 20,
    ERR_SHOP_NOT_ENOUTH_MONEY_TO_SALE_OUT = 21,
    ERR_SHOP_NOT_ENOUTH_MONEY_TO_BUY_BACK = 22,
    ERR_SHOP_NOT_ENOUTH_MONEY_TO_CHANGE_NAME = 23,
    ERR_SHOP_PARTNER_LIST_FULL = 24,
    ERR_SHOP_PARTNER_ALREADY_IN_LIST = 25,
    ERR_SHOP_PARTNER_NOT_FIND_IN_WORLD = 26,
    ERR_SHOP_PARTNER_INVALID = 27,
    ERR_SHOP_PARTNER_LIST_EMPTY = 28,
    ERR_SHOP_PARTNER_NOT_FIND_IN_LIST = 29,
    ERR_SHOP_ADD_TO_FAVORITE = 30,
    ERR_SHOP_DEL_FROM_FAVORITE = 31,
    ERR_SHOP_NOT_ENOUTH_MONEY_TO_EXPAND = 32,
}

define.RET_TYPE_PARTNER =
{
    RET_TYPE_INVALID            = -1,	--非法错误
    RET_TYPE_ALREADY_IN_LIST    = 0,    --合作者已在列表中
    RET_TYPE_NOT_FIND_IN_WORLD  = 1,    --合作者没有找到
    RET_TYPE_NOT_FIND_IN_LIST   = 2,	--合作者不在列表
    RET_TYPE_LIST_FULL          = 3,	--列表已满
    RET_TYPE_LIST_EMPTY         = 4,    --列表已满
    RET_TYPE_SUCCESS            = 5,	--操作成功
};

define.PLAYER_SHOP_TYPE = {
    TYPE_ERR = 0,
    TYPE_ITEM = 1,
    TYPE_PET = 2,
    TYPE_BOTH = 3,
}
define.TITILE = {
    SPOUSE = 22,
    JIEBAI = 24,
    SHITU = 25,
    SHOP_1 = 26,
    SHOP_2 = 27,
    MASTER = 28,
    MOOD = 36,
}

-- 帮众的通用权限
define.GUILD_AUTHORITY.GUILD_AUTHORITY_MEMBER	= define.GUILD_AUTHORITY.GUILD_AUTHORITY_DEPOSIT | define.GUILD_AUTHORITY.GUILD_AUTHORITY_LEAVE
define.GUILD_AUTHORITY.GUILD_AUTHORITY_ASSCHIEFTAIN	= define.GUILD_AUTHORITY.GUILD_AUTHORITY_ASSIGN | define.GUILD_AUTHORITY.GUILD_AUTHORITY_RECRUIT | define.GUILD_AUTHORITY.GUILD_AUTHORITY_EXPEL | define.GUILD_AUTHORITY.GUILD_AUTHORITY_LEAVE
define.GUILD_AUTHORITY.GUILD_AUTHORITY_HR = define.GUILD_AUTHORITY.GUILD_AUTHORITY_ASSCHIEFTAIN

define.GUILD_POSITION_INVALID			= 0			--无效位置
define.GUILD_POSITION_TRAINEE			= 1			--预备帮众，待批准
define.GUILD_POSITION_MEMBER			= 2			--普通帮众
define.GUILD_POSITION_ELITE_MEMBER	    = 3			--精英帮众
define.GUILD_POSITION_COM				= 4			--商业官员
define.GUILD_POSITION_AGRI				= 5			--农业官员
define.GUILD_POSITION_INDUSTRY			= 6			--工业官员
define.GUILD_POSITION_HR				= 7			--人事官员
define.GUILD_POSITION_ASS_CHIEFTAIN=	8			--副帮主
define.GUILD_POSITION_CHIEFTAIN		=	9			--帮主
--心法等级
define.XINFA_LEVEL = {
    XINFA1 = 60,
    XINFA2 = 60,
    XINFA3 = 60,
    XINFA4 = 60,
    XINFA5 = 60,
    XINFA6 = 60,
}


define.MAX_PLAYER_SHOP_COUNT = 250
define.STRIKE_POINT_SEGMENT_SIZE = 3
define.ZERO_VALUE = 0.01
define.MAX_GEM_QUALITY = {
	["publish_xws"] = 8,
	["publish_yu"] = 8,
}
define.MAX_ABILITY_PRESCRIPTION_NUM = (8 * 256)
define.IDENT_LEVEL_RANGE = 9
define.HUMAN_MAX_LEVEL = 201 -- exclusive: playable character levels 1..200
define.MAX_OBJ_ID = 25000
define.COMMISION_SHOP_SCRIPT_ID = 800116
define.SCENE_SCRIPT_ID = 888888
define.MAIL_SCRIPT_ID = 888889
define.PRIZE_SCRIPT_ID = 888899
define.YUANBAO_PIAO = 30501036
define.TIANWAI_COIN_1 = 38008157
define.TIANWAI_COIN_10 = 38008158
define.CHEDIFULU_DATA_SIZE = 30
define.SOLD_OUT_SIZE = 5
define.PET_BAG_SIZE = 10
define.BUY_BACK_INDEX = 200
define.MAX_GRID_MEMBER = 30
define.MAX_TEAM_MEMBER = 6
define.LEADER_ID = 1
define.SPEAKER_SCRIPT_ID = 330003
define.DEFAULT_WASHPOINT_LEVEL = 30
define.LEVELDELTA_CALLUP = 10
define.CALL_UP_PET = 2
define.PET_SOUL_MELTING = 1652
define.INVALID_GUID = -1
define.HALF_PI = math.pi / 2
define.DELAY_TIME = 5000
define.REFOLLOW_DISTSQR_C = 225
define.PETCOMMON = 335000
define.PET_LEVEL_NUM = 125
define.PET_APPERCEIVESKILLRATE_NUM = 56
define.DARK_ITEM_SCRIPT = 332207
define.PET_MAX_SKILL_COUNT = 7
define.PK_MODE_CHANGE_DELAY = 10 * 60 * 1000
define.DEF_SERVER_ADJUST_POS_WARP_DIST = 5
define.MAX_CREATE_PLAYER_NUM = 3
define.MIN_DELAY_TIME = 50
define.STALL_BOX_SIZE = 20
define.KFS_FILLING_IN_SKILL = 3238
define.STRIKE_POINT_SEGMENT_SIZE = 3
define.MENPAI_HEART_BEAT_TICK = 2500
define.HEART_BEAT_INTERVAL = 60
define.COPY_SCENE_BEGIN = 10000
define.SPAN_COPY_SCENE_BEGIN = 20000
define.MD_TIAOZHAN_SCRIPT = 28 -- 擂台挑战副本脚本号
define.MD_WDDAO_FOUR_1 = 541				--底层占用	无协议武道四
define.MD_WDDAO_FOUR_2 = 542				--底层占用	无协议武道四
define.MD_WDDAO_FOUR_3 = 543				--底层占用	无协议武道四
define.MD_WDDAO_FOUR_4 = 544				--底层占用	无协议武道四
define.CITY_BUILDING_ABILITY_SCRIPT	=	600022
define.DEFAULT_SCENEID_AND_WORLD_POS = {
    sceneid = 2,
    world_pos = {x = 160, y = 150} -- cs3a2: diem dung CY dali_new_320 (SceneAttr CY dong 2)
}
define.UINT_MAX = 4294967295
define.UCHAR_MAX = 255
define.USHORT_MAX = 65535
define.MAX_CHAR_MISSION_NUM = 20
define.STUDY_MENPAI_QINGGONG_SPEND = 100
define.ABILITY_TEACHER_SHOP = 11 -- 导师买工具商店
define.ABILITY_STUDY = 0 -- 学习技能
define.ABILITY_STUDY_OK = 2 -- 学习技能确认
define.ABILITY_STUDY_CANCEL = 3 -- 学习技能取消
define.ABILITY_DIALOG = {21, 22, 23, 24, 25} -- 技能说明对话
define.CopyScene_LevelGap = 31 -- 副本存玩家平均级别与怪物默认级别的级别差，差值用于场景初始化时对怪物级别进行调整，此编号固定不能改
-- 总任务数量
define.MAX_MISSION_NUM = (4096)
define.MAX_CHAR_MISSION_FLAG_LEN =
    math.floor((define.MAX_MISSION_NUM + 31) / 32)
define.MAX_CHAR_MISSION_DATA_NUM = 992
define.ATTR_REFESH_TIME = 500
define.MAIN_CITY = {
    [0] = true,
    [1] = true,
    [2] = true,
}

define.INIT_AOI_SCENE = 123
define.INIT_AOI_SERVICE = {
    [define.INIT_AOI_SCENE] = true,
}
define.EXCHANGE_BOX_SIZE = 5
define.QUALITY_MUST_BE_CHANGE        = 0 -- 可能需要被修改（这个参数值最后要被修改成下面的值）
define.QUALITY_CREATE_DEFAULT        = 0 -- 默认规则
define.QUALITY_CREATE_BY_MONSTER     = 0 -- 怪物掉落规则
define.QUALITY_CREATE_BY_BOSS        = 1 -- BOSS怪掉落规则
define.QUALITY_CREATE_BY_FOUNDRY_NOR = 2 -- 低级材料锻造
define.QUALITY_CREATE_BY_FOUNDRY_ADV = 3 -- 高级材料锻造
define.ABILITY_PENGREN	= 1		--烹饪技能对应编号
define.ABILITY_ZHIYAO	= 2		--制药技能对应编号
define.ABILITY_XIANGQIAN	= 3		--镶嵌技能对应编号
define.ABILITY_ZHUZAO= 4		--铸造技能对应编号
define.ABILITY_FENGREN	= 5		--缝纫技能对应编号
define.ABILITY_GONGYI	= 6		--工艺制作技能对应编号
define.ABILITY_CAIKUANG	= 7		--采矿技能对应编号
define.ABILITY_CAIYAO	= 8		--采药技能对应编号
define.ABILITY_DIAOYU	= 9		--钓鱼技能对应编号
define.ABILITY_ZHONGZHI	= 10		--种植技能对应编号
define.ABILITY_KAIGUANG	= 11		--开光技能对应编号
define.ABILITY_SHENGHUOSHU	= 12		--圣火术技能对应编号
define.ABILITY_NIANGJIU	= 13		--酿酒技能对应编号
define.ABILITY_XUANBINGSHU	= 14		--玄冰术技能对应编号
define.ABILITY_ZHIGU	= 15		--制蛊技能对应编号
define.ABILITY_ZHIDU	= 16		--制毒技能对应编号
define.ABILITY_ZHIFU	= 17		--制符技能对应编号
define.ABILITY_LIANDAN	= 18		--炼丹技能对应编号
define.ABILITY_QIMENDUNJIA	= 19		--奇门遁甲技能对应编号
define.ABILITY_GONGCHENGXUE	= 20		--工程学技能对应编号
define.ABILITY_QUGUI	= 21		--驱鬼技能对应编号
define.ABILITY_WABAO	= 22		--挖宝技能对应编号
define.ABILITY_PAOSHANG	= 23		--跑商技能对应编号
define.ABILITY_SHAJIA	= 24		--杀价技能对应编号
define.ABILITY_REMAI	= 25		--热卖技能对应编号
define.ABILITY_CAOZUOZHONG	= 26		--操作中技能对应编号
define.ABILITY_YAOLI = 27		--药理技能对应编号
define.ABILITY_YANGSHENGFA = 28 --养生法
define.ABILITY_FOFA = 29	--佛法					少林 用于辅助	开光
define.ABILITY_CAIHUOSHU = 30	--采火术			明教 用于辅助	圣火术
define.ABILITY_LIANHUALUO = 31	--莲花落			丐帮 用于辅助	酿酒
define.ABILITY_CAIBINGSHU = 32	--采冰术			天山 用于辅助	玄冰术
define.ABILITY_JINGMAIBAIJUE = 33	--经脉百决		大理 用于辅助	制蛊
define.ABILITY_YINCHONGSHU = 34	--引虫术		星宿 用于辅助	制毒
define.ABILITY_LINGXINSHU = 35	--灵心术			峨嵋 用于辅助	制符
define.ABILITY_DAOFA = 36	--道法					武当 用于辅助	炼丹
define.ABILITY_LIUYIFENGGU = 37	--六艺风骨		逍遥 用于辅助	奇门遁甲
define.ABILITY_QISHU	= 38	--骑术
define.ABILITY_GPS	= 39	--定位符
define.ABILITY_HUOXUE	= 40	--活血
define.ABILITY_YANGQI	= 41	--养气
define.ABILITY_QIANGSHEN	=	42	--强身
define.ABILITY_JIANTI	=	43	--健体
define.ABILITY_XIUSHEN	=	44	--修身
define.ABILITY_SUTI	=	45	--塑体
define.ABILITY_CAILIAOHECHENG = 49	--材料合成	材料合成
define.ABILITY_NEWPENGREN = 59
define.ABILITY_NEWZHIYAO  = 60
define.ABILITY_GONGJVXILIAN = 61
define.ABILITY_GONGCHENG = 62
define.ABILITY_NEW_CAIYAO 	= 63		--新采药技能对应编号
define.ABILITY_NEW_CAIKUANG	= 64		--新采矿技能对应编号
define.V_ZHONGZHI_ID = {20104001,20104002,20104003,20104004,20104005,20104006,20104007,20104008,20104009,20104010,
				20104011,20104012,20105001,20105002,20105003,20105004,20105005,20105006,20105007,20105008,
				20105009,20105010,20105011,20105012}
define.V_ZHONGZHI_NAME = {"早产小麦","早产大米","早产玉米","早产花生","早产红薯","早产高粱","早产芝麻","早产绿豆","早产黄豆","早产蚕豆",
					"早产马铃薯","早产芋头","早产苎麻","早产草棉","早产亚麻","早产木棉","早产黄麻","早产云棉","早产槿麻","早产绒棉",
					"早产青麻","早产彩棉","早产罗布麻","早产陆地棉",
					"晚产小麦","晚产大米","晚产玉米","晚产花生","晚产红薯","晚产高粱","晚产芝麻","晚产绿豆","晚产黄豆","晚产蚕豆",
					"晚产马铃薯","晚产芋头","晚产苎麻","晚产草棉","晚产亚麻","晚产木棉","晚产黄麻","晚产云棉","晚产槿麻","晚产绒棉",
					"晚产青麻","晚产彩棉","晚产罗布麻","晚产陆地棉"}
--种植产品的等级
define.V_ZHONGZHI_NEEDLEVEL = {1,2,3,4,5,6,7,8,9,10,
						11,12,1,2,3,4,5,6,7,8,
						9,10,11,12}
--种植时放入的幼苗生长点在growpoint.txt中的编号
define.V_ZHONGZHI_ITEMBOX_ID = {501,504,507,510,513,516,519,522,525,528,
531,534,537,540,543,546,549,552,555,558,
561,564,567,570,
701,704,707,710,713,716,719,722,725,728,
731,734,737,740,743,746,749,752,755,758,
761,764,767,770}
define.LUAAUDIT_FEIHUANGSHI = 20;--[tx43454]兑换飞蝗石
define.LUAAUDIT_FEIHUANGSHI_BOUND = 21
define.XIULIAN_GONGLI = 316  --修炼功力
define.XIULIAN_JINGJIE_1 = 317 --境界数据
define.XIULIAN_JINGJIE_2 = 318 --境界数据
define.QUALITY_MUST_BE_CHANGE        = 0 -- 可能需要被修改（这个参数值最后要被修改成下面的值）
define.QUALITY_CREATE_DEFAULT        = 0 -- 默认规则
define.QUALITY_CREATE_BY_MONSTER     = 0 -- 怪物掉落规则
define.QUALITY_CREATE_BY_BOSS        = 1 -- BOSS怪掉落规则
define.QUALITY_CREATE_BY_FOUNDRY_NOR = 2 -- 低级材料锻造
define.QUALITY_CREATE_BY_FOUNDRY_ADV = 3 -- 高级材料锻造
define.AOI_RADIS = 20.0 --aoi距离  修改这个一定要把c模块的也改了
define.MAX_VIEW_DIST_SQ = (1.2 * define.AOI_RADIS) * (1.2 * define.AOI_RADIS)
--使用StoreMap 返回类型
define.USEITEM_SUCCESS			=	0
define.USEITEM_CANNT_USE		=	1
define.USEITEM_LEVEL_FAIL		=	2
define.USEITEM_TYPE_FAIL		=	3
define.USEITEM_SKILL_FAIL		=	4
define.USEITEM_INVALID			=	5
define.ABILITYLOGIC_ID = 701601
define.ProCreateTargetLevel = {30, 50, 70, 90, 110}
define.ENUM_PK_VALUE_RANGE =
{
	PK_VALUE_RANGE_1	= 1,
	PK_VALUE_RANGE_20	= 20,
	PK_VALUE_RANGE_40	= 40,
	PK_VALUE_RANGE_60	= 60,
	PK_VALUE_RANGE_80	= 80,
	PK_VALUE_RANGE_MAX	= 1000,
}

define.ENUM_HUMAN_DIE_TYPE =
{
	HUMAN_DIE_TYPE_INVALID      = -1,
	HUMAN_DIE_TYPE_INTERCHANGE  = 0,	-- 切磋
	HUMAN_DIE_TYPE_MONSTER_KILL = 1,	-- 被怪杀死
	HUMAN_DIE_TYPE_PLAYER_KILL  = 2,	-- 被玩家杀死
	HUMAN_DIE_TYPE_NUMBERS      = 3,
}
--增加某区经验倍数  支持小数  当前经验情况增加  X  倍   暂不用
-- define.ADD_EXP_RATE = {
	-- ["debug"] = 1,
-- }
define.MILD_ANTI_ADDICTION_KILL_MONSTER_COUNT = {
	["moren"] = 999999999,					--默认减少收益  不动删此键 没有配置的环境读此项（已关闭）

	-- ["publish_xhz"] = 100000,
	["publish_yu"] = 999999999,
}
define.HEAVY_ANTI_ADDICTION_KILL_MONSTER_COUNT = {
	["moren"] = 999999999,					--默认无收益  不动删此键 没有配置的环境读此项（已关闭）

	-- ["publish_xhz"] = 100000,
	["publish_yu"] = 999999999,
}
-- define.MILD_ANTI_ADDICTION_KILL_MONSTER_COUNT = 7000
-- define.HEAVY_ANTI_ADDICTION_KILL_MONSTER_COUNT = 10000
define.PET_BANK_SIZE = 10
define.PET_BAG_SIZE = 10
define.UINT32_MAX = 2^32 - 1
define.INT32_MAX = 2^31 - 1
define.DEFAULT_BAG_SIZE = 20
define.DEFAULT_PET_NUM = 6
define.MAX_BANK_BAG_SIZE = 160
define.MAX_PET_BANK_BAG_SIZE = 10
define.ADD_PET_NumOfREPRODUCTION_LEVELS = {
    [30] = true,
    [50] = true,
    [70] = true,
    [90] = true,
    [110] = true,
}

define.WORLD_TIME =
{
	WT_IND_1 = 0,	--子时
	WT_IND_2 = 1,	--丑时
	WT_IND_3 = 2,	--寅时
	WT_IND_4 = 3,	--卯时
	WT_IND_5 = 4,	--辰时
	WT_IND_6 = 5,	--巳时
	WT_IND_7 = 6,   --午时
	WT_IND_8 = 7,	--未时
	WT_IND_9 = 8,	--申时
	WT_IND_10 = 9,	--酉时
	WT_IND_11 = 10, --戌时
	WT_IND_12 = 11, --亥时
}

define.BUILDING_TYPE = {
	BUILDING_XIANYA = 0,					--县衙0
	BUILDING_XIANGFANG = 1,					--厢房1
	BUILDING_JIUSI = 2,						--酒肆2
	BUILDING_QIANZHUANG = 3,				--钱庄3
	BUILDING_FANGJUFANG = 4,				--防具4
	BUILDING_DUANTAI = 5,					--锻台5
	BUILDING_WUJUFANG = 6,					--武具6
	BUILDING_MICANG = 7,					--米仓7
	BUILDING_CHENGQIANG = 8,				--城墙8
	BUILDING_JIFANG = 9,					--集仿9
	BUILDING_YISHE = 10,					--医舍10
	BUILDING_WUFANG = 11,					--武仿11
	BUILDING_JIANTA = 12,					--箭塔12
	BUILDING_SHUFANG = 13,					--书房13
	BUILDING_QIJI = 14,						--奇迹14
	BUILDING_XIAOCHANG = 15,				--校场15
	BUILDING_HUOBINGTA = 16,				--火冰塔16
	BUILDING_DAQI = 17,						--大旗17

	BUILDING_MAX = 18,
}

define.ZDZD_MISSION_ID = {
    496, 497, 498, 499, 500, 501, 513
}
define.MF = {
    { 18, 19, 20, 21, 22, 23, 24, 25, 26, 27 },
    {
        502, 503, 504, 505, 506, 507, 508, 509,
        510, 511, 720, 721, 722, 723, 724, 725,
        726, 727, 728, 729, 904, 905, 906, 907,
        908, 909, 910, 911, 912, 913
    }
}

define.MD_2_CLIENT = {
    [50] = 496,
    [51] = 497,
    [52] = 498,
    [53] = 499,
    [54] = 500,
    [55] = 501,
    [66] = 513,
    [78] = 723,
    [90] = 813,
    [100] = 854,
    [122] = 943,
}

define.CITY_INIT_BUILDINGS = {
    [define.BUILDING_TYPE.BUILDING_CHENGQIANG] = 0,
    [define.BUILDING_TYPE.BUILDING_JIUSI] = 1,
    [define.BUILDING_TYPE.BUILDING_JIFANG] = 2,
    [define.BUILDING_TYPE.BUILDING_FANGJUFANG] = 3,
    [define.BUILDING_TYPE.BUILDING_WUFANG] = 4,
    [define.BUILDING_TYPE.BUILDING_WUJUFANG] = 5,
    [define.BUILDING_TYPE.BUILDING_XIANGFANG] = 6,
    [define.BUILDING_TYPE.BUILDING_XIAOCHANG] = 7,
    [define.BUILDING_TYPE.BUILDING_DUANTAI] = 8,
    [define.BUILDING_TYPE.BUILDING_YISHE] = 9,
    [define.BUILDING_TYPE.BUILDING_SHUFANG] = 10,
    [define.BUILDING_TYPE.BUILDING_DAQI] = 11,
    [define.BUILDING_TYPE.BUILDING_MICANG] = 13,
    [define.BUILDING_TYPE.BUILDING_QIANZHUANG] = 15,
    [define.BUILDING_TYPE.BUILDING_XIANYA] = 17,
}
define.MAX_CITY_SCENE = 108
define.GUILD_WAR_LIST = 32
define.GUILD_WILD_WAR_LIST = 3
define.ASK_TYPE =
{
	ASK_TYPE_LOGIN = 0, --用户刚登陆游戏时发送的邮件检查消息, --如果有邮件，服务器发送通知消息
	ASK_TYPE_MAIL = 1,	--用户向服务器提出需要邮件的消息,--如果有邮件则发送邮件数据
}
define.MAX_STALL_NUM_PER_SHOP = 10
define.MANTUO_XUANYINQV_COLLECTION_ID = 313
define.CHANGE_NAME_SCRIPT_ID = 808008
define.TRANSFER_IMPACT_ID = 334
define.RIDE_IMPACT_ID = 99
define.YUANBAOPIAO_MAX_VALUE = 50000
define.TELE_PORT_SKILLS = {
    [524] = true,
    [379] = true,
    [764] = true,
    [503] = true
}
define.BIND_YUANBAO_SHOPS = {
    [209] = true,
    [211] = true,
    [212] = true,
    [213] = true,
    [215] = true,
    [216] = true,
    [217] = true,
    [218] = true,
}

--特定商店特定的人才可以打开  配置方式如下  [商店号] = "SHOP_商店号"
define.LIMIT_SHOP_HUMAN = {
	-- [666] = "SHOP_666",
}


--限量商店配置，没有则留空  配置示例如下
-- define.LIMIT_SHOP = {
    -- [888] = 1,
    -- [777] = 1,
    -- [666] = 1,
-- }
define.LIMIT_SHOP = {


}

--全区限量商店  [商店号] = 更新周期(单位:天)  永不更新 写 -1
define.REGION_LIMITED_SHOP = {
	[253] = 1,
	-- [999] = -1,

}

define.LEVEL_POINT_REMAIN = {
    { level = 0, add_point = 0 },
    { level = 30, add_point = 1 },
    { level = 40, add_point = 2 },
    { level = 50, add_point = 3 },
}
define.QIANZHUANG_BAN_SKILLS = {
    [524] = true, [503] = true, [379] = true, [764] = true
}
define.COMPOUND_MAT_ITEM_INDEX = {
    [46] = {
        [20500001] = true, [20500002] = true, [20500003] = true, [20500004] = true,
        [20500005] = true, [20500006] = true, [20500007] = true, [20500008] = true,
    },
    [47] = {
        [20501001] = true, [20501002] = true, [20501003] = true, [20501004] = true,
        [20501005] = true, [20501006] = true, [20501007] = true, [20501008] = true,
    },
    [48] = {
        [20502001] = true, [20502002] = true, [20502003] = true, [20502004] = true,
        [20502005] = true, [20502006] = true, [20502007] = true, [20502008] = true,
    },
    [54] = {
        [20600000] = true, [20600001] = true, [20600002] = true, [20600003] = true,
        [20600004] = true
    }
}
define.FWQ_EXT_ATTRS = {
    define.ITEM_ATTRIBUTE.IATTRIBUTE_POINT_MAXHP,
    define.ITEM_ATTRIBUTE.IATTRIBUTE_POINT_MAXMP,

    define.ITEM_ATTRIBUTE.IATTRIBUTE_COLD_ATTACK,
    define.ITEM_ATTRIBUTE.IATTRIBUTE_FIRE_ATTACK,
    define.ITEM_ATTRIBUTE.IATTRIBUTE_LIGHT_ATTACK,
    define.ITEM_ATTRIBUTE.IATTRIBUTE_POISON_ATTACK,

    define.ITEM_ATTRIBUTE.IATTRIBUTE_REDUCE_TARGET_COLD_RESIST,
    define.ITEM_ATTRIBUTE.IATTRIBUTE_REDUCE_TARGET_FIRE_RESIST,
    define.ITEM_ATTRIBUTE.IATTRIBUTE_REDUCE_TARGET_LIGHT_RESIST,
    define.ITEM_ATTRIBUTE.IATTRIBUTE_REDUCE_TARGET_POISON_RESIST,

    define.ITEM_ATTRIBUTE.IATTRIBUTE_CON,
    define.ITEM_ATTRIBUTE.IATTRIBUTE_INT,
    define.ITEM_ATTRIBUTE.IATTRIBUTE_DEX,
    define.ITEM_ATTRIBUTE.IATTRIBUTE_ALL,
    define.ITEM_ATTRIBUTE.IATTRIBUTE_SPR,
    define.ITEM_ATTRIBUTE.IATTRIBUTE_STR,

    define.ITEM_ATTRIBUTE.IATTRIBUTE_HIT,
    define.ITEM_ATTRIBUTE.IATTRIBUTE_MISS,
    define.ITEM_ATTRIBUTE.IATTRIBUTE_2ATTACK_RATE,
    define.ITEM_ATTRIBUTE.IATTRIBUTE_LUK,

    define.ITEM_ATTRIBUTE.IATTRIBUTE_ATTACK_P,
    define.ITEM_ATTRIBUTE.IATTRIBUTE_ATTACK_M,

    define.ITEM_ATTRIBUTE.IATTRIBUTE_DEFENCE_P,
    define.ITEM_ATTRIBUTE.IATTRIBUTE_DEFENCE_M,
}
define.PVP_RULE_0_BAN_SKILL = {
    [515] = true
}

define.MINORPASSWD_REQUEST_TYPE =
{
	MREQT_NONE							= 0,
	MREQT_PASSWDSETUP                   = 1, -- 询问二级密码是否已经设置
	MREQT_DELETEPASSWDTIME              = 2, -- 询问是否处于强制解除阶段
	MREQT_SETPASSWD                     = 3, -- 设置二级密码
	MREQT_MODIFYPASSWD 					= 4, -- 修改二级密码
	MREQT_UNLOCKPASSWD                  = 5, -- 二级密码解锁
	MREQT_DELETEPASSWD                  = 6, -- 强制解除二级密码
}

define.MINORPASSWD_RETURN_TYPE =
{
	MRETT_NONE							= 0,
	MRETT_PASSWDSETUP 					= 1, --二级密码是否已经设置
	MRETT_DELETEPASSWDTIME              = 2, --二级密码解除剩余时间（或者不在解除阶段）
	MRETT_SETPASSWDSUCC                 = 3, --二级密码设置成功
	MRETT_MODIFYPASSWDSUCC              = 4, --二级密码修改成功
	MRETT_UNLOCKPASSWDSUCC              = 5, --二级密码解锁成功
	MRETT_DELETEPASSWDCANCEL            = 6, --强制解除二级密码失效
	MRETT_DELETEPASSWDSUCC              = 7, --二级密码强制解除成功

	MRETT_ERR_START                     = 8,
	MRETT_ERR_SETPASSWDFAIL             = 9,  --二级密码设置失败
	MRETT_ERR_MODIFYPASSWDFAIL			= 10, --二级密码修改失败
	MRETT_ERR_UNLOCKPASSWDFAIL          = 11, --二级密码解锁失败
	MRETT_ERR_DELETEPASSWDFAIL          = 12, --二级密码强制解除失败
}

define.OTHER_SKILL_OR_STATUS_COOLDOWN = 10000

--活动参数
define.ACTIVITY_JINZHU_ID = 395		--金猪活动ID
define.ACTIVITY_XIYOU_ID = 398		--西游BOSS活动ID
define.ACTIVITY_SIZHOU_ID = 399		--四洲千岛 



define.ACTIVITY_TICEK_SEC = 101
define.ACTIVITY_TICEK_MINUTE = 102


define.ACTIVITY_SCENE_FLAG = {





}


--场景参数
define.SCENE_TICEK_SEC = 101
define.SCENE_TICEK_MINUTE = 102
define.SCENE_BOXTIME = 103



--怪物参数
define.MONSTER_KILLBOX_GUID = 1
define.MONSTER_KILLBOX_COUNT = 2
define.MONSTER_KILLBOX_PROTECT_TIME = 3
define.MONSTER_KILLBOX_DELTIME = 4
define.MONSTER_DROPBOX_COUNT = 5
define.MONSTER_DROPBOX_DELTIME = 6
define.MONSTER_DATAID = 7
define.MONSTER_CREATE_POSX = 8
define.MONSTER_CREATE_POSZ = 9
define.MONSTER_CREATE_INDEX = 10


--99	某角色开启箱子时间
--100  箱子开启角色名  
define.MONSTER_START = 101

define.MONSTER_KILLBOX_ITEM_COUNT = 1000

define.MONSTER_DROPBOX_ITEM_COUNT = 2000

define.CESHI_XYID =
{
	[86] = true,
	[584] = true,


}

-- DFeng(武境巅峰): 服务端script_id → 客户端mission_id映射
-- 客户端写入公式: CDetailAttrib_Player[0x53D + client_mission_id * 4] = value
define.MD_SCRIPT_TO_CLIENT = {
    [960] = 1299,  -- MD_DFeng_Exp
    [961] = 1300,  -- MD_DFeng_Level
    [962] = 1301,  -- MD_DFeng_LevelupTimes
    [963] = 1302,  -- MD_DFeng_Attack1  → CData[0x1995]
    [964] = 1303,  -- MD_DFeng_Defence1 → CData[0x1999]
    [965] = 1304,  -- MD_DFeng_Open     → CData[0x199D]
    [966] = 1305,  -- MD_DFeng_Attack2  → CData[0x19A1]
    [967] = 1306,  -- MD_DFeng_Defence2 → CData[0x19A5]
    [968] = 1307,  -- MD_DFeng_Attack3  → CData[0x19A9]
    [969] = 1308,  -- MD_DFeng_Defence3 → CData[0x19AD]
    [970] = 1309,  -- MD_DFeng_WeekMark
    [971] = 1310,  -- MD_DFeng_KW_Levels1 心络孔位1-4等级
    [972] = 1311,  -- MD_DFeng_KW_Levels2 心络孔位5-8等级
    [973] = 1312,  -- MD_DFeng_KW_Levels3 心络孔位9-12等级
    [974] = 1313,  -- MD_DFeng_KW_Levels4 心络孔位13-16等级
    [975] = 1314,  -- MD_DFeng_KW_Levels5 心络孔位17-20等级
}

-- Capacity is independent of configured/playable factions. Extension data is empty by default.
require("menpai_registry").extend_definitions(define, require("menpai_extensions"))

return define
