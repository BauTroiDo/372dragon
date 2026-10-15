local ScriptGlobal = require "scripts.ScriptGlobal"
local class = require "class"
local define = require "define"
local script_base = require "script_base"
local HumanPaoDian = class("HumanPaoDian", script_base)
HumanPaoDian.script_id = 900019
function HumanPaoDian:OnSceneTimer(selfId)
    if ScriptGlobal.is_internal_test then
        local nYuanBao = 200000
        local maxYuanBao = 2100000000
        if self:LuaFnIsObjValid(selfId) and self:LuaFnIsCanDoScriptLogic(selfId) and self:LuaFnIsCharacterLiving(selfId) then
            local nYuanBaoNum = self:GetYuanBao(selfId)
            if nYuanBao + nYuanBaoNum > maxYuanBao then
                self:Tips(selfId, "Nguyên bảo mang theo quá nhiều")
            else
                self:CSAddYuanbao(selfId, nYuanBao)
                --self:Tips(selfId, string.format("获得%d点元宝。", nYuanBao))
            end
        end
    end
end

function HumanPaoDian:Tips(selfId, msg)
    self:BeginEvent(self.script_id)
    self:AddText(msg)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

return HumanPaoDian
