"""Plan/apply bounded CY mail and GM fixes against a hashed private-server baseline."""
from pathlib import Path
import argparse,datetime,hashlib,json,shutil,subprocess
from inventory_integrity import function
ROOT=Path(__file__).resolve().parents[2]
LOG=ROOT/'Build/Logs/2026-10-01-runtime-fixes'
LIVE=Path('//wsl.localhost/TLBB/home/ubuntu/cys-test-20260913')
PAYLOAD=Path(__file__).with_suffix('')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def once(s,a,b):assert s.count(a)==1,(a,s.count(a));return s.replace(a,b)
def plan():
 applied=LOG/'server-applied.json';current=LOG/'server-manifest.json'
 if applied.exists() and current.exists() and sha(current)==json.loads(applied.read_text())['manifest']:
  shutil.copy2(current,LOG/'server-installed-manifest.json')
 files=['GameServer/lualib/GMCommand.lua','GameServer/lualib/cys_mail_guard.lua',
        'GameServer/services/msgagent.lua','GameServer/services/world/worldcore.lua','GameServer/services/scene/scenecore.lua']
 rows=[]
 for rel in files:
  src=LIVE/rel;base=LOG/'server-baseline'/rel
  if src.exists() and not base.exists():base.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(src,base)
  old=base.read_text(encoding='utf8') if base.exists() else ''
  if rel.endswith(('GMCommand.lua','cys_mail_guard.lua')):new=(PAYLOAD/Path(rel).name).read_text(encoding='utf8')
  elif rel.endswith('msgagent.lua'):
   new=function(old,'request:CGMail',change=lambda b:'''local cys_mail_guard = require "cys_mail_guard"
local cys_mail_admission = {}
function request:CGMail()
    local guid = ma_func:get_guid()
    if self.guid ~= guid then return end
    if not cys_mail_guard.accept(cys_mail_admission, self, skynet.now()/100) then return end
    self.source = ma_func:get_name()
    self.flag = define.MAIL_TYPE.MAIL_TYPE_NORMAL
    self.create_time = os.time()
    self.param_1,self.param_2,self.param_3,self.param_4,self.param_5 = nil,nil,nil,nil,nil
    skynet.send(".world", "lua", "send_player_mail", guid, self)
end''')
  elif rel.endswith('worldcore.lua'):
   new=once(old,'function worldcore:send_mail(mail)', '''-- Keep admission across reconnects; never throttle internal quest/system mail.
function worldcore:send_player_mail(guid, mail)
    if not self:find_user(guid) or type(mail) ~= "table" or mail.guid ~= guid then return false end
    local now = skynet.now()/100
    self.cys_mail_admission = self.cys_mail_admission or {}
    if not self.cys_mail_prune or now-self.cys_mail_prune >= 60 then
        for id,state in pairs(self.cys_mail_admission) do
            if now-(state.last or 0) >= 300 then self.cys_mail_admission[id]=nil end
        end
        self.cys_mail_prune=now
    end
    local state=self.cys_mail_admission[guid]
    if not state then state={};self.cys_mail_admission[guid]=state end
    if not require("cys_mail_guard").accept(state,mail,now) then return false end
    self:send_mail(mail)
    return true
end

function worldcore:send_mail(mail)''')
  else:
   new=once(old,'''            local env = skynet.getenv("env")
            if env == "local" or env == "debug" then
                GMCommand:process(obj, chat.Contex)
            end''','''            GMCommand:process(obj, chat.Contex)''')
   new=once(new,'function scenecore:is_can_go(start, target)', '''function scenecore:cys_gm_valid_destination(pos)
    if type(pos) ~= "table" or type(pos.x) ~= "number" or type(pos.y) ~= "number" or not self.map then return false end
    if self:move_blocked(nil,pos) then return false end
    -- GetPath(pos,pos) accepts even out-of-bounds points. Use the exact client
    -- triangle mesh already used to validate mount landings, including bounds.
    local mesh=require("cys_flight_nav").for_scene(self)
    return mesh ~= nil and mesh:walkable(pos.x,pos.y)
end

function scenecore:is_can_go(start, target)''')
   # GMs should not lose administrative chat merely because the character is below level 50.
   # Restrict replacement to the tell branch, leaving ordinary chat limits unchanged.
   start=new.index('    elseif chat.ChatType == define.ENUM_CHAT_TYPE.CHAT_TYPE_TELL then')
   end=new.index('    elseif chat.ChatType ==',start+10)
   part=new[start:end]
   part=once(part,'if scenecore:check_limit_chat(obj) then','if chat.TargetName ~= "GM" and scenecore:check_limit_chat(obj) then')
   new=new[:start]+part+new[end:]
  dst=LOG/'server'/rel;dst.parent.mkdir(parents=True,exist_ok=True);dst.write_text(new,encoding='utf8',newline='\n')
  rows.append(dict(path=rel,before=sha(base) if base.exists() else None,after=sha(dst)))
 (LOG/'server-manifest.json').write_text(json.dumps(rows,indent=2));print('Planned',len(rows),'private-server files')
def apply():
 state=json.loads(subprocess.check_output(['wsl','-d','TLBB','-u','root','--','python3','/mnt/c/TLBB/085/CY-Source/Tools/server/provision_test_wsl.py','status']))
 assert not next(s for s in state['services'] if s['name']=='Game')['running'],'Stop private Game before apply'
 rows=json.loads((LOG/'server-manifest.json').read_text())
 previous={};installed=LOG/'server-installed-manifest.json';applied=LOG/'server-applied.json'
 if installed.exists() and applied.exists():
  assert sha(installed)==json.loads(applied.read_text())['manifest']
  previous={r['path']:r['after'] for r in json.loads(installed.read_text())}
 for r in rows:
  p=LIVE/r['path'];assert (sha(p) if p.exists() else None) in (r['before'],r['after'],previous.get(r['path'])),r['path']
  assert sha(LOG/'server'/r['path'])==r['after']
 backup=LOG/'server-backup'/datetime.datetime.now().strftime('%Y%m%d-%H%M%S')
 for r in rows:
  p=LIVE/r['path'];b=backup/r['path']
  if p.exists():b.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,b)
  p.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(LOG/'server'/r['path'],p);assert sha(p)==r['after']
 (LOG/'server-applied.json').write_text(json.dumps(dict(backup=str(backup),manifest=sha(LOG/'server-manifest.json'))))
 print('Applied private server; backup',backup)
if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('mode',choices=['plan','apply']);a=p.parse_args()
 plan() if a.mode=='plan' else apply()
