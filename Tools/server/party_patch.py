"""Stage guarded party/guild fixes; apply only to the stopped private CY service."""
from pathlib import Path
import argparse,datetime,hashlib,json,shutil,subprocess
ROOT=Path(__file__).resolve().parents[2]
SERVER=Path('//wsl.localhost/TLBB/home/ubuntu/cys-test-20260913')
LOG=ROOT/'Build/Logs/2026-09-28-party-guild'
def sha(b):return hashlib.sha256(b).hexdigest()
def source(rel):return (LOG/'baseline/server'/rel).read_text(encoding='utf8')
def plan():
 files={}
 for name in ['cys_party','cys_guild']:files[f'GameServer/lualib/{name}.lua']=Path(__file__).with_name('party_lua').joinpath(name+'.lua').read_text(encoding='utf8')
 for rel,name,installer in [('services/world/worldcore.lua','worldcore',"require('cys_party').install"),('services/guild/guildmanager_core.lua','guildmanager_core',"require('cys_guild').installManager"),('msgagent_module/ma_guild.lua','ma_guild',"require('cys_guild').installAgent"),('services/scene/obj/human.lua','human',"require('cys_guild').installHuman")]:
  s=source(rel);needle='return '+name;assert s.rstrip().endswith(needle),rel
  s=s[:s.rfind(needle)]+'return '+installer+'('+name+')\n'
  if name=='guildmanager_core':
   needle='    -- local appoint_infos = {}';assert s.count(needle)==1
   s=s.replace(needle,'    local appoint_infos = {}')
   needle='        l.user_count = #guild.users';assert s.count(needle)==1
   s=s.replace(needle,'        l.user_count = 0; for _,u in ipairs(guild.users)do if u.position>1 then l.user_count=l.user_count+1 end end')
  if name=='human':
   start=s.index('function human:update_team_info_by_team_list(');end=s.index('\nfunction ',start+10)
   s=s[:start]+'''function human:update_team_info_by_team_list(msg)
    local t=self:get_team_info()
    if not t then return end
    if msg.member_size==0 then
        t:clean_up()
        self:send_refresh_attrib()
        return true
    end
    -- A roster is a replacement, not an append: removed members cannot keep EXP/follow privileges.
    local leader=msg.leader_guid or msg.member_list[1].guid
    local keep=t:get_team_id()==msg.team_id and t:get_team_leader()==leader
    if not keep then t:clean_up()end
    t.members={};t.scene_members={}
    t:set_my_guid(self:get_guid());t:set_my_scene_id(self.scene:get_id())
    for _,m in ipairs(msg.member_list)do t:add_member(m)end
    t:set_team_id(msg.team_id);t:set_team_leader(leader);t:set_exp_mode(msg.exp_mode)
    self:send_refresh_attrib()
    return true
end
'''+s[end:]
  files['GameServer/'+rel]=s
 # The manager otherwise mistakes a successful online update for an offline character.
 rel='services/msgagent.lua';s=source(rel)
 needle='function request:CGGuildApply()\n    ma_func:CGGuildApply(self)\nend';assert s.count(needle)==1
 s=s.replace(needle,'function request:CGGuildApply()\n    ma_func:CGGuildApply(self)\n    subscribe_guild_multicast(ma_func:get_guild_id())\nend')
 needle='    ma_func:CGGuild(guild_request)\nend\n';assert s.count(needle)==1
 s=s.replace(needle,'    if data.guild_id ~= -1 then ma_func:CGGuild(guild_request) end\n    return true\nend\n')
 files['GameServer/'+rel]=s
 rows=[]
 previous=LOG/'server/manifest.json'
 if previous.exists():
  for row in json.loads(previous.read_text()):
   current=SERVER/row['path'];digest=sha(current.read_bytes())if current.exists()else None
   assert digest in [row['before'],row['after']], 'Live server changed outside this plan: '+row['path']
 for rel,s in files.items():
  p=LOG/'server'/rel;p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(s.encode('utf8'))
  live=SERVER/rel;rows.append({'path':rel,'before':sha(live.read_bytes())if live.exists()else None,'after':sha(p.read_bytes())})
 (LOG/'server/manifest.json').write_text(json.dumps(rows,indent=2))
 print('Staged',len(rows),'private server sources')
def apply():
 status=json.loads(subprocess.check_output(['wsl','-d','TLBB','-u','root','--','python3','/mnt/c/TLBB/085/CY-Source/Tools/server/provision_test_wsl.py','status']))
 assert not any(s['running']for s in status['services']),'Stop private server before applying'
 rows=json.loads((LOG/'server/manifest.json').read_text());backup=ROOT/'Build/backups/party-guild-server'/datetime.datetime.now().strftime('%Y%m%d-%H%M%S')
 for r in rows:
  p=SERVER/r['path'];assert (sha(p.read_bytes())if p.exists()else None)==r['before'],r['path']
  assert sha((LOG/'server'/r['path']).read_bytes())==r['after']
 for r in rows:
  p=SERVER/r['path']
  if p.exists():b=backup/r['path'];b.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,b)
  p.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(LOG/'server'/r['path'],p)
  assert sha(p.read_bytes())==r['after']
 (LOG/'server-apply.json').write_text(json.dumps({'backup':str(backup),'files':rows},indent=2));print('Applied private CY only',backup)
if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('mode',choices=['plan','apply']);a=p.parse_args();plan()if a.mode=='plan'else apply()
