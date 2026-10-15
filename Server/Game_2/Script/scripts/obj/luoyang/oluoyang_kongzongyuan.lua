local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oluoyang_kongzongyuan = class("oluoyang_kongzongyuan", script_base)
oluoyang_kongzongyuan.script_id = 000124
oluoyang_kongzongyuan.g_Key = {["do"] = 100, ["undo"] = 101}
local GlobalLaborDayActivityTable = 
{
    ["PetCageCardID"]					= 40004446, --签名牌物品ID
    ["PetCageLv1"]						= 30509500, --兽栏一级物品ID
    ["PetCageDelayBuff"] 				= 5941,
        
    ["PetCagePresentStartTime"] 		= 20080501, --兑换兽栏开始时间
    ["PetCagePresentEndTime"] 			= 20080504, --兑换兽栏结束时间
        
    ["CardPresentStartTime"] 			= 20080501,	--签名牌开始兑换时间
    ["CardPresentEndTime"] 				= 20080503,	--签名牌结束兑换时间
        
    ["MailStartDayTime"] 				= 20080501,	--发送邮件开始时间
    ["MailEndDayTime"] 					= 20080503	--发送邮件结束时间
}
    
function oluoyang_kongzongyuan:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText(
        "  Ta chính là Diễn Thánh công nhà Đại Tống, Văn Thánh Nhân Khổng Tông Uyên đây. Nếu ngươi có đạo cụ nhiệm vụ thừa chiếm mất không gian túi đồ quý giá, có thể giao cho ta để xóa bỏ. Nhưng trước khi xóa đạo cụ nhiệm vụ, ngươi nhất định phải suy nghĩ cho kỹ, xem nó có thật sự không còn công dụng gì nữa không.")
    self:AddNumText("Ta muốn xóa đạo cụ nhiệm vụ", -1, self.g_Key["do"])
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oluoyang_kongzongyuan:OnEventRequest(selfId, targetId, arg, index)
    local key = index
    if key == self.g_Key["do"] then
        self:BeginUICommand()
        self:UICommand_AddInt(targetId)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 42)
    end
end

function oluoyang_kongzongyuan:OnDestroy(selfId, posItem)
    if posItem < 0 then return end
    local idItem = self:LuaFnGetItemTableIndexByIndex(selfId, posItem)
    if idItem == 40002109 then
        local ret = self:DelMission(selfId, 4021)
        if ret > 0 then
            self:SetCurTitle(selfId, 0, 124)
            self:DeleteTitle(selfId, 5)
            self:LuaFnDispatchAllTitle(selfId)
            self:SetMissionData(selfId, define.MD_ENUM.MD_CAOYUN_HUAN, 0)
            self:SetMissionData(selfId, define.MD_ENUM.MD_CAOYUN_MONSTERTIMER, 0)
            self:LuaFnCancelSpecificImpact(selfId, 113)
        end
    end
    self:EraseItem(selfId, posItem)
    self:OnDestroyLaborDay(selfId, idItem)
end

function oluoyang_kongzongyuan:OnDestroyLaborDay(selfId, idItem)
    if (GlobalLaborDayActivityTable["PetCageCardID"] == idItem) then
        local hasImapct = self:LuaFnHaveImpactOfSpecificDataIndex(selfId,
                                                                  GlobalLaborDayActivityTable["PetCageDelayBuff"])
        if (hasImapct > 0) then
            self:LuaFnCancelSpecificImpact(selfId,
                                           GlobalLaborDayActivityTable["PetCageDelayBuff"])
        end
    end
end

return oluoyang_kongzongyuan
