--大理NPC
--武桐
local class = require "class"
local script_base = require "script_base"
local odali_wutong = class("odali_wutong", script_base)
function odali_wutong:OnDefaultEvent(selfId, targetId)
	self:BeginEvent(self.script_id)
    self:AddText("    Lúc sư phụ một mình, ta thường thấy người ngẩn ngơ trước một bức họa, lẽ nào đây là phiền não của người lớn mà họ nói?")
    self:AddNumText("Kéo dài tuổi thọ Võ Hồn",6,1)
    self:AddNumText("Xóa Võ Hồn mở rộng Thuộc tính",6,2)
    self:AddNumText("Nhuận Hồn Thạch hợp thành",6,3)
    self:AddNumText("Hồn Băng Châu hợp thành",6,4)
    -- self:AddNumText("改变武魂属相",6,5)
    self:AddNumText("Tẩy tỉ lệ trưởng thành Võ Hồn",6,6)
    self:AddNumText("Về việc kéo dài tuổi thọ Võ Hồn",11,7)
    self:AddNumText("Về việc xóa Võ Hồn mở rộng Thuộc tính",11,8)
    -- self:AddNumText("关于改变武魂属相",11,9)
    self:AddNumText("Về hợp thành đạo cụ võ hồn",11,9)
    self:AddNumText("Về việc tẩy tỉ lệ trưởng thành Võ Hồn",11,10)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function odali_wutong:OnEventRequest(selfId, targetId, arg, index)
	if index == 1 then
		self:BeginUICommand()
		    self:UICommand_AddInt(targetId)
	        self:UICommand_AddInt(3)
        self:EndUICommand()
        self:DispatchUICommand(selfId,20090721)
	elseif index == 2 then 
	    self:BeginUICommand()
		    self:UICommand_AddInt(targetId)
        self:EndUICommand()
        self:DispatchUICommand(selfId,20090727)
	elseif index == 3 then
		self:BeginUICommand()
		    self:UICommand_AddInt(targetId)
            self:UICommand_AddInt(2)
        self:EndUICommand()
        self:DispatchUICommand(selfId,2016110701)
	elseif index == 4 then
		self:BeginUICommand()
            self:UICommand_AddInt(1)
		    self:UICommand_AddInt(targetId)
        self:EndUICommand()
        self:DispatchUICommand(selfId,79007501)
	elseif index == 5 then
		self:BeginUICommand()
		    self:UICommand_AddInt(targetId)
	        self:UICommand_AddInt(3)
			self:UICommand_AddStr("#{WHYH_161121_94}")
        self:EndUICommand()
        self:DispatchUICommand(selfId,20090722)
	elseif index == 6 then
		self:BeginEvent(self.script_id)
		self:AddText("#{WHXCZL_091026_01}")
		self:AddNumText("#{WHXCZL_xml_XX(04)}",6,16)
		self:EndEvent()
		self:DispatchEventList(selfId, targetId)
	elseif index == 16 then
		self:BeginUICommand()
		    self:UICommand_AddInt(targetId)
	        self:UICommand_AddInt(5)
        self:EndUICommand()
        self:DispatchUICommand(selfId,20090722)
	elseif index == 7 then--开始介绍
		self:BeginEvent(self.script_id)
		self:AddText("#{WH_090909_06}" )
		self:EndEvent()
		self:DispatchEventList(selfId, targetId)
	elseif index == 8 then
		self:BeginEvent(self.script_id)
		self:AddText("#{WH_090909_07}" )
		self:EndEvent()
		self:DispatchEventList(selfId, targetId)
	elseif index == 10 then
		self:BeginEvent(self.script_id)
		self:AddText("#{WHGBSX_091015_01}" )
		self:EndEvent()
		self:DispatchEventList(selfId, targetId)
	elseif index == 11 then
		self:BeginEvent(self.script_id)
		self:AddText("#{WHXCZL_091026_02}" )
		self:EndEvent()
		self:DispatchEventList(selfId, targetId)
	elseif index == 100 then		
		self:OnDefaultEvent(selfId,targetId )
    elseif index >= 200 and index <= 205 then
		self:BeginEvent(self.script_id)
		if index == 202 then
			self:AddText("#{WU_090908_05}")
			self:AddNumText("Ta muốn hợp thành",6,206)
		elseif index == 203 then
			self:AddText("#{WU_090908_06}")
			self:AddNumText("Ta muốn hợp thành",6,207)
	    elseif index == 204 then
			self:AddText("#{WU_090908_07}")
			self:AddNumText("Ta muốn hợp thành",6,208)
	    elseif index == 205 then
			self:AddText("#{WU_090908_08}")
			self:AddNumText("Ta muốn hợp thành",6,209)
		end
		self:AddNumText("Hủy bỏ",8,100)
	    self:EndEvent()
		self:DispatchEventList(selfId, targetId)
    end
end

return odali_wutong