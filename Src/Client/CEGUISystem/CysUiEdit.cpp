// CYS-UIEDIT 19/09/2026 — xem CysUiEdit.h cho thiet ke va ba tinh chat bat buoc.
#include "StdAfx.h"
#include "CysUiEdit.h"
#include "UIGlobal.h"

#include <CEGUIWindow.h>
#include <CEGUIWindowManager.h>
#include <CEGUISystem.h>
#include <CEGUILogger.h>
#include <CEGUIExceptions.h>

#include <map>
#include <string>
#include <vector>
#include <cstdio>
#include <cstring>
#include <cstdlib>

namespace
{
    const char* const kProp = "UnifiedAreaRect";
    const char* const kStatusWindow = "__cys_uiedit_status__";
    const char* const kMarkWindow = "__cys_uiedit_mark__";

    // ------------------------------------------------------------------ bien moi truong
    // Doc MOT lan roi nho. Bay da ghi trong DIEU-PHOI 19/09 muc 11: `CysSmokePhysicalMouseAllowed`
    // nho ket qua trong `static int` nen dat bien SAU khi tien trinh chay la vo tac dung ma khong
    // bao gi. Vi vay moi gia tri deu duoc ghi mot dong log ngay lan doc dau tien.
    bool EnvIs(const char* name, const char* want, bool fallback)
    {
        char value[8] = {0};
        const DWORD n = ::GetEnvironmentVariableA(name, value, sizeof(value));
        if (n == 0 || n >= sizeof(value)) return fallback;
        return strcmp(value, want) == 0;
    }

    void Log(const char* text)
    {
        try { CEGUI::Logger::getSingleton().logEvent((CEGUI::utf8*)text, CEGUI::Standard); }
        catch (...) {}
    }

    void LogErr(const char* text)
    {
        try { CEGUI::Logger::getSingleton().logEvent((CEGUI::utf8*)text, CEGUI::Errors); }
        catch (...) {}
    }

    // ------------------------------------------------------------------ duong dan file
    std::string DirOfModule()
    {
        char exe[MAX_PATH * 2] = {0};
        if (!::GetModuleFileNameA(NULL, exe, (DWORD)(sizeof(exe) - 1))) return std::string();
        std::string dir(exe);
        const std::string::size_type slash = dir.find_last_of("\\/");
        if (slash == std::string::npos) return std::string();
        dir.erase(slash);
        return dir;
    }

    // Game.exe nam trong Bin64; `Data` la thu muc anh em, tren mot cap (Build/world-gui/stage-*).
    std::string DataDir()
    {
        std::string bin = DirOfModule();
        if (bin.empty()) return std::string("Data");
        const std::string::size_type slash = bin.find_last_of("\\/");
        if (slash != std::string::npos) bin.erase(slash);
        return bin + "\\Data";
    }

    std::string g_filePath;

    const std::string& FilePathStr()
    {
        if (!g_filePath.empty()) return g_filePath;
        char over[MAX_PATH * 2] = {0};
        const DWORD n = ::GetEnvironmentVariableA("CYS_UIEDIT_FILE", over, (DWORD)(sizeof(over) - 1));
        if (n > 0 && n < sizeof(over) && over[0])
            g_filePath = over;
        else
            g_filePath = DataDir() + "\\InterfaceFolder\\CysUiEdit\\ui_layout_overrides.tsv";
        return g_filePath;
    }

    std::string TargetsPathStr()
    {
        std::string p = FilePathStr();
        const std::string::size_type slash = p.find_last_of("\\/");
        if (slash == std::string::npos) return std::string("ui_edit_targets.tsv");
        return p.substr(0, slash + 1) + "ui_edit_targets.tsv";
    }

    bool ReadWholeFile(const std::string& path, std::string& out)
    {
        FILE* fh = fopen(path.c_str(), "rb");
        if (!fh) return false;
        char buffer[8192];
        size_t got = 0;
        out.clear();
        while ((got = fread(buffer, 1, sizeof(buffer), fh)) > 0)
        {
            out.append(buffer, got);
            if (out.size() > 8u * 1024u * 1024u) { fclose(fh); return false; }
        }
        fclose(fh);
        if (out.compare(0, 3, "\xef\xbb\xbf") == 0) out.erase(0, 3);
        return true;
    }

    std::vector<std::string> SplitTab(const std::string& line)
    {
        std::vector<std::string> fields;
        std::string::size_type begin = 0;
        for (;;)
        {
            const std::string::size_type end = line.find('\t', begin);
            fields.push_back(line.substr(begin, end == std::string::npos ? end : end - begin));
            if (end == std::string::npos) return fields;
            begin = end + 1;
        }
    }

    void SplitLines(const std::string& text, std::vector<std::string>& out)
    {
        std::string::size_type begin = 0;
        while (begin < text.size())
        {
            std::string::size_type end = text.find('\n', begin);
            std::string line = text.substr(begin, end == std::string::npos ? end : end - begin);
            begin = (end == std::string::npos) ? text.size() : end + 1;
            if (!line.empty() && line[line.size() - 1] == '\r') line.erase(line.size() - 1);
            out.push_back(line);
        }
    }

    // ------------------------------------------------------------------ bang de
    struct Row
    {
        std::string layout;   // *.layout.xml (chi de doc cho de, khoa la ten window)
        std::string value;    // UnifiedAreaRect nguoi dung da keo
        std::string origin;   // UnifiedAreaRect goc cua layout (de biet delta va de hoan tac)
        bool dirty;
        Row() : dirty(false) {}
    };

    typedef std::map<std::string, Row> Table;

    Table  g_table;
    bool   g_loaded = false;
    int    g_applied = 0;    // tong so window da bi ghi de, de nghiem thu
    int    g_seenRows = 0;

    void LoadTable()
    {
        if (g_loaded) return;
        g_loaded = true;
        std::string text;
        if (!ReadWholeFile(FilePathStr(), text))
        {
            char line[MAX_PATH * 3];
            _snprintf(line, sizeof(line) - 1, "CYS-UIEDIT: chua co file de, khong ap gi (%s)", FilePathStr().c_str());
            line[sizeof(line) - 1] = 0;
            Log(line);
            return;
        }
        std::vector<std::string> lines;
        SplitLines(text, lines);
        for (size_t i = 0; i < lines.size(); ++i)
        {
            const std::string& raw = lines[i];
            if (raw.empty() || raw[0] == '#') continue;
            const std::vector<std::string> f = SplitTab(raw);
            // layout \t window \t prop \t value [\t origin]
            if (f.size() < 4) continue;
            if (f[2] != kProp) continue;         // ban v1 chi hieu UnifiedAreaRect
            if (f[1].empty() || f[3].empty()) continue;
            Row row;
            row.layout = f[0];
            row.value = f[3];
            row.origin = (f.size() >= 5) ? f[4] : std::string();
            g_table[f[1]] = row;
            ++g_seenRows;
        }
        char line[256];
        _snprintf(line, sizeof(line) - 1, "CYS-UIEDIT: doc %d dong de tu file", g_seenRows);
        line[sizeof(line) - 1] = 0;
        Log(line);
    }

    // ------------------------------------------------------------------ trang thai bo sua
    int          g_mode = 0;
    std::string  g_selected;
    bool         g_dragging = false;
    bool         g_sizing = false;
    float        g_lastX = 0.0f, g_lastY = 0.0f;
    std::vector<std::pair<std::string, std::string> > g_targets;   // layout, window
    int          g_targetIdx = -1;
    bool         g_targetsLoaded = false;
    CysUiEdit::OpenWindowFn g_openWindow = NULL;

    CEGUI::Window* FindWindow(const char* name)
    {
        if (!name || !*name) return NULL;
        try
        {
            CEGUI::WindowManager& wm = CEGUI::WindowManager::getSingleton();
            if (!wm.isWindowPresent((CEGUI::utf8*)name)) return NULL;
            return wm.getWindow((CEGUI::utf8*)name);
        }
        catch (CEGUI::Exception&) { return NULL; }
    }

    // Doc thuoc tinh mot cach an toan (window co the khong co thuoc tinh do).
    bool GetProp(CEGUI::Window* w, std::string& out)
    {
        if (!w) return false;
        try { out = w->getProperty((CEGUI::utf8*)kProp).c_str(); return true; }
        catch (CEGUI::Exception&) { return false; }
    }

    bool SetProp(CEGUI::Window* w, const std::string& value)
    {
        if (!w) return false;
        try { w->setProperty((CEGUI::utf8*)kProp, (CEGUI::utf8*)value.c_str()); return true; }
        catch (CEGUI::Exception&) { return false; }
    }

    // "{{ls,lo},{ts,to},{rs,ro},{bs,bo}}" -> 8 so. Dung dung dinh dang cua
    // CEGUIWindowProperties.h:1536 (UnifiedAreaRect).
    bool ParseArea(const std::string& text, float out[8])
    {
        int found = 0;
        const char* p = text.c_str();
        while (*p && found < 8)
        {
            if ((*p >= '0' && *p <= '9') || *p == '-' || *p == '+' || *p == '.')
            {
                char* end = NULL;
                const double v = strtod(p, &end);
                if (end == p) return false;
                out[found++] = (float)v;
                p = end;
            }
            else ++p;
        }
        return found == 8;
    }

    std::string FormatArea(const float v[8])
    {
        char buffer[256];
        _snprintf(buffer, sizeof(buffer) - 1, "{{%.6f,%.6f},{%.6f,%.6f},{%.6f,%.6f},{%.6f,%.6f}}",
                  v[0], v[1], v[2], v[3], v[4], v[5], v[6], v[7]);
        buffer[sizeof(buffer) - 1] = 0;
        return std::string(buffer);
    }

    // Ghi mot thay doi vao bang, nho gia tri goc lan dau.
    void Remember(const std::string& name, CEGUI::Window* w, const std::string& newValue)
    {
        Table::iterator it = g_table.find(name);
        if (it == g_table.end())
        {
            Row row;
            std::string origin;
            if (GetProp(w, origin)) row.origin = origin;
            row.value = newValue;
            row.dirty = true;
            g_table[name] = row;
        }
        else
        {
            if (it->second.origin.empty())
            {
                std::string origin;
                if (GetProp(w, origin)) it->second.origin = origin;
            }
            it->second.value = newValue;
            it->second.dirty = true;
        }
    }

    // ------------------------------------------------------------------ bang trang thai + vien chon
    // CEGUI window tao luc chay — KHONG phai layout moi, khong sua file nao. Chi ton tai khi
    // che do sua dang bat; SetMode(0) huy no.
    CEGUI::Window* EnsureOverlay(const char* name, const char* type)
    {
        CEGUI::Window* w = FindWindow(name);
        if (w) return w;
        try
        {
            CEGUI::WindowManager& wm = CEGUI::WindowManager::getSingleton();
            w = wm.createWindow((CEGUI::utf8*)type, (CEGUI::utf8*)name);
            if (!w) return NULL;
            CEGUI::Window* sheet = CEGUI::System::getSingleton().getGUISheet();
            if (!sheet) { wm.destroyWindow(w); return NULL; }
            sheet->addChildWindow(w);
            w->setAlwaysOnTop(true);
            w->setEnabled(false);          // khong an su kien chuot cua game
            w->setMouseHollow(true);
            w->setMouseLButtonHollow(true);
            w->setMouseRButtonHollow(true);
            return w;
        }
        catch (CEGUI::Exception& e)
        {
            LogErr((CEGUI::String((CEGUI::utf8*)"CYS-UIEDIT: khong tao duoc overlay: ") + e.getMessage()).c_str());
            return NULL;
        }
    }

    void DestroyOverlay(const char* name)
    {
        CEGUI::Window* w = FindWindow(name);
        if (!w) return;
        try { CEGUI::WindowManager::getSingleton().destroyWindow(w); }
        catch (CEGUI::Exception&) {}
    }

    void UpdateStatus(const char* extra)
    {
        if (!g_mode) return;
        CEGUI::Window* status = EnsureOverlay(kStatusWindow, "TLBB_SimpleText");
        if (!status) return;
        try
        {
            status->setProperty((CEGUI::utf8*)kProp,
                (CEGUI::utf8*)"{{0.000000,4.000000},{0.000000,4.000000},{1.000000,-4.000000},{0.000000,22.000000}}");
        }
        catch (CEGUI::Exception&) {}
        char text[512];
        if (g_selected.empty())
            _snprintf(text, sizeof(text) - 1,
                      "[SUA KHUNG] chua chon. Ctrl+trai = chon | keo = di | Shift+keo = co dan | mui ten = 1px | Ctrl+S = luu | PgUp/PgDn = khung hong | F11 = tat. %s",
                      extra ? extra : "");
        else
        {
            float rect[4] = {0.0f, 0.0f, 0.0f, 0.0f};
            CEGUI::Window* w = FindWindow(g_selected.c_str());
            if (w)
            {
                try
                {
                    const CEGUI::Rect r = w->getUnclippedPixelRect();
                    rect[0] = r.d_left; rect[1] = r.d_top;
                    rect[2] = r.getWidth(); rect[3] = r.getHeight();
                }
                catch (CEGUI::Exception&) {}
            }
            _snprintf(text, sizeof(text) - 1, "[SUA KHUNG] %s  x=%.0f y=%.0f w=%.0f h=%.0f  (%d dong cho luu) %s",
                      g_selected.c_str(), rect[0], rect[1], rect[2], rect[3], (int)g_table.size(), extra ? extra : "");
        }
        text[sizeof(text) - 1] = 0;
        try { status->setText((CEGUI::utf8*)text); }
        catch (CEGUI::Exception&) {}
        try { status->show(); } catch (CEGUI::Exception&) {}
    }

    // Vien danh dau widget dang chon: mot SimpleText rong dat dung o do, de nguoi dung thay minh
    // dang keo cai gi. Dung StaticImage NULL de khong ve chu.
    void UpdateMark()
    {
        CEGUI::Window* mark = FindWindow(kMarkWindow);
        if (g_selected.empty())
        {
            if (mark) { try { mark->hide(); } catch (CEGUI::Exception&) {} }
            return;
        }
        CEGUI::Window* target = FindWindow(g_selected.c_str());
        if (!target) return;
        if (!mark) mark = EnsureOverlay(kMarkWindow, "TLBB_SimpleText");
        if (!mark) return;
        try
        {
            const CEGUI::Rect r = target->getUnclippedPixelRect();
            char area[256];
            _snprintf(area, sizeof(area) - 1, "{{0.000000,%.6f},{0.000000,%.6f},{0.000000,%.6f},{0.000000,%.6f}}",
                      r.d_left, r.d_top, r.d_right, r.d_bottom);
            area[sizeof(area) - 1] = 0;
            mark->setProperty((CEGUI::utf8*)kProp, (CEGUI::utf8*)area);
            mark->setText((CEGUI::utf8*)"[  ]");
            mark->show();
        }
        catch (CEGUI::Exception&) {}
    }

    // ------------------------------------------------------------------ danh sach khung hong
    void LoadTargets()
    {
        if (g_targetsLoaded) return;
        g_targetsLoaded = true;
        std::string text;
        if (!ReadWholeFile(TargetsPathStr(), text)) return;
        std::vector<std::string> lines;
        SplitLines(text, lines);
        for (size_t i = 0; i < lines.size(); ++i)
        {
            if (lines[i].empty() || lines[i][0] == '#') continue;
            const std::vector<std::string> f = SplitTab(lines[i]);
            if (f.size() < 2 || f[0].empty() || f[1].empty()) continue;
            g_targets.push_back(std::make_pair(f[0], f[1]));
        }
        char line[128];
        _snprintf(line, sizeof(line) - 1, "CYS-UIEDIT: danh sach khung hong: %d muc", (int)g_targets.size());
        line[sizeof(line) - 1] = 0;
        Log(line);
    }
}

// ====================================================================== API

namespace CysUiEdit
{
    bool Armed()
    {
        static int cached = -1;
        if (cached < 0)
        {
            cached = EnvIs("CYS_UIEDIT", "1", false) ? 1 : 0;
            if (cached)
            {
                char line[MAX_PATH * 3];
                _snprintf(line, sizeof(line) - 1, "CYS-UIEDIT: BAT (CYS_UIEDIT=1), file de = %s", FilePathStr().c_str());
                line[sizeof(line) - 1] = 0;
                Log(line);
            }
        }
        return cached == 1;
    }

    void SetOpenWindowFn(OpenWindowFn fn) { g_openWindow = fn; }

    const char* FilePath() { return FilePathStr().c_str(); }

    int AppliedCount() { return g_applied; }
    int TableRows() { return (int)g_table.size(); }

    int ApplyTo(CEGUI::Window* root, const char* layoutFile)
    {
        static int applyOn = -1;
        if (applyOn < 0)
        {
            applyOn = EnvIs("CYS_UIEDIT_APPLY", "0", false) ? 0 : 1;
            if (!applyOn) Log("CYS-UIEDIT: CYS_UIEDIT_APPLY=0 — KHONG ap de (luot doi chung)");
        }
        if (!applyOn || !root) return 0;
        LoadTable();
        if (g_table.empty()) return 0;

        int changed = 0;
        // Duyet cay theo chieu rong, khong de quy (mot so layout long rat sau).
        std::vector<CEGUI::Window*> stack;
        stack.push_back(root);
        while (!stack.empty())
        {
            CEGUI::Window* w = stack.back();
            stack.pop_back();
            if (!w) continue;
            std::string name;
            try { name = w->getName().c_str(); } catch (CEGUI::Exception&) { name.clear(); }
            if (!name.empty())
            {
                Table::iterator it = g_table.find(name);
                if (it != g_table.end())
                {
                    if (it->second.origin.empty())
                    {
                        std::string origin;
                        if (GetProp(w, origin)) it->second.origin = origin;
                    }
                    if (it->second.layout.empty() && layoutFile) it->second.layout = layoutFile;
                    if (SetProp(w, it->second.value)) { ++changed; ++g_applied; }
                }
            }
            const unsigned int count = w->getChildCount();
            for (unsigned int i = 0; i < count; ++i) stack.push_back(w->getChildAtIdx(i));
        }
        return changed;
    }

    int Mode() { return g_mode; }

    bool SetMode(int on)
    {
        if (!Armed()) return false;
        const int want = on ? 1 : 0;
        if (want == g_mode) return true;
        g_mode = want;
        if (g_mode)
        {
            LoadTable();
            LoadTargets();
            UpdateStatus("");
            UpdateMark();
            Log("CYS-UIEDIT: che do sua BAT");
        }
        else
        {
            // Tat = khong con mot pixel nao cua bo sua tren man hinh.
            DestroyOverlay(kStatusWindow);
            DestroyOverlay(kMarkWindow);
            g_dragging = false;
            g_sizing = false;
            Log("CYS-UIEDIT: che do sua TAT");
        }
        return true;
    }

    bool Select(const char* windowName)
    {
        if (!Armed()) return false;
        if (!windowName || !*windowName) { g_selected.clear(); UpdateMark(); UpdateStatus(""); return true; }
        CEGUI::Window* w = FindWindow(windowName);
        if (!w) return false;
        g_selected = windowName;
        // Nho gia tri goc ngay luc chon, truoc khi nguoi dung keo.
        Table::iterator it = g_table.find(g_selected);
        if (it == g_table.end() || it->second.origin.empty())
        {
            std::string origin;
            if (GetProp(w, origin))
            {
                if (it == g_table.end())
                {
                    Row row; row.origin = origin; row.value = origin; row.dirty = false;
                    g_table[g_selected] = row;
                }
                else it->second.origin = origin;
            }
        }
        UpdateMark();
        UpdateStatus("");
        return true;
    }

    const char* Selected() { return g_selected.c_str(); }

    bool GetRect(const char* windowName, float out[4])
    {
        CEGUI::Window* w = FindWindow(windowName);
        if (!w || !out) return false;
        try
        {
            const CEGUI::Rect r = w->getUnclippedPixelRect();
            out[0] = r.d_left; out[1] = r.d_top; out[2] = r.getWidth(); out[3] = r.getHeight();
            return true;
        }
        catch (CEGUI::Exception&) { return false; }
    }

    static bool Nudge(float dl, float dt, float dr, float db)
    {
        if (!Armed() || g_selected.empty()) return false;
        CEGUI::Window* w = FindWindow(g_selected.c_str());
        if (!w) return false;
        std::string current;
        if (!GetProp(w, current)) return false;
        float v[8] = {0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f};
        if (!ParseArea(current, v)) return false;
        v[1] += dl; v[3] += dt; v[5] += dr; v[7] += db;
        const std::string next = FormatArea(v);
        if (!SetProp(w, next)) return false;
        Remember(g_selected, w, next);
        UpdateMark();
        UpdateStatus("");
        return true;
    }

    bool MoveBy(float dx, float dy) { return Nudge(dx, dy, dx, dy); }
    bool SizeBy(float dw, float dh) { return Nudge(0.0f, 0.0f, dw, dh); }

    bool ResetSelection()
    {
        if (!Armed() || g_selected.empty()) return false;
        Table::iterator it = g_table.find(g_selected);
        if (it == g_table.end() || it->second.origin.empty()) return false;
        CEGUI::Window* w = FindWindow(g_selected.c_str());
        if (!SetProp(w, it->second.origin)) return false;
        it->second.value = it->second.origin;
        it->second.dirty = true;
        UpdateMark();
        UpdateStatus("(da tra ve goc)");
        return true;
    }

    int Save(char* err, unsigned capacity)
    {
        if (err && capacity) err[0] = 0;
        const std::string path = FilePathStr();
        // Tao thu muc chua file neu chua co (khong dung shell API de khong them phu thuoc).
        const std::string::size_type slash = path.find_last_of("\\/");
        if (slash != std::string::npos)
        {
            const std::string dir = path.substr(0, slash);
            ::CreateDirectoryA(dir.c_str(), NULL);   // that bai vi da ton tai la binh thuong
        }
        FILE* fh = fopen(path.c_str(), "wb");
        if (!fh)
        {
            if (err && capacity)
            {
                _snprintf(err, capacity - 1, "khong mo duoc de ghi: %s", path.c_str());
                err[capacity - 1] = 0;   // _snprintf khong tu ket NUL khi day
            }
            return -1;
        }
        fprintf(fh, "# CYS-UIEDIT v1 - vi tri/kich thuoc widget do nguoi dung keo tay trong game.\n");
        fprintf(fh, "# Doc luc nap layout (CUIWindowItem::LoadWindow) va ghi de thuoc tinh CEGUI.\n");
        fprintf(fh, "# KHONG sua *.layout.xml: build_canonical_cy.py dung lai ca cay InterfaceFolder tu .axp cua CY.\n");
        fprintf(fh, "# layout\twindow\tprop\tvalue\tgoc\n");
        int rows = 0;
        for (Table::const_iterator it = g_table.begin(); it != g_table.end(); ++it)
        {
            // Chi ghi dong that su khac gia tri goc: bang se khong phinh vi nhung lan chon roi bo.
            if (it->second.value.empty()) continue;
            if (!it->second.origin.empty() && it->second.value == it->second.origin) continue;
            fprintf(fh, "%s\t%s\t%s\t%s\t%s\n",
                    it->second.layout.c_str(), it->first.c_str(), kProp,
                    it->second.value.c_str(), it->second.origin.c_str());
            ++rows;
        }
        fclose(fh);
        char line[MAX_PATH * 3];
        _snprintf(line, sizeof(line) - 1, "CYS-UIEDIT: da luu %d dong vao %s", rows, path.c_str());
        line[sizeof(line) - 1] = 0;
        Log(line);
        return rows;
    }

    // ------------------------------------------------------------------ chuot
    bool OnMouseDown(float x, float y, bool shift)
    {
        if (!Armed() || !g_mode) return false;
        // Ctrl = chon widget duoi con tro. Khong Ctrl thi khong dung gi tren duong chuot binh thuong.
        const bool ctrl = (::GetKeyState(VK_CONTROL) & 0x8000) != 0;
        if (ctrl)
        {
            CEGUI::Window* w = NULL;
            try { w = CEGUI::System::getSingleton().getTargetWindow(CEGUI::Point(x, y)); }
            catch (CEGUI::Exception&) { w = NULL; }
            if (w)
            {
                std::string name;
                try { name = w->getName().c_str(); } catch (CEGUI::Exception&) {}
                // Bo qua chinh overlay cua bo sua.
                if (!name.empty() && name != kStatusWindow && name != kMarkWindow)
                {
                    Select(name.c_str());
                    g_dragging = true;
                    g_sizing = shift;
                    g_lastX = x; g_lastY = y;
                    return true;
                }
            }
            return true;    // Ctrl+trai trong che do sua khong duoc roi xuong game
        }
        if (!g_selected.empty())
        {
            // Bat dau keo khi bam trong chinh widget dang chon.
            float rect[4] = {0.0f, 0.0f, 0.0f, 0.0f};
            if (GetRect(g_selected.c_str(), rect) &&
                x >= rect[0] && x <= rect[0] + rect[2] && y >= rect[1] && y <= rect[1] + rect[3])
            {
                g_dragging = true;
                g_sizing = shift;
                g_lastX = x; g_lastY = y;
                return true;
            }
        }
        return false;
    }

    bool OnMouseMove(float x, float y)
    {
        if (!Armed() || !g_mode || !g_dragging) return false;
        const float dx = x - g_lastX;
        const float dy = y - g_lastY;
        g_lastX = x; g_lastY = y;
        if (dx == 0.0f && dy == 0.0f) return true;
        if (g_sizing) SizeBy(dx, dy); else MoveBy(dx, dy);
        return true;
    }

    bool OnMouseUp(float, float)
    {
        if (!Armed() || !g_mode || !g_dragging) return false;
        g_dragging = false;
        g_sizing = false;
        UpdateStatus("");
        return true;
    }

    // ------------------------------------------------------------------ phim
    bool OnKey(int keyCode, bool shift, bool ctrl)
    {
        if (!Armed()) return false;
        // F11 = 0x57 (KC_F11, TDInputSystem.h:93). F1..F10 la thanh ky nang, F12 la an nguoi choi.
        if (keyCode == 0x57) { SetMode(g_mode ? 0 : 1); return true; }
        if (!g_mode) return false;
        const float step = shift ? 10.0f : 1.0f;
        switch (keyCode)
        {
        case 0xCB: return ctrl ? SizeBy(-step, 0.0f) : MoveBy(-step, 0.0f);   // KC_LEFT
        case 0xCD: return ctrl ? SizeBy(step, 0.0f)  : MoveBy(step, 0.0f);    // KC_RIGHT
        case 0xC8: return ctrl ? SizeBy(0.0f, -step) : MoveBy(0.0f, -step);   // KC_UP
        case 0xD0: return ctrl ? SizeBy(0.0f, step)  : MoveBy(0.0f, step);    // KC_DOWN
        case 0x1F:                                                            // KC_S
            if (ctrl)
            {
                char err[256] = {0};
                const int rows = Save(err, sizeof(err));
                char note[320];
                if (rows < 0) _snprintf(note, sizeof(note) - 1, "(LUU HONG: %s)", err);
                else          _snprintf(note, sizeof(note) - 1, "(da luu %d dong)", rows);
                note[sizeof(note) - 1] = 0;
                UpdateStatus(note);
                return true;
            }
            return false;
        case 0xD3: return ResetSelection();                                   // KC_DELETE
        case 0xC9: return StepTarget(-1);                                     // KC_PGUP
        case 0xD1: return StepTarget(1);                                      // KC_PGDOWN
        default: break;
        }
        return false;
    }

    bool StepTarget(int delta)
    {
        if (!Armed() || !g_mode) return false;
        LoadTargets();
        if (g_targets.empty())
        {
            UpdateStatus("(chua co danh sach khung hong: thieu ui_edit_targets.tsv)");
            return true;
        }
        const int n = (int)g_targets.size();
        g_targetIdx = (g_targetIdx + delta) % n;
        if (g_targetIdx < 0) g_targetIdx += n;
        const std::string& layoutName = g_targets[g_targetIdx].first;
        const std::string& windowName = g_targets[g_targetIdx].second;
        const bool opened = g_openWindow ? g_openWindow(layoutName.c_str()) : false;
        Select(windowName.c_str());
        char note[320];
        _snprintf(note, sizeof(note) - 1, "(%d/%d %s%s)", g_targetIdx + 1, n, layoutName.c_str(),
                  opened ? "" : " - KHONG MO DUOC");
        note[sizeof(note) - 1] = 0;
        UpdateStatus(note);
        return true;
    }
}
