"""Plan/apply 100-slot bags, stack limit and truthful capped EXP on the private server."""
from pathlib import Path
import argparse,datetime,hashlib,json,os,subprocess,shutil
from inventory_integrity import ROOT,function
if os.name!='nt': ROOT=Path('/home/ubuntu/cys-test-20260913')

MARK='-- CYS-ROUND2 23/09'
def transform(rel,text):
    if MARK in text:return text
    if rel.endswith('obj/human.lua'):
        for name in ('prop','material'):
            text=function(text,'human:get_'+name+'_bag_size',f'''function human:get_{name}_bag_size()
    {MARK} Fixed region: props 0..99, materials 100..199.
    return 100
end''')
        text=text.replace('    self:add_my_exp(add_exp, award_exp)',
                          '    add_exp, award_exp = self:add_my_exp(add_exp, award_exp)')
        def experience(b):
            b=b.replace('    local exp = self:get_exp() + add_exp + award_exp',
                f'''    {MARK} Report only EXP actually credited; never add the notification twice.
    add_exp=math.max(0,math.floor(add_exp or 0))
    award_exp=math.max(0,math.floor(award_exp or 0))
    local before=self:get_exp()
    local exp = before + add_exp + award_exp''')
            b=b.replace('    if exp > 4 * level_exp then\n        exp = 4 * level_exp',
                '''    local cap=math.floor(3.5 * level_exp)
    -- Keep already earned overflow after changing the policy; block new gains
    -- until EXP is spent below the cap. Automatic level-up has already spent EXP.
    local limit=math.max(cap, math.min(before,exp-add_exp-award_exp))
    local lost=math.max(0,exp-limit)
    if exp > limit then
        exp = limit''')
            b=b.replace('    self:update_exp(exp)', '''    self:update_exp(exp)
    self:send_refresh_attrib()
    local accepted=math.max(0,add_exp+award_exp-lost)
    local normal=math.min(add_exp,accepted)
    return normal,accepted-normal''')
            return b
        text=function(text,'human:add_my_exp',change=experience)
    elif rel.endswith('/item.lua'):
        text=function(text,'item:get_max_tile_count',change=lambda b:b.replace('    return max_tile_count',
            f'''    {MARK} Preserve single-instance gear and non-stackable special items.
    if max_tile_count > 1 and self:can_lay() then return 250 end
    return max_tile_count'''))
    elif rel.endswith('/scenecore.lua'):
        text=function(text,'scenecore:char_use_bag_equip',change=lambda b:b.replace(
            'local subsize = usesize - cursize',f'local subsize = 0 {MARK} Capacity stays 100 when bag equipment changes.'))
        text=function(text,'scenecore:char_un_equip',change=lambda b:b.replace(
            'test_can_change_size("prop", -size)', 'test_can_change_size("prop", 0)').replace(
            'dest_container:get_size().prop - size','dest_container:get_size().prop').replace(
            'test_can_change_size("material", -size)','test_can_change_size("material", 0)'))
    return text

RELS=['GameServer/services/scene/obj/human.lua','GameServer/lualib/item.lua','GameServer/services/scene/scenecore.lua']
def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--out',type=Path,required=True);p.add_argument('--apply',action='store_true');a=p.parse_args()
    changes=[];rows=[]
    for rel in RELS:
        src=ROOT/rel;raw=src.read_bytes();new=transform(rel,raw.decode('utf8')).encode('utf8')
        assert transform(rel,new.decode())==new.decode()
        dst=a.out/rel;dst.parent.mkdir(parents=True,exist_ok=True);dst.write_bytes(new)
        rows.append({'path':rel,'before':hashlib.sha256(raw).hexdigest(),'after':hashlib.sha256(new).hexdigest()})
        if raw!=new:changes.append((rel,raw,new))
    record={'root':str(ROOT),'files':rows}
    if a.apply and changes:
        for rel,raw,new in changes:
            subprocess.run(['luac','-p',str(a.out/rel)],check=True)
        from give_item import connected
        assert not connected(),'Do not restart or modify runtime while a client is connected'
        bak=ROOT/'backups'/('round2-basic-'+datetime.datetime.now().strftime('%Y%m%d-%H%M%S'));bak.mkdir()
        for rel,raw,new in changes:
            assert (ROOT/rel).read_bytes()==raw
            dst=bak/rel;dst.parent.mkdir(parents=True,exist_ok=True);dst.write_bytes(raw)
        for rel,raw,new in changes:(ROOT/rel).write_bytes(new)
        record['backup']=str(bak);(bak/'manifest.json').write_text(json.dumps(record,indent=2))
    (a.out/'manifest.json').write_text(json.dumps(record,indent=2))
    print('APPLIED' if a.apply else 'PLAN',len(changes),'files')
if __name__=='__main__':main()
