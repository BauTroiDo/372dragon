"""Aggregate the October 1 audit; preserve runtime evidence and coverage limits."""
from pathlib import Path
import datetime, hashlib, json, re, subprocess

ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'Build/Logs/2026-10-01-runtime-audit'
def read(name):return json.loads((OUT/name).read_text(encoding='utf8'))
state=json.loads(subprocess.check_output(['wsl','-d','TLBB','-u','root','--','python3',
 '/mnt/c/TLBB/085/CY-Source/Tools/server/provision_test_wsl.py','status']))
state['at']=datetime.datetime.now().astimezone().isoformat()
state['healthy']=all(s['running'] and not s['duplicate'] and s['pid_file_matches'] for s in state['services']) and all(state['ports'].values())
(OUT/'health.json').write_text(json.dumps(state,indent=2))
assert state['healthy'],'Private server still loading or unhealthy; do not finalize'
logs=Path('//wsl.localhost/TLBB/home/ubuntu/cys-test-20260913/log')
p=max(logs.glob('*/Game2_*.log'),key=lambda x:x.stat().st_mtime)
raw=p.read_bytes()
errors=[l for l in raw.splitlines() if b'[E]' in l]
types=sorted({int(n) for line in errors for n in re.findall(rb'\b4928[5-9]\b',line)})
known=bool(errors) and all(re.search(rb'\b4928[5-9]\b',l) and b'monster' in l.lower() for l in errors)
boot=dict(log=p.name,sha256=hashlib.sha256(raw).hexdigest(),tracebacks=raw.count(b'stack traceback'),
 error_lines=len(errors),monster_types=types,known_missing_monsters_only=known)
(OUT/'boot-log-summary.json').write_text(json.dumps(boot,indent=2))
assert not boot['tracebacks'] and (not errors or known),boot
baseline=read('baseline.json');runs=[read(f'gui-{i}/run.json') for i in (1,2)]
play=ROOT/'Build/world-gui/stage-play-21/Bin64/Game.exe'
assert hashlib.sha256(play.read_bytes()).hexdigest()==baseline['game']
for i,r in enumerate(runs,1):
 assert r['exit_code']==0 and not r['terminated_after_timeout'] and r['game_sha256']==baseline['game']
 assert read(f'gui-{i}/server-check.json')['passed']
assert read('restore.json')['full_bson_equal'] and read('verify.json')['full_bson_equal']
net=read('world-net-results/summary.json')
assert len(net['cases'])==19 and all(c['passed'] for c in net['cases'])
log=(OUT/'gui-2/WXClient.log').read_text(encoding='utf8',errors='replace')
assert 'GCShopBuy result=0 item=30602001 count=1' in log
assert 'GCItemInfo applied bag_index=1 item=30602001 count=4' in log
assert 'GCShopBuy received; money=28878965' in log
assert 'what=ui id=84 file=interface\\sound_money.wav' in log
assert re.search(r'CYS audio: mixed[^\n]*source=12[^\n]*audibility=0\.500 playing=1',log)
assert 'CYS-GAMEPLAY-CHECK: RESULT mode=3 errors=0' in log
issues=[
 dict(id=1,issue='Mail repeatedly sent',status='server_repeat_protection_missing_client_loop_not_observed',
      evidence=['offline-contracts.json','Src/Client/WXClient/Procedure/GamePro_Main.cpp:210','Src/Client/WXClient/Network/CysModernGame.cpp:525'],
      detail='Actual mail handler, world insertion and common filter accept each repeat in isolated mocks. Current CY legacy mail packets have no modern translator and are dropped. This does not prove the UI mail feature works or that a live flood occurred.'),
 dict(id=2,issue='Server dump when quitting',status='not_reproduced_two_normal_exits',evidence=['gui-1/run.json','gui-1/server-check.json','gui-2/run.json','gui-2/server-check.json'],
      detail='Both normal quits acknowledged and sockets closed; no new Lua traceback/error in watched intervals. Abrupt process kills and every gameplay state were not tested.'),
 dict(id=3,issue='Cannot log in after long idle',status='long_client_idle_unverified',evidence=['gui-1/run.json','server-before.json','world-net-results/summary.json'],
      detail='Login succeeded on private Game process started September 29, before any restart in this audit. No multi-hour client idle soak was performed. Deadline and failure-path network tests passed.'),
 dict(id=4,issue='Scene/background hangs at server selection',status='not_reproduced_two_gui_logins',evidence=['gui-1/run.json','gui-2/run.json'],
      detail='Both GUI sessions reached character selection and entered scene 2. Other machine/network/server combinations remain untested.'),
 dict(id=5,issue='Bag flashes on buying',status='full_refresh_confirmed_visible_flicker_not_proven',
      evidence=['Src/Client/WXClient/Network/CysModernHandlers.cpp:969','Src/Client/WXClient/Action/GMActionSystem.cpp:945','Build/world-gui/stage-play-21/Overlay/Post/InterfaceFolder/Packet/Packet.lua:210','gui-2/WXClient.log'],
      detail='GCNotifyEquip and GCItemInfo each refresh bag actions; Lua rebuilds the whole displayed tab. A successful purchase updated the stack; static shots do not establish frame-level flicker.'),
 dict(id=6,issue='Missing purchase sound',status='working_in_tested_npc_purchase',evidence=['gui-2/WXClient.log:2337','buy-sound-table.json'],
      detail='One 30602001 bought successfully: count 3 to 4, money 28879065 to 28878965. SoundInfo 84 sound_money.wav played and was mixed with audibility 0.500. Other shop types not exercised.'),
 dict(id=7,issue='Login character model display',status='visible_for_test15',
      evidence=['gui-1/cys-gl-332942984-existing-character-selection.png'],
      detail='Visually checked body, clothing, weapon and soul effect. This is one character, not all races/appearance combinations.'),
 dict(id=8,issue='Stuck maps',status='not_reproduced_in_scene2_all_maps_unverified',evidence=['gui-1/run.json','gui-2/run.json','world-net-results/summary.json'],
      detail='Movement and collision/navmesh loading worked in scene 2. Simulated transfer/refusal/timeout tests passed; all real portals and destinations were not traversed.'),
 dict(id=9,issue='GM commands missing/nonfunctional',status='confirmed_chat_gm_defects',evidence=['offline-contracts.json'],
      detail='Chat GM is gated to local/debug while runtime uses publish_yu. Help is empty. Invalid money, yuanbao, absent monster and trap cause Lua errors in actual source with synthetic dependencies. Valid tp dispatches. GUI GMTool is a separate path and not declared broken by these tests.'),
 dict(id=10,issue='Missing qinggong shortcut/logic',status='logic_passed_shortcut_exists_in_source',
      evidence=['Src/Client/WXClient/Cursor/CursorMng.cpp:640','Src/Client/WXClient/Network/CysLeapNet.cpp:66','gui-2/WXClient.log:2435'],
      detail='Ctrl + left terrain click selects MCT_LEAP for learned qinggong. GUI probe exercised AI skill34 directly: takeoff, input lock, original landing target, unlock and movement passed. Physical keyboard shortcut itself was not injected in this run.'),
 dict(id=11,issue='Equipment repair-count display',status='confirmed_incomplete_binding_and_data_mapping',
      evidence=['Src/Client/LuaApiGen/LuaApiGen_Cy.cpp:54','Src/Client/WXClient/Network/CysModernHandlers.cpp:521','Src/Shared/ProtocolGen/PgStructs.h:703'],
      detail='GetRemainRepairCount remains a generated stub. Server repair-failure counter is unknow_7; ToLegacyItem clears the item and never maps this byte to m_FaileTimes. Remaining repairs and used/failure count need correct GL/CY semantics, not a fabricated constant.')]
report=dict(at=state['at'],scope='Current CY Play on isolated private CY server; source audit and two short GUI sessions',
            game_sha256=baseline['game'],published_game_unchanged=True,gameplay_fixes_applied=False,
            original_test15_bson_restored=True,healthy_after_restore=True,gui_runs=2,network_cases_passed=19,
            source_contract_findings=read('offline-contracts.json')['findings'],issues=issues,
            residual_boot_errors=boot)
(OUT/'report.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf8')
print(json.dumps(dict(report=str(OUT/'report.json'),issues=len(issues),gui_runs=2,network_cases_passed=19,
 healthy=True,restored=True,boot=boot),ensure_ascii=False))
