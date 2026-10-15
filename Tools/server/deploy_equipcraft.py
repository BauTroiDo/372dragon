"""Reproducible equipment workshop install on the private CY server only."""
from pathlib import Path
import argparse,datetime,hashlib,json,re,shutil,subprocess
ROOT=Path('//wsl.localhost/TLBB/home/ubuntu/cys-test-20260913')
HERE=Path(__file__).resolve().parent
MARK='-- CYS-EQUIPCRAFT'

def changes():
    files={'GameServer/lualib/cys_equipcraft.lua':(HERE/'cys_equipcraft.lua').read_bytes()}
    files['Game_2/Script/scripts/cys_equipcraft.lua']=b'''local P=require('class')('cys_equipcraft_script',require 'script_base')
function P:Action(id,op,mode,pos,material,target,revision)
 local h=self.scene:get_obj_by_id(id)
 if h and h:get_obj_type()=='human' then return require('cys_equipcraft').action(self,h,op,mode,pos,material,target,revision) end
end
function P:LevelUp(id,npc,pos,check)
 return self:Action(id,0,1,pos,-1,-1,0)
end
return P
'''
    rel='Game_2/Script/scripts/scripts.lua';s=(ROOT/rel).read_text(encoding='utf8')
    for n in [990029,880036]:
        entry=f'    [{n}] = "scripts.cys_equipcraft",'
        if re.search(r'\['+str(n)+r'\]',s):assert entry in s,n
        else:
            m=re.search(r'^\s*\[\d+\]\s*=',s,re.M);assert m;s=s[:m.start()]+entry+'\n'+s[m.start():]
    files[rel]=s.encode()
    rel='GameServer/lualib/db/human_attrib.lua';s=(ROOT/rel).read_text(encoding='utf8')
    old='local ev = self:calc_zengfu_value(equip, ef, equip_data.attr_values[j])'
    new='local ev = self:calc_zengfu_value(equip, ef, require("cys_equipcraft").bonus(equip, ef, equip_data.attr_values[j]))'
    if new not in s:assert s.count(old)==4;s=s.replace(old,new)
    files[rel]=s.encode()
    rel='Game_2/Script/scripts/event/equip/diaowen.lua';s=(ROOT/rel).read_text(encoding='utf8')
    # Old APIs can bypass quote identity and contain nil derefs/negative-count
    # deductions. Route their basic operations into the validated workshop.
    for name,mode in [('DWShike',2),('DWQiangHua',3),('DWChaiChu',4),('DWHecheng',5),('DoDiaowenDivert',6)]:
        body=f'''function diaowen:{name}(selfId,...)
    {MARK} open current quote; only Action990029 commits costs.
    local h=self.scene:get_obj_by_id(selfId)
    if h then require('cys_equipcraft').quote(self,h,{mode},-1,-1,-1,true) end
end'''
        s,n=re.subn(r'^function diaowen:'+name+r'\([^\n]*\n.*?^end\b',lambda _:body,s,count=1,flags=re.M|re.S);assert n==1,name
    files[rel]=s.encode()
    rel='configs/AllowableScriptFunc.txt';raw=(ROOT/rel).read_bytes()
    for script,method in [(990029,'Action'),(880036,'LevelUp')]:
        entry=f'\t{script}\t{method}'.encode()
        if not any(line.rstrip(b'\r').endswith(entry) for line in raw.split(b'\n')):
            ids=[int(line.split(b'\t')[0]) for line in raw.split(b'\n') if line.split(b'\t')[0].isdigit()]
            raw=raw.rstrip(b'\r\n')+b'\n'+str(max(ids)+1).encode()+entry+b'\n'
    files[rel]=raw
    return files

def main():
    p=argparse.ArgumentParser();p.add_argument('--out',type=Path,required=True);p.add_argument('--apply',action='store_true');a=p.parse_args()
    files=changes();a.out.mkdir(parents=True,exist_ok=True);record=[]
    for rel,data in files.items():
        target=a.out/rel;target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(data)
        path='/mnt/'+target.resolve().drive[0].lower()+target.resolve().as_posix()[2:]
        if rel.endswith('.lua'):
            subprocess.run(['wsl','-d','TLBB','-u','root','--','luac5.4','-p',path],check=True)
        dst=ROOT/rel;record.append({'path':rel,'before':hashlib.sha256(dst.read_bytes()).hexdigest() if dst.exists() else None,'after':hashlib.sha256(data).hexdigest()})
    (a.out/'manifest.json').write_text(json.dumps(record,indent=2)+'\n')
    if a.apply:
        active=subprocess.check_output(['wsl','-d','TLBB','-u','root','--','ss','-Htn','state','established'],text=True)
        assert not re.search(r':1573[34]\b',active),'Private clients connected'
        backup=ROOT/'backups'/('equipcraft-'+datetime.datetime.now().strftime('%Y%m%d-%H%M%S'));backup.mkdir()
        for row in record:
            dst=ROOT/row['path'];assert (hashlib.sha256(dst.read_bytes()).hexdigest() if dst.exists() else None)==row['before']
            if dst.exists():save=backup/row['path'];save.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(dst,save)
        shutil.copy2(a.out/'manifest.json',backup/'manifest.json')
        for rel,data in files.items():(ROOT/rel).write_bytes(data)
        print('Backup:',backup)
    print('PASS syntax; prepared',len(files),'files; apply=',a.apply)
if __name__=='__main__':main()
