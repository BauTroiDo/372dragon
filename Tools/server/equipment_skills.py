"""Build/reapply equipment skill fixes against the private CY server only.

Sources and living clients are read-only. Plans include before hashes and backups.
"""
from pathlib import Path
import argparse, datetime, hashlib, json, re, shutil, sys
ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'Tools/game'))
from dbc_inventory import Table
from equipment_rl_data import rl_specs
R = Path('//wsl.localhost/TLBB/home/ubuntu/cys-test-20260913')
CY = Path('C:/TLBB/085/Tools/DATA NEW/DataCY31-08-26')
OWN = Path(__file__).with_name('equipment_skills_lua')

def sha(p):
    return hashlib.sha256(p.read_bytes()).hexdigest() if p.exists() else None

def lua(value):
    if isinstance(value, dict):
        return '{' + ','.join('[%s]=%s' % (lua(k), lua(v)) for k,v in value.items()) + '}'
    if isinstance(value, (list,tuple)):
        return '{' + ','.join(map(lua,value)) + '}'
    if isinstance(value,str): return json.dumps(value,ensure_ascii=False)
    if value is None: return 'nil'
    return str(value).lower()

def method(text, cls, name, body):
    pattern=r'(?m)^function '+re.escape(cls)+r':'+re.escape(name)+r'\([^\n]*\n.*?^end'
    changed,n=re.subn(pattern,lambda _:body.rstrip(),text,count=1,flags=re.S)
    assert n==1,(cls,name)
    return changed

def data():
    skill_rows={r[0]:r for r in Table(CY/'Config/SkillTemplate_V1.txt').rows}
    kfs=Table(CY/'Config/KFSSkillLevelup.txt').rows
    pools={1:[],2:[],3:[]}; valid={}
    # CY's three families: passive soul / single-target soul / attack soul.
    # Boundaries of the original families are preserved; CY's new passive roots
    # are identified by the template passive flag, not GL IDs or icon suffixes.
    by_id={r[0]:r for r in kfs}
    for row in kfs:
        if row[4]!=1: continue
        sid=row[0];s=skill_rows[sid]
        slot=2 if 1385<=sid<=1535 else 3 if 1541<=sid<=1619 else 1
        if slot==1: assert s[21]==1,(sid,s[2],s[21])
        pools[slot].append(sid)
        seen=set();current=sid
        while current!=-1:
            assert current not in seen and current in by_id,(sid,current)
            seen.add(current);r=by_id[current]
            valid[current]={'slot':slot,'level':r[4],'root':sid}
            current=r[1]
    assert len(valid)==len(kfs)==294
    dark=Table(CY/'tlbb15/Server/Config/DarkSkillList.txt').rows
    study=Table(CY/'tlbb15/Server/Config/DarkSkillStudy.txt').rows
    weights={}
    for slot,sid in enumerate([274,275,276],1):
        start,end={1:(0,8),2:(8,19),3:(19,34)}[slot]
        types={i+1:r for i,r in enumerate(dark[start:end])}
        weights[slot]={}
        for row in study:
            impact,weight=row[slot*2-1:slot*2+1]
            if impact<0 or weight<=0:continue
            match=[kind for kind,ids in types.items() if impact in ids]
            assert len(match)==1,(slot,impact,match)
            weights[slot][match[0]]=weight
        # Some effect families exist in DarkSkillList but have no study weight.
        # They are not learnable by rolling; do not assign a made-up probability.
        assert weights[slot] and set(weights[slot])<=set(types)
    tables={name:Table(CY/'Config'/(name+'.txt')).rows for name in
            ['LongWenBase','LongWenAddAttr','LongWenRateBase','RLBase','RLStar','RLAttrEx','RLSkillBook','RSSkill']}
    dark_types={1:dark[:8],2:dark[8:19],3:dark[19:]}
    return {'wuhun_pools':pools,'wuhun_skills':valid,'dark_weights':weights,'dark_types':dark_types,
            'rl_specs':rl_specs(tables['RSSkill']),
            'tables':{name:{r[0]:r for r in rows} for name,rows in tables.items()}},kfs

def plan(out,base=None):
    out.mkdir(parents=True,exist_ok=True)
    dat,kfs=data()
    files={'GameServer/lualib/cy_equipment_skill_data.lua':
           '-- Generated from CY 3.71 tables; see equipment_skills.py and evidence.json.\nreturn '+lua(dat)+'\n'}
    files.update({str(p.relative_to(OWN)).replace('\\','/'):p.read_text(encoding='utf8')
                  for p in OWN.rglob('*.lua')})
    header=(R/'configs/KFSSkillLevelup.txt').read_text(encoding='gbk').splitlines()[:2]
    files['configs/KFSSkillLevelup.txt']='\n'.join(header+['\t'.join(map(str,r)) for r in kfs])+'\n'
    # CGExecuteScript is admitted by this table before script registration is
    # even consulted. Keep the existing rows and add only our public entries.
    allow=(R/'configs/AllowableScriptFunc.txt').read_text(encoding='gbk')
    rows=[line.split('\t') for line in allow.splitlines()]
    next_id=max(int(row[0]) for row in rows if row[0].isdigit())+1
    for sid,fun in [(809273,'Lw_Op_Do'),(880001,'RL_QuerySkills'),(880001,'RL_SwitchSkill')]:
        if not any(len(row)>2 and row[1]==str(sid) and row[2]==fun for row in rows):
            allow=allow.rstrip('\r\n')+'\n'+f'{next_id}\t{sid}\t{fun}\n';next_id+=1
    files['configs/AllowableScriptFunc.txt']=allow
    for rel,transform in patches().items():
        source=base/rel if base and (base/rel).exists() else R/rel
        files[rel]=transform(source.read_text(encoding='utf8'))
    manifest=[]
    for rel,text in files.items():
        p=out/'files'/rel;p.parent.mkdir(parents=True,exist_ok=True)
        p.write_bytes(text.encode('gbk' if rel.startswith('configs/') else 'utf8'))
        manifest.append(dict(file=rel,before=sha(R/rel),after=sha(p)))
    (out/'plan.json').write_text(json.dumps(manifest,indent=2),encoding='utf8')
    (out/'evidence.json').write_text(json.dumps(dat,ensure_ascii=False,indent=2),encoding='utf8')
    print(json.dumps({'files':len(manifest),'pools':dat['wuhun_pools'],'dark_weights':dat['dark_weights']}))

def patches():
    def script(text):
        for name,kind,operation in [
            ('GenDarkSkillForBagItem',17,'generate'),('RefreshDarkSkills',17,'replace'),
            ('GenWuHunSkillForBagItem',18,'generate'),('ReplaceKfsSkill',18,'replace')]:
            text=method(text,'script_base',name,f'''function script_base:{name}(selfId, pos)
    return require('cy_equipment_skills').{operation}(self,selfId,pos,{kind})
end''')
        text=method(text,'script_base','LuaFnGetBagEquipType','''function script_base:LuaFnGetBagEquipType(selfId, BagPos)
    if type(BagPos)~='number' or BagPos~=math.floor(BagPos) or BagPos<0 or BagPos>254 then return -1 end
    local obj=self.scene:get_obj_by_id(selfId)
    local item=obj and obj:get_prop_bag_container():get_item(BagPos)
    if not item or item:get_serial_class()~=1 then return -1 end
    local base=item:get_base_config()
    return base and base.equip_point or -1
end''')
        start=text.index('function script_base:GetEquipWuHunData')
        end=text.index('\nend',start)
        block=text[start:end].replace('    assert(Item, BagPos)',
            '    if not Item or Item:get_serial_class()~=1 or Item:get_base_config().equip_point~=18 then return nil end')
        text=text[:start]+block+text[end:]
        return text
    def wuhun(text):
        text=text.replace('function wuhun:OnAction(selfId, operate, ...)\n', '''function wuhun:OnAction(selfId, operate, ...)
    local pos=select(1,...)
    if self:LuaFnGetBagEquipType(selfId,pos)~=18 or self:LuaFnIsItemLocked(selfId,pos) then
        self:notify_tips(selfId,'Võ Hồn không hợp lệ hoặc đang khóa.');return
    end
''')
        text=text.replace('if nKfsMain == nil or nKfsCom == nil then','if nKfsMain == nil or nKfsCom == nil or nKfsMain == nKfsCom then')
        text=text.replace('if odd < rand then','if rand <= odd then')
        text=text.replace('    assert(slot_index)\n','')
        text=text.replace('    if kfs_skill_level_up.level >= 6 then', '    if not kfs_skill_level_up or kfs_skill_level_up.level >= 6 then')
        # Check before indexing a missing extended-attribute row.
        text=text.replace('    kfs_attr_ext = kfs_attr_ext[attr_ext_id]\n',
            '    kfs_attr_ext = kfs_attr_ext[attr_ext_id]\n    if not kfs_attr_ext then return end\n')
        text=method(text,'wuhun','AskWashKfsSkill','''function wuhun:AskWashKfsSkill(selfId, pos)
    return require('cy_equipment_skills').paid_roll(self,selfId,pos,18,KfsItem_YiHunShi,50000)
end''')
        return text
    def darkscript(text):
        return method(text,'common_item','DarkSkillAdjustForBagItem','''function common_item:DarkSkillAdjustForBagItem(selfId, pos)
    local ok=require('cy_equipment_skills').paid_roll(self,selfId,pos,17,DarkItem_AdjustSkillItem,50000)
    self:DarkOperateResult(selfId,1,ok and 1 or -1)
    if ok then self:SendImpact(selfId) end
    return ok
end''')
    def item(text):
        text=method(text,'equip_data','wh_understand_skill','''function equip_data:wh_understand_skill(i)
    local skill=require('cy_equipment_skills').wuhun_roll(i,1)
    if not skill then return false end
    self:set_wh_skill(i,skill)
    return true
end''')
        text=method(text,'equip_data','anqi_understand_skill','''function equip_data:anqi_understand_skill()
    local level=self:get_aq_xiulian()
    local spec=define.ANQI_SKILL[level]
    if not spec then return end
    local skill=require('cy_equipment_skills').dark_effect(spec.index,level)
    if skill then self:set_aq_skill(spec.index,skill) end
end''')
        text=method(text,'equip_data','anqi_upgrade_skill','''function equip_data:anqi_upgrade_skill(force)
    local level=self:get_aq_xiulian()
    if not force and level%10~=0 then return end
    local skills=require('cy_equipment_skills')
    for i,required in ipairs({40,70,90})do
        if level>=required then
            local old=self:get_aq_skill(i)
            local kind=skills.dark_kind(i,old)
            -- Preserve a valid family on level-up; never silently reroll an unknown ID.
            if kind then
                local id=skills.dark_effect(i,level,kind)
                if id then self:set_aq_skill(i,id) end
            end
        end
    end
end''')
        return text
    def human(text):
        text=method(text,'human','get_wuhun_skills','''function human:get_wuhun_skills()
    local result={}
    local item=self:get_equip_container():get_item(define.HUMAN_EQUIP.HEQUIP_WUHUN)
    if not item or item:get_equip_data():get_wh_life()<=0 then return result end
    local ed=item:get_equip_data();local skills=ed:get_wh_skill()
    for i,required in ipairs({40,70,90})do
        if ed:get_wh_level()>=required and require('cy_equipment_skills').wuhun_valid(skills[i],i) then
            result[#result+1]=skills[i]
        end
    end
    return result
end''')
        text=text.replace('    local wh_skills = self:get_wuhun_skills()', '''    local dark=self:get_equip_container():get_item(define.HUMAN_EQUIP.HEQUIP_ANQI)
    if dark then
        local ed=dark:get_equip_data();local helper=require('cy_equipment_skills')
        for i,required in ipairs({40,70,90})do
            if ed:get_aq_xiulian()>=required and helper.dark_kind(i,ed:get_aq_skill(i)) then
                local id=273+i
                local found=false;for _,owned in ipairs(total)do if owned==id then found=true end end
                if not found then total[#total+1]=id end
            end
        end
    end
    local wh_skills = self:get_wuhun_skills()''')
        # Existing script permanently adds dark IDs in some paths. Filter them when
        # no valid equipped item exists, so stale learned IDs do not bypass ownership.
        text=text.replace('    local total = table.clone(self:get_skill_list())', '''    local total = {}
    for _,id in ipairs(self:get_skill_list())do
        if id<274 or id>276 then total[#total+1]=id end
    end''')
        addition='''function human:cy_commit_equipment_skill_roll(pos,pending,materials,cost)
    return require('cy_equipment_skills').commit_roll(self,pos,pending,materials,cost)
end

function human:cy_replace_equipment_skill_roll(pos,kind)
    return require('cy_equipment_skills').commit_replace(self,pos,kind)
end

function human:cy_longwen_skill_operation(pos,operation,selection)
    return require('cy_equipment_passives').lw_operation(self,pos,operation,selection)
end

function human:cy_lingpai_operation(operation,pos,group)
    local helper=require 'cy_lingpai'
    if operation=='learn' then return helper.learn(self,pos) end
    if operation=='switch' then return helper.switch(self,pos,group) end
    if operation=='sync' then helper.sync(self);return true end
    return false
end

'''
        if 'function human:cy_commit_equipment_skill_roll' not in text:
            text=text.replace('function human:set_temp_aq_skills',addition+'function human:set_temp_aq_skills')
        return text
    def agent(text):
        if 'function human:cy_commit_equipment_skill_roll' in text:return text
        addition='''function human:cy_commit_equipment_skill_roll(pos,pending,materials,cost)
    return skynet.call(self.obj_address,'lua','cy_commit_equipment_skill_roll',pos,pending,materials,cost)
end

function human:cy_replace_equipment_skill_roll(pos,kind)
    return skynet.call(self.obj_address,'lua','cy_replace_equipment_skill_roll',pos,kind)
end

function human:cy_longwen_skill_operation(pos,operation,selection)
    return skynet.call(self.obj_address,'lua','cy_longwen_skill_operation',pos,operation,selection)
end

function human:cy_lingpai_operation(operation,pos,group)
    return skynet.call(self.obj_address,'lua','cy_lingpai_operation',operation,pos,group)
end

'''
        return text.replace('function human:set_temp_aq_skills',addition+'function human:set_temp_aq_skills')
    def scene(text):
        # Sync all equipment-derived skills on both equip and unequip, after attributes.
        if '-- cy-equipment-skills' not in text:
            text=text.replace('obj_me:item_flush()','obj_me:item_flush()\n    obj_me:send_skill_list() -- cy-equipment-skills')
        start=text.index('function scenecore:char_use_item(');end=text.index('\nend',start)
        block=text[start:end]
        block=block.replace('            if script_id ~= define.INVAILD_ID then', '''            if require('cy_lingpai').is_book(item_index) then
                result=obj_me:cy_lingpai_operation('learn',use.bagIndex) and define.USEITEM_RESULT.USEITEM_SUCCESS or 1
            elseif script_id ~= define.INVAILD_ID then''')
        return text[:start]+block+text[end:]
    def operator(text):
        start=text.index('function item_operator:gen_common_equip_attrib')
        end=text.index('\nend',start)
        block=text[start:end]
        block=block.replace('    if tb.equip_point == 17 then', "    if require('cy_equipment_passives').initialize(item) then return end\n    if tb.equip_point == 17 then")
        return text[:start]+block+text[end:]
    def attrib(text):
        start=text.index('function human_attrib:lingwu_equip_effect_flush')
        end=text.index('\nend',start)
        block=text[start:end].replace('        if equip then', "        if equip and not require('cy_equipment_passives').kind(equip:get_index()) then")
        text=text[:start]+block+text[end:]
        text=text.replace('    self:lingwu_equip_effect_flush()', '''    local lw=self:get_human():get_equip_container():get_item(19)
    if lw then require('cy_equipment_passives').apply_attributes(self,lw,19) end
    self:lingwu_equip_effect_flush()''')
        return text
    def registry(text):
        if '[809273]' not in text:
            text=text.replace('[809270] = "scripts.event.equip.wuhun",','[809270] = "scripts.event.equip.wuhun",\n    [809273] = "scripts.event.equip.cy_longwen",')
        if '[880001]' not in text:
            text=text.replace('[809270] = "scripts.event.equip.wuhun",','[809270] = "scripts.event.equip.wuhun",\n    [880001] = "scripts.event.equip.cy_lingpai",')
        return text
    def impacts(text):
        text=text.replace('impactenginer.id_logic_module = {', "impactenginer.id_logic_module = {\n    [7991] = 'scene.skill.impact_logic.cy_lingpai_buff',")
        return text
    def cfg(text):
        for name in ['transferd','new_table']:
            needle='    self.std_impact_config = '+name
            call="    require('cy_lingpai_combat').install("+name+")\n"
            if call+needle not in text:text=text.replace(needle,call+needle)
        return text
    def character(text):
        text=text.replace('    self:impact_on_damage_target(damages, target, skill_id, imp)', '''    self:impact_on_damage_target(damages, target, skill_id, imp)
    if self:get_obj_type()=='human' then require('cy_lingpai_combat').proc(self,target,skill_id) end''')
        return text
    return {
        'GameServer/lualib/script_base.lua':script,
        'GameServer/lualib/item.lua':item,
        'Game_2/Script/scripts/event/equip/wuhun.lua':wuhun,
        'Game_2/Script/scripts/obj/commonitem/332207.lua':darkscript,
        'GameServer/services/scene/human.lua':human,
        'GameServer/services/scene/obj/human.lua':human,
        'GameServer/services/scene/obj_agent/human.lua':agent,
        'GameServer/services/scene/scenecore.lua':scene,
        'GameServer/lualib/item_operator.lua':operator,
        'GameServer/lualib/db/human_attrib.lua':attrib,
        'Game_2/Script/scripts/scripts.lua':registry,
        'GameServer/lualib/impactenginer.lua':impacts,
        'GameServer/services/scene/obj/character.lua':character,
        'GameServer/lualib/cfghelper.lua':cfg,
    }

def apply(staging):
    manifest=json.loads((staging/'plan.json').read_text())
    for e in manifest:
        assert sha(staging/'files'/e['file'])==e['after'],e['file']
        assert sha(R/e['file']) in {e['before'],e['after']},'source changed: '+e['file']
    backup=R/'backups'/('equipment-skills-'+datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%dT%H%M%SZ'))
    backup.mkdir(parents=True)
    for e in manifest:
        target=R/e['file'];p=backup/e['file']
        if target.exists():p.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(target,p)
        target.parent.mkdir(parents=True,exist_ok=True)
        shutil.copy2(staging/'files'/e['file'],target)
        assert sha(target)==e['after']
    (backup/'manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf8')
    print('applied',len(manifest),'backup',backup)

if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('command',choices=['plan','apply'])
    parser.add_argument('--out',type=Path);parser.add_argument('--staging',type=Path);parser.add_argument('--base',type=Path);args=parser.parse_args()
    if args.command=='plan':plan(args.out,args.base)
    else:apply(args.staging)
