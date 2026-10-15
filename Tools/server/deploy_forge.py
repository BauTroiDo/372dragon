"""Install/check/revert timing forge on the owned private server only."""
from pathlib import Path
import argparse,datetime,hashlib,json,shutil,subprocess
R=Path('/home/ubuntu/cys-test-20260913')
HERE=Path(__file__).resolve().parent
MODULE='GameServer/lualib/cys_forge.lua'
MARK='-- CYS-FORGE 23/09'

def patch(text,old,new):
    assert text.count(old)==1,old
    return text.replace(old,new,1)

def changes():
    out={MODULE:(HERE/'cys_forge.lua').read_bytes()}
    rel='Game_2/Script/scripts/event/equip/equip_enhance.lua';text=(R/rel).read_text(encoding='utf8')
    if MARK not in text:
        for name,signature in [('FinishEnhance','selfId, itemidx1, itemidx2 '),('DoFinishEnhance','selfId, itemidx1, itemidx2'),('DoQuickQiangHuaByYB','selfId, ItemPos, check')]:
            head=f'function equip_enhance:{name}({signature})'
            text=patch(text,head,head+'\n    '+MARK+' legacy rolls/paid shortcuts cannot bypass Space.\n    do self:notify_tips(selfId,"Hãy dùng khung Nhịp rèn để cường hoá bằng Space."); return end')
        methods='\n'+MARK+' new functions on the existing, permitted script 809262.\n'
        for name,fn,args in [('Quote','quote','slot,seq'),('Begin','begin','slot,material,seq'),('Strike','strike','nonce,elapsed'),('Cancel','cancel','seq')]:
            methods+=f'function equip_enhance:CysForge{name}(selfId,{args})\n    local h=self.scene:get_obj_by_id(selfId)\n    if h and h:get_obj_type()=="human" then require("cys_forge").{fn}(self,h,{args}) end\nend\n'
        text=patch(text,'return equip_enhance',methods+'\nreturn equip_enhance')
    out[rel]=text.encode()
    rel='GameServer/services/scene/obj/human.lua';text=(R/rel).read_text(encoding='utf8')
    if MARK not in text:
        line='self:init_contaioners(data)'
        # Insert on the next line so the existing inline comment remains intact.
        lines=text.splitlines(keepends=True);indices=[i for i,s in enumerate(lines) if line in s];assert len(indices)==1
        lines.insert(indices[0]+1,'    '+MARK+' recover a charged unfinished attempt after reload.\n    require("cys_forge").recover(self,data.cys_forge)\n')
        text=''.join(lines)
        text=patch(text,'function human:get_save_data()\n    return {','function human:get_save_data()\n    return {\n        cys_forge = self.cys_forge or false,')
    out[rel]=text.encode()
    rel='GameServer/services/scene/scenecore.lua';text=(R/rel).read_text(encoding='utf8')
    if MARK not in text:
        anchor='    obj._leaving = true\n'
        text=patch(text,anchor,'    '+MARK+' settle before the leave snapshot; no refund or lock survives logout.\n    require("cys_forge").finish(obj,false,true)\n'+anchor)
    out[rel]=text.encode()
    return out

def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('mode',choices=['check','apply','verify','revert']);p.add_argument('--backup',type=Path);a=p.parse_args()
    assert R.resolve()==R
    if a.mode=='revert':
        assert a.backup and a.backup.resolve().is_relative_to(R/'backups')
        record=json.loads((a.backup/'manifest.json').read_text())
        for row in record:
            dest=R/row['path']
            if row['existed']:shutil.copy2(a.backup/row['path'],dest)
            else:
                # Retain the unused module; reverting the callers makes it inert.
                print('Unused new file retained:',dest)
        print('Reverted callers; restart private server to load restored code');return
    generated=changes()
    temp=R/'backups/forge-syntax';temp.mkdir(parents=True,exist_ok=True)
    for i,(rel,data) in enumerate(generated.items()):
        path=temp/f'{i}.lua';path.write_bytes(data);subprocess.run(['luac','-p',str(path)],check=True)
    changed=[rel for rel,data in generated.items() if not (R/rel).exists() or (R/rel).read_bytes()!=data]
    if a.mode=='verify':assert not changed,changed
    if a.mode=='apply' and changed:
        # Follow existing private tools: no client may be connected during installation.
        from give_item import connected
        assert not connected(),'private clients still connected'
        backup=R/'backups'/('forge-'+datetime.datetime.now().strftime('%Y%m%d-%H%M%S'));backup.mkdir()
        rows=[]
        for rel in changed:
            dst=R/rel;row={'path':rel,'existed':dst.exists()}
            if dst.exists():
                row['sha256']=hashlib.sha256(dst.read_bytes()).hexdigest();save=backup/rel;save.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(dst,save)
            rows.append(row)
        (backup/'manifest.json').write_text(json.dumps(rows,indent=2))
        for rel in changed:(R/rel).write_bytes(generated[rel])
        print('Backup:',backup)
    print(json.dumps({'syntax':'PASS','mode':a.mode,'changed':changed},indent=2))
if __name__=='__main__':main()
