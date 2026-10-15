#include "NavMesh.h"

#include <algorithm>
#include <limits>

namespace PathLib {

namespace {

// Little-endian sequential reader with hard bounds checking.  On overrun it flags itself
// bad and every subsequent read returns 0, so a truncated file yields an empty-but-valid
// mesh rather than a crash.
class Reader {
public:
    Reader(const std::uint8_t* p, std::size_t len) : p_(p), len_(len) {}
    bool ok() const { return ok_; }
    std::size_t pos() const { return off_; }

    std::uint16_t u16() {
        if (!have(2)) return 0;
        std::uint16_t v;
        std::memcpy(&v, p_ + off_, 2);
        off_ += 2;
        return v;
    }
    std::uint32_t u32() {
        if (!have(4)) return 0;
        std::uint32_t v;
        std::memcpy(&v, p_ + off_, 4);
        off_ += 4;
        return v;
    }
    std::uint8_t u8() {
        if (!have(1)) return 0;
        return p_[off_++];
    }
    float f32() {
        std::uint32_t bits = u32();
        float v;
        std::memcpy(&v, &bits, 4);
        return v;
    }
    // width-selected unsigned (2 or 4 bytes)
    std::uint32_t un(bool wide) { return wide ? u32() : (std::uint32_t)u16(); }

private:
    bool have(std::size_t n) {
        if (!ok_) return false;
        if (off_ + n > len_) {
            ok_ = false;
            return false;
        }
        return true;
    }
    const std::uint8_t* p_;
    std::size_t len_;
    std::size_t off_ = 0;
    bool ok_ = true;
};

// Hard caps: refuse to allocate for a header that is obviously corrupt.  Real maps top out
// around 34k verts / 70k tris; give generous headroom.
constexpr std::uint32_t kMaxVerts = 8u * 1000u * 1000u;
constexpr std::uint32_t kMaxTris = 8u * 1000u * 1000u;
constexpr std::uint32_t kMaxEdges = 16u * 1000u * 1000u;
constexpr std::uint64_t kMaxCells = 64u * 1000u * 1000u;
constexpr std::uint32_t kMaxCellList = 4u * 1000u * 1000u;

}  // namespace

void NavMesh::finalizeTri(Tri& t) {
    const float* a = &verts[t.v[0]].x;
    const float* b = &verts[t.v[1]].x;
    const float* c = &verts[t.v[2]].x;
    t.cx = (a[0] + b[0] + c[0]) / 3.0f;
    t.cz = (a[1] + b[1] + c[1]) / 3.0f;
    t.box[0] = std::min(a[0], std::min(b[0], c[0]));
    t.box[1] = std::min(a[1], std::min(b[1], c[1]));
    t.box[2] = std::max(a[0], std::max(b[0], c[0]));
    t.box[3] = std::max(a[1], std::max(b[1], c[1]));
}

bool NavMesh::parse(const void* data, std::size_t len) {
    clear();
    if (!data || len < 6) return false;
    const std::uint8_t* p = static_cast<const std::uint8_t*>(data);
    Reader r(p, len);

    version = r.u16();
    const bool wide = (version == 0x2000);
    if (version != 0x1000 && version != 0x2000) return false;

    // ---- vertices ----
    std::uint32_t nPts = r.un(wide);
    if (nPts > kMaxVerts) return false;
    verts.resize(nPts);
    for (std::uint32_t i = 0; i < nPts && r.ok(); ++i) {
        verts[i].x = r.f32();
        verts[i].z = r.f32();
    }
    if (!r.ok()) { clear(); return false; }

    // ---- triangles ----
    std::uint32_t nTri = r.un(wide);
    if (nTri > kMaxTris) { clear(); return false; }
    tris.resize(nTri);
    for (std::uint32_t i = 0; i < nTri && r.ok(); ++i) {
        Tri& t = tris[i];
        t.v[0] = r.un(wide);
        t.v[1] = r.un(wide);
        t.v[2] = r.un(wide);
        t.n[0] = r.un(wide);
        t.n[1] = r.un(wide);
        t.n[2] = r.un(wide);
        t.flag = r.u8();
        t.extra = r.un(wide);
    }
    if (!r.ok()) { clear(); return false; }

    // ---- constraint edges ----
    std::uint32_t nEdge = r.un(wide);
    if (nEdge > kMaxEdges) { clear(); return false; }
    edges.resize(nEdge);
    for (std::uint32_t i = 0; i < nEdge && r.ok(); ++i) {
        Edge& e = edges[i];
        e.a = r.un(wide);
        e.b = r.un(wide);
        e.t1 = r.un(wide);
        e.t2 = r.un(wide);
    }
    if (!r.ok()) { clear(); return false; }

    // ---- grid ----
    cellSize = r.u32();
    if (cellSize == 0) cellSize = 8;
    nx = wide ? r.u32() : (std::uint32_t)r.u16();
    nz = wide ? r.u32() : (std::uint32_t)r.u16();
    std::uint64_t nCells = (std::uint64_t)nx * nz;
    if (nCells > kMaxCells) { clear(); return false; }
    cells.resize((std::size_t)nCells);
    for (std::size_t i = 0; i < cells.size() && r.ok(); ++i) {
        std::uint32_t n1 = r.un(wide);
        std::uint32_t n2 = r.un(wide);
        if (n1 > kMaxCellList || n2 > kMaxCellList) { clear(); return false; }
        cells[i].tris.reserve(n1);
        for (std::uint32_t k = 0; k < n1 && r.ok(); ++k) {
            std::uint32_t v = r.un(wide);
            if (v < nTri) cells[i].tris.push_back(v);  // repair: drop bad idx
        }
        cells[i].edges.reserve(n2);
        for (std::uint32_t k = 0; k < n2 && r.ok(); ++k) {
            std::uint32_t v = r.un(wide);
            if (v < nEdge) cells[i].edges.push_back(v);
        }
    }
    if (!r.ok()) { clear(); return false; }

    // ---- validate references ----
    // Only the vertex indices that queries dereference *without* a bounds check are clamped
    // (pointInTri / finalizeTri index verts[] directly). Triangle-neighbour and edge-triangle
    // indices are left EXACTLY as stored (in v0x1000 files the no-neighbour sentinel is the
    // truncation (uint16_t)1000000 == 16960, i.e. simply an out-of-range index): every place
    // that follows a neighbour or edge-triangle index already rejects `>= tris.size()`, so the
    // raw values are safe and the parse stays byte-identical to the file.
    for (Tri& t : tris) {
        for (int k = 0; k < 3; ++k)
            if (t.v[k] >= verts.size()) t.v[k] = 0;  // clamp degenerate vertex ref
        finalizeTri(t);
    }
    for (Edge& e : edges) {
        if (e.a >= verts.size()) e.a = 0;
        if (e.b >= verts.size()) e.b = 0;
    }

    valid = true;
    return true;
}

}  // namespace PathLib
