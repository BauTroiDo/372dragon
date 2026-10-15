#pragma once
// CYS-SKILL: scripted GUI turn of the skill module inside a live world session (CysGlLoginSmoke mode World, after the
// CysWorldReplay camera/walk script and the inventory driver). Enabled by CYS_SKILL_LIVE=1; otherwise Tick() returns
// true at once. Steps: CY skill book (TOGLE_SKILL_BOOK; common page without xinfa) -> drag the F1 item off the quick bar
// -> drag the skill (CYS_SKILL_ID, default 0 = normal attack) from the book onto F1 with injected CEGUI mouse events ->
// Tab (nearest enemy, CY target frame) -> F1 until the target dies (effect, damage numbers, cooldown) -> optional second
// skill with a server cooldown on F2 (CYS_SKILL_ID2) and removal again. Every step logs "CYS skill-live:" and takes a
// cys-live-*-skill-* PNG after resetting the camera to the classic view.
namespace CysSkillDriver
{
    // true when the driver finished (or is disabled); false while it still runs.
    bool Tick();
}
