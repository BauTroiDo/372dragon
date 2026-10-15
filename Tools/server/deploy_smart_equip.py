"""Fix paired-slot selection and reply identities on the private server only."""
from pathlib import Path
import datetime,hashlib,json,re,shutil,subprocess,sys
from deploy_power import method
ROOT=Path(__file__).resolve().parents[2]
LIVE=Path('//wsl.localhost/TLBB/home/ubuntu/cys-test-20260913')
OUT=ROOT/'Build/Logs/2026-09-25-smart-equip/server'
REL='GameServer/services/scene/scenecore.lua'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def patch(s):
 def replace(a,b):
  nonlocal s
  assert s.count(a)==1,(a[:100],s.count(a));s=s.replace(a,b)
 start=s.index('function scenecore:ring_or_amulet_select_slot(');end=s.index('\nfunction ',start+10)
 s=s[:start]+'''function scenecore:ring_or_amulet_select_slot(equip_container, slots)
    -- Empty slots first, stable first slot when both are occupied. table.sort's
    -- comparator must return a boolean; the old numeric return corrupted this.
    for _,point in ipairs(slots) do
        if not equip_container:get_item(point) then return point end
    end
    return slots[1]
end
\n'''+s[end:]
 start=s.index('function scenecore:char_use_bag_equip(');end=s.index('\nfunction ',start+10)
 part=s[start:end]
 a='\tlocal equip = equip_container:get_item(equipPoint)'
 assert part.count(a)==1
 part=part.replace(a,'''    if equipPoint == define.HUMAN_EQUIP.HEQUIP_RING_1 then
        equipPoint = self:ring_or_amulet_select_slot(equip_container, {define.HUMAN_EQUIP.HEQUIP_RING_1,define.HUMAN_EQUIP.HEQUIP_RING_2})
    elseif equipPoint == define.HUMAN_EQUIP.HEQUIP_AMULET_1 then
        equipPoint = self:ring_or_amulet_select_slot(equip_container, {define.HUMAN_EQUIP.HEQUIP_AMULET_1,define.HUMAN_EQUIP.HEQUIP_AMULET_2})
    end
    ret.equipPoint = equipPoint
'''+a)
 a=part.index('\t\telseif equipPoint == define.HUMAN_EQUIP.HEQUIP_RING_1 then')
 b=part.index('\n\t\tend',a)
 part=part[:a]+part[b:]
 s=s[:start]+part+s[end:]
 start=s.index('function scenecore:char_use_equip(');end=s.index('\nfunction ',start+10)
 part=s[start:end];anchor='    self:send2client(obj_me, ret)';assert part.count(anchor)==1
 part=part.replace(anchor,'    equipPoint = ret.equipPoint -- use the authoritative destination throughout notifications\n'+anchor)
 return s[:start]+part+s[end:]
def main():
 previous={r['path']:r['after'] for r in json.loads((OUT/'manifest.json').read_text())} if (OUT/'manifest.json').exists() else {}
 OUT.mkdir(parents=True,exist_ok=True);baseline=OUT/'before.lua'
 if not baseline.exists():shutil.copy2(LIVE/REL,baseline)
 data=patch(baseline.read_text(encoding='utf8')).encode();target=OUT/'scenecore.lua';target.write_bytes(data)
 subprocess.run(['wsl','-d','TLBB','-u','root','--','luac5.4','-p','/mnt/c'+target.as_posix()[2:]],check=True)
 files={REL:(baseline,target)}
 for name in ['GameServer/services/scene/obj/human.lua','GameServer/services/scene/human.lua']:
  before=OUT/'baseline'/name;after=OUT/name
  if not before.exists():before.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(LIVE/name,before)
  s=before.read_text(encoding='utf8');start=s.index('function human:send_mission_list()');end=s.index('\nfunction ',start+10)
  part=s[start:end];anchor='    self:get_scene():send2client(self, msg)';assert part.count(anchor)==1
  part=part.replace(anchor,anchor+'''
    -- CYS: the fixed 200-slot list does not include combat MD602/603.
    -- Resend authoritative totals on login and every scene list refresh.
    self:set_mission_data_by_script_id(602,self.db:get_chuanci())
    self:set_mission_data_by_script_id(603,self.db:get_fangchuan())
    require('cys_shending').sync(self)''')
  after.parent.mkdir(parents=True,exist_ok=True);after.write_text(s[:start]+part+s[end:],encoding='utf8')
  subprocess.run(['wsl','-d','TLBB','-u','root','--','luac5.4','-p','/mnt/c'+after.as_posix()[2:]],check=True)
  files[name]=(before,after)
 name='GameServer/lualib/cys_shending.lua';before=OUT/'baseline'/name;after=OUT/name
 if not before.exists():before.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(LIVE/name,before)
 after.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(Path(__file__).parent/'cys_shending.lua',after)
 subprocess.run(['wsl','-d','TLBB','-u','root','--','luac5.4','-p','/mnt/c'+after.as_posix()[2:]],check=True)
 files[name]=(before,after)
 report=[{'path':name,'before':sha(before),'after':sha(after)} for name,(before,after) in files.items()]
 if '--apply' in sys.argv:
  active=subprocess.check_output(['wsl','-d','TLBB','-u','root','--','ss','-Htn','state','established'],text=True)
  assert not re.search(r':1573[34]\b',active),'Private client connected'
  for r in report:assert sha(LIVE/r['path']) in [r['before'],r['after'],previous.get(r['path'])],r['path']
  backup=LIVE/'backups'/('smart-equip-'+datetime.datetime.now().strftime('%Y%m%d-%H%M%S'))
  for r in report:
   if sha(LIVE/r['path'])==r['after']:continue
   saved=backup/r['path'];saved.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(LIVE/r['path'],saved)
   shutil.copy2(files[r['path']][1],LIVE/r['path']);r['backup']=str(saved)
 (OUT/'manifest.json').write_text(json.dumps(report,indent=2));print('PASS syntax; applied','--apply' in sys.argv)
if __name__=='__main__':main()
