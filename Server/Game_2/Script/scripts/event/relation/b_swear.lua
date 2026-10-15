local gbk = require "wire_charset"
local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local b_swear = class("b_swear", script_base)
b_swear.script_id = 806001
b_swear.g_NeedMoney = 100000
b_swear.g_DrawTitleNeedMoney = 50000
b_swear.g_ChangeTitleNeedMoney = 10000
b_swear.g_msg_swear = {}

b_swear.g_msg_swear["swr"] = "Kết nghĩa"
b_swear.g_msg_swear["tit"] = "Lĩnh danh hiệu"
b_swear.g_msg_swear["chr"] = "Sửa đổi Cá nhândanh hiệu."
b_swear.g_msg_swear["tem"] = " Ngươi Yêu cầu cùng người muốn kết nghĩa tổ đội đến tìm ta, ta mới có thể chủ trì nghi thức kết nghĩa cho các ngươi."
b_swear.g_msg_swear["ten"] = " Trong đội của các hạ có người không ở Lạc Dương, nên ta không thể chủ trì nghi thức kết bái cho các hạ được."
b_swear.g_msg_swear["cap"] = " Chỉ có đội trưởng mới có thể hoàn thành thao tác kết bái."
b_swear.g_msg_swear["mar"] = " Giữa phu thê không thể kết nghĩa. Hai vị vẫn nên trở về trước đi."
b_swear.g_msg_swear["mat"] = " Sư đồ không thể kết nghĩa. Các vị hãy trở về trước đi."
b_swear.g_msg_swear["fri"] = " Chỉ có hảo hữu mới có thể kết nghĩa. Các vị Yêu cầu phải bồi đắp thêm tình bằng hữu mới được."
b_swear.g_msg_swear["all"] = " Tất cả huynh đệ kết nghĩa phải cùng ở trong đội ngũ thì mới có thể kết nạp thêm huynh đệ kết nghĩa mới."
b_swear.g_msg_swear["one"] = " Các ngươi đã là huynh đệ kết nghĩa, không Yêu cầu kết nghĩa thêm lần nữa để gia tăng hữu nghị."
b_swear.g_msg_swear["alr"] = " Thành viên A trong đội ngũ của ngài đã kết nghĩa rồi, nên ta không thể làm lễ kết nghĩa cho các vị."
b_swear.g_msg_swear["frd"] = " Nếu các vị muốn kết nghĩa, ta có thể làm chủ trì nghi lễ kết nghĩa, soạn Kim Lan Phổ. Nhưng trước đó, ta phải xác nhận mức độ thân hữu giữa các vị đã đạt 1000 điểm."
b_swear.g_msg_swear["mon"] = " Tiến hành nghi lễ kết nghĩa Yêu cầu tốn #{_EXCHG%d}, các vị có chắc chắn muốn kết nghĩa không?"
b_swear.g_msg_swear["nom"] = " Tiền bạc trên người ngài không đủ #{_EXCHG%d}."
b_swear.g_msg_swear["con"] = " Huynh đệ kết nghĩa, từ nay về sau có phúc cùng hưởng, có họa cùng đương. Các vị thật sự muốn kết nghĩa chứ?"
b_swear.g_msg_swear["chn"] = " Đội ngũ của các vị đã có thay đổi, nên ta không thể làm chủ trì nghi lễ kết nghĩa cho các vị."
b_swear.g_msg_swear["bul"] = " Hoàng thiên tại thượng, Hậu thổ tại hạ! Các ngươi hôm nay kết bái làm huynh đệ, sau này có phúc cùng hưởng, có nạn cùng đương! Không cầu cùng năm cùng tháng cùng ngày sinh, chỉ cầu cùng năm cùng tháng cùng ngày chết! Thiên hạ anh hùng, chúc mừng cho họ đi!"
b_swear.g_msg_swear["pro"] = " Chúc mừng chư vị, các ngươi đã trở thành huynh đệ kết nghĩa, xin đội trưởng của các ngươi đến lĩnh danh hiệu kết nghĩa."
b_swear.g_msg_swear["caa"] = " Phải tổ đội cùng tất cả huynh đệ kết nghĩa của ngươi, mới có thể lĩnh danh hiệu kết nghĩa."
b_swear.g_msg_swear["cac"] = " Chỉ có đội trưởng mới có thể lĩnh danh hiệu cho huynh đệ kết nghĩa."
b_swear.g_msg_swear["cas"] = " Ngươi chưa kết nghĩa, không thể lĩnh danh hiệu kết nghĩa."
b_swear.g_msg_swear["cab"] = " Trong đội của ngươi có người không phải huynh đệ kết nghĩa của ngươi."
b_swear.g_msg_swear["cat"] = " Ngươi đã lĩnh danh hiệu kết nghĩa rồi."
b_swear.g_msg_swear["can"] = " Ngươi chưa lĩnh danh hiệu kết nghĩa, còn chưa thể sửa danh hiệu kết nghĩa."
b_swear.g_msg_swear["ccs"] = " Ngươi chưa kết nghĩa, không thể sửa danh hiệu kết nghĩa."
b_swear.g_msg_swear["nmm"] = " Sửa danh hiệu kết nghĩa Yêu cầu #{_EXCHG%d}, tiền mặt của ngươi không đủ."
b_swear.g_msg_swear["ner"] = " Ngươi ở quá xa ta, ta không thể chủ trì nghi thức kết bái cho các ngươi."
b_swear.g_msg_swear["nel"] = " Đội của ngươi đang kết bái, mà ngươi lại ở quá xa ta, ta không thể chủ trì nghi thức kết bái cho các ngươi."
b_swear.g_msg_swear["wait"] = " Chờ Khác người hồi đáp."
b_swear.g_key = {}

b_swear.g_key["swear"] = 10000
b_swear.g_key["allow"] = 10001
b_swear.g_key["unall"] = 10002
b_swear.g_key["confi"] = 10003
b_swear.g_key["uncon"] = 10004
b_swear.g_key["title"] = 20000
b_swear.g_key["chrti"] = 30000
function b_swear:OnDefaultEvent(selfId, targetId, index)
    local key = index
    if key == self.g_key["swear"] then
        if self:CheckAccept(selfId, targetId) == 0 then
            return 0
        end
        self:LogTeamInfo(selfId, targetId)
        self:OnSubmit(selfId, targetId)
        return 1
    end
    if key == self.g_key["allow"] then
        local nMoneyJZ = self:GetMoneyJZ(selfId)
        local nMoneyJB = self:LuaFnGetMoney(selfId)
        local nMoneySelf = nMoneyJZ + nMoneyJB
        if nMoneySelf < self.g_NeedMoney then
            local msg = string.format(self.g_msg_swear["nom"], self.g_NeedMoney)
            self:MessageBox(selfId, targetId, msg)
            return 0
        end
        self:OnConfirm(selfId, targetId)
        return 1
    end
    if key == self.g_key["unall"] then
        self:BeginUICommand()
        self:UICommand_AddInt(targetId)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 1000)
        return 1
    end
    if key == self.g_key["confi"] then
        self:AgreeSwear(selfId, targetId)
        self:BeginUICommand()
        self:UICommand_AddInt(targetId)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 1000)
        if self:CheckIfAllAgreeSwear(selfId, targetId) == 1 then
            self:DoSwear(selfId, targetId)
        else
            self:WaitSwear(selfId, targetId)
        end
        return 1
    end
    if key == self.g_key["uncon"] then
        self:QuitSwear(selfId, targetId)
        return 1
    end
    if key == self.g_key["title"] then
        local TeamSize = self:CheckDrawTitle(selfId, targetId)
        if TeamSize == 0 then
            return 0
        end
        self:LogTeamInfo(selfId, targetId)
        self:LuaFnDrawJieBaiName(selfId, TeamSize)
        return 1
    end
    if key == self.g_key["chrti"] then
        if self:CheckChangeTitle(selfId, targetId) == 0 then
            return 0
        end
        self:LuaFnChangeJieBaiName(selfId)
        return 1
    end
    return 0
end

function b_swear:OnEnumerate(caller)
    caller:AddNumTextWithTarget(self.script_id, self.g_msg_swear["swr"], 6, self.g_key["swear"])
    caller:AddNumTextWithTarget(self.script_id, self.g_msg_swear["tit"], 6, self.g_key["title"])
    caller:AddNumTextWithTarget(self.script_id, self.g_msg_swear["chr"], 6, self.g_key["chrti"])
end

function b_swear:CheckAccept(selfId, targetId)
    if not self:LuaFnHasTeam(selfId) then
        self:MessageBox(selfId, targetId, self.g_msg_swear["tem"])
        return 0
    end
    local TeamSize = self:LuaFnGetTeamSize(selfId)
    if TeamSize == 1 then
        self:MessageBox(selfId, targetId, self.g_msg_swear["tem"])
        return 0
    end
    local TeamSizeSameScene = self:LuaFnGetTeamSceneMemberCount(selfId)
    if TeamSizeSameScene + 1 ~= TeamSize then
        self:MessageBox(selfId, targetId, self.g_msg_swear["ten"])
        return 0
    end
    if not self:LuaFnIsTeamLeader(selfId) then
        self:MessageBox(selfId, targetId, self.g_msg_swear["cap"])
        return 0
    end
    if not self:IsInDist(selfId, targetId, 6) then
        self:MessageBox(selfId, targetId, self.g_msg_swear["ner"])
        return 0
    end
    local theID
    local otherID
    local Friend1
    local Friend2
    local Brothers = 0
    local BrotherNum = self:LuaFnIsSweared(selfId)
    for i = 1, TeamSizeSameScene do
        theID = self:LuaFnGetTeamSceneMember(selfId, i)
        if self:LuaFnIsSpouses(selfId, theID) then
            self:MessageBox(selfId, targetId, self.g_msg_swear["mar"])
            return 0
        end
        if self:LuaFnIsMaster(selfId, theID) then
            self:MessageBox(selfId, targetId, self.g_msg_swear["mat"])
            return 0
        end
        if self:LuaFnIsPrentice(theID, selfId) then
            self:MessageBox(selfId, targetId, self.g_msg_swear["mat"])
            return 0
        end
        if not self:LuaFnIsFriend(selfId, theID) then
            self:MessageBox(selfId, targetId, self.g_msg_swear["fri"])
            return 0
        end
        if not self:LuaFnIsFriend(theID, selfId) then
            self:MessageBox(selfId, targetId, self.g_msg_swear["fri"])
            return 0
        end
        Friend1 = self:LuaFnGetFriendPoint(selfId, theID)
        Friend2 = self:LuaFnGetFriendPoint(theID, selfId)
        if Friend1 < 1000 or Friend2 < 1000 then
            self:MessageBox(selfId, targetId, self.g_msg_swear["frd"])
            return 0
        end
        if not self:IsInDist(theID, targetId, 6) then
            local theName = self:LuaFnGetName(theID)
            self:MessageBox(selfId, targetId, " Đội ngũ #Rcủa ngài" .. theName .. "#WKhoảng cách ta quá xa, nên ta không thể làm lễ kết nghĩa cho các ngươi.")
            self:MessageBox(theID, targetId, self.g_msg_swear["nel"])
            return 0
        end
        local theSwear = self:LuaFnIsSweared(theID)
        if theSwear then
            if BrotherNum then
                if self:LuaFnIsBrother(selfId, theID) then
                    local theName = self:LuaFnGetName(theID)
                    self:MessageBox(selfId, targetId, " Đội ngũ #Rcủa ngài" .. theName .. "Đã là huynh đệ kết nghĩa #Rcủa người khác, ta không thể làm lễ kết nghĩa cho các ngươi được nữa.")
                    return 0
                end
            else
                local theName = self:LuaFnGetName(theID)
                self:MessageBox(selfId, targetId, " Đội ngũ #Rcủa ngài" .. theName .. "Đã là huynh đệ kết nghĩa #Rcủa người khác, ta không thể làm lễ kết nghĩa cho các ngươi được nữa.")
            end
        end
        if theSwear and BrotherNum then
            Brothers = Brothers + 1
        end
        for j = i, TeamSizeSameScene do
            otherID = self:LuaFnGetTeamSceneMember(theID, j)
            if self:LuaFnIsSpouses(theID, otherID) then
                self:MessageBox(selfId, targetId, self.g_msg_swear["mar"])
                return 0
            end
            if self:LuaFnIsMaster(theID, otherID) then
                self:MessageBox(selfId, targetId, self.g_msg_swear["mat"])
                return 0
            end
            if self:LuaFnIsPrentice(otherID, theID) then
                self:MessageBox(selfId, targetId, self.g_msg_swear["mat"])
                return 0
            end
            if not self:LuaFnIsFriend(theID, otherID) then
                self:MessageBox(selfId, targetId, self.g_msg_swear["fri"])
                return 0
            end
            if not self:LuaFnIsFriend(otherID, theID) then
                self:MessageBox(selfId, targetId, self.g_msg_swear["fri"])
                return 0
            end
            Friend1 = self:LuaFnGetFriendPoint(theID, otherID)
            Friend2 = self:LuaFnGetFriendPoint(otherID, theID)
            if Friend1 < 1000 or Friend2 < 1000 then
                self:MessageBox(selfId, targetId, self.g_msg_swear["frd"])
                return 0
            end
        end
    end
    if BrotherNum > 0 then
        if BrotherNum == Brothers then
            if BrotherNum == TeamSizeSameScene then
                self:MessageBox(selfId, targetId, self.g_msg_swear["one"])
                return 0
            end
        else
            self:MessageBox(selfId, targetId, self.g_msg_swear["all"])
            return 0
        end
    end
    return 1
end

function b_swear:MessageBox(selfId, targetId, msg)
    self:BeginEvent(self.script_id)
    self:AddText(msg)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function b_swear:ConfirmSwear(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText(self.g_msg_swear["con"])
    self:AddNumText("Xác nhận kết nghĩa.", 6, self.g_key["confi"])
    self:AddNumText("Ta không muốn kết nghĩa nữa.", 8, self.g_key["uncon"])
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function b_swear:OnSubmit(selfId, targetId)
    self:BeginEvent(self.script_id)
    local msg = string.format(self.g_msg_swear["mon"], self.g_NeedMoney)
    self:AddText(msg)
    self:AddNumText("Xác nhận", 6, self.g_key["allow"])
    self:AddNumText("Hủy bỏ", 8, self.g_key["unall"])
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function b_swear:OnConfirm(selfId, targetId)
    self:ConfirmSwear(selfId, targetId)
    local TeamSizeSameScene = self:LuaFnGetTeamSceneMemberCount(selfId)
    for i = 1, TeamSizeSameScene do
        self:ConfirmSwear(self:LuaFnGetTeamSceneMember(selfId, i), targetId)
    end
end

function b_swear:LogTeamInfo(selfId, targetId)
    self:LuaFnTeamSnapshort(selfId)
    local TeamSizeSameScene = self:LuaFnGetTeamSceneMemberCount(selfId)
    for i = 1, TeamSizeSameScene do
        self:LuaFnTeamSnapshort(self:LuaFnGetTeamSceneMember(selfId, i))
    end
end

function b_swear:QuitSwear(selfId, targetId)
    self:BeginUICommand()
    self:UICommand_AddInt(targetId)
    self:EndUICommand()
    self:DispatchUICommand(selfId, 1000)
    local TeamLeaderID = self:GetTeamLeader(selfId)
    if TeamLeaderID ~= define.INVAILD_ID then
        local TeamSizeSameScene = self:LuaFnGetTeamSceneMemberCount(TeamLeaderID)
        local msg = self:LuaFnGetName(selfId) .. "Suy đi tính lại, ta xin rút khỏi nghi thức kết nghĩa."
        if TeamLeaderID ~= selfId then
            self:MessageBox(selfId, targetId, msg)
            self:MessageBox(TeamLeaderID, targetId, msg)
        end
        for i = 1, TeamSizeSameScene do
            local theID = self:LuaFnGetTeamSceneMember(TeamLeaderID, i)
            if theID ~= selfId then
                self:MessageBox(selfId, targetId, msg)
                self:MessageBox(theID, targetId, msg)
            end
        end
    end
end

function b_swear:AgreeSwear(selfId, targetId)
    self:LuaFnAgreeSwear(selfId, selfId)
    local TeamSizeSameScene = self:LuaFnGetTeamSceneMemberCount(selfId)
    for i = 1, TeamSizeSameScene do
        local theID = self:LuaFnGetTeamSceneMember(selfId, i)
        self:LuaFnAgreeSwear(theID, selfId)
    end
end

function b_swear:CheckIfAllAgreeSwear(selfId, targetId)
    if not self:LuaFnIfAllTeamAgreeSwear(selfId) then
        return 0
    end
    local TeamSizeSameScene = self:LuaFnGetTeamSceneMemberCount(selfId)
    for i = 1, TeamSizeSameScene do
        local theID = self:LuaFnGetTeamSceneMember(selfId, i)
        if not self:LuaFnIfAllTeamAgreeSwear(theID) then
            return 0
        end
    end
    return 1
end

function b_swear:DoSwear(selfId, targetId)
    local TeamLeaderID = self:GetTeamLeader(selfId)
    if TeamLeaderID == define.INVAILD_ID then
        return 0
    end
    local BrotherNum = self:LuaFnIsSweared(TeamLeaderID)
    local TeamSizeSameScene = self:LuaFnGetTeamSceneMemberCount(TeamLeaderID)
    if BrotherNum == TeamSizeSameScene then
        return 0
    end
    if self:LuaFnVerifyTeamWithSnapshort(TeamLeaderID) then
        self:MessageBox(TeamLeaderID, targetId, self.g_msg_swear["chn"])
        return 0
    end
    if self:CheckAccept(TeamLeaderID, targetId) == 0 then
        self:MessageBox(TeamLeaderID, targetId, self.g_msg_swear["chn"])
        return 0
    end
    local ret = self:LuaFnCostMoneyWithPriority(TeamLeaderID, 100000)
    if not ret then
        local msg = string.format(self.g_msg_swear["nom"], self.g_NeedMoney)
        self:MessageBox(TeamLeaderID, targetId, msg)
        return 0
    end
    local Names = self:LuaFnGetName(TeamLeaderID)
    self:LuaFnAllTeamSwear(TeamLeaderID)
    for i = 1, TeamSizeSameScene do
        local theID = self:LuaFnGetTeamSceneMember(TeamLeaderID, i)
        self:LuaFnAllTeamSwear(theID)
        Names = Names .. "," .. self:LuaFnGetName(theID)
    end
    self:MessageBox(TeamLeaderID, targetId, self.g_msg_swear["pro"])
    for i = 1, TeamSizeSameScene do
        local theID = self:LuaFnGetTeamSceneMember(TeamLeaderID, i)
        self:MessageBox(theID, targetId, self.g_msg_swear["pro"])
    end
    local sAllUserName = ""
    local sUserName
    local nearteammembercount = self:GetNearTeamCount(selfId)
    for i = 1, nearteammembercount do
        local idMem = self:GetNearTeamMember(selfId, i)
        sUserName = self:GetName(idMem)
        local sUserName2 = string.format("#B#{_INFOUSR%s}#Y", sUserName)
        sAllUserName = sAllUserName .. sUserName2
        if i ~= nearteammembercount then
            sAllUserName = sAllUserName .. "、"
        end
    end
    sAllUserName = gbk.fromutf8(sAllUserName)
    local sMessage = string.format("#{JieBai_00}%s#{JieBai_01}", sAllUserName)
    self:BroadMsgByChatPipe(selfId, sMessage, 4)
end

function b_swear:CheckDrawTitle(selfId, targetId)
    if not self:LuaFnHasTeam(selfId) then
        self:MessageBox(selfId, targetId, self.g_msg_swear["caa"])
        return 0
    end
    local TeamSize = self:LuaFnGetTeamSize(selfId)
    if TeamSize == 1 then
        self:MessageBox(selfId, targetId, self.g_msg_swear["caa"])
        return 0
    end
    local TeamSizeSameScene = self:LuaFnGetTeamSceneMemberCount(selfId)
    if TeamSizeSameScene + 1 ~= TeamSize then
        self:MessageBox(selfId, targetId, self.g_msg_swear["caa"])
        return 0
    end
    if not self:LuaFnIsTeamLeader(selfId) then
        self:MessageBox(selfId, targetId, self.g_msg_swear["cac"])
        return 0
    end
    local BrotherNum = self:LuaFnIsSweared(selfId)
    if BrotherNum == 0 then
        self:MessageBox(selfId, targetId, self.g_msg_swear["cas"])
        return 0
    end
    local Brothers = 0
    for i = 1, TeamSizeSameScene do
        local theID = self:LuaFnGetTeamSceneMember(selfId, i)
        if not self:LuaFnIsBrother(selfId, theID) then
            self:MessageBox(selfId, targetId, self.g_msg_swear["cab"])
            return 0
        end
        Brothers = Brothers + 1
    end
    if BrotherNum ~= Brothers then
        self:MessageBox(selfId, targetId, self.g_msg_swear["caa"])
        return 0
    end
    local nMoneyJZ = self:GetMoneyJZ(selfId)
    local nMoneyJB = self:LuaFnGetMoney(selfId)
    local nMoneySelf = nMoneyJZ + nMoneyJB
    if nMoneySelf < self.g_DrawTitleNeedMoney then
        local msg = string.format(self.g_msg_swear["nom"], self.g_DrawTitleNeedMoney)
        self:MessageBox(selfId, targetId, msg)
        return 0
    end
    return TeamSize
end

function b_swear:CheckChangeTitle(selfId, targetId)
    local BrotherNum = self:LuaFnIsSweared(selfId)
    if BrotherNum == 0 then
        self:MessageBox(selfId, targetId, self.g_msg_swear["ccs"])
        return 0
    end
    local title = self:LuaFnGetJieBaiName(selfId)
    if title == nil then
        self:MessageBox(selfId, targetId, self.g_msg_swear["can"])
        return 0
    end
    local nMoneyJZ = self:GetMoneyJZ(selfId)
    local nMoneyJB = self:LuaFnGetMoney(selfId)
    local nMoneySelf = nMoneyJZ + nMoneyJB
    if nMoneySelf < self.g_ChangeTitleNeedMoney then
        local msg = string.format(self.g_msg_swear["nmm"], self.g_ChangeTitleNeedMoney)
        self:MessageBox(selfId, targetId, msg)
        return 0
    end
    return 1
end

function b_swear:WaitSwear(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText(self.g_msg_swear["wait"])
    self:AddNumText("Ta không muốn kết nghĩa nữa.", 8, self.g_key["uncon"])
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return b_swear
