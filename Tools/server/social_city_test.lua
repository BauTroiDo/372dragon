local source=assert(arg[1]);local checks=0
local function check(v,n)assert(v,n);checks=checks+1;print('PASS '..n)end
local city={id=4,guild_id=9};local human={get_guild_id=function()return 9 end}
local current=human
package.loaded.skynet={call=function(_,_,method,id)
 if method=='get_city_by_id' and id==4 or method=='get_city_by_scene_id' and id==208 then return city end
end}
package.loaded.configenginer={getinstance=function()return {get_config=function()
 return {[15]={BuildingType=10},[28]={BuildingType=0}}
end}end}
local C=assert(loadfile(source))().install({})
local q=setmetatable({scene={conf={buildings={['9']={id=15,level=3},['17']={id=28,level=2}}},get_obj_by_id=function()return current end}}, {__index=C})
check(q:CityGetBuildingLevel(1,10)==3,'script building enum resolves placement index')
check(q:CityGetBuildingLevel(1,0)==2,'county hall reads stored level')
check(q:CityGetBuildingLevel(1,18)==0,'missing building has no fabricated level')
check(q:CityGetMaintainStatus(1,4)==0,'legacy saved city remains in normal state')
city.maintain_status=1;check(q:CityGetMaintainStatus(1,208)==1,'maintenance query accepts scene ID and preserves blocked state')
city.maintain_status=0;city.guild_id=10;check(q:CityGetMaintainStatus(1,4)==1,'another guild city cannot grant welfare')
check(q:CityGetMaintainStatus(1,999)==1,'missing city blocks welfare')
check(q:CityGetMaintainStatus(1,-1)==1,'invalid city blocks welfare')
print('PASS city query checks='..checks)
