// navcol_test.cpp — CYS-NAV: kiểm offline va chạm CY trên dữ liệu thật (Canonical CY SceneFolder).
//
//   navcol_test <SceneFolder> [--scene dali_new_320] [--out <dir>]
//
//  1. *.WCollision: mọi file của thư mục đọc HẾT đúng byte cuối (0xff000001 và 0xff000002), 0 file hỏng.
//  2. dali_new_320.WCollision: số tam giác, mặt bục giữa quảng trường cao hơn địa hình (.Heightmap) ở các điểm
//     click của replay (nhân vật từng chìm trong bục), ngoài bục không có mặt.
//  3. dali_new_320.path: từ vị trí replay (157.8,166.4) tới điểm ngay sau nhà (147.8,166.4): đoạn thẳng cắt cạnh
//     ràng buộc, FindPath trả đường vòng >= 2 waypoint, mọi đoạn không cắt tường; click vào trong nhà: IsBlocked,
//     MoveAlong dừng trước tường; điểm hồi sinh (160,150) đi được.
// Exit 0 = đạt. Báo cáo: <out>/navcol_test_report.txt.

#define WIN32_LEAN_AND_MEAN
#include <windows.h>

#include <cmath>
#include <cstdarg>
#include <cstdio>
#include <cstring>
#include <string>
#include <vector>

#include "CysNavMesh.h"
#include "CysWCollision.h"

namespace {

int gFails = 0;
std::vector<std::string> gReport;

void Report(const char* fmt, ...) {
    char buf[1024];
    va_list ap;
    va_start(ap, fmt);
    _vsnprintf_s(buf, sizeof(buf), _TRUNCATE, fmt, ap);
    va_end(ap);
    std::printf("%s\n", buf);
    gReport.push_back(buf);
}

void Check(bool ok, const char* what) {
    Report("%s %s", ok ? "PASS" : "FAIL", what);
    if (!ok) ++gFails;
}

bool ReadFile(const std::string& path, std::vector<unsigned char>& out) {
    out.clear();
    std::FILE* f = std::fopen(path.c_str(), "rb");
    if (!f) return false;
    std::fseek(f, 0, SEEK_END);
    long n = std::ftell(f);
    std::fseek(f, 0, SEEK_SET);
    if (n > 0) {
        out.resize((std::size_t)n);
        if (std::fread(out.data(), 1, out.size(), f) != out.size()) out.clear();
    }
    std::fclose(f);
    return !out.empty();
}

std::vector<std::string> List(const std::string& folder, const char* pattern) {
    std::vector<std::string> out;
    WIN32_FIND_DATAA fd;
    HANDLE h = FindFirstFileA((folder + "\\" + pattern).c_str(), &fd);
    if (h == INVALID_HANDLE_VALUE) return out;
    do {
        if (!(fd.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY)) out.push_back(fd.cFileName);
    } while (FindNextFileA(h, &fd));
    FindClose(h);
    return out;
}

struct Heightmap {
    unsigned w = 0, h = 0;
    std::vector<float> v;
    bool Load(const std::string& path) {
        std::vector<unsigned char> b;
        if (!ReadFile(path, b) || b.size() < 16 || std::memcmp(b.data(), "MHEF", 4) != 0) return false;
        std::memcpy(&w, b.data() + 8, 4);
        std::memcpy(&h, b.data() + 12, 4);
        if (b.size() < 16 + (std::size_t)w * h * 4) return false;
        v.resize((std::size_t)w * h);
        std::memcpy(v.data(), b.data() + 16, v.size() * 4);
        return true;
    }
    float At(float x, float z) const {
        x = std::fmin(std::fmax(x, 0.0f), (float)w - 1.001f);
        z = std::fmin(std::fmax(z, 0.0f), (float)h - 1.001f);
        const unsigned ix = (unsigned)x, iz = (unsigned)z;
        const float fx = x - ix, fz = z - iz;
        const float h00 = v[iz * w + ix], h10 = v[iz * w + ix + 1], h01 = v[(iz + 1) * w + ix], h11 = v[(iz + 1) * w + ix + 1];
        return (h00 * (1 - fx) + h10 * fx) * (1 - fz) + (h01 * (1 - fx) + h11 * fx) * fz;
    }
};

}  // namespace

int main(int argc, char** argv) {
    if (argc < 2) {
        std::printf("usage: navcol_test <SceneFolder> [--scene dali_new_320] [--out dir]\n");
        return 2;
    }
    std::string folder = argv[1], scene = "dali_new_320", out = ".";
    for (int i = 2; i + 1 < argc; ++i) {
        if (!std::strcmp(argv[i], "--scene")) scene = argv[++i];
        else if (!std::strcmp(argv[i], "--out")) out = argv[++i];
    }

    // 1. mọi *.WCollision
    {
        const std::vector<std::string> files = List(folder, "*.WCollision");
        unsigned ok = 0, bad = 0, m1 = 0, m2 = 0, other = 0;
        std::size_t tris = 0;
        std::vector<unsigned char> buf;
        std::vector<cys::WCollTri> t;
        cys::WCollStats st;
        for (const std::string& f : files) {
            if (!ReadFile(folder + "\\" + f, buf)) { ++bad; Report("  unreadable %s", f.c_str()); continue; }
            if (!cys::IsCyWCollisionMagic(buf.data(), buf.size())) { ++other; continue; }
            const bool parsed = cys::ParseCyWCollision(buf.data(), buf.size(), t, st);
            if (st.magic == 0xff000001u) ++m1; else ++m2;
            if (parsed && st.parsed == st.size) { ++ok; tris += t.size(); }
            else { ++bad; Report("  bad %s %s", f.c_str(), cys::DescribeWCollision(st).c_str()); }
        }
        Report("1a WCollision files=%u ok=%u bad=%u magic1=%u magic2=%u other=%u unique_tris=%u", (unsigned)files.size(), ok,
               bad, m1, m2, other, (unsigned)tris);
        Check(!files.empty() && bad == 0 && other == 0 && ok == files.size(), "1a every *.WCollision parses to its last byte");
    }

    // 2. dali_new_320 bục giữa
    {
        std::vector<unsigned char> buf;
        std::vector<cys::WCollTri> t;
        cys::WCollStats st;
        Heightmap hm;
        const bool loaded = ReadFile(folder + "\\" + scene + ".WCollision", buf) &&
                            cys::ParseCyWCollision(buf.data(), buf.size(), t, st);
        Report("2a %s.WCollision %s", scene.c_str(), cys::DescribeWCollision(st).c_str());
        Check(loaded && st.parsed == st.size && t.size() > 1000, "2a scene WCollision loads");
        Check(hm.Load(folder + "\\" + scene + ".Heightmap"), "2b scene Heightmap loads");
        if (scene == "dali_new_320" && loaded && !hm.v.empty()) {
            Check(st.magic == 0xff000002u && st.meshes == 29 && st.instances == 306 && t.size() == 11752,
                  "2c dali_new_320: 29 meshes, 306 instances, 11752 triangles");
            // Các điểm click của replay 15/09 06:56 (nhân vật chìm trong bục) và tâm bục.
            const float onPlatform[][2] = {{157.8f, 166.4f}, {163.5f, 172.1f}, {160.4f, 179.5f}, {154.8f, 173.8f}, {160.0f, 176.0f}};
            for (const auto& p : onPlatform) {
                float y = 0;
                const bool hit = cys::WCollTopHeight(t, p[0], p[1], y);
                const float ter = hm.At(p[0], p[1]);
                char what[160];
                std::snprintf(what, sizeof(what), "2d (%.1f,%.1f) platform top %.3f above terrain %.3f by >= 2", p[0], p[1],
                              hit ? y : -1.0f, ter);
                Check(hit && y - ter >= 2.0f, what);
            }
            const float offPlatform[][2] = {{160.0f, 150.0f}, {160.0f, 190.0f}};
            for (const auto& p : offPlatform) {
                float y = 0;
                const bool hit = cys::WCollTopHeight(t, p[0], p[1], y);
                char what[160];
                std::snprintf(what, sizeof(what), "2e (%.1f,%.1f) open plaza has no building surface", p[0], p[1]);
                Check(!hit, what);
            }
            // Mọi mặt công trình nằm trên hoặc sát địa hình (không có mặt âm sâu dưới đất do sai phép biến đổi).
            unsigned below = 0, samples = 0, offMap = 0;
            for (const cys::WCollTri& tr : t) {
                const float cx = (tr.v[0] + tr.v[3] + tr.v[6]) / 3, cy = (tr.v[1] + tr.v[4] + tr.v[7]) / 3,
                            cz = (tr.v[2] + tr.v[5] + tr.v[8]) / 3;
                if (cx < 0 || cz < 0 || cx > (float)hm.w || cz > (float)hm.h) { ++offMap; continue; }  // tường thành ngoài biên
                ++samples;
                if (cy < hm.At(cx, cz) - 3.0f) ++below;
            }
            Report("2f triangle centroids more than 3 units under the terrain: %u / %u on the map (%u off the map)", below,
                   samples, offMap);
            Check(samples > 0 && below * 50 < samples, "2f transform T*R*S puts < 2% of on-map centroids under the terrain");
        }
    }

    // 3. navmesh: đích ngay sau nhà
    {
        cys::NavMesh nav;
        const std::string path = folder + "\\" + scene + ".path";
        Check(nav.LoadFromFile(path.c_str()), "3a navmesh loads");
        Report("3a %s", nav.Summary().c_str());
        if (scene == "dali_new_320" && nav.IsLoaded()) {
            const cys::NavPoint start = {157.8f, 166.4f}, behind = {147.8f, 166.4f}, inside = {151.0f, 166.4f},
                                spawn = {160.0f, 150.0f};
            Check(nav.IsWalkable(spawn.x, spawn.z), "3b spawn (160,150) walkable");
            Check(nav.IsWalkable(start.x, start.z) && nav.IsWalkable(behind.x, behind.z) &&
                      nav.RegionAt(start.x, start.z) == nav.RegionAt(behind.x, behind.z),
                  "3c start and target behind the building walkable, same region");
            Check(nav.SegmentHitsWall(start, behind), "3d straight segment start->behind crosses a wall");
            std::vector<cys::NavPoint> way;
            const bool found = nav.FindPath(start, behind, way);
            bool valid = found && !way.empty();
            cys::NavPoint prev = start;
            float len = 0;
            for (const cys::NavPoint& p : way) {
                if (nav.SegmentHitsWall(prev, p) || !nav.IsWalkable(p.x, p.z)) valid = false;
                len += std::sqrt((p.x - prev.x) * (p.x - prev.x) + (p.z - prev.z) * (p.z - prev.z));
                Report("    waypoint (%.2f,%.2f)", p.x, p.z);
                prev = p;
            }
            Report("3e FindPath waypoints=%u length=%.1f (straight 10.0)", (unsigned)way.size(), len);
            Check(valid && way.size() >= 2 && len > 10.5f, "3e FindPath goes around the building, no segment crosses a wall");
            Check(nav.IsBlocked(inside.x, inside.z), "3f click inside the building is blocked");
            cys::NavPoint stop;
            const bool hit = nav.MoveAlong(start, inside, stop);
            Report("3g MoveAlong start->inside hit=%d stop=(%.2f,%.2f)", hit ? 1 : 0, stop.x, stop.z);
            Check(hit && nav.IsWalkable(stop.x, stop.z) && !nav.SegmentHitsWall(start, stop) && stop.x > inside.x,
                  "3g MoveAlong stops before the wall on the walkable side");
        }
    }

    Report("RESULT %s fails=%d", gFails ? "FAIL" : "PASS", gFails);
    std::FILE* f = std::fopen((out + "\\navcol_test_report.txt").c_str(), "wb");
    if (f) {
        for (const std::string& l : gReport) std::fprintf(f, "%s\n", l.c_str());
        std::fclose(f);
    }
    return gFails ? 1 : 0;
}
