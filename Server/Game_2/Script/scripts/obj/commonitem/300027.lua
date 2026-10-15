local gbk = require "wire_charset"
local class = require "class"
local define = require "define"
local script_base = require "script_base"
local common_item = class("common_item", script_base)

local g_petList = {}
g_petList[30309002] = {type=1, dataId=3009, level=1}	--çå…½è›‹ï¼šå…”å­
g_petList[30309003] = {type=1, dataId=3019, level=1}	--çå…½è›‹ï¼šç‡•å­
g_petList[30309004] = {type=1, dataId=3029, level=1}	--çå…½è›‹ï¼šä¹Œé¾Ÿ
g_petList[30309005] = {type=1, dataId=3039, level=1}	--çå…½è›‹ï¼šç‹?
g_petList[30309006] = {type=1, dataId=3049, level=1}	--çå…½è›‹ï¼šåˆºçŒ¬
g_petList[30309007] = {type=1, dataId=3059, level=1}	--çå…½è›‹ï¼šçŒ´å­
g_petList[30309008] = {type=1, dataId=3069, level=1}	--çå…½è›‹ï¼šæ¾é¼ 
g_petList[30309009] = {type=1, dataId=3079, level=1}	--çå…½è›‹ï¼šæµ£ç†Š
g_petList[30309010] = {type=1, dataId=3089, level=1}	--çå…½è›‹ï¼šé¹¦é¹‰
g_petList[30309011] = {type=1, dataId=3099, level=1}	--çå…½è›‹ï¼šèœ¥èœ´
g_petList[30309012] = {type=1, dataId=3109, level=1}	--çå…½è›‹ï¼šè™è 
g_petList[30309013] = {type=1, dataId=3119, level=1}	--çå…½è›‹ï¼šå¤§èž³èž?
g_petList[30309014] = {type=1, dataId=3129, level=1}	--çå…½è›‹ï¼šé³„é±¼
g_petList[30309015] = {type=1, dataId=3139, level=1}	--çå…½è›‹ï¼šçŒ?å¤´é¹°
g_petList[30309016] = {type=1, dataId=3149, level=1}	--çå…½è›‹ï¼šç?
g_petList[30309017] = {type=1, dataId=3159, level=1}	--çå…½è›‹ï¼šè€è™Ž
g_petList[30309018] = {type=1, dataId=3169, level=1}	--çå…½è›‹ï¼šé‡ŽçŒª
g_petList[30309019] = {type=1, dataId=3179, level=1}	--çå…½è›‹ï¼šå†°èš•
g_petList[30309020] = {type=1, dataId=3189, level=1}	--çå…½è›‹ï¼šé¹?
g_petList[30309021] = {type=1, dataId=3199, level=1}	--çå…½è›‹ï¼šé¸µé¸Ÿ
g_petList[30309022] = {type=1, dataId=3209, level=1}	--çå…½è›‹ï¼šè±¹å­
g_petList[30309023] = {type=1, dataId=3219, level=1}	--çå…½è›‹ï¼šåŒ—æžç†?
g_petList[30309024] = {type=1, dataId=3229, level=1}	--çå…½è›‹ï¼šå­”é›€
g_petList[30309025] = {type=1, dataId=3239, level=1}	--çå…½è›‹ï¼šå‰‘é½¿è™?
g_petList[30309026] = {type=1, dataId=3249, level=1}	--çå…½è›‹ï¼šå¤§çŒ©çŒ?
g_petList[30309027] = {type=1, dataId=3259, level=1}	--çå…½è›‹ï¼šçŠ?ç‰?
g_petList[30309028] = {type=1, dataId=3269, level=1}	--çå…½è›‹ï¼šé›?è²?
g_petList[30309029] = {type=1, dataId=3279, level=1}	--çå…½è›‹ï¼šå‰‘é¾™
g_petList[30309030] = {type=1, dataId=3289, level=1}	--çå…½è›‹ï¼šé§?é©?
g_petList[30309031] = {type=1, dataId=3299, level=1}	--çå…½è›‹ï¼šé»„é¸Ÿ
g_petList[30309032] = {type=1, dataId=3309, level=1}	--çå…½è›‹ï¼šå¹´å…½
g_petList[30309033] = {type=1, dataId=3319, level=1}	--çå…½è›‹ï¼šé¾™é¾Ÿ
g_petList[30309034] = {type=1, dataId=3329, level=1}	--çå…½è›‹ï¼šè‹±æ‹›
g_petList[30309035] = {type=1, dataId=3339, level=1}	--çå…½è›‹ï¼šéº’éºŸ
g_petList[30309036] = {type=1, dataId=3349, level=1}	--çå…½è›‹ï¼šè›Ÿé¾™
g_petList[30309037] = {type=1, dataId=3359, level=1}	--çå…½è›‹ï¼šæŸ´çŒ«
g_petList[30309038] = {type=1, dataId=3369, level=1}	--çå…½è›‹ï¼šé¸?
g_petList[30309039] = {type=1, dataId=3379, level=1}	--çå…½è›‹ï¼šé¸?å­?
g_petList[30309040] = {type=1, dataId=3389, level=1}	--çå…½è›‹ï¼šå±±ç¾Š
g_petList[30309041] = {type=1, dataId=3399, level=1}	--çå…½è›‹ï¼šæ¯›é©´
g_petList[30309042] = {type=1, dataId=3409, level=1}	--çå…½è›‹ï¼šé¹?
g_petList[30309043] = {type=1, dataId=3419, level=1}	--çå…½è›‹ï¼šéœ¸çŽ‹é¾?
g_petList[30309044] = {type=1, dataId=3429, level=1}	--çå…½è›‹ï¼šä¼é¹…
g_petList[30309045] = {type=1, dataId=3439, level=1}	--çå…½è›‹ï¼šè¢‹é¼ 
g_petList[30309046] = {type=1, dataId=3449, level=1}	--çå…½è›‹ï¼šé¸?å˜´å…½
g_petList[30309047] = {type=1, dataId=3459, level=1}	--çå…½è›‹ï¼šçŒ?
g_petList[30309048] = {type=1, dataId=3469, level=1}	--çå…½è›‹ï¼šé’è›™
g_petList[30309049] = {type=1, dataId=3479, level=1}	--çå…½è›‹ï¼šå°è±¡
g_petList[30309050] = {type=1, dataId=3489, level=1}	--çå…½è›‹ï¼šé›?ç‹?
g_petList[30309051] = {type=1, dataId=3499, level=1}	--çå…½è›‹ï¼šç‹?
g_petList[30505108] = {type=0, dataId=3459, level=1}	--çå…½è›‹ï¼šçŒ?
g_petList[30505109] = {type=1, dataId=6069, level=1}	--çå…½è›‹ï¼šå¢¨é•œçŒ?
g_petList[30505110] = {type=1, dataId=6079, level=1}	--çå…½è›‹ï¼šæµè?ŒçŒ«
g_petList[30505111] = {type=1, dataId=6089, level=1}	--çå…½è›‹ï¼šæ—¶å°šçŒ?
g_petList[30505112] = {type=1, dataId=6099, level=1}	--çå…½è›‹ï¼šå¶åƒçŒ?
g_petList[30505113] = {type=1, dataId=6109, level=1}	--çå…½è›‹ï¼šå† å†›çŒ?
g_petList[30505121] = {type=1, dataId=6569, level=1}	--ä¼é¹…è›?
g_petList[30505126] = {type=1, dataId=6649, level=1}	--çŽ‰å…”é“ƒé“›
g_petList[30505127] = {type=1, dataId=6659, level=1}	--çš“æœˆçŽ‰å…”é“ƒé“›
g_petList[30505128] = {type=1, dataId=6669, level=1}	--èŸ¾å??çŽ‰å…”é“ƒé“›
g_petList[30505129] = {type=1, dataId=6679, level=1}	--å«¦å¨¥çŽ‰å…”é“ƒé“›
g_petList[30505237] = {type=1, dataId=6639, level=1}	--çŽ„ç¿¼å…?
g_petList[30505238] = {type=1, dataId=6619, level=1}	--ç?é¬ƒé¼ 
g_petList[30309052] = {type=2, dataIds={}, level=1}	--ç¥žç¬›ï¼šçå¥‡é¼ (æŒ‰ç…§çŽ©å?¶ç­‰çº§åŒºé—´ç»™ä¸åŒçš„å® ç‰?)
g_petList[30309052].dataIds[1] = {dataId=8709,minHumanLevel=1,maxHumanLevel=44}
g_petList[30309052].dataIds[2] = {dataId=8719,minHumanLevel=45,maxHumanLevel=54}
g_petList[30309052].dataIds[3] = {dataId=8729,minHumanLevel=55,maxHumanLevel=64}
g_petList[30309052].dataIds[4] = {dataId=8679,minHumanLevel=65,maxHumanLevel=255}
g_petList[30309053] = {type=1, dataId=8689, level=1}	--éº’éºŸè›?
g_petList[30505154] = {type=1, dataId=8699, level=1}	--çå…½è›‹ï¼šå‰ç¥¥çŒ?
g_petList[30505164] = {type=2, dataIds={}, level=1}	--æµ·ç›—é¼?
g_petList[30505164].dataIds[1] = {dataId=8359,minHumanLevel=45,maxHumanLevel=54}
g_petList[30505164].dataIds[2] = {dataId=8369,minHumanLevel=55,maxHumanLevel=64}
g_petList[30505164].dataIds[3] = {dataId=8379,minHumanLevel=65,maxHumanLevel=255}
g_petList[30505179] = {type=1, dataId=7559, level=1}	--é¸?å˜´å…½é¡¹åœˆ
g_petList[30505180] = {type=1, dataId=3399, level=1}	--5çº§æ¯›é©´é“ƒé“?
g_petList[30505181] = {type=1, dataId=8969, level=1}	--45çº§æ¯›é©´é“ƒé“?
g_petList[30505182] = {type=1, dataId=8979, level=1}	--55çº§æ¯›é©´é“ƒé“?
g_petList[30505183] = {type=1, dataId=8989, level=1}	--65çº§æ¯›é©´é“ƒé“?
g_petList[30309600] = {type=1, dataId=7649, level=1} --çå…½è›‹ï¼šé¾™çŒ« 5
g_petList[30309601] = {type=1, dataId=7659, level=1} --çå…½è›‹ï¼šé¾™çŒ« 45
g_petList[30309602] = {type=1, dataId=7669, level=1} --çå…½è›‹ï¼šé¾™çŒ« 55
g_petList[30309603] = {type=1, dataId=7679, level=1} --çå…½è›‹ï¼šé¾™çŒ« 65
g_petList[30309604] = {type=1, dataId=7689, level=1} --çå…½è›‹ï¼šé¾™çŒ« 75
g_petList[30309605] = {type=1, dataId=7699, level=1} --çå…½è›‹ï¼šé¾™çŒ« 85
g_petList[30309606] = {type=1, dataId=7709, level=1} --çå…½è›‹ï¼šé¾™çŒ« 95
g_petList[30309607] = {type=1, dataId=7789, level=1} --çå…½è›‹ï¼šç†ŠçŒ« 5
g_petList[30309608] = {type=1, dataId=7799, level=1} --çå…½è›‹ï¼šç†ŠçŒ« 45
g_petList[30309609] = {type=1, dataId=7809, level=1} --çå…½è›‹ï¼šç†ŠçŒ« 55
g_petList[30309610] = {type=1, dataId=7819, level=1} --çå…½è›‹ï¼šç†ŠçŒ« 65
g_petList[30309611] = {type=1, dataId=7829, level=1} --çå…½è›‹ï¼šç†ŠçŒ« 75
g_petList[30309612] = {type=1, dataId=7839, level=1} --çå…½è›‹ï¼šç†ŠçŒ« 85
g_petList[30309613] = {type=1, dataId=7849, level=1} --çå…½è›‹ï¼šç†ŠçŒ« 95
g_petList[30309614] = {type=1, dataId=7929, level=1} --çå…½è›‹ï¼šè´è¶ 5
g_petList[30309615] = {type=1, dataId=7939, level=1} --çå…½è›‹ï¼šè´è¶ 45
g_petList[30309616] = {type=1, dataId=7949, level=1} --çå…½è›‹ï¼šè´è¶ 55
g_petList[30309617] = {type=1, dataId=7959, level=1} --çå…½è›‹ï¼šè´è¶ 65
g_petList[30309618] = {type=1, dataId=7969, level=1} --çå…½è›‹ï¼šè´è¶ 75
g_petList[30309619] = {type=1, dataId=7979, level=1} --çå…½è›‹ï¼šè´è¶ 85
g_petList[30309620] = {type=1, dataId=7989, level=1} --çå…½è›‹ï¼šè´è¶ 95
g_petList[30309621] = {type=1, dataId=7999, level=1} --çå…½è›‹ï¼šèœ—ç‰› 5
g_petList[30309622] = {type=1, dataId=8009, level=1} --çå…½è›‹ï¼šèœ—ç‰› 45
g_petList[30309623] = {type=1, dataId=8019, level=1} --çå…½è›‹ï¼šèœ—ç‰› 55
g_petList[30309624] = {type=1, dataId=8029, level=1} --çå…½è›‹ï¼šèœ—ç‰› 65
g_petList[30309625] = {type=1, dataId=8039, level=1} --çå…½è›‹ï¼šèœ—ç‰› 75
g_petList[30309626] = {type=1, dataId=8049, level=1} --çå…½è›‹ï¼šèœ—ç‰› 85
g_petList[30309627] = {type=1, dataId=8059, level=1} --çå…½è›‹ï¼šèœ—ç‰› 95
g_petList[30309628] = {type=1, dataId=8069, level=1} --çå…½è›‹ï¼šèŽå­ 5
g_petList[30309629] = {type=1, dataId=8079, level=1} --çå…½è›‹ï¼šèŽå­ 45
g_petList[30309630] = {type=1, dataId=8089, level=1} --çå…½è›‹ï¼šèŽå­ 55
g_petList[30309631] = {type=1, dataId=8099, level=1} --çå…½è›‹ï¼šèŽå­ 65
g_petList[30309632] = {type=1, dataId=8109, level=1} --çå…½è›‹ï¼šèŽå­ 75
g_petList[30309633] = {type=1, dataId=8119, level=1} --çå…½è›‹ï¼šèŽå­ 85
g_petList[30309634] = {type=1, dataId=8129, level=1} --çå…½è›‹ï¼šèŽå­ 95
g_petList[30309635] = {type=1, dataId=7859, level=1} --çå…½è›‹ï¼šèžƒèŸ¹ 5
g_petList[30309636] = {type=1, dataId=7869, level=1} --çå…½è›‹ï¼šèžƒèŸ¹ 45
g_petList[30309637] = {type=1, dataId=7879, level=1} --çå…½è›‹ï¼šèžƒèŸ¹ 55
g_petList[30309638] = {type=1, dataId=7889, level=1} --çå…½è›‹ï¼šèžƒèŸ¹ 65
g_petList[30309639] = {type=1, dataId=7899, level=1} --çå…½è›‹ï¼šèžƒèŸ¹ 75
g_petList[30309640] = {type=1, dataId=7909, level=1} --çå…½è›‹ï¼šèžƒèŸ¹ 85
g_petList[30309641] = {type=1, dataId=7919, level=1} --çå…½è›‹ï¼šèžƒèŸ¹ 95
g_petList[30309642] = {type=1, dataId=7719, level=1} --çå…½è›‹ï¼šçŠ?é¸? 5
g_petList[30309643] = {type=1, dataId=7729, level=1} --çå…½è›‹ï¼šçŠ?é¸? 45
g_petList[30309644] = {type=1, dataId=7739, level=1} --çå…½è›‹ï¼šçŠ?é¸? 55
g_petList[30309645] = {type=1, dataId=7749, level=1} --çå…½è›‹ï¼šçŠ?é¸? 65
g_petList[30309646] = {type=1, dataId=7759, level=1} --çå…½è›‹ï¼šçŠ?é¸? 75
g_petList[30309647] = {type=1, dataId=7769, level=1} --çå…½è›‹ï¼šçŠ?é¸? 85
g_petList[30309648] = {type=1, dataId=7779, level=1} --çå…½è›‹ï¼šçŠ?é¸? 95
g_petList[30309649] = {type=1, dataId=7509, level=1} --çå…½è›‹ï¼šé¸?å˜´å…½ 5
g_petList[30309650] = {type=1, dataId=7519, level=1} --çå…½è›‹ï¼šé¸?å˜´å…½ 45
g_petList[30309651] = {type=1, dataId=7529, level=1} --çå…½è›‹ï¼šé¸?å˜´å…½ 55
g_petList[30309652] = {type=1, dataId=7539, level=1} --çå…½è›‹ï¼šé¸?å˜´å…½ 65
g_petList[30309653] = {type=1, dataId=7549, level=1} --çå…½è›‹ï¼šé¸?å˜´å…½ 75
g_petList[30309654] = {type=1, dataId=7559, level=1} --çå…½è›‹ï¼šé¸?å˜´å…½ 85
g_petList[30309655] = {type=1, dataId=7569, level=1} --çå…½è›‹ï¼šé¸?å˜´å…½ 95
g_petList[30309656] = {type=1, dataId=7579, level=1} --çå…½è›‹ï¼šé›?ç‹? 5
g_petList[30309657] = {type=1, dataId=7589, level=1} --çå…½è›‹ï¼šé›?ç‹? 45
g_petList[30309658] = {type=1, dataId=7599, level=1} --çå…½è›‹ï¼šé›?ç‹? 55
g_petList[30309659] = {type=1, dataId=7609, level=1} --çå…½è›‹ï¼šé›?ç‹? 65
g_petList[30309660] = {type=1, dataId=7619, level=1} --çå…½è›‹ï¼šé›?ç‹? 75
g_petList[30309661] = {type=1, dataId=7629, level=1} --çå…½è›‹ï¼šé›?ç‹? 85
g_petList[30309662] = {type=1, dataId=7639, level=1} --çå…½è›‹ï¼šé›?ç‹? 95
g_petList[30309663] = {type=1, dataId=8139, level=1} --çå…½è›‹ï¼šç©¿å±±ç”? 5
g_petList[30309664] = {type=1, dataId=8149, level=1} --çå…½è›‹ï¼šç©¿å±±ç”? 45
g_petList[30309665] = {type=1, dataId=8159, level=1} --çå…½è›‹ï¼šç©¿å±±ç”? 55
g_petList[30309666] = {type=1, dataId=8169, level=1} --çå…½è›‹ï¼šç©¿å±±ç”? 65
g_petList[30309667] = {type=1, dataId=8179, level=1} --çå…½è›‹ï¼šç©¿å±±ç”? 75
g_petList[30309668] = {type=1, dataId=8189, level=1} --çå…½è›‹ï¼šç©¿å±±ç”? 85
g_petList[30309669] = {type=1, dataId=8199, level=1} --çå…½è›‹ï¼šç©¿å±±ç”? 95
g_petList[30309670] = {type=1, dataId=8209, level=1} --çå…½è›‹ï¼šå¤§ç”²è™? 5
g_petList[30309671] = {type=1, dataId=8219, level=1} --çå…½è›‹ï¼šå¤§ç”²è™? 45
g_petList[30309672] = {type=1, dataId=8229, level=1} --çå…½è›‹ï¼šå¤§ç”²è™? 55
g_petList[30309673] = {type=1, dataId=8239, level=1} --çå…½è›‹ï¼šå¤§ç”²è™? 65
g_petList[30309674] = {type=1, dataId=8249, level=1} --çå…½è›‹ï¼šå¤§ç”²è™? 75
g_petList[30309675] = {type=1, dataId=8259, level=1} --çå…½è›‹ï¼šå¤§ç”²è™? 85
g_petList[30309676] = {type=1, dataId=8269, level=1} --çå…½è›‹ï¼šå¤§ç”²è™? 95
g_petList[30309677] = {type=1, dataId=8279, level=1} --çå…½è›‹ï¼šå½“æ‰ˆ 5
g_petList[30309678] = {type=1, dataId=8289, level=1} --çå…½è›‹ï¼šå½“æ‰ˆ 45
g_petList[30309679] = {type=1, dataId=8299, level=1} --çå…½è›‹ï¼šå½“æ‰ˆ 55
g_petList[30309680] = {type=1, dataId=8309, level=1} --çå…½è›‹ï¼šå½“æ‰ˆ 65
g_petList[30309681] = {type=1, dataId=8319, level=1} --çå…½è›‹ï¼šå½“æ‰ˆ 75
g_petList[30309682] = {type=1, dataId=8329, level=1} --çå…½è›‹ï¼šå½“æ‰ˆ 85
g_petList[30309683] = {type=1, dataId=8339, level=1} --çå…½è›‹ï¼šå½“æ‰ˆ 95
g_petList[30309684] = {type=1, dataId=8349, level=1} --çå…½è›‹ï¼šæµ·ç›—é¼? 5
g_petList[30309685] = {type=1, dataId=8359, level=1} --çå…½è›‹ï¼šæµ·ç›—é¼? 45
g_petList[30309686] = {type=1, dataId=8369, level=1} --çå…½è›‹ï¼šæµ·ç›—é¼? 55
g_petList[30309687] = {type=1, dataId=8379, level=1} --çå…½è›‹ï¼šæµ·ç›—é¼? 65
g_petList[30309688] = {type=1, dataId=8389, level=1} --çå…½è›‹ï¼šæµ·ç›—é¼? 75
g_petList[30309689] = {type=1, dataId=8399, level=1} --çå…½è›‹ï¼šæµ·ç›—é¼? 85
g_petList[30309690] = {type=1, dataId=8409, level=1} --çå…½è›‹ï¼šæµ·ç›—é¼? 95
g_petList[30309691] = {type=1, dataId=8419, level=1} --çå…½è›‹ï¼šå®ç?±ç?¥å­ 5
g_petList[30309692] = {type=1, dataId=8429, level=1} --çå…½è›‹ï¼šå®ç?±ç?¥å­ 45
g_petList[30309693] = {type=1, dataId=8439, level=1} --çå…½è›‹ï¼šå®ç?±ç?¥å­ 55
g_petList[30309694] = {type=1, dataId=8449, level=1} --çå…½è›‹ï¼šå®ç?±ç?¥å­ 65
g_petList[30309695] = {type=1, dataId=8459, level=1} --çå…½è›‹ï¼šå®ç?±ç?¥å­ 75
g_petList[30309696] = {type=1, dataId=8469, level=1} --çå…½è›‹ï¼šå®ç?±ç?¥å­ 85
g_petList[30309697] = {type=1, dataId=8479, level=1} --çå…½è›‹ï¼šå®ç?±ç?¥å­ 95
g_petList[30309698] = {type=1, dataId=8489, level=1} --çå…½è›‹ï¼šæ ‘è?‹ç†Š 5
g_petList[30309699] = {type=1, dataId=8499, level=1} --çå…½è›‹ï¼šæ ‘è?‹ç†Š 45
g_petList[30309700] = {type=1, dataId=8509, level=1} --çå…½è›‹ï¼šæ ‘è?‹ç†Š 55
g_petList[30309701] = {type=1, dataId=8519, level=1} --çå…½è›‹ï¼šæ ‘è?‹ç†Š 65
g_petList[30309702] = {type=1, dataId=8529, level=1} --çå…½è›‹ï¼šæ ‘è?‹ç†Š 75
g_petList[30309703] = {type=1, dataId=8539, level=1} --çå…½è›‹ï¼šæ ‘è?‹ç†Š 85
g_petList[30309704] = {type=1, dataId=8549, level=1} --çå…½è›‹ï¼šæ ‘è?‹ç†Š 95
g_petList[30309705] = {type=1, dataId=8569, level=1} --çå…½è›‹ï¼šæ¬?ä¹çŒª 5
g_petList[30309706] = {type=1, dataId=8579, level=1} --çå…½è›‹ï¼šæ¬?ä¹çŒª 45
g_petList[30309707] = {type=1, dataId=8589, level=1} --çå…½è›‹ï¼šæ¬?ä¹çŒª 55
g_petList[30309708] = {type=1, dataId=8599, level=1} --çå…½è›‹ï¼šæ¬?ä¹çŒª 65
g_petList[30309709] = {type=1, dataId=8609, level=1} --çå…½è›‹ï¼šæ¬?ä¹çŒª 75
g_petList[30309710] = {type=1, dataId=8619, level=1} --çå…½è›‹ï¼šæ¬?ä¹çŒª 85
g_petList[30309711] = {type=1, dataId=8629, level=1} --çå…½è›‹ï¼šæ¬?ä¹çŒª 95
g_petList[30309712] = {type=1, dataId=8749, level=1} --çå…½è›‹ï¼šå”è?…é¼  5
g_petList[30309713] = {type=1, dataId=8759, level=1} --çå…½è›‹ï¼šå”è?…é¼  45
g_petList[30309714] = {type=1, dataId=8769, level=1} --çå…½è›‹ï¼šå”è?…é¼  55
g_petList[30309715] = {type=1, dataId=8779, level=1} --çå…½è›‹ï¼šå”è?…é¼  65
g_petList[30309716] = {type=1, dataId=8789, level=1} --çå…½è›‹ï¼šå”è?…é¼  75
g_petList[30309717] = {type=1, dataId=8799, level=1} --çå…½è›‹ï¼šå”è?…é¼  85
g_petList[30309718] = {type=1, dataId=8809, level=1} --çå…½è›‹ï¼šå”è?…é¼  95
g_petList[30309719] = {type=1, dataId=8819, level=1} --çå…½è›‹ï¼šå¹´å…½ 5
g_petList[30309720] = {type=1, dataId=8829, level=1} --çå…½è›‹ï¼šå¹´å…½ 45
g_petList[30309721] = {type=1, dataId=8839, level=1} --çå…½è›‹ï¼šå¹´å…½ 55
g_petList[30309722] = {type=1, dataId=8849, level=1} --çå…½è›‹ï¼šå¹´å…½ 65
g_petList[30309723] = {type=1, dataId=8859, level=1} --çå…½è›‹ï¼šå¹´å…½ 75
g_petList[30309724] = {type=1, dataId=8869, level=1} --çå…½è›‹ï¼šå¹´å…½ 85
g_petList[30309725] = {type=1, dataId=8879, level=1} --çå…½è›‹ï¼šå¹´å…½ 95
g_petList[30309726] = {type=1, dataId=8889, level=1} --çå…½è›‹ï¼šé¸³é¸¯ 5
g_petList[30309727] = {type=1, dataId=8899, level=1} --çå…½è›‹ï¼šé¸³é¸¯ 45
g_petList[30309728] = {type=1, dataId=8909, level=1} --çå…½è›‹ï¼šé¸³é¸¯ 55
g_petList[30309729] = {type=1, dataId=8919, level=1} --çå…½è›‹ï¼šé¸³é¸¯ 65
g_petList[30309730] = {type=1, dataId=8929, level=1} --çå…½è›‹ï¼šé¸³é¸¯ 75
g_petList[30309731] = {type=1, dataId=8939, level=1} --çå…½è›‹ï¼šé¸³é¸¯ 85
g_petList[30309732] = {type=1, dataId=8949, level=1} --çå…½è›‹ï¼šé¸³é¸¯ 95
g_petList[30309733] = {type=1, dataId=22059, level=1} --çå…½è›‹ï¼šç©·å?? 85
g_petList[30309734] = {type=1, dataId=22129, level=1} --çå…½è›‹ï¼šå°ç‹ä»? 85
g_petList[30309735] = {type=1, dataId=22140, level=1} --çå…½è›‹ï¼šé’¢æ–§ç¥žçŒ¿ 5
g_petList[30309736] = {type=1, dataId=22150, level=1} --çå…½è›‹ï¼šä¸›æž—ç¥žçŒ¿ 45
g_petList[30309737] = {type=1, dataId=22160, level=1} --çå…½è›‹ï¼šåœ°ç‹±ç¥žçŒ¿ 55
g_petList[30309738] = {type=1, dataId=22170, level=1} --çå…½è›‹ï¼šé­…çµç¥žçŒ¿ 65
g_petList[30309739] = {type=1, dataId=22180, level=1} --çå…½è›‹ï¼šç½—æ±‰ç¥žçŒ¿ 75
g_petList[30309740] = {type=1, dataId=22190, level=1} --çå…½è›‹ï¼šä¸Šå¤ç¥žçŒ¿ 85
g_petList[30309741] = {type=1, dataId=22219, level=1} --çå…½è›‹ï¼šæ¯”ç¿¼é¸? 5
g_petList[30309742] = {type=1, dataId=22229, level=1} --çå…½è›‹ï¼šæ¯”ç¿¼é¸? 45
g_petList[30309743] = {type=1, dataId=22239, level=1} --çå…½è›‹ï¼šæ¯”ç¿¼é¸? 55
g_petList[30309744] = {type=1, dataId=22249, level=1} --çå…½è›‹ï¼šæ¯”ç¿¼é¸? 65
g_petList[30309745] = {type=1, dataId=22259, level=1} --çå…½è›‹ï¼šæ¯”ç¿¼é¸? 75
g_petList[30309746] = {type=1, dataId=22269, level=1} --çå…½è›‹ï¼šæ¯”ç¿¼é¸? 85
g_petList[30309747] = {type=1, dataId=22279, level=1} --çå…½è›‹ï¼šæ¯”ç¿¼é¸? 95
g_petList[30309748] = {type=1, dataId=22289, level=1} --çå…½è›‹ï¼šå‘†å‘†ç‰? 5
g_petList[30309749] = {type=1, dataId=22299, level=1} --çå…½è›‹ï¼šå‘†å‘†ç‰? 45
g_petList[30309750] = {type=1, dataId=22309, level=1} --çå…½è›‹ï¼šå‘†å‘†ç‰? 55
g_petList[30309751] = {type=1, dataId=22319, level=1} --çå…½è›‹ï¼šå‘†å‘†ç‰? 65
g_petList[30309752] = {type=1, dataId=22329, level=1} --çå…½è›‹ï¼šå‘†å‘†ç‰? 75
g_petList[30309753] = {type=1, dataId=22339, level=1} --çå…½è›‹ï¼šå‘†å‘†ç‰? 85
g_petList[30309754] = {type=1, dataId=22349, level=1} --çå…½è›‹ï¼šå‘†å‘†ç‰? 95
g_petList[38000080] = {type=1, dataId=22293, level=1} --å˜å¼‚çå…½è›‹ï¼šå‘†å‘†ç‰? 45
g_petList[30309755] = {type=2, dataIds={}, level=1}	--çå?‡ç‰›(æŒ‰ç…§çŽ©å?¶ç­‰çº§åŒºé—´ç»™ä¸åŒçš„å® ç‰?)
g_petList[30309755].dataIds[1] = {dataId=22359,minHumanLevel=1,maxHumanLevel=44}
g_petList[30309755].dataIds[2] = {dataId=22369,minHumanLevel=45,maxHumanLevel=54}
g_petList[30309755].dataIds[3] = {dataId=22379,minHumanLevel=55,maxHumanLevel=64}
g_petList[30309755].dataIds[4] = {dataId=22389,minHumanLevel=65,maxHumanLevel=74}
g_petList[30309755].dataIds[5] = {dataId=22399,minHumanLevel=75,maxHumanLevel=84}
g_petList[30309755].dataIds[6] = {dataId=22409,minHumanLevel=85,maxHumanLevel=255}
g_petList[30309054] = {type=1, dataId=8189, level=1} --çå…½è›‹ï¼šé›·éºŸ 85     --æ–°çŽ„æ­¦å²›ä¼šæŽ‰è›?
g_petList[30309055] = {type=1, dataId=3299, level=1} --çå…½è›‹ï¼šé›å‡¤ 85
g_petList[30309756] = {type=1, dataId=22489, level=1} --çå…½è›‹ï¼šéº’éºŸ 95
g_petList[30309056] = {type=1, dataId=3159, level=1} --çå…½è›‹ï¼šè€è™Ž 45
g_petList[30504088] = {type=1, dataId=22499, level=1} --çå…½è›‹ï¼šgoä»? 5
g_petList[30504089] = {type=1, dataId=22509, level=1} --çå…½è›‹ï¼šgoä»? 45
g_petList[30504090] = {type=1, dataId=22519, level=1} --çå…½è›‹ï¼šgoä»? 55
g_petList[30504091] = {type=1, dataId=22529, level=1} --çå…½è›‹ï¼šgoä»? 65
g_petList[30504092] = {type=1, dataId=22539, level=1} --çå…½è›‹ï¼šgoä»? 75
g_petList[30504093] = {type=1, dataId=22549, level=1} --çå…½è›‹ï¼šgoä»? 85
g_petList[30504094] = {type=1, dataId=22559, level=1} --çå…½è›‹ï¼šgoä»? 95
g_petList[30504125] = {type=1, dataId=23109, level=1} --çå…½è›‹ï¼šèŠ±ä»™å­? 95
g_petList[30504126] = {type=1, dataId=23559, level=1} --çå…½è›‹ï¼šç« é±¼ 95
g_petList[30504127] = {type=1, dataId=23469, level=1} --çå…½è›‹ï¼šç†ŠçŒ«åŒä¾  95
g_petList[30504128] = {type=1, dataId=23009, level=1} --çå…½è›‹ï¼šå¥¶æ²¹ç?é¸? 95
--***********************************************************
--æžè‡´æ–°å?žä¿®æ­?
--***********************************************************
g_petList[30309057] = {type=1, dataId=22569, level=1} --çå…½è›‹ï¼šç¥žçŒ¿
g_petList[30309058] = {type=1, dataId=22579, level=1} --çå…½è›‹ï¼šç¥žçŒ¿
g_petList[30309059] = {type=1, dataId=22589, level=1} --å²©é­‚
g_petList[30309060] = {type=1, dataId=22599, level=1} --å²©é­‚
g_petList[30309061] = {type=1, dataId=22609, level=1} --å²©é­‚
g_petList[30309062] = {type=1, dataId=22619, level=1} --å²©é­‚
g_petList[30309063] = {type=1, dataId=22629, level=1} --å²©é­‚
g_petList[30309064] = {type=1, dataId=22639, level=1} --å²©é­‚
g_petList[30309065] = {type=1, dataId=22649, level=1} --å²©é­‚
g_petList[30309077] = {type=1, dataId=23979, level=1} --ä¸ƒå·§ç‹¸çŒ«å®å®
--CYS-PET egg-guard off: g_petList[30309078] = {type=1, dataId=24609, level=1} --ç‹?è·?é€?
--CYS-PET egg-map old: g_petList[30309079] = {type=1, dataId=24619, level=1} --ç‹?è·?é€?
g_petList[30309079] = {type=1, dataId=27149, level=1}	--ÕäÊÞµ°£ºßãÐ¡ÃÈ [CYS-PET egg-map: ßãÐ¡ÃÈ±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 5]
g_petList[30309080] = {type=1, dataId=24629, level=1} --ç‹?è·?é€?
g_petList[30309081] = {type=1, dataId=24639, level=1} --ç‹?è·?é€?
g_petList[30309082] = {type=1, dataId=24649, level=1} --ç‹?è·?é€?
g_petList[30309083] = {type=1, dataId=24659, level=1} --ç‹?è·?é€?
g_petList[30309085] = {type=1, dataId=24599, level=1} --ç‹?è·?é€?
g_petList[30309084] = {type=1, dataId=6649, level=1} --çŽ‰å…”å®å®
g_petList[30309765] = {type=1, dataId=22799, level=1} --çŽ‰å…”å®å®
g_petList[30309766] = {type=1, dataId=22809, level=1} --çŽ‰å…”å®å®
g_petList[30309767] = {type=1, dataId=22819, level=1} --çŽ‰å…”å®å®
g_petList[30309768] = {type=1, dataId=22829, level=1} --çŽ‰å…”å®å®
g_petList[30309769] = {type=1, dataId=22839, level=1} --çŽ‰å…”å®å®
g_petList[30309770] = {type=1, dataId=22849, level=1} --çŽ‰å…”å®å®
g_petList[30309771] = {type=1, dataId=22859, level=1}


g_petList[30309772] = {type=1, dataId=22729, level=1}
g_petList[30309773] = {type=1, dataId=22739, level=1}
g_petList[30309774] = {type=1, dataId=22749, level=1}
g_petList[30309775] = {type=1, dataId=22759, level=1}
g_petList[30309776] = {type=1, dataId=22769, level=1}
g_petList[30309777] = {type=1, dataId=22779, level=1}
g_petList[30309778] = {type=1, dataId=22789, level=1}


g_petList[30309808] = {type=1, dataId=22949, level=1}
g_petList[30309809] = {type=1, dataId=22959, level=1}
g_petList[30309810] = {type=1, dataId=22969, level=1}
g_petList[30309811] = {type=1, dataId=22979, level=1}
g_petList[30309812] = {type=1, dataId=22989, level=1}
g_petList[30309813] = {type=1, dataId=22999, level=1}
g_petList[30309814] = {type=1, dataId=23009, level=1}

g_petList[30309816] = {type=1, dataId=23259, level=1}
g_petList[30309817] = {type=1, dataId=23269, level=1}
g_petList[30309818] = {type=1, dataId=23279, level=1}
g_petList[30309819] = {type=1, dataId=23289, level=1}
g_petList[30309820] = {type=1, dataId=23299, level=1}
g_petList[30309821] = {type=1, dataId=23309, level=1}
g_petList[30309822] = {type=1, dataId=23319, level=1}

g_petList[30309827] = {type=1, dataId=23119, level=1}
g_petList[30309828] = {type=1, dataId=23129, level=1}
g_petList[30309829] = {type=1, dataId=23139, level=1}
g_petList[30309830] = {type=1, dataId=23149, level=1}
g_petList[30309831] = {type=1, dataId=23159, level=1}
g_petList[30309832] = {type=1, dataId=23169, level=1}
g_petList[30309833] = {type=1, dataId=23179, level=1}

g_petList[30309837] = {type=1, dataId=23409, level=1}
g_petList[30309838] = {type=1, dataId=23419, level=1}
g_petList[30309839] = {type=1, dataId=23429, level=1}
g_petList[30309840] = {type=1, dataId=23439, level=1}
g_petList[30309841] = {type=1, dataId=23449, level=1}
g_petList[30309842] = {type=1, dataId=23459, level=1}
g_petList[30309843] = {type=1, dataId=23469, level=1}

g_petList[30309845] = {type=1, dataId=3069, level=1}
g_petList[30309983] = {type=1, dataId=30909, level=1}
--CYS-PET egg-map old: g_petList[30309985] = {type=1, dataId=30919, level=1}
g_petList[30309985] = {type=1, dataId=22299, level=1}	--ÕäÊÞµ°£º´ô´ôÅ£ [CYS-PET egg-map: ´ô´ôÅ£±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 45]
g_petList[30309986] = {type=1, dataId=30929, level=1}
g_petList[30309987] = {type=1, dataId=30939, level=1}
g_petList[30309990] = {type=1, dataId=31209, level=1}

--å››æ—¶å±±å›
g_petList[30309991] = {type=1, dataId=31239, level=1}
g_petList[30309992] = {type=1, dataId=31249, level=1}
g_petList[30309993] = {type=1, dataId=31259, level=1}
g_petList[30309994] = {type=1, dataId=31279, level=1}

--èŠ±ä»™å­?
--CYS-PET egg-map old: g_petList[30309997] = {type=1, dataId=23049, level=1}
g_petList[30309997] = {type=1, dataId=27499, level=1}	--ÕäÊÞµ°£º°Ù±äÍô×Ð [CYS-PET egg-map: °Ù±äÍô×Ð±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 5]
--CYS-PET egg-map old: g_petList[30309998] = {type=1, dataId=23059, level=1}
g_petList[30309998] = {type=1, dataId=27549, level=1}	--ÕäÊÞµ°£º°Ù±äÍô×Ð [CYS-PET egg-map: °Ù±äÍô×Ð±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 85]
--CYS-PET egg-map old: g_petList[30309999] = {type=1, dataId=23069, level=1}
g_petList[30309999] = {type=1, dataId=27559, level=1}	--ÕäÊÞµ°£º°Ù±äÍô×Ð [CYS-PET egg-map: °Ù±äÍô×Ð±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 95]
g_petList[30310000] = {type=1, dataId=23079, level=1}
g_petList[30310001] = {type=1, dataId=23089, level=1}
g_petList[30310002] = {type=1, dataId=23099, level=1}
g_petList[30310003] = {type=1, dataId=23109, level=1}

--å·§å·§
g_petList[30310012] = {type=1, dataId=24759, level=1}
g_petList[30310013] = {type=1, dataId=24769, level=1}
g_petList[30310014] = {type=1, dataId=24779, level=1}
g_petList[30310015] = {type=1, dataId=24789, level=1}
g_petList[30310016] = {type=1, dataId=24799, level=1}
g_petList[30310017] = {type=1, dataId=24809, level=1}
g_petList[30310018] = {type=1, dataId=24819, level=1}

--å¤©å‘½çŽ„å‡¤
g_petList[30310023] = {type=1, dataId=24839, level=1}
g_petList[30310024] = {type=1, dataId=24849, level=1}
g_petList[30310025] = {type=1, dataId=24859, level=1}
g_petList[30310026] = {type=1, dataId=24869, level=1}
g_petList[30310027] = {type=1, dataId=24879, level=1}
g_petList[30310028] = {type=1, dataId=24889, level=1}
g_petList[30310029] = {type=1, dataId=24899, level=1}

--å°èŠ±å¦?
g_petList[30310039] = {type=1, dataId=23989, level=1}
g_petList[30310040] = {type=1, dataId=23999, level=1}
g_petList[30310041] = {type=1, dataId=24009, level=1}
g_petList[30310042] = {type=1, dataId=24019, level=1}
g_petList[30310043] = {type=1, dataId=24029, level=1}
g_petList[30310044] = {type=1, dataId=24039, level=1}
g_petList[30310045] = {type=1, dataId=24049, level=1}

--å›šç‰›
g_petList[30310031] = {type=1, dataId=24919, level=1}
g_petList[30310032] = {type=1, dataId=24929, level=1}
g_petList[30310033] = {type=1, dataId=24939, level=1}
g_petList[30310034] = {type=1, dataId=24949, level=1}
g_petList[30310035] = {type=1, dataId=24959, level=1}
g_petList[30310036] = {type=1, dataId=24969, level=1}
g_petList[30310037] = {type=1, dataId=24979, level=1}

--çƒˆå…”ç”œå¿ƒ
g_petList[30310047] = {type=1, dataId=27429, level=1}
g_petList[30310048] = {type=1, dataId=27439, level=1}
g_petList[30310049] = {type=1, dataId=27449, level=1}
g_petList[30310050] = {type=1, dataId=27459, level=1}
g_petList[30310051] = {type=1, dataId=27469, level=1}
g_petList[30310052] = {type=1, dataId=27479, level=1}
g_petList[30310053] = {type=1, dataId=27489, level=1}

--ä¸ƒå½©è¾‰éª
g_petList[30310055] = {type=1, dataId=27499, level=1}
g_petList[30310056] = {type=1, dataId=27509, level=1}
g_petList[30310057] = {type=1, dataId=27519, level=1}
g_petList[30310058] = {type=1, dataId=27529, level=1}
g_petList[30310059] = {type=1, dataId=27539, level=1}
g_petList[30310060] = {type=1, dataId=27549, level=1}
g_petList[30310061] = {type=1, dataId=27559, level=1}

--å®‰çªå„?
--CYS-PET egg-guard off: g_petList[30309089] = {type=1, dataId=24679, level=1}
--CYS-PET egg-guard off: g_petList[30309090] = {type=1, dataId=24689, level=1}
g_petList[30309091] = {type=1, dataId=24699, level=1}
--CYS-PET egg-guard off: g_petList[30309092] = {type=1, dataId=24709, level=1}
--CYS-PET egg-guard off: g_petList[30309093] = {type=1, dataId=24719, level=1}
--CYS-PET egg-map old: g_petList[30309094] = {type=1, dataId=24729, level=1}
g_petList[30309094] = {type=1, dataId=27809, level=1}	--ÕäÊÞµ°£ºÐþÅ®Éß [CYS-PET egg-map: ÐþÅ®Éß±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 85]
--CYS-PET egg-map old: g_petList[30309095] = {type=1, dataId=24739, level=1}
g_petList[30309095] = {type=1, dataId=27819, level=1}	--ÕäÊÞµ°£ºÐþÅ®Éß [CYS-PET egg-map: ÐþÅ®Éß±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 95]

--é•‡å²›ç¥žå…½
g_petList[30310068] = {type=1, dataId=27579, level=1}
g_petList[30310069] = {type=1, dataId=27589, level=1}
g_petList[30310070] = {type=1, dataId=27599, level=1}
g_petList[30310071] = {type=1, dataId=27609, level=1}
g_petList[30310072] = {type=1, dataId=27619, level=1}
g_petList[30310073] = {type=1, dataId=27629, level=1}
g_petList[30310074] = {type=1, dataId=27639, level=1}

--é¸¾å‡¤å’Œé¸£
g_petList[30310078] = {type=1, dataId=27649, level=1}
g_petList[30310079] = {type=1, dataId=27659, level=1}
g_petList[30310080] = {type=1, dataId=27669, level=1}
g_petList[30310081] = {type=1, dataId=27679, level=1}
g_petList[30310082] = {type=1, dataId=27689, level=1}
g_petList[30310083] = {type=1, dataId=27699, level=1}
g_petList[30310084] = {type=1, dataId=27709, level=1}
--å¹³å¤©å¤§åœ£
g_petList[30310130] = {type=1, dataId=30189, level=1}
g_petList[30310131] = {type=1, dataId=30199, level=1}
g_petList[30310132] = {type=1, dataId=30209, level=1}
g_petList[30310133] = {type=1, dataId=30219, level=1}
g_petList[30310134] = {type=1, dataId=30229, level=1}
g_petList[30310135] = {type=1, dataId=30239, level=1}
g_petList[30310136] = {type=1, dataId=30249, level=1}
--ç™¾å˜åœ£åƒ§
g_petList[30310141] = {type=1, dataId=6739, level=1}
g_petList[30310142] = {type=1, dataId=6749, level=1}
g_petList[30310143] = {type=1, dataId=6759, level=1}
g_petList[30310144] = {type=1, dataId=6769, level=1}
g_petList[30310145] = {type=1, dataId=6779, level=1}
g_petList[30310146] = {type=1, dataId=6789, level=1}
g_petList[30310147] = {type=1, dataId=6799, level=1}
--çµå·«æœˆç??
g_petList[30310149] = {type=1, dataId=27939, level=1}
g_petList[30310150] = {type=1, dataId=27949, level=1}
g_petList[30310151] = {type=1, dataId=27959, level=1}
g_petList[30310152] = {type=1, dataId=27969, level=1}
g_petList[30310153] = {type=1, dataId=27979, level=1}
g_petList[30310154] = {type=1, dataId=27989, level=1}
g_petList[30310155] = {type=1, dataId=27999, level=1}
--é»‘å±±å§¥å§¥
g_petList[30310160] = {type=1, dataId=25929, level=1}
g_petList[30310161] = {type=1, dataId=25939, level=1}
g_petList[30310162] = {type=1, dataId=25949, level=1}
g_petList[30310163] = {type=1, dataId=25959, level=1}
g_petList[30310164] = {type=1, dataId=25969, level=1}
g_petList[30310165] = {type=1, dataId=25979, level=1}
g_petList[30310166] = {type=1, dataId=25989, level=1}
--å…?è€³çŒ•çŒ?
-- g_petList[30310171] = {type=1, dataId=26039, level=1}
--g_petList[30310171] = {type=1, dataId=26039, level=1}
g_petList[30310171] = {type=1, dataId=26039, level=1}
g_petList[30310172] = {type=1, dataId=26049, level=1}
g_petList[30310173] = {type=1, dataId=26059, level=1}
g_petList[30310174] = {type=1, dataId=26069, level=1}
g_petList[30310175] = {type=1, dataId=26079, level=1}
g_petList[30310176] = {type=1, dataId=26089, level=1}
g_petList[30310177] = {type=1, dataId=26099, level=1}
--å—æºŸ
g_petList[30310179] = {type=1, dataId=26109, level=1}
g_petList[30310180] = {type=1, dataId=26119, level=1}
g_petList[30310181] = {type=1, dataId=26129, level=1}
g_petList[30310182] = {type=1, dataId=26139, level=1}
g_petList[30310183] = {type=1, dataId=26149, level=1}
g_petList[30310184] = {type=1, dataId=26159, level=1}
g_petList[30310185] = {type=1, dataId=26169, level=1}
--èš?éª¨å†¥è›?
g_petList[38003424] = {type=1, dataId=6809, level=1}
g_petList[38003414] = {type=1, dataId=6819, level=1}
g_petList[38003415] = {type=1, dataId=6829, level=1}
g_petList[38003416] = {type=1, dataId=6839, level=1}
g_petList[38003417] = {type=1, dataId=6849, level=1}
g_petList[38003418] = {type=1, dataId=6859, level=1}
g_petList[38003419] = {type=1, dataId=6869, level=1}
--é‡‘ç?¥çŽ‰å¥?
g_petList[38003490] = {type=1, dataId=25859, level=1}
g_petList[38003491] = {type=1, dataId=25869, level=1}
g_petList[38003492] = {type=1, dataId=25879, level=1}
g_petList[38003493] = {type=1, dataId=25889, level=1}
g_petList[38003494] = {type=1, dataId=25899, level=1}
g_petList[38003495] = {type=1, dataId=25909, level=1}
g_petList[38003496] = {type=1, dataId=25919, level=1}
--å®ç?±ç?¥å­
g_petList[30310066] = {type=1, dataId=8419, level=1}

--æ¬?ä¹çŒª
g_petList[30310067] = {type=1, dataId=8569, level=1}

--ç‰¹æ®Šçå…½ç‹?è·?é€¢Â·ä¹å¹½ä½“åŠ›èµ„è´¨åœ¨#G2500#Wä»¥ä¸Š
g_petList[30309086] = {type=1, dataId=24661, level=1} 
--ç‰¹æ®Šçå…½ç‹?è·?é€¢Â·ä¹å¹½ä½“åŠ›èµ„è´¨åœ¨#G2350#Wä»¥ä¸Š
g_petList[30309087] = {type=1, dataId=24661, level=1} 
--ç‰¹æ®Šçå…½ç‹?è·?é€¢Â·ä¹å¹½ä½“åŠ›èµ„è´¨åœ¨#G2200#Wä»¥ä¸Š
g_petList[30309088] = {type=1, dataId=24661, level=1} 
--/////////////////////////////////////////////////////////
g_petList[30309531] = {type=1, dataId=30039, level=1} 
--çå…½è›‹ï¼šæ˜?ç‘žéº’éº?
g_petList[30310089] = {type=1, dataId=30049, level=1} 
g_petList[30310090] = {type=1, dataId=30059, level=1} 
g_petList[30310091] = {type=1, dataId=30069, level=1} 
g_petList[30310092] = {type=1, dataId=30079, level=1} 
g_petList[30310093] = {type=1, dataId=30089, level=1} 
g_petList[30310094] = {type=1, dataId=30099, level=1} 
g_petList[30310095] = {type=1, dataId=30109, level=1} 

--çå…½è›‹ï¼šè¦†æµ·é¾™å›
g_petList[30310097] = {type=1, dataId=30119, level=1} 
g_petList[30310098] = {type=1, dataId=30129, level=1} 
g_petList[30310099] = {type=1, dataId=30139, level=1} 
g_petList[30310100] = {type=1, dataId=30149, level=1} 
g_petList[30310101] = {type=1, dataId=30159, level=1} 
g_petList[30310102] = {type=1, dataId=30169, level=1} 
g_petList[30310103] = {type=1, dataId=30179, level=1} 

--çå…½è›‹ï¼šé£“é?Žåœ£å…?
g_petList[30310105] = {type=1, dataId=27829, level=1}
g_petList[30310106] = {type=1, dataId=27839, level=1}
g_petList[30310107] = {type=1, dataId=27849, level=1}
g_petList[30310108] = {type=1, dataId=27859, level=1}
g_petList[30310109] = {type=1, dataId=27869, level=1}
g_petList[30310110] = {type=1, dataId=27879, level=1}
g_petList[30310111] = {type=1, dataId=27889, level=1}

--çå…½è›‹ï¼šåƒé”‹æˆ˜èŽ
g_petList[30310118] = {type=1, dataId=30949, level=1}
g_petList[30310119] = {type=1, dataId=30959, level=1}
g_petList[30310120] = {type=1, dataId=30969, level=1}
g_petList[30310121] = {type=1, dataId=30979, level=1}
g_petList[30310122] = {type=1, dataId=30989, level=1}
g_petList[30310123] = {type=1, dataId=30999, level=1}
g_petList[30310124] = {type=1, dataId=31009, level=1}

--çå…½è›‹ï¼šçµéœ„ç™½æ³½
g_petList[38003975] = {type=1, dataId=28249, level=1}
g_petList[38003976] = {type=1, dataId=28259, level=1}
g_petList[38003977] = {type=1, dataId=28269, level=1}
g_petList[38003978] = {type=1, dataId=28279, level=1}
g_petList[38003979] = {type=1, dataId=28289, level=1}
g_petList[38003980] = {type=1, dataId=28299, level=1}
g_petList[38003981] = {type=1, dataId=28309, level=1}


g_petList[30309066] = {type=1, dataIds={}, level=1}	--æ¬?ä¹çŒª
g_petList[30309066].dataIds[1] = {dataId=8569,minHumanLevel=5,maxHumanLevel=44}
g_petList[30309066].dataIds[2] = {dataId=8579,minHumanLevel=45,maxHumanLevel=54}
g_petList[30309066].dataIds[3] = {dataId=8589,minHumanLevel=55,maxHumanLevel=64}
g_petList[30309066].dataIds[4] = {dataId=8599,minHumanLevel=65,maxHumanLevel=74}
g_petList[30309066].dataIds[5] = {dataId=8609,minHumanLevel=75,maxHumanLevel=84}
g_petList[30309066].dataIds[6] = {dataId=8619,minHumanLevel=85,maxHumanLevel=94}
g_petList[30309066].dataIds[7] = {dataId=8629,minHumanLevel=95,maxHumanLevel=119}

g_petList[30309067] = {type=1, dataIds={}, level=1}	--çµå…”å…?
g_petList[30309067].dataIds[1] = {dataId=22799,minHumanLevel=5,maxHumanLevel=44}
g_petList[30309067].dataIds[2] = {dataId=22809,minHumanLevel=45,maxHumanLevel=54}
g_petList[30309067].dataIds[3] = {dataId=22819,minHumanLevel=55,maxHumanLevel=64}
g_petList[30309067].dataIds[4] = {dataId=22829,minHumanLevel=65,maxHumanLevel=74}
g_petList[30309067].dataIds[5] = {dataId=22839,minHumanLevel=75,maxHumanLevel=84}
g_petList[30309067].dataIds[6] = {dataId=22849,minHumanLevel=85,maxHumanLevel=94}
g_petList[30309067].dataIds[7] = {dataId=22859,minHumanLevel=95,maxHumanLevel=119}

g_petList[30309068] = {type=1, dataId=23339, level=1} --å¹¼é½¿é¾?
g_petList[30309069] = {type=1, dataId=23349, level=1} --å¹¼é½¿é¾?
g_petList[30309070] = {type=1, dataId=23359, level=1} --å¹¼é½¿é¾?
g_petList[30309071] = {type=1, dataId=23369, level=1} --å¹¼é½¿é¾?
g_petList[30309072] = {type=1, dataId=23379, level=1} --å¹¼é½¿é¾?
g_petList[30309073] = {type=1, dataId=23389, level=1} --å¹¼é½¿é¾?
g_petList[30309074] = {type=1, dataId=23399, level=1} --å¹¼é½¿é¾?

g_petList[30309075] = {type=1, dataIds={}, level=1}	--å¹¼é½¿é¾?
g_petList[30309075].dataIds[1] = {dataId=23339,minHumanLevel=5,maxHumanLevel=44}
g_petList[30309075].dataIds[2] = {dataId=23349,minHumanLevel=45,maxHumanLevel=54}
g_petList[30309075].dataIds[3] = {dataId=23359,minHumanLevel=55,maxHumanLevel=64}
g_petList[30309075].dataIds[4] = {dataId=23369,minHumanLevel=65,maxHumanLevel=74}
g_petList[30309075].dataIds[5] = {dataId=23379,minHumanLevel=75,maxHumanLevel=84}
g_petList[30309075].dataIds[6] = {dataId=23389,minHumanLevel=85,maxHumanLevel=94}
g_petList[30309075].dataIds[7] = {dataId=23399,minHumanLevel=95,maxHumanLevel=119}

g_petList[30309757] = {type=2, dataIds={}, level=1}	--å‘†å‘†ç‰?
g_petList[30309757].dataIds[1] = {dataId=22289,minHumanLevel=5,maxHumanLevel=44}
g_petList[30309757].dataIds[2] = {dataId=22299,minHumanLevel=45,maxHumanLevel=54}
g_petList[30309757].dataIds[3] = {dataId=22309,minHumanLevel=55,maxHumanLevel=64}
g_petList[30309757].dataIds[4] = {dataId=22319,minHumanLevel=65,maxHumanLevel=74}
g_petList[30309757].dataIds[5] = {dataId=22329,minHumanLevel=75,maxHumanLevel=84}
g_petList[30309757].dataIds[6] = {dataId=22339,minHumanLevel=85,maxHumanLevel=94}
g_petList[30309757].dataIds[7] = {dataId=22349,minHumanLevel=95,maxHumanLevel=119}


g_petList[30309815] = {type=2, dataIds={}, level=1}	--å‘†å‘†ç‰?
g_petList[30309815].dataIds[1] = {dataId=23189,minHumanLevel=5,maxHumanLevel=44}
g_petList[30309815].dataIds[2] = {dataId=23199,minHumanLevel=45,maxHumanLevel=54}
g_petList[30309815].dataIds[3] = {dataId=23209,minHumanLevel=55,maxHumanLevel=64}
g_petList[30309815].dataIds[4] = {dataId=23219,minHumanLevel=65,maxHumanLevel=74}
g_petList[30309815].dataIds[5] = {dataId=23229,minHumanLevel=75,maxHumanLevel=84}
g_petList[30309815].dataIds[6] = {dataId=23239,minHumanLevel=85,maxHumanLevel=94}
g_petList[30309815].dataIds[7] = {dataId=23249,minHumanLevel=95,maxHumanLevel=119}

--CYS-PET egg-guard off: g_petList[30309078] = {type=2, dataIds={}, level=1}	--çå…½è›‹ï¼šç‹?è·?é€?
--CYS-PET egg-guard off: g_petList[30309078].dataIds[1] = {dataId=24599,minHumanLevel=45,maxHumanLevel=54}
--CYS-PET egg-guard off: g_petList[30309078].dataIds[2] = {dataId=24609,minHumanLevel=55,maxHumanLevel=64}
--CYS-PET egg-guard off: g_petList[30309078].dataIds[3] = {dataId=24619,minHumanLevel=65,maxHumanLevel=74}
--CYS-PET egg-guard off: g_petList[30309078].dataIds[4] = {dataId=24629,minHumanLevel=75,maxHumanLevel=84}
--CYS-PET egg-guard off: g_petList[30309078].dataIds[5] = {dataId=24639,minHumanLevel=85,maxHumanLevel=94}
--CYS-PET egg-guard off: g_petList[30309078].dataIds[6] = {dataId=24649,minHumanLevel=95,maxHumanLevel=119}

g_petList[30309846] = {type=2, dataIds={}, level=1}	--é«˜çº§çå…½ç¬¼ï¼šå°ç‹ä»?
g_petList[30309846].dataIds[1] = {dataId=22099,minHumanLevel=55,maxHumanLevel=64}
g_petList[30309846].dataIds[2] = {dataId=22109,minHumanLevel=65,maxHumanLevel=74}
g_petList[30309846].dataIds[3] = {dataId=22119,minHumanLevel=75,maxHumanLevel=84}
g_petList[30309846].dataIds[4] = {dataId=22129,minHumanLevel=85,maxHumanLevel=94}
g_petList[30309846].dataIds[5] = {dataId=22139,minHumanLevel=95,maxHumanLevel=119}

g_petList[30309982] = {type=2, dataIds={}, level=1}	--è¶…çº§çå…½ç¬¼ï¼šä¹é»Žå¦–è™Ž
g_petList[30309982].dataIds[1] = {dataId=27389,minHumanLevel=65,maxHumanLevel=74}
g_petList[30309982].dataIds[2] = {dataId=27399,minHumanLevel=75,maxHumanLevel=84}
g_petList[30309982].dataIds[3] = {dataId=27409,minHumanLevel=85,maxHumanLevel=94}
g_petList[30309982].dataIds[4] = {dataId=27419,minHumanLevel=95,maxHumanLevel=119}

g_petList[30309984] = {type=2, dataIds={}, level=1}	--è¶…çº§çå…½ç¬¼ï¼šä¸‡ä¸–é­?
g_petList[30309984].dataIds[1] = {dataId=31109,minHumanLevel=65,maxHumanLevel=74}
g_petList[30309984].dataIds[2] = {dataId=31119,minHumanLevel=75,maxHumanLevel=84}
g_petList[30309984].dataIds[3] = {dataId=31129,minHumanLevel=85,maxHumanLevel=94}
g_petList[30309984].dataIds[4] = {dataId=31139,minHumanLevel=95,maxHumanLevel=119}

g_petList[30309988] = {type=2, dataIds={}, level=1}	--è¶…çº§çå…½ç¬¼ï¼šç‹?è·?é€?
g_petList[30309988].dataIds[1] = {dataId=24629,minHumanLevel=65,maxHumanLevel=74}
g_petList[30309988].dataIds[2] = {dataId=24639,minHumanLevel=75,maxHumanLevel=84}
g_petList[30309988].dataIds[3] = {dataId=24649,minHumanLevel=85,maxHumanLevel=94}
g_petList[30309988].dataIds[4] = {dataId=24659,minHumanLevel=95,maxHumanLevel=119}

g_petList[30309989] = {type=2, dataIds={}, level=1}	--è¶…çº§çå…½ç¬¼ï¼šç§¦å°å?
g_petList[30309989].dataIds[1] = {dataId=30909,minHumanLevel=65,maxHumanLevel=74}
g_petList[30309989].dataIds[2] = {dataId=30919,minHumanLevel=75,maxHumanLevel=84}
g_petList[30309989].dataIds[3] = {dataId=30929,minHumanLevel=85,maxHumanLevel=94}
g_petList[30309989].dataIds[4] = {dataId=30939,minHumanLevel=95,maxHumanLevel=119}

g_petList[30309995] = {type=2, dataIds={}, level=1}	--è¶…çº§çå…½ç¬¼ï¼šå››æ—¶å±±å›
g_petList[30309995].dataIds[1] = {dataId=31249,minHumanLevel=65,maxHumanLevel=74}
g_petList[30309995].dataIds[2] = {dataId=31259,minHumanLevel=75,maxHumanLevel=84}
g_petList[30309995].dataIds[3] = {dataId=31269,minHumanLevel=85,maxHumanLevel=94}
g_petList[30309995].dataIds[4] = {dataId=31279,minHumanLevel=95,maxHumanLevel=119}

g_petList[30309996] = {type=2, dataIds={}, level=1}	--è¶…çº§çå…½ç¬¼ï¼šå®‰çªå„?
g_petList[30309996].dataIds[1] = {dataId=24709,minHumanLevel=65,maxHumanLevel=74}
g_petList[30309996].dataIds[2] = {dataId=24719,minHumanLevel=75,maxHumanLevel=84}
g_petList[30309996].dataIds[3] = {dataId=24729,minHumanLevel=85,maxHumanLevel=94}
g_petList[30309996].dataIds[4] = {dataId=24739,minHumanLevel=95,maxHumanLevel=119}

g_petList[30310011] = {type=2, dataIds={}, level=1}	--è¶…çº§çå…½ç¬¼ï¼šéœ“å‡°
g_petList[30310011].dataIds[1] = {dataId=31319,minHumanLevel=65,maxHumanLevel=74}
g_petList[30310011].dataIds[2] = {dataId=31329,minHumanLevel=75,maxHumanLevel=84}
g_petList[30310011].dataIds[3] = {dataId=31339,minHumanLevel=85,maxHumanLevel=94}
g_petList[30310011].dataIds[4] = {dataId=31349,minHumanLevel=95,maxHumanLevel=119}

g_petList[30310022] = {type=2, dataIds={}, level=1}	--è¶…çº§çå…½ç¬¼ï¼šå·§å·§
g_petList[30310022].dataIds[1] = {dataId=24789,minHumanLevel=65,maxHumanLevel=74}
g_petList[30310022].dataIds[2] = {dataId=24799,minHumanLevel=75,maxHumanLevel=84}
g_petList[30310022].dataIds[3] = {dataId=24809,minHumanLevel=85,maxHumanLevel=94}
g_petList[30310022].dataIds[4] = {dataId=24819,minHumanLevel=95,maxHumanLevel=119}

g_petList[30310030] = {type=2, dataIds={}, level=1}	--è¶…çº§çå…½ç¬¼ï¼šå¤©å‘½çŽ„å‡¤
g_petList[30310030].dataIds[1] = {dataId=24869,minHumanLevel=65,maxHumanLevel=74}
g_petList[30310030].dataIds[2] = {dataId=24879,minHumanLevel=75,maxHumanLevel=84}
g_petList[30310030].dataIds[3] = {dataId=24889,minHumanLevel=85,maxHumanLevel=94}
g_petList[30310030].dataIds[4] = {dataId=24899,minHumanLevel=95,maxHumanLevel=119}

g_petList[30310038] = {type=2, dataIds={}, level=1}	--è¶…çº§çå…½ç¬¼ï¼šå›šç‰›
g_petList[30310038].dataIds[1] = {dataId=24949,minHumanLevel=65,maxHumanLevel=74}
g_petList[30310038].dataIds[2] = {dataId=24959,minHumanLevel=75,maxHumanLevel=84}
g_petList[30310038].dataIds[3] = {dataId=24969,minHumanLevel=85,maxHumanLevel=94}
g_petList[30310038].dataIds[4] = {dataId=24979,minHumanLevel=95,maxHumanLevel=119}

g_petList[30310046] = {type=2, dataIds={}, level=1}	--è¶…çº§çå…½ç¬¼ï¼šå°èŠ±å¦?
g_petList[30310046].dataIds[1] = {dataId=24019,minHumanLevel=65,maxHumanLevel=74}
g_petList[30310046].dataIds[2] = {dataId=24029,minHumanLevel=75,maxHumanLevel=84}
g_petList[30310046].dataIds[3] = {dataId=24039,minHumanLevel=85,maxHumanLevel=94}
g_petList[30310046].dataIds[4] = {dataId=24049,minHumanLevel=95,maxHumanLevel=119}

g_petList[30310054] = {type=2, dataIds={}, level=1}	--è¶…çº§çå…½ç¬¼ï¼šçƒˆå…”ç”œå¿ƒ
g_petList[30310054].dataIds[1] = {dataId=27459,minHumanLevel=65,maxHumanLevel=74}
g_petList[30310054].dataIds[2] = {dataId=27469,minHumanLevel=75,maxHumanLevel=84}
g_petList[30310054].dataIds[3] = {dataId=27479,minHumanLevel=85,maxHumanLevel=94}
g_petList[30310054].dataIds[4] = {dataId=27489,minHumanLevel=95,maxHumanLevel=119}

g_petList[30310062] = {type=2, dataIds={}, level=1}	--è¶…çº§çå…½ç¬¼ï¼šä¸ƒå½©è¾‰éª
g_petList[30310062].dataIds[1] = {dataId=27529,minHumanLevel=65,maxHumanLevel=74}
g_petList[30310062].dataIds[2] = {dataId=27539,minHumanLevel=75,maxHumanLevel=84}
g_petList[30310062].dataIds[3] = {dataId=27549,minHumanLevel=85,maxHumanLevel=94}
g_petList[30310062].dataIds[4] = {dataId=27559,minHumanLevel=95,maxHumanLevel=119}

g_petList[30310075] = {type=2, dataIds={}, level=1}	--è¶…çº§çå…½ç¬¼ï¼šé•‡å²›ç¥žå…½
g_petList[30310075].dataIds[1] = {dataId=27609,minHumanLevel=65,maxHumanLevel=74}
g_petList[30310075].dataIds[2] = {dataId=27619,minHumanLevel=75,maxHumanLevel=84}
g_petList[30310075].dataIds[3] = {dataId=27629,minHumanLevel=85,maxHumanLevel=94}
g_petList[30310075].dataIds[4] = {dataId=27639,minHumanLevel=95,maxHumanLevel=119}

g_petList[30310076] = {type=2, dataIds={}, level=1}	--è¶…çº§çå…½ç¬¼ï¼šé•‡å²›ç¥žå…½
g_petList[30310076].dataIds[1] = {dataId=27609,minHumanLevel=65,maxHumanLevel=74}
g_petList[30310076].dataIds[2] = {dataId=27619,minHumanLevel=75,maxHumanLevel=84}
g_petList[30310076].dataIds[3] = {dataId=27629,minHumanLevel=85,maxHumanLevel=94}
g_petList[30310076].dataIds[4] = {dataId=27639,minHumanLevel=95,maxHumanLevel=119}

g_petList[30310085] = {type=2, dataIds={}, level=1}	--è¶…çº§çå…½ç¬¼ï¼šé¸¾å‡¤å’Œé¸£
g_petList[30310085].dataIds[1] = {dataId=27679,minHumanLevel=65,maxHumanLevel=74}
g_petList[30310085].dataIds[2] = {dataId=27689,minHumanLevel=75,maxHumanLevel=84}
g_petList[30310085].dataIds[3] = {dataId=27699,minHumanLevel=85,maxHumanLevel=94}
g_petList[30310085].dataIds[4] = {dataId=27709,minHumanLevel=95,maxHumanLevel=119}

g_petList[38000204] = {type=2, dataIds={}, level=1}	--è¶…çº§çå…½ç¬¼ï¼šäº”è‰²ç¥žç‰›
g_petList[38000204].dataIds[1] = {dataId=23749,minHumanLevel=65,maxHumanLevel=74}
g_petList[38000204].dataIds[2] = {dataId=23759,minHumanLevel=75,maxHumanLevel=84}
g_petList[38000204].dataIds[3] = {dataId=23769,minHumanLevel=85,maxHumanLevel=94}
g_petList[38000204].dataIds[4] = {dataId=23779,minHumanLevel=95,maxHumanLevel=119}

g_petList[38002172] = {type=2, dataIds={}, level=1}	--è¶…çº§çå…½ç¬¼ï¼šä¸ƒå·§ç‹¸çŒ«
g_petList[38002172].dataIds[1] = {dataId=23949,minHumanLevel=65,maxHumanLevel=74}
g_petList[38002172].dataIds[2] = {dataId=23959,minHumanLevel=75,maxHumanLevel=84}
g_petList[38002172].dataIds[3] = {dataId=23969,minHumanLevel=85,maxHumanLevel=94}
g_petList[38002172].dataIds[4] = {dataId=23979,minHumanLevel=95,maxHumanLevel=119}

g_petList[38001080] = {type=2, dataIds={}, level=1}	--è¶…çº§çå…½ç¬¼ï¼šå”è?…é¼ 
g_petList[38001080].dataIds[1] = {dataId=8779,minHumanLevel=65,maxHumanLevel=74}
g_petList[38001080].dataIds[2] = {dataId=8789,minHumanLevel=75,maxHumanLevel=84}
g_petList[38001080].dataIds[3] = {dataId=8799,minHumanLevel=85,maxHumanLevel=94}
g_petList[38001080].dataIds[4] = {dataId=8809,minHumanLevel=95,maxHumanLevel=119}

g_petList[38001798] = {type=2, dataIds={}, level=1}	--è¶…çº§çå…½ç¬¼ï¼šèŒå®çŒ?
g_petList[38001798].dataIds[1] = {dataId=30609,minHumanLevel=65,maxHumanLevel=74}
g_petList[38001798].dataIds[2] = {dataId=30619,minHumanLevel=75,maxHumanLevel=84}
g_petList[38001798].dataIds[3] = {dataId=30629,minHumanLevel=85,maxHumanLevel=94}
g_petList[38001798].dataIds[4] = {dataId=30639,minHumanLevel=95,maxHumanLevel=119}

g_petList[30309802] = {type=2, dataIds={}, level=1}	--ä½Žçº§çå…½ç¬¼ï¼šç†ŠçŒ«
g_petList[30309802].dataIds[1] = {dataId=7789,minHumanLevel=5,maxHumanLevel=44}
g_petList[30309802].dataIds[2] = {dataId=7799,minHumanLevel=45,maxHumanLevel=119}

g_petList[30309803] = {type=2, dataIds={}, level=1}	--é«˜çº§çå…½ç¬¼ï¼šç†ŠçŒ«
g_petList[30309803].dataIds[1] = {dataId=7809,minHumanLevel=5,maxHumanLevel=64}
g_petList[30309803].dataIds[2] = {dataId=7819,minHumanLevel=65,maxHumanLevel=74}
g_petList[30309803].dataIds[3] = {dataId=7829,minHumanLevel=75,maxHumanLevel=84}
g_petList[30309803].dataIds[4] = {dataId=7839,minHumanLevel=85,maxHumanLevel=119}

g_petList[30309804] = {type=2, dataIds={}, level=1}	--è¶…çº§çå…½ç¬¼ï¼šç†ŠçŒ«
g_petList[30309804].dataIds[1] = {dataId=7849,minHumanLevel=5,maxHumanLevel=119}

g_petList[30309791] = {type=2, dataIds={}, level=1}	--ä½Žçº§çå…½ç¬¼ï¼šå‘†å‘†ç‰?
g_petList[30309791].dataIds[1] = {dataId=22289,minHumanLevel=5,maxHumanLevel=44}
g_petList[30309791].dataIds[2] = {dataId=22299,minHumanLevel=45,maxHumanLevel=119}

g_petList[30309792] = {type=2, dataIds={}, level=1}	--é«˜çº§çå…½ç¬¼ï¼šå‘†å‘†ç‰?
g_petList[30309792].dataIds[1] = {dataId=22309,minHumanLevel=5,maxHumanLevel=64}
g_petList[30309792].dataIds[2] = {dataId=22319,minHumanLevel=65,maxHumanLevel=74}
g_petList[30309792].dataIds[3] = {dataId=22329,minHumanLevel=75,maxHumanLevel=84}
g_petList[30309792].dataIds[4] = {dataId=22339,minHumanLevel=85,maxHumanLevel=119}

g_petList[30309793] = {type=2, dataIds={}, level=1}	--è¶…çº§çå…½ç¬¼ï¼šå‘†å‘†ç‰?
g_petList[30309793].dataIds[1] = {dataId=22349,minHumanLevel=5,maxHumanLevel=119}

g_petList[30310010] = {type=1, dataId=31349, level=1,minHumanLevel=95,maxHumanLevel=119} --éœ“å‡°
g_petList[30310116] = {type=1, dataId=27819, level=1,minHumanLevel=95,maxHumanLevel=119} --çå…½è›‹ï¼šå°é¹¿å‘¦å‘¦

g_petList[30310096] = {type=2, dataIds={}, level=1}	--è¶…çº§çå…½ç¬¼ï¼šæ˜?ç‘žéº’éº?
g_petList[30310096].dataIds[1] = {dataId=30079,minHumanLevel=65,maxHumanLevel=74}
g_petList[30310096].dataIds[2] = {dataId=30089,minHumanLevel=75,maxHumanLevel=84}
g_petList[30310096].dataIds[3] = {dataId=30099,minHumanLevel=85,maxHumanLevel=94}
g_petList[30310096].dataIds[4] = {dataId=30109,minHumanLevel=95,maxHumanLevel=119}

g_petList[30310104] = {type=2, dataIds={}, level=1}	--è¶…çº§çå…½ç¬¼ï¼šè¦†æµ·é¾™å›
g_petList[30310104].dataIds[1] = {dataId=30149,minHumanLevel=65,maxHumanLevel=74}
g_petList[30310104].dataIds[2] = {dataId=30159,minHumanLevel=75,maxHumanLevel=84}
g_petList[30310104].dataIds[3] = {dataId=30169,minHumanLevel=85,maxHumanLevel=94}
g_petList[30310104].dataIds[4] = {dataId=30179,minHumanLevel=95,maxHumanLevel=119}

g_petList[30310117] = {type=2, dataIds={}, level=1}	--è¶…çº§çå…½ç¬¼ï¼šå°é¹¿å‘¦å‘¦
g_petList[30310117].dataIds[1] = {dataId=27789,minHumanLevel=65,maxHumanLevel=74}
g_petList[30310117].dataIds[2] = {dataId=27799,minHumanLevel=75,maxHumanLevel=84}
g_petList[30310117].dataIds[3] = {dataId=27809,minHumanLevel=85,maxHumanLevel=94}
g_petList[30310117].dataIds[4] = {dataId=27819,minHumanLevel=95,maxHumanLevel=119}

g_petList[30310112] = {type=2, dataIds={}, level=1}	--è¶…çº§çå…½ç¬¼ï¼šé£“é?Žåœ£å…?
g_petList[30310112].dataIds[1] = {dataId=27859,minHumanLevel=65,maxHumanLevel=74}
g_petList[30310112].dataIds[2] = {dataId=27869,minHumanLevel=75,maxHumanLevel=84}
g_petList[30310112].dataIds[3] = {dataId=27879,minHumanLevel=85,maxHumanLevel=94}
g_petList[30310112].dataIds[4] = {dataId=27889,minHumanLevel=95,maxHumanLevel=119}

g_petList[30310125] = {type=2, dataIds={}, level=1}	--è¶…çº§çå…½ç¬¼ï¼šåƒå³°æˆ˜èŽ
g_petList[30310125].dataIds[1] = {dataId=30979,minHumanLevel=65,maxHumanLevel=74}
g_petList[30310125].dataIds[2] = {dataId=30989,minHumanLevel=75,maxHumanLevel=84}
g_petList[30310125].dataIds[3] = {dataId=30999,minHumanLevel=85,maxHumanLevel=94}
g_petList[30310125].dataIds[4] = {dataId=31009,minHumanLevel=95,maxHumanLevel=119}

g_petList[30310126] = {type=2, dataIds={}, level=1}	--è¶…çº§çå…½ç¬¼ï¼šç?ç„°å?–é­”
g_petList[30310126].dataIds[1] = {dataId=31179,minHumanLevel=65,maxHumanLevel=74}
g_petList[30310126].dataIds[2] = {dataId=31189,minHumanLevel=75,maxHumanLevel=84}
g_petList[30310126].dataIds[3] = {dataId=31199,minHumanLevel=85,maxHumanLevel=94}
g_petList[30310126].dataIds[4] = {dataId=31209,minHumanLevel=95,maxHumanLevel=119}

g_petList[30310140] = {type=2, dataIds={}, level=1}	--è¶…çº§çå…½ç¬¼ï¼šå¹³å¤©å¤§åœ£
g_petList[30310140].dataIds[1] = {dataId=30219,minHumanLevel=65,maxHumanLevel=74}
g_petList[30310140].dataIds[2] = {dataId=30229,minHumanLevel=75,maxHumanLevel=84}
g_petList[30310140].dataIds[3] = {dataId=30239,minHumanLevel=85,maxHumanLevel=94}
g_petList[30310140].dataIds[4] = {dataId=30249,minHumanLevel=95,maxHumanLevel=119}

g_petList[30310148] = {type=2, dataIds={}, level=1}	--è¶…çº§çå…½ç¬¼ï¼šç™¾å˜åœ£åƒ§
g_petList[30310148].dataIds[1] = {dataId=6769,minHumanLevel=65,maxHumanLevel=74}
g_petList[30310148].dataIds[2] = {dataId=6779,minHumanLevel=75,maxHumanLevel=84}
g_petList[30310148].dataIds[3] = {dataId=6789,minHumanLevel=85,maxHumanLevel=94}
g_petList[30310148].dataIds[4] = {dataId=6799,minHumanLevel=95,maxHumanLevel=119}

g_petList[30310156] = {type=2, dataIds={}, level=1}	--è¶…çº§çå…½ç¬¼ï¼šçµå·«æœˆç??
g_petList[30310156].dataIds[1] = {dataId=27969,minHumanLevel=65,maxHumanLevel=74}
g_petList[30310156].dataIds[2] = {dataId=27979,minHumanLevel=75,maxHumanLevel=84}
g_petList[30310156].dataIds[3] = {dataId=27989,minHumanLevel=85,maxHumanLevel=94}
g_petList[30310156].dataIds[4] = {dataId=27999,minHumanLevel=95,maxHumanLevel=119}

g_petList[38003420] = {type=2, dataIds={}, level=1}	--è¶…çº§çå…½ç¬¼ï¼šèš?éª¨å†¥è›?
g_petList[38003420].dataIds[1] = {dataId=6839,minHumanLevel=65,maxHumanLevel=74}
g_petList[38003420].dataIds[2] = {dataId=6849,minHumanLevel=75,maxHumanLevel=84}
g_petList[38003420].dataIds[3] = {dataId=6859,minHumanLevel=85,maxHumanLevel=94}
g_petList[38003420].dataIds[4] = {dataId=6869,minHumanLevel=95,maxHumanLevel=119}

g_petList[38003497] = {type=2, dataIds={}, level=1}	--è¶…çº§çå…½ç¬¼ï¼šé‡‘ç?¥çŽ‰å¥?
g_petList[38003497].dataIds[1] = {dataId=25889,minHumanLevel=65,maxHumanLevel=74}
g_petList[38003497].dataIds[2] = {dataId=25899,minHumanLevel=75,maxHumanLevel=84}
g_petList[38003497].dataIds[3] = {dataId=25909,minHumanLevel=85,maxHumanLevel=94}
g_petList[38003497].dataIds[4] = {dataId=25919,minHumanLevel=95,maxHumanLevel=119}

g_petList[38003982] = {type=2, dataIds={}, level=1}	--è¶…çº§çå…½ç¬¼ï¼šçµéœ„ç™½æ³½
g_petList[38003982].dataIds[1] = {dataId=28279,minHumanLevel=65,maxHumanLevel=74}
g_petList[38003982].dataIds[2] = {dataId=28289,minHumanLevel=75,maxHumanLevel=84}
g_petList[38003982].dataIds[3] = {dataId=28299,minHumanLevel=85,maxHumanLevel=94}
g_petList[38003982].dataIds[4] = {dataId=28309,minHumanLevel=95,maxHumanLevel=119}
g_petList[38010170] = {type=1, dataId=36949, level=1}	--ÕäÊÞµ°£º³þÐ¡¾Å lv5 pet2026-20260910
g_petList[38010171] = {type=1, dataId=36959, level=1}	--ÕäÊÞµ°£º³þÐ¡¾Å lv45 pet2026-20260910
g_petList[38010172] = {type=1, dataId=36969, level=1}	--ÕäÊÞµ°£º³þÐ¡¾Å lv55 pet2026-20260910
g_petList[38010173] = {type=1, dataId=36979, level=1}	--ÕäÊÞµ°£º³þÐ¡¾Å lv65 pet2026-20260910
g_petList[38010174] = {type=1, dataId=36989, level=1}	--ÕäÊÞµ°£º³þÐ¡¾Å lv75 pet2026-20260910
g_petList[38010175] = {type=1, dataId=36999, level=1}	--ÕäÊÞµ°£º³þÐ¡¾Å lv85 pet2026-20260910
g_petList[38010176] = {type=1, dataId=37009, level=1}	--ÕäÊÞµ°£º³þÐ¡¾Å lv95 pet2026-20260910
g_petList[38010177] = {type=2, dataIds={}, level=1}	--³¬¼¶ÕäÊÞÁý£º³þÐ¡¾Å pet2026-20260910
g_petList[38010177].dataIds[1] = {dataId=36979,minHumanLevel=65,maxHumanLevel=74}
g_petList[38010177].dataIds[2] = {dataId=36989,minHumanLevel=75,maxHumanLevel=84}
g_petList[38010177].dataIds[3] = {dataId=36999,minHumanLevel=85,maxHumanLevel=94}
g_petList[38010177].dataIds[4] = {dataId=37009,minHumanLevel=95,maxHumanLevel=119}
g_petList[38004038] = {type=1, dataId=26179, level=1}	--ÕäÊÞµ°£º³þÐ¡¾Å¡¤¼« lv5 cyhj2026-20260910
g_petList[38004039] = {type=1, dataId=26189, level=1}	--ÕäÊÞµ°£º³þÐ¡¾Å¡¤¼« lv45 cyhj2026-20260910
g_petList[38004040] = {type=1, dataId=26199, level=1}	--ÕäÊÞµ°£º³þÐ¡¾Å¡¤¼« lv55 cyhj2026-20260910
g_petList[38004041] = {type=1, dataId=26209, level=1}	--ÕäÊÞµ°£º³þÐ¡¾Å¡¤¼« lv65 cyhj2026-20260910
g_petList[38004042] = {type=1, dataId=26219, level=1}	--ÕäÊÞµ°£º³þÐ¡¾Å¡¤¼« lv75 cyhj2026-20260910
g_petList[38004043] = {type=1, dataId=26229, level=1}	--ÕäÊÞµ°£º³þÐ¡¾Å¡¤¼« lv85 cyhj2026-20260910
g_petList[38004044] = {type=1, dataId=26239, level=1}	--ÕäÊÞµ°£º³þÐ¡¾Å¡¤¼« lv95 cyhj2026-20260910
g_petList[38004045] = {type=2, dataIds={}, level=1}	--³¬¼¶ÕäÊÞÁý£º³þÐ¡¾Å¡¤¼« cyhj2026-20260910
g_petList[38004045].dataIds[1] = {dataId=26209,minHumanLevel=65,maxHumanLevel=74}
g_petList[38004045].dataIds[2] = {dataId=26219,minHumanLevel=75,maxHumanLevel=84}
g_petList[38004045].dataIds[3] = {dataId=26229,minHumanLevel=85,maxHumanLevel=94}
g_petList[38004045].dataIds[4] = {dataId=26239,minHumanLevel=95,maxHumanLevel=119}


g_petList[30310167] = {type=2, dataIds={}, level=1}	--è¶…çº§çå…½ç¬¼ï¼šé»‘å±±å§¥å§¥
g_petList[30310167].dataIds[1] = {dataId=25959,minHumanLevel=65,maxHumanLevel=119}
g_petList[30310167].dataIds[2] = {dataId=25969,minHumanLevel=75,maxHumanLevel=119}
g_petList[30310167].dataIds[3] = {dataId=25979,minHumanLevel=85,maxHumanLevel=119}
g_petList[30310167].dataIds[4] = {dataId=25989,minHumanLevel=95,maxHumanLevel=119}

g_petList[30310178] = {type=2, dataIds={}, level=1}	--è¶…çº§çå…½ç¬¼ï¼šå…?è€³çŒ•çŒ?
g_petList[30310178].dataIds[1] = {dataId=26069,minHumanLevel=65,maxHumanLevel=119}
g_petList[30310178].dataIds[2] = {dataId=26079,minHumanLevel=75,maxHumanLevel=119}
g_petList[30310178].dataIds[3] = {dataId=26089,minHumanLevel=85,maxHumanLevel=119}
g_petList[30310178].dataIds[4] = {dataId=26099,minHumanLevel=95,maxHumanLevel=119}
--CYS-PET egg-map: 173 trung CY khong co muc trong bang 0.85 (theo ten + ¿ÉÐ¯´øµÈ¼¶, xem Tools/server/pet_egg_map.py)
g_petList[30309066] = {type=1, dataId=8569, level=1}	--ÕäÊÞµ°£º»¶ÀÖÖí [CYS-PET egg-map: »¶ÀÖÖí±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 5]
g_petList[30309067] = {type=1, dataId=22799, level=1}	--ÕäÊÞµ°£ºÁéÍÃÊÞ [CYS-PET egg-map: ÁéÍÃÊÞ±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 5]
g_petList[30309075] = {type=1, dataId=23339, level=1}	--ÕäÊÞµ°£ºÓ×³ÝÁú [CYS-PET egg-map: Ó×³ÝÁú±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 5]
g_petList[30309097] = {type=1, dataId=27839, level=1}	--ÕäÊÞµ°£ºÖÓÐ¡»¨ [CYS-PET egg-map: ÖÓÐ¡»¨±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 45]
g_petList[30309098] = {type=1, dataId=27969, level=1}	--ÕäÊÞµ°£ºÃ«Ã«Å£ [CYS-PET egg-map: Ã«Ã«Å£±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 95]
g_petList[30309099] = {type=1, dataId=28039, level=1}	--ÕäÊÞµ°£ºÊ¥×±Ð¡Â¹ [CYS-PET egg-map: Ê¥×±Ð¡Â¹±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 95]
g_petList[30309501] = {type=1, dataId=27879, level=1}	--ÕäÊÞµ°£ºÖÓÐ¡ºÚ [CYS-PET egg-map: ÖÓÐ¡ºÚ±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 5]
g_petList[30309504] = {type=1, dataId=23989, level=1}	--ÕäÊÞµ°£ºÓñð½·ï [CYS-PET egg-map: Óñð½·ï±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 5]
g_petList[30309506] = {type=1, dataId=23989, level=1}	--ÕäÊÞµ°£ºÓñð½·ï [CYS-PET egg-map: Óñð½·ï±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 5]
g_petList[30309510] = {type=1, dataId=28249, level=1}	--ÕäÊÞµ°£º±©×ßÐÜÃ¨ [CYS-PET egg-map: ±©×ßÐÜÃ¨±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 95]
g_petList[30309511] = {type=1, dataId=28319, level=1}	--ÕäÊÞµ°£ºÃÈÒô»¨Áé [CYS-PET egg-map: ÃÈÒô»¨Áé±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 95]
g_petList[30309512] = {type=1, dataId=28329, level=1}	--ÕäÊÞµ°£ºÐ¡Ò× [CYS-PET egg-map: Ð¡Ò×±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 20]
g_petList[30309513] = {type=1, dataId=28399, level=1}	--ÕäÊÞµ°£ºÐ¡Âí¸ç [CYS-PET egg-map: Ð¡Âí¸ç±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 95]
g_petList[30309514] = {type=1, dataId=29449, level=1}	--ÕäÊÞµ°£ºº©¶ºÐÜ [CYS-PET egg-map: º©¶ºÐÜ±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 95]
g_petList[30309515] = {type=1, dataId=29451, level=1}	--±äÒìÕäÊÞµ°£ºÔªÔª [CYS-PET egg-map: ±äÒìÔªÔª, ten+¿ÉÐ¯´øµÈ¼¶ 5]
g_petList[30309516] = {type=1, dataId=28469, level=1}	--ÕäÊÞµ°£º°ÙÕ½½ð¸Õ [CYS-PET egg-map: °ÙÕ½½ð¸Õ±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 95]
g_petList[30309518] = {type=1, dataId=29529, level=1}	--ÕäÊÞµ°£ºÈËÓã¹«Ö÷ [CYS-PET egg-map: ÈËÓã¹«Ö÷±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 95]
g_petList[30309519] = {type=1, dataId=29609, level=1}	--ÕäÊÞµ°£ºÕ½ÐÞÂÞ [CYS-PET egg-map: Õ½ÐÞÂÞ±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 95]
g_petList[30309523] = {type=1, dataId=29679, level=1}	--ÕäÊÞµ°£ºÐ°Áé [CYS-PET egg-map: Ð°Áé±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 95]
g_petList[30309524] = {type=1, dataId=29749, level=1}	--ÕäÊÞµ°£ººüÑý½£¾ý [CYS-PET egg-map: ºüÑý½£¾ý±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 95]
g_petList[30309525] = {type=1, dataId=29819, level=1}	--ÕäÊÞµ°£º¾ÅÏöÕ½Áú [CYS-PET egg-map: ¾ÅÏöÕ½Áú±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 95]
g_petList[30309527] = {type=1, dataId=29959, level=1}	--ÕäÊÞµ°£ºÌúÉÈ¹«Ö÷ [CYS-PET egg-map: ÌúÉÈ¹«Ö÷±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 95]
g_petList[30309530] = {type=1, dataId=27229, level=1}	--ÕäÊÞµ°£ºÃÀÈËÓã [CYS-PET egg-map: ÃÀÈËÓã±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 5]
g_petList[30309534] = {type=1, dataId=30389, level=1}	--ÕäÊÞµ°£º¶þÀÉÕæ¾ý [CYS-PET egg-map: ¶þÀÉÕæ¾ý±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 95]
g_petList[30309755] = {type=1, dataId=22359, level=1}	--ÕäÊÞµ°£ºÕäÆæÅ£ [CYS-PET egg-map: ÕäÆæÅ£±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 5]
g_petList[30309757] = {type=1, dataId=22289, level=1}	--ÕäÊÞµ°£º´ô´ôÅ£ [CYS-PET egg-map: ´ô´ôÅ£±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 5]
g_petList[30309779] = {type=1, dataId=3001, level=1}	--ÕäÊÞµ°£º±äÒìÍÃ×Ó [CYS-PET egg-map: ±äÒìÍÃ×Ó, ten+¿ÉÐ¯´øµÈ¼¶ 5]
g_petList[30309780] = {type=1, dataId=3011, level=1}	--ÕäÊÞµ°£º±äÒìÑà×Ó [CYS-PET egg-map: ±äÒìÑà×Ó, ten+¿ÉÐ¯´øµÈ¼¶ 5]
g_petList[30309781] = {type=1, dataId=3021, level=1}	--ÕäÊÞµ°£º±äÒìÎÚ¹ê [CYS-PET egg-map: ±äÒìÎÚ¹ê, ten+¿ÉÐ¯´øµÈ¼¶ 5]
g_petList[30309782] = {type=1, dataId=3031, level=1}	--ÕäÊÞµ°£º±äÒì¹· [CYS-PET egg-map: ±äÒì¹·, ten+¿ÉÐ¯´øµÈ¼¶ 5]
g_petList[30309783] = {type=1, dataId=3041, level=1}	--ÕäÊÞµ°£º±äÒì´Ìâ¬ [CYS-PET egg-map: ±äÒì´Ìâ¬, ten+¿ÉÐ¯´øµÈ¼¶ 5]
g_petList[30309784] = {type=1, dataId=3051, level=1}	--ÕäÊÞµ°£º±äÒìºï×Ó [CYS-PET egg-map: ±äÒìºï×Ó, ten+¿ÉÐ¯´øµÈ¼¶ 5]
g_petList[30309815] = {type=1, dataId=23189, level=1}	--ÕäÊÞµ°£ºÕäÆæ»¢ [CYS-PET egg-map: ÕäÆæ»¢±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 5]
g_petList[30309846] = {type=1, dataId=23409, level=1}	--ÕäÊÞµ°£ºÐÜÃ¨Ë«ÏÀ [CYS-PET egg-map: ÐÜÃ¨Ë«ÏÀ±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 5]
g_petList[30309847] = {type=1, dataId=23719, level=1}	--ÕäÊÞµ°£ºÎåÉ«ÉñÅ£ [CYS-PET egg-map: ÎåÉ«ÉñÅ£±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 5]
g_petList[30309848] = {type=1, dataId=23729, level=1}	--ÕäÊÞµ°£ºÎåÉ«ÉñÅ£ [CYS-PET egg-map: ÎåÉ«ÉñÅ£±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 45]
g_petList[30309849] = {type=1, dataId=23739, level=1}	--ÕäÊÞµ°£ºÎåÉ«ÉñÅ£ [CYS-PET egg-map: ÎåÉ«ÉñÅ£±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 55]
g_petList[30309850] = {type=1, dataId=23749, level=1}	--ÕäÊÞµ°£ºÎåÉ«ÉñÅ£ [CYS-PET egg-map: ÎåÉ«ÉñÅ£±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 65]
g_petList[30309851] = {type=1, dataId=23759, level=1}	--ÕäÊÞµ°£ºÎåÉ«ÉñÅ£ [CYS-PET egg-map: ÎåÉ«ÉñÅ£±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 75]
g_petList[30309852] = {type=1, dataId=23769, level=1}	--ÕäÊÞµ°£ºÎåÉ«ÉñÅ£ [CYS-PET egg-map: ÎåÉ«ÉñÅ£±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 85]
g_petList[30309853] = {type=1, dataId=23779, level=1}	--ÕäÊÞµ°£ºÎåÉ«ÉñÅ£ [CYS-PET egg-map: ÎåÉ«ÉñÅ£±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 95]
g_petList[30309854] = {type=1, dataId=23719, level=1}	--ÕäÊÞµ°£ºÎåÉ«ÉñÅ£ [CYS-PET egg-map: ÎåÉ«ÉñÅ£±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 5]
g_petList[30309855] = {type=1, dataId=23989, level=1}	--ÕäÊÞµ°£ºÓñð½·ï [CYS-PET egg-map: Óñð½·ï±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 5]
g_petList[30309856] = {type=1, dataId=23999, level=1}	--ÕäÊÞµ°£ºÓñð½·ï [CYS-PET egg-map: Óñð½·ï±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 45]
g_petList[30309857] = {type=1, dataId=24009, level=1}	--ÕäÊÞµ°£ºÓñð½·ï [CYS-PET egg-map: Óñð½·ï±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 55]
g_petList[30309858] = {type=1, dataId=24019, level=1}	--ÕäÊÞµ°£ºÓñð½·ï [CYS-PET egg-map: Óñð½·ï±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 65]
g_petList[30309859] = {type=1, dataId=24029, level=1}	--ÕäÊÞµ°£ºÓñð½·ï [CYS-PET egg-map: Óñð½·ï±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 75]
g_petList[30309860] = {type=1, dataId=24039, level=1}	--ÕäÊÞµ°£ºÓñð½·ï [CYS-PET egg-map: Óñð½·ï±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 85]
g_petList[30309861] = {type=1, dataId=24049, level=1}	--ÕäÊÞµ°£ºÓñð½·ï [CYS-PET egg-map: Óñð½·ï±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 95]
g_petList[30309869] = {type=1, dataId=22429, level=1}	--ÕäÊÞµ°£º÷è÷ë [CYS-PET egg-map: ÷è÷ë±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 5]
g_petList[30309875] = {type=1, dataId=24129, level=1}	--ÕäÊÞµ°£ºÁéÍÃË«½Ü [CYS-PET egg-map: ÁéÍÃË«½Ü±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 5]
g_petList[30309876] = {type=1, dataId=24139, level=1}	--ÕäÊÞµ°£ºÁéÍÃË«½Ü [CYS-PET egg-map: ÁéÍÃË«½Ü±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 45]
g_petList[30309877] = {type=1, dataId=24149, level=1}	--ÕäÊÞµ°£ºÁéÍÃË«½Ü [CYS-PET egg-map: ÁéÍÃË«½Ü±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 55]
g_petList[30309878] = {type=1, dataId=24159, level=1}	--ÕäÊÞµ°£ºÁéÍÃË«½Ü [CYS-PET egg-map: ÁéÍÃË«½Ü±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 65]
g_petList[30309879] = {type=1, dataId=24169, level=1}	--ÕäÊÞµ°£ºÁéÍÃË«½Ü [CYS-PET egg-map: ÁéÍÃË«½Ü±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 75]
g_petList[30309880] = {type=1, dataId=24179, level=1}	--ÕäÊÞµ°£ºÁéÍÃË«½Ü [CYS-PET egg-map: ÁéÍÃË«½Ü±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 85]
g_petList[30309881] = {type=1, dataId=24189, level=1}	--ÕäÊÞµ°£ºÁéÍÃË«½Ü [CYS-PET egg-map: ÁéÍÃË«½Ü±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 95]
g_petList[30309882] = {type=1, dataId=24199, level=1}	--ÕäÊÞµ°£ºÂùÊ¯¹Ö [CYS-PET egg-map: ÂùÊ¯¹Ö±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 5]
g_petList[30309883] = {type=1, dataId=24209, level=1}	--ÕäÊÞµ°£ºÂùÊ¯¹Ö [CYS-PET egg-map: ÂùÊ¯¹Ö±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 45]
g_petList[30309884] = {type=1, dataId=24219, level=1}	--ÕäÊÞµ°£ºÂùÊ¯¹Ö [CYS-PET egg-map: ÂùÊ¯¹Ö±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 55]
g_petList[30309885] = {type=1, dataId=24229, level=1}	--ÕäÊÞµ°£ºÂùÊ¯¹Ö [CYS-PET egg-map: ÂùÊ¯¹Ö±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 65]
g_petList[30309886] = {type=1, dataId=24239, level=1}	--ÕäÊÞµ°£ºÂùÊ¯¹Ö [CYS-PET egg-map: ÂùÊ¯¹Ö±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 75]
g_petList[30309887] = {type=1, dataId=24249, level=1}	--ÕäÊÞµ°£ºÂùÊ¯¹Ö [CYS-PET egg-map: ÂùÊ¯¹Ö±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 85]
g_petList[30309888] = {type=1, dataId=24259, level=1}	--ÕäÊÞµ°£ºÂùÊ¯¹Ö [CYS-PET egg-map: ÂùÊ¯¹Ö±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 95]
g_petList[30309889] = {type=1, dataId=24269, level=1}	--ÕäÊÞµ°£º¾«ÁéÍÃ [CYS-PET egg-map: ¾«ÁéÍÃ±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 5]
g_petList[30309890] = {type=1, dataId=24279, level=1}	--ÕäÊÞµ°£º¾«ÁéÍÃ [CYS-PET egg-map: ¾«ÁéÍÃ±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 45]
g_petList[30309891] = {type=1, dataId=24289, level=1}	--ÕäÊÞµ°£º¾«ÁéÍÃ [CYS-PET egg-map: ¾«ÁéÍÃ±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 55]
g_petList[30309892] = {type=1, dataId=24299, level=1}	--ÕäÊÞµ°£º¾«ÁéÍÃ [CYS-PET egg-map: ¾«ÁéÍÃ±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 65]
g_petList[30309893] = {type=1, dataId=24309, level=1}	--ÕäÊÞµ°£º¾«ÁéÍÃ [CYS-PET egg-map: ¾«ÁéÍÃ±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 75]
g_petList[30309894] = {type=1, dataId=24319, level=1}	--ÕäÊÞµ°£º¾«ÁéÍÃ [CYS-PET egg-map: ¾«ÁéÍÃ±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 85]
g_petList[30309895] = {type=1, dataId=24329, level=1}	--ÕäÊÞµ°£º¾«ÁéÍÃ [CYS-PET egg-map: ¾«ÁéÍÃ±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 95]
g_petList[30309896] = {type=1, dataId=24339, level=1}	--ÕäÊÞµ°£º½õÃ«Êó [CYS-PET egg-map: ½õÃ«Êó±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 5]
g_petList[30309897] = {type=1, dataId=24349, level=1}	--ÕäÊÞµ°£º½õÃ«Êó [CYS-PET egg-map: ½õÃ«Êó±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 45]
g_petList[30309898] = {type=1, dataId=24359, level=1}	--ÕäÊÞµ°£º½õÃ«Êó [CYS-PET egg-map: ½õÃ«Êó±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 55]
g_petList[30309899] = {type=1, dataId=24369, level=1}	--ÕäÊÞµ°£º½õÃ«Êó [CYS-PET egg-map: ½õÃ«Êó±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 65]
g_petList[30309900] = {type=1, dataId=24379, level=1}	--ÕäÊÞµ°£º½õÃ«Êó [CYS-PET egg-map: ½õÃ«Êó±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 75]
g_petList[30309901] = {type=1, dataId=24389, level=1}	--ÕäÊÞµ°£º½õÃ«Êó [CYS-PET egg-map: ½õÃ«Êó±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 85]
g_petList[30309902] = {type=1, dataId=24399, level=1}	--ÕäÊÞµ°£º½õÃ«Êó [CYS-PET egg-map: ½õÃ«Êó±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 95]
g_petList[30309907] = {type=1, dataId=24409, level=1}	--ÕäÊÞµ°£º¶àÍæÐÜ [CYS-PET egg-map: ¶àÍæÐÜ±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 5]
g_petList[30309908] = {type=1, dataId=24419, level=1}	--ÕäÊÞµ°£ºYYÐÜ [CYS-PET egg-map: YYÐÜ±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 20]
g_petList[30309909] = {type=1, dataId=23839, level=1}	--ÕäÊÞµ°£º½©Ê¬ [CYS-PET egg-map: ½©Ê¬±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 95]
g_petList[30309913] = {type=1, dataId=24429, level=1}	--ÕäÊÞµ°£ºêÄÈÕÐÇ [CYS-PET egg-map: êÄÈÕÐÇ±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 5]
g_petList[30309914] = {type=1, dataId=24439, level=1}	--ÕäÊÞµ°£º¹°ÌìØX [CYS-PET egg-map: ¹°ÌìØX±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 5]
g_petList[30309915] = {type=1, dataId=24449, level=1}	--ÕäÊÞµ°£º¶«·çÂÝ [CYS-PET egg-map: ¶«·çÂÝ±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 5]
g_petList[30309924] = {type=1, dataId=23849, level=1}	--ÕäÊÞµ°£ºÓÄÚ¤ÀÇÑý [CYS-PET egg-map: ÓÄÚ¤ÀÇÑý±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 5]
g_petList[30309925] = {type=1, dataId=24519, level=1}	--ÕäÊÞµ°£º°Ù±äÃ¨ [CYS-PET egg-map: °Ù±äÃ¨±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 5]
g_petList[30309926] = {type=1, dataId=24529, level=1}	--ÕäÊÞµ°£º°Ù±äÃ¨ [CYS-PET egg-map: °Ù±äÃ¨±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 45]
g_petList[30309927] = {type=1, dataId=24539, level=1}	--ÕäÊÞµ°£º°Ù±äÃ¨ [CYS-PET egg-map: °Ù±äÃ¨±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 55]
g_petList[30309928] = {type=1, dataId=24549, level=1}	--ÕäÊÞµ°£º°Ù±äÃ¨ [CYS-PET egg-map: °Ù±äÃ¨±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 65]
g_petList[30309929] = {type=1, dataId=24559, level=1}	--ÕäÊÞµ°£º°Ù±äÃ¨ [CYS-PET egg-map: °Ù±äÃ¨±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 75]
g_petList[30309930] = {type=1, dataId=24569, level=1}	--ÕäÊÞµ°£º°Ù±äÃ¨ [CYS-PET egg-map: °Ù±äÃ¨±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 85]
g_petList[30309931] = {type=1, dataId=24579, level=1}	--ÕäÊÞµ°£º°Ù±äÃ¨ [CYS-PET egg-map: °Ù±äÃ¨±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 95]
g_petList[30309933] = {type=1, dataId=24589, level=1}	--ÕäÊÞµ°£ºáÔÊó [CYS-PET egg-map: áÔÊó±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 5]
g_petList[30309934] = {type=1, dataId=24599, level=1}	--ÕäÊÞµ°£ºÈËÅ¼ [CYS-PET egg-map: ÈËÅ¼±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 5]
g_petList[30309935] = {type=1, dataId=24609, level=1}	--ÕäÊÞµ°£ºè¯ÁéÈËÅ¼ [CYS-PET egg-map: è¯ÁéÈËÅ¼±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 45]
g_petList[30309936] = {type=1, dataId=24619, level=1}	--ÕäÊÞµ°£ºÐÇÚ¤ÈËÅ¼ [CYS-PET egg-map: ÐÇÚ¤ÈËÅ¼±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 55]
g_petList[30309937] = {type=1, dataId=24629, level=1}	--ÕäÊÞµ°£ºÎäÐþÈËÅ¼ [CYS-PET egg-map: ÎäÐþÈËÅ¼±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 65]
g_petList[30309938] = {type=1, dataId=24639, level=1}	--ÕäÊÞµ°£ºÑÖÉñÈËÅ¼ [CYS-PET egg-map: ÑÖÉñÈËÅ¼±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 75]
g_petList[30309939] = {type=1, dataId=24649, level=1}	--ÕäÊÞµ°£ºèóÊ¥ÈËÅ¼ [CYS-PET egg-map: èóÊ¥ÈËÅ¼±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 85]
g_petList[30309940] = {type=1, dataId=24659, level=1}	--ÕäÊÞµ°£ºÍ¨ÌìÈËÅ¼ [CYS-PET egg-map: Í¨ÌìÈËÅ¼±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 95]
g_petList[30309941] = {type=1, dataId=24669, level=1}	--ÕäÊÞµ°£º¶¹¶¹Áú [CYS-PET egg-map: ¶¹¶¹Áú±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 5]
g_petList[30309942] = {type=1, dataId=22219, level=1}	--ÕäÊÞµ°£º±ÈÒíÄñ [CYS-PET egg-map: ±ÈÒíÄñ±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 5]
g_petList[30309943] = {type=1, dataId=22289, level=1}	--ÕäÊÞµ°£º´ô´ôÅ£ [CYS-PET egg-map: ´ô´ôÅ£±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 5]
g_petList[30309944] = {type=1, dataId=24669, level=1}	--ÕäÊÞµ°£º¶¹¶¹Áú [CYS-PET egg-map: ¶¹¶¹Áú±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 5]
g_petList[30309945] = {type=1, dataId=24679, level=1}	--ÕäÊÞµ°£º¶¹¶¹Áú [CYS-PET egg-map: ¶¹¶¹Áú±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 45]
g_petList[30309946] = {type=1, dataId=24689, level=1}	--ÕäÊÞµ°£º¶¹¶¹Áú [CYS-PET egg-map: ¶¹¶¹Áú±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 55]
g_petList[30309947] = {type=1, dataId=24699, level=1}	--ÕäÊÞµ°£º¶¹¶¹Áú [CYS-PET egg-map: ¶¹¶¹Áú±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 65]
g_petList[30309948] = {type=1, dataId=24709, level=1}	--ÕäÊÞµ°£º¶¹¶¹Áú [CYS-PET egg-map: ¶¹¶¹Áú±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 75]
g_petList[30309949] = {type=1, dataId=24719, level=1}	--ÕäÊÞµ°£º¶¹¶¹Áú [CYS-PET egg-map: ¶¹¶¹Áú±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 85]
g_petList[30309950] = {type=1, dataId=24729, level=1}	--ÕäÊÞµ°£º¶¹¶¹Áú [CYS-PET egg-map: ¶¹¶¹Áú±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 95]
g_petList[30309951] = {type=1, dataId=24739, level=1}	--ÕäÊÞµ°£º³öÔÆÁúòþ [CYS-PET egg-map: ³öÔÆÁúòþ±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 5]
g_petList[30309952] = {type=1, dataId=24749, level=1}	--ÕäÊÞµ°£º³öÔÆÁúòþ [CYS-PET egg-map: ³öÔÆÁúòþ±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 45]
g_petList[30309953] = {type=1, dataId=24759, level=1}	--ÕäÊÞµ°£º³öÔÆÁúòþ [CYS-PET egg-map: ³öÔÆÁúòþ±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 55]
g_petList[30309954] = {type=1, dataId=24769, level=1}	--ÕäÊÞµ°£º³öÔÆÁúòþ [CYS-PET egg-map: ³öÔÆÁúòþ±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 65]
g_petList[30309955] = {type=1, dataId=24779, level=1}	--ÕäÊÞµ°£º³öÔÆÁúòþ [CYS-PET egg-map: ³öÔÆÁúòþ±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 75]
g_petList[30309956] = {type=1, dataId=24789, level=1}	--ÕäÊÞµ°£º³öÔÆÁúòþ [CYS-PET egg-map: ³öÔÆÁúòþ±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 85]
g_petList[30309957] = {type=1, dataId=24799, level=1}	--ÕäÊÞµ°£º³öÔÆÁúòþ [CYS-PET egg-map: ³öÔÆÁúòþ±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 95]
g_petList[30309958] = {type=1, dataId=24819, level=1}	--ÕäÊÞµ°£º°ÁÔÆ²ÔÁú [CYS-PET egg-map: °ÁÔÆ²ÔÁú±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 5]
g_petList[30309959] = {type=1, dataId=24829, level=1}	--ÕäÊÞµ°£º°ÁÔÆ²ÔÁú [CYS-PET egg-map: °ÁÔÆ²ÔÁú±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 45]
g_petList[30309960] = {type=1, dataId=24839, level=1}	--ÕäÊÞµ°£º°ÁÔÆ²ÔÁú [CYS-PET egg-map: °ÁÔÆ²ÔÁú±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 55]
g_petList[30309961] = {type=1, dataId=24849, level=1}	--ÕäÊÞµ°£º°ÁÔÆ²ÔÁú [CYS-PET egg-map: °ÁÔÆ²ÔÁú±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 65]
g_petList[30309962] = {type=1, dataId=24859, level=1}	--ÕäÊÞµ°£º°ÁÔÆ²ÔÁú [CYS-PET egg-map: °ÁÔÆ²ÔÁú±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 75]
g_petList[30309963] = {type=1, dataId=24869, level=1}	--ÕäÊÞµ°£º°ÁÔÆ²ÔÁú [CYS-PET egg-map: °ÁÔÆ²ÔÁú±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 85]
g_petList[30309965] = {type=1, dataId=24819, level=1}	--ÕäÊÞµ°£º°ÁÔÆ²ÔÁú [CYS-PET egg-map: °ÁÔÆ²ÔÁú±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 5]
g_petList[30309966] = {type=1, dataId=24889, level=1}	--ÕäÊÞµ°£ºÌ«¹ÅÁú»ê [CYS-PET egg-map: Ì«¹ÅÁú»ê±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 5]
g_petList[30309967] = {type=1, dataId=24899, level=1}	--ÕäÊÞµ°£ºÌ«¹ÅÁú»ê [CYS-PET egg-map: Ì«¹ÅÁú»ê±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 45]
g_petList[30309968] = {type=1, dataId=24909, level=1}	--ÕäÊÞµ°£ºÌ«¹ÅÁú»ê [CYS-PET egg-map: Ì«¹ÅÁú»ê±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 55]
g_petList[30309969] = {type=1, dataId=24919, level=1}	--ÕäÊÞµ°£ºÌ«¹ÅÁú»ê [CYS-PET egg-map: Ì«¹ÅÁú»ê±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 65]
g_petList[30309970] = {type=1, dataId=24929, level=1}	--ÕäÊÞµ°£ºÌ«¹ÅÁú»ê [CYS-PET egg-map: Ì«¹ÅÁú»ê±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 75]
g_petList[30309971] = {type=1, dataId=24939, level=1}	--ÕäÊÞµ°£ºÌ«¹ÅÁú»ê [CYS-PET egg-map: Ì«¹ÅÁú»ê±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 85]
g_petList[30309973] = {type=1, dataId=24889, level=1}	--ÕäÊÞµ°£ºÌ«¹ÅÁú»ê [CYS-PET egg-map: Ì«¹ÅÁú»ê±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 5]
g_petList[30309977] = {type=1, dataId=27169, level=1}	--ÕäÊÞµ°£ºßãÐ¡ÃÈ [CYS-PET egg-map: ßãÐ¡ÃÈ±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 55]
g_petList[30309978] = {type=1, dataId=27209, level=1}	--ÕäÊÞµ°£ºßãÐ¡ÃÈ [CYS-PET egg-map: ßãÐ¡ÃÈ±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 95]
g_petList[30309979] = {type=1, dataId=27229, level=1}	--ÕäÊÞµ°£ºÃÀÈËÓã [CYS-PET egg-map: ÃÀÈËÓã±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 5]
g_petList[30309980] = {type=1, dataId=27299, level=1}	--ÕäÊÞµ°£ºÌìÅîÀ¿ÔÂ [CYS-PET egg-map: ÌìÅîÀ¿ÔÂ±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 5]
g_petList[30309984] = {type=1, dataId=23049, level=1}	--ÕäÊÞµ°£º»¨ÏÉ×Ó [CYS-PET egg-map: »¨ÏÉ×Ó±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 5]
g_petList[30309995] = {type=1, dataId=24339, level=1}	--ÕäÊÞµ°£º½õÃ«Êó [CYS-PET egg-map: ½õÃ«Êó±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 5]
g_petList[30504318] = {type=1, dataId=23709, level=1}	--ÕäÊÞµ°£º½©Ê¬ [CYS-PET egg-map: ½©Ê¬±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 5]
g_petList[30504319] = {type=1, dataId=23789, level=1}	--ÕäÊÞµ°£º½©Ê¬ [CYS-PET egg-map: ½©Ê¬±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 45]
g_petList[30504320] = {type=1, dataId=23799, level=1}	--ÕäÊÞµ°£º½©Ê¬ [CYS-PET egg-map: ½©Ê¬±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 55]
g_petList[30504321] = {type=1, dataId=23809, level=1}	--ÕäÊÞµ°£º½©Ê¬ [CYS-PET egg-map: ½©Ê¬±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 65]
g_petList[30504322] = {type=1, dataId=23819, level=1}	--ÕäÊÞµ°£º½©Ê¬ [CYS-PET egg-map: ½©Ê¬±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 75]
g_petList[30504323] = {type=1, dataId=23829, level=1}	--ÕäÊÞµ°£º½©Ê¬ [CYS-PET egg-map: ½©Ê¬±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 85]
g_petList[30504325] = {type=1, dataId=23409, level=1}	--ÕäÊÞµ°£ºÐÜÃ¨Ë«ÏÀ [CYS-PET egg-map: ÐÜÃ¨Ë«ÏÀ±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 5]
g_petList[30504326] = {type=1, dataId=28479, level=1}	--ÕäÊÞµ°£ºÇàÑòÕæ¾ý [CYS-PET egg-map: ÇàÑòÕæ¾ý±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 5]
g_petList[30504327] = {type=1, dataId=30319, level=1}	--ÕäÊÞµ°£ºÖÉÔÂÁé [CYS-PET egg-map: ÖÉÔÂÁé±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 95]
g_petList[30504328] = {type=1, dataId=23259, level=1}	--ÕäÊÞµ°£º²¼ÀÏ»¢ [CYS-PET egg-map: ²¼ÀÏ»¢±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 5]
g_petList[30504329] = {type=1, dataId=31459, level=1}	--ÕäÊÞµ°£ºÀêÃÀÈË [CYS-PET egg-map: ÀêÃÀÈË±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 95]
g_petList[30504330] = {type=1, dataId=31419, level=1}	--ÕäÊÞµ°£ºÀêÃÀÈË [CYS-PET egg-map: ÀêÃÀÈË±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 55]
g_petList[30505230] = {type=1, dataId=8759, level=1}	--ÕäÊÞµ°£ºÌÆ×°Êó [CYS-PET egg-map: ÌÆ×°Êó±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 45]
g_petList[30505231] = {type=1, dataId=8779, level=1}	--ÕäÊÞµ°£ºÌÆ×°Êó [CYS-PET egg-map: ÌÆ×°Êó±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 65]
g_petList[30505232] = {type=1, dataId=8799, level=1}	--ÕäÊÞµ°£ºÌÆ×°Êó [CYS-PET egg-map: ÌÆ×°Êó±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 85]
g_petList[38001941] = {type=1, dataId=8819, level=1}	--ÕäÊÞµ°£ºÄêÊÞ [CYS-PET egg-map: ÄêÊÞ±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 5]
g_petList[39910078] = {type=1, dataId=30399, level=1}	--ÕäÊÞµ°£º¶«×Ð [CYS-PET egg-map: ¶«×Ð±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 20]
g_petList[39910079] = {type=1, dataId=30469, level=1}	--ÕäÊÞµ°£ºÁúÈýÌ«×Ó [CYS-PET egg-map: ÁúÈýÌ«×Ó±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 95]
g_petList[39910080] = {type=1, dataId=30569, level=1}	--ÕäÊÞµ°£ººüÐ¡ÏÉ [CYS-PET egg-map: ºüÐ¡ÏÉ±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 95]
g_petList[39910081] = {type=1, dataId=30719, level=1}	--ÕäÊÞµ°£ºÁé÷È¶ù [CYS-PET egg-map: Áé÷È¶ù±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 95]
g_petList[39910082] = {type=1, dataId=30719, level=1}	--ÕäÊÞµ°£ºÁé÷È¶ù [CYS-PET egg-map: Áé÷È¶ù±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 95]
g_petList[39910085] = {type=1, dataId=30949, level=1}	--ÕäÊÞµ°£ºÃîÊóÐ¡ÏÉ [CYS-PET egg-map: ÃîÊóÐ¡ÏÉ±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 95]
g_petList[39910086] = {type=1, dataId=31019, level=1}	--ÕäÊÞµ°£ºÉñ»úÐ¡×Ó [CYS-PET egg-map: Éñ»úÐ¡×Ó±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 95]
g_petList[39910088] = {type=1, dataId=31159, level=1}	--ÕäÊÞµ°£ºÁéÖé×Ó [CYS-PET egg-map: ÁéÖé×Ó±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 95]
g_petList[39910091] = {type=1, dataId=23639, level=1}	--ÕäÊÞµ°£º¿þÀÜÀÇ [CYS-PET egg-map: ¿þÀÜÀÇ±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 5]
g_petList[39910094] = {type=1, dataId=31319, level=1}	--ÕäÊÞµ°£ºµ°µ°¼¦ [CYS-PET egg-map: µ°µ°¼¦±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 5]
g_petList[39910096] = {type=1, dataId=30249, level=1}	--ÕäÊÞµ°£ºÆëÌì´óÊ¥ [CYS-PET egg-map: ÆëÌì´óÊ¥±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 95]
g_petList[39910097] = {type=1, dataId=23699, level=1}	--ÕäÊÞµ°£º¿þÀÜÀÇ [CYS-PET egg-map: ¿þÀÜÀÇ±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 95]
g_petList[39910098] = {type=1, dataId=31379, level=1}	--ÕäÊÞµ°£ºµ°µ°¼¦ [CYS-PET egg-map: µ°µ°¼¦±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 95]
g_petList[39910104] = {type=1, dataId=34529, level=1}	--ÕäÊÞµ°£ºÌ«°×Â¹Áé [CYS-PET egg-map: Ì«°×Â¹Áé±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 95]
g_petList[39910107] = {type=1, dataId=34469, level=1}	--ÕäÊÞµ°£ºÌ«°×Â¹Áé [CYS-PET egg-map: Ì«°×Â¹Áé±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 5]
g_petList[39910113] = {type=1, dataId=27639, level=1}	--ÕäÊÞµ°£ºæ´»ÊÁúòþ [CYS-PET egg-map: æ´»ÊÁúòþ±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 5]
g_petList[39910114] = {type=1, dataId=34689, level=1}	--ÕäÊÞµ°£ºÃî·¨Ð¡É® [CYS-PET egg-map: Ãî·¨Ð¡É®±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 5]
g_petList[39910124] = {type=1, dataId=35249, level=1}	--ÕäÊÞµ°£º°Ù±äÐÜÃ¨ [CYS-PET egg-map: °Ù±äÐÜÃ¨±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 5]
g_petList[39910134] = {type=1, dataId=29619, level=1}	--ÕäÊÞµ°£ºÐ°Áé [CYS-PET egg-map: Ð°Áé±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 5]
g_petList[39910139] = {type=1, dataId=30409, level=1}	--ÕäÊÞµ°£ºÁúÈýÌ«×Ó [CYS-PET egg-map: ÁúÈýÌ«×Ó±¦±¦, ten+¿ÉÐ¯´øµÈ¼¶ 5]
function common_item:IsSkillLikeScript()
    return 1
end

function common_item:CancelImpacts()
    return 0
end

function common_item:OnConditionCheck(selfId)
	-- æ ¡éªŒä½¿ç”¨çš„ç‰©å“?
	if not self:LuaFnVerifyUsedItem(selfId )then
		self:notify_tips( selfId, "Äáº?o cá»? chÆ°a má»?, khÃ´ng thá»? sá»? dá»?ng.")
		return 0
	end
	local checkCreatePet = self:TryCreatePet(selfId, 1)
	if not checkCreatePet then
		self:notify_tips( selfId, "NgÆ°Æ¡i khÃ´ng thá»? mang thÃªm TrÃ¢n thÃº.")
		return 0
	end
	local itemTblIndex = self:LuaFnGetItemIndexOfUsedItem(selfId)
	local petItem = g_petList[itemTblIndex]
	if not petItem then
		self:notify_tips( selfId, "Äáº?o cá»? chÆ°a má»?, khÃ´ng thá»? sá»? dá»?ng.")
		return 0
	end
	--[[if petItem.type ~= 2 then
	    local takeLevel = self:GetPetTakeLevel(petItem.dataId)
	    local humanLevel = self:GetLevel(selfId)
	    if not takeLevel or not humanLevel or takeLevel > humanLevel then
		    self:notify_tips( selfId, "ä½ çš„ç­‰çº§ä¸èƒ½æ¯”çå…½çš„æºå¸¦ç­‰çº§ä½Žã??")
		    return 0
	    end
	end]]
	return 1
end

function common_item:OnDeplete(selfId)
    return 1
end

function common_item:OnActivateOnce(selfId)
	--åˆ é™¤å‰ä¿å­˜Trans....
	local BagIndex = self:LuaFnGetBagIndexOfUsedItem(selfId)
	local itemTblIndex = self:LuaFnGetItemIndexOfUsedItem(selfId )
	if self:LuaFnGetItemTableIndexByIndex(selfId,BagIndex) ~= itemTblIndex then
		self:notify_tips(selfId, "DÃ¹ng Ä‘áº?o cá»? báº?t thÆ°á»ng, khÃ´ng dÃ¹ng Ä‘Æ°á»?c.")
		return 0
	end
	local petItem = g_petList[itemTblIndex];
	if not petItem then
		self:notify_tips(selfId, "Äáº?o cá»? chÆ°a má»?, khÃ´ng thá»? sá»? dá»?ng.")
		return 0
	end
	local params
	local pet_space
	local fun_name
	local pet_type = petItem.type
	if pet_type == 1 then
		fun_name = "CreateRMBPetToHuman34534"
		pet_space = 1
		if petItem.dataIds then
			params = petItem.dataIds
		else
			params = petItem.dataId
		end
	elseif pet_type == 2 then
		fun_name = "Create2RMBPetToHuman34534"
		pet_space = 2
		params = petItem.dataIds
	else
		pet_space = 1
		params = petItem.dataId
	end
	if pet_space and params then
		local ItemInfo = self:GetBagItemTransfer(selfId, BagIndex )
		local checkCreatePet = self:TryCreatePet(selfId,pet_space)
		if not checkCreatePet then
			self:notify_tips(selfId, "NgÆ°Æ¡i khÃ´ng thá»? mang thÃªm TrÃ¢n thÃº.")
			return 0
		end
		if fun_name then
			if type(params) == "number" then
				if not params or not self:GetIsPetID(params) then
					self:notify_tips(selfId, "ID trÃ¢n thÃº khÃ´ng tá»“n táº?i.")
					return 0
				end
				self:EraseItem(selfId, BagIndex)
				local ret, petGUID_H, petGUID_L = self:CallScriptFunction(800105, fun_name, selfId, params, petItem.level)
				if ret then
					self:OnGivePlayerPet(selfId, params, petGUID_H, petGUID_L, ItemInfo)
				end
				return 1
			elseif type(params) == "table" then
				local level = self:GetLevel(selfId)
				for _, pet in pairs(params) do
					if level >= pet.minHumanLevel and level <= pet.maxHumanLevel  then
						if not self:GetIsPetID(pet.dataId) then
							self:notify_tips(selfId, "ID trÃ¢n thÃº khÃ´ng tá»“n táº?i.")
							return 0
						end
						self:EraseItem(selfId, BagIndex)
						local ret, petGUID_H, petGUID_L = self:CallScriptFunction(800105, fun_name, selfId, pet.dataId, petItem.level)
						if ret then
							if pet_space == 1 then
								self:OnGivePlayerPet(selfId, pet.dataId, petGUID_H, petGUID_L, ItemInfo)
							else
								for i = 1,pet_space do
									self:OnGivePlayerPet(selfId, pet.dataId, petGUID_H[i], petGUID_L[i], ItemInfo )
								end
							end
						end
						return 1
					end
				end
			end
		else
			if not self:GetIsPetID(params) then
				self:notify_tips(selfId, "ID trÃ¢n thÃº khÃ´ng tá»“n táº?i.")
				return 0
			end
			self:EraseItem(selfId, BagIndex)
			local ret, petGUID_H, petGUID_L = self:LuaFnCreatePetToHuman(selfId, params, true)
			if ret then
				self:OnGivePlayerPet(selfId, params, petGUID_H, petGUID_L, ItemInfo )
			end
			return 1
		end
	end
	self:notify_tips(selfId, "Lá»—i khÃ´ng xÃ¡c Ä‘á»‹nh.")
	return 0
end

function common_item:OnGivePlayerPet(selfId, petId, petGUID_H, petGUID_L, ItemInfo )
	local petName = self:GetPetName(petId)
	if petName then
		self:notify_tips(selfId, "ChÃºc má»«ng ngÃ i Ä‘Ã£ thÃ nh cÃ´ng nháº­n Ä‘Æ°á»?c"..petName.."ï¼?")
	end
	self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 18, 0)
	local player_name = self:GetName(selfId)
	player_name = gbk.fromutf8(player_name)
	--æ¯›é©´å…?å‘?....
	if petId == 3399 or petId == 8969 or petId == 8979 or petId == 8989 then
		local szPetTrans = self:GetPetTransString(selfId, petGUID_H, petGUID_L )
		local Msg = "#{_INFOUSR%s}#R sá»? dá»?ng #{_INFOMSG%s}#R nháº­n Ä‘Æ°á»?c má»™t #{_INFOMSG%s}#R."
		local str = string.format(Msg, player_name, ItemInfo, szPetTrans )
		self:BroadMsgByChatPipe(selfId, str, 4)
		return
	end
	--å”è?…é¼ å…?å‘?....
	if petId == 8759 or petId == 8789 or petId == 8799  then
		local szPetTrans = self:GetPetTransString(selfId, petGUID_H, petGUID_L )
		local Msg = "#{_INFOUSR%s}#{TZS_16}#{_INFOMSG%s}#{TZS_17}#{_INFOUSR%s}#{TZS_18}"
		local str = string.format( Msg, player_name, szPetTrans, player_name )
		self:BroadMsgByChatPipe(selfId, str, 4)
		return
	end
	--ç©·å?‡å…¬å‘?....
	if petId == 22059 then
		local szPetTrans = self:GetPetTransString(selfId, petGUID_H, petGUID_L )
		local Msg = "#{_INFOUSR%s}#{XZS_01}#{_INFOMSG%s}#{XZS_02}#{_INFOMSG%s}#{XZS_03}"
		local str = string.format( Msg, player_name, ItemInfo, szPetTrans )
		self:BroadMsgByChatPipe(selfId, str, 4)
		return
	end
	--å°ç‹ä»™å…¬å‘?....
	if petId == 22129 then
		local szPetTrans = self:GetPetTransString(selfId, petGUID_H, petGUID_L )
		local Msg = "#{_INFOUSR%s}#{XZS_04}#{_INFOMSG%s}#{XZS_05}#{_INFOMSG%s}#{XZS_06}"
		local str = string.format( Msg, player_name, ItemInfo, szPetTrans )
		self:BroadMsgByChatPipe(selfId, str, 4)
		return
	end
	--é¸³é¸¯å…?å‘?... zchw
	if (petId == 8889) or (petId == 8899) or (petId == 8909) or (petId == 8919) or (petId == 8929) or(petId == 8939) or (petId == 8949) then
		local szPetTrans = self:GetPetTransString(selfId, petGUID_H, petGUID_L )
		local Msg = "#{_INFOUSR%s}#{XZS_07}#{_INFOMSG%s}#{XZS_08}#{_INFOMSG%s}#{XZS_09}"
		local str = string.format(Msg, player_name, ItemInfo, szPetTrans )
		self:BroadMsgByChatPipe(selfId, str, 4)
		return
	end
	--å‘†å‘†ç‰›å…¬å‘?... hzp
	if (petId == 22289) or (petId == 22299) or (petId == 22309) or (petId == 22319) or (petId == 22329) or(petId == 22339) or (petId == 22349) then
		local szPetTrans = self:GetPetTransString(selfId, petGUID_H, petGUID_L )
		local Msg = "#{_INFOUSR%s}#{XZS_04}#{_INFOMSG%s}#{XZS_10}#{_INFOMSG%s}#{XZS_11}"
		local str = string.format( Msg, player_name, ItemInfo, szPetTrans )
		self:BroadMsgByChatPipe(selfId, str, 4)
		return
	end
	--æ¬?ä¹çŒªå…?å‘?... hzp
	if (petId == 8569) or (petId == 8579) or (petId == 8589) or (petId == 8599) or (petId == 8609) or(petId == 8619) or (petId == 8629) then
		local szPetTrans =self: GetPetTransString(selfId, petGUID_H, petGUID_L )
		local Msg = "#{_INFOUSR%s}#{XZS_12}#{_INFOMSG%s}#{XZS_13}#{_INFOMSG%s}#{XZS_14}"
		local str = string.format(Msg, player_name, ItemInfo, szPetTrans )
		self:BroadMsgByChatPipe(selfId, str, 4)
		return
	end
	--æ¯”ç¿¼é¸Ÿå…¬å‘?... hzp
	if (petId == 22219) or (petId == 22229) or (petId == 22239) or (petId == 22249) or (petId == 22259) or(petId == 22269) or (petId == 22279) then
		local szPetTrans = self:GetPetTransString(selfId, petGUID_H, petGUID_L )
		local Msg = "#{_INFOUSR%s}#{XZS_15}#{_INFOMSG%s}#{XZS_16}#{_INFOMSG%s}#{DSSJ_4}"
		local str = string.format(Msg, player_name, ItemInfo, szPetTrans )
		self:BroadMsgByChatPipe(selfId, str, 4)
		return
	end
	local szPetTrans = self:GetPetTransString(selfId, petGUID_H, petGUID_L )
	local Msg = "#{_INFOUSR%s}#{XZS_12}#{_INFOMSG%s}#{XZS_13}#{_INFOMSG%s}#{XZS_14}"
	local str = string.format(Msg, player_name, ItemInfo, szPetTrans )
	self:BroadMsgByChatPipe(selfId, str, 4)
end

return common_item