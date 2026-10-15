#ifndef _GCWORLDTIME_H_
#define _GCWORLDTIME_H_


#include "Type.h"
#include "Packet.h"
#include "PacketFactory.h"


namespace Packets
{
	class GCWorldTime:public Packet
	{
	public:
		GCWorldTime() : m_Counter(0), m_Interval(0.0f) {};
		virtual ~GCWorldTime(){};

		//公用继承接口
		virtual BOOL			Read( SocketInputStream& iStream ) ;
		virtual BOOL			Write( SocketOutputStream& oStream ) const ;
		virtual UINT			Execute( Player* pPlayer ) ;


		virtual PacketID_t		GetPacketID() const { return PACKET_GC_WORLDTIME ; }

		virtual UINT			GetPacketSize()const { return sizeof(UINT) + sizeof(INT) + sizeof(FLOAT);}	// CYS-SKY: 12 bytes

	public:
		WORLD_TIME				GetWorldTime()
		{
			return m_Time;
		}
		VOID					SetWorldTime(WORLD_TIME WtTime)
		{
			m_Time = WtTime;
		}

		// CYS-SKY: ms of the day and the game-ms per real-ms rate (CY 3.71 GCWorldTime +0x1c / +0x20)
		INT						GetCounter() const { return m_Counter; }
		VOID					SetCounter(INT counter) { m_Counter = counter; }
		FLOAT					GetInterval() const { return m_Interval; }
		VOID					SetInterval(FLOAT interval) { m_Interval = interval; }

		SceneID_t				GetSceneID()
		{
			return m_SceneID;
		}
		VOID					SetSceneID(SceneID_t SceneID)
		{
			m_SceneID = SceneID;
		}
	private:
		WORLD_TIME				m_Time;
		SceneID_t				m_SceneID;
		INT						m_Counter;		// CYS-SKY
		FLOAT					m_Interval;		// CYS-SKY
	};

	class GCWorldTimeFactory: public	PacketFactory
	{
	public:
		Packet*		CreatePacket() { return new GCWorldTime() ; }
		PacketID_t	GetPacketID()const			{ return PACKET_GC_WORLDTIME ; }
		UINT		GetPacketMaxSize()const		{ return	sizeof(UINT) + sizeof(INT) + sizeof(FLOAT);}	// CYS-SKY			
	};

	class GCWorldTimeHandler
	{
	public:
		static UINT Execute(GCWorldTime* pPacket,Player* pPlayer);
	};

};

using namespace Packets;


#endif