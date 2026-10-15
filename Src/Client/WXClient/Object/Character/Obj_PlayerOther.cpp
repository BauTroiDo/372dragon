#include "StdAfx.h"
#include "../../DataPool/CysOrnamentData.h"
#include "../../DataPool/CysWuhunData.h"
#include "../../DataPool/CysExteriorActionData.h"
#include "CysDBCAccess.h"	// CYS: client_GL DBC column accessors
#include "Obj_PlayerOther.h"
#include "..\..\Global.h"
#include "..\..\Network\NetManager.h"
#include "CGAttack.h"
#include "CGCharAskEquipment.h"
#include "..\ObjectManager.h"
#include "..\Character\Obj_PlayerMySelf.h"
#include "CGOtherEquip.h"
#include "..\..\NetWork\NetManager.h"
#include "..\..\Procedure\GameProcedure.h"
#include "TDTimeSystem.h"
#include "TDSound.h"
#include "..\ObjectDef.h"
#include "..\ActionSetMgr.h"
#include "..\..\DBC\GMDataBase.h"
#include "TDDBC_Struct.h"
#include "TDException.h"
#include "..\ObjectCommandDef.h"
#include "..\..\GameCommand.h"
#include "..\Item\Obj_Item_Equip.h"
#include "..\..\DataPool\GMDP_CharacterData.h"
#include "..\..\Event\GMEventSystem.h"
#include "TDProfile.h"
#include "AI\GMAI_Base.h"

#include "TDActionSystem.h"
#include "TDGameInterface.h"
#include "..\..\DataPool\GMDP_Struct_Skill.h"
#include "..\..\DataPool\GMDP_CharacterData.h"
#include "..\..\DataPool\GMDataPool.h"
#include "GameStruct_Skill.h"
#include "Obj_PlayerMySelf.h"
#include "..\..\Procedure\GameProcedure.h"
#include "..\WxRender\RenderSystem.h"

WX_IMPLEMENT_DYNAMIC(CObject_PlayerOther, GETCLASS(CObject_PlayerNPC));
CObject_PlayerOther::CObject_PlayerOther()
{
	m_fDebugRate	= 1.4f;
	m_pCharRace		= NULL;
}

CObject_PlayerOther::~CObject_PlayerOther()
{
}

VOID CObject_PlayerOther::Initial( VOID *pParam )
{
	CObject_PlayerNPC::Initial( pParam );

	//空手
	SetWeaponType(WEAPON_TYPE_NONE);
}

RC_RESULT CObject_PlayerOther::OnCommand(const SCommand_Object *pCmd )
{
	RC_RESULT rcResult = RC_SKIP;

	switch ( pCmd->m_wID )
	{
	case OC_UPDATE_EQUIPMENT:
		{
			UINT	dwModifyFlags	= pCmd->m_adwParam[0];
			UINT	*pData			= (UINT*)(pCmd->m_apParam[1]);
			UINT	i, dwIndex;
			dwIndex = 0;
			for ( i = 0; i < HEQUIP_NUMBER; i++ )
			{
				if ( dwModifyFlags & (1<<i) )
				{
					GetCharacterData()->Set_Equip((HUMAN_EQUIP)i, pData[dwIndex]);
					dwIndex++;
				}
			}
			rcResult = RC_OK;
		}
		break;
	case OC_UPDATE_TEAM_FLAG:
		{
			if(this != CObjectManager::GetMe()->GetMySelf())
			{
				CCharacterData* pData = GetCharacterData();
				pData->Set_HaveTeamFlag( pCmd->m_abParam[0] );
				pData->Set_TeamLeaderFlag( pCmd->m_abParam[1] );
				pData->Set_TeamFullFlag( pCmd->m_abParam[2] );
			}
			rcResult = RC_OK;
		}
		break;
	case OC_TEAM_FOLLOW_MEMBER:
		{
			CCharacterData* pData = GetCharacterData();

			pData->Set_TeamFollowListCount( pCmd->m_adwParam[0] );

			for( INT i=0; i<(INT)(pCmd->m_adwParam[0]); ++i )
			{
				pData->Set_TeamFollowedMember(i, pCmd->m_adwParam[i+1]);
			}

			rcResult = RC_OK;
		}
		break;
	case OC_UPDATE_TEAM_FOLLOW_FLAG:
		{
			CCharacterData* pData = GetCharacterData();

			pData->Set_TeamFollowFlag( pCmd->m_abParam[0] );
			CharacterLogic_GetAI()->OnAIStopped();

			rcResult = RC_OK;
		}
		break;
	default:
		return CObject_PlayerNPC::OnCommand(pCmd);
	}

	return rcResult;
}

VOID CObject_PlayerOther::OnHideWeapon(INT nAppointedWeaponID)
{
	if(nAppointedWeaponID != INVALID_ID)
	{
		EquipItem_BodyLocator( HEQUIP_WEAPON, nAppointedWeaponID);
	}
	else
	{
		//卸载装备
		UnEquipItem(HEQUIP_WEAPON);
	}
}

VOID CObject_PlayerOther::OnShowWeapon(VOID)
{
	UpdateEquip(HEQUIP_WEAPON);
}

VOID CObject_PlayerOther::RefreshPreviewWeapon(BOOL armed)
{
    if(!GetFakeObjectFlag()) return;
    ClearAllChatMoodAction();SetChatMoodActionPlaying(FALSE);
    mCysManualBackAction=false;mCysBackAction=-1;
    if(!armed) {
        SetWeaponType(WEAPON_TYPE_NONE);
        ChangeAction(BASE_ACTION_N_IDLE,1.0f,TRUE);
        UnEquipItem(HEQUIP_WEAPON);
        return;
    }
    CObject_Item* item=CObject_Item::NewItem(GetCharacterData()->Get_Equip(HEQUIP_WEAPON));
    CObject_Item_Equip* equip=item && item->GetItemClass()==ICLASS_EQUIP ? (CObject_Item_Equip*)item : NULL;
    const int visual=equip?equip->GetVisualID():-1;
    const int point=equip?(int)equip->GetItemType():-1;
    SetWeaponType(equip ? equip->GetWeaponType() : WEAPON_TYPE_NONE);
    CObject_Item::DestroyItem(item);
    ChangeAction(BASE_ACTION_F_IDLE,1.0f,TRUE);
    // CY cosmetic weapons use EquipBase point 22, so UpdateEquip's ordinary
    // equipment switch never attaches them. The fake actor still uses the
    // native hand locators and materials from ItemVisualLocator.
    if(!IsHideWeapon() && visual>=0 && (point==HEQUIP_WEAPON || point==22))
        EquipItem_BodyLocator(HEQUIP_WEAPON,visual);
    else UnEquipItem(HEQUIP_WEAPON);
    if(m_pRenderInterface) m_pRenderInterface->Actor_SetUIVisibleFlag();
}

BOOL CObject_PlayerOther::PlayExteriorAction(INT category,INT id,INT index)
{
    if(!GetFakeObjectFlag() || !m_pRenderInterface) return FALSE;
    const auto action=CysExteriorActionData::Find(category,id,index);
    if(!action) return FALSE;
    if(category==7) {
        if(GetCharacterData()->Get_Equip(HEQUIP_WEAPON)!=action->item) return FALSE;
        STRING order=action->order;SetChatMoodAction(order);
        if(!IsHaveChatMoodAction()) return FALSE;
        PlayChatMoodAction();
    } else if(category==6) {
        if(GetCharacterData()->Get_OrnamentId(1)!=10000+id) return FALSE;
        mCysManualBackAction=true;
        m_pRenderInterface->Actor_SetObjectProperty("CysBackAction",action->order);
    } else return FALSE;
    TDU_Log("CYS-EXTERIOR-ACTION: cat=%d id=%d index=%d order=%s",category,id,index,action->order);
    return TRUE;
}

VOID CObject_PlayerOther::SyncAppearanceAction(INT action)
{
    if(!m_pRenderInterface || GetCharacterData()->Get_ModelID()!=-1) return;
    const auto row=CysOrnamentData::Find(6,GetCharacterData()->Get_OrnamentId(1));
    if(!row || !row->idle[0][0]) return;
    // Back ornaments distinguish standing and the two authored idle motions.
    // Locomotion/combat cancels rest without changing the character's action.
    int group=action==BASE_ACTION_N_IDLE_EX0?1:action==BASE_ACTION_N_IDLE_EX1?2:0;
    if(mCysManualBackAction && action==BASE_ACTION_N_IDLE) return;
    mCysManualBackAction=false;
    if(mCysBackAction==group) return;
    mCysBackAction=group;
    m_pRenderInterface->Actor_SetObjectProperty("CysBackAction",row->idle[group]);
}

// CYS: creation/select UI uses DATA CY appearance recipes, bypassing
// legacy CharModel/ItemVisual record overlays. Object lifetime remains native.
BOOL CObject_PlayerOther::InitializeCreationPreview(const char* objectFile)
{
    if (!GetFakeObjectFlag() || !objectFile || !objectFile[0] || !CGameProcedure::s_pGfxSystem)
        return FALSE;
    if (!m_pRenderInterface)
    {
        m_pRenderInterface = CGameProcedure::s_pGfxSystem->New_EntityObject(tEntityNode::ETYPE_ACTOR);
        if (!m_pRenderInterface) return FALSE;
        m_pRenderInterface->SetData(GetID());
    }
    // The render object's named property avoids rebuilding an unchanged template,
    // and allows a reused selection slot to display a different sex correctly.
    m_pRenderInterface->Actor_SetFile(objectFile);
    // The RTT hook moves only the renderer to its origin; the generic fake
    // object still starts at logical (100,100,100). Keep both in the UI scene
    // so refreshing an already hooked face/hair/outfit cannot move it away.
    SetPosition(fVector3(0.0f, 0.0f, 0.0f));
    CObject_Character::CreateRenderInterface();
    SetFaceDir(GetFaceDir());
    return TRUE;
}

VOID CObject_PlayerOther::CreateRenderInterface(VOID)
{
	if(m_pCharRace != NULL)
	{
		//模型定义
		DBC_DEFINEHANDLE(s_pCharModelDBC, DBC_CHARACTER_MODEL)

		LPCSTR lpszModelFileName = NULL;
		INT nModelID = GetCharModelID();
		const _DBC_CHARACTER_MODEL *pCharModel = (const _DBC_CHARACTER_MODEL*)(s_pCharModelDBC->Search_Index_EQU(nModelID));
		if(pCharModel != NULL)
		{
			lpszModelFileName = pCharModel->m_pszModelName;
		}

		if(lpszModelFileName != NULL)
		{
			m_pRenderInterface = CGameProcedure::s_pGfxSystem->New_EntityObject(tEntityNode::ETYPE_ACTOR);
			m_pRenderInterface->SetData(GetID());

			//设置ActorFile
			m_pRenderInterface->Actor_SetFile( lpszModelFileName );

			if (GetConstCharacterData()->Get_ModelID() == -1)
			{
				UpdateFaceMesh();
				UpdateHairMesh();
				UpdateHairColor();

				//重新刷新装备
				UpdateEquip( HEQUIP_WEAPON );
				UpdateEquip( HEQUIP_CAP );
				UpdateEquip( HEQUIP_ARMOR );
				UpdateEquip( HEQUIP_CUFF );
				UpdateEquip( HEQUIP_BOOT );
				UpdateEquip( HEQUIP_SASH );
                UpdateOrnaments();
                UpdateWuhun();
				UpdateDress();					// CYS-DRESS: bo do de len ARMOR/CUFF/BOOT vua dat o tren
			}

			SendEuipRequest();
		}
	}
	CObject_Character::CreateRenderInterface();
}

//发出请求更详细信息的请求
VOID CObject_PlayerOther::SendEuipRequest(VOID)
{
	if(GetServerID() == -1) return;

	CGCharAskEquipment msg;
	msg.setObjID((ObjID_t)GetServerID());

	CNetManager::GetMe()->SendPacket(&msg);
}

// 左键指令的分析
BOOL CObject_PlayerOther::FillMouseCommand_Left( SCommand_Mouse *pOutCmd, tActionItem* pActiveSkill )
{
	pOutCmd->m_typeMouse = SCommand_Mouse::MCT_NULL;

	//是物品
	if(pActiveSkill && pActiveSkill->GetType() == AOT_ITEM)
	{
		//鼠标上挂的是一个物品
		return CObject_PlayerNPC::FillMouseCommand_Left(pOutCmd, pActiveSkill);
	}
	else
	{
		ENUM_RELATION eCampType = CGameProcedure::s_pGameInterface->GetCampType( CObjectManager::GetMe()->GetMySelf(), this );
		switch ( eCampType )
		{
		case RELATION_FRIEND:
			{
				if ( pActiveSkill != NULL
					&& pActiveSkill->GetType() == AOT_MOUSECMD_ADDFRIEND )
				{
					pOutCmd->m_typeMouse  = SCommand_Mouse::MCT_UI_USE_ADDFRIEND;
					pOutCmd->m_adwParam[0] = GetServerID();
				}
				else 
				if ( pActiveSkill != NULL
					&& pActiveSkill->GetType() == AOT_MOUSECMD_EXCHANGE )
				{
					pOutCmd->m_typeMouse  = SCommand_Mouse::MCT_UI_USE_EXCHANGE;
					pOutCmd->m_adwParam[0] = GetServerID();
				}
				break;
			}
		case RELATION_ENEMY:
		default:
			{
				if ( pActiveSkill != NULL
					&& pActiveSkill->GetType() == AOT_SKILL )
				{
					const SCLIENT_SKILL* pSkillImpl = (const SCLIENT_SKILL*)pActiveSkill->GetImpl();
					if(pSkillImpl != NULL
						&& pSkillImpl->m_pDefine->m_nSelectType == SELECT_TYPE_CHARACTER)
					{
						pOutCmd->m_typeMouse = SCommand_Mouse::MCT_SKILL_OBJ;
						pOutCmd->m_apParam[0] = (VOID*)pActiveSkill;
						pOutCmd->m_adwParam[1] = GetServerID();
					}
				}
			}
			break;
		}
	}
	return TRUE;
}

// 右键指令的分析
BOOL CObject_PlayerOther::FillMouseCommand_Right( SCommand_Mouse *pOutCmd, tActionItem* pActiveSkill )
{
	pOutCmd->m_typeMouse = SCommand_Mouse::MCT_NULL;
	ENUM_RELATION eCampType = CGameProcedure::s_pGameInterface->GetCampType( CObjectManager::GetMe()->GetMySelf(), this );
	switch ( eCampType )
	{
	case RELATION_FRIEND:
		{
			pOutCmd->m_typeMouse	= SCommand_Mouse::MCT_CONTEXMENU;
			pOutCmd->m_adwParam[0]	= GetServerID();
		}
		break;
	case RELATION_ENEMY:
	default:
		{
			pOutCmd->m_typeMouse	= SCommand_Mouse::MCT_PLAYER_SELECT;
			pOutCmd->m_adwParam[0]	= GetServerID();
		}
		break;
	}
	return TRUE;
}

VOID CObject_PlayerOther::Debug_ChangeSpeed(FLOAT fStep)
{
	FLOAT fSpeed = GetCharacterData()->Get_MoveSpeed() + fStep;

	if(fSpeed < 0.0f) fSpeed = 0.0f;
	if(fSpeed > 10.0f) fSpeed = 10.0f;

	GetCharacterData()->Set_MoveSpeed(fSpeed);
}

VOID CObject_PlayerOther::Debug_ChangeRate(FLOAT fStep)
{
	//FLOAT fRate = m_fDebugRate + fStep;

	//if(fRate < 0.0f) fRate = 0.0f;
	//if(fRate > 3.0f) fRate = 3.0f;

	//m_fDebugRate = fRate;

	//CHAR szTemp[8];
	//_snprintf(szTemp, 8, "%.2f", m_fDebugRate);
	//if(m_pRenderInterface)
	//	m_pRenderInterface->Actor_SetObjectProperty("RunSpeed", szTemp);
}

VOID CObject_PlayerOther::OnDataChanged_Equip(HUMAN_EQUIP point)
{
	UpdateEquip(point);
    if(point==HEQUIP_WEAPON && IsIdle()) FreshAnimation();
}

// CYS-DRESS: 时装 (装备点 16). Server gui o nay trong GCCharEquipment (flag bit 0x10000, scenecore.lua
// broad_char_equioment -> set_fasion); `visual` la CHI SO EquipDress, khong phai id ItemVisualChar.
VOID CObject_PlayerOther::OnDataChanged_Dress(VOID)
{
	UpdateDress();
}

BOOL CObject_PlayerOther::IsDressWorn(VOID) const
{
	const CCharacterData* pCharacterData = GetConstCharacterData();
	if(!pCharacterData || pCharacterData->Get_DressVisual()==INVALID_ID) return FALSE;
	DBC_DEFINEHANDLE(s_pDress, DBC_ITEM_EQUIP_DRESS);
	const auto dress=(const _DBC_ITEM_EQUIP_DRESS*)s_pDress->Search_Index_EQU(pCharacterData->Get_DressVisual());
	if(!dress) return FALSE;
	DBC_DEFINEHANDLE(s_pVisual, DBC_ITEM_VISUAL_CHAR);
	const auto visual=(const _DBC_ITEM_VISUAL_CHAR*)s_pVisual->Search_Index_EQU(dress->nVisualID);
	const char* mesh=CysItemVisualEntity(visual,pCharacterData->Get_RaceID(),0);
	return mesh && *mesh && strcmp(mesh,"-1")!=0;
}

namespace {
const char* CysDressEffects(int visual,int sex) {
    static std::map<std::pair<int,int>,std::string> effects;
    static bool loaded=false;
    if(!loaded) {
        loaded=true; DBC::DBCFile dbc(0);
        if(CDataBase::Util_OpenDBCFromTxt("SpecialDressEffect.txt",&dbc) && dbc.GetFieldsNum()==5)
            for(int i=0;i<(int)dbc.GetRecordsNum();++i) for(int gender=0;gender<2;++gender) {
                auto value=dbc.Search_Posistion(i,1+gender)->pString;
                if(value && *value && strcmp(value,"-1")!=0)
                    effects[{dbc.Search_Posistion(i,0)->iValue,gender}]=value;
            }
    }
    auto found=effects.find({visual,sex});return found==effects.end()?"":found->second.c_str();
}
}

VOID CObject_PlayerOther::UpdateDress(VOID)
{
	if(m_pRenderInterface == NULL)
	{
		return;
	}
	CCharacterData *pCharacterData = GetCharacterData();
	if(pCharacterData == NULL)
	{
		return ;
	}
	//变身状态 (ModelID) khong dung ngoai hinh trang bi — giong UpdateEquip
	if(!GetFakeObjectFlag())
	{
		if(pCharacterData->Get_ModelID() != INVALID_ID)
		{
			return ;
		}
	}

	const INT nDressVisual = pCharacterData->Get_DressVisual();
    m_pRenderInterface->Actor_SetObjectProperty("CysDressEffects",CysDressEffects(nDressVisual,pCharacterData->Get_RaceID()));
	const _DBC_ITEM_EQUIP_DRESS* pDress = NULL;
	const _DBC_ITEM_VISUAL_CHAR* pVisual = NULL;
	if(nDressVisual != INVALID_ID)
	{
		//-----------------------------------------------------------
		//时装外形数据库: EquipBase.Visual -> EquipDress -> ItemVisualChar
		DBC_DEFINEHANDLE(s_pEquipDress, DBC_ITEM_EQUIP_DRESS);
		pDress = (const _DBC_ITEM_EQUIP_DRESS*)s_pEquipDress->Search_Index_EQU(nDressVisual);
		if(pDress != NULL)
		{
			DBC_DEFINEHANDLE(s_pEquipItem, DBC_ITEM_VISUAL_CHAR);
			pVisual = (const _DBC_ITEM_VISUAL_CHAR*)s_pEquipItem->Search_Index_EQU(pDress->nVisualID);
		}
	}

	if(pVisual == NULL || !IsDressWorn())
	{
		//không mặc thời trang (hoặc dòng bảng thiếu): trả ba ô thân về trang bị thường
		UpdateEquip(HEQUIP_ARMOR);
		UpdateEquip(HEQUIP_CUFF);
		UpdateEquip(HEQUIP_BOOT);
		return;
	}

	INT nRaceID = pCharacterData->Get_RaceID();
	TDAssert(nRaceID >= 0 && nRaceID<CHAR_RACE_NUM);
	if(nRaceID < 0 || nRaceID >= CHAR_RACE_NUM)
	{
		return ;
	}

	// Mesh thời trang là mesh TRỌN THÂN — đo trên dữ liệu CY: hộp bao của 女主角少林中级.mesh là
	// x[-78.4,78.4] y[-1.4,158.9], đúng bằng hợp của 衣服 (x±45.9, y 20..158.6) + 护腕 (x±78.4) +
	// 靴子 (y -0.3..44.2). Vì vậy ô tay và ô chân phải bị ẩn, nếu không tay/giày thường sẽ đâm xuyên.
	m_pRenderInterface->Actor_SetObjectProperty(szIDSTRING_MAINBODY_MESH, CysItemVisualEntity(pVisual, nRaceID, 0));
	m_pRenderInterface->Actor_SetObjectProperty(szIDSTRING_MAINBODY_MAT, CysDressMaterial(pVisual, nRaceID, pDress->nDyeSlot));
	m_pRenderInterface->Actor_SetObjectProperty(szIDSTRING_ARM_MESH, "");
	m_pRenderInterface->Actor_SetObjectProperty(szIDSTRING_ARM_MAT, "");
	m_pRenderInterface->Actor_SetObjectProperty(szIDSTRING_FOOT_MESH, "");
	m_pRenderInterface->Actor_SetObjectProperty(szIDSTRING_FOOT_MAT, "");

	//如果是UI物体，重新设置VisibleFlag
	if(GetFakeObjectFlag())
	{
		m_pRenderInterface->Actor_SetUIVisibleFlag();
	}
}

VOID CObject_PlayerOther::UpdateFaceMesh(VOID)
{
	if(m_pRenderInterface != NULL)
	{
		INT nFaceMeshID = GetCharacterData()->Get_FaceMesh();
		if(nFaceMeshID == INVALID_ID)
		{
			nFaceMeshID = m_pCharRace->nDefHeadGeo;
		}
		if(nFaceMeshID != INVALID_ID)
		{
			//-----------------------------------------------------------
			//角色头部模型数据库
			DBC_DEFINEHANDLE(s_pCharHeadGeo, DBC_CHARACTER_HEAD_GEO);
			//查找相应记录
			const _DBC_CHAR_HEAD_GEO* pFaceGeo = (const _DBC_CHAR_HEAD_GEO* )s_pCharHeadGeo->Search_Index_EQU(nFaceMeshID);
			if(pFaceGeo != NULL)
			{
				m_pRenderInterface->Actor_SetObjectProperty(szIDSTRING_FACE_MESH, pFaceGeo->pMeshFile);
			}
			else
			{
				m_pRenderInterface->Actor_SetObjectProperty(szIDSTRING_FACE_MESH, "");
			}

			//如果是UI物体，重新设置VisibleFlag
			if(GetFakeObjectFlag())
			{
				m_pRenderInterface->Actor_SetUIVisibleFlag();
			}
		}
	}
}

VOID CObject_PlayerOther::UpdateHairMesh(VOID)
{
	if(m_pRenderInterface != NULL)
	{
		INT nHairMesh = GetCharacterData()->Get_HairMesh();
		if(nHairMesh == INVALID_ID)
		{
			nHairMesh = m_pCharRace->nDefHairGeo;
		}
		if(nHairMesh != INVALID_ID)
		{
			//-----------------------------------------------------------
			//角色头发模型数据库
			DBC_DEFINEHANDLE(s_pCharHairMesh, DBC_CHARACTER_HAIR_GEO);
			//查找相应记录
			const _DBC_CHAR_HAIR_GEO* pHairMesh = (const _DBC_CHAR_HAIR_GEO*)s_pCharHairMesh->Search_Index_EQU(nHairMesh);
			if(pHairMesh != NULL)
			{
				m_pRenderInterface->Actor_SetObjectProperty(szIDSTRING_HAIR_MESH, pHairMesh->pMeshFile);
			}
			else
			{
				m_pRenderInterface->Actor_SetObjectProperty(szIDSTRING_HAIR_MESH, "");
			}
			//如果是UI物体，重新设置VisibleFlag
			if(GetFakeObjectFlag())
			{
				m_pRenderInterface->Actor_SetUIVisibleFlag();
			}
		}
	}
}

VOID CObject_PlayerOther::UpdateHairColor(VOID)
{
	//-----------------------------------------------------------
	//渲染层设置
	if(m_pRenderInterface)
	{
		UINT uHairColor = GetCharacterData()->Get_HairColor();
		m_pRenderInterface->Actor_SetHairColor(uHairColor);
	}
}

VOID CObject_PlayerOther::UpdateOrnaments()
{
    mCysBackAction=-1;mCysManualBackAction=false;
    auto data=GetConstCharacterData();
    if(!m_pRenderInterface || !data || data->Get_ModelID()!=-1) return;
    int sex=data->Get_RaceID()==0?0:1;
    for(int slot=0;slot<2;++slot) {
        const auto r=CysOrnamentData::Find(slot+5,data->Get_OrnamentId(slot));
        const char* property=slot==0?"HeadOrnamentsObj":"BackOrnamentsObj";
        const char* model=r?r->model[sex]:"";
        STRING previous;
        m_pRenderInterface->Actor_GetObjectProperty(property,previous);
        if(previous!=model) m_pRenderInterface->Actor_SetObjectProperty(property,model);
        if(r) {
            int pos=data->Get_OrnamentPos(slot);
            char offset[128];
            _snprintf(offset,sizeof(offset),"%.6f %.6f %.6f",(((pos>>0)&255)-128)*r->step[sex][0],(((pos>>8)&255)-128)*r->step[sex][1],(((pos>>16)&255)-128)*r->step[sex][2]);
            m_pRenderInterface->Actor_SetObjectProperty(slot==0?"CysOrnamentHeadOffset":"CysOrnamentBackOffset",offset);
        }
    }
}

VOID CObject_PlayerOther::OnDataChanged_Wuhun() { UpdateWuhun(); }
VOID CObject_PlayerOther::UpdateWuhun()
{
    if(!m_pRenderInterface) return;
    auto data=GetConstCharacterData();
    const auto visual=data && data->Get_ModelID()==-1 && data->Get_WuhunItem()>0
        ? CysWuhunData::Find(data->Get_WuhunVisual()):nullptr;
    const char* model=visual?visual->object:"";
    STRING previous;m_pRenderInterface->Actor_GetObjectProperty("KFSObj",previous);
    if(previous!=model) m_pRenderInterface->Actor_SetObjectProperty("KFSObj",model);
    // Only the new support item moves to the character's right; legacy KFS placement is unchanged.
    m_pRenderInterface->Actor_SetObjectProperty("CysSoulSupportOffset",data&&data->Get_WuhunItem()==10156901?"-100 -35 0":"0 0 0");
    const auto assault=data && data->Get_ModelID()==-1 && data->Get_AssaultItem()>0
        ? CysWuhunData::Find(data->Get_AssaultVisual()):nullptr;
    const char* other=assault?assault->object:"";
    m_pRenderInterface->Actor_GetObjectProperty("BattleSoulObj",previous);
    if(previous!=other) m_pRenderInterface->Actor_SetObjectProperty("BattleSoulObj",other);
    if(GetFakeObjectFlag()) m_pRenderInterface->Actor_SetUIVisibleFlag();
}

VOID CObject_PlayerOther::UpdateEquip(HUMAN_EQUIP point)
{
    if(!m_pRenderInterface) return; // Appearance packets may precede fake-avatar render creation.
	CCharacterData *pCharacterData = GetCharacterData();
	if(pCharacterData == NULL)
	{
		return ;
	}

	// CYS-DRESS: dang mac thoi trang thi bo do DE LEN giap/tay/giay — neu khong, mot goi
	// GCCharEquipment cua giap thuong se ghi de mesh bo do va nhan vat tro lai do mac dinh.
	if((point == HEQUIP_ARMOR || point == HEQUIP_CUFF || point == HEQUIP_BOOT) && IsDressWorn())
	{
		return ;
	}

	if(!GetFakeObjectFlag())
	{
		if(pCharacterData->Get_ModelID() != INVALID_ID)
		{
			return ;
		}
	}

	//生成一个临时的Item对象
	CObject_Item_Equip *pTempEquip = NULL;
	INT nID = point==HEQUIP_WEAPON && !GetFakeObjectFlag() ? pCharacterData->Get_WeaponAppearance() : pCharacterData->Get_Equip(point);
	if(nID != INVALID_ID)
	{
		pTempEquip = (CObject_Item_Equip *)CObject_Item::NewItem(nID);
	}
    if(point==HEQUIP_WEAPON) {
        SetWeaponType(pTempEquip && pTempEquip->GetItemClass()==ICLASS_EQUIP ? pTempEquip->GetWeaponType() : WEAPON_TYPE_NONE);
        if(IsHideWeapon()) { CObject_Item::DestroyItem(pTempEquip);return; }
    }

	//如果是装备根据装配点装备物品
	if(pTempEquip != NULL && ICLASS_EQUIP == pTempEquip->GetItemClass())
	{
		switch(pTempEquip->GetItemType())
		{
		case HEQUIP_WEAPON:				//武器，挂接类装备
		case (HUMAN_EQUIP)22:             // CY cosmetic weapon: render in the native hand slot.
			{
				EquipItem_BodyLocator(HEQUIP_WEAPON, pTempEquip->GetVisualID());
				SetWeaponType( pTempEquip->GetWeaponType() );
			}
			break;
		case HEQUIP_CAP:				//帽子, 身体, 手臂, 鞋, 装备类物品
		case HEQUIP_ARMOR:				
		case HEQUIP_CUFF:				
		case HEQUIP_BOOT:	
			{
				EquipItem_BodyPart(pTempEquip->GetItemType(), pTempEquip->GetVisualID());
			}
			break;
		case HEQUIP_SASH:				//腰带, 戒子, 项链
		case HEQUIP_RING:				
		case HEQUIP_NECKLACE:		
		default:
			break;
		}
	}
	else
	{
		//卸载装备
		UnEquipItem(point);
	}

	//如果是UI物体，重新设置VisibleFlag
	if(GetFakeObjectFlag())
	{
		m_pRenderInterface->Actor_SetUIVisibleFlag();
	}

	CObject_Item::DestroyItem(pTempEquip);
}

VOID CObject_PlayerOther::EquipItem_BodyPart(HUMAN_EQUIP nPart, INT nID)
{
	//-----------------------------------------------------------
	//渲染层设置
	if(!m_pRenderInterface)
	{
		return;
	}

	//-----------------------------------------------------------
	//角色装备类数据库
	DBC_DEFINEHANDLE(s_pEquipItem, DBC_ITEM_VISUAL_CHAR);
	const _DBC_ITEM_VISUAL_CHAR* pEquipVisual = (const _DBC_ITEM_VISUAL_CHAR*)s_pEquipItem->Search_Index_EQU(nID);
	if(!pEquipVisual)
	{
		return;
	}

	//种族(男，女)
	INT nRaceID = GetCharacterData()->Get_RaceID();
	TDAssert(nRaceID >= 0 && nRaceID<CHAR_RACE_NUM);
	if(nRaceID < 0 || nRaceID >= CHAR_RACE_NUM)
	{
		return ;
	}

	switch(nPart)
	{
	case HEQUIP_CAP:				//帽子
		{
			m_pRenderInterface->Actor_SetObjectProperty(
				szIDSTRING_CAP_MESH, CysItemVisualEntity(pEquipVisual, nRaceID, 0));

			m_pRenderInterface->Actor_SetObjectProperty(
				szIDSTRING_CAP_MAT, CysItemVisualEntity(pEquipVisual, nRaceID, 1));
		}
		break;
	case HEQUIP_ARMOR:				//身体
		{
			m_pRenderInterface->Actor_SetObjectProperty(
				szIDSTRING_MAINBODY_MESH, CysItemVisualEntity(pEquipVisual, nRaceID, 0));

			m_pRenderInterface->Actor_SetObjectProperty(
				szIDSTRING_MAINBODY_MAT, CysItemVisualEntity(pEquipVisual, nRaceID, 1));
		}
		break;
	case HEQUIP_CUFF:				//手臂
		{
			m_pRenderInterface->Actor_SetObjectProperty(
				szIDSTRING_ARM_MESH, CysItemVisualEntity(pEquipVisual, nRaceID, 0));

			m_pRenderInterface->Actor_SetObjectProperty(
				szIDSTRING_ARM_MAT, CysItemVisualEntity(pEquipVisual, nRaceID, 1));
		}
		break;
	case HEQUIP_BOOT:				//鞋
		{
			m_pRenderInterface->Actor_SetObjectProperty(
				szIDSTRING_FOOT_MESH, CysItemVisualEntity(pEquipVisual, nRaceID, 0));

			m_pRenderInterface->Actor_SetObjectProperty(
				szIDSTRING_FOOT_MAT, CysItemVisualEntity(pEquipVisual, nRaceID, 1));
		}
		break;
	}
}

VOID CObject_PlayerOther::EquipItem_BodyLocator(HUMAN_EQUIP nPart, INT nID)
{
	//-----------------------------------------------------------
	//渲染层设置
	if(!m_pRenderInterface)
	{
		return;
	}

	//-----------------------------------------------------------
	//角色挂接类数据库
	DBC_DEFINEHANDLE(s_pWeaponItem, DBC_ITEM_VISUAL_LOCATOR);
	const _DBC_ITEM_VISUAL_LOCATOR* pEquipVisual = (const _DBC_ITEM_VISUAL_LOCATOR*)s_pWeaponItem->Search_Index_EQU(nID);
	if(!pEquipVisual)
	{
		return;
	}

	//右手
	if(pEquipVisual->pObjFile_Right && pEquipVisual->pObjFile_Right[0] != '\0')
	{
		m_pRenderInterface->Actor_SetObjectProperty(szIDSTRING_CURRENT_RIGHTWEAPON, pEquipVisual->pObjFile_Right);
		m_pRenderInterface->SetRightWeaponMat(szIDSTRING_WEAPON_MAT, pEquipVisual->pMatName_Right);
		/*		
		tObject_Item* MyWeapon = CDataPool::GetMe()->UserEquip_GetItem(HEQUIP_WEAPON);

		CObject_Item_Equip::EXTRA_DEFINE* Extra = (CObject_Item_Equip::EXTRA_DEFINE*)((CObject_Item_Equip*)(CObject_Item*)MyWeapon)->GetExtraInfo();

		CObject_Item_Equip::EQUIP_ATTACH_GEM Gems = Extra->m_vEquipAttachGem;

		INT Gem_MaxLevel = 0;
		LPCTSTR szColor;

		for(INT GemIndex = 0; GemIndex < Gems.size(); GemIndex++)
		{
		UINT uGemType = Gems[GemIndex].m_GemType;

		// 从数据库中查找到这个Gem的信息
		DBC_DEFINEHANDLE(s_pItem_Gem, DBC_ITEM_GEM);
		//搜索纪录
		const _DBC_ITEM_GEM* pGem = (const _DBC_ITEM_GEM*)s_pItem_Gem->Search_Index_EQU(uGemType);
		if(!pGem) continue;

		if(pGem->nQuality > Gem_MaxLevel)
		{
		Gem_MaxLevel = pGem->nQuality;
		szColor = pGem->szColor;
		}
		}
		*/
		/////////////// code//////////////////
		UINT uGemType = GetCharacterData()->Get_EquipGem(HEQUIP_WEAPON);
		if(INVALID_ID != uGemType)
		{
			DBC_DEFINEHANDLE(s_pItem_Gem, DBC_ITEM_GEM);
			//搜索纪录
			const _DBC_ITEM_GEM* pGem = (const _DBC_ITEM_GEM*)s_pItem_Gem->Search_Index_EQU(uGemType);
			UINT nColor = 0;
			LPCTSTR szColor;
			szColor = pGem->szColor;

			INT eff_index = pGem->nEffectIndex;
			eff_index--;//表编号从1开始，对应列从0开始

			//如果策划在这列填了-1，表示不显示颜色。
			if(szColor[0] != '-' && szColor[1] != '1' && (eff_index >= 0) ) 
			{
				sscanf(szColor,"%8X",&nColor);

				if( pEquipVisual->pEffectName[eff_index] )//&& pEquipVisual->pEffectName[0] != '\0')
				{
					m_pRenderInterface->SetRightWeaponEffect(pEquipVisual->pEffectName[eff_index],nColor);
				}
			}
			else
			{
				m_pRenderInterface->SetRightWeaponEffect('\0',0);
			}
		}
		else
		{
//			if(pEquipVisual->pEffectName[eff_index] && pEquipVisual->pEffectName[0] != '\0')
//			{
				m_pRenderInterface->SetRightWeaponEffect('\0',0);
//			}
		}
	}
	else
		m_pRenderInterface->Actor_SetObjectProperty(szIDSTRING_CURRENT_RIGHTWEAPON, "");

	//左手
	if(pEquipVisual->pObjFile_Left && pEquipVisual->pObjFile_Left[0] != '\0' )
	{
		m_pRenderInterface->Actor_SetObjectProperty(szIDSTRING_CURRENT_LEFTWEAPON, pEquipVisual->pObjFile_Left);
		m_pRenderInterface->SetLeftWeaponMat(szIDSTRING_WEAPON_MAT, pEquipVisual->pMatName_Left);


		UINT uGemType = GetCharacterData()->Get_EquipGem(HEQUIP_WEAPON);
		if(INVALID_ID != uGemType)
		{
			DBC_DEFINEHANDLE(s_pItem_Gem, DBC_ITEM_GEM);
			//搜索纪录
			const _DBC_ITEM_GEM* pGem = (const _DBC_ITEM_GEM*)s_pItem_Gem->Search_Index_EQU(uGemType);
			UINT nColor = 0;
			LPCTSTR szColor;
			szColor = pGem->szColor;
			INT eff_index = pGem->nEffectIndex;
			eff_index--;//表编号从1开始，对应列从0开始

			//如果策划在这列填了-1，表示不显示颜色。
			if(szColor[0] != '-' && szColor[1] != '1' && (eff_index >= 0)) 
			{
				sscanf(szColor,"%8X",&nColor);


				if( pEquipVisual->pEffectName[eff_index] )//&& pEquipVisual->pEffectName[0] != '\0')
				{
					m_pRenderInterface->SetLeftWeaponEffect(pEquipVisual->pEffectName[eff_index],nColor);
				}
			}
			else
			{
				m_pRenderInterface->SetLeftWeaponEffect('\0',0);
			}
		}
		else
		{
//			if(pEquipVisual->pEffectName && pEquipVisual->pEffectName[0] != '\0')
//			{
				m_pRenderInterface->SetLeftWeaponEffect('\0',0);
//			}
		}
	}
	else
		m_pRenderInterface->Actor_SetObjectProperty(szIDSTRING_CURRENT_LEFTWEAPON, "");
}

VOID CObject_PlayerOther::UnEquipItem(HUMAN_EQUIP nPart)
{
	if(nPart == HEQUIP_WEAPON)
	{
		SetWeaponType(WEAPON_TYPE_NONE);
	}

	if(!m_pRenderInterface)
	{
		return;
	}

	switch(nPart)
	{
	case HEQUIP_WEAPON:
		m_pRenderInterface->Actor_SetObjectProperty(szIDSTRING_CURRENT_LEFTWEAPON, "");
		m_pRenderInterface->Actor_SetObjectProperty(szIDSTRING_CURRENT_RIGHTWEAPON, "");
		break;

	case HEQUIP_CAP:
		m_pRenderInterface->Actor_SetObjectProperty(szIDSTRING_CAP_MESH, "");
		m_pRenderInterface->Actor_SetObjectProperty(szIDSTRING_CAP_MAT, "");
		break;

	case HEQUIP_ARMOR:
		//设置缺省装备
		EquipItem_BodyPart(HEQUIP_ARMOR, m_pCharRace->nDefBody);		//衣服
		break;

	case HEQUIP_CUFF:
		//设置缺省装备
		EquipItem_BodyPart(HEQUIP_CUFF, m_pCharRace->nDefArm);		//手
		break;

	case HEQUIP_BOOT:
		//设置缺省装备
		EquipItem_BodyPart(HEQUIP_BOOT, m_pCharRace->nDefFoot);		//脚
		break;

	case HEQUIP_SASH:
	case HEQUIP_RING:
	case HEQUIP_NECKLACE:
		//Not Care...
		break;

	default:
		break;
	}
}

VOID CObject_PlayerOther::OnDataChanged_FaceMesh(VOID)
{
	UpdateFaceMesh();
}

VOID CObject_PlayerOther::OnDataChanged_HairMesh(VOID)
{
	UpdateHairMesh();
}

VOID CObject_PlayerOther::OnDataChanged_HairColor(VOID)
{
	UpdateHairColor();
}

VOID CObject_PlayerOther::OnDataChanged_EquipVer(VOID)
{
	//发送装备请求
	SendEuipRequest();
}

INT CObject_PlayerOther::CalcCharModelID( VOID )const
{
	//经过变身
	if (GetConstCharacterData()->Get_ModelID() != -1)
	{
		//直接从模型定义表中读取模型名
		return GetConstCharacterData()->Get_ModelID();
	}
	else
	{
		if ( m_pCharRace != NULL )
			return m_pCharRace->nModelID;
		else
			return INVALID_ID;
	}
}

UINT CObject_PlayerOther::GetIdleInterval(VOID)const
{
	if(m_pCharRace != NULL && m_pCharRace->nIdleInterval >= 0)
	{
		return m_pCharRace->nIdleInterval * 1000;
	}
	else
	{
		return CObject_Character::GetIdleInterval();
	}
}

VOID CObject_PlayerOther::RefreshSelectionAppearance()
{
    UpdateCharRace();
    UpdateFaceMesh(); UpdateHairMesh(); UpdateHairColor();
    for (int point=0; point<HEQUIP_NUMBER; ++point) UpdateEquip((HUMAN_EQUIP)point);
    UpdateDress(); UpdateOrnaments(); UpdateWuhun();
}

VOID CObject_PlayerOther::UpdateCharRace(VOID)
{
	m_pCharRace = NULL;

	CCharacterData *pCharacterData = GetCharacterData();
	if(pCharacterData != NULL && pCharacterData->Get_RaceID() != INVALID_ID)
	{
		DBC_DEFINEHANDLE(s_pCharacterRace, DBC_CHARACTER_RACE);
		m_pCharRace = (const _DBC_CHAR_RACE*)(s_pCharacterRace->Search_Index_EQU(pCharacterData->Get_RaceID()));
	}
}

VOID CObject_PlayerOther::OnDataChanged_RaceID( VOID )
{
	CObject_Character::OnDataChanged_RaceID();
	Enable(OSF_RAY_QUERY);
}

VOID CObject_PlayerOther::OnDataChanged_FaceImage(VOID)			// 头像改变事件函数, 2006-3-9
{

}
