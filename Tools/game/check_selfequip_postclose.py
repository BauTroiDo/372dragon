"""Require movement after SelfEquip closes; initial replay clicks never satisfy this gate."""
from pathlib import Path
import argparse
import json
import math
import re
import unittest

PREFIX = "CYS-SELFEQUIP-POSTMOVE: "
NUMBER = r"-?\d+(?:\.\d+)?"
POINT = rf"({NUMBER}),({NUMBER})"
REQUEST = re.compile(rf"{PREFIX}REQUEST index=(\d+) frame_shown=(\d) from={POINT}")
OBSERVED = re.compile(rf"{PREFIX}OBSERVED index=(\d+) frame_shown=(\d) from={POINT} to={POINT} distance_m=({NUMBER}) elapsed_ms=(\d+)")
GROUND = re.compile(rf"CYS live: ground click (\d+) from {POINT} to {POINT} navmesh=(\d) reachable=(\d) waypoints=(\d+) limit_move=(\d)")
SENT = re.compile(rf"CYS: click-move \({POINT}\)->\({POINT}\) waypoints=(\d+) sent=(\d+)")
PICK = re.compile(rf"CYS camera: click-pick (\d+) screen=\(-?\d+,-?\d+\) target=\({POINT}\) picked=\({POINT}\) error_m=({NUMBER})")


def grade(log):
    errors = []
    close = list(re.finditer(r"CYS-UNEQUIP-LIVE: state frame closed: [^\r\n]*frame_shown=0", log))
    begin = list(re.finditer(re.escape(PREFIX) + r"BEGIN frame_shown=0 path=LiveGroundClick_Player_MoveTo first_index=4", log))
    done = list(re.finditer(re.escape(PREFIX) + rf"DONE clicks=3 path_m=({NUMBER}) frame_shown=0", log))
    finish = list(re.finditer(r"CYS world smoke: world script finished", log))
    requests, observed = list(REQUEST.finditer(log)), list(OBSERVED.finditer(log))
    expected = [4, 5, 6]
    for name, matches in (("frame close", close), ("BEGIN", begin), ("DONE", done), ("world finish", finish)):
        if len(matches) != 1:
            errors.append(f"expected exactly one {name}")
    if [int(m[1]) for m in requests] != expected or [int(m[1]) for m in observed] != expected:
        errors.append("expected exactly requests/observations 4,5,6; initial clicks do not count")
    if len(re.findall(re.escape(PREFIX) + r"(?:BEGIN|DONE|REQUEST|OBSERVED)\b", log)) != 8:
        errors.append("missing, malformed or duplicate post-close record")
    if "CYS-UNEQUIP-LIVE: PRECONDITION" in log or PREFIX + "INVALID" in log:
        errors.append("probe invalid")
    if len(close) == len(begin) == len(done) == len(finish) == 1 and len(requests) == len(observed) == 3:
        ordered = [close[0].start(), begin[0].start()]
        for request, observation in zip(requests, observed):
            ordered.extend((request.start(), observation.start()))
        ordered.extend((done[0].start(), finish[0].start()))
        if ordered != sorted(set(ordered)):
            errors.append("required close -> BEGIN -> requests/observations -> DONE -> finish order violated")
        restored = list(re.finditer(r"CYS-UNEQUIP-LIVE: state restored: [^\r\n]*frame_shown=0", log))
        took_off = re.search(r"CYS-UNEQUIP-LIVE: RESULT [^\r\n]*taken_off=1", log)
        if took_off and (len(restored) != 1 or not close[0].start() < restored[0].start() < begin[0].start()):
            errors.append("removed equipment was not restored before post-close movement")
        if any(not close[0].start() < r.start() < begin[0].start() for r in restored):
            errors.append("restore must precede post-close movement")
    distances = []
    measurements = []
    for request, observation in zip(requests, observed):
        index = int(request[1])
        origin = tuple(map(float, request.group(3, 4)))
        before = tuple(map(float, observation.group(3, 4)))
        after = tuple(map(float, observation.group(5, 6)))
        distance = math.dist(before, after)
        reported = float(observation[7])
        elapsed = int(observation[8])
        distances.append(distance)
        measurements.append({"index": index, "from": before, "to": after, "displacement_m": distance, "elapsed_ms": elapsed})
        if int(observation[1]) != index or request[2] != "0" or observation[2] != "0":
            errors.append(f"move {index}: index mismatch or frame open")
        if origin != before or not all(map(math.isfinite, (*before, *after, reported))) or distance < .5 or abs(distance - reported) > .005:
            errors.append(f"move {index}: actual position/displacement invalid")
        if elapsed < 2500:
            errors.append(f"move {index}: observed before 2500ms")
        block = log[request.end():observation.start()]
        ground, packets = list(GROUND.finditer(block)), list(SENT.finditer(block))
        if len(ground) != 1 or len(re.findall(r"CYS live: ground click \d+", block)) != 1:
            errors.append(f"move {index}: missing/duplicate ground request")
            continue
        g = ground[0]
        target = tuple(map(float, g.group(4, 5)))
        if int(g[1]) != index or g[6] != "1" or g[7] != "1" or int(g[8]) < 1 or g[9] != "0" or math.dist(origin, tuple(map(float, g.group(2, 3)))) > .02:
            errors.append(f"move {index}: ground request was not reachable/unlimited or did not start here")
        # ClickGround substitutes the camera-picked target when error < 1m.
        # Compare the packet with that actual destination, not the earlier nav candidate.
        picks = list(PICK.finditer(block))
        if len(picks) > 1:
            errors.append(f"move {index}: duplicate camera pick")
        if len(picks) == 1:
            pick = picks[0]
            if int(pick[1]) != index or math.dist(target, tuple(map(float, pick.group(2, 3)))) > .02:
                errors.append(f"move {index}: camera pick differs from request")
            if float(pick[6]) < 1:
                target = tuple(map(float, pick.group(4, 5)))
        sent = [p for p in packets if p.start() > g.start() and int(p[5]) > 0 and int(p[6]) > 0
                and math.dist(origin, tuple(map(float, p.group(1, 2)))) < .16
                and math.dist(target, tuple(map(float, p.group(3, 4)))) < .16]
        if not sent:
            errors.append(f"move {index}: no matching sent click-move before observation")
    total = sum(distances)
    if not math.isfinite(total) or total < 2:
        errors.append("actual post-close displacement sum below 2m")
    if len(done) == 1 and abs(float(done[0][1]) - total) > .01:
        errors.append("DONE path differs from actual position measurements")
    return {"status": "FAIL" if errors else "PASS", "errors": errors, "moves": measurements,
            "displacement_sum_m": total,
            "scope": "LiveGroundClick -> Player_MoveTo after frame close and restore; not OS mouse/CEGUI ground hit-testing"}


def fixture(restore=False):
    """Synthetic regression input; never runtime evidence."""
    log = "CYS-UNEQUIP-LIVE: state frame closed: frame_shown=0\n"
    if restore:
        log = "CYS-UNEQUIP-LIVE: RESULT gesture=right taken_off=1\n" + log
        log += "CYS-UNEQUIP-LIVE: state restored: frame_shown=0\n"
    log += PREFIX + "BEGIN frame_shown=0 path=LiveGroundClick_Player_MoveTo first_index=4\n"
    for index in (4, 5, 6):
        x = 40 + 8 * (index - 4)
        log += (f"{PREFIX}REQUEST index={index} frame_shown=0 from={x}.000,100.000\n"
                f"CYS live: ground click {index} from {x}.00,100.00 to {x+8}.00,100.00 navmesh=1 reachable=1 waypoints=1 limit_move=0\n"
                f"CYS: click-move ({x}.0,100.0)->({x+8}.0,100.0) waypoints=1 sent=1 logic=99 pending=0\n"
                f"{PREFIX}OBSERVED index={index} frame_shown=0 from={x}.000,100.000 to={x+8}.000,100.000 distance_m=8.000 elapsed_ms=2500\n")
    return log + PREFIX + "DONE clicks=3 path_m=24.000 frame_shown=0\nCYS world smoke: world script finished; leaving through the system menu\n"


class Tests(unittest.TestCase):
    def rejects(self, text): self.assertEqual(grade(text)["status"], "FAIL")
    def test_positive(self): self.assertEqual(grade(fixture())["status"], "PASS")
    def test_after_restore(self): self.assertEqual(grade(fixture(True))["status"], "PASS")
    def test_old_preclose_only(self): self.rejects("CYS live: ground click 1 reachable=1\nCYS live: ground click 2 reachable=1\nCYS live: ground click 3 reachable=1\nCYS-UNEQUIP-LIVE: state frame closed: frame_shown=0\n")
    def test_before_close(self):
        lines = fixture().splitlines(); self.rejects("\n".join(lines[1:] + lines[:1]))
    def test_missing_index(self): self.rejects(fixture().replace("REQUEST index=5", "MISSING index=5"))
    def test_duplicate_index(self): self.rejects(fixture().replace("index=5", "index=4"))
    def test_missing_sent(self): self.rejects(fixture().replace("sent=1", "sent=0", 1))
    def test_unrelated_sent(self): self.rejects(fixture().replace("->(48.0,100.0)", "->(80.0,100.0)", 1))
    def test_camera_picked_destination(self):
        text = fixture().replace("CYS: click-move (40.0,100.0)->(48.0,100.0)", "CYS camera: click-pick 4 screen=(100,100) target=(48.00,100.00) picked=(48.30,100.00) error_m=0.300\nCYS: click-move (40.0,100.0)->(48.3,100.0)")
        self.assertEqual(grade(text)["status"], "PASS")
    def test_no_displacement(self): self.rejects(fixture().replace("to=48.000,100.000", "to=40.000,100.000"))
    def test_forged_distance(self): self.rejects(fixture().replace("distance_m=8.000", "distance_m=9.000", 1))
    def test_frame_reopened(self): self.rejects(fixture().replace("OBSERVED index=5 frame_shown=0", "OBSERVED index=5 frame_shown=1"))
    def test_observed_too_early(self): self.rejects(fixture().replace("elapsed_ms=2500", "elapsed_ms=2400", 1))
    def test_restore_missing(self): self.rejects(fixture(True).replace("state restored:", "state restore timeout:"))
    def test_restore_after_begin(self):
        lines = fixture(True).splitlines(); lines[2], lines[3] = lines[3], lines[2]; self.rejects("\n".join(lines))
    def test_duplicate_begin(self): self.rejects(fixture() + PREFIX + "BEGIN frame_shown=0 path=LiveGroundClick_Player_MoveTo first_index=4\n")
    def test_wrong_finish_order(self):
        lines = fixture().splitlines(); lines[-1], lines[-2] = lines[-2], lines[-1]; self.rejects("\n".join(lines))
    def test_invalid(self): self.rejects(fixture() + "CYS-UNEQUIP-LIVE: PRECONDITION failed\n")
    def test_initial_moves_do_not_contribute(self):
        extra = "CYS live: ground click 1 reachable=1\nCYS live: ground click 2 reachable=1\nCYS live: ground click 3 reachable=1\n"
        self.assertEqual(grade(extra + fixture())["displacement_sum_m"], 24)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--run", type=Path)
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()
    if args.self_test: unittest.main(argv=[__file__], exit=True)
    if not args.run: parser.error("--run required")
    run = json.loads((args.run / "run.json").read_text(encoding="utf-8-sig"))
    result = grade((args.run / "WXClient.log").read_text(encoding="utf-8", errors="replace"))
    if not run.get("passed") or run.get("account") != "test13" or run.get("exit_code") != 0:
        result["errors"].append("world/account/quit failed")
        result["status"] = "FAIL"
    print(json.dumps(result, indent=2))
    raise SystemExit(0 if result["status"] == "PASS" else 1)
