local root,stage=assert(arg[1]),assert(arg[2])
package.path=stage..'/GameServer/lualib/?.lua;'..root..'/GameServer/lualib/?.lua;'..root..'/Game_2/Script/?.lua;'..package.path
package.loaded.skynet={getenv=function()end}
local class=require 'class';local base=class('shimen_test');local S
function base:IsHaveMission(who)return S.people[who]~=nil end
function base:GetMissionIndexByID(who)return who end
function base:GetMissionParam(who,_,k)return S.people[who][k]or 0 end
function base:SetMissionByIndex(who,_,k,v)S.people[who][k]=v end
function base:GetMissionParamEx(who,_,_,k)return S.people[who].counter[k]end
function base:SetMissionParamByIndexEx(who,_,_,k,v)S.people[who].counter[k]=v end
function base:GetLevel()return S.level end
function base:GetName(id)return id==2 and S.npc or 'Player' end
function base:GetNpcInfoByNpcId(id)return id,'npc'..id,'scene',1,2,'desc'end
function base:GetMonsterNamebyDataId(id)return 'npc'..id end
function base:GetMonsterOwnerCount()return 3 end
function base:GetMonsterOwnerID(_,n)return n+1 end
function base:GetItemCount(_,id)return S.items[id]or 0 end
base.LuaFnGetAvailableItemCount=base.GetItemCount
function base:HaveItem(_,id)return (S.items[id]or 0)>0 and 1 or 0 end
function base:HaveItemInBag(_,id)return (S.items[id]or 0)>0 end
function base:IsEquipItem()return S.equip and 1 or 0 end
function base:IsWhiteEquip()return S.white and 1 or 0 end
function base:GetItemDetailInfo(id)return id,'item'..id,'desc'end
base.GetItemInfoByItemId=base.GetItemDetailInfo
function base:DelItem(_,id,n)assert((S.items[id]or 0)>=n);S.items[id]=S.items[id]-n;S.spent=S.spent+n;return 1 end
function base:LuaFnDelAvailableItem(who,id,n)self:DelItem(who,id,n);return true end
function base:DelMission(who)S.people[who]=nil end
function base:CallScriptFunction(_,method)if method=='OnSubmit_Necessary'then S.rewards=S.rewards+1;return 0,0 end end
function base:SetMissionData()end
for _,k in ipairs({'BeginEvent','EndEvent','AddText','DispatchMissionTips','DispatchEventList','DispatchMissionDemandInfo','ResetMissionEvent'})do base[k]=function()end end
package.loaded.script_base=base
local passed,failed=0,0
local function test(name,fn)local ok,e=xpcall(fn,debug.traceback);if ok then passed=passed+1 else failed=failed+1;print('FAIL',name,e)end end
for _,name in ipairs({'shaolin','mingjiao','wudang','emei','dali','xiaoyao','tianshan','xingxiu','gaibang'})do
 local cls=assert(loadfile(stage..'/Game_2/Script/scripts/event/shimen/event_shimen_'..name..'.lua'))();local q=cls.new()
 local function state(kind,marker)
  S={people={[1]={[0]=marker or 0,[1]=q.g_SubMissionTypeEnum[kind],counter={[0]=2,[1]=0}}},level=20,items={},spent=0,rewards=0}
  S.people[1][q.g_StrForePart+1]=91;S.people[1][q.g_StrForePart+2]=92;S.people[1][q.g_StrForePart+3]=93
 end
 for _,kind in ipairs({'SongXin','KaiGuang','DingDianYinDao','killMonster'})do
  test(name..' marker '..kind,function()
   state(kind);assert(q:CheckSubmit(1)==0);q:OnSubmit(1,2);assert(S.rewards==0)
   S.people[1][0]=1;assert(q:CheckSubmit(1)==1);q:OnSubmit(1,2);assert(S.rewards==1)
   q:OnSubmit(1,2);assert(S.rewards==1)
  end)
 end
 test(name..' capture selection is not completion',function()state('BuZhuo',1);assert(q:CheckSubmit(1)==2);q:OnSubmit(1,2);assert(S.rewards==0 and S.people[1])end)
 test(name..' equipment selection is not completion',function()state('XunWu');S.items[91]=1;S.equip=true;assert(q:CheckSubmit(1)==2);q:OnSubmit(1,2);assert(S.rewards==0 and S.spent==0)end)
 test(name..' collect five and replay',function()state('ShouJi');S.items[92]=4;assert(q:CheckSubmit(1)==0);S.items[92]=6;assert(q:CheckSubmit(1)==1);q:OnSubmit(1,2);assert(S.spent==5 and S.rewards==1);q:OnSubmit(1,2);assert(S.spent==5 and S.rewards==1)end)
 test(name..' delivery target',function()state('SongXin');S.items[93]=1;S.npc='wrong';q:OnDefaultEvent(1,2);assert(S.spent==0 and S.people[1][0]==0);S.npc='npc91';q:OnDefaultEvent(1,2);assert(S.spent==1 and S.people[1][0]==1)end)
 test(name..' each party member own objective',function()
  state('killMonster');S.people[2]={[0]=0,[1]=q.g_SubMissionTypeEnum.ShouJi,counter={[0]=2,[1]=0}}
  S.people[3]={[0]=0,[1]=q.g_SubMissionTypeEnum.killMonster,counter={[0]=2,[1]=0},[q.g_StrForePart+3]=94}
  q:OnKillObject(1,93,8);assert(S.people[1].counter[1]==1 and S.people[2].counter[1]==0 and S.people[3].counter[1]==0)
  q:OnKillObject(1,93,9);q:OnKillObject(1,93,10);assert(S.people[1].counter[1]==2 and S.people[1][0]==1)
 end)
 test(name..' absent quest events',function()state('ShouJi');S.people={};q:OnItemChanged(1,92);q:OnPetChanged(1,92);q:OnMissionCheck(1,2);assert(S.rewards==0)end)
 test(name..' partial collect abandonment',function()state('ShouJi');S.items[92]=3;q:OnAbandon(1);assert(S.spent==3 and not S.people[1])end)
 for _,level in ipairs({10,19,20,39,40,79,99,100,149,150,151,199,200})do
  test(name..' authored bands at '..level,function()state('killMonster');S.level=level;local n=q:GetDemandKillCount(1);assert(n and n>=20 and n<=55);assert(type(q:GetRateOfDropYiWu(1))=='number')end)
 end
end
print(string.format('Shimen callbacks: %d passed, %d failed',passed,failed));os.exit(failed==0 and 0 or 1)
