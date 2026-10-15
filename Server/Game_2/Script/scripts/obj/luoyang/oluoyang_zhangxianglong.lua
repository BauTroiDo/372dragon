--云涵儿

--脚本号
local gbk = require "wire_charset"
local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oluoyang_zhangxianglong = class("oluoyang_zhangxianglong", script_base)

function oluoyang_zhangxianglong:OnDefaultEvent(selfId, targetId)
	self:BeginEvent(self.script_id)
	    self:AddText("#{ZBDW_091105_1}")
	    self:AddNumText("Điêu Văn hợp thành",6,1)
	    self:AddNumText("Điêu Văn ăn mòn",6,2)
	    self:AddNumText("Điêu Văn cường hóa",6,4)
	    self:AddNumText("Chuyển di Điêu Văn",6,5)
	    self:AddNumText("Điêu Văn tháo dỡ",6,6)
	    -- self:AddNumText("#{DWCJJ_140606_01}",6,7)
	    self:AddNumText("Về Trang bị Điêu Văn",11,8)
	self:EndEvent()
	self:DispatchEventList(selfId,targetId)
end

function oluoyang_zhangxianglong:OnEventRequest(selfId, targetId, arg, index)
    if index == 1 then
		self:BeginUICommand()
		self:UICommand_AddInt(targetId)
		self:EndUICommand()
		self:DispatchUICommand(selfId, 1000156)
    elseif index == 2 then
		self:BeginUICommand()
		self:UICommand_AddInt(targetId)
		self:EndUICommand()
		self:DispatchUICommand(selfId, 2000156)
    elseif index == 4 then
		--local nMaterialNum = self:LuaFnMtl_GetCostNum(selfId,20310166,20310167,20310168)
		self:BeginUICommand()
        self:UICommand_AddInt(targetId)
		self:EndUICommand()
		self:DispatchUICommand(selfId, 3000156)--普通
		-- self:DispatchUICommand(selfId, 20141204)--快捷
	elseif index == 5 then
		self:BeginUICommand()
        self:UICommand_AddInt(1)
        self:UICommand_AddInt(targetId)
		self:EndUICommand()
		self:DispatchUICommand(selfId, 20141216)
	
    elseif index == 6 then
		self:BeginUICommand()
		self:UICommand_AddInt(targetId)
		self:EndUICommand()
		self:DispatchUICommand(selfId, 4000156)
	elseif index == 7 then
		self:BeginUICommand()
		self:UICommand_AddInt(targetId)
		self:EndUICommand()
		self:DispatchUICommand(selfId, 20140612)
    elseif index == 8 then
		self:BeginEvent(self.script_id)
        self:AddText("#{ZBDW_091105_21}")
		self:AddText("    #GMẹo: chuột phải trang bị, nguyên liệu để thao tác, chỉ trang bị cao cấp nhất định mới điêu văn được.")
		self:EndEvent()
		self:DispatchEventList(selfId,targetId)
    end
end

return oluoyang_zhangxianglong