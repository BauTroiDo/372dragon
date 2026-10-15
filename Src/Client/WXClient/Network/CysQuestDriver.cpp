#include "StdAfx.h"
#include "CysQuestDriver.h"

#if defined(CYS_HAVE_NETCORE)
#include "CysQuestNet.h"
#include "CysInventoryNet.h"
#include "CysModernGame.h"
#include "CysWorldReplay.h"
#include "CysUiInputBridge.h" // CYS-QUEST: scroll the NPC text to its end for the dialogue variable evidence
#include "TDEventDefine.h"
#include "TDUtil.h"
#include "TDUISystem.h"
#include "..\Procedure\GameProcedure.h"
#include "..\Object\ObjectManager.h"
#include "..\Object\Character\Obj_PlayerMySelf.h"
#include "..\DataPool\GMUIDataPool.h"
#include "..\DataPool\GMDP_CharacterData.h"
#include "..\DataPool\DetailAttrib_Player.h"
#include "..\Event\GMEventSystem.h"
#include "..\World\WorldManager.h"
#include "..\Interface\GMGameInterface.h"
#include "NetManager.h"
#include "CGCharDefaultEvent.h"
#include <cstdarg>
#include <cstdio>
#include <cstdlib>
#include <cstring>

namespace
{
    enum Step { Off, Begin, Talk, Menu, InfoWait, AcceptWait, DemandWait, ContinueWait, SubmitWait, TravelWait, ScrollEnd, ReturnClickWait, Approach, Finish, Done };
    enum Goal { GoalComplete, GoalAccept, GoalTravel, GoalReturn, GoalNone };
    struct Station { bool set = false; float x = 0, z = 0; int option = 0; };
    struct State
    {
        bool evaluated = false;
        Step step = Off;
        Goal goal = GoalNone;
        DWORD at = 0;
        float npcX = 160.0f, npcZ = 158.0f;  // Trieu Thien Su (dali_new_320_monster.ini, script 2030)
        int completeScript = -1, acceptScript = -1;
        Station travel, back;
        unsigned base = 0, base2 = 0, pages = 0, demands = 0; // CYS-QUEST: pages/demands = event lists / cmd 3 before the option click
        int sceneBefore = -1;
        bool leftWorld = false;
        int expBefore = 0;
        unsigned npcServer = 0;
        unsigned passed = 0, failed = 0;
        bool npcNear = false;
        unsigned clicks = 0;
        unsigned travelRounds = 0, roundsDone = 0;
        float clickFromX = 0, clickFromZ = 0;
    };
    State& S() { static State s; return s; }

    void Log(const char* fmt, ...)
    {
        char text[512] = {};
        va_list args; va_start(args, fmt);
        _vsnprintf(text, sizeof(text) - 1, fmt, args);
        va_end(args);
        TDU_Log("CYS quest-live: %s", text);
    }
    void Go(Step next, const char* why) { S().step = next; S().at = GetTickCount(); Log("step %d: %s", (int)next, why); }
    DWORD Age() { return GetTickCount() - S().at; }
    bool Shown(const char* window) { return CGameProcedure::s_pUISystem && CGameProcedure::s_pUISystem->IsWindowShow(window); }
    void Shot(const char* label) { CysWorldReplay::LiveShot(label); }
    int Exp()
    {
        CObject_PlayerMySelf* self = CObjectManager::GetMe() ? CObjectManager::GetMe()->GetMySelf() : nullptr;
        return self ? self->GetCharacterData()->Get_Exp() : 0;
    }
    int Scene() { return CWorldManager::GetMe() ? CWorldManager::GetMe()->GetActiveSceneID() : -1; }
    int MissionCount() { const CDetailAttrib_Player* p = CUIDataPool::GetMe() ? CUIDataPool::GetMe()->GetMySelfDetailAttrib() : nullptr; return p ? p->GetMission_Num() : -1; }

    bool ReadStation(const char* name, Station& out)
    {
        char text[64] = {};
        if (GetEnvironmentVariableA(name, text, sizeof(text)) == 0) return false;
        out.set = sscanf(text, "%f,%f,%d", &out.x, &out.z, &out.option) == 3;
        return out.set;
    }

    // Next goal after `after` (order: hand in, accept, travel, way back).
    Goal NextGoal(Goal after)
    {
        const State& s = S();
        const int a = after == GoalNone ? -1 : (int)after;
        if (a < GoalComplete && s.completeScript > 0) return GoalComplete;
        if (a < GoalAccept && s.acceptScript > 0) return GoalAccept;
        if (a < GoalTravel && s.travel.set) return GoalTravel;
        if (a < GoalReturn && s.back.set && s.travel.set) return GoalReturn;
        return GoalNone;
    }

    void StartGoal(Goal goal)
    {
        State& s = S();
        s.goal = goal;
        if (goal == GoalNone) { Go(Finish, "all goals done"); return; }
        if (goal == GoalTravel) { s.npcX = s.travel.x; s.npcZ = s.travel.z; }
        if (goal == GoalReturn) { s.npcX = s.back.x; s.npcZ = s.back.z; }
        // Quest requests, like transfer requests, require a real nearby NPC.
        // Use the ordinary navmesh movement path before opening the dialogue.
        if (!s.npcNear)
        {
            CObject_PlayerMySelf* self = CObjectManager::GetMe()->GetMySelf();
            if (self)
            {
                const fVector3 p = self->GetPosition();
                const float dx = p.x - s.npcX, dz = p.z - s.npcZ;
                if (dx*dx + dz*dz > 25.0f)
                {
                    CGameProcedure::s_pGameInterface->Player_MoveTo(fVector2(s.npcX, s.npcZ));
                    Go(Approach, "walk to the quest NPC");
                    return;
                }
            }
        }
        Go(Talk, goal == GoalComplete ? "hand in" : goal == GoalAccept ? "accept" : goal == GoalTravel ? "travel" : "return");
    }

    void Fail(const char* why) { ++S().failed; Log("FAIL %s", why); StartGoal(NextGoal(S().goal)); }
}

bool CysQuestDriver::Tick()
{
    State& s = S();
    if (!s.evaluated)
    {
        s.evaluated = true;
        char text[64] = {};
        if (GetEnvironmentVariableA("CYS_QUEST_LIVE", text, sizeof(text)) == 1 && text[0] == '1') { s.step = Begin; s.at = GetTickCount(); }
        if (GetEnvironmentVariableA("CYS_QUEST_NPC", text, sizeof(text)) > 0)
        {
            if (strcmp(text, "near") == 0) s.npcNear = true; // offline replay: any object next to the player
            else sscanf(text, "%f,%f", &s.npcX, &s.npcZ);
        }
        if (GetEnvironmentVariableA("CYS_QUEST_COMPLETE", text, sizeof(text)) > 0) s.completeScript = atoi(text);
        if (GetEnvironmentVariableA("CYS_QUEST_ACCEPT", text, sizeof(text)) > 0) s.acceptScript = atoi(text);
        ReadStation("CYS_QUEST_TRAVEL", s.travel);
        ReadStation("CYS_QUEST_RETURN", s.back);
        if (GetEnvironmentVariableA("CYS_QUEST_TRAVEL_ROUNDS", text, sizeof(text)) > 0)
        {
            const int rounds = atoi(text);
            if (rounds >= 1 && rounds <= 3 && s.travel.set && s.back.set) s.travelRounds = (unsigned)rounds;
        }
        Log("driver %s npc=%.0f,%.0f complete=%d accept=%d travel=%d(%.0f,%.0f) return=%d(%.0f,%.0f)", s.step == Begin ? "enabled" : "disabled",
            s.npcX, s.npcZ, s.completeScript, s.acceptScript, s.travel.option, s.travel.x, s.travel.z, s.back.option, s.back.x, s.back.z);
    }
    if (s.step == Off || s.step == Done) return true;
    // A transfer leaves the world for a moment: only the travel step waits through it.
    if (!CysModernGame::IsInWorld() && s.step != TravelWait) { Log("left the world at step %d", (int)s.step); s.step = Done; return true; }
    const CysQuestNet::Counters q = CysQuestNet::Get();
    const CysInventoryNet::Counters inv = CysInventoryNet::Get();
    switch (s.step)
    {
    case Begin:
        if (Age() < 2000) break;
        s.expBefore = Exp();
        Log("scene=%d missions=%d exp=%d MissionTrack shown=%d lists=%u", Scene(), MissionCount(), s.expBefore, Shown("MissionTrack") ? 1 : 0, q.missionLists);
        if (!Shown("MissionTrack")) CEventSystem::GetMe()->PushEvent(GE_OPEN_MISSION_TRACK, 1);
        Shot("quest-track-start");
        StartGoal(NextGoal(GoalNone));
        break;
    case Talk:
    {
        if (Age() < 800) break;
        float distance = 0;
        if (s.npcNear && s.goal != GoalTravel && s.goal != GoalReturn)
        {
            CObject_PlayerMySelf* self = CObjectManager::GetMe()->GetMySelf();
            if (self) { s.npcX = self->GetPosition().x; s.npcZ = self->GetPosition().z; }
            s.npcServer = CysModernGame::NearestObjectAt(s.npcX, s.npcZ, 80.0f, &distance);
        }
        else
        s.npcServer = CysModernGame::NearestObjectAt(s.npcX, s.npcZ, 6.0f, &distance);
        tObject* npc = s.npcServer ? CObjectManager::GetMe()->FindServerObject((INT)s.npcServer) : nullptr;
        if (!npc) { if (Age() > 6000) Fail("no NPC near the goal position"); break; }
        s.base = inv.eventLists;
        Log("CGCharDefaultEvent npc server=%u client=%d dist_to_point=%.1f scene=%d", s.npcServer, npc->GetID(), distance, Scene());
        CGCharDefaultEvent talk;
        talk.setObjID((ObjID_t)s.npcServer);
        CNetManager::GetMe()->SendPacket(&talk);
        Go(Menu, "CGCharDefaultEvent");
        break;
    }
    case Approach:
    {
        CObject_PlayerMySelf* self = CObjectManager::GetMe()->GetMySelf();
        if (!self) { Fail("no self while approaching quest NPC"); break; }
        const fVector3 p = self->GetPosition();
        const float dx = p.x - s.npcX, dz = p.z - s.npcZ;
        if (dx*dx + dz*dz <= 16.0f) Go(Talk, "arrived near quest NPC");
        else if (Age() > 45000) Fail("quest NPC approach timed out");
        break;
    }
    case Menu:
        if (inv.eventLists > s.base && Age() >= 1500)
        {
            Log("NPC dialogue Quest shown=%d", Shown("Quest") ? 1 : 0);
            int script = -1, index = -1;
            bool found = false;
            switch (s.goal)
            {
            case GoalComplete:
                Shot("quest-npc-dialog");
                found = CysQuestNet::FindOption(s.completeScript, 2, script, index) || CysQuestNet::FindOption(s.completeScript, -1, script, index);
                break;
            case GoalAccept:
                Shot("quest-npc-dialog-accept");
                found = CysQuestNet::FindOption(s.acceptScript, 1, script, index) || CysQuestNet::FindOption(s.acceptScript, -1, script, index);
                break;
            default:
                Shot(s.goal == GoalTravel ? "quest-station-dialog" : "quest-station-dialog-back");
                index = s.goal == GoalTravel ? s.travel.option : s.back.option;
                found = CysQuestNet::FindOptionByIndex(index, script);
                break;
            }
            if (!found) { Fail("the NPC menu has no option for the goal"); break; }
            Log("SendSelectEvent script=%d index=%d (QuestOption_Clicked -> QuestFrameOptionClicked)", script, index);
            if (s.goal == GoalTravel || s.goal == GoalReturn)
            {
                if (s.travelRounds) CysModernGame::LogStatsNow();
                s.sceneBefore = Scene(); s.leftWorld = false;
                CUIDataPool::GetMe()->SendSelectEvent(0, script, index);
                Go(TravelWait, "CGEventRequest (transfer)");
                break;
            }
            s.base = s.goal == GoalAccept ? q.missionInfos : q.missionDemands; s.base2 = q.missionContinues;
            s.pages = inv.eventLists; s.demands = q.missionDemands;
            CUIDataPool::GetMe()->SendSelectEvent(0, script, index);
            Go(s.goal == GoalAccept ? InfoWait : DemandWait, "CGEventRequest (mission)");
        }
        else if (Age() > 12000) Fail("no NPC menu within 12 s");
        break;
    case InfoWait:
        if (q.missionInfos > s.base && Age() >= 1500)
        {
            Log("mission info shown Quest=%d", Shown("Quest") ? 1 : 0);
            Shot("quest-info");
            s.base = q.missionAdds;
            CUIDataPool::GetMe()->SendAcceptEvent(); // QuestAccept_Clicked -> QuestFrameAcceptClicked
            Go(AcceptWait, "CGMissionAccept");
        }
        // CYS-QUEST: the option opened another NPC page (cmd 0) or the demand page of an accepted mission (cmd 3):
        // capture it (dialogue variables such as $N are expanded by the UI) and end the goal without accepting.
        else if ((inv.eventLists > s.pages || q.missionDemands > s.demands) && Age() >= 1500)
        {
            const bool page = inv.eventLists > s.pages;
            Log("option opened %s Quest=%d", page ? "another NPC page" : "the demand page", Shown("Quest") ? 1 : 0);
            Shot(page ? "quest-npc-dialog-next" : "quest-demand");
            s.clicks = 0;
            Go(ScrollEnd, "scroll the NPC text to its end");
        }
        else if (Age() > 8000) Fail("no mission info (GCScriptCommand 1) within 8 s");
        break;
    case AcceptWait:
        if (q.missionAdds > s.base && Age() >= 2500)
        {
            Log("accepted: missions=%d MissionTrack shown=%d", MissionCount(), Shown("MissionTrack") ? 1 : 0);
            Shot("quest-accepted-track");
            ++s.passed;
            StartGoal(NextGoal(GoalAccept));
        }
        else if (Age() > 8000) Fail("no GCMissionAdd within 8 s");
        break;
    case DemandWait:
        if (q.missionContinues > s.base2)
        {
            // accomplish NPC answers with the reward page at once (edali_zhidao_0200 OnDefaultEvent -> OnContinue)
            s.base = s.base2;
            Go(ContinueWait, "continue info without a demand page");
        }
        else if (q.missionDemands > s.base && Age() >= 1500)
        {
            Log("demand dialogue Quest=%d demands=%u", Shown("Quest") ? 1 : 0, q.missionDemands);
            Shot("quest-demand");
            s.base = q.missionContinues;
            CUIDataPool::GetMe()->SendContinueEvent(); // MissionContinue_Clicked (QUEST_STATE_CONTINUE_DONE)
            Go(ContinueWait, "CGMissionContinue");
        }
        else if (Age() > 8000) Fail("no demand dialogue within 8 s");
        break;
    case ContinueWait:
        if (q.missionContinues > s.base && Age() >= 1500)
        {
            Log("reward dialogue Quest=%d", Shown("Quest") ? 1 : 0);
            Shot("quest-reward");
            s.base = q.missionRemoves; s.base2 = q.doneFlags;
            CUIDataPool::GetMe()->SendCompleteEvent(0); // MissionContinue_Clicked (QUEST_STATE_AFTER_CONTINUE)
            Go(SubmitWait, "CGMissionSubmit");
        }
        else if (Age() > 8000) Fail("no continue info (GCScriptCommand 4) within 8 s");
        break;
    case SubmitWait:
        if ((q.missionRemoves > s.base || q.doneFlags > s.base2) && Age() >= 3000)
        {
            Log("completed: missions=%d exp %d -> %d removes=%u done_flags=%u", MissionCount(), s.expBefore, Exp(), q.missionRemoves, q.doneFlags);
            Shot("quest-completed");
            ++s.passed;
            StartGoal(NextGoal(GoalComplete));
        }
        else if (Age() > 9000) Fail("no GCMissionRemove within 9 s");
        break;
    case TravelWait:
        if (!CysModernGame::IsInWorld()) { s.leftWorld = true; if (Age() > 45000) { Log("FAIL transfer did not finish"); s.step = Done; return true; } break; }
        if (Scene() != s.sceneBefore && Scene() >= 0)
        {
            if (!s.at || Age() < 9000) break; // scene objects and the minimap settle
            Log("transferred scene %d -> %d (left world=%d)", s.sceneBefore, Scene(), s.leftWorld ? 1 : 0);
            Shot(s.goal == GoalTravel ? "quest-travel-arrived" : "quest-return-arrived");
            ++s.passed;
            if (s.travelRounds && s.goal == GoalReturn)
            {
                CObject_PlayerMySelf* self = CObjectManager::GetMe()->GetMySelf();
                if (!self) { Fail("no self after return"); break; }
                const fVector3 p = self->GetPosition();
                s.clickFromX = p.x; s.clickFromZ = p.z;
                Log("ROUND %u returned scene=%d pos=%.2f,%.2f ground-click BEGIN", s.roundsDone+1, Scene(), p.x, p.z);
                CysWorldReplay::LiveGroundClick(s.roundsDone+1);
                Go(ReturnClickWait, "verify movement after returning");
                break;
            }
            StartGoal(NextGoal(s.goal));
        }
        else if (Age() > 30000) Fail("no scene change within 30 s");
        break;
    case ReturnClickWait:
    {
        if (Age() < 4500) break;
        CObject_PlayerMySelf* self = CObjectManager::GetMe()->GetMySelf();
        if (!self) { Fail("no self after return click"); break; }
        const fVector3 p = self->GetPosition();
        const float dx = p.x - s.clickFromX, dz = p.z - s.clickFromZ;
        Log("ROUND %u ground-click END delta2=%.3f pos=%.2f,%.2f", s.roundsDone+1, dx*dx+dz*dz, p.x, p.z);
        CysModernGame::LogStatsNow();
        char label[48] = {}; _snprintf(label,sizeof(label)-1,"dali-round-%u",s.roundsDone+1); Shot(label);
        ++s.roundsDone;
        if (dx*dx+dz*dz < 0.25f) { ++s.failed; Go(Finish,"returned position cannot move"); }
        else if (s.roundsDone < s.travelRounds) StartGoal(GoalTravel);
        else StartGoal(GoalNone);
        break;
    }
    case ScrollEnd:
    {
        // Left clicks on the increase button of QuestGreeting_Desc's scroll bar (CysUiSmokePointer, smoke mode only).
        HMODULE ui = GetModuleHandleA("UI_CEGUI.dll");
        const CysUiInputBridge::GetWindowRectUtf8 rect = ui ? reinterpret_cast<CysUiInputBridge::GetWindowRectUtf8>(GetProcAddress(ui, "CysUiGetWindowRectUtf8")) : nullptr;
        const CysUiInputBridge::SmokePointer pointer = ui ? reinterpret_cast<CysUiInputBridge::SmokePointer>(GetProcAddress(ui, "CysUiSmokePointer")) : nullptr;
        float r[4] = {};
        const bool haveButton = rect && rect("QuestGreeting_Desc__auto_vscrollbar____auto_incbtn__", r) && r[2] > 0 && r[3] > 0;
        if (!pointer || !haveButton || s.clicks >= 40)
        {
            if (Age() < 600 && s.clicks) break;
            Log("scrolled clicks=%u pointer=%d button=%d", s.clicks, pointer ? 1 : 0, haveButton ? 1 : 0);
            Shot("quest-npc-dialog-end");
            ++s.passed;
            StartGoal(NextGoal(s.goal));
            break;
        }
        if (Age() < 60) break;
        const float x = r[0] + r[2] * 0.5f, y = r[1] + r[3] * 0.5f;
        pointer(0, x, y); pointer(1, x, y); pointer(2, x, y);
        ++s.clicks;
        s.at = GetTickCount();
        break;
    }
    case Finish:
        if (Age() < 800) break;
        Log("%s quest live script passed=%u failed=%u (infos=%u demands=%u continues=%u adds=%u removes=%u accepts=%u submits=%u)",
            s.failed ? "PARTIAL" : "PASS", s.passed, s.failed, q.missionInfos, q.missionDemands, q.missionContinues, q.missionAdds, q.missionRemoves, q.accepts, q.submits);
        s.step = Done;
        return true;
    default:
        break;
    }
    return false;
}

#else
bool CysQuestDriver::Tick() { return true; }
#endif
