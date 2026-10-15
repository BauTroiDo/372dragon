local class = require "class"
local define = require "define"
local script_base = require "script_base"
local osuzhou_chargetransfer = class("osuzhou_chargetransfer", script_base)
osuzhou_chargetransfer.script_id = 1087
osuzhou_chargetransfer.g_name = "车传安"
osuzhou_chargetransfer.g_transfer_target = {
    [1] = {["x"] = 120, ["z"] = 200, ["scene_num"] = 0},
    [2] = {["x"] = 246, ["z"] = 106, ["scene_num"] = 2},
    [3] = {["x"] = 294, ["z"] = 90, ["scene_num"] = 186},
    [4] = {["x"] = 206, ["z"] = 266, ["scene_num"] = 34},
    [5] = {["x"] = 186, ["z"] = 43, ["scene_num"] = 28},
    [6] = {["x"] = 158, ["z"] = 113, ["scene_num"] = 22}
}

osuzhou_chargetransfer.g_transfer_cost = 5000
function osuzhou_chargetransfer:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function osuzhou_chargetransfer:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{SFCS_80828_01}")
    self:AddNumText("Lạc Dương", 9, 1)
    self:AddNumText("Đại Lý", 9, 2)
    self:AddNumText("Lâu Lan", 9, 3)
    self:AddNumText("Nam Hải", 9, 4)
    self:AddNumText("Nam Chiếu", 9, 5)
    self:AddNumText("Trường Bạch Sơn", 9, 6)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function osuzhou_chargetransfer:OnEventRequest(selfId, targetId, arg, index)
    if self:GetItemCount(selfId, 40002000) >= 1 then
        self:BeginEvent(self.script_id)
        self:AddText("  Ngươi đang mang theo Ngân phiếu, đang trong lúc chạy thương! Ta không thể giúp ngươi.")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if self:GetTeamId(selfId) >= 0 and self:IsTeamFollow(selfId) and self:LuaFnIsTeamLeader(selfId) then
        self:BeginEvent(self.script_id)
        self:AddText("  Thành thật xin lỗi, vì đường xá quá xa xôi, năng lực vận chuyển của chúng tôi có hạn, nên không chấp nhận truyền tống tổ đội, xin ngài rời khỏi đội và đến một mình!")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if self:IsHaveMission(selfId, 4021)  then
        self:BeginEvent(self.script_id)
        self:AddText("  Ngươi đang có Khoang hàng vận chuyển, Dịch trạm chúng tôi không thể cung cấp dịch vụ truyền tống cho ngươi.")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    local id = index
    if id >= 1 and id <= 6 then
        self:BeginEvent(self.script_id)
        self:AddText("#{FFCS_081210_1}")
        if id == 1 then
            self:AddNumText("Xác nhận", 0, 11)
        elseif id == 2 then
            self:AddNumText("Xác nhận", 0, 21)
        elseif id == 3 then
            self:AddNumText("Xác nhận", 0, 31)
        elseif id == 4 then
            self:AddNumText("Xác nhận", 0, 41)
        elseif id == 5 then
            self:AddNumText("Xác nhận", 0, 51)
        elseif id == 6 then
            self:AddNumText("Xác nhận", 0, 61)
        end
        self:AddNumText("Hủy bỏ", 0, 100)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif id == 100 then
        self:BeginUICommand()
        self:UICommand_AddInt(targetId)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 1000)
    else
        local index = id // 10
        if index == 3 then
            if self:GetLevel(selfId) < 75 then
                self:BeginEvent(self.script_id)
                self:AddText("  Ngươi Cấp độ không đến 75, không thể truyền tống.")
                self:EndEvent()
                self:DispatchEventList(selfId, targetId)
                return
            end
            if self:LuaFnGetDRideFlag(selfId)  then
                local objId = self:LuaFnGetDRideTargetID(selfId)
                if objId ~= -1 and self:GetLevel(objId) < 75 then
                    self:BeginEvent(self.script_id)
                    self:AddText("#{SRCS_090203_1}")
                    self:EndEvent()
                    self:DispatchEventList(selfId, targetId)
                    return
                end
            end
        end
        local minLevel = 10
        if index == 3 then
            minLevel = 75
        end
        if self:LuaFnGetDRideFlag(selfId)  then
            local objId = self:LuaFnGetDRideTargetID(selfId)
            if objId ~= -1 and self:GetLevel(objId) < minLevel then
                local Tip = string.format("#{CQTS_90227_1}%d#{CQTS_90227_2}", minLevel)
                self:NotifyFailTips(selfId, targetId, Tip)
                return
            end
        end
        local pos_x = self.g_transfer_target[index]["x"]
        local pos_z = self.g_transfer_target[index]["z"]
        local scene_num = self.g_transfer_target[index]["scene_num"]
        local nMoneyJZ = self:GetMoneyJZ(selfId)
        local nMoney = self:GetMoney(selfId)
        if (nMoneyJZ + nMoney) >= self.g_transfer_cost then
            if not self:LuaFnCostMoneyWithPriority(selfId, self.g_transfer_cost) then
                self:BeginEvent(self.script_id)
                self:AddText("Thu phí thất bại!")
                self:EndEvent()
                self:DispatchMissionTips(selfId)
                return
            else
                self:CallScriptFunction((400900), "TransferFunc", selfId, scene_num, pos_x, pos_z, minLevel)
            end
        else
            self:BeginEvent(self.script_id)
            self:AddText("Kim tiền không đủ")
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
            return
        end
    end
end

function osuzhou_chargetransfer:NotifyFailTips(selfId, targetId, Tip)
    self:BeginEvent(self.script_id)
    self:AddText(Tip)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return osuzhou_chargetransfer
