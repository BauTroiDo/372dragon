#include "FalagardStar.h"
#include "CEGUIPropertyHelper.h"
#include "CEGUIExceptions.h"
#include "CEGUIAnimateManager.h"
#include "CEGUIAnimate.h"
#include "CEGUIImage.h"
#include <algorithm>
#include <cmath>
#include <cstdio>

namespace CEGUI {
const utf8 FalagardStar::WidgetTypeName[] = "Falagard/Star";
namespace {
class StarProperty : public Property {
public:
    StarProperty(const char* name) : Property(name, "Chat speaker star setting.", "") {}
    String get(const PropertyReceiver* r) const override { return static_cast<const FalagardStar*>(r)->getSetting(getName()); }
    void set(PropertyReceiver* r, const String& v) override { static_cast<FalagardStar*>(r)->setSetting(getName(), v); }
};
StarProperty element("StarElement"), builder("StarBuilder"), life("Life"), resetProp("Reset"), speaker("Name"), left("BackgroundLeft"), middle("Background"), right("BackgroundRight");
float number(const String& value) {
    float n = 0; int end = 0;
    if (sscanf(value.c_str(), "%f%n", &n, &end) != 1 || end != value.length() || !std::isfinite(n))
        throw InvalidRequestException("Star: invalid number");
    return n;
}
bool boolean(const String& value) {
    if (value == "true" || value == "True") return true;
    if (value == "false" || value == "False") return false;
    throw InvalidRequestException("Star: invalid boolean");
}
void pair(const String& value, const char* format, float& a, float& b) {
    int end = 0;
    if (sscanf(value.c_str(), format, &a, &b, &end) != 2 || end != value.length() || !std::isfinite(a) || !std::isfinite(b))
        throw InvalidRequestException("Star: invalid pair");
}
const Image* frame(const String& name, float age) {
    AnimateManager* manager = AnimateManager::getSingletonPtr();
    if (!manager || name.empty() || !manager->isAnimatePresent(name)) return 0;
    return manager->getAnimate(name)->getFrame(static_cast<int>(age), -1);
}
}
FalagardStar::FalagardStar(const String& type, const String& name) : FalagardSimpleText(type, name) {
    CEGUI_START_ADD_STATICPROPERTY(FalagardStar)
        CEGUI_ADD_STATICPROPERTY(&element); CEGUI_ADD_STATICPROPERTY(&builder);
        CEGUI_ADD_STATICPROPERTY(&life); CEGUI_ADD_STATICPROPERTY(&resetProp);
        CEGUI_ADD_STATICPROPERTY(&speaker); CEGUI_ADD_STATICPROPERTY(&left);
        CEGUI_ADD_STATICPROPERTY(&middle); CEGUI_ADD_STATICPROPERTY(&right);
    CEGUI_END_ADD_STATICPROPERTY
    addEvent("NameLClick"); addEvent("NameRClick");
    ranges_["Size"] = {20,20}; ranges_["SizeScale"] = {1,1};
    ranges_["SpeedXScale"] = {0,0}; ranges_["SpeedYScale"] = {0,0};
    ranges_["AccelerateXScale"] = {0,0}; ranges_["AccelerateYScale"] = {0,0};
    ranges_["SizeSpeed"] = {0,0}; ranges_["MaxLife"] = {500,500};
}
String FalagardStar::getSetting(const String& name) const {
    const auto i = settings_.find(name); return i == settings_.end() ? String("") : i->second;
}
void FalagardStar::reset() { age_ = debt_ = 0; stars_.clear(); requestRedraw(); }
void FalagardStar::setSetting(const String& name, const String& value) {
    if (name == "BackgroundLeft") left_ = PropertyHelper::stringToImage(value);
    else if (name == "Background") middle_ = PropertyHelper::stringToImage(value);
    else if (name == "BackgroundRight") right_ = PropertyHelper::stringToImage(value);
    else if (name == "Name") speaker_ = value;
    else if (name == "Reset") reset();
    else if (name == "Life") {
        const float v = number(value); if (v <= 0) throw InvalidRequestException("Star: Life must be positive"); life_ = v;
    } else {
        if (value.substr(0,4) != "key:") throw InvalidRequestException("Star: expected key/value");
        const size_t cut = value.find(" value:");
        if (cut == String::npos) throw InvalidRequestException("Star: expected value");
        const String key = value.substr(4,cut-4), val = value.substr(cut+7);
        if (name == "StarElement") {
            if (key == "Animate") animation_ = val;
            else {
                auto i = ranges_.find(key);
                if (i == ranges_.end()) throw InvalidRequestException("Star: unknown element key '"+key+"'");
                Range r; pair(val,"min:%f,max:%f%n",r.low,r.high);
                if (r.low > r.high || ((key=="MaxLife" || key=="Size" || key=="SizeScale") && r.low <= 0))
                    throw InvalidRequestException("Star: invalid element range");
                i->second = r;
            }
        } else if (name == "StarBuilder") {
            if (key == "MetricsMode") { if (val!="Absolute" && val!="Relative") throw InvalidRequestException("Star: invalid metrics"); relative_ = val=="Relative"; }
            else if (key == "StartPos") pair(val,"x:%f,y:%f%n",start_.d_x,start_.d_y);
            else if (key == "EndPos") pair(val,"x:%f,y:%f%n",end_.d_x,end_.d_y);
            else if (key == "BuilderSize") pair(val,"w:%f,h:%f%n",builderSize_.d_width,builderSize_.d_height);
            else if (key == "AnimateSize") pair(val,"w:%f,h:%f%n",animationSize_.d_width,animationSize_.d_height);
            else if (key == "Animate") builderAnimation_ = val;
            else if (key == "Life") { const float v=number(val); if(v<=0) throw InvalidRequestException("Star: invalid builder life"); builderLife_=v; }
            else if (key == "Number" || key == "TailNumber") {
                const float n=number(val); if(n<0 || n>4096 || n!=floor(n)) throw InvalidRequestException("Star: invalid count");
                (key=="Number" ? number_ : tailNumber_) = static_cast<int>(n);
            } else if (key == "ClipperOpen") clip_=boolean(val);
            else if (key == "TailOpen") tail_=boolean(val);
            else throw InvalidRequestException("Star: unknown builder key '"+key+"'");
        } else throw InvalidRequestException("Star: unknown property");
    }
    settings_[name]=value; requestRedraw();
}
float FalagardStar::sample(const String& key) {
    random_ ^= random_ << 13; random_ ^= random_ >> 17; random_ ^= random_ << 5;
    const Range& r=ranges_[key]; return r.low+(r.high-r.low)*float(random_ & 0xffff)/65535.0f;
}
void FalagardStar::onShown(WindowEventArgs& e) { reset(); FalagardSimpleText::onShown(e); }
void FalagardStar::onMouseButtonDown(MouseEventArgs& e) {
    FalagardSimpleText::onMouseButtonDown(e);
    if (!speaker_.empty()) {
        if(e.button==LeftButton) fireEvent("NameLClick",e);
        else if(e.button==RightButton) fireEvent("NameRClick",e);
    }
}
void FalagardStar::updateSelf(float elapsed) {
    FalagardSimpleText::updateSelf(elapsed);
    if (!isVisible() || !std::isfinite(elapsed) || elapsed<=0 || age_>=life_) return;
    const float ms=elapsed*1000.0f; age_+=ms;
    for(auto& s:stars_) { s.age+=ms; s.vx+=s.ax*elapsed; s.vy+=s.ay*elapsed; s.x+=s.vx*elapsed; s.y+=s.vy*elapsed; s.size+=s.sizeSpeed*elapsed; }
    stars_.erase(std::remove_if(stars_.begin(),stars_.end(),[](const Star& s){return s.age>=s.life || s.size<=0;}),stars_.end());
    if(age_<life_) {
        const int count=tail_ ? tailNumber_ : number_;
        debt_+=ms*count/builderLife_;
        const float f=std::fmod(age_,builderLife_)/builderLife_;
        const Size area=getAbsoluteSize();
        const float x=(start_.d_x+(end_.d_x-start_.d_x)*f)*(relative_?area.d_width:1);
        const float y=(start_.d_y+(end_.d_y-start_.d_y)*f)*(relative_?area.d_height:1);
        const int spawn=std::min(4096-static_cast<int>(stars_.size()),static_cast<int>(std::min(debt_,4096.0f)));
        for(int i=0;i<spawn;++i) {
            Star s={}; const float spread=float(i+1)/(spawn+1)-.5f;
            s.x=x+spread*builderSize_.d_width; s.y=y+spread*builderSize_.d_height;
            s.vx=sample("SpeedXScale"); s.vy=sample("SpeedYScale"); s.ax=sample("AccelerateXScale"); s.ay=sample("AccelerateYScale");
            s.size=sample("Size")*sample("SizeScale"); s.sizeSpeed=sample("SizeSpeed"); s.life=sample("MaxLife");
            stars_.push_back(s);
        }
        debt_=std::fmod(debt_,1.0f);
    } else stars_.clear();
    requestRedraw();
}
void FalagardStar::populateRenderCache() {
    if(age_>=life_) return;
    const Size area=getAbsoluteSize(); const Rect clip(Point(0,0),area);
    const ColourRect colours(CEGUI::colour(1,1,1,getEffectiveAlpha()));
    const float lw=left_?left_->getWidth():0, rw=right_?right_->getWidth():0;
    if(middle_) d_renderCache.cacheImage(*middle_,Rect(lw,0,std::max(lw,area.d_width-rw),area.d_height),0,colours);
    if(left_) d_renderCache.cacheImage(*left_,Rect(0,0,lw,area.d_height),0,colours);
    if(right_) d_renderCache.cacheImage(*right_,Rect(area.d_width-rw,0,area.d_width,area.d_height),0,colours);
    for(const auto& s:stars_) {
        const Image* image=frame(animation_,s.age); if(!image) continue;
        ColourRect tint(colours); tint.setAlpha(getEffectiveAlpha()*(1-s.age/s.life));
        d_renderCache.cacheImage(*image,Rect(s.x-s.size/2,s.y-s.size/2,s.x+s.size/2,s.y+s.size/2),0,tint,clip_?&clip:0,!clip_);
    }
    if(const Image* image=frame(builderAnimation_,age_)) {
        const float f=std::fmod(age_,builderLife_)/builderLife_;
        const Point p(start_.d_x+(end_.d_x-start_.d_x)*f,start_.d_y+(end_.d_y-start_.d_y)*f);
        d_renderCache.cacheImage(*image,Rect(p,animationSize_),0,colours,clip_?&clip:0,!clip_);
    }
    populateTextRenderCache(); // bubble artwork was already drawn above
}
}
