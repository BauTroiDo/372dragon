// CY-Source (scene agent): see CYSSceneFiles.h.
#include "CYSSceneFiles.h"

#include <OgreResourceGroupManager.h>
#include <OgreException.h>

#include <cstdio>
#include <cstring>

namespace WX
{
    void CYSSceneFileParams::reset(void)
    {
        hasHdr = hasNewHdrBloom = hasHeightFog = hasGodRays = false;
        hdr = CYSHdrFileParams();
        newHdrBloom = CYSNewHdrBloomParams();
        heightFog = CYSHeightFogParams();
        godRays = CYSGodRaysParams();
    }

    namespace CYSScene
    {
        namespace
        {
            bool checkSize(size_t size, size_t expected, const char* what, String* error)
            {
                if (size == expected)
                    return true;
                if (error)
                {
                    char buf[128];
                    sprintf(buf, "%s: %u bytes, expected %u", what, (unsigned)size, (unsigned)expected);
                    *error = buf;
                }
                return false;
            }

            inline float readF32(const unsigned char* p)
            {
                float v;
                memcpy(&v, p, 4);
                return v;
            }
        }

        bool decodeHdr(const void* data, size_t size, CYSHdrFileParams& out, String* error)
        {
            // 20 bytes (GL / older CY) or 28 bytes (CY 3.71: two extra floats, kept but not applied).
            if (size != 28 && !checkSize(size, 20, ".hdr", error))
                return false;
            const unsigned char* p = static_cast<const unsigned char*>(data);
            out.keyValue = readF32(p + 0);
            out.limitedLuminance = readF32(p + 4);
            out.gaussianMultiplier = readF32(p + 8);
            out.gaussianOffset = readF32(p + 12);
            out.gaussianDev = readF32(p + 16);
            out.hasCyExtra = (size == 28);
            if (out.hasCyExtra)
            {
                out.cyExtra[0] = readF32(p + 20);
                out.cyExtra[1] = readF32(p + 24);
                CYSSceneStats::instance().deferred("Scene file .hdr 28-byte CY variant (2 extra floats kept, not applied)");
            }
            return true;
        }

        bool decodeNewHdrBloom(const void* data, size_t size, CYSNewHdrBloomParams& out, String* error)
        {
            if (!checkSize(size, 34, ".newhdrbloom", error))
                return false;
            const unsigned char* p = static_cast<const unsigned char*>(data);
            out.intensity = readF32(p + 0);
            out.threshold = readF32(p + 4);
            out.softKnee = readF32(p + 8);
            out.exposure = readF32(p + 12);
            out.useHDR = p[16] != 0;
            out.useAutoExposure = p[17] != 0;
            out.bloomColour = Ogre::ColourValue(readF32(p + 18), readF32(p + 22), readF32(p + 26), readF32(p + 30));
            return true;
        }

        bool decodeHeightFog(const void* data, size_t size, CYSHeightFogParams& out, String* error)
        {
            if (!checkSize(size, 64, ".hfog", error))
                return false;
            const unsigned char* p = static_cast<const unsigned char*>(data);
            float f[16];
            for (int i = 0; i < 16; ++i)
                f[i] = readF32(p + 4 * i);
            out.fogColour = Ogre::ColourValue(f[0], f[1], f[2], f[3]);
            out.hDensity = f[4];
            out.hHeight = f[5];
            out.hHeightFalloff = f[6];
            out.hPowFactor = f[7];
            out.dDensity = f[8];
            out.dHeightFalloff = f[9];
            out.dStartDistance = f[10];
            out.inscatteringFactor = f[11];
            out.dirInscatteringColour = Ogre::ColourValue(f[12], f[13], f[14], f[15]);
            return true;
        }

        bool decodeGodRays(const void* data, size_t size, CYSGodRaysParams& out, String* error)
        {
            if (!checkSize(size, 12, ".godrays", error))
                return false;
            const unsigned char* p = static_cast<const unsigned char*>(data);
            out.decay = readF32(p + 0);
            out.exposure = readF32(p + 4);
            out.weight = readF32(p + 8);
            return true;
        }

        bool readResource(const String& name, const std::vector<String>& groups, std::vector<unsigned char>& bytes,
                          String* foundGroup)
        {
            Ogre::ResourceGroupManager& rgm = Ogre::ResourceGroupManager::getSingleton();
            for (size_t i = 0; i < groups.size(); ++i)
            {
                try
                {
                    if (!rgm.resourceExists(groups[i], name))
                        continue;
                    Ogre::DataStreamPtr stream = rgm.openResource(name, groups[i]);
                    if (stream.isNull())
                        continue;
                    const size_t size = stream->size();
                    bytes.resize(size);
                    if (size)
                        bytes.resize(stream->read(&bytes[0], size));
                    if (foundGroup)
                        *foundGroup = groups[i];
                    return true;
                }
                catch (const Ogre::Exception&)
                {
                    // group does not exist: try the next one
                }
            }
            return false;
        }

        size_t loadSceneFileParams(const String& sceneBaseName, const String& group, CYSSceneFileParams& out)
        {
            out.reset();
            std::vector<String> groups;
            groups.push_back(group);
            if (group != "Scene")
                groups.push_back("Scene");

            size_t read = 0;
            std::vector<unsigned char> bytes;
            String error;
            CYSSceneStats& stats = CYSSceneStats::instance();

            if (readResource(sceneBaseName + ".hdr", groups, bytes))
            {
                if (decodeHdr(bytes.empty() ? 0 : &bytes[0], bytes.size(), out.hdr, &error))
                {
                    out.hasHdr = true;
                    ++read;
                    stats.count("Scene file .hdr");
                }
                else
                    stats.problem("Scene file .hdr (" + error + ")", sceneBaseName + ".hdr");
            }
            if (readResource(sceneBaseName + ".newhdrbloom", groups, bytes))
            {
                if (decodeNewHdrBloom(bytes.empty() ? 0 : &bytes[0], bytes.size(), out.newHdrBloom, &error))
                {
                    out.hasNewHdrBloom = true;
                    ++read;
                    stats.count("Scene file .newhdrbloom");
                }
                else
                    stats.problem("Scene file .newhdrbloom (" + error + ")", sceneBaseName + ".newhdrbloom");
            }
            if (readResource(sceneBaseName + ".hfog", groups, bytes))
            {
                if (decodeHeightFog(bytes.empty() ? 0 : &bytes[0], bytes.size(), out.heightFog, &error))
                {
                    out.hasHeightFog = true;
                    ++read;
                    stats.count("Scene file .hfog");
                }
                else
                    stats.problem("Scene file .hfog (" + error + ")", sceneBaseName + ".hfog");
            }
            if (readResource(sceneBaseName + ".godrays", groups, bytes))
            {
                if (decodeGodRays(bytes.empty() ? 0 : &bytes[0], bytes.size(), out.godRays, &error))
                {
                    out.hasGodRays = true;
                    ++read;
                    stats.count("Scene file .godrays");
                }
                else
                    stats.problem("Scene file .godrays (" + error + ")", sceneBaseName + ".godrays");
            }
            return read;
        }
    }
}
