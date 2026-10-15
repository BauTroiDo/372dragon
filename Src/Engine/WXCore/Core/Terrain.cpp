#include "Terrain.h"
#include "TerrainTileEditable.h"
#include "TerrainTileOptimized.h"
#include "WXResources.h"
#include "ieee.h"

#include <OgreMaterialManager.h>
#include <OgreSceneManager.h>
#include <OgreStringConverter.h>
#include <OgreTextureManager.h>
#include <OgreHardwarePixelBuffer.h>
#include <OgreResourceGroupManager.h>   // CYS-PARITY (L5b)
#include <OgreImage.h>
#include <OgreRoot.h>
#include <OgreGpuProgramManager.h> // CYS-PARITY: terrain fog variants
#include <OgreLogManager.h>
#include <cstdlib>
#include <OgreCysPerf.h> // CYS-PERF-FIX prewarm: ticks()
#include <algorithm>    // CYS-PARITY: _comboBrushes

// Mosaic Terrain ?

namespace WX {

struct Terrain::Atlas
{
    Ogre::SharedPtr<Ogre::Image> image;
    Ogre::TexturePtr texture;

    Atlas(void)
        : image()
        , texture()
    {
    }
};

Terrain::Terrain(void)
    : mData(NULL)

    , mTiles(NULL)
    , mMaterials()
    , mCurrentFogMode(Ogre::FOG_NONE)

    , mLightmapTextures()
    , mLightmapTextureSize(1024)
    , mLightmapQuality(LMQ_HIGH)

    , mIndexBuffer()
    , mIndexDatas()

    , mEditable(false)
    , mDisplayGridLine(false)
    , mDisplayGridType(false)
{
    mCysColorMapImage = 0;      // CYS-PARITY (L5b)
    mCysColorMapScale = 2;
    mData = new TerrainData;

    mAtlasTextureSize = 512;
    mAtlasPixmapSize = 64;
    mAtlasNumMipMaps = 6;
    assert(mAtlasPixmapSize >= ((size_t)1 << mAtlasNumMipMaps));
    mAtlasBlockSize = mAtlasTextureSize / mAtlasPixmapSize;
    mMaxAtlasBlockId = mAtlasBlockSize * mAtlasBlockSize;
    mAtlasBlockTexCoordInc = 1.0f / mAtlasBlockSize;

    // Mark as invalidate
    mSolidAtlasAllocInfo.blockId = mMaxAtlasBlockId;
    mTransparentAtlasAllocInfo.blockId = mMaxAtlasBlockId;
}

Terrain::~Terrain()
{
    clearGeometry();
    delete mCysColorMapImage;   // CYS-PARITY (L5b)
    mCysColorMapImage = 0;
    delete mData;
}

void
Terrain::clearGeometry(void)
{
    _deleteTileList();
    _deleteMaterials();
    _deleteIndexDatas();

    mGridLineInfos.clear();
    mGridTypeInfos.clear();
}

void
Terrain::reset()
{
    clearGeometry();
    mData->reset();
}

void
Terrain::_deleteTileList(void)
{
    for (TileList::const_iterator it = mTiles.begin(); it != mTiles.end(); ++it)
    {
        TerrainTile* tile = *it;
        delete tile;
    }
    mTiles.clear();
}

void
Terrain::_initIndexBuffer(size_t maxQuads)
{
    assert(maxQuads <= 65536/4);

    mIndexBuffer =
        Ogre::HardwareBufferManager::getSingleton().createIndexBuffer(
            Ogre::HardwareIndexBuffer::IT_16BIT,
            maxQuads * 6,
            Ogre::HardwareBuffer::HBU_STATIC_WRITE_ONLY);

    ushort* pIndex = static_cast<unsigned short*>(
        mIndexBuffer->lock(0, mIndexBuffer->getSizeInBytes(), Ogre::HardwareBuffer::HBL_DISCARD));

    for (size_t i = 0; i < maxQuads; ++i)
    {
        // NB: We should take care with the clockwise ordered quad vertices

        *pIndex++ = i*4 + 1;
        *pIndex++ = i*4 + 0;
        *pIndex++ = i*4 + 2;

        *pIndex++ = i*4 + 1;
        *pIndex++ = i*4 + 2;
        *pIndex++ = i*4 + 3;
    }

    mIndexBuffer->unlock();
}

Ogre::IndexData*
Terrain::_getIndexData(size_t numQuads)
{
    assert(!mIndexBuffer.isNull());
    assert(numQuads * 6 <= mIndexBuffer->getNumIndexes());

    Ogre::IndexData* indexData;

    IndexDataMap::const_iterator it = mIndexDatas.find(numQuads);
    if (it != mIndexDatas.end())
    {
        indexData = it->second;
    }
    else
    {
        indexData = new Ogre::IndexData;
        indexData->indexBuffer = mIndexBuffer;
        indexData->indexStart = 0;
        indexData->indexCount = numQuads * 6;

        std::pair<IndexDataMap::iterator, bool> inserted =
            mIndexDatas.insert(IndexDataMap::value_type(numQuads, indexData));
        assert(inserted.second && "Internal fault while create index data");
    }

    return indexData;
}

void
Terrain::_deleteIndexDatas(void)
{
    for (IndexDataMap::const_iterator it = mIndexDatas.begin(); it != mIndexDatas.end(); ++it)
    {
        Ogre::IndexData* indexData = it->second;
        delete indexData;
    }
    mIndexDatas.clear();

    mIndexBuffer.setNull();
}

void
Terrain::loadResource(Ogre::Resource* resource)
{
	const String& name = resource->getName();
    // CYS: whole-terrain lightmap (prepareLightmapTexture): the whole image, scaled to the texture size.
    if (name == "<Lightmap>(all)")
    {
        Ogre::Texture* wholeTexture = static_cast<Ogre::Texture*>(resource);
        wholeTexture->createInternalResources();
        if (mData->mLightmapImage)
            wholeTexture->getBuffer()->blitFromMemory(mData->mLightmapImage->getPixelBox());
        return;
    }
    // CYS-PARITY (L5b): CY Terrain::loadResource (Render.dll FUN_1800d2a70) "<colorMap>(x,z)": the tile's box of the
    //      colour map image (scaleSize texels per grid), blitted as is.
    if (name.compare(0, 11, "<colorMap>(") == 0 && mCysColorMapImage)
    {
        Ogre::StringVector vec = Ogre::StringUtil::split(name.substr(11, name.size() - 12), ",", 2);
        int nPosX = vec.size() == 2 ? Ogre::StringConverter::parseInt(vec[0]) : -1;
        int nPosZ = vec.size() == 2 ? Ogre::StringConverter::parseInt(vec[1]) : -1;
        if (nPosX < 0 || nPosX >= mData->mNumTilePerX || nPosZ < 0 || nPosZ >= mData->mNumTilePerZ)
            OGRE_EXCEPT(Ogre::Exception::ERR_INTERNAL_ERROR, "Unorganised colormap texture name '" + name + "'",
                "Terrain::loadResource");
        const size_t size = mCysColorMapScale * mData->mTileSize;
        Ogre::Texture* tex = static_cast<Ogre::Texture*>(resource);
        if (tex->getWidth() != size || tex->getHeight() != size)
        {
            tex->freeInternalResources();
            tex->setWidth(size);
            tex->setHeight(size);
        }
        tex->createInternalResources();
        size_t l = nPosX * size, t = nPosZ * size;
        size_t r = std::min(l + size, mCysColorMapImage->getWidth());
        size_t b = std::min(t + size, mCysColorMapImage->getHeight());
        if (r > l && b > t)
            tex->getBuffer()->blitFromMemory(mCysColorMapImage->getPixelBox().getSubVolume(Ogre::Box(l, t, r, b)));
        return;
    }
    if (name.find("<Lightmap>") != String::npos)
	{
        String::size_type left_parentheses = name.find_first_of('(');
        String::size_type right_parentheses = name.find_last_of(')');
        if (left_parentheses == String::npos ||
            right_parentheses == String::npos)
        {
            OGRE_EXCEPT(Ogre::Exception::ERR_INTERNAL_ERROR,
                "Unorganised lightmap texture name '" + name + "'",
                "Terrain::loadResource");
        }

        Ogre::StringVector vec = Ogre::StringUtil::split(
            name.substr(left_parentheses + 1, right_parentheses - left_parentheses - 1), ",", 2);
        if (vec.size() != 2)
        {
            OGRE_EXCEPT(Ogre::Exception::ERR_INTERNAL_ERROR,
                "Unorganised lightmap texture name '" + name + "'",
                "Terrain::loadResource");
        }

        int nPosX = Ogre::StringConverter::parseInt(vec[0]);
        int nPosZ = Ogre::StringConverter::parseInt(vec[1]);
        if (nPosX < 0 || nPosX >= mData->mNumTilePerX ||
            nPosZ < 0 || nPosZ >= mData->mNumTilePerZ)
        {
            OGRE_EXCEPT(Ogre::Exception::ERR_INTERNAL_ERROR,
                "Unorganised lightmap texture name '" + name + "'",
                "Terrain::loadResource");
        }

        uint uWidth, uHeight;
        if (getLightmapQuality() == LMQ_LOW)
        {
            uWidth = mData->mTileSize * 2;
            uHeight = mData->mTileSize * 2;
        }
        else
        {
            uWidth = mData->mTileSize * 8;
            uHeight = mData->mTileSize * 8;
        }

		Ogre::Texture* pTexture = static_cast<Ogre::Texture*>(resource);
        if (pTexture->getWidth() != uWidth || pTexture->getHeight() != uHeight)
        {
            pTexture->freeInternalResources();
            pTexture->setWidth(uWidth);
            pTexture->setHeight(uHeight);
        }
		pTexture->createInternalResources();

		Ogre::HardwarePixelBufferSharedPtr bufferPtr = pTexture->getBuffer();
        size_t l = nPosX * mData->mTileSize * 8;
        size_t t = nPosZ * mData->mTileSize * 8;
        size_t r = l + mData->mTileSize * 8;
        size_t b = t + mData->mTileSize * 8;
        if (r > mData->mLightmapImage->getWidth())
            r = mData->mLightmapImage->getWidth();
        if (b > mData->mLightmapImage->getHeight())
            b = mData->mLightmapImage->getHeight();
		bufferPtr->blitFromMemory(
			mData->mLightmapImage->getPixelBox().getSubVolume(Ogre::Box(l, t, r, b)));
	}
	else
	{
		for (AtlasArray::const_iterator it = mAtlases.begin(); it != mAtlases.end(); ++it)
		{
			if (it->texture.get() == resource)
			{
                assert(!it->image.isNull());
				it->texture->loadImage(*it->image);
				break;
			}
		}
	}
}

// CYS-PARITY: CY Render.dll Fairy::Terrain::_comboBrushes (FUN_1800cc830, packer FUN_1800cbf50, caller
// FUN_18003f9f0 = System::_postprocessScene when not editable). FACT (trace cy-world-1 w09, cy-login-2): every CY
// terrain draw samples one 4096x1024 A8R8G8B8 5-level texture on both layers; a tile = one draw for its one-layer
// grids + one for its two-layer grids (scene 12 / shadow 40 draws at Dali w09).
// Steps as in Render.dll: brush i -> image (w+64)x(h+64) filled 0xAB, source at (32,32), the 32 px borders = the
// source edge row/column scaled (bilinear), corners stay 0xAB; first-fit on a 128-column grid of 32 px cells
// (rows opened on demand, 32 px each); atlas 4096 x next_pow2(opened rows * 32), 4 mipmaps (bilinear halving);
// pixmap' = (inner box origin + pixmap * brush size) / atlas size; textures = { "ComboedBrush" }.
// INF: CY keeps the packer grid in the Terrain object; Dali after the login scene is still 1024 high, so it is
// reset per scene here.
static bool cysParityTerrainCombo(void)
{
    const char* v = std::getenv("CYS_PARITY_TERRAIN_COMBO");
    return !(v && v[0] == '0');
}

bool
Terrain::_comboBrushes(void)
{
    static const String comboName = "ComboedBrush";
    static const size_t comboWidth = 4096;
    static const size_t cell = 32;
    static const size_t cells = 128;
    static const size_t comboMipmaps = 4;

    if (!cysParityTerrainCombo() || !mData)
        return false;
    const size_t numTextures = mData->mTextures.size();
    if (numTextures == 0 || (numTextures == 1 && mData->mTextures[0] == comboName))
        return false;

    std::vector<Ogre::Image> padded(numTextures);
    std::vector<Ogre::Box> boxes(numTextures);
    std::vector<std::pair<size_t, size_t> > sizes(numTextures);
    std::vector<signed char> grid(cells * cells, -1);
    size_t usedHeight = 0;

    try
    {
        for (size_t i = 0; i < numTextures; ++i)
        {
            Ogre::Image src;
            src.load(mData->mTextures[i], BRUSH_RESOURCE_GROUP_NAME);
            if (Ogre::PixelUtil::isCompressed(src.getFormat()))
                OGRE_EXCEPT(Ogre::Exception::ERR_INVALIDPARAMS, "compressed brush '" + mData->mTextures[i] + "'",
                    "Terrain::_comboBrushes");
            const size_t w = src.getWidth(), h = src.getHeight();
            const size_t pw = w + 64, ph = h + 64;
            sizes[i] = std::make_pair(w, h);

            Ogre::Image& img = padded[i];
            img.loadDynamicImage(0, pw, ph, 1, src.getFormat(), true, 1, 0);
            memset(img.getData(), 0xAB, img.getSize());
            const Ogre::PixelBox s = src.getPixelBox();
            const Ogre::PixelBox d = img.getPixelBox();
            Ogre::PixelUtil::bulkPixelConversion(s, d.getSubVolume(Ogre::Box(32, 32, w + 32, h + 32)));
            Ogre::Image::scale(s.getSubVolume(Ogre::Box(0, 0, w, 1)), d.getSubVolume(Ogre::Box(32, 0, pw - 32, 32)));
            Ogre::Image::scale(s.getSubVolume(Ogre::Box(0, 0, 1, h)), d.getSubVolume(Ogre::Box(0, 32, 32, ph - 32)));
            Ogre::Image::scale(s.getSubVolume(Ogre::Box(w - 1, 0, w, h)), d.getSubVolume(Ogre::Box(pw - 32, 32, pw, ph - 32)));
            Ogre::Image::scale(s.getSubVolume(Ogre::Box(0, h - 1, w, h)), d.getSubVolume(Ogre::Box(32, ph - 32, pw - 32, ph)));

            // packer (FUN_1800cbf50): first fit, rows top-down, columns left-right; -1 = row not opened yet
            const size_t cw = (pw + cell - 1) / cell, ch = (ph + cell - 1) / cell;
            bool placed = false;
            for (size_t row = 0; !placed && cw <= cells && ch <= cells && row + ch <= cells; ++row)
            {
                for (size_t x = 0; x + cw <= cells; ++x)
                {
                    signed char& c = grid[row * cells + x];
                    if (c < 0)
                    {
                        usedHeight += cell;
                        std::fill(grid.begin() + row * cells, grid.begin() + (row + 1) * cells, 0);
                    }
                    if (c != 0)
                        continue;
                    // column by column, top-down; a row not opened yet is opened on the way (as Render.dll)
                    bool fits = true;
                    for (size_t xx = x; xx < x + cw && fits; ++xx)
                    {
                        for (size_t yy = row; yy < row + ch; ++yy)
                        {
                            signed char cc = grid[yy * cells + xx];
                            if (cc == 1)
                            {
                                fits = false;
                                break;
                            }
                            if (cc < 0)
                            {
                                usedHeight += cell;
                                std::fill(grid.begin() + yy * cells, grid.begin() + (yy + 1) * cells, 0);
                            }
                        }
                    }
                    if (!fits)
                        continue;
                    for (size_t yy = row; yy < row + ch; ++yy)
                        for (size_t xx = x; xx < x + cw; ++xx)
                            grid[yy * cells + xx] = 1;
                    boxes[i] = Ogre::Box(x * cell, row * cell, x * cell + pw, row * cell + ph);
                    placed = true;
                    break;
                }
            }
            if (!placed)
                OGRE_EXCEPT(Ogre::Exception::ERR_INVALIDPARAMS, "Alloc Terrain Combo Box Failed! '" +
                    mData->mTextures[i] + "'", "Terrain::_comboBrushes");
        }
    }
    catch (const Ogre::Exception& e)
    {
        Ogre::LogManager::getSingleton().logMessage("CYS parity: terrain combo cancelled for '" + mData->mName +
            "': " + e.getFullDescription());
        return false;
    }

    size_t comboHeight = 1;
    while (comboHeight < usedHeight)
        comboHeight *= 2;

    if (!mComboedBrushTexture.isNull())
    {
        Ogre::TextureManager::getSingleton().remove(mComboedBrushTexture->getHandle());
        mComboedBrushTexture.setNull();
    }
    else if (Ogre::TextureManager::getSingleton().resourceExists(comboName))
    {
        Ogre::TextureManager::getSingleton().remove(comboName);
    }

    Ogre::Image combo;
    combo.loadDynamicImage(0, comboWidth, comboHeight, 1, Ogre::PF_A8R8G8B8, true, 1, comboMipmaps);
    memset(combo.getData(), 0, combo.getSize());
    const Ogre::PixelBox level0 = combo.getPixelBox(0, 0);
    for (size_t i = 0; i < numTextures; ++i)
    {
        Ogre::PixelUtil::bulkPixelConversion(padded[i].getPixelBox(), level0.getSubVolume(boxes[i]));
        padded[i].freeData();
    }
    for (size_t mip = 1; mip <= comboMipmaps; ++mip)
        Ogre::Image::scale(combo.getPixelBox(0, mip - 1), combo.getPixelBox(0, mip));

    // pixmaps -> combo coordinates (inner box = the source brush)
    for (TerrainData::PixmapArray::iterator it = mData->mPixmaps.begin(); it != mData->mPixmaps.end(); ++it)
    {
        size_t t = it->textureId;
        if (t >= numTextures)
            continue;
        const Real ox = (Real)(boxes[t].left + 32), oy = (Real)(boxes[t].top + 32);
        const Real w = (Real)sizes[t].first, h = (Real)sizes[t].second;
        it->left = (w * it->left + ox) / comboWidth;
        it->top = (h * it->top + oy) / comboHeight;
        it->right = ((it->right - 1.0f) * w + ox + w) / comboWidth;
        it->bottom = ((it->bottom - 1.0f) * h + oy + h) / comboHeight;
        it->textureId = 0;
    }

    mComboedBrushTexture = Ogre::TextureManager::getSingleton().loadImage(comboName, BRUSH_RESOURCE_GROUP_NAME,
        combo, Ogre::TEX_TYPE_2D, (int)comboMipmaps, 1.0f);

    Ogre::LogManager::getSingleton().logMessage("CYS parity: terrain '" + mData->mName + "' " +
        Ogre::StringConverter::toString(numTextures) + " brushes comboed into " + comboName + " " +
        Ogre::StringConverter::toString(comboWidth) + "x" + Ogre::StringConverter::toString(comboHeight));

    mData->mTextures.clear();
    mData->mTextures.push_back(comboName);

    // atlas state / materials of the old brushes are stale
    clearGeometry();
    return true;
}

size_t
Terrain::_getPixmapAtlasId(size_t pixmapId)
{
    assert(pixmapId < mData->mPixmaps.size());
    if (pixmapId >= mAtlasPixmaps.size())
        mAtlasPixmaps.resize(pixmapId + 1);

    if (!mAtlasPixmaps[pixmapId].atlasId)
    {
        _createAtlasPixmap(pixmapId);
    }

    assert(mAtlasPixmaps[pixmapId].atlasId > 0 && mAtlasPixmaps[pixmapId].atlasId <= mAtlases.size());
    return mAtlasPixmaps[pixmapId].atlasId - 1;
}

void
Terrain::_createAtlasPixmap(size_t pixmapId)
{
    const TerrainData::Pixmap& pixmap = mData->mPixmaps[pixmapId];
    size_t textureId = pixmap.textureId;
    assert(textureId < mData->mTextures.size());
    const String& textureName = mData->mTextures[textureId];

    // If the atlas texture already exist, use it.

    AtlasArray::const_iterator it;
    for (it = mAtlases.begin(); it != mAtlases.end(); ++it)
    {
        if (it->texture->getName() == textureName)
            break;
    }
    if (it != mAtlases.end())
    {
        // Fill up atlas pixmap info
        size_t atlasId = it - mAtlases.begin() + 1;
        mAtlasPixmaps[pixmapId].atlasId = atlasId;
        mAtlasPixmaps[pixmapId].left = pixmap.left;
        mAtlasPixmaps[pixmapId].top = pixmap.top;
        mAtlasPixmaps[pixmapId].right = pixmap.right;
        mAtlasPixmaps[pixmapId].bottom = pixmap.bottom;
        return;
    }

    // If texture already loaded and is composited, use it without any modify.
    Ogre::TexturePtr texture = Ogre::TextureManager::getSingleton().getByName(textureName);
    if (!texture.isNull() &&
        (texture->getWidth() > mAtlasPixmapSize || texture->getHeight() > mAtlasPixmapSize))
    {
        mAtlases.push_back(Atlas());
        Atlas& atlas = mAtlases.back();

        atlas.texture = texture;

        // Fill up atlas pixmap info
        size_t atlasId = mAtlases.size();
        mAtlasPixmaps[pixmapId].atlasId = atlasId;
        mAtlasPixmaps[pixmapId].left = pixmap.left;
        mAtlasPixmaps[pixmapId].top = pixmap.top;
        mAtlasPixmaps[pixmapId].right = pixmap.right;
        mAtlasPixmaps[pixmapId].bottom = pixmap.bottom;
        return;
    }

    // Load the image
    Ogre::Image image;
    image.load(textureName, BRUSH_RESOURCE_GROUP_NAME);

    // If the image is composited, use it without any modify.
    if (image.getWidth() > mAtlasPixmapSize || image.getHeight() > mAtlasPixmapSize)
    {
        mAtlases.push_back(Atlas());
        Atlas& atlas = mAtlases.back();

        // re-use the loaded image avoid load it again
        atlas.texture =
            Ogre::TextureManager::getSingleton()
            .loadImage(textureName, BRUSH_RESOURCE_GROUP_NAME, image);

        // Fill up atlas pixmap info
        size_t atlasId = mAtlases.size();
        mAtlasPixmaps[pixmapId].atlasId = atlasId;
        mAtlasPixmaps[pixmapId].left = pixmap.left;
        mAtlasPixmaps[pixmapId].top = pixmap.top;
        mAtlasPixmaps[pixmapId].right = pixmap.right;
        mAtlasPixmaps[pixmapId].bottom = pixmap.bottom;
        return;
    }

    // Composite into the atlas texture.

    bool isTransparent = image.getHasAlpha();
    AtlasAllocInfo& allocInfo = isTransparent ? mTransparentAtlasAllocInfo : mSolidAtlasAllocInfo;
    if (allocInfo.blockId >= mMaxAtlasBlockId)
    {
        // Use special name to avoid confuse with other reference with this texture
        String atlasName = "<Terrain/Atlas>:" + Ogre::StringConverter::toString(mAtlases.size());

        mAtlases.push_back(Atlas());
        Atlas& atlas = mAtlases.back();

        Ogre::PixelFormat pixelFormat = isTransparent ? Ogre::PF_A8R8G8B8 : Ogre::PF_X8R8G8B8;
        atlas.image.bind(new Ogre::Image);
        atlas.image->loadDynamicImage(0, mAtlasTextureSize, mAtlasTextureSize, 1, pixelFormat, true, 1, mAtlasNumMipMaps);
        memset(atlas.image->getData(), 0, atlas.image->getSize());

        atlas.texture =
            Ogre::TextureManager::getSingleton().createManual(atlasName,
                BRUSH_RESOURCE_GROUP_NAME, Ogre::TEX_TYPE_2D,
                atlas.image->getWidth(), atlas.image->getHeight(),
                mAtlasNumMipMaps, atlas.image->getFormat(),
                Ogre::TU_DYNAMIC_WRITE_ONLY_DISCARDABLE,
                this);

        allocInfo.atlasId = mAtlases.size();
        allocInfo.blockId = 0;
    }

    // Copy origin pixmap to atlas image
    Atlas& atlas = mAtlases[allocInfo.atlasId - 1];
    int blockX = allocInfo.blockId % mAtlasBlockSize;
    int blockY = allocInfo.blockId / mAtlasBlockSize;
    Ogre::PixelBox dst = atlas.image->getPixelBox().getSubVolume(Ogre::Box(
        blockX * mAtlasPixmapSize,
        blockY * mAtlasPixmapSize,
        blockX * mAtlasPixmapSize + mAtlasPixmapSize,
        blockY * mAtlasPixmapSize + mAtlasPixmapSize));
    Ogre::PixelBox src = image.getPixelBox().getSubVolume(Ogre::Box(
        fast_ifloor(pixmap.left * image.getWidth() + 0.5f),
        fast_ifloor(pixmap.top * image.getHeight() + 0.5f),
        fast_ifloor(pixmap.right * image.getWidth() + 0.5f),
        fast_ifloor(pixmap.bottom * image.getHeight() + 0.5f)));
    if (src.getWidth() == mAtlasPixmapSize && src.getHeight() == mAtlasPixmapSize)
        Ogre::PixelUtil::bulkPixelConversion(src, dst);
    else
        Ogre::Image::scale(src, dst);

    // Generate mipmaps manual
    for (size_t mipmap = 1; mipmap <= mAtlasNumMipMaps; ++mipmap)
    {
        src = dst;
        size_t pixmapSize = mAtlasPixmapSize >> mipmap;
        dst = atlas.image->getPixelBox(0, mipmap).getSubVolume(Ogre::Box(
            blockX * pixmapSize,
            blockY * pixmapSize,
            blockX * pixmapSize + pixmapSize,
            blockY * pixmapSize + pixmapSize));
        Ogre::Image::scale(src, dst);
    }

    // Notify that the atlas texture need to reload
    if (atlas.texture->isLoaded())
        atlas.texture->unload();

    ++allocInfo.blockId;

    // Fill up atlas pixmap info

    mAtlasPixmaps[pixmapId].atlasId = allocInfo.atlasId;
    mAtlasPixmaps[pixmapId].left = blockX * mAtlasBlockTexCoordInc + 0.5f / mAtlasTextureSize;
    mAtlasPixmaps[pixmapId].top = blockY * mAtlasBlockTexCoordInc + 0.5f / mAtlasTextureSize;
    mAtlasPixmaps[pixmapId].right = mAtlasPixmaps[pixmapId].left + mAtlasBlockTexCoordInc -  1.0f / mAtlasTextureSize;
    mAtlasPixmaps[pixmapId].bottom = mAtlasPixmaps[pixmapId].top + mAtlasBlockTexCoordInc -  1.0f / mAtlasTextureSize;
}

std::pair<Real, Real>
Terrain::_getPixmapCorner(const TerrainData::LayerInfo& layerInfo, TerrainData::Corner corner, uint flags) const
{
    assert(layerInfo.pixmapId && "Internal fault get pixmap corner");
	assert(0 <= corner && corner < 4 && "Invalid corner");
	assert(0 <= layerInfo.orientation && layerInfo.orientation < 16 && "Invalid orientation");

	// NOTE: This enum should be as same order as fields of 'Pixmap', search [Pixmap Fields Order] for detail
	enum {
		Left,
		Top,
		Right,
		Bottom,
	};

	// NOTE: This map is dependence 'OrientationFlags' and 'Corner', search [Corner Map] for detail
	static const int cornerIndexMap[2][16][4][2] =
	{
        Left,   Top,    Right,  Top,    Left,   Bottom, Right,  Bottom,
        Right,  Top,    Left,   Top,    Right,  Bottom, Left,   Bottom,
        Left,   Bottom, Right,  Bottom, Left,   Top,    Right,  Top,
        Right,  Bottom, Left,   Bottom, Right,  Top,    Left,   Top,

        //----------------------------------------

        Right,  Top,    Right,  Bottom, Left,   Top,    Left,   Bottom,
        Left,   Top,    Left,   Bottom, Right,  Top,    Right,  Bottom,
        Right,  Bottom, Right,  Top,    Left,   Bottom, Left,   Top,
        Left,   Bottom, Left,   Top,    Right,  Bottom, Right,  Top,

        //------------------------------------------------------------

        Left,   Top,    Right,  Top,    Left,   Bottom, Left,   Top,
        Right,  Top,    Left,   Top,    Right,  Bottom, Right,  Top,
        Left,   Bottom, Right,  Bottom, Left,   Top,    Left,   Bottom,
        Right,  Bottom, Left,   Bottom, Right,  Top,    Right,  Bottom,

        //----------------------------------------

        Right,  Top,    Right,  Bottom, Left,   Top,    Right,  Top,
        Left,   Top,    Left,   Bottom, Right,  Top,    Left,   Top,
        Right,  Bottom, Right,  Top,    Left,   Bottom, Right,  Bottom,
        Left,   Bottom, Left,   Top,    Right,  Bottom, Left,   Bottom,

        //----------------------------------------------------------------------

        Left,   Top,    Right,  Top,    Left,   Bottom, Right,  Bottom,
        Right,  Top,    Left,   Top,    Right,  Bottom, Left,   Bottom,
        Left,   Bottom, Right,  Bottom, Left,   Top,    Right,  Top,
        Right,  Bottom, Left,   Bottom, Right,  Top,    Left,   Top,

        //----------------------------------------

        Right,  Top,    Right,  Bottom, Left,   Top,    Left,   Bottom,
        Left,   Top,    Left,   Bottom, Right,  Top,    Right,  Bottom,
        Right,  Bottom, Right,  Top,    Left,   Bottom, Left,   Top,
        Left,   Bottom, Left,   Top,    Right,  Bottom, Right,  Top,

        //------------------------------------------------------------

        Left,   Top,    Right,  Top,    Right,  Top,    Right,  Bottom,
        Right,  Top,    Left,   Top,    Left,   Top,    Left,   Bottom,
        Left,   Bottom, Right,  Bottom, Right,  Bottom, Right,  Top,
        Right,  Bottom, Left,   Bottom, Left,   Bottom, Left,   Top,

        //----------------------------------------

        Right,  Top,    Right,  Bottom, Right,  Bottom, Left,   Bottom,
        Left,   Top,    Left,   Bottom, Left,   Bottom, Right,  Bottom,
        Right,  Bottom, Right,  Top,    Right,  Top,    Left,   Top,
        Left,   Bottom, Left,   Top,    Left,   Top,    Right,  Top,
    };

    assert(layerInfo.pixmapId <= mAtlasPixmaps.size());
    const AtlasPixmap& pixmap = mAtlasPixmaps[layerInfo.pixmapId-1];
    assert(pixmap.atlasId);
    const int *indices = cornerIndexMap[(flags & TerrainData::GridInfo::FlipDiagonal) != 0][layerInfo.orientation][corner];
	return std::pair<Real, Real>((&pixmap.left)[indices[0]], (&pixmap.left)[indices[1]]);
}

void
Terrain::resetSurfaceParams(void)
{
    for (MaterialMap::const_iterator it = mMaterials.begin(); it != mMaterials.end(); ++it)
    {
        _applySurfaceParams(it->second);
    }
}

void
Terrain::_applySurfaceParams(const Ogre::MaterialPtr& material) const
{
    material->setAmbient(mData->mSurfaceParams.ambient);
    material->setDiffuse(mData->mSurfaceParams.diffuse);
    material->setSpecular(mData->mSurfaceParams.specular);
    material->setSelfIllumination(mData->mSurfaceParams.emissive);
    material->setShininess(mData->mSurfaceParams.shininess);
}

void
Terrain::_updateMaterials(void) const
{
    if (!mData->mSupportedFogReplacements.empty())
    {
        Ogre::FogMode currentFogMode = Ogre::Root::getSingleton()._getCurrentSceneManager()->getFogMode();
        _cysSyncFogMode(currentFogMode);
    }
}

void
Terrain::_cysSyncFogMode(Ogre::FogMode currentFogMode) const
{
    if (mData->mSupportedFogReplacements.empty() || mCurrentFogMode == currentFogMode)
        return;
    Ogre::MaterialVariantResolver* resolver = Ogre::MaterialManager::getSingleton().getVariantResolver();
    for (MaterialMap::const_iterator it = mMaterials.begin(); it != mMaterials.end(); ++it)
    {
        _applyFogMode(it->second, mCurrentFogMode, currentFogMode);
        // CYS-PERF-FIX fogvariant: a runtime variant cloned before (terrain shadow receiver, built by cysPrewarm or
        // by an earlier frame) still has the programs of the old fog mode
        if (resolver && !it->second.isNull())
            resolver->forgetMaterial(it->second.getPointer());
    }
    mCurrentFogMode = currentFogMode;
}

void
Terrain::_applyFogMode(const Ogre::MaterialPtr& material, Ogre::FogMode oldFogMode, Ogre::FogMode newFogMode) const
{
    if (oldFogMode == newFogMode)
        return;

    if (mData->mSupportedFogReplacements.empty())
        return;

    String newProgramName;

    Ogre::Material::TechniqueIterator ti = material->getTechniqueIterator();
    while (ti.hasMoreElements())
    {
        Ogre::Technique* technique = ti.getNext();
        Ogre::Technique::PassIterator pi = technique->getPassIterator();
        while (pi.hasMoreElements())
        {
            Ogre::Pass* pass = pi.getNext();
            if (pass->hasVertexProgram() &&
                _checkFogProgramName(pass->getVertexProgram(), oldFogMode, newFogMode, newProgramName))
            {
                pass->setVertexProgram(newProgramName);
            }
            if (pass->hasFragmentProgram() &&
                _checkFogProgramName(pass->getFragmentProgram(), oldFogMode, newFogMode, newProgramName))
            {
                pass->setFragmentProgram(newProgramName);
            }
            if (pass->hasShadowCasterVertexProgram() &&
                _checkFogProgramName(pass->getShadowCasterVertexProgram(), oldFogMode, newFogMode, newProgramName))
            {
                pass->setShadowCasterVertexProgram(newProgramName);
            }
            if (pass->hasShadowReceiverVertexProgram() &&
                _checkFogProgramName(pass->getShadowReceiverVertexProgram(), oldFogMode, newFogMode, newProgramName))
            {
                pass->setShadowReceiverVertexProgram(newProgramName);
            }
            if (pass->hasShadowReceiverFragmentProgram() &&
                _checkFogProgramName(pass->getShadowReceiverFragmentProgram(), oldFogMode, newFogMode, newProgramName))
            {
                pass->setShadowReceiverFragmentProgram(newProgramName);
            }
        }
    }
}

bool
Terrain::_checkFogProgramName(const Ogre::GpuProgramPtr& program, Ogre::FogMode oldFogMode, Ogre::FogMode newFogMode, String& newProgramName) const
{
    const String& programName = program->getName();

    TerrainData::FogReplacements::const_iterator itfr, itfrend;
    itfrend = mData->mSupportedFogReplacements.end();
    for (itfr = mData->mSupportedFogReplacements.begin(); itfr != itfrend; ++itfr)
    {
        if (programName == itfr->programNames[oldFogMode])
        {
            newProgramName = itfr->programNames[newFogMode];
            return true;
        }
    }

    // CYS-PARITY: the fog replacement table only names the four legacy programs, so the colour-map terrain programs
    // (Terrain/*ColorMap*_ps, every scene with <useColorMap>) never got their "%fog_linear" variant and the terrain was
    // drawn without fog. FACT (d3d9 trace, Docs/specs/render/d3d9-parity_vi.md): the CY 3.71 terrain pixel shader of
    // erengu_DL has fog_colour/fog_params (ARB_fog_linear=1); CY Render.dll keeps the bare suffixes "%fog_exp",
    // "%fog_exp2", "%fog_linear" next to the legacy table. Same rule here: <base>[%fog_<mode>] when that program exists
    // (FairyTerrainColorMap.program defines %fog_linear for all of them, %fog_exp2 for most), else the base program.
    // CYS_PARITY_TERRAIN_FOG=0 restores the table-only behaviour for A/B.
    {
        static const bool enabled = []() {
            const char* v = getenv("CYS_PARITY_TERRAIN_FOG");
            return !(v && v[0] == '0');
        }();
        if (!enabled)
            return false;
        static const char* const kSuffix[4] = { "", "%fog_exp", "%fog_exp2", "%fog_linear" };
        if (programName.find('@') != String::npos || int(newFogMode) < 0 || int(newFogMode) > 3)
            return false; // material-system variant already derived from the program: leave it
        String base = programName;
        const size_t fogAt = base.find("%fog_");
        if (fogAt != String::npos)
            base.erase(fogAt);
        String candidate = base + kSuffix[newFogMode];
        if (candidate != base)
        {
            Ogre::GpuProgramPtr p = Ogre::GpuProgramManager::getSingleton().getByName(candidate);
            bool usable = !p.isNull() && p->isSupported();
            if (usable)
            {
                try
                {
                    p->load();
                }
                catch (const Ogre::Exception& e)
                {
                    Ogre::LogManager::getSingleton().logMessage("CYS parity: terrain fog program " + candidate +
                                                                " failed to load: " + e.getDescription());
                    usable = false;
                }
            }
            if (!usable)
                candidate = base;
        }
        if (candidate == programName)
            return false;
        newProgramName = candidate;
        return true;
    }
}

const Ogre::MaterialPtr&
Terrain::_getGridMaterial(const TerrainData::GridInfo &gridInfo, ushort depthBias, int nTileX, int nTileZ)
{
    assert(mData != NULL);

    size_t textureIds[TerrainData::NumLayers] = { 0 };
    for (size_t i = 0; i < TerrainData::NumLayers; ++i)
    {
        if (gridInfo.layers[i].pixmapId)
        {
            textureIds[i] = _getPixmapAtlasId(gridInfo.layers[i].pixmapId - 1) + 1;
        }
    }
    assert(textureIds[0] && "Internal fault while create grid material");

    bool lightmapped = mData->mLightmapImage && getLightmapQuality() != LMQ_NONE;
    // CYS-PARITY (L5b): the per-tile colour map makes the material per tile too
    ulong lightmapId = (lightmapped || _cysColorMapTiles()) ? (nTileZ << 16) | nTileX : ~0;

    MaterialId id(textureIds[0], textureIds[1], lightmapId, depthBias);

    // find the material that already created
    MaterialMap::const_iterator it = mMaterials.find(id);
    if (it != mMaterials.end())
        return it->second;

    String name = "Terrain/";
    if (!mData->mName.empty())
        name += mData->mName + "/";
    name += Ogre::StringConverter::toString(textureIds[0]) + "." + Ogre::StringConverter::toString(textureIds[1]);
    if (depthBias)
        name += "_" + Ogre::StringConverter::toString(depthBias);

    String lightmapName = "<Lightmap>(" +
        Ogre::StringConverter::toString(nTileX / mData->mTileSize) + "," +
        Ogre::StringConverter::toString(nTileZ / mData->mTileSize) + ")";
    if (lightmapped)
        name += "_" + lightmapName;
    else if (_cysColorMapTiles())   // CYS-PARITY (L5b)
        name += "_<colorMap>(" + Ogre::StringConverter::toString(nTileX / mData->mTileSize) + "," +
                Ogre::StringConverter::toString(nTileZ / mData->mTileSize) + ")";

	Ogre::MaterialPtr material = Ogre::MaterialManager::getSingleton().getByName(name);
    if (material.isNull())
    {
        // get user supplied material
        String templateName = textureIds[1] ? "TwoLayer" : "OneLayer";
		if (lightmapped)
            templateName += "Lightmap";

        TerrainData::MaterialTemplates::const_iterator it =
            mData->mMaterialTemplates.find(templateName);
        if (it == mData->mMaterialTemplates.end())
            OGRE_EXCEPT(Ogre::Exception::ERR_ITEM_NOT_FOUND,
                "Can't found grid material template for '" + templateName + "'!", 
                "Terrain::_getGridMaterial");

        const String& baseName = it->second;
        Ogre::MaterialPtr templateMaterial = Ogre::MaterialManager::getSingleton().getByName(baseName);
        if (templateMaterial.isNull())
            OGRE_EXCEPT(Ogre::Exception::ERR_ITEM_NOT_FOUND, 
                "Can't load grid material template '" + baseName + "'!", 
                "Terrain::_getGridMaterial");

        // clone the material
        material = templateMaterial->clone(name, true, BRUSH_RESOURCE_GROUP_NAME);

        // Setup texture alias list
        Ogre::AliasTextureNamePairList aliasList;
        aliasList["<layer0>"] = mAtlases[textureIds[0]-1].texture->getName();
        if (textureIds[1])
            aliasList["<layer1>"] = mAtlases[textureIds[1]-1].texture->getName();
        if (lightmapped)
            aliasList["<lightmap>"] = lightmapName;
        // CYS: B/C terrain colour map (.Terrain <colorMap filename>): the Terrain/*ColorMap* templates of
        //      FairyTerrainColorMap*.material sample "<colorMap>", which stayed unresolved (blank = black terrain).
        if (mData->mCYSExtras.hasColorMap && !mData->mCYSExtras.colorMapFilename.empty())
            aliasList["<colorMap>"] = mData->mCYSExtras.colorMapFilename;
        // CYS-PARITY (L5b): CY _getGridMaterial (FUN_1800cfa30) "<colorMap>(x,z)" of the tile
        if (_cysColorMapTiles())
            aliasList["<colorMap>"] = "<colorMap>(" + Ogre::StringConverter::toString(nTileX / mData->mTileSize) + "," +
                                      Ogre::StringConverter::toString(nTileZ / mData->mTileSize) + ")";
        // CYS: B/C templates sample "<lightmap>" with texture coordinate set 7 (whole-terrain UV, see
        //      TerrainTileOptimized): give them the whole-terrain lightmap instead of this tile's cut.
        if (lightmapped)
        {
            bool wholeLightmap = false;
            Ogre::Material::TechniqueIterator cysTechniques = templateMaterial->getTechniqueIterator();
            while (cysTechniques.hasMoreElements() && !wholeLightmap)
            {
                Ogre::Technique::PassIterator cysPasses = cysTechniques.getNext()->getPassIterator();
                while (cysPasses.hasMoreElements() && !wholeLightmap)
                {
                    Ogre::Pass::TextureUnitStateIterator cysUnits = cysPasses.getNext()->getTextureUnitStateIterator();
                    while (cysUnits.hasMoreElements())
                    {
                        const Ogre::TextureUnitState* unit = cysUnits.getNext();
                        if (unit->getTextureNameAlias() == "<lightmap>" && unit->getTextureCoordSet() == 7)
                        {
                            wholeLightmap = true;
                            break;
                        }
                    }
                }
            }
            if (wholeLightmap && !_cysTileMaps())   // CYS-PARITY (L5b): CY keeps the tile's lightmap
                aliasList["<lightmap>"] = "<Lightmap>(all)";
        }

        // Applies texture names
        material->applyTextureAliases(aliasList);

        // Applies surface params
        _applySurfaceParams(material);

        // Applies fog
        _applyFogMode(material, Ogre::FOG_NONE, mCurrentFogMode);

        // Adjust other material attributes
        Ogre::Material::TechniqueIterator ti = material->getTechniqueIterator();
        while (ti.hasMoreElements())
        {
            Ogre::Technique* technique = ti.getNext();
            Ogre::Technique::PassIterator pi = technique->getPassIterator();
            while (pi.hasMoreElements())
            {
                Ogre::Pass* pass = pi.getNext();
                if (depthBias)
                {
#if OGRE_VERSION >= 0x010300
                    pass->setDepthBias(depthBias + pass->getDepthBiasConstant(), pass->getDepthBiasSlopeScale());
#else
                    pass->setDepthBias(depthBias + pass->getDepthBias());
#endif
                }
            }
        }
    }

    // The material will load on demand

    std::pair<MaterialMap::iterator, bool> inserted =
        mMaterials.insert(MaterialMap::value_type(id, material));
    assert(inserted.second && "Internal fault while create grid material");
    return inserted.first->second;
}

void
Terrain::_deleteMaterials(void)
{
    Ogre::MaterialManager* materialManager = Ogre::MaterialManager::getSingletonPtr();
    // So we can delete this terrain after material manager is delete
    if (materialManager)
    {
        for (MaterialMap::const_iterator it = mMaterials.begin(); it != mMaterials.end(); ++it)
        {
            Ogre::ResourceHandle handle = it->second->getHandle();

            materialManager->remove(handle);
        }
    }
    mMaterials.clear();

    Ogre::TextureManager* textureManager = Ogre::TextureManager::getSingletonPtr();
    if (textureManager)
    {
        for (AtlasArray::const_iterator it = mAtlases.begin(); it != mAtlases.end(); ++it)
        {
            // Only remove composited textures.
            if (!it->texture.isNull() && !it->image.isNull())
            {
                textureManager->remove(it->texture->getHandle());
            }
        }

        for (TextureList::const_iterator it = mLightmapTextures.begin(); it != mLightmapTextures.end(); ++it)
        {
            textureManager->remove((*it)->getHandle());
        }
    }
    mAtlases.clear();
    mLightmapTextures.clear();

    mAtlasPixmaps.clear();

    // Mark as invalidate
    mSolidAtlasAllocInfo.blockId = mMaxAtlasBlockId;
    mTransparentAtlasAllocInfo.blockId = mMaxAtlasBlockId;
}

bool
Terrain::_cysTileMaps(void)
{
    static const bool on = []() {
        const char* v = std::getenv("CYS_PARITY_TERRAIN_TILEMAPS");
        return !(v && v[0] == '0');
    }();
    return on;
}

// CYS-PARITY (L5b): CY Terrain (Render.dll FUN_1800d3ab0): with useColorMap, one "<colorMap>(x,z)" texture per tile of
// scaleSize x tileSize texels, A8R8G8B8, automatic mipmaps, filled by loadResource from the colour map image.
// FACT trace cy-login-2: erengu_DL s3 = 64x64 A8R8G8B8 per tile (512x512 Color.tga, 256 grids, tile 32).
void
Terrain::_cysPrepareColorMapTextures(void)
{
    delete mCysColorMapImage;
    mCysColorMapImage = 0;
    const CYSTerrainExtras& x = mData->mCYSExtras;
    if (!_cysTileMaps() || mEditable || !x.hasColorMap || x.colorMapFilename.empty() || !mData->mXSize)
        return;
    try
    {
        Ogre::ResourceGroupManager& rgm = Ogre::ResourceGroupManager::getSingleton();
        const String group = rgm.findGroupContainingResource(x.colorMapFilename);
        Ogre::Image* image = new Ogre::Image;
        mCysColorMapImage = image;
        image->load(x.colorMapFilename, group);
    }
    catch (const Ogre::Exception& e)
    {
        Ogre::LogManager::getSingleton().logMessage("CYS parity: colour map '" + x.colorMapFilename +
            "' not loaded, whole-terrain colour map kept: " + e.getDescription());
        delete mCysColorMapImage;
        mCysColorMapImage = 0;
        return;
    }
    // scaleSize attribute; INF: absent = width / xsize (Color.tga = xsize x 2, CY trace 64 texels per 32-grid tile)
    int scale = x.colorMapScaleSize.empty() ? 0 : Ogre::StringConverter::parseInt(x.colorMapScaleSize);
    if (scale <= 0)
        scale = (int)std::max<size_t>(1, mCysColorMapImage->getWidth() / mData->mXSize);
    mCysColorMapScale = (size_t)scale;
    const uint size = (uint)(mCysColorMapScale * mData->mTileSize);
    Ogre::TextureManager& tm = Ogre::TextureManager::getSingleton();
    for (int z = 0; z < mData->mNumTilePerZ; ++z)
    {
        for (int t = 0; t < mData->mNumTilePerX; ++t)
        {
            const String n = "<colorMap>(" + Ogre::StringConverter::toString(t) + "," + Ogre::StringConverter::toString(z) + ")";
            if (!tm.getByName(n).isNull())
                tm.remove(n);
            mLightmapTextures.push_back(tm.createManual(n, BRUSH_RESOURCE_GROUP_NAME, Ogre::TEX_TYPE_2D, size, size, -1,
                Ogre::PF_A8R8G8B8, Ogre::TU_AUTOMIPMAP | Ogre::TU_STATIC_WRITE_ONLY, this));
        }
    }
    Ogre::LogManager::getSingleton().logMessage("CYS parity: terrain colour map per tile " +
        Ogre::StringConverter::toString(size) + "x" + Ogre::StringConverter::toString(size) + " (" +
        Ogre::StringConverter::toString(mData->mNumTilePerX * mData->mNumTilePerZ) + " tiles)");
}

void
Terrain::prepareLightmapTexture(void)
{
    assert(mLightmapTextures.empty());

	if (getLightmapQuality() == LMQ_NONE)
    {
        if (!mEditable && mData->mLightmapImage)
        {
            delete mData->mLightmapImage;
            mData->mLightmapImage = 0;
        }
		return;
    }
    else if (!mData->mLightmapImage)
    {
        if (mEditable || !mData->reloadLightmap())
            return;
    }

    int numTilePerX = mData->mNumTilePerX;
    int numTilePerZ = mData->mNumTilePerZ;

    // CYS: one whole-terrain lightmap for the B/C templates that sample "<lightmap>" with the TEXCOORD7
    //      whole-terrain UV (client_GL FairyTerrain*.material: tex_coord_set 7); same texel density as the tiles.
    if (!_cysTileMaps())    // CYS-PARITY (L5b): CY has only the tile lightmaps (FUN_1800d3ea0)
    {
        const uint texelsPerGrid = getLightmapQuality() == LMQ_LOW ? 2 : 8;
        uint wholeWidth = mData->mXSize * texelsPerGrid;
        uint wholeHeight = mData->mZSize * texelsPerGrid;
        while (wholeWidth > 8192 || wholeHeight > 8192)
        {
            wholeWidth = wholeWidth > 1 ? wholeWidth / 2 : 1;
            wholeHeight = wholeHeight > 1 ? wholeHeight / 2 : 1;
        }
        Ogre::TexturePtr wholeTexture = Ogre::TextureManager::getSingleton().createManual("<Lightmap>(all)",
            BRUSH_RESOURCE_GROUP_NAME, Ogre::TEX_TYPE_2D, wholeWidth, wholeHeight, -1, Ogre::PF_L8,
            Ogre::TU_AUTOMIPMAP | Ogre::TU_STATIC_WRITE_ONLY, this);
        mLightmapTextures.push_back(wholeTexture);
    }

	uint uWidth, uHeight;
	if (getLightmapQuality() == LMQ_LOW)
	{
		uWidth = mData->mTileSize * 2;
		uHeight = mData->mTileSize * 2;
	}
	else
	{
		uWidth = mData->mTileSize * 8;
		uHeight = mData->mTileSize * 8;
	}

    for (int z = 0; z < numTilePerZ; ++z)
    {
        for (int x = 0; x < numTilePerX; ++x)
		{
            String lightmapName = "<Lightmap>(" +
                Ogre::StringConverter::toString(x) + "," +
                Ogre::StringConverter::toString(z) + ")";
            Ogre::TexturePtr texture = Ogre::TextureManager::getSingleton().createManual(lightmapName,
                BRUSH_RESOURCE_GROUP_NAME, Ogre::TEX_TYPE_2D,
                uWidth, uHeight,
				-1, Ogre::PF_L8,
                Ogre::TU_AUTOMIPMAP | Ogre::TU_STATIC_WRITE_ONLY,
                this);
            mLightmapTextures.push_back(texture);
		}
	}
}

void 
Terrain::setLightmapQuality(LightmapQuality lightmapQuality)
{	
	mLightmapQuality = lightmapQuality;

    for (TextureList::const_iterator it = mLightmapTextures.begin(); it != mLightmapTextures.end(); ++it)
    {
        (*it)->unload();
    }

	// TODO: Rebuild lightmap textures and geometries
}

void
Terrain::buildGeometry(Ogre::SceneNode* parent, bool editable)
{
    clearGeometry();	

    assert(parent);

    // NB: We must adjust world geometry bounding box, especially for OctreeSceneManager
    Ogre::AxisAlignedBox aabb = mData->getBoundBox();
    Ogre::Vector3 centre = aabb.getCenter();
    const Ogre::Vector3 adjust(2000, 10000, 2000);
    const Real scale = 1.5f;
    aabb.setExtents(
        (aabb.getMinimum() - centre) * scale + centre - adjust,
        (aabb.getMaximum() - centre) * scale + centre + adjust);
    parent->getCreator()->setOption("Size", &aabb);

    mEditable = editable;

    if (!mData->mXSize || !mData->mZSize)
    {
        // Do nothing if it's empty terrain.
        return;
    }

    // Prepare atlas texture
    for (size_t pixmapId = 0, numPixmap = mData->mPixmaps.size(); pixmapId < numPixmap; ++pixmapId)
    {
        _getPixmapAtlasId(pixmapId);
    }

	prepareLightmapTexture();
    _cysPrepareColorMapTextures();  // CYS-PARITY (L5b)

    int depth = mData->mZSize;
    int width = mData->mXSize;
    int tileSize = mData->mTileSize;
    int numTilePerX = mData->mNumTilePerX;
    int numTilePerZ = mData->mNumTilePerZ;

    if (mEditable)
    {
        mGridTypeInfos.resize(2);
        mGridTypeInfos[0].material.setNull();
        mGridTypeInfos[1].material = Ogre::MaterialManager::getSingleton().getByName(
            "FairyEditor/GridType");
    }
    else
    {
        _initIndexBuffer(tileSize * tileSize);
    }

    mTiles.reserve(numTilePerX * numTilePerZ);
    for (int z = 0; z < numTilePerZ; ++z)
    {
        for (int x = 0; x < numTilePerX; ++x)
        {
            // Create the tile
            int tileX = x * tileSize;
            int tileZ = z * tileSize;
            int tileWidth = std::min(width - tileX, tileSize);
            int tileDepth = std::min(depth - tileZ, tileSize);
            TerrainTile* tile;
			if (mEditable)
				tile = new TerrainTileEditable(parent, this, tileX, tileZ, tileWidth, tileDepth);
			else
				tile = new TerrainTileOptimized(parent, this, tileX, tileZ, tileWidth, tileDepth);

            // Use the render queue that the world geometry associated with.
            tile->setRenderQueueGroup(parent->getCreator()->getWorldGeometryRenderQueue());

            // Attach it to the aux data
            mTiles.push_back(tile);
        }
    }

}

// CYS-PERF-FIX prewarm (perf-cy 15/09): a tile built its vertex buffers and grid materials at its first render, and the
// runtime shader variant of each grid material (CYS::MaterialSystem::resolveTechnique, ~0,13 ms) was cloned in the render
// queue of that frame: 397 variants in the first world frame of dali_new_320 and 93-190 in single frames when the camera
// turned to unseen terrain (perf-cy world replay varlog-1: cull 23-45 ms, first world frame cull 204 ms).
// CY 3.71 (FACT, probe) creates every vertex/pixel shader of
// the scene in its blocking load frames (world-nov60-2/3: 0 shaders created after the last load frame); INF: whatever CY
// prepares per material happens there too, not in the frames of the world.
// So the variants of every grid material (and the tile geometry that selects them) are prepared in the scene load:
// CRenderSystem::Scene_Load and Scene_SetLightmapQuality call this after their final buildGeometry (SceneInfo::initialise
// builds the geometry once more before that; prewarming there doubled the work).
void
Terrain::cysPrewarm(void)
{
    const char* env = getenv("CYS_PERF_PREWARM");
    if (mEditable || (env && env[0] == '0'))
        return;
    const long long t0 = Ogre::CysPerf::ticks();
    size_t built = 0;
    for (size_t i = 0; i < mTiles.size(); ++i)
    {
        try
        {
            if (mTiles[i] && mTiles[i]->cysPrewarmGeometry())
                ++built;
        }
        catch (const Ogre::Exception& e)
        {
            Ogre::LogManager::getSingleton().logMessage("CYS-PERF prewarm: terrain tile geometry failed: " + e.getDescription());
        }
    }
    const long long t1 = Ogre::CysPerf::ticks();
    // CYS-PERF-FIX fogvariant: the grid materials get the fog mode of the scene before their variants are resolved.
    // _updateMaterials does it when the first tile is queued, which is after this: the variants built here had the
    // programs without fog and kept them (terrain pixel shader without fog_colour / fog_params in Game.exe).
    // The Enviroment object sets the scene fog while the scene objects are created, before Scene_Load gets here.
    Ogre::SceneManager* fogScene = 0;
    for (size_t i = 0; i < mTiles.size() && !fogScene; ++i)
    {
        if (mTiles[i] && mTiles[i]->getParentSceneNode())
            fogScene = mTiles[i]->getParentSceneNode()->getCreator();
    }
    if (!fogScene)
        fogScene = Ogre::Root::getSingleton()._getCurrentSceneManager();
    if (fogScene)
        _cysSyncFogMode(fogScene->getFogMode());
    size_t resolved = 0;
    Ogre::MaterialVariantResolver* resolver = Ogre::MaterialManager::getSingleton().getVariantResolver();
    for (MaterialMap::const_iterator it = mMaterials.begin(); it != mMaterials.end(); ++it)
    {
        const Ogre::MaterialPtr& material = it->second;
        if (material.isNull())
            continue;
        try
        {
            material->touch(); // as RenderQueue::addRenderable
            Ogre::Technique* tech = material->getBestTechnique();
            if (tech && resolver)
            {
                resolver->resolveTechnique(0, tech);
                ++resolved;
            }
        }
        catch (const Ogre::Exception& e)
        {
            Ogre::LogManager::getSingleton().logMessage("CYS-PERF prewarm: terrain material " + material->getName() +
                " failed: " + e.getDescription());
        }
    }
    const long long t2 = Ogre::CysPerf::ticks();
    const double k = 1000.0 / double(Ogre::CysPerf::ticksPerSecond());
    Ogre::LogManager::getSingleton().logMessage("CYS-PERF prewarm: terrain '" + mData->mName + "' tiles " +
        Ogre::StringConverter::toString(mTiles.size()) + " (geometry built " + Ogre::StringConverter::toString(built) + ", " +
        Ogre::StringConverter::toString(Ogre::Real(double(t1 - t0) * k)) + " ms), grid materials " +
        Ogre::StringConverter::toString(mMaterials.size()) + " (resolved " + Ogre::StringConverter::toString(resolved) + ", " +
        Ogre::StringConverter::toString(Ogre::Real(double(t2 - t1) * k)) + " ms)");
}

TerrainTile*
Terrain::getTile(int x, int z) const
{
    assert(0 <= x && x < mData->mNumTilePerX);
    assert(0 <= z && z < mData->mNumTilePerZ);
    assert((size_t)(z * mData->mNumTilePerX + x) < mTiles.size());

    return mTiles[z * mData->mNumTilePerX + x];
}

void
Terrain::notifyHeightModified(int xstart, int zstart, int xend, int zend)
{
    assert(0 <= xstart && xstart < xend && xend <= mData->mXSize+1);
    assert(0 <= zstart && zstart < zend && zend <= mData->mZSize+1);

	// TODO: (optimization) some grid may be need to recompute normal only

    int tileSize = mData->mTileSize;
    int xtile0 = std::max(0, (xstart-2) / tileSize);
    int xtile1 = std::min(xend / tileSize + 1, mData->mNumTilePerX);
    int ztile0 = std::max(0, (zstart-2) / tileSize);
    int ztile1 = std::min(zend / tileSize + 1, mData->mNumTilePerZ);

    // Adjust boundary, make sure include changed normals
    if (xstart > 0) --xstart;
    if (xend <= mData->mXSize) ++xend;
    if (zstart > 0) --zstart;
    if (zend <= mData->mZSize) ++zend;

    for (int z = ztile0; z < ztile1; ++z)
    {
        int zbais = z * tileSize;
        for (int x = xtile0; x < xtile1; ++x)
        {
            int xbais = x * tileSize;
            getTile(x, z)->_notifyHeightModified(
                std::max(xstart - xbais, 0),
                std::max(zstart - zbais, 0),
                std::min(xend - xbais, tileSize + 1),
                std::min(zend - zbais, tileSize + 1));
        }
    }

    // Update of bounding box

    if (!mData->mBoundBox.isNull())
    {
        // Note: This update is not exactly, but can avoid compute entire terrain
        // height which should lower the performance

        Ogre::Vector3 maximum = mData->mBoundBox.getMaximum();
        Ogre::Vector3 minimum = mData->mBoundBox.getMinimum();
        for (int z = zstart; z < zend; ++z)
        {
            for (int x = xstart; x < xend; ++x)
            {
                Real h = mData->getHeight(x, z);
                if (maximum.y < h)
                    maximum.y = h;
                else if (minimum.y > h)
                    minimum.y = h;
            }
        }

        mData->mBoundBox.setExtents(minimum, maximum);
    }
}

void
Terrain::notifyGridInfoModified(int xstart, int zstart, int xend, int zend)
{
    assert(0 <= xstart && xstart < xend && xend <= mData->mXSize);
    assert(0 <= zstart && zstart < zend && zend <= mData->mZSize);

    int tileSize = mData->mTileSize;
    int xtile0 = xstart / tileSize;
    int xtile1 = (xend+tileSize-1) / tileSize;
    int ztile0 = zstart / tileSize;
    int ztile1 = (zend+tileSize-1) / tileSize;

    for (int z = ztile0; z < ztile1; ++z)
    {
        int zbais = z * tileSize;
        for (int x = xtile0; x < xtile1; ++x)
        {
            int xbais = x * tileSize;
            getTile(x, z)->_notifyGridInfoModified(
                std::max(xstart - xbais, 0),
                std::max(zstart - zbais, 0),
                std::min(xend - xbais, tileSize),
                std::min(zend - zbais, tileSize));
        }
    }
}

}
