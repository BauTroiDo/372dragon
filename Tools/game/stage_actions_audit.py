"""Isolated candidate, preserving every current Play overlay and launcher."""
from pathlib import Path
import json,shutil,subprocess
from publish_gameplay_fixes import ROOT,NAMES,sha
from deploy_npc_icons import idle,binaries
idle();stage=ROOT/'Build/world-gui/stage-actions-23';play=ROOT/'Build/world-gui/stage-play-21'
if not stage.exists():
 stage.mkdir()
 for folder in ['Bin64','Patch','Overlay']:shutil.copytree(play/folder,stage/folder)
 shutil.copy2(play/'Play.cmd',stage/'Play.cmd')
 subprocess.run(['powershell','-NoProfile','-Command',f"New-Item -ItemType Junction -Path '{stage/'Data'}' -Target '{ROOT/'Assets/CanonicalCY/Data'}' | Out-Null"],check=True)
m=json.loads((stage/'Bin64/game_data_stage.json').read_text(encoding='utf8'))
for row in m['binaries']:
 if row['name'] in NAMES:
  dst=stage/'Bin64'/row['name'];shutil.copy2(ROOT/'Build/cmake/coord-x64/bin'/row['name'],dst)
  row.update(sha256=sha(dst),bytes=dst.stat().st_size)
m['actions_candidate']={'quickbar':50,'skill_tooltip_column':1}
from patch_selfequip_readability import generate
src=ROOT/'Assets/CanonicalCY/Data/InterfaceFolder/SelfEquip'
layout,lua,report=generate((src/'SelfEquip.layout.xml').read_bytes(),(src/'SelfEquip.lua').read_bytes())
for side in ['Pre','Post']:
 for name,data in [('SelfEquip.layout.xml',layout),('SelfEquip.lua',lua)]:
  path=stage/'Overlay'/side/'InterfaceFolder/SelfEquip'/name;path.write_bytes(data)
  matches=[r for r in m['overlay'] if r['path'].replace('\\','/')==path.relative_to(stage).as_posix()]
  assert len(matches)==1
  matches[0].update(sha256=sha(path),bytes=path.stat().st_size)
m['cy_selfequip_readability']=report
from patch_nbshop_wardrobe import generate as shop_generate
for side in ['Pre','Post']:
 src=play/'Overlay'/side/'InterfaceFolder/YuanbaoShop'
 fallback=ROOT/'Assets/CanonicalCY/Data/InterfaceFolder/YuanbaoShop'
 shop_layout=(src/'YuanbaoShop.layout.xml').read_bytes()
 shop_lua=(src/'YuanbaoShop.lua' if (src/'YuanbaoShop.lua').exists() else fallback/'YuanbaoShop.lua').read_bytes()
 shop_layout,shop_lua=shop_generate(shop_layout,shop_lua)
 for name,data in [('YuanbaoShop.layout.xml',shop_layout),('YuanbaoShop.lua',shop_lua)]:
  path=stage/'Overlay'/side/'InterfaceFolder/YuanbaoShop'/name;path.write_bytes(data)
  rel=path.relative_to(stage).as_posix();rows=[r for r in m['overlay'] if r['path'].replace('\\','/')==rel]
  if not rows:m['overlay'].append({'path':rel,'origin':'wardrobe shop','reason':'empty shelf feedback'});rows=[m['overlay'][-1]]
  rows[0].update(sha256=sha(path),bytes=path.stat().st_size)
from patch_jue_projectile import generate as jue_generate
# Script resources are enumerated, unlike layouts. Mounting the same *.skill in
# Pre/Canonical/Post parses it three times. Replace this one archive completely.
unused=stage/'Overlay/Pre/EffectFolder/all.skill'
if unused.exists():unused.unlink()
m['overlay']=[r for r in m['overlay'] if r['path'].replace('\\','/')!='Overlay/Pre/EffectFolder/all.skill']
for name in ['all.effect','all.particle','all.skill']:
 source=ROOT/'Assets/CanonicalCY/Data/EffectFolder'/name
 effect=jue_generate(source.read_bytes()) if name=='all.skill' else source.read_bytes()
 path=stage/'Overlay/Post/EffectFolder'/name;path.parent.mkdir(parents=True,exist_ok=True);path.write_bytes(effect)
 rel=path.relative_to(stage).as_posix();rows=[r for r in m['overlay'] if r['path'].replace('\\','/')==rel]
 if not rows:m['overlay'].append({'path':rel,'origin':'GL Jue hit markers','reason':'release projectile at first attack beat'});rows=[m['overlay'][-1]]
 rows[0].update(sha256=sha(path),bytes=path.stat().st_size)
cfg=stage/'Bin64/WXResources.cfg';raw=(play/'Bin64/WXResources.cfg').read_bytes()
assert raw.count(b'FileSystem=*../Data/EffectFolder')==1
raw=raw.replace(b'FileSystem=*../Data/EffectFolder',b'FileSystem=*../Overlay/Post/EffectFolder',1)
cfg.write_bytes(raw);m['configs']['WXResources.cfg']=sha(cfg)
(stage/'Bin64/game_data_stage.json').write_text(json.dumps(m,ensure_ascii=False,indent=1)+'\n',encoding='utf8')
binaries(stage,m);print('Candidate',stage,'Game',sha(stage/'Bin64/Game.exe'))
