#!/usr/bin/env python3
"""Async NetCore tests against fresh loopback listeners owned by this runner.

No WSL/server account access. Payloads stay in memory; reports contain metadata.
The replay uses the existing ignored PGFRAME1 capture without copying its bodies.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import socket
import struct
import subprocess
import threading
import time

CY = Path(__file__).resolve().parents[2]
SCENARIOS = ("success", "pause-pump", "cancel", "cancel-queued", "destroy-callback",
             "wrong-password", "online", "wait", "known-short", "known-trailing",
             "unknown-id", "wrong-direction", "game-refusal", "list-refused", "timeout",
             "trickle", "peer-close", "status-flood", "partial-tail", "trailing-frame")


def exact(connection, count):
    result = bytearray()
    while len(result) < count:
        part = connection.recv(count - len(result))
        if not part:
            raise EOFError("client closed")
        result.extend(part)
    return result


def receive_frame(connection, evidence):
    packet_id, size, index = struct.unpack("<HHH", exact(connection, 6))
    body = exact(connection, size)
    evidence["tx_ids"].append(packet_id)
    evidence["tx_indices"].append(index)
    return packet_id, index, body


def frame(packet_id, body):
    return struct.pack("<HHH", packet_id, len(body), 0) + body


def login_reply(flag=0, wait=0):
    return bytes(50) + struct.pack("<i", flag) + bytes(15) + struct.pack("<i", wait) + bytes(5)


def server(listener, scenario, evidence):
    try:
        connection, _ = listener.accept()
        with connection:
            connection.settimeout(4)
            try:
                packet_id, index, body = receive_frame(connection, evidence)
            except EOFError:
                assert scenario in ("cancel", "destroy-callback"), "unexpected early close"
                evidence["closed"] = True
                return
            assert (packet_id, index, len(body)) == (355, 0x7B00, 110), "handshake metadata"
            assert body[4:54].split(b"\0", 1)[0] == b"unit-async", "generic account encoding"
            if scenario in ("cancel", "destroy-callback", "timeout"):
                assert connection.recv(1) == b"", "close on cancel or timeout"
                evidence["closed"] = True
                return
            if scenario == "peer-close":
                return
            if scenario == "trickle":
                for value in frame(311, bytes(64))[:3]:
                    connection.sendall(bytes([value]))
                    time.sleep(0.12)
                assert connection.recv(1) == b"", "slow trickle cannot extend state deadline"
                evidence["closed"] = True
                return
            connect = frame(311, bytes(64))
            for chunk in (connect[:1], connect[1:5], connect[5:]):
                connection.sendall(chunk)
            packet_id, index, body = receive_frame(connection, evidence)
            assert (packet_id, index, len(body)) == (299, 0x7C00, 949), "modern auth metadata"
            assert body[:50].split(b"\0", 1)[0] == b"unit-async%unit-value", "synthetic credential encoding"
            if scenario == "wrong-password":
                response = frame(223, login_reply(1))
            elif scenario == "online":
                response = frame(223, login_reply(8))
            elif scenario == "wait":
                response = frame(223, login_reply(21, 25001))
            elif scenario == "known-short":
                response = frame(223, login_reply()[:-1])
            elif scenario == "known-trailing":
                response = frame(223, login_reply() + b"\0")
            elif scenario == "unknown-id":
                response = frame(65535, b"")
            elif scenario == "wrong-direction":
                response = frame(355, bytes(110))
            elif scenario == "game-refusal":
                response = frame(397, bytes(9))
            else:
                connection.sendall(frame(223, login_reply()) + frame(554, bytes(6)))
                packet_id, index, body = receive_frame(connection, evidence)
                assert (packet_id, index, len(body)) == (711, 0x7D00, 50), "charlist sequence continuity"
                if scenario == "list-refused":
                    response = frame(319, struct.pack("<i", 1) + bytes(8))
                elif scenario == "status-flood":
                    response = frame(554, bytes(6)) * 65
                else:
                    response = frame(319, bytes(63))
                    if scenario == "partial-tail":
                        response += b"\x2a"
                    elif scenario == "trailing-frame":
                        response += frame(554, bytes(6))
            connection.sendall(response)
            assert connection.recv(1) == b"", "no packet or credential retry after terminal reply"
            evidence["closed"] = True
        listener.settimeout(0.05)
        try:
            unexpected, _ = listener.accept()
            unexpected.close()
            raise AssertionError("unexpected automatic reconnect")
        except socket.timeout:
            pass
    except Exception as error:
        # All assertion labels are fixed; never embed wire data in an exception.
        evidence["server_error"] = type(error).__name__ + ": " + str(error)


def checked_run(command, timeout=30):
    environment = os.environ.copy()
    environment.pop("CYS_BOT_PWD", None)
    process = subprocess.run(command, cwd=CY, env=environment, capture_output=True, timeout=timeout)
    output = process.stdout + process.stderr
    assert b"unit-value" not in output and b"unit-async%" not in output, "secret leaked into diagnostic output"
    return process.returncode, output.decode("utf-8", errors="replace").replace("\r\n", "\n")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--exe", required=True)
    parser.add_argument("--out", required=True)
    parser.add_argument("--replay", default="Build/cmake/protocol-x64/test-data/capture_frames.bin")
    args = parser.parse_args()
    executable = (CY / args.exe).resolve()
    output = Path(os.path.abspath(CY / args.out))
    if not output.is_relative_to(CY / "Build" / "Logs") or output.exists():
        raise SystemExit("Choose a new output below CY-Source/Build/Logs")
    for path in [output, *output.parents]:
        if path.exists() and (path.is_symlink() or path.is_junction()):
            raise SystemExit("Output must not traverse a junction")
    assert executable.is_relative_to(CY / "Build"), "test executable must be inside CY-Source/Build"
    output.mkdir(parents=True)
    summary = {"scope": "async-login-charlist-offline", "raw_output": False,
               "executable_sha256": hashlib.sha256(executable.read_bytes()).hexdigest(), "cases": []}
    rc, text = checked_run([str(executable)])
    (output / "unit.log").write_text(text, encoding="utf-8")
    summary["unit_rc"] = rc
    assert rc == 0, "NetCore unit/fuzz failed"
    replay = (CY / args.replay).resolve()
    assert replay.is_relative_to(CY / "Build") and replay.is_file(), "existing ignored capture required"
    rc, text = checked_run([str(executable), "--replay", str(replay)])
    (output / "replay.log").write_text(text, encoding="utf-8")
    summary["replay_rc"] = rc
    assert rc == 0, "NetCore replay failed"
    for scenario in SCENARIOS:
        evidence = {"scenario": scenario, "tx_ids": [], "tx_indices": []}
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as listener:
            listener.bind(("127.0.0.1", 0))
            listener.listen(1)
            listener.settimeout(5)
            port = listener.getsockname()[1]
            helper = threading.Thread(target=server, args=(listener, scenario, evidence))
            helper.start()
            started = time.monotonic()
            rc, text = checked_run([str(executable), "--loopback", str(port), scenario], timeout=8)
            helper.join(timeout=5)
            evidence["elapsed_ms"] = round((time.monotonic() - started) * 1000)
            evidence["exit_code"] = rc
            (output / (scenario + ".log")).write_text(text, encoding="utf-8")
            assert not helper.is_alive(), "loopback helper did not exit"
        evidence["passed"] = rc == 0 and "server_error" not in evidence
        summary["cases"].append(evidence)
        (output / "summary.json").write_text(json.dumps(summary, indent=2) + "\n", encoding="utf-8")
        assert evidence["passed"], scenario + ": loopback failed; see metadata"
        print("PASS", scenario, "tx=" + str(len(evidence["tx_ids"])))
    print("PASS NetCore unit/fuzz + replay1699 +", len(SCENARIOS), "async loopback cases")


if __name__ == "__main__":
    main()
