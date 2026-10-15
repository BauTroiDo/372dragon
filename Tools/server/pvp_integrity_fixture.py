"""Reversible private test14/test15 fixtures; restart private Game before every write."""
import argparse,copy
from pathlib import Path
from bson import json_util
from cs3b_menpai import provision
from give_item import connected
p=argparse.ArgumentParser();p.add_argument('mode',choices=['seed','reset','restore','verify']);p.add_argument('--scenario',choices=['mode','arena','safe','free'],default='mode');p.add_argument('--backup',type=Path,required=True);a=p.parse_args()
assert not connected(),'private players connected'
with provision().database() as c:
 col=c.tlbb.character
 for guid in (200015,200016):
  d=col.find_one({'attrib.guid':guid});assert d
  path=a.backup/(str(guid)+'.json')
  if a.mode=='seed':
   assert not path.exists();path.parent.mkdir(parents=True,exist_ok=True);path.write_text(json_util.dumps(d),encoding='utf8')
  original=json_util.loads(path.read_text(encoding='utf8'));assert original['_id']==d['_id'] and original['attrib']['guid']==guid
  if a.mode=='verify':assert d==original
  elif a.mode=='restore':col.replace_one({'_id':d['_id']},original);assert col.find_one({'_id':d['_id']})==original
  else:
   fixture=copy.deepcopy(original);attr=fixture['attrib']
   scene,x,y=(6,51,122) if a.scenario=='free' else (0,187,324) if a.scenario=='arena' else (2,219,123)
   attr.update(sceneid=scene,world_pos={'x':x+(2 if guid==200015 else 0),'y':y},level=95,menpai=9,camp_id=0,pk_mode=0,pk_value=0,hp=100000,mp=100000,team_id=-1,raid_id=-1,
     pet_guid={'m_uHighSection':0,'m_uLowSection':0},soul_melting_pet_guid={'m_uHighSection':0,'m_uLowSection':0})
   attr.pop('want_change_pk_mode',None);attr.pop('change_pk_mode_delay',None)
   fixture['sceneid']=scene;fixture['impact_list']={};fixture['cool_down_times']={};fixture['attackers_list']={};fixture['pk_declaration_list']={}
   fixture['lv1_attrib']={'str':500,'con':1000,'int':500,'spr':500,'dex':5000 if guid==200016 else 10,'point_remain':0}
   fixture['skill_list']=[0,1,2,3,21,22,34,35,43];fixture['xinfa_list']={}
   # The normal scene area callback should set the flag. Never seed eligibility.
   fixture['mission_data']['mission_datas'][28]=0
   col.replace_one({'_id':d['_id']},fixture)
  print(a.mode,'test'+str(guid-200001).zfill(2),a.scenario)
