"""Inspect JiYuan transport separately from core shop acceptance; never certify purchases."""
from pathlib import Path
from datetime import datetime
import argparse
import json
import re


def inspect(client, server, start, end):
    stamp = re.compile(r"^\[(\d{4}-\d\d-\d\d \d\d:\d\d:\d\d)\]")
    times, selected = [], []
    current = None
    for line in server.splitlines():
        found = stamp.match(line)
        if found:
            current = datetime.fromisoformat(found[1])
            times.append(current)
        if current is not None and start <= current <= end:
            selected.append(line)
    relevant = [line for line in selected if re.search(r"JiYuan|jiyuan", line)]
    errors = [line for line in selected if re.search(r"NOTFOUND|traceback|lua.*error|ERROR.*script", line, re.I)]
    requested = bool(re.search(r"CGExecuteScript id=888902 function=OpenJiYuanShop count=1\b", client))
    received_unhandled = "first unhandled GC id=191" in client
    decode_clean = bool(re.search(r"terminal=quit_complete[^\n]*decode_failures=0\b", client))
    coverage = bool(times and min(times) <= start and max(times) >= end)
    if not requested:
        status = "NOT_OBSERVED"
    elif errors or not coverage or not decode_clean:
        status = "REQUIRES_REVIEW"
    elif received_unhandled:
        status = "PARTIAL_RECEIVED_UNHANDLED"
    else:
        status = "RECEIVE_NOT_PROVEN"
    return {
        "status": status,
        "script_request_observed": requested,
        "packet_191_received_unhandled": received_unhandled,
        "clean_terminal_decode": decode_clean,
        "server_time_coverage": coverage,
        "server_window_lines": len(selected),
        "server_relevant_lines": relevant,
        "server_error_candidates": errors,
        "scope": "Transport observation only. GC191 is unhandled; no JiYuan catalog, display or purchase acceptance is implied. Core GC188 shop is graded separately.",
    }


def selftest():
    start = datetime.fromisoformat("2026-09-20 17:13:00")
    end = datetime.fromisoformat("2026-09-20 17:14:15")
    server = "[2026-09-20 17:12:00] ready\n[2026-09-20 17:15:00] heartbeat"
    client = "CGExecuteScript id=888902 function=OpenJiYuanShop count=1\nfirst unhandled GC id=191\nterminal=quit_complete decode_failures=0"
    cases = [
        ("partial is not full acceptance", client, server, "PARTIAL_RECEIVED_UNHANDLED"),
        ("missing request", "", server, "NOT_OBSERVED"),
        ("missing response", client.replace("first unhandled GC id=191", ""), server, "RECEIVE_NOT_PROVEN"),
        ("server error", client, server + "\n[2026-09-20 17:13:20] OpenJiYuanShop NOTFOUND", "REQUIRES_REVIEW"),
        ("incomplete server range", client, "", "REQUIRES_REVIEW"),
        ("decode failure", client.replace("decode_failures=0", "decode_failures=1"), server, "REQUIRES_REVIEW"),
    ]
    for name, c, s, want in cases:
        assert inspect(c, s, start, end)["status"] == want, name
        print("PASS", name)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--client", type=Path)
    parser.add_argument("--server", type=Path)
    parser.add_argument("--start", help="Server-local ISO timestamp")
    parser.add_argument("--end", help="Server-local ISO timestamp")
    parser.add_argument("--output", type=Path)
    parser.add_argument("--selftest", action="store_true")
    args = parser.parse_args()
    if args.selftest:
        selftest()
    else:
        if not all((args.client, args.server, args.start, args.end)):
            parser.error("--client, --server, --start and --end are required")
        start, end = datetime.fromisoformat(args.start), datetime.fromisoformat(args.end)
        if end < start:
            parser.error("end must not precede start")
        result = inspect(args.client.read_text(encoding="utf-8", errors="replace"), args.server.read_text(encoding="utf-8", errors="replace"), start, end)
        result.update(client=str(args.client), server=str(args.server), start=args.start, end=args.end)
        rendered = json.dumps(result, ensure_ascii=False, indent=2)
        if args.output:
            args.output.write_text(rendered + "\n", encoding="utf-8")
        print(rendered)
        raise SystemExit(0 if result["status"] == "PARTIAL_RECEIVED_UNHANDLED" else 1)
