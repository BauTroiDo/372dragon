#include "FalagardMapImage.h"
#include "CEGUIPropertyHelper.h"
#include "CEGUIExceptions.h"
#include "CEGUILogger.h"
#include <cstdio>

namespace CEGUI
{
namespace {
class ChildImageProperty : public Property {
public:
    ChildImageProperty() : Property("ChildImage","Named image: name:KEY set:IMAGESET image:IMAGE.","") {}
    String get(const PropertyReceiver* r) const { return static_cast<const FalagardMapImage*>(r)->getChildImageDescriptor(); }
    void set(PropertyReceiver* r,const String& v) { static_cast<FalagardMapImage*>(r)->setChildImage(v); }
} childImageProperty;
class CurrentImageProperty : public Property {
public:
    CurrentImageProperty() : Property("SetCurrentImage","Select a named child image; unknown names clear the image.","None") {}
    String get(const PropertyReceiver* r) const { return static_cast<const FalagardMapImage*>(r)->getCurrentImage(); }
    void set(PropertyReceiver* r,const String& v) { static_cast<FalagardMapImage*>(r)->setCurrentImage(v); }
} currentImageProperty;
}

const utf8 FalagardMapImage::WidgetTypeName[]="Falagard/MapImage";

FalagardMapImage::FalagardMapImage(const String& type,const String& name)
    : FalagardStaticImage(type,name), d_currentKey("None")
{
    CEGUI_START_ADD_STATICPROPERTY(FalagardMapImage)
        CEGUI_ADD_STATICPROPERTY(&childImageProperty);
        CEGUI_ADD_STATICPROPERTY(&currentImageProperty);
    CEGUI_END_ADD_STATICPROPERTY
}

void FalagardMapImage::addChildImage(const String& key,const Image* image)
{
    if (key.empty()) throw InvalidRequestException("ChildImage key cannot be empty.");
    // B replaces this mapping without changing the currently displayed image.
    d_childImages[key]=image;
}

void FalagardMapImage::setChildImage(const String& descriptor)
{
    char key[128]={}, set[128]={}, imageName[128]={}, tail=0;
    if (sscanf(descriptor.c_str(),"name:%127s set:%127s image:%127s %c",key,set,imageName,&tail)!=3)
    {
        // CYS-CYGUI: a malformed or unresolvable ChildImage of the CY looks/layouts must not abort the window
        // that is being built (rule: log and skip, never throw - Timeline bay 8.2); the key stays unmapped.
        Logger::getSingleton().logEvent("MapImage: ChildImage '"+descriptor+
            "' ignored (expected 'name:KEY set:IMAGESET image:IMAGE').",Errors);
        return;
    }
    const Image* image=PropertyHelper::stringToImage(String("set:")+set+" image:"+imageName);
    if (!image)
    {
        Logger::getSingleton().logEvent("MapImage: ChildImage '"+descriptor+
            "' ignored (image not found in the imageset).",Errors);
        return;
    }
    addChildImage(key,image);
    d_childDescriptor=descriptor;
}

void FalagardMapImage::setCurrentImage(const String& key)
{
    const std::map<String,const Image*>::const_iterator item=d_childImages.find(key);
    d_currentKey=key;
    // B clears instead of preserving the previous picture for an unknown key.
    setImage(item==d_childImages.end() ? 0 : item->second);
    requestRedraw();
}

Window* FalagardMapImageFactory::createWindow(const String& name)
{
    return new FalagardMapImage(d_type,name);
}
void FalagardMapImageFactory::destroyWindow(Window* window)
{
    delete window;
}
}
