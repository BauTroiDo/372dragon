return function(env)
local cfg,operator=env.config,env.operator
local reward=require'cys_script_reward'
local batches=require'cys_script_item_batches'
local passed,failed=0,0
local function test(name,fn)
 local ok,e=xpcall(fn,debug.traceback)
 if ok then passed=passed+1 else failed=failed+1;print('FAIL reward '..name,e)end
end
local function newitem(id,count,bound)
 local item=assert(operator:gen_item({},id,0));item:set_lay_count(count or 1);item:set_is_bind(bound or false);return item
end
local function actor(id)
 local h={items={},id=id,sent={}}
 local bag={get_item=function(_,p)return h.items[p]end,set_item=function(_,p,i)h.items[p]=i end,get_size=function()return{prop=100,material=100,task=20}end}
 function bag:ipairs(kind)
  local p=({prop=0,material=100,task=200})[kind]-1;local last=p+(kind=='task'and 20 or 100)
  return function()p=p+1;if p<=last then return p,h.items[p]end end
 end
 function h:get_prop_bag_container()return bag end
 function h:get_name()return 'reward-test-'..self.id end
 function h:get_guid()return self.id end
 function h:notify_tips()end
 return h
end
local a,b=actor(1),actor(2)
local script={script_id=210200,scene={get_obj_by_id=function(_,id)return id==1 and a or id==2 and b end,send2client=function(_,id,p)table.insert((id==1 and a or b).sent,p)end}}
local f=assert(io.open(env.stage..'/GameServer/lualib/script_base.lua'));local source=f:read('*a');f:close()
local host=setmetatable({script_base=script},{__index=_G})
for _,name in ipairs({'BeginAddItem','AddItem','EndAddItem','AddItemListToHuman','LuaFnEndAddItemIgnoreFatigueState','LuaFnAddItemListToHumanIgnoreFatigueState'})do
 local first=assert(source:find('function script_base:'..name..'(',1,true));local last=assert(source:find('\nfunction ',first+1,true))
 assert(load(source:sub(first,last-1),'@actual-script_base:'..name,'t',host))()
end
local function reset()a,b=actor(1),actor(2);script:BeginAddItem()end
local function count(h,id)local n=0;for _,i in pairs(h.items)do if i:get_index()==id then n=n+i:get_lay_count()end end;return n end
test('complete mixed award, 250 cap, duplicate rows and replay',function()
 reset();script:AddItem(30101001,200);script:AddItem(30101001,200);script:AddItem(10200001,2);script:AddItem(20103001,4)
 assert(script:EndAddItem(1));assert(next(a.items)==nil)
 assert(script:AddItemListToHuman(1));assert(count(a,30101001)==400 and count(a,10200001)==2 and count(a,20103001)==4)
 local guids={};for _,i in pairs(a.items)do assert(i:get_lay_count()<=250);local g=i:copy_raw_data().guid;local key=g.world..':'..g.server..':'..g.series;assert(not guids[key]);guids[key]=true end
 assert(not script:AddItemListToHuman(1));assert(count(a,30101001)==400)
end)
for _,scenario in ipairs({'full','locked-stack','different-binding','different-timer','second-generation-failure','race-full-during-guid','invalid-id','fraction-count','negative-count'})do
 test(scenario,function()
  reset();for p=0,99 do a.items[p]=newitem(10200001)end
  if scenario=='locked-stack'then a.items[0]=newitem(30101001,100);a.items[0].is_lock=function()return true end
  elseif scenario=='different-binding'then a.items[0]=newitem(30101001,100,true)
  elseif scenario=='different-timer'then a.items[0]=newitem(30101001,100);a.items[0]:set_validity_period_start_time(123)
  elseif scenario=='second-generation-failure'or scenario=='race-full-during-guid'then a.items={}end
  script:AddItem(scenario=='invalid-id'and 39999999 or 30101001,scenario=='fraction-count'and 1.5 or scenario=='negative-count'and -1 or 1)
  script:AddItem(30506001,1)
  local old=operator.gen_item;local calls=0
  operator.gen_item=function(self,...)
   calls=calls+1
   if scenario=='second-generation-failure'and calls==2 then return nil end
   local i=old(self,...)
   if scenario=='race-full-during-guid'and calls==2 then for p=0,99 do a.items[p]=newitem(10200001)end end
   return i
  end
  local ok,result=pcall(script.EndAddItem,script,1);operator.gen_item=old
  assert(ok and not result);assert(not script:AddItemListToHuman(1))
  assert(count(a,30506001)==0)
 end)
end
for _,scenario in ipairs({'slot-replaced','count-changed','identity-changed','binding-changed','locked-after-prepare','wrong-actor','wrong-way'})do
 test('stale '..scenario,function()
  reset();a.items[0]=newitem(30101001,100);script:AddItem(30101001,2);assert(script:EndAddItem(1))
  if scenario=='slot-replaced'then a.items[0]=newitem(30101001,100)
  elseif scenario=='count-changed'then a.items[0]:set_lay_count(99)
  elseif scenario=='identity-changed'then a.items[0]:set_index(30506001)
  elseif scenario=='binding-changed'then a.items[0]:set_is_bind(true)
  elseif scenario=='locked-after-prepare'then a.items[0].is_lock=function()return true end end
  assert(not script:AddItemListToHuman(scenario=='wrong-actor'and 2 or 1,scenario=='wrong-way'and 1 or 0))
  assert(a.items[0]:get_lay_count()<=100 and next(b.items)==nil)
 end)
end
test('bind normalization and prepared commit performs zero generation',function()
 reset();a.items[0]=newitem(30101001,249);script:AddItem(30101001,1,0);assert(script:EndAddItem(1))
 local old=operator.gen_item;operator.gen_item=function()error('commit generated an item')end
 local ok,res=pcall(script.AddItemListToHuman,script,1);operator.gen_item=old
 assert(ok and res and a.items[0]:get_lay_count()==250 and a.items[1]==nil)
end)
test('two actors interleave GUID allocation on the same NPC',function()
 reset();local old=operator.gen_item
 operator.gen_item=function(self,...)
  local i=old(self,...);coroutine.yield('guid');return i
 end
 local ca=coroutine.create(function()script:BeginAddItem();script:AddItem(30101001,3);assert(script:EndAddItem(1));assert(script:AddItemListToHuman(1))end)
 local cb=coroutine.create(function()script:BeginAddItem();script:AddItem(30506001,5);assert(script:EndAddItem(2));assert(script:AddItemListToHuman(2))end)
 local ok,e=pcall(function()assert(coroutine.resume(ca));assert(coroutine.resume(cb));assert(coroutine.resume(cb));assert(coroutine.resume(ca))end)
 operator.gen_item=old;assert(ok,e);assert(coroutine.status(ca)=='dead'and coroutine.status(cb)=='dead')
 assert(count(a,30101001)==3 and count(a,30506001)==0 and count(b,30506001)==5 and count(b,30101001)==0)
end)
test('empty check, ignore-fatigue alias and explicit way',function()
 reset();assert(not script:EndAddItem(1));script:AddItem(30101001,1);assert(script:EndAddItem(1,true));assert(not script:AddItemListToHuman(1))
 script:AddItem(30101001,1);assert(script:LuaFnEndAddItemIgnoreFatigueState(1));assert(script:LuaFnAddItemListToHumanIgnoreFatigueState(1))
 script:BeginAddItem();script:AddItem(30506001,1);assert(script:EndAddItem(1,nil,1));assert(script:AddItemListToHuman(1,1))
end)
print(string.format('Actual reward preparation/commit: %d passed, %d failed',passed,failed))
return failed
end
