"""Install CY automatic combat on the private server, with rollback sources."""
from pathlib import Path
import argparse,datetime,json,re,subprocess,sys
from inventory_integrity import function
R=Path('/home/ubuntu/cys-test-20260913');HERE=Path(__file__).resolve().parent
sys.path.insert(0,str(HERE.parent/'game'))
from dbc_inventory import Table

def main():
    p=argparse.ArgumentParser();p.add_argument('--apply',action='store_true');p.add_argument('--out',type=Path,required=True);a=p.parse_args()
    changes={'GameServer/lualib/cys_battle_assist.lua':(HERE/'cys_battle_assist.lua').read_bytes()}
    src=HERE.parents[1]/'Assets/CanonicalCY/Data/ConfigFolder'
    data='-- Generated from canonical CY ZdZdSkill and ZdZdPotion, numeric columns in original order.\nreturn {\n'
    for key,name,width in [('skills','ZdZdSkill.txt',9),('potions','ZdZdPotion.txt',4)]:
        t=Table(src/name);data+=key+'={\n'+''.join('{'+','.join(str(int(v)) for v in row[:width])+'},\n' for row in t.rows)+'},\n'
    changes['GameServer/lualib/cys_assist_data.lua']=(data+'}\n').encode()
    rel='GameServer/services/scene/obj/human.lua';s=(R/rel).read_text()
    if '-- CYS-ASSIST storage' not in s:
        anchor='    self.talent = data.talent'
        assert s.count(anchor)==1
        s=s.replace(anchor,'    self.cys_assist = data.cys_assist -- CYS-ASSIST storage: active state is never persisted.\n'+anchor)
        anchor='        talent = self:get_talent(),';assert s.count(anchor)==1
        s=s.replace(anchor,anchor+'\n        cys_assist = self.cys_assist,')
    changes[rel]=s.encode()
    rel='GameServer/services/scene/ai/human.lua';s=(R/rel).read_text()
    if '-- CYS-ASSIST executor' not in s:
        anchor='function human:push_command_move(handle, path, line)'
        s=s.replace(anchor,anchor+'\n    require("cys_battle_assist").stop(self:get_character(), "Đã dừng tự chiến đấu theo lệnh di chuyển.")')
        # Own AI tick, with the existing state machine still responsible for all actual actions.
        anchor='function human:ctor()';assert s.count(anchor)==1
        s=s.replace(anchor,'''-- CYS-ASSIST executor
function human:logic(delta_time)
    require("cys_battle_assist").tick(self:get_character(),delta_time)
    return self.super.logic(self,delta_time)
end

'''+anchor)
    changes[rel]=s.encode()
    script='local class=require "class"\nlocal P=class("cys_assist",require "script_base")\nlocal M=require "cys_battle_assist"\n'
    for name,fn in [('Open','snapshot'),('Begin','begin'),('Chunk','chunk'),('Commit','commit'),('Start','start')]:
        script+=f'''function P:{name}(selfId,...)
 local h=self.scene:get_obj_by_id(selfId)
 if h and h:get_obj_type()=="human" then M.{fn}(self,h,...) end
end
'''
    script+='function P:Stop(selfId) local h=self.scene:get_obj_by_id(selfId);if h then M.stop(h);M.snapshot(self,h) end end\nreturn P\n'
    changes['Game_2/Script/scripts/cys_assist.lua']=script.encode()
    rel='Game_2/Script/scripts/scripts.lua';s=(R/rel).read_text();entry='    [990026] = "scripts.cys_assist",'
    if re.search(r'\[990026\]',s):assert entry in s
    else:
        m=re.search(r'^\s*\[\d+\]\s*=',s,re.M);s=s[:m.start()]+entry+'\n'+s[m.start():]
    changes[rel]=s.encode()
    rel='configs/AllowableScriptFunc.txt';raw=(R/rel).read_bytes()
    if not re.search(rb'\t990026\t',raw):
        ids=[int(line.split(b'\t')[0]) for line in raw.splitlines() if line.split(b'\t')[0].isdigit()]
        raw=raw.rstrip(b'\r\n')+f'\n{max(ids)+1}\t990026\tOpen\n'.encode()
    changes[rel]=raw;a.out.mkdir(parents=True,exist_ok=True)
    for rel,data in changes.items():
        dst=a.out/rel;dst.parent.mkdir(parents=True,exist_ok=True);dst.write_bytes(data)
        if rel.endswith('.lua'):subprocess.run(['luac','-p',str(dst)],check=True)
    if a.apply:
        from give_item import connected
        assert not connected()
        backup=R/'backups'/('assist-'+datetime.datetime.now().strftime('%Y%m%d-%H%M%S'))
        for rel,data in changes.items():
            dst=R/rel
            if dst.exists():
                saved=backup/rel;saved.parent.mkdir(parents=True,exist_ok=True);saved.write_bytes(dst.read_bytes())
            dst.parent.mkdir(parents=True,exist_ok=True);dst.write_bytes(data)
        print('Backup',backup)
    print('APPLIED' if a.apply else 'PLAN',len(changes),'syntax PASS')
if __name__=='__main__':main()
