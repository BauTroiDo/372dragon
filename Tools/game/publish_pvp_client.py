"""Publish PvP Game.exe only after six matching feature runs. Caller holds game slot."""
import argparse,datetime,json,shutil,subprocess
from pathlib import Path
from publish_inventory_client import ROOT,sha

def main():
    p=argparse.ArgumentParser(description=__doc__)
    markers={
        'negative':'CYS PVP-LIVE step=1 FAIL',
        'mode':'CYS PVP-LIVE mode PASS',
        'free':'CYS PVP-LIVE PASS mode=4 free PK combat',
        'safe':'CYS PVP-LIVE PASS mode=5 safe zone rejected attacks',
        'arena':'CYS PVP-LIVE PASS mode=2 arena reject accept transfer combat',
        'receive':'CYS PVP-LIVE PASS mode=3 received invitation accepted through CY UI',
    }
    for name in markers:p.add_argument('--'+name,type=Path,required=True)
    args=p.parse_args();test=ROOT/'Build/world-gui/stage-equipment-skills-23/Bin64';play=ROOT/'Build/world-gui/stage-play-21/Bin64';build=ROOT/'Build/cmake/coord-x64/bin'
    evidence={}
    for name,marker in markers.items():
        folder=getattr(args,name);r=json.loads((folder/'run.json').read_text(encoding='utf-8-sig'));log=(folder/'WXClient.log').read_text(encoding='utf8',errors='replace')
        assert r['passed'] and r['account']=='test15',name
        assert r['game_sha256']==sha(test/'Game.exe'),name
        assert r['stage_manifest_sha256']==sha(test/'game_data_stage.json'),name
        assert marker in log and 'CYS-CRASHRPT' not in log,name
        if name=='negative':assert 'missing host function Player:ChangePVPMode' in log,name
        else:assert 'CYS Lua failure' not in log and 'CYS PVP-LIVE Lua FAIL' not in log and 'CYS PVP-LIVE FAIL' not in log,name
        if name in ('free','safe','arena','receive'):
            peer=json.loads(Path(str(folder)+'-peer','result.json').read_text(encoding='utf8'))
            assert peer['guid']==200015 and peer['exit_code']==0 and peer['terminal']=='quit_complete' and peer['quit_flag']==0,name+' peer quit'
            assert peer['decode_failures']==0 and peer['moves_sent']>=1,name+' peer motion/decode'
            if name in ('free','arena'):assert peer['core']['damage_taken']>0,name+' peer HP'
            if name=='safe':assert peer['core']['damage_taken']==0,name+' peer HP'
            if name=='arena':assert peer['transfers']>=2 and peer['core']['final_scene']==0 and peer['core']['final_pos']==[180,328],name+' arena exit'
        evidence[name]=dict(path=str(folder),started=r['started'],finished=r['finished'])
    result=subprocess.run(['powershell','-NoProfile','-Command','[bool](Get-Process Game -ErrorAction SilentlyContinue)'],capture_output=True,text=True,check=True)
    assert result.stdout.strip()=='False','Game must be closed'
    manifest=play/'game_data_stage.json';current=json.loads(manifest.read_text(encoding='utf8'));tested=json.loads((test/'game_data_stage.json').read_text(encoding='utf8'))
    for base,data in ((play,current),(test,tested)):
        for row in data['binaries']:assert sha(base/row['name'])==row['sha256'],row['name']
    runtimes=lambda d:{r['name']:r['sha256'] for r in d['binaries'] if r['name'].lower().endswith(('.dll','.exe'))}
    before,after=runtimes(current),runtimes(tested)
    assert set(before)==set(after)
    assert all(before[k]==after[k] for k in before if k!='Game.exe'),'unexpected DLL change'
    assert sha(build/'Game.exe')==after['Game.exe']
    stamp=datetime.datetime.now().strftime('%Y%m%d-%H%M%S');backup=ROOT/'Build/backups/pvp-play'/stamp;backup.mkdir(parents=True,exist_ok=False)
    names=('Game.exe','Game.pdb');launcher=play/'Run-CY-Server.cmd';raw=launcher.read_bytes();anchor=b'set "CYS_WORLD_REPLAY="';assert raw.count(anchor)==1
    for flag in ('CYS_PVP_LIVE','CYS_PVP_OLD'):
        line=('set "'+flag+'="').encode('ascii')
        if line not in raw:raw=raw.replace(anchor,anchor+b'\r\n'+line)
    for name in names+('game_data_stage.json','Run-CY-Server.cmd'):shutil.copy2(play/name,backup/name)
    records=[]
    for row in current['binaries']:
        if row['name'] in names:
            dest=play/row['name'];old=sha(dest);shutil.copy2(build/row['name'],dest);row.update(sha256=sha(dest),bytes=dest.stat().st_size);records.append(dict(path=row['name'],before=old,after=row['sha256']))
    launcher.write_bytes(raw)
    for row in current['wsl_test']['launchers']:
        if row['path']=='Bin64/Run-CY-Server.cmd':row.update(sha256=sha(launcher),bytes=launcher.stat().st_size)
    evidence.update(at=stamp,backup=str(backup),files=records);current['pvp_integrity_update']=evidence
    manifest.write_text(json.dumps(current,ensure_ascii=False,indent=1)+'\n',encoding='utf8',newline='\n')
    for row in current['binaries']:assert sha(play/row['name'])==row['sha256']
    (backup/'deployment.json').write_text(json.dumps(evidence,ensure_ascii=False,indent=2),encoding='utf8')
    print(json.dumps(evidence,ensure_ascii=False,indent=2))
if __name__=='__main__':main()
