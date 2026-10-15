#pragma once

/*
|	附属在WXObj上的投射纹理,包括选择环,阴影斑点,脚印等
|	
*/
#include "..\WxRender\RenderSystem.h"

namespace Ogre
{
	class SceneNode;
}

namespace WX
{
    class Effect;
}

// CYS-FPSMOVE (fps-move, 20/09/2026): cong tac cua hai dong chan doan "CYS-RINGSIZE".
// Hai dong do nam tren duong MOI KHUNG: CObject_ProjTex_MouseTarget::Tick goi Attach_ProjTexture(REACHABLE,FALSE)
// + (UNREACHABLE,FALSE) moi khung khi nhan vat dung yen sau cu bam dat dau tien, va Player_MoveTo goi lai moi khung
// khi giu chuot chay. Ban choi stage-play-5 ghi 124.132 dong / 19 phut (dinh 248 dong/giay).
// CAY SONG (do bang cung mot thuoc, Tools/pipeline/probe_gate_check.py): log ve cua client_GL
// (client_GL/Bin64/LogDirectory/Fairy_*.log) KHONG co tien to nao ban theo khung; CY/GL Render.dll khong co loi goi
// log nao trong CRFObj_Dummy::Attach_ProjTexture (projsize.md). => MAC DINH TAT; CYS_RINGSIZE_LOG=1 bat lai de A/B.
// Doc moi truong DUNG MOT LAN roi nho (cung cach voi CYS_BULLET_LOG trong RFObjDummy.cpp).
bool CysRingSizeLogOn(void);

class CWXObject;
class CWXObj_ProjTex
{
public:
	tEntityNode::PROJTEX_TYPE	GetType(VOID) const { return m_theType; }
	VOID						Show(BOOL bShow);
	VOID						SetAddHeight(FLOAT fAddHeight = 1.7f);
	FLOAT						GetAddHeight(void) const { return m_fAddHeight; }

	// CYS-PROJSIZE (projsize, 20/09/2026): co cua may chieu PHAI ap len effect CUA CHINH doi tuong nay.
	// 0.85 (va CY-Source cho toi hom nay) ap len `CRFObj_Dummy::m_pEffect` - mot con tro KHAC, NULL tren
	// duong nay - nen khong bao gio co tac dung. Hai cay SONG deu da chuyen viec nay vao day:
	//   CY 3.71 Render.dll  (4.057.088 B, sha256 e6e67de45489f902...) 0x18001d280
	//   client_GL Render.dll(3.991.552 B, sha256 49b2ab1f3c72d4b1...) 0x180007eb0
	// Ca hai duyet effect cua chinh ProjTex, so getType()=="Projector", goi setProjectionSize(size).
	VOID						SetProjectionSize(FLOAT fSize);
	FLOAT						GetProjectionSize(void) const { return m_fProjectionSize; }

protected:
	tEntityNode::PROJTEX_TYPE	m_theType;

    WX::Effect*					mProjectorEffect;

	//先是或者隐藏
	BOOL						m_bShow;
	//附加高度
	FLOAT						m_fAddHeight;
	// CYS-PROJSIZE: CY giu so nay lam thanh vien (+0x28, khoi tao 0 trong ctor 0x18001d090).
	FLOAT						m_fProjectionSize;

public:
	CWXObj_ProjTex(tEntityNode::PROJTEX_TYPE type, Ogre::SceneNode* pParentNode, FLOAT fAddHeight=170.0f);
	virtual ~CWXObj_ProjTex();
};