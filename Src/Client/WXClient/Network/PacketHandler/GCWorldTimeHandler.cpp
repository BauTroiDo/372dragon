#include "StdAfx.h"
#include "GCWorldTime.h"
#include "../../Procedure/CysWorldTime.h"

uint GCWorldTimeHandler::Execute( GCWorldTime* pPacket, Player* pPlayer )
{
__ENTER_FUNCTION


	CysWorldTime::OnPacket(static_cast<unsigned>(pPacket->GetWorldTime()), pPacket->GetCounter(), pPacket->GetInterval());
	return PACKET_EXE_CONTINUE ;

__LEAVE_FUNCTION

	return PACKET_EXE_ERROR ;
}
