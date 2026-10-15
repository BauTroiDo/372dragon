local gbk = require "wire_charset"
local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local efuben_cuju = class("efuben_cuju", script_base)
efuben_cuju.script_id = 402040
efuben_cuju.TIME_2000_01_03_ = 946828868
efuben_cuju.g_CopySceneName = "牡丹碗"
efuben_cuju.g_CopySceneType = ScriptGlobal.FUBEN_CUJU
efuben_cuju.g_CopySceneMap = "cuju.nav"
efuben_cuju.g_Exit = "cuju.ini"
efuben_cuju.g_client_res = 233
efuben_cuju.g_LimitMembers = 3
efuben_cuju.g_TickTime = 1
efuben_cuju.g_LimitTotalHoldTime = 360
efuben_cuju.g_LimitTimeSuccess = 500
efuben_cuju.g_CloseTick = 3
efuben_cuju.g_NoUserTime = 10
efuben_cuju.g_DeadTrans = 0
efuben_cuju.g_Fuben_X = 38
efuben_cuju.g_Fuben_Z = 32
efuben_cuju.g_Back_X = 203
efuben_cuju.g_Back_Z = 56
efuben_cuju.g_Back_SceneId = 0
efuben_cuju.g_BossPoint = {["x"] = 61, ["z"] = 57}

efuben_cuju.g_MonsterPoint = {
    {["x"] = 41, ["z"] = 32}, {["x"] = 46, ["z"] = 32},
    {["x"] = 51, ["z"] = 32}, {["x"] = 56, ["z"] = 32},
    {["x"] = 61, ["z"] = 32}, {["x"] = 66, ["z"] = 32},
    {["x"] = 71, ["z"] = 32}, {["x"] = 76, ["z"] = 32},
    {["x"] = 81, ["z"] = 32}, {["x"] = 86, ["z"] = 32},
    {["x"] = 86, ["z"] = 37}, {["x"] = 86, ["z"] = 42},
    {["x"] = 86, ["z"] = 47}, {["x"] = 86, ["z"] = 52},
    {["x"] = 86, ["z"] = 57}, {["x"] = 86, ["z"] = 62},
    {["x"] = 86, ["z"] = 67}, {["x"] = 86, ["z"] = 72},
    {["x"] = 86, ["z"] = 77}, {["x"] = 86, ["z"] = 82},
    {["x"] = 86, ["z"] = 87}, {["x"] = 86, ["z"] = 92},
    {["x"] = 86, ["z"] = 97}, {["x"] = 86, ["z"] = 102},
    {["x"] = 81, ["z"] = 102}, {["x"] = 76, ["z"] = 102},
    {["x"] = 71, ["z"] = 102}, {["x"] = 66, ["z"] = 102},
    {["x"] = 61, ["z"] = 102}, {["x"] = 56, ["z"] = 102},
    {["x"] = 51, ["z"] = 102}, {["x"] = 46, ["z"] = 102},
    {["x"] = 41, ["z"] = 102}, {["x"] = 41, ["z"] = 97},
    {["x"] = 41, ["z"] = 92}, {["x"] = 41, ["z"] = 87},
    {["x"] = 41, ["z"] = 82}, {["x"] = 41, ["z"] = 77},
    {["x"] = 41, ["z"] = 72}, {["x"] = 41, ["z"] = 67},
    {["x"] = 41, ["z"] = 62}, {["x"] = 41, ["z"] = 57},
    {["x"] = 41, ["z"] = 52}, {["x"] = 41, ["z"] = 47},
    {["x"] = 41, ["z"] = 42}, {["x"] = 41, ["z"] = 37},
    {["x"] = 46, ["z"] = 37}, {["x"] = 51, ["z"] = 37},
    {["x"] = 56, ["z"] = 37}, {["x"] = 61, ["z"] = 37},
    {["x"] = 66, ["z"] = 37}, {["x"] = 71, ["z"] = 37},
    {["x"] = 76, ["z"] = 37}, {["x"] = 81, ["z"] = 37},
    {["x"] = 81, ["z"] = 42}, {["x"] = 81, ["z"] = 47},
    {["x"] = 81, ["z"] = 52}, {["x"] = 81, ["z"] = 57},
    {["x"] = 81, ["z"] = 62}, {["x"] = 81, ["z"] = 67},
    {["x"] = 81, ["z"] = 72}, {["x"] = 81, ["z"] = 77},
    {["x"] = 81, ["z"] = 82}, {["x"] = 81, ["z"] = 87},
    {["x"] = 81, ["z"] = 92}, {["x"] = 81, ["z"] = 97},
    {["x"] = 76, ["z"] = 97}, {["x"] = 71, ["z"] = 97},
    {["x"] = 66, ["z"] = 97}, {["x"] = 61, ["z"] = 97},
    {["x"] = 56, ["z"] = 97}, {["x"] = 51, ["z"] = 97},
    {["x"] = 46, ["z"] = 97}, {["x"] = 46, ["z"] = 92},
    {["x"] = 46, ["z"] = 87}, {["x"] = 46, ["z"] = 82},
    {["x"] = 46, ["z"] = 77}, {["x"] = 46, ["z"] = 72},
    {["x"] = 46, ["z"] = 67}, {["x"] = 46, ["z"] = 62},
    {["x"] = 46, ["z"] = 57}, {["x"] = 46, ["z"] = 52},
    {["x"] = 46, ["z"] = 47}, {["x"] = 46, ["z"] = 42},
    {["x"] = 51, ["z"] = 42}, {["x"] = 56, ["z"] = 42},
    {["x"] = 61, ["z"] = 42}, {["x"] = 66, ["z"] = 42},
    {["x"] = 71, ["z"] = 42}, {["x"] = 76, ["z"] = 42},
    {["x"] = 76, ["z"] = 47}, {["x"] = 76, ["z"] = 52},
    {["x"] = 76, ["z"] = 57}, {["x"] = 76, ["z"] = 62},
    {["x"] = 76, ["z"] = 67}, {["x"] = 76, ["z"] = 72},
    {["x"] = 76, ["z"] = 77}, {["x"] = 76, ["z"] = 82},
    {["x"] = 76, ["z"] = 87}, {["x"] = 76, ["z"] = 92},
    {["x"] = 71, ["z"] = 92}, {["x"] = 66, ["z"] = 92},
    {["x"] = 61, ["z"] = 92}, {["x"] = 56, ["z"] = 92},
    {["x"] = 51, ["z"] = 92}, {["x"] = 51, ["z"] = 87},
    {["x"] = 51, ["z"] = 82}, {["x"] = 51, ["z"] = 77},
    {["x"] = 51, ["z"] = 72}, {["x"] = 51, ["z"] = 67},
    {["x"] = 51, ["z"] = 62}, {["x"] = 51, ["z"] = 57},
    {["x"] = 51, ["z"] = 52}, {["x"] = 51, ["z"] = 47},
    {["x"] = 56, ["z"] = 47}, {["x"] = 61, ["z"] = 47},
    {["x"] = 66, ["z"] = 47}, {["x"] = 71, ["z"] = 47},
    {["x"] = 71, ["z"] = 52}, {["x"] = 71, ["z"] = 57},
    {["x"] = 71, ["z"] = 62}, {["x"] = 71, ["z"] = 67},
    {["x"] = 71, ["z"] = 72}, {["x"] = 71, ["z"] = 77},
    {["x"] = 71, ["z"] = 82}, {["x"] = 71, ["z"] = 87},
    {["x"] = 66, ["z"] = 87}, {["x"] = 61, ["z"] = 87},
    {["x"] = 56, ["z"] = 87}, {["x"] = 56, ["z"] = 82},
    {["x"] = 56, ["z"] = 77}, {["x"] = 56, ["z"] = 72},
    {["x"] = 56, ["z"] = 67}, {["x"] = 56, ["z"] = 62},
    {["x"] = 56, ["z"] = 57}, {["x"] = 56, ["z"] = 52},
    {["x"] = 61, ["z"] = 52}, {["x"] = 66, ["z"] = 52},
    {["x"] = 66, ["z"] = 57}, {["x"] = 66, ["z"] = 62},
    {["x"] = 66, ["z"] = 67}, {["x"] = 66, ["z"] = 72},
    {["x"] = 66, ["z"] = 77}, {["x"] = 66, ["z"] = 82},
    {["x"] = 61, ["z"] = 82}, {["x"] = 61, ["z"] = 77},
    {["x"] = 61, ["z"] = 72}, {["x"] = 61, ["z"] = 67}, {["x"] = 61, ["z"] = 62}
}

efuben_cuju.g_NianShouPoint = {
    {["x"] = 40, ["z"] = 100}, {["x"] = 40, ["z"] = 92},
    {["x"] = 40, ["z"] = 84}, {["x"] = 40, ["z"] = 76},
    {["x"] = 40, ["z"] = 68}, {["x"] = 40, ["z"] = 60},
    {["x"] = 40, ["z"] = 52}, {["x"] = 64, ["z"] = 30},
    {["x"] = 50, ["z"] = 30}, {["x"] = 78, ["z"] = 30},
    {["x"] = 90, ["z"] = 100}, {["x"] = 90, ["z"] = 92},
    {["x"] = 90, ["z"] = 84}, {["x"] = 90, ["z"] = 76},
    {["x"] = 90, ["z"] = 68}, {["x"] = 90, ["z"] = 60},
    {["x"] = 90, ["z"] = 52}, {["x"] = 60, ["z"] = 103},
    {["x"] = 50, ["z"] = 103}, {["x"] = 78, ["z"] = 103}
}

efuben_cuju.g_SmallMonsterId_1 = {
    3680, 3681, 3682, 3683, 3684, 3685, 3686, 3687, 3688, 3689, 33680, 33681,
    33682, 33683, 33684, 33685, 33686, 33687, 33688, 33689
}

efuben_cuju.g_SmallMonsterId_2 = {
    3690, 3691, 3692, 3693, 3694, 3695, 3696, 3697, 3698, 3699, 33690, 33691,
    33692, 33693, 33694, 33695, 33696, 33697, 33698, 33699
}

efuben_cuju.g_SmallMonsterId_3 = {
    3700, 3701, 3702, 3703, 3704, 3705, 3706, 3707, 3708, 3709, 33700, 33701,
    33702, 33703, 33704, 33705, 33706, 33707, 33708, 33709
}

efuben_cuju.g_MiddleMonsterId = {
    3710, 3711, 3712, 3713, 3714, 3715, 3716, 3717, 3718, 3719, 33710, 33711,
    33712, 33713, 33714, 33715, 33716, 33717, 33718, 33719
}

efuben_cuju.g_BossMonsterId = {
    3720, 3721, 3722, 3723, 3724, 3725, 3726, 3727, 3728, 3729, 33720, 33721,
    33722, 33723, 33724, 33725, 33726, 33727, 33728, 33729
}

efuben_cuju.g_NianShouID = {
    12200, 12201, 12202, 12203, 12204, 12205, 12206, 12207, 12208, 12209, 12210,
    12211
}

efuben_cuju.paramonce = 14
efuben_cuju.g_KillNum = 20
efuben_cuju.g_BigFootBall = {9160, 9170, 9180, 9190, 39160, 39170, 39180, 39190}

function efuben_cuju:OnDefaultEvent(selfId, targetId, arg, index)
    if index == 1 then
        self:BeginEvent(self.script_id)
        self:AddText("#{CUDS_20071010}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
	local nToday = tonumber(os.date("%d",os.time()))
	if nToday > 7 and nToday < 15 then
		self:BeginEvent(self.script_id)
			self:AddText("#BHoành Tảo Mẫu Đơn Oản");
			self:AddText("  #YLạc Dương#W, Giải Đấu Cúc Cầu Hoành Tảo Mẫu Đơn Oản đang ráo riết chuẩn bị cho trận đấu quan trọng kế tiếp. Kính mời chư vị đến tham gia vào khoảng thời gian từ 19:00 đến 23:00 các tối chủ nhật của tuần đầu tiên và tuần thứ ba mỗi tháng.");
		self:EndEvent()
		self:DispatchEventList(selfId,targetId)
		return
	end
	if nToday > 21 then
		self:BeginEvent(self.script_id)
			self:AddText("#BHoành Tảo Mẫu Đơn Oản");
			self:AddText("  #YLạc Dương#W, Giải Đấu Cúc Cầu Hoành Tảo Mẫu Đơn Oản đang ráo riết chuẩn bị cho trận đấu quan trọng kế tiếp. Kính mời chư vị đến tham gia vào khoảng thời gian từ 19:00 đến 23:00 các tối chủ nhật của tuần đầu tiên và tuần thứ ba mỗi tháng.");
		self:EndEvent()
		self:DispatchEventList(selfId,targetId)
		return
	end
    local nWeek = self:GetTodayWeek()
    if nWeek ~= 0 then
		self:BeginEvent(self.script_id)
			self:AddText("#BHoành Tảo Mẫu Đơn Oản");
			self:AddText("  Giải cúc cúc Hoành Tảo Mẫu Đơn Uyển Lạc Dương đang chuẩn bị trận then chốt tiếp theo. Xin tới thi Chủ nhật này từ 19h tới 23h.");
		self:EndEvent()
		self:DispatchEventList(selfId,targetId)
        return
    end
    local nQuarter = self:GetQuarterTime()
    if nQuarter < 76 or nQuarter > 92 then 
		self:BeginEvent(self.script_id)
			self:AddText("#BHoành Tảo Mẫu Đơn Oản");
			self:AddText("  Giải cúc cúc Hoành Tảo Mẫu Đơn Uyển Lạc Dương đang chuẩn bị trận then chốt tiếp theo. Xin tới thi từ 19h tới 23h tối nay.");
		self:EndEvent()
		self:DispatchEventList(selfId,targetId)
        return
    end
    if not self:LuaFnHasTeam(selfId) then
        self:BeginEvent(self.script_id)
        self:AddText("#BHoành Tảo Mẫu Đơn Oản")
        self:AddText(
            "  Giải đấu Cúc Cầu Quét Ngang Mẫu Đơn Uyển Yêu cầu tổ đội từ 3 người trở lên mới có thể tham gia, nếu ngươi chỉ muốn thể hiện tài năng Cá nhân, hãy đến tham gia Hoa Sơn Luận Kiếm!")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if self:GetTeamSize(selfId) < self.g_LimitMembers then
        self:BeginEvent(self.script_id)
        self:AddText("#BHoành Tảo Mẫu Đơn Oản")
        self:AddText(
            "  Một đội không đủ ba người, dù có vào sân Cúc Cầu cũng khó mà có khả năng giành thắng lợi, vẫn là đừng nên đi.")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if self:GetTeamLeader(selfId) ~= selfId then
        self:BeginEvent(self.script_id)
        self:AddText("#BHoành Tảo Mẫu Đơn Oản")
        self:AddText(
            "  Xin hãy thúc giục đội trưởng đội ngươi đến chỗ ta báo danh chuẩn bị tham gia!")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if self:GetTeamSize(selfId) ~= self:GetNearTeamCount(selfId) then
        self:BeginEvent(self.script_id)
        self:AddText("#BHoành Tảo Mẫu Đơn Oản")
        self:AddText(
            "  Tốt rồi, muốn nhanh chóng vào sân tham gia so tài, thì mau chóng gọi các thành viên của ngươi đến gần đây đi.")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    local nearteammembercount = self:GetNearTeamCount(selfId)
    for i = 1, nearteammembercount do
        local memId = self:GetNearTeamMember(selfId, i)
        local level = self:GetLevel(memId)
        if level < 30 then
            self:BeginEvent(self.script_id)
            self:AddText("#BHoành Tảo Mẫu Đơn Oản")
            self:AddText(
                "  Trong đội của ngươi có thành viên Cấp độ không đủ cấp 30, điều này có thể không thích ứng được với sự tranh giành quyết liệt của giải đấu Mẫu Đơn Uyển.")
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
            return
        end
    end
    for i = 1, nearteammembercount do
        local memId = self:GetNearTeamMember(selfId, i)
        local DayTimes = self:GetMissionData(memId, define.MD_ENUM.MD_CUJU_PRE_TIME)
        local oldDate = DayTimes % 100000
        local takenTimes = math.floor(DayTimes / 100000)
        local nowDate = self:GetDayTime()
        if nowDate ~= oldDate then takenTimes = 0 end
        if takenTimes >= 1 then
            self:BeginEvent(self.script_id)
            self:AddText("#BHoành Tảo Mẫu Đơn Oản")
            self:AddText(
                "  Đừng tưởng mắt ta chỉ để ngắm mỹ nữ soái ca. Ai kia! Vừa nãy chẳng phải đã thi rồi sao? Mai hãy tới")
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
            return
        end
    end
    for i = 1, nearteammembercount do
        local memId = self:GetNearTeamMember(selfId, i)
        if self:CheckAllXinfaLevel(memId, 30) == 0 then
            self:BeginEvent(self.script_id)
            self:AddText("#BHoành Tảo Mẫu Đơn Oản")
            self:AddText(
                "  Trong đội của ngươi có thành viên Cấp độ tâm pháp không đủ cấp 30, điều này có thể không thích ứng được với sự tranh giành quyết liệt của giải đấu Mẫu Đơn Uyển.")
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
            return
        end
    end
    local str = "Ta chính thức tuyên bố," .. self:GetName(selfId) ..
                    "Đội của hắn đã có thể chính thức vào sân, tham gia giải đấu Cúc Cầu Quét Ngang Mẫu Đơn Uyển mỗi tháng một lần!#r" ..
                    self:GetName(selfId) .. "#WChúc ngươi may mắn."
    self:BeginEvent(self.script_id)
    self:AddText("#BHoành Tảo Mẫu Đơn Oản")
    self:AddText(str)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
    self:MakeCopyScene(selfId)
end

function efuben_cuju:OnEnumerate(caller, selfId, targetId, arg, index)
    caller:AddNumTextWithTarget(self.script_id, "Về Giải Đấu Cúc Cầu", 11, 1)
    caller:AddNumTextWithTarget(self.script_id, "Bát Mẫu Đơn Hoành Tảo", 10, -1)
end

function efuben_cuju:CheckAccept(selfId) end

function efuben_cuju:AskEnterCopyScene(selfId) end

function efuben_cuju:OnAccept(selfId, targetId) end

function efuben_cuju:AcceptEnterCopyScene(selfId) end

function efuben_cuju:MakeCopyScene(selfId)
    local param0 = 4
    local param1 = 3
    local mylevel = 0
    local memId
    local tempMemlevel = 0
    local level0 = 0
    local level1 = 0
    local i
    local nearmembercount = self:GetNearTeamCount(selfId)
    for i = 1, nearmembercount  do
        memId = self:GetNearTeamMember(selfId, i)
        tempMemlevel = self:GetLevel(memId)
        level0 = level0 + (tempMemlevel ^ param0)
        level1 = level1 + (tempMemlevel ^ param1)
    end
    if level1 == 0 then
        mylevel = 0
    else
        mylevel = level0 / level1
    end
    if nearmembercount == -1 then mylevel = self:GetLevel(selfId) end
    local x, z = self:LuaFnGetWorldPos(selfId)
    local leaderguid = self:LuaFnObjId2Guid(selfId)
    local config = {}
    config.navmapname = self.g_CopySceneMap
	config.client_res = self.g_client_res
	config.teamleader = leaderguid
    config.NoUserCloseTime = 0
	config.Timer = self.g_TickTime * 1000
	config.params = {}
	config.params[0] = self.g_CopySceneType
	config.params[1] = self.script_id
    config.params[2] = 0
	config.params[3] = -1
	config.params[4] = x
	config.params[5] = z
	config.params[6] = self:GetTeamId( selfId )
	config.params[7] = 0
    for i = 8, 31 do config.params[i] = 0 end
    local PlayerMaxLevel = self:GetHumanMaxLevelLimit()
    local iniLevel
    if mylevel < 10 then
        iniLevel = 1
    elseif mylevel < PlayerMaxLevel then
        iniLevel = math.floor(mylevel / 10)
    else
        iniLevel = PlayerMaxLevel / 10
    end
    config.params[8] = self.g_SmallMonsterId_1[iniLevel]
    config.params[9] = self.g_SmallMonsterId_2[iniLevel]
    config.params[10] = self.g_SmallMonsterId_3[iniLevel]
    config.params[11] = self.g_MiddleMonsterId[iniLevel]
    config.params[12] = self.g_BossMonsterId[iniLevel]
    config.params[13] = mylevel
    config.params[21] = iniLevel - 1
    config.event_area = "cuju_area.ini"
    config.monsterfile = "cuju_monster.ini"
    config.sn 		 = self:LuaFnGenCopySceneSN()
    local bRetSceneID = self:LuaFnCreateCopyScene(config)
    self:BeginEvent(self.script_id)
    if bRetSceneID > 0 then
        self:AddText("Tạo phó bản thành công!")
    else
        self:AddText("Số lượng phó bản đã đạt đến giới hạn, xin hãy thử lại sau!")
    end
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

function efuben_cuju:OnCopySceneReady(destsceneId)
    local sceneId = self:get_scene_id()
    local sn = self:LuaFnGetCopySceneData_Sn(destsceneId)
    self:LuaFnSetCopySceneData_Param(destsceneId, 3, sceneId)
    local leaderguid = self:LuaFnGetCopySceneData_TeamLeader(destsceneId)
    local leaderObjId = self:LuaFnGuid2ObjId(leaderguid)
    if not self:LuaFnIsCanDoScriptLogic(leaderObjId) then return end
    if not self:LuaFnHasTeam(leaderObjId) then
        self:NewWorld(leaderObjId, destsceneId, sn, self.g_Fuben_X, self.g_Fuben_Z, self.g_client_res)
    else
        if not self:IsCaptain(leaderObjId) then
            self:NewWorld(leaderObjId, destsceneId, sn, self.g_Fuben_X, self.g_Fuben_Z, self.g_client_res)
        else
            local nearteammembercount = self:GetNearTeamCount(leaderObjId)
            local mems = {}
            for i = 1, nearteammembercount do
                mems[i] = self:GetNearTeamMember(leaderObjId, i)
                self:NewWorld(mems[i], destsceneId, sn, self.g_Fuben_X, self.g_Fuben_Z, self.g_client_res)
            end
        end
    end
end

function efuben_cuju:OnPlayerEnter(selfId)
    self:SetMissionData(selfId, define.MD_ENUM.MD_CUJU_PRE_TIME, 1 * 100000 + self:GetDayTime())
    self:SetPlayerDefaultReliveInfo(selfId, 1, 1, 0, self.g_Fuben_X,  self.g_Fuben_Z)
end

function efuben_cuju:OnHumanDie(selfId, killerId) end

function efuben_cuju:OnAbandon(selfId) end

function efuben_cuju:BackToCity(selfId) end

function efuben_cuju:OnContinue(selfId, targetId) end

function efuben_cuju:CheckSubmit(selfId, selectRadioId) end

function efuben_cuju:OnSubmit(selfId, targetId, selectRadioId) end

function efuben_cuju:OnKillObject(selfId, objdataId, objId) end

function efuben_cuju:OnEnterZone(selfId, zoneId) end

function efuben_cuju:OnItemChanged(selfId, itemdataId) end

function efuben_cuju:OnCopySceneTimer(nowTime)
    local once = self:LuaFnGetCopySceneData_Param(self.paramonce)
    if (once == 0) then
        self:LuaFnSetCopySceneData_Param(self.paramonce, 1)
        local mylevel = self:LuaFnGetCopySceneData_Param(13)
        local PlayerMaxLevel = self:GetHumanMaxLevelLimit()
        local iniLevel
        if mylevel < 100 then
            iniLevel = 100
        elseif mylevel < PlayerMaxLevel then
            iniLevel = math.floor(mylevel / 100) * 100
        else
            iniLevel = PlayerMaxLevel
        end
        local iNianShouIdx = iniLevel / 100
    end
    local nKillNum = self:LuaFnGetCopySceneData_Param(20)
    local nPreTime = self:LuaFnGetCopySceneData_Param(15)
    local nCurTime = self:LuaFnGetCurrentTime()
    local nStep = self:LuaFnGetCopySceneData_Param(16)
    local SmallMonsterId_1 = self:LuaFnGetCopySceneData_Param(8)
    local SmallMonsterId_2 = self:LuaFnGetCopySceneData_Param(9)
    local SmallMonsterId_3 = self:LuaFnGetCopySceneData_Param(10)
    local MiddleMonsterId = self:LuaFnGetCopySceneData_Param(11)
    local BossMonsterId = self:LuaFnGetCopySceneData_Param(12)
    local nMonsterLevel = self:LuaFnGetCopySceneData_Param(13)
    local nPreBossSpeakTime = self:LuaFnGetCopySceneData_Param(20)
    local arrayex = 0
    local levelex = 0
    if (nMonsterLevel >= 110) then
        arrayex = 4
        levelex = 10
    end
    if nPreTime == 0 then
        self:LuaFnSetCopySceneData_Param(15, nCurTime)
        self:TipAllHuman("So tài đá cầu sẽ chính thức bắt đầu sau 60 giây")
        return
    end
    if nStep == 0 and nCurTime - nPreTime >= 10 then
        self:TipAllHuman("Giải Túc Cầu so tài sẽ chính thức bắt đầu sau 50 giây nữa.")
        self:LuaFnSetCopySceneData_Param(16, nStep + 1)
        self:LuaFnSetCopySceneData_Param(15, nCurTime)
        return
    end
    if nStep == 1 and nCurTime - nPreTime >= 10 then
        self:TipAllHuman("Giải Túc Cầu so tài sẽ chính thức bắt đầu sau 40 giây nữa.")
        self:LuaFnSetCopySceneData_Param(16, nStep + 1)
        self:LuaFnSetCopySceneData_Param(15, nCurTime)
        return
    end
    if nStep == 2 and nCurTime - nPreTime >= 10 then
        self:TipAllHuman("Giải Túc Cầu so tài sẽ chính thức bắt đầu sau 30 giây nữa.")
        self:LuaFnSetCopySceneData_Param(16, nStep + 1)
        self:LuaFnSetCopySceneData_Param(15, nCurTime)
        return
    end
    if nStep == 3 and nCurTime - nPreTime >= 10 then
        self:TipAllHuman("Giải Túc Cầu so tài sẽ chính thức bắt đầu sau 20 giây nữa.")
        self:LuaFnSetCopySceneData_Param(16, nStep + 1)
        self:LuaFnSetCopySceneData_Param(15, nCurTime)
        return
    end
    if nStep == 4 and nCurTime - nPreTime >= 10 then
        self:TipAllHuman("Giải Túc Cầu so tài sẽ chính thức bắt đầu sau 10 giây nữa.")
        self:LuaFnSetCopySceneData_Param(16, nStep + 1)
        self:LuaFnSetCopySceneData_Param(15, nCurTime + 5)
        return
    end
    local nMonsterNum = self:GetMonsterCount()
    local bHaveMonster = 0
    for ii = 1, nMonsterNum do
        local nMonsterId = self:GetMonsterObjID(ii)
        if self:GetName(nMonsterId) == "双双燕" or self:GetName(nMonsterId) ==
            "鸳鸯拐" or self:GetName(nMonsterId) == "云外飘" then
            if nowTime - self:GetObjCreateTime(nMonsterId) > 60000 then
                if self:GetHp(nMonsterId) > 0 then
                    local PosX, PosZ = self:LuaFnGetWorldPos(nMonsterId)
                    PosX = math.floor(PosX)
                    PosZ = math.floor(PosZ)
                    self:LuaFnDeleteMonster(nMonsterId)
                    local nMiddleMonster =
                        self:LuaFnCreateMonster(MiddleMonsterId, PosX, PosZ, 3,
                                                0, 402045)
                    self:SetLevel(nMiddleMonster, nMonsterLevel)
                    self:SetNPCAIType(nMiddleMonster, 0)
                    self:SetCharacterName(nMiddleMonster, "满天星")
                end
            end
        elseif self:GetName(nMonsterId) == "双双燕燕" or
            self:GetName(nMonsterId) == "鸳鸯拐拐" or
            self:GetName(nMonsterId) == "云外飘飘" then
            if nowTime - self:GetObjCreateTime(nMonsterId) > 60000 then
                if self:GetHp(nMonsterId) > 0 then
                    local PosX, PosZ = self:LuaFnGetWorldPos(nMonsterId)
                    PosX = math.floor(PosX)
                    PosZ = math.floor(PosZ)
                    self:LuaFnDeleteMonster(nMonsterId)
                    local nIniLevel = self:LuaFnGetCopySceneData_Param(21)
                    local nBigBallId = self.g_BigFootBall[4 + arrayex] +
                                           nIniLevel - levelex
                    local nMiddleMonster =
                        self:LuaFnCreateMonster(nBigBallId, PosX, PosZ, 3, 0,
                                                402045)
                    self:SetLevel(nMiddleMonster, nMonsterLevel)
                    self:SetNPCAIType(nMiddleMonster, 0)
                    self:SetCharacterName(nMiddleMonster, "满天星")
                end
            end
        end
    end
    if nStep >= 5 and nStep < 154 and nCurTime - nPreBossSpeakTime >= 60 then
        self:LuaFnSetCopySceneData_Param(20, nCurTime)
        local nRand = math.random(6)
        local str
        if nRand == 1 then
            str =
                "#{_BOSS4}#P:Chúng ta là người kế thừa của Trung Hoa Cúc Cầu! Kế thừa Cao Cầu Đồng Quán của truyền thống vinh quang!"
        elseif nRand == 2 then
            str =
                "#{_BOSS4}#P:Mau mau mau, chia biên nào! Xuống đáy nào! Truyền giữa nào! Đánh đầu nào!"
        elseif nRand == 3 then
            str =
                "#{_BOSS4}#P:Mãn Thiên Tinh lập công rồi! Song Song Yến, Uyên Ương Quải, Vân Ngoại Phiêu, vào khoảnh khắc này linh hồn nhập thể!"
        elseif nRand == 4 then
            str =
                "#{_BOSS4}#P:Mãn Thiên Tinh đại diện cho truyền thống vinh quang của ta Tôn Mỹ Mỹ! Nó không phải là một Cá nhân! Nó không phải là một Cá nhân!"
        elseif nRand == 5 then
            str =
                "#{_BOSS4}#P:Ái da, các ngươi thật ngốc! Song Song Yến, ngươi nói xem, sao ngươi cứ đứng yên cho người ta đánh thế?"
        else
            str =
                "#{_BOSS4}#P:Ngươi mà còn đánh vào bóng của người ta nữa, người ta sẽ không chơi với ngươi đâu đó!"
        end
        self:CallScriptFunction((200060), "Duibai", "", "牡丹碗", str)
    end
    if nStep == 24 or nStep == 54 or nStep == 124 then
        local nStep_1 = self:LuaFnGetCopySceneData_Param(25)
        local nStep_1_T = self:LuaFnGetCopySceneData_Param(26)
        if nStep_1 == 0 then
            self:LuaFnSetCopySceneData_Param(25, nStep_1 + 1)
            self:LuaFnSetCopySceneData_Param(26, nCurTime)
            local str
            if nStep == 24 then
                str =
                    "#{_BOSS4}#P:Đừng đắc ý quá sớm! Để ta thay người! Cái lợi hại còn ở phía sau kia!"
            elseif nStep == 24 then
                str =
                    "#{_BOSS4}#P:Ai cười đến cuối cùng! Ai cười là hay nhất! Ta còn phải thay người!"
            else
                str =
                    "#{_BOSS4}#P:Ngươi xong rồi! Ta phải thay đội mạnh nhất của ta ra sân!"
            end
            self:CallScriptFunction((200060), "Duibai", "", "牡丹碗", str)
            self:TipAllHuman(
                "Tôn Mỹ Mỹ xin đổi người, 30 giây sau so tài tiếp tục tiến hành.")
        elseif nStep_1 == 1 then
            if nCurTime - nStep_1_T >= 10 then
                self:TipAllHuman(
                    "Tôn Mỹ Mỹ xin đổi người, 20 giây sau so tài tiếp tục tiến hành.")
                self:LuaFnSetCopySceneData_Param(25, nStep_1 + 1)
                self:LuaFnSetCopySceneData_Param(26, nCurTime)
            end
        elseif nStep_1 == 2 then
            if nCurTime - nStep_1_T >= 10 then
                self:TipAllHuman(
                    "Tôn Mỹ Mỹ xin đổi người, 10 giây sau so tài tiếp tục tiến hành.")
                self:LuaFnSetCopySceneData_Param(25, nStep_1 + 1)
                self:LuaFnSetCopySceneData_Param(26, nCurTime)
            end
        elseif nStep_1 == 3 then
            if nCurTime - nStep_1_T >= 10 then
                self:TipAllHuman("So tài bắt đầu lại.")
                self:LuaFnSetCopySceneData_Param(25, nStep_1 + 1)
                self:LuaFnSetCopySceneData_Param(26, nCurTime)
                local nIniLevel = self:LuaFnGetCopySceneData_Param(21)
                local nBigFootballId = 0
                local ran = math.random(3)
                local szName = ""
                if ran == 1 then
                    nBigFootballId =
                        self.g_BigFootBall[1 + arrayex] + nIniLevel - levelex
                    szName = "双双燕燕"
                elseif ran == 2 then
                    nBigFootballId =
                        self.g_BigFootBall[2 + arrayex] + nIniLevel - levelex
                    szName = "鸳鸯拐拐"
                else
                    nBigFootballId =
                        self.g_BigFootBall[3 + arrayex] + nIniLevel - levelex
                    szName = "云外飘飘"
                end
                local Point = self.g_MonsterPoint[nStep - 4]
                local nNpc1 = self:LuaFnCreateMonster(nBigFootballId,
                                                      Point["x"] +
                                                          math.random(2),
                                                      Point["z"], 3, 0, 402045)
                self:SetLevel(nNpc1, nMonsterLevel)
                self:SetCharacterName(nNpc1, szName)
            end
        elseif nStep_1 == 4 then
            self:LuaFnSetCopySceneData_Param(25, 0)
            self:LuaFnSetCopySceneData_Param(26, nCurTime)
            self:LuaFnSetCopySceneData_Param(15, nCurTime)
            self:LuaFnSetCopySceneData_Param(16, nStep + 1)
        end
    end
    if (nStep >= 5 and nStep < 24 and nCurTime - nPreTime >= 15) or
        (nStep >= 25 and nStep < 54 and nCurTime - nPreTime >= 12) or
        (nStep >= 55 and nStep < 124 and nCurTime - nPreTime >= 10) or
        (nStep >= 125 and nStep < 154 and nCurTime - nPreTime >= 5) then
        if nStep == 5 then self:TipAllHuman("So tài đá cầu chính thức bắt đầu.") end
        local Point = self.g_MonsterPoint[nStep - 4]
        local nMonsterId = 0
        local ran = math.random(3)
        if ran == 1 then
            nMonsterId = SmallMonsterId_1
        elseif ran == 2 then
            nMonsterId = SmallMonsterId_2
        else
            nMonsterId = SmallMonsterId_3
        end
        local nNpc1 = self:LuaFnCreateMonster(nMonsterId,
                                              Point["x"] + math.random(2),
                                              Point["z"], 3, 0, 402045)
        self:SetLevel(nNpc1, nMonsterLevel)
        if ran == 1 then
            self:SetCharacterName(nNpc1, "双双燕")
        elseif ran == 2 then
            self:SetCharacterName(nNpc1, "鸳鸯拐")
        else
            self:SetCharacterName(nNpc1, "云外飘")
        end
        nStep = nStep + 1
        self:LuaFnSetCopySceneData_Param(15, nCurTime)
        self:LuaFnSetCopySceneData_Param(16, nStep)
    end
    if nStep == 154 then
        local nMonsterNum = self:GetMonsterCount()
        local bHaveMonster = 0
        for ii = 1, nMonsterNum do
            local nMonsterId = self:GetMonsterObjID(ii)
            if self:GetName(nMonsterId) == "双双燕" then
                bHaveMonster = 1
                break
            end
            if self:GetName(nMonsterId) == "鸳鸯拐" then
                bHaveMonster = 1
                break
            end
            if self:GetName(nMonsterId) == "云外飘" then
                bHaveMonster = 1
                break
            end
            if self:GetName(nMonsterId) == "满天星" then
                bHaveMonster = 1
                break
            end
        end
        if bHaveMonster == 0 then
            nStep = nStep + 1
            self:LuaFnSetCopySceneData_Param(15, nCurTime)
            self:LuaFnSetCopySceneData_Param(16, nStep)
        end
    end
    if nStep == 155 then
        self:TipAllHuman("Tôn Mỹ Mỹ sẽ xuất hiện sau 10 giây")
        self:LuaFnSetCopySceneData_Param(16, nStep + 1)
        self:LuaFnSetCopySceneData_Param(15, nCurTime)
        return
    end
    if nStep == 156 and nCurTime - nPreTime >= 10 then
        nStep = nStep + 1
        self:LuaFnSetCopySceneData_Param(15, nCurTime)
        self:LuaFnSetCopySceneData_Param(16, nStep)
        local nNpc1 = self:LuaFnCreateMonster(BossMonsterId,
                                              self.g_BossPoint["x"],
                                              self.g_BossPoint["z"], 19, 216,
                                              402040)
        self:SetLevel(nNpc1, nMonsterLevel)
        self:SetNPCAIType(nNpc1, 0)
        self:SetCharacterName(nNpc1, "孙美美")
        self:SetCharacterTitle(nNpc1, "\"Xúc Cúc Thập Tam Muội\"")
        self:TipAllHuman("Tôn Mỹ Mỹ xuất hiện")
    end
end

function efuben_cuju:OnDie(objId, killerId)
    local playerID = killerId
    local objType = self:GetCharacterType(killerId)
    if objType == 3 then playerID = self:GetPetCreator(killerId) end
    local nLeaderId = self:GetTeamLeader(playerID)
    if nLeaderId < 1 then nLeaderId = playerID end
    local str = string.format(
              "#PTrong trận đại hội Xúc Cúc Mẫu Đơn Uyển càn quét vừa kết thúc, #{_INFOUSR%s}#P đã dẫn dắt đội Xúc Cúc càn quét đội của #{_BOSS4}#P, nhận được một trận đại thắng vô cùng sảng khoái!",
              self:GetName(nLeaderId))
    str = gbk.fromutf8(str)
    self:BroadMsgByChatPipe(nLeaderId, str, 4)
end

function efuben_cuju:CheckAllXinfaLevel(selfId, level)
    local nMenpai = self:GetMenPai(selfId)
    if nMenpai == 9 then return 0 end
    for i = 1, 6 do
        local xinfa
        if nMenpai < 9 then
            xinfa = nMenpai * 6 + i
        else
            xinfa = nMenpai * 6 + (i + 3)
        end
        local nXinfaLevel = self:LuaFnGetXinFaLevel(selfId, xinfa)
        if nXinfaLevel < level then
            return 0
        end
    end
    return 1
end

function efuben_cuju:TipAllHuman(Str)
    local nHumanNum = self:LuaFnGetCopyScene_HumanCount()
    if nHumanNum < 1 then return end
    for i = 1, nHumanNum do
        local PlayerId = self:LuaFnGetCopyScene_HumanObjId(i)
        self:BeginEvent(self.script_id)
        self:AddText(Str)
        self:EndEvent()
        self:DispatchMissionTips(PlayerId)
    end
end

return efuben_cuju
