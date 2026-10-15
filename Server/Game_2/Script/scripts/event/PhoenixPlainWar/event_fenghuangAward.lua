local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local event_fenghuangAward = class("event_fenghuangAward", script_base)
local gbk = require "wire_charset"

event_fenghuangAward.script_id = 403012
--杀人榜奖励配置  1-10名    不需要的奖励把键位删除 BindYuanBao  Item
event_fenghuangAward.TopKillAward = 
{
	{
		BindYuanBao = 100000,
		--[[称号注释：有 Titleid 时 TitleName 与 TitleFlag 必带
		TitleFlag = 逻辑类型(程序用)  适用于char_title.txt 的称号
		TitleFlag = -1 适用于 char_title_new.txt 的称号]]
		 Titleid = 1349,
		 TitleName = "Danh hiệu: Hoàng Thành Chí Tôn",
		 TitleFlag = -1,
		Item = {
				{20310217,200},
				{20310219,200},
							},
	},
	{
		BindYuanBao = 80000,
		 Titleid = 1350,
		 TitleName = "Danh hiệu: Hoàng Thành Thống Lĩnh",
		 TitleFlag = -1,
		Item = {
				{20310217,150},
				{20310219,150},
							},
	},
	{
		BindYuanBao = 60000,
		 Titleid = 1351,
		 TitleName = "Danh hiệu: Hoàng Thành Chiến Tướng",
		 TitleFlag = -1,
		Item = {
				{20310217,100},
				{20310219,100},
							},
	},
	{
		BindYuanBao = 50000,
		Item = {
				{20310217,80},
				{20310219,80},
							},
	},
	{
		BindYuanBao = 40000,
		Item = {
				{20310217,70},
				{20310219,70},
							},
	},
	{
		BindYuanBao = 30000,
		Item = {
				{20310217,60},
				{20310219,60},
							},
	},
	{
		BindYuanBao = 20000,
		Item = {
				{20310217,50},
				{20310219,50},
							},
	},
	{
		BindYuanBao = 20000,
		Item = {
				{20310217,50},
				{20310219,50},
							},
	},
	{
		BindYuanBao = 20000,
		Item = {
				{20310217,50},
				{20310219,50},
							},
	},
	{
		BindYuanBao = 20000,
		Item = {
				{20310217,50},
				{20310219,50},
							},
	},
}
--联盟积分奖励配置  不需要的奖励把键位删除 BindYuanBao  Item
event_fenghuangAward.TopScoreAward = 
{
	--0-2000积分奖励
	{
		Score = 2000,
		BindYuanBao = 10000,
	},
	--0-4000积分奖励
	{
		Score = 4000,
		BindYuanBao = 15000,
	},
	--0-6000积分奖励
	{
		Score = 6000,
		BindYuanBao = 20000,
	},
	--0-8000积分奖励
	{
		Score = 8000,
		BindYuanBao = 25000,
	},
	--0-6000积分奖励
	{
		Score = 10000,
		BindYuanBao = 30000,
		--[[称号注释：有 Titleid 时 TitleName 与 TitleFlag 必带
		TitleFlag = 逻辑类型(程序用)  适用于char_title.txt 的称号
		TitleFlag = -1 适用于 char_title_new.txt 的称号]]
		Titleid = 264,
		TitleName = "Danh hiệu: Bá chủ Phượng Hoàng Cổ Thành (và dẫn đội vào lăng Phượng Hoàng được)",
		TitleFlag = 44,
	},
	
}
--*********************************
-- 领取奖励
--*********************************
function event_fenghuangAward:ReceiveTopAward(selfId,targetId,nscriptid)
	if 001218 ~= nscriptid then return end
	local msg
	local index = self:GetMissionData(selfId,ScriptGlobal.MD_FH_UNION)
	if index < 1 or index > 8 then
		msg = "Vòng chiến Phượng Hoàng trước ngươi không thuộc liên minh nào."
		self:NotifyFailBox(selfId,targetId,nscriptid,msg)
		return
	end
	local receivetime = self:GetMissionDataEx(selfId,ScriptGlobal.MDEX_FH_AWARDFLAG)
	local opentime = self:GetMissionDataEx(selfId,ScriptGlobal.MDEX_FH_TIME)
	local needtime = self:GetMissionDataEx(selfId,ScriptGlobal.MDEX_FH_PARTICIPATIONTIME)
	local name = self:GetName(selfId)
	local scoreinfo = self:GetPhoenixPlainData(1,1,index)
	local killinfo = self:GetPhoenixPlainData(2,3,name)
	local topscore,topkill
	if scoreinfo then
		if receivetime == scoreinfo.opentime then
			msg = "score: thưởng chiến Phượng Hoàng vòng trước đã nhận."
			self:NotifyFailBox(selfId,targetId,nscriptid,msg)
			return
		elseif opentime ~= scoreinfo.opentime then
			msg = "score: vòng chiến Phượng Hoàng trước ngươi không tham gia hoặc thưởng hết hạn."
			self:NotifyFailBox(selfId,targetId,nscriptid,msg)
			return
		-- elseif needtime < scoreinfo.needtime then
		elseif needtime < 1800 then
			msg = "score: vòng chiến Phượng Hoàng trước ngươi tham gia chưa đủ lâu"..tostring(1800).."giây."..tostring(needtime)
			-- msg = "score:上一轮凤凰战你的参与时长不足"..tostring(scoreinfo.needtime).."秒。"..tostring(needtime)
			self:NotifyFailBox(selfId,targetId,nscriptid,msg)
			return
		end
		topscore = scoreinfo.score
	end
	if killinfo then
		if receivetime == killinfo.opentime then
			msg = "kill: thưởng chiến Phượng Hoàng vòng trước đã nhận."
			self:NotifyFailBox(selfId,targetId,nscriptid,msg)
			return
		elseif opentime ~= killinfo.opentime then
			msg = "kill: vòng chiến Phượng Hoàng trước ngươi không tham gia hoặc thưởng hết hạn."
			self:NotifyFailBox(selfId,targetId,nscriptid,msg)
			return
		elseif needtime < 1800 then
		-- elseif needtime < killinfo.needtime then
			msg = "kill: vòng chiến Phượng Hoàng trước ngươi tham gia chưa đủ lâu"..tostring(1800).."giây."..tostring(needtime)
			-- msg = "kill:上一轮凤凰战你的参与时长不足"..tostring(killinfo.needtime).."秒。"..tostring(needtime)
			self:NotifyFailBox(selfId,targetId,nscriptid,msg)
			return
		end
		topkill = scoreinfo.index
	end
	if not topscore and not topkill then
		msg = "Ngươi không có thưởng để nhận."
		self:NotifyFailBox(selfId,targetId,nscriptid,msg)
		return
	end
	local bindyuanbao = 0
	local titleinfo = {}
	local iteminfo = {}
	local lsinfo,lsinfox,lsinfoz,lsinfon
	if topscore then
		for i,j in ipairs(self.TopScoreAward) do
			if topscore <= j.Score then
				lsinfox = j.BindYuanBao
				if lsinfox then
					bindyuanbao = bindyuanbao + lsinfox
				end
				if topscore >= 10000 then
					lsinfox = j.Titleid
					lsinfoz = j.TitleFlag
					lsinfon = j.TitleName
					if lsinfox and lsinfoz and lsinfon then
						table.insert(titleinfo,{lsinfox,lsinfoz,lsinfon})
					end
				end
				lsinfo = j.Item
				if lsinfo then
					for m,n in ipairs(lsinfo) do
						lsinfox = n[1]
						lsinfoz = n[2]
						table.insert(iteminfo,{lsinfox,lsinfoz})
					end
				end
				break
			end
		end
	end
	if topkill then
		local killaward = self.TopKillAward[topkill]
		if killaward then
			lsinfox = killaward.BindYuanBao
			if lsinfox then
				bindyuanbao = bindyuanbao + lsinfox
			end
			lsinfox = killaward.Titleid
			lsinfoz = killaward.TitleFlag
			lsinfon = killaward.TitleName
			if lsinfox and lsinfoz and lsinfon then
				table.insert(titleinfo,{lsinfox,lsinfoz,lsinfon})
			end
			lsinfo = killaward.Item
			if lsinfo then
				for m,n in ipairs(lsinfo) do
					lsinfox = n[1]
					lsinfoz = n[2]
					table.insert(iteminfo,{lsinfox,lsinfoz})
				end
			end
		end
	end
	local textinfo = {"Nhận thành công các thưởng sau:"}
	if #iteminfo > 0 then
		self:BeginAddItem()
		for i = 1,#iteminfo do
			self:AddItem(iteminfo[i][1],iteminfo[i][2],true);
			table.insert(textinfo,self:GetItemName(iteminfo[i][1]).." * "..tostring(iteminfo[i][2]))
			if not self:EndAddItem(selfId) then
				msg = "Túi đồ không đủ chỗ trống."
				self:NotifyFailBox(selfId,targetId,nscriptid,msg)
				return
			end
		end
	end
	self:SetMissionDataEx(selfId,ScriptGlobal.MDEX_FH_AWARDFLAG,opentime)
	if self:GetMissionDataEx(selfId,ScriptGlobal.MDEX_FH_AWARDFLAG) == opentime then
		if #iteminfo > 0 then
			self:AddItemListToHuman(selfId)
		end
		if bindyuanbao > 0 then
			self:AddBindYuanBao(selfId, bindyuanbao)
			table.insert(textinfo,"Nguyên bảo khóa * "..tostring(bindyuanbao))
		end
		if #titleinfo > 0 then
			for i,j in ipairs(titleinfo) do
				if j[2] == -1 then
					if not self:LuaFnHaveAgname(selfId,j[1]) then
						self:LuaFnAddNewAgname(selfId,j[1])
					end
				else
					self:LuaFnAwardTitle(selfId,j[2],j[1])
					self:LuaFnDispatchAllTitle(selfId)
				end
				table.insert(textinfo,"Nhận danh hiệu:"..tostring(j[3]))
			end
		end
		if opentime == 1723468148 and self:GetMissionDataEx(selfId,700) < 2 then
			self:SetMissionDataEx(selfId,700,2)
		end
		local text = table.concat(textinfo,"\n")
		self:BeginEvent(nscriptid)
		self:AddText(text)
		self:EndEvent()
		self:DispatchEventList(selfId,targetId)
		self:SetLog(selfId,"Nhận thưởng chiến Phượng Hoàng Thành","Nhận xong","Nhận xong","Nhận xong")
	else
		self:BeginAddItem()
	end
end
--*********************************
-- 查询奖励
--*********************************
function event_fenghuangAward:GetKillTopAward(selfId,delflag,top)
	if not top or top < 0 then
		return
	end
	if delflag == 1 then
		local index
		local Score
		for i,j in ipairs(self.TopScoreAward) do
			if top <= j.Score then
				index = i
				Score = j.Score
				break
			end
		end
		if not index or not Score then
			self:MsgBox(selfId,"Bảng tích điểm:"..tostring(top))
			return
		end
		local texttab = {"["..tostring(Score - 2000).."-"..tostring(Score).."]thưởng tích điểm liên minh:\\n"}
		local tinfo = self.TopScoreAward[index]
		if tinfo then
			if tinfo.BindYuanBao then
				table.insert(texttab,"    Nguyên bảo khóa:")
				table.insert(texttab,tostring(tinfo.BindYuanBao))
				table.insert(texttab,"\n")
			end
			if tinfo.Titleid then
				table.insert(texttab,"    "..tostring(tinfo.TitleName).."\n")
			end
			if tinfo.Item then
				for i,j in ipairs(tinfo.Item) do
					table.insert(texttab,"    "..self:GetItemName(j[1]).." * "..tostring(j[2]))
					table.insert(texttab,"\n")
				end
			end
		end
		table.insert(texttab,"ps. Sau hoạt động nhận ở NPC vào trận (#Ghạn tới trước lần chiến Phượng Hoàng sau#W)")
		local text = table.concat(texttab)
		self:BeginEvent(self.script_id)
		self:AddText(text)
		self:EndEvent()
		self:DispatchEventList(selfId,selfId)
		return
	end
	if delflag == 2 then
		local tinfo = self.TopKillAward[top]
		if not tinfo then
			self:MsgBox(selfId,"Bảng sát nhân:"..tostring(top))
			return
		end
		local texttab = {"Bảng sát nhân thứ ["..tostring(top).."]hạng thưởng:\\n"}
		if tinfo.BindYuanBao then
			table.insert(texttab,"    Nguyên bảo khóa:")
			table.insert(texttab,tostring(tinfo.BindYuanBao))
			table.insert(texttab,"\n")
		end
		if tinfo.Titleid then
			table.insert(texttab,"    "..tostring(tinfo.TitleName).."\n")
		end
		if tinfo.Item then
			for i,j in ipairs(tinfo.Item) do
				table.insert(texttab,"    "..self:GetItemName(j[1]).." * "..tostring(j[2]))
				table.insert(texttab,"\n")
			end
		end
		table.insert(texttab,"ps. Sau hoạt động nhận ở NPC vào trận (#Ghạn tới trước lần chiến Phượng Hoàng sau#W)")
		local text = table.concat(texttab)
		self:BeginEvent(self.script_id)
		self:AddText(text)
		self:EndEvent()
		self:DispatchEventList(selfId,selfId)
		return
	end
end
function event_fenghuangAward:MsgBox(selfId,str)
    self:BeginEvent(self.script_id)
    self:AddText(str)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

function event_fenghuangAward:NotifyFailBox(selfId,targetId,nscriptid,msg)
    self:BeginEvent(nscriptid)
    self:AddText(msg)
    self:EndEvent()
    self:DispatchEventList(selfId,targetId)
end
return event_fenghuangAward