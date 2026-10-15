// CYS-PERF (CY-Source): storage of the frame instrumentation block (see OgreCysPerf.h).
#ifndef WIN32_LEAN_AND_MEAN
#   define WIN32_LEAN_AND_MEAN
#endif
#ifndef NOMINMAX
#   define NOMINMAX
#endif
#include <windows.h>

#include "OgreCysPerf.h"

namespace Ogre
{
namespace CysPerf
{
    Block gBlock = { 0, BLOCK_VERSION };

    long long ticks(void)
    {
        LARGE_INTEGER t;
        QueryPerformanceCounter(&t);
        return t.QuadPart;
    }

    long long ticksPerSecond(void)
    {
        static long long frequency = 0;
        if (!frequency)
        {
            LARGE_INTEGER f;
            QueryPerformanceFrequency(&f);
            frequency = f.QuadPart;
        }
        return frequency;
    }
}
}

extern "C" Ogre::CysPerf::Block* CysPerfBlock(void)
{
    return &Ogre::CysPerf::gBlock;
}
