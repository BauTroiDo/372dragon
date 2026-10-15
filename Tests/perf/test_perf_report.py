#!/usr/bin/env python3
"""Unit tests for Tools/perf/perf_report.py (synthetic CSV, no game run). Run: python -B Tests/perf/test_perf_report.py"""
import os
import sys
import tempfile
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "Tools", "perf"))
import perf_report  # noqa: E402

HEADER = "frame,t_ms,frame_ms,cpu_wait_ms,cpu_draw_ms,gpu_frame_ms,gpu_window_ms,gpu_rtt_ms,gpu_ui_ms,draws,allocs"


def write_csv(rows, marks=()):
    handle = tempfile.NamedTemporaryFile("w", suffix=".csv", delete=False, encoding="utf-8", newline="")
    handle.write(HEADER + "\n")
    by_frame = {}
    for frame, t, label in marks:
        by_frame.setdefault(frame, []).append("#mark,%d,%.3f,%s\n" % (frame, t, label))
    t = 0.0
    for i, (ms, gpu) in enumerate(rows):
        for m in by_frame.get(i, []):
            handle.write(m)
        handle.write("%d,%.3f,%.3f,1.0,2.0,%s,,,,100,5\n" % (i, t, ms, "" if gpu is None else "%.3f" % gpu))
        t += ms
    handle.write("999,1")  # truncated row of a killed process must be ignored
    handle.close()
    return handle.name


class PercentileTests(unittest.TestCase):
    def test_nearest_rank(self):
        values = list(range(1, 101))  # 1..100
        self.assertEqual(perf_report.percentile(values, 0.5), 51)   # round(0.5*99)=50 -> 51
        self.assertEqual(perf_report.percentile(values, 0.95), 95)  # round(94.05)=94 -> 95
        self.assertEqual(perf_report.percentile(values, 0.99), 99)  # round(98.01)=98 -> 99
        self.assertEqual(perf_report.percentile([], 0.9), 0.0)
        self.assertEqual(perf_report.percentile([7.0], 0.99), 7.0)


class ReportTests(unittest.TestCase):
    def test_distribution_and_hitches(self):
        path = write_csv([(16.0, 5.0)] * 98 + [(60.0, 5.0), (120.0, None)])
        try:
            report = perf_report.analyse(path, settle_s=0.0)
        finally:
            os.unlink(path)
        d = report["all"]
        self.assertEqual(d["frames"], 100)
        self.assertEqual(d["hitches"]["gt33.4"], 2)
        self.assertEqual(d["hitches"]["gt50"], 2)
        self.assertEqual(d["hitches"]["gt100"], 1)
        self.assertAlmostEqual(d["mean"], (98 * 16.0 + 60 + 120) / 100.0, places=3)
        self.assertEqual(d["max"], 120.0)
        seg = report["segments"][0]
        self.assertAlmostEqual(seg["gpu_ms"]["gpu_frame_ms"], 5.0)   # empty GPU cells are skipped
        self.assertAlmostEqual(seg["counters"]["draws"], 100.0)

    def test_drop_last_capture_frame(self):
        path = write_csv([(16.0, None)] * 50 + [(400.0, None)])   # last frame = TlbbViewer PNG capture
        try:
            kept = perf_report.analyse(path, settle_s=0.0, drop_last=1)["all"]
            full = perf_report.analyse(path, settle_s=0.0)["all"]
        finally:
            os.unlink(path)
        self.assertEqual(kept["frames"], 50)
        self.assertEqual(kept["max"], 16.0)
        self.assertEqual(full["hitches"]["gt100"], 1)

    def test_skip_frames_for_short_runs(self):
        # 900 fast frames (a viewer run): a time-based settle alone would leave nothing, frame 0 is the init frame
        path = write_csv([(400.0, None)] + [(1.0, None)] * 899)
        try:
            report = perf_report.analyse(path, settle_s=0.0, skip_frames=60)
        finally:
            os.unlink(path)
        settled = report["segments"][0]["settled"]
        self.assertEqual(settled["frames"], 840)
        self.assertEqual(settled["max"], 1.0)

    def test_segments_and_settle(self):
        rows = [(100.0, None)] * 10 + [(10.0, None)] * 400
        marks = [(0, 0.0, "proc:Login"), (10, 1000.0, "scene-built")]
        path = write_csv(rows, marks)
        try:
            report = perf_report.analyse(path, settle_s=2.0)
        finally:
            os.unlink(path)
        labels = [s["label"] for s in report["segments"]]
        self.assertEqual(labels, ["proc:Login", "scene-built"])
        login, built = report["segments"]
        self.assertEqual(login["raw"]["frames"], 10)
        self.assertEqual(login["settled"]["frames"], 0)      # the whole segment is inside the settle window
        self.assertEqual(built["raw"]["frames"], 400)
        self.assertEqual(built["settled"]["frames"], 200)    # 4 s of 10 ms frames minus 2 s
        self.assertAlmostEqual(built["settled"]["fps"], 100.0)

    def test_markdown_and_table(self):
        path = write_csv([(16.0, 4.0)] * 300, [(0, 0.0, "proc:CharCreate")])
        run_dir = tempfile.mkdtemp()
        try:
            report = perf_report.analyse(path, settle_s=1.0, title="unit")
            text = perf_report.markdown(report)
            self.assertIn("proc:CharCreate", text)
            import json
            with open(os.path.join(run_dir, "report.json"), "w", encoding="utf-8") as handle:
                json.dump(report, handle)
            table = perf_report.table([run_dir])
            self.assertIn("proc:CharCreate", table)
            self.assertIn("62.5", table)
        finally:
            os.unlink(path)


if __name__ == "__main__":
    unittest.main(verbosity=2)
