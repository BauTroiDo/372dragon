local class = require "class"
local define = require "define"
local script_base = require "script_base"
local p_finishappr = class("p_finishappr", script_base)
p_finishappr.script_id = 806007
p_finishappr.g_FinishAppr = {}

p_finishappr.g_FinishAppr["Id"] = 1004
p_finishappr.g_FinishAppr["Name"] = "Ta dẫn theo đồ đệ đến xuất sư."
p_finishappr.g_msg = {}

p_finishappr.g_msg["tem"] = "  Yêu cầu sư đồ 2 người tổ đội đến tìm ta mới có thể xuất sư."
p_finishappr.g_msg["ner"] = "  Chỉ khi cả 2 người đều đến bên ta mới có thể xuất sư."
p_finishappr.g_msg["lev"] = "  Đồ đệ Cấp độ đạt đến cấp 40 mới có thể xuất sư."
p_finishappr.g_msg["dad"] = "  Ngươi vẫn chưa thu đồ đệ."
p_finishappr.g_msg["itm"] = "  Trong túi mỗi người sư đồ, phải có ít nhất một ô trống vật phẩm thường."
p_finishappr.g_itm = {30008001, "Kẹo Đậu Xuất Sư"}

function p_finishappr:OnDefaultEvent(selfId, targetId)
    local tId = self:CheckAccept(selfId, targetId)
    if tId == 0 then
        return
    end
    self:OnAccept(selfId, targetId, tId)
end

function p_finishappr:OnEnumerate(caller)
    caller:AddNumTextWithTarget(self.script_id, self.g_FinishAppr["Name"], 6, -1)
end

function p_finishappr:CheckAccept(selfId, targetId)
    if not self:LuaFnHasTeam(selfId) or self:LuaFnGetTeamSize(selfId) ~= 2 then
        self:MsgBox(selfId, targetId, self.g_msg["tem"])
        return 0
    end
    if self:LuaFnGetTeamSceneMemberCount(selfId) ~= 1 then
        self:MsgBox(selfId, targetId, self.g_msg["ner"])
        return 0
    end
    local tId = self:LuaFnGetTeamSceneMember(selfId, 1)
    if not self:LuaFnIsCanDoScriptLogic(selfId) or not self:LuaFnIsCanDoScriptLogic(tId) then
        return 0
    end
    if self:LuaFnGetLevel(tId) < 40 then
        self:MsgBox(selfId, targetId, self.g_msg["lev"])
        return 0
    end
    if not self:LuaFnIsPrentice(selfId, tId) then
        self:MsgBox(selfId, targetId, self.g_msg["dad"])
        return 0
    end
    self:LuaFnBeginAddItem()
    self:LuaFnAddItem(self.g_itm[1], 1)
    if not self:LuaFnEndAddItem(selfId) or not self:LuaFnEndAddItem(tId) then
        self:MsgBox(selfId, targetId, self.g_msg["itm"])
        return 0
    end
    return tId
end

function p_finishappr:OnAccept(selfId, targetId, tId)
    local fp_st = self:LuaFnGetFriendPoint(selfId, tId)
    local fp_ts = self:LuaFnGetFriendPoint(tId, selfId)
    local lv_t = self:LuaFnGetLevel(tId)
    if lv_t >= 40 and lv_t <= 45 and fp_st >= 300 and fp_ts >= 300 then
        self:MsgBox(selfId, targetId, "  Xuất sư thành công!")
        self:Msg2Player(selfId, "Xuất sư thành công!", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
        self:Msg2Player(selfId, "Ngươi nhận được" .. self.g_itm[2] .. "Một.", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
        self:MsgBox(tId, targetId, "  Xuất sư thành công!")
        self:Msg2Player(tId, "Xuất sư thành công!", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
        self:Msg2Player(tId, "Ngươi nhận được" .. self.g_itm[2] .. "Một.", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
        local title
        local MasterName = self:LuaFnGetName(selfId)
        title = MasterName .. "Chi đồ"
        self:AwardShiTuTitle(tId, title)
        self:DispatchAllTitle(tId)
        self:Msg2Player(tId, "Nhận đượcdanh hiệu:" .. title .. "。", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
    else
        local msg = "Do độ hữu hảo không đạt 300 hoặc Cấp độ đồ đệ lớn hơn 45, không có phần thưởng."
        self:MsgBox(selfId, targetId, "  Xuất sư thành công!" .. msg)
        self:Msg2Player(selfId, "Xuất sư thành công!", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
        self:Msg2Player(selfId, msg, define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
        self:MsgBox(tId, targetId, "  Xuất sư thành công!" .. msg)
        self:Msg2Player(tId, "Xuất sư thành công!", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
        self:Msg2Player(tId, msg, define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
    end
    self:LuaFnFinishAprentice(tId, selfId)
end

function p_finishappr:GetTitle(MoralPoint)
    return ""
end

function p_finishappr:MsgBox(selfId, targetId, msg)
    self:BeginEvent(self.script_id)
    self:AddText(msg)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return p_finishappr
