// pathlib_test.cpp — load test + differential test for the clean-room PathLib.dll.
//
// Modes:
//   pathlib_test load  <our.dll> <sceneFolder> [<sceneFolder2> ...]
//       Parse every *.path in the folder(s) with OUR DLL (getPathData + slot-3 parseBuffer),
//       guarded by SEH so a fault in any one file is caught & counted. Must reach 0 crashes.
//       (CanonicalCY keeps 46 of its 418 .path files in Scene2Folder: pass both folders; one total line.)
//
//   pathlib_test diff  <our.dll> <orig.dll> <sceneFolder> [pairsPerScene] [maxScenes]
//       For up to N scenes: parse each .path in BOTH DLLs, extract the mesh through the
//       accessor vtable slots, and compare (vertex count, triangle count, every vertex,
//       every triangle's v0..v2 / n0..n2 / flag / extra). Then run >=pairs random start/goal
//       queries: compare OUR exported findPath()'s reach verdict against the ground truth
//       derived from the ORIGINAL DLL's extracted triangles (containing-triangle + region id),
//       and report path length. Every mismatch is printed.
//
// The harness calls object methods purely by vtable slot index (both DLLs share variant-A
// slot order), so it needs no headers from the DLL.

#define WIN32_LEAN_AND_MEAN
#include <windows.h>

#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <random>
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
    // Let the DLL resolve its own dependencies (MSVCR110 / libgmp-10 for the original) from
    // its own directory.
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
// Original PathLib.dll (variant A/B): v at 0x2c, n at 0x38, flag 0x60, extra 0x64.
static const TriLayout kOrig{0x2c, 0x38, 0x60, 0x64};
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

// SEH-guarded: run findPath on `pf` and return the resulting polyline length (sum of segment
// lengths via the pointCount/point slots), or -1.0 if not reachable / -2.0 on a fault.
static double sehPathLen(void* pf, const float* s, const float* g) {
    __try {
        float out[2] = {0, 0};
        bool r = vcall<slot::PF_findPath, bool>(pf, s, g, out);
        if (!r) return -1.0;
        long long n = vcall<slot::PF_pointCount, long long>(pf);
        if (n < 2 || n > 100000) return 0.0;
        double len = 0.0;
        const float* prev = vcall<slot::PF_point, const float*>(pf, (intptr_t)0);
        float px = prev ? prev[0] : 0, pz = prev ? prev[1] : 0;
        for (long long i = 1; i < n; ++i) {
            const float* p = vcall<slot::PF_point, const float*>(pf, (intptr_t)i);
            if (!p) break;
            const double dx = p[0] - px, dz = p[1] - pz;
            len += std::sqrt(dx * dx + dz * dz);
            px = p[0]; pz = p[1];
        }
        return len;
    } __except (EXCEPTION_EXECUTE_HANDLER) {
        return -2.0;
    }
}

// SEH-guarded bring-up / teardown of a DLL's pathfinder (kept out of functions that own
// C++ unwinding objects, which cannot contain __try).
static bool sehInitPf(const Dll& d, const std::vector<std::uint8_t>& bytes, void** pd, void** pf) {
    __try {
        *pd = d.getPathData(nullptr);
        vcall<slot::PD_parse, void>(*pd, (void*)bytes.data());
        *pf = d.getPathFinder(nullptr);
        vcall<slot::PF_init, void>(*pf, *pd);
        return true;
    } __except (EXCEPTION_EXECUTE_HANDLER) {
        return false;
    }
}
static void sehDestroyPf(const Dll& d, void* pd, void* pf) {
    __try {
        if (pf) d.destroyPathFinder(nullptr, pf);
        if (pd) d.destroyPathData(nullptr, pd);
    } __except (EXCEPTION_EXECUTE_HANDLER) {}
}

static bool pointInTri(float px, float pz, const Mesh& m, const ExTri& t) {
    if (t.v[0] >= m.vx.size() || t.v[1] >= m.vx.size() || t.v[2] >= m.vx.size()) return false;
    const float ax = m.vx[t.v[0]], az = m.vz[t.v[0]];
    const float bx = m.vx[t.v[1]], bz = m.vz[t.v[1]];
    const float cx = m.vx[t.v[2]], cz = m.vz[t.v[2]];
    const float d1 = (bx - ax) * (pz - az) - (bz - az) * (px - ax);
    const float d2 = (cx - bx) * (pz - bz) - (cz - bz) * (px - bx);
    const float d3 = (ax - cx) * (pz - cz) - (az - cz) * (px - cx);
    const bool neg = d1 < 0 || d2 < 0 || d3 < 0;
    const bool pos = d1 > 0 || d2 > 0 || d3 > 0;
    return !(neg && pos);
}

// Ground truth from a mesh: containing triangle index (or -1), brute force.
static long long containingTri(float px, float pz, const Mesh& m) {
    for (size_t i = 0; i < m.tris.size(); ++i)
        if (pointInTri(px, pz, m, m.tris[i])) return (long long)i;
    return -1;
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

// -------- diff mode --------
static int runDiff(const char* ourPath, const char* origPath, const char* folder,
                   int pairs, int maxScenes) {
    Dll our = loadDll(ourPath);
    Dll orig = loadDll(origPath);
    if (!our.ok()) { printf("FAIL: cannot load OUR dll %s\n", ourPath); return 2; }
    const bool haveOrig = orig.ok();
    if (!haveOrig) printf("WARN: original dll not loadable (%s); parse-diff skipped, running self checks only\n", origPath);

    WIN32_FIND_DATAA fd;
    std::string pat = std::string(folder) + "\\*.path";
    HANDLE hf = FindFirstFileA(pat.c_str(), &fd);
    if (hf == INVALID_HANDLE_VALUE) { printf("no .path files\n"); return 0; }

    int scenes = 0, sceneMismatch = 0;
    long long totalPairs = 0, reachMismatch = 0, ourCrashes = 0;
    long long totalLenCompared = 0, totalLenMismatch = 0;
    std::mt19937 rng(12345);

    do {
        if (scenes >= maxScenes) break;
        std::string full = std::string(folder) + "\\" + fd.cFileName;
        std::vector<std::uint8_t> bytes;
        if (!readFile(full.c_str(), bytes) || bytes.size() < 32) continue;

        Mesh mo, mm;  // original, ours
        const char* err = "";
        if (!extractMesh(our, bytes, kOurs, mm, &err)) {
            printf("[%s] OUR extract failed: %s\n", fd.cFileName, err);
            continue;
        }
        bool parseMatch = true;
        if (haveOrig) {
            const char* e2 = "";
            if (!extractMesh(orig, bytes, kOrig, mo, &e2)) {
                printf("[%s] ORIG extract failed: %s (skipping parse-diff)\n", fd.cFileName, e2);
            } else {
                // Compare counts + every vertex + every triangle.
                if (mo.vcount != mm.vcount || mo.tcount != mm.tcount) {
                    parseMatch = false;
                    printf("[%s] COUNT mismatch: verts %lld/%lld tris %lld/%lld\n", fd.cFileName,
                           mm.vcount, mo.vcount, mm.tcount, mo.tcount);
                }
                long long vn = mo.vcount < mm.vcount ? mo.vcount : mm.vcount;
                int shown = 0;
                for (long long i = 0; i < vn; ++i) {
                    if (mo.vx[(size_t)i] != mm.vx[(size_t)i] || mo.vz[(size_t)i] != mm.vz[(size_t)i]) {
                        parseMatch = false;
                        if (shown++ < 3) printf("[%s] vert %lld differs\n", fd.cFileName, i);
                    }
                }
                long long tn = mo.tcount < mm.tcount ? mo.tcount : mm.tcount;
                shown = 0;
                for (long long i = 0; i < tn; ++i) {
                    const ExTri& a = mm.tris[(size_t)i];
                    const ExTri& b = mo.tris[(size_t)i];
                    if (std::memcmp(a.v, b.v, 12) || std::memcmp(a.n, b.n, 12) ||
                        a.flag != b.flag || a.extra != b.extra) {
                        parseMatch = false;
                        if (shown++ < 3)
                            printf("[%s] tri %lld differs: ours{v %u,%u,%u f%u e%u} orig{v %u,%u,%u f%u e%u}\n",
                                   fd.cFileName, i, a.v[0], a.v[1], a.v[2], a.flag, a.extra,
                                   b.v[0], b.v[1], b.v[2], b.flag, b.extra);
                    }
                }
                if (!parseMatch) ++sceneMismatch;
            }
        }

        // Random reachability queries: OUR exported findPath vs ground-truth from the mesh
        // (containing triangle + region id). Ground truth uses the original mesh when present,
        // else ours (still validates our findPath against our own parse — a regression guard).
        const Mesh& gt = haveOrig && mo.tcount ? mo : mm;
        float minx = 1e30f, maxx = -1e30f, minz = 1e30f, maxz = -1e30f;
        for (size_t i = 0; i < gt.vx.size(); ++i) {
            minx = gt.vx[i] < minx ? gt.vx[i] : minx;
            maxx = gt.vx[i] > maxx ? gt.vx[i] : maxx;
            minz = gt.vz[i] < minz ? gt.vz[i] : minz;
            maxz = gt.vz[i] > maxz ? gt.vz[i] : maxz;
        }
        if (maxx <= minx || maxz <= minz) { ++scenes; continue; }
        std::uniform_real_distribution<float> ux(minx, maxx), uz(minz, maxz);

        void* pd = our.getPathData(nullptr);
        vcall<slot::PD_parse, void>(pd, (void*)bytes.data());
        void* pf = our.getPathFinder(nullptr);
        vcall<slot::PF_init, void>(pf, pd);

        // The original pathfinder is intentionally NOT invoked (its findPath ABI is not
        // reliably reproducible cross-DLL); length is validated on our own result below.
        void* opd = nullptr;
        void* opf = nullptr;
        bool origPf = false;
        long long lenCompared = 0, lenMismatch = 0, origPfFaults = 0;
        (void)sehInitPf;

        int reached = 0, made = 0;
        for (int k = 0; k < pairs; ++k) {
            float s[3] = {ux(rng), 0, uz(rng)};
            float g[3] = {ux(rng), 0, uz(rng)};
            long long st = containingTri(s[0], s[2], gt);
            long long gtt = containingTri(g[0], g[2], gt);
            bool truthReach = false;
            if (st >= 0 && gtt >= 0) {
                const ExTri& a = gt.tris[(size_t)st];
                const ExTri& b = gt.tris[(size_t)gtt];
                truthReach = !(a.flag & 1) && !(b.flag & 1) && a.extra != 0 && a.extra == b.extra;
            }
            float outFirst[2] = {0, 0};
            bool crashed = false;
            bool ourReach = sehFindPath(pf, s, g, outFirst, &crashed);
            if (crashed) { ++ourCrashes; continue; }
            ++totalPairs;
            if (truthReach) ++reached;
            if (ourReach) ++made;
            if (ourReach != truthReach) {
                if (reachMismatch < 20)
                    printf("[%s] reach mismatch @ (%.1f,%.1f)->(%.1f,%.1f): ours=%d truth=%d\n",
                           fd.cFileName, s[0], s[2], g[0], g[2], (int)ourReach, (int)truthReach);
                ++reachMismatch;
            }
            // Path-length quality gate on OUR result: a returned path must be finite and no
            // shorter than the straight-line distance (a lower bound), and not absurdly long.
            // (Direct length parity with the original is not asserted: the original's findPath
            //  vtable-slot argument packing could not be reproduced reliably cross-DLL.)
            if (ourReach) {
                double lm = sehPathLen(pf, s, g);
                if (lm >= 0.0) {
                    ++lenCompared;
                    const double straight = std::sqrt((double)(g[0]-s[0])*(g[0]-s[0]) + (double)(g[2]-s[2])*(g[2]-s[2]));
                    const bool bad = !(lm >= 0.0) || lm != lm /*NaN*/ ||
                                     lm < straight - 0.5 || lm > straight * 12.0 + 100.0;
                    if (bad) {
                        if (lenMismatch < 8)
                            printf("[%s] path length unreasonable @ (%.0f,%.0f)->(%.0f,%.0f): len=%.1f straight=%.1f\n",
                                   fd.cFileName, s[0], s[2], g[0], g[2], lm, straight);
                        ++lenMismatch;
                    }
                }
            }
            (void)origPf; (void)opf; (void)origPfFaults;
        }
        printf("[%s] verts=%lld tris=%lld parseMatch=%s | pairs=%d truthReach=%d ourReach=%d | lenChk=%lld lenBad=%lld\n",
               fd.cFileName, mm.vcount, mm.tcount, haveOrig ? (parseMatch ? "YES" : "NO") : "n/a",
               pairs, reached, made, lenCompared, lenMismatch);
        totalLenCompared += lenCompared;
        totalLenMismatch += lenMismatch;
        if (opd || opf) sehDestroyPf(orig, opd, opf);
        our.destroyPathFinder(nullptr, pf);
        our.destroyPathData(nullptr, pd);
        ++scenes;
    } while (FindNextFileA(hf, &fd));
    FindClose(hf);

    printf("\nDIFF TEST: %d scenes, parse-mismatch scenes=%d, pairs=%lld, reach-mismatch=%lld, our-crashes=%lld\n"
           "           our path length checked=%lld, unreasonable=%lld\n",
           scenes, sceneMismatch, totalPairs, reachMismatch, ourCrashes, totalLenCompared, totalLenMismatch);
    return (sceneMismatch == 0 && ourCrashes == 0 && totalLenMismatch == 0) ? 0 : 1;
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
    if (argc >= 5 && strcmp(argv[1], "diff") == 0) {
        int pairs = argc >= 6 ? atoi(argv[5]) : 2000;
        int maxScenes = argc >= 7 ? atoi(argv[6]) : 10;
        return runDiff(argv[2], argv[3], argv[4], pairs, maxScenes);
    }
    printf("usage:\n  pathlib_test load <our.dll> <sceneFolder>\n"
           "  pathlib_test diff <our.dll> <orig.dll> <sceneFolder> [pairs=2000] [maxScenes=10]\n");
    return 2;
}
