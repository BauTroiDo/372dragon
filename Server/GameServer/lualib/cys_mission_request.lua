-- NPC script retains its authored event allowlist/quest conditions. Bound the
-- request to a live, nearby actor and serialize accept/submit across yields.
local M={}
function M.call(scene,who,npc_id,script_id,callback,...)
    local h,npc=scene.objs[who],scene.objs[npc_id]
    if not h or not npc or not h.get_mission_by_id or not h:is_alive()
        or not npc.get_script_id or h._cys_mission_request then return false end
    local a,b=h:get_world_pos(),npc:get_world_pos()
    -- GameDefine.h MAX_NPC_DISTANCE = 5.0, matching native interaction range.
    if not a or not b or (a.x-b.x)^2+(a.y-b.y)^2>25 then return false end
    if type(script_id)~='number' or script_id%1~=0 or script_id<0 then return false end
    h._cys_mission_request=true
    local ok,result=xpcall(scene.scriptenginer.call,debug.traceback,scene.scriptenginer,
        npc:get_script_id(),callback,who,npc_id,script_id,...)
    h._cys_mission_request=nil
    if not ok then error(result) end
    return result
end
return M
