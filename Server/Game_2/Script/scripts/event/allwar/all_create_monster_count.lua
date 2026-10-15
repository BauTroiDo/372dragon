local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local all_create_monster_count = class("all_create_monster_count", script_base)
-- local gbk = require "wire_charset"
--非配置信息
all_create_monster_count.script_id = 900064
all_create_monster_count.DataValidator = 0
all_create_monster_count.needsceneId = 420
all_create_monster_count.needsactId = 401

all_create_monster_count.actinfo_250706 = 
{
	[420] = {
		{
			boss_scriptid = 999965,monstername = "",monstertitle = "Vệ binh Trùng Lâu",
			monsterId = 11392,monsterHp = 0,respawn_time = 6000,
			ReputationID = 29,
			--怪物刷新坐标，有多少个刷多少只
			posinfo = 
			{
				{posx = 36,posz = 39},
				{posx = 30,posz = 148},
				{posx = 35,posz = 259},
				{posx = 283,posz = 119},
			}
		},
	},
	[394] = {
		{
			boss_scriptid = 501000,monstername = "",monstertitle = "Thiên Niên Thiên Thánh Thú",
			monsterId = 11353,monsterHp = 0,respawn_time = 3600,
			ReputationID = 29,base_ai = 22,no_log = true,
			--怪物刷新坐标，有多少个刷多少只
			posinfo = 
			{
				{posx = 172,posz = 34},
			}
		},
		{
			boss_scriptid = 808067,monstername = "白蟒宝箱",monstertitle = "",
			monsterId = 5011,monsterHp = 0,respawn_time = 3600,
			base_ai = 3,no_log = true,
			--怪物刷新坐标，有多少个刷多少只
			posinfo = 
			{
				{posx = 142,posz = 112},
			}
		},
	},


}

function all_create_monster_count:OnDefaultEvent(actId, iNoticeType, param2, param3, param4, param5, param6)
	if param6 ~= self.DataValidator then
		return
	elseif not iNoticeType or not param2 or not param3 or not param4 or not param5 then
		return
	end
	local sceneId = self.scene:get_id()
	if sceneId == self.needsceneId and actId == self.needsactId then
		self:StartOneActivity(actId,2100000000,iNoticeType,-1)
	end
end
function all_create_monster_count:GetDataValidator(param1,param2)
	self.DataValidator = math.random(1,2100000000)
	return self.DataValidator
end
function all_create_monster_count:CheckMonsterRespawn(cur_time)
	local scene = self:get_scene()
	local sceneId = scene:get_id()
	local actinfo_250706 = self.actinfo_250706[sceneId]
	if actinfo_250706 then
		local value,objId,obj,bossname,bosstitle
		local base_ai
		local script_ai
		local script_id
		local monsterHp
		local moster_id
		local respawn_time
		local no_log,doc,ReputationID
		local startid,boss_index
		for index,info in ipairs(actinfo_250706) do
			base_ai = info.base_ai or 0
			script_ai = info.script_ai or 0
			script_id = info.script_id or -1
			monsterHp = info.monsterHp or 0
			moster_id = info.monsterId
			respawn_time = info.respawn_time
			bossname = info.monstername
			bosstitle = info.monstertitle
			ReputationID = info.ReputationID
			startid = index * 1000
			for i,boss_pos in ipairs(info.posinfo) do
				boss_index = startid + i
				value = scene:get_param(boss_index)
				if value >= 0 and value <= cur_time then
					objId = self:LuaFnCreateMonster(moster_id,boss_pos.posx,boss_pos.posz,base_ai,script_ai,script_id,90)
					obj = scene:get_obj_by_id(objId)
					if obj then
						scene:set_param(boss_index,-1)
						obj:set_scene_params(define.MONSTER_CREATE_INDEX,boss_index)
						obj:set_scene_params(define.MONSTER_KILLBOX_PROTECT_TIME,respawn_time)
						obj:set_scene_params(define.MONSTER_DATAID,moster_id)
						if monsterHp > 0 then
							self:LuaFnSetLifeTimeAttrRefix_MaxHP(objId,monsterHp)
							self:RestoreHp(objId)
						end
						if bossname ~= "" then
							self:SetCharacterName(objId,bossname)
						end
						if bosstitle ~= "" then
							self:SetCharacterTitle(objId,bosstitle)
						end
						if ReputationID then
							self:SetUnitReputationID(objId,objId,ReputationID)
						end
						-- if not no_log then
								doc = {
								fun_name = "CheckMonsterRespawn",
								sceneId = sceneId,
								bossid = moster_id,
								posx = boss_pos.posx,
								posz = boss_pos.posz,
								date_time = os.date("%y-%m-%d %H:%M:%S")
							}
							local collection = "log_create_boss"
							self:SetGameLog(collection,doc)
						-- end
					end
				end
			end
		end
	end
end
function all_create_monster_count:OnTimer_Second(actId,minute,hminute,hour)
	if not actId or actId >= 0 then
		return
	end
	local cur_time = os.time()
	local sceneId = self:GetSceneID()
	for sid,info in pairs(self.actinfo_250706) do
		if sid ~= sceneId then
			self:CallDestSceneFunctionEx(sid,self.script_id,"CheckMonsterRespawn",cur_time)
		else
			self:CheckMonsterRespawn(cur_time)
		end
	end
end

function all_create_monster_count:OnTimer(actId, uTime, param1)
end

return all_create_monster_count