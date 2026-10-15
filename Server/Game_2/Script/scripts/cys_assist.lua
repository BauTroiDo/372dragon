local class=require "class"
local P=class("cys_assist",require "script_base")
local M=require "cys_battle_assist"
function P:Open(selfId,...)
 local h=self.scene:get_obj_by_id(selfId)
 if h and h:get_obj_type()=="human" then M.snapshot(self,h,...) end
end
function P:Begin(selfId,...)
 local h=self.scene:get_obj_by_id(selfId)
 if h and h:get_obj_type()=="human" then M.begin(self,h,...) end
end
function P:Chunk(selfId,...)
 local h=self.scene:get_obj_by_id(selfId)
 if h and h:get_obj_type()=="human" then M.chunk(self,h,...) end
end
function P:Commit(selfId,...)
 local h=self.scene:get_obj_by_id(selfId)
 if h and h:get_obj_type()=="human" then M.commit(self,h,...) end
end
function P:Start(selfId,...)
 local h=self.scene:get_obj_by_id(selfId)
 if h and h:get_obj_type()=="human" then M.start(self,h,...) end
end
function P:Stop(selfId) local h=self.scene:get_obj_by_id(selfId);if h then M.stop(h);M.snapshot(self,h) end end
return P
