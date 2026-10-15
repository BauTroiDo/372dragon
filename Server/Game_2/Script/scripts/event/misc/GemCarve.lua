-- 装备打孔
-- 普通
local gbk = require "wire_charset"
local class = require "class"
local define = require "define"
local configenginer = require "configenginer":getinstance()
local script_base = require "script_base"
local GemCarve = class("GemCarve", script_base)
function GemCarve:OnGemCarve(...)
    print("GemCarve:OnGemCarve =", ...)
    local selfId, GemItemPos, NeedItemPos, TargetId = ...
	-- if self:LuaFnGetMaterialBagSpace(selfId) < 1 then
        -- self:notify_tips(selfId, "请给材料栏预留一空位。")
        -- return
    -- end
    if TargetId == nil then return end
    if TargetId == -1 then return end
    if GemItemPos == -1 or NeedItemPos == -1 then return end
    local GemItem = self:GetBagItem(selfId, GemItemPos)
    local NeedItem = self:GetBagItem(selfId, NeedItemPos)
    local gem_carve = configenginer:get_config("gem_carve")
    local config = gem_carve[GemItem:get_index()]
    if config == nil then return end
    if config.need_item ~= NeedItem:get_index() then return end
    if not self:LuaFnIsItemAvailable(selfId, GemItemPos) then
        self:notify_tips(selfId, "Bảo thạch không thể sử dụng, Điều khắc Bảo thạch thất bại.")
        return
    end
    if not self:LuaFnIsItemAvailable(selfId, NeedItemPos) then
        self:notify_tips(selfId,
                         "Vật phẩm cần thiết không thể sử dụng, Điều khắc Bảo thạch thất bại.")
        return
    end
    local space_count = self:LuaFnGetMaterialBagSpace(selfId)
    if space_count <= 0 then
        self:notify_tips(selfId, "Ô nguyên liệu thiếu chỗ, không điêu trác được, xin chừa ít nhất một ô")
        return
    end
    local NeedItemInfo = self:GetBagItemTransfer(selfId, NeedItemPos)
    local del = self:LuaFnDecItemLayCount(selfId, GemItemPos, 1)
	if not del then
		return
	end
   local del = self:LuaFnDecItemLayCount(selfId, NeedItemPos, 1)
	if not del then
		return
	end
    if not self:LuaFnCostMoneyWithPriority(selfId, config.need_money) then
        self:notify_tips(selfId, "Kim tiền không đủ, Điều khắc Bảo thạch thất bại.")
        return
    end
    local BagPos = self:TryRecieveItem(selfId, config.product_id, true)
    if BagPos == define.INVAILD_ID then
        self:notify_tips(selfId, "Túi đã đầy, Điều khắc Bảo thạch thất bại.")
        return
    end
    -- 公告精简，只保留3级以上的宝石雕琢公告
    local gemQual = self:GetItemQuality(config.product_id)
    if (gemQual > 4) then
        -- 公告....
        local Name = self:GetName(selfId)
        local SceneName = self:GetSceneName()
        local NPCName = self:GetName(TargetId)
        local GemItemInfo = self:GetBagItemTransfer(selfId, BagPos)
        local format = gbk.fromutf8(
                           "#{_INFOUSR%s}#I tại #G%s#R%s#I tại #{_INFOMSG%s}#I Điều khắc ra một viên #{_INFOMSG%s}#I, %s nhất thời bảo quang trùng thiên.")
        local strText = string.format(format, gbk.fromutf8(Name),
                                      gbk.fromutf8(SceneName),
                                      gbk.fromutf8(NPCName), NeedItemInfo,
                                      GemItemInfo, gbk.fromutf8(SceneName))

        self:BroadMsgByChatPipe(selfId, strText, 4)
    end

    self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 49, 0)
end

function GemCarve:notify_tip(selfId, msg)
    self:BeginEvent()
    self:AddText(msg)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

return GemCarve
