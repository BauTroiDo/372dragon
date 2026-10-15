#pragma once
#include "UICreatureBoard.h"
#include "FalagardSelfFitWindow.h"

namespace CysNameboardFixture {
static CEGUI::String nameText,titleText;
static bool saved=false;
static const char* longName=u8"Đặng Nguyễn Trường Giang - Người hướng dẫn nhiệm vụ Đại Lý";
static const char* longTitle=u8"Đại sư luyện dược - Điều chế linh đan và hướng dẫn nhiệm vụ môn phái";
}

// The probe borrows a live NPC board. Only its local label text is temporarily
// replaced; no object attributes, database records or packets are changed.
extern "C" __declspec(dllexport) int __cdecl CysNameboardFixtureRun(tCreatureBoard* board,int mode,float out[8]) {
    char enabled[4]={};
    if(!board || !out || !g_hMainWnd || GetEnvironmentVariableA("CYS_NAMEBOARD_LIVE",enabled,sizeof(enabled))!=1 || enabled[0]!='1' ||
       !strstr(GetCommandLineA(),"-cys-gl-login-smoke") || GetWindowThreadProcessId(g_hMainWnd,nullptr)!=GetCurrentThreadId())return -1;
    using namespace CEGUI;using namespace CysNameboardFixture;
    try {
        Window* root=static_cast<CCreatureBoard*>(board)->GetMainWindow();
        auto& wm=WindowManager::getSingleton();
        auto name=dynamic_cast<FalagardSelfFitWindow*>(wm.getWindow(root->getName()+"__auto_playername__"));
        auto title=dynamic_cast<FalagardSelfFitWindow*>(wm.getWindow(root->getName()+"__auto_playertitle__"));
        if(!name || !title || !name->isVisible())return -2;
        if(mode==7){
            for(auto w:{name,title})if(!w->getFitTextArea() || w->getMaxWidth()!=600 || w->getMinHeight()!=32 ||
                w->getHorizontalFormatting()!=FalagardSimpleText::WordWrapCentred)return -5;
            return 0;
        }
        if(mode==1){
            if(saved)return -3;
            nameText=name->getText();titleText=title->getText();saved=true;
            name->setFitTextArea(false);title->setFitTextArea(false);
            name->setMaxWidth(250);title->setMaxWidth(500);name->setMinHeight(0);
            name->setHorizontalFormatting(FalagardSimpleText::HorzCentred);
            title->setHorizontalFormatting(FalagardSimpleText::HorzCentred);
            name->setText((const utf8*)longName);title->setText((const utf8*)longTitle);
        }
        if(mode==2){
            name->setHorizontalFormatting(FalagardSimpleText::WordWrapCentred);
            title->setHorizontalFormatting(FalagardSimpleText::WordWrapCentred);
            for(auto w:{name,title}){w->setMaxWidth(600);w->setMinHeight(32);w->setFitTextArea(true);}
        }
        if(mode==5)name->setText((const utf8*)u8"Đặng Nguyễn Trường Giang");
        if(mode==6){name->setText((const utf8*)longName);title->setText((const utf8*)longTitle);}
        if(mode==3){
            name->setText((const utf8*)u8"Đặng Nguyễn Trường Giang - Người hướng dẫn nhiệm vụ môn phái và truyền thụ võ học tại Đại Lý");
            title->setText((const utf8*)u8"Đại sư luyện dược - Điều chế linh đan, hướng dẫn nhiệm vụ môn phái và truyền thụ bí quyết chữa thương cho đệ tử mới nhập môn");
        }
        if(mode==4){
            if(!saved)return -3;
            name->setText(nameText);title->setText(titleText);saved=false;
            return 0;
        }
        const fVector2 anchor=board->GetPosition();board->SetPosition(anchor.x,anchor.y);
        int clipped=0,index=0;
        for(auto w:{name,title}){
            const Rect area=WidgetLookManager::getSingleton().getWidgetLook(w->getLookNFeel()).getNamedArea("TextArea").getArea().getPixelRect(*w);
            const auto scale=w->getTextScale();
            const Size text=w->getFont()->getFormattedSize(w->getText(),area,(TextFormatting)w->getHorizontalFormatting(),scale.d_width,scale.d_height);
            const bool cut=text.d_width>area.getWidth()+0.1f || text.d_height>area.getHeight()+0.1f;
            clipped+=cut?1:0;
            out[index++]=w->getAbsoluteWidth();out[index++]=w->getAbsoluteHeight();
            if(mode!=0){char line[1024];sprintf(line,"CYS-NAMEBOARD: mode=%d label=%s window=%.1f,%.1f area=%.1f,%.1f text=%.1f,%.1f cut=%d fit=%d max=%d hollow=%d",
                mode,w==name?"name":"title",w->getAbsoluteWidth(),w->getAbsoluteHeight(),area.getWidth(),area.getHeight(),text.d_width,text.d_height,cut,w->getFitTextArea(),w->getMaxWidth(),w->getMouseHollow());Logger::getSingleton().logEvent(line,Standard);}
        }
        const Rect nr=name->getUnclippedPixelRect(),tr=title->getUnclippedPixelRect();
        out[4]=nr.d_left+nr.getWidth()/2;out[5]=nr.d_bottom;out[6]=tr.d_bottom<=nr.d_top+1?1.f:0.f;
        out[7]=name->getMouseHollow() && title->getMouseHollow()?1.f:0.f;
        return clipped;
    }catch(const Exception& e){Logger::getSingleton().logEvent("CYS-NAMEBOARD: exception "+e.getMessage(),Errors);return -4;}
}
