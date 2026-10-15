local P=require('class')('cys_petsoul_script',require 'script_base')
function P:Action(id,op,pos,revision,material,lock_value,color_pos)
 local h=self.scene:get_obj_by_id(id)
 if h and h:get_obj_type()=='human' then return require('cys_petsoul').action(self,h,op,pos,revision,material,lock_value,color_pos) end
end
return P
