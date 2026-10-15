"""Check tab geometry/dispatch. Target windows and visual text clipping remain explicit evidence."""
from pathlib import Path
import argparse
import importlib.util
import json
import re
import unittest

ROW = re.compile(r"ROW slot=(\d+) semantic=(-?\d+) shown=(\d) disabled=(-?\d+) mask=(\d) rect_ok=(\d) rect=([\d.,-]+) bytes=(-?\d+) text=\[([^\r\n]*)\]")
OUT = re.compile(r"OUTCOME slot=(\d+) semantic=(-?\d+) disabled=(\d) dispatch_delta=(-?\d+) last=(-?\d+) route=(\w+) target=([\w-]+) target_state=(\w+)")
ENABLED = {1, 2, 3, 5, 10, 17}
_post_spec = importlib.util.spec_from_file_location("selfequip_postclose", Path(__file__).with_name("check_selfequip_postclose.py"))
POSTCLOSE = importlib.util.module_from_spec(_post_spec)
_post_spec.loader.exec_module(POSTCLOSE)


def grade(log, run, readable):
    errors = []
    rows = ROW.findall(log); outcomes = OUT.findall(log)
    if not run.get("passed") or run.get("account") != "test13" or run.get("exit_code") != 0:
        errors.append("world/account/quit failed")
    if [int(r[0]) for r in rows] != list(range(1, 18)):
        errors.append("missing/duplicate census rows")
    if [int(r[0]) for r in outcomes] != list(range(1, 18)):
        errors.append("missing/duplicate click outcomes")
    if not re.search(r"CYS selfequip stats: .*present=63 .*old=0", log):
        errors.append("stats NEW with complete snapshot not measured")
    bounds = re.search(r"BEGIN tabs=17 parent=([\d.,-]+)", log)
    parent = list(map(float, bounds[1].split(","))) if bounds else []
    targets = {}
    for row in rows:
        slot, semantic, shown, disabled, mask, rect_ok = map(int, row[:6])
        if semantic != slot or shown != 1 or rect_ok != 1 or int(row[7]) <= 0 or not row[8]:
            errors.append(f"row {slot}: missing actual visible control/text")
        if disabled != int(slot not in ENABLED) or mask != disabled:
            errors.append(f"row {slot}: enable/mask differs from real lv15 gates")
        x, y, w, h = map(float, row[6].split(","))
        if readable:
            if w < 80 or h < 22:
                errors.append(f"row {slot}: readable cell too small")
            if len(parent) != 4 or x < parent[0]-0.5 or y < parent[1]-0.5 or x+w > parent[0]+parent[2]+0.5 or y+h > parent[1]+parent[3]+0.5:
                errors.append(f"row {slot}: outside tab parent")
    for row in outcomes:
        slot, semantic, disabled, delta, last = map(int, row[:5])
        expected = slot in ENABLED
        if row[5] != "PASS" or semantic != slot or disabled != int(not expected) or delta != int(expected) or (expected and last != slot):
            errors.append(f"slot {slot}: shipping MouseButtonUp route failed")
        targets[row[6]] = row[7]
        if not expected and row[7] != "LOCKED":
            errors.append(f"slot {slot}: disabled tab not locked")
    for name in ("Pet", "Wuhun"):
        if targets.get(name) != "OPEN":
            errors.append(f"implemented target {name} did not open")
    if "DONE measured=17 routed=6 blocked=11 bad=0" not in log or "observer_restored=1" not in log:
        errors.append("incomplete dispatch count or observer not restored")
    clicks = re.findall(r"UP slot=(\d+) kind=0 accepted=(\d) held_ms=(\d+)", log)
    if [int(x[0]) for x in clicks] != list(range(1, 18)) or any(ok != "1" or int(ms) > 190 for _, ok, ms in clicks):
        errors.append("17 valid physical UI gestures not measured")
    if "CYS-SELFEQUIP-GEOM: INVALID" in log or "CYS-UNEQUIP-LIVE: PRECONDITION" in log:
        errors.append("probe invalid")
    if "DoAction (left click) on worn item point=0 -> nothing" not in log or "CYS inv: CGUnEquip" in log:
        errors.append("unequip left backbone changed")
    if not re.search(r"state frame closed: [^\n]*frame_shown=0", log):
        errors.append("SelfEquip remained open")
    if re.findall(r"CYS live: ground click ([123]) [^\n]*reachable=1[^\n]*limit_move=0", log) != ["1", "2", "3"]:
        errors.append("initial replay's three ground clicks missing")
    postclose = POSTCLOSE.grade(log)
    errors.extend("post-close: " + e for e in postclose["errors"])
    return {"status": "FAIL" if errors else "PASS", "errors": errors, "targets": targets, "postclose": postclose,
            "rows": rows, "scope": "tab layout and dispatch; NOT_OPEN targets remain unfinished functionality; visual clipping requires photo review"}


class Tests(unittest.TestCase):
    def fixture(self):
        log = "CYS selfequip stats: obj=350 present=63 changed=63 old=0\nBEGIN tabs=17 parent=0,0,776,52\n"
        for i in range(1, 18):
            disabled = int(i not in ENABLED); x = ((i-1) % 9)*86; y = ((i-1)//9)*27
            log += f"ROW slot={i} semantic={i} shown=1 disabled={disabled} mask={disabled} rect_ok=1 rect={x},{y},84,24 bytes=3 text=[Tab]\n"
            target = {1:"SelfEquip", 2:"SelfData", 3:"Pet", 5:"Wuhun", 10:"ShenDing", 17:"OtherInfo"}.get(i,"not-enabled-for-test13")
            state = "LOCKED" if disabled else "NOT_OPEN" if i in (2,10,17) else "OPEN"
            log += f"UP slot={i} kind=0 accepted=1 held_ms=110\nOUTCOME slot={i} semantic={i} disabled={disabled} dispatch_delta={1-disabled} last={i} route=PASS target={target} target_state={state}\n"
        log += "DONE measured=17 routed=6 blocked=11 bad=0\nobserver_restored=1\nDoAction (left click) on worn item point=0 -> nothing\n"
        for i in range(1, 4): log += f"CYS live: ground click {i} reachable=1 limit_move=0\n"
        return log + POSTCLOSE.fixture(), {"passed":True,"account":"test13","exit_code":0}
    def test_positive_with_stubs_explicit(self): self.assertEqual(grade(*self.fixture(),True)["status"],"PASS")
    def test_missing_row(self):
        log, run=self.fixture(); self.assertEqual(grade(log.replace("ROW slot=17","MISSING slot=17"),run,True)["status"],"FAIL")
    def test_missing_dispatch(self):
        log, run=self.fixture(); self.assertEqual(grade(log.replace("dispatch_delta=1","dispatch_delta=0",1),run,True)["status"],"FAIL")
    def test_small_layout(self):
        log, run=self.fixture(); self.assertEqual(grade(log.replace(",84,24",",36,24"),run,True)["status"],"FAIL")
    def test_unrestored(self):
        log, run=self.fixture(); self.assertEqual(grade(log.replace("observer_restored=1","observer_restored=0"),run,True)["status"],"FAIL")
    def test_enabled_mask(self):
        log, run=self.fixture(); self.assertEqual(grade(log.replace("disabled=0 mask=0","disabled=0 mask=1",1),run,True)["status"],"FAIL")
    def test_preclose_moves_insufficient(self):
        log, run=self.fixture(); self.assertEqual(grade(log.split(POSTCLOSE.PREFIX)[0],run,True)["status"],"FAIL")


if __name__ == "__main__":
    p=argparse.ArgumentParser(); p.add_argument("--base",type=Path); p.add_argument("--readable",type=Path); p.add_argument("--self-test",action="store_true"); args=p.parse_args()
    if args.self_test: unittest.main(argv=[__file__],exit=True)
    if not args.base or not args.readable: p.error("--base and --readable required")
    result={}; runs=[]
    for name, path in (("base",args.base),("readable",args.readable)):
        run=json.loads((path/"run.json").read_text(encoding="utf-8-sig")); runs.append(run)
        result[name]=grade((path/"WXClient.log").read_text(encoding="utf-8",errors="replace"),run,name=="readable")
    same=bool(runs[0].get("game_sha256")) and runs[0]["game_sha256"]==runs[1].get("game_sha256")
    changed=bool(runs[0].get("stage_manifest_sha256")) and runs[0]["stage_manifest_sha256"]!=runs[1].get("stage_manifest_sha256")
    same_text=[r[8] for r in result["base"]["rows"]]==[r[8] for r in result["readable"]["rows"]]
    result["same_game_different_overlay_same_captions"] = same and changed and same_text
    result["status"]="PASS" if same and changed and same_text and all(result[n]["status"]=="PASS" for n in ("base","readable")) else "FAIL"
    print(json.dumps(result,ensure_ascii=False,indent=2)); raise SystemExit(0 if result["status"]=="PASS" else 1)
