// Load and navigation smoke tests for the PathLib.dll built from this repository.
#define WIN32_LEAN_AND_MEAN
#include <windows.h>

#include <cstdint>
#include <cstdio>
#include <cstring>
#include <string>
#include <vector>

// ---- call an object method by vtable slot -------------------------------------------
template <int SLOT, typename Ret, typename... Args>
Ret vcall(void* obj, Args... args) {
    void** vt = *reinterpret_cast<void***>(obj);
    using Fn = Ret(__fastcall*)(void*, Args...);
    return reinterpret_cast<Fn>(vt[SLOT])(obj, args...);
}

// PathData slots (variant A): 3 parseBuffer, 8 worldToGrid, 9 isValidGrid,
//   14 triangle, 15 vertex, 16 vertexCount, 17 triangleCount.
namespace slot {
constexpr int PD_parse = 3;
constexpr int PD_tri = 14;
constexpr int PD_vert = 15;
constexpr int PD_vcount = 16;
constexpr int PD_tcount = 17;
constexpr int PF_init = 1;
constexpr int PF_findPath = 3;
constexpr int PF_pointCount = 7;
constexpr int PF_point = 8;
}  // namespace slot

// A DLL's factory entry points.
struct Dll {
    HMODULE h = nullptr;
    void*(__fastcall* getPathData)(void*) = nullptr;
    void*(__fastcall* getPathFinder)(void*) = nullptr;
    void(__fastcall* destroyPathData)(void*, void*) = nullptr;
    void(__fastcall* destroyPathFinder)(void*, void*) = nullptr;
    bool ok() const { return h && getPathData && getPathFinder; }
};

static Dll loadDll(const char* path) {
    Dll d;
    // Resolve dependencies from the directory of the tested build.
    std::string dir(path);
    size_t slash = dir.find_last_of("\\/");
    if (slash != std::string::npos) {
        dir.resize(slash);
        SetDllDirectoryA(dir.c_str());
    }
    d.h = LoadLibraryA(path);
    SetDllDirectoryA(nullptr);
    if (!d.h) return d;
    d.getPathData = reinterpret_cast<decltype(d.getPathData)>(
        GetProcAddress(d.h, "?getPathData@PathLibRoot@PathLib@@QEAAPEAVPathData@2@XZ"));
    d.getPathFinder = reinterpret_cast<decltype(d.getPathFinder)>(
        GetProcAddress(d.h, "?getPathFinder@PathLibRoot@PathLib@@QEAAPEAVPathFinder@2@XZ"));
    d.destroyPathData = reinterpret_cast<decltype(d.destroyPathData)>(
        GetProcAddress(d.h, "?destroyPathData@PathLibRoot@PathLib@@QEAAXPEAVPathData@2@@Z"));
    d.destroyPathFinder = reinterpret_cast<decltype(d.destroyPathFinder)>(
        GetProcAddress(d.h, "?destroyPathFinderInfo@PathLibRoot@PathLib@@QEAAXPEAVPathFinder@2@@Z"));
    if (!d.destroyPathFinder)
        d.destroyPathFinder = reinterpret_cast<decltype(d.destroyPathFinder)>(
            GetProcAddress(d.h, "?destroyPathFinder@PathLibRoot@PathLib@@QEAAXPEAVPathFinder@2@@Z"));
    return d;
}

// A triangle extracted through the accessor slot, at the layout of the given DLL variant.
struct ExTri {
    std::uint32_t v[3];
    std::uint32_t n[3];
    std::uint8_t flag;
    std::uint32_t extra;
};

// Field offsets inside the opaque Tri* returned by slot 14.
struct TriLayout {
    int v0, n0, flag, extra;
};
// Our DLL: struct Tri{ u32 v[3]; u32 n[3]; u8 flag; u32 extra; ... } -> v 0, n 12, flag 24, extra 28.
static const TriLayout kOurs{0, 12, 24, 28};

static ExTri readTri(const void* t, const TriLayout& L) {
    const std::uint8_t* p = static_cast<const std::uint8_t*>(t);
    ExTri e;
    std::memcpy(&e.v[0], p + L.v0 + 0, 4);
    std::memcpy(&e.v[1], p + L.v0 + 4, 4);
    std::memcpy(&e.v[2], p + L.v0 + 8, 4);
    std::memcpy(&e.n[0], p + L.n0 + 0, 4);
    std::memcpy(&e.n[1], p + L.n0 + 4, 4);
    std::memcpy(&e.n[2], p + L.n0 + 8, 4);
    e.flag = p[L.flag];
    std::memcpy(&e.extra, p + L.extra, 4);
    return e;
}

struct Mesh {
    std::vector<float> vx, vz;
    std::vector<ExTri> tris;
    long long vcount = 0, tcount = 0;
};

static bool readFile(const char* path, std::vector<std::uint8_t>& out) {
    FILE* f = fopen(path, "rb");
    if (!f) return false;
    fseek(f, 0, SEEK_END);
    long n = ftell(f);
    fseek(f, 0, SEEK_SET);
    bool ok = false;
    if (n > 0) {
        out.resize((size_t)n);
        ok = fread(out.data(), 1, (size_t)n, f) == (size_t)n;
    }
    fclose(f);
    return ok;
}

// Parse `bytes` in `d` and extract the mesh through the accessor slots. Returns false if the
// DLL faulted (caught by SEH).
static bool extractMesh(const Dll& d, const std::vector<std::uint8_t>& bytes, const TriLayout& L,
                        Mesh& m, const char** err) {
    __try {
        void* pd = d.getPathData(nullptr);
        if (!pd) { *err = "getPathData returned null"; return false; }
        vcall<slot::PD_parse, void>(pd, (void*)bytes.data());
        m.vcount = vcall<slot::PD_vcount, long long>(pd);
        m.tcount = vcall<slot::PD_tcount, long long>(pd);
        if (m.vcount < 0 || m.vcount > 50000000 || m.tcount < 0 || m.tcount > 50000000) {
            *err = "insane counts";
            d.destroyPathData(nullptr, pd);
            return false;
        }
        m.vx.resize((size_t)m.vcount);
        m.vz.resize((size_t)m.vcount);
        for (long long i = 0; i < m.vcount; ++i) {
            const float* v = vcall<slot::PD_vert, const float*>(pd, (intptr_t)i);
            m.vx[(size_t)i] = v ? v[0] : 0;
            m.vz[(size_t)i] = v ? v[1] : 0;
        }
        m.tris.resize((size_t)m.tcount);
        for (long long i = 0; i < m.tcount; ++i) {
            const void* t = vcall<slot::PD_tri, const void*>(pd, (intptr_t)i);
            m.tris[(size_t)i] = t ? readTri(t, L) : ExTri{};
        }
        d.destroyPathData(nullptr, pd);
        return true;
    } __except (EXCEPTION_EXECUTE_HANDLER) {
        *err = "SEH fault during parse/extract";
        return false;
    }
}

// SEH-guarded findPath call. Kept in its own function (no C++ unwinding objects) so __try
// is legal here; a fault is reported via `crashed` instead of taking down the harness.
static bool sehFindPath(void* pf, const float* s, const float* g, float* out, bool* crashed) {
    __try {
        *crashed = false;
        return vcall<slot::PF_findPath, bool>(pf, s, g, out);
    } __except (EXCEPTION_EXECUTE_HANDLER) {
        *crashed = true;
        return false;
    }
}

// -------- load mode --------
static int runLoad(const char* dllPath, const std::vector<std::string>& folders) {
    Dll d = loadDll(dllPath);
    if (!d.ok()) { printf("FAIL: cannot load %s or its exports\n", dllPath); return 2; }
    int total = 0, okc = 0, parseFail = 0, crash = 0;
    for (size_t fi = 0; fi < folders.size(); ++fi) {
    const char* folder = folders[fi].c_str();
    WIN32_FIND_DATAA fd;
    std::string pat = std::string(folder) + "\\*.path";
    HANDLE hf = FindFirstFileA(pat.c_str(), &fd);
    if (hf == INVALID_HANDLE_VALUE) { printf("no .path files in %s\n", folder); continue; }
    int folderTotal = 0;
    do {
        std::string full = std::string(folder) + "\\" + fd.cFileName;
        std::vector<std::uint8_t> bytes;
        if (!readFile(full.c_str(), bytes)) continue;
        ++total;
        ++folderTotal;
        Mesh m;
        const char* err = "";
        if (extractMesh(d, bytes, kOurs, m, &err)) {
            ++okc;
        } else {
            if (strstr(err, "SEH")) { ++crash; printf("  CRASH %s : %s\n", fd.cFileName, err); }
            else { ++parseFail; printf("  parse-fail %s : %s (%zu bytes)\n", fd.cFileName, err, bytes.size()); }
        }
    } while (FindNextFileA(hf, &fd));
    FindClose(hf);
    printf("  folder %s: %d .path files\n", folder, folderTotal);
    }
    printf("\nLOAD TEST: %d files, %d parsed ok, %d parse-fail, %d CRASH\n", total, okc, parseFail, crash);
    return crash == 0 ? 0 : 1;
}

// -------- probe mode: does OUR findTri (via findPath to centroids) locate triangles? -----
static int runProbe(const char* ourPath, const char* pathFile) {
    Dll our = loadDll(ourPath);
    if (!our.ok()) { printf("cannot load %s\n", ourPath); return 2; }
    std::vector<std::uint8_t> bytes;
    if (!readFile(pathFile, bytes)) { printf("cannot read %s\n", pathFile); return 2; }
    Mesh m; const char* err = "";
    if (!extractMesh(our, bytes, kOurs, m, &err)) { printf("extract failed: %s\n", err); return 2; }
    void* pd = our.getPathData(nullptr);
    vcall<slot::PD_parse, void>(pd, (void*)bytes.data());
    void* pf = our.getPathFinder(nullptr);
    vcall<slot::PF_init, void>(pf, pd);
    int found = 0, tested = 0, adjOk = 0;
    for (long long i = 0; i < m.tcount && tested < 40; i += (m.tcount / 40 + 1)) {
        const ExTri& t = m.tris[(size_t)i];
        if (t.flag & 1) continue;
        float cx = (m.vx[t.v[0]] + m.vx[t.v[1]] + m.vx[t.v[2]]) / 3.0f;
        float cz = (m.vz[t.v[0]] + m.vz[t.v[1]] + m.vz[t.v[2]]) / 3.0f;
        float s[3] = {cx, 0, cz};
        float out[2] = {0, 0};
        bool crashed = false;
        bool r = sehFindPath(pf, s, s, out, &crashed);  // same point -> should be true if tri located
        ++tested;
        if (r) ++found;
        // adjacent triangle: does a->neighbour-centroid path succeed?
        if (t.n[0] != 1000000u && t.n[0] < (std::uint32_t)m.tcount) {
            const ExTri& nb = m.tris[t.n[0]];
            if (!(nb.flag & 1)) {
                float ncx = (m.vx[nb.v[0]] + m.vx[nb.v[1]] + m.vx[nb.v[2]]) / 3.0f;
                float ncz = (m.vz[nb.v[0]] + m.vz[nb.v[1]] + m.vz[nb.v[2]]) / 3.0f;
                float g[3] = {ncx, 0, ncz};
                if (sehFindPath(pf, s, g, out, &crashed)) ++adjOk;
            }
        }
        printf("  tri %lld centroid (%.2f,%.2f) flag=%u extra=%u  findSelf=%d\n", i, cx, cz, t.flag, t.extra, (int)r);
    }
    printf("PROBE %s: verts=%lld tris=%lld  self-located %d/%d  adj-paths %d\n",
           pathFile, m.vcount, m.tcount, found, tested, adjOk);
    our.destroyPathFinder(nullptr, pf);
    our.destroyPathData(nullptr, pd);
    return 0;
}

int main(int argc, char** argv) {
    if (argc >= 4 && strcmp(argv[1], "probe") == 0) return runProbe(argv[2], argv[3]);
    if (argc >= 4 && strcmp(argv[1], "load") == 0) {
        std::vector<std::string> folders;
        for (int i = 3; i < argc; ++i) folders.push_back(argv[i]);
        return runLoad(argv[2], folders);
    }
    printf("usage:\n  pathlib_test load <our.dll> <sceneFolder>\n"
           "  pathlib_test probe <our.dll> <pathFile>\n");
    return 2;
}
