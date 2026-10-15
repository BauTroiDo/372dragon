local class=require "class"
local P=class("cys_tembank",require "script_base")
function P:Open(selfId)
 local h=self.scene:get_obj_by_id(selfId)
 if h and h:get_obj_type()=="human" then require("cys_tembank").snapshot(self,h) end
end
function P:Move(selfId,dir,index,revision,world,server,series)
 local h=self.scene:get_obj_by_id(selfId)
 if h and h:get_obj_type()=="human" then require("cys_tembank").move(self,h,dir,index,revision,world,server,series) end
end
function P:TakeAll(selfId,revision)
 local h=self.scene:get_obj_by_id(selfId)
 if h and h:get_obj_type()=="human" then require("cys_tembank").take_all(self,h,revision) end
end
function P:Sort(selfId,revision)
 local h=self.scene:get_obj_by_id(selfId)
 if h and h:get_obj_type()=="human" then require("cys_tembank").sort(self,h,revision) end
end
return P
