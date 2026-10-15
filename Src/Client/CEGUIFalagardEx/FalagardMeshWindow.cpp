
#include "FalagardMeshWindow.h"
#include "CEGUIImageset.h"
#include "CEGUISystem.h"
#include "CEGUIRenderer.h"
#include "CEGUITexture.h"
#include "OgreCEGUIRenderer.h"
#include "CEGUIWindowManager.h"
#include "AxTrace.h" // CYS: was "..\Common\AxTrace.h" (0.85 Client\Common = Src\Engine\Interface, on the include path)

// Start of CEGUI namespace section
namespace CEGUI
{
	//===================================================================================
	//
	// FalagardMeshWindow
	//
	//===================================================================================
	const utf8 FalagardMeshWindow::WidgetTypeName[] = "Falagard/MeshWindow";

    // Event Strings
    const String FalagardMeshWindow::EventNamespace("Falagard/MeshWindow");

    const String FalagardMeshWindow::EventMeshHook("MeshHook");
    const String FalagardMeshWindow::EventMeshShown("MeshShown");
    const String FalagardMeshWindow::EventMeshHidden("MeshHidden");

    // Properties
	FalagardMeshWindowProperties::FakeObject	FalagardMeshWindow::d_fakeObjectProperty;
	FalagardMeshWindowProperties::ShowControl	FalagardMeshWindow::d_showControlProperty;
	FalagardMeshWindowProperties::BackgroundName FalagardMeshWindow::d_backgroundNameProperty;

	FalagardMeshWindow::FalagardMeshWindow(const String& type, const String& name):
		StaticImage(type, name)
	{
		addMeshWindowProperties();
	}

	FalagardMeshWindow::~FalagardMeshWindow(void)
	{
	}

	void FalagardMeshWindow::addMeshWindowProperties(void)
	{
		CEGUI_START_ADD_STATICPROPERTY( FalagardMeshWindow )
		   CEGUI_ADD_STATICPROPERTY( &d_fakeObjectProperty );
		   CEGUI_ADD_STATICPROPERTY( &d_showControlProperty );
		   CEGUI_ADD_STATICPROPERTY( &d_backgroundNameProperty );
		CEGUI_END_ADD_STATICPROPERTY
	}

	void FalagardMeshWindow::setShowControl(const String& windowName)
	{
		d_showControlWindowName = windowName;

		//Get the window point.
		Window* pControlWindow = WindowManager::getSingleton().getWindow(windowName);
		if(!pControlWindow) return;

		//Subscribe the ShownEvent and HiddenEvent.
		pControlWindow->subscribeEvent(EventShown,
			CEGUI::Event::Subscriber(&CEGUI::FalagardMeshWindow::handleControlShown, this));

		pControlWindow->subscribeEvent(EventHidden,
			CEGUI::Event::Subscriber(&CEGUI::FalagardMeshWindow::handleControlHidden, this));
	}

	void FalagardMeshWindow::onParentHidden(void)
	{
		StaticImage::onParentHidden();

		WindowEventArgs args(this);
		fireEvent(EventMeshHidden, args, EventNamespace);
	}

    void FalagardMeshWindow::onShown(WindowEventArgs& e)
    {
        StaticImage::onShown(e);
        // AttachWindowEx may bind an RTT while this widget is hidden. Merely
        // showing the StaticImage does not start that render target: the first
        // mount then displays an uninitialised/recycled texture until reselect.
        if (!d_fakeObjectName.empty() && isVisible())
        {
            WindowEventArgs args(this);
            fireEvent(EventMeshShown, args, EventNamespace);
        }
    }

    void FalagardMeshWindow::onHidden(WindowEventArgs& e)
    {
        StaticImage::onHidden(e);
        WindowEventArgs args(this);
        fireEvent(EventMeshHidden, args, EventNamespace);
    }

    void FalagardMeshWindow::onSized(WindowEventArgs& e)
    {
        StaticImage::onSized(e);
        // Opt-in negative control for the live aspect regression.
        static const bool oldAspect=[](){ char v[8]={}; return GetEnvironmentVariableA("CYS_PREVIEW_ASPECT_OLD",v,8)>0 && v[0]=='1'; }();
        if (oldAspect) return;
        // The RTT is stretched to this widget. Its camera must use the NEW
        // display aspect, including when wardrobe variant controls resize it.
        // Reuse the existing notification; do not recreate the actor/texture.
        if (!d_fakeObjectName.empty() && isVisible())
        {
            WindowEventArgs args(this);
            fireEvent(EventMeshShown, args, EventNamespace);
        }
    }

	void FalagardMeshWindow::setFakeObject(const String& fakeObject)
	{ 
		d_fakeObjectName = fakeObject;

		if(!d_fakeObjectName.empty() && isVisible())
		{
			WindowEventArgs args(this);
			fireEvent(EventMeshShown, args, EventNamespace);
		}
	}

	void FalagardMeshWindow::setBackgroundName(const String& backgroundName)
	{
		d_backgroundName = backgroundName;
		// B setter raises MeshShown for each nonempty assignment while visible.
		if (!d_backgroundName.empty() && isVisible(false))
		{
			WindowEventArgs args(this);
			fireEvent(EventMeshShown, args, EventNamespace);
		}
	}

	bool FalagardMeshWindow::handleControlShown(const CEGUI::EventArgs& e)
	{
		WindowEventArgs args(this);
		fireEvent(EventMeshShown, args, EventNamespace);

		requestRedraw();
		return false;
	}

	bool FalagardMeshWindow::handleControlHidden(const CEGUI::EventArgs& e)
	{
		WindowEventArgs args(this);
		fireEvent(EventMeshHidden, args, EventNamespace);

		return false;
	}

	void FalagardMeshWindow::subscribeShownEvent(Event::Subscriber subscriber)
	{
		subscribeEvent(EventMeshShown, subscriber);
	}
	
	void FalagardMeshWindow::subscribeHidenEvent(Event::Subscriber subscriber)
	{
		subscribeEvent(EventMeshHidden, subscriber);
	}
	
	void FalagardMeshWindow::subscribeHookEvent(Event::Subscriber subscriber)
	{
		subscribeEvent(EventMeshHook, subscriber);
	}

	void FalagardMeshWindow::populateRenderCache()
	{
//		StaticImage::populateRenderCache();
		d_image.setVertFormatting(RenderableImage::VertStretched);
		d_image.setHorzFormatting(RenderableImage::HorzStretched);

		d_image.draw(d_renderCache);
	}

	//////////////////////////////////////////////////////////////////////////
    Window* FalagardMeshWindowFactory::createWindow(const String& name)
    {
        return new FalagardMeshWindow(d_type, name);
    }

    void FalagardMeshWindowFactory::destroyWindow(Window* window)
    {
        delete window;
    }
};
