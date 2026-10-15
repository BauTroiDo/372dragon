// CYS-PERF (perf-cy, 15/09/2026): present probe - a d3d9.dll proxy that timestamps every Present and counts the device
// work between two Presents. Same tool for the CY 3.71 client copy and for our Game.exe, so frame times are compared
// with one clock. Nothing is changed in the rendering: every call is forwarded to %SystemRoot%\System32\d3d9.dll.
//
// Output (directory from CYS_PROBE_DIR, else the exe directory):
//   probe_<pid>.txt  device creation parameters (PresentationInterval = VSync, behaviour flags, size), QPC frequency
//   probe_<pid>.csv  one row per IDirect3DDevice9::Present:
//     frame,t_ms,present_ms,tid,main_cyc,other_cyc,draws,settex,tex,vb,ib,rt,ds,surf,decl,vs,ps,query,create_ms,offthread
//     t_ms       = QPC at Present entry (ms since probe load)
//     present_ms = time spent inside the real Present (VSync / driver queue wait)
//     main_cyc   = CPU cycles of the presenting thread since the previous Present (QueryThreadCycleTime)
//     other_cyc  = CPU cycles of all other threads of the process in the same interval (QueryProcessCycleTime - main)
//     tex..query = resources created in the interval; create_ms = time inside those Create* calls (all threads);
//     offthread  = Create* calls made by a thread other than the presenting one
// The CSV is flushed every 30 frames, so a killed process keeps its data.
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <d3d9.h>
#include <cstdarg>
#include <cstdio>
#include <cstring>
#include <cstdlib>

namespace
{
HMODULE g_real = NULL;
typedef IDirect3D9* (WINAPI* Create9Fn)(UINT);
typedef HRESULT (WINAPI* Create9ExFn)(UINT, IDirect3D9Ex**);
Create9Fn g_create9 = NULL;
Create9ExFn g_create9ex = NULL;

LARGE_INTEGER g_freq, g_t0;
FILE* g_csv = NULL;
FILE* g_txt = NULL;
CRITICAL_SECTION g_lock;
HANDLE g_process = NULL;

volatile LONG g_draws, g_settex, g_tex, g_vb, g_ib, g_rt, g_ds, g_surf, g_decl, g_vs, g_ps, g_query, g_offthread;
volatile LONGLONG g_createTicks;
DWORD g_presentTid = 0;
ULONG64 g_lastMainCyc = 0, g_lastProcCyc = 0;
unsigned g_frame = 0;

double ms(LONGLONG ticks) { return ticks * 1000.0 / (double)g_freq.QuadPart; }
LONGLONG now() { LARGE_INTEGER t; QueryPerformanceCounter(&t); return t.QuadPart; }

void openFiles()
{
    if (g_csv) return;
    char dir[MAX_PATH] = {0};
    DWORD n = GetEnvironmentVariableA("CYS_PROBE_DIR", dir, sizeof(dir));
    if (n == 0 || n >= sizeof(dir))
    {
        GetModuleFileNameA(NULL, dir, sizeof(dir));
        char* s = strrchr(dir, '\\');
        if (s) *s = 0;
    }
    char path[MAX_PATH + 64];
    _snprintf(path, sizeof(path), "%s\\probe_%lu.csv", dir, GetCurrentProcessId());
    path[sizeof(path) - 1] = 0;
    g_csv = fopen(path, "w");
    if (g_csv)
    {
        setvbuf(g_csv, NULL, _IOFBF, 1 << 16);
        fprintf(g_csv, "frame,t_ms,present_ms,tid,main_cyc,other_cyc,draws,settex,tex,vb,ib,rt,ds,surf,decl,vs,ps,query,create_ms,offthread\n");
    }
    _snprintf(path, sizeof(path), "%s\\probe_%lu.txt", dir, GetCurrentProcessId());
    path[sizeof(path) - 1] = 0;
    g_txt = fopen(path, "w");
    if (g_txt)
    {
        char exe[MAX_PATH] = {0};
        GetModuleFileNameA(NULL, exe, sizeof(exe));
        fprintf(g_txt, "exe=%s\nqpc_freq=%lld\n", exe, g_freq.QuadPart);
        fflush(g_txt);
    }
}

void txt(const char* fmt, ...)
{
    if (!g_txt) return;
    va_list ap;
    va_start(ap, fmt);
    EnterCriticalSection(&g_lock);
    fprintf(g_txt, "[%.1f ms tid %lu] ", ms(now() - g_t0.QuadPart), GetCurrentThreadId());
    vfprintf(g_txt, fmt, ap);
    fputc('\n', g_txt);
    fflush(g_txt);
    LeaveCriticalSection(&g_lock);
    va_end(ap);
}

void patch(void** vtbl, int slot, void* hook, void** orig)
{
    if (vtbl[slot] == hook) return;
    DWORD old;
    if (!VirtualProtect(&vtbl[slot], sizeof(void*), PAGE_EXECUTE_READWRITE, &old)) return;
    if (*orig == NULL) *orig = vtbl[slot];
    vtbl[slot] = hook;
    VirtualProtect(&vtbl[slot], sizeof(void*), old, &old);
}

// ---- device hooks ------------------------------------------------------------------------------------------------
void* o_Present, *o_Reset, *o_CreateTexture, *o_CreateVolumeTexture, *o_CreateCubeTexture, *o_CreateVB, *o_CreateIB,
    *o_CreateRT, *o_CreateDS, *o_CreateOffscreen, *o_CreateDecl, *o_CreateVS, *o_CreatePS, *o_DrawPrimitive, *o_DrawIndexed,
    *o_DrawUP, *o_DrawIndexedUP, *o_SetTexture, *o_CreateQuery;

struct CreateScope
{
    LONGLONG t;
    explicit CreateScope(volatile LONG* counter) : t(now())
    {
        InterlockedIncrement(counter);
        if (g_presentTid && GetCurrentThreadId() != g_presentTid) InterlockedIncrement(&g_offthread);
    }
    ~CreateScope() { InterlockedExchangeAdd64(&g_createTicks, now() - t); }
};

// ---- sampling profiler of the presenting thread (CYS_PROBE_SAMPLE=1) -------------------------------------------------
// Every CYS_PROBE_SAMPLE_MS (default 4) ms: SuspendThread, GetThreadContext, copy up to 16 KB of stack from RSP into a preallocated buffer, ResumeThread
// (no heap, no loader lock while the thread is suspended). After the resume: the candidate return addresses of the copy
// (inside a loaded module and preceded by a call instruction) are written with the RIP to probe_<pid>.samples:
//   record = double t_ms, uint32 count, uint64 rip, uint64 ret[count-1]   (count <= 32)
// probe_<pid>.modules lists "base size path" of the modules (rewritten each second). Same tool for CY and CY-Source.
HANDLE g_sampleThread = NULL;
volatile LONG g_sampleStarted = 0;
FILE* g_samples = NULL;

struct ModRange { ULONG_PTR base, end; };
ModRange g_mods[512];
int g_modCount = 0;

void refreshModules(const char* dir)
{
    HMODULE mods[512];
    DWORD needed = 0;
    typedef BOOL (WINAPI* EnumFn)(HANDLE, HMODULE*, DWORD, LPDWORD);
    typedef BOOL (WINAPI* InfoFn)(HANDLE, HMODULE, void*, DWORD);
    static EnumFn enumMods = 0;
    static InfoFn modInfo = 0;
    if (!enumMods)
    {
        HMODULE k = GetModuleHandleA("kernel32.dll");
        enumMods = (EnumFn)GetProcAddress(k, "K32EnumProcessModules");
        modInfo = (InfoFn)GetProcAddress(k, "K32GetModuleInformation");
        if (!enumMods || !modInfo) return;
    }
    if (!enumMods(g_process, mods, sizeof(mods), &needed)) return;
    int n = int(needed / sizeof(HMODULE));
    if (n > 512) n = 512;
    char path[MAX_PATH + 64];
    _snprintf(path, sizeof(path), "%s\\probe_%lu.modules", dir, GetCurrentProcessId());
    path[sizeof(path) - 1] = 0;
    if (n == g_modCount) return; // unchanged module count: keep the list
    char tmp[MAX_PATH + 72];
    _snprintf(tmp, sizeof(tmp), "%s.tmp", path);
    tmp[sizeof(tmp) - 1] = 0;
    FILE* f = fopen(tmp, "w");
    int count = 0;
    for (int i = 0; i < n; ++i)
    {
        struct { void* base; DWORD size; void* entry; } mi;
        if (!modInfo(g_process, mods[i], &mi, sizeof(mi))) continue;
        char name[MAX_PATH] = {0};
        GetModuleFileNameA(mods[i], name, MAX_PATH);
        if (f) fprintf(f, "%llx %lx %s\n", (unsigned long long)(ULONG_PTR)mi.base, mi.size, name);
        g_mods[count].base = (ULONG_PTR)mi.base;
        g_mods[count].end = (ULONG_PTR)mi.base + mi.size;
        ++count;
    }
    g_modCount = count;
    if (f)
    {
        fclose(f);
        MoveFileExA(tmp, path, MOVEFILE_REPLACE_EXISTING); // a killed process never leaves a truncated list
    }
}

bool inModule(ULONG_PTR v)
{
    for (int i = 0; i < g_modCount; ++i)
        if (v >= g_mods[i].base + 0x1000 && v < g_mods[i].end) return true;
    return false;
}

// return address check: the bytes before it form a call (E8 rel32, FF /2 with modrm lengths 2..7)
bool looksLikeReturn(ULONG_PTR ra)
{
    __try
    {
        const unsigned char* p = (const unsigned char*)ra;
        if (p[-5] == 0xE8) return true;
        for (int len = 2; len <= 7; ++len)
        {
            const unsigned char* c = p - len;
            if (c[0] == 0xFF && ((c[1] >> 3) & 7) == 2) return true;
            if (len >= 3 && (c[0] & 0xF0) == 0x40 && c[1] == 0xFF && ((c[2] >> 3) & 7) == 2) return true;
        }
    }
    __except (EXCEPTION_EXECUTE_HANDLER)
    {
    }
    return false;
}

DWORD WINAPI samplerMain(LPVOID param)
{
    const DWORD tid = (DWORD)(ULONG_PTR)param;
    HANDLE th = OpenThread(THREAD_SUSPEND_RESUME | THREAD_GET_CONTEXT | THREAD_QUERY_INFORMATION, FALSE, tid);
    if (!th) return 0;
    char dir[MAX_PATH] = {0};
    DWORD n = GetEnvironmentVariableA("CYS_PROBE_DIR", dir, sizeof(dir));
    if (n == 0 || n >= sizeof(dir)) { GetModuleFileNameA(NULL, dir, sizeof(dir)); char* s = strrchr(dir, '\\'); if (s) *s = 0; }
    char path[MAX_PATH + 64];
    _snprintf(path, sizeof(path), "%s\\probe_%lu.samples", dir, GetCurrentProcessId());
    path[sizeof(path) - 1] = 0;
    g_samples = fopen(path, "wb");
    if (!g_samples) return 0;
    setvbuf(g_samples, NULL, _IOFBF, 1 << 20);
    // stack base of the thread: NT_TIB.StackBase (TEB + 8) through NtQueryInformationThread(ThreadBasicInformation)
    ULONG_PTR stackBase = 0;
    {
        typedef LONG (WINAPI* NtQit)(HANDLE, int, PVOID, ULONG, PULONG);
        NtQit q = (NtQit)GetProcAddress(GetModuleHandleA("ntdll.dll"), "NtQueryInformationThread");
        struct { LONG status; PVOID teb; ULONG_PTR pid, tid, affinity; LONG prio, base; } tbi = {0};
        if (q && q(th, 0, &tbi, sizeof(tbi), NULL) == 0 && tbi.teb)
            stackBase = ((NT_TIB*)tbi.teb)->StackBase ? (ULONG_PTR)((NT_TIB*)tbi.teb)->StackBase : 0;
    }
    typedef UINT (WINAPI* TbpFn)(UINT);
    HMODULE winmm = LoadLibraryA("winmm.dll");
    TbpFn tbp = winmm ? (TbpFn)GetProcAddress(winmm, "timeBeginPeriod") : 0;
    if (tbp) tbp(1);
    SetThreadPriority(GetCurrentThread(), THREAD_PRIORITY_TIME_CRITICAL);
    static unsigned char stackCopy[65536];
    ULONG64 out[32];
    LONGLONG lastMods = 0, lastFlush = now();
    refreshModules(dir);
    char intervalText[16] = {0};
    DWORD intervalMs = 4; // CYS_PROBE_SAMPLE_MS; 1 ms slowed the sampled thread by ~0,4 ms per sample on this machine
    if (GetEnvironmentVariableA("CYS_PROBE_SAMPLE_MS", intervalText, sizeof(intervalText)))
    {
        const int v = atoi(intervalText);
        if (v >= 1 && v <= 100) intervalMs = DWORD(v);
    }
    char unwindText[8] = {0};
    const bool unwindMode = !(GetEnvironmentVariableA("CYS_PROBE_UNWIND", unwindText, sizeof(unwindText)) && unwindText[0] == '0');
    for (;;)
    {
        Sleep(intervalMs);
        const LONGLONG t = now();
        if (ms(t - lastMods) > 1000.0) { refreshModules(dir); lastMods = t; }
        CONTEXT ctx;
        ctx.ContextFlags = CONTEXT_CONTROL | CONTEXT_INTEGER;
        size_t copied = 0;
        if (SuspendThread(th) == (DWORD)-1) break;
        if (GetThreadContext(th, &ctx))
        {
            ULONG_PTR rsp = (ULONG_PTR)ctx.Rsp;
            if (stackBase > rsp)
            {
                copied = stackBase - rsp;
                if (copied > sizeof(stackCopy)) copied = sizeof(stackCopy);
                memcpy(stackCopy, (void*)rsp, copied);
            }
        }
        else
            ctx.Rip = 0;
        ResumeThread(th);
        if (!ctx.Rip) continue;
        UINT count = 0;
        out[count++] = ctx.Rip;
        if (unwindMode)
        {
            // Exact walk: RtlVirtualUnwind on the copy (the thread runs again). Every register that points into the copied
            // range of the real stack is rebased into the copy before each step, so the unwinder never touches the live stack.
            const ULONG_PTR realLo = (ULONG_PTR)ctx.Rsp, realHi = realLo + copied;
            const ULONG_PTR copyLo = (ULONG_PTR)stackCopy;
            auto rebase = [&](DWORD64& r) { if (r >= realLo && r < realHi) r = r - realLo + copyLo; };
            ctx.Rsp = copyLo;
            for (int step = 0; step < 31 && count < 32; ++step)
            {
                rebase(ctx.Rbp); rebase(ctx.Rbx); rebase(ctx.Rsi); rebase(ctx.Rdi);
                rebase(ctx.R12); rebase(ctx.R13); rebase(ctx.R14); rebase(ctx.R15);
                if (ctx.Rsp < copyLo || ctx.Rsp + 8 > copyLo + copied) break;
                DWORD64 imageBase = 0;
                PRUNTIME_FUNCTION fe = RtlLookupFunctionEntry(ctx.Rip, &imageBase, NULL);
                if (!fe)
                {
                    ctx.Rip = *(DWORD64*)ctx.Rsp; // leaf without unwind data
                    ctx.Rsp += 8;
                }
                else
                {
                    PVOID handlerData = 0;
                    DWORD64 establisher = 0;
                    __try
                    {
                        RtlVirtualUnwind(UNW_FLAG_NHANDLER, imageBase, ctx.Rip, fe, &ctx, &handlerData, &establisher, NULL);
                    }
                    __except (EXCEPTION_EXECUTE_HANDLER)
                    {
                        break;
                    }
                }
                if (!ctx.Rip || !inModule((ULONG_PTR)ctx.Rip)) break;
                out[count++] = ctx.Rip;
            }
        }
        else
        {
            for (size_t off = 0; off + 8 <= copied && count < 32; off += 8)
            {
                ULONG_PTR v = *(ULONG_PTR*)(stackCopy + off);
                if (inModule(v) && looksLikeReturn(v))
                    out[count++] = v;
            }
        }
        double tm = ms(t - g_t0.QuadPart);
        fwrite(&tm, sizeof(tm), 1, g_samples);
        fwrite(&count, sizeof(count), 1, g_samples);
        fwrite(out, sizeof(ULONG64), count, g_samples);
        if (ms(t - lastFlush) > 2000.0) { fflush(g_samples); lastFlush = t; }
    }
    return 0;
}

void maybeStartSampler(DWORD tid)
{
    if (g_sampleStarted || InterlockedExchange(&g_sampleStarted, 1)) return;
    char v[8] = {0};
    if (!GetEnvironmentVariableA("CYS_PROBE_SAMPLE", v, sizeof(v)) || v[0] != '1') return;
    g_sampleThread = CreateThread(NULL, 0, samplerMain, (LPVOID)(ULONG_PTR)tid, 0, NULL);
}

typedef HRESULT (STDMETHODCALLTYPE* PresentFn)(IDirect3DDevice9*, const RECT*, const RECT*, HWND, const RGNDATA*);
HRESULT STDMETHODCALLTYPE h_Present(IDirect3DDevice9* d, const RECT* a, const RECT* b, HWND w, const RGNDATA* r)
{
    maybeStartSampler(GetCurrentThreadId());
    const LONGLONG t = now();
    const DWORD tid = GetCurrentThreadId();
    ULONG64 mainCyc = 0, procCyc = 0;
    QueryThreadCycleTime(GetCurrentThread(), &mainCyc);
    QueryProcessCycleTime(g_process, &procCyc);
    HRESULT hr = ((PresentFn)o_Present)(d, a, b, w, r);
    const LONGLONG t2 = now();
    if (g_presentTid != tid) g_presentTid = tid;
    ULONG64 dMain = g_lastMainCyc ? mainCyc - g_lastMainCyc : 0;
    ULONG64 dProc = g_lastProcCyc ? procCyc - g_lastProcCyc : 0;
    g_lastMainCyc = mainCyc;
    g_lastProcCyc = procCyc;
    LONG draws = InterlockedExchange(&g_draws, 0), settex = InterlockedExchange(&g_settex, 0);
    LONG tex = InterlockedExchange(&g_tex, 0), vb = InterlockedExchange(&g_vb, 0), ib = InterlockedExchange(&g_ib, 0);
    LONG rt = InterlockedExchange(&g_rt, 0), ds = InterlockedExchange(&g_ds, 0), surf = InterlockedExchange(&g_surf, 0);
    LONG decl = InterlockedExchange(&g_decl, 0), vs = InterlockedExchange(&g_vs, 0), ps = InterlockedExchange(&g_ps, 0);
    LONG query = InterlockedExchange(&g_query, 0), off = InterlockedExchange(&g_offthread, 0);
    LONGLONG ct = InterlockedExchange64(&g_createTicks, 0);
    if (g_csv)
    {
        EnterCriticalSection(&g_lock);
        fprintf(g_csv, "%u,%.3f,%.3f,%lu,%llu,%llu,%ld,%ld,%ld,%ld,%ld,%ld,%ld,%ld,%ld,%ld,%ld,%ld,%.3f,%ld\n", g_frame,
            ms(t - g_t0.QuadPart), ms(t2 - t), tid, dMain, dProc > dMain ? dProc - dMain : 0, draws, settex, tex, vb, ib, rt,
            ds, surf, decl, vs, ps, query, ms(ct), off);
        if ((++g_frame % 30) == 0) fflush(g_csv);
        LeaveCriticalSection(&g_lock);
    }
    return hr;
}

void logParams(const char* what, const D3DPRESENT_PARAMETERS* pp, DWORD behaviour)
{
    if (!pp) return;
    txt("%s: backbuffer %ux%u fmt %d count %u ms %d swap %d windowed %d depth %d fmt %d flags 0x%x refresh %u "
        "PresentationInterval 0x%x behaviour 0x%x", what, pp->BackBufferWidth, pp->BackBufferHeight, (int)pp->BackBufferFormat,
        pp->BackBufferCount, (int)pp->MultiSampleType, (int)pp->SwapEffect, pp->Windowed, pp->EnableAutoDepthStencil,
        (int)pp->AutoDepthStencilFormat, pp->Flags, pp->FullScreen_RefreshRateInHz, pp->PresentationInterval, behaviour);
}

typedef HRESULT (STDMETHODCALLTYPE* ResetFn)(IDirect3DDevice9*, D3DPRESENT_PARAMETERS*);
HRESULT STDMETHODCALLTYPE h_Reset(IDirect3DDevice9* d, D3DPRESENT_PARAMETERS* pp)
{
    logParams("Reset", pp, 0);
    const LONGLONG t = now();
    HRESULT hr = ((ResetFn)o_Reset)(d, pp);
    txt("Reset hr 0x%08x %.1f ms", hr, ms(now() - t));
    return hr;
}


typedef HRESULT (STDMETHODCALLTYPE* CreateTextureFn)(IDirect3DDevice9*, UINT, UINT, UINT, DWORD, D3DFORMAT, D3DPOOL, IDirect3DTexture9**, HANDLE*);
HRESULT STDMETHODCALLTYPE h_CreateTexture(IDirect3DDevice9* d, UINT w, UINT h, UINT l, DWORD u, D3DFORMAT f, D3DPOOL p, IDirect3DTexture9** o, HANDLE* s)
{ CreateScope c(&g_tex); return ((CreateTextureFn)o_CreateTexture)(d, w, h, l, u, f, p, o, s); }

typedef HRESULT (STDMETHODCALLTYPE* CreateVolumeTextureFn)(IDirect3DDevice9*, UINT, UINT, UINT, UINT, DWORD, D3DFORMAT, D3DPOOL, IDirect3DVolumeTexture9**, HANDLE*);
HRESULT STDMETHODCALLTYPE h_CreateVolumeTexture(IDirect3DDevice9* d, UINT w, UINT h, UINT z, UINT l, DWORD u, D3DFORMAT f, D3DPOOL p, IDirect3DVolumeTexture9** o, HANDLE* s)
{ CreateScope c(&g_tex); return ((CreateVolumeTextureFn)o_CreateVolumeTexture)(d, w, h, z, l, u, f, p, o, s); }

typedef HRESULT (STDMETHODCALLTYPE* CreateCubeTextureFn)(IDirect3DDevice9*, UINT, UINT, DWORD, D3DFORMAT, D3DPOOL, IDirect3DCubeTexture9**, HANDLE*);
HRESULT STDMETHODCALLTYPE h_CreateCubeTexture(IDirect3DDevice9* d, UINT e, UINT l, DWORD u, D3DFORMAT f, D3DPOOL p, IDirect3DCubeTexture9** o, HANDLE* s)
{ CreateScope c(&g_tex); return ((CreateCubeTextureFn)o_CreateCubeTexture)(d, e, l, u, f, p, o, s); }

typedef HRESULT (STDMETHODCALLTYPE* CreateVBFn)(IDirect3DDevice9*, UINT, DWORD, DWORD, D3DPOOL, IDirect3DVertexBuffer9**, HANDLE*);
HRESULT STDMETHODCALLTYPE h_CreateVB(IDirect3DDevice9* d, UINT n, DWORD u, DWORD fvf, D3DPOOL p, IDirect3DVertexBuffer9** o, HANDLE* s)
{ CreateScope c(&g_vb); return ((CreateVBFn)o_CreateVB)(d, n, u, fvf, p, o, s); }

typedef HRESULT (STDMETHODCALLTYPE* CreateIBFn)(IDirect3DDevice9*, UINT, DWORD, D3DFORMAT, D3DPOOL, IDirect3DIndexBuffer9**, HANDLE*);
HRESULT STDMETHODCALLTYPE h_CreateIB(IDirect3DDevice9* d, UINT n, DWORD u, D3DFORMAT f, D3DPOOL p, IDirect3DIndexBuffer9** o, HANDLE* s)
{ CreateScope c(&g_ib); return ((CreateIBFn)o_CreateIB)(d, n, u, f, p, o, s); }

typedef HRESULT (STDMETHODCALLTYPE* CreateRTFn)(IDirect3DDevice9*, UINT, UINT, D3DFORMAT, D3DMULTISAMPLE_TYPE, DWORD, BOOL, IDirect3DSurface9**, HANDLE*);
HRESULT STDMETHODCALLTYPE h_CreateRT(IDirect3DDevice9* d, UINT w, UINT h, D3DFORMAT f, D3DMULTISAMPLE_TYPE m, DWORD q, BOOL l, IDirect3DSurface9** o, HANDLE* s)
{ CreateScope c(&g_rt); return ((CreateRTFn)o_CreateRT)(d, w, h, f, m, q, l, o, s); }

HRESULT STDMETHODCALLTYPE h_CreateDS(IDirect3DDevice9* d, UINT w, UINT h, D3DFORMAT f, D3DMULTISAMPLE_TYPE m, DWORD q, BOOL l, IDirect3DSurface9** o, HANDLE* s)
{ CreateScope c(&g_ds); return ((CreateRTFn)o_CreateDS)(d, w, h, f, m, q, l, o, s); }

typedef HRESULT (STDMETHODCALLTYPE* CreateOffscreenFn)(IDirect3DDevice9*, UINT, UINT, D3DFORMAT, D3DPOOL, IDirect3DSurface9**, HANDLE*);
HRESULT STDMETHODCALLTYPE h_CreateOffscreen(IDirect3DDevice9* d, UINT w, UINT h, D3DFORMAT f, D3DPOOL p, IDirect3DSurface9** o, HANDLE* s)
{ CreateScope c(&g_surf); return ((CreateOffscreenFn)o_CreateOffscreen)(d, w, h, f, p, o, s); }

typedef HRESULT (STDMETHODCALLTYPE* CreateDeclFn)(IDirect3DDevice9*, const D3DVERTEXELEMENT9*, IDirect3DVertexDeclaration9**);
HRESULT STDMETHODCALLTYPE h_CreateDecl(IDirect3DDevice9* d, const D3DVERTEXELEMENT9* e, IDirect3DVertexDeclaration9** o)
{ CreateScope c(&g_decl); return ((CreateDeclFn)o_CreateDecl)(d, e, o); }

typedef HRESULT (STDMETHODCALLTYPE* CreateVSFn)(IDirect3DDevice9*, const DWORD*, IDirect3DVertexShader9**);
HRESULT STDMETHODCALLTYPE h_CreateVS(IDirect3DDevice9* d, const DWORD* f, IDirect3DVertexShader9** o)
{ CreateScope c(&g_vs); return ((CreateVSFn)o_CreateVS)(d, f, o); }

typedef HRESULT (STDMETHODCALLTYPE* CreatePSFn)(IDirect3DDevice9*, const DWORD*, IDirect3DPixelShader9**);
HRESULT STDMETHODCALLTYPE h_CreatePS(IDirect3DDevice9* d, const DWORD* f, IDirect3DPixelShader9** o)
{ CreateScope c(&g_ps); return ((CreatePSFn)o_CreatePS)(d, f, o); }

typedef HRESULT (STDMETHODCALLTYPE* CreateQueryFn)(IDirect3DDevice9*, D3DQUERYTYPE, IDirect3DQuery9**);
HRESULT STDMETHODCALLTYPE h_CreateQuery(IDirect3DDevice9* d, D3DQUERYTYPE t, IDirect3DQuery9** o)
{ CreateScope c(&g_query); return ((CreateQueryFn)o_CreateQuery)(d, t, o); }

typedef HRESULT (STDMETHODCALLTYPE* DrawPrimitiveFn)(IDirect3DDevice9*, D3DPRIMITIVETYPE, UINT, UINT);
HRESULT STDMETHODCALLTYPE h_DrawPrimitive(IDirect3DDevice9* d, D3DPRIMITIVETYPE t, UINT a, UINT b)
{ InterlockedIncrement(&g_draws); return ((DrawPrimitiveFn)o_DrawPrimitive)(d, t, a, b); }

typedef HRESULT (STDMETHODCALLTYPE* DrawIndexedFn)(IDirect3DDevice9*, D3DPRIMITIVETYPE, INT, UINT, UINT, UINT, UINT);
HRESULT STDMETHODCALLTYPE h_DrawIndexed(IDirect3DDevice9* d, D3DPRIMITIVETYPE t, INT a, UINT b, UINT c, UINT e, UINT f)
{ InterlockedIncrement(&g_draws); return ((DrawIndexedFn)o_DrawIndexed)(d, t, a, b, c, e, f); }

typedef HRESULT (STDMETHODCALLTYPE* DrawUPFn)(IDirect3DDevice9*, D3DPRIMITIVETYPE, UINT, const void*, UINT);
HRESULT STDMETHODCALLTYPE h_DrawUP(IDirect3DDevice9* d, D3DPRIMITIVETYPE t, UINT n, const void* v, UINT s)
{ InterlockedIncrement(&g_draws); return ((DrawUPFn)o_DrawUP)(d, t, n, v, s); }

typedef HRESULT (STDMETHODCALLTYPE* DrawIndexedUPFn)(IDirect3DDevice9*, D3DPRIMITIVETYPE, UINT, UINT, UINT, const void*, D3DFORMAT, const void*, UINT);
HRESULT STDMETHODCALLTYPE h_DrawIndexedUP(IDirect3DDevice9* d, D3DPRIMITIVETYPE t, UINT a, UINT b, UINT c, const void* i, D3DFORMAT f, const void* v, UINT s)
{ InterlockedIncrement(&g_draws); return ((DrawIndexedUPFn)o_DrawIndexedUP)(d, t, a, b, c, i, f, v, s); }

typedef HRESULT (STDMETHODCALLTYPE* SetTextureFn)(IDirect3DDevice9*, DWORD, IDirect3DBaseTexture9*);
HRESULT STDMETHODCALLTYPE h_SetTexture(IDirect3DDevice9* d, DWORD s, IDirect3DBaseTexture9* t)
{ InterlockedIncrement(&g_settex); return ((SetTextureFn)o_SetTexture)(d, s, t); }

void hookDevice(IDirect3DDevice9* dev)
{
    void** v = *(void***)dev;
    patch(v, 16, h_Reset, &o_Reset);
    patch(v, 17, h_Present, &o_Present);
    patch(v, 23, h_CreateTexture, &o_CreateTexture);
    patch(v, 24, h_CreateVolumeTexture, &o_CreateVolumeTexture);
    patch(v, 25, h_CreateCubeTexture, &o_CreateCubeTexture);
    patch(v, 26, h_CreateVB, &o_CreateVB);
    patch(v, 27, h_CreateIB, &o_CreateIB);
    patch(v, 28, h_CreateRT, &o_CreateRT);
    patch(v, 29, h_CreateDS, &o_CreateDS);
    patch(v, 36, h_CreateOffscreen, &o_CreateOffscreen);
    patch(v, 65, h_SetTexture, &o_SetTexture);
    patch(v, 81, h_DrawPrimitive, &o_DrawPrimitive);
    patch(v, 82, h_DrawIndexed, &o_DrawIndexed);
    patch(v, 83, h_DrawUP, &o_DrawUP);
    patch(v, 84, h_DrawIndexedUP, &o_DrawIndexedUP);
    patch(v, 86, h_CreateDecl, &o_CreateDecl);
    patch(v, 91, h_CreateVS, &o_CreateVS);
    patch(v, 106, h_CreatePS, &o_CreatePS);
    patch(v, 118, h_CreateQuery, &o_CreateQuery);
}

// ---- IDirect3D9::CreateDevice ---------------------------------------------------------------------------------------
void* o_CreateDevice;
typedef HRESULT (STDMETHODCALLTYPE* CreateDeviceFn)(IDirect3D9*, UINT, D3DDEVTYPE, HWND, DWORD, D3DPRESENT_PARAMETERS*, IDirect3DDevice9**);
HRESULT STDMETHODCALLTYPE h_CreateDevice(IDirect3D9* d3d, UINT adapter, D3DDEVTYPE type, HWND w, DWORD bf, D3DPRESENT_PARAMETERS* pp, IDirect3DDevice9** out)
{
    logParams("CreateDevice (requested)", pp, bf);
    const LONGLONG t = now();
    HRESULT hr = ((CreateDeviceFn)o_CreateDevice)(d3d, adapter, type, w, bf, pp, out);
    txt("CreateDevice adapter %u type %d hr 0x%08x %.1f ms", adapter, (int)type, hr, ms(now() - t));
    if (SUCCEEDED(hr) && out && *out)
    {
        logParams("CreateDevice (final)", pp, bf);
        hookDevice(*out);
    }
    return hr;
}

bool loadReal()
{
    if (g_real) return true;
    char path[MAX_PATH];
    UINT n = GetSystemDirectoryA(path, MAX_PATH - 16);
    if (n == 0 || n >= MAX_PATH - 16) return false;
    strcat(path, "\\d3d9.dll");
    g_real = LoadLibraryA(path);
    if (!g_real) return false;
    g_create9 = (Create9Fn)GetProcAddress(g_real, "Direct3DCreate9");
    g_create9ex = (Create9ExFn)GetProcAddress(g_real, "Direct3DCreate9Ex");
    return true;
}

FARPROC real(const char* name) { return loadReal() ? GetProcAddress(g_real, name) : NULL; }
}

extern "C" {
IDirect3D9* WINAPI Probe_Direct3DCreate9(UINT sdk)
{
    if (!loadReal() || !g_create9) return NULL;
    openFiles();
    IDirect3D9* d3d = g_create9(sdk);
    txt("Direct3DCreate9 sdk %u -> %p", sdk, d3d);
    if (d3d) patch(*(void***)d3d, 16, h_CreateDevice, &o_CreateDevice);
    return d3d;
}

HRESULT WINAPI Probe_Direct3DCreate9Ex(UINT sdk, IDirect3D9Ex** out)
{
    if (!loadReal() || !g_create9ex) return E_FAIL;
    openFiles();
    HRESULT hr = g_create9ex(sdk, out);
    txt("Direct3DCreate9Ex sdk %u hr 0x%08x", sdk, hr);
    if (SUCCEEDED(hr) && out && *out) patch(*(void***)*out, 16, h_CreateDevice, &o_CreateDevice);
    return hr;
}

int WINAPI Probe_D3DPERF_BeginEvent(D3DCOLOR c, LPCWSTR n)
{ typedef int (WINAPI* F)(D3DCOLOR, LPCWSTR); F f = (F)real("D3DPERF_BeginEvent"); return f ? f(c, n) : -1; }
int WINAPI Probe_D3DPERF_EndEvent(void)
{ typedef int (WINAPI* F)(void); F f = (F)real("D3DPERF_EndEvent"); return f ? f() : -1; }
void WINAPI Probe_D3DPERF_SetMarker(D3DCOLOR c, LPCWSTR n)
{ typedef void (WINAPI* F)(D3DCOLOR, LPCWSTR); F f = (F)real("D3DPERF_SetMarker"); if (f) f(c, n); }
void WINAPI Probe_D3DPERF_SetRegion(D3DCOLOR c, LPCWSTR n)
{ typedef void (WINAPI* F)(D3DCOLOR, LPCWSTR); F f = (F)real("D3DPERF_SetRegion"); if (f) f(c, n); }
BOOL WINAPI Probe_D3DPERF_QueryRepeatFrame(void)
{ typedef BOOL (WINAPI* F)(void); F f = (F)real("D3DPERF_QueryRepeatFrame"); return f ? f() : FALSE; }
void WINAPI Probe_D3DPERF_SetOptions(DWORD o)
{ typedef void (WINAPI* F)(DWORD); F f = (F)real("D3DPERF_SetOptions"); if (f) f(o); }
DWORD WINAPI Probe_D3DPERF_GetStatus(void)
{ typedef DWORD (WINAPI* F)(void); F f = (F)real("D3DPERF_GetStatus"); return f ? f() : 0; }
}

BOOL WINAPI DllMain(HINSTANCE, DWORD reason, LPVOID)
{
    if (reason == DLL_PROCESS_ATTACH)
    {
        InitializeCriticalSection(&g_lock);
        QueryPerformanceFrequency(&g_freq);
        QueryPerformanceCounter(&g_t0);
        g_process = GetCurrentProcess();
    }
    else if (reason == DLL_PROCESS_DETACH)
    {
        if (g_csv) fflush(g_csv);
        if (g_txt) fflush(g_txt);
    }
    return TRUE;
}
