local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ojingji_Npc_4 = class("ojingji_Npc_4", script_base)
ojingji_Npc_4.script_id = 125014
ojingji_Npc_4.g_eventList = {}

function ojingji_Npc_4:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("Ta có thể sửa chữa tất cả Trang bị từ cấp 40 trở lên, bất kể là Vũ khí, phòng cụ hay Trang sức. Chỉ có điều cũng bởi lúc ta học nghề năm xưa, cái gì cũng thích, nên thành ra không phương diện nào ta thực sự tinh thông. Vì vậy lúc ta sửa chữa, tỷ lệ thành công không phải là 100% đâu. Nếu ngươi không có ý kiến gì, thì hãy tìm ta sửa giúp cho.")
    self:AddNumText("Ta muốn Sửa chữa Trang bị", 6, 1)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function ojingji_Npc_4:OnEventRequest(selfId, targetId, arg, index)
    if index == 1 then
        self:BeginUICommand()
        self:UICommand_AddInt(targetId)
        self:UICommand_AddInt(-1)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 19810313)
    end
end

return ojingji_Npc_4
