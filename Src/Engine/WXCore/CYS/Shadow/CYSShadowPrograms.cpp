// CY-Source (shadow agent): GPU program helpers. See CYSShadowPrograms.h.
#include "CYSShadowPrograms.h"

#include <OgreException.h>
#include <OgreHighLevelGpuProgramManager.h>
#include <OgreLogManager.h>
#include <OgreResourceGroupManager.h>
#include <OgreStringVector.h>
#include <OgreVector4.h>

#include <set>

namespace WX
{
    namespace CYSShadowPrograms
    {
        namespace
        {
            Ogre::HighLevelGpuProgramPtr find(const Ogre::String& name)
            {
                if (name.empty() || !Ogre::HighLevelGpuProgramManager::getSingletonPtr())
                    return Ogre::HighLevelGpuProgramPtr();
                Ogre::ResourcePtr r = Ogre::HighLevelGpuProgramManager::getSingleton().getByName(name);
                return r.isNull() ? Ogre::HighLevelGpuProgramPtr() : Ogre::HighLevelGpuProgramPtr(r);
            }

            bool fileExists(const Ogre::String& group, const Ogre::String& file)
            {
                try
                {
                    return Ogre::ResourceGroupManager::getSingleton().resourceExists(group, file);
                }
                catch (Ogre::Exception&)
                {
                    return false; // group not declared
                }
            }
        }
        //-----------------------------------------------------------------------------------------------------------
        void log(const Ogre::String& message)
        {
            if (Ogre::LogManager::getSingletonPtr())
                Ogre::LogManager::getSingleton().logMessage("CYS shadow: " + message);
        }
        //-----------------------------------------------------------------------------------------------------------
        Ogre::HighLevelGpuProgramPtr createHlsl(const Ogre::String& name, const Ogre::String& group,
                                                const Ogre::String& file, const Ogre::String& entry,
                                                const Ogre::String& target, const Ogre::String& defines,
                                                Ogre::GpuProgramType type)
        {
            Ogre::HighLevelGpuProgramPtr p = find(name);
            if (p.isNull())
            {
                if (!fileExists(group, file))
                {
                    static std::set<Ogre::String> reported;
                    if (reported.insert(group + "/" + file).second)
                        log(file + " is not a resource of group '" + group + "' (media folder not registered)");
                    return Ogre::HighLevelGpuProgramPtr();
                }
                p = Ogre::HighLevelGpuProgramManager::getSingleton().createProgram(name, group, "hlsl", type);
                p->setSourceFile(file);
                p->setParameter("entry_point", entry);
                p->setParameter("target", target);
                p->setParameter("column_major_matrices", "false");
                if (!defines.empty())
                    p->setParameter("preprocessor_defines", defines);
            }
            try
            {
                p->load();
            }
            catch (Ogre::Exception& e)
            {
                log("program " + name + " failed to load: " + e.getDescription());
                return Ogre::HighLevelGpuProgramPtr();
            }
            if (p->hasCompileError() || !p->isSupported())
            {
                log("program " + name + " (" + file + ":" + entry + ") does not compile or is not supported");
                return Ogre::HighLevelGpuProgramPtr();
            }
            return p;
        }
        //-----------------------------------------------------------------------------------------------------------
        bool isUsable(const Ogre::String& name)
        {
            Ogre::HighLevelGpuProgramPtr p = find(name);
            if (p.isNull())
                return false;
            try
            {
                p->load();
            }
            catch (Ogre::Exception& e)
            {
                log("program " + name + " failed to load: " + e.getDescription());
                return false;
            }
            return !p->hasCompileError() && p->isSupported();
        }
        //-----------------------------------------------------------------------------------------------------------
        bool setAuto(const Ogre::GpuProgramParametersSharedPtr& params, const Ogre::String& name,
                     Ogre::GpuProgramParameters::AutoConstantType type, size_t extra)
        {
            if (params.isNull())
                return false;
            try
            {
                params->setNamedAutoConstant(name, type, extra);
                return true;
            }
            catch (Ogre::Exception&)
            {
                return false; // optimised away by the compiler, or not declared by this variant
            }
        }
        //-----------------------------------------------------------------------------------------------------------
        bool setConstant(const Ogre::GpuProgramParametersSharedPtr& params, const Ogre::String& name,
                         Ogre::Real value)
        {
            if (params.isNull())
                return false;
            try
            {
                params->setNamedConstant(name, value);
                return true;
            }
            catch (Ogre::Exception&)
            {
                return false;
            }
        }
        //-----------------------------------------------------------------------------------------------------------
        bool setConstant(const Ogre::GpuProgramParametersSharedPtr& params, const Ogre::String& name,
                         const Ogre::Vector4& value)
        {
            if (params.isNull())
                return false;
            try
            {
                params->setNamedConstant(name, value);
                return true;
            }
            catch (Ogre::Exception&)
            {
                return false;
            }
        }
        //-----------------------------------------------------------------------------------------------------------
        bool hasDefine(const Ogre::String& programName, const Ogre::String& define, const Ogre::String& value)
        {
            Ogre::HighLevelGpuProgramPtr p = find(programName);
            if (p.isNull())
                return false;
            const Ogre::StringVector items = Ogre::StringUtil::split(p->getParameter("preprocessor_defines"), ";,");
            for (size_t i = 0; i < items.size(); ++i)
            {
                Ogre::String item = items[i];
                Ogre::StringUtil::trim(item);
                const size_t eq = item.find('=');
                Ogre::String key = eq == Ogre::String::npos ? item : item.substr(0, eq);
                Ogre::String val = eq == Ogre::String::npos ? Ogre::String("1") : item.substr(eq + 1);
                Ogre::StringUtil::trim(key);
                Ogre::StringUtil::trim(val);
                if (key == define)
                    return val == value;
            }
            return false;
        }
    }
}
