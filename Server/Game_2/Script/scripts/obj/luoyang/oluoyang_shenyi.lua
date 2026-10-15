--洛阳NPC
--神医
--普通

local class = require "class"
local script_base = require "script_base"
local oluoyang_shenyi = class("oluoyang_shenyi", script_base)
local g_rat = {
    {"0~9",0,0},	{"10~19",0.0079375,0.02480469},
	{"20~29",0.018375,0.05742188},	{"30~39",0.0313125,0.09785157},
	{"40~49",0.04675,0.14609376},		{"50~59",0.0646875,0.20214845},
	{"60~69",0.085125,0.26601564},	{"70~79",0.1080625,0.33769533},
	{"80~89",0.1335,0.41718752},	  {"90~99",0.162,0.50625},
	{"100~109",0.3,0.8},	          {"110~119",0.352,0.935},
	{"120~129",0.408,1.08},	      {"130~139",0.468,1.235},
	{"140~149",0.532,1.4}
}
function oluoyang_shenyi:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
        self:AddText("#{OBJ_luoyang_0019}")
        self:AddNumText("治疗",6,0)
    self:EndEvent()
    self:DispatchEventList(selfId,targetId)
end

function oluoyang_shenyi:OnEventRequest(selfId, targetId, arg, index)
	if index == 1000 then	--不愿再治疗
		self:BeginUICommand()
		    self:UICommand_AddInt(targetId)
		self:EndUICommand()
		self:DispatchUICommand(selfId, 1000)
		return
	end

    --计算恢复血和气费用
	local gld	= self:CalcMoney_hpmp(selfId )
    if index == 1001 then	--确认要治疗

		-- 得到交子和金钱数目
		local nMoneyJZ = self:GetMoneyJZ (selfId )
		local nMoney = self:GetMoney (selfId )

		--检查玩家是否有足够的现金
		if (nMoneyJZ + nMoney >= gld) then
			--扣钱
			self:LuaFnCostMoneyWithPriority (selfId, gld)
			--恢复血和气
			self:Restore_hpmp(selfId, targetId )
			return
		--钱不够
		else
			self:BeginEvent(self.script_id)
                self:AddText( "tiền của ngươi không đủ!" )
            self:EndEvent()
			self:DispatchMissionTips(selfId )
		end
        return
	end

    if index == 0 then
		if self:GetHp(selfId ) == self:GetMaxHp(selfId ) and
        self:GetRage(selfId ) == self:GetMaxRage(selfId ) and
        self:GetMp( selfId ) == self:GetMaxMp(selfId ) then
			self:BeginEvent(self.script_id)
			self:AddText("Bạn hiện rất khỏe mạnh, không Yêu cầu trị liệu!" )
			self:EndEvent()
			self:DispatchEventList( selfId, targetId )
			return
		end
		if gld <= 0 then
			self:Restore_hpmp(selfId, targetId )
		else
			self:BeginEvent( targetId )
                self:AddText("  Ngươi Yêu cầu tiêu tốn #G#{_EXCHG"..gld.."}#Wđể phục hồi huyết và khí, xác định muốn trị liệu không?" )
                self:AddNumText("là", -1, 1001 )
                self:AddNumText("không", -1, 1000 )
			self:EndEvent()
			self:DispatchEventList(selfId, targetId )
		end
        return
    end
end

function oluoyang_shenyi:CalcMoney_hpmp(selfId, TargeId)
    local sceneid = self:get_scene_id()
    local PlayerMaxLevel = self:GetHumanMaxLevelLimit()
    local	level	= self:GetLevel(selfId )
    if level < 10 then	--如果玩家等级<10，则不需要钱
        return 0
    elseif sceneid == 191 then
        return 0
    elseif level > PlayerMaxLevel then
        level	= PlayerMaxLevel
    end
    local rat		= g_rat[ math.floor(level/10) + 1 ]
    local hp		= self:GetHp(selfId )
    local maxhp	    = self:GetMaxHp(selfId )
    local mp		= self:GetMp(selfId )
    local maxmp	    = self:GetMaxMp(selfId )
    local	gld		= math.floor((maxhp-hp) * rat[2] + (maxmp-mp) * rat[3] )
    if gld < 1 then
        gld				= 100
    end
    return gld
end

function oluoyang_shenyi:Restore_hpmp(selfId, targetId )
	self:RestoreHp(selfId)
	self:RestoreMp(selfId)
    self:RestoreRage(selfId)

	local msg = "Khí huyết và nộ khí của ngươi đã hoàn toàn khôi phục."
	--取消指定玩家身上的所有敌对可驱散驻留效果
	self:BeginEvent(self.script_id)
        self:AddText(msg );
    self:EndEvent()
	self:DispatchMissionTips(selfId )

	self:BeginUICommand()
        self:UICommand_AddInt(targetId )
	self:EndUICommand()
	self:DispatchUICommand(selfId, 1000 )
end

return oluoyang_shenyi