local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local all_activity = class("all_activity", script_base)
-- local gbk = require "wire_charset"
--非配置信息
all_activity.script_id = 999970
all_activity.minutetick = define.ACTIVITY_PARAM_TICEK_MINUTE
all_activity.DataValidator = 0
all_activity.needsceneId = 159
all_activity.needsactId = 400




--集散活动触发与结束总控

	-- sceneId = 场景ID
	-- weeks = 星期 1-7  星期一 = 1 。。。 星期天 = 7
	-- boss_flag = 特殊情况  一般用在同一个场景刷不同BOSS且是同一个脚本的时候用到
	-- starthour = 开始：小时
	-- startminute = 开始：分钟
	-- actscript = 跳转脚本   999965=多点刷新BOSS  999971=单点刷新BOSS 
	-- boxtime = 弹窗持续时长(单位:秒) 0=不弹窗  > 0 则弹窗有效时长
	-- cycle_minute = 循环开启  每小时几分开启(0-59)  非循环 填 -1
	-- {sceneId = xxx,starthour = -1,startminute = -1,actscript = xxx,boxtime = 0,cycle_minute = 0,is_spcialid = 1},
all_activity.timerinfo = 
{
	--秦皇地宫四层 BOSS 星期1,3,5,6 逢21,22,23,0,1点0分刷一波BOSS N个点
	{sceneId = 1299,weeks = {2,4,6,7},starthour = 20,startminute = 0,actscript = 999965,boxtime = 0},
	{sceneId = 1299,weeks = {2,4,6,7},starthour = 21,startminute = 0,actscript = 999965,boxtime = 0},
	{sceneId = 1299,weeks = {2,4,6,7},starthour = 22,startminute = 0,actscript = 999965,boxtime = 0},
	{sceneId = 1299,weeks = {2,4,6,7},starthour = 23,startminute = 0,actscript = 999965,boxtime = 0},
	{sceneId = 1299,weeks = {2,4,6,7},starthour = 0,startminute = 0,actscript = 999965,boxtime = 0},
	{sceneId = 1299,weeks = {2,4,6,7},starthour = 21,startminute = 0,actscript = 999971,boxtime = 0},
	--{sceneId = 5,weeks = {1,2,3,4,5,6,7},starthour = -1,startminute = -1,actscript = 999965,boxtime = 0,cycle_minute = 15},
	--玄武岛终极BOSS
	--{sceneId = 1303,starthour = 21,startminute = 0,actscript = 999971,boxtime = 0},
}

all_activity.special_hour = {
	-- [1] = all_activity.timerinfo[xx].is_spcialid



}
function all_activity:OnDefaultEvent(actId, iNoticeType, param2, param3, param4, param5, param6)
	if param6 ~= self.DataValidator then
		return
	elseif not iNoticeType or not param2 or not param3 or not param4 or not param5 then
		return
	end
	local sceneId = self.scene:get_id()
	if self.scene:get_id() == self.needsceneId and actId == self.needsactId then
		self:StartOneActivity(actId,2100000000,iNoticeType,false,-1)
		self:CallDestSceneFunctionEx(0,700489,"create_paipai_npc","paipai")
		-- local skynet = require "skynet"
		-- skynet.send(".SCENE_0","lua","char_excute_Script",700489,"create_paipai_npc","paipai")
	end
end
function all_activity:GetDataValidator(param1,param2)
	self.DataValidator = math.random(1,2100000000)
	return self.DataValidator
end
function all_activity:OnTimer_Minute(actId,minute,hminute,hour)
	-- if not actId or actId >= 0 then
	-- 	return
	-- end
	-- local today = tonumber(os.date("%Y%m%d"))
	--西游BOSS活动
	--self:CallScriptFunction(999983,"CheckOpen",-1 * define.ACTIVITY_XIYOU_ID,minute,hminute,hour,today)
	--金猪赠礼
	--self:CallScriptFunction(999992,"CheckOpen",-1 * define.ACTIVITY_JINZHU_ID,minute,hminute,hour,today)
	
	-- actId = -1 * actId
	-- if #self.timerinfo > 0 then
	-- 	local openminute,overminute,kjname,istrue
	-- 	local cur_week = self:GetWeek()
	-- 	-- local skynet = require "skynet"
	-- 	for i,j in ipairs(self.timerinfo) do
	-- 		-- if hminute ~= self:GetActivityParam(actId,i) then
	-- 			-- self:SetActivityParam(actId,i,hminute)
	-- 			istrue = false
	-- 			if j.weeks then
	-- 				for _,wk in ipairs(j.weeks) do
	-- 					if wk == cur_week then
	-- 						istrue = true
	-- 						break
	-- 					end
	-- 				end
	-- 			else
	-- 				istrue = true
	-- 			end
	-- 			if istrue then
	-- 				if j.is_spcialid == 1 then
	-- 					if self.special_hour[1][hour] then
	-- 						openminute = j.cycle_minute or 0
	-- 						if minute == openminute then
	-- 							self:CallDestSceneFunctionEx(j.sceneId,j.actscript,"activity_start",0 - j.sceneId,j.boxtime)
	-- 						end
	-- 					end
	-- 				elseif j.cycle_minute and j.cycle_minute == minute then
	-- 					-- kjname = string.format(".SCENE_%d",j.sceneId)
	-- 					-- skynet.send(kjname,"lua","char_excute_Script",j.actscript,"activity_start",0 - j.sceneId,j.boxtime)
	-- 					self:CallDestSceneFunctionEx(j.sceneId,j.actscript,"activity_start",0 - j.sceneId,j.boxtime)
	-- 				else
	-- 					openminute = j.starthour * 60 + j.startminute
	-- 					if hminute == openminute then
	-- 						self:CallDestSceneFunctionEx(j.sceneId,j.actscript,"activity_start",0 - j.sceneId,j.boxtime)
	-- 						-- kjname = string.format(".SCENE_%d",j.sceneId)
	-- 						-- skynet.send(kjname,"lua","char_excute_Script",j.actscript,"activity_start",0 - j.sceneId,j.boxtime)
	-- 					end
	-- 				end
	-- 			end
	-- 		-- end
	-- 	end
	-- end
end

function all_activity:OnTimer(actId, uTime, param1)
end

return all_activity
