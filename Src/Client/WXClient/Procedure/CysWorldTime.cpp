#include "StdAfx.h"
#include "CysWorldTime.h"
#include "GameProcedure.h"
#include "../WXRender/RenderSystem.h"
#include "CysLoginSceneBridge.h"
#include "TDTimeSystem.h"
#include "TDVariable.h"
#include "TDUtil.h"
#include <ctime>
#include <cstdlib>

namespace CysWorldTime
{
namespace
{
int counterMs = 0;          // DAT_1410393dc
unsigned lastTick = 0;      // DAT_1410393e0
bool received = false;

// FUN_14064d030
void Apply()
{
    if (!CGameProcedure::s_pGfxSystem) return;
    float fraction = static_cast<float>(counterMs) / 8.64e7f;
    if (fraction > 0.99f) fraction = 0.99f;
    else if (fraction < 0.01f) fraction = 0.01f;
    const time_t now = time(NULL);
    const tm* local = localtime(&now);
    const int day = local ? local->tm_mday : 1;
    // Test override: CYS_WORLD_TIME=<hours> pins the sky clock (the CY noon flag at +0x5efa00 gives 0.5).
    if (const char* pin = getenv("CYS_WORLD_TIME"))
        fraction = static_cast<float>(atof(pin) / 24.0);
    HMODULE module = GetModuleHandleA("Render.dll");
    if (!module) module = GetModuleHandleA("WXRender.dll");
    const auto set = module ? reinterpret_cast<CysLoginSceneBridge::SkyTime>(
        GetProcAddress(module, "CysSceneSetTime")) : NULL;
    if (!set || !set(CGameProcedure::s_pGfxSystem, day, fraction))
        TDU_Log("CYS world time: sky time bridge unavailable");
}
}

void OnPacket(unsigned worldTime, int counter, float interval)
{
    // FUN_1405420a0
    if (CGameProcedure::s_pVariableSystem)
    {
        CGameProcedure::s_pVariableSystem->SetAs_Int("WorldTime", static_cast<INT>(worldTime), TRUE);
        CGameProcedure::s_pVariableSystem->SetAs_Float("NewWorldTime_Interval", interval, TRUE);
    }
    counterMs = counter;
    lastTick = CGameProcedure::s_pTimeSystem ? CGameProcedure::s_pTimeSystem->GetTimeNow() : 0;
    TDU_Log("CYS world time: GCWorldTime WorldTime=%u counter=%d ms (%.3f h) interval=%.3f", worldTime, counter,
        counter / 3.6e6, interval);
    received = true;
    if (CGameProcedure::s_pProcMain)
        Apply();
}

void Tick()
{
    // FUN_14064a0a0: View_SkyBoxRefreshTime (CY System.cfg 3000) and NewWorldTime_Interval > 0
    if (!received || !CGameProcedure::s_pTimeSystem || !CGameProcedure::s_pVariableSystem) return;
    const unsigned now = CGameProcedure::s_pTimeSystem->GetTimeNow();
    BOOL have = FALSE;
    INT refresh = CGameProcedure::s_pVariableSystem->GetAs_Int("View_SkyBoxRefreshTime", &have);
    if (!have) refresh = 3000;
    if (now - lastTick <= static_cast<unsigned>(refresh < 0 ? 0 : refresh)) return;
    const float interval = CGameProcedure::s_pVariableSystem->GetAs_Float("NewWorldTime_Interval");
    if (!(interval > 0.0f)) return;
    counterMs = static_cast<int>((static_cast<long long>(static_cast<float>(now - lastTick) * interval) + counterMs) % 86400000);
    lastTick = now;
    Apply();
}
}
