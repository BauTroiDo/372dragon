/*
-----------------------------------------------------------------------------
CYS-PERF (CY-Source): frame instrumentation shared by OgreMain, the D3D9 render system, the CEGUI renderer,
the WXCore collector (Src/Engine/WXCore/CYS/Perf) and Game.exe (through the C entry point CysPerfBlock()).

Every hook is a no-op until a collector sets gBlock.enabled (environment variable CYS_PERF=1), so normal runs
pay one predictable branch per call site. Phases accumulate QueryPerformanceCounter ticks and counters
accumulate events between two frame boundaries (Root::_fireFrameStarted); the collector harvests and clears
them at every boundary.

This header is standalone on purpose (no OGRE includes): Game.exe does not link OgreMain and includes it only
for the layout, with CYS_PERF_NO_IMPORT defined, then resolves CysPerfBlock() with GetProcAddress.
-----------------------------------------------------------------------------
*/
#ifndef __OgreCysPerf_H__
#define __OgreCysPerf_H__

#if defined(OGRE_NONCLIENT_BUILD)
#   define CYS_PERF_API __declspec(dllexport)
#elif defined(CYS_PERF_NO_IMPORT)
#   define CYS_PERF_API
#else
#   define CYS_PERF_API __declspec(dllimport)
#endif

namespace Ogre
{
namespace CysPerf
{
    /// CPU phases. "nested" phases are also counted inside their parent.
    enum Phase
    {
        // Game.exe main loop (CGameProcedure)
        PH_GAME_MSG = 0,    ///< Windows message pump
        PH_GAME_WAIT,       ///< idle wait for the frame pacer / next message
        PH_GAME_TICK,       ///< TickActive: the whole logic tick (parent of the tick phases below)
        PH_GAME_INPUT,      ///< input system tick (nested in TICK)
        PH_GAME_UI,         ///< UI system tick: CEGUI time pulse and UI Lua (nested in TICK)
        PH_GAME_NET,        ///< network tick (nested in TICK)
        PH_GAME_WORLD,      ///< world manager tick (nested in TICK)
        PH_GAME_OBJECT,     ///< object manager tick: characters and their models (nested in TICK)
        PH_GAME_SCRIPT,     ///< script system tick: Lua timers (nested in TICK)
        PH_GAME_OTHER,      ///< test harness work of the main loop (UI smoke clicks and PNG captures in smoke runs)
        PH_GAME_EVENTS,     ///< ProcessGameEvent: queued game events and their Lua handlers
        PH_GAME_RENDER,     ///< RenderActive: the whole OGRE frame (parent of the OGRE phases)
        // OGRE frame
        PH_FRAME_STARTED,   ///< Root frameStarted listeners: LogicModel/effects/scene builder/environment
        PH_SCENE_BUILD,     ///< incremental scene object creation (nested in FRAME_STARTED)
        PH_CONTROLLERS,     ///< ControllerManager::updateAllControllers: particle systems, texture/UV animation
        PH_SCENE_ANIM,      ///< SceneManager::_applySceneAnimations
        PH_SCENE_GRAPH,     ///< SceneManager::_updateSceneGraph: node transforms and bounds
        PH_CULL_QUEUE,      ///< visible object search and render queue build (skies/overlays queueing included)
        PH_ANIMATION,       ///< Entity::updateAnimation: skeletons and software skinning (nested in CULL_QUEUE)
        PH_DRAW,            ///< SceneManager::_renderVisibleObjects: pass/state setup and draw submission
        PH_UI_DRAW,         ///< CEGUI renderGUI: geometry rebuild and submission (nested in DRAW)
        PH_PRESENT,         ///< IDirect3DDevice9::Present
        PH_FRAME_ENDED,     ///< Root frameEnded listeners and temporary buffer release
        PH_TARGETS,         ///< Root::_updateAllRenderTargets: every auto-updated target incl. scene render + Present
        PH_COUNT
    };

    /// Per-frame event counters.
    enum Counter
    {
        C_DRAW = 0,         ///< DrawPrimitive / DrawIndexedPrimitive calls
        C_PRIMS,            ///< primitives submitted
        C_TEXTURE,          ///< SetTexture calls that changed a sampler
        C_VS,               ///< vertex shader binds
        C_PS,               ///< pixel shader binds
        C_RS,               ///< render state changes (after the redundancy check)
        C_SS,               ///< sampler and texture stage state changes (after the redundancy check)
        C_DECL,             ///< vertex declaration binds
        C_STREAM,           ///< SetStreamSource calls
        C_INDEX,            ///< SetIndices calls
        C_VS_CONST,         ///< vertex shader float4 constant registers uploaded
        C_PS_CONST,         ///< SetPixelShaderConstantF calls (one per register before CYS-PERF-FIX psconst)
        C_RENDER_SCENE,     ///< SceneManager::_renderScene calls (every viewport of every render target)
        C_ENTITY_QUEUED,    ///< entities queued for rendering
        C_ANIM_DIRTY,       ///< entities whose animation was re-evaluated
        C_SW_SKIN,          ///< entities skinned on the CPU
        C_ANIM_EXTERNAL,    ///< Entity::_updateAnimation calls from outside the render queue
        C_SCENE_OBJECTS,    ///< scene objects created by the incremental scene builder
        C_UI_REBUILD,       ///< CEGUI full geometry rebuilds
        C_UI_VB_FILL,       ///< CEGUI vertex buffer refills
        C_UI_QUADS,         ///< CEGUI quads rendered
        C_UI_BATCHES,       ///< CEGUI draw batches
        C_TEX_LOAD,         ///< textures loaded (D3D9Texture::loadImpl) - CYS-PERF-C2
        C_SHADER_CREATE,    ///< D3D9 vertex/pixel shaders created from microcode - CYS-PERF-C2
        C_CASTER_BUILD,     ///< shadow caster lookups that missed the cache (CYSShadowCasters::casterFor) - CYS-PERF-C3
        C_CASTER_US,        ///< microseconds spent in those misses (material create + load)
        C_VARIANT_BUILD,    ///< material variants created (CysMaterialSystem::getVariantMaterial misses)
        C_VARIANT_US,       ///< microseconds spent in those misses
        C_MAT_LOAD,         ///< Material::load calls that compiled a material (first use of a material)
        C_MAT_LOAD_US,      ///< microseconds spent in Material::load
        C_COUNT
    };

    /// GPU timestamp markers (Block::gpuMark).
    enum GpuMarker
    {
        MK_FRAME_BEGIN = 0,
        MK_TARGET_BEGIN,    ///< an offscreen render target (render texture) update starts
        MK_TARGET_END,
        MK_WINDOW_BEGIN,    ///< the main window update starts
        MK_WINDOW_END,
        MK_UI_BEGIN,
        MK_UI_END,
        MK_PRESENT,         ///< just before Present: end of the frame's GPU work
        MK_COUNT
    };

    enum { BLOCK_VERSION = 3 }; // CYS-PERF-C2: two counters added; CYS-PERF-C3 (perf-cy): six more

    struct Block
    {
        volatile int enabled;                   ///< non-zero while a collector is installed
        int version;                            ///< BLOCK_VERSION
        long long phaseTicks[PH_COUNT];         ///< ticks accumulated since the last frame boundary
        unsigned int phaseCalls[PH_COUNT];
        unsigned long long counters[C_COUNT];
        // Hooks installed by the collector; null when unused.
        void (*frameBegin)(void);               ///< Root::_fireFrameStarted, before any listener
        void (*gpuMark)(int marker);            ///< GPU timestamp at a GpuMarker
        void (*mark)(const char* label);        ///< named event (procedure change, scene built, ...)
        void (*listenerTime)(const void* listener, int ended, long long ticks); ///< one frame listener call
    };

    /// The single instance, exported by OgreMain.dll.
    extern CYS_PERF_API Block gBlock;

    /// QueryPerformanceCounter ticks and frequency.
    CYS_PERF_API long long ticks(void);
    CYS_PERF_API long long ticksPerSecond(void);

    inline bool on(void) { return gBlock.enabled != 0; }
    inline void count(Counter c, unsigned long long n = 1) { if (gBlock.enabled) gBlock.counters[c] += n; }
    inline void gpu(GpuMarker m) { if (gBlock.enabled && gBlock.gpuMark) gBlock.gpuMark(m); }

    /// Explicit start/stop for spans that are not a C++ scope (begin() returns 0 while disabled).
    inline long long begin(void) { return gBlock.enabled ? ticks() : 0; }
    inline void end(Phase p, long long start)
    {
        if (start && gBlock.enabled)
        {
            gBlock.phaseTicks[p] += ticks() - start;
            ++gBlock.phaseCalls[p];
        }
    }

    /// CYS-PERF-C3: counts one event and its duration in microseconds (no-op while disabled).
    class CountScope
    {
    public:
        CountScope(Counter events, Counter micros) : mEvents(events), mMicros(micros), mStart(gBlock.enabled ? ticks() : 0) {}
        ~CountScope()
        {
            if (mStart && gBlock.enabled)
            {
                gBlock.counters[mEvents] += 1;
                gBlock.counters[mMicros] += (unsigned long long)((ticks() - mStart) * 1000000 / ticksPerSecond());
            }
        }
    private:
        Counter mEvents, mMicros;
        long long mStart;
        CountScope(const CountScope&);
        CountScope& operator=(const CountScope&);
    };

    /// Adds the duration of a scope to a phase (no-op while disabled).
    class Scope
    {
    public:
        explicit Scope(Phase p) : mPhase(gBlock.enabled ? (int)p : -1), mStart(mPhase >= 0 ? ticks() : 0) {}
        ~Scope()
        {
            if (mPhase >= 0)
            {
                gBlock.phaseTicks[mPhase] += ticks() - mStart;
                ++gBlock.phaseCalls[mPhase];
            }
        }
    private:
        int mPhase;
        long long mStart;
        Scope(const Scope&);
        Scope& operator=(const Scope&);
    };
}
}

/// C entry point for modules that do not link OgreMain:
/// GetProcAddress(GetModuleHandleA("OgreMain.dll"), "CysPerfBlock").
extern "C" CYS_PERF_API Ogre::CysPerf::Block* CysPerfBlock(void);

#endif
