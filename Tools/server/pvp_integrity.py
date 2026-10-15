"""Stage/apply bounded PvP repairs to the private clone, with exact backups."""
from pathlib import Path
import argparse, datetime, hashlib, json, re
from inventory_integrity import function
ROOT=Path(__file__).resolve().parents[2]
R=Path('//wsl.localhost/TLBB/home/ubuntu/cys-test-20260913')
OWN=Path(__file__).with_name('pvp_integrity_lua')
CY=Path('C:/TLBB/085/Tools/DATA NEW/DataCY31-08-26')
TRAITS=[0,1,2,3,4,5,6,7,8,9,16,17,18,19,20,15]
FILES=['GameServer/lualib/cy_pvp.lua','GameServer/services/scene/obj/human.lua',
       'GameServer/services/scene/scenecore.lua','GameServer/services/scene/skill/combat_core.lua',
       'Game_2/Script/scripts/event/challenge/eluoyang_challenge.lua','configs/AttackTraits.txt','configs/BaseValueTable.ini',
       'GameServer/services/scene/skill/base.lua','GameServer/services/scene/skill/impact_logic/std_impact_114.lua']

def base_values(raw):
    values={};section=None
    for line in raw.decode('gbk').splitlines():
        match=re.match(r'\[MENPAI(\d+)\]',line)
        if match:section=int(match[1]);values[section]={}
        match=re.match(r'AINFOTYPE(\d+)\s*=\s*(-?\d+)',line)
        if match and section is not None:values[section][int(match[1])]=int(match[2])
    return values
def transform(rel,raw):
    if rel.endswith('/cy_pvp.lua'):return (OWN/'cy_pvp.lua').read_bytes()
    if rel=='configs/BaseValueTable.ini':
        reference=base_values((CY/'tlbb15/Server/Config/BaseValueTable.ini').read_bytes())
        section=None;out=[];seen=set()
        for line in raw.decode('gbk').splitlines(True):
            match=re.match(r'\[MENPAI(\d+)\]',line)
            if match:section=int(match[1])
            match=re.match(r'(AINFOTYPE(\d+)\s*=\s*)(-?\d+)',line)
            if match and section is not None and section<16:
                key=int(match[2])
                if key<40 or key==41:
                    seen.add((section,key));value=TRAITS[section] if key==41 else reference[section][key]
                    line=line[:match.start(3)]+str(value)+line[match.end(3):]
            out.append(line)
        assert len(seen)==16*41,'BaseValueTable playable school schema changed'
        return ''.join(out).encode('gbk')
    if rel=='configs/AttackTraits.txt':
        rows=raw.decode('gbk').splitlines(True)
        for i,row in enumerate(rows):
            cells=row.rstrip('\r\n').split('\t')
            if cells[0]=='2':
                assert cells[1]=='丐帮' and int(cells[8]) in (1300000,1400000)
                cells[8]='1300000';rows[i]='\t'.join(cells)+'\n'
        return ''.join(rows).encode('gbk')
    s=raw.decode('utf8').replace('\r\n','\n')
    if rel.endswith('/std_impact_114.lua'):
        return (ROOT/'Tools/server/server_impact_lua'/rel).read_bytes()
    if rel.endswith('/skill/base.lua'):
        for name,rate in [('is_hit','accuracy'),('is_critical_hit','critical_rate')]:
            def normalize(b,rate=rate):
                if '-- CYS-PVP percentage' in b:return b
                anchor='    end\n    -- skynet.error' if rate=='accuracy' else '    end\n    local rand'
                assert anchor in b
                return b.replace(anchor, '    else\n        -- CYS-PVP percentage: table and fixed buff rates are 0..100; -1 uses derived ratio.\n        '+rate+' = '+rate+' / 100\n'+anchor,1)
            s=function(s,'skill:'+name,change=normalize)
    elif rel.endswith('/human.lua'):
        s=function(s,'human:get_attack_traits_type','''function human:get_attack_traits_type()
    return require('cy_pvp').trait(self:get_menpai())
end''')
        def mode(b):
            if '-- CYS-PVP mode' not in b:b=b.replace('\n',"\n    -- CYS-PVP mode: reject malformed/unsupported modes before DB writes.\n    if not require('cy_pvp').mode(mode) then return false end\n",1)
            return b
        s=function(s,'human:change_pk_mode',change=mode)
        s=function(s,'human:check_pk_mode_can_change',change=lambda b:b.replace('local change_pk_mode_delay = self.db:get_db_attrib("change_pk_mode_delay")\n','local change_pk_mode_delay = self.db:get_db_attrib("change_pk_mode_delay") or define.PK_MODE_CHANGE_DELAY\n').replace('if change_pk_mode_delay < 0 then','if change_pk_mode_delay <= 0 then'))
        def enemy(b):
            b=b.replace('if self:is_in_pk_declaration_list(other) then','if (rule & 8) ~= 0 and self:is_in_pk_declaration_list(other) then')
            b=b.replace('if other:is_in_pk_declaration_list(self) then','if (rule & 8) ~= 0 and other:is_in_pk_declaration_list(self) then')
            if '-- CYS-PVP scene permission' in b:return b
            b=b.replace('    if other:get_level() < self.db:get_attrib("pk_min_level") then', '''    -- CYS-PVP scene permission: safe zones and level protection apply to both sides.
    local rule = self.db:get_attrib('pvp_rule') or 0
    local minimum = math.max(self.db:get_attrib('pk_min_level') or 10000, other.db:get_attrib('pk_min_level') or 10000)
    if (rule & 14) == 0 or self:get_level() < minimum or other:get_level() < minimum then''')
            b=b.replace('    if self:is_enemy_camp(other) then', '    if (rule & 4) ~= 0 and self:is_enemy_camp(other) then')
            b=b.replace('    local pk_mode =', "    if (rule & 2) == 0 then return false end\n    local pk_mode =")
            return b
        s=function(s,'human:is_enemy_human',change=enemy)
    elif rel.endswith('/combat_core.lua'):
        s=s.replace('local result = rand < accuracy * 100','local result = rand <= accuracy * 100')
        s=function(s,'combat_core:magic_damage',change=lambda b:b.replace('IATTRIBUTE_IMMUNITY_P','IATTRIBUTE_IMMUNITY_M'))
        s=re.sub(r'\t\tif atype >= 10 and not \(define.MENPAI_ATTACK_TRAITS or \{\}\)\[menpai\] then\n.*?\n\t\tend', '\t\t-- CYS-PVP: human:get_attack_traits_type already resolves CY identities.',s,flags=re.S)
    elif rel.endswith('/scenecore.lua'):
        s=function(s,'scenecore:char_challenge', '''function scenecore:char_challenge(who, ch)
    return require('cy_pvp').challenge(self, who, ch)
end''')
        s=function(s,'scenecore:get_team_challenge_members',change=lambda b:b.replace('if n:get_team_id() == obj:get_team_id() and n ~= obj then', '''if #near_team_members < 6 and n:get_team_id() == obj:get_team_id() and n ~= obj
                and n:is_alive() and n:get_mission_data_by_script_id(define.MD_ENUM.MD_TIAOZHAN_SCRIPT)
                    == obj:get_mission_data_by_script_id(define.MD_ENUM.MD_TIAOZHAN_SCRIPT) then'''))
    elif rel.endswith('/eluoyang_challenge.lua'):
        # CY 3.71 uses luoyang_new; old (91,185) is inside blocked terrain.
        s=s.replace('leitai.g_BackPos = { sceneId=0, x=91, z=185 }','leitai.g_BackPos = { sceneId=0, x=180, z=328 }')
        for side,slot in [('Self',6),('Target',7)]:
            s=function(s,f'leitai:Get{side}TeamId',f'''function leitai:Get{side}TeamId()
    local value = self:LuaFnGetCopySceneData_Param({slot}) / 10
    return value < 0 and math.ceil(value) or math.floor(value)
end''')
            s=function(s,f'leitai:Get{side}MembersCount',f'''function leitai:Get{side}MembersCount()
    return math.abs(self:LuaFnGetCopySceneData_Param({slot})) % 10
end''')
        s=function(s,'leitai:OnCopySceneReady',change=lambda b: re.sub(r'\t-- 将符合传送条件的玩家组合起来.*?\n\tfor _, member in ipairs\(members\) do', '''\t-- CYS-PVP: only unique, living teammates on the same challenge platform.
    local seen = {}
    for _, leader in ipairs({selfId,targetId}) do
        local obj = self.scene:get_obj_by_id(leader)
        if not obj then return end
        for _, member in ipairs(self.scene:get_team_challenge_members(obj)) do
            local id=member:get_obj_id()
            if not seen[id] then seen[id]=true;members[#members+1]=id end
        end
    end
\tfor _, member in ipairs(members) do''',b,flags=re.S))
        def ready(b):
            if '-- CYS-PVP allocator' not in b:
                b=b.replace('\tlocal members = {}', '''    -- CYS-PVP allocator yields: revalidate before team lookup or transfer.
    if not require('cy_pvp').ready(self.scene, self.scene:get_obj_by_id(selfId), self.scene:get_obj_by_id(targetId)) then return end
\tlocal members = {}''')
            return b
        s=function(s,'leitai:OnCopySceneReady',change=ready)
        s=function(s,'leitai:OnPlayerLeave',change=lambda b:b if '-- CYS-PVP leave' in b else b.replace('\n', '\n    -- CYS-PVP leave: clear arena camp even on death/teleport/logout exits.\n    self:SetUnitCampID(selfId, -1)\n',1))
    return s.encode('utf8')

def main():
    p=argparse.ArgumentParser();p.add_argument('--apply',action='store_true');p.add_argument('--stage',type=Path,default=ROOT/'Build/Logs/2026-09-22-pvp-audit/staged');a=p.parse_args()
    assert R.name=='cys-test-20260913'
    backup=ROOT/'Build/backups/pvp'/datetime.datetime.now().strftime('%Y%m%d-%H%M%S');result=[];jobs=[]
    for rel in FILES:
        source=R/rel;before=source.read_bytes() if source.exists() else b'';after=transform(rel,before)
        assert transform(rel,after)==after, 'non-idempotent '+rel
        jobs.append((rel,before,after))
    # Validate every input and create every backup before changing any runtime file.
    if a.apply:
        for rel,before,after in jobs:
            if before!=after:
                b=backup/rel;b.parent.mkdir(parents=True,exist_ok=True);b.write_bytes(before)
    for rel,before,after in jobs:
        dest=(R if a.apply else a.stage)/rel
        dest.parent.mkdir(parents=True,exist_ok=True)
        if not dest.exists() or dest.read_bytes()!=after:dest.write_bytes(after)
        result.append({'path':rel,'changed':before!=after,'sha256':hashlib.sha256(after).hexdigest()})
    print(json.dumps({'apply':a.apply,'backup':str(backup) if a.apply else None,'files':result},indent=2))
if __name__=='__main__':main()
