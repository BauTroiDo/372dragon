local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_multiuse = class("item_multiuse", script_base)
item_multiuse.script_id = 889915

function item_multiuse:OnItemBatchUseFromClient(selfId, itemID, count, scriptId, bagPos)
    if not count or count < 1 then
        self:notify_tips(selfId, "Số lượng dùng không hợp lệ.")
        return
    end
    if not scriptId or scriptId <= 0 then
        self:notify_tips(selfId, "ID script vật phẩm không hợp lệ.")
        return
    end
    if not bagPos or bagPos < 0 then
        self:notify_tips(selfId, "Vị trí túi không hợp lệ.")
        return
    end
    self:CallScriptFunction(scriptId, "OnItemBatchUse", selfId, bagPos, count)
end

return item_multiuse
