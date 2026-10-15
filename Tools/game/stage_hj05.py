"""Stage the HJ05 client and UI with opt-in probes; leave Play unchanged until verified."""
from pathlib import Path
import json,shutil,subprocess
from hj05_ui import files as ui_files
from deploy_mount_flight import idle,binaries
from publish_gameplay_fixes import ROOT,sha
PLAY=ROOT/'Build/world-gui/stage-play-21';STAGE=ROOT/'Build/world-gui/stage-hj05-28'
LOG=ROOT/'Build/Logs/2026-09-28-hj05-fixes'
idle()
if not STAGE.exists():
    STAGE.mkdir()
    for name in ['Bin64','Patch','Overlay']:shutil.copytree(PLAY/name,STAGE/name)
    shutil.copy2(PLAY/'Play.cmd',STAGE/'Play.cmd')
    subprocess.run(['powershell','-NoProfile','-Command',f"New-Item -ItemType Junction -Path '{STAGE/'Data'}' -Target '{ROOT/'Assets/CanonicalCY/Data'}' | Out-Null"],check=True)
baseline=LOG/'play-baseline.json'
if not baseline.exists():baseline.write_text(json.dumps({'game':sha(PLAY/'Bin64/Game.exe'),'manifest':sha(PLAY/'Bin64/game_data_stage.json')}))
m=json.loads((PLAY/'Bin64/game_data_stage.json').read_text(encoding='utf8'))
for row in m['binaries']:
    if row['name'] in ('Game.exe','Game.pdb'):
        dst=STAGE/'Bin64'/row['name'];shutil.copy2(ROOT/'Build/cmake/coord-x64/bin'/row['name'],dst)
        row.update(sha256=sha(dst),bytes=dst.stat().st_size)
newui=ui_files(STAGE)
names={r['path'] for r in newui}
m['overlay']=[r for r in m['overlay'] if r['path'] not in names]+newui
m['hj05_probe_candidate']={'modes':[3,4,5,6],'server':sha(LOG/'server/manifest.json')}
(STAGE/'Bin64/game_data_stage.json').write_text(json.dumps(m,ensure_ascii=False,indent=1)+'\n',encoding='utf8')
binaries(STAGE,m)
for row in m['overlay']:assert sha(STAGE/row['path'])==row['sha256'],row['path']
print('Candidate',STAGE,'Game',sha(STAGE/'Bin64/Game.exe'))
