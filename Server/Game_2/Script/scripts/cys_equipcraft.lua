local P=require('class')('cys_equipcraft_script',require 'script_base')
function P:Action(id,op,mode,pos,material,target,revision)
 local h=self.scene:get_obj_by_id(id)
 if h and h:get_obj_type()=='human' then return require('cys_equipcraft').action(self,h,op,mode,pos,material,target,revision) end
end
function P:LevelUp(id,npc,pos,check)
 return self:Action(id,0,1,pos,-1,-1,0)
end
return P
