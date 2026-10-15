// CysUiViewer - initialisation: OGRE window + resources, image codecs, CEGUI (System, null script module, scheme),
// shutdown and window messages. CYS: new tool (2026-09-12). Keep this file ASCII.
#include "UiViewerApp.h"

#include <Ogre.h>
#include <OgreCodec.h>
#include <OgreDataStream.h>
#include <OgreImageCodec.h>
#include <OgreRenderQueueListener.h>

#include <CEGUI.h>
#include <CEGUIAnimateManager.h>
#include <CEGUIScriptModule.h>
#include <CEGUIXMLAttributes.h>
#include <CEGUIXMLHandler.h>
#include <CEGUIXMLParser.h>
#include <falagard/CEGUIFalWidgetLookManager.h>
#include <OgreCEGUIRenderer.h>

#include <wincodec.h>

#include <cstdio>
#include <cstring>

namespace cysui
{
    namespace
    {
        IWICImagingFactory* g_wic = NULL;
        std::vector<std::string> g_wicDecoded; // "ext\tresource name"

        std::string cguiText(const CEGUI::String& s) { return std::string(s.c_str()); }

        bool writeFileUtf8(const std::string& path, const std::string& text, bool bom)
        {
            FILE* f = std::fopen(path.c_str(), "wb");
            if (!f)
                return false;
            if (bom)
                std::fputs("\xEF\xBB\xBF", f);
            std::fwrite(text.data(), 1, text.size(), f);
            std::fclose(f);
            return true;
        }

        std::string xmlEscape(const std::string& s)
        {
            std::string o;
            for (size_t i = 0; i < s.size(); ++i)
            {
                switch (s[i])
                {
                case '&': o += "&amp;"; break;
                case '<': o += "&lt;"; break;
                case '>': o += "&gt;"; break;
                case '"': o += "&quot;"; break;
                default: o += s[i]; break;
                }
            }
            return o;
        }

        std::string fileSafe(const std::string& s)
        {
            std::string o;
            for (size_t i = 0; i < s.size(); ++i)
            {
                char c = s[i];
                o += ((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') || c == '.' ||
                      c == '-' || c == '_') ? c : '_';
            }
            return o;
        }

        std::string extOf(const std::string& name)
        {
            size_t p = name.find_last_of('.');
            return p == std::string::npos ? std::string() : lowerAscii(name.substr(p + 1));
        }

        // Layout <Event> handlers are recorded by CEGUI as ScriptFunctors; nothing is executed here.
        class NullScriptModule : public CEGUI::ScriptModule
        {
        public:
            NullScriptModule(void)
            {
                d_identifierString = CEGUI::String((const CEGUI::utf8*)"CysUiViewer null script module (layout events are not run)");
            }
            void executeScriptFile(const CEGUI::String&, const CEGUI::String&) {}
            int executeScriptGlobal(const CEGUI::String&) { return 0; }
            bool executeScriptedEventHandler(const CEGUI::String&, const CEGUI::EventArgs&) { return false; }
            void executeString(const CEGUI::String&) {}
        };

        // ---- scheme / font file collectors (CEGUI's own expat parser + resource provider)
        struct SchemeItem
        {
            CEGUI::String name, file, group;
            bool bitmap = false;
        };
        struct SchemeModule
        {
            CEGUI::String name;
            std::vector<CEGUI::String> factories;
        };
        struct SchemeMapping
        {
            CEGUI::String type, target, look;
        };
        struct SchemeData
        {
            CEGUI::String name;
            std::vector<SchemeItem> imagesets, imagesetsFromImage, fonts, looknfeels;
            std::vector<SchemeModule> modules;
            std::vector<std::pair<CEGUI::String, CEGUI::String> > aliases;
            std::vector<SchemeMapping> mappings;
            int unknown = 0;
        };

        class SchemeCollector : public CEGUI::XMLHandler
        {
        public:
            explicit SchemeCollector(SchemeData& d) : d_(d) {}
            void elementStart(const CEGUI::String& e, const CEGUI::XMLAttributes& a)
            {
                if (e == "GUIScheme")
                    d_.name = a.getValueAsString("Name");
                else if (e == "Imageset" || e == "ImagesetFromImage" || e == "Font" || e == "LookNFeel")
                {
                    SchemeItem it;
                    it.name = a.getValueAsString("Name");
                    it.file = a.getValueAsString("Filename");
                    it.group = a.getValueAsString("ResourceGroup");
                    if (e == "Imageset")
                        d_.imagesets.push_back(it);
                    else if (e == "ImagesetFromImage")
                        d_.imagesetsFromImage.push_back(it);
                    else if (e == "Font")
                    {
                        it.bitmap = a.getValueAsString("Type") == "Bitmap";
                        d_.fonts.push_back(it);
                    }
                    else
                        d_.looknfeels.push_back(it);
                }
                else if (e == "WindowSet")
                {
                    SchemeModule m;
                    m.name = a.getValueAsString("Filename");
                    d_.modules.push_back(m);
                }
                else if (e == "WindowFactory")
                {
                    if (!d_.modules.empty())
                        d_.modules.back().factories.push_back(a.getValueAsString("Name"));
                }
                else if (e == "WindowAlias")
                    d_.aliases.push_back(std::make_pair(a.getValueAsString("Alias"), a.getValueAsString("Target")));
                else if (e == "FalagardMapping")
                {
                    SchemeMapping m;
                    m.type = a.getValueAsString("WindowType");
                    m.target = a.getValueAsString("TargetType");
                    m.look = a.getValueAsString("LookNFeel");
                    d_.mappings.push_back(m);
                }
                else if (e != "FontBlinkTime" && e != "Imageset_bin")
                    ++d_.unknown;
            }

        private:
            SchemeData& d_;
        };

        struct FontEntry
        {
            std::map<std::string, std::string> attrs;
            std::string get(const char* k) const
            {
                std::map<std::string, std::string>::const_iterator it = attrs.find(k);
                return it == attrs.end() ? std::string() : it->second;
            }
        };

        class FontFileCollector : public CEGUI::XMLHandler
        {
        public:
            std::string root;
            std::vector<FontEntry> entries;
            void elementStart(const CEGUI::String& e, const CEGUI::XMLAttributes& a)
            {
                if (root.empty())
                    root = e.c_str();
                if (e == "Font")
                {
                    FontEntry f;
                    for (size_t i = 0; i < a.getCount(); ++i)
                        f.attrs[a.getName(i).c_str()] = a.getValue(i).c_str();
                    entries.push_back(f);
                }
            }
        };

        template <class It> int countOf(It it)
        {
            int n = 0;
            for (it.toStart(); !it.isAtEnd(); ++it)
                ++n;
            return n;
        }
    }

    // ------------------------------------------------------------------ WIC fallback image codec
    // Registered for jpg/png only when the engine has no codec for them (the x64 DevIL is built with IL_NO_JPG/PNG;
    // D3D9Texture::_loadNormTex decodes everything but .dds through Ogre codecs). Viewer-side only.
    class WicImageCodec : public Ogre::ImageCodec
    {
    public:
        explicit WicImageCodec(const Ogre::String& ext) : mExt(ext) {}
        Ogre::String getType(void) const { return mExt; }
        Ogre::DataStreamPtr code(Ogre::MemoryDataStreamPtr&, Ogre::Codec::CodecDataPtr&) const
        {
            OGRE_EXCEPT(Ogre::Exception::ERR_INTERNAL_ERROR, "decode only", "WicImageCodec::code");
        }
        void codeToFile(Ogre::MemoryDataStreamPtr&, const Ogre::String&, Ogre::Codec::CodecDataPtr&) const
        {
            OGRE_EXCEPT(Ogre::Exception::ERR_INTERNAL_ERROR, "decode only", "WicImageCodec::codeToFile");
        }
        DecodeResult decode(Ogre::DataStreamPtr& input) const
        {
            const std::string name = input->getName();
            Ogre::MemoryDataStream src(input);
            IWICStream* stream = NULL;
            IWICBitmapDecoder* decoder = NULL;
            IWICBitmapFrameDecode* frame = NULL;
            IWICFormatConverter* conv = NULL;
            UINT w = 0, h = 0;
            Ogre::MemoryDataStreamPtr out;
            HRESULT hr = g_wic ? g_wic->CreateStream(&stream) : E_FAIL;
            if (SUCCEEDED(hr))
                hr = stream->InitializeFromMemory((BYTE*)src.getPtr(), (DWORD)src.size());
            if (SUCCEEDED(hr))
                hr = g_wic->CreateDecoderFromStream(stream, NULL, WICDecodeMetadataCacheOnDemand, &decoder);
            if (SUCCEEDED(hr))
                hr = decoder->GetFrame(0, &frame);
            if (SUCCEEDED(hr))
                hr = g_wic->CreateFormatConverter(&conv);
            if (SUCCEEDED(hr))
                hr = conv->Initialize(frame, GUID_WICPixelFormat32bppBGRA, WICBitmapDitherTypeNone, NULL, 0.0,
                                      WICBitmapPaletteTypeCustom);
            if (SUCCEEDED(hr))
                hr = conv->GetSize(&w, &h);
            if (SUCCEEDED(hr) && w && h)
            {
                out = Ogre::MemoryDataStreamPtr(new Ogre::MemoryDataStream((size_t)w * h * 4));
                hr = conv->CopyPixels(NULL, w * 4, w * h * 4, out->getPtr());
            }
            if (conv) conv->Release();
            if (frame) frame->Release();
            if (decoder) decoder->Release();
            if (stream) stream->Release();
            if (FAILED(hr) || out.isNull())
                OGRE_EXCEPT(Ogre::Exception::ERR_INTERNAL_ERROR, "WIC cannot decode " + name, "WicImageCodec::decode");
            Ogre::ImageCodec::ImageData* data = new Ogre::ImageCodec::ImageData();
            data->width = w;
            data->height = h;
            data->depth = 1;
            data->size = w * h * 4;
            data->num_mipmaps = 0;
            data->flags = 0;
            data->format = Ogre::PF_A8R8G8B8; // little endian: B G R A in memory = WIC 32bppBGRA
            g_wicDecoded.push_back(mExt + "\t" + name);
            DecodeResult ret;
            ret.first = out;
            ret.second = Ogre::Codec::CodecDataPtr(data);
            return ret;
        }

    private:
        Ogre::String mExt;
    };

    // ------------------------------------------------------------------ GUI render hook
    // Own RENDER_QUEUE_OVERLAY listener instead of OgreCEGUIRenderer's, so that exceptions inside renderGUI (a
    // texture that cannot be loaded) are caught inside the OGRE frame.
    class GuiRenderListener : public Ogre::RenderQueueListener
    {
    public:
        GuiRenderListener(App* app, Ogre::RenderTarget* target) : mApp(app), mTarget(target) {}
        void renderQueueStarted(Ogre::uint8 id, const Ogre::String&, bool&)
        {
            if (id != Ogre::RENDER_QUEUE_OVERLAY)
                return;
            Ogre::RenderSystem* rs = Ogre::Root::getSingleton().getRenderSystem();
            Ogre::Viewport* vp = rs ? rs->_getViewport() : NULL;
            if (vp && vp->getTarget() == mTarget)
                mApp->renderGuiGuarded();
        }
        void renderQueueEnded(Ogre::uint8, const Ogre::String&, bool&) {}

    private:
        App* mApp;
        Ogre::RenderTarget* mTarget;
    };

    // ------------------------------------------------------------------ App
    App* App::s_current = NULL;

    App::App(const Options& opt)
        : m_opt(opt), m_writeSchemeReport(false), m_hwnd(NULL), m_logManager(NULL), m_root(NULL), m_window(NULL),
          m_scene(NULL), m_camera(NULL), m_viewport(NULL), m_listener(NULL), m_renderer(NULL), m_script(NULL),
          m_system(NULL), m_sheet(NULL), m_schemeLogEnd(0), m_dictLoaded(false), m_renderSeh(0), m_currentIndex(-1),
          m_shotRequested(false), m_reloadRequested(false)
    {
        s_current = this;
    }

    App::~App()
    {
        shutdown();
        s_current = NULL;
    }

    void App::say(const std::string& s)
    {
        std::printf("%s\n", s.c_str());
        std::fflush(stdout);
    }

    void App::note(const std::string& s)
    {
        m_schemeReport += s + "\n";
        say(s);
    }

    bool App::init(HWND hwnd, const WorkerPaths& paths, bool writeSchemeReport, std::string& error)
    {
        m_hwnd = hwnd;
        m_paths = paths;
        m_writeSchemeReport = writeSchemeReport;
        makeDirs(m_paths.runDir);
        makeDirs(joinPath(m_paths.runDir, "_gen"));
        try
        {
            return initEngine(hwnd, error) && initCegui(error);
        }
        catch (Ogre::Exception& e)
        {
            error = "OGRE: " + e.getFullDescription();
        }
        catch (CEGUI::Exception& e)
        {
            error = "CEGUI: " + cguiText(e.getMessage());
        }
        catch (std::exception& e)
        {
            error = e.what();
        }
        return false;
    }

    bool App::initEngine(HWND hwnd, std::string& error)
    {
        // Own log manager (Root then keeps it, OgreRoot.cpp:154): no stderr mirror of every line.
        const std::string ogreLog = joinPath(m_paths.runDir, "Ogre.log");
        m_logManager = new Ogre::LogManager();
        m_logManager->createLog(ogreLog, true, false, false);
        m_logManager->setLogDetail(Ogre::LL_NORMAL);
        m_root = new Ogre::Root("", "", ogreLog);
        m_root->loadRenderPlugins_D3D9(); // as WXRender RenderSystem.cpp; inner plugins are not needed for UI
        if (!m_root->getRenderSystem())
        {
            error = "no Direct3D9 render system (RenderSystem_Direct3D9.dll next to the exe?)";
            return false;
        }
        m_root->initialise(false);
        Ogre::NameValuePairList misc;
        misc["externalWindowHandle"] = Ogre::StringConverter::toString((unsigned int)(UINT_PTR)hwnd);
        misc["vsync"] = "false";
        misc["FSAA"] = "0";
        m_window = m_root->createRenderWindow("CysUiViewer", m_opt.width, m_opt.height, false, &misc);
        char buf[160];
        std::sprintf(buf, "render window %ux%u (requested %dx%d), D3D9", m_window->getWidth(), m_window->getHeight(),
                     m_opt.width, m_opt.height);
        note(buf);
        m_scene = m_root->createSceneManager(Ogre::ST_GENERIC, "CysUiViewer");
        m_camera = m_scene->createCamera("CysUiViewerCamera");
        m_viewport = m_window->addViewport(m_camera);
        m_viewport->setBackgroundColour(Ogre::ColourValue(m_opt.bg[0] / 255.0f, m_opt.bg[1] / 255.0f, m_opt.bg[2] / 255.0f));
        m_viewport->setOverlaysEnabled(true); // OgreCEGUIRenderer::doRender needs it
        // Only created queue groups are rendered (OgreSceneManager.cpp:1750) and clear() keeps them.
        m_scene->getRenderQueue()->getQueueGroup(Ogre::RENDER_QUEUE_OVERLAY);
        m_listener = new GuiRenderListener(this, m_window);
        m_scene->addRenderQueueListener(m_listener);
        addResourceLocations();
        registerCodecs();
        return true;
    }

    void App::addResourceLocations(void)
    {
        // As client_GL Bin\FairyResources.cfg: one non-recursive FileSystem location per folder in "General";
        // UI names carry their sub-folder ("Schema/...", "Common/x.dds") and are found by the in-order search
        // (OgreResourceGroupManager.cpp:579), so earlier locations win: UI roots, --tex, then texture folders.
        std::vector<std::string> locs = m_opt.uiRoots;
        locs.insert(locs.end(), m_opt.texDirs.begin(), m_opt.texDirs.end());
        std::vector<std::string> dataDirs(1, m_opt.dataDir);
        for (size_t i = 1; i < m_opt.uiRoots.size(); ++i)
        {
            std::string sib = parentDir(m_opt.uiRoots[i]);
            if (dirExists(joinPath(sib, "MaterialFolder")) && lowerAscii(sib) != lowerAscii(m_opt.dataDir))
                dataDirs.push_back(sib);
        }
        static const char* const folders[] = { "MaterialFolder", "Material2Folder", "Material3Folder",
                                               "Material4Folder", "Material5Folder", "Material6Folder",
                                               "Material7Folder", "Material8Folder" };
        for (size_t d = 0; d < dataDirs.size(); ++d)
            for (size_t f = 0; f < sizeof(folders) / sizeof(folders[0]); ++f)
                if (dirExists(joinPath(dataDirs[d], folders[f])))
                    locs.push_back(joinPath(dataDirs[d], folders[f]));
        Ogre::ResourceGroupManager& rgm = Ogre::ResourceGroupManager::getSingleton();
        std::set<std::string> seen;
        for (size_t i = 0; i < locs.size(); ++i)
        {
            if (!dirExists(locs[i]) || !seen.insert(lowerAscii(locs[i])).second)
                continue;
            rgm.addResourceLocation(locs[i], "FileSystem", "General", false);
            m_locations.push_back(locs[i]);
            note("resource location " + std::to_string(m_locations.size()) + ": " + acpToUtf8(locs[i]));
        }
        rgm.addResourceLocation(joinPath(m_paths.runDir, "_gen"), "FileSystem", "CysUiViewerGen", false);
    }

    void App::registerCodecs(void)
    {
        std::string engine;
        static const char* const all[] = { "dds", "tga", "jpg", "png", "bmp" };
        for (size_t i = 0; i < sizeof(all) / sizeof(all[0]); ++i)
        {
            bool has = true;
            try
            {
                Ogre::Codec::getCodec(all[i]);
            }
            catch (Ogre::Exception&)
            {
                has = false;
            }
            engine += std::string(all[i]) + (has ? "=yes " : "=NO ");
        }
        note("engine image codecs (Ogre::Codec; .dds textures go through D3DX): " + engine);
        if (!m_opt.wic)
        {
            note("WIC fallback codec: off (--no-wic): jpg/png textures without an engine codec get placeholders");
            return;
        }
        if (!g_wic && FAILED(CoCreateInstance(CLSID_WICImagingFactory, NULL, CLSCTX_INPROC_SERVER,
                                              IID_PPV_ARGS(&g_wic))))
            g_wic = NULL;
        if (!g_wic)
        {
            note("WIC fallback codec: unavailable (CoCreateInstance failed)");
            return;
        }
        std::string added;
        static const char* const wexts[] = { "jpg", "jpeg", "jpe", "png" };
        for (size_t i = 0; i < sizeof(wexts) / sizeof(wexts[0]); ++i)
        {
            bool has = true;
            try
            {
                Ogre::Codec::getCodec(wexts[i]);
            }
            catch (Ogre::Exception&)
            {
                has = false;
            }
            if (has && !m_opt.forceWic)
                continue;
            WicImageCodec* c = new WicImageCodec(wexts[i]);
            Ogre::Codec::registerCodec(c);
            m_codecs.push_back(c);
            added += std::string(wexts[i]) + " ";
        }
        note("WIC fallback codec (viewer only, NOT in the engine): " + (added.empty() ? std::string("not needed") : added));
    }

    bool App::initCegui(std::string& error)
    {
        (void)error;
        // Renderer without scene manager hook: GuiRenderListener calls renderGUI (see above).
        m_renderer = new CEGUI::OgreCEGUIRenderer(m_window, Ogre::RENDER_QUEUE_OVERLAY, false, 0);
        m_script = new NullScriptModule();
        // CEGUI::System(renderer, script, config) logs to "UISystem.log" in the current directory
        // (CEGUISystem.cpp:162), so the run folder becomes the current directory.
        SetCurrentDirectoryA(m_paths.runDir.c_str());
        m_system = new CEGUI::System(m_renderer, m_script, (const CEGUI::utf8*)"");
        m_logPath = joinPath(m_paths.runDir, "UISystem.log");
        CEGUI::LoggingLevel level = CEGUI::Standard;
        if (m_opt.logLevel == "errors") level = CEGUI::Errors;
        else if (m_opt.logLevel == "informative") level = CEGUI::Informative;
        else if (m_opt.logLevel == "insane") level = CEGUI::Insane;
        CEGUI::Logger::getSingleton().setLoggingLevel(level);
        m_system->getResourceProvider()->setDefaultResourceGroup("General"); // as CUISystem::Initial
        // CYS: exercise the engine's language selection with the same text code page.
        CEGUI::FontManager::getSingleton().setCodePage(m_opt.codePage);
        CEGUI::MouseCursor::getSingleton().hide();

        char buf[320];
        std::sprintf(buf, "CysUiViewer: UI text code page %d (%s)", m_opt.codePage,
                     m_opt.codePage == 65001 ? "UTF-8 end to end = UI_CEGUI with System_CodePage=65001"
                                             : "texts round-trip through this code page like the 0.85 client");
        CEGUI::Logger::getSingleton().logEvent((const CEGUI::utf8*)buf, CEGUI::Standard);
        note(buf);

        if (!m_opt.dictFile.empty())
        {
            std::string err;
            m_dictLoaded = m_text.loadDictionary(m_opt.dictFile, err);
            note(m_dictLoaded ? "dictionary: " + std::to_string(m_text.dictionarySize()) + " keys from " +
                                    acpToUtf8(m_opt.dictFile)
                              : "dictionary: " + err);
        }
        m_text.setCodePage(m_opt.codePage);
        if (loadInterfaceTable(m_opt.interfaceTable, m_windowNames))
            note("InterfaceEx: " + std::to_string(m_windowNames.size()) + " layouts from " + acpToUtf8(m_opt.interfaceTable));
        m_sample = sampleText(m_opt.sampleUtf8);

        note("scheme " + m_opt.scheme + " - " + (m_opt.gameScheme ? "game mode (SchemeManager::loadScheme)"
                                                                   : "robust mode (element by element)"));
        if (m_opt.gameScheme)
            loadSchemeGame();
        else
            loadSchemeRobust();

        // As CUISystem::Initial (UISystem.cpp:367-380): tooltip type, animations, background sheet (UIWindowMng.cpp:448).
        // CYS-HUD: same choice as UISystem.cpp:380 - the GL scheme maps TLBB_Tooltip, 0.85 had WoWLook/Tooltip.
        const char* tooltipType = CEGUI::WindowFactoryManager::getSingleton().isFactoryPresent("TLBB_Tooltip") ? "TLBB_Tooltip" : "WoWLook/Tooltip";
        try
        {
            m_system->setTooltip(tooltipType);
        }
        catch (CEGUI::Exception& e)
        {
            note(std::string("tooltip ") + tooltipType + " FAILED: " + cguiText(e.getMessage()));
        }
        try
        {
            new CEGUI::AnimateManager("schema\\wowanimate.xml");
            note("AnimateManager: schema\\wowanimate.xml loaded");
        }
        catch (CEGUI::Exception& e)
        {
            note("AnimateManager FAILED: " + cguiText(e.getMessage()));
        }
        m_sheet = CEGUI::WindowManager::getSingleton().createWindow("DefaultGUISheet", "__BACKGOUNDSHEET__");
        m_sheet->setMouseHollow(true);
        m_system->setGUISheet(m_sheet);
        finishSchemeReport();
        return true;
    }

    void App::loadSchemeGame(void)
    {
        try
        {
            CEGUI::SchemeManager::getSingleton().loadScheme(CEGUI::String(m_opt.scheme.c_str()));
            note("scheme loaded (game mode)");
        }
        catch (CEGUI::Exception& e)
        {
            note("SCHEME LOAD ABORTED (game mode): " + cguiText(e.getMessage()));
        }
    }

    void App::loadSchemeRobust(void)
    {
        SchemeData sd;
        SchemeCollector collector(sd);
        try
        {
            m_system->getXMLParser()->parseXMLFile(collector, CEGUI::String(m_opt.scheme.c_str()), "", "");
        }
        catch (CEGUI::Exception& e)
        {
            note("SCHEME PARSE FAILED: " + cguiText(e.getMessage()));
            return;
        }
        char buf[400];
        std::sprintf(buf, "scheme '%s': %d imagesets, %d fonts, %d looknfeel files, %d window sets, %d aliases, "
                     "%d falagard mappings, %d unknown elements", sd.name.c_str(), (int)sd.imagesets.size(),
                     (int)sd.fonts.size(), (int)sd.looknfeels.size(), (int)sd.modules.size(), (int)sd.aliases.size(),
                     (int)sd.mappings.size(), sd.unknown);
        note(buf);

        // ---- imagesets (textures load lazily at first draw, CEGUIImageset.cpp:266)
        CEGUI::ImagesetManager& ism = CEGUI::ImagesetManager::getSingleton();
        Ogre::ResourceGroupManager& rgm = Ogre::ResourceGroupManager::getSingleton();
        int ok = 0, failed = 0, missing = 0;
        std::map<std::string, int> byExt, missingByExt;
        std::string failList, missList;
        for (size_t i = 0; i < sd.imagesets.size(); ++i)
        {
            const SchemeItem& it = sd.imagesets[i];
            try
            {
                if (ism.isImagesetPresent(it.name))
                {
                    ++ok;
                    continue;
                }
                CEGUI::Imageset* is = ism.createImageset(it.file, it.group);
                if (is->getName() != it.name)
                    failList += "  " + cguiText(it.name) + ": file " + cguiText(it.file) + " defines imageset '" +
                                cguiText(is->getName()) + "'\n";
                ++ok;
                const std::string tex = cguiText(is->getTextureFilename());
                byExt[extOf(tex)]++;
                if (!tex.empty() && !rgm.resourceExists("General", tex))
                {
                    ++missing;
                    missingByExt[extOf(tex)]++;
                    missList += "  " + cguiText(it.name) + " -> " + tex + "\n";
                }
            }
            catch (CEGUI::Exception& e)
            {
                ++failed;
                failList += "  " + cguiText(it.name) + " (" + cguiText(it.file) + "): " + cguiText(e.getMessage()) + "\n";
            }
        }
        std::string exts;
        for (std::map<std::string, int>::const_iterator e = byExt.begin(); e != byExt.end(); ++e)
            exts += (exts.empty() ? "" : ", ") + e->first + " " + std::to_string(e->second);
        std::sprintf(buf, "imagesets: %d created, %d failed; texture files not found: %d", ok, failed, missing);
        note(std::string(buf) + "; textures by type: " + exts);
        if (!failList.empty())
            note("imageset failures:\n" + failList);
        if (!missList.empty())
            note("imagesets whose texture file is missing:\n" + missList);
        for (size_t i = 0; i < sd.imagesetsFromImage.size(); ++i)
        {
            const SchemeItem& it = sd.imagesetsFromImage[i];
            try
            {
                if (!ism.isImagesetPresent(it.name))
                    ism.createImagesetFromImageFile(it.name, it.file, it.group);
            }
            catch (CEGUI::Exception& e)
            {
                note("imageset-from-image " + cguiText(it.name) + " FAILED: " + cguiText(e.getMessage()));
            }
        }

        // ---- fonts (the 0.85 Font_xmlHandler knows <Font> only; client_GL files are <Fonts> with CodePage entries)
        CEGUI::FontManager& fm = CEGUI::FontManager::getSingleton();
        int fontsOk = 0, fontsAdapted = 0, fontsFailed = 0;
        for (size_t i = 0; i < sd.fonts.size(); ++i)
        {
            const SchemeItem& it = sd.fonts[i];
            if (fm.isFontPresent(it.name))
            {
                ++fontsOk;
                continue;
            }
            try
            {
                fm.createFont(it.bitmap ? CEGUI::Bitmap : CEGUI::FreeType, it.file, it.group);
                ++fontsOk;
                note("font " + cguiText(it.name) + ": loaded by the engine from " + cguiText(it.file));
            }
            catch (CEGUI::Exception& e)
            {
                const std::string msg = cguiText(e.getMessage());
                std::string how;
                if (!m_opt.strictFonts && adaptFont(it.name, it.file, it.group, how))
                {
                    ++fontsAdapted;
                    note("font " + cguiText(it.name) + ": ENGINE REJECTED " + cguiText(it.file) + " (" + msg +
                         "); viewer adapted it: " + how);
                }
                else
                {
                    ++fontsFailed;
                    note("font " + cguiText(it.name) + " FAILED: " + msg + (how.empty() ? "" : " / " + how));
                }
            }
        }
        std::sprintf(buf, "fonts: %d loaded by the engine, %d adapted by the viewer, %d failed%s", fontsOk,
                     fontsAdapted, fontsFailed, m_opt.strictFonts ? " (--strict-fonts)" : "");
        note(buf);
        if (m_system->getDefaultFont())
            note("default font: " + cguiText(m_system->getDefaultFont()->getName()));

        // ---- looknfeel
        CEGUI::WidgetLookManager& wlm = CEGUI::WidgetLookManager::getSingleton();
        int lnfOk = 0;
        for (size_t i = 0; i < sd.looknfeels.size(); ++i)
        {
            try
            {
                wlm.parseLookNFeelSpecification(sd.looknfeels[i].file, sd.looknfeels[i].group);
                ++lnfOk;
            }
            catch (CEGUI::Exception& e)
            {
                note("looknfeel " + cguiText(sd.looknfeels[i].file) + " FAILED: " + cguiText(e.getMessage()));
            }
        }
        note("looknfeel files: " + std::to_string(lnfOk) + " / " + std::to_string(sd.looknfeels.size()) + " parsed");

        // ---- window sets (CEGUI::FactoryModule equivalent)
        CEGUI::WindowFactoryManager& wfm = CEGUI::WindowFactoryManager::getSingleton();
        for (size_t i = 0; i < sd.modules.size(); ++i)
        {
            std::string dll = cguiText(sd.modules[i].name);
            if (!endsWithNoCase(dll, ".dll"))
                dll += ".dll";
            HMODULE h = LoadLibraryA(dll.c_str());
            if (!h)
            {
                note("window set " + dll + " FAILED to load (Win32 error " + std::to_string(GetLastError()) + ")");
                continue;
            }
            typedef CEGUI::uint (*RegisterAll)(void);
            typedef void (*RegisterOne)(const CEGUI::String&);
            RegisterAll regAll = (RegisterAll)GetProcAddress(h, "registerAllFactories");
            RegisterOne regOne = (RegisterOne)GetProcAddress(h, "registerFactory");
            try
            {
                if (sd.modules[i].factories.empty())
                {
                    if (regAll)
                        note("window set " + dll + ": " + std::to_string(regAll()) + " factories registered");
                    else
                        note("window set " + dll + ": no registerAllFactories export");
                }
                else if (regOne)
                {
                    for (size_t f = 0; f < sd.modules[i].factories.size(); ++f)
                        if (!wfm.isFactoryPresent(sd.modules[i].factories[f]))
                            regOne(sd.modules[i].factories[f]);
                }
            }
            catch (CEGUI::Exception& e)
            {
                note("window set " + dll + " registration FAILED: " + cguiText(e.getMessage()));
            }
        }
        for (size_t i = 0; i < sd.aliases.size(); ++i)
        {
            try
            {
                wfm.addWindowTypeAlias(sd.aliases[i].first, sd.aliases[i].second);
            }
            catch (CEGUI::Exception& e)
            {
                note("alias " + cguiText(sd.aliases[i].first) + " FAILED: " + cguiText(e.getMessage()));
            }
        }

        // ---- falagard mappings: the look and the base type must exist when a window of that type is created
        std::map<std::string, std::string> missingLooks, unknownTargets;
        int mapped = 0;
        for (size_t i = 0; i < sd.mappings.size(); ++i)
        {
            const SchemeMapping& m = sd.mappings[i];
            if (!wlm.isWidgetLookAvailable(m.look))
            {
                std::string& uses = missingLooks[cguiText(m.look)];
                uses += (uses.empty() ? "" : ", ") + cguiText(m.type);
            }
            if (!wfm.isFactoryPresent(m.target))
            {
                std::string& uses = unknownTargets[cguiText(m.target)];
                uses += (uses.empty() ? "" : ", ") + cguiText(m.type);
            }
            try
            {
                wfm.addFalagardWindowMapping(m.type, m.target, m.look);
                ++mapped;
            }
            catch (CEGUI::Exception& e)
            {
                note("mapping " + cguiText(m.type) + " FAILED: " + cguiText(e.getMessage()));
            }
        }
        note("falagard mappings: " + std::to_string(mapped) + " added; " + std::to_string(missingLooks.size()) +
             " looks missing, " + std::to_string(unknownTargets.size()) + " base types unknown");
        for (std::map<std::string, std::string>::const_iterator it = missingLooks.begin(); it != missingLooks.end(); ++it)
            note("  missing look " + it->first + "  <- window types: " + it->second);
        for (std::map<std::string, std::string>::const_iterator it = unknownTargets.begin(); it != unknownTargets.end(); ++it)
            note("  unknown base type " + it->first + "  <- window types: " + it->second);
    }

    bool App::adaptFont(const CEGUI::String& name, const CEGUI::String& file, const CEGUI::String& group,
                        std::string& how)
    {
        FontFileCollector fc;
        try
        {
            m_system->getXMLParser()->parseXMLFile(fc, file, "", group);
        }
        catch (CEGUI::Exception& e)
        {
            how = "cannot parse the font file: " + cguiText(e.getMessage());
            return false;
        }
        if (fc.entries.empty())
        {
            how = "no <Font> entry";
            return false;
        }
        // Prefer the modern client's UTF-8 entry (CodePage 65001 = Noto Sans SC), then 1258, then any single file.
        const FontEntry* pick = NULL;
        static const char* const prefs[] = { "65001", "1258" };
        for (size_t p = 0; p < 2 && !pick; ++p)
            for (size_t i = 0; i < fc.entries.size() && !pick; ++i)
                if (fc.entries[i].get("CodePage") == prefs[p] && fc.entries[i].get("Filename").find('|') == std::string::npos)
                    pick = &fc.entries[i];
        for (size_t i = 0; i < fc.entries.size() && !pick; ++i)
            if (fc.entries[i].get("Filename").find('|') == std::string::npos)
                pick = &fc.entries[i];
        if (!pick)
        {
            how = "every entry is a multi-file (a|b) font";
            return false;
        }
        const std::string type = pick->get("Type").empty() ? std::string("FreeType") : pick->get("Type");
        const std::string grp = pick->get("ResourceGroup").empty() ? std::string("General") : pick->get("ResourceGroup");
        const std::string size = pick->get("Size").empty() ? std::string("12") : pick->get("Size");
        std::string xml = "<?xml version=\"1.0\" ?>\n<Font Name=\"" + xmlEscape(cguiText(name)) + "\" Filename=\"" +
                          xmlEscape(pick->get("Filename")) + "\" ResourceGroup=\"" + xmlEscape(grp) + "\" Size=\"" +
                          xmlEscape(size) + "\"";
        static const char* const extra[] = { "NativeHorzRes", "NativeVertRes", "AutoScaled" };
        for (size_t i = 0; i < 3; ++i)
            if (!pick->get(extra[i]).empty())
                xml += std::string(" ") + extra[i] + "=\"" + xmlEscape(pick->get(extra[i])) + "\"";
        xml += " />\n";
        const std::string gen = "cysfont_" + fileSafe(cguiText(name)) + ".font";
        if (!writeFileUtf8(joinPath(joinPath(m_paths.runDir, "_gen"), gen), xml, false))
        {
            how = "cannot write " + gen;
            return false;
        }
        try
        {
            CEGUI::FontManager::getSingleton().createFont(type == "Bitmap" ? CEGUI::Bitmap : CEGUI::FreeType,
                                                          CEGUI::String(gen.c_str()), "CysUiViewerGen");
        }
        catch (CEGUI::Exception& e)
        {
            how = "the adapted entry failed too: " + cguiText(e.getMessage());
            return false;
        }
        how = "<" + fc.root + "> with " + std::to_string(fc.entries.size()) + " entries -> CodePage=" +
              pick->get("CodePage") + " " + type + " " + pick->get("Filename") + " size " + size;
        return true;
    }

    void App::finishSchemeReport(void)
    {
        unsigned long long end = 0;
        std::vector<std::string> errs = readLogErrors(m_logPath, 0, &end);
        m_schemeLogEnd = end;
        char buf[320];
        std::sprintf(buf, "after init: %d imagesets, %d fonts, %d window factories, %d falagard mappings; "
                     "CEGUI (Error) lines so far: %d",
                     countOf(CEGUI::ImagesetManager::getSingleton().getIterator()),
                     countOf(CEGUI::FontManager::getSingleton().getIterator()),
                     countOf(CEGUI::WindowFactoryManager::getSingleton().getIterator()),
                     countOf(CEGUI::WindowFactoryManager::getSingleton().getFalagardMappingIterator()), (int)errs.size());
        note(buf);
        if (!m_writeSchemeReport)
            return;
        std::string e;
        for (size_t i = 0; i < errs.size(); ++i)
            e += errs[i] + "\n";
        writeFileUtf8(joinPath(m_paths.runDir, "scheme_errors.txt"), e, false);
        writeFileUtf8(joinPath(m_paths.runDir, "scheme_report.txt"), "== init and scheme\n" + m_schemeReport, true);
    }

    void App::writeWorkerFiles(void)
    {
        std::string t;
        for (size_t i = 0; i < g_wicDecoded.size(); ++i)
            t += "wic\t" + g_wicDecoded[i] + "\n";
        for (std::set<std::string>::const_iterator it = m_placeholders.begin(); it != m_placeholders.end(); ++it)
            t += "placeholder\t-\t" + *it + "\n";
        writeFileUtf8(joinPath(m_paths.runDir, "textures.txt"), t, false);
        std::string d;
        const std::map<std::string, int>& miss = m_text.missingKeys();
        for (std::map<std::string, int>::const_iterator it = miss.begin(); it != miss.end(); ++it)
            d += it->first + "\t" + std::to_string(it->second) + "\n";
        writeFileUtf8(joinPath(m_paths.runDir, "dict_missing.txt"), d, false);
        std::string mk;
        const std::map<std::string, int>& markup = m_text.unknownMarkup();
        for (std::map<std::string, int>::const_iterator it = markup.begin(); it != markup.end(); ++it)
            mk += it->first + "\t" + std::to_string(it->second) + "\n";
        writeFileUtf8(joinPath(m_paths.runDir, "markup.txt"), mk, false);
    }

    void App::shutdown(void)
    {
        if (m_system)
        {
            try
            {
                if (CEGUI::AnimateManager::getSingletonPtr())
                    delete CEGUI::AnimateManager::getSingletonPtr();
                delete m_system;
            }
            catch (...)
            {
            }
            m_system = NULL;
            m_sheet = NULL;
        }
        delete m_script;
        m_script = NULL;
        delete m_renderer;
        m_renderer = NULL;
        if (m_scene && m_listener)
            m_scene->removeRenderQueueListener(m_listener);
        delete m_listener;
        m_listener = NULL;
        for (size_t i = 0; i < m_codecs.size(); ++i)
        {
            Ogre::Codec::unRegisterCodec(m_codecs[i]);
            delete m_codecs[i];
        }
        m_codecs.clear();
        if (m_root)
        {
            try
            {
                delete m_root;
            }
            catch (...)
            {
            }
            m_root = NULL;
        }
        delete m_logManager;
        m_logManager = NULL;
        if (g_wic)
        {
            g_wic->Release();
            g_wic = NULL;
        }
    }

    bool App::handleMessage(HWND, UINT msg, WPARAM wp, LPARAM lp, LRESULT& result)
    {
        if (!m_system)
            return false;
        try
        {
            switch (msg)
            {
            case WM_MOUSEMOVE:
                m_system->injectMousePosition((float)(short)LOWORD(lp), (float)(short)HIWORD(lp));
                break;
            case WM_LBUTTONDOWN: m_system->injectMouseButtonDown(CEGUI::LeftButton); break;
            case WM_LBUTTONUP: m_system->injectMouseButtonUp(CEGUI::LeftButton); break;
            case WM_RBUTTONDOWN: m_system->injectMouseButtonDown(CEGUI::RightButton); break;
            case WM_RBUTTONUP: m_system->injectMouseButtonUp(CEGUI::RightButton); break;
            case WM_MOUSEWHEEL: m_system->injectMouseWheelChange((float)(short)HIWORD(wp) / (float)WHEEL_DELTA); break;
            case WM_KEYDOWN:
                if (wp == VK_F12) m_shotRequested = true;
                else if (wp == VK_F5) m_reloadRequested = true;
                else if (wp == VK_ESCAPE) PostQuitMessage(0);
                else return false;
                break;
            default:
                return false;
            }
        }
        catch (CEGUI::Exception& e)
        {
            say("input: " + cguiText(e.getMessage()));
        }
        result = 0;
        return true;
    }
}
