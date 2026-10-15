local class = require "class"
local define = require "define"
local script_base = require "script_base"
local edali_0240 = class("edali_0240", script_base)
edali_0240.script_id = 210240
function edali_0240:OnDefaultEvent(selfId, targetId)
    local WorldReferenceID = 30308021
    local bHave = self:LuaFnGetAvailableItemCount(selfId, WorldReferenceID)
    if (bHave > 0) then
        self:BeginEvent(self.script_id)
        self:AddText("  Ngươi chẳng phải đã có một quyển Giang Hồ Chỉ Nam rồi sao?")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    local FreeSpace = self:LuaFnGetPropertyBagSpace(selfId)
    if (FreeSpace > 0) then
        self:BeginAddItem()
        self:AddItem(WorldReferenceID, 1)
        self:EndAddItem(selfId)
        self:AddItemListToHuman(selfId)
        self:BeginUICommand()
        self:UICommand_AddInt(targetId)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 1000)
        self:BeginEvent(self.script_id)
        local strText = "Ngươi nhận được một quyển Giang Hồ Chỉ Nam"
        self:AddText(strText)
        self:EndEvent()
        self:DispatchMissionTips(selfId)
    else
        self:BeginEvent(self.script_id)
        self:AddText("  Túi càn khôn của ngươi đã đầy, xin chừa chỗ trống rồi hãy đến tìm ta!")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    end
end
function edali_0240:OnEnumerate(caller, selfId, targetId, arg, index)
    caller:AddNumTextWithTarget(self.script_id, "Lĩnh Giang Hồ Chỉ Nam", 11, 100)
end
function edali_0240:CheckAccept(selfId) end
function edali_0240:OnAccept(selfId) end
function edali_0240:OnAbandon(selfId) end
function edali_0240:OnContinue(selfId, targetId) end
function edali_0240:CheckSubmit(selfId) end
function edali_0240:OnSubmit(selfId, targetId, selectRadioId) end
function edali_0240:OnKillObject(selfId, objdataId, objId) end
function edali_0240:OnEnterArea(selfId, zoneId) end
function edali_0240:OnItemChanged(selfId, itemdataId) end
return edali_0240
