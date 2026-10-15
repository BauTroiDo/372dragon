#include "StdAfx.h"
#include "GCPlayerShopType.h"
#include "..\..\Procedure\GameProcedure.h"
#include "..\..\DataPool\GMDataPool.h"
#include "..\..\Event\GMEventSystem.h"
#include "..\..\Object\Item\Obj_Item.h"
#include "..\..\Action\GMActionSystem.h"
#include "TDException.h"

UINT GCPlayerShopTypeHandler::Execute( GCPlayerShopType* pPacket, Player* pPlayer )
{
	__ENTER_FUNCTION

		if(CGameProcedure::GetActiveProcedure() == (CGameProcedure*)CGameProcedure::s_pProcMain)
		{
			_PLAYERSHOP_GUID	nShopID	=	pPacket->GetShopID();		//商店ID
			BYTE	nType	=	pPacket->GetType();						//存到哪

			CDataPool::GetMe()->PlayerShop_SetShopSubType(TRUE, nType);
		
		}

		
		return PACKET_EXE_CONTINUE ;

	__LEAVE_FUNCTION

		return PACKET_EXE_ERROR ;
}
