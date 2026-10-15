#include "StdAfx.h"
#include "GCWorldTime.h"
#include "../../Procedure/CysWorldTime.h"

uint GCWorldTimeHandler::Execute( GCWorldTime* pPacket, Player* pPlayer )
{
__ENTER_FUNCTION

	// CYS-SKY: CY 3.71 GCWorldTime handler FUN_1405420a0 drives the sky clock (Procedure/CysWorldTime.h)
	CysWorldTime::OnPacket(static_cast<unsigned>(pPacket->GetWorldTime()), pPacket->GetCounter(), pPacket->GetInterval());
	return PACKET_EXE_CONTINUE ;

__LEAVE_FUNCTION

	return PACKET_EXE_ERROR ;
}
