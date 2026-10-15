-- Run the staged, real callbacks with deterministic scene/party fixtures.
local root=assert(arg[1]);local stage=assert(arg[2])
package.path=root..'/GameServer/lualib/?.lua;'..stage..'/Game_2/Script/?.lua;'..root..'/Game_2/Script/?.lua;'..package.path
local count=0
local function eq(a,b,msg)count=count+1;assert(a==b,(msg or '')..' '..tostring(a)..' ~= '..tostring(b))end
local base={};package.loaded.script_base=base
package.loaded.class=function()return setmetatable({},{__index=base})end
package.loaded.define={};package.loaded['scripts.ScriptGlobal']={FUBEN_PORTECT_PET=9}
package.loaded.wire_charset={fromutf8=function(s)return s end}
local warnings=0;package.loaded.skynet={loge=function()warnings=warnings+1 end}
local B=require 'scripts.obj.DynamicNPC.bg_CangJingGe'
local F=require 'scripts.obj.DynamicNPC.FB_cangjinge_FB'
local function obj(t)return setmetatable({},{__index=t})end
local function scene(T)
 local s=obj(T);s.params={};for i=0,31 do s.params[i]=0 end
 s.params[8]=95;s.params[9]=9;s.params[10]=113565
 s.params[3]=18;s.params[16]=266;s.params[17]=257
 s.live={};s.spawn={};s.attrs={};s.users={71,72,73};s.nextid=100;s.kicked={};s.tips={};s.broad=0
 function s:LuaFnCreateMonster(id,x,y,ai,ext,script)
  if self.fail or self.failAt==#self.spawn+1 then return nil end
  assert(id>=113565 and id<=113600,'wrong monster family '..id)
  self.nextid=self.nextid+1;local o={id=self.nextid,data=id,x=x,y=y,ai=ai,ext=ext,script=script}
  self.live[o.id]=o;self.spawn[#self.spawn+1]=o;return o.id
 end
 function s:LuaFnSetNpcIntParameter(id,k,v)assert(self.live[id]);self.live[id][k]=v end
 function s:LuaFnGetNpcIntParameter(id,k)return assert(self.live[id])[k] or 0 end
 function s:SetCharacterTitle(id,v)assert(self.live[id]);self.live[id].title=v end
 function s:SetCharacterDieTime(id,v)assert(self.live[id]);self.live[id].ttl=v end
 function s:SetUnitCampID(id,v)assert(self.live[id]);self.live[id].camp=v end
 function s:SetMonsterFightWithNpcFlag(id,v)assert(self.live[id]);self.live[id].fight=v end
 function s:SetPatrolId(id,v)assert(self.live[id]);self.live[id].patrol=v end
 function s:SetLevel(id,v)assert(self.live[id] and v==math.floor(v));self.live[id].level=v end
 function s:LuaFnIsCharacterLiving(id)return self.live[id] and not self.live[id].dead end
 function s:LuaFnGetCopySceneData_Param(k)return self.params[k]end
 function s:LuaFnSetCopySceneData_Param(k,v)self.params[k]=v end
 function s:get_scene_id()return 18 end
 function s:GetMonsterCount()local n=0;self.ids={};for id in pairs(self.live)do self.ids[#self.ids+1]=id;n=n+1 end;table.sort(self.ids);return n end
 function s:GetMonsterObjID(i)return self.ids[i]end
 function s:GetMonsterDataID(id)return assert(self.live[id]).data end
 function s:LuaFnGetCopyScene_HumanCount()return #self.users end
 function s:LuaFnGetCopyScene_HumanObjId(i)return self.users[i]end
 function s:LuaFnIsObjValid(id)for _,v in ipairs(self.users)do if v==id then return true end end;return false end
 function s:NewWorld(id,sc,sn,x,z)eq(sc,18);eq(x,266);eq(z,257);self.kicked[id]=true end
 function s:LuaFnAddMissionHuoYueZhi(id,k)eq(k,19);self.attrs[id]=(self.attrs[id] or 0)+1 end
 function s:GetTeamLeader()return 71 end
 function s:GetName()return 'CYS fixture'end
 function s:BeginEvent()end
 function s:AddText(t)self.tips[#self.tips+1]=t end
 function s:EndEvent()end
 function s:DispatchMissionTips()end
 function s:BroadMsgByChatPipe()self.broad=self.broad+1 end
 function s:StartOneActivity()self.started=true end
 return s
end
-- Authenticated event creation, re-entry and replenishment: old code repeatedly
-- marked only the first matching row and created 17 duplicates every time.
local s=scene(B);B.DataValidator=42
s:OnDefaultEvent(2,0,0,0,0,0,41);eq(#s.spawn,0,'bad validator')
s:OnDefaultEvent(2,0,0,0,0,0,42);eq(#s.spawn,18)
for _,o in ipairs(s.spawn)do eq(o.data,113565);eq(o.script,402111);eq(o[1],18);eq(o[2],3);eq(o.ttl,1800000)end
s:OnDefaultEvent(2,0,0,0,0,0,42);eq(#s.spawn,18,'no duplicate entry NPC')
local removed={};for _,i in ipairs({5,11,18})do removed[i]=s.spawn[i];s.live[s.spawn[i].id]=nil end
s:OnDefaultEvent(2,0,0,0,0,0,42);eq(#s.spawn,21,'replace only missing NPCs')
for i=19,21 do local o=s.spawn[i];local old=assert(removed[o[3]],'wrong spawn slot');eq(o.x,old.x);eq(o.y,old.y)end
s=scene(B);s.fail=true;s:OnDefaultEvent(2,0,0,0,0,0,42);eq(#s.spawn,0)
-- Both directions and every supported party decade resolve within the family.
for _,level in ipairs({40,49,50,80,95,110,119,120,150,200})do
 s=scene(F);s.params[8]=level;s.params[9]=math.floor(level/10)
 for side=0,1 do s:CreateXiaoBOSS(side)end
 local expected=113574+math.min(8,math.floor(level/10)-3)
 eq(#s.spawn,2);for i,o in ipairs(s.spawn)do eq(o.data,expected);eq(o.level,level);eq(o.patrol,i-1);eq(o.camp,101)end
 for _,baseid in ipairs({113574,113583,113592})do
  local id=s:CreateNpc(baseid,1,2,9,0,-1,227766)
  eq(s.live[id].data,baseid+math.min(8,math.floor(level/10)-3))
 end
 eq(s:CreateNpc(113583,1,2,9,0,-1,0),-1,'unauthorized direct spawn')
end
-- A full timed run executes the real 13 waves, boss, protection and exit paths.
s=scene(F)
for tick=1,810 do s:OnCopySceneTimer(tick)end
eq(#s.spawn,184,'guardian + 169 ordinary + 13 mini-bosses + final boss')
eq(s.params[24],6);eq(s.params[25],7);eq(s.params[22],7);eq(s.params[23],6)
eq(s.live[s.params[15]].data,113571,'guardian by party decade')
eq(s.live[s.params[13]].data,113598,'boss by party decade')
eq(s.attrs[71],1);eq(s.attrs[72],1);eq(s.attrs[73],1)
local before=s.params[2];s:OnDie(999,71);eq(s.params[2],before,'unrelated death cannot finish')
s:OnDie(s.params[13],71);eq(s.params[2],1780)
for tick=1781,1800 do s:OnCopySceneTimer(tick)end
eq(s.params[21],1);eq(s.broad,1,'success announcement once')
for _,id in ipairs(s.users)do eq(s.kicked[id],true)end
-- Infrastructure failure cannot mutate an invalid object or grant success.
for _,at in ipairs({1,2,16,184})do
 s=scene(F);s.failAt=at
 for tick=1,1800 do s:OnCopySceneTimer(tick)end
 eq(s.params[21],-1);eq(s.broad,0)
 for _,id in ipairs(s.users)do eq(s.kicked[id],true)end
end
-- Instance creation errors retain the entry NPC, successful creation consumes it.
local function entry(success)
 local x=scene(F);x.copy=success and 99 or -1;x.deleted=0
 function x:LuaFnIsActivityMonster()return true end
 function x:LuaFnHasTeam()return true end
 function x:GetTeamSize()return 3 end
 function x:GetNearTeamCount()return 3 end
 function x:GetNearTeamMember(selfId,i)return self.users[i]end
 function x:GetLevel(id)return id==71 and 95 or 96 end
 function x:LuaFnObjId2Guid()return 200016 end
 function x:GetTeamId()return 6 end
 function x:GetHumanMaxLevelLimit()return 200 end
 function x:GetMonsterDataID()return 113565 end
 function x:GetWorldPos()return 266,257 end
 function x:LuaFnGenCopySceneSN()return 5 end
 function x:LuaFnCreateCopyScene(config)self.config=config;return self.copy end
 function x:LuaFnDeleteMonster()self.deleted=self.deleted+1 end
 x:OnDefaultEvent(71,88,402112,10)
 eq(x.deleted,success and 1 or 0);eq(x.config.params[8],95,'integral weighted level')
end
entry(false);entry(true)
print('PASS Cangjingge '..count..' assertions: data family, duplicate start, all waves, spawn failure, exit and failed entry')
