"""Apply two verified CY mesh conversions to a private, completed creation stage.

Default: write a reviewable plan only. --apply backs up both meshes and both
active profile manifests before replacing anything. Original source records,
earlier backups, six GL login pairs, fonts and skeletons remain unchanged.
"""
import argparse
import copy
import importlib.util
import json
import os
from pathlib import Path, PureWindowsPath
import re
import sys
import time
import uuid

ROOT = Path(__file__).absolute().parents[2]
spec = importlib.util.spec_from_file_location("cys_mesh_conversion", ROOT / "Tests/ui/create_role_mesh_upgrade.py")
conversion = importlib.util.module_from_spec(spec)
spec.loader.exec_module(conversion)
digest, require = conversion.digest, conversion.require
GL = "Bin64/gl_login_profile.json"
CREATE = "Bin64/create_role_profile.json"
EXTENSION = "mesh_upgrade_extension"
PAIRS = ("Logon/LogOn", "SelectServer/SelectServer", "SoftKeyBoard/SoftKeyBoard")


def relative_name(value):
    require(isinstance(value, str) and value, "Expected relative file name")
    path = PureWindowsPath(value)
    require(not path.is_absolute() and not path.drive and ".." not in path.parts,
            "Absolute/traversal manifest path")
    require(all(":" not in part and "~" not in part and not part.endswith((".", " "))
                for part in path.parts), "Invalid manifest path component")
    return Path(*path.parts)


def guarded(path, missing=False):
    path = Path(path).absolute()
    require(path != ROOT / "Build" and path.is_relative_to(ROOT / "Build"), "Only private Build paths allowed")
    conversion.no_links(path, allow_missing=missing)
    return path


def argument(value, missing=False):
    return guarded(ROOT / relative_name(value), missing)


def child(stage, name):
    return guarded(stage / relative_name(name))


def rel(path):
    return path.relative_to(ROOT).as_posix()


def json_bytes(value):
    return (json.dumps(value, ensure_ascii=False, indent=2) + "\n").encode("utf-8")


def unique_records(records, field="path"):
    require(isinstance(records, list), "Missing manifest file list")
    indexed, folded = {}, set()
    for record in records:
        name = relative_name(record[field]).as_posix()
        require(name.casefold() not in folded, "Duplicate Windows manifest target")
        indexed[name] = record
        folded.add(name.casefold())
    return indexed


def load_conversion(report_path):
    raw = guarded(report_path).read_bytes()
    report = json.loads(raw)
    require(report.get("schema") == 1 and report.get("mode") == "cpu-convert"
            and report.get("pass") is True and report.get("source_unchanged") is True
            and report.get("stage_modified") is False, "Conversion did not pass")
    rows = report.get("fixtures", [])
    require(len(rows) == 2 and {r.get("fixture") for r in rows} == {"bird", "crane"},
            "Expected exactly two conversion results")
    results = []
    for fixture in conversion.FIXTURES:
        row = next(r for r in rows if r["fixture"] == fixture["id"])
        require(row.get("exit_code") == 0, "Native conversion exit was not successful")
        work = report_path.parent / fixture["id"]
        input_path, output_path = guarded(work / "input.mesh"), guarded(work / "output.mesh")
        require(row.get("input") == rel(input_path) and row.get("output") == rel(output_path),
                "Conversion result path differs from fixed work layout")
        skeleton_copy = guarded(work / "resources" /
            (fixture["name"] + ".skeleton").encode("gbk").decode("cp1252"))
        source_path, original = conversion.source_bytes(fixture)
        _, skeleton = conversion.source_bytes(fixture, True)
        require(input_path.read_bytes() == original and skeleton_copy.read_bytes() == skeleton,
                "Conversion inputs no longer match CY source")
        output = output_path.read_bytes()
        native = conversion.validate_native(
            fixture, output, skeleton_copy.read_bytes(),
            guarded(work / "stdout.log").read_text(encoding="utf-8", errors="replace"),
            guarded(work / "output.mesh.log").read_text(encoding="cp1252", errors="replace"))
        require(row.get("native") == native and row.get("source_sha256") == fixture["mesh_sha256"]
                and row.get("skeleton_sha256") == fixture["skeleton_sha256"], "Conversion report evidence mismatch")
        key = "\u5c0f\u52a8\u7269/" + fixture["name"] + ".mesh"
        target = "Data/Model/" + key.encode("gbk").decode("cp1252").lower()
        results.append({"fixture": fixture["id"], "target": target, "before": original, "after": output,
                        "source": "../" + source_path.relative_to(ROOT.parent).as_posix(),
                        "native": native, "skeleton_sha256": fixture["skeleton_sha256"],
                        "skeleton_target": "Data/Model/" +
                            (fixture["name"] + ".skeleton").encode("gbk").decode("cp1252").lower()})
    return raw, results


def verify_profiles(stage, gl, creation):
    marker = json.loads(child(stage, "Bin64/offline_stage.json").read_bytes())
    require(re.fullmatch(r"[0-9a-f]{40}", marker.get("sha", "")) is not None,
            "Private CI stage marker missing")
    require(gl.get("applied") is True and creation.get("applied") is True
            and creation.get("source") == "../Tools/DATA NEW/DataCY31-08-26"
            and creation.get("font_codepage") == 65001 and creation.get("strfilter_rules") == 0,
            "Completed CY creation and GL profiles required")
    for manifest in (gl, creation):
        require(argument(manifest["stage"]) == stage, "Profile stage identity mismatch")
        require(EXTENSION not in manifest, "Meshes already adapted; use a fresh stage")
        for name, record in unique_records(manifest["files"]).items():
            data = child(stage, name).read_bytes()
            require(digest(data) == record["sha256"] and len(data) == record["bytes"],
                    "Existing profile content/hash mismatch: " + name)
    expected = {p + ext for p in PAIRS for ext in (".lua", ".layout.xml")}
    pairs = unique_records(gl["pairs"])
    require(set(pairs) == expected and creation["login_pairs"] == gl["pairs"], "GL six-pair contract mismatch")
    for name, record in pairs.items():
        data = child(stage, "Data/Interface/" + name).read_bytes()
        canonical = ROOT / "Assets/Canonical/Data/InterfaceFolder" / relative_name(name)
        conversion.no_links(canonical)
        require(data == canonical.read_bytes() and digest(data) == record["sha256"], "GL login pair changed")
    font = child(stage, "Data/Interface/Schema/NotoSansSC-Regular.ttf").read_bytes()
    require(digest(font) == creation["font_sha256"], "Noto font identity mismatch")


def update_documents(gl_before, creation_before, changes, provenance):
    """Pure transformation; old origins/hashes/backups remain available."""
    gl, creation = copy.deepcopy(gl_before), copy.deepcopy(creation_before)
    creation_files = unique_records(creation["files"])
    scene = creation.get("scene")
    require(isinstance(scene, dict) and scene.get("valid") is True, "Complete creation scene required")
    scene_files = unique_records(scene["files"])
    scene_resources = unique_records(scene["resources"], "target")
    gl_files = unique_records(gl["files"])
    for change in changes:
        name = change["target"]
        before_hash, after_hash = digest(change["before"]), digest(change["after"])
        def update(record):
            require(record["sha256"] == before_hash and record["bytes"] == len(change["before"]),
                    "Target manifest identity mismatch")
            require("mesh_upgrade" not in record, "Target already upgraded")
            record["mesh_upgrade"] = {"sha256_before": before_hash, "bytes_before": record["bytes"],
                                      "backup": change["backup"], "conversion_report": provenance["conversion_report"],
                                      "invariant_sha256": change["native"]["invariant_sha256"]}
            record["sha256"], record["bytes"] = after_hash, len(change["after"])
        require(name in creation_files and name in scene_files and name in scene_resources,
                "Both scene and creation must own the exact target")
        require(creation_files[name]["origin"] == change["source"]
                and scene_resources[name]["source"] == change["source"], "Target source provenance mismatch")
        for records in (creation_files, scene_files, scene_resources):
            update(records[name])
        if name in gl_files:
            update(gl_files[name])
    # Source lists describe the unchanged S2 input and are deliberately untouched.
    gl[EXTENSION] = copy.deepcopy(provenance)
    creation[EXTENSION] = copy.deepcopy(provenance)
    gl_after = json_bytes(gl)
    record = creation_files[GL]
    require(record["sha256"] == provenance["gl_manifest_sha256_before"], "GL chain was already invalid")
    record["mesh_upgrade"] = {"sha256_before": record["sha256"], "bytes_before": record["bytes"],
                              "backup": provenance["gl_manifest_backup"]}
    record["sha256"], record["bytes"] = digest(gl_after), len(gl_after)
    return gl_after, json_bytes(creation)


def make_plan(stage, report_path, out):
    for a, b in ((stage, out), (stage, report_path.parent), (out, report_path.parent)):
        require(not a.is_relative_to(b) and not b.is_relative_to(a), "Stage, conversion and evidence must be disjoint")
    require(not out.exists(), "Evidence directory must be new")
    raw_report, changes = load_conversion(report_path)
    raw_gl, raw_creation = child(stage, GL).read_bytes(), child(stage, CREATE).read_bytes()
    gl, creation = json.loads(raw_gl), json.loads(raw_creation)
    verify_profiles(stage, gl, creation)
    for i, change in enumerate(changes):
        require(child(stage, change["target"]).read_bytes() == change["before"], "Stage mesh is not original CY bytes")
        require(digest(child(stage, change["skeleton_target"]).read_bytes()) == change["skeleton_sha256"],
                "Staged skeleton changed")
        change["backup"] = rel(out / ("%02d.before.bin" % i))
    provenance = {"version": 1, "adapter": "Tools/data/apply_create_role_mesh_upgrade.py",
                  "adapter_sha256": digest(Path(__file__).read_bytes()),
                  "conversion_report": rel(report_path), "conversion_report_sha256": digest(raw_report),
                  "report": rel(out / "result.json"), "from": "1.30", "to": "1.40",
                  "gl_manifest_sha256_before": digest(raw_gl),
                  "creation_manifest_sha256_before": digest(raw_creation),
                  "gl_manifest_backup": rel(out / "02.before.bin"),
                  "creation_manifest_backup": rel(out / "03.before.bin"),
                  "targets": [{"fixture": c["fixture"], "path": c["target"],
                               "sha256_before": digest(c["before"]), "sha256": digest(c["after"]),
                               "backup": c["backup"], "invariant_sha256": c["native"]["invariant_sha256"]}
                              for c in changes]}
    gl_after, creation_after = update_documents(gl, creation, changes, provenance)
    updates = [(c["target"], c["before"], c["after"]) for c in changes]
    updates += [(GL, raw_gl, gl_after), (CREATE, raw_creation, creation_after)]
    return updates, provenance


def replace_checked(path, expected, data):
    guarded(path)
    require(path.read_bytes() == expected, "Destination changed since plan")
    temporary = guarded(path.with_name(path.name + ".cys-upgrade-" + uuid.uuid4().hex + ".tmp"), True)
    conversion.write_new(temporary, data)
    require(temporary.read_bytes() == data, "Temporary write verification failed")
    guarded(path)
    require(path.read_bytes() == expected, "Destination changed during write")
    os.replace(temporary, path)
    require(path.read_bytes() == data, "Replacement verification failed")


def apply_updates(stage, out, updates, provenance, apply=False):
    require(not out.exists(), "Evidence directory already exists")
    guarded(out, True)
    for name, before, _ in updates:
        require(child(stage, name).read_bytes() == before, "Destination changed before backup")
    out.mkdir(parents=True, exist_ok=False)
    report = {"version": 1, "stage": rel(stage), "applied": False, "started_unix": time.time(),
              "provenance": provenance, "files": [
                  {"path": name, "sha256_before": digest(before), "sha256": digest(after),
                   "bytes_before": len(before), "bytes": len(after),
                   "backup": rel(out / ("%02d.before.bin" % i))}
                  for i, (name, before, after) in enumerate(updates)]}
    conversion.write_new(out / "plan.json", json_bytes(report))
    if not apply:
        return report
    # All four originals and the mapping are durable before the first stage write.
    for i, (_, before, _) in enumerate(updates):
        backup = out / ("%02d.before.bin" % i)
        conversion.write_new(backup, before)
        require(backup.read_bytes() == before, "Backup verification failed")
    conversion.write_new(out / "backup-index.json", json_bytes(report))
    touched = []
    try:
        for name, before, after in updates:
            # Register before the atomic operation so even a verification fault
            # after replacement is included in the guarded rollback.
            touched.append((name, before, after))
            replace_checked(child(stage, name), before, after)
        for name, _, after in updates:
            require(child(stage, name).read_bytes() == after, "Final verification failed")
        report["applied"] = True
    except Exception as error:
        report["failure"] = str(error)
        report["rollback"] = []
        for name, before, after in reversed(touched):
            try:
                path = child(stage, name)
                if path.read_bytes() == after:
                    replace_checked(path, after, before)
                require(path.read_bytes() == before, "Refuse to overwrite unexpected changed content")
                report["rollback"].append({"path": name, "restored": True})
            except Exception as rollback_error:
                report["rollback"].append({"path": name, "restored": False, "error": str(rollback_error)})
        raise
    finally:
        report["finished_unix"] = time.time()
        conversion.write_new(out / "result.json", json_bytes(report))
    return report


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--stage", required=True)
    parser.add_argument("--conversion", required=True, help="Successful converter report.json, relative to CY-Source")
    parser.add_argument("--out", required=True, help="New disjoint Build evidence directory")
    parser.add_argument("--apply", action="store_true")
    args = parser.parse_args()
    try:
        stage, report_path, out = argument(args.stage), argument(args.conversion), argument(args.out, True)
        updates, provenance = make_plan(stage, report_path, out)
        report = apply_updates(stage, out, updates, provenance, args.apply)
        print(json.dumps({"applied": report["applied"], "files": len(report["files"]), "out": rel(out)}))
        return 0
    except Exception as error:
        print("CYS mesh stage adapter: " + str(error), file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
