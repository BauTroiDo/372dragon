#include "LoginClient.h"
#include "LoginProbe.h"
#include "PgPackets_login.h"
#include <algorithm>
#include <chrono>
#include <cstdio>
#include <fstream>
#include <iterator>
#include <random>
#include <stdexcept>
#include <thread>

using namespace cys::net;
using Clock = std::chrono::steady_clock;
static unsigned checks = 0;
static void check(bool value, const char* name) {
    if (!value) throw std::runtime_error(name);
    ++checks;
    std::printf("PASS %s\n", name);
}
static std::vector<uint8_t> wire(const pg::Packet& packet, uint16_t index=0) {
    std::vector<uint8_t> bytes;
    if (!pg::encodeFrame(packet, index, bytes)) throw std::runtime_error("encode fixture");
    return bytes;
}

static void unit() {
    cysbot::TxSequencer sequence;
    check(sequence.next() == 0x7b00, "sequence starts at 0x7b00");
    for (unsigned i=0; i<133; ++i) sequence.admitted();
    check(sequence.next() == 0, "sequence wraps only on admission");
    pg::LCRetConnect reply;
    const auto data = wire(reply);
    bool everySplit = true;
    for (size_t split=0; split<=data.size(); ++split) {
        cysbot::FrameAssembler assembler;
        std::vector<cysbot::Frame> frames;
        everySplit = everySplit && assembler.feed(data.data(), split, frames) &&
            assembler.feed(data.data()+split, data.size()-split, frames) &&
            frames.size()==1 && !assembler.pending() && cysbot::DecodeInbound(frames[0]).packet != nullptr;
    }
    check(everySplit, "all header/body split points strictly assemble");
    cysbot::FrameAssembler assembler;
    std::vector<cysbot::Frame> frames;
    auto joined=data; joined.insert(joined.end(),data.begin(),data.end());
    check(assembler.feed(joined.data(),joined.size(),frames) && frames.size()==2 && !assembler.pending(),
        "coalesced frames stay distinct owned bodies");
    frames[0].body.push_back(0);
    auto decoded=cysbot::DecodeInbound(frames[0]);
    check(!decoded.packet && decoded.proto==pg::Proto::Login, "known Login decode error never falls back");
    auto game=pg::createPacket(pg::Proto::Game,397);
    auto gameWire=wire(*game);
    cysbot::FrameAssembler other;
    std::vector<cysbot::Frame> gameFrames;
    other.feed(gameWire.data(),gameWire.size(),gameFrames);
    auto fallback=cysbot::DecodeInbound(gameFrames[0]);
    check(fallback.packet && fallback.proto==pg::Proto::Game, "unknown Login id falls back to Game table");
    pg::CLConnect outgoing;
    auto outgoingWire=wire(outgoing);
    cysbot::FrameAssembler wrong;
    std::vector<cysbot::Frame> wrongFrames;
    wrong.feed(outgoingWire.data(),outgoingWire.size(),wrongFrames);
    check(!cysbot::DecodeInbound(wrongFrames[0]).packet, "inbound client direction rejected");
    cysbot::FrameAssembler capped;
    std::vector<cysbot::Frame> empty;
    check(!capped.feed(data.data(),65537,empty), "receive input cap precedes memory read");
    cysbot::FrameAssembler many;
    std::vector<uint8_t> tiny(129*6);
    check(!many.feed(tiny.data(),tiny.size(),empty), "per-feed frame cap enforced");

    LoginClient client;
    check(!client.start(Endpoint{"192.0.2.1",12345},"unit-async","unit-value") &&
        client.lastStartError()==ErrorCode::InvalidInput, "non-loopback endpoint rejected before networking");
    check(!client.start(Endpoint{"localhost",12345},"unit-async","unit-value"), "DNS endpoint rejected");
    check(!client.start(Endpoint{"127.0.0.1",12345},"unit_async","unit-value"), "account sanitization mismatch rejected");
    check(!client.start(Endpoint{"127.0.0.1",12345},"unit-async","bad%separator"), "credential separator rejected");
    check(!client.start(Endpoint{"127.0.0.1",12345},"unit-async",std::string(49,'x')), "wire credential truncation rejected");
    Options invalid; invalid.replyTimeoutMs=0;
    check(!client.start(Endpoint{"127.0.0.1",12345},"unit-async","unit-value",invalid), "invalid deadline rejected");
    bool wrongStart=false, wrongPump=false, wrongCancel=false;
    std::thread alien([&]() {
        wrongStart=!client.start(Endpoint{},"unit-async","unit-value") && client.lastStartError()==ErrorCode::WrongThread;
        try { client.pump([](Event&&){}); } catch(const std::logic_error&) { wrongPump=true; }
        try { client.cancel(); } catch(const std::logic_error&) { wrongCancel=true; }
    });
    alien.join();
    check(wrongStart && wrongPump && wrongCancel, "start pump cancel enforce main thread ownership");
    check(client.pump([](Event&&){})==0 && !client.active(), "invalid starts create no worker event");

    std::mt19937 random(0x20260913);
    size_t accepted=0;
    for (unsigned i=0; i<100000; ++i) {
        auto input=data;
        switch(i%4) {
        case 0: input.resize(random()%(input.size()+1)); break;
        case 1: input[random()%input.size()]=static_cast<uint8_t>(random()); break;
        case 2: input.resize(random()%257); for(auto& b:input) b=static_cast<uint8_t>(random()); break;
        default: input.insert(input.end(),data.begin(),data.end()); break;
        }
        cysbot::FrameAssembler fuzz;
        std::vector<cysbot::Frame> out;
        bool ok=true;
        for(size_t pos=0; pos<input.size() && ok;) {
            const size_t n=(std::min)(input.size()-pos,size_t(1+random()%31));
            ok=fuzz.feed(input.data()+pos,n,out); pos+=n;
        }
        if(fuzz.pending()>65541) throw std::runtime_error("fuzz pending cap");
        for(auto& frame:out) if(cysbot::DecodeInbound(frame).packet) ++accepted;
    }
    std::printf("FUZZ inputs=100000 accepted_frames=%zu\n",accepted);
    check(true,"100000 fragmented mutated framing/strict decode inputs survive");
}

static uint32_t little(const uint8_t* p,unsigned size) {
    uint32_t value=0; for(unsigned i=0;i<size;++i) value|=uint32_t(p[i])<<(8*i); return value;
}
static void replay(const char* path) {
    std::ifstream input(path,std::ios::binary);
    char magic[8]{}; input.read(magic,8);
    if(!input || std::string(magic,8)!="PGFRAME1") throw std::runtime_error("capture format");
    std::mt19937 random(0x1699);
    struct Record { pg::Proto proto; std::vector<uint8_t> wire; };
    std::vector<Record> records;
    std::vector<uint8_t> stream;
    size_t count=0;
    for (;;) {
        uint8_t record[10]{}; input.read(reinterpret_cast<char*>(record),10);
        if(input.gcount()==0) break;
        if(input.gcount()!=10) throw std::runtime_error("partial capture record");
        const auto proto=record[0]?pg::Proto::Login:pg::Proto::Game;
        const uint16_t id=static_cast<uint16_t>(little(record+2,2)), index=static_cast<uint16_t>(little(record+4,2));
        const size_t size=little(record+6,4);
        if(size>65535) throw std::runtime_error("capture body cap");
        std::vector<uint8_t> bytes(6+size);
        bytes[0]=uint8_t(id); bytes[1]=uint8_t(id>>8); bytes[2]=uint8_t(size); bytes[3]=uint8_t(size>>8);
        bytes[4]=uint8_t(index); bytes[5]=uint8_t(index>>8);
        input.read(reinterpret_cast<char*>(bytes.data()+6),size);
        if(static_cast<size_t>(input.gcount())!=size) throw std::runtime_error("partial capture body");
        stream.insert(stream.end(),bytes.begin(),bytes.end());
        records.push_back(Record{proto,std::move(bytes)});
    }
    cysbot::FrameAssembler assembler;
    size_t coalescedFeeds=0;
    for(size_t pos=0;pos<stream.size();) {
        const size_t n=(std::min)(stream.size()-pos,size_t(1+random()%512));
        std::vector<cysbot::Frame> frames;
        if(!assembler.feed(stream.data()+pos,n,frames)) throw std::runtime_error("capture assembly failed");
        pos+=n;
        if(frames.size()>1) ++coalescedFeeds;
        for(auto& frame:frames) {
            if(count>=records.size()) throw std::runtime_error("capture produced extra frame");
            Record& record=records[count];
            pg::DecodeResult result;
            auto packet=pg::decodePacket(record.proto,frame.header.id,frame.body.data(),frame.body.size(),&result,true);
            if(!packet) throw std::runtime_error("capture strict decode failed");
            auto encoded=wire(*packet,frame.header.idx);
            if(encoded!=record.wire) throw std::runtime_error("capture roundtrip differs");
            if(packet->packetProto()==pg::Proto::Login && packet->packetId()==pg::CLAskLogin::PACKET_ID) {
                auto& login=static_cast<pg::CLAskLogin&>(*packet);
                cysbot::Wipe(login.account.data(),login.account.size());
                cysbot::Wipe(&login.encrypted_data[0],login.encrypted_data.size());
            }
            cysbot::Wipe(encoded.data(),encoded.size());
            cysbot::Wipe(record.wire.data(),record.wire.size());
            cysbot::Wipe(frame.body.data(),frame.body.size());
            ++count;
        }
    }
    cysbot::Wipe(stream.data(),stream.size());
    if(assembler.pending() || count!=records.size() || !coalescedFeeds)
        throw std::runtime_error("capture framing residue or missing coalesced feeds");
    std::printf("REPLAY coalesced_feeds=%zu pending=0\n",coalescedFeeds);
    std::printf("REPLAY frames=%zu raw_output=0\n",count);
    check(count==1699,"1699 capture frames replay fragmented strict and byte-identical");
}

static void loopback(uint16_t port,const std::string& scenario) {
    std::unique_ptr<LoginClient> client(new LoginClient);
    Options options; options.replyTimeoutMs=300; options.connectTimeoutMs=1000; options.overallTimeoutMs=3000;
    const auto owner=std::this_thread::get_id();
    std::vector<Event> events;
    const auto started=Clock::now();
    check(client->start(Endpoint{"127.0.0.1",port},"unit-async","unit-value",options),"async start accepted");
    check(Clock::now()-started<std::chrono::milliseconds(100),"start does not wait for a network reply");
    check(!client->start(Endpoint{"127.0.0.1",port},"unit-async","unit-value",options) &&
        client->lastStartError()==ErrorCode::Busy,"duplicate start creates no second connection");
    if(scenario=="pause-pump" || scenario=="cancel-queued") {
        while(client->active() && Clock::now()-started<std::chrono::seconds(4)) std::this_thread::sleep_for(std::chrono::milliseconds(1));
        check(events.empty(),"worker never invokes a UI callback");
        if(scenario=="cancel-queued") {
            client->cancel();
            check(client->pump([&](Event&& e){events.push_back(std::move(e));})==0,"cancel suppresses undelivered terminal UI event");
            return;
        }
    }
    bool done=false, cancelled=false, destroyed=false;
    while(!done && Clock::now()-started<std::chrono::seconds(5)) {
        const size_t delivered=client->pump([&](Event&& e) {
            if(std::this_thread::get_id()!=owner) throw std::runtime_error("callback wrong thread");
            if(client->pump([](Event&&){})!=0) throw std::runtime_error("reentrant pump dispatched");
            if(e.type==EventType::Connected && (scenario=="cancel" || scenario=="destroy-callback")) {
                const auto before=Clock::now();
                if(scenario=="cancel") { client->cancel(); cancelled=true; }
                else { client.reset(); destroyed=true; done=true; }
                if(Clock::now()-before>std::chrono::milliseconds(200)) throw std::runtime_error("cancel/destructor blocked on network deadline");
            }
            if(e.type==EventType::CharacterList || e.type==EventType::Refused ||
               e.type==EventType::Error || e.type==EventType::Cancelled) done=true;
            events.push_back(std::move(e));
        },1);
        if(delivered>1) throw std::runtime_error("pump max exceeded");
        if(!done) std::this_thread::sleep_for(std::chrono::milliseconds(1));
    }
    check(done,"terminal event delivered on main thread");
    if(destroyed) { check(true,"client can be destroyed inside its callback safely"); return; }
    const Event& last=events.back();
    check(last.counters.socketClosed,"terminal event follows clean socket close");
    check(client->pump([](Event&&){})==0,"no duplicate terminal event");
    if(scenario=="cancel") check(cancelled && last.type==EventType::Cancelled,"cancel closes promptly with one terminal event");
    else if(scenario=="success" || scenario=="pause-pump") {
        check(events.size()==3 && events[0].type==EventType::Connected && events[1].type==EventType::Authenticated &&
            last.type==EventType::CharacterList,"owned connected auth charlist events stay ordered");
        check(last.packet && static_cast<const pg::LCRetCharList&>(*last.packet).charlist.empty(),"owned charlist survives receive buffer lifetime");
        check(last.counters.txFrames==3 && last.counters.rxFrames==4 && last.counters.nextTxIndex==0x7e00 &&
            !last.counters.decodeFailures && !last.counters.pendingBytes,"three transmissions preserve sequence continuity and no residue");
    } else if(scenario=="wrong-password" || scenario=="online" || scenario=="wait") {
        const int flag=scenario=="wrong-password"?1:scenario=="online"?8:21;
        check(last.type==EventType::Refused && last.loginFlag==flag && last.packet,"refusal remains typed and owned");
        check(last.counters.txFrames==2,"refusal sends no character-list or credential retry");
        if(flag!=1) check(last.retryAfterSeconds==(flag==8?20U:26U),"retryable flag reports minimum backoff without retry");
    } else {
        ErrorCode expected=ErrorCode::Decode;
        if(scenario=="timeout" || scenario=="trickle") expected=ErrorCode::Timeout;
        else if(scenario=="peer-close") expected=ErrorCode::PeerClosed;
        else if(scenario=="status-flood") expected=ErrorCode::Limit;
        else if(scenario=="game-refusal" || scenario=="list-refused" || scenario=="trailing-frame") expected=ErrorCode::UnexpectedPacket;
        check(last.type==EventType::Error && last.error==expected,"protocol timeout or limit failure is explicit");
    }
    std::printf("SESSION events=%zu tx=%u rx=%u decode_failures=%u closed=1\n",
        events.size(),last.counters.txFrames,last.counters.rxFrames,last.counters.decodeFailures);
}

int main(int argc,char** argv) {
    try {
        if(argc==1) unit();
        else if(argc==3 && std::string(argv[1])=="--replay") replay(argv[2]);
        else if(argc==4 && std::string(argv[1])=="--loopback") {
            const unsigned port=static_cast<unsigned>(std::stoul(argv[2]));
            if(!port || port>65535) return 3;
            loopback(static_cast<uint16_t>(port),argv[3]);
        } else return 3;
        std::printf("RESULT checks=%u status=PASS\n",checks); return 0;
    } catch(const std::exception& e) {
        std::fprintf(stderr,"FAIL %s\n",e.what()); return 2;
    }
}
