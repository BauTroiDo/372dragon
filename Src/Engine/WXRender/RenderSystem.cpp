#include "RenderSystem.h"
#include "CysOfflineUiCapture.h"
#include "Global.h"
#include "TDException.h"
#include "TDUtil.h"
#include "AxTrace.h"
#include <OgreException.h>
#include <OgreRoot.h>
#include <OgreRenderWindow.h>
#include <OgreCamera.h>
#include <OgreSceneNode.h> // CYS: verify login actor scale at the real scene node.
#include <OgreVector2.h>
#include <OgreOverlayManager.h>
#include <OgreRenderTarget.h>
#include <OgreOverlayElement.h>
#include <OgreOverlayContainer.h> // CYS: inspect optional debug overlay children without throwing

#include "Core/WXSystem.h"
#include "Core/TerrainData.h"
#include "Core/FrameStatsListener.h"
#include "Core/WXObjectProxy.h"
#include "Camera/Camera_CharSel.h"
#include "Camera/Camera_Scene.h"
#include "./Object/RFObjDummy.h"
#include "./Object/RFObj_Static.h"
#include "./Object/RFObj_Model.h"
#include "./Object/RFObj_Actor.h"
#include "CysLoginSceneBridge.h"
#include "Core/WXFlags.h"
#include "DebugPanel.h"
#include "HelpPanel.h"
#include "OgreLogmanager.h"
#include "OgreCommon.h"
#include "Core/WXSceneInfo.h"
#include "Core/Terrain.h"
#include "Core/WXResourceSolverHelper.h"
#include "PostFilter/WXPostFilters.h"
#include "PostFilter/WXPostFilterManager.h"
#include "CYS/PostFX/CysPostFx.h" // CYS: CY-Source post chain, applied from System.cfg at start-up and at run time
#include "CYS/Water/CysWaterRender.h" // CYS-WATER: CY 3.71 water render targets (Docs/specs/render/water-cy_vi.md)
#include "CYS/Scene/CYSEnvironment.h" // CYS-SKY: CY day clock of the procedure scenes (Docs/specs/render/sky-enscene-cy_vi.md)
#include "ResourceLoadListener.h"
#include "Core/WXExpatParser.h"
#include "TDVariable.h"
#include "TerrainGrid.h"
#include "TDKernel.h"
#include <OgreParticleSystemManager.h>
#include <OgreParticleSystem.h>
#include "TDProfile.h"
#include "MaterialSystem/CysMaterialSystem.h" // CYS
#include "CYS/Shadow/CYSShadowHost.h" // CYS-SHADOW
#include "TDSound.h"
#include "ModelSystem/WXLogicModel.h"
#include "RFFakeObjectManager.h"
#include "CysUiMeshBridge.h"
#include <type_traits>
#include <cmath>
#include "Core/WXSceneInfo.h"
#include "Core/WXEnviromentObject.h"
#include <OgreMeshManager.h>
#include <OgreSkeletonManager.h>
#include <OgreMaterialManager.h>
#include <OgreSceneManager.h>
#include <OgreStringConverter.h>
#include "TDWorldSystem.h"
#include "TDEventDefine.h"
#include "Core/WXLogicModelObject.h"
#include "TDTimeSystem.h"
#include "ResourceProvider.h"
#include "ModelSystem/WXLogicModelManager.h"

const CHAR CRenderSystem::sz32BitTexturesVar[]				= "View_ColorQuality"; //"yszl";//颜色质量，比特数(16/32位)
const CHAR CRenderSystem::szDefaultTextureFilteringVar[]	= "View_TextureFiltering";//"cy";		//采样(高/中/低)
const CHAR CRenderSystem::szLightmapQualityVar[]			= "View_LightmapQuality";//"dxyy";	//地形阴影(高/低/无)
const CHAR CRenderSystem::szAnimationQualityVar[]			= "View_ObjectMove";//"wtdh";	//静态物体动画(开/关)
const CHAR CRenderSystem::szPostFilterEnabledVar[]			= "View_FullScreenLight";//"qpfg";	//全屏泛光效果(开/关)
const CHAR CRenderSystem::szFSAAVar[]						= "View_Fanhunjiao";//"fhj";	//反混角(1/2/4)
const CHAR CRenderSystem::szShadowTechniqueVar[]			= "View_HumanLightmap";//"rwyy";	//人物阴影(开/关)
const CHAR CRenderSystem::szvsyncVar[]						= "View_Aplomb";//"cztb";	//垂直同步(开/关)

CRenderSystem* CRenderSystem::s_pMe = NULL;
WX_IMPLEMENT_DYNAMIC(CRenderSystem, GETCLASS(tNode));

// CYS: System.cfg lookup for WX::CysPostFx::applyStartup (a key the configuration does not set gets its default).
static bool _CysPostFxLookup(void* /*user*/, const Ogre::String& key, Ogre::String& value)
{
	BOOL bHave = FALSE;
	value = g_pVaribleSys->GetAs_String(key.c_str(), &bHave);
	return bHave == TRUE;
}

CRenderSystem::CRenderSystem(VOID)
	: m_pRenderSystem(NULL)
	, m_pCamera_Current(NULL)
{
	s_pMe = this;

	m_pTerrainGrid = NULL;

	m_bDeathMode = FALSE;
	m_nDeachModePercent = 0;

	m_pCamera_Current = 0;
	m_pCamera_CharView = 0;
	m_pCamera_Scene = 0;
	m_pTerrainGrid = 0;
	m_pRaySceneQuery = 0;
	m_pPostFilterManager = 0;
	m_pEnviromentObject = 0;
	m_pDebugPanel = 0;
	m_pFakeObjectManager = 0;

	//创建Fiary
	m_pRenderSystem = new WX::System;
}

CRenderSystem::~CRenderSystem(VOID)
{
}

VOID CRenderSystem::Release(VOID)
{
	if( m_pFakeObjectManager )
	{
		m_pFakeObjectManager->Release();
		delete m_pFakeObjectManager;
		m_pFakeObjectManager = NULL;
	}
	if(m_pCamera_CharView) 
	{
		delete m_pCamera_CharView;
		m_pCamera_CharView = NULL;
	}
	if(m_pCamera_Scene) 
	{
		delete m_pCamera_Scene;
		m_pCamera_Scene = NULL;
	}

	if(m_pDebugPanel)
	{
		delete m_pDebugPanel;
		m_pDebugPanel = NULL;
	}

	if(m_pRaySceneQuery)
	{
		m_pRenderSystem->getSceneManager()->destroyQuery(m_pRaySceneQuery);
		m_pRaySceneQuery = NULL;
	}

	if(m_pTerrainGrid)
	{
		delete m_pTerrainGrid;
		m_pTerrainGrid = NULL;
	}

	// CYS-SHADOW: atlas, cascade cameras and caster materials go before the scene manager and Root
	WX::CYSShadowHost::stop();
	WX::CysWaterRender::uninstall(); // CYS-WATER: render targets and the mirror camera before the scene goes

	// CYS: the material system caches material/program references; release them before Ogre goes
	CYS::MaterialSystem::getSingleton().uninstall();

	if(m_pRenderSystem)
	{
		delete m_pRenderSystem;	m_pRenderSystem = NULL;
	}
}

HWND CRenderSystem::GetWindow(VOID) const
{ 
	return g_hMainWnd; 
}

BOOL CRenderSystem::Axis_CheckValid(AXIS_TYPE typeSource, const fVector3& fvAxis)
{
	register WX::TerrainData* pTerrainData = m_pRenderSystem->getTerrainData();
	//尚未加载
	if(pTerrainData && (pTerrainData->getXSize()==0 || pTerrainData->getZSize()==0))
	{
		pTerrainData = 0;
	}

	switch(typeSource)
	{
		//-----------------------------------------------
	case AX_GAME:
	case AX_PLAN:
		{
			if(pTerrainData)
				return pTerrainData->isValidGrid(std::make_pair((INT)fvAxis.x, (INT)fvAxis.z));
			else
				return TRUE;
		}
		break;

		//-----------------------------------------------
	case AX_GFX:
		{
			if(pTerrainData)
				return pTerrainData->isValidCoord(fvAxis.x, fvAxis.z);
			else
				return TRUE;
		}
		break;

		//-----------------------------------------------
	case AX_SCREEN:
		{
			RECT rect;
			GetClientRect(g_hMainWnd, &rect);

			POINT pt;
			pt.x = (INT)fvAxis.x;
			pt.y = (INT)fvAxis.y;

			return (PtInRect(&rect, pt)==TRUE);
		}
		break;

	default:
		return FALSE;
	}

	return FALSE;
}

BOOL CRenderSystem::Axis_Trans(	AXIS_TYPE typeSource, const fVector3& fvSource,
								AXIS_TYPE typeTar,			fVector3& fvTarget)
{
	register WX::TerrainData*	pTerrainData = m_pRenderSystem->getTerrainData();
	//尚未加载
	if(pTerrainData && (pTerrainData->getXSize()==0 || pTerrainData->getZSize()==0))
	{
		pTerrainData = 0;
	}

	fVector3 fvScale = GetSacle();

	//检查是否是合法的坐标
	fvTarget = fvSource;
	if(!Axis_CheckValid(typeSource, fvSource)) return FALSE;
	if(typeSource == typeTar) return TRUE;

	switch(typeSource)
	{
		//-----------------------------------------------
	case AX_GAME:
		{
			if(AX_PLAN==typeTar) return TRUE;
			else if(AX_GFX == typeTar)
			{
				if(pTerrainData)
				{
					fvTarget.x = pTerrainData->mPosition.x + (FLOAT)fvSource.x * pTerrainData->mScale.x;
					fvTarget.y = pTerrainData->mPosition.y + (FLOAT)fvSource.y * pTerrainData->mScale.y;
					fvTarget.z = pTerrainData->mPosition.z + (FLOAT)fvSource.z * pTerrainData->mScale.z;
				}
				else
				{
					fvTarget.x = (FLOAT)fvSource.x * fvScale.x;
					fvTarget.y = (FLOAT)fvSource.y * fvScale.y;
					fvTarget.z = (FLOAT)fvSource.z * fvScale.z;
				}
				return TRUE;
			}
			else if(AX_SCREEN==typeTar)
			{
				TDThrow("(AX_GAME->AX_SCREEN) Not support yet!");
			}
		}
		break;
		//-----------------------------------------------
	case AX_PLAN:
		{
			if(!pTerrainData) return FALSE;

			FLOAT fGfxX = pTerrainData->mPosition.x + (FLOAT)fvSource.x * pTerrainData->mScale.x;
			FLOAT fGfxZ = pTerrainData->mPosition.z + (FLOAT)fvSource.z * pTerrainData->mScale.z;

			if(AX_GAME==typeTar)
			{
				//取得相地形高度作为Y坐标(游戏坐标)
				fvTarget.y = (pTerrainData->getHeightAtGrid(fvSource.x, fvSource.z)-pTerrainData->mPosition.y)/ pTerrainData->mScale.y;
				return TRUE;
			}
			else if(AX_GFX == typeTar)
			{
				//取得相地形高度作为Y坐标
				fvTarget.x = fGfxX;
				fvTarget.z = fGfxZ;
				fvTarget.y = pTerrainData->getHeightAtGrid(fvSource.x, fvSource.z);
				return TRUE;
			}
			else if(AX_SCREEN==typeTar)
			{
				TDThrow("(AX_PLAN->AX_SCREEN) Not support yet!");
			}
		}
		break;

		//-----------------------------------------------
	case AX_GFX:
		{
			if(AX_GAME==typeTar || AX_PLAN==typeTar)
			{
				if(pTerrainData)
				{
					fvTarget.x = (fvSource.x-pTerrainData->mPosition.x)/pTerrainData->mScale.x;
					fvTarget.y = (fvSource.y-pTerrainData->mPosition.y)/pTerrainData->mScale.y;
					fvTarget.z = (fvSource.z-pTerrainData->mPosition.z)/pTerrainData->mScale.z;
				}
				else
				{
					fvTarget.x = (fvSource.x)/fvScale.x;
					fvTarget.y = (fvSource.y)/fvScale.y;
					fvTarget.z = (fvSource.z)/fvScale.z;
				}
				return TRUE;
			}
			else if(AX_SCREEN==typeTar)
			{
				//TDThrow("(AX_GFX->AX_SCREEN) Not support yet!");
				if(!pTerrainData) return FALSE;
				
				//得到Ogre相机
				Ogre::Camera* pOgreCamera = m_pCamera_Current->GetOgreCamera();
				if(!pOgreCamera) return FALSE;
				if(!(pOgreCamera->isVisible(Ogre::Vector3(fvSource.x, fvSource.y, fvSource.z)))) return FALSE;

				// x:[-1w, 1w]	z:[-1h, 1h]
				Ogre::Vector3 vRet = pOgreCamera->getProjectionMatrix()* pOgreCamera->getViewMatrix() * Ogre::Vector3(fvSource.x, fvSource.y, fvSource.z);

				int nWidth  = m_pRenderSystem->getViewport()->getActualWidth();
				int nHeight = m_pRenderSystem->getViewport()->getActualHeight();

				fvTarget.x = (( vRet.x + 1.0f)*nWidth/2.0f);
				fvTarget.y = ((-vRet.y + 1.0f)*nHeight/2.0f);
					
				return TRUE;
			}
		}
		break;

		//-----------------------------------------------
	case AX_SCREEN:
		{
			if(!pTerrainData) return FALSE;

			Ogre::Vector3 vRenderPos;
			BOOL bRet = m_pRenderSystem->getTerrainIntersects(WX::Point((INT)fvSource.x, fvSource.y), vRenderPos);
			if(!bRet) return FALSE;

			if(AX_GAME==typeTar || AX_PLAN==typeTar)
			{
				return Axis_Trans(AX_GFX, fVector3(vRenderPos.x, vRenderPos.y, vRenderPos.z), AX_GAME, fvTarget);
			}
			else if(AX_GFX==typeTar)
			{
				fvTarget = fVector3(vRenderPos.x, vRenderPos.y, vRenderPos.z);
				return TRUE;
			}
		}
		break;
	}
	return FALSE;
}

fVector3 CRenderSystem::GetSacle(VOID) const
{
	register WX::TerrainData* pTerrainData = m_pRenderSystem->getTerrainData();
	if(pTerrainData && pTerrainData->getXSize()>0 && pTerrainData->getZSize()>0)
		return fVector3(pTerrainData->mScale.x, pTerrainData->mScale.y, pTerrainData->mScale.z);
	else
		return fVector3(100.0f, 100.0f, 100.0f);
}

//初始化
VOID CRenderSystem::Initial(VOID* pParam)
{
#if (_MSC_VER >= 1400)
//	std::locale langLocale("");
//	std::locale::global(langLocale);
	setlocale( LC_CTYPE, "" );
#endif
	//---------------------------------------------------------
	//取得渲染窗口句柄
	TDAssert(pParam);
	HWND hMainWnd = *((HWND*)pParam);
	g_hMainWnd = hMainWnd;

	g_pVaribleSys = (tVariableSystem*)g_pKernel->GetNode("bin\\var");
	TDAssert(g_pVaribleSys);

	g_pEventSys = (tEventSystem*)g_pKernel->GetNode("bin\\event");
	TDAssert(g_pEventSys);

	//---------------------------------------------------------
	//初始化RenderSystem
	m_pRenderSystem->init("WXResources.cfg", "", "", "WXRender.log");

	//---------------------------------------------------------
	//加载OGRE插件
	g_pDebuger = (tDebuger*)g_pKernel->GetNode("bin\\debuger");

	g_pSoundSystem = (tSoundSystem*)g_pKernel->GetNode("bin\\snd");
	TDAssert(g_pSoundSystem);

	g_pWorldSystem = (tWorldSystem*)g_pKernel->GetNode("bin\\worldman");
	TDAssert(g_pWorldSystem);

	g_pTimeSystem = (tTimeSystem*)g_pKernel->GetNode("bin\\time");
	TDAssert(g_pTimeSystem);

	g_pResourceProvider = (CResourceProvider*)g_pKernel->GetNode("bin\\resprovider");
	TDAssert(g_pResourceProvider);

	//STRING str = g_pVaribleSys->GetAs_String("Gfx_API");
	Ogre::Root* pTheRoot = &(Ogre::Root::getSingleton());

	//选择渲染系统
	//if(stricmp(g_pVaribleSys->GetAs_String("Gfx_API").c_str(), "Direct3D") == 0)
	//{
	//	pTheRoot->loadPlugin("RenderSystem_Direct3D9.dll");
	//	pTheRoot->setRenderSystem(pTheRoot->getRenderSystemByName("Direct3D9 Rendering Subsystem"));
	//}
	//else if(stricmp(g_pVaribleSys->GetAs_String("Gfx_API").c_str(), "OpenGL") == 0)
	//{
	//	TDThrow("Don't Support GL RenderSystem!");
	//	//pTheRoot->loadPlugin("RenderSystem_GL.dll");
	//	//pTheRoot->setRenderSystem(pTheRoot->getRenderSystemByName("OpenGL Rendering Subsystem"));
	//}
	//else 
	//	TDThrow("UnKnown RenderSystem!");


	//使用D3D渲染
	pTheRoot->loadRenderPlugins_D3D9();
	//加载其他插件
	pTheRoot->loadInnerPlugins();
	// CYS: B/Fairy runtime material system (vertex program pairing for the pixel-shader-only
	// MaterialTemplates, shader variants, per-instance constants) + .\ShaderCache; before the
	// resource scripts are parsed in setup() below, because they compile the programs.
	CYS::MaterialSystem::getSingleton().install(".\\ShaderCache", "");
	// CYS-SHADOW: shadow receivers are compiled with SHADOWMAP_TYPE before any model material is resolved
	CYS::MaterialSystem::getSingleton().setGlobalDefine("SHADOWMAP_TYPE",
		WX::CYSShadowHost::shaderDefine(WX::CYSShadowHost::readConfig(_CysPostFxLookup, NULL)));
	//pTheRoot->loadPlugin("Plugin_ParticleFX.dll");
	//pTheRoot->loadPlugin("Plugin_ParticleFX2.dll");
	//pTheRoot->loadPlugin("Plugin_OctreeSceneManager.dll");
	//pTheRoot->loadPlugin("Plugin_CgProgramManager.dll");

	//分析资源
	ScriptParsingListener listener;
	try 
	{
		//传入渲染窗口句柄
		WX::System::NameValuePairList ViewSetting;
		INT nFSAA = g_pVaribleSys->GetAs_Int(szFSAAVar);
		INT nVsync = g_pVaribleSys->GetAs_Int(szvsyncVar);

		switch(nFSAA)
		{
		case 0:
			ViewSetting["FSAA"]  = Ogre::StringConverter::toString(0);
			break;
		case 1:
			ViewSetting["FSAA"]  = Ogre::StringConverter::toString(2);
			break;
		case 2:
			ViewSetting["FSAA"]  = Ogre::StringConverter::toString(4);
			break;
		default:
			ViewSetting["FSAA"]  = Ogre::StringConverter::toString(0);
			break;
		}

		// CYS: the CY-Source post chain renders the scene into its own 16-bit float target and View_Fanhunjiao
		// means FXAA there (client_GL): a multisampled back buffer would only hold the final copy and the UI.
		{
			BOOL bHave = FALSE;
			const STRING& postFx = g_pVaribleSys->GetAs_String("Gfx_PostFX", &bHave);
			if (!bHave || !(postFx == "0" || postFx == "false" || postFx == "off" || postFx == "no"))
				ViewSetting["FSAA"] = Ogre::StringConverter::toString(0);
		}

		if(nVsync == 1)
			ViewSetting["vsync"] = "true";
		else
			ViewSetting["vsync"] = "false";

		m_pRenderSystem->setup((size_t)(UINT_PTR)g_hMainWnd, &ViewSetting); // CYS: was (WX::ulong), 32-bit on Win64

		//关闭OGRE图标
		m_pRenderSystem->getFrameStatsListener()->showLogoPanel(FALSE);
		
		//状态板
		m_pRenderSystem->getFrameStatsListener()->showStatPanel(FALSE);

		//创建射线交集
		m_pRaySceneQuery = m_pRenderSystem->getSceneManager()->createRayQuery(Ogre::Ray());
        m_pRaySceneQuery->setSortByDistance(TRUE);

		//---------------------------------------------------------
		//设置DebugPanel
		// CYS: modern data uses TLBB/*; optional debug UI must not block engine startup.
		const char* debugPrefixes[] = { "TLBB/", "WX/" };
		for (size_t i = 0; i < sizeof(debugPrefixes) / sizeof(debugPrefixes[0]); ++i)
		{
			const Ogre::String prefix(debugPrefixes[i]);
			Ogre::Overlay* overlay = Ogre::OverlayManager::getSingleton().getByName(prefix + "DebugOverlay");
			if (!overlay) continue;
			Ogre::OverlayContainer* stat = overlay->getChild(prefix + "StatPanel");
			Ogre::OverlayContainer* hit = overlay->getChild(prefix + "HitObjPanel");
			Ogre::OverlayElement* text = NULL;
			if (hit)
			{
				// CYS: iterate instead of getOverlayElement/getChild, which throw if missing.
				Ogre::OverlayContainer::ChildIterator child = hit->getChildIterator();
				while (child.hasMoreElements())
				{
					Ogre::OverlayElement* element = child.getNext();
					if (element->getName() == prefix + "HitObjText")
					{
						text = element;
						break;
					}
				}
			}
			if (!stat || !hit || !text)
			{
				Ogre::LogManager::getSingleton().logMessage("[CYS] Debug overlay incomplete: " + prefix + "DebugOverlay; trying fallback");
				continue;
			}
			m_pDebugPanel = new CDebugPanel(overlay, stat, hit, text, m_pRenderSystem->getRenderWindow());
			Ogre::LogManager::getSingleton().logMessage("[CYS] Debug overlay selected: " + prefix + "DebugOverlay");
			break;
		}
		if (!m_pDebugPanel)
			Ogre::LogManager::getSingleton().logMessage("[CYS] Debug overlay unavailable (TLBB/*, WX/*); debug panel skipped");

		//---------------------------------------------------------
		//创建摄像机
		{
			//设置摄像机
			//取得环境变量
		
			BOOL bHave;
			FLOAT fCamera_MinDistance = g_pVaribleSys->GetAs_Float("Camera_MinDistance", &bHave);
			if(bHave) CCamera_Scene::MIN_DISTANCE = fCamera_MinDistance;

			FLOAT fCamera_MaxDistance = g_pVaribleSys->GetAs_Float("Camera_MaxDistance", &bHave);
			if(bHave) CCamera_Scene::MAX_DISTANCE = fCamera_MaxDistance;

			FLOAT fCamera_Pitch = g_pVaribleSys->GetAs_Float("Camera_Pitch", &bHave);
			if(bHave) CCamera_Scene::STATIC_PITCH = -fCamera_Pitch*TDU_PI/180.0f;
		}

		m_pCamera_CharView = new CCamera_CharSel(m_pRenderSystem->getCamera());
		m_pCamera_Scene = new CCamera_Scene(m_pRenderSystem->getCamera());
		m_pCamera_Scene->SetDistance(CCamera_Scene::MAX_DISTANCE);
		// CYS: khoa camera CY 3.71 (View_DefaultCamera, Camera_Pitch_Min/Max, Camera_Zoom, Camera_Smooth ...)
		Camera_ApplyVariables();

		m_pCamera_Current = m_pCamera_CharView;

		//--------------------------------------------
		//初始化PostFilter系统
		m_pPostFilterManager = m_pRenderSystem->getPostFilterManager();
		//注册所有全局渲染器
		WX::registerAllPostFilterFactories(m_pPostFilterManager);
		m_pPostFilterManager->createPostFilter("Floodlighting", m_pRenderSystem->getViewport());
//		m_pPostFilterManager->createPostFilter("Bloom", m_pRenderSystem->getViewport());
//		m_pPostFilterManager->createPostFilter("HeatVision", m_pRenderSystem->getViewport());
		m_pPostFilterManager->createPostFilter("Fade", m_pRenderSystem->getViewport());
		// CYS: CY-Source post filters (CYS/PostFX): System.cfg values act at start-up as a VARIABLE_CHANGED event
		// would (doc 08 3.6); keys it does not set get client_GL's look (FXAA + NewHDRBloom, B's height fog).
		WX::CysPostFx::applyStartup(m_pPostFilterManager, m_pRenderSystem->getViewport(), _CysPostFxLookup, NULL);
		// CYS-SHADOW: cascaded shadow maps of the scene camera (atlas allocated once, never per scene)
		WX::CYSShadowHost::start(WX::CYSShadowHost::readConfig(_CysPostFxLookup, NULL),
			m_pRenderSystem->getSceneManager(), m_pRenderSystem->getCamera());
		// CYS-WATER: new water as CY 3.71 (queue 76/77 split, scene_buffer copy, depth node, mirror texture)
		WX::CysWaterRender::install(m_pRenderSystem);

		//--------------------------------------------
		//设置特效系统的声音播放函数
		WX::LogicModel::SetPlaySoundFuncton((OnPlaySound)(g_pSoundSystem->GetPlaySoundFunc()));
		WX::LogicModel::SetStopSoundFunction((OnStopSound)(g_pSoundSystem->GetStopSoundFunc()));
		WX::LogicModel::SetGetHeightInWorldListener((GetHeightInWorld)(g_pWorldSystem->GetTerrainHeightFunc()));

		// 初始化 fake obeject manager
		m_pFakeObjectManager = new CFakeObjectManager;
		m_pFakeObjectManager->Initial();

//		WX::Effect::setDefaultIterativeInterval(0.01f);
		Ogre::ParticleSystem::setDefaultIterationInterval(0.033f);
		// CYS-PERF-FIX nonvis: B (client_GL Bin64/Render.dll) calls setDefaultNonVisibleUpdateTimeout(5.0f) right after
		// setDefaultIterationInterval(0.033f): a particle system out of view for 5 s stops updating until it is seen.
		Ogre::ParticleSystem::setDefaultNonVisibleUpdateTimeout(5.0f); // CYS-PERF-FIX nonvis

		//系统设置接口挂接变量控制系统
		g_pEventSys->RegisterEventHandle("VARIABLE_CHANGED",_OnVariableChangedEvent);

		//恢复上次颜色设置
		g_pEventSys->PushEvent(
            GE_VARIABLE_CHANGED, 
			sz32BitTexturesVar, 
			g_pVaribleSys->GetAs_String(sz32BitTexturesVar).c_str());

	} 
	catch(const Ogre::Exception& e)
	{
        BOOL rethrow = TRUE;

        if (e.getNumber() == Ogre::Exception::ERR_DUPLICATE_ITEM)
        {
            if (e.getSource() == "ResourceManager::add")
            {
                if (Ogre::StringUtil::endsWith(listener._scriptName, ".material", TRUE))
                {
                    char materialName[256];
                    if (sscanf(e.getDescription().c_str(), "Resource with the name %255s already exists.", materialName) == 1)
                    {
                        Ogre::MaterialPtr material = Ogre::MaterialManager::getSingleton().getByName(materialName);
                        if (!material.isNull())
                        {
                            char message[1024];

                            Ogre::StringVectorPtr currentNames = WX::findResourceFilenames(listener._groupName, listener._scriptName);
                            const Ogre::String& currentName = currentNames.isNull() || currentNames->empty() ? listener._scriptName : currentNames->front();
                            if (material->getOrigin().empty())
                            {
								_snprintf(message, 1024,
										("Predefined material \"%s\" duplicated in file \"%s\", the application will exit."),
                                        material->getName().c_str(), currentName.c_str());
                            }
                            else
                            {
                                Ogre::StringVectorPtr originNames = WX::findResourceFilenames(material->getGroup(), material->getOrigin());
                                const Ogre::String& originName = originNames.isNull() || originNames->empty() ? material->getOrigin() : originNames->front();
                                if (currentName == originName)
                                {
									_snprintf(message, 1024,
												("The material \"%s\" occuring in the file \"%s\" more than once, the application will exit."),
			                                    material->getName().c_str(), currentName.c_str());
                                }
                                else
                                {
									_snprintf(message, 1024,
											("Duplicate material \"%s\" in files \"%s\" and \"%s\", the application will exit."),
                                            material->getName().c_str(), currentName.c_str(), originName.c_str());
                                }
                            }

							TDThrow("Ogre::%s", message);
                        }
                    }
                }
            }
		}
		
		throw;
	}
}

VOID CRenderSystem::Tick(VOID)
{
	const INT nStep = 5;
	CHAR szParam[32];
	if(m_bDeathMode && m_nDeachModePercent < 100)
	{
		m_nDeachModePercent += nStep;

		_snprintf(szParam, 32, "%f", (100.0f-m_nDeachModePercent)/100.0f );
		m_pPostFilterManager->setPostFilterParameter("Fade", "ColourAmount", szParam);

		_snprintf(szParam, 32, "%f", (FLOAT)m_nDeachModePercent/100.0f );
		m_pPostFilterManager->setPostFilterParameter("Fade", "GrayAmount", szParam);
	}
	else if(!m_bDeathMode && m_nDeachModePercent>0)
	{
		m_nDeachModePercent-=nStep;

		_snprintf(szParam, 32, "%f", (100.0f-m_nDeachModePercent)/100.0f );
		m_pPostFilterManager->setPostFilterParameter("Fade", "ColourAmount", szParam);

		_snprintf(szParam, 32, "%f", (FLOAT)m_nDeachModePercent/100.0f );
		m_pPostFilterManager->setPostFilterParameter("Fade", "GrayAmount", szParam);

		if(m_nDeachModePercent <= 0)
		{
			m_pPostFilterManager->setPostFilterEnabled("Fade", false);
		}
	}
}

VOID CRenderSystem::Camera_SetCurrent(CAMERA_TYPE theType)
{
	switch(theType)
	{
	case CHAR_VIEW:
		m_pCamera_Current = m_pCamera_CharView;
		break;

	case SCENE:
		m_pCamera_Current = m_pCamera_Scene;
		break;
	}

	m_pCamera_Current->Update();
}

/// 渲染Loading场景
VOID CRenderSystem::RenderLodingFrame(LPCTSTR szLoding)
{
	RenderFrame();
}

/// 渲染OGRE场景
VOID CRenderSystem::RenderFrame(VOID)
{
	if(!Ogre::Root::getSingletonPtr())
	{
		TDThrow("Ogre::Root = 0");
	}

	const UINT MAX_RENDER_INTER_TIME = 2000;

	static UINT s_nLastRenderTime = 0;
	UINT s_nTimeNow = g_pTimeSystem->GetTimeNow();

	if(g_pTimeSystem->CalSubTime(s_nLastRenderTime, s_nTimeNow) > MAX_RENDER_INTER_TIME)
	{
		Ogre::Root::getSingleton().clearEventTimes();
		s_nLastRenderTime = s_nTimeNow;
		return;
	}
	s_nLastRenderTime = s_nTimeNow;

	Camera_Tick();	// CYS: noi suy + va cham camera canh truoc khi ve
	
	Ogre::Root::getSingleton().renderOneFrame();
}

/// 响应WM_PAINT消息
VOID CRenderSystem::OnPaint(VOID)
{
	RenderFrame();
}

/// 窗口大小发生改变
VOID CRenderSystem::OnSizeChange(UINT message, WPARAM wParam, LPARAM lParam)
{
	//用户点击最大化或者最小化
	if(WM_SIZE == message)
	{
		m_pRenderSystem->resizeWindow(LOWORD(lParam), HIWORD(lParam));
	}
	//用户拖动窗口边缘结束
	else if(WM_EXITSIZEMOVE == message)
	{
		RECT rect;
		GetClientRect(g_hMainWnd, &rect);

		m_pRenderSystem->resizeWindow(rect.right-rect.left, rect.bottom-rect.top);
	}
}

VOID CRenderSystem::Camera_SetLookAt(const fVector3& fvPos)
{
	TDAssert(m_pCamera_Current);

	((CCamera_Scene*)m_pCamera_Current)->SetLookAt(fvPos);
}

/// 缩放相机视口 [0.0f, 1.0f]  0-最近距离 1-最远距离
VOID CRenderSystem::Camera_SetZoom(FLOAT fZoom)
{
	if(fZoom < 0.0f || fZoom > 1.0f) return;
	FLOAT fDistance = CCamera_Scene::MIN_DISTANCE + (CCamera_Scene::MAX_DISTANCE-CCamera_Scene::MIN_DISTANCE)*fZoom;
	m_pCamera_Current->SetDistance(fDistance);
}

VOID CRenderSystem::Camera_SetZoom(BOOL bUp,INT multiple)
{
	const FLOAT ZOOMSPEED = 0.05f;

	FLOAT fZoom = (m_pCamera_Current->GetDistance()-CCamera_Scene::MIN_DISTANCE)/(CCamera_Scene::MAX_DISTANCE-CCamera_Scene::MIN_DISTANCE);
	if (bUp)
	{
		fZoom-=(ZOOMSPEED*multiple);		
		if (fZoom<0.0f) fZoom=0.0f;
	}
	else
	{		
		fZoom+=(ZOOMSPEED*multiple);
		if (fZoom>1.0f) fZoom=1.0f;
	}
	Camera_SetZoom(fZoom);
}

VOID CRenderSystem::Camera_Direction(FLOAT fDir)
{
	m_pCamera_Current->SetDirection(fDir);		
}

VOID CRenderSystem::Camera_AddDirection(FLOAT fMultiple)
{
	FLOAT fDir = m_pCamera_Current->GetDirection() + fMultiple;
	Camera_Direction(fDir);
}

VOID CRenderSystem::Camera_GetWindowToViewportRay(INT nX, INT nY, fRay& fRay)
{
	Ogre::Ray ray = m_pRenderSystem->getWindowToViewportRay(nX, nY);

	fVector3 fGFX = fVector3(ray.getOrigin().x, ray.getOrigin().y, ray.getOrigin().z);
	Axis_Trans(AX_GFX, fGFX, AX_GAME, fRay.mOrigin);

	fRay.mDirection = fVector3(ray.getDirection().x, ray.getDirection().y, ray.getDirection().z);
}

//=====================================================================================
// CYS: camera 3D tu do theo CY 3.71 (Docs/specs/render/camera3d_vi.md). Pitch nguoi choi = CCamera_Scene::STATIC_PITCH
// (quy uoc 0.85: radian, am = nhin xuong). Gioi han pitch/khoang cach/FOV lay tu System.cfg nhu Game.exe C khi vao
// canh (FUN_1406be820: View_DefaultCamera != 0 va canh Type 0), nguoc lai la dong 1 cua SpecialSceneCamera.txt.
namespace
{
	FLOAT _CysCamFloat(LPCTSTR szName, FLOAT fDefault)
	{
		BOOL bHave = FALSE;
		FLOAT f = g_pVaribleSys->GetAs_Float(szName, &bHave);
		return bHave ? f : fDefault;
	}
	INT _CysCamInt(LPCTSTR szName, INT nDefault)
	{
		BOOL bHave = FALSE;
		INT n = g_pVaribleSys->GetAs_Int(szName, &bHave);
		return bHave ? n : nDefault;
	}
	const FLOAT kCysDeg = TDU_PI/180.0f;
	// Gioi han pitch (quy uoc 0.85): C DAT_140fae440 (tren) / DAT_140fae444 (duoi)
	FLOAT s_fCysPitchUpper = 40.0f*kCysDeg;		// -Camera_Pitch_Min
	FLOAT s_fCysPitchLower = -60.0f*kCysDeg;	// -Camera_Pitch_Max
	BOOL  s_bCysSkyCamera = FALSE;				// B View_UseSkyCamera; C: pitch co dinh Camera_Pitch (CYS-SCFIX)
	BOOL  s_bCysSmooth = TRUE;					// Camera_Smooth
	FLOAT s_fCysZoomStep = 0.1f;				// SpecialSceneCamera cot 5 (C DAT_140fae44c)
	FLOAT s_fCysSmoothStep = 0.01f;				// SpecialSceneCamera cot 6 (C DAT_140fae450)
	FLOAT s_fCysZoomTarget = -1.0f;				// C DAT_140fae454; < 0: khong noi suy
	BOOL  s_bCysZoomApplied = FALSE;
}

VOID CRenderSystem::Camera_ApplyVariables(VOID)
{
	if(!g_pVaribleSys) return;
	// SpecialSceneCamera.txt dong 1 (DataCY): Type 0, FOV 55, dist 2..25, ZoomStep 0.1, SmoothStep 0.01, pitch -40..60
	FLOAT fMinDist = 2.0f, fMaxDist = 25.0f, fPitchMin = -40.0f, fPitchMax = 60.0f;
	s_fCysZoomStep = 0.1f;
	s_fCysSmoothStep = 0.01f;
	CCamera_Scene::COLLIDE_BY_DISTANCE = FALSE;
	if(_CysCamInt("View_DefaultCamera", 1) != 0)
	{
		const FLOAT fCfgPitchMin = _CysCamFloat("Camera_Pitch_Min", -40.0f);
		const FLOAT fCfgPitchMax = _CysCamFloat("Camera_Pitch_Max", 60.0f);
		if(-90.0f <= fCfgPitchMin && fCfgPitchMin <= 90.0f && -90.0f <= fCfgPitchMax && fCfgPitchMax <= 90.0f &&
			fCfgPitchMin <= fCfgPitchMax)
		{
			fPitchMin = fCfgPitchMin;
			fPitchMax = fCfgPitchMax;
		}
		// C FUN_140647430: <= 0 -> 6 / 27.5; max >= min + 0.1
		fMinDist = _CysCamFloat("Camera_MinDistance", 6.0f);
		fMaxDist = _CysCamFloat("Camera_MaxDistance", 27.5f);
		if(fMinDist <= 0.0f) fMinDist = 6.0f;
		if(fMaxDist <= 0.0f) fMaxDist = 27.5f;
		if(fMaxDist < fMinDist + 0.1f) fMaxDist = fMinDist + 0.1f;
	}
	CCamera_Scene::MIN_DISTANCE = fMinDist;
	CCamera_Scene::MAX_DISTANCE = fMaxDist;
	s_fCysPitchUpper = -fPitchMin*kCysDeg;
	s_fCysPitchLower = -fPitchMax*kCysDeg;
	s_bCysSmooth = _CysCamInt("Camera_Smooth", 1) != 0;
	// CYS-SCFIX: CY 3.71 do tu bo nho (Build/Logs/2026-09-15-scene-change-fix/oracle-1-luoyang cam-a0/a1/a3,
	// cy-oracle run-18..21): voi System.cfg cua CY, keo chuot phai doc 160 px va lan chuot 4 nac KHONG doi pitch,
	// pitch luon = Camera_Pitch (40 do nhin xuong); keo ngang doi yaw. C khong co khoa View_UseSkyCamera: mac dinh 0
	// = goc CY co dinh Camera_Pitch. Gia tri 1 (khoa cua B) chi con cho driver chup anh 3D.
	// CO Y KHAC CY (17/09/2026): ban choi (stage_game.py) nay ghi View_UseSkyCamera=1 = CAMERA TU DO theo
	// yeu cau nguoi dung; CY that su khoa pitch 40 do. Mac dinh cua ENGINE van la 0 (dung CY) de cac bo
	// do doi chung (cy-oracle, d3d9-trace, viewer) khong bi doi camera khi khong co cfg cua ban choi.
	// Muon quay ve dung CY khi choi: doi mot khoa View_UseSkyCamera ve 0 trong stage_game.py.
	s_bCysSkyCamera = _CysCamInt("View_UseSkyCamera", 0) != 0;
	if(!s_bCysSkyCamera)
	{
		const FLOAT fCfgPitch = _CysCamFloat("Camera_Pitch", 40.0f);
		s_fCysPitchUpper = -fCfgPitch*kCysDeg;
		s_fCysPitchLower = -fCfgPitch*kCysDeg;
	}
	if(CCamera_Scene::STATIC_PITCH > s_fCysPitchUpper) CCamera_Scene::STATIC_PITCH = s_fCysPitchUpper;
	if(CCamera_Scene::STATIC_PITCH < s_fCysPitchLower) CCamera_Scene::STATIC_PITCH = s_fCysPitchLower;
	if(m_pCamera_Scene)
	{
		if(!s_bCysZoomApplied)
		{
			// Camera_Zoom (CY System.cfg 1.0): vi tri zoom chuan hoa luc bat dau
			const FLOAT fZoom = _CysCamFloat("Camera_Zoom", 1.0f);
			if(fZoom >= 0.0f && fZoom <= 1.0f)
				m_pCamera_Scene->SetDistance(fMinDist + (fMaxDist - fMinDist)*fZoom);
			s_bCysZoomApplied = TRUE;
		}
		else
		{
			FLOAT fDist = m_pCamera_Scene->GetDistance();
			if(fDist < fMinDist) fDist = fMinDist;
			if(fDist > fMaxDist) fDist = fMaxDist;
			m_pCamera_Scene->SetDistance(fDist);
		}
		m_pCamera_Scene->Update();
	}
}

VOID CRenderSystem::Camera_SetPitch(FLOAT fPitch)
{
	// C FUN_18002b420: chi nhan |p| < 89 do, ghi STATIC_PITCH roi Update
	if(!(fPitch < 1.553343f && fPitch > -1.553343f)) return;
	CCamera_Scene::STATIC_PITCH = fPitch;
	if(m_pCamera_Scene) m_pCamera_Scene->Update();
}

// CYS-FXBASE (fx-cy-baseline 19/09): do cao diem nhin tren vi tri nhan vat, tinh bang met (CCamera_Scene add height).
// CY 3.71 quay quanh mot diem cao hon dong bang camera cua engine nay 0,8 m (cy-oracle camread: target y 1350 so voi
// 1270 tai cung cho, cung pitch/yaw/khoang cach); replay ngoai tuyen dat gia tri nay qua CYS_SFX_CAM_ADDH de hai camera
// trung nhau. Khong ai goi ham nay trong duong choi thuong.
VOID CRenderSystem::Camera_SetAddHeight(FLOAT fAddHeight)
{
	if(!(fAddHeight >= 0.0f && fAddHeight < 10.0f)) return;
	if(m_pCamera_Scene) ((CCamera_Scene*)m_pCamera_Scene)->SetAddHeight(fAddHeight);
}

VOID CRenderSystem::Camera_AddPitch(FLOAT fDelta)
{
	if(!s_bCysSkyCamera) return;
	// C ProcessInput FUN_14064bd70: p = GetPitch() - dy/300, kep trong [DAT_140fae444, DAT_140fae440]
	FLOAT p = CCamera_Scene::STATIC_PITCH + fDelta;
	if(p > s_fCysPitchUpper) p = s_fCysPitchUpper;
	if(p < s_fCysPitchLower) p = s_fCysPitchLower;
	Camera_SetPitch(p);
}

FLOAT CRenderSystem::Camera_GetPitch(VOID) const
{
	return CCamera_Scene::STATIC_PITCH;	// C FUN_18002b1c0
}

VOID CRenderSystem::Camera_SetFreeMode(BOOL bFree)
{
	// B View_UseSkyCamera. C khong co khoa nay va pitch co dinh Camera_Pitch (CYS-SCFIX); TRUE chi dung cho driver chup 3D
	if(g_pVaribleSys) g_pVaribleSys->SetAs_Int("View_UseSkyCamera", bFree ? 1 : 0, TRUE);
	if(!bFree)
		CCamera_Scene::STATIC_PITCH = -_CysCamFloat("Camera_Pitch", 40.0f)*kCysDeg;
	Camera_ApplyVariables();
}

BOOL CRenderSystem::Camera_IsFreeMode(VOID) const
{
	return s_bCysSkyCamera;
}

VOID CRenderSystem::Camera_ZoomStep(BOOL bUp)
{
	if(!m_pCamera_Current) return;
	if(!s_bCysSmooth)
	{
		Camera_SetZoom(bUp, 2);	// C: Camera_SetZoom(up, 2) = +-0.1 ngay lap tuc
		return;
	}
	// C: muc tieu DAT_140fae454 -+= ZoomStep, kep [0,1]; Camera_Tick di toi muc tieu SmoothStep moi khung
	FLOAT t = s_fCysZoomTarget >= 0.0f ? s_fCysZoomTarget : Camera_GetZoom();
	t += bUp ? -s_fCysZoomStep : s_fCysZoomStep;
	if(t < 0.0f) t = 0.0f;
	if(t > 1.0f) t = 1.0f;
	s_fCysZoomTarget = t;
}

VOID CRenderSystem::Camera_SetZoomTarget(FLOAT fZoom)
{
	if(fZoom < 0.0f || fZoom > 1.0f) return;
	if(s_bCysSmooth) s_fCysZoomTarget = fZoom;
	else Camera_SetZoom(fZoom);
}

VOID CRenderSystem::Camera_Tick(VOID)
{
	// C GamePro_Main tick FUN_14064a0a0: |zoom - target| > SmoothStep -> zoom += +-SmoothStep, nguoc lai gan dung target
	if(!m_pCamera_Current || m_pCamera_Current != m_pCamera_Scene || s_fCysZoomTarget < 0.0f) return;
	FLOAT z = Camera_GetZoom();
	if(::fabs(z - s_fCysZoomTarget) > s_fCysSmoothStep)
		z += (s_fCysZoomTarget > z) ? s_fCysSmoothStep : -s_fCysSmoothStep;
	else
	{
		z = s_fCysZoomTarget;
		s_fCysZoomTarget = -1.0f;
	}
	if(z < 0.0f) z = 0.0f;
	if(z > 1.0f) z = 1.0f;
	Camera_SetZoom(z);
}

VOID CRenderSystem::Camera_SetClip(FLOAT fFar, FLOAT fNear)
{
	if(fFar > 0.0f) CCamera_Scene::FAR_CLIP = fFar;
	if(fNear > 0.0f && (fFar <= 0.0f || fNear < fFar)) CCamera_Scene::NEAR_CLIP = fNear;
	Ogre::LogManager::getSingleton().logMessage("[CYS] camera3d: scene camera clip far=" +
		Ogre::StringConverter::toString(CCamera_Scene::FAR_CLIP) + " near=" + Ogre::StringConverter::toString(CCamera_Scene::NEAR_CLIP));
	if(m_pCamera_Scene) m_pCamera_Scene->Update();
}

INT CRenderSystem::Camera_CountOccluders(FLOAT fDirection, FLOAT fPitch, FLOAT fDistance)
{
	if(!m_pCamera_Scene || !m_pRaySceneQuery) return -1;
	CCamera_Scene* p = (CCamera_Scene*)m_pCamera_Scene;
	const fVector3& look = p->GetLookAtGfx();
	const FLOAT d = fDistance*GetSacle().y;
	const Ogre::Vector3 origin(look.x, look.y, look.z);
	const Ogre::Vector3 dir(-::sin(fDirection)*::cos(-fPitch), ::sin(-fPitch), -::cos(fDirection)*::cos(-fPitch));
	m_pRaySceneQuery->setRay(Ogre::Ray(origin, dir));
	INT nHits = 0;
	const Ogre::RaySceneQueryResult& result = m_pRaySceneQuery->execute();
	for(Ogre::RaySceneQueryResult::const_iterator it = result.begin(); it != result.end(); ++it)
	{
		if(!it->movable || it->distance > d || it->distance < 50.0f) continue;
		if(it->movable->getMovableType() != "Entity") continue;
		WX::ObjectPtr object = WX::getObjectFromMovable(it->movable);
		if(object && object->getData()) continue;	// nhan vat / vat the logic game
		++nHits;
	}
	return nHits;
}

STRING CRenderSystem::Camera_Describe(VOID) const
{
	if(!m_pCamera_Scene) return STRING("camera=none");
	CCamera_Scene* p = (CCamera_Scene*)m_pCamera_Scene;
	Ogre::Camera* pOgre = p->GetOgreCamera();
	CHAR sz[640];
	_snprintf(sz, sizeof(sz)-1,
		"mode=%s pitch_deg=%.1f user_pitch_deg=%.1f dir_deg=%.1f dist_m=%.2f zoom=%.2f zoom_target=%.2f collide=%s "
		"eye=(%.0f,%.0f,%.0f) look=(%.0f,%.0f,%.0f) near=%.1f far=%.0f fov=%.1f pitch_range_deg=[%.1f,%.1f] dist_range_m=[%.1f,%.1f] smooth=%d",
		s_bCysSkyCamera ? "free3d" : "classic",
		-p->CCamera::GetPitch()*180.0f/TDU_PI, -CCamera_Scene::STATIC_PITCH*180.0f/TDU_PI, p->GetDirection()*180.0f/TDU_PI,
		p->GetDistance(), ((CRenderSystem*)this)->Camera_GetZoom(), s_fCysZoomTarget,
		CCamera_Scene::COLLIDE_BY_DISTANCE ? "distance" : "pitch",
		p->GetEyePos().x, p->GetEyePos().y, p->GetEyePos().z, p->GetLookAtGfx().x, p->GetLookAtGfx().y, p->GetLookAtGfx().z,
		pOgre ? pOgre->getNearClipDistance() : 0.0f, pOgre ? pOgre->getFarClipDistance() : 0.0f,
		pOgre ? pOgre->getFOVy().valueDegrees() : 0.0f,
		-s_fCysPitchUpper*180.0f/TDU_PI, -s_fCysPitchLower*180.0f/TDU_PI,
		CCamera_Scene::MIN_DISTANCE, CCamera_Scene::MAX_DISTANCE, s_bCysSmooth ? 1 : 0);
	sz[sizeof(sz)-1] = 0;
	return STRING(sz);
}

// 震荡一次
VOID CRenderSystem::Camera_VibrateOneTime()
{
	TDAssert(m_pCamera_Current);

	((CCamera_Scene*)m_pCamera_Current)->AddOneVib(10, 8, 2);
}


// 设置眼睛的位置, ogre 坐标
VOID	CRenderSystem::Camera_SetEyePos(const fVector3& fvPos)
{
	
	if(m_pRenderSystem)
	{
		Ogre::Camera* pOgreCamera = m_pRenderSystem->getCamera();

		pOgreCamera->setPosition(Ogre::Vector3(fvPos.x, fvPos.y, fvPos.z));
		
	}
}

// 设置观察点的位置 ogre 坐标.
VOID	CRenderSystem::Camera_SetLookAtPos(const fVector3& fvPos)
{
	if(m_pRenderSystem)
	{
		Ogre::Camera* pOgreCamera = m_pRenderSystem->getCamera();
		pOgreCamera->lookAt(Ogre::Vector3(fvPos.x, fvPos.y, fvPos.z));
	}
}

VOID CRenderSystem::Scene_PreLoad(const STRING& theScenePreload)
{
	char* lpAddress = NULL;
	DWORD dwSize = g_pResourceProvider->loadResource(theScenePreload.c_str(), lpAddress, "General");
	if(dwSize > 0)
	{
		register const char* pMemory = lpAddress;
		const char* pDeadEnd = lpAddress + dwSize + 1;

		char szLine[1024] = {0};
		do
		{
			//读取一行
			pMemory = TDU_GetLineFromMemory(szLine, 1024, pMemory, pDeadEnd);
			if(!pMemory) break;

			WX::LogicModelManager::getSingleton().loadModelResource(szLine);
		}while(true);
		g_pResourceProvider->unloadResource(lpAddress, dwSize);
	}
}

VOID CRenderSystem::Scene_Load(INT nID, const STRING& theSceneDefine)
{
	WX::ExpatParser parserExpat(NULL);
	
	if(m_pTerrainGrid)
	{
		m_pTerrainGrid->destroyRenderable();
	}

	//卸载现有资源
	m_pRenderSystem->resetScene();

	//加载场景文件
	m_pRenderSystem->loadSceneFromResource(&parserExpat, theSceneDefine.c_str(), "General");
	// CYS: B holds NewHDRBloom off on the login / character screens (scene id < 0) and restores it in the world
	// CYS-LUT: + the scene file: CY picks the ColorLUT of the scene here (Game.exe Scene_SetSceneLUTParam)
	WX::CysPostFx::onSceneLoaded(m_pPostFilterManager, m_pRenderSystem->getViewport(), nID, theSceneDefine);
	// CYS-LOOK: CY turns the shadows off on the character screen and on (back-off 18000) at the login scene
	WX::CYSShadowHost::onSceneLoaded(theSceneDefine);

	//释放未使用资源
	{
		Ogre::ResourceGroupManager& resManager = Ogre::ResourceGroupManager::getSingleton();

		const Ogre::StringVector& strGroupVec = resManager.getResourceGroups();

		for(int i=0; i<(int)strGroupVec.size(); i++)
		{
			if( strGroupVec[i] != Ogre::ResourceGroupManager::INTERNAL_RESOURCE_GROUP_NAME &&
				strGroupVec[i] != Ogre::ResourceGroupManager::BOOTSTRAP_RESOURCE_GROUP_NAME)
			{
				resManager.unloadUnreferencedResourcesInGroup(strGroupVec[i]);
			}
		}
	}
	
	//设置LightMap
	// CYS-PARITY (L5b): CY 3.71 has no View_LightmapQuality (string absent from Game.exe / Render.dll); its Terrain
	// constructor sets quality 2 and nothing changes it, so the tile lightmaps are 8 texels per grid (trace: 256x256 L8
	// per 32-grid tile at the login). CYS_PARITY_TERRAIN_TILEMAPS=0 keeps B's LMQ_LOW on scene load.
	m_pRenderSystem->getTerrain()->setLightmapQuality(WX::Terrain::_cysTileMaps() ? WX::Terrain::LMQ_HIGH : WX::Terrain::LMQ_LOW);
	m_pRenderSystem->getTerrain()->buildGeometry(m_pRenderSystem->getBaseSceneNode());
	m_pRenderSystem->getTerrain()->cysPrewarm(); // CYS-PERF-FIX prewarm: terrain geometry + material variants in the load

	//取得环境特效
	WX::SceneInfo::ObjectsByTypeRange objEnviroment = 
		m_pRenderSystem->getSceneInfo()->findObjectsByType("Enviroment");

	if (objEnviroment.first != objEnviroment.second)
	{
		m_pEnviromentObject = static_cast< WX::EnviromentObject * >(objEnviroment.first->get());
		TDAssert(m_pEnviromentObject);
	}
	else
	{
		m_pEnviromentObject = NULL;
	}
}

VOID CRenderSystem::Scene_SetEnviromentInfo(const fVector3& fvPos)
{
	if(m_pEnviromentObject)
	{
		//坐标转换
		fVector3 fvPosGfx;
		if(!Axis_Trans(AX_GAME, fvPos, AX_GFX, fvPosGfx)) return;

		//设置新的位置
		m_pEnviromentObject->setWeatherParticleSystemPosition(Ogre::Vector3(fvPosGfx.x, fvPosGfx.y+300, fvPosGfx.z));
	}
}

//VOID CRenderSystem::Debug_Scene_SetFloodlighting(FLOAT fBlur, FLOAT fShine)
//{
//	Scene_SetPostFilter("Floodlighting");
//
//	CHAR szTemp[32];
//	
//	_snprintf(szTemp, 32, "%.2f", fBlur);
//	m_pPostFilterManager->setPostFilterParameter("BlurAmount", szTemp);
//
//	_snprintf(szTemp, 32, "%.2f", fShine);
//	m_pPostFilterManager->setPostFilterParameter("ShineAmount", szTemp);
//}

//设置地形阴影
VOID CRenderSystem::Scene_SetLightmapQuality(INT nQuality)
{
	switch(nQuality)
	{
	case 0:
		m_pRenderSystem->getTerrain()->setLightmapQuality(WX::Terrain::LMQ_NONE);
		m_pRenderSystem->getTerrain()->buildGeometry(m_pRenderSystem->getBaseSceneNode());
		m_pRenderSystem->getTerrain()->cysPrewarm(); // CYS-PERF-FIX prewarm
		break;

	case 1:
		m_pRenderSystem->getTerrain()->setLightmapQuality(WX::Terrain::LMQ_LOW);
		m_pRenderSystem->getTerrain()->buildGeometry(m_pRenderSystem->getBaseSceneNode());
		m_pRenderSystem->getTerrain()->cysPrewarm(); // CYS-PERF-FIX prewarm
		break;

	case 2:
		m_pRenderSystem->getTerrain()->setLightmapQuality(WX::Terrain::LMQ_HIGH);
		m_pRenderSystem->getTerrain()->buildGeometry(m_pRenderSystem->getBaseSceneNode());
		m_pRenderSystem->getTerrain()->cysPrewarm(); // CYS-PERF-FIX prewarm
		break;
	
	default:
		m_pRenderSystem->getTerrain()->setLightmapQuality(WX::Terrain::LMQ_HIGH);
		m_pRenderSystem->getTerrain()->buildGeometry(m_pRenderSystem->getBaseSceneNode());
		m_pRenderSystem->getTerrain()->cysPrewarm(); // CYS-PERF-FIX prewarm
		break;
	}
}

VOID CRenderSystem::Scene_ShowGridSwitch(INT nZoneSize)
{
	if(m_pTerrainGrid == NULL)
	{
		m_pTerrainGrid = new WX::TerrainGrid(m_pRenderSystem->getSceneManager(), nZoneSize);
	}

	//显示网格
	m_pTerrainGrid->setActive(!(m_pTerrainGrid->isActive()));
}

//显示设置全局渲染效果
VOID CRenderSystem::Scene_SetPostFilter(LPCTSTR szFilterName)
{
	//设置全局渲染特效
	m_pPostFilterManager->setPostFilterEnabled(szFilterName, true);

	//取得环境变量
	g_pVaribleSys->SetVariable("Gfx_PostFilter", szFilterName);
}

//进入/退出死亡全局渲染效果
VOID CRenderSystem::Scene_SetPostFilter_Death(BOOL bEnter)
{
	if(bEnter == m_bDeathMode) return;

	if(bEnter)
	{
		m_pPostFilterManager->setPostFilterEnabled("Fade", true);
		m_nDeachModePercent = 0;

		m_pPostFilterManager->setPostFilterParameter("Fade", "ColourAmount", "1.0");
		m_pPostFilterManager->setPostFilterParameter("Fade", "GrayAmount", "0.0");
	}
	else
	{
		m_nDeachModePercent = 100;
	}

	m_bDeathMode = bEnter;
}

tEntityNode* CRenderSystem::New_EntityObject(tEntityNode::EntityType type)
{
	switch(type)
	{
	case tEntityNode::ETYPE_DUMMY:
		return new CRFObj_Dummy;

	case tEntityNode::ETYPE_MESH:
		return new CRFObj_Static;

	case tEntityNode::ETYPE_MODEL:
		return new CRFObj_Model;

	case tEntityNode::ETYPE_ACTOR:
		return new CRFObj_Actor;

	default:
		return NULL;
	}
}

VOID CRenderSystem::Destroy_EntityObject(tEntityNode* pNode)
{
	TDAssert(pNode);

	delete ((CWXObject*)pNode);

	//之后不能调用和该node相关的任何代码
	return;
}

tEntityNode* CRenderSystem::Find_HitWXObject(INT nX, INT nY)
{
	Ogre::Ray ray = m_pRenderSystem->getWindowToViewportRay(WX::Point(nX, nY));
	m_pRaySceneQuery->setRay(ray);

	//按照逻辑优先级的查询队列
	std::map< INT, tEntityNode* > mapRayQuery;

	const Ogre::RaySceneQueryResult& queryResult = m_pRaySceneQuery->execute();
	for (Ogre::RaySceneQueryResult::const_iterator it = queryResult.begin(); it != queryResult.end(); ++it)
	{
		Ogre::MovableObject* pMovable = it->movable;
		WX::ObjectPtr object = WX::getObjectFromMovable(pMovable);
		if (object&&object->getData())
		{
			tEntityNode* pEntityNode = (tEntityNode*)(object->getData());
			//不是游戏逻辑中动态生成的
			if(!pEntityNode) continue;
			//不再被关心
			if(!(pEntityNode->GetRayQuery())) continue;

			if(pEntityNode->GetType() == tEntityNode::ETYPE_ACTOR) // object->getType() == "LogicModel")
            {
                WX::LogicModelObject* logicModelObject = static_cast<WX::LogicModelObject*>(object.get());

                assert (logicModelObject);

                WX::LogicModel* model = logicModelObject->getLogicModel();

                assert (model);

				//不再自定义BoundingBox中
				if (model->isUseExternalBoundingBox() && !(model->rayIntersect(ray)))
                {        
                    continue;
                }
            }

			//如果已经有同级存在，按照摄像机远近排序
			if(mapRayQuery.find(pEntityNode->RayQuery_GetLevel()) != mapRayQuery.end()) continue;

			//放入查询队列
			mapRayQuery.insert(std::make_pair(pEntityNode->RayQuery_GetLevel(), pEntityNode));
		}
	}

	//返回优先级最高的逻辑对象
	if(!mapRayQuery.empty()) 
	{
		return mapRayQuery.begin()->second;
	}

	return NULL;
}

VOID CRenderSystem::PushDebugString(LPCTSTR szMsg, ...)
{
}

VOID CRenderSystem::SetDebugString(LPCTSTR szName, LPCTSTR szValue)
{
	if(!m_pDebugPanel) return;
	m_pDebugPanel->SetDebugString(szName, szValue);
}

inline FLOAT CRenderSystem::Camera_GetDirection(VOID) const 
{
	return m_pCamera_Current->GetDirection();
}

inline FLOAT CRenderSystem::Camera_GetZoom(VOID) const 
{
	// CYS: C FUN_18002b270 tra ve zoom chuan hoa [0,1] (0.85 tra ve khoang cach nen Camera_SetZoom(fTransDistance) vo hieu)
	if(CCamera_Scene::MAX_DISTANCE <= CCamera_Scene::MIN_DISTANCE) return 1.0f;
	return (m_pCamera_Current->GetDistance() - CCamera_Scene::MIN_DISTANCE)/(CCamera_Scene::MAX_DISTANCE - CCamera_Scene::MIN_DISTANCE);
}

VOID CRenderSystem::SetHitObjText(LPCTSTR szHitObjText)
{
	if (!m_pDebugPanel) return; // CYS: debug overlays are optional.
	m_pDebugPanel->SetHitObjString(szHitObjText);
}

VOID CRenderSystem::Debug_AddParticle(LPCTSTR szParticleName, const fVector3& fvPos)
{
	//static int name = 0;
	//char szTemp[MAX_PATH];
	//_snprintf(szTemp, MAX_PATH, "__test_%d", name++);

	//Ogre::ParticleSystem *system = m_pRenderSystem->getSceneManager()->createParticleSystem(szTemp,	szParticleName);
	//assert (system);
	//Ogre::SceneNode *node = m_pRenderSystem->getBaseSceneNode()->createChildSceneNode();

	//node->attachObject(system);

	//fVector3 fvGfx;
	//Axis_Trans(AX_GAME, fvPos, AX_GFX, fvGfx);

	//node->setPosition(Ogre::Vector3(fvGfx.x, fvGfx.y, fvGfx.z));//
}


//创建一个Fake渲染对象
VOID CRenderSystem::FakeObj_Create(LPCTSTR szObjectName, tEntityNode* pNode, LPCTSTR szCameraName)
{
	m_pFakeObjectManager->CreateObject(szObjectName, pNode, szCameraName);
}

// Additive POD bridge: preserve the legacy plugin virtual interface.
extern "C" __declspec(dllexport) void __cdecl CysFakeObjCreateWithBackground(
	void* renderer, const char* objectName, void* entity, const char* cameraName,
	unsigned int width, unsigned int height, const char* backgroundName)
{
	if (!renderer || renderer != CRenderSystem::GetMe() || !CFakeObjectManager::GetMe())
		OGRE_EXCEPT(Ogre::Exception::ERR_INVALIDPARAMS, "Inactive UI RTT renderer",
			"CysFakeObjCreateWithBackground");
	CFakeObjectManager::GetMe()->CreateObject(objectName, static_cast<tEntityNode*>(entity),
		cameraName, width, height, backgroundName);
}

static_assert(std::is_same<decltype(&CysFakeObjCreateWithBackground), CysUiMeshBridge::Create>::value,
	"UI RTT bridge signature must match the Game caller");

// CYS-MESHWIN 19/09: camera of a UI model, keyed by object name (Game.exe maps the CY window name to it).
// Same additive-export road as CysFakeObjCreateWithBackground; 1 = done, 0 = unknown object / no manager.
extern "C" __declspec(dllexport) int __cdecl CysFakeObjRttCameraGet(
	const char* objectName, float* height, float* distance, float* pitch, float* xOffset)
{
	if (!CFakeObjectManager::GetMe()) return 0;
	return CFakeObjectManager::GetMe()->GetCamera(objectName, height, distance, pitch, xOffset) ? 1 : 0;
}
extern "C" __declspec(dllexport) int __cdecl CysFakeObjRttCameraSet(
	const char* objectName, float height, float distance, float pitch, float xOffset)
{
	if (!CFakeObjectManager::GetMe()) return 0;
	return CFakeObjectManager::GetMe()->SetCamera(objectName, height, distance, pitch, xOffset) ? 1 : 0;
}
extern "C" __declspec(dllexport) int __cdecl CysFakeObjRttCameraReset(const char* objectName)
{
	if (!CFakeObjectManager::GetMe()) return 0;
	return CFakeObjectManager::GetMe()->ResetCamera(objectName) ? 1 : 0;
}
static_assert(std::is_same<decltype(&CysFakeObjRttCameraGet), CysUiMeshBridge::RttCameraGet>::value, "CysFakeObjRttCameraGet signature");
static_assert(std::is_same<decltype(&CysFakeObjRttCameraSet), CysUiMeshBridge::RttCameraSet>::value, "CysFakeObjRttCameraSet signature");
static_assert(std::is_same<decltype(&CysFakeObjRttCameraReset), CysUiMeshBridge::RttCameraReset>::value, "CysFakeObjRttCameraReset signature");

//销毁一个Fake渲染对象
// CYS: additive scene-mode bridge for the original CY login/create presentation.
// Fake game objects still own their actors, but their meshes draw in the main
// scene. The UI controller must unhook an old RTT before selecting this mode.
extern "C" __declspec(dllexport) int __cdecl CysLoginActorSceneVisible(
    void* renderer, void* entity, int visible)
{
    if (!renderer || renderer != CRenderSystem::GetMe() || !entity ||
        (visible != 0 && visible != 1)) return 0;
    tEntityNode* node = static_cast<tEntityNode*>(entity);
    if (node->GetType() != tEntityNode::ETYPE_ACTOR) return 0;
    CRFObj_Actor* actor = static_cast<CRFObj_Actor*>(node);
    WX::LogicModel* model = actor->GetActorImpl();
    if (!model) return 0;
    model->setVisibleFlag(static_cast<unsigned int>(WX::OVF_DEFAULT));
    actor->SetVisible(visible ? TRUE : FALSE);
    return model->getVisibleFlag() == static_cast<unsigned int>(WX::OVF_DEFAULT) ? 1 : 0;
}

static_assert(std::is_same<decltype(&CysLoginActorSceneVisible),
    CysLoginSceneBridge::ActorVisible>::value, "Login scene bridge signature mismatch");

// CYS: LogicModelObject has no generic "scale" property; use its model API.
extern "C" __declspec(dllexport) int __cdecl CysLoginActorSceneScale(
    void* renderer, void* entity, float scale)
{
    if (!renderer || renderer != CRenderSystem::GetMe() || !entity ||
        !std::isfinite(scale) || scale <= 0 || scale > 10) return 0;
    tEntityNode* node = static_cast<tEntityNode*>(entity);
    if (node->GetType() != tEntityNode::ETYPE_ACTOR) return 0;
    WX::LogicModel* model = static_cast<CRFObj_Actor*>(node)->GetActorImpl();
    if (!model || !model->getSceneNode()) return 0;
    const Ogre::Vector3 wanted(scale, scale, scale);
    model->setScaleFactor(wanted);
    return model->getSceneNode()->getScale().positionEquals(wanted, 0.0001f) ? 1 : 0;
}
static_assert(std::is_same<decltype(&CysLoginActorSceneScale),
    CysLoginSceneBridge::ActorScale>::value, "Login actor scale bridge signature mismatch");

// CYS: exact CY camera quaternion/FOV without changing the plugin vtable.
extern "C" __declspec(dllexport) int __cdecl CysLoginSceneCamera(
    void* renderer, const float* eye, const float* orientation, float fov)
{
    if (!renderer || renderer != CRenderSystem::GetMe() || !eye || !orientation ||
        !std::isfinite(fov) || fov < 20 || fov > 100) return 0;
    for (int i = 0; i < 3; ++i) if (!std::isfinite(eye[i])) return 0;
    float norm = 0;
    for (int i = 0; i < 4; ++i)
    {
        if (!std::isfinite(orientation[i])) return 0;
        norm += orientation[i] * orientation[i];
    }
    if (norm < 0.99f || norm > 1.01f) return 0;
    WX::System* system = CRenderSystem::GetMe()->GetRenderSystem();
    Ogre::Camera* camera = system ? system->getCamera() : NULL;
    if (!camera) return 0;
    camera->setPosition(Ogre::Vector3(eye[0], eye[1], eye[2]));
    camera->setOrientation(Ogre::Quaternion(orientation[0], orientation[1], orientation[2], orientation[3]));
    camera->setFOVy(Ogre::Degree(fov));
    return fabs(camera->getFOVy().valueDegrees() - fov) < 0.001f ? 1 : 0;
}
static_assert(std::is_same<decltype(&CysLoginSceneCamera),
    CysLoginSceneBridge::CameraPose>::value, "Login camera bridge signature mismatch");

// CYS-CHARSEL: CY login camera CCamera_CharSel FUN_180002a30 ends with setFarClipDistance(40000); CCamera_CharSel::Update
// restores 100000 when the character screens select the view again.
extern "C" __declspec(dllexport) int __cdecl CysLoginSceneFarClip(void* renderer, float farClip)
{
    if (!renderer || renderer != CRenderSystem::GetMe() || !std::isfinite(farClip) || farClip < 1000 || farClip > 200000)
        return 0;
    WX::System* system = CRenderSystem::GetMe()->GetRenderSystem();
    Ogre::Camera* camera = system ? system->getCamera() : NULL;
    if (!camera) return 0;
    camera->setFarClipDistance(farClip);
    return fabs(camera->getFarClipDistance() - farClip) < 0.5f ? 1 : 0;
}
static_assert(std::is_same<decltype(&CysLoginSceneFarClip),
    CysLoginSceneBridge::CameraFarClip>::value, "Login far clip bridge signature mismatch");

// CYS-SKY: CY 3.71 Render.dll day clock (FUN_1800dde40: 60 s day, FUN_1800ddec0 advances it) keeps running until the game
// sets the time (FUN_18002e3d0, called when entering the world). Login / character procedures never set it.
extern "C" __declspec(dllexport) int __cdecl CysSceneSkyClock(void* renderer, int running)
{
    if (!renderer || renderer != CRenderSystem::GetMe())
        return 0;
    WX::CYSEnvironmentManager::getSingleton().setCyFreeClock(running != 0);
    return 1;
}
static_assert(std::is_same<decltype(&CysSceneSkyClock),
    CysLoginSceneBridge::SkyClock>::value, "Sky clock bridge signature mismatch");

// CYS-SKY: CY 3.71 CRenderSystem vtable +0x350 = FUN_18002e3d0 (Render.dll): without a SkySphere it stops the day clock
// and sets the day fraction; with one it sets the SkySphere time and lunar date. Game.exe FUN_14064d030 calls it from
// GCWorldTime and every View_SkyBoxRefreshTime ms.
extern "C" __declspec(dllexport) int __cdecl CysSceneSetTime(void* renderer, int dayOfMonth, float dayFraction)
{
    if (!renderer || renderer != CRenderSystem::GetMe() || !std::isfinite(dayFraction))
        return 0;
    WX::CYSEnvironmentManager::getSingleton().setWorldTime(dayOfMonth, dayFraction);
    return 1;
}
static_assert(std::is_same<decltype(&CysSceneSetTime),
    CysLoginSceneBridge::SkyTime>::value, "Sky time bridge signature mismatch");

VOID CRenderSystem::FakeObj_Destroy(LPCTSTR szObjName)
{
	m_pFakeObjectManager->DestroyObject(szObjName);
}

//隐藏/显示Fake渲染对象
VOID CRenderSystem::FakeObj_Show(LPCTSTR szObjName, BOOL bVisible, float fAspectRatio)
{
	m_pFakeObjectManager->SetVisible(szObjName, bVisible, fAspectRatio);
}

VOID CRenderSystem::Debug_SetFakeCamera(INT nType, FLOAT fValue)
{
	m_pFakeObjectManager->Debug_SetFakeCamera(nType, fValue);
}

VOID CRenderSystem::Debug_ToggleShowDebugPanel(VOID)
{
	if (m_pDebugPanel) m_pDebugPanel->ToggleShow(); // CYS: keep frame-stat toggle available without the debug panel.

	bool bShow = !(m_pRenderSystem->getFrameStatsListener()->isStatPanelShown());
	m_pRenderSystem->getFrameStatsListener()->showStatPanel(bShow);

}

VOID WINAPI CRenderSystem::_OnVariableChangedEvent(const EVENT* pEvent, UINT_PTR dwOwnerData)
{
	if(pEvent && pEvent->pEventDef && pEvent->pEventDef->idEvent == GE_VARIABLE_CHANGED)
	{
		const STRING& strVariable = pEvent->vArg[0];
		const STRING& strValue = pEvent->vArg[1];

		BOOL bEnable = (strValue=="1");

		// CYS: the CY-Source post filters follow their keys at run time exactly as at start-up
		if (GetMe() && GetMe()->m_pPostFilterManager && GetMe()->m_pRenderSystem)
			WX::CysPostFx::applyVariable(GetMe()->m_pPostFilterManager, GetMe()->m_pRenderSystem->getViewport(),
				strVariable, strValue);
		WX::CYSShadowHost::applyVariable(strVariable, strValue); // CYS-SHADOW: quality level / Gfx_Shadow* at run time

		// CYS: khoa camera 3D doi luc chay (thiet lap he thong)
		if(GetMe() && (strVariable.compare(0, 7, "Camera_") == 0 || strVariable == "View_UseSkyCamera" ||
			strVariable == "View_DefaultCamera" || strVariable == "View_VisibleRangeLevelNew"))
		{
			GetMe()->Camera_ApplyVariables();
		}

		if(strVariable == szAnimationQualityVar)
		{
			INT nValue = strValue[0] - '0';

			GetMe()->Scene_SetAnimationQuality( nValue*50 - 50 );
			//低的模型 -50
			//中		0
			//高		50
		}
		else if(strVariable == szLightmapQualityVar)
		{
			INT nValue = strValue[0] - '0';

			GetMe()->Scene_SetLightmapQuality(nValue);
		}

		else if(strVariable == szPostFilterEnabledVar)
		{
			if(bEnable)
				GetMe()->Scene_SetPostFilterEnabled(TRUE);
			else
				GetMe()->Scene_SetPostFilterEnabled(FALSE);			
		}

		else if(strVariable == sz32BitTexturesVar)
		{
			INT nValue = strValue[0] - '0';

			if(nValue == 0)
			{	//16
				GetMe()->Scene_Enable32BitTextures(FALSE);
			}
			else if(nValue == 1)
			{
				//32
				GetMe()->Scene_Enable32BitTextures(TRUE);
			}
			else
			{
				//桌面
				int nDesktopBits = ::GetDeviceCaps(::GetDC(::GetDesktopWindow()), BITSPIXEL);
				if(16 == nDesktopBits)
				{
//					g_pVaribleSys->SetAs_Int(sz32BitTexturesVar, 0, FALSE);
					GetMe()->Scene_Enable32BitTextures(FALSE);
				}
				else
				{
//					g_pVaribleSys->SetAs_Int(sz32BitTexturesVar, 1, FALSE);
					GetMe()->Scene_Enable32BitTextures(TRUE);
				}
			}
		}
		else if(strVariable == szDefaultTextureFilteringVar)
		{
			INT nValue = strValue[0] - '0';

			GetMe()->Scene_SetTextureFiltering(nValue);

		}
	}
}

//设置材质32位/16位转化
VOID CRenderSystem::Scene_Enable32BitTextures(BOOL bSetting)
{
	#if (_MSC_VER >= 1400)
	//	std::locale langLocale("");
	//	std::locale::global(langLocale);
		setlocale( LC_CTYPE, "" );
	#endif

	//Ogre::TextureManager::getSingleton().enable32BitTextures(bSetting==TRUE);
}

//设置采样
VOID CRenderSystem::Scene_SetTextureFiltering(INT nOptions)
{
	switch(nOptions)
	{
	case 0:	
		Ogre::MaterialManager::getSingleton().setDefaultTextureFiltering(Ogre::TFO_BILINEAR);
		Ogre::MaterialManager::getSingleton().setDefaultAnisotropy(1);
		break;
	case 1:
		Ogre::MaterialManager::getSingleton().setDefaultTextureFiltering(Ogre::TFO_TRILINEAR);
		Ogre::MaterialManager::getSingleton().setDefaultAnisotropy(2);
		break;
	case 2:
		Ogre::MaterialManager::getSingleton().setDefaultTextureFiltering(Ogre::TFO_ANISOTROPIC);
		Ogre::MaterialManager::getSingleton().setDefaultAnisotropy(8);
		break;
	default:
		break;
	}
}

//设置静态物体动画
VOID CRenderSystem::Scene_SetAnimationQuality(INT nOptions)
{
//	WX::System::setAnimationQuality( (bSetting == TRUE)?1:0);
	m_pRenderSystem->setAnimationQuality( nOptions );
}

//设置全屏泛光效果
VOID CRenderSystem::Scene_SetPostFilterEnabled(BOOL bSetting)
{
//	WX::PostFilterManager::setPostFilterEnabled("Floodlighting",(bSetting==TRUE));
	m_pRenderSystem->getPostFilterManager()->setPostFilterEnabled("Floodlighting",(bSetting==TRUE));
}

//设置人物实时阴影
VOID CRenderSystem::Scene_SetShadowTechnique(BOOL bSetting)
{
	//Ogre::SceneManager::setShadowTechnique
	if(bSetting == TRUE)
		m_pRenderSystem->getSceneManager()->setShadowTechnique(Ogre::SHADOWTYPE_NONE);
	else
		m_pRenderSystem->getSceneManager()->setShadowTechnique(Ogre::SHADOWTYPE_STENCIL_MODULATIVE);

}

//将当前屏幕截图到文件中
BOOL CRenderSystem::PrintScreen(LPTSTR szReturnBuf, INT nBufSize)
{
	const char* szScreenShortPath = "..\\ScreenShots";
	CHAR szFileName[MAX_PATH] = {0};
	try
	{
		//时间
		SYSTEMTIME timeNow;
		::GetLocalTime(&timeNow);

		_snprintf(szFileName, MAX_PATH, "%04d_%02d_%02d_%02d_%02d_%02d.jpg",
			timeNow.wYear, timeNow.wMonth, timeNow.wDay, 
			timeNow.wHour, timeNow.wMinute, timeNow.wSecond);

		//创建目录
		::CreateDirectory(szScreenShortPath, 0);

		//全路径
		char szPathFileName[MAX_PATH] = {0};
		_snprintf(szPathFileName, MAX_PATH, "%s\\%s", szScreenShortPath, szFileName);

		m_pRenderSystem->getRenderWindow()->writeContentsToFile(szPathFileName);
	}
	catch(...)
	{
		return FALSE;	
	}

	strncpy(szReturnBuf, szFileName, nBufSize);
	return TRUE;
}

//// 重新设置旧的显示设置， 全屏显示等 2006－4－10；
//// 登录界面之后。 进入游戏中， 调用这个函数。
//void CRenderSystem::ResetOldShowSetting()
//{
//	//-------------------------------------------
//	//其他需要重置的显示设置
//	{
//		const char* szNeedReset[] = 
//		{
//			"View_FullScreen",		//全屏模式
//			"View_ColorQuality",	//颜色质量
//			"View_Resoution",		//分辨率
//		};
//
//		for(int i=0; i<sizeof(szNeedReset)/sizeof(const char*); i++)
//		{
//			g_pEventSys->PushEvent(GE_VARIABLE_CHANGED, szNeedReset[i], 
//				g_pVaribleSys->GetAs_String(szNeedReset[i]).c_str());
//		}
//	}
//}

// CYS: explicitly requested offline UI evidence; no desktop/front-buffer access.
extern "C" __declspec(dllexport) BOOL __cdecl CysCaptureOfflineUi(CRenderSystem* renderer, const char* filename)
{
    // C export cannot unwind under /EHc. Report the failure; the caller fails its smoke gate.
    try {
        if (!renderer || !renderer->GetRenderSystem()) throw std::runtime_error("render system unavailable");
        cysCaptureOfflineUi(renderer->GetRenderSystem()->getRenderWindow(),filename);
        return TRUE;
    } catch (const Ogre::Exception& e) {
        TDU_Log("CYS UI capture failed: %s",e.getFullDescription().c_str());
    } catch (const std::exception& e) {
        TDU_Log("CYS UI capture failed: %s",e.what());
    } catch (...) {
        TDU_Log("CYS UI capture failed: unknown exception");
    }
    return FALSE;
}
