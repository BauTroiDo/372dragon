#ifndef __CYS_SHADOW_PROGRAMS_H__
#define __CYS_SHADOW_PROGRAMS_H__

// CY-Source (shadow agent): small helpers for the GPU programs of the shadow system (media folder
// Src\Engine\WXCore\CYS\Shadow\media, registered as a resource location by the host).

#include <OgrePrerequisites.h>
#include <OgreGpuProgram.h>
#include <OgreHighLevelGpuProgram.h>
#include <OgreString.h>

namespace WX
{
    namespace CYSShadowPrograms
    {
        /** Declares and compiles an HLSL program whose source 'file' is a resource of 'group'. Returns the
            existing program when 'name' is already declared, null when the file is missing or does not compile
            (logged once). Matrices use B's convention: column_major_matrices false, mul(M, v). */
        Ogre::HighLevelGpuProgramPtr createHlsl(const Ogre::String& name, const Ogre::String& group,
                                                const Ogre::String& file, const Ogre::String& entry,
                                                const Ogre::String& target, const Ogre::String& defines,
                                                Ogre::GpuProgramType type);

        /// true when a declared program loads and compiles
        bool isUsable(const Ogre::String& name);

        /// setNamedAutoConstant that tolerates uniforms the compiler removed; false when absent
        bool setAuto(const Ogre::GpuProgramParametersSharedPtr& params, const Ogre::String& name,
                     Ogre::GpuProgramParameters::AutoConstantType type, size_t extra = 0);
        bool setConstant(const Ogre::GpuProgramParametersSharedPtr& params, const Ogre::String& name,
                         Ogre::Real value);
        bool setConstant(const Ogre::GpuProgramParametersSharedPtr& params, const Ogre::String& name,
                         const Ogre::Vector4& value);

        /// true when the program's preprocessor_defines contain name=value (a bare name means "1")
        bool hasDefine(const Ogre::String& programName, const Ogre::String& define,
                       const Ogre::String& value = "1");

        /// "CYS shadow: " + message into the Ogre log
        void log(const Ogre::String& message);
    }
}

#endif // __CYS_SHADOW_PROGRAMS_H__
