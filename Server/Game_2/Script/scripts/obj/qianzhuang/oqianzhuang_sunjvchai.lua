local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oqianzhuang_sunjvchai = class("oqianzhuang_sunjvchai", script_base)
oqianzhuang_sunjvchai.script_id = 701900
function oqianzhuang_sunjvchai:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    local strText = "#{YBSC_100111_41}"
    self:AddText(strText)
    self:AddNumText("#{YBSC_100111_43}", 7, 1)
    self:AddNumText("#{YBSC_100111_65}", 7, 2)
    self:AddNumText("#{YBSC_100111_58}", 7, 3)
    self:AddNumText("#{YBSC_XML_05}", 11, 10)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oqianzhuang_sunjvchai:OnEventRequest(selfId, targetId, arg, index)
    if index == 1 then
        self:BeginUICommand()
        self:UICommand_AddInt(targetId)
        self:UICommand_AddInt(1)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 701900)
    elseif index == 2 then
        self:BeginUICommand()
        self:UICommand_AddInt(targetId)
        self:UICommand_AddInt(2)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 701900)
    elseif index == 3 then
        self:notify_tips(selfId, "Ngươi không có Nguyên bảo có thể bù thu")
    elseif index == 10 then
        self:BeginEvent(self.script_id)
        local strText = "#{YBSC_100111_39}"
        self:AddText(strText)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    end
end

return oqianzhuang_sunjvchai
