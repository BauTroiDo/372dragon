#include "LoginClient.h"
#include "PgFactory.h"
#include "PgPackets_login.h"
#include <chrono>
#include <cstdio>
#include <fcntl.h>
#include <io.h>
#include <stdexcept>
#include <thread>
#include <vector>

using namespace cys::net;
using Clock = std::chrono::steady_clock;
static void check(bool value, const char* message) { if (!value) throw std::runtime_error(message); }
static CreateCharacterRequest request() {
    CreateCharacterRequest r; r.nickname = u8"Việt中文";
    r.model=1; r.faceStyle=100; r.hairStyle=5; r.portraitId=22; r.newPlayerSet=2;
    return r;
}
static void fixture(const std::string& kind) {
    pg::LCRetCharList list;
    unsigned n = kind == "duplicate" || kind == "changed" ? 2U : static_cast<unsigned>(std::stoul(kind));
    check(n<=4,"fixture bound"); list.charnum=static_cast<uint8_t>(n);
    for(unsigned i=0;i<n;++i) {
        pg::LCRetCharList::E_charlist role;
        role.guid=200001+i; role.sex=1; role.level=1; role.set_nickname(u8"Việt中文");
        role.hair=5; role.head=100; role.portrait_id=22; role.new_player_set=2;
        if(kind=="duplicate") role.guid=200001;
        if(kind=="changed") role.guid+=10;
        list.charlist.push_back(role);
    }
    std::vector<uint8_t> bytes; check(pg::encodeFrame(list,0,bytes),"encode fixture");
    _setmode(_fileno(stdout),_O_BINARY);
    check(std::fwrite(bytes.data(),1,bytes.size(),stdout)==bytes.size(),"fixture output");
}
static void unit() {
    LoginClient client;
    check(!client.canRequestCreatePermission() && !client.canCreateCharacter(),"inactive readiness");
    check(!client.requestCreatePermission() && client.lastCommandError()==ErrorCode::NotReady,"inactive permission");
    check(!client.createCharacter(request()) && client.lastCommandError()==ErrorCode::NotReady,"inactive create");
    unsigned invalid=0;
    for(const std::string& name : std::vector<std::string>{"",std::string(30,'x'),std::string("a\0b",3),"a#b","a*b"," a","a ",std::string("\xc0\x80",2),std::string("\xed\xa0\x80",3),std::string("\xf4\x90\x80\x80",4),std::string("\xe4\xb8",2)}) {
        auto r=request(); r.nickname=name;
        check(!client.createCharacter(r) && client.lastCommandError()==ErrorCode::InvalidInput,"invalid nickname rejected");++invalid;
    }
    auto r=request(); r.nickname=std::string(29,'x');
    check(!client.createCharacter(r) && client.lastCommandError()==ErrorCode::NotReady,"29 bytes validate without truncation");
    r=request();r.faceStyle=-1;
    check(!client.createCharacter(r) && client.lastCommandError()==ErrorCode::InvalidInput,"negative asset rejected");
    bool wrong=false;
    std::thread other([&] { wrong=!client.requestCreatePermission() && !client.createCharacter(request()) &&
        !client.canCreateCharacter() && !client.canRequestCreatePermission() && client.lastCommandError()==ErrorCode::WrongThread; });
    other.join(); check(wrong,"command owner required");
    std::printf("UNIT invalid_names=%u owner=1 inactive=1 utf8_bounds=1 PASS\n",invalid);
}
static void run(uint16_t port,const std::string& scenario) {
    std::unique_ptr<LoginClient> client(new LoginClient);
    Options options; options.mode=SessionMode::Interactive;
    options.connectTimeoutMs=1000;options.replyTimeoutMs=250;options.idleTimeoutMs=400;options.overallTimeoutMs=4000;
    const auto owner=std::this_thread::get_id();
    check(client->start(Endpoint{"127.0.0.1",port},"unit-create","unit-value",options),"start accepted");
    check(!client->canRequestCreatePermission() && !client->canCreateCharacter(),"unreceived list cannot enable commands");
    if(scenario=="pause-pump") {
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
        check(client->active() && !client->canRequestCreatePermission() && !client->canCreateCharacter(),"worker cannot enable main readiness");
    }
    std::vector<Event> events; unsigned lists=0, permissions=0, results=0;
    bool done=false,destroyed=false;
    auto cancelAt=Clock::time_point::max();
    const auto end=Clock::now()+std::chrono::seconds(6);
    while(!done && Clock::now()<end) {
        client->pump([&](Event&& event) {
            check(owner==std::this_thread::get_id(),"owner callback");
            check(client->pump([](Event&&){})==0,"no nested pump");
            if(event.type==EventType::CharacterList) {
                ++lists;
                check(event.packet && event.packet->packetId()==319 && !event.counters.socketClosed,"owned interactive list has open socket");
                const auto& list=static_cast<const pg::LCRetCharList&>(*event.packet);
                if(lists==1) {
                    if(scenario=="full-list") {
                        check(list.charlist.size()==3 && !client->canRequestCreatePermission() && !client->canCreateCharacter(),"full list disables creation");client->cancel();
                    } else if(scenario=="cancel-ready") client->cancel();
                    else if(scenario=="destroy-ready") { client.reset();destroyed=true;done=true; }
                    else if(scenario!="idle" && scenario!="unsolicited") {
                        check(client->canRequestCreatePermission() && !client->canCreateCharacter(),"permission gate precedes create");
                        check(client->requestCreatePermission(),"permission admission");
                        check(!client->requestCreatePermission() && !client->createCharacter(request()),"single slot excludes duplicate and premature create");
                    }
                } else {
                    check(!list.charlist.empty() && list.charlist[0].nickname_text()==u8"Việt中文","owned UTF8 role fields");
                    client->cancel();
                }
            } else if(event.type==EventType::CreatePermission) {
                ++permissions; check(event.packet && event.packet->packetId()==777,"owned permission");
                if(event.permissionFlag==0) {
                    check(!client->canCreateCharacter(),"denied gate stays closed");
                    if(scenario=="command-cap" && permissions<16) check(client->requestCreatePermission(),"explicit permission command");
                    else {
                        if(scenario=="command-cap") check(!client->requestCreatePermission() && client->lastCommandError()==ErrorCode::Limit,"session command cap");
                        client->cancel();
                    }
                }
                else {
                    check(event.permissionFlag==1 && client->canCreateCharacter(),"pumped permission enables create");
                    check(client->createCharacter(request()),"create admission");
                    check(!client->canCreateCharacter() && !client->requestCreatePermission() && !client->createCharacter(request()),"pending create rejects every duplicate");
                    if(scenario=="cancel-create") client->cancel();
                    if(scenario=="cancel-inflight") cancelAt=Clock::now()+std::chrono::milliseconds(75);
                }
            } else if(event.type==EventType::CharacterCreated) {
                ++results; check(event.packet && event.packet->packetId()==440,"owned create result");
                if(event.createResult!=0) {
                    check(client->canCreateCharacter(),"refused request can be corrected explicitly");
                    if(scenario=="manual-retry" && results==1) check(client->createCharacter(request()),"explicit corrected submission");
                    else client->cancel();
                } else check(!client->canCreateCharacter(),"success waits for pushed list before readiness");
            } else if(event.type==EventType::Cancelled || event.type==EventType::Error || event.type==EventType::Refused) done=true;
            events.push_back(std::move(event));
        },1);
        if(!done && Clock::now()>=cancelAt) { client->cancel();cancelAt=Clock::time_point::max(); }
        if(!done) std::this_thread::sleep_for(std::chrono::milliseconds(1));
    }
    check(done,"bounded terminal event");
    if(destroyed) { std::printf("SESSION destroy_callback=1 PASS\n");return; }
    const auto& last=events.back();check(last.counters.socketClosed,"terminal closes socket");
    check(!client->canRequestCreatePermission() && !client->canCreateCharacter(),"terminal readiness false");
    const bool success=scenario=="success" || scenario=="split" || scenario=="pause-pump" || scenario=="manual-retry" || scenario=="existing";
    if(success) {
        check(lists==2 && permissions==1 && results==(scenario=="manual-retry"?2U:1U),"ordered result and refreshed list");
        check(last.type==EventType::Cancelled && last.counters.txFrames==(scenario=="manual-retry"?6U:5U),"no redundant charlist or automatic auth");
        const Event* saved=nullptr;for(const auto& event:events) if(event.type==EventType::CharacterList && !static_cast<const pg::LCRetCharList&>(*event.packet).charlist.empty()) saved=&event;
        check(saved && static_cast<const pg::LCRetCharList&>(*saved->packet).charlist[0].guid==200001,"role object survives all later callbacks and cancel");
    } else if(scenario=="deny" || scenario=="refuse" || scenario=="full-list" || scenario=="cancel-ready" || scenario=="cancel-create" || scenario=="cancel-inflight" || scenario=="command-cap") {
        check(last.type==EventType::Cancelled,"deliberate cancel terminal");
        if(scenario=="cancel-inflight") check(last.counters.txFrames==5,"cancel closes an already transmitted create");
        if(scenario=="command-cap") check(last.counters.txFrames==19 && permissions==16,"bounded commands share sequencer");
    } else {
        ErrorCode expected=ErrorCode::UnexpectedPacket;
        if(scenario=="idle" || scenario=="timeout" || scenario=="missing-list" || scenario=="permission-timeout" || scenario=="trickle") expected=ErrorCode::Timeout;
        if(scenario=="short-result") expected=ErrorCode::Decode;
        if(scenario=="peer-close") expected=ErrorCode::PeerClosed;
        check(last.type==EventType::Error && last.error==expected,"bad response fails explicitly");
    }
    std::printf("SESSION lists=%u permissions=%u results=%u tx=%u rx=%u next=%u closed=1 PASS\n",lists,permissions,results,last.counters.txFrames,last.counters.rxFrames,last.counters.nextTxIndex);
}
int main(int argc,char** argv) {
    try {
        if(argc==1) unit();
        else if(argc==3 && std::string(argv[1])=="--fixture") fixture(argv[2]);
        else if(argc==4 && std::string(argv[1])=="--loopback") { const unsigned p=static_cast<unsigned>(std::stoul(argv[2]));check(p>0 && p<=65535,"port");run(static_cast<uint16_t>(p),argv[3]); }
        else return 3;
        return 0;
    } catch(...) { std::fprintf(stderr,"FAIL creation session test (fixed diagnostic)\n");return 2; }
}
