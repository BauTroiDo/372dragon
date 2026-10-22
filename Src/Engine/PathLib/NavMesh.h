

















#ifndef CYS_PATHLIB_NAVMESH_H
#define CYS_PATHLIB_NAVMESH_H

#pragma once

#include <cstdint>
#include <cstring>
#include <vector>

#include "Geometry.h"
#include "PathLib.h"  // for PathLib::Point2

namespace PathLib {

constexpr std::uint32_t kNoNeighbor = 1000000u;

struct Tri {
    std::uint32_t v[3];
    std::uint32_t n[3];   // adjacent tri per edge (v0v1, v1v2, v2v0), or kNoNeighbor
    std::uint8_t flag;    // bit0 = blocked
    std::uint32_t extra;  // region id
    float cx, cz;         // centroid
    float box[4];         // minx, minz, maxx, maxz
    bool blocked() const { return (flag & 1u) != 0u; }
};

struct Edge {
    std::uint32_t a, b;   // vertex indices
    std::uint32_t t1, t2; // blocked-side tri, walkable-side tri (kNoNeighbor allowed)
};

struct Cell {
    std::vector<std::uint32_t> tris;
    std::vector<std::uint32_t> edges;
};

class NavMesh {
public:
    std::uint16_t version = 0;
    std::vector<Point2> verts;
    std::vector<Tri> tris;
    std::vector<Edge> edges;
    std::uint32_t cellSize = 8;
    std::uint32_t nx = 0, nz = 0;
    std::vector<Cell> cells;
    bool valid = false;

    void clear() {
        version = 0;
        verts.clear();
        tris.clear();
        edges.clear();
        cells.clear();
        cellSize = 8;
        nx = nz = 0;
        valid = false;
    }

    // Parse from a raw buffer.  `len` is the trusted byte length; pass SIZE_MAX only when the
    // caller genuinely does not know it (matches the original slot-3 contract) — counts are
    // still capped to sane maxima so a corrupt header cannot force a wild allocation.
    bool parse(const void* data, std::size_t len);

    const Cell* cellAt(int gx, int gz) const {
        if (gx < 0 || gz < 0 || (std::uint32_t)gx >= nx || (std::uint32_t)gz >= nz) return nullptr;
        std::size_t idx = (std::size_t)gz * nx + (std::uint32_t)gx;
        return idx < cells.size() ? &cells[idx] : nullptr;
    }

    void worldToGrid(float x, float z, int& gx, int& gz) const {
        const float cs = cellSize > 0 ? (float)cellSize : 1.0f;
        gx = x < 0.0f ? 0 : (int)(x / cs);
        gz = z < 0.0f ? 0 : (int)(z / cs);
    }

    // Triangle containing (x,z), searched via the grid; kNoNeighbor if none.
    std::uint32_t findTri(float x, float z) const {
        int gx, gz;
        worldToGrid(x, z, gx, gz);
        const Cell* c = cellAt(gx, gz);
        if (c) {
            for (std::uint32_t ti : c->tris) {
                if (ti < tris.size() && triContains(ti, x, z)) return ti;
            }
        }
        return kNoNeighbor;
    }

    bool triContains(std::uint32_t ti, float x, float z) const {
        const Tri& t = tris[ti];
        return geom::pointInTri(x, z, &verts[t.v[0]].x, &verts[t.v[1]].x, &verts[t.v[2]].x);
    }

private:
    void finalizeTri(Tri& t);
};

}  // namespace PathLib

#endif  // CYS_PATHLIB_NAVMESH_H
