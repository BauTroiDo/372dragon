local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oloulan_kelimu = class("oloulan_kelimu", script_base)
oloulan_kelimu.script_id = 001119
function oloulan_kelimu:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{loulan_baoshigongjiang_20080329}")
    self:AddNumText("Bảo thạch liên quan tửu quán", 11, 0)
    self:AddNumText("Nguyên liệu hợp thành tửu quán", 11, 20)
    self:AddNumText("Hợp thành Bảo thạch", 6, 1)
    self:AddNumText("Đục lỗ Trang bị", 6, 2)
    self:AddNumText("Gỡ Bảo thạch", 6, 3)
    self:AddNumText("Hợp thành Nguyên liệu", 6, 4)
    self:AddNumText("Khảm Bảo thạch", 6, 5)
    self:AddNumText("Điều khắc Bảo thạch", 6, 6)
    self:AddNumText("Nấu chảy Bảo thạch", 6, 7)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oloulan_kelimu:OnEventRequest(selfId, targetId, arg, index)
    if index == 0 then
        self:BeginEvent(self.script_id)
        self:AddText("#{function_help_104}#r")
        self:AddNumText("Trang bị đục lỗ tửu quán", 11, 8)
        self:AddNumText("Bảo thạch hợp thành tửu quán", 11, 9)
        self:AddNumText("Bảo thạch khảm nạm tửu quán", 11, 10)
        self:AddNumText("Bảo thạch tháo gỡ tửu quán", 11, 11)
        self:AddNumText("Bảo thạch Điều khắc tửu quán", 11, 13)
        self:AddNumText("Bảo thạch nấu chảy tửu quán", 11, 14)
        self:AddNumText("Thắng lợi Bảo thạch tửu quán", 11, 15)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if index == 20 then
        self:BeginEvent(self.script_id)
        self:AddText("#{SJSJ_081021_003}#r")
        self:AddNumText("Tinh Thiết của Thao tác tửu quán", 11, 21)
        self:AddNumText("Bí ngân của Thao tác tửu quán", 11, 22)
        self:AddNumText("Vải Bông của Thao tác tửu quán", 11, 23)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if index == 21 then
        self:BeginEvent(self.script_id)
        self:AddText("#{SJSJ_081021_004}#r")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if index == 22 then
        self:BeginEvent(self.script_id)
        self:AddText("#{SJSJ_081021_005}#r")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if index == 23 then
        self:BeginEvent(self.script_id)
        self:AddText("#{SJSJ_081021_006}#r")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if index == 8 then
        self:BeginEvent(self.script_id)
        self:AddText("#{function_help_039}#r")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if index == 9 then
        self:BeginEvent(self.script_id)
        self:AddText("#{function_help_040}#r")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if index == 10 then
        self:BeginEvent(self.script_id)
        self:AddText("#{function_help_041}#r")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if index == 11 then
        self:BeginEvent(self.script_id)
        self:AddText("#{function_help_042}#r")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if index == 13 then
        self:BeginEvent(self.script_id)
        self:AddText("#{INTERFACE_XML_GemCarve_6}#r")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if index == 14 then
        self:BeginEvent(self.script_id)
        self:AddText("#{JKBS_081021_022}#r")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if index == 15 then
        self:BeginEvent(self.script_id)
        self:AddText("#{JKBS_081021_023}#r")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if index == 1 then
        self:BeginUICommand()
        self:UICommand_AddInt(targetId)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 23)
        return
    end
    if index == 2 then
        self:BeginUICommand()
        self:UICommand_AddInt(targetId)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 25)
        return
    end
    if index == 3 then
        self:BeginUICommand()
        self:UICommand_AddInt(targetId)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 27)
        return
    end
    if index == 4 then
        self:BeginUICommand()
        self:UICommand_AddInt(targetId)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 19810424)
        return
    end
    if index == 5 then
        self:BeginUICommand()
        self:UICommand_AddInt(targetId)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 19830424)
        return
    end
    if index == 6 then
        self:BeginUICommand()
        self:UICommand_AddInt(targetId)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 112236)
        return
    end
    if index == 7 then
        self:BeginUICommand()
        self:UICommand_AddInt(targetId)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 112237)
        return
    end
end

return oloulan_kelimu
