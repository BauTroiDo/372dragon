#pragma once
namespace pg { class Packet; }
namespace CysAllianceNet { void Reset(); void RegisterHost(); bool IsWorldPacket(unsigned short); bool Dispatch(const pg::Packet&); int MyLeagueId(); void OnMembership(int id); }
