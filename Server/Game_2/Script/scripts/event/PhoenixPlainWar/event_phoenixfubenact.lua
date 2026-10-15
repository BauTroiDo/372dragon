local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local event_phoenixfubenact = class("event_phoenixfubenact", script_base)
local gbk = require "wire_charset"
event_phoenixfubenact.script_id = 403013

event_phoenixfubenact.DataValidator = 0
event_phoenixfubenact.NeedSceneId = 191

event_phoenixfubenact.TimeTick = -1
event_phoenixfubenact.StartTime1 = 600				--小时 * 60 + 分钟
event_phoenixfubenact.StartTime2 = 840				--小时 * 60 + 分钟
event_phoenixfubenact.StartTime3 = 1320				--小时 * 60 + 分钟
event_phoenixfubenact.UpdateCount = 20
event_phoenixfubenact.MonsterId = 13786
event_phoenixfubenact.ScriptId = 403014


function event_phoenixfubenact:OnTimer(actId, uTime, param1)
	if not uTime or uTime ~= param1 then
		return
	end
	local curmin = self:GetMinute()
	if self.TimeTick == curmin then
		return
	end
	self.TimeTick = curmin
	local sceneId = self:GetSceneID()
	if sceneId ~= self.NeedSceneId then return end
	local curhour = self:GetHour()
	local curtime = curhour * 60 + curmin
	local timetab = {self.StartTime1,self.StartTime2,self.StartTime3,
				self.StartTime1 + 20,self.StartTime2 + 20,self.StartTime3 + 20,
				self.StartTime1 + 40,self.StartTime2 + 40,self.StartTime3 + 40,
				}
	local isupdate = false
	for i,j in ipairs(timetab) do
		if curtime == j then
			isupdate = true
			break
		end
	end
	if isupdate then
		local PosxTab = {81,92,107,108,107,91,91,79,88,96,91,91,91,78,103,109,107,143,157,172,192,211,212,211,228,240,224,230,229,237,226,201,165,153,126,137,151,160,171,189,194,203,207,190,164,176,186,139,116,112,110,119,107,147,151,163,174,176,171,162};
		local PoszTab = {212,212,211,226,239,197,178,165,154,152,136,127,107,107,106,96,80,93,87,91,90,92,79,105,107,107,130,147,164,159,187,223,236,226,228,212,200,210,200,204,219,204,181,155,131,118,121,111,104,119,130,145,161,159,173,176,170,158,148,145};
		local posx,posz,objId,index
		for i = 1,self.UpdateCount do
			index = math.random(1,#PosxTab)
			posx = PosxTab[index]
			posz = PoszTab[index]
			if posx and posz then
				table.remove(PosxTab,index)
				table.remove(PoszTab,index)
				objId = self:LuaFnCreateMonster(self.MonsterId,posx,posz,3,0,self.ScriptId)
				if objId >= 0 then
					self:MonsterAI_SetIntParamByIndex(objId,1,sceneId)
					self:MonsterAI_SetIntParamByIndex(objId,2,actId + 1)
				end
			end
		end
		local msg = "#{FHGC_090706_01}"
		self:SceneBroadcastMsg(msg)
	end
end

function event_phoenixfubenact:OnDefaultEvent(actId, iNoticeType, param2, param3, param4, param5, param6)
	if param6 ~= self.DataValidator then
		return
	elseif not iNoticeType or not param2 or not param3 or not param4 or not param5 then
		return
	end
    self:StartOneActivity(actId, 100 * 10, iNoticeType)
end
function event_phoenixfubenact:GetDataValidator(param1,param2)
	self.DataValidator = math.random(1,2100000000)
	return self.DataValidator
end
return event_phoenixfubenact
