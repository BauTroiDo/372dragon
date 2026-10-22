#include "StdAfx.h"
#include "WXObj_ProjTex.h"
#include "RenderSystem.h"
#include "TDException.h"
#include "EffectSystem/WXEffect.h"
#include "EffectSystem/WXEffectManager.h"
#include "EffectSystem/WXEffectElement.h"	// CYS-PROJSIZE
#include "EffectSystem/WXProjectorElement.h"	// CYS-PROJSIZE
#include <OgreLogManager.h>		// CYS-FXCY2
#include <OgreStringConverter.h>	// CYS-FXCY2
#include <cstdlib>			// CYS-FXCY2: getenv

CWXObj_ProjTex::CWXObj_ProjTex(tEntityNode::PROJTEX_TYPE type, Ogre::SceneNode* pParentNode, FLOAT fAddHeight)
{
    TDAssert(pParentNode);
    mProjectorEffect = NULL;

    Ogre::String effectName;
	switch(type)
	{
	case tEntityNode::REACHABLE:
        effectName = "reachable_projector";
		break;

	case tEntityNode::UNREACHABLE:
        effectName = "unreachable_projector";
		break;

	default:











		if ((INT)type >= (INT)tEntityNode::AURA_RUNE)
		{
			// CYS-FXCY2: canh doi chung cua A/B tren CUNG MOT binary.
			// CYS_AURARING=0 => NGUYEN VAN duong ma cu (ten tran, khong co chi so).
			static int s_fix = -1;
			if (s_fix < 0) { const char* v = getenv("CYS_AURARING"); s_fix = (v && v[0] == '0') ? 0 : 1; }
			if (!s_fix) { effectName = "aura_rune_projector"; break; }
			INT nRune = (INT)type - (INT)tEntityNode::AURA_RUNE;
			if (nRune < 0 || nRune > 15) nRune = 0;
			CHAR szName[64];
			sprintf_s(szName, sizeof(szName), "aura_rune_projector%d", nRune);
			effectName = szName;
			break;
		}
		TDThrow("Invalid ProjTextType!");
		break;
	}

    // CYS-FXCY2: mot dong de nghiem thu doc duoc CHINH XAC ten template da xin.
    Ogre::LogManager::getSingleton().logMessage("CYS-FXCY2 auraring: type=" +
        Ogre::StringConverter::toString((int)type) + " effect=" + effectName);
    mProjectorEffect = WX::EffectManager::getSingleton().createEffect(effectName);
    mProjectorEffect->createSceneNode(pParentNode);

	m_theType = type;
	m_fProjectionSize = 0.0f;
	
	//设置高度
	SetAddHeight(fAddHeight);
}

// CYS-FPSMOVE (fps-move, 20/09/2026): cong tac cua hai dong "CYS-RINGSIZE". Mac dinh TAT. Doc MOT lan.
bool CysRingSizeLogOn(void)
{
	static const int s_on = []() { char t[4] = {}; return (::GetEnvironmentVariableA("CYS_RINGSIZE_LOG", t, sizeof(t)) == 1 && t[0] == '1') ? 1 : 0; }();
	return s_on != 0;
}










VOID CWXObj_ProjTex::SetProjectionSize(FLOAT fSize)
{
	m_fProjectionSize = fSize;
	if (!mProjectorEffect) return;

	int nApplied = 0;
	for (unsigned short i = 0; i < mProjectorEffect->getNumElements(); ++i)
	{
		WX::EffectElement* pElement = mProjectorEffect->getElement(i);
		if (pElement && pElement->getType() == "Projector")
		{
			static_cast<WX::ProjectorElement*>(pElement)->setProjectionSize(fSize);
			++nApplied;
		}
	}
	// CYS-FPSMOVE: duong MOI KHUNG (xem WXObj_ProjTex.h) - chi ghi khi CYS_RINGSIZE_LOG=1.
	if (CysRingSizeLogOn())
		Ogre::LogManager::getSingleton().logMessage("CYS-RINGSIZE: projtex type=" +
			Ogre::StringConverter::toString((int)m_theType) + " size=" +
			Ogre::StringConverter::toString(fSize) + " elements=" +
			Ogre::StringConverter::toString(nApplied));
}

CWXObj_ProjTex::~CWXObj_ProjTex()
{
    WX::EffectManager::getSingleton().removeEffect(mProjectorEffect);
    mProjectorEffect = NULL;
}

VOID CWXObj_ProjTex::SetAddHeight(FLOAT fAddHeight)
{
	m_fAddHeight = fAddHeight;
}

VOID CWXObj_ProjTex::Show(BOOL bShow)
{
    if (mProjectorEffect)
        mProjectorEffect->setVisible(bShow==TRUE);
}
