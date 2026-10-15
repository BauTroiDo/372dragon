#pragma once
#include "UIWindowMng.h"
#include "FalagardComplexWindow.h"
#include "FalagardNotSuperList.h"
#include "FalChatHistory.h"
#include "elements/CEGUIListbox.h"
#include "elements/CEGUIListboxTextItem.h"
#include "elements/CEGUIMultiColumnList.h"
#include "elements/CEGUIStaticText.h"
#include "elements/CEGUIScrollbar.h"

// Populate actual loaded CY menu instances with client-only long content. No Lua
// callback is replaced, no packet is sent. The owning smoke exits after the checks.
extern "C" __declspec(dllexport) int __cdecl CysUiWheelFixture(const char* name, int prepare, float out[6])
{
    char enabled[4] = {};
    if (!name || !out || !g_hMainWnd ||
        GetEnvironmentVariableA("CYS_UI_WHEEL_LIVE",enabled,sizeof(enabled))!=1 || enabled[0]!='1' ||
        !strstr(GetCommandLineA(),"-cys-gl-login-smoke") ||
        GetWindowThreadProcessId(g_hMainWnd,nullptr)!=GetCurrentThreadId()) return 0;
    using namespace CEGUI;
    try {
        if (prepare==-1) return CUIWindowMng::GetMe()->ShowWindowByName(name) ? 1 : 0;
        if (prepare==-2) return CUIWindowMng::GetMe()->CloseWindowByName(name) ? 1 : 0;
        WindowManager& wm=WindowManager::getSingleton();
        Window* w=wm.getWindow(name);
        if (!w->isVisible()) return 0;
        if (prepare) {
            if (auto p=dynamic_cast<FalagardComplexWindow*>(w)) {
                p->ClearAllElement();
                for (int i=0;i<40;++i) {char row[120];sprintf(row,"Menu %02d - kiem tra cuon noi dung dai",i+1);p->AddChildElement_Option(row,"","","",nullptr);}
            } else if (auto p=dynamic_cast<FalagardNotSuperList*>(w)) {
                p->Clear();
                for (int i=0;i<100;++i) p->AddChild("SelectFacestyle_SuperListItem");
                p->RefreshLayout();
            } else if (auto p=dynamic_cast<MultiColumnList*>(w)) {
                p->resetList();
                if (!p->getColumnCount()) p->addColumn("Menu",0,0.9f);
                for (int i=0;i<40;++i) {char row[64];sprintf(row,"Menu %02d - scroll check",i+1);p->addRow(new ListboxTextItem(row),p->getColumnID(0),i);}
            } else if (auto p=dynamic_cast<Listbox*>(w)) {
                p->resetList();
                for (int i=0;i<40;++i) {char row[64];sprintf(row,"Menu %02d - scroll check",i+1);p->addItem(new ListboxTextItem(row,i));}
            } else if (auto p=dynamic_cast<StaticText*>(w)) {
                String text;
                for (int i=0;i<40;++i) text+="Long description - scroll the content here.\n";
                p->setText(text);
            } else if (auto p=dynamic_cast<FalagardChatHistory*>(w)) {
                p->setChatBoardNumber(100);
                for (int i=0;i<40;++i) {char row[64];sprintf(row,"Local scroll check %02d",i+1);p->insertChatString(row);}
            } else return -2;
        }
        Scrollbar* bar=dynamic_cast<Scrollbar*>(wm.getWindow(w->getName()+"__auto_vscrollbar__"));
        if (!bar || !bar->isVisible()) return -3;
        if (prepare) bar->setScrollPosition(0);
        const Rect r=w->getPixelRect();
        out[0]=r.d_left;out[1]=r.d_top;out[2]=r.getWidth();out[3]=r.getHeight();
        out[4]=bar->getScrollPosition();out[5]=bar->getDocumentSize()-bar->getPageSize();
        return 1;
    } catch (const Exception& e) {
        Logger::getSingleton().logEvent("CYS-UI-WHEEL fixture: "+e.getMessage(),Errors);
        return -4;
    }
}
