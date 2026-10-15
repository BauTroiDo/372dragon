local class=require 'class'
local base=require 'script_base'
local script=class('cys_gift_boxes_script',base)
function script:OnClientGetGift(id,pos,...)
 local h=self.scene:get_obj_by_id(id)
 if h then return require('cys_gift_boxes').claim(self,h,pos,...) end
end
return script
