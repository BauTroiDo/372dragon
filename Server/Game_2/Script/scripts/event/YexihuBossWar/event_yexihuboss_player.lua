local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local event_yexihuboss_player = class("event_yexihuboss_player", script_base)

event_yexihuboss_player.script_id = 999995
function event_yexihuboss_player:OnBossWarScene(selfId)
	local obj = self.scene:get_obj_by_id(selfId)
	if not obj then
		return
	end
	local sceneId = self.scene:get_id()
	local warscene = self:LuaFnGetCopySceneData_Param(0,66)
	if sceneId ~= warscene then
		return
	end
	local warstart = self.scene:get_param(1)
	local waring = self.scene:get_param(2)
	local scenename = self:GetSceneName()
	-- if warstart > 0 and waring == 0 then
		-- local msg = scenename.."BOSS战即将开启，请留意系统开启公告再进场！"
		-- -- self:notify_tips( selfId,msg )
		 -- obj:notify_tips(msg)
		-- local backscene = self.scene:get_param(37)
		-- local backposx = self.scene:get_param(38)
		-- local backposz = self.scene:get_param(39)
		-- if backposx > 0 and backposz > 0 then
			-- self:NewWorld(selfId,backscene,nil,backposx,backposz)
		-- else
			-- self:NewWorld(selfId,0,nil,111,111)
		-- end
		-- return
	if waring > 0 then
		local mylv = obj:get_attrib("level")
		local myhp = obj:get_attrib("hp_max")
		local needlv = self.scene:get_param(8)
		local needhp = self.scene:get_param(9)
		local msg = ""
		if mylv < needlv then
			msg = scenename.."Cấp yêu cầu tham gia chiến BOSS đạt"..tostring(needlv).."cấp!\\nBạn không tham gia được, lát nữa sẽ mời rời chiến trường."
			-- local msg = scenename.."BOSS战参与需求等级达"..tostring(needlv).."级！"
			 -- obj:notify_tips(msg)
			-- local backscene = self.scene:get_param(37)
			-- local backposx = self.scene:get_param(38)
			-- local backposz = self.scene:get_param(39)
			-- if backposx > 0 and backposz > 0 then
				-- self:NewWorld(selfId,backscene,nil,backposx,backposz)
			-- else
				-- self:NewWorld(selfId,0,nil,111,111)
			-- end
			-- return
		elseif myhp < needhp then
			msg = scenename.."Máu tối thiểu tham gia chiến BOSS là"..tostring(needhp).."!\\nBạn không tham gia được, lát nữa sẽ mời rời chiến trường."
			 -- obj:notify_tips(msg)
			-- local backscene = self.scene:get_param(37)
			-- local backposx = self.scene:get_param(38)
			-- local backposz = self.scene:get_param(39)
			-- if backposx > 0 and backposz > 0 then
				-- self:NewWorld(selfId,backscene,nil,backposx,backposz)
			-- else
				-- self:NewWorld(selfId,0,nil,111,111)
			-- end
			-- return
		end
		if msg == "" then
			local opentime = self.scene:get_param(3)
			local playertime = obj:get_mission_data_ex_by_script_id(ScriptGlobal.MDEX_YXH_ONTIME)
			local damage,killnum = 0,0
			if opentime ~= playertime then
				obj:set_mission_data_ex_by_script_id(ScriptGlobal.MDEX_YXH_DAMAGE,damage)
				obj:set_mission_data_ex_by_script_id(ScriptGlobal.MDEX_YXH_KILLNUM,killnum)
				obj:set_mission_data_ex_by_script_id(ScriptGlobal.MDEX_YXH_ONTIME,opentime)
			else
				damage = obj:get_mission_data_ex_by_script_id(ScriptGlobal.MDEX_YXH_DAMAGE)
				killnum = obj:get_mission_data_ex_by_script_id(ScriptGlobal.MDEX_YXH_KILLNUM)
			end
			local bossid = self.scene:get_param(19)
			obj:set_mission_data_by_script_id(ScriptGlobal.MD_DAMAGEDATA,damage)
			obj:set_mission_data_by_script_id(ScriptGlobal.MD_DAMAGENEEDSCENE,sceneId + 1)
			obj:set_mission_data_by_script_id(ScriptGlobal.MD_DAMAGEOBJID,bossid)
		else
			self:BeginEvent(self.script_id)
			self:AddText(msg)
			self:EndEvent()
			self:DispatchEventList(selfId,selfId)
		end
		local bosshp = self.scene:get_param(6)
		-- local boss = self.scene:get_obj_by_id(bossid - 1)
		-- if boss then
			-- bosshp = obj:get_attrib("hp_max")
		-- end
		self:BeginUICommand()
		self:UICommand_AddInt(209042021)
		self:UICommand_AddInt(bosshp)
		self:EndUICommand()
		self:DispatchUICommand(selfId,209042021)
	end
	self:CallScriptFunction((999996), "AwardInfo",selfId,0)
end

function event_yexihuboss_player:OnSceneHumanDie(selfId,killerId)
	local sceneId = self.scene:get_id()
	local warscene = self:LuaFnGetCopySceneData_Param(0,66)
	if sceneId ~= warscene then
		return
	end
	local selfobj = self.scene:get_obj_by_id(selfId)
	if not selfobj then
		return
	end
	local selflv = selfobj:get_attrib("level")
	local selfhp = selfobj:get_attrib("hp_max")
	local needlevel = self.scene:get_param(8)
	local needmaxhp = self.scene:get_param(9)
	local targetId = killerId
	local tarobj = self.scene:get_obj_by_id(targetId)
	if not tarobj then
		return
	end
	if tarobj:get_obj_type() == "pet" then
		targetId = tarobj:get_owner_obj_id()
		tarobj = self.scene:get_obj_by_id(targetId)
		if not tarobj then
			return
		end
	end
	local tarlv = tarobj:get_attrib("level")
	local tarhp = tarobj:get_attrib("hp_max")
    --防止自杀情况
    if selfId == targetId then
        return
    end
	if tarlv < needlevel or tarhp < needmaxhp then
		return
	elseif selflv < needlevel or selfhp < needmaxhp then
		tarobj:notify_tips("Giết không hợp lệ, người bị giết thiếu cấp hoặc máu chưa đạt")
		return
	end
	local waring = self.scene:get_param(2)
	if waring > 0 then
		local tarname,iseffective = self:GetKillEffective(selfId,targetId,10)
		if iseffective then
			local maxkillnum = 32767
			local tarkillnum = tarobj:get_mission_data_ex_by_script_id(ScriptGlobal.MDEX_YXH_KILLNUM) + 1
			if tarkillnum > maxkillnum then
				tarkillnum = maxkillnum
			end
			tarobj:set_mission_data_ex_by_script_id(ScriptGlobal.MDEX_YXH_KILLNUM,tarkillnum)
			local targuid = tarobj:get_guid()
			-- local tarname = tarobj:get_name()
			local leaguename = tarobj:get_confederate_name()
			if not leaguename or leaguename == "" then
				leaguename = "Không minh hội"
			end
			local toppos = 0
			for i = 101,110 do
				if self.scene:get_param(i) == targuid then
					toppos = i
					self.scene:set_param(i - 10,tarkillnum)
					self.scene:set_param(i + 10,tarname)
					self.scene:set_param(i + 20,leaguename)
					break
				end
			end
			if toppos == 0 then
				for i = 91,100 do
					local topkillnum = self.scene:get_param(i)
					if topkillnum < maxkillnum then
						maxkillnum = topkillnum
						toppos = i
					end
				end
				if tarkillnum > maxkillnum and toppos > 0 then
					self.scene:set_param(toppos,tarkillnum)
					self.scene:set_param(toppos + 10,targuid)
					self.scene:set_param(toppos + 20,tarname)
					self.scene:set_param(toppos + 30,leaguename)
				end
			end
			if tarkillnum >= 10 and tarkillnum % 10 == 0 then
				local scenename = self:GetSceneName()
				local Msg = string.format("#{_INFOUSR%s} với khí thế không ai cản nổi, chém %d địch.",tarname,tarkillnum)
				self:MonsterTalk(-1,scenename.."Chiến BOSS",Msg)
			end
		else
			self:BeginEvent(self.script_id)
			self:AddText("Giết không hợp lệ (trong 10 giây)")
			self:EndEvent()
			self:DispatchMissionTips(nHumanId)
		end
	end
end

return event_yexihuboss_player
