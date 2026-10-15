local class = require "class"
local define = require "define"
local script_base = require "script_base"
local opetisland_guijia = class("opetisland_guijia", script_base)
opetisland_guijia.script_id = 112001
opetisland_guijia.g_mpInfo = {}
opetisland_guijia.g_mpInfo[0] = {"星宿", 16, 96, 152, define.MENPAI_ATTRIBUTE.MATTRIBUTE_XINGXIU}
opetisland_guijia.g_mpInfo[1] = {"逍遥", 14, 67, 145, define.MENPAI_ATTRIBUTE.MATTRIBUTE_XIAOYAO}
opetisland_guijia.g_mpInfo[2] = {"少林", 9, 96, 127, define.MENPAI_ATTRIBUTE.MATTRIBUTE_SHAOLIN}
opetisland_guijia.g_mpInfo[3] = {"天山", 17, 95, 120, define.MENPAI_ATTRIBUTE.MATTRIBUTE_TIANSHAN}
opetisland_guijia.g_mpInfo[4] = {"天龙", 13, 96, 120, define.MENPAI_ATTRIBUTE.MATTRIBUTE_DALI}
opetisland_guijia.g_mpInfo[5] = {"Nga Mi", 15, 89, 139, define.MENPAI_ATTRIBUTE.MATTRIBUTE_EMEI}
opetisland_guijia.g_mpInfo[6] = {"武当", 12, 103, 140, define.MENPAI_ATTRIBUTE.MATTRIBUTE_WUDANG}
opetisland_guijia.g_mpInfo[7] = {"明教", 11, 98, 167, define.MENPAI_ATTRIBUTE.MATTRIBUTE_MINGJIAO}
opetisland_guijia.g_mpInfo[8] = {"丐帮", 10, 91, 116, define.MENPAI_ATTRIBUTE.MATTRIBUTE_GAIBANG}
opetisland_guijia.g_mpInfo[10] = { "曼陀山庄", 184, 139, 162, define.MENPAI_ATTRIBUTE.MATTRIBUTE_MANTUOSHANZHUANG}
opetisland_guijia.g_mpInfo[11] = { "恶人谷", 987, 125, 152, define.MENPAI_ATTRIBUTE.MATTRIBUTE_ERENGU}
opetisland_guijia.g_mpInfo[12] = { "慕容山庄", 1358, 28, 133, define.MENPAI_ATTRIBUTE.MATTRIBUTE_GUSU}
opetisland_guijia.g_Yinpiao = 40002000
function opetisland_guijia:OnDefaultEvent(selfId, targetId)
    if self:GetItemCount(selfId, self.g_Yinpiao) >= 1 then
        self:BeginEvent(self.script_id)
        self:AddText("  Ngươi đang mang theo Ngân phiếu, đang trong lúc chạy thương! Ta không thể giúp ngươi.")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    self:BeginEvent(self.script_id)
    self:AddText("    Hoan nghênh đến Huyền Vũ Đảo!")
    self:AddNumText("Trở về Môn phái", 9, 1000)
    self:AddNumText("Thành thị - Lạc Dương", 9, 1003)
    self:AddNumText("Thành thị - Tô Châu", 9, 1001)
    self:AddNumText("Thành thị - Đại Lý", 9, 1002)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function opetisland_guijia:OnEventRequest(selfId, targetId, arg, index)
    if self:GetTeamId(selfId) >= 0 and self:IsTeamFollow(selfId) and self:LuaFnIsTeamLeader(selfId) then
        local num = self:LuaFnGetFollowedMembersCount(selfId)
        local mems = {}
        for i = 1, num do
            mems[i] = self:GetFollowedMember(selfId, i)
            if mems[i] == -1 then
                return
            end
            if self:IsHaveMission(mems[i], 4021) then
                self:MsgBox(selfId, targetId, "  Trong đội ngũ của ngươi có người mang theo hàng hóa vận chuyển bằng đường thủy, dịch trạm của chúng ta không thể cung cấp dịch vụ truyền tống cho ngươi.")
                return
            end
        end
    end
    if self:IsHaveMission(selfId, 4021) then
        self:MsgBox(selfId, targetId, "  Ngươi đang có Khoang hàng vận chuyển, Dịch trạm chúng tôi không thể cung cấp dịch vụ truyền tống cho ngươi.")
        return
    end
    local id = self:LuaFnGetMenPai(selfId)
    if index == 1000 then
        if id < 0 or id == 9 or id > 10 then
            self:MsgBox(selfId, targetId, "  Ngươi còn chưa gia nhập#WMôn phái#Wnào!")
        else
            local mp = self:GetMPInfo(id)
            if mp ~= nil then
                self:CallScriptFunction((400900), "TransferFunc", selfId, mp[2], mp[3], mp[4])
            end
        end
        return
    end
    if index == 1001 then
        self:CallScriptFunction((400900), "TransferFunc", selfId, 1, 177, 240)
        return
    end
    if index == 1002 then
        self:CallScriptFunction((400900), "TransferFunc", selfId, 2, 253, 125)
        return
    end
    if index == 1003 then
        self:CallScriptFunction((400900), "TransferFunc", selfId, 0, 278, 301)
        return
    end
    for i, mp in pairs(self.g_mpInfo) do
        if index == i then
            self:CallScriptFunction((400900), "TransferFunc", selfId, mp[2], mp[3], mp[4])
            return
        end
    end
    if index == 2000 then
        self:BeginEvent(self.script_id)
        self:AddText("#{GOTO_DUNHUANF_SONGSHAN}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
end

function opetisland_guijia:GetMPInfo(mpID)
    for _, mp in pairs(self.g_mpInfo) do
        if mp[5] == mpID then
            return mp
        end
    end
    return nil
end

function opetisland_guijia:MsgBox(selfId, targetId, msg)
    self:BeginEvent(self.script_id)
    self:AddText(msg)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return opetisland_guijia
