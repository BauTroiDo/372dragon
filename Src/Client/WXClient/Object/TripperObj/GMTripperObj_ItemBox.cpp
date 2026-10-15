#include "StdAfx.h"
#include "GMTripperObj_ItemBox.h"
#include "../../Global.h"
#include "../../NetWork/NetManager.h"
#include "../ObjectManager.h"
#include "../Character/Obj_PlayerMySelf.h"
#include "../../Procedure/GameProcedure.h"
#include "CGOpenItemBox.h"
#include "..\WxRender\RenderSystem.h"

WX_IMPLEMENT_DYNAMIC(CTripperObject_ItemBox, GETCLASS(CTripperObject));
CTripperObject_ItemBox::CTripperObject_ItemBox()
{

}


CTripperObject_ItemBox::~CTripperObject_ItemBox()
{
}

VOID CTripperObject_ItemBox::Initial(VOID*)
{
		
	if ( m_pRenderInterface == NULL )
	{
		//创建渲染层实体
		m_pRenderInterface = CGameProcedure::s_pGfxSystem->New_EntityObject(tEntityNode::ETYPE_ACTOR);

		// CYS-CRASHANIM 19/09/2026: the drop-box model name is a RESOURCE KEY, not UI text, and the
		// dictionary route was a port regression: no StrDictionary of this project has ever had the
		// key "Obj_ItemBox_DropBox" (checked in CanonicalCY, client, client_GL and the pre-translation
		// GBK backup), so the lookup returned a non-model and TDAssert(mModel) in Actor_SetFile threw
		// - the crash that ended the user's 19/09 20:18 session, one packet after GCNewItemBox.
		// The shipped clients do NOT use the dictionary here: the GBK bytes of "0物品/包袱.obj" occur
		// exactly once in 085 client\Bin\Game.exe and once in CY 3.71 Bin64\Game.exe, and zero times
		// in ours. The dictionary cannot carry this name anyway while the UI runs UTF-8
		// (UIString.cpp:118 System_CodePage): all.obj object names are GBK bytes, and the only row that
		// ever held this path, Obj_ItemBox_Info_MuXiang, was itself translated to "0 vật phẩm/túi.obj"
		// by the text pipeline. Written as hex escapes on purpose - do not retype as source text.
		static const CHAR szDropBoxModel[] = "0\xce\xef\xc6\xb7/\xb0\xfc\xb8\xa4.obj";	// GBK: 0物品/包袱.obj
		// Measurement switch, default OFF, read once: 1 puts the old dictionary lookup back so a
		// control run can prove the check still detects the bug (same binary, one variable).
		static INT s_nOldKey = -1;
		if (s_nOldKey < 0)
		{
			CHAR szValue[8] = {0};
			const DWORD nLen = ::GetEnvironmentVariableA("CYS_CRASHANIM_OLDKEY", szValue, sizeof(szValue));
			s_nOldKey = (nLen == 1 && szValue[0] == '1') ? 1 : 0;
		}
		if (s_nOldKey)
		{
			const STRING strTemp = NOCOLORMSGFUNC("Obj_ItemBox_DropBox");
			TDU_Log("CYS-CRASHANIM: ARM=control (CYS_CRASHANIM_OLDKEY=1) drop-box name from StrDictionary");
			m_pRenderInterface->Actor_SetFile(strTemp.c_str());
		}
		else
		{
			m_pRenderInterface->Actor_SetFile(szDropBoxModel);
		}

		//设置选择优先级
		m_pRenderInterface->RayQuery_SetLevel(tEntityNode::RL_ITEMBOX);

		m_pRenderInterface->SetData(GetID());
	}
}

BOOL CTripperObject_ItemBox::Tripper_CanOperation(VOID) const
{ 
	if(CObjectManager::GetMe()->GetMySelf()->GetServerGUID() == m_idOwner)
		return TRUE;
	else
		return FALSE;
}

VOID CTripperObject_ItemBox::Release( VOID )
{
	if ( m_pRenderInterface != NULL )
	{
		m_pRenderInterface->Destroy();
		m_pRenderInterface = NULL;
	}
	CObject_Static::Release();
}

VOID CTripperObject_ItemBox::Tripper_Active(VOID)
{
	Packets::CGOpenItemBox msg;
	msg.setObjID(this->GetServerID());

	CNetManager::GetMe()->SendPacket(&msg);
}

