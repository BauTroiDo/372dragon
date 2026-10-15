--圣兽山宝箱争夺
local gbk = require "wire_charset"
local class = require "class"
local define = require "define"
local script_base = require "script_base"
local eShengShou_Contest = class("eShengShou_Contest", script_base)
eShengShou_Contest.DataValidator = 0
eShengShou_Contest.script_id = 808066
--NPC大宝箱
eShengShou_Contest.g_BigBox = {
	Name			= "白蟒宝箱",
	MonsterID	= 5011,
	PosX		= 142,
	PosY		= 112,
	ScriptID	= 808067
}

--当前的大宝箱是否存在....1存在 0不存在
eShengShou_Contest.g_IsBigBoxExist = 0
--当前是否有人在开启大宝箱....
eShengShou_Contest.g_IsBigBoxOpening = 0
eShengShou_Contest.g_OpeningPlayerName = "(ERROR)"

--正在开宝箱的人开始开宝箱的时间....
eShengShou_Contest.g_PlayerOpeningTime = 0

--技能书ID
eShengShou_Contest.g_SkillBooks = {
	30700226,
	30700227,
	30700228,
	30700229,
	-- 30700228,
	-- 30700229,
	-- 20310228,
}
eShengShou_Contest.g_SkillBooksNormal = {
	26000003,
	20310102,
	-- 30700228,
	-- 30700229,
	-- 20310228,
	-- 20310220,
}

--开出的BOSS的数据表....
eShengShou_Contest.g_BOSSData = {
	{ ID = 3845, PosX = 144, PosY = 112, BaseAI = 15, ExtAIScript = 0, ScriptID = -1, PatrolId = 0 },
	{ ID = 3846, PosX = 140, PosY = 112, BaseAI = 15, ExtAIScript = 0, ScriptID = -1, PatrolId = 1 },
	{ ID = 3847, PosX = 140, PosY = 113, BaseAI = 15, ExtAIScript = 0, ScriptID = -1, PatrolId = 2 },
	{ ID = 3848, PosX = 144, PosY = 113, BaseAI = 15, ExtAIScript = 0, ScriptID = -1, PatrolId = 3 },
}

--掉落包坐标....有多少坐标就掉多少掉落包....
eShengShou_Contest.g_DropBox = {
	{ PosX = 135, PosY = 108 },
	{ PosX = 136, PosY = 112 },
	{ PosX = 138, PosY = 108 },
	{ PosX = 143, PosY = 113 },
	{ PosX = 146, PosY = 109 },
	{ PosX = 147, PosY = 109 },

	{ PosX = 135, PosY = 113 },
	{ PosX = 137, PosY = 113 },
	{ PosX = 138, PosY = 114 },
	{ PosX = 143, PosY = 115 },
	{ PosX = 146, PosY = 112 },
	{ PosX = 147, PosY = 113 },

	{ PosX = 135, PosY = 115 },
	{ PosX = 137, PosY = 115 },
	{ PosX = 138, PosY = 116 },
	{ PosX = 143, PosY = 117 },
	{ PosX = 146, PosY = 114 },
	{ PosX = 147, PosY = 115 },

	{ PosX = 135, PosY = 117 },
	{ PosX = 147, PosY = 117 },
}

--掉落包的物品掉落表....
eShengShou_Contest.g_DropBoxItem = {
	{ odds = 30, itemId =30700226 },
	{ odds = 20, itemId =30700227 },
	{ odds = 20, itemId =30700228 },
	{ odds = 30, itemId =30700229 },
}
function eShengShou_Contest:GetDataValidator(param1,param2)
	eShengShou_Contest.DataValidator = math.random(1,2100000000)
	return eShengShou_Contest.DataValidator
end
--**********************************
--心跳函数
--**********************************
function eShengShou_Contest:OnTimer(actId, uTime, param1)
	if not uTime or uTime ~= param1 then
		return
	end
	--检测活动是否过期
	if self:CheckActiviyValidity(actId ) == 0 then
		self:StopOneActivity(actId )
	end
end

--**********************************
--事件交互入口
--**********************************
function eShengShou_Contest:OnDefaultEvent(actId, iNoticeType, param2, param3, param4, param5, param6)
	if param6 ~= eShengShou_Contest.DataValidator then
		return
	elseif not iNoticeType or not param2 or not param3 or not param4 or not param5 then
		return
	end
    local nTime = self:GetQuarterTime();
    local sceneId = self:GetSceneID()
	if nTime ~= 13 and nTime ~= 41 and nTime ~= 53 and nTime ~= 73 and nTime ~= 94 then
		return
	end
	if sceneId ~= 158 then
		return
	end
	--雷电交加天气效果....
	local curWeather = self:LuaFnGetSceneWeather(sceneId)
	if not curWeather or curWeather ~= -1 then
		--已经有天气了则不改变天气....
	else
		self:LuaFnSetSceneWeather(3, 5*60*1000 )
	end
	--如果已经有了就不再创建新的大宝箱....
	-- if self.g_IsBigBoxExist == 1 then
		-- return
	-- end
    local nMonsterNum = self:GetMonsterCount()
	for i=1, nMonsterNum do
		local MonsterId = self:GetMonsterObjID(i)
		local MosDataID = self:GetMonsterDataID(MonsterId)
		if MosDataID == self.g_BigBox.MonsterID
		and self:LuaFnIsCharacterLiving(MonsterId) then
		    self:StopOneActivity(actId)
		    return
		end
	end
	--没有则创建NPC大宝箱....
	local MstId = self:LuaFnCreateMonster(self.g_BigBox.MonsterID, self.g_BigBox.PosX, self.g_BigBox.PosY, 3, 0, self.g_BigBox.ScriptID,90 )
	self:SetCharacterName(MstId, self.g_BigBox.Name )
	-- self.g_IsBigBoxExist = 1
end
--**********************************
--检测是否可以打开大宝箱....
--**********************************
function eShengShou_Contest:CheckOpenBigBox(selfId,targetId )
	local obj = self:get_scene():get_obj_by_id(targetId)
	if not obj or obj:get_obj_type() ~= "monster" then
		self:notify_tips(selfId,"Rương không tồn tại.")
		return
	elseif obj:is_die() then
		self:notify_tips(selfId,"Rương đã bị mở.")
		return
	end
	local my_name = self:LuaFnGetName(selfId)
	local open_name = obj:get_scene_params(100)
	if open_name ~= 0 then
		if open_name == my_name then
			return true
		else
			local open_time = obj:get_scene_params(99)
			if os.time() < open_time then
				local msg = string.format("%s đang mở rương, có thể đánh gián đoạn rồi tới mở.",open_name)
				self:notify_tips(selfId,msg)
				return
			end
		end
	end
	obj:set_scene_params(100,my_name)
	obj:set_scene_params(99,os.time() + 180) 
	return true
end

--**********************************
--玩家开大宝箱被打断事件(由大宝箱脚本调用)....
--**********************************
function eShengShou_Contest:OnCancelOpen(targetId)
	local obj = self:get_scene():get_obj_by_id(targetId)
	if not obj or obj:get_obj_type() ~= "monster" then
		return
	elseif obj:is_die() then
		return
	end
	obj:set_scene_params(100,0)
	obj:set_scene_params(99,0)
end

--**********************************
--大宝箱被打开事件(由大宝箱脚本调用)....
--**********************************
function eShengShou_Contest:OnBigBoxOpen( selfId, activatorId )
	local obj = self:get_scene():get_obj_by_id(selfId)
	if not obj or obj:get_obj_type() ~= "monster" then
		self:notify_tips(activatorId,"Rương không tồn tại.")
		return
	elseif obj:is_die() then
		self:notify_tips(activatorId,"Rương đã bị mở.")
		return
	elseif obj:get_scene_params(100) ~= self:LuaFnGetName(activatorId) then
		self:notify_tips(activatorId,"Người mở rương không phải ngươi.")
		return
	end
	--kill大宝箱....大宝箱死亡动画为打开盖子....
	self:LuaFnSendSpecificImpactToUnit( selfId, selfId, selfId, 169, 0);
	self:LuaFnGmKillObj(selfId, activatorId)
	local rand = math.random(100)
	--if rand <= 30 then
		--开出技能书....
	--	self:GiveDropBox("fang_call",selfId, activatorId )
	--else
		--开出一堆掉落包....
		self:GiveSkillBook("fang_call",selfId, activatorId )
	--end

	--统计....
	self:LuaFnAuditShengShouOpenBigBox(activatorId)
end

--**********************************
--大宝箱被打开事件_给技能书....
--**********************************
function eShengShou_Contest:GiveSkillBook(flag,selfId, activatorId )
	if flag ~= "fang_call" then
		return
	end
	--随机给玩家一本技能书....并公告....
	local rand = math.random(1,4)
	--local numBooks
	--local randBook
	local BookID
	BookID = self.g_SkillBooks[rand]
	-- if rand % 20 == 0 then  --5%几率在所有可能掉落的书里随机
	-- 	numBooks = #(self.g_SkillBooks)
	-- 	randBook = math.random(numBooks)
	-- 	BookID = self.g_SkillBooks[ randBook ]
	-- else										--80%不包括10本特定技能
	-- 	numBooks = #(self.g_SkillBooksNormal)
	-- 	randBook = math.random(numBooks)
	-- 	BookID = self.g_SkillBooksNormal[ randBook ]
	-- end

	--给物品并公告....
	local BagIndex = self:TryRecieveItem(activatorId, BookID, false, 1)
	if BagIndex ~= -1 then
		self:BeginEvent(self.script_id)
        self:AddText("Ngươi nhận được một #{_ITEM"..BookID.."}" )
		self:EndEvent()
		self:DispatchMissionTips(activatorId )

		--公告....
		local ItemTransfer = self:GetBagItemTransfer(activatorId,BagIndex)
		local PlayerName = self:GetName(activatorId)
		local fmt = gbk.fromutf8("#W#{_INFOUSR%s}#Ptại#GThánh Thú Sơn#Pđốt lửa xông khói lỡ cay mắt, mơ hồ đâm vào#Yrương lớn#P, mở ra xem, hóa ra là #{_INFOMSG%s}.")
		local str = string.format(fmt, gbk.fromutf8(PlayerName), ItemTransfer)
		self:BroadMsgByChatPipe(activatorId, str, 4 )
	end
end

--**********************************
--大宝箱被打开事件_开出BOSS....
--**********************************
function eShengShou_Contest:GiveBOSS(flag,selfId, activatorId )
	if flag ~= "fang_call" then
		return
	end
	--刷BOSS....
	local MstId
	for _, BOSSData in pairs(self.g_BOSSData) do
		MstId = self:LuaFnCreateMonster(BOSSData.ID, BOSSData.PosX, BOSSData.PosY, BOSSData.BaseAI, BOSSData.ExtAIScript, BOSSData.ScriptID )
		self:SetCharacterDieTime(MstId, 2*60*60*1000 )
		self:SetPatrolId(MstId, BOSSData.PatrolId)
	end
	--公告....
	local PlayerName = self:GetName(activatorId)
	local str = string.format( "#GThánh Thú Sơn#P thượng quần hùng đoạt bảo, duy #W#{_INFOUSR%s}#P kỹ cao nhất trù, hỗn chiến trung nhất chưởng tương #YBạch Mãng Bảo Rương#P đả phiên, bất liệu cánh khiêu xuất tứ cá #WBảo Rương Đồng Tử#P!", PlayerName )
	str = gbk.fromutf8(str)
	self:BroadMsgByChatPipe(activatorId, str, 4 )
end

--**********************************
--大宝箱被打开事件_掉落一堆掉落包....
--**********************************
function eShengShou_Contest:GiveDropBox(flag,selfId, activatorId )
	if flag ~= "fang_call" then
		return
	end
	--计算总权重....
	local totalOdds = 0
	for _, item in pairs(self.g_DropBoxItem )do
		totalOdds = totalOdds  + item.odds
	end
	if totalOdds < 1 then
		return
	end
	--给掉落包....
	local DropItemId = -1
	for _, box in pairs(self.g_DropBox) do
		--计算本包掉落的物品....
		local randValue = math.random(1, totalOdds)
		randValue = randValue - 1
		for _, item in pairs(self.g_DropBoxItem) do
			if item.odds >= randValue then
				DropItemId = item.itemId
				break
			end
			randValue = randValue - item.odds
		end
		--放掉落包到场景里....
		if DropItemId > 0 then
			local BoxId = self:DropBoxEnterScene(box.PosX, box.PosY)
			if BoxId > -1 then
				self:AddItemToBox(BoxId, define.QUALITY_CREATE_BY_BOSS, 1, DropItemId)
			end
		end

	end
	--公告....
	local PlayerName = self:GetName(activatorId)
	local str = string.format( "#GThánh Thú Sơn#P thượng #W#{_INFOUSR%s}#P tại quần hào thôi cử dưới mở #YBạch Mãng Bảo Rương#P, chỉ thấy kim quang thiểm quá, biến địa tài bảo, hoan thanh nhất phiến.", PlayerName )
	str = gbk.fromutf8(str)
	self:BroadMsgByChatPipe(activatorId, str, 4 )
end

function eShengShou_Contest:OnPlayerPickUpItemInBoar(selfId, itemId, bagidx )
	--公告....
	if itemId == 40004429 then
		local playerName = self:GetName(selfId)
		local transfer = self:GetBagItemTransfer(selfId,bagidx)
		local fmt = "#{BoarItem_Info_001}#{_INFOUSR%s}#{BoarItem_Info_002}#{_INFOMSG%s}#{BoarItem_Info_003}"
		fmt = gbk.fromutf8(fmt)
		local str = string.format(fmt, gbk.fromutf8(playerName), transfer)
		self:BroadMsgByChatPipe(selfId, str, 4)
	end
end

return eShengShou_Contest