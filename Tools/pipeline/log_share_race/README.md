# Native reproduction of the live-log sharing race

This test only creates files under a fresh repository `Build` directory. It does
not launch Game.exe, connect to a server, change Mongo, or modify an existing log.
It requires Windows PowerShell and Visual Studio 2022 BuildTools x64 at the path
already used by this repository's build.

From the repository root:

```powershell
& .\Tools\pipeline\log_share_race\run.ps1
& .\Tools\pipeline\log_share_race\run.ps1 -PollMs 1000
```

Each command compiles one native writer, runs two eight-second arms, and saves
`result.json`, compiler output, writer counters and both logs in a new directory
under `Build/Logs/log-share-race`. The hidden writer can produce about40MB per arm;
logs are retained as evidence. `-OutRoot` may name a fresh directory within `Build`.

The writer preserves the open/format/close sequence from
`Src/Engine/WXEngine/Util/TDUtil.cpp:12..29`: try `fopen("a")`, then `fopen("w")`
when append fails. Counters merely observe which open succeeded. The payload
contains an increasing sequence and the file starts with a sentinel. The two
reader arms differ only in file-sharing mode:

- Before: `[IO.File]::ReadAllText`, whose handle denies a concurrent writer.
- After: `FileStream(Open, Read, FileShare.ReadWrite | FileShare.Delete)` and a
  disposed `StreamReader`, which permits the live writer to continue appending.

If the reader closes its handle between a failed append open and the fallback
open, `"w"` succeeds and truncates all preceding lines. If both opens fail, the
line is dropped. The test exits with a failure if the shared reader loses the
sentinel, any sequence, or records an append failure. Timing can make the unsafe
arm fail to reproduce on a particular run; its result must be inspected, not
manufactured into a failure.

Observed on20/09/2026 with the same native writer:

| Reader / polling | Append failures | Successful truncating fallback | Retained sequence |
|---|---:|---:|---|
| ReadAllText / tight loop | 2473 | 2138 | 47143..47152 of47152; sentinel lost |
| ReadWrite / tight loop | 0 | 0 | 1..75020; sentinel retained |
| ReadAllText /1000ms | 1537 | 1 | 35458..66810 with gaps; sentinel lost |
| ReadWrite /1000ms | 0 | 0 | 1..68027; sentinel retained |

Original evidence: `Build/Logs/2026-09-20-nbshop/log-share-race/run-175750`
and `run-175856`. Writer throughput is intentionally higher than an ordinary game
session, including in the1000ms polling arm. This proves the sharing/truncation
mechanism; it does not establish that every historical missing log had this cause.

Use the shared-reader pattern for files still being written. Reading immutable
copies after the process exits does not create this race. A separate defensive
writer change could remove the truncating fallback because append mode already
creates missing files, but this reproduction makes no product-source change.
