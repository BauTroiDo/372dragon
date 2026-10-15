// CysNavMesh.cpp — CYS: navmesh *.path nạp qua PathLib clean-room (Src/Engine/PathLib). Xem CysNavMesh.h.
//
// Dùng đúng giao diện ảo mà Render.dll của B gọi (PathData slot 3 parseBuffer/ParsePathImage, slot 7/13/14/15
// gridCell/edge/triangle/vertex; PathFinder slot 1 init, 3 findPath, 7/8 pointCount/point). Các con trỏ opaque
// từ slot 7/13/14 được ép về struct Cell/Edge/Tri của NavMesh.h — header công khai của chính PathLib clean-room.

#include "CysNavMesh.h"

#include <algorithm>
#include <cmath>
#include <cstdio>
#include <cstring>
#include <set>
#include <vector>

#include "PathLib.h"
#include "NavMesh.h"

namespace cys {

namespace {

inline const PathLib::Tri* TriAt(const PathLib::PathData* pd, std::intptr_t i) {
    return static_cast<const PathLib::Tri*>(pd->triangle(i));
}
inline const PathLib::Edge* EdgeAt(const PathLib::PathData* pd, std::intptr_t i) {
    return static_cast<const PathLib::Edge*>(pd->edge(i));
}
inline const PathLib::Cell* CellAt(const PathLib::PathData* pd, int gx, int gz) {
    return static_cast<const PathLib::Cell*>(pd->gridCell(gx, gz));
}

// Tam giác chứa (x,z) qua lưới ô; PathLib::kNoNeighbor nếu không có.
std::uint32_t FindTri(const PathLib::PathData* pd, float x, float z) {
    int g[2] = {0, 0};
    pd->worldToGrid(g, x, z);
    if (!pd->isValidGrid(g[0], g[1])) return PathLib::kNoNeighbor;
    const PathLib::Cell* c = CellAt(pd, g[0], g[1]);
    if (!c) return PathLib::kNoNeighbor;
    const std::intptr_t nTri = pd->triangleCount();
    for (std::uint32_t ti : c->tris) {
        if ((std::intptr_t)ti >= nTri) continue;
        const PathLib::Tri* t = TriAt(pd, ti);
        const float* a = pd->vertex(t->v[0]);
        const float* b = pd->vertex(t->v[1]);
        const float* cc = pd->vertex(t->v[2]);
        if (!a || !b || !cc) continue;
        if (PathLib::geom::pointInTri(x, z, a, b, cc)) return ti;
    }
    return PathLib::kNoNeighbor;
}

}  // namespace

NavMesh::NavMesh() : m_data(nullptr), m_finder(nullptr), m_loaded(false) {}

NavMesh::~NavMesh() { Unload(); }

void NavMesh::Unload() {
    PathLib::PathLibRoot root;
    if (m_finder) { root.destroyPathFinder(m_finder); m_finder = nullptr; }
    if (m_data) { root.destroyPathData(m_data); m_data = nullptr; }
    m_loaded = false;
    m_stats = NavStats();
    m_name.clear();
}

bool NavMesh::LoadFromMemory(const void* bytes, std::size_t len, const char* nameForLog) {
    Unload();
    if (!bytes || len < 6) return false;
    PathLib::PathLibRoot root;
    m_data = root.getPathData();
    if (!m_data) return false;
    if (!PathLib::ParsePathImage(m_data, bytes, len)) { Unload(); return false; }
    return Finish(nameForLog);
}

bool NavMesh::LoadFromFile(const char* path) {
    Unload();
    if (!path || !*path) return false;
    std::FILE* f = std::fopen(path, "rb");
    if (!f) return false;
    std::vector<unsigned char> buf;
    std::fseek(f, 0, SEEK_END);
    long n = std::ftell(f);
    std::fseek(f, 0, SEEK_SET);
    if (n > 0) {
        buf.resize((std::size_t)n);
        if (std::fread(buf.data(), 1, buf.size(), f) != buf.size()) buf.clear();
    }
    std::fclose(f);
    if (buf.empty()) return false;
    return LoadFromMemory(buf.data(), buf.size(), path);
}

bool NavMesh::Finish(const char* nameForLog) {
    if (!m_data || m_data->triangleCount() <= 0 || m_data->vertexCount() <= 0) { Unload(); return false; }
    PathLib::PathLibRoot root;
    m_finder = root.getPathFinder();
    if (!m_finder) { Unload(); return false; }
    m_finder->init(m_data);
    m_name = nameForLog ? nameForLog : "";
    ComputeStats();
    m_loaded = true;
    return true;
}

void NavMesh::ComputeStats() {
    NavStats s;
    s.points = (std::size_t)m_data->vertexCount();
    s.tris = (std::size_t)m_data->triangleCount();
    std::set<std::uint32_t> regions;
    for (std::intptr_t i = 0; i < (std::intptr_t)s.tris; ++i) {
        const PathLib::Tri* t = TriAt(m_data, i);
        if (!t) continue;
        if (t->blocked()) {
            ++s.blockedTris;
            if (t->extra != 0) ++s.invariantBlockedExtra;
        } else {
            if (t->extra == 0) ++s.invariantWalkableZero;
            else regions.insert(t->extra);
        }
    }
    s.regions = regions.size();
    for (std::intptr_t i = 0;; ++i) {
        if (!EdgeAt(m_data, i)) break;
        ++s.edges;
    }
    bool first = true;
    for (std::intptr_t i = 0; i < (std::intptr_t)s.points; ++i) {
        const float* v = m_data->vertex(i);
        if (!v) continue;
        if (first) { s.minX = s.maxX = v[0]; s.minZ = s.maxZ = v[1]; first = false; }
        s.minX = std::min(s.minX, v[0]); s.maxX = std::max(s.maxX, v[0]);
        s.minZ = std::min(s.minZ, v[1]); s.maxZ = std::max(s.maxZ, v[1]);
    }
    int g[2] = {0, 0};
    // cellSize/nx/nz không có slot đọc trực tiếp: suy từ worldToGrid (ô 8 đơn vị như mọi file gốc).
    m_data->worldToGrid(g, 8.0f, 0.0f);
    s.cellSize = g[0] > 0 ? (unsigned)(8 / g[0]) : 0;
    for (int gx = 0; m_data->isValidGrid(gx, 0); ++gx) s.nx = (unsigned)gx + 1;
    for (int gz = 0; m_data->isValidGrid(0, gz); ++gz) s.nz = (unsigned)gz + 1;
    m_stats = s;
}

std::string NavMesh::Summary() const {
    char buf[320];
    std::snprintf(buf, sizeof(buf),
                  "points=%u tris=%u blocked=%u edges=%u regions=%u cell=%u grid=%ux%u bounds=[%.1f,%.1f]-[%.1f,%.1f] "
                  "invariant_violations=%u",
                  (unsigned)m_stats.points, (unsigned)m_stats.tris, (unsigned)m_stats.blockedTris,
                  (unsigned)m_stats.edges, (unsigned)m_stats.regions, m_stats.cellSize, m_stats.nx, m_stats.nz,
                  m_stats.minX, m_stats.minZ, m_stats.maxX, m_stats.maxZ,
                  (unsigned)(m_stats.invariantBlockedExtra + m_stats.invariantWalkableZero));
    return buf;
}

bool NavMesh::IsBlocked(float x, float z) const {
    if (!m_loaded) return false;
    const std::uint32_t ti = FindTri(m_data, x, z);
    if (ti == PathLib::kNoNeighbor) return true;  // ngoài lưới / không có tam giác => không đi được
    const PathLib::Tri* t = TriAt(m_data, ti);
    return !t || t->blocked();
}

bool NavMesh::IsWalkable(float x, float z) const {
    if (!m_loaded) return false;
    const std::uint32_t ti = FindTri(m_data, x, z);
    if (ti == PathLib::kNoNeighbor) return false;
    const PathLib::Tri* t = TriAt(m_data, ti);
    return t && !t->blocked();
}

unsigned NavMesh::RegionAt(float x, float z) const {
    if (!m_loaded) return 0;
    const std::uint32_t ti = FindTri(m_data, x, z);
    if (ti == PathLib::kNoNeighbor) return 0;
    const PathLib::Tri* t = TriAt(m_data, ti);
    return (t && !t->blocked()) ? t->extra : 0;
}

bool NavMesh::FindPath(const NavPoint& from, const NavPoint& to, std::vector<NavPoint>& out) const {
    out.clear();
    if (!m_loaded || !m_finder) return false;
    const float s[3] = {from.x, 0.0f, from.z};
    const float g[3] = {to.x, 0.0f, to.z};
    float first[2] = {0.0f, 0.0f};
    if (!m_finder->findPath(s, g, first)) return false;
    const std::intptr_t n = m_finder->pointCount();
    if (n < 2) return false;
    out.reserve((std::size_t)n);
    for (std::intptr_t i = 1; i < n; ++i) {  // bỏ điểm 0 = xuất phát
        const float* p = m_finder->point(i);
        if (!p) continue;
        NavPoint np = {p[0], p[1]};
        if (!out.empty() && out.back().x == np.x && out.back().z == np.z) continue;
        out.push_back(np);
    }
    if (out.empty()) return false;
    // Điểm cuối luôn là đích yêu cầu.
    if (std::fabs(out.back().x - to.x) > 1e-4f || std::fabs(out.back().z - to.z) > 1e-4f) {
        NavPoint np = {to.x, to.z};
        out.push_back(np);
    }
    return true;
}

bool NavMesh::LineOfSight(const NavPoint& from, const NavPoint& to) const {
    if (!m_loaded || !m_finder) return false;
    const float s[3] = {from.x, 0.0f, from.z};
    const float g[3] = {to.x, 0.0f, to.z};
    return m_finder->lineOfSight(s, g, nullptr);
}

bool NavMesh::MoveAlong(const NavPoint& from, const NavPoint& to, NavPoint& stop) const {
    stop = to;
    if (!m_loaded || !m_finder) return false;
    float pos[2] = {to.x, to.z};
    float dir[2] = {0.0f, 0.0f};
    if (!m_finder->moveAlong(from.x, from.z, nullptr, to.x, to.z, pos, dir)) return false;
    const bool hit = (pos[0] != to.x || pos[1] != to.z);
    stop.x = pos[0];
    stop.z = pos[1];
    return hit;
}

bool NavMesh::SegmentHitsWall(const NavPoint& from, const NavPoint& to) const {
    if (!m_loaded) return false;
    const float a[2] = {from.x, from.z};
    const float b[2] = {to.x, to.z};
    int g0[2] = {0, 0}, g1[2] = {0, 0};
    m_data->worldToGrid(g0, a[0], a[1]);
    m_data->worldToGrid(g1, b[0], b[1]);
    const int lox = std::min(g0[0], g1[0]), hix = std::max(g0[0], g1[0]);
    const int loz = std::min(g0[1], g1[1]), hiz = std::max(g0[1], g1[1]);
    float tmp[2];
    for (int gz = loz; gz <= hiz; ++gz) {
        for (int gx = lox; gx <= hix; ++gx) {
            const PathLib::Cell* c = CellAt(m_data, gx, gz);
            if (!c) continue;
            for (std::uint32_t ei : c->edges) {
                const PathLib::Edge* e = EdgeAt(m_data, (std::intptr_t)ei);
                if (!e) continue;
                const float* va = m_data->vertex(e->a);
                const float* vb = m_data->vertex(e->b);
                if (!va || !vb) continue;
                if (PathLib::geom::segSeg(a, b, va, vb, tmp)) return true;
            }
        }
    }
    return false;
}

}  // namespace cys
