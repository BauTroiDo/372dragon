"""Stage/publish the HJ pack while preserving the current CY Play overlays."""
from pathlib import Path
import argparse,datetime,json,re,shutil,subprocess,xml.etree.ElementTree as ET
from hj_appearance_data import ROOT,PLAY,PACK,OUT,sha,json_write
from wardrobe_ui import generate
STAGE=ROOT/'Build/world-gui/stage-hj-appearance-25'
BUILD=ROOT/'Build/cmake/coord-x64/bin'
def digest(p):return sha(p.read_bytes())
def entries():
    out={}
    for row in json.loads((PACK/'wuhun-overrides.json').read_text(encoding='utf8')):
        p=PACK/'MaterialFolder'/row['hj_output'];assert digest(p)==row['sha256']
        out['Overlay/Post/MaterialFolder/'+row['output']]=p
    for folder in ['ConfigFolder','ModelFolder','MaterialFolder','EffectFolder','InterfaceFolder','SoundFolder']:
        for p in (PACK/folder).rglob('*'):
            if not p.is_file():continue
            rel=p.relative_to(PACK).as_posix()
            out['Overlay/Post/'+rel]=p
            if folder=='ConfigFolder':out['Overlay/Pre/'+rel]=p
    layout,controller,_=generate(ROOT/'Assets/CanonicalCY/Data')
    for ext,data in [('layout.xml',layout),('lua',controller)]:
        path=OUT/('NewExterior_DressBox.'+ext);path.write_bytes(data)
        for side in ['Pre','Post']:out[f'Overlay/{side}/InterfaceFolder/NewExterior_DressBox/NewExterior_DressBox.{ext}']=path
    scheme_rel='InterfaceFolder/Schema/WoWLookSkin.scheme.xml'
    raw=(PLAY/'Overlay/Post'/scheme_rel).read_bytes()
    additions=[]
    for rel in json.loads((PACK/'icon-imagesets.json').read_text(encoding='utf8')):
        root=ET.fromstring((PACK/'InterfaceFolder'/rel).read_bytes());name=root.get('Name')
        assert name.encode() not in raw
        additions.append(f'  <Imageset Name="{name}" Filename="{rel}" />'.encode())
    raw=raw.replace(b'</GUIScheme>',b'\r\n'.join(additions)+b'\r\n</GUIScheme>')
    path=OUT/'HJ.scheme.xml';path.write_bytes(raw)
    for side in ['Pre','Post']:out['Overlay/'+side+'/'+scheme_rel]=path
    return out

def stage():
    baseline=json.loads((OUT/'baseline.json').read_text())
    assert digest(PLAY/'Bin64/Game.exe')==baseline['game'] and digest(PLAY/'Bin64/game_data_stage.json')==baseline['manifest']
    if not STAGE.exists():
        STAGE.mkdir()
        for folder in ['Bin64','Patch','Overlay']:shutil.copytree(PLAY/folder,STAGE/folder)
        shutil.copy2(PLAY/'Play.cmd',STAGE/'Play.cmd')
        subprocess.run(['powershell','-NoProfile','-Command',f"New-Item -ItemType Junction -Path '{STAGE/'Data'}' -Target '{ROOT/'Assets/CanonicalCY/Data'}' | Out-Null"],check=True)
    m=json.loads((PLAY/'Bin64/game_data_stage.json').read_text(encoding='utf8'))
    cfg=(PLAY/'Bin64/WXResources.cfg').read_bytes()
    sound=b'FileSystem=*../Overlay/Post/SoundFolder'
    if sound not in cfg:
        cfg=cfg.replace(b'[Brushes]',sound+b'\r\n\r\n[Brushes]')
    (STAGE/'Bin64/WXResources.cfg').write_bytes(cfg)
    m['configs']['WXResources.cfg']=sha(cfg)
    for row in m['binaries']:
        if row['name'] in ('Game.exe','Game.pdb'):
            dst=STAGE/'Bin64'/row['name'];shutil.copy2(BUILD/row['name'],dst);row.update(sha256=digest(dst),bytes=dst.stat().st_size)
    overlays=entries()
    for rel,source in overlays.items():
        dst=STAGE/rel;dst.parent.mkdir(parents=True,exist_ok=True)
        if not dst.exists() or digest(dst)!=digest(source):shutil.copy2(source,dst)
        row=next((r for r in m['overlay'] if r['path']==rel),None)
        if row is None:row={'path':rel,'origin':'HJ20260910 isolated pack','reason':'HJ appearance catalog'};m['overlay'].append(row)
        row.update(sha256=digest(dst),bytes=dst.stat().st_size)
    m['hj_appearance_candidate']={'source':'CYHJ091026','catalog':digest(ROOT/'Registry/hj-appearance-catalog.json'),'tables':digest(PACK/'tables-manifest.json')}
    json_write(STAGE/'Bin64/game_data_stage.json',m)
    json_write(OUT/'candidate-files.json',sorted(overlays))
    print('Staged',len(overlays),'overlay files;',digest(STAGE/'Bin64/Game.exe'))

def release(mode,checks):
    m=json.loads((STAGE/'Bin64/game_data_stage.json').read_text(encoding='utf8'))
    from hj_asset_extension import prove
    extension=prove(STAGE)
    current_manifest=digest(STAGE/'Bin64/game_data_stage.json')
    accepted_manifests={current_manifest,extension['old_manifest_sha256']}
    current_checks=[]
    assert checks
    for folder in checks:
        run=json.loads((folder/'run.json').read_text(encoding='utf-8-sig'))
        log=(folder/'WXClient.log').read_text(encoding='utf8',errors='replace')
        assert run['passed'] and run['game_sha256']==digest(STAGE/'Bin64/Game.exe') and run['stage_manifest_sha256'] in accepted_manifests,folder
        if run['stage_manifest_sha256']==current_manifest:current_checks.append(folder)
        assert 'CYS-WARDROBE-PROBE: RESULT errors=0' in log and 'pass=0' not in '\n'.join(l for l in log.splitlines() if 'CYS-WARDROBE-PROBE:' in l),folder
        render=(folder/'WXRender.log').read_text(encoding='utf8',errors='replace')
        # Ogre exceptions use multiple lines (Model / Animation then Failed!).
        # Treat every animation-state failure as a release blocker; retaining
        # only lines which also name an imported resource missed these failures.
        # CysMaterialSystem.cpp resolveEntity deliberately logs this exact
        # CPU-skinning fallback for a static/fixed-function material pass.
        # It is a supported rendering path, not a missing imported resource.
        skin_fallback=r'^\d\d:\d\d:\d\d: CYS material: software skinning for mesh cys_(?:hj|wh)_[0-9a-f]+\.mesh \(bones per sub-mesh \d+, a pass cannot be paired with a skinning vertex program\)$'
        bad=[l for l in render.splitlines() if '_getAnimationState Failed!' in l or
             (re.search(r'cys_(hj|wh)_',l,re.I) and
              re.search(r'error|exception|failed|unable|not found|could not|cannot|missing|not defined',l,re.I) and
              not re.fullmatch(skin_fallback,l))]
        # The private Wudang scene already lacks these two terrain DDS files;
        # all other Ogre exception blocks (including multiline ones) block.
        baseline_scene=('jpg_wudangscene_3_0.dds','jpg_wudangscene_0_4.dds')
        for block in re.findall(r'An exception has been thrown!.*?Stack unwinding:[^\r\n]*',render,re.S):
            if not any('Description: Cannot locate resource '+name+' in resource group ' in block for name in baseline_scene):bad.append(block)
        assert not bad,('imported resource load error',str(folder),bad[:10])
    texts=[(p/'WXClient.log').read_text(encoding='utf8',errors='replace') for p in checks]
    rides={(int(mount),int(sex)) for t in texts for mount,sex in re.findall(
        r'CYS-HJ-PROBE: rider case=\d+ mount=(\d+) sex=([01])',t)}
    assert rides=={(mount,sex) for mount in (2087,2094,2097,2227) for sex in (0,1)},('rider coverage',rides)
    for relogin in [0,1]:
        completed={int(cat) for t in texts for cat in re.findall(
            r'CYS-HJ-PROBE: functional cat=(\d+) id=\d+ result=\d+ current=\d+ relogin='+str(relogin),t)}
        assert completed=={1,2,3,4,5,6,7,9},('functional/relogin coverage',relogin,completed)
    catalog=json.loads((ROOT/'Registry/hj-appearance-catalog.json').read_text(encoding='utf8'))
    expected=[]
    for cat,groups in catalog['families'].items():
        for family in groups:
            for row in family['variants']:
                if any(row['valid']):expected.append((int(cat),row['id'],row['visual']))
    coverage={0:set(),1:set()}
    for t in texts:
        matches=re.findall(r'CYS-HJ-PROBE: rendered index=(\d+) cat=(\d+) id=(\d+) visual=(\d+) sex=([01])',t)
        if matches:assert re.search(r'CYS-HJ-PROBE: census count=\d+ errors=0',t)
        for match in matches:
            index,cat,id,visual,sex=map(int,match)
            assert expected[index][0:2]==(cat,id) and expected[index][2][sex]==visual
            coverage[sex].add(index)
    for sex,indices in coverage.items():assert indices==set(range(len(expected))),('incomplete census',sex,len(indices),len(expected))
    # Reusing unchanged preview evidence is allowed only after the byte/block
    # proof above. Both sexes must render every affected back entry again, and
    # persistence must be checked using the final additive resource pack.
    current_texts=[(p/'WXClient.log').read_text(encoding='utf8',errors='replace') for p in current_checks]
    backs={(int(index),int(sex)) for t in current_texts for index,sex in re.findall(
        r'CYS-HJ-PROBE: rendered index=(\d+) cat=6 id=\d+ visual=\d+ sex=([01])',t)}
    assert backs=={(i,s) for i,row in enumerate(expected) if row[0]==6 for s in (0,1)},('final back coverage',backs)
    relogin_cats={int(cat) for t in current_texts for cat in re.findall(
        r'CYS-HJ-PROBE: functional cat=(\d+) id=\d+ result=\d+ current=\d+ relogin=1',t)}
    assert relogin_cats=={1,2,3,4,5,6,7,9},('final relogin coverage',relogin_cats)
    assert json.loads((OUT/'restore-result.json').read_text())['full_bson_equal']
    assert json.loads((OUT/'static-validation.json').read_text())['passed']
    baseline=json.loads((OUT/'baseline.json').read_text())
    assert digest(PLAY/'Bin64/Game.exe')==baseline['game'] and digest(PLAY/'Bin64/game_data_stage.json')==baseline['manifest']
    for row in m['binaries']:assert digest(STAGE/'Bin64'/row['name'])==row['sha256']
    assert digest(STAGE/'Bin64/WXResources.cfg')==m['configs']['WXResources.cfg']
    for row in m['overlay']:assert digest(STAGE/row['path'])==row['sha256']
    if mode=='check':print('PASS candidate gates');return
    assert subprocess.run(['powershell','-NoProfile','-Command','[bool](Get-Process Game -ErrorAction SilentlyContinue)'],capture_output=True,text=True,check=True).stdout.strip()=='False'
    stamp=datetime.datetime.now().strftime('%Y%m%d-%H%M%S');backup=ROOT/'Build/backups/hj-appearance-play'/stamp;backup.mkdir(parents=True)
    paths=['Bin64/Game.exe','Bin64/Game.pdb','Bin64/WXResources.cfg']+json.loads((OUT/'candidate-files.json').read_text())
    rollback=[]
    for rel in paths+['Bin64/game_data_stage.json']:
        p=PLAY/rel
        rollback.append({'path':rel,'existed':p.exists(),'before':digest(p) if p.exists() else None})
        if p.exists():dst=backup/rel;dst.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,dst)
    json_write(backup/'rollback-manifest.json',{'play':str(PLAY),'files':rollback})
    for rel in paths:
        dst=PLAY/rel;dst.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(STAGE/rel,dst)
    m['hj_appearance_release']={'at':stamp,'backup':str(backup),'checks':[str(p) for p in checks]}
    json_write(PLAY/'Bin64/game_data_stage.json',m)
    for row in m['binaries']:assert digest(PLAY/'Bin64'/row['name'])==row['sha256']
    for row in m['overlay']:assert digest(PLAY/row['path'])==row['sha256']
    assert digest(PLAY/'Bin64/WXResources.cfg')==m['configs']['WXResources.cfg']
    json_write(OUT/'release-report.json',{'published':True,'play':str(PLAY),'backup':str(backup),
        'game_sha256':digest(PLAY/'Bin64/Game.exe'),'candidate_manifest_sha256':digest(STAGE/'Bin64/game_data_stage.json'),
        'published_manifest_sha256':digest(PLAY/'Bin64/game_data_stage.json'),
        'overlay_files':len(m['overlay']),'binary_files':len(m['binaries']),
        'checks':[str(p) for p in checks],'asset_extension_proof':extension,
        'full_bson_restored':True,'post_copy_hashes_verified':True})
    print('Published and verified',PLAY,'backup',backup)

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('mode',choices=['stage','check','publish']);p.add_argument('--checks',type=Path,nargs='+');a=p.parse_args()
    if a.mode=='stage':stage()
    else:release(a.mode,a.checks)
