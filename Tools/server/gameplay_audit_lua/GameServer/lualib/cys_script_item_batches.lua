-- Script instances are shared by every actor in a scene. A reward batch belongs
-- to the calling coroutine: config/GUID service calls may yield to another actor.
local by_script=setmetatable({}, {__mode='k'})
local M={}
function M.get(script)
    local batches=by_script[script]
    if not batches then batches=setmetatable({}, {__mode='k'});by_script[script]=batches end
    local thread=assert(coroutine.running())
    local batch=batches[thread]
    if not batch then batch={items={}};batches[thread]=batch end
    return batch
end
return M
