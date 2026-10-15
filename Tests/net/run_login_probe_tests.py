#!/usr/bin/env python3
"""Bounded loopback tests for CysNetBot. Never connects to WSL or an existing server.

Only a synthetic credential is sent to a fresh 127.0.0.1 listener owned by this process.
All output is metadata and is confined to a new directory below CY-Source/Build/Logs.
"""
import argparse
import csv
import json
import os
from pathlib import Path
import socket
import struct
import subprocess
import threading
import time

CY = Path(__file__).resolve().parents[2]
SYNTHETIC = "unit-value"


def exact(connection, count):
    data = bytearray()
    while len(data) < count:
        part = connection.recv(count - len(data))
        if not part:
            raise AssertionError("unexpected close")
        data.extend(part)
    return bytes(data)


def read_frame(connection):
    packet_id, size, index = struct.unpack("<HHH", exact(connection, 6))
    return packet_id, index, exact(connection, size)


def frame(packet_id, body):
    return struct.pack("<HHH", packet_id, len(body), 0) + body


def login_reply(flag=0, wait=0):
    return bytes(50) + struct.pack("<i", flag) + bytes(15) + struct.pack("<i", wait) + bytes(5)


def mock_server(listener, scenario, evidence):
    try:
        connection, _ = listener.accept()
        with connection:
            connection.settimeout(5)
            packet_id, index, body = read_frame(connection)
            assert (packet_id, index, len(body)) == (355, 0x7B00, 110), "handshake metadata"
            assert body[4:54].split(b"\0", 1)[0] == b"test00", "handshake account"
            assert body[54:86].split(b"\0", 1)[0] == b"tlbb", "handshake version"
            evidence["tx_ids"].append(packet_id)
            evidence["tx_indices"].append(index)
            if scenario == "timeout":
                assert connection.recv(1) == b"", "client must close on deadline"
                return
            if scenario == "peer-close":
                return
            connect = frame(311, bytes(64))
            # Exercise header/body fragmentation with the real nonblocking socket code.
            connection.sendall(connect[:1])
            connection.sendall(connect[1:5])
            connection.sendall(connect[5:])
            packet_id, index, body = read_frame(connection)
            assert (packet_id, index, len(body)) == (299, 0x7C00, 949), "modern login metadata"
            assert body[:50].split(b"\0", 1)[0] == ("test00%" + SYNTHETIC).encode(), "credential encoding"
            assert struct.unpack_from("<II", body, 50) == (0, 0), "modern login fields"
            evidence["tx_ids"].append(packet_id)
            evidence["tx_indices"].append(index)
            if scenario == "wrong-password":
                connection.sendall(frame(223, login_reply(1)))
            elif scenario == "online":
                connection.sendall(frame(223, login_reply(8)))
            elif scenario == "wait":
                connection.sendall(frame(223, login_reply(21, 25001)))
            elif scenario == "known-short":
                connection.sendall(frame(223, login_reply()[:-1]))
            elif scenario == "known-trailing":
                connection.sendall(frame(223, login_reply() + b"\0"))
            elif scenario == "unknown-id":
                connection.sendall(frame(65535, b""))
            else:
                connection.sendall(frame(223, login_reply()) + frame(554, bytes(6)))
                packet_id, index, body = read_frame(connection)
                assert (packet_id, index, len(body)) == (711, 0x7D00, 50), "list sequence continuity"
                evidence["tx_ids"].append(packet_id)
                evidence["tx_indices"].append(index)
                if scenario == "list-refused":
                    connection.sendall(frame(319, struct.pack("<i", 1) + bytes(8)))
                else:
                    connection.sendall(frame(319, bytes(63)))
            assert connection.recv(1) == b"", "must close without retry or another packet"
            evidence["closed"] = True
        listener.settimeout(0.1)
        try:
            unexpected, _ = listener.accept()
            unexpected.close()
            raise AssertionError("unexpected automatic reconnect")
        except socket.timeout:
            pass
    except Exception as failure:
        # Assertions contain only a fixed test label, never packet bytes.
        evidence["server_error"] = type(failure).__name__ + ": " + str(failure)


def run_case(executable, out, scenario, expected):
    evidence = {"scenario": scenario, "tx_ids": [], "tx_indices": []}
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as listener:
        listener.bind(("127.0.0.1", 0))
        listener.listen(1)
        listener.settimeout(8)
        port = listener.getsockname()[1]
        thread = threading.Thread(target=mock_server, args=(listener, scenario, evidence))
        thread.start()
        environment = os.environ.copy()
        environment["CYS_BOT_PWD"] = SYNTHETIC
        started = time.monotonic()
        command = [str(executable), "--host", "127.0.0.1", "--port", str(port),
                   "--account", "test00", "--out", (out / scenario).relative_to(CY).as_posix(),
                   "--timeout-ms", "1000"]
        process = subprocess.run(command, cwd=CY, env=environment, capture_output=True, timeout=8)
        thread.join(timeout=8)
        assert not thread.is_alive(), "loopback helper did not terminate"
        evidence["elapsed_ms"] = round((time.monotonic() - started) * 1000)
        evidence["exit_code"] = process.returncode
        assert process.returncode == expected, scenario + ": unexpected return code"
        assert "server_error" not in evidence, scenario + ": " + evidence.get("server_error", "")
        result = json.loads((out / scenario / "result.json").read_text())
        assert result["automatic_retries"] == 0 and result["socket_closed"]
        assert result["game_connection_created"] is False
        assert result["tx_frames"] == len(evidence["tx_ids"])
        if scenario == "happy":
            assert result["character_count"] == 0 and result["state"] == "complete"
            assert result["decode_failures"] == 0 and result["rx_frames"] == 4
        if scenario == "wrong-password":
            assert result["login_flag"] == 1 and result["tx_frames"] == 2
        if scenario in ("online", "wait"):
            assert result["retry_after_seconds"] == (20 if scenario == "online" else 26)
        if scenario.startswith("known-"):
            failures = list(csv.DictReader((out / scenario / "failures.tsv").open(), delimiter="\t"))
            assert len(failures) == 1 and failures[0]["proto"] == "login" and failures[0]["id"] == "223"
        if scenario == "timeout":
            assert 900 <= result["elapsed_ms"] <= 4000
        # Scan every report plus stdout/stderr for synthetic secret/combined auth material.
        outputs = process.stdout + process.stderr
        for path in (out / scenario).iterdir():
            outputs += path.read_bytes()
        assert SYNTHETIC.encode() not in outputs and b"test00%" not in outputs, "credential leaked to diagnostics"
    evidence["passed"] = True
    print("PASS", scenario, "tx=" + str(len(evidence["tx_ids"])))
    return evidence


def setup_guards(executable,out):
    """Invalid root/path exits before any socket connect or report write."""
    no_markers=out/'not-a-checkout'
    no_markers.mkdir()
    existing=out/'existing-output'
    existing.mkdir()
    cases=[('cwd-markers',no_markers,'Build/Logs/should-not-exist'),
           ('traversal',CY,'Build/Logs/../should-not-exist'),
           ('absolute',CY,str(out/'absolute-output')),
           ('existing-output',CY,existing.relative_to(CY).as_posix()),
           ('outside-build',CY,'Tests/should-not-exist')]
    evidence=[]
    for name,cwd,destination in cases:
        with socket.socket(socket.AF_INET,socket.SOCK_STREAM) as listener:
            listener.bind(('127.0.0.1',0)); listener.listen(1); listener.settimeout(.1)
            environment=os.environ.copy(); environment['CYS_BOT_PWD']=SYNTHETIC
            process=subprocess.run([str(executable),'--host','127.0.0.1','--port',str(listener.getsockname()[1]),
                                    '--account','test00','--out',destination],
                                   cwd=cwd,env=environment,capture_output=True,timeout=5)
            assert process.returncode==2,name+': setup guard return code'
            assert SYNTHETIC.encode() not in process.stdout+process.stderr,'setup diagnostic leak'
            try:
                connection,_=listener.accept(); connection.close()
                raise AssertionError(name+': connected before setup validation')
            except socket.timeout:
                pass
            evidence.append({'scenario':name,'exit_code':2,'connections':0,'passed':True})
            print('PASS',name,'connections=0')
    assert not (no_markers/'Build').exists() and not list(existing.iterdir())
    return evidence


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--exe", default="Build/cmake/gpt-netbot-20260913/bin/CysNetBot.exe")
    parser.add_argument("--out", required=True)
    args = parser.parse_args()
    executable = (CY / args.exe).resolve()
    out = (CY / args.out).resolve()
    assert out.is_relative_to(CY / "Build" / "Logs") and out != CY / "Build" / "Logs"
    out.mkdir(parents=True, exist_ok=False)
    cases = [("happy", 0), ("wrong-password", 6), ("online", 6), ("wait", 6),
             ("known-short", 5), ("known-trailing", 5), ("unknown-id", 5),
             ("list-refused", 6), ("timeout", 4), ("peer-close", 4)]
    results = [run_case(executable, out, scenario, expected) for scenario, expected in cases]
    guards=setup_guards(executable,out)
    summary = {"tests": len(results)+len(guards), "passed": len(results)+len(guards), "wsl_connections": 0,
               "credential_diagnostic_leaks": 0, "results": results,"setup_guards":guards,
               "report_root":"runtime CY-Source working directory"}
    (out / "summary.json").write_text(json.dumps(summary, indent=2) + "\n", encoding="utf-8")
    print("RESULT loopback_tests=" + str(len(results)) + " setup_guards="+str(len(guards))+" failed=0 wsl_connections=0")


if __name__ == "__main__":
    main()
