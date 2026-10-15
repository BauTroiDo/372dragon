local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oluoyang_guanhanshou = class("oluoyang_guanhanshou", script_base)
oluoyang_guanhanshou.script_id = 125
oluoyang_guanhanshou.g_Key = {
    ["do"] = 100,
    ["undo"] = 101,
    ["del"] = 103,
    ["hlp"] = 104
}

function oluoyang_guanhanshou:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText(
        "  Ta chuyên chủ trì nghi thức rửa tay gác kiếm cho các bậc anh hùng trong giang hồ. Nếu ngươi muốn xóa nhân vật, lui khỏi giang hồ, có thể đến tìm ta.")
    self:AddNumText("Ta muốn xóa nhân vật", -1, self.g_Key["do"])
    self:AddNumText("Về việc xóa nhân vật", 11, self.g_Key["hlp"])
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oluoyang_guanhanshou:OnEventRequest(selfId, targetId, arg, index)
    local key = index
    if key == self.g_Key["do"] then
        self:BeginEvent(self.script_id)
        if 9 == 9 then
            self:AddText(
                "  Vì công bằng của game, tạm không mở xóa nhân vật.")
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
            return
        end
        local result = self:QueryDeleteCharState(selfId)
        if result == 1 then
            self:AddText("  Rửa tay gác kiếm, lui khỏi giang hồ.")
            self:AddNumText("Ta quyết định lui khỏi giang hồ", 6, self.g_Key["del"])
        end
        if result == 2 then
            self:AddText("  Ngươi vẫn còn ở trong bang hội, không thể thoái ẩn giang hồ.")
        end
        if result == 3 then
            self:AddText("  Ngươi vẫn còn trong Trạng thái kết hôn, không thể thoái ẩn giang hồ.")
        end
        if result == 4 then
            self:AddText("  Ngươi có vật phẩm đã bị khóa, không thể thoái ẩn giang hồ.")
        end
        if result == 5 then
            self:AddText("  Ngươi sở hữu cửa hàng người chơi, không thể thoái ẩn giang hồ.")
        end
        if result == 6 then
            self:AddText("  Ngươi sở hữu huynh đệ kết nghĩa, không thể thoái ẩn giang hồ.")
        end
        if result == 7 then
            self:AddText("  Ngươi sở hữu quan hệ sư đồ, không thể thoái ẩn giang hồ.")
        end
        if result == 8 then
            local lefttime = self:GetLeftDeleteTime(selfId) - 11
            if lefttime > 0 then
                self:AddText("  Thời gian ngươi cáo lão giang hồ còn chưa tới, còn thiếu." ..
                                 lefttime .. "Trời.")
            else
                self:AddText("  Ngươi còn chưa đăng ký cáo lão giang hồ!")
            end
        end
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif key == self.g_Key["del"] then
        self:OpenClientAcceptUI(selfId, targetId, arg)
    elseif key == self.g_Key["hlp"] then
        self:BeginEvent(self.script_id)
        self:AddText("#{function_help_089}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
end

function oluoyang_guanhanshou:OpenClientAcceptUI(selfId, targetId, eventId)
    self:BeginUICommand()
    self:UICommand_AddInt(self.script_id)
    self:UICommand_AddInt(targetId)
    self:UICommand_AddInt(eventId)
    self:UICommand_AddStr("OnMsgAccept")
    local str = string.format("Ngươi có chắc chắn muốn xóa bỏ nhân vật này không?")
    self:UICommand_AddStr(str)
    self:EndUICommand()
    self:DispatchUICommand(selfId, 24)
end

function oluoyang_guanhanshou:OnMsgAccept(selfId, targetId, eventId)
    local result = self:QueryDeleteCharState(selfId)
    if (1 == result) then self:ExecuteDeleteChar(selfId) end
end

return oluoyang_guanhanshou
