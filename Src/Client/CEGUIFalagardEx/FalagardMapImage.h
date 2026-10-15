#ifndef CYS_FALAGARD_MAP_IMAGE_H
#define CYS_FALAGARD_MAP_IMAGE_H

#include "FalStaticImage.h"
#include "CEGUIWindowFactory.h"
#include <map>

namespace CEGUI
{
class FALAGARDBASE_API FalagardMapImage : public FalagardStaticImage
{
public:
    static const utf8 WidgetTypeName[];
    FalagardMapImage(const String& type,const String& name);
    void addChildImage(const String& key,const Image* image);
    void setChildImage(const String& descriptor);
    const String& getChildImageDescriptor() const { return d_childDescriptor; }
    void setCurrentImage(const String& key);
    const String& getCurrentImage() const { return d_currentKey; }
protected:
    bool testClassName_impl(const String& name) const {
        return name=="FalagardMapImage" || FalagardStaticImage::testClassName_impl(name);
    }
private:
    std::map<String,const Image*> d_childImages;
    String d_childDescriptor;
    String d_currentKey;
};

class FALAGARDBASE_API FalagardMapImageFactory : public WindowFactory
{
public:
    FalagardMapImageFactory() : WindowFactory(FalagardMapImage::WidgetTypeName) {}
    Window* createWindow(const String& name);
    void destroyWindow(Window* window);
};
}
#endif
