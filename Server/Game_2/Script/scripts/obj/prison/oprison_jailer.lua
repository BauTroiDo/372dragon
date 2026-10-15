local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ScriptGlobal = require "scripts.ScriptGlobal"
local oprison_jailer = class("oprison_jailer", script_base)
oprison_jailer.script_id = 077011
oprison_jailer.g_Key = { ["dlg"] = 10, ["out"] = 11, ["sn0"] = 0, ["sn1"] = 1, ["sn2"] = 2 }
oprison_jailer.g_PKMinVal = 8
function oprison_jailer:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{PRISON_081120_01}")
    self:AddNumText("Ta muốn ra ngoài", 9, self.g_Key["out"])
    self:AddNumText("Nơi này là đâu?", 11, self.g_Key["dlg"])
    self:AddNumText("Ta muốn kêu oan", 9, 21)
    self:AddNumText("Ta có Lệnh Ân Xá", 9, 15)
    self:AddNumText("Thế nào là kêu oan?", 11, 22)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oprison_jailer:OnEventRequest(selfId, targetId, arg, index)
    local key = index
    local val = self:LuaFnGetHumanPKValue(selfId)
    if key == 15 then
        local nItemCount = self:LuaFnGetAvailableItemCount(selfId, 30008019)
        if nItemCount < 1 then
            self:MsgBox(selfId, targetId, "#{TeSheLing_00}")
            return 0
        end
        local bRet = 0
        local nItemNum = self:LuaFnGetAvailableItemCount(selfId, 30008019)
        if nItemNum < 1 then
            self:MsgBox(selfId, targetId, "Vật phẩm này đã bị khóa!")
            return 0
        end
        bRet = 1
        if bRet > 0 then
            self:BeginEvent(self.script_id)
            self:AddText("  Chúc mừng ngươi, cuối cùng ngươi cũng có thể rời khỏi nơi này, nhớ kỹ sau khi ra ngoài chớ nên lại giết hại người vô tội, nếu không ta sẽ không tha cho ngươi đâu, ngươi muốn đi thành nào?")
            self:AddNumText("Lạc Dương", 9, 3)
            self:AddNumText("Tô Châu", 9, 4)
            self:AddNumText("Đại Lý", 9, 5)
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
        end
        return 0
    end
    if key == 21 then
        self:ShenYuan(selfId, targetId)
        return 0
    elseif key == 22 then
        self:MsgBox(selfId, targetId, "#{PRISON_SHENYUAN_00}")
        return 0
    end
    if key == self.g_Key["dlg"] then
        self:MsgBox(selfId, targetId, "#{function_help_087}")
        return 0
    elseif key == self.g_Key["out"] then
        if val >= self.g_PKMinVal then
            self:MsgBox(selfId, targetId, "  Sát khí hiện tại của ngài là" .. val .. ", chỉ khi nhỏ hơn" .. self.g_PKMinVal .. "điểm của lúc đó mới có thể ra ngoài.")
            return 0
        end
        self:LuaFnCancelSpecificImpact(selfId, 42)
        self:BeginEvent(self.script_id)
        self:AddText("  Chúc mừng ngươi, cuối cùng ngươi cũng có thể rời khỏi nơi này, nhớ kỹ sau khi ra ngoài chớ nên lại giết hại người vô tội, nếu không ta sẽ không tha cho ngươi đâu, ngươi muốn đi thành nào?")
        self:AddNumText("Lạc Dương", 9, self.g_Key["sn0"])
        self:AddNumText("Tô Châu", 9, self.g_Key["sn1"])
        self:AddNumText("Đại Lý", 9, self.g_Key["sn2"])
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif key == self.g_Key["sn0"] then
        self:LuaFnCancelSpecificImpact(selfId,42)
        self:CallScriptFunction((400900), "TransferFunc", selfId, 0, 235, 322,10)
    elseif key == self.g_Key["sn1"] then
        self:LuaFnCancelSpecificImpact(selfId,42)
        self:CallScriptFunction((400900), "TransferFunc", selfId, 1, 204, 256,10)
    elseif key == self.g_Key["sn2"] then
        self:LuaFnCancelSpecificImpact(selfId,42)
        self:CallScriptFunction((400900), "TransferFunc", selfId, 2, 253, 121)
    elseif key == 3 then
        local nItemNum = self:LuaFnGetAvailableItemCount(selfId, 30008019)
        if nItemNum < 1 then
            self:MsgBox(selfId, targetId, "Vật phẩm này đã bị khóa!")
            return 0
        end
        self:LuaFnDelAvailableItem(selfId, 30008019, 1)
        if val > 4 then
            self:SetPKValue(selfId,4)
        end
        self:LuaFnCancelSpecificImpact(selfId,42)
        self:CallScriptFunction((400900), "TransferFunc", selfId, 0, 235, 322,10)
    elseif key == 4 then
        local nItemNum = self:LuaFnGetAvailableItemCount(selfId, 30008019)
        if nItemNum < 1 then
            self:MsgBox(selfId, targetId, "Vật phẩm này đã bị khóa!")
            return 0
        end
        self:LuaFnDelAvailableItem(selfId, 30008019, 1)
        if val > 4 then
            self:SetPKValue(selfId,4)
        end
        self:LuaFnCancelSpecificImpact(selfId,42)
        self:CallScriptFunction((400900), "TransferFunc", selfId, 1, 204, 256,10)
    elseif key == 5 then
        local nItemNum = self:LuaFnGetAvailableItemCount(selfId, 30008019)
        if nItemNum < 1 then
            self:MsgBox(selfId, targetId, "Vật phẩm này đã bị khóa!")
            return 0
        end
        self:LuaFnDelAvailableItem(selfId, 30008019, 1)
        if val > 4 then
            self:SetPKValue(selfId,4)
        end
        self:LuaFnCancelSpecificImpact(selfId,42)
        self:CallScriptFunction((400900), "TransferFunc", selfId, 2, 253, 121)
    end
    return 1
end

function oprison_jailer:MsgBox(selfId, targetId, msg)
    self:BeginEvent(self.script_id)
    self:AddText(msg)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oprison_jailer:ShenYuan(selfId, targetId)
    if self:LuaFnGetHumanPKValue(selfId) >= self.g_PKMinVal then
        self:MsgBox(selfId, targetId, "#{PRISON_SHENYUAN_01}")
        return
    end
    local lastDayTime = self:GetMissionDataEx(selfId, ScriptGlobal.MDEX_PRISON_SHENYUAN_DAYTIME)
    local CurDayTime = self:GetDayTime()
    if CurDayTime <= lastDayTime then
        self:MsgBox(selfId, targetId, "#{PRISON_SHENYUAN_03}")
        return
    end
    self:SetMissionDataEx(selfId, ScriptGlobal.MDEX_PRISON_SHENYUAN_DAYTIME, CurDayTime)
    self:BeginUICommand()
    self:EndUICommand()
    self:DispatchUICommand(selfId, 1000)
    self:LuaFnSendGuajiQuestion(selfId)
end

return oprison_jailer
