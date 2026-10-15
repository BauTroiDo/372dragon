--洛阳NPC
--燕青
--普通

--脚本号
local class = require "class"
local script_base = require "script_base"
local oluoyang_yanqing = class("oluoyang_yanqing", script_base)
local g_DarkSkillName = { [40] = {name = "Ám Khí Phi Trịch", id = 274, needmoney = 20000},
                            [70] = {name = "Ám Khí Đả Huyệt", id = 275, needmoney = 100000},
                            [90] = {name = "Ám Khí Hộ Thể", id = 276, needmoney = 500000}}
local g_DarkSkillTips = { [40] = "#{FBSJ_090106_89}",
                            [70] = "#{FBSJ_090106_90}",
                            [90] = "#{FBSJ_090106_91}",
                          }
local g_DarkBreachPointNeedMoney =
{
	[39] = 40000,
	[49] = 50000,
	[59] = 60000,
	[69] = 70000,
	[79] = 80000,
	[89] = 90000,
	[99] = 100000,
	[109] = 110000,
	[119] = 120000,
	[129] = 130000,
}
function oluoyang_yanqing:OnDefaultEvent(selfId, targetId)
    local  PlayerSex = self:GetSex(selfId)
	if PlayerSex == 0 then
		PlayerSex = "Cô nương"
	else
		PlayerSex = "Thiếu hiệp"
	end
	self:BeginEvent(self.script_id)
		self:AddText("#{FBYQ_090204_01}"..PlayerSex.."#{FBYQ_090204_02}")
		self:AddNumText("#{FBSJ_081209_05}",6,7)
		self:AddNumText("#{FBSJ_081209_06}",6,8)
		self:AddNumText("#{FBSJ_081209_01}",6,9)
		self:AddNumText("#{FBSJ_081209_07}",6,10)
		self:AddNumText("#{FBSJ_090311_01}",6,11)
		self:AddNumText("#{FBSJ_081209_08}",6,31)
		self:AddNumText("#{FBSJ_081209_09}",11,28)
    self:EndEvent()
    self:DispatchEventList(selfId,targetId)
end

function oluoyang_yanqing:OnEventRequest(selfId, targetId, arg, index)
	if index == 6 then  --取消了
		self:BeginUICommand()
		self:EndUICommand()
		self:DispatchUICommand(selfId, 1000)
		return
	end
	if index == 7 then  --突破暗器瓶颈
		self:BeginEvent(self.script_id)
			self:AddText("#{FBSJ_081209_10}")
			self:AddNumText("#{FBSJ_081209_11}",6,12)
			self:AddNumText("#{FBSJ_081209_12}",8,13)
		self:EndEvent()
		self:DispatchEventList(selfId,targetId)
		return
	end
    if index == 8 then  --学习暗器手法
        self:BeginEvent(self.script_id)
        self:AddText("#{FBSJ_081209_20}")
        self:AddNumText("#{FBSJ_081209_21}",6,14)
        self:AddNumText("#{FBSJ_081209_22}",6,15)
        self:AddNumText("#{FBSJ_081209_23}",6,16)
        self:AddNumText("#{FBSJ_081209_12}",8,13)
        self:EndEvent()
        self:DispatchEventList(selfId,targetId)
        return
    end
	if index == 9 then
		self:BeginEvent(self.script_id)
			self:AddText("#{FBSJ_081209_31}")
			self:AddNumText("#{FBSJ_081209_32}",6,21)
			self:AddNumText("#{FBSJ_081209_33}",6,22)
			self:AddNumText("#{FBSJ_081209_34}",6,23)
			self:AddNumText("#{FBSJ_081209_35}",6,24)
			self:AddNumText("#{FBSJ_081209_36}",6,25)
			self:AddNumText("#{FBSJ_081209_12}",8,13)
		self:EndEvent()
		self:DispatchEventList(selfId,targetId)
		return
	end
	if index == 10 then
		self:BeginUICommand()
			self:UICommand_AddInt(6 )
			self:UICommand_AddInt(targetId )
		self:EndUICommand()
		self:DispatchUICommand(selfId, 800034)
		return
	end
	if index == 11 then  --重置暗器
		self:BeginEvent(self.script_id)
			self:AddText("#{FBSJ_081209_84}")
			self:AddNumText("#{FBSJ_090311_03}",6,26)
			self:AddNumText("#{FBSJ_090311_04}",6,27)
			self:AddNumText("#{FBSJ_081209_12}",8,13)
		self:EndEvent()
		self:DispatchEventList(selfId,targetId)
		return
	end
	if index == 12 then                   --我要突破当前瓶颈
		if self:CheckDarkReachPoint(selfId, targetId) then
			self:BeginEvent(self.script_id)
				local nDarkLevel = self:GetDarkLevel(selfId)
				local nNeedMoney = g_DarkBreachPointNeedMoney[nDarkLevel]
				local strInfo = string.format("  Phá vỡ bình cảnh Yêu cầu #{_EXCHG%d}.", nNeedMoney)
				self:AddText(strInfo)
				self:AddNumText("#{INTERFACE_XML_557}",6,20)
				self:AddNumText("#{Agreement_Info_No}",8,6)
			self:EndEvent()
			self:DispatchEventList(selfId,targetId)
		end
		return
	end
	if index == 13 then
		self:OnDefaultEvent(selfId, targetId)
		return
	end
    if index == 14 then
        self:BeginEvent(self.script_id)
            local strInfo = string.format("  Học tập %s thủ pháp Yêu cầu #{_EXCHG%d}.", g_DarkSkillName[40].name, g_DarkSkillName[40].needmoney)
            self:AddText(strInfo)
            self:AddNumText("#{INTERFACE_XML_557}",6,17)
            self:AddNumText("#{Agreement_Info_No}",8,6)
        self:EndEvent()
        self:DispatchEventList(selfId,targetId)
        return
    elseif index == 15 then
        self:BeginEvent(self.script_id)
            local strInfo = string.format("  Học tập %s thủ pháp Yêu cầu #{_EXCHG%d}.", g_DarkSkillName[70].name, g_DarkSkillName[70].needmoney)
            self:AddText(strInfo)
            self:AddNumText("#{INTERFACE_XML_557}",6,18)
            self:AddNumText("#{Agreement_Info_No}",8,6)
        self:EndEvent()
        self:DispatchEventList(selfId,targetId)
        return
    elseif index == 16 then
        self:BeginEvent(self.script_id)
            local strInfo = string.format("  Học tập %s thủ pháp Yêu cầu #{_EXCHG%d}.", g_DarkSkillName[90].name, g_DarkSkillName[70].needmoney)
            self:AddText(strInfo)
            self:AddNumText("#{INTERFACE_XML_557}",6,19)
            self:AddNumText("#{Agreement_Info_No}",8,6)
        self:EndEvent()
        self:DispatchEventList(selfId,targetId)
        return
    end
    if index == 17 then
        if self:CheckStudyDarkSkills(selfId, targetId, 40) == 1 then
            self:StudyDarkSkills(selfId, targetId, 40)
        end
        return
    elseif index == 18 then
        if self:CheckStudyDarkSkills(selfId, targetId, 70) == 1 then
            self:StudyDarkSkills(selfId, targetId, 70)
        end
        return
    elseif index == 19 then
        if self:CheckStudyDarkSkills(selfId, targetId, 90) == 1 then
            self:StudyDarkSkills(selfId, targetId, 90)
        end
        return
    end
	if index == 20 then
		self:BreachDarkPoint(selfId, targetId)
		return
	end
	if index == 21 then
		self:BeginUICommand()
			self:UICommand_AddInt(1)
			self:UICommand_AddInt(targetId)
		self:EndUICommand()
		self:DispatchUICommand(selfId, 800034)
		return
	elseif index == 22 then
		self:BeginUICommand()
			self:UICommand_AddInt(2)
			self:UICommand_AddInt(targetId)
		self:EndUICommand()
		self:DispatchUICommand(selfId, 800034)
		return
	elseif index == 23 then
		self:BeginUICommand()
			self:UICommand_AddInt(3)
			self:UICommand_AddInt(targetId)
		self:EndUICommand()
		self:DispatchUICommand(selfId, 800034)
		return
	elseif index == 24 then
		self:BeginUICommand()
			self:UICommand_AddInt(4 )
			self:UICommand_AddInt(targetId)
		self:EndUICommand()
		self:DispatchUICommand(selfId, 800034)
		return
	end
	if index == 26 then
		self:BeginUICommand()
			self:UICommand_AddInt(7)
			self:UICommand_AddInt(targetId )
		self:EndUICommand()
		self:DispatchUICommand(selfId, 800034)
		return
	elseif index == 27 then
		self:BeginUICommand()
			self:UICommand_AddInt(8)
			self:UICommand_AddInt(targetId)
		self:EndUICommand()
		self:DispatchUICommand(selfId, 800034)
		return
	end
	if index == 28 then
		self:BeginEvent(self.script_id)
			self:AddText("#{FBSJ_081209_69}")
			self:AddNumText("#{FBSJ_090304_02}",11,29)
			self:AddNumText("#{FBSJ_090304_01}",11,30)
		self:EndEvent()
		self:DispatchEventList(selfId,targetId)
		return
	end
	if index == 29 then
		self:BeginEvent(self.script_id)
			self:AddText("#{FBSJ_090304_03}")
		self:EndEvent()
		self:DispatchEventList(selfId,targetId)
		return
	elseif index == 30 then
		self:BeginEvent(self.script_id)
			self:AddText("#{FBSJ_090304_04}")
		self:EndEvent()
		self:DispatchEventList(selfId,targetId)
		return
	elseif index == 31 then
		self:BeginUICommand()
			self:UICommand_AddInt(9)
			self:UICommand_AddInt(targetId)
		self:EndUICommand()
		self:DispatchUICommand(selfId, 800034)
		return
	end
end

function oluoyang_yanqing:BreachDarkPoint(selfId, targetId)

	local strInfo
	--判断玩家身上是否装备有暗器
	local bHaveDarkEquip = self:HaveDarkEquiped(selfId)
	if not bHaveDarkEquip then
		strInfo = "#{FBSJ_081209_13}"
		self:ShowNotice(selfId, targetId, strInfo)
		return false
	end
	--判断玩家身上暗器是否达到瓶颈
	local bNeedNPC = self:IsDarkNeedLevelUpByNpcNow(selfId)
	if not bNeedNPC then
		strInfo = "#{FBSJ_081209_14}"
		self:ShowNotice(selfId, targetId, strInfo)
		return false
	end
	--判断玩家等级是否和暗器等级相等或者没有暗器等级高
	local nDarkLevel = self:GetDarkLevel(selfId)
	local nCharLevel = self:GetLevel(selfId)
	if (nDarkLevel >= nCharLevel) then
		strInfo = "#{FBSJ_081209_15}"
		self:ShowNotice(selfId, targetId, strInfo)
		return false
	end
	--判断玩家身上是否有足够的钱
	local nNeedMoney = g_DarkBreachPointNeedMoney[nDarkLevel]
	local nHaveMoney = self:GetMoney(selfId) + self:GetMoneyJZ(selfId)
	if (nHaveMoney < nNeedMoney) then    --10金
		self:ShowNotice(selfId, targetId, "#{FBSJ_081209_25}")
		return false
	end
	--上面判断都通过，可以扣钱突破了
	local nRet = self:LuaFnCostMoneyWithPriority(selfId, nNeedMoney)
	if not nRet then
		self:ShowNotice(selfId, targetId, "#{FBSJ_081209_25}")
		return false
	end
	--突破瓶颈，让暗器升级
	local bDarkLevelup = self:DarkLevelUp(selfId)
	if bDarkLevelup then
		self:ShowNotice(selfId, targetId, "#{FBSJ_081209_18}")
	else
		self:ShowNotice(selfId, targetId, "Đột phá thất bại.")
	end
	return true
end

--**********************************
--判断是否能够学习
--nSkillIndex参数可能值为：40，70，90，分别学习对应级别的技能
--**********************************
function oluoyang_yanqing:CheckStudyDarkSkills(selfId, targetId, nSkillIndex )
	if (nSkillIndex ~= 40 and nSkillIndex ~= 70 and nSkillIndex ~= 90) then
		return 0
	end
	--判断玩家等级是否够了
	local strNotice = ""
	local nLevel = self:GetLevel(selfId)
	if ( nLevel < nSkillIndex) then
		if (nSkillIndex == 40) then
			strNotice = "#{FBSJ_081209_24}"
		elseif (nSkillIndex == 70) then
			strNotice = "#{FBSJ_081209_27}"
		elseif (nSkillIndex == 90) then
			strNotice = "#{FBSJ_081209_29}"
		end
		self:ShowNotice(selfId, targetId, strNotice)
		return 0
	end
	--判断是否已经学会了对应技能
	if self:HaveSkill(selfId, g_DarkSkillName[nSkillIndex].id) then
		if (nSkillIndex == 40) then
			strNotice = "#{FBSJ_081209_26}"
		elseif (nSkillIndex == 70) then
			strNotice = "#{FBSJ_081209_28}"
		elseif (nSkillIndex == 90) then
			strNotice = "#{FBSJ_081209_30}"
		end
		self:ShowNotice(selfId, targetId, strNotice)
		return 0
	end
	--判断玩家身上是否有足够的钱
	local nHaveMoney = self:GetMoney(selfId) + self:GetMoneyJZ(selfId);
	if (nHaveMoney < g_DarkSkillName[nSkillIndex].needmoney) then    --10金
		strNotice = "#{FBSJ_081209_25}"
		self:ShowNotice(selfId, targetId, strNotice)
		return 0
	end
	return 1
end

--**********************************
--玩家找NPC学习暗器使用技能
--nSkillIndex参数可能值为：40，70，90，分别学习对应级别的技能
--**********************************
function oluoyang_yanqing:StudyDarkSkills(selfId, targetId, nSkillIndex )
	if (nSkillIndex ~= 40 and nSkillIndex ~= 70 and nSkillIndex ~= 90) then
		return
	end
	--判断玩家等级是否够了
	local strNotice = ""
	local nLevel = self:GetLevel(selfId)
	if ( nLevel < nSkillIndex) then
		if (nSkillIndex == 40) then
			strNotice = "#{FBSJ_081209_24}"
		elseif (nSkillIndex == 70) then
			strNotice = "#{FBSJ_081209_27}"
		elseif (nSkillIndex == 90) then
			strNotice = "#{FBSJ_081209_29}"
		end
		self:ShowNotice(selfId, targetId, strNotice)
		return 0
	end
	--判断是否已经学会了对应技能
	if self:HaveSkill(selfId, g_DarkSkillName[nSkillIndex].id) then
		if (nSkillIndex == 40) then
			strNotice = "#{FBSJ_081209_26}"
		elseif (nSkillIndex == 70) then
			strNotice = "#{FBSJ_081209_28}"
		elseif (nSkillIndex == 90) then
			strNotice = "#{FBSJ_081209_30}"
		end
		self:ShowNotice(selfId, targetId, strNotice)
		return 0
	end
	--判断玩家身上是否有足够的钱
	local nHaveMoney = self:GetMoney(selfId) + self:GetMoneyJZ(selfId);
	if (nHaveMoney < g_DarkSkillName[nSkillIndex].needmoney) then    --10金
		strNotice = "#{FBSJ_081209_25}"
		self:ShowNotice(selfId, targetId, strNotice)
		return
	end
	--上面判断都通过，可以扣钱给技能了
	local nRet = self:LuaFnCostMoneyWithPriority(selfId, g_DarkSkillName[nSkillIndex].needmoney)
	if (nRet == -1) then
		strNotice = "#{FBSJ_081209_25}"
		self:ShowNotice(selfId, targetId, strNotice)
		return 0
	end
	self:AddSkill(selfId, g_DarkSkillName[nSkillIndex].id)
    self:ShowNotice(selfId, targetId, g_DarkSkillTips[nSkillIndex]);
	self:notify_tips(selfId, targetId, g_DarkSkillTips[nSkillIndex])
	self:StudySkillImpact(selfId)
	self:DarkOperateResult(selfId, 5, 1)    --让技能按钮闪烁
end

function oluoyang_yanqing:StudySkillImpact(playerId)
	--显示学习到新技能的特效 目前使用升级特效
	self:LuaFnSendSpecificImpactToUnit(playerId, playerId, playerId, 32407, 0 )
end

function oluoyang_yanqing:ShowNotice(selfId, targetId, strNotice)
	self:BeginEvent(self.script_id)
		self:AddText(strNotice )
	self:EndEvent()
	self:DispatchEventList(selfId, targetId)
end

--玩家是否满足暗器瓶颈条件
--返回值：0或者1，1为满足，0
--**********************************
function oluoyang_yanqing:CheckDarkReachPoint(selfId, targetId)
	local strInfo
	--判断玩家身上是否装备有暗器
	local bHaveDarkEquip = self:HaveDarkEquiped(selfId)
	if not bHaveDarkEquip then
		strInfo = "#{FBSJ_081209_13}"
		self:ShowNotice(selfId, targetId, strInfo)
		return false
	end
	--判断玩家身上暗器是否达到瓶颈
	local bNeedNPC = self:IsDarkNeedLevelUpByNpcNow(selfId)
	if not bNeedNPC then
		strInfo = "#{FBSJ_081209_14}"
		self:ShowNotice(selfId, targetId, strInfo)
		return false
	end
	--判断玩家等级是否和暗器等级相等或者没有暗器等级高
	local nDarkLevel = self:GetDarkLevel(selfId)
	local nCharLevel = self:GetLevel(selfId)
	if (nDarkLevel >= nCharLevel) then
		strInfo = "#{FBSJ_081209_15}"
		self:ShowNotice(selfId, targetId, strInfo)
		return false
	end
	--判断玩家身上是否有足够的钱
	local nNeedMoney = g_DarkBreachPointNeedMoney[nDarkLevel]
	local nHaveMoney = self:GetMoney(selfId) + self:GetMoneyJZ(selfId);
	if (nHaveMoney < nNeedMoney) then    --10金
		local strNotice = "#{FBSJ_081209_25}"
		self:ShowNotice(selfId, targetId, strNotice)
		return false
	end
	return true
end

return oluoyang_yanqing