--洛阳NPC
--彭怀玉
--普通
local class = require "class"
local script_base = require "script_base"
local oluoyang_penghuaiyu = class("oluoyang_penghuaiyu", script_base)

function oluoyang_penghuaiyu:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
        self:AddText("#{BSLCYH_130529_02}")
        self:AddNumText("#{JXDK_20220121_05}", 11, 0)
        self:AddNumText("#{JXDK_20220121_06}", 11, 20)
        self:AddNumText("#{JXDK_20220121_02}", 6, 100)
        self:AddNumText("#{JXDK_20220121_03}", 6, 101)
        --self:AddNumText("#{JXDK_20220121_04}", 6, 4)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oluoyang_penghuaiyu:OnEventRequest(selfId, targetId, arg, index)
    print("oluoyang_penghuaiyu:OnEventRequest", selfId, targetId, arg, index)
    if index == 100 then
        self:BeginEvent(self.script_id)
            self:AddNumText("#{JXDK_20220121_07}", 6, 2)
            self:AddNumText("#{JXDK_20220121_08}", 6, 5)
            self:AddNumText("#{JXDK_20220121_09}", 6, 3)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if index == 101 then
        self:BeginEvent(self.script_id)
            self:AddNumText("#{JXDK_20220121_13}", 6, 1)
            self:AddNumText("#{JXDK_20220121_14}", 6, 6)
            self:AddNumText("#{JXDK_20220121_15}", 6, 7)
            self:AddNumText("#{JXDK_20220121_16}", 6, 16)
			-- self:AddNumText("#G宝石琢刻", 6, 24)
			-- self:AddNumText("#G宝石分离", 6, 25)
			self:AddNumText("#{BSFHC_240613_03}", 6, 999)
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
        self:DispatchUICommand(selfId, 2013060601)
        return
    end
    if index == 3 then
        self:BeginUICommand()
            self:UICommand_AddInt(targetId)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 2013060603)
        return
    end
	if index == 4 then
        self:BeginUICommand()
            self:UICommand_AddInt(1)
			self:UICommand_AddInt(targetId)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 920170825)
        return
    end
    if index == 5 then
        self:BeginUICommand()
            self:UICommand_AddInt(targetId)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 2013060602)
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
    if index == 16 then
        self:BeginUICommand()
            self:UICommand_AddInt(targetId)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 20110509)
        return
    end
    if index == 0 then
        self:BeginEvent(self.script_id)
        self:AddText("#{function_help_054}#r")
        self:AddNumText("Đục lỗ Trang bị", 11, 8)
        self:AddNumText("Hợp thành Bảo thạch", 11, 9)
        self:AddNumText("Khảm Bảo thạch", 11, 10)
        self:AddNumText("Gỡ Bảo thạch", 11, 11)
        self:AddNumText("Điều khắc Bảo thạch", 11, 13)
        self:AddNumText("Nấu chảy Bảo thạch", 11, 14)
        self:AddNumText("#{BSQKY_20110506_10}", 11, 17)
        self:AddNumText("Bảo thạch Thắng Lợi", 11, 15)
        self:AddNumText("#{JXDK_20220121_17}", 11, 205)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if index == 24 then
		self:BeginUICommand()
		self:UICommand_AddInt(targetId)
		self:UICommand_AddInt(888814)
		self:UICommand_AddInt(3)
		self:UICommand_AddInt(1)
		self:UICommand_AddStr("GemZhuoKe")
		self:EndUICommand()
		self:DispatchUICommand(selfId,50162021)
        return
    end
    if index == 25 then
		self:BeginUICommand()
		self:UICommand_AddInt(targetId)
		self:UICommand_AddInt(888814)
		self:UICommand_AddInt(2)
		self:UICommand_AddInt(1)
		self:UICommand_AddStr("GemFenLi")
		self:EndUICommand()
		self:DispatchUICommand(selfId,50162022)
        return
    end
    if index == 8 then
        self:BeginEvent(self.script_id)
        self:AddText("#{YZBS_20220719_01}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if index == 8 then
        self:BeginEvent(self.script_id)
        self:AddText("#{YZBS_20220719_01}")
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
        self:AddText("#{YZBS_20220719_02}")
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
    if index == 17 then
        self:BeginEvent(self.script_id)
        self:AddText("#{BSQKY_20110506_25}")
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
    if index == 205 then
        self:BeginEvent(self.script_id)
        self:AddText("#{YZBS_20220719_03}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if index == 20 then
        self:BeginEvent(self.script_id)
        self:AddText("#{SJSJ_081021_001}#r")
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
end

return oluoyang_penghuaiyu