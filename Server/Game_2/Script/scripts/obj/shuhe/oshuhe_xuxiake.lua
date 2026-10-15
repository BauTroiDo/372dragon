local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oshuhe_xuxiake = class("oshuhe_xuxiake", script_base)
oshuhe_xuxiake.script_id = 001171
oshuhe_xuxiake.g_Yinpiao = 40002000
oshuhe_xuxiake.g_Impact_NotTransportList = {5929, 5944}
oshuhe_xuxiake.g_TalkInfo_NotTransportList = {"#{GodFire_Info_062}", "#{XSHCD_20080418_099}"}
oshuhe_xuxiake.g_mpInfo = {}
oshuhe_xuxiake.g_mpInfo[0] = {"星宿", 16, 96, 152, define.MENPAI_ATTRIBUTE.MATTRIBUTE_XINGXIU}
oshuhe_xuxiake.g_mpInfo[1] = {"逍遥", 14, 67, 145, define.MENPAI_ATTRIBUTE.MATTRIBUTE_XIAOYAO}
oshuhe_xuxiake.g_mpInfo[2] = {"少林", 9, 96, 127, define.MENPAI_ATTRIBUTE.MATTRIBUTE_SHAOLIN}
oshuhe_xuxiake.g_mpInfo[3] = {"天山", 17, 95, 120, define.MENPAI_ATTRIBUTE.MATTRIBUTE_TIANSHAN}
oshuhe_xuxiake.g_mpInfo[4] = {"天龙", 13, 96, 120, define.MENPAI_ATTRIBUTE.MATTRIBUTE_DALI}
oshuhe_xuxiake.g_mpInfo[5] = {"Nga Mi", 15, 89, 139, define.MENPAI_ATTRIBUTE.MATTRIBUTE_EMEI}
oshuhe_xuxiake.g_mpInfo[6] = {"武当", 12, 103, 140, define.MENPAI_ATTRIBUTE.MATTRIBUTE_WUDANG}
oshuhe_xuxiake.g_mpInfo[7] = {"明教", 11, 98, 167, define.MENPAI_ATTRIBUTE.MATTRIBUTE_MINGJIAO}
oshuhe_xuxiake.g_mpInfo[8] = {"丐帮", 10, 91, 116, define.MENPAI_ATTRIBUTE.MATTRIBUTE_GAIBANG}
oshuhe_xuxiake.g_MsgInfo = {"#{SHGZ_001}", "#{SHGZ_0620_01}", "#{SHGZ_0620_02}", "#{SHGZ_0620_03}"}

function oshuhe_xuxiake:OnDefaultEvent(selfId, targetId)
    if self:GetItemCount(selfId, self.g_Yinpiao) >= 1 then
        self:BeginEvent(self.script_id)
        self:AddText("  Ngươi đang mang theo Ngân phiếu, đang trong lúc chạy thương! Ta không thể giúp ngươi.")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    self:BeginEvent(self.script_id)
    local msgidx = math.random(#(self.g_MsgInfo))
    self:AddText(self.g_MsgInfo[msgidx])
    self:AddNumText("Trở về Môn phái", 9, 1000)
    self:AddNumText("Thành thị - Lạc Dương", 9, 1001)
    self:AddNumText("Thành thị - Tô Châu", 9, 1002)
    self:AddNumText("Thành thị - Đại Lý", 9, 1003)
    self:AddNumText("Thành thị - Lạc Dương - Cửu ChâuThương hội", 9, 1006)
    self:AddNumText("Thành thị - Tô Châu - Tiệm Thợ rèn", 9, 1007)
    self:AddNumText("Thành thị - Lâu Lan", 9, 1008)
    self:AddNumText("Đưa ta đến Môn phái khác.", 9, 1011)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oshuhe_xuxiake:OnEventRequest(selfId, targetId, arg, index)
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
    for i, ImpactId in pairs(self.g_Impact_NotTransportList) do
        if self:LuaFnHaveImpactOfSpecificDataIndex(selfId, ImpactId) then
            self:MsgBox(selfId, targetId, self.g_TalkInfo_NotTransportList[i])
            return 0
        end
    end
    local id = self:LuaFnGetMenPai(selfId)
    if index == 1000 then
        if id < 0 or id >= 9 then
            self:MsgBox(selfId, targetId, "  Ngươi còn chưa gia nhập#WMôn phái#Wnào!")
        else
            local mp = self:GetMPInfo(id)
            if mp ~= nil then
                self:CallScriptFunction((400900), "TransferFunc", selfId, mp[2], mp[3], mp[4], 10)
            end
        end
        return
    end
    if index == 1001 then
        self:CallScriptFunction((400900), "TransferFunc", selfId, 0, 235, 322, 20)
        return
    end
    if index == 1002 then
        self:CallScriptFunction((400900), "TransferFunc", selfId, 1, 204, 256, 20)
        return
    end
    if index == 1003 then
        self:CallScriptFunction((400900), "TransferFunc", selfId, 2, 253, 121, 20)
        return
    end
    if index == 1006 then
        self:CallScriptFunction((400900), "TransferFunc", selfId, 0, 326, 269, 20)
        return
    end
    if index == 1007 then
        self:CallScriptFunction((400900), "TransferFunc", selfId, 1, 335, 225, 20)
        return
    end
    if index == 1008 then
        self:CallScriptFunction((400900), "TransferFunc", selfId, 186, 288, 136, 75)
        return
    end
    if index == 1011 then
        self:BeginEvent(self.script_id)
        for i, mp in pairs(self.g_mpInfo) do
            self:AddNumText("Môn phái - " .. mp[1], 9, i)
        end
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    for i, mp in pairs(self.g_mpInfo) do
        if index == i then
            self:CallScriptFunction((400900), "TransferFunc", selfId, mp[2], mp[3], mp[4])
            return
        end
    end
end

function oshuhe_xuxiake:MsgBox(selfId, targetId, msg)
    self:BeginEvent(self.script_id)
    self:AddText(msg)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oshuhe_xuxiake:GetMPInfo(mpID)
    for _, mp in pairs(self.g_mpInfo) do
        if mp[5] == mpID then
            return mp
        end
    end
end

return oshuhe_xuxiake
