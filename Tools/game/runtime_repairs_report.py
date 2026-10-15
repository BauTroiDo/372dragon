"""Summarize verified runtime repairs without copying private account traffic."""
from pathlib import Path
import datetime,hashlib,json
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'Build/Logs/2026-10-01-runtime-fixes'
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
release=read(OUT/'release-report.json')
runs=[]
for field in ('gui','relogin'):
 p=Path(release[field]);r=read(p/'run.json')
 assert r['passed'] and read(p/'server-check.json')['passed']
 runs.append(dict(path=str(p),passed=True,game=r['game_sha256'],checks=r['checks']))
report=dict(
 at=datetime.datetime.now().astimezone().isoformat(),
 scope='CY source-built Play and private CY server /home/ubuntu/cys-test-20260913',
 release=release,gui_runs=runs,server_contracts=read(OUT/'server-tests.json'),
 lua_ui=read(OUT/'ui-tests.json'),navigation=read(OUT/'live-result.json'),
 visual_review=read(OUT/'visual-review.json'),purchase_persisted=read(OUT/'purchase-persisted.json'),
 original_test15=read(OUT/'verify.json'),health=read(OUT/'health.json'),
 boot_baseline=read(OUT/'boot-log-summary.json'),
 repaired=[
  'Player-mail admission at both agent and world: 5-second interval, 10 per minute, identical recipient/content blocked for 60 seconds; reconnect does not bypass world guard; system mail independent.',
  'Bag purchase deltas refresh the changed action/slot instead of rebuilding the entire visible tab.',
  'GM chat uses existing GMTool authority in publish profile; help and practical aliases; parameter, ID, overflow and stale-owner checks.',
  'GM teleport validates exact client triangle walkability and bounds; unknown trap ID rejected before object allocation.',
  'Equipment repair failure byte is preserved from server; Lua remaining-repair binding and tooltip use the server limit of three failed advanced repairs.'
 ],
 tested_existing_behaviors=[
  'Character selection, scene 2 entry and terrain clicks, movement after closing inventory, normal acknowledged quit without a client dump or new server error.',
  'NPC purchase of 30602001 adds one item and debits 100 base currency units; sound_money.wav plays.',
  'Relogin retains the resulting money, item count and repair counters.'
 ],
 limitations=[
  'No multi-hour idle-client soak; this work does not establish that every long-idle login failure is resolved.',
  'No exhaustive traversal of all maps or every abnormal-disconnect/gameplay state.',
  'Legacy client mail packets still lack a modern translator; server spam protection does not establish full UI mail functionality.',
  'Prior audit exercised qinggong AI lock/landing/unlock, but did not inject the physical Ctrl+left-click shortcut.',
  'Five existing missing monster configurations 49285 through 49289 remain in the private-server boot log.'
 ])
assert report['original_test15']['full_bson_equal'] and report['health']['healthy']
(OUT/'report.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf8')
print('Wrote verified runtime repair report')
