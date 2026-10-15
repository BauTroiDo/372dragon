local root=assert(arg[1]);local tools=assert(arg[2])
package.path=root..'/GameServer/lualib/?.lua;'..package.path
package.cpath=root..'/GameServer/luaclib/?.so;'..package.cpath
local say=print
package.loaded.skynet={getenv=function(k)if k=='config_path'then return root..'/configs/%s'end end,logd=function()end,logi=function()end,error=function()end}
package.loaded['skynet.sharetable']={};table.tostr=function()return ''end
package.loaded['skynet.manager']={}
print=function()end
local reader=require('cfghelper').new();reader:read_pet_soul_extension()
print=say
local define=require 'define';local M=assert(loadfile(tools..'/remaining_soul_reforge.lua'))()
local ext=reader.pet_soul_extension;local types=define.PET_SOUL_ATTRS;local n=0
local function check(ok,why)n=n+1;assert(ok,why)end
for _,t in ipairs(types)do for band=1,6 do
    check(M.text_color(ext[t],ext[t][band*2-1])==M.text_colors[band],'native color at lower bound')
    check(M.text_color(ext[t],ext[t][band*2])==M.text_colors[band],'native color at upper bound')
end end
local maxType=types[1];for _,t in ipairs(types)do maxType=math.max(maxType,t)end
math.randomseed(28092026)
for q=0,3 do
    local visible=q==0 and 4 or q==1 and 5 or 6
    local old={};for i=1,visible do old[i]={type=types[i],value=1}end
    old[visible]={type=maxType,value=2}
    local mask=10^(6-visible)
    for attempt=1,30 do
        local rows,count=M.generate(q,old,mask,visible,types,ext)
        check(rows and #rows==6 and count==1,'valid locked roll')
        local seen={};for i=1,visible do
            local a=rows[i];check(not seen[a.type],'unique types');seen[a.type]=true
            local band=q+3;check(a.value>=ext[a.type][band*2-1] and a.value<=ext[a.type][band*2],'color guarantee uses quality band')
        end
        check(seen[maxType],'locked high type must survive sorting and truncation')
        for i=visible+1,6 do check(rows[i].type==-1 and rows[i].value==0,'hidden rows remain empty')end
    end
    check(M.generate(q,old,222222,0,types,ext)==nil,'nonbinary decimal lock rejected')
    check(M.generate(q,old,0,visible+1,types,ext)==nil,'too many colors rejected')
end
for _,mask in ipairs({-1,1.5,111112,1000000})do check(M.generate(2,{},mask,0,types,ext)==nil,'invalid mask')end
check(M.generate(0,{},100000,0,types,ext)==nil,'cannot lock an empty row')
check(M.generate(0,{[6]={type=types[1]}},1,0,types,ext)==nil,'cannot lock hidden row')
check(M.generate(2,{[1]={type=types[1]},[2]={type=types[1]}},110000,0,types,ext)==nil,'duplicate existing locks rejected')
for k,c in pairs({[0]=1,[1]=2,[2]=2,[3]=3,[4]=3,[5]=4,[6]=5})do check(M.costs[k]==c,'native fee table')end
for _,id in ipairs({38002633,38002634,38002635})do check(M.colors[id][0]==nil and M.colors[id][1]==nil,'divine color items reject lower quality')end
print('PASS soul reforge '..n..' checks: real extension data, locks survive, unique types, color bands, fees, invalid masks')
