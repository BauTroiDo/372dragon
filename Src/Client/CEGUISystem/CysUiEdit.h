// CYS-UIEDIT 19/09/2026 — bo sua bo cuc UI ngay trong game (nguoi dung tu keo khung roi LUU).
//
// Huong cua nguoi dung 19/09: "lam 1 cong cu bat tat, cho toi tu vao game, mo khung len va tu keo
// khung den khi vua y". Nguoc voi mang `ui-fit` cu (rut ngan BAN DICH cho vua khung), o day GIU ban
// dich va sua KHUNG.
//
// BA TINH CHAT BAT BUOC
//  1. TAT = KHONG MOT PIXEL. `CYS_UIEDIT` khong bang "1" thi Armed() tra false ngay o bien, khong
//     tao window nao, khong doc file nao, khong dang ky su kien nao.
//  2. KHONG SUA `*.layout.xml`. `Tools/pipeline/build_canonical_cy.py` dung lai CA CAY
//     `InterfaceFolder` tu `.axp` cua CY (xform_layout), nen moi chu sua trong layout se bi xoa sach
//     o lan dung lai sau — dung lop mat du lieu da phai tra gia bang 242 dong DBC. Ket qua keo tay
//     nam trong MOT file TSV rieng, doc luc nap layout va ghi de len thuoc tinh CEGUI.
//  3. AP DE DO DUOC. `CYS_UIEDIT_APPLY=0` tat viec ap de (bang chung A/B: cung binary, cung du lieu,
//     chi khac mot bien moi truong).
//
// BAY DA BIET, DA TRANH TRONG BAN NAY
//  - `RegisterMetaTable` gan MOT metatable cho MOI lop control (UILuaControl.cpp:265
//    `*ProgressBar::s_pMetaTable = *Window::s_pMetaTable`) ⇒ khong ep kieu mu. O day chi dung API cua
//    lop co so `CEGUI::Window` (getProperty/setProperty/getName/getChildAtIdx) nen khong dinh bay do.
//  - Client KHONG tao duoc window CUA HE DIEU HANH moi, nhung CEGUI window thi tao duoc luc chay
//    (FalagardComplexWindow.cpp:316 tao "WoWLook/QuestButton_1" moi lan ve). Vi vay bang trang thai
//    la mot `TLBB_SimpleText` tao luc chay — khong phai mot layout moi, khong sua layout nao.
#pragma once

namespace CEGUI { class Window; }

// UIWindowMng.cpp — mo MOT khung theo ten, khong di qua script cua khung do.
// `OpenWindow("X")` cua Lua chi day su kien `OPEN_WINDOW`; khung nao khong tu dang ky va so khop
// `arg0 == "X"` thi khong bao gio mo. Day la ham tra loi dung yeu cau "mot NPC de mo cac khung con loi".
bool CysUiEditOpenWindow(const char* windowName);

namespace CysUiEdit
{
    // `CysUiEdit.cpp` co chu y KHONG phu thuoc vao quan ly cua so cua game: no chi can mot con tro
    // ham. Nho vay cung file nay linh duoc vao mot harness chi co CEGUI (khong Lua, khong game).
    // UIWindowMng.cpp dat con tro nay luc khoi tao.
    typedef bool (*OpenWindowFn)(const char* windowName);
    void SetOpenWindowFn(OpenWindowFn fn);

    // `CYS_UIEDIT=1`. Doc MOT lan roi nho (giong CysSmokePhysicalMouseAllowed) va ghi MOT dong log,
    // vi dat bien sau khi tien trinh chay la vo tac dung ma khong bao gi.
    bool Armed();

    // Ap bang de len cay window vua nap. Goi tu CUIWindowItem::LoadWindow ngay sau loadWindowLayout,
    // TRUOC _RegisterControlToScript, de script cua khung thay hinh hoc da sua.
    // Tra ve so window bi doi. Khong phu thuoc Armed(): ket qua keo tay la SAN PHAM, con bo sua la
    // CONG CU. `CYS_UIEDIT_APPLY=0` tat rieng viec ap de.
    int ApplyTo(CEGUI::Window* root, const char* layoutFile);

    // Bat/tat che do sua (F11 khi da Armed, hoac export CysUiEditSetMode cho rig do).
    bool SetMode(int on);
    int  Mode();

    // Chon widget theo ten window. Ten window cua engine nay la duy nhat toan cuc
    // (CEGUI::WindowManager::getWindow lay theo ten).
    bool Select(const char* windowName);
    const char* Selected();

    // Hinh chu nhat tuyet doi (pixel man hinh) l,t,w,h — de rig doc lai sau khi keo.
    bool GetRect(const char* windowName, float out[4]);

    // Doi hinh hoc cua widget dang chon. Day CHINH LA duong ma cu keo chuot goi, nen rig goi thang
    // vao day la do dung mot loi ma, khong phai mot loi ma song song.
    bool MoveBy(float dx, float dy);
    bool SizeBy(float dw, float dh);
    bool ResetSelection();

    // Ghi file TSV. Tra ve so dong ghi duoc, -1 khi hong (ly do vao `err`).
    int Save(char* err, unsigned capacity);

    // Duong dan file dang dung (de log va de rig kiem).
    const char* FilePath();

    // Bang chung "da ap that": so luot ghi de tu luc khoi dong, va so dong bang dang giu.
    int AppliedCount();
    int TableRows();

    // Bo su kien chuot cua bo sua. Goi tu CUISystem::InjectInput TRUOC khi bom vao CEGUI.
    // Tra ve true = bo sua da nuot su kien, dung chuyen tiep.
    bool OnMouseDown(float x, float y, bool shift);
    bool OnMouseMove(float x, float y);
    bool OnMouseUp(float x, float y);

    // Phim. Tra ve true = da nuot.
    bool OnKey(int keyCode, bool shift, bool ctrl);

    // Mo khung ke tiep / truoc do trong danh sach khung hong (PgDn/PgUp).
    bool StepTarget(int delta);
}
