-- Execute the actual candidate methods; all state is in local doubles.
local plan=assert(...)
local function read(p) local f=assert(io.open(p,'rb'));local s=f:read('a');f:close();return s:gsub('\r\n','\n') end
local expSource=read(plan..'/GameServer/services/scene/obj/human.lua')
local itemSource=read(plan..'/GameServer/lualib/item.lua')
local h,item={},{}
local levels={[8]=80,[9]=90,[10]=100,[81]=101}
local conf={get_config=function(_,k) if k=='player_exp_level' then return levels elseif k=='config_info' then return {LeverUpflag={LeverUpflag=0}} elseif k=='common_item' then return {[301]={max_tile_count=20},[302]={max_tile_count=1}} end error(k) end}
local env=setmetatable({human=h,item=item,configenginer=conf,
 define={ITEM_CLASS={ICLASS_GEM=2,ICLASS_EQUIP=1,ICLASS_PET_EQUIP=8}},
 packet_def={GCLevelUpResult={new=function()return{}end},GCLevelUp={new=function()return{}end}}},{__index=_G})
local function method(src,prefix,name)
 local body=assert(src:match('function '..prefix..':'..name..'%([^\n]*%)[^\n]*\n.-\nend'),name)
 assert(load(body,'@candidate:'..name,'t',env))()
end
for _,name in ipairs({'add_my_exp','get_prop_bag_size','get_material_bag_size'}) do method(expSource,'human',name) end
method(itemSource,'item','get_max_tile_count')
function h:get_exp()return self.exp end
function h:get_level()return self.level end
function h:set_level(v)self.level=v end
function h:update_exp(v)self.exp=v end
function h:send_refresh_attrib()self.refreshed=(self.refreshed or 0)+1 end
function h:notify_tips()self.capped=true end
function h:on_level_up()end
function h:get_obj_id()return 1 end
function h:get_scene()return {send2client=function()end,broadcast=function()end} end
local count=0
local function test(name,fn) fn();count=count+1;print('PASS '..name) end
local function gain(before,normal,bonus,want,accepted,level)
 local o=setmetatable({exp=before,level=level or 81},{__index=h})
 local a,b=o:add_my_exp(normal,bonus)
 assert(o.exp==want,tostring(o.exp)..' ~= '..want)
 assert(a+b==accepted and o.refreshed==1,'notification or refresh mismatch')
 return o
end
test('exp ordinary updates total',function()gain(100,21,5,126,26)end)
test('exp cap rounded down 3.5',function()gain(340,20,10,353,13)end)
test('exp at cap gives zero notification',function()gain(353,20,10,353,0)end)
test('old overflow preserved without new gain',function()gain(404,20,10,404,0)end)
test('exp automatic first levels retained',function()assert(gain(70,20,0,10,20,8).level==9)end)
test('negative reward rejected',function()gain(100,-20,-10,100,0)end)
test('two fixed 100-slot regions',function()assert(h:get_prop_bag_size()==100 and h:get_material_bag_size()==100)end)
function item:get_serial_class()return self.cls end
function item:can_lay()return self.lay end
for _,r in ipairs({{3,301,true,250},{3,301,false,20},{3,302,true,1},{1,301,true,1},{8,301,true,1},{2,0,true,250}}) do
 test('stack class '..r[1]..' id '..r[2]..' lay '..tostring(r[3]),function()
  local x=setmetatable({cls=r[1],item_index=r[2],lay=r[3]},{__index=item});assert(x:get_max_tile_count()==r[4])
 end)
end
print('RESULT round2 actual methods tests='..count..' failures=0')
