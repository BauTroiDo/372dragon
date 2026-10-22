#pragma once


























#include <cstdint>

namespace pg { class Packet; }
class CCharacterData;
struct SCLIENT_SKILL;	// CYS-LEAP: FindLearnedSkill

namespace CysLeapNet
{
    bool IsWorldPacket(uint16_t id);
    // Returns true when the packet was consumed (GCCharFly).
    bool Dispatch(const pg::Packet& packet);

    // CGCharFly on the wire. False when nothing was sent (no modern session).
    bool SendFly(int objId, int skillId, float fromX, float fromZ, float toX, float toZ);




    int DefaultFlySkillID(const CCharacterData* data);

    // CYS-LEAP 19/09: tra ky nang DA HOC theo *template id* (vi du 34), lam dung viec ma Get_Skill(34) khong lam
    // duoc: ban do ky nang cua client khoa theo `tid*100 + level` (GMDP_CharacterData.cpp:1967), nen tra bang id
    // tran LUON tra NULL. Do duoc o Build\Logs\2026-09-17-leap-gui\live-3. Tra NULL neu chua hoc.
    const SCLIENT_SKILL* FindLearnedSkill(const CCharacterData* data, int templateId);

    struct Counters
    {
        unsigned requestsSent;
        unsigned requestsRefused;
        unsigned repliesReceived;   // GCCharFly of any object
        unsigned repliesSelf;       // ... of the own character
        unsigned unknownObject;     // GCCharFly for an object this client does not have
        unsigned leapsStarted;      // CysStartLeap accepted
    };
    Counters Get();
}
