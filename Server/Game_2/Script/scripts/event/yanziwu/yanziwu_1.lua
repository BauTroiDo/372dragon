local class = require "class"
local ScriptGlobal = require "scripts.ScriptGlobal"
local define = require "define"
local script_base = require "script_base"
local yanziwu_1 = class("yanziwu_1", script_base)
yanziwu_1.script_id = 401040
yanziwu_1.g_Name = "李纲"
yanziwu_1.TIME_2000_01_03_ = 946828868
yanziwu_1.g_SceneData_1 = 8
yanziwu_1.g_SceneData_3 = 9
yanziwu_1.g_SceneData_4 = 10
yanziwu_1.g_SceneData_5 = 11
yanziwu_1.g_SceneData_6 = 12
yanziwu_1.g_SceneData_7 = 13
yanziwu_1.g_SD_Monster_1 = 14
yanziwu_1.g_SD_Monster_1_T = 15
yanziwu_1.g_SD_Monster_2 = 16
yanziwu_1.g_SD_Monster_2_T = 17
yanziwu_1.g_SD_Monster_3 = 18
yanziwu_1.g_SD_Monster_3_T = 19
yanziwu_1.g_KillMonsCount_Qincheng = 20
yanziwu_1.g_KillMonsCount_Qinjia = 21
yanziwu_1.g_KillMonsCount_Lama = 22
yanziwu_1.g_SkillSign = 23
yanziwu_1.g_bWangyuyanSpeak = 24
yanziwu_1.g_bWangyuyanSpeak_T = 27
yanziwu_1.g_CloseTime = 25
yanziwu_1.g_MissionLost = 26
yanziwu_1.g_SystemTipsTime = 28
yanziwu_1.g_DuanAndWangFlag = 29
yanziwu_1.g_CopySceneName = "燕子坞"
yanziwu_1.g_CopySceneType = ScriptGlobal.FUBEN_DAZHAN_YZW
yanziwu_1.g_CopySceneMap = "yanziwu.nav"
yanziwu_1.g_client_res = 236
yanziwu_1.g_LimitMembers = 1
yanziwu_1.g_TickTime = 1
yanziwu_1.g_LimitTotalHoldTime = 360
yanziwu_1.g_LimitTimeSuccess = 500
yanziwu_1.g_CloseTick = 3
yanziwu_1.g_NoUserTime = 300
yanziwu_1.g_DeadTrans = 0
yanziwu_1.g_Fuben_X = 177
yanziwu_1.g_Fuben_Z = 234
yanziwu_1.g_Back_X = 70
yanziwu_1.g_Back_Z = 120
yanziwu_1.g_Back_SceneId = 4
yanziwu_1.g_Npc_1 = {
    {["id"] = 9210, ["x"] = 175, ["y"] = 202, ["camp"] = 109, ["ai"] = 21, ["af"] = 222},
    {["id"] = 9210, ["x"] = 181, ["y"] = 202, ["camp"] = 109, ["ai"] = 21, ["af"] = 222},
    {["id"] = 9210, ["x"] = 172, ["y"] = 152, ["camp"] = 109, ["ai"] = 21, ["af"] = 222},
    {["id"] = 9210, ["x"] = 173, ["y"] = 158, ["camp"] = 109, ["ai"] = 21, ["af"] = 222},
    {["id"] = 9210, ["x"] = 146, ["y"] = 151, ["camp"] = 109, ["ai"] = 21, ["af"] = 222},
    {["id"] = 9210, ["x"] = 151, ["y"] = 154, ["camp"] = 109, ["ai"] = 21, ["af"] = 222},
    {["id"] = 9210, ["x"] = 137, ["y"] = 177, ["camp"] = 109, ["ai"] = 21, ["af"] = 222},
    {["id"] = 9210, ["x"] = 133, ["y"] = 175, ["camp"] = 109, ["ai"] = 21, ["af"] = 222},
    {["id"] = 9210, ["x"] = 109, ["y"] = 162, ["camp"] = 109, ["ai"] = 21, ["af"] = 222},
    {["id"] = 9210, ["x"] = 104, ["y"] = 164, ["camp"] = 109, ["ai"] = 21, ["af"] = 222},
    {["id"] = 9210, ["x"] = 82, ["y"] = 176, ["camp"] = 109, ["ai"] = 21, ["af"] = 222},
    {["id"] = 9210, ["x"] = 77, ["y"] = 176, ["camp"] = 109, ["ai"] = 21, ["af"] = 222},
    {["id"] = 9210, ["x"] = 53, ["y"] = 157, ["camp"] = 109, ["ai"] = 21, ["af"] = 222},
    {["id"] = 9210, ["x"] = 58, ["y"] = 156, ["camp"] = 109, ["ai"] = 21, ["af"] = 222},
    {["id"] = 9210, ["x"] = 76, ["y"] = 210, ["camp"] = 109, ["ai"] = 21, ["af"] = 222},
    {["id"] = 9210, ["x"] = 80, ["y"] = 210, ["camp"] = 109, ["ai"] = 21, ["af"] = 222},
    {["id"] = 9210, ["x"] = 86, ["y"] = 210, ["camp"] = 109, ["ai"] = 21, ["af"] = 222},
    {["id"] = 9210, ["x"] = 91, ["y"] = 210, ["camp"] = 109, ["ai"] = 21, ["af"] = 222},
    {["id"] = 9210, ["x"] = 211, ["y"] = 146, ["camp"] = 109, ["ai"] = 21, ["af"] = 222},
    {["id"] = 9210, ["x"] = 214, ["y"] = 146, ["camp"] = 109, ["ai"] = 21, ["af"] = 222},
    {["id"] = 9210, ["x"] = 217, ["y"] = 146, ["camp"] = 109, ["ai"] = 21, ["af"] = 222},
    {["id"] = 9210, ["x"] = 220, ["y"] = 146, ["camp"] = 109, ["ai"] = 21, ["af"] = 222},
    {["id"] = 9210, ["x"] = 223, ["y"] = 146, ["camp"] = 109, ["ai"] = 21, ["af"] = 222},
    {["id"] = 9240, ["x"] = 175, ["y"] = 152, ["camp"] = 110, ["ai"] = 21, ["af"] = 226},
    {["id"] = 9240, ["x"] = 149, ["y"] = 150, ["camp"] = 110, ["ai"] = 21, ["af"] = 226},
    {["id"] = 9240, ["x"] = 147, ["y"] = 146, ["camp"] = 110, ["ai"] = 21, ["af"] = 226},
    {["id"] = 9240, ["x"] = 135, ["y"] = 174, ["camp"] = 110, ["ai"] = 21, ["af"] = 226},
    {["id"] = 9240, ["x"] = 133, ["y"] = 171, ["camp"] = 110, ["ai"] = 21, ["af"] = 226},
    {["id"] = 9240, ["x"] = 135, ["y"] = 177, ["camp"] = 110, ["ai"] = 21, ["af"] = 226},
    {["id"] = 9240, ["x"] = 105, ["y"] = 161, ["camp"] = 110, ["ai"] = 21, ["af"] = 226},
    {["id"] = 9240, ["x"] = 108, ["y"] = 159, ["camp"] = 110, ["ai"] = 21, ["af"] = 226},
    {["id"] = 9240, ["x"] = 80, ["y"] = 173, ["camp"] = 110, ["ai"] = 21, ["af"] = 226},
    {["id"] = 9240, ["x"] = 81, ["y"] = 177, ["camp"] = 110, ["ai"] = 21, ["af"] = 226},
    {["id"] = 9240, ["x"] = 55, ["y"] = 155, ["camp"] = 110, ["ai"] = 21, ["af"] = 226},
    {["id"] = 9240, ["x"] = 52, ["y"] = 154, ["camp"] = 110, ["ai"] = 21, ["af"] = 226},
    {["id"] = 9240, ["x"] = 58, ["y"] = 155, ["camp"] = 110, ["ai"] = 21, ["af"] = 226},
    {["id"] = 9280, ["x"] = 209, ["y"] = 80, ["camp"] = 110, ["ai"] = 21, ["af"] = 239},
    {["id"] = 9280, ["x"] = 222, ["y"] = 79, ["camp"] = 110, ["ai"] = 21, ["af"] = 239},
    {["id"] = 9280, ["x"] = 218, ["y"] = 69, ["camp"] = 110, ["ai"] = 21, ["af"] = 239},
    {["id"] = 9280, ["x"] = 228, ["y"] = 64, ["camp"] = 110, ["ai"] = 21, ["af"] = 239},
    {["id"] = 9280, ["x"] = 228, ["y"] = 52, ["camp"] = 110, ["ai"] = 21, ["af"] = 239},
    {["id"] = 9280, ["x"] = 217, ["y"] = 39, ["camp"] = 110, ["ai"] = 21, ["af"] = 239},
    {["id"] = 9280, ["x"] = 186, ["y"] = 31, ["camp"] = 110, ["ai"] = 21, ["af"] = 239},
    {["id"] = 9280, ["x"] = 181, ["y"] = 36, ["camp"] = 110, ["ai"] = 21, ["af"] = 239},
    {["id"] = 9280, ["x"] = 176, ["y"] = 42, ["camp"] = 110, ["ai"] = 21, ["af"] = 239},
    {["id"] = 9280, ["x"] = 176, ["y"] = 52, ["camp"] = 110, ["ai"] = 21, ["af"] = 239},
    {["id"] = 9280, ["x"] = 136, ["y"] = 93, ["camp"] = 110, ["ai"] = 21, ["af"] = 239},
    {["id"] = 9280, ["x"] = 140, ["y"] = 88, ["camp"] = 110, ["ai"] = 21, ["af"] = 239},
    {["id"] = 9280, ["x"] = 137, ["y"] = 82, ["camp"] = 110, ["ai"] = 21, ["af"] = 239},
    {["id"] = 9280, ["x"] = 144, ["y"] = 86, ["camp"] = 110, ["ai"] = 21, ["af"] = 239},
    {["id"] = 9280, ["x"] = 143, ["y"] = 101, ["camp"] = 110, ["ai"] = 21, ["af"] = 239},
    {["id"] = 9280, ["x"] = 141, ["y"] = 111, ["camp"] = 110, ["ai"] = 21, ["af"] = 239},
    {["id"] = 9280, ["x"] = 148, ["y"] = 112, ["camp"] = 110, ["ai"] = 21, ["af"] = 239},
    {["id"] = 9280, ["x"] = 146, ["y"] = 103, ["camp"] = 110, ["ai"] = 21, ["af"] = 239},
    {["id"] = 9280, ["x"] = 154, ["y"] = 110, ["camp"] = 110, ["ai"] = 21, ["af"] = 239},
    {["id"] = 9290, ["x"] = 234, ["y"] = 30, ["camp"] = 109, ["ai"] = 21, ["af"] = 223},
    {["id"] = 9290, ["x"] = 225, ["y"] = 25, ["camp"] = 109, ["ai"] = 21, ["af"] = 223},
    {["id"] = 9290, ["x"] = 175, ["y"] = 41, ["camp"] = 109, ["ai"] = 21, ["af"] = 223},
    {["id"] = 9290, ["x"] = 179, ["y"] = 45, ["camp"] = 109, ["ai"] = 21, ["af"] = 223},
    {["id"] = 9290, ["x"] = 172, ["y"] = 48, ["camp"] = 109, ["ai"] = 21, ["af"] = 223},
    {["id"] = 9290, ["x"] = 171, ["y"] = 52, ["camp"] = 109, ["ai"] = 21, ["af"] = 223},
    {["id"] = 9290, ["x"] = 170, ["y"] = 57, ["camp"] = 109, ["ai"] = 21, ["af"] = 223},
    {["id"] = 9290, ["x"] = 167, ["y"] = 61, ["camp"] = 109, ["ai"] = 21, ["af"] = 223}
}

yanziwu_1.g_Npc_2 = {
    {["id"] = 9200, ["x"] = 177, ["y"] = 232, ["script"] = 402240, ["camp"] = 109, ["ai"] = 3, ["af"] = -1},
    {["id"] = 9220, ["x"] = 79, ["y"] = 202, ["script"] = 402241, ["camp"] = 109, ["ai"] = 21, ["af"] = 220}
}

yanziwu_1.g_Npc_2_1 = {
    {["id"] = 9210, ["x"] = 171, ["y"] = 236, ["camp"] = 109, ["ai"] = 21, ["af"] = 222, ["script"] = 402262},
    {["id"] = 9210, ["x"] = 175, ["y"] = 236, ["camp"] = 109, ["ai"] = 21, ["af"] = 222, ["script"] = 402262},
    {["id"] = 9210, ["x"] = 179, ["y"] = 236, ["camp"] = 109, ["ai"] = 21, ["af"] = 222, ["script"] = 402262},
    {["id"] = 9210, ["x"] = 183, ["y"] = 236, ["camp"] = 109, ["ai"] = 21, ["af"] = 222, ["script"] = 402262}
}

yanziwu_1.g_Npc_3 = {
    {["id"] = 9340, ["x"] = 81, ["y"] = 197, ["script"] = 402242, ["camp"] = 110, ["ai"] = 21, ["af"] = 227}
}

yanziwu_1.g_Npc_3_1 = {
    {["id"] = 9240, ["x"] = 79, ["y"] = 195, ["camp"] = 110, ["ai"] = 21, ["af"] = 226},
    {["id"] = 9240, ["x"] = 77, ["y"] = 207, ["camp"] = 110, ["ai"] = 21, ["af"] = 226},
    {["id"] = 9240, ["x"] = 82, ["y"] = 195, ["camp"] = 110, ["ai"] = 21, ["af"] = 226},
    {["id"] = 9240, ["x"] = 86, ["y"] = 206, ["camp"] = 110, ["ai"] = 21, ["af"] = 226}
}

yanziwu_1.g_Npc_4 = {
    {["id"] = 9330, ["x"] = 77, ["y"] = 195, ["script"] = 402244, ["camp"] = 110, ["ai"] = 21, ["af"] = 228},
    {["id"] = 9350, ["x"] = 83, ["y"] = 198, ["script"] = 402243, ["camp"] = 110, ["ai"] = 21, ["af"] = 229}
}

yanziwu_1.g_Npc_5 = {
    {["id"] = 9320, ["x"] = 81, ["y"] = 195, ["script"] = 402245, ["camp"] = 110, ["ai"] = 21, ["af"] = 230}
}

yanziwu_1.g_Npc_6 = {
    {["id"] = 9230, ["x"] = 217, ["y"] = 150, ["script"] = 402246, ["camp"] = 109, ["ai"] = 21, ["af"] = 221},
    {["id"] = 9480, ["x"] = 179, ["y"] = 91, ["script"] = 402249, ["camp"] = 109, ["ai"] = 3, ["af"] = -1}
}

yanziwu_1.g_Npc_7 = {
    {
        ["id"] = 9290,
        ["x"] = 210,
        ["y"] = 155,
        ["script"] = 402247,
        ["name"] = "Tiền",
        ["camp"] = 109,
        ["ai"] = 3,
        ["af"] = -1
    },
    {
        ["id"] = 9290,
        ["x"] = 225,
        ["y"] = 138,
        ["script"] = 402247,
        ["name"] = "Hậu",
        ["camp"] = 109,
        ["ai"] = 3,
        ["af"] = -1
    },
    {["id"] = 9300, ["x"] = 225, ["y"] = 155, ["script"] = 402247, ["name"] = "", ["camp"] = 109, ["ai"] = 3, ["af"] = -1},
    {["id"] = 9310, ["x"] = 209, ["y"] = 138, ["script"] = 402247, ["name"] = "", ["camp"] = 109, ["ai"] = 3, ["af"] = -1}
}

yanziwu_1.g_Npc_8 = {
    {["id"] = 9240, ["x"] = 79, ["y"] = 195, ["script"] = -1, ["camp"] = 110, ["ai"] = 21, ["af"] = 226},
    {["id"] = 9240, ["x"] = 77, ["y"] = 207, ["script"] = -1, ["camp"] = 110, ["ai"] = 21, ["af"] = 226},
    {["id"] = 9240, ["x"] = 82, ["y"] = 195, ["script"] = -1, ["camp"] = 110, ["ai"] = 21, ["af"] = 226},
    {["id"] = 9240, ["x"] = 86, ["y"] = 206, ["script"] = -1, ["camp"] = 110, ["ai"] = 21, ["af"] = 226}
}

yanziwu_1.g_Npc_9 = {
    {
        ["id"] = 9250,
        ["x"] = 233,
        ["y"] = 214,
        ["script"] = 402258,
        ["pp"] = 1,
        ["camp"] = 110,
        ["ai"] = 21,
        ["af"] = 231
    },
    {
        ["id"] = 9250,
        ["x"] = 236,
        ["y"] = 214,
        ["script"] = 402258,
        ["pp"] = 2,
        ["camp"] = 110,
        ["ai"] = 21,
        ["af"] = 231
    },
    {
        ["id"] = 9250,
        ["x"] = 235,
        ["y"] = 217,
        ["script"] = 402258,
        ["pp"] = 3,
        ["camp"] = 110,
        ["ai"] = 21,
        ["af"] = 231
    },
    {
        ["id"] = 9250,
        ["x"] = 238,
        ["y"] = 216,
        ["script"] = 402258,
        ["pp"] = 4,
        ["camp"] = 110,
        ["ai"] = 21,
        ["af"] = 231
    },
    {
        ["id"] = 9250,
        ["x"] = 237,
        ["y"] = 219,
        ["script"] = 402258,
        ["pp"] = 5,
        ["camp"] = 110,
        ["ai"] = 21,
        ["af"] = 231
    }
}

yanziwu_1.g_Npc_9_1 = {
    {
        ["id"] = 9530,
        ["x"] = 237,
        ["y"] = 219,
        ["script"] = 402259,
        ["pp"] = 5,
        ["camp"] = 110,
        ["ai"] = 21,
        ["af"] = 233
    }
}

yanziwu_1.g_Npc_9_2 = {
    {
        ["id"] = 9260,
        ["x"] = 233,
        ["y"] = 214,
        ["script"] = 402257,
        ["pp"] = 1,
        ["camp"] = 110,
        ["ai"] = 21,
        ["af"] = 232
    },
    {
        ["id"] = 9260,
        ["x"] = 236,
        ["y"] = 214,
        ["script"] = 402257,
        ["pp"] = 2,
        ["camp"] = 110,
        ["ai"] = 21,
        ["af"] = 232
    },
    {
        ["id"] = 9260,
        ["x"] = 235,
        ["y"] = 217,
        ["script"] = 402257,
        ["pp"] = 3,
        ["camp"] = 110,
        ["ai"] = 21,
        ["af"] = 232
    },
    {
        ["id"] = 9260,
        ["x"] = 238,
        ["y"] = 216,
        ["script"] = 402257,
        ["pp"] = 4,
        ["camp"] = 110,
        ["ai"] = 21,
        ["af"] = 232
    },
    {
        ["id"] = 9260,
        ["x"] = 237,
        ["y"] = 219,
        ["script"] = 402257,
        ["pp"] = 5,
        ["camp"] = 110,
        ["ai"] = 21,
        ["af"] = 232
    }
}

yanziwu_1.g_Npc_10 = {
    {
        ["id"] = 9270,
        ["x"] = 233,
        ["y"] = 214,
        ["script"] = 402260,
        ["pp"] = 1,
        ["camp"] = 110,
        ["ai"] = 21,
        ["af"] = 234
    },
    {
        ["id"] = 9270,
        ["x"] = 236,
        ["y"] = 214,
        ["script"] = 402260,
        ["pp"] = 2,
        ["camp"] = 110,
        ["ai"] = 21,
        ["af"] = 234
    },
    {
        ["id"] = 9270,
        ["x"] = 235,
        ["y"] = 217,
        ["script"] = 402260,
        ["pp"] = 3,
        ["camp"] = 110,
        ["ai"] = 21,
        ["af"] = 234
    },
    {
        ["id"] = 9270,
        ["x"] = 238,
        ["y"] = 216,
        ["script"] = 402260,
        ["pp"] = 3,
        ["camp"] = 110,
        ["ai"] = 21,
        ["af"] = 234
    },
    {
        ["id"] = 9270,
        ["x"] = 237,
        ["y"] = 219,
        ["script"] = 402260,
        ["pp"] = 3,
        ["camp"] = 110,
        ["ai"] = 21,
        ["af"] = 234
    }
}

yanziwu_1.g_Npc_11 = {
    {
        ["id"] = 9360,
        ["x"] = 233,
        ["y"] = 214,
        ["script"] = 402248,
        ["pp"] = 1,
        ["camp"] = 110,
        ["ai"] = 21,
        ["af"] = 235
    },
    {
        ["id"] = 9370,
        ["x"] = 233,
        ["y"] = 214,
        ["script"] = 402248,
        ["pp"] = 1,
        ["camp"] = 110,
        ["ai"] = 21,
        ["af"] = 236
    },
    {
        ["id"] = 9380,
        ["x"] = 233,
        ["y"] = 214,
        ["script"] = 402248,
        ["pp"] = 1,
        ["camp"] = 110,
        ["ai"] = 21,
        ["af"] = 237
    }
}

yanziwu_1.g_Npc_12 = {
    {["id"] = 9390, ["x"] = 130, ["y"] = 112, ["script"] = 402250, ["camp"] = 0, ["ai"] = 21, ["af"] = 241},
    {["id"] = 9400, ["x"] = 126, ["y"] = 109, ["script"] = 402251, ["camp"] = 0, ["ai"] = 21, ["af"] = 241},
    {["id"] = 9410, ["x"] = 126, ["y"] = 112, ["script"] = 402252, ["camp"] = 0, ["ai"] = 21, ["af"] = 241},
    {["id"] = 9420, ["x"] = 126, ["y"] = 115, ["script"] = 402253, ["camp"] = 0, ["ai"] = 21, ["af"] = 241}
}

yanziwu_1.g_Npc_13 = {
    {["id"] = 9430, ["x"] = 63, ["y"] = 67, ["script"] = 402254, ["camp"] = 110, ["ai"] = 25, ["af"] = 244}
}

yanziwu_1.g_Npc_14 = {
    {["id"] = 9450, ["x"] = 76, ["y"] = 67, ["script"] = 402255, ["camp"] = 0, ["ai"] = 26, ["af"] = -1},
    {["id"] = 9440, ["x"] = 76, ["y"] = 64, ["script"] = 402256, ["camp"] = 0, ["ai"] = 27, ["af"] = 245},
    {["id"] = 9460, ["x"] = 79, ["y"] = 70, ["script"] = 402249, ["camp"] = 0, ["ai"] = 27, ["af"] = 247},
    {["id"] = 9470, ["x"] = 79, ["y"] = 69, ["script"] = 402249, ["camp"] = 0, ["ai"] = 27, ["af"] = 248},
    {["id"] = 9490, ["x"] = 79, ["y"] = 68, ["script"] = 402249, ["camp"] = 0, ["ai"] = 27, ["af"] = 249},
    {["id"] = 9500, ["x"] = 79, ["y"] = 67, ["script"] = 402249, ["camp"] = 0, ["ai"] = 27, ["af"] = 250},
    {["id"] = 9510, ["x"] = 79, ["y"] = 66, ["script"] = 402249, ["camp"] = 0, ["ai"] = 27, ["af"] = 251},
    {["id"] = 9520, ["x"] = 79, ["y"] = 65, ["script"] = 402249, ["camp"] = 0, ["ai"] = 27, ["af"] = 252}
}

yanziwu_1.g_Npc_15 = {}

yanziwu_1.g_Npc_16 = {}

function yanziwu_1:OnDefaultEvent(selfId, targetId, arg, index)
    if index == 1 then
        self:BeginEvent(self.script_id)
        self:AddText("#{yanziwu_info}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if self:GetName(targetId) ~= self.g_Name then
        return
    end
    if self:GetTeamSize(selfId) < self.g_LimitMembers then
        self:BeginEvent(self.script_id)
        self:AddText("#BTảo Phạt Yến Tử Ổ")
        self:AddText("  Trận chiến này hung hiểm dị thường, nếu không đủ ba người, ta không dám để các ngươi tiến vào.")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if self:GetTeamLeader(selfId) ~= selfId then
        self:BeginEvent(self.script_id)
        self:AddText("#BTảo Phạt Yến Tử Ổ")
        self:AddText("  Ngươi nhất định phải là đội trưởng mới được.")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if self:GetTeamSize(selfId) ~= self:GetNearTeamCount(selfId) then
        self:BeginEvent(self.script_id)
        self:AddText("#BTảo Phạt Yến Tử Ổ")
        self:AddText("  Vẫn còn thành viên không ở gần.")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    local nPlayerNum = self:GetNearTeamCount(selfId)
    for i = 1, nPlayerNum do
        local nPlayerId = self:GetNearTeamMember(selfId, i)
        if self:GetLevel(nPlayerId) < 60 then
            self:BeginEvent(self.script_id)
            self:AddText("#BTảo Phạt Yến Tử Ổ")
            self:AddText("  Trận chiến này hung hiểm dị thường, nếu không đủ cấp 60, ta không dám để các ngươi tiến vào.")
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
            return
        end
    end
    local strName = {}
    strName[1] = ""
    strName[2] = ""
    strName[3] = ""
    strName[4] = ""
    strName[5] = ""
    strName[6] = ""
    local bOk = true
    for i = 1, nPlayerNum do
        local nPlayerId = self:GetNearTeamMember(selfId, i)
        local nTimes = self:GetMissionData(nPlayerId, define.MD_ENUM.MD_YANZIWU_TIMES)
        local nPreTime = self:GetMissionData(nPlayerId, define.MD_ENUM.MD_PRE_YANZIWU_TIME)
        local nCurTime = self:LuaFnGetCurrentTime()
        if(nCurTime - nPreTime >= 3600 * 24) or (math.floor((nCurTime - self.TIME_2000_01_03_) / (3600 * 24)) ~= math.floor((nPreTime - self.TIME_2000_01_03_) / (3600 * 24))) then
            nTimes = 0
            nPreTime = nCurTime
            self:SetMissionData(nPlayerId, define.MD_ENUM.MD_YANZIWU_TIMES, nTimes)
            self:SetMissionData(nPlayerId, define.MD_ENUM.MD_PRE_YANZIWU_TIME, nPreTime)
        end
        if nTimes >= 3 then
            bOk = false
            strName[i] = self:GetName(nPlayerId)
        end
    end
    local nCount = 0
    if not bOk then
        local szAllName = ""
        for i = 1, 6 do
            if strName[i] ~= "" then
                if nCount == 0 then
                    szAllName = strName[i]
                else
                    szAllName = szAllName .. "、" .. strName[i]
                end
                nCount = nCount + 1
            end
        end
        self:BeginEvent(self.script_id)
        self:AddText("#BTảo Phạt Yến Tử Ổ")
        self:AddText("  Trong đội của ngươi" .. szAllName .. "Hôm nay đã tham gia 3 lần chiến dịch Tảo Phạt Yến Tử Ổ.")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    self:MakeCopyScene(selfId)
    self:BeginUICommand()
    self:EndUICommand()
    self:DispatchUICommand(selfId, 1000)
end

function yanziwu_1:OnEnumerate(caller, selfId, targetId, arg, index)
    if self:GetName(targetId) == self.g_Name then
        caller:AddNumTextWithTarget(self.script_id, "讨伐燕子坞", 10, -1)
        caller:AddNumTextWithTarget(self.script_id, "Về Tảo Phạt Yến Tử Ổ", 8, 1)
    end
end

function yanziwu_1:CheckAccept(selfId)
end

function yanziwu_1:AskEnterCopyScene(selfId)
end

function yanziwu_1:OnAccept(selfId, targetId)
end

function yanziwu_1:AcceptEnterCopyScene(selfId)
end

function yanziwu_1:MakeCopyScene(selfId)
    local param0 = 4
    local param1 = 3
    local mylevel
    local memId
    local level0 = 0
    local level1 = 0
    local nearmembercount = self:GetNearTeamCount(selfId)
    for i = 1, nearmembercount do
        memId = self:GetNearTeamMember(selfId, i)
        local tempMemlevel = self:GetLevel(memId)
        level0 = level0 + (tempMemlevel ^ param0)
        level1 = level1 + (tempMemlevel ^ param1)
    end
    if level1 == 0 then
        mylevel = 0
    else
        mylevel = level0 / level1
    end
    if nearmembercount == -1 then
        mylevel = self:GetLevel(selfId)
    end
    local leaderguid = self:LuaFnObjId2Guid(selfId)
    local config = {}
    config.navmapname = self.g_CopySceneMap
    config.client_res = self.g_client_res
    config.teamleader = leaderguid
    config.NoUserCloseTime = 0
	config.Timer = self.g_TickTime * 1000
    config.params = {}
	config.params[0] = self.g_CopySceneType
    config.params[1] = self.script_id
	config.params[2] = 0
    config.params[3] = -1
    config.params[4] = 0
    config.params[5] = 0
	config.params[6] = self:GetTeamId(selfId)
	config.params[7] = 0
    for i = 8, 31 do
        config.params[i] = 0
    end
    config.params[self.g_SceneData_7] = mylevel
    config.eventfile = "yanziwu_area.ini"
	config.monsterfile = "yanziwu_monster.ini"
    config.patrolpoint = "yanziwu_patrolpoint.ini"
    config.sn = self:LuaFnGenCopySceneSN()

	local bRetSceneID = self:LuaFnCreateCopyScene(config)
	local text
	if bRetSceneID > 0 then
		text = "Tạo phó bản thành công!"
	else
		text = "Số lượng phó bản đã đạt đến giới hạn, xin hãy thử lại sau!"
	end
	self:notify_tips(selfId, text)
end

function yanziwu_1:OnCopySceneReady(destsceneId)
	local sceneId = self:get_scene_id()
	self:LuaFnSetCopySceneData_Param(destsceneId, 3, sceneId)
    local leaderguid = self:LuaFnGetCopySceneData_TeamLeader(destsceneId)
    local leaderObjId = self:LuaFnGuid2ObjId(leaderguid)
	if not self:LuaFnIsCanDoScriptLogic(leaderObjId) then
		return
	end
    if not self:LuaFnHasTeam(leaderObjId) then
        self:GotoScene(leaderObjId, destsceneId)
    else
        if not self:IsCaptain(leaderObjId) then
            self:GotoScene(leaderObjId, destsceneId)
        else
            local nearteammembercount = self:GetNearTeamCount(leaderObjId)
            local mems = {}
            for i = 1, nearteammembercount do
                mems[i] = self:GetNearTeamMember(leaderObjId, i)
                self:GotoScene(mems[i], destsceneId)
            end
        end
    end
end

function yanziwu_1:GotoScene(ObjId, destsceneId)
    local sn = self:LuaFnGetCopySceneData_Sn(destsceneId)
    self:NewWorld(ObjId, destsceneId, sn, self.g_Fuben_X, self.g_Fuben_Z, self.g_client_res)
end

function yanziwu_1:OnPlayerEnter(selfId)
    self:SetUnitCampID(selfId, 109)
    self:SetPlayerDefaultReliveInfo(selfId, 1, 1, 0, self.g_Fuben_X, self.g_Fuben_Z)
    local nTimes = self:GetMissionData(selfId, define.MD_ENUM.MD_YANZIWU_TIMES)
    local nCurTime = self:LuaFnGetCurrentTime()
    self:SetMissionData(selfId, define.MD_ENUM.MD_YANZIWU_TIMES, nTimes + 1)
    self:SetMissionData(selfId, define.MD_ENUM.MD_PRE_YANZIWU_TIME, nCurTime)
    self:DungeonDone(selfId, 7)
end

function yanziwu_1:OnHumanDie(selfId, killerId)
end

function yanziwu_1:OnAbandon(selfId)
end

function yanziwu_1:OnContinue(selfId, targetId)
end

function yanziwu_1:CheckSubmit(selfId, selectRadioId)
end

function yanziwu_1:OnSubmit(selfId, targetId, selectRadioId)
end

function yanziwu_1:OnDie(objId, killerId)
end

function yanziwu_1:TipAllHuman(Str)
    local nHumanNum = self:LuaFnGetCopyScene_HumanCount()
    if nHumanNum < 1 then
        return
    end
    for i = 1, nHumanNum do
        local PlayerId = self:LuaFnGetCopyScene_HumanObjId(i)
        self:BeginEvent(self.script_id)
        self:AddText(Str)
        self:EndEvent()
        self:DispatchMissionTips(PlayerId)
    end
end

function yanziwu_1:OnKillObject(selfId, objdataId, objId)
    local name = self:GetMonsterNamebyDataId(objdataId)
    if name == "慕容复" then
        local num = self:LuaFnGetCopyScene_HumanCount()
        local mems = {}
        for i = 1, num do
            mems[i] = self:LuaFnGetCopyScene_HumanObjId(i)
            self:LuaFnAddSweepPointByID(mems[i], 7, 8)
        end
    end
end

function yanziwu_1:OnEnterZone(selfId, zoneId)
end

function yanziwu_1:OnItemChanged(selfId, itemdataId)
end

function yanziwu_1:SystemTips(nStep)
    if nStep == 1 then
        self:TipAllHuman("Có cao thủ muốn thích sát Hô Diên Báo tướng quân!")
        self:TipAllHuman("Xin hãy dùng khinh công từ lá sen bay đến thủy quân kỳ hạm để bảo vệ ngài ấy!")
    elseif nStep == 2 then
        self:TipAllHuman("Có một lượng lớn cao thủ võ lâm muốn đến tiếp viện cho bọn phản tặc Mộ Dung!")
        self:TipAllHuman("Xin hãy nhanh chóng đến điểm chặn kích, hiệp trợ Tiền Hoành Vũ tướng quân ngăn chặn viện quân phản tặc!")
    elseif nStep == 3 then
        self:TipAllHuman("Có một lượng lớn cao thủ võ lâm muốn đến tiếp viện cho bọn phản tặc Mộ Dung!")
        self:TipAllHuman("Xin hãy nhanh chóng đến điểm chặn kích, hiệp trợ Tiền Hoành Vũ tướng quân ngăn chặn viện quân phản tặc!")
    end
end

function yanziwu_1:OnCopySceneTimer(nowTime)
    local nStep = self:LuaFnGetCopySceneData_Param(self.g_SceneData_1)
    if nStep == 13 then
        return
    end
    local nTime = self:LuaFnGetCurrentTime()
    if nStep == 0 then
        self:CreateMonster_1()
    end
    local nPreSystemTime = self:LuaFnGetCopySceneData_Param(self.g_SystemTipsTime)
    if nStep == 1 then
        if nTime - nPreSystemTime >= 15 then
            self:SystemTips(1)
            self:LuaFnSetCopySceneData_Param(self.g_SystemTipsTime, nTime)
        end
    end
    if nStep == 2 then
        self:CreateMonster_2()
        self:LuaFnSetCopySceneData_Param(self.g_SceneData_1, 3)
    end
    if nStep == 4 then
        self:CreateMonster_3()
        self:LuaFnSetCopySceneData_Param(self.g_SceneData_1, 5)
    end
    if nStep == 6 then
        self:CreateMonster_5()
        self:LuaFnSetCopySceneData_Param(self.g_SceneData_1, 7)
    end
    if nStep == 9 then
        self:ClearMonsterByName("一品堂武士")
        self:TipAllHuman("Đoàn Diên Khánh chiến bại, thủ hạ và võ sĩ Nhất Phẩm Đường đều bỏ chạy.")
        self:ClearMonsterByName("叶二娘")
        self:ClearMonsterByName("云中鹤")
        self:LuaFnSetCopySceneData_Param(self.g_SceneData_1, 10)
    end
    nPreSystemTime = self:LuaFnGetCopySceneData_Param(self.g_SystemTipsTime)
    if nStep == 10 then
        if nTime - nPreSystemTime >= 5 then
            self:SystemTips(2)
            self:LuaFnSetCopySceneData_Param(self.g_SystemTipsTime, nTime)
        end
    end
    if nStep == 11 then
        local nStep1 = self:LuaFnGetCopySceneData_Param(self.g_SD_Monster_2)
        local nPreTime = self:LuaFnGetCopySceneData_Param(self.g_SD_Monster_2_T)
        if nStep1 == 0 then
            local nNpcNum = self:GetMonsterCount()
            for i = 1, nNpcNum do
                local nNpcId = self:GetMonsterObjID(i)
                if self:GetName(nNpcId) == "钱宏宇" then
                    self:SetMonsterFightWithNpcFlag(nNpcId, 1)
                end
            end
        end
        if nStep1 < 10 then
            if nTime - nPreTime >= 10 then
                self:LuaFnSetCopySceneData_Param(self.g_SD_Monster_2, nStep1 + 1)
                self:LuaFnSetCopySceneData_Param(self.g_SD_Monster_2_T, nTime)
                self:CreateMonster_7_1()
                self:CreateMonster_7_3()
                self:TipAllHuman("Cảnh giác! Thứ" .. nStep1 + 1 .. "#YYến Tử Ổ#W viện quân đã đến, vẫn còn" .. 25 - (nStep1 + 1) .. "#YYến Tử Ổ#W viện quân sắp đến.")
                if nStep1 == 9 then
                    self:CreateMonster_8(1)
                end
            end
        end
        if nStep1 == 10 then
            if nTime - nPreTime >= 30 then
                self:LuaFnSetCopySceneData_Param(self.g_SD_Monster_2, nStep1 + 1)
            end
        end
        if nStep1 >= 11 and nStep1 < 21 then
            if nTime - nPreTime >= 20 then
                self:LuaFnSetCopySceneData_Param(self.g_SD_Monster_2, nStep1 + 1)
                self:LuaFnSetCopySceneData_Param(self.g_SD_Monster_2_T, nTime)
                self:CreateMonster_7_4()
                self:CreateMonster_7_3()
                self:TipAllHuman("Cảnh giác! Thứ" .. nStep1 .. "#YYến Tử Ổ#W viện quân đã đến, vẫn còn" .. 25 - (nStep1) .. "#YYến Tử Ổ#W viện quân sắp đến.")
                if nStep1 == 20 then
                    self:CreateMonster_8(2)
                end
            end
        end
        if nStep1 == 21 then
            if nTime - nPreTime >= 30 then
                self:LuaFnSetCopySceneData_Param(self.g_SD_Monster_2, nStep1 + 1)
            end
        end
        if nStep1 >= 22 and nStep1 < 27 then
            if nTime - nPreTime >= 30 then
                self:LuaFnSetCopySceneData_Param(self.g_SD_Monster_2, nStep1 + 1)
                self:LuaFnSetCopySceneData_Param(self.g_SD_Monster_2_T, nTime)
                self:CreateMonster_7_2()
                self:TipAllHuman("Cảnh giác! Thứ" .. nStep1 - 1 .. "#YYến Tử Ổ#W viện quân đã đến, vẫn còn" .. 25 - (nStep1 - 1) .. "#YYến Tử Ổ#W viện quân sắp đến.")
                if nStep1 == 26 then
                    self:CreateMonster_8(3)
                    self:LuaFnSetCopySceneData_Param(self.g_SceneData_1, 12)
                end
            end
        end
    end
    if nStep == 12 then
        local nNpcNum = self:GetMonsterCount()
        local bOK = false
        for i = 1, nNpcNum do
            local nNpcId = self:GetMonsterObjID(i)
            if self:GetName(nNpcId) == "钱宏宇" then
                bOK = true
            end
        end
        if bOK then
            self:LuaFnSetCopySceneData_Param(self.g_SceneData_1, 15)
            self:CreateMonster_9()
            self:CreateMonster_10()
            self:CreateMonster_11()
            self:CreateMonster_13()
        else
            self:LuaFnSetCopySceneData_Param(self.g_SceneData_1, 501)
        end
    end
    local nLost = self:LuaFnGetCopySceneData_Param(self.g_MissionLost)
    if nLost == 500 then
        self:CallScriptFunction((200060), "Paopao", "呼延庆", "燕子坞", "Do Hô Diên Báo tướng quân Thất bại, lần thảo phạt này Thất bại, chúng ta lui về, đợi chỉnh đốn lại rồi đến.")
        self:LuaFnSetCopySceneData_Param(self.g_MissionLost, 1000)
    end
    if nLost == 501 then
        self:CallScriptFunction((200060), "Paopao", "呼延庆", "燕子坞", "Do Tiền Hoành Vũ tướng quân Thất bại, lần thảo phạt này Thất bại, chúng ta lui về, đợi chỉnh đốn lại rồi đến.")
        self:LuaFnSetCopySceneData_Param(self.g_MissionLost, 1000)
    end
    local nCloaeTime = self:LuaFnGetCopySceneData_Param(self.g_CloseTime)
    if nLost == 1000 then
        self:TipAllHuman("Phó bản sẽ đóng sau 30 giây.")
        self:LuaFnSetCopySceneData_Param(self.g_CloseTime, nTime)
        self:LuaFnSetCopySceneData_Param(self.g_MissionLost, nLost + 1)
    end
    if nLost == 1001 and nTime - nCloaeTime >= 15 then
        self:TipAllHuman("Phó bản sẽ đóng sau 15 giây.")
        self:LuaFnSetCopySceneData_Param(self.g_CloseTime, nTime)
        self:LuaFnSetCopySceneData_Param(self.g_MissionLost, nLost + 1)
    end
    if nLost == 1002 and nTime - nCloaeTime >= 10 then
        self:TipAllHuman("Phó bản sẽ đóng sau 5 giây.")
        self:LuaFnSetCopySceneData_Param(self.g_CloseTime, nTime)
        self:LuaFnSetCopySceneData_Param(self.g_MissionLost, nLost + 1)
    end
    if nLost == 1003 and nTime - nCloaeTime >= 5 then
        local nHumanNum = self:LuaFnGetCopyScene_HumanCount()
        for i = 1, nHumanNum do
            local nPlayerId = self:LuaFnGetCopyScene_HumanObjId(i)
            self:NewWorld(nPlayerId, self.g_Back_SceneId, nil, self.g_Back_X, self.g_Back_Z)
        end
        self:LuaFnSetCopySceneData_Param(self.g_CloseTime, nTime)
        self:LuaFnSetCopySceneData_Param(self.g_MissionLost, nLost + 1)
    end
    local jianta1 = self:LuaFnGetCopySceneData_Param(self.g_SceneData_3)
    if jianta1 >= 5 and jianta1 < 1000 then
        self:ChangeNpc("前连弩塔")
        self:LuaFnSetCopySceneData_Param(self.g_SceneData_3, jianta1 + 1000)
    end
    local jianta2 = self:LuaFnGetCopySceneData_Param(self.g_SceneData_4)
    if jianta2 >= 5 and jianta2 < 1000 then
        self:ChangeNpc("后连弩塔")
        self:LuaFnSetCopySceneData_Param(self.g_SceneData_4, jianta2 + 1000)
    end
    local jianta3 = self:LuaFnGetCopySceneData_Param(self.g_SceneData_5)
    if jianta3 >= 10 and jianta3 < 1000 then
        self:ChangeNpc("治疗塔")
        self:LuaFnSetCopySceneData_Param(self.g_SceneData_5, jianta3 + 1000)
    end
    local jianta4 = self:LuaFnGetCopySceneData_Param(self.g_SceneData_6)
    if jianta4 >= 5 and jianta4 < 1000 then
        self:ChangeNpc("守御塔")
        self:LuaFnSetCopySceneData_Param(self.g_SceneData_6, jianta4 + 1000)
    end
    if nStep >= 11 then
        if nTime - nPreSystemTime >= 5 then
            self:LuaFnSetCopySceneData_Param(self.g_SystemTipsTime, nTime)
            if jianta1 > 1000 then
                local nNpcId = self:NameToId("前连弩塔")
                if nNpcId >= 0 then
                    if self:GetHp(nNpcId) > 0 then
                        local x
                        local z
                        x = self:GetWorldPos(nNpcId)
                        self:LuaFnUnitUseSkill(nNpcId, 1008, nNpcId, x, z, 10, 0)
                    end
                end
            end
            if jianta2 > 1000 then
                local nNpcId = self:NameToId("后连弩塔")
                if nNpcId >= 0 then
                    if self:GetHp(nNpcId) > 0 then
                        local x
                        local z
                        x = self:GetWorldPos(nNpcId)
                        self:LuaFnUnitUseSkill(nNpcId, 1008, nNpcId, x, z, 10, 0)
                    end
                end
            end
            if jianta3 > 1000 then
                local nNpcId = self:NameToId("治疗塔")
                if nNpcId >= 0 then
                    if self:GetHp(nNpcId) > 0 then
                        local x
                        local z
                        x = self:GetWorldPos(nNpcId)
                        self:LuaFnUnitUseSkill(nNpcId, 1010, nNpcId, x, z, 10, 0)
                    end
                end
            end
            if jianta4 > 1000 then
                local nNpcId = self:NameToId("守御塔")
                if nNpcId >= 0 then
                    if self:GetHp(nNpcId) > 0 then
                        local x
                        local z
                        x = self:GetWorldPos(nNpcId)
                        self:LuaFnUnitUseSkill(nNpcId, 1009, nNpcId, x, z, 10, 0)
                    end
                end
            end
        end
    end
    local bSpeak = self:LuaFnGetCopySceneData_Param(self.g_bWangyuyanSpeak)
    local nSpeakTime = self:LuaFnGetCopySceneData_Param(self.g_bWangyuyanSpeak_T)
    if bSpeak == 1 then
        self:CallScriptFunction((200060), "Paopao", "王语嫣", "燕子坞", "Đoàn công tử, chàng có thể giúp biểu ca ta được không?")
        self:LuaFnSetCopySceneData_Param(self.g_bWangyuyanSpeak, 2)
        self:LuaFnSetCopySceneData_Param(self.g_bWangyuyanSpeak_T, nTime)
    elseif bSpeak == 2 and nTime - nSpeakTime >= 1 then
        self:CallScriptFunction((200060), "Paopao", "段誉", "燕子坞", "Vương cô nương đã sai bảo, tại hạ dẫu muôn lần chết cũng không chối từ.#70")
        self:LuaFnSetCopySceneData_Param(self.g_bWangyuyanSpeak, 3)
        self:LuaFnSetCopySceneData_Param(self.g_bWangyuyanSpeak_T, nTime)
        local nNpcNum = self:GetMonsterCount()
        for i = 1, nNpcNum do
            local nNpcId = self:GetMonsterObjID(i)
            if self:GetName(nNpcId) == "段誉" then
                self:SetMonsterFightWithNpcFlag(nNpcId, 1)
                self:SetUnitCampID(nNpcId, 110)
                self:SetNPCAIType(nNpcId, 27)
                self:SetAIScriptID(nNpcId, 245)
            end
            if self:GetName(nNpcId) == "王语嫣" then
                self:SetMonsterFightWithNpcFlag(nNpcId, 0)
                self:SetUnitCampID(nNpcId, 110)
            end
        end
        self:LuaFnSetCopySceneData_Param(self.g_bWangyuyanSpeak, 3)
    elseif bSpeak == 3 and nTime - nSpeakTime >= 20 then
        self:CallScriptFunction((200060), "Paopao", "段誉", "燕子坞", "#18#18#18Vương cô nương, thật sự ngại quá, xem Lục Mạch Thần Kiếm của ta lúc linh lúc không này, giờ thì làm sao cũng không đả thương được người...")
        self:LuaFnSetCopySceneData_Param(self.g_bWangyuyanSpeak, 4)
        self:LuaFnSetCopySceneData_Param(self.g_bWangyuyanSpeak_T, nTime)
    elseif bSpeak == 4 and nTime - nSpeakTime >= 1 then
        self:CallScriptFunction((200060), "Paopao", "王语嫣", "燕子坞", "#20#20#20Lại giở trò này... Hay là ta tự mình giúp biểu ca vậy.")
        self:LuaFnSetCopySceneData_Param(self.g_bWangyuyanSpeak, 5)
        self:LuaFnSetCopySceneData_Param(self.g_bWangyuyanSpeak_T, nTime)
    elseif bSpeak == 5 then
        if nTime - nSpeakTime >= 10 then
            self:GiveDirections()
            self:LuaFnSetCopySceneData_Param(self.g_bWangyuyanSpeak_T, nTime)
        end
    end
    bSpeak = self:LuaFnGetCopySceneData_Param(self.g_DuanAndWangFlag)
    if bSpeak == 1 then
        self:CallScriptFunction((200060), "Paopao", "王语嫣", "燕子坞", "Biểu ca, cứu muội!")
        self:CallScriptFunction((200060), "Paopao", "段誉", "燕子坞", "Vương cô nương, ta đến cứu nàng đây!")
        local nNpcNum = self:GetMonsterCount()
        for i = 1, nNpcNum do
            local nNpcId = self:GetMonsterObjID(i)
            if self:GetName(nNpcId) == "段誉" then
                self:SetMonsterFightWithNpcFlag(nNpcId, 1)
                self:SetUnitCampID(nNpcId, 110)
                self:SetAIScriptID(nNpcId, 246)
            end
        end
        self:LuaFnSetCopySceneData_Param(self.g_DuanAndWangFlag, 2)
    end
end

function yanziwu_1:NameToId(szName)
    local nNpcId = -1
    local nMonsterNum = self:GetMonsterCount()
    for i = 1, nMonsterNum do
        local nMonsterId = self:GetMonsterObjID(i)
        if self:GetName(nMonsterId) == szName then
            nNpcId = nMonsterId
        end
    end
    return nNpcId
end

function yanziwu_1:CreateMonster_1()
    if self:LuaFnGetCopySceneData_Param(self.g_SceneData_1) == 0 then
        for i, Npc in pairs(self.g_Npc_1) do
            local nNpcId = self:CreateNpc(Npc["id"], Npc["x"], Npc["y"], Npc["ai"], Npc["af"], -1)
            local szName = self:GetName(nNpcId)
            self:SetUnitCampID(nNpcId, Npc["camp"])
            if szName == "宋军士兵" then
                self:SetMonsterFightWithNpcFlag(nNpcId, 1)
            elseif szName == "一品堂武士" then
                self:SetMonsterFightWithNpcFlag(nNpcId, 1)
            elseif szName == "燕子坞家丁" then
                self:SetMonsterFightWithNpcFlag(nNpcId, 1)
            end
        end
        for i, Npc in pairs(self.g_Npc_2) do
            local nNpcId = self:CreateNpc(Npc["id"], Npc["x"], Npc["y"], Npc["ai"], Npc["af"], Npc["script"])
            self:SetUnitCampID(nNpcId, Npc["camp"])
            self:SetMonsterFightWithNpcFlag(nNpcId, 0)
        end
        for i, Npc in pairs(self.g_Npc_2_1) do
            local nNpcId = self:CreateNpc(Npc["id"], Npc["x"], Npc["y"], Npc["ai"], Npc["af"], Npc["script"])
            self:SetUnitCampID(nNpcId, Npc["camp"])
            self:SetMonsterFightWithNpcFlag(nNpcId, 0)
        end
        for i, Npc in pairs(self.g_Npc_6) do
            local nNpcId = self:CreateNpc(Npc["id"], Npc["x"], Npc["y"], Npc["ai"], Npc["af"], Npc["script"])
            self:SetUnitCampID(nNpcId, Npc["camp"])
            self:SetMonsterFightWithNpcFlag(nNpcId, 0)
        end
        for i, Npc in pairs(self.g_Npc_7) do
            local nNpcId = self:CreateNpc(Npc["id"], Npc["x"], Npc["y"], Npc["ai"], Npc["af"], Npc["script"])
            self:SetUnitCampID(nNpcId, Npc["camp"])
            self:SetMonsterFightWithNpcFlag(nNpcId, 0)
            local szName = self:GetName(nNpcId)
            self:SetCharacterName(nNpcId, Npc["name"] .. szName)
        end
        self:LuaFnSetCopySceneData_Param(self.g_SceneData_1, 1)
    end
end

function yanziwu_1:CreateMonster_2()
    for i, Npc in pairs(self.g_Npc_3) do
        local nNpcId = self:CreateNpc(Npc["id"], Npc["x"], Npc["y"], Npc["ai"], Npc["af"], Npc["script"])
        self:SetUnitCampID(nNpcId, Npc["camp"])
        self:SetMonsterFightWithNpcFlag(nNpcId, 1)
        if self:GetName(nNpcId) == "岳老三" then
            self:LuaFnNpcChat(nNpcId, 0, "Cẩu quan, Nhạc Lão Nhị ta đến giết ngươi đây, mau đưa cái đầu ra đây, để ta \"khặc\" một tiếng vặn đứt cổ của ngươi.")
        end
    end
    self:CreateMonster_6()
    local nNpcNum = self:GetMonsterCount()
    for i = 1, nNpcNum do
        local nNpcId = self:GetMonsterObjID(i)
        if self:GetName(nNpcId) == "呼延豹" then
            self:SetMonsterFightWithNpcFlag(nNpcId, 1)
            return
        end
    end
end

function yanziwu_1:CreateMonster_3()
    for i, Npc in pairs(self.g_Npc_4) do
        local nNpcId = self:CreateNpc(Npc["id"], Npc["x"], Npc["y"], Npc["ai"], Npc["af"], Npc["script"])
        self:SetUnitCampID(nNpcId, Npc["camp"])
        self:SetMonsterFightWithNpcFlag(nNpcId, 1)
    end
    self:CreateMonster_6()
end

function yanziwu_1:CreateMonster_5()
    for i, Npc in pairs(self.g_Npc_5) do
        local nNpcId = self:CreateNpc(Npc["id"], Npc["x"], Npc["y"], Npc["ai"], Npc["af"], Npc["script"])
        self:SetUnitCampID(nNpcId, Npc["camp"])
        self:SetMonsterFightWithNpcFlag(nNpcId, 1)
    end
    self:CreateMonster_6()
end

function yanziwu_1:ChangeNpc(szName)
    local nNpcNum = self:GetMonsterCount()
    for i = 1, nNpcNum do
        local nNpcId = self:GetMonsterObjID(i)
        if self:GetName(nNpcId) == szName then
            self:SetUnitCampID(nNpcId, 109)
            self:SetMonsterFightWithNpcFlag(nNpcId, 1)
            self:LuaFnNpcChat(nNpcId, 0, szName .. "Ta đã được sửa chữa xong.")
        end
    end
end

function yanziwu_1:CreateMonster_6()
    for i, Npc in pairs(self.g_Npc_8) do
        local nNpcId = self:CreateNpc(Npc["id"], Npc["x"], Npc["y"], Npc["ai"], Npc["af"], Npc["script"])
        self:SetUnitCampID(nNpcId, Npc["camp"])
        self:SetMonsterFightWithNpcFlag(nNpcId, 1)
    end
end

function yanziwu_1:CreateMonster_7_1()
    for i, Npc in pairs(self.g_Npc_9) do
        local nNpcId = self:CreateNpc(Npc["id"], Npc["x"], Npc["y"], Npc["ai"], Npc["af"], Npc["script"])
        self:SetUnitCampID(nNpcId, Npc["camp"])
        self:SetMonsterFightWithNpcFlag(nNpcId, 1)
        self:SetPatrolId(nNpcId, Npc["pp"])
    end
end

function yanziwu_1:CreateMonster_7_3()
    for i, Npc in pairs(self.g_Npc_9_1) do
        local nNpcId = self:CreateNpc(Npc["id"], Npc["x"], Npc["y"], Npc["ai"], Npc["af"], Npc["script"])
        self:SetUnitCampID(nNpcId, Npc["camp"])
        self:SetMonsterFightWithNpcFlag(nNpcId, 1)
        self:SetPatrolId(nNpcId, Npc["pp"])
    end
end

function yanziwu_1:CreateMonster_7_4()
    for i, Npc in pairs(self.g_Npc_9_2) do
        local nNpcId = self:CreateNpc(Npc["id"], Npc["x"], Npc["y"], Npc["ai"], Npc["af"], Npc["script"])
        self:SetUnitCampID(nNpcId, Npc["camp"])
        self:SetMonsterFightWithNpcFlag(nNpcId, 1)
        self:SetPatrolId(nNpcId, Npc["pp"])
    end
end

function yanziwu_1:CreateMonster_7_2()
    for i, Npc in pairs(self.g_Npc_10) do
        local nNpcId = self:CreateNpc(Npc["id"], Npc["x"], Npc["y"], Npc["ai"], Npc["af"], Npc["script"])
        self:SetUnitCampID(nNpcId, Npc["camp"])
        self:SetMonsterFightWithNpcFlag(nNpcId, 1)
        self:SetPatrolId(nNpcId, Npc["pp"])
    end
end

function yanziwu_1:CreateMonster_8(nIndex)
    local Npc = self.g_Npc_11[nIndex]
    local nNpcId
    if nIndex == 3 then
        nNpcId = self:CreateNpc(Npc["id"], Npc["x"], Npc["y"], Npc["ai"], Npc["af"], Npc["script"])
    else
        nNpcId = self:CreateNpc(Npc["id"], Npc["x"], Npc["y"], Npc["ai"], Npc["af"], Npc["script"])
    end
    self:SetUnitCampID(nNpcId, Npc["camp"])
    self:SetMonsterFightWithNpcFlag(nNpcId, 1)
    self:SetPatrolId(nNpcId, Npc["pp"])
end

function yanziwu_1:CreateMonster_9()
    for i, Npc in pairs(self.g_Npc_12) do
        local nNpcId = self:CreateNpc(Npc["id"], Npc["x"], Npc["y"], Npc["ai"], Npc["af"], Npc["script"])
        self:SetUnitCampID(nNpcId, Npc["camp"])
        self:SetMonsterGroupID(nNpcId, 99)
    end
end

function yanziwu_1:CreateMonster_10()
    for i, Npc in pairs(self.g_Npc_13) do
        local nNpcId = self:CreateNpc(Npc["id"], Npc["x"], Npc["y"], Npc["ai"], Npc["af"], Npc["script"])
        self:SetUnitCampID(nNpcId, Npc["camp"])
        self:SetMonsterFightWithNpcFlag(nNpcId, 1)
    end
    local SceneNum = self:LuaFnGetCopyScene_HumanCount()
    for i = 1, SceneNum do
        local humanObjId = self:LuaFnGetCopyScene_HumanObjId(i)
        self:LuaFnAddMissionHuoYueZhi(humanObjId, 12)
        self:LuaFnAddSweepPointByID(humanObjId, 7, 1)
    end
end

function yanziwu_1:CreateMonster_11()
    for i, Npc in pairs(self.g_Npc_14) do
        local nNpcId = self:CreateNpc(Npc["id"], Npc["x"], Npc["y"], Npc["ai"], Npc["af"], Npc["script"])
        self:SetUnitCampID(nNpcId, Npc["camp"])
        --self:SetMonsterFightWithNpcFlag(nNpcId, 1)
    end
end

function yanziwu_1:CreateMonster_12()
    for i, Npc in pairs(self.g_Npc_15) do
        local nNpcId = self:CreateNpc(Npc["id"], Npc["x"], Npc["y"], Npc["ai"], Npc["af"], Npc["script"])
        self:SetUnitCampID(nNpcId, Npc["camp"])
        self:SetMonsterFightWithNpcFlag(nNpcId, 1)
    end
end

function yanziwu_1:CreateMonster_13()
    for i, Npc in pairs(self.g_Npc_16) do
        local nNpcId = self:CreateNpc(Npc["id"], Npc["x"], Npc["y"], Npc["ai"], Npc["af"], Npc["script"])
        self:SetUnitCampID(nNpcId, Npc["camp"])
        self:SetMonsterFightWithNpcFlag(nNpcId, 1)
    end
end

function yanziwu_1:ClearMonsterByName(szName)
    local nMonsterNum = self:GetMonsterCount()
    for i = 1, nMonsterNum do
        local nMonsterId = self:GetMonsterObjID(i)
        if self:GetName(nMonsterId) == szName then
            self:LuaFnDeleteMonster(nMonsterId)
        end
    end
end

function yanziwu_1:GiveDirections()
    local nWangId = -1
    local nMonsterNum = self:GetMonsterCount()
    for i = 1, nMonsterNum do
        local nMonsterId = self:GetMonsterObjID(i)
        if self:GetName(nMonsterId) == "王语嫣" then
            nWangId = nMonsterId
        end
    end
    if nWangId == -1 then
        return
    end
    local nHumanCount = self:LuaFnGetCopyScene_HumanCount()
    local nRand = math.random(1, nHumanCount)
    local nHumanId = self:LuaFnGetCopyScene_HumanObjId(nRand)
    self:LuaFnSendSpecificImpactToUnit(nWangId, nWangId, nHumanId, 10188, 2000)
    local szHumanName = self:GetName(nHumanId)
    local str1 = "Vương Ngữ Yên dời ánh mắt về phía #H[" .. szHumanName .. "】"
    local str = self:GetDirectionsDesc(self:GetMenPai(nHumanId))
    self:CallScriptFunction((200060), "Paopao", "王语嫣", "燕子坞", str)
    self:TipAllHuman(str1)
end

function yanziwu_1:CreateNpc(NpcId, x, y, Ai, AiFile, Script)
    local PlayerLevel = self:LuaFnGetCopySceneData_Param(self.g_SceneData_7)
    local ModifyLevel = 0
    if PlayerLevel >= 10 then
        ModifyLevel = 1
    end
    if PlayerLevel >= 20 then
        ModifyLevel = 2
    end
    if PlayerLevel >= 30 then
        ModifyLevel = 3
    end
    if PlayerLevel >= 40 then
        ModifyLevel = 4
    end
    if PlayerLevel >= 50 then
        ModifyLevel = 5
    end
    if PlayerLevel >= 60 then
        ModifyLevel = 6
    end
    if PlayerLevel >= 70 then
        ModifyLevel = 7
    end
    if PlayerLevel >= 80 then
        ModifyLevel = 8
    end
    if PlayerLevel >= 90 then
        ModifyLevel = 9
    end
    if PlayerLevel >= 100 then
        ModifyLevel = 30001
    end
    if PlayerLevel >= 110 then
        ModifyLevel = 30002
    end
    if PlayerLevel >= 120 then
        ModifyLevel = 30003
    end
    if PlayerLevel >= 130 then
        ModifyLevel = 30004
    end
    if PlayerLevel >= 140 then
        ModifyLevel = 30005
    end
    local nNpcId = NpcId + ModifyLevel - 1
    local nMonsterId = self:LuaFnCreateMonster(nNpcId, x, y, Ai, AiFile, Script)
    self:SetLevel(nMonsterId, PlayerLevel)
    self:SetNpcTitle(nMonsterId)
    return nMonsterId
end

function yanziwu_1:GetDirectionsDesc(MenpaiId)
    local str = ""
    if MenpaiId == 0 then
        str = "Biểu ca, nhược điểm của Đệ tử Thiếu Lâm ở huyệt Đại Chùy!"
    elseif MenpaiId == 1 then
        str = "Biểu ca, nhược điểm của Đệ tử Minh Giáo ở huyệt Linh Đài!"
    elseif MenpaiId == 2 then
        str = "Biểu ca, nhược điểm của Đệ tử Cái Bang ở huyệt Huyền Xu!"
    elseif MenpaiId == 3 then
        str = "Biểu ca, nhược điểm của Đệ tử Võ Đang ở huyệt Bách Hội!"
    elseif MenpaiId == 4 then
        str = "Biểu ca, nhược điểm của Đệ tử Nga My ở huyệt Thần Đình!"
    elseif MenpaiId == 5 then
        str = "Biểu ca, nhược điểm của Đệ tử Tinh Túc ở huyệt Thái Dương!"
    elseif MenpaiId == 6 then
        str = "Biểu ca, nhược điểm của Đệ tử Thiên Long ở huyệt Đản Trung!"
    elseif MenpaiId == 7 then
        str = "Biểu ca, nhược điểm của Đệ tử Thiên Sơn ở huyệt Cưu Vĩ!"
    elseif MenpaiId == 8 then
        str = "Biểu ca, nhược điểm của Đệ tử Tiêu Dao ở huyệt Thương Khúc!"
    end
    return str
end

function yanziwu_1:SetNpcTitle(nNpcId)
    local szName = self:GetName(nNpcId)
    if szName == "呼延庆" then
        self:SetCharacterTitle(nNpcId, "太湖水军大都督")
    elseif szName == "呼延豹" then
        self:SetCharacterTitle(nNpcId, "Thủy Quân Tiên Phong")
    elseif szName == "钱宏宇" then
        self:SetCharacterTitle(nNpcId, "苏州校尉")
    elseif szName == "岳老三" then
        self:SetCharacterTitle(nNpcId, "“凶神恶煞”")
    elseif szName == "叶二娘" then
        self:SetCharacterTitle(nNpcId, "“无恶不作”")
    elseif szName == "云中鹤" then
        self:SetCharacterTitle(nNpcId, "“穷凶极恶”")
    elseif szName == "段延庆" then
        self:SetCharacterTitle(nNpcId, "“恶贯满盈”")
    elseif szName == "姚伯当" then
        self:SetCharacterTitle(nNpcId, "Trại Chủ Tần Gia Trại")
    elseif szName == "司马林" then
        self:SetCharacterTitle(nNpcId, "Chưởng Môn phái Thanh Thành")
    elseif szName == "鸠摩智" then
        self:SetCharacterTitle(nNpcId, "大轮明王")
    elseif szName == "慕容复" then
        self:SetCharacterTitle(nNpcId, "\"Đấu Chuyển Tinh Di\"")
    end
end

function yanziwu_1:CalSweepData(selfId)
    local nTimes = self:GetMissionData(selfId, define.MD_ENUM.MD_YANZIWU_TIMES)
    local nCurTime = self:LuaFnGetCurrentTime()
    self:SetMissionData(selfId, define.MD_ENUM.MD_YANZIWU_TIMES, nTimes + 1)
    self:SetMissionData(selfId, define.MD_ENUM.MD_PRE_YANZIWU_TIME, nCurTime)
end

return yanziwu_1