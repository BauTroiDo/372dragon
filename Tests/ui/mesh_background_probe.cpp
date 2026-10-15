#include "CysUiMeshBackground.h"
#include <OgreRoot.h>
#include <OgreCamera.h>
#include <OgreHardwarePixelBuffer.h>
#include <OgreRenderTexture.h>
#include <OgreRenderWindow.h>
#include <OgreTextureManager.h>
#include <OgreViewport.h>
#include <windows.h>
#include <cstdio>
#include <stdexcept>
#include <string>
#include <vector>

static unsigned checks = 0;
static size_t materialCount()
{
    size_t count = 0;
    Ogre::ResourceManager::ResourceMapIterator it = Ogre::MaterialManager::getSingleton().getResourceIterator();
    while (it.hasMoreElements()) { it.getNext(); ++count; }
    return count;
}
static void check(bool condition, const char* name)
{
    if (!condition) throw std::runtime_error(name);
    ++checks;
    std::printf("PASS %s\n", name);
    std::fflush(stdout);
}

static Ogre::TexturePtr colourTexture(const Ogre::String& name, unsigned char r,
    unsigned char g, unsigned char b)
{
    Ogre::TexturePtr texture = Ogre::TextureManager::getSingleton().createManual(name,
        Ogre::ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME, Ogre::TEX_TYPE_2D,
        4, 4, 1, 0, Ogre::PF_A8R8G8B8, Ogre::TU_STATIC_WRITE_ONLY);
    std::vector<unsigned char> pixels(4 * 4 * 4);
    for (size_t i = 0; i != pixels.size(); i += 4)
    {
        pixels[i] = r; pixels[i+1] = g; pixels[i+2] = b; pixels[i+3] = 255;
    }
    texture->getBuffer()->blitFromMemory(Ogre::PixelBox(4, 4, 1, Ogre::PF_BYTE_RGBA, &pixels[0]));
    return texture;
}

static Ogre::TexturePtr renderTexture(const Ogre::String& name, unsigned width,
    unsigned height, Ogre::Camera& camera)
{
    Ogre::TexturePtr texture = Ogre::TextureManager::getSingleton().createManual(name,
        Ogre::ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME, Ogre::TEX_TYPE_2D,
        width, height, 1, 0, Ogre::PF_R8G8B8A8, Ogre::TU_RENDERTARGET);
    Ogre::RenderTexture* target = texture->getBuffer()->getRenderTarget();
    target->setAutoUpdated(false);
    Ogre::Viewport* viewport = target->addViewport(&camera);
    viewport->setClearEveryFrame(true);
    viewport->setBackgroundColour(Ogre::ColourValue(156.0f/255,123.0f/255,74.0f/255,0));
    viewport->setOverlaysEnabled(false);
    viewport->setSkiesEnabled(false);
    return texture;
}

static void pixelsEqual(const Ogre::TexturePtr& texture, unsigned char r,
    unsigned char g, unsigned char b, unsigned char a, const char* name)
{
    texture->getBuffer()->getRenderTarget()->update();
    const unsigned width = texture->getWidth(), height = texture->getHeight();
    std::vector<unsigned char> pixels(size_t(width) * height * 4);
    texture->getBuffer()->blitToMemory(Ogre::PixelBox(width, height, 1, Ogre::PF_BYTE_RGBA, &pixels[0]));
    size_t mismatches = 0;
    for (size_t i = 0; i != pixels.size(); i += 4)
        if (pixels[i] != r || pixels[i+1] != g || pixels[i+2] != b || pixels[i+3] != a) ++mismatches;
    std::printf("PIXELS width=%u height=%u compared=%u mismatches=%zu\n", width, height, width * height, mismatches);
    check(mismatches == 0, name);
}

int main()
{
    SetErrorMode(SEM_FAILCRITICALERRORS | SEM_NOGPFAULTERRORBOX);
    // A hidden native owner prevents Ogre from creating a visible test window.
    HWND hwnd = CreateWindowExA(0, "STATIC", "CYS UI RTT probe", WS_OVERLAPPEDWINDOW,
        0, 0, 256, 256, 0, 0, GetModuleHandleA(0), 0);
    if (!hwnd) return 3;
    int result = 0;
    try
    {
        Ogre::Root root("", "", "Ogre.log");
        root.loadRenderPlugins_D3D9();
        root.initialise(false);
        Ogre::NameValuePairList options;
        options["externalWindowHandle"] = std::to_string(reinterpret_cast<size_t>(hwnd));
        options["vsync"] = "false";
        options["FSAA"] = "0";
        root.createRenderWindow("CysUiBackgroundProbe", 128, 128, false, &options);
        Ogre::ResourceGroupManager::getSingleton().addResourceLocation(".", "FileSystem",
            Ogre::ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME, true);
        check(!IsWindowVisible(hwnd), "native owner stays hidden");
        Ogre::SceneManager* scene = root.createSceneManager(Ogre::ST_GENERIC, "CysUiBackgroundScene");
        scene->setVisibilityMask(4);
        Ogre::Camera* camera = scene->createCamera("CysUiBackgroundCamera");
        camera->setNearClipDistance(1);
        camera->setFarClipDistance(10000);
        camera->setPosition(100, 50, 1000);
        camera->lookAt(0, 0, 0);
        const unsigned initialChildren = scene->getRootSceneNode()->numChildren();
        Ogre::MaterialManager& materials = Ogre::MaterialManager::getSingleton();

        CysUiMeshBackground absent;
        absent.create(*scene, "Absent", "probe-red");
        check(!absent.rectangle(), "missing base material creates no rectangle");
        check(scene->getRootSceneNode()->numChildren() == initialChildren, "missing material creates no scene node");
        Ogre::MaterialPtr base = materials.create("TLBB/UIModelBackground",
            Ogre::ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME);
        Ogre::Pass* pass = base->getTechnique(0)->getPass(0);
        pass->setLightingEnabled(false);
        pass->setDepthWriteEnabled(false);
        pass->createTextureUnitState()->setTextureAddressingMode(Ogre::TextureUnitState::TAM_CLAMP);
        // This synthetic fixture has the same settings as Canonical all.material.
        Ogre::TexturePtr red = colourTexture("probe-red", 211, 31, 59);
        Ogre::TexturePtr blue = colourTexture("probe-blue", 17, 89, 223);
        Ogre::TexturePtr wide = renderTexture("probe-wide", 128, 64, *camera);
        Ogre::TexturePtr tall = renderTexture("probe-tall", 64, 128, *camera);
        Ogre::TexturePtr realBackground;
        Ogre::TexturePtr canonicalBackground;
        {
            CysUiMeshBackground first, second, empty;
            empty.create(*scene, "Empty", "");
            check(!empty.rectangle() && !materials.resourceExists("Empty_Rectangle"), "empty background allocates no clone");
            first.create(*scene, "First", red->getName());
            second.create(*scene, "Second", blue->getName());
            check(first.rectangle() && second.rectangle(), "two native rectangles created");
            check(scene->getRootSceneNode()->numChildren() == initialChildren + 2,
                "two scene nodes are attached to the root");
            check(first.ownsMaterial() && second.ownsMaterial(), "each object owns a separate material clone");
            check(first.rectangle()->getRenderQueueGroup() == Ogre::RENDER_QUEUE_BACKGROUND &&
                first.rectangle()->getVisibilityFlags() == 4, "background queue and visibility mask match B");
            check(first.rectangle()->getBoundingBox().getMinimum().x == Ogre::Math::NEG_INFINITY &&
                first.rectangle()->getBoundingBox().getMaximum().x == Ogre::Math::POS_INFINITY,
                "screen rectangle has infinite bounds");
            check(first.material()->getTechnique(0)->getPass(0)->getTextureUnitState(0)->getTextureName() == "probe-red" &&
                base->getTechnique(0)->getPass(0)->getTextureUnitState(0)->getTextureName().empty(),
                "texture name applied to clone only");
            pixelsEqual(wide, 156, 123, 74, 0, "initial hidden backgrounds preserve transparent RTT clear");
            first.setActive(true); second.setActive(false);
            camera->setAspectRatio(2.0f);
            pixelsEqual(wide, 211, 31, 59, 255, "first active fills every wide RTT pixel");
            first.setActive(false); second.setActive(true);
            camera->setAspectRatio(0.5f);
            pixelsEqual(tall, 17, 89, 223, 255, "second active fills every tall RTT pixel without first leakage");
            scene->setVisibilityMask(1);
            pixelsEqual(wide, 156, 123, 74, 0, "GUI background excluded by world visibility mask");
            scene->setVisibilityMask(4);
            second.setActive(false);
            pixelsEqual(tall, 156, 123, 74, 0, "post-viewport deactivate restores transparent RTT clear");
            first.clear(); second.clear();
            check(scene->getRootSceneNode()->numChildren() == initialChildren, "destroy removes both child nodes");
            check(!materials.resourceExists("First_Rectangle") && !materials.resourceExists("Second_Rectangle"),
                "destroy removes owned clones");
            first.create(*scene, "First", blue->getName());
            first.setActive(true);
            pixelsEqual(wide, 17, 89, 223, 255, "destroy/recreate same name uses new texture");
            first.clear();
            Ogre::MaterialPtr borrowed = base->clone("Borrowed_Rectangle");
            borrowed->getTechnique(0)->getPass(0)->getTextureUnitState(0)->setTextureName("probe-red");
            first.create(*scene, "Borrowed", "probe-blue");
            check(!first.ownsMaterial(), "pre-existing clone remains externally owned");
            first.setActive(true);
            pixelsEqual(wide, 211, 31, 59, 255, "pre-existing material texture is preserved as B");
            first.clear();
            check(materials.resourceExists("Borrowed_Rectangle"), "destroy preserves borrowed material");
            materials.remove(borrowed->getHandle()); borrowed.setNull();
            first.create(*scene, "RealMeshBack", "Common/MeshBack.dds");
            realBackground = Ogre::TextureManager::getSingleton().getByName("Common/MeshBack.dds");
            check(!realBackground.isNull() && realBackground->isLoaded() &&
                realBackground->getWidth() && realBackground->getHeight(),
                "actual Common/MeshBack.dds loads through production material");
            std::printf("ASSET name=Common/MeshBack.dds width=%u height=%u\n",
                realBackground->getWidth(), realBackground->getHeight());
            first.setActive(true);
            wide->getBuffer()->getRenderTarget()->update();
            first.clear();
            first.create(*scene, "CanonicalMeshBack", "Canonical/MeshBack.dds");
            canonicalBackground = Ogre::TextureManager::getSingleton().getByName("Canonical/MeshBack.dds");
            check(!canonicalBackground.isNull() && canonicalBackground->isLoaded() &&
                canonicalBackground->getWidth() == 256 && canonicalBackground->getHeight() == 256,
                "canonical DXT1 MeshBack.dds loads through production material");
            first.setActive(true);
            wide->getBuffer()->getRenderTarget()->update();
            first.clear();
            const size_t beforeCycles = materialCount();
            for (unsigned i = 0; i != 32; ++i)
            {
                first.create(*scene, "Cycle", i % 2 ? "probe-red" : "probe-blue");
                first.clear();
            }
            check(!materials.resourceExists("Cycle_Rectangle") &&
                scene->getRootSceneNode()->numChildren() == initialChildren,
                "32 lifecycle cycles leave no clones or child nodes");
            check(materialCount() == beforeCycles, "32 lifecycle cycles preserve material resource count");
        }
        check(HeapValidate(GetProcessHeap(), 0, 0) != FALSE, "process heap valid after native lifecycle checks");
        wide->getBuffer()->getRenderTarget()->removeAllViewports();
        tall->getBuffer()->getRenderTarget()->removeAllViewports();
        scene->destroyCamera(camera);
        for (const Ogre::TexturePtr& texture : {wide, tall, red, blue, realBackground, canonicalBackground})
            Ogre::TextureManager::getSingleton().remove(texture->getHandle());
        wide.setNull(); tall.setNull(); red.setNull(); blue.setNull(); realBackground.setNull(); canonicalBackground.setNull();
        materials.remove(base->getHandle()); base.setNull();
    }
    catch (const Ogre::Exception& error)
    {
        std::fprintf(stderr, "OGRE ERROR %s\n", error.getFullDescription().c_str()); result = 2;
    }
    catch (const std::exception& error)
    {
        std::fprintf(stderr, "ERROR %s\n", error.what()); result = 2;
    }
    DestroyWindow(hwnd);
    std::printf("RESULT checks=%u status=%s\n", checks, result ? "FAIL" : "PASS");
    return result;
}
