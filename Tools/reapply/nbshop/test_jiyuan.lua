-- Contract only: no server/DB, verify the real dispatch helper receives the requested player/target.
package.loaded.class=function(_,base) return setmetatable({}, {__index=base}) end
package.loaded.wire_charset={}
local sent,tips,level={},0,15
package.loaded.script_base={
 GetLevel=function() return level end,
 notify_tips=function() tips=tips+1 end,
 DispatchJiYuanShopInfo=function(_,who,target) sent[#sent+1]={who,target} end,
}
local shop=assert(loadfile(assert(arg[1])))()
shop:OpenJiYuanShop(200014,-1)
assert(#sent==1 and sent[1][1]==200014 and sent[1][2]==-1)
shop:OpenJiYuanShop(200014,42)
assert(#sent==2 and sent[2][1]==200014 and sent[2][2]==42)
level=14
shop:OpenJiYuanShop(200014,-1)
assert(#sent==2 and tips==1)
print('PASS JiYuan metadata contract 3/3: minimap/player target, NPC target, level gate; no DB writes.')
