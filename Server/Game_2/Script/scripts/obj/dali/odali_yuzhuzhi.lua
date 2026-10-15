local class = require "class"
local define = require "define"
local script_base = require "script_base"
local odali_yuzhuzhi = class("odali_yuzhuzhi", script_base)
odali_yuzhuzhi.script_id = 002088
odali_yuzhuzhi.g_Key = {["mis"] = 100, ["itm"] = 101, ["do"] = 102}

odali_yuzhuzhi.g_MisItemList = {
    40004000,
    40004451,
    40004452,
    40004461,
    40004453,
    40004456,
    40004459,
    40004458,
    40004455,
    40004457,
    30505062,
    40004465,
    40004462,
    40004463,
    40004464
}

function odali_yuzhuzhi:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Ta phụng mệnh Hoàng đế nước Đại Lý bệ hạ, ở đây giúp các vị anh hùng trong thiên hạ dọn dẹp nhiệm vụ. Nếu như ngài muốn xóa bỏ tất cả nhiệm vụ trong danh sách nhiệm vụ, hoặc xóa bỏ một đạo cụ nhiệm vụ đặc định nào đó, đều có thể đến tìm ta giúp đỡ. Ngài muốn làm gì?")
    self:AddNumText("Ta muốn xóa bỏ tất cả nhiệm vụ của ta.", -1, self.g_Key["mis"])
    self:AddNumText("Ta muốn xóa đạo cụ nhiệm vụ", -1, self.g_Key["itm"])
	self:AddNumText("Ta muốn xóa tọa kỵ", -1, 300)
	self:AddNumText("Ta muốn xóa đạo cụ trong túi", -1, 310)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function odali_yuzhuzhi:CheckCanDelMission_OverTime(selfId, targetId, eventId)
    local DayTime = self:GetDayTime()
    local LastTime = self:GetMissionData(selfId, define.MD_ENUM.MD_NPC_DELMISSION)
    if DayTime > LastTime then
        self:SetMissionData(selfId, define.MD_ENUM.MD_NPC_DELMISSION, DayTime)
        return 1
    end
    return -1
end

function odali_yuzhuzhi:OnEventRequest(selfId, targetId, arg, index)
    local key = index
    if key == self.g_Key["mis"] then
        if not self:GetMissionCount(selfId) then
            self:BeginEvent(self.script_id)
            self:AddText("  Trên người ngươi vốn dĩ không có nhiệm vụ nào cả!")
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
        else
            self:BeginEvent(self.script_id)
            self:AddText("  Xóa bỏ nhiệm vụ sẽ xóa bỏ tất cả nhiệm vụ trên người, có xác nhận muốn xóa bỏ không?")
            self:AddNumText("确认", -1, self.g_Key["do"])
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
        end
    elseif key == self.g_Key["itm"] then
        self:BeginUICommand()
        self:UICommand_AddInt(targetId)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 42)
    elseif key == self.g_Key["do"] then
        if self:IsHaveMission(selfId, 1258) then
            self:DelItem(selfId, 40004454, 1)
        end
        self:DelAllMission(selfId)
        for i, nItemId in pairs(self.g_MisItemList) do
            local nItemCount = self:GetItemCount(selfId, nItemId)
            if nItemCount > 0 then
                self:DelItem(selfId, nItemId, nItemCount)
            end
        end
        self:notify_tips(selfId, "Xóa tất cả nhiệm vụ thành công!")
        self:BeginEvent(self.script_id)
        self:AddText("  Xóa tất cả nhiệm vụ thành công!")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
	elseif key == 300 then
		self:DelPlayerRide(selfId, 132)
		self:DelPlayerRide(selfId, 133)
		self:DelPlayerRide(selfId, 134)
		self:DelPlayerRide(selfId, 135)
	elseif key == 310 then
        self:BeginEvent(self.script_id)
        self:AddText("  Xóa túi sẽ xóa đạo cụ ô cuối, xác nhận xóa chứ?")
        self:AddNumText("确认", -1, 320)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
	elseif key == 320 then
		self:EraseItem(selfId, 99)
        self:notify_tips(selfId, "Xóa đạo cụ thành công!")
        self:BeginEvent(self.script_id)
        self:AddText("  Xóa đạo cụ thành công!")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    end
end

function odali_yuzhuzhi:OnDestroy(selfId, posItem)
    if posItem < 0 then
        return
    end
    self:EraseItem(selfId, posItem)
end

return odali_yuzhuzhi
