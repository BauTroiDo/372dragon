#pragma once
// CYS-WARD2 19/09 (branch wardrobe-2): the CLIENT-SIDE state the CY wardrobe (NewExterior_*) needs in order to
// (a) list the player's fashions and (b) show a fashion the player has NOT put on yet - "try it on".
//
// Two pieces live here:
//
//   1. FASHION DEPOT (时装仓库). CY asks FashionDepot:LuaFnGetFashionDepotItem(kho, i) for an ACTION ITEM and calls
//      theAction:GetID() on it (NewExterior_DressBox.lua:1050). The generated stub answered two numbers, so the
//      call cut the Lua handler before NewExterior_DressBox_UpdateObj() could attach the model (branch `wardrobe`,
//      handoff 3.3b). The depot here is built from what the CLIENT actually knows: the fashion worn at equip point
//      16 (HEQUIP_DRESS) plus every equip-point-16 item in the bag. The server keeps a bigger one
//      (character.fashion_bag_list in Mongo) that no packet brings down yet - see the handoff, mục 5.
//
//   2. FITTING SET (试穿). Exterior:LuaFnSetCurrentExteriorSetInfo(key, id, idx) / LuaFnGetCurrentExteriorSetInfo(key)
//      are the pair every NewExterior_* frame uses to remember what the player is currently trying on, and
//      Exterior:LuaFnUpdateExteriorPlayerData() lays that set over the player's real appearance on the wardrobe
//      avatar. CY does the same: its LuaFnUpdateExteriorPlayerData (0x1403d5da0) is SetFakeObjDataEx's worker
//      followed by a second half that reads the fitting object at [0x14102f080]+0x6818c8
//      (Build\Logs\2026-09-19-meshwindow-ex\re\cy-wardrobe-addresses.md mục 3/4). This is that second half.
//
// The avatar composition hooks (RaceIdFor / ApplyFitting) are called from CysMeshWinHost::CopyMySelfAppearance so
// that the ONE function that builds every wardrobe avatar stays in one place.
#include "LuaPlus.h"
#include "CysWardrobeCatalog.h"

class CObject_Character;

namespace CysWardrobeHost
{
    int  Register(LuaPlus::LuaState* state);   // how many host functions were (re)registered
    void RegisterHost();                       // resolves the Lua state from CScriptSystem

    // ---- avatar composition (called by CysMeshWinHost::CopyMySelfAppearance) ----
    // The race id the wardrobe avatar must be built with: the previewed sex when the frame set one
    // ("SEX" key, CY LuaFnGetExteriorRaceID 0x1403eaef0 reads [fitting+0x30] first), else the player's own.
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
