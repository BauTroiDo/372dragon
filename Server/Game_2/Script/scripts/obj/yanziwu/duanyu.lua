-- 402256
-- 段誉
local class = require "class"
local define = require "define"
local script_base = require "script_base"
local duanyu = class("duanyu", script_base)
function duanyu:OnDie(selfId)
    self:MonsterAI_SetIntParamByIndex(selfId, 1, 0)
    self:MonsterAI_SetIntParamByIndex(selfId, 2, 0)
    self:MonsterAI_SetBoolParamByIndex(selfId, 1, 0)
end

function duanyu:OnDefaultEvent() end

function duanyu:OnHeartBeat(selfId)
    -- 当段誉血减少的时候，改变段誉的Ai——File
    if (self:LuaFnIsCharacterLiving(selfId)) then
        if (1 == self:MonsterAI_GetBoolParamByIndex(selfId, 1)) then
            if self:GetHp(selfId) <= self:GetMaxHp(selfId) - 500 then
                self:SetAIScriptID(selfId, 246)
                -- 改变段誉家臣的阵营
                local nMonsterNum = self:GetMonsterCount()
                for i = 1, nMonsterNum do
                    local nMonsterId = self:GetMonsterObjID(i)
                    local szName = self:GetName(nMonsterId)
                    if szName == "巴天石" or szName == "范骅" or szName ==
                        "褚万里" or szName == "古笃诚" or szName ==
                        "傅思归" or szName == "朱丹臣" then
                        if self:GetUnitCampID(nMonsterId) ~= 110 then
                            self:SetUnitCampID(nMonsterId, 110)
                            self:CallScriptFunction((200060), "Paopao", szName,
                                                    "燕子坞",
                                                    "Dừng tay, chớ làm tổn thương công tử nhà ta!")
                        end
                    end
                end
            end
        end
    end
end

function duanyu:OnInit(selfId)
    self:MonsterAI_SetIntParamByIndex(selfId, 1, 0)
    self:MonsterAI_SetIntParamByIndex(selfId, 2, 0)
    self:MonsterAI_SetBoolParamByIndex(selfId, 1, 0)
end

function duanyu:OnKillCharacter() end

function duanyu:OnEnterCombat(selfId)
    self:MonsterAI_SetIntParamByIndex(selfId, 1, 60000)
    self:MonsterAI_SetIntParamByIndex(selfId, 2, 0)
    self:MonsterAI_SetBoolParamByIndex(selfId, 1, 1)
end

function duanyu:OnLeaveCombat(selfId)
    self:MonsterAI_SetIntParamByIndex(selfId, 1, 0)
    self:MonsterAI_SetIntParamByIndex(selfId, 2, 0)
    self:MonsterAI_SetBoolParamByIndex(selfId, 1, 0)
end

return duanyu
