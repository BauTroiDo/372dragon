"""Guarded staging for raid, party rewards and advanced guild work."""
from pathlib import Path
import argparse, datetime, hashlib, json, shutil, subprocess
ROOT=Path(__file__).resolve().parents[2]
LIVE=Path('//wsl.localhost/TLBB/home/ubuntu/cys-test-20260913')
LOG=ROOT/'Build/Logs/2026-09-28-social-completion'
REL=['GameServer/services/world/worldcore.lua','GameServer/services/msgagent.lua',
     'GameServer/lualib/raid.lua','GameServer/services/scene/obj/monster.lua',
     'GameServer/services/scene/obj/human.lua','GameServer/lualib/script_base.lua',
     'GameServer/services/guild/guildmanager_core.lua','GameServer/msgagent_module/ma_guild.lua',
     'Game_2/Script/scripts/event/team.lua',
     'Game_2/Script/scripts/obj/city/pc_guilddirector.lua',
     'Game_2/Script/scripts/obj/city/pc_industrialofficer.lua',
     'Game_2/Script/scripts/city0_LevelUp.lua','Game_2/Script/scripts/city0_Research.lua']
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest() if p.exists() else None
def baseline():
    LOG.mkdir(parents=True,exist_ok=True)
    for rel in REL:
        p=LOG/'baseline'/rel
        if not p.exists():p.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(LIVE/rel,p)
def replace(s,a,b):
    assert s.count(a)==1,a
    return s.replace(a,b)
def plan():
    baseline();files={}
    for p in sorted(Path(__file__).with_name('social_lua').glob('*.lua')):
        files['GameServer/lualib/'+p.name]=p.read_text(encoding='utf8')
    rel=REL[0];s=(LOG/'baseline'/rel).read_text(encoding='utf8')
    files[rel]=replace(s,"return require('cys_party').install(worldcore)","return require('cys_social_world').install(require('cys_party').install(worldcore))")
    rel=REL[1];s=(LOG/'baseline'/rel).read_text(encoding='utf8')
    # Never trust the acting GUID supplied by a raid client.
    for method,field in [('CGRaidApply','m_SourGUID'),('CGRaidInvite','m_SourObjID'),
                         ('CGRaidModifyMemberPosition','m_OperateGUID'),('CGRaidKick','m_OperateGUID'),
                         ('CGRaidAppoint','m_OperateGUID'),('CGRaidCreate','m_CreateGUID'),('CGRaidLeave','guid')]:
        needle='function request:'+method+'()'
        s=replace(s,needle,needle+'\n    self.'+field+' = ma_func:get_guid()')
    files[rel]=s
    # Invalid/stale social packets must produce an empty response, not crash the agent.
    rel=REL[7];s=(LOG/'baseline'/rel).read_text(encoding='utf8')
    s=replace(s,'for k, v in pairs(list) do','for k, v in pairs(list or {league_id=-1,guilds={}}) do')
    s=replace(s,'local guilds = info.guilds','info = info or {league_id=-1,chief_guid=-1,founded_time=0,member_count=0,name="",desc="",creator="",chief_name="",guilds={}}\n    local guilds = info.guilds')
    s=replace(s,'self:notify_tips("开出同盟成功")','self:CGWGuildLeagueInfo({})')
    # Reply after completion; a client refresh sent alongside the request may race an RPC.
    for method,next_method in [('CGCreateGuildLeague','CGWGuildLeagueMemberApplyList'),('CGWGuildLeagueQuit','CGWGuildLeagueAnswerEnter'),('CGWGuildLeagueAnswerEnter','CGWGuildLeagueAskEnter')]:
        a=s.index('function ma_guild:'+method+'(');b=s.index('function ma_guild:'+next_method+'(',a)
        block=s[a:b];i=block.rfind('\nend');block=block[:i]+'\n    self:CGWGuildLeagueInfo({})'+block[i:];s=s[:a]+block+s[b:]
    files[rel]=s
    rel=REL[1];s=files[rel]
    s=replace(s,'local kick_guild_id = self.data[3]','local kick_guild_id = (self.data[3] or 0) + 256 * (self.data[4] or 0)')
    s=replace(s,'local msg = packet_def.GCWGCPacket.new()\n        msg.type = 4','if not guild or not zhengtao_info then return end\n        local msg = packet_def.GCWGCPacket.new()\n        msg.type = 4')
    s=replace(s,'function request:CGCGWPacket()\n    local my_guid = ma_func:get_guid()', '''function request:CGCGWPacket()
    local my_guid = ma_func:get_guid()
    local function refresh_war_list(subtype)
        local id = skynet.call(my_scene, "lua", "get_obj_guild_id", my_obj_id)
        local g, list = skynet.call(".Guildmanager", "lua", "guild_zhengtao", my_guid, {guild_id=id,args={0,0,6+subtype}})
        if not g or not list then return end
        local msg = packet_def.GCWGCPacket.new();msg.type=4;msg.wgc_guild=g;Net:send(msg)
        msg = packet_def.GCWGCPacket.new();msg.type=10;msg.wgc_zhengtao=list;Net:send(msg)
    end''')
    s=replace(s,'skynet.call(".Guildmanager", "lua", "guild_wild_war", my_guid, self.guild_wild_war)', 'skynet.call(".Guildmanager", "lua", "guild_wild_war", my_guid, self.guild_wild_war)\n        refresh_war_list(0)')
    s=replace(s,'skynet.call(".Guildmanager", "lua", "guild_war", my_guid, self.guild_war)', 'skynet.call(".Guildmanager", "lua", "guild_war", my_guid, self.guild_war)\n        refresh_war_list(self.guild_war.initiate_or_accept == 0 and 3 or 2)')
    files[rel]=s
    rel=REL[4];s=(LOG/'baseline'/rel).read_text(encoding='utf8')
    s=replace(s,'local sceneId = self.scene:get_id()\n\tlocal guid = self:get_guid()\n\traid_info:set_raid_id(msg.m_RaidID)',
        'local sceneId = self.scene:get_id()\n\tlocal guid = self:get_guid()\n\t-- A full roster replaces removed members and assistant roles.\n\traid_info:clean_up()\n\traid_info:set_raid_id(msg.m_RaidID)')
    a=s.index('function human:update_raid_info_by_raid_list(');b=s.index('\nfunction human:update_raid_info(',a)
    block=s[a:b].replace('if obj then','if obj and obj:get_guid() == mb.guid then')
    files[rel]=s[:a]+block+s[b:]
    rel=REL[6];s=(LOG/'baseline'/rel).read_text(encoding='utf8')
    s=replace(s,'[7] = "money",','[7] = "founded_money",')
    s=replace(s,'local MAX_GUILD_COUNT_IN_LEAGUE = 30','local MAX_GUILD_COUNT_IN_LEAGUE = 3')
    s=replace(s,"return require('cys_guild').installManager(guildmanager_core)","return require('cys_social_guild').install(require('cys_guild').installManager(guildmanager_core))")
    s=replace(s,'if self:is_guild_war_or_be_war_running(guild) then','if #(guild.war_list or {}) > 0 or #(guild.be_war_list or {}) > 0 then')
    s=s.replace('if war.scene_id then\n            war.remain_time = war.remain_time - delta_time\n        end','war.remain_time = (war.remain_time or 0) - delta_time')
    s=replace(s,'l.guild_count = #league.guilds','l.guild_count = self:get_league_guilds_member_count(league)')
    s=replace(s,'local league_info = {}\n    league_info.league_id = league.id','if not league then return nil end\n    local league_info = {}\n    league_info.league_id = league.id')
    s=replace(s,'guild_info.member_count = #guild.users',"guild_info.member_count = 0\n            for _,u in ipairs(guild.users or {}) do if (u.position or 0)>1 then guild_info.member_count=guild_info.member_count+1 end end")
    s=replace(s,'if league_guild.join_date then\n            local guild = self:get_guild_by_id(league_guild.id)','if league_guild.join_date and self:get_guild_by_id(league_guild.id) then\n            local guild = self:get_guild_by_id(league_guild.id)')
    s=replace(s,'updater.desc = string.match(updater.desc, "([^%z]+)")','updater.desc = string.match(updater.desc, "([^%z]+)") or ""')
    files[rel]=s
    rel=REL[3];s=(LOG/'baseline'/rel).read_text(encoding='utf8')
    s=replace(s,'function monster:caculate_owner_list()','function monster:caculate_owner_list()\n    self.owners = {}\n    local seen = {}')
    s=replace(s,'if n:get_obj_type() == "human" then\n            if n:get_guid() == occupant_guid then',
        'if n:get_obj_type() == "human" and not n:is_die() and not seen[n:get_guid()] then\n            seen[n:get_guid()] = true\n            if n:get_guid() == occupant_guid then')
    s=replace(s,'function monster:on_die_after()','function monster:on_die_after()\n    if self.cys_rewards_dispatched then return end\n    self.cys_rewards_dispatched = true')
    for fn in ['reset','respawn']:
        s=replace(s,'function monster:'+fn+'()','function monster:'+fn+'()\n    self.cys_rewards_dispatched = nil')
    s=replace(s,'scene_exp_rate = self:get_scene():get_scene_exp_rate()','local scene_exp_rate = self:get_scene():get_scene_exp_rate()')
    s=replace(s,'local exp_mode = 0\n        if team_leader then','local exp_mode = 0\n        local sharing_member = team_leader or owners[1]\n        if sharing_member then')
    s=replace(s,'local team_info = team_leader:get_team_info()\n            if team_info then','local team_info = sharing_member:get_team_info()\n            if team_info then')
    files[rel]=s
    rel=REL[5];s=(LOG/'baseline'/rel).read_text(encoding='utf8')
    s=replace(s,'"city_get_attr", human:get_guild_id(), Attr)','"city_get_attr", human:get_guild_id(), Attr, human:get_guid())')
    s=replace(s,'local followd_member = human:get_team_info():get_followed_member(index)\n    followd_member = self.scene:get_obj_by_guid(followd_member.guid)',
        'local followd_member = human:get_team_info():get_followed_member(index)\n    if not followd_member then return define.INVAILD_ID end\n    followd_member = self.scene:get_obj_by_guid(followd_member.guid)\n    if followd_member and followd_member:get_team_id() ~= human:get_team_id() then return define.INVAILD_ID end')
    s=replace(s,'return script_base',"return require('cys_social_city').install(script_base)")
    files[rel]=s
    rel=REL[9];s=(LOG/'baseline'/rel).read_text(encoding='utf8')
    s=s.replace('level >= 55 and level < 69','level >= 55 and level < 70').replace('level >= 70 and level < 84','level >= 70 and level < 85').replace('level >= 85 and level < 100','level >= 85 and level <= 200')
    s=replace(s,'if GuildMoney <= curMoney then','if GuildMoney < curMoney then')
    a=s.index('if GuildMoney < curMoney then');b=s.index('            self:BeginAddItem()',a)
    block=s[a:b].replace('self:DispatchMissionTips(selfId)','self:DispatchMissionTips(selfId)\n                return');s=s[:a]+block+s[b:]
    for name,value in [('CUR','curMoney'),('MAX','maxMoney')]:
        s=s.replace('ScriptGlobal.TICKET_ITEM_PARAM_'+name+'_MONEY_TYPE, '+value,value+', ScriptGlobal.TICKET_ITEM_PARAM_'+name+'_MONEY_TYPE')
    s=replace(s,'            self:BeginAddItem()\n            self:AddItem(self.g_TicketItemIdx, 1)',
        '            if self:CityChangeAttr(selfId, ScriptGlobal.GUILD_MONEY, -curMoney) ~= 1 then return end\n            self:BeginAddItem()\n            self:AddItem(self.g_TicketItemIdx, 1)')
    s=replace(s,'                self:AddItemListToHuman(selfId)\n                bagpos = self:GetBagPosByItemSn(selfId, self.g_TicketItemIdx)',
        '                if not self:AddItemListToHuman(selfId) then\n                    self:CityChangeAttr(selfId, ScriptGlobal.GUILD_MONEY, curMoney)\n                    return\n                end\n                bagpos = self:GetBagPosByItemSn(selfId, self.g_TicketItemIdx)')
    s=replace(s,'                self:CityChangeAttr(selfId, ScriptGlobal.GUILD_MONEY, (-1) * curMoney)\n','')
    s=replace(s,'            else\n                self:BeginEvent(self.script_id)\n                strText = "Hành trang đã đầy, không thể chấp nhận nhiệm vụ"',
        '            else\n                self:CityChangeAttr(selfId, ScriptGlobal.GUILD_MONEY, curMoney)\n                self:BeginEvent(self.script_id)\n                strText = "Hành trang đã đầy, không thể chấp nhận nhiệm vụ"')
    rewards='''                self:CityChangeAttr(selfId, ScriptGlobal.GUILD_CONTRIB_POINT, 50)
                self:CityChangeAttr(selfId, ScriptGlobal.GUILD_MONEY, TicketMoney * 0.9)
                self:AddMoney(selfId, TicketMoney * 0.1)
                self:AddExp(selfId, 20000)
'''
    s=replace(s,rewards,'')
    s=replace(s,'                else\n                    self:BeginEvent(self.script_id)\n                    strText = "Xóa Ngân phiếu thành công"',
        '                else\n'+rewards+'                    self:BeginEvent(self.script_id)\n                    strText = "Xóa Ngân phiếu thành công"')
    files[rel]=replace(s,'return pc_guilddirector',"return require('cys_social_npc').install(pc_guilddirector)")
    rel=REL[10];s=(LOG/'baseline'/rel).read_text(encoding='utf8')
    s=s.replace('Level >= 150 and Level <= 160','Level >= 150 and Level <= 200')
    s=replace(s,'self:CityChangeAttr(selfId, 6, -1)','if self:CityChangeAttr(selfId, 6, -1) ~= 1 then return end')
    files[rel]=replace(s,'return pc_industrialofficer',"return require('cys_social_npc').install(pc_industrialofficer)")
    rel=REL[8];s=(LOG/'baseline'/rel).read_text(encoding='utf8')
    s=s.replace('assert(false)', '-- Reject a stale follow request without crashing the scene.')
    s=replace(s,'function team:TransferFunc(selfId, newSceneId, posX, posY, minLevel, maxLevel)', 'function team:TransferFunc(selfId, newSceneId, posX, posY, minLevel, maxLevel)\n    local initiatingHuman = self.scene:get_obj_by_id(selfId)\n    if not initiatingHuman then return end')
    s=replace(s,'    if newSceneId == 2 then', '    if self.scene:get_obj_by_id(selfId) ~= initiatingHuman then return end\n    if newSceneId == 2 then')
    s=replace(s,'    for _, checkHumanId in pairs(humanList) do\n        local checkRet',
        '''    -- Pin object identity and party membership before validation can yield.
    local transferMembers = {}
    for _,id in ipairs(humanList) do
        local h = self.scene:get_obj_by_id(id)
        if not h then return end
        if transferMembers[id] then return end
        transferMembers[id] = {human=h,team=h:get_team_id(),follow=h:get_team_follow_flag()}
    end
    for _, checkHumanId in pairs(humanList) do
        local checkRet''')
    s=replace(s,'    local sceneId = self:get_scene_id()\n    if sceneId ~= newSceneId then',
        '''    for id,v in pairs(transferMembers) do
        if self.scene:get_obj_by_id(id) ~= v.human or v.human:get_team_id() ~= v.team or v.human:get_team_follow_flag() ~= v.follow or v.human:is_die() then
            self:NotifyFailTips(selfId, "Đội đã thay đổi trong lúc chuyển cảnh; hãy thử lại.")
            return
        end
    end
    local sceneId = self:get_scene_id()
    if sceneId ~= newSceneId then''')
    files[rel]=s
    # These original scripts debit money before calling the missing progress API.
    # Fail before accepting/deleting a mission or spending money until that API exists.
    for rel in REL[11:]:
        s=(LOG/'baseline'/rel).read_text(encoding='utf8');name=Path(rel).stem
        for method in ['CheckAccept','CheckSubmit','OnAccept']:
            signature='function '+name+':'+method+'(selfId)'
            s=replace(s,signature,signature+'\n    if type(self.CityIncProgress) ~= "function" then return 0 end')
        files[rel]=s
    rows=[]
    for rel,s in files.items():
        dst=LOG/'server'/rel;dst.parent.mkdir(parents=True,exist_ok=True);dst.write_bytes(s.encode('utf8'))
        rows.append({'path':rel,'before':sha(LIVE/rel),'after':sha(dst)})
    (LOG/'server/manifest.json').write_text(json.dumps(rows,indent=2))
    print('Staged',len(rows),'files. Live server unchanged.')
def apply():
    status=json.loads(subprocess.check_output(['wsl','-d','TLBB','-u','root','--','python3',
        '/mnt/c/TLBB/085/CY-Source/Tools/server/provision_test_wsl.py','status']))
    assert not any(s['running'] for s in status['services']),'Stop the private service first'
    rows=json.loads((LOG/'server/manifest.json').read_text())
    for r in rows:
        assert sha(LIVE/r['path'])==r['before'],r['path']
        assert sha(LOG/'server'/r['path'])==r['after'],r['path']
    backup=ROOT/'Build/backups/social-completion-server'/datetime.datetime.now().strftime('%Y%m%d-%H%M%S')
    for r in rows:
        p=LIVE/r['path'];src=LOG/'server'/r['path']
        if p.exists():b=backup/r['path'];b.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,b)
        p.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(src,p)
        assert sha(p)==r['after']
    (LOG/'server-apply.json').write_text(json.dumps({'backup':str(backup),'files':rows},indent=2))
    print('Applied private CY files; backup:',backup)
if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('mode',choices=['baseline','plan','apply']);a=p.parse_args()
    {'baseline':baseline,'plan':plan,'apply':apply}[a.mode]()
