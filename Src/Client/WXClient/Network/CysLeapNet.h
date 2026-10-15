#pragma once
// CYS-MOVE2: 轻功 (qinggong leap) on the skynet CY protocol. Game.exe main thread only.
//
//   CGCharFly (1225)  {u32 objID, u32 skill_id, f32 from_x, from_y, to_x, to_y}
//       sent by CAI_MySelf::PushCommand_Fly (CY 0x140118600) after the local gates: no 500 ms lock, a learned
//       skill, IsCanFly, target clamped to 0.9 * SkillTemplate max range, one straight path unit.
//   GCCharFly (1262)  {i32 objID, i32 logic_count, i32 skill_id, f32 from(2), to(2), to again(2), i32 unknow_4,
//                      f32 unknow_5}
//       the server's answer (services/scene/skill/human/skill_15.lua effect_on_unit_once: obj:fly_to(target),
//       then GCCharFly broadcast to everyone in range).
//       MEASURED 18/09 on the private server (Build/Logs/2026-09-17-move-2/bot-fly-1-ok-8u, CGCharFly 160,150 ->
//       168,150 with skill 34): the answer came back 30 ms later as
//         obj=200 (self) logic=4 skill=34 from=160.0,150.0 to=168.0,150.0 to2=168.0,150.0 u4=0 u5=4.00
//       so `from` really is the PRE-leap position (fly_to has not moved get_world_pos() yet when the packet is
//       built), `to` and `to2` are both the target, and u5 defaults to 4 (packet.lua ctor).
//       CY's handler (0x140395860) reads only logic_count (+0x1c), skill (+0x20), to (+0x2c/0x30) and to2
//       (+0x34/0x38) into SCommand_Object 202 - NOT `from`: the visible start is always the object's own client
//       position. CysStartLeap does the same.
//
// Server side (read-only clone /home/ubuntu/cys-test-20260913, verified 18/09/2026):
//   msgagent.lua:1521 request:CGCharFly -> scenecore.lua:6146 scenecore:char_fly(who, fly):
//     1. skill_id not in define.QINGGONG_SKILL (23..31 per menpai, 110 Gusu, 4648 Erengu; 34 always) -> tips
//        "不能使用该技能", nothing else;
//     2. distance(target, own position) > 15 -> tips "超出距离", nothing else;
//     3. push_command_use_skill(skill, self, target) -> the normal skill pipeline (GCCharSkill_Send may precede
//        the GCCharFly) -> skill_15 effect: fly_to + GCCharFly.
//   So a refused leap answers with a GCScriptCommand tip only; RequestFly cannot know, it only counts.
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

    // CY's CCharacterData::GetDefaultFlySkillID: the menpai's qinggong skill when learned, else any learned one of the
    // server's set, else -1. (CY 3.71 itself keys 0x1407132c8 = skills 5271.. per menpai - a different id space than
    // this server's define.QINGGONG_SKILL, so the server's table is the one used here.)
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
