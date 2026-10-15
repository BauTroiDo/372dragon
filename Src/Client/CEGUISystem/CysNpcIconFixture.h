#pragma once
#include "FalagardComplexWindow.h"
#include "elements/CEGUIStaticImage.h"
#include "CEGUIImage.h"
#include "CEGUIPropertyHelper.h"

// Owned smoke only. First inspect the real server menu; then use an isolated
// ComplexWindow with no Lua/network handler to test all configured icon states.
namespace CysNpcIconFixture {
static CEGUI::FalagardComplexWindow* fixture = nullptr;
static int clicks = 0;
static CEGUI::String lastClicked;
static CEGUI::String expectedClicked;
inline bool Clicked(const CEGUI::EventArgs& e) {
    ++clicks;
    lastClicked = static_cast<const CEGUI::WindowEventArgs&>(e).window->getName();
    return true;
}
inline int Inspect(CEGUI::Window* parent, const char* phase, float out[12]) {
    using namespace CEGUI;
    int count = 0;
    for (uint i=0; i<parent->getChildCount(); ++i) {
        Window* button=parent->getChildAtIdx(i);
        const String name=button->getName()+"__icon__";
        if (!WindowManager::getSingleton().isWindowPresent(name)) continue;
        auto icon=dynamic_cast<StaticImage*>(WindowManager::getSingleton().getWindow(name));
        if (!icon || !icon->getImage()) return -2;
        const Rect cell=icon->getImage()->getSourceTextureArea();
        const Rect r=icon->getUnclippedPixelRect();
        char line[1024];
        sprintf(line,"CYS-NPC-ICON: %s button=%s image=[%s] size=%.0f,%.0f source=%.0f,%.0f mouse=%d,%d",
            phase,button->getName().c_str(),icon->getProperty("Image").c_str(),r.getWidth(),r.getHeight(),
            cell.getWidth(),cell.getHeight(),icon->getMouseHollow(),icon->getMouseMoveHollow());
        Logger::getSingleton().logEvent(line,Standard);
        if (r.getWidth()!=cell.getWidth() || r.getHeight()!=cell.getHeight() ||
            !icon->getMouseHollow() || !icon->getMouseMoveHollow()) return -3;
        if (!count) {
            expectedClicked=button->getName();
            out[0]=r.d_left+r.getWidth()/2;out[1]=r.d_top+r.getHeight()/2;
            const Rect b=button->getUnclippedPixelRect();
            out[2]=b.d_left+b.getWidth()/2;out[3]=b.d_top+b.getHeight()/2;
        }
        ++count;
    }
    return count;
}
}

extern "C" __declspec(dllexport) int __cdecl CysNpcIconFixtureRun(int mode, float out[12]) {
    char enabled[4]={};
    if (!out || !g_hMainWnd ||
        GetEnvironmentVariableA("CYS_NPC_ICON_LIVE",enabled,sizeof(enabled))!=1 || enabled[0]!='1' ||
        !strstr(GetCommandLineA(),"-cys-gl-login-smoke") ||
        GetWindowThreadProcessId(g_hMainWnd,nullptr)!=GetCurrentThreadId()) return -1;
    using namespace CEGUI;
    using namespace CysNpcIconFixture;
    try {
        auto& wm=WindowManager::getSingleton();
        auto original=dynamic_cast<FalagardComplexWindow*>(wm.getWindow("QuestGreeting_Desc"));
        if (!original) return -2;
        if (mode==0) {
            if (!original->isVisible()) return -3;
            return Inspect(wm.getWindow(original->getName()+"__auto_parent__"),"server",out);
        }
        if (mode==8) {
            if (fixture) wm.destroyWindow(fixture);
            fixture=nullptr;original->show();return 1;
        }
        if (mode==7) {out[4]=float(clicks);return lastClicked==expectedClicked ? 1 : 0;}
        if (mode==10) {out[4]=fixture->GetVertScrollbarPosition();return 1;}
        if (!fixture) {
            fixture=static_cast<FalagardComplexWindow*>(wm.createWindow("TLBB_ComplexWindow","CysNpcIconCheck"));
            original->getParent()->addChildWindow(fixture);
            fixture->setFont(original->getFont());
            fixture->setPosition(Absolute,original->getAbsolutePosition());
            fixture->setSize(Absolute,original->getAbsoluteSize());
            fixture->subscribeEvent(FalagardComplexWindow::EventOptionClicked,Event::Subscriber(&Clicked));
            original->hide();fixture->show();
        }
        fixture->ClearAllElement();clicks=0;lastClicked="";
        const char* labels[]={"Mac dinh","Nhan nhiem vu","Tra nhiem vu","Nhiem vu 3","Nhiem vu 4",
            "Lua chon 5","Phan thuong","Cua hang","Lua chon 8","Dich chuyen","Lua chon 10","Khac"};
        int begin=mode==9 ? 0 : (mode-1)*6, end=mode==9 ? 32 : std::min(begin+6,32);
        for (int i=begin;i<end;++i) {
            char state[16],text[128];sprintf(state,"%d",i);
            sprintf(text,"%02d  %s",i,i<12 ? labels[i] : "Bieu tuong theo bo giao dien CY");
            fixture->AddChildElement_Option(text,"-9173",state,state,nullptr);
        }
        fixture->SetVertScrollbarPosition(0);
        return Inspect(wm.getWindow(fixture->getName()+"__auto_parent__"),"catalog",out);
    } catch (const Exception& e) {
        Logger::getSingleton().logEvent("CYS-NPC-ICON: exception "+e.getMessage(),Errors);return -4;
    }
}
