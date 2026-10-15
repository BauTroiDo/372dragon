"""Install the temporary bag on the private server; keep original containers isolated."""
from pathlib import Path
import argparse,datetime,json,re,subprocess
R=Path('/home/ubuntu/cys-test-20260913');HERE=Path(__file__).resolve().parent
def main():
    p=argparse.ArgumentParser();p.add_argument('--apply',action='store_true');p.add_argument('--out',type=Path,required=True);a=p.parse_args()
    changes={'GameServer/lualib/cys_tembank.lua':(HERE/'cys_tembank.lua').read_bytes()}
    rel='GameServer/services/scene/obj/human.lua';s=(R/rel).read_text()
    if '-- CYS-TEMBANK' not in s:
        anchor='    self.bank_bag_container = item_container.new()'
        assert s.count(anchor)==1
        s=s.replace(anchor,'    -- CYS-TEMBANK: distinct persistent storage, never a bank alias.\n    self.cys_tembank = item_container.new()\n    self.cys_tembank:init(120,data.cys_tembank_items,define.CONTAINER_INDEX.HUMAN_BANK)\n    self.cys_tembank_revision=((data.cys_tembank_revision or 0)%2147483646)+1\n'+anchor)
        anchor='        bank_bag_list = self:get_bank_bag_container():get_save_data(),'
        assert s.count(anchor)==1
        s=s.replace(anchor,anchor+'\n        cys_tembank_items = self.cys_tembank:get_save_data(),\n        cys_tembank_revision = self.cys_tembank_revision,')
    changes[rel]=s.encode()
    changes['Game_2/Script/scripts/cys_tembank.lua']=b'''local class=require "class"
local P=class("cys_tembank",require "script_base")
function P:Open(selfId)
 local h=self.scene:get_obj_by_id(selfId)
 if h and h:get_obj_type()=="human" then require("cys_tembank").snapshot(self,h) end
end
function P:Move(selfId,dir,index,revision,world,server,series)
 local h=self.scene:get_obj_by_id(selfId)
 if h and h:get_obj_type()=="human" then require("cys_tembank").move(self,h,dir,index,revision,world,server,series) end
end
function P:TakeAll(selfId,revision)
 local h=self.scene:get_obj_by_id(selfId)
 if h and h:get_obj_type()=="human" then require("cys_tembank").take_all(self,h,revision) end
end
function P:Sort(selfId,revision)
 local h=self.scene:get_obj_by_id(selfId)
 if h and h:get_obj_type()=="human" then require("cys_tembank").sort(self,h,revision) end
end
return P
'''
    rel='Game_2/Script/scripts/scripts.lua';s=(R/rel).read_text();entry='    [990025] = "scripts.cys_tembank",'
    if re.search(r'\[990025\]',s):assert entry in s
    else:
        m=re.search(r'^\s*\[\d+\]\s*=',s,re.M);s=s[:m.start()]+entry+'\n'+s[m.start():]
    changes[rel]=s.encode()
    rel='configs/AllowableScriptFunc.txt';raw=(R/rel).read_bytes()
    if not re.search(rb'\t990025\t',raw):
        ids=[int(line.split(b'\t')[0]) for line in raw.splitlines() if line.split(b'\t')[0].isdigit()]
        raw=raw.rstrip(b'\r\n')+f'\n{max(ids)+1}\t990025\tOpen\n'.encode()
    changes[rel]=raw;a.out.mkdir(parents=True,exist_ok=True)
    for rel,data in changes.items():
        dst=a.out/rel;dst.parent.mkdir(parents=True,exist_ok=True);dst.write_bytes(data)
        if rel.endswith('.lua'):subprocess.run(['luac','-p',str(dst)],check=True)
    if a.apply:
        from give_item import connected
        assert not connected()
        backup=R/'backups'/('tembank-'+datetime.datetime.now().strftime('%Y%m%d-%H%M%S'))
        for rel,data in changes.items():
            dst=R/rel
            if dst.exists():
                saved=backup/rel;saved.parent.mkdir(parents=True,exist_ok=True);saved.write_bytes(dst.read_bytes())
            dst.parent.mkdir(parents=True,exist_ok=True);dst.write_bytes(data)
        print('Backup',backup)
    print('APPLIED' if a.apply else 'PLAN',len(changes),'syntax PASS')
if __name__=='__main__':main()
