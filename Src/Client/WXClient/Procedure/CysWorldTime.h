#pragma once

// CYS-SKY (sky-enscene, Docs/specs/render/sky-enscene-cy_vi.md §3.1): world time of the sky as CY 3.71 Game.exe does it.
//   GCWorldTime (CY id 349 / skynet 472, handler FUN_1405420a0): u32 WorldTime -> variable "WorldTime",
//   i32 counter (ms of the day) -> DAT_1410393dc, f32 interval -> variable "NewWorldTime_Interval"; applied at once
//   when the main procedure exists (FUN_14064d030).
//   CGamePro_Main tick (FUN_14064a0a0): every View_SkyBoxRefreshTime ms (CY 3000) with interval > 0:
//   counter = (counter + elapsed_ms * interval) % 86400000, then FUN_14064d030.
//   FUN_14064d030: fraction = clamp(counter / 8.64e7, 0.01, 0.99), gfx vtable +0x350 (Render.dll FUN_18002e3d0)
//   with (localtime().tm_mday, fraction); 0.5 instead when the flag at DAT_14102f080 + 0x5efa00 is set.
namespace CysWorldTime
{
void OnPacket(unsigned worldTime, int counterMs, float interval);
void Tick();
}
