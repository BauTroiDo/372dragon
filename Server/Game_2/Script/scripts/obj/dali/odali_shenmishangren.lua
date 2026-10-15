local class = require "class"
local define = require "define"
local script_base = require "script_base"
local odali_shenmishangren = class("odali_shenmishangren", script_base)
odali_shenmishangren.script_id = 900013
odali_shenmishangren.g_shoptableindexs = {239, 240, 241, 242, 243, 244, 245}

function odali_shenmishangren:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Chỗ của ta thỉnh thoảng sẽ có một ít đồ tốt, chỉ cần ngươi có nhẫn nại, nhất định sẽ tìm được thứ mà ngươi ưng ý nhất.#r Nhưng đồ tốt sẽ không thường xuyên có đâu, cơ bản là vừa lên kệ là sẽ bị người ta mua mất... ")
    self:AddNumText("Thần Bí Tiệm", 7, 1)
    self:AddNumText("Cơ Duyên Tiệm", 7, 3)
    self:AddNumText("Về Thần Bí Thương Điếm", 11, 2)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function odali_shenmishangren:NotifyTip(selfId, Msg)
    self:BeginEvent(self.script_id)
    self:AddText(Msg)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

function odali_shenmishangren:OnEventRequest(selfId, targetId, arg, index)
    if index == 1 then
        if self:GetLevel(selfId) < 30 then
            self:NotifyTip(selfId,"Chỉ người chơi trên cấp 30 mới xem tiệm thần bí được.")
            return
        end
        local i = os.date("%j") % (#self.g_shoptableindexs) + 1
        if i == 6 then
            i = 5
        end
        self:DispatchShopItem(selfId, targetId, self.g_shoptableindexs[i])
        return
    end
    if index == 2 then
        self:BeginEvent(self.script_id)
        self:AddText("#{SMYBSD_091102_03}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if index == 3 then
        self:DispatchJiYuanShopInfo(selfId, targetId)
        return
    end
end

return odali_shenmishangren
