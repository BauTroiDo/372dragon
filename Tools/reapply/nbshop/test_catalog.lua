-- Isolated script contract test: no server process, socket, database, or reference-file writes.
package.loaded.class = function(_, base) return setmetatable({}, {__index=base}) end
package.loaded.wire_charset = {}
local sent, tips, level = {}, 0, 15
package.loaded.script_base = {
 GetLevel=function() return level end,
 notify_tips=function() tips=tips+1 end,
 DispatchYuanbaoShopItem=function(_,who,shop) sent[#sent+1]={who=who,shop=shop} end,
 DispatchNpcYuanbaoShopItem=function(_,who,npc,shop) sent[#sent+1]={who=who,npc=npc,shop=shop} end,
}
local path=arg[1]
assert(path and path:match('/yuanbaoshop%.lua$'))
local shop=assert(loadfile(path))()
local cases={
 {2,1,150},{2,2,307},{2,3,308},{2,4,178},{2,5,198},{2,6,193},
 {5,7,208},{5,8,345},{6,5,133},{7,2,253},{7,3,277},{7,4,278},
 {8,2,159},{8,6,163},{10,7,182},{104,1,217},{104,6,304},
}
for _,c in ipairs(cases) do
 local before=#sent
 shop:OpenYuanbaoShop(200014,-1,c[1],c[2])
 assert(#sent==before+1 and sent[#sent].shop==c[3])
end
local before=#sent
shop:OpenYuanbaoShop(200014,-1,999,1)
shop:OpenYuanbaoShop(200014,-1,1,999)
shop:OpenYuanbaoShop(200014,-1,nil,nil)
assert(#sent==before and tips==3)
level=14
shop:OpenYuanbaoShop(200014,-1,2,2)
assert(#sent==before and tips==4)
level=15
shop:OpenYuanbaoShop(200014,42,2,2)
assert(#sent==before+1 and sent[#sent].npc==42 and sent[#sent].shop==307)
print('PASS catalog Lua routing: 17 changed cells + 3 invalid inputs + level<15 + NPC route; 22/22')
