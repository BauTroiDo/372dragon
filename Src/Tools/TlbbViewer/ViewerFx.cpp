// TlbbViewer - fx-audit (CYS, 2026-09-13): runtime census dump (--fx-census) and deterministic effect sheets
// (--fx-sheet). Commands, file formats and the defect list: Docs/specs/render/07-fx-audit_vi.md; tools in Tools/fx.
//
// --fx-census <dir> writes what the REAL runtime holds after parsing the data (OgreMain particle factories,
// Plugin_ParticleFX2, WXCore effect/skill parsers and the CYS affectors/elements):
//   dict.tsv        every registered type and its parameter dictionary (what setParameter accepts)
//   ptemplates.tsv  particle templates (renderer, material, quota, emitter/affector types, material exists)
//   pparams.tsv     their parameter values that differ from a fresh instance of the same type
//   effects.tsv     effect templates, elements and their non-default values
//   skills.tsv      skills and their sub-blocks (AnimEffect, Ribbon, Sound, SceneLight, CameraShake, ComplexBlur)
//   passes.tsv      material passes (blend factors, depth, lighting, alpha reject, programs)
//   textures.tsv    texture references of every pass with runtime existence
//   resources.tsv   resource names per group
// The per-line rejections are in census.log (full detail, file:line). Tools/fx/fx_census.py joins it all with the
// data files (per-occurrence counts, examples, usage weight).
//
// --fx-sheet <list> renders every item twice with the same seed: a pre-pass collects the union of the bounds at the
// capture times (camera fit), then the capture pass writes one PNG per capture time and background and measures the
// cost around t = 1 s (CPU update = frame listeners + controllers, render submit, GPU-inclusive frame via an event
// query, D3D9 draw calls counted in this process, particles).
#include "ViewerApp.h"

#include <OgreRoot.h>
#include <OgreRenderWindow.h>
#include <OgreCamera.h>
#include <OgreViewport.h>
#include <OgreSceneManager.h>
#include <OgreSceneNode.h>
#include <OgreEntity.h>
#include <OgreMaterialManager.h>
#include <OgreMaterial.h>
#include <OgreTechnique.h>
#include <OgrePass.h>
#include <OgreTextureUnitState.h>
#include <OgreTextureManager.h>
#include <OgreResourceGroupManager.h>
#include <OgreParticleSystemManager.h>
#include <OgreParticleSystem.h>
#include <OgreParticleEmitter.h>
#include <OgreParticleEmitterFactory.h>
#include <OgreParticleAffector.h>
#include <OgreParticleAffectorFactory.h>
#include <OgreParticleSystemRenderer.h>
#include <OgreControllerManager.h>
#include <OgreStringConverter.h>
#include <OgreException.h>
#include <OgreLogManager.h>
#include <OgreArchive.h>
#include <OgreArchiveFactory.h>
#include <OgreArchiveManager.h>
#include <OgreDataStream.h>
#include <OgreString.h>

#include "Core/WXSystem.h"
#include "ModelSystem/WXLogicModel.h"
#include "ModelSystem/WXLogicModelManager.h"
#include "EffectSystem/WXEffectManager.h"
#include "EffectSystem/WXEffect.h"
#include "EffectSystem/WXEffectBasic.h"
#include "EffectSystem/WXEffectElement.h"
#include "EffectSystem/WXEffectElementFactory.h"
#include "EffectSystem/WXSkill.h"
#include "EffectSystem/WXAnimationEffectInfo.h"
#include "EffectSystem/WXAnimationRibbon.h"
#include "EffectSystem/WXAnimationSound.h"
#include "EffectSystem/WXAnimationSceneLightInfo.h"
#include "CYS/Effects/WXSkillCameraEffects.h"

#include <d3d9.h>

#include <algorithm>
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <map>
#include <set>

namespace tlbbv
{
    //=======================================================================
    struct ViewerApp::FxFrameStats
    {
        double updateMs;   // frame listeners + controllers (effects, particle systems, animations)
        double renderMs;   // render targets + window update (culling, particle geometry, D3D submission)
        double gpuMs;      // from the end of the submission until the GPU finished the frame (event query)
        size_t draws;      // D3D9 Draw*Primitive* calls in this frame
        size_t faces;      // RenderTarget::getTriangleCount
    };

    namespace
    {
        const char* const FX_SCRATCH = "__cys_fx_census__";

        void fxLog(const std::string& text)
        {
            if (Ogre::LogManager::getSingletonPtr())
                Ogre::LogManager::getSingleton().logMessage(text, Ogre::LML_CRITICAL);
        }

        void fxReport(const std::string& text)
        {
            out(text);
            fxLog(text);
        }

        void fxError(const std::string& text)
        {
            err(text);
            fxLog(text);
        }

        std::string num(double v)
        {
            char b[64];
            sprintf(b, "%.6g", v);
            return b;
        }

        std::string unum(size_t v)
        {
            char b[32];
            sprintf(b, "%llu", (unsigned long long)v);
            return b;
        }

        std::string fixed3(double v)
        {
            char b[64];
            sprintf(b, "%.3f", v);
            return b;
        }

        void makeDirs(const std::string& path)
        {
            for (size_t i = 3; i <= path.size(); ++i)
            {
                if (i == path.size() || path[i] == '\\' || path[i] == '/')
                    CreateDirectoryA(path.substr(0, i).c_str(), NULL);
            }
        }

        //-------------------------------------------------------------------
        // Tab separated output; fields are engine bytes (GBK), tabs / line breaks inside a field become spaces.
        class Tsv
        {
        public:
            explicit Tsv(const std::string& path) : mFile(fopen(path.c_str(), "wb")), mRows(0)
            {
                if (!mFile)
                    fxError("TlbbViewer: cannot write " + path);
            }
            ~Tsv()
            {
                if (mFile)
                    fclose(mFile);
            }
            size_t rows(void) const { return mRows; }
            void flush(void)
            {
                if (mFile)
                    fflush(mFile);
            }
            void row(const std::vector<std::string>& cols)
            {
                if (!mFile)
                    return;
                std::string line;
                for (size_t i = 0; i < cols.size(); ++i)
                {
                    if (i)
                        line += '\t';
                    const std::string& c = cols[i];
                    for (size_t k = 0; k < c.size(); ++k)
                    {
                        const char ch = c[k];
                        line += (ch == '\t' || ch == '\r' || ch == '\n') ? ' ' : ch;
                    }
                }
                line += '\n';
                fwrite(line.data(), 1, line.size(), mFile);
                ++mRows;
            }

        private:
            Tsv(const Tsv&);
            Tsv& operator=(const Tsv&);
            FILE* mFile;
            size_t mRows;
        };

        //-------------------------------------------------------------------
        // getParameter guarded against C++ exceptions and access violations (a ParamCommand::doGet of a type that
        // was never meant to be read back must not end the census).
        struct GetCall
        {
            const Ogre::StringInterface* object;
            const std::string* name;
            std::string* value;
        };

        void getCall(GetCall* call)
        {
            try
            {
                *call->value = call->object->getParameter(*call->name);
            }
            catch (...)
            {
                *call->value = "#get-exception";
            }
        }

        bool safeGet(const Ogre::StringInterface* object, const std::string& name, std::string& value)
        {
            GetCall call = { object, &name, &value };
            __try
            {
                getCall(&call);
                return true;
            }
            __except (EXCEPTION_EXECUTE_HANDLER)
            {
                return false;
            }
        }

        void dumpDict(Tsv& t, const std::string& scope, const std::string& type, const Ogre::StringInterface* object)
        {
            if (!object)
            {
                t.row({ scope, type, "#no-instance", "", "" });
                return;
            }
            const Ogre::ParameterList& params = object->getParameters();
            if (params.empty())
                t.row({ scope, type, "#no-parameters", "", "" });
            for (size_t i = 0; i < params.size(); ++i)
            {
                std::string def; // value of a fresh instance (the census compares data values with it)
                if (!safeGet(object, params[i].name, def))
                    def = "#get-crash";
                t.row({ scope, type, params[i].name, unum((size_t)params[i].paramType), def });
            }
        }

        // One row per parameter of 'object' whose value differs from 'reference' (a fresh instance of the same
        // type; all parameters when there is none).
        size_t dumpValues(Tsv& t, const std::vector<std::string>& prefix, const Ogre::StringInterface* object,
                          const Ogre::StringInterface* reference)
        {
            if (!object)
                return 0;
            size_t n = 0;
            const Ogre::ParameterList& params = object->getParameters();
            for (size_t i = 0; i < params.size(); ++i)
            {
                const std::string& name = params[i].name;
                std::string value, def;
                if (!safeGet(object, name, value))
                    value = "#get-crash";
                if (reference)
                {
                    if (!safeGet(reference, name, def))
                        def = "#get-crash";
                    if (value == def)
                        continue;
                }
                std::vector<std::string> row(prefix);
                row.push_back(name);
                row.push_back(value);
                t.row(row);
                ++n;
            }
            return n;
        }

        const char* blendName(Ogre::SceneBlendFactor f)
        {
            switch (f)
            {
            case Ogre::SBF_ONE:                     return "one";
            case Ogre::SBF_ZERO:                    return "zero";
            case Ogre::SBF_DEST_COLOUR:             return "dest_colour";
            case Ogre::SBF_SOURCE_COLOUR:           return "src_colour";
            case Ogre::SBF_ONE_MINUS_DEST_COLOUR:   return "one_minus_dest_colour";
            case Ogre::SBF_ONE_MINUS_SOURCE_COLOUR: return "one_minus_src_colour";
            case Ogre::SBF_DEST_ALPHA:              return "dest_alpha";
            case Ogre::SBF_SOURCE_ALPHA:            return "src_alpha";
            case Ogre::SBF_ONE_MINUS_DEST_ALPHA:    return "one_minus_dest_alpha";
            case Ogre::SBF_ONE_MINUS_SOURCE_ALPHA:  return "one_minus_src_alpha";
            default:                                return "?";
            }
        }

        // Lower-case file names of every resource group, built once. ResourceGroupManager::resourceExists falls back
        // to asking every archive (a file-system stat per location, 500-1500 locations here) for each missing
        // name, which made the census take hours; every location is pre-indexed when it is added
        // (addResourceLocation -> archive->find("*")), so the listed names give the same answer.
        std::set<std::string> gResourceIndex;
        bool gResourceIndexBuilt = false;

        bool textureExists(const std::string& group, const std::string& name)
        {
            (void)group;
            if (name.empty())
                return false;
            if (!Ogre::TextureManager::getSingleton().getByName(name).isNull())
                return true;
            if (!gResourceIndexBuilt)
            {
                Ogre::ResourceGroupManager& rgm = Ogre::ResourceGroupManager::getSingleton();
                Ogre::StringVector groups = rgm.getResourceGroups();
                for (size_t g = 0; g < groups.size(); ++g)
                {
                    Ogre::StringVectorPtr names = rgm.listResourceNames(groups[g]);
                    for (Ogre::StringVector::const_iterator n = names->begin(); n != names->end(); ++n)
                    {
                        std::string lower(*n);
                        for (size_t i = 0; i < lower.size(); ++i)
                        {
                            if (lower[i] >= 'A' && lower[i] <= 'Z')
                                lower[i] = char(lower[i] - 'A' + 'a');
                        }
                        gResourceIndex.insert(lower);
                    }
                }
                gResourceIndexBuilt = true;
            }
            return gResourceIndex.find(asciiLower(name)) != gResourceIndex.end();
        }

        size_t countResources(Ogre::ResourceManager& manager)
        {
            size_t n = 0;
            Ogre::ResourceManager::ResourceMapIterator it = manager.getResourceIterator();
            while (it.hasMoreElements())
            {
                it.moveNext();
                ++n;
            }
            return n;
        }

        //-------------------------------------------------------------------
        // D3D9 draw-call counter for --fx-sheet: IDirect3DDevice9 vtable slots 81..84 (d3d9.h order: DrawPrimitive,
        // DrawIndexedPrimitive, DrawPrimitiveUP, DrawIndexedPrimitiveUP), patched in this process only.
        typedef HRESULT (STDMETHODCALLTYPE* PfnDP)(IDirect3DDevice9*, D3DPRIMITIVETYPE, UINT, UINT);
        typedef HRESULT (STDMETHODCALLTYPE* PfnDIP)(IDirect3DDevice9*, D3DPRIMITIVETYPE, INT, UINT, UINT, UINT, UINT);
        typedef HRESULT (STDMETHODCALLTYPE* PfnDPUP)(IDirect3DDevice9*, D3DPRIMITIVETYPE, UINT, CONST void*, UINT);
        typedef HRESULT (STDMETHODCALLTYPE* PfnDIPUP)(IDirect3DDevice9*, D3DPRIMITIVETYPE, UINT, UINT, UINT,
                                                      CONST void*, D3DFORMAT, CONST void*, UINT);
        PfnDP gDP = NULL;
        PfnDIP gDIP = NULL;
        PfnDPUP gDPUP = NULL;
        PfnDIPUP gDIPUP = NULL;
        size_t gDrawCalls = 0;
        IDirect3DQuery9* gQuery = NULL;

        HRESULT STDMETHODCALLTYPE hookDP(IDirect3DDevice9* d, D3DPRIMITIVETYPE t, UINT a, UINT b)
        {
            ++gDrawCalls;
            return gDP(d, t, a, b);
        }
        HRESULT STDMETHODCALLTYPE hookDIP(IDirect3DDevice9* d, D3DPRIMITIVETYPE t, INT a, UINT b, UINT c, UINT e, UINT f)
        {
            ++gDrawCalls;
            return gDIP(d, t, a, b, c, e, f);
        }
        HRESULT STDMETHODCALLTYPE hookDPUP(IDirect3DDevice9* d, D3DPRIMITIVETYPE t, UINT a, CONST void* p, UINT s)
        {
            ++gDrawCalls;
            return gDPUP(d, t, a, p, s);
        }
        HRESULT STDMETHODCALLTYPE hookDIPUP(IDirect3DDevice9* d, D3DPRIMITIVETYPE t, UINT a, UINT b, UINT c,
                                            CONST void* i, D3DFORMAT f, CONST void* v, UINT s)
        {
            ++gDrawCalls;
            return gDIPUP(d, t, a, b, c, i, f, v, s);
        }

        bool installDrawCounter(IDirect3DDevice9* device)
        {
            if (gDP)
                return true;
            if (!device)
                return false;
            void** vtable = *reinterpret_cast<void***>(device);
            DWORD old = 0;
            if (!VirtualProtect(&vtable[81], 4 * sizeof(void*), PAGE_EXECUTE_READWRITE, &old))
                return false;
            gDP = (PfnDP)vtable[81];
            gDIP = (PfnDIP)vtable[82];
            gDPUP = (PfnDPUP)vtable[83];
            gDIPUP = (PfnDIPUP)vtable[84];
            vtable[81] = (void*)&hookDP;
            vtable[82] = (void*)&hookDIP;
            vtable[83] = (void*)&hookDPUP;
            vtable[84] = (void*)&hookDIPUP;
            VirtualProtect(&vtable[81], 4 * sizeof(void*), old, &old);
            FlushInstructionCache(GetCurrentProcess(), NULL, 0);
            return true;
        }

        //-------------------------------------------------------------------
        void mergeFxBounds(Ogre::SceneNode* node, Ogre::AxisAlignedBox& box, bool entitiesOnly)
        {
            if (!node)
                return;
            Ogre::SceneNode::ObjectIterator objects = node->getAttachedObjectIterator();
            while (objects.hasMoreElements())
            {
                Ogre::MovableObject* object = objects.getNext();
                if (!object->isVisible())
                    continue;
                const bool isEntity = object->getMovableType() == "Entity";
                if (entitiesOnly && !isEntity)
                    continue;
                if (isEntity && static_cast<Ogre::Entity*>(object)->getNumSubEntities() == 0)
                    continue;
                const Ogre::AxisAlignedBox& b = object->getWorldBoundingBox(true);
                if (!b.isNull())
                {
                    const Ogre::Vector3 size = b.getMaximum() - b.getMinimum();
                    if (size.x < 1e6f && size.y < 1e6f && size.z < 1e6f)
                        box.merge(b);
                }
            }
            Ogre::Node::ChildNodeIterator children = node->getChildIterator();
            while (children.hasMoreElements())
                mergeFxBounds(static_cast<Ogre::SceneNode*>(children.getNext()), box, entitiesOnly);
        }

        struct ParticleCount
        {
            size_t systems, particles, quota, objects;
            ParticleCount() : systems(0), particles(0), quota(0), objects(0) {}
        };

        void countParticles(Ogre::SceneNode* node, ParticleCount& c)
        {
            if (!node)
                return;
            Ogre::SceneNode::ObjectIterator objects = node->getAttachedObjectIterator();
            while (objects.hasMoreElements())
            {
                Ogre::MovableObject* object = objects.getNext();
                ++c.objects;
                if (object->getMovableType() == "ParticleSystem")
                {
                    Ogre::ParticleSystem* ps = static_cast<Ogre::ParticleSystem*>(object);
                    ++c.systems;
                    c.particles += ps->getNumParticles();
                    c.quota += ps->getParticleQuota();
                }
            }
            Ogre::Node::ChildNodeIterator children = node->getChildIterator();
            while (children.hasMoreElements())
                countParticles(static_cast<Ogre::SceneNode*>(children.getNext()), c);
        }

        // UTF-8 bytes -> engine bytes (as the command line: cp1252 mojibake of GBK kept, Chinese -> GBK).
        std::string utf8ToEngine(const std::string& utf8)
        {
            if (utf8.empty())
                return utf8;
            int n = MultiByteToWideChar(CP_UTF8, 0, utf8.c_str(), (int)utf8.size(), NULL, 0);
            if (n <= 0)
                return utf8;
            std::wstring w(n, L'\0');
            MultiByteToWideChar(CP_UTF8, 0, utf8.c_str(), (int)utf8.size(), &w[0], n);
            return toEngineBytes(w);
        }

        struct FxFiles
        {
            Tsv* items;
            Tsv* captures;
            Tsv* metrics;
        };

        //-------------------------------------------------------------------
        // --wide-names: a folder archive on the wide-character API. The engine's FileSystemArchive enumerates and
        // opens with _findfirst / FindFirstFileA (OgreFileSystem.cpp:318/374/505), so under ACP 1252 a file whose
        // name holds CJK characters (Reference, game stage, DataCY) never matches the GBK name data asks for. Here
        // each UTF-16 name is converted like the command line (toEngineBytes: cp1252 mojibake of GBK kept byte for
        // byte, real Chinese -> CP936), which is what an ANSI process on a CP936 system would see. Viewer only.
        std::wstring acpToWide(const std::string& s)
        {
            if (s.empty())
                return std::wstring();
            int n = MultiByteToWideChar(CP_ACP, 0, s.c_str(), (int)s.size(), NULL, 0);
            std::wstring w(n > 0 ? n : 0, L'\0');
            if (n > 0)
                MultiByteToWideChar(CP_ACP, 0, s.c_str(), (int)s.size(), &w[0], n);
            return w;
        }

        std::string wideToUtf8(const std::wstring& w)
        {
            if (w.empty())
                return std::string();
            int n = WideCharToMultiByte(CP_UTF8, 0, w.c_str(), (int)w.size(), NULL, 0, NULL, NULL);
            std::string s(n > 0 ? n : 0, '\0');
            if (n > 0)
                WideCharToMultiByte(CP_UTF8, 0, w.c_str(), (int)w.size(), &s[0], n, NULL, NULL);
            return s;
        }

        std::wstring utf8ToWide(const std::string& s)
        {
            if (s.empty())
                return std::wstring();
            int n = MultiByteToWideChar(CP_UTF8, 0, s.c_str(), (int)s.size(), NULL, 0);
            std::wstring w(n > 0 ? n : 0, L'\0');
            if (n > 0)
                MultiByteToWideChar(CP_UTF8, 0, s.c_str(), (int)s.size(), &w[0], n);
            return w;
        }

        class WideFileArchive : public Ogre::Archive
        {
        public:
            WideFileArchive(const Ogre::String& name, const Ogre::String& type) : Ogre::Archive(name, type) {}
            virtual ~WideFileArchive() { unload(); }

            virtual bool isCaseSensitive(void) const { return false; }

            virtual void load()
            {
                unload();
                const std::wstring dir = utf8ToWide(mName); // archive name = UTF-8 of the wide folder path
                WIN32_FIND_DATAW fd;
                HANDLE h = FindFirstFileW((dir + L"\\*").c_str(), &fd);
                if (h == INVALID_HANDLE_VALUE)
                    return;
                do
                {
                    if (fd.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY)
                        continue;
                    const std::string engine = toEngineBytes(fd.cFileName);
                    Entry e;
                    e.path = dir + L"\\" + fd.cFileName;
                    e.size = (size_t)(((unsigned long long)fd.nFileSizeHigh << 32) | fd.nFileSizeLow);
                    e.name = engine;
                    if (mFiles.insert(std::make_pair(asciiLower(engine), e)).second)
                        mOrder.push_back(engine);
                } while (FindNextFileW(h, &fd));
                FindClose(h);
            }

            virtual void unload()
            {
                mFiles.clear();
                mOrder.clear();
            }

            // A request with a folder prefix ("ShaderLib/ShadingParams.inc" from a shader #include) is resolved against
            // this folder on disk, as the engine's FileSystemArchive does (resolvePath); the index holds base names.
            bool resolve(const Ogre::String& filename, std::wstring& path) const
            {
                std::map<std::string, Entry>::const_iterator it = mFiles.find(asciiLower(filename));
                if (it != mFiles.end())
                {
                    path = it->second.path;
                    return true;
                }
                if (filename.find('/') == Ogre::String::npos && filename.find('\\') == Ogre::String::npos)
                    return false;
                std::string rel(filename);
                for (size_t i = 0; i < rel.size(); ++i)
                {
                    if (rel[i] == '/')
                        rel[i] = '\\';
                }
                path = utf8ToWide(mName) + L"\\" + engineToWide(rel);
                const DWORD attributes = GetFileAttributesW(path.c_str());
                return attributes != INVALID_FILE_ATTRIBUTES && !(attributes & FILE_ATTRIBUTE_DIRECTORY);
            }

            virtual Ogre::DataStreamPtr open(const Ogre::String& filename) const
            {
                std::wstring path;
                if (!resolve(filename, path))
                    OGRE_EXCEPT(Ogre::Exception::ERR_FILE_NOT_FOUND, "Cannot open file: " + filename,
                                "WideFileArchive::open");
                HANDLE f = CreateFileW(path.c_str(), GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING,
                                       FILE_ATTRIBUTE_NORMAL, NULL);
                if (f == INVALID_HANDLE_VALUE)
                    OGRE_EXCEPT(Ogre::Exception::ERR_FILE_NOT_FOUND, "Cannot open file: " + filename,
                                "WideFileArchive::open");
                LARGE_INTEGER size;
                size.QuadPart = 0;
                GetFileSizeEx(f, &size);
                Ogre::MemoryDataStream* stream = new Ogre::MemoryDataStream(filename, (size_t)size.QuadPart, true);
                unsigned char* p = stream->getPtr();
                size_t done = 0;
                while (done < (size_t)size.QuadPart)
                {
                    DWORD want = (DWORD)std::min<size_t>((size_t)size.QuadPart - done, 1 << 24), got = 0;
                    if (!ReadFile(f, p + done, want, &got, NULL) || got == 0)
                        break;
                    done += got;
                }
                CloseHandle(f);
                return Ogre::DataStreamPtr(stream);
            }

            virtual Ogre::StringVectorPtr list(bool recursive = true)
            {
                (void)recursive;
                return Ogre::StringVectorPtr(new Ogre::StringVector(mOrder));
            }

            virtual Ogre::FileInfoListPtr listFileInfo(bool recursive = true)
            {
                return findFileInfo("*", recursive);
            }

            virtual Ogre::StringVectorPtr find(const Ogre::String& pattern, bool recursive = true)
            {
                (void)recursive;
                Ogre::StringVectorPtr r(new Ogre::StringVector());
                for (size_t i = 0; i < mOrder.size(); ++i)
                {
                    if (Ogre::StringUtil::match(mOrder[i], pattern, false))
                        r->push_back(mOrder[i]);
                }
                return r;
            }

            virtual bool exists(const Ogre::String& filename)
            {
                std::wstring path;
                return resolve(filename, path);
            }

            virtual Ogre::FileInfoListPtr findFileInfo(const Ogre::String& pattern, bool recursive = true)
            {
                (void)recursive;
                Ogre::FileInfoListPtr r(new Ogre::FileInfoList());
                for (size_t i = 0; i < mOrder.size(); ++i)
                {
                    if (!Ogre::StringUtil::match(mOrder[i], pattern, false))
                        continue;
                    const Entry& e = mFiles.find(asciiLower(mOrder[i]))->second;
                    Ogre::FileInfo fi;
                    fi.archive = this;
                    fi.filename = mOrder[i];
                    fi.path = Ogre::StringUtil::BLANK;
                    fi.basename = mOrder[i];
                    fi.compressedSize = e.size;
                    fi.uncompressedSize = e.size;
                    r->push_back(fi);
                }
                return r;
            }

        private:
            struct Entry
            {
                std::wstring path;
                std::string name;
                size_t size;
            };
            std::map<std::string, Entry> mFiles;   // lower-case engine name -> file
            std::vector<std::string> mOrder;       // engine names in enumeration order
        };

        class WideFileArchiveFactory : public Ogre::ArchiveFactory
        {
        public:
            virtual ~WideFileArchiveFactory() {}
            virtual const Ogre::String& getType(void) const
            {
                static const Ogre::String type = "FileSystemW";
                return type;
            }
            virtual Ogre::Archive* createInstance(const Ogre::String& name)
            {
                return new WideFileArchive(name, "FileSystemW");
            }
            virtual void destroyInstance(Ogre::Archive* archive)
            {
                delete archive;
            }
        };

        WideFileArchiveFactory gWideFactory;
        bool gWideFactoryAdded = false;

        void addWideTree(const std::wstring& dir, const std::string& group, size_t& count)
        {
            Ogre::ResourceGroupManager::getSingleton().addResourceLocation(wideToUtf8(dir), "FileSystemW", group,
                                                                           false);
            ++count;
            std::vector<std::wstring> subdirs;
            WIN32_FIND_DATAW fd;
            HANDLE h = FindFirstFileW((dir + L"\\*").c_str(), &fd);
            if (h == INVALID_HANDLE_VALUE)
                return;
            do
            {
                if ((fd.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) && wcscmp(fd.cFileName, L".") != 0 &&
                    wcscmp(fd.cFileName, L"..") != 0)
                    subdirs.push_back(fd.cFileName);
            } while (FindNextFileW(h, &fd));
            FindClose(h);
            std::sort(subdirs.begin(), subdirs.end());
            for (size_t i = 0; i < subdirs.size(); ++i)
                addWideTree(dir + L"\\" + subdirs[i], group, count);
        }
    }

    //=======================================================================
    void ViewerApp::addWideFolderTree(const std::string& dirAcp, const std::string& group, size_t& count)
    {
        if (!gWideFactoryAdded)
        {
            Ogre::ArchiveManager::getSingleton().addArchiveFactory(&gWideFactory);
            gWideFactoryAdded = true;
        }
        addWideTree(acpToWide(dirAcp), group, count);
    }

    //=======================================================================
    // --fx-census
    //=======================================================================
    int ViewerApp::runFxCensus(void)
    {
        const std::string dir = mOpt.fxCensusDir;
        makeDirs(dir);
        const DWORD start = GetTickCount();
        Ogre::ParticleSystemManager& psm = Ogre::ParticleSystemManager::getSingleton();
        WX::EffectManager& effects = WX::EffectManager::getSingleton();

        // ---- dictionaries + reference instances (fresh object of every registered type)
        Ogre::ParticleSystem* scratch = psm.getTemplate(FX_SCRATCH);
        if (!scratch)
            scratch = psm.createTemplate(FX_SCRATCH, Ogre::ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME);
        std::map<std::string, Ogre::ParticleEmitter*> refEmitters;
        std::map<std::string, Ogre::ParticleAffector*> refAffectors;
        std::map<std::string, Ogre::ParticleSystemRenderer*> refRenderers;
        std::map<std::string, WX::EffectElement*> refElements;
        WX::Effect* refEffect = NULL;
        WX::Skill* refSkill = NULL;
        WX::AnimationEffectInfo* refAnimEffect = NULL;
        WX::AnimationRibbon* refRibbon = NULL;
        WX::AnimationSound* refSound = NULL;
        WX::AnimationSceneLightInfo* refSceneLight = NULL;
        WX::AnimationCameraShake* refShake = NULL;
        WX::AnimationComplexBlur* refBlur = NULL;
        {
            Tsv dict(dir + "\\dict.tsv");
            dict.row({ "scope", "type", "param", "ptype", "default" });
            dumpDict(dict, "system", "ParticleSystem", scratch);

            Ogre::ParticleSystemManager::ParticleEmitterFactoryIterator ei = psm.getEmitterFactoryIterator();
            while (ei.hasMoreElements())
            {
                const std::string type = ei.peekNextKey();
                ei.moveNext();
                Ogre::ParticleEmitter* e = NULL;
                try { e = scratch->addEmitter(type); }
                catch (const Ogre::Exception& ex) { fxError("TlbbViewer: census: emitter " + type + ": " + ex.getDescription()); }
                refEmitters[type] = e;
                dumpDict(dict, "emitter", type, e);
            }
            Ogre::ParticleSystemManager::ParticleAffectorFactoryIterator ai = psm.getAffectorFactoryIterator();
            while (ai.hasMoreElements())
            {
                const std::string type = ai.peekNextKey();
                ai.moveNext();
                Ogre::ParticleAffector* a = NULL;
                try { a = scratch->addAffector(type); }
                catch (const Ogre::Exception& ex) { fxError("TlbbViewer: census: affector " + type + ": " + ex.getDescription()); }
                refAffectors[type] = a;
                dumpDict(dict, "affector", type, a);
            }
            Ogre::ParticleSystemManager::ParticleRendererFactoryIterator ri = psm.getRendererFactoryIterator();
            while (ri.hasMoreElements())
            {
                const std::string type = ri.peekNextKey();
                Ogre::ParticleSystemRendererFactory* factory = ri.peekNextValue();
                ri.moveNext();
                Ogre::ParticleSystemRenderer* r = NULL;
                try { r = factory->createInstance(std::string(FX_SCRATCH) + type); }
                catch (const Ogre::Exception& ex) { fxError("TlbbViewer: census: renderer " + type + ": " + ex.getDescription()); }
                refRenderers[type] = r;
                dumpDict(dict, "renderer", type, r);
            }

            WX::EffectManager::ElementFactoryIterator fi = effects.getElementFactoryIterator();
            while (fi.hasMoreElements())
            {
                const std::string type = fi.peekNextKey();
                WX::EffectElementFactory* factory = fi.peekNextValue();
                fi.moveNext();
                WX::EffectElement* element = NULL;
                try { element = factory->createElement(wxSystem()); }
                catch (const Ogre::Exception& ex) { fxError("TlbbViewer: census: element " + type + ": " + ex.getDescription()); }
                refElements[type] = element;
                dumpDict(dict, "element", type, element);
            }

            refEffect = effects.getTemplate(FX_SCRATCH);
            if (!refEffect)
                refEffect = effects.createEffectTemplate(FX_SCRATCH);
            dumpDict(dict, "effect", "Effect", refEffect);

            try
            {
                refSkill = effects.createSkillTemplate(FX_SCRATCH);
                refAnimEffect = refSkill->addAnimationEffectInfo();
                refRibbon = refSkill->addAnimationRibbon();
                refSound = refSkill->addAnimationSound();
                refSceneLight = refSkill->addAnimationSceneLightInfo();
                refShake = refSkill->addAnimationCameraShake();
                refBlur = refSkill->addAnimationComplexBlur();
            }
            catch (const Ogre::Exception& ex)
            {
                fxError("TlbbViewer: census: skill reference: " + ex.getDescription());
            }
            dumpDict(dict, "skill", "Skill", refSkill);
            dumpDict(dict, "skill", "AnimEffect", refAnimEffect);
            dumpDict(dict, "skill", "Ribbon", refRibbon);
            dumpDict(dict, "skill", "Sound", refSound);
            dumpDict(dict, "skill", "SceneLight", refSceneLight);
            dumpDict(dict, "skill", "CameraShake", refShake);
            dumpDict(dict, "skill", "ComplexBlur", refBlur);
            fxReport("TlbbViewer: census: dict.tsv " + unum(dict.rows()) + " rows");
        }

        // ---- particle templates
        size_t templates = 0;
        {
            Tsv pt(dir + "\\ptemplates.tsv");
            pt.row({ "template", "origin", "renderer", "material", "material_exists", "quota", "width", "height",
                     "localspace", "emitters", "affectors" });
            Tsv pp(dir + "\\pparams.tsv");
            pp.row({ "template", "scope", "type", "ordinal", "param", "value" });
            Ogre::MaterialManager& mm = Ogre::MaterialManager::getSingleton();
            Ogre::ParticleSystemManager::ParticleSystemTemplateIterator it = psm.getTemplateIterator();
            while (it.hasMoreElements())
            {
                const std::string name = it.peekNextKey();
                Ogre::ParticleSystem* sys = it.peekNextValue();
                it.moveNext();
                if (!sys || name == FX_SCRATCH)
                    continue;
                ++templates;
                std::string emitterList, affectorList;
                std::map<std::string, size_t> ordinal;
                dumpValues(pp, { name, "system", "ParticleSystem", "0" }, sys, scratch);
                Ogre::ParticleSystemRenderer* renderer = sys->getRenderer();
                if (renderer)
                {
                    std::map<std::string, Ogre::ParticleSystemRenderer*>::const_iterator ref =
                        refRenderers.find(sys->getRendererName());
                    dumpValues(pp, { name, "renderer", sys->getRendererName(), "0" }, renderer,
                               ref == refRenderers.end() ? NULL : ref->second);
                }
                for (unsigned short i = 0; i < sys->getNumEmitters(); ++i)
                {
                    Ogre::ParticleEmitter* e = sys->getEmitter(i);
                    const std::string type = e->getType();
                    emitterList += (emitterList.empty() ? "" : ",") + type;
                    std::map<std::string, Ogre::ParticleEmitter*>::const_iterator ref = refEmitters.find(type);
                    dumpValues(pp, { name, "emitter", type, unum(ordinal["e:" + type]++) }, e,
                               ref == refEmitters.end() ? NULL : ref->second);
                }
                for (unsigned short i = 0; i < sys->getNumAffectors(); ++i)
                {
                    Ogre::ParticleAffector* a = sys->getAffector(i);
                    const std::string type = a->getType();
                    affectorList += (affectorList.empty() ? "" : ",") + type;
                    std::map<std::string, Ogre::ParticleAffector*>::const_iterator ref = refAffectors.find(type);
                    dumpValues(pp, { name, "affector", type, unum(ordinal["a:" + type]++) }, a,
                               ref == refAffectors.end() ? NULL : ref->second);
                }
                const std::string& material = sys->getMaterialName();
                pt.row({ name, sys->getOrigin(), sys->getRendererName(), material,
                         mm.getByName(material).isNull() ? "0" : "1", unum(sys->getParticleQuota()),
                         num(sys->getDefaultWidth()), num(sys->getDefaultHeight()),
                         sys->getKeepParticlesInLocalSpace() ? "1" : "0", emitterList, affectorList });
            }
            fxReport("TlbbViewer: census: " + unum(templates) + " particle templates, pparams.tsv " +
                     unum(pp.rows()) + " rows");
        }

        // ---- effect templates
        {
            Tsv ef(dir + "\\effects.tsv");
            ef.row({ "effect", "element", "type", "param", "value" });
            size_t count = 0, elements = 0;
            WX::EffectManager::EffectTemplateIterator it = effects.getEffectTemplateIterator();
            while (it.hasMoreElements())
            {
                const std::string name = it.peekNextKey();
                WX::Effect* effect = it.peekNextValue();
                it.moveNext();
                if (!effect || name == FX_SCRATCH)
                    continue;
                ++count;
                ef.row({ name, "-", "Effect", "#effect", unum(effect->getNumElements()) });
                dumpValues(ef, { name, "-", "Effect" }, effect, refEffect);
                for (unsigned short i = 0; i < effect->getNumElements(); ++i)
                {
                    WX::EffectElement* element = effect->getElement(i);
                    if (!element)
                        continue;
                    ++elements;
                    const std::string type = element->getType();
                    ef.row({ name, unum(i), type, "#element", "" });
                    std::map<std::string, WX::EffectElement*>::const_iterator ref = refElements.find(type);
                    dumpValues(ef, { name, unum(i), type }, element, ref == refElements.end() ? NULL : ref->second);
                }
            }
            fxReport("TlbbViewer: census: " + unum(count) + " effect templates, " + unum(elements) + " elements");
        }

        // ---- skills
        {
            Tsv sk(dir + "\\skills.tsv");
            sk.row({ "skill", "block", "index", "param", "value" });
            size_t count = 0;
            WX::EffectManager::SkillIterator it = effects.getSkillIterator();
            while (it.hasMoreElements())
            {
                const std::string name = it.peekNextKey();
                WX::Skill* skill = it.peekNextValue();
                it.moveNext();
                if (!skill || name == FX_SCRATCH)
                    continue;
                ++count;
                sk.row({ name, "Skill", "0", "#skill", "" });
                dumpValues(sk, { name, "Skill", "0" }, skill, refSkill);
                for (unsigned short i = 0; i < skill->getNumAnimationEffectInfos(); ++i)
                {
                    sk.row({ name, "AnimEffect", unum(i), "#block", "" });
                    dumpValues(sk, { name, "AnimEffect", unum(i) }, skill->getAnimationEffectInfo(i), refAnimEffect);
                }
                for (unsigned short i = 0; i < skill->getNumAnimationRibbons(); ++i)
                {
                    sk.row({ name, "Ribbon", unum(i), "#block", "" });
                    dumpValues(sk, { name, "Ribbon", unum(i) }, skill->getAnimationRibbon(i), refRibbon);
                }
                for (unsigned short i = 0; i < skill->getNumAnimationSounds(); ++i)
                {
                    sk.row({ name, "Sound", unum(i), "#block", "" });
                    dumpValues(sk, { name, "Sound", unum(i) }, skill->getAnimationSound(i), refSound);
                }
                for (unsigned short i = 0; i < skill->getNumAnimationSceneLightInfos(); ++i)
                {
                    sk.row({ name, "SceneLight", unum(i), "#block", "" });
                    dumpValues(sk, { name, "SceneLight", unum(i) }, skill->getAnimationSceneLightInfo(i), refSceneLight);
                }
                for (unsigned short i = 0; i < skill->getNumAnimationCameraShakes(); ++i)
                {
                    sk.row({ name, "CameraShake", unum(i), "#block", "" });
                    dumpValues(sk, { name, "CameraShake", unum(i) }, skill->getAnimationCameraShake(i), refShake);
                }
                for (unsigned short i = 0; i < skill->getNumAnimationComplexBlurs(); ++i)
                {
                    sk.row({ name, "ComplexBlur", unum(i), "#block", "" });
                    dumpValues(sk, { name, "ComplexBlur", unum(i) }, skill->getAnimationComplexBlur(i), refBlur);
                }
            }
            fxReport("TlbbViewer: census: " + unum(count) + " skills");
        }

        // ---- materials: passes and texture references (parse level: nothing is loaded)
        {
            Tsv ps(dir + "\\passes.tsv");
            ps.row({ "material", "group", "tech", "pass", "src", "dst", "depth_write", "depth_check", "lighting",
                     "alpha_reject", "cull", "vp", "fp", "tus" });
            Tsv tx(dir + "\\textures.tsv");
            tx.row({ "material", "tech", "pass", "tu", "frame", "texture", "exists" });
            size_t materials = 0, missing = 0;
            Ogre::ResourceManager::ResourceMapIterator it = Ogre::MaterialManager::getSingleton().getResourceIterator();
            while (it.hasMoreElements())
            {
                Ogre::ResourcePtr resource = it.getNext();
                Ogre::MaterialPtr material(resource);
                if (material.isNull())
                    continue;
                ++materials;
                const std::string name = material->getName();
                const std::string group = material->getGroup();
                for (unsigned short t = 0; t < material->getNumTechniques(); ++t)
                {
                    Ogre::Technique* technique = material->getTechnique(t);
                    for (unsigned short p = 0; p < technique->getNumPasses(); ++p)
                    {
                        Ogre::Pass* pass = technique->getPass(p);
                        ps.row({ name, group, unum(t), unum(p), blendName(pass->getSourceBlendFactor()),
                                 blendName(pass->getDestBlendFactor()), pass->getDepthWriteEnabled() ? "1" : "0",
                                 pass->getDepthCheckEnabled() ? "1" : "0", pass->getLightingEnabled() ? "1" : "0",
                                 unum((size_t)pass->getAlphaRejectFunction()) + ":" +
                                     unum((size_t)pass->getAlphaRejectValue()),
                                 unum((size_t)pass->getCullingMode()),
                                 pass->hasVertexProgram() ? pass->getVertexProgramName() : std::string(),
                                 pass->hasFragmentProgram() ? pass->getFragmentProgramName() : std::string(),
                                 unum(pass->getNumTextureUnitStates()) });
                        for (unsigned short u = 0; u < pass->getNumTextureUnitStates(); ++u)
                        {
                            Ogre::TextureUnitState* tus = pass->getTextureUnitState(u);
                            const unsigned int frames = tus->getNumFrames();
                            if (frames == 0)
                            {
                                tx.row({ name, unum(t), unum(p), unum(u), "-", "", "0" });
                                continue;
                            }
                            for (unsigned int f = 0; f < frames; ++f)
                            {
                                const std::string texture = tus->getFrameTextureName(f);
                                const bool special = texture.empty() || texture[0] == '<';
                                const bool exists = !special && textureExists(group, texture);
                                if (!special && !exists)
                                    ++missing;
                                tx.row({ name, unum(t), unum(p), unum(u), unum(f), texture,
                                         special ? "special" : (exists ? "1" : "0") });
                            }
                        }
                    }
                }
            }
            fxReport("TlbbViewer: census: " + unum(materials) + " materials, " + unum(missing) +
                     " texture references without a resource");
        }

        // ---- resource names per group
        {
            Tsv rs(dir + "\\resources.tsv");
            rs.row({ "group", "name" });
            Ogre::ResourceGroupManager& rgm = Ogre::ResourceGroupManager::getSingleton();
            Ogre::StringVector groups = rgm.getResourceGroups();
            for (size_t g = 0; g < groups.size(); ++g)
            {
                Ogre::StringVectorPtr names = rgm.listResourceNames(groups[g]);
                for (Ogre::StringVector::const_iterator n = names->begin(); n != names->end(); ++n)
                    rs.row({ groups[g], *n });
            }
        }

        fxReport("TlbbViewer: census written to " + dir + " in " + unum(GetTickCount() - start) + " ms");
        return EXIT_OK;
    }

    //=======================================================================
    // --fx-sheet
    //=======================================================================
    Ogre::SceneNode* ViewerApp::fxContentNode(const std::string& kind) const
    {
        if (kind == "effect")
            return mEffectNode;
        if (kind == "particle")
            return mFxNode;
        return mModel ? mModel->getSceneNode() : NULL;
    }
    //-----------------------------------------------------------------------
    bool ViewerApp::fxCreate(const std::string& kind, const std::string& name, const std::string& anim)
    {
        WX::System* system = wxSystem();
        if (mOpt.hasSeed)
            srand(mOpt.seed); // same random sequence for the pre-pass, the capture pass and a single-item rerun
        ++mFxSerial;
        if (kind == "effect")
        {
            if (!mEffectNode)
                mEffectNode = system->getBaseSceneNode()->createChildSceneNode();
            mEffectNode->setPosition(Ogre::Vector3::ZERO);
            WX::EffectManager& effects = WX::EffectManager::getSingleton();
            mEffect = effects.createEffect(name);
            WX::TransformInfos infos;
            infos.push_back(WX::TransformInfo(Ogre::Vector3::ZERO));
            mEffect->setExtraTransformInfos(infos);
            mEffect->createSceneNode(mEffectNode);
            return true;
        }
        if (kind == "particle")
        {
            mFxNode = system->getBaseSceneNode()->createChildSceneNode();
            mFxParticle = system->getSceneManager()->createParticleSystem(
                "TlbbViewer/FxParticle/" + unum(mFxSerial), name);
            mFxNode->attachObject(mFxParticle);
            return true;
        }
        mModel = WX::LogicModelManager::getSingleton().createLogicModel("TlbbViewer/FxModel/" + unum(mFxSerial), name);
        mModel->setParentSceneNode(system->getBaseSceneNode());
        Ogre::Vector3 origin = Ogre::Vector3::ZERO; // LogicModel::setPosition takes a non-const reference
        mModel->setPosition(origin);
        // CYS: fx-effects --scale
        if (mOpt.modelScale != 1.0f)
            mModel->setScaleFactor(Ogre::Vector3(mOpt.modelScale, mOpt.modelScale, mOpt.modelScale));
        mModel->setEffectFollowScale(mOpt.effectFollowScale);
        if (!anim.empty())
            mModel->createSkill(anim, true, false);
        return true;
    }
    //-----------------------------------------------------------------------
    void ViewerApp::fxDestroy(void)
    {
        WX::System* system = wxSystem();
        if (mEffect)
        {
            WX::EffectManager::getSingleton().destroyEffect(mEffect);
            mEffect = NULL;
            WX::EffectManager::getSingleton().clearAllFreeEffects();
        }
        if (mEffectNode && mEffectNode->numChildren() > 0)
        {
            fxLog("[TlbbViewer] fx-sheet: " + unum(mEffectNode->numChildren()) + " scene node(s) left by the effect");
            mEffectNode->removeAndDestroyAllChildren();
        }
        if (mFxParticle)
        {
            mFxNode->detachAllObjects();
            system->getSceneManager()->destroyParticleSystem(mFxParticle);
            mFxParticle = NULL;
        }
        if (mFxNode)
        {
            system->getSceneManager()->destroySceneNode(mFxNode->getName());
            mFxNode = NULL;
        }
        if (mModel)
        {
            WX::LogicModelManager::getSingleton().destroyLogicModel(mModel);
            mModel = NULL;
        }
    }
    //-----------------------------------------------------------------------
    void ViewerApp::fxFrame(float dt, const std::string* capturePath, FxFrameStats* stats)
    {
        Ogre::Root& root = Ogre::Root::getSingleton();
        LARGE_INTEGER frequency, t0, t1, t2, t3;
        QueryPerformanceFrequency(&frequency);
        Ogre::FrameEvent evt;
        evt.timeSinceLastEvent = dt;
        evt.timeSinceLastFrame = dt;

        QueryPerformanceCounter(&t0);
        root._fireFrameStarted(evt);
        // Controllers (effects, particle systems, texture animation) run once per frame number: running them here
        // separates the update cost from the render cost; the scene manager's own call is then a no-op.
        Ogre::ControllerManager::getSingleton().updateAllControllers();
        QueryPerformanceCounter(&t1);
        const size_t drawsBefore = gDrawCalls;
        root._updateAllRenderTargets();
        mWindow->update(false);
        QueryPerformanceCounter(&t2);
        if (gQuery && SUCCEEDED(gQuery->Issue(D3DISSUE_END)))
        {
            for (int spin = 0; spin < 5000000 && gQuery->GetData(NULL, 0, D3DGETDATA_FLUSH) == S_FALSE; ++spin)
                ;
        }
        QueryPerformanceCounter(&t3);
        if (stats)
        {
            const double ms = 1000.0 / double(frequency.QuadPart);
            stats->updateMs = double(t1.QuadPart - t0.QuadPart) * ms;
            stats->renderMs = double(t2.QuadPart - t1.QuadPart) * ms;
            stats->gpuMs = double(t3.QuadPart - t2.QuadPart) * ms;
            stats->draws = gDrawCalls - drawsBefore;
            stats->faces = mWindow->getTriangleCount();
        }
        if (capturePath)
            mCaptureOk = captureBackBuffer(*capturePath);
        mWindow->swapBuffers(false);
        root._fireFrameEnded(evt);
        mSimTime += dt;
    }
    //-----------------------------------------------------------------------
    bool ViewerApp::fxSheetItem(const std::vector<std::string>& item, void* filesPointer)
    {
        FxFiles& files = *static_cast<FxFiles*>(filesPointer);
        const std::string id = item.size() > 0 ? item[0] : std::string("?");
        const std::string kind = item.size() > 1 ? asciiLower(item[1]) : std::string("effect");
        const std::string name = item.size() > 2 ? item[2] : std::string();
        const std::string anim = item.size() > 3 ? item[3] : std::string();
        const DWORD start = GetTickCount();

        std::string status = "ok";
        if (kind == "effect")
        {
            if (!WX::EffectManager::getSingleton().getTemplate(name))
                status = "absent";
        }
        else if (kind == "particle")
        {
            if (!Ogre::ParticleSystemManager::getSingleton().getTemplate(name))
                status = "absent";
        }
        else if (kind == "model")
        {
            if (!WX::LogicModelManager::getSingleton().getTemplateByName(name))
                status = "absent";
        }
        else
        {
            status = "bad-kind";
        }
        if (status != "ok")
        {
            files.items->row({ id, kind, name, status, "0" });
            files.items->flush();
            fxReport("TlbbViewer: fx-sheet " + id + " " + kind + " " + name + ": " + status);
            return false;
        }

        const float dt = mOpt.dt;
        std::vector<int> captureFrames;
        for (size_t i = 0; i < mOpt.times.size(); ++i)
            captureFrames.push_back(std::max(1, (int)std::floor(mOpt.times[i] / dt + 0.5f)));
        const int lastFrame = captureFrames.back();
        const int metricFrame = std::max(1, (int)std::floor(1.0f / dt + 0.5f));
        const int windowFrames = std::max(1, (int)std::floor(0.1f / dt + 0.5f));

        Ogre::Viewport* viewport = wxSystem()->getViewport();
        const Ogre::ColourValue firstBg(mOpt.bgColours[0], mOpt.bgColours[1], mOpt.bgColours[2]);
        viewport->setBackgroundColour(firstBg);

        Ogre::AxisAlignedBox box;
        box.setNull();
        try
        {
            // 1) pre-pass: union of the bounds at the capture times
            if (mOpt.fit)
            {
                fxCreate(kind, name, anim);
                size_t next = 0;
                for (int frame = 1; frame <= lastFrame; ++frame)
                {
                    fxFrame(dt, NULL, NULL);
                    while (next < captureFrames.size() && captureFrames[next] == frame)
                    {
                        mergeFxBounds(fxContentNode(kind), box, kind == "model");
                        ++next;
                    }
                }
                fxDestroy();
            }

            // camera
            mYaw = Ogre::Degree(mOpt.orbitYaw).valueRadians();
            mPitch = Ogre::Degree(mOpt.orbitPitch).valueRadians();
            mFov = mOpt.fov;
            float fitDistance = 0.0f;
            if (!box.isNull())
            {
                float radius = std::max(box.getHalfSize().length(), 5.0f);
                if (kind == "model")
                    radius *= 1.15f; // effects around the figure
                mTarget = box.getCenter();
                mDist = radius / std::sin(Ogre::Degree(mFov * 0.5f).valueRadians()) * 1.05f;
            }
            else
            {
                mTarget = Ogre::Vector3(0.0f, 100.0f, 0.0f);
                mDist = 600.0f;
            }
            fitDistance = mDist;
            const float baseYaw = mYaw;
            applyCamera();

            // 2) capture pass
            fxCreate(kind, name, anim);
            const size_t materialsStart = countResources(Ogre::MaterialManager::getSingleton());
            const size_t texturesStart = countResources(Ogre::TextureManager::getSingleton());
            double updateSum = 0.0, renderSum = 0.0, gpuSum = 0.0;
            size_t windowCount = 0, particlesMax = 0, drawsAt1 = 0, facesAt1 = 0, systemsAt1 = 0, quotaAt1 = 0;
            size_t next = 0;
            for (int frame = 1; frame <= lastFrame; ++frame)
            {
                if (mOpt.turntable != 0.0f)
                {
                    mYaw = baseYaw + Ogre::Degree(mOpt.turntable * frame * dt).valueRadians();
                    applyCamera();
                }
                const bool capture = next < captureFrames.size() && captureFrames[next] == frame;
                std::string path;
                char timeText[32];
                if (capture)
                {
                    sprintf(timeText, "%05d", (int)std::floor(frame * dt * 1000.0f + 0.5f));
                    path = mOpt.outDir + "\\" + id + "\\" + mOpt.bgNames[0] + "_t" + timeText + ".png";
                    makeDirs(mOpt.outDir + "\\" + id);
                }
                FxFrameStats s = { 0, 0, 0, 0, 0 };
                fxFrame(dt, capture ? &path : NULL, &s);

                ParticleCount pc;
                countParticles(fxContentNode(kind), pc);
                if (std::abs(frame - metricFrame) <= windowFrames)
                {
                    updateSum += s.updateMs;
                    renderSum += s.renderMs;
                    gpuSum += s.gpuMs;
                    ++windowCount;
                    particlesMax = std::max(particlesMax, pc.particles);
                }
                if (frame == metricFrame)
                {
                    drawsAt1 = s.draws;
                    facesAt1 = s.faces;
                    systemsAt1 = pc.systems;
                    quotaAt1 = pc.quota;
                }
                while (next < captureFrames.size() && captureFrames[next] == frame)
                {
                    const std::string requested = fixed3(mOpt.times[next]);
                    files.captures->row({ id, mOpt.bgNames[0], requested, unum((size_t)frame), fixed3(frame * dt),
                                          id + "\\" + mOpt.bgNames[0] + "_t" + timeText + ".png",
                                          mCaptureOk ? "1" : "0", unum(pc.systems), unum(pc.particles),
                                          unum(s.draws), unum(s.faces) });
                    // The other backgrounds: the same state rendered again with dt = 0.
                    for (size_t b = 1; b < mOpt.bgNames.size(); ++b)
                    {
                        viewport->setBackgroundColour(Ogre::ColourValue(mOpt.bgColours[b * 3], mOpt.bgColours[b * 3 + 1],
                                                                        mOpt.bgColours[b * 3 + 2]));
                        const std::string other = mOpt.outDir + "\\" + id + "\\" + mOpt.bgNames[b] + "_t" + timeText + ".png";
                        fxFrame(0.0f, &other, NULL);
                        files.captures->row({ id, mOpt.bgNames[b], requested, unum((size_t)frame),
                                              fixed3(frame * dt),
                                              id + "\\" + mOpt.bgNames[b] + "_t" + timeText + ".png",
                                              mCaptureOk ? "1" : "0", unum(pc.systems), unum(pc.particles),
                                              "", "" });
                    }
                    viewport->setBackgroundColour(firstBg);
                    ++next;
                }
            }
            const size_t materialsEnd = countResources(Ogre::MaterialManager::getSingleton());
            const size_t texturesEnd = countResources(Ogre::TextureManager::getSingleton());
            const bool alive = (kind != "effect") || (mEffect && mEffect->isAlive());
            const size_t elements = (kind == "effect" && mEffect) ? mEffect->getNumElements() : 0;
            fxDestroy();

            const double n = windowCount ? double(windowCount) : 1.0;
            const Ogre::Vector3 bmin = box.isNull() ? Ogre::Vector3::ZERO : box.getMinimum();
            const Ogre::Vector3 bmax = box.isNull() ? Ogre::Vector3::ZERO : box.getMaximum();
            files.metrics->row({ id, kind, name, status, unum(elements), unum(systemsAt1), unum(quotaAt1),
                                 unum(particlesMax), unum(drawsAt1), unum(facesAt1), fixed3(updateSum / n),
                                 fixed3(renderSum / n), fixed3(gpuSum / n), unum(materialsStart),
                                 unum(materialsEnd), unum(texturesStart), unum(texturesEnd),
                                 num(bmin.x), num(bmin.y), num(bmin.z), num(bmax.x), num(bmax.y), num(bmax.z),
                                 num(fitDistance), alive ? "1" : "0" });
        }
        catch (const Ogre::Exception& e)
        {
            status = "error";
            fxError("TlbbViewer: fx-sheet " + id + ": " + e.getFullDescription());
            try { fxDestroy(); } catch (...) {}
        }
        files.items->row({ id, kind, name, status, unum(GetTickCount() - start) });
        files.items->flush();
        files.captures->flush();
        files.metrics->flush();
        return status == "ok";
    }
    //-----------------------------------------------------------------------
    int ViewerApp::runFxSheet(void)
    {
        // list: UTF-8, one item per line: id <TAB> effect|particle|model <TAB> name [<TAB> anim]; '#' = comment
        std::string text;
        {
            FILE* f = fopen(mOpt.fxSheetList.c_str(), "rb");
            if (!f)
            {
                fxError("TlbbViewer: cannot read " + mOpt.fxSheetList);
                return EXIT_NOT_FOUND;
            }
            char buffer[65536];
            size_t n;
            while ((n = fread(buffer, 1, sizeof(buffer), f)) > 0)
                text.append(buffer, n);
            fclose(f);
        }
        if (text.size() >= 3 && (unsigned char)text[0] == 0xEF && (unsigned char)text[1] == 0xBB &&
            (unsigned char)text[2] == 0xBF)
            text.erase(0, 3);
        std::vector<std::vector<std::string> > items;
        size_t pos = 0;
        while (pos < text.size())
        {
            size_t eol = text.find('\n', pos);
            if (eol == std::string::npos)
                eol = text.size();
            std::string line = text.substr(pos, eol - pos);
            pos = eol + 1;
            if (!line.empty() && line[line.size() - 1] == '\r')
                line.erase(line.size() - 1);
            if (line.empty() || line[0] == '#')
                continue;
            std::vector<std::string> fields;
            size_t start = 0, tab;
            while ((tab = line.find('\t', start)) != std::string::npos)
            {
                fields.push_back(utf8ToEngine(line.substr(start, tab - start)));
                start = tab + 1;
            }
            fields.push_back(utf8ToEngine(line.substr(start)));
            items.push_back(fields);
        }

        makeDirs(mOpt.outDir);
        Tsv itemsTsv(mOpt.outDir + "\\items.tsv");
        itemsTsv.row({ "id", "kind", "name", "status", "ms" });
        Tsv captures(mOpt.outDir + "\\captures.tsv");
        captures.row({ "id", "bg", "t_req", "frame", "t", "png", "ok", "systems", "particles", "draws", "faces" });
        Tsv metrics(mOpt.outDir + "\\metrics.tsv");
        metrics.row({ "id", "kind", "name", "status", "elements", "systems_t1", "quota_t1", "particles_max_t1",
                      "draws_t1", "faces_t1", "update_ms_t1", "render_ms_t1", "gpu_ms_t1", "materials_start",
                      "materials_end", "textures_start", "textures_end", "box_min_x", "box_min_y", "box_min_z",
                      "box_max_x", "box_max_y", "box_max_z", "fit_distance", "alive_end" });
        FxFiles files = { &itemsTsv, &captures, &metrics };

        setupLights();
        IDirect3DDevice9* device = NULL;
        mWindow->getCustomAttribute("D3DDEVICE", &device);
        const bool counting = installDrawCounter(device);
        if (device && !gQuery)
            device->CreateQuery(D3DQUERYTYPE_EVENT, &gQuery);
        fxReport("TlbbViewer: fx-sheet: " + unum(items.size()) + " items, " + unum(mOpt.times.size()) +
                 " capture times x " + unum(mOpt.bgNames.size()) + " backgrounds, dt " + num(mOpt.dt) +
                 (mOpt.hasSeed ? ", seed " + unum(mOpt.seed) : std::string(", NO SEED (not repeatable)")) +
                 (counting ? ", draw calls counted" : ", draw calls NOT counted"));

        size_t ok = 0;
        for (size_t i = 0; i < items.size() && !mQuit; ++i)
        {
            pumpMessages();
            if (fxSheetItem(items[i], &files))
                ++ok;
        }
        if (gQuery)
        {
            gQuery->Release();
            gQuery = NULL;
        }
        fxReport("TlbbViewer: fx-sheet done: " + unum(ok) + "/" + unum(items.size()) + " items rendered into " +
                 mOpt.outDir);
        return EXIT_OK;
    }
}
