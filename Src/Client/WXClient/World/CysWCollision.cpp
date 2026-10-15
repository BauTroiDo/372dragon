// CysWCollision.cpp — CYS-NAV: xem CysWCollision.h.

#include "CysWCollision.h"

#include <cmath>
#include <cstdio>
#include <cstring>
#include <set>

namespace cys {

namespace {

struct Reader {
    const unsigned char* p;
    std::size_t n;
    std::size_t o;
    bool bad;
    bool need(std::size_t k) {
        if (bad || o + k > n) { bad = true; return false; }
        return true;
    }
    unsigned u32() { unsigned v = 0; if (need(4)) { std::memcpy(&v, p + o, 4); o += 4; } return v; }
    int i32() { int v = 0; if (need(4)) { std::memcpy(&v, p + o, 4); o += 4; } return v; }
    unsigned u16() { unsigned short v = 0; if (need(2)) { std::memcpy(&v, p + o, 2); o += 2; } return v; }
    float f32() { float v = 0; if (need(4)) { std::memcpy(&v, p + o, 4); o += 4; } return v; }
};

bool finiteTri(const WCollTri& t) {
    for (int i = 0; i < 9; ++i) {
        if (!(t.v[i] == t.v[i]) || std::fabs(t.v[i]) > 1.0e6f) return false;
    }
    return true;
}

}  // namespace

bool IsCyWCollisionMagic(const unsigned char* data, std::size_t size) {
    if (!data || size < 4) return false;
    unsigned m = 0;
    std::memcpy(&m, data, 4);
    return m == 0xff000001u || m == 0xff000002u;
}

bool ParseCyWCollision(const unsigned char* data, std::size_t size, std::vector<WCollTri>& out, WCollStats& st) {
    out.clear();
    st = WCollStats();
    st.size = size;
    if (!IsCyWCollisionMagic(data, size)) return false;
    Reader rd = {data, size, 0, false};
    st.magic = rd.u32();
    if (st.magic == 0xff000001u) {
        std::set<std::string> seen;
        st.cells = rd.u32();
        for (unsigned i = 0; i < st.cells && !rd.bad; ++i) {
            rd.i32();
            rd.i32();
            const unsigned k = rd.u32();
            if (!rd.need((std::size_t)k * 36)) break;
            for (unsigned j = 0; j < k; ++j) {
                WCollTri t;
                std::memcpy(t.v, data + rd.o, 36);
                std::string key((const char*)(data + rd.o), 36);
                rd.o += 36;
                ++st.trisRead;
                if (finiteTri(t) && seen.insert(key).second) out.push_back(t);
            }
        }
    } else {
        struct Mesh { std::vector<float> v; std::vector<unsigned short> idx; };
        st.meshes = rd.u16();
        std::vector<Mesh> meshes(st.meshes);
        for (unsigned m = 0; m < st.meshes && !rd.bad; ++m) {
            const unsigned nv = rd.u16();
            if (!rd.need((std::size_t)nv * 12)) break;
            meshes[m].v.resize((std::size_t)nv * 3);
            if (nv) std::memcpy(&meshes[m].v[0], data + rd.o, (std::size_t)nv * 12);
            rd.o += (std::size_t)nv * 12;
            const unsigned nt = rd.u16();
            if (!rd.need((std::size_t)nt * 6)) break;
            meshes[m].idx.resize((std::size_t)nt * 3);
            if (nt) std::memcpy(&meshes[m].idx[0], data + rd.o, (std::size_t)nt * 6);
            rd.o += (std::size_t)nt * 6;
        }
        float offs[3], scl[3];
        for (int k = 0; k < 3; ++k) offs[k] = rd.f32();
        for (int k = 0; k < 3; ++k) scl[k] = rd.f32();
        for (int k = 0; k < 3; ++k) if (scl[k] == 0.0f) scl[k] = 1.0f;
        st.instances = rd.u16();
        for (unsigned i = 0; i < st.instances && !rd.bad; ++i) {
            float s[3], t[3], q[4];
            for (int k = 0; k < 3; ++k) s[k] = rd.f32();
            for (int k = 0; k < 3; ++k) t[k] = rd.f32();
            for (int k = 0; k < 4; ++k) q[k] = rd.f32();
            const unsigned mi = rd.u16();
            if (rd.bad || mi >= meshes.size()) continue;
            // Ogre::Quaternion::ToRotationMatrix, q = (w, x, y, z)
            const float w = q[0], x = q[1], y = q[2], z = q[3];
            const float tx = 2 * x, ty = 2 * y, tz = 2 * z;
            const float twx = tx * w, twy = ty * w, twz = tz * w;
            const float txx = tx * x, txy = ty * x, txz = tz * x;
            const float tyy = ty * y, tyz = tz * y, tzz = tz * z;
            const float r[3][3] = {{1 - (tyy + tzz), txy - twz, txz + twy},
                                   {txy + twz, 1 - (txx + tzz), tyz - twx},
                                   {txz - twy, tyz + twx, 1 - (txx + tyy)}};
            const Mesh& mesh = meshes[mi];
            const std::size_t nv = mesh.v.size() / 3;
            std::vector<float> tv(nv * 3);
            for (std::size_t k = 0; k < nv; ++k) {
                const float sx = mesh.v[k * 3] * s[0], sy = mesh.v[k * 3 + 1] * s[1], sz = mesh.v[k * 3 + 2] * s[2];
                for (int a = 0; a < 3; ++a) {
                    tv[k * 3 + a] = (r[a][0] * sx + r[a][1] * sy + r[a][2] * sz + t[a] - offs[a]) / scl[a];
                }
            }
            for (std::size_t k = 0; k + 2 < mesh.idx.size(); k += 3) {
                const unsigned a = mesh.idx[k], b = mesh.idx[k + 1], c = mesh.idx[k + 2];
                if (a >= nv || b >= nv || c >= nv) continue;
                WCollTri tri;
                for (int e = 0; e < 3; ++e) {
                    tri.v[e] = tv[a * 3 + e];
                    tri.v[3 + e] = tv[b * 3 + e];
                    tri.v[6 + e] = tv[c * 3 + e];
                }
                ++st.trisRead;
                if (finiteTri(tri)) out.push_back(tri);
            }
        }
    }
    st.parsed = rd.o;
    st.truncated = rd.bad;
    st.trisUnique = (unsigned)out.size();
    bool first = true;
    for (const WCollTri& t : out) {
        for (int e = 0; e < 3; ++e) {
            const float yy = t.v[3 * e + 1];
            if (first) { st.minY = st.maxY = yy; first = false; }
            if (yy < st.minY) st.minY = yy;
            if (yy > st.maxY) st.maxY = yy;
        }
    }
    return !rd.bad;
}

std::string DescribeWCollision(const WCollStats& st) {
    char buf[256];
    std::snprintf(buf, sizeof(buf),
                  "magic=0x%08x meshes=%u instances=%u cells=%u tris=%u unique=%u y=[%.2f,%.2f] parsed=%u/%u%s", st.magic,
                  st.meshes, st.instances, st.cells, st.trisRead, st.trisUnique, st.minY, st.maxY, (unsigned)st.parsed,
                  (unsigned)st.size, st.truncated ? " TRUNCATED" : "");
    return buf;
}

bool WCollTopHeight(const std::vector<WCollTri>& tris, float x, float z, float& y) {
    bool hit = false;
    float best = 0;
    for (const WCollTri& t : tris) {
        const float ax = t.v[0], ay = t.v[1], az = t.v[2];
        const float x21 = t.v[3] - ax, z21 = t.v[5] - az, x31 = t.v[6] - ax, z31 = t.v[8] - az;
        const float den = x21 * z31 - z21 * x31;
        if (std::fabs(den) < 0.0001f) continue;
        const float x1 = x - ax, z1 = z - az;
        const float u = (x1 * z31 - z1 * x31) / den;
        const float v = (z1 * x21 - x1 * z21) / den;
        const float eps = -0.00001f;
        if (u >= eps && v >= eps && 1 - u - v >= eps) {
            const float h = ay + u * (t.v[4] - ay) + v * (t.v[7] - ay);
            if (!hit || h > best) { best = h; hit = true; }
        }
    }
    if (hit) y = best;
    return hit;
}

}  // namespace cys
