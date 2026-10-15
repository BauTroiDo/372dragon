
#include "StdAfx.h"
#include "GCPlayerShopEstablish.h"
#include "..\..\Procedure\GameProcedure.h"
#include "..\..\DataPool\GMDataPool.h"
#include "..\..\Event\GMEventSystem.h"

UINT GCPlayerShopEstablishHandler::Execute( GCPlayerShopEstablish* pPacket, Player* pPlayer )
{
	__ENTER_FUNCTION
		if(CGameProcedure::GetActiveProcedure() == (CGameProcedure*)CGameProcedure::s_pProcMain)
		{
			CHAR resultMsg[256] = {0};
			// CYS-WARNSWEEP 19/09 (C4474 "too many arguments", chi thay o /W3): chuoi dinh dang
			// KHONG co %s nen ten cua hang bi vut im lang tu 2026-09-12. Da kiem: chuoi nay khong
			// lam khoa cho bang dich nao trong Assets/ hay Tools/, nen them %s dung cho ten vao.
			_snprintf(resultMsg, 256, "开张大吉，你的店铺 %s 成功创建了。", pPacket->GetShopName());
			CEventSystem::GetMe()->PushEvent(GE_NEW_DEBUGMESSAGE, resultMsg);
		}
		return PACKET_EXE_CONTINUE ;

	__LEAVE_FUNCTION

		return PACKET_EXE_ERROR ;
}
