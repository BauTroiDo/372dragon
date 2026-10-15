local class = require "class"
local define = require "define"
local script_base = require "script_base"
local p_recruit = class("p_recruit", script_base)
p_recruit.script_id = 806008
p_recruit.g_Recruit = {}

p_recruit.g_Recruit["Id"] = 1003
p_recruit.g_Recruit["Name"] = "Đồ đệ của ta muốn bái ta làm sư phụ."
p_recruit.g_msg = {}

p_recruit.g_msg["tem"] = "  Khi bái sư bắt buộc phải là quan hệ hảo hữu với đồ đệ, và yêu cầu hai Cá nhân tổ đội cùng nhau đến tìm ta."
p_recruit.g_msg["ner"] = "  Chỉ khi cả 2 người đến bên cạnh ta mới có thể bái sư."
p_recruit.g_msg["mlv"] = "  Sư phụ có Cấp độ phải lớn hơn hoặc bằng đồ đệ cấp 10."
p_recruit.g_msg["slv"] = "  Đồ đệ từ cấp 10 trở lên mới có thể bái sư."
p_recruit.g_msg["sib"] = "  Đã có quan hệ kết nghĩa thì không thể bái sư."
p_recruit.g_msg["mar"] = "  Quan hệ phu thê thì không thể bái sư."
p_recruit.g_msg["frp"] = "  Phải kết bạn với nhau mới có thể bái sư."
p_recruit.g_msg["msl"] = "  Xin hãy nâng cao Cấp độ sư đức của ngài, chỉ người có Cấp độ sư đức lớn hơn hoặc bằng 1 mới có tư cách thu đồ."
p_recruit.g_msg["rec_3"] = "  Sau khi cưỡng ép giải trừ quan hệ sư đồ 3 ngày mới có thể bái sư lần nữa."
p_recruit.g_msg["rec_2"] = "  Số lượng thu đồ đã đạt tối đa."
p_recruit.g_msg["rec_1"] = "  Người chơi đã có sư phụ thì không thể bái sư."
p_recruit.g_msg["ts"] = "  Đã là quan hệ sư đồ rồi, không thể bái sư."
function p_recruit:OnDefaultEvent(selfId, targetId, index)
    local key = index
    if key == -1 then
        local tId = self:CheckAccept(selfId, targetId)
        if tId == 0 then
            return
        end
        local MasterName = self:LuaFnGetName(selfId)
        local ApprenticeName = self:LuaFnGetName(tId)
        local targetName = self:LuaFnGetName(targetId)
        print("p_recruit targetName =", targetName)
        self:BeginEvent(self.script_id)
        self:AddText("  Sau khi bái sư, giết quái có thể nhận được 10% kinh nghiệm thêm, nếu cùng sư phụ tổ đội, vậy sẽ nhận được 20% kinh nghiệm thêm.")
        self:AddText("  Đồ đệ sau khi bái sư sẽ nhận được \"" .. MasterName .. "của đệ tử\" của danh hiệu.")
        self:AddText("  Con có nguyện ý bái" .. MasterName .. "vi sư chăng?")
        self:AddNumText("là", 6, 1)
        self:AddNumText("không", 8, 0)
        self:EndEvent()
        self:DispatchEventList(tId, targetId)
        self:BeginEvent(self.script_id)
        self:AddText("  Đợi đã" .. ApprenticeName .. "Trả lời...")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif key == 0 then
        self:OnCancel(selfId, targetId)
    elseif key == 1 then
        self:OnConfirm(selfId, targetId)
    end
end

function p_recruit:OnEnumerate(caller)
    caller:AddNumTextWithTarget(self.script_id, self.g_Recruit["Name"], 6, -1)
end

function p_recruit:CheckAccept(selfId, targetId)
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
    if self:LuaFnGetLevel(tId) < 10 then
        self:MsgBox(selfId, targetId, self.g_msg["slv"])
        return 0
    end
    if self:LuaFnGetLevel(tId) > 44 then
        self:MsgBox(selfId, targetId, "#{STGZ_20080520_7}")
        return 0
    end
    if self:LuaFnGetLevel(selfId) < (self:LuaFnGetLevel(tId) + 10) then
        self:MsgBox(selfId, targetId, self.g_msg["mlv"])
        return 0
    end
    local MasterLevel = self:LuaFnGetmasterLevel(selfId)
    if MasterLevel <= 0 then
        self:MsgBox(selfId, targetId, self.g_msg["msl"])
        return 0
    end
    if self:LuaFnIsBrother(selfId, tId) then
        self:MsgBox(selfId, targetId, self.g_msg["sib"])
        return 0
    end
    if self:LuaFnIsSpouses(selfId, tId) then
        self:MsgBox(selfId, targetId, self.g_msg["mar"])
        return 0
    end
    local PrenticeNum = 2
    if MasterLevel == 1 then
        PrenticeNum = 2
    elseif MasterLevel == 2 then
        PrenticeNum = 3
    elseif MasterLevel == 3 then
        PrenticeNum = 5
    elseif MasterLevel == 4 then
        PrenticeNum = 8
    end
    if self:LuaFnGetPrenticeCount(selfId) >= PrenticeNum then
        self:MsgBox(selfId, targetId, self.g_msg["rec_2"])
        return 0
    end
    if self:LuaFnHaveMaster(tId) then
        self:MsgBox(selfId, targetId, self.g_msg["rec_1"])
        return 0
    end
    if not self:LuaFnIsFriend(selfId, tId) or not self:LuaFnIsFriend(tId, selfId) then
        self:MsgBox(selfId, targetId, self.g_msg["frp"])
        return 0
    end
    if self:LuaFnIsMaster(selfId, tId) or self:LuaFnIsMaster(tId, selfId) then
        self:MsgBox(selfId, targetId, self.g_msg["ts"])
        return 0
    end
    return tId
end

function p_recruit:OnAccept(selfId, targetId)
    self:OnConfirm(selfId, targetId)
end

function p_recruit:OnSubmit(selfId, targetId, tId)
    local MasterName = self:LuaFnGetName(tId)
    local SelfName = self:LuaFnGetName(selfId)
    self:AwardShiTuTitle(selfId, MasterName .. "của đệ tử")
    self:DispatchAllTitle(selfId)
    self:LuaFnAprentice(selfId, tId)
    self:MsgBox(tId, targetId, "  Chúc mừng thu đồ thành công!")
    self:Msg2Player(tId, "Chúc mừng thu đồ thành công!", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
    self:Msg2Player(tId, "Sư phụ phải cố gắng dạy dỗ đồ nhi của con thật tốt.", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
    local str =
        string.format(
        "Chúc mừng ngài thu %s làm đồ đệ, sau khi thu đồ đệ, giết quái nhận được kinh nghiệm sẽ tăng thêm 5%. Tổ đội cùng đồ đệ, số thiện ác giá trị nhận được sẽ tăng thành 160% so với ban đầu. Sau khi đồ đệ đạt đến một Cấp độ nhất định, còn căn cứ vào độ hữu hảo giữa hai người mà cho ngài thêm phần thưởng kinh nghiệm, kinh nghiệm này cần dùng thiện ác giá trị để đổi.",
        SelfName
    )
    self:LuaFnSendSystemMail(MasterName, str)
    self:CallScriptFunction(define.SCENE_SCRIPT_ID, "PlaySoundEffect", tId, 66)
    self:LuaFnSendSpecificImpactToUnit(tId, tId, tId, 18, 1000)
    self:MsgBox(selfId, targetId, "  Chúc mừng bái sư thành công!")
    self:Msg2Player(selfId, "Chúc mừng bái sư thành công!", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
    str = string.format("Chúc mừng ngài bái %s làm sư phụ, sau khi bái sư, giết quái nhận được kinh nghiệm giá trị sẽ tăng thêm 10%, nếu cùng sư phụ tổ đội giết quái sẽ tăng thêm 20%. Sau cấp 40 phần thưởng kinh nghiệm thêm sẽ bị hủy bỏ.", MasterName)
    self:LuaFnSendSystemMail(SelfName, str)
    self:CallScriptFunction(define.SCENE_SCRIPT_ID, "PlaySoundEffect", selfId, 66)
    self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 18, 1000)
end

function p_recruit:OnConfirm(selfId, targetId)
    local tId
    if not self:LuaFnHasTeam(selfId) then
        return
    end
    if self:LuaFnGetTeamSize(selfId) ~= 2 then
        return
    end
    if self:LuaFnGetTeamSceneMemberCount(selfId) ~= 1 then
        return
    end
    tId = self:LuaFnGetTeamSceneMember(selfId, 1)
    self:MsgBox(selfId, targetId, "  Ngươi đồng ý bái đối phương làm sư.")
    self:Msg2Player(selfId, "Ngươi đồng ý bái đối phương làm sư.", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
    self:MsgBox(tId, targetId, "  Đối phương đồng ý bái ngươi làm sư.")
    self:Msg2Player(tId, "Đối phương đồng ý bái ngươi làm sư.", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
    if self:CheckAccept(tId, targetId) > 0 then
        self:OnSubmit(selfId, targetId, tId)
    end
end

function p_recruit:OnCancel(selfId, targetId)
    local tId
    if not  self:LuaFnHasTeam(selfId) then
        return
    end
    if self:LuaFnGetTeamSize(selfId) ~= 2 then
        return
    end
    if self:LuaFnGetTeamSceneMemberCount(selfId) ~= 1 then
        return
    end
    tId = self:LuaFnGetTeamSceneMember(selfId, 1)
    self:MsgBox(selfId, targetId, "  Ngươi từ chối bái đối phương làm sư.")
    self:Msg2Player(selfId, "Ngươi từ chối bái đối phương làm sư.", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
    self:MsgBox(tId, targetId, "  Đối phương từ chối bái ngươi làm sư.")
    self:Msg2Player(tId, "Đối phương từ chối bái ngươi làm sư.", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
end

function p_recruit:MsgBox(selfId, targetId, msg)
    self:BeginEvent(self.script_id)
    self:AddText(msg)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function p_recruit:MsgTip(selfId, msg)
    self:BeginEvent(self.script_id)
    self:AddText(msg)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

return p_recruit
