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
	if 30501171 ~= nItemId then
		return 0
	end
	local FreeSpace = self:LuaFnGetPropertyBagSpace(selfId)
	if( FreeSpace < 2 ) then
	    local strNotice = "Ô đạo cụ đầy, xin chừa 2 chỗ."
		self:notify_tips(selfId, strNotice)
	    return 0
	end
	return 1 --不需要任何条件，并且始终返回1。
end

function common_item:OnDeplete(selfId)
	return 1
    -- return self:LuaFnDepletingUsedItem(selfId)
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
	if 30501171 ~= nItemId then
		return 0
	end
	self:LuaFnDecItemLayCount(selfId, BagPos, 1)
	local PetSkill = {30402021,30402022,30402023,30402024,30402032,30402012,30402014,30402016,30402018,30402020,30402034,30402036,30402038,30402040,30402042,30402044,30402046,30402048,30402050,
	30402051,30402052,30402053,30402054,30402056,30402058,30402060,30402062,30402064,30402066,30402068,30402070,30402068,30402070,30402072,30402074,30402076,30402078,30402080,30402092,30402094,
	}
	local nRandom = 0
	local start_index = 5
	if math.random(1000) <= start_index then
		nRandom = math.random(1,start_index)
	else
		nRandom = math.random(start_index + 1,#(PetSkill))
	end
	if not PetSkill[nRandom] then
		return
	end
	--30402003 30402099
	-- local nRandom = math.random(1,#(PetSkill))
    self:BeginAddItem()
    self:AddItem(30501318,1)
	self:AddItem(PetSkill[nRandom],1)
    if not self:EndAddItem(selfId) then
		return 0
    end
	self:AddItemListToHuman(selfId)
	self:notify_tips(selfId,"Nhận 1 trang sách cổ rách.")
	self:notify_tips(selfId,string.format("Nhận 1 quyển %s.",self:GetItemName(PetSkill[nRandom])))
	self:LuaFnSendSpecificImpactToUnit(selfId,selfId,selfId,18,0)
	return 1
end

return common_item
