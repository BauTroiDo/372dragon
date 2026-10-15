"""Install CY high-flight support on the private source server, with backups."""
from pathlib import Path
import argparse,datetime,hashlib,json,re,struct,subprocess,sys
import deploy_equipcraft as installer
ROOT=installer.ROOT
HERE=Path(__file__).resolve().parent
PROJECT=HERE.parents[1]
sys.path.insert(0,str(PROJECT/'Tools/game'))
from dbc_inventory import Table

def changes():
 files={}
 config=PROJECT/'Assets/CanonicalCY/Data/ConfigFolder'
 mounts=[r[0] for r in Table(config/'CharMount.txt').rows if r[19]>=1]
 scenes={}; evidence=[];nav_bundle=bytearray(b'CYFN1');nav_entries={}
 for r in Table(config/'SceneDefineEx.txt').rows:
  p=PROJECT/'Assets/CanonicalCY/Data/SceneFolder'/Path(r[4]).with_suffix('.fly')
  if not p.is_file():continue
  b=p.read_bytes();n=struct.unpack_from('<I',b)[0]
  if n!=(r[2]+1)*(r[3]+1) or len(b) not in [4+4*n,20+4*n]:continue
  navpath=PROJECT/'Assets/CanonicalCY/Data/SceneFolder'/r[5]
  if not navpath.is_file():continue
  navbytes=navpath.read_bytes();digest=hashlib.sha256(navbytes).hexdigest()
  assert struct.unpack_from('<H',navbytes)[0] in [0x1000,0x2000],navpath
  if digest not in nav_entries:
   nav_entries[digest]=[len(nav_bundle),len(navbytes)];nav_bundle.extend(navbytes)
  scenes[r[0]]=[r[2],r[3],*nav_entries[digest]];evidence.append({'scene':r[0],'file':p.name,'sha256':hashlib.sha256(b).hexdigest(),'header':len(b)-4*n,'navfile':navpath.name,'navsha256':digest})
 lua='-- Generated from canonical CY CharMount[19], SceneDefineEx and validated .fly/.path files.\nreturn {mounts={'+','.join(f'[{n}]=true' for n in mounts)+'},scenes={'+','.join('[%d]={%s}'%(n,','.join(map(str,s))) for n,s in scenes.items())+'},knockoff={[37]=true}}\n'
 files['GameServer/lualib/cys_mount_flight_nav.bin']=bytes(nav_bundle)
 files['GameServer/lualib/cys_flight_nav.lua']=(HERE/'cys_flight_nav.lua').read_bytes()
 files['GameServer/lualib/cys_mount_flight_data.lua']=lua.encode()
 files['GameServer/lualib/cys_mount_flight.lua']=(HERE/'cys_mount_flight.lua').read_bytes()
 files['GameServer/services/game/packet_domains/cys_mount_flight.lua']=(HERE/'cys_mount_flight_packet.lua').read_bytes()
 def edit(rel,old,new):
  b=files.get(rel,(ROOT/rel).read_bytes());s=b.decode('utf8')
  if new not in s:
   assert s.count(old)==1,(rel,old,s.count(old));s=s.replace(old,new)
  files[rel]=s.encode()
 def head(rel,signature,body):edit(rel,signature,signature+'\n    -- CYS-MOUNT-FLIGHT\n'+body)
 p='GameServer/services/game/packet.lua'
 edit(p,'return packet','require("game.packet_domains.cys_mount_flight").bind(packet,bistream,bostream)\nreturn packet')
 p='GameServer/services/msgagent.lua'
 edit(p,'function request:CGCharAutoRide()', 'function request:CGFlyOperation()\n    skynet.send(my_scene,"lua","mount_flight_operation",my_obj_id,self)\nend\n\nfunction request:CGCharAutoRide()')
 p='GameServer/services/scene/scenecore.lua'
 edit(p,'function scenecore:char_auto_ride(who, flag)','function scenecore:mount_flight_operation(who,req)\n    return require("cys_mount_flight").request(self,who,req)\nend\n\nfunction scenecore:char_auto_ride(who, flag)')
 head(p,'function scenecore:char_auto_ride(who, flag)', '''    local flight=require 'cys_mount_flight'
    if flight.active(self.objs[who]) then flight.refuse(self,self.objs[who],'Hãy hạ cánh trước khi xuống thú cưỡi.');return end''')
 head(p,'function scenecore:char_diepel_buff(obj_id, req)', '''    local f=require 'cys_mount_flight';local h=self.objs[obj_id]
    if f.active(h) then f.refuse(self,h,'Hãy hạ cánh trước khi hủy trạng thái kỹ năng.');return end''')
 head(p,'function scenecore:on_ask_team_follow(obj_me)', '''    if require('cys_mount_flight').active(obj_me) then obj_me:notify_tips('Hãy hạ cánh trước khi tập hợp đội.');return end''')
 head(p,'function scenecore:char_move(my_obj_id, move)', '''    local h=self.objs[my_obj_id];local f=require 'cys_mount_flight'
    if f.changing(h) then return define.OPERATE_RESULT.OR_BUSY end
    if f.active(h) then
        if not f.bounds(self,move.posWorld) then return define.OPERATE_RESULT.OR_ERROR end
        for _,pos in ipairs(move.targetPos or {})do if not f.bounds(self,pos)then return define.OPERATE_RESULT.OR_ERROR end end
    end''')
 old='            self:send2client(to, ret)\n            skynet.timeout(5,function()'
 edit(p,old,'            self:send2client(to, ret)\n            require("cys_mount_flight").sync(self,obj,to)\n            skynet.timeout(5,function()')
 p='GameServer/services/scene/obj/human.lua'
 head(p,'function human:set_ride(ride)', '''    if require('cys_mount_flight').active(self) then self:notify_tips('Hãy hạ cánh trước khi đổi thú cưỡi.');return end''')
 head(p,'function human:on_enter_scene()', '''    require('cys_mount_flight').reset(self)''')
 p='GameServer/services/scene/obj/character.lua'
 head(p,'function character:do_move(handle, pos_tar)', '''    if require('cys_mount_flight').changing(self) then return define.OPERATE_RESULT.OR_BUSY end''')
 head(p,'function character:can_use_this_skill_in_this_status(skill_id)', '''    if require('cys_mount_flight').active(self) then return false end''')
 head(p,'function character:do_use_item(bag_index, target_obj_id, target_pos, target_pet_guid, target_item_bag_index)', '''    local flight=require 'cys_mount_flight'
    if flight.active(self) or flight.active(self:get_scene():get_obj_by_id(target_obj_id)) then return define.OPERATE_RESULT.OR_BUSY end''')
 # Check targets at selection and hit time, including delayed missiles/AOE.
 p='GameServer/services/scene/skill/base.lua'
 head(p,'function skill:is_wantd_target(obj_me, obj_tar, skill_info)', '''    if not require('cys_mount_flight').skill_allowed(obj_me,obj_tar,skill_info:get_skill_id()) then return false end''')
 head(p,'function skill:hit_this_target(obj_me, obj_tar)', '''    if not require('cys_mount_flight').skill_allowed(obj_me,obj_tar,obj_me:get_skill_info():get_skill_id()) then return false end''')
 p='GameServer/services/scene/ai/human.lua'
 head(p,'function human:push_command_team_follow()', '''    if require('cys_mount_flight').active(self:get_character()) then return define.OPERATE_RESULT.OR_BUSY end''')
 out=PROJECT/'Build/Logs/2026-09-24-mount-flight-actions';out.mkdir(parents=True,exist_ok=True)
 (out/'data-evidence.json').write_text(json.dumps({'mounts':mounts,'scenes':evidence},ensure_ascii=False,indent=2),encoding='utf8')
 return files

if __name__=='__main__':
 # Reuse the proven installer: syntax checks, connected-client guard, per-file
 # compare-before-write, full backups. The manifest enumerates exact flight files.
 installer.changes=changes
 installer.main()
