#pragma once
// CYS-NPCINT 19/09: luot do live cho TUONG TAC NPC (`CYS_NPCINT_LIVE=1`).
//
// VI SAO CAN: nguoi dung bao "khong tuong tac duoc voi npc". Chuoi tuong tac di qua 5 lop
//   (1) chon duoc NPC  (2) ra duoc menu  (3) goi mang di  (4) server tra loi  (5) bam muc chay,
// va moi lop hong thi sua khac nhau. Log phien choi that chi cho thay "moi cu nhap trai deu ra
// MCT_PLAYER_MOVETO" - du de nghi, chua du de chi mat lop.
//
// BO DO NAY CHAY DUNG DUONG MA CHUOT TRAI CHAY, khong phai mot duong rieng:
//   CCursorMng::MouseCommand_Set(bHoverInUI=FALSE, pSelectObj, fvPos, GetDefaultAction())
//     -> CObject::FillMouseCommand_Left/Right   <- dung ham ao that
//   CCursorMng::MouseCommand_Active(MouseCommand_GetLeft())
//     <- dung dong ma GamePro_Main.cpp EVENT_MOUSE_LBUP goi
// Thu duy nhat no KHONG lam la chon doi tuong bang tia chuot (GetMouseOverObject). Phan do da co
// bang chung rieng trong phien choi that: 29/176 cu nhap co `obj=1` (lbup-census.json) => tia
// chuot BAT DUOC doi tuong; van de nam o buoc sau.
//
// IN RA (moi NPC mot dong `CYS-NPCINT: npc ...`): id server, race, ten, npc_type, camp, quan he,
// cannot_attack, canbe_select, ray_query, canHandle cua bang DBC, va LENH TRAI/PHAI thu duoc.
// Sau do goi MouseCommand_Active cho NPC dau tien co lenh trai = MCT_SPEAK va dem
// `CysInventoryNet::Get().eventLists` (GCScriptCommand 0 = menu NPC cua server) de chung minh
// lop 3+4 chay that.
//
// DOI CHUNG AM: chay lai CUNG BINARY voi `CYS_NPCINT_OFF=1`. Khi do CObject_PlayerNPC::CannotBeAttack
// tra ve luat cu (hang so 0) => moi dong phai in `cannot_attack=0 left=0(MCT_NULL)` va
// `speak_sent=0`. Neu tay do am ma van xanh thi phep do KHONG biet truot => bo di.
#include "TDUtil.h"
#include "TDActionSystem.h"
#include "..\Global.h"
#include "..\Cursor\CursorMng.h"
#include "..\GameCommand.h"
#include "..\Object\ObjectManager.h"
#include "..\Object\Character\Obj_PlayerNPC.h"
#include "..\Object\Character\Obj_PlayerMySelf.h"
#include "..\DataPool\GMDP_CharacterData.h"
#include "..\Interface\GMGameInterface.h"
#include "TDDBC_Struct.h"
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <cstring>

#if defined(CYS_HAVE_NETCORE)
#include "..\Network\CysModernGame.h"
#include "..\Network\CysInventoryNet.h"
#endif

namespace CysNpcInteractProbe
{
    namespace
    {
        struct State
        {
            bool evaluated;
            bool on;
            bool done;
            int  step;
            DWORD at;
            unsigned baseEventLists;
            unsigned speakId;
            unsigned npcSeen, npcSpeak, npcBlocked, objSeen;
            State() : evaluated(false), on(false), done(false), step(0), at(0),
                      baseEventLists(0), speakId(0), npcSeen(0), npcSpeak(0), npcBlocked(0), objSeen(0) {}
        };
        inline State& S() { static State s; return s; }

        inline const char* MctName(int t)
        {
            switch (t)
            {
            case SCommand_Mouse::MCT_NULL:          return "MCT_NULL";
            case SCommand_Mouse::MCT_PLAYER_MOVETO: return "MCT_PLAYER_MOVETO";
            case SCommand_Mouse::MCT_PLAYER_SELECT: return "MCT_PLAYER_SELECT";
            case SCommand_Mouse::MCT_SKILL_OBJ:     return "MCT_SKILL_OBJ";
            case SCommand_Mouse::MCT_SKILL_AREA:    return "MCT_SKILL_AREA";
            case SCommand_Mouse::MCT_SPEAK:         return "MCT_SPEAK";
            case SCommand_Mouse::MCT_CONTEXMENU:    return "MCT_CONTEXMENU";
            case SCommand_Mouse::MCT_USE_ITEM:      return "MCT_USE_ITEM";
            default:                                return "khac";
            }
        }

        inline unsigned EventLists()
        {
#if defined(CYS_HAVE_NETCORE)
            return CysInventoryNet::Get().eventLists;
#else
            return 0;
#endif
        }

        // Mot vong do: duyet moi doi tuong quanh nguoi choi, chay DUNG duong cursor cho tung cai.
        inline void Survey()
        {
            State& s = S();
            CObjectManager* objects = CObjectManager::GetMe();
            CObject_PlayerMySelf* self = objects ? objects->GetMySelf() : NULL;
            if (!self) { TDU_Log("CYS-NPCINT: khong co nhan vat cua minh; bo luot"); return; }
            const fVector3 me = self->GetPosition();
            unsigned ids[64] = {0};
            unsigned count = 0;
#if defined(CYS_HAVE_NETCORE)
            count = CysModernGame::ObjectsNear(me.x, me.z, 40.0f, ids, 64);
#endif
            TDU_Log("CYS-NPCINT: khao sat quanh (%.1f,%.1f) ban kinh 40: %u doi tuong", me.x, me.z, count);
            tActionItem* action = CActionSystem::GetMe() ? CActionSystem::GetMe()->GetDefaultAction() : NULL;
            CCursorMng* cursor = CCursorMng::GetMe();
            for (unsigned i = 0; i < count; ++i)
            {
                CObject* object = (CObject*)objects->FindServerObject((INT)ids[i]);
                if (!object) continue;
                ++s.objSeen;
                const BOOL isNpc = g_theKernel.IsKindOf(object->GetClass(), GETCLASS(CObject_PlayerNPC));
                if (!isNpc) continue;
                CObject_PlayerNPC* npc = (CObject_PlayerNPC*)object;
                if (npc->GetCharacterType() != CObject_Character::CT_MONSTER) continue; // nguoi choi khac: khong tinh
                ++s.npcSeen;

                // DUNG duong ma chuot trai chay.
                const fVector3 at = npc->GetPosition();
                cursor->MouseCommand_Set(FALSE, npc, at, action);
                const SCommand_Mouse left  = cursor->MouseCommand_GetLeft();
                const SCommand_Mouse right = cursor->MouseCommand_GetRight();

                const CCharacterData* data = npc->GetCharacterData();
                const _DBC_CREATURE_ATT* att = npc->GetCreatureAtt();
                const _CAMP_DATA* camp = npc->GetCampData();
                const ENUM_RELATION rel = CGameInterface::GetMe()->GetCampType(self, npc);
                const FLOAT dx = at.x - me.x, dz = at.z - me.z;
                TDU_Log("CYS-NPCINT: npc id=%u race=%d ten=%s dist=%.1f npc_type=%d camp=%d rel=%d "
                        "canHandle=%d ai_type=%d cannot_attack=%d canbe_select=%d ray_query=%d "
                        "left=%d(%s) right=%d(%s)",
                        ids[i], data ? data->Get_RaceID() : -1, data ? data->Get_Name() : "?",
                        (float)sqrt(dx * dx + dz * dz), (int)npc->GetNpcType(),
                        camp ? camp->m_nCampID : -99, (int)rel,
                        att ? att->nCanHandle : -99, data ? data->Get_AIType() : -99,
                        (int)npc->CannotBeAttack(), (int)npc->CanbeSelect(),
                        (int)(npc->IsEnable(OSF_RAY_QUERY) ? 1 : 0),
                        (int)left.m_typeMouse, MctName(left.m_typeMouse),
                        (int)right.m_typeMouse, MctName(right.m_typeMouse));

                if (left.m_typeMouse == SCommand_Mouse::MCT_SPEAK)
                {
                    ++s.npcSpeak;
                    if (!s.speakId) s.speakId = ids[i];
                }
                else if (att && att->nCanHandle == 1)
                {
                    ++s.npcBlocked; // NPC doi thoai theo bang du lieu, nhung lenh trai khong ra MCT_SPEAK
                }
            }
            TDU_Log("CYS-NPCINT: tong ket khao sat objects=%u npc=%u speak=%u blocked=%u",
                    s.objSeen, s.npcSeen, s.npcSpeak, s.npcBlocked);
        }
    }

    // true = xong (hoac tat); false = con dang chay, goi lai o khung sau.
    inline bool Tick()
    {
        State& s = S();
        if (!s.evaluated)
        {
            s.evaluated = true;
            char text[8] = {0};
            s.on = (::GetEnvironmentVariableA("CYS_NPCINT_LIVE", text, sizeof(text)) > 0 && text[0] == '1');
            char off[8] = {0};
            const bool offMode = (::GetEnvironmentVariableA("CYS_NPCINT_OFF", off, sizeof(off)) > 0 && off[0] == '1');
            TDU_Log("CYS-NPCINT: bo do %s, che do doi chung am (CYS_NPCINT_OFF) = %d",
                    s.on ? "BAT" : "TAT", offMode ? 1 : 0);
            s.at = GetTickCount();
        }
        if (!s.on || s.done) return true;
        const DWORD age = GetTickCount() - s.at;

        switch (s.step)
        {
        case 0: // cho the gioi on dinh + danh sach doi tuong quanh nguoi choi day du
            if (age < 4000) return false;
            s.step = 1; s.at = GetTickCount();
            return false;
        case 1:
            Survey();
            s.baseEventLists = EventLists();
            if (!s.speakId)
            {
                TDU_Log("CYS-NPCINT: KET QUA lop 2 HONG - khong mot NPC nao quanh day cho lenh trai MCT_SPEAK "
                        "(npc=%u, trong do %u la NPC doi thoai theo bang du lieu). Khong co gi de bam.",
                        s.npcSeen, s.npcBlocked);
                s.done = true;
                return true;
            }
            TDU_Log("CYS-NPCINT: kich hoat lenh trai tren NPC %u (dung CCursorMng::MouseCommand_Active nhu EVENT_MOUSE_LBUP); "
                    "eventLists truoc = %u", s.speakId, s.baseEventLists);
            {
                SCommand_Mouse speak;
                speak.m_typeMouse = SCommand_Mouse::MCT_SPEAK;
                speak.m_adwParam[0] = s.speakId;
                CCursorMng::GetMe()->MouseCommand_Active(speak);
            }
            s.step = 2; s.at = GetTickCount();
            return false;
        case 2:
            // Enter_DefaultEvent gui goi ngay khi trong 3 met (MAX_CLIENT_DEFAULT_EVENT_DIST), neu xa hon
            // thi dat MYSELF_AI_DEFAULT_EVENT va di toi. Cho toi 20 s cho ca hai truong hop.
            if (EventLists() > s.baseEventLists)
            {
                TDU_Log("CYS-NPCINT: KET QUA lop 1..4 XANH - server tra menu NPC sau %lu ms "
                        "(eventLists %u -> %u); npc=%u speak=%u blocked=%u",
                        (unsigned long)age, s.baseEventLists, EventLists(), s.npcSeen, s.npcSpeak, s.npcBlocked);
                s.done = true;
                return true;
            }
            if (age > 20000)
            {
                TDU_Log("CYS-NPCINT: KET QUA lop 3 hoac 4 HONG - lenh trai la MCT_SPEAK nhung 20 s khong co "
                        "menu NPC nao ve (eventLists van = %u)", s.baseEventLists);
                s.done = true;
                return true;
            }
            return false;
        default:
            s.done = true;
            return true;
        }
    }
}
