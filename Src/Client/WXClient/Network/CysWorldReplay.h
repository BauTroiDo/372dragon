#pragma once
// CYS: offline replay of one recorded world session for Game.exe (CYS_WORLD_REPLAY).
// When the environment variable names a PGWORLD1 fixture, the modern login and game
// workers of NetCore run on the replay streams of NetCore/ReplayStream.h instead of
// Winsock: no socket is opened, any account is accepted, the character list is
// CYTest00 / GUID 200001, and the recorded 741 GC frames are paced into the client.
// Unless CYS_WORLD_REPLAY_AUTO=0 the driver also selects the server, submits the
// login, enters with the first character, captures PNGs in the world and closes
// the window once the replay has finished (CGAskQuit goes out on shutdown).
// Nothing here runs when the variable is not set. Main thread only.

#include <memory>

namespace cys { namespace net { class StreamFactory; } }

namespace CysWorldReplay
{
    // True when CYS_WORLD_REPLAY names a loadable fixture (evaluated once, logged).
    bool Active();
    std::shared_ptr<cys::net::StreamFactory> LoginFactory();
    std::shared_ptr<cys::net::StreamFactory> GameFactory();
    // The game port the replay LCRetCharLogin names (the approved port of the profile).
    unsigned short GamePort();
    // Once per main-loop iteration: log drain and the automatic driver.
    void Tick();
    // True while the automatic driver runs (CYS_WORLD_REPLAY_AUTO != 0): the physical mouse/keyboard of the machine
    // must not move the camera or the character, so CGamePro_Main::ProcessInput is skipped (camera3d 14/09).
    bool AutoDriving();
    // CYS cs2-world: live GUI session on the private server (CysGlLoginSmoke, CYS_CREATE_ROLE_SMOKE=World). After the
    // world is ready: LiveWorldBegin once, then LiveWorldTick each main-loop iteration until it returns true (camera
    // script + three navmesh ground clicks through Player_MoveTo done, or the session ended). PNGs: cys-live-*.png.
    void LiveWorldBegin(unsigned dwellMs);
    bool LiveWorldTick();
    void LiveShot(const char* label);
    // CYS-REVIVE: one more navmesh ground click on MySelf, exactly the one the three scripted clicks use
    // (16 directions x 8 radii, through the camera ray). `index` only turns the starting direction.
    // Returns false when there is no MySelf. A driver can call it before and after a change and compare positions:
    // an impact with CanMove = 0 makes the server drop the move, so the position delta stays 0.
    bool LiveGroundClick(unsigned index);
}
