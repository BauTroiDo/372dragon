"""Plan/apply power-system changes to the private server, with before hashes."""
from pathlib import Path
import argparse,datetime,hashlib,json,re,shutil,subprocess,sys
R=Path('//wsl.localhost/TLBB/home/ubuntu/cys-test-20260913')
HERE=Path(__file__).resolve().parent
from power_data import extract
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest() if p.exists() else None
def method(s,cls,name,body):
    s,n=re.subn(r'^function '+cls+':'+name+r'\([^\n]*\n.*?^end',lambda _:body,s,count=1,flags=re.M|re.S)
    assert n==1,(cls,name)
    return s
def main():
    p=argparse.ArgumentParser();p.add_argument('--out',type=Path,required=True);p.add_argument('--apply',action='store_true');a=p.parse_args()
    files={f'GameServer/lualib/{n}.lua':(HERE/(n+'.lua')).read_bytes() for n in ['cys_shending','cys_xiulian','cys_petsoul']}
    text,evidence=extract();files['GameServer/lualib/cys_power_data.lua']=text.encode()
    rel='GameServer/services/scene/obj/human.lua';s=(R/rel).read_text(encoding='utf8')
    if '-- CYS-POWER-SYSTEMS' not in s:
        anchor='    self.xiulian_list = data.xiulian_list'
        assert anchor in s
        s=s.replace(anchor,'    -- CYS-POWER-SYSTEMS: state persists independently of equipment and derived attributes.\n    self.cys_shending=require("cys_shending").init(data.cys_shending)\n    self.cys_shending_revision=math.random(1,2147483646)\n'+anchor,1)
        anchor='        xiulian_list = self:get_xiulian_list(),';assert anchor in s
        s=s.replace(anchor,anchor+'\n        cys_shending = self.cys_shending,',1)
    s=method(s,'human','fix_xiulian_list','function human:fix_xiulian_list()\n    self.xiulian_list=require("cys_xiulian").init(self.xiulian_list)\nend')
    s=method(s,'human','set_temp_pet_soul_attr_data','function human:set_temp_pet_soul_attr_data(bag_index,attr)\n    self.temp_pet_soul_attr_data=bag_index and {bag_index=bag_index,attr=attr} or nil\nend')
    files[rel]=s.encode()
    rel='GameServer/lualib/db/human_attrib.lua';s=(R/rel).read_text(encoding='utf8')
    anchor='    self:common_equip_effect_flush()'
    if 'require("cys_shending").attributes(self)' not in s:
        assert s.count(anchor)==1;s=s.replace(anchor,anchor+'\n    require("cys_shending").attributes(self)')
    files[rel]=s.encode()
    rel='GameServer/lualib/cfghelper.lua';s=(R/rel).read_text(encoding='utf8')
    m=re.search(r'^function cfghelper:read_xiulian_detail\([^\n]*\n.*?^end',s,re.M|re.S);assert m
    s=s[:m.start()]+m.group().replace('for i = 1, 11 do','for i = 1, 15 do')+s[m.end():];files[rel]=s.encode()
    # CY table has the same named repeated headers; covers all 16 CY school IDs.
    source=HERE.parents[2]/'Tools/DATA NEW/DataCY31-08-26/tlbb15/Public/Config/XiuLianDetail.txt'
    from power_data import CY
    from dbc_inventory import Table
    rows=Table(CY/'Config/XiuLianDetail.txt').rows
    original=(R/'configs/XiuLianDetail.txt').read_bytes().split(b'\n')[:2]
    header=original[1].decode('gbk').rstrip('\r').split('\t')
    assert len(header) in (47,63) and len(rows)==2416 and len(rows[0])==63
    header=header[:3]+header[3:7]*15
    files['configs/XiuLianDetail.txt']=('\t'.join(['INT']*63)+'\n'+'\t'.join(header)+'\n'+'\n'.join('\t'.join(map(str,r)) for r in rows)+'\n').encode('gbk')
    rel='Game_2/Script/scripts/obj/dali/odali_wuyazi.lua';s=(R/rel).read_text(encoding='utf8')
    for name,advance in [('AskXiuLianLevelUp','false'),('AskXiuLianAdvanceJingJie','true')]:
        s=method(s,'odali_wuyazi',name,f'function odali_wuyazi:{name}(selfId,targetId,index)\n    return require("cys_xiulian").operate(self,selfId,index,{advance})\nend')
    files[rel]=s.encode()
    rel='GameServer/services/game/packet_domains/misc.lua';s=(R/rel).read_text(encoding='utf8')
    start=s.index('    packet.GCDetailXiulianList = {');end=s.index('    packet.GCSectDetail = {',start)
    block=s[start:end].replace('1, 11 do','1, 15 do')
    if 'stream:writeuint(self.activated or 0)' not in block:
        block=block.replace('stream:writeuint(self.unknow_2)','stream:writeuint(self.unknow_2)\n            stream:writeuint(self.activated or 0)')
    # Decoder matches the actual CY 68-byte layout, even though normally server only writes it.
    block=re.sub(r'for i = 1, 15 do self.xiulian\[i\] = stream:readuint\(\) end\s*self.unknow_2 = stream:readuint\(\)',
        'for i = 1, 15 do self.xiulian[i] = {level=stream:readushort()} end\n            for i = 1, 15 do self.xiulian[i].upper_limit=stream:readushort() end\n            self.unknow_2 = stream:readuint()\n            self.activated = stream:readuint()',block)
    files[rel]=(s[:start]+block+s[end:]).encode()
    files['Game_2/Script/scripts/cys_power.lua']=b'''local P=require('class')('cys_power',require 'script_base')
function P:Action(id,op,revision,a,b,c,d)
 local h=self.scene:get_obj_by_id(id)
 if h and h:get_obj_type()=='human' then return require('cys_shending').action(self,h,op,revision,a,b,c,d) end
end
return P
'''
    files['Game_2/Script/scripts/cys_petsoul.lua']=b'''local P=require('class')('cys_petsoul_script',require 'script_base')
function P:Action(id,op,pos,revision,material)
 local h=self.scene:get_obj_by_id(id)
 if h and h:get_obj_type()=='human' then return require('cys_petsoul').action(self,h,op,pos,revision,material) end
end
return P
'''
    rel='Game_2/Script/scripts/scripts.lua';s=(R/rel).read_text(encoding='utf8');entry='    [990027] = "scripts.cys_power",'
    if re.search(r'\[990027\]',s):assert entry in s
    else:
        m=re.search(r'^\s*\[\d+\]\s*=',s,re.M);s=s[:m.start()]+entry+'\n'+s[m.start():]
    files[rel]=s.encode()
    rel='GameServer/services/scene/scenecore.lua';s=(R/rel).read_text(encoding='utf8')
    for name,var,remove in [('char_use_pet_equip','use','false'),('char_un_pet_equip','un','true')]:
        anchor=f'function scenecore:{name}(who, {var})'
        guardline=f'    if not require("cys_petsoul").can_equip(self,who,{var},{remove}) then return end'
        if guardline not in s:
            assert anchor in s;s=s.replace(anchor,anchor+'\n'+guardline,1)
    files[rel]=s.encode()
    # Keep the legacy GL endpoints safe as well as the new integrated UI.
    rel='GameServer/lualib/script_base.lua';s=(R/rel).read_text(encoding='utf8')
    anchor='    obj:set_temp_pet_soul_attr_data(BagPos, pet_soul_attr)'
    if '-- CYS-SOUL-IDENTITY' not in s:
        assert anchor in s
        s=s.replace(anchor,anchor+'\n    -- CYS-SOUL-IDENTITY: a bag slot is not an item identity.\n    local g=item:get_guid()\n    obj:get_temp_pet_soul_attr_data().guid={world=g.world,server=g.server,series=g.series}',1)
        anchor='    soul:get_pet_equip_data():set_pet_soul_attr(data.attr)';assert anchor in s
        s=s.replace(anchor,'''    local g=soul:get_guid();local old=data.guid
    if soul:is_empty() or soul:is_lock() or soul:get_serial_class()~=7 or not old or old.world~=g.world or old.server~=g.server or old.series~=g.series then
        obj:set_temp_pet_soul_attr_data(nil);return false
    end
'''+anchor,1)
    files[rel]=s.encode()
    rel='Game_2/Script/scripts/obj/suzhou/osuzhou_yunshenshen.lua';s=(R/rel).read_text(encoding='utf8')
    if '-- CYS-SOUL-LIMITS' not in s:
        anchor='    local cost_count, cost_money = self:GetPetSoulLevelUpCost(level, quanlity)';assert anchor in s
        s=s.replace(anchor,'''    -- CYS-SOUL-LIMITS: reject before material or money deductions.
    if level>=100 or self:LuaFnIsItemLocked(selfId,BagPos) then return end
'''+anchor,1)
        anchor='    local quanlity = self:GetPetSoulQuanlity(selfId, BagPosSoul)'
        s=s.replace(anchor,'''    if self:LuaFnIsItemLocked(selfId,BagPosSoul) then return end
'''+anchor)
        anchor='    local count_m = self:GetBagItemLayCount(selfId, BagPosM)';assert anchor in s
        s=s.replace(anchor,'''    if self:LuaFnIsItemLocked(selfId,BagPosM) then return end
    local soul=self.scene:get_obj_by_id(selfId):get_prop_bag_container():get_item(BagPosSoul)
    if soul:get_pet_equip_data():get_pet_soul_level()>=5 then return end
    local count_m = 1 -- feed one item per click; do not erase an entire stack at the cap''',1)
        s=s.replace('if slot_count > 0 then','if slot_count > 0 and not self:LuaFnIsItemLocked(selfId,i) then',1)
        anchor='    local quanlity = self:GetPetSoulQuanlity(selfId, BagPosSoul)'
        start=s.index('function osuzhou_yunshenshen:OnPetSoulXiShuXing(');idx=s.index(anchor,start)
        s=s[:idx]+'''    if type(LockValue)~='number' or LockValue%1~=0 or LockValue<0 or LockValue>111111 or tostring(LockValue):find('[2-9]') then return end
    if BagPosL~=-1 and self:LuaFnIsItemLocked(selfId,BagPosL) then return end
'''+s[idx:]
        anchor='    local pieceId = self:GetBagItemIndex(selfId, BagPosPiece)';assert anchor in s
        s=s.replace(anchor,'    if self:LuaFnIsItemLocked(selfId,BagPosSoul) or self:LuaFnIsItemLocked(selfId,BagPosPiece) then return end\n'+anchor,1)
    files[rel]=s.encode()
    rel='Game_2/Script/scripts/scripts.lua';s=files[rel].decode('utf8')
    entry='    [990028] = "scripts.cys_petsoul",'
    if re.search(r'\[990028\]',s):assert entry in s
    else:
        m=re.search(r'^\s*\[\d+\]\s*=',s,re.M);s=s[:m.start()]+entry+'\n'+s[m.start():]
    files[rel]=s.encode()
    rel='Game_2/Script/scripts/obj/suzhou/osuzhou_yunshenshen.lua';s=files[rel].decode('utf8')
    s=method(s,'osuzhou_yunshenshen','OnPetSoulAddlife','''function osuzhou_yunshenshen:OnPetSoulAddlife(selfId,targetId,pos,reserved,piece)
    local h=self.scene:get_obj_by_id(selfId);if not h then return end
    local power=require('cys_petsoul')
    power.quote(self,h,pos,false)
    return power.action(self,h,5,pos,h._cys_soul_revision,piece)
end''')
    files[rel]=s.encode()
    rel='Game_2/Script/scripts/event/equip/wuhun.lua';s=(R/rel).read_text(encoding='utf8')
    if '-- CYS-KFS-BOOK-COUNT' not in s:
        start=s.index('function wuhun:KfsAttrExStudy(');end=s.index('\nfunction ',start+1)
        block=s[start:end]
        anchor='    self:SetEquipWuHunData(selfId, nKfsPos, {ex_attr = {[slot_index] = attr }})';assert anchor in block
        block=block.replace(anchor,'''    -- CYS-KFS-BOOK-COUNT: validate free slots and consume one book from this stack.
    if attr_count>=ex_attr_number or not slot_index or exist_attr then
        self:notify_tips(selfId,'Không còn ô trống hoặc đã có thuộc tính này.');return
    end
'''+anchor)
        assert 'self:EraseItem(selfId, nBookPos)' in block
        block=block.replace('self:EraseItem(selfId, nBookPos)','self:LuaFnDecItemLayCount(selfId,nBookPos,1)')
        s=s[:start]+block+s[end:]
    files[rel]=s.encode()
    # Validate physical materials before legacy Wuhun mutation/cost calls.
    rel='Game_2/Script/scripts/event/equip/wuhun.lua';s=files[rel].decode('utf8')
    marker='    -- CYS-KFS-MATERIAL-GUARD'
    if marker not in s:
        anchor='function wuhun:OnAction(selfId, operate, ...)'
        s=s.replace(anchor,anchor+"\n"+marker+"\n"+"""    local bagpos=select(1,...)
    local guard=require 'cys_inventory_guard'
    if not guard.integer(bagpos,0,199) then return end
    if operate==1 or operate==2 or operate==3 or operate==4 or operate==9 then
        local material=select(2,...)
        if not guard.integer(material,0,199) or material==bagpos or self:LuaFnIsItemLocked(selfId,material) then return end
    end
""",1)
    files[rel]=s.encode()
    rel='configs/AllowableScriptFunc.txt';raw=(R/rel).read_bytes()
    if b'\t990027\tAction' not in raw:
        ids=[int(line.split(b'\t')[0]) for line in raw.split(b'\n') if line.split(b'\t')[0].isdigit()]
        raw=raw.rstrip(b'\r\n')+f'\n{max(ids)+1}\t990027\tAction\n'.encode()
    files[rel]=raw
    if b'\t990028\tAction' not in raw:
        ids=[int(line.split(b'\t')[0]) for line in raw.split(b'\n') if line.split(b'\t')[0].isdigit()]
        files[rel]=raw.rstrip(b'\r\n')+f'\n{max(ids)+1}\t990028\tAction\n'.encode()
    a.out.mkdir(parents=True,exist_ok=True);manifest=[]
    for rel,raw in files.items():
        dst=a.out/rel;dst.parent.mkdir(parents=True,exist_ok=True);dst.write_bytes(raw)
        manifest.append({'file':rel,'before':sha(R/rel),'after':sha(dst)})
    (a.out/'manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf8')
    (a.out/'evidence.json').write_text(json.dumps(evidence,indent=2),encoding='utf8')
    if a.apply:
        for rel in files:
            if rel.endswith('.lua'):
                path=(a.out/rel).resolve().as_posix();path='/mnt/'+path[0].lower()+path[2:]
                subprocess.run(['wsl','-d','TLBB','-u','root','--','luac5.4','-p',path],check=True)
        active=subprocess.check_output(['wsl','-d','TLBB','-u','root','--','ss','-Htn','state','established'],text=True)
        assert not re.search(r':1573[34]\b',active),'private client connected'
        backup=R/'backups'/('power-'+datetime.datetime.now().strftime('%Y%m%d-%H%M%S'))
        for row in manifest:
            rel=row['file'];dst=R/rel;assert sha(dst)==row['before']
            if row['before']==row['after']:continue
            if dst.exists():
                saved=backup/rel;saved.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(dst,saved)
            dst.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(a.out/rel,dst)
        backup.mkdir(parents=True,exist_ok=True);shutil.copy2(a.out/'manifest.json',backup/'manifest.json')
        print('Backup',backup)
    print('APPLIED' if a.apply else 'PLAN',len(files),'files')
if __name__=='__main__':main()
