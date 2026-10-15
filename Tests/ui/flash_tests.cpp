#include "CEGUISystem.h"
#include "CEGUIRenderer.h"
#include "CEGUITexture.h"
#include "CEGUIDefaultResourceProvider.h"
#include "CEGUIWindowFactoryManager.h"
#include "CEGUIWindowManager.h"
#include "CEGUIImagesetManager.h"
#include "CEGUIImageset.h"
#include "CEGUIAnimateManager.h"
#include "CEGUIAnimate.h"
#include "CEGUIExceptions.h"
#include "CEGUIPropertyHelper.h"
#include "FalagardCheckButton.h"
#include "CysFlashBinding.h"
#include <cstdio>
#include <cmath>
#include <cstring>
#include <fstream>
#include <functional>
#include <iterator>
#include <stdexcept>
#include <vector>
using namespace CEGUI;
static int passed=0,failed=0;
static void require(bool v,const char* msg){if(!v)throw std::runtime_error(msg);}
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

struct Vm {
    LuaPlus::LuaState* state=LuaPlus::LuaState::Create(true);
    ~Vm(){LuaPlus::LuaState::Destroy(state);}
    void run(const char* s){if(state->DoString(s)!=0)throw std::runtime_error(lua_tostring(state->GetCState(),-1));}
};
static void setField(lua_State* s,int index,const char* key){lua_pushstring(s,key);lua_insert(s,-2);lua_settable(s,index<0?index-1:index);}
static Window* receiver(lua_State* s){return *static_cast<Window**>(lua_touserdata(s,1));}
static int flash(lua_State* s){return CysFlashBinding::flashMe(s,*receiver(s));}
static int selected(lua_State* s){if(lua_type(s,2)==LUA_TNUMBER)receiver(s)->setProperty("Selected",lua_tonumber(s,2)==1?"True":"False");return 0;}
static int hide(lua_State* s){static_cast<Window*>(lua_touserdata(s,lua_upvalueindex(1)))->hide();return 0;}
static void box(lua_State* s,Window* window,const char* name){
    *static_cast<Window**>(lua_newuserdata(s,sizeof(Window*)))=window;
    lua_getglobal(s,"CheckboxMeta");lua_setmetatable(s,-2);lua_setglobal(s,name);
}
int main(int argc,char** argv){
    setvbuf(stdout,nullptr,_IONBF,0);
    require(argc==2,"Canonical InterfaceFolder argument required");
    MemoryRenderer renderer;DefaultResourceProvider provider;System system(&renderer,&provider);
    std::ofstream("flash-empty.animate",std::ios::binary)<<"<AnimateManager/>";
    AnimateManager animations("flash-empty.animate");
    auto& wm=WindowManager::getSingleton();auto& fm=WindowFactoryManager::getSingleton();
    fm.addFactory(new FalagardButtonFactory);fm.addFactory(new FalagardCheckButtonFactory);
    auto* atlas=ImagesetManager::getSingleton().createImageset("FlashFixture",renderer.createTexture());
    atlas->defineImage("Solid",Point(0,0),Size(16,16),Point(0,0));
    RenderableImage image;image.setImage(&atlas->getImage("Solid"));image.setRect(Rect(0,0,40,20));
    auto make=[&](const char* name){
        auto* b=static_cast<FalagardCheckButton*>(wm.createWindow("Falagard/CheckBox",name));
        b->setSize(Absolute,Size(40,20));b->setCheck(false);b->setStandardImageryEnabled(false);
        b->setNormalImage(&image);b->setHoverImage(&image);b->setPushedImage(&image);b->setDisabledImage(&image);return b;
    };
    auto* button=make("Pulse");
    auto draw=[&](Window* w){renderer.clearRenderList();w->requestRedraw();w->render();require(renderer.colours.size()==1,"expected one actual native image quad");return renderer.colours[0].d_top_left.getAlpha();};
    auto near=[](float a,float b){return std::fabs(a-b)<.001f;};
    test("Flash property is inherited by CheckBox and starts disabled",[&]{require(button->getProperty("Flash")=="0" && near(draw(button),1),"default Flash mismatch");});
    test("enabling Flash waits for update and first frame starts at zero",[&]{button->setProperty("Flash","1");require(near(draw(button),1),"setter advanced alpha");button->update(.1f);require(near(draw(button),0),"initial decreasing phase not clamped");});
    test("Flash rises over 0.6 seconds and affects rendered glyph-independent alpha",[&]{button->update(.3f);require(near(draw(button),.5f),"pulse midpoint not rendered");button->update(.3f);require(near(draw(button),1),"pulse peak not rendered");});
    test("Flash descends and large ticks clamp one endpoint",[&]{button->update(.3f);require(near(draw(button),.5f),"descending midpoint wrong");button->update(10);require(near(draw(button),0),"large tick wrapped or overshot");button->update(.15f);require(near(draw(button),.25f),"clamped phase did not reverse");});
    test("setting Flash again preserves phase and direction",[&]{button->setProperty("Flash","1");button->update(.15f);require(near(draw(button),.5f),"setter reset active phase");});
    test("hidden windows pause Flash and remain hidden",[&]{button->hide();button->update(.4f);require(!button->isVisible() && near(button->getAlpha(),.5f),"hidden phase advanced");button->show();button->update(.15f);require(near(draw(button),.75f),"hidden phase reset");});
    test("disabling Flash restores full alpha on the next visible update",[&]{button->setProperty("Flash","0");require(near(draw(button),.75f),"setter changed alpha early");button->update(0);require(near(draw(button),1),"disabled pulse retained transparency");});
    test("nonzero integer property resumes its previous phase",[&]{button->setProperty("Flash","-3");require(button->getProperty("Flash")=="-3","integer property narrowed");button->update(.15f);require(near(draw(button),1),"phase was reset while disabled");button->update(.3f);require(near(draw(button),.5f),"nonzero property failed to pulse");});
    test("BtnAnimation takes precedence and pauses Flash phase",[&]{auto* a=animations.createAnimate("FlashOverlay",918,true,200,false,0);a->defineAnimateKey(&atlas->getImage("Solid"));button->setBtnAnimation("FlashOverlay");button->enableAnimate(true);button->setAlpha(.8f);button->update(.2f);require(near(button->getAlpha(),.8f),"Flash overwrote animation alpha");button->enableAnimate(false);button->update(.15f);require(near(draw(button),.25f),"animation advanced flash phase");});
    test("Window StartFade remains ordered after button Flash",[&]{button->setProperty("Flash","0");button->startFade(0,1,1);button->update(.5f);require(near(draw(button),.5f),"button alpha overrode later native fade");button->update(.5f);require(near(draw(button),1),"fade endpoint missing");});
    Vm vm;lua_State* lua=vm.state->GetCState();vm.run("CheckboxMeta={};CheckboxMeta.__index=CheckboxMeta");
    lua_getglobal(lua,"CheckboxMeta");lua_pushcfunction(lua,selected);setField(lua,-2,"SetCheck");lua_pop(lua,1);
    box(lua,button,"Pulse");
    lua_getglobal(lua,"CheckboxMeta");lua_pushcfunction(lua,flash);setField(lua,-2,"FlashMe");lua_pop(lua,1);
    test("Lua FlashMe returns no values and truncates actual numbers like B",[&]{vm.run("assert((function(...) return arg.n end)(Pulse:FlashMe(1.9))==0)");require(button->getFlash()==1,"fraction did not truncate to one");vm.run("Pulse:FlashMe(2)");require(button->getFlash()==0,"two treated as enabled");vm.run("Pulse:FlashMe(-1)");require(button->getFlash()==0,"negative treated as enabled");});
    test("Lua FlashMe ignores nonnumbers without changing property",[&]{vm.run("Pulse:FlashMe(1);Pulse:FlashMe('0');Pulse:FlashMe(false);Pulse:FlashMe();Pulse:FlashMe({})");require(button->getFlash()==1,"nonnumeric argument mutated flash");});
    test("Lua nonfinite and out-of-range numbers disable without unsafe integer casts",[&]{vm.run("Pulse:FlashMe(1/0)");require(button->getFlash()==0,"infinity enabled flash");vm.run("Pulse:FlashMe(1);Pulse:FlashMe(0/0)");require(button->getFlash()==0,"NaN enabled flash");});
    auto* root=wm.createWindow("DefaultWindow","FixtureRoot");root->setSize(Absolute,Size(1024,768));system.setGUISheet(root);
    auto* account=wm.createWindow("DefaultWindow","FixtureAccount");account->setSize(Absolute,Size(500,500));root->addChildWindow(account);
    auto* server=wm.createWindow("DefaultWindow","FixtureServer");server->setSize(Absolute,Size(500,500));root->addChildWindow(server);server->moveToFront();
    std::vector<FalagardCheckButton*> areas;
    for(int i=1;i<=32;++i){char name[48];std::snprintf(name,sizeof(name),i<=16?"SelectServer_Subarea%d":"SelectServer2_Subarea%d",i<=16?i:i-16);auto* w=make(name);w->setCheck(true);w->setFlash(1);server->addChildWindow(w);areas.push_back(w);box(lua,w,name);}
    std::ifstream input(std::string(argv[1])+"/SelectServer/SelectServer.lua",std::ios::binary);require(bool(input),"actual SelectServer.lua unavailable");
    std::string script((std::istreambuf_iterator<char>(input)),std::istreambuf_iterator<char>());if(script.compare(0,3,"\xef\xbb\xbf")==0)script.erase(0,3);vm.run(script.c_str());
    // Fill the script's existing local arrays with real native controls; keep its functions unchanged.
    vm.run("for i=1,100 do local n,t=debug.getupvalue(NotFlashAreaBtnAll,i);if not n then break end;if n=='g_BnArea' or n=='g_BntestArea' then local prefix=n=='g_BnArea' and 'SelectServer_Subarea' or 'SelectServer2_Subarea';for j=1,16 do t[j]=_G[prefix..j] end end end;GameProduceLogin={IsYunGameMobileClient=function() return false end};this={}");
    lua_getglobal(lua,"this");lua_pushlightuserdata(lua,server);lua_pushcclosure(lua,hide,1);setField(lua,-2,"Hide");lua_pop(lua,1);
    test("missing FlashMe aborts actual GL close handler before Hide and leaves server over account",[&]{vm.run("CheckboxMeta.FlashMe=nil;local ok,err=pcall(LoginSelectServer_OnEvent,'GAMELOGIN_CLOSE_SELECT_SERVER');assert(not ok and string.find(err,'FlashMe'))");require(server->isVisible() && system.getTargetWindow(Point(400,400))==server,"pre-fix overlay not reproduced");});
    lua_getglobal(lua,"CheckboxMeta");lua_pushcfunction(lua,flash);setField(lua,-2,"FlashMe");lua_pop(lua,1);
    test("actual GL close handler disables all 32 native areas and uncovers account",[&]{vm.run("LoginSelectServer_OnEvent('GAMELOGIN_CLOSE_SELECT_SERVER')");require(!server->isVisible() && system.getTargetWindow(Point(400,400))==account,"account remained covered");for(auto* w:areas)require(w->getFlash()==0 && !w->isCheck(),"area was not cleared");});
    test("reopening after GL close restores disabled pulse alpha without changing selection",[&]{server->show();server->update(0);for(auto* w:areas)require(w->getAlpha()==1 && !w->isCheck(),"reopened area retained flash alpha");});
    system.setGUISheet(nullptr);wm.destroyAllWindows();wm.cleanDeadPool();
    std::printf("RESULT passed=%d failed=%d\n",passed,failed);return failed?1:0;
}
