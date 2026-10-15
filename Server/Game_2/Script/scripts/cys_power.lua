local P=require('class')('cys_power',require 'script_base')
function P:Action(id,op,revision,a,b,c,d)
 local h=self.scene:get_obj_by_id(id)
 if h and h:get_obj_type()=='human' then return require('cys_shending').action(self,h,op,revision,a,b,c,d) end
end
return P
