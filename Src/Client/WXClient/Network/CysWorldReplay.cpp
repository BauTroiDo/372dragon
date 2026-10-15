#include "StdAfx.h"
#include "CysWorldReplay.h"

#if defined(CYS_HAVE_NETCORE)
#include "ReplayStream.h"
#include "CysModernGame.h"
#include "CysModernHandlers.h"
#include "..\Procedure\GameProcedure.h"
#include "..\Procedure\GamePro_Login.h"
#include "..\Procedure\GamePro_CharSel.h"
#include "..\Procedure\CysOfflineUiCapture.h"
#include "..\Object\ObjectManager.h"
#include "..\Object\Character\Obj_PlayerMySelf.h"
#include "..\Object\Character\AI\GMAI_Base.h" // opt-in exact-ground qinggong probe: same AI entry as MCT_LEAP
#include "TDGameInterface.h"
#include "..\WxRender\RenderSystem.h"
#include "TDMath.h"
#include <cmath>
#include <cstring>
#include "..\World\Path.h"
#include "..\World\Scene.h"
#include "..\World\WorldManager.h"
#include "..\World\CysNavMesh.h"
#include "..\DataPool\GMDP_CharacterData.h"
#include "..\Global.h"
#include "TDUtil.h"
// CYS-CORE: core-loop driver (target, skill, loot, chat, bag) on the synthetic responder of ReplayStream
#include "NetManager.h"
#include "..\DataPool\GMDataPool.h"
#include "..\Object\TripperObj\GMTripperObj_ItemBox.h"
#include "CGAskDetailSkillList.h"
#include "CGCharUseSkill.h"
#include "CGAskMyBagList.h"
#include "CysQuestDriver.h" // CYS-QUEST
#include <stdexcept>
#define CYS_PERF_NO_IMPORT
#include "..\..\..\Engine\OGRE\OgreMain\include\OgreCysPerf.h" // CYS-PERF: perf-cy marks (layout only, CYS_PERF_NO_IMPORT)
#include <string>
#include <vector>

namespace
{
    using cys::net::replay::Session;

    // Steps of the automatic driver (CYS_WORLD_REPLAY_AUTO != 0).
    enum Step { StepLogin = 0, StepSelect, StepEnter, StepWorld, StepCore, StepClosing, StepQuest, StepScenario }; // CYS-CORE: StepCore; CYS-QUEST: StepQuest; CYS-SFX: StepScenario

    struct State
    {
        bool evaluated = false, active = false, autoDrive = true, quitPosted = false;
        std::unique_ptr<Session> session;
        std::string fixture;
        unsigned gapMs = 20, dwellMs = 12000, deadlineMs = 80000;
        DWORD started = 0, stepAt = 0, enteredAt = 0, finishedAt = 0;
        unsigned step = StepLogin, shots = 0, drained = 0;
        bool runningShot = false;
        unsigned clicks = 0;
        float moveFromX = 0, moveFromZ = 0;
        // CYS camera3d: camera script in the world (classic -> free 3D low -> yaw 90 -> zoom far -> 3D angle for clicks)
        unsigned camStep = 0;
        float camBaseDir = 0, camLowDir = 0;
        DWORD clickBase = 0;
        // CYS cs2-world: the ground clicks wait until the character stands still on walkable navmesh
        float steadyX = 0, steadyZ = 0;
        DWORD steadyAt = 0;
        // CYS cs2-world: the same world script drives a live GUI session (CysGlLoginSmoke mode World); log tag and PNG prefix
        bool live = false, liveDone = false;
        const char* tag = "replay";
        const char* shotPrefix = "cys-replay";
        // CYS-CORE: core-loop driver state (CYS_WORLD_REPLAY_CORE=1)
        bool core = false;
        bool quest = false; // CYS-QUEST: CYS_WORLD_REPLAY_QUEST=1 (synthetic NPC dialogue responder + CysQuestDriver)
        unsigned coreStep = 0, coreSkills = 0;
        int coreTarget = -1;
        DWORD coreAt = 0;
        // CYS-PERF: perf-cy scenario (CYS_PERF_SPIN=<ms>: one continuous 360 degree camera turn before the clicks)
        unsigned spinMs = 0;
        unsigned loginHoldMs = 0; // CYS-PERF: CYS_PERF_LOGIN_HOLD_MS keeps the server list (3D login scene) on screen
        DWORD spinAt = 0;
        float spinBase = 0;
        bool spinDone = false;
        // CYS-SFX: timed cy-oracle scenario (CYS_WORLD_SCENARIO) with shots at fixed offsets after every tag
        bool scenario = false, scenarioCam = false;
        unsigned seenTags = 0, scenarioShots = 0;
        std::string tagName;
        DWORD tagAt = 0, scenarioDoneAt = 0;
        std::vector<unsigned> shotMs;
        unsigned nextShot = 0;
        float camZoom = 0.4f, camDirDeg = -23.98f;
        float camAddH = -1.0f;  // CYS-FXBASE: CYS_SFX_CAM_ADDH look-at height (m); < 0 = camera table value
    };
    State& S() { static State state; return state; }

    unsigned EnvUnsigned(const char* name, unsigned fallback, unsigned low, unsigned high)
    {
        char text[32] = {};
        const DWORD length = GetEnvironmentVariableA(name, text, sizeof(text));
        if (!length || length >= sizeof(text)) return fallback;
        char* end = nullptr;
        const unsigned long value = strtoul(text, &end, 10);
        if (!end || *end || value < low || value > high) return fallback;
        return static_cast<unsigned>(value);
    }

    // CYS-PERF: named mark in the CYS_PERF collector (#mark row of CYS_PERF_CSV); no-op when CYS_PERF is not set.
    void PerfMark(const char* label)
    {
        static Ogre::CysPerf::Block* block = nullptr;
        static bool looked = false;
        if (!looked)
        {
            looked = true;
            if (HMODULE ogre = ::GetModuleHandleA("OgreMain.dll"))
            {
                typedef Ogre::CysPerf::Block* (*GetBlock)(void);
                GetBlock get = reinterpret_cast<GetBlock>(::GetProcAddress(ogre, "CysPerfBlock"));
                Ogre::CysPerf::Block* b = get ? get() : nullptr;
                if (b && b->version == Ogre::CysPerf::BLOCK_VERSION) block = b;
            }
        }
        if (block && block->enabled && block->mark) block->mark(label);
    }

    void Evaluate()
    {
        State& s = S();
        s.evaluated = true;
        char path[1024] = {};
        const DWORD length = GetEnvironmentVariableA("CYS_WORLD_REPLAY", path, sizeof(path));
        if (!length || length >= sizeof(path)) return; // Not set: the real transport is untouched.
        std::vector<cys::net::replay::Record> records;
        std::string error;
        if (!cys::net::replay::LoadFixture(path, records, error))
        {
            TDU_Log("CYS replay: fixture rejected (%s); replay disabled, no socket is opened either: %s", error.c_str(), path);
            return;
        }
        cys::net::replay::Options options;
        options.frameGapMs = EnvUnsigned("CYS_WORLD_REPLAY_GAP_MS", 20, 0, 5000);
        options.gamePort = CysWorldReplay::GamePort();
        options.coreLoop = EnvUnsigned("CYS_WORLD_REPLAY_CORE", 0, 0, 1) == 1; // CYS-CORE
        s.core = options.coreLoop;
        options.questLoop = EnvUnsigned("CYS_WORLD_REPLAY_QUEST", 0, 0, 1) == 1; // CYS-QUEST
        s.quest = options.questLoop;
        { // CYS-SFX: CYS_WORLD_SCENARIO=<file from Tools/game/cy_scenario_replay.py>
            char scenarioPath[1024] = {};
            const DWORD n = GetEnvironmentVariableA("CYS_WORLD_SCENARIO", scenarioPath, sizeof(scenarioPath));
            if (n && n < sizeof(scenarioPath))
            {
                std::string scenarioError;
                if (cys::net::replay::LoadScenario(scenarioPath, options.scenario, scenarioError))
                {
                    s.scenario = true;
                    options.scenarioDelayMs = EnvUnsigned("CYS_WORLD_SCENARIO_DELAY_MS", 0, 0, 120000);
                    char text[128] = {};
                    const DWORD m = GetEnvironmentVariableA("CYS_SFX_SHOT_MS", text, sizeof(text));
                    const char* p = (m && m < sizeof(text)) ? text : "300,800,1300";
                    for (; p && *p; )
                    {
                        s.shotMs.push_back(static_cast<unsigned>(strtoul(p, nullptr, 10)));
                        p = strchr(p, ',');
                        if (p) ++p;
                    }
                    char cam[64] = {};
                    const DWORD c = GetEnvironmentVariableA("CYS_SFX_CAM", cam, sizeof(cam));
                    if (c && c < sizeof(cam)) sscanf(cam, "%f,%f", &s.camZoom, &s.camDirDeg);
                    char addh[32] = {}; // CYS-FXBASE: CY 3.71 orbits 0.8 m above this engine's camera row (cy-oracle camread)
                    const DWORD ah = GetEnvironmentVariableA("CYS_SFX_CAM_ADDH", addh, sizeof(addh));
                    if (ah && ah < sizeof(addh)) s.camAddH = static_cast<float>(atof(addh));
                    TDU_Log("CYS scenario: %s scene=%u pos=%.2f,%.2f obj=%u steps=%u delay_ms=%u shots=%u cam zoom=%.2f dir_deg=%.2f",
                            scenarioPath, options.scenario.sceneId, options.scenario.x, options.scenario.z, options.scenario.myObj,
                            static_cast<unsigned>(options.scenario.steps.size()), options.scenarioDelayMs,
                            static_cast<unsigned>(s.shotMs.size()), s.camZoom, s.camDirDeg);
                }
                else
                {
                    TDU_Log("CYS scenario: rejected (%s): %s", scenarioError.c_str(), scenarioPath);
                }
            }
        }
        s.session.reset(new Session(std::move(records), options));
        s.fixture = path;
        s.gapMs = options.frameGapMs;
        s.dwellMs = EnvUnsigned("CYS_WORLD_REPLAY_DWELL_MS", 12000, 0, 120000);
        s.deadlineMs = EnvUnsigned("CYS_WORLD_REPLAY_DEADLINE_MS", 80000, 10000, 600000);
        s.spinMs = EnvUnsigned("CYS_PERF_SPIN", 0, 1000, 60000); // CYS-PERF: perf-cy camera turn
        s.loginHoldMs = EnvUnsigned("CYS_PERF_LOGIN_HOLD_MS", 0, 0, 120000); // CYS-PERF
        char autoText[8] = {};
        s.autoDrive = !(GetEnvironmentVariableA("CYS_WORLD_REPLAY_AUTO", autoText, sizeof(autoText)) == 1 && autoText[0] == '0');
        s.active = true;
        s.started = GetTickCount();
        TDU_Log("CYS replay: enabled fixture=%s gap_ms=%u dwell_ms=%u deadline_ms=%u auto=%d; login and game sockets are replaced by the replay streams",
                path, s.gapMs, s.dwellMs, s.deadlineMs, s.autoDrive ? 1 : 0);
    }

    void Drain()
    {
        State& s = S();
        std::vector<std::string> lines;
        s.session->drainLog(lines);
        for (const auto& line : lines)
        {
            if (s.drained++ < 4096) TDU_Log("CYS replay: %s", line.c_str());
        }
    }

    void LogVisibleWindows(const char* label);

    void Shot(const char* label)
    {
        State& s = S();
        CreateDirectoryA("..\\ScreenShots", nullptr);
        char path[MAX_PATH] = {};
        _snprintf(path, MAX_PATH, "..\\ScreenShots\\%s-%lu-%s.png", s.shotPrefix, static_cast<unsigned long>(s.started), label);
        { char mark[96] = {}; _snprintf(mark, sizeof(mark) - 1, "shot:%s", label); PerfMark(mark); } // CYS-PERF: harness frame
        try
        {
            cysCaptureOfflineUi(CGameProcedure::s_pGfxSystem, path);
            TDU_Log("CYS %s: capture=%s file=%s", s.tag, label, path);
        }
        catch (const std::exception& e)
        {
            TDU_Log("CYS %s: capture %s failed: %s", s.tag, label, e.what());
        }
        LogVisibleWindows(label);
    }

    // CYS-CYGUI2: HUD census next to every capture - the visible windows of the GUI sheet (export of UI_CEGUI.dll,
    // read-only) so a screenshot can be matched to window names ("cua so thua", missing frames).
    void LogVisibleWindows(const char* label)
    {
        typedef int (__cdecl *DumpFn)(char*, unsigned);
        HMODULE module = GetModuleHandleA("UI_CEGUI.dll");
        DumpFn dump = module ? reinterpret_cast<DumpFn>(GetProcAddress(module, "CysUiDumpVisibleWindowsUtf8")) : 0;
        if (!dump) return;
        static char buffer[65536];
        const int count = dump(buffer, sizeof(buffer));
        TDU_Log("CYS ui: census=%s visible=%d", label, count);
        const char* p = buffer;
        while (*p)
        {
            const char* e = std::strchr(p, ';');
            if (!e) break;
            TDU_Log("CYS ui: %s %.*s", label, static_cast<int>(e - p), p);
            p = e + 1;
        }
    }

    void LogReplayStats(const char* label)
    {
        const cys::net::replay::Stats st = S().session->stats();
        TDU_Log("CYS replay: %s login_tx=%u login_rx=%u game_tx=%u game_rx=%u heartbeats=%u moves=%u move_echoes=%u quits=%u "
                "unexpected=%u protocol_errors=%u world=%u/%u first_idx=%04x last_idx=%04x idx_contiguous=%d connect_first=%d",
                label, st.loginTx, st.loginRx, st.gameTx, st.gameRx, st.heartbeats, st.moves, st.moveEchoes, st.quits,
                st.unexpected, st.protocolErrors, st.worldSent, st.worldTotal, st.firstGameIdx, st.lastGameIdx,
                st.gameIdxContiguous ? 1 : 0, st.connectFirst ? 1 : 0);
    }

    void Close(const char* why)
    {
        PerfMark("replay:close"); // CYS-PERF
        State& s = S();
        if (s.quitPosted) return;
        s.quitPosted = true;
        s.step = StepClosing;
        CysModernGame::LogStatsNow();
        LogReplayStats("counters");
        TDU_Log("CYS replay: %s; closing the window (CGAskQuit goes out on shutdown)", why);
        PostMessage(g_hMainWnd, WM_CLOSE, 0xC0DE, 0xC0DE);
    }

    // CYS camera3d: the camera script calls the same CRenderSystem entry points the mouse handlers of
    // CGamePro_Main::ProcessInput call (right drag: Camera_AddDirection/Camera_AddPitch, wheel: Camera_ZoomStep).
    void LogCamera(const char* label)
    {
        CRenderSystem* gfx = CGameProcedure::s_pGfxSystem;
        if (!gfx) return;
        TDU_Log("CYS camera: %s %s", label, gfx->Camera_Describe().c_str());
    }

    float DegToPitch(float lookDownDeg) { return -lookDownDeg * TDU_PI / 180.0f; }

    // CYS-WLP (wuliang-parity): live shots from the CY 3.71 oracle cameras (Build/Logs/2026-09-15-cy-oracle/run-25-wuliang/
    // cameras.tsv). CYS_WLP_CAMS="name,orbit_distance,yaw_deg;..." (render units, CY yaw = dir_deg). Classic CY view
    // (fixed Camera_Pitch 40), direction = CY yaw, zoom so that eye-to-look distance = CY orbit distance (same entry
    // points as right drag / wheel). After each PNG, <CYS_D3DTRACE_DIR>\capture.now asks the d3d9 trace proxy (if
    // loaded) for the next frame. CYS_WLP_WAIT_MS: delay after the dwell (default 8000).
    struct WlpCam { std::string name; float dist, yaw; };
    struct WlpState { bool evaluated = false; std::vector<WlpCam> cams; unsigned index = 0, phase = 0; DWORD at = 0; unsigned waitMs = 8000, holdMs = 1500; };
    WlpState& W() { static WlpState w; return w; }

    bool WlpActive()
    {
        WlpState& w = W();
        if (w.evaluated) return !w.cams.empty();
        w.evaluated = true;
        char text[2048] = {};
        const DWORD length = GetEnvironmentVariableA("CYS_WLP_CAMS", text, sizeof(text));
        if (!length || length >= sizeof(text)) return false;
        w.waitMs = EnvUnsigned("CYS_WLP_WAIT_MS", 8000, 0, 120000);
        w.holdMs = EnvUnsigned("CYS_WLP_HOLD_MS", 1500, 1500, 60000);
        std::string all(text);
        size_t start = 0;
        while (start < all.size())
        {
            size_t end = all.find(';', start);
            if (end == std::string::npos) end = all.size();
            std::string item = all.substr(start, end - start);
            start = end + 1;
            char name[64] = {};
            WlpCam c;
            if (sscanf_s(item.c_str(), "%63[^,],%f,%f", name, static_cast<unsigned>(sizeof(name)), &c.dist, &c.yaw) == 3)
            {
                c.name = name;
                w.cams.push_back(c);
            }
        }
        TDU_Log("CYS wlp: %u CY cameras from CYS_WLP_CAMS, wait_ms=%u", static_cast<unsigned>(w.cams.size()), w.waitMs);
        return !w.cams.empty();
    }

    // Returns true once every CY camera was shot.
    bool WlpCameraScript(DWORD now, bool finished, DWORD sinceFinished)
    {
        WlpState& w = W();
        CRenderSystem* gfx = CGameProcedure::s_pGfxSystem;
        if (!gfx || w.index >= w.cams.size()) return true;
        if (!finished || sinceFinished < w.waitMs) return false;
        const WlpCam& c = w.cams[w.index];
        const float kDeg = TDU_PI / 180.0f;
        if (w.phase == 0)
        {
            if (w.index > 0 && now - w.at < 3000) return false; // the traced frame keeps the previous camera
            gfx->Camera_SetFreeMode(FALSE);
            gfx->Camera_Direction(c.yaw * kDeg);
            gfx->Camera_SetZoom(1.0f);
            w.phase = 1; w.at = now;
            return false;
        }
        if (w.phase == 1)
        {
            if (now - w.at < 600) return false;
            // CCamera_Scene distance is in game metres (render units / 100), MIN/MAX_DISTANCE from System.cfg (6 / 27.5)
            float zoom = (c.dist / 100.0f - 6.0f) / (27.5f - 6.0f);
            char line[160] = {};
            _snprintf(line, sizeof(line) - 1, "set %s cy_orbit=%.0f cy_yaw=%.1f zoom=%.3f", c.name.c_str(), c.dist, c.yaw, zoom);
            if (zoom < 0.0f) zoom = 0.0f;
            if (zoom > 1.0f) zoom = 1.0f;
            gfx->Camera_SetZoom(zoom);
            LogCamera(line);
            w.phase = 2; w.at = now;
            return false;
        }
        if (now - w.at < w.holdMs) return false;
        const std::string label = "wlp-cam-" + c.name; // "cam-": run_world_gui_live world_shots check
        Shot(label.c_str());
        LogCamera(("shot=" + label).c_str());
        char dir[MAX_PATH] = {};
        const DWORD n = GetEnvironmentVariableA("CYS_D3DTRACE_DIR", dir, sizeof(dir));
        if (n && n < sizeof(dir) - 16)
        {
            const std::string path = std::string(dir) + "\\capture.now";
            if (FILE* f = fopen(path.c_str(), "wb")) { fputs(label.c_str(), f); fclose(f); TDU_Log("CYS wlp: trace capture requested %s", label.c_str()); }
        }
        ++w.index; w.phase = 0; w.at = now;
        // the trace proxy blocks Present for a few seconds: give the next camera its own settle time
        return w.index >= w.cams.size();
    }

    // Projects a world point (game metres, y from the terrain) to the screen with the current camera and picks
    // the ground back through the camera ray exactly as CObjectManager::GetMouseOverObject does (AX_SCREEN -> AX_PLAN).
    bool PickThroughCamera(const fVector2& target, fVector2& picked, float& error, int& sx, int& sy)
    {
        CRenderSystem* gfx = CGameProcedure::s_pGfxSystem;
        fVector3 gfxPos, screen, plan;
        if (!gfx->Axis_Trans(CRenderSystem::AX_PLAN, fVector3(target.x, 0.0f, target.y), CRenderSystem::AX_GFX, gfxPos)) return false;
        if (!gfx->Axis_Trans(CRenderSystem::AX_GFX, gfxPos, CRenderSystem::AX_SCREEN, screen)) return false;
        sx = static_cast<int>(screen.x + 0.5f); sy = static_cast<int>(screen.y + 0.5f);
        if (!gfx->Axis_Trans(CRenderSystem::AX_SCREEN, fVector3(static_cast<float>(sx), static_cast<float>(sy), 0.0f), CRenderSystem::AX_PLAN, plan)) return false;
        picked = fVector2(plan.x, plan.z);
        error = std::sqrt((plan.x - target.x) * (plan.x - target.x) + (plan.z - target.y) * (plan.z - target.y));
        return true;
    }

    // Returns true once the script is finished. The classic shot is taken 3 s after entering; the free 3D shots
    // wait for the end of the recorded stream so the character stands at the fixture's last position (the same
    // framing on every run). 1.5 s between a change and its PNG lets the pitch climb (1 degree per Update) and the
    // zoom smoothing (SmoothStep 0.01 per frame) settle.
    bool CameraScript(DWORD sinceEnter, DWORD sinceFinished, bool finished)
    {
        State& s = S();
        CRenderSystem* gfx = CGameProcedure::s_pGfxSystem;
        if (!gfx) return true;
        static const DWORD at[] = {500, 3000, 200, 1700, 2000, 3500, 3800, 5300, 5600};
        if (s.camStep >= sizeof(at) / sizeof(at[0])) return true;
        if (s.camStep < 2 ? sinceEnter < at[s.camStep] : (!finished || sinceFinished < at[s.camStep])) return false;
        switch (s.camStep)
        {
        case 0: // classic 0.85/CY default view: fixed pitch Camera_Pitch, default zoom
            gfx->Camera_SetFreeMode(FALSE);
            s.camBaseDir = gfx->Camera_GetDirection();
            LogCamera("set classic");
            break;
        case 1: Shot("world-1"); LogCamera("shot=cam-classic"); s.shots = 1; break;
        case 2: // free 3D, camera lowered to look at the horizon (5 degrees down), middle zoom
        {
            // CY collides with the terrain only: a low camera behind a railing hides the character. Take the first
            // yaw (base, +45, ... ) whose camera line crosses no scene entity; the +90 shot keeps that yaw + 90.
            const float zoom = 0.55f, pitch = DegToPitch(5.0f);
            float dist = 6.0f + (27.5f - 6.0f) * zoom;
            int best = 1 << 30;
            for (int k = 0; k < 8; ++k)
            {
                const float yaw = s.camBaseDir + TDU_PI * 0.25f * k;
                const int hits = gfx->Camera_CountOccluders(yaw, pitch, dist) + gfx->Camera_CountOccluders(yaw + TDU_PI * 0.5f, pitch, dist);
                TDU_Log("CYS camera: occluders yaw_deg=%.0f hits(low+yaw90)=%d", yaw * 180.0f / TDU_PI, hits);
                if (hits >= 0 && hits < best) { best = hits; s.camLowDir = yaw; }
                if (hits == 0) break;
            }
            gfx->Camera_Direction(s.camLowDir);
        }
            gfx->Camera_SetFreeMode(TRUE);
            gfx->Camera_SetPitch(DegToPitch(5.0f));
            gfx->Camera_SetZoom(0.55f);
            LogCamera("set free3d low");
            break;
        case 3: Shot("cam-sky-low"); LogCamera("shot=cam-sky-low"); break;
        case 4: gfx->Camera_Direction(s.camLowDir + TDU_PI * 0.5f); LogCamera("set yaw+90"); break;
        case 5: Shot("cam-yaw90"); LogCamera("shot=cam-yaw90"); break;
        case 6: // zoom out to Camera_MaxDistance, pitch 35 degrees down
            gfx->Camera_SetPitch(DegToPitch(35.0f));
            gfx->Camera_SetZoomTarget(1.0f); // Camera_Smooth: Camera_Tick walks SmoothStep per frame as the wheel does
            LogCamera("set zoom-far");
            break;
        case 7: Shot("cam-zoom-far"); LogCamera("shot=cam-zoom-far"); break;
        case 8: // 3D angle for the ground clicks: 20 degrees down, yaw +45 degrees
            gfx->Camera_Direction(s.camLowDir + TDU_PI * 0.25f);
            gfx->Camera_SetPitch(DegToPitch(20.0f));
            gfx->Camera_SetZoom(0.7f);
            LogCamera("set click-angle");
            break;
        }
        ++s.camStep;
        return false;
    }

    // CYS cs2-world: true once the character rests on walkable ground. The recorded stream keeps moving the
    // character for a while after its last frame, and on the CY map (dali_new_320) some recorded positions of the
    // old dali fixture are not walkable at all - clicking from there produced reachable=0 (replay-run-7/8).
    bool ReadyForClicks(CObject_PlayerMySelf* self)
    {
        State& s = S();
        const DWORD now = GetTickCount();
        const float x = self->GetPosition().x, z = self->GetPosition().z;
        if (!s.steadyAt || std::fabs(x - s.steadyX) > 0.05f || std::fabs(z - s.steadyZ) > 0.05f)
        {
            s.steadyX = x; s.steadyZ = z; s.steadyAt = now;
            return false;
        }
        if (now - s.steadyAt < 800) return false;
        CScene* scene = (CScene*)CWorldManager::GetMe()->GetActiveScene();
        cys::NavMesh* nav = scene ? scene->GetNavMesh() : nullptr;
        return !nav || nav->IsWalkable(x, z);
    }

    // One ground click as the mouse does (CGameInterface::Player_MoveTo -> CAI_MySelf::AI_MoveTo -> CGCharMove).
    // The target is the first candidate around the character that the scene navmesh can reach.
    // CYS-NAV: khoảng giữa các click (mặc định 2,5 s); CYS_WORLD_REPLAY_CLICK_MS cho đường vòng dài quanh nhà.
    DWORD ClickGapMs() { static const DWORD gap = EnvUnsigned("CYS_WORLD_REPLAY_CLICK_MS", 2500, 1000, 20000); return gap; }

    bool QingProbe() { static const bool on = EnvUnsigned("CYS_WORLD_REPLAY_FLY", 0, 0, 1) == 1; return on; }

    void QingShots(CObject_PlayerMySelf* self)
    {
        if (!QingProbe() || !self || !S().clicks) return;
        static unsigned click = 0, mask = 0;
        if (click != S().clicks) { click = S().clicks; mask = 0; }
        const float progress = self->CysLeapProgress();
        const char* tag = 0; unsigned bit = 0;
        if (self->CysIsLeaping())
        {
            if (!(mask & 1)) { tag = "first-fly-frame"; bit = 1; }
            else if (progress >= .5f && !(mask & 2)) { tag = "progress50"; bit = 2; }
            else if (progress >= .85f && !(mask & 4)) { tag = "progress85"; bit = 4; }
        }
        else if ((mask & 1) && !(mask & 8)) { tag = "landed"; bit = 8; }
        if (tag)
        {
            char label[96]; _snprintf(label, sizeof(label)-1, "qing-%u-%s", click, tag); label[sizeof(label)-1] = 0;
            Shot(label); mask |= bit;
            TDU_Log("CYS-QINGPROBE: shot=%s progress=%.4f pos=(%.3f,%.3f)", label, progress, self->GetPosition().x, self->GetPosition().z);
        }
    }

    void ClickGround(CObject_PlayerMySelf* self, unsigned index)
    {
        // CYS cs2-world: 16 directions x 5 radii instead of the 10 fixed offsets of the dali fixture. On the CY map
        // (dali_new_320) the recorded positions can stand next to a wall, where every fixed offset was blocked and
        // the click became a no-op (replay-run-7: 2 of 3 clicks reachable=0).
        static const float radii[] = {8.0f, 6.0f, 4.0f, 3.0f, 2.0f, 12.0f, 16.0f, 24.0f};
        const float x = self->GetPosition().x, z = self->GetPosition().z;
        CScene* scene = (CScene*)CWorldManager::GetMe()->GetActiveScene();
        cys::NavMesh* nav = scene ? scene->GetNavMesh() : nullptr;
        fVector2 target(x + radii[0], z);
        size_t waypoints = 0;
        bool found = false;
        const unsigned sectors = 16;
        for (size_t r = 0; r < sizeof(radii) / sizeof(radii[0]) && !found; ++r)
        {
            for (unsigned k = 0; k < sectors && !found; ++k)
            {
                // Turn the starting direction per click so the three clicks do not repeat one target.
                const float angle = 2.0f * TDU_PI * ((k + (index - 1) * 5) % sectors) / sectors;
                const cys::NavPoint from = {x, z};
                const cys::NavPoint to = {x + radii[r] * std::cos(angle), z + radii[r] * std::sin(angle)};
                std::vector<cys::NavPoint> path;
                if (!nav || (nav->IsWalkable(to.x, to.z) && nav->FindPath(from, to, path) && !path.empty()))
                {
                    target = fVector2(to.x, to.z);
                    waypoints = path.size();
                    found = true;
                }
            }
        }
        // CYS-NAV: CYS_WORLD_REPLAY_CLICKS="x,z;x,z;x,z" đặt đích click cố định (sau tường, lên bục) để chứng minh
        // navmesh + WCollision; đích không cần đi được (click vào nhà = đi thẳng tới tường rồi dừng như CY).
        {
            char clicks[256] = {};
            const DWORD length = GetEnvironmentVariableA("CYS_WORLD_REPLAY_CLICKS", clicks, sizeof(clicks));
            if (length && length < sizeof(clicks))
            {
                const char* p = clicks;
                for (unsigned k = 1; k < index && p; ++k) { p = strchr(p, ';'); if (p) ++p; }
                float cx = 0, cz = 0;
                if (p && sscanf(p, "%f,%f", &cx, &cz) == 2)
                {
                    const cys::NavPoint from = {x, z};
                    const cys::NavPoint to = {cx, cz};
                    std::vector<cys::NavPoint> path;
                    found = nav && nav->IsWalkable(cx, cz) && nav->FindPath(from, to, path) && !path.empty();
                    waypoints = path.size();
                    target = fVector2(cx, cz);
                    float building = 0;
                    const BOOL onBuilding = scene ? scene->m_WalkCollisionMng.GetHeight(cx, cz, building) : FALSE;
                    TDU_Log("CYS-NAV: scripted click %u target=(%.2f,%.2f) walkable=%d segment_hits_wall=%d building_top=%s%.3f",
                            index, cx, cz, nav && nav->IsWalkable(cx, cz) ? 1 : 0,
                            nav && nav->SegmentHitsWall(from, to) ? 1 : 0, onBuilding ? "" : "none/", building);
                }
            }
        }
        const CCharacterData* data = self->GetCharacterData();
        TDU_Log("CYS %s: ground click %u from %.2f,%.2f to %.2f,%.2f navmesh=%d reachable=%d waypoints=%u limit_move=%d",
                S().tag, index, x, z, target.x, target.y, nav ? 1 : 0, found ? 1 : 0, static_cast<unsigned>(waypoints),
                data && data->IsLimitMove() ? 1 : 0);
        if (QingProbe())
        {
            // Exact target for L=5/13.5/3 evidence. The physical Ctrl-click path uses this same AI entry;
            // only the screen-pixel pick is bypassed, explicitly, so it cannot perturb the measured length.
            const INT skill = data ? data->GetDefaultFlySkillID() : INVALID_ID;
            const BOOL sent = self->CharacterLogic_GetAI() && self->CharacterLogic_GetAI()->PushCommand_Fly(skill, target.x, target.y);
            TDU_Log("CYS-QINGPROBE: request=%u skill=%d from=(%.3f,%.3f) to=(%.3f,%.3f) length=%.6f accepted=%d",
                index, skill, x, z, target.x, target.y, std::sqrt((target.x-x)*(target.x-x)+(target.y-z)*(target.y-z)), sent ? 1 : 0);
            return;
        }
        // CYS camera3d: the click goes through the current camera ray (screen point -> terrain), as a mouse click would
        fVector2 picked;
        float error = 0;
        int sx = -1, sy = -1;
        if (PickThroughCamera(target, picked, error, sx, sy))
        {
            TDU_Log("CYS camera: click-pick %u screen=(%d,%d) target=(%.2f,%.2f) picked=(%.2f,%.2f) error_m=%.3f free3d=%d pitch_deg=%.1f",
                    index, sx, sy, target.x, target.y, picked.x, picked.y, error,
                    CGameProcedure::s_pGfxSystem->Camera_IsFreeMode() ? 1 : 0, -CGameProcedure::s_pGfxSystem->Camera_GetPitch() * 180.0f / TDU_PI);
            if (error < 1.0f) target = picked;
        }
        else
        {
            TDU_Log("CYS camera: click-pick %u target=(%.2f,%.2f) not on screen; direct target used", index, target.x, target.y);
        }
        CGameProcedure::s_pGameInterface->Player_MoveTo(target);
    }

    void CoreScript(DWORD now); // CYS-CORE

    // CYS-SFX: cy-oracle scenario. The CY camera of the reference run (run-27-hit cameras.tsv: pitch 40, fovy 35,
    // yaw -23.98, orbit 14.6 m = zoom 0.4 of [6, 27.5]) in the classic mode, then CYS_SFX_SHOT_MS after every tag.
    // CYS_SFX_TRIGGER=<file>: the label is written there right before each capture (d3d9 trace proxy capture.now).
    void ScenarioScript(DWORD now)
    {
        State& s = S();
        if (!CysModernGame::IsActive()) { Close("game session ended in the scenario"); return; }
        CRenderSystem* gfx = CGameProcedure::s_pGfxSystem;
        if (!s.scenarioCam && gfx)
        {
            gfx->Camera_SetFreeMode(FALSE);
            gfx->Camera_SetZoom(s.camZoom);
            gfx->Camera_Direction(s.camDirDeg * TDU_PI / 180.0f);
            if (s.camAddH >= 0.0f) { gfx->Camera_SetAddHeight(s.camAddH); TDU_Log("CYS scenario: CYS_SFX_CAM_ADDH %.2f m applied", s.camAddH); } // CYS-FXBASE
            s.scenarioCam = true;
            LogCamera("scenario set");
        }
        const cys::net::replay::Stats st = s.session->stats();
        if (st.scenarioTags > s.seenTags)
        {
            s.seenTags = st.scenarioTags;
            s.tagName = st.lastTag;
            s.tagAt = now;
            s.nextShot = 0;
            TDU_Log("CYS scenario: tag %s seen (session %u ms after enter)", s.tagName.c_str(), st.lastTagMs);
        }
        if (s.tagAt && s.nextShot < s.shotMs.size() && now - s.tagAt >= s.shotMs[s.nextShot])
        {
            static const char suffix[] = "abcdefgh";
            char label[96] = {};
            _snprintf(label, sizeof(label) - 1, "%s-%c", s.tagName.c_str(), suffix[s.nextShot < 8 ? s.nextShot : 7]);
            char trigger[1024] = {};
            const DWORD n = GetEnvironmentVariableA("CYS_SFX_TRIGGER", trigger, sizeof(trigger));
            if (n && n < sizeof(trigger))
            {
                if (FILE* f = fopen(trigger, "wb")) { fputs(label, f); fclose(f); }
            }
            TDU_Log("CYS scenario: shot %s at +%lu ms after tag", label, static_cast<unsigned long>(now - s.tagAt));
            Shot(label);
            if (s.nextShot == 0)
            {
                LogCamera(label);
                CObjectManager* objects = CObjectManager::GetMe();
                if (objects && objects->GetMySelf())
                {
                    const fVector3& p = objects->GetMySelf()->GetPosition();
                    TDU_Log("CYS scenario: %s myself=%.2f,%.2f,%.2f", label, p.x, p.y, p.z);
                }
            }
            ++s.nextShot;
            ++s.scenarioShots;
        }
        const bool shotsDone = !s.tagAt || s.nextShot >= s.shotMs.size();
        if (st.finished && shotsDone)
        {
            if (!s.scenarioDoneAt) s.scenarioDoneAt = now;
            if (now - s.scenarioDoneAt >= 1500)
            {
                char why[96] = {};
                _snprintf(why, sizeof(why) - 1, "scenario finished (%u tags, %u shots)", s.seenTags, s.scenarioShots);
                Close(why);
            }
        }
    }

    void Drive()
    {
        State& s = S();
        const DWORD now = GetTickCount();
        CGameProcedure* proc = CGameProcedure::GetActiveProcedure();
        if (!s.quitPosted && now - s.started > s.deadlineMs)
        {
            char why[96] = {};
            _snprintf(why, sizeof(why) - 1, "deadline %u ms reached at step %u", s.deadlineMs, s.step);
            Close(why);
            return;
        }
        switch (s.step)
        {
        case StepLogin:
        {
            CGamePro_Login* login = CGameProcedure::s_pProcLogIn;
            if (proc != (CGameProcedure*)login || !login) break;
            const CGamePro_Login::PLAYER_LOGIN_STATUS status = login->GetStatus();
            if (status == CGamePro_Login::LOGIN_SELECT_SERVER)
            {
                if (!s.stepAt) { s.stepAt = now; PerfMark("replay:server-list"); } // CYS-PERF
                if (now - s.stepAt >= 1500 + s.loginHoldMs) // CYS-PERF: + CYS_PERF_LOGIN_HOLD_MS
                {
                    const int rc = login->SelectLoginServer(0, 0);
                    TDU_Log("CYS replay: auto server selection rc=%d", rc);
                    s.stepAt = 0;
                }
            }
            else if (status == CGamePro_Login::LOGIN_INPUT_ACCOUNT)
            {
                if (!s.stepAt) s.stepAt = now;
                if (now - s.stepAt >= 2000)
                {
                    Shot("login");
                    char account[] = "replay", password[] = "replay";
                    const int rc = login->CheckAccount(account, password);
                    TDU_Log("CYS replay: auto login submitted rc=%d modern=%d", rc, login->IsModernLoginActive() ? 1 : 0);
                    s.step = StepSelect;
                    s.stepAt = 0;
                }
            }
            break;
        }
        case StepSelect:
        {
            CGamePro_CharSel* select = CGameProcedure::s_pProcCharSel;
            if (proc != (CGameProcedure*)select || !select || !select->UsesModernCharacters() || select->GetCurRoleCount() < 1) break;
            if (!s.stepAt) s.stepAt = now;
            if (now - s.stepAt >= 2500)
            {
                Shot("charsel");
                const bool selected = select->SelectRoleIndex(0);
                const int rc = select->SendEnterGameMsg(0);
                TDU_Log("CYS replay: auto enter selected=%d rc=%d", selected ? 1 : 0, rc);
                s.step = StepEnter;
                s.stepAt = 0;
            }
            break;
        }
        case StepEnter:
            if (CysModernGame::IsInWorld() && CysModernHandlers::WorldReady())
            {
                s.enteredAt = now;
                s.step = s.scenario ? StepScenario : StepWorld; // CYS-SFX
                TDU_Log("CYS replay: in world %lu ms after start", static_cast<unsigned long>(now - s.started));
                PerfMark("replay:in-world"); // CYS-PERF
            }
            else if (!CysModernGame::IsActive() && proc != (CGameProcedure*)CGameProcedure::s_pProcCharSel &&
                     proc != (CGameProcedure*)CGameProcedure::s_pProcLogIn)
            {
                Close("game session ended before the world was ready");
            }
            break;
        case StepWorld:
        {
            if (!CysModernGame::IsActive()) { Close("game session ended in the world"); break; }
            CObject_PlayerMySelf* self = CObjectManager::GetMe() ? CObjectManager::GetMe()->GetMySelf() : nullptr;
            const cys::net::replay::Stats st = s.session->stats();
            if (st.finished && !s.finishedAt) s.finishedAt = now;
            const bool cameraDone = CameraScript(now - s.enteredAt, s.finishedAt ? now - s.finishedAt : 0, s.finishedAt != 0);
            if (!s.finishedAt || !self || !CGameProcedure::s_pGameInterface || !cameraDone) break;
            // CYS-PERF: perf-cy scenario - one continuous 360 degree turn of the free camera at the click angle.
            if (s.spinMs && !s.spinDone)
            {
                CRenderSystem* gfx = CGameProcedure::s_pGfxSystem;
                if (!s.spinAt) { s.spinAt = now; s.spinBase = gfx ? gfx->Camera_GetDirection() : 0.0f; PerfMark("replay:spin-begin"); }
                const float t = static_cast<float>(now - s.spinAt) / static_cast<float>(s.spinMs);
                if (gfx) gfx->Camera_Direction(s.spinBase + TDU_PI * 2.0f * (t < 1.0f ? t : 1.0f));
                if (t < 1.0f) break;
                s.spinDone = true;
                PerfMark("replay:spin-end");
            }
            if (!s.clicks && !ReadyForClicks(self)) break;
            // Three ground clicks once the recorded stream is over (its own GCCharMove frames no longer interfere)
            // and the camera script has put the camera at the 3D click angle; 2.5 s between clicks (8 m walks).
            if (!s.clickBase) s.clickBase = now;
            const DWORD since = now - s.clickBase;
            if (s.clicks < 3 && since >= 1000 + s.clicks * ClickGapMs())
            {
                if (s.clicks == 0)
                {
                    s.moveFromX = self->GetPosition().x; s.moveFromZ = self->GetPosition().z;
                    Shot("move-before");
                }
                PerfMark(s.clicks == 0 ? "replay:click-1" : (s.clicks == 1 ? "replay:click-2" : "replay:click-3")); // CYS-PERF
                ClickGround(self, s.clicks + 1);
                ++s.clicks;
            }
            if (s.clicks == 1 && !s.runningShot && since >= 1000 + 700) { Shot("move-running"); LogCamera("shot=move-running"); s.runningShot = true; }
            if (s.clicks == 3 && since >= 1000 + 3 * ClickGapMs())
            {
                Shot("move-after");
                LogCamera("shot=move-after");
                TDU_Log("CYS replay: position before clicks %.2f,%.2f after %.2f,%.2f (delta %.2f,%.2f)", s.moveFromX, s.moveFromZ,
                        self->GetPosition().x, self->GetPosition().z, self->GetPosition().x - s.moveFromX,
                        self->GetPosition().z - s.moveFromZ);
                if (s.core) { s.step = StepCore; s.coreAt = now; TDU_Log("CYS replay: core loop begins"); } // CYS-CORE
                else if (s.quest) { s.step = StepQuest; TDU_Log("CYS replay: quest script begins"); } // CYS-QUEST
                else Close("replay finished and three ground clicks done");
            }
            break;
        }
        case StepCore: // CYS-CORE
            CoreScript(now);
            break;
        case StepQuest: // CYS-QUEST: NPC dialogue / mission GUI script on the synthetic responder
            if (CysQuestDriver::Tick()) Close("quest script finished");
            break;
        case StepScenario: // CYS-SFX
            ScenarioScript(now);
            break;
        default:
            break;
        }
    }

    size_t CountBag(); // CYS-CORE

    // CYS-CORE: the core loop on the synthetic responder. Wire packets go through CNetManager::SendPacket, i.e. the
    // same 0.85 packet classes the UI/AI would build, translated by CysModernGame; the replies exercise the ported
    // handlers (CysModernHandlers) and the existing UI (target board, damage text, loot window, chat frame, bag).
    void CoreScript(DWORD now)
    {
        State& s = S();
        if (!CysModernGame::IsActive()) { Close("game session ended during the core loop"); return; }
        CObjectManager* objects = CObjectManager::GetMe();
        CObject_PlayerMySelf* self = objects ? objects->GetMySelf() : nullptr;
        if (!self) { Close("no own object in the core loop"); return; }
        const DWORD since = now - s.coreAt;
        const CysModernHandlers::CoreCounters c = CysModernHandlers::Core();
        auto next = [&](unsigned step, const char* what) { s.coreStep = step; s.coreAt = now; TDU_Log("CYS replay: core step %u %s", step, what);
            char mark[48] = {}; _snprintf(mark, sizeof(mark) - 1, "replay:core-%u", step); PerfMark(mark); }; // CYS-PERF
        switch (s.coreStep)
        {
        case 0: // skill list (the AI needs Get_Skill), then the nearest enemy (Tab logic of 0.85)
        {
            // CYS-CYGUI2: the camera script left the free camera at 20 degrees / zoom 0.7 for the clicks; the core
            // captures (core-target/core-hit/core-dead) must show the character, the monster and the damage text:
            // back to the classic CY view (fixed pitch, default zoom) that the world-1 HUD capture uses.
            if (CRenderSystem* gfx = CGameProcedure::s_pGfxSystem)
            {
                gfx->Camera_SetFreeMode(FALSE);
                gfx->Camera_SetZoom(1.0f);   // classic default (world-1: zoom=1.00 dist 27.5 m)
                LogCamera("core reset classic");
            }
            CGAskDetailSkillList ask;
            ask.setTargetID(self->GetServerID());
            CNetManager::GetMe()->SendPacket(&ask);
            objects->Debug_LockNearestTarget();
            tObject* target = objects->GetMainTarget();
            s.coreTarget = target ? target->GetServerID() : -1;
            if (s.coreTarget < 0)
            {
                // The recorded Dali scene holds camp-8 NPCs only (no RELATION_ENEMY): the responder kills any recorded
                // monster, so take the nearest monster of the WorldModel and select it as a click would.
                float distance = 0;
                const unsigned nearest = CysModernGame::NearestMonster(&distance);
                if (nearest && objects->FindServerObject(static_cast<INT>(nearest)))
                {
                    objects->SetMainTarget(static_cast<INT>(nearest));
                    s.coreTarget = static_cast<int>(nearest);
                    TDU_Log("CYS replay: core target fallback nearest monster=%u dist=%.1f", nearest, distance);
                }
            }
            TDU_Log("CYS replay: core target=%d (Debug_LockNearestTarget, enemy within 20 m)", s.coreTarget);
            if (s.coreTarget < 0) { Close("core loop: no enemy within 20 m"); return; }
            next(1, "target locked; CGLockTarget sent by SetMainTarget");
            break;
        }
        case 1:
            if (since >= 1200)
            {
                Shot("core-target");
                next(2, "first skill");
            }
            break;
        case 2: case 3: case 4: // three normal attacks (SkillData 0) 1.3 s apart; the responder kills on the third
            if (since >= (s.coreStep == 2 ? 0u : 1300u))
            {
                CObject* target = (CObject*)objects->FindServerObject(s.coreTarget);
                WORLD_POS pos;
                pos.m_fX = target ? target->GetPosition().x : self->GetPosition().x;
                pos.m_fZ = target ? target->GetPosition().z : self->GetPosition().z;
                Packets::CGCharUseSkill use;
                use.setObjID(self->GetServerID());
                use.setSkillDataID(0);
                use.setTargetGUID(INVALID_GUID);
                use.setTargetID(s.coreTarget);
                use.setTargetPos(pos);
                use.setDir(0.0f);
                CNetManager::GetMe()->SendPacket(&use);
                ++s.coreSkills;
                TDU_Log("CYS replay: core CGCharUseSkill %u skill=0 target=%d", s.coreSkills, s.coreTarget);
                if (s.coreStep == 3) Shot("core-hit");
                next(s.coreStep + 1, "skill sent");
            }
            break;
        case 5: // corpse + drop box
            if (c.itemBoxes >= 1 && since >= 1200)
            {
                Shot("core-dead");
                next(6, "monster dead; opening the drop box");
            }
            else if (since > 6000) { Close("core loop: no drop box after the third skill"); }
            break;
        case 6:
        {
            // The box object was created by OnGCNewItemBox (or by AddDropBoxEvent after the die animation).
            CTripperObject_ItemBox* box = nullptr;
            for (int id = 0x00FF0001; id < 0x00FF0004 && !box; ++id)
            {
                tObject* candidate = objects->FindServerObject(id);
                if (candidate && g_theKernel.IsKindOf(candidate->GetClass(), GETCLASS(CTripperObject_ItemBox))) box = (CTripperObject_ItemBox*)candidate;
            }
            if (box) { box->Tripper_Active(); next(7, "CGOpenItemBox sent"); }
            else if (since > 5000) Close("core loop: drop box object not created");
            break;
        }
        case 7:
            if (c.boxLists >= 1 && since >= 1000)
            {
                Shot("core-loot");
                tObject_Item* item = CDataPool::GetMe()->ItemBox_GetItem(0);
                if (!item) { Close("core loop: loot window has no item"); return; }
                CGameProcedure::s_pGameInterface->ItemBox_PickItem(item);
                next(8, "CGPickBoxItem sent");
            }
            else if (since > 5000) Close("core loop: no GCBoxItemList");
            break;
        case 8:
            if (c.picksOk >= 1 && since >= 800)
            {
                CGameProcedure::s_pGameInterface->SendChatCommand(0, CHAT_TYPE_NORMAL, 0, "Xin chao Dai Ly! (CY-Source core loop)", "");
                next(9, "CGChat sent");
            }
            else if (since > 5000) Close("core loop: no GCPickResult");
            break;
        case 9:
            if (c.chats >= 1 && since >= 1200)
            {
                Shot("core-chat");
                CGAskMyBagList bag;
                bag.SetAskMode(ASK_ALL);
                CNetManager::GetMe()->SendPacket(&bag);
                next(10, "CGAskMyBagList sent");
            }
            else if (since > 5000) Close("core loop: no GCChat echo");
            break;
        case 10:
            if (c.bagLists >= 1 && since >= 800)
            {
                Shot("core-bag");
                TDU_Log("CYS replay: core done chats=%u skill_sends=%u damages=%u target_lists=%u item_boxes=%u box_lists=%u picks_ok=%u "
                        "item_infos=%u bag_lists=%u skill_lists=%u bag_items=%u",
                        c.chats, c.skillSends, c.damages, c.targetLists, c.itemBoxes, c.boxLists, c.picksOk, c.itemInfos, c.bagLists,
                        c.skillLists, static_cast<unsigned>(CountBag()));
                Close("core loop finished");
            }
            else if (since > 5000) Close("core loop: no GCMyBagList");
            break;
        default:
            break;
        }
    }

    size_t CountBag()
    {
        size_t count = 0;
        for (INT i = 0; i < 100; ++i) if (CDataPool::GetMe()->UserBag_GetItem(i)) ++count;
        return count;
    }
}

bool CysWorldReplay::Active()
{
    State& s = S();
    if (!s.evaluated) Evaluate();
    return s.active;
}

std::shared_ptr<cys::net::StreamFactory> CysWorldReplay::LoginFactory()
{
    return Active() ? S().session->loginFactory() : std::shared_ptr<cys::net::StreamFactory>();
}

std::shared_ptr<cys::net::StreamFactory> CysWorldReplay::GameFactory()
{
    return Active() ? S().session->gameFactory() : std::shared_ptr<cys::net::StreamFactory>();
}

unsigned short CysWorldReplay::GamePort() { return 15734; } // CYS: port recorded in the replay fixture LCRetCharLogin.

bool CysWorldReplay::AutoDriving()
{
    // CYS cs2-world: the live world script owns the camera too, so the physical mouse of the machine must not drive it.
    return (Active() && S().autoDrive) || (S().live && !S().liveDone);
}

void CysWorldReplay::Tick()
{
    if (!Active()) return;
    Drain();
    if (S().autoDrive) Drive();
}

// CYS cs2-world: world part of a live GUI session on the private server (CysGlLoginSmoke mode World). Same camera script
// and ground clicks as the replay driver; the "end of the recorded stream" is replaced by a dwell after entering, so
// the server has sent the NPC/monster frames of the scene before the free 3D shots.
void CysWorldReplay::LiveWorldBegin(unsigned dwellMs)
{
    State& s = S();
    if (s.active || s.live) return; // a replay owns the driver state
    s.live = true;
    s.tag = "live";
    s.shotPrefix = "cys-live";
    s.started = GetTickCount();
    s.enteredAt = s.started;
    s.finishedAt = s.started + dwellMs;
    s.step = StepWorld;
    TDU_Log("CYS live: world driver begin dwell_ms=%u", dwellMs);
}

bool CysWorldReplay::LiveWorldTick()
{
    State& s = S();
    if (!s.live) return true;
    if (s.liveDone) return true;
    const DWORD now = GetTickCount();
    if (!CysModernGame::IsActive())
    {
        TDU_Log("CYS live: game session ended in the world before the script finished (clicks=%u)", s.clicks);
        s.liveDone = true;
        return true;
    }
    CObject_PlayerMySelf* self = CObjectManager::GetMe() ? CObjectManager::GetMe()->GetMySelf() : nullptr;
    const bool finished = static_cast<LONG>(now - s.finishedAt) >= 0;
    if (WlpActive()) // CYS-WLP: CY oracle cameras only, no free-3D script and no ground clicks (character stays put)
    {
        if (!WlpCameraScript(now, finished, finished ? now - s.finishedAt : 0)) return false;
        if (CRenderSystem* gfx = CGameProcedure::s_pGfxSystem) { gfx->Camera_SetFreeMode(FALSE); gfx->Camera_SetZoom(1.0f); LogCamera("wlp reset classic"); }
        s.liveDone = true;
        return true;
    }
    const bool cameraDone = CameraScript(now - s.enteredAt, finished ? now - s.finishedAt : 0, finished);
    if (!finished || !self || !CGameProcedure::s_pGameInterface || !cameraDone) return false;
    if (!s.clicks && !ReadyForClicks(self)) return false;
    if (!s.clickBase) s.clickBase = now;
    const DWORD since = now - s.clickBase;
    QingShots(self);
    if (s.clicks < 3 && since >= 1000 + s.clicks * ClickGapMs())
    {
        if (s.clicks == 0)
        {
            s.moveFromX = self->GetPosition().x; s.moveFromZ = self->GetPosition().z;
            Shot("move-before");
        }
        ClickGround(self, s.clicks + 1);
        ++s.clicks;
    }
    if (s.clicks == 1 && !s.runningShot && since >= 1000 + 700) { Shot("move-running"); LogCamera("shot=move-running"); s.runningShot = true; }
    if (s.clicks == 3 && since >= 1000 + 3 * ClickGapMs())
    {
        if (QingProbe())
        {
            static DWORD walkAt = 0;
            static bool returning = false;
            if (!walkAt)
            {
                walkAt = now;
                const fVector3 p = self->GetPosition();
                CGameProcedure::s_pGameInterface->Player_MoveTo(fVector2(p.x + 2.0f, p.z));
                TDU_Log("CYS-QINGPROBE: after-land walk from=(%.3f,%.3f) to=(%.3f,%.3f)", p.x, p.z, p.x+2.0f, p.z);
                return false;
            }
            if (!returning)
            {
                if (now - walkAt < 2500) return false;
                TDU_Log("CYS-QINGPROBE: after-land walk observed=(%.3f,%.3f), returning to fixture=(%.3f,%.3f)",
                    self->GetPosition().x, self->GetPosition().z, s.moveFromX, s.moveFromZ);
                Shot("qing-after-land-walk");
                CGameProcedure::s_pGameInterface->Player_MoveTo(fVector2(s.moveFromX, s.moveFromZ));
                returning = true; walkAt = now;
                return false;
            }
            if (now - walkAt < 8000) return false;
            TDU_Log("CYS-QINGPROBE: fixture restored start=(%.3f,%.3f) actual=(%.3f,%.3f)",
                s.moveFromX, s.moveFromZ, self->GetPosition().x, self->GetPosition().z);
        }
        Shot("move-after");
        LogCamera("shot=move-after");
        TDU_Log("CYS live: position before clicks %.2f,%.2f after %.2f,%.2f (delta %.2f,%.2f)", s.moveFromX, s.moveFromZ,
                self->GetPosition().x, self->GetPosition().z, self->GetPosition().x - s.moveFromX,
                self->GetPosition().z - s.moveFromZ);
        CysModernGame::LogStatsNow();
        // CYS-SCFIX: the camera script left the driver-only free camera (20 degrees, zoom 0.7) for the clicks. A CY
        // player cannot reach that pitch (oracle-1-luoyang: pitch stays Camera_Pitch 40) and the quest drivers that
        // follow travel to other scenes with it: npc-quest gui-live-11 arrived in Luoyang with the eye inside a tree.
        // Back to the CY view (fixed pitch, default zoom 1.0 = 27.5 m) as the core replay already does.
        if (CRenderSystem* gfx = CGameProcedure::s_pGfxSystem)
        {
            gfx->Camera_SetFreeMode(FALSE);
            gfx->Camera_SetZoom(1.0f);
            LogCamera("live reset classic");
        }
        s.liveDone = true;
        return true;
    }
    return false;
}

void CysWorldReplay::LiveShot(const char* label)
{
    if (S().live || S().quest)
    {
        Shot(label); // CYS-QUEST: the quest driver also runs on the offline replay
        // CYS-SCFIX: camera (yaw, pitch, distance) with each quest capture, e.g. right after a scene transfer
        char line[96] = {};
        _snprintf(line, sizeof(line) - 1, "shot=%s", label ? label : "?");
        LogCamera(line);
        if (CObjectManager::GetMe() && CObjectManager::GetMe()->GetMySelf())
        {
            const fVector3& p = CObjectManager::GetMe()->GetMySelf()->GetPosition();
            TDU_Log("CYS camera: shot=%s myself=%.2f,%.2f", label ? label : "?", p.x, p.z);
        }
    }
}

bool CysWorldReplay::LiveGroundClick(unsigned index)
{
    // CYS-REVIVE: the same click the three scripted ones use, callable from a driver.
    CObjectManager* objects = CObjectManager::GetMe();
    CObject_PlayerMySelf* self = objects ? objects->GetMySelf() : NULL;
    if (!self) return false;
    ClickGround(self, index);
    return true;
}

#else // !CYS_HAVE_NETCORE

bool CysWorldReplay::Active() { return false; }
std::shared_ptr<cys::net::StreamFactory> CysWorldReplay::LoginFactory() { return std::shared_ptr<cys::net::StreamFactory>(); }
std::shared_ptr<cys::net::StreamFactory> CysWorldReplay::GameFactory() { return std::shared_ptr<cys::net::StreamFactory>(); }
unsigned short CysWorldReplay::GamePort() { return 15734; }
void CysWorldReplay::Tick() {}
bool CysWorldReplay::AutoDriving() { return false; }
void CysWorldReplay::LiveWorldBegin(unsigned) {}
bool CysWorldReplay::LiveWorldTick() { return true; }
void CysWorldReplay::LiveShot(const char*) {}
bool CysWorldReplay::LiveGroundClick(unsigned) { return false; }

#endif
