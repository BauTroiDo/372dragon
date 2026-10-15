/*
-----------------------------------------------------------------------------
CY-Source addition to OGRE 1.2.5 (Dagon) - not part of the original distribution.
CYS: ImageCodec on the Windows Imaging Component (2026-09-12).
-----------------------------------------------------------------------------
*/
#ifndef __CysWICCodec_H__
#define __CysWICCodec_H__

#include "OgrePrerequisites.h"
#include "OgreImageCodec.h"

namespace Ogre {

    /** CYS: image codec backed by the Windows Imaging Component, which every Windows version since
        XP SP3 ships. The DevIL of this source tree is built without libpng/libjpeg (only x86 VC6
        builds of them exist), so PNG/JPEG textures (OgreCore.zip, MaterialTemplates.zip, lightmaps,
        terrain) failed to load. Decodes PNG, JPEG, BMP, GIF, TIFF to PF_A8R8G8B8 and encodes PNG,
        JPEG, BMP. DevIL stays registered for DDS, TGA and the other formats. */
    class _OgrePrivate WICImageCodec : public ImageCodec
    {
    public:
        enum Container { WIC_DECODE_ONLY = 0, WIC_PNG, WIC_JPEG, WIC_BMP, WIC_TIFF };

        WICImageCodec(const String& type, Container encoder);
        virtual ~WICImageCodec() {}

        /// @copydoc Codec::code
        DataStreamPtr code(MemoryDataStreamPtr& input, CodecDataPtr& pData) const;
        /// @copydoc Codec::codeToFile
        void codeToFile(MemoryDataStreamPtr& input, const String& outFileName, CodecDataPtr& pData) const;
        /// @copydoc Codec::decode
        DecodeResult decode(DataStreamPtr& input) const;
        /// @copydoc Codec::getType
        String getType() const { return mType; }

        /// Registers png, jpg, jpeg, bmp, gif, tif, tiff (overriding DevIL for those extensions)
        static void registerCodecs(void);
        static void unregisterCodecs(void);

    private:
        String mType;
        Container mEncoder;
        /// Encodes the image to 'stream' (an IStream*), shared by code() and codeToFile()
        void encodeTo(void* stream, MemoryDataStreamPtr& input, CodecDataPtr& pData) const;
    };

}

#endif
