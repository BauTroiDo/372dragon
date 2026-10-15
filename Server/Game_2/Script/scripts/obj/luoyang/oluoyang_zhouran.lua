local gbk = require "wire_charset"
local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local oluoyang_zhouran = class("oluoyang_zhouran", script_base)
oluoyang_zhouran.script_id = 000154
oluoyang_zhouran.g_eventList = {402047}

oluoyang_zhouran.g_ExchGoodsName = {
    "#{BHXZ_081211_4}", "#{BHXZ_081211_5}", "#{BHXZ_081211_6}",
    "#{BHXZ_081211_7}"
}

oluoyang_zhouran.g_ConsumeHonour = {300, 800, 1500, 3000}

oluoyang_zhouran.g_ExchGoodsIndex = {30008018, 38002397, 20310119, 30900057}

oluoyang_zhouran.g_MenpaiName = {
    "#{BHXZ_081211_20}", "#{BHXZ_081211_21}", "#{BHXZ_081211_22}",
    "#{BHXZ_081211_23}", "#{BHXZ_081211_24}", "#{BHXZ_081211_25}",
    "#{BHXZ_081211_26}", "#{BHXZ_081211_27}", "#{BHXZ_081211_28}"
}

oluoyang_zhouran.g_MenpaiWantHonour = 5000
oluoyang_zhouran.g_MenpaiGoodsIndex = {
    10124142, 10124143, 10124144, 10124145, 10124146, 10124147, 10124148,
    10124149, 10124150
}

oluoyang_zhouran.g_WantHonour = 100
oluoyang_zhouran.g_GiveBanggong = 50
oluoyang_zhouran.g_BuyLuoyangMoney = 10000000
oluoyang_zhouran.g_LuoyangOwnerIndex = 53
oluoyang_zhouran.g_BaseGuildIndex = 10000
oluoyang_zhouran.g_PrizeTitle = {
    ["AwardPos"] = 18,
    ["SetPos"] = 42,
    ["Index"] = 255
}

oluoyang_zhouran.g_LuoyangCityMoneyJZ = 200000
function oluoyang_zhouran:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{BHXZ_081103_114}")
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:AddNumText("#{BHXZ_081211_1}", 6, 10)
    self:AddNumText("#{BHXZ_081211_2}", 11, 11)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oluoyang_zhouran:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function oluoyang_zhouran:OnEventRequest(selfId, targetId, arg, index)
    local key = index
    if key == 10 then
        self:BeginEvent(self.script_id)
        self:AddText("#{BHXZ_081211_3}")
        self:AddNumText("#{BHXZ_081211_4}", 6, 100)
        self:AddNumText("#{BHXZ_081211_5}", 6, 200)
        self:AddNumText("#{BHXZ_081211_6}", 6, 300)
        self:AddNumText("#{BHXZ_081211_7}", 6, 400)
        self:AddNumText("#{BHXZ_081211_32}", 6, 600)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if key == 11 then
        self:NotifyFailBox(selfId, targetId, "#{BHXZ_081211_31}")
        return
    end
    if key == 12 then
        self:BeginUICommand()
        self:UICommand_AddInt(targetId)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 1000)
        return
    end
    if key == 13 then return end
    if key == 14 then return end
    if key == 15 then return end
    if key == 100 or key == 200 or key == 300 or key == 400 then
        key = math.floor(key / 100)
        self:BeginEvent(self.script_id)
        self:AddText("#{BHXZ_081211_13}" .. self.g_ExchGoodsName[key] ..
                         "#{BHXZ_081211_10}" .. self.g_ConsumeHonour[key] ..
                         "#{BHXZ_081211_14}")
        self:AddNumText("#{BHXZ_081211_15}", 8, key * 1000)
        self:AddNumText("#{BHXZ_081211_16}", 8, 12)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if key == 1000 or key == 2000 or key == 3000 or key == 4000 then
        key = math.floor(key / 1000)
        local Honour = self:GetHonour(selfId)
        if Honour < self.g_ConsumeHonour[key] then
            self:NotifyFailBox(selfId, targetId,
                               "#{BHXZ_081211_9}" .. self.g_ExchGoodsName[key] ..
                                   "#{BHXZ_081211_10}" ..
                                   self.g_ConsumeHonour[key] ..
                                   "#{BHXZ_081211_11}")
            return
        end
        self:BeginAddItem()
        self:AddItem(self.g_ExchGoodsIndex[key], 1)
        local bBagOk = self:EndAddItem(selfId)
        if not bBagOk then
            self:NotifyFailBox(selfId, targetId, "#{BHXZ_081211_12}")
            return
        end
        if self:SetHonour(selfId, Honour - self.g_ConsumeHonour[key]) then
            local bagindex = self:TryRecieveItem(selfId, self.g_ExchGoodsIndex[key], true)
            if bagindex ~= -1 then
                local ItemInfo = self:GetBagItemTransfer(selfId, bagindex)
                local message = string.format(
                                    "#{BHXZ_081229_02}#{_INFOUSR%s}#{BHXZ_081229_03}%d#{BHXZ_081229_04}#{_INFOMSG%s}#{BHXZ_081229_05}",
                                    gbk.fromutf8(self:LuaFnGetName(selfId)),
                                    self.g_ConsumeHonour[key], ItemInfo)
                self:BroadMsgByChatPipe(selfId, message, 4)
                local guid = self:LuaFnObjId2Guid(selfId)
                local log = string.format(
                                "ItemIndex=%d,ConsumeHonour=%d,Honour=%d",
                                self.g_ExchGoodsIndex[key],
                                self.g_ConsumeHonour[key],
                                (Honour - self.g_ConsumeHonour[key]))
                self:ScriptGlobal_AuditGeneralLog(ScriptGlobal.LUAAUDIT_BANGZHAN_EXCHANGEHONOUR, guid, log)
            end
            self:NotifyFailBox(selfId, targetId, "#{BHXZ_081211_17}" ..
                                   self.g_ExchGoodsName[key] ..
                                   "#{BHXZ_081211_18}")
        end
        return
    end
    if key == 500 then
        self:BeginEvent(self.script_id)
        self:AddText("#{BHXZ_081211_19}")
        for i = 1, #(self.g_MenpaiName) do
            self:AddNumText(self.g_MenpaiName[i], 6, key + i * 10)
        end
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if key >= 510 and key < 600 then
        local type = math.floor((key - 500) / 10)
        self:BeginEvent(self.script_id)
        self:AddText("#{BHXZ_081211_13}" .. self.g_MenpaiName[type] ..
                         "#{BHXZ_081211_30}")
        self:AddNumText("#{BHXZ_081211_15}", 8, 700 + type * 10)
        self:AddNumText("#{BHXZ_081211_16}", 8, 12)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if key == 600 then
        local Honour = self:GetHonour(selfId)
        if self:GetHumanGuildID(selfId) == -1 then
            self:NotifyFailBox(selfId, targetId, "#{BHXZ_081211_35}")
            return
        end
        if self:CityGetSelfCityID(selfId) == -1 then
            self:NotifyFailBox(selfId, targetId, "#{BHXZ_081211_36}")
            return
        end
        if Honour < self.g_WantHonour then
            self:NotifyFailBox(selfId, targetId, "#{BHXZ_081211_33}")
            return
        end
        if self:SetHonour(selfId, Honour - self.g_WantHonour) then
            self:CityChangeAttr(selfId, ScriptGlobal.GUILD_CONTRIB_POINT, self.g_GiveBanggong)
            local message = string.format(
                                "@*;SrvMsg;GLD:#{_INFOUSR%s}#{BHXZ_081229_01}",
                                gbk.fromutf8(self:LuaFnGetName(selfId)))
            self:BroadMsgByChatPipe(selfId, message, 6)
            self:NotifyFailBox(selfId, targetId, "#{BHXZ_081211_34}")
            local guid = self:LuaFnObjId2Guid(selfId)
            local log = string.format(
                            "CONTRIB_POINT=%d,ConsumeHonour=%d,Honour=%d",
                            self.g_GiveBanggong, self.g_WantHonour,
                            (Honour - self.g_WantHonour))
            self:ScriptGlobal_AuditGeneralLog(ScriptGlobal.LUAAUDIT_BANGZHAN_EXCHANGEHONOUR, guid, log)
        end
        return
    end
    if key >= 710 and key < 800 then
        local type = math.floor((key - 700) / 10)
        local Honour = self:GetHonour(selfId)
        if Honour < self.g_MenpaiWantHonour then
            self:NotifyFailBox(selfId, targetId, "#{BHXZ_081211_9}" ..
                                   self.g_MenpaiName[type] ..
                                   "#{BHXZ_081211_29}")
            return
        end
        self:BeginAddItem()
        self:AddItem(self.g_MenpaiGoodsIndex[type], 1)
        local bBagOk = self:EndAddItem(selfId)
        if not bBagOk then
            self:NotifyFailBox(selfId, targetId, "#{BHXZ_081211_12}")
            return
        end
        if self:SetHonour(selfId, Honour - self.g_MenpaiWantHonour) == 1 then
            local bagindex = self:TryRecieveItem(selfId, self.g_MenpaiGoodsIndex[type], true)
            if bagindex ~= -1 then
                local ItemInfo = self:GetBagItemTransfer(selfId, bagindex)
                local message = string.format("#{BHXZ_081229_02}#{_INFOUSR%s}#{BHXZ_081229_03}%d#{BHXZ_081229_04}#{_INFOMSG%s}#{BHXZ_081229_05}",
                                    gbk.fromutf8(self:LuaFnGetName(selfId)),
                                    self.g_MenpaiWantHonour, ItemInfo)
                self:BroadMsgByChatPipe(selfId, message, 4)
                local guid = self:LuaFnObjId2Guid(selfId)
                local log = string.format(
                                "ItemIndex=%d,ConsumeHonour=%d,Honour=%d",
                                self.g_MenpaiGoodsIndex[type],
                                self.g_MenpaiWantHonour,
                                (Honour - self.g_MenpaiWantHonour))
                self:ScriptGlobal_AuditGeneralLog(ScriptGlobal.LUAAUDIT_BANGZHAN_EXCHANGEHONOUR, guid, log)
            end
            self:NotifyFailBox(selfId, targetId, "#{BHXZ_081211_17}" .. self.g_MenpaiName[type] .. "#{BHXZ_081211_18}")
        end
        return
    end
    for i, findId in pairs(self.g_eventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId, index)
            return
        end
    end
end

function oluoyang_zhouran:OnMissionAccept(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            local ret =
                self:CallScriptFunction(missionScriptId, "CheckAccept", selfId)
            if ret > 0 then
                self:CallScriptFunction(missionScriptId, "OnAccept", selfId)
            end
            return
        end
    end
end

function oluoyang_zhouran:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function oluoyang_zhouran:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId,
                                    targetId)
            return
        end
    end
end

function oluoyang_zhouran:OnMissionSubmit(selfId, targetId, missionScriptId,
                                          selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId,
                                    targetId, selectRadioId)
            return
        end
    end
end

function oluoyang_zhouran:NotifyFailBox(selfId, targetId, msg)
    self:BeginEvent(self.script_id)
    self:AddText(msg)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oluoyang_zhouran:NotifyFailTips(selfId, Tip)
    self:BeginEvent(self.script_id)
    self:AddText(Tip)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

function oluoyang_zhouran:CheckBuyLuoyang(selfId, targetId)
    if self:IsPilferLockFlag(selfId) <= 0 then return 0 end
    if self:GetHumanGuildID(selfId) == -1 then
        self:NotifyFailTips(selfId, "#{BHXZ_090112_01}")
        return 0
    end
    if self:CityGetSelfCityID(selfId) == -1 then
        self:NotifyFailTips(selfId, "#{BHXZ_090112_02}")
        return 0
    end
    if self:LuaFnGetWorldGlobalData(self.g_LuoyangOwnerIndex) > 0 then
        self:NotifyFailTips(selfId, "#{BHXZ_090112_04}")
        return 0
    end
    if self:GetMoney(selfId) < self.g_BuyLuoyangMoney then
        self:NotifyFailTips(selfId, "#{BHXZ_090112_05}")
        return 0
    end
    return 1
end

function oluoyang_zhouran:CheckGetCityTitle(selfId, targetId)
    if not self:IsPilferLockFlag(selfId) then return 0 end
    local GuildID = self:GetHumanGuildID(selfId)
    if GuildID == -1 then
        self:NotifyFailTips(selfId, "#{BHXZ_090112_07}")
        return 0
    end
    if (GuildID + self.g_BaseGuildIndex) ~=
        self:LuaFnGetWorldGlobalData(self.g_LuoyangOwnerIndex) then
        self:NotifyFailTips(selfId, "#{BHXZ_090112_08}")
        return 0
    end
    if self:GetTitle(selfId, self.g_PrizeTitle["AwardPos"]) ==
        self.g_PrizeTitle["Index"] then
        self:NotifyFailTips(selfId, "#{BHXZ_090112_09}")
        return 0
    end
    return 1
end

function oluoyang_zhouran:CheckGetMoneyJZ(selfId, targetId)
    if self:IsPilferLockFlag(selfId) then return 0 end
    local GuildID = self:GetHumanGuildID(selfId)
    if GuildID == -1 then
        self:NotifyFailTips(selfId, "#{BHXZ_090112_07}")
        return 0
    end
    if (GuildID + self.g_BaseGuildIndex) ~= self:LuaFnGetWorldGlobalData(self.g_LuoyangOwnerIndex) then
        self:NotifyFailTips(selfId, "#{BHXZ_090112_11}")
        return 0
    end
    if not self:GetTodayWeek() then
        self:NotifyFailTips(selfId, "#{BHXZ_090112_12}")
        return 0
    end
    if self:GetMissionData(selfId, define.MD_ENUM.MD_LUOYANG_CITYMONEY) >= self:GetDayTime() then
        self:NotifyFailTips(selfId, "#{BHXZ_090112_13}")
        return 0
    end
    return 1
end

return oluoyang_zhouran
