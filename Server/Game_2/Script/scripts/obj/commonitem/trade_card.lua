local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ScriptGlobal = require "scripts.ScriptGlobal"

local trade_card = class("trade_card", script_base)
trade_card.script_id = 889936

function trade_card:OnDefaultEvent(selfId, bagIndex)
    -- 检查是否已有交易权限
    local flag = self:GetMissionFlag(selfId, ScriptGlobal.MF_TradeCard)
    if flag and flag ~= 0 then
        self:notify_tips(selfId, "Ngươi đã có quyền giao dịch, khỏi dùng lại.")
        return define.USEITEM_RESULT.USEITEM_FAIL
    end
    -- 设置交易权限标记
    self:SetMissionFlag(selfId, ScriptGlobal.MF_TradeCard, 1)
    -- 扣除道具
    self:EraseItem(selfId, bagIndex)
    -- 提示玩家
    self:notify_tips(selfId, "Dùng thẻ giao dịch thành công! Ngươi có quyền giao dịch.")
    return define.USEITEM_RESULT.USEITEM_SUCCESS
end

return trade_card
