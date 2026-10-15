local root=assert(arg[1]);local live=assert(arg[2])
package.path=root..'/GameServer/lualib/?.lua;'..live..'/GameServer/lualib/?.lua;'..package.path
local define=require 'define'
package.loaded.wire_charset={fromutf8=function(s)return s end}
local global={GUILD_MONEY=7,GUILD_CONTRIB_POINT=6,
    TICKET_ITEM_PARAM_CUR_MONEY_START=4,TICKET_ITEM_PARAM_CUR_MONEY_TYPE='uint',
    TICKET_ITEM_PARAM_MAX_MONEY_START=8,TICKET_ITEM_PARAM_MAX_MONEY_TYPE='uint'}
package.loaded['scripts.ScriptGlobal']=global
package.loaded.script_base=require('class')('audit_script_base')
local npc=assert(loadfile(root..'/Game_2/Script/scripts/obj/city/pc_guilddirector.lua'))()
local function trader(balance,ticket)
    local t=setmetatable({balance=balance,ticket=ticket,granted=0,reward=0,experience=0,
        changes={},params={},tips={}}, {__index=npc})
    local h={};t.scene={get_obj_by_id=function()return h end}
    function t:IsValidEvent()return 0 end
    function t:GetHumanGuildID()return 1 end
    function t:GetCityGuildID()return 1 end
    function t:GetGuildPos()return define.GUILD_POSITION_CHIEFTAIN end
    function t:GetLevel()return 60 end
    function t:GetBagPosByItemSn()return self.ticket and 0 or -1 end
    function t:CityGetAttr()return self.balance end
    function t:BeginEvent()end
    function t:AddText(s)table.insert(self.tips,s)end
    function t:EndEvent()end
    function t:DispatchMissionTips()end
    function t:DispatchEventList()end
    function t:BeginAddItem()end
    function t:AddItem()end
    function t:EndAddItem()return self.bagOK~=false end
    function t:AddItemListToHuman()if self.commitOK==false then return false end;self.granted=self.granted+1;self.ticket=true;return true end
    function t:SetBagItemParam(_,_,start,value,vtype)
        self.params[#self.params+1]={start=start,value=value,vtype=vtype}
    end
    function t:CityChangeAttr(_,attr,amount)
        if self.reenter then local f=self.reenter;self.reenter=nil;f(self) end
        if self.denyDebit and amount<0 then return 0 end
        if attr==7 then self.balance=self.balance+amount end
        self.changes[#self.changes+1]={attr=attr,amount=amount};return 1
    end
    function t:LuaFnRefreshItemInfo()end
    function t:GetBagItemParam()return 150000 end
    function t:AddMoney(_,n)self.reward=self.reward+n end
    function t:AddExp(_,n)self.experience=self.experience+n end
    function t:DelItem()if self.deleteOK then self.ticket=false;return true end;return false end
    return t
end
local checks=0;local function check(v,name)assert(v,name);checks=checks+1;print('PASS '..name)end
local t=trader(0,false);t:OnEventRequest(1,2,t.script_id,16)
check(t.granted==0 and #t.changes==0,'insufficient treasury has no side effects')
t=trader(30000,false);t:OnEventRequest(1,2,t.script_id,16)
check(t.granted==1 and t.balance==0,'exact treasury cost allowed')
check(t.params[1].value==30000 and t.params[1].vtype=='uint' and t.params[2].value==150000,'ticket values and types correct')
t:OnEventRequest(1,2,t.script_id,16);check(t.granted==1,'existing ticket blocks duplicate')
for _,key in ipairs{'bagOK','commitOK'}do t=trader(100000,false);t[key]=false;t:OnEventRequest(1,2,t.script_id,16);check(t.granted==0 and t.balance==100000,key..' refunds reserved treasury')end
t=trader(100000,false);t.denyDebit=true;t:OnEventRequest(1,2,t.script_id,16);check(t.granted==0 and t.balance==100000,'failed treasury reservation never grants')
t=trader(100000,false);t.reenter=function(x)x:OnEventRequest(1,2,x.script_id,16)end;t:OnEventRequest(1,2,t.script_id,16);check(t.granted==1 and t.balance==70000,'RPC reentry gives one ticket and one debit')
t=trader(100000,true);t:OnEventRequest(1,2,t.script_id,17);check(t.ticket and t.reward==0 and t.experience==0 and #t.changes==0,'failed deletion has no rewards')
t.deleteOK=true;t:OnEventRequest(1,2,t.script_id,17);check(not t.ticket and t.reward==15000 and t.experience==20000 and t.balance==235000,'successful redemption rewards once')
t:OnEventRequest(1,2,t.script_id,17);check(t.reward==15000 and t.experience==20000,'duplicate redemption has no rewards')
for _,level in ipairs{69,84,100,160,200}do t=trader(100000,false);function t:GetLevel()return level end;t:OnEventRequest(1,2,t.script_id,16);check(t.granted==1 and t.params[1].value>0,'valid ticket at level '..level)end
print('PASS trader checks='..checks)

local care=assert(loadfile(root..'/Game_2/Script/scripts/obj/city/pc_industrialofficer.lua'))()
local function patient(level)
 local t=setmetatable({points=1,last=0,today=100,buffs=0,level=level}, {__index=care})
 function t:GetHumanGuildID()return 1 end;function t:GetCityGuildID()return self.foreign and 2 or 1 end
 function t:CityGetAttr()return self.points end;function t:GetDayTime()return self.today end
 function t:GetMissionData()return self.last end;function t:SetMissionData(_,_,v)self.last=v end
 function t:CityGetSelfCityID()return 1 end;function t:CityGetMaintainStatus()return self.maintain or 0 end
 function t:GetLevel()return self.level end;function t:GetName()return 'Test' end
 function t:CityChangeAttr(_,_,n)if self.denied then return 0 end;self.points=self.points+n;return 1 end
 function t:BroadMsgByChatPipe()end
 function t:LuaFnSendSpecificImpactToUnit(_,_,_,id)self.buff=id;self.buffs=self.buffs+1 end
 return t
end
for _,n in ipairs{10,69,160,161,200}do local t=patient(n);t:SetFavorOfGuild(1);check(t.points==0 and t.buffs==1,'care spends contribution at level '..n);t:SetFavorOfGuild(1);check(t.buffs==1,'care once a day at level '..n)end
for _,k in ipairs{'foreign','denied'}do local t=patient(60);t[k]=true;t:SetFavorOfGuild(1);check(t.points==1 and t.buffs==0 and t.last==0,k..' care rejected')end
local t=patient(60);t.maintain=1;t:SetFavorOfGuild(1);check(t.buffs==0 and t.points==1,'maintenance blocks care')
for _,name in ipairs{'city0_LevelUp','city0_Research'}do
 local q=assert(loadfile(root..'/Game_2/Script/scripts/'..name..'.lua'))()
 local actor=setmetatable({}, {__index=q})
 function actor:GetLevel()return 200 end
 function actor:GetMoney()return 1000000 end
 function actor:AddMission()error('Must not accept an unimplemented progress mission')end
 function actor:DelMission()error('Must not remove mission before progress is available')end
 function actor:CostMoney()error('Must not debit money before progress is available')end
 check(actor:CheckAccept(1)==0,name..' cannot offer a mission without progress support')
 check(actor:OnAccept(1)==0,name..' forged acceptance rejected')
 check(actor:CheckSubmit(1)==0,name..' submission requires progress support')
 actor:OnSubmit(1,2,0);check(true,name..' cannot lose money or mission on submission')
end
print('PASS trader and welfare checks='..checks)
