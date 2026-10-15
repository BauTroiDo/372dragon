local gbk = require "wire_charset"
local class = require "class"
local define = require "define"
local script_base = require "script_base"
local mod_event = class("mod_event", script_base)
local ScriptGlobal = require("scripts.ScriptGlobal")
mod_event.script_id = 006672
function mod_event:DoEnumerate(caller, selfId, targetId, missionIndex)
    local missionId = self:TGetMissionIdByIndex(missionIndex)
    if self:IsMissionHaveDone(selfId, missionId) and not self:TIsMissionRoundable(missionIndex) then
        return
    end
    local missionName = self:TGetMissionName(missionIndex)
    local PrevMis = { -1, -1, -1 }
    local nLevel = 0
    nLevel = self:TGetCheckInfo(missionIndex)
    if nLevel > self:GetLevel(selfId) then
        return
    end
    if PrevMis[1] == 800 then
        if PrevMis[2] ~= self:LuaFnGetMenPai(selfId) then
            return
        end
    elseif PrevMis[1] == 810 then
        local bOk = 0
        for i = 801, 809 do
            if self:IsMissionHaveDone(selfId, i) then
                bOk = 1
            end
        end
        if bOk == 0 then
            return
        end
    else
        for i = 1, #(PrevMis) do
            if PrevMis[i] > 0 then
                if not self:IsMissionHaveDone(selfId, PrevMis[i]) then
                    return
                end
            end
        end
    end
    if self:IsHaveMission(selfId, missionId) then
        local completeNpcScene, completeNpcName = self:TGetCompleteNpcInfo(missionIndex)
        if self:GetName(targetId) == completeNpcName then
            if self:TIsMissionRoundable(missionIndex) then
                caller:AddNumTextWithTarget(missionIndex, missionName, 4, -1)
            else
                caller:AddNumTextWithTarget(missionIndex, missionName, 2, -1)
            end
            --caller:TDispatchEventList(selfId, targetId)
        end
    else
        local acceptNpcScene, acceptNpcName = self:TGetAcceptNpcInfo(missionIndex)
        if self:GetName(targetId) == acceptNpcName then
            if self:TIsMissionRoundable(missionIndex) then
                caller:AddNumTextWithTarget(missionIndex, missionName, 3, -1)
            else
                caller:AddNumTextWithTarget(missionIndex, missionName, 1, -1)
            end
            --caller:TDispatchEventList(selfId, targetId)
        end
    end
end

function mod_event:CheckAccept(selfId, missionIndex)
    local nLevel = self:LuaFnGetLevel(selfId)
    local AcceptMissionSceneId = { 9, 11, 10, 12, 15, 16, 13, 17, 14, 184 }
    local PrevMis = { -1, -1, -1 }
    local limitLevel = 0
    limitLevel = self:TGetCheckInfo(missionIndex)
    if nLevel < limitLevel then
        self:NotifyFailBox(selfId, -1, "    Giang hồ lịch duyệt của ngươi còn thấp, e rằng không thể đảm đương nổi, đợi" ..
        limitLevel .. "Đạt cấp rồi hãy đến tìm ta.")
        return 0
    end
    if missionIndex >= 1018729 and missionIndex <= 1018818 then
        local nMenpai = self:LuaFnGetMenPai(selfId)
        if nMenpai < 0 or nMenpai == 9 then
            self:NotifyFailBox(selfId, -1, "#{YD_20080421_222}")
            return 0
        elseif AcceptMissionSceneId[nMenpai + 1] ~= self:get_scene_id() then
            self:NotifyFailBox(selfId, -1, "#{YD_20080421_223}")
            return 0
        end
    end
    if PrevMis[1] == 800 then
        if PrevMis[2] == self:LuaFnGetMenPai(selfId) then
            return 1
        end
        return 0
    end
    if PrevMis[1] == 810 then
        local bOk = 0
        for i = 801, 809 do
            if self:IsMissionHaveDone(selfId, i) then
                bOk = 1
            end
        end
        if bOk == 1 then
            return 1
        end
        return 0
    end
    for i = 1, #(PrevMis) do
        if PrevMis[i] > 0 then
            if not self:IsMissionHaveDone(selfId, PrevMis[i]) then
                return 0
            end
        end
    end
    local mdLocation, value, prompt = self:TGetLimitedTimeInfo(missionIndex)
    if mdLocation and value then
        local ApprovedTime = self:GetMissionData(selfId, mdLocation)
        if ApprovedTime > self:LuaFnGetCurrentTime() then
            self:NotifyFailBox(selfId, -1, prompt)
            return 0
        end
    end
    return 1
end

function mod_event:GetRandomDuologue(missionIndex, duologueContent)
    local duologueList = {}
    string.sub(duologueContent,"(%d+)",
    function(n) 
        table.insrt(duologueList, tonumber(n))
    end 
    )
    if #(duologueList) < 1 then
        return ""
    end
    duologueContent = self:TGetDuologue(duologueList[math.random(#(duologueList))])
    if type(duologueContent) ~= "string" then
        return ""
    end
    return duologueContent
end

function mod_event:FormatDuologue(selfId, duologueContent, npcId, itemIndex, itemList)
    if not duologueContent or type(duologueContent) ~= "string" or npcId == 0 then
        return ""
    end
    if string.find(duologueContent, "%R", 1, 1) then
        local PlayerGender = self:GetSex(selfId)
        local rank
        if PlayerGender == 0 then
            rank = "Hiệp Nữ"
        else
            rank = "Thiếu hiệp"
        end
        duologueContent = string.sub(duologueContent, "%%R", rank)
    end
    if npcId and npcId ~= -1 then
        local nNpcId, strNpcName, strNpcScene, nPosX, nPosZ, strNPCDesc, nScene, nGender, nLevel, nType = self
        :GetNpcInfoByNpcId(npcId)
        local strGender                                                                        = {}
        strGender[0]                                                                           = "nàng"
        strGender[1]                                                                           = "hắn"
        if string.find(duologueContent, "%n", 1, 1) then
            local newLocation
            if nPosX > 0 and nPosZ > 0 then
                newLocation = strNpcScene .. strNpcName .. "（" .. nPosX .. "，" .. nPosZ .. "）"
            else
                newLocation = strNpcScene .. strNpcName
            end
            duologueContent = string.sub(duologueContent, "%%n", newLocation)
        end
        if string.find(duologueContent, "%g", 1, 1) then
            duologueContent = string.sub(duologueContent, "%%g", strGender[nGender])
        end
    end
    if itemIndex and itemIndex ~= -1 and itemList == "" and itemIndex ~= 0 then
        local nitemId, strItemName, strItemDesc = self:GetItemInfoByItemId(itemIndex)
        if string.find(duologueContent, "%i", 1, 1) then
            duologueContent = string.sub(duologueContent, "%%i", strItemName)
        end
    end
    if itemList ~= "" then
        if string.find(duologueContent, "%i", 1, 1) then
            duologueContent = string.sub(duologueContent, "%%i", itemList)
        end
    end
    return duologueContent
end

function mod_event:DisplayBonus(caller, missionIndex, selfId)
    local itemCt
    local a = { { ["id"] = -1, ["ct"] = 0 }
    , { ["id"] = -1, ["ct"] = 0 }
    , { ["id"] = -1, ["ct"] = 0 }
    , { ["id"] = -1, ["ct"] = 0 }
    , { ["id"] = -1, ["ct"] = 0 }
    }
    itemCt, a[1].id, a[1].ct,
    a[2].id, a[2].ct,
    a[3].id, a[3].ct,
    a[4].id, a[4].ct,
    a[5].id, a[5].ct
    = self:TGetAwardItem(missionIndex)
    for i = 1, itemCt do
        if a[i]["id"] > 0 then
            caller:AddItemBonus(a[i]["id"], a[i]["ct"])
        end
    end
    itemCt, a[1].id, a[1].ct,
    a[2].id, a[2].ct,
    a[3].id, a[3].ct,
    a[4].id, a[4].ct,
    a[5].id, a[5].ct = self:TGetRadioItem(missionIndex)
    for i = 1, itemCt do
        if a[i]["id"] > 0 then
            caller:AddRadioItemBonus(a[i]["id"], a[i]["ct"])
        end
    end
    itemCt, a[1].id, a[1].ct,
    a[2].id, a[2].ct,
    a[3].id, a[3].ct,
    a[4].id, a[4].ct,
    a[5].id, a[5].ct = self:TGetHideItem(missionIndex)
    for i = 1, itemCt do
        if a[i]["id"] > 0 then
            caller:AddRandItemBonus(a[i]["id"], a[i]["ct"])
        end
    end
    local awardMoney = self:TGetAwardMoney(missionIndex)
    if (missionIndex >= 1010243 and missionIndex <= 1010250) or (missionIndex >= 1010402 and missionIndex <= 1010409) or (missionIndex >= 1018000 and missionIndex <= 1018033) or (missionIndex >= 1018050 and missionIndex <= 1018084) or (missionIndex >= 1018100 and missionIndex <= 1018155) or (missionIndex >= 1018200 and missionIndex <= 1018235) or (missionIndex >= 1018300 and missionIndex <= 1018311) or (missionIndex >= 1018350 and missionIndex <= 1018352) or (missionIndex >= 1018360 and missionIndex <= 1018367) or (missionIndex >= 1018400 and missionIndex <= 1018455) or (missionIndex >= 1018500 and missionIndex <= 1018504) or (missionIndex >= 1018530 and missionIndex <= 1018541) or (missionIndex >= 1018560 and missionIndex <= 1018566) or (missionIndex >= 1038000 and missionIndex <= 1038040) or (missionIndex >= 1038110 and missionIndex <= 1038114) or (missionIndex >= 1039000 and missionIndex <= 1039011) or (missionIndex >= 1039020 and missionIndex <= 1039024) or (missionIndex >= 1039100 and missionIndex <= 1039104) or (missionIndex >= 1038100 and missionIndex <= 1038104) or (missionIndex >= 1039110 and missionIndex <= 1039126) or (missionIndex >= 1039200 and missionIndex <= 1039211) or (missionIndex >= 1039250 and missionIndex <= 1039259) or (missionIndex >= 1039300 and missionIndex <= 1039312) or (missionIndex >= 1039350 and missionIndex <= 1039357) or (missionIndex >= 1039400 and missionIndex <= 1039412) or (missionIndex >= 1039450 and missionIndex <= 1039462) or (missionIndex >= 1039500 and missionIndex <= 1039511) or (missionIndex >= 1039550 and missionIndex <= 1039554) or (missionIndex >= 1039600 and missionIndex <= 1039612) or (missionIndex >= 1009000 and missionIndex <= 1009027) or (missionIndex >= 1009100 and missionIndex <= 1009103) then
        awardMoney = self:GetLevel(selfId) * 18 - 101
    end
    caller:AddMoneyBonus(awardMoney)
end

function mod_event:RewardRelationShip(selfId, missionIndex, targetId)
    local mdLocation, value, prompt = self:TGetRelationShipAwardInfo(missionIndex)
    if not mdLocation or not value then
        return
    end
    if mdLocation == define.INVAILD_ID then
        return
    end
    local szNpcName = ""
    local nLimitiIndex = -1
    if mdLocation == ScriptGlobal.MD_RELATION_MUWANQING then
        szNpcName = "木婉清"
        nLimitiIndex = ScriptGlobal.MD_JQXH_MUWANQING_LIMITI
    elseif mdLocation == ScriptGlobal.MD_RELATION_ZHONGLING then
        szNpcName = "钟灵"
        nLimitiIndex = ScriptGlobal.MD_JQXH_ZHONGLING_LIMITI
    elseif mdLocation == ScriptGlobal.MD_RELATION_DUANYANQING then
        szNpcName = "段延庆"
        nLimitiIndex = ScriptGlobal.MD_JQXH_DUANYANQING_LIMITI
    elseif mdLocation == ScriptGlobal.MD_RELATION_DUANYU then
        szNpcName = "段誉"
        nLimitiIndex = ScriptGlobal.MD_JQXH_DUANYU_LIMITI
    elseif mdLocation == ScriptGlobal.MD_RELATION_AZHU then
        szNpcName = "阿朱"
        nLimitiIndex = ScriptGlobal.MD_JQXH_AZHU_LIMITI
    elseif mdLocation == ScriptGlobal.MD_RELATION_ABI then
        szNpcName = "阿碧"
        nLimitiIndex = ScriptGlobal.MD_JQXH_ABI_LIMITI
    elseif mdLocation == ScriptGlobal.MD_RELATION_WANGYUYAN then
        szNpcName = "王语嫣"
        nLimitiIndex = ScriptGlobal.MD_JQXH_WANGYUYAN_LIMITI
    elseif mdLocation == ScriptGlobal.MD_RELATION_XIAOFENG then
        szNpcName = "萧峰"
        nLimitiIndex = ScriptGlobal.MD_JQXH_XIAOFENG_LIMITI
    elseif mdLocation == ScriptGlobal.MD_RELATION_AZI then
        szNpcName = "阿紫"
        nLimitiIndex = ScriptGlobal.MD_JQXH_AZI_LIMITI
    elseif mdLocation == ScriptGlobal.MD_RELATION_MURONGFU then
        szNpcName = "慕容复"
        nLimitiIndex = ScriptGlobal.MD_JQXH_MURONGFU_LIMITI
    elseif mdLocation == ScriptGlobal.MD_RELATION_XUZHU then
        szNpcName = "虚竹"
        nLimitiIndex = ScriptGlobal.MD_JQXH_XUZHU_LIMITI
    elseif mdLocation == ScriptGlobal.MD_RELATION_JIUMOZHI then
        szNpcName = "鸠摩智"
        nLimitiIndex = ScriptGlobal.MD_JQXH_JIUMOZHI_LIMITI
    elseif mdLocation == ScriptGlobal.MD_RELATION_YINCHUAN then
        szNpcName = "银川公主"
        nLimitiIndex = ScriptGlobal.MD_JQXH_YINCHUAN_LIMITI
    end
    if nLimitiIndex >= ScriptGlobal.MD_JQXH_MUWANQING_LIMITI and nLimitiIndex <= ScriptGlobal.MD_JQXH_YINCHUAN_LIMITI then
        local nDayCount = self:GetMissionData(selfId, nLimitiIndex)
        local nCount = math.floor(nDayCount / 100000)
        local nTime = (nDayCount % 100000)
        local nDayTime = nTime
        local CurTime = self:GetDayTime()
        local CurDaytime = CurTime
        if nDayTime == CurDaytime then
            nCount = nCount + 1
        else
            nCount = 1
        end
        local nNewDayCount = nCount * 100000 + CurTime
        self:SetMissionData(selfId, nLimitiIndex, nNewDayCount)
    end
    local oldValue = self:GetMissionData(selfId, mdLocation)
    value = value + oldValue
    if value > 9999 then
        value = 9999
    else
        self:BeginEvent(self.script_id)
        local strText = prompt
        self:AddText(strText)
        self:EndEvent()
        self:DispatchMissionTips(selfId)
        if value == 1000 then
            self:BeginEvent(self.script_id)
            local strText = "Ngươi cùng #G" .. szNpcName .. "#Wquan hệ của ngươi đã Phát triển đến #YQuân Tử Chi Giao#W."
            self:AddText(strText)
            self:EndEvent()
            self:DispatchMissionTips(selfId)
            self:LuaFnSendSystemMail(self:GetName(selfId), strText)
        elseif value == 2000 then
            self:BeginEvent(self.script_id)
            local strText = "Ngươi cùng #G" .. szNpcName .. "#Wquan hệ của ngươi đã Phát triển đến #YMạc Nghịch Chi Giao#W."
            self:AddText(strText)
            self:EndEvent()
            self:DispatchMissionTips(selfId)
            self:LuaFnSendSystemMail(self:GetName(selfId), strText)
        elseif value == 4000 then
            self:BeginEvent(self.script_id)
            local strText = "Ngươi cùng #G" .. szNpcName .. "#Wquan hệ của ngươi đã Phát triển đến #YBát Bái Chi Giao#W"
            self:AddText(strText)
            self:EndEvent()
            self:DispatchMissionTips(selfId)
            self:LuaFnSendSystemMail(self:GetName(selfId), strText)
        elseif value == 6500 then
            self:BeginEvent(self.script_id)
            local strText = "Ngươi cùng #G" .. szNpcName .. "#Wquan hệ của ngươi đã Phát triển đến #YWẫn Cảnh Chi Giao#W."
            self:AddText(strText)
            self:EndEvent()
            self:DispatchMissionTips(selfId)
            self:LuaFnSendSystemMail(self:GetName(selfId), strText)
            local szPlayer = self:GetName(selfId)
            szPlayer = gbk.fromutf8(szPlayer)
            if self:GetName(targetId) == "木婉清" then
                local szBroad = "@*;SrvMsg;" .. "juqing_xunhuan_system_muwanqing" .. ";" .. szPlayer .. ";" .. szPlayer
                self:BroadMsgByChatPipe(selfId, szBroad, 4)
            elseif self:GetName(targetId) == "耶律大石" then
                local szBroad = "@*;SrvMsg;" .. "juqing_xunhuan_system_xiaofeng" .. ";" .. szPlayer .. ";" .. szPlayer
                self:BroadMsgByChatPipe(selfId, szBroad, 4)
            end
        end
    end
    self:SetMissionData(selfId, mdLocation, value)
    if mdLocation == ScriptGlobal.MD_RELATION_MUWANQING then
        self:AuditRelationPoint(selfId, value, "MD_RELATION_MUWANQING")
    end
    local PlayerMaxLevel = self:GetHumanMaxLevelLimit()
    local nLevel = self:GetLevel(selfId)
    if nLevel >= 20 and nLevel <= PlayerMaxLevel then
        local nExp = nLevel * 80 - 326
        local nMoney = nLevel * 18 - 101
        local missionId = self:TGetMissionIdByIndex(missionIndex)
        self:AddMoney(selfId, nMoney, missionId, missionIndex)
        self:AddExp(selfId, nExp)
    end
    local missionName = self:TGetMissionName(missionIndex)
    self:LuaFnAuditQuest(selfId, missionName)
    if value > oldValue then
        self:Msg2Player(selfId, prompt, define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
    end
end

function mod_event:PunishRelationShip(selfId, missionIndex)
    local mdLocation, value, prompt = self:TGetRelationShipPunishInfo(missionIndex)
    if not mdLocation or not value then
        return
    end
    if mdLocation == define.INVAILD_ID then
        return
    end
    local oldValue = self:GetMissionData(selfId, mdLocation)
    value = oldValue - value
    if value < 0 then
        value = 0
    end
    self:SetMissionData(selfId, mdLocation, value)
    if mdLocation == ScriptGlobal.MD_RELATION_MUWANQING then
        self:AuditRelationPoint(selfId, value, "MD_RELATION_MUWANQING")
    end
    if value < oldValue then
        self:Msg2Player(selfId, prompt, define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
    end
end

function mod_event:AcceptTimeLimit(selfId, missionIndex)
    local mdLocation, value, prompt = self:TGetLimitedTimeInfo(missionIndex)
    if not mdLocation or not value then
        return
    end
    self:SetMissionData(selfId, mdLocation, self:LuaFnGetCurrentTime() + value)
end

function mod_event:NotifyFailBox(selfId, targetId, msg)
    self:BeginEvent(self.script_id)
    self:AddText(msg)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return mod_event
