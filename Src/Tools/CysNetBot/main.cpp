// No credentials in argv, files, packet dumps, or diagnostic messages.
// CYS-SELF (17/09): --cast SKILL,TARGET now takes three kinds of TARGET - an object id, 0 = nearest live monster
// (unchanged), and -1 or "self" = the bot's own object id read from GCEnterScene. The self form is what makes the
// ally-only support skills measurable (3557 emei, 3558 tianshan, 3432 guigu, 4624 erenkgu):
// against any monster the server answers operate_result -16 (OR_WARNING, wrong camp). See Options::castSelf,
// Sk::CastPick and the GCOperateResult handler.
// CYS-POS (17/09): a fourth TARGET kind, "pos" (own position) or "pos:DX,DZ" (own position plus that offset in
// scene units), sends an explicit CGCharUseSkill.posTarget instead of letting WorldModel::makeUseSkill derive it
// from the target object. Ground-placed skills - SkillTemplate targeting_logic 7 TARGET_AE_AROUND_POSITION, e.g.
// 4468 tangmen, 841/844/847 xingxiu - read only that point (scene/skill/base.lua calculate_target_list), so this
// is the only way the bot can aim them at a chosen spot. See Options::CastStep and Sk::Cast.
// CYS-SEQ (17/09): --cast-seq "A,TA;B,TB[;...]" casts every step once in order inside ONE session and then gives
// the LAST step the full --cast treatment (cast, re-cast inside the cooldown, cast until the target dies). That
// measures skills whose server-side condition needs a state an earlier skill installs - 841/844/847 xiexingwuzu
// only work while 434 shenxiebaixiang holds the juxie state. --cast stays a one-step sequence, so every state
// below (Sk::CastPick .. Sk::CastLoop, the GCOperateResult handler, result.json) reads Options::CastStep through
// castStep() and never options.castSkill/castTarget directly.
// CYS-ITEM (17/09): the item loop needs three things the inventory phase did not have.
//  1. --use ITEM[,COUNT] sends CGUseItem (473) for a bag slot holding ITEM and reports GCUseItemResult plus the
//     hp/mp the server pushed around it. A consumable whose CommonItem "script" is skill-like (a health potion:
//     30001001 -> script 333001 -> impact 3001) is refused at full health by the script itself
//     (item_3001:OnConditionCheck -> OR_HEALTH_IS_FULL), so set the hp low before the session.
//     WorldModel is out of this agent's write scope, so the packet is built here (makeUseItem), the same way
//     CYS-POS builds its own CGCharUseSkill.
//  2. Some shop NPCs open the shop straight from OnDefaultEvent with no event list at all (Luoyang 230,308
//     bai mengsheng -> shop 14, the health-potion shop). Inv::NpcMenu now also accepts "the shop list arrived
//     without a menu" instead of timing out after 5 s and skipping the whole buy phase.
//  3. Equipping has to be shown to change the character, not just to answer 1. The bot snapshots GCDetailAttrib
//     (att/def physics+magic, hit, miss, hp_max, mp_max) and re-asks CGAskDetailAttrib after every equip/unequip,
//     so result.json carries the before/after numbers (SelfAttrs / attrsBefore / attrsAfter).
#include <winsock2.h>
#include <ws2tcpip.h>
#include <windows.h>
#include "LoginProbe.h"
#if defined(CYS_NETBOT_WORLD)
// World mode drives the same NetCore sessions as Game.exe: login -> CLAskCharLogin ->
// game socket (CGConnect first) -> enter scene -> heartbeat/move -> CGAskQuit.
#include "GameClient.h"
#include "LoginClient.h"
#include "WorldModel.h"
#include "RecordStream.h" // CYS-CORE
#include "PgPackets_combat.h"
#include "PgPackets_core.h"
#include "PgPackets_item.h"
#include "PgPackets_misc.h"
#include "PgPackets_mission.h" // CYS-EXEC: CGExecuteScript
#include "PgPackets_movement.h"
#include "PgPackets_pet_detail_types.h" // CYS-PET: GCDetailAttrib_Pet (512)
#include "PgPackets_social.h"
#include "PgPackets_team.h" // CYS-TEAM
#include <cmath>
#include <cstdlib>
#include <thread>
#endif
#include <array>
#include <chrono>
#include <cstdio>
#include <cstring>
#include <fstream>
#include <iostream>
#include <map>
#include <set>
#include <stdexcept>
#include <string>
#include <tuple>
#include <vector>

namespace {
using Clock = std::chrono::steady_clock;
using Deadline = Clock::time_point;

struct Failure : std::runtime_error {
    int code;
    Failure(int value, const char* message) : std::runtime_error(message), code(value) {}
};

struct Options {
    std::string host, account, out;
    unsigned port = 0;
    unsigned pvpPeer = 0; // opt-in fixture: 1 reject first invitation, accept next; 2 invite GUI peer
    unsigned timeoutMs = 10000;
    // World mode only (--mode world). The game port pins the LCRetCharLogin hand-off.
    bool world = false;
    unsigned gamePort = 0, guid = 0, dwellMs = 60000, heartbeatMs = 15000, walk = 0;
    bool flySet = false; float flyX = 0, flyZ = 0; int flySkill = 34; // CYS-MOVE2: --fly X,Z[,SKILL] sends one CGCharFly (1225) after setup
    // CYS-CORE: core loop (all optional; --goto X,Z walks straight, a portal area transfers the scene)
    bool chat = false, pickup = false, bag = false, record = false, gotoSet = false;
    unsigned attack = 0, skill = 0;
    float gotoX = 0, gotoZ = 0, huntX = 0, huntZ = 0;
    bool huntSet = false; // --hunt X,Z: walk there in the FINAL scene when no live monster is within 25 m
    std::string chatText = "Xin chao Dai Ly! (CysNetBot core-loop)";
    // CYS-EXEC: --exec SCRIPT,FUNC[,P1,...] (repeatable) -> CGExecuteScript before the chat line (GM console tests)
    struct Exec { uint32_t script = 0; std::string func; std::vector<int32_t> params; };
    std::vector<Exec> execs;
    // CYS-INV: inventory / equipment / NPC shop (all optional). --goto-scene limits --goto to one scene id.
    int gotoScene = -1;
    bool npcSet = false, sell = false, drop = false, buySet = false, swap = false;
    float npcX = 0, npcZ = 0;
    unsigned buyShop = 0, buyItem = 0, buyCount = 1;
    int equipSlot = -1, unequipSlot = -1;
    // CYS-RIDE: --ride FLAG -> one CGCharAutoRide (636) right after the world setup. The reply GCCharAutoRide
    // (63) is only sent on 2 of the 4 paths of scenecore:char_auto_ride, so "no reply" is data, not a bug.
    bool rideSet = false;
    unsigned rideFlag = 1;
    // --select-ride ID -> CGExteriorRequest type 7 / category 3 (set_ride) sent just before CGCharAutoRide.
    bool selectRideSet = false;
    unsigned selectRide = 0;
    // CYS-ITEM: --use ITEM[,COUNT] -> CGUseItem on the bag slot that holds ITEM (a bought slot first).
    bool useSet = false;
    unsigned useItem = 0, useCount = 1;
    bool invMode() const { return npcSet || buySet || sell || drop || swap || useSet || equipSlot >= 0 || unequipSlot >= 0; }
    // CYS-SKILL: --hotbar 1 lists the quick bar (CGAskSetting), 2 also drags a skill into the first empty main slot
    // (CGModifySetting), checks the stored value and puts the slot back; --cast SKILL,TARGET (TARGET = obj id, 0 =
    // nearest live monster, -1 / self = the bot's own object id, or pos / pos:DX,DZ = a ground point) casts one skill,
    // re-casts inside the cooldown and keeps casting until the target dies; --xinfa 1 lists the xinfa, 2 also asks to
    // study the first one (CGAskStudyXinfa).
    // CYS-SELF: TARGET -1 / self is the ally-only branch (templates 3557, 3558, 3432, 4624):
    // the server answers OR_WARNING (-16) for every monster, so the only measurable target is the caster itself.
    // CYS-POS: TARGET pos / pos:DX,DZ is the ground branch (targeting_logic 7 TARGET_AE_AROUND_POSITION).
    // CYS-SEQ: castSteps holds one entry per --cast / per --cast-seq element, in cast order; the LAST entry is the
    // measured one, so castSkill / castTarget / castSelf / castPos mirror castSteps.back() for result.json and the
    // quick-bar drag. Everything in the cast state machine reads castStep(), never these mirrors.
    struct CastStep {
        unsigned skill = 0;
        unsigned target = 0;      // object id; 0 = nearest live monster (only when !self && !pos)
        bool self = false;        // TARGET -1 / self
        bool pos = false;         // TARGET pos / pos:DX,DZ
        float dx = 0, dz = 0;     // offset added to the own position when pos
        // CYS-ALLY 17/09/2026: TARGET ally / corpse -> the nearest OTHER player, alive or dead. Two skills of the
        // 220 cannot be measured by one bot at all: 408 起死回生 needs a corpse and 423 金针渡劫 a hurt ally; both
        // answer OR_INVALID_TARGET (-8) when aimed at the caster. Run a second bot in the same scene first.
        uint8_t ally = 0;         // 0 = not an ally cast, 1 = ally (alive), 2 = corpse (dead)
    };
    std::vector<CastStep> castSteps;
    unsigned hotbar = 0, xinfa = 0, castSkill = 0, castTarget = 0;
    bool castSet = false, castSelf = false, castPos = false;
    bool skillMode() const { return hotbar > 0 || xinfa > 0 || castSet; }
    // CYS-QUEST: NPC dialogue / missions / NPC transfer. --talk X,Z walks to the NPC and opens its dialogue;
    // --quest accept|complete|full drives one mission option; --talk-option N picks the option with index N (station).
    bool talkSet = false, talkOptionSet = false, talkConfirmSet = false;
    int talkConfirm = 0; // Optional second menu choice, e.g. the real NPC sect confirmation.
    float talkX = 0, talkZ = 0;
    int questMode = 0; // 0 none, 1 accept, 2 complete, 3 full (accept then complete)
    int questScript = -1, talkOption = 0, talkScene = -1; // --talk-scene: talk only in that scene (after --goto portals)
    bool questOn() const { return talkSet || questMode != 0; }
    // CYS-TEAM: two bots, one session each. --team-invite NAME sends CGTeamInvite; --team-accept 1 answers
    // every GCTeamAskInvite / GCTeamAskApply with CGTeamRetInvite / CGTeamRetApply accept=1; --team-apply NAME
    // is the other direction (CGTeamApply to a leader). --team-at-ms N pins the invite to N ms after GCEnterScene
    // so the two processes line up without talking to each other. --hold-ms N keeps the session in world until
    // N ms after GCEnterScene (the member has to stay while the owner kills for the exp split to be visible).
    std::string teamInvite, teamApply, teamChatText, tellName, tellText;
    bool teamAccept = false, teamLeave = false, teamDismiss = false, teamInfo = false;
    bool teamAppoint = false, teamKick = false; // both act on the first roster entry that is not me
    unsigned teamAtMs = 0, teamWaitMs = 25000, holdMs = 0;
    // CYS-STAYDEAD: chet roi thi nam yen lam xac, khong tra CGPlayerDieResult (xem cho dung).
    bool stayDead = false;
    int teamExpMode = -1;
    bool teamMode() const {
        return !teamInvite.empty() || !teamApply.empty() || teamAccept || teamLeave || teamDismiss || teamInfo ||
               !teamChatText.empty() || !tellName.empty() || teamExpMode >= 0 || teamAppoint || teamKick;
    }
    // CYS-PET 17/09/2026: the 珍兽 loop. --pet 1 lists the pet bag (CGAskDetailAttrib makes the server answer with
    // one GCDetailAttrib_Pet per pet: scenecore.lua ask_detail_attrib -> human:send_pets_detail), --pet 2 also
    // summons the first usable pet (CGManipulatePet type 0 MANIPULATE_CREATEPET -> skill_11 -> human:call_up_pet),
    // keeps it out for --pet-fight-ms and puts it away again (type 1 MANIPULATE_DELETEPET -> human:recall_pet).
    // --pet-capture 1 casts skill template 1 捕兽 (SkillData id 1, 技能逻辑ID 10 -> scene/skill/human/skill_10.lua)
    // at the nearest wild pet object (GCNewPet -> WorldModel::Kind::Pet). 聚气时间 is 15000 ms, so the capture
    // answer (GCManipulatePetRet ret 1 CAPTURESUCC / 0 CAPTUREFALID) only lands ~15 s after the cast.
    unsigned pet = 0, petFightMs = 12000;
    bool petCapture = false;
    bool petMode() const { return pet > 0 || petCapture; }
    // CYS-ATTRIB 17/09/2026: the character-power loop (potential points, titles, 武魂). Every step is
    // "snapshot GCDetailAttrib -> send the CG packet -> re-ask CGAskDetailAttrib -> snapshot again", so a
    // system is only called working when a NUMBER moved, never because the server answered.
    //   --attr-point S,SP,C,I,D  -> CGReqManualAttr (598). GCDetailAttrib carries point_remain (flag byte 2
    //        bit 4) and str/spr/con/int/dex (flag byte 1 bits 32/64/128, byte 2 bits 1/2), so the spend and
    //        the stat gain are both visible. The answer is GCManualAttrResult (1031) result = ATTR_RESULT.
    //   --titles 1               -> CGCharAllTitles (1230) on my own object -> GCCharAllTitles (1227) list.
    //   --set-title ID           -> CGCharUpdateCurTitle (1192) id=ID (0 = clear); the effect shows up in
    //        GCCharBaseAttrib / GCDetailAttrib of the caster.
    //   --kfs OP[,A1,A2,A3]      -> CGKfsOperate (908) -> scenecore char_kfs_operate -> script 809270 OnAction.
    //   --set-id-title ID        -> CGCharUpdateCurTitle with id = 0 and id_title_id = ID. That is the OTHER
    //        branch of scenecore:char_update_cur_title: id ~= 0 wears a STRING title out of human.titles,
    //        id == 0 wears an ID title out of human.id_titles (the CharTitleNew rows, the ones that carry
    //        IA/IV attribute pairs). Mixing the two is the classic way to see "nothing happened".
    bool attrPointSet = false, kfsSet = false;
    int32_t attrStr = 0, attrSpr = 0, attrCon = 0, attrInt = 0, attrDex = 0;
    unsigned titles = 0;
    int64_t setTitle = -1, setIdTitle = -1;
    int32_t kfsOp = 0;
    unsigned kfsA1 = 0, kfsA2 = 0, kfsA3 = 0;
    bool attribMode() const { return attrPointSet || titles > 0 || setTitle >= 0 || setIdTitle >= 0 || kfsSet; }
};

// CYS-INV: "a,b[,c]" -> up to 3 unsigned numbers
unsigned SplitNumbers(const std::string& value, unsigned out[3]) {
    unsigned n = 0;
    size_t start = 0;
    while (n < 3) {
        const size_t comma = value.find(',', start);
        const std::string part = value.substr(start, comma == std::string::npos ? std::string::npos : comma - start);
        if (part.empty() || part.size() > 10 || part.find_first_not_of("0123456789") != std::string::npos) throw Failure(2, "invalid numeric list");
        out[n++] = static_cast<unsigned>(std::strtoul(part.c_str(), nullptr, 10));
        if (comma == std::string::npos) break;
        start = comma + 1;
    }
    return n;
}

// CYS-SEQ/CYS-POS: one "SKILL,TARGET" pair. TARGET is an object id, 0 (nearest live monster), -1 / self
// (the caster), pos (the own position) or pos:DX,DZ (the own position plus that offset, +-64 scene units).
// Case-insensitive; SplitNumbers cannot be used because the grammar is not digits-only any more.
const char* const kCastUsage = "--cast / --cast-seq need SKILL,TARGET (template id, then object id, 0 = nearest monster,"
                               " -1 or self = the bot itself, ally or corpse = the nearest other player alive or dead,"
                               " pos or pos:DX,DZ = a ground point)";

Options::CastStep ParseCastStep(const std::string& value) {
    const size_t comma = value.find(',');
    if (comma == std::string::npos) throw Failure(2, kCastUsage);
    const std::string skillPart = value.substr(0, comma);
    std::string targetPart = value.substr(comma + 1);
    if (skillPart.empty() || skillPart.size() > 10 || skillPart.find_first_not_of("0123456789") != std::string::npos)
        throw Failure(2, kCastUsage);
    Options::CastStep step;
    step.skill = static_cast<unsigned>(std::strtoul(skillPart.c_str(), nullptr, 10));
    if (step.skill > 100000) throw Failure(2, kCastUsage); // id 0 stays legal: it is a real base skill
    for (auto& c : targetPart) if (c >= 'A' && c <= 'Z') c = static_cast<char>(c - 'A' + 'a');
    if (targetPart == "-1" || targetPart == "self") { step.self = true; return step; }
    if (targetPart == "ally") { step.ally = 1; return step; }     // CYS-ALLY
    if (targetPart == "corpse") { step.ally = 2; return step; }   // CYS-ALLY
    if (targetPart == "pos") { step.pos = true; return step; }
    if (targetPart.compare(0, 4, "pos:") == 0) {
        const std::string offsets = targetPart.substr(4);
        const size_t split = offsets.find(',');
        if (split == std::string::npos) throw Failure(2, "--cast pos:DX,DZ needs both offsets");
        const std::string xPart = offsets.substr(0, split), zPart = offsets.substr(split + 1);
        if (xPart.empty() || zPart.empty() || xPart.size() > 12 || zPart.size() > 12 ||
            xPart.find_first_not_of("-+.0123456789") != std::string::npos ||
            zPart.find_first_not_of("-+.0123456789") != std::string::npos)
            throw Failure(2, "--cast pos:DX,DZ offsets must be numbers");
        step.pos = true;
        step.dx = static_cast<float>(std::atof(xPart.c_str()));
        step.dz = static_cast<float>(std::atof(zPart.c_str()));
        if (!(step.dx >= -64 && step.dx <= 64 && step.dz >= -64 && step.dz <= 64))
            throw Failure(2, "--cast pos:DX,DZ offsets must be -64..64");
        return step;
    }
    if (targetPart.empty() || targetPart.size() > 10 || targetPart.find_first_not_of("0123456789") != std::string::npos)
        throw Failure(2, kCastUsage);
    step.target = static_cast<unsigned>(std::strtoul(targetPart.c_str(), nullptr, 10));
    return step;
}

unsigned Number(const char* value) {
    unsigned n = 0;
    if (!*value) throw Failure(2, "invalid numeric option");
    for (; *value; ++value) {
        if (*value < '0' || *value > '9' || n > 65535)
            throw Failure(2, "invalid numeric option");
        n = n * 10 + static_cast<unsigned>(*value - '0');
    }
    return n;
}

Options Parse(int argc, char** argv) {
    Options options;
    bool host = false, port = false, account = false, out = false, timeout = false;
    bool mode = false, gamePort = false, guid = false, dwell = false, heartbeat = false, walk = false;
    bool chat = false, attack = false, pickup = false, bag = false, record = false, gotoOpt = false, skill = false, chatText = false, huntOpt = false;
    for (int i = 1; i < argc; i += 2) {
        if (i + 1 == argc) throw Failure(2, "option requires a value");
        const std::string key(argv[i]);
        if (key == "--host" && !host) { options.host = argv[i + 1]; host = true; }
        else if (key == "--port" && !port) { options.port = Number(argv[i + 1]); port = true; }
        else if (key == "--pvp-peer") { options.pvpPeer = Number(argv[i + 1]); if(options.pvpPeer>2)throw Failure(2,"pvp peer 0..2"); }
        else if (key == "--account" && !account) { options.account = argv[i + 1]; account = true; }
        else if (key == "--out" && !out) { options.out = argv[i + 1]; out = true; }
        else if (key == "--timeout-ms" && !timeout) { options.timeoutMs = Number(argv[i + 1]); timeout = true; }
        else if (key == "--mode" && !mode) {
            const std::string value(argv[i + 1]);
            if (value != "login" && value != "world") throw Failure(2, "mode must be login or world");
            options.world = value == "world"; mode = true;
        }
        else if (key == "--game-port" && !gamePort) { options.gamePort = Number(argv[i + 1]); gamePort = true; }
        else if (key == "--guid" && !guid) { options.guid = Number(argv[i + 1]); guid = true; }
        else if (key == "--dwell-ms" && !dwell) { options.dwellMs = Number(argv[i + 1]); dwell = true; }
        else if (key == "--heartbeat-ms" && !heartbeat) { options.heartbeatMs = Number(argv[i + 1]); heartbeat = true; }
        else if (key == "--walk" && !walk) { options.walk = Number(argv[i + 1]); walk = true; }
        else if (key == "--fly" && !options.flySet) { // CYS-MOVE2: absolute target X,Z and an optional skill id (default 34 = 轻功 of every menpai)
            unsigned v[3] = {0, 0, 34};
            if (SplitNumbers(argv[i + 1], v) < 2) throw Failure(2, "--fly needs X,Z[,SKILL]");
            options.flyX = static_cast<float>(v[0]); options.flyZ = static_cast<float>(v[1]); options.flySkill = static_cast<int>(v[2]); options.flySet = true;
        }
        // CYS-CORE
        else if (key == "--chat" && !chat) { options.chat = Number(argv[i + 1]) != 0; chat = true; }
        else if (key == "--attack" && !attack) { options.attack = Number(argv[i + 1]); attack = true; }
        else if (key == "--pickup" && !pickup) { options.pickup = Number(argv[i + 1]) != 0; pickup = true; }
        else if (key == "--bag" && !bag) { options.bag = Number(argv[i + 1]) != 0; bag = true; }
        else if (key == "--record" && !record) { options.record = Number(argv[i + 1]) != 0; record = true; }
        else if (key == "--skill" && !skill) { options.skill = Number(argv[i + 1]); skill = true; }
        else if (key == "--ride" && !options.rideSet) { options.rideFlag = Number(argv[i + 1]); options.rideSet = true; } // CYS-RIDE
        else if (key == "--select-ride" && !options.selectRideSet) { options.selectRide = Number(argv[i + 1]); options.selectRideSet = true; } // CYS-RIDE
        else if (key == "--chat-text" && !chatText) { options.chatText = argv[i + 1]; chatText = true; }
        else if (key == "--exec") { // CYS-EXEC
            std::vector<std::string> parts; std::string cur; const std::string value(argv[i + 1]);
            for (char c : value) { if (c == ',') { parts.push_back(cur); cur.clear(); } else cur.push_back(c); }
            parts.push_back(cur);
            if (parts.size() < 2 || parts.size() > 10 || parts[1].empty() || parts[1].size() > 64) throw Failure(2, "--exec SCRIPT,FUNC[,P1..P8]");
            Options::Exec e; e.script = static_cast<uint32_t>(std::strtoul(parts[0].c_str(), nullptr, 10)); e.func = parts[1];
            for (size_t k = 2; k < parts.size(); ++k) e.params.push_back(static_cast<int32_t>(std::strtol(parts[k].c_str(), nullptr, 10)));
            options.execs.push_back(e); options.chat = true; chat = true;
        }
        else if (key == "--hunt" && !huntOpt) {
            const std::string value(argv[i + 1]);
            const size_t comma = value.find(',');
            if (comma == std::string::npos) throw Failure(2, "--hunt needs X,Z");
            options.huntX = static_cast<float>(std::atof(value.substr(0, comma).c_str()));
            options.huntZ = static_cast<float>(std::atof(value.substr(comma + 1).c_str()));
            if (!(options.huntX >= 0 && options.huntX <= 4096 && options.huntZ >= 0 && options.huntZ <= 4096)) throw Failure(2, "--hunt out of range");
            options.huntSet = true; huntOpt = true;
        }
        else if (key == "--goto" && !gotoOpt) {
            const std::string value(argv[i + 1]);
            const size_t comma = value.find(',');
            if (comma == std::string::npos) throw Failure(2, "--goto needs X,Z");
            options.gotoX = static_cast<float>(std::atof(value.substr(0, comma).c_str()));
            options.gotoZ = static_cast<float>(std::atof(value.substr(comma + 1).c_str()));
            if (!(options.gotoX >= 0 && options.gotoX <= 4096 && options.gotoZ >= 0 && options.gotoZ <= 4096)) throw Failure(2, "--goto out of range");
            options.gotoSet = true; gotoOpt = true;
        }
        // CYS-INV
        else if (key == "--goto-scene" && options.gotoScene < 0) { options.gotoScene = static_cast<int>(Number(argv[i + 1])); }
        else if (key == "--npc" && !options.npcSet) {
            const std::string value(argv[i + 1]);
            const size_t comma = value.find(',');
            if (comma == std::string::npos) throw Failure(2, "--npc needs X,Z");
            options.npcX = static_cast<float>(std::atof(value.substr(0, comma).c_str()));
            options.npcZ = static_cast<float>(std::atof(value.substr(comma + 1).c_str()));
            if (!(options.npcX > 0 && options.npcX <= 4096 && options.npcZ > 0 && options.npcZ <= 4096)) throw Failure(2, "--npc out of range");
            options.npcSet = true;
        }
        else if (key == "--buy" && !options.buySet) {
            unsigned v[3] = {0, 0, 1};
            const unsigned n = SplitNumbers(argv[i + 1], v);
            if (n < 2 || v[1] == 0 || v[2] == 0 || v[2] > 5) throw Failure(2, "--buy needs SHOP,ITEM[,COUNT 1..5]");
            options.buyShop = v[0]; options.buyItem = v[1]; options.buyCount = v[2]; options.buySet = true;
        }
        // CYS-ITEM: --use ITEM[,COUNT 1..5] (CGUseItem on the bag slot that holds ITEM)
        else if (key == "--use" && !options.useSet) {
            unsigned v[3] = {0, 1, 0};
            const unsigned n = SplitNumbers(argv[i + 1], v);
            if (n < 1 || v[0] == 0 || v[1] == 0 || v[1] > 5) throw Failure(2, "--use needs ITEM[,COUNT 1..5]");
            options.useItem = v[0]; options.useCount = v[1]; options.useSet = true;
        }
        else if (key == "--equip" && options.equipSlot < 0) { options.equipSlot = static_cast<int>(Number(argv[i + 1])); if (options.equipSlot > 38) throw Failure(2, "--equip slot 0..38"); }
        else if (key == "--unequip" && options.unequipSlot < 0) { options.unequipSlot = static_cast<int>(Number(argv[i + 1])); if (options.unequipSlot > 38) throw Failure(2, "--unequip slot 0..38"); }
        else if (key == "--sell" && !options.sell) { options.sell = Number(argv[i + 1]) != 0; }
        else if (key == "--drop" && !options.drop) { options.drop = Number(argv[i + 1]) != 0; }
        else if (key == "--swap" && !options.swap) { options.swap = Number(argv[i + 1]) != 0; }
        // CYS-SKILL
        else if (key == "--hotbar" && !options.hotbar) { options.hotbar = Number(argv[i + 1]); if (options.hotbar > 2) throw Failure(2, "--hotbar 0..2"); }
        else if (key == "--xinfa" && !options.xinfa) { options.xinfa = Number(argv[i + 1]); if (options.xinfa > 2) throw Failure(2, "--xinfa 0..2"); }
        else if (key == "--cast" && !options.castSet) {
            // CYS-SELF / CYS-POS: one step; the grammar lives in ParseCastStep (digits, -1/self, pos, pos:DX,DZ).
            options.castSteps.push_back(ParseCastStep(argv[i + 1]));
            options.castSet = true;
        }
        else if (key == "--cast-seq" && !options.castSet) {
            // CYS-SEQ: "A,TA;B,TB[;...]" - every step is cast once in order, the LAST one is the measured skill.
            const std::string value(argv[i + 1]);
            std::string cur;
            for (const char c : value) {
                if (c != ';') { cur.push_back(c); continue; }
                options.castSteps.push_back(ParseCastStep(cur));
                cur.clear();
            }
            options.castSteps.push_back(ParseCastStep(cur));
            if (options.castSteps.size() < 2 || options.castSteps.size() > 6)
                throw Failure(2, "--cast-seq needs 2..6 steps separated by ';' (use --cast for a single one)");
            options.castSet = true;
        }
        // CYS-QUEST
        else if (key == "--talk" && !options.talkSet) {
            const std::string value(argv[i + 1]);
            const size_t comma = value.find(',');
            if (comma == std::string::npos) throw Failure(2, "--talk needs X,Z");
            options.talkX = static_cast<float>(std::atof(value.substr(0, comma).c_str()));
            options.talkZ = static_cast<float>(std::atof(value.substr(comma + 1).c_str()));
            if (!(options.talkX > 0 && options.talkX <= 4096 && options.talkZ > 0 && options.talkZ <= 4096)) throw Failure(2, "--talk out of range");
            options.talkSet = true;
        }
        else if (key == "--quest" && options.questMode == 0) {
            const std::string value(argv[i + 1]);
            options.questMode = value == "accept" ? 1 : value == "complete" ? 2 : value == "full" ? 3 : 0;
            if (!options.questMode) throw Failure(2, "--quest accept|complete|full");
        }
        else if (key == "--talk-scene" && options.talkScene < 0) { options.talkScene = static_cast<int>(Number(argv[i + 1])); }
        else if (key == "--quest-script" && options.questScript < 0) { options.questScript = static_cast<int>(std::strtoul(argv[i + 1], nullptr, 10)); if (options.questScript <= 0) throw Failure(2, "--quest-script needs a script id"); }
        else if (key == "--talk-option" && !options.talkOptionSet) {
            const std::string value(argv[i + 1]);
            if (value.empty() || value.size() > 8 || value.find_first_not_of("-0123456789") != std::string::npos) throw Failure(2, "--talk-option needs an integer");
            options.talkOption = std::atoi(value.c_str()); options.talkOptionSet = true;
        }
        else if (key == "--talk-confirm" && !options.talkConfirmSet) {
            const std::string value(argv[i + 1]);
            if (value.empty() || value.size() > 7 || value.find_first_not_of("0123456789") != std::string::npos)
                throw Failure(2, "--talk-confirm needs a nonnegative menu index");
            options.talkConfirm = std::atoi(value.c_str()); options.talkConfirmSet = true;
        }
        // CYS-TEAM
        else if (key == "--team-invite" && options.teamInvite.empty()) { options.teamInvite = argv[i + 1]; if (options.teamInvite.empty() || options.teamInvite.size() > 29) throw Failure(2, "--team-invite needs a character name (1..29 bytes)"); }
        else if (key == "--team-apply" && options.teamApply.empty()) { options.teamApply = argv[i + 1]; if (options.teamApply.empty() || options.teamApply.size() > 29) throw Failure(2, "--team-apply needs a character name (1..29 bytes)"); }
        else if (key == "--team-accept" && !options.teamAccept) { options.teamAccept = Number(argv[i + 1]) != 0; }
        else if (key == "--team-leave" && !options.teamLeave) { options.teamLeave = Number(argv[i + 1]) != 0; }
        else if (key == "--team-dismiss" && !options.teamDismiss) { options.teamDismiss = Number(argv[i + 1]) != 0; }
        else if (key == "--team-info" && !options.teamInfo) { options.teamInfo = Number(argv[i + 1]) != 0; }
        else if (key == "--team-appoint" && !options.teamAppoint) { options.teamAppoint = Number(argv[i + 1]) != 0; }
        else if (key == "--team-kick" && !options.teamKick) { options.teamKick = Number(argv[i + 1]) != 0; }
        else if (key == "--team-at-ms" && !options.teamAtMs) { options.teamAtMs = Number(argv[i + 1]); if (options.teamAtMs > 120000) throw Failure(2, "--team-at-ms 0..120000"); }
        else if (key == "--team-wait-ms") { options.teamWaitMs = Number(argv[i + 1]); if (options.teamWaitMs < 1000 || options.teamWaitMs > 120000) throw Failure(2, "--team-wait-ms 1000..120000"); }
        else if (key == "--team-chat" && options.teamChatText.empty()) { options.teamChatText = argv[i + 1]; }
        else if (key == "--tell" && options.tellName.empty()) { options.tellName = argv[i + 1]; }
        else if (key == "--tell-text" && options.tellText.empty()) { options.tellText = argv[i + 1]; }
        else if (key == "--team-exp-mode" && options.teamExpMode < 0) { options.teamExpMode = static_cast<int>(Number(argv[i + 1])); if (options.teamExpMode > 1) throw Failure(2, "--team-exp-mode 0 or 1"); }
        else if (key == "--hold-ms" && !options.holdMs) { options.holdMs = Number(argv[i + 1]); if (options.holdMs > 180000) throw Failure(2, "--hold-ms 0..180000"); }
        else if (key == "--stay-dead") { options.stayDead = Number(argv[i + 1]) != 0; }  // CYS-STAYDEAD
        // CYS-PET
        else if (key == "--pet" && !options.pet) { options.pet = Number(argv[i + 1]); if (options.pet > 2) throw Failure(2, "--pet 0..2"); }
        else if (key == "--pet-capture" && !options.petCapture) { options.petCapture = Number(argv[i + 1]) != 0; }
        else if (key == "--pet-fight-ms") { options.petFightMs = Number(argv[i + 1]); if (options.petFightMs > 60000) throw Failure(2, "--pet-fight-ms 0..60000"); }
        // CYS-ATTRIB: the character-power loop.
        else if (key == "--attr-point" && !options.attrPointSet) {
            unsigned five[5] = {0, 0, 0, 0, 0};
            const std::string value = argv[i + 1];
            size_t start = 0, n = 0;
            while (n < 5) {
                const size_t comma = value.find(',', start);
                const std::string part = value.substr(start, comma == std::string::npos ? std::string::npos : comma - start);
                if (part.empty()) throw Failure(2, "--attr-point STR,SPR,CON,INT,DEX");
                five[n++] = Number(part.c_str());
                if (comma == std::string::npos) break;
                start = comma + 1;
            }
            if (n != 5) throw Failure(2, "--attr-point needs five numbers STR,SPR,CON,INT,DEX");
            for (unsigned v : five) if (v > 200) throw Failure(2, "--attr-point values 0..200");
            options.attrStr = static_cast<int32_t>(five[0]); options.attrSpr = static_cast<int32_t>(five[1]);
            options.attrCon = static_cast<int32_t>(five[2]); options.attrInt = static_cast<int32_t>(five[3]);
            options.attrDex = static_cast<int32_t>(five[4]);
            if (five[0] + five[1] + five[2] + five[3] + five[4] == 0) throw Failure(2, "--attr-point: at least one point");
            options.attrPointSet = true;
        }
        else if (key == "--titles" && !options.titles) { options.titles = Number(argv[i + 1]); if (options.titles > 1) throw Failure(2, "--titles 0|1"); }
        else if (key == "--set-title" && options.setTitle < 0) { options.setTitle = static_cast<int64_t>(Number(argv[i + 1])); }
        else if (key == "--set-id-title" && options.setIdTitle < 0) { options.setIdTitle = static_cast<int64_t>(Number(argv[i + 1])); if (options.setIdTitle > 65535) throw Failure(2, "--set-id-title 0..65535"); }
        else if (key == "--kfs" && !options.kfsSet) {
            unsigned four[3] = {0, 0, 0};
            const std::string value = argv[i + 1];
            const size_t first = value.find(',');
            options.kfsOp = static_cast<int32_t>(Number(value.substr(0, first).c_str()));
            if (first != std::string::npos) SplitNumbers(value.substr(first + 1), four);
            if (four[0] > 255 || four[1] > 255 || four[2] > 127) throw Failure(2, "--kfs OP,A1 0..255,A2 0..255,A3 0..127");
            options.kfsA1 = four[0]; options.kfsA2 = four[1]; options.kfsA3 = four[2];
            options.kfsSet = true;
        }
        else throw Failure(2, "unknown or duplicate option");
    }
    // CYS-SEQ: the measured skill is the last step; mirror it so result.json, the quick-bar drag and --help stay honest.
    if (options.castSet && !options.castSteps.empty()) {
        const auto& last = options.castSteps.back();
        options.castSkill = last.skill; options.castTarget = last.target;
        options.castSelf = last.self; options.castPos = last.pos;
    }
    if ((options.questMode || options.talkOptionSet) && !options.talkSet) throw Failure(2, "--quest / --talk-option need --talk X,Z");
    if (options.talkConfirmSet && !options.talkOptionSet) throw Failure(2, "--talk-confirm needs --talk-option");
    if (options.questMode && options.talkOptionSet) throw Failure(2, "--quest and --talk-option are exclusive");
    // CYS-TEAM
    if (!options.tellName.empty() && options.tellText.empty()) throw Failure(2, "--tell needs --tell-text");
    if (options.tellText.empty() == false && options.tellName.empty()) throw Failure(2, "--tell-text needs --tell NAME");
    if (!options.teamInvite.empty() && !options.teamApply.empty()) throw Failure(2, "--team-invite and --team-apply are exclusive");
    if (!host || !port || !account || !out || options.port == 0 || options.port > 65535 ||
        options.timeoutMs < 1000 || options.timeoutMs > 30000 ||
        !cysbot::AllowedAccount(options.account))
        throw Failure(2, "explicit host, port, account test00..test15 and output are required");
    IN_ADDR address{};
    if (InetPtonA(AF_INET, options.host.c_str(), &address) != 1)
        throw Failure(2, "host must be an explicit IPv4 address");
    if (options.world) {
#if defined(CYS_NETBOT_WORLD)
        if (!gamePort || !guid || options.gamePort == 0 || options.gamePort > 65535 || options.guid == 0 ||
            options.dwellMs < 1000 || options.dwellMs > 300000 || options.heartbeatMs < 100 ||
            options.heartbeatMs > 60000 || options.walk > 1 || (ntohl(address.S_un.S_addr) >> 24) != 127)
            throw Failure(2, "world mode needs loopback host, --game-port, --guid, dwell 1000..300000, walk 0..1");
        if (options.attack > 10 || options.chatText.empty() || options.chatText.size() > 200 || options.skill > 100000)
            throw Failure(2, "core loop: --attack 0..10, --chat-text 1..200 bytes, --skill 0..100000");
#else
        throw Failure(2, "this build has no NetCore world mode");
#endif
    } else if (gamePort || guid || dwell || heartbeat || walk || chat || attack || pickup || bag || record || gotoOpt || skill || chatText || huntOpt || options.skillMode()) {
        throw Failure(2, "world options require --mode world");
    }
    return options;
}

std::string OutputDirectory(const std::string& relative) {
    // Deliberately narrow: all artifacts below this checkout's Build/Logs.
    std::string normalized = relative;
    for (auto& c : normalized) if (c == '\\') c = '/';
    if (normalized.compare(0, 11, "Build/Logs/") != 0 || normalized.size() <= 11)
        throw Failure(2, "output must be relative below Build/Logs");
    size_t start = 0;
    while (start < normalized.size()) {
        const size_t end = normalized.find('/', start);
        const auto part = normalized.substr(start, end == std::string::npos ? end : end - start);
        if (part.empty() || part == "." || part == "..")
            throw Failure(2, "invalid output path component");
        for (const char c : part)
            if (!(c >= 'a' && c <= 'z') && !(c >= 'A' && c <= 'Z') &&
                !(c >= '0' && c <= '9') && c != '-' && c != '_')
                throw Failure(2, "output path accepts only letters, digits, dash and underscore");
        if (end == std::string::npos) break;
        start = end + 1;
    }
    if (normalized.back() == '/') throw Failure(2, "invalid output path");
    const DWORD required=GetCurrentDirectoryA(0,nullptr);
    if (!required) throw Failure(2,"cannot determine checkout working directory");
    std::vector<char> current(required);
    if (!GetCurrentDirectoryA(required,current.data()))
        throw Failure(2,"cannot determine checkout working directory");
    std::string path(current.data());
    auto regularFile=[](const std::string& name) {
        const DWORD attr=GetFileAttributesA(name.c_str());
        return attr!=INVALID_FILE_ATTRIBUTES && !(attr & (FILE_ATTRIBUTE_DIRECTORY|FILE_ATTRIBUTE_REPARSE_POINT));
    };
    // Runtime cwd, never the compiler's checkout: CI builds inside Build/ci/wt.
    // Require project markers before any report directory is created.
    if (!regularFile(path+"/Src/CMakeLists.txt") ||
        !regularFile(path+"/Timeline/TIMELINE_vi.md") ||
        GetFileAttributesA((path+"/.git").c_str())==INVALID_FILE_ATTRIBUTES)
        throw Failure(2,"working directory must be the CY-Source checkout root");
    for (std::string ancestor=path; !ancestor.empty();) {
        const DWORD attr=GetFileAttributesA(ancestor.c_str());
        if (attr==INVALID_FILE_ATTRIBUTES || (attr & FILE_ATTRIBUTE_REPARSE_POINT))
            throw Failure(2,"checkout path may not cross a reparse point");
        const size_t slash=ancestor.find_last_of("/\\");
        if (slash==std::string::npos || slash<3) break;
        ancestor.resize(slash);
    }
    start = 0;
    while (start < normalized.size()) {
        const size_t end = normalized.find('/', start);
        path += '/' + normalized.substr(start, end == std::string::npos ? end : end - start);
        const DWORD attr = GetFileAttributesA(path.c_str());
        const bool last = end == std::string::npos;
        if (attr != INVALID_FILE_ATTRIBUTES) {
            if (last || !(attr & FILE_ATTRIBUTE_DIRECTORY) || (attr & FILE_ATTRIBUTE_REPARSE_POINT))
                throw Failure(2, "output must be new and may not cross a reparse point");
        } else if (!CreateDirectoryA(path.c_str(), nullptr)) {
            throw Failure(2, "cannot create output directory");
        }
        if (last) break;
        start = end + 1;
    }
    return path;
}

struct Secret {
    std::vector<char> bytes;
    Secret() {
        const DWORD needed = GetEnvironmentVariableA("CYS_BOT_PWD", nullptr, 0);
        if (needed < 2 || needed > 43) throw Failure(2, "CYS_BOT_PWD missing or unsupported length");
        bytes.resize(needed);
        const DWORD got = GetEnvironmentVariableA("CYS_BOT_PWD", bytes.data(), needed);
        SetEnvironmentVariableA("CYS_BOT_PWD", nullptr);
        if (!got || got + 1 != needed) {
            cysbot::Wipe(bytes.data(), bytes.size());
            throw Failure(2, "cannot read CYS_BOT_PWD");
        }
    }
    ~Secret() { cysbot::Wipe(bytes.data(), bytes.size()); }
    Secret(const Secret&) = delete;
    Secret& operator=(const Secret&) = delete;
};

struct SecretFrame {
    std::vector<uint8_t> bytes;
    ~SecretFrame() { cysbot::Wipe(bytes.data(), bytes.size()); }
};

struct LoginPacket : pg::CLAskLogin {
    ~LoginPacket() { cysbot::Wipe(account.data(), account.size()); }
};

struct Winsock {
    Winsock() {
        WSADATA data{};
        if (WSAStartup(MAKEWORD(2, 2), &data)) throw Failure(3, "WSAStartup failed");
    }
    ~Winsock() { WSACleanup(); }
};

class Connection {
public:
    ~Connection() { close(); }
    void close() {
        if (socket_ != INVALID_SOCKET) {
            shutdown(socket_, SD_BOTH);
            closesocket(socket_);
            socket_ = INVALID_SOCKET;
        }
    }
    void connect(const Options& options, Deadline deadline) {
        socket_ = ::socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
        if (socket_ == INVALID_SOCKET) throw Failure(3, "socket failed");
        u_long nonblocking = 1;
        if (ioctlsocket(socket_, FIONBIO, &nonblocking)) throw Failure(3, "nonblocking socket failed");
        BOOL nodelay = TRUE;
        if (setsockopt(socket_, IPPROTO_TCP, TCP_NODELAY,
                       reinterpret_cast<const char*>(&nodelay), sizeof(nodelay)))
            throw Failure(3, "TCP_NODELAY failed");
        sockaddr_in address{};
        address.sin_family = AF_INET;
        address.sin_port = htons(static_cast<u_short>(options.port));
        InetPtonA(AF_INET, options.host.c_str(), &address.sin_addr);
        if (::connect(socket_, reinterpret_cast<const sockaddr*>(&address), sizeof(address)) == SOCKET_ERROR) {
            if (WSAGetLastError() != WSAEWOULDBLOCK) throw Failure(3, "connect failed");
            wait(POLLWRNORM, deadline);
            int error = 0;
            int length = sizeof(error);
            if (getsockopt(socket_, SOL_SOCKET, SO_ERROR, reinterpret_cast<char*>(&error), &length) || error)
                throw Failure(3, "connect refused");
        }
    }
    void send(const std::vector<uint8_t>& bytes, Deadline deadline) {
        size_t sent = 0;
        while (sent < bytes.size()) {
            wait(POLLWRNORM, deadline);
            const int n = ::send(socket_, reinterpret_cast<const char*>(bytes.data() + sent),
                                 static_cast<int>(bytes.size() - sent), 0);
            if (n == SOCKET_ERROR && WSAGetLastError() == WSAEWOULDBLOCK) continue;
            if (n <= 0) throw Failure(4, "send failed");
            sent += static_cast<size_t>(n);
        }
    }
    size_t receive(uint8_t* bytes, size_t capacity, Deadline deadline) {
        for (;;) {
            wait(POLLRDNORM, deadline);
            const int n = ::recv(socket_, reinterpret_cast<char*>(bytes), static_cast<int>(capacity), 0);
            if (n == SOCKET_ERROR && WSAGetLastError() == WSAEWOULDBLOCK) continue;
            if (n == 0) throw Failure(4, "server closed connection");
            if (n < 0) throw Failure(4, "receive failed");
            return static_cast<size_t>(n);
        }
    }
private:
    SOCKET socket_ = INVALID_SOCKET;
    void wait(short events, Deadline deadline) {
        for (;;) {
            const auto remain = std::chrono::duration_cast<std::chrono::milliseconds>(deadline - Clock::now()).count();
            if (remain <= 0) throw Failure(4, "network deadline exceeded");
            WSAPOLLFD poll{};
            poll.fd = socket_;
            poll.events = events;
            const int count = WSAPoll(&poll, 1, static_cast<int>((std::min)(remain, 1000LL)));
            if (count == SOCKET_ERROR) throw Failure(4, "socket poll failed");
            if (count == 0) continue;
            // Buffered data may accompany HUP; drain readable bytes first.
            if (poll.revents & events) return;
            if (poll.revents & (POLLERR | POLLHUP | POLLNVAL)) throw Failure(4, "socket closed or failed");
        }
    }
};

struct Count { size_t count = 0, bytes = 0, ok = 0, fail = 0; };
struct Report {
    std::string directory;
    std::ofstream failures, frames;
    std::map<std::tuple<int, bool, uint16_t>, Count> counts;
    size_t tx = 0, rx = 0, decodeFailures = 0;
    explicit Report(const std::string& path) : directory(path),
        failures(path + "/failures.tsv"), frames(path + "/frames.tsv") {
        if (!failures || !frames) throw Failure(2, "cannot create report files");
        failures << "proto\tid\terror\tfield\toffset\tbody_size\n";
        frames << "direction\tproto\tid\tidx\tbody_size\tstrict_ok\n";
    }
    void frame(bool outbound, pg::Proto proto, const pg::FrameHeader& h, bool ok) {
        const int p = proto == pg::Proto::Login ? 1 : 0;
        auto& count = counts[std::make_tuple(p, outbound, h.id)];
        ++count.count; count.bytes += h.size;
        if (ok) ++count.ok; else ++count.fail;
        if (outbound) ++tx; else ++rx;
        frames << (outbound ? "tx" : "rx") << '\t' << (p ? "login" : "game") << '\t'
               << h.id << '\t' << h.idx << '\t' << h.size << '\t' << ok << '\n';
        frames.flush();
    }
    void bad(const cysbot::Frame& frame, const cysbot::Decoded& d) {
        ++decodeFailures;
        failures << (d.proto == pg::Proto::Login ? "login" : "game") << '\t' << frame.header.id
                 << '\t' << d.result.error << '\t' << d.result.field << '\t'
                 << d.result.errorPos << '\t' << frame.body.size() << '\n';
        failures.flush();
    }
    void finish(const Options& options, const cysbot::LoginConversation& session, int code,
                const char* error, long long elapsedMs, bool connected, size_t pending) {
        std::ofstream table(directory + "/report.tsv");
        table << "proto\tdir\tid\tname\tcount\tbytes\tok\tfail\n";
        for (const auto& entry : counts) {
            const bool login = std::get<0>(entry.first) != 0;
            const bool outbound = std::get<1>(entry.first);
            const uint16_t id = std::get<2>(entry.first);
            const auto* info = pg::findPacket(login ? pg::Proto::Login : pg::Proto::Game, id);
            const auto& c = entry.second;
            table << (login ? "login" : "game") << '\t'
                  << (login ? (outbound ? "CL" : "LC") : (outbound ? "CG" : "GC")) << '\t'
                  << id << '\t' << (info ? info->name : "unknown") << '\t' << c.count << '\t'
                  << c.bytes << '\t' << c.ok << '\t' << c.fail << '\n';
        }
        std::ofstream result(directory + "/result.json");
        result << "{\n  \"scope\": \"login-auth-charlist-only\",\n  \"host\": \"" << options.host
               << "\",\n  \"port\": " << options.port << ",\n  \"exit_code\": " << code
               << ",\n  \"error\": \"" << error << "\",\n  \"state\": \"" << session.state()
               << "\",\n  \"login_flag\": ";
        if (session.hasLoginFlag()) result << session.loginFlag(); else result << "null";
        result << ",\n  \"retry_after_seconds\": " << session.retryAfterSeconds()
               << ",\n  \"automatic_retries\": 0,\n  \"character_count\": " << session.characterCount()
               << ",\n  \"tx_frames\": " << tx << ",\n  \"rx_frames\": " << rx
               << ",\n  \"decode_failures\": " << decodeFailures
               << ",\n  \"pending_bytes\": " << pending << ",\n  \"elapsed_ms\": " << elapsedMs
               << ",\n  \"connected\": " << (connected ? "true" : "false")
               << ",\n  \"socket_closed\": true,\n  \"game_connection_created\": false\n}\n";
        table.flush(); result.flush(); failures.flush(); frames.flush();
        if (!table || !result || !failures || !frames) throw Failure(2, "report write failed");
    }
};

int Run(const Options& options, const std::string& directory) {
    Report report(directory);
    cysbot::LoginConversation session;
    cysbot::FrameAssembler assembler;
    cysbot::TxSequencer sequence;
    const auto started = Clock::now();
    const auto overall = started + std::chrono::seconds(90);
    int code = 0;
    const char* error = "";
    bool connected = false;
    try {
        Secret secret;
        LoginPacket login;
        if (!cysbot::MakeLogin(options.account, secret.bytes.data(), secret.bytes.size() - 1, login))
            throw Failure(2, "unsupported credential format");
        cysbot::Wipe(secret.bytes.data(), secret.bytes.size());
        Winsock winsock;
        Connection connection;
        auto deadline = [&]() { return (std::min)(overall, Clock::now() + std::chrono::milliseconds(options.timeoutMs)); };
        connection.connect(options, deadline());
        connected = true;
        auto send = [&](const pg::Packet& packet) {
            if (report.tx >= 3) throw Failure(7, "transmit frame limit");
            SecretFrame wire;
            if (!pg::encodeFrame(packet, sequence.next(), wire.bytes)) throw Failure(7, "encode failed");
            if (packet.packetId() == pg::CLAskLogin::PACKET_ID && wire.bytes.size() != 955)
                throw Failure(7, "modern login body must be 949 bytes");
            pg::FrameHeader header{};
            pg::readFrameHeader(wire.bytes.data(), wire.bytes.size(), header);
            connection.send(wire.bytes, deadline());
            sequence.admitted();
            report.frame(true, packet.packetProto(), header, true);
        };
        pg::CLConnect connect;
        connect.set_account(options.account);
        connect.set_version("tlbb");
        send(connect);
        auto stateDeadline = deadline();
        size_t receivedBytes = 0;
        bool complete = false;
        while (!complete) {
            std::array<uint8_t, 16384> buffer{};
            const size_t count = connection.receive(buffer.data(), buffer.size(), stateDeadline);
            receivedBytes += count;
            if (receivedBytes > 256 * 1024) throw Failure(7, "receive byte limit");
            std::vector<cysbot::Frame> frames;
            const bool assembled = assembler.feed(buffer.data(), count, frames);
            cysbot::Wipe(buffer.data(), buffer.size());
            if (!assembled) throw Failure(7, assembler.error());
            for (auto& frame : frames) {
                if (report.rx >= 64) throw Failure(7, "receive frame limit");
                auto decoded = cysbot::DecodeInbound(frame);
                report.frame(false, decoded.proto, frame.header, decoded.result.ok);
                if (!decoded.packet) {
                    report.bad(frame, decoded);
                    cysbot::Wipe(frame.body.data(), frame.body.size());
                    throw Failure(5, "strict packet decode failed");
                }
                cysbot::Wipe(frame.body.data(), frame.body.size());
                const auto action = session.accept(*decoded.packet);
                if (action == cysbot::Action::Failed) throw Failure(6, session.error());
                if (action == cysbot::Action::SendLogin) {
                    send(login);
                    cysbot::Wipe(login.account.data(), login.account.size());
                    stateDeadline = deadline();
                } else if (action == cysbot::Action::SendCharList) {
                    pg::CLAskCharList list;
                    list.set_account(options.account);
                    send(list);
                    stateDeadline = deadline();
                } else if (action == cysbot::Action::Complete) {
                    complete = true;
                }
            }
        }
        if (assembler.pending()) throw Failure(7, "partial frame at completion");
        // Login only: no character session exists, so CGAskQuit is not applicable.
        connection.close();
    } catch (const Failure& failure) {
        code = failure.code;
        error = failure.what();
        // Keep the message alive after the exception object is destroyed.
        const std::string message(error);
        report.finish(options, session, code, message.c_str(),
                      std::chrono::duration_cast<std::chrono::milliseconds>(Clock::now() - started).count(),
                      connected, assembler.pending());
        std::cout << "CysNetBot failed code=" << code << " reason=" << message << '\n';
        return code;
    }
    report.finish(options, session, code, error,
                  std::chrono::duration_cast<std::chrono::milliseconds>(Clock::now() - started).count(),
                  connected, assembler.pending());
    std::cout << "CysNetBot login_auth=ok charlist=ok characters=" << session.characterCount()
              << " tx=" << report.tx << " rx=" << report.rx << " decode_failures=0 socket_closed=1\n";
    return 0;
}
#if defined(CYS_NETBOT_WORLD)
const char* LoginEventName(cys::net::EventType type) {
    using cys::net::EventType;
    switch (type) {
    case EventType::Connected: return "connected";
    case EventType::Authenticated: return "authenticated";
    case EventType::Refused: return "refused";
    case EventType::CharacterList: return "character_list";
    case EventType::Error: return "error";
    case EventType::Cancelled: return "cancelled";
    case EventType::CharacterCreated: return "character_created";
    case EventType::CreatePermission: return "create_permission";
    case EventType::CharacterLoginGranted: return "character_login_granted";
    case EventType::CharacterLoginRefused: return "character_login_refused";
    }
    return "unknown";
}
const char* GameEventName(cys::net::GameEventType type) {
    using cys::net::GameEventType;
    switch (type) {
    case GameEventType::Connected: return "connected";
    case GameEventType::Packet: return "packet";
    case GameEventType::Transfer: return "transfer";
    case GameEventType::QuitComplete: return "quit_complete";
    case GameEventType::Error: return "error";
    case GameEventType::Cancelled: return "cancelled";
    }
    return "unknown";
}

// Headless world session with the approved test character. Reports hold IDs,
// counters and phases only: no packet bodies, key, account field or peer text.
// CYS-CORE: optional core loop after entering: --goto (straight-line walk, portal transfer),
// --chat, --attack N (nearest monster: CGLockTarget + CGCharUseSkill until it dies), --pickup
// (CGOpenItemBox/CGPickBoxItem on the own drop box), --bag (CGAskMyBagList), --record 1
// (PGWORLD1 fixture of the game socket that saw the combat, keys zeroed).
int RunWorld(const Options& options, const std::string& directory) {
    using namespace cys::net;
    const auto started = Clock::now();
    auto elapsed = [&]() {
        return static_cast<long long>(std::chrono::duration_cast<std::chrono::milliseconds>(Clock::now() - started).count());
    };
    std::ofstream log(directory + "/world-events.tsv");
    if (!log) throw Failure(2, "cannot create report files");
    log << "ms\tsocket\tevent\tgeneration\tid\tname\tbody_size\tphase\n";
    std::ofstream core(directory + "/core-loop.tsv");
    if (!core) throw Failure(2, "cannot create report files");
    core << "ms\tstep\tdetail\n";
    auto note = [&](const char* step, const std::string& detail) { core << elapsed() << '\t' << step << '\t' << detail << '\n'; core.flush(); };
    int code = 0;
    std::string error, charLogin = "not_requested", terminalName = "none";
    std::string charName; // CYS-TEAM: own character name from LCRetCharList (the invite key on the wire)
    int32_t loginFlag = 0, quitFlag = -1;
    uint32_t characterCount = 0, generation = 0, movesSent = 0;
    bool flySent = false; // CYS-MOVE2
    uint16_t ticketIndex = 0;
    Counters loginCounters;
    GameCounters gameCounters;
    LoginClient login;
    WorldModel world;
    std::unique_ptr<GameTicket> ticket;
    {
        Secret secret;
        std::string password(secret.bytes.data(), secret.bytes.size() - 1);
        cysbot::Wipe(secret.bytes.data(), secret.bytes.size());
        cys::net::Options lo;
        lo.mode = SessionMode::Interactive;
        lo.connectTimeoutMs = options.timeoutMs; lo.replyTimeoutMs = options.timeoutMs;
        lo.overallTimeoutMs = 120000; lo.idleTimeoutMs = 30000;
        lo.approvedGamePort = static_cast<uint16_t>(options.gamePort);
        const bool accepted = login.start(Endpoint{options.host, static_cast<uint16_t>(options.port)},
                                          options.account, password, lo);
        if (!password.empty()) cysbot::Wipe(&password[0], password.size());
        if (!accepted) throw Failure(2, "login start rejected");
    }
    bool loginDone = false;
    const auto loginDeadline = Clock::now() + std::chrono::seconds(40);
    while (!loginDone && Clock::now() < loginDeadline) {
        login.pump([&](Event&& event) {
            loginCounters = event.counters;
            log << elapsed() << "\tlogin\t" << LoginEventName(event.type) << "\t0\t" << event.packetId << "\t\t"
                << event.bodySize << "\t\n";
            switch (event.type) {
            case EventType::CharacterList: {
                const auto* list = dynamic_cast<const pg::LCRetCharList*>(event.packet.get());
                bool found = false;
                if (list) {
                    characterCount = static_cast<uint32_t>(list->charlist.size());
                    for (const auto& role : list->charlist) {
                        found = found || role.guid == options.guid;
                        if (role.guid == options.guid) charName = pg::getText(role.nickname); // CYS-TEAM
                    }
                }
                if (!found) {
                    code = 6; error = "requested GUID is not in the character list; no character login sent";
                    login.cancel(); loginDone = true;
                } else if (!login.requestCharacterLogin(options.guid)) {
                    code = 7; error = "character login command rejected"; login.cancel(); loginDone = true;
                } else charLogin = "requested";
                break;
            }
            case EventType::CharacterLoginGranted:
                ticket = std::move(event.ticket);
                charLogin = ticket && ticket->valid() ? "granted" : "invalid";
                if (ticket) ticketIndex = ticket->nextTxIndex();
                loginDone = true;
                break;
            case EventType::CharacterLoginRefused:
                code = 6; charLogin = "refused"; error = "character login refused by server; no retry performed";
                login.cancel(); loginDone = true;
                break;
            case EventType::Refused:
                code = 6; loginFlag = event.loginFlag; error = "login refused; no retry performed"; loginDone = true;
                break;
            case EventType::Error:
                code = event.error == ErrorCode::Decode ? 5 : event.error == ErrorCode::UnexpectedPacket ? 7 : 4;
                error = event.message; loginDone = true;
                break;
            case EventType::Cancelled:
                loginDone = true;
                break;
            default: break;
            }
        }, 8);
        if (!loginDone) std::this_thread::sleep_for(std::chrono::milliseconds(5));
    }
    if (!loginDone) { login.cancel(); code = 4; error = "login deadline exceeded"; }
    GameClient game;
    GameEvent terminal;
    bool haveTerminal = false;
    std::shared_ptr<record::Recorder> recorder;
    if (code == 0 && ticket && ticket->valid()) {
        GameOptions go;
        go.approvedGamePort = static_cast<uint16_t>(options.gamePort);
        go.heartbeatIntervalMs = options.heartbeatMs;
        go.connectTimeoutMs = options.timeoutMs;
        if (options.record) { // CYS-CORE: game sockets only; the login socket (credentials) is never recorded
            recorder.reset(new record::Recorder);
            go.streamFactory = record::RecordingStreamFactory(std::shared_ptr<StreamFactory>(), recorder);
        }
        if (!game.start(std::move(*ticket), go)) { code = 7; error = "game session start rejected"; }
    } else if (code == 0) {
        code = 7; error = "no valid game ticket";
    }
    // CYS-CORE: core-loop bookkeeping
    enum class Step { Enter, Setup, Goto, Team, Attack, Pickup, Chat, Bag, Inv, Skills, Quest, Pet, Attrib, Quit }; // CYS-ATTRIB
    Step step = Step::Enter;
    Clock::time_point worldAt{}, stepAt{}, swingAt{}, arriveAt{};
    bool inWorld = false, quitAsked = false, setupSent = false;
    float startX = 0, startY = 0;
    uint32_t target = 0, kills = 0, skillsSent = 0, chatsSent = 0, chatEchoes = 0, boxOpened = 0, picksSent = 0;
    uint32_t locksSent = 0, bagAsks = 0, notifyAsks = 0, targetsTried = 0;
    uint32_t rideAsks = 0; // CYS-RIDE
    // server-impact: targets the server refuses for the chosen skill (OR_WARNING -16 / OR_INVALID_TARGET -8, e.g. friendly NPC)
    std::set<uint32_t> rejectedTargets;
    uint32_t rejectHits = 0;
    int32_t skillId = -1;
    const bool coreMode = options.chat || options.attack > 0 || options.pickup || options.bag || options.gotoSet || options.huntSet || options.invMode() || options.skillMode() || options.questOn() || options.teamMode() || options.petMode();
    // CYS-TEAM: one linear team script per session; the two processes only synchronise through --team-at-ms.
    enum class Tm { Wait, Invite, InviteWait, Join, Info, InfoWait, Option, OptionWait, Appoint, AppointWait,
                    Kick, KickWait, Chat, ChatWait, Tell, TellWait, Done };
    Tm tm = Tm::Wait;
    bool teamDone = false, teamLeaveSent = false, teamAccepted = false;
    uint32_t invitesSent = 0, acceptsSent = 0, teamInfoAsks = 0, teamChatsSent = 0, tellsSent = 0, memberInfoAsks = 0;
    uint32_t teamChatsSeenBefore = 0, tellsSeenBefore = 0, tipsSeen = 0;
    int32_t acceptedInviter = 0;
    Clock::time_point tmAt = Clock::now();
    std::string teamLog;
    auto stepName = [&](Step s) {
        switch (s) {
        case Step::Enter: return "enter"; case Step::Setup: return "setup"; case Step::Goto: return "goto";
        case Step::Attack: return "attack"; case Step::Pickup: return "pickup"; case Step::Chat: return "chat";
        case Step::Bag: return "bag"; case Step::Inv: return "inventory"; case Step::Skills: return "skills"; case Step::Quest: return "quest";
        case Step::Team: return "team"; case Step::Pet: return "pet"; case Step::Attrib: return "attrib"; // CYS-TEAM / CYS-PET / CYS-ATTRIB
        default: return "quit";
        }
    };
    auto go = [&](Step next, const std::string& why) {
        step = next; stepAt = Clock::now();
        note(stepName(next), why);
    };
    Clock::time_point lastSendAt = Clock::now();
    auto send = [&](std::unique_ptr<pg::Packet> packet, const char* what) {
        if (!packet) { note("send", std::string(what) + " not built"); return false; }
        const uint16_t id = packet->packetId();
        lastSendAt = Clock::now();
        if (!game.send(std::move(packet))) {
            note("send", std::string(what) + " refused id=" + std::to_string(id) + " code=" + ErrorCodeName(game.lastCommandError()));
            return false;
        }
        return true;
    };
    size_t execsSent = 0; Clock::time_point execAt = Clock::now(); // CYS-EXEC
    auto sinceExec = [&]() { return static_cast<long long>(std::chrono::duration_cast<std::chrono::milliseconds>(Clock::now() - execAt).count()); };
    auto sinceStep = [&]() { return static_cast<long long>(std::chrono::duration_cast<std::chrono::milliseconds>(Clock::now() - stepAt).count()); };
    auto speed = [&]() { return world.mySpeed() > 0.5f ? world.mySpeed() : 4.0f; };
    auto distanceTo = [&](float x, float y) { return std::sqrt((x - world.myX()) * (x - world.myX()) + (y - world.myY()) * (y - world.myY())); };
    // Straight-line waypoints of at most `segment` units; the private server does not re-check walls.
    auto walkTo = [&](float x, float y, float stopShort) {
        const float dx = x - world.myX(), dy = y - world.myY();
        float dist = std::sqrt(dx * dx + dy * dy);
        if (dist <= stopShort) return 0.0f;
        const float travel = dist - stopShort;
        std::vector<std::pair<float, float>> points;
        const float segment = 10.0f;
        const unsigned count = static_cast<unsigned>((std::min)(16.0f, std::ceil(travel / segment)));
        for (unsigned i = 1; i <= count; ++i) {
            const float t = (travel * i / count) / dist;
            points.push_back(std::make_pair(world.myX() + dx * t, world.myY() + dy * t));
        }
        if (send(world.makeMovePath(points), "CGCharMove path")) {
            ++movesSent;
            char text[160];
            std::snprintf(text, sizeof(text), "from %.1f,%.1f to %.1f,%.1f waypoints=%u travel=%.1f speed=%.2f",
                          world.myX(), world.myY(), points.back().first, points.back().second, count, travel, speed());
            note("walk", text);
            return travel / speed();
        }
        return -1.0f;
    };
    // CYS-INV: inventory / equipment / NPC shop steps (after the core-loop steps, before CGAskQuit).
    // CYS-ITEM: Use / UseWait sit after Swap and before Final, so --use spends what --buy just bought.
    enum class Inv { Ask, AskWait, NpcWalk, NpcArrive, NpcTalk, NpcMenu, ShopWait, Buy, BuyWait, BuyBag, Unequip, UnequipWait,
                     Equip, EquipWait, Split, SplitWait, Sell, SellWait, Drop, DropWait, Swap, SwapWait, SwapBack, SwapBackWait,
                     Use, UseWait, Final, FinalWait, FundSell, FundWait };
    Inv inv = Inv::Ask;
    bool invDone = false, funded = false;
    unsigned buyCount = options.buyCount;
    int fundSlot = -1, swapFrom = -1, swapTo = -1;
    Clock::time_point invAt = Clock::now(), npcArriveAt{};
    uint32_t invBase = 0, npcObject = 0, usedSlotMask = 0;
    std::vector<uint8_t> bought;
    std::map<uint8_t, WorldModel::BagItem> bagBefore;
    int64_t moneyBefore = -1;
    // CYS-ITEM: --use bookkeeping. useLeft counts the CGUseItem still to send; useSlot / useIndexBefore /
    // useHpBefore are the state of the one being measured right now.
    unsigned useLeft = options.useSet ? options.useCount : 0, usesSent = 0, usesOk = 0;
    int useSlot = -1;
    uint32_t useCountBefore = 0;
    int useHpBefore = -1, useMpBefore = -1;
    int32_t useResult = 0; // last GCUseItemResult.result (WorldModel only counts the packet)
    std::string useLog;
    // CYS-ITEM: the own GCDetailAttrib, so "equipping changed the character" is a number and not just result 1.
    // Every field is optional in the packet (22 flag bytes, see PgPackets_combat GCDetailAttrib::read), so only
    // the ones actually present are copied.
    struct SelfAttrs {
        bool valid = false;
        uint32_t level = 0, hp = 0, hpMax = 0, mp = 0, mpMax = 0;
        uint32_t attP = 0, attM = 0, defP = 0, defM = 0, hit = 0, miss = 0;
        // CYS-ATTRIB: the five base stats, the unspent potential points and the 修炼 (xiulian) bonuses. All of
        // them ride in the same GCDetailAttrib, so one snapshot covers the potential-point system AND xiulian.
        uint32_t pointRemain = 0, str = 0, spr = 0, con = 0, intel = 0, dex = 0;
        uint32_t xlStr = 0, xlSpr = 0, xlCon = 0, xlInt = 0, xlDex = 0;
        uint32_t xlAttP = 0, xlAttM = 0, xlDefP = 0, xlDefM = 0, xlHit = 0, xlMiss = 0;
        uint32_t mindAttack = 0, mindDefend = 0;
        std::string text() const {
            return "level=" + std::to_string(level) + " hp=" + std::to_string(hp) + "/" + std::to_string(hpMax) +
                   " mp=" + std::to_string(mp) + "/" + std::to_string(mpMax) +
                   " att_p=" + std::to_string(attP) + " att_m=" + std::to_string(attM) +
                   " def_p=" + std::to_string(defP) + " def_m=" + std::to_string(defM) +
                   " hit=" + std::to_string(hit) + " miss=" + std::to_string(miss);
        }
        // CYS-ATTRIB: the power-system view of the same packet, printed next to text() so a log line shows both.
        std::string powerText() const {
            return "point_remain=" + std::to_string(pointRemain) +
                   " str=" + std::to_string(str) + " spr=" + std::to_string(spr) + " con=" + std::to_string(con) +
                   " int=" + std::to_string(intel) + " dex=" + std::to_string(dex) +
                   " xiulian=[" + std::to_string(xlStr) + "," + std::to_string(xlSpr) + "," + std::to_string(xlCon) +
                   "," + std::to_string(xlInt) + "," + std::to_string(xlDex) + "|" + std::to_string(xlAttP) +
                   "," + std::to_string(xlAttM) + "," + std::to_string(xlDefP) + "," + std::to_string(xlDefM) +
                   "," + std::to_string(xlHit) + "," + std::to_string(xlMiss) + "]" +
                   " mind=" + std::to_string(mindAttack) + "/" + std::to_string(mindDefend);
        }
        std::string json() const {
            return std::string("{\"valid\": ") + (valid ? "true" : "false") +
                   ", \"level\": " + std::to_string(level) + ", \"hp\": " + std::to_string(hp) +
                   ", \"hp_max\": " + std::to_string(hpMax) + ", \"mp\": " + std::to_string(mp) +
                   ", \"mp_max\": " + std::to_string(mpMax) + ", \"att_p\": " + std::to_string(attP) +
                   ", \"att_m\": " + std::to_string(attM) + ", \"def_p\": " + std::to_string(defP) +
                   ", \"def_m\": " + std::to_string(defM) + ", \"hit\": " + std::to_string(hit) +
                   ", \"miss\": " + std::to_string(miss) + ", \"point_remain\": " + std::to_string(pointRemain) +
                   ", \"str\": " + std::to_string(str) + ", \"spr\": " + std::to_string(spr) +
                   ", \"con\": " + std::to_string(con) + ", \"int\": " + std::to_string(intel) +
                   ", \"dex\": " + std::to_string(dex) +
                   ", \"xiulian_str\": " + std::to_string(xlStr) + ", \"xiulian_spr\": " + std::to_string(xlSpr) +
                   ", \"xiulian_con\": " + std::to_string(xlCon) + ", \"xiulian_int\": " + std::to_string(xlInt) +
                   ", \"xiulian_dex\": " + std::to_string(xlDex) +
                   ", \"xiulian_att_p\": " + std::to_string(xlAttP) + ", \"xiulian_att_m\": " + std::to_string(xlAttM) +
                   ", \"xiulian_def_p\": " + std::to_string(xlDefP) + ", \"xiulian_def_m\": " + std::to_string(xlDefM) +
                   ", \"xiulian_hit\": " + std::to_string(xlHit) + ", \"xiulian_miss\": " + std::to_string(xlMiss) +
                   ", \"mind_attack\": " + std::to_string(mindAttack) + ", \"mind_defend\": " + std::to_string(mindDefend) + "}";
        }
    };
    SelfAttrs attrs, attrsStart, attrsAfterUnequip, attrsAfterEquip;
    uint32_t attribUpdates = 0, shopBase = 0;
    bool unequipAsked = false, equipAsked = false, useAsked = false;
    uint32_t useBagBase = 0;
    // CYS-ITEM: WorldModel::apply only subtracts NEGATIVE hp_modification from myHp_, so a heal is invisible there.
    // A health potion is exactly the positive case, so count it here: this is the number that says whether the
    // consumable did anything at all.
    uint32_t healsOnMe = 0;
    int64_t healedHp = 0;
    std::string invLog; // compact summary for result.json
    auto invName = [](Inv v) {
        static const char* const names[] = {"ask", "ask_wait", "npc_walk", "npc_arrive", "npc_talk", "npc_menu", "shop_wait", "buy",
            "buy_wait", "buy_bag", "unequip", "unequip_wait", "equip", "equip_wait", "split", "split_wait", "sell", "sell_wait", "drop", "drop_wait", "swap", "swap_wait", "swap_back",
            "swap_back_wait", "use", "use_wait", "final", "final_wait", "fund_sell", "fund_wait"};
        return names[static_cast<int>(v)];
    };
    auto invAge = [&]() { return static_cast<long long>(std::chrono::duration_cast<std::chrono::milliseconds>(Clock::now() - invAt).count()); };
    auto setInv = [&](Inv next, const std::string& why) { inv = next; invAt = Clock::now(); note(invName(next), why); };
    auto bagText = [&]() {
        std::string text;
        for (const auto& e : world.bag()) text += (text.empty() ? "" : " ") + std::to_string(e.first) + ":" + std::to_string(e.second.itemIndex) + "x" + std::to_string(e.second.count);
        return text;
    };
    auto equipText = [&]() {
        std::string text;
        for (const auto& e : world.equips()) text += (text.empty() ? "" : " ") + std::to_string(e.first) + ":" + std::to_string(e.second.itemIndex);
        return text;
    };
    // Order of the optional phases: NPC shop -> buy -> equip -> unequip -> sell -> drop -> final bag/equip listing.
    auto invNext = [&](Inv after) {
        const int a = static_cast<int>(after);
        if (a < static_cast<int>(Inv::NpcWalk) && options.npcSet) return Inv::NpcWalk;
        if (a < static_cast<int>(Inv::Buy) && options.buySet) return Inv::Buy;
        if (a < static_cast<int>(Inv::Unequip) && options.unequipSlot >= 0) return Inv::Unequip;
        if (a < static_cast<int>(Inv::Equip) && options.equipSlot >= 0) return Inv::Equip;
        if (a < static_cast<int>(Inv::Split) && options.sell && options.drop && bought.size() == 1) return Inv::Split;
        if (a < static_cast<int>(Inv::Sell) && options.sell) return Inv::Sell;
        if (a < static_cast<int>(Inv::Drop) && options.drop) return Inv::Drop;
        if (a < static_cast<int>(Inv::Swap) && options.swap) return Inv::Swap;
        if (a < static_cast<int>(Inv::Use) && options.useSet && useLeft > 0) return Inv::Use; // CYS-ITEM
        return Inv::Final;
    };
    // CYS-ITEM: item.lua CGUseItem. WorldModel has no maker for it and is outside this tool's write scope, so the
    // packet is filled here from what scenecore.lua char_use_item reads: bagIndex + item_index have to agree (the
    // handler drops the packet otherwise), pet_guid / target_bag_index stay empty for a self potion, and
    // target_obj_id / target_pos are the caster - human ai push_command_use_item passes them straight to the item
    // script, and a health potion (script 333001 -> impact 3001) only ever acts on the user.
    auto makeUseItem = [&](uint8_t bagIndex, uint32_t itemIndex) -> std::unique_ptr<pg::Packet> {
        std::unique_ptr<pg::CGUseItem> packet(new pg::CGUseItem);
        packet->bagIndex = bagIndex;
        packet->item_index = itemIndex;
        packet->target_obj_id = static_cast<int32_t>(world.myObjectId());
        packet->target_pos_x = world.myX();
        packet->target_pos_y = world.myY();
        packet->target_dir = 0;
        packet->target_bag_index = 255;
        return std::unique_ptr<pg::Packet>(packet.release());
    };
    // CYS-ITEM: the bag slot to consume - a slot filled by --buy first, then any slot holding the item.
    auto findUseSlot = [&]() -> int {
        for (uint8_t slot : bought) {
            auto e = world.bag().find(slot);
            if (e != world.bag().end() && e->second.itemIndex == options.useItem && e->second.count > 0) return slot;
        }
        for (const auto& e : world.bag())
            if (e.second.itemIndex == options.useItem && e.second.count > 0) return e.first;
        return -1;
    };
    auto takeBought = [&](const char* purpose) -> int {
        for (size_t i = 0; i < bought.size() && i < 32; ++i) {
            if (usedSlotMask & (1u << i)) continue;
            usedSlotMask |= 1u << i;
            note(purpose, "bought slot " + std::to_string(bought[i]));
            return bought[i];
        }
        return -1;
    };
    auto runInventory = [&]() {
        const auto& st = world.stats();
        switch (inv) {
        case Inv::Ask:
            invBase = st.bagLists;
            moneyBefore = world.myMoney();
            send(world.makeAskDetailAttrib(), "CGAskDetailAttrib");
            send(world.makeAskDetailEquipList(), "CGAskDetailEquipList");
            send(world.makeAskMyBagList(), "CGAskMyBagList");
            setInv(Inv::AskWait, "CGAskDetailAttrib + CGAskDetailEquipList + CGAskMyBagList");
            break;
        case Inv::AskWait:
            if ((st.equipLists > 0 && st.bagLists > invBase) || invAge() > 4000) {
                note("inv_state", "money=" + std::to_string(world.myMoney()) + " jiaozi=" + std::to_string(world.myJiaozi()) + " equips=[" + equipText() + "] bag=[" + bagText() + "]");
                invLog += "start equips=[" + equipText() + "] bag=[" + bagText() + "]; ";
                attrsStart = attrs; // CYS-ITEM
                note("attrs_start", attrs.text());
                invLog += "attrs start " + attrs.text() + "; ";
                setInv(invNext(Inv::AskWait), "listing done");
            }
            break;
        case Inv::NpcWalk: {
            const float d = distanceTo(options.npcX, options.npcZ);
            if (d <= 3.0f) { setInv(Inv::NpcTalk, "already near the NPC"); break; }
            const float seconds = walkTo(options.npcX, options.npcZ, 2.0f);
            if (seconds < 0) { invLog += "npc walk refused; "; setInv(invNext(Inv::BuyBag), "walk refused"); break; }
            npcArriveAt = Clock::now() + std::chrono::milliseconds(static_cast<long long>(seconds * 1000) + 1500);
            setInv(Inv::NpcArrive, "walking to the NPC");
            break;
        }
        case Inv::NpcArrive:
            if (Clock::now() >= npcArriveAt) setInv(Inv::NpcTalk, "arrived (model)");
            break;
        case Inv::NpcTalk: {
            float d = 0;
            npcObject = world.nearestObjectAt(options.npcX, options.npcZ, 5.0f, &d);
            if (!npcObject) {
                if (invAge() > 3000) { invLog += "no NPC object near --npc; "; setInv(invNext(Inv::BuyBag), "no NPC object within 5 m of --npc"); }
                break;
            }
            invBase = st.scriptEventLists;
            shopBase = st.shopLists; // CYS-ITEM: some NPCs answer with the shop itself, never with a menu
            char text[96];
            std::snprintf(text, sizeof(text), "npc=%u dist=%.1f -> CGCharDefaultEvent", npcObject, d);
            send(world.makeCharDefaultEvent(npcObject), "CGCharDefaultEvent");
            setInv(Inv::NpcMenu, text);
            break;
        }
        case Inv::NpcMenu: {
            // CYS-ITEM: OnDefaultEvent may call DispatchShopItem straight away, with no event list at all - that is
            // how the health-potion shop works (Luoyang bai mengsheng 230,308 -> shop 14). Waiting 5 s for a menu
            // that never comes used to skip the whole buy phase, so take the shop when it arrives on its own.
            if (st.shopLists > shopBase) {
                invBase = shopBase;
                note("npc_menu", "no event list: the NPC opened the shop directly");
                setInv(Inv::ShopWait, "GCShopMerchandiseList without a menu");
                break;
            }
            if (st.scriptEventLists > invBase) {
                const WorldModel::ScriptEvent* pick = nullptr;
                std::string menu;
                for (const auto& e : world.scriptEvents()) {
                    menu += (menu.empty() ? "" : " ") + std::to_string(e.scriptId) + "/" + std::to_string(e.index) + "/t" + std::to_string(e.type);
                    if (!pick && e.type == 7) pick = &e;
                }
                note("npc_menu", "options=[" + menu + "]");
                if (!pick) { invLog += "NPC menu without a shop option; "; setInv(invNext(Inv::BuyBag), "no type-7 option"); break; }
                invBase = st.shopLists;
                send(world.makeEventRequest(pick->scriptId, pick->index, static_cast<int32_t>(npcObject)), "CGEventRequest");
                setInv(Inv::ShopWait, "CGEventRequest script=" + std::to_string(pick->scriptId) + " index=" + std::to_string(pick->index));
            } else if (invAge() > 5000) { invLog += "no GCScriptCommand; "; setInv(invNext(Inv::BuyBag), "no NPC menu within 5 s"); }
            break;
        }
        case Inv::ShopWait:
            if (st.shopLists > invBase) {
                const auto& shop = world.shop();
                note("shop", "GCShopMerchandiseList shop=" + std::to_string(shop.shopId) + " npc=" + std::to_string(shop.npc) + " type=" + std::to_string(shop.type) +
                     " goods=" + std::to_string(shop.goods.size()) + " unique=" + std::to_string(shop.uniqueId));
                invLog += "shop " + std::to_string(shop.shopId) + " goods " + std::to_string(shop.goods.size()) + "; ";
                setInv(invNext(Inv::ShopWait), "shop open");
            } else if (invAge() > 5000) { invLog += "no shop list; "; setInv(invNext(Inv::BuyBag), "no GCShopMerchandiseList within 5 s"); }
            break;
        case Inv::Buy: {
            const auto& shop = world.shop();
            int merch = -1;
            if (shop.open && (options.buyShop == 0 || shop.shopId == static_cast<int32_t>(options.buyShop)))
                for (size_t i = 0; i < shop.goods.size(); ++i) if (shop.goods[i].itemIndex == options.buyItem) { merch = static_cast<int>(i); break; }
            if (merch < 0) { invLog += "item not in the open shop; "; setInv(invNext(Inv::BuyBag), "item " + std::to_string(options.buyItem) + " not sold by the open shop"); break; }
            {
                // Money check (currency 1 = gold for the Dali merchants): sell one non-equipment stack first when short.
                const int64_t gold = world.myMoney() > 0 ? world.myMoney() : 0, jiaozi = world.myJiaozi() > 0 ? world.myJiaozi() : 0;
                const int64_t money = shop.type == 8 ? gold + jiaozi : world.myMoney();
                const int64_t price = static_cast<int64_t>(shop.goods[merch].price);
                if (money >= 0 && price > 0 && money < price * buyCount) {
                    if (options.sell && !funded) {
                        funded = true;
                        for (const auto& e : world.bag()) if (e.first >= 100 && e.second.itemIndex / 10000000 != 1) { fundSlot = e.first; break; }
                        if (fundSlot < 0) for (const auto& e : world.bag()) if (e.second.itemIndex / 10000000 != 1) { fundSlot = e.first; break; }
                        if (fundSlot >= 0) {
                            invBase = st.shopSells;
                            send(world.makeShopSell(static_cast<uint8_t>(fundSlot)), "CGShopSell");
                            setInv(Inv::FundWait, "money " + std::to_string(money) + " < " + std::to_string(price * buyCount) + ": CGShopSell bag=" + std::to_string(fundSlot) + " first");
                            break;
                        }
                    }
                    const unsigned affordable = static_cast<unsigned>(money / price);
                    if (affordable == 0) { invLog += "not enough money (" + std::to_string(money) + "); "; setInv(invNext(Inv::BuyBag), "not enough money"); break; }
                    note("buy", "count " + std::to_string(buyCount) + " -> " + std::to_string(affordable) + " (money " + std::to_string(money) + ")");
                    buyCount = affordable;
                }
            }
            bagBefore = world.bag();
            moneyBefore = world.myMoney();
            invBase = st.shopBuys;
            send(world.makeShopBuy(static_cast<uint8_t>(merch), buyCount), "CGShopBuy");
            setInv(Inv::BuyWait, "CGShopBuy index=" + std::to_string(merch) + " count=" + std::to_string(buyCount) + " price=" + std::to_string(shop.goods[merch].price));
            break;
        }
        case Inv::BuyWait:
            if (st.shopBuys > invBase && invAge() >= 800) {
                note("buy", "GCShopBuy result=" + std::to_string(world.lastBuy().code) + " item=" + std::to_string(world.lastBuy().itemIndex) + " count=" + std::to_string(world.lastBuy().other));
                invBase = st.bagLists;
                send(world.makeAskMyBagList(), "CGAskMyBagList");
                setInv(Inv::BuyBag, "refresh bag");
            } else if (invAge() > 5000) { invLog += "no GCShopBuy; "; setInv(invNext(Inv::BuyBag), "no GCShopBuy within 5 s"); }
            break;
        case Inv::BuyBag:
            if (st.bagLists > invBase || invAge() > 3000) {
                bought.clear();
                for (const auto& e : world.bag()) {
                    if (e.second.itemIndex != options.buyItem) continue;
                    auto before = bagBefore.find(e.first);
                    if (before == bagBefore.end() || before->second.guid.series != e.second.guid.series) bought.push_back(e.first);
                }
                std::string slots;
                for (uint8_t b : bought) slots += (slots.empty() ? "" : ",") + std::to_string(b);
                note("bought", "slots=[" + slots + "] money " + std::to_string(moneyBefore) + " -> " + std::to_string(world.myMoney()));
                invLog += "buy result " + std::to_string(world.lastBuy().code) + " slots [" + slots + "] money " + std::to_string(moneyBefore) + "->" + std::to_string(world.myMoney()) + "; ";
                setInv(invNext(Inv::BuyBag), "buy done");
            }
            break;
        case Inv::Equip: {
            int slot = -1;
            for (size_t i = 0; i < bought.size() && i < 32 && slot < 0; ++i) {
                auto e = world.bag().find(bought[i]);
                if (!(usedSlotMask & (1u << i)) && e != world.bag().end() && e->second.itemIndex / 10000000 == 1) { usedSlotMask |= 1u << i; slot = bought[i]; }
            }
            if (slot < 0) for (const auto& e : world.bag()) if (e.second.itemIndex / 10000000 == 1) { slot = e.first; break; }
            if (slot < 0) { invLog += "no equipment in the bag; "; setInv(invNext(Inv::EquipWait), "no equipment in the bag"); break; }
            invBase = st.useEquips;
            send(world.makeUseEquip(static_cast<uint8_t>(slot), static_cast<uint8_t>(options.equipSlot)), "CGUseEquip");
            setInv(Inv::EquipWait, "CGUseEquip bag=" + std::to_string(slot) + " point=" + std::to_string(options.equipSlot));
            break;
        }
        case Inv::EquipWait:
            // CYS-ITEM: after the result, ask the attributes again and wait ~1.2 s so the change is a number.
            if (st.useEquips > invBase && !equipAsked) {
                equipAsked = true;
                const auto& r = world.lastUseEquip();
                note("equip", "GCUseEquipResult result=" + std::to_string(r.code) + " point=" + std::to_string(r.point) + " item=" + std::to_string(r.itemIndex) + " old=" + std::to_string(r.other) + " bag=" + std::to_string(r.bagIndex));
                invLog += "equip result " + std::to_string(r.code) + " item " + std::to_string(r.itemIndex) + " old " + std::to_string(r.other) + "; ";
                send(world.makeAskDetailEquipList(), "CGAskDetailEquipList");
                send(world.makeAskDetailAttrib(), "CGAskDetailAttrib");
                invAt = Clock::now();
                break;
            }
            if (equipAsked && invAge() >= 1200) {
                attrsAfterEquip = attrs;
                note("attrs_after_equip", attrs.text());
                invLog += "attrs after equip " + attrs.text() + "; ";
                setInv(invNext(Inv::EquipWait), "equip done");
            } else if (!equipAsked && invAge() > 5000) { invLog += "no GCUseEquipResult (server tip only?); "; setInv(invNext(Inv::EquipWait), "no GCUseEquipResult within 5 s"); }
            break;
        case Inv::Unequip:
            invBase = st.unEquips;
            send(world.makeUnEquip(static_cast<uint8_t>(options.unequipSlot)), "CGUnEquip");
            setInv(Inv::UnequipWait, "CGUnEquip point=" + std::to_string(options.unequipSlot));
            break;
        case Inv::UnequipWait:
            // CYS-ITEM: same attribute re-read as EquipWait, so the pair "unequipped -> equipped" has both numbers.
            if (st.unEquips > invBase && !unequipAsked) {
                unequipAsked = true;
                const auto& r = world.lastUnEquip();
                note("unequip", "GCUnEquipResult result=" + std::to_string(r.code) + " item=" + std::to_string(r.itemIndex) + " bag=" + std::to_string(r.bagIndex));
                invLog += "unequip result " + std::to_string(r.code) + " item " + std::to_string(r.itemIndex) + " bag " + std::to_string(r.bagIndex) + "; ";
                send(world.makeAskDetailAttrib(), "CGAskDetailAttrib");
                send(world.makeAskMyBagList(), "CGAskMyBagList");
                invAt = Clock::now();
                break;
            }
            if (unequipAsked && invAge() >= 1200) {
                attrsAfterUnequip = attrs;
                note("attrs_after_unequip", attrs.text());
                invLog += "attrs after unequip " + attrs.text() + "; ";
                setInv(invNext(Inv::UnequipWait), "unequip done");
            } else if (!unequipAsked && invAge() > 5000) { invLog += "no GCUnEquipResult; "; setInv(invNext(Inv::UnequipWait), "no GCUnEquipResult within 5 s"); }
            break;
        case Inv::Sell: {
            const int slot = takeBought("sell");
            if (slot < 0) { invLog += "nothing bought to sell; "; setInv(invNext(Inv::SellWait), "no bought item left to sell"); break; }
            moneyBefore = world.myMoney();
            invBase = st.shopSells;
            send(world.makeShopSell(static_cast<uint8_t>(slot)), "CGShopSell");
            setInv(Inv::SellWait, "CGShopSell bag=" + std::to_string(slot));
            break;
        }
        case Inv::SellWait:
            if (st.shopSells > invBase && invAge() >= 600) {
                note("sell", "GCShopSell result=" + std::to_string(world.lastSell().code) + " money " + std::to_string(moneyBefore) + " -> " + std::to_string(world.myMoney()));
                invLog += "sell result " + std::to_string(world.lastSell().code) + " money " + std::to_string(moneyBefore) + "->" + std::to_string(world.myMoney()) + "; ";
                setInv(invNext(Inv::SellWait), "sell done");
            } else if (invAge() > 5000) { invLog += "no GCShopSell; "; setInv(invNext(Inv::SellWait), "no GCShopSell within 5 s"); }
            break;
        case Inv::Drop: {
            const int slot = takeBought("drop");
            if (slot < 0) { invLog += "nothing bought to drop; "; setInv(invNext(Inv::DropWait), "no bought item left to drop"); break; }
            invBase = st.discards;
            send(world.makeDiscardItem(static_cast<uint8_t>(slot)), "CGDiscardItem");
            setInv(Inv::DropWait, "CGDiscardItem bag=" + std::to_string(slot));
            break;
        }
        case Inv::DropWait:
            if (st.discards > invBase) {
                const auto& r = world.lastDiscard();
                note("drop", "GCDiscardItemResult result=" + std::to_string(r.code) + " bag=" + std::to_string(r.bagIndex) + " item=" + std::to_string(r.itemIndex));
                invLog += "drop result " + std::to_string(r.code) + " item " + std::to_string(r.itemIndex) + "; ";
                setInv(invNext(Inv::DropWait), "drop done");
            } else if (invAge() > 5000) { invLog += "no GCDiscardItemResult; "; setInv(invNext(Inv::DropWait), "no GCDiscardItemResult within 5 s"); }
            break;
        case Inv::Final:
            invBase = st.bagLists;
            send(world.makeAskDetailEquipList(), "CGAskDetailEquipList");
            send(world.makeAskMyBagList(), "CGAskMyBagList");
            setInv(Inv::FinalWait, "final listing");
            break;
        case Inv::Split: {
            // one stack bought but both --sell and --drop: split one unit off (CGSplitItem BAG_CON) -> two bought slots
            const auto e = world.bag().find(bought.empty() ? 255 : bought[0]);
            if (e == world.bag().end()) { setInv(invNext(Inv::SplitWait), "bought stack not in the bag"); break; }
            invBase = st.splits;
            send(world.makeSplitItem(bought[0], 1), "CGSplitItem");
            setInv(Inv::SplitWait, "CGSplitItem bag=" + std::to_string(bought[0]) + " num=1");
            break;
        }
        case Inv::SplitWait:
            if (st.splits > invBase && invAge() >= 600) {
                const auto& r = world.lastSplit();
                note("split", "GCSplitItemResult result=" + std::to_string(r.code) + " new_slot=" + std::to_string(r.bagIndex) + " item=" + std::to_string(r.itemIndex));
                invLog += "split result " + std::to_string(r.code) + " slot " + std::to_string(r.bagIndex) + "; ";
                if (r.code == 2 && r.bagIndex != 255) bought.push_back(r.bagIndex);
                setInv(invNext(Inv::SplitWait), "split done");
            } else if (invAge() > 5000) { invLog += "no GCSplitItemResult; "; setInv(invNext(Inv::SplitWait), "no GCSplitItemResult within 5 s"); }
            break;
        case Inv::Swap: {
            // move the first prop-bag item to the first free prop slot and back (CGPackage_SwapItem, "xep" in the bag)
            int from = -1, to = -1;
            for (const auto& e : world.bag()) if (e.first < 100) { from = e.first; break; }
            for (int i = 0; i < 100 && from >= 0; ++i) if (!world.bag().count(static_cast<uint8_t>(i))) { to = i; break; }
            if (from < 0 || to < 0) { setInv(invNext(Inv::SwapBackWait), "no item/free slot to swap"); break; }
            swapFrom = from; swapTo = to;
            invBase = st.swaps;
            send(world.makePackageSwap(static_cast<uint8_t>(from), static_cast<uint8_t>(to)), "CGPackage_SwapItem");
            setInv(Inv::SwapWait, "CGPackage_SwapItem " + std::to_string(from) + " -> " + std::to_string(to));
            break;
        }
        case Inv::SwapWait:
        case Inv::SwapBackWait:
            if (st.swaps > invBase && invAge() >= 600) {
                const auto& r = world.lastSwap();
                note("swap", "GCPackage_SwapItem result=" + std::to_string(r.code) + " from=" + std::to_string(r.point) + " to=" + std::to_string(r.bagIndex) + " bag=[" + bagText() + "]");
                invLog += "swap result " + std::to_string(r.code) + " " + std::to_string(r.point) + "->" + std::to_string(r.bagIndex) + "; ";
                if (inv == Inv::SwapWait) setInv(Inv::SwapBack, "swap back");
                else setInv(invNext(Inv::SwapBackWait), "swap done");
            } else if (invAge() > 5000) { invLog += "no GCPackage_SwapItem; "; setInv(invNext(Inv::SwapBackWait), "no GCPackage_SwapItem within 5 s"); }
            break;
        case Inv::SwapBack:
            invBase = st.swaps;
            send(world.makePackageSwap(static_cast<uint8_t>(swapTo), static_cast<uint8_t>(swapFrom)), "CGPackage_SwapItem");
            setInv(Inv::SwapBackWait, "CGPackage_SwapItem " + std::to_string(swapTo) + " -> " + std::to_string(swapFrom));
            break;
        // CYS-ITEM: consume one unit of --use ITEM and measure what the server did with it.
        case Inv::Use: {
            useSlot = findUseSlot();
            if (useSlot < 0) {
                useLog += "item " + std::to_string(options.useItem) + " not in the bag; ";
                useLeft = 0;
                setInv(Inv::Final, "nothing to use");
                break;
            }
            const auto e = world.bag().find(static_cast<uint8_t>(useSlot));
            useCountBefore = e == world.bag().end() ? 0 : e->second.count;
            useHpBefore = world.myHp();
            useMpBefore = attrs.valid ? static_cast<int>(attrs.mp) : -1;
            invBase = st.useItems;
            if (!send(makeUseItem(static_cast<uint8_t>(useSlot), options.useItem), "CGUseItem")) {
                useLog += "CGUseItem refused by the worker; ";
                useLeft = 0;
                setInv(Inv::Final, "CGUseItem refused");
                break;
            }
            ++usesSent;
            setInv(Inv::UseWait, "CGUseItem bag=" + std::to_string(useSlot) + " item=" + std::to_string(options.useItem) +
                                 " hp=" + std::to_string(useHpBefore) + "/" + std::to_string(world.myMaxHp()) +
                                 " count=" + std::to_string(useCountBefore));
            break;
        }
        case Inv::UseWait:
            // GCUseItemResult comes back at once, the heal follows as GCDetailHealsAndDamages. The stack size must
            // come from a fresh GCMyBagList: WorldModel fills BagItem::count = 1 for every GCItemInfo (it does not
            // read the stack size out of ItemInfo), so the per-slot count is wrong until the next full list.
            if (st.useItems > invBase && !useAsked) {
                useAsked = true;
                useBagBase = st.bagLists;
                send(world.makeAskDetailAttrib(), "CGAskDetailAttrib");
                send(world.makeAskMyBagList(), "CGAskMyBagList");
                invAt = Clock::now();
                break;
            }
            if ((useAsked && st.bagLists > useBagBase && invAge() >= 1200) || invAge() > 5000) {
                const auto e = world.bag().find(static_cast<uint8_t>(useSlot));
                const uint32_t after = e == world.bag().end() ? 0 : e->second.count;
                const bool answered = useAsked;
                if (answered && useResult == 0) ++usesOk;
                const std::string line =
                    "slot=" + std::to_string(useSlot) + " item=" + std::to_string(options.useItem) +
                    " result=" + (answered ? std::to_string(useResult) : std::string("none")) +
                    " hp " + std::to_string(useHpBefore) + "->" + std::to_string(world.myHp()) + "/" + std::to_string(world.myMaxHp()) +
                    " count " + std::to_string(useCountBefore) + "->" + std::to_string(after);
                note("use", line);
                useLog += line + "; ";
                if (useLeft > 0) --useLeft;
                useAsked = false;
                setInv(useLeft > 0 ? Inv::Use : Inv::Final, useLeft > 0 ? "use again" : "use done");
            }
            break;
        case Inv::FundSell:
            break;
        case Inv::FundWait:
            if (st.shopSells > invBase && invAge() >= 800 && invAge() < 900) send(world.makeAskDetailAttrib(), "CGAskDetailAttrib");
            if (st.shopSells > invBase && invAge() >= 2000) {
                note("fund", "GCShopSell result=" + std::to_string(world.lastSell().code) + " money " + std::to_string(moneyBefore) + " -> " + std::to_string(world.myMoney()));
                invLog += "fund sell bag " + std::to_string(fundSlot) + " result " + std::to_string(world.lastSell().code) + " money ->" + std::to_string(world.myMoney()) + "; ";
                setInv(Inv::Buy, "retry buy after the sale");
            } else if (invAge() > 6000) { invLog += "no GCShopSell for the fund sale; "; setInv(Inv::Buy, "no GCShopSell within 6 s"); }
            break;
        case Inv::FinalWait:
            if ((st.bagLists > invBase && invAge() >= 1500) || invAge() > 4000) {
                note("inv_state", "money=" + std::to_string(world.myMoney()) + " jiaozi=" + std::to_string(world.myJiaozi()) + " equips=[" + equipText() + "] bag=[" + bagText() + "]");
                invLog += "end equips=[" + equipText() + "] bag=[" + bagText() + "]";
                invDone = true;
                go(Step::Quit, "inventory done");
            }
            break;
        }
    };
    // CYS-SKILL: quick bar (CGAskSetting / CGModifySetting), xinfa list / study, one cast + re-cast inside the cooldown.
    enum class Sk { Ask, AskWait, SetBar, SetWait, Verify, VerifyWait, Restore, RestoreWait, RestoreVerify, RestoreVerifyWait,
                    Study, StudyWait, CastPick, CastArrive, Cast, CastWait, Recast, RecastWait, CastLoop, Done };
    Sk sk = Sk::Ask;
    bool skillsDone = false;
    Clock::time_point skAt = Clock::now(), castAt{};
    uint32_t skBase = 0, skBase2 = 0, skBase3 = 0, skBase4 = 0, castTargetId = 0, casts = 0, castKills = 0, castRejects = 0;
    // CYS-SEQ: which --cast-seq step is running. CYS-POS: the ground point of the running step, frozen at
    // Sk::CastPick so the re-cast repeats the same point even if the bot drifts a little.
    size_t castIndex = 0;
    float castPosX = 0, castPosZ = 0;
    int skHpBefore = -1; // CYS-HP: own hp right before a cast (a full-hp heal is invisible in heal_sum otherwise)
    std::string castSeqText; // the parsed steps, in cast order, for result.json (ASCII, no quotes)
    for (size_t s = 0; s < options.castSteps.size(); ++s) {
        const auto& cs = options.castSteps[s];
        char one[64];
        if (cs.self) std::snprintf(one, sizeof(one), "%u,self", cs.skill);
        else if (cs.ally) std::snprintf(one, sizeof(one), "%u,%s", cs.skill, cs.ally == 2 ? "corpse" : "ally");  // CYS-ALLY
        else if (cs.pos && cs.dx == 0 && cs.dz == 0) std::snprintf(one, sizeof(one), "%u,pos", cs.skill);
        else if (cs.pos) std::snprintf(one, sizeof(one), "%u,pos:%.1f,%.1f", cs.skill, cs.dx, cs.dz);
        else std::snprintf(one, sizeof(one), "%u,%u", cs.skill, cs.target);
        castSeqText += (s ? ";" : "") + std::string(one);
    }
    const Options::CastStep noCastStep;
    auto castStep = [&]() -> const Options::CastStep& {
        if (options.castSteps.empty()) return noCastStep;
        return options.castSteps[castIndex < options.castSteps.size() ? castIndex : options.castSteps.size() - 1];
    };
    auto castStepText = [&]() {
        const auto& cs = castStep();
        std::string target = cs.self ? "self" : cs.ally ? (cs.ally == 2 ? "corpse" : "ally") : cs.pos ? "pos" : cs.target ? std::to_string(cs.target) : "nearest";
        if (cs.pos && (cs.dx != 0 || cs.dz != 0)) {
            char off[48];
            std::snprintf(off, sizeof(off), "pos%+.1f%+.1f", cs.dx, cs.dz);
            target = off;
        }
        return "step " + std::to_string(castIndex + 1) + "/" + std::to_string(options.castSteps.size()) +
               " skill " + std::to_string(cs.skill) + " target=" + target;
    };
    // CYS-POS: WorldModel::makeUseSkill reads posTarget off the target object (own position when the id is unknown),
    // which is right for an object cast but cannot aim at a chosen spot, and WorldModel is outside this tool. The
    // ground branch therefore fills misc.lua's CGCharUseSkill layout here: targetObjID = the own object (scenecore.lua
    // char_use_skill substitutes exactly that when the id is not in the scene), posTarget = the frozen point, dir =
    // the bearing from the bot to it. Everything else keeps going through WorldModel.
    auto makeCast = [&]() -> std::unique_ptr<pg::Packet> {
        const auto& cs = castStep();
        if (!cs.pos) return world.makeUseSkill(static_cast<int32_t>(cs.skill), static_cast<int32_t>(castTargetId));
        std::unique_ptr<pg::CGCharUseSkill> packet(new pg::CGCharUseSkill);
        packet->m_objID = world.myObjectId();
        packet->skillID = static_cast<int32_t>(cs.skill);
        packet->target = static_cast<int32_t>(castTargetId);
        packet->targetObjID = static_cast<int32_t>(castTargetId);
        packet->posTarget_x = castPosX;
        packet->posTarget_y = castPosZ;
        packet->dir = std::atan2(castPosZ - world.myY(), castPosX - world.myX());
        return std::unique_ptr<pg::Packet>(packet.release());
    };
    int barSlot = -1;
    uint32_t barSkill = 0;
    std::vector<WorldModel::Setting> barBefore;
    std::string skillLog;
    auto skName = [](Sk v) {
        static const char* const names[] = {"sk_ask", "sk_ask_wait", "bar_set", "bar_set_wait", "bar_verify", "bar_verify_wait",
            "bar_restore", "bar_restore_wait", "bar_restore_verify", "bar_restore_verify_wait", "xinfa_study", "xinfa_study_wait",
            "cast_pick", "cast_arrive", "cast", "cast_wait", "recast", "recast_wait", "cast_loop", "sk_done"};
        return names[static_cast<int>(v)];
    };
    auto skAge = [&]() { return static_cast<long long>(std::chrono::duration_cast<std::chrono::milliseconds>(Clock::now() - skAt).count()); };
    auto setSk = [&](Sk next, const std::string& why) { sk = next; skAt = Clock::now(); note(skName(next), why); };
    auto barText = [&](const std::vector<WorldModel::Setting>& bar) {
        std::string text;
        for (size_t t = 2; t <= 21 && t < bar.size(); ++t)
            if (bar[t].type != 0 || bar[t].data != 0)
                text += (text.empty() ? "" : " ") + std::string(t <= 11 ? "F" : "R") + std::to_string(t <= 11 ? t - 1 : t - 11) + "=" + std::to_string(bar[t].type) + "/" + std::to_string(bar[t].data);
        return text;
    };
    auto skNext = [&](Sk after) {
        const int a = static_cast<int>(after);
        if (a < static_cast<int>(Sk::SetBar) && options.hotbar >= 2) return Sk::SetBar;
        if (a < static_cast<int>(Sk::Study) && options.xinfa >= 2) return Sk::Study;
        if (a < static_cast<int>(Sk::CastPick) && options.castSet) return Sk::CastPick;
        return Sk::Done;
    };
    auto maxCooldown = [&]() {
        uint32_t best = 0;
        for (const auto& c : world.cooldowns()) best = (std::max)(best, c.second.total);
        return best;
    };
    auto cooldownText = [&]() {
        std::string text;
        for (const auto& c : world.cooldowns()) text += (text.empty() ? "" : " ") + std::to_string(c.first) + ":" + std::to_string(c.second.total) + "ms";
        return text;
    };
    auto runSkills = [&]() {
        const auto& st = world.stats();
        switch (sk) {
        case Sk::Ask:
            skBase = st.settingLists; skBase2 = st.xinfaLists;
            send(world.makeAskDetailAttrib(), "CGAskDetailAttrib");
            send(world.makeAskSetting(), "CGAskSetting");
            send(world.makeAskDetailXinFaList(), "CGAskDetailXinFaList");
            setSk(Sk::AskWait, "CGAskDetailAttrib + CGAskSetting + CGAskDetailXinFaList");
            break;
        case Sk::AskWait:
            if ((st.settingLists > skBase && st.xinfaLists > skBase2 && skAge() >= 800) || skAge() > 5000) {
                std::string skills, xinfa;
                for (size_t i = 0; i < world.skills().size(); ++i) skills += (i ? "," : "") + std::to_string(world.skills()[i]);
                for (const auto& x : world.xinfas()) xinfa += (xinfa.empty() ? "" : " ") + std::to_string(x.id) + ":" + std::to_string(x.level);
                barBefore = world.settings();
                note("hotbar", "GCRetSetting lists=" + std::to_string(st.settingLists) + " bar=[" + barText(barBefore) + "]");
                note("xinfa", "GCDetailXinFaList lists=" + std::to_string(st.xinfaLists) + " menpai=" + std::to_string(world.myMenpai()) + " xinfa=[" + xinfa + "] skills=[" + skills + "]");
                skillLog += "menpai " + std::to_string(world.myMenpai()) + " skills [" + skills + "] xinfa [" + xinfa + "] bar [" + barText(barBefore) + "]; ";
                setSk(skNext(Sk::AskWait), "listing done");
            }
            break;
        case Sk::SetBar: {
            if (barBefore.size() < 22) { skillLog += "no GCRetSetting: bar set skipped; "; setSk(skNext(Sk::RestoreVerifyWait), "no settings"); break; }
            if (Clock::now() - worldAt < std::chrono::milliseconds(3500)) break; // char_modify_setting ignores the first 3 s in a scene
            barSlot = -1;
            for (int t = 2; t <= 11 && barSlot < 0; ++t) if (barBefore[t].type == 0 && barBefore[t].data == 0) barSlot = t;
            if (barSlot < 0) { skillLog += "main bar full: bar set skipped; "; setSk(skNext(Sk::RestoreVerifyWait), "no empty main slot"); break; }
            barSkill = options.castSet ? options.castSkill : 0;
            skBase = st.settingLists;
            send(world.makeModifySetting(static_cast<uint8_t>(barSlot), 1, barSkill), "CGModifySetting");
            setSk(Sk::SetWait, "CGModifySetting type=" + std::to_string(barSlot) + " (F" + std::to_string(barSlot - 1) + ") skill=" + std::to_string(barSkill));
            break;
        }
        case Sk::SetWait:
            if (skAge() >= 1200) setSk(Sk::Verify, "stored?");
            break;
        case Sk::Verify:
            skBase = st.settingLists;
            send(world.makeAskSetting(), "CGAskSetting");
            setSk(Sk::VerifyWait, "CGAskSetting");
            break;
        case Sk::VerifyWait:
            if (st.settingLists > skBase || skAge() > 4000) {
                const auto& bar = world.settings();
                const bool ok = st.settingLists > skBase && static_cast<int>(bar.size()) > barSlot && bar[barSlot].type == 1 && bar[barSlot].data == barSkill;
                note("hotbar", std::string(ok ? "PASS" : "FAIL") + " stored bar=[" + barText(bar) + "]");
                skillLog += std::string("bar set F") + std::to_string(barSlot - 1) + "=" + std::to_string(barSkill) + (ok ? " stored" : " NOT stored") + "; ";
                setSk(Sk::Restore, "put the slot back");
            }
            break;
        case Sk::Restore:
            send(world.makeModifySetting(static_cast<uint8_t>(barSlot), barBefore[barSlot].type, barBefore[barSlot].data), "CGModifySetting");
            setSk(Sk::RestoreWait, "CGModifySetting type=" + std::to_string(barSlot) + " back to " + std::to_string(barBefore[barSlot].type) + "/" + std::to_string(barBefore[barSlot].data));
            break;
        case Sk::RestoreWait:
            if (skAge() >= 1200) setSk(Sk::RestoreVerify, "restored?");
            break;
        case Sk::RestoreVerify:
            skBase = st.settingLists;
            send(world.makeAskSetting(), "CGAskSetting");
            setSk(Sk::RestoreVerifyWait, "CGAskSetting");
            break;
        case Sk::RestoreVerifyWait:
            if (st.settingLists > skBase || skAge() > 4000) {
                const bool same = barText(world.settings()) == barText(barBefore);
                note("hotbar", std::string(same ? "restored" : "DIFFERENT") + " bar=[" + barText(world.settings()) + "]");
                skillLog += std::string("bar ") + (same ? "restored" : "differs after restore") + "; ";
                setSk(skNext(Sk::RestoreVerifyWait), "bar done");
            }
            break;
        case Sk::Study:
            if (world.xinfas().empty()) { note("xinfa", "no xinfa (menpai " + std::to_string(world.myMenpai()) + "): CGAskStudyXinfa not sent"); skillLog += "xinfa study skipped (no xinfa); "; setSk(skNext(Sk::StudyWait), "no xinfa"); break; }
            skBase = st.studyResults;
            send(world.makeAskStudyXinfa(static_cast<uint16_t>(world.myMenpai()), static_cast<uint16_t>(world.xinfas()[0].id), static_cast<uint16_t>(world.xinfas()[0].level)), "CGAskStudyXinfa");
            setSk(Sk::StudyWait, "CGAskStudyXinfa xinfa=" + std::to_string(world.xinfas()[0].id) + " level=" + std::to_string(world.xinfas()[0].level));
            break;
        case Sk::StudyWait:
            if (st.studyResults > skBase || skAge() > 4000) {
                const auto& r = world.lastStudy();
                note("xinfa", st.studyResults > skBase ? "GCStudyXinfa xinfa=" + std::to_string(r.xinfa) + " level=" + std::to_string(r.level) + " exp=" + std::to_string(r.exp) + " money=" + std::to_string(r.money) : "no GCStudyXinfa within 4 s");
                skillLog += "xinfa study -> level " + std::to_string(r.level) + "; ";
                setSk(skNext(Sk::StudyWait), "study done");
            }
            break;
        case Sk::CastPick: {
            float distance = 0;
            // CYS-SELF: --cast SKILL,-1 | SKILL,self -> the caster itself. GCEnterScene never puts the own object in
            // world.objects(), so this branch must not walk, lock or look the target up; WorldModel::makeUseSkill
            // falls back to the own position for an unknown target id, which is exactly what a self cast needs.
            // CYS-POS: --cast SKILL,pos | SKILL,pos:DX,DZ -> a ground point. Same rule (no walk, no lock, no lookup);
            // the point is frozen here so the first cast and the re-cast use the very same coordinates.
            if (castStep().self || castStep().pos) {
                castTargetId = world.myObjectId();
                if (!castTargetId) {
                    if (skAge() > 8000) { note("cast", "no own object id"); skillLog += "cast: no self target; "; setSk(Sk::Done, "no self target"); }
                    break;
                }
                char selfText[192];
                if (castStep().pos) {
                    castPosX = world.myX() + castStep().dx;
                    castPosZ = world.myY() + castStep().dz;
                    if (castPosX < 0) castPosX = 0; else if (castPosX > 4096) castPosX = 4096;
                    if (castPosZ < 0) castPosZ = 0; else if (castPosZ > 4096) castPosZ = 4096;
                    std::snprintf(selfText, sizeof(selfText), "target=pos %.1f,%.1f (self %.1f,%.1f + %.1f,%.1f) obj=%u hp=%d",
                                  castPosX, castPosZ, world.myX(), world.myY(), castStep().dx, castStep().dz, castTargetId, world.myHp());
                } else {
                    std::snprintf(selfText, sizeof(selfText), "target=self obj=%u pos=%.1f,%.1f hp=%d/%d",
                                  castTargetId, world.myX(), world.myY(), world.myHp(), world.myMaxHp());
                }
                castAt = Clock::now() + std::chrono::milliseconds(400);
                setSk(Sk::CastArrive, selfText);
                break;
            }
            // CYS-ALLY: --cast SKILL,ally | SKILL,corpse -> the nearest OTHER player. Resolved fresh every attempt
            // because the second bot may not have entered the scene yet when the first cast is due. From here on the
            // ordinary object path applies (lock, walk into range, cast), so nothing else has to know about allies.
            if (castStep().ally) {
                float allyDistance = 0;
                castTargetId = world.nearestPlayer(castStep().ally == 2, &allyDistance);
                if (!castTargetId) {
                    if (skAge() > 60000) {   // CYS-ALLY: 60 s — bạn phải kịp đăng nhập, vào cảnh RỒI CHẾT
                        // CYS-ALLY: liệt kê luôn người chơi ĐÃ THẤY kèm hpPercent. Không có dòng này thì
                        // "no dead player" không phân biệt được ba ca rất khác nhau: chưa thấy ai, thấy mà
                        // chưa có GCCharBaseAttrib (hp = -1), hay thấy mà server vẫn báo còn máu.
                        std::string seen;
                        for (const auto& entry : world.objects()) {
                            if (entry.second.kind != WorldModel::Kind::Player || entry.first == world.myObjectId()) continue;
                            char one[64];
                            std::snprintf(one, sizeof(one), "%s%u:hp%d", seen.empty() ? "" : ",", entry.first, entry.second.hpPercent);
                            seen += one;
                        }
                        const std::string why = std::string(castStep().ally == 2 ? "no dead player in the scene"
                                                                                 : "no other live player in the scene") +
                                                " (nguoi choi thay duoc: " + (seen.empty() ? "khong co" : seen) + ")";
                        note("cast", why); skillLog += "cast: " + why + "; "; setSk(Sk::Done, why);
                    }
                    break;  // keep waiting: the partner bot logs in a few seconds later
                }
            } else {
            castTargetId = castStep().target;
            if (!castTargetId) {
                // Hostile first: monsters of camp 9/10 (CampAndStand: players camp 0 fight 9/10; camp 8 NPCs answer
                // OR_WARNING -16), then any live monster the server has not refused yet.
                float best = 0;
                for (int pass = 0; pass < 2 && !castTargetId; ++pass)
                    for (const auto& entry : world.objects()) {
                        const auto& m = entry.second;
                        if (m.kind != WorldModel::Kind::Monster || m.hpPercent == 0 || rejectedTargets.count(entry.first) || (m.x == 0 && m.y == 0)) continue;
                        if (pass == 0 && m.camp != 9 && m.camp != 10) continue;
                        const float d = std::sqrt((m.x - world.myX()) * (m.x - world.myX()) + (m.y - world.myY()) * (m.y - world.myY()));
                        if (!castTargetId || d < best) { castTargetId = entry.first; best = d; }
                    }
            }
            }  // CYS-ALLY: đóng nhánh "không phải ally"
            const auto found = world.objects().find(castTargetId);
            if (!castTargetId || found == world.objects().end()) {
                if (skAge() > 8000) { note("cast", "no target"); skillLog += "cast: no target; "; setSk(Sk::Done, "no target"); }
                break;
            }
            const auto& o = found->second;
            distance = std::sqrt((o.x - world.myX()) * (o.x - world.myX()) + (o.y - world.myY()) * (o.y - world.myY()));
            char text[160];
            std::snprintf(text, sizeof(text), "target=%u name=%s level=%d hp=%d dist=%.1f", castTargetId, o.name.c_str(), o.level, o.hpPercent, distance);
            send(world.makeLockTarget(static_cast<int32_t>(castTargetId)), "CGLockTarget");
            castAt = Clock::now() + std::chrono::milliseconds(400);
            if (distance > 3.5f) {
                const float seconds = walkTo(o.x, o.y, 2.0f);
                castAt = Clock::now() + std::chrono::milliseconds(seconds > 0 ? static_cast<long long>(seconds * 1000) + 900 : 900);
            }
            setSk(Sk::CastArrive, text);
            break;
        }
        case Sk::CastArrive:
            if (Clock::now() >= castAt)
                setSk(Sk::Cast, castStep().pos ? "ground point (no walk, no lock)" : castStep().self ? "self target (no walk, no lock)" : "in range (model)");
            break;
        case Sk::Cast:
            skBase = st.selfSkillSends; skBase2 = st.damageDealt; skBase3 = st.cooldownEntries; skBase4 = st.operateResults;
            skHpBefore = world.myHp();
            if (send(makeCast(), "CGCharUseSkill")) ++casts;
            setSk(Sk::CastWait, "CGCharUseSkill " + castStepText() + " target_obj=" + std::to_string(castTargetId)
                                + (castStep().pos ? " pos=" + std::to_string(static_cast<int>(castPosX)) + "," + std::to_string(static_cast<int>(castPosZ)) : ""));
            break;
        case Sk::CastWait:
            if (skAge() >= 2500) {
                const std::string text = "self_skill_sends+" + std::to_string(st.selfSkillSends - skBase) + " damage_dealt+" + std::to_string(st.damageDealt - skBase2)
                    + " cooldown_entries+" + std::to_string(st.cooldownEntries - skBase3) + " cooldowns=[" + cooldownText() + "] operate_results+" + std::to_string(st.operateResults - skBase4)
                    + " last_operate=" + std::to_string(world.lastOperateResult())
                    // CYS-HP: hp before/after every cast, so "the heal ran" and "the heal did nothing" stay apart
                    // even when the fixture is missing (heal_sum only shows when GCDetailHealsAndDamages arrives).
                    + " hp=" + std::to_string(skHpBefore) + "->" + std::to_string(world.myHp()) + "/" + std::to_string(world.myMaxHp());
                note("cast", castStepText() + " " + text);
                skillLog += "cast " + std::to_string(castStep().skill) + " (" + castStepText() + "): " + text + "; ";
                // CYS-SEQ: every step but the last is a one-shot state setter; only the last gets re-cast / cast-loop.
                if (castIndex + 1 < options.castSteps.size()) {
                    ++castIndex;
                    castTargetId = 0; castRejects = 0;
                    setSk(Sk::CastPick, "cast-seq -> " + castStepText());
                    break;
                }
                setSk(Sk::Recast, "re-cast inside the cooldown");
            }
            break;
        case Sk::Recast:
            // 0.85 CAI_MySelf checks the cooldown before sending; the server answers OR_COOL_DOWNING (-6) otherwise.
            skBase = st.selfSkillSends; skBase4 = st.operateResults;
            if (send(makeCast(), "CGCharUseSkill")) ++casts;
            setSk(Sk::RecastWait, "second CGCharUseSkill right after the first result");
            break;
        case Sk::RecastWait:
            if (skAge() >= 1200) {
                const std::string text = "self_skill_sends+" + std::to_string(st.selfSkillSends - skBase) + " operate_results+" + std::to_string(st.operateResults - skBase4)
                    + " last_operate=" + std::to_string(world.lastOperateResult()) + " max_cooldown=" + std::to_string(maxCooldown()) + "ms";
                note("recast", text);
                skillLog += "recast: " + text + "; ";
                castAt = Clock::now() + std::chrono::milliseconds((std::max)(1300LL, static_cast<long long>(maxCooldown()) + 200));
                // CYS-SELF / CYS-POS: neither a self cast nor a ground cast has a "target dies" exit; the two casts
                // above are the whole measurement.
                if (castStep().self || castStep().pos) {
                    skillLog += std::string(castStep().pos ? "ground" : "self") + " cast done after " + std::to_string(casts) + " casts; ";
                    setSk(Sk::Done, castStep().pos ? "ground cast measured" : "self cast measured");
                    break;
                }
                setSk(Sk::CastLoop, "cast until the target dies");
            }
            break;
        case Sk::CastLoop: {
            // CYS-SELF / CYS-POS: never report a kill for a self or ground cast (the own object is not in
            // world.objects(), so the "target gone" test below would always fire). Sk::Recast already ends those
            // runs before this state.
            if (castStep().self || castStep().pos) { setSk(Sk::Done, "self/ground cast measured"); break; }
            const auto found = world.objects().find(castTargetId);
            if (found == world.objects().end() || found->second.hpPercent == 0) {
                ++castKills;
                note("kill", "cast target " + std::to_string(castTargetId) + " after " + std::to_string(casts) + " casts damage_dealt=" + std::to_string(st.damageDealt));
                skillLog += "kill after " + std::to_string(casts) + " casts; ";
                setSk(Sk::Done, "target died");
                break;
            }
            if (casts >= 40 || skAge() > 60000) { note("cast", "target alive after " + std::to_string(casts) + " casts"); skillLog += "target alive after " + std::to_string(casts) + " casts; "; setSk(Sk::Done, "cast limit"); break; }
            if (Clock::now() >= castAt) {
                if (send(makeCast(), "CGCharUseSkill")) ++casts;
                castAt = Clock::now() + std::chrono::milliseconds((std::max)(1300LL, static_cast<long long>(maxCooldown()) + 200));
            }
            break;
        }
        case Sk::Done:
            skillsDone = true;
            if (options.attack) go(Step::Attack, "skills done"); else if (options.bag) go(Step::Bag, "skills done"); else go(Step::Quit, "skills done");
            break;
        }
    };
    // CYS-QUEST: NPC dialogue / mission / NPC transfer steps (after the inventory steps, before CGAskQuit).
    enum class Q { Ask, AskWait, Walk, Arrive, Talk, Menu, InfoWait, AcceptWait, ContinueWait, SubmitWait, PortalWait, Final, FinalWait };
    Q q = Q::Ask;
    bool questDone = false, questAccepted = false, questSubmitted = false, portalDone = false;
    Clock::time_point qAt = Clock::now(), talkArriveAt{};
    uint32_t qBase = 0, qBase2 = 0, qContinueBase = 0, qNpc = 0, talks = 0;
    int32_t qScript = options.questScript, qMission = -1;
    int64_t expBefore = -1;
    uint16_t sceneBefore = 0;
    std::string questLog;
    bool waitingForTalkConfirmation = false;
    auto qName = [](Q v) {
        static const char* const names[] = {"ask", "ask_wait", "walk", "arrive", "talk", "menu", "info_wait", "accept_wait",
            "continue_wait", "submit_wait", "portal_wait", "final", "final_wait"};
        return names[static_cast<int>(v)];
    };
    auto qAge = [&]() { return static_cast<long long>(std::chrono::duration_cast<std::chrono::milliseconds>(Clock::now() - qAt).count()); };
    auto setQ = [&](Q next, const std::string& why) { q = next; qAt = Clock::now(); note(qName(next), why); };
    auto missionText = [&]() {
        std::string text;
        for (const auto& m : world.missions()) text += (text.empty() ? "" : " ") + std::to_string(m.id) + "/" + std::to_string(m.script) + "/p0=" + std::to_string(m.params[0]);
        return text;
    };
    auto doneText = [&]() { // newbie chain of Dali / Wuliang (edali_newquest_*, 1400..1430) and the chosen mission
        std::string text;
        for (int32_t id = 1400; id <= 1430; ++id) if (world.missionHaveDone(id)) text += (text.empty() ? "" : ",") + std::to_string(id);
        return text;
    };
    auto runQuest = [&]() {
        const auto& st = world.stats();
        switch (q) {
        case Q::Ask:
            qBase = st.missionLists;
            sceneBefore = world.sceneId();
            send(world.makeAskDetailAttrib(), "CGAskDetailAttrib");
            send(world.makeAskMissionList(), "CGAskMissionList");
            setQ(Q::AskWait, "CGAskDetailAttrib + CGAskMissionList");
            break;
        case Q::AskWait:
            if ((st.missionLists > qBase && qAge() >= 600) || qAge() > 4000) {
                expBefore = world.myExp();
                note("quest_state", "level=" + std::to_string(world.myLevel()) + " exp=" + std::to_string(world.myExp()) + " missions=[" + missionText() + "] done_1400_1430=[" + doneText() + "]");
                questLog += "start missions [" + missionText() + "] done [" + doneText() + "] exp " + std::to_string(world.myExp()) + "; ";
                setQ(Q::Walk, "mission list done");
            }
            break;
        case Q::Walk: {
            if (options.talkScene >= 0 && world.sceneId() != static_cast<uint16_t>(options.talkScene)) {
                questLog += "wrong scene " + std::to_string(world.sceneId()) + "; ";
                setQ(Q::Final, "scene " + std::to_string(world.sceneId()) + " is not --talk-scene " + std::to_string(options.talkScene));
                break;
            }
            const float d = distanceTo(options.talkX, options.talkZ);
            if (d <= 3.0f) { setQ(Q::Talk, "already near the NPC"); break; }
            const float seconds = walkTo(options.talkX, options.talkZ, 2.0f);
            if (seconds < 0) { questLog += "walk refused; "; setQ(Q::Final, "walk refused"); break; }
            talkArriveAt = Clock::now() + std::chrono::milliseconds(static_cast<long long>(seconds * 1000) + 1500);
            setQ(Q::Arrive, "walking to the NPC");
            break;
        }
        case Q::Arrive:
            if (Clock::now() >= talkArriveAt) setQ(Q::Talk, "arrived (model)");
            break;
        case Q::Talk: {
            if (talks > 0 && qAge() < 1200) break; // re-talk after an accept: let the server settle
            float d = 0;
            qNpc = world.nearestObjectAt(options.talkX, options.talkZ, 5.0f, &d);
            if (!qNpc) {
                if (qAge() > 3000) { questLog += "no NPC object near --talk; "; setQ(Q::Final, "no NPC object within 5 m of --talk"); }
                break;
            }
            qBase = st.scriptEventLists;
            ++talks;
            char text[112];
            std::snprintf(text, sizeof(text), "npc=%u dist=%.1f scene=%u -> CGCharDefaultEvent (talk %u)", qNpc, d, world.sceneId(), talks);
            send(world.makeCharDefaultEvent(qNpc), "CGCharDefaultEvent");
            setQ(Q::Menu, text);
            break;
        }
        case Q::Menu: {
            if (st.scriptEventLists <= qBase) {
                if (qAge() > 5000) { questLog += "no GCScriptCommand event list; "; setQ(Q::Final, "no NPC menu within 5 s"); }
                break;
            }
            std::string menu;
            for (const auto& e : world.scriptEvents())
                menu += (menu.empty() ? "" : " ") + std::to_string(e.scriptId) + "/" + std::to_string(e.index) + "/t" + std::to_string(e.type);
            note("npc_menu", "texts=" + std::to_string(world.scriptTexts()) + " options=[" + menu + "]");
            questLog += "menu " + std::to_string(talks) + " texts " + std::to_string(world.scriptTexts()) + " options [" + menu + "]; ";
            const WorldModel::ScriptEvent* pick = nullptr;
            if (options.talkOptionSet) {
                const int wanted = waitingForTalkConfirmation ? options.talkConfirm : options.talkOption;
                for (const auto& e : world.scriptEvents()) if (e.index == wanted) { pick = &e; break; }
                if (!pick) { questLog += "option " + std::to_string(wanted) + " not offered; "; setQ(Q::Final, "requested talk option not in the menu"); break; }
                if (options.talkConfirmSet) {
                    qBase = st.scriptEventLists;
                    send(world.makeEventRequest(pick->scriptId, pick->index, static_cast<int32_t>(qNpc)), "CGEventRequest");
                    questLog += "selected " + std::to_string(pick->scriptId) + "/" + std::to_string(pick->index) + "; ";
                    if (!waitingForTalkConfirmation) {
                        waitingForTalkConfirmation = true;
                        setQ(Q::Menu, "waiting for the NPC confirmation menu");
                    } else {
                        // FinalWait requests fresh attributes and allows the skill/xinfa replies to arrive.
                        setQ(Q::Final, "NPC confirmation selected; inspect the resulting character state");
                    }
                    break;
                }
                qBase = st.enters; qBase2 = st.notifyChangeScene;
                send(world.makeEventRequest(pick->scriptId, pick->index, static_cast<int32_t>(qNpc)), "CGEventRequest");
                setQ(Q::PortalWait, "CGEventRequest script=" + std::to_string(pick->scriptId) + " index=" + std::to_string(pick->index) + " (transfer)");
                break;
            }
            if (!options.questMode) { setQ(Q::Final, "dialogue only (--talk)"); break; }
            // Mission options come from the mission scripts' OnEnumerate: AddNumTextWithTarget(script, name, 1 = can accept / 2 = accepted, 1)
            const int wantType = (options.questMode == 2 || questAccepted) ? 2 : 1;
            for (int pass = 0; pass < 2 && !pick; ++pass)
                for (const auto& e : world.scriptEvents()) {
                    if (e.type != 1 && e.type != 2) continue;
                    if (qScript > 0 && e.scriptId != qScript) continue;
                    if (qScript <= 0 && e.scriptId < 100000) continue;
                    if (pass == 0 && e.type != wantType) continue;
                    pick = &e; break;
                }
            if (!pick) { questLog += "no mission option; "; setQ(Q::Final, "no mission option (type 1/2) in the menu"); break; }
            qScript = pick->scriptId;
            qBase = st.missionInfos; qBase2 = st.missionDemands; qContinueBase = st.missionContinues;
            send(world.makeEventRequest(pick->scriptId, pick->index, static_cast<int32_t>(qNpc)), "CGEventRequest");
            setQ(Q::InfoWait, "CGEventRequest script=" + std::to_string(pick->scriptId) + " index=" + std::to_string(pick->index) + " type=" + std::to_string(pick->type));
            break;
        }
        case Q::InfoWait: {
            const auto& dlg = world.lastMissionDialog();
            if (st.missionContinues > qContinueBase) {
                // edali_zhidao_0200 OnDefaultEvent at the accomplish NPC goes straight to OnContinue (GCScriptCommand 4)
                qMission = dlg.mission;
                note("mission_demand", "GCScriptCommand 4 direct (no demand step) script=" + std::to_string(dlg.script) + " mission=" + std::to_string(dlg.mission));
                if (options.questMode == 1) { setQ(Q::Final, "mission ready, --quest accept"); break; }
                qBase = qContinueBase;
                setQ(Q::ContinueWait, "continue info already received");
            } else if (st.missionInfos > qBase) {
                qMission = dlg.mission;
                note("mission_info", "GCScriptCommand 1 npc=" + std::to_string(dlg.npc) + " script=" + std::to_string(dlg.script) + " mission=" + std::to_string(dlg.mission) + " texts=" + std::to_string(dlg.texts) + " bonuses=" + std::to_string(dlg.bonuses));
                questLog += "info script " + std::to_string(dlg.script) + " mission " + std::to_string(dlg.mission) + " texts " + std::to_string(dlg.texts) + "; ";
                if (options.questMode == 2) { questLog += "mission not accepted yet (complete only); "; setQ(Q::Final, "mission offered, --quest complete"); break; }
                qBase = st.missionAdds;
                send(world.makeMissionAccept(static_cast<int32_t>(qNpc), dlg.script), "CGMissionAccept");
                setQ(Q::AcceptWait, "CGMissionAccept npc=" + std::to_string(qNpc) + " script=" + std::to_string(dlg.script));
            } else if (st.missionDemands > qBase2) {
                qMission = dlg.mission;
                note("mission_demand", "GCScriptCommand 3 npc=" + std::to_string(dlg.npc) + " script=" + std::to_string(dlg.script) + " mission=" + std::to_string(dlg.mission) + " done=" + std::to_string(dlg.done) + " texts=" + std::to_string(dlg.texts) + " demands=" + std::to_string(dlg.bonuses));
                questLog += "demand script " + std::to_string(dlg.script) + " mission " + std::to_string(dlg.mission) + " done " + std::to_string(dlg.done) + "; ";
                if (dlg.done != 1 || options.questMode == 1) { setQ(Q::Final, dlg.done == 1 ? "mission done, --quest accept" : "mission not done yet"); break; }
                qBase = st.missionContinues;
                send(world.makeMissionContinue(static_cast<int32_t>(qNpc), dlg.script), "CGMissionContinue");
                setQ(Q::ContinueWait, "CGMissionContinue npc=" + std::to_string(qNpc) + " script=" + std::to_string(dlg.script));
            } else if (qAge() > 5000) { questLog += "no mission dialogue; "; setQ(Q::Final, "no GCScriptCommand 1/3 within 5 s"); }
            break;
        }
        case Q::AcceptWait:
            if (st.missionAdds > qBase && qAge() >= 600) {
                const auto* m = world.findMission(qMission);
                questAccepted = true;
                note("accepted", "GCMissionAdd mission=" + std::to_string(qMission) + (m ? " script=" + std::to_string(m->script) + " p0=" + std::to_string(m->params[0]) + " p1=" + std::to_string(m->params[1]) : std::string(" (not in list)")) + " missions=[" + missionText() + "]");
                questLog += "accepted mission " + std::to_string(qMission) + (m ? " p0 " + std::to_string(m->params[0]) : std::string()) + "; ";
                if (options.questMode == 3) setQ(Q::Talk, "talk again to complete");
                else setQ(Q::Final, "accept done");
            } else if (qAge() > 5000) { questLog += "no GCMissionAdd; "; setQ(Q::Final, "no GCMissionAdd within 5 s"); }
            break;
        case Q::ContinueWait:
            if (st.missionContinues > qBase) {
                const auto& dlg = world.lastMissionDialog();
                std::string bonus;
                for (const auto& b : dlg.bonus) bonus += (bonus.empty() ? "" : " ") + std::to_string(b.first) + ":" + std::to_string(b.second);
                note("mission_continue", "GCScriptCommand 4 script=" + std::to_string(dlg.script) + " mission=" + std::to_string(dlg.mission) + " texts=" + std::to_string(dlg.texts) + " bonus=[" + bonus + "]");
                // Radio rewards (script_base AddRadioItemBonus flag 4): OnSubmit matches selectRadioId against the item id.
                int32_t radio = 0;
                for (const auto& b : dlg.bonus) if (b.first == 4 && b.second > 0) { radio = b.second; break; }
                qBase = st.missionRemoves; qBase2 = st.missionDoneFlags;
                send(world.makeAskMyBagList(), "CGAskMyBagList");
                send(world.makeMissionSubmit(static_cast<int32_t>(qNpc), dlg.script, radio), "CGMissionSubmit");
                setQ(Q::SubmitWait, "CGMissionSubmit npc=" + std::to_string(qNpc) + " script=" + std::to_string(dlg.script) + " radio=" + std::to_string(radio));
            } else if (qAge() > 5000) { questLog += "no GCScriptCommand 4; "; setQ(Q::Final, "no continue info within 5 s"); }
            break;
        case Q::SubmitWait:
            if ((st.missionRemoves > qBase || st.missionDoneFlags > qBase2) && qAge() >= 1500) {
                questSubmitted = world.missionHaveDone(qMission) || world.findMission(qMission) == nullptr;
                note("submitted", "GCMissionRemove=" + std::to_string(st.missionRemoves - qBase) + " GCMissionHaveDoneFlag=" + std::to_string(st.missionDoneFlags - qBase2) + " done(" + std::to_string(qMission) + ")=" + (world.missionHaveDone(qMission) ? "1" : "0") + " next_infos=" + std::to_string(st.missionInfos));
                questLog += "submitted mission " + std::to_string(qMission) + " done flag " + (world.missionHaveDone(qMission) ? "1" : "0") + "; ";
                setQ(Q::Final, "submit done");
            } else if (qAge() > 6000) { questLog += "no GCMissionRemove; "; setQ(Q::Final, "no GCMissionRemove within 6 s"); }
            break;
        case Q::PortalWait:
            if (st.enters > qBase && world.inWorld() && qAge() >= 1500) {
                portalDone = true;
                note("transferred", "GCNotifyChangeScene=" + std::to_string(st.notifyChangeScene - qBase2) + " scene " + std::to_string(sceneBefore) + " -> " + std::to_string(world.sceneId()) + " pos=" + std::to_string(static_cast<int>(world.myX())) + "," + std::to_string(static_cast<int>(world.myY())));
                questLog += "transfer scene " + std::to_string(sceneBefore) + "->" + std::to_string(world.sceneId()) + "; ";
                setQ(Q::Final, "transfer done");
            } else if (qAge() > 25000) { questLog += "no transfer; "; setQ(Q::Final, "no scene transfer within 25 s"); }
            break;
        case Q::Final:
            qBase = st.missionLists;
            send(world.makeAskDetailAttrib(), "CGAskDetailAttrib");
            send(world.makeAskMissionList(), "CGAskMissionList");
            setQ(Q::FinalWait, "final listing");
            break;
        case Q::FinalWait:
            if ((st.missionLists > qBase && qAge() >= 1500) || qAge() > 4000) {
                note("quest_state", "level=" + std::to_string(world.myLevel()) + " exp " + std::to_string(expBefore) + " -> " + std::to_string(world.myExp()) + " missions=[" + missionText() + "] done_1400_1430=[" + doneText() + "]");
                questLog += "end missions [" + missionText() + "] done [" + doneText() + "] exp " + std::to_string(expBefore) + "->" + std::to_string(world.myExp());
                questDone = true;
                go(Step::Quit, "quest done");
            }
            break;
        }
    };
    // CYS-TEAM: form the team, prove it with GCTeamList, then talk on the team channel. The invite is pinned to
    // --team-at-ms after GCEnterScene so the accepting process is already in world when it arrives; the accepting
    // side answers GCTeamAskInvite inside the pump, not here.
    auto tmName = [&](Tm t) {
        switch (t) {
        case Tm::Wait: return "tm_wait"; case Tm::Invite: return "tm_invite"; case Tm::InviteWait: return "tm_invite_wait";
        case Tm::Join: return "tm_join"; case Tm::Info: return "tm_info"; case Tm::InfoWait: return "tm_info_wait";
        case Tm::Option: return "tm_option"; case Tm::OptionWait: return "tm_option_wait";
        case Tm::Appoint: return "tm_appoint"; case Tm::AppointWait: return "tm_appoint_wait";
        case Tm::Kick: return "tm_kick"; case Tm::KickWait: return "tm_kick_wait";
        case Tm::Chat: return "tm_chat"; case Tm::ChatWait: return "tm_chat_wait";
        case Tm::Tell: return "tm_tell"; case Tm::TellWait: return "tm_tell_wait"; default: return "tm_done";
        }
    };
    auto setTm = [&](Tm next, const std::string& why) { tm = next; tmAt = Clock::now(); note(tmName(next), why); };
    auto tmAge = [&]() { return static_cast<long long>(std::chrono::duration_cast<std::chrono::milliseconds>(Clock::now() - tmAt).count()); };
    auto teamText = [&]() {
        std::string out = "id=" + std::to_string(world.teamId()) + " leader=" + std::to_string(world.teamLeader()) +
                          " exp_mode=" + std::to_string(world.teamExpMode()) + " members=[";
        const auto& members = world.teamMembers();
        for (size_t i = 0; i < members.size(); ++i)
            out += (i ? "," : "") + std::to_string(members[i].guid) + ":" + members[i].name +
                   "(obj " + std::to_string(members[i].objId) + " scene " + std::to_string(members[i].sceneId) + " lv " + std::to_string(members[i].level) + ")";
        return out + "]";
    };
    auto otherMember = [&]() -> int32_t {
        for (const auto& m : world.teamMembers()) if (m.guid != world.myGuid()) return m.guid;
        return 0;
    };
    auto runTeam = [&]() {
        const auto& st = world.stats();
        const long long worldAge = static_cast<long long>(std::chrono::duration_cast<std::chrono::milliseconds>(Clock::now() - worldAt).count());
        switch (tm) {
        case Tm::Wait:
            if (worldAge >= static_cast<long long>(options.teamAtMs)) {
                teamChatsSeenBefore = st.teamChats; tellsSeenBefore = st.tellChats;
                if (!options.teamInvite.empty() || !options.teamApply.empty()) setTm(Tm::Invite, "scheduled at " + std::to_string(options.teamAtMs) + " ms");
                else if (options.teamAccept) setTm(Tm::Join, "waiting for GCTeamAskInvite");
                else setTm(Tm::Info, "no invite / accept requested");
            }
            break;
        case Tm::Invite:
            if (!options.teamInvite.empty()) {
                if (send(world.makeTeamInvite(options.teamInvite), "CGTeamInvite")) {
                    ++invitesSent; note("team_invite", "CGTeamInvite dest=" + options.teamInvite);
                    setTm(Tm::InviteWait, "invite sent");
                } else setTm(Tm::Done, "invite refused by the worker");
            } else {
                if (send(world.makeTeamApply(options.teamApply), "CGTeamApply")) {
                    ++invitesSent; note("team_apply", "CGTeamApply dest=" + options.teamApply);
                    setTm(Tm::InviteWait, "apply sent");
                } else setTm(Tm::Done, "apply refused by the worker");
            }
            break;
        case Tm::InviteWait:
            // GCTeamResult(type 0) arrives first but carries no level/leader; wait for the GCTeamList roster.
            if (world.inTeam() && st.teamLists > 0 && !world.teamMembers().empty()) {
                note("team_formed", teamText());
                teamLog += "formed " + teamText() + "; ";
                setTm(Tm::Info, "GCTeamList received");
            } else if (st.teamErrors > 0) {
                note("team_error", "GCTeamError code=" + std::to_string(world.lastTeamError()));
                teamLog += "GCTeamError " + std::to_string(world.lastTeamError()) + "; ";
                setTm(Tm::Done, "server refused the invite");
            } else if (tmAge() >= static_cast<long long>(options.teamWaitMs)) {
                note("team_invite", "no GCTeamList / GCTeamError within " + std::to_string(options.teamWaitMs) + " ms");
                teamLog += "invite timed out; ";
                setTm(Tm::Done, "invite timeout");
            }
            break;
        case Tm::Join:
            if (world.inTeam() && st.teamLists > 0 && !world.teamMembers().empty()) {
                note("team_joined", teamText());
                teamLog += "joined " + teamText() + "; ";
                setTm(Tm::Info, "GCTeamList received");
            } else if (tmAge() >= static_cast<long long>(options.teamWaitMs)) {
                note("team_join", "no invite arrived within " + std::to_string(options.teamWaitMs) + " ms");
                teamLog += "no invite arrived; ";
                setTm(Tm::Done, "join timeout");
            }
            break;
        case Tm::Info:
            if (!options.teamInfo) { setTm(Tm::Option, "no --team-info"); break; }
            if (send(world.makeAskTeamInfo(), "CGAskTeamInfo")) ++teamInfoAsks;
            for (const auto& m : world.teamMembers())
                if (world.myGuid() && m.guid != world.myGuid() && send(world.makeAskTeamMemberInfo(m.guid), "CGAskTeamMemberInfo")) ++memberInfoAsks;
            setTm(Tm::InfoWait, "CGAskTeamInfo + " + std::to_string(memberInfoAsks) + " x CGAskTeamMemberInfo");
            break;
        case Tm::InfoWait:
            if (tmAge() >= 2000) {
                note("team_info", "team_lists=" + std::to_string(st.teamLists) + " member_infos=" + std::to_string(st.teamMemberInfos) + " " + teamText());
                teamLog += "info lists=" + std::to_string(st.teamLists) + " member_infos=" + std::to_string(st.teamMemberInfos) + "; ";
                setTm(Tm::Option, "info done");
            }
            break;
        case Tm::Option:
            if (options.teamExpMode < 0 || !world.inTeam()) { setTm(Tm::Appoint, "no --team-exp-mode"); break; }
            send(world.makeTeamChangeOption(static_cast<uint32_t>(options.teamExpMode)), "CGTeamChangeOption");
            setTm(Tm::OptionWait, "exp_mode -> " + std::to_string(options.teamExpMode));
            break;
        case Tm::OptionWait:
            if (tmAge() >= 1500) {
                note("team_option", "option_changes=" + std::to_string(st.teamOptionChanges) + " exp_mode=" + std::to_string(world.teamExpMode()));
                teamLog += "exp_mode=" + std::to_string(world.teamExpMode()) + "; ";
                setTm(Tm::Appoint, "option done");
            }
            break;
        case Tm::Appoint: {
            if (!options.teamAppoint || !world.inTeam()) { setTm(Tm::Kick, "no --team-appoint"); break; }
            const int32_t other = otherMember();
            if (!other) { teamLog += "appoint skipped (no other member); "; setTm(Tm::Kick, "no other member"); break; }
            if (send(world.makeTeamAppoint(other), "CGTeamAppoint")) note("team_appoint", "CGTeamAppoint dest=" + std::to_string(other));
            setTm(Tm::AppointWait, "appoint sent");
            break;
        }
        case Tm::AppointWait:
            if (world.lastTeamResult().returnType == 5 || tmAge() >= 4000) {
                note("team_appoint", "last_result=" + std::to_string(world.lastTeamResult().returnType) + " " + teamText());
                teamLog += "appoint -> leader=" + std::to_string(world.teamLeader()) + "; ";
                setTm(Tm::Kick, "appoint done");
            }
            break;
        case Tm::Kick: {
            if (!options.teamKick || !world.inTeam()) { setTm(Tm::Chat, "no --team-kick"); break; }
            const int32_t other = otherMember();
            if (!other) { teamLog += "kick skipped (no other member); "; setTm(Tm::Chat, "no other member"); break; }
            if (send(world.makeTeamKick(other), "CGTeamKick")) note("team_kick", "CGTeamKick dest=" + std::to_string(other));
            setTm(Tm::KickWait, "kick sent");
            break;
        }
        case Tm::KickWait:
            if (world.lastTeamResult().returnType == 4 || st.teamErrors > 0 || tmAge() >= 4000) {
                note("team_kick", "last_result=" + std::to_string(world.lastTeamResult().returnType) +
                     " team_errors=" + std::to_string(st.teamErrors) + " " + teamText());
                teamLog += "kick last_result=" + std::to_string(world.lastTeamResult().returnType) + "; ";
                setTm(Tm::Chat, "kick done");
            }
            break;
        case Tm::Chat:
            if (options.teamChatText.empty()) { setTm(Tm::Tell, "no --team-chat"); break; }
            if (!world.inTeam()) { teamLog += "team chat skipped (not in a team); "; setTm(Tm::Tell, "not in a team"); break; }
            if (send(world.makeTeamChat(options.teamChatText), "CGChat type=1")) {
                ++teamChatsSent; note("team_chat", "CGChat type=1 teamID=" + std::to_string(world.teamId()) + " bytes=" + std::to_string(options.teamChatText.size()));
            }
            setTm(Tm::ChatWait, "team chat sent");
            break;
        case Tm::ChatWait:
            if (st.teamChats > teamChatsSeenBefore || tmAge() >= 4000) {
                note("team_chat", "GCChat type=1 seen=" + std::to_string(st.teamChats) + " (before " + std::to_string(teamChatsSeenBefore) + ") last=[" + world.lastChat().source + "] " + world.lastChat().text);
                teamLog += "team_chat rx=" + std::to_string(st.teamChats - teamChatsSeenBefore) + "; ";
                setTm(Tm::Tell, "team chat done");
            }
            break;
        case Tm::Tell:
            if (options.tellName.empty()) { setTm(Tm::Done, "no --tell"); break; }
            if (send(world.makeTellChat(options.tellName, options.tellText), "CGChat type=3")) {
                ++tellsSent; note("tell_chat", "CGChat type=3 target=" + options.tellName);
            }
            setTm(Tm::TellWait, "tell sent");
            break;
        case Tm::TellWait:
            if (st.tellChats > tellsSeenBefore || st.missionTips > 0 || tmAge() >= 4000) {
                note("tell_chat", "GCChat type=3/25 seen=" + std::to_string(st.tellChats) + " (before " + std::to_string(tellsSeenBefore) + ")");
                teamLog += "tell rx=" + std::to_string(st.tellChats - tellsSeenBefore) + "; ";
                setTm(Tm::Done, "tell done");
            }
            break;
        case Tm::Done:
            teamDone = true;
            if (options.skillMode()) go(Step::Skills, "team done");
            else if (options.attack) go(Step::Attack, "team done");
            else if (options.bag) go(Step::Bag, "team done");
            else go(Step::Quit, "team done");
            break;
        }
    };
    // CYS-PET 17/09/2026: one linear pet script per session.
    //   Ask      CGAskDetailAttrib on my own object -> scenecore.lua ask_detail_attrib sends one
    //            GCDetailAttrib_Pet (512) per pet in the pet bag (human:send_pets_detail), so the bag becomes
    //            visible without any new server call.
    //   Capture  the nearest WorldModel::Kind::Pet object that is NOT my own summoned pet: lock it, walk into
    //            range, cast skill template 1 捕兽. skill_10.lua adds me as a capturer at the start of the cast
    //            and only decides on effect_on_unit_once, i.e. after the 15 s 聚气时间, with GCManipulatePetRet
    //            ret 1 (CAPTURESUCC) or 0 (CAPTUREFALID).
    //   Summon   CGManipulatePet type 0 -> human:test_call_up_pet + skill CALL_UP_PET -> skill_11 -> call_up_pet;
    //            the answer is GCManipulatePetRet ret 3 (CALLUPSUCC) / 2 (CALLUPFALID, with a GCOperateResult).
    //   Recall   CGManipulatePet type 1 -> human:recall_pet, ret 7 (RECALLSUCC) / 6 (RECALLFALID).
    enum class Pt { Ask, AskWait, CapturePick, CaptureArrive, Capture, CaptureWait, Ask2Summon, Ask2Wait,
                    Summon, SummonWait, Fight, Recall, RecallWait, Done };
    Pt pt = Pt::Ask;
    bool petDone = false;
    // CYS-PETSKILL 19/09 (pet-skill-12): skillIds are the 13 CY skill cells in wire order (2 activate + 11 positive).
    // The server sets all 13 FLAGS on every refresh even for a pet with no skill, so only the ids say anything;
    // skillCount counts the cells with an id >= 0. This is the server-side half of the "12 pet skill buttons" work:
    // the client can only show what the server sends, and the 0.85 pool used to keep just the first six.
    struct PetRow { uint32_t high = 0, low = 0, dataIndex = 0, level = 0, hp = 0, hpMax = 0, objId = 0; std::string nameGbkHex;
                    int32_t skillIds[13] = {-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1}; int skillCount = 0; };
    std::vector<PetRow> petBag;
    uint32_t petDetails = 0, petRets = 0, petNewPets = 0, capturesSent = 0, summonsSent = 0, recallsSent = 0;
    int32_t lastPetRet = -99;
    uint32_t lastPetRetHigh = 0, lastPetRetLow = 0, lastPetRetFighting = 0;
    uint32_t captureTarget = 0, capturedHigh = 0, capturedLow = 0, summonHigh = 0, summonLow = 0;
    size_t petBagBefore = 0;
    // CYS-PET: the guids already in the bag before the capture. Measured 17/09: GCManipulatePetRet for a
    // capture arrived 22 s AFTER the cast (聚气 15 s plus the server-side approach/cast machinery), so a
    // timeout is not proof of failure - the new guid appearing in the bag is. Keep both.
    std::set<std::pair<uint32_t, uint32_t>> petBagStart;
    Clock::time_point ptAt = Clock::now(), petArriveAt = Clock::now();
    std::string petLog;
    auto ptName = [&](Pt v) {
        static const char* const names[] = {"ask", "ask_wait", "capture_pick", "capture_arrive", "capture", "capture_wait",
                                            "ask2", "ask2_wait", "summon", "summon_wait", "fight", "recall", "recall_wait", "done"};
        return names[static_cast<int>(v)];
    };
    auto ptAge = [&]() { return static_cast<long long>(std::chrono::duration_cast<std::chrono::milliseconds>(Clock::now() - ptAt).count()); };
    auto setPt = [&](Pt next, const std::string& why) {
        pt = next; ptAt = Clock::now();
        const std::string phase = std::string("pet_") + ptName(next);
        note(phase.c_str(), why);
    };
    auto petBagText = [&]() {
        std::string text;
        for (const auto& p : petBag) {
            char one[160];
            std::snprintf(one, sizeof(one), "%s%u:%u/data%u/lv%u/hp%u-%u/sk%d", text.empty() ? "" : " ",
                          p.high, p.low, p.dataIndex, p.level, p.hp, p.hpMax, p.skillCount);   // CYS-PETSKILL
            text += one;
        }
        return text;
    };
    // CGManipulatePet is built here for the same reason as CGUseItem: WorldModel is outside this tool's write
    // scope. misc.lua CGManipulatePet.bis reads m_objID, PetGUID{high,low}, type - nothing else.
    auto makeManipulatePet = [&](uint32_t high, uint32_t low, int32_t type) -> std::unique_ptr<pg::Packet> {
        std::unique_ptr<pg::CGManipulatePet> packet(new pg::CGManipulatePet);
        packet->m_objID = world.myObjectId();
        packet->pet_guid.m_uHighSection = high;
        packet->pet_guid.m_uLowSection = low;
        packet->type = type;
        return std::unique_ptr<pg::Packet>(packet.release());
    };
    // A wild pet is an object the world model marked Kind::Pet (GCNewPet / GCNewPet_Move) that is not the pet I
    // summoned myself. petdropper.lua gives it a capture protection guid, so a pet another player dropped may
    // still refuse; that refusal is a GCManipulatePetRet, which is the measurement.
    auto nearestWildPet = [&](uint32_t except, float* distance) {
        uint32_t best = 0; float bestD = 0;
        for (const auto& entry : world.objects()) {
            if (entry.second.kind != WorldModel::Kind::Pet || entry.first == except) continue;
            if (entry.second.x == 0 && entry.second.y == 0) continue;
            const float dx = entry.second.x - world.myX(), dy = entry.second.y - world.myY();
            const float d = std::sqrt(dx * dx + dy * dy);
            if (!best || d < bestD) { best = entry.first; bestD = d; }
        }
        if (distance) *distance = bestD;
        return best;
    };
    auto runPet = [&]() {
        const auto& st = world.stats();
        switch (pt) {
        case Pt::Ask:
            petBag.clear(); petDetails = 0;
            send(world.makeAskDetailAttrib(), "CGAskDetailAttrib");
            setPt(Pt::AskWait, "CGAskDetailAttrib -> GCDetailAttrib_Pet per pet in the bag");
            break;
        case Pt::AskWait:
            if (ptAge() >= 3000) {
                petBagBefore = petBag.size();
                petBagStart.clear();
                for (const auto& p : petBag) petBagStart.insert(std::make_pair(p.high, p.low));
                note("pet_bag", "pets=" + std::to_string(petBag.size()) + " details=" + std::to_string(petDetails) + " [" + petBagText() + "]");
                petLog += "bag start pets=" + std::to_string(petBag.size()) + " [" + petBagText() + "]; ";
                setPt(options.petCapture ? Pt::CapturePick : Pt::Summon, "bag listed");
            }
            break;
        case Pt::CapturePick: {
            float d = 0;
            captureTarget = nearestWildPet(0, &d);
            if (!captureTarget) {
                if (ptAge() > 8000) {
                    // The only server-side source of a wild pet is petdropper.lua (a monster of g_PetDropList dying)
                    // or a growpoint script calling CreatePetOnScene. Say so instead of "capture failed".
                    const std::string why = "no wild pet object in scene " + std::to_string(world.sceneId()) +
                                            " (objects=" + std::to_string(world.objects().size()) + ")";
                    note("pet_capture", why); petLog += "capture: " + why + "; ";
                    setPt(Pt::Summon, why);
                }
                break;
            }
            const auto found = world.objects().find(captureTarget);
            const auto& o = found->second;
            char text[160];
            std::snprintf(text, sizeof(text), "pet_obj=%u name=%s level=%d hp=%d dist=%.1f", captureTarget, o.name.c_str(), o.level, o.hpPercent, d);
            send(world.makeLockTarget(static_cast<int32_t>(captureTarget)), "CGLockTarget");
            petArriveAt = Clock::now() + std::chrono::milliseconds(400);
            if (d > 3.5f) {
                const float seconds = walkTo(o.x, o.y, 2.0f);
                petArriveAt = Clock::now() + std::chrono::milliseconds(seconds > 0 ? static_cast<long long>(seconds * 1000) + 900 : 900);
            }
            setPt(Pt::CaptureArrive, text);
            break;
        }
        case Pt::CaptureArrive:
            if (Clock::now() >= petArriveAt) setPt(Pt::Capture, "in range (model)");
            break;
        case Pt::Capture:
            petRets = 0;
            if (send(world.makeUseSkill(1, static_cast<int32_t>(captureTarget)), "CGCharUseSkill skill=1 捕兽")) ++capturesSent;
            setPt(Pt::CaptureWait, "capture cast at pet_obj=" + std::to_string(captureTarget) + " (聚气 15 s)");
            break;
        case Pt::CaptureWait:
            // 聚气 15 s, but the measured answer took 22 s from the cast, so give it 45 s. A new guid in the
            // bag also ends the wait: that is the capture landing even if the ret is still on the way.
            if (petRets > 0 || ptAge() >= 45000) {
                const std::string text = "captures=" + std::to_string(capturesSent) + " manipulate_rets=" + std::to_string(petRets) +
                                         " last_ret=" + std::to_string(lastPetRet) + " last_operate=" + std::to_string(world.lastOperateResult()) +
                                         " skill_sends=" + std::to_string(st.selfSkillSends);
                note("pet_capture", text); petLog += "capture: " + text + "; ";
                if (lastPetRet == 1) { capturedHigh = lastPetRetHigh; capturedLow = lastPetRetLow; }
                setPt(Pt::Ask2Summon, "capture answered");
            }
            break;
        case Pt::Summon: {
            if (options.pet < 2) { setPt(Pt::Done, "--pet 1: listing only"); break; }
            // human:test_call_up_pet -> can_use_skill_now(): summoning while the capture skill is still
            // running answers OR_BUSY (-17). Measured 17/09. Let the caster settle first.
            if (options.petCapture && ptAge() < 4000) break;
            // Prefer the pet just captured, else the first pet in the bag with hp > 0.
            const PetRow* pick = nullptr;
            for (const auto& p : petBag) {
                if (capturedHigh || capturedLow) { if (p.high == capturedHigh && p.low == capturedLow) { pick = &p; break; } }
                else if (p.hp > 0 && !pick) pick = &p;
            }
            if (!pick && !petBag.empty()) pick = &petBag.front();
            if (!pick) {
                const std::string why = "pet bag empty: nothing to summon";
                note("pet_summon", why); petLog += "summon: " + why + "; ";
                setPt(Pt::Done, why);
                break;
            }
            summonHigh = pick->high; summonLow = pick->low;
            petRets = 0; petNewPets = 0;
            if (send(makeManipulatePet(summonHigh, summonLow, 0), "CGManipulatePet type=0 CREATEPET")) ++summonsSent;
            setPt(Pt::SummonWait, "CGManipulatePet type=0 guid=" + std::to_string(summonHigh) + ":" + std::to_string(summonLow) +
                                  " data=" + std::to_string(pick->dataIndex));
            break;
        }
        case Pt::SummonWait:
            if (petRets > 0 || ptAge() >= 6000) {
                const std::string text = "summons=" + std::to_string(summonsSent) + " manipulate_rets=" + std::to_string(petRets) +
                                         " last_ret=" + std::to_string(lastPetRet) + " is_fighting=" + std::to_string(lastPetRetFighting) +
                                         " new_pet_objects=" + std::to_string(petNewPets) +
                                         " last_operate=" + std::to_string(world.lastOperateResult());
                note("pet_summon", text); petLog += "summon: " + text + "; ";
                // OR_BUSY (-17) is "try again in a moment", not "cannot": retry once before giving up.
                if (lastPetRet == 2 && world.lastOperateResult() == -17 && summonsSent < 2) {
                    setPt(Pt::Summon, "CALLUPFALID with OR_BUSY -> retry once");
                    break;
                }
                setPt(lastPetRet == 3 ? Pt::Fight : Pt::Done, lastPetRet == 3 ? "CALLUPSUCC" : "summon did not succeed");
            }
            break;
        case Pt::Fight:
            // Keep the pet out long enough that the scene really carries it (GCNewPet_Move, pet ai ticks). The
            // caller adds --attack / --hunt when the pet should also be seen fighting.
            if (ptAge() >= static_cast<long long>(options.petFightMs)) {
                uint32_t petObjects = 0;
                for (const auto& e : world.objects()) if (e.second.kind == WorldModel::Kind::Pet) ++petObjects;
                const std::string text = "pet_objects_in_scene=" + std::to_string(petObjects) +
                                         " damage_dealt=" + std::to_string(st.damageDealt) + " kills=" + std::to_string(kills);
                note("pet_fight", text); petLog += "fight: " + text + "; ";
                setPt(Pt::Recall, "fight window over");
            }
            break;
        case Pt::Recall:
            petRets = 0;
            if (send(makeManipulatePet(summonHigh, summonLow, 1), "CGManipulatePet type=1 DELETEPET")) ++recallsSent;
            setPt(Pt::RecallWait, "CGManipulatePet type=1 guid=" + std::to_string(summonHigh) + ":" + std::to_string(summonLow));
            break;
        case Pt::RecallWait:
            if (petRets > 0 || ptAge() >= 5000) {
                uint32_t petObjects = 0;
                for (const auto& e : world.objects()) if (e.second.kind == WorldModel::Kind::Pet) ++petObjects;
                const std::string text = "recalls=" + std::to_string(recallsSent) + " manipulate_rets=" + std::to_string(petRets) +
                                         " last_ret=" + std::to_string(lastPetRet) + " pet_objects_in_scene=" + std::to_string(petObjects);
                note("pet_recall", text); petLog += "recall: " + text + "; ";
                setPt(Pt::Done, "recall answered");
            }
            break;
        case Pt::Ask2Summon:
            // Re-list the bag after a capture so the new pet's guid is known before the summon.
            petBag.clear(); petDetails = 0;
            send(world.makeAskDetailAttrib(), "CGAskDetailAttrib");
            setPt(Pt::Ask2Wait, "re-list the pet bag after the capture");
            break;
        case Pt::Ask2Wait:
            // Wait for the new guid, not just for a fixed delay: the pet only lands in the bag when
            // human:capture_pet -> add_pet runs, which is the end of the 聚气. Also let the caster finish
            // channelling - summoning while the capture skill is still running answers OR_BUSY (-17).
            {
                const PetRow* fresh = nullptr;
                for (const auto& p : petBag)
                    if (!petBagStart.count(std::make_pair(p.high, p.low))) { fresh = &p; break; }
                if (fresh) { capturedHigh = fresh->high; capturedLow = fresh->low; }
                if (fresh || ptAge() >= 20000) {
                    if (!fresh && ptAge() >= 10000 && ptAge() < 19000) { send(world.makeAskDetailAttrib(), "CGAskDetailAttrib"); break; }
                    const std::string text = "after capture pets=" + std::to_string(petBag.size()) +
                                             " (before " + std::to_string(petBagBefore) + ")" +
                                             (fresh ? " new=" + std::to_string(fresh->high) + ":" + std::to_string(fresh->low) +
                                                      " data=" + std::to_string(fresh->dataIndex) : " new=none");
                    note("pet_bag", text);
                    petLog += "bag " + text + "; ";
                    setPt(Pt::Summon, "bag re-listed");
                }
            }
            break;
        case Pt::Done:
            petDone = true;
            if (options.attack) go(Step::Attack, "pet done");
            else if (options.bag) go(Step::Bag, "pet done");
            else go(Step::Quit, "pet done");
            break;
        }
    };
    // CYS-ATTRIB 17/09/2026: the character-power loop. Ask -> act -> re-ask, so every claim is a number pair.
    //   Ask      CGAskDetailAttrib on my own object; the answer GCDetailAttrib (1772) already carries
    //            point_remain, str/spr/con/int/dex and the eleven 修炼 fields.
    //   Act      one of: CGReqManualAttr (598, --attr-point), CGCharAllTitles (1230, --titles),
    //            CGCharUpdateCurTitle (1192, --set-title), CGKfsOperate (908, --kfs). All of them are sent in
    //            the same session so one run can cover several systems.
    //   Verify   CGAskDetailAttrib again. attrsPowerBefore / attrsPowerAfter end up in result.json.
    enum class At { Ask, AskWait, Act, ActWait, Verify, VerifyWait, Done };
    At at = At::Ask;
    bool attribDone = false;
    Clock::time_point atAt = Clock::now();
    SelfAttrs attrsPowerBefore, attrsPowerAfter;
    uint32_t manualAttrResults = 0, titleLists = 0, kfsRefreshes = 0;
    int64_t lastManualAttrResult = -99;
    uint32_t titleIdCount = 0, titleStrCount = 0;
    std::string titleListText, attribLog;
    // CYS-ATTRIB: 修炼. GCDetailXiulianList (1014) is a fixed 48-byte packet: 11 levels + 11 upper limits +
    // unknow_2 (the server writes 54). The server pushes it from human:send_xiulian_list, which XiuLianLevelUp
    // calls, so a level-up is visible without any extra request. 11 is the packet's hard cap - CY has 15 books.
    uint32_t xiulianLists = 0;
    std::string xiulianText;
    auto atName = [&](At v) {
        static const char* const names[] = {"ask", "ask_wait", "act", "act_wait", "verify", "verify_wait", "done"};
        return names[static_cast<int>(v)];
    };
    auto atAge = [&]() { return static_cast<long long>(std::chrono::duration_cast<std::chrono::milliseconds>(Clock::now() - atAt).count()); };
    auto setAt = [&](At next, const std::string& why) {
        note("attrib_state", std::string(atName(at)) + " -> " + atName(next) + " (" + why + ")");
        at = next; atAt = Clock::now();
    };
    auto attribPhase = [&]() {
        switch (at) {
        case At::Ask:
            send(world.makeAskDetailAttrib(), "CGAskDetailAttrib");
            setAt(At::AskWait, "CGAskDetailAttrib -> GCDetailAttrib (own power fields)");
            break;
        case At::AskWait:
            if (atAge() >= 2500) {
                attrsPowerBefore = attrs;
                note("attrib_before", attrs.valid ? attrs.powerText() : "no GCDetailAttrib within 2.5 s");
                attribLog += "before " + (attrs.valid ? attrs.powerText() : std::string("none")) + "; ";
                setAt(At::Act, "snapshot taken");
            }
            break;
        case At::Act: {
            if (options.attrPointSet) {
                std::unique_ptr<pg::CGReqManualAttr> pkt(new pg::CGReqManualAttr);
                pkt->str = options.attrStr; pkt->spr = options.attrSpr; pkt->con = options.attrCon;
                pkt->int_ = options.attrInt; pkt->dex = options.attrDex;
                const std::string desc = "CGReqManualAttr str=" + std::to_string(options.attrStr) + " spr=" + std::to_string(options.attrSpr) +
                                         " con=" + std::to_string(options.attrCon) + " int=" + std::to_string(options.attrInt) +
                                         " dex=" + std::to_string(options.attrDex);
                if (send(std::unique_ptr<pg::Packet>(pkt.release()), "CGReqManualAttr")) note("attr_point", desc);
                else note("attr_point", "refused: " + desc);
                attribLog += desc + "; ";
            }
            if (options.titles) {
                std::unique_ptr<pg::CGCharAllTitles> pkt(new pg::CGCharAllTitles);
                pkt->m_objID = world.myObjectId();
                if (send(std::unique_ptr<pg::Packet>(pkt.release()), "CGCharAllTitles")) note("titles", "CGCharAllTitles obj=" + std::to_string(world.myObjectId()));
            }
            if (options.setTitle >= 0) {
                std::unique_ptr<pg::CGCharUpdateCurTitle> pkt(new pg::CGCharUpdateCurTitle);
                pkt->id = static_cast<uint32_t>(options.setTitle); pkt->id_title_id = 0;
                if (send(std::unique_ptr<pg::Packet>(pkt.release()), "CGCharUpdateCurTitle")) note("titles", "CGCharUpdateCurTitle id=" + std::to_string(options.setTitle));
                attribLog += "set_title " + std::to_string(options.setTitle) + "; ";
            }
            if (options.setIdTitle >= 0) {
                std::unique_ptr<pg::CGCharUpdateCurTitle> pkt(new pg::CGCharUpdateCurTitle);
                pkt->id = 0; pkt->id_title_id = static_cast<uint16_t>(options.setIdTitle);
                if (send(std::unique_ptr<pg::Packet>(pkt.release()), "CGCharUpdateCurTitle")) note("titles", "CGCharUpdateCurTitle id=0 id_title_id=" + std::to_string(options.setIdTitle));
                attribLog += "set_id_title " + std::to_string(options.setIdTitle) + "; ";
            }
            if (options.kfsSet) {
                std::unique_ptr<pg::CGKfsOperate> pkt(new pg::CGKfsOperate);
                pkt->operate = options.kfsOp; pkt->arg_1 = static_cast<uint8_t>(options.kfsA1);
                pkt->arg_2 = static_cast<uint8_t>(options.kfsA2); pkt->arg_3 = static_cast<int8_t>(options.kfsA3);
                const std::string desc = "CGKfsOperate op=" + std::to_string(options.kfsOp) + " args=" + std::to_string(options.kfsA1) +
                                         "," + std::to_string(options.kfsA2) + "," + std::to_string(options.kfsA3);
                if (send(std::unique_ptr<pg::Packet>(pkt.release()), "CGKfsOperate")) note("kfs", desc); else note("kfs", "refused: " + desc);
                attribLog += desc + "; ";
            }
            setAt(At::ActWait, "packets sent");
            break;
        }
        case At::ActWait:
            if (atAge() >= 4000) {
                if (options.attrPointSet)
                    note("attr_point", manualAttrResults ? "GCManualAttrResult result=" + std::to_string(lastManualAttrResult)
                                                         : "no GCManualAttrResult within 4 s");
                if (options.titles)
                    note("titles", titleLists ? "GCCharAllTitles ids=" + std::to_string(titleIdCount) + " strs=" + std::to_string(titleStrCount) + " [" + titleListText + "]"
                                              : "no GCCharAllTitles within 4 s");
                setAt(At::Verify, "answers collected");
            }
            break;
        case At::Verify:
            send(world.makeAskDetailAttrib(), "CGAskDetailAttrib");
            setAt(At::VerifyWait, "CGAskDetailAttrib again");
            break;
        case At::VerifyWait:
            if (atAge() >= 2500) {
                attrsPowerAfter = attrs;
                note("attrib_after", attrs.valid ? attrs.powerText() : "no GCDetailAttrib within 2.5 s");
                attribLog += "after " + (attrs.valid ? attrs.powerText() : std::string("none")) + "; ";
                setAt(At::Done, "snapshot taken");
            }
            break;
        case At::Done:
            attribDone = true;
            if (options.skillMode() && !skillsDone) go(Step::Skills, "attrib done");
            else if (options.attack) go(Step::Attack, "attrib done");
            else if (options.bag) go(Step::Bag, "attrib done");
            else go(Step::Quit, "attrib done");
            break;
        }
    };
    if (code == 0) {
        const auto pvpSessionAt = Clock::now();
        auto gameDeadline = pvpSessionAt + std::chrono::milliseconds(options.dwellMs + 120000);
        while (!haveTerminal && Clock::now() < gameDeadline) {
            game.pump([&](GameEvent&& event) {
                gameCounters = event.counters;
                const auto* info = event.packet ? pg::findPacket(pg::Proto::Game, event.packetId) : nullptr;
                log << elapsed() << "\tgame\t" << GameEventName(event.type) << '\t' << event.generation << '\t'
                    << event.packetId << '\t' << (info ? info->name : "") << '\t' << event.bodySize << '\t'
                    << GamePhaseName(event.phase) << '\n';
                switch (event.type) {
                case GameEventType::Connected:
                    world.onConnected(event.generation); generation = event.generation;
                    break;
                case GameEventType::Packet: {
                    world.apply(*event.packet);
                    if(options.pvpPeer && event.packetId==pg::GCChallenge::PACKET_ID){
                        const auto& p=static_cast<const pg::GCChallenge&>(*event.packet);
                        if(p.type==1 && !p.member_list.empty()){
                            static unsigned invites=0;++invites;
                            std::unique_ptr<pg::CGChallenge> reply(new pg::CGChallenge);reply->m_objID=p.m_objID;reply->type=invites==1?2:1;
                            note("pvp_invite","members="+std::to_string(p.member_list.size())+" response="+std::to_string(reply->type));
                            send(std::move(reply),"CGChallenge response");
                        }
                    }
                    if (event.packetId == pg::GCConnect::PACKET_ID) game.send(world.makeEnterScene());
                    if (event.packetId == pg::GCEnterScene::PACKET_ID) {
                        inWorld = true; worldAt = Clock::now();
                        startX = world.myX(); startY = world.myY();
                        setupSent = false;
                        char text[96];
                        std::snprintf(text, sizeof(text), "scene=%u obj=%u pos=%.1f,%.1f generation=%u", world.sceneId(),
                                      world.myObjectId(), world.myX(), world.myY(), generation);
                        note("entered", text);
                        if (step == Step::Enter || step == Step::Goto) go(Step::Setup, "GCEnterScene");
                    }
                    // Portal: GCNotifyChangeScene -> CGAskChangeScene (the worker reconnects on GCRetChangeScene).
                    if (event.packetId == pg::GCNotifyChangeScene::PACKET_ID && world.changeScenePending()) {
                        if (send(world.makeAskChangeScene(), "CGAskChangeScene")) { ++notifyAsks; note("portal", "CGAskChangeScene " + std::to_string(world.notifyFrom()) + "->" + std::to_string(world.notifyTo())); }
                    }
                    if (event.packetId == pg::GCChat::PACKET_ID && world.lastChat().sourceId == world.myObjectId()) ++chatEchoes;
                    // CYS-TEAM: answer the invite the moment it arrives; worldcore only keeps it in flight while
                    // both sessions are online, so a step-driven reply would race the other bot's dwell.
                    if (options.teamAccept && !teamAccepted &&
                        (event.packetId == pg::GCTeamAskInvite::PACKET_ID || event.packetId == pg::GCTeamAskApply::PACKET_ID)) {
                        const auto& invite = world.pendingInvite();
                        const bool apply = event.packetId == pg::GCTeamAskApply::PACKET_ID;
                        auto reply = apply ? world.makeTeamRetApply(1, invite.guid) : world.makeTeamRetInvite(1, invite.guid);
                        if (send(std::move(reply), apply ? "CGTeamRetApply" : "CGTeamRetInvite")) {
                            teamAccepted = true; ++acceptsSent; acceptedInviter = invite.guid;
                            note("team_accept", std::string(apply ? "CGTeamRetApply" : "CGTeamRetInvite") + " accept=1 source=" +
                                 std::to_string(invite.guid) + " name=" + invite.nickname);
                        }
                    }
                    if (event.packetId == pg::GCDetailExp::PACKET_ID) {
                        const auto& gain = world.lastExp();
                        note("exp", "GCDetailExp exp=" + std::to_string(gain.exp) + " award=" + std::to_string(gain.awardExp) +
                             " pet=" + std::to_string(gain.petExp) + " total=" + std::to_string(world.expGained()));
                    }
                    if (event.packetId == pg::GCTeamResult::PACKET_ID) {
                        const auto& r = world.lastTeamResult();
                        note("team_result", "type=" + std::to_string(r.returnType) + " guid=" + std::to_string(r.guid) +
                             " team=" + std::to_string(r.teamId) + " name=" + r.name + " -> " + teamText());
                    }
                    if (event.packetId == pg::GCTeamList::PACKET_ID)
                        note("team_list", "#" + std::to_string(world.stats().teamLists) + " " + teamText());
                    if (event.packetId == pg::GCTeamError::PACKET_ID)
                        note("team_error", "GCTeamError code=" + std::to_string(world.lastTeamError()));
                    // CYS-TEAM: human:notify_tips (GCScriptCommand cmd 5) carries the server's refusal text,
                    // e.g. the level gate scenecore:check_limit_chat puts in front of private / scene chat.
                    if (event.packetId == pg::GCScriptCommand::PACKET_ID && world.stats().missionTips > tipsSeen) {
                        tipsSeen = world.stats().missionTips;
                        std::string hex; // the text is GBK on the wire; hex keeps the evidence byte-exact
                        for (unsigned char c : world.lastTip()) { const char* d = "0123456789abcdef"; hex += d[c >> 4]; hex += d[c & 15]; }
                        note("tip", "GCScriptCommand cmd=5 gbk_hex=" + hex);
                    }
                    // CYS-MOVE2: the server's answer to --fly (skill_15.lua effect_on_unit_once broadcasts GCCharFly)
                    if (event.packetId == pg::GCCharFly::PACKET_ID && event.packet) {
                        const auto& f = static_cast<const pg::GCCharFly&>(*event.packet);
                        char text[220];
                        std::snprintf(text, sizeof(text), "GCCharFly obj=%d%s logic=%d skill=%d from=%.1f,%.1f to=%.1f,%.1f to2=%.1f,%.1f u4=%d u5=%.2f",
                                      f.m_objID, f.m_objID == static_cast<int32_t>(world.myObjectId()) ? " (self)" : "", f.logic_count, f.skill_id,
                                      f.from_x, f.from_y, f.to_x, f.to_y, f.to_x_2, f.to_y_2, f.unknow_4, f.unknow_5);
                        note("fly_reply", text);
                    }
                    // CYS-ITEM: a positive hp_modification on the own object = something healed us.
                    if (event.packetId == pg::GCDetailHealsAndDamages::PACKET_ID) {
                        const auto& p = static_cast<const pg::GCDetailHealsAndDamages&>(*event.packet);
                        if(options.pvpPeer)note("pvp_damage","sender="+std::to_string(p.sender)+" receiver="+std::to_string(p.reciver)+" hp="+std::to_string(p.hp_modification));
                        if ((p.dirty_flags & 1) && p.hp_modification > 0 && world.myObjectId() &&
                            p.reciver == world.myObjectId()) {
                            ++healsOnMe;
                            healedHp += p.hp_modification;
                            note("heal", "GCDetailHealsAndDamages +" + std::to_string(p.hp_modification) +
                                         " sender=" + std::to_string(p.sender));
                        }
                    }
                    // CYS-ITEM: GCUseItemResult keeps only a counter in WorldModel; the code is what says whether
                    // the item script ran (0 = OR_OK) or refused (e.g. -33 OR_HEALTH_IS_FULL at full health).
                    if (event.packetId == pg::GCUseItemResult::PACKET_ID)
                        useResult = static_cast<const pg::GCUseItemResult&>(*event.packet).result;
                    // CYS-PET: the pet bag. One GCDetailAttrib_Pet per pet in human:send_pets_detail; the same
                    // packet is also the per-pet refresh of a summoned pet, so keep one row per PetGUID.
                    if (event.packetId == pg::GCDetailAttrib_Pet::PACKET_ID) {
                        const auto& p = static_cast<const pg::GCDetailAttrib_Pet&>(*event.packet);
                        ++petDetails;
                        PetRow row;
                        row.high = p.guid.m_uHighSection; row.low = p.guid.m_uLowSection;
                        row.dataIndex = p.data_index; row.level = p.level; row.hp = p.hp; row.hpMax = p.hp_max;
                        row.objId = p.m_objID;
                        // CYS-PETSKILL: the 13 skill cells, wire order.
                        {
                            const int32_t cells[13] = {
                                p.skills_activate_1_id, p.skills_activate_2_id,
                                p.skills_positive_1_id, p.skills_positive_2_id, p.skills_positive_3_id,
                                p.skills_positive_4_id, p.skills_positive_5_id, p.skills_positive_6_id,
                                p.skills_positive_7_id, p.skills_positive_8_id, p.skills_positive_9_id,
                                p.skills_positive_10_id, p.skills_positive_11_id };
                            for (int k = 0; k < 13; ++k) { row.skillIds[k] = cells[k]; if (cells[k] >= 0) ++row.skillCount; }
                        }
                        for (unsigned char c : p.name) { const char* d = "0123456789abcdef"; row.nameGbkHex += d[c >> 4]; row.nameGbkHex += d[c & 15]; }
                        bool merged = false;
                        for (auto& old : petBag)
                            if (old.high == row.high && old.low == row.low) { old = row; merged = true; break; }
                        if (!merged) petBag.push_back(row);
                        std::string skillText;   // CYS-PETSKILL
                        for (int k = 0; k < 13; ++k) skillText += (k ? "," : "") + std::to_string(row.skillIds[k]);
                        note("pet_detail", "guid=" + std::to_string(row.high) + ":" + std::to_string(row.low) +
                             " data=" + std::to_string(row.dataIndex) + " lv=" + std::to_string(row.level) +
                             " hp=" + std::to_string(row.hp) + "/" + std::to_string(row.hpMax) +
                             " obj=" + std::to_string(row.objId) + " name_gbk_hex=" + row.nameGbkHex +
                             " skills=" + std::to_string(row.skillCount) + "/13 [" + skillText + "]" +
                             " lingxing=" + std::to_string((int)p.lingxing) +
                             " attack_type=" + std::to_string((int)p.attack_type) +
                             " main_perception=" + std::to_string((unsigned)p.main_perception));
                    }
                    // CYS-PET: every capture / summon / recall / free answer (define.ENUM_MANIPULATEPET_RET:
                    // 0 capture fail, 1 capture ok, 2 callup fail, 3 callup ok, 4/5 free, 6/7 recall, 8/9 soul).
                    if (event.packetId == pg::GCManipulatePetRet::PACKET_ID) {
                        const auto& p = static_cast<const pg::GCManipulatePetRet&>(*event.packet);
                        ++petRets;
                        lastPetRet = p.ret; lastPetRetFighting = p.is_fighting;
                        lastPetRetHigh = p.guid.m_uHighSection; lastPetRetLow = p.guid.m_uLowSection;
                        note("pet_ret", "ret=" + std::to_string(p.ret) + " is_fighting=" + std::to_string(p.is_fighting) +
                             " guid=" + std::to_string(lastPetRetHigh) + ":" + std::to_string(lastPetRetLow));
                    }
                    if (event.packetId == pg::GCNewPet::PACKET_ID) {
                        const auto& p = static_cast<const pg::GCNewPet&>(*event.packet);
                        ++petNewPets;
                        note("pet_object", "GCNewPet obj=" + std::to_string(p.m_objID));
                    }
                    // CYS-ITEM: own combat attributes, so equip/unequip can be shown as a number change.
                    if (event.packetId == pg::GCDetailAttrib::PACKET_ID) {
                        const auto& p = static_cast<const pg::GCDetailAttrib&>(*event.packet);
                        if (world.myObjectId() && p.m_objID == world.myObjectId()) {
                            auto has = [&](int64_t index, int64_t mask) { return (pg::at1(p.flags, index) & mask) == mask; };
                            if (has(1, 1)) attrs.level = p.level;
                            if (has(1, 2)) attrs.hp = p.hp;
                            if (has(2, 128)) attrs.hpMax = p.hp_max;
                            if (has(1, 4)) attrs.mp = p.mp;
                            if (has(3, 1)) attrs.mpMax = p.mp_max;
                            if (has(2, 8)) attrs.attP = p.attrib_att_physics;
                            if (has(2, 32)) attrs.attM = p.attrib_att_magic;
                            if (has(2, 16)) attrs.defP = p.attrib_def_physics;
                            if (has(2, 64)) attrs.defM = p.attrib_def_magic;
                            if (has(3, 8)) attrs.hit = p.attrib_hit;
                            if (has(3, 16)) attrs.miss = p.attrib_miss;
                            // CYS-ATTRIB: the power fields of the very same packet (flag bits from
                            // PgPackets_combat.cpp GCDetailAttrib::read).
                            if (has(1, 32)) attrs.str = p.str;
                            if (has(1, 64)) attrs.spr = p.spr;
                            if (has(1, 128)) attrs.con = p.con;
                            if (has(2, 1)) attrs.intel = p.int_;
                            if (has(2, 2)) attrs.dex = p.dex;
                            if (has(2, 4)) attrs.pointRemain = p.point_remain;
                            if (has(3, 32)) attrs.mindAttack = p.mind_attack;
                            if (has(3, 64)) attrs.mindDefend = p.mind_defend;
                            if (has(3, 128)) attrs.xlStr = p.xiulian_str;
                            if (has(4, 1)) attrs.xlSpr = p.xiulian_spr;
                            if (has(4, 2)) attrs.xlCon = p.xiulian_con;
                            if (has(4, 4)) attrs.xlInt = p.xiulian_int;
                            if (has(4, 8)) attrs.xlDex = p.xiulian_dex;
                            if (has(4, 16)) attrs.xlHit = p.xiulian_attrib_hit;
                            if (has(4, 32)) attrs.xlMiss = p.xiulian_attrib_miss;
                            if (has(4, 64)) attrs.xlAttP = p.xiulian_attrib_att_physics;
                            if (has(4, 128)) attrs.xlDefP = p.xiulian_attrib_def_physics;
                            if (has(5, 1)) attrs.xlAttM = p.xiulian_attrib_att_magic;
                            if (has(5, 2)) attrs.xlDefM = p.xiulian_attrib_def_magic;
                            attrs.valid = true;
                            ++attribUpdates;
                        }
                    }
                    // CYS-ATTRIB: the three answers of the character-power loop.
                    if (event.packetId == pg::GCManualAttrResult::PACKET_ID) {
                        const auto& p = static_cast<const pg::GCManualAttrResult&>(*event.packet);
                        lastManualAttrResult = static_cast<int64_t>(static_cast<int32_t>(p.result));
                        ++manualAttrResults;
                    }
                    if (event.packetId == pg::GCCharAllTitles::PACKET_ID) {
                        const auto& p = static_cast<const pg::GCCharAllTitles&>(*event.packet);
                        if (!world.myObjectId() || p.m_objID == world.myObjectId()) {
                            ++titleLists;
                            titleIdCount = static_cast<uint32_t>(p.m_TitleIdList.size());
                            titleStrCount = static_cast<uint32_t>(p.m_TitleStrList.size());
                            titleListText.clear();
                            for (size_t i = 0; i < p.m_TitleIdList.size() && i < 24; ++i)
                                titleListText += (i ? "," : "") + std::to_string(p.m_TitleIdList[i].id) + ":" + std::to_string(p.m_TitleIdList[i].remain_time);
                        }
                    }
                    if (event.packetId == pg::GCRefreshKFSSkill::PACKET_ID) ++kfsRefreshes;
                    if (event.packetId == pg::GCDetailXiulianList::PACKET_ID) {
                        const auto& p = static_cast<const pg::GCDetailXiulianList&>(*event.packet);
                        ++xiulianLists;
                        xiulianText.clear();
                        for (size_t i = 0; i < p.xiulian.size(); ++i)
                            xiulianText += (i ? "," : "") + std::to_string(p.xiulian[i]) + "/" + std::to_string(p.xiulian_2[i]);
                        note("xiulian", "GCDetailXiulianList #" + std::to_string(xiulianLists) + " level/limit=[" + xiulianText + "] unknow_2=" + std::to_string(p.unknow_2));
                    }
                    if (event.packetId == pg::GCOperateResult::PACKET_ID) {
                        note("operate_result", std::to_string(world.lastOperateResult()));
                        const int32_t code = world.lastOperateResult();
                        if (step == Step::Attack && target && (code == -16 || code == -8) && ++rejectHits >= 3) {
                            note("target", "rejected by server (operate_result " + std::to_string(code) + "): " + std::to_string(target) + " -> next");
                            rejectedTargets.insert(target);
                            target = 0;
                            rejectHits = 0;
                        }
                        // CYS-SKILL: same rule for --cast (friendly NPC / invalid target -> next target).
                        // CYS-SELF / CYS-POS: only a "nearest live monster" step may hop to another target. A self,
                        // ground or explicit-object step is exempt - the refusal IS the measurement and there is no
                        // "next" self / point. Without this the ally-only skills (3557/3558/3432/4624) and every
                        // ground skill would silently move onto a monster. The step is the RUNNING one (castStep()),
                        // not the measured last one, so a --cast-seq prefix step keeps its own rule.
                        const bool castHops = options.castSet && !castStep().self && !castStep().pos && !castStep().target;
                        if (step == Step::Skills && castTargetId && sk >= Sk::Cast && sk <= Sk::CastLoop && (code == -16 || code == -8) && castHops && ++castRejects >= 2) {
                            note("target", "cast target refused by server (operate_result " + std::to_string(code) + "): " + std::to_string(castTargetId) + " -> next");
                            rejectedTargets.insert(castTargetId);
                            castTargetId = 0; castRejects = 0; casts = 0;
                            if (rejectedTargets.size() > 12) setSk(Sk::Done, "too many refused targets"); else setSk(Sk::CastPick, "target refused");
                        }
                    }
                    if (event.packetId == pg::GCPlayerDie::PACKET_ID) {
                        // CYS-STAYDEAD 17/09/2026: MOI resultcode cua CGPlayerDieResult deu goi relive()
                        // (services/scene/ai/human.lua push_command_die_result), va hoi sinh xong thi nhan
                        // vat roi canh ve diem hoi sinh. Muon giu MOT CAI XAC tai cho - thu duy nhat de do
                        // 408 khoi tu hoi sinh va 423 kim cham do kiep - thi phai KHONG tra loi gi ca.
                        if (options.stayDead) {
                            note("died", "GCPlayerDie -> khong tra loi (--stay-dead: giu xac tai cho)");
                        } else {
                            note("died", "GCPlayerDie -> CGPlayerDieResult 0 (out ghost)");
                            send(world.makePlayerDieResult(0), "CGPlayerDieResult");
                        }
                    }
                    break;
                }
                case GameEventType::Transfer:
                    world.onTransfer();
                    inWorld = false;
                    note("transfer", "GCRetChangeScene accepted; reconnecting");
                    break;
                default:
                    terminal = std::move(event); haveTerminal = true;
                    break;
                }
            }, 256);
            if (haveTerminal) break;
            const long long age = inWorld ? static_cast<long long>(std::chrono::duration_cast<std::chrono::milliseconds>(Clock::now() - worldAt).count()) : 0;
            if (inWorld && !quitAsked) {
                if(options.pvpPeer==2 && age>90000){
                    static bool invited=false;const auto peerTarget=world.nearestPlayer(false);
                    if(!invited && peerTarget){std::unique_ptr<pg::CGChallenge> p(new pg::CGChallenge);p->type=0;p->m_objID=peerTarget;invited=send(std::move(p),"CGChallenge invite GUI");}
                }
                switch (step) {
                case Step::Enter:
                    break;
                case Step::Setup:
                    if (!setupSent) {
                        setupSent = true;
                        send(world.makeAskBaseAttrib(world.myObjectId()), "CGCharAskBaseAttrib");
                        if (options.selectRideSet) // CYS-RIDE: pick the mount first (set_ride)
                            send(world.makeExteriorApply(3, options.selectRide), "CGExteriorRequest(ride)");
                        if (options.rideSet) { // CYS-RIDE
                            if (send(world.makeAutoRide(options.rideFlag), "CGCharAutoRide")) ++rideAsks;
                        }
                        if (coreMode) {
                            send(world.makeAskDetailSkillList(), "CGAskDetailSkillList");
                            for (const auto& object : world.objects())
                                if (object.second.kind == WorldModel::Kind::Monster) send(world.makeAskBaseAttrib(object.first), "CGCharAskBaseAttrib(monster)");
                        }
                    }
                    // CYS-MOVE2: --fly sends CGCharFly once, 1.5 s after setup, and stays 5 s more for GCCharFly / tips.
                    if (options.flySet && !flySent && sinceStep() >= 1500) {
                        flySent = true;
                        std::unique_ptr<pg::CGCharFly> fly(new pg::CGCharFly);
                        fly->m_objID = world.myObjectId(); fly->skill_id = static_cast<uint32_t>(options.flySkill);
                        fly->from_x = world.myX(); fly->from_y = world.myY(); fly->to_x = options.flyX; fly->to_y = options.flyZ;
                        char text[200];
                        std::snprintf(text, sizeof(text), "CGCharFly skill=%d from=%.1f,%.1f to=%.1f,%.1f dist=%.2f", options.flySkill,
                                      world.myX(), world.myY(), options.flyX, options.flyZ, distanceTo(options.flyX, options.flyZ));
                        note("fly", text);
                        send(std::move(fly), "CGCharFly");
                    }
                    if (sinceStep() >= (options.flySet ? 6500 : 1500)) {
                        // The legacy one-step walk (--walk 1) stays available for the old live check.
                        if (options.walk && movesSent == 0) { if (send(world.makeMove(startX + 1.0f, startY), "CGCharMove")) ++movesSent; }
                        // --goto targets the FIRST scene only: a portal transfer (generation > 1) means we arrived.
                        float monsterDistance = 0;
                        const bool monsterNear = world.nearestMonster(&monsterDistance) != 0 && monsterDistance <= 25.0f;
                        if (options.gotoSet && generation == 1 && (options.gotoScene < 0 || options.gotoScene == static_cast<int>(world.sceneId())) && distanceTo(options.gotoX, options.gotoZ) > 3.0f) {
                            const float seconds = walkTo(options.gotoX, options.gotoZ, 0.0f);
                            if (seconds < 0) { go(Step::Quit, "walk refused"); break; }
                            arriveAt = Clock::now() + std::chrono::milliseconds(static_cast<long long>(seconds * 1000) + 2500);
                            go(Step::Goto, "walking to the portal/target");
                        } else if (options.huntSet && !monsterNear && distanceTo(options.huntX, options.huntZ) > 3.0f) {
                            const float seconds = walkTo(options.huntX, options.huntZ, 0.0f);
                            if (seconds < 0) { go(Step::Quit, "hunt walk refused"); break; }
                            arriveAt = Clock::now() + std::chrono::milliseconds(static_cast<long long>(seconds * 1000) + 2500);
                            go(Step::Goto, "walking to the hunt spot (no live monster within 25 m)");
                        } else if (options.chat) go(Step::Chat, "setup done");
                        else if (options.teamMode() && !teamDone) go(Step::Team, "setup done"); // CYS-TEAM
                        else if (options.attribMode() && !attribDone) go(Step::Attrib, "setup done"); // CYS-ATTRIB
                        else if (options.skillMode() && !skillsDone) go(Step::Skills, "setup done"); // CYS-SKILL
                        // CYS-PET: the inventory phase first (a pet egg has to be used before the pet bag is
                        // listed), then the pet phase, and only then Attack, so a summoned pet is already out
                        // while the bot fights.
                        else if (options.petMode() && options.invMode() && !invDone) go(Step::Inv, "setup done");
                        // --pet-capture needs a wild pet to exist first, and the only thing that makes one is a
                        // pet monster dying (petdropper.lua OnDie), so Attack has to run BEFORE the pet phase then.
                        else if (options.petMode() && !options.petCapture && !petDone) go(Step::Pet, "setup done");
                        else if (options.attack) go(Step::Attack, "setup done");
                        else if (options.bag) go(Step::Bag, "setup done");
                        else go(Step::Quit, "setup done");
                    }
                    break;
                case Step::Goto:
                    // Arrival = timed estimate (the own GCCharMove echo only confirms the path). A portal transfer
                    // re-enters the Setup step through GCEnterScene; without a portal we continue in place.
                    if (Clock::now() >= arriveAt) {
                        char text[96];
                        std::snprintf(text, sizeof(text), "arrived (model) at %.1f,%.1f scene=%u", world.myX(), world.myY(), world.sceneId());
                        note("goto", text);
                        if (options.chat) go(Step::Chat, "arrived");
                        else if (options.teamMode() && !teamDone) go(Step::Team, "arrived"); // CYS-TEAM
                        else if (options.attribMode() && !attribDone) go(Step::Attrib, "arrived"); // CYS-ATTRIB
                        else if (options.skillMode() && !skillsDone) go(Step::Skills, "arrived");
                        else if (options.petMode() && options.invMode() && !invDone) go(Step::Inv, "arrived"); // CYS-PET
                        else if (options.petMode() && !petDone) go(Step::Pet, "arrived"); // CYS-PET
                        else if (options.attack) go(Step::Attack, "arrived");
                        else if (options.bag) go(Step::Bag, "arrived"); else go(Step::Quit, "arrived");
                    }
                    break;
                case Step::Chat:
                    if (execsSent < options.execs.size()) { // CYS-EXEC
                        if (execsSent == 0 || sinceExec() >= 1500) {
                            const Options::Exec& e = options.execs[execsSent];
                            std::unique_ptr<pg::CGExecuteScript> pkt(new pg::CGExecuteScript);
                            pkt->m_ScriptID = e.script; pkt->set_m_szFunName(e.func);
                            pkt->m_aParam = e.params; pkt->m_uParamCount = static_cast<uint8_t>(e.params.size());
                            std::string desc = "CGExecuteScript " + std::to_string(e.script) + ":" + e.func;
                            for (int32_t v : e.params) desc += "," + std::to_string(v);
                            if (send(std::unique_ptr<pg::Packet>(pkt.release()), "CGExecuteScript")) note("exec", desc); else note("exec", "refused: " + desc);
                            ++execsSent; execAt = Clock::now();
                        }
                        break;
                    }
                    if (execsSent > 0 && sinceExec() < 2500) break; // CYS-EXEC: let the last script reply arrive
                    if (chatsSent == 0) {
                        if (send(world.makeChat(0, options.chatText), "CGChat")) { ++chatsSent; note("chat", "CGChat type=0 bytes=" + std::to_string(options.chatText.size())); }
                        else go(Step::Quit, "chat refused");
                    } else if (chatEchoes > 0 || sinceStep() >= 4000) {
                        note("chat", chatEchoes ? "GCChat echo received from own object" : "no GCChat echo within 4 s");
                        if (options.teamMode() && !teamDone) go(Step::Team, "chat done"); // CYS-TEAM
                        else if (options.attribMode() && !attribDone) go(Step::Attrib, "chat done"); // CYS-ATTRIB
                        else if (options.skillMode() && !skillsDone) go(Step::Skills, "chat done"); else if (options.attack) go(Step::Attack, "chat done"); else if (options.bag) go(Step::Bag, "chat done"); else go(Step::Quit, "chat done");
                    }
                    break;
                case Step::Attack: {
                    if (kills >= options.attack || sinceStep() > 90000) {
                        note("attack", "done kills=" + std::to_string(kills) + " skills_sent=" + std::to_string(skillsSent));
                        if (options.bag) go(Step::Bag, "attack done"); else go(Step::Quit, "attack done");
                        break;
                    }
                    if (skillId < 0) {
                        if (!world.skills().empty() || sinceStep() >= 3000) {
                            skillId = static_cast<int32_t>(options.skill);
                            bool listed = false;
                            for (uint32_t id : world.skills()) listed = listed || id == options.skill;
                            if (!listed && !world.skills().empty() && options.skill != 0) skillId = static_cast<int32_t>(world.skills()[0]);
                            std::string list;
                            for (size_t i = 0; i < world.skills().size() && i < 24; ++i) list += (i ? "," : "") + std::to_string(world.skills()[i]);
                            note("skills", "list=[" + list + "] use=" + std::to_string(skillId) + (listed ? " (listed)" : " (not listed)"));
                        }
                        break;
                    }
                    const auto& objects = world.objects();
                    auto found = target ? objects.find(target) : objects.end();
                    if (found == objects.end() || found->second.hpPercent == 0) {
                        if (target) {
                            const bool died = found == objects.end() || found->second.hpPercent == 0;
                            if (died) { ++kills; note("kill", "target " + std::to_string(target) + (found == objects.end() ? " deleted" : " hp 0") + " after " + std::to_string(skillsSent) + " skills"); }
                            target = 0;
                            if (options.pickup) { go(Step::Pickup, "waiting for the drop box"); break; }
                            if (kills >= options.attack) break;
                        }
                        float distance = 0;
                        uint32_t next = world.nearestMonster(&distance);
                        if (next && rejectedTargets.count(next)) {
                            next = 0;
                            for (const auto& entry : objects) {
                                const auto& m = entry.second;
                                if (m.kind != WorldModel::Kind::Monster || m.hpPercent == 0 || rejectedTargets.count(entry.first) || (m.x == 0 && m.y == 0)) continue;
                                const float d = std::sqrt((m.x - world.myX()) * (m.x - world.myX()) + (m.y - world.myY()) * (m.y - world.myY()));
                                if (!next || d < distance) { next = entry.first; distance = d; }
                            }
                        }
                        if (!next && options.huntSet && distanceTo(options.huntX, options.huntZ) > 3.0f && Clock::now() >= swingAt) {
                            const float seconds = walkTo(options.huntX, options.huntZ, 0.0f);
                            note("attack", "no acceptable target in view; walking to the hunt spot");
                            swingAt = Clock::now() + std::chrono::milliseconds(seconds > 0 ? static_cast<long long>(seconds * 1000) + 800 : 3000);
                            break;
                        }
                        if (!next) { if (sinceStep() > 8000 && Clock::now() >= swingAt) { note("attack", "no live monster in view"); go(options.bag ? Step::Bag : Step::Quit, "no monster"); } break; }
                        rejectHits = 0;
                        target = next; ++targetsTried;
                        const auto& o = objects.at(next);
                        char text[160];
                        std::snprintf(text, sizeof(text), "target=%u name=%s level=%d hp=%d dist=%.1f pos=%.1f,%.1f", next, o.name.c_str(), o.level, o.hpPercent, distance, o.x, o.y);
                        note("target", text);
                        if (send(world.makeLockTarget(static_cast<int32_t>(next)), "CGLockTarget")) ++locksSent;
                        if (distance > 4.0f) {
                            const float seconds = walkTo(o.x, o.y, 2.0f);
                            swingAt = Clock::now() + std::chrono::milliseconds(seconds > 0 ? static_cast<long long>(seconds * 1000) + 800 : 800);
                        } else swingAt = Clock::now() + std::chrono::milliseconds(300);
                        break;
                    }
                    if (Clock::now() >= swingAt) {
                        if (send(world.makeUseSkill(skillId, static_cast<int32_t>(target)), "CGCharUseSkill")) ++skillsSent;
                        swingAt = Clock::now() + std::chrono::milliseconds(1300);
                        if (skillsSent >= 40) { note("attack", "40 skills without a kill; giving up on the target"); target = 0; }
                    }
                    break;
                }
                case Step::Pickup: {
                    if ((boxOpened && world.stats().boxLists > 0 && world.boxItems().empty() && Clock::now() >= swingAt) || sinceStep() > 8000) {
                        note("pickup", "done picks_sent=" + std::to_string(picksSent) + " picks_ok=" + std::to_string(world.stats().picksOk) + " bag_items=" + std::to_string(world.bag().size()));
                        go(kills >= options.attack ? (options.bag ? Step::Bag : Step::Quit) : Step::Attack, "pickup done");
                        break;
                    }
                    const uint32_t box = world.nearestItemBox(12.0f);
                    if (!box) {
                        if (sinceStep() > 4000) { note("pickup", "no drop box within 4 s"); go(kills >= options.attack ? (options.bag ? Step::Bag : Step::Quit) : Step::Attack, "no box"); }
                        break;
                    }
                    if (boxOpened != box) {
                        boxOpened = box;
                        const auto& b = world.itemBoxes().at(box);
                        char text[160];
                        std::snprintf(text, sizeof(text), "box=%u owner=%d monster=%d type=%d pos=%.1f,%.1f mine=%d", box, b.owner, b.monster, b.type, b.x, b.y, b.owner == world.myGuid() ? 1 : 0);
                        note("box", text);
                        send(world.makeOpenItemBox(box), "CGOpenItemBox");
                        swingAt = Clock::now() + std::chrono::milliseconds(600);
                        break;
                    }
                    if (world.openBoxId() == box && !world.boxItems().empty() && Clock::now() >= swingAt) {
                        const auto& item = world.boxItems().front();
                        note("pick", "item_index=" + std::to_string(item.itemIndex) + " series=" + std::to_string(item.guid.series));
                        if (send(world.makePickBoxItem(box, item.guid), "CGPickBoxItem")) ++picksSent;
                        swingAt = Clock::now() + std::chrono::milliseconds(700);
                        break;
                    }
                    break;
                }
                case Step::Bag:
                    if (bagAsks == 0) { if (send(world.makeAskMyBagList(), "CGAskMyBagList")) ++bagAsks; else go(Step::Quit, "bag refused"); }
                    else if (world.stats().bagLists > 0 || sinceStep() >= 3000) {
                        note("bag", "GCMyBagList lists=" + std::to_string(world.stats().bagLists) + " items=" + std::to_string(world.bag().size()));
                        go(Step::Quit, "bag done");
                    }
                    break;
                case Step::Inv: runInventory(); break; // CYS-INV
                case Step::Skills: runSkills(); break; // CYS-SKILL
                case Step::Quest: runQuest(); break; // CYS-QUEST
                case Step::Team: runTeam(); break; // CYS-TEAM
                case Step::Pet: runPet(); break; // CYS-PET
                case Step::Attrib: attribPhase(); break; // CYS-ATTRIB
                case Step::Quit:
                    if (options.invMode() && !invDone) { go(Step::Inv, "inventory steps"); break; } // CYS-INV
                    if (options.questOn() && !questDone) { go(Step::Quest, "quest steps"); break; } // CYS-QUEST
                    if (options.teamMode() && !teamDone) { go(Step::Team, "team steps"); break; } // CYS-TEAM
                    if (options.petMode() && !petDone) { go(Step::Pet, "pet steps"); break; } // CYS-PET
                    if (options.attribMode() && !attribDone) { go(Step::Attrib, "attrib steps"); break; } // CYS-ATTRIB
                    // CYS-TEAM: --hold-ms keeps the session in world (the exp split needs the second member present
                    // while the owner kills); the leave / dismiss is the last packet before CGAskQuit.
                    if (options.holdMs && age < static_cast<long long>(options.holdMs)) break;
                    if ((options.teamLeave || options.teamDismiss) && !teamLeaveSent) {
                        teamLeaveSent = true;
                        if (options.teamDismiss) { if (send(world.makeTeamDismiss(), "CGTeamDismiss")) note("team_leave", "CGTeamDismiss"); }
                        else if (send(world.makeTeamLeave(), "CGTeamLeave")) note("team_leave", "CGTeamLeave guid=" + std::to_string(world.myGuid()));
                        stepAt = Clock::now();
                        break;
                    }
                    if (teamLeaveSent && sinceStep() < 2000) break; // let GCTeamResult land before quitting
                    if (teamLeaveSent && teamLog.find("left ") == std::string::npos) {
                        teamLog += "left in_team=" + std::string(world.inTeam() ? "true" : "false") +
                                   " last_result=" + std::to_string(world.lastTeamResult().returnType) + "; ";
                        note("team_left", "in_team=" + std::string(world.inTeam() ? "true" : "false") + " " + teamText());
                    }
                    // A PvP fixture's lifetime spans arena entry AND return; scene age resets at each transfer.
                    const auto dwellAge = options.pvpPeer ? std::chrono::duration_cast<std::chrono::milliseconds>(Clock::now()-pvpSessionAt).count() : age;
                    if (dwellAge >= static_cast<long long>(options.dwellMs) || (options.attack || options.chat || options.bag || options.gotoSet || options.invMode() || options.skillMode() || options.questOn() || options.teamMode() || options.attribMode())) {
                        if (options.walk && movesSent == 1 && sinceStep() < 1500) break;
                        if (options.walk && movesSent == 1) { if (send(world.makeMove(startX, startY), "CGCharMove")) ++movesSent; lastSendAt = Clock::now(); break; }
                        // The owner queue and the quit flag race in the worker: give the last packet 400 ms on the wire first.
                        if (Clock::now() - lastSendAt < std::chrono::milliseconds(400)) break;
                        quitAsked = true;
                        gameDeadline = (std::max)(gameDeadline, Clock::now() + std::chrono::seconds(30)); // GCRetAskQuit + server close (quit tick <= 10 s)
                        note("quit", "CGAskQuit");
                        if (!game.requestQuit()) { error = "quit could not be requested"; game.cancel(); }
                    }
                    break;
                }
            }
            std::this_thread::sleep_for(std::chrono::milliseconds(5));
        }
        if (!haveTerminal) {
            game.cancel();
            const auto drain = Clock::now() + std::chrono::seconds(3);
            while (!haveTerminal && Clock::now() < drain) {
                game.pump([&](GameEvent&& event) {
                    if (event.type != GameEventType::Packet && event.type != GameEventType::Connected &&
                        event.type != GameEventType::Transfer) { terminal = std::move(event); haveTerminal = true; }
                }, 256);
                std::this_thread::sleep_for(std::chrono::milliseconds(5));
            }
            code = 4; error = "world deadline exceeded; socket cancelled";
        } else {
            gameCounters = terminal.counters;
            quitFlag = terminal.quitFlag;
            terminalName = GameEventName(terminal.type);
            if (terminal.type == GameEventType::QuitComplete && terminal.quitFlag == 0) code = 0;
            else if (terminal.type == GameEventType::QuitComplete) { code = 7; error = "server closed without GCRetAskQuit"; }
            else {
                code = terminal.error == ErrorCode::Decode ? 5 : terminal.error == ErrorCode::UnexpectedPacket ? 7 : 4;
                error = terminal.message;
            }
        }
    }
    // CYS-CORE: fixture of the recorded game socket (the one with combat frames, else the last one).
    std::string fixturePath, fixtureError;
    unsigned fixtureSocket = 0;
    if (recorder) {
        fixtureSocket = recorder->lastSocketWith(pg::GCNewItemBox::PACKET_ID);
        if (!fixtureSocket) fixtureSocket = recorder->lastSocketWith(pg::GCCharSkill_Send::PACKET_ID);
        if (!fixtureSocket) fixtureSocket = recorder->sockets();
        if (fixtureSocket) {
            fixturePath = directory + "/world_core_g" + std::to_string(fixtureSocket) + ".bin";
            if (!recorder->writeFixture(fixturePath, fixtureSocket, fixtureError)) fixturePath.clear();
            for (auto& c : fixturePath) if (c == '\\') c = '/'; // JSON-safe path
        } else fixtureError = "no game socket recorded";
    }
    std::ofstream table(directory + "/report.tsv");
    table << "proto\tdir\tid\tname\tcount\n";
    for (const auto& entry : world.packetCounts()) {
        const auto* info = pg::findPacket(pg::Proto::Game, entry.first);
        table << "game\tGC\t" << entry.first << '\t' << (info ? info->name : "unknown") << '\t' << entry.second << '\n';
    }
    const auto& st = world.stats();
    char index[8] = {}, ticketText[8] = {};
    std::snprintf(index, sizeof(index), "%04x", gameCounters.nextTxIndex);
    std::snprintf(ticketText, sizeof(ticketText), "%04x", ticketIndex);
    std::string skillList;
    for (size_t i = 0; i < world.skills().size(); ++i) skillList += (i ? "," : "") + std::to_string(world.skills()[i]);
    std::ofstream result(directory + "/result.json");
    result << "{\n  \"scope\": \"world-session\",\n  \"host\": \"" << options.host << "\",\n  \"login_port\": " << options.port
           << ",\n  \"game_port\": " << options.gamePort << ",\n  \"guid\": " << options.guid
           << ",\n  \"exit_code\": " << code << ",\n  \"error\": \"" << error << "\",\n  \"login_flag\": " << loginFlag
           << ",\n  \"character_count\": " << characterCount << ",\n  \"charlogin\": \"" << charLogin
           << "\",\n  \"login_tx_frames\": " << loginCounters.txFrames << ",\n  \"ticket_next_idx\": \"" << ticketText
           << "\",\n  \"first_game_frame\": \"CGConnect\",\n  \"terminal\": \"" << terminalName
           << "\",\n  \"quit_flag\": " << quitFlag << ",\n  \"generation\": " << generation
           << ",\n  \"game_tx_frames\": " << gameCounters.txFrames << ",\n  \"game_rx_frames\": " << gameCounters.rxFrames
           << ",\n  \"heartbeats\": " << gameCounters.heartbeats << ",\n  \"transfers\": " << gameCounters.transfers
           << ",\n  \"decode_failures\": " << gameCounters.decodeFailures
           // CYS-UNKNOWNID: gói server gửi mà Registry chưa có dòng nào (bỏ qua, không giết phiên).
           << ",\n  \"unknown_packets\": " << gameCounters.unknownPackets
           << ",\n  \"unknown_first_id\": " << gameCounters.firstUnknownId
           << ",\n  \"unknown_last_id\": " << gameCounters.lastUnknownId
           << ",\n  \"dropped_outbound\": " << gameCounters.droppedOutbound << ",\n  \"next_idx\": \"" << index
           << "\",\n  \"moves_sent\": " << movesSent << ",\n  \"in_world\": " << (inWorld ? "true" : "false")
           << ",\n  \"world\": {\"my\": " << world.myObjectId() << ", \"scene\": " << world.sceneId()
           << ", \"objects\": " << world.objects().size() << ", \"created\": " << st.created << ", \"deleted\": " << st.deleted
           << ", \"moves\": " << st.moves << ", \"self_moves\": " << st.selfMoves << ", \"base_attribs\": " << st.baseAttribs
           << ", \"quit_acks\": " << st.quitAcks << "},\n"
           // CYS-CORE
           << "  \"core\": {\"step\": \"" << stepName(step) << "\", \"goto\": " << (options.gotoSet ? "true" : "false")
           << ", \"portal_asks\": " << notifyAsks << ", \"final_scene\": " << world.sceneId()
           << ", \"final_pos\": [" << world.myX() << ", " << world.myY() << "]"
           << ", \"chats_sent\": " << chatsSent << ", \"chat_echoes\": " << chatEchoes << ", \"chats_seen\": " << st.chats
           << ", \"skill_list\": [" << skillList << "], \"skill_used\": " << skillId
           << ", \"targets_tried\": " << targetsTried << ", \"locks_sent\": " << locksSent << ", \"skills_sent\": " << skillsSent
           << ", \"skill_sends_seen\": " << st.skillSends << ", \"self_skill_sends\": " << st.selfSkillSends
           << ", \"target_lists\": " << st.targetLists << ", \"damages\": " << st.damages << ", \"damage_dealt\": " << st.damageDealt
           << ", \"damage_taken\": " << st.damageTaken << ", \"hp_updates\": " << st.hpUpdates << ", \"target_deaths\": " << st.targetDeaths
           << ", \"kills\": " << kills << ", \"item_boxes\": " << st.itemBoxes << ", \"box_lists\": " << st.boxLists
           << ", \"picks_sent\": " << picksSent << ", \"pick_results\": " << st.pickResults << ", \"picks_ok\": " << st.picksOk
           << ", \"item_infos\": " << st.itemInfos << ", \"bag_asks\": " << bagAsks << ", \"bag_lists\": " << st.bagLists
           << ", \"bag_items\": " << world.bag().size() << ", \"skill_lists\": " << st.skillLists
           << ", \"operate_results\": " << st.operateResults << ", \"last_operate_result\": " << world.lastOperateResult()
           << ", \"player_dies\": " << st.playerDies << ", \"player_relives\": " << st.playerRelives
           << ", \"my_level\": " << world.myLevel() << ", \"my_hp\": " << world.myHp() << ", \"my_max_hp\": " << world.myMaxHp()
           << ", \"my_exp\": " << world.myExp() << ", \"my_guid\": " << world.myGuid() << ", \"my_camp\": " << world.myCamp()
           << ", \"detail_attribs\": " << st.detailAttribs << ", \"level_ups\": " << st.levelUps
           << ", \"ride_asks\": " << rideAsks << ", \"ride_replies\": " << st.autoRideReplies
           << ", \"ride_model\": " << world.myRideModel() << ", \"ride_model_changes\": " << world.rideModelChanges() // CYS-RIDE
           << ", \"fixture\": \"" << fixturePath << "\", \"fixture_socket\": " << fixtureSocket
           << ", \"fixture_error\": \"" << fixtureError << "\", \"record_sockets\": " << (recorder ? recorder->sockets() : 0) << "},\n"
           // CYS-INV
           << "  \"inventory\": {\"enabled\": " << (options.invMode() ? "true" : "false") << ", \"done\": " << (invDone ? "true" : "false")
           << ", \"phase\": \"" << invName(inv) << "\", \"money\": " << world.myMoney() << ", \"jiaozi\": " << world.myJiaozi() << ", \"equip_lists\": " << st.equipLists
           << ", \"char_equipments\": " << st.charEquipments << ", \"script_menus\": " << st.scriptEventLists << ", \"shop_lists\": " << st.shopLists
           << ", \"shop_id\": " << world.shop().shopId << ", \"shop_goods\": " << world.shop().goods.size()
           << ", \"shop_buys\": " << st.shopBuys << ", \"buys_ok\": " << st.buysOk << ", \"bought_slots\": " << bought.size()
           << ", \"use_equips\": " << st.useEquips << ", \"use_equips_ok\": " << st.useEquipsOk << ", \"un_equips\": " << st.unEquips
           << ", \"un_equips_ok\": " << st.unEquipsOk << ", \"shop_sells\": " << st.shopSells << ", \"sells_ok\": " << st.sellsOk
           << ", \"sold_lists\": " << st.soldLists << ", \"discards\": " << st.discards << ", \"discards_ok\": " << st.discardsOk << ", \"splits\": " << st.splits << ", \"swaps\": " << st.swaps
           << ", \"item_infos\": " << st.itemInfos << ", \"equips\": " << world.equips().size() << ", \"bag_items\": " << world.bag().size()
           // CYS-ITEM: consumables (--use) and the attribute snapshots around equip/unequip.
           << ", \"use_item\": " << options.useItem << ", \"use_sent\": " << usesSent << ", \"use_results\": " << st.useItems
           << ", \"use_ok\": " << usesOk << ", \"use_last_result\": " << useResult << ", \"use_summary\": \"" << useLog << "\""
           << ", \"heals_on_me\": " << healsOnMe << ", \"healed_hp\": " << healedHp
           << ", \"attrib_updates\": " << attribUpdates
           << ", \"attrs_start\": \"" << (attrsStart.valid ? attrsStart.text() : std::string()) << "\""
           << ", \"attrs_after_unequip\": \"" << (attrsAfterUnequip.valid ? attrsAfterUnequip.text() : std::string()) << "\""
           << ", \"attrs_after_equip\": \"" << (attrsAfterEquip.valid ? attrsAfterEquip.text() : std::string()) << "\""
           << ", \"attrs_end\": \"" << (attrs.valid ? attrs.text() : std::string()) << "\""
           << ", \"summary\": \"" << invLog << "\"},\n"
           // CYS-SKILL
           << "  \"skills\": {\"enabled\": " << (options.skillMode() ? "true" : "false") << ", \"done\": " << (skillsDone ? "true" : "false")
           << ", \"phase\": \"" << skName(sk) << "\", \"menpai\": " << world.myMenpai() << ", \"setting_lists\": " << st.settingLists
           << ", \"xinfa_lists\": " << st.xinfaLists << ", \"xinfa_count\": " << world.xinfas().size() << ", \"cooldown_updates\": " << st.cooldowns
           << ", \"cooldown_entries\": " << st.cooldownEntries << ", \"study_results\": " << st.studyResults << ", \"casts\": " << casts
           << ", \"cast_kills\": " << castKills << ", \"bar_slot\": " << barSlot
           // CYS-SELF: cast_self / cast_skill / cast_target make the measured target explicit in the evidence.
           // CYS-POS / CYS-SEQ: cast_pos + cast_pos_xy are the ground point actually sent, cast_seq is the parsed
           // step list in cast order and cast_steps_done says how far the run got. Fields are only ADDED here:
           // menpai_check.ps1 / aggregate_check.py read result.json by name, so the TSV layout is untouched.
           << ", \"cast_skill\": " << options.castSkill << ", \"cast_self\": " << (options.castSelf ? "true" : "false")
           << ", \"cast_pos\": " << (options.castPos ? "true" : "false")
           << ", \"cast_pos_xy\": [" << castPosX << ", " << castPosZ << "]"
           << ", \"cast_seq\": \"" << castSeqText << "\", \"cast_steps\": " << options.castSteps.size()
           << ", \"cast_steps_done\": " << (options.castSteps.empty() ? 0 : castIndex + 1)
           << ", \"cast_hp_before\": " << skHpBefore << ", \"cast_hp_after\": " << world.myHp()
           << ", \"cast_target\": " << castTargetId << ", \"summary\": \"" << skillLog << "\"},\n"
           // CYS-QUEST
           << "  \"quest\": {\"enabled\": " << (options.questOn() ? "true" : "false") << ", \"done\": " << (questDone ? "true" : "false")
           << ", \"phase\": \"" << qName(q) << "\", \"mode\": " << options.questMode << ", \"talks\": " << talks
           << ", \"script\": " << qScript << ", \"mission\": " << qMission << ", \"accepted\": " << (questAccepted ? "true" : "false")
           << ", \"submitted\": " << (questSubmitted ? "true" : "false") << ", \"transferred\": " << (portalDone ? "true" : "false")
           << ", \"exp_before\": " << expBefore << ", \"exp_after\": " << world.myExp()
           << ", \"script_menus\": " << st.scriptEventLists << ", \"mission_lists\": " << st.missionLists << ", \"mission_infos\": " << st.missionInfos
           << ", \"mission_demands\": " << st.missionDemands << ", \"mission_continues\": " << st.missionContinues << ", \"mission_tips\": " << st.missionTips
           << ", \"mission_adds\": " << st.missionAdds << ", \"mission_modifies\": " << st.missionModifies << ", \"mission_removes\": " << st.missionRemoves
           << ", \"mission_done_flags\": " << st.missionDoneFlags << ", \"ui_commands\": " << st.uiCommands << ", \"missions\": " << world.missions().size()
           << ", \"summary\": \"" << questLog << "\"},\n"
           // CYS-TEAM
           << "  \"team\": {\"enabled\": " << (options.teamMode() ? "true" : "false") << ", \"done\": " << (teamDone ? "true" : "false")
           << ", \"phase\": \"" << tmName(tm) << "\", \"char_name\": \"" << charName << "\""
           << ", \"invite_target\": \"" << options.teamInvite << "\", \"apply_target\": \"" << options.teamApply << "\""
           << ", \"invites_sent\": " << invitesSent << ", \"accepts_sent\": " << acceptsSent
           << ", \"accepted_inviter\": " << acceptedInviter << ", \"in_team\": " << (world.inTeam() ? "true" : "false")
           << ", \"team_id\": " << world.teamId() << ", \"leader\": " << world.teamLeader()
           << ", \"exp_mode\": " << world.teamExpMode() << ", \"members\": " << world.teamMembers().size()
           << ", \"member_list\": [";
    {
        const auto& members = world.teamMembers();
        for (size_t i = 0; i < members.size(); ++i)
            result << (i ? ", " : "") << "{\"guid\": " << members[i].guid << ", \"name\": \"" << members[i].name
                   << "\", \"obj\": " << members[i].objId << ", \"scene\": " << members[i].sceneId
                   << ", \"level\": " << members[i].level << ", \"menpai\": " << static_cast<int>(members[i].menpai) << "}";
    }
    result << "], \"team_lists\": " << st.teamLists << ", \"team_results\": " << st.teamResults
           << ", \"team_errors\": " << st.teamErrors << ", \"last_team_error\": " << world.lastTeamError()
           << ", \"ask_invites\": " << st.teamAskInvites << ", \"leader_ask_invites\": " << st.teamLeaderAskInvites
           << ", \"ask_applies\": " << st.teamAskApplies << ", \"option_changes\": " << st.teamOptionChanges
           << ", \"member_infos\": " << st.teamMemberInfos << ", \"info_asks\": " << teamInfoAsks
           << ", \"member_info_asks\": " << memberInfoAsks
           << ", \"team_chats_sent\": " << teamChatsSent << ", \"team_chats_seen\": " << st.teamChats
           << ", \"tells_sent\": " << tellsSent << ", \"tells_seen\": " << st.tellChats
           << ", \"appoint_sent\": " << (options.teamAppoint ? "true" : "false")
           << ", \"kick_sent\": " << (options.teamKick ? "true" : "false")
           << ", \"leave_sent\": " << (teamLeaveSent ? "true" : "false")
           << ", \"last_result_type\": " << world.lastTeamResult().returnType
           << ", \"exp_packets\": " << st.expPackets << ", \"exp_gained\": " << world.expGained()
           << ", \"last_exp\": [" << world.lastExp().exp << ", " << world.lastExp().awardExp << "]"
           << ", \"summary\": \"" << teamLog << "\"},\n"
           // CYS-PET: the pet loop. pet_bag is what GCDetailAttrib_Pet actually carried, so "the pet bag is empty"
           // and "the summon failed" stay apart. last_ret is define.ENUM_MANIPULATEPET_RET.
           << "  \"pet\": {\"enabled\": " << (options.petMode() ? "true" : "false") << ", \"done\": " << (petDone ? "true" : "false")
           << ", \"phase\": \"" << ptName(pt) << "\", \"mode\": " << options.pet
           << ", \"capture\": " << (options.petCapture ? "true" : "false")
           << ", \"pet_details\": " << petDetails << ", \"pet_bag_size\": " << petBag.size()
           << ", \"pet_bag_before\": " << petBagBefore
           << ", \"captures_sent\": " << capturesSent << ", \"capture_target\": " << captureTarget
           << ", \"summons_sent\": " << summonsSent << ", \"recalls_sent\": " << recallsSent
           << ", \"manipulate_rets\": " << petRets << ", \"last_ret\": " << lastPetRet
           << ", \"last_ret_guid\": [" << lastPetRetHigh << ", " << lastPetRetLow << "]"
           << ", \"is_fighting\": " << lastPetRetFighting << ", \"new_pet_objects\": " << petNewPets
           << ", \"summon_guid\": [" << summonHigh << ", " << summonLow << "]"
           << ", \"pet_bag\": [";
    for (size_t i = 0; i < petBag.size(); ++i)
        result << (i ? ", " : "") << "{\"guid\": [" << petBag[i].high << ", " << petBag[i].low
               << "], \"data_index\": " << petBag[i].dataIndex << ", \"level\": " << petBag[i].level
               << ", \"hp\": " << petBag[i].hp << ", \"hp_max\": " << petBag[i].hpMax
               << ", \"obj\": " << petBag[i].objId << ", \"name_gbk_hex\": \"" << petBag[i].nameGbkHex << "\"}";
    result << "], \"summary\": \"" << petLog << "\"},\n"
           // CYS-ATTRIB: the character-power loop. before / after are two full GCDetailAttrib snapshots of MY
           // object, so "the system works" is a number pair (point_remain down, str up ...), never a result code.
           << "  \"attrib\": {\"enabled\": " << (options.attribMode() ? "true" : "false") << ", \"done\": " << (attribDone ? "true" : "false")
           << ", \"phase\": \"" << atName(at) << "\""
           << ", \"attr_point_sent\": " << (options.attrPointSet ? "true" : "false")
           << ", \"attr_point_req\": [" << options.attrStr << ", " << options.attrSpr << ", " << options.attrCon
           << ", " << options.attrInt << ", " << options.attrDex << "]"
           << ", \"manual_attr_results\": " << manualAttrResults << ", \"last_manual_attr_result\": " << lastManualAttrResult
           << ", \"titles_asked\": " << (options.titles ? "true" : "false") << ", \"title_lists\": " << titleLists
           << ", \"title_ids\": " << titleIdCount << ", \"title_strs\": " << titleStrCount
           << ", \"title_list\": \"" << titleListText << "\""
           << ", \"set_title\": " << options.setTitle << ", \"set_id_title\": " << options.setIdTitle
           << ", \"kfs_sent\": " << (options.kfsSet ? "true" : "false") << ", \"kfs_op\": " << options.kfsOp
           << ", \"kfs_refreshes\": " << kfsRefreshes
           << ", \"xiulian_lists\": " << xiulianLists << ", \"xiulian_level_limit\": \"" << xiulianText << "\""
           << ", \"before\": " << attrsPowerBefore.json() << ", \"after\": " << attrsPowerAfter.json()
           << ", \"summary\": \"" << attribLog << "\"},\n"
           << "  \"elapsed_ms\": " << elapsed()
           << ",\n  \"automatic_retries\": 0,\n  \"socket_closed\": true\n}\n";
    table.flush(); result.flush(); log.flush(); core.flush();
    if (!table || !result || !log || !core) throw Failure(2, "report write failed");
    std::cout << "CysNetBot world code=" << code << " charlogin=" << charLogin << " terminal=" << terminalName
              << " quit_flag=" << quitFlag << " heartbeats=" << gameCounters.heartbeats << " moves=" << movesSent
              << " tx=" << gameCounters.txFrames << " rx=" << gameCounters.rxFrames
              << " core: scene=" << world.sceneId() << " chats=" << chatsSent << "/" << chatEchoes << " skills=" << skillsSent
              << " dealt=" << st.damageDealt << " kills=" << kills << " boxes=" << st.itemBoxes << " picks_ok=" << st.picksOk
              << " uses=" << usesSent << "/" << usesOk // CYS-ITEM
              << " bag=" << world.bag().size() << " inv: buys_ok=" << st.buysOk << " equip_ok=" << st.useEquipsOk << " sells_ok=" << st.sellsOk << " drops_ok=" << st.discardsOk << " fixture=" << (fixturePath.empty() ? "-" : fixturePath) << '\n';
    return code;
}
#endif

} // namespace

int main(int argc, char** argv) {
    if (argc == 2 && std::strcmp(argv[1], "--help") == 0) {
        std::cout << "CysNetBot --host IPv4 --port PORT --account test00..test15 --out Build/Logs/NEW-DIRECTORY"
                     " [--timeout-ms 1000..30000]\n"
                     "  (the account allowlist is closed: only this project's own measurement accounts test00..test15,\n"
                     "   characters CYTest00..CYTest15, --guid 200001..200016 - one account per parallel run)\n"
                     "  [--mode world --game-port PORT --guid GUID [--dwell-ms 1000..300000] [--heartbeat-ms 100..60000]"
                     " [--walk 0|1] [--fly X,Z[,SKILL]]]\n"
                     "  core loop (world): [--goto X,Z] [--chat 0|1] [--chat-text TEXT] [--attack N] [--skill ID]"
                     " [--select-ride ID] [--ride FLAG]"
                     " [--hunt X,Z] [--pickup 0|1] [--bag 0|1] [--record 0|1]\n"
                     "  inventory (world): [--goto-scene ID] [--npc X,Z] [--buy SHOP,ITEM[,COUNT]] [--equip SLOT]"
                     " [--unequip SLOT] [--sell 0|1] [--drop 0|1] [--swap 0|1] [--use ITEM[,COUNT 1..5]]\n"
                     "      --use sends CGUseItem on the bag slot holding ITEM (a slot filled by --buy first) and\n"
                     "      reports GCUseItemResult plus hp/mp and the stack size around it. A health potion is\n"
                     "      refused at full health by its own script (30001001 -> OR_HEALTH_IS_FULL), so lower the\n"
                     "      hp before the session. --equip / --unequip now re-ask CGAskDetailAttrib and record the\n"
                     "      att/def/hit/miss before and after, so the equipment change is a number.\n"
                     "  skills (world): [--hotbar 1|2] [--xinfa 1|2] [--cast SKILL,TARGET | --cast-seq \"A,TA;B,TB\"]\n"
                     "      --cast TARGET: OBJID = that object, 0 = nearest live monster, -1 or self = the bot itself,\n"
                     "                     pos = the bot's own position, pos:DX,DZ = own position + that offset (-64..64)\n"
                     "      (self is the only measurable target for ally-only skills: 3557, 3558, 3432, 4624;\n"
                     "       pos is the only way to aim a ground skill: targeting_logic 7, e.g. 4468, 841/844/847)\n"
                     "      --cast-seq: 2..6 \"SKILL,TARGET\" steps separated by ';', cast once each in ONE session,\n"
                     "       in order; the LAST step is the measured one (it also gets the re-cast and the cast loop).\n"
                     "       Use it when a skill needs a state an earlier skill installs, e.g. --cast-seq \"434,-1;841,0\"\n"
                     "  script (world): [--exec SCRIPT,FUNC[,P1..P8]] (repeatable; CGExecuteScript before chat)\n"
                     "  npc/quest (world): [--talk X,Z] [--quest accept|complete|full] [--quest-script ID] [--talk-option INDEX] [--talk-confirm INDEX] [--talk-scene ID]\n"
                     "  team (world): [--team-invite NAME | --team-apply NAME] [--team-accept 0|1] [--team-info 0|1]\n"
                     "      [--team-exp-mode 0|1] [--team-chat TEXT] [--tell NAME --tell-text TEXT]\n"
                     "      [--team-appoint 0|1] [--team-kick 0|1] (both target the first roster entry that is not me)\n"
                     "      [--team-leave 0|1] [--team-dismiss 0|1] [--team-at-ms N] [--team-wait-ms N] [--hold-ms N] [--stay-dead 0|1]\n"
                     "      Two processes: the inviter gets --team-invite NAME --team-at-ms N, the other --team-accept 1.\n"
                     "      result.json -> team.member_list is the decoded GCTeamList roster; team.exp_gained sums GCDetailExp.\n"
                     "  pet (world): [--pet 1|2] [--pet-capture 0|1] [--pet-fight-ms 0..60000]\n"
                     "      --pet 1 lists the pet bag (CGAskDetailAttrib makes the server send one GCDetailAttrib_Pet\n"
                     "      per pet), --pet 2 also summons the first usable pet (CGManipulatePet type 0), keeps it out\n"
                     "      for --pet-fight-ms and puts it away again (type 1). --pet-capture 1 casts skill template 1\n"
                     "      捕兽 at the nearest wild pet object first; that skill gathers for 15 s, so the answer\n"
                     "      (GCManipulatePetRet ret 1 = captured, 0 = failed) lands about 15 s after the cast.\n"
                     "      A wild pet only exists where petdropper.lua (script 501000) killed a pet monster, so the\n"
                     "      scene must be one that actually places those monsters.\n"
                     "  attrib (world): [--attr-point S,SP,C,I,D] [--titles 0|1] [--set-title ID] [--set-id-title ID]\n"
                     "                  [--kfs OP[,A1,A2,A3]]\n"
                     "      --attr-point spends unspent potential points (CGReqManualAttr 598). The phase snapshots\n"
                     "      GCDetailAttrib before and after, so result.json -> attrib.before/after carry point_remain,\n"
                     "      str/spr/con/int/dex, the eleven 修炼 fields and mind_attack/defend; attrib.last_manual_attr_result\n"
                     "      is the GCManualAttrResult code (0 = success, 1 = not enough remaining points).\n"
                     "      --titles 1 lists my titles (CGCharAllTitles 1230 -> GCCharAllTitles 1227). A title is worn\n"
                     "      with CGCharUpdateCurTitle 1192, and the packet has TWO branches: --set-title ID picks a\n"
                     "      string title out of human.titles, --set-id-title ID picks a CharTitleNew row out of\n"
                     "      human.id_titles - only the second kind carries the IA/IV attribute pairs that\n"
                     "      human_attrib:title_new_effect_flush applies. --kfs sends CGKfsOperate 908 (script 809270).\n"
                     "      attrib.xiulian_lists / xiulian_level_limit decode GCDetailXiulianList 1014 (11 books,\n"
                     "      level/limit each), which the server pushes whenever a 修炼 level changes.\n"
                     "Password: CYS_BOT_PWD environment only. No retry or character creation. World mode ends with CGAskQuit.\n";
        return 0;
    }
    try {
        const auto options = Parse(argc, argv);
#if defined(CYS_NETBOT_WORLD)
        if (options.world) return RunWorld(options, OutputDirectory(options.out));
#endif
        return Run(options, OutputDirectory(options.out));
    } catch (const Failure& failure) {
        std::cerr << "CysNetBot setup failed: " << failure.what() << '\n';
        return failure.code;
    } catch (...) {
        std::cerr << "CysNetBot stopped: internal failure (details suppressed)\n";
        return 10;
    }
}
