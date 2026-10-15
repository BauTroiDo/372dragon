// PathLib.h — public interface of PathLib.dll (clean-room reimplementation).
//
// PathLib.dll has NO surviving source. This interface was recovered as a *specification*
// (Docs 04 §8) from three sources, cross-checked:
//   1. the export table of client_GL\Bin64\PathLib.dll (variant A, x64, the build the
//      modern client's Render.dll links against — this is our ABI target);
//   2. how Render.dll wraps and calls the 6 imported factory functions and the returned
//      objects' virtual methods (analysis\ghidra + Build\re\pathlib\out\render_*);
//   3. the decompiled bodies in analysis\ghidra\pathlib-out\all.c.
// No decompiled code is pasted; every method is re-derived from the observed contract.
//
// ABI contract that MUST hold for a drop-in replacement (verified: consumers never read
// object fields directly — they only call the factory and the objects' virtuals):
//   * the 24 exported mangled names (see pathlib.def — union of variant A and B name sets);
//   * PathLibRoot::get{PathData,PathFinder,BuildingCollsion}() return a heap object whose
//     vtable slots appear in the exact order below (variant A: PathData 18 slots,
//     PathFinder 20 slots, BuildingCollision 5 slots on the concrete class);
//   * PathLibRoot::destroy*() delete such an object.
//
// The classes below are ABSTRACT interfaces (all-pure vtables, matching the exported
// ??_7*@PathLib@@6B@ vtable symbols). The concrete *Impl classes live in PathLibImpl.h.

#ifndef CYS_PATHLIB_H
#define CYS_PATHLIB_H

#pragma once

#include <cstddef>
#include <cstdint>

// Export decoration. When building PathLib.dll we emit the exact MSVC-mangled names the
// consumers import (matching signatures + the PathLib::PathLibRoot enclosing scope yields
// the identical decorated names, e.g. ?getPathData@PathLibRoot@PathLib@@QEAAPEAVPathData@2@XZ).
#if defined(PATHLIB_EXPORTS)
#define PATHLIB_API __declspec(dllexport)
#else
#define PATHLIB_API
#endif

namespace PathLib {

// A 2-D point in scene "cell" units (the same units the .path file stores; Y/height is
// handled separately by BuildingCollision and the terrain heightmap).
struct Point2 {
    float x;
    float z;
};

// ---- PathData : an immutable, loaded navigation mesh (one .path file) ---------------
//
// Slot order (variant A vtable ??_7PathData@PathLib@@6B@, 18 slots):
//   0  virtual dtor (scalar-deleting)
//   1  loadRegionFile(baseName)          build mesh from <name>.region + <name>.terrain
//   2  writePath(path)                   serialize current mesh to a .path file
//   3  parseBuffer(bytes)                parse an in-memory .path image  <-- Render uses this
//   4  loadPathFile(path)                open a .path file and parseBuffer it
//   5  writeXml(path)                    debug dump
//   6  clear()
//   7  gridCell(gx,gz)                   -> const GridCell*
//   8  worldToGrid(out,x,z)              -> Point-as-int grid coords
//   9  isValidGrid(gx,gz)               -> bool
//   10 segmentHitsBlockedTri(a,b,c,d,blocked) test seg(ab) vs triangles in the cell
//   11 segmentHitsConstraintEdge(a,b,c,d)     test seg(ab) vs constraint edges in the cell
//   12 self()                           -> opaque (returns this+region-string; unused by us)
//   13 edge(i)                          -> const Edge*
//   14 triangle(i)                      -> const Triangle*
//   15 vertex(i)                        -> const Point2*
//   16 vertexCount()
//   17 triangleCount()
class PathData {
public:
    virtual ~PathData() = 0;
    virtual bool loadRegionFile(const char* baseName) = 0;                    // 1
    virtual bool writePath(const char* path) = 0;                             // 2
    virtual void parseBuffer(const void* bytes) = 0;                          // 3
    virtual void loadPathFile(const char* path) = 0;                          // 4
    virtual void writeXml(const char* path) = 0;                              // 5
    virtual void clear() = 0;                                                 // 6
    virtual const void* gridCell(int gx, int gz) const = 0;                   // 7
    virtual void worldToGrid(int* out2, float x, float z) const = 0;          // 8
    virtual bool isValidGrid(int gx, int gz) const = 0;                       // 9
    virtual bool segmentHitsBlockedTri(const float* a, const float* b,
                                       float* hitA, float* hitB, char blocked) const = 0; // 10
    virtual bool segmentHitsConstraintEdge(const float* a, const float* b,
                                           float* hitA, float* hitB) const = 0;           // 11
    virtual const void* self() const = 0;                                     // 12
    virtual const void* edge(std::intptr_t i) const = 0;                      // 13
    virtual const void* triangle(std::intptr_t i) const = 0;                  // 14
    virtual const float* vertex(std::intptr_t i) const = 0;                   // 15
    virtual std::intptr_t vertexCount() const = 0;                            // 16
    virtual std::intptr_t triangleCount() const = 0;                          // 17
};

// ---- PathFinder : an A* path query engine bound to one PathData ---------------------
//
// Slot order (variant A vtable ??_7PathFinder@PathLib@@6B@, 20 slots). Render invokes
// slots 1,2,3,5,6,7,8,9,10,12. The remaining slots are edit-time / rarely-used variants;
// they are implemented defensively.
//   0  virtual dtor
//   1  init(pathData)                    bind mesh, allocate node array
//   2  reset()                           clear per-query & dynamic-obstacle state
//   3  findPath(sx,sz,gx,gz)             run A* + funnel; result in the point list
//   4  moveAlong(...)                    "walk as far as possible + slide along wall"
//   5  findNearestReachable(sx,sz,gx,gz) A* to nearest reachable cell of the goal region
//   6  raycastWalkable(out,sx,sz,gx,gz,blocked) first blocked crossing along a segment
//   7  pointCount()
//   8  point(out2,i)
//   9  regionRoot()                      -> opaque region tree root
//   10 addBlockPolygon(pts,n,tag)        insert a dynamic obstacle polygon
//   11 removeBlockPolygon(...)           (edit-time)
//   12 lineOfSight(out,sx,sz,gx,gz)      straight-line walkability
//   13..19 construction/query variants (defensive)
class PathFinder {
public:
    virtual ~PathFinder() = 0;
    virtual void init(PathData* pd) = 0;                                       // 1
    virtual void reset() = 0;                                                  // 2
    virtual bool findPath(const float* start, const float* goal, float* outFirst) = 0; // 3
    virtual bool moveAlong(float sx, float sz, const void* goalHint,
                           float gx, float gz, float* outPos, float* outDir) = 0;       // 4
    virtual bool findNearestReachable(const float* start, const float* goal) = 0;       // 5
    virtual bool raycastWalkable(float px, float pz, float* out, void* outCell, char blocked) = 0; // 6
    virtual std::intptr_t pointCount() const = 0;                              // 7
    virtual const float* point(std::intptr_t i) const = 0;                     // 8
    virtual const void* regionRoot() const = 0;                                // 9
    virtual bool addBlockPolygon(const float* pts, int n, void* tag) = 0;      // 10
    virtual bool removeBlockPolygon(void* tag) = 0;                            // 11
    virtual bool lineOfSight(const float* start, const float* goal, void* scratch) = 0; // 12
    virtual bool slot13(void*) = 0;
    virtual bool slot14(void*) = 0;
    virtual bool slot15(void*) = 0;
    virtual bool slot16(void*) = 0;
    virtual bool slot17(void*) = 0;
    virtual bool slot18(void*) = 0;
    virtual bool slot19(void*) = 0;
};

// ---- BuildingCollision : per-building walk-surface (height + ray pick) --------------
//
// Same on-disk format as the tEngine-side CBuildingCollisionMng (0.85 source survives in
// Src\Client\WXClient\World\BuildingCollisionMng.*), re-implemented here as the DLL slot.
//   0  virtual dtor
//   1  loadFromMemory(bytes)             parse the pos->triangle-list map
//   2  getHeight(out,pos,q)              vertical query -> surface height
//   3  selBuilding(out,orig,dir,...)     ray pick against the walk surface
//   4  loadV2(...)                       alternate loader (defensive)
class BuildingCollision {
public:
    virtual ~BuildingCollision();  // concrete: base slot 0 is a real (non-pure) dtor
    virtual std::uint32_t loadFromMemory(const void* bytes) = 0;   // 1
    virtual bool getHeight(int gx, int gz, const float* pos, float* out) = 0; // 2
    virtual bool selBuilding(const float* orig, const float* dir, float* out) = 0; // 3
};

// ---- PathLibRoot : the object factory (the imported exports live here) --------------
// We export the UNION of variant A (client_GL, Render.dll consumer) and variant B
// (Reference Game.exe consumer) name sets, so one built DLL is a drop-in for either:
//   A imports: destroyBuildingCollision, destroyPathFinderInfo, destroyPathData,
//              getBuildingCollsion, getPathFinder, getPathData
//   B imports: destroyBuildingCollision, destroyPathFinder,     destroyPathData,
//              getBuildingCollsion, getPathFinder, getPathData
// (getBuildingCollsion keeps the original's misspelling on purpose — it is the imported name.)
class PATHLIB_API PathLibRoot {
public:
    void destroyBuildingCollision(BuildingCollision* p);
    static void destroyBuildingWalkGeometry(BuildingCollision* p);  // A only
    void destroyPathData(PathData* p);
    void destroyPathFinderInfo(PathFinder* p);   // A name
    void destroyPathFinder(PathFinder* p);       // B name (same behaviour)
    BuildingCollision* getBuildingCollsion();
    PathData* getPathData();
    PathFinder* getPathFinder();
    static BuildingCollision* newBuildingWalkGeometry();  // A only
};

// CYS: bounded parse for callers that hold a whole .path image in memory together with its
// length (the client's resource provider returns buffer + size). Not part of the original ABI:
// one extra export, harmless to Render.dll / Game.exe consumers. Returns the mesh validity.
PATHLIB_API bool ParsePathImage(PathData* pd, const void* bytes, std::size_t len);

}  // namespace PathLib

#endif  // CYS_PATHLIB_H
