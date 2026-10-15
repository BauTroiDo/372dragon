#pragma once
#include "FalSimpleText.h"
#include <map>
#include <vector>

namespace CEGUI {
// CYS: chat speaker text, three-part background and animated star emitter.
class FALAGARDBASE_API FalagardStar : public FalagardSimpleText {
public:
    static const utf8 WidgetTypeName[];
    FalagardStar(const String& type, const String& name);
    void setSetting(const String& name, const String& value);
    String getSetting(const String& name) const;
    void updateSelf(float elapsed) override;
protected:
    void populateRenderCache() override;
    void onShown(WindowEventArgs& e) override;
    void onMouseButtonDown(MouseEventArgs& e) override;
private:
    struct Range { float low, high; };
    struct Star { float x, y, vx, vy, ax, ay, size, sizeSpeed, age, life; };
    std::map<String, String> settings_;
    std::map<String, Range> ranges_;
    std::vector<Star> stars_;
    const Image *left_ = 0, *middle_ = 0, *right_ = 0;
    String animation_, builderAnimation_, speaker_;
    Point start_, end_;
    Size builderSize_, animationSize_;
    float life_ = 30000, builderLife_ = 3000, age_ = 0, debt_ = 0;
    int number_ = 100, tailNumber_ = 100;
    bool relative_ = false, clip_ = true, tail_ = false;
    unsigned random_ = 0x12345678;
    float sample(const String& key);
    void reset();
};
class FALAGARDBASE_API FalagardStarFactory : public WindowFactory {
public:
    FalagardStarFactory() : WindowFactory(FalagardStar::WidgetTypeName) {}
    Window* createWindow(const String& name) override { return new FalagardStar(d_type, name); }
    void destroyWindow(Window* window) override { delete window; }
};
}
