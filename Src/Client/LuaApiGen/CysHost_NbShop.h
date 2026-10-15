// CYS-NBSHOP 20/09: the door of the yuanbao mall (YuanbaoShop frame, "shop nguyen bao").
//
// What the working pair does (Build/Logs/2026-09-20-nbshop/01-cay-song-lam-the-nao.md):
//   MiniMap_Yuanbao button -> MiniMap_YuanBaoFunc() -> ToggleYuanbaoShop()
//     client_GL Game.exe (sha256 ce0c4fec...): body 0x1402214d0 = PushEvent(0x239 TOGGLE_YUANBAOSHOP), no argument
//     CY 3.71   Game.exe (sha256 9278c7f3...): body 0x140239e10 = PushEvent(0x24e TOGGLE_YUANBAOSHOP, "normal")
//   -> YuanbaoShop.lua sends Send_XSCRIPT("OpenYuanbaoShop", 888902, {target, A, B})          (CGExecuteScript)
//   -> server DispatchYuanbaoShopItem -> GCShopMerchandiseList{is_yuanbao_shop = 1}
//   -> the client handler pushes OPEN_YUANBAOSHOP, and ONLY THAT shows the frame.
//
// This tree broke the chain at four consecutive links (02-bang-vi-sai.md rows #3 #4 #6 #10). The four fixes carry
// the tag CYS-NBSHOP and share ONE switch so a run can be A/B-ed on a single binary:
//
//   CYS_NBSHOP_OFF unset / ""  everything on (default)
//   CYS_NBSHOP_OFF=1           everything off: the binary behaves as before the patch (arm A)
//   CYS_NBSHOP_OFF=<letters>   only those links off:  d = door host (#3)   x = Send_XSCRIPT mapping (#6)
//                                                     o = OPEN_YUANBAOSHOP on the reply (#10)
//                              (proves that ANY single broken link reproduces the user's symptom)
// The variable is read once and cached.
#pragma once
class tObject_Item;

namespace CysHostNbShop
{
    bool Off(char link);
    const char* OffText();
    // The host body. Returns false when there is no event system to push to.
    bool ToggleYuanbaoShop();
    void RegisterHost();
    // True when currency is handled by the CY confirmation/buy path.
    bool BuyItemOrConfirm(tObject_Item* item);
}
