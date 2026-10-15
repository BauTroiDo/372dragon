-- SINH MÁY bởi Tools/server/menpai_fix.py (menpai-fix): tập ID CY cho logic điều kiện CY (scene.skill.condition_cy).
-- Nguồn: IDCollections client CY 3.71 (522 dòng) + dòng chỉ có ở tlbb15 Public/Config (10: 340,341,342,343,344,345,346,347,348,349).
-- KHÔNG thay configs/IDCollections.txt của server (bản HJS/GL, Lua GL + StandardImpact tlbb15 còn dùng).
return {
    [1] = {type = 0, ids = {[105] = true, [108] = true, [106] = true}}, -- 摩诃无量+万劫无相+明镜无尘
    [2] = {type = 0, ids = {[105] = true, [108] = true, [109] = true}}, -- 摩诃无量+万劫无相+迦叶会心
    [3] = {type = 0, ids = {[105] = true}}, -- 摩诃无量
    [4] = {type = 0, ids = {[108] = true}}, -- 万劫无相
    [5] = {type = 1, ids = {[1] = true, [2] = true, [3] = true, [4] = true}}, -- HPDOT1~4
    [6] = {type = 1, ids = {[5] = true, [6] = true, [46] = true}}, -- HPDOT5~6
    [7] = {type = 0, ids = {[117] = true, [118] = true}}, -- 日行式+夜行式
    [8] = {type = 0, ids = {[117] = true}}, -- 日行式
    [9] = {type = 0, ids = {[118] = true}}, -- 夜行式
    [10] = {type = 0, ids = {[126] = true, [127] = true}}, -- 囚龙式+擒龙式
    [11] = {type = 0, ids = {[126] = true, [127] = true, [129] = true}}, -- 囚龙式+擒龙式+神龙摆尾
    [12] = {type = 0, ids = {[126] = true}}, -- 囚龙式
    [13] = {type = 0, ids = {[127] = true}}, -- 擒龙式
    [14] = {type = 0, ids = {[137] = true, [138] = true, [140] = true}}, -- 犀牛望月式+野马分鬃式+玉女穿梭
    [15] = {type = 0, ids = {[137] = true, [140] = true, [141] = true}}, -- 犀牛望月式+野马分鬃式+白鹤晾翅
    [16] = {type = 0, ids = {[137] = true}}, -- 犀牛望月式
    [17] = {type = 0, ids = {[140] = true}}, -- 野马分鬃式
    [18] = {type = 0, ids = {[147] = true}}, -- 绝剑式
    [19] = {type = 0, ids = {[148] = true}}, -- 灭剑式
    [20] = {type = 0, ids = {[145] = true}}, -- 菩提护体
    [21] = {type = 0, ids = {[147] = true, [148] = true, [151] = true}}, -- 绝剑式＋灭剑式＋斩情诀
    [22] = {type = 0, ids = {[147] = true, [148] = true}}, -- 绝剑式＋灭剑式
    [23] = {type = 3, ids = {[403] = true}}, -- 峨嵋聚气技能
    [24] = {type = 0, ids = {[159] = true}}, -- 神木行
    [25] = {type = 0, ids = {[161] = true}}, -- 御水行
    [26] = {type = 0, ids = {[159] = true, [161] = true}}, -- 神木行+御水行
    [27] = {type = 0, ids = {[171] = true}}, -- 截拳式
    [28] = {type = 0, ids = {[172] = true}}, -- 破剑式
    [29] = {type = 0, ids = {[171] = true, [172] = true, [173] = true}}, -- 截拳式+破剑式+金玉满堂
    [30] = {type = 0, ids = {[171] = true, [172] = true}}, -- 截拳式+破剑式
    [31] = {type = 0, ids = {[185] = true}}, -- 奈何心生
    [32] = {type = 0, ids = {[183] = true}}, -- 奈何心死
    [33] = {type = 0, ids = {[183] = true, [185] = true}}, -- 奈何心生+奈何心死
    [34] = {type = 3, ids = {[529] = true}}, -- 诛仙阵
    [35] = {type = 0, ids = {[196] = true}}, -- 抚琴式
    [36] = {type = 0, ids = {[192] = true}}, -- 运笔式
    [37] = {type = 0, ids = {[192] = true, [196] = true}}, -- 抚琴式+运笔式
    [38] = {type = 0, ids = {[192] = true, [196] = true, [193] = true}}, -- 抚琴式+运笔式+江行初雪
    [39] = {type = 1, ids = {[11] = true}}, -- 围困
    [40] = {type = 1, ids = {[13] = true, [122] = true}}, -- 封穴
    [41] = {type = 1, ids = {[15] = true}}, -- 昏睡
    [42] = {type = 1, ids = {[17] = true}}, -- 失明
    [43] = {type = 1, ids = {[19] = true}}, -- 定身
    [44] = {type = 1, ids = {[21] = true}}, -- 散功
    [45] = {type = 1, ids = {[23] = true, [38] = true, [98] = true}}, -- 僵硬
    [46] = {type = 1, ids = {[12] = true}}, -- 石化
    [47] = {type = 1, ids = {[14] = true}}, -- 麻痹
    [48] = {type = 1, ids = {[16] = true}}, -- 失明
    [49] = {type = 1, ids = {[18] = true}}, -- 恐惧
    [50] = {type = 1, ids = {[20] = true}}, -- 缠绕
    [51] = {type = 1, ids = {[22] = true}}, -- 就擒
    [52] = {type = 1, ids = {[24] = true, [25] = true, [26] = true, [27] = true, [28] = true, [29] = true, [30] = true, [31] = true, [112] = true, [113] = true, [139] = true, [1516] = true, [1732] = true, [8500] = true, [8517] = true, [8535] = true, [8590] = true, [8617] = true}}, -- 破绽
    [53] = {type = 1, ids = {[32] = true, [33] = true, [34] = true, [35] = true, [36] = true, [37] = true, [1514] = true, [8605] = true, [9102] = true}}, -- 虚弱
    [54] = {type = 1, ids = {[39] = true, [40] = true, [41] = true, [42] = true, [43] = true, [44] = true, [45] = true, [46] = true, [47] = true, [48] = true, [49] = true, [50] = true, [51] = true, [52] = true, [53] = true, [54] = true, [55] = true, [56] = true, [57] = true, [58] = true, [59] = true}}, -- 强化
    [55] = {type = 1, ids = {[60] = true, [61] = true, [62] = true, [63] = true, [64] = true, [65] = true, [66] = true, [67] = true, [68] = true, [69] = true, [70] = true, [71] = true, [72] = true, [73] = true, [74] = true, [75] = true, [76] = true, [77] = true, [78] = true, [79] = true, [80] = true}}, -- 增强
    [56] = {type = 3, ids = {[0] = true, [281] = true, [282] = true, [283] = true, [291] = true, [295] = true, [298] = true}}, -- 少林攻击技能
    [57] = {type = 3, ids = {[0] = true, [341] = true, [342] = true, [343] = true, [347] = true, [351] = true, [355] = true, [358] = true, [361] = true}}, -- 丐帮攻击技能
    [58] = {type = 3, ids = {[0] = true, [371] = true, [372] = true, [373] = true, [377] = true, [385] = true, [388] = true, [391] = true, [395] = true}}, -- 武当攻击技能
    [59] = {type = 3, ids = {[0] = true, [461] = true, [462] = true, [463] = true, [465] = true, [467] = true, [469] = true, [471] = true, [475] = true, [478] = true, [481] = true, [487] = true, [488] = true, [821] = true, [822] = true, [823] = true, [825] = true, [826] = true}}, -- 大理攻击技能
    [60] = {type = 1, ids = {[11] = true, [12] = true, [13] = true, [14] = true, [15] = true, [16] = true, [17] = true, [18] = true, [19] = true, [20] = true, [21] = true, [22] = true}}, -- 控制
    [61] = {type = 0, ids = {[99] = true, [176] = true, [177] = true, [180] = true, [214] = true}}, -- 隐身
    [62] = {type = 3, ids = {[401] = true, [403] = true, [404] = true, [415] = true, [418] = true, [421] = true, [426] = true}}, -- 峨嵋攻击技能
    [63] = {type = 1, ids = {[99] = true, [251] = true}}, -- 漕运免疫（隐身、骑乘）
    [64] = {type = 3, ids = {[21] = true, [22] = true, [248] = true, [496] = true, [497] = true}}, -- 漕运禁用技能(乘骑，隐身，回城)
    [65] = {type = 6, ids = {[2] = true}}, -- 引爆陷阱类型
    [66] = {type = 1, ids = {[99] = true}}, -- 乘骑
    [67] = {type = 3, ids = {[281] = true, [283] = true, [291] = true, [295] = true, [298] = true, [311] = true, [313] = true, [321] = true, [325] = true, [328] = true, [341] = true, [343] = true, [351] = true, [355] = true, [358] = true, [371] = true, [373] = true, [381] = true, [385] = true, [388] = true, [401] = true, [403] = true, [411] = true, [415] = true, [418] = true, [431] = true, [433] = true, [441] = true, [445] = true, [448] = true}}, -- 门派攻击技能1
    [68] = {type = 3, ids = {[461] = true, [463] = true, [471] = true, [475] = true, [478] = true, [491] = true, [493] = true, [501] = true, [505] = true, [508] = true, [521] = true, [523] = true, [531] = true, [535] = true, [538] = true, [347] = true, [377] = true, [404] = true, [437] = true, [450] = true, [507] = true, [361] = true, [391] = true, [421] = true, [451] = true, [481] = true, [511] = true, [541] = true}}, -- 门派攻击技能2
    [69] = {type = 3, ids = {[53] = true, [59] = true, [60] = true, [61] = true, [62] = true, [373] = true, [378] = true, [404] = true, [432] = true, [437] = true, [443] = true, [462] = true, [700] = true, [701] = true}}, -- 引导类技能
    [70] = {type = 3, ids = {[0] = true, [281] = true, [311] = true, [341] = true, [371] = true, [401] = true, [431] = true, [461] = true, [491] = true, [521] = true, [760] = true, [2900] = true, [3430] = true, [3800] = true, [4515] = true, [4622] = true}}, -- 普通攻击和连续技
    [71] = {type = 3, ids = {[1002] = true}}, -- 火烧赤壁
    [72] = {type = 1, ids = {[136] = true, [213] = true}}, -- 封印
    [73] = {type = 3, ids = {[1004] = true}}, -- 蛟龙乱舞
    [74] = {type = 3, ids = {[1006] = true}}, -- 蜃龙乱舞
    [75] = {type = 1, ids = {[96] = true, [99] = true, [131] = true, [150] = true, [176] = true, [177] = true, [180] = true, [214] = true, [276] = true, [334] = true, [372] = true, [373] = true, [374] = true, [375] = true, [158] = true}}, -- 开箱免疫
    [76] = {type = 1, ids = {[441] = true}}, -- 开膛
    [77] = {type = 1, ids = {[5] = true}}, -- 噬血
    [78] = {type = 1, ids = {[6] = true}}, -- 兽毒
    [79] = {type = 1, ids = {[16] = true}}, -- 失魂
    [80] = {type = 1, ids = {[2] = true, [129] = true}}, -- 中毒
    [81] = {type = 1, ids = {[4] = true}}, -- 灼烧
    [82] = {type = 1, ids = {[1] = true}}, -- 失血
    [83] = {type = 3, ids = {[245] = true, [407] = true, [423] = true, [424] = true}}, -- 治疗技能
    [84] = {type = 3, ids = {[248] = true}}, -- 影遁
    [85] = {type = 1, ids = {[1019] = true}}, -- 剑舞内功
    [86] = {type = 1, ids = {[1020] = true}}, -- 剑舞外功
    [87] = {type = 0, ids = {[634] = true, [636] = true, [637] = true, [638] = true, [639] = true}}, -- 圣火传递乌龟免疫
    [88] = {type = 1, ids = {[11] = true, [13] = true, [14] = true, [15] = true, [17] = true, [18] = true, [19] = true, [20] = true, [21] = true, [22] = true, [23] = true, [136] = true, [269] = true, [382] = true}}, -- 嘲讽之外的控制
    [89] = {type = 1, ids = {[32] = true}}, -- 减血气上限
    [90] = {type = 3, ids = {[287] = true, [304] = true, [305] = true}}, -- 嘲讽技能
    [91] = {type = 1, ids = {[704] = true}}, -- 剑舞(紫)
    [92] = {type = 1, ids = {[705] = true}}, -- 剑舞(红)
    [93] = {type = 1, ids = {[706] = true}}, -- 剑舞(白)
    [94] = {type = 1, ids = {[707] = true}}, -- 剑舞(黄)
    [95] = {type = 1, ids = {[708] = true}}, -- 剑舞(蓝)
    [96] = {type = 1, ids = {[709] = true}}, -- 剑舞(绿)
    [97] = {type = 3, ids = {[407] = true}}, -- 峨眉冲虚养气
    [98] = {type = 3, ids = {[407] = true, [424] = true, [426] = true}}, -- 峨眉冲虚养气+清心
    [99] = {type = 1, ids = {[269] = true}}, -- 变身集合
    [100] = {type = 3, ids = {[402] = true, [467] = true, [535] = true}}, -- 伤害放大技能
    [101] = {type = 3, ids = {[334] = true, [515] = true}}, -- 天地明灭+烽火连城
    [102] = {type = 3, ids = {[726] = true, [727] = true}}, -- 珍兽连击技能
    [103] = {type = 3, ids = {[722] = true, [723] = true, [1260] = true, [1261] = true, [1262] = true, [1263] = true, [1264] = true, [1265] = true, [1266] = true, [1267] = true, [1268] = true}}, -- 珍兽猛击技能
    [104] = {type = 3, ids = {[728] = true, [729] = true, [1251] = true, [1252] = true, [1253] = true, [1254] = true, [1255] = true, [1256] = true, [1257] = true, [1258] = true, [1259] = true}}, -- 珍兽痛击技能
    [105] = {type = 3, ids = {[702] = true, [703] = true, [704] = true, [705] = true, [1269] = true, [1270] = true, [1271] = true, [1272] = true, [1273] = true, [1274] = true, [1275] = true, [1276] = true, [1277] = true, [1278] = true, [1279] = true, [1280] = true, [1281] = true, [1282] = true, [1283] = true, [1284] = true, [1285] = true, [1286] = true}}, -- 珍兽属性攻击技能1
    [106] = {type = 3, ids = {[1287] = true, [1288] = true, [1289] = true, [1290] = true, [1291] = true, [1292] = true, [1293] = true, [1294] = true, [1295] = true, [1296] = true, [1297] = true, [1298] = true, [1299] = true, [1300] = true, [1301] = true, [1302] = true, [1303] = true, [1304] = true}}, -- 珍兽属性攻击技能2
    [107] = {type = 3, ids = {[712] = true, [713] = true}}, -- 灵动
    [108] = {type = 3, ids = {[720] = true, [721] = true}}, -- 灵气
    [109] = {type = 3, ids = {[718] = true, [719] = true}}, -- 忠心
    [110] = {type = 3, ids = {[710] = true, [711] = true}}, -- 反震
    [111] = {type = 3, ids = {[706] = true, [707] = true}}, -- 反击
    [112] = {type = 3, ids = {[734] = true, [735] = true}}, -- 摔拌
    [113] = {type = 3, ids = {[732] = true, [733] = true}}, -- 破绽
    [114] = {type = 3, ids = {[730] = true, [731] = true}}, -- 虚弱
    [115] = {type = 3, ids = {[716] = true, [717] = true}}, -- 打怒
    [116] = {type = 3, ids = {[714] = true, [715] = true}}, -- 吸气
    [117] = {type = 3, ids = {[0] = true, [242] = true, [243] = true, [244] = true, [274] = true, [311] = true, [312] = true, [313] = true, [319] = true, [321] = true, [325] = true, [328] = true, [3566] = true, [3567] = true, [3568] = true, [3569] = true, [3570] = true, [3571] = true, [3572] = true, [3573] = true, [3574] = true, [3575] = true, [3576] = true, [3577] = true}}, -- 怒火连斩
    [118] = {type = 0, ids = {[176] = true, [180] = true, [214] = true}}, -- 被动隐身
    [119] = {type = 1, ids = {[1505] = true, [9] = true}}, -- 引导加血
    [120] = {type = 8, ids = {[121] = true}}, -- 怒火连斩
    [121] = {type = 3, ids = {[281] = true, [311] = true, [341] = true, [371] = true, [401] = true, [431] = true, [461] = true, [491] = true, [521] = true, [760] = true, [2900] = true, [3430] = true, [3800] = true, [4515] = true, [4622] = true}}, -- 十大门派的第一本心法第一个技能
    [122] = {type = 3, ids = {[283] = true, [313] = true, [343] = true, [373] = true, [403] = true, [433] = true, [463] = true, [493] = true, [523] = true, [763] = true, [2903] = true, [3433] = true, [3803] = true, [4518] = true, [4625] = true}}, -- 十大门派的第二本心法第一个技能
    [123] = {type = 3, ids = {[292] = true, [322] = true, [352] = true, [382] = true, [412] = true, [442] = true, [472] = true, [502] = true, [532] = true, [772] = true, [2912] = true}}, -- 十大门派的第四本心法第三个技能
    [124] = {type = 3, ids = {[295] = true, [325] = true, [355] = true, [385] = true, [415] = true, [445] = true, [475] = true, [505] = true, [535] = true, [775] = true, [2915] = true, [3445] = true, [3815] = true, [4532] = true, [4637] = true}}, -- 十大门派的第五本心法第二个技能
    [125] = {type = 3, ids = {[296] = true, [326] = true, [356] = true, [386] = true, [416] = true, [446] = true, [476] = true, [506] = true, [536] = true, [776] = true, [2916] = true}}, -- 十大门派的第五本心法第三个技能
    [126] = {type = 3, ids = {[298] = true, [328] = true, [358] = true, [388] = true, [418] = true, [448] = true, [478] = true, [508] = true, [538] = true, [778] = true, [2918] = true, [3448] = true, [3818] = true, [4539] = true, [4640] = true}}, -- 十大门派的第六本心法第一个技能
    [127] = {type = 1, ids = {[1515] = true, [1517] = true}}, -- 慕容姿态技能集合
    [128] = {type = 1, ids = {[1529] = true}}, -- 心剑交融BUFF借力
    [129] = {type = 1, ids = {[1531] = true, [1532] = true, [1533] = true, [1534] = true, [1535] = true, [1536] = true}}, -- 蓄云欲雨BUFF集合
    [130] = {type = 1, ids = {[1531] = true}}, -- 蓄气（围困）
    [131] = {type = 1, ids = {[1532] = true}}, -- 蓄气（封穴）
    [132] = {type = 1, ids = {[1533] = true}}, -- 蓄气（昏睡）
    [133] = {type = 1, ids = {[1534] = true}}, -- 蓄气（失明）
    [134] = {type = 1, ids = {[1535] = true}}, -- 蓄气（定身）
    [135] = {type = 1, ids = {[1536] = true}}, -- 蓄气（散功）
    [136] = {type = 3, ids = {[760] = true, [763] = true, [771] = true, [775] = true, [778] = true, [777] = true, [780] = true, [785] = true}}, -- 慕容攻击技能（补集合67和68）
    [137] = {type = 1, ids = {[1212] = true, [1213] = true, [1214] = true, [1215] = true, [1216] = true, [1217] = true, [1218] = true, [1219] = true, [1220] = true, [1221] = true, [2623] = true, [3656] = true, [4115] = true, [7152] = true, [9115] = true}}, -- 第八本心法的控制
    [138] = {type = 1, ids = {[11] = true, [13] = true, [14] = true, [15] = true, [17] = true, [18] = true, [19] = true, [20] = true, [21] = true, [22] = true, [23] = true, [32] = true, [136] = true, [233] = true, [269] = true, [382] = true, [1212] = true, [1213] = true, [1214] = true, [1215] = true, [1216] = true, [1217] = true, [1218] = true, [1219] = true, [1220] = true, [1221] = true, [49] = true, [3656] = true, [2623] = true, [3133] = true}}, -- 非伤害类负面效果1（综合88、89、137）（涉及到的集合138和334）
    [139] = {type = 3, ids = {[1077] = true, [1078] = true, [1081] = true}}, -- 拈花寺僧冷却技能集合
    [140] = {type = 3, ids = {[0] = true, [243] = true, [245] = true, [248] = true, [249] = true}}, -- 测试用拈花寺僧技能集合1
    [141] = {type = 3, ids = {[401] = true, [407] = true, [415] = true}}, -- 测试用拈花寺僧技能集合2
    [142] = {type = 1, ids = {[174] = true}}, -- 飞行部件
    [143] = {type = 1, ids = {[11] = true, [13] = true, [14] = true, [15] = true, [17] = true, [18] = true, [19] = true, [20] = true, [21] = true, [22] = true, [23] = true, [136] = true, [382] = true}}, -- 嘲讽变身之外的控制
    [144] = {type = 3, ids = {[1080] = true, [1077] = true, [1078] = true, [1081] = true, [1079] = true}}, -- 拈花寺僧新加技能
    [145] = {type = 3, ids = {[0] = true, [23] = true, [24] = true, [25] = true, [26] = true, [27] = true, [28] = true, [29] = true, [30] = true, [31] = true, [34] = true, [110] = true}}, -- 拈花寺僧允许使用的技能
    [146] = {type = 1, ids = {[1660] = true, [1662] = true}}, -- 庄聚贤免疫冰蚕的攻击
    [147] = {type = 3, ids = {[938] = true, [939] = true, [940] = true, [941] = true, [942] = true, [943] = true, [944] = true, [945] = true, [946] = true, [948] = true, [949] = true, [950] = true, [951] = true, [952] = true, [953] = true}}, -- 慕容博攻击技能
    [148] = {type = 1, ids = {[99] = true, [174] = true}}, -- 落马箭驱散集合
    [149] = {type = 3, ids = {[21] = true}}, -- 召唤坐骑技能
    [150] = {type = 3, ids = {[147] = true, [146] = true}}, -- 画龙点睛活动技能
    [151] = {type = 0, ids = {[1297] = true}}, -- 拈花寺僧移动速度加成集合
    [152] = {type = 1, ids = {[36] = true}}, -- 放大伤害的互斥ID
    [153] = {type = 0, ids = {[1687] = true}}, -- 帮会生产移动速度加成集合
    [154] = {type = 3, ids = {}}, -- 搬运工技能
    [155] = {type = 3, ids = {[1767] = true, [1766] = true}}, -- 采集工技能
    [156] = {type = 3, ids = {[1768] = true, [1766] = true}}, -- 收集工技能
    [157] = {type = 3, ids = {[1769] = true, [1766] = true}}, -- 挖掘工技能
    [158] = {type = 1, ids = {[32] = true}}, -- 剧情本慕容博萧远山免疫减血上限
    [159] = {type = 0, ids = {[614] = true}}, -- 逍遥放大效果
    [160] = {type = 3, ids = {[269] = true, [270] = true, [271] = true, [272] = true, [273] = true, [379] = true, [503] = true, [515] = true, [524] = true, [2904] = true, [3806] = true, [3807] = true, [3808] = true, [4516] = true, [4544] = true, [4626] = true, [5829] = true, [5836] = true, [5838] = true, [5842] = true, [5844] = true, [5847] = true}}, -- 非敌对目标传送技能（钱庄不能用的位移技能）
    [161] = {type = 3, ids = {[154] = true, [155] = true}}, -- 变身飞禽后新增加的技能（许愿树的烦恼）
    [162] = {type = 3, ids = {[1772] = true}}, -- 循环采集烹饪技能
    [163] = {type = 3, ids = {[1773] = true, [1774] = true, [1775] = true, [1776] = true, [1777] = true, [1778] = true}}, -- 循环捕鱼技能
    [164] = {type = 3, ids = {[1779] = true, [1780] = true, [1781] = true, [1782] = true}}, -- QTE制药技能
    [165] = {type = 3, ids = {[1783] = true, [1784] = true, [1785] = true, [1786] = true, [1787] = true, [1788] = true}}, -- 元素精粹打造变身技能
    [167] = {type = 3, ids = {[1902] = true}}, -- 秘境矿师变身技能
    [168] = {type = 9, ids = {[54] = true}}, -- 秘境矿师采矿
    [169] = {type = 3, ids = {[2201] = true, [2203] = true, [2205] = true, [2202] = true, [2204] = true}}, -- 少林QTE
    [170] = {type = 3, ids = {[2206] = true, [2210] = true, [2208] = true, [2207] = true, [2209] = true}}, -- 明教QTE
    [171] = {type = 3, ids = {[2211] = true, [2212] = true, [2213] = true, [2214] = true}}, -- 丐帮QTE
    [172] = {type = 3, ids = {[2215] = true, [2216] = true, [2217] = true, [2218] = true}}, -- 武当QTE
    [173] = {type = 3, ids = {[2219] = true, [2220] = true, [2221] = true, [2222] = true}}, -- 峨眉QTE
    [174] = {type = 3, ids = {[2223] = true, [2224] = true, [2225] = true, [2226] = true, [2227] = true}}, -- 星宿QTE
    [175] = {type = 3, ids = {[2229] = true, [2228] = true, [2232] = true, [2231] = true, [2230] = true}}, -- 天龙QTE
    [176] = {type = 3, ids = {[2233] = true, [2234] = true, [2235] = true, [2236] = true, [2237] = true}}, -- 天山QTE
    [177] = {type = 3, ids = {[2238] = true, [2239] = true, [2240] = true, [2241] = true}}, -- 逍遥QTE
    [178] = {type = 3, ids = {[2242] = true, [2243] = true, [2244] = true, [2245] = true, [2246] = true}}, -- 慕容QTE
    [179] = {type = 3, ids = {[2247] = true, [2248] = true, [2249] = true}}, -- 少林第三环
    [180] = {type = 3, ids = {[2250] = true, [2251] = true, [2252] = true}}, -- 明教第三环
    [181] = {type = 3, ids = {[2253] = true, [2254] = true, [2255] = true}}, -- 丐帮第三环
    [182] = {type = 3, ids = {[2256] = true, [2257] = true, [2258] = true}}, -- 武当第三环
    [183] = {type = 3, ids = {[2259] = true, [2260] = true, [2261] = true}}, -- 峨眉第三环
    [184] = {type = 3, ids = {[2262] = true, [2263] = true, [2264] = true}}, -- 星宿第三环
    [185] = {type = 3, ids = {[2265] = true, [2266] = true, [2267] = true}}, -- 天龙第三环
    [186] = {type = 3, ids = {[2268] = true, [2269] = true, [2270] = true}}, -- 天山第三环
    [187] = {type = 3, ids = {[2271] = true, [2272] = true, [2273] = true}}, -- 逍遥第三环
    [188] = {type = 3, ids = {[2274] = true, [2275] = true, [2276] = true}}, -- 慕容第三环
    [189] = {type = 3, ids = {[168] = true, [170] = true}}, -- 疾风迅影
    [190] = {type = 3, ids = {[169] = true, [170] = true}}, -- 疾风迅影战京师
    [191] = {type = 3, ids = {[23] = true, [281] = true, [282] = true, [283] = true, [284] = true, [285] = true, [286] = true, [287] = true, [288] = true, [289] = true, [290] = true, [291] = true, [292] = true, [293] = true, [294] = true, [295] = true, [296] = true, [297] = true, [298] = true, [299] = true, [300] = true, [301] = true, [302] = true, [303] = true, [304] = true, [305] = true, [306] = true, [307] = true, [308] = true}}, -- 少林
    [192] = {type = 3, ids = {[24] = true, [311] = true, [312] = true, [313] = true, [314] = true, [315] = true, [316] = true, [317] = true, [318] = true, [319] = true, [320] = true, [321] = true, [322] = true, [323] = true, [324] = true, [325] = true, [326] = true, [327] = true, [328] = true, [329] = true, [330] = true, [331] = true, [332] = true, [333] = true, [334] = true, [335] = true, [336] = true, [337] = true}}, -- 明教
    [193] = {type = 3, ids = {[25] = true, [341] = true, [342] = true, [343] = true, [344] = true, [345] = true, [346] = true, [347] = true, [348] = true, [349] = true, [350] = true, [351] = true, [352] = true, [353] = true, [354] = true, [355] = true, [356] = true, [357] = true, [358] = true, [359] = true, [360] = true, [361] = true, [362] = true, [363] = true, [364] = true, [365] = true, [366] = true, [367] = true}}, -- 丐帮
    [194] = {type = 3, ids = {[26] = true, [371] = true, [372] = true, [373] = true, [374] = true, [375] = true, [376] = true, [377] = true, [378] = true, [379] = true, [380] = true, [381] = true, [382] = true, [383] = true, [384] = true, [385] = true, [386] = true, [387] = true, [388] = true, [389] = true, [390] = true, [391] = true, [392] = true, [393] = true, [394] = true, [395] = true, [396] = true, [397] = true}}, -- 武当
    [195] = {type = 3, ids = {[27] = true, [401] = true, [402] = true, [403] = true, [404] = true, [405] = true, [406] = true, [407] = true, [408] = true, [409] = true, [410] = true, [411] = true, [412] = true, [413] = true, [414] = true, [415] = true, [416] = true, [417] = true, [418] = true, [419] = true, [420] = true, [421] = true, [422] = true, [423] = true, [424] = true, [425] = true, [426] = true, [427] = true, [428] = true}}, -- 峨嵋
    [196] = {type = 3, ids = {[28] = true, [431] = true, [432] = true, [433] = true, [434] = true, [435] = true, [436] = true, [437] = true, [438] = true, [439] = true, [440] = true, [441] = true, [442] = true, [443] = true, [444] = true, [445] = true, [446] = true, [447] = true, [448] = true, [449] = true, [450] = true, [451] = true, [452] = true, [453] = true, [454] = true, [455] = true, [456] = true, [457] = true}}, -- 星宿
    [197] = {type = 3, ids = {[29] = true, [461] = true, [462] = true, [463] = true, [464] = true, [465] = true, [466] = true, [467] = true, [468] = true, [469] = true, [470] = true, [471] = true, [472] = true, [473] = true, [474] = true, [475] = true, [476] = true, [477] = true, [478] = true, [479] = true, [480] = true, [481] = true, [482] = true, [483] = true, [484] = true, [487] = true, [488] = true, [489] = true, [490] = true}}, -- 大理
    [198] = {type = 3, ids = {[30] = true, [491] = true, [492] = true, [493] = true, [494] = true, [495] = true, [496] = true, [497] = true, [498] = true, [499] = true, [500] = true, [501] = true, [502] = true, [503] = true, [504] = true, [505] = true, [506] = true, [507] = true, [508] = true, [509] = true, [510] = true, [511] = true, [512] = true, [513] = true, [514] = true, [515] = true, [516] = true, [517] = true, [518] = true}}, -- 天山
    [199] = {type = 3, ids = {[31] = true, [521] = true, [522] = true, [523] = true, [524] = true, [525] = true, [526] = true, [527] = true, [528] = true, [529] = true, [530] = true, [531] = true, [532] = true, [533] = true, [534] = true, [535] = true, [536] = true, [537] = true, [538] = true, [539] = true, [540] = true, [541] = true, [542] = true, [543] = true, [544] = true, [545] = true, [546] = true, [547] = true}}, -- 逍遥
    [200] = {type = 3, ids = {[110] = true, [760] = true, [761] = true, [762] = true, [763] = true, [764] = true, [765] = true, [766] = true, [767] = true, [768] = true, [769] = true, [770] = true, [771] = true, [772] = true, [773] = true, [774] = true, [775] = true, [776] = true, [777] = true, [778] = true, [779] = true, [780] = true, [781] = true, [784] = true, [785] = true, [786] = true, [787] = true, [795] = true, [796] = true}}, -- 慕容
    [201] = {type = 3, ids = {[0] = true, [2] = true, [1] = true, [1652] = true, [3] = true, [22] = true, [241] = true, [242] = true, [243] = true, [244] = true, [245] = true, [246] = true, [247] = true, [248] = true, [249] = true, [277] = true, [37] = true, [274] = true, [275] = true, [276] = true, [80] = true, [81] = true, [86] = true, [788] = true, [789] = true, [790] = true, [791] = true, [792] = true, [793] = true, [794] = true}}, -- 变身通用
    [202] = {type = 3, ids = {[2300] = true, [2301] = true, [2302] = true, [2303] = true, [2304] = true, [2320] = true}}, -- 幽毒战车技能
    [203] = {type = 3, ids = {[2305] = true, [2306] = true, [2307] = true, [2308] = true, [2309] = true, [2320] = true}}, -- 玄音战车技能
    [204] = {type = 3, ids = {[2310] = true, [2311] = true, [2312] = true, [2313] = true, [2314] = true, [2320] = true}}, -- 火云战车技能
    [205] = {type = 3, ids = {[2315] = true, [2316] = true, [2317] = true, [2318] = true, [2319] = true, [2320] = true}}, -- 凌冰战车技能
    [206] = {type = 3, ids = {[2300] = true}}, -- 幽毒战车普通攻击技能
    [207] = {type = 3, ids = {[2305] = true}}, -- 玄音战车普通攻击技能
    [208] = {type = 3, ids = {[2310] = true}}, -- 火云战车普通攻击技能
    [209] = {type = 3, ids = {[2315] = true}}, -- 凌冰战车普通攻击技能
    [210] = {type = 3, ids = {[2306] = true}}, -- 玄音战车玄七雷技能
    [211] = {type = 3, ids = {[2316] = true}}, -- 凌冰战车千里冰封技能
    [212] = {type = 0, ids = {[1852] = true, [1889] = true}}, -- 正法BUFF
    [213] = {type = 0, ids = {[1853] = true, [1890] = true}}, -- 邪法BUFF
    [214] = {type = 0, ids = {[1855] = true}}, -- 点名心魔
    [215] = {type = 0, ids = {[1856] = true}}, -- 非点名心魔
    [216] = {type = 3, ids = {[281] = true, [282] = true, [283] = true, [291] = true, [295] = true, [298] = true, [341] = true, [342] = true, [343] = true, [347] = true, [351] = true, [355] = true, [358] = true, [364] = true, [371] = true, [372] = true, [377] = true, [381] = true, [385] = true, [388] = true, [391] = true, [395] = true, [401] = true, [403] = true, [418] = true, [426] = true, [521] = true, [523] = true, [533] = true, [535] = true}}, -- 慕容博内息冷却和伤害增加效果（1）
    [217] = {type = 3, ids = {[431] = true, [432] = true, [433] = true, [441] = true, [445] = true, [448] = true, [450] = true, [451] = true, [461] = true, [462] = true, [463] = true, [471] = true, [475] = true, [491] = true, [492] = true, [493] = true, [501] = true, [505] = true, [507] = true, [508] = true, [760] = true, [761] = true, [763] = true, [771] = true, [775] = true, [777] = true, [778] = true, [780] = true}}, -- 慕容博内息冷却和伤害增加效果（2）
    [218] = {type = 0, ids = {[1870] = true}}, -- 天陨火雨增强标记BUFF
    [219] = {type = 3, ids = {[2300] = true, [2301] = true, [2305] = true, [2306] = true, [2310] = true, [2311] = true, [2315] = true, [2316] = true}}, -- 不需要计算角色自身属性伤害的技能
    [220] = {type = 1, ids = {[23] = true}}, -- 减速
    [221] = {type = 3, ids = {[939] = true, [942] = true, [2336] = true}}, -- 慕容博明教内息技能集合1
    [222] = {type = 3, ids = {[950] = true, [948] = true, [952] = true}}, -- 慕容博明教内息技能集合2
    [223] = {type = 3, ids = {[939] = true, [942] = true, [950] = true, [948] = true, [952] = true}}, -- 慕容博武当内息技能集合
    [224] = {type = 1, ids = {[1926] = true}}, -- 驱散萧远山追击BUFF技能
    [225] = {type = 1, ids = {[1927] = true}}, -- 驱散慕容博追击BUFF技能
    [226] = {type = 0, ids = {[335] = true, [352] = true, [353] = true, [357] = true}}, -- 珍兽与主人配合的疲劳buff
    [227] = {type = 3, ids = {[2532] = true}}, -- 黄龙揽尾·剑宗
    [229] = {type = 3, ids = {[2501] = true, [2504] = true, [2507] = true, [2510] = true, [2513] = true, [2515] = true, [2518] = true, [2521] = true, [2524] = true, [2527] = true}}, -- 武林秘籍中不考虑玩家自身普攻伤害的技能
    [230] = {type = 0, ids = {[2614] = true}}, -- 催箭式
    [231] = {type = 0, ids = {[2617] = true}}, -- 震箭式
    [232] = {type = 0, ids = {[2614] = true, [2617] = true, [2618] = true}}, -- 催箭式＋震箭式＋风雷万钧
    [233] = {type = 0, ids = {[2614] = true, [2615] = true}}, -- 催箭式＋震箭式+软猬仙身
    [234] = {type = 3, ids = {[2900] = true, [2901] = true, [2902] = true, [2903] = true, [2904] = true, [2905] = true, [2906] = true, [2907] = true, [2908] = true, [2909] = true, [2911] = true, [2912] = true, [2913] = true, [2915] = true, [2916] = true, [2917] = true, [2918] = true, [2919] = true, [2920] = true, [2921] = true, [2922] = true, [2923] = true, [2924] = true, [2925] = true, [4462] = true, [4463] = true, [4464] = true}}, -- 唐门技能
    [235] = {type = 3, ids = {[2927] = true, [2928] = true, [2929] = true, [2930] = true}}, -- 唐门QTE
    [236] = {type = 3, ids = {[2931] = true, [2932] = true, [2933] = true}}, -- 唐门第三环
    [237] = {type = 3, ids = {[2947] = true, [2948] = true, [2949] = true}}, -- 低级礼仪技能集合
    [238] = {type = 3, ids = {[2950] = true, [2951] = true, [2952] = true, [2953] = true}}, -- 中级礼仪技能集合
    [239] = {type = 3, ids = {[2954] = true, [2955] = true, [2956] = true, [2957] = true, [2958] = true}}, -- 高级礼仪技能集合
    [240] = {type = 3, ids = {[406] = true, [407] = true, [423] = true, [424] = true, [426] = true}}, -- 免疫春花秋月
    [241] = {type = 0, ids = {[116] = true, [283] = true, [284] = true, [285] = true, [286] = true, [287] = true, [288] = true, [289] = true, [290] = true, [291] = true, [1305] = true, [2607] = true}}, -- 门派增益BUFF
    [242] = {type = 3, ids = {[3092] = true}}, -- 变身：帮会郎中
    [243] = {type = 3, ids = {[3093] = true, [3112] = true}}, -- 变身：夜行劲装
    [244] = {type = 3, ids = {[3094] = true, [3095] = true, [3096] = true, [3097] = true, [3098] = true, [3099] = true}}, -- 变身：帮会渔夫
    [245] = {type = 3, ids = {[3104] = true}}, -- 变身：菜园农夫
    [246] = {type = 3, ids = {[3105] = true}}, -- 变身：军需队长
    [247] = {type = 1, ids = {[2885] = true, [2888] = true, [2890] = true}}, -- 风雨无阻
    [248] = {type = 3, ids = {[3106] = true, [3107] = true, [3109] = true}}, -- 变身矿工
    [249] = {type = 3, ids = {[3092] = true}}, -- 增强帮派任务加血技能
    [250] = {type = 10, ids = {[38855] = true, [38856] = true, [38857] = true, [38858] = true}}, -- 帮会产金变身buff合计
    [251] = {type = 10, ids = {[38837] = true, [38843] = true, [38845] = true}}, -- 加速互斥1
    [252] = {type = 10, ids = {[38848] = true}}, -- 减速互斥
    [253] = {type = 10, ids = {[38849] = true, [38850] = true}}, -- 眩晕互斥
    [254] = {type = 10, ids = {[38845] = true, [38837] = true}}, -- 加速互斥2
    [255] = {type = 10, ids = {[38837] = true}}, -- 加速互斥3
    [256] = {type = 1, ids = {[100] = true, [701] = true}}, -- 帮会产金免疫唐门群加速
    [257] = {type = 1, ids = {[99] = true, [251] = true}}, -- 押镖免疫（隐身、骑乘）
    [258] = {type = 3, ids = {[21] = true, [248] = true, [496] = true, [497] = true, [514] = true}}, -- 押镖禁用技能(乘骑，隐身)
    [259] = {type = 3, ids = {[3172] = true}}, -- KVK野外挂BOSS技能
    [260] = {type = 3, ids = {[306] = true}}, -- 战旗免疫效果
    [261] = {type = 1, ids = {[1] = true, [2] = true, [3] = true, [4] = true, [35] = true, [125] = true, [129] = true, [1514] = true}}, -- 战旗免疫效果
    [262] = {type = 3, ids = {[245] = true, [522] = true, [527] = true, [529] = true, [544] = true, [545] = true, [784] = true}}, -- 战旗免疫效果
    [263] = {type = 3, ids = {[276] = true, [301] = true, [406] = true, [407] = true, [423] = true, [424] = true, [426] = true}}, -- 免疫春花秋月
    [264] = {type = 2, ids = {[1] = true}}, -- 免疫逻辑ID
    [265] = {type = 3, ids = {[3185] = true, [3188] = true, [3189] = true, [3191] = true, [3192] = true, [3194] = true, [3196] = true, [3197] = true}}, -- 情定三生（男）
    [266] = {type = 3, ids = {[3186] = true, [3187] = true, [3190] = true, [3193] = true, [3195] = true, [3198] = true}}, -- 情定三生（女）
    [267] = {type = 3, ids = {[3199] = true, [3200] = true, [3203] = true, [3205] = true, [3207] = true, [3209] = true, [3210] = true, [3212] = true}}, -- 情定三生（男）
    [268] = {type = 3, ids = {[3201] = true, [3202] = true, [3204] = true, [3206] = true, [3208] = true, [3211] = true}}, -- 情定三生（女）
    [269] = {type = 3, ids = {[3213] = true, [3215] = true, [3216] = true, [3217] = true, [3220] = true, [3221] = true, [3223] = true, [3225] = true}}, -- 情定三生（男）
    [270] = {type = 3, ids = {[3214] = true, [3218] = true, [3219] = true, [3222] = true, [3224] = true, [3226] = true}}, -- 情定三生（女）
    [271] = {type = 3, ids = {[3230] = true, [3231] = true, [3232] = true}}, -- 变身：新师父
    [272] = {type = 3, ids = {[3233] = true, [3240] = true}}, -- 变身：新徒弟
    [273] = {type = 3, ids = {[3236] = true, [3237] = true, [3238] = true, [3239] = true, [3240] = true}}, -- 变身：老徒弟
    [274] = {type = 3, ids = {[3241] = true, [3242] = true, [3243] = true, [3244] = true, [3245] = true}}, -- 演奏QTE
    [275] = {type = 3, ids = {[3247] = true, [3248] = true}}, -- 暗器习练
    [276] = {type = 3, ids = {[3277] = true}}, -- 变身：七夕男
    [277] = {type = 3, ids = {[3280] = true}}, -- 变身：七夕女
    [278] = {type = 3, ids = {[3285] = true}}, -- 瓜农
    [279] = {type = 3, ids = {[3286] = true}}, -- 保镖
    [280] = {type = 3, ids = {[3287] = true, [3288] = true, [3289] = true}}, -- 变身：夫妻任务夫君
    [281] = {type = 3, ids = {[3290] = true, [3291] = true, [3292] = true}}, -- 变身：夫妻任务娘子
    [282] = {type = 3, ids = {[3294] = true}}, -- 抓捕
    [283] = {type = 3, ids = {[3295] = true, [3325] = true, [3327] = true}}, -- 空矿车
    [284] = {type = 3, ids = {[3318] = true, [3319] = true, [3320] = true, [3321] = true, [3322] = true, [3323] = true, [3341] = true, [3342] = true, [3343] = true, [3344] = true, [3345] = true, [3346] = true, [3347] = true, [3348] = true, [3349] = true, [3350] = true, [3351] = true, [3352] = true, [3353] = true, [3354] = true, [3355] = true, [3356] = true, [3357] = true, [3358] = true, [3359] = true, [3360] = true, [3361] = true, [3362] = true, [3363] = true, [3364] = true}}, -- 连射
    [285] = {type = 3, ids = {[3296] = true, [3325] = true, [3327] = true}}, -- 满矿车
    [286] = {type = 3, ids = {[3296] = true, [3327] = true}}, -- 破损矿车
    [287] = {type = 3, ids = {[334] = true}}, -- 烽火连城免疫
    [288] = {type = 3, ids = {[3403] = true, [515] = true}}, -- 调用新的伤害计算逻辑的技能（目前只有暗器连击）
    [289] = {type = 2, ids = {[1] = true, [2] = true, [3] = true, [4] = true, [5] = true, [57] = true, [63] = true, [67] = true, [70] = true, [82] = true, [110] = true, [114] = true, [140] = true}}, -- 鬼谷图腾
    [290] = {type = 3, ids = {[3420] = true, [3421] = true, [3422] = true, [3423] = true, [3424] = true}}, -- 家宴变身
    [291] = {type = 3, ids = {[3501] = true}}, -- 鬼谷变身1+取消
    [292] = {type = 3, ids = {[3502] = true}}, -- 鬼谷变身2+取消
    [293] = {type = 3, ids = {[3503] = true}}, -- 鬼谷变身3+取消
    [294] = {type = 3, ids = {[3504] = true}}, -- 鬼谷变身4+取消
    [295] = {type = 3, ids = {[3511] = true, [3512] = true, [3513] = true, [3514] = true, [3515] = true}}, -- 变身：楼兰舞娘
    [296] = {type = 0, ids = {[3651] = true, [3653] = true}}, -- 逍遥游＋意纵横
    [297] = {type = 0, ids = {[3651] = true}}, -- 逍遥游
    [298] = {type = 0, ids = {[3653] = true}}, -- 意纵横
    [299] = {type = 3, ids = {[3430] = true, [3431] = true, [3432] = true, [3433] = true, [3434] = true, [3435] = true, [3436] = true, [3437] = true, [3438] = true, [3439] = true, [3440] = true, [3441] = true, [3442] = true, [3443] = true, [3444] = true, [3445] = true, [3446] = true, [3447] = true, [3448] = true, [3449] = true, [3450] = true, [3451] = true, [3452] = true, [3453] = true, [3454] = true, [3455] = true, [3456] = true}}, -- 鬼谷技能
    [300] = {type = 3, ids = {[3524] = true, [3525] = true, [3526] = true, [3527] = true}}, -- 鬼谷QTE
    [301] = {type = 3, ids = {[3528] = true, [3529] = true, [3539] = true, [3540] = true}}, -- 鬼谷进阶3变身
    [302] = {type = 1, ids = {[784] = true}}, -- 九星铸魂火墙
    [303] = {type = 3, ids = {[3643] = true, [3644] = true, [3646] = true}}, -- 爆竹侠士
    [304] = {type = 3, ids = {[3665] = true}}, -- 气球变身
    [305] = {type = 3, ids = {[3671] = true, [3672] = true, [3673] = true, [3674] = true}}, -- 吃瓜群众
    [306] = {type = 3, ids = {[3669] = true}}, -- 瓜农
    [307] = {type = 3, ids = {[3670] = true}}, -- 保镖
    [308] = {type = 1, ids = {[105] = true, [115] = true, [116] = true, [117] = true, [126] = true, [129] = true, [134] = true, [137] = true, [138] = true, [145] = true, [147] = true, [151] = true, [158] = true, [159] = true, [161] = true, [168] = true, [171] = true, [172] = true, [99] = true, [185] = true, [183] = true, [192] = true, [190] = true, [292] = true, [193] = true, [1515] = true, [2611] = true, [2617] = true, [3651] = true, [3653] = true}}, -- 转门派驱散BUFF互斥ID集合
    [309] = {type = 3, ids = {[3680] = true}}, -- 集枫叶
    [310] = {type = 3, ids = {[3690] = true, [3691] = true}}, -- 天眼
    [311] = {type = 3, ids = {[3701] = true, [3702] = true, [3703] = true, [3704] = true, [3705] = true, [3706] = true, [3707] = true}}, -- 妙手织锦
    [312] = {type = 1, ids = {[4395] = true, [4159] = true}}, -- 明夷于飞＋人世何欢
    [313] = {type = 1, ids = {[4395] = true}}, -- 明夷于飞
    [314] = {type = 1, ids = {[4159] = true}}, -- 人世何欢
    [315] = {type = 3, ids = {[3800] = true, [3801] = true, [3802] = true, [3803] = true, [3804] = true, [3805] = true, [3806] = true, [3807] = true, [3808] = true, [3809] = true, [3810] = true, [3811] = true, [3812] = true, [3813] = true, [3814] = true, [3815] = true, [3816] = true, [3817] = true, [3818] = true, [3819] = true, [3820] = true, [3821] = true, [3822] = true, [3823] = true, [3824] = true, [3825] = true, [3826] = true}}, -- 桃花岛技能
    [316] = {type = 1, ids = {[4159] = true}}, -- 桃花岛武具姿态集合（永久）
    [317] = {type = 1, ids = {[4160] = true}}, -- 桃花岛武具姿态集合（10秒）
    [318] = {type = 1, ids = {[4321] = true}}, -- 桃花岛内劲BUFF集合
    [319] = {type = 3, ids = {[3800] = true, [3803] = true, [3811] = true, [3815] = true, [3818] = true, [3824] = true, [3718] = true}}, -- 桃花岛攻击回能技能
    [320] = {type = 3, ids = {[3800] = true, [3803] = true, [3811] = true, [3815] = true, [3818] = true, [3824] = true, [3718] = true}}, -- 桃花岛暴击回能技能
    [321] = {type = 3, ids = {[3801] = true, [3807] = true, [3820] = true}}, -- 桃花岛群体攻击回能
    [322] = {type = 3, ids = {[3800] = true, [3801] = true, [3803] = true, [3807] = true, [3811] = true, [3815] = true, [3818] = true, [3820] = true, [3824] = true, [3718] = true}}, -- 桃花岛翻滚后技能暴击或回能
    [323] = {type = 1, ids = {[4411] = true}}, -- 桃花岛暗伤BUFF集合
    [324] = {type = 3, ids = {[3714] = true, [3715] = true, [3716] = true, [3717] = true}}, -- 桃花岛QTE
    [325] = {type = 3, ids = {[3718] = true, [3719] = true, [3720] = true, [3721] = true}}, -- 桃花岛进阶3变身
    [326] = {type = 3, ids = {[3837] = true, [3838] = true, [3839] = true}}, -- 爆竹侠士
    [327] = {type = 3, ids = {[282] = true, [285] = true, [315] = true, [327] = true, [334] = true, [345] = true, [348] = true, [364] = true, [375] = true, [385] = true, [391] = true, [395] = true, [405] = true, [415] = true, [435] = true, [454] = true, [455] = true, [465] = true, [475] = true, [495] = true, [499] = true, [511] = true, [525] = true, [527] = true, [529] = true, [533] = true, [540] = true, [765] = true, [768] = true, [773] = true}}, -- 各门派控制技能1
    [328] = {type = 3, ids = {[775] = true, [780] = true, [784] = true, [2905] = true, [2915] = true, [2921] = true, [3435] = true, [3445] = true, [3451] = true, [3804] = true, [3805] = true, [3807] = true, [3815] = true, [3822] = true}}, -- 各门派控制技能2
    [329] = {type = 1, ids = {[4422] = true}}, -- 桃花岛反控护盾集合
    [330] = {type = 1, ids = {[150] = true, [1018] = true, [374] = true}}, -- 呆若木鸡+神佑无敌
    [331] = {type = 1, ids = {[13] = true, [122] = true, [15] = true, [17] = true, [19] = true, [21] = true, [23] = true, [14] = true, [16] = true, [136] = true}}, -- 桃花岛解控集合
    [332] = {type = 5, ids = {[136] = true}}, -- 如封似闭（封印）
    [333] = {type = 1, ids = {[4159] = true, [4395] = true, [1517] = true, [9103] = true, [9106] = true}}, -- 转门派驱散BUFF互斥ID集合2
    [334] = {type = 1, ids = {[4115] = true, [55] = true, [7163] = true, [7152] = true, [9115] = true}}, -- 非伤害类负面效果2（综合88、89、137）（涉及到的集合138和334）
    [335] = {type = 1, ids = {[13] = true, [122] = true, [17] = true, [21] = true, [14] = true, [16] = true, [136] = true, [213] = true}}, -- 星阵-受到控制，提升伤害（封穴、失明、散功、麻痹、封印）
    [336] = {type = 3, ids = {[3960] = true}}, -- 新副本-鬼谷不让用技能
    [337] = {type = 3, ids = {[275] = true, [2530] = true, [2533] = true, [2536] = true, [2539] = true, [2542] = true, [2545] = true, [525] = true, [700] = true, [701] = true}}, -- 新副本-执剑人免疫技能
    [338] = {type = 1, ids = {[132] = true, [23] = true, [269] = true}}, -- 新副本-执剑人免疫效果
    [339] = {type = 3, ids = {[535] = true}}, -- 新副本-执剑人免疫放大
    [340] = {type = 3, ids = {[3806] = true, [3807] = true, [3809] = true, [3820] = true, [3822] = true}}, -- 桃花岛共情技能 (tlbb15)
    [341] = {type = 1, ids = {[7163] = true}}, -- 硬直 (tlbb15)
    [342] = {type = 1, ids = {[11] = true, [13] = true, [122] = true, [14] = true, [15] = true, [17] = true, [18] = true, [19] = true, [21] = true, [136] = true, [7163] = true, [233] = true, [49] = true, [55] = true}}, -- 绝情谷-减少刀意点 (tlbb15)
    [343] = {type = 1, ids = {[21] = true, [14] = true}}, -- 散功+麻痹 (tlbb15)
    [344] = {type = 1, ids = {[11] = true, [13] = true, [122] = true, [14] = true, [15] = true, [17] = true, [18] = true, [19] = true, [21] = true, [136] = true, [127] = true}}, -- 绝情谷-霸体免疫 (tlbb15)
    [345] = {type = 3, ids = {[3846] = true, [3847] = true, [3851] = true}}, -- 绝情谷宁鸣不默（状态下必命中） (tlbb15)
    [346] = {type = 0, ids = {[9100] = true}}, -- 拘魂·天 (tlbb15)
    [347] = {type = 1, ids = {[9101] = true, [9113] = true}}, -- 失魂·天+失魂落魄 (tlbb15)
    [348] = {type = 0, ids = {[9093] = true}}, -- 拘魂·地 (tlbb15)
    [349] = {type = 1, ids = {[9094] = true, [9113] = true}}, -- 失魂·地+失魂落魄 (tlbb15)
    [350] = {type = 3, ids = {[4504] = true}}, -- 周年庆交互
    [351] = {type = 7, ids = {[99] = true}}, -- 骑乘(马鞍用)
    [352] = {type = 3, ids = {[424] = true, [3438] = true, [406] = true}}, -- 加血效果
    [353] = {type = 2, ids = {[173] = true}}, -- 绝情谷门派控制buff集合（硬直）
    [354] = {type = 3, ids = {[4700] = true, [4701] = true, [4702] = true, [4703] = true}}, -- 绝情谷进阶QTE
    [355] = {type = 3, ids = {[4704] = true, [4705] = true, [4706] = true, [4707] = true}}, -- 绝情谷进阶3变身
    [356] = {type = 0, ids = {}}, -- 绝情谷门派控制buff集合-减速（加刀意点）
    [357] = {type = 0, ids = {[7163] = true}}, -- 绝情谷门派控制buff集合-硬直（加刀意点）
    [358] = {type = 1, ids = {[7151] = true, [11] = true, [13] = true, [14] = true, [15] = true, [17] = true, [18] = true, [19] = true, [21] = true, [136] = true, [122] = true}}, -- 绝情谷门派控制buff集合-定身（加刀意点）
    [359] = {type = 0, ids = {[7565] = true}}, -- 绝情谷门派控制buff集合-散工（加刀意点）
    [360] = {type = 0, ids = {[7567] = true}}, -- 绝情谷门派控制buff集合-定身2（加刀意点）
    [361] = {type = 0, ids = {[7568] = true}}, -- 绝情谷门派控制buff集合-眩晕2（加刀意点）
    [362] = {type = 0, ids = {[7569] = true}}, -- 绝情谷门派控制buff集合-眩晕3（加刀意点）
    [363] = {type = 3, ids = {[4515] = true, [4516] = true, [4518] = true, [4529] = true, [4532] = true, [4533] = true, [4534] = true, [4538] = true, [4539] = true, [4545] = true}}, -- 绝情谷门派技能集合（增伤集合）
    [364] = {type = 3, ids = {[4515] = true, [4516] = true, [4517] = true, [4518] = true, [4519] = true, [4520] = true, [4521] = true, [4522] = true, [4523] = true, [4524] = true, [4525] = true, [4526] = true, [4527] = true, [4528] = true, [4529] = true, [4530] = true, [4531] = true, [4532] = true, [4533] = true, [4534] = true, [4537] = true, [4538] = true, [4539] = true, [4540] = true, [4541] = true, [4542] = true, [4543] = true, [4544] = true, [4545] = true, [4546] = true}}, -- 绝情谷技能
    [365] = {type = 3, ids = {}}, -- 空
    [366] = {type = 1, ids = {[11] = true, [13] = true, [122] = true, [14] = true, [15] = true, [17] = true, [18] = true, [19] = true, [21] = true, [136] = true, [127] = true}}, -- 绝情谷-霸体免疫
    [367] = {type = 1, ids = {[11] = true, [13] = true, [122] = true, [14] = true, [15] = true, [17] = true, [18] = true, [19] = true, [21] = true, [136] = true, [7163] = true, [233] = true, [49] = true, [55] = true}}, -- 绝情谷-减少刀意点
    [368] = {type = 1, ids = {[11] = true, [13] = true, [122] = true, [14] = true, [15] = true, [17] = true, [18] = true, [19] = true, [21] = true, [136] = true, [7163] = true, [233] = true, [49] = true, [55] = true}}, -- 绝情谷-增加刀意点
    [369] = {type = 3, ids = {[4538] = true, [4533] = true, [4534] = true}}, -- 绝情谷宁鸣不默（状态下必命中）
    [370] = {type = 3, ids = {[4730] = true, [4731] = true, [4732] = true, [4733] = true, [4734] = true}}, -- 火锅变身
    [371] = {type = 3, ids = {[4735] = true, [4736] = true}}, -- 玩具火锅标记
    [372] = {type = 3, ids = {[4747] = true, [4748] = true, [4749] = true, [4750] = true}}, -- 年画变身
    [373] = {type = 1, ids = {[21] = true, [14] = true}}, -- 散功+麻痹
    [374] = {type = 1, ids = {[1517] = true}}, -- 蓄云欲雨BUFF
    [375] = {type = 3, ids = {[4791] = true}}, -- 打地鼠变身
    [376] = {type = 0, ids = {[151] = true}}, -- 斩情诀BUFF
    [377] = {type = 3, ids = {[4792] = true, [4793] = true}}, -- 抓鬼变身
    [378] = {type = 3, ids = {[4793] = true}}, -- 抓鬼变身2
    [379] = {type = 7, ids = {[999] = true}}, -- 重楼控制效果集合
    [380] = {type = 3, ids = {[4806] = true, [4807] = true, [4808] = true}}, -- 穆桂英变身
    [381] = {type = 3, ids = {[4809] = true, [4810] = true, [4811] = true}}, -- 杨宗保变身
    [382] = {type = 3, ids = {[4821] = true, [4822] = true, [4823] = true, [4824] = true}}, -- 涿鹿演阵
    [383] = {type = 1, ids = {[13] = true, [122] = true, [17] = true, [21] = true, [14] = true, [136] = true, [7163] = true, [1212] = true, [1213] = true, [1214] = true, [1215] = true, [1216] = true, [1217] = true, [1218] = true, [1219] = true, [1220] = true, [1221] = true, [2623] = true, [3656] = true, [4115] = true, [7152] = true, [9115] = true}}, -- 宝珠触发硬控集合
    [384] = {type = 3, ids = {[4828] = true}}, -- 丢香囊
    [385] = {type = 3, ids = {[4832] = true}}, -- 浇水
    [386] = {type = 3, ids = {[4833] = true}}, -- 放下玫瑰宫灯
    [387] = {type = 3, ids = {[4830] = true, [4831] = true}}, -- 杯酒尽江湖
    [388] = {type = 1, ids = {[105] = true, [117] = true, [126] = true, [137] = true, [147] = true, [159] = true, [161] = true, [171] = true, [172] = true, [183] = true, [185] = true, [192] = true, [1515] = true, [1517] = true, [2617] = true, [3651] = true, [3653] = true, [4159] = true, [4395] = true, [9103] = true, [9106] = true}}, -- 所有门派姿态buff
    [389] = {type = 1, ids = {[106] = true, [109] = true, [128] = true, [138] = true, [141] = true, [151] = true, [7711] = true, [7798] = true, [173] = true, [193] = true, [2615] = true, [2618] = true, [4160] = true, [4341] = true, [9104] = true}}, -- 所有门派姿态下技能buff
    [390] = {type = 3, ids = {[4854] = true}}, -- 周年庆打地鼠
    [391] = {type = 1, ids = {[99] = true, [100] = true}}, -- 持棋免疫（隐身、骑乘）
    [392] = {type = 3, ids = {[21] = true, [248] = true, [496] = true, [497] = true, [514] = true, [515] = true, [2908] = true, [379] = true, [503] = true, [524] = true, [2904] = true, [3808] = true, [3806] = true, [3721] = true, [284] = true, [314] = true, [344] = true, [464] = true, [494] = true, [764] = true, [3434] = true, [4519] = true, [3807] = true, [4516] = true}}, -- 持棋禁用技能(乘骑，隐身)
    [393] = {type = 3, ids = {[23] = true, [24] = true, [25] = true, [26] = true, [27] = true, [28] = true, [29] = true, [30] = true, [31] = true, [34] = true, [110] = true, [170] = true, [988] = true, [1081] = true, [2942] = true, [3518] = true, [3836] = true, [4547] = true}}, -- 持棋禁用技能(轻功)
    [394] = {type = 0, ids = {[383] = true, [382] = true}}, -- 珍兽附身
    [395] = {type = 1, ids = {[11] = true, [13] = true, [14] = true, [15] = true, [17] = true, [18] = true, [21] = true, [22] = true, [136] = true, [7163] = true, [49] = true, [55] = true, [233] = true, [1212] = true, [1213] = true, [1214] = true, [1215] = true, [1216] = true, [1217] = true, [1218] = true, [1219] = true, [1220] = true, [1221] = true, [3656] = true, [2623] = true, [4115] = true, [7152] = true, [382] = true, [9115] = true, [0] = true}}, -- 珍兽受控集合
    [396] = {type = 3, ids = {[491] = true, [493] = true, [501] = true, [505] = true, [507] = true, [508] = true, [511] = true, [517] = true}}, -- 天山单体伤害技能
    [397] = {type = 0, ids = {[3690] = true, [3691] = true, [3693] = true, [3694] = true, [3695] = true, [3697] = true}}, -- 鬼谷星阵增益状态
    [398] = {type = 3, ids = {[4972] = true, [4973] = true, [4974] = true}}, -- 雪灵变身
    [399] = {type = 3, ids = {[4970] = true}}, -- 堆雪人变身
    [400] = {type = 3, ids = {[0] = true, [281] = true, [311] = true, [341] = true, [371] = true, [401] = true, [431] = true, [461] = true, [491] = true, [521] = true, [760] = true, [2900] = true, [3430] = true, [3800] = true, [4515] = true}}, -- 怒火连斩（肉鸽版）
    [401] = {type = 3, ids = {[4976] = true}}, -- 吃金币变身
    [402] = {type = 3, ids = {[5023] = true}}, -- 剑意长袭
    [403] = {type = 3, ids = {[5024] = true}}, -- 剑意迅攻
    [404] = {type = 3, ids = {[364] = true, [379] = true, [503] = true, [524] = true, [785] = true, [2543] = true, [2904] = true, [3806] = true, [3807] = true, [3808] = true, [4516] = true, [4523] = true, [4524] = true, [4544] = true, [4626] = true, [5826] = true, [5829] = true, [5836] = true, [5838] = true, [5839] = true, [5842] = true, [5844] = true, [5847] = true}}, -- 位移技能（瞬移+冲锋）
    [405] = {type = 1, ids = {[7163] = true}}, -- 硬直
    [406] = {type = 3, ids = {[4980] = true}}, -- 七夕预热变身
    [407] = {type = 3, ids = {[4995] = true, [4996] = true, [4997] = true}}, -- 七夕打卡变身1
    [408] = {type = 3, ids = {[4998] = true}}, -- 七夕打卡变身2
    [409] = {type = 3, ids = {[5274] = true, [5275] = true}}, -- 红阵营变身
    [410] = {type = 3, ids = {[5276] = true, [5277] = true}}, -- 蓝阵营变身
    [411] = {type = 3, ids = {[5278] = true, [5279] = true}}, -- 绿阵营变身
    [412] = {type = 0, ids = {[9100] = true}}, -- 拘魂·天
    [413] = {type = 1, ids = {[9101] = true, [9113] = true}}, -- 失魂·天+失魂落魄
    [414] = {type = 0, ids = {[9093] = true}}, -- 拘魂·地
    [415] = {type = 1, ids = {[9094] = true, [9113] = true}}, -- 失魂·地+失魂落魄
    [416] = {type = 0, ids = {[9098] = true}}, -- 拘魂·命
    [417] = {type = 1, ids = {[9099] = true, [9113] = true}}, -- 失魂·命+失魂落魄
    [418] = {type = 0, ids = {[9114] = true}}, -- 丧魂落魄
    [419] = {type = 0, ids = {[9113] = true}}, -- 丧魂
    [420] = {type = 1, ids = {[9101] = true, [9094] = true, [9099] = true}}, -- 失魂
    [421] = {type = 1, ids = {[9103] = true}}, -- 防具姿态
    [422] = {type = 1, ids = {[9106] = true}}, -- 武具姿态
    [423] = {type = 1, ids = {[9100] = true, [9093] = true, [9098] = true}}, -- 拘魂
    [424] = {type = 3, ids = {[4691] = true, [4692] = true, [4693] = true, [4694] = true}}, -- 恶人谷进阶QTE
    [425] = {type = 3, ids = {[4695] = true, [4696] = true, [4697] = true, [4698] = true}}, -- 恶人谷进阶3变身
    [426] = {type = 0, ids = {[178] = true}}, -- 移花接木状态
    [427] = {type = 1, ids = {[9101] = true, [9094] = true, [9099] = true, [9113] = true}}, -- 失魂+丧魂
    [428] = {type = 3, ids = {[5362] = true, [5363] = true, [5364] = true}}, -- 新门派预热变身
    [429] = {type = 3, ids = {[5384] = true}}, -- 新门派稳活变身
    [430] = {type = 3, ids = {[5437] = true, [5438] = true}}, -- 怒火连斩吃鸡版
    [431] = {type = 3, ids = {[5500] = true, [5501] = true}}, -- 含沙射影吃鸡版
    [432] = {type = 3, ids = {[5514] = true, [5515] = true}}, -- 秦皇东遣吃鸡版
    [433] = {type = 3, ids = {[5430] = true, [5431] = true, [5432] = true, [5433] = true, [5587] = true, [5435] = true, [5436] = true, [5541] = true, [5572] = true}}, -- 少林基础技能吃鸡版
    [434] = {type = 3, ids = {[5437] = true, [5438] = true, [5439] = true, [5440] = true, [5588] = true, [5442] = true, [5443] = true, [5542] = true, [5573] = true}}, -- 明教基础技能吃鸡版
    [435] = {type = 3, ids = {[5444] = true, [5445] = true, [5446] = true, [5447] = true, [5589] = true, [5449] = true, [5450] = true, [5543] = true, [5574] = true}}, -- 丐帮基础技能吃鸡版
    [436] = {type = 3, ids = {[5451] = true, [5452] = true, [5453] = true, [5454] = true, [5590] = true, [5456] = true, [5457] = true, [5544] = true, [5575] = true}}, -- 武当基础技能吃鸡版
    [437] = {type = 3, ids = {[5458] = true, [5459] = true, [5460] = true, [5461] = true, [5591] = true, [5463] = true, [5464] = true, [5545] = true, [5576] = true}}, -- 峨嵋基础技能吃鸡版
    [438] = {type = 3, ids = {[5465] = true, [5466] = true, [5467] = true, [5468] = true, [5592] = true, [5470] = true, [5471] = true, [5546] = true, [5577] = true}}, -- 星宿基础技能吃鸡版
    [439] = {type = 3, ids = {[5472] = true, [5473] = true, [5474] = true, [5475] = true, [5476] = true, [5477] = true, [5478] = true, [5547] = true, [5578] = true}}, -- 天龙基础技能吃鸡版
    [440] = {type = 3, ids = {[5479] = true, [5480] = true, [5481] = true, [5482] = true, [5593] = true, [5484] = true, [5485] = true, [5548] = true, [5579] = true}}, -- 天山基础技能吃鸡版
    [441] = {type = 3, ids = {[5486] = true, [5487] = true, [5488] = true, [5489] = true, [5594] = true, [5491] = true, [5492] = true, [5549] = true, [5580] = true}}, -- 逍遥基础技能吃鸡版
    [442] = {type = 3, ids = {[5493] = true, [5494] = true, [5495] = true, [5496] = true, [5595] = true, [5498] = true, [5499] = true, [5550] = true, [5581] = true}}, -- 慕容基础技能吃鸡版
    [443] = {type = 3, ids = {[5500] = true, [5501] = true, [5502] = true, [5503] = true, [5596] = true, [5505] = true, [5506] = true, [5551] = true, [5582] = true}}, -- 唐门基础技能吃鸡版
    [444] = {type = 3, ids = {[5507] = true, [5508] = true, [5509] = true, [5510] = true, [5597] = true, [5512] = true, [5513] = true, [5552] = true, [5583] = true}}, -- 鬼谷基础技能吃鸡版
    [445] = {type = 3, ids = {[5514] = true, [5515] = true, [5516] = true, [5517] = true, [5518] = true, [5519] = true, [5520] = true, [5553] = true, [5584] = true}}, -- 桃花岛基础技能吃鸡版
    [446] = {type = 3, ids = {[5521] = true, [5522] = true, [5523] = true, [5524] = true, [5525] = true, [5526] = true, [5527] = true, [5554] = true, [5585] = true}}, -- 绝情谷基础技能吃鸡版
    [447] = {type = 3, ids = {[5528] = true, [5529] = true, [5530] = true, [5531] = true, [5598] = true, [5533] = true, [5534] = true, [5555] = true, [5586] = true}}, -- 恶人谷基础技能吃鸡版
    [448] = {type = 1, ids = {[7485] = true, [7487] = true, [7491] = true}}, -- 失魂吃鸡版
    [449] = {type = 3, ids = {[5392] = true, [5389] = true, [5390] = true}}, -- 新门派预热恶人谷变身
    [450] = {type = 3, ids = {[4622] = true, [4623] = true, [4624] = true, [4625] = true, [4626] = true, [4627] = true, [4628] = true, [4629] = true, [4630] = true, [4631] = true, [4632] = true, [4633] = true, [4634] = true, [4635] = true, [4636] = true, [4637] = true, [4638] = true, [4639] = true, [4640] = true, [4641] = true, [4642] = true, [4643] = true, [4644] = true, [4645] = true, [4646] = true, [4647] = true}}, -- 恶人谷技能
    [451] = {type = 3, ids = {[5600] = true, [5601] = true, [5602] = true, [5603] = true}}, -- 打雪人变身
    [452] = {type = 3, ids = {[5631] = true, [5702] = true}}, -- 冰雪节答题企鹅变身
    [453] = {type = 3, ids = {[5652] = true, [5656] = true, [5655] = true, [5653] = true}}, -- 冰雪PVP1级雪人变身技能集合
    [454] = {type = 2, ids = {[232] = true}}, -- 冰雪PVP变身buff集合
    [455] = {type = 3, ids = {[5925] = true, [5930] = true, [5933] = true, [5634] = true}}, -- 变身1级
    [456] = {type = 3, ids = {[5926] = true, [5930] = true, [5933] = true, [5700] = true, [5634] = true}}, -- 变身2级
    [457] = {type = 3, ids = {[5927] = true, [5931] = true, [5934] = true, [5700] = true, [5959] = true, [5634] = true}}, -- 变身3级
    [458] = {type = 3, ids = {[5928] = true, [5931] = true, [5934] = true, [5701] = true, [5960] = true, [5693] = true, [5634] = true}}, -- 变身4级
    [459] = {type = 3, ids = {[5929] = true, [5932] = true, [5934] = true, [5701] = true, [5960] = true, [5693] = true, [5634] = true}}, -- 变身5级
    [460] = {type = 2, ids = {[232] = true, [233] = true, [234] = true, [235] = true}}, -- 允许对雪人生效的效果集合1
    [461] = {type = 3, ids = {[5632] = true, [5703] = true}}, -- 冰雪节答题水豚变身
    [462] = {type = 3, ids = {[5633] = true, [5704] = true}}, -- 冰雪节答题小猫变身
    [463] = {type = 3, ids = {[5695] = true, [5694] = true}}, -- 冰雪节春节泡温泉变身
    [464] = {type = 3, ids = {[5698] = true, [5696] = true, [5699] = true}}, -- 冰雪节元旦泡温泉变身
    [465] = {type = 3, ids = {[5670] = true}}, -- 冰雪节聚人采集技能
    [466] = {type = 3, ids = {[521] = true}}, -- 桃花阵技能
    [467] = {type = 6, ids = {[5] = true}}, -- 步步生花1级
    [468] = {type = 6, ids = {[6] = true}}, -- 步步生花2级
    [469] = {type = 6, ids = {[7] = true}}, -- 步步生花3级
    [470] = {type = 6, ids = {[8] = true}}, -- 步步生花4级
    [471] = {type = 1, ids = {[9392] = true, [9394] = true, [9395] = true, [9396] = true, [9397] = true, [9398] = true, [9418] = true, [9419] = true, [9420] = true, [9421] = true, [9424] = true, [9425] = true, [9428] = true, [9434] = true, [9436] = true}}, -- 允许对普通雪人生效的效果集合2
    [472] = {type = 7, ids = {[536] = true}}, -- 洛神图灼烧
    [473] = {type = 3, ids = {[5649] = true, [5650] = true}}, -- 打雪人变身
    [474] = {type = 1, ids = {[9423] = true}}, -- 雪人付费外观
    [475] = {type = 3, ids = {[5652] = true, [5656] = true, [5655] = true, [5653] = true, [5654] = true}}, -- 冰雪PVP激素雪人变身技能集合
    [476] = {type = 3, ids = {[5282] = true, [5657] = true, [5658] = true, [5659] = true, [5660] = true}}, -- 冰雪PVP附加技能
    [477] = {type = 1, ids = {[9392] = true, [9394] = true, [9395] = true, [9396] = true, [9397] = true, [9398] = true, [9418] = true, [9424] = true, [9425] = true, [9428] = true, [9434] = true, [9436] = true}}, -- 允许对激素雪人生效的效果集合2
    [478] = {type = 3, ids = {[5652] = true, [5656] = true, [5655] = true, [5653] = true}}, -- 冰雪PVP2级雪人变身技能集合
    [479] = {type = 3, ids = {[5652] = true, [5656] = true, [5655] = true, [5653] = true}}, -- 冰雪PVP3级雪人变身技能集合
    [480] = {type = 3, ids = {[5652] = true, [5656] = true, [5655] = true, [5653] = true}}, -- 冰雪PVP4级雪人变身技能集合
    [481] = {type = 3, ids = {[5652] = true, [5656] = true, [5655] = true, [5653] = true}}, -- 冰雪PVP5级雪人变身技能集合
    [482] = {type = 3, ids = {[5652] = true, [5656] = true, [5655] = true, [5653] = true}}, -- 冰雪PVP6级雪人变身技能集合
    [483] = {type = 3, ids = {[5652] = true, [5656] = true, [5655] = true, [5653] = true}}, -- 冰雪PVP7级雪人变身技能集合
    [484] = {type = 3, ids = {[5652] = true, [5656] = true, [5655] = true, [5653] = true}}, -- 冰雪PVP8级雪人变身技能集合
    [485] = {type = 3, ids = {[5652] = true, [5656] = true, [5655] = true, [5653] = true}}, -- 冰雪PVP9级雪人变身技能集合
    [486] = {type = 3, ids = {[5652] = true, [5656] = true, [5655] = true, [5653] = true}}, -- 冰雪PVP10级雪人变身技能集合
    [487] = {type = 1, ids = {[13] = true, [14] = true, [15] = true, [16] = true, [17] = true, [19] = true, [21] = true, [23] = true, [122] = true, [136] = true, [7163] = true}}, -- 步步生花免控
    [488] = {type = 3, ids = {[5629] = true}}, -- 冰雪节雪球合成变身
    [489] = {type = 0, ids = {[173] = true}}, -- 金玉满堂
    [490] = {type = 0, ids = {[935] = true}}, -- 少商剑二式飞剑
    [491] = {type = 0, ids = {[936] = true}}, -- 少冲剑二式飞剑
    [492] = {type = 0, ids = {[937] = true}}, -- 关冲剑二式飞剑
    [493] = {type = 0, ids = {[938] = true}}, -- 少泽剑二式飞剑
    [494] = {type = 0, ids = {[939] = true}}, -- 商阳剑二式飞剑
    [495] = {type = 0, ids = {[940] = true}}, -- 中冲剑二式飞剑
    [496] = {type = 1, ids = {[930] = true}}, -- 少冲剑二式封技能
    [497] = {type = 0, ids = {[933] = true}}, -- 商阳剑二式气息紊乱标记
    [498] = {type = 3, ids = {[285] = true, [315] = true, [345] = true, [375] = true, [405] = true, [435] = true, [465] = true, [495] = true, [525] = true, [765] = true, [2905] = true, [3435] = true, [3805] = true, [4520] = true, [4627] = true}}, -- 商阳剑二式气息紊乱技能
    [499] = {type = 0, ids = {[2631] = true}}, -- 回天术九阳状态
    [500] = {type = 3, ids = {[401] = true, [403] = true, [404] = true, [415] = true, [418] = true, [421] = true, [426] = true, [427] = true, [832] = true, [833] = true, [834] = true}}, -- 神爪九阴叠层技能
    [501] = {type = 1, ids = {[13] = true, [14] = true, [15] = true, [17] = true, [18] = true, [21] = true, [127] = true, [136] = true, [7163] = true, [233] = true, [49] = true, [55] = true, [382] = true, [122] = true}}, -- 重楼带控制条件集合
    [502] = {type = 1, ids = {[233] = true, [49] = true, [55] = true}}, -- 真重楼控制集合
    [503] = {type = 1, ids = {[13] = true, [14] = true, [15] = true, [17] = true, [18] = true, [21] = true, [127] = true, [136] = true, [7163] = true, [382] = true, [122] = true}}, -- 重楼带控制条件集合2
    [504] = {type = 3, ids = {[5810] = true, [5811] = true}}, -- 打卡变身
    [505] = {type = 3, ids = {[5642] = true, [5656] = true, [5655] = true, [5653] = true}}, -- 冰雪PVP限时武器变身技能集合
    [506] = {type = 3, ids = {[311] = true, [312] = true, [319] = true, [321] = true, [325] = true, [328] = true, [336] = true}}, -- 明教攻击技能（除炎龙无双）
    [507] = {type = 3, ids = {[821] = true, [822] = true, [823] = true, [824] = true, [825] = true, [826] = true}}, -- 六脉神剑刃影技能
    [508] = {type = 7, ids = {[2] = true}}, -- 免疫放大效果
    [509] = {type = 3, ids = {[4462] = true, [4463] = true, [4464] = true}}, -- 唐门神枢战甲技能
    [510] = {type = 1, ids = {[11] = true, [13] = true, [14] = true, [15] = true, [17] = true, [19] = true, [21] = true, [122] = true, [136] = true, [7163] = true}}, -- 唐门神枢战甲、千机变造物免控
    [511] = {type = 0, ids = {[8919] = true}}, -- 唐门神机幻影蒙面状态禁用
    [512] = {type = 3, ids = {[0] = true, [281] = true, [311] = true, [341] = true, [371] = true, [401] = true, [431] = true, [461] = true, [491] = true, [521] = true, [760] = true, [2900] = true, [3430] = true, [3800] = true, [4515] = true, [4622] = true, [283] = true, [313] = true, [343] = true, [377] = true, [403] = true, [433] = true, [463] = true, [493] = true, [523] = true, [763] = true, [2903] = true, [3433] = true, [3803] = true, [4518] = true}}, -- 怒火连斩偷师版1
    [513] = {type = 3, ids = {[4625] = true}}, -- 怒火连斩偷师版2
    [514] = {type = 3, ids = {[5825] = true, [5826] = true, [5832] = true, [5839] = true, [5844] = true, [5851] = true, [5835] = true, [5837] = true}}, -- 偷师伤害类技能
    [515] = {type = 10, ids = {[58569] = true, [58641] = true, [58642] = true, [58643] = true, [58644] = true, [58645] = true}}, -- 偷师移花接木伤害buff
    [516] = {type = 3, ids = {[5033] = true, [5034] = true}}, -- 抓鬼人变身技能
    [517] = {type = 3, ids = {[5035] = true, [5036] = true, [5037] = true, [5038] = true}}, -- 鬼变身技能
    [518] = {type = 3, ids = {[6000] = true, [6001] = true}}, -- 风云搜打撤开锁
    [519] = {type = 3, ids = {[5949] = true, [5950] = true, [5951] = true}}, -- 风云打卡变身
    [520] = {type = 1, ids = {[10100] = true, [10124] = true}}, -- 藏品排行榜buff集合
    [521] = {type = 3, ids = {[288] = true, [769] = true}}, -- 观战禁用技能集合
    [522] = {type = 3, ids = {[712] = true, [713] = true, [720] = true, [721] = true, [718] = true, [719] = true, [730] = true, [731] = true, [716] = true, [717] = true, [714] = true, [715] = true}}, -- 废弃珍兽技能集合
    [523] = {type = 3, ids = {[6056] = true, [6057] = true, [6058] = true}}, -- 七夕预热变身2
    [524] = {type = 3, ids = {[6077] = true}}, -- 七夕pve变身
    [525] = {type = 3, ids = {[6040] = true, [6041] = true}}, -- 武神坛倒计时技能
    [530] = {type = 3, ids = {[839] = true, [840] = true, [841] = true, [838] = true}}, -- 蝎子1技能
    [531] = {type = 3, ids = {[842] = true, [843] = true, [844] = true, [838] = true}}, -- 蝎子2技能
    [532] = {type = 3, ids = {[845] = true, [846] = true, [847] = true, [838] = true}}, -- 蝎子3技能
    [533] = {type = 3, ids = {[431] = true}}, -- 星宿普攻
    [534] = {type = 3, ids = {[281] = true, [311] = true, [341] = true, [371] = true, [401] = true, [431] = true, [461] = true, [491] = true, [521] = true, [760] = true, [2900] = true, [3430] = true, [3800] = true, [4515] = true, [4622] = true, [4742] = true, [4743] = true, [4744] = true, [4745] = true, [4746] = true}}, -- 废弃集合
    [535] = {type = 1, ids = {[13] = true, [122] = true, [15] = true, [17] = true, [19] = true, [21] = true, [14] = true, [136] = true}}, -- 星宿解控集合1-控制
    [536] = {type = 1, ids = {[24] = true, [25] = true, [26] = true, [27] = true, [28] = true, [29] = true, [30] = true, [31] = true, [112] = true, [113] = true, [139] = true, [1516] = true, [1732] = true, [8500] = true, [8517] = true, [8535] = true, [8590] = true, [8617] = true}}, -- 星宿解控集合2-破绽
    [537] = {type = 1, ids = {[32] = true, [33] = true, [34] = true, [35] = true, [36] = true, [37] = true, [1514] = true, [8605] = true, [9102] = true}}, -- 星宿解控集合3-虚弱
    [538] = {type = 1, ids = {[2574] = true}}, -- 星宿蝎子免控
}
