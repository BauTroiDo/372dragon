local class = require "class"
local define = require "define"
local script_base = require "script_base"
local eLingyuActivity = class("eLingyuActivity", script_base)
-- local IsScriptid = 808002
eLingyuActivity.script_id = 808002
eLingyuActivity.DataValidator = 0
eLingyuActivity.sceneId = 1297
eLingyuActivity.actId = 365
eLingyuActivity.update_min_monster_time = 600
eLingyuActivity.g_BossData = {
    {
        ["ID"] = 50947,
        ["PosX"] = 45,
        ["PosY"] = 45,
        ["BaseAI"] = 3,
        ["ExtAIScript"] = -1,
        ["ScriptID"] = 900068,
        ["NeedCreate"] = 1
    },
    {
        ["ID"] = 50947,
        ["PosX"] = 102,
        ["PosY"] = 82,
        ["BaseAI"] = 3,
        ["ExtAIScript"] = -1,
        ["ScriptID"] = 900068,
        ["NeedCreate"] = 1
    },
    {
        ["ID"] = 50947,
        ["PosX"] = 65,
        ["PosY"] = 98,
        ["BaseAI"] = 3,
        ["ExtAIScript"] = -1,
        ["ScriptID"] = 900068,
        ["NeedCreate"] = 1
    },
    {
        ["ID"] = 50947,
        ["PosX"] = 39,
        ["PosY"] = 145,
        ["BaseAI"] = 3,
        ["ExtAIScript"] = -1,
        ["ScriptID"] = 900068,
        ["NeedCreate"] = 1
    },
    {
        ["ID"] = 50947,
        ["PosX"] = 75,
        ["PosY"] = 198,
        ["BaseAI"] = 3,
        ["ExtAIScript"] = -1,
        ["ScriptID"] = 900068,
        ["NeedCreate"] = 1
    },
    {
        ["ID"] = 50947,
        ["PosX"] = 57,
        ["PosY"] = 237,
        ["BaseAI"] = 3,
        ["ExtAIScript"] = -1,
        ["ScriptID"] = 900068,
        ["NeedCreate"] = 1
    },
    {
        ["ID"] = 50947,
        ["PosX"] = 160,
        ["PosY"] = 210,
        ["BaseAI"] = 3,
        ["ExtAIScript"] = -1,
        ["ScriptID"] = 900068,
        ["NeedCreate"] = 1
    },
    {
        ["ID"] = 50947,
        ["PosX"] = 279,
        ["PosY"] = 76,
        ["BaseAI"] = 3,
        ["ExtAIScript"] = -1,
        ["ScriptID"] = 900068,
        ["NeedCreate"] = 1
    },
    {
        ["ID"] = 50947,
        ["PosX"] = 260,
        ["PosY"] = 119,
        ["BaseAI"] = 3,
        ["ExtAIScript"] = -1,
        ["ScriptID"] = 900068,
        ["NeedCreate"] = 1
    },
    {
        ["ID"] = 50947,
        ["PosX"] = 254.5,
        ["PosY"] = 184.5,
        ["BaseAI"] = 3,
        ["ExtAIScript"] = -1,
        ["ScriptID"] = 900068,
        ["NeedCreate"] = 1
    },
    {
        ["ID"] = 50947,
        ["PosX"] = 256,
        ["PosY"] = 239,
        ["BaseAI"] = 3,
        ["ExtAIScript"] = -1,
        ["ScriptID"] = 900068,
        ["NeedCreate"] = 1
    },
    {
        ["ID"] = 50947,
        ["PosX"] = 215,
        ["PosY"] = 232,
        ["BaseAI"] = 3,
        ["ExtAIScript"] = -1,
        ["ScriptID"] = 900068,
        ["NeedCreate"] = 1
    },

    {
        ["ID"] = 50949,
        ["PosX"] = 160,
        ["PosY"] = 90,
        ["BaseAI"] = 3,
        ["ExtAIScript"] = -1,
        ["ScriptID"] = 900068,
        ["NeedCreate"] = 1
    },
    {
        ["ID"] = 50949,
        ["PosX"] = 131.5,
        ["PosY"] = 189.5,
        ["BaseAI"] = 3,
        ["ExtAIScript"] = -1,
        ["ScriptID"] = 900068,
        ["NeedCreate"] = 1
    },
    {
        ["ID"] = 50949,
        ["PosX"] = 160,
        ["PosY"] = 160,
        ["BaseAI"] = 3,
        ["ExtAIScript"] = -1,
        ["ScriptID"] = 900068,
        ["NeedCreate"] = 1
    },
    {
        ["ID"] = 50949,
        ["PosX"] = 188,
        ["PosY"] = 136,
        ["BaseAI"] = 3,
        ["ExtAIScript"] = -1,
        ["ScriptID"] = 900068,
        ["NeedCreate"] = 1
    },
    {
        ["ID"] = 50949,
        ["PosX"] = 188,
        ["PosY"] = 191,
        ["BaseAI"] = 3,
        ["ExtAIScript"] = -1,
        ["ScriptID"] = 900068,
        ["NeedCreate"] = 1
    },
    {
        ["ID"] = 50949,
        ["PosX"] = 132,
        ["PosY"] = 136,
        ["BaseAI"] = 3,
        ["ExtAIScript"] = -1,
        ["ScriptID"] = 900068,
        ["NeedCreate"] = 1
    }
}
eLingyuActivity.MonsterGroup = {
    { ID = 50940, Num = 4},
    { ID = 50942, Num = 2},
    { ID = 50944, Num = 1},
}
eLingyuActivity.open_time = 
{
	{starthour = 13,startminue = 0,endhour = 14,endminue = 0},
}
function eLingyuActivity:OnDefaultEvent(actId, iNoticeType, param2, param3, param4, param5, param6)
	if param6 ~= eLingyuActivity.DataValidator then
		return
	elseif not iNoticeType or not param2 or not param3 or not param4 or not param5 then
		return
	end
	if self:get_scene_id() ~= 1297 or actId ~= self.actId then
		return
	end
	if self:HaveActivity(actId) then
		return
	end
	self:StartOneActivity(actId,2100000000,iNoticeType,nil,-1)
    -- self:SetActivityParam(actId, 1, 0)
    -- self:CreatePlatform_808002(actId)
    -- self:CreateMonsters_808002()
end
function eLingyuActivity:GetDataValidator(param1,param2)
	eLingyuActivity.DataValidator = math.random(1,2100000000)
	return eLingyuActivity.DataValidator
end
--*********************************
-- 开启活动
--*********************************
function eLingyuActivity:OnTimer_Minute(actId,minute,hminute,hour)
	if not actId or actId >= 0 then
		return
	end
	local newId = -1 * actId
	if newId ~= self.actId then
		return
	end
	local ischeck
	local statrtime,overtime,value
	local today = tonumber(os.date("%Y%m%d"))
	local load_date = today % 10000
	load_date = load_date * 10000
	local old_date
	for _,info in pairs(self.open_time) do
		statrtime = info.starthour * 60 + info.startminue
		overtime = info.endhour * 60 + info.endminue
		if hminute >= statrtime and hminute < overtime then
			if self:GetActivityParam(newId,1) == 0 then
				value = load_date + statrtime
				old_date = self:GetActivityKey(newId,"load_date",self.sceneId)
				if old_date and old_date ~= value then
					self:SetActivityTick(newId,"tsec")
					self:SetActivityParam(newId,1,1)
					self:SetActivityParam(newId,2,self.update_min_monster_time)
					local del_time = overtime - hminute
					del_time = del_time * 60 * 1000
					self:CreatePlatform(actId,del_time)
					self:CreateMonsters(actId)
					local msg = "#GTrường Xuân Cốc·Bất Lão Điện#Pmở, người có chí mau tới#GBạch Khê Hồ (109,108)#P,#GThục Nam Trúc Hải (78,108)#P, chỗ#GTây Lương Phong Lâm (91,59)#YThanh Diên#Pđể tới#GTrường Xuân Cốc·Bất Lão Điện#P."
					self:AddGlobalCountNews(msg)
				end
			end
			return
		elseif hminute == overtime then
			self:DelActivityTick(actId,"tsec")
			self:SetActivityParam(newId,1,0)
			return
		end
	end
end
function eLingyuActivity:OnTimer_Second(actId,minute,hminute,hour)
	if not actId or actId >= 0 then
		return
	end
	local newId = -1 * actId
	if newId ~= self.actId then
		return
	end
	if self:GetActivityParam(newId,1) == 1 then
		local value = self:GetActivityParam(newId,2)
		if value > 1 then
			value = value - 1
			self:SetActivityParam(newId,2,value)
		else
			self:SetActivityParam(newId,2,self.update_min_monster_time)
			self:CreateMonsters(actId)
		end
	end
end
function eLingyuActivity:CreatePlatform(actId,del_time)
	if not actId or actId >= 0 then
		return
	end
	local newId = -1 * actId
	if newId ~= self.actId then
		return
	end
    for _, Data in pairs(self.g_BossData) do
        Data["NeedCreate"] = 1
    end
    for _, BossData in pairs(self.g_BossData) do
        if BossData["NeedCreate"] == 1 then
			local monsterId = self:LuaFnCreateMonster(
                BossData["ID"],
                BossData["PosX"],
                BossData["PosY"],
                BossData["BaseAI"],
                BossData["ExtAIScript"],
                BossData["ScriptID"]
            )
			if monsterId then
				self:SetCharacterDieTime(monsterId,del_time)
			end
        end
    end
end
function eLingyuActivity:CreateMonsters(actId)
	if not actId or actId >= 0 then
		return
	end
	local newId = -1 * actId
	if newId ~= self.actId then
		return
	end
	if self:GetActivityParam(newId,1) == 1 then
		local del_time = self.update_min_monster_time * 1000 - 1000
		for _, boss in ipairs(self.g_BossData) do
			local x = boss["PosX"]
			local y = boss["PosY"]
			for _, g in ipairs(self.MonsterGroup) do
				for i = 1, g.Num do
					local nx = x + math.random(4, 6)
					local ny = y + math.random(4, 6)
					local monsterid = self:LuaFnCreateMonster(g.ID, nx, ny, 4, define.INVAILD_ID, define.INVAILD_ID)
					if monsterid then
						self:SetCharacterDieTime(monsterid,del_time)
					end
				end
			end
		end
	end
end
return eLingyuActivity
