local class = require "class"
--local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local b_disengage = class("b_disengage", script_base)
b_disengage.script_id = 806000
b_disengage.g_msg_swear = {}

b_disengage.g_msg_swear["uns"] = "Giải trừ kết bái"
b_disengage.g_msg_swear["cas"] = " Chưa từng kết bái, nên không thể giải trừ quan hệ kết bái."
b_disengage.g_msg_swear["unc"] = " Sau khi giải trừ quan hệ kết bái, hảo hữu độ với người chơi kết bái của ngươi sẽ giảm xuống 500, có muốn giải trừ quan hệ kết bái không?"
b_disengage.g_key = {}

b_disengage.g_key["uns"] = 10000
b_disengage.g_key["all"] = 20000
b_disengage.g_key["una"] = 30000
function b_disengage:OnEnumerate(caller)
    caller:AddNumTextWithTarget(self.script_id, self.g_msg_swear["uns"], 6, self.g_key["uns"])
end

function b_disengage:OnDefaultEvent(selfId, targetId, index)
    local key = index
    if key == self.g_key["uns"] then
        if self:CheckAccept(selfId, targetId) == 0 then
            return 0
        end
        self:OnSubmit(selfId, targetId)
        return 1
    end
    if key == self.g_key["all"] then
        self:DoUnswear(selfId, targetId)
        self:BeginUICommand()
        self:UICommand_AddInt(targetId)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 1000)
        return 1
    end
    if key == self.g_key["una"] then
        self:BeginUICommand()
        self:UICommand_AddInt(targetId)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 1000)
        return 1
    end
end

function b_disengage:CheckAccept(selfId, targetId)
    local BrotherNum = self:LuaFnIsSweared(selfId)
    if BrotherNum == 0 then
        self:MessageBox(selfId, targetId, self.g_msg_swear["cas"])
        return 0
    end
end

function b_disengage:OnSubmit(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText(self.g_msg_swear["unc"])
    self:AddNumText("Xác nhận", 6, self.g_key["all"])
    self:AddNumText("Hủy bỏ", 8, self.g_key["una"])
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function b_disengage:MessageBox(selfId, targetId, msg)
    self:BeginEvent(self.script_id)
    self:AddText(msg)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function b_disengage:DoUnswear(selfId)
    local BrotherNum = self:LuaFnIsSweared(selfId)
    local selfName = self:LuaFnGetName(selfId)
    local selfGuid = self:LuaFnGetGUID(selfId)
    local AllDismiss = 0
    if BrotherNum == 1 then
        AllDismiss = 1
    end
    self:AwardJieBaiTitle(selfId, "")
    self:DispatchAllTitle(selfId)
    local BrotherGuid = {}
    for i = 1, BrotherNum do
        BrotherGuid[i] = self:LuaFnGetBrotherGuid(selfId, i)
    end
    for i = 1, BrotherNum do
        local theGUID = BrotherGuid[i]
        if theGUID then
            local FriendPoint = self:LuaFnGetFriendPointByGUID(selfId, theGUID)
            if FriendPoint > 500 then
                self:LuaFnSetFriendPointByGUID(selfId, theGUID, 500)
            end
            self:LuaFnUnswear(selfId, theGUID)
            local FriendName = self:LuaFnGetFriendName(selfId, theGUID)
            self:LuaFnSendSystemMail(FriendName, selfName .. "Đã giải trừ quan hệ kết nghĩa với bạn.")
            self:LuaFnSendScriptMail(FriendName, ScriptGlobal.MAIL_UNSWEAR, selfGuid, AllDismiss, 0)
        end
    end
end

return b_disengage
