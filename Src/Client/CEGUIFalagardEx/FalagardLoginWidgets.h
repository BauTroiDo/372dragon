#pragma once
#include "FalStaticImage.h"
#include "FalIMEEditBox.h"
#include "FalagardAnimate.h"

namespace CEGUI {
// CYS: modern layout controls, using the native image, button and IME paths.
class FALAGARDBASE_API FalagardAnimateImage : public FalagardStaticImage, public IFalagardAnimate {
public:
    static const utf8 WidgetTypeName[];
    FalagardAnimateImage(const String& type, const String& name);
    void setAnimate(const String& name);
    const String& getAnimate() const { return d_animationName; }
    void Play(bool play) override;
    void updateSelf(float elapsed) override;
protected:
    void populateRenderCache() override;
private:
    String d_animationName;
    Animate* d_animation;
    float d_frameAlpha;
    int d_start;
    bool d_play;
};
class FALAGARDBASE_API FalagardAnimateButton : public FalagardAnimate {
public:
    static const utf8 WidgetTypeName[];
    FalagardAnimateButton(const String& type, const String& name) : FalagardAnimate(type,name) {}
};
class FALAGARDBASE_API FalagardSafeIMEEditBox : public FalagardIMEEditBox {
public:
    static const utf8 WidgetTypeName[];
    FalagardSafeIMEEditBox(const String& type, const String& name);
};
#define CYS_LOGIN_FACTORY(Type) \
class FALAGARDBASE_API Type##Factory : public WindowFactory { \
public: Type##Factory() : WindowFactory(Type::WidgetTypeName) {} \
    Window* createWindow(const String& name) override { return new Type(d_type,name); } \
    void destroyWindow(Window* window) override { delete window; } \
};
CYS_LOGIN_FACTORY(FalagardAnimateImage)
CYS_LOGIN_FACTORY(FalagardAnimateButton)
CYS_LOGIN_FACTORY(FalagardSafeIMEEditBox)
#undef CYS_LOGIN_FACTORY
}
