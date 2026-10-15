#include "StdAfx.h"
#include "CysReviveDriver.h"

#if defined(CYS_HAVE_NETCORE)

#include "CysModernGame.h"
#include "CysWorldReplay.h"
#include "GameStruct_Skill.h"
#include "TDUtil.h"
#include "..\Procedure\GameProcedure.h"
#include "..\Object\ObjectManager.h"
#include "..\Object\Character\Obj_PlayerMySelf.h"
#include "..\DataPool\GMDataPool.h"
#include <cmath>
#include <cstdarg>
#include <cstdio>
#include <cstdlib>
#include <cstring>

namespace
{
    enum Step { Off, Begin, MoveBefore, MoveBeforeWait, Dispel, DispelWait, MoveAfter, MoveAfterWait, Finish, Done };

    struct State
    {
        bool evaluated = false;
        Step step = Off;
        DWORD at = 0;
        int targetBuff = 59901;   // 地府束缚
        int buffsBefore = -1, buffsAfter = -1;
        int targetIndex = -1;
        bool dispelSent = false;
        bool stillThere = true;
        float fromX = 0, fromZ = 0;
        float movedBefore = -1.0f, movedAfter = -1.0f;
    };
    State& S() { static State s; return s; }

    void Log(const char* fmt, ...)
    {
        char text[512] = {};
        va_list args; va_start(args, fmt);
        _vsnprintf(text, sizeof(text) - 1, fmt, args);
        va_end(args);
        TDU_Log("CYS revive-live: %s", text);
    }
    void Go(Step next, const char* why) { S().step = next; S().at = GetTickCount(); Log("step %d: %s", (int)next, why); }
    DWORD Age() { return GetTickCount() - S().at; }

    CObject_PlayerMySelf* Me()
    {
        return CObjectManager::GetMe() ? CObjectManager::GetMe()->GetMySelf() : NULL;
    }

    // Walk the own buff pool the way PlayerImpactFrame_Update does (GetBuffNumber + per-index reads) and log every
    // entry. Returns the count, and puts the index of `want` into outIndex (-1 when it is not there).
    // CDataPool::BuffImpact_GetByID is not usable here: its guard is `size() > nID`, so for a five-digit buff id on a
    // two-entry pool it always returns NULL. Scan by index instead.
    int DumpBuffs(const char* when, int want, int* outIndex)
    {
        if (outIndex) *outIndex = -1;
        CDataPool* pool = CDataPool::GetMe();
        if (!pool) { Log("%s: no CDataPool", when); return -1; }
        const int count = pool->BuffImpact_GetCount();
        Log("%s: buffs=%d", when, count);
        for (int i = 0; i < count; ++i)
        {
            const _BUFF_IMPACT_INFO* info = pool->BuffImpact_GetByIndex(i);
            if (!info) continue;
            Log("%s: [%d] buff_id=%d sn=%u skill=%d timer=%d receiver=%d sender=%d", when, i, (int)info->m_nBuffID,
                info->m_nSN, (int)info->m_nSkillID, info->m_nTimer, (int)info->m_nReceiverID, (int)info->m_nSenderID);
            if (outIndex && (int)info->m_nBuffID == want && *outIndex < 0) *outIndex = i;
        }
        return count;
    }

    float MovedSince()
    {
        CObject_PlayerMySelf* self = Me();
        if (!self) return -1.0f;
        const float dx = self->GetPosition().x - S().fromX;
        const float dz = self->GetPosition().z - S().fromZ;
        return std::sqrt(dx * dx + dz * dz);
    }

    void MarkFrom()
    {
        CObject_PlayerMySelf* self = Me();
        if (!self) return;
        S().fromX = self->GetPosition().x;
        S().fromZ = self->GetPosition().z;
    }
}

bool CysReviveDriver::Tick()
{
    State& s = S();
    if (!s.evaluated)
    {
        s.evaluated = true;
        char text[64] = {};
        if (GetEnvironmentVariableA("CYS_REVIVE_LIVE", text, sizeof(text)) == 1 && text[0] == '1') { s.step = Begin; s.at = GetTickCount(); }
        if (GetEnvironmentVariableA("CYS_REVIVE_BUFF", text, sizeof(text)) > 0) s.targetBuff = atoi(text);
        Log("driver %s target_buff=%d", s.step == Begin ? "enabled" : "disabled", s.targetBuff);
    }
    if (s.step == Off || s.step == Done) return true;
    if (!CysModernGame::IsInWorld()) { Log("left the world at step %d", (int)s.step); s.step = Done; return true; }

    switch (s.step)
    {
    case Begin:
        if (Age() < 1500) break;
        s.buffsBefore = DumpBuffs("before", s.targetBuff, &s.targetIndex);
        CysWorldReplay::LiveShot("revive-buffs-before");
        Log("target buff %d found at index %d", s.targetBuff, s.targetIndex);
        MarkFrom();
        Go(MoveBefore, "probe movement while the buff is still on");
        break;

    case MoveBefore:
        // POSITIVE CONTROL: with CanMove = 0 the server drops the move, so this delta must stay ~0. If it does not,
        // the character was not blocked and the turn proves nothing about a stuck one - say so instead of claiming a fix.
        CysWorldReplay::LiveGroundClick(1);
        Go(MoveBeforeWait, "ground click 1 sent");
        break;

    case MoveBeforeWait:
        if (Age() < 3000) break;
        s.movedBefore = MovedSince();
        Log("moved_before=%.2f (expected ~0 while CanMove = 0)", s.movedBefore);
        CysWorldReplay::LiveShot("revive-move-before");
        Go(Dispel, "cancel the buff the way MouseRClick does");
        break;

    case Dispel:
        if (s.targetIndex < 0)
        {
            Log("target buff %d is NOT in the own buff pool; nothing to right-click", s.targetBuff);
            Go(Finish, "no target buff");
            break;
        }
        // Exactly what PlayerImpactFrame_ImageN_Click does through Player:DispelBuffByIndex.
        s.dispelSent = CDataPool::GetMe()->BuffImpact_DispelByIndex(s.targetIndex) ? true : false;
        Log("BuffImpact_DispelByIndex(%d) returned %d (CGDispelBuffReq 651 -> pg 657)", s.targetIndex, s.dispelSent ? 1 : 0);
        MarkFrom();
        Go(DispelWait, "wait for the server answer (GCDetailBuff enable=0)");
        break;

    case DispelWait:
        if (Age() < 2500) break;
        {
            int after = -1;
            s.buffsAfter = DumpBuffs("after", s.targetBuff, &after);
            s.stillThere = after >= 0;
            s.targetIndex = after;
        }
        CysWorldReplay::LiveShot("revive-buffs-after");
        MarkFrom();
        Go(MoveAfter, "probe movement again");
        break;

    case MoveAfter:
        CysWorldReplay::LiveGroundClick(2);
        Go(MoveAfterWait, "ground click 2 sent");
        break;

    case MoveAfterWait:
        if (Age() < 3000) break;
        s.movedAfter = MovedSince();
        CysWorldReplay::LiveShot("revive-move-after");
        Go(Finish, "done");
        break;

    case Finish:
        Log("VERDICT target_buff=%d buffs_before=%d found_before=%d moved_before=%.2f dispel_sent=%d buffs_after=%d still_there=%d moved_after=%.2f",
            s.targetBuff, s.buffsBefore, s.buffsBefore >= 0 && s.movedBefore >= 0 ? 1 : 0, s.movedBefore,
            s.dispelSent ? 1 : 0, s.buffsAfter, s.stillThere ? 1 : 0, s.movedAfter);
        s.step = Done;
        return true;

    default:
        break;
    }
    return false;
}

#else
bool CysReviveDriver::Tick() { return true; }
#endif
