local ScriptGlobal = {}
ScriptGlobal.MF_Dialog_01 = 0 -- 赵天师对话标记
ScriptGlobal.MF_GetAwardFlag = 1 -- 是否激活 CD-KEY 领取奖励条件
ScriptGlobal.MF_GetAward0Flag = 2 -- 是否已经领取初级 CD-Key 奖品
ScriptGlobal.MF_GetAward1Flag = 3 -- 是否已经领取 30 级 CD-Key 奖品
ScriptGlobal.MF_GetAward2Flag = 4 -- 是否已经领取 60 级 CD-Key 奖品
ScriptGlobal.MF_BUCHANG_MONEY = 5 --删档补偿是否领了钱
ScriptGlobal.MF_BUCHANG_STONE = 6 --删档补偿是否领了石头
ScriptGlobal.MF_BUCHANG_EQUIP = 7 --删档补偿是否领了装备
ScriptGlobal.MF_ActiveNewUserCard = 8 --是否激活新手卡,558
ScriptGlobal.MF_GetNewUserCard0 = 9 --是否已经领取1级新手卡奖品588
ScriptGlobal.MF_GetNewUserCard1 = 10 --是否已经领取15级新手卡奖品588
ScriptGlobal.MF_GetNewUserCard2 = 11 --是否已经领取30级新手卡奖品588
ScriptGlobal.MF_GetNewUserCard3 = 12 --是否已经领取40级新手卡奖品588
ScriptGlobal.MF_GetNewUserCard4 = 13 --是否已经领取50级新手卡奖品588
ScriptGlobal.MF_GetNewUserCard5 = 14 --是否已经领取60级新手卡奖品588
ScriptGlobal.MF_GetNewUserCard6 = 15 --是否已经领取70级新手卡奖品588
ScriptGlobal.MF_GetNewUserCard7 = 16 --是否已经领取80级新手卡奖品588
ScriptGlobal.MF_ActiveSportsCard = 17 --是否领取体育竞猜奖励
ScriptGlobal.MF_ActiveJuCard = 18 --是否领取网聚活动奖励
ScriptGlobal.MF_LunjianJiangli01 = 19 --华山论剑奖励标记01
ScriptGlobal.MF_LunjianJiangli02 = 20 --华山论剑奖励标记02
ScriptGlobal.MF_LunjianJiangli03 = 21 --华山论剑奖励标记03
ScriptGlobal.MF_AZHU_RELATION_RESET = 22 --阿朱关系值是否已经重置过了
ScriptGlobal.MF_CannotPrisonShenyuan = 23 --当前是否禁止伸冤
ScriptGlobal.MF_TianGongJiangli60 = 24 --天工开物60级奖励标记
ScriptGlobal.MF_TianGongJiangli70 = 25 --天工开物70级奖励标记
ScriptGlobal.MF_TianGongJiangli80 = 26 --天工开物80级奖励标记
ScriptGlobal.MF_CHOUJIANGDALIBAO01 = 27 --抽奖大礼包一级
ScriptGlobal.MF_CHOUJIANGDALIBAO02 = 28 --抽奖大礼包二级
ScriptGlobal.MF_DATAOSHA_WIN = 29 --大逃杀单回合获胜标记
ScriptGlobal.MF_ActiveWenZhouCard = 30 --温州推广活动标记
ScriptGlobal.MF_CHRISTMAS07_GIFT = 31 --07圣诞元旦活动_圣诞守夜礼物领取标记
ScriptGlobal.MF_LABORDAY_PETCAGE_GIFT = 32 --是否参加了2008/05/01的兽栏赠送活动
ScriptGlobal.MF_LABORDAY_PETCAGE_MAIL = 33 --是否收到了2008/05/01兽栏赠送活动邮件
ScriptGlobal.MF_ShiTuHelp_Mail = 34 --是否发送师徒总动员活动邮件
ScriptGlobal.MF_ShiTuHelp_30_prentice = 35 --自己是否领取过30级奖励
ScriptGlobal.MF_ShiTuHelp_30_master = 36 --师傅是否领取过30级奖励
ScriptGlobal.MF_ShiTuHelp_45_prentice = 37 --自己是否领取过30级奖励
ScriptGlobal.MF_ShiTuHelp_45_master = 38 --师傅是否领取过30级奖励
ScriptGlobal.MF_ShiTu_ChuShi_Flag = 39 --是否出师
ScriptGlobal.MF_DianHuaMiBao_Gift = 40 --是否领取了电话密保赠品 byLB JIA2008-7-29 10:26:30
ScriptGlobal.MF_AnBaoDaLiBao_Gift = 41 --是否领取了安保大礼包
ScriptGlobal.MF_ActiveNewUserCard666 = 42 --是否激活新手卡,666
ScriptGlobal.MF_GetNewUserCard0_666 = 43 --是否已经领取1级新手卡奖品666
ScriptGlobal.MF_GetNewUserCard1_666 = 44 --是否已经领取15级新手卡奖品666
ScriptGlobal.MF_GetNewUserCard2_666 = 45 --是否已经领取30级新手卡奖品666
ScriptGlobal.MF_GetNewUserCard3_666 = 46 --是否已经领取40级新手卡奖品666
ScriptGlobal.MF_GetNewUserCard4_666 = 47 --是否已经领取50级新手卡奖品666
ScriptGlobal.MF_GetNewUserCard5_666 = 48 --是否已经领取60级新手卡奖品666
ScriptGlobal.MF_GetNewUserCard6_666 = 49 --是否已经领取70级新手卡奖品666
ScriptGlobal.MF_GetNewUserCard7_666 = 50 --是否已经领取80级新手卡奖品666
ScriptGlobal.MF_Xueshengzhuang_flag = 51 --9月17日学生装活动是否已经参加过
ScriptGlobal.MF_BangZhan_Kill_Flag = 52 --帮战后的奖励（领取杀人次数最多称号）
ScriptGlobal.MF_BangZhan_Flag_Flag = 53 --帮战后的奖励（领取占领旗帜最多称号）
ScriptGlobal.MF_BangZhan_Source_Flag = 54 --帮战后的奖励（领取采集资源最多称号）
ScriptGlobal.MF_CHRISTMAS08_GIFT = 55 --08圣诞元旦活动_圣诞守夜礼物领取标记 zchw
ScriptGlobal.MF_NEWPLAYER10_USED = 56 --新人礼包（10级)是否使用过
ScriptGlobal.MF_GEM_PRIZE_FLAG = 57
ScriptGlobal.MF_TW_SCHOOLUNIFORM_JOIN = 58 --是否参加过海外天使校服养成计划
ScriptGlobal.MF_TW_EXPDAN10 = 59 --是否使用过10级经验丹
ScriptGlobal.MF_TW_EXPDAN20 = 60 --是否使用过20级经验丹
ScriptGlobal.MF_TW_EXPDAN30 = 61 --是否使用过30级经验丹
ScriptGlobal.MF_TW_EXPDAN40 = 62 --是否使用过40级经验丹
ScriptGlobal.MF_TW_EXPDAN50 = 63 --是否使用过50级经验丹
ScriptGlobal.MF_DARK_NOTIFYMAIL = 64
ScriptGlobal.MF_TW_ZONGHENGSIHAI_JOIN = 65 --天龙嘉年华之纵横四海活动参加过 xiehong
ScriptGlobal.MF_TW_BRAVERYCHALLENGE1 = 66 --台湾50勇者过车山任务一标志--zz
ScriptGlobal.MF_TW_BRAVERYCHALLENGE2 = 67 --台湾50勇者过车山任务二标志--zz（暂时废弃） 由于MissionFlag算法有问题，67会导致错误的结果
ScriptGlobal.MF_TW_BRAVERYCHALLENGE3 = 68 --台湾50勇者过车山任务三标志--zz
ScriptGlobal.MF_TW_BRAVERYCHALLENGE22 = 69 --台湾50勇者过车山任务二标志--zz
ScriptGlobal.MF_GetQianKunDai = 70 --是否领取过江湖乾坤袋(上线领及补领)
ScriptGlobal.MF_ILLIGAL_COOLDOWNCHECK = 109 --非法冷却池重置检查

ScriptGlobal.MF_JINGPAI_FOLLOWEDMIN = 111 --拍卖关注  111 - 210
ScriptGlobal.MF_JINGPAI_FOLLOWEDMAX = 210 --拍卖关注  111 - 210

ScriptGlobal.MF_SWEEP_ALL_MONTH_CARD = 752
ScriptGlobal.MF_SWEEP_ALL_DAY_CARD = 753
ScriptGlobal.MF_TRADE_TOKEN = 754 --交易令激活标记
ScriptGlobal.MF_TradeCard = 754    --交易卡激活标记(别名)

--门派ID号宏定义
ScriptGlobal.MP_MAX = 12
ScriptGlobal.MP_SHAOLIN = 0
ScriptGlobal.MP_MINGJIAO = 1
ScriptGlobal.MP_GAIBANG = 2
ScriptGlobal.MP_WUDANG = 3
ScriptGlobal.MP_EMEI = 4
ScriptGlobal.MP_XINGSU = 5
ScriptGlobal.MP_DALI = 6
ScriptGlobal.MP_TIANSHAN = 7
ScriptGlobal.MP_XIAOYAO = 8
ScriptGlobal.MP_WUMENPAI = 9
ScriptGlobal.MP_MANTUO = 10
ScriptGlobal.MP_ERENGU = 11
ScriptGlobal.MP_GUSU = 12

ScriptGlobal.MD_PINPAN_DAYCOUNT = 0 --100000的倍数是当前完成的环数，小于100000的数是时间
ScriptGlobal.MD_PINPAN_HUAN = 1 --平叛
ScriptGlobal.MD_WABAO_DAYCOUNT = 2 --100000的倍数是当前完成的环数，小于100000的数是时间
ScriptGlobal.MD_WABAO_HUAN = 3 --挖宝
ScriptGlobal.MD_BAIMASI_DAYCOUNT = 4 --年虫问题修复，此位置只存储白马寺任务环数 modified by zhangguoxin 090207
ScriptGlobal.MD_BAIMASI_HUAN = 5 --白马寺
ScriptGlobal.MD_SHUILAO_DAYCOUNT = 6 --100000的倍数是当前完成的环数，小于100000的数是时间
ScriptGlobal.MD_SHUILAO_HUAN = 7 --水牢
ScriptGlobal.MD_MURENXIANG_DAYCOUNT = 8 --100000的倍数是当前完成的环数，小于100000的数是时间
ScriptGlobal.MD_MURENXIANG_HUAN = 9 --木人巷
ScriptGlobal.MD_WENDA_DAYCOUNT = 10 --100000的倍数是当前完成的环数，小于100000的数是时间
ScriptGlobal.MD_WENDA_HUAN = 11 --问答
ScriptGlobal.MD_LINGLONG_DAYCOUNT = 12 --100000的倍数是当前完成的环数，小于100000的数是时间
ScriptGlobal.MD_LINGLONG_HUAN = 13 --玲珑
ScriptGlobal.MD_CAOYUN_DAYCOUNT = 14 --年虫问题修复，此位置只存储漕运任务环数 modified by zhangguoxin 090207
ScriptGlobal.MD_CAOYUN_HUAN = 15 --漕运
ScriptGlobal.MD_SHIMEN_DAYCOUNT = 16 --年虫问题修复，此位置只存储师门任务次数 modified by zhangguoxin 090208
ScriptGlobal.MD_SHIMEN_HUAN = 17 --九大门派师门任务
ScriptGlobal.MD_GAME_FLAG0 = 18 -- 游戏标记位
ScriptGlobal.MD_GAME_FLAG1 = 19 -- 游戏标记位
ScriptGlobal.MD_GAME_FLAG2 = 20 -- 游戏标记位
ScriptGlobal.MD_GAME_FLAG3 = 21 -- 游戏标记位
ScriptGlobal.MD_GAME_FLAG4 = 22 -- 游戏标记位
ScriptGlobal.MD_GAME_FLAG5 = 23 -- 游戏标记位
ScriptGlobal.MD_GAME_FLAG6 = 24 -- 游戏标记位
ScriptGlobal.MD_GAME_FLAG7 = 25 -- 游戏标记位
ScriptGlobal.MD_GAME_FLAG8 = 26 -- 游戏标记位
ScriptGlobal.MD_GAME_FLAG9 = 27 -- 游戏标记位
ScriptGlobal.MD_TIAOZHAN_SCRIPT = 28 --擂台挑战副本脚本号
ScriptGlobal.MD_ZHONGZHI_TIME = 29 --设置种植的时间，避免一个玩家同时种太多土地
ScriptGlobal.MD_FASONGTONGZHI_HUAN = 30 --发送通知的环数
ScriptGlobal.MD_PREV_CAMP = 31 --阵营号缓存，目前仅用于进入擂台是缓存进入前的阵营号
ScriptGlobal.MD_CATCH_PET = 32 --洛阳捉珍兽任务，记录环数
ScriptGlobal.MD_SEND_MAIL = 33 --洛阳送信任务，记录环数
ScriptGlobal.MD_RENWULIAN_DAYCOUNT = 34 --任务链 100000的倍数是当前完成的环数，小于100000的数是时间
ScriptGlobal.MD_RENWULIAN_HUAN = 35 --任务链的环数
ScriptGlobal.MD_CAOYUN_MONSTERTIMER = 36 --漕运的怪物出现次数
ScriptGlobal.MD_QUIZ_DAYCOUNT = 37 --智力问答每天做的次数，100000的倍数是当前完成的环数，小于100000的数是时间
ScriptGlobal.MD_CITY_ENGINEERING_ROUND = 38 --城市内政工程任务
ScriptGlobal.MD_CITY_ENGINEERING_TIME = 39 --城市内政工程任务放弃任务的时间
ScriptGlobal.MD_CITY_DEVELOPMENT_ROUND = 40 --城市内政发展任务
ScriptGlobal.MD_CITY_DEVELOPMENT_TIME = 41 --城市内政发展任务放弃任务的时间
ScriptGlobal.MD_CITY_SCITECH_ROUND = 42 --城市内政科技任务
ScriptGlobal.MD_CITY_SCITECH_TIME = 43 --城市内政科技任务放弃任务的时间
ScriptGlobal.MD_CITY_MARKET_ROUND = 330 --城市内政市集任务（修改）
ScriptGlobal.MD_CITY_MARKET_TIME = 331 --城市内政市集任务放弃任务的时间（修改）
ScriptGlobal.MD_FASONGTONGZHI_DAYCOUNT = 46 --年虫问题修复，此位置只存储发送通知次数 modified by zhangguoxin 090207
ScriptGlobal.MD_CAPTUREPETABANDON_TIME = 47 --捕捉珍兽放弃时间。Steven.Han 2006-8-15 14:18
ScriptGlobal.MD_SHIMEN_DOUBLE_EXP = 48 --师门是否为双倍经验的标识
ScriptGlobal.MD_CHENGXIONGDATU_DAYCOUNT = 49 --年虫问题修复，此位置只存储逞凶打图次数 modified by zhangguoxin 090208
ScriptGlobal.MD_CAOYUN_SUMTIME = 50 --漕运的总次数
ScriptGlobal.MD_CAOYUN_BARGAINUP = 51 --漕运的抬价时间
ScriptGlobal.MD_CAOYUN_BARGAINDOWN = 52 --漕运的杀价时间
ScriptGlobal.MD_QUIZ_ASKTIME = 53 --智力问答提问的时间
ScriptGlobal.MD_MIDAUTUMN_SCORE = 54 --中秋积分
ScriptGlobal.MD_CITY_EXPAND_ROUND = 55 --城市内政扩张任务
ScriptGlobal.MD_RENWULIAN_ACCPETTIME = 56 --任务链的接收时间
ScriptGlobal.MD_STOPWATCH_PAUSE_FLAG = 57
ScriptGlobal.MD_CITY_EXPAND_TIME = 58 --城市内政扩张任务放弃任务的时间
ScriptGlobal.MD_CITY_CONSTRUCT_ROUND = 59 --城市内政建设任务
ScriptGlobal.MD_CITY_CONSTRUCT_TIME = 60 --城市内政建设任务放弃任务的时间
ScriptGlobal.MD_CITY_RESEARCH_ROUND = 61 --城市内政研究任务
ScriptGlobal.MD_CITY_RESEARCH_TIME = 62 --城市内政研究任务放弃任务的时间
ScriptGlobal.MD_ThiefSoldierInvade = 63 --贼兵入侵积分
ScriptGlobal.MD_FUBENPARAM0 = 64 -- 副本参数1
ScriptGlobal.MD_FUBENPARAM1 = 65 -- 副本参数2
ScriptGlobal.MD_FUBENPARAM2 = 66 -- 副本参数3
ScriptGlobal.MD_FUBENPARAM3 = 67 -- 副本参数4
ScriptGlobal.MD_FUBENPARAM4 = 68 -- 副本参数5
ScriptGlobal.MD_FUBENPARAM5 = 69 -- 副本参数6
ScriptGlobal.MD_FUBENPARAM6 = 70 -- 副本参数7
ScriptGlobal.MD_FUBENPARAM7 = 71 -- 副本参数8
ScriptGlobal.MD_EXAM_TARGETID = 72 -- 科举系统点击的NPC ID
ScriptGlobal.MD_EXAM_STARTTIME = 73 -- 科举系统的开始时间
ScriptGlobal.MD_EXAM_SEQUENCE = 74 -- 科举系统的题的次序
ScriptGlobal.MD_EXAM_ASKTIME = 75 -- 科举系统的提问时间
ScriptGlobal.MD_EXAM_FLAG = 76 -- 科举系统的标记
ScriptGlobal.MD_ZHONGZHI_FLAG = 77 --设置种植的标记，他是种早产还是种晚产
ScriptGlobal.MD_LAST_QIJU_DAY = 78 --棋局活动的最后日期
ScriptGlobal.MD_CITY_MILITARY_ROUND = 79 -- 城市内政国防任务
ScriptGlobal.MD_CITY_MILITARY_TIME = 80 -- 城市内政国防任务放弃任务的时间
ScriptGlobal.MD_DATAOSHA_ROUND = 81 -- 大逃杀的比武回合数
ScriptGlobal.MD_DATAOSHA_RESULT = 82 -- 大逃杀的比武结果
ScriptGlobal.MD_EXAM_FEE_FLAG = 83 --科举的是否缴费的标记
ScriptGlobal.MD_CAOYUN_TARGETID = 84 --漕运点击的NPC记录
ScriptGlobal.MD_EXAM_BRIBE_FLAG = 85 --科举是否贿赂的标记
ScriptGlobal.MD_EXAM_FIGHT_FLAG = 86 --科举是否副本的标记
ScriptGlobal.MD_BUCHANG_MONEY = 87 --删档补偿是否领了钱
ScriptGlobal.MD_BUCHANG_STONE = 88 --删档补偿是否领了石头
ScriptGlobal.MD_BUCHANG_EQUIP = 89 --删档补偿是否领了装备
ScriptGlobal.MD_EXAM_QUESTION = 90 --科举中，当前问题是哪个。
ScriptGlobal.MD_RELATION_ABANDON = 91 -- 关系任务放弃后的限制时间
ScriptGlobal.MD_RELATION_MUWANQING = 92 -- 木婉清任务
ScriptGlobal.MD_RELATION_ZHONGLING = 93 -- 钟灵任务
ScriptGlobal.MD_RELATION_DUANYANQING = 94 -- 段延庆任务
ScriptGlobal.MD_RELATION_DUANYU = 95 -- 段誉任务
ScriptGlobal.MD_RELATION_AZHU = 96 -- 阿朱任务
ScriptGlobal.MD_RELATION_ABI = 97 -- 阿碧任务
ScriptGlobal.MD_RELATION_WANGYUYAN = 98 -- 王语嫣任务
ScriptGlobal.MD_RELATION_XIAOFENG = 99 -- 萧峰任务
ScriptGlobal.MD_RELATION_AZI = 100 -- 阿紫任务
ScriptGlobal.MD_RELATION_MURONGFU = 101 -- 慕容复任务
ScriptGlobal.MD_RELATION_XUZHU = 102 -- 虚竹任务
ScriptGlobal.MD_RELATION_JIUMOZHI = 103 -- 鸠摩智任务
ScriptGlobal.MD_RELATION_YINCHUAN = 104 -- 银川公主任务
ScriptGlobal.MD_QUIZ_TARGET = 105 --智力问答中，点的NPC的ID
ScriptGlobal.MD_MENPAI_BOUNTY = 106 --门派奖励的标记
ScriptGlobal.MD_MILITARY_ROND_POSITION = 107 --国防任务需要的
ScriptGlobal.MD_RENWULIAN_HONGYUN_LASTTIME = 108 --任务链的鸿运掉落的时间控制数据
ScriptGlobal.MD_FAVOROFGUILD_LASTTIME = 109 --上次领取帮派关怀的时间
ScriptGlobal.MD_MENPAI_BOUNTY_SHIZHUANG = 110 --门派时装每个人只能领取1次
ScriptGlobal.MD_RENWULIAN_EXCHANGEITEM = 111 --任务链用善恶值兑换物品的时间限制

ScriptGlobal.MD_EXCHANGE_MIJIORYAOJUE = 112 --是否已经领取秘籍和要诀

ScriptGlobal.MD_ROUNDMISSION1 = 113 -- 一个也不能跑再也不能随便放弃啦~！
ScriptGlobal.MD_CIRCUS_DAYCOUNT = 114 --马戏团：100000的倍数是当前完成的环数，小于100000的数是时间

ScriptGlobal.MD_ROUNDMISSION2 = 115 -- 任务放弃后的冷却时间,任务(除害)再也不能随便放弃啦~！
ScriptGlobal.MD_ROUNDMISSION3 = 116 -- 任务放弃后的冷却时间,任务(剿匪)再也不能随便放弃啦~！
ScriptGlobal.MD_NPC_DELMISSION = 117 --不能随便在NPC那删除任务啦~！明天才能再次删除.

ScriptGlobal.MD_JU_XUNHUAN_MUWANQING = 118
ScriptGlobal.MD_JU_XUNHUAN_MUWANQING_1 = 119
ScriptGlobal.MD_JU_XUNHUAN_ZHONGLING = 120
ScriptGlobal.MD_JU_XUNHUAN_ZHONGLING_1 = 121
ScriptGlobal.MD_JU_XUNHUAN_DUANYANQING = 122
ScriptGlobal.MD_JU_XUNHUAN_DUANYANQING_1 = 123
ScriptGlobal.MD_JU_XUNHUAN_DUANYU = 124
ScriptGlobal.MD_JU_XUNHUAN_DUANYU_1 = 125
ScriptGlobal.MD_JU_XUNHUAN_AZHU = 126
ScriptGlobal.MD_JU_XUNHUAN_AZHU_1 = 127
ScriptGlobal.MD_JU_XUNHUAN_ABI = 128
ScriptGlobal.MD_JU_XUNHUAN_ABI_1 = 129
ScriptGlobal.MD_JU_XUNHUAN_WANGYUYAN = 130
ScriptGlobal.MD_JU_XUNHUAN_WANGYUYAN_1 = 131
ScriptGlobal.MD_JU_XUNHUAN_XIAOFENG = 132
ScriptGlobal.MD_JU_XUNHUAN_XIAOFENG_1 = 133
ScriptGlobal.MD_JU_XUNHUAN_AZI = 134
ScriptGlobal.MD_JU_XUNHUAN_AZI_1 = 135
ScriptGlobal.MD_JU_XUNHUAN_MURONGFU = 136
ScriptGlobal.MD_JU_XUNHUAN_MURONGFU_1 = 137
ScriptGlobal.MD_JU_XUNHUAN_XUZHU = 138
ScriptGlobal.MD_JU_XUNHUAN_XUZHU_1 = 139
ScriptGlobal.MD_JU_XUNHUAN_JIUMOZHI = 140
ScriptGlobal.MD_JU_XUNHUAN_JIUMOZHI_1 = 141
ScriptGlobal.MD_JU_XUNHUAN_YINCHUAN = 142
ScriptGlobal.MD_JU_XUNHUAN_YINCHUAN_1 = 143
ScriptGlobal.MD_GUILDTICKET_TAKENTIMES = 144 -- 帮派银票一天领取的次数
ScriptGlobal.MD_GUILD_MIS_COUNT_TODAY = 145 --今天做的帮派任务的次数
ScriptGlobal.MD_PRE_GUILD_MIS_TIME = 146 --上一次完成帮派任务的时间

ScriptGlobal.MD_ROUNDMISSION1_TIMES = 147 -- 一个也不能跑每天接取的次数
ScriptGlobal.MD_ROUNDMISSION2_TIMES = 148 -- 除害每天接取的次数
ScriptGlobal.MD_ROUNDMISSION3_TIMES = 149 -- 剿匪每天接取的次数

ScriptGlobal.MD_KILL_CAOYUN_PAOSHANG_CT = 150 -- 一天时间里头打劫商人和漕运人的次数
ScriptGlobal.MD_KILL_CAOYUN_PAOSHANG_PRE_TIME = 151 --上一次打劫时间

-- 每个NPC的剧情循环任务，每日最多可以做50次。
ScriptGlobal.MD_JQXH_MUWANQING_LIMITI = 152 -- 100000的倍数是当前完成的环数，小于100000的数是时间
ScriptGlobal.MD_JQXH_ZHONGLING_LIMITI = 153 -- 同上
ScriptGlobal.MD_JQXH_DUANYANQING_LIMITI = 154 -- 同上
ScriptGlobal.MD_JQXH_DUANYU_LIMITI = 155 -- 同上
ScriptGlobal.MD_JQXH_AZHU_LIMITI = 156 -- 同上
ScriptGlobal.MD_JQXH_ABI_LIMITI = 157 -- 同上
ScriptGlobal.MD_JQXH_WANGYUYAN_LIMITI = 158 -- 同上
ScriptGlobal.MD_JQXH_XIAOFENG_LIMITI = 159 -- 同上
ScriptGlobal.MD_JQXH_AZI_LIMITI = 160 -- 同上
ScriptGlobal.MD_JQXH_MURONGFU_LIMITI = 161 -- 同上
ScriptGlobal.MD_JQXH_XUZHU_LIMITI = 162 -- 同上
ScriptGlobal.MD_JQXH_JIUMOZHI_LIMITI = 163 -- 同上
ScriptGlobal.MD_JQXH_YINCHUAN_LIMITI = 164 -- 同上

ScriptGlobal.MD_RELATION_QIANHONGYU = 165 -- 跟钱宏宇的关系值
ScriptGlobal.MD_CAOYUN_COMPLETE_TIME = 166 -- 漕运完成次数时间
-- ScriptGlobal.MD_DRAWPAY_TIME				= 167		-- 领取工资时间
-- ScriptGlobal.MD_SALARY_PAYTIME			= 168		-- 封测服务器工资发放时间
-- ScriptGlobal.MD_YUANBAO_PRIZE_GEM_COUNT	= 169		-- 元宝奖励宝石次数
ScriptGlobal.MD_JIAOFEI_TIMES = 170 -- 每天的剿匪次数，记录时间和次数
ScriptGlobal.MD_JIAOFEI_PRE_TIME = 171 -- 每天的剿匪次数，记录时间和次数
ScriptGlobal.MD_TDZ_TIME = 172 -- 使用药物土遁珠的一些需要的数据，郁闷中，放这里了
ScriptGlobal.MD_TDZ_SCENE = 173
ScriptGlobal.MD_TDZ_X = 174
ScriptGlobal.MD_TDZ_Y = 175
ScriptGlobal.MD_SPEAKER_STATE = 176 -- 正在使用的小喇叭物品索引号
ScriptGlobal.MD_BLUEHALO_DAYTIME = 177 -- 上次领取新蓝光环的时间
ScriptGlobal.MD_HUASHANJIANGLI_TIME = 178 --	华山论剑奖励时间
ScriptGlobal.MD_PEXP_GP_VALUE = 179 --	帮贡领取师傅经验值
ScriptGlobal.MD_PEXP_GP_TIME = 180 --	帮贡领取师傅经验时间
ScriptGlobal.MD_SHUILAO_ACCEPT_COUNT = 181 --	水牢每天接受任务的次数
ScriptGlobal.MD_SHUILAO_ACCEPT_TIME = 182 --	水牢接受任务的时间
ScriptGlobal.MD_JIAOFEI_KILL_BOSS_TIME = 183 -- 镜湖剿匪杀boss的总次数
ScriptGlobal.MD_SHANG_YUE_FANG_YIAN_HUA = 184 -- 美丽的夜西湖 赏月放烟花
-- ScriptGlobal.MD_ZHONGQIU_TUANYUANPIE1_DAYTIME		= 185		-- 上次以个人身份领取团圆欢庆月饼的时间
ScriptGlobal.MD_ZHONGQIU_TUANYUANPIE2_DAYTIME = 186 -- 上次以夫妻身份领取团圆欢庆月饼的时间
ScriptGlobal.MD_ZHONGQIU_TUANYUANPIE3_DAYTIME = 187 -- 上次以结拜身份领取团圆欢庆月饼的时间
ScriptGlobal.MD_ZHONGQIU_TUANYUANPIE4A_DAYTIME = 188 -- 上次以师傅身份领取团圆欢庆月饼的时间
ScriptGlobal.MD_ZHONGQIU_TUANYUANPIE4B_DAYTIME = 189 -- 上次以徒弟身份领取团圆欢庆月饼的时间
ScriptGlobal.MD_AZHU_TUERDUO_COUNT = 190 -- 阿朱循环任务 兔耳朵计数
ScriptGlobal.MD_PRISON_SHENYUAN_DAYTIME = 191 --上次伸冤的日期
ScriptGlobal.MD_COUPLEQUESTION_DAYTIME = 192 -- 夫妻做回答问题的时间，一天一次
ScriptGlobal.MD_CUJU_PRE_TIME = 193 -- 上一次参加蹴鞠活动的时间
ScriptGlobal.MD_MISSHENBING_WEAPONLEVEL = 194 -- 血欲神兵任务扣除的武器等级
ScriptGlobal.MD_YANZIWU_TIMES = 195 -- 每天进入燕子坞的次数
ScriptGlobal.MD_PRE_YANZIWU_TIME = 196 -- 上一次去燕子坞的时间
-- ScriptGlobal.MD_SHITU_PRIZE_COUNT = 197			-- 师徒抽奖次数
-- ScriptGlobal.MD_JOINMEIPAI_DAYTIME = 198		--上一次推荐玩家加入门派的日期
ScriptGlobal.MD_JOINMEIPAI_COUNT = 199 --今天推荐玩家加入门派的次数
ScriptGlobal.MD_LASTPLAYER_ID = 200 -- 上次所杀玩家的ID
ScriptGlobal.MD_XICONGTIANJIANG_LASTLV = 201 --07圣诞元旦活动_喜从天降 玩家上次参加本活动的级别
-- ScriptGlobal.MD_GETGIFT_COUNT = 202		  --圣诞元旦今天换取奖品次数
ScriptGlobal.MD_PLAYERSERVERID = 202 --玩家唯一ID标识
-- ScriptGlobal.MD_GETGIFT_TIME = 203		  --圣诞元旦今天换取奖品次数
-- ScriptGlobal.MD_DAOJISHIDATI_YUANDAN_DAYTIME = 204 --07圣诞元旦活动_倒计时答题玩家上次参加的时间
-- ScriptGlobal.MD_DAOJISHIDATI_EXP = 205 						--07圣诞元旦活动_倒计时答题玩家可以获得的经验
-- ScriptGlobal.MD_QIANXUN_FUQI_DAYTIME 	= 206		-- 接受千寻夫妻关系任务的时间
-- ScriptGlobal.MD_QIANXUN_JIEBAI_DAYTIME = 207		-- 接受千寻结拜关系任务的时间
-- ScriptGlobal.MD_QIANXUN_SHITU_DAYTIME 	= 208		-- 接受千寻师徒关系任务的时间
ScriptGlobal.MD_QIANXUN_SELECT_MISSIONTYPE = 209 -- 玩家所选的千寻任务类型
ScriptGlobal.MD_HANYUBED_USEBOOK_LASTDAY = 210 -- 更改为一天使用三次，寒玉谷泡点要诀
ScriptGlobal.MD_XINGYUN_DATA = 211 -- 玩家是否参与抽奖和3个奖品的类型
ScriptGlobal.MD_HANYUBED_CANADDEXP_COUNT = 212 -- 玩家在寒玉床可以获得经验的次数(寒玉床阀值功能) --更改为每日购买次数
ScriptGlobal.MD_XINGYUN_TIME_INFO = 213 -- 幸运轮盘时间信息
ScriptGlobal.MD_50WAN_TIME_INFO = 214 -- 50万同庆时间信息

ScriptGlobal.MD_CHUNJIE_TUANYUANJIAOZI1_DAYTIME = 215 -- 上次以个人身份领取的天之饺子时间 --内测福利暂时占用
ScriptGlobal.MD_CHUNJIE_TUANYUANJIAOZI2_DAYTIME = 216 -- 上次以夫妻身份领取天之饺子的时间
ScriptGlobal.MD_CHUNJIE_TUANYUANJIAOZI3_DAYTIME = 217 -- 上次以结拜身份领取天之饺子的时间
ScriptGlobal.MD_CHUNJIE_TUANYUANJIAOZI4A_DAYTIME = 218 -- 上次以师傅身份领取天之饺子的时间
ScriptGlobal.MD_CHUNJIE_TUANYUANJIAOZI4B_DAYTIME = 219 -- 上次以徒弟身份领取天之饺子的时间
ScriptGlobal.MD_CHUNJIE_BIANPAO_DAYTIME = 220 --上次领取鞭炮时间
ScriptGlobal.MD_CHUNJIE_BIANPAO_NUMBER = 221 --今天领取鞭炮个数
ScriptGlobal.MD_SPRING07DENGMI_DAYTIME = 222 --07元宵节活动_上次答灯谜时间
ScriptGlobal.MD_SHUANGXIANGPAO_LASTTIME = 223 --双响炮活动_上次抽奖日期和次数
ScriptGlobal.MD_GUILD_MANAGER_DRAW_BONUS = 224 --帮派官员领取福利时间
ScriptGlobal.MD_YURENJIE_LASTTIME = 225 --该位记录"愚人节活动"上次领取的时间(以天为单位)	--add by xindefeng
ScriptGlobal.MD_GODOFFIRE_DAYTIME = 226 --上次圣火传递活动的参加时间

-- ScriptGlobal.MD_LINGQUZHAOPAI_HAVESENDMAIL	=	227			--该位记录五一期间玩家登陆是否收到过"领取招牌活动"发送的邮件		--add by xindefeng
-- ScriptGlobal.MD_LINGQUZHAOPAI_LASTDATE = 228					--该位记录"五一领取招牌活动"上次领取的日期(以天为单位)	--add by xindefeng
-- ScriptGlobal.MD_GODOFFIRE_COMPLETE_COUNT	=	229				--该玩家完成圣火活动的次数
-- ScriptGlobal.MD_GODOFFIRE_COMPLETE_STEPNUM	=	230			--该玩家完成圣火活动任务链第几步
-- ScriptGlobal.MD_GODOFFIRE_COMPLETE_DAYTIME	=	231			--该玩家完成圣火活动的时间(以天为单位)
ScriptGlobal.MD_PIAOMIAOFENG_LASTTIME = 232 --上次挑战缥缈峰的日期和次数
ScriptGlobal.MD_SHITUZONGDONGYUAN_PRIZE_COUNT = 233 --师徒总动员当天领取奖品次数
ScriptGlobal.MD_PIAOMIAOFENG_SMALL_LASTTIME = 234 --上次挑战缥缈峰简单版的日期和次数
ScriptGlobal.MD_EX_HUMAN_QIANNENG_SUBJOIN = 235 --玩家对潜能点数的附加操作
ScriptGlobal.MD_SHITU_XINLIANXIN = 236 --师徒心连心奖励领取时间
ScriptGlobal.MD_GIFT_OUTLINE = 237 --离线经验馈赠类型
ScriptGlobal.MD_SIGNATURE_GETPRIZE_TIME = 238 -- 签名活动兑奖时间 zchw
ScriptGlobal.MD_SPY_DAYCOUNT = 239 -- 打探消息任务一天完成次数 个位保存次数 10的倍数为时间（天） zchw
ScriptGlobal.MD_SEEK_TREASURE = 240 -- 寻宝活动 zchw
ScriptGlobal.MD_XINSANHUAN_1_LAST = 241 --新三环任务第一环黄金之链任务的最后放弃时间
--接口重写
ScriptGlobal.MD_XINSANHUAN_1_DAYTIME = 227 --新三环任务第一环黄金之链任务的当日次数
ScriptGlobal.MD_XINSANHUAN_2_LAST = 228 --新三环任务第二环玄佛珠任务的最后放弃时间
ScriptGlobal.MD_XINSANHUAN_2_DAYTIME = 229 --新三环任务第二环玄佛珠任务的当日次数
ScriptGlobal.MD_XINSANHUAN_3_LAST = 230 --新三环任务第三环熔岩之地任务的最后放弃时间
ScriptGlobal.MD_XINSANHUAN_3_DAYTIME = 231 --新三环任务第三环熔岩之地任务的当日次数

ScriptGlobal.MD_BANGGONGPAI_DAYTIME = 247 --帮贡牌的当日次数
ScriptGlobal.MD_GUILD_COLLECT_DATA = 248 --帮派收集活动数据 zchw
ScriptGlobal.MD_REEXPERIENCE_WEDDING = 249 --重温婚礼 zchw
ScriptGlobal.MD_SHIMENCAIJI_COUNT = 250 --师门采集当天的次数
ScriptGlobal.MD_SHIMENCAIJI_DAY = 251 --师门采集的日期
ScriptGlobal.MD_QINGRENJIE_ARROWDAY = 252 --情人节活动上次领爱神之箭日期
ScriptGlobal.MD_QINGRENJIE_KISSDAY = 253 --情人节活动上次领取爱神之吻的日期
ScriptGlobal.MD_SHIMENCAIJI_ABANDON = 254 --师门采集活动当天的放弃次数
ScriptGlobal.MD_RESET_PMFSMALL_COUNT_LASTTIME = 255 --上次重置小缥缈峰挑战次数 的日期和次数
ScriptGlobal.MD_FINDFRIENDAD_DELTIME_MARRY = 256 --征友系统中，玩家上次撤销征婚信息的时间  --已扩展，可以加256
ScriptGlobal.MD_FINDFRIENDAD_DELTIME_GUILD = 257 --征友系统中，玩家上次撤销征帮派成员信息的时间
ScriptGlobal.MD_FINDFRIENDAD_DELTIME_TEACHER = 258 --征友系统中，玩家上次撤销征师徒信息的时间
ScriptGlobal.MD_FINDFRIENDAD_DELTIME_BROTHER = 259 --征友系统中，玩家上次撤销征兄弟信息的时间
ScriptGlobal.MD_GUILDBATTLE_SCORE = 260 --帮战个人积分
ScriptGlobal.MD_GUILDBATTLE_FLAG = 261 --帮战个人占领大旗次数
ScriptGlobal.MD_GUILDBATTLE_RES = 262 --帮战个人采集资源个数
ScriptGlobal.MD_GUILDBATTLE_PRIZESCORE = 263 --帮战个人荣誉积分
ScriptGlobal.MD_TW_REEXPERIENCE_WEDDING_TODAY_COUNT = 264
--重温婚礼今日次数 xiehong
ScriptGlobal.MD_TW_REEXPERIENCE_WEDDING_TOTAL_COUNT = 265
--重温婚礼总次数 xiehong
-- ScriptGlobal.MD_TW_HANYU_SPOUSEBOOK_LASTUSEDAY = 266 --夫妻行动要诀 zchw
-- ScriptGlobal.MD_HEXIE_GUANGHUAN_DATE	= 267		--和谐光环活动上一次加BUFF的日期（2009-3-26到2009-5-9） xiehong
-- ScriptGlobal.MD_HEXIE_GUANGHUAN_ScriptGlobal.MAIL_DATE	= 268		--和谐光环活动上一次发送邮件的日期（2009-3-26到2009-5-9） xiehong
ScriptGlobal.MD_LUOYANG_CITYMONEY = 269 --最后领取洛阳城市工资的时间
-- ScriptGlobal.MD_BAIBIANLIANPU_TIME = 270              --上次参加百变脸谱活动时间
ScriptGlobal.MD_MUWANQING_TUERDUO_COUNT = 271 --木婉清分组寻物 兔耳朵计数 zchw

ScriptGlobal.MD_TW_YURENJIE_LAST_LOGIN_DATE = 272 --愚人节上一次登陆时间 xiehong
ScriptGlobal.MD_TW_YURENJIE_LAST_GET_EXP_DATE = 273 --愚人节上一次领经验的时间 xiehong
ScriptGlobal.MD_JQXH_DUANYANQING_COUNT = 274 --段延庆任务任务计数 [tx]
--****begin****以下部分为年虫问题修复增加的missiondata add by zhangguoxin 090207*********************
ScriptGlobal.MD_CAOYUN_DAYTIME = 275 --漕运任务时间数据
ScriptGlobal.MD_FASONGTONGZHI_DAYTIME = 276 --发送通知的时间数据
ScriptGlobal.MD_BAIMASI_DAYTIME = 277 --白马寺任务 时间记录
ScriptGlobal.MD_CHENGXIONGDATU_DAYTIME = 278 --逞凶打图 时间数据
ScriptGlobal.MD_SHIMEN_DAYTIME = 279 --师门任务 时间数据
--****end******年虫问题修复增加的missiondata add by zhangguoxin 090207*******************************
ScriptGlobal.MD_LIXIAN_POOLEXP = 280 --离线经验池数据
ScriptGlobal.MD_TW_QIANDAO_LAST_JOIN_TIME = 281 --签到活动上一次时间 xiehong
ScriptGlobal.MD_TW_QIANDAO_JOIN_COUNT = 282 --签到次数 xiehong
ScriptGlobal.MD_TW_XINGFUMOTIANLUN_LAST_MAIL_DATE = 283 --幸福摩天轮，收取邮件日期 xiehong

ScriptGlobal.MD_TW_JIANIANHUA_XUANMU_DATE = 284 --参加嘉年华-旋转木马活动时间
ScriptGlobal.MD_TW_BRAVERYCHALLENGE_RESET = 285 --勇者过山车重置周标记 --zz
ScriptGlobal.MD_TW_BRAVERYCHALLENGE_GIFT = 286 --勇者过山车领奖 --zz
ScriptGlobal.MD_DAY_TO_HAVE_DWJKL = 297 --获得端午节快乐的时间[tx]五一活动
ScriptGlobal.MD_HK_TW_DAY_H1N1_COUNT = 306 --台湾香港H1N1活动每天的计数  
ScriptGlobal.XiaoXiang_CJ_DZP_WPH = 374	--转盘

ScriptGlobal.MD_LAST_MODIFYMENPAI_TIME = 1

ScriptGlobal.MD_SHUI_YUE_SHAN_ZHUANG_LASTTIME = 10001
--388 兑换元宝数
--389 消费元宝数
ScriptGlobal.MD_CHANGE_YUANBAO = 388  --兑换的元宝总数
ScriptGlobal.MD_COST_YUANBAO = 389    --消费的元宝总数
ScriptGlobal.MD_CHANGE_YUANBAO_RATE = 2000		--元宝兑换比例
--此值不是MD，是serverId  这里的ID 兑换总数时将用 MD_CHANGE_YUANBAO_NEW 来记录  废弃，无需配置这个
--全部默认用MD_CHANGE_YUANBAO_NEW_RATE  比例  MD_CHANGE_YUANBAO_OLD_RATE只是顺带获取下旧的记录来计算总充值数
ScriptGlobal.MD_SERVER_ID = {
	[10] = true,
	[11] = true,
	[12] = true,
	[13] = true,
}
ScriptGlobal.MD_CHANGE_POINTCOUNT = 598		--兑换的点数
ScriptGlobal.MD_CHANGE_YUANBAO_NEW_RATE = 1000		--此值不是MD是比例

ScriptGlobal.MD_HUIKUI_1 = 390		--充值回馈1重
ScriptGlobal.MD_HUIKUI_2 = 391		--充值回馈2重
ScriptGlobal.MD_HUIKUI_0 = 392		--0元回馈

--MD  游戏标记位 明细见 define.MF   502, 503, 504, 505, 506, 507, 508, 509,510, 511
--部分定义从520起记录，DataEx记录貌似有问题
ScriptGlobal.MD_SHAXING_DAYTIME = 517 --杀星副本当日次数
ScriptGlobal.MD_SEVENDAYTIME = 520 --新手七日礼
ScriptGlobal.MD_SEVENDAYTIME_DATA = 521 --新手七日礼
ScriptGlobal.MD_SERVER_DAYTIME = 522 --每日登陆记录
ScriptGlobal.MD_YU_LONG_TIE_END_TIME = 533
-- 534  紫金游龙卡
-- 535   荣誉点底层占用  （散人，避免功能移植时 索引被占用出异常）
ScriptGlobal.MD_PAIPAI = 536			--拍拍抽奖数据
ScriptGlobal.MD_WDDAO_FOUR_1 = 541				--底层占用	无协议武道四
ScriptGlobal.MD_WDDAO_FOUR_2 = 542				--底层占用	无协议武道四
ScriptGlobal.MD_WDDAO_FOUR_3 = 543				--底层占用	无协议武道四
ScriptGlobal.MD_WDDAO_FOUR_4 = 544				--底层占用	无协议武道四


ScriptGlobal.MD_CHOUJIANGLEIJI = 570	--抽奖累计
ScriptGlobal.MD_CHOUJIANGDUIHUAN = 571	--抽奖兑换
ScriptGlobal.MD_CHOUJIANGWUQI = 572	--抽奖武器

ScriptGlobal.MD_JINGPAI_YUANBAO_CLIENT = 599
ScriptGlobal.MD_JINGPAI_YUANBAO = 600
ScriptGlobal.MD_JINGPAI_AWARDFALG = 601
ScriptGlobal.MD_ENHANCE_CHUANCI = 602			--底层占用，这里标记出来
ScriptGlobal.MD_ENHANCE_FNAGCHUAN = 603			--底层占用，这里标记出来
ScriptGlobal.MD_GEM_SCORE = 604					--底层占用，这里标记出来
-- ScriptGlobal.MD_SONGHUA = 605					--花榜 送花
-- ScriptGlobal.MD_SHOUHUA = 606					--花榜 收花
ScriptGlobal.MD_QINGRENJIEDAIBI = 607			--情人节代币 爱神金箭
ScriptGlobal.MD_QIXIHUOBI = 608					--七夕代币 诉情蝶
ScriptGlobal.MD_QIXITIME = 609					--花榜时间
ScriptGlobal.MD_FH_UNION = 610					--凤凰战联盟ID
ScriptGlobal.MD_DAMAGECURSCENE = 611			--底层占用，这里标记出来
ScriptGlobal.MD_DAMAGENEEDSCENE = 612			--底层占用，这里标记出来
ScriptGlobal.MD_DAMAGEOBJID = 613				--底层占用，这里标记出来
ScriptGlobal.MD_DAMAGEDATA = 614				--底层占用，这里标记出来
-- 615											--底层占用，这里标记出来
ScriptGlobal.MD_SONGHUA1 = 616					--花榜 送花 1期
ScriptGlobal.MD_SONGHUA2 = 617					--花榜 送花 2期
ScriptGlobal.MD_SONGHUA3 = 618					--花榜 送花 3期
ScriptGlobal.MD_SHOUHUA1 = 619					--花榜 收花 1期
ScriptGlobal.MD_SHOUHUA2 = 620					--花榜 收花 2期
ScriptGlobal.MD_SHOUHUA3 = 621					--花榜 收花 3期
--622											--底层占用，这里标记出来  damage cs
ScriptGlobal.MD_TUIGUANG = 623 --推广CDK使用

--628				--客户端任务占用，数据上线刷不回去

ScriptGlobal.MD_WDDAO_FOUR_4_Ex1 = 629 --武道四用，具体不清楚
ScriptGlobal.MD_WDDAO_FOUR_4_Ex2 = 630 --武道四用，具体不清楚
ScriptGlobal.MD_JIAOYIPINGZHENG_END_TIME = 651 --交易凭证结束时间

ScriptGlobal.MD_SHENGDAN_POINT = 718 --圣诞活动累计兑换点数
ScriptGlobal.MD_SHENGDANFLAG = 719 --圣诞活动奖励领取情况


--MD  游戏标记位 明细见 define.MF
--720, 721, 722, 723, 724, 725,726, 727, 728, 729



ScriptGlobal.MD_SweepAll_SeckillTequanData= 813  
ScriptGlobal.LingWuLiuPai= 854  -- 854 这个是选择的灵武派系
--MD  游戏标记位 明细见 define.MF
--904, 905, 906, 907,908, 909, 910, 911, 912, 913

ScriptGlobal.MD_SweepAll_SeckillTequanDayCount = 943
ScriptGlobal.MDEX_JINGE_ACTIVE = 156

-- 武境(DFeng)系统 MissionData 字段
ScriptGlobal.MD_DFeng_Exp          = 960   -- 武境经验
ScriptGlobal.MD_DFeng_Level        = 961   -- 武境等级
ScriptGlobal.MD_DFeng_LevelUp_Times= 962   -- 通脉等级(仅由通脉升级写入)
ScriptGlobal.MD_DFeng_Attack1      = 963   -- 攻击槽1 (school + xdd*100)
ScriptGlobal.MD_DFeng_Defence1     = 964   -- 防御槽1
ScriptGlobal.MD_DFeng_Open         = 965   -- 武境开启标记 0=未开启 1=开启(分流中) 2=开启(分流暂停)
ScriptGlobal.MD_DFeng_Attack2      = 966   -- 攻击槽2
ScriptGlobal.MD_DFeng_Defence2     = 967   -- 防御槽2
ScriptGlobal.MD_DFeng_Attack3      = 968   -- 攻击槽3
ScriptGlobal.MD_DFeng_Defence3     = 969   -- 防御槽3
ScriptGlobal.MD_DFeng_WeekMark     = 970   -- 周计数打包: week_id*10000 + 武境周*100 + 通脉周
-- 心络孔位等级存储 (byte packed: lv1 | lv2<<8 | lv3<<16 | lv4<<24)
ScriptGlobal.MD_DFeng_KW_Levels1   = 971   -- 心络孔位1-4等级
ScriptGlobal.MD_DFeng_KW_Levels2   = 972   -- 心络孔位5-8等级
ScriptGlobal.MD_DFeng_KW_Levels3   = 973   -- 心络孔位9-12等级
ScriptGlobal.MD_DFeng_KW_Levels4   = 974   -- 心络孔位13-16等级
ScriptGlobal.MD_DFeng_KW_Levels5   = 975   -- 心络孔位17-20等级
ScriptGlobal.MD_BUCHANG_LIBAO       = 976   -- 补偿礼包是否已领取

--MissionDataEx定义相关
ScriptGlobal.MDEX_QINGQIU_SHOPLINGYE = 100 --青丘商店灵叶币
ScriptGlobal.MDEX_QINGQIU_SHOPXINYE = 101 --青丘商店新叶币
ScriptGlobal.MDEX_QINGQIU_TYPE_0 = 102 --青丘类型挑战点数
ScriptGlobal.MDEX_QINGQIU_TYPE_1 = 103 --青丘类型挑战点数
ScriptGlobal.MDEX_GIFT_OUTLINE = 104 --周天师再战江湖占用
ScriptGlobal.MDEX_LIXIAN_POOLEXP = 105 --周天师再战江湖占用
ScriptGlobal.MDEX_SHENQUAN_POINT = 106
ScriptGlobal.MDEX_SHENQUAN_YUANBAO_COUNT = 107
ScriptGlobal.MDEX_SHENQUAN_GET_COUNT = 108
ScriptGlobal.MDEX_SHENQUAN_GET_DI_ACTIVE = 109
ScriptGlobal.MDEX_SHENQUAN_GET_DI_COUNT = 110
ScriptGlobal.MDEX_SHENQUAN_GET_TIAN_ACTIVE = 111
ScriptGlobal.MDEX_SHENQUAN_GET_TIAN_COUNT = 112
ScriptGlobal.MDEX_SHENQUAN_END_DATE = 113
ScriptGlobal.MDEX_NEWGUILD_LEVEL = 114
ScriptGlobal.MDEX_NEWGUILD_TIME = 115
ScriptGlobal.MDEX_MISSION_XUYUAN = 116
ScriptGlobal.MDEX_MISSION_TIME = 117

ScriptGlobal.MDEX_QIANXUN_SELECT_MISSIONTYPE = 118
ScriptGlobal.MDEX_QIANXUN_FUQI_DAYTIME = 119
ScriptGlobal.MDEX_QIANXUN_JIEBAI_DAYTIME = 120
ScriptGlobal.MDEX_QIANXUN_SHITU_DAYTIME = 121
ScriptGlobal.MDEX_BAIBIANLIANPU_TIME = 122
ScriptGlobal.MDEX_TDZ_TIME = 123
ScriptGlobal.MDEX_TDZ_SCENE = 124
ScriptGlobal.MDEX_TDZ_X = 125
ScriptGlobal.MDEX_TDZ_Y = 126

ScriptGlobal.MDEX_TOPCHONGZHI_1 = 127
ScriptGlobal.MDEX_TOPCHONGZHI_2 = 128
ScriptGlobal.MDEX_TOPCHONGZHI_3 = 129

ScriptGlobal.MDEX_FRISTLOGIN = 130
ScriptGlobal.MDEX_CAIFUCARD = 131
ScriptGlobal.MDEX_CAIFUGIFTDATA = 132
ScriptGlobal.MDEX_MENPAIDRESSFLAG = 133
ScriptGlobal.MDEX_MENPAIEQUIPFLAG = 134
ScriptGlobal.MDEX_MENPAIPETFLAG = 135

ScriptGlobal.MDEX_FEEKFEEDBACK800_1 = 136
ScriptGlobal.MDEX_FEEKFEEDBACK800_DAYTIME = 137
ScriptGlobal.MDEX_NEWVERSON_GIFTDATA = 138

ScriptGlobal.MDEX_DARKEQUIP_BULING = 139

ScriptGlobal.MDEX_WEIHUGIFT_FALG = 140
ScriptGlobal.MDEX_VERSONPAY_FLAG = 141

ScriptGlobal.MDEX_SHUIYUE_DAYTIME = 142
ScriptGlobal.MDEX_WEIHUGIFT_FALGEX = 143
ScriptGlobal.MDEX_WEIHUGIFT_FALGDATA = 144
ScriptGlobal.MDEX_WEIHUGIFT_FALGH = 145

ScriptGlobal.MDEX_GONGLIDANCOUNT = 146
ScriptGlobal.MDEX_GONGLIDANTIME = 147
ScriptGlobal.MDEX_XUYUANCOUNT = 148

ScriptGlobal.MDEX_WEIHUGIFT_EX = 149
ScriptGlobal.MDEX_SEEK_TREASURE = 150
ScriptGlobal.MDEX_DEBUGMIYINMIANBU = 151
-- 金戈号令独立存档，不能与天鉴神券(106-113)共用。
ScriptGlobal.MDEX_JINGE_PERIOD_BEGIN = 152
ScriptGlobal.MDEX_JINGE_POINT = 153
ScriptGlobal.MDEX_JINGE_PREMIUM_CLAIM = 154
ScriptGlobal.MDEX_JINGE_BUY_COUNT = 155
ScriptGlobal.MDEX_QINGQIU_DAYTIME = 160

--170 171 172 往日梦境副本

ScriptGlobal.MDEX_PRISON_SHENYUAN_DAYTIME = 200 --伸冤时间记录
ScriptGlobal.MDEX_PAY_PETITEM_DATA = 220 --充值达到点数领取珍兽记录
ScriptGlobal.MDEX_PAY_PETITEMEX_DATA = 221 --充值达到点数领取尚品蛋记录

ScriptGlobal.MDEX_YUCHONGLIBAO_1 = 400
ScriptGlobal.MDEX_YUCHONGLIBAO_2 = 401
ScriptGlobal.MDEX_YUCHONGLIBAO_3 = 402
ScriptGlobal.MDEX_YUCHONGLIBAO_4 = 403
ScriptGlobal.MDEX_YUCHONGLIBAO_GIFTDATA = 404
ScriptGlobal.MDEX_HUNCHEN_POINT = 405
ScriptGlobal.MDEX_GET_QIQINGREN_GIFT = 406
ScriptGlobal.MDEX_BULING5000DATA = 407
ScriptGlobal.MDEX_PRE_RECHAGE_GETD = 408
ScriptGlobal.MDEX_9500_AWARD_GETD = 409
ScriptGlobal.MDEX_9500_COMPENSATION_AWARD_GETD = 410
ScriptGlobal.MDEX_YUANXIAOHUIKUI_2024 = 411
ScriptGlobal.MDEX_8000_HUIKUI_PET = 412
ScriptGlobal.MDEX_YUANXIAOHUIKUI_2024_FREE = 413
ScriptGlobal.MDEX_FUYUJIEHUIKUI_2024 = 414
ScriptGlobal.MDEX_FUYUJIEHUIKUI_2024_FREE = 415
ScriptGlobal.MDEX_ZHUBO_GET_AWARD = 416
ScriptGlobal.MDEX_YURENJIE_GET_AWARD = 417
ScriptGlobal.MDEX_YURENJIE_GET_AWARD_2 = 418
ScriptGlobal.MDEX_HAIDENGJIE_GET_AWARD = 419
ScriptGlobal.MDEX_HAIDENGJIE_GET_AWARD_FREE = 420
ScriptGlobal.MDEX_GUANWANG_YUYUE_GET_AWARD = 421
ScriptGlobal.MDEX_5WAN_CHONGLOU = 422
ScriptGlobal.MDEX_GUANWANG_YUYUE_GET_AWARD_2 = 423

ScriptGlobal.MDEX_ZHUBO_GET_AWARD_PET = 424



ScriptGlobal.MDEX_HIGHLEVELWEEKLYCARD_START = 426
ScriptGlobal.MDEX_HIGHLEVELWEEKLYCARD_OVER = 427
ScriptGlobal.MDEX_LOWLEVELWEEKLYCARD_START = 428
ScriptGlobal.MDEX_LOWLEVELWEEKLYCARD_OVER = 429
ScriptGlobal.MDEX_MOONCARDAWARD = 430
ScriptGlobal.MDEX_FH_TIME = 431
-- ScriptGlobal.MDEX_FH_UNION = 432			--???
ScriptGlobal.MDEX_FH_KILLNUM = 433
ScriptGlobal.MDEX_FH_AWARDFLAG = 434
ScriptGlobal.MDEX_FH_PARTICIPATIONTIME = 435

ScriptGlobal.MDEX_PAYREWARD_FLAG = 436
ScriptGlobal.MDEX_PAYREWARD_DAY = 437
ScriptGlobal.MDEX_PAYREWARD_POINT = 438

ScriptGlobal.MDEX_DAYPOINT_HUA = 439
ScriptGlobal.MDEX_MONEYCARDFLAG = 440

--441 - 448 日充值豪礼奖励池选择记录

ScriptGlobal.MDEX_PLAYERRANDOMID = 450

ScriptGlobal.MDEX_YXH_ONTIME = 451
ScriptGlobal.MDEX_YXH_KILLNUM = 452
ScriptGlobal.MDEX_YXH_DAMAGE = 453
ScriptGlobal.MDEX_YXH_AWARDTIME = 454

ScriptGlobal.MDEX_BANGHUIBOSS_ONTIME = 455
ScriptGlobal.MDEX_BANGHUIBOSS_DAMAGE = 456
ScriptGlobal.MDEX_BANGHUIBOSS_AWARDTIME = 457

ScriptGlobal.MDEX_DI4BOSS_ONTIME = 458
ScriptGlobal.MDEX_DI4BOSS_DAMAGE = 459
ScriptGlobal.MDEX_DI4BOSS_AWARDTIME = 460
ScriptGlobal.MDEX_OLD_SCENEID = 461
ScriptGlobal.MDEX_MENGPO = 462
ScriptGlobal.MDEX_MENGPO_2 = 463
ScriptGlobal.MDEX_MENGPO_3 = 464



ScriptGlobal.MDEX_KILL0 = 501
ScriptGlobal.MDEX_KILL1 = 502
ScriptGlobal.MDEX_KILL2 = 503
ScriptGlobal.MDEX_KILL3 = 504
ScriptGlobal.MDEX_KILL4 = 505
ScriptGlobal.MDEX_KILL5 = 506
ScriptGlobal.MDEX_KILL6 = 507
ScriptGlobal.MDEX_KILL7 = 508
ScriptGlobal.MDEX_KILL8 = 509
ScriptGlobal.MDEX_KILL9 = 510
ScriptGlobal.MDEX_KILL_TIME0 = 511
ScriptGlobal.MDEX_KILL_TIME1 = 512
ScriptGlobal.MDEX_KILL_TIME2 = 513
ScriptGlobal.MDEX_KILL_TIME3 = 514
ScriptGlobal.MDEX_KILL_TIME4 = 515
ScriptGlobal.MDEX_KILL_TIME5 = 516
ScriptGlobal.MDEX_KILL_TIME6 = 517
ScriptGlobal.MDEX_KILL_TIME7 = 518
ScriptGlobal.MDEX_KILL_TIME8 = 519
ScriptGlobal.MDEX_KILL_TIME9 = 520
--521 - 550  角色临时储存数据

ScriptGlobal.MDEX_DaLuanDouJF = 800

--五期竞拍关注占用
ScriptGlobal.MDEX_JINGPAI_FOLLOW = {
	{ndate = 601,follows = {602,603,604,605}},
	{ndate = 606,follows = {607,608,609,610}},
	{ndate = 611,follows = {612,613,614,615}},
	{ndate = 616,follows = {617,618,619,620}},
	{ndate = 621,follows = {622,623,624,625}},
}




ScriptGlobal.MDEX_JSGONGLIDANTIME = 651 --聚神功力丹使用时间
ScriptGlobal.MDEX_JSGONGLIDANCOUNT = 652 --聚神功力丹使用次数
ScriptGlobal.MDEX_CHANGE_TITLE = 653    --梁师成 称号兑换
ScriptGlobal.MDEX_LAST_MODIFYMENPAI_TIME = 654    --记录上次转门派  暂无用，保留记录
ScriptGlobal.MDEX_CDK_CD = 655  				  --CDK  CD  
ScriptGlobal.MDEX_TOP_CD = 656  				--排行打开界面  CD  
ScriptGlobal.MDEX_CLAIM_AWARD_CD = 657  		--领取奖励  CD  
ScriptGlobal.MDEX_USE_TOP_ITEM_CD = 658  		--排行使用道具相关  CD  
ScriptGlobal.MDEX_TOP_PREVIEW_CD = 659  		--排行预览  CD  
ScriptGlobal.MDEX_JINGPAI_SPECIAL_COUNT = 660	--竞拍特卖品购买次数
ScriptGlobal.MDEX_JINGPAI_TIME = 661 			--竞拍个人日期

ScriptGlobal.MDEX_MAZEI_TIME = 662 			--马贼时间
ScriptGlobal.MDEX_MAZEI = 663 				--马贼记录
ScriptGlobal.MDEX_TUI = 663 				--马贼记录
--700  补偿专用  目前已用最大值 2
--702  花榜补偿
--703-705  被占用
ScriptGlobal.MDEX_CHOULOU = 706    --是否领取了重楼肩膀
ScriptGlobal.MDEX_LIMITED_TIME_REWARD_BACK = 708    --限时回馈


ScriptGlobal.MDEX_LIMITED_TIME_COMPENSATION = 710    --角色记录

ScriptGlobal.MDEX_LIMITED_LingYuPai_TIME = 711 --加入派系的时间

ScriptGlobal.MDEX_XINFULIBAO = 712 --陈星福大礼包
ScriptGlobal.MDEX_GONGZIKA = 713 --工资卡今日使用情况
ScriptGlobal.MDEX_GONGZIKAFLAG = 714 --工资卡今日领取情况
ScriptGlobal.MDEX_GONGZITIME = 715 --工资卡BUFF发放时间

ScriptGlobal.MDEX_NEWREWARD1 = 716 --活动标记
ScriptGlobal.MDEX_NEWREWARD2 = 717 --活动标记

ScriptGlobal.MDEX_SKILLERNUM = 718 --连杀数量





ScriptGlobal.WORLD_ID_PAIPAI_1 = 1		--拍拍系统 
ScriptGlobal.WORLD_ID_PAIPAI_2 = 2		--拍拍系统 
ScriptGlobal.WORLD_ID_PAIPAI_3 = 3		--拍拍系统 
ScriptGlobal.WORLD_ID_PAIPAI_4 = 4		--拍拍系统 
ScriptGlobal.WORLD_ID_PAIPAI_5 = 5		--拍拍系统 
ScriptGlobal.WORLD_CHONGZHI_DAY = 6		--日充值记录日期 






ScriptGlobal.MAIL_REPUDIATE = 1 --强制离婚
ScriptGlobal.MAIL_BETRAYMASTER = 2 --叛师
ScriptGlobal.MAIL_EXPELPRENTICE = 3 --开除徒弟
ScriptGlobal.MAIL_UPDATE_ATTR = 4 --属性刷新
ScriptGlobal.MAIL_UNSWEAR = 5 --解除结拜
ScriptGlobal.MAIL_PRENTICE_EXP = 6 --徒弟给师傅经验
ScriptGlobal.MAIL_COMMISIONSHOP = 7 --寄售商店邮件
ScriptGlobal.MAIL_HUASHANJIANGLI = 8 --华山论剑奖励相关
ScriptGlobal.MAIL_SHITUPRIZE = 9 --徒弟给师父抽奖机会
ScriptGlobal.MAIL_SHITUPRIZE_GOODBAD = 10 --奖励经验和善恶值
ScriptGlobal.MIAL_SHITU_CHUSHI = 11 --45级出师
ScriptGlobal.MAIL_FINDFRIEND_DELINFO = 12 --征友系统，玩家主动或者系统撤销了玩家发布的信息
-- define.MAIL_JINGPAI_BACK_YUANBAO = 13 --竞拍有流拍元宝时提示   常量定义占用
-- define.MAIL_UPDATE_MINGDONG_TOP = 14 --更新名动



-- 帮会相关枚举值
ScriptGlobal.GUILD_IND_LEVEL = 0 --工业度0
ScriptGlobal.GUILD_AGR_LEVEL = 1 --农业度1
ScriptGlobal.GUILD_COM_LEVEL = 2 --商业度2
ScriptGlobal.GUILD_DEF_LEVEL = 3 --防卫度3
ScriptGlobal.GUILD_TECH_LEVEL = 4 --科技度4
ScriptGlobal.GUILD_AMBI_LEVEL = 5 --扩张度5
ScriptGlobal.GUILD_CONTRIB_POINT = 6 --贡献度6
ScriptGlobal.GUILD_MONEY = 7 --帮派资金7
ScriptGlobal.GUILD_IND_RATE = 8 --工业率8
ScriptGlobal.GUILD_AGR_RATE = 9 --农业率9
ScriptGlobal.GUILD_COM_RATE = 10 --商业率10
ScriptGlobal.GUILD_DEF_RATE = 11 --国防率11
ScriptGlobal.GUILD_TECH_RATE = 12 --科技率12
ScriptGlobal.GUILD_AMBI_RATE = 13 --扩张率13
ScriptGlobal.GUILD_SALARY = 14 --工资次数14

--LUA_AUDIT_ID BEGIN

ScriptGlobal.LUAAUDIT_EXAMPLE = 1
ScriptGlobal.LUAAUDIT_BANGZHAN_CREATEFUBEN = 2 --帮战创建副本
ScriptGlobal.LUAAUDIT_BANGZHAN_RESOURCE = 3 --每天涿鹿副本内的资源交纳量
ScriptGlobal.LUAAUDIT_BANGZHAN_FLAG = 4 --帮战中央战场旗帜占领次数
ScriptGlobal.LUAAUDIT_BANGZHAN_HONOUR = 5 --帮战副本放出荣誉值数量
ScriptGlobal.LUAAUDIT_BANGZHAN_EXCHANGEHONOUR = 6 --帮战荣誉值换取各项奖品的数量
ScriptGlobal.LUAAUDIT_BANGZHAN_TITLE_BUFF = 7 --帮战领取帮会征讨个人称号和buff的数量
ScriptGlobal.LUAAUDIT_PETSHELIZI = 8 --炼制珍兽舍利子的人数和次数
ScriptGlobal.LUAAUDIT_LOVEDAY = 9 --情人节活动 每天参加活动的人次
ScriptGlobal.LUAAUDIT_DENGMI_START = 10 --元宵节灯谜 点开界面的玩家
ScriptGlobal.LUAAUDIT_DENGMI_END = 11 --元宵节灯谜 完成所有答题的玩家
--hzp 2009-1-14
ScriptGlobal.LUAAUDIT_TSLB10 = 12
ScriptGlobal.LUAAUDIT_TSLB20 = 13
ScriptGlobal.LUAAUDIT_TSLB30 = 14
ScriptGlobal.LUAAUDIT_TSLB40 = 15

ScriptGlobal.LUAAUDIT_TSLBOUT = 16
ScriptGlobal.LUAAUDIT_SNOW = 17 --瑞雪兆丰年活动
ScriptGlobal.LUAAUDIT_MPCARD_EXCHANGE = 18 --门派贺贴 参与节日符节兑换人数。
ScriptGlobal.LUAAUDIT_MPCARD_PRIZE = 19 --门派贺贴 在诸葛孔亮处参与抽奖的人数和获得的礼品。
ScriptGlobal.LUAAUDIT_FEIHUANGSHI = 20 --[tx43454]兑换飞蝗石
ScriptGlobal.LUAAUDIT_FEIHUANGSHI_BOUND = 21 --[tx43454]兑换绑定飞蝗石
ScriptGlobal.LUAAUDIT_MEIHUABIAO = 22 --[tx43454]兑换梅花镖
ScriptGlobal.LUAAUDIT_MWQ_TUERDUO = 23 --木婉清分组寻物 兔耳朵放出统计
ScriptGlobal.LUAAUDIT_UNIVERSEBAG = 24 --江湖乾坤袋使用统计
ScriptGlobal.LUAAUDIT_ANQITUPO = 25 --暗器突破瓶颈统计
ScriptGlobal.LUAAUDIT_QIANKUNDAI_BULING_LEVEL1 = 33 --补领乾坤袋
ScriptGlobal.LUAAUDIT_LINGQU_DWJKL = 44 --成功领取端午节快乐任务
ScriptGlobal.LUAAUDIT_USE_MWZONGZI = 45 --使用美味的粽子
ScriptGlobal.LUAAUDIT_MWZONGZI_PRIZE = 46 --使用粽子后的随机奖励
ScriptGlobal.LUAAUDIT_H1N1_WUXINGLINGPAI = 47 --获得五行令牌
ScriptGlobal.LUAAUDIT_H1N1_CHONGLOUYU = 48 --兑换重楼玉
ScriptGlobal.LUAAUDIT_77_GIFTBAG = 49 --开七夕礼包
ScriptGlobal.LUAAUDIT_LHSY = 50 --六合神玉[czf]
--LUA_AUDIT_ID END

--副本类型
ScriptGlobal.FUBEN_EXAMPLE = 999
ScriptGlobal.FUBEN_MURENXIANG_7 = 998
ScriptGlobal.FUBEN_MURENXIANG_9 = 997
ScriptGlobal.FUBEN_MURENXIANG = 996
ScriptGlobal.FUBEN_SHUILAO = 995
ScriptGlobal.FUBEN_ZHENGLONG = 994
ScriptGlobal.FUBEN_PVP_LEITAI = 993
ScriptGlobal.FUBEN_BOZANG = 992
ScriptGlobal.FUBEN_TAOHUAZHEN = 991
ScriptGlobal.FUBEN_JIUJIAO = 990
ScriptGlobal.FUBEN_GUANGMINGDONG = 989
ScriptGlobal.FUBEN_TALIN = 988
ScriptGlobal.FUBEN_TADI = 987
ScriptGlobal.FUBEN_ZHEMEIFENG = 986
ScriptGlobal.FUBEN_LINGXINGFENG = 985
ScriptGlobal.FUBEN_GUDI = 984
ScriptGlobal.FUBEN_WUSHENDONG = 983
ScriptGlobal.FUBEN_RENWULIAN = 982
ScriptGlobal.FUBEN_MINE = 981
ScriptGlobal.FUBEN_KILLVERMIN = 980
ScriptGlobal.FUBEN_CHUCKOUTVILLAIN = 979
ScriptGlobal.FUBEN_CONVOYPET = 978
ScriptGlobal.FUBEN_BIANGUAN = 977 -- 用于中秋任务
ScriptGlobal.FUBEN_JIAOCHANG = 976
ScriptGlobal.FUBEN_TALIN1 = 975
ScriptGlobal.FUBEN_GUANGMINGDONG1 = 974
ScriptGlobal.FUBEN_JIUJIAO1 = 973
ScriptGlobal.FUBEN_LINGXINGFENG1 = 972
ScriptGlobal.FUBEN_TAOHUAZHEN1 = 971
ScriptGlobal.FUBEN_TADI1 = 970
ScriptGlobal.FUBEN_WUSHENDONG1 = 969
ScriptGlobal.FUBEN_ZHEMEIFENG1 = 968
ScriptGlobal.FUBEN_GUDI1 = 967
ScriptGlobal.FUBEN_SHIJI2 = 966
ScriptGlobal.FUBEN_GONGDI = 965
ScriptGlobal.FUBEN_SHIJI1 = 964
ScriptGlobal.FUBEN_KAOCHANG = 963
ScriptGlobal.FUBEN_WEDDING = 962
ScriptGlobal.FUBEN_DATAOSHA = 961
ScriptGlobal.FUBEN_SONGLIAO = 960
ScriptGlobal.FUBEN_ZHULIN = 959
ScriptGlobal.FUBEN_FEIZHAI = 958
ScriptGlobal.FUBEN_ZEIBINGRUQIN = 957
ScriptGlobal.FUBEN_JUQING = 956
ScriptGlobal.FUBEN_GUOFANG = 955
ScriptGlobal.FUBEN_BAOZANG = 954
ScriptGlobal.FUBEN_TIANLONG1 = 953
ScriptGlobal.FUBEN_SHAOLIN1 = 952
ScriptGlobal.FUBEN_MINGJIAO1 = 951
ScriptGlobal.FUBEN_GAIBANG1 = 950
ScriptGlobal.FUBEN_EMEI1 = 949
ScriptGlobal.FUBEN_XINGXIU1 = 948
ScriptGlobal.FUBEN_XIAOYAO1 = 947
ScriptGlobal.FUBEN_WUDANG1 = 946
ScriptGlobal.FUBEN_TIANSHAN1 = 945
ScriptGlobal.FUBEN_YMGTAISHOUFU = 944
ScriptGlobal.FUBEN_JIAOFEI = 943
ScriptGlobal.FUBEN_CUJU = 942
ScriptGlobal.FUBEN_PORTECT_PET = 941
ScriptGlobal.FUBEN_CATCH_PET = 940
ScriptGlobal.FUBEN_DAZHAN_YZW = 939
ScriptGlobal.FUBEN_GODFIRE = 938
ScriptGlobal.FUBEN_PIAOMIAOFENG = 937
ScriptGlobal.FUBEN_PROTECTGUILD = 936
ScriptGlobal.FUBEN_XINSHENGSHOUSHAN = 935
ScriptGlobal.FUBEN_SEEK_TREASURE = 934 -- zchw
ScriptGlobal.FUBEN_HUANGJINZHILIAN = 933
ScriptGlobal.FUBEN_XUANFOUZHU = 932
ScriptGlobal.FUBEN_RONGYANZHIDI = 931
ScriptGlobal.FUBEN_BANGZHAN = 930
ScriptGlobal.FUBEN_JUQING_CANGMANGSHAN = 929
ScriptGlobal.FUBEN_ZHENGSHOUJINGDI = 928 --青丘副本
ScriptGlobal.FUBEN_SHUIYUESHANZHUANG = 927 --水月山庄
ScriptGlobal.FUBEN_YANMENLUNWU = 926 --雁门论武
ScriptGlobal.FUBEN_HAOYUEZHOU = 925 --曼陀师门副本皓月洲
ScriptGlobal.FUBEN_WANGRIMENGJING = 924 --往日梦境副本
ScriptGlobal.FUBEN_FENGHUANGLINGMU = 923 --凤凰陵墓
ScriptGlobal.FUBEN_ERENGU1 = 922
ScriptGlobal.FUBEN_GUSU1 = 921
ScriptGlobal.FUBEN_MANTUO1 = 920

ScriptGlobal.COUPLE_LOG_STARTQUESTION = 1
ScriptGlobal.COUPLE_LOG_STOPQUESTION = 2
ScriptGlobal.COUPLE_LOG_FINISHQUESTION = 3
ScriptGlobal.COUPLE_LOG_LEARNSKILL = 4
ScriptGlobal.COUPLE_LOG_LEVELUPSKILL = 5
ScriptGlobal.COUPLE_LOG_DETAIL = {
	[ScriptGlobal.COUPLE_LOG_STARTQUESTION] = "COUPLE_LOG_STARTQUESTION",
	[ScriptGlobal.COUPLE_LOG_STOPQUESTION] = "COUPLE_LOG_STOPQUESTION",
	[ScriptGlobal.COUPLE_LOG_FINISHQUESTION] = "COUPLE_LOG_FINISHQUESTION",
	[ScriptGlobal.COUPLE_LOG_LEARNSKILL] = "COUPLE_LOG_LEARNSKILL",
	[ScriptGlobal.COUPLE_LOG_LEVELUPSKILL] = "COUPLE_LOG_LEVELUPSKILL"
}
--抽奖日志编号
ScriptGlobal.PRIZE_LOG_XINSHOUSHITU = 1 --新手师徒抽奖
ScriptGlobal.PLANTNPC_ADDRESS = {
	{X = 37, Z = 93, Scene = 2, X_MIN = 35, X_MAX = 40, Z_MIN = 90, Z_MAX = 96},
	{X = 46, Z = 93, Scene = 2, X_MIN = 43, X_MAX = 48, Z_MIN = 90, Z_MAX = 96},
	{X = 37, Z = 101, Scene = 2, X_MIN = 35, X_MAX = 40, Z_MIN = 98, Z_MAX = 104},
	{X = 46, Z = 101, Scene = 2, X_MIN = 43, X_MAX = 48, Z_MIN = 98, Z_MAX = 104},
	{X = 38, Z = 109, Scene = 2, X_MIN = 35, X_MAX = 40, Z_MIN = 106, Z_MAX = 112},
	{X = 46, Z = 109, Scene = 2, X_MIN = 43, X_MAX = 48, Z_MIN = 106, Z_MAX = 112},
	{X = 37, Z = 117, Scene = 2, X_MIN = 35, X_MAX = 40, Z_MIN = 114, Z_MAX = 120},
	{X = 46, Z = 117, Scene = 2, X_MIN = 43, X_MAX = 48, Z_MIN = 114, Z_MAX = 120},
	{X = 38, Z = 125, Scene = 2, X_MIN = 35, X_MAX = 40, Z_MIN = 122, Z_MAX = 128},
	{X = 46, Z = 125, Scene = 2, X_MIN = 43, X_MAX = 48, Z_MIN = 122, Z_MAX = 128},
	{X = 38, Z = 134, Scene = 2, X_MIN = 35, X_MAX = 40, Z_MIN = 131, Z_MAX = 137},
	{X = 46, Z = 134, Scene = 2, X_MIN = 43, X_MAX = 48, Z_MIN = 131, Z_MAX = 138},
	{X = 264, Z = 175, Scene = 2, X_MIN = 262, X_MAX = 266, Z_MIN = 172, Z_MAX = 178},
	{X = 270, Z = 175, Scene = 2, X_MIN = 268, X_MAX = 272, Z_MIN = 172, Z_MAX = 178},
	{X = 277, Z = 175, Scene = 2, X_MIN = 275, X_MAX = 279, Z_MIN = 173, Z_MAX = 178},
	{X = 287, Z = 175, Scene = 2, X_MIN = 285, X_MAX = 289, Z_MIN = 172, Z_MAX = 178},
	{X = 270, Z = 183, Scene = 2, X_MIN = 268, X_MAX = 272, Z_MIN = 180, Z_MAX = 186},
	{X = 277, Z = 183, Scene = 2, X_MIN = 275, X_MAX = 279, Z_MIN = 180, Z_MAX = 186},
	{X = 287, Z = 183, Scene = 2, X_MIN = 285, X_MAX = 289, Z_MIN = 180, Z_MAX = 186},
	{X = 270, Z = 192, Scene = 2, X_MIN = 268, X_MAX = 272, Z_MIN = 189, Z_MAX = 195},
	{X = 277, Z = 192, Scene = 2, X_MIN = 275, X_MAX = 279, Z_MIN = 189, Z_MAX = 195},
	{X = 287, Z = 192, Scene = 2, X_MIN = 285, X_MAX = 289, Z_MIN = 189, Z_MAX = 195},
	{X = 287, Z = 200, Scene = 2, X_MIN = 285, X_MAX = 289, Z_MIN = 197, Z_MAX = 203},
	{X = 287, Z = 209, Scene = 2, X_MIN = 285, X_MAX = 289, Z_MIN = 206, Z_MAX = 212},
	{X = 134, Z = 272, Scene = 2, X_MIN = 132, X_MAX = 136, Z_MIN = 269, Z_MAX = 274},
	{X = 141, Z = 272, Scene = 2, X_MIN = 139, X_MAX = 143, Z_MIN = 269, Z_MAX = 274},
	{X = 148, Z = 272, Scene = 2, X_MIN = 146, X_MAX = 150, Z_MIN = 269, Z_MAX = 275},
	{X = 173, Z = 271, Scene = 2, X_MIN = 171, X_MAX = 175, Z_MIN = 268, Z_MAX = 274},
	{X = 181, Z = 271, Scene = 2, X_MIN = 179, X_MAX = 183, Z_MIN = 268, Z_MAX = 274},
	{X = 188, Z = 271, Scene = 2, X_MIN = 186, X_MAX = 190, Z_MIN = 268, Z_MAX = 273},
	{X = 134, Z = 279, Scene = 2, X_MIN = 132, X_MAX = 136, Z_MIN = 276, Z_MAX = 281},
	{X = 141, Z = 279, Scene = 2, X_MIN = 139, X_MAX = 143, Z_MIN = 276, Z_MAX = 281},
	{X = 148, Z = 279, Scene = 2, X_MIN = 146, X_MAX = 150, Z_MIN = 276, Z_MAX = 282},
	{X = 173, Z = 279, Scene = 2, X_MIN = 171, X_MAX = 175, Z_MIN = 276, Z_MAX = 281},
	{X = 181, Z = 279, Scene = 2, X_MIN = 179, X_MAX = 183, Z_MIN = 276, Z_MAX = 281},
	{X = 188, Z = 279, Scene = 2, X_MIN = 186, X_MAX = 190, Z_MIN = 276, Z_MAX = 281},
	{X = 47, Z = 160, Scene = 0, X_MIN = 44, X_MAX = 50, Z_MIN = 156, Z_MAX = 164},
	{X = 41, Z = 170, Scene = 0, X_MIN = 38, X_MAX = 44, Z_MIN = 166, Z_MAX = 174},
	{X = 48, Z = 170, Scene = 0, X_MIN = 45, X_MAX = 51, Z_MIN = 166, Z_MAX = 174},
	{X = 56, Z = 170, Scene = 0, X_MIN = 53, X_MAX = 59, Z_MIN = 166, Z_MAX = 174},
	{X = 63, Z = 170, Scene = 0, X_MIN = 60, X_MAX = 66, Z_MIN = 166, Z_MAX = 174},
	{X = 41, Z = 179, Scene = 0, X_MIN = 38, X_MAX = 44, Z_MIN = 175, Z_MAX = 183},
	{X = 48, Z = 179, Scene = 0, X_MIN = 45, X_MAX = 51, Z_MIN = 175, Z_MAX = 183},
	{X = 56, Z = 179, Scene = 0, X_MIN = 53, X_MAX = 59, Z_MIN = 175, Z_MAX = 183},
	{X = 63, Z = 179, Scene = 0, X_MIN = 60, X_MAX = 66, Z_MIN = 175, Z_MAX = 183},
	{X = 44, Z = 188, Scene = 0, X_MIN = 41, X_MAX = 47, Z_MIN = 184, Z_MAX = 192},
	{X = 51, Z = 188, Scene = 0, X_MIN = 48, X_MAX = 54, Z_MIN = 184, Z_MAX = 192},
	{X = 51, Z = 197, Scene = 0, X_MIN = 48, X_MAX = 54, Z_MIN = 193, Z_MAX = 201},
	{X = 269, Z = 162, Scene = 0, X_MIN = 266, X_MAX = 272, Z_MIN = 158, Z_MAX = 166},
	{X = 276, Z = 162, Scene = 0, X_MIN = 273, X_MAX = 279, Z_MIN = 158, Z_MAX = 166},
	{X = 255, Z = 170, Scene = 0, X_MIN = 252, X_MAX = 258, Z_MIN = 166, Z_MAX = 174},
	{X = 262, Z = 170, Scene = 0, X_MIN = 259, X_MAX = 265, Z_MIN = 166, Z_MAX = 174},
	{X = 269, Z = 170, Scene = 0, X_MIN = 266, X_MAX = 272, Z_MIN = 166, Z_MAX = 174},
	{X = 276, Z = 170, Scene = 0, X_MIN = 273, X_MAX = 279, Z_MIN = 166, Z_MAX = 174},
	{X = 255, Z = 178, Scene = 0, X_MIN = 252, X_MAX = 258, Z_MIN = 174, Z_MAX = 182},
	{X = 262, Z = 178, Scene = 0, X_MIN = 259, X_MAX = 265, Z_MIN = 174, Z_MAX = 182},
	{X = 269, Z = 179, Scene = 0, X_MIN = 266, X_MAX = 272, Z_MIN = 175, Z_MAX = 183},
	{X = 276, Z = 179, Scene = 0, X_MIN = 273, X_MAX = 279, Z_MIN = 175, Z_MAX = 183},
	{X = 262, Z = 187, Scene = 0, X_MIN = 259, X_MAX = 265, Z_MIN = 183, Z_MAX = 191},
	{X = 269, Z = 187, Scene = 0, X_MIN = 263, X_MAX = 272, Z_MIN = 183, Z_MAX = 191},
	{X = 77, Z = 251, Scene = 0, X_MIN = 74, X_MAX = 80, Z_MIN = 247, Z_MAX = 255},
	{X = 83, Z = 251, Scene = 0, X_MIN = 80, X_MAX = 86, Z_MIN = 247, Z_MAX = 255},
	{X = 89, Z = 251, Scene = 0, X_MIN = 86, X_MAX = 92, Z_MIN = 247, Z_MAX = 255},
	{X = 94, Z = 251, Scene = 0, X_MIN = 91, X_MAX = 97, Z_MIN = 247, Z_MAX = 255},
	{X = 100, Z = 251, Scene = 0, X_MIN = 97, X_MAX = 103, Z_MIN = 247, Z_MAX = 255},
	{X = 77, Z = 259, Scene = 0, X_MIN = 74, X_MAX = 80, Z_MIN = 255, Z_MAX = 264},
	{X = 83, Z = 259, Scene = 0, X_MIN = 80, X_MAX = 86, Z_MIN = 255, Z_MAX = 264},
	{X = 89, Z = 259, Scene = 0, X_MIN = 86, X_MAX = 92, Z_MIN = 255, Z_MAX = 264},
	{X = 94, Z = 259, Scene = 0, X_MIN = 91, X_MAX = 97, Z_MIN = 255, Z_MAX = 264},
	{X = 100, Z = 259, Scene = 0, X_MIN = 97, X_MAX = 103, Z_MIN = 255, Z_MAX = 264},
	{X = 227, Z = 251, Scene = 0, X_MIN = 224, X_MAX = 230, Z_MIN = 247, Z_MAX = 255},
	{X = 235, Z = 251, Scene = 0, X_MIN = 232, X_MAX = 238, Z_MIN = 247, Z_MAX = 255},
	{X = 64, Z = 98, Scene = 1, X_MIN = 61, X_MAX = 66, Z_MIN = 95, Z_MAX = 102},
	{X = 63, Z = 110, Scene = 1, X_MIN = 61, X_MAX = 66, Z_MIN = 106, Z_MAX = 113},
	{X = 56, Z = 121, Scene = 1, X_MIN = 53, X_MAX = 58, Z_MIN = 117, Z_MAX = 124},
	{X = 64, Z = 121, Scene = 1, X_MIN = 61, X_MAX = 66, Z_MIN = 117, Z_MAX = 124},
	{X = 63, Z = 133, Scene = 1, X_MIN = 61, X_MAX = 66, Z_MIN = 130, Z_MAX = 137},
	{X = 64, Z = 145, Scene = 1, X_MIN = 61, X_MAX = 66, Z_MIN = 141, Z_MAX = 148},
	{X = 52, Z = 216, Scene = 1, X_MIN = 49, X_MAX = 54, Z_MIN = 212, Z_MAX = 219},
	{X = 62, Z = 212, Scene = 1, X_MIN = 60, X_MAX = 65, Z_MIN = 208, Z_MAX = 215},
	{X = 51, Z = 223, Scene = 1, X_MIN = 49, X_MAX = 54, Z_MIN = 220, Z_MAX = 227},
	{X = 63, Z = 222, Scene = 1, X_MIN = 60, X_MAX = 65, Z_MIN = 218, Z_MAX = 225},
	{X = 51, Z = 232, Scene = 1, X_MIN = 49, X_MAX = 54, Z_MIN = 228, Z_MAX = 235},
	{X = 63, Z = 232, Scene = 1, X_MIN = 20, X_MAX = 65, Z_MIN = 228, Z_MAX = 235},
	{X = 119, Z = 54, Scene = 1, X_MIN = 116, X_MAX = 121, Z_MIN = 50, Z_MAX = 57},
	{X = 126, Z = 54, Scene = 1, X_MIN = 124, X_MAX = 129, Z_MIN = 50, Z_MAX = 57},
	{X = 136, Z = 54, Scene = 1, X_MIN = 133, X_MAX = 138, Z_MIN = 50, Z_MAX = 57},
	{X = 145, Z = 54, Scene = 1, X_MIN = 142, X_MAX = 147, Z_MIN = 50, Z_MAX = 57},
	{X = 154, Z = 54, Scene = 1, X_MIN = 151, X_MAX = 156, Z_MIN = 50, Z_MAX = 57},
	{X = 162, Z = 54, Scene = 1, X_MIN = 160, X_MAX = 165, Z_MIN = 50, Z_MAX = 57},
	{X = 194, Z = 53, Scene = 1, X_MIN = 192, X_MAX = 197, Z_MIN = 49, Z_MAX = 56},
	{X = 203, Z = 53, Scene = 1, X_MIN = 200, X_MAX = 205, Z_MIN = 49, Z_MAX = 56},
	{X = 209, Z = 53, Scene = 1, X_MIN = 207, X_MAX = 212, Z_MIN = 49, Z_MAX = 56},
	{X = 218, Z = 53, Scene = 1, X_MIN = 216, X_MAX = 221, Z_MIN = 49, Z_MAX = 56},
	{X = 227, Z = 53, Scene = 1, X_MIN = 224, X_MAX = 229, Z_MIN = 49, Z_MAX = 56},
	{X = 235, Z = 53, Scene = 1, X_MIN = 232, X_MAX = 237, Z_MIN = 49, Z_MAX = 56},
	{X = 114, Z = 252, Scene = 1, X_MIN = 111, X_MAX = 116, Z_MIN = 248, Z_MAX = 255},
	{X = 122, Z = 252, Scene = 1, X_MIN = 119, X_MAX = 124, Z_MIN = 248, Z_MAX = 255},
	{X = 129, Z = 252, Scene = 1, X_MIN = 127, X_MAX = 132, Z_MIN = 248, Z_MAX = 255},
	{X = 137, Z = 252, Scene = 1, X_MIN = 135, X_MAX = 140, Z_MIN = 248, Z_MAX = 255},
	{X = 145, Z = 252, Scene = 1, X_MIN = 143, X_MAX = 148, Z_MIN = 248, Z_MAX = 255},
	{X = 153, Z = 252, Scene = 1, X_MIN = 151, X_MAX = 156, Z_MIN = 248, Z_MAX = 255},
	{X = 217, Z = 251, Scene = 1, X_MIN = 215, X_MAX = 220, Z_MIN = 247, Z_MAX = 254},
	{X = 223, Z = 251, Scene = 1, X_MIN = 221, X_MAX = 226, Z_MIN = 247, Z_MAX = 254},
	{X = 229, Z = 251, Scene = 1, X_MIN = 227, X_MAX = 232, Z_MIN = 247, Z_MAX = 254},
	{X = 217, Z = 259, Scene = 1, X_MIN = 215, X_MAX = 220, Z_MIN = 255, Z_MAX = 262},
	{X = 223, Z = 259, Scene = 1, X_MIN = 221, X_MAX = 226, Z_MIN = 255, Z_MAX = 262},
	{X = 229, Z = 259, Scene = 1, X_MIN = 227, X_MAX = 232, Z_MIN = 255, Z_MAX = 262},
	{X = 37, Z = 93, Scene = 71, X_MIN = 35, X_MAX = 40, Z_MIN = 90, Z_MAX = 96},
	{X = 46, Z = 93, Scene = 71, X_MIN = 43, X_MAX = 48, Z_MIN = 90, Z_MAX = 96},
	{X = 37, Z = 101, Scene = 71, X_MIN = 35, X_MAX = 40, Z_MIN = 98, Z_MAX = 104},
	{X = 46, Z = 101, Scene = 71, X_MIN = 43, X_MAX = 48, Z_MIN = 98, Z_MAX = 104},
	{X = 38, Z = 109, Scene = 71, X_MIN = 35, X_MAX = 40, Z_MIN = 106, Z_MAX = 112},
	{X = 46, Z = 109, Scene = 71, X_MIN = 43, X_MAX = 48, Z_MIN = 106, Z_MAX = 112},
	{X = 37, Z = 117, Scene = 71, X_MIN = 35, X_MAX = 40, Z_MIN = 114, Z_MAX = 120},
	{X = 46, Z = 117, Scene = 71, X_MIN = 43, X_MAX = 48, Z_MIN = 114, Z_MAX = 120},
	{X = 38, Z = 125, Scene = 71, X_MIN = 35, X_MAX = 40, Z_MIN = 122, Z_MAX = 128},
	{X = 46, Z = 125, Scene = 71, X_MIN = 43, X_MAX = 48, Z_MIN = 122, Z_MAX = 128},
	{X = 38, Z = 134, Scene = 71, X_MIN = 35, X_MAX = 40, Z_MIN = 131, Z_MAX = 137},
	{X = 46, Z = 134, Scene = 71, X_MIN = 43, X_MAX = 48, Z_MIN = 131, Z_MAX = 138},
	{X = 264, Z = 175, Scene = 71, X_MIN = 262, X_MAX = 266, Z_MIN = 172, Z_MAX = 178},
	{X = 270, Z = 175, Scene = 71, X_MIN = 268, X_MAX = 272, Z_MIN = 172, Z_MAX = 178},
	{X = 277, Z = 175, Scene = 71, X_MIN = 275, X_MAX = 279, Z_MIN = 173, Z_MAX = 178},
	{X = 287, Z = 175, Scene = 71, X_MIN = 285, X_MAX = 289, Z_MIN = 172, Z_MAX = 178},
	{X = 270, Z = 183, Scene = 71, X_MIN = 268, X_MAX = 272, Z_MIN = 180, Z_MAX = 186},
	{X = 277, Z = 183, Scene = 71, X_MIN = 275, X_MAX = 279, Z_MIN = 180, Z_MAX = 186},
	{X = 287, Z = 183, Scene = 71, X_MIN = 285, X_MAX = 289, Z_MIN = 180, Z_MAX = 186},
	{X = 270, Z = 192, Scene = 71, X_MIN = 268, X_MAX = 272, Z_MIN = 189, Z_MAX = 195},
	{X = 277, Z = 192, Scene = 71, X_MIN = 275, X_MAX = 279, Z_MIN = 189, Z_MAX = 195},
	{X = 287, Z = 192, Scene = 71, X_MIN = 285, X_MAX = 289, Z_MIN = 189, Z_MAX = 195},
	{X = 287, Z = 200, Scene = 71, X_MIN = 285, X_MAX = 289, Z_MIN = 197, Z_MAX = 203},
	{X = 287, Z = 209, Scene = 71, X_MIN = 285, X_MAX = 289, Z_MIN = 206, Z_MAX = 212},
	{X = 134, Z = 272, Scene = 71, X_MIN = 132, X_MAX = 136, Z_MIN = 269, Z_MAX = 274},
	{X = 141, Z = 272, Scene = 71, X_MIN = 139, X_MAX = 143, Z_MIN = 269, Z_MAX = 274},
	{X = 148, Z = 272, Scene = 71, X_MIN = 146, X_MAX = 150, Z_MIN = 269, Z_MAX = 275},
	{X = 173, Z = 271, Scene = 71, X_MIN = 171, X_MAX = 175, Z_MIN = 268, Z_MAX = 274},
	{X = 181, Z = 271, Scene = 71, X_MIN = 179, X_MAX = 183, Z_MIN = 268, Z_MAX = 274},
	{X = 188, Z = 271, Scene = 71, X_MIN = 186, X_MAX = 190, Z_MIN = 268, Z_MAX = 273},
	{X = 134, Z = 279, Scene = 71, X_MIN = 132, X_MAX = 136, Z_MIN = 276, Z_MAX = 281},
	{X = 141, Z = 279, Scene = 71, X_MIN = 139, X_MAX = 143, Z_MIN = 276, Z_MAX = 281},
	{X = 148, Z = 279, Scene = 71, X_MIN = 146, X_MAX = 150, Z_MIN = 276, Z_MAX = 282},
	{X = 173, Z = 279, Scene = 71, X_MIN = 171, X_MAX = 175, Z_MIN = 276, Z_MAX = 281},
	{X = 181, Z = 279, Scene = 71, X_MIN = 179, X_MAX = 183, Z_MIN = 276, Z_MAX = 281},
	{X = 188, Z = 279, Scene = 71, X_MIN = 186, X_MAX = 190, Z_MIN = 276, Z_MAX = 281},
	{X = 37, Z = 93, Scene = 72, X_MIN = 35, X_MAX = 40, Z_MIN = 90, Z_MAX = 96},
	{X = 46, Z = 93, Scene = 72, X_MIN = 43, X_MAX = 48, Z_MIN = 90, Z_MAX = 96},
	{X = 37, Z = 101, Scene = 72, X_MIN = 35, X_MAX = 40, Z_MIN = 98, Z_MAX = 104},
	{X = 46, Z = 101, Scene = 72, X_MIN = 43, X_MAX = 48, Z_MIN = 98, Z_MAX = 104},
	{X = 38, Z = 109, Scene = 72, X_MIN = 35, X_MAX = 40, Z_MIN = 106, Z_MAX = 112},
	{X = 46, Z = 109, Scene = 72, X_MIN = 43, X_MAX = 48, Z_MIN = 106, Z_MAX = 112},
	{X = 37, Z = 117, Scene = 72, X_MIN = 35, X_MAX = 40, Z_MIN = 114, Z_MAX = 120},
	{X = 46, Z = 117, Scene = 72, X_MIN = 43, X_MAX = 48, Z_MIN = 114, Z_MAX = 120},
	{X = 38, Z = 125, Scene = 72, X_MIN = 35, X_MAX = 40, Z_MIN = 122, Z_MAX = 128},
	{X = 46, Z = 125, Scene = 72, X_MIN = 43, X_MAX = 48, Z_MIN = 122, Z_MAX = 128},
	{X = 38, Z = 134, Scene = 72, X_MIN = 35, X_MAX = 40, Z_MIN = 131, Z_MAX = 137},
	{X = 46, Z = 134, Scene = 72, X_MIN = 43, X_MAX = 48, Z_MIN = 131, Z_MAX = 138},
	{X = 264, Z = 175, Scene = 72, X_MIN = 262, X_MAX = 266, Z_MIN = 172, Z_MAX = 178},
	{X = 270, Z = 175, Scene = 72, X_MIN = 268, X_MAX = 272, Z_MIN = 172, Z_MAX = 178},
	{X = 277, Z = 175, Scene = 72, X_MIN = 275, X_MAX = 279, Z_MIN = 173, Z_MAX = 178},
	{X = 287, Z = 175, Scene = 72, X_MIN = 285, X_MAX = 289, Z_MIN = 172, Z_MAX = 178},
	{X = 270, Z = 183, Scene = 72, X_MIN = 268, X_MAX = 272, Z_MIN = 180, Z_MAX = 186},
	{X = 277, Z = 183, Scene = 72, X_MIN = 275, X_MAX = 279, Z_MIN = 180, Z_MAX = 186},
	{X = 287, Z = 183, Scene = 72, X_MIN = 285, X_MAX = 289, Z_MIN = 180, Z_MAX = 186},
	{X = 270, Z = 192, Scene = 72, X_MIN = 268, X_MAX = 272, Z_MIN = 189, Z_MAX = 195},
	{X = 277, Z = 192, Scene = 72, X_MIN = 275, X_MAX = 279, Z_MIN = 189, Z_MAX = 195},
	{X = 287, Z = 192, Scene = 72, X_MIN = 285, X_MAX = 289, Z_MIN = 189, Z_MAX = 195},
	{X = 287, Z = 200, Scene = 72, X_MIN = 285, X_MAX = 289, Z_MIN = 197, Z_MAX = 203},
	{X = 287, Z = 209, Scene = 72, X_MIN = 285, X_MAX = 289, Z_MIN = 206, Z_MAX = 212},
	{X = 134, Z = 272, Scene = 72, X_MIN = 132, X_MAX = 136, Z_MIN = 269, Z_MAX = 274},
	{X = 141, Z = 272, Scene = 72, X_MIN = 139, X_MAX = 143, Z_MIN = 269, Z_MAX = 274},
	{X = 148, Z = 272, Scene = 72, X_MIN = 146, X_MAX = 150, Z_MIN = 269, Z_MAX = 275},
	{X = 173, Z = 271, Scene = 72, X_MIN = 171, X_MAX = 175, Z_MIN = 268, Z_MAX = 274},
	{X = 181, Z = 271, Scene = 72, X_MIN = 179, X_MAX = 183, Z_MIN = 268, Z_MAX = 274},
	{X = 188, Z = 271, Scene = 72, X_MIN = 186, X_MAX = 190, Z_MIN = 268, Z_MAX = 273},
	{X = 134, Z = 279, Scene = 72, X_MIN = 132, X_MAX = 136, Z_MIN = 276, Z_MAX = 281},
	{X = 141, Z = 279, Scene = 72, X_MIN = 139, X_MAX = 143, Z_MIN = 276, Z_MAX = 281},
	{X = 148, Z = 279, Scene = 72, X_MIN = 146, X_MAX = 150, Z_MIN = 276, Z_MAX = 282},
	{X = 173, Z = 279, Scene = 72, X_MIN = 171, X_MAX = 175, Z_MIN = 276, Z_MAX = 281},
	{X = 181, Z = 279, Scene = 72, X_MIN = 179, X_MAX = 183, Z_MIN = 276, Z_MAX = 281},
	{X = 188, Z = 279, Scene = 72, X_MIN = 186, X_MAX = 190, Z_MIN = 276, Z_MAX = 281},
	-- 楼兰种植点
	{X = 35, Z = 206, Scene = 186, X_MIN = 33, X_MAX = 37, Z_MIN = 203, Z_MAX = 208},
	{X = 41, Z = 206, Scene = 186, X_MIN = 39, X_MAX = 43, Z_MIN = 203, Z_MAX = 208},
	{X = 46, Z = 206, Scene = 186, X_MIN = 43, X_MAX = 47, Z_MIN = 203, Z_MAX = 208},
	{X = 51, Z = 206, Scene = 186, X_MIN = 48, X_MAX = 52, Z_MIN = 203, Z_MAX = 208},
	{X = 57, Z = 206, Scene = 186, X_MIN = 54, X_MAX = 58, Z_MIN = 203, Z_MAX = 208},
	{X = 57, Z = 214, Scene = 186, X_MIN = 55, X_MAX = 59, Z_MIN = 211, Z_MAX = 216},
	{X = 51, Z = 214, Scene = 186, X_MIN = 49, X_MAX = 53, Z_MIN = 211, Z_MAX = 216},
	{X = 46, Z = 214, Scene = 186, X_MIN = 44, X_MAX = 48, Z_MIN = 211, Z_MAX = 216},
	{X = 41, Z = 214, Scene = 186, X_MIN = 39, X_MAX = 43, Z_MIN = 211, Z_MAX = 216},
	{X = 35, Z = 214, Scene = 186, X_MIN = 33, X_MAX = 37, Z_MIN = 211, Z_MAX = 216},
	--楼兰新开10块地
	{X = 97, Z = 197, Scene = 186, X_MIN = 95, X_MAX = 99, Z_MIN = 194, Z_MAX = 199},
	{X = 104, Z = 197, Scene = 186, X_MIN = 102, X_MAX = 106, Z_MIN = 194, Z_MAX = 199},
	{X = 97, Z = 206, Scene = 186, X_MIN = 95, X_MAX = 99, Z_MIN = 203, Z_MAX = 208},
	{X = 103, Z = 206, Scene = 186, X_MIN = 101, X_MAX = 105, Z_MIN = 203, Z_MAX = 208},
	{X = 109, Z = 206, Scene = 186, X_MIN = 107, X_MAX = 121, Z_MIN = 203, Z_MAX = 208},
	{X = 96, Z = 216, Scene = 186, X_MIN = 94, X_MAX = 98, Z_MIN = 213, Z_MAX = 218},
	{X = 102, Z = 216, Scene = 186, X_MIN = 100, X_MAX = 104, Z_MIN = 213, Z_MAX = 218},
	{X = 108, Z = 216, Scene = 186, X_MIN = 106, X_MAX = 110, Z_MIN = 213, Z_MAX = 218},
	{X = 96, Z = 234, Scene = 186, X_MIN = 94, X_MAX = 98, Z_MIN = 231, Z_MAX = 236},
	{X = 102, Z = 234, Scene = 186, X_MIN = 100, X_MAX = 104, Z_MIN = 231, Z_MAX = 236},
	--束河古镇种植点 zchw
	{X = 288, Z = 284, Scene = 420, X_MIN = 287, X_MAX = 291, Z_MIN = 283, Z_MAX = 287},
	{X = 288, Z = 276, Scene = 420, X_MIN = 287, X_MAX = 291, Z_MIN = 275, Z_MAX = 279},
	{X = 288, Z = 268, Scene = 420, X_MIN = 287, X_MAX = 291, Z_MIN = 267, Z_MAX = 271},
	{X = 288, Z = 259, Scene = 420, X_MIN = 287, X_MAX = 291, Z_MIN = 258, Z_MAX = 262},
	{X = 296, Z = 258, Scene = 420, X_MIN = 295, X_MAX = 298, Z_MIN = 257, Z_MAX = 261},
	{X = 296, Z = 267, Scene = 420, X_MIN = 295, X_MAX = 298, Z_MIN = 266, Z_MAX = 270},
	{X = 296, Z = 276, Scene = 420, X_MIN = 295, X_MAX = 298, Z_MIN = 275, Z_MAX = 279}
}
ScriptGlobal.PLANTFLAG = {
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	--楼兰开始的20个标志
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0
}
ScriptGlobal.MENPAI_SHIMEN_MISID = 
{
	1060,
	1070,
	1065,
	1075,
	1090,
	1095,
	1080,
	1100,
	1085,
	2126,
}
--门派的师门脚本ID....
ScriptGlobal.MENPAI_SHIMEN_SCRIPTID = 
{
	229000,
	229001,
	229008,
	229002,
	229003,
	229007,
	229004,
	229006,
	229005,
	229014,
	893259,
}
ScriptGlobal.MISSION_4006 = 4006
ScriptGlobal.MISSION_4007 = 4007
ScriptGlobal.MISSION_4008 = 4008
ScriptGlobal.MISSION_4009 = 4009
ScriptGlobal.MISSION_4013 = 4013
ScriptGlobal.MISSION_4022 = 4022
ScriptGlobal.MISSION_4028 = 4028
ScriptGlobal.MISSION_546 = 546
ScriptGlobal.MISSION_564 = 564
ScriptGlobal.MISSION_561 = 561
ScriptGlobal.MONEY_DISPLAY_SCRIPT_ID = 701604
ScriptGlobal.SHIMEN_MISSION_SCRIPT_ID = 229000

--物品质量生成规则
ScriptGlobal.QUALITY_CREATE_DEFAULT        = 0 -- 默认规则
ScriptGlobal.QUALITY_CREATE_BY_MONSTER     = 0 -- 怪物掉落规则
ScriptGlobal.QUALITY_CREATE_BY_BOSS        = 1 -- BOSS怪掉落规则
ScriptGlobal.QUALITY_CREATE_BY_FOUNDRY_NOR = 2 -- 低级材料锻造
ScriptGlobal.QUALITY_CREATE_BY_FOUNDRY_ADV = 3 -- 高级材料锻造
ScriptGlobal.QUALITY_MUST_BE_CHANGE        = 0 -- 可能需要被修改（这个参数值最后要被修改成下面的值）


ScriptGlobal.MIN_APPOINT_TIME_FOR_BONUS          = 7200
ScriptGlobal.CITY_BUILDING_XIANYA			= 0			--县衙0
ScriptGlobal.CITY_BUILDING_XIANGFANG		= 1     --厢房1
ScriptGlobal.CITY_BUILDING_JIUSI				= 2     --酒肆2
ScriptGlobal.CITY_BUILDING_QIANZHUANG	= 3     --钱庄3
ScriptGlobal.CITY_BUILDING_FANGJUFANG	= 4     --防具4
ScriptGlobal.CITY_BUILDING_DUANTAI			= 5     --锻台5
ScriptGlobal.CITY_BUILDING_WUJUFANG		= 6     --武具6
ScriptGlobal.CITY_BUILDING_MICANG			= 7     --米仓7
ScriptGlobal.CITY_BUILDING_CHENGQIANG	= 8     --城墙8
ScriptGlobal.CITY_BUILDING_JIFANG			= 9     --集仿9
ScriptGlobal.CITY_BUILDING_YISHE				= 10    --医舍10
ScriptGlobal.CITY_BUILDING_WUFANG			= 11    --武仿11
ScriptGlobal.CITY_BUILDING_JIANTA			= 12    --箭塔12
ScriptGlobal.CITY_BUILDING_SHUFANG			= 13    --书房13
ScriptGlobal.CITY_BUILDING_QIJI				= 14    --奇迹14
ScriptGlobal.CITY_BUILDING_XIAOCHANG		= 15    --校场15
ScriptGlobal.CITY_BUILDING_HUOBINGTA		= 16    --火冰塔16
ScriptGlobal.CITY_BUILDING_DAQI				= 17    --大旗17

ScriptGlobal.CITY_IND_RATE		= 0		--工业率0
ScriptGlobal.CITY_AGR_RATE		=	1   --农业率1
ScriptGlobal.CITY_COM_RATE		=	2   --商业率2
ScriptGlobal.CITY_DEF_RATE		=	3   --防卫率3
ScriptGlobal.CITY_TECH_RATE	=	4   --科技率4
ScriptGlobal.CITY_AMBI_RATE	=	5   --扩张率5

--天外的话更新后记得重启天外
--任意场景阵营配置   场景ID sceneinfo.ini 中的 pvp 对应的表中需把  允许自由PK  配置成1
ScriptGlobal.TW_INI = {
	-- [场景ID] = {
		-- {seerver_id = 10,camp_id = 1001,guild_id = {1,2,3,4,5}},	--10号服务器 guild_id 里的帮会进入时带阵营 1001
		-- {seerver_id = 11,camp_id = 1002},		--11号服务器 所有人进入该场景时带阵营 1002
	-- },

	[1297] = {
		{seerver_id = 10,camp_id = 1001,guild_id = {1}},
		{seerver_id = 11,camp_id = 1002,guild_id = {1}},
	
	
	},


}
--
--功能开关类型
ScriptGlobal.ONOFF_T_PETPRO	= 0	--珍兽繁殖
ScriptGlobal.ONOFF_T_GUILD		= 1	--建帮
ScriptGlobal.ONOFF_T_CITY		= 2	--建城
ScriptGlobal.ONOFF_T_PSHOP		= 3	--玩家商店
ScriptGlobal.ONOFF_T_CSHOP		= 4	--寄售商店
ScriptGlobal.ONOFF_T_YBCASH		= 5	--元宝票NPC兑换
ScriptGlobal.ONOFF_T_YBUSE		= 6	--元宝票使用
--WorldGlobalData
ScriptGlobal.WORLDGLOBAL_SHENBINGTYPE = 100 --每日七情副本类型
ScriptGlobal.WORLDGLOBAL_SHENBINGTIME = 99 --七情副本时间记录
--WorldGlobalDataEx
ScriptGlobal.WORLDGLOBAL_JIANGLINUM = 96 --奖励次数
ScriptGlobal.WORLDGLOBAL_XUYUANCISHU = 95 --全服许愿次数


ScriptGlobal.is_internal_test =  false--true--false --内测开关，正常开服不要打开

-- ========== 从 GameServer/ScriptGlobal.lua 合并的常量 ==========
ScriptGlobal.MDEX_JINGPAI_CDTIME = 425
ScriptGlobal.MD_SHOUHUA = 606					--花榜 收花
ScriptGlobal.MD_SONGHUA = 605					--花榜 送花

return ScriptGlobal
