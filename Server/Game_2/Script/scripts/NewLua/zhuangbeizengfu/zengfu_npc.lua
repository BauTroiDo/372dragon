local class = require "class"
local script_base = require "script_base"

local zengfu_npc = class("zengfu_npc", script_base)

zengfu_npc.script_id = 990601
zengfu_npc.main_script_id = 990602

function zengfu_npc:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
        self:AddText("Chỗ này tăng trang bị được.")
        self:AddNumText("Bắt đầu tăng trang bị", 6, 1)
        self:AddNumText("Xem quy tắc tăng", 6, 2)
        self:AddNumText("Xem bảng cộng tăng", 6, 3)
        self:AddNumText("Xem phạm vi trang bị tăng được", 6, 4)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function zengfu_npc:OnEventRequest(selfId, targetId, arg, index)
    if index == 1 then
        self:CallScriptFunction(self.main_script_id, "TryOpenAmplifyPanel", selfId, targetId, self.script_id)
        return
    end

    if index == 2 then
		self:BeginEvent(self.script_id)
			self:AddText("#{ZF_260501_01}")
		self:EndEvent()
		self:DispatchEventList(selfId, targetId)
        return
    end

    if index == 3 then
		self:BeginEvent(self.script_id)
			self:AddText("#{ZF_260501_02}")
		self:EndEvent()
		self:DispatchEventList(selfId, targetId)
        return
    end

    if index == 4 then
		self:BeginEvent(self.script_id)
			self:AddText(
				"Phạm vi tăng được:#r"
				.. "1. Đồ thủ công tăng được.#r"
				.. "2. Đồ Trùng Lâu tăng được.#r"
				.. "3. Thần khí, võ hồn, ám khí, thất tình không tăng được."
			)
		self:EndEvent()
		self:DispatchEventList(selfId, targetId)
        return
    end
end


return zengfu_npc