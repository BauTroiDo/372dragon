"""Stage adapter guards, provenance and rollback; no native/Game invocation."""
import copy
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
from unittest import mock

ROOT = Path(__file__).absolute().parents[2]
spec = importlib.util.spec_from_file_location("mesh_adapter", ROOT / "Tools/data/apply_create_role_mesh_upgrade.py")
adapter = importlib.util.module_from_spec(spec)
spec.loader.exec_module(adapter)


class AdapterTests(unittest.TestCase):
    def setUp(self):
        base = ROOT / "Build/Logs/2026-09-13-gpt-create-role/mesh-adapter-tests"
        adapter.guarded(base, True)
        base.mkdir(parents=True, exist_ok=True)
        self.temp = tempfile.TemporaryDirectory(dir=base, prefix="unit-")
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name)
        self.stage = self.base / "stage"
        self.stage.mkdir()
        self.out = self.base / "evidence"

    def updates(self):
        result = []
        for index, name in enumerate(("Data/a.mesh", "Data/b.mesh", adapter.GL, adapter.CREATE)):
            path = self.stage / name
            path.parent.mkdir(parents=True, exist_ok=True)
            before = ("before-%d" % index).encode()
            after = ("after-%d" % index).encode()
            path.write_bytes(before)
            result.append((name, before, after))
        return result

    def test_reject_traversal_absolute_ads(self):
        for value in ("../outside", "C:/outside", "Build/../Src/x", "Build/x:stream", "Build/x."):
            with self.subTest(value=value), self.assertRaises(ValueError):
                adapter.argument(value, True)

    def test_reject_case_duplicate_manifest(self):
        with self.assertRaises(ValueError):
            adapter.unique_records([{"path": "Data/a.mesh"}, {"path": "data/A.mesh"}])

    def test_reject_hardlink(self):
        path = self.base / "a"
        path.write_bytes(b"private")
        (self.base / "b").hardlink_to(path)
        with self.assertRaises(ValueError):
            adapter.guarded(path)

    def test_plan_has_no_stage_writes(self):
        updates = self.updates()
        report = adapter.apply_updates(self.stage, self.out, updates, {}, False)
        self.assertFalse(report["applied"])
        self.assertTrue((self.out / "plan.json").is_file())
        for name, before, _ in updates:
            self.assertEqual((self.stage / name).read_bytes(), before)

    def test_backups_complete_before_first_write(self):
        updates = self.updates()
        real = adapter.replace_checked
        def checked(path, before, after):
            self.assertTrue((self.out / "backup-index.json").is_file())
            for index, (_, original, _) in enumerate(updates):
                self.assertEqual((self.out / ("%02d.before.bin" % index)).read_bytes(), original)
            real(path, before, after)
        with mock.patch.object(adapter, "replace_checked", side_effect=checked):
            report = adapter.apply_updates(self.stage, self.out, updates, {}, True)
        self.assertTrue(report["applied"])
        for name, _, after in updates:
            self.assertEqual((self.stage / name).read_bytes(), after)

    def test_failure_after_replace_rolls_back(self):
        updates = self.updates()
        real = adapter.replace_checked
        calls = 0
        def broken(path, before, after):
            nonlocal calls
            calls += 1
            real(path, before, after)
            if calls == 2:
                raise OSError("injected-after-replace")
        with mock.patch.object(adapter, "replace_checked", side_effect=broken), self.assertRaises(OSError):
            adapter.apply_updates(self.stage, self.out, updates, {}, True)
        for name, before, _ in updates:
            self.assertEqual((self.stage / name).read_bytes(), before)
        result = json.loads((self.out / "result.json").read_bytes())
        self.assertFalse(result["applied"])
        self.assertTrue(all(row["restored"] for row in result["rollback"]))

    def test_concurrent_change_is_not_overwritten(self):
        updates = self.updates()
        real = adapter.replace_checked
        def concurrent(path, before, after):
            path.write_bytes(b"external-change")
            real(path, before, after)
        with mock.patch.object(adapter, "replace_checked", side_effect=concurrent), self.assertRaises(ValueError):
            adapter.apply_updates(self.stage, self.out, updates, {}, True)
        self.assertEqual((self.stage / updates[0][0]).read_bytes(), b"external-change")
        result = json.loads((self.out / "result.json").read_bytes())
        self.assertFalse(result["rollback"][0]["restored"])

    def test_refuse_reusing_evidence(self):
        updates = self.updates()
        self.out.mkdir()
        with self.assertRaises(ValueError):
            adapter.apply_updates(self.stage, self.out, updates, {}, True)
        for name, before, _ in updates:
            self.assertEqual((self.stage / name).read_bytes(), before)

    def documents(self):
        changes, files, resources, sources = [], [], [], []
        for index in range(2):
            name = "Data/Model/unit-%d.mesh" % index
            before, after = b"source" + bytes([index]), b"converted" + bytes([index])
            source = "../source/%d.mesh" % index
            record = {"path": name, "origin": source, "sha256": adapter.digest(before), "bytes": len(before),
                      "backup": "original-before", "sha256_before": "older-source"}
            files.append(record)
            resources.append({"target": name, "source": source, "sha256": record["sha256"], "bytes": len(before)})
            sources.append({"path": source, "sha256": record["sha256"]})
            changes.append({"target": name, "source": source, "before": before, "after": after,
                            "backup": "new-backup-%d" % index, "native": {"invariant_sha256": "a" * 64}})
        gl = {"files": [], "pairs": [{"path": "unchanged-pair", "sha256": "original"}]}
        raw_gl = adapter.json_bytes(gl)
        creation = {"files": copy.deepcopy(files) + [{"path": adapter.GL, "sha256": adapter.digest(raw_gl),
                     "bytes": len(raw_gl), "backup": "old-gl-backup", "sha256_before_creation": "historic"}],
                    "gl_parent_sha256": "original-parent",
                    "scene": {"valid": True, "files": copy.deepcopy(files), "resources": resources, "sources": sources}}
        provenance = {"conversion_report": "Build/unit/report.json", "gl_manifest_sha256_before": adapter.digest(raw_gl),
                      "gl_manifest_backup": "Build/unit/gl.before"}
        return gl, creation, changes, provenance

    def test_manifest_chain_and_source_history_preserved(self):
        gl, creation, changes, provenance = self.documents()
        old = copy.deepcopy(creation)
        gl_raw, cr_raw = adapter.update_documents(gl, creation, changes, provenance)
        new_gl, new_cr = json.loads(gl_raw), json.loads(cr_raw)
        self.assertEqual(creation, old)
        self.assertEqual(new_gl["pairs"], gl["pairs"])
        self.assertEqual(new_cr["scene"]["sources"], old["scene"]["sources"])
        self.assertEqual(new_cr["gl_parent_sha256"], "original-parent")
        records = adapter.unique_records(new_cr["files"])
        self.assertEqual(records[adapter.GL]["sha256"], adapter.digest(gl_raw))
        self.assertEqual(records[adapter.GL]["sha256_before_creation"], "historic")
        for change in changes:
            record = records[change["target"]]
            self.assertEqual(record["sha256"], adapter.digest(change["after"]))
            self.assertEqual(record["sha256_before"], "older-source")
            self.assertEqual(record["backup"], "original-before")
            self.assertEqual(record["mesh_upgrade"]["backup"], change["backup"])

    def test_refuse_missing_scene_target(self):
        gl, creation, changes, provenance = self.documents()
        creation["scene"]["resources"].pop()
        with self.assertRaises(ValueError):
            adapter.update_documents(gl, creation, changes, provenance)

    def test_reject_failed_native_report(self):
        path = self.base / "report.json"
        path.write_text('{"schema":1,"mode":"cpu-convert","pass":false}')
        with self.assertRaises(ValueError):
            adapter.load_conversion(path)


if __name__ == "__main__":
    unittest.main(verbosity=2)
