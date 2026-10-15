#include "CEGUISystem.h"
#include "CEGUIRenderer.h"
#include "CEGUITexture.h"
#include "CEGUIDefaultResourceProvider.h"
#include "CEGUIImagesetManager.h"
#include "CEGUIImageset.h"
#include "CEGUIWindowFactoryManager.h"
#include "CEGUIExceptions.h"
#include "FalagardLoginWidgets.h"
#include "FalSimpleText.h"
#include "CysUiInputAccess.h"
#include "CysUiFadeBinding.h"
#include "CysHostInput.h"
#include "CysCapsLockState.h"
#include <windows.h>
#include <cstdio>
#include <cmath>
#include <cstring>
#include <functional>
#include <limits>
#include <stdexcept>
#include <vector>
using namespace CEGUI;
static int passed=0,failed=0;
static void require(bool value,const char* message) { if(!value) throw std::runtime_error(message); }
static void test(const char* name,const std::function<void()>& function) {
    try {function();++passed;std::printf("PASS %s\n",name);}
    catch(const CEGUI::Exception& e){++failed;std::printf("FAIL %s: %s\n",name,e.getMessage().c_str());}
    catch(const std::exception& e){++failed;std::printf("FAIL %s: %s\n",name,e.what());}
}
struct MemoryTexture:Texture {
    MemoryTexture(Renderer* r,ushort size):Texture(r),size(size){}
    ushort size;
    ushort getWidth()const override{return size;} ushort getHeight()const override{return size;}
    void loadFromFile(const String&,const String&)override{throw std::runtime_error("unexpected texture file");}
    void loadFromMemory(const void*,uint w,uint)override{size=static_cast<ushort>(w);}
};
struct MemoryRenderer:Renderer {
    std::vector<ColourRect> colours;
    unsigned long addQuad(const Rect&,float,const Texture*,const Rect&,const ColourRect& c,QuadSplitMode,UserSharps)override{colours.push_back(c);return static_cast<unsigned long>(colours.size());}
    void adjustQuad(unsigned long,const Texture*,const Rect&,const ColourRect&)override{}
    void doRender()override{} void clearRenderList()override{colours.clear();} void setQueueingEnabled(bool)override{}
    Texture* createTexture()override{return new MemoryTexture(this,16);}
    Texture* createTexture(const String&,const String&)override{throw std::runtime_error("unexpected texture file");}
    Texture* createTexture(float size)override{return new MemoryTexture(this,static_cast<ushort>(size));}
    void destroyTexture(Texture* texture)override{delete texture;} void destroyAllTextures()override{}
    bool isQueueingEnabled()const override{return true;} float getWidth()const override{return 1024;}
    float getHeight()const override{return 768;} Size getSize()const override{return Size(1024,768);}
    Rect getRect()const override{return Rect(0,0,1024,768);} uint getMaxTextureSize()const override{return 2048;}
    uint getHorzScreenDPI()const override{return 96;} uint getVertScreenDPI()const override{return 96;}
};
struct SolidWindow:Window {
    const Image* image=nullptr;
    SolidWindow(const String& type,const String& name):Window(type,name){}
    void populateRenderCache()override{if(image)d_renderCache.cacheImage(*image,Rect(0,0,40,20),0,ColourRect(colour(1,1,1,getEffectiveAlpha())));}
};
struct SolidFactory:WindowFactory {
    SolidFactory():WindowFactory("Fixture/Fade"){}
    Window* createWindow(const String& name)override{return new SolidWindow(d_type,name);}
    void destroyWindow(Window* window)override{delete window;}
};
struct Vm {
    LuaPlus::LuaState* state=LuaPlus::LuaState::Create(true);
    ~Vm(){LuaPlus::LuaState::Destroy(state);}
    void run(const char* text){if(state->DoString(text)!=0)throw std::runtime_error(lua_tostring(state->GetCState(),-1));}
};
static const char* activeName(void*){return CysUiInputAccess::activeInputName();}
static int capsState(void*){return GetKeyState(VK_CAPITAL);}
static int fadeBinding(lua_State* state){return CysUiFadeBinding::startFade(state,*static_cast<Window*>(lua_touserdata(state,lua_upvalueindex(1))));}

int main() {
    setvbuf(stdout,nullptr,_IONBF,0);
    MemoryRenderer renderer;DefaultResourceProvider provider;System system(&renderer,&provider);
    auto& wm=WindowManager::getSingleton();auto& fm=WindowFactoryManager::getSingleton();
    fm.addFactory(new SolidFactory);fm.addFactory(new FalagardIMEEditBoxFactory);fm.addFactory(new FalagardSafeIMEEditBoxFactory);
    fm.addFactory(new FalagardSimpleTextFactory);
    auto* ordinary=wm.createWindow("Falagard/IMEEditBox","InputA");
    auto* masked=wm.createWindow("Falagard/SafeIMEEditBox","InputB");
    Vm vm;auto globals=vm.state->GetGlobals();CysHostInput::Services api;api.activeInputName=activeName;api.capsLockStatus=capsState;
    test("input globals register once and keep the existing functions",[&]{require(CysHostInput::Register(globals,api)==2,"missing globals");require(CysHostInput::Register(globals,api)==0,"existing globals replaced");});
    test("GetActiveInput returns an empty string without an active edit",[&]{vm.run("assert(type(GetActiveInput())=='string' and GetActiveInput()=='')");});
    test("GetActiveInput follows the actual native IME focus stack",[&]{Ime::SetActiveIMEEditBox(ordinary,true);vm.run("assert(GetActiveInput()=='InputA')");Ime::SetActiveIMEEditBox(masked,true);vm.run("assert(GetActiveInput()=='InputB')");Ime::SetActiveIMEEditBox(masked,false);vm.run("assert(GetActiveInput()=='InputA')");});
    test("host registration owns a copy of its service descriptor",[&]{api.activeInputName=nullptr;vm.run("assert(GetActiveInput()=='InputA')");});
    test("destroying active input removes it before dead pool deletion",[&]{Ime::SetActiveIMEEditBox(masked,true);wm.destroyWindow(masked);vm.run("assert(GetActiveInput()=='InputA')");wm.cleanDeadPool();vm.run("assert(GetActiveInput()=='InputA')");});
    test("destroying the last active edit cannot leave a dangling name",[&]{wm.destroyWindow(ordinary);wm.cleanDeadPool();vm.run("assert(GetActiveInput()=='')");});
    masked=wm.createWindow("Falagard/SafeIMEEditBox","RawInput");
    const String synthetic(reinterpret_cast<const utf8*>(u8"\u4e2d\u6587 Ti\u1ebfng Vi\u1ec7t"));masked->setText(synthetic);
    test("copying safe input returns raw UTF8 instead of mask glyphs",[&]{char out[128];int count=CysUiInputAccess::copyWindowTextUtf8("RawInput",out,sizeof(out));require(count==static_cast<int>(std::strlen(synthetic.c_str())) && std::strcmp(out,synthetic.c_str())==0,"raw input changed");});
    test("input copy rejects insufficient capacity without truncation",[&]{char out[4]={'x','x','x','x'};require(CysUiInputAccess::copyWindowTextUtf8("RawInput",out,sizeof(out))==-2 && out[0]==0 && out[3]=='x',"small buffer truncated or overwritten");});
    test("input copy requires a live editbox and writable capacity",[&]{auto* other=wm.createWindow("DefaultWindow","NotInput");char out[8]={'x'};require(CysUiInputAccess::copyWindowTextUtf8("Missing",out,8)==-1 && !out[0],"missing control accepted");require(CysUiInputAccess::copyWindowTextUtf8(other->getName().c_str(),out,8)==-1,"non-edit accepted");require(CysUiInputAccess::copyWindowTextUtf8("RawInput",nullptr,0)==-1,"null capacity accepted");});
    auto* label=wm.createWindow("Falagard/SimpleText","RoleNameLabel");label->setText(synthetic);
    test("SimpleText copy reads UTF8 from the real native label factory",[&]{
        require(dynamic_cast<FalagardSimpleText*>(label)!=nullptr,"fixture is not a native SimpleText");
        char out[128]={};const int count=CysUiInputAccess::copySimpleTextUtf8("RoleNameLabel",out,sizeof(out));
        require(count==static_cast<int>(std::strlen(synthetic.c_str())) && std::strcmp(out,synthetic.c_str())==0,"label UTF8 changed");
    });
    test("SimpleText copy requires capacity for the UTF8 bytes and terminator",[&]{
        const unsigned bytes=static_cast<unsigned>(std::strlen(synthetic.c_str()));
        std::vector<char> out(bytes+2,'x');
        require(CysUiInputAccess::copySimpleTextUtf8("RoleNameLabel",out.data(),bytes)==-2 && out[0]==0,"unterminated capacity accepted");
        for(unsigned i=1;i<out.size();++i)require(out[i]=='x',"short buffer was partially copied");
        require(CysUiInputAccess::copySimpleTextUtf8("RoleNameLabel",out.data(),bytes+1)==static_cast<int>(bytes) && std::strcmp(out.data(),synthetic.c_str())==0 && out[bytes+1]=='x',"exact capacity changed UTF8 or guard");
    });
    test("SimpleText copy accepts an empty label without borrowing input focus",[&]{
        label->setText("");char out[2]={'x','y'};
        require(CysUiInputAccess::copySimpleTextUtf8("RoleNameLabel",out,1)==0 && out[0]==0 && out[1]=='y',"empty label copy failed");
        label->setText(synthetic);
    });
    test("SimpleText copy rejects missing and wrong controls with empty output",[&]{
        for(const char* name:{"Missing","RawInput","NotInput"}){char out[4]={'x','x','x','x'};require(CysUiInputAccess::copySimpleTextUtf8(name,out,sizeof(out))==-1 && !out[0] && out[3]=='x',"wrong label control accepted or buffer corrupted");}
        char out[2]={'x','y'};require(CysUiInputAccess::copySimpleTextUtf8(nullptr,out,sizeof(out))==-1 && !out[0] && out[1]=='y',"null name accepted");
        out[0]='x';require(CysUiInputAccess::copySimpleTextUtf8("RoleNameLabel",out,0)==-1 && out[0]=='x',"zero capacity was written");
        require(CysUiInputAccess::copySimpleTextUtf8("RoleNameLabel",nullptr,1)==-1,"null output accepted");
    });
    test("input accessor still rejects a real SimpleText label",[&]{
        char out[8]={'x'};require(CysUiInputAccess::copyWindowTextUtf8("RoleNameLabel",out,sizeof(out))==-1 && !out[0],"input getter contract broadened");
    });
    test("window query exposes absolute pixel rectangle for a visible input",[&]{
        masked->setPosition(Absolute,Point(23,37));masked->setSize(Absolute,Size(120,24));
        float rect[4];require(CysUiInputAccess::getWindowRectUtf8("RawInput",rect)==1 && rect[0]==23 && rect[1]==37 && rect[2]==120 && rect[3]==24,"incorrect input rectangle");
    });
    test("window query excludes hidden ancestors and missing controls",[&]{
        auto* parent=wm.createWindow("DefaultWindow","InputParent");parent->addChildWindow(masked);parent->hide();
        float rect[4]={1,2,3,4};require(!CysUiInputAccess::getWindowRectUtf8("RawInput",rect) && !rect[0] && !rect[3],"hidden parent ignored");
        parent->show();require(CysUiInputAccess::getWindowRectUtf8("RawInput",rect)==1,"visible child unavailable");
        require(!CysUiInputAccess::getWindowRectUtf8("Missing",rect) && !CysUiInputAccess::getWindowRectUtf8(nullptr,rect) && !CysUiInputAccess::getWindowRectUtf8("RawInput",nullptr),"invalid query accepted");
    });
    test("missing input service reports Lua failure rather than fake state",[&]{Vm missing;auto g=missing.state->GetGlobals();CysHostInput::Register(g,CysHostInput::Services());missing.run("local ok=pcall(GetActiveInput);assert(not ok);ok=pcall(GetCaplockStatus);assert(not ok)");});
    test("CapsLock tracking ignores key-down bits and repeated samples",[&]{CysInput::CapsLockState tracker(0);require(!tracker.sample(0x8000) && tracker.sample(1) && !tracker.sample(0x8001) && tracker.sample(0) && !tracker.sample(0),"toggle events repeated or key-down used");});
    test("GetCaplockStatus reads Win32 thread keyboard toggle state",[&]{
        struct KeyboardState {BYTE saved[256];bool captured;KeyboardState():captured(GetKeyboardState(saved)!=FALSE){}~KeyboardState(){if(captured)SetKeyboardState(saved);}} original;
        require(original.captured,"thread keyboard state unavailable");BYTE changed[256];std::memcpy(changed,original.saved,256);
        changed[VK_CAPITAL]=0;require(SetKeyboardState(changed)!=FALSE,"cannot set thread keyboard state");vm.run("assert(type(GetCaplockStatus())=='number' and GetCaplockStatus()==0)");
        changed[VK_CAPITAL]=0x81;require(SetKeyboardState(changed)!=FALSE,"cannot set thread keyboard state");vm.run("assert(GetCaplockStatus()==1)");
    });
    auto* fading=static_cast<SolidWindow*>(wm.createWindow("Fixture/Fade","Fading"));fading->setSize(Absolute,Size(40,20));
    auto* atlas=ImagesetManager::getSingleton().createImageset("FadeFixture",renderer.createTexture());atlas->defineImage("Solid",Point(0,0),Size(16,16),Point(0,0));fading->image=&atlas->getImage("Solid");
    auto drawAlpha=[&](){renderer.clearRenderList();fading->requestRedraw();fading->render();require(renderer.colours.size()==1,"expected one native image quad");return renderer.colours[0].d_top_left.getAlpha();};
    auto nearly=[](float a,float b){return std::fabs(a-b)<.001f;};
    test("StartFade arms the transition without changing alpha early",[&]{fading->setAlpha(.8f);fading->startFade(0,1,.3f);require(nearly(fading->getAlpha(),.8f),"setter advanced fade");fading->update(0);require(nearly(drawAlpha(),0),"first update missed initial alpha");});
    test("native fade interpolates and changes the rendered quad alpha",[&]{fading->update(.15f);require(nearly(drawAlpha(),.5f),"midpoint alpha missing");fading->update(.15f);require(nearly(drawAlpha(),1),"target alpha missing");});
    test("large frame clamps to the target and does not keep animating",[&]{fading->startFade(1,0,.3f);fading->update(5);require(nearly(drawAlpha(),0),"overshoot missed target");fading->setAlpha(.4f);fading->update(5);require(nearly(drawAlpha(),.4f),"finished fade kept overwriting alpha");});
    test("restarting fade uses the new endpoints and resets elapsed time",[&]{fading->startFade(0,1,1);fading->update(.5f);fading->startFade(1,.2f,1);fading->update(.25f);require(nearly(drawAlpha(),.8f),"restart retained old time");});
    test("fade clamps alpha endpoints and handles zero or negative duration",[&]{fading->startFade(-1,2,0);fading->update(0);require(nearly(drawAlpha(),1),"zero duration produced invalid alpha");fading->startFade(2,-1,-.5f);fading->update(0);require(nearly(drawAlpha(),0),"negative duration not clamped");});
    test("hidden fade pauses and resumes without changing visibility",[&]{fading->startFade(0,1,1);fading->update(.2f);fading->hide();fading->update(.5f);require(!fading->isVisible() && nearly(fading->getAlpha(),.2f),"hidden fade advanced or showed window");fading->show();fading->update(.2f);require(nearly(drawAlpha(),.4f),"resume lost elapsed time");});
    test("fade rejects nonfinite arguments atomically",[&]{fading->startFade(0,1,1);bool rejected=false;try{fading->startFade(0,1,std::numeric_limits<float>::infinity());}catch(const InvalidRequestException&){rejected=true;}fading->update(.25f);require(rejected && nearly(drawAlpha(),.25f),"invalid duration changed transition");});
    lua_State* raw=vm.state->GetCState();lua_pushlightuserdata(raw,fading);lua_pushcclosure(raw,fadeBinding,1);lua_setglobal(raw,"NativeFade");
    test("GL Lua fade binding accepts exactly numeric argument slots",[&]{vm.run("NativeFade(nil,0,1,0.3)");fading->update(.15f);require(nearly(drawAlpha(),.5f),"Lua numeric fade not connected");vm.run("NativeFade(nil,'1',0,0.3);NativeFade(nil,1,false,0.3);NativeFade(nil,1,0)");fading->update(.15f);require(nearly(drawAlpha(),1),"invalid Lua values altered fade");});
    test("destroying a fading window leaves no update callback",[&]{fading->startFade(0,1,5);wm.destroyWindow(fading);wm.cleanDeadPool();auto* survivor=wm.createWindow("DefaultWindow","Survivor");survivor->update(10);require(survivor->getAlpha()==1,"destroyed fade leaked state");});
    wm.destroyAllWindows();wm.cleanDeadPool();
    std::printf("RESULT passed=%d failed=%d\n",passed,failed);return failed?1:0;
}
