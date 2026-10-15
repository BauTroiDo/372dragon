local pet_gameplay = require "cy_pet_gameplay"
local gbk = require "wire_charset"
local class = require "class"
local define = require "define"
local script_base = require "script_base"
local petskilllevelup = class("petskilllevelup", script_base)
petskilllevelup.script_id = 311112
petskilllevelup.g_NumText_Main = 1

function petskilllevelup:OnDefaultEvent(selfId, targetId, arg, index)
    local numText = index
    if numText == self.g_NumText_Main then
        self:BeginUICommand()
        self:UICommand_AddInt(targetId)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 19823)
    end
end

function petskilllevelup:OnEnumerate(caller, selfId, targetId, arg, index)
    caller:AddNumTextWithTarget(self.script_id, "Trân thú Kỹ năng Thăng cấp", 6, self.g_NumText_Main)
end

function petskilllevelup:PetSkillLevelup(selfId, petHid, petLid, skillindex, ItemIndexInBag, mode)
    local ok
    if mode==nil or mode==0 then ok=pet_gameplay.upgrade(self,selfId,petHid,petLid,skillindex,ItemIndexInBag)
    elseif mode==1 then ok=pet_gameplay.upgrade_quick(self,selfId,petHid,petLid,skillindex) end
    if not ok then
        self:NotifyFailTips(selfId, "Trân thú, kỹ năng, nguyên liệu hoặc tiền không hợp lệ.")
        return false
    end
    self:NotifyFailTips(selfId, "Thăng cấp thành công!")
    self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 18, 0)
    return true
end

function petskilllevelup:NotifyFailTips(selfId, Tip)
    self:BeginEvent(self.script_id)
    self:AddText(Tip)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

return petskilllevelup
