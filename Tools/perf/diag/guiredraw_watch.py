#!/usr/bin/env python3
"""CYS-PERF diagnostic, isolated perf tree only (never ported): who sets CEGUI::System::d_gui_redraw?

  guiredraw_watch.py [SRC_ROOT]      default Build/perf/src/Src; any tree outside Build/perf is refused

Adds to CEGUI/src/CEGUISystem.cpp a hardware write watch (DR0, 1 byte, write) on System::d_gui_redraw, armed in
System::renderGUI when CYS_PERF_REDRAW=1 (a helper thread sets DR0/DR7 on every thread; a vectored handler counts).
Every write that leaves the flag set is attributed to its call stack (5 frames, RtlVirtualUnwind). Every 10 s
UISystem.log gets "CYS-GUIREDRAW" lines: the 20 stacks that wrote most in the interval, with DbgHelp symbols (PDBs
next to the binaries or at their build path). Logged at Standard level: in UISystem.log "(InfL1)" is Standard and
Informative lines are dropped.

Then: Tools/perf/build_perf.cmd export cys_ceguibase, stage the new CEGUIBase.dll (+pdb), run Game with
-Env CYS_PERF_REDRAW=1, and read the CYS-GUIREDRAW lines. This found the per-frame whole-GUI rebuild fixed by
btnalpha and uiredraw2 (Docs/specs/render/09-performance_vi.md, 5.2 and 7.3).
Undo: copy the git HEAD version of CEGUISystem.cpp back (git show HEAD:Src/ThirdParty/CEGUI-0.4.1/CEGUI/src/
CEGUISystem.cpp) and rebuild cys_ceguibase.
"""
import os
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", ".."))
REL = os.path.join("ThirdParty", "CEGUI-0.4.1", "CEGUI", "src", "CEGUISystem.cpp")

HELPER = r'''#include "windows.h"
// CYS-PERF-DIAG (temporary, isolated perf tree only): hardware write watch on System::d_gui_redraw.
#include <tlhelp32.h>
#include <dbghelp.h>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <string>
namespace
{
    const int kCysFrames = 5;
    const int kCysSites = 48;
    struct CysSite { DWORD64 pc[kCysFrames]; LONG count; };
    CysSite s_cysSites[kCysSites];
    volatile bool* s_cysWatch = 0;
    volatile LONG s_cysHits = 0;
    volatile LONG s_cysDropped = 0;

    typedef PVOID (WINAPI* CysLookupEntry)(DWORD64, PDWORD64, PVOID);
    typedef PVOID (WINAPI* CysVirtualUnwind)(DWORD, DWORD64, DWORD64, PVOID, PCONTEXT, PVOID*, PDWORD64, PVOID);
    typedef LONG (CALLBACK* CysVeh)(PEXCEPTION_POINTERS);
    typedef PVOID (WINAPI* CysAddVeh)(ULONG, CysVeh);
    typedef HANDLE (WINAPI* CysOpenThread)(DWORD, BOOL, DWORD);
    CysLookupEntry s_cysLookup = 0;
    CysVirtualUnwind s_cysUnwind = 0;

    void cysWalk(CONTEXT ctx, DWORD64* out)
    {
        for (int i = 0; i < kCysFrames; ++i)
        {
            out[i] = ctx.Rip;
            if (!ctx.Rip)
                continue;
            DWORD64 imageBase = 0;
            PVOID fn = s_cysLookup ? s_cysLookup(ctx.Rip, &imageBase, NULL) : 0;
            if (!fn)
            {
                ctx.Rip = *(DWORD64*)ctx.Rsp;
                ctx.Rsp += 8;
            }
            else
            {
                PVOID handlerData = 0;
                DWORD64 establisher = 0;
                s_cysUnwind(0, imageBase, ctx.Rip, fn, &ctx, &handlerData, &establisher, NULL);
            }
        }
    }

    LONG CALLBACK cysWatchHandler(PEXCEPTION_POINTERS info)
    {
        if (info->ExceptionRecord->ExceptionCode != EXCEPTION_SINGLE_STEP || !(info->ContextRecord->Dr6 & 1))
            return EXCEPTION_CONTINUE_SEARCH;
        info->ContextRecord->Dr6 = 0;
        if (s_cysWatch && *s_cysWatch)
        {
            DWORD64 pc[kCysFrames];
            cysWalk(*info->ContextRecord, pc);
            int i = 0;
            for (; i < kCysSites; ++i)
            {
                if (s_cysSites[i].count == 0)
                {
                    memcpy(s_cysSites[i].pc, pc, sizeof(pc));
                    s_cysSites[i].count = 1;
                    break;
                }
                if (memcmp(s_cysSites[i].pc, pc, sizeof(pc)) == 0)
                {
                    ++s_cysSites[i].count;
                    break;
                }
            }
            if (i == kCysSites)
                ++s_cysDropped;
            ++s_cysHits;
        }
        return EXCEPTION_CONTINUE_EXECUTION;
    }

    DWORD WINAPI cysArmThread(LPVOID)
    {
        CysOpenThread openThread = (CysOpenThread)GetProcAddress(GetModuleHandleA("kernel32.dll"), "OpenThread");
        if (!openThread)
            return 1;
        const DWORD self = GetCurrentThreadId(), pid = GetCurrentProcessId();
        HANDLE snap = CreateToolhelp32Snapshot(TH32CS_SNAPTHREAD, 0);
        if (snap == INVALID_HANDLE_VALUE)
            return 1;
        THREADENTRY32 te;
        te.dwSize = sizeof(te);
        for (BOOL ok = Thread32First(snap, &te); ok; ok = Thread32Next(snap, &te))
        {
            if (te.th32OwnerProcessID != pid || te.th32ThreadID == self)
                continue;
            HANDLE th = openThread(THREAD_GET_CONTEXT | THREAD_SET_CONTEXT | THREAD_SUSPEND_RESUME, FALSE, te.th32ThreadID);
            if (!th)
                continue;
            if (SuspendThread(th) != (DWORD)-1)
            {
                CONTEXT c;
                memset(&c, 0, sizeof(c));
                c.ContextFlags = CONTEXT_DEBUG_REGISTERS;
                if (GetThreadContext(th, &c))
                {
                    c.Dr0 = (DWORD64)s_cysWatch;
                    c.Dr7 = (c.Dr7 & ~(DWORD64)0xF0003) | 1 | (1 << 16);
                    SetThreadContext(th, &c);
                }
                ResumeThread(th);
            }
            CloseHandle(th);
        }
        CloseHandle(snap);
        return 0;
    }

    typedef BOOL (WINAPI* CysSymInitialize)(HANDLE, PCSTR, BOOL);
    typedef DWORD (WINAPI* CysSymSetOptions)(DWORD);
    typedef BOOL (WINAPI* CysSymFromAddr)(HANDLE, DWORD64, PDWORD64, PSYMBOL_INFO);
    typedef BOOL (WINAPI* CysSymGetLine)(HANDLE, DWORD64, PDWORD, PIMAGEHLP_LINE64);

    void cysDescribe(DWORD64 pc, char* out, size_t size)
    {
        static CysSymFromAddr s_fromAddr = 0;
        static CysSymGetLine s_line = 0;
        static int s_init = 0;
        if (!s_init)
        {
            s_init = 1;
            HMODULE dbg = LoadLibraryA("dbghelp.dll");
            if (dbg)
            {
                CysSymSetOptions setOptions = (CysSymSetOptions)GetProcAddress(dbg, "SymSetOptions");
                CysSymInitialize init = (CysSymInitialize)GetProcAddress(dbg, "SymInitialize");
                s_fromAddr = (CysSymFromAddr)GetProcAddress(dbg, "SymFromAddr");
                s_line = (CysSymGetLine)GetProcAddress(dbg, "SymGetLineFromAddr64");
                if (setOptions)
                    setOptions(SYMOPT_UNDNAME | SYMOPT_DEFERRED_LOADS | SYMOPT_LOAD_LINES);
                if (!init || !init(GetCurrentProcess(), NULL, TRUE))
                    s_fromAddr = 0;
            }
        }
        MEMORY_BASIC_INFORMATION mbi;
        DWORD64 base = 0;
        char modName[MAX_PATH] = "?";
        if (VirtualQuery((LPCVOID)pc, &mbi, sizeof(mbi)) && mbi.AllocationBase)
        {
            base = (DWORD64)mbi.AllocationBase;
            char path[MAX_PATH];
            if (GetModuleFileNameA((HMODULE)mbi.AllocationBase, path, MAX_PATH))
            {
                const char* name = strrchr(path, '\\');
                strncpy(modName, name ? name + 1 : path, MAX_PATH - 1);
                modName[MAX_PATH - 1] = 0;
            }
        }
        int n = _snprintf(out, size, "%s+0x%llx", modName, (unsigned long long)(pc - base));
        if (n < 0 || (size_t)n >= size)
        {
            out[size - 1] = 0;
            return;
        }
        if (s_fromAddr)
        {
            char buffer[sizeof(SYMBOL_INFO) + 256];
            memset(buffer, 0, sizeof(buffer));
            PSYMBOL_INFO sym = (PSYMBOL_INFO)buffer;
            sym->SizeOfStruct = sizeof(SYMBOL_INFO);
            sym->MaxNameLen = 255;
            DWORD64 disp = 0;
            if (s_fromAddr(GetCurrentProcess(), pc, &disp, sym))
            {
                int m = _snprintf(out + n, size - n, " %s", sym->Name);
                if (m > 0 && (size_t)(n + m) < size)
                    n += m;
                IMAGEHLP_LINE64 line;
                memset(&line, 0, sizeof(line));
                line.SizeOfStruct = sizeof(line);
                DWORD lineDisp = 0;
                if (s_line && (size_t)n < size && s_line(GetCurrentProcess(), pc, &lineDisp, &line) && line.FileName)
                {
                    const char* file = strrchr(line.FileName, '\\');
                    _snprintf(out + n, size - n, " (%s:%lu)", file ? file + 1 : line.FileName, (unsigned long)line.LineNumber);
                }
            }
        }
        out[size - 1] = 0;
    }
}
'''

ARM = r'''void System::renderGUI(void)
{
	// CYS-PERF-DIAG: arm the write watch once; report the writers every 10 s.
	static int s_cysArmed = -1;
	static DWORD s_cysNextReport = 0;
	if (s_cysArmed < 0)
	{
		s_cysArmed = std::getenv("CYS_PERF_REDRAW") ? 1 : 0;
		HMODULE k32 = GetModuleHandleA("kernel32.dll");
		CysAddVeh addVeh = k32 ? (CysAddVeh)GetProcAddress(k32, "AddVectoredExceptionHandler") : 0;
		s_cysLookup = k32 ? (CysLookupEntry)GetProcAddress(k32, "RtlLookupFunctionEntry") : 0;
		s_cysUnwind = k32 ? (CysVirtualUnwind)GetProcAddress(k32, "RtlVirtualUnwind") : 0;
		if (!s_cysUnwind)
			s_cysLookup = 0;
		if (s_cysArmed && addVeh)
		{
			s_cysWatch = (volatile bool*)&d_gui_redraw;
			addVeh(1, cysWatchHandler);
			HANDLE arm = CreateThread(NULL, 0, cysArmThread, NULL, 0, NULL);
			if (arm)
			{
				WaitForSingleObject(arm, 5000);
				CloseHandle(arm);
			}
			Logger::getSingleton().logEvent("CYS-GUIREDRAW: write watch armed on System::d_gui_redraw", Standard);
			s_cysNextReport = GetTickCount() + 10000;
		}
		else
			s_cysArmed = 0;
	}
	if (s_cysArmed > 0 && (LONG)(GetTickCount() - s_cysNextReport) >= 0)
	{
		s_cysNextReport = GetTickCount() + 10000;
		char head[128];
		_snprintf(head, sizeof(head), "CYS-GUIREDRAW: %ld writes set the flag so far (sites table full: %ld)", (long)s_cysHits, (long)s_cysDropped);
		head[sizeof(head) - 1] = 0;
		Logger::getSingleton().logEvent(head, Standard);
		for (int i = 0; i < kCysSites && s_cysSites[i].count; ++i)
		{
			char count[48];
			_snprintf(count, sizeof(count), "CYS-GUIREDRAW   site %d x%ld:", i, (long)s_cysSites[i].count);
			count[sizeof(count) - 1] = 0;
			std::string line(count);
			for (int f = 0; f < kCysFrames && s_cysSites[i].pc[f]; ++f)
			{
				char where[600];
				cysDescribe(s_cysSites[i].pc[f], where, sizeof(where));
				line += f ? " <- " : " ";
				line += where;
			}
			Logger::getSingleton().logEvent(line.c_str(), Standard);
		}
	}
'''

# Second step, as measured: 1024 sites, and every report lists the 20 sites with the most writes in the interval.
OLD_LOOP = '''		for (int i = 0; i < kCysSites && s_cysSites[i].count; ++i)
		{
			char count[48];
			_snprintf(count, sizeof(count), "CYS-GUIREDRAW   site %d x%ld:", i, (long)s_cysSites[i].count);
'''
NEW_LOOP = '''		// CYS-PERF-DIAG2: the 20 sites with the most writes in this interval.
		static int s_order[kCysSites];
		static LONG s_delta[kCysSites];
		int used = 0;
		for (int i = 0; i < kCysSites && s_cysSites[i].count; ++i)
		{
			const LONG now = s_cysSites[i].count;
			s_delta[i] = now - s_cysSeen[i];
			s_cysSeen[i] = now;
			if (s_delta[i] > 0)
				s_order[used++] = i;
		}
		for (int a = 0; a < used && a < 20; ++a)
			for (int b = a + 1; b < used; ++b)
				if (s_delta[s_order[b]] > s_delta[s_order[a]])
				{
					const int t = s_order[a];
					s_order[a] = s_order[b];
					s_order[b] = t;
				}
		for (int k = 0; k < used && k < 20; ++k)
		{
			const int i = s_order[k];
			char count[64];
			_snprintf(count, sizeof(count), "CYS-GUIREDRAW   site %d +%ld (total %ld):", i, (long)s_delta[i], (long)s_cysSites[i].count);
'''


def main(argv):
    src = os.path.abspath(argv[0] if argv else os.path.join(ROOT, "Build", "perf", "src", "Src"))
    allowed = os.path.join(ROOT, "Build", "perf") + os.sep
    if not (src + os.sep).lower().startswith(allowed.lower()):
        print("refused: %s is not under %s (diagnostics never go into the main tree)" % (src, allowed))
        return 2
    path = os.path.join(src, REL)
    data = open(path, "rb").read()
    bom = data.startswith(b"\xef\xbb\xbf")
    text = (data[3:] if bom else data).decode("utf-8", "surrogateescape")
    eol = "\r\n" if "\r\n" in text else "\n"
    if "CYS-PERF-DIAG" in text:
        print("already applied: " + path)
        return 0
    for old, new in (('#include "windows.h"\n', HELPER), ("void System::renderGUI(void)\n{\n", ARM),
                     ("    const int kCysSites = 48;\n",
                      "    const int kCysSites = 1024; // CYS-PERF-DIAG2\n    LONG s_cysSeen[1024];\n"),
                     (OLD_LOOP, NEW_LOOP)):
        old, new = old.replace("\n", eol), new.replace("\n", eol)
        if text.count(old) != 1:
            print("FAIL: anchor %r matched %d time(s), expected 1" % (old[:50], text.count(old)))
            return 1
        text = text.replace(old, new)
    with open(path, "wb") as handle:
        handle.write((b"\xef\xbb\xbf" if bom else b"") + text.encode("utf-8", "surrogateescape"))
    print("ok: write watch on System::d_gui_redraw added to " + path)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
