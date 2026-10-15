#include "stdafx.h"
#include "GCWorldTime.h"


BOOL	GCWorldTime::Read(SocketInputStream& iStream )
{
	__ENTER_FUNCTION

		// CYS-SKY: CY 3.71 wire (Read 14086a940, skynet GCWorldTime.bos): u32 WorldTime, i32 counter (ms of day), f32 interval
		iStream.Read((CHAR*)(&m_Time),sizeof(UINT));
		iStream.Read((CHAR*)(&m_Counter),sizeof(INT));
		iStream.Read((CHAR*)(&m_Interval),sizeof(FLOAT));
		return TRUE;

	__LEAVE_FUNCTION

		return FALSE;
}

BOOL	GCWorldTime::Write(SocketOutputStream& oStream )	const
{
	__ENTER_FUNCTION
		
		oStream.Write((CHAR*)(&m_Time),sizeof(UINT));
		oStream.Write((CHAR*)(&m_Counter),sizeof(INT));
		oStream.Write((CHAR*)(&m_Interval),sizeof(FLOAT));
		return TRUE;

	__LEAVE_FUNCTION

		return FALSE;
}

UINT GCWorldTime::Execute( Player* pPlayer )
{
	__ENTER_FUNCTION

		return GCWorldTimeHandler::Execute( this, pPlayer ) ;

	__LEAVE_FUNCTION

		return FALSE ;
}