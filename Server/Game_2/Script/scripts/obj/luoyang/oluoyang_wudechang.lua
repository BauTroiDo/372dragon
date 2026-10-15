local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oluoyang_wudechang = class("oluoyang_wudechang", script_base)
oluoyang_wudechang.script_id = 000082
oluoyang_wudechang.g_mpInfo = {}

oluoyang_wudechang.g_mpInfo[0] = {
    "星宿", 16, 96, 152, define.MENPAI_ATTRIBUTE.MATTRIBUTE_XINGXIU
}

oluoyang_wudechang.g_mpInfo[1] = {
    "逍遥", 14, 67, 145, define.MENPAI_ATTRIBUTE.MATTRIBUTE_XIAOYAO
}

oluoyang_wudechang.g_mpInfo[2] = {
    "少林", 9, 96, 127, define.MENPAI_ATTRIBUTE.MATTRIBUTE_SHAOLIN
}

oluoyang_wudechang.g_mpInfo[3] = {
    "天山", 17, 95, 120, define.MENPAI_ATTRIBUTE.MATTRIBUTE_TIANSHAN
}

oluoyang_wudechang.g_mpInfo[4] = {
    "天龙", 13, 96, 120, define.MENPAI_ATTRIBUTE.MATTRIBUTE_DALI
}

oluoyang_wudechang.g_mpInfo[5] = {
    "Nga Mi", 15, 89, 139, define.MENPAI_ATTRIBUTE.MATTRIBUTE_EMEI
}

oluoyang_wudechang.g_mpInfo[6] = {
    "武当", 12, 103, 140, define.MENPAI_ATTRIBUTE.MATTRIBUTE_WUDANG
}

oluoyang_wudechang.g_mpInfo[7] = {
    "明教", 11, 98, 167, define.MENPAI_ATTRIBUTE.MATTRIBUTE_MINGJIAO
}

oluoyang_wudechang.g_mpInfo[8] = {
    "丐帮", 10, 91, 116, define.MENPAI_ATTRIBUTE.MATTRIBUTE_GAIBANG
}

oluoyang_wudechang.g_Yinpiao = 40002000
oluoyang_wudechang.g_Impact_NotTransportList = {5929, 5944}

oluoyang_wudechang.g_TalkInfo_NotTransportList = {
    "#{GodFire_Info_062}", "#{XSHCD_20080418_099}"
}

function oluoyang_wudechang:OnDefaultEvent(selfId, targetId)
    if self:GetItemCount(selfId, self.g_Yinpiao) >= 1 then
        self:BeginEvent(self.script_id)
        self:AddText(
            "  Ngươi đang mang theo Ngân phiếu, đang trong lúc chạy thương! Ta không thể giúp ngươi.")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    local mp
    local i = 0
    self:BeginEvent(self.script_id)
    self:AddText("#{XIYU_20071228_01}")
    self:AddNumText("Trở về Môn phái", 9, 1000)
    self:AddNumText("Thành thị - Tô Châu", 9, 1001)
    self:AddNumText("Thành thị - Tô Châu - Tiệm Thợ rèn", 9, 1007)
    self:AddNumText("Thành thị - Đại Lý", 9, 1002)
    self:AddNumText("Thành thị - Lâu Lan", 9, 1011)
    self:AddNumText("Thành thị - Thúc Hà Cổ Trấn", 9, 1010)
    self:AddNumText("Thành thị - Côn Ngô", 9, -999)
    self:AddNumText("Đưa ta đến Môn phái khác.", 9, 1012)
    self:AddNumText("Ta phải làm sao mới có thể đến Đôn Hoàng và Tung Sơn?", 11, 2000)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oluoyang_wudechang:OnEventRequest(selfId, targetId, arg, index)
    if self:GetTeamId(selfId) >= 0 and self:IsTeamFollow(selfId) and
        self:LuaFnIsTeamLeader(selfId) then
        local num = self:LuaFnGetFollowedMembersCount(selfId)
        local mems = {}

        for i = 0, num do
            mems[i] = self:GetFollowedMember(selfId, i)
            if mems[i] == -1 then return end
            if self:IsHaveMission(mems[i], 4021) then
                self:MsgBox(selfId, targetId,
                            "  Trong đội ngũ của ngươi có người mang theo hàng hóa vận chuyển bằng đường thủy, dịch trạm của chúng ta không thể cung cấp dịch vụ truyền tống cho ngươi.")
                return
            end
        end
    end
    if self:IsHaveMission(selfId, 4021)  then
        self:MsgBox(selfId, targetId,
                    "  Ngươi đang có Khoang hàng vận chuyển, Dịch trạm chúng tôi không thể cung cấp dịch vụ truyền tống cho ngươi.")
        return
    end
    for i, ImpactId in pairs(self.g_Impact_NotTransportList) do
        if self:LuaFnHaveImpactOfSpecificDataIndex(selfId, ImpactId) then
            self:MsgBox(selfId, targetId, self.g_TalkInfo_NotTransportList[i])
            return 0
        end
    end
    local mp
    local i = 0
    local id = self:LuaFnGetMenPai(selfId)
    if index == 1000 then
        if id < 0 or id >= 9 then
            self:MsgBox(selfId, targetId, "  Ngươi còn chưa gia nhập#WMôn phái#Wnào!")
        else
            mp = self:GetMPInfo(id)
            if mp ~= nil then
                self:CallScriptFunction((400900), "TransferFunc", selfId, mp[2],
                                        mp[3], mp[4])
            end
        end
        return
    end
    if index == 1001 then
        self:CallScriptFunction((400900), "TransferFunc", selfId, 1, 204, 256)
        return
    end
    if index == 1007 then
        self:CallScriptFunction((400900), "TransferFunc", selfId, 1, 335, 225)
        return
    end
    if index == 1002 then
        self:CallScriptFunction((400900), "TransferFunc", selfId, 2, 253, 121)
        return
    end
    if index == 1006 then
        self:SetPos(selfId, 234, 132)
        return
    end
    if index == 1011 then
        self:CallScriptFunction((400900), "TransferFunc", selfId, 186, 288, 136,
                                75)
        return
    end
    for i, mp in pairs(self.g_mpInfo) do
        if arg == i then
            self:CallScriptFunction((400900), "TransferFunc", selfId, mp[2],
                                    mp[3], mp[4])
            return
        end
    end
    if index == 1010 then
        self:BeginUICommand()
        self:UICommand_AddInt(self.script_id)
        self:UICommand_AddInt(targetId)
        self:UICommand_AddStr("GotoShuHeGuZhen")
        self:UICommand_AddStr(
            "Thúc Hà Cổ Trấn là cảnh không tăng sát khí, xin hãy chú ý an toàn. Ngươi đã xác nhận muốn tiến vào chưa?")
        self:EndUICommand()
        self:DispatchUICommand(selfId, 24)
        return
    end
    if arg == 1012 then
        self:BeginEvent(self.script_id)
        for i, mp in pairs(self.g_mpInfo) do
            self:AddNumText("Môn phái - " .. mp[1], 9, i)
        end
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if index == 2000 then
        self:BeginEvent(self.script_id)
        self:AddText("#{GOTO_DUNHUANF_SONGSHAN}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
end

function oluoyang_wudechang:GotoShuHeGuZhen(selfId, targetId)
    self:CallScriptFunction((400900), "TransferFunc", selfId, 420, 200, 211, 20)
    return
end

function oluoyang_wudechang:GetMPInfo(mpID)
    local mp
    local i = 0
    for i, mp in pairs(self.g_mpInfo) do if mp[5] == mpID then return mp end end
    return nil
end

function oluoyang_wudechang:MsgBox(selfId, targetId, msg)
    self:BeginEvent(self.script_id)
    self:AddText(msg)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oluoyang_wudechang
