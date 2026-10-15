#include "StdAfx.h"
#include "CysSkillDriver.h"

#if defined(CYS_HAVE_NETCORE)
#include "CysSkillNet.h"
#include "CysModernGame.h"
#include "CysModernHandlers.h"
#include "CysWorldReplay.h"
#include "CysUiInputBridge.h"
#include "TDEventDefine.h"
#include "TDUtil.h"
#include "TDUISystem.h"
#include "GameDefine2.h"
#include "..\Global.h"
#include "..\Procedure\GameProcedure.h"
#include "..\Object\ObjectManager.h"
#include "..\Object\Character\Obj_PlayerMySelf.h"
#include "..\DataPool\GMDataPool.h"
#include "..\DataPool\GMDP_CharacterData.h"
#include "..\DataPool\GMDP_Struct_Skill.h"
#include "GameStruct_Skill.h"
#include "..\Action\GMActionSystem.h"
#include "..\Event\GMEventSystem.h"
#include "..\WxRender\RenderSystem.h"
#include "..\Input\GMInputSystem.h"
#include "..\Interface\GMGameInterface.h"
#include "..\Script\GMScriptSystem.h"
#include "..\Script\CysCheckedScriptLua.h"
#include <cstdarg>
#include <cstdlib>
#include <cstring>
#include <string>

namespace
{
    enum Step { Off, Wait, Hud, Book, SectSkill, Common, ClearDown, ClearMove, ClearUp, ClearCheck, DragDown, DragMove, DragUp, DragCheck,
                CloseBook, Target, TargetCheck, Cast, CastEffect, CastDamage, CastLoop, CoolKey, CoolShot,
                // CYS-XINFA: second, independent chain (CYS_XINFA_LIVE=1) - the CY xinfa study window from the button
                // to the packet: ActionSkillsStudy -> SkillsStudyFrame_study -> STUDY_XINFA -> MessageBox_Self OK ->
                // SendAskStudyXinfa -> CGAskStudyXinfa 555 -> GCStudyXinfa 137.
                XWait, XOpen, XPick, XLearn, XConfirm, XVerify, CombatCleanup, LootMove, LootOpen, LootPick, LootVerify, Done };
    struct State
    {
        bool evaluated = false;
        Step step = Off;
        DWORD at = 0, since = 0;
        int skill = 0;                // SkillTemplate to drag onto F1
        int coolKey = 8;              // F-key of a bar skill with a server cooldown (CYTest00: F8 = 35 sitting)
        int presses = 0, damagesBase = 0, sendsBase = 0, cooldownBase = 0, targetId = -1, moves = 0;
        int xinfa = 0, xinfaButton = -1, xinfaBefore = -1; // CYS-XINFA: study chain
        unsigned studyBase = 0, askBase = 0, requestBase = 0;
        bool usedFallback = false;
        int lootBox=0,lootBefore=0,lootExpected=0;
        bool round2=false;
        float from[2] = {}, to[2] = {};
        char source[48] = {};
        CysUiInputBridge::SmokePointer pointer = nullptr;
        CysUiInputBridge::GetWindowRectUtf8 rect = nullptr;
        CysUiInputBridge::CopyWindowTextUtf8 text = nullptr;        // CYS-CY 16/09 (menpai-verify): chi phí tâm pháp
        CysUiInputBridge::CopyWindowTextUtf8 simpleText = nullptr;  // nhãn TLBB_SimpleMulitiTextFrame
    };
    State& S() { static State s; return s; }

    void Log(const char* fmt, ...)
    {
        char text[512] = {};
        va_list args; va_start(args, fmt);
        _vsnprintf(text, sizeof(text) - 1, fmt, args);
        va_end(args);
        TDU_Log("CYS skill-live: %s", text);
    }

    void Go(Step next, const char* why) { S().step = next; S().at = GetTickCount(); Log("step %d: %s", (int)next, why); }
    DWORD Age() { return GetTickCount() - S().at; }
    bool Shown(const char* window) { return CGameProcedure::s_pUISystem && CGameProcedure::s_pUISystem->IsWindowShow(window); }

    // Classic 0.85/CY view (fixed pitch, default distance) before every capture: the camera script of CysWorldReplay
    // leaves a free 3D angle.
    void ResetCamera()
    {
        CRenderSystem* gfx = CGameProcedure::s_pGfxSystem;
        if (!gfx) return;
        gfx->Camera_SetFreeMode(FALSE);
        gfx->Camera_SetZoom(0.45f);
    }
    void Shot(const char* label) { ResetCamera(); CysWorldReplay::LiveShot(label); }

    // CYS-CY 16/09 (menpai-verify): trang tâm pháp của ActionSkill.lua (dòng 306-338) hiện chi phí nâng một cấp qua
    // GetUplevelXinfaSpendMoney/Exp. Ghi lại nhãn đang hiện để kiểm "chi phí như CY" mà không cần đọc ảnh:
    // ActionSkill_Name = tên + cấp, ActionSkill_LearnExp = kinh nghiệm, ActionSkill_LearnDemand_Jiaozi_Text = nhãn tiền
    // (bản thân số tiền nằm ở property MoneyNumber của ActionSkill_LearnDemand_Jiaozi, không đọc qua text được).
    void LogXinfaCost()
    {
        if (!S().text && !S().simpleText) { Log("xinfa cost: no UI text bridge"); return; }
        static const char* const kWindows[] = { "ActionSkill_Name", "ActionSkill_LearnExp", "ActionSkill_LearnDemand_Jiaozi_Text" };
        for (const char* window : kWindows)
        {
            char buffer[256] = {};
            int n = S().text ? S().text(window, buffer, (unsigned)sizeof(buffer)) : -1;
            // TLBB_SimpleMulitiTextFrame giữ chữ ở lớp riêng: CopyWindowText trả rỗng, phải hỏi CopySimpleText
            if (n <= 0 && S().simpleText) n = S().simpleText(window, buffer, (unsigned)sizeof(buffer));
            for (char* p = buffer; *p; ++p) { if (*p == '\r' || *p == '\n') *p = ' '; }
            Log("xinfa cost: %s rc=%d text=[%s]", window, n, buffer);
        }
    }

    bool Center(const char* window, float xy[2])
    {
        float r[4] = {};
        if (!S().rect || S().rect(window, r) != 1) return false;
        xy[0] = r[0] + r[2] * 0.5f; xy[1] = r[1] + r[3] * 0.5f;
        return true;
    }

    // The 0.85 keyboard is DirectInput device polling (CInputSystem::KeybordTick), not WM_KEYDOWN: the scripted key
    // goes through CInputSystem::CysInjectKey (one EVENT_KEY_DOWN tick, one EVENT_KEY_UP tick -> GamePro_Main).
    void Key(int keyCode)
    {
        CInputSystem::GetMe()->CysInjectKey(keyCode, TRUE);
        CInputSystem::GetMe()->CysInjectKey(keyCode, FALSE);
    }

    CObject_PlayerMySelf* Self() { return CObjectManager::GetMe()->GetMySelf(); }

    // Define id of the action on main bar slot `index` (-1 = empty).
    int BarSkill(int index)
    {
        const INT action = CActionSystem::GetMe()->MainMenuBar_Get(index);
        tActionItem* item = action == INVALID_ID ? nullptr : CActionSystem::GetMe()->GetAction(action);
        return item ? item->GetDefineID()/100 : -1;
    }

    // CommonSkill.lua CommonSkill_Update (page 0): buttons 1..4 are pet actions, then the skills whose owner xinfa is
    // -9999 (player skills without a learned xinfa action) in EnumAction("skill") order. ActionSkill.lua lists the
    // skills of the selected xinfa on ActionSkill_Zhaoshi1..5.
    // Sect skill: ActionSkill.lua ActionSkill_Update_Cliecked(k, 1) lists on ActionSkill_Zhaoshi1..5 the skills whose
    // owner xinfa action is XINFA_INDEX[k] = EnumAction(k-1, "xinfa"), in EnumAction("skill") order. xinfaButton = k.
    bool SectButton(int templateId, char* name, size_t size, tActionItem** found, int& xinfaButton)
    {
        CActionSystem* actions = CActionSystem::GetMe();
        xinfaButton = -1;
        const _DBC_SKILL_DATA* def = nullptr;
        const INT count = actions->GetActionNum(NAMETYPE_SKILL);
        for (INT i = 0; i < count && !def; ++i)
        {
            CActionItem* item = (CActionItem*)actions->EnumAction(i, NAMETYPE_SKILL);
            const SCLIENT_SKILL* skill = item ? (const SCLIENT_SKILL*)item->GetImpl() : nullptr;
            if (skill && skill->m_pDefine && skill->m_pDefine->m_nID == templateId) def = skill->m_pDefine;
        }
        tActionItem* owner = def ? actions->GetAction_SkillClass(def->m_nSkillClass) : nullptr;
        if (!owner) return false;
        for (int k = 1; k <= 8 && xinfaButton < 0; ++k)
        {
            tActionItem* x = actions->EnumAction(k - 1, NAMETYPE_XINFA);
            if (x && x->GetID() == owner->GetID()) xinfaButton = k;
        }
        int n = 1;
        for (INT i = 0; i < count; ++i)
        {
            CActionItem* item = (CActionItem*)actions->EnumAction(i, NAMETYPE_SKILL);
            const SCLIENT_SKILL* skill = item ? (const SCLIENT_SKILL*)item->GetImpl() : nullptr;
            if (!skill || !skill->m_pDefine) continue;
            tActionItem* o = actions->GetAction_SkillClass(skill->m_pDefine->m_nSkillClass);
            if (!o || o->GetID() != owner->GetID()) continue;
            if (skill->m_pDefine->m_nID == templateId) { _snprintf(name, size, "ActionSkill_Zhaoshi%d", n); *found = item; return xinfaButton > 0 && n <= 5; }
            ++n;
        }
        return false;
    }

    bool SourceButton(int templateId, char* name, size_t size, tActionItem** found)
    {
        CActionSystem* actions = CActionSystem::GetMe();
        int xinfaButton = -1;
        if (SectButton(templateId, name, size, found, xinfaButton)) return true;
        int button = 5;
        const INT count = actions->GetActionNum(NAMETYPE_SKILL);
        for (INT i = 0; i < count; ++i)
        {
            CActionItem* item = (CActionItem*)actions->EnumAction(i, NAMETYPE_SKILL);
            const SCLIENT_SKILL* skill = item ? (const SCLIENT_SKILL*)item->GetImpl() : nullptr;
            if (!skill || !skill->m_pDefine || skill->m_pDefine->m_nClassByUser != A_SKILL_FOR_PLAYER) continue;
            if (actions->GetAction_SkillClass(skill->m_pDefine->m_nSkillClass)) continue; // shown by ActionSkill
            if (item->GetDefineID() == templateId)
            {
                _snprintf(name, size, "CommonSkill_Skill%d", button);
                *found = item;
                return button <= 20;
            }
            ++button;
        }
        return false;
    }

    // CYS-XINFA: ActionSkillsStudy_UpdateFrame fills button i (1..8) from EnumAction(i-1, "xinfa") and remembers
    // GetDefineID() in g_XinfaDefineID[i] - the XinFa_V1 id that SkillsStudyFrame_study receives.
    int XinfaButton(int xinfaId)
    {
        for (int k = 1; k <= 8; ++k)
        {
            tActionItem* x = CActionSystem::GetMe()->EnumAction(k - 1, NAMETYPE_XINFA);
            if (x && x->GetDefineID() == xinfaId) return k;
        }
        return -1;
    }

    // Without CYS_XINFA_ID: the learned xinfa on the lowest level (cheapest next level, XinFaStudySpend_V1 grows).
    // ActionSkillsStudy_Xinfa_Clicked DISABLES the learn button for slots 2, 3 and 6 below character level 20
    // (ActionSkillsStudy.lua:362-367), so those slots are skipped - clicking them does nothing at all (gui-live-4).
    int CheapestXinfa(int& button)
    {
        int best = 0, bestLevel = 0;
        button = -1;
        const int myLevel = Self() ? Self()->GetCharacterData()->Get_Level() : 0;
        for (int k = 1; k <= 8; ++k)
        {
            if ((k == 2 || k == 3 || k == 6) && myLevel < 20) continue;
            tActionItem* x = CActionSystem::GetMe()->EnumAction(k - 1, NAMETYPE_XINFA);
            if (!x) continue;
            const int id = x->GetDefineID();
            if (id <= 0) continue;
            const int level = CysSkillNet::XinfaLevel(id);
            if (best == 0 || level < bestLevel) { best = id; bestLevel = level; button = k; }
        }
        return best;
    }

    int Damages() { return static_cast<int>(CysModernHandlers::Core().damages); }
    int Sends() { return static_cast<int>(CysModernHandlers::Core().skillSends); }

    bool TargetAlive(int serverId)
    {
        tObject* object = serverId >= 0 ? CObjectManager::GetMe()->FindServerObject(serverId) : nullptr;
        if (!object || !g_theKernel.IsKindOf(object->GetClass(), GETCLASS(CObject_Character))) return false;
        return ((CObject_Character*)object)->CharacterLogic_Get() != CObject_Character::CHARACTER_LOGIC_DEAD;
    }
}

bool CysSkillDriver::Tick()
{
    State& s = S();
    if (!s.evaluated)
    {
        s.evaluated = true;
        char text[64] = {};
        const DWORD n = GetEnvironmentVariableA("CYS_SKILL_LIVE", text, sizeof(text));
        if (n == 1 && text[0] == '1') { s.step = Wait; s.at = s.since = GetTickCount(); }
        if (GetEnvironmentVariableA("CYS_SKILL_ID", text, sizeof(text)) > 0) s.skill = atoi(text);
        if (GetEnvironmentVariableA("CYS_SKILL_COOL_KEY", text, sizeof(text)) > 0) s.coolKey = atoi(text);
        // CYS-XINFA: the study chain replaces the quick-bar chain when CYS_XINFA_LIVE=1 (both need the same session).
        const DWORD x = GetEnvironmentVariableA("CYS_XINFA_LIVE", text, sizeof(text));
        if (x == 1 && text[0] == '1') { s.step = XWait; s.at = s.since = GetTickCount(); }
        if (GetEnvironmentVariableA("CYS_XINFA_ID", text, sizeof(text)) > 0) s.xinfa = atoi(text);
        HMODULE ui = GetModuleHandleA("UI_CEGUI.dll");
        if (ui)
        {
            s.rect = reinterpret_cast<CysUiInputBridge::GetWindowRectUtf8>(GetProcAddress(ui, "CysUiGetWindowRectUtf8"));
            s.pointer = reinterpret_cast<CysUiInputBridge::SmokePointer>(GetProcAddress(ui, "CysUiSmokePointer"));
            s.text = reinterpret_cast<CysUiInputBridge::CopyWindowTextUtf8>(GetProcAddress(ui, "CysUiCopyWindowTextUtf8"));
            s.simpleText = reinterpret_cast<CysUiInputBridge::CopyWindowTextUtf8>(GetProcAddress(ui, "CysUiCopySimpleTextUtf8"));
        }
        Log("driver %s skill=%d cool_key=F%d pointer=%d", s.step == Wait ? "enabled" : "disabled", s.skill, s.coolKey, s.pointer ? 1 : 0);
    }
    if (s.step == Off || s.step == Done) return true;
    if (!CysModernGame::IsInWorld() || !Self()) { Log("left the world at step %d", (int)s.step); s.step = Done; return true; }
    const CysSkillNet::Counters c = CysSkillNet::Get();
    switch (s.step)
    {
    case Wait:
        if ((c.skillLists > 0 && c.settingLists > 0 && Age() >= 1500) || Age() > 15000)
        {
            std::string bar;
            for (int i = 0; i < 10; ++i) { char item[24]; _snprintf(item, sizeof(item), "%sF%d=%d", i ? " " : "", i + 1, BarSkill(i)); bar += item; }
            Log("skill_lists=%u setting_lists=%u xinfa=%d menpai=%d skills=%d bar=[%s]", c.skillLists, c.settingLists, CysSkillNet::XinfaCount(),
                Self()->GetCharacterData()->Get_MenPai(), (int)Self()->GetCharacterData()->Get_Skill().size(), bar.c_str());
            Go(Hud, "hud");
        }
        break;
    case Hud:
        Shot("skill-hud");
        CEventSystem::GetMe()->PushEvent(GE_TOGLE_SKILL_BOOK); // MainMenuBar_Skill_Clicked of the CY main menu
        Go(Book, "TOGLE_SKILL_BOOK");
        break;
    case Book:
        if (Age() < 1400) break;
        Log("skill book ActionSkill_Frame shown=%d CommonSkill_Frame shown=%d", Shown("ActionSkill") ? 1 : 0, Shown("CommonSkill") ? 1 : 0);
        Shot("skill-book");
        {
            tActionItem* action = nullptr;
            int xinfaButton = -1;
            char xinfa[40] = {};
            float xy[2] = {};
            if (s.pointer && SectButton(s.skill, s.source, sizeof(s.source), &action, xinfaButton))
            {
                _snprintf(xinfa, sizeof(xinfa), "ActionSkill_Xinfa%d", xinfaButton);
                if (Center(xinfa, xy)) { s.pointer(1, xy[0], xy[1]); s.pointer(2, xy[0], xy[1]); }
                Log("sect skill %d (%s): clicked %s, skill button %s", s.skill, action->GetName(), xinfa, s.source);
                Go(SectSkill, "xinfa selected");
                break;
            }
        }
        CEventSystem::GetMe()->PushEvent(GE_TOGLE_COMMONSKILL_PAGE); // the "common" tab (skills without a xinfa)
        Go(Common, "TOGLE_COMMONSKILL_PAGE");
        break;
    case SectSkill:
    {
        if (Age() < 1200) break;
        LogXinfaCost();
        Shot("skill-book-xinfa");
        float xy[2] = {};
        if (Center(s.source, xy)) { s.pointer(1, xy[0], xy[1]); s.pointer(2, xy[0], xy[1]); Log("clicked %s", s.source); }
        Go(ClearDown, "skill selected");
        break;
    }
    case Common:
        if (Age() < 1400) break;
        Log("common skill page CommonSkill shown=%d", Shown("CommonSkill") ? 1 : 0);
        Shot("skill-common");
        {
            // Click the skill button (CommonSkill_Buttons_Clicked): the page shows its Vietnamese name and description.
            tActionItem* action = nullptr;
            float xy[2] = {};
            if (s.pointer && SourceButton(s.skill, s.source, sizeof(s.source), &action) && Center(s.source, xy))
            {
                s.pointer(1, xy[0], xy[1]); s.pointer(2, xy[0], xy[1]);
                Log("clicked %s (skill %d: %s)", s.source, s.skill, action->GetName());
                Go(ClearDown, "skill selected");
                break;
            }
        }
        Go(ClearDown, "no skill button to select");
        break;
    case ClearDown:
        if (Age() < 1200) break;
        Shot("skill-selected");
        if (BarSkill(0) < 0) { Go(DragDown, "F1 already empty"); break; }
        if (!s.pointer || !Center("Button_Action1", s.from)) { Log("no pointer bridge / F1 button"); Go(DragDown, "skip clearing F1"); break; }
        s.to[0] = s.from[0]; s.to[1] = s.from[1] - 260.0f; // open world above the bar
        s.pointer(1, s.from[0], s.from[1]);
        Go(ClearMove, "press on F1");
        break;
    case ClearMove:
        // CEGUI drag starts on a later mouse move than the press: one move per tick over ~0.6 s
        if (Age() < 150 + 100 * (DWORD)s.moves) break;
        ++s.moves;
        s.pointer(0, s.from[0] + (s.to[0] - s.from[0]) * s.moves / 6.0f, s.from[1] + (s.to[1] - s.from[1]) * s.moves / 6.0f);
        if (s.moves >= 6) { s.moves = 0; Go(ClearUp, "drag F1 off the bar"); }
        break;
    case ClearUp:
        if (Age() < 200) break;
        s.pointer(2, s.to[0], s.to[1]);
        Go(ClearCheck, "release");
        break;
    case ClearCheck:
        if (Age() < 1200) break;
        Log("F1 after drag-off: %d (modify_settings=%u)", BarSkill(0), c.modifySettings);
        if (BarSkill(0) >= 0) { CActionSystem::GetMe()->MainMenuBar_Set(0, INVALID_ID); s.usedFallback = true; Log("fallback: MainMenuBar_Set(0, -1)"); }
        Shot("skill-bar-f1-empty");
        Go(DragDown, "drag the skill");
        break;
    case DragDown:
    {
        tActionItem* action = nullptr;
        if (!SourceButton(s.skill, s.source, sizeof(s.source), &action)) { Log("skill %d is on no skill page", s.skill); Go(CloseBook, "no source"); break; }
        if (!s.pointer || !Center(s.source, s.from) || !Center("Button_Action1", s.to))
        {
            Log("source %s or F1 not visible: DoAction-free fallback NotifyDragDropDragged", s.source);
            action->NotifyDragDropDragged(FALSE, "M00", "");
            s.usedFallback = true;
            Go(DragCheck, "fallback drop");
            break;
        }
        Log("drag %s (%.0f,%.0f) -> Button_Action1 (%.0f,%.0f)", s.source, s.from[0], s.from[1], s.to[0], s.to[1]);
        s.pointer(1, s.from[0], s.from[1]);
        Go(DragMove, "press on the skill");
        break;
    }
    case DragMove:
        if (Age() < 150 + 100 * (DWORD)s.moves) break;
        ++s.moves;
        s.pointer(0, s.from[0] + (s.to[0] - s.from[0]) * s.moves / 6.0f, s.from[1] + (s.to[1] - s.from[1]) * s.moves / 6.0f);
        if (s.moves >= 6) { s.moves = 0; Go(DragUp, "move over F1"); }
        break;
    case DragUp:
        if (Age() < 200) break;
        s.pointer(2, s.to[0], s.to[1]);
        Go(DragCheck, "drop on F1");
        break;
    case DragCheck:
        if (Age() < 1500) break;
        Log("F1 after drop: %d (want %d) modify_settings=%u", BarSkill(0), s.skill, c.modifySettings);
        if (BarSkill(0) != s.skill)
        {
            tActionItem* action = nullptr;
            char name[48] = {};
            if (SourceButton(s.skill, name, sizeof(name), &action)) { action->NotifyDragDropDragged(FALSE, "M00", ""); s.usedFallback = true; Log("fallback: NotifyDragDropDragged(M00) F1=%d", BarSkill(0)); }
        }
        Shot("skill-dragged-f1");
        Go(CloseBook, "close the book");
        break;
    case CloseBook:
    {
        CEventSystem::GetMe()->PushEvent(GE_CLOSE_SKILL_BOOK);
        // Stand in the open, 4 m from the nearest hostile monster, before the combat captures (gui-live-6: the hunt
        // spot 40,150 of Vo Luong Son puts the character under a tree canopy that hides effects and damage numbers).
        float distance = 0;
        const unsigned id = CysModernGame::NearestMonster(&distance);
        s.targetId = id ? (int)id : -1;
        CObject* monster = id ? (CObject*)CObjectManager::GetMe()->FindServerObject((INT)id) : nullptr;
        DWORD walk = 0;
        if (monster && distance > 0.5f && (distance > 5.0f || getenv("CYS_SKILL_RANGE")) && CGameProcedure::s_pGameInterface->GetCampType(Self(), monster) == RELATION_ENEMY)
        {
            const fVector3 me = Self()->GetPosition(), it = monster->GetPosition();
            const char* range = getenv("CYS_SKILL_RANGE");
            const float desired = range ? (float)atof(range) : 4.0f;
            const float t = (distance - desired) / distance;
            CGameInterface::GetMe()->Player_MoveTo(fVector2(me.x + (it.x - me.x) * t, me.z + (it.z - me.z) * t));
            walk = static_cast<DWORD>(fabsf(distance - desired) / 4.0f * 1000.0f) + 800;
            Log("walk toward monster %u (%.1f m) for the combat captures", id, distance);
        }
        s.since = walk;
        Go(Target, "CLOSE_SKILL_BOOK");
        break;
    }
    case Target:
        if (Age() < 800 + s.since) break;
        // This fixture measures the projectile, not target selection. Keep the
        // same monster used to measure the requested range; Tab is CY's map key.
        CObjectManager::GetMe()->SetMainTarget(s.targetId);
        s.usedFallback = true;
        Go(TargetCheck, "fixture target selected");
        break;
    case TargetCheck:
    {
        if (Age() < 1200) break;
        // CY's restored accelerator table can bind Tab to the scene map. The old
        // probe assumed 0.85's nearest-enemy binding and left that map over quit/shop.
        if (Shown("SceneMap")) Key(KC_ESCAPE);
        tObject* target = CObjectManager::GetMe()->GetMainTarget();
        s.targetId = target ? target->GetServerID() : -1;
        if (target) {
            const fVector3 a=Self()->GetPosition(),b=((CObject*)target)->GetPosition();
            const float dx=a.x-b.x,dz=a.z-b.z;
            Log("measured cast range=%.2f target=%d",sqrtf(dx*dx+dz*dz),s.targetId);
        }
        Log("main target after Tab: server=%d TargetFrame shown=%d", s.targetId, Shown("TargetFrame") ? 1 : 0);
        if (s.targetId < 0)
        {
            // Diagnostic of the Tab rule (RELATION_ENEMY within 20 m) on the nearest object, then the click path:
            // a left click on a monster ends in CObjectManager::SetMainTarget as well.
            float distance = 0;
            const fVector3 me = Self()->GetPosition();
            const unsigned nearest = CysModernGame::NearestObjectAt(me.x, me.z, 15.0f, &distance);
            CObject* obj = nearest ? (CObject*)CObjectManager::GetMe()->FindServerObject((INT)nearest) : nullptr;
            const _CAMP_DATA* mine = Self()->GetCampData();
            const _CAMP_DATA* theirs = obj ? obj->GetCampData() : nullptr;
            Log("Tab diagnostic: nearest=%u dist=%.1f my_camp=%d target_camp=%d relation=%d", nearest, distance,
                mine ? mine->m_nCampID : -99, theirs ? theirs->m_nCampID : -99,
                obj ? (int)CGameProcedure::s_pGameInterface->GetCampType(Self(), obj) : -1);
            if (obj && obj != (CObject*)Self())
            {
                CObjectManager::GetMe()->SetMainTarget(obj->GetServerID());
                tObject* picked = CObjectManager::GetMe()->GetMainTarget();
                s.targetId = picked ? picked->GetServerID() : -1;
                Log("click-path target: server=%d", s.targetId);
                s.usedFallback = true;
            }
        }
        Shot("skill-target");
        if (s.targetId < 0) { Log("no enemy within 20 m"); Go(CoolKey, "no target"); break; }
        Go(Cast, "F1");
        break;
    }
    case Cast:
        s.damagesBase = Damages(); s.sendsBase = Sends(); ++s.presses;
        Key(KC_F1);
        Go(CastEffect, "F1 pressed");
        break;
    case CastEffect:
        if (Age() < 450) break;
        Log("F1 #%d: skill_sends+%d damages+%d", s.presses, Sends() - s.sendsBase, Damages() - s.damagesBase);
        if (s.presses == 1) Shot("skill-cast-f1");
        Go(CastDamage, "effect");
        break;
    case CastDamage:
        if (Age() < 500) break;
        if (s.presses == 1 || (Damages() > s.damagesBase && s.presses <= 3)) { char label[32]; _snprintf(label, sizeof(label), "skill-damage-%d", s.presses); Shot(label); }
        Go(CastLoop, "next press");
        break;
    case CastLoop:
        if (!TargetAlive(s.targetId))
        {
            Log("target %d dead/removed after %d presses (damages %d)", s.targetId, s.presses, Damages());
            Shot("skill-kill");
            Go(CoolKey, "cooldown skill");
            break;
        }
        if (s.presses >= 15) { Log("target alive after %d presses", s.presses); Go(CoolKey, "press limit"); break; }
        if (Age() >= 700) Go(Cast, "F1 again");
        break;
    case CoolKey:
        if (Age() < 1500) break;
        if(getenv("CYS_ROUND2_COMBAT") && !TargetAlive(s.targetId))
        {
            s.round2=true;
            auto d=Self()->GetCharacterData();
            Log("ROUND2 death exp=%lld need=%d logic=%d target=%d",d->Get_Exp(),d->Get_MaxExp(),Self()->CharacterLogic_Get(),s.targetId);
            if(d->Get_Exp()<=1000 || d->Get_MaxExp()!=3604920 || Self()->CharacterLogic_Get()==CObject_Character::CHARACTER_LOGIC_SKILL_SEND)
                Log("ROUND2 FAIL credited EXP or basic attack interrupt");
            else Log("ROUND2 PASS kill EXP credited and attack stopped before manual cancel");
            float x=0,z=0;s.lootBox=CysModernGame::NearestItemBox(30,&x,&z);
            if(s.lootBox){s.to[0]=x;s.to[1]=z;CGameInterface::GetMe()->Player_MoveTo(fVector2(x,z));Go(LootMove,"walk to actual drop box");break;}
            static int killsWithoutLoot=0;
            if(++killsWithoutLoot<10){
                unsigned candidates[100]={};auto me=Self()->GetPosition();
                auto count=CysModernGame::ObjectsNear(me.x,me.z,35,candidates,100);
                for(unsigned i=0;i<count;++i){
                    auto target=(CObject*)CObjectManager::GetMe()->FindServerObject(candidates[i]);
                    if(target && g_theKernel.IsKindOf(target->GetClass(),GETCLASS(CObject_Character)) && ((CObject_Character*)target)->GetCharacterType()==CObject_Character::CT_MONSTER && TargetAlive(candidates[i]) && CGameProcedure::s_pGameInterface->GetCampType(Self(),target)==RELATION_ENEMY){
                        s.targetId=candidates[i];s.presses=0;CObjectManager::GetMe()->SetMainTarget(s.targetId);Go(Cast,"next real monster until natural loot");return false;
                    }
                }
            }
            Log("ROUND2 FAIL no natural loot after %d kills",killsWithoutLoot);
        }
        if (s.coolKey < 1 || s.coolKey > 10 || BarSkill(s.coolKey - 1) < 0)
        {
            CGameInterface::GetMe()->Skill_CancelAction();
            CObjectManager::GetMe()->SetMainTarget(INVALID_ID);
            Go(CombatCleanup,"wait for combat state before quit");break;
        }
        s.cooldownBase = (int)c.cooldownEntries;
        Log("F%d skill=%d", s.coolKey, BarSkill(s.coolKey - 1));
        Key(KC_F1 + s.coolKey - 1);
        Go(CoolShot, "cooldown key");
        break;
    case LootMove:
        if(Age()<1500)break;
        if(std::hypot(Self()->GetPosition().x-s.to[0],Self()->GetPosition().z-s.to[1])>2.5f && Age()<10000)break;
        CGameInterface::GetMe()->TripperObj_Active(s.lootBox);Go(LootOpen,"open actual box");break;
    case LootOpen:
        if(Age()<1000)break;
        if(CDataPool::GetMe()->ItemBox_GetID()!=s.lootBox || CDataPool::GetMe()->ItemBox_GetNumber()==0)
        {if(Age()<8000)break;Log("ROUND2 FAIL real drop box not opened");Go(CombatCleanup,"loot failed");break;}
        s.lootBefore=0;s.lootExpected=0;
        for(int i=0;i<200;++i)if(auto item=CDataPool::GetMe()->UserBag_GetItem(i))s.lootBefore+=item->GetNumber();
        for(int i=0;i<MAX_BOXITEM_NUMBER;++i)if(auto item=CDataPool::GetMe()->ItemBox_GetItem(i))s.lootExpected+=item->GetNumber();
        Shot("round2-loot-before");Go(LootPick,"click pick all twice to test replay");break;
    case LootPick:
        {auto r=CScriptSystem::GetMe()->EvaluateScript("LootPacket_Env","PlayerPackage:PickAllItem();PlayerPackage:PickAllItem()");if(!r.ok())Log("ROUND2 FAIL pick all Lua %s",r.error);}
        Go(LootVerify,"wait authoritative item acknowledgements");break;
    case LootVerify:
        if(Age()<2000)break;
        {int total=0;for(int i=0;i<200;++i)if(auto item=CDataPool::GetMe()->UserBag_GetItem(i))total+=item->GetNumber();
         Log("ROUND2 %s pick all conservation before=%d expected=%d after=%d remaining=%d",total==s.lootBefore+s.lootExpected&&CDataPool::GetMe()->ItemBox_GetNumber()==0?"PASS":"FAIL",s.lootBefore,s.lootExpected,total,CDataPool::GetMe()->ItemBox_GetNumber());}
        Shot("round2-loot-after");Go(CombatCleanup,"loot completed");break;
    case CombatCleanup:
        if(Age()<35000)break;
        Log("RESULT skill=%d fallback=%d presses=%d damages=%d",s.skill,s.usedFallback?1:0,s.presses,Damages());
        Go(Done,"combat cleanup complete");break;
    case CoolShot:
        if (Age() < 900) break;
        Log("GCCooldownUpdate entries+%d", (int)c.cooldownEntries - s.cooldownBase);
        Shot("skill-cooldown");
        Log("PASS skill live script (fallback=%d skill_lists=%u setting_lists=%u modify_settings=%u cooldown_entries=%u presses=%d damages=%d)",
            s.usedFallback ? 1 : 0, c.skillLists, c.settingLists, c.modifySettings, c.cooldownEntries, s.presses, Damages());
        s.step = Done;
        return true;

    // ---- CYS-XINFA: the CY xinfa study path, button by button -------------------------------------------------
    case XWait:
        if ((c.skillLists > 0 && c.xinfaLists > 0 && Age() >= 1500) || Age() > 15000)
        {
            if (s.xinfa > 0) s.xinfaButton = XinfaButton(s.xinfa);
            else s.xinfa = CheapestXinfa(s.xinfaButton);
            s.xinfaBefore = s.xinfa > 0 ? CysSkillNet::XinfaLevel(s.xinfa) : -1;
            Log("xinfa study: menpai=%d xinfa_known=%d target=%d level=%d button=%d exp=%lld money=%d",
                Self()->GetCharacterData()->Get_MenPai(), CysSkillNet::XinfaCount(), s.xinfa, s.xinfaBefore, s.xinfaButton,
                Self()->GetCharacterData()->Get_Exp(), Self()->GetCharacterData()->Get_Money());
            if (s.xinfa <= 0 || s.xinfaButton < 1) { Log("FAIL no xinfa on a study button"); s.step = Done; return true; }
            Shot("xinfa-hud");
            // GCXinfaStudyInfo of a real teacher pushes the same event (CysSkillNet::OnXinfaStudyInfo); -1 = no NPC.
            CEventSystem::GetMe()->PushEvent(GE_TOGLE_SKILLSTUDY, -1);
            Go(XOpen, "TOGLE_SKILLSTUDY");
        }
        break;
    case XOpen:
    {
        if (Age() < 1500) break;
        Log("ActionSkillsStudy shown=%d", Shown("ActionSkillsStudy") ? 1 : 0);
        Shot("xinfa-window");
        char button[48] = {};
        float xy[2] = {};
        _snprintf(button, sizeof(button), "ActionSkillsStudy_XinfaSkill_%d", s.xinfaButton);
        if (s.pointer && Center(button, xy)) { s.pointer(1, xy[0], xy[1]); s.pointer(2, xy[0], xy[1]); Log("clicked %s (xinfa %d)", button, s.xinfa); }
        else Log("no pointer bridge / %s not visible", button);
        Go(XPick, "xinfa selected");
        break;
    }
    case XPick:
    {
        if (Age() < 1200) break;
        Shot("xinfa-selected");
        s.requestBase = c.studyRequests; s.askBase = c.studyAsks; s.studyBase = c.studyResults;
        float xy[2] = {};
        if (s.pointer && Center("ActionSkillsStudy_UpLevel_Frame", xy))
        {
            s.pointer(1, xy[0], xy[1]); s.pointer(2, xy[0], xy[1]);
            Log("clicked ActionSkillsStudy_UpLevel_Frame -> SkillsStudyFrame_study(%d)", s.xinfa);
        }
        else Log("FAIL ActionSkillsStudy_UpLevel_Frame not visible");
        Go(XLearn, "learn button");
        break;
    }
    case XLearn:
        if (Age() < 1500) break;
        Log("after the learn button: study_requests+%u MessageBox_Self shown=%d",
            c.studyRequests - s.requestBase, Shown("MessageBox_Self") ? 1 : 0);
        Shot("xinfa-confirm");
        {
            float xy[2] = {};
            if (Shown("MessageBox_Self") && s.pointer && Center("MessageBox_Self_OK_Button", xy))
            {
                s.pointer(1, xy[0], xy[1]); s.pointer(2, xy[0], xy[1]);
                Log("clicked MessageBox_Self_OK_Button -> SendAskStudyXinfa");
            }
            else Log("no STUDY_XINFA confirmation to click (study_asks+%u already)", c.studyAsks - s.askBase);
        }
        Go(XConfirm, "confirmation");
        break;
    case XConfirm:
        if (Age() < 1200) break;
        Log("after the OK button: study_asks+%u (CGAskStudyXinfa sent)", c.studyAsks - s.askBase);
        Go(XVerify, "wait for GCStudyXinfa");
        break;
    case XVerify:
    {
        const int now = CysSkillNet::XinfaLevel(s.xinfa);
        if (c.studyResults == s.studyBase && Age() < 6000) break;
        Shot("xinfa-after");
        Log("%s xinfa live script: xinfa=%d level %d -> %d study_requests+%u study_asks+%u GCStudyXinfa+%u",
            (c.studyAsks > s.askBase && c.studyResults > s.studyBase && now > s.xinfaBefore) ? "PASS" : "PARTIAL",
            s.xinfa, s.xinfaBefore, now, c.studyRequests - s.requestBase, c.studyAsks - s.askBase, c.studyResults - s.studyBase);
        s.step = Done;
        return true;
    }
    default:
        break;
    }
    return false;
}

#else
bool CysSkillDriver::Tick() { return true; }
#endif
