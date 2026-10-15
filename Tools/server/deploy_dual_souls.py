"""Prepare source-backed dual souls for the private server; hash-guarded install."""
from pathlib import Path
import datetime, hashlib, json, re, shutil, subprocess, sys
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[1]
sys.path.insert(0,str(ROOT/'Tools/game'))
from dual_souls_data import SERVER, tables
from deploy_power import method
OUT=ROOT/'Build/Logs/2026-09-25-dual-souls/server'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest() if p.exists() else None
def replace(s,a,b,count=1):
    assert s.count(a)==count,(a,s.count(a),count)
    return s.replace(a,b)
def changes():
    out={'GameServer/lualib/cys_dual_souls.lua':(HERE/'cys_dual_souls.lua').read_bytes()}
    for rel,data in tables().items():
        if rel.startswith('server/'):out['configs/'+rel.split('/',1)[1]]=data
    def read(rel):
        p=OUT/'baseline'/rel
        if not p.exists():p.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(SERVER/rel,p)
        return p.read_text(encoding='utf8')
    def put(rel,s):out[rel]=s.encode()
    rel='GameServer/lualib/define.lua';s=read(rel)
    s=replace(s,'    HEQUIP_ALL = 38','    HEQUIP_ALL = 38, -- preserve legacy sentinel semantics\n    HEQUIP_CHIENHON = 39,\n    HEQUIP_CAPACITY = 40')
    put(rel,s)
    for rel in ['GameServer/services/scene/human.lua','GameServer/services/scene/obj/human.lua']:
        s=read(rel)
        s=replace(s,'self.equip_container:init(define.HUMAN_EQUIP.HEQUIP_ALL,','self.equip_container:init(define.HUMAN_EQUIP.HEQUIP_CAPACITY,')
        anchor='function human:get_wuhun_skills()\n'
        s=replace(s,anchor,anchor+"    local soul=self:get_equip_container():get_item(18)\n    if soul and require('cys_dual_souls').definition(soul:get_index()) then return require('cys_dual_souls').skills(self,18) end\n")
        anchor='    local wh_skills = self:get_wuhun_skills()'
        s=replace(s,anchor,"    for _,id in ipairs(require('cys_dual_souls').skills(self,39)) do total[#total+1]=id end\n"+anchor)
        put(rel,s)
    rel='GameServer/lualib/item_operator.lua';s=read(rel)
    anchor="    if require('cy_equipment_passives').initialize(item) then return end"
    s=replace(s,anchor,"    if require('cys_dual_souls').initialize(item) then return end\n"+anchor);put(rel,s)
    rel='GameServer/lualib/item.lua';s=read(rel)
    s=replace(s,'[18] = 2,','[18] = 2, [39] = 2,');put(rel,s)
    rel='GameServer/lualib/db/human_attrib.lua';s=read(rel)
    anchor='function human_attrib:kfs_effect_flush(equip, i, item_type)\n'
    s=replace(s,anchor,anchor+"    if require('cys_dual_souls').definition(equip:get_index()) then return end -- its mastery skill is the only passive source\n")
    put(rel,s)
    rel='GameServer/lualib/skillenginer.lua';s=read(rel)
    anchor='function skillenginer:process_skill_request('
    pos=s.index('\n',s.index(anchor))+1
    s=s[:pos]+"    if not require('cys_dual_souls').authorized(obj_me,skill_id) then return false end\n"+s[pos:]
    put(rel,s)
    for rel in ['GameServer/services/scene/obj/character.lua']:
        s=read(rel)
        for anchor in ['function character:on_use_skill_success_fully(skill_info)\n','function character:on_be_hit(sender, skill)\n']:
            s=replace(s,anchor,anchor+"    require('cys_dual_souls').combat(self)\n")
        anchor='function character:impact_clean_when_unequip(equip)\n'
        s=replace(s,anchor,anchor+"    require('cys_dual_souls').unequip(self,equip)\n")
        put(rel,s)
    rel='GameServer/services/scene/scenecore.lua';s=read(rel)
    s=s.replace('for i = define.HUMAN_EQUIP.HEQUIP_WEAPON, define.HUMAN_EQUIP.HEQUIP_ALL do','for i = define.HUMAN_EQUIP.HEQUIP_WEAPON, define.HUMAN_EQUIP.HEQUIP_CAPACITY-1 do')
    # Attach state to the same request that refreshes an AOI character, after its equipment.
    start=s.index('function scenecore:ask_char_equipment(');end=s.index('\nfunction ',start+10)
    part=s[start:end];part=replace(part,'\t\tself:send2client(to, ret)',"\t\tself:send2client(to, ret)\n        require('cys_dual_souls').snapshot(self,obj,to)")
    s=s[:start]+part+s[end:]
    anchor='function scenecore:broad_char_equioment(obj,equip_point)\n'
    s=replace(s,anchor,anchor+"    if equip_point==18 or equip_point==39 then require('cys_dual_souls').snapshot(self,obj,nil,true) end\n")
    anchor='    local equipPoint = use.equipPoint\n'
    start=s.index('function scenecore:char_use_equip(');end=s.index('\nfunction ',start+10)
    part=s[start:end];part=replace(part,anchor,anchor+"    if not require('cys_dual_souls').can_swap(obj_me,equipPoint) then obj_me:notify_tips('Hãy rời giao tranh 10 giây trước khi đổi hồn.');return end\n")
    s=s[:start]+part+s[end:]
    start=s.index('function scenecore:char_un_equip(');end=s.index('\nfunction ',start+10)
    part=s[start:end];anchor='    local equipPoint = unequip.equipPoint\n'
    part=replace(part,anchor,anchor+"    if not obj_me or not require('cys_dual_souls').can_swap(obj_me,equipPoint) then return end\n")
    s=s[:start]+part+s[end:];put(rel,s)
    rel='GameServer/lualib/cys_wuhun_appearance.lua';s=read(rel)
    anchor='function M.visual(item,compound,show,yy,qian,kun,unlocked)\n'
    s=replace(s,anchor,anchor+" if item==10156901 then return show==0 and 0 or 704,show==0 and -1 or item end\n")
    anchor='local function eligible(s,h)\n'
    s=replace(s,anchor,anchor+" local item=h:get_equip_container():get_item(18)\n if item and item:get_index()==10156901 then s:notify_tips(h:get_obj_id(),'Võ hồn Huyền Giáp đang dùng bộ kỹ năng cố định cấp 1.');return false end\n")
    put(rel,s)
    rel='GameServer/lualib/eventenginer.lua';s=read(rel)
    anchor='            if skill_id == 4515 and sender then'
    s=replace(s,anchor,"            if require('cys_dual_souls').schedule_impact(scene,sender,reciver,imp,delaytime,skill_id) then\n                -- Queued by the soul module; the timer owns this prepared impact.\n            elseif skill_id == 4515 and sender then")
    put(rel,s)
    # Tagged extension in the existing ten reserved bytes. No record length change.
    rel='GameServer/services/login/logind.lua';s=read(rel)
    anchor='        c.visuals[20] = 0'
    s=replace(s,anchor,anchor+"\n        local v,item=require('cys_dual_souls').saved_visual(char)\n        c.anon9={0x5344,1,v,item>0 and (item & 0xffff) or 0,item>0 and (item >> 16) or 0}")
    put(rel,s)
    rel='GameServer/services/login/packet.lua';s=read(rel)
    s=replace(s,'            for j = 1, 5 do\n                stream:writeshort(0)\n            end','            -- CYS-DUAL-SOULS: magic, version, visual, item low/high uint16.\n            for j = 1, 5 do\n                local n=(char.anon9 and char.anon9[j]) or 0\n                stream:writeshort(n>32767 and n-65536 or n)\n            end')
    put(rel,s)
    # Existing wh upgrade handlers cannot mutate fixed prototype instances.
    rel='Game_2/Script/scripts/event/equip/wuhun.lua';s=read(rel)
    anchor='    local bagpos=select(1,...)'
    s=replace(s,anchor,anchor+"\n    local h=self.scene:get_obj_by_id(selfId)\n    local item=h and h:get_prop_bag():get_item(bagpos)\n    if item and require('cys_dual_souls').definition(item:get_index()) then self:notify_tips(selfId,'Hồn thử đang dùng bộ kỹ năng cố định cấp 1.');return end")
    put(rel,s)
    # Reuse the existing registered soul script entry, with strict operation whitelist.
    rel='Game_2/Script/scripts/event/equip/huanhun.lua';s=read(rel)
    extension="""
function huanhun:CysDualSoul(id,op,value)
 local h=self.scene:get_obj_by_id(id);if not h or h:get_obj_type()~='human' then return end
 local m=require 'cys_dual_souls'
 if op==1 and (value==0 or value==1) then
  h:set_game_flag_key('cys_assault_hidden',1-value);m.snapshot(self.scene,h,nil,true)
 elseif op==0 then m.snapshot(self.scene,h)
 end
end
"""
    s=replace(s,'return huanhun',extension+'return huanhun');put(rel,s)
    rel='configs/AllowableScriptFunc.txt';raw=(SERVER/rel).read_bytes()
    ids=[int(x.split(b'\t')[0]) for x in raw.splitlines() if x.split(b'\t')[0].isdigit()]
    out[rel]=raw if b'\t888800\tCysDualSoul' in raw else raw.rstrip(b'\r\n')+f'\n{max(ids)+1}\t888800\tCysDualSoul\n'.encode()
    return out
def main():
    files=changes();OUT.mkdir(parents=True,exist_ok=True);records=[]
    for rel,data in files.items():
        p=OUT/rel;p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(data)
        if rel.endswith('.lua'):
            subprocess.run(['wsl','-d','TLBB','-u','root','--','luac5.4','-p','/mnt/c'+p.as_posix()[2:]],check=True)
        records.append({'path':rel,'before':sha(SERVER/rel),'after':sha(p)})
    (OUT/'manifest.json').write_text(json.dumps(records,indent=2))
    if '--apply' in sys.argv:
        active=subprocess.check_output(['wsl','-d','TLBB','-u','root','--','ss','-Htn','state','established'],text=True)
        assert not re.search(r':1573[34]\b',active),'Private client connected'
        backup=SERVER/'backups'/('dual-souls-'+datetime.datetime.now().strftime('%Y%m%d-%H%M%S'));backup.mkdir()
        for row in records:
            p=SERVER/row['path'];assert sha(p)==row['before']
            if p.exists():q=backup/row['path'];q.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,q)
        shutil.copy2(OUT/'manifest.json',backup/'manifest.json')
        for rel,data in files.items():(SERVER/rel).write_bytes(data)
        print('Backup',backup)
    print('Prepared',len(files),'files; syntax PASS; applied','--apply' in sys.argv)
if __name__=='__main__':main()
