/****************************************\
*										*
* 	  用于在ui上显示的物体管理器接口	*
*										*
\****************************************/

#pragma once
#include "TDFakeObjSystem.h"

class CFakeObjSystem : public tFakeObjSystem
{
	//-----------------------------------------------------------
	//功能接口
	//-----------------------------------------------------------
protected:
	struct FakeObject
	{
		STRING			strName;		//名字，UI控件根据该名字控制
		INT				nObjectID;		//逻辑Obj对象ID
		BOOL			bVisible;		//当前该对象是否需要显示
		STRING			strWindowName;	//显示该模型的窗口名
		STRING			strCameraName;	//该窗口的摄象机名字
	};

public:
	//创建/销毁在ui上显示的obj对象
	virtual tObject*		NewFakeObject(LPCTSTR szClassName, LPCTSTR szObjName, LPCTSTR szCameraName);
	virtual VOID			DestroyObject(LPCTSTR szObjName);

	//UI需要显示某物体
	virtual VOID			OnUIHook(LPCTSTR szWindowName, LPCTSTR szObjName);
	VOID OnUIHookWithBackground(LPCTSTR szWindowName, LPCTSTR szObjName,
		unsigned int width, unsigned int height, const char* backgroundName);
	//UI不再需要显示某物体
	virtual VOID			OnUIUnHook(LPCTSTR szWindowName);

	//UI显示/隐藏
	virtual	VOID			OnUIShown(LPCTSTR szWindowName, float fAspectRatio);
	virtual VOID			OnUIHiden(LPCTSTR szWindowName);

	//旋转模型
	virtual VOID			RotateObj_Begin(LPCTSTR szObjName, FLOAT fAngle);
	virtual VOID			RotateObj_End(LPCTSTR szObjName);
	virtual VOID			Obj_ChangeAction(LPCTSTR szObjName, INT SkillID,INT SkillLoop);

	// CYS-MESHWIN 19/09: the CY MeshWindow *Ex Lua API (UI_CEGUI.dll) addresses this system by WINDOW name, as
	// CY's second node "bin\fakeEx" (CFakeObjSystemEx) does; these are non-virtual (no vtable change, see
	// CysUiMeshBridge.h) and reach the render layer through the Render.dll exports CysFakeObjRttCamera*.
	LPCTSTR					GetWindowObject(LPCTSTR szWindowName) const;	// object shown in the window, NULL when none
	BOOL					IsFakeObject(LPCTSTR szObjName) const;			// CY fakeEx vt[23]







	static LPCTSTR			ExObjectClass(LPCTSTR szObjName);				// NULL when the name is not a CY Ex entry
	tObject*				EnsureExObject(LPCTSTR szObjName);				// creates it once; NULL when unknown
	tObject*				FindFakeObject(LPCTSTR szObjName) const;		// the logical object behind a fake name
	BOOL					RestPose(LPCTSTR szWindowName);					// CY RestPositonEx: stop rotating, face 0, camera defaults [SL]
	BOOL					GetCamera(LPCTSTR szWindowName, float* pHeight, float* pDistance, float* pPitch, float* pXOffset);
	BOOL					SetCamera(LPCTSTR szWindowName, float fHeight, float fDistance, float fPitch, float fXOffset);

	//-----------------------------------------------------------
	//受管理的obj对象，最多32个
	//-----------------------------------------------------------
protected:

	//FakeObj链表，最多32个
	std::map< STRING, FakeObject > m_listFakeMap;

	//以窗口名为索引
	std::map< STRING, FakeObject* > m_listFakeUI;

	// CYS-MESHWIN 19/09: a hook asked for before the object has its render entity (Pet.lua:518 attaches "My_Pet"
	// BEFORE Pet:SetModel creates the pet's model; Wuhun.lua:327 the same without a wuhun). 0.85 asserted here and
	// Release then handed a NULL entity to Render.dll (OGRE_EXCEPT through the Lua call). CY's fakeEx creates the
	// object inside Attach and fills it later; here the hook waits in this map and Tick() completes it as soon as
	// the entity exists. m_shownAspect remembers OnUIShown for windows whose hook is still pending, so the texture
	// starts updating when the hook completes.
	struct PendingHook
	{
		STRING			strObjName;
		unsigned int	nWidth;
		unsigned int	nHeight;
		STRING			strBackground;
	};
	std::map< STRING, PendingHook >	m_pendingHooks;
	std::map< STRING, float >		m_shownAspect;

	// CYS-WARDROBE 19/09: a camera set while the hook is still waiting. NewExterior_PlayerFrame_Show() runs
	// AttachWindowEx -> LuaFnUpdateExteriorPlayerData -> ... -> UpdateCamera in ONE Lua call, but the object only
	// gets its entity when Set_RaceID builds the model, so the hook finishes in the next Tick and the Get/SetCameraEx
	// pair in between reached no RTT at all (live-1 17:48:36: "GetCameraEx ... rc=0", "SetCameraEx ... rc=0", and
	// the frame opened at the 0.85 default 0.3/1.2 instead of the frame's own 0.85/7.2). Remember it and replay it
	// when the hook completes - same shape as m_shownAspect above.
	struct PendingCamera { float h, d, p, x; };
	std::map< STRING, PendingCamera > m_pendingCamera;

	//正在旋转中的模型
	FakeObject*						m_pRotateObj;
	FakeObject*						m_pActionObj;
	FLOAT							m_fRotateSpeed;

	//-----------------------------------------------------------
	//核心继承
	//-----------------------------------------------------------
public:
	virtual VOID	Initial(VOID*);
	virtual VOID	Release(VOID);
	virtual VOID	Tick(VOID);


public:
	CFakeObjSystem();
	virtual ~CFakeObjSystem();

	static CFakeObjSystem*	GetMe(void) { return s_pMe; }

protected:
	static CFakeObjSystem* s_pMe;
protected:
	WX_DECLARE_DYNAMIC(CFakeObjSystem);
};
