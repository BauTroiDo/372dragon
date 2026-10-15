#pragma once
// CYS-MESHWIN 19/09: game-layer half of the MeshWindow work (branch meshwindow). Two things live here:
//
//   1. DataPool:KFS_UpdateKFSModel()  CY Game.exe 0x1402f2490 -> CDataPool 0x1400db200:
//        item = equipment at point 18 (HEQUIP_WUHUN); model = item ? KfsModelId(item) : -1;
//        m_pWuhunAvatar->CharacterData.Set_ModelID(model); m_pWuhunAvatar->SetFaceDir(0)
//      KfsModelId (0x1404fd780): equip point must be 18; row = KFSBase (CY DBC 0xEE) by the item's table id;
//        visual tier (1..4) ? row[10 + tier] : row[10] (CanonicalCY KFSBase.txt: 4 rows x 35 ints,
//        10156001 -> 2341..2345, 10156002 -> 2346..2350). These are direct CharModelEx IDs.
//        The base appearance uses column 10; combat wh_level (1..120) is not this visual tier.
//      25/09 correction: the earlier Set_RaceID annotation was wrong. MonsterAttrExTable[2341]
//      resolves to a human; CharModelEx[2341] is the actual flame, with its own Camera_Main.
//      Wuhun.lua:325-327 calls SetFakeObject("") / KFS_UpdateKFSModel() / SetFakeObject("My_Wuhun"); the avatar
//      "My_Wuhun" itself is created in CDataPool::Initial next to My_Pet (GMDataPool.cpp, as CY 0x1400e6149).
//
//   2. CYS_MESHWIN_LIVE=1 probe of the live GUI smoke (CysGlLoginSmoke case 52, after the host-2 probe): opens
//      SelfEquip (OPEN_EQUIP), Pet (TOGLE_PET_PAGE) and Wuhun (ToggleWuhunPage), logs whether each model window is
//      bound to a fake object, shoots the screen (mw-selfequip / mw-pet / mw-wuhun) and closes them again.
//      With CYS_MESHWIN_DUMP=1 Render.dll also writes the render textures themselves (..\ScreenShots\mw-rtt-*.png).
//
// Registered (forced) from CysModernGame after a world session starts, like CysHostHost2.
#include "LuaPlus.h"

namespace CysMeshWinHost
{
    int Register(LuaPlus::LuaState* state);   // returns how many host functions were (re)registered
    void RegisterHost();                      // resolves the Lua state from CScriptSystem
    int WuhunModelId(int itemTableId, int wuhunLevel);   // KFSBase lookup; -1 = unknown item / no table
    bool UpdateWuhunModel();                  // the body of DataPool:KFS_UpdateKFSModel
}

namespace CysMeshWinProbe
{
    bool Tick();   // true when off or finished (same contract as CysHostHost2::Tick)
}
