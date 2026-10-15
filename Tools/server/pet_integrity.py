"""Reapply Pet fixes to the private server; original CY/GL trees stay read-only."""
from pathlib import Path
import argparse, datetime, hashlib, json, re, sys
from inventory_integrity import function
from pet_integrity_data import upgrade_rows
ROOT = Path(__file__).resolve().parents[2]
R = Path('//wsl.localhost/TLBB/home/ubuntu/cys-test-20260913')
CY = Path('C:/TLBB/085/Tools/DATA NEW/DataCY31-08-26')
OWN = Path(__file__).with_name('pet_integrity_lua')
sys.path.insert(0, str(ROOT/'Tools/game'))
from dbc_inventory import Table

def lua(value):
    if isinstance(value, dict): return '{'+','.join('[%s]=%s'%(lua(k),lua(v)) for k,v in value.items())+'}'
    if isinstance(value, list): return '{'+','.join(map(lua,value))+'}'
    if isinstance(value, str): return json.dumps(value,ensure_ascii=False)
    return str(value).lower()

def cy_data():
    text=(CY/'tlbb15/Server/Config/PetConfigTable.ini').read_bytes().decode('gbk')
    out={k:int(v) for k,v in re.findall(r'^(\w+)\s*=\s*(\d+)\s*(?:;.*)?$',text,re.M)}
    rows={}
    for row in Table(CY/'Config/PetLingXing.txt').rows:
        rows.setdefault(row[1],[]).append(row[2:24])
    assert len(rows)>7000 and out['Compound_leveldown_savvy3']==2
    out['lingxing']=rows
    out['skill_upgrade']=upgrade_rows(CY)
    def script_table(path, key, indexed=False):
        source=(CY/path).read_bytes().decode('gbk')
        body=re.search(re.escape(key)+r'\s*=\s*\{(.*?)\}',source,re.S)[1]
        body=re.sub(r'--[^\n]*','',body)
        if indexed: return {int(k):int(v) for k,v in re.findall(r'\[(\d+)\]\s*=\s*(\d+)',body)}
        return [int(v) for v in re.findall(r'\d+',body)]
    holy='tlbb15/Public/Data/Script/event/pet/pet_holy.lua'
    out['quick_savvy']=script_table('tlbb15/Public/Data/Script/event/petcompound/petsavvyggd.lua','x800106_g_YuanBaoCosts',True)
    out['quick_lingxing']=script_table(holy,'x800124_g_YuanBaoCosts',True)
    out['lingxing_cost']=script_table(holy,'x800124_g_m_money')
    out['lingxing_material']=script_table(holy,'x800124_g_PetJingHun')
    return ('-- Generated from CY 3.71; see pet_integrity.py.\nreturn '+lua(out)+'\n').encode('utf-8')

def methods(text, source):
    for hit in re.finditer(r'^function ([\w:]+)\([^\n]*\n.*?^end',source,re.M|re.S):
        text=function(text,hit[1],hit[0])
    return text

def inject(text, tag, code):
    if tag not in text: return code+'\n'+text
    return text

def transform(rel, raw):
    name=Path(rel).name
    if rel=='configs/PetSkillLevelup.txt':
        return (CY/'tlbb15/Public/Config/PetSkillLevelup.txt').read_bytes()
    if name=='cy_pet_rules_data.lua': return cy_data()
    if name in ('cy_pet_rules.lua','cy_pet_gameplay.lua'): return (OWN/name).read_bytes()
    text=raw.decode('utf-8').replace('\r\n','\n')
    if name=='pet_detail.lua':
        text=inject(text,'local pet_rules =', 'local pet_rules = require "cy_pet_rules"')
        text=methods(text,(OWN/'pet_detail_methods.lua').read_text(encoding='utf-8'))
        text=text.replace('local main_perception = attrib.con_perception','local main_perception = attrib.main_perception')
        text=function(text,'pet_detail:manual_attr',change=lambda b: b if '-- CYS-PET validate points' in b else b.replace(
            '\n', '''
    -- CYS-PET validate points BEFORE name/title or stat mutations.
    if pet_rules.points(manual, self.db:get_lv1_attrib().point_remain) == nil then return false end
''',1))
    elif name=='pet_attrib.lua':
        text=inject(text,'local pet_rules =', 'local pet_rules = require "cy_pet_rules"')
        text=text.replace('''lingxing = lingxing % 100
                local l_bonus = lingxing_bonus[2][lingxing] or 0''','''local rows = configenginer:get_config("cy_pet_rules_data").lingxing[self:get_db_attrib("data_id")]
                local main = refix_by_other.main_perception(self)
                local l_bonus = pet_rules.lingxing_bonus(rows, main, lingxing)''')
        # Main perception changes with base stats and savvy; it is also the
        # selector of the PetLingXing row advertised in GC512.
        text=text.replace('wuxing = { str_perception = true,','wuxing = { main_perception = true, str_perception = true,')
        def guard_effects(body):
            if '-- CYS-PET missing soul config' in body:return body
            body=body.replace('''local config = pet_soul_level_up_info[item_index] and pet_soul_level_up_info[item_index][soul_level]
        if not config then
            return
        end''','local config = pet_soul_level_up_info[item_index][soul_level]')
            body=body.replace('local base = equip_base[equip:get_index()]','local base = equip_base[equip:get_index()] or {base_attrs={}}')
            body=body.replace('local base_config = equip:get_base_config()','local base_config = equip:get_base_config() or {}')
            body=body.replace('if set_id ~= define.INVAILD_ID then','if set_id and set_id ~= define.INVAILD_ID then')
            body=body.replace('local ia = set.IAS[i]','local ia = set.IAS and set.IAS[i]').replace('if ia ~= define.INVAILD_ID then','if type(ia)=="table" and ia.IA and ia.IV then')
            body=body.replace('local config = pet_soul_level_up_info[item_index][soul_level]', '''local config = pet_soul_level_up_info[item_index] and pet_soul_level_up_info[item_index][soul_level]
        -- CYS-PET missing soul config: keep item, omit unavailable effects.
        if not config then require('skynet').error('[PET_CONFIG] missing soul level',item_index,soul_level) end
        if config then''')
            body=body.replace('local pet_soul_attrs = raw_data.pet_soul_attr','local pet_soul_attrs = raw_data.pet_soul_attr or {}')
            body=body.replace('local attr = pet_soul_attrs[i]','local attr = pet_soul_attrs[i] or {type=define.INVAILD_ID,value=0}')
            body=body.replace('assert(ia, type)','if ia then')
            body=body.replace('''                    self:cal_item_effect(ia, value)
                end''','''                    self:cal_item_effect(ia, value)
                    else require('skynet').error('[PET_CONFIG] unknown soul extension', type) end
                end''',1)
            marker='    -- 兽灵(精灵槽)属性加成'
            assert marker in body
            body=body.replace(marker,'    end -- CYS-PET valid soul level\n\n'+marker,1)
            return body
        text=function(text,'pet_attrib:item_effect_flush',change=guard_effects)
    elif name=='cfghelper.lua':
        marker='-- CYS-PET shared rules config'
        text=re.sub(r'-- CYS-PET shared rules config\nfunction cfghelper:read_cy_pet_rules_data\(\).*?\nend\nfunction cfghelper:get_cy_pet_rules_data\(\).*?\nend\n\n?', '', text, flags=re.S)
        block='''-- CYS-PET shared rules config
function cfghelper:read_cy_pet_rules_data()
    self.cy_pet_rules_data = require "cy_pet_rules_data"
end
function cfghelper:get_cy_pet_rules_data()
    if not self.cy_pet_rules_data then self:read_cy_pet_rules_data() end
    return self.cy_pet_rules_data
end
'''
        text=re.sub(r'^return cfghelper$',block+'\nreturn cfghelper',text,flags=re.M)
    elif name=='configenginer.lua':
        if '"cy_pet_rules_data",' not in text: text=text.replace('"pet_config_table",','"pet_config_table",\n    "cy_pet_rules_data",')
    elif name in ('item_6096.lua','6096.lua'):
        cls='item_6096' if name=='item_6096.lua' else 'common_item'
        text=inject(text,'local pet_gameplay =','local pet_gameplay = require "cy_pet_gameplay"')
        text=function(text,cls+':OnConditionCheck',f'''function {cls}:OnConditionCheck(selfId)
    return pet_gameplay.study(self, selfId, false) and 1 or 0
end''')
        text=function(text,cls+':OnActivateOnce',f'''function {cls}:OnActivateOnce(selfId)
    if not pet_gameplay.study(self, selfId, true) then return 0 end
    self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 18, 0)
    return 1
end''')
    elif name=='petskilllevelup.lua':
        text=inject(text,'local pet_gameplay =','local pet_gameplay = require "cy_pet_gameplay"')
        text=function(text,'petskilllevelup:PetSkillLevelup','''function petskilllevelup:PetSkillLevelup(selfId, petHid, petLid, skillindex, ItemIndexInBag, mode)
    local ok
    if mode==nil or mode==0 then ok=pet_gameplay.upgrade(self,selfId,petHid,petLid,skillindex,ItemIndexInBag)
    elseif mode==1 then ok=pet_gameplay.upgrade_quick(self,selfId,petHid,petLid,skillindex) end
    if not ok then
        self:NotifyFailTips(selfId, "Trân thú, kỹ năng, nguyên liệu hoặc tiền không hợp lệ.")
        return false
    end
    self:NotifyFailTips(selfId, "Thăng cấp thành công!")
    self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 18, 0)
    return true
end''')
    elif name in ('petsavvyggd.lua','petsavvy.lua','pet_holy.lua'):
        text=inject(text,'local pet_gameplay =','local pet_gameplay = require "cy_pet_gameplay"')
        if name=='petsavvyggd.lua':
            changes=[('PetSavvy','savvy','false'),('QuickPetSavvy','savvy','true')]
        elif name=='pet_holy.lua':
            changes=[('Pet_LXUP','lingxing','false'),('Quick_Pet_LXUP','lingxing','true')]
            text=function(text,'pet_holy:Pet_HH','''function pet_holy:Pet_HH(selfId,high,low,keep_model)
    local ok=pet_gameplay.awaken(self,selfId,high,low,keep_model)
    self:notify_tips(selfId,ok and "Huyễn hóa thành công." or "Trân thú, ngoại hình, nguyên liệu hoặc tiền không hợp lệ.")
    if ok then self:LuaFnSendSpecificImpactToUnit(selfId,selfId,selfId,18,0) end
    return ok
end''')
        else:
            changes=[]
            text=function(text,'petsavvy:PetSavvy','''function petsavvy:PetSavvy(selfId,high,low,assist_high,assist_low)
    local ok,won=pet_gameplay.savvy(self,selfId,high,low,false,assist_high,assist_low)
    self:notify_tips(selfId,not ok and "Trân thú, căn cốt hoặc tiền không hợp lệ." or won and "Tăng ngộ tính thành công." or "Tăng ngộ tính thất bại.")
    return ok
end''')
        cls=name[:-4]
        for method,op,quick in changes:
            text=function(text,cls+':'+method,f'''function {cls}:{method}(selfId,high,low)
    local ok,won=pet_gameplay.{op}(self,selfId,high,low,{quick})
    self:notify_tips(selfId,not ok and "Trân thú, nguyên liệu hoặc tiền không hợp lệ." or won==false and "Nâng cấp thất bại." or "Nâng cấp thành công.")
    return ok
end''')
    elif name=='script_base.lua':
        text=inject(text,'local pet_gameplay =','local pet_gameplay = require "cy_pet_gameplay"')
        text=function(text,'script_base:GetPetSkillLevelupTbl','''function script_base:GetPetSkillLevelupTbl(selfId, high, low, index)
    local pet, human, current, target, item, cost, broadcast = pet_gameplay.upgrade_info(self, selfId, high, low, index)
    if not pet then return -1 end
    return current, target, item, cost, broadcast
end''')
        text=function(text,'script_base:LuaFnPetSkillUp','''function script_base:LuaFnPetSkillUp(selfId, high, low, index, target)
    local pet, human, current, expected = pet_gameplay.upgrade_info(self, selfId, high, low, index)
    if not pet or target ~= expected then return false end
    pet:set_skill_by_index(index, target)
    human:send_pet_detail(pet, human)
    return true
end''')
    elif rel=='GameServer/services/scene/obj/human.lua':
        text=methods(text,(OWN/'human_pet_methods.lua').read_text(encoding='utf-8'))
        text=function(text,'human:remove_pet',change=lambda b:b if '-- CYS-PET remove soul state' in b else b.replace(
            '    if self:get_current_pet_guid() == guid then', '''    -- CYS-PET remove soul state before removing its owner record.
    if not self:get_pet_bag_container():get_pet_by_guid(guid) then return false end
    if self:get_current_soul_melting_pet_guid() == guid then self:remelting_pet_soul() end
    if self:get_current_pet_guid() == guid then'''))
        text=function(text,'human:call_up_pet',change=lambda b:b.replace('    if pet:is_in_exchange() then','    if not pet or pet:is_lock() or pet:is_in_exchange() then'))
    elif name=='scenecore.lua':
        text=inject(text,'local pet_rules =','local pet_rules = require "cy_pet_rules"')
        text=function(text,'scenecore:char_set_pet_attrib',change=lambda b: b.replace(
            'local guid = pet_guid.new()', '''if not obj or type(set.guid) ~= "table"
        or not pet_rules.integer(set.guid.m_uHighSection, 0, 4294967295)
        or not pet_rules.integer(set.guid.m_uLowSection, 0, 4294967295) then return end
    local guid = pet_guid.new()''') if '-- CYS-PET valid owned pet' not in b else b)
        text=function(text,'scenecore:char_set_pet_attrib',change=lambda b: b.replace(
            '    pet_detail:manual_attr(set)', '''    -- CYS-PET valid owned pet
    if not pet_detail or pet_detail:is_lock() or pet_detail:is_in_exchange() then return end
    pet_detail:manual_attr(set)''') if '-- CYS-PET valid owned pet' not in b else b)
        text=function(text,'scenecore:char_set_pet_attrib',change=lambda b: b.replace('        pet:item_flush()','        if pet then pet:item_flush() end'))
    return text.encode('utf-8')

RELS=['GameServer/'+p for p in [
    'lualib/cy_pet_rules.lua','lualib/cy_pet_gameplay.lua','lualib/cy_pet_rules_data.lua',
    'lualib/pet_detail.lua','lualib/db/pet_detail.lua','lualib/pet_attrib.lua','lualib/db/pet_attrib.lua',
    'lualib/cfghelper.lua','lualib/configenginer.lua','lualib/script_base.lua','services/scene/scenecore.lua',
    'services/scene/obj/human.lua']]+[
    'Game_2/Script/scripts/obj/commonitem/item_6096.lua',
    'Game_2/Script/scripts/obj/pet/6096.lua',
    'Game_2/Script/scripts/event/petskill/petskilllevelup.lua',
    'Game_2/Script/scripts/event/petcompound/petsavvyggd.lua',
    'Game_2/Script/scripts/event/petcompound/petsavvy.lua',
    'Game_2/Script/scripts/event/petcompound/pet_holy.lua',
    'configs/PetSkillLevelup.txt']

def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--out',type=Path,required=True);p.add_argument('--apply',action='store_true')
    a=p.parse_args();assert R.name=='cys-test-20260913' and R.is_dir()
    a.out.mkdir(parents=True,exist_ok=True);todo=[];manifest=[]
    sha=lambda b:hashlib.sha256(b).hexdigest()
    for rel in RELS:
        path=R/rel;raw=path.read_bytes() if path.exists() else b'';new=transform(rel,raw)
        assert transform(rel,new)==new, 'non-idempotent '+rel
        dest=a.out/rel;dest.parent.mkdir(parents=True,exist_ok=True);dest.write_bytes(new)
        manifest.append(dict(path=rel,before=sha(raw) if path.exists() else None,after=sha(new)))
        if new!=raw:todo.append((rel,raw,new,path.exists()))
    report=dict(files=manifest,utc=datetime.datetime.now(datetime.timezone.utc).isoformat())
    if a.apply and todo:
        backup=R/'backups'/('pet-integrity-'+datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%dT%H%M%SZ'));backup.mkdir(parents=True,exist_ok=False)
        for rel,raw,new,exists in todo:
            assert ((R/rel).read_bytes() if (R/rel).exists() else b'')==raw
            if exists:
                dest=backup/rel;dest.parent.mkdir(parents=True,exist_ok=True);dest.write_bytes(raw)
        for rel,raw,new,exists in todo:
            (R/rel).parent.mkdir(parents=True,exist_ok=True);(R/rel).write_bytes(new)
        report['backup']=str(backup);(backup/'manifest.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
        print('backup',backup)
    (a.out/'manifest.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
    print('APPLIED' if a.apply else 'PLAN',len(todo),'files')
if __name__=='__main__':main()
