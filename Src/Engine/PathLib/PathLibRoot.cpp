// PathLibRoot — the exported object factory. These methods carry the exact mangled names
// the consumers import (guaranteed by matching the PathLib::PathLibRoot signatures under
// PATHLIB_EXPORTS). Objects are created here and destroyed through their virtual dtor, so
// the concrete *Impl types never need to be visible to callers.

#include "PathLib.h"

#if defined(_WIN32)
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#endif

namespace PathLib {

// Concrete factory hooks (defined in the *Impl.cpp translation units).
PathData* CreatePathDataImpl();
PathFinder* CreatePathFinderImpl();
BuildingCollision* CreateBuildingCollisionImpl();

void PathLibRoot::destroyBuildingCollision(BuildingCollision* p) { delete p; }
void PathLibRoot::destroyBuildingWalkGeometry(BuildingCollision* p) { delete p; }
void PathLibRoot::destroyPathData(PathData* p) { delete p; }
void PathLibRoot::destroyPathFinderInfo(PathFinder* p) { delete p; }
void PathLibRoot::destroyPathFinder(PathFinder* p) { delete p; }

BuildingCollision* PathLibRoot::getBuildingCollsion() { return CreateBuildingCollisionImpl(); }
PathData* PathLibRoot::getPathData() { return CreatePathDataImpl(); }
PathFinder* PathLibRoot::getPathFinder() { return CreatePathFinderImpl(); }
BuildingCollision* PathLibRoot::newBuildingWalkGeometry() { return CreateBuildingCollisionImpl(); }

}  // namespace PathLib

#if defined(_WIN32)
BOOL WINAPI DllMain(HINSTANCE inst, DWORD reason, LPVOID) {
    if (reason == DLL_PROCESS_ATTACH) DisableThreadLibraryCalls(inst);
    return TRUE;
}
#endif
