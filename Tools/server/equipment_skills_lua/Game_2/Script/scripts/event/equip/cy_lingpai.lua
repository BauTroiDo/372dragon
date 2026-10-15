local class=require 'class'
local base=require 'script_base'
local script=class('cy_lingpai',base)
function script:RL_SwitchSkill(selfId,pos,group)
    local human=self.scene:get_obj_by_id(selfId)
    if human and not human:cy_lingpai_operation('switch',pos,group) then
        self:notify_tips(selfId,'Chưa thể đổi kỹ năng: kiểm tra Lệnh Bài cấp 5, sách đã học, khóa và tiền.')
    end
end
function script:RL_QuerySkills(selfId)
    local human=self.scene:get_obj_by_id(selfId)
    if human then human:cy_lingpai_operation('sync')end
end
return script
