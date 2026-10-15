local class = require "class"
local define = require "define"
local script_base = require "script_base"
local yuelaosan = class("yuelaosan", script_base)
yuelaosan.TBL = {
    IDX_TimerPrepare = 1,
    IDX_TimerInterval = 2,
    IDX_FlagCombat = 1,
    BossSkill = 1002,
    PrepareTime = 60000,
    SkillInterval = 60000,
    BossBuff = 9999
}

function yuelaosan:OnDie(selfId, killerId)
    self:LuaFnNpcChat(selfId, 0, "Tam muội, Tứ đệ mau đến, đối thủ khó chơi, Nhị ca ta phải lui trước đây.")
    self:MonsterAI_SetIntParamByIndex(selfId, self.TBL.IDX_TimerPrepare, 0)
    self:MonsterAI_SetIntParamByIndex(selfId, self.TBL.IDX_TimerInterval, 0)
    self:MonsterAI_SetBoolParamByIndex(selfId, self.TBL.IDX_FlagCombat, 0)
    -- 死亡的时候，通知副本刷怪
    self:LuaFnSetCopySceneData_Param(8, 4)
end

function yuelaosan:OnHeartBeat(selfId, nTick) end

function yuelaosan:OnInit(selfId)
    self:MonsterAI_SetIntParamByIndex(selfId, self.TBL.IDX_TimerPrepare, 0)
    self:MonsterAI_SetIntParamByIndex(selfId, self.TBL.IDX_TimerInterval, 0)
    self:MonsterAI_SetBoolParamByIndex(selfId, self.TBL.IDX_FlagCombat, 0)
end

function yuelaosan:OnKillCharacter(selfId, targetId) end

function yuelaosan:OnEnterCombat(selfId, enmeyId)
    self:MonsterAI_SetIntParamByIndex(selfId, self.TBL.IDX_TimerPrepare,
                                      self.TBL.PrepareTime)
    self:MonsterAI_SetIntParamByIndex(selfId, self.TBL.IDX_TimerInterval, 0)
    self:MonsterAI_SetBoolParamByIndex(selfId, self.TBL.IDX_FlagCombat, 1)
end

function yuelaosan:OnLeaveCombat(selfId)
    self:MonsterAI_SetIntParamByIndex(selfId, self.TBL.IDX_TimerPrepare, 0)
    self:MonsterAI_SetIntParamByIndex(selfId, self.TBL.IDX_TimerInterval, 0)
    self:MonsterAI_SetBoolParamByIndex(selfId, self.TBL.IDX_FlagCombat, 0)
end

return yuelaosan
