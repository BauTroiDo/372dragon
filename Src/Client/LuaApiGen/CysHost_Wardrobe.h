#pragma once





















#include "LuaPlus.h"
#include "CysWardrobeCatalog.h"

class CObject_Character;

namespace CysWardrobeHost
{
    int  Register(LuaPlus::LuaState* state);   // how many host functions were (re)registered
    void RegisterHost();                       // resolves the Lua state from CScriptSystem




    int  RaceIdFor(const char* objectName, int selfRaceId);
    // Lay the fitting over an avatar whose fields were just copied from MySelf. No-op when nothing is being
    // tried on, so an empty fitting leaves the avatar byte for byte what branch `wardrobe` measured.
    void ApplyFitting(const char* objectName, CObject_Character* dst);

    // ---- the server's own depot ----
    // GCAskFashionDepotData (id 590) is the answer to CGAskFashionDepotData (1316): scenecore.lua
    // send_char_fashion_depot_data fills a FIXED 100-slot array where an empty slot has item_index 0 and the
    // fashion being worn sits at the character's fashion_depot_index - i.e. the array index IS the nVecIndex the
    // CY list uses. When it arrives it replaces the bag-derived guess. Fed from CysInventoryNet::Dispatch so the
    // pg:: types stay out of this header.
    void SetServerDepot(const int* itemIds, const int* visuals, int count);
    bool HaveServerDepot();

    // ---- evidence / probe ----
    int  DepotCount();      // fashions the depot holds right now (server array size, or the bag-derived count)
    int  DepotFilled();     // of those, how many are a real fashion (item != 0)
    int  FittingCount();    // keys of the fitting set that are on
    int  AppliedCount();    // times ApplyFitting actually changed a field
    int  PickRow();         // CY list row (1-based) of the first fashion that is NOT the one being worn; 0 = none
}

// CYS-WARD3 20/09 (nhanh `wardrobe`): probe do CHINH CAI NUT cua nguoi choi (SelfEquip_Yirong_Icon), khong day
// su kien thay no. Bat bang CYS_WARD3_LIVE=1; ve A cua phep do bat bang CYS_WARD3_OFF=1.
namespace CysWard3Probe
{
    bool Tick();
}
