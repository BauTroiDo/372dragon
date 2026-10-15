-- Real mission tables + real Lua methods. No account, DB or mission writes.
local root,stage=assert(arg[1]),assert(arg[2])
package.path=root..'/GameServer/lualib/?.lua;'..stage..'/Game_2/Script/?.lua;'..root..'/Game_2/Script/?.lua;'..package.path
package.cpath=root..'/GameServer/luaclib/?.so;'..package.cpath
local quiet=function()end
package.loaded.skynet={getenv=function(k)if k=='config_path'then return root..'/configs/%s'end end,logd=quiet,logi=quiet,logw=quiet,loge=quiet,error=quiet,log=quiet}
package.loaded['skynet.manager']={};package.loaded['skynet.sharetable']={};table.tostr=function()return ''end
local cfg=require('cfghelper').new();local say=print;print=quiet;cfg:read_mission_npc_hash_table();print=say
local conf=cfg.mission_npc_hash_table
local class=require 'class';local base=class('shimen_base')
local function read(path)local f=assert(io.open(path));local t=f:read('*a');f:close();return t end
local source=read(stage..'/GameServer/lualib/script_base.lua')
local selected=1
local env=setmetatable({script_base=base,math=setmetatable({random=function(lo,hi)assert(lo==1 and hi>=selected);return selected end},{__index=math}),
  configenginer={get_config=function(_,key)assert(key=='mission_npc_hash_table');return conf end}},{__index=_G})
assert(load(assert(source:match('(function script_base:GetOneMissionNpc%b().-\nend)')),'npc-group','t',env))()
local pass,fail=0,0
local function test(name,fn)local ok,e=pcall(fn);if ok then pass=pass+1 else fail=fail+1 end;print(ok and 'PASS' or 'FAIL',name,e or '')end
for _,group in ipairs({0,43})do
  test('group '..group..' selects every indexed row',function()
    assert(#conf.index[group]>1)
    for i,id in ipairs(conf.index[group])do
      selected=i
      local tuple=table.pack(base:GetOneMissionNpc(group));local row=conf.data[id]
      assert(tuple.n==9 and tuple[1]==id,'group used as row ID')
      assert(tuple[2]==row['NPC名称$1$'] and tuple[4]==row['场景ID'] and tuple[5]==row['坐标X'] and tuple[6]==row['坐标Z'] and tuple[9]==row['等级'])
    end
  end)
end
test('absent group does not throw or invent target',function()local t=table.pack(base:GetOneMissionNpc(-123));assert(t.n==9 and t[1]==-1 and t[9]==-1)end)
test('empty group does not call random with zero',function()conf.index[-124]={};local t=table.pack(base:GetOneMissionNpc(-124));assert(t.n==9 and t[1]==-1)end)
package.loaded.script_base=base
for _,school in ipairs({'shaolin','tianshan','wudang','xiaoyao','xingxiu','gaibang','mingjiao','emei','dali','mantuo'})do
  test(school..' retains level before AddMission',function()
    local obj=require('scripts.event.shimen.event_shimen_'..school).new()
    local reached=false
    function obj:GetLevel()return 30 end
    function obj:GetOneMissionNpc()return 101,'Quai','Scene',2,100,110,'desc',0,30 end
    function obj:abs(n)return math.abs(n)end
    function obj:AddMission()reached=true;return false end -- stops before any mutation
    function obj:SongXin_Accept()error('unexpected fallback')end
    obj:KillMonster_Accept(1);assert(reached,'never reached admission')
  end)
end
print(string.format('SUMMARY pass=%d fail=%d',pass,fail));os.exit(fail==0 and 0 or 1)
