// Obj_Bullet.cpp
// 
/////////////////////////////////////////////////////

#include "StdAfx.h"

#include "GameStruct_Skill.h"
#include "TDException.h"
#include "TDUtil.h"
#include "TDTimeSystem.h"
#include "TDDBC_Struct.h"
#include "..\ObjectManager.h"
#include "..\..\Procedure\GameProcedure.h"
#include "..\..\Dbc\GMDataBase.h"
#include "..\Character\Obj_Character.h"

#include "Obj_Bullet.h"
#include "..\..\Sound\GMSoundSystem.h"	// CYS-AUDIO
#include "..\..\Network\CysWorldReplay.h"	// CYS-BULLETLIVE: LiveShot

// CYS-BULLETLIVE 20/09/2026 (bullet-live): bon chot cua duong di mot vien dan. Tat mac dinh.
static bool CysBulletLog() { static const int on = []() { char t[4] = {}; return (::GetEnvironmentVariableA("CYS_BULLET_LOG", t, sizeof(t)) == 1 && t[0] == '1') ? 1 : 0; }(); return on != 0; }
// CYS-BULLETLIVE: chup mot loat anh TRONG luc dan bay (CYS_BULLET_SHOT=1). Day la bang chung nhin thay duoc.
static bool CysBulletShot() { static const int on = []() { char t[4] = {}; return (::GetEnvironmentVariableA("CYS_BULLET_SHOT", t, sizeof(t)) == 1 && t[0] == '1') ? 1 : 0; }(); return on != 0; }

WX_IMPLEMENT_DYNAMIC(CObject_Bullet, GETCLASS(CObject_Effect));
CObject_Bullet::CObject_Bullet()
{
	m_idSend			= INVALID_ID;
	m_pBulletData		= NULL;
	m_nSendLogicCount	= -1;

	m_bSingleTarget		= FALSE;
	m_idTarget			= INVALID_ID;
	m_fvTargetPos		= fVector3( -1.f, -1.f, -1.f );
	m_fvStartPos		= fVector3( -1.f, -1.f, -1.f );
	m_fStartToEndDist	= -1.f;

	m_bAlreadyHit		= FALSE;
	m_nCysFlySound		= -1;	// CYS-AUDIO
	m_nCysFrames		= 0;	// CYS-BULLETLIVE
	m_dwCysBornTick		= 0;	// CYS-BULLETLIVE
	m_dwCysLastShot		= 0;	// CYS-BULLETLIVE
}

CObject_Bullet::~CObject_Bullet()
{
	CSoundSystemFMod::StopSoundHandle(m_nCysFlySound);	// CYS-AUDIO
}

VOID CObject_Bullet::Initial( VOID *pInit )
{
	CObject_Effect::Initial(pInit);

	SObject_BulletInit *pBulletInit= (SObject_BulletInit*)(pInit);
	if ( pBulletInit != NULL )
	{
		m_idSend			= pBulletInit->m_idSend;
		if ( pBulletInit->m_nBulletID != -1 )
		{
			DBC_DEFINEHANDLE(s_pBulletDataDBC, DBC_BULLET_DATA);
			m_pBulletData	= (const _DBC_BULLET_DATA*)(s_pBulletDataDBC->Search_Index_EQU( pBulletInit->m_nBulletID ));
		}
		else
		{
			m_pBulletData	= NULL;
		}
		m_nSendLogicCount	= pBulletInit->m_nSendLogicCount;

		m_bSingleTarget		= pBulletInit->m_bSingleTarget;
		m_idTarget			= pBulletInit->m_idTarget;
		m_fvTargetPos		= pBulletInit->m_fvTargetPos;
	}
	else
	{
		m_idSend			= INVALID_ID;
		m_pBulletData		= NULL;
		m_nSendLogicCount	= -1;

		m_bSingleTarget		= FALSE;
		m_idTarget			= INVALID_ID;
		m_fvTargetPos		= fVector3( -1.f, -1.f, -1.f );
	}

	if(m_pBulletData != NULL)
	{
		switch(m_pBulletData->m_nContrailType)
		{
		case BULLET_CONTRAIL_TYPE_BEELINE:
		case BULLET_CONTRAIL_TYPE_PARABOLA:
			m_fvStartPos	= GetPosition();
			if ( strlen( m_pBulletData->m_szFlyEffect ) > 0 )
			{
				ChangEffect( m_pBulletData->m_szFlyEffect, FALSE );
			}
			break;
		case BULLET_CONTRAIL_TYPE_NONE:
		default:
			m_fvStartPos	= m_fvTargetPos;
			SetPosition(m_fvStartPos);
			break;
		}

	}
	else
	{
		m_fvStartPos	= GetPosition();
	}

	m_fStartToEndDist = TDU_GetDist(m_fvTargetPos, m_fvStartPos);
	m_bAlreadyHit	= FALSE;

	// CYS-AUDIO: CY 3.71 FUN_14061a720: Bullet.txt column 4 (fly sound, row +0x18) plays looping in 3D at the bullet
	// CYS-AUDIO: and its handle is kept; FUN_14061a850 stops it and plays column 7 (hit sound, row +0x30) once.
	CSoundSystemFMod::StopSoundHandle(m_nCysFlySound);
	if(m_pBulletData != NULL && m_pBulletData->m_szFlySound != NULL)
		m_nCysFlySound = CSoundSystemFMod::PlaySoundFileAtGame(m_pBulletData->m_szFlySound, GetPosition(), TRUE, "bullet-fly");

	// CYS-BULLETLIVE: chot 4 - doi tuong dan da duoc tao chua, co dong Bullet.txt khong, co gan duoc hieu ung khong.
	m_dwCysBornTick = ::GetTickCount();
	if (CysBulletLog())
	{
		const fVector3 vPos = GetPosition();
		TDU_Log("CYS-BULLETLIVE: bullet t=%lu id=%d row=%s contrail=%d speed=%.2f fly_effect=[%s] hit_effect=[%s] "
			"single=%d target=%d pos=%.2f,%.2f,%.2f dist=%.2f render=%s",
			(unsigned long)m_dwCysBornTick,
			(pBulletInit != NULL) ? (int)pBulletInit->m_nBulletID : -1,
			(m_pBulletData != NULL) ? "found" : "NO-ROW",
			(m_pBulletData != NULL) ? (int)m_pBulletData->m_nContrailType : -1,
			(m_pBulletData != NULL) ? m_pBulletData->m_fSpeed : -1.f,
			(m_pBulletData != NULL && m_pBulletData->m_szFlyEffect != NULL) ? m_pBulletData->m_szFlyEffect : "",
			(m_pBulletData != NULL && m_pBulletData->m_szHitEffect != NULL) ? m_pBulletData->m_szHitEffect : "",
			(int)m_bSingleTarget, (int)m_idTarget, vPos.x, vPos.y, vPos.z, m_fStartToEndDist,
			(GetRenderInterface() != NULL) ? "yes" : "NULL");
	}
}

VOID CObject_Bullet::Tick( VOID )
{
	if ( m_bAlreadyHit )
	{
		CObject_Effect::Tick();
	}
	else
	{
		if ( m_pBulletData == NULL )
		{
			m_bAlreadyHit = TRUE;
			return ;
		}

		// CYS-BULLETLIVE: dem khung bay + chup anh trong luc bay (chi khi CYS_BULLET_SHOT=1).
		++m_nCysFrames;
		if (CysBulletShot())
		{
			const DWORD dwNow = ::GetTickCount();
			if (m_dwCysLastShot == 0 || dwNow - m_dwCysLastShot >= 120)
			{
				m_dwCysLastShot = dwNow;
				CHAR szLabel[64] = {};
				_snprintf(szLabel, sizeof(szLabel) - 1, "bullet-%d-fly-%03d", (int)m_idSend, (int)m_nCysFrames);
				CysWorldReplay::LiveShot(szLabel);
			}
		}

		switch(m_pBulletData->m_nContrailType)
		{
		case BULLET_CONTRAIL_TYPE_BEELINE:
		case BULLET_CONTRAIL_TYPE_PARABOLA:
			{
				fVector3 fvTargetPos;
				if ( m_bSingleTarget )
				{
					CObject *pObj = (CObject*)(CObjectManager::GetMe()->FindServerObject( m_idTarget ));
					if ( pObj != NULL )
					{
						fvTargetPos = pObj->GetPosition();
						if ( pObj->GetRenderInterface() != NULL && strlen( m_pBulletData->m_szHitEffectLocator ) > 0 )
						{
							pObj->GetRenderInterface()->Actor_GetLocator( m_pBulletData->m_szHitEffectLocator, fvTargetPos );
						}
						else
						{
							fvTargetPos = pObj->GetPosition();
						}
					}
					else
					{
						fvTargetPos = fVector3( -1.f, -1.f, -1.f );
					}
				}
				else
				{
					fvTargetPos = m_fvTargetPos;
				}

				FLOAT fCurTickFlyDist = m_pBulletData->m_fSpeed * CGameProcedure::s_pTimeSystem->GetDeltaTime()/1000.0f;
				FLOAT fCurTickFlyDistSq = fCurTickFlyDist * fCurTickFlyDist;
				FLOAT fDistSq = TDU_GetDistSq( fvTargetPos, GetPosition() );
				if ( fDistSq <= fCurTickFlyDistSq )
				{
					if(m_pBulletData->m_nContrailType == BULLET_CONTRAIL_TYPE_PARABOLA)
					{
						FLOAT fStartToEndDist = m_fStartToEndDist;
						FLOAT fTargetToStartDist = TDU_GetDist(fvTargetPos, m_fvStartPos);
						FLOAT fCenterToTargetDist = fabsf(fTargetToStartDist - fStartToEndDist/2.f);
						FLOAT fTemp = (fCenterToTargetDist * 2.f)/fStartToEndDist;
						FLOAT fAddY = (1.f - (fTemp * fTemp)) * (FLOAT)m_pBulletData->m_nContrailParam;	// CYS-CY: CY 3.71 Bullet.txt column 2 is INT
						fvTargetPos.y += fAddY;
					}
					FLOAT fDir = TDU_GetYAngle( fVector2( GetPosition().x, GetPosition().z ), fVector2( fvTargetPos.x, fvTargetPos.z ) );
					SetPosition( fvTargetPos );
					SetFaceDir( fDir );

					AlreadyHit();
				}
				else
				{
					fVector3 vDir = fvTargetPos - GetPosition();
					vDir.normalise();
					fVector3 vFlyLength;
					vFlyLength.x = vDir.x * fCurTickFlyDist;
					vFlyLength.y = vDir.y * fCurTickFlyDist;
					vFlyLength.z = vDir.z * fCurTickFlyDist;
					fvTargetPos = vFlyLength + GetPosition();
					if(m_pBulletData->m_nContrailType == BULLET_CONTRAIL_TYPE_PARABOLA)
					{
						FLOAT fStartToEndDist = m_fStartToEndDist;
						FLOAT fTargetToStartDist = TDU_GetDist(fvTargetPos, m_fvStartPos);
						FLOAT fCenterToTargetDist = fabsf(fTargetToStartDist - fStartToEndDist/2.f);
						FLOAT fTemp = (fCenterToTargetDist * 2.f)/fStartToEndDist;
						FLOAT fAddY = (1.f - (fTemp * fTemp)) * (FLOAT)m_pBulletData->m_nContrailParam;	// CYS-CY: CY 3.71 Bullet.txt column 2 is INT
						fvTargetPos.y += fAddY;
					}
					FLOAT fDir = TDU_GetYAngle( fVector2( GetPosition().x, GetPosition().z ), fVector2( fvTargetPos.x, fvTargetPos.z ) );
					SetPosition( fvTargetPos );
					SetFaceDir( fDir );
				}
			}
			break;
		case BULLET_CONTRAIL_TYPE_NONE:
		default:
			{
				AlreadyHit();
			}
			break;
		}
	}
}

VOID CObject_Bullet::AlreadyHit( VOID )
{
	// CYS-BULLETLIVE: ket thuc duong bay - bao nhieu khung, bao nhieu met, bao lau.
	if (CysBulletLog())
	{
		const fVector3 vPos = GetPosition();
		TDU_Log("CYS-BULLETLIVE: hit t=%lu sender=%d frames=%d ms=%lu flown=%.2f planned=%.2f pos=%.2f,%.2f,%.2f render=%s",
			(unsigned long)::GetTickCount(), (int)m_idSend, (int)m_nCysFrames,
			(unsigned long)(::GetTickCount() - m_dwCysBornTick),
			TDU_GetDist(vPos, m_fvStartPos), m_fStartToEndDist, vPos.x, vPos.y, vPos.z,
			(GetRenderInterface() != NULL) ? "yes" : "NULL");
	}
	if(m_idTarget != INVALID_ID)
	{
		CObject_Character *pChar = (CObject_Character*)(CObjectManager::GetMe()->FindServerObject(m_idTarget));
		if(pChar != NULL)
		{
			pChar->ShowLogicEvent(m_idSend, m_nSendLogicCount, TRUE);
		}
	}

	m_bAlreadyHit = TRUE;
	// CYS-AUDIO: CY 3.71 FUN_14061a850 (see Initial)
	CSoundSystemFMod::StopSoundHandle(m_nCysFlySound);
	if(m_pBulletData != NULL && m_pBulletData->m_szHitSound != NULL)
		CSoundSystemFMod::PlaySoundFileAtGame(m_pBulletData->m_szHitSound, GetPosition(), FALSE, "bullet-hit");
	if ( m_pBulletData != NULL && strlen( m_pBulletData->m_szHitEffect ) > 0 )
	{
		ChangEffect( m_pBulletData->m_szHitEffect, FALSE );
	}
	else
	{
		if(m_pRenderInterface != NULL)
			m_pRenderInterface->Detach_Effect();
	}
}
