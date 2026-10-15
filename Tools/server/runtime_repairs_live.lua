-- Read-only validation against the private scene's real native navigation map.
local skynet=require 'skynet'
local step='identity'
local ok=xpcall(function()
 assert(skynet.call('.cluster_agent','lua','get_processid')==2)
 assert(skynet.call('.SCENE_2','lua','get_id')==2)
 step='valid-merchant-position'
 assert(skynet.call('.SCENE_2','lua','cys_gm_valid_destination',{x=271,y=135})==true)
 step='invalid-out-of-bounds'
 assert(skynet.call('.SCENE_2','lua','cys_gm_valid_destination',{x=65535,y=65535})==false)
 step='complete'
end,function()return false end)
local result='CYS-RUNTIME-NAV '..(ok and 'PASS native-path=2' or ('FAIL '..step))
local previous=table.tostr
table.tostr=function()table.tostr=previous;return result end
return result
