"""Prepare/validate/apply only to the private CY server; preserve every original file."""
from pathlib import Path
import argparse,datetime,hashlib,json,re,shutil,subprocess
from deploy_power import method
ROOT=Path('//wsl.localhost/TLBB/home/ubuntu/cys-test-20260913')
HERE=Path(__file__).resolve().parent
def changes():
 files={'GameServer/lualib/cys_wuhun_appearance.lua':(HERE/'cys_wuhun_appearance.lua').read_bytes()}
 for rel in ['GameServer/services/scene/human.lua','GameServer/services/scene/obj/human.lua']:
  s=(ROOT/rel).read_text(encoding='utf8')
  s=method(s,'human','get_wuhun_visual','''function human:get_wuhun_visual()
    local w=self:get_equip_container():get_item(define.HUMAN_EQUIP.HEQUIP_WUHUN)
    local visual,item=require('cys_wuhun_appearance').visual(w and w:get_index(),w and w:get_equip_data():get_wh_hecheng_level(),
        self:get_attrib('wuhun_show_flag'),self:get_attrib('wuhun_yy_flag'),self:get_attrib('huanhun_qian_index'),self:get_attrib('huanhun_kun_index'),self.huanhun)
    self:set_game_flag_keys_visual(define.HUMAN_EQUIP.HEQUIP_WUHUN,{[define.WG_KEY_A]=item,[define.WG_KEY_B]=-1,[define.WG_KEY_C]=visual})
    return visual,item
end''')
  files[rel]=s.encode()
 rel='Game_2/Script/scripts/event/equip/huanhun.lua';s=(ROOT/rel).read_text(encoding='utf8')
 marker='-- CYS-WUHUN-APPEARANCE'
 if marker in s:s=s[:s.index(marker)]+'return huanhun\n'
 wrap=marker+'''\nlocal appearance=require 'cys_wuhun_appearance'
function huanhun:CysFill(id,side,soul)
 local h=self.scene:get_obj_by_id(id)
 if h and h:get_obj_type()=='human' then return appearance.slot(self,h,side,soul) end
end
for _,name in ipairs({'ActiveWg','LevelUpWg','GradeUpWg','SwitchYY','TakeOut','SetShowWuhun','OpenChangeWg','CysState'})do
 local original=huanhun[name]
 huanhun[name]=function(self,id,arg)return appearance.operate(self,id,name,arg,original)end
end
'''
 assert s.count('return huanhun')==1;s=s.replace('return huanhun',wrap+'return huanhun');files[rel]=s.encode()
 rel='GameServer/services/scene/scenecore.lua';s=(ROOT/rel).read_text(encoding='utf8')
 start=s.index('function scenecore:ask_wuhun_wg(');end=s.index('\nfunction ',start+10)
 body=s[start:end]
 a=body.index('        elseif ntype == 2 then');b=body.index('\n        end',a)
 body=body[:a]+'''        elseif ntype == 2 then
            -- CY's skill 3238 is not the GL soul-cast contract. Validate the
            -- same equip request, then use GL's authoritative slot operation.
            self.scriptenginer:call(888800,'CysFill',who,ask.qiankun,ask.huanhun_id)
            return'''+body[b:]
 s=s[:start]+body+s[end:];files[rel]=s.encode()
 rel='GameServer/services/login/logind.lua';s=(ROOT/rel).read_text(encoding='utf8')
 marker='        -- CYS-WUHUN-LOGIN'
 if marker not in s:
  anchor='        c.visuals[20] = 0';assert s.count(anchor)==1
  s=s.replace(anchor,'''        -- CYS-WUHUN-LOGIN: derive from saved equipment and unlock state, never a stale cached visual.
        local w=char.equip_list and char.equip_list['19']
        local a=char.attrib
        c.visuals[19],c.equips[19]=require('cys_wuhun_appearance').visual(w and w.item_index,w and w.wh_hecheng_level,
            a.wuhun_show_flag,a.wuhun_yy_flag,a.huanhun_qian_index,a.huanhun_kun_index,char.huanhun)
'''+anchor)
 files[rel]=s.encode()
 rel='configs/AllowableScriptFunc.txt';raw=(ROOT/rel).read_bytes()
 for method_name in ['SetShowWuhun','CysState']:
  key=('\t888800\t'+method_name).encode()
  if not any(x.rstrip(b'\r').endswith(key) for x in raw.split(b'\n')):
   ids=[int(x.split(b'\t')[0]) for x in raw.split(b'\n') if x.split(b'\t')[0].isdigit()]
   raw=raw.rstrip(b'\r\n')+b'\n'+str(max(ids)+1).encode()+key+b'\n'
 files[rel]=raw
 return files
def main():
 p=argparse.ArgumentParser();p.add_argument('--out',type=Path,required=True);p.add_argument('--apply',action='store_true');a=p.parse_args()
 files=changes();a.out.mkdir(parents=True,exist_ok=True);records=[]
 for rel,data in files.items():
  dst=a.out/rel;dst.parent.mkdir(parents=True,exist_ok=True);dst.write_bytes(data)
  if rel.endswith('.lua'):
   path='/mnt/'+dst.resolve().drive[0].lower()+dst.resolve().as_posix()[2:]
   subprocess.run(['wsl','-d','TLBB','-u','root','--','luac5.4','-p',path],check=True)
  old=ROOT/rel;records.append({'path':rel,'before':hashlib.sha256(old.read_bytes()).hexdigest() if old.exists() else None,'after':hashlib.sha256(data).hexdigest()})
 (a.out/'manifest.json').write_text(json.dumps(records,indent=2))
 if a.apply:
  active=subprocess.check_output(['wsl','-d','TLBB','-u','root','--','ss','-Htn','state','established'],text=True)
  assert not re.search(r':1573[34]\b',active),'Private clients connected'
  backup=ROOT/'backups'/('wuhun-appearance-'+datetime.datetime.now().strftime('%Y%m%d-%H%M%S'));backup.mkdir()
  for row in records:
   dst=ROOT/row['path'];assert (hashlib.sha256(dst.read_bytes()).hexdigest() if dst.exists() else None)==row['before']
   if dst.exists():target=backup/row['path'];target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(dst,target)
  shutil.copy2(a.out/'manifest.json',backup/'manifest.json')
  for rel,data in files.items():(ROOT/rel).write_bytes(data)
  print('Backup',backup)
 print('Prepared',len(files),'files; syntax PASS; applied',a.apply)
if __name__=='__main__':main()
