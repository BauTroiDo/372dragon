-- Generate recovered crafting outputs with the actual item operator/configs.
-- Only the GUID service and transport are replaced; no database is modified.
local root,stage,configroot,report=assert(arg[1]),assert(arg[2]),assert(arg[3]),assert(arg[4])
package.path=stage..'/GameServer/lualib/?.lua;'..root..'/GameServer/lualib/?.lua;'..package.path
package.cpath=root..'/GameServer/luaclib/?.so;'..package.cpath
local quiet=function()end
local serial=0
package.loaded.skynet={getenv=function(k)if k=='config_path'then return configroot..'/configs/%s'elseif k=='process_id'then return '2'end end,
 logd=quiet,logi=quiet,logw=quiet,loge=quiet,error=quiet,log=quiet,send=quiet,
 call=function(service,_,method)assert(service=='.gen_serial'and method=='inc_serial');serial=serial+1;return{world=254,server=254,series=serial}end}
package.loaded['skynet.manager']={};package.loaded['skynet.sharetable']={};table.tostr=function()return ''end
table.clone=function(value)if type(value)~='table'then return value end;local copy={};for k,v in pairs(value)do copy[k]=table.clone(v)end;return copy end
package.loaded['skynet.crypt']={}
package.loaded['game.packet']=setmetatable({},{__index=function()return{new=function()return{}end}end})
local reader=require('cfghelper').new();local cache={};local config={}
function config:get_config(k)
 if not cache[k]then local say=print;print=quiet;assert(reader['read_'..k],k)(reader);print=say;cache[k]=reader[k]end
 return assert(cache[k],k)
end
package.loaded.configenginer={getinstance=function()return config end}
local f=assert(io.open(report));local data=f:read('*a');f:close()
local imported=assert(data:match('"imported"%s*:%s*{(.-)}'))
local operator=require('item_operator'):getinstance()
local passed,failed=0,0
math.randomseed(27092026)
for value in imported:gmatch('%d+')do
 local id=tonumber(value)
 local say=print
 local ok,e=xpcall(function()
  print=quiet
  for n=1,3 do
   local item=assert(operator:gen_item({},id,1));assert(item:get_index()==id)
   assert(item:get_lay_count()==1 and item:get_max_tile_count()>=1)
   local raw=item:copy_raw_data();assert(raw.item_index==id)
   if item:is_equip()then assert(item:get_equip_data():get_max_dur()>0)end
  end
 end,debug.traceback)
 print=say
 if ok then passed=passed+1 else failed=failed+1;print('FAIL recovered item '..id,e)end
end
print(string.format('Actual item generation: %d passed, %d failed',passed,failed))
if arg[5]then
 local extra=assert(loadfile(arg[5]))()({root=root,stage=stage,config=config,operator=operator})
 failed=failed+extra
end
os.exit(failed==0 and 0 or 1)
