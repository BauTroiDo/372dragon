#include "FalagardLoginWidgets.h"
#include "CEGUIAnimate.h"
#include "CEGUIAnimateManager.h"
#include "CEGUISystem.h"

namespace CEGUI {
const utf8 FalagardAnimateImage::WidgetTypeName[] = "Falagard/AnimateImage";
const utf8 FalagardAnimateButton::WidgetTypeName[] = "Falagard/AnimateButton";
const utf8 FalagardSafeIMEEditBox::WidgetTypeName[] = "Falagard/SafeIMEEditBox";
namespace {
class AnimateImageProperty : public Property {
public:
    AnimateImageProperty() : Property("Animate", "Animation resource name.", "") {}
    String get(const PropertyReceiver* r) const override { return static_cast<const FalagardAnimateImage*>(r)->getAnimate(); }
    void set(PropertyReceiver* r, const String& value) override { static_cast<FalagardAnimateImage*>(r)->setAnimate(value); }
} animateProperty;
}
FalagardAnimateImage::FalagardAnimateImage(const String& type, const String& name)
    : FalagardStaticImage(type,name), d_animation(0), d_frameAlpha(1), d_start(0), d_play(true)
{
    CEGUI_START_ADD_STATICPROPERTY(FalagardAnimateImage)
        CEGUI_ADD_STATICPROPERTY(&animateProperty);
    CEGUI_END_ADD_STATICPROPERTY
    setFrameEnabled(false);
    setBackgroundEnabled(false);
}
void FalagardAnimateImage::setAnimate(const String& name)
{
    // Resolve first: an unknown resource must leave the previous animation intact.
    Animate* next = name.empty() ? 0 : const_cast<Animate*>(AnimateManager::getSingleton().getAnimate(name));
    d_animation = next;
    d_animationName = name;
    Play(d_play);
}
void FalagardAnimateImage::Play(bool play)
{
    d_play = play;
    d_start = static_cast<int>(System::getSingleton().getCurTimeElapsed()*1000.0f);
    updateSelf(0);
}
void FalagardAnimateImage::updateSelf(float elapsed)
{
    FalagardStaticImage::updateSelf(elapsed);
    const int now = static_cast<int>(System::getSingleton().getCurTimeElapsed()*1000.0f);
    const int age = now >= d_start ? now-d_start : 0;
    // CYS-PERF-FIX uiredraw: setImage/requestRedraw rebuild the whole GUI in CEGUI 0.4 and update() also runs for
    // hidden windows. Redraw only when the frame or its opacity changes, and only if the window can be seen
    // (showing a window redraws it anyway).
    const Image* cysFrame = d_animation && d_play ? d_animation->getFrame(age,-1) : 0;
    const float cysAlpha = d_animation && d_play ? d_animation->getFrameAlpha(age,-1) : 1;
    if (cysFrame != getImage() || cysAlpha != d_frameAlpha)
    {
        d_frameAlpha = cysAlpha;
        if (isVisible())
            setImage(cysFrame);
        else
            d_image.setImage(cysFrame);
    }
}
void FalagardAnimateImage::populateRenderCache()
{
    // Preserve the authored colours: animation opacity is a rendering multiplier.
    struct Restore { ColourRect& dest; ColourRect saved; ~Restore() { dest=saved; } } restore{d_imageCols,d_imageCols};
    d_imageCols.modulateAlpha(d_frameAlpha);
    FalagardStaticImage::populateRenderCache();
}
FalagardSafeIMEEditBox::FalagardSafeIMEEditBox(const String& type, const String& name)
    : FalagardIMEEditBox(type,name)
{
    setTextMasked(true);
    setCopyPasteDisabled(true);
}
}
