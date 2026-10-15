--蜃海幻兽
local gbk = require "wire_charset"
local class = require "class"
local define = require "define"
local script_base = require "script_base"
local shenhaihuanshou_activity = class("shenhaihuanshou_activity", script_base)
shenhaihuanshou_activity.script_id = 999979
shenhaihuanshou_activity.DataValidator = 0
--公告
shenhaihuanshou_activity.text = "#c00ff00Nhóm BOSS Thẩn Hải Huyễn Thú đã xuất hiện ở [Diêm Hồ], chư vị anh hùng mau tới khiêu chiến!"
--boss信息
shenhaihuanshou_activity.bossinfo = 
{
	{
		sceneId = 415,
		scenename = "Diêm Hồ",
		bossId = 55103,
		lifetime = 3600 * 1000,
		bossHp = 0,
		monsterpos = 
		{
			{79,175,false},
			{73,160,false},
			{64,166,false},
			{63,175,false},
		},
	},
	{
		sceneId = 415,
		scenename = "Diêm Hồ",
		bossId = 55104,
		lifetime = 3600 * 1000,
		bossHp = 0,
		monsterpos = 
		{
			{120,42,false},
			{108,43,false},
			{102,33,false},
			{112,29,false},
		},
	},
	{
		sceneId = 415,
		scenename = "Diêm Hồ",
		bossId = 55109,
		lifetime = 3600 * 1000,
		bossHp = 0,
		monsterpos = 
		{
			{214,35,false},
			{218,46,false},
			{204,58,false},
			{192,54,false},
		},
	},
	{
		sceneId = 415,
		scenename = "Diêm Hồ",
		bossId = 55106,
		lifetime = 3600 * 1000,
		bossHp = 0,
		monsterpos = 
		{
			{184,145,false},
			{190,165,false},
			{207,152,false},
			{207,132,false},
		},
	},
	{
		sceneId = 415,
		scenename = "Diêm Hồ",
		bossId = 55107,
		lifetime = 3600 * 1000,
		bossHp = 0,
		monsterpos = 
		{
			{152,223,false},
			{136,220,false},
			{119,219,false},
			{167,200,false},
		},
	},
	{
		sceneId = 415,
		scenename = "Diêm Hồ",
		bossId = 55108,
		lifetime = 3600 * 1000,
		bossHp = 0,
		monsterpos = 
		{
			{57,205,false},
			{67,197,false},
			{75,209,false},
			{60,220,false},
		},
	},
}
shenhaihuanshou_activity.openhours = {
		[0]	= true,
		[2] = true,
		[4] = true,
		[6] = true,
		[8] = true,
		[10] = true,
		[12] = true,
		[14] = true,
		[16] = true,
		[18] = true,
		[20] = true,
		[22] = true,
}

--非配置内容
shenhaihuanshou_activity.minutetick = 2


function shenhaihuanshou_activity:GetDataValidator(param1,param2)
	self.DataValidator = math.random(1,2100000000)
	return self.DataValidator
end
function shenhaihuanshou_activity:OnDefaultEvent(actId, iNoticeType, param2, param3, param4, param5, param6)
	if param6 ~= self.DataValidator then
		return
	elseif not iNoticeType or not param2 or not param3 or not param4 or not param5 then
		return
	-- elseif self.scene:get_id() ~= self.scene:get_param(1) then
		-- return
	end
	if actId ~= define.ACTIVITY_SIZHOU_ID then
		return
	end
	if not self:HaveActivity(actId) then
		self:StartOneActivity(actId,2100000000,iNoticeType,nil,nil,-1)
	end
end

function shenhaihuanshou_activity:CreateBoss(actId,sceneId)
	if not actId or actId >= 0 then
		return
	end
	actId = -1 * actId
	local scene = self:get_scene()
	if not scene or scene:get_id() ~= sceneId
	or actId ~= define.ACTIVITY_SIZHOU_ID then
		return
	end
	local bossinfo
	for i,j in ipairs(self.bossinfo) do
		if j.sceneId == sceneId then
			bossinfo = j
			break
		end
	end
	if not bossinfo then return end
	local existing = 0
	for _, obj in pairs(scene.objs) do
		if obj and obj:get_obj_type() == "monster" and obj:is_alive()
		and obj:get_model() == bossinfo.bossId then
			existing = existing + 1
		end
	end

	local objId
	for i = existing + 1, #bossinfo.monsterpos do
		local j = bossinfo.monsterpos[i]
		objId = self:LuaFnCreateMonster(bossinfo.bossId,j[1],j[2],4,0,-1)
		if objId and objId ~= define.INVAILD_ID then
			self:SetCharacterDieTime(objId,bossinfo.lifetime or 3600000)
			if bossinfo.bossHp > 0 then
				self:LuaFnSetLifeTimeAttrRefix_MaxHP(objId,bossinfo.bossHp)
				self:RestoreHp(objId)
			end
			-- self:SetCharacterName(objId, "")
			self:SetCharacterTitle(objId,bossinfo.scenename.."BOSS")
			self:SetUnitReputationID(objId,objId,29)
		end
	end
	-- self:AddGlobalCountNews("@*;SrvMsg;SCA:"..bossinfo.scenename..":"..self.text)
end
function shenhaihuanshou_activity:OnTimer_Hour(actId,minute,hminute,hour)
	if not actId or actId >= 0 then
		return
	end
	if self.openhours[hour] and minute == 0 then
		local skynet = require "skynet"
		for _,j in ipairs(self.bossinfo) do
			local name = string.format(".SCENE_%d", j.sceneId)
			skynet.send(name, "lua", "char_excute_Script", self.script_id, "CreateBoss", actId, j.sceneId)
		end
		self:AddGlobalCountNews("@*;SrvMsg;SCA:"..self.text)
	end
end
function shenhaihuanshou_activity:OnTimer(actId, uTime, param1)
end
		
return shenhaihuanshou_activity
