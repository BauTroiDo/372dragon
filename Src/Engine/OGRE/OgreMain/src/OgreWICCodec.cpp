/*
-----------------------------------------------------------------------------
CY-Source addition to OGRE 1.2.5 (Dagon) - not part of the original distribution.
CYS: ImageCodec on the Windows Imaging Component (2026-09-12). See OgreWICCodec.h.
-----------------------------------------------------------------------------
*/
#include "OgreStableHeaders.h"
#include "OgreWICCodec.h"
#include "OgreException.h"
#include "OgreLogManager.h"
#include "OgreImage.h"
#include "OgrePixelFormat.h"

#if OGRE_PLATFORM == OGRE_PLATFORM_WIN32
#   define WIN32_LEAN_AND_MEAN
#   ifndef NOMINMAX
#       define NOMINMAX
#   endif
#   include <windows.h>
#   include <objbase.h>
#   include <wincodec.h>
#endif

#include <vector>

namespace Ogre {

#if OGRE_PLATFORM == OGRE_PLATFORM_WIN32
    namespace
    {
        /// COM for the calling thread for the duration of one codec call. A thread that already
        /// runs another apartment model (RPC_E_CHANGED_MODE) can still use WIC's free-threaded objects.
        struct ComScope
        {
            bool mUninit;
            ComScope() : mUninit(false)
            {
                HRESULT hr = CoInitializeEx(NULL, COINIT_MULTITHREADED);
                mUninit = SUCCEEDED(hr);
            }
            ~ComScope()
            {
                if (mUninit)
                    CoUninitialize();
            }
        };

        template <class T> struct ComPtrLite
        {
            T* p;
            ComPtrLite() : p(0) {}
            ~ComPtrLite() { if (p) p->Release(); }
            T** operator&() { return &p; }
            T* operator->() const { return p; }
        };

        void check(HRESULT hr, const char* what, const String& where)
        {
            if (FAILED(hr))
            {
                char buf[160];
                sprintf(buf, "WIC %s failed (hr=0x%08lX)", what, (unsigned long)hr);
                OGRE_EXCEPT(Exception::ERR_INTERNAL_ERROR, buf, where);
            }
        }

        const GUID* containerGuid(WICImageCodec::Container c)
        {
            switch (c)
            {
            case WICImageCodec::WIC_PNG:  return &GUID_ContainerFormatPng;
            case WICImageCodec::WIC_JPEG: return &GUID_ContainerFormatJpeg;
            case WICImageCodec::WIC_BMP:  return &GUID_ContainerFormatBmp;
            case WICImageCodec::WIC_TIFF: return &GUID_ContainerFormatTiff;
            default:                      return 0;
            }
        }

        std::vector<WICImageCodec*> gWICCodecs;
    }
#endif

    //---------------------------------------------------------------------
    WICImageCodec::WICImageCodec(const String& type, Container encoder)
        : mType(type), mEncoder(encoder)
    {
    }
    //---------------------------------------------------------------------
    void WICImageCodec::registerCodecs(void)
    {
#if OGRE_PLATFORM == OGRE_PLATFORM_WIN32
        struct Entry { const char* ext; Container enc; };
        static const Entry entries[] = {
            { "png", WIC_PNG }, { "jpg", WIC_JPEG }, { "jpeg", WIC_JPEG }, { "bmp", WIC_BMP },
            { "gif", WIC_DECODE_ONLY }, { "tif", WIC_TIFF }, { "tiff", WIC_TIFF } };
        for (size_t i = 0; i < sizeof(entries) / sizeof(entries[0]); ++i)
        {
            WICImageCodec* c = new WICImageCodec(entries[i].ext, entries[i].enc);
            Codec::registerCodec(c); // replaces DevIL's codec for this extension
            gWICCodecs.push_back(c);
        }
        LogManager::getSingleton().logMessage(
            "CYS: WIC image codecs registered: png jpg jpeg bmp gif tif tiff");
#endif
    }
    //---------------------------------------------------------------------
    void WICImageCodec::unregisterCodecs(void)
    {
#if OGRE_PLATFORM == OGRE_PLATFORM_WIN32
        for (size_t i = 0; i < gWICCodecs.size(); ++i)
        {
            Codec::unRegisterCodec(gWICCodecs[i]);
            delete gWICCodecs[i];
        }
        gWICCodecs.clear();
#endif
    }
    //---------------------------------------------------------------------
    Codec::DecodeResult WICImageCodec::decode(DataStreamPtr& input) const
    {
#if OGRE_PLATFORM == OGRE_PLATFORM_WIN32
        const String where = "WICImageCodec::decode";
        MemoryDataStream encoded(input); // whole file in memory
        ComScope com;
        ComPtrLite<IWICImagingFactory> factory;
        check(CoCreateInstance(CLSID_WICImagingFactory, NULL, CLSCTX_INPROC_SERVER,
            IID_IWICImagingFactory, (void**)&factory), "CoCreateInstance(ImagingFactory)", where);
        ComPtrLite<IWICStream> stream;
        check(factory->CreateStream(&stream), "CreateStream", where);
        check(stream->InitializeFromMemory(encoded.getPtr(), static_cast<DWORD>(encoded.size())),
            "InitializeFromMemory", where);
        ComPtrLite<IWICBitmapDecoder> decoder;
        check(factory->CreateDecoderFromStream(stream.p, NULL, WICDecodeMetadataCacheOnDemand, &decoder),
            "CreateDecoderFromStream", where);
        ComPtrLite<IWICBitmapFrameDecode> frame;
        check(decoder->GetFrame(0, &frame), "GetFrame", where);
        UINT w = 0, h = 0;
        check(frame->GetSize(&w, &h), "GetSize", where);
        ComPtrLite<IWICFormatConverter> conv;
        check(factory->CreateFormatConverter(&conv), "CreateFormatConverter", where);
        check(conv->Initialize(frame.p, GUID_WICPixelFormat32bppBGRA, WICBitmapDitherTypeNone, NULL, 0.0,
            WICBitmapPaletteTypeCustom), "FormatConverter::Initialize", where);

        const size_t stride = size_t(w) * 4;
        MemoryDataStreamPtr output(new MemoryDataStream(stride * h));
        check(conv->CopyPixels(NULL, static_cast<UINT>(stride), static_cast<UINT>(stride * h), output->getPtr()),
            "CopyPixels", where);

        ImageData* imgData = new ImageData();
        imgData->width = w;
        imgData->height = h;
        imgData->depth = 1;
        imgData->num_mipmaps = 0;
        imgData->flags = 0;
        imgData->format = PF_A8R8G8B8; // B,G,R,A bytes on little-endian = WIC 32bppBGRA
        imgData->size = static_cast<uint>(stride * h);

        DecodeResult ret;
        ret.first = output;
        ret.second = CodecDataPtr(imgData);
        return ret;
#else
        OGRE_EXCEPT(Exception::ERR_NOT_IMPLEMENTED, "WIC is Windows only", "WICImageCodec::decode");
#endif
    }
    //---------------------------------------------------------------------
    void WICImageCodec::encodeTo(void* streamPtr, MemoryDataStreamPtr& input, CodecDataPtr& pData) const
    {
#if OGRE_PLATFORM == OGRE_PLATFORM_WIN32
        const String where = "WICImageCodec::encode";
        const GUID* container = containerGuid(mEncoder);
        if (!container)
            OGRE_EXCEPT(Exception::ERR_NOT_IMPLEMENTED, "no WIC encoder for " + mType, where);
        ImageData* img = static_cast<ImageData*>(pData.getPointer());
        const uint w = img->width, h = img->height;

        // Convert the top level to B,G,R,A bytes
        std::vector<uchar> bgra(size_t(w) * h * 4);
        PixelBox src(w, h, 1, img->format, input->getPtr());
        PixelBox dst(w, h, 1, PF_A8R8G8B8, &bgra[0]);
        PixelUtil::bulkPixelConversion(src, dst);

        IStream* stream = static_cast<IStream*>(streamPtr);
        ComPtrLite<IWICImagingFactory> factory;
        check(CoCreateInstance(CLSID_WICImagingFactory, NULL, CLSCTX_INPROC_SERVER,
            IID_IWICImagingFactory, (void**)&factory), "CoCreateInstance(ImagingFactory)", where);
        ComPtrLite<IWICBitmap> bitmap;
        check(factory->CreateBitmapFromMemory(w, h, GUID_WICPixelFormat32bppBGRA, w * 4,
            static_cast<UINT>(bgra.size()), &bgra[0], &bitmap), "CreateBitmapFromMemory", where);
        ComPtrLite<IWICBitmapEncoder> encoder;
        check(factory->CreateEncoder(*container, NULL, &encoder), "CreateEncoder", where);
        check(encoder->Initialize(stream, WICBitmapEncoderNoCache), "Encoder::Initialize", where);
        ComPtrLite<IWICBitmapFrameEncode> frame;
        check(encoder->CreateNewFrame(&frame, NULL), "CreateNewFrame", where);
        check(frame->Initialize(NULL), "Frame::Initialize", where);
        check(frame->SetSize(w, h), "SetSize", where);
        WICPixelFormatGUID fmt = GUID_WICPixelFormat32bppBGRA; // the encoder may pick another one
        check(frame->SetPixelFormat(&fmt), "SetPixelFormat", where);
        check(frame->WriteSource(bitmap.p, NULL), "WriteSource", where); // converts as needed
        check(frame->Commit(), "Frame::Commit", where);
        check(encoder->Commit(), "Encoder::Commit", where);
#else
        (void)streamPtr; (void)input; (void)pData;
#endif
    }
    //---------------------------------------------------------------------
    void WICImageCodec::codeToFile(MemoryDataStreamPtr& input, const String& outFileName,
        CodecDataPtr& pData) const
    {
#if OGRE_PLATFORM == OGRE_PLATFORM_WIN32
        ComScope com;
        // file names are ACP / GBK byte strings in this engine
        int wn = MultiByteToWideChar(CP_ACP, 0, outFileName.c_str(), -1, NULL, 0);
        std::vector<wchar_t> wname(wn > 0 ? wn : 1, L'\0');
        MultiByteToWideChar(CP_ACP, 0, outFileName.c_str(), -1, &wname[0], wn);
        ComPtrLite<IWICImagingFactory> factory;
        check(CoCreateInstance(CLSID_WICImagingFactory, NULL, CLSCTX_INPROC_SERVER,
            IID_IWICImagingFactory, (void**)&factory), "CoCreateInstance(ImagingFactory)", "WICImageCodec::codeToFile");
        ComPtrLite<IWICStream> stream;
        check(factory->CreateStream(&stream), "CreateStream", "WICImageCodec::codeToFile");
        check(stream->InitializeFromFilename(&wname[0], GENERIC_WRITE), "InitializeFromFilename",
            "WICImageCodec::codeToFile");
        encodeTo(stream.p, input, pData);
#else
        (void)input; (void)outFileName; (void)pData;
#endif
    }
    //---------------------------------------------------------------------
    DataStreamPtr WICImageCodec::code(MemoryDataStreamPtr& input, CodecDataPtr& pData) const
    {
#if OGRE_PLATFORM == OGRE_PLATFORM_WIN32
        ComScope com;
        ComPtrLite<IStream> mem;
        check(CreateStreamOnHGlobal(NULL, TRUE, &mem), "CreateStreamOnHGlobal", "WICImageCodec::code");
        encodeTo(mem.p, input, pData);
        STATSTG st;
        check(mem->Stat(&st, STATFLAG_NONAME), "IStream::Stat", "WICImageCodec::code");
        size_t n = static_cast<size_t>(st.cbSize.QuadPart);
        MemoryDataStream* out = new MemoryDataStream(n);
        LARGE_INTEGER zero;
        zero.QuadPart = 0;
        mem->Seek(zero, STREAM_SEEK_SET, NULL);
        ULONG got = 0;
        mem->Read(out->getPtr(), static_cast<ULONG>(n), &got);
        return DataStreamPtr(out);
#else
        (void)input; (void)pData;
        OGRE_EXCEPT(Exception::ERR_NOT_IMPLEMENTED, "WIC is Windows only", "WICImageCodec::code");
#endif
    }

}
