"""Snapshot current Play for read-only diagnosis; do not publish or rebuild."""
from pathlib import Path
import hashlib,json,shutil,subprocess
ROOT=Path(__file__).resolve().parents[2];PLAY=ROOT/'Build/world-gui/stage-play-21'
STAGE=ROOT/'Build/world-gui/stage-runtime-audit-01';LOG=ROOT/'Build/Logs/2026-10-01-runtime-audit'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
LOG.mkdir(exist_ok=True);assert not STAGE.exists()
subprocess.run(['powershell','-NoProfile','-Command',"if (Get-Process Game -ErrorAction SilentlyContinue) { exit 1 }"],check=True)
manifest=json.loads((PLAY/'Bin64/game_data_stage.json').read_text(encoding='utf8'))
for r in manifest['binaries']:assert sha(PLAY/'Bin64'/r['name'])==r['sha256']
for folder in ('Bin64','Overlay','Patch'):shutil.copytree(PLAY/folder,STAGE/folder)
shutil.copy2(PLAY/'Play.cmd',STAGE/'Play.cmd')
subprocess.run(['powershell','-NoProfile','-Command',f"New-Item -ItemType Junction -Path '{STAGE/'Data'}' -Target '{(PLAY/'Data').resolve()}' | Out-Null"],check=True)
assert sha(STAGE/'Bin64/game_data_stage.json')==sha(PLAY/'Bin64/game_data_stage.json')
for r in manifest['binaries']:assert sha(STAGE/'Bin64'/r['name'])==r['sha256']
(LOG/'baseline.json').write_text(json.dumps(dict(game=sha(PLAY/'Bin64/Game.exe'),manifest=sha(PLAY/'Bin64/game_data_stage.json'),binaries=manifest['binaries']),indent=2))
print('Staged exact published Play, no code or data changes:',STAGE)
