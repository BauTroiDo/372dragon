





#include <algorithm>
#include <cmath>
#include <cstdint>
#include <queue>
#include <utility>
#include <vector>

#include "NavMesh.h"
#include "PathLib.h"

namespace PathLib {

extern NavMesh* MeshOf(PathData* pd);

PathFinder::~PathFinder() {}

namespace {

// Midpoint of the edge shared by triangles ta and tb (their two common vertices).
bool sharedEdgeMid(const NavMesh& m, std::uint32_t ta, std::uint32_t tb, float* out) {
    const Tri& A = m.tris[ta];
    const Tri& B = m.tris[tb];
    std::uint32_t common[2];
    int n = 0;
    for (int i = 0; i < 3 && n < 2; ++i)
        for (int j = 0; j < 3; ++j)
            if (A.v[i] == B.v[j]) { common[n++] = A.v[i]; break; }
    if (n < 2) {  // not truly adjacent (repaired data): use centroid midpoint
        out[0] = (A.cx + B.cx) * 0.5f;
        out[1] = (A.cz + B.cz) * 0.5f;
        return false;
    }
    const Point2& p = m.verts[common[0]];
    const Point2& q = m.verts[common[1]];
    out[0] = (p.x + q.x) * 0.5f;
    out[1] = (p.z + q.z) * 0.5f;
    return true;
}

}  // namespace

class PathFinderImpl final : public PathFinder {
public:
    NavMesh* mesh = nullptr;
    float radius = 0.1f;  // agent radius (DAT: PathFinder+0xf0 = 0x3dcccccd)

    // A* working set with query-stamped visitation (no per-query clear of the whole array).
    struct Node { float g; std::uint32_t from; std::uint32_t stamp; };
    std::vector<Node> nodes;
    std::uint32_t query = 0;

    std::vector<Point2> points;   // result polyline
    std::vector<std::uint32_t> channel;
    std::vector<std::vector<Point2>> blockPolys;  // dynamic obstacles (slot 10)

    ~PathFinderImpl() override {}

    void init(PathData* pd) override {
        mesh = MeshOf(pd);
        reset();
        if (mesh) nodes.assign(mesh->tris.size(), Node{0.0f, kNoNeighbor, 0});
    }

    void reset() override {
        points.clear();
        channel.clear();
        blockPolys.clear();
        query = 0;
        if (mesh && nodes.size() != mesh->tris.size())
            nodes.assign(mesh->tris.size(), Node{0.0f, kNoNeighbor, 0});
    }

    // The engine passes 3-float world vectors (x, y, z); the nav plane is x-z (Y is up),
    // so we project to (x, z) = components [0] and [2]. `outFirst` receives the first
    // waypoint as 2 floats (x, z), matching how Render reads the point accessor.
    bool findPath(const float* start, const float* goal, float* outFirst) override {
        points.clear();
        channel.clear();
        if (!mesh || !mesh->valid || !start || !goal) return false;
        const float s[2] = {start[0], start[2]};
        const float g[2] = {goal[0], goal[2]};

        const std::uint32_t st = mesh->findTri(s[0], s[1]);
        const std::uint32_t gt = mesh->findTri(g[0], g[1]);
        if (st == kNoNeighbor || gt == kNoNeighbor) return false;
        if (mesh->tris[st].blocked() || mesh->tris[gt].blocked()) return false;


        const std::uint32_t rs = mesh->tris[st].extra;
        const std::uint32_t rg = mesh->tris[gt].extra;
        if (rs == 0 || rg == 0 || rs != rg) return false;

        // Direct line-of-sight shortcut.
        if (losSegment(s, g)) {
            points.push_back({s[0], s[1]});
            points.push_back({g[0], g[1]});
            writeFirst(outFirst);
            return true;
        }

        if (!astar(st, gt)) return false;
        funnel(s, g);
        if (points.size() < 2) {  // degenerate channel: fall back to straight line
            points.clear();
            points.push_back({s[0], s[1]});
            points.push_back({g[0], g[1]});
        }
        writeFirst(outFirst);
        return true;
    }

    bool findNearestReachable(const float* start, const float* goal) override {
        if (findPath(start, goal, nullptr)) return true;
        if (!mesh || !mesh->valid || !start || !goal) return false;
        const float s[2] = {start[0], start[2]};
        const float g[2] = {goal[0], goal[2]};
        const std::uint32_t st = mesh->findTri(s[0], s[1]);
        if (st == kNoNeighbor || mesh->tris[st].blocked()) return false;
        // Snap the goal to the nearest walkable centroid in the start's region, then path to it.
        float best2 = 3.4e38f;
        Point2 target{s[0], s[1]};
        bool found = false;
        const std::uint32_t rs = mesh->tris[st].extra;
        for (const Tri& t : mesh->tris) {
            if (t.blocked() || t.extra != rs) continue;
            const float c[2] = {t.cx, t.cz};
            const float d = geom::dist2(c, g);
            if (d < best2) { best2 = d; target = {t.cx, t.cz}; found = true; }
        }
        const float tg[3] = {target.x, 0.0f, target.z};
        return found && findPath(start, tg, nullptr);
    }

    // First blocked crossing of segment (px,pz)->(out on entry) — used as a walkability probe.
    bool raycastWalkable(float px, float pz, float* out, void* /*outCell*/, char /*blocked*/) override {
        if (!mesh || !mesh->valid || !out) return false;
        const float a[2] = {px, pz};
        const float b[2] = {out[0], out[1]};
        return firstWallHit(a, b, out);
    }

    std::intptr_t pointCount() const override { return (std::intptr_t)points.size(); }
    const float* point(std::intptr_t i) const override {
        return (i >= 0 && (std::size_t)i < points.size()) ? &points[(std::size_t)i].x : nullptr;
    }
    const void* regionRoot() const override { return this; }

    bool addBlockPolygon(const float* pts, int n, void* /*tag*/) override {
        if (!pts || n < 3) return false;
        std::vector<Point2> poly;
        poly.reserve(n);
        for (int i = 0; i < n; ++i) poly.push_back({pts[i * 2], pts[i * 2 + 1]});
        blockPolys.push_back(std::move(poly));
        return true;
    }
    bool removeBlockPolygon(void* /*tag*/) override {
        if (blockPolys.empty()) return false;
        blockPolys.pop_back();
        return true;
    }

    bool moveAlong(float sx, float sz, const void* /*goalHint*/, float gx, float gz,
                   float* outPos, float* outDir) override {
        if (!mesh || !mesh->valid) return false;
        const float a[2] = {sx, sz};
        const float b[2] = {gx, gz};
        float hit[2];
        if (!firstWallHit(a, b, hit)) {  // clear move
            if (outPos) { outPos[0] = gx; outPos[1] = gz; }
            if (outDir) { outDir[0] = 0; outDir[1] = 0; }
            return true;
        }
        // Stop just before the wall; report the residual direction (for a slide by the caller).
        if (outPos) { outPos[0] = hit[0]; outPos[1] = hit[1]; }
        if (outDir) {
            float d[2] = {gx - hit[0], gz - hit[1]};
            const float len = std::sqrt(d[0] * d[0] + d[1] * d[1]);
            if ((double)len > geom::kUnitEps) { d[0] /= len; d[1] /= len; }
            outDir[0] = d[0];
            outDir[1] = d[1];
        }
        return true;
    }

    bool lineOfSight(const float* start, const float* goal, void* /*scratch*/) override {
        if (!start || !goal) return false;
        const float s[2] = {start[0], start[2]};
        const float g[2] = {goal[0], goal[2]};
        return losSegment(s, g);
    }

    bool slot13(void*) override { return false; }
    bool slot14(void*) override { return false; }
    bool slot15(void*) override { return false; }
    bool slot16(void*) override { return false; }
    bool slot17(void*) override { return false; }
    bool slot18(void*) override { return false; }
    bool slot19(void*) override { return false; }

private:
    void writeFirst(float* outFirst) {
        if (outFirst && points.size() >= 2) { outFirst[0] = points[1].x; outFirst[1] = points[1].z; }
        else if (outFirst && !points.empty()) { outFirst[0] = points.back().x; outFirst[1] = points.back().z; }
    }




    bool losSegment(const float* a, const float* b) const {
        // Any dynamic obstacle edge crossed?
        for (const auto& poly : blockPolys) {
            const std::size_t n = poly.size();
            for (std::size_t i = 0; i < n; ++i) {
                const float* p = &poly[i].x;
                const float* q = &poly[(i + 1) % n].x;
                if (geom::segCross(a, b, p, q)) return false;
            }
        }
        if (!mesh) return true;
        int gx0, gz0, gx1, gz1;
        mesh->worldToGrid(a[0], a[1], gx0, gz0);
        mesh->worldToGrid(b[0], b[1], gx1, gz1);
        float tmp[2];
        // Walk the inclusive rectangle of cells the segment overlaps (cells are small, and the
        // segment cannot skip a wall that lies in an untouched cell of its own bounding box).
        const int lo_x = std::min(gx0, gx1), hi_x = std::max(gx0, gx1);
        const int lo_z = std::min(gz0, gz1), hi_z = std::max(gz0, gz1);
        for (int gz = lo_z; gz <= hi_z; ++gz) {
            for (int gx = lo_x; gx <= hi_x; ++gx) {
                const Cell* c = mesh->cellAt(gx, gz);
                if (!c) continue;
                for (std::uint32_t ei : c->edges) {
                    if (ei >= mesh->edges.size()) continue;
                    const Edge& e = mesh->edges[ei];
                    if (geom::segSeg(a, b, &mesh->verts[e.a].x, &mesh->verts[e.b].x, tmp)) return false;
                }
            }
        }
        return true;
    }

    // First wall crossing along a->b (nearest to a). Returns true and writes the point.
    bool firstWallHit(const float* a, const float* b, float* out) const {
        if (!mesh) return false;
        int gx0, gz0, gx1, gz1;
        mesh->worldToGrid(a[0], a[1], gx0, gz0);
        mesh->worldToGrid(b[0], b[1], gx1, gz1);
        const int lo_x = std::min(gx0, gx1), hi_x = std::max(gx0, gx1);
        const int lo_z = std::min(gz0, gz1), hi_z = std::max(gz0, gz1);
        float best2 = 3.4e38f;
        bool hit = false;
        float tmp[2];
        for (int gz = lo_z; gz <= hi_z; ++gz) {
            for (int gx = lo_x; gx <= hi_x; ++gx) {
                const Cell* c = mesh->cellAt(gx, gz);
                if (!c) continue;
                for (std::uint32_t ei : c->edges) {
                    if (ei >= mesh->edges.size()) continue;
                    const Edge& e = mesh->edges[ei];
                    if (geom::segSeg(a, b, &mesh->verts[e.a].x, &mesh->verts[e.b].x, tmp)) {
                        const float d = geom::dist2(a, tmp);
                        if (d < best2) { best2 = d; out[0] = tmp[0]; out[1] = tmp[1]; hit = true; }
                    }
                }
            }
        }
        return hit;
    }

    bool astar(std::uint32_t start, std::uint32_t goal) {
        if (nodes.size() != mesh->tris.size()) nodes.assign(mesh->tris.size(), Node{0.0f, kNoNeighbor, 0});
        ++query;
        if (query == 0) { std::fill(nodes.begin(), nodes.end(), Node{0.0f, kNoNeighbor, 0}); query = 1; }

        const float goalC[2] = {mesh->tris[goal].cx, mesh->tris[goal].cz};
        // Min-heap of (f, tri).
        std::priority_queue<std::pair<float, std::uint32_t>,
                            std::vector<std::pair<float, std::uint32_t>>,
                            std::greater<std::pair<float, std::uint32_t>>> open;
        auto& sn = nodes[start];
        sn.g = 0.0f; sn.from = kNoNeighbor; sn.stamp = query;
        const float sc[2] = {mesh->tris[start].cx, mesh->tris[start].cz};
        open.push({geom::dist(sc, goalC), start});

        const std::uint64_t iterCap = (std::uint64_t)mesh->tris.size() * 4 + 16;
        std::uint64_t iters = 0;
        while (!open.empty()) {
            if (++iters > iterCap) break;  // safety valve
            const std::uint32_t cur = open.top().second;
            const float curf = open.top().first;
            open.pop();
            if (cur == goal) return reconstruct(start, goal);
            const Node& cn = nodes[cur];
            if (cn.stamp != query) continue;
            // Stale heap entry?
            const float cc[2] = {mesh->tris[cur].cx, mesh->tris[cur].cz};
            if (curf > cn.g + geom::dist(cc, goalC) + 1e-3f) continue;
            const Tri& t = mesh->tris[cur];
            for (int k = 0; k < 3; ++k) {
                const std::uint32_t nb = t.n[k];
                if (nb == kNoNeighbor || nb >= mesh->tris.size()) continue;
                if (mesh->tris[nb].blocked()) continue;
                const float nc[2] = {mesh->tris[nb].cx, mesh->tris[nb].cz};
                const float ng = cn.g + geom::dist(cc, nc);
                Node& nn = nodes[nb];
                if (nn.stamp != query || ng < nn.g) {
                    nn.g = ng; nn.from = cur; nn.stamp = query;
                    open.push({ng + geom::dist(nc, goalC), nb});
                }
            }
        }
        return false;
    }

    bool reconstruct(std::uint32_t start, std::uint32_t goal) {
        channel.clear();
        std::uint32_t cur = goal;
        std::uint64_t guard = 0;
        const std::uint64_t cap = mesh->tris.size() + 2;
        while (cur != kNoNeighbor && guard++ <= cap) {
            channel.push_back(cur);
            if (cur == start) break;
            cur = nodes[cur].from;
        }
        std::reverse(channel.begin(), channel.end());
        return !channel.empty() && channel.front() == start;
    }

    // Greedy string-pull over the corridor of shared-edge midpoints. Every emitted segment is
    // verified wall-free by losSegment, so the result stays inside the walkable corridor.
    void funnel(const float* start, const float* goal) {
        points.clear();
        std::vector<Point2> corridor;
        corridor.reserve(channel.size() + 2);
        corridor.push_back({start[0], start[1]});
        for (std::size_t i = 0; i + 1 < channel.size(); ++i) {
            float mid[2];
            sharedEdgeMid(*mesh, channel[i], channel[i + 1], mid);
            corridor.push_back({mid[0], mid[1]});
        }
        corridor.push_back({goal[0], goal[1]});

        points.push_back(corridor.front());
        std::size_t anchor = 0;
        std::size_t lastVisible = 0;
        for (std::size_t i = 1; i < corridor.size(); ++i) {
            if (losSegment(&points.back().x, &corridor[i].x)) {
                lastVisible = i;
                continue;
            }
            if (lastVisible <= anchor) lastVisible = i;  // corridor point itself; keep progress
            points.push_back(corridor[lastVisible]);
            anchor = lastVisible;
            i = lastVisible;  // continue scanning from the new anchor
        }
        if (points.back().x != corridor.back().x || points.back().z != corridor.back().z)
            points.push_back(corridor.back());
        // Drop exact duplicates.
        points.erase(std::unique(points.begin(), points.end(),
                                 [](const Point2& p, const Point2& q) { return p.x == q.x && p.z == q.z; }),
                     points.end());
    }
};

PathFinder* CreatePathFinderImpl() { return new PathFinderImpl(); }

}  // namespace PathLib
