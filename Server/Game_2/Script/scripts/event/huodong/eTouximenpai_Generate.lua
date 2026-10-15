--偷袭门派
--普通
local gbk = require "wire_charset"
local class = require "class"
local define = require "define"
local script_base = require "script_base"
local eTouximenpai_Generate = class("eTouximenpai_Generate", script_base)
eTouximenpai_Generate.DataValidator = 0
--所拥有的事件ID列表
eTouximenpai_Generate.g_EventList = {808017}
--接取任务的最低等级
eTouximenpai_Generate.g_minLevel = 20
--活动每次tick时间
eTouximenpai_Generate.g_TimeTickIndex = 0
--后刷出的怪物的数量
eTouximenpai_Generate.g_RefreshMonsterNum = 5
--15分钟后刷出的怪物的位置
eTouximenpai_Generate.g_DLPosInfoList = {
	{
		sceneId = 9,
		sceneName = "少林",
		G1posList = {
			{x = 61, z = 55, r = 3},
			{x = 80, z = 60, r = 3},
			{x = 147, z = 111, r = 3},
			{x = 155, z = 143, r = 3},
			{x = 63, z = 102, r = 3}
		},
		G2posList = {
			{x = 66, z = 120, r = 3},
			{x = 121, z = 58, r = 3},
			{x = 154, z = 52, r = 3},
			{x = 154, z = 72, r = 3},
			{x = 145, z = 80, r = 3}
		}
	},
	{
		sceneId = 10,
		sceneName = "丐帮",
		G1posList = {
			{x = 50, z = 150, r = 3},
			{x = 60, z = 150, r = 3},
			{x = 54, z = 136, r = 3},
			{x = 57, z = 110, r = 3},
			{x = 70, z = 102, r = 3}
		},
		G2posList = {
			{x = 114, z = 93, r = 3},
			{x = 133, z = 83, r = 3},
			{x = 154, z = 63, r = 3},
			{x = 155, z = 46, r = 3},
			{x = 111, z = 36, r = 3}
		}
	},
	{
		sceneId = 11,
		sceneName = "明教",
		G1posList = {
			{x = 36, z = 153, r = 3},
			{x = 36, z = 147, r = 3},
			{x = 36, z = 112, r = 3},
			{x = 28, z = 98, r = 3},
			{x = 39, z = 76, r = 3}
		},
		G2posList = {
			{x = 110, z = 63, r = 3},
			{x = 131, z = 55, r = 3},
			{x = 156, z = 49, r = 3},
			{x = 155, z = 115, r = 3},
			{x = 115, z = 153, r = 3}
		}
	},
	{
		sceneId = 12,
		sceneName = "武当",
		G1posList = {
			{x = 43, z = 95, r = 3},
			{x = 40, z = 55, r = 3},
			{x = 68, z = 182, r = 3},
			{x = 55, z = 179, r = 3},
			{x = 43, z = 168, r = 3}
		},
		G2posList = {
			{x = 45, z = 146, r = 3},
			{x = 95, z = 126, r = 3},
			{x = 108, z = 128, r = 3},
			{x = 93, z = 112, r = 3},
			{x = 86, z = 84, r = 3}
		}
	},
	{
		sceneId = 13,
		sceneName = "天龙",
		G1posList = {
			{x = 65, z = 150, r = 3},
			{x = 64, z = 152, r = 3},
			{x = 42, z = 136, r = 3},
			{x = 37, z = 131, r = 3},
			{x = 23, z = 126, r = 3}
		},
		G2posList = {
			{x = 40, z = 100, r = 3},
			{x = 50, z = 100, r = 3},
			{x = 64, z = 91, r = 3},
			{x = 65, z = 73, r = 3},
			{x = 50, z = 75, r = 3}
		}
	},
	{
		sceneId = 14,
		sceneName = "逍遥",
		G1posList = {
			{x = 39, z = 150, r = 3},
			{x = 52, z = 149, r = 3},
			{x = 67, z = 152, r = 3},
			{x = 74, z = 153, r = 3},
			{x = 150, z = 151, r = 3}
		},
		G2posList = {
			{x = 152, z = 136, r = 3},
			{x = 153, z = 129, r = 3},
			{x = 152, z = 115, r = 3},
			{x = 115, z = 94, r = 3},
			{x = 132, z = 154, r = 3}
		}
	},
	{
		sceneId = 15,
		sceneName = "Nga Mi",
		G1posList = {
			{x = 100, z = 145, r = 3},
			{x = 84, z = 145, r = 3},
			{x = 63, z = 140, r = 3},
			{x = 60, z = 150, r = 3},
			{x = 62, z = 155, r = 3}
		},
		G2posList = {
			{x = 35, z = 152, r = 3},
			{x = 55, z = 129, r = 3},
			{x = 53, z = 91, r = 3},
			{x = 54, z = 51, r = 3},
			{x = 35, z = 59, r = 3}
		}
	},
	{
		sceneId = 16,
		sceneName = "星宿",
		G1posList = {
			{x = 43, z = 148, r = 3},
			{x = 43, z = 132, r = 3},
			{x = 57, z = 118, r = 3},
			{x = 70, z = 109, r = 3},
			{x = 80, z = 119, r = 3}
		},
		G2posList = {
			{x = 109, z = 133, r = 3},
			{x = 128, z = 147, r = 3},
			{x = 139, z = 149, r = 3},
			{x = 149, z = 143, r = 3},
			{x = 147, z = 124, r = 3}
		}
	},
	{
		sceneId = 17,
		sceneName = "天山",
		G1posList = {
			{x = 43, z = 146, r = 3},
			{x = 50, z = 140, r = 3},
			{x = 47, z = 132, r = 3},
			{x = 60, z = 126, r = 3},
			{x = 42, z = 124, r = 3}
		},
		G2posList = {
			{x = 34, z = 110, r = 3},
			{x = 33, z = 100, r = 3},
			{x = 67, z = 82, r = 3},
			{x = 126, z = 44, r = 3},
			{x = 131, z = 52, r = 3}
		}
	},
	{
		sceneId = 184,
		sceneName = "曼陀山庄",
		G1posList = {
			{x = 145, z = 137, r = 3},
			{x = 127, z = 139, r = 3},
			{x = 109, z = 125, r = 3},
			{x = 160, z = 110, r = 3},
			{x = 117, z = 102, r = 3}
		},
		G2posList = {
			{x = 99, z = 102, r = 3},
			{x = 85, z = 97, r = 3},
			{x = 74, z = 80, r = 3},
			{x = 72, z = 67, r = 3},
			{x = 77, z = 65, r = 3}
		}
	},
	{
		sceneId = 987,
		sceneName = "恶人谷",
		G1posList = {
			{x = 130, z = 155, r = 3},
			{x = 120, z = 148, r = 3},
			{x = 110, z = 140, r = 3},
			{x = 135, z = 135, r = 3},
			{x = 125, z = 130, r = 3}
		},
		G2posList = {
			{x = 100, z = 125, r = 3},
			{x = 90, z = 120, r = 3},
			{x = 80, z = 115, r = 3},
			{x = 70, z = 110, r = 3},
			{x = 60, z = 105, r = 3}
		}
	},
	{
		sceneId = 1358,
		sceneName = "慕容山庄",
		G1posList = {
			{x = 35, z = 140, r = 3},
			{x = 30, z = 135, r = 3},
			{x = 25, z = 128, r = 3},
			{x = 40, z = 125, r = 3},
			{x = 33, z = 120, r = 3}
		},
		G2posList = {
			{x = 20, z = 115, r = 3},
			{x = 15, z = 110, r = 3},
			{x = 45, z = 105, r = 3},
			{x = 50, z = 100, r = 3},
			{x = 38, z = 95, r = 3}
		}
	}
}

eTouximenpai_Generate.g_scenePosInfoList = {
	{
		sceneId = 9,
		sceneLeader = "玄慈",
		sceneName = "少林",
		minL = 30,
		maxL = 45,
		posList = {
			{x = 42, z = 48, r = 3},
			{x = 41, z = 55, r = 3},
			{x = 42, z = 65, r = 3},
			{x = 42, z = 74, r = 3},
			{x = 129, z = 56, r = 5},
			{x = 42, z = 100, r = 5},
			{x = 42, z = 121, r = 3},
			{x = 48, z = 139, r = 3},
			{x = 54, z = 146, r = 3},
			{x = 68, z = 148, r = 3},
			{x = 42, z = 130, r = 3},
			{x = 66, z = 102, r = 10},
			{x = 66, z = 120, r = 3},
			{x = 55, z = 98, r = 3},
			{x = 64, z = 87, r = 5},
			{x = 70, z = 90, r = 5},
			{x = 79, z = 96, r = 5},
			{x = 79, z = 108, r = 3},
			{x = 85, z = 105, r = 3},
			{x = 95, z = 110, r = 5},
			{x = 95, z = 120, r = 5},
			{x = 95, z = 129, r = 3},
			{x = 103, z = 106, r = 5},
			{x = 113, z = 106, r = 3},
			{x = 117, z = 116, r = 3},
			{x = 116, z = 125, r = 3},
			{x = 125, z = 102, r = 8},
			{x = 150, z = 67, r = 8},
			{x = 149, z = 99, r = 6},
			{x = 153, z = 144, r = 6}
		}
	},
	{
		sceneId = 10,
		sceneLeader = "宋慈",
		sceneName = "丐帮",
		minL = 46,
		maxL = 60,
		posList = {
			{x = 46, z = 36, r = 5},
			{x = 39, z = 60, r = 5},
			{x = 45, z = 76, r = 3},
			{x = 45, z = 90, r = 5},
			{x = 45, z = 113, r = 8},
			{x = 49, z = 198, r = 8},
			{x = 72, z = 140, r = 3},
			{x = 83, z = 141, r = 4},
			{x = 101, z = 141, r = 4},
			{x = 91, z = 124, r = 4},
			{x = 72, z = 115, r = 6},
			{x = 72, z = 106, r = 5},
			{x = 71, z = 97, r = 5},
			{x = 97, z = 106, r = 3},
			{x = 86, z = 106, r = 3},
			{x = 79, z = 60, r = 5},
			{x = 104, z = 61, r = 5},
			{x = 92, z = 46, r = 3},
			{x = 54, z = 55, r = 3},
			{x = 86, z = 36, r = 3},
			{x = 110, z = 37, r = 5},
			{x = 125, z = 63, r = 5},
			{x = 127, z = 37, r = 3},
			{x = 154, z = 50, r = 4},
			{x = 154, z = 62, r = 4},
			{x = 134, z = 82, r = 4},
			{x = 149, z = 113, r = 4},
			{x = 149, z = 140, r = 10},
			{x = 132, z = 150, r = 5},
			{x = 112, z = 110, r = 5}
		}
	},
	{
		sceneId = 11,
		sceneLeader = "林世长",
		sceneName = "明教",
		minL = 61,
		maxL = 75,
		posList = {
			{x = 38, z = 38, r = 6},
			{x = 35, z = 53, r = 6},
			{x = 39, z = 77, r = 5},
			{x = 36, z = 87, r = 4},
			{x = 35, z = 97, r = 5},
			{x = 37, z = 113, r = 4},
			{x = 38, z = 140, r = 5},
			{x = 40, z = 153, r = 5},
			{x = 50, z = 154, r = 5},
			{x = 60, z = 154, r = 5},
			{x = 62, z = 141, r = 4},
			{x = 81, z = 153, r = 5},
			{x = 81, z = 139, r = 5},
			{x = 97, z = 147, r = 7},
			{x = 97, z = 110, r = 5},
			{x = 98, z = 89, r = 3},
			{x = 99, z = 70, r = 10},
			{x = 84, z = 71, r = 5},
			{x = 110, z = 69, r = 5},
			{x = 114, z = 136, r = 5},
			{x = 114, z = 152, r = 5},
			{x = 159, z = 140, r = 5},
			{x = 140, z = 117, r = 5},
			{x = 154, z = 118, r = 5},
			{x = 155, z = 99, r = 5},
			{x = 143, z = 78, r = 5},
			{x = 155, z = 50, r = 4},
			{x = 155, z = 36, r = 4},
			{x = 115, z = 39, r = 5},
			{x = 80, z = 39, r = 5}
		}
	},
	{
		sceneId = 12,
		sceneLeader = "张玄素",
		sceneName = "武当",
		minL = 76,
		maxL = 90,
		posList = {
			{x = 40, z = 55, r = 3},
			{x = 54, z = 57, r = 4},
			{x = 63, z = 61, r = 6},
			{x = 45, z = 70, r = 3},
			{x = 45, z = 78, r = 3},
			{x = 45, z = 94, r = 4},
			{x = 63, z = 99, r = 5},
			{x = 78, z = 112, r = 10},
			{x = 79, z = 135, r = 6},
			{x = 94, z = 137, r = 3},
			{x = 104, z = 127, r = 4},
			{x = 90, z = 179, r = 5},
			{x = 60, z = 180, r = 8},
			{x = 45, z = 145, r = 5},
			{x = 45, z = 164, r = 5},
			{x = 91, z = 98, r = 3},
			{x = 90, z = 55, r = 8},
			{x = 74, z = 58, r = 4},
			{x = 99, z = 87, r = 3},
			{x = 78, z = 92, r = 5},
			{x = 95, z = 111, r = 4},
			{x = 73, z = 143, r = 3},
			{x = 58, z = 68, r = 3},
			{x = 79, z = 43, r = 3},
			{x = 96, z = 42, r = 3},
			{x = 98, z = 66, r = 4},
			{x = 109, z = 165, r = 4},
			{x = 80, z = 50, r = 3},
			{x = 70, z = 83, r = 3},
			{x = 86, z = 83, r = 3}
		}
	},
	{
		sceneId = 13,
		sceneLeader = "本因",
		sceneName = "天龙",
		minL = 91,
		maxL = 100,
		posList = {
			{x = 54, z = 38, r = 5},
			{x = 41, z = 46, r = 5},
			{x = 42, z = 64, r = 3},
			{x = 40, z = 76, r = 7},
			{x = 55, z = 74, r = 5},
			{x = 64, z = 73, r = 5},
			{x = 42, z = 104, r = 4},
			{x = 24, z = 126, r = 4},
			{x = 41, z = 130, r = 6},
			{x = 95, z = 38, r = 5},
			{x = 110, z = 35, r = 4},
			{x = 153, z = 35, r = 4},
			{x = 146, z = 56, r = 5},
			{x = 123, z = 67, r = 4},
			{x = 95, z = 71, r = 5},
			{x = 83, z = 71, r = 5},
			{x = 95, z = 89, r = 10},
			{x = 65, z = 96, r = 5},
			{x = 65, z = 145, r = 5},
			{x = 65, z = 123, r = 5},
			{x = 95, z = 128, r = 5},
			{x = 95, z = 107, r = 4},
			{x = 117, z = 114, r = 5},
			{x = 135, z = 152, r = 5},
			{x = 153, z = 150, r = 5},
			{x = 155, z = 126, r = 5},
			{x = 154, z = 89, r = 5},
			{x = 128, z = 94, r = 5},
			{x = 139, z = 35, r = 3},
			{x = 131, z = 132, r = 4}
		}
	},
	{
		sceneId = 14,
		sceneLeader = "苏星河",
		sceneName = "逍遥",
		minL = 100,
		maxL = 105,
		posList = {
			{x = 48, z = 55, r = 5},
			{x = 53, z = 63, r = 5},
			{x = 46, z = 72, r = 4},
			{x = 64, z = 62, r = 4},
			{x = 69, z = 55, r = 4},
			{x = 118, z = 90, r = 10},
			{x = 55, z = 73, r = 4},
			{x = 49, z = 127, r = 3},
			{x = 65, z = 135, r = 5},
			{x = 49, z = 147, r = 5},
			{x = 70, z = 150, r = 5},
			{x = 91, z = 124, r = 4},
			{x = 120, z = 140, r = 10},
			{x = 119, z = 154, r = 5},
			{x = 149, z = 148, r = 5},
			{x = 150, z = 129, r = 6},
			{x = 149, z = 119, r = 5},
			{x = 146, z = 58, r = 3},
			{x = 157, z = 58, r = 3},
			{x = 160, z = 50, r = 3},
			{x = 149, z = 44, r = 4},
			{x = 139, z = 43, r = 4},
			{x = 130, z = 43, r = 3},
			{x = 130, z = 136, r = 5},
			{x = 41, z = 152, r = 3},
			{x = 114, z = 147, r = 3},
			{x = 41, z = 150, r = 3},
			{x = 144, z = 124, r = 5},
			{x = 158, z = 65, r = 3},
			{x = 121, z = 42, r = 3}
		}
	},
	{
		sceneId = 15,
		sceneLeader = "孟青青",
		sceneName = "Nga Mi",
		minL = 30,
		maxL = 40,
		posList = {
			{x = 49, z = 40, r = 8},
			{x = 39, z = 46, r = 5},
			{x = 35, z = 58, r = 3},
			{x = 56, z = 54, r = 4},
			{x = 54, z = 93, r = 3},
			{x = 66, z = 110, r = 3},
			{x = 39, z = 108, r = 5},
			{x = 36, z = 119, r = 4},
			{x = 36, z = 131, r = 4},
			{x = 39, z = 149, r = 8},
			{x = 57, z = 149, r = 5},
			{x = 56, z = 138, r = 4},
			{x = 56, z = 130, r = 4},
			{x = 95, z = 88, r = 5},
			{x = 95, z = 69, r = 5},
			{x = 95, z = 62, r = 5},
			{x = 85, z = 38, r = 3},
			{x = 106, z = 48, r = 4},
			{x = 95, z = 38, r = 4},
			{x = 85, z = 38, r = 3},
			{x = 105, z = 38, r = 3},
			{x = 137, z = 40, r = 4},
			{x = 149, z = 40, r = 5},
			{x = 150, z = 49, r = 5},
			{x = 139, z = 49, r = 5},
			{x = 140, z = 74, r = 5},
			{x = 150, z = 77, r = 4},
			{x = 139, z = 106, r = 8},
			{x = 152, z = 108, r = 5},
			{x = 145, z = 153, r = 5}
		}
	},
	{
		sceneId = 16,
		sceneLeader = "丁春秋",
		sceneName = "星宿",
		minL = 41,
		maxL = 55,
		posList = {
			{x = 46, z = 53, r = 3},
			{x = 40, z = 84, r = 5},
			{x = 50, z = 83, r = 5},
			{x = 43, z = 93, r = 4},
			{x = 45, z = 130, r = 5},
			{x = 43, z = 148, r = 4},
			{x = 55, z = 140, r = 5},
			{x = 70, z = 140, r = 10},
			{x = 90, z = 140, r = 9},
			{x = 99, z = 130, r = 8},
			{x = 95, z = 110, r = 5},
			{x = 84, z = 114, r = 5},
			{x = 70, z = 108, r = 5},
			{x = 60, z = 118, r = 5},
			{x = 110, z = 113, r = 5},
			{x = 110, z = 125, r = 5},
			{x = 109, z = 146, r = 3},
			{x = 125, z = 147, r = 5},
			{x = 137, z = 149, r = 3},
			{x = 144, z = 140, r = 5},
			{x = 147, z = 126, r = 5},
			{x = 126, z = 100, r = 6},
			{x = 143, z = 93, r = 5},
			{x = 147, z = 55, r = 3},
			{x = 123, z = 73, r = 3},
			{x = 96, z = 91, r = 5},
			{x = 95, z = 53, r = 5},
			{x = 115, z = 54, r = 4},
			{x = 68, z = 63, r = 5},
			{x = 62, z = 96, r = 5}
		}
	},
	{
		sceneId = 17,
		sceneLeader = "梅剑",
		sceneName = "天山",
		minL = 56,
		maxL = 70,
		posList = {
			{x = 40, z = 47, r = 8},
			{x = 41, z = 67, r = 5},
			{x = 36, z = 76, r = 5},
			{x = 33, z = 88, r = 5},
			{x = 33, z = 100, r = 4},
			{x = 35, z = 110, r = 5},
			{x = 49, z = 126, r = 7},
			{x = 39, z = 146, r = 6},
			{x = 50, z = 140, r = 5},
			{x = 62, z = 126, r = 4},
			{x = 49, z = 110, r = 5},
			{x = 49, z = 77, r = 5},
			{x = 66, z = 87, r = 5},
			{x = 70, z = 99, r = 8},
			{x = 85, z = 100, r = 5},
			{x = 100, z = 100, r = 5},
			{x = 95, z = 79, r = 5},
			{x = 85, z = 72, r = 5},
			{x = 90, z = 50, r = 8},
			{x = 109, z = 49, r = 7},
			{x = 125, z = 50, r = 5},
			{x = 153, z = 61, r = 5},
			{x = 152, z = 82, r = 5},
			{x = 126, z = 80, r = 8},
			{x = 122, z = 96, r = 5},
			{x = 135, z = 124, r = 5},
			{x = 153, z = 143, r = 5},
			{x = 82, z = 119, r = 5},
			{x = 107, z = 120, r = 4},
			{x = 61, z = 41, r = 4}
		}
	},
	{
		sceneId = 184,
		sceneLeader = "王素商",
		sceneName = "曼陀山庄",
		minL = 56,
		maxL = 70,
		posList = {
			{x = 51, z = 50, r = 8},
			{x = 53, z = 59, r = 5},
			{x = 56, z = 65, r = 5},
			{x = 87, z = 56, r = 5},
			{x = 79, z = 38, r = 4},
			{x = 89, z = 25, r = 5},
			{x = 109, z = 28, r = 7},
			{x = 134, z = 36, r = 6},
			{x = 158, z = 34, r = 5},
			{x = 171, z = 52, r = 4},
			{x = 169, z = 67, r = 5},
			{x = 181, z = 70, r = 5},
			{x = 186, z = 60, r = 5},
			{x = 196, z = 76, r = 8},
			{x = 200, z = 94, r = 5},
			{x = 216, z = 94, r = 5},
			{x = 210, z = 106, r = 5},
			{x = 191, z = 111, r = 5},
			{x = 185, z = 128, r = 8},
			{x = 191, z = 139, r = 7},
			{x = 211, z = 149, r = 5},
			{x = 163, z = 122, r = 5},
			{x = 150, z = 112, r = 5},
			{x = 141, z = 110, r = 8},
			{x = 126, z = 110, r = 5},
			{x = 139, z = 97, r = 5},
			{x = 143, z = 87, r = 5},
			{x = 138, z = 73, r = 5},
			{x = 136, z = 56, r = 4},
			{x = 140, z = 57, r = 4}
		}
	},
	{
		sceneId = 987,
		sceneLeader = "左子穆",
		sceneName = "恶人谷",
		minL = 71,
		maxL = 85,
		posList = {
			{x = 40, z = 50, r = 5},
			{x = 50, z = 55, r = 5},
			{x = 60, z = 60, r = 5},
			{x = 70, z = 65, r = 5},
			{x = 80, z = 70, r = 4},
			{x = 90, z = 75, r = 5},
			{x = 100, z = 80, r = 5},
			{x = 110, z = 85, r = 5},
			{x = 120, z = 90, r = 4},
			{x = 130, z = 95, r = 5},
			{x = 135, z = 100, r = 5},
			{x = 140, z = 105, r = 5},
			{x = 145, z = 110, r = 4},
			{x = 150, z = 115, r = 5},
			{x = 125, z = 120, r = 5},
			{x = 115, z = 125, r = 5},
			{x = 105, z = 130, r = 4},
			{x = 95, z = 135, r = 5},
			{x = 85, z = 140, r = 5},
			{x = 75, z = 145, r = 5},
			{x = 65, z = 150, r = 4},
			{x = 55, z = 145, r = 5},
			{x = 45, z = 140, r = 5},
			{x = 35, z = 135, r = 5},
			{x = 130, z = 150, r = 4},
			{x = 140, z = 145, r = 5},
			{x = 150, z = 140, r = 5},
			{x = 120, z = 155, r = 5},
			{x = 110, z = 150, r = 4},
			{x = 100, z = 145, r = 5}
		}
	},
	{
		sceneId = 1358,
		sceneLeader = "慕容复",
		sceneName = "慕容山庄",
		minL = 86,
		maxL = 100,
		posList = {
			{x = 20, z = 40, r = 5},
			{x = 25, z = 50, r = 5},
			{x = 30, z = 60, r = 5},
			{x = 35, z = 70, r = 5},
			{x = 40, z = 80, r = 4},
			{x = 28, z = 90, r = 5},
			{x = 22, z = 100, r = 5},
			{x = 18, z = 110, r = 5},
			{x = 32, z = 120, r = 4},
			{x = 38, z = 130, r = 5},
			{x = 45, z = 135, r = 5},
			{x = 50, z = 125, r = 5},
			{x = 55, z = 115, r = 4},
			{x = 48, z = 105, r = 5},
			{x = 42, z = 95, r = 5},
			{x = 36, z = 85, r = 5},
			{x = 26, z = 75, r = 4},
			{x = 15, z = 65, r = 5},
			{x = 10, z = 55, r = 5},
			{x = 33, z = 45, r = 5},
			{x = 44, z = 55, r = 4},
			{x = 52, z = 65, r = 5},
			{x = 46, z = 75, r = 5},
			{x = 39, z = 85, r = 5},
			{x = 27, z = 95, r = 4},
			{x = 16, z = 105, r = 5},
			{x = 23, z = 115, r = 5},
			{x = 31, z = 125, r = 5},
			{x = 41, z = 133, r = 4},
			{x = 48, z = 140, r = 5}
		}
	}
}
function eTouximenpai_Generate:GetDataValidator(param1,param2)
	eTouximenpai_Generate.DataValidator = math.random(1,2100000000)
	return eTouximenpai_Generate.DataValidator
end
--**********************************
--事件交互入口 19-145-40 18-149-48
--**********************************
function eTouximenpai_Generate:OnDefaultEvent(actId, iNoticeType, param2, param3, param4, param5, param6)
	if param6 ~= eTouximenpai_Generate.DataValidator then
		return
	elseif not iNoticeType or not param2 or not param3 or not param4 or not param5 then
		return
	end
	-- self:Start808015Activity(actId, param6)
	
	local sceneIds = {
		{ sceneId = 9, n = math.random(1, 100) },
		{ sceneId = 10, n = math.random(1, 100) },
		{ sceneId = 11, n = math.random(1, 100) },
		{ sceneId = 12, n = math.random(1, 100) },
		{ sceneId = 13, n = math.random(1, 100) },
		{ sceneId = 14, n = math.random(1, 100) },
		{ sceneId = 15, n = math.random(1, 100) },
		{ sceneId = 16, n = math.random(1, 100) },
		{ sceneId = 17, n = math.random(1, 100) },
		{ sceneId = 184, n = math.random(1, 100) },
		{ sceneId = 987, n = math.random(1, 100) },
		{ sceneId = 1358, n = math.random(1, 100) },
	}
	local sceneId = self:get_scene_id()
	for i = #sceneIds, 1, -1 do
		local s = sceneIds[i]
		if s.sceneId == sceneId then
			table.remove(sceneIds, i)
			break
		end
	end
	local skynet = require "skynet"
	table.sort( sceneIds, function(s1, s2)
		return s1.n > s2.n
	end)
	for i = 1, 1 do
		local s = sceneIds[i]
		local name = string.format(".SCENE_%d", s.sceneId)
		print("eTouximenpai_Generate:OnDefaultEvent name =", name)
		skynet.send(name, "lua", "char_excute_Script", 808015, "Start808015Activity", actId, eTouximenpai_Generate.DataValidator)
	end
end

function eTouximenpai_Generate:Start808015Activity(actId, param6)
	-- if param6 ~= eTouximenpai_Generate.DataValidator then
		-- return
	-- end
    local sceneId = self:get_scene_id()
	for _, v in ipairs(self.g_scenePosInfoList) do
		if v.sceneId == sceneId then
			self:StartOneActivity(actId, math.floor(1000 * 3600))
			self:SetActivityParam(actId, self.g_TimeTickIndex, 0)
			self:SpawnInvaders(actId, sceneId, v.posList, 10)
			local NotifyMsg = "@*;SrvMsg;SCA:#P" .. v.sceneLeader .. "#P: Ta#Y" .. v.sceneName .. "#Pbỗng gặp một đám#Ggiang hồ tiểu tốt#P tập kích, thỉnh chư vị đệ tử mau chóng hồi Môn phái tiêu diệt địch!"
			-- print("AddGlobalCountNews NotifyMsg =", NotifyMsg)
			self:AddGlobalCountNews(NotifyMsg)
			return
		end
	end
end

function eTouximenpai_Generate:SpawnInvaders(actId, sceneId, posList, count)
	local maxCount = math.min(count, #posList)
	for i = 1, maxCount do
		local pos = posList[i]
		local MonsterId = self:LuaFnCreateMonster(486, pos.x, pos.z, pos.r or 3, -1, 808017)
		if MonsterId and MonsterId ~= -1 then
			self:LuaFnSetNpcIntParameter(MonsterId, 1, sceneId)
			self:LuaFnSetNpcIntParameter(MonsterId, 2, actId + 1)
			self:SetCharacterDieTime(MonsterId, 1000 * 900)
		end
	end
end

function eTouximenpai_Generate:GetDelayedPositions(sceneId, groupName)
	for _, info in ipairs(self.g_DLPosInfoList) do
		if info.sceneId == sceneId then
			return info[groupName]
		end
	end
	return nil
end
-- function eTouximenpai_Generate:Update_808015_Moster(actId,Validatorid,msgflag)
	-- if Validatorid == eTouximenpai_Generate.DataValidator then
		-- local sceneId = self:get_scene_id()
		-- for i, v in ipairs(self.g_scenePosInfoList) do
			-- if v.sceneId == sceneId then
				-- local j = 1
				-- while j <= 10 do
					-- local MonsterId = self:LuaFnCreateMonster(486, v.posList[j].x, v.posList[j].z, 3, -1, 808017)
					-- self:LuaFnSetNpcIntParameter(MonsterId, 1, sceneId)
					-- self:LuaFnSetNpcIntParameter(MonsterId, 2, actId + 1)
					-- self:SetCharacterDieTime(MonsterId, 1000 * 900)
					-- j = j + 1
				-- end
				-- if msgflag then
					-- local NotifyMsg = "@*;SrvMsg;SCA:#P" .. v.sceneLeader .. "#P: 我#Y" .. v.sceneName .. "#P突遭一批#G江湖宵小#P偷袭，请各位门下弟子速回门派肃清来敌。"
					-- -- print("AddGlobalCountNews NotifyMsg =", NotifyMsg)
					-- self:AddGlobalCountNews(NotifyMsg)
				-- end
			-- end
		-- end
	-- else
		-- self:LOGI("eTouximenpai_Generate(刷新怪异常):Validatorid",Validatorid,"eTouximenpai_Generate.DataValidator",eTouximenpai_Generate.DataValidator)
	-- end
-- end
--**********************************
--心跳函数
--**********************************
function eTouximenpai_Generate:OnTimer(actId, uTime, param1)
	if not uTime or uTime ~= param1 then
		return
	end
	-- print("eTouximenpai_Generate:OnTimer actId =", actId, ", uTime =", uTime)
	local TickTime = self:GetActivityParam(actId, self.g_TimeTickIndex)
	TickTime = TickTime + uTime
	self:SetActivityParam(actId, self.g_TimeTickIndex, TickTime)
	local sceneId = self:get_scene_id()
	if TickTime == 900000 then
		local positions = self:GetDelayedPositions(sceneId, "G1posList")
		if positions then
			self:SpawnInvaders(actId, sceneId, positions, self.g_RefreshMonsterNum)
		end
	elseif TickTime == 1800000 then
		local positions = self:GetDelayedPositions(sceneId, "G2posList")
		if positions then
			self:SpawnInvaders(actId, sceneId, positions, self.g_RefreshMonsterNum)
		end
	elseif TickTime >= 1000 * 3600 then
		if not self:CheckActiviyValidity(actId) then
			self:StopOneActivity(actId)
		end
	end
end

return eTouximenpai_Generate
