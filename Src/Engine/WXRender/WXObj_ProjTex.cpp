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
		// CYS-FXCY2 (fx-cy-2, 20/09/2026): vong pham vi ky nang.
		// Du lieu CHI co aura_rune_projector0..15 - KHONG co template ten tran "aura_rune_projector",
		// nen dong cu lam createEffect() ghi log "can't find the required effect template" roi NEM
		// (template Effect_Error cung khong co trong du lieu) => vong bao tam KHONG BAO GIO ve duoc.
		// CY 3.71 Render.dll ghep chi so: sprintf(buf, "aura_rune_projector%d", type - 4), doc duoc
		// tai 0x18001d090..0x18001d159 (CY Render.dll 4.057.088 B, sha256 e6e67de45489f902...).
		// Hai nhanh anh em xac nhan cach danh so: type==2 -> "reachable_projector" (19 ky tu),
		// type==3 -> "unreachable_projector" (21). Enum cua ta: SELECT_RING=0, SHADOW_BLOB=1,
		// REACHABLE=2, UNREACHABLE=3, AURA_RUNE=4 => chi so rune = type - AURA_RUNE, KHOP TUNG O.
		// Dong "//..." bo lung ngay sau AURA_RUNE trong TDGfxSystem.h chinh la cho cua cac hang so
		// 5..19 ma CY co con ta thieu. GL Render.dll (3.991.552 B) cung chua chuoi do.
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
	m_fProjectionSize = 0.0f;	// CYS-PROJSIZE: CY khoi tao +0x28 = 0 trong ctor (0x18001d0dc)
	
	//设置高度
	SetAddHeight(fAddHeight);
}

// CYS-FPSMOVE (fps-move, 20/09/2026): cong tac cua hai dong "CYS-RINGSIZE". Mac dinh TAT. Doc MOT lan.
bool CysRingSizeLogOn(void)
{
	static const int s_on = []() { char t[4] = {}; return (::GetEnvironmentVariableA("CYS_RINGSIZE_LOG", t, sizeof(t)) == 1 && t[0] == '1') ? 1 : 0; }();
	return s_on != 0;
}

//-----------------------------------------------------------------------------
// CYS-PROJSIZE (projsize, 20/09/2026)
// Nguyen ban tu hai cay SONG, doc bang xref chuoi chu khong bang dia chi chep tay:
//   CY 3.71  Render.dll 4.057.088 B sha256 e6e67de45489f90207379419c0eb2e9f4fbdbd1d800cc6f46902c1fe5eb0cec7
//            CWXObj_ProjTex::SetProjectionSize = 0x18001d280
//   client_GL Render.dll 3.991.552 B sha256 49b2ab1f3c72d4b1c957e463bbe474f0ef86f3f085fd8aa8660776f9de1369bb
//            CWXObj_ProjTex::SetProjectionSize = 0x180007eb0
// Ca hai: this->+0x10 (mProjectorEffect) -> getNumElements -> getElement(i) -> so chuoi voi "Projector"
// (9 ky tu) -> ProjectorElement::setProjectionSize(size). CY con luu size vao +0x28; GL thi khong.
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

