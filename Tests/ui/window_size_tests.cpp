#define NOMINMAX
#define _SILENCE_STDEXT_HASH_DEPRECATION_WARNINGS
#include <windows.h>
#include "CEGUISystem.h"
#include "CEGUIRenderer.h"
#include "CEGUITexture.h"
#include "CEGUIDefaultResourceProvider.h"
#include "CEGUIWindowFactoryManager.h"
#include "CEGUIWindowManager.h"
#include "CEGUIExceptions.h"
#include "CEGUIPropertyHelper.h"
#include "FalagardSelfFitWindow.h"
#include "UILuaControl.h"
#include <cstdio>
#include <cmath>
#include <fstream>
#include <functional>
#include <iterator>
#include <memory>
#include <stdexcept>
#include <vector>
using namespace CEGUI;
// Fixture owns only the metatable storage; the tested method is the production inline member.
LuaPlus::LuaObject* LUA_CONTROL::Window::s_pMetaTable = nullptr;
static int passed=0,failed=0;
static void require(bool value,const char* message){if(!value)throw std::runtime_error(message);}
static void test(const char* name,const std::function<void()>& fn){
    try{fn();++passed;std::printf("PASS %s\n",name);}
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


// B reads stored native float dimensions directly; this fixture isolates its conversion
// from CEGUI's normal UDim-to-pixel rounding during setSize.
struct FractionalWindow: CEGUI::Window {
    FractionalWindow():CEGUI::Window("DefaultWindow","FractionalNative") { d_pixelSize=Size(137.875f,53.75f); }
};
struct Vm {
    LuaPlus::LuaState* state=LuaPlus::LuaState::Create(true);
    ~Vm(){LuaPlus::LuaState::Destroy(state);}
    void run(const char* source){if(state->DoString(source)!=0)throw std::runtime_error(lua_tostring(state->GetCState(),-1));}
};
struct BoundWindow: LUA_CONTROL::Window {
    explicit BoundWindow(CEGUI::Window* window):LUA_CONTROL::Window(window){}
    int property(LuaPlus::LuaState* state){LuaPlus::LuaStack args(state);m_pWindow->setProperty(args[2].GetString(),args[3].GetString());return 0;}
    int text(LuaPlus::LuaState* state){LuaPlus::LuaStack args(state);m_pWindow->setText(args[2].GetString());return 0;}
    int hide(LuaPlus::LuaState*){m_pWindow->hide();return 0;}
};
int main(int argc,char** argv){
    setvbuf(stdout,nullptr,_IONBF,0);
    require(argc==2,"Canonical InterfaceFolder argument required");
    MemoryRenderer renderer;DefaultResourceProvider provider;System system(&renderer,&provider);
    auto& wm=WindowManager::getSingleton();
    auto* parent=wm.createWindow("DefaultWindow","SizeParent");parent->setSize(Absolute,Size(400,240));system.setGUISheet(parent);
    auto* window=wm.createWindow("DefaultWindow","Measured");parent->addChildWindow(window);
    FractionalWindow fractional;
    Vm vm;
    std::vector<std::unique_ptr<BoundWindow>> controls;
    {
        auto globals=vm.state->GetGlobals();auto meta=globals.CreateTable("SizeMeta");meta.SetObject("__index",meta);
        meta.RegisterObjectFunctor("GetWindowSize",&LUA_CONTROL::Window::GetWindowSize);
        meta.RegisterObjectFunctor("Show",&LUA_CONTROL::Window::Show);
        meta.RegisterObjectFunctor("IsVisible",&LUA_CONTROL::Window::IsVisible);
        meta.RegisterObjectFunctor("SetProperty",&BoundWindow::property);
        meta.RegisterObjectFunctor("SetText",&BoundWindow::text);
        meta.RegisterObjectFunctor("Hide",&BoundWindow::hide);
        auto bind=[&](const char* name,CEGUI::Window* native){
            controls.emplace_back(new BoundWindow(native));
            LuaPlus::LuaObject box=vm.state->BoxPointer(controls.back().get());box.SetMetaTable(meta);globals.SetObject(name,box);
        };
        bind("Measured",window);bind("Fractional",&fractional);
        test("Lua returns exactly two integer-valued numbers in width-height order",[&]{window->setSize(Absolute,Size(137,53));vm.run("local t={Measured:GetWindowSize()};assert(table.getn(t)==2 and type(t[1])=='number' and type(t[2])=='number' and t[1]==137 and t[2]==53)");});
        test("getter observes native pixel alignment performed by setSize",[&]{window->setSize(Absolute,Size(137.875f,53.75f));require(window->getAbsoluteWidth()==138 && window->getAbsoluteHeight()==54,"native alignment changed");vm.run("local w,h=Measured:GetWindowSize();assert(w==138 and h==54)");});
        test("stored fractional native dimensions truncate instead of round",[&]{vm.run("local w,h=Fractional:GetWindowSize();assert(w==137 and h==53)");});
        test("relative metrics return constrained absolute pixels",[&]{window->setMetricsMode(Relative);window->setSize(Relative,Size(.5f,.25f));vm.run("local w,h=Measured:GetWindowSize();assert(w==200 and h==60)");});
        test("parent resize is reflected without caching",[&]{parent->setSize(Absolute,Size(640,320));vm.run("local w,h=Measured:GetWindowSize();assert(w==320 and h==80)");});
        test("native min and max constraints determine reported size",[&]{window->setProperty("UnifiedMinSize","{{0,20},{0,25}}");window->setProperty("UnifiedMaxSize","{{0,120},{0,90}}");window->setSize(Absolute,Size(999,1));vm.run("local w,h=Measured:GetWindowSize();assert(w==120 and h==25)");});
        test("hidden windows retain measured size and visibility",[&]{window->hide();vm.run("local w,h=Measured:GetWindowSize();assert(w==120 and h==25 and not Measured:IsVisible())");});
        test("zero size and unused arguments preserve the two-result contract",[&]{window->setProperty("UnifiedMinSize","{{0,0},{0,0}}");window->setSize(Absolute,Size(0,0));vm.run("local w,h,extra=Measured:GetWindowSize('ignored',false);assert(w==0 and h==0 and extra==nil)");});
        WindowFactoryManager::getSingleton().addFactory(new FalagardSelfFitFactory);
        auto* frame=wm.createWindow("DefaultWindow","SelectServerQuest_Frame");parent->addChildWindow(frame);frame->setSize(Absolute,Size(640,320));
        auto* sub=wm.createWindow("DefaultWindow","SelectServerQuest_Frame_sub");frame->addChildWindow(sub);sub->setSize(Absolute,Size(346,128));
        auto* info=static_cast<FalagardSelfFitWindow*>(wm.createWindow("Falagard/SelfFitWindow","SelectServerQuest_InfoWindow"));sub->addChildWindow(info);info->setMinHeight(25);
        bind("this",frame);bind("SelectServerQuest_Frame_sub",sub);bind("SelectServerQuest_InfoWindow",info);
        for(const char* name:{"SelectServerQuest_Button1","SelectServerQuest_Button2","SelectServerQuest_Time_Text","SelectServerQuest_LostPassword"}){auto* item=wm.createWindow("DefaultWindow",name);sub->addChildWindow(item);bind(name,item);}
        std::ifstream input(std::string(argv[1])+"/SelectServerQuest/SelectServerQuest.lua",std::ios::binary);require(bool(input),"actual SelectServerQuest.lua unavailable");
        std::string script((std::istreambuf_iterator<char>(input)),std::istreambuf_iterator<char>());if(script.compare(0,3,"\xef\xbb\xbf")==0)script.erase(0,3);vm.run(script.c_str());
        vm.run("AxTrace=function() end;arg0='Connecting to the test server...';arg1=nil");
        frame->hide();
        test("actual no-button handler stops before Show when GetWindowSize is absent",[&]{meta.SetNil("GetWindowSize");vm.run("local ok,err=pcall(LoginSelectServerQuest_OnEvent,'GAMELOGIN_SHOW_SYSTEM_INFO_NO_BUTTON');assert(not ok and string.find(err,'GetWindowSize'))");require(!frame->isVisible(),"missing method did not reproduce hidden dialog");});
        meta.RegisterObjectFunctor("GetWindowSize",&LUA_CONTROL::Window::GetWindowSize);
        test("actual no-button handler uses fitted native height and shows a 73px dialog",[&]{vm.run("LoginSelectServerQuest_OnEvent('GAMELOGIN_SHOW_SYSTEM_INFO_NO_BUTTON')");require(frame->isVisible() && info->getAbsoluteHeight()==25 && sub->getAbsoluteHeight()==73,"actual script did not size or show wait dialog");require(!wm.getWindow("SelectServerQuest_Button1")->isVisible() && !wm.getWindow("SelectServerQuest_Button2")->isVisible(),"wait dialog displayed buttons");});
        test("actual dialog resizes from changed native content height",[&]{info->setMinHeight(63);vm.run("LoginSelectUpdateRect()");require(sub->getAbsoluteHeight()==111,"script did not add 48 to changed native height");});
    }
    controls.clear();system.setGUISheet(nullptr);wm.destroyAllWindows();wm.cleanDeadPool();
    std::printf("RESULT passed=%d failed=%d\n",passed,failed);return failed?1:0;
}
