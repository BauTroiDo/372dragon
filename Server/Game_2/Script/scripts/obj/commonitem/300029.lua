local class = require "class"
local define = require "define"
local script_base = require "script_base"
local common_item = class("common_item", script_base)

local g_itemList = {}
g_itemList[30501003] = {impactId=4828}
g_itemList[30501007] = {impactId=4836}
g_itemList[30501008] = {impactId=4837}
g_itemList[30501009] = {impactId=4838}
g_itemList[30501010] = {impactId=4839}
g_itemList[30501011] = {impactId=4840}
g_itemList[30501012] = {impactId=4841}
g_itemList[30501013] = {impactId=4842}
g_itemList[30501014] = {impactId=4843}
g_itemList[30501015] = {impactId=4844}
g_itemList[30501016] = {impactId=4845}
g_itemList[30501101] = {impactId=4846}
g_itemList[30501102] = {impactId=4847}
g_itemList[30505132] = {impactId=4848}
g_itemList[30501107] = {impactId=4849}
g_itemList[30501108] = {impactId=4850}
g_itemList[30501109] = {impactId=4851}
g_itemList[30501110] = {impactId=4852}
g_itemList[30501111] = {impactId=4853}
g_itemList[30501112] = {impactId=4854}
g_itemList[30501113] = {impactId=4855}
g_itemList[30501114] = {impactId=4856}
g_itemList[30501115] = {impactId=4857}
g_itemList[30501116] = {impactId=4858}
g_itemList[30501125] = {impactId=4860}
g_itemList[30501126] = {impactId=4861}
g_itemList[30501127] = {impactId=4862}
g_itemList[30501128] = {impactId=4863}
g_itemList[30501129] = {impactId=4864}
g_itemList[30501130] = {impactId=4865}
g_itemList[30501131] = {impactId=4860}
g_itemList[30501132] = {impactId=4861}
g_itemList[30501133] = {impactId=4862}
g_itemList[30501134] = {impactId=4846}
g_itemList[30501135] = {impactId=4847}
g_itemList[30501136] = {impactId=4848}
g_itemList[30501137] = {impactId=4828}
g_itemList[30501138] = {impactId=4836}
g_itemList[30501139] = {impactId=4837}
g_itemList[30501140] = {impactId=4838}
g_itemList[30501141] = {impactId=4839}
g_itemList[30501142] = {impactId=4840}
g_itemList[30501143] = {impactId=4841}
g_itemList[30501144] = {impactId=4842}
g_itemList[30501145] = {impactId=4843}
g_itemList[30501146] = {impactId=4844}
g_itemList[30501147] = {impactId=4845}
g_itemList[30501148] = {impactId=4866}
g_itemList[30501149] = {impactId=4867}
g_itemList[30501150] = {impactId=4868}
g_itemList[30501151] = {impactId=4866}
g_itemList[30501152] = {impactId=4867}
g_itemList[30501153] = {impactId=4868}
g_itemList[30501154] = {impactId=4869}
g_itemList[30501155] = {impactId=4870}
g_itemList[30501156] = {impactId=4871}
g_itemList[30501157] = {impactId=4873}
g_itemList[30501158] = {impactId=4872}
g_itemList[30501159] = {impactId=4873}
g_itemList[30501160] = {impactId=4872}
g_itemList[30501163] = {impactId=4856}
g_itemList[30501164] = {impactId=4854}
g_itemList[30501165] = {impactId=4855}
g_itemList[30503022] = {impactId=4876} --礼盒变身
g_itemList[30503023] = {impactId=4877} --玫瑰花变身
g_itemList[30503024] = {impactId=4878} --兔爷变身

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
    return 1
end

function common_item:OnDeplete(selfId)
    return self:LuaFnDepletingUsedItem(selfId)
end

function common_item:OnActivateOnce(selfId)
	local itemTblIndex = self:LuaFnGetItemIndexOfUsedItem(selfId )
	local itemCur = g_itemList[itemTblIndex]
	if not itemCur then
		self:notify_tips(selfId, "Đạo cụ chưa mở, không thể sử dụng.")
		return 0;
	end
	
	if(-1~=itemCur.impactId) then
		self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, itemCur.impactId, 0)
	end
    return 1
end

return common_item