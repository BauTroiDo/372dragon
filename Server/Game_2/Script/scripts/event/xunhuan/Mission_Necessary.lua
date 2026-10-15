local gbk = require "wire_charset"
local class = require "class"
local define = require "define"
local script_base = require "script_base"
local Mission_Necessary = class("Mission_Necessary", script_base)
local ScriptGlobal = require "scripts.ScriptGlobal"
Mission_Necessary.script_id = 500501
Mission_Necessary.HeKaId = { 20310011, 20310017, 20310012, 20310019, 20310014, 20310018, 20310015, 20310016, 20310013 }
Mission_Necessary.g_StartDayTime = 8030
Mission_Necessary.g_EndDayTime = 8044
Mission_Necessary.g_strDieNotice0 = "#{SMRW_20080118_01}"
Mission_Necessary.g_strDieNotice1 = "#{SMRW_20080118_02}"
Mission_Necessary.g_ItemId = { 30501101, 30501102 }
Mission_Necessary.g_LingShouDanId = { 30503034, 30503043, 30503052, 30503061 }
Mission_Necessary.g_strHelpFinishedText = "  Đồng môn hữu nạn, lý đương tương trợ, nhiệm vụ của ngươi ta đã an bài Khác đồng môn đi hoàn thành rồi.#r#GNhiệm vụ hoàn thành!#W"
function Mission_Necessary:ACT_Duanwu(selfId, iDayHuan)
    local DayTime = self:GetDayTime()
    local Duanwu_Cyc = 20
    local Duanwu_Zongzi = 30501100
    local Duanwu_GemDataGlobalIndex = 40
    local Duanwu_MaxGemCount = 2000
    local Duanwu_GemData = self:LuaFnGetWorldGlobalData(Duanwu_GemDataGlobalIndex)
    local Duanwu_Daytime = math.floor(Duanwu_GemData / 10000)
    local Duanwu_GemCount = Duanwu_GemData % 10000
    local DuanwuGemList = { 50101001, 50101002, 50102001, 50102002, 50102003, 50102004, 50103001, 50104002, 50111001,
        50111002, 50112001, 50112002, 50112003, 50112004, 50113001, 50113002, 50113003, 50113004, 50113005, 50114001 }
    if iDayHuan <= 0 then
        return
    end
    if DayTime < 7168 or DayTime > 7175 then
        return
    end
    local ModHuan = iDayHuan % Duanwu_Cyc
    if 0 ~= ModHuan then
        return
    end
    self:BeginAddItem()
    self:AddItem(Duanwu_Zongzi, 1)
    local AddRet = self:EndAddItem(selfId)
    if AddRet then
        self:AddItemListToHuman(selfId)
        local Gemable = math.random(100)
        if Gemable > 20 then
            return
        end
        if DayTime ~= Duanwu_Daytime then
            Duanwu_Daytime = DayTime
            Duanwu_GemCount = 0
        end
        if Duanwu_GemCount >= Duanwu_MaxGemCount then
            return
        end
        local GemListSize =#(DuanwuGemList)
        local RandomGem = DuanwuGemList[math.random(GemListSize)]
        self:BeginAddItem()
        self:AddItem(RandomGem, 1)
        local GemRet = self:EndAddItem(selfId)
        if GemRet then
            self:AddItemListToHuman(selfId)
            local GemInfo = self:GetItemTransfer(selfId, 0)
            local strformat = "#{_INFOUSR%s}# trong hoạt động Tết Đoan Ngọ, vì hoàn thành Khuyên thứ 20 của nhiệm vụ Sư Môn, được sư phụ khen ngợi, không những nhận được một hạt Bánh Tống Tử, mà còn bất ngờ nhận được một viên #Y#{_INFOMSG%s}."
            local strText = string.format(strformat, self:GetName(selfId), GemInfo)
            Duanwu_GemData = DayTime * 10000 + Duanwu_GemCount + 1
            self:LuaFnSetWorldGlobalData(Duanwu_GemDataGlobalIndex, Duanwu_GemData)
        end
    end
end

function Mission_Necessary:OnSubmit_Necessary(selfId, targetId, isHelpFinish)
    local Level = self:GetLevel(selfId)
    local iDayCount = self:GetMissionData(selfId, ScriptGlobal.MD_SHIMEN_DAYCOUNT)
    local iTime = self:GetMissionData(selfId, ScriptGlobal.MD_SHIMEN_DAYTIME)
    local iDayTime = math.floor(iTime / 100)
    local iQuarterTime = iTime % 100
    local iDayHuan = iDayCount
    local CurTime = self:GetQuarterTime()
    local CurDaytime = math.floor(CurTime / 100)
    local CurQuarterTime = CurTime % 100
    if CurDaytime == iDayTime then
        iDayHuan = iDayHuan + 1
    else
        iDayTime = CurDaytime
        iQuarterTime = 99
        iDayHuan = 1
    end
    if iDayHuan == 20 or iDayHuan == 40 or iDayHuan == 60 then
        local curDayTime = self:GetDayTime()
        if curDayTime >= self.g_StartDayTime and curDayTime <= self.g_EndDayTime then
            self:BeginAddItem()
            self:AddItem(30505166, 20)
            local canAdd = self:EndAddItem(selfId)
            if not canAdd then
                self:BeginEvent(self.script_id)
                self:AddText("Túi đồ của ngài không đủ chỗ trống, xin hãy chừa đủ chỗ trống túi đồ khi giao nhiệm vụ lần sau.")
                self:EndEvent()
                self:DispatchMissionTips(selfId)
            else
                self:AddItemListToHuman(selfId)
                local transfer = self:GetItemTransfer(selfId, 0)
                local str1 = string.format("#{_INFOUSR%s}", self:GetName(selfId))
                local str2 = string.format("#W#{_INFOMSG%s}", transfer)
                local strMsg = str1 .. self.g_strDieNotice0 .. str2 .. self.g_strDieNotice1
                strMsg = gbk.fromutf8(strMsg)
                self:BroadMsgByChatPipe(selfId, strMsg, 4)
            end
        end
        if 0 > 1 then
            local randomIndex = math.random(self:getn(self.g_LingShouDanId))
            self:BeginAddItem()
            self:AddItem(self.g_LingShouDanId[randomIndex], 1)
            local canAdd = self:EndAddItem(selfId)
            if not canAdd then
                self:BeginEvent(self.script_id)
                self:AddText("#{JNHC_081128_01}" .. self:GetItemName(self.g_LingShouDanId[randomIndex]) .. "#{HSLJJF_2}")
                self:EndEvent()
                self:DispatchMissionTips(selfId)
            else
                self:AddItemListToHuman(selfId)
                local strMsg = string.format("Ngươi nhận được #H#{_ITEM%d}#W.", self.g_LingShouDanId[randomIndex])
                self:Msg2Player(selfId, strMsg, define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
                local myStrMsg = string.format("#{BSJH_81106_10}#H#{_ITEM%d}#W。", self.g_LingShouDanId[randomIndex])
                self:BeginEvent(self.script_id)
                self:AddText(myStrMsg)
                self:EndEvent()
                self:DispatchMissionTips(selfId)
                if math.random(100) <= 5 then
                    self:BeginAddItem()
                    self:AddItem(self.g_LingShouDanId[randomIndex], 1)
                    canAdd = self:EndAddItem(selfId)
                    if not canAdd then
                        self:BeginEvent(self.script_id)
                        self:AddText("#{JNHC_081128_02}" ..
                            self:GetItemName(self.g_LingShouDanId[randomIndex]) .. "#{HSLJJF_2}")
                        self:EndEvent()
                        self:DispatchMissionTips(selfId)
                    else
                        self:AddItemListToHuman(selfId)
                        local transfer = self:GetItemTransfer(selfId, 0)
                        local str = string.format("#{_INFOUSR%s}#{JNHC_081128_03}#{_INFOMSG%s}#{JNHC_081128_04}", gbk.fromutf8(self:GetName(selfId)), transfer)
                        self:BroadMsgByChatPipe(selfId, str, 4)
                        strMsg = string.format("Ngươi nhận được #H#{_ITEM%d}#W.", self.g_LingShouDanId[randomIndex])
                        self:Msg2Player(selfId, strMsg, define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
                    end
                end
            end
        end
    end
    if iDayHuan == 10 or iDayHuan == 30 or iDayHuan == 50 then
        if math.random(100) <= 30 then
            local randomIndex = math.random(2)
            self:BeginAddItem()
            self:AddItem(self.g_ItemId[randomIndex], 1)
            local canAdd = self:EndAddItem(selfId)
            if not canAdd then
                self:BeginEvent(self.script_id)
                self:AddText("Túi đồ của ngài không đủ chỗ trống, xin hãy chừa đủ chỗ trống túi đồ khi giao nhiệm vụ lần sau.")
                self:EndEvent()
                self:DispatchMissionTips(selfId)
            else
                self:AddItemListToHuman(selfId)
                local strMsg = string.format("Ngươi nhận được #H#{_ITEM%d}#W.", self.g_ItemId[randomIndex])
                self:Msg2Player(selfId, strMsg, define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
            end
        end
    end
    self:ACT_Christmas(selfId, iDayHuan)
    local baseMenpaiPoint = 0
    if iDayHuan < 10 then
        baseMenpaiPoint = 1
    elseif iDayHuan < 15 then
        baseMenpaiPoint = 2
    elseif iDayHuan < 19 then
        baseMenpaiPoint = 3
    elseif iDayHuan == 19 then
        baseMenpaiPoint = 4
    elseif iDayHuan == 20 then
        baseMenpaiPoint = 5
    end
    local menpaiPoint = math.floor((self:GetLevel(selfId) - 10) * 0.05) + baseMenpaiPoint
    self:SetHumanMenpaiPoint(selfId, self:GetHumanMenpaiPoint(selfId) + menpaiPoint)
    self:Msg2Player(selfId, "Ngươi nhận được #Y" .. menpaiPoint .. "#W điểm Môn phái cống hiến độ.",
        define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
    local Reward_Append = 1
    local playerLevel = self:GetLevel(selfId)
    if playerLevel < 20 then
        if iDayHuan <= 10 then
            Reward_Append = 2
        end
    elseif playerLevel >= 20 and playerLevel < 30 then
        if iDayHuan <= 15 then
            Reward_Append = 2
        end
    elseif playerLevel >= 30 and playerLevel < 100 then
        if iDayHuan <= 20 then
            Reward_Append = 2
        end
    elseif playerLevel >= 100 and playerLevel < 120 then
        if iDayHuan <= 20 then
            Reward_Append = 2
        end
    end
    if playerLevel >= 40 and iDayHuan == 20 then
        local ret = math.random(100)
        if ret <= 10 then
            self:BeginAddItem()
            self:AddItem(30900015, 1)
            local canAdd = self:EndAddItem(selfId)
            if canAdd then
                self:AddItemListToHuman(selfId)
                local szItemTransfer = self:GetItemTransfer(selfId, 0)
                local strformat =
                "#W#{_INFOUSR%s}#I hôm nay vì sư môn làm nhiệm vụ dũng cảm tiến lên, quên mình, khi hoàn thành lần thứ 20, cuối cùng vì quá mệt mỏi mà vấp ngã bên đường, lúc bò dậy, trên mặt lại dính một tấm nhăn nhúm của #W#{_INFOMSG%s}."
                strformat = gbk.fromutf8(strformat)
                local strText = string.format(strformat, gbk.fromutf8(self:GetName(selfId)), szItemTransfer)
                self:BroadMsgByChatPipe(selfId, strText, 4)
            end
        end
    end
    local MijiActive = 1
    local AwardID = 30505078
    local AwardCyc = 20
    local DayTime = self:GetDayTime()
    if DayTime < 7104 then
        MijiActive = 0
    end
    if DayTime >= 7115 then
        MijiActive = 0
    end
    if playerLevel > 19 then
        if iDayHuan > 0 then
            local ModHuan = iDayHuan % AwardCyc
            if 0 == ModHuan then
                if 1 == MijiActive then
                    self:BeginAddItem()
                    self:AddItem(AwardID, 1)
                    local AddRet = self:EndAddItem(selfId)
                    if AddRet then
                        self:AddItemListToHuman(selfId)
                    end
                end
            end
        end
    end
    local skyrockets = { 30505081, 30505082, 30505083, 30505084 }
    local count = 2
    local cycle = 20
    if DayTime >= 7128 and DayTime <= 7150 then
        if (iDayHuan / cycle) == math.floor(iDayHuan / cycle) then
            local skyrocket = skyrockets[math.random(self:getn(skyrockets))]
            self:BeginAddItem()
            self:AddItem(skyrocket, 2)
            local AddRet = self:EndAddItem(selfId)
            if AddRet then
                self:AddItemListToHuman(selfId)
            else
                local strText = "Vì không gian túi của ngài không đủ, ngài đã mất một lần nhận được #{_ITEM" ..
                    skyrocket .. "} cơ hội."
                self:BeginEvent(self.script_id)
                self:AddText(strText)
                self:EndEvent()
                self:DispatchMissionTips(selfId)
                self:Msg2Player(selfId, strText, define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
            end
        end
    end
    self:ACT_Duanwu(selfId, iDayHuan)
    iDayCount = iDayHuan
    local newTime = iDayTime * 100 + iQuarterTime
    self:SetMissionData(selfId, ScriptGlobal.MD_SHIMEN_DAYTIME, newTime)
    self:SetMissionData(selfId, ScriptGlobal.MD_SHIMEN_DAYCOUNT, iDayCount)
    self.g_MissionRound = self:GetMissionData(selfId, ScriptGlobal.MD_SHIMEN_HUAN)
    local levelfactor = 0.035
    local refix = 1 + levelfactor * playerLevel / 10
    local strHuashan = ""
    local strHuashan2 = ""
    if Reward_Append == 2 then
        if self:GetHuashanV(selfId) == self:GetMenPai(selfId) then
            local addMoney = math.floor(self:GetMoneyMultipleByRound(self.g_MissionRound) *
                math.floor(self:GetMoneyBonusByLevel(Level) / 2))
            local addExp = math.floor(self:GetExpMultipleByRound(self.g_MissionRound) *
                math.floor(self:GetExpBonusByLevel(Level)) * refix)
            self.g_Money = addMoney * 3
            self.g_Exp = addExp * 3
            strHuashan = "#PBởi Môn phái của ta đoạt ngôi vị quán quân Hoa Sơn Luận Kiếm kỳ này, nên sẽ nhận được thêm #Ykinh nghiệm#W thưởng của sư môn." ..
                addExp .. "#P, tiền bạc#{_MONEY" .. addMoney .. "}#P。"
            strHuashan2 = "#Pnhận được thêm #Ykinh nghiệm#Wphần thưởng sư môn (Quán quân Hoa Sơn Luận Kiếm)" ..
                addExp .. ", tiền bạc#Y#{_MONEY" .. addMoney .. "}#P。"
        else
            self.g_Money = math.floor((self:GetMoneyMultipleByRound(self.g_MissionRound) * self:GetMoneyBonusByLevel(Level)))
            self.g_Exp = math.floor((self:GetExpMultipleByRound(self.g_MissionRound) * self:GetExpBonusByLevel(Level) * 2) *
                refix)
        end
    else
        self.g_Money = self:GetMoneyMultipleByRound(self.g_MissionRound) * math.floor(self:GetMoneyBonusByLevel(Level) /
            2)
        self.g_Exp = self:GetExpMultipleByRound(self.g_MissionRound) * math.floor(self:GetExpBonusByLevel(Level) / 2)
    end
    self.g_Exp = math.floor(self.g_Exp)
    self.g_Money = math.floor(self.g_Money)
    self:AddExp(selfId, self.g_Exp)
    self:AddMoney(selfId, self.g_Money)
    self:BeginEvent(self.script_id)
    if isHelpFinish and isHelpFinish == 1 then
        self:AddText(self.g_strHelpFinishedText)
    end
    self:AddText("  Làm tốt lắm, đây là" .. self.g_Exp .. "chút giá trị kinh nghiệm và #{_MONEY" .. self.g_Money .. ", xem như là phần thưởng cho ngươi.")
    self:AddText(strHuashan)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
    self:Msg2Player(selfId, strHuashan2, define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
    if Reward_Append == 2 and (iDayHuan % 5) == 0 and math.random(1000) <= 5 then
        local ItemSn, ItemName, _, bBroadCast = self:GetOneMissionBonusItem(27)
        local szItemTransfer = ""
        self:BeginAddItem()
        self:AddItem(ItemSn, 1)
        local canAdd = self:EndAddItem(selfId)
        if canAdd then
            self:AddItemListToHuman(selfId)
            szItemTransfer = self:GetItemTransfer(selfId, 0)
            local strText = string.format("Ngươi nhận được %s", ItemName)
            self:BeginEvent(self.script_id)
            self:AddText(strText)
            self:EndEvent()
            self:DispatchMissionTips(selfId)
            local strformatList = { "#W#{_INFOUSR%s}#I khi làm nhiệm vụ sư môn, bởi vì lao khổ công cao, được sư phụ phần thưởng một cái #W#{_INFOMSG%s}.",
                "#W#{_INFOUSR%s}#I vừa hoàn thành nhiệm vụ ra khỏi cửa, bị vấp phải bậc thềm, phát hiện một cái #W#{_INFOMSG%s}.",
                "#I Bởi vì #W#{_INFOUSR%s}#I trong lúc hoàn thành nhiệm vụ sư môn, sư phụ đang nổi giận, bị sư phụ tiện tay nhặt lấy một cái #W#{_INFOMSG%s}#I ném trúng.",
                "#W#{_INFOUSR%s}#I trên đường hoàn thành nhiệm vụ sư môn, đột nhiên bị một cái #W#{_INFOMSG%s}#I từ trên trời rơi xuống ném trúng." }
            local index = math.random(4)
            local PlayName = self:GetName(selfId)
            strText = string.format(strformatList[index], PlayName, szItemTransfer)
        end
    end
    self:BeginEvent(self.script_id)
    self:AddText("Hôm nay bạn đã hoàn thành#R" .. iDayHuan .. "#GKhuyên nhiệm vụ Môn phái.")
    self:EndEvent()
    self:DispatchMissionTips(selfId)
    self:LuaFnAddMissionHuoYueZhi(selfId, 6)
    self:LuaFnAuditShiMenRenWu(selfId, self.g_MissionRound, self:GetLevel(selfId))
    self:LuaFnAuditShiMenRenWu_Day(selfId, iDayHuan, self:GetLevel(selfId))
    return Reward_Append,self.g_MissionRound
end

function Mission_Necessary:CheckAccept_Necessary(selfId)
    local iDayCount = self:GetMissionData(selfId, ScriptGlobal.MD_SHIMEN_DAYCOUNT)
    local iTime = self:GetMissionData(selfId, ScriptGlobal.MD_SHIMEN_DAYTIME)
    local iDayTime = math.floor(iTime / 100)
    local iQuarterTime = (iTime % 100)
    local iDayHuan = iDayCount
    local CurTime = self:GetQuarterTime()
    local CurDaytime = math.floor(CurTime / 100)
    local CurQuarterTime = (CurTime % 100)
    if iDayTime == CurDaytime then
        if iDayHuan >= 60 then
            return 2000
        end
        if CurQuarterTime == iQuarterTime then
            return 1000
        end
    else
        iDayHuan = 1
        iDayCount = iDayHuan
        local newTime = iDayTime * 100 + iQuarterTime
        self:SetMissionData(selfId, ScriptGlobal.MD_SHIMEN_DAYTIME, newTime)
        self:SetMissionData(selfId, ScriptGlobal.MD_SHIMEN_DAYCOUNT, iDayCount)
    end
    local playerLevel = self:GetLevel(selfId)
    if playerLevel < 20 then
        if iDayHuan < 10 then
            self:SetMissionData(selfId, ScriptGlobal.MD_SHIMEN_DOUBLE_EXP, 1)
        else
            self:SetMissionData(selfId, ScriptGlobal.MD_SHIMEN_DOUBLE_EXP, 0)
        end
    elseif playerLevel >= 20 and playerLevel < 30 then
        if iDayHuan < 15 then
            self:SetMissionData(selfId, ScriptGlobal.MD_SHIMEN_DOUBLE_EXP, 1)
        else
            self:SetMissionData(selfId, ScriptGlobal.MD_SHIMEN_DOUBLE_EXP, 0)
        end
    elseif playerLevel >= 30 and playerLevel < 100 then
        if iDayHuan < 20 then
            self:SetMissionData(selfId, ScriptGlobal.MD_SHIMEN_DOUBLE_EXP, 1)
        else
            self:SetMissionData(selfId, ScriptGlobal.MD_SHIMEN_DOUBLE_EXP, 0)
        end
    elseif playerLevel >= 100 and playerLevel < 120 then
        if iDayHuan < 20 then
            self:SetMissionData(selfId, ScriptGlobal.MD_SHIMEN_DOUBLE_EXP, 1)
        else
            self:SetMissionData(selfId, ScriptGlobal.MD_SHIMEN_DOUBLE_EXP, 0)
        end
    end
    return 1
end

function Mission_Necessary:Abandon_Necessary(selfId)
    local iTime = self:GetMissionData(selfId, ScriptGlobal.MD_SHIMEN_DAYTIME)
    local iDayTime = math.floor(iTime / 100)
    local CurTime = self:GetQuarterTime()
    local CurDaytime = math.floor(CurTime / 100)
    if iDayTime ~= CurDaytime then
        self:SetMissionData(selfId, ScriptGlobal.MD_SHIMEN_DAYCOUNT, 0)
    end
    self:SetMissionData(selfId, ScriptGlobal.MD_SHIMEN_DAYTIME, CurTime)
    local menpaiPoint = self:GetHumanMenpaiPoint(selfId)
    if menpaiPoint == 1 then
        self:SetHumanMenpaiPoint(selfId, menpaiPoint - 1)
        self:Msg2Player(selfId, "Ngươi tiêu hao #Y1#W điểm cống hiến Môn phái.", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
    elseif menpaiPoint >= 2 then
        self:SetHumanMenpaiPoint(selfId, menpaiPoint - 2)
        self:Msg2Player(selfId, "Ngươi tiêu hao #Y2#W điểm cống hiến Môn phái.", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
    end
end

function Mission_Necessary:OnMissionCheck_Necessary(selfId, index1, index2, index3, Needindex)
    if Needindex == nil or Needindex == -1 then
        return 0
    end
    if index1 >= 0 and index1 < 60 then
        SerialNum = self:LuaFnGetItemTableIndexByIndex(selfId, index1)
        if SerialNum == Needindex then
            return index1
        end
    end
    if index2 >= 0 and index2 < 60 then
        SerialNum = self:LuaFnGetItemTableIndexByIndex(selfId, index2)
        if SerialNum == Needindex then
            return index2
        end
    end
    if index3 >= 0 and index3 < 60 then
        SerialNum = self:LuaFnGetItemTableIndexByIndex(selfId, index3)
        if SerialNum == Needindex then
            return index3
        end
    end
    self:BeginEvent(self.script_id)
    self:AddText("Nhiệm vụ của ngươi không thể hoàn thành, vật phẩm ngươi nộp không chính xác.")
    self:EndEvent()
    self:DispatchEventList(selfId, -1)
    return -1
end

function Mission_Necessary:OnMissionCheckName_Necessary(selfId, index1, index2, index3, Needindex)
    if Needindex == nil or Needindex == -1 then
        return 0
    end
    if index1 >= 0 and index1 < 60 then
        SerialNum = self:LuaFnGetItemTableIndexByIndex(selfId, index1)
        ItemNameId = self:GetItemNameID(SerialNum)
        if ItemNameId == Needindex then
            return index1
        end
    end
    if index2 >= 0 and index2 < 60 then
        SerialNum = self:LuaFnGetItemTableIndexByIndex(selfId, index2)
        ItemNameId = self:GetItemNameID(SerialNum)
        if ItemNameId == Needindex then
            return index2
        end
    end
    if index3 >= 0 and index3 < 60 then
        SerialNum = self:LuaFnGetItemTableIndexByIndex(selfId, index3)
        ItemNameId = self:GetItemNameID(SerialNum)
        if ItemNameId == Needindex then
            return index3
        end
    end
    self:BeginEvent(self.script_id)
    self:AddText("Nhiệm vụ của ngươi không thể hoàn thành, vật phẩm ngươi nộp không chính xác.")
    self:EndEvent()
    self:DispatchEventList(selfId, -1)
    return -1
end

function Mission_Necessary:OnMissionCheck_NecessaryEx(selfId, index1, index2, index3, Needindex)
    if Needindex == nil or Needindex <= 0 then
        return -1
    end
    local indices = { index1, index2, index3 }
    for i = 1,#(indices) do
        if indices[i] and indices[i] >= 0 and indices[i] < 80 then
            if self:LuaFnGetItemTableIndexByIndex(selfId, indices[i]) == Needindex then
                return indices[i]
            end
        end
    end
    return -1
end

function Mission_Necessary:ACT_Christmas(selfId, DayHuan)
    if DayHuan ~= 20 and DayHuan ~= 40 and DayHuan ~= 60 then
        return
    end
    if self:CallScriptFunction(050025, "CheckRightTime") == 1 then
        if self:GetLevel(selfId) < 25 then
            return
        end
        if self:LuaFnGetMaterialBagSpace(selfId) < 1 then
            return
        end
        local menpaiId = self:LuaFnGetMenPai(selfId)
        local hekaid = 0
        local strtext = ""
        if menpaiId == define.MENPAI_ATTRIBUTE.MATTRIBUTE_SHAOLIN then
            strtext = "Ngươi nhận được Thiệp Chúc Mừng Lễ Hội Thiếu Lâm."
            hekaid = self.HeKaId[1]
        elseif menpaiId == define.MENPAI_ATTRIBUTE.MATTRIBUTE_MINGJIAO then
            strtext = "Ngươi nhận được Thiệp Chúc Mừng Lễ Hội Minh Giáo."
            hekaid = self.HeKaId[2]
        elseif menpaiId == define.MENPAI_ATTRIBUTE.MATTRIBUTE_GAIBANG then
            strtext = "Ngươi nhận được Thiệp Chúc Mừng Lễ Hội Cái Bang."
            hekaid = self.HeKaId[3]
        elseif menpaiId == define.MENPAI_ATTRIBUTE.MATTRIBUTE_WUDANG then
            strtext = "Ngươi nhận được Thiệp Chúc Mừng Lễ Hội Võ Đang."
            hekaid = self.HeKaId[4]
        elseif menpaiId == define.MENPAI_ATTRIBUTE.MATTRIBUTE_EMEI then
            strtext = "Ngươi nhận được Thiệp Chúc Mừng Lễ Hội Nga Mi."
            hekaid = self.HeKaId[5]
        elseif menpaiId == define.MENPAI_ATTRIBUTE.MATTRIBUTE_XINGXIU then
            strtext = "Ngươi nhận được Thiệp Chúc Mừng Lễ Hội Tinh Túc."
            hekaid = self.HeKaId[6]
        elseif menpaiId == define.MENPAI_ATTRIBUTE.MATTRIBUTE_DALI then
            strtext = "Ngươi nhận được Thiệp Chúc Mừng Lễ Hội Thiên Long."
            hekaid = self.HeKaId[7]
        elseif menpaiId == define.MENPAI_ATTRIBUTE.MATTRIBUTE_TIANSHAN then
            strtext = "Ngươi nhận được Thiệp Chúc Mừng Lễ Hội Thiên Sơn."
            hekaid = self.HeKaId[8]
        elseif menpaiId == define.MENPAI_ATTRIBUTE.MATTRIBUTE_XIAOYAO then
            strtext = "Ngươi nhận được Thiệp Chúc Mừng Lễ Hội Tiêu Dao."
            hekaid = self.HeKaId[9]
        end
        local BagIndex = self:TryRecieveItem(selfId, hekaid, ScriptGlobal.QUALITY_MUST_BE_CHANGE)
        if BagIndex ~= -1 then
            self:BeginEvent(self.script_id)
            self:AddText(strtext)
            self:EndEvent()
            self:DispatchMissionTips(selfId)
        end
    end
end

return Mission_Necessary
