#include "StdAfx.h"

#include "..\..\Procedure\GameProcedure.h"
#include "..\..\Event\GMEventSystem.h"

#include "GCTeamFollowErr.h"

const char* pErrString[] = {
	"Too_Far_To_Leader",
	"Can_Not_Move_Self",
	"Stall_Can_Not_Follow_Team",
	"In_Follow"
};

uint GCTeamFollowErrHandler::Execute( GCTeamFollowErr* pPacket, Player* pPlayer )
{
__ENTER_FUNCTION

	if(CGameProcedure::GetActiveProcedure() == (CGameProcedure*)CGameProcedure::s_pProcMain)
	{
		CHAR *pErrContent = new CHAR[MAX_PATH];

		switch( pPacket->GetError() )
		{
		case TF_ERROR_TOO_FAR:
		case TF_ERROR_IN_TEAM_FOLLOW:
		case TF_ERROR_STALL_OPEN:
		case TF_ERROR_NOT_IN_FOLLOW_MODE:
			{
				STRING strTemp = "";
				strTemp = NOCOLORMSGFUNC(pErrString[pPacket->GetError()]);
				// CYS-CRTGUARD 20/09/2026: `strTemp` la VAN BAN da dich, KHONG phai chuoi
				// dinh dang. Nguyen van dua no lam tham so `format` cua `_snprintf` voi 0 doi
				// so, nen moi dau `%` con sot trong ban dich se doc doi so KHONG TON TAI
				// (`%s` -> con tro rac, `%n` -> __fastfail 0xC0000409 khong minidump).
				// Day la lan thu HAI cung mot chuoi di qua printf: `NOCOLORMSGFUNC` o dong
				// tren da dinh dang no mot lan roi. Chep bang "%s".
				_snprintf(pErrContent, MAX_PATH - 1, "%s", strTemp.c_str());
				pErrContent[MAX_PATH - 1] = 0;
				//_snprintf(pErrContent, MAX_PATH, pErrString[pPacket->GetError()]);
			}
			break;
		default:
			return PACKET_EXE_CONTINUE;
		}

		CGameProcedure::s_pEventSystem->PushEvent( GE_NEW_DEBUGMESSAGE, pErrContent );
	}

	return PACKET_EXE_CONTINUE;

__LEAVE_FUNCTION

	return PACKET_EXE_ERROR;
}
