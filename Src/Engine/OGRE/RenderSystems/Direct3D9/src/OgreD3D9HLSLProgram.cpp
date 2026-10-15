/*
-----------------------------------------------------------------------------
This source file is part of OGRE
    (Object-oriented Graphics Rendering Engine)
For the latest info, see http://www.ogre3d.org/

Copyright (c) 2000-2005 The OGRE Team
Also see acknowledgements in Readme.html

This program is free software you can redistribute it and/or modify it under
the terms of the GNU Lesser General Public License as published by the Free Software
Foundation either version 2 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public License along with
this program if not, write to the Free Software Foundation, Inc., 59 Temple
Place - Suite 330, Boston, MA 02111-1307, USA, or go to
http://www.gnu.org/copyleft/lesser.txt.
-----------------------------------------------------------------------------
*/
#include "OgreD3D9HLSLProgram.h"
#include "OgreGpuProgramManager.h"
#include "OgreStringConverter.h"
#include "OgreD3D9GpuProgram.h"
#include "OgreGpuProgram.h"
#include "OgreRoot.h"
#include "OgreRenderSystem.h"
#include "OgreRenderSystemCapabilities.h"
#include "OgreResourceGroupManager.h" // CYS: HLSL #include resolver
#include "OgreLogManager.h"           // CYS
#include <fstream>                    // CYS: shader microcode cache
#include <vector>

namespace Ogre {
    //-----------------------------------------------------------------------
    // CYS: compiled-microcode cache (B RenderSystem_Direct3D9 keeps .\ShaderCache\*.bin).
    // Key = 128-bit hash of the preprocessed source (all #includes and macros expanded), the
    // target, the entry point, the compile flags and the D3DX version; a changed shader or define
    // set therefore never hits a stale entry.
    namespace
    {
        void cysHash(const char* data, size_t len, unsigned long long& h1, unsigned long long& h2)
        {
            // two independent 64-bit FNV-1a streams
            for (size_t i = 0; i < len; ++i)
            {
                unsigned char c = static_cast<unsigned char>(data[i]);
                h1 = (h1 ^ c) * 0x100000001b3ULL;
                h2 = (h2 ^ c) * 0x00000100000001b3ULL + 0x9e3779b97f4a7c15ULL;
            }
        }

        bool cysReadFile(const String& path, std::vector<char>& out)
        {
            std::ifstream f(path.c_str(), std::ios::binary);
            if (!f)
                return false;
            f.seekg(0, std::ios::end);
            std::streamoff n = f.tellg();
            if (n <= 0)
                return false;
            out.resize(static_cast<size_t>(n));
            f.seekg(0, std::ios::beg);
            f.read(&out[0], n);
            return f.good() || f.eof();
        }

        void cysWriteFile(const String& path, const void* data, size_t len)
        {
            // write to a temporary name first so that a concurrent reader never sees half a file
            String tmp = path + ".tmp" + StringConverter::toString(static_cast<unsigned long>(GetCurrentProcessId()));
            {
                std::ofstream f(tmp.c_str(), std::ios::binary | std::ios::trunc);
                if (!f)
                    return;
                f.write(static_cast<const char*>(data), static_cast<std::streamsize>(len));
                if (!f.good())
                    return;
            }
            if (!MoveFileExA(tmp.c_str(), path.c_str(), MOVEFILE_REPLACE_EXISTING))
                DeleteFileA(tmp.c_str());
        }
    }
    //-----------------------------------------------------------------------
    // CYS: #include resolver for D3DXCompileShader. The client_GL material templates
    // (MaterialTemplates.zip) #include ModelDef.inc, ParticleDef.inc, ...; the 0.85 code passed
    // NULL, so each such program failed with X1507. Includes are opened through the resource
    // system: the program's group first, then all groups.
    class CysHLSLIncludeHandler : public ID3DXInclude
    {
    public:
        explicit CysHLSLIncludeHandler(const String& group) : mGroup(group) {}
        STDMETHOD(Open)(D3DXINCLUDE_TYPE IncludeType, LPCSTR pFileName, LPCVOID pParentData,
            LPCVOID* ppData, UINT* pBytes)
        {
            try
            {
                DataStreamPtr stream =
                    ResourceGroupManager::getSingleton().openResource(pFileName, mGroup, true);
                String source = stream->getAsString();
                char* data = new char[source.size() + 1];
                memcpy(data, source.c_str(), source.size() + 1);
                *ppData = data;
                *pBytes = static_cast<UINT>(source.size());
                return S_OK;
            }
            catch (Exception&)
            {
                return E_FAIL;
            }
        }
        STDMETHOD(Close)(LPCVOID pData)
        {
            delete[] static_cast<const char*>(pData);
            return S_OK;
        }
    private:
        String mGroup;
    };
    //-----------------------------------------------------------------------
    D3D9HLSLProgram::CmdEntryPoint D3D9HLSLProgram::msCmdEntryPoint;
    D3D9HLSLProgram::CmdTarget D3D9HLSLProgram::msCmdTarget;
    D3D9HLSLProgram::CmdPreprocessorDefines D3D9HLSLProgram::msCmdPreprocessorDefines;
    D3D9HLSLProgram::CmdColumnMajorMatrices D3D9HLSLProgram::msCmdColumnMajorMatrices;
    //-----------------------------------------------------------------------
    //-----------------------------------------------------------------------
    void D3D9HLSLProgram::loadFromSource(void)
    {
        // Populate preprocessor defines
        String stringBuffer;
        std::vector<D3DXMACRO> defines;
        const D3DXMACRO* pDefines = 0;
        if (!mPreprocessorDefines.empty())
        {
            stringBuffer = mPreprocessorDefines;

            // Split preprocessor defines and build up macro array
            D3DXMACRO macro;
            String::size_type pos = 0;
            while (pos != String::npos)
            {
                macro.Name = &stringBuffer[pos];
                macro.Definition = 0;

                // Find delims
                pos = stringBuffer.find_first_of(";,=", pos);
                if (pos != String::npos)
                {
                    // Check definition part
                    if (stringBuffer[pos] == '=')
                    {
                        // Setup null character for macro name
                        stringBuffer[pos++] = '\0';
                        macro.Definition = &stringBuffer[pos];
                        pos = stringBuffer.find_first_of(";,", pos);
                    }
                    else
                    {
                        // No definition part, define as "1"
                        macro.Definition = "1";
                    }

                    if (pos != String::npos)
                    {
                        // Setup null character for macro name or definition
                        stringBuffer[pos++] = '\0';
                    }
                }

                defines.push_back(macro);
            }

            // Add NULL terminator
            macro.Name = 0;
            macro.Definition = 0;
            defines.push_back(macro);

            pDefines = &defines[0];
        }

        // Populate compile flags
        DWORD compileFlags = 0;
        // CYS-SKY (sky-enscene): CY 3.71 RenderSystem_Direct3D9 D3D9HLSLProgram::loadFromSource (FUN_180009270) replaces
        // a target containing "vs_1" by "vs_2_0" and "ps_1" by "ps_2_0" before D3DXCompileShader (flags: pack matrix
        // only). The d3d9 trace of CY never shows a 1.x shader: SkySphereLayerBlend_*_VS_1_1_hlsl runs as vs_2_0
        // (hash 56cd7c90). CYS_HLSL_SM1_UPGRADE=0 keeps the former behaviour (vs_1_x as is, ps_1_x with the D3DX43
        // backwards-compatibility flag, commit 6ea1ed4b).
        String target = mTarget;
        static const bool cysUpgradeSm1 = !(getenv("CYS_HLSL_SM1_UPGRADE") && getenv("CYS_HLSL_SM1_UPGRADE")[0] == '0');
        if (cysUpgradeSm1)
        {
            if (target.find("vs_1") != String::npos)
                target = "vs_2_0";
            if (target.find("ps_1") != String::npos)
                target = "ps_2_0";
        }
        // CYS: D3DX43 requires compatibility for original ps_1_x HLSL.
        // Compile flags participate in the microcode cache key below.
        if (target.compare(0, 5, "ps_1_") == 0)
            compileFlags |= D3DXSHADER_ENABLE_BACKWARDS_COMPATIBILITY;
        if (mColumnMajorMatrices)
            compileFlags |= D3DXSHADER_PACKMATRIX_COLUMNMAJOR;
        else
            compileFlags |= D3DXSHADER_PACKMATRIX_ROWMAJOR;

        LPD3DXBUFFER errors = 0;
        CysHLSLIncludeHandler includeHandler(mGroup); // CYS

        // CYS: microcode cache lookup (see cysHash above)
        String cacheFile;
        const String& cacheDir = GpuProgramManager::getMicrocodeCacheDirectory();
        if (!cacheDir.empty())
        {
            LPD3DXBUFFER preprocessed = 0;
            LPD3DXBUFFER preErrors = 0;
            if (SUCCEEDED(D3DXPreprocessShader(mSource.c_str(), static_cast<UINT>(mSource.length()),
                pDefines, &includeHandler, &preprocessed, &preErrors)) && preprocessed)
            {
                unsigned long long h1 = 0xcbf29ce484222325ULL, h2 = 0x84222325cbf29ce4ULL;
                cysHash(static_cast<const char*>(preprocessed->GetBufferPointer()),
                    preprocessed->GetBufferSize(), h1, h2);
                String salt = "|" + target + "|" + mEntryPoint + "|" +
                    StringConverter::toString(static_cast<unsigned long>(compileFlags)) + "|d3dx" +
                    StringConverter::toString(D3DX_SDK_VERSION) + "|cys1";
                cysHash(salt.c_str(), salt.size(), h1, h2);
                char name[40];
                sprintf(name, "%016llx%016llx.bin", h1, h2);
                cacheFile = cacheDir + "\\" + name;
                std::vector<char> blob;
                if (cysReadFile(cacheFile, blob) && blob.size() >= 4 &&
                    SUCCEEDED(D3DXCreateBuffer(static_cast<DWORD>(blob.size()), &mpMicroCode)))
                {
                    memcpy(mpMicroCode->GetBufferPointer(), &blob[0], blob.size());
                    if (SUCCEEDED(D3DXGetShaderConstantTable(
                        static_cast<const DWORD*>(mpMicroCode->GetBufferPointer()), &mpConstTable)))
                    {
                        SAFE_RELEASE(preprocessed);
                        SAFE_RELEASE(preErrors);
                        GpuProgramManager::_notifyMicrocodeCacheLookup(true);
                        return;
                    }
                    SAFE_RELEASE(mpMicroCode);
                }
            }
            SAFE_RELEASE(preprocessed);
            SAFE_RELEASE(preErrors);
        }

        // Compile & assemble into microcode
        HRESULT hr = D3DXCompileShader(
            mSource.c_str(),
            static_cast<UINT>(mSource.length()),
            pDefines,
            &includeHandler, // CYS: was NULL (no includes)
            mEntryPoint.c_str(),
            target.c_str(),
            compileFlags,
            &mpMicroCode,
            &errors,
            &mpConstTable);

        if (FAILED(hr))
        {
            // CYS: the compiler may fail without an error buffer
            String message = "Cannot assemble D3D9 high-level shader " + mName + " Errors:\n" +
                (errors ? static_cast<const char*>(errors->GetBufferPointer()) : "(no error buffer)");
            if (errors) errors->Release();
            OGRE_EXCEPT(hr, message,
                "D3D9HLSLProgram::loadFromSource");
        }
        SAFE_RELEASE(errors); // CYS: warnings buffer

        // CYS: store the microcode for the next start
        if (!cacheFile.empty() && mpMicroCode)
        {
            cysWriteFile(cacheFile, mpMicroCode->GetBufferPointer(), mpMicroCode->GetBufferSize());
            GpuProgramManager::_notifyMicrocodeCacheLookup(false);
        }
    }
    //-----------------------------------------------------------------------
    void D3D9HLSLProgram::createLowLevelImpl(void)
    {
        // Create a low-level program, give it the same name as us
        mAssemblerProgram = 
            GpuProgramManager::getSingleton().createProgramFromString(
                mName, 
                mGroup,
                StringUtil::BLANK,  // dummy source, since we'll be using microcode
                mType, 
                mTarget);
        static_cast<D3D9GpuProgram*>(mAssemblerProgram.get())->setExternalMicrocode(mpMicroCode);

    }
    //-----------------------------------------------------------------------
    void D3D9HLSLProgram::unloadHighLevelImpl(void)
    {
        SAFE_RELEASE(mpMicroCode);
        SAFE_RELEASE(mpConstTable);

    }
    //-----------------------------------------------------------------------
    void D3D9HLSLProgram::populateParameterNames(GpuProgramParametersSharedPtr params)
    {
        // Derive parameter names from const table
        assert(mpConstTable && "Program not loaded!");
        // Get contents of the constant table
        D3DXCONSTANTTABLE_DESC desc;
        HRESULT hr = mpConstTable->GetDesc(&desc);

        if (FAILED(hr))
        {
            OGRE_EXCEPT(Exception::ERR_INTERNAL_ERROR, 
                "Cannot retrieve constant descriptions from HLSL program.", 
                "D3D9HLSLProgram::populateParameterNames");
        }
        // Iterate over the constants
        for (unsigned int i = 0; i < desc.Constants; ++i)
        {
            // Recursively descend through the structure levels
            // Since D3D9 has no nice 'leaf' method like Cg (sigh)
            processParamElement(NULL, StringUtil::BLANK, i, params);
        }

        // CYS: uniforms named after auto constants (MaterialTemplates ShaderLib/ParamNamedAuto.inc)
        // are bound implicitly, as B's Render.dll does for the programs it generates; explicit
        // param_named_auto lines of the script override these bindings afterwards.
        params->_setAutoConstantsByName();
    }
    //-----------------------------------------------------------------------
    void D3D9HLSLProgram::processParamElement(D3DXHANDLE parent, String prefix, 
        unsigned int index, GpuProgramParametersSharedPtr params)
    {
        D3DXHANDLE hConstant = mpConstTable->GetConstant(parent, index);

        // Since D3D HLSL doesn't deal with naming of array and struct parameters
        // automatically, we have to do it by hand

        D3DXCONSTANT_DESC desc;
        unsigned int numParams = 1;
        HRESULT hr = mpConstTable->GetConstantDesc(hConstant, &desc, &numParams);
        if (FAILED(hr))
        {
            OGRE_EXCEPT(Exception::ERR_INTERNAL_ERROR, 
                "Cannot retrieve constant description from HLSL program.", 
                "D3D9HLSLProgram::processParamElement");
        }

        String paramName = desc.Name;
        // trim the odd '$' which appears at the start of the names in HLSL
        if (paramName.at(0) == '$')
            paramName.erase(paramName.begin());

        // If it's an array, elements will be > 1
        for (unsigned int e = 0; e < desc.Elements; ++e)
        {
            if (desc.Class == D3DXPC_STRUCT)
            {
                // work out a new prefix for nested members, if it's an array, we need an index
                if (desc.Elements > 1)
                    prefix = prefix + paramName + "[" + StringConverter::toString(e) + "].";
                else
                    prefix = prefix + paramName + ".";
                // Cascade into struct
                for (unsigned int i = 0; i < desc.StructMembers; ++i)
                {
                    processParamElement(hConstant, prefix, i, params);
                }
            }
            else
            {
                // Process params
                if (desc.Type == D3DXPT_FLOAT || desc.Type == D3DXPT_INT || desc.Type == D3DXPT_BOOL)
                {
                    // CYS: registers per element (row / column count for matrices). fxc allocates
                    // registers only up to the last element the shader uses, so the old
                    // 'e * RegisterCount / Elements' mapped trimmed arrays wrongly; elements without
                    // registers get no name (writes to them would hit other constants).
                    size_t regsPerElem = 1;
                    if (desc.Class == D3DXPC_MATRIX_ROWS)
                        regsPerElem = desc.Rows;
                    else if (desc.Class == D3DXPC_MATRIX_COLUMNS)
                        regsPerElem = desc.Columns;
                    if (regsPerElem == 0)
                        regsPerElem = 1;
                    size_t allocated = desc.RegisterCount / regsPerElem;
                    if (desc.Elements > 1 && e >= allocated && allocated > 0)
                        break;
                    size_t paramIndex = desc.RegisterIndex + e * regsPerElem;
                    String name = prefix + paramName;
                    // If this is an array, need to append element index
                    if (desc.Elements > 1)
                        name += "[" + StringConverter::toString(e) + "]";

                    params->_mapParameterNameToIndex(name, paramIndex);
                    // setup constant definition
                    // is it float or int
                    GpuProgramParameters::ElementType elementType = GpuProgramParameters::ET_INT;
                    if (desc.Type == D3DXPT_FLOAT)
                        elementType = GpuProgramParameters::ET_REAL;
                    params->addConstantDefinition(name, paramIndex, 0, elementType);

                    // CYS: HLSL initialisers ('float4 spec_params = float4(255,255,255,1);' in
                    // ParamNamed.inc) are not applied by D3D9 itself; use them as default values so
                    // unset constants do not keep another program's register contents.
                    if (desc.DefaultValue && desc.Type == D3DXPT_FLOAT && desc.Elements == 1 &&
                        (desc.Class == D3DXPC_SCALAR || desc.Class == D3DXPC_VECTOR))
                    {
                        const float* dv = static_cast<const float*>(desc.DefaultValue);
                        float v[4] = { 0.0f, 0.0f, 0.0f, 0.0f };
                        UINT n = desc.Columns < 4 ? desc.Columns : 4;
                        for (UINT c = 0; c < n; ++c)
                            v[c] = dv[c];
                        params->setConstant(paramIndex, v, 1);
                    }
                }
            }
        }
            
    }
    //-----------------------------------------------------------------------
    D3D9HLSLProgram::D3D9HLSLProgram(ResourceManager* creator, const String& name, 
        ResourceHandle handle, const String& group, bool isManual, 
        ManualResourceLoader* loader)
        : HighLevelGpuProgram(creator, name, handle, group, isManual, loader)
        , mTarget()
        , mEntryPoint()
        , mPreprocessorDefines()
        , mColumnMajorMatrices(true)
        , mpMicroCode(NULL), mpConstTable(NULL)
    {
        if (createParamDictionary("D3D9HLSLProgram"))
        {
            setupBaseParamDictionary();
            ParamDictionary* dict = getParamDictionary();

            dict->addParameter(ParameterDef("entry_point", 
                "The entry point for the HLSL program.",
                PT_STRING),&msCmdEntryPoint);
            dict->addParameter(ParameterDef("target", 
                "Name of the assembler target to compile down to.",
                PT_STRING),&msCmdTarget);
            dict->addParameter(ParameterDef("preprocessor_defines", 
                "Preprocessor defines use to compile the program.",
                PT_STRING),&msCmdPreprocessorDefines);
            dict->addParameter(ParameterDef("column_major_matrices", 
                "Whether matrix packing in column-major order.",
                PT_BOOL),&msCmdColumnMajorMatrices);
        }
        
    }
    //-----------------------------------------------------------------------
    D3D9HLSLProgram::~D3D9HLSLProgram()
    {
        // have to call this here reather than in Resource destructor
        // since calling virtual methods in base destructors causes crash
        if (mIsLoaded)
        {
            unload();
        }
        else
        {
            unloadHighLevel();
        }
    }
    //-----------------------------------------------------------------------
    bool D3D9HLSLProgram::isSupported(void) const
    {
		// If skeletal animation is being done, we need support for UBYTE4
		if ((isSkeletalAnimationIncluded() && 
			!Root::getSingleton().getRenderSystem()->getCapabilities()
				->hasCapability(RSC_VERTEX_FORMAT_UBYTE4)) ||  
			mCompileError)
		{
			return false;
		}

        return GpuProgramManager::getSingleton().isSyntaxSupported(mTarget);
    }
    //-----------------------------------------------------------------------
    GpuProgramParametersSharedPtr D3D9HLSLProgram::createParameters(void)
    {
        // Call superclass
        GpuProgramParametersSharedPtr params = HighLevelGpuProgram::createParameters();

        // Need to transpose matrices if compiled with column-major matrices
        params->setTransposeMatrices(mColumnMajorMatrices);

        return params;
    }
    //-----------------------------------------------------------------------
    void D3D9HLSLProgram::setTarget(const String& target)
    {
        mTarget = target;
    }

    //-----------------------------------------------------------------------
    const String& D3D9HLSLProgram::getLanguage(void) const
    {
        static const String language = "hlsl";

        return language;
    }

    //-----------------------------------------------------------------------
    //-----------------------------------------------------------------------
    String D3D9HLSLProgram::CmdEntryPoint::doGet(const void *target) const
    {
        return static_cast<const D3D9HLSLProgram*>(target)->getEntryPoint();
    }
    void D3D9HLSLProgram::CmdEntryPoint::doSet(void *target, const String& val)
    {
        static_cast<D3D9HLSLProgram*>(target)->setEntryPoint(val);
    }
    //-----------------------------------------------------------------------
    String D3D9HLSLProgram::CmdTarget::doGet(const void *target) const
    {
        return static_cast<const D3D9HLSLProgram*>(target)->getTarget();
    }
    void D3D9HLSLProgram::CmdTarget::doSet(void *target, const String& val)
    {
        static_cast<D3D9HLSLProgram*>(target)->setTarget(val);
    }
    //-----------------------------------------------------------------------
    String D3D9HLSLProgram::CmdPreprocessorDefines::doGet(const void *target) const
    {
        return static_cast<const D3D9HLSLProgram*>(target)->getPreprocessorDefines();
    }
    void D3D9HLSLProgram::CmdPreprocessorDefines::doSet(void *target, const String& val)
    {
        static_cast<D3D9HLSLProgram*>(target)->setPreprocessorDefines(val);
    }
    //-----------------------------------------------------------------------
    String D3D9HLSLProgram::CmdColumnMajorMatrices::doGet(const void *target) const
    {
        return StringConverter::toString(static_cast<const D3D9HLSLProgram*>(target)->getColumnMajorMatrices());
    }
    void D3D9HLSLProgram::CmdColumnMajorMatrices::doSet(void *target, const String& val)
    {
        static_cast<D3D9HLSLProgram*>(target)->setColumnMajorMatrices(StringConverter::parseBool(val));
    }

}
