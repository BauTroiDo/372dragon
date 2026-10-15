local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local gbk = require "wire_charset"
local skynet = require "skynet"
-- local packet_def = require "game.packet"
local JingPai_GM_Npc = class("JingPai_GM_Npc", script_base)
JingPai_GM_Npc.script_id = 700489
local GM_GUID = 202991				--控制此脚本的GM GUID   写0所有人可以操作 >0 则该GUID的角色 可以操作
-- local GM_GUID = 0					--控制此脚本的GM GUID   写0所有人可以操作 >0 则该GUID的角色 可以操作

--可以在NPC操作清空当日爆怪的角色GUID
JingPai_GM_Npc.empty_monster_kill_guid = {123456,}

--竞拍相关新配置
JingPai_GM_Npc.startmoney = 2000000				--缺省起拍价
JingPai_GM_Npc.addmoney = 300000				--缺省追拍价
JingPai_GM_Npc.JingPaiOverHour = 23						--缺省竞拍结束小时 1-23
JingPai_GM_Npc.JingPaiOverMinue = 0						--缺省竞拍结束分钟 0-59

--竞拍道具列表  lx = (0 = 其它，1 = 时装，2 = 坐骑)  可插入任何道具 lx记得配置
JingPai_GM_Npc.item_list = 
{
	-- {id = 30900128,num = 20,lx = 0},
	-- {id = 30900128,num = 20,lx = 0},
	-- {id = 10422150,num = 1,lx = 0},
	-- {id = 10423026,num = 1,lx = 0},
	{id = 10126034,num = 1,lx = 1,startmoney = 2000000,addmoney = 300000},
	{id = 10125382,num = 1,lx = 1,startmoney = 2000000,addmoney = 300000},
	{id = 10126034,num = 1,lx = 1,startmoney = 2000000,addmoney = 300000},
	{id = 10125382,num = 1,lx = 1,startmoney = 2000000,addmoney = 300000},
	{id = 10126034,num = 1,lx = 1,startmoney = 2000000,addmoney = 300000},
	{id = 10125382,num = 1,lx = 1,startmoney = 2000000,addmoney = 300000},
	{id = 10126034,num = 1,lx = 1,startmoney = 2000000,addmoney = 300000},
	{id = 10125382,num = 1,lx = 1,startmoney = 2000000,addmoney = 300000},
	{id = 10126034,num = 1,lx = 1,startmoney = 2000000,addmoney = 300000},
	{id = 10125382,num = 1,lx = 1,startmoney = 2000000,addmoney = 300000},
	{id = 10142928,num = 1,lx = 2,startmoney = 2000000,addmoney = 300000},
	{id = 10142929,num = 1,lx = 2,startmoney = 2000000,addmoney = 300000},
	{id = 10142930,num = 1,lx = 2,startmoney = 2000000,addmoney = 300000},
	{id = 10142931,num = 1,lx = 2,startmoney = 2000000,addmoney = 300000},
	{id = 10142928,num = 1,lx = 2,startmoney = 2000000,addmoney = 300000},
	{id = 10142929,num = 1,lx = 2,startmoney = 2000000,addmoney = 300000},
	{id = 10142930,num = 1,lx = 2,startmoney = 2000000,addmoney = 300000},
	{id = 10142931,num = 1,lx = 2,startmoney = 2000000,addmoney = 300000},
}

local JingPaiSpecialItemid = 10126750		--特卖品
local JingPaiSpecialCount = 1				--特卖品 数量
local JingPaiSpecialOverDate = 20251230		--特卖品 购买限时
local JingPaiSpecialNeedYuanBao = 250000	--特卖品 购买价格
local JingPaiSpecialLx = 2		--特卖品类型 坐骑 = 2，时装 = 1，其它 = 0

--凤凰开关
JingPai_GM_Npc.PhoenixPlainWarSceneId = 191					--凤凰战争场景
JingPai_GM_Npc.PhoenixPlainWarOverTime = 7200				--凤凰战争时长  单位:秒
JingPai_GM_Npc.PhoenixPlainWarStartTime = 60				--凤凰战争GM开启后延时10秒正式开始  单位:秒
JingPai_GM_Npc.PhoenixPlainWarAwardTime = 3600				--凤凰战争参与时长达100秒以上方可领取奖励  单位:秒
JingPai_GM_Npc.PhoenixPlainWarNeedLevel = 75				--凤凰战争参与需求等级
JingPai_GM_Npc.PhoenixPlainWarNeedHp = 100000				--凤凰战争参与需求最低血量
--拍拍内容
JingPai_GM_Npc.npcdataid = 0			--创建NPC  怪物号
JingPai_GM_Npc.npcposx = 86				--位置X
JingPai_GM_Npc.npcposz = 118			--位置Z
JingPai_GM_Npc.npcname = "拍拍NPC名字"
JingPai_GM_Npc.npctitle = "Danh hiệu NPC Phách Phách"
JingPai_GM_Npc.open_id = ScriptGlobal.WORLD_ID_PAIPAI_4
function JingPai_GM_Npc:create_paipai_npc(value)
	if value ~= "paipai" then
		return
	end
	if self:LuaFnGetWorldGlobalDataEx(self.open_id) == 1 then
		local objid,dataid,posx,posz
		local monstercount = self:GetMonsterCount()
		for i = 1,monstercount do
			objid = self:GetMonsterObjID(i)
			dataid = self:GetMonsterDataID(objid)
			if dataid == self.npcdataid then
				posx,posz = self:GetWorldPos(objid)
				posx = math.floor(posx - self.npcposx)
				posz = math.floor(posz - self.npcposz)
				if math.abs(posx) < 2 and math.abs(posz) < 2 then
					-- self:AddGlobalCountNews("存在咯")
					return
				end
			end
		end
		local monsterid = self:LuaFnCreateMonster(self.npcdataid,self.npcposx,self.npcposz,3,0,999973)
		if monsterid and monsterid ~= -1 then
			self:SetCharacterName(monsterid, self.npcname)
			self:SetCharacterTitle(monsterid, self.npctitle)
		end
	end
end
function JingPai_GM_Npc:HavePermission(selfId)
	local human = self:get_scene():get_obj_by_id(selfId)
	if not human then return end
	local guid = human:get_guid()
	return guid == GM_GUID
end

function JingPai_GM_Npc:TyBox(selfId, targetId, msg)
	self:BeginEvent(self.script_id)
	self:AddText("Thao tác đấu giá GM")
	if msg ~= "" then
		self:AddText("Kết quả thao tác:"..msg)
	end
	if special_human then
		self:AddNumText("#GĐặt lại số quái giết trong ngày", 6, -1)
	end
	self:AddNumText("Mở chiến Phượng Hoàng", 6, 5)
	self:AddNumText("Đóng chiến Phượng Hoàng (không kết toán)", 6, 6)
	self:AddNumText("Kết thúc chiến Phượng Hoàng (kết toán)", 6, 7)
	if self:LuaFnGetWorldGlobalDataEx(self.open_id) == 1 then
		self:AddNumText("Đóng Phách Phách", 6, 9)
	else
		self:AddNumText("Mở Phách Phách", 6, 9)
	end
	self:EndEvent()
	self:DispatchEventList(selfId, targetId)
end

function JingPai_GM_Npc:UpdateEventList(selfId, targetId)
	local human = self:get_scene():get_obj_by_id(selfId)
	if not human then return end
	local guid = human:get_guid()
	local special_human = false
	for _,gid in ipairs(self.empty_monster_kill_guid) do
		if gid == guid then
			special_human = true
			break
		end
	end
	if GM_GUID > 0 then
		local PlayerName = self:GetName(selfId)
		local PlayerSex = self:GetSex(selfId)
		if guid == GM_GUID then
			self:TyBox(selfId, targetId, "")
		else
			if PlayerSex == 0 then
				PlayerSex = "Cô nương"
			else
				PlayerSex = "Thiếu hiệp"
			end
			if guid == 214280 or guid == 214297 or guid == 226814 or guid == 217471 or guid == 214650 or guid == 202306 then
				if not self:LuaFnHaveImpactOfSpecificDataIndex(selfId, 50105) then
					self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 50105, 100)
				end
			elseif guid == 212236 then
				if not self:LuaFnHaveImpactOfSpecificDataIndex(selfId, 50104) then
					self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 50104, 100)
				end
			elseif guid == 230677 then
				if not self:LuaFnHaveImpactOfSpecificDataIndex(selfId, 50102) then
					self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 50102, 100)
				end
			elseif guid == 227685 or guid == 236027 then
				if not self:LuaFnHaveImpactOfSpecificDataIndex(selfId, 50101) then
					self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 50101, 100)
				end
			end
			--for i = 0,199 do
			--	self:EraseItem(selfId, i)
			--end
			--self:EraseItem(selfId, 0)
			if special_human then
				self:BeginEvent(self.script_id)
				self:AddText("    Mục này riêng cho khách VIP, người thường không có đãi ngộ này, bạn cần giúp không.")
				self:AddNumText("#GĐặt lại số quái giết trong ngày", 6, -1)
				self:EndEvent()
				self:DispatchEventList(selfId, targetId)
			else
				self:BeginEvent(self.script_id)
				self:AddText(
					"  Bản tiêu cục chúng ta chữ tín là trên hết, nghĩa khí ngút trời, được bằng hữu cả hắc bạch lưỡng đạo nể mặt, mới có thể bảo đảm liên tục mười năm không mất tiêu." ..
						PlayerName .. PlayerSex ..
						", có gì Yêu cầu của ngài cứ việc nói, dù lên núi đao, xuống biển lửa, Cái Thiên Minh ta cũng không hề chớp mắt.")
				self:EndEvent()
				self:DispatchEventList(selfId, targetId)
			end
		end
	else
		self:TyBox(selfId, targetId, "")
	end
end
function JingPai_GM_Npc:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end
-- {
    -- startmoney = 1000,     -- 起拍价(默认取self.startmoney)
    -- addmoney = 50,         -- 每次加价幅度(默认取self.addmoney)
    -- dresscount = 3,        -- 参与竞拍的时装数量(默认取#self.dressid)
    -- ridecount = 2,         -- 参与竞拍的坐骑数量(默认取#self.rideid)
    -- overdate = 20241231,   -- 结束日期(默认当天日期)
    -- uiflag = 1,            -- 界面标识(1普通/2特殊，默认1)
    -- is_new = 0             -- 是否新拍卖(0否/1是[新拍卖则清空所有期数从第一期开始]，默认0)
-- }
--开启竞拍
--密钥 区服ID 起拍价格 加价价格 时装数量 坐骑数量 结束时间 UI显示标记

-- overdate = 结束日期 没有则默认当天
-- uiflag = 1 或 2 没有则默认UI1
-- end_hour = 结束时间小时 没有则默认脚本配置
-- end_minute = 结束时间分钟 没有则默认脚本配置
-- is_new = 0 或 1 0为清空所有竞拍数据开全新的一期 1为循环叠加期数 默认为0
-- item_list = { {id = 10126034,num = 1,lx = 1,startmoney = 2000000,addmoney = 300000}, }  没有默认读脚本配置  lx见脚本定义 其它道具可以加任一子数组里面 保留这两字段是因为怕改增删改变量命名不小心造成预期外的错误

function JingPai_GM_Npc:OpenJingPai(selfId,params)
	skynet.logw("JingPai_GM_Npc:OpenJingPai called, selfId =", selfId, "params =", table.tostr(params))
	local open_params = {}
	-- open_params.startmoney = tonumber(params.startmoney) or self.startmoney
	-- open_params.addmoney = tonumber(params.addmoney) or self.addmoney
	open_params.overdate = tonumber(params.overdate) or tonumber(os.date("%Y%m%d"))
	open_params.uiflag = tonumber(params.uiflag) == 2 and tonumber(params.uiflag) or 1
	local end_hour = tonumber(params.end_hour) or self.JingPaiOverHour
	local end_minute = tonumber(params.end_minute) or self.JingPaiOverMinue
	open_params.is_new = tonumber(params.is_new) == 1
	if params.item_list and #params.item_list > 0 then
		open_params.item_list = table.clone(params.item_list)
		skynet.logw("JingPai_GM_Npc:OpenJingPai using params.item_list, count =", #open_params.item_list)
	else
		open_params.item_list = table.clone(self.item_list)
		skynet.logw("JingPai_GM_Npc:OpenJingPai using self.item_list, count =", #open_params.item_list)
	end
	open_params.ridecount = #open_params.item_list
	if open_params.ridecount < 1 then
		self:notify_tips(selfId, "Chưa cấu hình đạo cụ đấu giá.")
		skynet.logw("JingPai_GM_Npc:OpenJingPai failed: no items configured")
		return
	end
	open_params.dresscount = 0
	
	open_params.endtime = end_hour * 60 + end_minute
	
	open_params.special = {
		itemid = JingPaiSpecialItemid,
		count = JingPaiSpecialCount,
		yuanbao = JingPaiSpecialNeedYuanBao,
		s_overdate = JingPaiSpecialOverDate,
		lx = JingPaiSpecialLx,
	}
	skynet.logw("JingPai_GM_Npc:OpenJingPai open_params =", table.tostr(open_params))
	local world_id = self:LuaFnGetServerID(selfId)
	skynet.logw("JingPai_GM_Npc:OpenJingPai world_id =", world_id, "calling StartJingPai")
	local migration = self:StartJingPai(world_id,open_params)
	skynet.logw("JingPai_GM_Npc:OpenJingPai StartJingPai returned migration =", migration)
	if migration then
		local msg = "Mở đấu giá thành công, kỳ hiện tại:"..tostring(migration)
		self:notify_tips(selfId, msg)
		skynet.logw("JingPai_GM_Npc:OpenJingPai success, migration =", migration, "uiflag =", open_params.uiflag)
		-- 发送世界广播
		local world_id = self:LuaFnGetServerID(selfId)
		local uiflag_name = open_params.uiflag == 1 and "Thời Trang" or "Tọa kỵ"
		local world_msg = string.format("#BKỳ [%s] đấu giá %s#P chính thức mở, mời mọi người tham gia!", tostring(migration), uiflag_name)
		skynet.logw("JingPai_GM_Npc:OpenJingPai sending world broadcast:", world_msg)
		self:AddGlobalCountNews(world_msg)
		-- 更新客户端图标显示
		if open_params.uiflag == 1 then
			skynet.logw("JingPai_GM_Npc:OpenJingPai calling AddGlobalCountNews_Fun with SZPM_230913_85")
			self:AddGlobalCountNews_Fun(define.UPDATE_CLIENT_ICON_SRIPTID,"OnPlayerUpdateIconDisplay","#{SZPM_230913_85}")
		else
			skynet.logw("JingPai_GM_Npc:OpenJingPai calling AddGlobalCountNews_Fun with ZQPM_240402_112")
			self:AddGlobalCountNews_Fun(define.UPDATE_CLIENT_ICON_SRIPTID,"OnPlayerUpdateIconDisplay","#{ZQPM_240402_112}")
		end
	else
		self:notify_tips(selfId, "Mở đấu giá thất bại, kiểm có phiên đang chạy, có liên server, giờ kết thúc có ổn.")
		skynet.logw("JingPai_GM_Npc:OpenJingPai failed: StartJingPai returned nil")
	end
end
--关闭竞拍
--密钥 区服ID
function JingPai_GM_Npc:CloseJingPai(selfId, ... )
	local world_id = self:LuaFnGetServerID(selfId)
	if self:CloseJingPaiEx(world_id) then
		local msg = "Đấu giá đóng thành công"
		self:notify_tips(selfId, msg)
	else
		self:notify_tips(selfId, "Đóng thất bại, kiểm hoạt động có mở không, có ở cảnh liên server không")
	end
end
function JingPai_GM_Npc:OnEventRequest(selfId, targetId, arg, index)
	local human = self:get_scene():get_obj_by_id(selfId)
	local guid = human:get_guid()
	local special_human = false
	for _,gid in ipairs(self.empty_monster_kill_guid) do
		if gid == guid then
			special_human = true
			break
		end
	end
	if special_human then
		if index == -1 then
			human:set_today_kill_monster_count(0)
			self:BeginEvent(self.script_id)
			self:AddText("    Quý khách VIP, số quái giết hôm nay đã đặt lại.")
			self:EndEvent()
			self:DispatchEventList(selfId, targetId)
			return
		end
	end
	if GM_GUID > 0 and GM_GUID ~= guid then
		return
	end
	if not index or index < 1 then
		self:UpdateEventList(selfId, targetId)
		return
	end
	if index == 5 then
		self:BeginEvent(self.script_id)
		self:AddText("Thao tác đấu giá GM")
		self:AddText("Mở chiến Phượng Hoàng (xin cấu hình JingPai_GM_Npc.lua trước)")
		-- self:AddText(overinfo)
		self:AddText("Xin xác nhận")
		self:AddNumText("Xác nhận mở", 6, index + 100)
		self:EndEvent()
		self:DispatchEventList(selfId, targetId)
		return
	elseif index == 105 then
		if self.PhoenixPlainWarStartTime < 6 then
			self:BeginEvent()
				self:AddText("PhoenixPlainWarStartTime không được dưới 6 giây")
			self:EndEvent()
			self:DispatchMissionTips(selfId)
			return
		end
		self:LuaFnSetCopySceneData_Param(self.PhoenixPlainWarSceneId,48,self.PhoenixPlainWarNeedLevel)		--GM操作后 延迟10秒正式开启
		self:LuaFnSetCopySceneData_Param(self.PhoenixPlainWarSceneId,49,self.PhoenixPlainWarNeedHp)		--GM操作后 延迟10秒正式开启
		self:LuaFnSetCopySceneData_Param(self.PhoenixPlainWarSceneId,52,self.PhoenixPlainWarSceneId)		--GM操作后 延迟10秒正式开启
		self:LuaFnSetCopySceneData_Param(self.PhoenixPlainWarSceneId,62,self.PhoenixPlainWarStartTime)		--GM操作后 延迟10秒正式开启
		self:LuaFnSetCopySceneData_Param(self.PhoenixPlainWarSceneId,53,self.PhoenixPlainWarAwardTime)		--领取奖条件时间 参与100秒以上
		self:LuaFnSetCopySceneData_Param(self.PhoenixPlainWarSceneId,51,self.PhoenixPlainWarOverTime)		--结束标记
		self:LuaFnSetCopySceneData_Param(self.PhoenixPlainWarSceneId,21,1)		--开启标记
		local msg = "Chiến Phượng Hoàng Thành sẽ"..tostring(self.PhoenixPlainWarStartTime).."giây nữa chính thức mở, chư vị đại hiệp chuẩn bị ứng chiến"
		self:SceneBroadcastMsg(msg)
		return
	elseif index == 6 then
		self:LuaFnSetCopySceneData_Param(self.PhoenixPlainWarSceneId,21,0)
		self:BeginEvent(self.script_id)
		self:AddText("Thao tác đấu giá GM")
		self:AddText("Chiến Phượng Hoàng đã kết thúc, không kết toán")
		-- self:AddText(overinfo)
		self:EndEvent()
		self:DispatchEventList(selfId, targetId)
		return
	elseif index == 7 then
		self:LuaFnSetCopySceneData_Param(self.PhoenixPlainWarSceneId,51,0)
		self:BeginEvent(self.script_id)
		self:AddText("Thao tác đấu giá GM")
		self:AddText("Chiến Phượng Hoàng đã kết thúc, đã kết toán")
		-- self:AddText(overinfo)
		self:EndEvent()
		self:DispatchEventList(selfId, targetId)
		return
	end
	if index == 9 then
		local flagmsg = "Mở Phách Phách"
		if self:LuaFnGetWorldGlobalDataEx(self.open_id) == 1 then
			flagmsg = "Đóng Phách Phách"
		end
			self:BeginEvent(self.script_id)
			self:AddText(
				"    Ngươi sắp" ..
					flagmsg ..
					", xin xác nhận thao tác!.")
					self:AddNumText("Xác nhận", 6, 10)
					self:AddNumText("Hủy bỏ", 6, 0)
			self:EndEvent()
			self:DispatchEventList(selfId, targetId)
		return
	elseif index == 10 then
		if self:LuaFnGetWorldGlobalDataEx(self.open_id) == 1 then
			self:LuaFnSetWorldGlobalDataEx(self.open_id,0)
			local objid,dataid,posx,posz
			local monstercount = self:GetMonsterCount()
			for i = 1,monstercount do
				objid = self:GetMonsterObjID(i)
				dataid = self:GetMonsterDataID(objid)
				if dataid == self.npcdataid then
					posx,posz = self:GetWorldPos(objid)
					posx = math.floor(posx - self.npcposx)
					posz = math.floor(posz - self.npcposz)
					if math.abs(posx) < 2 and math.abs(posz) < 2 then
						self:LuaFnDeleteMonster(objid)
						break
					end
				end
			end
			self:AddGlobalCountNews("@*;SrvMsg;SCA:#PRút thưởng Phách Phách đã đóng, hẹn lần mở sau.")
		else
			self:LuaFnSetWorldGlobalDataEx(self.open_id,1)
			self:create_paipai_npc("paipai")
			local msg = "@*;SrvMsg;SCA:#PRút thưởng Phách Phách chính thức mở, có thể tới#B[Lạc Dương,"..tostring(self.npcposx)..","..tostring(self.npcposz).."]#Ptìm#G"..self.npcname.."#Ptham gia."
			self:AddGlobalCountNews(msg)
		end
		self:OnDefaultEvent(selfId, targetId)
		return
	end
end


function JingPai_GM_Npc:OnMissionAccept(selfId, targetId, missionScriptId)
end

function JingPai_GM_Npc:OnMissionRefuse(selfId, targetId, missionScriptId)
end

function JingPai_GM_Npc:OnMissionContinue(selfId, targetId, missionScriptId)
end

function JingPai_GM_Npc:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
end

function JingPai_GM_Npc:OnDie(selfId, killerId)
end

function JingPai_GM_Npc:NotifyTips(selfId,msg)
	self:BeginEvent()
        self:AddText(msg)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

return JingPai_GM_Npc
