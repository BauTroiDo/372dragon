local class = require "class"
local define = require "define"
local script_base = require "script_base"


local common_item = class("common_item", script_base)

function common_item:IsSkillLikeScript()
    return 1
end

function common_item:CancelImpacts()
    return 0
end

function common_item:OnConditionCheck(selfId)
    if not self:LuaFnVerifyUsedItem(selfId) then
        return 0
    end
    local BagPos = self:LuaFnGetBagIndexOfUsedItem(selfId)
	local nItemId = self:GetItemTableIndexByIndex(selfId, BagPos)
	if 38008300 ~= nItemId then
		return 0
	end
	local FreeSpace = self:LuaFnGetPropertyBagSpace(selfId)
	if( FreeSpace < 2 ) then
	    local strNotice = "Ô đạo cụ đầy, xin chừa 2 chỗ."
		self:notify_tips(selfId, strNotice)  
	    return 0
	end
	return 1
end


function common_item:OnDeplete(selfId)
	return 1
end

function common_item:OnActivateOnce(selfId)
	local FreeSpace = self:LuaFnGetPropertyBagSpace(selfId)
	local strNotice = "Ô đạo cụ đầy, xin chừa 2 chỗ."
	if( FreeSpace < 2 ) then
		self:notify_tips(selfId, strNotice)
	    return 0
	end
    local BagPos = self:LuaFnGetBagIndexOfUsedItem(selfId)
	local nItemId = self:GetItemTableIndexByIndex(selfId, BagPos)
	if 38008300 ~= nItemId then
		return 0
	end
	self:LuaFnDecItemLayCount(selfId, BagPos, 1)
	
	local HuoDongItem = {
		--熊赳赳,冬夜小熊,熊爪棒冰,小熊甜筒,萌熊出没
        38003723,38003724,38003728,38003729,10126710,
		--超级长春玉,神魂檀箱,灵玑瑶盘,琉璃金盏,沧海游鳞,凤舞沙华,玄莲道影,九幽鸩鼎
        20600003,38002499,20800000,20800002,20800004,20800006,20800008,20800010,
		--至尊强化精华,点数卡20点
        38008160,38008168

    }
	local nRandom = 0
	local start_index = 2 
	if math.random(100) <= start_index then
		nRandom = math.random(1,5)
	else
		nRandom = math.random(6,#(HuoDongItem))
	end
	if not HuoDongItem[nRandom] then
		return
	end
    self:BeginAddItem()
	self:AddItem(HuoDongItem[nRandom],1)
    if not self:EndAddItem(selfId) then
		return 0
    end
	self:AddItemListToHuman(selfId)
	self:notify_tips(selfId,string.format("Chúc mừng bạn nhận được: %s.",self:GetItemName(HuoDongItem[nRandom])))
	self:LuaFnSendSpecificImpactToUnit(selfId,selfId,selfId,18,0)	
	return 1
end

return common_item