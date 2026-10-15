local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local p_expelprentice = class("p_expelprentice", script_base)
p_expelprentice.script_id = 806009
p_expelprentice.g_ExpelPrentice = {}

p_expelprentice.g_ExpelPrentice["Id"] = 1006
p_expelprentice.g_ExpelPrentice["Name"] = "Ta muốn trục xuất đồ đệ khỏi sư môn"
p_expelprentice.g_msg = {["gld"] = "  Trục xuất đồ đệ Yêu cầu nộp #{_EXCHG%d}.", ["con"] = "  Khai trừ đồ đệ sẽ bị khấu trừ #{_EXCHG%d}, có chắc muốn khai trừ người chơi: %s không."}

p_expelprentice.g_Gold = 25000
function p_expelprentice:OnDefaultEvent(selfId, targetId, index)
    local key = index
    local guid
    local PrenticeName
    local log = 0
    local str
    if key == -1 then
        self:BeginEvent(self.script_id)
        for i = 1, 8 do
            guid = self:LuaFnGetPrenticeGUID(selfId, i)
            if guid ~= -1 then
                log = 1
                PrenticeName = self:LuaFnGetFriendName(selfId, guid)
                self:AddNumText("Tướng" .. PrenticeName .. "Trục Xuất Sư Môn", 6, i)
            end
        end
        if log == 0 then
            self:AddText("  Ngươi vẫn chưa có đệ tử!")
        end
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    end
    if key >= 1 and key <= 8 then
        guid = self:LuaFnGetPrenticeGUID(selfId, key)
        if guid ~= -1 then
            PrenticeName = self:LuaFnGetFriendName(selfId, guid)
        end
        str = string.format(self.g_msg["con"], self.g_Gold, PrenticeName)
        self:BeginEvent(self.script_id)
        self:AddText(str)
        self:AddNumText("là", 6, (key + 1) * 100)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    end
    if key >= 100 then
        if self:CheckAccept(selfId, targetId) > 0 then
            self:OnAccept(selfId, targetId, math.floor(key / 100) - 1)
        end
    end
end

function p_expelprentice:OnEnumerate(caller)
    caller:AddNumTextWithTarget(self.script_id, self.g_ExpelPrentice["Name"], 6, -1)
end

function p_expelprentice:CheckAccept(selfId, targetId)
    local nMoneyJZ = self:GetMoneyJZ(selfId)
    local nMoneyJB = self:LuaFnGetMoney(selfId)
    local nMoneySelf = nMoneyJZ + nMoneyJB
    if nMoneySelf < self.g_Gold then
        local str = string.format(self.g_msg["gld"], self.g_Gold)
        self:MsgBox(selfId, targetId, str)
        return 0
    end
    return 1
end

function p_expelprentice:OnAccept(selfId, targetId, nIndex)
    local PrenticeGUID = self:LuaFnGetPrenticeGUID(selfId, nIndex)
    if PrenticeGUID == -1 then
        self:BeginEvent(self.script_id)
        self:AddText("  Ngươi vẫn chưa có đệ tử!")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    local PrenticeName = self:LuaFnGetFriendName(selfId, PrenticeGUID)
    local selfName = self:LuaFnGetName(selfId)
    local nMoneyJZ, nMoneyJB = self:LuaFnCostMoneyWithPriority(selfId, self.g_Gold)
    if nMoneyJZ == 0 then
        local str = string.format("Giải trừ sư đồ quan hệ, khấu trừ #{_MONEY%d}.", self.g_Gold)
        self:Msg2Player(selfId, str, define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
    end
    if nMoneyJB == 0 then
        local str = string.format("Giải trừ sư đồ quan hệ, khấu trừ #{_EXCHG%d}.", self.g_Gold)
        self:Msg2Player(selfId, str, define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
    end
    if nMoneyJB ~= 0 and nMoneyJZ ~= 0 then
        local str = string.format("Giải trừ quan hệ sư đồ, khấu trừ #{_EXCHG%d} và #{_MONEY%d}.", nMoneyJZ, nMoneyJB)
        self:Msg2Player(selfId, str, define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
    end
    self:MsgBox(selfId, targetId, "  Ngươi đã giải trừ cùng" .. PrenticeName .. "của sư đồ quan hệ.")
    self:LuaFnSendSystemMail(PrenticeName, "Ngươi của sư phụ" .. selfName .. "Vô ý tiếp tục chỉ dạy ngươi, đã đoạn tuyệt quan hệ sư đồ với ngươi.")
    self:LuaFnSendScriptMail(PrenticeName, ScriptGlobal.MAIL_EXPELPRENTICE, 0, 0, 0)
    self:LuaFnExpelPrentice(selfId, PrenticeGUID)
end

function p_expelprentice:MsgBox(selfId, targetId, msg)
    self:BeginEvent(self.script_id)
    self:AddText(msg)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return p_expelprentice
