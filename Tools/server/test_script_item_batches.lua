local root,stage=assert(arg[1]),assert(arg[2])
package.path=stage..'/GameServer/lualib/?.lua;'..package.path
local f=assert(io.open(stage..'/GameServer/lualib/script_base.lua'));local text=f:read('*a');f:close()
local body=assert(text:match('(function script_base:BeginAddItem%(.-)function script_base:LuaFnDelAllAvailableItems'))
local base={};local checks=0
local function check(x)assert(x);checks=checks+1 end
assert(load(body,'@actual-script-item-batch-methods','t',setmetatable({script_base=base,
    human_item_logic={calc_item_space=function()coroutine.yield('space');return true end}},{__index=_G})))()
local output={}
local obj=setmetatable({scene={get_obj_by_id=function(_,id)return id end}},{__index=base})
function obj:TryRecieveItemWithCount(id,item,count,bound,param,way)
    coroutine.yield('allocate')
    output[id]=output[id]or {};output[id][#output[id]+1]={item,count,bound,param,way}
end
local function actor(id,item)
    return coroutine.create(function()
        obj:BeginAddItem();obj:AddItem(item,2,true,123);obj:AddItem(item+1,1,false,456)
        check(obj:LuaFnEndAddItemIgnoreFatigueState(id))
        obj:AddItemListToHuman(id,88);obj:AddItemListToHuman(id,88)
    end)
end
local a,b=actor(1,100),actor(2,200)
while coroutine.status(a)~='dead' or coroutine.status(b)~='dead' do
    for _,co in ipairs({a,b})do if coroutine.status(co)~='dead'then local ok,err=coroutine.resume(co);assert(ok,err)end end
end
for id=1,2 do
    check(#output[id]==2)
    check(output[id][1][1]==id*100 and output[id][2][1]==id*100+1)
    check(output[id][1][2]==2 and output[id][1][3]==true and output[id][1][4]==123 and output[id][1][5]==88)
end
obj:BeginAddItem();obj:AddItem(300,1);obj:BeginAddItem()
check(#require('cys_script_item_batches').get(obj).items==0)
print('script reward batch isolation: '..checks..' passed, 0 failed; two actors interleaved at capacity/allocation yields')
