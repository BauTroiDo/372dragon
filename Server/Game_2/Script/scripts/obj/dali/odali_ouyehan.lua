local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local odali_ouyehan = class("odali_ouyehan", script_base)
odali_ouyehan.script_id = 890285

function odali_ouyehan:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{SBFW_20230707_255}")
    self:AddNumText("#{SBFW_20230707_26}", 6, 1)
    --self:AddNumText("#G旧神兵数据修正", 6, 2)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function odali_ouyehan:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function odali_ouyehan:OnEventRequest(selfId, targetId, arg, index)
    if index == 1 then
        self:BeginUICommand()
        self:UICommand_AddInt(targetId)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 88881205)
	elseif index == 2 then
		self:BeginEvent(self.script_id)
		self:AddText("    Xin đặt thần binh vào ô đạo cụ đầu tiên.")
		self:AddNumText("#GSửa dữ liệu", 6, 3)
		self:EndEvent()
		self:DispatchEventList(selfId, targetId)
	elseif index == 3 then
		if self:FixLegacyShenBinData(selfId,0) then
			self:BeginEvent(self.script_id)
			self:AddText("    Dữ liệu thần binh đã sửa.")
			self:EndEvent()
			self:DispatchEventList(selfId, targetId)
		else
			self:BeginEvent(self.script_id)
			self:AddText("    Dữ liệu thần binh mới nhất, khỏi sửa.")
			self:EndEvent()
			self:DispatchEventList(selfId, targetId)
		end
    end
end

return odali_ouyehan
