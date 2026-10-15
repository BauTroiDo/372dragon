#include "StdAfx.h"
#include "RFObjDummy.h"
#include "../RenderSystem.h"
#include "../Global.h"
#include "TDException.h"
#include "TDUtil.h"	// CYS-BULLETLIVE: TDU_Log
#include "Core/WXSystem.h"
#include <OgreSceneManager.h>
#include "../WXObj_ProjTex.h"
#include "EffectSystem/WXEffectManager.h"
#include "EffectSystem/WXEffect.h"
#include "EffectSystem/WXEffectElement.h"
#include "EffectSystem/WXProjectorElement.h"
#include <OgreLogManager.h>		// CYS-PROJSIZE
#include <OgreStringConverter.h>	// CYS-PROJSIZE
#include <cstdlib>			// CYS-PROJSIZE: getenv


CRFObj_Dummy::CRFObj_Dummy()
{
	//创建空白节点，可以附加特效或者ProjTexture
	m_pSceneNode = 
		CRenderSystem::GetMe()->GetRenderSystem()->getBaseSceneNode()->createChildSceneNode();

	m_pEffect = NULL;
}

CRFObj_Dummy::~CRFObj_Dummy()
{
	if(m_pSceneNode)
	{
		if ( m_pEffect != NULL )
		{
			WX::EffectManager::getSingleton().removeEffect(m_pEffect);
			m_pEffect = NULL;
		}
		CRenderSystem::GetMe()->GetRenderSystem()->getSceneManager()->destroySceneNode(m_pSceneNode->getName());
	}
}

VOID CRFObj_Dummy::Destroy(VOID)
{
	//删除投影
	for(INT i=0; i<(INT)m_vProjTex.size(); i++)
	{
		delete m_vProjTex[i]; 	m_vProjTex[i] = NULL;
	}
	m_vProjTex.clear();

	//删除自身
	CWXObject::Destroy();
}

//设置位置 (游戏世界坐标)
VOID CRFObj_Dummy::SetPosition(const fVector3& vPos)
{
	if(!m_pSceneNode) return;

	//坐标转换
	fVector3 fvGfx;
	CRenderSystem::GetMe()->Axis_Trans(CRenderSystem::AX_GAME, 
		vPos, CRenderSystem::AX_GFX, fvGfx);

	m_pSceneNode->setPosition(fvGfx.x, fvGfx.y, fvGfx.z);
}

//设置旋转
VOID CRFObj_Dummy::SetOrientation(const fVector3& vRotate)
{
	//Todo ...	
	if(!m_pSceneNode) return;

	m_pSceneNode->setOrientation( Ogre::Quaternion(Ogre::Radian(vRotate.y), Ogre::Vector3::UNIT_Y) );
}

//设置是否可见
VOID CRFObj_Dummy::SetVisible(BOOL bVisible)
{
	TDThrow("Not support!");
}

//设置投射纹理
VOID CRFObj_Dummy::Attach_ProjTexture(PROJTEX_TYPE type, BOOL bShow, FLOAT Ring_Range, FLOAT fHeight)
{
	//定位现有的ProjTex
	CWXObj_ProjTex* pShadowProj = NULL;
	for(INT i=0; i<(INT)m_vProjTex.size(); i++)
	{
		if(m_vProjTex[i]->GetType() == type)
		{
			pShadowProj = m_vProjTex[i];
			break;
		}
	}
	
	// CYS-PROJSIZE (projsize, 20/09/2026) --------------------------------------------------------
	// Cong tac A/B tren CUNG MOT binary: CYS_RINGSIZE=0 giu NGUYEN VAN duong ma cu cua 0.85.
	static int s_fix = -1;
	if (s_fix < 0) { const char* v = getenv("CYS_RINGSIZE"); s_fix = (v && v[0] == '0') ? 0 : 1; }

	const FLOAT fRangeIn = Ring_Range;

	if (!s_fix)
	{
		// DUONG CU, NGUYEN VAN (0.85 RFObjDummy.cpp:91-103). `m_pEffect` la hieu ung rieng cua dummy,
		// chi duoc dat boi Attach_Effect(); duong vong bao tam KHONG BAO GIO goi Attach_Effect nen
		// con tro nay LUON NULL => vong lap bi bo qua => may chieu giu nguyen ProjectionSize cua du lieu.
		if(Ring_Range != 100.0f && m_pEffect)
		{
			for (unsigned short i=0; i < m_pEffect->getNumElements(); i++)
			{
				WX::EffectElement *eff_element = m_pEffect->getElement(i);

				if (eff_element->getType() == "Projector")
				{
					static_cast<WX::ProjectorElement*>(eff_element)->setProjectionSize(Ring_Range);
				}
			}
		}
	}
	else
	{
		// HAI CAY SONG deu kep Ring_Range TRUOC khi dung, doc bang xref chuoi:
		//   CY 3.71  Render.dll 4.057.088 B sha256 e6e67de45489f902... CRFObj_Dummy::Attach_ProjTexture
		//            = 0x180006640; kep tai 0x1800066c4-0x1800066e5 (hang so 100.0f @0x1802bbda4,
		//            200.0f @0x1802bc664).
		//   client_GL Render.dll 3.991.552 B sha256 49b2ab1f3c72d4b1... = 0x1800292d0; kep tai
		//            0x180029354-0x180029375 (100.0f @0x1802b3098, 200.0f @0x1802b5774).
		//   if (Ring_Range == 0) Ring_Range = 100; else if (Ring_Range < 0) Ring_Range = 200;
		// Kep nay BAT BUOC: 30 chieu khinh cong (ke ca 34) co m_fDamageRange = 0 => Ring_Range = 0
		// => fov = atan(0/(2*near))*2 = 0 => cua so truc giao 0 don vi => vong BIEN MAT.
		if (Ring_Range == 0.0f)      Ring_Range = 100.0f;
		else if (Ring_Range < 0.0f)  Ring_Range = 200.0f;
	}
	// --------------------------------------------------------------------------------------------
	
	//高度转换 GAME->GFX
	//取得放缩系数
	fVector3 fvScale = CRenderSystem::GetMe()->GetSacle();
	fHeight = fHeight*fvScale.y;

	// CYS-FPSMOVE (fps-move, 20/09/2026): ham nay chay MOI KHUNG (CObject_ProjTex_MouseTarget::Tick khi dung yen,
	// Player_MoveTo khi giu chuot chay) => dong chan doan nay chi ghi khi CYS_RINGSIZE_LOG=1 (mac dinh TAT).
	// Cay song khong ghi gi o day; xem WXObj_ProjTex.h.
	if (CysRingSizeLogOn())
		Ogre::LogManager::getSingleton().logMessage("CYS-RINGSIZE: dummy type=" +
			Ogre::StringConverter::toString((int)type) + " fix=" +
			Ogre::StringConverter::toString(s_fix) + " show=" +
			Ogre::StringConverter::toString((int)(bShow ? 1 : 0)) + " range_in=" +
			Ogre::StringConverter::toString(fRangeIn) + " range_used=" +
			Ogre::StringConverter::toString(Ring_Range) + " m_pEffect=" +
			Ogre::StringConverter::toString(m_pEffect != NULL ? 1 : 0));

	if(bShow)
	{
		//已经存在
		if(pShadowProj)
		{
			pShadowProj->Show(bShow);
			pShadowProj->SetAddHeight(fHeight);
			// CYS-PROJSIZE: CY 0x180006708 / GL 0x180029398 goi SetProjectionSize o CHINH nhanh nay.
			if (s_fix) pShadowProj->SetProjectionSize(Ring_Range);
			return;
		}

		//创建
		pShadowProj = new CWXObj_ProjTex(type, m_pSceneNode, fHeight);

		// CYS-PROJSIZE: CY 0x180006757 / GL 0x1800293e7 goi ngay sau ctor, TRUOC push_back.
		if (s_fix) pShadowProj->SetProjectionSize(Ring_Range);

		m_vProjTex.push_back(pShadowProj);
	}
	else
	{
		//已经存在
		if(pShadowProj)
		{
			pShadowProj->Show(bShow);
			pShadowProj->SetAddHeight(fHeight);
			if (s_fix) pShadowProj->SetProjectionSize(Ring_Range);
			return;
		}
	}

}

// CYS-BULLETLIVE 20/09/2026 (bullet-live): chot 4 cua duong dan. Tat mac dinh.
static bool CysBulletLog() { static const int on = []() { char t[4] = {}; return (::GetEnvironmentVariableA("CYS_BULLET_LOG", t, sizeof(t)) == 1 && t[0] == '1') ? 1 : 0; }(); return on != 0; }

VOID CRFObj_Dummy::Attach_Effect(LPCTSTR szEffectName)
{
	if ( m_pEffect != NULL )
	{
		assert( m_pEffect == NULL && "CRFObj_Dummy::Attach_Effect" );
		Detach_Effect();
	}

	//创建新的特效
	m_pEffect = WX::EffectManager::getSingleton().createEffect(szEffectName);
	if ( m_pEffect != NULL )
	{
		//挂接到场景节点
		//m_pSceneNode->addChild(m_pEffect->createSceneNode());
		m_pEffect->createSceneNode(m_pSceneNode);
	}
	// CYS-BULLETLIVE: hieu ung co duoc tao va co nut canh khong. createEffect KHONG BAO GIO tra NULL
	// (no roi ve Effect_Error), nen dong nay mot minh CHUA chung minh ve dung thu; phai doc them
	// dong "can't find the required effect template" trong WXRender.log.
	if (CysBulletLog())
		TDU_Log("CYS-BULLETLIVE: attach effect [%s] -> effect=%s node=%s",
			szEffectName ? szEffectName : "", m_pEffect ? "yes" : "NULL", m_pSceneNode ? "yes" : "NULL");
}

VOID CRFObj_Dummy::Detach_Effect(void)
{
	if ( m_pSceneNode != NULL )
	{
		if ( m_pEffect != NULL )
		{
			WX::EffectManager::getSingleton().removeEffect(m_pEffect);
			m_pEffect = NULL;
		}
	}
}
