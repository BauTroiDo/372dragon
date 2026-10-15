local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local daqi = class("daqi", script_base)
daqi.script_id = 402301
daqi.g_BangzhanScriptId = 402047
daqi.g_FlagTime = 10 * 60
daqi.g_OpenFlagSelfIDIndex = 10
daqi.g_OpenFlagStartTime = 11
daqi.g_FlagRemainedTime = 12
daqi.g_GuildPoint_GetFlag = 4
daqi.g_A_FlagNumIndex = 16
daqi.g_B_FlagNumIndex = 17
daqi.g_Human_FlagIndex = 3
daqi.g_A_FlagName = "炎黄战旗"
daqi.g_A_FlagID = 13332
daqi.g_A_FlagPosX = 115.9615
daqi.g_A_FlagPosZ = 130.9660
daqi.g_B_FlagName = "蚩尤战旗"
daqi.g_B_FlagID = 13323
daqi.g_B_FlagPosX = 115.9615
daqi.g_B_FlagPosZ = 130.9660
function daqi:OnActivateConditionCheck(selfId, activatorId)
    local sceneType = self:LuaFnGetSceneType()
    if sceneType ~= 1 then
        self:BeginEvent(self.script_id)
        self:AddText("#{BHXZ_081103_78}")
        self:EndEvent()
        self:DispatchMissionTips(activatorId)
        return 0
    end
    local fubentype = self:LuaFnGetCopySceneData_Param(0)
    if fubentype ~= ScriptGlobal.FUBEN_BANGZHAN then
        self:BeginEvent(self.script_id)
        self:AddText("#{BHXZ_081103_78}")
        self:EndEvent()
        self:DispatchMissionTips(activatorId)
        return 0
    end
    if self:LuaFnGetCopySceneData_Param(7) == 0 then
        self:BeginEvent(self.script_id)
        self:AddText("#{BHXZ_081103_79}")
        self:EndEvent()
        self:DispatchMissionTips(activatorId)
        return 0
    end
    local RemainedTime = self:LuaFnGetCopySceneData_Param(self.g_FlagRemainedTime)
    if RemainedTime > 0 then
        local minute = math.floor(RemainedTime / 60)
        local second = RemainedTime % 60
        self:BeginEvent(self.script_id)
        if minute == 0 then
            self:AddText("#{BHXZ_081103_80}" .. second .. "#{BHXZ_081103_81}")
        else
            self:AddText("#{BHXZ_081103_80}" .. minute .. "phân" .. second .. "#{BHXZ_081103_81}")
        end
        self:EndEvent()
        self:DispatchMissionTips(activatorId)
        return 0
    end
    if self:LuaFnIsUnbreakable(activatorId) then
        self:BeginEvent(self.script_id)
        self:AddText("#{BHXZ_081103_124}")
        self:EndEvent()
        self:DispatchMissionTips(activatorId)
        return 0
    end
    local totalguildid = self:LuaFnGetCopySceneData_Param(6)
    local Aguildid = math.floor(totalguildid / 10000)
    local Bguildid = totalguildid % 10000
    local guildid = self:GetHumanGuildID(activatorId)
    if guildid ~= Aguildid and guildid ~= Bguildid then
        self:BeginEvent(self.script_id)
        self:AddText("Ngươi không ở trong bang phái đúng.")
        self:EndEvent()
        self:DispatchMissionTips(activatorId)
        return 0
    end
    local OpenFlagSelfId = self:LuaFnGetCopySceneData_Param(self.g_OpenFlagSelfIDIndex)
    local OpenFlagStartTime = self:LuaFnGetCopySceneData_Param(self.g_OpenFlagStartTime)
    local NowTime = self:LuaFnGetCurrentTime()
    if OpenFlagSelfId ~= 0 then
        if OpenFlagSelfId == activatorId then
            return 1
        else
            if (NowTime - OpenFlagStartTime) <= 180 then
                self:BeginEvent(self.script_id)
                self:AddText(self:GetName(OpenFlagSelfId) .. "#{BHXZ_081103_65}")
                self:EndEvent()
                self:DispatchMissionTips(activatorId)
                return 0
            end
        end
    end
    self:LuaFnSetCopySceneData_Param(self.g_OpenFlagSelfIDIndex, activatorId)
    self:LuaFnSetCopySceneData_Param(self.g_OpenFlagStartTime, NowTime)
    return 1
end

function daqi:OnActivateDeplete(selfId, activatorId)
    return 1
end

function daqi:OnActivateEffectOnce(selfId, activatorId)
    local sceneType = self:LuaFnGetSceneType()
    if sceneType ~= 1 then
        self:BeginEvent(self.script_id)
        self:AddText("#{BHXZ_081103_78}")
        self:EndEvent()
        self:DispatchMissionTips(activatorId)
        return 1
    end
    local fubentype = self:LuaFnGetCopySceneData_Param(0)
    if fubentype ~= ScriptGlobal.FUBEN_BANGZHAN then
        self:BeginEvent(self.script_id)
        self:AddText("#{BHXZ_081103_78}")
        self:EndEvent()
        self:DispatchMissionTips(activatorId)
        return 1
    end
    local totalguildid = self:LuaFnGetCopySceneData_Param(6)
    local Aguildid = math.floor(totalguildid / 10000)
    local Bguildid = totalguildid % 10000
    local guildid = self:GetHumanGuildID(activatorId)
    local membercount = self:LuaFnGetCopyScene_HumanCount()
    local mems = {}
    for i = 1, membercount do
        mems[i] = self:LuaFnGetCopyScene_HumanObjId(i)
    end
    if guildid == Aguildid then
        local MstId = self:LuaFnCreateMonster(self.g_A_FlagID, self.g_A_FlagPosX, self.g_A_FlagPosZ, 3, 0, -1)
        self:SetCharacterName(MstId, self.g_A_FlagName)
        self:LuaFnSetCopySceneData_Param(self.g_FlagRemainedTime, self.g_FlagTime)
        local addpoint = self:GetGuildWarPoint(self.g_GuildPoint_GetFlag)
        self:CallScriptFunction(self.g_BangzhanScriptId, "AddAGuildPoint", activatorId, guildid, addpoint)
        local alreadynum = self:GetGuildIntNum(guildid, self.g_A_FlagNumIndex)
        self:SetGuildIntNum(guildid, self.g_A_FlagNumIndex, alreadynum + 1)
        self:CallScriptFunction(
            self.g_BangzhanScriptId,
            "AddHumanGuildArrayInt",
            activatorId,
            self.g_Human_FlagIndex,
            1
        )
        local guid = self:LuaFnObjId2Guid(activatorId)
        local log = string.format("HumanGuildID=%d,Apply_GuildID=%d,Applied_GuildID=%d", guildid, Aguildid, Bguildid)
        self:ScriptGlobal_AuditGeneralLog(ScriptGlobal.LUAAUDIT_BANGZHAN_FLAG, guid, log)
        local msg =
            self:LuaFnGetGuildName(activatorId) ..
            "#{BHXZ_081103_125}" .. self:GetName(activatorId) .. "Đã được dựng lên" .. self.g_A_FlagName .. "。"
        for i = 1, membercount do
            if self:LuaFnIsObjValid(mems[i]) and self:LuaFnIsCanDoScriptLogic(mems[i]) then
                self:NotifyFailTips(mems[i], msg)
                self:Msg2Player(mems[i], msg, define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
            end
        end
    elseif guildid == Bguildid then
        local MstId = self:LuaFnCreateMonster(self.g_B_FlagID, self.g_B_FlagPosX, self.g_B_FlagPosZ, 3, 0, -1)
        self:SetCharacterName(MstId, self.g_B_FlagName)
        self:LuaFnSetCopySceneData_Param(self.g_FlagRemainedTime, self.g_FlagTime)
        local addpoint = self:GetGuildWarPoint(self.g_GuildPoint_GetFlag)
        self:CallScriptFunction(self.g_BangzhanScriptId, "AddBGuildPoint", activatorId, guildid, addpoint)
        local alreadynum = self:GetGuildIntNum(guildid, self.g_B_FlagNumIndex)
        self:SetGuildIntNum(guildid, self.g_B_FlagNumIndex, alreadynum + 1)
        self:CallScriptFunction(
            self.g_BangzhanScriptId,
            "AddHumanGuildArrayInt",
            activatorId,
            self.g_Human_FlagIndex,
            1
        )
        local guid = self:LuaFnObjId2Guid(activatorId)
        local log = string.format("HumanGuildID=%d,Apply_GuildID=%d,Applied_GuildID=%d", guildid, Aguildid, Bguildid)
        self:ScriptGlobal_AuditGeneralLog(ScriptGlobal.LUAAUDIT_BANGZHAN_FLAG, guid, log)
        local msg =
            self:LuaFnGetGuildName(activatorId) ..
            "#{BHXZ_081103_125}" .. self:GetName(activatorId) .. "Đã được dựng lên" .. self.g_B_FlagName .. "。"
        for i = 1, membercount do
            if self:LuaFnIsObjValid(mems[i]) and self:LuaFnIsCanDoScriptLogic(mems[i]) then
                self:NotifyFailTips(mems[i], msg)
                self:Msg2Player(mems[i], msg, define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
            end
        end
    end
    self:LuaFnSetCopySceneData_Param(self.g_OpenFlagSelfIDIndex, 0)
    self:LuaFnSetCopySceneData_Param(self.g_OpenFlagStartTime, 0)
    return 1
end

function daqi:OnActivateEffectEachTick(selfId, activatorId)
    return 1
end

function daqi:OnActivateActionStart(selfId, activatorId)
    return 1
end

function daqi:OnActivateCancel(selfId, activatorId)
    return 0
end

function daqi:OnActivateInterrupt(selfId, activatorId)
    self:LuaFnSetCopySceneData_Param(self.g_OpenFlagSelfIDIndex, 0)
    self:LuaFnSetCopySceneData_Param(self.g_OpenFlagStartTime, 0)
    return 0
end

function daqi:NotifyFailTips(selfId, Tip)
    self:BeginEvent(self.script_id)
    self:AddText(Tip)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

return daqi
