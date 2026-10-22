#include "StdAfx.h"
#include "CysLeapNet.h"
// CYS-MOVE2: see CysLeapNet.h. Modelled on CysRideNet.cpp (ride-core).
#include "..\DataPool\GMDP_CharacterData.h"
#include "..\Object\ObjectManager.h"
#include "..\Object\Character\Obj_Character.h"
#include "..\Object\Character\Obj_PlayerMySelf.h"
#include "..\Global.h"
#include "TDUtil.h"

#if defined(CYS_HAVE_NETCORE)
#include "CysModernGame.h"
#include "PgPackets_movement.h"
#include <memory>
#endif

namespace
{
    CysLeapNet::Counters g_counters = {};
    unsigned g_logs = 0;

    void LeapLog(const char* fmt, ...)
    {
        if (g_logs++ >= 200) return;
        char text[512] = {};
        va_list args; va_start(args, fmt);
        _vsnprintf(text, sizeof(text) - 1, fmt, args);
        va_end(args);
        TDU_Log("CYS-MOVE2 leap: %s", text);
    }

    // services/lualib/define.lua:296 define.QINGGONG_SKILL, menpai ids of define.MENPAI_ATTRIBUTE (251..263).
    struct MenpaiSkill { int menpai; int skill; };
    const MenpaiSkill kServerQinggong[] =
    {
        { 0, 23 }, { 1, 24 }, { 2, 25 }, { 3, 26 }, { 4, 27 }, { 5, 28 }, { 6, 29 }, { 7, 30 }, { 8, 31 },
        { 10, 110 },     // 慕容 (Gusu)
        { 15, 4648 },    // 恶人谷 (Erengu)
        // 16 曼陀山庄 -> 50110: "dải riêng, tắt" in define.lua - not offered
    };
    const int kAlwaysAccepted = 34;   // scenecore:is_qinggong_skill accepts 34 for every menpai

    bool Learned(const CCharacterData* data, int skill)
    {
        // CYS-LEAP 19/09 SUA LOI: cho nay truoc goi Get_Skill(skill) voi `skill` la *template id* (34).
        // Ban do ky nang khoa theo `tid*100 + level` (Set_Skill, GMDP_CharacterData.cpp:1967), nen tra bang id
        // tran LUON ra NULL => DefaultFlySkillID luon tra -1 => khinh cong trong GUI khong bao gio gui goi nao.
        // Bot cua move-2 khong dinh loi nay vi no truyen thang skill=34 vao day, khong qua ban do cua client.
        // Do duoc: Build\Logs\2026-09-17-leap-gui\live-3 - "skills applied 9/9 ... 34/1 ..." (ky nang CO trong
        // ban do) nhung "fly refused, no qinggong skill (GetDefaultFlySkillID = -1)".
        return CysLeapNet::FindLearnedSkill(data, skill) != NULL;
    }
}

const SCLIENT_SKILL* CysLeapNet::FindLearnedSkill(const CCharacterData* data, int templateId)
{
    if (!data) return NULL;
    const SSKILL_MAP& skills = data->Get_Skill();
    for (SSKILL_MAP::const_iterator it = skills.begin(); it != skills.end(); ++it)
    {
        const SCLIENT_SKILL& skill = it->second;
        if (skill.m_pDefine != NULL && skill.m_pDefine->m_nID == templateId && skill.m_bLeaned)
            return &skill;
    }
    return NULL;
}

int CysLeapNet::DefaultFlySkillID(const CCharacterData* data)
{
    if (!data) return INVALID_ID;
    const int menpai = data->Get_MenPai();   // players only (CHECK_MUST_NOT(CT_MONSTER) inside); the caller is MySelf
    for (unsigned i = 0; i < sizeof(kServerQinggong) / sizeof(kServerQinggong[0]); ++i)
        if (kServerQinggong[i].menpai == menpai && Learned(data, kServerQinggong[i].skill)) return kServerQinggong[i].skill;
    for (unsigned i = 0; i < sizeof(kServerQinggong) / sizeof(kServerQinggong[0]); ++i)
        if (Learned(data, kServerQinggong[i].skill)) return kServerQinggong[i].skill;
    if (Learned(data, kAlwaysAccepted)) return kAlwaysAccepted;
    return INVALID_ID;
}


INT CCharacterData::GetDefaultFlySkillID(VOID) const
{
    return CysLeapNet::DefaultFlySkillID(this);
}

#if defined(CYS_HAVE_NETCORE)
bool CysLeapNet::IsWorldPacket(uint16_t id)
{
    return id == pg::GCCharFly::PACKET_ID;
}

bool CysLeapNet::Dispatch(const pg::Packet& packet)
{
    if (packet.packetId() != pg::GCCharFly::PACKET_ID) return false;
    const pg::GCCharFly& fly = static_cast<const pg::GCCharFly&>(packet);
    ++g_counters.repliesReceived;

    CObjectManager* objects = CObjectManager::GetMe();
    CObject* obj = objects ? (CObject*)objects->FindServerObject((INT)fly.m_objID) : NULL;
    if (!obj || !g_theKernel.IsKindOf(obj->GetClass(), GETCLASS(CObject_Character)))
    {
        ++g_counters.unknownObject;
        LeapLog("GCCharFly obj=%d skill=%d to=(%.1f,%.1f) - object not here", fly.m_objID, fly.skill_id, fly.to_x, fly.to_y);
        return true;
    }
    CObject_Character* character = (CObject_Character*)obj;
    const bool self = objects->GetMySelf() == (CObject_PlayerMySelf*)character;
    if (self) ++g_counters.repliesSelf;
    LeapLog("GCCharFly obj=%d%s logic=%d skill=%d wire_from=(%.1f,%.1f) to=(%.1f,%.1f) to2=(%.1f,%.1f) u4=%d u5=%.2f client_pos=(%.1f,%.1f)",
            fly.m_objID, self ? " (self)" : "", fly.logic_count, fly.skill_id, fly.from_x, fly.from_y, fly.to_x, fly.to_y,
            fly.to_x_2, fly.to_y_2, fly.unknow_4, fly.unknow_5, character->GetPosition().x, character->GetPosition().z);
    if (character->CysStartLeap(fly.skill_id, fVector2(character->GetPosition().x, character->GetPosition().z),
                                fVector2(fly.to_x, fly.to_y), fly.logic_count, fVector2(fly.to_x_2, fly.to_y_2), fly.unknow_4, fly.unknow_5))
        ++g_counters.leapsStarted;
    return true;
}

bool CysLeapNet::SendFly(int objId, int skillId, float fromX, float fromZ, float toX, float toZ)
{
    pg::CGCharFly* request = new pg::CGCharFly;
    request->m_objID = (uint32_t)objId;
    request->skill_id = (uint32_t)skillId;
    request->from_x = fromX; request->from_y = fromZ;
    request->to_x = toX;     request->to_y = toZ;
    if (!CysModernGame::SendModern(std::unique_ptr<pg::Packet>(request)))
    {
        ++g_counters.requestsRefused;
        return false;
    }
    ++g_counters.requestsSent;
    return true;
}
#else
bool CysLeapNet::IsWorldPacket(uint16_t) { return false; }
bool CysLeapNet::Dispatch(const pg::Packet&) { return false; }
bool CysLeapNet::SendFly(int, int, float, float, float, float) { ++g_counters.requestsRefused; return false; }
#endif

CysLeapNet::Counters CysLeapNet::Get() { return g_counters; }
