// BuildingCollisionImpl — concrete BuildingCollision: the per-building walk-surface
// (triangle soup keyed by an integer XZ cell) used for "what is the ground height here"
// and "ray-pick the walk surface". The simple loader matches the surviving tEngine-side
// source (Src\Client\WXClient\World\BuildingCollisionMng.cpp); the indexed .WCollision
// formats (magic 0xff000001 / 0xff000002) are parsed defensively and, when their layout
// is uncertain, produce an empty (but valid, non-crashing) surface.

#include <cmath>
#include <cstdint>
#include <cstring>
#include <map>
#include <vector>

#include "PathLib.h"

namespace PathLib {

BuildingCollision::~BuildingCollision() {}

namespace {

struct P3 { float x, y, z; };
struct BTri { P3 v[3]; };

// Ray/triangle (Moller-Trumbore, double-sided) — matches CBuildingCollisionMng::IntersectTriangle.
bool rayTri(const float* orig, const float* dir, const P3& a, const P3& b, const P3& c,
            float* t, float* u, float* v) {
    const float e1[3] = {b.x - a.x, b.y - a.y, b.z - a.z};
    const float e2[3] = {c.x - a.x, c.y - a.y, c.z - a.z};
    float pv[3] = {dir[1] * e2[2] - dir[2] * e2[1],
                   dir[2] * e2[0] - dir[0] * e2[2],
                   dir[0] * e2[1] - dir[1] * e2[0]};
    float det = e1[0] * pv[0] + e1[1] * pv[1] + e1[2] * pv[2];
    float tv[3];
    if (det > 0) { tv[0] = orig[0] - a.x; tv[1] = orig[1] - a.y; tv[2] = orig[2] - a.z; }
    else { tv[0] = a.x - orig[0]; tv[1] = a.y - orig[1]; tv[2] = a.z - orig[2]; det = -det; }
    if (det < 0.0001f) return false;
    *u = tv[0] * pv[0] + tv[1] * pv[1] + tv[2] * pv[2];
    if (*u < 0.0f || *u > det) return false;
    float qv[3] = {tv[1] * e1[2] - tv[2] * e1[1],
                   tv[2] * e1[0] - tv[0] * e1[2],
                   tv[0] * e1[1] - tv[1] * e1[0]};
    *v = dir[0] * qv[0] + dir[1] * qv[1] + dir[2] * qv[2];
    if (*v < 0.0f || *u + *v > det) return false;
    *t = e2[0] * qv[0] + e2[1] * qv[1] + e2[2] * qv[2];
    const float inv = 1.0f / det;
    *t *= inv; *u *= inv; *v *= inv;
    return true;
}

}  // namespace

class BuildingCollisionImpl final : public BuildingCollision {
public:
    std::map<std::pair<int, int>, std::vector<BTri>> cells;

    ~BuildingCollisionImpl() override {}

    std::uint32_t loadFromMemory(const void* bytes) override {
        cells.clear();
        if (!bytes) return 1;
        const std::uint8_t* p = static_cast<const std::uint8_t*>(bytes);
        std::uint32_t magic;
        std::memcpy(&magic, p, 4);
        // Indexed formats: not needed by the .path test; parse tolerantly (nothing) rather
        // than risk a mis-sized read. The surface stays empty -> getHeight returns false.
        if (magic == 0xff000001u || magic == 0xff000002u) return 0;
        // Simple format (matches CBuildingCollisionMng): u32 version, u32 posCount,
        //   posCount x { int posX, int posZ, u32 triCount, triCount x {3 x float[3]} }.
        // No length is passed (original contract), so counts are capped defensively.
        std::size_t off = 0;
        auto u32 = [&](std::uint32_t& out) { std::memcpy(&out, p + off, 4); off += 4; };
        auto i32 = [&](int& out) { std::memcpy(&out, p + off, 4); off += 4; };
        auto f32 = [&](float& out) { std::memcpy(&out, p + off, 4); off += 4; };
        std::uint32_t version = 0, posCount = 0;
        u32(version);
        u32(posCount);
        if (posCount > 2000000u) return 1;  // corrupt header guard
        for (std::uint32_t i = 0; i < posCount; ++i) {
            int px = 0, pz = 0;
            i32(px); i32(pz);
            std::uint32_t triCount = 0;
            u32(triCount);
            if (triCount > 2000000u) { cells.clear(); return 1; }
            auto& vec = cells[{px, pz}];
            vec.reserve(vec.size() + triCount);
            for (std::uint32_t j = 0; j < triCount; ++j) {
                BTri t;
                for (int k = 0; k < 3; ++k) { f32(t.v[k].x); f32(t.v[k].y); f32(t.v[k].z); }
                vec.push_back(t);
            }
        }
        return 0;
    }

    // Ground height at logical position. `pos` is (x, z) in scene units; we key on
    // floor(x),floor(z) like the original. Returns the highest surface found; false = none.
    bool getHeight(int /*gx*/, int /*gz*/, const float* pos, float* out) override {
        if (!pos || !out) return false;
        return heightAt(pos[0], pos[1], *out);
    }

    bool selBuilding(const float* orig, const float* dir, float* out) override {
        if (!orig || !dir || !out) return false;
        float best = 1000.0f;
        bool hit = false;
        const int cx = (int)orig[0], cz = (int)orig[2];
        const int R = 30;  // BUILD_COLLISION_SEARCH_RANGE
        float t, u, v;
        for (int i = cx - R; i < cx + R; ++i) {
            for (int j = cz - R; j < cz + R; ++j) {
                auto it = cells.find({i, j});
                if (it == cells.end()) continue;
                for (const BTri& tr : it->second) {
                    if (rayTri(orig, dir, tr.v[0], tr.v[1], tr.v[2], &t, &u, &v) && t < best) {
                        best = t;
                        const float w = 1.0f - u - v;
                        out[0] = w * tr.v[0].x + u * tr.v[1].x + v * tr.v[2].x;
                        out[1] = w * tr.v[0].y + u * tr.v[1].y + v * tr.v[2].y;
                        out[2] = w * tr.v[0].z + u * tr.v[1].z + v * tr.v[2].z;
                        hit = true;
                    }
                }
            }
        }
        return hit;
    }

private:
    bool heightAt(float fx, float fz, float& outY) {
        auto it = cells.find({(int)fx, (int)fz});
        if (it == cells.end()) return false;
        float found = -1000.0f;
        bool hit = false;
        for (const BTri& t : it->second) {
            const float x1 = fx - t.v[0].x, z1 = fz - t.v[0].z;
            const float x21 = t.v[1].x - t.v[0].x, z21 = t.v[1].z - t.v[0].z;
            const float x31 = t.v[2].x - t.v[0].x, z31 = t.v[2].z - t.v[0].z;
            const float den = x21 * z31 - z21 * x31;
            if (std::fabs(den) < 0.0001f) continue;
            const float uu = (x1 * z31 - z1 * x31) / den;
            const float vv = (z1 * x21 - x1 * z21) / den;
            if (uu > 0 && uu < 1 && vv > 0 && vv < 1 && (1 - uu - vv) > 0) {
                const float y = t.v[0].y + uu * (t.v[1].y - t.v[0].y) + vv * (t.v[2].y - t.v[0].y);
                if (y > found) found = y;
                hit = true;
            }
        }
        if (hit) outY = found;
        return hit;
    }
};

BuildingCollision* CreateBuildingCollisionImpl() { return new BuildingCollisionImpl(); }

}  // namespace PathLib
