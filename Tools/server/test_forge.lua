-- Execute the production module with deterministic clock and inventory doubles.
local now=100000
package.preload.skynet=function()return {now=function()return now end,error=function()end}end
package.preload.define=function()return {HUMAN_EQUIP={HEQUIP_RIDER=8,HEQUIP_FASHION=16,HEQUIP_WUHUN=18},ITEM_CLASS={ICLASS_EQUIP=1}}end
package.preload['game.packet']=function()return {GCItemInfo={new=function()return {}end}}end
package.preload.human_item_logic=function()return {dec_item_lay_count=function(_,_,h,slot,n,id)
    local m=h.items[slot];assert(m.id==id and m.count>=n and not m.lock);m.count=m.count-n;h.spent=h.spent+n;return true
end}end
local M=dofile(arg[1])
local count=0
local function check(ok,label)assert(ok,label);count=count+1;print('PASS '..label)end
local function item(id,level,baselevel)
    local t={id=id,level=level or 0,lock=false,count=30,bind=false,identified=true,baselevel=baselevel or 1,
        point=id==10106000 and 0 or 99,guid={world=1,server=1,series=id},params={}}
    function t:get_index()return self.id end
    function t:get_guid()return self.guid end
    function t:get_equip_data()return self end
    function t:get_enhancement_level()return self.level end
    function t:set_enhancement_level(v)self.level=v end
    function t:get_base_config()return {level=self.baselevel,equip_point=self.point}end
    function t:get_next_enhance_config()return {cost_money=100+self.level*15,bonus={[21]=10+self.level*5}}end
    function t:get_enhance_config()return {bonus={[21]=self.level==0 and 0 or 5+self.level*5}}end
    function t:get_serial_class()return self.id//10000000 end
    function t:is_empty()return self.count<=0 end
    function t:is_lock()return self.lock end
    function t:set_lock(v)self.lock=v end
    function t:is_identd()return self.identified end
    function t:is_bind()return self.bind end
    function t:set_is_bind(v)self.bind=v end
    function t:get_lay_count()return self.count end
    function t:get_param(i)return self.params[i] or 0 end
    function t:set_param(i,v)self.params[i]=v end
    function t:copy_raw_data()return {id=self.id,level=self.level,lock=self.lock}end
    return t
end
local function fixture(level)
    local h={items={[0]=item(10106000,level),[1]=item(30900005)},money=100000,spent=0,charges=0}
    function h:get_obj_id()return 55 end
    function h:get_guid()return 200016 end
    function h:get_obj_type()return 'human' end
    function h:is_die()return self.dead or false end
    function h:get_prop_bag_container()return {get_item=function(_,i)return h.items[i]end}end
    function h:check_money_with_priority(n)return self.money>=n end
    function h:cost_money_with_priority(n)self.money=self.money-n;self.charges=self.charges+1;return true end
    function h:get_scene()return {send2client=function()end}end
    local s={}
    function s:BeginUICommand()self.ints={};self.text=''end
    function s:UICommand_AddInt(v)table.insert(self.ints,v)end
    function s:UICommand_AddStr(v)self.text=v end
    function s:EndUICommand()end
    function s:DispatchUICommand(_,id)assert(id==M.UI)end
    return s,h
end
local function begin(s,h,seq)M.quote(s,h,0,seq or 1);M.begin(s,h,0,1,seq or 1)end
local function strike(s,h,hit)
    local p=h.cys_forge;assert(p)
    local elapsed=hit and math.floor(p.center*p.period/10000) or 0
    now=math.floor((p.start+elapsed+40)/10)
    M.strike(s,h,p.nonce,elapsed)
    return p.nonce,elapsed
end
do
 local s,h=fixture(0)
 local lastWidth=10001;local lastPeriod=10000
 for level=0,8 do
    begin(s,h,level+1);local p=h.cys_forge
    check(p and p.level==level and p.width<lastWidth and p.period<lastPeriod,'difficulty rises at target '..(level+1))
    lastWidth=p.width;lastPeriod=p.period
    check(h.items[0].lock and h.spent==level+1 and h.charges==level+1,'charged once and locked '..level)
    local nonce,elapsed=strike(s,h,true)
    check(h.items[0].level==level+1 and not h.items[0].lock and not h.cys_forge,'successful hit '..(level+1))
    M.strike(s,h,nonce,elapsed)
    check(h.items[0].level==level+1 and h.charges==level+1,'replay does not upgrade or charge '..level)
 end
 begin(s,h,10);check(not h.cys_forge and h.charges==9 and h.items[0].level==9,'cap 9 preserves inputs')
end
for _,level in ipairs({0,1,8})do
 local s,h=fixture(level);begin(s,h);strike(s,h,false)
 check(h.items[0].level==math.max(0,level-1) and h.charges==1 and h.spent==1,'miss lowers one with floor zero '..level)
end
for _,case in ipairs({'money','wrong_material','locked','unidentified','missing','dead','changed_guid','level_above_cap'})do
 local s,h=fixture(3);M.quote(s,h,0,1)
 if case=='money'then h.money=0 elseif case=='wrong_material'then h.items[1].id=30001001
 elseif case=='locked'then h.items[0].lock=true elseif case=='unidentified'then h.items[0].identified=false
 elseif case=='missing'then h.items[1]=nil elseif case=='dead'then h.dead=true
 elseif case=='changed_guid'then h.items[0].guid.series=100
 elseif case=='level_above_cap'then h.items[0].level=25 end
 M.begin(s,h,0,1,1);check(not h.cys_forge and h.charges==0 and h.spent==0,'reject before consumption '..case)
end
do
 local s,h=fixture(5);begin(s,h);local nonce=h.cys_forge.nonce
 M.begin(s,h,0,1,1);check(h.charges==1 and h.spent==1 and h.cys_forge.nonce==nonce,'double start cannot double charge')
 M.strike(s,h,nonce+1,100);check(h.cys_forge~=nil,'foreign nonce cannot resolve')
 M.cancel(s,h,2);check(h.cys_forge~=nil,'stale cancel cannot resolve')
 M.cancel(s,h,1);check(h.items[0].level==4 and not h.items[0].lock and not h.cys_forge,'cancel settles one failure')
 M.cancel(s,h,1);check(h.items[0].level==4,'cancel replay harmless')
end
do
 local s,h=fixture(5);begin(s,h);local saved=h.cys_forge;h.cys_forge=nil
 M.recover(h,saved);check(h.items[0].level==4 and not h.items[0].lock,'persisted pending recovers as one failure')
 M.recover(h,false);check(h.items[0].level==4,'cleared recovery does not repeat')
end
do
 local s,h=fixture(5);begin(s,h);local p=h.cys_forge
 local elapsed=math.floor(p.center*p.period/10000)
 M.strike(s,h,p.nonce,elapsed)
 check(h.items[0].level==4,'forged future timestamp refused')
end
do
 local s,h=fixture(5);h.items[0].baselevel=40;h.items[1]=item(30900045);h.items[1].params[8]=9;h.items[1].bind=true
 begin(s,h);check(h.items[1].params[8]==10 and h.spent==0 and h.items[0].bind,'Lộ uses one charge and binds equipment')
 strike(s,h,true);begin(s,h,2);check(h.items[1].count==29 and h.spent==1,'last Lộ charge consumes item once')
 check(h.items[1].params[8]==0,'remaining stacked Lộ starts with full charges')
 strike(s,h,true);begin(s,h,3);check(h.items[1].params[8]==1 and h.spent==1,'next stacked Lộ spends a charge instead of another item')
end
for _,t in ipairs({0,2600,5200,7800,1000000})do
 local x=M.position(t,2600);check(x>=0 and x<=10000,'triangle bounds '..t)
end
do
 local s,h=fixture(2);h.items[1].count=1;begin(s,h);strike(s,h,true);begin(s,h,2)
 check(h.spent==1 and h.charges==1 and not h.cys_forge and h.items[0].level==3,'last material stops next attempt without double spending or phantom stack')
end
print('PASS forge production rules '..count..' assertions')
