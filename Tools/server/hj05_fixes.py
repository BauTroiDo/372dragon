"""Hash-guarded HJ05 integration layer. Runtime: private CY only; apply last."""
from pathlib import Path
import argparse, datetime, hashlib, json, shutil, subprocess
from inventory_integrity import function
ROOT=Path(__file__).resolve().parents[2]
LIVE=Path('//wsl.localhost/TLBB/home/ubuntu/cys-test-20260913')
LOG=ROOT/'Build/Logs/2026-09-28-hj05-fixes'
OWN=Path(__file__).with_name('hj05_lua')
RELS=['GameServer/lualib/item.lua','GameServer/lualib/pet_attrib.lua',
    'GameServer/lualib/db/pet_attrib.lua','GameServer/lualib/eventenginer.lua',
    'GameServer/services/scene/obj/human.lua','GameServer/services/scene/obj/character.lua',
    'Game_2/Script/scripts/event/huodong/echangeusername.lua',
    'GameServer/services/scene/skill/impact_logic/std_impact_101.lua',
    'GameServer/services/scene/ai/human.lua','GameServer/services/scene/scenecore.lua',
    'GameServer/lualib/script_base.lua','GameServer/services/game/packet_types/item_types.lua']
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest() if p.exists() else None
def replace(s,a,b):
    assert s.count(a)==1,(a,s.count(a))
    return s.replace(a,b)

def plan():
    files={}
    for rel in RELS:
        backup=LOG/'baseline'/rel
        if not backup.exists():
            backup.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(LIVE/rel,backup)
        s=backup.read_text(encoding='utf8')
        if rel.endswith('/packet_types/item_types.lua'):
            s=replace(s,'''                    stream:writechar(self.pet_soul_attr[i].type)
                    stream:writeuint(self.pet_soul_attr[i].value)''','''                    -- Same empty-slot encoding as pet_equip_data:get_transfer.
                    -- Newly created/unwashed souls may have fewer than six rows.
                    local attr = self.pet_soul_attr and self.pet_soul_attr[i]
                    stream:writechar(attr and attr.type or define.INVAILD_ID)
                    stream:writeuint(attr and attr.value or 0)''')
        elif rel.endswith('/scenecore.lua'):
            s=function(s,'scenecore:char_pet_bank_add_pet','''function scenecore:char_pet_bank_add_pet(who, request)
    return require('cys_pet_bank').handle(self, who, request)
end''')
        elif rel.endswith('/script_base.lua'):
            s=function(s,'script_base:PetBankBegin',change=lambda b:replace(b,
                '    local msg = packet_def.GCBankBegin.new()',
                "    require('cys_pet_bank').open(self.scene,human,targetId)\n    local msg = packet_def.GCBankBegin.new()"))
        elif rel.endswith('/item.lua'):
            s=function(s,'pet_equip_data:init_from_data',change=lambda b:replace(b,
                '    self:set_pet_equip_type(data.pet_equip_type)',
                '''    -- HJ05: 0 is valid exhausted life; absent legacy fields keep 300.
    local life = tonumber(data.pet_equip_unknow_8)
    if life and life == life and life >= 0 and life <= 65535 then
        self.pet_equip_unknow_8 = math.floor(life)
    end
    self:set_pet_equip_type(data.pet_equip_type)'''))
            for method,old in [('get_transfer','os:writeushort(300)'),('get_stream','os:writeuint(300)')]:
                s=function(s,'pet_equip_data:'+method,change=lambda b,o=old:replace(b,o,o.replace('300','self.pet_equip_unknow_8')))
        elif rel.endswith('/pet_attrib.lua'):
            s=function(s,'pet_attrib:item_effect_flush',change=lambda b:replace(b,
                'self:cal_item_effect(ia, iv, i, item_type)',
                'self:cal_item_effect(ia, iv + require("cys_pet_equipment").quality_bonus(raw_data, ia, iv), i, item_type)'))
        elif rel.endswith('/eventenginer.lua'):
            s=replace(s,'function eventenginer:real_register_skill_miss_event(sender, reciver, skill_id)',
                'function eventenginer:real_register_skill_miss_event(sender, reciver, skill_id, cast_token)')
            s=replace(s,'sender:on_skill_miss_target(reciver, skill_id)','sender:on_skill_miss_target(reciver, skill_id, cast_token)')
            s=replace(s,'ret.sender_logic_count = sender:get_logic_count()','ret.sender_logic_count = cast_token')
            s=replace(s,'function eventenginer:register_skill_miss_event(sender, reciver, skill_id)',
                'function eventenginer:register_skill_miss_event(sender, reciver, skill_id)\n    local cast_token = sender:get_logic_count()')
            s=replace(s,'pcall(self.real_register_skill_miss_event, self, sender, reciver, skill_id)',
                'pcall(self.real_register_skill_miss_event, self, sender, reciver, skill_id, cast_token)')
            s=replace(s,'function eventenginer:real_register_impact_event(reciver, sender, imp, delaytime, skill_id)',
                'function eventenginer:real_register_impact_event(reciver, sender, imp, delaytime, skill_id, cast_token)')
            s=replace(s,'local caster_logic_count = sender and sender:get_logic_count() or define.INVAILD_ID',
                'local caster_logic_count = cast_token or (sender and sender:get_logic_count() or define.INVAILD_ID)')
            s=replace(s,'function eventenginer:register_impact_event(reciver, sender, imp, delaytime, skill_id)',
                'function eventenginer:register_impact_event(reciver, sender, imp, delaytime, skill_id)\n    local cast_token = sender and sender:get_logic_count() or define.INVAILD_ID')
            s=replace(s,'pcall(self.real_register_impact_event, self, reciver, sender, imp, delaytime, skill_id)',
                'pcall(self.real_register_impact_event, self, reciver, sender, imp, delaytime, skill_id, cast_token)')
        elif rel=='GameServer/services/scene/obj/human.lua':
            s=replace(s,'function human:is_enemy_human(other)', '''function human:is_enemy_human(other)
    -- HJ05 #100/#101: self is never hostile. Personal PK cannot override
    -- shared-party protection in normal or cross-server instances.
    if not other or self == other then return false end
    local scene = self.get_scene and self:get_scene()
    local kind = scene and scene:get_type()
    if kind == 1 or kind == 4 then
        local party = self:get_team_id()
        if type(party) == 'number' and party >= 0 and party == other:get_team_id() then return false end
    end''')
            s=function(s,'human:impact_forbidden_this_skill',change=lambda b:
                replace(replace(b,'        logic:on_skill_miss(impact, sender)\n',''),
                    'logic:forbidden_this_skill(imp, skill_id)','logic:forbidden_this_skill(impact, skill_id)'))
            s=replace(s,'function human:on_skill_miss_target(reciver, skill_id)',
                '''function human:on_skill_miss_target(reciver, skill_id, cast_token)
    -- Outgoing miss is distinct from evading another actor's attack.
    local engine = self:get_scene():get_impact_enginer()
    for _,impact in ipairs(self:get_impact_list()) do
        local logic = engine:get_logic(impact)
        if logic and logic.on_miss_target then
            logic:on_miss_target(impact, self, reciver, skill_id, cast_token)
        end
    end''')
        elif rel=='GameServer/services/scene/ai/human.lua':
            for method in ['add_killer_pk_value','on_be_kill']:
                s=function(s,'human:'+method,change=lambda b:replace(b,
                    '    if killer:get_obj_type() ~= "human" then',
                    '    if not killer or killer == character or killer:get_obj_type() ~= "human" then'))
            s=function(s,'human:after_die',change=lambda b:replace(b,
                '    if killer:get_obj_type() == "pet" then',
                '    if killer and killer:get_obj_type() == "pet" then'))
            s=function(s,'human:is_counter_killed',change=lambda b:replace(b,
                '    if killer:get_obj_type() == "human" then',
                '    if killer and killer ~= character and killer:get_obj_type() == "human" then'))
            def penalty(b):
                b=replace(b,'    local obj_type = killer:get_obj_type()',
                    '    local obj_type = killer and killer ~= character and killer:get_obj_type() or "environment"')
                return replace(b,'            if owner:get_obj_type() == "human" then',
                    '            if owner and owner ~= character and owner:get_obj_type() == "human" then')
            s=function(s,'human:pentalty_type_after_die',change=penalty)
        elif rel.endswith('/character.lua'):
            s=replace(s,'\t\thp_modify = hp_modify + damage_point_refix',
                '''\t\thp_modify = hp_modify + damage_point_refix
        -- HJ05: StdImpact101 changes combined damage once, round half up.
        if damages.cys_nuhuo_rate and hp_modify > 0 then
            hp_modify = hp_modify + math.floor(hp_modify * damages.cys_nuhuo_rate / 100 + 0.5)
        end''')
        elif rel.endswith('/echangeusername.lua'):
            s=function(s,'echangeusername:CallBackChangeUserNameAfter', '''function echangeusername:CallBackChangeUserNameAfter(selfId, nRetType, old_name)
    if not self:LuaFnIsCanDoScriptLogic(selfId) then return 0 end
    local errors = {
        [1]="Đổi tên thất bại.", [2]="Máy chủ đang bận, xin thử lại.",
        [3]="Tên mới không hợp lệ.", [4]="Tên này đã được sử dụng.",
    }
    if nRetType ~= 0 then
        self:MsgBox(selfId, errors[nRetType] or errors[1])
        return 0
    end
    if not string.find(old_name or "", "*", 1, true) then
        if not self:LuaFnDelAvailableItem(selfId, 30008105, 1) then return 0 end
    end
    self:MsgBox(selfId, "Đổi tên thành công!")
    return 1
end''')
        else: s=(OWN/'std_impact_101.lua').read_text(encoding='utf8')
        files[rel]=s.encode('utf8')
    donor=Path('C:/TLBB/085/Tools/DATA NEW/DataCY31-08-26/tlbb15/Public/Config/PetEquipItemAptRate.txt')
    rows=[list(map(int,line.split())) for line in donor.read_text(encoding='gb18030').splitlines()[2:] if line.strip()]
    assert len(rows)==255 and [r[0] for r in rows]==list(range(1,256))
    data='-- CY PetEquipItemAptRate.txt SHA256 '+sha(donor)+'\nreturn {\n'
    data+='\n'.join('[%d]={%s},'%(r[0],','.join(map(str,r[1:]))) for r in rows)+'\n}\n'
    files['GameServer/lualib/cys_pet_apt_data.lua']=data.encode('utf8')
    files['GameServer/lualib/cys_pet_equipment.lua']=(OWN/'cys_pet_equipment.lua').read_bytes()
    files['GameServer/lualib/cys_pet_bank.lua']=(OWN/'cys_pet_bank.lua').read_bytes()
    manifest=[]
    for rel,raw in files.items():
        p=LOG/'server'/rel;p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(raw)
        manifest.append(dict(path=rel,before=sha(LIVE/rel),after=sha(p)))
    (LOG/'server/manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf8')
    print('Staged',len(manifest),'files; private runtime unchanged.')

def apply():
    status=json.loads(subprocess.check_output(['wsl','-d','TLBB','-u','root','--','python3',
        '/mnt/c/TLBB/085/CY-Source/Tools/server/provision_test_wsl.py','status']))
    assert not any(s['running'] for s in status['services']),'Stop private CY services first'
    rows=json.loads((LOG/'server/manifest.json').read_text())
    for r in rows:
        assert sha(LIVE/r['path'])==r['before'],r['path']
        assert sha(LOG/'server'/r['path'])==r['after'],r['path']
    backup=ROOT/'Build/backups/hj05-server'/datetime.datetime.now().strftime('%Y%m%d-%H%M%S')
    for r in rows:
        p=LIVE/r['path'];src=LOG/'server'/r['path']
        if p.exists():
            b=backup/r['path'];b.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,b)
        p.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(src,p)
        assert sha(p)==r['after']
    if (LOG/'server-apply.json').exists():
        shutil.copy2(LOG/'server-apply.json',LOG/('server-apply-before-'+backup.name+'.json'))
    (LOG/'server-apply.json').write_text(json.dumps(dict(backup=str(backup),files=rows),indent=2))
    print('Applied to private CY; backup',backup)
if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('mode',choices=['plan','apply']);a=p.parse_args()
    {'plan':plan,'apply':apply}[a.mode]()
