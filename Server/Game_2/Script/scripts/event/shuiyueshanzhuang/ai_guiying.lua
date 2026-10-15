local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ai_guiying = class("ai_guiying", script_base)

function ai_guiying:OnDie(selfId,killerId)
    if self:GetName(selfId) == "鬼影" then
        local nHumanCount = self:LuaFnGetCopyScene_HumanCount()
        for i = 1, nHumanCount do
            local nHumanId = self:LuaFnGetCopyScene_HumanObjId(i)
            if self:LuaFnIsObjValid(nHumanId) and self:LuaFnIsCanDoScriptLogic(nHumanId) and self:LuaFnIsCharacterLiving(nHumanId) then
                if self:LuaFnHaveImpactOfSpecificDataIndex(nHumanId,50005) then
                    self:LuaFnCancelSpecificImpact(nHumanId,50005)
                    self:LuaFnCancelSpecificImpact(nHumanId,3779)
                end
            end
        end
    end
end
return ai_guiying
