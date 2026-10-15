#include "StdAfx.h"
#include "ObjectManager.h"
#include "Object.h"
#include "..\Global.h"
#include "Character\Obj_Character.h"
#include "Character\Obj_PlayerOther.h"
#include "Character\Obj_PlayerMySelf.h"
#include "Character\Obj_PlayerNPC.h"	// CYS-QUEST: GetTalkSex
#include "..\DataPool\GMDP_CharacterData.h"
#include "Surface\Obj_Surface.h"
#include "..\Procedure\GameProcedure.h"
#include "..\Procedure\GamePro_Main.h"
#include "..\DBC\GMDataBase.h"
#include "TDDBC_Struct.h"
#include "TDException.h"
#include "..\NetWork\NetManager.h"
#include "TDinputsystem.h"
#include "..\WxRender\RenderSystem.h"
#include "..\Cursor\CursorMng.h"
#include "ProjTex\Obj_ProjTex.h"
#include "..\World\WorldManager.h"
#include "Item\Obj_Item.h"
#include "Item\Obj_Item_Equip.h"
#include "Item\Obj_Item_Medicine.h"
#include "Item\Obj_Item_Gem.h"
#include "Item\Obj_Item_StoreMap.h"
#include "CGLockTarget.h"
#include "TDEventDefine.h"
#include "TDUtil.h"
#include "..\Event\GMEventSystem.h"
#include "AxProfile.h"
#include "GMObjectLoadQueue.h"
#include "..\FakeObject\GMFakeObjSystem.h"
#include "TDGameInterface.h"
#include "..\DataPool\GMUIDataPool.h"
#include "..\Action\GMActionSystem.h"
WX_IMPLEMENT_DYNAMIC(CObjectManager, GETCLASS(tObjectSystem));
CObjectManager			*CObjectManager::s_pMe		= NULL;
CObjectManager::CObjectManager()
{
	s_pMe				= this;
	m_pMySelf			= NULL;
	m_pObjectRoot		= NULL;
	m_pLogicalObject	= NULL;
	m_pPlayerOther		= NULL;
	m_pAlogicalObject	= NULL;
	m_pNearestTargetOLD = NULL;
	m_pMainTarget		= NULL;
	m_pLoadQueue		= 0;

	m_bIsSelTeam = false;
}

CObjectManager::~CObjectManager()
{
	if ( s_pMe == this )
		s_pMe = NULL;
}

VOID CObjectManager::Initial( VOID* )
{
	m_pObjectRoot				= (CObject*)g_theKernel.NewNode(_T("CObject"), _T("scene"), _T("object"));
		m_pLogicalObject		= (CObject*)g_theKernel.NewNode(_T("CObject"), m_pObjectRoot, _T("logical"));
			m_pPlayerOther		= (CObject*)g_theKernel.NewNode(_T("CObject"), m_pLogicalObject, _T("otherplayer"));
			m_pNPC				= (CObject*)g_theKernel.NewNode(_T("CObject"), m_pLogicalObject, _T("npc"));
			m_pSurface			= (CObject*)g_theKernel.NewNode(_T("CObject"), m_pLogicalObject, _T("surface"));
		m_pAlogicalObject		= (CObject*)g_theKernel.NewNode(_T("CObject"), m_pObjectRoot, _T("alogical"));

	m_pLoadQueue = new CObjectLoadQueue();

	m_pMainTargetAvatar  = (CObject_PlayerOther*)(CFakeObjSystem::GetMe()->NewFakeObject("CObject_PlayerOther", "Target","Camera_Main"));
}

VOID CObjectManager::Release(VOID)
{
	ClearAllObject();
	delete m_pLoadQueue; m_pLoadQueue = 0;
//	m_pAvatar = NULL;
}

// CYS-SCFIX: close limit per care sign, CY 3.71 Game.exe 1405c79dd..1405c8623 (xmm7 1e9, xmm12 6, xmm9 15, xmm10 3,
// xmm11 10, xmm8 5; constants 0x140c141fc / 0x140a561ac / 0x140a54e2c / 0x140a54e28 / 0x140a6eae8 / 0x140a561a8).
static FLOAT CysCareCloseDistance(const std::string& sign)
{
	static const char* const kNever[] = { "ContexMenu", "TargetEquip", "TargetData", "TargetRune", "TargetWuhun",
		"OtherRide", "OtherPet", "TargetJingMai", "TargetZhenYuan", "TargetMiji", "TargetInfant", "TargetShenDing",
		"TargetFightScore", "TargetJunXian", "TargetBaoJian", "OtherYuShou_BaiHu", "OtherYuShou_QingLong",
		"OtherYuShou_XuanWu", "OtherYuShou_ZhuQue", "TargetShop_Dresser", "OtherMartial_WuYi",
		"OtherSuperWeapon9_DIYSkill", "BW_Match_Stage", "TargetArmor", "OtherHuanLing", "OtherPetNeidan",
		"Target_CangPin_GoTo", "Target_CangPin_ShuXing" };
	static const char* const kTen[] = { "HappyETJ_HD1", "HappyETJ_HD2", "XinShouMarriageNote", "OtherXunzhang_TuJian",
		"Xunzhang_TuJian_Record" };
	static const char* const kFive[] = { "WuLin_Peak", "WuLin", "WuLin_Awards", "WuLin_AwardEX", "WuLin_List",
		"WuLin_Peak_New", "WuLin_Difficulty", "ErtongjieHoudong", "CJ_ShiQu" };
	if (sign == "StallBuy" || sign == "Exchange") return 6.0f;
	for (size_t i = 0; i < sizeof(kNever) / sizeof(kNever[0]); ++i) if (sign == kNever[i]) return 1.0e9f;
	if (sign == "PetProcreate" || sign == "BieYeCutePetProcreate") return 15.0f;
	// INF: CY keeps LootPacket open (1e9) while MySelf has impact 0x157/0x2c1/0x2657 (FUN_1405f9510); not ported.
	for (size_t i = 0; i < sizeof(kTen) / sizeof(kTen[0]); ++i) if (sign == kTen[i]) return 10.0f;
	for (size_t i = 0; i < sizeof(kFive) / sizeof(kFive[0]); ++i) if (sign == kFive[i]) return 5.0f;
	return 3.0f;
}

// CYS-SCFIX: CY UI_CEGUI CUIWindowMng 0x1800763b0 only hides a window that is shown; a sign that names no window
// ("MsgBox") does nothing.
static VOID CysCareCloseWindow(const std::string& sign)
{
	if (!CGameProcedure::s_pUISystem || sign.empty()) return;
	if (CGameProcedure::s_pUISystem->IsWindowShow(sign.c_str()))
		CGameProcedure::s_pUISystem->CloseWindowByName(sign.c_str());
}

VOID CObjectManager::Tick(VOID)
{
	//检查是否有物体不再被关心
	if(CGameProcedure::GetActiveProcedure() == CGameProcedure::s_pProcMain)
		m_pLogicalObject->Tick_CheckAlive();
	//执行逻辑函数
	m_pLogicalObject->Tick();
	//检查被UI关心的逻辑对象
	// CYS-SCFIX: CY 3.71 CObjectManager::Tick (Game.exe 1405c79ca..1405c8705, Build/re/scene-change-fix/out/g_caretick.asm)
	// never broadcasts OBJECT_CARED_EVENT. For each cared object it measures the 2D distance to MySelf, picks a limit by
	// the care sign and, when distance > limit, calls tUISystem vtable +0xe0 (UI_CEGUI 0x180068730 -> CUIWindowMng
	// 0x1800763b0: hide the shown window whose name == sign) and drops the entry. Event id 0x137 OBJECT_CARED_EVENT is
	// only in the CY event table. The 0.85 broadcast reached every CY window that registers the event with bLoad=true:
	// MessageBox_Self (hidden) falls through its OnEvent chain to MessageBox_Self_UpdateFrame, whose UpdateFrameEx
	// returns 1 for g_FrameInfo -1 and shows the frame with the layout default text #{INTERFACE_XML_681} (the
	// "save stall info" box) - after every scene transfer the NPC dialog's cared NPC is destroyed (npc-quest gui-live-11).
	std::vector< std::string > cysCareClose;
	std::map< std::string, OBJECT_BECARED >::iterator it;
	for(it=m_mapCaredObject.begin(); GetMySelf() && it!=m_mapCaredObject.end(); it++)
	{
		OBJECT_BECARED& obj = it->second;
		//物体是否存在
		CObject* pObject = (CObject*)FindObject(obj.id);
		if(!pObject)
		{
			TDAssert(false && "Careobject error find!");
			continue;
		}

		//计算目前的距离
		FLOAT fDistance =
			TDU_GetDist(fVector2(GetMySelf()->GetPosition().x, GetMySelf()->GetPosition().z),
						fVector2(pObject->GetPosition().x, pObject->GetPosition().z));
		obj.fLastDistance = fDistance;

		if(fDistance > CysCareCloseDistance(it->first))
			cysCareClose.push_back(it->first);
	}
	// Erase first, then hide: the window's Hidden handler may call CareObject(..., 0, sign) and edit the map.
	for(size_t i = 0; i < cysCareClose.size(); ++i)
	{
		m_mapCaredObject.erase(cysCareClose[i]);
		CysCareCloseWindow(cysCareClose[i]);
	}
	//加载队列工作
	if(m_pLoadQueue)
	{
		m_pLoadQueue->Tick();
	}
}

tObject* CObjectManager::NewObject(LPCTSTR szClass, INT idServer, tObject* pParent)
{
	TDAssert(szClass);

	if(idServer != -1)
	{
		tObject* pFind = (tObject*)FindServerObject(idServer);
		//如果已经有
		if(pFind != NULL)
		{
			return pFind;
		}
	}

	//-------------------------------------------------------------------------
	//通过数据Kernel创建节点
	INT id = IDFactory();
	TCHAR szName[MAX_PATH];
	_stprintf(szName, _T("%d"), id);

	CObject* pNewNode = (CObject*)g_theKernel.NewNode(szClass, m_pObjectRoot, szName);
	m_pObjectRoot->EraseChild(pNewNode);

	pNewNode->SetServerID( idServer );
	pNewNode->m_ID = id;
	AttachObject( pNewNode );

	pNewNode->Enable(OSF_VISIABLE);
	CGameProcedure::m_bWaitNeedFreshMinimap = true;
	return pNewNode;
}

BOOL CObjectManager::DestroyObject(tObject* pObject)
{
	CGameProcedure::m_bWaitNeedFreshMinimap = true;
	TDAssert(pObject);

	DetchObject( pObject );

	delete (CObject*)pObject;
	return true;
}

// 根据ID得到某物体
tObject* CObjectManager::FindObject( INT id )
{
	CObjectMap::iterator it = m_hmObject.find(id);

	if(it == m_hmObject.end()) return 0;
	else return it->second;
}

// 获取一个SERVER OBJ对象的指针
tObject* CObjectManager::FindServerObject( INT idServer )
{
	CObjectMap::iterator it = m_hmServerObject.find(idServer);

	if(it == m_hmServerObject.end()) return 0;
	else return it->second;
}

CObject_Character* CObjectManager::FindCharacterByName(std::string szName)
{
	CObject_Character* pObject = NULL;

	if(!(m_hmServerObject.empty()))
	{
		std::map< INT, CObject* >::iterator it = m_hmServerObject.begin();
		for(;it != m_hmServerObject.end(); it++)
		{
			pObject = (CObject_Character*)(it->second);
			if(!g_theKernel.IsKindOf(pObject->GetClass(), GETCLASS(CObject_Character)))
			{
				pObject = NULL;
			}
			else
			{
				std::string szObjName = pObject->GetCharacterData()->Get_Name();
				if(szObjName != szName)
					pObject = NULL;
				else
					break;
			}				
		}
	}

	return pObject;
}

tObject_Item* CObjectManager::FindItem(INT id)
{
	return CObject_Item::FindItem(id);
}

VOID CObjectManager::ClearAllObject(VOID)
{
	//m_pMySelf			= NULL;
	m_pAlogicalObject->EraseAllChild();
	m_pPlayerOther->EraseAllChild();
	m_pNPC->EraseAllChild();
	m_pSurface->EraseAllChild();
	m_pLogicalObject->EraseAllChild();
	m_pLogicalObject->AddChild( m_pPlayerOther );
	m_pLogicalObject->AddChild( m_pNPC );
	m_pLogicalObject->AddChild( m_pSurface );
	m_pLogicalObject->AddChild( m_pMySelf );

	CObject *pObject;
	CObjectMap::iterator itCur, itEnd;
	if ( !m_hmObject.empty() )
	{
		itEnd = m_hmObject.end();
		for ( itCur = m_hmObject.begin(); itCur != itEnd; itCur++ )
		{
			pObject = (CObject*)(itCur->second);
			if ( pObject != NULL && m_pMySelf != pObject )
			{
				pObject->Release();
				delete pObject;
			}
		}
		m_hmObject.clear();
	}

	m_hmServerObject.clear();
}

BOOL CObjectManager::SetObjectServerID( INT idObj, INT idServer )
{
	if ( idObj != INVALID_ID )
	{
		CObject *pObject = (CObject*)(FindObject( idObj ));
		if ( pObject != NULL )
		{
			INT idOldServer = pObject->GetServerID();
			if ( idOldServer != INVALID_ID )
				m_hmServerObject.erase( idOldServer ); 

			if ( idServer != INVALID_ID )
				m_hmServerObject[idServer] = pObject; 

			pObject->SetServerID( idServer );
		}
	}
	return TRUE;
}

// 产生新物体,并加入数据链
CObject_PlayerOther* CObjectManager::NewPlayerOther( INT idServer )
{
	return (CObject_PlayerOther*)(NewObject( "CObject_PlayerOther", idServer, m_pPlayerOther ));
}

/// 产生新物体,并加入数据链
CObject_PlayerNPC* CObjectManager::NewPlayerNPC( INT idServer )
{
	return (CObject_PlayerNPC*)(NewObject( "CObject_PlayerNPC", idServer, m_pNPC ));
}

CObject_Surface* CObjectManager::NewSurfaceObj( LPCTSTR szClass )
{
	return (CObject_Surface*)NewObject( szClass, INVALID_ID, m_pSurface );
}

VOID CObjectManager::AttachObject( tObject *pObject )
{
	TDAssert(pObject);
	//-------------------------------------------------------------------------
	//根据是否有逻辑函数加入到节点中
	if(g_theKernel.IsKindOf(pObject->GetClass(), GETCLASS(CObject_PlayerMySelf)))
	{
		m_pLogicalObject->AddChild(pObject);
	}
	else if(g_theKernel.IsKindOf(pObject->GetClass(), GETCLASS(CObject_PlayerOther)))
	{
		m_pPlayerOther->AddChild(pObject);
	}
	else if(g_theKernel.IsKindOf(pObject->GetClass(), GETCLASS(CObject_PlayerNPC)))
	{
		m_pNPC->AddChild(pObject);
	}
	else if(g_theKernel.IsKindOf(pObject->GetClass(), GETCLASS(CObject_Surface)))
	{
		m_pSurface->AddChild(pObject);
	}
	else if(g_theKernel.IsKindOf(pObject->GetClass(), GETCLASS(CObject_ProjTex)))
	{
		m_pLogicalObject->AddChild(pObject);
	}
	else
	{
		m_pAlogicalObject->AddChild(pObject);
	}

	//-------------------------------------------------------------------------
	//加入hash_map
	m_hmObject[pObject->GetID()] = ((CObject*)pObject);

	INT idServer = ((CObject*)pObject)->GetServerID();
	if(idServer != INVALID_ID) 
	{
		m_hmServerObject[idServer] = ((CObject*)pObject);
	}

	//-------------------------------------------------------------------------
	//如果是自身，记录下指针
	if(pObject->GetClass() == GETCLASS(CObject_PlayerMySelf))
	{
		m_pMySelf = (CObject_PlayerMySelf*)pObject;
	}
}

VOID CObjectManager::DetchObject( tObject *pObject )
{
	TDAssert(pObject);

	INT id = pObject->GetID();
	INT idServer = ((CObject*)(pObject))->GetServerID();

	// 从数据链表中删除
	if(! pObject->GetParent()->EraseChild(pObject) ) return ;

	// 从HashMap中删除
	m_hmObject.erase(id);

	if ( idServer != INVALID_ID )
		m_hmServerObject.erase( idServer ); 

	if (CDataPool::GetMe()->GetTargetEquip() == pObject) CDataPool::GetMe()->Copy_To_TargetEquip(NULL);
	// 如果是自身，记录下指针
	if(pObject == m_pMySelf )
	{
		m_pMySelf = NULL;
	}

	//如果是主目标,取消选择
	if(pObject == m_pMainTarget)
	{
		m_pMainTarget = NULL;
	}

	//如果被ui关心，发出事件并清除
	// CYS-SCFIX: CY 3.71 DestroyObject (Game.exe 1405cf9d4..1405cfae1): every care entry of this object closes the
	// window named by its sign through tUISystem +0xe0 and is erased; no OBJECT_CARED_EVENT "destroy" broadcast.
	std::map< std::string, OBJECT_BECARED >::iterator it;
	std::vector< std::string > cysCareSigns;
	for(it=m_mapCaredObject.begin(); it!=m_mapCaredObject.end(); it++)
	{
		if(it->second.id == id) cysCareSigns.push_back(it->first);
	}
	for(size_t i = 0; i < cysCareSigns.size(); ++i)
	{
		m_mapCaredObject.erase(cysCareSigns[i]);
		CysCareCloseWindow(cysCareSigns[i]);
	}

	//删除队列中其他同ID的物体
	std::map< std::string, OBJECT_BECARED >::iterator itNext;
	for(it=m_mapCaredObject.begin(); it!=m_mapCaredObject.end(); it=itNext)
	{
		itNext = it;
		itNext++;

		OBJECT_BECARED& obj = it->second;
		if(obj.id == id)
		{
			m_mapCaredObject.erase(it);
		}
	}
}

tObject* CObjectManager::GetMouseOverObject( INT nX, INT nY, fVector3& fvMouseHitPlan ) 
{
	CObject* pHitObject = NULL;
	//-----------------------------------------------------------
	//取得鼠标射线
	fRay rayScreen;
	CGameProcedure::s_pGfxSystem->Camera_GetWindowToViewportRay(nX, nY, rayScreen);

	//-----------------------------------------------------------
	//根据屏幕上的坐标取得3D世界中的坐标
	const POINT pt = CGameProcedure::s_pInputSystem->MouseGetPos();
	if(!CGameProcedure::s_pGfxSystem->Axis_Trans( CRenderSystem::AX_SCREEN, fVector3((FLOAT)pt.x, (FLOAT)pt.y, 0.0f), 
		CRenderSystem::AX_PLAN, fvMouseHitPlan))
	{
		//与世界没有相交的物体
		pHitObject = NULL;
		return pHitObject;
	}

	//-----------------------------------------------------------
	//和行走面相交
	fVector3 fvBuilding;
	BOOL bInBuilding = ((CScene*)CWorldManager::GetMe()->GetActiveScene())->m_WalkCollisionMng.SelBuilding(
							rayScreen.mOrigin.x, rayScreen.mOrigin.y, rayScreen.mOrigin.z, 
							rayScreen.mDirection.x, rayScreen.mDirection.y, rayScreen.mDirection.z, 
							(INT)fvMouseHitPlan.x, (INT)fvMouseHitPlan.z,
							fvBuilding.x, fvBuilding.y, fvBuilding.z);

	if(bInBuilding)
	{
		fvMouseHitPlan = fvBuilding;
	}

	//-----------------------------------------------------------
	//查找鼠标接触物体
	static INT s_nLastHitObj = -1;

	tEntityNode* pEntityHitObj = CGameProcedure::s_pGfxSystem->Find_HitWXObject(pt.x, pt.y);
	if(pEntityHitObj)
	{
		pHitObject = (CObject*)CObjectManager::GetMe()->FindObject((INT)(pEntityHitObj->GetData()));
		if(pHitObject)
		{
			CGameProcedure::s_pGfxSystem->SetHitObjText( pHitObject->GetDebugDesc().c_str());
		}
		else 
		{
			CGameProcedure::s_pGfxSystem->SetHitObjText( "");
		}
	}
	else
	{
		CGameProcedure::s_pGfxSystem->SetHitObjText( "");
	}

	INT nHitObjID = pHitObject ? pHitObject->GetID() : -1;
	if(s_nLastHitObj != nHitObjID)
	{
		if(pHitObject )	pHitObject->GetRenderInterface()->Actor_SetMouseHover(TRUE);
		CObject* pLastHitObj = (CObject*)FindObject(s_nLastHitObj);

		if(pLastHitObj) pLastHitObj->GetRenderInterface()->Actor_SetMouseHover(FALSE);

		s_nLastHitObj = nHitObjID;
	}
	return pHitObject;
}

INT CObjectManager::IDFactory(VOID)
{
	static INT nLastUID = 100;

	return ++nLastUID; 
}

VOID CObjectManager::SetMainTarget(INT id, DESTROY_MAIN_TARGET_TYPE delType)
{
	CObject* pFindObj = NULL;
	
	if (id != INVALID_ID)
	{
		pFindObj = (CObject*)FindServerObject(id);
	}

	
	//不考虑无法选择的物体
	//如果没选中物体或者选种的物体是不CanbeSelect的，告诉服务器取消当前选种对象。
	if(!pFindObj || ( pFindObj && !(pFindObj->CanbeSelect()) ) ) 
	{
	
		if(m_pMainTarget)
		{
			//关闭选择环
			// CYS-CYGUI2: a dead monster keeps m_pMainTarget after its render interface is released (replay-8 -Core: AV here
			// when the drop box opened). Same guard as the SELECT_RING attach below.
			if (m_pMainTarget->GetRenderInterface()) m_pMainTarget->GetRenderInterface()->Attach_ProjTexture(tEntityNode::SELECT_RING, FALSE);
			m_pMainTarget	= NULL;
			
			if((delType != DEL_OBJECT)||(pFindObj && !(pFindObj->CanbeSelect())))
			{
				// 如果是鼠标右键销毁， target 窗口.
				// 2006-4-12 如果当前选择的不是队友返回。
				
				// 设置当前没有选中队友
				SetCurSelTeam(-1);

				CGameProcedure::s_pEventSystem->PushEvent(GE_MAINTARGET_CHANGED, -1);
				
			}
			else
			{
				if(!IsSelTeam())
				{
					// 2006-4-12 如果当前选择的不是队友返回。
					CGameProcedure::s_pEventSystem->PushEvent(GE_MAINTARGET_CHANGED, -1);
				}
			}

		}
		else
		{
			// 设置当前没有选中队友
			SetCurSelTeam(-1);

			CGameProcedure::s_pEventSystem->PushEvent(GE_MAINTARGET_CHANGED, -1);
		}
		return;
	}

	if( pFindObj && (pFindObj != m_pMainTarget) )
	{
		//关闭选择环
		if(m_pMainTarget)
		{
			// CYS-CYGUI2: a dead monster keeps m_pMainTarget after its render interface is released (replay-8 -Core: AV here
			// when the drop box opened). Same guard as the SELECT_RING attach below.
			if (m_pMainTarget->GetRenderInterface()) m_pMainTarget->GetRenderInterface()->Attach_ProjTexture(tEntityNode::SELECT_RING, FALSE, 0);
		}
		//设置选择对象
		m_pMainTarget = pFindObj;
/*		if( g_theKernel.IsKindOf(pFindObj->GetClass(), GETCLASS(CObject_PlayerOther)) )
		{

			m_pMainTargetAvatar->GetCharacterData()->Set_RaceID( ((CObject_Character*)pFindObj)->GetCharacterData()->Get_RaceID() );
			for(INT i=0; i<HEQUIP_NUMBER; i++)
			{
				m_pMainTargetAvatar->GetCharacterData()->Set_Equip((HUMAN_EQUIP)i,((CObject_Character*)pFindObj)->GetCharacterData()->Get_Equip((HUMAN_EQUIP)i));
			}
			m_pMainTargetAvatar->SetFaceDir(0.0f);
		}
*/
		//告诉server选中的对象

		//发往服务器
		CGLockTarget msg;
		msg.setTargetID(id);
		CNetManager::GetMe()->SendPacket( &msg );
		//msg.setObjID( pCharacter->GetServerID() );
		//msg.setSkillDataID( idSkill );
		//msg.setTargetID( idTargetObj );
		//msg.setTargetPos( posTarget );
		//msg.setDir( fDir );

		//CNetManager::GetMe()->SendPacket( &msg );

		//打开新的选择环
		if(m_pMainTarget && m_pMainTarget->GetRenderInterface())
		{
			FLOAT Select_Ring_Range = ((CObject_PlayerNPC*)(CObject_Character*)pFindObj)->GetProjtexRange();

			m_pMainTarget->GetRenderInterface()->Attach_ProjTexture(tEntityNode::SELECT_RING, TRUE, Select_Ring_Range );
		}

		//产生一个选择对象更改的事件
		CGameProcedure::s_pEventSystem->PushEvent(GE_MAINTARGET_CHANGED, id);


		//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		//
		// 设置选中队友2006－4－1
		//

		TeamMemberInfo* pInfo = CUIDataPool::GetMe()->GetTeamOrGroup()->GetMemberByServerId(m_pMainTarget->GetServerID());
		if(pInfo)
		{
			GUID_t GUID = pInfo->m_GUID;

			// 设置当前选中队友
			SetCurSelTeam(TRUE);
			SetCurSelTeam(GUID);
		}


	}

}

tObject* CObjectManager::GetMainTarget(VOID)
{
	return m_pMainTarget;
}

//关心某物体的指定事件 id-物体ID,	szSign:关心标志（谁关心）		bCare-关心或者取消关心
//修改说明：添加一个“是谁关心”的内容
VOID CObjectManager::CareObject(INT id, BOOL bCare, std::string szSign)
{
	//AxTrace(0,0,"C++ id =%d,bCare =%d,szSign =%s",id,(INT)bCare,szSign.c_str());
	//搜索物体
	CObject* pObject = (CObject*)FindObject(id);
	if(!pObject) return;

	//是否已经加入
	std::map< std::string, OBJECT_BECARED >::iterator it;
	it = m_mapCaredObject.find(szSign);

	//在表中已经有
	if(it != m_mapCaredObject.end())// && !bCare)
	{
		if(bCare)
		{
			//这个界面已经有关心的NPC，去关心新的 Npc 就可以了，
			it->second.id = id;
		}
		else
		{
			//取消关心的操作
			m_mapCaredObject.erase(it);
		}
	}
	//在表中没有
	if(it == m_mapCaredObject.end() && bCare)
	{
		OBJECT_BECARED objNewCared;
		objNewCared.id      = id;
		objNewCared.fLastDistance = 
			TDU_GetDist(fVector2(GetMySelf()->GetPosition().x, GetMySelf()->GetPosition().z),
						fVector2(pObject->GetPosition().x, pObject->GetPosition().z));

		m_mapCaredObject.insert(std::make_pair(szSign, objNewCared));
	}
}

// CYS-QUEST: CY 3.71 CObjectManager vt+0xb8 (Game.exe 0x1405c95f0). nWho 0: MySelf name; otherwise the main target's
// name when it is a CObject_Character; "" when there is none.
namespace
{
	CObject_Character* CysTalkCharacter(CObjectManager* self, INT nWho)
	{
		if(nWho == 0) return self->GetMySelf();
		tObject* pTarget = self->GetMainTarget();
		if(pTarget && g_theKernel.IsKindOf(pTarget->GetClass(), GETCLASS(CObject_Character))) return (CObject_Character*)pTarget;
		return NULL;
	}
}

LPCTSTR CObjectManager::GetTalkName(INT nWho)
{
	CObject_Character* pChar = CysTalkCharacter(this, nWho);
	if(!pChar || !pChar->GetCharacterData()) return "";
	LPCTSTR szName = pChar->GetCharacterData()->Get_Name();
	return szName ? szName : "";
}

// CY vt+0xc0 (0x1405c9700) -> character vt+0x308: players (0x14060b8a0) race record id % 2 when RaceID != -1,
// NPCs (0x1406026a0) the creature record gender. CY also requires an NPC field at +0x4f0 to be 0 [SL: not mapped].
INT CObjectManager::GetTalkSex(INT nWho)
{
	CObject_Character* pChar = CysTalkCharacter(this, nWho);
	if(!pChar || !pChar->GetCharacterData()) return -1;
	if(g_theKernel.IsKindOf(pChar->GetClass(), GETCLASS(CObject_PlayerNPC)))
	{
		const _DBC_CREATURE_ATT* pAtt = ((CObject_PlayerNPC*)pChar)->GetCreatureAtt();
		return pAtt ? pAtt->nGender : -1;
	}
	if(g_theKernel.IsKindOf(pChar->GetClass(), GETCLASS(CObject_PlayerOther)))
	{
		INT nRace = pChar->GetCharacterData()->Get_RaceID();
		return nRace == -1 ? -1 : nRace % 2;
	}
	return -1;
}

// CY vt+0xc8 (0x1405c96c0 -> 0x1401955c0): a MySelf character data string (+0x4940), "" in cross-server mode.
// [SL] the field is only reset in CY (0x1401bc250) and no data or script uses $U; 0.85 has no matching field -> "".
LPCTSTR CObjectManager::GetTalkUserString(VOID)
{
	return "";
}

LPCTSTR CObjectManager::ItemNameByTBIndex(UINT idTable)
{
	//-------------------------------------------------------
	//根据资源id打开资源定义
	if(idTable >= 10100000 && idTable <= 10199999)			// 白色装备
	{
		//打开数据表
		DBC_DEFINEHANDLE(s_pItem_WhiteEquip, DBC_ITEM_EQUIP_WHITE);
		//搜索纪录
		const _DBC_ITEM_EQUIP_WHITE* pWhiteEquip = (const _DBC_ITEM_EQUIP_WHITE*)s_pItem_WhiteEquip->Search_Index_EQU((UINT)idTable);
		if(!pWhiteEquip) return NULL;
		return pWhiteEquip->szName;

	}
	else if(idTable >= 10400000 && idTable <= 10499999)	// 绿色装备
	{
		//打开数据表
		DBC_DEFINEHANDLE(s_pItem_GreenEquip, DBC_ITEM_EQUIP_GREEN);
		//搜索纪录
		const _DBC_ITEM_EQUIP_GREEN* pGreenEquip = (const _DBC_ITEM_EQUIP_GREEN*)s_pItem_GreenEquip->Search_Index_EQU((UINT)idTable);
		if(!pGreenEquip) return NULL;
		return pGreenEquip->szName;
	}
	else if(idTable >= 10200000 && idTable <= 10299999)	// 蓝色装备
	{
		//打开数据表
		DBC_DEFINEHANDLE(s_pItem_BlueEquip, DBC_ITEM_EQUIP_BLUE);
		//搜索纪录
		const _DBC_ITEM_EQUIP_BLUE* pBlueEquip = (const _DBC_ITEM_EQUIP_BLUE*)s_pItem_BlueEquip->Search_Index_EQU((UINT)idTable);
		if(!pBlueEquip) return NULL;
		return pBlueEquip->szName;
	}
	else if(idTable >= 20000000 && idTable <= 49999999)	// 原材料 + 食品 + 药瓶
	{
		//打开数据表
		DBC_DEFINEHANDLE(s_pItem_Medic, DBC_ITEM_MEDIC);
		//搜索纪录
		const _DBC_ITEM_MEDIC* pMedic = (const _DBC_ITEM_MEDIC*)s_pItem_Medic->Search_Index_EQU((UINT)idTable);
		if(!pMedic) return NULL;
		return pMedic->szName;
	}
	else if(idTable >= 50000000 && idTable <= 59999999)	// 宝石
	{
		//打开数据表
		DBC_DEFINEHANDLE(s_pItem_Gem, DBC_ITEM_GEM);
		//搜索纪录
		const _DBC_ITEM_GEM* pGem = (const _DBC_ITEM_GEM*)s_pItem_Gem->Search_Index_EQU((UINT)idTable);
		if(!pGem) return NULL;
		return pGem->szName;
	}
	else if(idTable >= 60000000 && idTable <= 69999999)	// 地图
	{
		//打开数据表
		DBC_DEFINEHANDLE(s_pItem_StoreMap, DBC_ITEM_STOREMAP);
		//搜索纪录
		const _DBC_ITEM_STOREMAP* pStoreMap = (const _DBC_ITEM_STOREMAP*)s_pItem_StoreMap->Search_Index_EQU((UINT)idTable);
		if(!pStoreMap) return NULL;
		return pStoreMap->szName;
	}
	else
	{
		return NULL;
		TDThrow("Invalid ItemID:%d", idTable);
	}
}

void CObjectManager::Debug_LockNearestTarget(void)
{
	
	CObjectMap::iterator it;

	CObject* pNearestTarget = 0;
	float fNearestDist = 20.0f; //最大允许距离(m)

	for(it=m_hmServerObject.begin(); it!=m_hmServerObject.end(); it++)
	{
		CObject* pObj = it->second;

		//非角色
		if(!g_theKernel.IsKindOf(pObj->GetClass(), GETCLASS(CObject_Character))) continue;

		//友好阵营
		CObject_Character* pChar = (CObject_Character*)pObj;
		if(RELATION_ENEMY != CGameProcedure::s_pGameInterface->GetCampType(
									GetMySelf(), pChar))
		{
			continue;
		}

		//死亡
		if(CObject_Character::CHARACTER_LOGIC_DEAD == pChar->CharacterLogic_Get()) continue;

		//距离太远
		float fDistance = ::TDU_GetDist(  
								fVector2(GetMySelf()->GetPosition().x, GetMySelf()->GetPosition().z), 
								fVector2(pObj->GetPosition().x, pObj->GetPosition().z));

		if(fDistance >= fNearestDist) continue;


		pNearestTarget = pObj;
		fNearestDist = fDistance;
	}

	//锁定该目标
	if(pNearestTarget && pNearestTarget != GetMainTarget())
	{
		SetMainTarget(pNearestTarget->GetServerID());
	}
}

void CObjectManager::Debug_LockNearestTargetToHit(void)
{

	CObjectMap::iterator it;

	CObject* pNearestTarget = 0;
	float fNearestDist = 20.0f; //最大允许距离(m)

	for(it=m_hmServerObject.begin(); it!=m_hmServerObject.end(); it++)
	{
		CObject* pObj = it->second;

		//非角色
		if(!g_theKernel.IsKindOf(pObj->GetClass(), GETCLASS(CObject_Character))) continue;

		//友好阵营
		CObject_Character* pChar = (CObject_Character*)pObj;
		if(RELATION_ENEMY != CGameProcedure::s_pGameInterface->GetCampType(
			GetMySelf(), pChar))
		{
			continue;
		}

		//死亡
		if(CObject_Character::CHARACTER_LOGIC_DEAD == pChar->CharacterLogic_Get()) continue;

		//距离太远
		float fDistance = ::TDU_GetDist(  
			fVector2(GetMySelf()->GetPosition().x, GetMySelf()->GetPosition().z), 
			fVector2(pObj->GetPosition().x, pObj->GetPosition().z));

		if(fDistance >= fNearestDist) continue;


		pNearestTarget = pObj;
		fNearestDist = fDistance;
	}

	//锁定该目标
	if(pNearestTarget && pNearestTarget != GetMainTarget())
	{
		SetMainTarget(pNearestTarget->GetServerID());
	}
	//下边为挂机增加自动攻击
	if (m_pNearestTargetOLD !=pNearestTarget)
	{
		fVector3 fvMouseHitPlan;
		fvMouseHitPlan.x = 0.0f;
		fvMouseHitPlan.z = 0.0f;
		CCursorMng::GetMe()->MouseCommand_Set(false, pNearestTarget, fvMouseHitPlan, CActionSystem::GetMe()->GetDefaultAction());
		CCursorMng::GetMe()->MouseCommand_Active(CCursorMng::GetMe()->MouseCommand_GetLeft());
		m_pNearestTargetOLD = pNearestTarget;
	}

}

// 设置当前选择的是队友
void CObjectManager::SetCurSelTeam(GUID_t id)
{
	if(-1 == id)
	{
		m_bIsSelTeam = FALSE;
	}
	else
	{
		m_bIsSelTeam = TRUE;
	}

	m_GUID = id;
}

// 设置队友是否在当前可视范围
void CObjectManager::SetPresent(BOOL  bIsPresent)
{
	m_bIsSelTeamInPresent = bIsPresent;
}

// 当前选择的是否是对友2006－4－1
BOOL CObjectManager::IsSelTeam()
{
	return m_bIsSelTeam;

}

	// 选择的队友是否在眼前2006－4－1
BOOL CObjectManager::IsSelTeamInPresent()
{
	return m_bIsSelTeamInPresent;
}

GUID_t CObjectManager::GetCurSelTeam()
{
	return m_GUID;
}



VOID CObjectManager::SetTargetAvatarAsTarget( VOID )
{
	CObject* pObj = CDataPool::GetMe()->GetTargetEquip();
	
	if(!pObj)
		pObj = m_pMainTarget;

	if(pObj)
	{

		if( g_theKernel.IsKindOf(pObj->GetClass(), GETCLASS(CObject_PlayerOther)) )
		{

			m_pMainTargetAvatar->GetCharacterData()->Set_RaceID( ((CObject_Character*)pObj)->GetCharacterData()->Get_RaceID() );

			m_pMainTargetAvatar->GetCharacterData()->Set_HairColor( ((CObject_Character*)pObj)->GetCharacterData()->Get_HairColor() );
			m_pMainTargetAvatar->GetCharacterData()->Set_HairMesh( ((CObject_Character*)pObj)->GetCharacterData()->Get_HairMesh() );
			

			for(INT i=0; i<HEQUIP_NUMBER; i++)
			{
				m_pMainTargetAvatar->GetCharacterData()->Set_Equip((HUMAN_EQUIP)i,((CObject_Character*)pObj)->GetCharacterData()->Get_Equip((HUMAN_EQUIP)i));
			}
            auto source=((CObject_Character*)pObj)->GetCharacterData();
            auto preview=m_pMainTargetAvatar->GetCharacterData();
            preview->Set_FaceMesh(source->Get_FaceMesh());
            preview->Set_DressVisual(source->Get_DressVisual());
            preview->Set_ExteriorWeapon(source->Get_ExteriorWeapon());
            preview->Set_WuhunAppearance(source->Get_WuhunItem(),source->Get_WuhunVisual());
            preview->Set_AssaultAppearance(source->Get_AssaultItem(),source->Get_AssaultVisual());
            for (int slot=0;slot<2;++slot) preview->Set_Ornament(slot,source->Get_OrnamentId(slot),source->Get_OrnamentPos(slot));
            m_pMainTargetAvatar->SetFaceDir(0.0f);
		}
	}
}

//取得当前选中物体
tObject*	CObjectManager::GetMainTarget(GUID_t& guid)
{
	if(IsSelTeam())
	{
		guid = m_GUID;
	}
	else
	{
		guid = (GUID_t)-1;
	}

	return m_pMainTarget;

}

void CObjectManager::OnScreenSizeChanged(void)
{
	CObjectMap::iterator it;
	for(it=m_hmServerObject.begin(); it!=m_hmServerObject.end(); it++)
	{
		CObject* pObj = it->second;
		if(g_theKernel.IsKindOf(pObj->GetClass(), GETCLASS(CObject_Character)))
		{
			((CObject_Character*)pObj)->Tick_UpdateInfoBoard();
		}
	}
}

void CObjectManager::OnMySelfLevelUp(void)
{
	//重新根据等级刷新周围怪物的名称颜色
	CObjectMap::iterator it;
	for(it=m_hmServerObject.begin(); it!=m_hmServerObject.end(); it++)
	{
		if(g_theKernel.IsKindOf(it->second->GetClass(), GETCLASS(CObject_Character)))
		{
			CObject_Character* pChar = (CObject_Character*)(it->second);

			pChar->GetCharacterData()->Set_Name(pChar->GetCharacterData()->Get_Name());
		}
	}
}

void CObjectManager::UnSelMainTarget(void)
{
	
	if(m_pMainTarget)
	{
		//关闭选择环
		m_pMainTarget->GetRenderInterface()->Attach_ProjTexture(tEntityNode::SELECT_RING, FALSE);
		m_pMainTarget	= NULL;
	}

}

void CObjectManager::SetLoadNPCDirect(BOOL b)
{
	if(m_pLoadQueue)
	{
		m_pLoadQueue->SetLoadNPCDirect(b);
	}
}
