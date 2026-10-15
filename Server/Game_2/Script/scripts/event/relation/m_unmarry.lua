local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local m_unmarry = class("m_unmarry", script_base)
m_unmarry.script_id = 806005
m_unmarry.g_Unmarry = {}

m_unmarry.g_Unmarry["Id"] = 1001
m_unmarry.g_Unmarry["Name"] = "Ly hôn"
m_unmarry.g_Unmarry["Skills"] = {
    {260, "Kỹ năng Phu Thê cấp 1"},
    {261, "Kỹ năng Phu Thê cấp 2"},
    {262, "Kỹ năng Phu Thê cấp 3"},
    {263, "Kỹ năng Phu Thê cấp 4"},
    {264, "Kỹ năng Phu Thê cấp 5"},
    {265, "Kỹ năng Phu Thê cấp 6"},
    {266, "Kỹ năng Phu Thê cấp 7"},
    {267, "Kỹ năng Phu Thê cấp 8"},
    {268, "Kỹ năng Phu Thê cấp 9"}
}

m_unmarry.g_msg_unm = {}

m_unmarry.g_msg_unm["tem"] = "  Nếu muốn ly hôn, xin hai người nam nữ tổ thành một đội rồi đến tìm ta."
m_unmarry.g_msg_unm["mar"] = "  Hai vị còn chưa kết hôn ư? Vì sao lại muốn ly hôn vậy?"
m_unmarry.g_msg_unm["gld"] = "  Bên nam Yêu cầu mang theo #{_EXCHG55555} mới có thể ly hôn."
m_unmarry.g_msg_unm["ner"] = "  Chỉ khi cả hai người cùng đến bên ta mới có thể ly hôn."
function m_unmarry:OnDefaultEvent(selfId, targetId, index)
    local tId, male, female = self:CheckAccept(selfId, targetId)
    if tId == 0 or male == 0 or female == 0 then
        return 0
    end
    if index == 1 then
        self:OnAccept(male, female)
        self:MessageBox(tId, targetId, "  Đối phương đã chấp nhận thỉnh cầu ly hôn của ngươi.")
        self:BeginUICommand()
        self:UICommand_AddInt(targetId)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 1000)
        return 1
    end
    if index == 2 then
        self:MessageBox(tId, targetId, "  Rất tiếc, đối phương không đồng ý thỉnh cầu của ngươi.")
        self:BeginUICommand()
        self:UICommand_AddInt(targetId)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 1000)
        return 1
    end
    self:OnSubmit(selfId, targetId, tId)
    return 1
end

function m_unmarry:OnEnumerate(caller, selfId, targetId, arg, index)
    if self:LuaFnIsMarried(selfId) then
        caller:AddNumTextWithTarget(self.script_id, self.g_Unmarry["Name"], 6, -1)
    end
end

function m_unmarry:CheckAccept(selfId, targetId)
    if not self:LuaFnHasTeam(selfId) then
        self:MessageBox(selfId, targetId, self.g_msg_unm["tem"])
        return 0
    end
    if self:LuaFnGetTeamSize(selfId) ~= 2 then
        self:MessageBox(selfId, targetId, self.g_msg_unm["tem"])
        return 0
    end
    if self:LuaFnGetTeamSceneMemberCount(selfId) ~= 1 then
        self:MessageBox(selfId, targetId, self.g_msg_unm["tem"])
        return 0
    end
    local selfSex = self:LuaFnGetSex(selfId)
    local tId = self:LuaFnGetTeamSceneMember(selfId, 1)
    local tSex = self:LuaFnGetSex(tId)
    if selfSex == tSex then
        self:MessageBox(selfId, targetId, self.g_msg_unm["mar"])
        return 0
    end
    local male, female
    if selfSex == 1 then
        male = selfId
        female = tId
    else
        male = tId
        female = selfId
    end
    if not self:LuaFnIsSpouses(male, female) then
        self:MessageBox(selfId, targetId, self.g_msg_unm["mar"])
        return 0
    end
    if not self:LuaFnIsCanDoScriptLogic(male) then
        return 0
    end
    if not self:LuaFnIsCanDoScriptLogic(female) then
        return 0
    end
    local nMoneyJZ = self:GetMoneyJZ(male)
    local nMoneyJB = self:LuaFnGetMoney(male)
    local nMoneySelf = nMoneyJZ + nMoneyJB
    if nMoneySelf < 55555 then
        self:MessageBox(selfId, targetId, self.g_msg_unm["gld"])
        return 0
    end
    if not self:IsInDist(selfId, tId, 10) then
        self:MessageBox(selfId, targetId, self.g_msg_unm["ner"])
        return 0
    end
    return tId
end

function m_unmarry:OnSubmit(selfId, targetId, tId)
    local selfName = self:LuaFnGetName(selfId)
    self:BeginEvent(self.script_id)
    self:AddText("  Đợi đối phương trả lời...#r Sau khi ly hôn, độ hữu hảo của cả hai vợ chồng sẽ giảm xuống 10, đồng thời các Kỹ năng phu thê đã học sẽ bị xóa toàn bộ.#r Chú ý, ly hôn Yêu cầu nam nhân tốn #{_EXCHG55555}")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Ngươi có đồng ý cùng" .. selfName .. "ly hôn không? Sau khi ly hôn, độ hữu hảo của cả hai vợ chồng sẽ giảm xuống 10, đồng thời các Kỹ năng phu thê đã học sẽ bị xóa toàn bộ.#r Chú ý, ly hôn Yêu cầu nam nhân tốn #{_EXCHG55555}")
    self:AddNumText("là", 6, 1)
    self:AddNumText("không", 8, 2)
    self:EndEvent()
    self:DispatchEventList(tId, targetId)
end

function m_unmarry:OnAccept(male, female)
    self:LuaFnCostMoneyWithPriority(male, 55555)
    self:LuaFnSetFriendPoint(male, female, 10)
    self:LuaFnSetFriendPoint(female, male, 10)
    self:LuaFnAwardSpouseTitle(female, "")
    self:DispatchAllTitle(female)
    self:LuaFnAwardSpouseTitle(male, "")
    self:DispatchAllTitle(male)
    self:Msg2Player(male, "Ngươi đã trở lại độc thân rồi.", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
    self:Msg2Player(male, "Mất danh hiệu phu thê.", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
    self:Msg2Player(male, "Mất tất cả Kỹ năng phu thê.", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
    self:Msg2Player(female, "Ngươi đã trở lại độc thân rồi.", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
    self:Msg2Player(female, "Mất danh hiệu phu thê.", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
    self:Msg2Player(female, "Mất tất cả Kỹ năng phu thê.", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
    for _, skillId in pairs(self.g_Unmarry["Skills"]) do
        self:DelSkill(male, skillId[1])
        self:DelSkill(female, skillId[1])
    end
    local NewSkill = {250, 251, 252, 253, 254, 255, 256, 257, 258, 259}
    for _, skillId in pairs(NewSkill) do
        self:DelSkill(male, skillId)
        self:DelSkill(female, skillId)
    end
    for _, skillId in pairs({269, 270, 271, 272, 273}) do
        self:DelSkill(male, skillId)
        self:DelSkill(female, skillId)
    end
    self:CallScriptFunction(250036, "OnAbandon", male)
    self:CallScriptFunction(250037, "OnAbandon", male)
    self:CallScriptFunction(250036, "OnAbandon", female)
    self:CallScriptFunction(250037, "OnAbandon", female)
    self:SetMissionData(male, ScriptGlobal.MD_TW_REEXPERIENCE_WEDDING_TOTAL_COUNT, 0)
    self:SetMissionData(female, ScriptGlobal.MD_TW_REEXPERIENCE_WEDDING_TOTAL_COUNT, 0)
    self:LuaFnUnMarry(male, female)
end

function m_unmarry:MessageBox(selfId, targetId, msg)
    self:BeginEvent(self.script_id)
    self:AddText(msg)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return m_unmarry
