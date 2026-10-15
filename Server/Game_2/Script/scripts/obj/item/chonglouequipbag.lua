local class = require "class"
local define = require "define"
local script_base = require "script_base"
local chonglouequipbag = class("chonglouequipbag", script_base)
--暂开放至多五个道具选择
local PlayerSelectAward = {
	{
		needitem = 38002943,
		needcount = 1,
		title = "#gFF0FA0Trùng Lâu chọn 1 trong 2",
		{10422150,1},
		{10423026,1},
	},
	{
		needitem = 38008166,
		needcount = 1,
		title = "#gFF0FA0Tọa kỵ chọn 1 trong 4",
		{10141095,1},
		{10142847,1},
		{10141846,1},
		{10141906,1},
	},
	{
		needitem = 38008167,
		needcount = 1,
		title = "#gFF0FA0Thời trang chọn 1 trong 4",
		{10125152,1},
		{10124570,1},
		{10124868,1},
		{10125293,1},
		{10125954,1},
	},
	{
		needitem = 38008186,
		needcount = 1,
		title = "#gFF0FA0Tọa kỵ chọn 1 trong 4",
		{10142536,1},
		{10142554,1},
		{10142572,1},
		{10142590,1},
	},
	{
		needitem = 38008187,
		needcount = 1,
		title = "#gFF0FA0Tọa kỵ chọn 1 trong 4",
		{10142928,1},
		{10142929,1},
		{10142930,1},
		{10142931,1},
	},
}
-- chonglouequipbag.g_tableRewardInfo = { 10422150, 10423024 }
chonglouequipbag.script_id = 892042
function chonglouequipbag:IsSkillLikeScript(selfId)
    return 1
end

function chonglouequipbag:CancelImpacts(selfId)
    return 0
end

function chonglouequipbag:OnConditionCheck(selfId)
    if not self:LuaFnVerifyUsedItem(selfId) then
        return 0
    end
    return 1
end

function chonglouequipbag:OnDeplete(selfId)
    -- if self:LuaFnDepletingUsedItem(selfId) then
        -- return 1
    -- end
    return 1
end

function chonglouequipbag:OnActivateOnce(selfId)
    local nItemId = self:LuaFnGetItemIndexOfUsedItem(selfId)
	for i,j in ipairs(PlayerSelectAward) do
		if i <= 5 then
			if j.needitem == nItemId then
				local addcount = 0
				self:BeginUICommand()
				self:UICommand_AddInt(nItemId)
				for m,n in ipairs(j) do
					self:UICommand_AddInt(n[1])
					self:UICommand_AddInt(n[2])
					addcount = addcount + 1
				end
				self:UICommand_AddStr(tostring(addcount))
				self:UICommand_AddStr(tostring(j.title))
				self:EndUICommand()
				self:DispatchUICommand(selfId, 2023061200)
				return
			end
		end
	end
	self:NotifyFailTips(selfId,"Vật phẩm không hợp lệ.")
    return 1
end

function chonglouequipbag:OpenTwoGift(selfId,nItemId,nSelect)
	if not nItemId or not nSelect or nSelect < 1 or nSelect > 5 then
		return
	-- elseif self:LuaFnGetItemIndexOfUsedItem(selfId) ~= nItemId then
        -- self:NotifyFailTips(selfId,"物品非法。。")
        -- return
	end
	local awardinfo
	for i,j in ipairs(PlayerSelectAward) do
		if j.needitem == nItemId then
			awardinfo = j
			break
		end
	end
	if not awardinfo then
        self:NotifyFailTips(selfId,"Vật phẩm không hợp lệ.")
        return
    end
	local selectitem = awardinfo[nSelect]
	if not selectitem then
        self:NotifyFailTips(selfId,"Chọn bất thường.")
        return
    end
    self:BeginAddItem()
	self:AddItem(selectitem[1], selectitem[2],true)
    if not self:EndAddItem(selfId) then
		self:BeginAddItem()
        self:NotifyFailTips(selfId,"Túi đồ không đủ chỗ trống.")
        return
    end
	local del,count = self:LuaFnDelAvailableItem(selfId, nItemId, awardinfo.needcount)
	if del then
		self:AddItemListToHuman(selfId)
		self:BeginAddItem()
		self:NotifyFailTips(selfId, string.format("Bạn nhận %s %d cái.", self:GetItemName(selectitem[1]),selectitem[2]))
		self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 49, 0)
		self:BeginUICommand()
		self:EndUICommand()
		self:DispatchUICommand(selfId, 2023061201)
	else
		self:NotifyFailTips(selfId,"Trừ đạo cụ thất bại.")
	end
end

function chonglouequipbag:OnActivateEachTick(selfId)
    return 1
end

function chonglouequipbag:NotifyFailTips(selfId, Tip)
    self:BeginEvent(self.script_id)
    self:AddText(Tip)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

return chonglouequipbag
