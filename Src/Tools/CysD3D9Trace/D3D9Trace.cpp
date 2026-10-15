// CY-Source Src/Tools/CysD3D9Trace/D3D9Trace.cpp - d3d9.dll proxy (x64) recording every draw call of selected frames.
//
// Put the built d3d9.dll next to the exe of a PRIVATE COPY of a run folder (CY 3.71 Bin64, a CY-Source stage, a
// TlbbViewer bin copy). It loads the real %SystemRoot%\System32\d3d9.dll, patches the COM vtables of IDirect3D9,
// IDirect3DDevice9 and IDirect3DSwapChain9 (no wrapper objects: the application keeps the real interface pointers, so
// resource->GetDevice() identity and Ogre's per-device maps stay intact) and records nothing outside a captured frame
// except the Present timestamps.
//
// Configuration (environment variable, else key of [trace] in d3d9trace.ini next to this DLL):
//   CYS_D3DTRACE_DIR     output root (default <exe dir>\d3dtrace)
//   CYS_D3DTRACE_FRAMES  comma list of frame numbers to capture (frame n = calls between Present n-1 and Present n)
//   CYS_D3DTRACE_AT      comma list of seconds after the first Present
//   CYS_D3DTRACE_KEY     virtual key polled with GetAsyncKeyState at Present (default 0x7A = F11, 0 = off)
//   CYS_D3DTRACE_RT      1 = PNG of render target 0 at the end of every pass + back buffer at Present (default 1)
//   CYS_D3DTRACE_OCC     1 = occlusion query per draw -> visible pixel count "px" (default 1)
//   CYS_D3DTRACE_VB      1 = hash index range + referenced vertex bytes of managed buffers (default 1)
//   CYS_D3DTRACE_MAX     maximum number of captures (default 8)
//   CYS_D3DTRACE_RTMAX   maximum render-target PNGs per capture (default 64)
// A file <dir>\capture.now also triggers a capture of the next frame (its first line = label; the file is deleted).
//
// Output per capture <dir>\f<frame>_<label>\ : events.jsonl (ordered: setrt/setds/clear/stretchrect/colorfill/draw/
// marker/present), textures.jsonl, shaders.jsonl, draws.tsv, rt\*.png; shared <dir>\shaders\<hash>.<vs|ps>.{bin,asm};
// <dir>\frametimes.tsv (every Present), <dir>\trace.log.
#include <windows.h>
#include <d3d9.h>
#include <d3dx9.h>
#include <cstdio>
#include <cstdint>
#include <cstring>
#include <string>
#include <vector>
#include <map>
#include <set>
#include <unordered_map>
#include <algorithm>

namespace {

// ---------------------------------------------------------------------------------------------------------------- utils
uint64_t HashBytes(const void* data, size_t n, uint64_t seed = 0x6A09E667F3BCC909ULL)
{
    const uint8_t* p = static_cast<const uint8_t*>(data);
    uint64_t h = seed ^ (n * 0x9E3779B97F4A7C15ULL);
    size_t i = 0;
    for (; i + 8 <= n; i += 8) {
        uint64_t v;
        memcpy(&v, p + i, 8);
        v *= 0x87C37B91114253D5ULL;
        v = (v << 31) | (v >> 33);
        v *= 0x4CF5AD432745937FULL;
        h ^= v;
        h = ((h << 27) | (h >> 37)) * 5 + 0x52DCE729;
    }
    uint64_t t = 0;
    for (size_t k = 0; i < n; ++i, ++k) t |= uint64_t(p[i]) << (8 * k);
    h ^= t * 0x9E3779B97F4A7C15ULL;
    h ^= h >> 33; h *= 0xFF51AFD7ED558CCDULL; h ^= h >> 33; h *= 0xC4CEB9FE1A85EC53ULL; h ^= h >> 33;
    return h;
}

std::string Hex64(uint64_t v)
{
    char b[24];
    snprintf(b, sizeof b, "%016llx", (unsigned long long)v);
    return b;
}

std::string Fmt(const char* f, ...)
{
    char buf[1024];
    va_list ap;
    va_start(ap, f);
    int n = vsnprintf(buf, sizeof buf, f, ap);
    va_end(ap);
    if (n < 0) return std::string();
    if (n < (int)sizeof buf) return std::string(buf, n);
    std::string s(n + 1, '\0');
    va_start(ap, f);
    vsnprintf(&s[0], s.size(), f, ap);
    va_end(ap);
    s.resize(n);
    return s;
}

std::string FloatStr(float v)
{
    if (v != v) return "\"nan\"";
    if (v > 3.0e38f || v < -3.0e38f) return v > 0 ? "\"inf\"" : "\"-inf\"";
    char b[32];
    snprintf(b, sizeof b, "%.6g", v);
    return b;
}

std::string JStr(const std::string& s)
{
    std::string o = "\"";
    for (unsigned char c : s) {
        if (c == '"' || c == '\\') { o += '\\'; o += char(c); }
        else if (c < 0x20) o += Fmt("\\u%04x", c);
        else o += char(c);
    }
    return o + "\"";
}

std::string Narrow(const std::wstring& w)
{
    if (w.empty()) return std::string();
    int n = WideCharToMultiByte(CP_UTF8, 0, w.c_str(), (int)w.size(), nullptr, 0, nullptr, nullptr);
    std::string s(n, '\0');
    WideCharToMultiByte(CP_UTF8, 0, w.c_str(), (int)w.size(), &s[0], n, nullptr, nullptr);
    return s;
}

std::wstring Widen(const std::string& s)
{
    if (s.empty()) return std::wstring();
    int n = MultiByteToWideChar(CP_UTF8, 0, s.c_str(), (int)s.size(), nullptr, 0);
    std::wstring w(n, L'\0');
    MultiByteToWideChar(CP_UTF8, 0, s.c_str(), (int)s.size(), &w[0], n);
    return w;
}

void WriteFileAll(const std::wstring& path, const std::string& data, bool append = false)
{
    FILE* f = _wfopen(path.c_str(), append ? L"ab" : L"wb");
    if (!f) return;
    fwrite(data.data(), 1, data.size(), f);
    fclose(f);
}

bool FileExists(const std::wstring& p) { return GetFileAttributesW(p.c_str()) != INVALID_FILE_ATTRIBUTES; }

double NowSec()
{
    static LARGE_INTEGER freq = [] { LARGE_INTEGER f; QueryPerformanceFrequency(&f); return f; }();
    LARGE_INTEGER c;
    QueryPerformanceCounter(&c);
    return double(c.QuadPart) / double(freq.QuadPart);
}

// --------------------------------------------------------------------------------------------------------------- config
struct Config {
    std::wstring dir;
    std::vector<uint64_t> frames;
    std::vector<double> at;
    int key = 0x7A;
    bool rt = true, occ = true, vb = true;
    int vbDump = 0;     // L5b: CYS_D3DTRACE_VBDUMP = N bytes of every hashed vertex range written to <cap>\vb (0 = off)
    int maxCaps = 8, rtMax = 64;
} g_cfg;

HMODULE g_self = nullptr;
std::wstring g_iniPath;

std::wstring CfgValue(const wchar_t* name)
{
    wchar_t buf[2048];
    DWORD n = GetEnvironmentVariableW(name, buf, 2048);
    if (n > 0 && n < 2048) return std::wstring(buf, n);
    if (!g_iniPath.empty()) {
        n = GetPrivateProfileStringW(L"trace", name, L"", buf, 2048, g_iniPath.c_str());
        if (n > 0) return std::wstring(buf, n);
    }
    return std::wstring();
}

std::wstring g_logPath;
void Log(const std::string& s)
{
    if (g_logPath.empty()) return;
    SYSTEMTIME st;
    GetLocalTime(&st);
    WriteFileAll(g_logPath, Fmt("%02d:%02d:%02d.%03d ", st.wHour, st.wMinute, st.wSecond, st.wMilliseconds) + s + "\n", true);
}

void LoadConfig()
{
    wchar_t mod[MAX_PATH];
    GetModuleFileNameW(g_self, mod, MAX_PATH);
    std::wstring m(mod);
    g_iniPath = m.substr(0, m.find_last_of(L"\\/") + 1) + L"d3d9trace.ini";
    if (!FileExists(g_iniPath)) g_iniPath.clear();
    GetModuleFileNameW(nullptr, mod, MAX_PATH);
    std::wstring exe(mod);
    std::wstring d = CfgValue(L"CYS_D3DTRACE_DIR");
    g_cfg.dir = d.empty() ? exe.substr(0, exe.find_last_of(L"\\/") + 1) + L"d3dtrace" : d;
    while (!g_cfg.dir.empty() && (g_cfg.dir.back() == L'\\' || g_cfg.dir.back() == L'/')) g_cfg.dir.pop_back();
    CreateDirectoryW(g_cfg.dir.c_str(), nullptr);
    CreateDirectoryW((g_cfg.dir + L"\\shaders").c_str(), nullptr);
    g_logPath = g_cfg.dir + L"\\trace.log";
    auto list = [](const std::wstring& s) {
        std::vector<std::string> out;
        std::string a = Narrow(s), cur;
        for (char c : a) {
            if (c == ',' || c == ';' || c == ' ') { if (!cur.empty()) out.push_back(cur); cur.clear(); }
            else cur += c;
        }
        if (!cur.empty()) out.push_back(cur);
        return out;
    };
    for (auto& v : list(CfgValue(L"CYS_D3DTRACE_FRAMES"))) g_cfg.frames.push_back(strtoull(v.c_str(), nullptr, 10));
    for (auto& v : list(CfgValue(L"CYS_D3DTRACE_AT"))) g_cfg.at.push_back(atof(v.c_str()));
    std::sort(g_cfg.at.begin(), g_cfg.at.end());
    auto num = [](const wchar_t* n, int def) {
        std::wstring v = CfgValue(n);
        return v.empty() ? def : (int)wcstol(v.c_str(), nullptr, 0);
    };
    g_cfg.key = num(L"CYS_D3DTRACE_KEY", 0x7A);
    g_cfg.rt = num(L"CYS_D3DTRACE_RT", 1) != 0;
    g_cfg.occ = num(L"CYS_D3DTRACE_OCC", 1) != 0;
    g_cfg.vb = num(L"CYS_D3DTRACE_VB", 1) != 0;
    g_cfg.vbDump = num(L"CYS_D3DTRACE_VBDUMP", 0);
    g_cfg.maxCaps = num(L"CYS_D3DTRACE_MAX", 8);
    g_cfg.rtMax = num(L"CYS_D3DTRACE_RTMAX", 64);
    Log(Fmt("config: exe=%s dir=%s frames=%zu at=%zu key=0x%x rt=%d occ=%d vb=%d max=%d", Narrow(exe).c_str(),
            Narrow(g_cfg.dir).c_str(), g_cfg.frames.size(), g_cfg.at.size(), g_cfg.key, g_cfg.rt, g_cfg.occ, g_cfg.vb,
            g_cfg.maxCaps));
}

// ------------------------------------------------------------------------------------------------------ real d3d9/d3dx
HMODULE g_real = nullptr;
HMODULE Real()
{
    if (!g_real) {
        wchar_t sys[MAX_PATH];
        GetSystemDirectoryW(sys, MAX_PATH);
        g_real = LoadLibraryW((std::wstring(sys) + L"\\d3d9.dll").c_str());
    }
    return g_real;
}
FARPROC RealProc(const char* n) { HMODULE h = Real(); return h ? GetProcAddress(h, n) : nullptr; }

struct D3DX {
    HRESULT(WINAPI* Disassemble)(const DWORD*, BOOL, LPCSTR, LPD3DXBUFFER*) = nullptr;
    HRESULT(WINAPI* ConstTable)(const DWORD*, LPD3DXCONSTANTTABLE*) = nullptr;
    HRESULT(WINAPI* SaveSurface)(LPCWSTR, D3DXIMAGE_FILEFORMAT, LPDIRECT3DSURFACE9, const PALETTEENTRY*, const RECT*) = nullptr;
    bool tried = false;
} g_dx;

void LoadD3DX()
{
    if (g_dx.tried) return;
    g_dx.tried = true;
    HMODULE h = LoadLibraryW(L"d3dx9_43.dll");
    if (!h) { Log("d3dx9_43.dll not found: no disassembly / constant tables / PNG"); return; }
    g_dx.Disassemble = (decltype(g_dx.Disassemble))GetProcAddress(h, "D3DXDisassembleShader");
    g_dx.ConstTable = (decltype(g_dx.ConstTable))GetProcAddress(h, "D3DXGetShaderConstantTable");
    g_dx.SaveSurface = (decltype(g_dx.SaveSurface))GetProcAddress(h, "D3DXSaveSurfaceToFileW");
}

// ----------------------------------------------------------------------------------------------------- vtable patching
struct VTable { void** vt; void* orig[128]; };
VTable g_vts[16];
int g_nvts = 0;
CRITICAL_SECTION g_patchCs;

void** OrigOf(IUnknown* self)
{
    void** vt = *(void***)self;
    for (int i = 0; i < g_nvts; ++i)
        if (g_vts[i].vt == vt) return g_vts[i].orig;
    return nullptr;
}

void Patch(IUnknown* obj, int idx, void* hook)
{
    EnterCriticalSection(&g_patchCs);
    void** vt = *(void***)obj;
    VTable* t = nullptr;
    for (int i = 0; i < g_nvts; ++i)
        if (g_vts[i].vt == vt) t = &g_vts[i];
    if (!t && g_nvts < 16) {
        t = &g_vts[g_nvts++];
        t->vt = vt;
        memset(t->orig, 0, sizeof t->orig);
    }
    if (t && vt[idx] != hook) {
        t->orig[idx] = vt[idx];
        DWORD old;
        VirtualProtect(&vt[idx], sizeof(void*), PAGE_EXECUTE_READWRITE, &old);
        vt[idx] = hook;
        VirtualProtect(&vt[idx], sizeof(void*), old, &old);
    }
    LeaveCriticalSection(&g_patchCs);
}

#define ORIG(self, idx, T) ((T)OrigOf((IUnknown*)(self))[idx])

// Device vtable indices (Windows SDK d3d9.h order).
enum {
    kGetSwapChain = 14, kReset = 16, kPresent = 17, kGetBackBuffer = 18, kCreateRenderTarget = 28,
    kUpdateSurface = 30, kUpdateTexture = 31, kGetRenderTargetData = 32, kStretchRect = 34, kColorFill = 35,
    kCreateOffscreenPlainSurface = 36, kSetRenderTarget = 37, kSetDepthStencilSurface = 39, kBeginScene = 41,
    kEndScene = 42, kClear = 43, kDrawPrimitive = 81, kDrawIndexedPrimitive = 82, kDrawPrimitiveUP = 83,
    kDrawIndexedPrimitiveUP = 84, kSwapChainPresent = 3, kD3DCreateDevice = 16, kD3DCreateDeviceEx = 20
};

// ------------------------------------------------------------------------------------------------------------- names
std::string FmtName(D3DFORMAT f)
{
    switch (f) {
#define F(x) case D3DFMT_##x: return #x;
    F(UNKNOWN) F(R8G8B8) F(A8R8G8B8) F(X8R8G8B8) F(R5G6B5) F(X1R5G5B5) F(A1R5G5B5) F(A4R4G4B4) F(R3G3B2) F(A8)
    F(A8R3G3B2) F(X4R4G4B4) F(A2B10G10R10) F(A8B8G8R8) F(X8B8G8R8) F(G16R16) F(A2R10G10B10) F(A16B16G16R16) F(A8P8)
    F(P8) F(L8) F(A8L8) F(A4L4) F(V8U8) F(L6V5U5) F(X8L8V8U8) F(Q8W8V8U8) F(V16U16) F(A2W10V10U10) F(D16_LOCKABLE)
    F(D32) F(D15S1) F(D24S8) F(D24X8) F(D24X4S4) F(D16) F(D32F_LOCKABLE) F(D24FS8) F(L16) F(Q16W16V16U16) F(R16F)
    F(G16R16F) F(A16B16G16R16F) F(R32F) F(G32R32F) F(A32B32G32R32F) F(CxV8U8) F(INDEX16) F(INDEX32)
#undef F
    default: break;
    }
    DWORD v = (DWORD)f;
    if (v > 0xFFFF) {
        char s[5] = { char(v & 0xFF), char((v >> 8) & 0xFF), char((v >> 16) & 0xFF), char((v >> 24) & 0xFF), 0 };
        for (int i = 0; i < 4; ++i) if (s[i] < 0x20 || s[i] > 0x7E) s[i] = '?';
        return s;
    }
    return Fmt("fmt%u", v);
}

bool IsCompressed(D3DFORMAT f)
{
    DWORD v = (DWORD)f;
    return v == MAKEFOURCC('D', 'X', 'T', '1') || v == MAKEFOURCC('D', 'X', 'T', '2') || v == MAKEFOURCC('D', 'X', 'T', '3') ||
           v == MAKEFOURCC('D', 'X', 'T', '4') || v == MAKEFOURCC('D', 'X', 'T', '5') || v == MAKEFOURCC('A', 'T', 'I', '1') ||
           v == MAKEFOURCC('A', 'T', 'I', '2');
}

bool IsFloatFmt(D3DFORMAT f)
{
    return f == D3DFMT_R16F || f == D3DFMT_G16R16F || f == D3DFMT_A16B16G16R16F || f == D3DFMT_R32F ||
           f == D3DFMT_G32R32F || f == D3DFMT_A32B32G32R32F || f == D3DFMT_A2R10G10B10 || f == D3DFMT_A2B10G10R10 ||
           f == D3DFMT_A16B16G16R16 || f == D3DFMT_G16R16;
}

struct Named { DWORD id; const char* name; };
#define RS(x) { D3DRS_##x, #x }
const Named kRenderStates[] = {
    RS(ZENABLE), RS(FILLMODE), RS(SHADEMODE), RS(ZWRITEENABLE), RS(ALPHATESTENABLE), RS(LASTPIXEL), RS(SRCBLEND),
    RS(DESTBLEND), RS(CULLMODE), RS(ZFUNC), RS(ALPHAREF), RS(ALPHAFUNC), RS(DITHERENABLE), RS(ALPHABLENDENABLE),
    RS(FOGENABLE), RS(SPECULARENABLE), RS(FOGCOLOR), RS(FOGTABLEMODE), RS(FOGSTART), RS(FOGEND), RS(FOGDENSITY),
    RS(RANGEFOGENABLE), RS(STENCILENABLE), RS(STENCILFAIL), RS(STENCILZFAIL), RS(STENCILPASS), RS(STENCILFUNC),
    RS(STENCILREF), RS(STENCILMASK), RS(STENCILWRITEMASK), RS(TEXTUREFACTOR), RS(WRAP0), RS(CLIPPING), RS(LIGHTING),
    RS(AMBIENT), RS(FOGVERTEXMODE), RS(COLORVERTEX), RS(LOCALVIEWER), RS(NORMALIZENORMALS),
    RS(DIFFUSEMATERIALSOURCE), RS(AMBIENTMATERIALSOURCE), RS(VERTEXBLEND), RS(CLIPPLANEENABLE), RS(POINTSIZE),
    RS(POINTSPRITEENABLE), RS(MULTISAMPLEANTIALIAS), RS(MULTISAMPLEMASK), RS(INDEXEDVERTEXBLENDENABLE),
    RS(COLORWRITEENABLE), RS(BLENDOP), RS(SCISSORTESTENABLE), RS(SLOPESCALEDEPTHBIAS), RS(ANTIALIASEDLINEENABLE),
    RS(TWOSIDEDSTENCILMODE), RS(CCW_STENCILFUNC), RS(COLORWRITEENABLE1), RS(COLORWRITEENABLE2), RS(COLORWRITEENABLE3),
    RS(BLENDFACTOR), RS(SRGBWRITEENABLE), RS(DEPTHBIAS), RS(SEPARATEALPHABLENDENABLE), RS(SRCBLENDALPHA),
    RS(DESTBLENDALPHA), RS(BLENDOPALPHA)
};
#undef RS
#define SS(x) { D3DSAMP_##x, #x }
const Named kSamplerStates[] = {
    SS(ADDRESSU), SS(ADDRESSV), SS(ADDRESSW), SS(BORDERCOLOR), SS(MAGFILTER), SS(MINFILTER), SS(MIPFILTER),
    SS(MIPMAPLODBIAS), SS(MAXMIPLEVEL), SS(MAXANISOTROPY), SS(SRGBTEXTURE)
};
#undef SS
#define TS(x) { D3DTSS_##x, #x }
const Named kStageStates[] = {
    TS(COLOROP), TS(COLORARG1), TS(COLORARG2), TS(ALPHAOP), TS(ALPHAARG1), TS(ALPHAARG2), TS(TEXCOORDINDEX),
    TS(TEXTURETRANSFORMFLAGS), TS(COLORARG0), TS(ALPHAARG0), TS(RESULTARG)
};
#undef TS

const char* DeclTypeName(BYTE t)
{
    static const char* n[] = { "FLOAT1", "FLOAT2", "FLOAT3", "FLOAT4", "D3DCOLOR", "UBYTE4", "SHORT2", "SHORT4",
                               "UBYTE4N", "SHORT2N", "SHORT4N", "USHORT2N", "USHORT4N", "UDEC3", "DEC3N", "FLOAT16_2",
                               "FLOAT16_4" };
    return t < 17 ? n[t] : "UNUSED";
}
const char* DeclUsageName(BYTE u)
{
    static const char* n[] = { "POSITION", "BLENDWEIGHT", "BLENDINDICES", "NORMAL", "PSIZE", "TEXCOORD", "TANGENT",
                               "BINORMAL", "TESSFACTOR", "POSITIONT", "COLOR", "FOG", "DEPTH", "SAMPLE" };
    return u < 14 ? n[u] : "?";
}

// ------------------------------------------------------------------------------------------------------ shader database
struct ConstDesc { std::string name; int set; int reg; int count; int cls; int type; int rows; int cols; int elems; };
struct ShaderInfo {
    std::string hash, kind;
    size_t size = 0;
    bool ctab = false;
    std::vector<ConstDesc> consts;
    std::vector<int> samplers;
    std::string json;
};
std::map<std::string, ShaderInfo> g_shaders; // by kind:hash
std::set<std::string> g_shaderFilesWritten;

void ScanDisasm(const std::string& asmText, ShaderInfo& si)
{
    // Without a constant table (Cg / assembled shaders): register references c#, i#, b# outside def lines;
    // relative addressing c#[a0.x] gets a 32-register window. Samplers from dcl_* s# lines.
    std::map<int, int> fl, in, bo;
    std::set<int> defs;
    size_t pos = 0;
    while (pos < asmText.size()) {
        size_t e = asmText.find('\n', pos);
        if (e == std::string::npos) e = asmText.size();
        std::string line = asmText.substr(pos, e - pos);
        pos = e + 1;
        size_t k = line.find_first_not_of(" \t");
        if (k == std::string::npos || line.compare(k, 2, "//") == 0) continue;
        std::string l = line.substr(k);
        if (l.compare(0, 4, "dcl_") == 0) {
            size_t s = l.find(" s");
            bool texDecl = l.compare(0, 6, "dcl_2d") == 0 || l.compare(0, 8, "dcl_cube") == 0 || l.compare(0, 10, "dcl_volume") == 0;
            if (texDecl && s != std::string::npos) si.samplers.push_back(atoi(l.c_str() + s + 2));
            continue;
        }
        bool isDef = l.compare(0, 3, "def") == 0 || l.compare(0, 4, "defi") == 0 || l.compare(0, 4, "defb") == 0;
        for (size_t i = 0; i + 1 < l.size(); ++i) {
            char c = l[i];
            if ((c == 'c' || c == 'i' || c == 'b') && (i == 0 || (!isalnum((unsigned char)l[i - 1]) && l[i - 1] != '_')) &&
                isdigit((unsigned char)l[i + 1])) {
                int reg = atoi(l.c_str() + i + 1);
                size_t j = i + 1;
                while (j < l.size() && isdigit((unsigned char)l[j])) ++j;
                if (j < l.size() && (isalpha((unsigned char)l[j]) || l[j] == '_')) continue;
                bool rel = j < l.size() && l[j] == '[';
                if (isDef) { if (c == 'c') defs.insert(reg); break; }
                auto& m = c == 'c' ? fl : c == 'i' ? in : bo;
                int cnt = rel ? 32 : 1;
                auto it = m.find(reg);
                if (it == m.end() || it->second < cnt) m[reg] = cnt;
            }
        }
    }
    auto add = [&](std::map<int, int>& m, int set, const char* p) {
        for (auto& kv : m) {
            if (set == 2 && defs.count(kv.first)) continue;
            ConstDesc d;
            d.name = Fmt("%s%d%s", p, kv.first, kv.second > 1 ? "[]" : "");
            d.set = set; d.reg = kv.first; d.count = kv.second; d.cls = 0; d.type = 0; d.rows = 1; d.cols = 4; d.elems = 1;
            si.consts.push_back(d);
        }
    };
    add(fl, 2, "c");
    add(in, 1, "i");
    add(bo, 0, "b");
    std::sort(si.samplers.begin(), si.samplers.end());
    si.samplers.erase(std::unique(si.samplers.begin(), si.samplers.end()), si.samplers.end());
}

ShaderInfo* GetShaderInfo(IUnknown* shader, bool pixel)
{
    if (!shader) return nullptr;
    UINT size = 0;
    HRESULT hr = pixel ? ((IDirect3DPixelShader9*)shader)->GetFunction(nullptr, &size)
                       : ((IDirect3DVertexShader9*)shader)->GetFunction(nullptr, &size);
    if (FAILED(hr) || size == 0) return nullptr;
    std::vector<char> code(size);
    hr = pixel ? ((IDirect3DPixelShader9*)shader)->GetFunction(code.data(), &size)
               : ((IDirect3DVertexShader9*)shader)->GetFunction(code.data(), &size);
    if (FAILED(hr)) return nullptr;
    std::string hash = Hex64(HashBytes(code.data(), size));
    std::string kind = pixel ? "ps" : "vs";
    std::string key = kind + ":" + hash;
    auto it = g_shaders.find(key);
    if (it != g_shaders.end()) return &it->second;
    ShaderInfo& si = g_shaders[key];
    si.hash = hash; si.kind = kind; si.size = size;
    LoadD3DX();
    std::wstring base = g_cfg.dir + L"\\shaders\\" + Widen(hash + "." + kind);
    WriteFileAll(base + L".bin", std::string(code.data(), size));
    std::string asmText;
    if (g_dx.Disassemble) {
        LPD3DXBUFFER buf = nullptr;
        if (SUCCEEDED(g_dx.Disassemble((const DWORD*)code.data(), FALSE, nullptr, &buf)) && buf) {
            asmText.assign((const char*)buf->GetBufferPointer(), strnlen((const char*)buf->GetBufferPointer(), buf->GetBufferSize()));
            buf->Release();
            WriteFileAll(base + L".asm", asmText);
        }
    }
    if (g_dx.ConstTable) {
        LPD3DXCONSTANTTABLE ct = nullptr;
        if (SUCCEEDED(g_dx.ConstTable((const DWORD*)code.data(), &ct)) && ct) {
            D3DXCONSTANTTABLE_DESC td;
            if (SUCCEEDED(ct->GetDesc(&td)) && td.Constants > 0) {
                si.ctab = true;
                for (UINT i = 0; i < td.Constants; ++i) {
                    D3DXHANDLE h = ct->GetConstant(nullptr, i);
                    D3DXCONSTANT_DESC cd;
                    UINT n = 1;
                    if (!h || FAILED(ct->GetConstantDesc(h, &cd, &n))) continue;
                    if (cd.RegisterSet == D3DXRS_SAMPLER) {
                        for (UINT r = 0; r < cd.RegisterCount; ++r) si.samplers.push_back(int(cd.RegisterIndex + r));
                        continue;
                    }
                    ConstDesc d;
                    d.name = cd.Name ? cd.Name : "?";
                    d.set = cd.RegisterSet == D3DXRS_BOOL ? 0 : cd.RegisterSet == D3DXRS_INT4 ? 1 : 2;
                    d.reg = int(cd.RegisterIndex); d.count = int(cd.RegisterCount); d.cls = int(cd.Class);
                    d.type = int(cd.Type); d.rows = int(cd.Rows); d.cols = int(cd.Columns); d.elems = int(cd.Elements);
                    si.consts.push_back(d);
                }
                std::sort(si.samplers.begin(), si.samplers.end());
            }
            ct->Release();
        }
    }
    if (!si.ctab && !asmText.empty()) ScanDisasm(asmText, si);
    std::string j = Fmt("{\"kind\":\"%s\",\"hash\":\"%s\",\"size\":%u,\"ctab\":%s,\"samplers\":[", kind.c_str(), hash.c_str(),
                        (unsigned)size, si.ctab ? "true" : "false");
    for (size_t i = 0; i < si.samplers.size(); ++i) j += Fmt("%s%d", i ? "," : "", si.samplers[i]);
    j += "],\"consts\":[";
    for (size_t i = 0; i < si.consts.size(); ++i) {
        const ConstDesc& d = si.consts[i];
        j += Fmt("%s{\"name\":%s,\"set\":\"%s\",\"reg\":%d,\"count\":%d,\"class\":%d,\"type\":%d,\"rows\":%d,\"cols\":%d,\"elems\":%d}",
                 i ? "," : "", JStr(d.name).c_str(), d.set == 2 ? "f" : d.set == 1 ? "i" : "b", d.reg, d.count, d.cls, d.type,
                 d.rows, d.cols, d.elems);
    }
    si.json = j + "]}";
    return &si;
}

// --------------------------------------------------------------------------------------------------------------- capture
struct Event { std::string json; IDirect3DQuery9* query = nullptr; bool draw = false; };
struct Capture {
    bool active = false;
    uint64_t frame = 0;
    std::string label;
    std::wstring dir;
    double t0 = 0;
    DWORD thread = 0;
    std::vector<Event> events;
    std::unordered_map<void*, std::string> texIds;     // texture/surface pointer -> id
    std::map<std::string, std::string> texJson;          // id -> json line
    std::set<std::string> shaderKeys;
    std::unordered_map<void*, std::string> rtIds;       // render-target key -> id
    std::unordered_map<void*, std::string> declCache;
    int rtCount = 0, pass = 0, drawsInPass = 0, rtDumps = 0, draws = 0;
    std::string curRt;
    IDirect3DSurface9* backBuffer = nullptr;
} g_cap;

uint64_t g_frame = 0;
int g_caps = 0;
double g_firstPresent = 0, g_lastPresent = 0;
size_t g_atIndex = 0;
bool g_keyDown = false;
std::string g_frameTimes;
thread_local int t_inside = 0;

struct Inside { Inside() { ++t_inside; } ~Inside() { --t_inside; } };

std::string RtKeyId(IDirect3DDevice9* dev, IDirect3DSurface9* s, std::string* descOut = nullptr)
{
    if (!s) return "null";
    void* key = s;
    IDirect3DTexture9* tex = nullptr;
    if (SUCCEEDED(s->GetContainer(IID_IDirect3DTexture9, (void**)&tex)) && tex) { key = tex; tex->Release(); }
    else {
        IDirect3DCubeTexture9* cube = nullptr;
        if (SUCCEEDED(s->GetContainer(IID_IDirect3DCubeTexture9, (void**)&cube)) && cube) { key = cube; cube->Release(); }
    }
    auto it = g_cap.rtIds.find(key);
    if (it != g_cap.rtIds.end()) return it->second;
    D3DSURFACE_DESC d;
    s->GetDesc(&d);
    std::string id = (s == g_cap.backBuffer) ? std::string("bb") : Fmt("rt%d", ++g_cap.rtCount);
    g_cap.rtIds[key] = id;
    std::string j = Fmt("{\"id\":\"%s\",\"type\":\"%s\",\"w\":%u,\"h\":%u,\"fmt\":\"%s\",\"usage\":%lu,\"pool\":%d,\"msaa\":%d,\"msq\":%lu}",
                        id.c_str(), key != (void*)s ? "rt-texture" : (id == "bb" ? "backbuffer" : "rt-surface"), d.Width, d.Height,
                        FmtName(d.Format).c_str(), d.Usage, int(d.Pool), int(d.MultiSampleType), d.MultiSampleQuality);
    g_cap.texJson[id] = j;
    if (descOut) *descOut = j;
    return id;
}

std::string TexId(IDirect3DDevice9* dev, IDirect3DBaseTexture9* t)
{
    if (!t) return "null";
    auto it = g_cap.texIds.find(t);
    if (it != g_cap.texIds.end()) return it->second;
    D3DRESOURCETYPE type = t->GetType();
    DWORD levels = t->GetLevelCount();
    std::string id, typeName;
    UINT w = 0, h = 0, depth = 1;
    D3DFORMAT fmt = D3DFMT_UNKNOWN;
    DWORD usage = 0;
    D3DPOOL pool = D3DPOOL_DEFAULT;
    uint64_t hash = 0;
    bool hashed = false;
    if (type == D3DRTYPE_TEXTURE || type == D3DRTYPE_CUBETEXTURE) {
        D3DSURFACE_DESC d;
        if (type == D3DRTYPE_TEXTURE) ((IDirect3DTexture9*)t)->GetLevelDesc(0, &d);
        else ((IDirect3DCubeTexture9*)t)->GetLevelDesc(0, &d);
        w = d.Width; h = d.Height; fmt = d.Format; usage = d.Usage; pool = d.Pool;
        typeName = type == D3DRTYPE_TEXTURE ? "2d" : "cube";
        if (usage & (D3DUSAGE_RENDERTARGET | D3DUSAGE_DEPTHSTENCIL)) {
            IDirect3DSurface9* s = nullptr;
            HRESULT hr = type == D3DRTYPE_TEXTURE ? ((IDirect3DTexture9*)t)->GetSurfaceLevel(0, &s)
                                                  : ((IDirect3DCubeTexture9*)t)->GetCubeMapSurface(D3DCUBEMAP_FACE_POSITIVE_X, 0, &s);
            if (SUCCEEDED(hr) && s) {
                id = RtKeyId(dev, s);
                s->Release();
            }
            g_cap.texIds[t] = id;
            return id;
        }
        if (pool != D3DPOOL_DEFAULT || (usage & D3DUSAGE_DYNAMIC)) {
            D3DLOCKED_RECT lr;
            HRESULT hr = type == D3DRTYPE_TEXTURE
                             ? ((IDirect3DTexture9*)t)->LockRect(0, &lr, nullptr, D3DLOCK_READONLY | D3DLOCK_NOSYSLOCK)
                             : ((IDirect3DCubeTexture9*)t)->LockRect(D3DCUBEMAP_FACE_POSITIVE_X, 0, &lr, nullptr,
                                                                    D3DLOCK_READONLY | D3DLOCK_NOSYSLOCK);
            if (SUCCEEDED(hr)) {
                size_t rows = IsCompressed(fmt) ? (h + 3) / 4 : h;
                hash = HashBytes(lr.pBits, size_t(lr.Pitch) * rows);
                hashed = true;
                if (type == D3DRTYPE_TEXTURE) ((IDirect3DTexture9*)t)->UnlockRect(0);
                else ((IDirect3DCubeTexture9*)t)->UnlockRect(D3DCUBEMAP_FACE_POSITIVE_X, 0);
            }
        }
    } else if (type == D3DRTYPE_VOLUMETEXTURE) {
        D3DVOLUME_DESC d;
        ((IDirect3DVolumeTexture9*)t)->GetLevelDesc(0, &d);
        w = d.Width; h = d.Height; depth = d.Depth; fmt = d.Format; usage = d.Usage; pool = d.Pool;
        typeName = "volume";
    }
    if (hashed) id = "t" + Hex64(hash).substr(0, 12);
    else id = Fmt("tx%zu", g_cap.texIds.size() + 1);
    // two different texture objects with identical content share an id (same data loaded twice) - keep one record
    g_cap.texIds[t] = id;
    if (!g_cap.texJson.count(id))
        g_cap.texJson[id] = Fmt("{\"id\":\"%s\",\"type\":\"%s\",\"w\":%u,\"h\":%u,\"d\":%u,\"fmt\":\"%s\",\"levels\":%lu,\"usage\":%lu,\"pool\":%d,\"hash\":\"%s\"}",
                                id.c_str(), typeName.c_str(), w, h, depth, FmtName(fmt).c_str(), levels, usage, int(pool),
                                hashed ? Hex64(hash).c_str() : "");
    return id;
}

std::string DeclDesc(IDirect3DVertexDeclaration9* decl, int* maxStream)
{
    *maxStream = 0;
    if (!decl) return "";
    UINT n = 0;
    decl->GetDeclaration(nullptr, &n);
    std::vector<D3DVERTEXELEMENT9> el(n);
    if (n == 0 || FAILED(decl->GetDeclaration(el.data(), &n))) return "";
    std::string s;
    for (UINT i = 0; i < n; ++i) {
        if (el[i].Stream == 0xFF) break;
        if (el[i].Stream > *maxStream) *maxStream = el[i].Stream;
        s += Fmt("%s%u:%u:%s%u:%s", s.empty() ? "" : "|", el[i].Stream, el[i].Offset, DeclUsageName(el[i].Usage),
                 el[i].UsageIndex, DeclTypeName(el[i].Type));
    }
    return s;
}

UINT IndexCount(D3DPRIMITIVETYPE pt, UINT pc)
{
    switch (pt) {
    case D3DPT_POINTLIST: return pc;
    case D3DPT_LINELIST: return pc * 2;
    case D3DPT_LINESTRIP: return pc + 1;
    case D3DPT_TRIANGLELIST: return pc * 3;
    case D3DPT_TRIANGLESTRIP: case D3DPT_TRIANGLEFAN: return pc + 2;
    default: return pc;
    }
}

std::string ConstValues(IDirect3DDevice9* dev, const ShaderInfo* si, bool pixel)
{
    std::string j = "{";
    bool first = true;
    for (const ConstDesc& d : si->consts) {
        int cnt = std::min(d.count, 256);
        std::string vals;
        if (d.set == 2) {
            std::vector<float> v(size_t(cnt) * 4);
            HRESULT hr = pixel ? dev->GetPixelShaderConstantF(d.reg, v.data(), cnt) : dev->GetVertexShaderConstantF(d.reg, v.data(), cnt);
            if (FAILED(hr)) continue;
            size_t show = std::min<size_t>(v.size(), 16);
            // a single scalar/vector: print only its columns
            if (d.count == 1 && d.rows == 1 && d.cols >= 1 && d.cols <= 4) show = d.cols;
            vals = "[";
            for (size_t i = 0; i < show; ++i) vals += (i ? "," : "") + FloatStr(v[i]);
            vals += "]";
            if (v.size() > 16) vals = Fmt("{\"n\":%d,\"hash\":\"%s\",\"head\":%s}", cnt, Hex64(HashBytes(v.data(), v.size() * 4)).c_str(), vals.c_str());
        } else if (d.set == 1) {
            std::vector<int> v(size_t(cnt) * 4);
            HRESULT hr = pixel ? dev->GetPixelShaderConstantI(d.reg, v.data(), cnt) : dev->GetVertexShaderConstantI(d.reg, v.data(), cnt);
            if (FAILED(hr)) continue;
            vals = "[";
            for (size_t i = 0; i < std::min<size_t>(v.size(), 16); ++i) vals += Fmt("%s%d", i ? "," : "", v[i]);
            vals += "]";
        } else {
            std::vector<BOOL> v(cnt);
            HRESULT hr = pixel ? dev->GetPixelShaderConstantB(d.reg, v.data(), cnt) : dev->GetVertexShaderConstantB(d.reg, v.data(), cnt);
            if (FAILED(hr)) continue;
            vals = "[";
            for (size_t i = 0; i < std::min<size_t>(v.size(), 16); ++i) vals += Fmt("%s%d", i ? "," : "", v[i]);
            vals += "]";
        }
        j += (first ? "" : ",") + JStr(d.name) + ":" + vals;
        first = false;
    }
    return j + "}";
}

std::string DescribeDraw(IDirect3DDevice9* dev, const char* api, D3DPRIMITIVETYPE pt, int base, UINT minV, UINT numV,
                         UINT start, UINT pc, const void* upIdx, D3DFORMAT upIdxFmt, const void* upVtx, UINT upStride)
{
    std::string j = Fmt("{\"ev\":\"draw\",\"n\":%d,\"pass\":%d,\"api\":\"%s\",\"prim\":%d,\"base\":%d,\"minv\":%u,\"nv\":%u,\"start\":%u,\"pc\":%u",
                        g_cap.draws, g_cap.pass, api, int(pt), base, minV, numV, start, pc);
    j += Fmt(",\"t\":%.3f", (NowSec() - g_cap.t0) * 1000.0);
    // render targets / depth / viewport / scissor
    j += ",\"rt\":[";
    for (DWORD i = 0; i < 4; ++i) {
        IDirect3DSurface9* s = nullptr;
        if (FAILED(dev->GetRenderTarget(i, &s)) || !s) break;
        j += (i ? "," : "") + JStr(RtKeyId(dev, s));
        s->Release();
    }
    j += "]";
    IDirect3DSurface9* ds = nullptr;
    if (SUCCEEDED(dev->GetDepthStencilSurface(&ds)) && ds) {
        D3DSURFACE_DESC d;
        ds->GetDesc(&d);
        j += Fmt(",\"ds\":\"%ux%u:%s\"", d.Width, d.Height, FmtName(d.Format).c_str());
        ds->Release();
    } else j += ",\"ds\":null";
    D3DVIEWPORT9 vp;
    dev->GetViewport(&vp);
    j += Fmt(",\"vp\":[%lu,%lu,%lu,%lu,%s,%s]", vp.X, vp.Y, vp.Width, vp.Height, FloatStr(vp.MinZ).c_str(), FloatStr(vp.MaxZ).c_str());
    DWORD scis = 0;
    dev->GetRenderState(D3DRS_SCISSORTESTENABLE, &scis);
    if (scis) {
        RECT r;
        dev->GetScissorRect(&r);
        j += Fmt(",\"scissor\":[%ld,%ld,%ld,%ld]", r.left, r.top, r.right, r.bottom);
    }
    // render states
    j += ",\"rs\":{";
    for (size_t i = 0; i < sizeof kRenderStates / sizeof kRenderStates[0]; ++i) {
        DWORD v = 0;
        dev->GetRenderState((D3DRENDERSTATETYPE)kRenderStates[i].id, &v);
        if (kRenderStates[i].id == D3DRS_FOGSTART || kRenderStates[i].id == D3DRS_FOGEND || kRenderStates[i].id == D3DRS_FOGDENSITY ||
            kRenderStates[i].id == D3DRS_POINTSIZE || kRenderStates[i].id == D3DRS_SLOPESCALEDEPTHBIAS || kRenderStates[i].id == D3DRS_DEPTHBIAS) {
            float f;
            memcpy(&f, &v, 4);
            j += Fmt("%s\"%s\":%s", i ? "," : "", kRenderStates[i].name, FloatStr(f).c_str());
        } else j += Fmt("%s\"%s\":%lu", i ? "," : "", kRenderStates[i].name, v);
    }
    j += "}";
    // shaders
    IDirect3DVertexShader9* vs = nullptr;
    IDirect3DPixelShader9* ps = nullptr;
    dev->GetVertexShader(&vs);
    dev->GetPixelShader(&ps);
    ShaderInfo* vsi = GetShaderInfo(vs, false);
    ShaderInfo* psi = GetShaderInfo(ps, true);
    if (vs) vs->Release();
    if (ps) ps->Release();
    j += ",\"vs\":" + (vsi ? JStr(vsi->hash) : std::string("null"));
    j += ",\"ps\":" + (psi ? JStr(psi->hash) : std::string("null"));
    if (vsi) g_cap.shaderKeys.insert("vs:" + vsi->hash);
    if (psi) g_cap.shaderKeys.insert("ps:" + psi->hash);
    if (vsi) j += ",\"vsc\":" + ConstValues(dev, vsi, false);
    if (psi) j += ",\"psc\":" + ConstValues(dev, psi, true);
    // vertex layout + streams
    IDirect3DVertexDeclaration9* decl = nullptr;
    dev->GetVertexDeclaration(&decl);
    int maxStream = 0;
    std::string dd;
    if (decl) {
        auto it = g_cap.declCache.find(decl);
        if (it != g_cap.declCache.end()) dd = it->second;
        else g_cap.declCache[decl] = dd = DeclDesc(decl, &maxStream);
        for (size_t p = dd.find('|'), q = 0; ; p = dd.find('|', q)) {
            int st = atoi(dd.c_str() + q);
            if (st > maxStream) maxStream = st;
            if (p == std::string::npos) break;
            q = p + 1;
        }
        decl->Release();
    }
    DWORD fvf = 0;
    dev->GetFVF(&fvf);
    j += ",\"decl\":" + JStr(dd) + Fmt(",\"fvf\":%lu", fvf);
    j += ",\"streams\":[";
    uint64_t geomHash = 0;
    for (int s = 0; s <= maxStream && !upVtx; ++s) {
        IDirect3DVertexBuffer9* vb = nullptr;
        UINT off = 0, stride = 0, freq = 1;
        dev->GetStreamSource(s, &vb, &off, &stride);
        dev->GetStreamSourceFreq(s, &freq);
        std::string vh;
        if (vb) {
            D3DVERTEXBUFFER_DESC vd;
            vb->GetDesc(&vd);
            if (g_cfg.vb && stride > 0 && (vd.Pool != D3DPOOL_DEFAULT)) {
                // DIP: vertices base+minV .. +numV; DP: start .. +vertex count of the primitives
                UINT first = UINT(std::max(0, base + int(minV)));
                UINT bytesOff = off + first * stride;
                UINT bytes = std::min<UINT>(numV * stride, 64 * 1024);
                if (strcmp(api, "DP") == 0) { bytesOff = off + start * stride; bytes = std::min<UINT>(IndexCount(pt, pc) * stride, 64 * 1024); }
                if (bytesOff + bytes <= vd.Size) {
                    void* p = nullptr;
                    if (SUCCEEDED(vb->Lock(bytesOff, bytes, &p, D3DLOCK_READONLY | D3DLOCK_NOSYSLOCK)) && p) {
                        uint64_t h = HashBytes(p, bytes);
                        if (g_cfg.vbDump > 0) {     // L5b: raw vertices for layout / UV analysis
                            CreateDirectoryW((g_cap.dir + L"\\vb").c_str(), nullptr);
                            WriteFileAll(g_cap.dir + L"\\vb\\" + Widen(Fmt("d%05d_s%d.bin", g_cap.draws, s)),
                                         std::string(static_cast<const char*>(p), std::min<UINT>(bytes, UINT(g_cfg.vbDump))));
                        }
                        vb->Unlock();
                        vh = Hex64(h);
                        geomHash ^= h * (s + 1);
                    }
                }
            }
            j += Fmt("%s{\"s\":%d,\"off\":%u,\"stride\":%u,\"freq\":%u,\"size\":%u,\"pool\":%d,\"usage\":%lu,\"hash\":%s}", s ? "," : "", s, off,
                     stride, freq, vd.Size, int(vd.Pool), vd.Usage, vh.empty() ? "null" : JStr(vh).c_str());
            vb->Release();
        } else j += Fmt("%snull", s ? "," : "");
    }
    j += "]";
    if (strcmp(api, "DIP") == 0) {
        IDirect3DIndexBuffer9* ib = nullptr;
        dev->GetIndices(&ib);
        if (ib) {
            D3DINDEXBUFFER_DESC id;
            ib->GetDesc(&id);
            UINT isz = id.Format == D3DFMT_INDEX32 ? 4 : 2;
            std::string ih;
            if (g_cfg.vb && id.Pool != D3DPOOL_DEFAULT) {
                UINT bytes = std::min<UINT>(IndexCount(pt, pc) * isz, 256 * 1024);
                if (start * isz + bytes <= id.Size) {
                    void* p = nullptr;
                    if (SUCCEEDED(ib->Lock(start * isz, bytes, &p, D3DLOCK_READONLY | D3DLOCK_NOSYSLOCK)) && p) {
                        uint64_t h = HashBytes(p, bytes);
                        ib->Unlock();
                        ih = Hex64(h);
                        geomHash ^= h;
                    }
                }
            }
            j += Fmt(",\"ib\":{\"fmt\":%u,\"size\":%u,\"pool\":%d,\"hash\":%s}", isz * 8, id.Size, int(id.Pool), ih.empty() ? "null" : JStr(ih).c_str());
            ib->Release();
        }
    }
    if (upVtx) {
        uint64_t h = HashBytes(upVtx, size_t(std::min<UINT>(numV ? numV : IndexCount(pt, pc), 65536)) * upStride);
        if (upIdx) h ^= HashBytes(upIdx, size_t(IndexCount(pt, pc)) * (upIdxFmt == D3DFMT_INDEX32 ? 4 : 2));
        geomHash = h;
        j += Fmt(",\"upstride\":%u", upStride);
    }
    j += ",\"geom\":" + (geomHash ? JStr(Hex64(geomHash)) : std::string("null"));
    // textures + samplers: PS samplers, else fixed-function stages until COLOROP = DISABLE
    std::vector<int> stages;
    if (psi) stages = psi->samplers;
    else {
        for (int s = 0; s < 8; ++s) {
            DWORD op = 0;
            dev->GetTextureStageState(s, D3DTSS_COLOROP, &op);
            if (op == D3DTOP_DISABLE) break;
            stages.push_back(s);
        }
    }
    if (vsi) for (int s : vsi->samplers) stages.push_back(D3DVERTEXTEXTURESAMPLER0 + s);
    j += ",\"tex\":{";
    for (size_t i = 0; i < stages.size(); ++i) {
        int s = stages[i];
        IDirect3DBaseTexture9* t = nullptr;
        dev->GetTexture(s, &t);
        std::string id = TexId(dev, t);
        if (t) t->Release();
        j += Fmt("%s\"%d\":{\"id\":%s", i ? "," : "", s, JStr(id).c_str());
        for (size_t k = 0; k < sizeof kSamplerStates / sizeof kSamplerStates[0]; ++k) {
            DWORD v = 0;
            dev->GetSamplerState(s, (D3DSAMPLERSTATETYPE)kSamplerStates[k].id, &v);
            if (kSamplerStates[k].id == D3DSAMP_MIPMAPLODBIAS) { float f; memcpy(&f, &v, 4); j += Fmt(",\"%s\":%s", kSamplerStates[k].name, FloatStr(f).c_str()); }
            else j += Fmt(",\"%s\":%lu", kSamplerStates[k].name, v);
        }
        if (!psi && s < 8) {
            for (size_t k = 0; k < sizeof kStageStates / sizeof kStageStates[0]; ++k) {
                DWORD v = 0;
                dev->GetTextureStageState(s, (D3DTEXTURESTAGESTATETYPE)kStageStates[k].id, &v);
                j += Fmt(",\"%s\":%lu", kStageStates[k].name, v);
            }
        }
        j += "}";
    }
    j += "}";
    if (!vsi) {
        // fixed-function transforms
        const D3DTRANSFORMSTATETYPE xs[] = { D3DTS_WORLD, D3DTS_VIEW, D3DTS_PROJECTION };
        const char* xn[] = { "world", "view", "proj" };
        j += ",\"xf\":{";
        for (int i = 0; i < 3; ++i) {
            D3DMATRIX m;
            dev->GetTransform(xs[i], &m);
            j += Fmt("%s\"%s\":[", i ? "," : "", xn[i]);
            for (int k = 0; k < 16; ++k) j += (k ? "," : "") + FloatStr(m.m[k / 4][k % 4]);
            j += "]";
        }
        j += "}";
    }
    return j;
}

void DumpSurface(IDirect3DDevice9* dev, IDirect3DSurface9* s, const std::string& name)
{
    if (!s || !g_cfg.rt || g_cap.rtDumps >= g_cfg.rtMax) return;
    LoadD3DX();
    if (!g_dx.SaveSurface) return;
    // callers hold an Inside guard: calls through the (patched) vtable are not recorded
    D3DSURFACE_DESC d;
    s->GetDesc(&d);
    if (d.Usage & D3DUSAGE_DEPTHSTENCIL) return;
    IDirect3DSurface9* src = s;
    IDirect3DSurface9* resolved = nullptr;
    if (d.MultiSampleType != D3DMULTISAMPLE_NONE) {
        if (FAILED(dev->CreateRenderTarget(d.Width, d.Height, d.Format, D3DMULTISAMPLE_NONE, 0, FALSE, &resolved, nullptr)) || !resolved) return;
        dev->StretchRect(s, nullptr, resolved, nullptr, D3DTEXF_NONE);
        src = resolved;
    }
    IDirect3DSurface9* sys = nullptr;
    if (SUCCEEDED(dev->CreateOffscreenPlainSurface(d.Width, d.Height, d.Format, D3DPOOL_SYSTEMMEM, &sys, nullptr)) && sys) {
        if (SUCCEEDED(dev->GetRenderTargetData(src, sys))) {
            CreateDirectoryW((g_cap.dir + L"\\rt").c_str(), nullptr);
            std::wstring base = g_cap.dir + L"\\rt\\" + Widen(name);
            g_dx.SaveSurface((base + L".png").c_str(), D3DXIFF_PNG, sys, nullptr, nullptr);
            if (IsFloatFmt(d.Format)) g_dx.SaveSurface((base + L".dds").c_str(), D3DXIFF_DDS, sys, nullptr, nullptr);
            ++g_cap.rtDumps;
        }
        sys->Release();
    }
    if (resolved) resolved->Release();
}

void EndPass(IDirect3DDevice9* dev, const char* why)
{
    if (g_cap.drawsInPass == 0) return;
    IDirect3DSurface9* s = nullptr;
    if (SUCCEEDED(dev->GetRenderTarget(0, &s)) && s) {
        std::string id = RtKeyId(dev, s);
        DumpSurface(dev, s, Fmt("pass%03d_%s", g_cap.pass, id.c_str()));
        s->Release();
    }
    g_cap.drawsInPass = 0;
}

void BeginCapture(IDirect3DDevice9* dev, const std::string& label)
{
    g_cap = Capture();
    g_cap.active = true;
    g_cap.frame = g_frame;
    g_cap.label = label;
    g_cap.t0 = NowSec();
    g_cap.thread = GetCurrentThreadId();
    std::string safe;
    for (char c : label) safe += (isalnum((unsigned char)c) || c == '-' || c == '_') ? c : '_';
    g_cap.dir = g_cfg.dir + L"\\" + Widen(Fmt("f%06llu_%s", (unsigned long long)g_frame, safe.c_str()));
    CreateDirectoryW(g_cap.dir.c_str(), nullptr);
    dev->GetBackBuffer(0, 0, D3DBACKBUFFER_TYPE_MONO, &g_cap.backBuffer);
    if (g_cap.backBuffer) RtKeyId(dev, g_cap.backBuffer);
    IDirect3DSurface9* s = nullptr;
    if (SUCCEEDED(dev->GetRenderTarget(0, &s)) && s) { g_cap.curRt = RtKeyId(dev, s); s->Release(); }
    ++g_caps;
    Log(Fmt("capture %d begin frame %llu label %s", g_caps, (unsigned long long)g_frame, label.c_str()));
}

void FinishCapture(IDirect3DDevice9* dev)
{
    // resolve occlusion queries (after Present the GPU has the frame)
    std::string ev, tsv = "n\tpass\tapi\tprim\tpc\tnv\trt\tvs\tps\ttex0\ttex1\tpx\tZENABLE\tZWRITE\tABLEND\tSRC\tDST\tATEST\tAREF\tCULL\tFOG\tSRGBW\n";
    double waitEnd = NowSec() + 5.0;
    for (auto& e : g_cap.events) {
        if (e.query) {
            DWORD px = 0;
            HRESULT hr;
            while ((hr = e.query->GetData(&px, sizeof px, 0)) == S_FALSE && NowSec() < waitEnd) Sleep(0);
            if (hr == S_OK) e.json += Fmt(",\"px\":%lu", px);
            e.query->Release();
            e.query = nullptr;
        }
        e.json += "}";
        ev += e.json + "\n";
    }
    WriteFileAll(g_cap.dir + L"\\events.jsonl", ev);
    std::string tx;
    for (auto& kv : g_cap.texJson) tx += kv.second + "\n";
    WriteFileAll(g_cap.dir + L"\\textures.jsonl", tx);
    std::string sh;
    for (auto& k : g_cap.shaderKeys) sh += g_shaders[k].json + "\n";
    WriteFileAll(g_cap.dir + L"\\shaders.jsonl", sh);
    WriteFileAll(g_cap.dir + L"\\capture.json",
                 Fmt("{\"frame\":%llu,\"label\":%s,\"draws\":%d,\"passes\":%d,\"rt_dumps\":%d,\"textures\":%zu,\"shaders\":%zu,\"record_ms\":%.1f,\"frame_dt_ms\":%.3f}\n",
                     (unsigned long long)g_cap.frame, JStr(g_cap.label).c_str(), g_cap.draws, g_cap.pass, g_cap.rtDumps,
                     g_cap.texJson.size(), g_cap.shaderKeys.size(), (NowSec() - g_cap.t0) * 1000.0, 0.0));
    if (g_cap.backBuffer) g_cap.backBuffer->Release();
    Log(Fmt("capture end frame %llu: %d draws, %d passes, %zu textures, %zu shaders", (unsigned long long)g_cap.frame, g_cap.draws,
            g_cap.pass, g_cap.texJson.size(), g_cap.shaderKeys.size()));
    g_cap = Capture();
}

bool Capturing() { return g_cap.active && t_inside == 0 && GetCurrentThreadId() == g_cap.thread; }

void AddEvent(const std::string& json) { Event e; e.json = json; g_cap.events.push_back(std::move(e)); }

void FlushFrameTimes()
{
    if (g_frameTimes.empty() || g_cfg.dir.empty()) return;
    WriteFileAll(g_cfg.dir + L"\\frametimes.tsv", g_frameTimes, true);
    g_frameTimes.clear();
}

// ------------------------------------------------------------------------------------------------------------- hooks
double g_presentEnter = 0;   // L5 perf: Present entry (cpu_ms = previous Present return -> this entry)

void OnPresentBefore(IDirect3DDevice9* dev)
{
    g_presentEnter = NowSec();
    if (!Capturing()) return;
    Inside in;
    EndPass(dev, "present");
    if (g_cap.backBuffer) DumpSurface(dev, g_cap.backBuffer, "present_bb");
    AddEvent(Fmt("{\"ev\":\"present\",\"t\":%.3f", (NowSec() - g_cap.t0) * 1000.0));
}

void OnPresentAfter(IDirect3DDevice9* dev)
{
    double now = NowSec();
    if (g_firstPresent == 0) {
        g_firstPresent = now;
        g_frameTimes += "frame\tt_s\tdt_ms\tcaptured\tcpu_ms\tpresent_ms\n";
    }
    bool wasCapture = g_cap.active && GetCurrentThreadId() == g_cap.thread;
    if (wasCapture) { Inside in; FinishCapture(dev); }
    const double enter = g_presentEnter > 0 ? g_presentEnter : now;
    g_frameTimes += Fmt("%llu\t%.4f\t%.3f\t%d\t%.3f\t%.3f\n", (unsigned long long)g_frame, now - g_firstPresent,
                        g_lastPresent > 0 ? (now - g_lastPresent) * 1000.0 : 0.0, wasCapture ? 1 : 0,
                        g_lastPresent > 0 ? (enter - g_lastPresent) * 1000.0 : 0.0, (now - enter) * 1000.0);
    g_lastPresent = now;
    if ((g_frame % 300) == 0) FlushFrameTimes();
    ++g_frame;
    if (g_caps >= g_cfg.maxCaps) return;
    std::string label;
    if (std::find(g_cfg.frames.begin(), g_cfg.frames.end(), g_frame) != g_cfg.frames.end()) label = "frame";
    if (label.empty() && g_atIndex < g_cfg.at.size() && now - g_firstPresent >= g_cfg.at[g_atIndex]) {
        label = Fmt("at%gs", g_cfg.at[g_atIndex]);
        ++g_atIndex;
    }
    if (label.empty() && g_cfg.key) {
        bool down = (GetAsyncKeyState(g_cfg.key) & 0x8000) != 0;
        if (down && !g_keyDown) label = "key";
        g_keyDown = down;
    }
    if (label.empty() && (g_frame % 10) == 0) {
        std::wstring trig = g_cfg.dir + L"\\capture.now";
        if (FileExists(trig)) {
            label = "file";
            FILE* f = _wfopen(trig.c_str(), L"rb");
            if (f) {
                char b[128] = { 0 };
                if (fgets(b, sizeof b, f)) {
                    std::string l(b);
                    while (!l.empty() && (l.back() == '\n' || l.back() == '\r' || l.back() == ' ')) l.pop_back();
                    if (!l.empty()) label = l;
                }
                fclose(f);
            }
            DeleteFileW(trig.c_str());
        }
    }
    if (!label.empty()) { Inside in; BeginCapture(dev, label); }
}

thread_local int t_inPresent = 0;

HRESULT STDMETHODCALLTYPE HkPresent(IDirect3DDevice9* self, const RECT* a, const RECT* b, HWND c, const RGNDATA* d)
{
    auto orig = ORIG(self, kPresent, HRESULT(STDMETHODCALLTYPE*)(IDirect3DDevice9*, const RECT*, const RECT*, HWND, const RGNDATA*));
    OnPresentBefore(self);
    ++t_inPresent;
    HRESULT hr = orig(self, a, b, c, d);
    --t_inPresent;
    OnPresentAfter(self);
    return hr;
}

HRESULT STDMETHODCALLTYPE HkSwapPresent(IDirect3DSwapChain9* self, const RECT* a, const RECT* b, HWND c, const RGNDATA* d, DWORD flags)
{
    auto orig = ORIG(self, kSwapChainPresent, HRESULT(STDMETHODCALLTYPE*)(IDirect3DSwapChain9*, const RECT*, const RECT*, HWND, const RGNDATA*, DWORD));
    if (t_inPresent) return orig(self, a, b, c, d, flags);
    IDirect3DDevice9* dev = nullptr;
    self->GetDevice(&dev);
    if (dev) OnPresentBefore(dev);
    ++t_inPresent;
    HRESULT hr = orig(self, a, b, c, d, flags);
    --t_inPresent;
    if (dev) { OnPresentAfter(dev); dev->Release(); }
    return hr;
}

void HookSwapChains(IDirect3DDevice9* dev);

HRESULT STDMETHODCALLTYPE HkReset(IDirect3DDevice9* self, D3DPRESENT_PARAMETERS* pp)
{
    auto orig = ORIG(self, kReset, HRESULT(STDMETHODCALLTYPE*)(IDirect3DDevice9*, D3DPRESENT_PARAMETERS*));
    if (g_cap.active) { Inside in; FinishCapture(self); }
    HRESULT hr = orig(self, pp);
    Log(Fmt("Reset hr=0x%08lx %ux%u fmt %s msaa %d", hr, pp ? pp->BackBufferWidth : 0, pp ? pp->BackBufferHeight : 0,
            pp ? FmtName(pp->BackBufferFormat).c_str() : "", pp ? int(pp->MultiSampleType) : 0));
    return hr;
}

HRESULT STDMETHODCALLTYPE HkSetRenderTarget(IDirect3DDevice9* self, DWORD idx, IDirect3DSurface9* s)
{
    auto orig = ORIG(self, kSetRenderTarget, HRESULT(STDMETHODCALLTYPE*)(IDirect3DDevice9*, DWORD, IDirect3DSurface9*));
    if (Capturing()) {
        Inside in;
        std::string id = RtKeyId(self, s);
        if (idx == 0 && id != g_cap.curRt) {
            EndPass(self, "setrt");
            ++g_cap.pass;
            g_cap.curRt = id;
        }
        AddEvent(Fmt("{\"ev\":\"setrt\",\"pass\":%d,\"idx\":%lu,\"rt\":%s,\"t\":%.3f", g_cap.pass, idx, JStr(id).c_str(), (NowSec() - g_cap.t0) * 1000.0));
    }
    return orig(self, idx, s);
}

HRESULT STDMETHODCALLTYPE HkSetDepthStencil(IDirect3DDevice9* self, IDirect3DSurface9* s)
{
    auto orig = ORIG(self, kSetDepthStencilSurface, HRESULT(STDMETHODCALLTYPE*)(IDirect3DDevice9*, IDirect3DSurface9*));
    if (Capturing()) {
        Inside in;
        std::string d = "null";
        if (s) { D3DSURFACE_DESC sd; s->GetDesc(&sd); d = JStr(Fmt("%ux%u:%s", sd.Width, sd.Height, FmtName(sd.Format).c_str())); }
        AddEvent(Fmt("{\"ev\":\"setds\",\"pass\":%d,\"ds\":%s", g_cap.pass, d.c_str()));
    }
    return orig(self, s);
}

HRESULT STDMETHODCALLTYPE HkClear(IDirect3DDevice9* self, DWORD count, const D3DRECT* rects, DWORD flags, D3DCOLOR color, float z, DWORD stencil)
{
    auto orig = ORIG(self, kClear, HRESULT(STDMETHODCALLTYPE*)(IDirect3DDevice9*, DWORD, const D3DRECT*, DWORD, D3DCOLOR, float, DWORD));
    if (Capturing()) {
        Inside in;
        IDirect3DSurface9* s = nullptr;
        std::string id = "null";
        if (SUCCEEDED(self->GetRenderTarget(0, &s)) && s) { id = RtKeyId(self, s); s->Release(); }
        D3DVIEWPORT9 vp;
        self->GetViewport(&vp);
        AddEvent(Fmt("{\"ev\":\"clear\",\"pass\":%d,\"rt\":%s,\"flags\":%lu,\"color\":\"%08lx\",\"z\":%s,\"stencil\":%lu,\"rects\":%lu,\"vp\":[%lu,%lu,%lu,%lu],\"t\":%.3f",
                     g_cap.pass, JStr(id).c_str(), flags, color, FloatStr(z).c_str(), stencil, count, vp.X, vp.Y, vp.Width, vp.Height,
                     (NowSec() - g_cap.t0) * 1000.0));
    }
    return orig(self, count, rects, flags, color, z, stencil);
}

HRESULT STDMETHODCALLTYPE HkStretchRect(IDirect3DDevice9* self, IDirect3DSurface9* src, const RECT* sr, IDirect3DSurface9* dst, const RECT* dr, D3DTEXTUREFILTERTYPE f)
{
    auto orig = ORIG(self, kStretchRect, HRESULT(STDMETHODCALLTYPE*)(IDirect3DDevice9*, IDirect3DSurface9*, const RECT*, IDirect3DSurface9*, const RECT*, D3DTEXTUREFILTERTYPE));
    if (Capturing()) {
        Inside in;
        auto rs = [](const RECT* r) { return r ? Fmt("[%ld,%ld,%ld,%ld]", r->left, r->top, r->right, r->bottom) : std::string("null"); };
        AddEvent(Fmt("{\"ev\":\"stretchrect\",\"pass\":%d,\"src\":%s,\"dst\":%s,\"srect\":%s,\"drect\":%s,\"filter\":%d", g_cap.pass,
                     JStr(RtKeyId(self, src)).c_str(), JStr(RtKeyId(self, dst)).c_str(), rs(sr).c_str(), rs(dr).c_str(), int(f)));
    }
    return orig(self, src, sr, dst, dr, f);
}

HRESULT STDMETHODCALLTYPE HkColorFill(IDirect3DDevice9* self, IDirect3DSurface9* s, const RECT* r, D3DCOLOR c)
{
    auto orig = ORIG(self, kColorFill, HRESULT(STDMETHODCALLTYPE*)(IDirect3DDevice9*, IDirect3DSurface9*, const RECT*, D3DCOLOR));
    if (Capturing()) { Inside in; AddEvent(Fmt("{\"ev\":\"colorfill\",\"pass\":%d,\"dst\":%s,\"color\":\"%08lx\"", g_cap.pass, JStr(RtKeyId(self, s)).c_str(), c)); }
    return orig(self, s, r, c);
}

HRESULT STDMETHODCALLTYPE HkGetRenderTargetData(IDirect3DDevice9* self, IDirect3DSurface9* rt, IDirect3DSurface9* dst)
{
    auto orig = ORIG(self, kGetRenderTargetData, HRESULT(STDMETHODCALLTYPE*)(IDirect3DDevice9*, IDirect3DSurface9*, IDirect3DSurface9*));
    if (Capturing()) { Inside in; AddEvent(Fmt("{\"ev\":\"readback\",\"pass\":%d,\"src\":%s", g_cap.pass, JStr(RtKeyId(self, rt)).c_str())); }
    return orig(self, rt, dst);
}

HRESULT STDMETHODCALLTYPE HkUpdateTexture(IDirect3DDevice9* self, IDirect3DBaseTexture9* src, IDirect3DBaseTexture9* dst)
{
    auto orig = ORIG(self, kUpdateTexture, HRESULT(STDMETHODCALLTYPE*)(IDirect3DDevice9*, IDirect3DBaseTexture9*, IDirect3DBaseTexture9*));
    if (Capturing()) { Inside in; AddEvent(Fmt("{\"ev\":\"updatetexture\",\"pass\":%d", g_cap.pass)); }
    return orig(self, src, dst);
}

template <class F>
HRESULT Draw(IDirect3DDevice9* self, F call, const char* api, D3DPRIMITIVETYPE pt, int base, UINT minV, UINT numV, UINT start, UINT pc,
             const void* upIdx = nullptr, D3DFORMAT upFmt = D3DFMT_UNKNOWN, const void* upVtx = nullptr, UINT upStride = 0)
{
    if (!Capturing()) return call();
    IDirect3DQuery9* q = nullptr;
    {
        Inside in;
        Event e;
        e.json = DescribeDraw(self, api, pt, base, minV, numV, start, pc, upIdx, upFmt, upVtx, upStride);
        e.draw = true;
        if (g_cfg.occ && SUCCEEDED(self->CreateQuery(D3DQUERYTYPE_OCCLUSION, &q)) && q) e.query = q;
        g_cap.events.push_back(std::move(e));
        ++g_cap.draws;
        ++g_cap.drawsInPass;
    }
    if (q) q->Issue(D3DISSUE_BEGIN);
    HRESULT hr = call();
    if (q) q->Issue(D3DISSUE_END);
    return hr;
}

HRESULT STDMETHODCALLTYPE HkDrawPrimitive(IDirect3DDevice9* self, D3DPRIMITIVETYPE pt, UINT start, UINT pc)
{
    auto orig = ORIG(self, kDrawPrimitive, HRESULT(STDMETHODCALLTYPE*)(IDirect3DDevice9*, D3DPRIMITIVETYPE, UINT, UINT));
    return Draw(self, [&] { return orig(self, pt, start, pc); }, "DP", pt, 0, 0, 0, start, pc);
}

HRESULT STDMETHODCALLTYPE HkDrawIndexedPrimitive(IDirect3DDevice9* self, D3DPRIMITIVETYPE pt, INT base, UINT minV, UINT numV, UINT start, UINT pc)
{
    auto orig = ORIG(self, kDrawIndexedPrimitive, HRESULT(STDMETHODCALLTYPE*)(IDirect3DDevice9*, D3DPRIMITIVETYPE, INT, UINT, UINT, UINT, UINT));
    return Draw(self, [&] { return orig(self, pt, base, minV, numV, start, pc); }, "DIP", pt, base, minV, numV, start, pc);
}

HRESULT STDMETHODCALLTYPE HkDrawPrimitiveUP(IDirect3DDevice9* self, D3DPRIMITIVETYPE pt, UINT pc, const void* data, UINT stride)
{
    auto orig = ORIG(self, kDrawPrimitiveUP, HRESULT(STDMETHODCALLTYPE*)(IDirect3DDevice9*, D3DPRIMITIVETYPE, UINT, const void*, UINT));
    return Draw(self, [&] { return orig(self, pt, pc, data, stride); }, "DPUP", pt, 0, 0, 0, 0, pc, nullptr, D3DFMT_UNKNOWN, data, stride);
}

HRESULT STDMETHODCALLTYPE HkDrawIndexedPrimitiveUP(IDirect3DDevice9* self, D3DPRIMITIVETYPE pt, UINT minV, UINT numV, UINT pc, const void* idx,
                                                   D3DFORMAT ifmt, const void* data, UINT stride)
{
    auto orig = ORIG(self, kDrawIndexedPrimitiveUP, HRESULT(STDMETHODCALLTYPE*)(IDirect3DDevice9*, D3DPRIMITIVETYPE, UINT, UINT, UINT, const void*, D3DFORMAT, const void*, UINT));
    return Draw(self, [&] { return orig(self, pt, minV, numV, pc, idx, ifmt, data, stride); }, "DIPUP", pt, 0, minV, numV, 0, pc, idx, ifmt,
                data, stride);
}

HRESULT STDMETHODCALLTYPE HkGetSwapChain(IDirect3DDevice9* self, UINT i, IDirect3DSwapChain9** out)
{
    auto orig = ORIG(self, kGetSwapChain, HRESULT(STDMETHODCALLTYPE*)(IDirect3DDevice9*, UINT, IDirect3DSwapChain9**));
    HRESULT hr = orig(self, i, out);
    if (SUCCEEDED(hr) && out && *out) Patch(*out, kSwapChainPresent, (void*)&HkSwapPresent);
    return hr;
}

void HookDevice(IDirect3DDevice9* dev)
{
    Patch(dev, kReset, (void*)&HkReset);
    Patch(dev, kPresent, (void*)&HkPresent);
    Patch(dev, kGetSwapChain, (void*)&HkGetSwapChain);
    Patch(dev, kSetRenderTarget, (void*)&HkSetRenderTarget);
    Patch(dev, kSetDepthStencilSurface, (void*)&HkSetDepthStencil);
    Patch(dev, kClear, (void*)&HkClear);
    Patch(dev, kStretchRect, (void*)&HkStretchRect);
    Patch(dev, kColorFill, (void*)&HkColorFill);
    Patch(dev, kGetRenderTargetData, (void*)&HkGetRenderTargetData);
    Patch(dev, kUpdateTexture, (void*)&HkUpdateTexture);
    Patch(dev, kDrawPrimitive, (void*)&HkDrawPrimitive);
    Patch(dev, kDrawIndexedPrimitive, (void*)&HkDrawIndexedPrimitive);
    Patch(dev, kDrawPrimitiveUP, (void*)&HkDrawPrimitiveUP);
    Patch(dev, kDrawIndexedPrimitiveUP, (void*)&HkDrawIndexedPrimitiveUP);
    IDirect3DSwapChain9* sc = nullptr;
    if (SUCCEEDED(dev->GetSwapChain(0, &sc)) && sc) sc->Release(); // patched by HkGetSwapChain
}

void LogCreate(const char* what, HRESULT hr, DWORD flags, D3DPRESENT_PARAMETERS* pp, HWND focus)
{
    Log(Fmt("%s hr=0x%08lx behavior=0x%lx backbuffer %ux%u fmt %s count %u msaa %d/%lu swap %d windowed %d autodepth %d %s interval 0x%x flags 0x%lx focus %p",
            what, hr, flags, pp ? pp->BackBufferWidth : 0, pp ? pp->BackBufferHeight : 0, pp ? FmtName(pp->BackBufferFormat).c_str() : "",
            pp ? pp->BackBufferCount : 0, pp ? int(pp->MultiSampleType) : 0, pp ? pp->MultiSampleQuality : 0, pp ? int(pp->SwapEffect) : 0,
            pp ? pp->Windowed : 0, pp ? pp->EnableAutoDepthStencil : 0, pp ? FmtName(pp->AutoDepthStencilFormat).c_str() : "",
            pp ? pp->PresentationInterval : 0, pp ? pp->Flags : 0, (void*)focus));
}

HRESULT STDMETHODCALLTYPE HkCreateDevice(IDirect3D9* self, UINT adapter, D3DDEVTYPE type, HWND focus, DWORD flags, D3DPRESENT_PARAMETERS* pp,
                                         IDirect3DDevice9** out)
{
    auto orig = ORIG(self, kD3DCreateDevice, HRESULT(STDMETHODCALLTYPE*)(IDirect3D9*, UINT, D3DDEVTYPE, HWND, DWORD, D3DPRESENT_PARAMETERS*, IDirect3DDevice9**));
    DWORD f = flags & ~DWORD(D3DCREATE_PUREDEVICE); // Get* state queries need a non-pure device
    HRESULT hr = orig(self, adapter, type, focus, f, pp, out);
    LogCreate("CreateDevice", hr, flags, pp, focus);
    if (SUCCEEDED(hr) && out && *out) HookDevice(*out);
    return hr;
}

HRESULT STDMETHODCALLTYPE HkCreateDeviceEx(IDirect3D9Ex* self, UINT adapter, D3DDEVTYPE type, HWND focus, DWORD flags, D3DPRESENT_PARAMETERS* pp,
                                           D3DDISPLAYMODEEX* mode, IDirect3DDevice9Ex** out)
{
    auto orig = ORIG(self, kD3DCreateDeviceEx, HRESULT(STDMETHODCALLTYPE*)(IDirect3D9Ex*, UINT, D3DDEVTYPE, HWND, DWORD, D3DPRESENT_PARAMETERS*, D3DDISPLAYMODEEX*, IDirect3DDevice9Ex**));
    DWORD f = flags & ~DWORD(D3DCREATE_PUREDEVICE);
    HRESULT hr = orig(self, adapter, type, focus, f, pp, mode, out);
    LogCreate("CreateDeviceEx", hr, flags, pp, focus);
    if (SUCCEEDED(hr) && out && *out) HookDevice(*out);
    return hr;
}

// First-chance access violations / fatal exceptions are logged with module + RVA (max 20) to diagnose crashes of the
// traced application; the exception is never handled here.
LONG g_excLogged = 0;
LONG CALLBACK ExceptionLogger(EXCEPTION_POINTERS* ep)
{
    DWORD code = ep->ExceptionRecord->ExceptionCode;
    if (code != EXCEPTION_ACCESS_VIOLATION && code != EXCEPTION_ILLEGAL_INSTRUCTION && code != EXCEPTION_STACK_OVERFLOW &&
        code != 0xC0000409 && code != EXCEPTION_INT_DIVIDE_BY_ZERO)
        return EXCEPTION_CONTINUE_SEARCH;
    if (InterlockedIncrement(&g_excLogged) > 20) return EXCEPTION_CONTINUE_SEARCH;
    void* addr = ep->ExceptionRecord->ExceptionAddress;
    HMODULE mod = nullptr;
    char name[MAX_PATH] = "?";
    if (GetModuleHandleExA(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS | GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT, (LPCSTR)addr, &mod) && mod)
        GetModuleFileNameA(mod, name, MAX_PATH);
    const char* base = strrchr(name, 0x5C);
    Log(Fmt("exception 0x%08lx at %p (%s+0x%llx) info %llx %llx thread %lu frame %llu capturing %d", code, addr, base ? base + 1 : name,
            (unsigned long long)((char*)addr - (char*)mod), ep->ExceptionRecord->NumberParameters > 0 ? (unsigned long long)ep->ExceptionRecord->ExceptionInformation[0] : 0ULL,
            ep->ExceptionRecord->NumberParameters > 1 ? (unsigned long long)ep->ExceptionRecord->ExceptionInformation[1] : 0ULL,
            GetCurrentThreadId(), (unsigned long long)g_frame, g_cap.active ? 1 : 0));
    return EXCEPTION_CONTINUE_SEARCH;
}

bool g_configured = false;
void EnsureConfig()
{
    if (!g_configured) {
        g_configured = true;
        LoadConfig();
        AddVectoredExceptionHandler(0, ExceptionLogger);
    }
}

} // namespace

extern "C" {

IDirect3D9* WINAPI Direct3DCreate9(UINT sdk)
{
    EnsureConfig();
    auto f = (IDirect3D9 * (WINAPI*)(UINT))RealProc("Direct3DCreate9");
    IDirect3D9* d = f ? f(sdk) : nullptr;
    Log(Fmt("Direct3DCreate9(%u) -> %p", sdk, (void*)d));
    if (d) Patch(d, kD3DCreateDevice, (void*)&HkCreateDevice);
    return d;
}

HRESULT WINAPI Direct3DCreate9Ex(UINT sdk, IDirect3D9Ex** out)
{
    EnsureConfig();
    auto f = (HRESULT(WINAPI*)(UINT, IDirect3D9Ex**))RealProc("Direct3DCreate9Ex");
    HRESULT hr = f ? f(sdk, out) : E_FAIL;
    Log(Fmt("Direct3DCreate9Ex(%u) hr=0x%08lx", sdk, hr));
    if (SUCCEEDED(hr) && out && *out) {
        Patch(*out, kD3DCreateDevice, (void*)&HkCreateDevice);
        Patch(*out, kD3DCreateDeviceEx, (void*)&HkCreateDeviceEx);
    }
    return hr;
}

int WINAPI D3DPERF_BeginEvent(D3DCOLOR col, LPCWSTR name)
{
    if (g_cap.active && GetCurrentThreadId() == g_cap.thread && t_inside == 0)
        AddEvent(Fmt("{\"ev\":\"marker\",\"kind\":\"begin\",\"pass\":%d,\"name\":%s", g_cap.pass, JStr(Narrow(name ? name : L"")).c_str()));
    auto f = (int(WINAPI*)(D3DCOLOR, LPCWSTR))RealProc("D3DPERF_BeginEvent");
    return f ? f(col, name) : 0;
}

int WINAPI D3DPERF_EndEvent()
{
    if (g_cap.active && GetCurrentThreadId() == g_cap.thread && t_inside == 0)
        AddEvent(Fmt("{\"ev\":\"marker\",\"kind\":\"end\",\"pass\":%d", g_cap.pass));
    auto f = (int(WINAPI*)())RealProc("D3DPERF_EndEvent");
    return f ? f() : 0;
}

void WINAPI D3DPERF_SetMarker(D3DCOLOR col, LPCWSTR name)
{
    auto f = (void(WINAPI*)(D3DCOLOR, LPCWSTR))RealProc("D3DPERF_SetMarker");
    if (f) f(col, name);
}

void WINAPI D3DPERF_SetRegion(D3DCOLOR col, LPCWSTR name)
{
    auto f = (void(WINAPI*)(D3DCOLOR, LPCWSTR))RealProc("D3DPERF_SetRegion");
    if (f) f(col, name);
}

BOOL WINAPI D3DPERF_QueryRepeatFrame()
{
    auto f = (BOOL(WINAPI*)())RealProc("D3DPERF_QueryRepeatFrame");
    return f ? f() : FALSE;
}

void WINAPI D3DPERF_SetOptions(DWORD o)
{
    auto f = (void(WINAPI*)(DWORD))RealProc("D3DPERF_SetOptions");
    if (f) f(o);
}

DWORD WINAPI D3DPERF_GetStatus()
{
    auto f = (DWORD(WINAPI*)())RealProc("D3DPERF_GetStatus");
    return f ? f() : 0;
}

void WINAPI DebugSetMute()
{
    auto f = (void(WINAPI*)())RealProc("DebugSetMute");
    if (f) f();
}

int WINAPI DebugSetLevel(int level)
{
    auto f = (int(WINAPI*)(int))RealProc("DebugSetLevel");
    return f ? f(level) : 0;
}

} // extern "C"

BOOL WINAPI DllMain(HINSTANCE inst, DWORD reason, LPVOID reserved)
{
    if (reason == DLL_PROCESS_ATTACH) {
        g_self = inst;
        InitializeCriticalSection(&g_patchCs);
        DisableThreadLibraryCalls(inst);
    } else if (reason == DLL_PROCESS_DETACH) {
        FlushFrameTimes();
    }
    return TRUE;
}
