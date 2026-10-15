local class = require "class"
local define = require "define"
local gbk = require "wire_charset"
local ScriptGlobal = require "scripts.ScriptGlobal"
-- local packet_def = require "game.packet"
local script_base = require "script_base"
local PaiPai = class("PaiPai", script_base)
PaiPai.script_id = 999972

PaiPai.world_id1 = ScriptGlobal.WORLD_ID_PAIPAI_1
PaiPai.world_id2 = ScriptGlobal.WORLD_ID_PAIPAI_2
PaiPai.world_id3 = ScriptGlobal.WORLD_ID_PAIPAI_3
PaiPai.open_id = ScriptGlobal.WORLD_ID_PAIPAI_4
PaiPai.open_id_two = ScriptGlobal.WORLD_ID_PAIPAI_5
			
--self.ranitem[n][1] = 	物品id
--self.ranitem[n][2] = 	物品数量
--self.ranitem[n][3] = 	物品高亮 = 0 即打开界面时该道具不高亮   = 1 则高亮显示   高亮是物品框里那个动态GIF 1=开启 0=隐藏
--self.ranitem[n][4] = 	抽奖范围最小值
--self.ranitem[n][5] = 	抽奖范围最大值
--self.ranitem[n][6] = 	物品给予绑定状态 = 0 不绑定  = 1 绑定

            -- ID	   数量    高亮    范围    范围    绑定
            --[n][1]  [n][2]  [n][3]  [n][4]  [n][5]  [n][6]
PaiPai.ranitem = {
	[1] = {20101002,	1,		1,		0,		7,		1,},
	[2] = {20101003,	1,		1,		8,		18,		1,},
	[3] = {20101004,	1,		1,		19,		24,		1,},
	[4] = {20101005,	1,		0,		25,		35,		1,},
	[5] = {20101006,	1,		1,		36,		41,		1,},
	[6] = {20101007,	1,		0,		42,		45,		1,},
	[7] = {20101008,	1,		1,		46,		51,		1,},
	[8] = {20101009,	30,		1,		52,		60,		1,},
}

PaiPai.needitem = 20102027		--抽奖券
PaiPai.needitemcount = 1		--消耗抽奖券数量
PaiPai.needyuanbao = 28888 		--抽奖券单价   （元宝）   > 0时则开放元宝补充抽奖券抽奖  <=0 时则不开放元宝补充

PaiPai.havemsg = 1		--抽奖结果是否系统公告    = 1 公告  = 0 不公告



function PaiPai:LuckyDraw( selfId,Par,buyflag )
	if Par == 4 then
		--开UI时初始化修正检测
		if self:LuaFnGetWorldGlobalDataEx(self.open_id) == 0 then
			self:notify_tips( selfId, "Hệ thống này chưa mở.")
			return
		end
		local GmFlag = self:CallScriptFunction(700489,"HavePermission",selfId)
		if not GmFlag then
			if self:LuaFnGetWorldGlobalDataEx(self.open_id_two) == 0 then
				self:notify_tips( selfId, "Hệ thống chưa chính thức mở, xin chờ.")
				return
			end
		end
		local nF1,nF2,nF3,nF4 = self:GetLotteryDrawingData(  selfId )
		local Fag
		if nF1 == 0 or nF1 == 1 then
			if nF2 ~= 0 or nF3 ~= 0 or nF4 ~= 0 then
				Fag = 1
			end
		elseif nF1 == 2 then
			if (nF2 < 1 or nF2 > 21) or (nF3 < 1 or nF3 > 21) or (nF4 < 1 or nF4 > 21) then
				Fag = 1
			end
		else
			Fag = 1
		end
		if Fag == 1 then
			self:SetMissionData(selfId,ScriptGlobal.MD_PAIPAI,0)
		end
		local nTab = {}
		for i,j in ipairs(self.ranitem) do
			Fag = string.format("%d,%d,%d,%d,%d",j[1],j[2],j[3],j[4],j[5])
			nTab[i] = Fag
		end
		self:BeginUICommand( sceneId )
		self:UICommand_AddInt(self.needitem)
		self:UICommand_AddInt(self.needitemcount)
		self:UICommand_AddInt(self.needyuanbao * self.needitemcount)
		for i = 1,8 do
			self:UICommand_AddStr(nTab[i])
		end
		self:UICommand_AddStr("Paipai")
		self:EndUICommand( sceneId )
		self:DispatchUICommand(  selfId,20130427)
	elseif Par == 0 then
		local nF1 = self:GetLotteryDrawingData(  selfId )
		if nF1 == 1 then
			self:notify_tips(  selfId, "Đang rút thưởng..." )
		elseif nF1 == 2 then
			self:notify_tips(  selfId, "Hiện có thưởng chưa nhận, sẽ nhận ngay." )
			self:LuckyDraw( selfId,2 )
		else
			if self:LuaFnGetWorldGlobalDataEx(self.open_id) == 0 then
				self:notify_tips( selfId, "Hệ thống này chưa mở.")
				return
			end
			local GmFlag = self:CallScriptFunction(700489,"HavePermission",selfId)
			if not GmFlag then
				if self:LuaFnGetWorldGlobalDataEx(self.open_id_two) == 0 then
					self:notify_tips( selfId, "Hệ thống chưa chính thức mở, xin chờ.")
					return
				end
			end
			local count = self:LuaFnGetAvailableItemCount(selfId, self.needitem)
			local needyuanbao = 0
			if count < self.needitemcount then
				if not buyflag or buyflag == 0 or self.needyuanbao < 1 then
					local msg = "Lần rút này cần"..self:GetItemName(self.needitem)..tostring(self.needitemcount).."cái."
					self:notify_tips( selfId, msg)
					return
				end
				needyuanbao = self.needitemcount - count
				needyuanbao = needyuanbao * self.needyuanbao
				local yuanbao = self:GetYuanBao(selfId)
				if yuanbao < needyuanbao then
					local msg = "Lần rút này cần"..self:GetItemName(self.needitem)..tostring(self.needitemcount).."cái."
					self:notify_tips( selfId, msg)
					return
				end
				if count > 0 then
					self:LuaFnDelAvailableItem(selfId, self.needitem, count)
				end
				self:LuaFnCostYuanBao(selfId, needyuanbao)
				local msg = "Ngươi tiêu tốn"..tostring(needyuanbao).."Nguyên bảo bù vé rút để rút thưởng."
				self:notify_tips( selfId, msg)
			else
				self:LuaFnDelAvailableItem(selfId, self.needitem, self.needitemcount)
			end
			self:SetMissionData(selfId,ScriptGlobal.MD_PAIPAI,10^6)
			self:BeginUICommand( sceneId )
			self:DispatchUICommand(  selfId,20130508)
		end
	elseif Par == 1 then
		if self:LuaFnGetWorldGlobalDataEx(self.open_id) == 0 then
			self:notify_tips( selfId, "Hệ thống này chưa mở.")
			return
		end
		local GmFlag = self:CallScriptFunction(700489,"HavePermission",selfId)
		if not GmFlag then
			if self:LuaFnGetWorldGlobalDataEx(self.open_id_two) == 0 then
				self:notify_tips( selfId, "Hệ thống chưa chính thức mở, xin chờ.")
				return
			end
		end
		local nF1,nF2,nF3,nF4 = self:GetLotteryDrawingData(  selfId )
		if nF1 == 1 then
			if nF2 == 0 and nF3 == 0 and nF4 == 0 then
				local nRandom = {0,0,0}
				local nTab,nFs = PaiPai:Cameraobscura()
				if nFs > 0 then
					local nH1 = math.random(1,nFs)
					local nH2 = 0
					local nH3
					for i = 1,8 do
						if nTab[i] > 0 then
							nH2 = nH2 + nTab[i]
							if nH1 <= nH2 then
								nH3 = i
								break
							end
						end
					end
					if nH3 and nH3 >= 1 and nH3 <= 8 then
						local nH4 = self.ranitem[nH3]
						local nH5 = math.random(nH4[4],nH4[5]) + 3
						if nH5 >= 23 then
							nRandom[1] = math.random(1,21)
						else
							local nJ1 = nH5-2
							nRandom[1] = math.random(1,nJ1)
						end
						nH5 = nH5 - nRandom[1]
						if nH5 >= 22 then
							nRandom[2] = math.random(1,21)
						else
							local nJ1 = nH5-1
							nRandom[2] = math.random(1,nJ1)
						end
						nH5 = nH5 - nRandom[2]
						if nH5 == 21 then
							nRandom[3] = nH5
						else
							if nH5 > 21 then
								nRandom[3] = math.random(1,21)
							else
								nRandom[3] = math.random(1,nH5)
							end
							nH5 = nH5 - nRandom[3]
							if nH5 > 0 then
								local nJ1 = math.floor(nH5/3)
								local nJ2 = (nH5 % 3)
								if nJ1 > 0 then
									for i = 1,nJ1 do
										for j,k in ipairs(nRandom) do
											if k < 21 then
												nRandom[j] = k + 1
											else
												nJ2 = nJ2 + 1
											end
										end
									end
								end
								if nJ2 > 0 then
									for i,j in ipairs(nRandom) do
										if j + nJ2 <= 21 then
											nRandom[i] = j + nJ2
											nJ2 = 0
											break
										elseif j < 21 then
											nJ2 = nJ2 - (21 - j)
											nRandom[i] = 21
										end
									end
								end
							end
						end
					else
						--逻辑上进不到这一步,不过得写上
						nRandom[1] = math.random(1,21)
						nRandom[2] = math.random(1,21)
						nRandom[3] = math.random(1,21)
					end
				else
					nRandom[1] = math.random(1,21)
					nRandom[2] = math.random(1,21)
					nRandom[3] = math.random(1,21)
				end
				local nF8 = 2 * 10^6 + nRandom[1] * 10000 + nRandom[2] * 100 + nRandom[3]
				self:SetMissionData(selfId,ScriptGlobal.MD_PAIPAI,nF8)
				self:BeginUICommand( sceneId )
				self:DispatchUICommand(  selfId,20130428)
			end
		end
	elseif Par == 2 then
		local nF1,nF2,nF3,nF4 = self:GetLotteryDrawingData(  selfId )
		if nF1 == 2 then
			if nF2 > 0 and nF3 > 0 and nF4 > 0 then
				local nF5 = nF2 + nF3 + nF4 - 3
				local Fag
				for _,j in ipairs(self.ranitem) do
					if nF5 >= j[4] and nF5 <= j[5] then
						Fag = true
						self:BeginAddItem()
						if j[6] == 0 then
							self:AddItem(j[1],j[2],false)
						else
							self:AddItem(j[1],j[2],true)
						end
						if not self:EndAddItem(selfId) then
							return
						end
						self:SetMissionData(selfId,ScriptGlobal.MD_PAIPAI,0)
						if self:GetMissionData(selfId,ScriptGlobal.MD_PAIPAI) == 0 then
							self:AddItemListToHuman(selfId)
							local msg = string.format("Nhận thưởng thành công, được %s*%d",self:GetItemName(j[1]),j[2])
							self:notify_tips(  selfId, msg )
							if self.havemsg == 1 then
								local GmFlag = self:CallScriptFunction(700489,"HavePermission",selfId)
								if not GmFlag then
									local Name = self:GetName(selfId)
									local str = string.format("#cFF0000Người chơi#{_INFOUSR%s}#Pdùng#Wđại rút thưởng Phách Phách may mắn nhận#Rđược %d cái %s",Name,j[2],self:GetItemName(j[1]))
									self:BroadMsgByChatPipe( selfId,gbk.fromutf8(str), 4)
								end
							end
						end
						break
					end
				end
				if not Fag then
					self:SetMissionData(selfId,ScriptGlobal.MD_PAIPAI,0)
				end
				self:BeginUICommand( sceneId )
				self:DispatchUICommand(selfId,20130508)
			end
		end
	end
end
function PaiPai:Cameraobscura()
	local nTab = {}
	local nF1 = self:LuaFnGetWorldGlobalDataEx(self.world_id1)
	nTab[1] = math.floor(nF1/10^6)
	nF1 = (nF1 % 10^6)
	nTab[2] = math.floor(nF1/1000)
	nTab[3] = (nF1 % 1000)
	nF1 = self:LuaFnGetWorldGlobalDataEx(self.world_id2)
	nTab[4] = math.floor(nF1/10^6)
	nF1 = (nF1 % 10^6)
	nTab[5] = math.floor(nF1/1000)
	nTab[6] = (nF1 % 1000)
	nF1 = self:LuaFnGetWorldGlobalDataEx(self.world_id3)
	nTab[7] = math.floor(nF1/1000)
	nTab[8] = (nF1 % 1000)
	nF1 = 0
	for _,j in ipairs(nTab) do
		nF1 = nF1 + j
	end
	return nTab,nF1
end
function PaiPai:GetLotteryDrawingData( selfId )
	local nF4 = self:GetMissionData(selfId,ScriptGlobal.MD_PAIPAI)
	local nF1 = math.floor(nF4/10^6)
	nF4 = nF4 % 10^6
	local nF2 = math.floor(nF4/10000)
	nF4 = (nF4 % 10000)
	local nF3 = math.floor(nF4/100)
	nF4 = (nF4 % 100)
	return nF1,nF2,nF3,nF4
end
return PaiPai
