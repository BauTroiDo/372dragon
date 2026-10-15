-- Script instances are shared by a scene. Lock the interacting human across
-- guild RPC yields so two clicks cannot issue/return a ticket or claim care twice.
local M={}
function M.install(C)
    local original=C.OnEventRequest
    function C:OnEventRequest(id,...)
        local h=self.scene and self.scene:get_obj_by_id(id)
        if not h or h.cys_guild_npc_busy then return end
        h.cys_guild_npc_busy=true
        local ok,result=pcall(original,self,id,...)
        h.cys_guild_npc_busy=nil
        if not ok then error(result)end
        return result
    end
    return C
end
return M
