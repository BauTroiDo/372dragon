local plan=assert(arg[1]);package.path=plan..'/?.lua;'..package.path
local N=require 'cys_flight_nav';local total,blocked,walkable=0,0,0
for line in io.lines(assert(arg[2])) do
 local id,x,z,expected=line:match('^(%d+) (%S+) (%S+) (%d)$');assert(id,line)
 local mesh=assert(N.for_scene({get_id=function()return tonumber(id)end}),id)
 local actual=mesh:walkable(tonumber(x),tonumber(z));expected=expected=='1'
 assert(actual==expected,string.format('scene=%s point=%s,%s client=%s server=%s',id,x,z,tostring(expected),tostring(actual)))
 total=total+1;if actual then walkable=walkable+1 else blocked=blocked+1 end
end
assert(not pcall(N.parse,''));assert(not pcall(N.parse,string.pack('<I2I4',0x2000,0xffffffff)))
local mesh=assert(N.for_scene({get_id=function()return 12 end}))
assert(not mesh:walkable(0/0,0) and not mesh:walkable(math.huge,0) and not mesh:walkable(-1,0))
assert(mesh:walkable(72.54,100.23) and not mesh:walkable(72.54,103.23),'live obstacle regression')
assert(not N.for_scene({get_id=function()return -1 end}))
print(string.format('PASS %d exact client/server points (%d walkable, %d blocked), corrupt data, boundaries, live regression',total,walkable,blocked))
