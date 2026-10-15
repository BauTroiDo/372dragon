--圣兽山宝箱争夺
local gbk = require "wire_charset"
local class = require "class"
local define = require "define"
local script_base = require "script_base"
local WuYiXiangBoss_middle = class("WuYiXiangBoss_middle", script_base)
WuYiXiangBoss_middle.DataValidator = 0
WuYiXiangBoss_middle.script_id = 3000005
WuYiXiangBoss_middle.Poss = {
    { x = 55, y = 170}, { x = 70, y = 171}, { x = 81, y = 165}, { x = 99, y = 173}, { x = 99, y = 173}, { x = 118, y = 170}, { x = 145, y = 163}, { x = 178, y = 166}, { x = 193, y = 192}, { x = 208, y = 205},
    { x = 171, y = 210}, { x = 118, y = 200}, { x = 99, y = 208}, { x = 63, y = 209}, { x = 54, y = 127}, { x = 47, y = 209}, { x = 30, y = 139}, { x = 43, y = 117}, { x = 45, y = 79}, { x = 53, y = 47},
    { x = 67, y = 31}, { x = 113, y = 39}, { x = 182, y = 42}, { x = 200, y = 65}, { x = 218, y = 61}, { x = 186, y = 85}, { x = 150, y = 117}, { x = 163, y = 143}, { x = 192, y = 125}, { x = 204, y = 129},
    { x = 212, y = 155}, { x = 204, y = 204}, { x = 176, y = 212}
}
WuYiXiangBoss_middle.Nums = {
    68, 28, 38, 38, 28, 68, 88, 52, 58, 66, 36, 18, 59, 38, 47, 32, 38, 28, 18, 28, 88, 39, 22, 17, 23, 77, 38, 88, 18, 57, 36, 28, 79, 25, 26, 69, 58, 88, 60, 88, 72, 48, 58, 88, 29, 68, 58, 55, 53, 73,
    68, 28, 38, 38, 28, 68, 88, 52, 58, 66, 36, 18, 59, 38, 47, 32, 38, 28, 18, 28, 88, 39, 22, 17, 23, 77, 38, 88, 18, 57, 36, 28, 79, 25, 26, 69, 58, 88, 60, 88, 72, 48, 58, 88, 29, 68, 58, 55, 53, 73
}
WuYiXiangBoss_middle.g_BigBox = {
	Name		= "Bảo vật Ô Y Hạng thiên ngoại",
	MonsterID	= 5011,
	ScriptID	= 3000007
}
WuYiXiangBoss_middle.Bosss = {
    51005,
    51006
}
WuYiXiangBoss_middle.IDX_ITEM_ID = 1
WuYiXiangBoss_middle.IDX_ITEM_NUM = 2
WuYiXiangBoss_middle.IDX_BOX_OPEN_OID = 3
WuYiXiangBoss_middle.IDX_BOX_OPEN_TIME = 4
WuYiXiangBoss_middle.IDX_MONSTER_KILLER_GUID = 5
function WuYiXiangBoss_middle:OnDefaultEvent(actId, iNoticeType, param2, param3, param4, param5, param6)
	if param6 ~= WuYiXiangBoss_middle.DataValidator then
		return
	elseif not iNoticeType or not param2 or not param3 or not param4 or not param5 then
		return
	end
	local sceneId = self:get_scene_id()
	--雷电交加天气效果....
	local curWeather = self:LuaFnGetSceneWeather(sceneId)
	if not curWeather or curWeather ~= -1 then
		--已经有天气了则不改变天气....
	else
		self:LuaFnSetSceneWeather(3, 5*60*1000 )
	end
    for i, pos in ipairs(self.Poss) do
        local MonsterID = self.Bosss[math.random(1, 2)]
        local MstId = self:LuaFnCreateMonster(MonsterID, pos.x + 2, pos.y - 2, 0, 0, self.script_id)
        self:MonsterAI_SetIntParamByIndex(MstId, self.IDX_ITEM_NUM, self.Nums[(i - 1) * 3 + 1])
		self:LuaFnSetNpcIntParameter(MstId, 6, sceneId)
		self:LuaFnSetNpcIntParameter(MstId, 7, actId + 1)
		
        MonsterID = self.Bosss[math.random(1, 2)]
        MstId = self:LuaFnCreateMonster(MonsterID, pos.x + 4, pos.y - 4, 0, 0, self.script_id)
        self:MonsterAI_SetIntParamByIndex(MstId, self.IDX_ITEM_NUM, self.Nums[(i - 1) * 3 + 2])
		self:LuaFnSetNpcIntParameter(MstId, 6, sceneId)
		self:LuaFnSetNpcIntParameter(MstId, 7, actId + 1)
        MonsterID = self.Bosss[math.random(1, 2)]
        MstId = self:LuaFnCreateMonster(MonsterID, pos.x, pos.y, 0, 0, self.script_id)
        self:MonsterAI_SetIntParamByIndex(MstId, self.IDX_ITEM_NUM, self.Nums[(i - 1) * 3 + 3])
		self:LuaFnSetNpcIntParameter(MstId, 6, sceneId)
		self:LuaFnSetNpcIntParameter(MstId, 7, actId + 1)
    end
	local NotifyMsg = "@*;SrvMsg;SCA:#GBoss Thiên Ngoại#Pđã giáng lâm Trường Xuân Cốc - Ô Y Hạng#P, xin thoại với Long Bá Thiên ở Lạc Dương để tới, đánh bại mở rương nhận vô số thưởng hiếm"
	self:AddGlobalCountNews(NotifyMsg)
end
function WuYiXiangBoss_middle:OnTimer(actId, uTime, param1)
	if not uTime or uTime ~= param1 then
		return
	end
    -- if not self:CheckActiviyValidity(actId) then
        -- self:StopOneWuYiXiangBoss_middle(actId)
    -- end
end
function WuYiXiangBoss_middle:GetDataValidator(param1,param2)
	WuYiXiangBoss_middle.DataValidator = math.random(1,2100000000)
	return WuYiXiangBoss_middle.DataValidator
end

function WuYiXiangBoss_middle:OnDie(objId, killerId)
	if self:LuaFnGetNpcIntParameter(objId,6) ~= sceneId then
			self:notify_tips(selfId, "Không do hoạt động tạo")
		return
	end
	local actId = self:LuaFnGetNpcIntParameter(objId,7)
	if not actId or actId < 1 then
			self:notify_tips(selfId, "Không do hoạt động tạo")
		return
	end
	actId = actId - 1
    local activity = self:CheckActiviyValidity(actId)
    if not self:CheckActiviyValidity(actId) then
		self:notify_tips(selfId, "hoạt động đã kết thúc")
        return
    end

    local x, y = self:LuaFnGetWorldPos(objId)
    local num = self:MonsterAI_GetIntParamByIndex(objId, self.IDX_ITEM_NUM)
    num = num <= 0 and 1 or num
    num = num > 100 and 1 or num
    local PlayerGUID = self:LuaFnGetGUID(killerId)
    local MstId = self:LuaFnCreateMonster(self.g_BigBox.MonsterID, x, y, 3, 0, self.g_BigBox.ScriptID,90 )
    self:SetCharacterName(MstId, self.g_BigBox.Name )
    self:SetCharacterDieTime(MstId, 60 * 60 * 1000)
	self:MonsterAI_SetIntParamByIndex(MstId, self.IDX_ITEM_ID, 38008157)
	self:MonsterAI_SetIntParamByIndex(MstId, self.IDX_ITEM_NUM, num)
    self:MonsterAI_SetIntParamByIndex(MstId, self.IDX_MONSTER_KILLER_GUID, PlayerGUID)
end

function WuYiXiangBoss_middle:CheckOpenBigBox(activatorId, selfId)
	local opening_oid = self:MonsterAI_GetIntParamByIndex(selfId, self.IDX_BOX_OPEN_OID)
	--如果有人正在开大宝箱....
	local NowTime = self:LuaFnGetCurrentTime()
	if opening_oid ~= 0 then
		--如果是自己在开....
		if opening_oid == activatorId then
			return 1, "(ERROR)"
		end
		local opening_time = self:MonsterAI_GetIntParamByIndex(selfId, self.IDX_BOX_OPEN_TIME)
		--如果是别人在开并且他已经超时了....则让位给我来开....
		if (NowTime - opening_time) > 150 then
			self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_BOX_OPEN_TIME, NowTime)
			self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_BOX_OPEN_OID, activatorId)
			return 1, "(ERROR)"
		else
			return -1, self:GetName(opening_oid)
		end
	end
	--没有人在开大宝箱....
	self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_BOX_OPEN_TIME, NowTime)
	self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_BOX_OPEN_OID, activatorId)
	return 1, "(ERROR)"
end


function WuYiXiangBoss_middle:OnCancelOpenXXX(selfId)
	self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_BOX_OPEN_OID, 0)
end

function WuYiXiangBoss_middle:OnBigBoxOpen( selfId, activatorId )
	local item_id = self:MonsterAI_GetIntParamByIndex(selfId, self.IDX_ITEM_ID)
	local item_num = self:MonsterAI_GetIntParamByIndex(selfId, self.IDX_ITEM_NUM)
	local BagIndex = self:TryRecieveItemWithCount(activatorId, item_id, item_num, false)
	if BagIndex ~= -1 then
		self:BeginEvent(self.script_id)
        self:AddText("Ngươi nhận được" .. item_num .. "#{_ITEM"..item_id.."}" )
		self:EndEvent()
		self:DispatchMissionTips(activatorId )

		--公告....
		local ItemTransfer = self:GetBagItemTransfer(activatorId,BagIndex)
		local PlayerName = self:GetName(activatorId)
		local fmt = gbk.fromutf8("#W#{_INFOUSR%s}#Ptại#GTrường Xuân Cốc - Ô Y Hạng#Pđốt lửa xông khói lỡ cay mắt, mơ hồ đâm vào#Y" .. self.g_BigBox.Name .. "#P, mở ra xem, hóa ra là#{_INFOMSG%s}#G" .. item_num .. "#Pcái.")
		local str = string.format(fmt, gbk.fromutf8(PlayerName), ItemTransfer)
		self:BroadMsgByChatPipe(activatorId, str, 4 )
	end
	--kill大宝箱....大宝箱死亡动画为打开盖子....
	self:LuaFnSendSpecificImpactToUnit( selfId, selfId, selfId, 169, 0);
	self:LuaFnGmKillObj(selfId, activatorId)

	self:LOGI(string.format("Người chơi %d mở rương Thiên Ngoại, nhận đạo cụ %d tổng %d cái", self:LuaFnGetGUID(activatorId), item_id, item_num))
end

return WuYiXiangBoss_middle