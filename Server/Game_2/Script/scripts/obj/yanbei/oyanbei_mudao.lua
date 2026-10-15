local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oyanbei_mudao = class("oyanbei_mudao", script_base)
oyanbei_mudao.script_id = 019033
oyanbei_mudao.g_eventList = {}
local EquipInfo = 
{
    [1] = {10410001,10422013,10420004,10423021,15},
    [2] = {10410002,10422014,10420005,10423022,30},
    [3] = {10410003,10422015,10420006,10423023,60},
}
local YanXianYu = {20310000,20310003}
function oyanbei_mudao:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Ngươi muốn đổi bảo vật của ta ư? Vậy ngươi e rằng phải chuẩn bị cả một bao tải Yến Huyền Ngọc mới được, thứ đó trong cổ mộ nhiều vô kể, chỉ xem ngươi có mệnh mang ra được không thôi.")
    self:AddNumText("Đổi Bộ Trang bị cấp 50", 6, 1)
    self:AddNumText("Đổi Bộ Trang bị cấp 60", 6, 2)
    self:AddNumText("Đổi Bộ Trang bị cấp 70", 6, 3)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oyanbei_mudao:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function oyanbei_mudao:OnEventRequest(selfId, targetId, arg, index)
    if index >= 1 and index <= 3 then
        self:BeginEvent(self.script_id)
        self:AddText("Nếu ngươi nỡ đem"..EquipInfo[index][5].."Huyền Hạo Ngọc đưa ta là chọn được một món trang bị dưới đây:")
        for i = 1,4 do
            self:AddRadioItemBonus(EquipInfo[index][i],4)
        end
        self:EndEvent()
        self:DispatchMissionContinueInfo(selfId,targetId,20231015, 0)
    end
end

function oyanbei_mudao:OnMissionAccept(selfId, targetId, missionScriptId)
end

function oyanbei_mudao:OnMissionRefuse(selfId, targetId, missionScriptId)
end

function oyanbei_mudao:OnMissionContinue(selfId, targetId, missionScriptId)
end

function oyanbei_mudao:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    if missionScriptId == 20231015 then
        local nIndex = 0
        for i = 1,3 do
            for j = 1,4 do
                if selectRadioId == EquipInfo[i][j] then
                    nIndex = i
                    break
                end
            end
        end
        local num = 0
        for i = 1,2 do
            num = num + self:LuaFnGetAvailableItemCount(selfId,YanXianYu[i])
        end
        if num < EquipInfo[nIndex][5] then
            self:notify_tips(selfId,"Ngươi không có đủ Nguyên liệu để đổi lấy vật phẩm này.")
            return
        end
        local nRet,nCount
        if self:LuaFnGetAvailableItemCount(selfId,YanXianYu[1]) >= EquipInfo[nIndex][5] then
            nRet = self:LuaFnDelAvailableItem(selfId,YanXianYu[1],EquipInfo[nIndex][5])
        else
            nCount = EquipInfo[nIndex][5] - self:LuaFnGetAvailableItemCount(selfId,YanXianYu[1])
            nRet = self:LuaFnDelAvailableItem(selfId,YanXianYu[1],self:LuaFnGetAvailableItemCount(selfId,YanXianYu[1]))
            nRet = self:LuaFnDelAvailableItem(selfId,YanXianYu[2],nCount)
        end
        if not nRet then
            self:notify_tips(selfId,"Trừ nguyên liệu thất bại, xin kiểm đạo cụ có khóa không.")
            return
        end
		self:BeginAddItem()
			self:AddItem(selectRadioId,1)
		if not self:EndAddItem(selfId) then
			self:NotifyTips(selfId,"Túi đồ không đủ chỗ trống.")
			return
		end
        self:AddItemListToHuman(selfId)
        self:notify_tips(selfId,"Đổi thành công, ngươi nhận một món"..self:GetItemName(selectRadioId).."。")
        return
    end
end

function oyanbei_mudao:OnDie(selfId, killerId) end

return oyanbei_mudao
