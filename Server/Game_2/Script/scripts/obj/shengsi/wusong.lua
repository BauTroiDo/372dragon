local class = require "class"
local define = require "define"
local script_base = require "script_base"
local wusong = class("wusong", script_base)
wusong.script_id = 892021
wusong.g_scriptId = 892009
wusong.g_MonsterId = 13561
wusong.g_CreateId = 13537
wusong.g_posX = 35
wusong.g_posY = 23
wusong.g_AIScript = 257
wusong.g_Title = "Thiên Thương Tinh"
wusong.monster_groupId = 1
function wusong:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("Sinh Tử Lôi Đài không dễ vượt đâu, mỗi lần thắng một BOSS trong phụ bản đều nhận vật phẩm thần bí cao cấp, cẩn thận nguy hiểm nhé!")
    self:AddNumText("#c00ff00Quyết chiến Võ Tụng?", 6, 200)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function wusong:OnEventRequest(selfId, targetId, arg, index)
    local nkey = self:LuaFnGetCopySceneData_Param(29)
    if index == 200 then
        if self:GetTeamLeader(selfId) ~= selfId then
            self:BeginEvent(self.script_id)
            self:AddText("#{PMF_20080521_07}")
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
            return
        end
        local ret, msg = self:CallScriptFunction(self.g_scriptId, "CheckHaveBOSS")
        if 1 == ret then
            self:BeginEvent(self.script_id)
            self:AddText(msg)
            self:EndEvent()
            self:DispatchMissionTips(selfId)
            return
        end
        local nCount = self:GetMonsterCount()
        for i = 1, nCount do
            local nObjId = self:GetMonsterObjID(i)
            local MosDataID = self:GetMonsterDataID(nObjId)
            if MosDataID == self.g_CreateId - nkey then
                self:BeginEvent(self.script_id)
                self:AddText("#GĐội bạn đã vào trận, xin đừng gọi quái lặp!")
                self:EndEvent()
                self:DispatchEventList(selfId, targetId)
                return
            end
        end
        self:CallScriptFunction(self.g_scriptId, "TipAllHuman", "Chiến đấu bắt đầu")
        local nMonsterNum = self:GetMonsterCount()
        local Monsters = self.g_MonsterId
        for i = 1, nMonsterNum do
            local MonsterId = self:GetMonsterObjID(i)
            if Monsters == self:GetMonsterDataID(MonsterId) then
                self:LuaFnSendSpecificImpactToUnit(MonsterId, MonsterId, MonsterId, 152, 0)
                self:SetCharacterDieTime(MonsterId, 1000)
            end
        end
        local posX = self.g_posX
        local posY = self.g_posY
        local AIScript = self.g_AIScript
        local Title = self.g_Title
        local MstId = self:LuaFnCreateMonster(self.g_CreateId - nkey, posX, posY, 27, AIScript, 892009)
        self:SetMonsterFightWithNpcFlag(MstId, 0)
        self:SetUnitReputationID(selfId, MstId, 29)
        self:SetMonsterGroupID(MstId, self.monster_groupId)
        self:SetNPCAIType(MstId, 1)
        if Title ~= "" then
            self:SetCharacterTitle(MstId, Title)
        end
        self:LuaFnSendSpecificImpactToUnit(MstId, MstId, MstId, 152, 0)
        self:BeginUICommand()
        self:EndUICommand()
        self:DispatchUICommand(selfId, 1000)
    end
end

function wusong:TipAllHuman(Str)
    local nHumanNum = self:LuaFnGetCopyScene_HumanCount()
    for i = 1, nHumanNum do
        local PlayerId = self:LuaFnGetCopyScene_HumanObjId(i)
        if self:LuaFnIsObjValid(PlayerId) and self:LuaFnIsCanDoScriptLogic(PlayerId) then
            self:BeginEvent(self.script_id)
            self:AddText(Str)
            self:EndEvent()
            self:DispatchMissionTips(PlayerId)
        end
    end
end

return wusong
