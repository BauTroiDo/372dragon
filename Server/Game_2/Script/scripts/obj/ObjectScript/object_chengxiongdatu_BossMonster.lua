local class = require "class"
local define = require "define"
local script_base = require "script_base"
local object_chengxiongdatu_BossMonster = class("object_chengxiongdatu_BossMonster", script_base)
object_chengxiongdatu_BossMonster.script_id = 807000
object_chengxiongdatu_BossMonster.g_dropitemId = 20309009
function object_chengxiongdatu_BossMonster:OnDie(objId, killerId)
    local PlayerId = killerId
    local objType = self:GetCharacterType(killerId)
    if objType == 3 then
        PlayerId = self:GetPetCreator(killerId)
    end
    self:AddMonsterDropItem(objId, PlayerId, self.g_dropitemId)
end

return object_chengxiongdatu_BossMonster
