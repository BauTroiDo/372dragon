// navmesh_test.cpp — CYS: kiểm offline cys::NavMesh (Src/Client/WXClient/World/CysNavMesh.cpp) trên dữ liệu
// *.path thật của Canonical, qua PathLib.dll clean-room (nạp động, giống Game.exe).
//
//   navmesh_test <SceneFolder> [--scene dali.path] [--start x,z] [--out <dir>] [--all] [--queries N]
//
// Kiểm:
//   1. nạp cảnh chỉ định: thống kê, bất biến (blocked => extra==0, walkable => extra!=0) = 0 vi phạm,
//      biên nằm trong kích thước cảnh (đơn vị 1:1 với thế giới/server);
//   2. FindPath từ --start tới >= 3 điểm đi được gần đó: đường hợp lệ (mọi đoạn không cắt cạnh ràng buộc,
//      mọi waypoint đi được), có ít nhất một đường vòng (>= 2 waypoint);
//   3. điểm trong ô bị chặn: IsBlocked = true, FindPath = false;
//   4. mô phỏng 3 lượt click nối tiếp (đi hết đường rồi click tiếp), gồm một click vào ô chặn -> MoveAlong dừng
//      trước tường (điểm dừng đi được);
//   5. --all: nạp mọi *.path trong thư mục (SEH), đếm vi phạm bất biến và chạy --queries truy vấn ngẫu nhiên.
// Ghi <out>/paths.json (cho tools/draw_navmesh.py) và <out>/navmesh_test_report.txt. Exit 0 = đạt.

#define WIN32_LEAN_AND_MEAN
#include <windows.h>

#include <cmath>
#include <cstdarg>
#include <cstdio>
#include <cstdlib>
#include <cctype>
#include <cstring>
#include <random>
#include <string>
#include <vector>

#include "CysNavMesh.h"

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

std::vector<std::string> ListPathFiles(const std::string& folder) {
    std::vector<std::string> out;
    WIN32_FIND_DATAA fd;
    HANDLE h = FindFirstFileA((folder + "\\*.path").c_str(), &fd);
    if (h == INVALID_HANDLE_VALUE) return out;
    do {
        if (!(fd.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY)) out.push_back(fd.cFileName);
    } while (FindNextFileA(h, &fd));
    FindClose(h);
    return out;
}

bool PathValid(const cys::NavMesh& nav, const cys::NavPoint& start, const std::vector<cys::NavPoint>& way,
               std::string& why) {
    cys::NavPoint prev = start;
    for (std::size_t i = 0; i < way.size(); ++i) {
        if (!nav.IsWalkable(way[i].x, way[i].z)) { why = "waypoint in blocked triangle"; return false; }
        if (nav.SegmentHitsWall(prev, way[i])) { why = "segment crosses a constraint edge"; return false; }
        prev = way[i];
    }
    return true;
}

struct ClickSim {
    cys::NavPoint from, click, stop;
    std::vector<cys::NavPoint> way;
    bool blocked = false, found = false, partial = false;
};

std::string J(const cys::NavPoint& p) {
    char b[64];
    std::snprintf(b, sizeof(b), "[%.3f,%.3f]", p.x, p.z);
    return b;
}
std::string J(const std::vector<cys::NavPoint>& v) {
    std::string s = "[";
    for (std::size_t i = 0; i < v.size(); ++i) { if (i) s += ","; s += J(v[i]); }
    return s + "]";
}

// SEH-guarded load for the --all sweep.
int GuardedLoad(cys::NavMesh& nav, const char* file, bool& ok) {
    __try {
        ok = nav.LoadFromFile(file);
        return 0;
    } __except (EXCEPTION_EXECUTE_HANDLER) {
        return (int)GetExceptionCode();
    }
}

}  // namespace

int main(int argc, char** argv) {
    if (argc < 2) {
        std::fprintf(stderr, "usage: navmesh_test <SceneFolder> [--scene dali.path] [--start x,z] [--out dir] [--all] [--queries N]\n");
        return 2;
    }
    std::string folder = argv[1];
    std::string scene = "dali.path";
    std::string outDir = ".";
    float sx = 165.0f, sz = 170.0f;
    bool all = false;
    int queries = 20;
    std::string sceneDef;
    std::vector<int> ids;
    for (int i = 2; i < argc; ++i) {
        std::string a = argv[i];
        if (a == "--scenedef" && i + 1 < argc) sceneDef = argv[++i];
        else if (a == "--ids" && i + 1 < argc) {
            const char* p = argv[++i];
            // separators , : + (cmd.exe splits %1 on commas, so the .cmd wrapper passes 2:1:3)
            while (*p) { ids.push_back(std::atoi(p)); while (*p && *p != ',' && *p != ':' && *p != '+') ++p; if (*p == ',' || *p == ':' || *p == '+') ++p; }
        }
        else if (a == "--scene" && i + 1 < argc) scene = argv[++i];
        else if (a == "--start" && i + 1 < argc) std::sscanf(argv[++i], "%f,%f", &sx, &sz);
        else if (a == "--out" && i + 1 < argc) outDir = argv[++i];
        else if (a == "--all") all = true;
        else if (a == "--queries" && i + 1 < argc) queries = std::atoi(argv[++i]);
    }
    CreateDirectoryA(outDir.c_str(), nullptr);

    // ---------------- 0. SceneDefineEx cột 5 -> *.path (cảnh 2 và các cảnh --ids), cùng đường nạp/log của CScene ----
    if (!sceneDef.empty()) {
        std::FILE* f = std::fopen(sceneDef.c_str(), "rb");
        Check(f != nullptr, "0a SceneDefineEx.txt opens");
        if (f) {
            std::vector<char> buf;
            char tmp[65536];
            std::size_t n;
            while ((n = std::fread(tmp, 1, sizeof(tmp), f)) > 0) buf.insert(buf.end(), tmp, tmp + n);
            std::fclose(f);
            std::string text(buf.begin(), buf.end());
            int checked = 0;
            std::size_t pos = 0;
            while (pos < text.size()) {
                std::size_t eol = text.find('\n', pos);
                if (eol == std::string::npos) eol = text.size();
                std::string line = text.substr(pos, eol - pos);
                pos = eol + 1;
                if (!line.empty() && line.back() == '\r') line.pop_back();
                if (line.empty() || !std::isdigit((unsigned char)line[0])) continue;
                std::vector<std::string> cols;
                std::size_t c = 0;
                while (true) {
                    std::size_t t = line.find('\t', c);
                    cols.push_back(line.substr(c, t == std::string::npos ? std::string::npos : t - c));
                    if (t == std::string::npos) break;
                    c = t + 1;
                }
                if (cols.size() < 6) continue;
                const int id = std::atoi(cols[0].c_str());
                bool wanted = false;
                for (int w : ids) if (w == id) wanted = true;
                if (!wanted) continue;
                const int xs = std::atoi(cols[2].c_str()), zs = std::atoi(cols[3].c_str());
                const std::string& file = cols[5];
                cys::NavMesh m;
                const bool ok = m.LoadFromFile((folder + "\\" + file).c_str());
                if (!ok) {
                    Report("CYS: navmesh %s missing (scene %d); click-to-move limited to scene bounds", file.c_str(), id);
                } else {
                    // Cùng nội dung dòng log của CScene::LoadNavMesh (Scene.cpp).
                    Report("CYS: navmesh %s %s  [scene %d size %dx%d]", file.c_str(), m.Summary().c_str(), id, xs, zs);
                }
                char label[96];
                std::snprintf(label, sizeof(label), "0b scene %d col5=%s loads through PathLib", id, file.c_str());
                Check(ok, label);
                if (ok) {
                    const cys::NavStats& s = m.Stats();
                    std::snprintf(label, sizeof(label), "0c scene %d navmesh bounds fit SceneDefineEx size (units 1:1)", id);
                    Check(s.maxX <= (float)xs + 1.0f && s.maxZ <= (float)zs + 1.0f && s.maxX > (float)xs * 0.5f, label);
                    std::snprintf(label, sizeof(label), "0d scene %d invariant (blocked=>extra==0, walkable=>extra!=0)", id);
                    Check(s.invariantBlockedExtra == 0 && s.invariantWalkableZero == 0, label);
                }
                ++checked;
            }
            Report("scenedef: %d scene rows checked (ids requested %u)", checked, (unsigned)ids.size());
            Check(checked >= 4, "0e scene 2 and >= 3 other scenes checked");
        }
    }

    // ---------------- 1. nạp cảnh chính ----------------
    cys::NavMesh nav;
    const std::string sceneFile = folder + "\\" + scene;
    const bool loaded = nav.LoadFromFile(sceneFile.c_str());
    Report("scene %s loaded=%d %s", scene.c_str(), (int)loaded, loaded ? nav.Summary().c_str() : "");
    Check(loaded, "1a load scene");
    if (!loaded) return 1;
    const cys::NavStats& st = nav.Stats();
    Check(st.invariantBlockedExtra == 0 && st.invariantWalkableZero == 0, "1b invariant: blocked=>extra==0, walkable=>extra!=0");
    Check(st.regions >= 1 && st.edges > 0 && st.blockedTris > 0, "1c mesh has regions, walls and blocked triangles");
    Check(st.minX >= -1.0f && st.minZ >= -1.0f && st.maxX <= 4096.0f && st.maxZ <= 4096.0f, "1d bounds are world units (0..scene size)");
    Report("units: 1 .path unit = 1 world unit (server posWorld); scene bounds max=(%.1f,%.1f) cell=%u", st.maxX, st.maxZ, st.cellSize);

    // ---------------- 2. FindPath từ start tới >= 3 điểm ----------------
    cys::NavPoint start = {sx, sz};
    Report("start (%.1f,%.1f) walkable=%d region=%u", sx, sz, (int)nav.IsWalkable(sx, sz), nav.RegionAt(sx, sz));
    Check(nav.IsWalkable(sx, sz), "2a start is walkable");
    const unsigned startRegion = nav.RegionAt(sx, sz);

    struct Q { cys::NavPoint to; std::vector<cys::NavPoint> way; bool ok; bool los; };
    std::vector<Q> qs;
    int detours = 0;
    // Quét vòng tròn: bán kính 12..60, 16 hướng; giữ điểm đi được cùng vùng; ưu tiên có đường vòng.
    for (float r = 12.0f; r <= 60.0f && qs.size() < 6; r += 8.0f) {
        for (int k = 0; k < 16 && qs.size() < 6; ++k) {
            const float ang = (float)k * 6.2831853f / 16.0f;
            cys::NavPoint to = {sx + r * std::cos(ang), sz + r * std::sin(ang)};
            if (!nav.IsWalkable(to.x, to.z) || nav.RegionAt(to.x, to.z) != startRegion) continue;
            Q q;
            q.to = to;
            q.los = nav.LineOfSight(start, to);
            q.ok = nav.FindPath(start, to, q.way);
            if (!q.ok) continue;
            if (q.way.size() >= 2) ++detours;
            else if (qs.size() >= 3 && detours == 0) continue;  // giữ chỗ cho đường vòng
            qs.push_back(q);
        }
    }
    Report("queries=%u detours=%d", (unsigned)qs.size(), detours);
    Check(qs.size() >= 3, "2b >= 3 reachable targets found near start");
    for (std::size_t i = 0; i < qs.size(); ++i) {
        std::string why;
        const bool valid = PathValid(nav, start, qs[i].way, why);
        float len = 0;
        cys::NavPoint prev = start;
        for (const auto& w : qs[i].way) { len += std::sqrt((w.x - prev.x) * (w.x - prev.x) + (w.z - prev.z) * (w.z - prev.z)); prev = w; }
        Report("  path %u: to (%.1f,%.1f) waypoints=%u len=%.1f los=%d valid=%d %s", (unsigned)i, qs[i].to.x, qs[i].to.z,
               (unsigned)qs[i].way.size(), len, (int)qs[i].los, (int)valid, why.c_str());
        char label[64];
        std::snprintf(label, sizeof(label), "2c path %u valid (no wall crossing)", (unsigned)i);
        Check(valid, label);
        std::snprintf(label, sizeof(label), "2d path %u ends at target", (unsigned)i);
        Check(!qs[i].way.empty() && std::fabs(qs[i].way.back().x - qs[i].to.x) < 1e-3f && std::fabs(qs[i].way.back().z - qs[i].to.z) < 1e-3f, label);
    }
    Check(detours >= 1, "2e at least one path bends around a wall (>= 2 waypoints)");

    // ---------------- 3. điểm bị chặn ----------------
    cys::NavPoint blockedPt = {-1, -1};
    bool haveBlocked = false;
    for (float r = 2.0f; r <= 80.0f && !haveBlocked; r += 1.0f) {
        for (int k = 0; k < 32 && !haveBlocked; ++k) {
            const float ang = (float)k * 6.2831853f / 32.0f;
            cys::NavPoint p = {sx + r * std::cos(ang), sz + r * std::sin(ang)};
            if (nav.IsBlocked(p.x, p.z) && p.x > 0 && p.z > 0 && p.x < st.maxX && p.z < st.maxZ) { blockedPt = p; haveBlocked = true; }
        }
    }
    Report("blocked point near start: (%.1f,%.1f) found=%d", blockedPt.x, blockedPt.z, (int)haveBlocked);
    Check(haveBlocked, "3a a blocked point exists near start");
    std::vector<cys::NavPoint> wb;
    Check(haveBlocked && !nav.FindPath(start, blockedPt, wb), "3b FindPath to blocked point returns unreachable");
    Check(haveBlocked && nav.IsBlocked(blockedPt.x, blockedPt.z) && !nav.IsWalkable(blockedPt.x, blockedPt.z), "3c IsBlocked/IsWalkable agree");
    Check(nav.RegionAt(blockedPt.x, blockedPt.z) == 0, "3d blocked point has region 0");
    // Điểm khác vùng liên thông (nếu có) cũng phải "không tới được".
    {
        bool otherRegionChecked = false;
        for (float x = 4.0f; x < st.maxX && !otherRegionChecked; x += 6.0f)
            for (float z = 4.0f; z < st.maxZ && !otherRegionChecked; z += 6.0f) {
                const unsigned r = nav.RegionAt(x, z);
                if (r != 0 && r != startRegion) {
                    std::vector<cys::NavPoint> w;
                    cys::NavPoint p = {x, z};
                    const bool reach = nav.FindPath(start, p, w);
                    Report("other region %u at (%.1f,%.1f): reachable=%d", r, x, z, (int)reach);
                    Check(!reach, "3e point in another connected region is unreachable");
                    otherRegionChecked = true;
                }
            }
        if (!otherRegionChecked) Report("no second connected region in this scene (3e skipped)");
    }

    // ---------------- 4. mô phỏng 3 lượt click ----------------
    std::vector<ClickSim> clicks;
    {
        cys::NavPoint pos = start;
        // click 1: mục tiêu có đường vòng nếu có, nếu không lấy mục tiêu đầu
        std::size_t pick = 0;
        for (std::size_t i = 0; i < qs.size(); ++i) if (qs[i].way.size() >= 2) { pick = i; break; }
        ClickSim c1; c1.from = pos; c1.click = qs.empty() ? start : qs[pick].to;
        c1.found = nav.FindPath(c1.from, c1.click, c1.way);
        if (c1.found) pos = c1.way.back();
        c1.stop = pos;
        clicks.push_back(c1);
        // click 2: điểm bị chặn -> đỏ, đi thẳng tới trước tường (GetPathDirect của CPath)
        ClickSim c2; c2.from = pos; c2.click = blockedPt; c2.blocked = nav.IsBlocked(blockedPt.x, blockedPt.z);
        c2.found = nav.FindPath(c2.from, c2.click, c2.way);
        if (!c2.found) {
            cys::NavPoint stop;
            const bool hit = nav.MoveAlong(c2.from, c2.click, stop);
            // như CPath::GetPathDirect: lùi 0,3 đơn vị về phía xuất phát
            if (hit) {
                const float dx = stop.x - c2.from.x, dz = stop.z - c2.from.z;
                const float len = std::sqrt(dx * dx + dz * dz);
                if (len > 0.3f) { stop.x = c2.from.x + dx * (len - 0.3f) / len; stop.z = c2.from.z + dz * (len - 0.3f) / len; }
            }
            c2.partial = hit;
            c2.stop = stop;
            if (nav.IsWalkable(stop.x, stop.z)) { c2.way.push_back(stop); pos = stop; }
        } else { pos = c2.way.back(); c2.stop = pos; }
        clicks.push_back(c2);
        // click 3: quay về điểm xuất phát
        ClickSim c3; c3.from = pos; c3.click = start;
        c3.found = nav.FindPath(c3.from, c3.click, c3.way);
        if (c3.found) pos = c3.way.back();
        c3.stop = pos;
        clicks.push_back(c3);
    }
    for (std::size_t i = 0; i < clicks.size(); ++i) {
        const ClickSim& c = clicks[i];
        std::string why;
        const bool valid = PathValid(nav, c.from, c.way, why);
        Report("  click %u: from (%.1f,%.1f) click (%.1f,%.1f) blocked=%d found=%d partial=%d waypoints=%u stop (%.1f,%.1f) valid=%d %s",
               (unsigned)i + 1, c.from.x, c.from.z, c.click.x, c.click.z, (int)c.blocked, (int)c.found, (int)c.partial,
               (unsigned)c.way.size(), c.stop.x, c.stop.z, (int)valid, why.c_str());
        char label[64];
        std::snprintf(label, sizeof(label), "4 click %u walk is valid", (unsigned)i + 1);
        Check(valid, label);
    }
    Check(clicks[1].blocked && !clicks[1].found, "4b click on blocked cell: red marker (IsBlocked) and no full path");
    Check(!clicks[1].way.empty() ? nav.IsWalkable(clicks[1].stop.x, clicks[1].stop.z) : true, "4c partial walk stops on walkable ground before the wall");
    Check(clicks[2].found, "4d walking back to start succeeds");

    // ---------------- ghi paths.json ----------------
    {
        std::string js = "{\n  \"scene\": \"" + scene + "\",\n  \"start\": " + J(start) + ",\n  \"blocked\": " + J(blockedPt) + ",\n  \"paths\": [\n";
        for (std::size_t i = 0; i < qs.size(); ++i) {
            js += "    {\"to\": " + J(qs[i].to) + ", \"los\": " + (qs[i].los ? "true" : "false") + ", \"way\": " + J(qs[i].way) + "}";
            js += (i + 1 < qs.size()) ? ",\n" : "\n";
        }
        js += "  ],\n  \"clicks\": [\n";
        for (std::size_t i = 0; i < clicks.size(); ++i) {
            const ClickSim& c = clicks[i];
            js += "    {\"from\": " + J(c.from) + ", \"click\": " + J(c.click) + ", \"blocked\": " + (c.blocked ? "true" : "false") +
                  ", \"found\": " + (c.found ? "true" : "false") + ", \"partial\": " + (c.partial ? "true" : "false") +
                  ", \"stop\": " + J(c.stop) + ", \"way\": " + J(c.way) + "}";
            js += (i + 1 < clicks.size()) ? ",\n" : "\n";
        }
        js += "  ]\n}\n";
        std::FILE* f = std::fopen((outDir + "\\paths.json").c_str(), "wb");
        if (f) { std::fwrite(js.data(), 1, js.size(), f); std::fclose(f); }
    }

    // ---------------- 5. --all: mọi *.path ----------------
    if (all) {
        std::vector<std::string> files = ListPathFiles(folder);
        int okFiles = 0, badFiles = 0, crashes = 0, violations = 0, pathsFound = 0, queriesRun = 0;
        std::mt19937 rng(20260914u);
        for (const std::string& fn : files) {
            cys::NavMesh m;
            bool ok = false;
            const int code = GuardedLoad(m, (folder + "\\" + fn).c_str(), ok);
            if (code != 0) { ++crashes; Report("  CRASH 0x%08x %s", (unsigned)code, fn.c_str()); continue; }
            if (!ok) { ++badFiles; Report("  load failed: %s", fn.c_str()); continue; }
            ++okFiles;
            const cys::NavStats& s = m.Stats();
            if (s.invariantBlockedExtra || s.invariantWalkableZero) {
                ++violations;
                Report("  invariant: %s blocked_with_region=%u walkable_without_region=%u", fn.c_str(),
                       (unsigned)s.invariantBlockedExtra, (unsigned)s.invariantWalkableZero);
            }
            std::uniform_real_distribution<float> ux(s.minX, s.maxX), uz(s.minZ, s.maxZ);
            for (int q = 0; q < queries; ++q) {
                cys::NavPoint a = {ux(rng), uz(rng)}, b = {ux(rng), uz(rng)};
                std::vector<cys::NavPoint> w;
                ++queriesRun;
                if (m.FindPath(a, b, w)) {
                    ++pathsFound;
                    std::string why;
                    if (!PathValid(m, a, w, why)) { Report("  invalid path in %s: %s", fn.c_str(), why.c_str()); ++gFails; }
                }
            }
        }
        Report("all: files=%u ok=%d failed=%d crashes=%d invariant_violation_files=%d queries=%d paths=%d",
               (unsigned)files.size(), okFiles, badFiles, crashes, violations, queriesRun, pathsFound);
        Check(crashes == 0, "5a no crash on any .path");
        Check(badFiles == 0, "5b every .path parses");
        Check(violations == 0, "5c invariant holds on every .path");
        Check(okFiles >= 480, "5d >= 480 scenes loaded");
    }

    Report("RESULT %s fails=%d", gFails == 0 ? "PASS" : "FAIL", gFails);
    std::FILE* f = std::fopen((outDir + "\\navmesh_test_report.txt").c_str(), "wb");
    if (f) { for (const auto& l : gReport) { std::fputs(l.c_str(), f); std::fputc('\n', f); } std::fclose(f); }
    return gFails == 0 ? 0 : 1;
}
