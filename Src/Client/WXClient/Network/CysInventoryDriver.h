#pragma once
// CYS-INV: scripted GUI turn of the inventory module inside a live world session (CysGlLoginSmoke mode World,
// after the CysWorldReplay camera/walk script). Enabled by CYS_INV_LIVE=1; otherwise Tick() returns true at once.
// Steps: bag window (TOGLE_CONTAINER) -> item tooltip -> SelfEquip window (OPEN_EQUIP) -> equip / unequip / re-equip
// through the action items (the right-click path of the CY windows) -> talk to the Dali merchant -> shop option ->
// buy one item from the booth. Every step logs "CYS inv-live:" and takes a cys-live-inv-* PNG.
namespace CysInventoryDriver
{
    // true when the driver finished (or is disabled); false while it still runs.
    bool Tick();
}
