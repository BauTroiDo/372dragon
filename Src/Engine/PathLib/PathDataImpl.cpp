// PathDataImpl — concrete PathData: owns one parsed NavMesh and answers the mesh queries.
// Only slot 3 (parseBuffer) is reached at runtime by Render.dll; the rest back the
// edit-time / internal helpers and are implemented for completeness and safety.

#include <cstdio>
#include <string>
#include <vector>

#include "NavMesh.h"
#include "PathLib.h"

namespace PathLib {

// Pure-virtual dtor bodies (needed so the base vtables link and export cleanly).
PathData::~PathData() {}

class PathDataImpl final : public PathData {
public:
    NavMesh mesh;
    std::string base;

    ~PathDataImpl() override {}

    bool loadRegionFile(const char* /*baseName*/) override {
        // Edit-time path (build a mesh from <name>.region + <name>.terrain via a constrained
        // Delaunay triangulation). The runtime client never calls this; report failure
        // rather than pull in a triangulator.
        return false;
    }

    bool writePath(const char* path) override { return writeBinary(path); }

    void parseBuffer(const void* bytes) override {
        // Contract: `bytes` points at a whole .path image; length is unknown here (the
        // original trusted the header). We parse with an effectively-unbounded length but
        // the reader caps counts and validates indices, so corrupt data yields an empty
        // mesh instead of a crash.
        mesh.parse(bytes, static_cast<std::size_t>(-1));
    }

    void loadPathFile(const char* path) override {
        std::vector<std::uint8_t> buf;
        if (readFile(path, buf)) mesh.parse(buf.data(), buf.size());
    }

    void writeXml(const char* /*path*/) override {}

    void clear() override { mesh.clear(); }

    const void* gridCell(int gx, int gz) const override { return mesh.cellAt(gx, gz); }

    void worldToGrid(int* out2, float x, float z) const override {
        int gx = 0, gz = 0;
        mesh.worldToGrid(x, z, gx, gz);
        if (out2) { out2[0] = gx; out2[1] = gz; }
    }

    bool isValidGrid(int gx, int gz) const override {
        return gx >= 0 && gz >= 0 && (std::uint32_t)gx < mesh.nx && (std::uint32_t)gz < mesh.nz;
    }



    bool segmentHitsBlockedTri(const float* a, const float* b, float* hitA, float* hitB,
                               char blocked) const override {
        int gx, gz;
        mesh.worldToGrid(a[0], a[1], gx, gz);
        const Cell* c = mesh.cellAt(gx, gz);
        if (!c) return false;
        float tmp[2];
        for (std::uint32_t ti : c->tris) {
            if (ti >= mesh.tris.size()) continue;
            const Tri& t = mesh.tris[ti];
            if ((char)(t.flag & 1) != blocked) continue;
            const float* v0 = &mesh.verts[t.v[0]].x;
            const float* v1 = &mesh.verts[t.v[1]].x;
            const float* v2 = &mesh.verts[t.v[2]].x;
            if (geom::segSeg(a, b, v0, v1, tmp) || geom::segSeg(a, b, v1, v2, tmp) ||
                geom::segSeg(a, b, v0, v2, tmp)) {
                if (hitA) { hitA[0] = tmp[0]; hitA[1] = tmp[1]; }
                if (hitB) { hitB[0] = tmp[0]; hitB[1] = tmp[1]; }
                return true;
            }
        }
        return false;
    }



    bool segmentHitsConstraintEdge(const float* a, const float* b, float* hitA,
                                   float* hitB) const override {
        int gx, gz;
        mesh.worldToGrid(a[0], a[1], gx, gz);
        const Cell* c = mesh.cellAt(gx, gz);
        if (!c) return false;
        float tmp[2];
        for (std::uint32_t ei : c->edges) {
            if (ei >= mesh.edges.size()) continue;
            const Edge& e = mesh.edges[ei];
            const float* va = &mesh.verts[e.a].x;
            const float* vb = &mesh.verts[e.b].x;
            if (geom::segSeg(a, b, va, vb, tmp)) {
                if (hitA) { hitA[0] = tmp[0]; hitA[1] = tmp[1]; }
                if (hitB) { hitB[0] = tmp[0]; hitB[1] = tmp[1]; }
                return true;
            }
        }
        return false;
    }

    const void* self() const override { return this; }

    const void* edge(std::intptr_t i) const override {
        return (i >= 0 && (std::size_t)i < mesh.edges.size()) ? &mesh.edges[(std::size_t)i] : nullptr;
    }
    const void* triangle(std::intptr_t i) const override {
        return (i >= 0 && (std::size_t)i < mesh.tris.size()) ? &mesh.tris[(std::size_t)i] : nullptr;
    }
    const float* vertex(std::intptr_t i) const override {
        return (i >= 0 && (std::size_t)i < mesh.verts.size()) ? &mesh.verts[(std::size_t)i].x : nullptr;
    }
    std::intptr_t vertexCount() const override { return (std::intptr_t)mesh.verts.size(); }
    std::intptr_t triangleCount() const override { return (std::intptr_t)mesh.tris.size(); }

private:
    static bool readFile(const char* path, std::vector<std::uint8_t>& out) {
        if (!path) return false;
        std::FILE* f = std::fopen(path, "rb");
        if (!f) return false;
        std::fseek(f, 0, SEEK_END);
        long n = std::ftell(f);
        std::fseek(f, 0, SEEK_SET);
        bool ok = false;
        if (n > 0) {
            out.resize((std::size_t)n);
            ok = std::fread(out.data(), 1, (std::size_t)n, f) == (std::size_t)n;
        }
        std::fclose(f);
        return ok;
    }

    bool writeBinary(const char* path) {
        if (!path || !mesh.valid) return false;
        std::FILE* f = std::fopen(path, "wb");
        if (!f) return false;
        const bool wide = mesh.version != 0x1000;
        auto wu16 = [&](std::uint16_t v) { std::fwrite(&v, 2, 1, f); };
        auto wu32 = [&](std::uint32_t v) { std::fwrite(&v, 4, 1, f); };
        auto wn = [&](std::uint32_t v) { if (wide) wu32(v); else wu16((std::uint16_t)v); };
        auto wf = [&](float v) { std::fwrite(&v, 4, 1, f); };
        wu16(mesh.version ? mesh.version : 0x2000);
        wn((std::uint32_t)mesh.verts.size());
        for (const Point2& p : mesh.verts) { wf(p.x); wf(p.z); }
        wn((std::uint32_t)mesh.tris.size());
        for (const Tri& t : mesh.tris) {
            wn(t.v[0]); wn(t.v[1]); wn(t.v[2]);
            wn(t.n[0]); wn(t.n[1]); wn(t.n[2]);
            std::fwrite(&t.flag, 1, 1, f);
            wn(t.extra);
        }
        wn((std::uint32_t)mesh.edges.size());
        for (const Edge& e : mesh.edges) { wn(e.a); wn(e.b); wn(e.t1); wn(e.t2); }
        wu32(mesh.cellSize);
        if (wide) { wu32(mesh.nx); wu32(mesh.nz); } else { wu16((std::uint16_t)mesh.nx); wu16((std::uint16_t)mesh.nz); }
        for (const Cell& c : mesh.cells) {
            wn((std::uint32_t)c.tris.size());
            wn((std::uint32_t)c.edges.size());
            for (std::uint32_t v : c.tris) wn(v);
            for (std::uint32_t v : c.edges) wn(v);
        }
        std::fclose(f);
        return true;
    }
};

// Factory hook used by PathLibRoot (defined in PathLibRoot.cpp).
PathData* CreatePathDataImpl() { return new PathDataImpl(); }
NavMesh* MeshOf(PathData* pd) { return pd ? &static_cast<PathDataImpl*>(pd)->mesh : nullptr; }

// CYS: length-checked parse (see PathLib.h).
bool ParsePathImage(PathData* pd, const void* bytes, std::size_t len) {
    NavMesh* m = MeshOf(pd);
    if (!m) return false;
    if (!bytes || len == 0) { m->clear(); return false; }
    return m->parse(bytes, len);
}

}  // namespace PathLib
