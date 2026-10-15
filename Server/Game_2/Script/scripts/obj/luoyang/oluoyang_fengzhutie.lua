local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oluoyang_fengzhutie = class("oluoyang_fengzhutie", script_base)
oluoyang_fengzhutie.script_id = 000141
oluoyang_fengzhutie.g_shoptableindex = 167
oluoyang_fengzhutie.g_eventList = {713538}

function oluoyang_fengzhutie:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText(
        "  Muốn học Kỹ năng Chế Tác Nguyên Liệu không? Nhấn vào \"Học Chế Tác Nguyên Liệu\" Nút phía dưới, là có thể học Kỹ năng Chế Tác Nguyên Liệu rồi.")
    self:AddText(
        "  Chế Tác Nguyên Liệu yêu cầu sự kiên nhẫn và bền bỉ, mới có thể tạo ra số lượng lớn thành phẩm tổng hợp. Mà những thành phẩm này là điều tất yếu để tu luyện ba Kỹ năng sống: Công Nghệ, Đúc và May. Nếu như ngươi muốn nâng cao ba Kỹ năng sống: Công Nghệ, Đúc và May của ngươi, vậy thì nhất định phải học Chế Tác Nguyên Liệu!")
    self:AddText(
        "  Chú ý: Học \"Chế Tác Nguyên Liệu\" Yêu cầu tiêu hao #{_EXCHG10000}, đừng quên mang theo!")
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:AddNumText("Mua Công Thức Chế Tác Nguyên Liệu", 7, 99)
    self:AddNumText("Chế Tác Nguyên Liệu tửu quán", 11, 100)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oluoyang_fengzhutie:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function oluoyang_fengzhutie:OnEventRequest(selfId, targetId, arg, index)
    if index == 100 then
        self:BeginEvent(self.script_id)
        self:AddText("#{HELP_CLJG}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if index == 99 then
        self:DispatchShopItem(selfId, targetId, self.g_shoptableindex)
    end
    for i, findId in pairs(self.g_eventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId,
                                    index, self.script_id)
            return
        end
    end
end

function oluoyang_fengzhutie:OnMissionAccept(selfId, targetId, missionScriptId) end

function oluoyang_fengzhutie:OnMissionRefuse(selfId, targetId, missionScriptId) end

function oluoyang_fengzhutie:OnMissionContinue(selfId, targetId, missionScriptId)

end

function oluoyang_fengzhutie:OnMissionSubmit(selfId, targetId, missionScriptId,
                                             selectRadioId) end

function oluoyang_fengzhutie:OnDie(selfId, killerId) end

return oluoyang_fengzhutie
