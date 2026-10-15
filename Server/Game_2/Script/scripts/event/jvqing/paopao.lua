local class = require "class"
local define = require "define"
local script_base = require "script_base"
local paopao = class("paopao", script_base)
paopao.script_id = 200060
function paopao:Paopao(NpcName, sceneName, nPaopaoStr)
    local nMonsterNum = self:GetMonsterCount()
    for ii = 1, nMonsterNum do
        local nMonsterId = self:GetMonsterObjID(ii)
        if self:GetName(nMonsterId) == NpcName then
            self:MonsterTalk(nMonsterId, sceneName, nPaopaoStr)
        end
    end
end

function paopao:Duibai(NpcName, sceneName, szStr)
    if NpcName == "" then
        self:MonsterTalk(-1, sceneName, szStr)
        return
    end
    local nMonsterNum = self:GetMonsterCount()
    local bOk = false
    for ii = 1, nMonsterNum do
        local nMonsterId = self:GetMonsterObjID(ii)
        if self:GetName(nMonsterId) == NpcName then
            self:MonsterTalk(nMonsterId, sceneName, szStr)
            bOk = true
        end
    end
    if not bOk then self:MonsterTalk(-1, sceneName, szStr) end
end

return paopao
