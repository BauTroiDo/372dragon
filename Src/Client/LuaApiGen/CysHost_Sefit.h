#pragma once
// CYS-SEFIT: host functions whose GENERATED stub answers with the wrong SHAPE, found by walking the
// character frame (SelfEquip) failure chain on real user sessions.
//
// THE BUG CLASS (one mechanism, several victims):
//
// LuaApiGen answers a missing host function according to a `rets` spec recovered by a generator.
// When that spec is "o" the stub returns the shared NULL OBJECT - a table whose __index hands back a
// C closure for every field. That is right for a function that only exists to be chained
// (a:b():c()), and WRONG for any function whose result is used as DATA, because:
//
//     x ~= nil        -> TRUE   (a null object is a table)  => every nil-guard is defeated
//     x.field >= 1    -> THROWS "attempt to compare number with function"
//     x <= 129        -> THROWS "attempt to compare table with number"
//     if x.field then -> ALWAYS TRUE (a function is truthy) => silent logic bug
//
// One throw kills the whole Lua call, so every :SetText() after it never runs and the frame keeps the
// design-time placeholder text of its .layout.xml. That is why the character frame showed "99999" and
// blanks instead of the character's real numbers.
//
// ---- victim 1: WGAch:GetCJMaxCur  (LuaApiGen_Cy.cpp, rets "o") ----------------------------------
// Measured 19/09 20:15-20:16 (Build/Logs/2026-09-19-user-play-1/WXClient.log 598/701/902/1195),
// four opens, four throws:
//     SelfEquip.lua:1464  local cur = WGAch:GetCJMaxCur()
//     SelfEquip.lua:1465  if cur ~= nil and cur.cur_level >= 1 and ... then
//         -> "attempt to compare number with function"
//
// SIGNATURE: ONE return value, a TABLE. Proven by the call sites themselves - every one of the five
// files binds a single variable and then indexes it (`cur.cur_level`, `curData.param0`, ...). It is
// NOT a multi-return (max, cur) pair: with two returns the first would be a number and nobody would
// index it. Returning nil instead of a table would fix SelfEquip and Pretty_Shop:172 but break the
// four sites that index the result with no nil check, so the fix is a zero-filled record.
// Fields read by the CY 3.71 scripts (measured across all five call-site files):
//     cur_level  cur_value  max_level  max_value  name  param0  param1
//
// ---- victim 2: _G:Lua_GetMyMaxLevelLimit  (LuaApiGen_Cy.cpp:3287, rets "o") ----------------------
// Measured 19/09 22:44 and 22:47 (Build/Logs/2026-09-19-user-play-2/WXClient.log 539/1849) on a build
// that ALREADY carried the victim-1 fix. The throw moved 15 lines down, which is how we know victim 1
// was really fixed:
//     SelfEquip.lua:3039  LEVEL_MAX_ENABLE = Lua_GetMyMaxLevelLimit()   -- in the frame's OPEN handler
//     SelfEquip.lua:1480  if( LEVEL_MAX_ENABLE <= nCompatPKLevel and ... ) then
//         -> "attempt to compare table with number"
// Note the operand order in that message: the TABLE is the LEFT operand, i.e. LEVEL_MAX_ENABLE
// itself - not the level value next to it. Line 3039 overwrites the script's own file-level local
// (declared `local LEVEL_MAX_ENABLE = 129` at line 65) with the null object every time the window
// opens. Line 1451 reads the same variable but survives, because `isCompatPKServer == 1` is false and
// `and` short-circuits before the comparison; line 1480 puts the comparison first, so it cannot.
//
// SIGNATURE: ONE return value, a NUMBER (a character level). Both callers use it numerically -
// SelfEquip.lua:3039 -> compared against a level, Quest.lua:3617 -> `local nMaxLevel = ...`.
// VALUE: 129, which is the script's OWN default for this variable (SelfEquip.lua:65,
// "目前允许的最高级为129"). This is not an invented number; it is what the frame uses when no special
// server mode applies. A real implementation should read the server's configured cap instead.
#include "LuaPlus.h"

namespace CysHostSefit
{
    // Registers the real host functions over the generated stubs. Must run BEFORE
    // LuaApiGen::RegisterAll / RegisterCyExtras so IsMissing() keeps the stubs out.
    // Returns the number of functions registered.
    int Register(LuaPlus::LuaState* state);

    // The level cap reported to the UI scripts. Exposed so the test names one number, not two.
    int MaxLevelLimit();
}
