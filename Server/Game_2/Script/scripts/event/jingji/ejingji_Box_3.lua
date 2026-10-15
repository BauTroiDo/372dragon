local gbk = require "wire_charset"
local ScriptGlobal = require "scripts.ScriptGlobal"local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ejingji_Box_3 = class("ejingji_Box_3", script_base)
ejingji_Box_3.script_id = 125024

function ejingji_Box_3:OnActivateConditionCheck(selfId, activatorId)
    local bOk = self:CallScriptFunction((125022), "IsCanOpenBox", activatorId)
    if bOk == 0 then
        self:BeginEvent(self.script_id)
        self:AddText("Ngươi hiện tại không thể mở rương báu này.")
        self:EndEvent()
        self:DispatchMissionTips(activatorId, selfId)
    end
    if self:GetUnitCampID(activatorId) < 10 then
        self:BeginEvent(self.script_id)
        self:AddText("Trận doanh Chiến đấu của ngươi hiện tại không chính xác, không thể mở bảo tương.")
        self:EndEvent()
        self:DispatchMissionTips(activatorId, selfId)
        bOk = 0
    end
    return bOk
end

function ejingji_Box_3:OnActivateDeplete(selfId, activatorId) return 1 end
function ejingji_Box_3:OnActivateEffectOnce(selfId, activatorId)
    local x, z = self:GetWorldPos(selfId)
    self:LuaFnDeleteMonster(selfId)
    local nItemId = 40004434
    local nBoxId = self:DropBoxEnterScene(x, z)
    if nBoxId > -1 then
        self:AddItemToBox(nBoxId, ScriptGlobal.QUALITY_CREATE_BY_BOSS, 1, nItemId)
        self:SetItemBoxOwner(nBoxId, self:LuaFnGetGUID(activatorId))
    end
    return 1
end

function ejingji_Box_3:OnActivateEffectEachTick(selfId, activatorId) return 1 end

function ejingji_Box_3:OnActivateActionStart(selfId, activatorId) return 1 end

function ejingji_Box_3:OnActivateCancel(selfId, activatorId) return 0 end

function ejingji_Box_3:OnActivateInterrupt(selfId, activatorId) return 0 end

function ejingji_Box_3:OnActivateInterrupt(selfId, activatorId) end

return ejingji_Box_3
