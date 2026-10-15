#pragma once
namespace pg { class Packet; }
namespace CysGuildWarNet {void Reset();void RegisterHost();bool IsWorldPacket(unsigned short);bool Dispatch(const pg::Packet&);}
