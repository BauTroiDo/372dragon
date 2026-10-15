local gbk = require "wire_charset"
local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local common_item = class("common_item", script_base)

local g_ItemId = 30000000
local g_NpcScriptID = 807001
local g_DefaultCorpseDataId = 3510
local g_ChengxiongdatuScriptId = 229020
local g_DiaorubaozangScriptId = 229021
local g_minValue = 6000
local g_maxValue = 90000
local g_MissionIndex10 = 24
local g_MissionIndex20 = 43
local g_MissionIndex30 = 44
local g_MissionIndex40 = 45
local g_MissionIndex50 = 46
local g_MissionIndex60 = 47
local g_MissionIndex70 = 48
local g_MissionIndex80 = 49
local g_MissionIndex90 = 50

local g_zhu_bo_count = 50

local open_item_count_day = 5		--每日开启马图次数上限
local base_item_count = 1000		--基数，马个数>=1000时需调整这个值
local create_monster_day = 50		--每日出马个数
local g_SceneMapDefine = {
    {sceneId=18,	sceneName="Nhạn Nam",	CorpseMonsterId=3512},
    {sceneId=19,	sceneName="Nhạn Bắc",	CorpseMonsterId=3513},
    {sceneId=20,	sceneName="Thảo Nguyên",	CorpseMonsterId=3515},
    {sceneId=21,	sceneName="Liêu Tây",	CorpseMonsterId=3516},
    {sceneId=22,	sceneName="Trường Bạch Sơn",	CorpseMonsterId=3518},
    {sceneId=23,	sceneName="Hoàng Long phủ",	CorpseMonsterId=3519},
    {sceneId=24,	sceneName="Nhĩ Hải",	CorpseMonsterId=3511},
    {sceneId=25,	sceneName="Thương Sơn",	CorpseMonsterId=3513},
    {sceneId=26,	sceneName="Thạch Lâm",	CorpseMonsterId=3514},
    {sceneId=27,	sceneName="Ngọc Khê",	CorpseMonsterId=3516},
    {sceneId=28,	sceneName="Nam Chiếu",	CorpseMonsterId=3517},
    {sceneId=29,	sceneName="Miêu Cương",	CorpseMonsterId=3518},
    {sceneId=30,	sceneName="Tây Hồ",	CorpseMonsterId=3511},
    {sceneId=31,	sceneName="Long Tuyền",	CorpseMonsterId=3512},
    {sceneId=32,	sceneName="Võ Di",	CorpseMonsterId=3516},
    {sceneId=33,	sceneName="Mai Lĩnh",	CorpseMonsterId=3515},
    {sceneId=34,	sceneName="Nam Hải",	CorpseMonsterId=3517},
    {sceneId=35,	sceneName="Quỳnh Châu",	CorpseMonsterId=3518},
}

local g_CorpseMonsterPosTable = {
    {x=104, y=221},
    {x=104, y=201},
    {x=79, y=222}
}

local g_GhoulMonsterTable = {
    {level=11, id=3520},{level=21, id=3521},
    {level=31, id=3522},{level=41, id=3523},
    {level=51, id=3524},{level=61, id=3525},
    {level=71, id=3526},{level=81, id=3527},
    {level=91, id=3528},{level=101, id=3529},
}

function common_item:GetItemParam(selfId, BagPos)
	local targetsceneId = self:GetBagItemParam(selfId, BagPos, 1, "uchar")
	local targetX = self:GetBagItemParam(selfId, BagPos, 3, "ushort")
    local targetZ = self:GetBagItemParam(selfId, BagPos, 5, "ushort")
    local r = self:GetBagItemParam(selfId, BagPos, 7, "uchar")
    return targetsceneId, targetX, targetZ, r
end

function common_item:IsSkillLikeScript()
    return 0
end

function common_item:CancelImpacts()
    return 0
end

function common_item:OnConditionCheck(selfId)
    if not self:LuaFnVerifyUsedItem(selfId) then
		return 0
	end
    return 1
end

function common_item:OnDeplete(selfId)
    return self:LuaFnDepletingUsedItem(selfId)
end

function common_item:OnActivateOnce(selfId)
    return 1
end

function common_item:DiscoverMoney(selfId)
    local Bonus = 1 --math.random(g_maxValue - g_minValue) + g_minValue
    local str = "Ngươi đào được #{_MONEY" .. tostring(Bonus) .. "}"
    self:AddMoney(selfId, Bonus)
    self:Msg2Player(selfId, str, define.ENUM_CHAT_TYPE.CHAT_TYPE_NORMAL )
    self:notify_tips(selfId, str)
end

--**********************************
--遇盗墓贼 --OK
--**********************************
function common_item:DiscoverGhoulMonster(selfId)
	local humanLevel = self:GetLevel(selfId)
	local dataId = g_GhoulMonsterTable[1].id
	local ct = #(g_GhoulMonsterTable)
	for i=1, ct do
		if humanLevel >= g_GhoulMonsterTable[i].level then
			if i+1 <= ct then
				if humanLevel < g_GhoulMonsterTable[i+1].level then
					dataId = g_GhoulMonsterTable[i].id
					break
				end
			end
		end
	end

	local aifile = math.random(10)
	local x, z = self:GetWorldPos(selfId)
	local MonsterId = self:LuaFnCreateMonster(dataId, x, z-2, 0, aifile, -1)
	self:SetLevel(MonsterId, humanLevel+(math.random(2)-math.random(2)) )
	self:SetCharacterDieTime(MonsterId, 60*60000)

	local strTitle, strName = self:CallScriptFunction(g_ChengxiongdatuScriptId, "CreateTitleAndName_ForCangBaoTu", selfId)
	self:SetCharacterTitle(MonsterId, strTitle)
	self:SetCharacterName(MonsterId, strName)

    self:notify_tips(selfId, "Cẩn thận! Đạo mộ tặc")
end

--**********************************
--获得物品 --OK
--**********************************
function common_item:DiscoverItem(selfId)
    local ItemSn, ItemName, _, bBroadCast
    local playerLevel = self:GetLevel(selfId)
    if playerLevel <= 10 then
     ItemSn, ItemName, _, bBroadCast = self:GetOneMissionBonusItem(g_MissionIndex10)
    elseif  playerLevel <= 20 then
        ItemSn, ItemName, _, bBroadCast = self:GetOneMissionBonusItem(g_MissionIndex20)
    elseif  playerLevel <= 30 then
        ItemSn, ItemName, _, bBroadCast = self:GetOneMissionBonusItem(g_MissionIndex30)
    elseif  playerLevel <= 40 then
        ItemSn, ItemName, _, bBroadCast = self:GetOneMissionBonusItem(g_MissionIndex40)
    elseif  playerLevel <= 50 then
        ItemSn, ItemName, _, bBroadCast = self:GetOneMissionBonusItem(g_MissionIndex50)
    elseif  playerLevel <= 60 then
        ItemSn, ItemName, _, bBroadCast = self:GetOneMissionBonusItem(g_MissionIndex60)
    elseif  playerLevel <= 70 then
        ItemSn, ItemName, _, bBroadCast = self:GetOneMissionBonusItem(g_MissionIndex70)
    elseif  playerLevel <= 80 then
        ItemSn, ItemName, _, bBroadCast = self:GetOneMissionBonusItem(g_MissionIndex80)
    else
        ItemSn, ItemName, _, bBroadCast = self:GetOneMissionBonusItem(g_MissionIndex90)
    end

    self:BeginAddItem()
        self:AddItem(ItemSn, 1 )
    local canAdd = self:EndAddItem(selfId)
    if canAdd then
        --奖励统计
        local itemName;
        _,itemName,_ = self:GetItemInfoByItemId(ItemSn)
        self:LuaFnAuditItemCreate(selfId,1,ItemSn,itemName,"Đào Bảo")
        self:AddItemListToHuman(selfId)
        local strText = string.format("Ngươi nhận được %s", ItemName)
        self:notify_tips(selfId, strText)
        local PlayName = self:GetName(selfId)
        local x, z = self:GetWorldPos(selfId)
        local _, sceneName = self:CallScriptFunction(g_ChengxiongdatuScriptId, "GetScenePosInfo", self.scene:get_id())
        ItemName = self:GetBagItemTransfer(selfId,0)
        local format = gbk.fromutf8("#W#{_INFOUSR%s}#cff99cc tại #G%s#cff99cc đào báu lúc may mắn nhận được #W#{_INFOMSG%s}")
        strText = string.format(format, gbk.fromutf8(PlayName), gbk.fromutf8(sceneName), ItemName)
        self:BroadMsgByChatPipe(selfId, strText, bBroadCast)
    else
        self:notify_tips(selfId, "Túi của ngươi đã đầy!")
        return 0
    end
    return 1
end

function common_item:GetDataIDbySceneID(sceneId)
    for i, SceneMapInfo in pairs(g_SceneMapDefine) do
        if SceneMapInfo.sceneId == sceneId then
            return SceneMapInfo.CorpseMonsterId
        end
    end
    return g_DefaultCorpseDataId
end

--**********************************
--放出僵尸
--**********************************
function common_item:DiscoverCorpseMonster_zhubo(selfId)
    local sceneid = self.scene:get_id()
	if sceneid == 377 or sceneid == 394 then
		if self:GetHumanGameFlag(selfId,"zhu_bo_flag") == 666 then
            local x, z = self:GetWorldPos(selfId)
            x = x + 2
			local  monsterLevel = self:GetLevel(selfId)
			for i = 1,g_zhu_bo_count do
				local aifile = math.random(10)
				local MonsterId = self:LuaFnCreateMonster(3519, x, z, 0, aifile, g_NpcScriptID)
				if MonsterId and MonsterId ~= -1 then
					self:SetLevel(MonsterId, monsterLevel)
				end
			end
			return true
		end
	end
end

--**********************************
--放出僵尸
--**********************************
function common_item:DiscoverCorpseMonster(selfId)
    local sceneid = self.scene:get_id()
    local corpseMonsterId = self:GetDataIDbySceneID(sceneid)
    local monster_count = self:GetMonsterCount()
    local corpseMonsters = {}
    for i = 1, monster_count do
        local nMonsterId = self:GetMonsterObjID(i)
        local dataId = self:GetMonsterDataID(nMonsterId)
        local reputation = self:GetUnitReputationID(nMonsterId, nMonsterId)
        if dataId == corpseMonsterId and reputation == 0 then
            local level = self:GetLevel(nMonsterId)
            corpseMonsters[level] = corpseMonsters[level] or {}
            table.insert(corpseMonsters[level], nMonsterId)
        end
    end
    for i=1, 10 do
        local _, sceneName, x, z, _ = self:CallScriptFunction(g_ChengxiongdatuScriptId, "GetScenePosInfo", sceneid)
        --至少保证在玩家身边出现一个夺宝马贼
        if i == 1 then
            x, z = self:GetWorldPos(selfId)
            x = x + 2
        end
        corpseMonsterId = corpseMonsterId or g_DefaultCorpseDataId
        local aifile = math.random(10)
        local MonsterId = self:LuaFnCreateMonster(corpseMonsterId, x, z, 0, aifile, g_NpcScriptID)
        self:SetCharacterDieTime(MonsterId, 60*60000)
        --设置对怪为友好的 目前是0号是友好的，如果有人改变了相应的势力声望那我就惨了！！:-(((
        self:SetUnitReputationID(selfId, MonsterId, 0)
        local  monsterLevel = self:GetLevel(MonsterId)
        local level =  monsterLevel+i-1
        self:SetLevel(MonsterId, level)
        local monsters = corpseMonsters[level] or {}
        if #monsters >= 10 then
            local objId = monsters[1]
            self:LuaFnDeleteMonster(objId)
        end
        --如果怪物的最大等级超过玩家最大等级上限，则怪物等级等于玩家最大等级上限
        local PlayerMaxLevel = self:GetHumanMaxLevelLimit()
        if level > PlayerMaxLevel then
            self:SetLevel(MonsterId, PlayerMaxLevel)
        end
    end
    self:notify_tips(selfId, "Thả Đạt Bảo Mã Tặc.")
    local _, sceneName = self:CallScriptFunction(g_ChengxiongdatuScriptId, "GetScenePosInfo", sceneid)
    local playerName = self:GetName(selfId)
    local strText = string.format("#W#{_INFOUSR%s}#cff99cckhi đào bảo lỡ lộ tin, tại#G%s#cff99ccdẫn tới một đám #{_BOSS48}. Chí sĩ giang hồ chỉ cần diệt mã tặc là nhận bảo tàng của chúng!",
                playerName, sceneName)
    strText = gbk.fromutf8(strText)
    self:BroadMsgByChatPipe(selfId, strText, 4)
end

--**********************************
--掉入宝藏
--**********************************
function common_item:DiscoverInstance(selfId)
    self:CallScriptFunction(g_DiaorubaozangScriptId, "MakeCopyScene", selfId, 0)
    self:notify_tips(selfId, "Rơi vào bảo tàng.")
end

--**********************************
--遭遇机关 --OK
--**********************************
function common_item:DiscoverTrap(selfId)
    local nHp = self:GetHp(selfId)
    local nMp = self:GetHp(selfId)
    local nHp = nHp * 0.3 --0.05
    local nMp = nMp * 0.3 --0.05

    if nHp < 1 then
        nHp = 1
    end
    if nMp < 1 then
        nMp = 1
    end

    self:SetHp(selfId, nHp)
    self:SetMp(selfId, nMp)

    self:notify_tips(selfId, "Gặp phải cơ quan")
end

--**********************************
--默认事件
--**********************************
function common_item:OnDefaultEvent(selfId, BagPos)
	-- if self:DiscoverCorpseMonster_zhubo(selfId) then
		-- return
	-- end
	local today = self:GetTime2Day()
	local open_count = 0
	local create_num = 0
	if today ~= self:GetMissionDataEx(selfId,ScriptGlobal.MDEX_MAZEI_TIME) then
		self:SetMissionDataEx(selfId,ScriptGlobal.MDEX_MAZEI,0)
		self:SetMissionDataEx(selfId,ScriptGlobal.MDEX_MAZEI_TIME,today)
	else
		open_count = self:GetMissionDataEx(selfId,ScriptGlobal.MDEX_MAZEI_TIME)
		create_num = open_count % base_item_count
	end
	if open_count >= open_item_count_day * base_item_count then
		self:notify_tips(selfId,"Hôm nay mở Mã Đồ đã tối đa, mai hãy tới.")
		return
	end
	--未满30级时轻涉宝藏恐有性命之虞啊
	if self:GetLevel(selfId) < 30 then
		self:BeginEvent(define.INVAILD_ID)
			self:AddText("Khi chưa đủ cấp 30, mạo muội đến bảo tàng sợ rằng nguy hiểm đến tính mạng đó.")
		self:EndEvent()
		self:DispatchEventList(selfId,-1)
		return
	end

	-- /////////////////////////////////////////////////////////////////
	-- 先取出物品中数据，如果是默认值0则说明是第一次使用，立即生成数据
	-- 如果已经有数据则什么都不做
	local targetSceneId, targetX, targetZ, r = self:GetItemParam(selfId, BagPos)
	if targetSceneId==nil or targetSceneId<=0
		or targetX==nil or targetX<=0
		or targetZ==nil or targetZ<=0
		or r==nil or r<=0 then
		--立即生成数据
		self:CallScriptFunction(g_ChengxiongdatuScriptId, "ProduceItemParamData", selfId, BagPos)
		--重新获取物品数据
		targetSceneId, targetX, targetZ, r = self:GetItemParam(selfId, BagPos)
        self:LuaFnRefreshItemInfo(selfId, BagPos)
	end
	-- 有些BT 我们再做一次检测
	if targetSceneId==nil or targetSceneId<=0
		or targetX==nil or targetX<=0
		or targetZ==nil or targetZ<=0
		or r==nil or r<=0 then
		--立即生成数据
		self:CallScriptFunction(g_ChengxiongdatuScriptId, "ProduceItemParamData", selfId, BagPos)
		--重新获取物品数据
		targetSceneId, targetX, targetZ, r = self:GetItemParam(selfId, BagPos)
	end
	--如果不在指定的场景, 指定的坐标就弹出对话框提示玩家去哪儿哪儿哪儿
	local sceneName = self:CallScriptFunction(g_ChengxiongdatuScriptId, "GetSceneName", selfId, targetSceneId)
	-- /////////////////////////////////////////////////////////////////

	local strText = self:ContactArgs("#{DTZDXL_210319_02", sceneName, targetX, targetZ, targetSceneId)
	--取得玩家当前坐标
	local PlayerX = self:GetHumanWorldX(selfId)
	local PlayerZ = self:GetHumanWorldZ(selfId)
	--计算玩家与目标点的距离
	local Distance = math.floor(math.sqrt((targetX-PlayerX)*(targetX-PlayerX)+(targetZ-PlayerZ)*(targetZ-PlayerZ)))
	if targetSceneId ~= self.scene:get_id() or Distance > r then
		self:BeginEvent(define.INVAILD_ID)
        self:AddText(strText .. "}")
        self:AddText("#e00f000Nhắc nhở nhỏ:#e000000 Đôi khi Tàng Bảo Đồ sẽ xuất hiện ở #gfff0f0bản đồ có Cấp độ cao hơn Cấp độ hiện tại của ngài#g000000, Cấp độ quái vật trên những bản đồ này tương đối cao, #gfff0f0xin hãy cẩn thận#g000000, ngài có thể đem Tàng Bảo Đồ bán cho Khác người chơi hoặc giữ lại đến khi Cấp độ của bản thân tăng lên rồi hãy sử dụng.")
		self:EndEvent()
		self:DispatchEventList(selfId,-1)
		return 0
	end

	--删除该物品
	if not self:LuaFnIsItemAvailable(selfId, BagPos) then
        self:notify_tips(selfId, "Vật phẩm của ngài hiện tại không khả dụng hoặc đã bị khóa.")
		return 0
	end
	open_count = open_count + base_item_count
	self:SetMissionDataEx(selfId,ScriptGlobal.MDEX_MAZEI,open_count)
	--如果在使用范围, 则随机触发以下事件
	local ret = math.random(100)
	if ret < 20 then --挖到银两
		self:DiscoverMoney(selfId)
	elseif ret < 50 then --放出僵尸
		if create_num < create_monster_day then
			open_count = open_count + 10
			self:SetMissionDataEx(selfId,ScriptGlobal.MDEX_MAZEI,open_count)
		self:DiscoverCorpseMonster(selfId)
		else
			self:DiscoverMoney(selfId)
		end
	elseif ret < 80 then --获得物品
		self:DiscoverMoney(selfId)
	elseif ret < 85 then --遇盗墓贼
		self:DiscoverInstance(selfId)
	elseif ret < 90 then --掉入宝藏
		if create_num < create_monster_day then
			open_count = open_count + 10
			self:SetMissionDataEx(selfId,ScriptGlobal.MDEX_MAZEI,open_count)
		self:DiscoverCorpseMonster(selfId)
		else
			self:DiscoverTrap(selfId)
		end
	else --遭遇机关
		self:DiscoverTrap(selfId)
	end

	self:EraseItem(selfId, BagPos )
	self:LuaFnAddMissionHuoYueZhi(selfId,4)
    self:LuaFnRefreshItemInfo(selfId, BagPos)
    return define.USEITEM_RESULT.USEITEM_SUCCESS
end

return common_item