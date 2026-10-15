"""Stage/apply only the private CY settings, relation and title fixes."""
from pathlib import Path
import argparse,datetime,hashlib,json,shutil,subprocess
ROOT=Path(__file__).resolve().parents[2]
SERVER=Path('//wsl.localhost/TLBB/home/ubuntu/cys-test-20260913')
LOG=ROOT/'Build/Logs/2026-09-28-settings-friends-titles'
def sha(b):return hashlib.sha256(b).hexdigest()
def source(rel):
 p=LOG/'baseline/server'/rel
 if not p.exists():p.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(SERVER/rel,p)
 return p.read_text(encoding='utf8')
def replace_function(s,name,body):
 start=s.index('function '+name+'(');end=s.find('\nfunction ',start+10)
 assert end>start,name
 return s[:start]+body.rstrip()+'\n'+s[end:]
def plan():
 files={'GameServer/lualib/cys_community.lua':Path(__file__).with_name('community_lua').joinpath('cys_community.lua').read_text(encoding='utf8')}
 rel='GameServer/msgagent_module/ma_relation.lua';s=source(rel);assert 'return ma_relation' in s
 files[rel]=s.replace('return ma_relation',"return require('cys_community').install(ma_relation)")
 rel='GameServer/services/world/worldcore.lua';s=source(rel)
 s=s.replace('assert(character, guid)','if not character then return nil end').replace('assert(character, name)','if not character then return nil end')
 needle='relation = character.relation\n';assert needle in s
 s=s.replace(needle,'relation = character.relation,\n            game_flags = (character.setting and character.setting["2"] or {}).data or 0\n')
 needle='    assert(inviter, guid)\n';assert needle in s
 s=s.replace(needle,'''    if not inviter then return end
    local target_info = skynet.call(accpter.uinfo.agent, "lua", "get_player_info")
    if target_info and ((target_info.game_flags or 0) & 8) ~= 0 and guid ~= accpter.uinfo.guid then
        local msg = packet_def.GCTeamError.new()
        msg.error_code = define.TEAM_RESULT.TEAM_ERROR_REFUSEINVITESETTING
        self:send2client(inviter, msg)
        return
    end
''',1)
 files[rel]=s
 rel='GameServer/services/msgagent.lua';s=source(rel)
 start=s.index('function CMD.get_player_info()');end=s.index('\nfunction ',start+10);body=s[start:end]
 body=body.replace('    local uinfo = {','    local setting = skynet.call(my_scene, "lua", "call_human_function", my_obj_id, "get_setting")\n    local uinfo = {').replace('        client_res = my_client_res,','        client_res = my_client_res,\n        game_flags = (setting and setting["2"] or {}).data or 0,')
 files[rel]=s[:start]+body+s[end:]
 rel='GameServer/services/scene/scenecore.lua';s=source(rel)
 s=replace_function(s,'scenecore:char_update_cur_title','''function scenecore:char_update_cur_title(who, uct)
    local h=self:get_obj_by_id(who)
    if not h or type(uct)~='table' then return end
    if uct.id==0 and uct.id_title_id==0 then
        h:set_current_title({id=0,str=''})
    elseif uct.id~=0 then
        h:set_cur_title_by_id(uct.id)
    else
        h:set_cur_title_by_id_title(uct.id_title_id)
    end
    h:update_titles_to_client()
end''')
 # Acknowledge settings so the UI reloads authoritative flags on every session.
 anchor='    all_setting[setting_key] = setting\n';assert anchor in s
 s=s.replace(anchor,anchor+'    if modify.type == define.SETTING_TYPE.SETTING_TYPE_GAME then obj_me:send_setting() end\n')
 files[rel]=s
 rel='GameServer/services/scene/obj/human.lua';s=source(rel)
 s=replace_function(s,'human:add_id_title','''function human:add_id_title(id)
    local config=configenginer:get_config('char_title_new')
    if not config or not config[id] or self:have_id_title(id) then return false end
    self:del_conflict_titles(id)
    table.insert(self.id_titles,{id=id})
    self.db:mark_all_attr_dirty()
    self:set_cur_title_by_id_title(id)
    self:update_titles_to_client()
    return true
end''')
 s=replace_function(s,'human:set_title','''function human:set_title(id,titlestr)
    if id==define.INVAILD_ID or type(titlestr)~='string' then return false end
    for _,title in ipairs(self.titles)do
        if title.id==id then title.str=titlestr;self:set_current_title(title);self:update_titles_to_client();return true end
    end
    local title={id=id,str=titlestr}
    table.insert(self.titles,title)
    self:set_current_title(title)
    self:update_titles_to_client()
    return true
end''')
 s=s.replace('        char_title_new = char_title_new[id]\n        local title', '        char_title_new = char_title_new and char_title_new[id]\n        if not char_title_new then return false end\n        local title')
 files[rel]=s
 rel='GameServer/lualib/db/human_attrib.lua';s=source(rel)
 s=s.replace('local config = char_title_new[id]\n        for i = 1, 6 do', 'local config = char_title_new and char_title_new[id]\n        for i = 1, config and 6 or 0 do')
 files[rel]=s
 rows=[]
 for rel,s in files.items():
  b=s.encode('utf8');p=LOG/'server'/rel;p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(b)
  live=SERVER/rel;rows.append({'path':rel,'before':sha(live.read_bytes())if live.exists()else None,'after':sha(b)})
 (LOG/'server/manifest.json').write_text(json.dumps(rows,indent=2))
 print('Staged',len(rows),'server files')
def apply():
 status=json.loads(subprocess.check_output(['wsl','-d','TLBB','-u','root','--','python3','/mnt/c/TLBB/085/CY-Source/Tools/server/provision_test_wsl.py','status']))
 assert not any(s['running']for s in status['services']),'Stop private server before applying'
 rows=json.loads((LOG/'server/manifest.json').read_text());backup=ROOT/'Build/backups/community-server'/datetime.datetime.now().strftime('%Y%m%d-%H%M%S')
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
