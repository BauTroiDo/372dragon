local T=...
local recipes=T.config:get_config('item_compound')
local authored=require 'cys_recipe_authored'
local count=0
local function seed(row,info,data,choice)
    local h=T.human();local aid=row['对应技能ID'];h.op={ability_id=aid,pres_id=row.index,mat_bag_index=255}
    h.ability={level=info.recipeLevel,exp=0};h.assist={level=0,exp=0}
    function h:get_ability(id)if id==aid then return self.ability else return self.assist end end
    local need={}
    if row['脚本ID']==700900 then
        local list=data.CaiLiaoBiao[info.matClassBase+choice-1]
        if #list==0 then return end
        need[list[1]]=math.max(1,info.matCostBase-(choice-1)*info.matFactor)
    elseif row['脚本ID']==700960 then
        for n,id in ipairs(info.matTbl[1].matList)do need[id]=info.matTbl[1].count[n]end
    else
        local m=info.matTbl[choice];need[m.matList[1]]=m.count
    end
    local nextpos={prop=0,material=100,task=200}
    for id,n in pairs(need)do
        if not(T.config:get_config('common_item')[id]or T.config:get_config('equip_base')[id])then
            print('Authored material missing; group remains unavailable:',row.index,choice,id);return
        end
        local i=T.item(id,n);local kind=i:get_place_bag();local p=nextpos[kind];nextpos[kind]=p+1;h.items[p]=i
    end
    return h,{id=aid,abilityenginer=T.engine},need
end
for _,sid in ipairs({700900,700901,700959,700960})do
 local data=require('cys_recipe_data_'..sid)
 for id,info in pairs(data.CompoundInfo)do
  local row=assert(recipes[id]);assert(row['脚本ID']==sid)
  for choice=1,(info.matClassCount or #info.matTbl)do
   local h,a,need=seed(row,info,data,choice)
   if h then
    count=count+1
    T.test('authored recipe '..id..' material group '..choice,function()
     local expected=0;for _,n in pairs(need)do expected=expected+n end
     assert(T.craft.check(a,h)==T.R.OR_OK,'check rejected')
     local random=math.random;math.random=function()return 1 end
     local ok,res=pcall(T.craft.finish,a,h,'compound');math.random=random
     assert(ok,res);assert(res==T.R.OR_OK,'finish rejected '..tostring(res));assert(h.spent==expected)
     local outputs=0;for _,i in pairs(h.items)do outputs=outputs+i.count end
     assert(outputs==(sid==700900 and 2 or 1),'wrong output count')
     assert(T.craft.finish(a,h,'compound')~=T.R.OR_OK and h.spent==expected,'replay')
    end)
   end
  end
 end
end
local data=require 'cys_recipe_data_700900';local row=recipes[163];local info=data.CompoundInfo[163]
for _,case in ipairs({'locked','partial','output-full','race-count','race-identity','race-assisted-level','race-operation','reentrant','bonus-full'})do
 T.test('authored crafting rejects '..case,function()
  local h,a=seed(row,info,data,1);local success=false;local random=math.random;math.random=function()return 1 end
  if case=='locked'then h.items[100].locked=true
  elseif case=='partial'then h.items[100].count=1
  elseif case=='output-full'or case=='bonus-full'then
   for p=(case=='bonus-full'and 1 or 0),99 do h.items[p]=T.item(10200001)end
  else T.generation(function()
   if case=='race-count'then h.items[100].count=1
   elseif case=='race-identity'then h.items[100]=T.item(h.items[100].id,h.items[100].count)
   elseif case=='race-assisted-level'then h.assist.level=1
   elseif case=='race-operation'then h.op={ability_id=2,pres_id=163,mat_bag_index=255}
   elseif case=='reentrant'then assert(T.craft.finish(a,h,'compound')~=T.R.OR_OK);success=true end
  end)end
  local vigor=h.vigor;local ok,res=pcall(T.craft.finish,a,h,'compound');math.random=random
  assert(ok,res);assert((res==T.R.OR_OK)==success)
  if not success then assert(h.spent==0 and h.vigor==vigor,'partial debit')end
 end)
end
-- Execute the actual common deletion method, without loading unrelated services.
local f=assert(io.open(T.stage..'/GameServer/lualib/human_item_logic.lua'));local s=f:read('*a');f:close()
local body=assert(s:match('(function human_item_logic:del_available_items%b()%s*.-)\nfunction human_item_logic:erase_material_item'))
local logic={dec_item_lay_count=T.logic.dec_item_lay_count}
function logic:erase_item_by_bag_index(_,h,p)h.items[p]=nil;h.spent=h.spent+1;return true end
assert(load(body,'actual atomic deletion','t',setmetatable({human_item_logic=logic,inventory_guard=require 'cys_inventory_guard'},{__index=_G})))()
for _,case in ipairs({'equip','split','insufficient','locked','invalid-count'})do
 T.test('quest debit '..case,function()
  local h=T.human();local id=case=='equip'and 10200001 or 20103001;local p=case=='equip'and 0 or 100
  h.items[p]=T.item(id,case=='equip'and 1 or 2);if case~='equip'then h.items[101]=T.item(id,3)end
  if case=='locked'then h.items[101].locked=true end
  local n=case=='equip'and 1 or case=='insufficient'and 6 or case=='invalid-count'and 0 or 5
  local ok=logic:del_available_item({},h,id,n)
  local success=case=='equip'or case=='split';assert(ok==success and h.spent==(success and n or 0))
 end)
end
for _,n in ipairs({5,6})do
 T.test('mixed materials atomic '..n,function()
  local h=T.human();h.items[100]=T.item(20103001,2);h.items[101]=T.item(20103061,3)
  local ok,left=logic:del_available_items({},h,n,{20103001,20103001,20103061})
  assert(ok==(n==5));assert(left==(n==5 and 0 or n));assert(h.spent==(n==5 and 5 or 0))
 end)
end
print('Recovered authored recipe material groups tested:',count)
