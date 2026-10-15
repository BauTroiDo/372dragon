--云思儿

local class = require "class"
local script_base = require "script_base"
local osuzhou_yunsier = class("osuzhou_yunsier", script_base)
osuzhou_yunsier.g_shoptableindex = 102
local g_eventList = {400918, 400963}
function osuzhou_yunsier:OnDefaultEvent(selfId, targetId)
	self:BeginEvent(self.script_id)
        self:AddText("#{YXZ_80917_01}")
        for _, eventId in ipairs(g_eventList) do
            self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
        end
        self:AddNumText("Linh Thú Đan hợp thành",6,-99)
        self:AddNumText("Trân thú Huyễn hóa",6,10)
        self:AddNumText("Hợp thành Đan Dị Hoá Trân Thú",6,11)
        self:AddNumText("Tăng cường Linh tính Dị Hoá Trân Thú",6,12)
        self:AddNumText("Mua Kỹ năng Trân Thú thư",7,2)
        self:AddNumText("#{XXWD_8916_07}",11,5)
        self:AddNumText("Giới thiệu hợp thành Linh Thú Đan",11,-98)
        self:AddNumText("Làm thế nào để Trân thú nhanh chóng Thăng cấp",11,-97)
        self:AddNumText("Về Dị Hoá Trân Thú",11,-96)
        self:AddNumText("Về việc tăng cường Linh tính Dị Hoá Trân Thú",11,-95)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function osuzhou_yunsier:OnEventRequest(selfId, targetId, arg, index)
	if index == 1 then
		self:BeginUICommand()
		self:UICommand_AddInt(targetId)
		self:EndUICommand()
		self:DispatchUICommand(selfId, 1001095)
	elseif index == 2 then
		self:DispatchShopItem(selfId,targetId, self.g_shoptableindex )
	elseif index == 10 then
		self:BeginUICommand()
        self:UICommand_AddInt(targetId )
		self:EndUICommand()
		self:DispatchUICommand(selfId, 20090804)	--珍兽幻化
	elseif index == 12 then
		self:BeginUICommand()
        self:UICommand_AddInt(targetId)
		self:EndUICommand()
		self:DispatchUICommand(selfId, 20090805)	--珍兽幻化灵性提升
	elseif index == 11 then
		self:BeginEvent(targetId)
		self:AddText("#{RXZS_090804_9}")
		self:AddNumText("Hợp thành",6,20)
        self:EndEvent()
        self:DispatchEventList(selfId,targetId)
	elseif index == 5 then
		self:BeginEvent(targetId)
		self:AddText("#{XXWD_8916_08}" )
		self:EndEvent()
		self:DispatchEventList(selfId, targetId)
	end
	for _, eventId in ipairs(g_eventList) do
		if eventId == arg then
			self:CallScriptFunction(arg, "OnEventRequest", self, selfId)
		end
	end
end

return osuzhou_yunsier