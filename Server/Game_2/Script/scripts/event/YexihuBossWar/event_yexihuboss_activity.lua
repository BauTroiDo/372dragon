local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
-- local packet_def = require "game.packet"
local script_base = require "script_base"
local event_yexihuboss_activity = class("event_yexihuboss_activity", script_base)
-- local gbk = require "wire_charset"
--手动配置项
event_yexihuboss_activity.BossName = "Doanh Chính"
event_yexihuboss_activity.BossTitle = "Ta thống nhất thiên hạ, si mê thuật trường sinh~ bi thay~"




--不可配置项，相关配置请到GM工具操作
event_yexihuboss_activity.script_id = 999998
event_yexihuboss_activity.ActId = 394
event_yexihuboss_activity.DataValidator = 0

--夜西湖缺省定义
event_yexihuboss_activity.NeedLevel = 100
event_yexihuboss_activity.NeedMaxhp = 10000
event_yexihuboss_activity.NeedSceneId = 0
event_yexihuboss_activity.LongTime = 7200
event_yexihuboss_activity.BossMaxhp = 2100000000

event_yexihuboss_activity.nPaoDianTime = 0
event_yexihuboss_activity.nPaoDianLuckHuman = 0
event_yexihuboss_activity.nPaoDianLx = 0
event_yexihuboss_activity.nPaoDianCount = 0
event_yexihuboss_activity.nPaoDianLuckLx = 0
event_yexihuboss_activity.nPaoDianLuckCount = 0


event_yexihuboss_activity.BossID = 51660
event_yexihuboss_activity.BossPosX = 155
event_yexihuboss_activity.BossPosZ = 144
event_yexihuboss_activity.BossScriptID = 999997

event_yexihuboss_activity.GoBackScene = 0
event_yexihuboss_activity.GoBackPosx = 150
event_yexihuboss_activity.GoBackPosz = 150


event_yexihuboss_activity.backtopinfo = 
{
	{league_id = -1,guild_id_1 = -1,guild_id_2 = -1,guild_id_3 = -1,crystal_hold_score = 0,flag_capture_score = 0,league_name = "",guild_name_1 = "",guild_name_2 = "",guild_name_3 = ""},
	{league_id = -1,guild_id_1 = -1,guild_id_2 = -1,guild_id_3 = -1,crystal_hold_score = 0,flag_capture_score = 0,league_name = "",guild_name_1 = "",guild_name_2 = "",guild_name_3 = ""},
	{league_id = -1,guild_id_1 = -1,guild_id_2 = -1,guild_id_3 = -1,crystal_hold_score = 0,flag_capture_score = 0,league_name = "",guild_name_1 = "",guild_name_2 = "",guild_name_3 = ""},
	{league_id = -1,guild_id_1 = -1,guild_id_2 = -1,guild_id_3 = -1,crystal_hold_score = 0,flag_capture_score = 0,league_name = "",guild_name_1 = "",guild_name_2 = "",guild_name_3 = ""},
	{league_id = -1,guild_id_1 = -1,guild_id_2 = -1,guild_id_3 = -1,crystal_hold_score = 0,flag_capture_score = 0,league_name = "",guild_name_1 = "",guild_name_2 = "",guild_name_3 = ""},
	{league_id = -1,guild_id_1 = -1,guild_id_2 = -1,guild_id_3 = -1,crystal_hold_score = 0,flag_capture_score = 0,league_name = "",guild_name_1 = "",guild_name_2 = "",guild_name_3 = ""},
	{league_id = -1,guild_id_1 = -1,guild_id_2 = -1,guild_id_3 = -1,crystal_hold_score = 0,flag_capture_score = 0,league_name = "",guild_name_1 = "",guild_name_2 = "",guild_name_3 = ""},
	{league_id = -1,guild_id_1 = -1,guild_id_2 = -1,guild_id_3 = -1,crystal_hold_score = 0,flag_capture_score = 0,league_name = "",guild_name_1 = "",guild_name_2 = "",guild_name_3 = ""},
	{league_id = -1,guild_id_1 = -1,guild_id_2 = -1,guild_id_3 = -1,crystal_hold_score = 0,flag_capture_score = 0,league_name = "",guild_name_1 = "",guild_name_2 = "",guild_name_3 = ""},
	{league_id = -1,guild_id_1 = -1,guild_id_2 = -1,guild_id_3 = -1,crystal_hold_score = 0,flag_capture_score = 0,league_name = "",guild_name_1 = "",guild_name_2 = "",guild_name_3 = ""},
}
event_yexihuboss_activity.bosspos = 
    { 
        --第一个水晶
        [1] = 
        {
            world_pos = {x = -1, y = -1}, --水晶位置
            league_id = 1, --占领水晶同盟id
            guild_id = 1, --占领水晶帮会id
            league_name = "Phạm vi rơi khi BOSS chết", --占领水晶同盟名称
            hp = 0, -- 写死传0
        },
        --第二个水晶
        [2] = 
        {
            world_pos = {x = -1, y = -1}, --水晶位置
            league_id = 1, --占领水晶同盟id
            guild_id = 1, --占领水晶帮会id
            league_name = "Phạm vi rơi khi BOSS chết", --占领水晶同盟名称
            hp = 0, -- 写死传0
        },
        --第三个水晶
        [3] = 
        {
            world_pos = {x = -1, y = -1}, --水晶位置
            league_id = 1, --占领水晶同盟id
            guild_id = 1, --占领水晶帮会id
            league_name = "Phạm vi rơi khi BOSS chết", --占领水晶同盟名称
            hp = 0, -- 写死传0
        },
        --第四个水晶
        [4] = 
        {
            world_pos = {x = -1, y = -1}, --水晶位置
            league_id = 1, --占领水晶同盟id
            guild_id = 1, --占领水晶帮会id
            league_name = "Phạm vi rơi khi BOSS chết", --占领水晶同盟名称
            hp = 0, -- 写死传0
        },
    }

event_yexihuboss_activity.warflag = 69
event_yexihuboss_activity.callscriptname = 68
event_yexihuboss_activity.callscript = 67
event_yexihuboss_activity.needscene = 66
event_yexihuboss_activity.startflag = 1
event_yexihuboss_activity.openflag = 2
event_yexihuboss_activity.opentime = 3
event_yexihuboss_activity.closetime = 4
event_yexihuboss_activity.longtime = 5
event_yexihuboss_activity.bossmaxhp = 6
event_yexihuboss_activity.bosscurhp = 7
event_yexihuboss_activity.needlevel = 8
event_yexihuboss_activity.needmaxhp = 9
event_yexihuboss_activity.paodiantime = 10
event_yexihuboss_activity.paodianluckhuman = 11
event_yexihuboss_activity.paodianlx = 12
event_yexihuboss_activity.paodiancount = 13
event_yexihuboss_activity.paodianlucklx = 14
event_yexihuboss_activity.paodianluckcount = 15
event_yexihuboss_activity.startminue = 16
event_yexihuboss_activity.sceneminuetick = 17
event_yexihuboss_activity.scenesectick = 18
event_yexihuboss_activity.bossobjid = 19
--20-26		weekflag
event_yexihuboss_activity.IsOpenYexihu = 27
event_yexihuboss_activity.bossid = 28
event_yexihuboss_activity.bossposx = 29
event_yexihuboss_activity.bossposz = 30
event_yexihuboss_activity.bossscriptid = 31
event_yexihuboss_activity.paodiantick = 32

event_yexihuboss_activity.dieboxcount = 33
event_yexihuboss_activity.dieboxdeltime = 34
event_yexihuboss_activity.playerboxcount = 35
event_yexihuboss_activity.playerboxprotecttime = 36

event_yexihuboss_activity.backsceneid = 37
event_yexihuboss_activity.backposx = 38
event_yexihuboss_activity.backposz = 39

-- event_yexihuboss_activity.warscenename = 40
event_yexihuboss_activity.closetimetwo = 41


--51-60 damagetop topvalue
--61-70 damagetop guid
--71-80 damagetop name
--81-90 damagetop leaguename

--91-100 killtop topvalue
--101-110 killtop guid
--111-120 killtop name
--121-130 killtop leaguename

function event_yexihuboss_activity:GetDataValidator(param1,param2)
	self.DataValidator = math.random(1,2100000000)
	return self.DataValidator
end

--*********************************
-- 战场心跳
--*********************************
function event_yexihuboss_activity:OnTimer(actId, uTime, param1)
	if not uTime or uTime ~= param1 then
		return
	elseif self.scene:get_id() ~= self:LuaFnGetCopySceneData_Param(0,self.needscene) then
		return
	end
	
	local timer = os.date("*t")
	local openflag = self.scene:get_param(self.openflag)
	if openflag > 0 then
		if timer.sec ~= self.scene:get_param(self.scenesectick) then
			self.scene:set_param(self.scenesectick,timer.sec)
			local curtick = os.time()
			local closetime = self.scene:get_param(self.closetime)
			local subtime = closetime - curtick
			if subtime > 32767 then
				subtime = 32767
			elseif subtime < 0 then
				subtime = 0
			end
			local bosscurhp = 0
			local bossposx,bossposz = 0,0
			-- local bossposx = self.scene:get_param(self.bossposx)
			-- local bossposz = self.scene:get_param(self.bossposz)
			local objId = self.scene:get_param(self.bossobjid) - 1
			local obj
			if objId >= 0 then
				local obj = self.scene:get_obj_by_id(objId)
				if obj and obj:is_alive() then
					bosscurhp = obj:get_attrib("hp")
					local world_pos = obj:get_world_pos()
					bossposx = math.floor(world_pos.x)
					bossposz = math.floor(world_pos.y)
				end
			end
			if bosscurhp > 0 then
				if subtime == 0 then
					self:LuaFnGmKillObj(objId, objId)
					bosscurhp = 0
				end
			end
			local damage = {}
			local kill = {}
			local idx = 0
			for i = 51,60 do
				idx = i - 50
				damage[idx] = {
					self.scene:get_param(i),
					self.scene:get_param(i + 10),
					self.scene:get_param(i + 20),
					self.scene:get_param(i + 30),
				}
			end
			idx = 0
			for i = 91,100 do
				idx = i - 90
				kill[idx] = {
					self.scene:get_param(i),
					self.scene:get_param(i + 10),
					self.scene:get_param(i + 20),
					self.scene:get_param(i + 30),
				}
			end
			
			local needlevel = self.scene:get_param(self.needlevel)
			local needmaxhp = self.scene:get_param(self.needmaxhp)
			local scenename = self:GetSceneName()
			local nHumanCount = self:LuaFnGetCopyScene_HumanCount()
			local pdlx,pdcount
			if bosscurhp > 0 then
				local paodiantick = self.scene:get_param(self.paodiantick)
				if curtick >= paodiantick then
					local paodiantime = self.scene:get_param(self.paodiantime)
					if paodiantime > 0 then
						paodiantick = curtick + paodiantime
						self.scene:set_param(self.paodiantick,paodiantick)
						local paodianlx = self.scene:get_param(self.paodianlx)
						local paodiancount = self.scene:get_param(self.paodiancount)
						local paodianluckhuman = self.scene:get_param(self.paodianluckhuman)
						local paodianlucklx = self.scene:get_param(self.paodianlucklx)
						local paodianluckcount = self.scene:get_param(self.paodianluckcount)
						if paodiancount > 0 then
							if paodianlx >= 1 and paodianlx <= 4 then
								pdlx = paodianlx
								pdcount = paodiancount
							end
						end
						if nHumanCount > 0 and paodianlucklx >= 1 and paodianlucklx <= 4 and paodianluckhuman > 0 and paodianluckcount > 0 then
							local luckdog = {}
							local luckid,text
							for i = 1,paodianluckhuman do
								luckid = math.random(1,nHumanCount)
								istrue = true
								if #luckdog > 0 then
									for n,m in ipairs(luckdog) do
										if m == luckid then
											istrue = false
											break
										end
									end
								end
								if istrue then
									table.insert(luckdog,luckid)
								end
							end
							if #luckdog > 0 then
								if paodianlucklx == 1 then
									for n,m in ipairs(luckdog) do
										objId = self:LuaFnGetCopyScene_HumanObjId(m)
										obj = self.scene:get_obj_by_id(objId)
										if obj then
											if obj:get_attrib("level") >= needlevel
											and obj:get_attrib("hp_max") >= needmaxhp then
												obj:add_money(paodianluckcount,"Kim tệ treo máy may mắn chiến BOSS")
												obj:notify_tips("Ngươi treo máy may mắn nhận được"..tostring(paodianluckcount).."Kim tệ.")
												text = "#PKẻ may mắn~#B["..obj:get_name().."]#Pnhận được#G"..tostring(paodianluckcount).."#PKim tệ."
												self:MonsterTalk(-1,scenename.."Chiến BOSS",text)
											end
										end
									end
								elseif paodianlucklx == 2 then
									for n,m in ipairs(luckdog) do
										objId = self:LuaFnGetCopyScene_HumanObjId(m)
										obj = self.scene:get_obj_by_id(objId)
										if obj then
											if obj:get_attrib("level") >= needlevel
											and obj:get_attrib("hp_max") >= needmaxhp then
												obj:add_jiaozi(paodianluckcount,"Giao Tử treo máy may mắn chiến BOSS")
												obj:notify_tips("Ngươi treo máy may mắn nhận được"..tostring(paodianluckcount).."Giao Tử.")
												text = "#PKẻ may mắn~#B["..obj:get_name().."]#Pnhận được#G"..tostring(paodianluckcount).."#PGiao Tử."
												self:MonsterTalk(-1,scenename.."Chiến BOSS",text)
											end
										end
									end
								elseif paodianlucklx == 3 then
									for n,m in ipairs(luckdog) do
										objId = self:LuaFnGetCopyScene_HumanObjId(m)
										obj = self.scene:get_obj_by_id(objId)
										if obj then
											if obj:get_attrib("level") >= needlevel
											and obj:get_attrib("hp_max") >= needmaxhp then
												obj:add_yuanbao(paodianluckcount, "Nguyên bảo treo máy may mắn chiến BOSS")
												obj:notify_tips("Ngươi treo máy may mắn nhận được"..tostring(paodianluckcount).."Nguyên bảo.")
												text = "#PKẻ may mắn~#B["..obj:get_name().."]#Pnhận được#G"..tostring(paodianluckcount).."#PNguyên bảo."
												self:MonsterTalk(-1,scenename.."Chiến BOSS",text)
											end
										end
									end
								elseif paodianlucklx == 4 then
									for n,m in ipairs(luckdog) do
										objId = self:LuaFnGetCopyScene_HumanObjId(m)
										obj = self.scene:get_obj_by_id(objId)
										if obj then
											if obj:get_attrib("level") >= needlevel
											and obj:get_attrib("hp_max") >= needmaxhp then
												obj:add_bind_yuanbao(paodianluckcount, "Nguyên bảo khóa treo máy may mắn chiến BOSS")
												obj:notify_tips("Ngươi treo máy may mắn nhận được"..tostring(paodianluckcount).."Nguyên bảo khóa.")
												text = "#PKẻ may mắn~#B["..obj:get_name().."]#Pnhận được#G"..tostring(paodianluckcount).."#PNguyên bảo khóa."
												self:MonsterTalk(-1,scenename.."Chiến BOSS",text)
											end
										end
									end
								end
							end
						end
					end
				end
			else
				local sorttab = function(paramx,paramz)
					return paramx[1] > paramz[1]
				end
				table.sort(damage,sorttab)
				table.sort(kill,sorttab)
				local opentime = self.scene:get_param(self.opentime)
				local closetimetwo = self.scene:get_param(self.closetimetwo)
				-- local closetime = self.scene:get_param(self.closetime)
				local closeinfo = string.format("Thời gian trận: %d giây / Kết thúc: %d giờ %d phút %d giây",
												curtick - opentime,timer.hour,timer.min,timer.sec)
				local addData = {
					actname = "yexihu_damage",
					opentime = opentime,
					closetime = closeinfo,
					topid = 0,
					topvalue = 0,
					playerguid = 0,
					playername = "",
					leaguename = "",
					warini = "Thưởng: chưa nhận"
				}
				local lsint,lsstr
				local yexihu_damage = self:GetActivityWar("yexihu_damage",false,false,"findOne",{_id = 0,warini = 0})
				if yexihu_damage then
					self:DelActivityWar("yexihu_damage")
				end
				for i,j in ipairs(damage) do
					addData.topid = i
					lsint = j[1]
					addData.topvalue = lsint
					lsint = j[2]
					addData.playerguid = lsint
					lsstr = j[3]
					addData.playername = lsstr
					lsstr = j[4]
					addData.leaguename = lsstr
					self:SetActivityWar(addData)
				end
				addData.actname = "yexihu_kill"
				local yexihu_kill = self:GetActivityWar("yexihu_kill",false,false,"findOne",{_id = 0,warini = 0})
				if yexihu_kill then
					self:DelActivityWar("yexihu_kill")
				end
				for i,j in ipairs(kill) do
					addData.topid = i
					lsint = j[1]
					addData.topvalue = lsint
					lsint = j[2]
					addData.playerguid = lsint
					lsstr = j[3]
					addData.playername = lsstr
					lsstr = j[4]
					addData.leaguename = lsstr
					self:SetActivityWar(addData)
				end
				local yexihu_boss = self:GetActivityWar("yexihu_boss",false,false,"findOne",{_id = 0,warini = 0})
				if yexihu_boss then
					local updatedata = {opentime = opentime,closetime = closetimetwo}
					self:UpdateActivityWar("yexihu_boss",false,false,updatedata)
				end
				self:StopOneActivity(self.ActId)
				self.scene:set_param(self.paodiantick,2147483647)
				self.scene:set_param(self.startflag,0)
				self.scene:set_param(self.openflag,0)
				local msg = "@*;SrvMsg;SCA:#B"..scenename.."#PChiến BOSS kết thúc, đại hiệp chưa nhận#Gthưởng#Pcó thể vào lại#B["..scenename.."]#Pcảnh#Gtự phát#P(#HMẹo: thưởng hạn tới trước vòng chiến BOSS sau#P)!"
				self:AddGlobalCountNews(msg)
			end
			local backscene = self.scene:get_param(self.backsceneid)
			local backposx = self.scene:get_param(self.backposx)
			local backposz = self.scene:get_param(self.backposz)
			
			local name,leaguename,guid,damagevalue
			local istrue
			local minvalue,minpos
			for i = 1,nHumanCount do
				objId = self:LuaFnGetCopyScene_HumanObjId(i)
				obj = self.scene:get_obj_by_id(objId)
				if obj then
					if obj:get_attrib("level") >= needlevel
					and obj:get_attrib("hp_max") >= needmaxhp then
						if bosscurhp > 0 then
							guid = obj:get_guid()
							name = obj:get_name()
							leaguename = obj:get_confederate_name()
							if not leaguename or leaguename == "" then
								leaguename = "Không minh hội"
							end
							-- damagevalue = obj:get_mission_data_ex_by_script_id(ScriptGlobal.MDEX_YXH_DAMAGE)
							damagevalue = obj:get_mission_data_by_script_id(ScriptGlobal.MD_DAMAGEDATA)
							obj:set_mission_data_ex_by_script_id(ScriptGlobal.MDEX_YXH_DAMAGE,damagevalue)
							if damagevalue > 0 then
								istrue = false
								minvalue = 2100000000
								minpos = 0
								for m,n in ipairs(damage) do
									if n[2] == guid then
										n[1] = damagevalue
										n[3] = name
										n[4] = leaguename
										istrue = true
										break
									elseif n[1] < minvalue then
										minvalue = n[1]
										minpos = m
									end
								end
								if not istrue and minpos > 0 and damagevalue > minvalue then
									damage[minpos][1] = damagevalue
									damage[minpos][2] = guid
									damage[minpos][3] = name
									damage[minpos][4] = leaguename
								end
							end
						end
						if pdlx and pdcount then
							if pdlx == 1 then
								obj:add_money(pdcount,"Kim tệ treo máy may mắn chiến BOSS")
								obj:notify_tips("Ngươi treo máy nhận được"..tostring(pdcount).."Kim tệ.")
							elseif pdlx == 2 then
								obj:add_jiaozi(pdcount,"Giao Tử treo máy may mắn chiến BOSS")
								obj:notify_tips("Ngươi treo máy nhận được"..tostring(pdcount).."Giao Tử.")
							elseif pdlx == 3 then
								obj:add_yuanbao(pdcount, "Nguyên bảo treo máy may mắn chiến BOSS")
								obj:notify_tips("Ngươi treo máy nhận được"..tostring(pdcount).."Nguyên bảo.")
							elseif pdlx == 4 then
								obj:add_bind_yuanbao(pdcount, "Nguyên bảo khóa treo máy may mắn chiến BOSS")
								obj:notify_tips("Ngươi treo máy nhận được"..tostring(pdcount).."Nguyên bảo khóa.")
							end
						elseif bosscurhp <= 0 then
							self:CallScriptFunction((999996), "AwardInfo",objId,0)
						end
					else
						self:NewWorld(objId,backscene,nil,backposx,backposz)
					end
				end
			end
			if pdlx and pdcount then
				if pdlx == 1 then
					text = "#Pđạt tới#G"..tostring(needlevel).."cấp#P và máu đạt#G"..tostring(needmaxhp).."#Pđại hiệp trong chiến trường nhận treo máy#G"..tostring(pdcount).."#PKim tệ."
					self:MonsterTalk(-1,scenename.."Chiến BOSS",text)
				elseif pdlx == 2 then
					text = "#Pđạt tới#G"..tostring(needlevel).."cấp#P và máu đạt#G"..tostring(needmaxhp).."#Pđại hiệp trong chiến trường nhận treo máy#G"..tostring(pdcount).."#PGiao Tử."
					self:MonsterTalk(-1,scenename.."Chiến BOSS",text)
				elseif pdlx == 3 then
					text = "#Pđạt tới#G"..tostring(needlevel).."cấp#P và máu đạt#G"..tostring(needmaxhp).."#Pđại hiệp trong chiến trường nhận treo máy#G"..tostring(pdcount).."#PNguyên bảo."
					self:MonsterTalk(-1,scenename.."Chiến BOSS",text)
				elseif pdlx == 4 then
					text = "#Pđạt tới#G"..tostring(needlevel).."cấp#P và máu đạt#G"..tostring(needmaxhp).."#Pđại hiệp trong chiến trường nhận treo máy#G"..tostring(pdcount).."#PNguyên bảo khóa."
					self:MonsterTalk(-1,scenename.."Chiến BOSS",text)
				end
			end
			for i,j in ipairs(damage) do
				self.scene:set_param(i + 50,j[1])
				self.scene:set_param(i + 60,j[2])
				self.scene:set_param(i + 70,j[3])
				self.scene:set_param(i + 80,j[4])
			end
			for i,j in ipairs(self.backtopinfo) do
				j.crystal_hold_score = bosscurhp
				j.flag_capture_score = damage[i][1]
				j.league_name = damage[i][3]
				j.guild_name_1 = damage[i][4]
				j.league_id = kill[i][1]
				j.guild_name_2 = kill[i][3]
				j.guild_name_3 = kill[i][4]
			end
			self.backtopinfo[1].guild_id_1 = subtime
			self.backtopinfo[1].guild_id_2 = bossposx
			self.backtopinfo[1].guild_id_3 = bossposz
			self:LuaFnDispatchPhoenixPlainWarScore(self.backtopinfo)
			if bossposx > 0 and bossposz > 0 then
				self.bosspos[1].world_pos.x = bossposx - 5
				self.bosspos[1].world_pos.y = bossposz - 5
				self.bosspos[2].world_pos.x = bossposx - 5
				self.bosspos[2].world_pos.y = bossposz + 5
				self.bosspos[3].world_pos.x = bossposx + 5
				self.bosspos[3].world_pos.y = bossposz - 5
				self.bosspos[4].world_pos.x = bossposx + 5
				self.bosspos[4].world_pos.y = bossposz + 5
				self:DispatchPhoenixPlainWarCrystalPos(self.bosspos)
			end
		end
	else
		if timer.min ~= self.scene:get_param(self.sceneminuetick) then
			self.scene:set_param(self.sceneminuetick,timer.min)
			local startminue = self.scene:get_param(self.startminue)
			if startminue > 0 then
				local curminue = timer.hour * 60 + timer.min
				if curminue >= startminue - 2
				and curminue <= startminue then
					local needlevel = self.scene:get_param(self.needlevel)
					local needmaxhp = self.scene:get_param(self.needmaxhp)
				
					local weektrue = true
					-- local weektrue = false
					-- if self.scene:get_param(timer.wday + 19) ~= 0 then
						-- weektrue = true
					-- end
					if weektrue then
						local scenename = self:GetSceneName()
						local subminue = startminue - curminue
						if subminue == 2 then
							self.scene:set_param(self.startflag,1)
							local msg = "#B"..scenename.."#PBOSS sẽ#G"..tostring(subminue).."phút#P sau giá lâm, đạt#G"..tostring(needlevel).."cấp#P và máu đạt#G"..tostring(needmaxhp).."#Pđại hiệp chuẩn bị! (#HMẹo: vào trước được#P)."
							self:AddGlobalCountNews(msg)
							return
						elseif subminue == 1 then
							--踢人
							--重置
							-- local backsceneid = self.scene:get_param(self.backsceneid)
							-- local backposx = self.scene:get_param(self.backposx)
							-- local backposz = self.scene:get_param(self.backposz)
							-- local human
							-- local nHumanCount = self:LuaFnGetCopyScene_HumanCount()
							-- for i = 1,nHumanCount do
								-- local nHumanId = self:LuaFnGetCopyScene_HumanObjId(i)
								-- human = self.scene:get_obj_by_id(nHumanId)
								-- if human and human:is_alive() then
									-- self:NewWorld(nHumanId,backsceneid,nil,backposx,backposz)
								-- end
							-- end
							
							
							self:UpdateActivityTop("zero")
							local msg = "#B"..scenename.."#PBOSS sẽ#G"..tostring(subminue).."phút#P sau giá lâm, đạt#G"..tostring(needlevel).."cấp#P và máu đạt#G"..tostring(needmaxhp).."#Pđại hiệp chuẩn bị! (#HMẹo: vào trước được#P)."
							self:AddGlobalCountNews(msg)
							return
						elseif subminue == 0 then
							local opentime = os.time()
							local longtime = self.scene:get_param(self.longtime)
							local closetime = opentime + longtime
							
							local paodiantime = self.scene:get_param(self.paodiantime)
							local paodiantime = paodiantime + opentime
							self.scene:set_param(self.paodiantick,paodiantime)
							local bossid = self.scene:get_param(self.bossid)
							local bossposx = self.scene:get_param(self.bossposx)
							local bossposz = self.scene:get_param(self.bossposz)
							local bossscriptid = self.scene:get_param(self.bossscriptid)
							local bossmaxhp = self.scene:get_param(self.bossmaxhp)
							self.scene:set_param(self.bosscurhp,bossmaxhp)
							local mostercount = self:GetMonsterCount()
							local objId,dataId,obj
							for i = 1,mostercount do
								objId = self:GetMonsterObjID(i)
								obj = self.scene:get_obj_by_id(objId)
								if obj then
									dataId = obj:get_model()
									if dataId == bossid
									or dataId == 99998
									or dataId == 99999
									or dataId == 52338 then
										self.scene:delete_temp_monster(obj)
									end
								end
							end
							
							objId = self:LuaFnCreateMonster(bossid,bossposx,bossposz,3,0,bossscriptid)
							if objId and objId ~= -1 then
								self.scene:set_param(self.bossobjid,objId + 1)
								-- self:SetCharacterDieTime(objId, longtime * 1000 + 60000)
								self:SetCharacterName(objId, self.BossName)
								self:SetCharacterTitle(objId,self.BossTitle)
								self:LuaFnSetLifeTimeAttrRefix_MaxHP(objId,bossmaxhp)
								self:RestoreHp(objId)
							end
							self.scene:set_param(self.opentime,opentime)
							self.scene:set_param(self.closetime,closetime)
							self.scene:set_param(self.closetimetwo,closetime)
							self.scene:set_param(self.startflag,0)
							self.scene:set_param(self.openflag,1)
							-- self.scene:set_param(self.warscenename,scenename)
							-- self.scene:set_param(self.IsOpenYexihu,1)
							local nHumanCount = self:LuaFnGetCopyScene_HumanCount()
							for i = 1,nHumanCount do
								objId = self:LuaFnGetCopyScene_HumanObjId(i)
								self:CallScriptFunction((999995), "OnBossWarScene",objId)
							end
							local msg = "@*;SrvMsg;SCA:#B"..scenename.."#PBOSS giá lâm tại#B["..scenename..","..tostring(bossposx)..","..tostring(bossposz).."]#P, đạt tới#G"..tostring(needlevel).."cấp#P và máu đạt#G"..tostring(needmaxhp).."#Pđại hiệp có thể vào trận bất cứ lúc nào!"
							self:AddGlobalCountNews(msg)
							return
						end
					end
				else
					if self.scene:get_param(self.startflag) > 0 then
						self.scene:set_param(self.startflag,0)
					end
				end
			end
			-- if self.scene:get_param(self.IsOpenYexihu) == 1 then
				-- self.scene:set_param(self.IsOpenYexihu,0)
				-- self:UpdateActivityTop("getsec")
			-- end
		end
	end
end
--*********************************
-- 更新战场排行数据
--*********************************
function event_yexihuboss_activity:UpdateActivityTop(paramx)
	if paramx ~= "getsec" and paramx ~= "zero" then return end
	for i = 51,70 do
		self.scene:set_param(i,0)
	end
	for i = 91,110 do
		self.scene:set_param(i,0)
	end
	for i = 71,80 do
		self.scene:set_param(i,"Trống trải chờ mong")
	end
	for i = 111,120 do
		self.scene:set_param(i,"Trống trải chờ mong")
	end
	for i = 81,90 do
		self.scene:set_param(i,"Không minh hội")
	end
	for i = 121,130 do
		self.scene:set_param(i,"Không minh hội")
	end
	if paramx == "getsec" then
		local yexihu_damage = self:GetActivityWar("yexihu_damage",false,false,"findAll",{_id = 0,warini = 0})
		if yexihu_damage then
			for i,j in ipairs(yexihu_damage) do
				self.scene:set_param(i + 50,j.topvalue)
				self.scene:set_param(i + 60,j.playerguid)
				self.scene:set_param(i + 70,j.playername)
				self.scene:set_param(i + 80,j.leaguename)
			end
		end
		local yexihu_kill = self:GetActivityWar("yexihu_kill",false,false,"findAll",{_id = 0,warini = 0})
		if yexihu_kill then
			for i,j in ipairs(yexihu_kill) do
				self.scene:set_param(i + 90,j.topvalue)
				self.scene:set_param(i + 100,j.playerguid)
				self.scene:set_param(i + 110,j.playername)
				self.scene:set_param(i + 120,j.leaguename)
			end
		end
	end
end
--*********************************
-- 加载战场数据
--*********************************
function event_yexihuboss_activity:LoadActivity(paramx,paramz)
	if paramx ~= "load" then return end
	local yexihu_boss = self:GetActivityWar("yexihu_boss",false,false,"findOne",{_id = 0})
	if yexihu_boss then
		-- self.scene:set_param(self.IsOpenYexihu,0)
		self.scene:set_param(self.sceneminuetick,-1)
		self.scene:set_param(self.scenesectick,-1)
		
		self.scene:set_param(self.startflag,0)
		self.scene:set_param(self.openflag,0)
		self.scene:set_param(self.bossobjid,0)
		local warini = yexihu_boss.warini
		self:LuaFnSetCopySceneData_Param(0,self.needscene,warini.needscene)
		self:LuaFnSetCopySceneData_Param(0,self.callscript,warini.callscript)
		self:LuaFnSetCopySceneData_Param(0,self.callscriptname,warini.callscriptname)
		self:LuaFnSetCopySceneData_Param(0,self.warflag,2)

		
		-- self.scene:set_param(self.needscene,warini.needscene)
		self.scene:set_param(self.opentime,yexihu_boss.opentime)
		self.scene:set_param(self.longtime,warini.longtime)
		self.scene:set_param(self.closetime,warini.longtime)
		self.scene:set_param(self.bossid,warini.bossid)
		self.scene:set_param(self.bossposx,warini.bossposx)
		self.scene:set_param(self.bossposz,warini.bossposz)
		self.scene:set_param(self.bossscriptid,warini.bossscriptid)
		self.scene:set_param(self.bossmaxhp,warini.bossmaxhp)
		self.scene:set_param(self.bosscurhp,warini.bossmaxhp)
		self.scene:set_param(self.needlevel,warini.needlevel)
		self.scene:set_param(self.needmaxhp,warini.needmaxhp)
		self.scene:set_param(self.paodiantime,warini.paodiantime)
		self.scene:set_param(self.paodiantick,warini.paodiantime)
		self.scene:set_param(self.paodianluckhuman,warini.paodianluckhuman)
		self.scene:set_param(self.paodianlx,warini.paodianlx)
		self.scene:set_param(self.paodiancount,warini.paodiancount)
		self.scene:set_param(self.paodianlucklx,warini.paodianlucklx)
		self.scene:set_param(self.paodianluckcount,warini.paodianluckcount)
		self.scene:set_param(self.startminue,warini.startminue)
		
		self.scene:set_param(self.dieboxcount,warini.dieboxcount)
		self.scene:set_param(self.playerboxcount,warini.playerboxcount)
		self.scene:set_param(self.playerboxprotecttime,warini.playerboxprotecttime)
		self.scene:set_param(self.dieboxdeltime,warini.dieboxdeltime)
		
		self.scene:set_param(self.backsceneid,warini.backsceneid)
		self.scene:set_param(self.backposx,warini.backposx)
		self.scene:set_param(self.backposz,warini.backposz)
		local idx
		for i = 20,26 do
			idx = "week"..(i - 19)
			self.scene:set_param(i,warini[idx])
		end
		self:UpdateActivityTop("getsec")
		return 1
	else
		if paramz then
			return 0
		end
		-- self:LuaFnSetCopySceneData_Param(0,self.needscene,self.NeedSceneId)
		-- -- self.scene:set_param(self.needscene,self.NeedSceneId)
		-- self.scene:set_param(self.opentime,0)
		-- self.scene:set_param(self.longtime,self.LongTime)
		-- self.scene:set_param(self.closetime,self.LongTime)
		-- self.scene:set_param(self.bossid,self.BossID)
		-- self.scene:set_param(self.bossposx,self.BossPosX)
		-- self.scene:set_param(self.bossposz,self.BossPosZ)
		-- self.scene:set_param(self.bossscriptid,self.BossScriptID)
		-- self.scene:set_param(self.bossmaxhp,self.BossMaxhp)
		-- self.scene:set_param(self.bosscurhp,self.BossMaxhp)
		-- self.scene:set_param(self.needlevel,self.NeedLevel)
		-- self.scene:set_param(self.needmaxhp,self.NeedMaxhp)
		-- self.scene:set_param(self.paodiantime,self.nPaoDianTime)
		-- self.scene:set_param(self.paodiantick,self.nPaoDianTime)
		-- self.scene:set_param(self.paodianluckhuman,self.nPaoDianLuckHuman)
		-- self.scene:set_param(self.paodianlx,self.nPaoDianLx)
		-- self.scene:set_param(self.paodiancount,self.nPaoDianCount)
		-- self.scene:set_param(self.paodianlucklx,self.nPaoDianLuckLx)
		-- self.scene:set_param(self.paodianluckcount,self.nPaoDianLuckCount)
		-- self.scene:set_param(self.startminue,0)
		-- self.scene:set_param(self.dieboxcount,0)
		-- self.scene:set_param(self.playerboxcount,0)
		-- self.scene:set_param(self.playerboxprotecttime,0)
		-- self.scene:set_param(self.dieboxdeltime,0)
		-- self.scene:set_param(self.backsceneid,self.GoBackScene)
		-- self.scene:set_param(self.backposx,self.GoBackPosx)
		-- self.scene:set_param(self.backposz,self.GoBackPosz)
		
		-- for i = 20,26 do
			-- self.scene:set_param(i,0)
		-- end
		-- self:UpdateActivityTop("zero")
		local scenename = "Chiến trường tại:"..self:GetSceneName()
		local addData = {
			actname = "yexihu_boss",
			opentime = 0,
			closetime = self.LongTime,
			topid = 0,
			topvalue = 0,
			playerguid = 0,
			playername = scenename,
			leaguename = "Cấu hình chiến trường ở warini",
			warini = {
				-- openflag = 0,
				needlevel = self.NeedLevel,
				needmaxhp = self.NeedMaxhp,
				needscene = self.NeedSceneId,
				paodiantime = self.nPaoDianTime,
				paodianluckhuman = self.nPaoDianLuckHuman,
				paodianlx = self.nPaoDianLx,
				paodiancount = self.nPaoDianCount,
				paodianlucklx = self.nPaoDianLuckCount,
				paodianluckcount = self.nPaoDianLuckCount,
				startminue = 0,
				longtime = self.LongTime,
				bossid = self.BossID,
				bossposx = self.BossPosX,
				bossposz = self.BossPosZ,
				bossscriptid = self.BossScriptID,
				bossmaxhp = self.BossMaxhp,
				dieboxcount = 0,
				playerboxcount = 0,
				playerboxprotecttime = 0,
				dieboxdeltime = 0,
				backsceneid = self.GoBackScene,
				backposx = self.GoBackPosx,
				backposz = self.GoBackPosz,
				week1 = 0,
				week2 = 0,
				week3 = 0,
				week4 = 0,
				week5 = 0,
				week6 = 0,
				week7 = 0,
				
				callscript = 999995,
				callscriptname = "OnBossWarScene",
			},
		}
		self:SetActivityWar(addData)
		return 2
	end
	return 0
end
function event_yexihuboss_activity:OnDefaultEvent(actId, iNoticeType, param2, param3, param4, param5, param6)
	if param6 ~= self.DataValidator then
		return
	elseif not iNoticeType or not param2 or not param3 or not param4 or not param5 then
		return
	-- elseif self.scene:get_id() ~= self.scene:get_param(1) then
		-- return
	end
	self:StopOneActivity(actId)
	self:LoadActivity("load",true)
    -- self:StartOneActivity(actId,2100000000,iNoticeType)
end



return event_yexihuboss_activity
