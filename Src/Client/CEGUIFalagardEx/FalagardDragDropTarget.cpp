// CYS-HUD: Falagard/DragDropTarget + Falagard/DragContainer. See the header for the evidence from client_GL.
#include "FalagardDragDropTarget.h"
#include "CEGUIPropertyHelper.h"
#include "falagard/CEGUIFalWidgetLookManager.h"
#include "falagard/CEGUIFalWidgetLookFeel.h"

namespace CEGUI
{
    namespace
    {
        class HoverStateProperty : public Property
        {
        public:
            HoverStateProperty() : Property("HoverState", "Property to get/set the hover state of FalDragDropTarget Window.", "False") {}
            String get(const PropertyReceiver* r) const { return PropertyHelper::boolToString(static_cast<const FalagardDragDropTarget*>(r)->GetHovering()); }
            void set(PropertyReceiver* r, const String& v) { static_cast<FalagardDragDropTarget*>(r)->SetHovering(PropertyHelper::stringToBool(v)); }
        };
        HoverStateProperty s_hoverState;

        void renderState(Window& w, const String& look, const char* state, const char* fallback)
        {
            if (look.empty()) return;
            const WidgetLookFeel& wlf = WidgetLookManager::getSingleton().getWidgetLook(look);
            if (wlf.isStateImageryPresent(state)) wlf.getStateImagery(state).render(w);
            else if (fallback && wlf.isStateImageryPresent(fallback)) wlf.getStateImagery(fallback).render(w);
        }
    }

    const utf8 FalagardDragDropTarget::WidgetTypeName[] = "Falagard/DragDropTarget";
    const String FalagardDragDropTarget::EventNamespace("DragDropTarget");
    const String FalagardDragDropTarget::EventDragDropTargetChanged("DragDropTargetChanged");
    const utf8 FalagardDragContainer::WidgetTypeName[] = "Falagard/DragContainer";

    FalagardDragDropTarget::FalagardDragDropTarget(const String& type, const String& name) :
        Window(type, name), d_hovering(false)
    {
        CEGUI_START_ADD_STATICPROPERTY(FalagardDragDropTarget)
            CEGUI_ADD_STATICPROPERTY(&s_hoverState);
        CEGUI_END_ADD_STATICPROPERTY
        addEvent(EventDragDropTargetChanged);
    }

    FalagardDragDropTarget::~FalagardDragDropTarget() {}

    void FalagardDragDropTarget::SetHovering(bool hovering)
    {
        if (d_hovering == hovering) return;
        d_hovering = hovering;
        WindowEventArgs args(this);
        fireEvent(EventDragDropTargetChanged, args, EventNamespace);
        requestRedraw();
    }

    void FalagardDragDropTarget::populateRenderCache()
    {
        renderState(*this, d_lookName, isDisabled() ? "Disabled" : (d_hovering ? "Hover" : "Normal"), "Enabled");
    }

    void FalagardDragDropTarget::onDragDropItemEnters(DragDropEventArgs& e)
    {
        SetHovering(true);
        Window::onDragDropItemEnters(e);
    }

    void FalagardDragDropTarget::onDragDropItemLeaves(DragDropEventArgs& e)
    {
        SetHovering(false);
        Window::onDragDropItemLeaves(e);
    }

    void FalagardDragDropTarget::onDragDropItemDropped(DragDropEventArgs& e)
    {
        SetHovering(false);
        Window::onDragDropItemDropped(e);
    }

    void FalagardDragContainer::populateRenderCache()
    {
        renderState(*this, d_lookName, isDisabled() ? "Disabled" : "Enabled", 0);
    }
}
