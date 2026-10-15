-- 402245
-- 段延庆   燕子坞副本内
local class = require "class"
local script_base = require "script_base"
local duanyanqing = class("huyanzhuo", script_base)
local tbl = {
    IDX_TimerPrepare = 1,
    IDX_TimerInterval = 2,
    IDX_FlagCombat = 1,
    BossSkill = 1002,
    PrepareTime = 60000,
    SkillInterval = 60000,
    BossBuff = 9999
}

function duanyanqing:OnDie(selfId, killerId)
    self:LuaFnNpcChat(selfId, 0, "Mối nhục chiến bại hôm nay, ngày sau nhất định phải đòi lại gấp bội!")
    self:MonsterAI_SetIntParamByIndex(selfId, tbl.IDX_TimerPrepare, 0)
    self:MonsterAI_SetIntParamByIndex(selfId, tbl.IDX_TimerInterval, 0)
    self:MonsterAI_SetBoolParamByIndex(selfId, tbl.IDX_FlagCombat, 0)
    -- 检测目前的副本进度
    self:LuaFnSetCopySceneData_Param(8, 9)
end

function duanyanqing:OnHeartBeat() end

function duanyanqing:OnInit(selfId)
    self:MonsterAI_SetIntParamByIndex(selfId, tbl.IDX_TimerPrepare, 0)
    self:MonsterAI_SetIntParamByIndex(selfId, tbl.IDX_TimerInterval, 0)
    self:MonsterAI_SetBoolParamByIndex(selfId, tbl.IDX_FlagCombat, 0)
end

function duanyanqing:OnKillCharacter() end

function duanyanqing:OnEnterCombat(selfId)
    self:MonsterAI_SetIntParamByIndex(selfId, tbl.IDX_TimerPrepare,
                                      tbl.PrepareTime)
    self:MonsterAI_SetIntParamByIndex(selfId, tbl.IDX_TimerInterval, 0)
    self:MonsterAI_SetBoolParamByIndex(selfId, tbl.IDX_FlagCombat, 1)
end

function duanyanqing:OnLeaveCombat(selfId)
    self:MonsterAI_SetIntParamByIndex(selfId, tbl.IDX_TimerPrepare, 0)
    self:MonsterAI_SetIntParamByIndex(selfId, tbl.IDX_TimerInterval, 0)
    self:MonsterAI_SetBoolParamByIndex(selfId, tbl.IDX_FlagCombat, 0)
end

return duanyanqing
