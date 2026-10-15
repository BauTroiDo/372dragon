local class=require 'class'
local base=require 'script_base'
local longwen=class('cy_longwen',base)
function longwen:Lw_Op_Do(selfId,operation,pos,selection)
    if self:IsPilferLockFlag(selfId) then return false end
    local human=self.scene:get_obj_by_id(selfId);if not human then return false end
    local ok=human:cy_longwen_skill_operation(pos,operation,selection)
    if not ok then self:notify_tips(selfId,'Long Văn: kiểm tra loại thao tác, thuộc tính, khóa vật phẩm, kim tiền và nguyên liệu.')end
    return ok
end
return longwen
