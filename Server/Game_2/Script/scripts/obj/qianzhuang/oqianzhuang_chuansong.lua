local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oqianzhuang_chuansong = class("oqianzhuang_chuansong", script_base)
oqianzhuang_chuansong.script_id = 181001
oqianzhuang_chuansong.g_gotoluoyang = 1
oqianzhuang_chuansong.g_YBBTIntro = 11
oqianzhuang_chuansong.g_leave = 20
function oqianzhuang_chuansong:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    local strText = "    Ngươi muốn làm gì?"
    self:AddText(strText)
    self:AddNumText("Trở về Lạc Dương", 9, self.g_gotoluoyang)
    self:AddNumText("Nguyên bảo Bày bán tửu quán", 11, self.g_YBBTIntro)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oqianzhuang_chuansong:OnEventRequest(selfId, targetId, arg, index)
    if index == self.g_gotoluoyang then
        self:CallScriptFunction((400900), "TransferFunc", selfId, 0, 303, 314)
    elseif index == self.g_YBBTIntro then
        self:BeginEvent(self.script_id)
        self:AddText("#{YBBT_081023_1}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    elseif index == self.g_leave then
        self:BeginUICommand()
        self:UICommand_AddInt(targetId)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 1000)
    end
end

return oqianzhuang_chuansong
