local class = require "class"
local define = require "define"
local script_base = require "script_base"
local edali_0238 = class("edali_0238", script_base)
edali_0238.script_id = 210238
edali_0238.g_Position_X = 160.0895
edali_0238.g_Position_Z = 156.9309
edali_0238.g_SceneID = 2
edali_0238.g_AccomplishNPC_Name = "赵天师"
edali_0238.g_MissionId = 1424
edali_0238.g_Name = "赵天师"
edali_0238.g_MissionKind = 13
edali_0238.g_MissionLevel = 1
edali_0238.g_IfMissionElite = 0
edali_0238.g_IsMissionOkFail = 0
edali_0238.g_MissionName = "Mười năm"
edali_0238.g_MissionInfo = "    Chúng ta Tứ đại thiện nhân mấy lão ca vừa thấy ngươi, liền cảm thấy ngươi là kỳ tài võ học trăm năm có một, nếu được danh sư truyền thụ, tiền đồ không thể lường a."
edali_0238.g_MissionInfo1 = "    Bất quá việc quan trọng nhất của ngươi hiện giờ, vẫn là trước tiên hãy xây dựng cho vững chắc nền tảng võ học. Sau khi nền tảng đã vững chắc, có thể tìm một vị danh sư, học tập võ công cao thâm, sau này trở thành một đời đại anh hùng, đại hiệp sĩ!"
edali_0238.g_MissionInfo2 = "    Vậy đi, đợi khi ngươi đạt tới Cấp độ 10, hãy đến tìm ta Triệu Thiên Sư, mấy lão già chúng ta sẽ chuẩn bị cho ngươi một phần lễ vật rất đặc biệt."
edali_0238.g_MissionTarget = "#{MIS_dali_ZTS_002}"
edali_0238.g_ContinueInfo = "#{XSRW_100111_107}"
edali_0238.g_MissionComplete = "  Tốt quá rồi, ngươi có thể gia nhập Môn phái rồi."
edali_0238.g_exp = 0
edali_0238.g_ItemBonus = {}
edali_0238.g_Custom = {{["id"] = "已达等级",["num"] = 10}}
function edali_0238:OnDefaultEvent(selfId,targetId,arg,index)
	if self:IsMissionHaveDone(selfId,self.g_MissionId) then
		return
	elseif self:IsHaveMission(selfId,self.g_MissionId) then
		self:BeginEvent(self.script_id)
		self:AddText(self.g_MissionName)
		self:AddText(self.g_ContinueInfo)
		self:EndEvent()
	local bDone = self:CheckSubmit(selfId)
		self:DispatchMissionDemandInfo(selfId,targetId,self.script_id,self.g_MissionId,bDone)
	elseif self:CheckAccept(selfId) > 0 then
		self:BeginEvent(self.script_id)
		self:AddText(self.g_MissionName)
		self:AddText(self.g_MissionInfo)
		self:AddText(self.g_MissionInfo1)
		self:AddText(self.g_MissionInfo2)
		self:EndEvent()
		self:DispatchMissionInfo(selfId,targetId,self.script_id,self.g_MissionId)
	end
end

function edali_0238:OnEnumerate(caller,selfId,targetId,arg,index)
	if self:IsMissionHaveDone(selfId,self.g_MissionId) then
		return
	elseif self:IsHaveMission(selfId,self.g_MissionId) then
	local bDone = self:CheckSubmit(selfId)
	if (1 == bDone) then
		caller:AddNumTextWithTarget(self.script_id, self.g_MissionName,2,1)
	else
		caller:AddNumTextWithTarget(self.script_id, self.g_MissionName,1,1)
	end
	elseif self:CheckAccept(selfId) > 0 then
		caller:AddNumTextWithTarget(self.script_id, self.g_MissionName,1,1)
	end
end

function edali_0238:CheckAccept(selfId)
	if self:GetLevel(selfId) >= self.g_MissionLevel then
		return 1
	else
		return 0
	end
end

function edali_0238:OnAccept(selfId)
	if self:IsMissionHaveDone(selfId,self.g_MissionId) then
		return
	end
	local ret = self:AddMission(selfId,self.g_MissionId,self.script_id,1,0,0)
	if not ret then
		self:Msg2Player(selfId,"#YNhật ký nhiệm vụ của ngươi đã đầy",define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
		return
	end
	self:Msg2Player(selfId,"Tiếp nhận nhiệm vụ:#Y" .. self.g_MissionName,define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
	local misIndex = self:GetMissionIndexByID(selfId,self.g_MissionId)
	self:SetMissionByIndex(selfId,misIndex,1, self:GetLevel(selfId))
end

function edali_0238:OnAbandon(selfId)
	self:DelMission(selfId,self.g_MissionId)
end

function edali_0238:OnContinue(selfId,targetId)
	self:BeginEvent(self.script_id)
	self:AddText(self.g_MissionName)
	self:AddText(self.g_MissionComplete)
	for i,item in pairs(self.g_ItemBonus) do
		self:AddItemBonus(item["id"] ,item["num"] )
	end
	self:EndEvent()
	self:DispatchMissionContinueInfo(selfId,targetId,self.script_id,self.g_MissionId)
end

function edali_0238:CheckSubmit(selfId)
	local Level = self:GetLevel(selfId)
	if (Level < 10) then
		return 0
	end
	return 1
end

function edali_0238:OnSubmit(selfId,targetId,selectRadioId)
	if not self:IsHaveMission(selfId,self.g_MissionId) then
		return
	end
	if self:CheckSubmit(selfId) <= 0 then
		return
	end
	if (self.g_exp > 0) then
		self:LuaFnAddExp(selfId,self.g_exp)
	end
	self:DelMission(selfId,self.g_MissionId)
	self:MissionCom(selfId,self.g_MissionId)
end

function edali_0238:OnKillObject(selfId,objdataId,objId)

end

function edali_0238:OnEnterArea(selfId,zoneId)

end

function edali_0238:OnItemChanged(selfId,itemdataId)

end

return edali_0238