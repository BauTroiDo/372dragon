-- Execute the staged portal transfer function with isolated scene objects.
local path=assert(arg[1]);local f=assert(io.open(path));local src=f:read('*a');f:close()
local T={};local env=setmetatable({team=T,skynet={logi=function()end,loge=function()end},require=function()
 return {resolve=function(_,_,_,_,x,y)return x,y end}
end},{__index=_G})
local a=assert(src:find('function team:TransferFunc(',1,true));local b=assert(src:find('function team:TransferFuncFromNpc(',a,true))
assert(load(src:sub(a,b-1),'staged transfer','t',env))()
local checks=0;local function check(v,n)assert(v,n);checks=checks+1;print('PASS '..n)end
local function fixture()
 local t=setmetatable({map=2,moves={},following=true,leader=true,followed={1,2},humans={}}, {__index=T})
 for i=1,2 do
  local h={team=10,follow=true};function h:get_team_id()return self.team end
  function h:get_team_follow_flag()return self.follow end;function h:is_die()return self.dead end;t.humans[i]=h
 end
 t.scene={get_obj_by_id=function(_,id)return t.humans[id]end}
 function t:GetWorldPos()return 20,30 end;function t:get_scene_id()return self.map end
 function t:IsSceneAvailable()if self.duringAvailable then self:duringAvailable()end;return not self.unavailable end
 function t:LuaFnGetDestSceneHumanCount()return 0 end;function t:LuaFnGetDRideFlag()return false end
 function t:LuaFnHasTeam()return true end;function t:IsTeamFollow()return self.following end
 function t:LuaFnIsTeamLeader()return self.leader end;function t:LuaFnGetFollowedMembersCount()return #self.followed end
 function t:GetFollowedMember(_,i)return self.followed[i]end
 function t:IsHaveMission()return false end;function t:GetItemCount()return 0 end
 function t:CheckChangeScene(id)if self.duringCheck then self:duringCheck(id)end;return id==self.blocked and 0 or 1 end
 function t:NewWorld(id,map,_,x,y)self.moves[#self.moves+1]={id=id,map=map,x=x,y=y}end
 function t:SetPos(id,x,y)self:NewWorld(id,self.map,nil,x,y)end
 function t:NotifyFailTips()end;function t:notify_tips()end
 return t
end
local t=fixture()
for _,map in ipairs{0,1,2}do t:TransferFunc(1,map,100,101,1,200);t.map=map end
check(#t.moves==6 and t.moves[1].id==1 and t.moves[2].id==2 and t.moves[6].map==2,'both following members pass three sequential maps')
t=fixture();t.blocked=2;t:TransferFunc(1,0,100,101);check(#t.moves==0,'one member failing entry prevents split transfer')
t=fixture();t.leader=false;t:TransferFunc(2,0,100,101);check(#t.moves==0,'follower cannot initiate independent gate transition')
t=fixture();function t:duringCheck()self.humans[2].team=11 end;t:TransferFunc(1,0,100,101);check(#t.moves==0,'membership changed during validation aborts')
t=fixture();function t:duringCheck()self.humans[2].follow=false end;t:TransferFunc(1,0,100,101);check(#t.moves==0,'stopped following during validation aborts')
t=fixture();function t:duringAvailable()self.humans[1]={}end;t:TransferFunc(1,0,100,101);check(#t.moves==0,'reused object ID after RPC aborts')
t=fixture();function t:duringCheck()self.humans[2].dead=true end;t:TransferFunc(1,0,100,101);check(#t.moves==0,'death during validation aborts')
t=fixture();t.followed={1,1};t:TransferFunc(1,0,100,101);check(#t.moves==0,'duplicate follow entries cannot transfer twice')
t=fixture();t.following=false;t:TransferFunc(1,0,100,101);check(#t.moves==1 and t.moves[1].id==1,'independent party member may travel alone')
t=fixture();t.followed={1,-1};t:TransferFunc(1,0,100,101);check(#t.moves==0,'member not in current scene blocks group transition')
print('PASS follow transfer checks='..checks)
