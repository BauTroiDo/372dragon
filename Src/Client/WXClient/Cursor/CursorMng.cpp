#include "StdAfx.h"
#include ".\cursormng.h"
#include "../Network/CysRideNet.h"
#include "..\resource.h"
#include "..\Network\NetManager.h"
#include "..\gamecommand.h"
#include "..\object\Object.h"
#include "..\Interface\GMGameInterface.h"
#include "..\Procedure\GameProcedure.h"
#include "..\Object\ObjectManager.h"
#include "..\Object\Character\Obj_Character.h"
#include "..\Object\Character\Obj_PlayerMySelf.h"
#include "..\Object\Character\AI\GMAI_Base.h"	// CYS-MOVE2: PushCommand_Fly of MCT_LEAP
#include "..\Object\TripperObj\GMTripperObj_ItemBox.h"
#include "DB_Struct.h"
#include "..\Global.h"
#include "TDUtil.h"
#include "..\Event\GMEventSystem.h"
#include "TDActionSystem.h"
#include "TDTimeSystem.h"
#include "..\Action\GMActionSystem.h"
#include "..\DataPool\GMDP_CharacterData.h"
#include "..\DataPool\GMDataPool.h"
#include "..\Action\GMActionSystem_Item.h"
#include "CGUseItem.h"
#include "..\Object\Item\Obj_Item_Medicine.h"
#include "..\Action\GMActionSystem_PetSkill.h"
#include "..\interface\GMGameInterface_Script.h"
#include "..\Input\GMInputSystem.h"
#include "CGExchangeApplyI.h"
#include "CGRelation.h"

namespace
{
	// CYS-ROBUST -- root cause (orchestrator, 13/09): CGameProcedure::
	// _MainWndProc (GameProcedure.cpp) falls through to DefWindowProcW
	// whenever s_pProcActive is NULL, which the offline/-fl login path can
	// hit; DefWindowProcW's own WM_SETCURSOR handling shows the WINDOW
	// CLASS's cursor, not whatever CCursorMng last chose. This makes our
	// cursor stick two ways instead of depending on WM_SETCURSOR reaching
	// OnSetCursor:
	//   1. SetClassLongPtrW(..., GCLP_HCURSOR, h) -- so DefWindowProcW's
	//      own fallback shows OUR cursor too (CreateMainWnd also now
	//      registers the class with a GL cursor to begin with, so this
	//      is right even before CCursorMng ever runs).
	//   2. An immediate ::SetCursor(h), but ONLY when this window is both
	//      the foreground window and the pointer is over its own client
	//      area -- otherwise this would steal the cursor from whatever
	//      window/app genuinely owns it right now.
	VOID ApplyCursorRobust(HCURSOR hCursor)
	{
		if (!hCursor || !g_hMainWnd) return;

		::SetClassLongPtrW(g_hMainWnd, GCLP_HCURSOR, (LONG_PTR)hCursor);

		if (::GetForegroundWindow() != g_hMainWnd) return;
		POINT pt;
		if (!::GetCursorPos(&pt)) return;
		if (::WindowFromPoint(pt) != g_hMainWnd) return;
		POINT ptClient = pt;
		::ScreenToClient(g_hMainWnd, &ptClient);
		RECT rc;
		if (::GetClientRect(g_hMainWnd, &rc) && ::PtInRect(&rc, ptClient))
		{
			::SetCursor(hCursor);
		}
	}
}

WX_IMPLEMENT_DYNAMIC(CCursorMng, GETCLASS(tCursorSystem));
CCursorMng* CCursorMng::s_pMe = NULL;
CCursorMng::CCursorMng(VOID)
{
	s_pMe = this;

	m_bShow = TRUE;
	m_nCursorState	= CURSOR_NORMAL;
	m_hUICursor = NULL;
	m_cmdCurrent_Left.Cleanup();
	m_cmdCurrent_Right.Cleanup();

	m_cmdCurrent_Left.m_typeMouse = SCommand_Mouse::MCT_NULL;
	m_cmdCurrent_Right.m_typeMouse = SCommand_Mouse::MCT_NULL;
}

CCursorMng::~CCursorMng(VOID)
{
}

VOID CCursorMng::SetCursor(ENUM_CURSOR_TYPE nType )
{
	m_nCursorState		= nType;
	::PostMessage( g_hMainWnd, WM_SETCURSOR, 0, HTCLIENT );

	// CYS-ROBUST: apply directly too, in case that PostMessage's
	// WM_SETCURSOR never reaches OnSetCursor (see ApplyCursorRobust
	// above) -- a real cursor-type change (attack/pickup/... over a game
	// object) must never depend solely on that routing succeeding. Skip
	// while a UI drag icon is active, matching OnSetCursor's own
	// precedence (m_hUICursor wins over m_hCursor[state]).
	if (m_bShow && !m_hUICursor)
	{
		ApplyCursorRobust(m_hCursor[nType]);
	}
}

INT CCursorMng::GetCursor_State(VOID)
{
//	if(!m_bShow) return CURSOR_NORMAL;

	return m_nCursorState;
}

HCURSOR CCursorMng::GetCursor(VOID)
{
	if(!m_bShow) return NULL;

	return m_hCursor[m_nCursorState];
}

//响应WM_SETCURSOR
VOID CCursorMng::OnSetCursor(VOID)
{
	if(m_bShow)
	{
		HCURSOR hCursor = m_hUICursor ? m_hUICursor : GetCursor();
		::SetCursor(hCursor);
		ApplyCursorRobust(hCursor);	// CYS-ROBUST: keep the window class's fallback cursor in sync too
	}
}

VOID CCursorMng::ShowCursor(BOOL bShow)
{
	if(bShow == m_bShow) return;

	m_bShow = bShow;
	::ShowCursor(m_bShow);
}


// 激活当前鼠标上挂接的命令
VOID CCursorMng::MouseCommand_Active(SCommand_Mouse& cmd)
{
	switch(cmd.m_typeMouse)
	{
	case SCommand_Mouse::MCT_PLAYER_MOVETO:
		{
			static UINT uPrevMoveTime = 0;
			if(CGameProcedure::s_pTimeSystem->GetTimeNow() > uPrevMoveTime + 100)
			{
				uPrevMoveTime = CGameProcedure::s_pTimeSystem->GetTimeNow();
				CGameProcedure::s_pGameInterface->Player_MoveTo(fVector2(cmd.m_afParam[0], cmd.m_afParam[1]));
	//			AxTrace(0, 0, "Active: MoveTo(Pos=%.1f, %.1f)", (float)cmd.m_afParam[0], (float)cmd.m_afParam[1]);
			}
		}
		break;

	case SCommand_Mouse::MCT_PLAYER_SELECT:
		{
			// 
			CGameProcedure::s_pGameInterface->Object_SelectAsMainTarget((INT)cmd.m_adwParam[0], 1);
			
			
			if(	m_cmdCurrent_Left.m_typeMouse == SCommand_Mouse::MCT_SKILL_DIR ||
				m_cmdCurrent_Left.m_typeMouse == SCommand_Mouse::MCT_SKILL_AREA)
			{
				m_cmdCurrent_Left.m_typeMouse = SCommand_Mouse::MCT_NULL;
				m_cmdCurrent_Left.m_apParam[0] = NULL;
				m_cmdCurrent_Left.m_afParam[1] = NULL;
				//恢复激活技能
				CActionSystem::GetMe()->SetDefaultAction(CGameProcedure::s_pGameInterface->Skill_GetActive());
			}
//			AxTrace(0, 0, "Active: SelectPlayer(ID=%d)", (int)cmd.m_afParam[0]);
		}
		break;

	case SCommand_Mouse::MCT_SKILL_OBJ:
		{
			//首先选择
			CGameProcedure::s_pGameInterface->Object_SelectAsMainTarget((INT)cmd.m_adwParam[1]);

			tActionItem* pItem = (tActionItem*)cmd.m_apParam[0];
			if(!pItem) break;

			//进入攻击
			if(pItem->GetType() == AOT_PET_SKILL)
			{
				int nPetSkillID = ((PET_SKILL*)(((CActionItem_PetSkill*)pItem)->GetImpl()))->m_pDefine->m_nID;
				CDataPool::GetMe()->Pet_SendUseSkillMessage(nPetSkillID, 
					INVALID_ID, cmd.m_afParam[1], cmd.m_afParam[2]);
			}
			else
			{
				CGameProcedure::s_pGameInterface->Player_UseSkill(
							((tActionItem*)cmd.m_apParam[0])->GetID(),
							(INT)cmd.m_adwParam[1]);
			}
//			AxTrace(0, 0, "Active: SkillObj(Skill=%d, ID=%d)", (int)cmd.m_afParam[0], (int)cmd.m_adwParam[1]);
		}
		break;

	case SCommand_Mouse::MCT_SKILL_AREA:
		{
			tActionItem* pItem = (tActionItem*)cmd.m_apParam[0];
			if(!pItem) break;

			if(pItem->GetType() == AOT_PET_SKILL)
			{
				int nPetSkillID = ((PET_SKILL*)(((CActionItem_PetSkill*)pItem)->GetImpl()))->m_pDefine->m_nID;
				CDataPool::GetMe()->Pet_SendUseSkillMessage(nPetSkillID, 
					INVALID_ID, cmd.m_afParam[1], cmd.m_afParam[2]);
			}
			else
			{
				CGameProcedure::s_pGameInterface->Player_UseSkill(
							((tActionItem*)cmd.m_apParam[0])->GetID(),
							fVector2(cmd.m_afParam[1], cmd.m_afParam[2]));
			}
//			AxTrace(0, 0, "Active: SkillArea(Skill=%d, Pos=%.1f,%.1f)", 
//				(int)cmd.m_afParam[0], (int)cmd.m_adwParam[1], (int)cmd.m_afParam[2]);

			//恢复激活Action
			CActionSystem::GetMe()->SetDefaultAction(CGameProcedure::s_pGameInterface->Skill_GetActive());
		}
		break;

	case SCommand_Mouse::MCT_CANCEL_SKILL:
		{
			//恢复激活Action
			CActionSystem::GetMe()->SetDefaultAction(CGameProcedure::s_pGameInterface->Skill_GetActive());
		}
		break;

	case SCommand_Mouse::MCT_SKILL_DIR:
		{
			TDThrow("Not support any more!");
		}
		break;

	case SCommand_Mouse::MCT_HIT_TRIPPEROBJ:
		{
			CGameProcedure::s_pGameInterface->TripperObj_Active(cmd.m_adwParam[0]);
//			AxTrace(0, 0, "Active: TripObj(ID=%d)", (int)cmd.m_adwParam[0]);
		}
		break;

	case SCommand_Mouse::MCT_SPEAK:
		{
			//首先选择
			CGameProcedure::s_pGameInterface->Object_SelectAsMainTarget((INT)cmd.m_adwParam[0]);
			
			//谈话
			CGameProcedure::s_pGameInterface->Player_Speak(cmd.m_adwParam[0]);

//			AxTrace(0, 0, "Active: Speak(ID=%d)", (int)cmd.m_adwParam[0]);
		}
		break;

	case SCommand_Mouse::MCT_CONTEXMENU:
		{
			//首先选择
			CGameProcedure::s_pGameInterface->Object_SelectAsMainTarget((INT)cmd.m_adwParam[0], 1);
			
			//显示右键菜单
			CGameProcedure::s_pGameInterface->Object_ShowContexMenu(cmd.m_adwParam[0]);
//			AxTrace(0, 0, "Active: ContexMenu(ID=%d)", (int)cmd.m_adwParam[0]);
		}
		break;

	case SCommand_Mouse::MCT_REPAIR:
		{
			//do nothing...
		}
		break;

	case SCommand_Mouse::MCT_CANCLE_REPAIR:
		{
			//取消修理
			CActionSystem::GetMe()->SetDefaultAction(CGameInterface::GetMe()->Skill_GetActive());
		}
		break;

    
	case SCommand_Mouse::MCT_UI_USE_IDENTIFY:
		{
			// 使用鉴定卷轴
			
			break;
		}
	case SCommand_Mouse::MCT_UI_USE_CANCEL_IDENTIFY:
		{
			// 取消使用鉴定卷轴
			CDataPool::GetMe()->Identify_UnLock();
			break;
		}
	case SCommand_Mouse::MCT_UI_USE_EXCHANGE:
		{
			if(TRUE == CObjectManager::GetMe()->GetMySelf()->GetCharacterData()->Get_IsInStall())
			{
				CEventSystem::GetMe()->PushEvent(GE_NEW_DEBUGMESSAGE,"你正在摆摊……");
				return ;
			}
			CGameProcedure::s_pGameInterface->Object_SelectAsMainTarget((INT)cmd.m_adwParam[0]);
			CObject* pChar = (CObject*) CObjectManager::GetMe()->GetMainTarget();
			if(pChar && g_theKernel.IsKindOf(pChar->GetClass(), GETCLASS(CObject_PlayerOther)))
			{
				//先判定距离是不是合法
				if(pChar)
				{
					const fVector3 pMePos = CObjectManager::GetMe()->GetMySelf()->GetPosition();
					const fVector3 pOtherPos = ((CObject*)pChar)->GetPosition();

					FLOAT fDistance = 
						TDU_GetDist(fVector2(pMePos.x, pMePos.z),
						fVector2(pOtherPos.x, pOtherPos.z));

					if( EXCHANGE_MAX_DISTANCE < fDistance )
					{
						CEventSystem::GetMe()->PushEvent(GE_NEW_DEBUGMESSAGE,"距离太远，启动交易失败");
						return;
					}
				}

				//不能向已经死亡的玩家发送交易申请
				if ( ((CObject_Character*)pChar)->CharacterLogic_Get() == CObject_Character::CHARACTER_LOGIC_DEAD )
				{
					CEventSystem::GetMe()->PushEvent(GE_NEW_DEBUGMESSAGE,"不能向已经死亡的玩家申请交易");
					return ;
				}

				CGExchangeApplyI msg;
				msg.SetObjID(pChar->GetServerID());
				CNetManager::GetMe()->SendPacket(&msg);
				CEventSystem::GetMe()->PushEvent(GE_NEW_DEBUGMESSAGE,"交易请求已经发送");
				CGameProcedure::s_pGameInterface->Skill_CancelAction();
				return ;
			}
		}
		break;
	case SCommand_Mouse::MCT_UI_USE_CANCEL_EXCHANGE:
		{
			CActionSystem::GetMe()->SetDefaultAction(CGameInterface::GetMe()->Skill_GetActive());
			break;
		}
	case SCommand_Mouse::MCT_SALE:
		break;
	case SCommand_Mouse::MCT_CANCEL_SALE:
		{
			CActionSystem::GetMe()->SetDefaultAction(CGameInterface::GetMe()->Skill_GetActive());
			break;
		}
	case SCommand_Mouse::MCT_BUYMULT:
		break;
	case SCommand_Mouse::MCT_CANCEL_BUYMULT:
		{
			CActionSystem::GetMe()->SetDefaultAction(CGameInterface::GetMe()->Skill_GetActive());
			break;
		}
	case SCommand_Mouse::MCT_UI_USE_ADDFRIEND:
		{
			//首先选择
			CGRelation Msg;
			Msg.GetRelation()->CleanUp();
			Msg.GetRelation()->m_Type = REQ_ADDFRIEND;
			REQUEST_ADD_RELATION_WITH_GROUP* pFriend = &(Msg.GetRelation()->m_AddRelationWithGroup);
			pFriend->CleanUp();
			CGameProcedure::s_pGameInterface->Object_SelectAsMainTarget((INT)cmd.m_adwParam[0]);
			CObject_Character* pCharObj = (CObject_Character*)CObjectManager::GetMe()->GetMainTarget();
			if( pCharObj == NULL )
				break;
			if( pCharObj == CObjectManager::GetMe()->GetMySelf() ) // 如果是自己，就不加
				break;
			if( g_theKernel.IsKindOf( pCharObj->GetClass(), GETCLASS(CObject_PlayerOther) ) ) // 如果是玩家
			{
				ENUM_RELATION sCamp = CGameInterface::GetMe()->GetCampType( 
					pCharObj, 
					(CObject*)CObjectManager::GetMe()->GetMySelf() );
				if( sCamp != RELATION_FRIEND ) // 如果是同一阵营的
				{
					CGameProcedure::s_pEventSystem->PushEvent( GE_NEW_DEBUGMESSAGE, "无效目标");
					break;
				}
			}
			else
			{
				CGameProcedure::s_pEventSystem->PushEvent( GE_NEW_DEBUGMESSAGE, "无效目标");
				break;
			}
			pFriend->SetTargetName( pCharObj->GetCharacterData()->Get_Name() );
			pFriend->SetGroup( SCRIPT_SANDBOX::Friend::m_nCurTeam );
			pFriend->SetRelationType( RELATION_TYPE_FRIEND );
			CNetManager::GetMe()->SendPacket( &Msg );
		}
		break;
	case SCommand_Mouse::MCT_UI_USE_CANCEL_ADDFRIEND:
		CActionSystem::GetMe()->SetDefaultAction(CGameInterface::GetMe()->Skill_GetActive());
		break;
	case SCommand_Mouse::MCT_USE_ITEM:
		{
			//使用物品
			CGameProcedure::s_pGameInterface->PacketItem_UserItem((
				tActionItem*)cmd.m_apParam[0], 
				cmd.m_adwParam[1],
				fVector2(cmd.m_afParam[2], cmd.m_afParam[3]));

			//恢复激活Action
			CActionSystem::GetMe()->SetDefaultAction(CGameProcedure::s_pGameInterface->Skill_GetActive());
		}
		break;

	case SCommand_Mouse::MCT_CANCEL_USE_ITEM:
		{
			//恢复激活Action
			CActionSystem::GetMe()->SetDefaultAction(CGameProcedure::s_pGameInterface->Skill_GetActive());
		}
		break;

	case SCommand_Mouse::MCT_LEAP:
		{




			CObject_PlayerMySelf* pMySelf = CObjectManager::GetMe()->GetMySelf();
			// CYS-LEAP: truoc day ca ba dieu kien duoi day that bai trong im lang; mot luot do am tinh khong noi duoc
			// la lenh chua bao gio duoc kich hoat hay da kich hoat ma bi tu choi.
			if(!pMySelf || !pMySelf->GetCharacterData() || !pMySelf->CharacterLogic_GetAI())
			{
				TDU_Log("CYS-LEAP: MCT_LEAP bo qua (myself=%d data=%d ai=%d)", pMySelf ? 1 : 0,
					(pMySelf && pMySelf->GetCharacterData()) ? 1 : 0, (pMySelf && pMySelf->CharacterLogic_GetAI()) ? 1 : 0);
				break;
			}
			{
                if(pMySelf->GetCharacterData()->Get_MountID()!=INVALID_ID) { CysRideNet::ToggleFlight();break; }
				const INT idFly = pMySelf->GetCharacterData()->GetDefaultFlySkillID();
				TDU_Log("CYS-LEAP: MCT_LEAP kich hoat, skill=%d dich=(%.1f,%.1f)", (int)idFly, cmd.m_afParam[0], cmd.m_afParam[1]);
				pMySelf->CharacterLogic_GetAI()->PushCommand_Fly(idFly, cmd.m_afParam[0], cmd.m_afParam[1]);
			}
		}
		break;
	case SCommand_Mouse::MCT_CATCH_PET:
		{
			CGameProcedure::s_pGameInterface->Player_UseSkill( cmd.m_adwParam[0], int( cmd.m_adwParam[1] ) );
		}
		break;
	default:
		AxTrace(0, 0, "Active: ERROR!(%d)", cmd.m_typeMouse);
		break;
	}
}

namespace
{


















































	struct SCursorResourceMap
	{
		ENUM_CURSOR_TYPE	nType;
		WORD				wGLResourceId;		// client_GL art (resource.h, IDC_CURSOR_GL_*)
		WORD				wLegacyResourceId;	// 0.85 Res\*.cur fallback (0 = 0.85 never had real art for this type either)
	};

	const SCursorResourceMap g_aCursorResourceMap[] =
	{

		{ CURSOR_NORMAL,       IDC_CURSOR_GL_NORMAL,      IDC_CURSOR_NORMAL      }, // MEDIUM  id129 - first real slot right after IDC_ARROW; themed flame/scroll art, not a plain arrow
		{ CURSOR_ATTACK,       IDC_CURSOR_GL_ATTACK,      IDC_CURSOR_ATTACK      }, // HIGH    id130 - sword
		{ CURSOR_AUTORUN,      IDC_CURSOR_GL_AUTORUN,     IDC_CURSOR_AUTORUN     }, // LOW     id155 - assigned by elimination (flame-like art)
		{ CURSOR_PICKUP,       IDC_CURSOR_GL_PICKUP,      IDC_CURSOR_PICKUP      }, // HIGH    id135 - open glove/hand
		{ CURSOR_UNREACHABLE,  IDC_CURSOR_GL_UNREACHABLE, IDC_CURSOR_UNREACHABLE }, // HIGH    id136 - red "X"
		{ CURSOR_MINE,         IDC_CURSOR_GL_MINE,        IDC_CURSOR_MINE        }, // HIGH    id138 - pickaxe
		{ CURSOR_HERBS,        IDC_CURSOR_GL_HERBS,       IDC_CURSOR_HERBS       }, // HIGH    id139 - sickle/scythe
		{ CURSOR_FISH,         IDC_CURSOR_GL_FISH,        0                      }, // LOW     id137 - assigned by elimination (pouch/sack art); 0.85 never had real FISH art either
		{ CURSOR_SPEAK,        IDC_CURSOR_GL_SPEAK,       IDC_CURSOR_SPEAK       }, // HIGH    id141 - chat bubble
		{ CURSOR_INTERACT,     IDC_CURSOR_GL_INTERACT,    IDC_CURSOR_INTERACT    }, // MEDIUM  id150 - open hand reaching
		{ CURSOR_REPAIR,       IDC_CURSOR_GL_REPAIR,      IDC_CURSOR_REPAIR      }, // HIGH    id145 - hammer/mallet
		{ CURSOR_HOVER,        IDC_CURSOR_GL_HOVER,       IDC_CURSOR_HOVER       }, // MEDIUM  id140 - second glove/hand variant, same style as PICKUP
		{ CURSOR_IDENTIFY,     IDC_CURSOR_GL_IDENTIFY,    IDC_CURSOR_IDENFITY    }, // HIGH    id149 - eye
		{ CURSOR_ADDFRIEND,    IDC_CURSOR_GL_ADDFRIEND,   0                      }, // HIGH    id151 - dove; 0.85 never had real ADDFRIEND art either
		{ CURSOR_EXCHANGE,     IDC_CURSOR_GL_EXCHANGE,    0                      }, // HIGH    id153 - coins; 0.85 never had real EXCHANGE art either
		{ CURSOR_CATCH_PET,    IDC_CURSOR_GL_CATCH_PET,   0                      }, // MEDIUM  id154 - claw/hook; 0.85 never had real CATCH_PET art either
	};

	// CYS -- guarantee a non-NULL HCURSOR: try the client_GL resource,
	// then the 0.85 legacy resource, then the system arrow. This is the
	// actual fix for the reported bug -- a NULL anywhere in this chain
	// used to reach m_hCursor[]/::SetCursor() silently. Never add a path
	// through this function that can return NULL.
	HCURSOR LoadCursorSafe(HINSTANCE hInstance, WORD wGLResourceId, WORD wLegacyResourceId)
	{
		HCURSOR hCursor = NULL;
		LPCSTR pszStage = "none";
		if (wGLResourceId != 0)
		{
			hCursor = ::LoadCursorW(hInstance, MAKEINTRESOURCEW(wGLResourceId));
			if (hCursor) pszStage = "gl";
		}
		if (!hCursor && wLegacyResourceId != 0)
		{
			hCursor = ::LoadCursorW(hInstance, MAKEINTRESOURCEW(wLegacyResourceId));
			if (hCursor) pszStage = "legacy";
		}
		if (!hCursor)
		{
			hCursor = ::LoadCursor(hInstance, IDC_ARROW);
			if (hCursor) pszStage = "arrow(hInst)";
		}
		if (!hCursor)
		{
			// CYS: last-resort form MSDN documents as always valid (NULL
			// hInstance for a predefined cursor id); should be unreachable.
			hCursor = ::LoadCursor(NULL, IDC_ARROW);
			if (hCursor) pszStage = "arrow(NULL)";
		}
		(VOID)pszStage; // CYS: kept for a debugger watch/breakpoint condition; no logging in the shipped build (see HANDOFF.md's open-issue note on why file-based logging did not work for verifying this path).
		return hCursor;
	}
}

VOID CCursorMng::Initial( VOID * pHandle)
{
	// CYS: called as s_pCursorMng->Initial(&g_hInstance) (GameProcedure.cpp),
	// so hInstance here and g_hInstance (Global.h) are always the same value.
	HINSTANCE hInstance = *( ( HINSTANCE*) pHandle );

	// CYS: MAKEINTRESOURCE(IDC_ARROW) cast the IDC_ARROW pointer to WORD (C4302 on x64); IDC_ARROW already is
	// CYS: MAKEINTRESOURCE(32512), so passing it directly is the identical value.
	m_hCursor[ CURSOR_WINBASE ] = ::LoadCursor(hInstance, IDC_ARROW);
	if (!m_hCursor[ CURSOR_WINBASE ])
	{
		m_hCursor[ CURSOR_WINBASE ] = ::LoadCursor(NULL, IDC_ARROW);	// CYS: never store a NULL cursor
	}

	for (INT i = 0; i < (INT)(sizeof(g_aCursorResourceMap) / sizeof(g_aCursorResourceMap[0])); ++i)
	{
		const SCursorResourceMap& rMap = g_aCursorResourceMap[i];
		m_hCursor[ rMap.nType ] = LoadCursorSafe(hInstance, rMap.wGLResourceId, rMap.wLegacyResourceId);
	}

	// CYS-ROBUST: re-assert the window class's cursor now that the real
	// GL handle is known, in case CreateMainWnd's own initial resource
	// load (GameProcedure.cpp, tagged "// CYS: cursor") ever disagrees
	// with this one -- e.g. a future edit changes one but not the other.
	ApplyCursorRobust(m_hCursor[ CURSOR_NORMAL ]);

	// CYS-DIAG-CURSORTEST: temporary, offline-only proof that SetCursor()
	// generalizes beyond CURSOR_NORMAL (e.g. CURSOR_ATTACK/PICKUP/SPEAK,
	// normally only reachable in-world) without needing a real login.
	// Opt-in via env var so it never fires unless explicitly requested;
	// remove this block once verified. Runs synchronously here (Initial()
	// completes well before the verifier's own settle wait), so the test
	// type is already the active, steady-state cursor by the time anyone
	// samples it -- no extra delay needed.
	{
		CHAR szType[8] = {0};
		if (::GetEnvironmentVariableA("CYS_CURSOR_TEST_TYPE", szType, sizeof(szType)) > 0)
		{
			INT nTestType = atoi(szType);
			if (nTestType > CURSOR_WINBASE && nTestType < CURSOR_NUMBER)
			{
				SetCursor((ENUM_CURSOR_TYPE)nTestType);
			}
		}
	}
}

// CYS-LEAP: khinh cong (MCT_LEAP) chi duoc "len dan" trong MouseCommand_Set va chi "bop co" o EVENT_MOUSE_LBUP.
// Giua hai buoc do khong co mot dong log nao, nen mot luot do am tinh khong phan biet duoc 5 nguyen nhan khac han
// nhau: chuot roi vao UI / khong co action mac dinh / Ctrl khong xuong / nhanh MOVETO khong doc Ctrl / PushCommand_Fly
// tu choi. Bo vet duoi day in MOT dong moi khi QUYET DINH doi (khong phai moi khung hinh), du de mot luot GUI tra loi.
// Bit phu tro cua du an: 1 = Ctrl, 2 = Alt, 4 = Shift (xem CysHost_Accel_Table.inc / host-2).
namespace
{
	void CysLeapTraceDecision(const char* szWhere, BOOL bCtrlDown, INT nType, FLOAT fX, FLOAT fZ)
	{
		static const char*	s_szPrevWhere	= NULL;
		static INT			s_nPrevType		= -1;
		static BOOL			s_bPrevCtrl		= -1;
		if(s_szPrevWhere == szWhere && s_nPrevType == nType && s_bPrevCtrl == bCtrlDown) return;
		s_szPrevWhere	= szWhere;
		s_nPrevType		= nType;
		s_bPrevCtrl		= bCtrlDown;
		TDU_Log("CYS-LEAP: MouseCommand_Set %s ctrl=%d -> left=%d (%s) at (%.1f,%.1f)", szWhere, (int)(bCtrlDown ? 1 : 0),
			(int)nType, nType == SCommand_Mouse::MCT_LEAP ? "MCT_LEAP" : "MCT_PLAYER_MOVETO", fX, fZ);
	}
}

VOID CCursorMng::MouseCommand_Set(BOOL bHoverInUI, CObject* pSelectObj, const fVector3& fvPos, tActionItem* pActiveSkill)
{
	m_cmdCurrent_Left.m_typeMouse	= SCommand_Mouse::MCT_NULL;
	m_cmdCurrent_Right.m_typeMouse	= SCommand_Mouse::MCT_NULL;
	BOOL bCtrlDown = CInputSystem::GetMe()->IsKeyDown(KC_LCONTROL) || CInputSystem::GetMe()->IsKeyDown(KC_RCONTROL);
    // Mounted flight takes priority over a selected ground-target skill. UI clicks
    // retain their normal meaning; the native gesture is Ctrl + left on the world.
    auto rider=CObjectManager::GetMe()->GetMySelf();
    if(!bHoverInUI && !pSelectObj && bCtrlDown && rider && rider->GetCharacterData()->Get_MountID()!=INVALID_ID) {
        m_cmdCurrent_Left.m_typeMouse=SCommand_Mouse::MCT_LEAP;
        m_cmdCurrent_Left.m_afParam[0]=fvPos.x;m_cmdCurrent_Left.m_afParam[1]=fvPos.z;return;
    }

	//在UI上空
	if(bHoverInUI)
	{
		if(!pActiveSkill) return;

		switch(pActiveSkill->GetType())
		{
		//修理装备
		case AOT_MOUSECMD_REPARE:
			{
				//左键挂锤子
				m_cmdCurrent_Left.m_typeMouse  = SCommand_Mouse::MCT_REPAIR;
				//右键取消
				m_cmdCurrent_Right.m_typeMouse = SCommand_Mouse::MCT_CANCLE_REPAIR;		
			}
			break;

		//鉴定装备
		case AOT_MOUSECMD_IDENTIFY:
			{
				//左键鉴定
				m_cmdCurrent_Left.m_typeMouse  = SCommand_Mouse::MCT_UI_USE_IDENTIFY;
				//右键取消
				m_cmdCurrent_Right.m_typeMouse = SCommand_Mouse::MCT_UI_USE_CANCEL_IDENTIFY;		
			}
			break;

		case AOT_MOUSECMD_ADDFRIEND:
			{
				//左键鉴定
				m_cmdCurrent_Left.m_typeMouse  = SCommand_Mouse::MCT_UI_USE_ADDFRIEND;
				//右键取消
				m_cmdCurrent_Right.m_typeMouse = SCommand_Mouse::MCT_UI_USE_CANCEL_ADDFRIEND;		
			}
			break;
		case AOT_MOUSECMD_EXCHANGE:
			{
				//左键鉴定
				m_cmdCurrent_Left.m_typeMouse  = SCommand_Mouse::MCT_UI_USE_EXCHANGE;
				//右键取消
				m_cmdCurrent_Right.m_typeMouse = SCommand_Mouse::MCT_UI_USE_CANCEL_EXCHANGE;		
			}
			break;
		case AOT_MOUSECMD_SALE:
			{
				//左键鉴定
				m_cmdCurrent_Left.m_typeMouse  = SCommand_Mouse::MCT_SALE;
				//右键取消
				m_cmdCurrent_Right.m_typeMouse = SCommand_Mouse::MCT_CANCEL_SALE;		
			}
			break;
		case AOT_MOUSECMD_BUYMULT:
			{
				//左键鉴定
				m_cmdCurrent_Left.m_typeMouse  = SCommand_Mouse::MCT_BUYMULT;
				//右键取消
				m_cmdCurrent_Right.m_typeMouse = SCommand_Mouse::MCT_CANCEL_BUYMULT;		
			}
			break;

		default:
			break;
		}
	}
	else
	{

		//计算相应obj鼠标指令
		if ( pSelectObj != NULL )
		{
			pSelectObj->FillMouseCommand_Left( &m_cmdCurrent_Left, pActiveSkill );
			pSelectObj->FillMouseCommand_Right( &m_cmdCurrent_Right, pActiveSkill );
		}

		if ( m_cmdCurrent_Left.m_typeMouse == SCommand_Mouse::MCT_NULL )
		{
			if ( pActiveSkill != NULL )
			{
				switch(pActiveSkill->GetType())
				{
				case AOT_SKILL:
				case AOT_PET_SKILL:
					{
						const void* pSkillImpl = pActiveSkill->GetImpl();
						if(!pSkillImpl)
						{
							m_cmdCurrent_Left.m_typeMouse = bCtrlDown ? SCommand_Mouse::MCT_LEAP : SCommand_Mouse::MCT_PLAYER_MOVETO;
							m_cmdCurrent_Left.m_afParam[0] = fvPos.x;
							m_cmdCurrent_Left.m_afParam[1] = fvPos.z;
							CysLeapTraceDecision("skill-no-impl", bCtrlDown, m_cmdCurrent_Left.m_typeMouse, fvPos.x, fvPos.z);	// CYS-LEAP
							return;
						}

						//选择类型
						ENUM_SELECT_TYPE typeSel = (ENUM_SELECT_TYPE)( pActiveSkill->GetType()==AOT_SKILL ? 
							((SCLIENT_SKILL*)pSkillImpl)->m_pDefine->m_nSelectType : 
							((PET_SKILL*)pSkillImpl)->m_pDefine->m_nSelectType);


						switch(typeSel)
						{
						//点选角色
						case SELECT_TYPE_CHARACTER:
							{
								m_cmdCurrent_Left.m_typeMouse = bCtrlDown ? SCommand_Mouse::MCT_LEAP : SCommand_Mouse::MCT_PLAYER_MOVETO;
								m_cmdCurrent_Left.m_afParam[0] = fvPos.x;
								m_cmdCurrent_Left.m_afParam[1] = fvPos.z;
								CysLeapTraceDecision("skill-select-character", bCtrlDown, m_cmdCurrent_Left.m_typeMouse, fvPos.x, fvPos.z);	// CYS-LEAP
							}
							break;

						//点选范围
						case SELECT_TYPE_POS:
							{
								//储存技能
								m_cmdCurrent_Left.m_typeMouse = SCommand_Mouse::MCT_SKILL_AREA;
								m_cmdCurrent_Left.m_apParam[0] = (VOID*)pActiveSkill;
								m_cmdCurrent_Left.m_afParam[1] = fvPos.x;
								m_cmdCurrent_Left.m_afParam[2] = fvPos.z;
								FLOAT fRingRange = (FLOAT)( pActiveSkill->GetType()==AOT_SKILL ? 
									((SCLIENT_SKILL*)pSkillImpl)->m_pDefine->m_fDamageRange : 
								((PET_SKILL*)pSkillImpl)->m_pDefine->m_fDamageRange);
								m_cmdCurrent_Left.m_afParam[5] = fRingRange * 100;

								//取消技能
								m_cmdCurrent_Right.m_typeMouse = SCommand_Mouse::MCT_CANCEL_SKILL;
							}
							break;
						//方向
						case SELECT_TYPE_DIR:
							{
								//储存技能
								m_cmdCurrent_Left.m_typeMouse = SCommand_Mouse::MCT_SKILL_DIR;
								m_cmdCurrent_Left.m_apParam[0] = (VOID*)pActiveSkill;
								
								//计算方向
								
								//主角位置
								fVector3 fvPlayer = CObjectManager::GetMe()->GetMySelf()->GetPosition();
								//鼠标位置
								fVector3 fvTarget = fvPos;

								m_cmdCurrent_Left.m_afParam[1] = TDU_GetYAngle(
										fVector2(fvPlayer.x, fvPlayer.z),
										fVector2(fvTarget.x, fvTarget.z));
							}
							break;
						case SELECT_TYPE_SELF:
							//ERROR...
							break;
						}
					}
					break;

				case AOT_ITEM:
					{
						if(!pActiveSkill || pActiveSkill->GetType() != AOT_ITEM) break;
						CObject_Item* pItem = (CObject_Item*)(((CActionItem_Item*)pActiveSkill)->GetItemImpl());
						if(!pItem) break;
						//必须是能够使用的物品
						if(pItem->GetItemClass() != ICLASS_COMITEM) break;

						BOOL bAreaItem = ((CObject_Item_Medicine*)pItem)->IsAreaTargetType();

						m_cmdCurrent_Left.m_typeMouse = SCommand_Mouse::MCT_USE_ITEM;
						m_cmdCurrent_Left.m_apParam[0] = (VOID*)pActiveSkill;
						m_cmdCurrent_Left.m_adwParam[1] = -1;
						m_cmdCurrent_Left.m_afParam[2] = fvPos.x;
						m_cmdCurrent_Left.m_afParam[3] = fvPos.z;
						m_cmdCurrent_Left.m_adwParam[4] = bAreaItem;

						m_cmdCurrent_Right.m_typeMouse = SCommand_Mouse::MCT_CANCEL_USE_ITEM;
					}
					break;

				//修理单独处理
				case AOT_MOUSECMD_REPARE:
					{
						//左键挂锤子
						m_cmdCurrent_Left.m_typeMouse  = SCommand_Mouse::MCT_REPAIR;
						//右键取消
						m_cmdCurrent_Right.m_typeMouse = SCommand_Mouse::MCT_CANCLE_REPAIR;		
					}
					break;

				//鉴定装备
				case AOT_MOUSECMD_IDENTIFY:
					{
						//左键鉴定
						m_cmdCurrent_Left.m_typeMouse  = SCommand_Mouse::MCT_UI_USE_IDENTIFY;
						//右键取消
						m_cmdCurrent_Right.m_typeMouse = SCommand_Mouse::MCT_UI_USE_CANCEL_IDENTIFY;		
					}
					break;
				case AOT_MOUSECMD_ADDFRIEND:
					{
						//左键鉴定
						m_cmdCurrent_Left.m_typeMouse  = SCommand_Mouse::MCT_UI_USE_ADDFRIEND;
						//右键取消
						m_cmdCurrent_Right.m_typeMouse = SCommand_Mouse::MCT_UI_USE_CANCEL_ADDFRIEND;		
					}
					break;
				case AOT_MOUSECMD_EXCHANGE:
					{
						//左键鉴定
						m_cmdCurrent_Left.m_typeMouse  = SCommand_Mouse::MCT_UI_USE_EXCHANGE;
						//右键取消
						m_cmdCurrent_Right.m_typeMouse = SCommand_Mouse::MCT_UI_USE_CANCEL_EXCHANGE;		
					}
					break;
				case AOT_MOUSECMD_CATCHPET:
					{
						m_cmdCurrent_Left.m_typeMouse = SCommand_Mouse::MCT_CATCH_PET;
						m_cmdCurrent_Left.m_afParam[0] = fvPos.x;
						m_cmdCurrent_Left.m_afParam[1] = fvPos.z;
					}
					break;
				case AOT_MOUSECMD_SALE:
					{
						//左键鉴定
						m_cmdCurrent_Left.m_typeMouse  = SCommand_Mouse::MCT_SALE;
						//右键取消
						m_cmdCurrent_Right.m_typeMouse = SCommand_Mouse::MCT_CANCEL_SALE;		
					}
					break;
				case AOT_MOUSECMD_BUYMULT:
					{
						//左键
						m_cmdCurrent_Left.m_typeMouse  = SCommand_Mouse::MCT_BUYMULT;
						//右键
						m_cmdCurrent_Right.m_typeMouse = SCommand_Mouse::MCT_CANCEL_BUYMULT;		
					}
					break;
				default:
					//移动
					{
						// CYS-LEAP: o dung CHO NAY co le thu ba quyet dinh "di chuyen toi mat dat" (hai cho kia o tren
						// nhanh AOT_SKILL/AOT_PET_SKILL). Ban 0.85 goc quen doc co Ctrl o day, nen moi action mac dinh
						// KHONG phai ky nang (vi du AOT_SKILL_LIFEABILITY) lam khinh cong chet im lang. Doc cung mot co.
						m_cmdCurrent_Left.m_typeMouse = bCtrlDown ? SCommand_Mouse::MCT_LEAP : SCommand_Mouse::MCT_PLAYER_MOVETO;
						m_cmdCurrent_Left.m_afParam[0] = fvPos.x;
						m_cmdCurrent_Left.m_afParam[1] = fvPos.z;
						CysLeapTraceDecision("action-default", bCtrlDown, m_cmdCurrent_Left.m_typeMouse, fvPos.x, fvPos.z);	// CYS-LEAP
					}
					break;
				}
			}
			else if(bCtrlDown)
			{
				// CYS-LEAP: khong co action mac dinh nao (CActionItem::~CActionItem goi Skill_SetActive(0) +
				// SetDefaultAction(0); trang thai nay ton tai that trong khoang tu luc vao the gioi toi luc danh
				// sach ky nang cua server toi). Ban goc khong gan lenh nao ca, nen khinh cong chet im lang o day.
				//
				// CO Y chi mo duong khi DANG GIU Ctrl: cay nguon nay dung chung voi nhieu nhanh khac dang do live.
				// Ctrl khong xuong => khong vao nhanh nay => hanh vi giong het truoc khi sua (lenh trai o nguyen
				// MCT_NULL). Nho vay ban va nay khong the lam nhieu phep do cua ai. Muon bit not lo hong "bam xuong
				// dat khong di chuyen" thi doi `else if(bCtrlDown)` thanh `else` - nhung do la doi hanh vi chung,
				// phai co nguoi nhan va do rieng.
				m_cmdCurrent_Left.m_typeMouse = SCommand_Mouse::MCT_LEAP;
				m_cmdCurrent_Left.m_afParam[0] = fvPos.x;
				m_cmdCurrent_Left.m_afParam[1] = fvPos.z;
				CysLeapTraceDecision("no-active-action", bCtrlDown, m_cmdCurrent_Left.m_typeMouse, fvPos.x, fvPos.z);	// CYS-LEAP
			}
		}

		//选择玩家
		if ( m_cmdCurrent_Right.m_typeMouse == SCommand_Mouse::MCT_NULL )
		{
			m_cmdCurrent_Right.m_typeMouse = SCommand_Mouse::MCT_PLAYER_SELECT;
			m_cmdCurrent_Right.m_anParam[0] = INVALID_ID;
		}
	}
}
