"""Validate real GemInfo recipes before any consumption; private server only."""
from pathlib import Path
import argparse, datetime, json, shutil, subprocess
R=Path('/home/ubuntu/cys-test-20260913')
TARGET=R/'GameServer/services/scene/scenecore.lua'
OLD='''		if new_item_index == 0 then
			obj_me:notify_tips("更高等级的宝石尚未开放。")'''
NEW='''        -- CYS 23/09: arithmetic IDs are not proof that the next gem exists.
        -- Reject before dec_item_lay_count/cost_money, preserving every input.
        local gems = configenginer:get_config("gem_info")
		if new_item_index == 0 or not gems[item_index] or not gems[new_item_index] then
			obj_me:notify_tips("更高等级的宝石尚未开放。")'''
def main():
 p=argparse.ArgumentParser(description=__doc__);p.add_argument('mode',choices=['apply','check']);a=p.parse_args()
 text=TARGET.read_text(encoding='utf8')
 if a.mode=='apply' and NEW not in text:
  assert text.count(OLD)==1
  backup=R/'backups'/('gem-recipe-'+datetime.datetime.now().strftime('%Y%m%d-%H%M%S'))
  backup.mkdir(parents=True);shutil.copy2(TARGET,backup/TARGET.name)
  TARGET.write_text(text.replace(OLD,NEW,1),encoding='utf8');print('Backup:',backup)
 text=TARGET.read_text(encoding='utf8');assert NEW in text
 subprocess.run(['luac','-p',str(TARGET)],check=True)
 # Execute the real full production entry point with an inventory double.
 # Invalid recipe must never reach a mutation; a valid recipe must still craft.
 body=text.split('function scenecore:char_gem_compound(me, compound)',1)[1].split('\nfunction scenecore:char_modify_setting',1)[0]
 have=[]
 for line in (R/'configs/GemInfo.txt').read_bytes().split(b'\n')[2:]:
  c=line.split(b'\t')[0]
  if c.isdigit():have.append(int(c))
 lua='''local scenecore={}; local mutations=0; local created=0
 local function mutate() mutations=mutations+1;return true end
 local gems={GEMS}
 local configenginer={get_config=function() return gems end}
 local define={INVAILD_ID=-1,OPERATE_RESULT={}}
 local material={get_index=function() return 30900016 end,is_lock=function()return false end,is_bind=function()return false end}
 local bag={get_item=function()return material end,get_empty_index_count=function()return 1 end}
 local human={get_prop_bag_container=function()return bag end,notify_tips=function()end,
 get_attrib=function()return 1000000 end,get_name=function()return 'test' end,get_guid=function()return 1 end,
 cost_money_with_priority=mutate,get_obj_id=function()return 1 end,get_logic_count=function()return 0 end,
 show_buff_effect=function()end,send_operate_result_msg=function()end}
 scenecore.objs={[1]=human}
 local human_item_logic={get_items_in_need=function()return {{bag_index=0,count=5}},false end,
 gem_compound_item_index=function(_,id)return id+100000,5 end,dec_item_lay_count=mutate,
 create_multi_item_to_bag=function(_,_,_,id)created=id;return true,1 end}
 local result={get_base_config=function()return {quality=1}end}
 function bag:get_item(index) if index==1 then return result else return material end end
 function scenecore:char_gem_compound(me, compound)
 BODY
 scenecore:char_gem_compound(1,{gem_id=50431001,mat_index=0,method=0})
 assert(mutations==0 and created==0,'invalid next gem consumed inventory')
 scenecore:char_gem_compound(1,{gem_id=59999999,mat_index=0,method=0})
 assert(mutations==0 and created==0,'unknown source consumed inventory')
 scenecore:char_gem_compound(1,{gem_id=50401001,mat_index=0,method=0})
 assert(mutations==3 and created==50501001,'valid recipe changed behavior')
 print('PASS invalid-next/unknown-source preserve all inputs; valid recipe consumes gems+charm+money once and creates correct gem')
 '''.replace('GEMS',','.join('[%d]=true'%i for i in have)).replace('BODY',body)
 subprocess.run(['lua','-'],input=lua,text=True,check=True)
 print(json.dumps({'guard':True,'table_gems':len(have),'syntax':'PASS'}))
if __name__=='__main__':main()
