-- Run against the staged module with Lua 5.4, without touching the server DB.
local source=assert(arg[1]);local count=0
local function check(v,why) count=count+1;assert(v,why) end
local function clone(t)if type(t)~='table'then return t end local r={}for k,v in pairs(t)do r[k]=clone(v)end return r end
table.clone=clone
local saved,answers,users,notifications
local skynet={}
function skynet.call(target,_,method,...)
 local a={...}
 if method=='get_player_info_by_name'then return clone(users[a[1]]) end
 if method=='get_player_info'then for _,u in pairs(users)do if u.guid==a[1]then return clone(u)end end return nil end
 if method=='call_human_function'then if a[2]=='set_relation_list_from_agent'then saved=clone(a[3])end return end
 error(method)
end
function skynet.send(...)notifications=notifications+1 end
package.preload.skynet=function()return skynet end
package.preload['game.packet']=function()return {GCRelation={new=function()return {}end}}end
package.preload.define=function()return {}end
local agent={CGRelation=function()return 'old'end}
assert(loadfile(source))().install(agent)
function agent:send2client(p)answers[#answers+1]=p end
local h=setmetatable({my_scene=1,my_obj_id=2,my_guid=15},{__index=agent})
local function reset()
 h.my_data={relation={friends={},black={},enemies={},temp={},mood=''}}
 users={Alice={guid=16,name='Alice'},Bob={guid=17,name='Bob'},Refuse={guid=18,name='Refuse',game_flags=1}}
 saved=nil;answers={};notifications=0
end
local function send(t,q)h:CGRelation{type=t,request_relation_info=q};return answers[#answers]end
reset();check(send(4,{name='Alice',group=1}).type==5,'add reply');check(#saved.friends==1,'add persisted');check(saved.friends[1].guid==16,'identity');
check(send(4,{name='Alice',group=1}).type==28,'duplicate rejected');check(#h.my_data.relation.friends==1,'no duplicate');
check(send(8,{guid=16,from=1,to=2}).type==9,'move');check(saved.friends[1].group==2,'move persisted');
check(send(8,{guid=16,from=1,to=3}).type==30,'stale source');check(saved.friends[1].group==2,'stale unchanged');
check(send(8,{guid=16,from=2,to=5}).type==9,'block friend');check(#saved.friends==0 and #saved.black==1,'block saved');
check(send(8,{guid=16,from=5,to=3}).type==9,'unblock to friend');check(saved.friends[1].group==3 and saved.friends[1].relation_type==1,'unblock metadata');
check(send(9,{guid=16}).type==10,'delete');check(#saved.friends==0,'delete persisted');check(send(9,{guid=16}).type==31,'repeat delete');
check(send(5,{name='Bob'}).type==6,'direct blacklist');check(saved.black[1].group==5 and saved.black[1].relation_type==4,'blacklist type matches define.RELATION_TYPE_BLACKNAME');
check(send(10,{guid=17}).type==10,'remove blacklist');check(#saved.black==0,'blacklist remove persisted');
check(send(4,{name='Refuse',group=1}).type==42,'refusal flag is enforced');check(#h.my_data.relation.friends==0,'refusal does not insert');
check(send(4,{name='NoSuchPlayer',group=1}).type==26,'missing name returns error');
users.Self={name='Self',guid=15};check(send(4,{name='Self',group=1}).type==26,'self rejected');
for from=-3,11 do for to=-3,11 do
 local before=clone(h.my_data.relation);send(8,{guid=777,from=from,to=to})
 check(#h.my_data.relation.friends==#before.friends and #h.my_data.relation.black==#before.black,'invalid move unchanged')
end end
reset();for i=1,20 do users['User'..i]={guid=100+i,name='User'..i};check(send(4,{name='User'..i,group=1}).type==5,'capacity insert')end
check(send(4,{name='Alice',group=1}).type==27,'group limit20');check(send(4,{name='Alice',group=2}).type==5,'another group available');
reset();for i=1,10 do users['User'..i]={guid=100+i,name='User'..i};check(send(5,{name='User'..i}).type==6,'black capacity insert')end
check(send(5,{name='Alice'}).type==27,'black limit10');
reset();check(send(13,{mood='Xin chao'}).type==16 and saved.mood=='Xin chao','mood saved');check(send(13,{mood=string.rep('x',30)}).type==46,'mood wire length');
h.my_data.relation.friends={{guid=16,name='Alice',group=1,relation_type=3}}
check(send(8,{guid=16,from=1,to=5}).type==30,'protected relation not blacklisted');check(send(9,{guid=16}).type==31,'protected relation not deleted');
print('PASS community server checks='..count)
