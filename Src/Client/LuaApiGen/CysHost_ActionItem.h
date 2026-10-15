#pragma once
// CYS-UIFRAMES: DataPool:CreateActionItemForShow / CreateBindActionItemForShow.
//
// WHY THIS IS THE HIGHEST-LEVERAGE HOST FILE IN THE TREE
// -----------------------------------------------------
// These two names are called from 419 CY frames, 958 call sites. Until they exist, every one of
// those windows draws an EMPTY item cell, and most of them also throw and lose the rest of their
// update function. They are the single choke point for "item icon" in shops, reward lists, gift
// boxes, treasure boxes, the quest log and the wardrobe.
//
// THE SIGNATURE WAS MEASURED, NOT GUESSED
// ---------------------------------------
// Build/Logs/2026-09-19-ui-frames/scan/actionitem-census.json counts ALL 958 call sites:
//
//     return values taken by the script : 1  in 957 sites, 0 in 1        -> return exactly 1
//     arguments passed                  : 2  in 957 sites               -> (itemDefineId, count)
//     method surface on the returned value, complete, not a sample:
//         GetID                2376 uses
//         GetName               100 uses
//         GetItemColorInShop      4 uses
//     GetNum : never called -> the count argument is not observable through the object anywhere,
//              so it is deliberately not stored.
//
// The generated stub declared `"ob"` (two values). That is WRONG by measurement: 957 of 958 sites
// bind one. This is the same mistake class that cost `selfequip-fit` two rounds - a signature
// inferred from the function name instead of read off the call sites.
//
// WHY A REAL OBJECT, AND NOT nil
// ------------------------------
// The branch rule "returning nil is safer than returning a null object" is TRUE ONLY WHERE THE
// CALL SITES GUARD WITH `~= nil`. Measured here (same census, `guard_forms`):
//
//     sites guarding with `theAction:GetID() ~= 0`   : the CY idiom, by far the common one
//     sites guarding with `theAction ~= nil`         : 96
//     sites with no guard at all                     : the rest - they call :GetID() immediately
//
// So nil would throw "attempt to index a nil value" in every unguarded site. The correct answer is
// the one the engine already ships: hand Lua a REAL CActionItem, and when the item id resolves to
// nothing hand it CActionItem::s_InvalidAction, whose GetID() is 0 (CActionItem(INT id=0)) - which
// is exactly what `if theAction:GetID() ~= 0 then` was written to test. Same shape as the engine's
// own Lua_EnumAction (GMGameInterface_Script.cpp:755-767).
//
// THIS IS THE SAME DISEASE AS SelfEquip:1465/:1480, THIRD SHAPE
// ------------------------------------------------------------
// The null object's __index hands back NullCall, which returns ZERO values. So on a stubbed
// CreateActionItemForShow, `theAction:GetID()` yields no value -> Lua pads to nil -> `nil ~= 0` is
// TRUE -> the CY guard is defeated (again) -> SetActionItem(nil) draws nothing and the following
// `.."..theAction:GetName()` concatenates nil and throws. Wrong RETURN COUNT, the shape that is
// easiest for a scanner to miss.
//
// Storage and lifetime live in CActionSystem::CreateActionForShow (GMActionSystem.cpp), which keeps
// one action per define id so a window calling this every frame does not grow the action map.
#include "LuaPlus.h"

namespace CysHostActionItem
{
    // Registers both names; returns how many were registered. Idempotent, main thread only.
    int Register(LuaPlus::LuaState* state);
    // Same, resolving the Lua state from CScriptSystem (call site: CysModernGame).
    void RegisterHost();
    // Evidence runs only: resolve an item define id to a display action id without going through
    // Lua. Returns 0 when the id is in no item table - the same 0 Lua would see from GetID().
    int ProbeShowActionId(int itemDefineId);
}
