#include "StdAfx.h"
#include "RFFakeObjectManager.h"

#include <OgreException.h>
#include <OgreRoot.h>
#include <OgreRenderWindow.h>
#include <OgreCamera.h>
#include <OgreVector2.h>
#include <OgreOverlayManager.h>
#include <OgreRenderTarget.h>
#include <OgreRenderSystem.h>
#include <OgreOverlayElement.h>
#include <OgreCommon.h>
#include <OgreRenderTargetListener.h>
#include <OgreColourValue.h>
#include <OgreHardwarePixelBuffer.h>

#include "Core/WXFlags.h"
#include "Core/WXSystem.h"
#include "RenderSystem.h"
#include "AxTrace.h"
#include "TDException.h"
#include "..\WxRender\RenderSystem.h"
#include <OgreLogManager.h>
#include <OgreStringConverter.h>
#include <OgreParticleSystem.h>
#include "Object/RFObj_Actor.h"
#include "ModelSystem/WXLogicModel.h"

static bool cysLegacyPreviewEffects()
{
    static const bool old = [](){ char v[8] = {}; return GetEnvironmentVariableA("CYS_PREVIEW_FX_OLD",v,8)>0 && v[0]=='1'; }();
    return old;
}

// An RTT draw selects a visibility layer; it must not hide the actor logically.
// ParticleElement::setVisible(false) destroys mesh particles and sub-effects.
static void cysSelectPreview(tEntityNode* node, bool active)
{
    if (!node) return;
    if (!cysLegacyPreviewEffects() && node->GetType()==tEntityNode::ETYPE_ACTOR) {
        WX::LogicModel* model=static_cast<CRFObj_Actor*>(node)->GetActorImpl();
        if(model) model->setVisibleFlag(active ? WX::OVF_GUI_ELEMENTS : 0);
    } else node->SetVisible(active);
}

// CYS-MESHWIN 19/09: CYS_MESHWIN_DUMP read once (exactly "1"), like the other CYS_* switches of the client.
static bool cysMeshWinDumpEnabled()
{
	static int s_enabled = -1;
	if (s_enabled < 0)
	{
		char text[4] = {0};
		s_enabled = (::GetEnvironmentVariableA("CYS_MESHWIN_DUMP", text, sizeof(text)) == 1 && text[0] == '1') ? 1 : 0;
	}
	return s_enabled == 1;
}

//=====================================================================
//Ogre ViewPort渲染侦听
class CFakeRenderTargetListener : public Ogre::RenderTargetListener
{
public:
	virtual void preViewportUpdate(const Ogre::RenderTargetViewportEvent& evt)
	{
		Ogre::SceneManager* pSceneManager = CRenderSystem::GetMe()->GetRenderSystem()->getSceneManager();
		CFakeObjectManager::FakeObject* pObj = CFakeObjectManager::GetMe()->GetObjectAsViewPort(evt.source);
		if(!pObj) return;

		//----------------------------------------------------------
		//设置VisibleFlag
		m_nRenderMask = pSceneManager->getVisibilityMask();
		pSceneManager->setVisibilityMask(WX::OVF_GUI_ELEMENTS);
		CFakeObjectManager::GetMe()->SetActiveObject(pObj);

		//----------------------------------------------------------
		//设置环境光
		m_colAmbient = pSceneManager->getAmbientLight();
		pSceneManager->setAmbientLight(Ogre::ColourValue(1.0f, 1.0f, 1.0f, 1.0f));
		m_pLightModel->setPosition(pObj->pCamera->getPosition());
	}

    virtual void postViewportUpdate(const Ogre::RenderTargetViewportEvent& evt)
	{
		Ogre::SceneManager* pSceneManager = CRenderSystem::GetMe()->GetRenderSystem()->getSceneManager();

		CFakeObjectManager::FakeObject* pObj = CFakeObjectManager::GetMe()->GetObjectAsViewPort(evt.source);
		if(!pObj) return;

		//----------------------------------------------------------
		//恢复VisibleFlag
        static const bool metrics=[](){ char v[8]={};return GetEnvironmentVariableA("CYS_PREVIEW_FX_METRICS",v,8)>0 && v[0]=='1'; }();
        if(metrics && pObj->nUpdates%60==0) {
            const auto& projection=pObj->pCamera->getProjectionMatrix();
            Ogre::LogManager::getSingleton().logMessage("CYS-PREVIEW-ASPECT: object="+pObj->strName+
                " aspect="+Ogre::StringConverter::toString(pObj->pCamera->getAspectRatio())+
                " projection="+Ogre::StringConverter::toString(projection[0][0]/projection[1][1]));
            unsigned systems=0,particles=0;
            auto it=pSceneManager->getMovableObjectIterator("ParticleSystem");
            while(it.hasMoreElements()) {
                auto ps=static_cast<Ogre::ParticleSystem*>(it.getNext());
                if(ps->getVisibilityFlags()==WX::OVF_GUI_ELEMENTS && ps->isVisible() && ps->isAttached()) {
                    ++systems; particles+=(unsigned)ps->getNumParticles();
                }
            }
            Ogre::LogManager::getSingleton().logMessage("CYS-PREVIEW-FX: object="+pObj->strName+
                " systems="+Ogre::StringConverter::toString(systems)+" particles="+Ogre::StringConverter::toString(particles));
        }
		pSceneManager->setVisibilityMask(m_nRenderMask);
		CFakeObjectManager::GetMe()->SetActiveObject(0);

		//----------------------------------------------------------
		//恢复环境光
		pSceneManager->setAmbientLight(m_colAmbient);

		// CYS-MESHWIN 19/09: evidence dump of the UI render texture itself (not a screenshot of the composed
		// frame): CYS_MESHWIN_DUMP=1 writes the 3rd and the 30th update of every UI model to
		// ..\ScreenShots\mw-rtt-<object>-<n>.png (the folder the live rig already collects *.png from), so a live
		// run proves "the model reached the texture" with a pixel count instead of an eye. Off by default; the
		// #if 0 block that stood here (c:\<name>.tga on the 10th frame) was its 0.85 ancestor.
		++pObj->nUpdates;
		if (cysMeshWinDumpEnabled() && (pObj->nUpdates == 3 || pObj->nUpdates == 30) && pObj->pRenderTexture)
		{
			CHAR szFileName[MAX_PATH] = {0};
			::CreateDirectoryA("..\\ScreenShots", NULL);
			_snprintf(szFileName, MAX_PATH - 1, "..\\ScreenShots\\mw-rtt-%s-%u.png", pObj->strName.c_str(), pObj->nUpdates);
			try
			{
				pObj->pRenderTexture->writeContentsToFile(szFileName);
				Ogre::LogManager::getSingleton().logMessage(Ogre::String("[CYS-MESHWIN] rtt dump ") + szFileName +
					" " + Ogre::StringConverter::toString(pObj->pRenderTexture->getWidth()) + "x" +
					Ogre::StringConverter::toString(pObj->pRenderTexture->getHeight()));
			}
			catch (Ogre::Exception& e)
			{
				Ogre::LogManager::getSingleton().logMessage(Ogre::String("[CYS-MESHWIN] rtt dump failed: ") + e.getFullDescription());
			}
		}
	}

	//创建专用灯光
	void createSpecialLight(void)
	{
		m_pLightModel = 
			CRenderSystem::GetMe()->GetRenderSystem()->getSceneManager()->createLight("Light_ForFakeSystem");
		TDAssert(m_pLightModel);

		//设置VisibleFlag
		m_pLightModel->setVisibilityFlags(WX::OVF_GUI_ELEMENTS);
	}

	//销毁灯光
	void destroySpecialLight(void)
	{
		if (m_pLightModel)
			CRenderSystem::GetMe()->GetRenderSystem()->getSceneManager()->destroyLight(m_pLightModel);
		m_pLightModel = 0;
	}

	CFakeRenderTargetListener()
		:m_pLightModel(0)
	{
	}
protected:
	//用于临时储存场景渲染参数

	//Visible Flag
	unsigned int			m_nRenderMask;
	//环境光参数
	Ogre::ColourValue		m_colAmbient;
	//用于照亮模型的灯光
	Ogre::Light*			m_pLightModel;
};
CFakeRenderTargetListener	g_theListener;


//=====================================================================
CFakeObjectManager*	CFakeObjectManager::s_pMe = NULL;
CFakeObjectManager::CFakeObjectManager()
{
	s_pMe = this;
	m_fvPosition = Ogre::Vector3(0.f, 0.f, 0.f);
}

CFakeObjectManager::~CFakeObjectManager()
{
	if (s_pMe == this) s_pMe = 0;
}

// 初始化
VOID  CFakeObjectManager::Initial(VOID)
{
	//创建专用灯光
	g_theListener.createSpecialLight();
}

void  CFakeObjectManager::Release()
{
	m_mapIndexOfViewPort.clear();
	FakeObjectMap::iterator it = m_mapObject.begin();

	for(it=m_mapObject.begin(); it!=m_mapObject.end(); it++)
	{
		FakeObject& obj = it->second;
		//销毁对象
		_DestroyFakeNode(obj);
	}
	m_mapObject.clear();

	//销毁灯光
	g_theListener.destroySpecialLight();
}

// 把一个物体放到指定得摄影机位置
void CFakeObjectManager::CreateObject(LPCTSTR szObjName, tEntityNode* pNode, LPCTSTR szCameraName)
{
	CreateObject(szObjName, pNode, szCameraName, 256, 512, "");
}

void CFakeObjectManager::CreateObject(LPCTSTR szObjName, tEntityNode* pNode, LPCTSTR szCameraName,
	unsigned int width, unsigned int height, LPCTSTR backgroundName)
{
	if (!szObjName || !*szObjName || !pNode || !szCameraName || !backgroundName ||
		!width || !height || width > 4096 || height > 4096)
		OGRE_EXCEPT(Ogre::Exception::ERR_INVALIDPARAMS, "Invalid UI RTT creation parameters",
			"CFakeObjectManager::CreateObject");
	//物体不存在，创建新的渲染环境
	FakeObjectMap::iterator it = _GetFakeNode(szObjName,pNode,szCameraName,width,height,backgroundName);

	if(it == m_mapObject.end()) return;

	it->second.pEntityNode = pNode;
	//将需要渲染的实体放入渲染环境中

	//坐标转化(GFX->Game)
	Ogre::Vector3& fGfxPos = m_fvPosition;
	fVector3 fvGamePos;
	CRenderSystem::GetMe()->Axis_Trans(CRenderSystem::AX_GFX, 
		fVector3(fGfxPos.x, fGfxPos.y, fGfxPos.z),
		CRenderSystem::AX_GAME, fvGamePos);

	pNode->SetPosition(fvGamePos);
	//初始隐藏
    pNode->SetVisible(cysLegacyPreviewEffects() ? FALSE : TRUE);
    cysSelectPreview(pNode,false);
}

void CFakeObjectManager::SetActiveObject(FakeObject* pObj)
{
	FakeObjectMap::iterator it;
	for(it=m_mapObject.begin(); it!=m_mapObject.end(); it++)
	{
		FakeObject& theObj = it->second;

        cysSelectPreview(theObj.pEntityNode, &theObj == pObj);
		if (theObj.pBackground) theObj.pBackground->setActive(&theObj == pObj);
	}
}

VOID CFakeObjectManager::Debug_SetFakeCamera(int nType, float fValue)
{
	FakeObjectMap::iterator it = m_mapObject.find("Player_Head");
	if(it == m_mapObject.end()) return;

	FakeObject& obj = it->second;

	Ogre::Camera* pCam = it->second.pCamera;

#if 1
	switch(nType)
	{
	case 2:
		{

			obj.fCameraHeight += fValue;
			_UpdateCamera(obj);

			AxTrace(0, 0, "Height:%f", obj.fCameraHeight);
		}
		break;

	case 3:
		{
			obj.fCameraDistance += fValue;
			_UpdateCamera(obj);

			AxTrace(0, 0, "Distance:%f", obj.fCameraDistance);
		}
		break;
	case 4:
		{
			obj.fCameraPitch += fValue;
			_UpdateCamera(obj);

			AxTrace(0, 0, "Pitch:%f", obj.fCameraPitch);
		}
		break;
	default:
		return;
	}
#endif
}

void CFakeObjectManager::SetVisible(LPCTSTR szObjName, BOOL bVisible, float fAspectRatio)
{
	FakeObjectMap::iterator it = m_mapObject.find(szObjName);
	if(it == m_mapObject.end()) return;
	FakeObject& obj = it->second;


    if (!cysLegacyPreviewEffects() && obj.pEntityNode)
        obj.pEntityNode->SetVisible(bVisible);

	if(bVisible)
	{
		//设置摄像机AspectRatio
		obj.pCamera->setAspectRatio(fAspectRatio);
	}

	//设置是否自动刷新
	if(obj.pRenderTexture)
		obj.pRenderTexture->setAutoUpdated(bVisible==TRUE);
}

// CYS-MESHWIN 19/09: camera access for the CY MeshWindow *Ex Lua API. CY's fakeEx keeps (height, distance, pitch)
// per window (Lua: "local fHeight, fDistance, fPitch = X:GetCameraEx()"), this manager keeps them per object - the
// Game layer maps window -> object. xOffset is the optional 4th SetCameraEx argument (0 = none).
BOOL CFakeObjectManager::GetCamera(LPCTSTR szObjName, float* pHeight, float* pDistance, float* pPitch, float* pXOffset) const
{
	if (!szObjName) return FALSE;
	FakeObjectMap::const_iterator it = m_mapObject.find(szObjName);
	if (it == m_mapObject.end()) return FALSE;
	const FakeObject& obj = it->second;
	if (pHeight) *pHeight = obj.fCameraHeight;
	if (pDistance) *pDistance = obj.fCameraDistance;
	if (pPitch) *pPitch = obj.fCameraPitch;
	if (pXOffset) *pXOffset = obj.fCameraXOffset;
	return TRUE;
}

BOOL CFakeObjectManager::SetCamera(LPCTSTR szObjName, float fHeight, float fDistance, float fPitch, float fXOffset)
{
	if (!szObjName) return FALSE;
	FakeObjectMap::iterator it = m_mapObject.find(szObjName);
	if (it == m_mapObject.end() || !it->second.pCamera) return FALSE;
	// Finite values only: a NaN camera would poison every later frame of the texture.
	if (!(fHeight == fHeight) || !(fDistance == fDistance) || !(fPitch == fPitch) || !(fXOffset == fXOffset)) return FALSE;
	FakeObject& obj = it->second;
	obj.fCameraHeight = fHeight;
	obj.fCameraDistance = fDistance;
	obj.fCameraPitch = fPitch;
	obj.fCameraXOffset = fXOffset;
	_UpdateCamera(obj);
	return TRUE;
}

BOOL CFakeObjectManager::ResetCamera(LPCTSTR szObjName)
{
	if (!szObjName) return FALSE;
	FakeObjectMap::iterator it = m_mapObject.find(szObjName);
	if (it == m_mapObject.end() || !it->second.pCamera) return FALSE;
	FakeObject& obj = it->second;
	obj.fCameraHeight = obj.fDefaultHeight;
	obj.fCameraDistance = obj.fDefaultDistance;
	obj.fCameraPitch = obj.fDefaultPitch;
	obj.fCameraXOffset = 0.0f;
	_UpdateCamera(obj);
	return TRUE;
}

CFakeObjectManager::FakeObjectMap::iterator CFakeObjectManager::_GetFakeNode(LPCTSTR szNodeName, tEntityNode* pNode, LPCTSTR szCameraName,
	unsigned int width, unsigned int height, LPCTSTR backgroundName)
{
	//缺省摄像机的位置
	static const float s_fHeight	= 0.3f;
	static const float s_fDistance = 1.2f;
	static const float s_fPitch = 0.21f;

	FakeObjectMap::iterator it = m_mapObject.find(szNodeName);
	if(it != m_mapObject.end()) return it;

	//不存在，创建
	FakeObject newNode;
	newNode.strName = szNodeName;
	try
	{

	//--------------------------------------------------
	//创建RenderTarget
	Ogre::TexturePtr ptrTex =
		Ogre::TextureManager::getSingleton().createManual(
			Ogre::String(szNodeName) + "_RenderTexture",
			Ogre::ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME,
			Ogre::TEX_TYPE_2D,
			width, height, 1, 0,
			Ogre::PF_R8G8B8A8,
			Ogre::TU_RENDERTARGET,
			0);

	newNode.pTexturePtr = ptrTex;
	newNode.pRenderTexture = ptrTex->getBuffer()->getRenderTarget();
	
	//缺省不刷新
	newNode.pRenderTexture ->setAutoUpdated(false);
	newNode.pRenderTexture ->addListener(&g_theListener);

	//--------------------------------------------------
	//放置摄像机
	Ogre::SceneManager* pScnManager = CRenderSystem::GetMe()->GetRenderSystem()->getSceneManager();
	newNode.pCamera = pScnManager->createCamera(Ogre::String(szNodeName) + "_Camera");

	//放缩系数
	fVector3 fvScale = CRenderSystem::GetMe()->GetSacle();

	newNode.fCameraHeight=s_fHeight;
	newNode.fCameraDistance=s_fDistance;
	newNode.fCameraPitch=s_fPitch;

	// CYS-MESHWIN 19/09: the Game layer may hand the camera VALUES instead of a property name ("=<height>;<distance>"):
	// in CY/B data the object property Camera_Main is a ROW ID of Model_Parameter.txt (id, name, height, distance;
	// row 0 "默认(必须有这行)" = 0.95/5.4, 3 男主角 = 1.0/6.0, 489 宠物 = 1.8/9.0), which this 0.85 source never
	// understood - it parsed "h;d" only, so every CY model got the 0.85 defaults 0.3/1.2 and the SelfEquip portrait
	// showed the legs (live-3 12:08). The DBC lives in Game.exe, so CFakeObjSystem resolves the row and passes "=h;d".
	STRING szUserCameraValue;
	if (szCameraName && szCameraName[0] == '=')
		szUserCameraValue = szCameraName + 1;
	else
		pNode->Actor_GetObjectProperty(szCameraName, szUserCameraValue);
	if(szUserCameraValue.size() > 2 && szUserCameraValue.find(';') != STRING::npos)
	{
		sscanf(szUserCameraValue.c_str(), "%f;%f", &(newNode.fCameraHeight), &(newNode.fCameraDistance));
	}
	Ogre::LogManager::getSingleton().logMessage(Ogre::String("[CYS-MESHWIN] rtt camera ") + szNodeName + " spec=" +
		(szCameraName ? szCameraName : "") + " value=" + szUserCameraValue + " -> h=" +
		Ogre::StringConverter::toString(newNode.fCameraHeight) + " d=" + Ogre::StringConverter::toString(newNode.fCameraDistance) +
		" p=" + Ogre::StringConverter::toString(newNode.fCameraPitch));
	// CYS-MESHWIN: remember the starting camera for RestPositonEx / ResetCamera.
	newNode.fDefaultHeight = newNode.fCameraHeight;
	newNode.fDefaultDistance = newNode.fCameraDistance;
	newNode.fDefaultPitch = newNode.fCameraPitch;
	newNode.fCameraXOffset = 0.0f;

	//设置摄像机
	_UpdateCamera(newNode);

	newNode.pCamera->setNearClipDistance(10.f);
	newNode.pCamera->setAspectRatio((float)width/height);
	newNode.pCamera->setFOVy(Ogre::Degree(45.0f));	// 经验值
	newNode.pCamera->setProjectionType(Ogre::PT_PERSPECTIVE);	//透视投影 (平行投影 Ogre::PT_ORTHOGRAPHIC)

	//--------------------------------------------------
	//创建ViewPort
	newNode.pViewPort = newNode.pRenderTexture->addViewport(newNode.pCamera, 1);
	newNode.pViewPort->setClearEveryFrame(true);
	newNode.pViewPort->setBackgroundColour(Ogre::ColourValue(156.0f/255,123.0f/255,74.0f/255,0));
	newNode.pViewPort->setOverlaysEnabled(false);
	newNode.pViewPort->setSkiesEnabled(false);
	newNode.pBackground.reset(new CysUiMeshBackground);
	newNode.pBackground->create(*pScnManager, szNodeName, backgroundName);
	}
	catch (...)
	{
		_DestroyFakeNode(newNode);
		throw;
	}

	//--------------------------------------------------
	//加入Map
	m_mapObject.insert(std::make_pair(newNode.strName, newNode));

	it = m_mapObject.find(newNode.strName);
	TDAssert(it != m_mapObject.end());

	//加入索引Map
	m_mapIndexOfViewPort.insert(std::make_pair(newNode.pViewPort, &(it->second)));
	return it;
}

//更新摄像机
void CFakeObjectManager::_UpdateCamera(FakeObject& node)
{
	//放缩系数
	fVector3 fvScale = CRenderSystem::GetMe()->GetSacle();

	//Lookat
	Ogre::Vector3 fvLookAtPos = m_fvPosition;
	// CYS-MESHWIN: fCameraXOffset shifts eye and look-at together (CY SetCameraEx 4th argument); 0 keeps the 0.85 camera.
	fvLookAtPos += Ogre::Vector3(node.fCameraXOffset*fvScale.x, node.fCameraHeight*fvScale.y, 0.0f);

	//EyePos
	Ogre::Vector3 fvEyePosPos = m_fvPosition;
	fvEyePosPos += Ogre::Vector3(node.fCameraXOffset*fvScale.x,
		(node.fCameraHeight+node.fCameraDistance*node.fCameraPitch)*fvScale.y, node.fCameraDistance*fvScale.z);

	node.pCamera->setPosition(fvEyePosPos);
	node.pCamera->lookAt(fvLookAtPos);
}

void CFakeObjectManager::_DestroyFakeNode(FakeObject& obj)
{
	obj.pBackground.reset();
	if (obj.pRenderTexture)
	{
		obj.pRenderTexture->removeListener(&g_theListener);
		obj.pRenderTexture->removeAllViewports();
		obj.pViewPort = 0;
	}
	//销毁摄像机
	if (obj.pCamera)
		CRenderSystem::GetMe()->GetRenderSystem()->getSceneManager()->destroyCamera(obj.pCamera);
	obj.pCamera = 0;

	//销毁RenderTexture
	if (!obj.pTexturePtr.isNull())
		Ogre::TextureManager::getSingleton().remove(obj.pTexturePtr->getHandle());
	obj.pTexturePtr.setNull();
	obj.pRenderTexture = 0;
}

//销毁
void CFakeObjectManager::DestroyObject(LPCTSTR szObjName)
{
	FakeObjectMap::iterator it = m_mapObject.find(szObjName);
	if(it == m_mapObject.end()) return;
    // Unhook is a real close/rebind, unlike postViewportUpdate. Stop hidden
    // particle systems before releasing their viewport/camera.
    if(!cysLegacyPreviewEffects() && it->second.pEntityNode)
        it->second.pEntityNode->SetVisible(FALSE);

	//先从索引表中删除
	std::map< Ogre::Viewport*, FakeObject* >::iterator itIndex;
	itIndex = m_mapIndexOfViewPort.find(it->second.pViewPort);
	if(itIndex != m_mapIndexOfViewPort.end())
	{
		m_mapIndexOfViewPort.erase(itIndex);
	}

	//删除节点数据
	_DestroyFakeNode(it->second);

	m_mapObject.erase(it);
}

CFakeObjectManager::FakeObject*	CFakeObjectManager::GetObjectAsViewPort(Ogre::Viewport* pViewPort)
{
	std::map< Ogre::Viewport*, FakeObject* >::iterator it;
	it = m_mapIndexOfViewPort.find(pViewPort);

	if(it == m_mapIndexOfViewPort.end()) return NULL;

	return it->second;
}
