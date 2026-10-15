# Lua host query tests

Run from PowerShell with an existing CI-built LuaPlus library and DLL:

```powershell
& C:\TLBB\085\CY-Source\Tests\luaapi\run_query_tests.ps1 -Jobs 3
```

The runner writes only inside a unique repository `Build` directory, compiles four sources with at most three jobs, copies the existing LuaPlus DLL, and bounds the isolated test process to five seconds. It does not start Game.exe, the client or the server. `result.json` records compiler arguments, source hashes, dependency hash and exit codes.

The tests execute the production `CysHostQueries` wrapper with LuaPlus 5.0.1 and the generated PlayerPackage stubs. The bag callback is explicitly simulated. These tests establish Lua argument/return behavior, signed numeric conversion, copied service descriptors, existing receiver/metatable identity, non-override, error cleanup, and missing-call counters. They do not establish that GameProcedure's real `CDataPool::UserBag_GetItem` bridge or live bag data works.

The same two-call snippet yields generated-stub values `0,0` with missing calls `2`, then real wrapper results `10100001,-1` with missing calls `0`. A separate generated method must continue counting missing calls.

The simulated source bag has 60 slots. B's getter supports 240 slots. Tests prove the wrapper forwards indices 60, 239 and 240 without clamping; the source backend decides whether an item exists. No test claims a populated B slot 60..239 is represented by CY.

Native faults are not converted to Lua errors. The game retains its existing fatal handling; this harness tests only recoverable C++ and LuaPlus callback exceptions.
