local gbk = require "wire_charset"
local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oloulan_jinjiuling = class("oloulan_jinjiuling", script_base)
oloulan_jinjiuling.script_id = 001168
oloulan_jinjiuling.g_eventList = {808039}

oloulan_jinjiuling.g_moster_album_id = 30505192
oloulan_jinjiuling.g_exchange_num = 20
oloulan_jinjiuling.g_clothing_id = {
    10124416, 10124417, 10124406, 10124415, 10124414, 10124413, 10124412,
    10124410, 10124407
}

function oloulan_jinjiuling:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{LLXB_8815_06}")
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:AddNumText("#{LLXB_8820_01}", 6, 100)
    self:AddNumText("#{LLXB_8820_02}", 11, 101)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oloulan_jinjiuling:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function oloulan_jinjiuling:OnEventRequest(selfId, targetId, arg, index)
    for i, findId in pairs(self.g_eventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId,
                                    index, self.script_id)
            return
        end
    end
    if index == 100 then
        local num = self:LuaFnGetAvailableItemCount(selfId,
                                                    self.g_moster_album_id)
        if num == 0 then
            self:ShowMsg(selfId, targetId, "#{LLXB_8820_03}")
            return
        elseif num < 20 then
            self:ShowMsg(selfId, targetId, "#{LLXB_8820_04}")
            return
        end
        if self:LuaFnGetPropertyBagSpace(selfId) < 1 then
            self:ShowMsg(selfId, targetId, "#{SJQM_8815_06}")
            return
        end
        local menpaiId = self:GetMenPai(selfId)
        if menpaiId < 0 or menpaiId > 10 then
            self:ShowMsg(selfId, targetId, "#{LLXB_8820_06}")
            return
        end
        local nItemBagIndexalbum = self:GetBagPosByItemSn(selfId,
                                                          self.g_moster_album_id)
        local szTransferalbum = self:GetBagItemTransfer(selfId,
                                                        nItemBagIndexalbum)
        if self:LuaFnDelAvailableItem(selfId, self.g_moster_album_id,
                                      self.g_exchange_num) then
            local clothingId = self.g_clothing_id[menpaiId + 1]
            local ret = self:TryRecieveItem(selfId, clothingId, true)
            if ret then
                self:BeginEvent(self.script_id)
                self:AddText("Đổi Cao cấp Môn phái Thời Trang thành công!")
                self:EndEvent()
                self:DispatchMissionTips(selfId)
                self:Msg2Player(selfId, "Đổi Cao cấp Môn phái Thời Trang thành công!", 8)
                self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 18, 0)
                local PlayerName = self:GetName(selfId)
                PlayerName = gbk.fromutf8(PlayerName)
                local szTransferEquip = self:GetBagItemTransfer(selfId, ret)
                local str = string.format(
                                "#{_INFOUSR%s}#{GWXCSZGG_1}#{_INFOMSG%s}#{GWXCSZGG_2}#{_INFOMSG%s}#{GWXCSZGG_3}",
                                PlayerName, szTransferalbum, szTransferEquip)
                self:BroadMsgByChatPipe(selfId, str, 4)
                self:AuditExchangeMenpaiSuit(selfId, menpaiId, clothingId)
            end
        end
    elseif index == 101 then
        self:ShowMsg(selfId, targetId, "#{LLXB_8820_05}")
    end
end

function oloulan_jinjiuling:OnMissionAccept(selfId, targetId, missionScriptId)
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

function oloulan_jinjiuling:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function oloulan_jinjiuling:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId,
                                    targetId)
            return
        end
    end
end

function oloulan_jinjiuling:OnMissionSubmit(selfId, targetId, missionScriptId,
                                            selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId,
                                    targetId, selectRadioId)
            return
        end
    end
end

function oloulan_jinjiuling:ShowMsg(selfId, targetId, msg)
    self:BeginEvent(self.script_id)
    self:AddText(msg)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oloulan_jinjiuling
