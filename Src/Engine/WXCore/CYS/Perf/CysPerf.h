// CYS-PERF (CY-Source): frame collector for Game.exe and TlbbViewer.
//
// Enabled by the environment variable CYS_PERF=1 (nothing is installed otherwise). Options:
//   CYS_PERF_INTERVAL=<s>   seconds between log lines (default 2)
//   CYS_PERF_CSV=<path>     one row per frame (phases, GPU times, counters) plus "#mark" rows
//   CYS_PERF_GPU=0          no D3D9 timestamp queries
//   CYS_PERF_ALLOC=0        no heap allocation counting (CRT heap import hooks of the engine modules)
//   CYS_PERF_OVERLAY=1|2    draw the last log line on screen (2 = double size)
//   CYS_PERF_LISTENERS=0    no per frame listener timing
// Output: "CYS-PERF ..." lines in the OGRE log (WXRender.log for Game.exe), a summary at shutdown.
#ifndef __CysPerf_H__
#define __CysPerf_H__

namespace Ogre
{
    class Root;
    class RenderWindow;
    class SceneManager;
}

namespace CYS
{
namespace Perf
{
    /// Installs the collector when CYS_PERF is set. Called by WX::System::setup once the window, the scene
    /// manager and the viewport exist. A second call is ignored.
    void install(Ogre::Root* root, Ogre::RenderWindow* window, Ogre::SceneManager* sceneManager);

    /// Writes the run summary, closes the CSV and releases the GPU queries. Called by WX::System before OGRE
    /// shuts down. No-op when nothing is installed.
    void shutdown(void);

    /// Records a named event in the log and the CSV (no-op when not installed).
    void mark(const char* label);

    /// True while a collector is installed.
    bool installed(void);
}
}

#endif
