#pragma once
// CYS-HUD: Falagard/DragDropTarget + Falagard/DragContainer (GL union-frame member drag & drop; absent from 0.85).
// Evidence: client_GL CEGUIFalagard.dll exports FalagardDragDropTarget::{SetHovering, GetHovering,
// handleDragDropItemEnters, handleDragDropItemLeaves, handleDragDropItemDropped, populateRenderCache,
// d_HoverStateProperty, addFalagardDragDropTargetProperties}; strings "HoverState" ("Property to get/set the hover
// state of FalDragDropTarget Window."), "DragDropTargetChanged", "Falagard/DragContainer", "LoseCapture".
// Looks: TLBB_Look_UnionDragTarget (states Normal/Hover/Disabled + label section with the window Text),
// TLBB_UnionDragItem = Falagard/DragContainer with TLBB_Look_StaticImage (empty states; content = child windows).
// Layouts (UnionFrame): DragContainer subscribes MouseLClick/MouseRClick/DragStarted; the target receives the
// CEGUI drag-drop events (DragDropItemEnters/Leaves/Dropped) which the Lua layer handles.
#include "FalModule.h"
#include "CEGUIWindowFactory.h"
#include "elements/CEGUIDragContainer.h"

namespace CEGUI
{
    class FALAGARDBASE_API FalagardDragDropTarget : public Window
    {
    public:
        static const utf8 WidgetTypeName[];
        static const String EventNamespace;
        static const String EventDragDropTargetChanged; //!< hover state changed (a drag item entered or left)

        FalagardDragDropTarget(const String& type, const String& name);
        ~FalagardDragDropTarget();

        void SetHovering(bool hovering);
        bool GetHovering() const { return d_hovering; }

    protected:
        virtual void populateRenderCache();
        virtual void onDragDropItemEnters(DragDropEventArgs& e);
        virtual void onDragDropItemLeaves(DragDropEventArgs& e);
        virtual void onDragDropItemDropped(DragDropEventArgs& e);
        virtual bool testClassName_impl(const String& class_name) const
        {
            if (class_name == (const utf8*)"FalagardDragDropTarget") return true;
            return Window::testClassName_impl(class_name);
        }
        bool d_hovering;
    };

    class FALAGARDBASE_API FalagardDragContainer : public DragContainer
    {
    public:
        static const utf8 WidgetTypeName[];
        FalagardDragContainer(const String& type, const String& name) : DragContainer(type, name) {}
    protected:
        virtual void populateRenderCache();
        virtual bool testClassName_impl(const String& class_name) const
        {
            if (class_name == (const utf8*)"FalagardDragContainer") return true;
            return DragContainer::testClassName_impl(class_name);
        }
    };

    class FALAGARDBASE_API FalagardDragDropTargetFactory : public WindowFactory
    {
    public:
        FalagardDragDropTargetFactory() : WindowFactory(FalagardDragDropTarget::WidgetTypeName) {}
        Window* createWindow(const String& name) { return new FalagardDragDropTarget(d_type, name); }
        void destroyWindow(Window* window) { delete window; }
    };

    class FALAGARDBASE_API FalagardDragContainerFactory : public WindowFactory
    {
    public:
        FalagardDragContainerFactory() : WindowFactory(FalagardDragContainer::WidgetTypeName) {}
        Window* createWindow(const String& name) { return new FalagardDragContainer(d_type, name); }
        void destroyWindow(Window* window) { delete window; }
    };
}
