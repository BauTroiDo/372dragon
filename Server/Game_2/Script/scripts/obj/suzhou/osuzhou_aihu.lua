local class = require "class"
local define = require "define"
local script_base = require "script_base"
local osuzhou_aihu = class("osuzhou_aihu", script_base)
osuzhou_aihu.script_id = 001031
function osuzhou_aihu:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{ZSCH_20071018_004}")
    self:AddNumText("Lĩnh Trân Thú Chiến đấu danh hiệu", 6, 10)
    self:AddNumText("Trân Thúdanh hiệutửu quán", 11, 11)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function osuzhou_aihu:OnEventRequest(selfId, targetId, arg, index)
    if index == 10 then
        self:BeginUICommand()
        self:UICommand_AddInt(targetId)
        self:UICommand_AddInt(7)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 3)
    elseif index == 11 then
        self:MsgBox(selfId, targetId, "#{ZSCH_20071018_006}")
    end
end

function osuzhou_aihu:OnAcceptPetTitle(selfId, targetId, petHid, petLid)
    if petHid == nil or petLid == nil then
        self:MsgBox(selfId, targetId, "Xin hãy chọn Trân Thú Yêu cầu lĩnh danh hiệu.")
        return
    end
    if self:LuaFnIsPetGrowRateByGUID(selfId, petHid, petLid) == 0 then
        self:MsgBox(selfId, targetId, "#{ZSCH_20071018_008}")
        return
    end
    local nSavvy = self:GetPetSavvy(selfId, petHid, petLid)
    local nLevS = 0
    local nGrow = self:LuaFnGetPetGrowRateByGUID(selfId, petHid, petLid)
    local nLevG = 0
    local nPer = self:GetPetPerceptionLevel(selfId, petHid, petLid)
    local nLevP = 0
    if nSavvy == 10 then
        nLevS = 3
    elseif nSavvy >= 8 then
        nLevS = 2
    elseif nSavvy >= 5 then
        nLevS = 1
    elseif nSavvy >= 0 then
        nLevS = 0
    end
    if nGrow >= 4 then
        nLevG = 2
    elseif nGrow >= 3 then
        nLevG = 1
    elseif nGrow >= 1 then
        nLevG = 0
    end
    if nPer >= 9 then
        nLevP = 2
    elseif nPer >= 6 then
        nLevP = 1
    elseif nPer >= 1 then
        nLevP = 0
    end
    local nTitle = 100000 + 100 * nLevS + 10 * nLevG + nLevP
    local nRet = self:LuaFnSetPetTitle(selfId, petHid, petLid, nTitle)
    if nRet == 1 then
        self:MsgBox(selfId, targetId, "#{ZSCH_20071018_010}")
        local _, nTLevel, nTName, nTDes = self:LuaFnGetPetTitleAttr(selfId, petHid, petLid, nTitle)
        local szMsg
        if nTLevel ~= nil and nTLevel > 550 then
            szMsg =
                string.format(
                "#{ZSCH_NEW1}#{_INFOUSR%s}#{ZSCH_NEW2}#{_INFOMSG%s}#{ZSCH_NEW3}%s！",
                self:GetName(selfId),
                self:LuaFnGetPetTransferByGUID(selfId, petHid, petLid),
                nTName
            )
            self:AddGlobalCountNews(szMsg)
        end
    else
        self:MsgBox(selfId, targetId, "#{ZSCH_20071018_009}")
    end
end

function osuzhou_aihu:MsgBox(selfId, targetId, str)
    self:BeginEvent(self.script_id)
    self:AddText(str)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return osuzhou_aihu
