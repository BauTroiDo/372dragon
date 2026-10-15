// CYS-MTSWEEP 19/09/2026 - DO THAT, ngoai tro choi: hau qua cua "ep kieu mu m_pWindow" khi metatable dung chung.
//
// Khong can Game.exe, khong can GPU, khong can mang. Dung dung hai DLL that (CEGUIBase.dll, CEGUIFalagard.dll)
// va mot Renderer trong bo nho, tao ra dung nhung lop widget ma cac khung that dung, roi chay HAI TAY:
//     * tay DOI CHUNG = duong ep kieu mu CU (thu ma UILuaControl.cpp lam truoc ban va)
//     * tay SUA       = duong dieu huong theo kieu THAT (thu ma UILuaControl.cpp lam sau ban va)
//
// Tay doi chung chay trong TIEN TRINH CON, vi no co the giet tien trinh den muc `__except` cung khong cuu duoc
// (goi nham mot ham AO lam hong ca ngan xep) - va do chinh la trieu chung trong game: chet, khong loi Lua,
// khong thong bao. Ma thoat cua tien trinh con CHINH LA so do.
//
// Phep do BIET TRUOT: neu mot tay doi chung nao do song sot va khong doi byte nao thi probe bao [FAIL],
// vi khi do no khong chung minh duoc dieu gi.
//
//   metatable_cast_probe.exe <duong-dan-font.ttf> [ten-tay]
//       (khong co ten-tay) = tien trinh cha: chay cac tay SUA + goi lai chinh minh cho tung tay DOI CHUNG
//       edit-setselected   = ((FalagardNotSuperListItem*)editbox)->setSelected(true)
//       scrollinfo-clear   = ((FalagardNotSuperList*)scrollinfo)->GetListSize()
//       image-combobox     = ((Combobox*)staticimage)->getSelectedItem()
#include "CEGUISystem.h"
#include "CEGUIRenderer.h"
#include "CEGUITexture.h"
#include "CEGUIDefaultResourceProvider.h"
#include "CEGUIWindowManager.h"
#include "CEGUIWindowFactoryManager.h"
#include "CEGUIExceptions.h"
#include "CEGUIFontManager.h"
#include "CEGUIFontBase.h"
#include "FalIMEEditBox.h"
#include "FalagardNotSuperList.h"
#include "FalagardScrollInfo.h"
#include "FalStaticImage.h"
#include "elements/CEGUICombobox.h"
#include "elements/CEGUIListbox.h"
#include "elements/CEGUIListboxTextItem.h"
#include <windows.h>
#include <cstdio>
#include <cstring>
#include <cstdlib>
#include <fstream>
#include <string>
#include <vector>

using namespace CEGUI;

static int passed = 0, failed = 0;
static void check(const char* name, bool ok, const char* detail)
{
    if (ok) { ++passed; std::printf("[PASS] %s | %s\n", name, detail); }
    else    { ++failed; std::printf("[FAIL] %s | %s\n", name, detail); }
}

struct MemoryTexture : Texture
{
    ushort d_size;
    MemoryTexture(Renderer* r, ushort size) : Texture(r), d_size(size) {}
    ushort getWidth() const override { return d_size; }
    ushort getHeight() const override { return d_size; }
    void loadFromFile(const String&, const String&) override {}
    void loadFromMemory(const void*, uint, uint) override {}
};

struct MemoryRenderer : Renderer
{
    unsigned long addQuad(const Rect&, float, const Texture*, const Rect&, const ColourRect&, QuadSplitMode, UserSharps) override { return 1; }
    void adjustQuad(unsigned long, const Texture*, const Rect&, const ColourRect&) override {}
    void doRender() override {}
    void clearRenderList() override {}
    void setQueueingEnabled(bool) override {}
    Texture* createTexture() override { return new MemoryTexture(this, 256); }
    Texture* createTexture(const String&, const String&) override { return new MemoryTexture(this, 256); }
    Texture* createTexture(float size) override { return new MemoryTexture(this, static_cast<ushort>(size)); }
    void destroyTexture(Texture* texture) override { delete texture; }
    void destroyAllTextures() override {}
    bool isQueueingEnabled() const override { return true; }
    float getWidth() const override { return 1024; }
    float getHeight() const override { return 768; }
    Size getSize() const override { return Size(1024, 768); }
    Rect getRect() const override { return Rect(0, 0, 1024, 768); }
    uint getMaxTextureSize() const override { return 2048; }
    uint getHorzScreenDPI() const override { return 96; }
    uint getVertScreenDPI() const override { return 96; }
};

static std::string diffOffsets(const std::vector<char>& a, const std::vector<char>& b, size_t windowSize, int* beyondWindow)
{
    std::string out;
    char buf[64];
    *beyondWindow = 0;
    for (size_t i = 0; i < a.size() && i < b.size(); ++i)
    {
        if (a[i] == b[i]) continue;
        if (i >= windowSize) ++(*beyondWindow);
        if (out.size() < 300)
        {
            std::sprintf(buf, "0x%03X(%02X->%02X)%s ", (unsigned)i, (unsigned char)a[i], (unsigned char)b[i],
                         i >= windowSize ? "*" : "");
            out += buf;
        }
    }
    return out;
}

// Ma thoat rieng cua tien trinh con khi tay doi chung SONG SOT (de phan biet voi ma ngoai le cua Windows).
static const unsigned CONTROL_SURVIVED_NO_DAMAGE = 70;
static const unsigned CONTROL_SURVIVED_DAMAGED   = 71;

static FontBase* makeFont(const char* fontPath)
{
    if (!fontPath) return 0;
    std::ofstream("probe.font", std::ios::binary)
        << "<Font Name=\"Probe\" Type=\"FreeType\" Filename=\"" << fontPath << "\" Size=\"12\"/>";
    FontManager::getSingleton().setCodePage(65001);
    return FontManager::getSingleton().createFont(FreeType, "probe.font");
}

// Mot `CEGUI::Listbox` CU THE, khong can look'n'feel - dung de tra loi mot cau hoi duy nhat:
// mot Listbox thuong co thuoc tinh "AddItem" hay khong. (`Falagard/Listbox` va `Falagard/ListBoxEx`
// deu ke thua `FalagardListbox` -> `CEGUI::Listbox`; thuoc tinh "AddItem" chi duoc khai bao trong
// `FalImageListProperties.h` va `FalImageListExProperties.h`.)
struct PlainListbox : Listbox
{
    PlainListbox(const String& t, const String& n) : Listbox(t, n) {}
    Rect getListRenderArea() const override { return Rect(0, 0, 120, 60); }
    Scrollbar* createVertScrollbar(const String&) const override { return 0; }
    Scrollbar* createHorzScrollbar(const String&) const override { return 0; }
    void cacheListboxBaseImagery() override {}
    void initialise() override {}
};
struct PlainListboxFactory : WindowFactory
{
    PlainListboxFactory() : WindowFactory("Probe/Listbox") {}
    Window* createWindow(const String& n) override { return new PlainListbox(d_type, n); }
    void destroyWindow(Window* w) override { delete w; }
};

static void registerFactories()
{
    WindowFactoryManager& fm = WindowFactoryManager::getSingleton();
    fm.addFactory(new PlainListboxFactory);
    fm.addFactory(new FalagardIMEEditBoxFactory);
    fm.addFactory(new FalagardNotSuperListFactory);
    fm.addFactory(new FalagardNotSuperListItemFactory);
    fm.addFactory(new FalagardScrollInfoFactory);
    fm.addFactory(new FalagardStaticImageFactory);
}

// --------------------------------------------------------------------------------- tien trinh con: mot tay
static int runControlArm(const char* arm, const char* fontPath)
{
    MemoryRenderer renderer;
    DefaultResourceProvider provider;
    System system(&renderer, &provider);
    registerFactories();
    WindowManager& wm = WindowManager::getSingleton();
    FontBase* font = makeFont(fontPath);

    if (std::strcmp(arm, "edit-setselected") == 0)
    {
        FalagardIMEEditBox* edit = static_cast<FalagardIMEEditBox*>(wm.createWindow("Falagard/IMEEditBox", "probe_edit"));
        if (font) edit->setFont(font);
        edit->setMaxTextLength(32);
        edit->setText("123456");
        edit->setSelection(0, 0);
        std::vector<char> before(sizeof(FalagardIMEEditBox)), after(sizeof(FalagardIMEEditBox));
        std::memcpy(&before[0], edit, before.size());
        // Do offset cua vai truong cua Editbox bang chinh phep dat cua no, de goi ten byte bi ghi de.
        {
            FalagardIMEEditBox* map = static_cast<FalagardIMEEditBox*>(wm.createWindow("Falagard/IMEEditBox", "probe_map"));
            if (font) map->setFont(font);
            std::vector<char> a(sizeof(FalagardIMEEditBox)), b(sizeof(FalagardIMEEditBox));
            int n = 0;
            std::memcpy(&a[0], map, a.size()); map->setReadOnly(true);
            std::memcpy(&b[0], map, b.size());
            std::printf("      [con] offset cua Editbox::d_readOnly = %s\n", diffOffsets(a, b, sizeof(Window), &n).c_str());
            std::memcpy(&a[0], map, a.size()); map->setTextMasked(true);
            std::memcpy(&b[0], map, b.size());
            std::printf("      [con] offset cua Editbox::d_maskText  = %s\n", diffOffsets(a, b, sizeof(Window), &n).c_str());
        }
        std::printf("      [con] truoc: readOnly=%d masked=%d maxLen=%u carat=%u selStart=%u selLen=%u\n",
                    (int)edit->isReadOnly(), (int)edit->isTextMasked(), (unsigned)edit->getMaxTextLength(),
                    (unsigned)edit->getCaratIndex(), (unsigned)edit->getSelectionStartIndex(),
                    (unsigned)edit->getSelectionLength());
        std::printf("      [con] sap goi ((FalagardNotSuperListItem*)editbox)->setSelected(true)\n");
        ((FalagardNotSuperListItem*)edit)->setSelected(true);      // <== duong ep kieu mu cu
        std::memcpy(&after[0], edit, after.size());
        int beyond = 0;
        const std::string diff = diffOffsets(before, after, sizeof(Window), &beyond);
        std::printf("      [con] song sot; byte doi: %s | ngoai phan Window (>=0x%03X): %d\n",
                    diff.empty() ? "(khong co)" : diff.c_str(), (unsigned)sizeof(Window), beyond);
        std::printf("      [con] sau:   readOnly=%d masked=%d maxLen=%u carat=%u selStart=%u selLen=%u\n",
                    (int)edit->isReadOnly(), (int)edit->isTextMasked(), (unsigned)edit->getMaxTextLength(),
                    (unsigned)edit->getCaratIndex(), (unsigned)edit->getSelectionStartIndex(),
                    (unsigned)edit->getSelectionLength());
        return beyond > 0 ? CONTROL_SURVIVED_DAMAGED : CONTROL_SURVIVED_NO_DAMAGE;
    }
    if (std::strcmp(arm, "scrollinfo-clear") == 0)
    {
        FalagardScrollInfo* info = static_cast<FalagardScrollInfo*>(wm.createWindow("Falagard/ScrollInfo", "probe_info"));
        info->setWaitingInfo("a"); info->setWaitingInfo("b"); info->setWaitingInfo("c");
        FalagardNotSuperList* real = static_cast<FalagardNotSuperList*>(wm.createWindow("Falagard/NotSuperList", "probe_list"));
        std::printf("      [con] NotSuperList that (rong) GetListSize()=%llu\n", (unsigned long long)real->GetListSize());
        std::printf("      [con] sap goi ((FalagardNotSuperList*)scrollinfo)->GetListSize()\n");
        const size_t garbage = ((FalagardNotSuperList*)info)->GetListSize();   // <== duong ep kieu mu cu
        std::printf("      [con] song sot; GetListSize() tren ScrollInfo = %llu => vong lap `Clear` cua ban cu "
                    "se goi GetListItem() %llu lan tren mot doi tuong khong he co danh sach\n",
                    (unsigned long long)garbage, (unsigned long long)garbage);
        return garbage != real->GetListSize() ? CONTROL_SURVIVED_DAMAGED : CONTROL_SURVIVED_NO_DAMAGE;
    }
    if (std::strcmp(arm, "image-combobox") == 0)
    {
        Window* image = wm.createWindow("Falagard/StaticImage", "probe_image");
        std::printf("      [con] sap goi ((Combobox*)staticimage)->getSelectedItem()\n");
        ListboxItem* item = ((Combobox*)image)->getSelectedItem();            // <== duong ep kieu mu cu
        std::printf("      [con] song sot; getSelectedItem() = %p\n", (void*)item);
        return item ? CONTROL_SURVIVED_DAMAGED : CONTROL_SURVIVED_NO_DAMAGE;
    }
    if (std::strcmp(arm, "listbox-additem") == 0)
    {
        // `AddItem` dang ky BA lan; ban thang la `ImageListBoxEx::AddItem`, no dat THUOC TINH "AddItem".
        // Cau hoi do: mot Listbox thuong co thuoc tinh do khong?
        PlainListbox* list = static_cast<PlainListbox*>(wm.createWindow("Probe/Listbox", "probe_plainlist"));
        std::printf("      [con] Listbox thuong: isPropertyPresent(\"AddItem\") = %d\n",
                    (int)list->isPropertyPresent("AddItem"));
        std::printf("      [con] sap goi setProperty(\"AddItem\", \"id=1 state=0 text=x\")\n");
        bool threw = false;
        String what;
        try { list->setProperty("AddItem", "id=1 state=0 text=x"); }
        catch (const CEGUI::Exception& e) { threw = true; what = e.getMessage(); }
        std::printf("      [con] nem ngoai le = %d (%s); so muc trong danh sach = %u\n",
                    (int)threw, what.c_str(), (unsigned)list->getItemCount());
        return (threw && list->getItemCount() == 0) ? CONTROL_SURVIVED_DAMAGED : CONTROL_SURVIVED_NO_DAMAGE;
    }
    std::printf("      [con] khong biet tay '%s'\n", arm);
    return 2;
}

static unsigned runChild(const char* exe, const char* fontPath, const char* arm)
{
    char cmd[1024];
    std::sprintf(cmd, "\"%s\" \"%s\" %s", exe, fontPath ? fontPath : "", arm);
    STARTUPINFOA si; PROCESS_INFORMATION pi;
    std::memset(&si, 0, sizeof(si)); si.cb = sizeof(si);
    std::memset(&pi, 0, sizeof(pi));
    if (!CreateProcessA(NULL, cmd, NULL, NULL, TRUE, 0, NULL, NULL, &si, &pi)) return 0xFFFFFFFF;
    WaitForSingleObject(pi.hProcess, 60000);
    DWORD code = 0;
    GetExitCodeProcess(pi.hProcess, &code);
    CloseHandle(pi.hThread); CloseHandle(pi.hProcess);
    return (unsigned)code;
}

static void controlCheck(const char* name, const char* exe, const char* fontPath, const char* arm)
{
    std::printf("  -- tay DOI CHUNG '%s'\n", arm);
    const unsigned code = runChild(exe, fontPath, arm);
    char detail[300];
    const bool died = (code & 0xC0000000u) == 0xC0000000u;
    std::sprintf(detail, "ma thoat tien trinh con = 0x%08X (%s)", code,
                 died ? "tien trinh CHET - ngoai le Windows"
                      : code == CONTROL_SURVIVED_DAMAGED ? "song sot nhung da doc/ghi sai"
                      : code == CONTROL_SURVIVED_NO_DAMAGE ? "song sot va KHONG hu hai gi"
                      : "ket thuc bat thuong");
    check(name, died || code == CONTROL_SURVIVED_DAMAGED, detail);
}

// ------------------------------------------------------------------------------------ tien trinh cha
int main(int argc, char** argv)
{
    setvbuf(stdout, NULL, _IONBF, 0);
    const char* fontPath = (argc > 1 && argv[1][0]) ? argv[1] : 0;
    if (argc > 2) return runControlArm(argv[2], fontPath);

    std::printf("sizeof(Window)=%u sizeof(FalagardNotSuperListItem)=%u sizeof(FalagardIMEEditBox)=%u "
                "sizeof(FalagardNotSuperList)=%u sizeof(FalagardScrollInfo)=%u\n",
                (unsigned)sizeof(Window), (unsigned)sizeof(FalagardNotSuperListItem),
                (unsigned)sizeof(FalagardIMEEditBox), (unsigned)sizeof(FalagardNotSuperList),
                (unsigned)sizeof(FalagardScrollInfo));

    // ---- bon tay DOI CHUNG, moi tay mot tien trinh con
    // 1. `ActivitySchedule_MBuy_InputNumBK:SetSelected(0,-1)` va 83 cua so cung dang (o nhap chu)
    controlCheck("DOI CHUNG 1/4: ep kieu mu NotSuperListItem tren mot Editbox (83 cua so that)",
                 argv[0], fontPath, "edit-setselected");
    // 2. `ScrollInfo_Frame:Clear()` (ScrollInfo.lua:35,43,48,57, canh 303..306)
    controlCheck("DOI CHUNG 2/4: ep kieu mu NotSuperList tren mot ScrollInfo",
                 argv[0], fontPath, "scrollinfo-clear");
    // 3. `CreateRole_SelectHair:GetCurrentSelect()` (man tao nhan vat)
    controlCheck("DOI CHUNG 3/4: ep kieu mu Combobox tren mot StaticImage",
                 argv[0], fontPath, "image-combobox");
    // 4. `Friend_List:AddItem(...)`, `GemList_List:AddItem(...)` va 157 cho khac - ban dang ky thang la
    //    `ImageListBoxEx::AddItem`, no dat thuoc tinh "AddItem" ma Listbox thuong khong co.
    controlCheck("DOI CHUNG 4/4: ban AddItem cua ImageListBoxEx tren mot Listbox thuong",
                 argv[0], fontPath, "listbox-additem");

    // ---- cac tay SUA, chay ngay trong tien trinh nay
    MemoryRenderer renderer;
    DefaultResourceProvider provider;
    System system(&renderer, &provider);
    registerFactories();
    WindowManager& wm = WindowManager::getSingleton();
    FontBase* font = makeFont(fontPath);
    {
        FalagardIMEEditBox* edit = static_cast<FalagardIMEEditBox*>(wm.createWindow("Falagard/IMEEditBox", "fix_edit"));
        if (font) edit->setFont(font);
        edit->setMaxTextLength(32);
        edit->setText("123456");
        edit->setSelection(0, (size_t)-1);      // duong moi: Editbox::setSelection nhu CY
        char d[200];
        std::sprintf(d, "chon %u/%u ky tu", (unsigned)edit->getSelectionLength(), (unsigned)edit->getText().length());
        check("SUA 1/4: Editbox::setSelection(0,-1) chon het chu nhu CY, khong cham ra ngoai lop",
              edit->getSelectionLength() == edit->getText().length() && edit->getText().length() == 6, d);
    }
    {
        FalagardScrollInfo* info = static_cast<FalagardScrollInfo*>(wm.createWindow("Falagard/ScrollInfo", "fix_info"));
        info->setWaitingInfo("a"); info->setWaitingInfo("b"); info->setWaitingInfo("c");
        const size_t q = info->getQueueSize();
        info->ResetIt();                         // duong moi cho `Clear` tren ScrollInfo
        char d[200];
        std::sprintf(d, "hang doi %u -> %u (muc dau tien da chuyen sang trang thai dang hien)",
                     (unsigned)q, (unsigned)info->getQueueSize());
        check("SUA 2/4: ScrollInfo::ResetIt() xoa dung hang doi cua no", q > 0 && info->getQueueSize() == 0, d);
    }
    {
        Window* image = wm.createWindow("Falagard/StaticImage", "fix_image");
        Combobox* safe = dynamic_cast<Combobox*>(image);                       // duong moi
        FalagardNotSuperListItem* notItem = dynamic_cast<FalagardNotSuperListItem*>(image);
        check("SUA 3/4: dynamic_cast tren mot StaticImage tra NULL, binding thoat sach",
              safe == 0 && notItem == 0, safe == 0 && notItem == 0 ? "ca hai deu NULL" : "KHONG NULL - mo hinh sai");
    }
    {
        // Duong moi cho `AddItem` khi cua so that la mot Listbox: them ListboxTextItem, khong dung thuoc tinh.
        PlainListbox* list = static_cast<PlainListbox*>(wm.createWindow("Probe/Listbox", "fix_plainlist"));
        ListboxTextItem* item = new ListboxTextItem((utf8*)"x", 7);
        list->addItem(item);
        char d[200];
        std::sprintf(d, "so muc = %u, id muc dau = %u", (unsigned)list->getItemCount(),
                     (unsigned)(list->getItemCount() ? list->getListboxItemFromIndex(0)->getID() : 0));
        check("SUA 4/4: Listbox nhan duoc muc qua addItem (duong ma 159 loi goi Lua le ra phai di)",
              list->getItemCount() == 1, d);
    }

    std::printf("passed=%d failed=%d\n", passed, failed);
    return failed ? 1 : 0;
}
