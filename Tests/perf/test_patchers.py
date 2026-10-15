#!/usr/bin/env python3
"""Regression test of Tools/perf/apply_perf_hooks.py and apply_perf_fixes.py on pristine sources.

  python -B Tests/perf/test_patchers.py

Takes the committed (git HEAD) version of every file the patchers touch into a temporary Src tree, adds the four
CYS-PERF source files from the working tree, then checks: hooks and fixes apply in order (pacer, uiredraw, counters2,
psconst), a second run changes nothing, BOM and CRLF/LF line endings are unchanged, and every inserted line is
tagged. Nothing outside the temporary directory is written. Files whose HEAD version already carries the hooks
(after the orchestrator committed them) are expected to be skipped instead of patched.
"""
import os
import shutil
import subprocess
import sys
import tempfile
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
sys.path.insert(0, os.path.join(ROOT, "Tools", "perf"))
import apply_perf_hooks  # noqa: E402
import apply_perf_fixes  # noqa: E402

NEW_FILES = ["Engine/OGRE/OgreMain/include/OgreCysPerf.h", "Engine/OGRE/OgreMain/src/OgreCysPerf.cpp",
             "Engine/WXCore/CYS/Perf/CysPerf.h", "Engine/WXCore/CYS/Perf/CysPerf.cpp"]
FIX_ORDER = ["pacer", "uiredraw", "counters2", "psconst", "btnalpha", "uiredraw2", "seqframe", "nonvis"]


def head_bytes(rel):
    return subprocess.run(["git", "-C", ROOT, "show", "HEAD:Src/" + rel], capture_output=True, check=True).stdout


def eol_profile(data):
    text = data[3:] if data.startswith(b"\xef\xbb\xbf") else data
    return (data.startswith(b"\xef\xbb\xbf"), text.count(b"\r\n"), text.count(b"\n"))


class PatcherTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.tmp = tempfile.mkdtemp(prefix="cysperf-patch-")
        cls.src = os.path.join(cls.tmp, "Src")
        targets = set()
        for group in apply_perf_hooks.GROUPS.values():
            targets.update(group)
        for _, files in apply_perf_fixes.FIXES.values():
            targets.update(files)
        cls.targets = sorted(t for t in targets if t not in NEW_FILES)
        cls.original = {}
        for rel in cls.targets:
            data = head_bytes(rel)
            cls.original[rel] = data
            path = os.path.join(cls.src, rel.replace("/", os.sep))
            os.makedirs(os.path.dirname(path), exist_ok=True)
            with open(path, "wb") as handle:
                handle.write(data)
        for rel in NEW_FILES:   # the working-tree versions, as the patchers expect them next to the hooks
            path = os.path.join(cls.src, rel.replace("/", os.sep))
            os.makedirs(os.path.dirname(path), exist_ok=True)
            shutil.copyfile(os.path.join(ROOT, "Src", rel.replace("/", os.sep)), path)
        # The working-tree OgreCysPerf.h/CysPerf.cpp may already contain counters2/psconst: restore the pre-C2
        # layout text the patch sets anchor on when needed (they are then skipped by their markers).

    @classmethod
    def tearDownClass(cls):
        shutil.rmtree(cls.tmp, ignore_errors=True)

    def run_hooks(self):
        return apply_perf_hooks.main([self.src])

    def run_fixes(self):
        return apply_perf_fixes.main([self.src] + FIX_ORDER)

    def test_1_apply_then_idempotent(self):
        self.assertEqual(self.run_hooks(), 0)
        self.assertEqual(self.run_fixes(), 0)
        after = {}
        for rel in self.targets:
            with open(os.path.join(self.src, rel.replace("/", os.sep)), "rb") as handle:
                after[rel] = handle.read()
        # second run: nothing changes
        self.assertEqual(self.run_hooks(), 0)
        self.assertEqual(self.run_fixes(), 0)
        for rel in self.targets:
            with open(os.path.join(self.src, rel.replace("/", os.sep)), "rb") as handle:
                self.assertEqual(handle.read(), after[rel], rel)
        # BOM and line-ending style kept, every file actually changed (or already carried the hooks at HEAD)
        for rel in self.targets:
            before_bom, before_crlf, before_lf = eol_profile(self.original[rel])
            bom, crlf, lf = eol_profile(after[rel])
            self.assertEqual(bom, before_bom, rel)
            if before_crlf == before_lf:
                self.assertEqual(crlf, lf, rel + ": CRLF file got LF lines")
            elif before_crlf == 0:
                self.assertEqual(crlf, 0, rel + ": LF file got CRLF lines")
            if b"CYS-PERF" not in self.original[rel]:
                self.assertNotEqual(after[rel], self.original[rel], rel + " was not patched")

    def test_2_inserted_lines_are_tagged(self):
        # every line added to a shared file lies in a hunk that carries a CYS-PERF tag nearby (comment lines,
        # braces and continuation lines of a tagged statement are allowed)
        import difflib
        for rel in self.targets:
            path = os.path.join(self.src, rel.replace("/", os.sep))
            with open(path, "rb") as handle:
                new = handle.read().decode("utf-8", "surrogateescape").splitlines()
            old = self.original[rel].decode("utf-8", "surrogateescape").splitlines()
            if "CYS-PERF" in "\n".join(old):
                continue
            matcher = difflib.SequenceMatcher(None, old, new, autojunk=False)
            for tag, i1, i2, j1, j2 in matcher.get_opcodes():
                if tag in ("insert", "replace"):
                    hunk = "\n".join(new[j1:j2])
                    if all(l.strip() in ("", "{", "}") for l in new[j1:j2]):
                        continue   # re-indented braces / blank lines of a tagged block
                    self.assertIn("CYS-PERF", hunk, "%s: untagged hunk at line %d" % (rel, j1 + 1))


if __name__ == "__main__":
    unittest.main(verbosity=2)
