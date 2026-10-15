"""Continue the CY gameplay repair using immutable per-task baseline files."""
from pathlib import Path
import argparse,datetime,hashlib,json,re,shutil,sys,subprocess
ROOT=Path(__file__).resolve().parents[2]
SERVER=Path('//wsl.localhost/TLBB/home/ubuntu/cys-test-20260913')
OUT=ROOT/'Build/Logs/2026-09-27-gameplay-completion'
OWN=Path(__file__).with_name('gameplay_completion_lua')
def sha(data):return hashlib.sha256(data).hexdigest()
def baseline(rel):
    p=OUT/'baseline/server'/rel
    if not p.exists():p.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(SERVER/rel,p)
    return p.read_bytes()
def plan():
    files={p.relative_to(OWN).as_posix():p.read_bytes()for p in OWN.rglob('*.lua')}
    from gameplay_completion_data import generate
    files.update(generate())
    registry='Game_2/Script/scripts/scripts.lua';reg=baseline(registry).decode('utf8')
    names=['shaolin','mingjiao','wudang','emei','dali','xiaoyao','tianshan','xingxiu','gaibang']
    for n,name in enumerate(names):
        cls='event_shimen_'+name;rel='Game_2/Script/scripts/event/shimen/'+cls+'.lua'
        s=baseline(rel).decode('utf8')
        # The engine's deletion API returns a boolean, whereas the legacy DelItem
        # wrapper both ignored the count and was tested as a number in these ports.
        s=s.replace('self:DelItem(', 'self:LuaFnDelAvailableItem(')
        s=re.sub(r'self:LuaFnDelAvailableItem\(selfId,\s*(\w+)\)',r'self:LuaFnDelAvailableItem(selfId, \1, 1)',s)
        s=re.sub(r'if ret\s*<=\s*0 then','if not ret then',s)
        s=s.replace('self:HaveItemInBag(selfId, self.g_DingDianYinDaoList[index]["itemId"]) == 1',
                    'self:HaveItemInBag(selfId, self.g_DingDianYinDaoList[index]["itemId"])')
        s=re.sub(r'if itemCount\s*==\s*5 then','if itemCount >= 5 then',s)
        # This is a coroutine-local letter, not mutable state shared by all actors.
        begin=s.index('function '+cls+':SongXin_Accept(');end=s.index('\nfunction ',begin+10)
        part=s[begin:end].replace('self.g_Xin_ItemId','letterItemId')
        part=re.sub(r'(?m)^(\s*)letterItemId\s*=',r'\1local letterItemId =',part,count=1)
        s=s[:begin]+part+s[end:]
        s=s.replace('elseif self:GetMissionParam(selfId, misIndex, 0) then','elseif self:GetMissionParam(selfId, misIndex, 0) > 0 then')
        s=s.replace('if not self:GetMissionParam(humanObjId, misIndex, 0) then','if self:GetMissionParam(humanObjId, misIndex, 0) <= 0 then')
        s=s.replace('nNpcId = self:GetNpcInfoByNpcId(nNpcId)','nNpcId, strNpcName = self:GetNpcInfoByNpcId(nNpcId)')
        # Abandonment discards at most the available objective items, never overdrafts.
        start=s.index('function '+cls+':OnAbandon(');end=s.index('\nfunction ',start+10)
        body=s[start:end]
        body=re.sub(r'(LuaFnGetAvailableItemCount\(selfId,\s*itemId\)\s*>=\s*)5',r'\g<1>1',body)
        body=re.sub(r'self:LuaFnDelAvailableItem\(selfId,\s*itemId,\s*5\)',
                    'self:LuaFnDelAvailableItem(selfId, itemId, math.min(5, self:LuaFnGetAvailableItemCount(selfId, itemId)))',body)
        s=s[:start]+body+s[end:]
        # A party member with a different school task must not receive kill progress.
        s=s.replace('if self:GetMissionParam(humanObjId, misIndex, 0) <= 0 then',
          'if self:GetMissionParam(humanObjId, misIndex, 1) == self.g_SubMissionTypeEnum["killMonster"]\n                    and self:GetMissionParam(humanObjId, misIndex, 0) <= 0 then')
        assert s.count('return '+cls)==1
        s=s.replace('return '+cls,"return require('cys_shimen').install("+cls+')')
        files[rel]=s.encode('utf8')
        sid=229000+n
        if not re.search(r'\['+str(sid)+r'\]\s*=',reg):
            anchor='    [229000] = "scripts.event.shimen.event_shimen_shaolin",'
            assert anchor in reg;reg=reg.replace(anchor,anchor+'\n    ['+str(sid)+'] = "scripts.event.shimen.'+cls+'",')
    files[registry]=reg.encode('utf8')
    rel='GameServer/lualib/human_item_logic.lua';s=baseline(rel).decode('utf8')
    begin=s.index('function human_item_logic:del_available_item(');end=s.index('\nfunction ',begin+10)
    s=s[:begin]+'''function human_item_logic:del_available_items(logparam, human, count, ids)
    if not inventory_guard.integer(count,1,65535) then return false,count end
    local bag=human:get_prop_bag_container()
    local parts,left,seen={},count,{}
    for _,item_index in ipairs(ids)do
        if not inventory_guard.integer(item_index,10000000,79999999)then return false,count end
        if not seen[item_index]then
            seen[item_index]=true
            local family=item_index//10000000
            local kind=(family==2 or family==5 or family==6) and "material" or family==4 and "task" or "prop"
            for p,item in bag:ipairs(kind)do
                if left>0 and item and not item:is_lock() and item:get_index()==item_index then
                    local take=math.min(left,item:get_lay_count())
                    if take>0 then parts[#parts+1]={p,take,item_index,family};left=left-take end
                end
            end
        end
    end
    if left>0 then return false,count end
    -- No yielding calls between the complete availability check and the debit.
    for _,part in ipairs(parts)do
        if part[4]==1 or part[4]==7 then
            assert(part[2]==1);assert(self:erase_item_by_bag_index(logparam,human,part[1]))
        else assert(self:dec_item_lay_count(logparam,human,part[1],part[2],part[3]))end
    end
    return true,0
end
function human_item_logic:del_available_item(logparam,human,item_index,count)
    return self:del_available_items(logparam,human,count,{item_index})
end
''' +s[end:]
    files[rel]=s.encode('utf8')
    rel='GameServer/lualib/script_base.lua';s=baseline(rel).decode('utf8')
    s=s.replace('function script_base:DelItem(selfId, item_index)\n    return self:LuaFnDelAvailableItem(selfId, item_index, 1)',
                'function script_base:DelItem(selfId, item_index, count)\n    return self:LuaFnDelAvailableItem(selfId, item_index, count or 1)')
    for method,replacement in [
      ('LuaFnDelAllAvailableItems','''function script_base:LuaFnDelAllAvailableItems(selfId,count,...)
    local human=self.scene:get_obj_by_id(selfId)
    return human_item_logic:del_available_items({},human,count,{...})
end
'''),('LuaFnMtl_CostMaterial','''function script_base:LuaFnMtl_CostMaterial(selfId,count,materials)
    local human=self.scene:get_obj_by_id(selfId)
    local ok=human_item_logic:del_available_items({},human,count,materials)
    return ok,{}
end
''')]:
        begin=s.index('function script_base:'+method+'(');end=s.index('\nfunction ',begin+10)
        s=s[:begin]+replacement+s[end:]
    for method,replacement in {
      'BeginAddItem': '''function script_base:BeginAddItem()
    local batch=require('cys_script_item_batches').get(self)
    batch.items={};batch.prepared=nil
end
''',
      'AddItem': '''function script_base:AddItem(ItemIndex,Count,is_bind,param)
    local batch=require('cys_script_item_batches').get(self);batch.prepared=nil
    table.insert(batch.items,{item_index=ItemIndex,count=Count,is_bind=is_bind,param=param})
end
''',
      'EndAddItem': '''function script_base:EndAddItem(selfId,emptytab,way)
    local ok=require('cys_script_reward').prepare(self,selfId,way)
    if not ok then
        local human=self.scene:get_obj_by_id(selfId)
        if human then human:notify_tips('Không thể nhận đủ vật phẩm. Hãy kiểm tra chỗ trống trong túi.')end
    end
    if emptytab or not ok then self:BeginAddItem()end
    return ok
end
''',
      'AddItemListToHuman': '''function script_base:AddItemListToHuman(selfId,way)
    return require('cys_script_reward').commit(self,selfId,way)
end
''',
      'LuaFnEndAddItemIgnoreFatigueState': '''function script_base:LuaFnEndAddItemIgnoreFatigueState(selfId)
    return self:EndAddItem(selfId)
end
''',
      'LuaFnAddItemListToHumanIgnoreFatigueState': '''function script_base:LuaFnAddItemListToHumanIgnoreFatigueState(selfId)
    return self:AddItemListToHuman(selfId)
end
''',
    }.items():
        begin=s.index('function script_base:'+method+'(');end=s.index('\nfunction ',begin+10)
        s=s[:begin]+replacement+s[end:]
    begin=s.index('function script_base:LuaFnAwardFreshManEquipWithGemList(');end=s.index('\nfunction ',begin+10)
    part=s[begin:end].replace('self:EndAddItem(selfId)','self:EndAddItem(selfId, nil, 116)')
    part=part.replace('self:AddItemListToHuman(selfId, 116)',
        'if not self:AddItemListToHuman(selfId, 116) then return false, "reward_bag_changed" end')
    s=s[:begin]+part+s[end:]
    files[rel]=s.encode('utf8')
    # Claim the already prepared reward before changing the Dali quest journal
    # or currencies. A stale/full bag therefore leaves the quest claimable.
    for number in [3,4,7,8,9,15,20]:
        rel=f'Game_2/Script/scripts/event/dali/edali_newquest_{number:03d}.lua'
        s=baseline(rel).decode('utf8');begin=s.index(':OnSubmit(');end=s.index('\nfunction ',begin+1)
        part=s[begin:end];assert part.count('self:AddItemListToHuman(selfId)')==1
        part=part.replace('self:AddItemListToHuman(selfId)','')
        guard='if not self:AddItemListToHuman(selfId) then return end'
        if number==9:guard='if next(self.g_ItemBonus)~=nil and not self:AddItemListToHuman(selfId) then return end'
        part=part.replace('if ret then','if ret then\n        '+guard,1)
        files[rel]=(s[:begin]+part+s[end:]).encode('utf8')
    # This is the only authored non-default reward generation mode at a callsite.
    rel='Game_2/Script/scripts/obj/qianzhuang/oqianzhuang_yuanbao.lua'
    s=baseline(rel).decode('utf8');s=s.replace('local ret = self:EndAddItem(selfId)','local ret = self:EndAddItem(selfId, nil, 1)')
    s=s.replace('self:AddItemListToHuman(selfId, 1)','if not self:AddItemListToHuman(selfId, 1) then return end')
    files[rel]=s.encode('utf8')
    rel='Game_2/Script/scripts/event/dali/edali_zhidao_0200.lua'
    s=baseline(rel).decode('utf8');begin=s.index('function edali_zhidao_0200:OnSubmit(');end=s.index('\nfunction ',begin+10)
    part=s[begin:end]
    anchor='    if self:CheckSubmit(selfId) == 1 then'
    assert anchor in part
    part=part.replace(anchor,'''    if not self:IsHaveMission(selfId,self.g_MissionId) then return end
    local valid=false
    for _,item in ipairs(self.g_RadioItemBonus)do if item.id==selectRadioId then valid=true;break end end
    if not valid then return end
'''+anchor,1)
    part=part.replace('self:AddItemListToHuman(selfId)','')
    part=part.replace('if ret then','if ret then\n            if not self:AddItemListToHuman(selfId) then return end',1)
    files[rel]=(s[:begin]+part+s[end:]).encode('utf8')
    rel='GameServer/lualib/abilityenginer.lua';s=baseline(rel).decode('utf8')
    anchor='elseif id == define.AbilityClass.ABILITY_CLASS_COOKING then'
    assert anchor in s
    s=s.replace(anchor,'elseif id == define.ABILITY_CAILIAOHECHENG then\n            self.abilitys[id] = ability_compound.new(ability)\n        '+anchor,1)
    files[rel]=s.encode('utf8')
    staged=OUT/'server';manifest=[]
    for rel,data in sorted(files.items()):
        p=staged/rel;p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(data)
        live=SERVER/rel if not rel.startswith('CLIENT/') else OUT/'baseline/client'/rel[7:]
        manifest.append(dict(path=rel,before=sha(live.read_bytes())if live.exists()else None,after=sha(data)))
    (staged/'manifest.json').write_text(json.dumps(manifest,indent=2))
    print('Planned',len(files),'server files at',staged)
def apply():
    guard="import sys;sys.path.insert(0,'/mnt/c/TLBB/085/CY-Source/Tools/server');import provision_test_wsl as p;p.guard();assert not any(p.owned_processes(s) for s in p.role_specs()[2:]),'Stop the owned private server before apply'"
    subprocess.run(['wsl','-d','TLBB','-u','root','--','python3','-c',guard],check=True)
    staged=OUT/'server';entries=[e for e in json.loads((staged/'manifest.json').read_text())if not e['path'].startswith('CLIENT/')]
    for e in entries:
        p=SERVER/e['path'];assert (sha(p.read_bytes())if p.exists()else None)==e['before'],e['path']
        assert sha((staged/e['path']).read_bytes())==e['after']
    backup=ROOT/'Build/backups/gameplay-completion-server'/datetime.datetime.now().strftime('%Y%m%d-%H%M%S')
    for e in entries:
        p=SERVER/e['path'];b=backup/e['path'];b.parent.mkdir(parents=True,exist_ok=True)
        if p.exists():shutil.copy2(p,b)
        p.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(staged/e['path'],p)
    (backup/'manifest.json').write_text(json.dumps(entries,indent=2));(OUT/'server-applied.json').write_text(json.dumps(dict(backup=str(backup),files=entries),indent=2));print('Applied; backup',backup)
if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('mode',choices=['plan','apply']);a=p.parse_args();globals()[a.mode]()
