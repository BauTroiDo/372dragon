"""Check opt-in SelfEquip stats logs. UI geometry remains a separate visual A/B."""
from pathlib import Path
import argparse
import importlib.util
import json
import re
import unittest

KEYS = ("CRITICALATTACK", "CRITICALDEFENCE", "VIGOR", "MAXVIGOR", "ENERGY", "MAXENERGY")
WIDGETS = ("SelfEquip_Perporty8", "SelfEquip_Perporty9", "SelfEquip_Vigor", "SelfEquip_Energy")
_post_spec = importlib.util.spec_from_file_location("selfequip_postclose", Path(__file__).with_name("check_selfequip_postclose.py"))
POSTCLOSE = importlib.util.module_from_spec(_post_spec)
_post_spec.loader.exec_module(POSTCLOSE)


def grade(log, run, old):
    errors = []
    if not run.get("passed") or run.get("account") != "test13" or run.get("exit_code") != 0:
        errors.append("world/account/exit did not pass")
    rows = re.findall(r"CYS selfequip stats: obj=\d+ present=(\d+) changed=\d+ flags3=\d+ flags9=\d+ critical=(\d+)/(\d+) vigor=(\d+)/(\d+) energy=(\d+)/(\d+) old=([01])", log)
    full = [r for r in rows if int(r[0]) == 63 and int(r[-1]) == int(old)]
    if not full:
        errors.append("missing complete packet-backed snapshot or wrong stats arm")
    values = {}
    for key, ok, number, value in re.findall(r"CYS-SELFEQUIP-STATS: key=(\w+) ok=(\d) number=(\d) value=(-?\d+)", log):
        if key in values:
            errors.append("duplicate key measurement")
        if ok != "1" or number != "1":
            errors.append("Lua key call failed")
        values[key] = int(value)
    if set(values) != set(KEYS):
        errors.append("six Lua keys not all measured")
    expected = [-1] * 6 if old else list(map(int, full[-1][1:7])) if full else []
    if expected and [values.get(k) for k in KEYS] != expected:
        errors.append("Lua values differ from expected arm/packet snapshot")
    if not old and expected and expected[2:] != [60, 60, 50, 50]:
        errors.append("resources differ from authorized test13 census")
    actual = {}
    for name, size, text in re.findall(r"CYS-SELFEQUIP-STATS: widget=(\w+) bytes=(-?\d+) text=\[([^\r\n]*)\]", log):
        if int(size) <= 0:
            errors.append("widget text missing")
        actual[name] = text
    if len(expected) == 6:
        text_values = [str(expected[0]), str(expected[1]), f"{expected[2]}/{expected[3]}", f"{expected[4]}/{expected[5]}"]
        if actual != dict(zip(WIDGETS, text_values)):
            errors.append("actual rendered strings differ from six expected values")
    if "DoAction (left click) on worn item point=0 -> nothing" not in log:
        errors.append("left click did not reach shipping C++ action")
    if "CYS inv: CGUnEquip" in log or "CYS inv: GCUnEquipResult" in log:
        errors.append("read-only left arm changed equipment")
    if not re.search(r"state frame closed: [^\n]*frame_shown=0", log):
        errors.append("SelfEquip not closed")
    clicks = re.findall(r"CYS live: ground click ([123]) [^\n]*reachable=1[^\n]*limit_move=0", log)
    if clicks != ["1", "2", "3"] or len(re.findall(r"CYS: click-move [^\n]*sent=[1-9]", log)) < 3:
        errors.append("three successful ground moves not measured")
    if "CYS-SELFEQUIP-STATS: INVALID" in log or "CYS-UNEQUIP-LIVE: PRECONDITION" in log:
        errors.append("probe invalid")
    postclose = POSTCLOSE.grade(log)
    errors.extend("post-close: " + e for e in postclose["errors"])
    return {"status": "FAIL" if errors else "PASS", "errors": errors, "keys": values, "widgets": actual, "postclose": postclose}


def fixture(old=False):
    nums = [-1] * 6 if old else [19, 7, 60, 60, 50, 50]
    log = f"CYS selfequip stats: obj=350 present=63 changed=63 flags3=96 flags9=30 critical=19/7 vigor=60/60 energy=50/50 old={int(old)}\n"
    log += "\n".join(f"CYS-SELFEQUIP-STATS: key={k} ok=1 number=1 value={v}" for k, v in zip(KEYS, nums)) + "\n"
    texts = [str(nums[0]), str(nums[1]), f"{nums[2]}/{nums[3]}", f"{nums[4]}/{nums[5]}"]
    log += "\n".join(f"CYS-SELFEQUIP-STATS: widget={k} bytes={len(v)} text=[{v}]" for k, v in zip(WIDGETS, texts))
    log += "\nDoAction (left click) on worn item point=0 -> nothing\n"
    for i in range(1, 4):
        log += f"CYS live: ground click {i} reachable=1 limit_move=0\nCYS: click-move sent=1\n"
    return log + POSTCLOSE.fixture(), {"passed": True, "account": "test13", "exit_code": 0}


class Tests(unittest.TestCase):
    def test_new(self): self.assertEqual(grade(*fixture(), False)["status"], "PASS")
    def test_old(self): self.assertEqual(grade(*fixture(True), True)["status"], "PASS")
    def test_missing_presence(self):
        log, run = fixture(); self.assertEqual(grade(log.replace("present=63", "present=31"), run, False)["status"], "FAIL")
    def test_wrong_text(self):
        log, run = fixture(); self.assertEqual(grade(log.replace("text=[60/60]", "text=[-1/-1]"), run, False)["status"], "FAIL")
    def test_wrong_critical(self):
        log, run = fixture(); self.assertEqual(grade(log.replace("critical=19/7", "critical=20/7"), run, False)["status"], "FAIL")
    def test_missing_move(self):
        log, run = fixture(); self.assertEqual(grade(log.replace("ground click 3", "ground click 4"), run, False)["status"], "FAIL")
    def test_failed_lua(self):
        log, run = fixture(); self.assertEqual(grade(log.replace("ok=1", "ok=0", 1), run, False)["status"], "FAIL")
    def test_wrong_arm(self): self.assertEqual(grade(*fixture(), True)["status"], "FAIL")
    def test_preclose_moves_insufficient(self):
        log, run = fixture(); self.assertEqual(grade(log.split(POSTCLOSE.PREFIX)[0], run, False)["status"], "FAIL")


if __name__ == "__main__":
    p = argparse.ArgumentParser()
    p.add_argument("--old", type=Path); p.add_argument("--new", type=Path)
    p.add_argument("--self-test", action="store_true")
    args = p.parse_args()
    if args.self_test:
        unittest.main(argv=[__file__], exit=True)
    if not args.old or not args.new: p.error("provide both --old and --new run directories")
    verdict = {}; runs = []
    for name, path, old in [("old", args.old, True), ("new", args.new, False)]:
        run = json.loads((path / "run.json").read_text(encoding="utf-8-sig")); runs.append(run)
        verdict[name] = grade((path / "WXClient.log").read_text(encoding="utf-8", errors="replace"), run, old)
    same = all(runs[0].get(k) and runs[0].get(k) == runs[1].get(k) for k in ("game_sha256", "stage_manifest_sha256", "account"))
    verdict["same_stage_and_account"] = same
    verdict["status"] = "PASS" if same and all(verdict[k]["status"] == "PASS" for k in ("old", "new")) else "FAIL"
    print(json.dumps(verdict, indent=2))
    raise SystemExit(0 if verdict["status"] == "PASS" else 1)
