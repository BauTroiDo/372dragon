-- Exercise the actual staged human/title functions, including forged requests.
local base=assert(arg[1]);local checks=0
local function check(v,why)checks=checks+1;assert(v,why)end
local function read(p)local f=assert(io.open(p));local s=f:read('*a');f:close();return s end
local config={[1043]={Type=137,IA={0,35},IV={5000,1288}},[1000]={Type=100,IA={},IV={}},[1001]={Type=100,IA={},IV={}}}
local human={};local scene={};local env={human=human,scenecore=scene,define={INVAILD_ID=-1},configenginer={get_config=function()return config end}}
setmetatable(env,{__index=_G})
local function fn(file,name)
 local s=read(base..file);local first=assert(s:find('function '..name..'(',1,true));local last=s:find('\nfunction ',first+10,true)
 assert(load(s:sub(first,last and last-1 or #s),'@'..name,'t',env))()
end
local path='/GameServer/services/scene/obj/human.lua'
for _,name in ipairs({'have_id_title','check_have_id_title','del_conflict_titles','add_id_title','set_title','get_title_by_id','set_cur_title_by_id','set_cur_title_by_id_title'})do fn(path,'human:'..name)end
fn('/GameServer/services/scene/scenecore.lua','scenecore:char_update_cur_title')
local h=setmetatable({titles={},id_titles={},dirty=0,updates=0},{__index=human})
function h:set_current_title(t)assert(t);self.current=t end
function h:update_titles_to_client()self.updates=self.updates+1 end
h.db={mark_all_attr_dirty=function()h.dirty=h.dirty+1 end}
function scene:get_obj_by_id(id)if id==1 then return h end end
check(h:add_id_title(1043)==true,'valid title awarded');check(h.current.str=='#1043' and h.dirty==1,'selection and attributes dirty');
check(h:add_id_title(1043)==false and #h.id_titles==1,'duplicate not stacked');check(h:add_id_title(9999)==false,'unknown title rejected');
h:add_id_title(1000);h:add_id_title(1001);check(#h.id_titles==2 and h:have_id_title(1001)and not h:have_id_title(1000),'same type replaced');
check(h:set_title(14,'Owned title')==true and h.current.str=='Owned title','new custom title has valid scope');
scene:char_update_cur_title(1,{id=0,id_title_id=1043});check(h.current.str=='#1043','owned numeric selected');
scene:char_update_cur_title(1,{id=0,id_title_id=9999});check(h.current.str=='#1043','unowned numeric rejected');
scene:char_update_cur_title(1,{id=99,id_title_id=0});check(h.current.str=='#1043','unowned custom rejected');
scene:char_update_cur_title(1,{id=14,id_title_id=0});check(h.current.str=='Owned title','owned custom selected');
scene:char_update_cur_title(1,{id=0,id_title_id=0});check(h.current.str=='' and #h.id_titles==2,'hide preserves owned bonuses');
scene:char_update_cur_title(999,{id=0,id_title_id=0});check(h.current.str=='','missing player safe');
-- The real attribute-flush function must still apply owned bonuses while hidden.
env.human_attrib={}
fn('/GameServer/lualib/db/human_attrib.lua','human_attrib:title_new_effect_flush')
local effects={}
local attr=setmetatable({},{__index=env.human_attrib})
function h:get_id_titles()return self.id_titles end
function attr:get_human()return h end
function attr:cal_item_effect(ia,iv)effects[#effects+1]={ia,iv}end
attr:title_new_effect_flush()
check(#effects==2 and effects[1][1]==0 and effects[1][2]==5000 and effects[2][1]==35 and effects[2][2]==1288,'owned title contributes HP and hit while hidden')
h.id_titles[#h.id_titles+1]={id=9999};effects={};attr:title_new_effect_flush()
check(#effects==2,'historical unknown title skipped without losing valid bonuses')
h:set_cur_title_by_id_title(1043);effects={};attr:title_new_effect_flush()
check(#effects==2,'showing a title does not apply its bonuses twice')
print('PASS title server checks='..checks)
