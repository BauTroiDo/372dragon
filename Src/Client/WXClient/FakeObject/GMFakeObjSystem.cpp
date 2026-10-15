#include "StdAfx.h"
#include "GMFakeObjSystem.h"
#include "..\object\ObjectManager.h"
#include "tdgfxsystem.h"//rendersystem.h"
#include "..\object\object.h"
#include "..\procedure\gameprocedure.h"
#include "TDException.h"
#include "TDUISystem.h"
#include "CysUiMeshBridge.h"
#include "..\WxRender\RenderSystem.h"
#include "TDUtil.h"   // CYS-MESHWIN: TDU_Log
#include "..\DBC\GMDataBase.h"   // CYS-MESHWIN: Model_Parameter.txt (UI camera rows)
#include <type_traits>   // CYS-MESHWIN: static_assert of the bridge exports
#include <vector>        // CYS-MESHWIN: Tick() pending hooks
#include <cstdlib>       // CYS-MESHWIN: strtol

STRING cysMeshWinCameraSpec(tEntityNode* pNode, LPCTSTR szCameraName);   // defined below OnUIHook

WX_IMPLEMENT_DYNAMIC(CFakeObjSystem, GETCLASS(tFakeObjSystem));
CFakeObjSystem* CFakeObjSystem::s_pMe = NULL;
CFakeObjSystem::CFakeObjSystem()
{
	s_pMe = this;
	m_pRotateObj = NULL;
	m_fRotateSpeed = 0.0f;
}

CFakeObjSystem::~CFakeObjSystem()
{
}

tObject* CFakeObjSystem::NewFakeObject(LPCTSTR szClassName, LPCTSTR szObjName, LPCTSTR szCameraName)
{ 
	// 如果已经有这个名字的物体了,就不创建了
	std::map< STRING, FakeObject >::iterator it = m_listFakeMap.find( szObjName );
	if(it != m_listFakeMap.end())
	{
		TDThrow("Fake Object Multi define(%s)", szObjName);
	}

	tObject* pNewNode = CObjectManager::GetMe()->NewObject( szClassName );
	((CObject*)pNewNode)->SetFakeObjectFlag(TRUE);

	FakeObject newFakeObj;
	newFakeObj.bVisible = false;
	newFakeObj.nObjectID= pNewNode->GetID();
	newFakeObj.strName	= szObjName;
	newFakeObj.strCameraName = szCameraName;

	m_listFakeMap.insert(std::make_pair(szObjName, newFakeObj));

	SObjectInit init;
	init.m_fvPos.x = init.m_fvPos.y = init.m_fvPos.z = 100;
	pNewNode->Initial(&init);

	return pNewNode; 
}

VOID CFakeObjSystem::DestroyObject( LPCTSTR szObjName )
{
	std::map< STRING, FakeObject >::iterator it = m_listFakeMap.find(szObjName);
	if(it!=m_listFakeMap.end())
	{
		FakeObject& obj = it->second;

		//找到显示该模型的UI窗口
		std::map< STRING, FakeObject* >::iterator itWin = 
			m_listFakeUI.find(obj.strWindowName);
		if(itWin != m_listFakeUI.end())
		{
			//断开和渲染层、UI层的连接，并释放相应资源
			OnUIUnHook(itWin->first.c_str());
		}

		//销毁逻辑层数据
		CObject* pObj = (CObject*)CObjectManager::GetMe()->FindObject(obj.nObjectID);
		if(pObj)
		{
			pObj->Release();
			CObjectManager::GetMe()->DestroyObject(pObj);
		}

		//从列表中删除
		m_listFakeMap.erase(it);
	}
}

VOID CFakeObjSystem::OnUIHook(LPCTSTR szWindowName, LPCTSTR szObjName)
{
	OnUIHookWithBackground(szWindowName, szObjName, 256, 512, "");
}

// ---- CYS-MESHWIN 19/09: Camera_Main -> Model_Parameter.txt (id, name, height, distance) -> "=h;d" for Render ----
// CanonicalCY: 507 rows, row 0 "默认(必须有这行)" 0.95/5.4, 3 男主角 1.0/6.0, 1 女主角 0.95/5.4, 2 女主角(头) 1.6/1.3,
// 18 宠物:松鼠 0.55/4.8, 489 宠物:烛引沧溟 1.8/9.0. The 0.85 client ships the same table; the 0.85 SOURCE only parsed
// "h;d" out of the property, so a numeric Camera_Main (every CY/B object) fell back to 0.3/1.2 (legs only in the
// SelfEquip portrait, live-3). Opened once through Util_OpenDBCFromTxt like the other CY-only tables; unknown id or
// missing table -> row 0 when present, else the old property string (Render keeps its 0.85 defaults).
namespace
{
	struct CysCameraRow { float fHeight; float fDistance; };
	std::map<int, CysCameraRow> g_cameraRows;
	bool g_cameraRowsTried = false;

	const std::map<int, CysCameraRow>& cysCameraRows()
	{
		if (g_cameraRowsTried) return g_cameraRows;
		g_cameraRowsTried = true;
		DBC::DBCFile* dbc = new DBC::DBCFile(0);
		if (!CDataBase::Util_OpenDBCFromTxt("Model_Parameter.txt", dbc) || dbc->GetFieldsNum() < 4)
		{
			TDU_Log("CYS-MESHWIN: Model_Parameter.txt not found or wrong shape - UI cameras keep the 0.85 defaults");
			delete dbc;
			return g_cameraRows;
		}
		const int rows = (int)dbc->GetRecordsNum();
		for (int row = 0; row < rows; ++row)
		{
			const DBC::DBCFile::FIELD* id = dbc->Search_Posistion(row, 0);
			const DBC::DBCFile::FIELD* h = dbc->Search_Posistion(row, 2);
			const DBC::DBCFile::FIELD* d = dbc->Search_Posistion(row, 3);
			if (!id || !h || !d) continue;
			CysCameraRow r; r.fHeight = h->fValue; r.fDistance = d->fValue;
			g_cameraRows[id->iValue] = r;
		}
		delete dbc;
		TDU_Log("CYS-MESHWIN: Model_Parameter.txt loaded: %d camera rows", (int)g_cameraRows.size());
		return g_cameraRows;
	}
}

STRING cysMeshWinCameraSpec(tEntityNode* pNode, LPCTSTR szCameraName)
{
	STRING value;
	if (pNode && szCameraName) pNode->Actor_GetObjectProperty(szCameraName, value);
	if (value.find(';') != STRING::npos) return szCameraName;   // "h;d" literal - Render parses it as before
	const std::map<int, CysCameraRow>& rows = cysCameraRows();
	if (rows.empty()) return szCameraName;
	char* end = NULL;
	const long id = value.empty() ? 0 : strtol(value.c_str(), &end, 10);
	std::map<int, CysCameraRow>::const_iterator it = (end && *end == 0 && !value.empty()) ? rows.find((int)id) : rows.end();
	if (it == rows.end()) it = rows.find(0);   // "默认(必须有这行)"
	if (it == rows.end()) return szCameraName;
	char spec[64] = {0};
	_snprintf(spec, sizeof(spec) - 1, "=%.4f;%.4f", it->second.fHeight, it->second.fDistance);
	TDU_Log("CYS-MESHWIN: camera %s='%s' -> Model_Parameter row %d -> %s", szCameraName ? szCameraName : "", value.c_str(), (int)it->first, spec);
	return spec;
}

VOID CFakeObjSystem::OnUIHookWithBackground(LPCTSTR szWindowName, LPCTSTR szObjName,
	unsigned int width, unsigned int height, const char* backgroundName)
{
	// CYS-MESHWIN: a new request for this window replaces any hook still waiting for its entity.
	m_pendingHooks.erase(szWindowName);

	//察看是否该窗口已经有显示
	std::map< STRING, FakeObject* >::iterator itWin;
	itWin = m_listFakeUI.find(szWindowName);
	if(itWin != m_listFakeUI.end())
	{
		FakeObject* obj = itWin->second;

		//一样的模型
		if(itWin->second->strName == szObjName) return;

		//首先隐藏该窗口上已有的模型
		OnUIUnHook(szWindowName);
	}

	//找到先前创建的FakeObj
	std::map< STRING, FakeObject >::iterator it = m_listFakeMap.find(szObjName);
	// CYS-MESHEX 19/09: CY's fakeEx AttachWindow (0x1401f9560) creates the object from its registered entry here;
	// the 0.85 road simply returned, which is why every Dress*/NewExterior_* model window stayed empty.
	// The empty name is the DETACH road (DetachWindowEx and every SetFakeObject("") of the CY scripts hook ""), not a
	// missing entry - the unhook above has already run, so leave without looking anything up or logging.
	if(it == m_listFakeMap.end() && szObjName && szObjName[0])
	{
		if (!EnsureExObject(szObjName)) return;
		it = m_listFakeMap.find(szObjName);
	}
	if(it == m_listFakeMap.end()) return;

	FakeObject& obj = it->second;
	//目前不支持一个模型被多个窗口显示
	// CYS-MESHWIN 19/09: in Release TDAssert is (void)0, and a second window attaching the same object would then
	// create the imageset "<obj>_RenderTexture" twice (CEGUI AlreadyExistsException). CY's fakeEx closes the old
	// window of the object first (Game.exe 0x1401f9707-0x1401f9745); do the same here.
	if (!obj.strWindowName.empty() && obj.strWindowName != szWindowName)
	{
		TDU_Log("CYS-MESHWIN: object %s moves from window %s to %s", szObjName, obj.strWindowName.c_str(), szWindowName);
		OnUIUnHook(obj.strWindowName.c_str());
	}
	TDAssert(obj.strWindowName.empty());
	//确认渲染层物体已经创建
	CObject* pObjPoint = (CObject*)CObjectManager::GetMe()->FindObject(obj.nObjectID);
	// CYS-MESHWIN: the 0.85 line here was TDAssert(pObjPoint && pObjPoint->GetRenderInterface()) - and in THIS build
	// TDAssert throws (live-3 12:08:50: Wuhun.lua:327 "host function failed: Assert ... GMFakeObjSystem.cpp Line 126",
	// the Lua handler died before this:Show() and the Wuhun window never opened). The guard below replaces it.
	if (!pObjPoint || !pObjPoint->GetRenderInterface())
	{
		// CYS-MESHWIN: no entity yet (model not set) - wait for it in Tick() instead of handing Render.dll a NULL.
		PendingHook pending;
		pending.strObjName = szObjName;
		pending.nWidth = width;
		pending.nHeight = height;
		pending.strBackground = backgroundName ? backgroundName : "";
		m_pendingHooks[szWindowName] = pending;
		TDU_Log("CYS-MESHWIN: hook window=%s object=%s waits for the entity (object %s)", szWindowName, szObjName, pObjPoint ? "has no model yet" : "not found");
		return;
	}

	//通知渲染层，创建渲染纹理
	// B preserves the main Player portrait size independently of the layout.
	if (strcmp(szObjName, "Player") == 0) { width = 256; height = 512; }
	HMODULE renderModule = GetModuleHandleA("Render.dll");
	if (!renderModule) renderModule = GetModuleHandleA("WXRender.dll");
	CysUiMeshBridge::Create create = renderModule ? reinterpret_cast<CysUiMeshBridge::Create>(
		GetProcAddress(renderModule, "CysFakeObjCreateWithBackground")) : NULL;
	if (!create) TDThrow("MeshWindow: Render background bridge unavailable");
	// CYS-MESHWIN: CY/B keep the camera of a UI model in Model_Parameter.txt, keyed by the object's Camera_Main
	// property (a row id); resolve it here (the DBC reader lives in Game.exe) and hand Render "=<height>;<distance>".
	const STRING strCameraSpec = cysMeshWinCameraSpec(pObjPoint->GetRenderInterface(), obj.strCameraName.c_str());
	create(CGameProcedure::s_pGfxSystem, szObjName, pObjPoint->GetRenderInterface(),
		strCameraSpec.c_str(), width, height, backgroundName);
			
	//通知UI创建相应的Image
	if(CGameProcedure::s_pUISystem)
		CGameProcedure::s_pUISystem->FakeObj_Show(szWindowName, szObjName);

	//加入列表
	obj.strWindowName = szWindowName;
	m_listFakeUI.insert(std::make_pair(szWindowName, &obj));
	TDU_Log("CYS-MESHWIN: hook window=%s object=%s rtt=%ux%u bg=%s", szWindowName, szObjName, width, height, backgroundName ? backgroundName : "");
}

extern "C" __declspec(dllexport) void __cdecl CysFakeObjOnUIHook(
	const char* windowName, const char* objectName, unsigned int width,
	unsigned int height, const char* backgroundName)
{
	CFakeObjSystem* system = CFakeObjSystem::GetMe();
	if (!system || !windowName || !objectName || !backgroundName)
		TDThrow("MeshWindow: invalid Game background bridge call");
	system->OnUIHookWithBackground(windowName, objectName, width, height, backgroundName);
}

// ---- CYS-MESHWIN 19/09: window-keyed accessors + camera / rest-pose bridges for the CY MeshWindow *Ex Lua API ----
namespace
{
	// Render.dll camera exports, resolved once (same road as the Create lookup above).
	struct CysRttCameraBridge
	{
		CysUiMeshBridge::RttCameraGet get;
		CysUiMeshBridge::RttCameraSet set;
		CysUiMeshBridge::RttCameraReset reset;
	};
	const CysRttCameraBridge& cysRttCameraBridge()
	{
		static CysRttCameraBridge s_bridge = {NULL, NULL, NULL};
		static bool s_resolved = false;
		if (!s_resolved)
		{
			s_resolved = true;
			HMODULE renderModule = GetModuleHandleA("Render.dll");
			if (!renderModule) renderModule = GetModuleHandleA("WXRender.dll");
			if (renderModule)
			{
				s_bridge.get = reinterpret_cast<CysUiMeshBridge::RttCameraGet>(GetProcAddress(renderModule, "CysFakeObjRttCameraGet"));
				s_bridge.set = reinterpret_cast<CysUiMeshBridge::RttCameraSet>(GetProcAddress(renderModule, "CysFakeObjRttCameraSet"));
				s_bridge.reset = reinterpret_cast<CysUiMeshBridge::RttCameraReset>(GetProcAddress(renderModule, "CysFakeObjRttCameraReset"));
			}
			TDU_Log("CYS-MESHWIN: Render camera bridge get=%d set=%d reset=%d", s_bridge.get ? 1 : 0, s_bridge.set ? 1 : 0, s_bridge.reset ? 1 : 0);
		}
		return s_bridge;
	}
}

LPCTSTR CFakeObjSystem::GetWindowObject(LPCTSTR szWindowName) const
{
	if (!szWindowName) return NULL;
	std::map< STRING, FakeObject* >::const_iterator it = m_listFakeUI.find(szWindowName);
	if (it == m_listFakeUI.end() || !it->second) return NULL;
	return it->second->strName.c_str();
}

BOOL CFakeObjSystem::IsFakeObject(LPCTSTR szObjName) const
{
	return szObjName && m_listFakeMap.find(szObjName) != m_listFakeMap.end();
}

tObject* CFakeObjSystem::FindFakeObject(LPCTSTR szObjName) const
{
	if (!szObjName) return NULL;
	std::map< STRING, FakeObject >::const_iterator it = m_listFakeMap.find(szObjName);
	if (it == m_listFakeMap.end()) return NULL;
	return CObjectManager::GetMe()->FindObject(it->second.nObjectID);
}

// ---- CYS-MESHEX 19/09: the CY fakeEx entry table (see GMFakeObjSystem.h) -----------------------------------------
// Read off CY 3.71 Game.exe (sha256 9278c7f3...), the 18 calls of 0x1401f8eb0 inside CDataPool::Initial. Each entry
// is (class, object name, camera); the camera is "Camera_Main" in every one of the 18. Five of the names are already
// created eagerly by this tree (Player / My_Pet / My_TargetPet, and the two pets' own road), so only the rest are
// created lazily here - a name that is already in m_listFakeMap is never touched.
namespace
{
	struct CysExEntry { const char* szObject; const char* szClass; const char* szCamera; };
	const CysExEntry kCysExEntries[] = {
		{"Rabbit",                  "CObject_PlayerNPC",   "Camera_Main"},   // GL GM creature preview
		{"Pet_Tujian",              "CObject_PlayerNPC",   "Camera_Main"},
		{"My_Pet",                  "CObject_PlayerNPC",   "Camera_Main"},   // 0x1400e5dcc
		{"My_OtherPet",             "CObject_PlayerNPC",   "Camera_Main"},   // 0x1400e5e05
		{"My_TargetPet",            "CObject_PlayerNPC",   "Camera_Main"},   // 0x1400e5e3e
		{"PetOneType_ShopView",     "CObject_PlayerNPC",   "Camera_Main"},   // 0x1400e60ea
		{"Player",                  "CObject_PlayerOther", "Camera_Main"},   // 0x1400e6c5d
		{"DecoWeapon_Player",       "CObject_PlayerOther", "Camera_Main"},   // 0x1400e6c96
		{"FashionAction_Player",    "CObject_PlayerOther", "Camera_Main"},   // 0x1400e6ccf
		{"Exterior_Player",         "CObject_PlayerOther", "Camera_Main"},   // 0x1400e6d08
		{"Exterior_Ride",           "CObject_PlayerNPC",   "Camera_Main"},   // 0x1400e6d41  (NPC, not Other)
		{"Exterior_Target",         "CObject_PlayerOther", "Camera_Main"},   // 0x1400e6d7a
		{"ChongLou_Player",         "CObject_PlayerOther", "Camera_Main"},   // 0x1400e6db3
		{"Exterior_OtherShare",     "CObject_PlayerOther", "Camera_Main"},   // 0x1400e6dec
		{"PlayerDressPaint_sp",     "CObject_PlayerOther", "Camera_Main"},   // 0x1400e6e25
		{"PlayerDressJian_sp",      "CObject_PlayerOther", "Camera_Main"},   // 0x1400e6e5e
		{"DressPreview_Player",     "CObject_PlayerOther", "Camera_Main"},   // 0x1400e6e97
		{"GemEffectPreview_Player", "CObject_PlayerOther", "Camera_Main"},   // 0x1400e6ed0
		{"Ornaments_Player",        "CObject_PlayerOther", "Camera_Main"},   // 0x1400e6f09
		// 0x1400e6971 is a loop: "XFSJFakeObj_PlayerNew%d" 0..5, CObject_PlayerOther (ServerNew_XFSJ.lua:159 builds
		// the same name with (index-1)). Spelled out so the table stays a plain lookup.
		{"XFSJFakeObj_PlayerNew0",  "CObject_PlayerOther", "Camera_Main"},
		{"XFSJFakeObj_PlayerNew1",  "CObject_PlayerOther", "Camera_Main"},
		{"XFSJFakeObj_PlayerNew2",  "CObject_PlayerOther", "Camera_Main"},
		{"XFSJFakeObj_PlayerNew3",  "CObject_PlayerOther", "Camera_Main"},
		{"XFSJFakeObj_PlayerNew4",  "CObject_PlayerOther", "Camera_Main"},
		{"XFSJFakeObj_PlayerNew5",  "CObject_PlayerOther", "Camera_Main"},
	};

	const CysExEntry* cysExEntry(LPCTSTR szObjName)
	{
		if (!szObjName) return NULL;
		for (size_t i = 0; i < sizeof(kCysExEntries) / sizeof(kCysExEntries[0]); ++i)
			if (strcmp(kCysExEntries[i].szObject, szObjName) == 0) return &kCysExEntries[i];
		return NULL;
	}
}

LPCTSTR CFakeObjSystem::ExObjectClass(LPCTSTR szObjName)
{
	const CysExEntry* entry = cysExEntry(szObjName);
	return entry ? entry->szClass : NULL;
}

tObject* CFakeObjSystem::EnsureExObject(LPCTSTR szObjName)
{
	if (!szObjName) return NULL;
	std::map< STRING, FakeObject >::iterator it = m_listFakeMap.find(szObjName);
	if (it != m_listFakeMap.end())
		return CObjectManager::GetMe()->FindObject(it->second.nObjectID);

	const CysExEntry* entry = cysExEntry(szObjName);
	if (!entry)
	{
		// CY 0x1401f95bf prints exactly this when the NAME has no entry; keep the same wording so a missing frame
		// is recognisable in the log instead of being a silent no-op.
		TDU_Log("CYS-MESHEX: FakeObjectAttachWindow: Fake ObjectEx szObjName is not exist(%s)", szObjName);
		return NULL;
	}
	if (!CObjectManager::GetMe()) return NULL;
	tObject* pNew = NewFakeObject(entry->szClass, entry->szObject, entry->szCamera);
	TDU_Log("CYS-MESHEX: created Ex object %s (%s) lazily", entry->szObject, entry->szClass);
	return pNew;
}

BOOL CFakeObjSystem::RestPose(LPCTSTR szWindowName)
{
	std::map< STRING, FakeObject* >::iterator it = szWindowName ? m_listFakeUI.find(szWindowName) : m_listFakeUI.end();
	if (it == m_listFakeUI.end() || !it->second) return FALSE;
	FakeObject& obj = *(it->second);
	if (m_pRotateObj == &obj) m_pRotateObj = NULL;
	// [SL] CY's RestPositonEx ends in Render.dll (fakeEx vt[20] -> render vt[0x9e](window)), not disassembled;
	// the avatars are created facing 0 (Obj_PlayerMySelf.cpp:132, GMDataPool.cpp Pet_SetPetModel), so "rest" = face 0
	// + the camera the object started with.
	CObject* pObj = (CObject*)CObjectManager::GetMe()->FindObject(obj.nObjectID);
	if (pObj) pObj->SetFaceDir(0.0f);
	const CysRttCameraBridge& bridge = cysRttCameraBridge();
	if (bridge.reset) bridge.reset(obj.strName.c_str());
	return TRUE;
}

BOOL CFakeObjSystem::GetCamera(LPCTSTR szWindowName, float* pHeight, float* pDistance, float* pPitch, float* pXOffset)
{
	LPCTSTR szObjName = GetWindowObject(szWindowName);
	const CysRttCameraBridge& bridge = cysRttCameraBridge();
	if (!szObjName || !bridge.get)
	{
		// CYS-WARDROBE: the hook is still waiting - hand back what was set in the same Lua call, so a frame that
		// reads its own camera back (NewExterior_*, DressPreview) does not compute the next value from the defaults.
		std::map< STRING, PendingCamera >::const_iterator it = szWindowName ? m_pendingCamera.find(szWindowName) : m_pendingCamera.end();
		if (it == m_pendingCamera.end()) return FALSE;
		if (pHeight) *pHeight = it->second.h;
		if (pDistance) *pDistance = it->second.d;
		if (pPitch) *pPitch = it->second.p;
		if (pXOffset) *pXOffset = it->second.x;
		return TRUE;
	}
	return bridge.get(szObjName, pHeight, pDistance, pPitch, pXOffset) == 1;
}

BOOL CFakeObjSystem::SetCamera(LPCTSTR szWindowName, float fHeight, float fDistance, float fPitch, float fXOffset)
{
	LPCTSTR szObjName = GetWindowObject(szWindowName);
	const CysRttCameraBridge& bridge = cysRttCameraBridge();
	if (!bridge.set || !szWindowName) return FALSE;
	if (!szObjName)
	{
		// CYS-WARDROBE: no RTT yet. Keep it only while a hook for this window is actually waiting; Tick() replays it.
		if (m_pendingHooks.find(szWindowName) == m_pendingHooks.end()) return FALSE;
		PendingCamera c = {fHeight, fDistance, fPitch, fXOffset};
		m_pendingCamera[szWindowName] = c;
		TDU_Log("CYS-WARDROBE: camera for %s deferred (hook waiting) h=%.4f d=%.4f p=%.4f x=%.4f",
			szWindowName, fHeight, fDistance, fPitch, fXOffset);
		return TRUE;
	}
	m_pendingCamera.erase(szWindowName);
	return bridge.set(szObjName, fHeight, fDistance, fPitch, fXOffset) == 1;
}

// Exports for UI_CEGUI.dll (CysUiMeshBridge.h). 1 = done, 0 = unknown window / object. Never throw: a missing
// camera is a cosmetic loss, not a reason to end the process inside a Lua call.
extern "C" __declspec(dllexport) int __cdecl CysFakeObjCameraGet(
	const char* windowName, float* height, float* distance, float* pitch, float* xOffset)
{
	CFakeObjSystem* system = CFakeObjSystem::GetMe();
	return (system && windowName && system->GetCamera(windowName, height, distance, pitch, xOffset)) ? 1 : 0;
}
extern "C" __declspec(dllexport) int __cdecl CysFakeObjCameraSet(
	const char* windowName, float height, float distance, float pitch, float xOffset)
{
	CFakeObjSystem* system = CFakeObjSystem::GetMe();
	return (system && windowName && system->SetCamera(windowName, height, distance, pitch, xOffset)) ? 1 : 0;
}
extern "C" __declspec(dllexport) int __cdecl CysFakeObjRestPose(const char* windowName)
{
	CFakeObjSystem* system = CFakeObjSystem::GetMe();
	return (system && windowName && system->RestPose(windowName)) ? 1 : 0;
}
extern "C" __declspec(dllexport) int __cdecl CysFakeObjExists(const char* objectName)
{
	CFakeObjSystem* system = CFakeObjSystem::GetMe();
	return (system && objectName && system->IsFakeObject(objectName)) ? 1 : 0;
}
static_assert(std::is_same<decltype(&CysFakeObjCameraGet), CysUiMeshBridge::CameraGet>::value, "CysFakeObjCameraGet signature");
static_assert(std::is_same<decltype(&CysFakeObjCameraSet), CysUiMeshBridge::CameraSet>::value, "CysFakeObjCameraSet signature");
static_assert(std::is_same<decltype(&CysFakeObjRestPose), CysUiMeshBridge::RestPose>::value, "CysFakeObjRestPose signature");
static_assert(std::is_same<decltype(&CysFakeObjExists), CysUiMeshBridge::ObjectExists>::value, "CysFakeObjExists signature");

VOID CFakeObjSystem::OnUIUnHook(LPCTSTR szWindowName)
{
	m_pendingHooks.erase(szWindowName);   // CYS-MESHWIN: a waiting hook is cancelled by the detach as well
	m_pendingCamera.erase(szWindowName);  // CYS-WARDROBE: and so is a camera that was waiting for it

	std::map< STRING, FakeObject* >::iterator itWin;
	itWin = m_listFakeUI.find(szWindowName);
	if(itWin == m_listFakeUI.end()) return;

	FakeObject& obj = *(itWin->second);

	//通知UI
	if(CGameProcedure::s_pUISystem)
		CGameProcedure::s_pUISystem->FakeObj_Close(szWindowName, obj.strName.c_str());

	//删除渲染层中的渲染纹理
	CGameProcedure::s_pGfxSystem->FakeObj_Destroy(obj.strName.c_str());

	//从列表中删除
	obj.strWindowName.clear();
	m_listFakeUI.erase(itWin);
}

VOID CFakeObjSystem::OnUIShown(LPCTSTR szWindowName, float fAspectRatio)
{
	m_shownAspect[szWindowName] = fAspectRatio;   // CYS-MESHWIN: kept for a hook that is still waiting for its entity

	std::map< STRING, FakeObject* >::iterator it = m_listFakeUI.find(szWindowName);
	if(it == m_listFakeUI.end()) return;

	//通知渲染层，开始渲染该模型
	CGameProcedure::s_pGfxSystem->FakeObj_Show(it->second->strName.c_str(), TRUE, fAspectRatio);
}

VOID CFakeObjSystem::OnUIHiden(LPCTSTR szWindowName)
{
	m_shownAspect.erase(szWindowName);   // CYS-MESHWIN

	std::map< STRING, FakeObject* >::iterator it = m_listFakeUI.find(szWindowName);
	if(it == m_listFakeUI.end()) return;

	//通知渲染层，停止渲染该模型
	CGameProcedure::s_pGfxSystem->FakeObj_Show(it->second->strName.c_str(), FALSE, 0.0f);
}

VOID CFakeObjSystem::RotateObj_Begin(LPCTSTR szObjName, FLOAT fAngle)
{
	std::map< STRING, FakeObject >::iterator it = m_listFakeMap.find(szObjName);
	if(it == m_listFakeMap.end()) return;

	//开始旋转模型
	m_pRotateObj = &(it->second);
	m_fRotateSpeed = fAngle;
}

VOID CFakeObjSystem::Obj_ChangeAction(LPCTSTR szObjName, INT SkillID,INT SkillLoop)
{
	std::map< STRING, FakeObject >::iterator it = m_listFakeMap.find(szObjName);
	if(it == m_listFakeMap.end()) return;

	//开始旋转模型
	m_pActionObj = &(it->second);
	CObject* pObj = (CObject*)CObjectManager::GetMe()->FindObject(m_pActionObj->nObjectID);
	((CObject_Character*)pObj)->ChangeAction(SkillID,1.5f,SkillLoop);
}

VOID CFakeObjSystem::RotateObj_End(LPCTSTR szObjName)
{
//	std::map< STRING, FakeObject >::iterator it = m_listFakeMap.find(szObjName);
//	if(it == m_listFakeMap.end()) return;

//	CObject* pObj = (CObject*)(it->second.pObject);

	//停止旋转模型
	m_pRotateObj = NULL;
}

VOID CFakeObjSystem::Initial(VOID*)
{
}

VOID CFakeObjSystem::Tick(VOID)
{
	// CYS-MESHWIN: complete the hooks that waited for their entity (see PendingHook). Ready ones are collected
	// first because OnUIHookWithBackground edits m_pendingHooks itself.
	if (!m_pendingHooks.empty())
	{
		std::vector< std::pair< STRING, PendingHook > > ready;
		for (std::map< STRING, PendingHook >::iterator it = m_pendingHooks.begin(); it != m_pendingHooks.end(); ++it)
		{
			std::map< STRING, FakeObject >::iterator itObj = m_listFakeMap.find(it->second.strObjName);
			if (itObj == m_listFakeMap.end()) continue;
			CObject* pObj = (CObject*)CObjectManager::GetMe()->FindObject(itObj->second.nObjectID);
			if (pObj && pObj->GetRenderInterface()) ready.push_back(*it);
		}
		for (size_t i = 0; i < ready.size(); ++i)
		{
			const STRING& strWindow = ready[i].first;
			const PendingHook& pending = ready[i].second;
			OnUIHookWithBackground(strWindow.c_str(), pending.strObjName.c_str(), pending.nWidth, pending.nHeight, pending.strBackground.c_str());
			std::map< STRING, float >::iterator itShown = m_shownAspect.find(strWindow);
			if (itShown != m_shownAspect.end() && m_listFakeUI.find(strWindow) != m_listFakeUI.end())
			{
				// MeshShown fired while the hook was waiting: start the texture now, as OnUIShown would have.
				CGameProcedure::s_pGfxSystem->FakeObj_Show(pending.strObjName.c_str(), TRUE, itShown->second);
				TDU_Log("CYS-MESHWIN: hook window=%s object=%s completed late, texture started (aspect %.3f)", strWindow.c_str(), pending.strObjName.c_str(), itShown->second);
			}
			// CYS-WARDROBE: replay the camera the frame set before its RTT existed (see m_pendingCamera).
			std::map< STRING, PendingCamera >::iterator itCam = m_pendingCamera.find(strWindow);
			if (itCam != m_pendingCamera.end())
			{
				const PendingCamera c = itCam->second;
				m_pendingCamera.erase(itCam);
				const BOOL ok = SetCamera(strWindow.c_str(), c.h, c.d, c.p, c.x);
				TDU_Log("CYS-WARDROBE: camera for %s replayed after the hook h=%.4f d=%.4f p=%.4f x=%.4f ok=%d",
					strWindow.c_str(), c.h, c.d, c.p, c.x, ok ? 1 : 0);
			}
		}
	}

	if(m_pRotateObj)
	{
		CObject* pObj = (CObject*)CObjectManager::GetMe()->FindObject(m_pRotateObj->nObjectID);
		if(!pObj) return;

		FLOAT fAngleNow = pObj->GetFaceDir();
		pObj->SetFaceDir(fAngleNow+m_fRotateSpeed);
	}
}


VOID CFakeObjSystem::Release(VOID)
{
//	m_listFakeMap.clear();
}
