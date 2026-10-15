local class = require "class"
local define = require "define"
local script_base = require "script_base"
local weekactive = class("weekactive", script_base)
local g_ZhouHuoYueItemId = {
	[1] = {item = 20310167, num = 250},
	[2] = {item = 50413004, num = 1},
	[3] = {item = 20310174, num = 250},
	[4] = {item = 50413004, num = 1},
	[5] = {item = 20310167, num = 250},
	[6] = {item = 50413004, num = 1},
	[7] = {item = 20310174, num = 250},
	[8] = {item = 50413004, num = 1},
	[9] = {item = 20310167, num = 250},
	[10] = {item = 50513004, num = 1},
	[11] = {item = 20310174, num = 250},
	[12] = {item = 50513004, num = 1},
	[13] = {item = 20310167, num = 250},
	[14] = {item = 50513004, num = 1},
	[15] = {item = 20310174, num = 250},
	[16] = {item = 50513004, num = 1},
	[17] = {item = 20310167, num = 250},
	[18] = {item = 50513004, num = 1},
	[19] = {item = 20310174, num = 250},
	[20] = {item = 50613004, num = 1},
}

local g_ProcessLimit = {
	[1] = {neednum = 200, itemspace = 2, materialspace = 0},
	[2] = {neednum = 400, itemspace = 2, materialspace = 0},
	[3] = {neednum = 600, itemspace = 2, materialspace = 0},
	[4] = {neednum = 800, itemspace = 1, materialspace = 1},
	[5] = {neednum = 1000, itemspace = 1, materialspace = 1},
	[6] = {neednum = 1200, itemspace = 1, materialspace = 1},
	[7] = {neednum = 1400, itemspace = 2, materialspace = 0},
	[8] = {neednum = 1600, itemspace = 1, materialspace = 1},
	[9] = {neednum = 1800, itemspace = 1, materialspace = 1},
	[10] = {neednum = 2000, itemspace = 2, materialspace = 0},
}

function weekactive:OpenUI(selfId)
    self:DispatchWeekActive(selfId)
end

function weekactive:AddHuoYueZhi(selfId, id)
    local result = self:WeekActiveAddHuoYueZhi(selfId, id)
    self:DispatchWeekActive(selfId)
    return result and 1 or 0
end

function weekactive:GetZhouHuoYueAward(selfId)
    local index = self:GetWeekActiveGetAwardIndex(selfId)
    index = index + 1
    local limit = g_ProcessLimit[index]
    local huoyue = self:GetWeekActiveHuoYue(selfId)
    if limit == nil then
        self:notify_tips(selfId, "Đã nhận hết")
        return
    end
    if huoyue < limit.neednum then
        self:notify_tips(selfId, "Không đủ điểm sôi nổi")
        return
    end
    if self:LuaFnGetPropertyBagSpace(selfId) < limit.itemspace
        or self:LuaFnGetMaterialBagSpace(selfId) < limit.materialspace then
        self:notify_tips(selfId, "Túi hành trang không đủ chỗ")
        return
    end
    local awards = { g_ZhouHuoYueItemId[2 * index - 1], g_ZhouHuoYueItemId[2 * index]}
    if #awards > 0 then
        for _, award in ipairs(awards) do
            self:TryRecieveItemWithCount(selfId, award.item, award.num,true)
        end
        self:SetWeekActiveGetAwardIndex(selfId, index)
        self:DispatchWeekActive(selfId)
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 149, 0)
    end
end

return weekactive
