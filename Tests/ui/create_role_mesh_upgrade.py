"""CPU conversion harness for exactly two CY login meshes; never edits a stage.

Run from CY-Source. --out must be a NEW ASCII path under Build. Source mesh and
skeleton bytes are hash-pinned; CP1252 disk names preserve their GBK resource keys.
The native tool verifies full typed geometry before/after export. This harness
also verifies original files, copied skeletons, output version and warning census.
No optimisation, source replacement, profile-manifest rewriting or GPU is used.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import stat
import subprocess
import sys
import time

ROOT = Path(__file__).absolute().parents[2]
SOURCE = ROOT.parent / "Tools/DATA NEW/DataCY31-08-26/Model"
FIXTURES = (
    {"id": "bird", "name": "\u98de\u9e1f", "vertices": 48, "triangles": 48, "bone_ids": 7,
     "mesh_sha256": "1dcb85938d9a93ff88d4fa82df4d8c1c9499691fee1663f28635d12b87dce417",
     "skeleton_sha256": "605509a85e43e4853c16a305a00722761f8b1763743bc74746657775c236fec7"},
    {"id": "crane", "name": "\u5c0f\u52a8\u7269\u9e64", "vertices": 484, "triangles": 560, "bone_ids": 18,
     "mesh_sha256": "4f625d68d20157bea39692044ea06dddbb1b8bde628b31715c9ce781886c56ee",
     "skeleton_sha256": "05d12a57c08c693b0040819d492ec5fbea4867c35418d8d2619ebe425f59accc"},
)
PREFIX = "CYS_MESH_UPGRADE "


def require(ok, reason):
    if not ok:
        raise ValueError(reason)


def no_links(path, allow_missing=False):
    """Check lexical ancestors before resolve so a junction cannot be hidden."""
    path = path.absolute()
    for part in reversed((path, *path.parents)):
        try:
            info = part.lstat()
        except FileNotFoundError:
            if allow_missing:
                continue
            raise ValueError("Missing guarded path") from None
        require(not stat.S_ISLNK(info.st_mode)
                and not (getattr(info, "st_file_attributes", 0) & 0x400),
                "Symlink/junction/reparse point is forbidden")
        if stat.S_ISREG(info.st_mode):
            require(info.st_nlink == 1, "Hard-linked file is forbidden")
    return path


def private_path(value, must_be_new=False):
    path = Path(value)
    require(str(path).isascii() and ".." not in path.parts and "~" not in str(path),
            "Build path must be ASCII without traversal or short names")
    for part in path.parts[1:] if path.is_absolute() else path.parts:
        require(":" not in part and not part.endswith((".", " ")),
                "Invalid Windows path component")
    path = path if path.is_absolute() else ROOT / path
    path = path.absolute()
    require(path != ROOT / "Build" and path.is_relative_to(ROOT / "Build"),
            "Path must be beneath CY-Source/Build")
    no_links(path, allow_missing=must_be_new)
    if must_be_new:
        require(not path.exists(), "Output already exists; use a fresh run directory")
    return path


def digest(blob):
    return hashlib.sha256(blob).hexdigest()


def write_new(path, data):
    no_links(path.parent)
    with path.open("xb") as stream:
        stream.write(data)


def relative(path):
    return path.relative_to(ROOT).as_posix()


def source_bytes(fixture, skeleton=False):
    suffix = ".skeleton" if skeleton else ".mesh"
    path = SOURCE / (fixture["name"] + suffix) if skeleton else (
        SOURCE / "\u5c0f\u52a8\u7269" / (fixture["name"] + suffix))
    no_links(path)
    blob = path.read_bytes()
    require(digest(blob) == fixture["skeleton_sha256" if skeleton else "mesh_sha256"],
            "CY source identity changed")
    return path, blob


def validate_native(fixture, output, skeleton, stdout, log):
    require(len(output) > 24 and output.startswith(b"\x00\x10[MeshSerializer_v1.40]\n"),
            "Output is not an Ogre v1.40 mesh")
    rows = [line[len(PREFIX):] for line in stdout.splitlines() if line.startswith(PREFIX + "{")]
    require(len(rows) == 1, "Native success record absent/ambiguous")
    record = json.loads(rows[0])
    require(record.get("pass") is True and record.get("renderer") is False
            and record.get("fixture") == fixture["id"]
            and record.get("from") == "1.30" and record.get("to") == "1.40",
            "Native mode contract failed")
    for key in ("vertices", "triangles", "bone_ids"):
        require(record.get(key) == fixture[key], "Native geometry count mismatch")
    require(record.get("source_sha256") == fixture["mesh_sha256"]
            and record.get("skeleton_sha256") == fixture["skeleton_sha256"]
            and record.get("output_sha256") == digest(output)
            and digest(skeleton) == fixture["skeleton_sha256"], "Native/output identity mismatch")
    require(isinstance(record.get("weights"), int) and record["weights"] > 0
            and isinstance(record.get("invariant_sha256"), str)
            and len(record["invariant_sha256"]) == 64
            and all(c in "0123456789abcdef" for c in record["invariant_sha256"]),
            "Native invariant evidence missing")
    # Keep the input v1.30 warning. The reimported output must add no old-format warning.
    old = [line for line in log.splitlines() if "older format" in line]
    require(len(old) == 1 and "cys-upgrade-input" in old[0], "Unexpected old-format warning census")
    failures = [line for line in log.splitlines()
                if any(word in line.lower() for word in ("error", "exception", "unable to load", "warning:"))
                and "older format" not in line]
    require(not failures, "Additional native warnings/errors; inspect preserved log")
    record["old_format_warnings"] = len(old)
    return record


def run(exe_value, out_value, prepare_only=False):
    require(os.name == "nt" and Path.cwd().absolute() == ROOT, "Run on Windows from CY-Source")
    no_links(ROOT)
    require(ROOT.name == "CY-Source" and (ROOT / "Src/CMakeLists.txt").is_file()
            and (ROOT / "Timeline/handoff/net.md").is_file(), "Checkout markers absent")
    exe = private_path(exe_value)
    require(exe.is_file() and exe.name.lower() == "ogresmoke.exe", "Expected CY Build OgreSmoke.exe")
    out = private_path(out_value, must_be_new=True)
    # Verify BOTH originals before creating any output directory.
    originals = [(f, source_bytes(f), source_bytes(f, True)) for f in FIXTURES]
    out.mkdir(parents=True, exist_ok=False)
    report = {"schema": 1, "mode": "prepare" if prepare_only else "cpu-convert",
              "started_unix": time.time(), "exe": relative(exe), "exe_sha256": digest(exe.read_bytes()),
              "source_unchanged": False, "stage_modified": False, "fixtures": [], "pass": False}
    try:
        for fixture, (mesh_path, mesh), (skeleton_path, skeleton) in originals:
            work = out / fixture["id"]
            resources = work / "resources"
            resources.mkdir(parents=True)
            (work / "tmp").mkdir()
            input_path, output_path = work / "input.mesh", work / "output.mesh"
            skeleton_copy = resources / (fixture["name"] + ".skeleton").encode("gbk").decode("cp1252")
            write_new(input_path, mesh)
            write_new(skeleton_copy, skeleton)
            argv = [str(exe), "--upgrade-login-mesh", str(input_path), str(output_path), str(resources)]
            row = {"fixture": fixture["id"], "source": "../" + mesh_path.relative_to(ROOT.parent).as_posix(),
                   "skeleton_source": "../" + skeleton_path.relative_to(ROOT.parent).as_posix(),
                   "source_sha256": digest(mesh), "skeleton_sha256": digest(skeleton),
                   "input": relative(input_path), "output": relative(output_path),
                   "skeleton_key_hex": (fixture["name"] + ".skeleton").encode("gbk").hex(),
                   "command": [relative(exe), "--upgrade-login-mesh", relative(input_path),
                               relative(output_path), relative(resources)]}
            report["fixtures"].append(row)
            if prepare_only:
                continue
            env = os.environ.copy()
            env["TEMP"] = env["TMP"] = str(work / "tmp")
            # One invocation per fixture, no retry. Native mode returns before normal smoke init.
            with (work / "stdout.log").open("xb") as stdout, (work / "stderr.log").open("xb") as stderr:
                result = subprocess.run(argv, cwd=ROOT, env=env, stdin=subprocess.DEVNULL,
                                        stdout=stdout, stderr=stderr, timeout=60, check=False,
                                        creationflags=subprocess.CREATE_NO_WINDOW)
            row["exit_code"] = result.returncode
            require(result.returncode == 0, "Native conversion failed; logs preserved")
            no_links(output_path)
            log_path = Path(str(output_path) + ".log")
            no_links(log_path)
            row["native"] = validate_native(
                fixture, output_path.read_bytes(), skeleton_copy.read_bytes(),
                (work / "stdout.log").read_text(encoding="utf-8", errors="replace"),
                log_path.read_text(encoding="cp1252", errors="replace"))
            require(input_path.read_bytes() == mesh, "Private input mesh changed")
        for fixture, (path, mesh), (skeleton_path, skeleton) in originals:
            require(path.read_bytes() == mesh and skeleton_path.read_bytes() == skeleton,
                    "Original CY source changed")
        report["source_unchanged"] = True
        report["pass"] = not prepare_only
    except Exception as error:
        report["failure"] = str(error)
        raise
    finally:
        report["finished_unix"] = time.time()
        write_new(out / "report.json", (json.dumps(report, ensure_ascii=True, indent=2) + "\n").encode("ascii"))
    return report


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--exe", required=True)
    parser.add_argument("--out", required=True)
    parser.add_argument("--prepare-only", action="store_true", help="Copy/hash inputs and print commands; do not run native")
    args = parser.parse_args()
    try:
        result = run(args.exe, args.out, args.prepare_only)
        print(json.dumps({"prepared": True, "pass": result["pass"], "out": args.out}, ensure_ascii=True))
        return 0
    except Exception as error:
        print("CYS mesh upgrade: " + str(error), file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
