local class = require "class"
local define = require "define"
local script_base = require "script_base"
local WuYouBag = class("WuYouBag", script_base)
WuYouBag.script_id = 100019
WuYouBag.g_ItemInfo = { 
10402001, 10414054, 10415054, 10422152, 10422152, 10423060, 10423061, 
10553090, 10553091, 10553092, 10553093, 10553094, 10553095}
WuYouBag.g_gemInfo = {
    [1] = {
	  { 50302005, 50303001, 50304002}
    , { 50302007, 50303001, 50304002}
    , { 50302008, 50303001, 50304002}
    , { 50302006, 50303001, 50304002}
    , { 50302006, 50303001, 50304002}
    , { 50302008, 50303001, 50304002}
    , { 50302005, 50303001, 50304002}
    , { 50302006, 50303001, 50304002}
    , { 50302007, 50303001, 50304002}
    , { 50302005, 50303001, 50304002}
    , { 50302005, 50303001, 50304002}
    }
    ,
    [2] = {{ 50313004, 50314001, 50311001 }
    , { 50313004, 50314001, 50311001}
    , { 50313004, 50314001, 50311001}
    , { 50313004, 50314001, 50311001}
    , { 50313004, 50314001, 50311001}
    , { 50313004, 50314001, 50311001}
    , { 50313004, 50314001, 50311001}
    , { 50313004, 50314001, 50311001}
    , { 50313004, 50314001, 50311001}
    , { 50313004, 50314001, 50311001}
    , { 50313004, 50314001, 50311001}
    }
}
function WuYouBag:OnDefaultEvent(selfId, bagIndex)
end

function WuYouBag:IsSkillLikeScript(selfId)
    return 1
end

function WuYouBag:CancelImpacts(selfId)
    return 0
end

function WuYouBag:OnConditionCheck(selfId)
    if not self:LuaFnVerifyUsedItem(selfId) then
        return 0
    end
    local itemTblIndex = self:LuaFnGetItemIndexOfUsedItem(selfId)
    local nMenPai = self:GetMenPai(selfId)
    if nMenPai == 9 then
        self:ShowNotice(selfId, "Xin hãy gia nhập Môn phái trước.")
        return 0 
    end
    if itemTblIndex ~= 38000958 then
        self:ShowNotice(selfId, "Vật phẩm không hợp lệ.")
        return 0
    end
    self:BeginAddItem()
    for i = 1, #self.g_ItemInfo do
        self:AddItem(self.g_ItemInfo[i], 1)
    end
    if not self:EndAddItem(selfId) then
        self:ShowNotice(selfId, "Túi đồ không đủ chỗ trống.")
        return 0
    end
    local nBagsPos = self:LuaFnGetPropertyBagSpace(selfId)
    if nBagsPos < 13 then
        self:ShowNotice(selfId, "Túi đồ không đủ chỗ trống.")
        return 0
    end
    return 1
end

function WuYouBag:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function WuYouBag:OnActivateOnce(selfId)
    local nMenPai = self:GetMenPai(selfId)
    nMenPai = nMenPai + 1
    local itemTblIndex = self:LuaFnGetItemIndexOfUsedItem(selfId)
    if itemTblIndex == 38000958 then
        local equiptype = { 1, 1, 2, 1, 1, 1, 1, 2, 2, 2, 2, 2, 1 }
        for i = 1, 13 do
            local ibagidx1 = self:TryRecieveItem(selfId, self.g_ItemInfo[i], 1,true)
            if ibagidx1 ~= -1 then
                local equipMaxGemCount = self:GetBagGemCount(selfId, ibagidx1)
                while equipMaxGemCount < 3 do
                    self:AddBagItemSlot(selfId, ibagidx1)
                    equipMaxGemCount = self:GetBagGemCount(selfId, ibagidx1)
                end
                for j = 1, 3 do
                    local gemId = self.g_gemInfo[equiptype[i]][nMenPai][j]
                    local BagIndex = self:TryRecieveItem(selfId, gemId, 1,true)
                    if BagIndex ~= -1 then
                        self:GemEnchasing(selfId, BagIndex, ibagidx1,j)
                    end
                end
                self:LuaFnItemBind(selfId, ibagidx1)
            end
        end
        self:notify_tips(selfId, "  Chúc mừng bạn nhận bộ trang bị Vô Ưu dùng cho giai đoạn đầu.")
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 18, 0)
    end
    return 1
end

function WuYouBag:OnActivateEachTick(selfId)
    return 1
end

function WuYouBag:ShowNotice(selfId, strNotice)
    self:BeginEvent(self.script_id)
    self:AddText(strNotice)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

return WuYouBag
