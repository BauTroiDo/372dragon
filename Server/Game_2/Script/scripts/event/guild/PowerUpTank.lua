local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ExchangeTank = class("ExchangeTank", script_base)
ExchangeTank.script_id = 600052
ExchangeTank.g_Name = "上官冰"
ExchangeTank.g_Name2 = "上官雪"
ExchangeTank.g_A_LingShiIndex = 2
ExchangeTank.g_B_LingShiIndex = 7
ExchangeTank.g_LingShi = {
    "Thanh Long Thạch", "Bạch Hổ Thạch", "Chu Tước Thạch", "Ô Ô Thạch", "Bàn Cổ Thạch"
}
ExchangeTank.g_GuildPoint_ExchangeTank = 6
ExchangeTank.g_WantLingShiNum = 20
ExchangeTank.g_TankID = {
    13334, 13335, 13336, 13337, 13338, 13339, 13340, 13341, 13342, 13343
}
ExchangeTank.g_AttrBuff = {
    31567, 31568, 31569, 31570, 31571, 31572, 31573, 31574, 31575, 31576
}
ExchangeTank.g_ImmuneControlBuff = 10474
ExchangeTank.g_A_FirstTankManSelfID = 13
ExchangeTank.g_A_SecondTankManSelfID = 14
ExchangeTank.g_B_FirstTankManSelfID = 15
ExchangeTank.g_B_SecondTankManSelfID = 16
ExchangeTank.g_A_FirstTankBuff = 17
ExchangeTank.g_A_SecondTankBuff = 18
ExchangeTank.g_B_FirstTankBuff = 19
ExchangeTank.g_B_SecondTankBuff = 20
ExchangeTank.g_A_FirstTankPos = 21
ExchangeTank.g_A_SecondTankPos = 22
ExchangeTank.g_B_FirstTankPos = 23
ExchangeTank.g_B_SecondTankPos = 24
ExchangeTank.g_DefaultTankPos = {{47, 39}, {47, 39}, {203, 215}, {203, 215}}
ExchangeTank.g_TankName = {
    "Thanh Long Chiến Xa", "Bạch Hổ Chiến Xa", "Chu Tước Chiến Xa", "Huyền Ô Chiến Xa",
    "Bàn Cổ Chiến Xa"
}
ExchangeTank.g_Msg = {
    "#{BHXZ_081103_55}", "#{BHXZ_081103_46}", "#{BHXZ_081103_48}",
    "#{BHXZ_081103_50}", "#{BHXZ_081103_52}"
}
ExchangeTank.g_BangzhanScriptId = 402047
function ExchangeTank:OnDefaultEvent(selfId, targetId, index)
    local numText = index
    if numText == 1 then
        self:BeginEvent(self.script_id)
        self:AddText("#{BHXZ_081103_41}")
        for i = 1, #(self.g_TankName) do
            self:AddNumText(self.g_TankName[i], 4, i * 1000)
        end
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if numText == 2 then
        self:BeginEvent(self.script_id)
        self:AddText("#{BHXZ_081103_59}")
        for i = 1, #(self.g_TankName) do
            self:AddNumText(self.g_TankName[i], 4, i * 1000 + 5000)
        end
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    local TankManFirst
    local TankManSecond
    local base
    local intbase
    local isguildA
    local guildid
    local beginindex
    local totalguildid = self:LuaFnGetCopySceneData_Param(6)
    if self:GetName(targetId) == self.g_Name then
        TankManFirst = self:LuaFnGetCopySceneData_Param(self.g_A_FirstTankManSelfID)
        TankManSecond = self:LuaFnGetCopySceneData_Param(self.g_A_SecondTankManSelfID)
        base = 5
        intbase = 0
        isguildA = 1
        guildid = math.floor(totalguildid / 10000)
        beginindex = self.g_A_LingShiIndex
    else
        TankManFirst = self:LuaFnGetCopySceneData_Param(self.g_B_FirstTankManSelfID)
        TankManSecond = self:LuaFnGetCopySceneData_Param(self.g_B_SecondTankManSelfID)
        base = 0
        intbase = 2
        isguildA = 0
        guildid = totalguildid % 10000
        beginindex = self.g_B_LingShiIndex
    end
    if numText == 1000 or numText == 2000 or numText == 3000 or numText == 4000 or
        numText == 5000 then
        self:BeginEvent(self.script_id)
        index = numText // 1000
        if (TankManFirst ~= 0 and
            self:CallScriptFunction(self.g_BangzhanScriptId, "HaveTankBuff",
                                    TankManFirst) ==
            self.g_AttrBuff[index + base]) or (TankManSecond ~= 0 and
            self:CallScriptFunction(self.g_BangzhanScriptId, "HaveTankBuff",
                                    TankManSecond) ==
            self.g_AttrBuff[index + base]) or
            (self:FindWildTank(index + base) ~= 0) then
            self:AddText("  Muốn để cho chiếc" .. self.g_TankName[index] ..
                             "#{BHXZ_081103_54}")
            for i = 1, #(self.g_TankName) do
                if index ~= i then
                    self:AddNumText(self.g_TankName[i], 4, numText + i * 100)
                end
            end
            self:AddNumText("Bước trước", 8, 1)
        else
            self:AddText("#{BHXZ_081103_42}" .. self.g_TankName[index] .. "。")
        end
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if numText == 6000 or numText == 7000 or numText == 8000 or numText == 9000 or
        numText == 10000 then
        self:BeginEvent(self.script_id)
        index = numText // 1000
        index = index - 5
        if (TankManFirst ~= 0 and
            self:CallScriptFunction(self.g_BangzhanScriptId, "HaveTankBuff",
                                    TankManFirst) ==
            self.g_AttrBuff[index + base]) or (TankManSecond ~= 0 and
            self:CallScriptFunction(self.g_BangzhanScriptId, "HaveTankBuff",
                                    TankManSecond) ==
            self.g_AttrBuff[index + base]) or
            (self:FindWildTank(index + base) ~= 0) then

            self:AddText("    #{BHXZ_081103_152}" .. self.g_TankName[index] ..
                             "#{BHXZ_081103_153}")
            self:AddNumText("Xác nhận", 8, numText + 100)
            self:AddNumText("Hủy bỏ", 8, numText + 200)
        else
            self:AddText("#{BHXZ_081103_42}" .. self.g_TankName[index] .. "。")
        end
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if numText > 1000 and numText < 6000 then
        local thousand = math.floor(numText / 1000)
        local hundred = math.floor((numText - thousand * 1000) / 100)
        if hundred == 0 or hundred >= #(self.g_TankName) + 1 or thousand ==
            hundred then return end
        local ten = math.floor((numText - thousand * 1000 - hundred * 100) / 10)
        if ten == 0 then
            if (TankManFirst ~= 0 and
                self:CallScriptFunction(self.g_BangzhanScriptId, "HaveTankBuff",
                                        TankManFirst) ==
                self.g_AttrBuff[hundred + base]) or (TankManSecond ~= 0 and
                self:CallScriptFunction(self.g_BangzhanScriptId, "HaveTankBuff",
                                        TankManSecond) ==
                self.g_AttrBuff[hundred + base]) or
                (self:FindWildTank(hundred + base) ~= 0) then
                self:NotifyFailBox(selfId, targetId, "#{BHXZ_081103_44}" ..
                                       self.g_TankName[hundred] ..
                                       "#{BHXZ_081103_45}")

            else
                self:BeginEvent(self.script_id)
                self:AddText(self.g_Msg[hundred])
                self:AddNumText("Xác nhận", 8, numText + 10)
                self:AddNumText("Hủy bỏ", 8, numText + 20)
                self:EndEvent()
                self:DispatchEventList(selfId, targetId)
            end
        elseif ten == 1 then
            if TankManFirst ~= 0 and
                self:CallScriptFunction(self.g_BangzhanScriptId, "HaveTankBuff",
                                        TankManFirst) ==
                self.g_AttrBuff[thousand + base] then
                if (TankManSecond ~= 0 and
                    self:CallScriptFunction(self.g_BangzhanScriptId,
                                            "HaveTankBuff", TankManSecond) ==
                    self.g_AttrBuff[hundred + base]) or
                    (self:FindWildTank(hundred + base) ~= 0) then

                    self:NotifyFailBox(selfId, targetId, "#{BHXZ_081103_44}" ..
                                           self.g_TankName[hundred] ..
                                           "#{BHXZ_081103_45}")
                else
                    local num = self:GetGuildIntNum(guildid,beginindex + hundred - 1)
                    if num < self.g_WantLingShiNum then
                        self:NotifyFailBox(selfId, targetId,
                                           "#{BHXZ_081103_47}" ..
                                               self.g_LingShi[hundred] ..
                                               "#{BHXZ_081103_56}" .. num)
                    else
                        num = num - self.g_WantLingShiNum
                        self:SetGuildIntNum(guildid, beginindex + hundred - 1, num)
                        self:LuaFnSetCopySceneData_Param(
                            self.g_A_FirstTankManSelfID + intbase, 0)
                        self:LuaFnSetCopySceneData_Param(
                            self.g_A_FirstTankBuff + intbase, 0)
                        self:LuaFnSetCopySceneData_Param(
                            self.g_A_FirstTankPos + intbase, 0)
                        self:LuaFnCancelSpecificImpact(TankManFirst,
                                                       self.g_AttrBuff[thousand +
                                                           base])
                        local selfIdindex =
                            self:CallScriptFunction(600051, "FindTankManIndex",
                                                    isguildA, hundred + base)
                        if selfIdindex > 0 then
                            local PosX, PosZ = self:GetWorldPos(TankManFirst)
                            local monsterID =
                                self:LuaFnCreateMonster(
                                    self.g_TankID[hundred + base], PosX, PosZ,
                                    3, -1, 402302)
                            self:LuaFnSendSpecificImpactToUnit(monsterID,
                                                               monsterID,
                                                               monsterID,
                                                               self.g_ImmuneControlBuff,
                                                               0)
                        end
                        local addpoint =
                            self:GetGuildWarPoint(self.g_GuildPoint_ExchangeTank)
                        if isguildA == 1 then
                            self:CallScriptFunction(self.g_BangzhanScriptId,
                                                    "AddAGuildPoint", 0,
                                                    guildid, addpoint)
                        else
                            self:CallScriptFunction(self.g_BangzhanScriptId,
                                                    "AddBGuildPoint", 0,
                                                    guildid, addpoint)
                        end
                        self:NotifyFailBox(selfId, targetId,
                                           "#{BHXZ_081103_111}")
                        self:Msg2Player(selfId,
                                        "#{BHXZ_081103_138}" ..
                                            self.g_TankName[thousand] ..
                                            "Đã chuyển thành" ..
                                            self.g_TankName[hundred] .. "。",
                                        define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
                    end
                end
            elseif TankManSecond ~= 0 and
                self:CallScriptFunction(self.g_BangzhanScriptId, "HaveTankBuff",
                                        TankManSecond) ==
                self.g_AttrBuff[thousand + base] then
                if (TankManFirst ~= 0 and
                    self:CallScriptFunction(self.g_BangzhanScriptId,
                                            "HaveTankBuff", TankManFirst) ==
                    self.g_AttrBuff[hundred + base]) or
                    (self:FindWildTank(hundred + base) ~= 0) then
                    self:NotifyFailBox(selfId, targetId, "#{BHXZ_081103_44}" ..
                                           self.g_TankName[hundred] ..
                                           "#{BHXZ_081103_45}")
                else
                    local num = self:GetGuildIntNum(guildid,
                                                    beginindex + hundred - 1)
                    if num < self.g_WantLingShiNum then
                        self:NotifyFailBox(selfId, targetId,
                                           "#{BHXZ_081103_47}" ..
                                               self.g_LingShi[hundred] ..
                                               "#{BHXZ_081103_56}" .. num)
                    else
                        num = num - self.g_WantLingShiNum
                        self:SetGuildIntNum(guildid, beginindex + hundred - 1,
                                            num)
                        self:LuaFnSetCopySceneData_Param(
                            self.g_A_SecondTankManSelfID + intbase, 0)
                        self:LuaFnSetCopySceneData_Param(
                            self.g_A_SecondTankBuff + intbase, 0)
                        self:LuaFnSetCopySceneData_Param(
                            self.g_A_SecondTankPos + intbase, 0)
                        self:LuaFnCancelSpecificImpact(TankManSecond,
                                                       self.g_AttrBuff[thousand +
                                                           base])
                        local selfIdindex =
                            self:CallScriptFunction(600051, "FindTankManIndex",
                                                    isguildA, hundred + base)
                        if selfIdindex > 0 then
                            local PosX, PosZ = self:GetWorldPos(TankManSecond)
                            local monsterID =
                                self:LuaFnCreateMonster(
                                    self.g_TankID[hundred + base], PosX, PosZ,
                                    3, -1, 402302)

                            self:LuaFnSendSpecificImpactToUnit(monsterID,
                                                               monsterID,
                                                               monsterID,
                                                               self.g_ImmuneControlBuff,
                                                               0)
                        end
                        local addpoint =
                            self:GetGuildWarPoint(self.g_GuildPoint_ExchangeTank)
                        if isguildA == 1 then
                            self:CallScriptFunction(self.g_BangzhanScriptId,
                                                    "AddAGuildPoint", 0,
                                                    guildid, addpoint)
                        else
                            self:CallScriptFunction(self.g_BangzhanScriptId,
                                                    "AddBGuildPoint", 0,
                                                    guildid, addpoint)
                        end
                        self:NotifyFailBox(selfId, targetId,
                                           "#{BHXZ_081103_111}")
                        self:Msg2Player(selfId,
                                        "#{BHXZ_081103_138}" ..
                                            self.g_TankName[thousand] ..
                                            "Đã chuyển thành" ..
                                            self.g_TankName[hundred] .. "。",
                                        define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
                    end
                end
            else
                local tankobjID = self:FindWildTank(thousand + base)
                if tankobjID ~= 0 then
                    local PosX, PosZ = self:GetWorldPos(tankobjID)
                    if (TankManFirst ~= 0 and
                        self:CallScriptFunction(self.g_BangzhanScriptId,
                                                "HaveTankBuff", TankManFirst) ==
                        self.g_AttrBuff[hundred + base]) or
                        (TankManSecond ~= 0 and
                            self:CallScriptFunction(self.g_BangzhanScriptId,
                                                    "HaveTankBuff",
                                                    TankManSecond) ==
                            self.g_AttrBuff[hundred + base]) or
                        (self:FindWildTank(hundred + base) ~= 0) then
                        self:NotifyFailBox(selfId, targetId,
                                           "#{BHXZ_081103_44}" ..
                                               self.g_TankName[hundred] ..
                                               "#{BHXZ_081103_45}")
                    else
                        local num = self:GetGuildIntNum(guildid, beginindex +
                                                            hundred - 1)
                        if num < self.g_WantLingShiNum then
                            self:NotifyFailBox(selfId, targetId,
                                               "#{BHXZ_081103_47}" ..
                                                   self.g_LingShi[hundred] ..
                                                   "#{BHXZ_081103_56}" .. num)
                        else
                            num = num - self.g_WantLingShiNum
                            self:SetGuildIntNum(guildid,
                                                beginindex + hundred - 1, num)
                            self:LuaFnDeleteMonster(tankobjID)
                            local monsterID =
                                self:LuaFnCreateMonster(
                                    self.g_TankID[hundred + base], PosX, PosZ,
                                    3, -1, 402302)
                            self:LuaFnSendSpecificImpactToUnit(monsterID,
                                                               monsterID,
                                                               monsterID,
                                                               self.g_ImmuneControlBuff,
                                                               0)
                            local addpoint =
                                self:GetGuildWarPoint(
                                    self.g_GuildPoint_ExchangeTank)
                            if isguildA == 1 then
                                self:CallScriptFunction(self.g_BangzhanScriptId,
                                                        "AddAGuildPoint", 0,
                                                        guildid, addpoint)
                            else
                                self:CallScriptFunction(self.g_BangzhanScriptId,
                                                        "AddBGuildPoint", 0,
                                                        guildid, addpoint)
                            end
                            self:NotifyFailBox(selfId, targetId,
                                               "#{BHXZ_081103_111}")
                            self:Msg2Player(selfId,
                                            "#{BHXZ_081103_138}" ..
                                                self.g_TankName[thousand] ..
                                                "Đã chuyển thành" ..
                                                self.g_TankName[hundred] ..
                                                "。", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
                        end
                    end
                else
                    self:NotifyFailBox(selfId, targetId, "#{BHXZ_081103_42}" ..
                                           self.g_TankName[thousand] .. "。")
                end
            end
        elseif ten == 2 then
            self:BeginUICommand()
            self:UICommand_AddInt(targetId)
            self:EndUICommand()
            self:DispatchUICommand(selfId, 1000)
        end
        return
    end
    if numText > 6000 and numText < 11000 then
        local thousand = math.floor(numText / 1000)
        local hundred = math.floor((numText - thousand * 1000) / 100)
        thousand = thousand - 5
        if hundred == 1 then
            local countarray = {}
            for i = 0, 4 do
                countarray[i + 1] = self:GetGuildIntNum(guildid, beginindex + i)
                if countarray[i + 1] < self.g_WantLingShiNum then
                    self:NotifyFailBox(selfId, targetId, "#{BHXZ_081103_151}")
                    return
                end
            end
            if TankManFirst ~= 0 and
                self:CallScriptFunction(self.g_BangzhanScriptId, "HaveTankBuff",
                                        TankManFirst) ==
                self.g_AttrBuff[thousand + base] then
                self:BeginUICommand()
                self:UICommand_AddInt(self.script_id)
                self:UICommand_AddInt(targetId)
                self:UICommand_AddInt(thousand + base)
                self:UICommand_AddStr("ChangeOK")
                self:UICommand_AddStr("    #{BHXZ_081103_152}" ..
                                          self.g_TankName[thousand] ..
                                          "#{BHXZ_081103_153}")
                self:EndUICommand()
                self:DispatchUICommand(selfId, 24)
            elseif TankManSecond ~= 0 and
                self:CallScriptFunction(self.g_BangzhanScriptId, "HaveTankBuff",
                                        TankManSecond) ==
                self.g_AttrBuff[thousand + base] then
                self:BeginUICommand()
                self:UICommand_AddInt(self.script_id)
                self:UICommand_AddInt(targetId)
                self:UICommand_AddInt(thousand + base)
                self:UICommand_AddStr("ChangeOK")
                self:UICommand_AddStr("    #{BHXZ_081103_152}" ..
                                          self.g_TankName[thousand] ..
                                          "#{BHXZ_081103_153}")
                self:EndUICommand()
                self:DispatchUICommand(selfId, 24)
            else
                local tankobjID = self:FindWildTank(thousand + base)
                if tankobjID ~= 0 then
                    self:BeginUICommand()
                    self:UICommand_AddInt(self.script_id)
                    self:UICommand_AddInt(targetId)
                    self:UICommand_AddInt(thousand + base)
                    self:UICommand_AddStr("ChangeOK")
                    self:UICommand_AddStr(
                        "    #{BHXZ_081103_152}" .. self.g_TankName[thousand] ..
                            "#{BHXZ_081103_153}")
                    self:EndUICommand()
                    self:DispatchUICommand(selfId, 24)
                else
                    self:NotifyFailBox(selfId, targetId, "#{BHXZ_081103_42}" ..
                                         self.g_TankName[thousand] .. "。")
                end
            end
        elseif hundred == 2 then
            self:BeginUICommand()
            self:UICommand_AddInt(targetId)
            self:EndUICommand()
            self:DispatchUICommand(selfId, 1000)
        end
        return
    end
end

function ExchangeTank:ChangeOK(selfId, targetId, tanktype)
    local sceneId = self:get_scene_id()
    if not sceneId or not selfId or not targetId or not tanktype then return end
    local TankManFirst
    local TankManSecond
    local intbase
    local guildid
    local beginindex
    local totalguildid = self:LuaFnGetCopySceneData_Param(6)
    if self:GetName(targetId) == self.g_Name then
        TankManFirst = self:LuaFnGetCopySceneData_Param(
                           self.g_A_FirstTankManSelfID)
        TankManSecond = self:LuaFnGetCopySceneData_Param(
                            self.g_A_SecondTankManSelfID)
        intbase = 0
        guildid = math.floor(totalguildid / 10000)
        beginindex = self.g_A_LingShiIndex
        if tanktype < 6 or tanktype > 10 then return end
    elseif self:GetName(targetId) == self.g_Name2 then
        TankManFirst = self:LuaFnGetCopySceneData_Param(
                           self.g_B_FirstTankManSelfID)
        TankManSecond = self:LuaFnGetCopySceneData_Param(
                            self.g_B_SecondTankManSelfID)
        intbase = 2
        guildid = totalguildid % 10000
        beginindex = self.g_B_LingShiIndex
        if tanktype < 1 or tanktype > 5 then return end
    else
        return
    end
    if guildid ~= self:GetHumanGuildID(selfId) then return end
    local countarray = {}
    for i = 0, 4 do
        countarray[i + 1] = self:GetGuildIntNum(guildid, beginindex + i)
        if countarray[i + 1] < self.g_WantLingShiNum then
            self:NotifyFailBox(selfId, targetId, "#{BHXZ_081103_151}")
            return
        end
    end
    if TankManFirst ~= 0 and
        self:CallScriptFunction(self.g_BangzhanScriptId, "HaveTankBuff",
                                TankManFirst) == self.g_AttrBuff[tanktype] then
        for i = 0, 4 do
            self:SetGuildIntNum(guildid, beginindex + i, countarray[i + 1] - 20)
        end
        self:SetPos(TankManFirst, self.g_DefaultTankPos[1 + intbase][1],
                    self.g_DefaultTankPos[1 + intbase][2])
        if 1 <= tanktype and tanktype <= 5 then
            self:NotifyFailBox(selfId, targetId, "   " ..
                                   self.g_TankName[tanktype] ..
                                   "#{BHXZ_081103_154}")
            self:Msg2Player(selfId, "#{BHXZ_081103_138}" ..
                                self.g_TankName[tanktype] ..
                                "#{BHXZ_081103_139}", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
        elseif 6 <= tanktype and tanktype <= 10 then
            self:NotifyFailBox(selfId, targetId, "   " ..
                                   self.g_TankName[tanktype - 5] ..
                                   "#{BHXZ_081103_154}")
            self:Msg2Player(selfId, "#{BHXZ_081103_138}" ..
                                self.g_TankName[tanktype - 5] ..
                                "#{BHXZ_081103_139}", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
        end
    elseif TankManSecond ~= 0 and
        self:CallScriptFunction(self.g_BangzhanScriptId, "HaveTankBuff",
                                TankManSecond) == self.g_AttrBuff[tanktype] then
        for i = 0, 4 do
            self:SetGuildIntNum(guildid, beginindex + i, countarray[i + 1] - 20)
        end
        self:SetPos(TankManFirst, self.g_DefaultTankPos[1 + intbase][1],
                    self.g_DefaultTankPos[1 + intbase][2])
        if 1 <= tanktype and tanktype <= 5 then
            self:NotifyFailBox(selfId, targetId, "   " ..
                                   self.g_TankName[tanktype] ..
                                   "#{BHXZ_081103_154}")
            self:Msg2Player(selfId, "#{BHXZ_081103_138}" ..
                                self.g_TankName[tanktype] ..
                                "#{BHXZ_081103_139}", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
        elseif 6 <= tanktype and tanktype <= 10 then
            self:NotifyFailBox(selfId, targetId, "   " ..
                                   self.g_TankName[tanktype - 5] ..
                                   "#{BHXZ_081103_154}")
            self:Msg2Player(selfId, "#{BHXZ_081103_138}" ..
                                self.g_TankName[tanktype - 5] ..
                                "#{BHXZ_081103_139}", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
        end
    else
        local tankobjID = self:FindWildTank(tanktype)
        if tankobjID ~= 0 then
            for i = 0, 4 do
                self:SetGuildIntNum(guildid, beginindex + i,
                                    countarray[i + 1] - 20)
            end
            self:SetPos(tankobjID, self.g_DefaultTankPos[1 + intbase][1],
                        self.g_DefaultTankPos[1 + intbase][2])
            if 1 <= tanktype and tanktype <= 5 then
                self:NotifyFailBox(selfId, targetId, "   " ..
                                       self.g_TankName[tanktype] ..
                                       "#{BHXZ_081103_154}")
                self:Msg2Player(selfId, "#{BHXZ_081103_138}" ..
                                    self.g_TankName[tanktype] ..
                                    "#{BHXZ_081103_139}", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
            elseif 6 <= tanktype and tanktype <= 10 then
                self:NotifyFailBox(selfId, targetId, "   " ..
                                       self.g_TankName[tanktype - 5] ..
                                       "#{BHXZ_081103_154}")
                self:Msg2Player(selfId, "#{BHXZ_081103_138}" ..
                                    self.g_TankName[tanktype - 5] ..
                                    "#{BHXZ_081103_139}", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
            end
        else
            if 1 <= tanktype and tanktype <= 5 then
                self:NotifyFailBox(selfId, targetId, "#{BHXZ_081103_42}" ..
                                       self.g_TankName[tanktype] .. "。")
            elseif 6 <= tanktype and tanktype <= 10 then
                self:NotifyFailBox(selfId, targetId, "#{BHXZ_081103_42}" ..
                                       self.g_TankName[tanktype - 5] .. "。")
            end
        end
    end
end

function ExchangeTank:OnEnumerate(caller, selfId, targetId, arg, index)
    caller:AddNumTextWithTarget(self.script_id, "#{BHXZ_081103_40}", 4, 1)
    caller:AddNumTextWithTarget(self.script_id, "#{BHXZ_081103_58}", 4, 2)
end

function ExchangeTank:FindWildTank(tankIDindex)
    local tankID = self.g_TankID[tankIDindex]
    if not tankID then return 0 end
    local nNpcNum = self:GetMonsterCount()
    for i = 1, nNpcNum do
        local nNpcId = self:GetMonsterObjID(i)
        local DataId = self:GetMonsterDataID(nNpcId)
        if DataId == tankID then return nNpcId end
    end
    return 0
end

function ExchangeTank:CheckAccept(selfId, targetId) return 1 end

function ExchangeTank:OnAccept(selfId, targetId) end

function ExchangeTank:OnContinue(selfId, targetId) end

function ExchangeTank:OnAbandon(selfId) end

function ExchangeTank:CheckSubmit(selfId) return 1 end

function ExchangeTank:OnSubmit(selfId, targetId, selectRadioId) end

function ExchangeTank:NotifyFailBox(selfId, targetId, msg)
    self:BeginEvent(self.script_id)
    self:AddText(msg)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function ExchangeTank:NotifyFailTips(selfId, Tip)
    self:BeginEvent(self.script_id)
    self:AddText(Tip)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

return ExchangeTank
