#pragma once

#include <OgreException.h>
#include <OgreMaterialManager.h>
#include <OgrePass.h>
#include <OgreRectangle2D.h>
#include <OgreRenderQueue.h>
#include <OgreSceneManager.h>
#include <OgreSceneNode.h>
#include <OgreTechnique.h>
#include <OgreTextureUnitState.h>

// The RTT background uses the same implementation in Render.dll and the native
// renderer probe. It owns its node/rectangle and only materials it cloned.
class CysUiMeshBackground
{
public:
    CysUiMeshBackground() : m_scene(0), m_rectangle(0), m_node(0), m_ownsMaterial(false) {}
    ~CysUiMeshBackground() { clear(); }

    void create(Ogre::SceneManager& scene, const Ogre::String& objectName,
                const Ogre::String& textureName)
    {
        clear();
        if (textureName.empty()) return;
        Ogre::MaterialManager& materials = Ogre::MaterialManager::getSingleton();
        Ogre::MaterialPtr source = materials.getByName("TLBB/UIModelBackground");
        if (source.isNull()) return; // B also leaves the RTT without a background.

        m_scene = &scene;
        try
        {
            const Ogre::String name = objectName + "_Rectangle";
            m_material = materials.getByName(name);
            if (m_material.isNull())
            {
                m_material = source->clone(name);
                m_ownsMaterial = true;
                if (m_material->getNumTechniques() &&
                    m_material->getTechnique(0)->getNumPasses() &&
                    m_material->getTechnique(0)->getPass(0)->getNumTextureUnitStates())
                    m_material->getTechnique(0)->getPass(0)->getTextureUnitState(0)->setTextureName(textureName);
            }

            m_rectangle = new Ogre::Rectangle2D(true);
            m_rectangle->setCorners(-1.0f, 1.0f, 1.0f, -1.0f);
            m_rectangle->setMaterial(m_material->getName());
            m_rectangle->setRenderQueueGroup(Ogre::RENDER_QUEUE_BACKGROUND);
            m_rectangle->setVisibilityFlags(0x4); // WX::OVF_GUI_ELEMENTS, as B.
            m_rectangle->setBoundingBox(Ogre::AxisAlignedBox(
                Ogre::Math::NEG_INFINITY, Ogre::Math::NEG_INFINITY, Ogre::Math::NEG_INFINITY,
                Ogre::Math::POS_INFINITY, Ogre::Math::POS_INFINITY, Ogre::Math::POS_INFINITY));
            m_rectangle->setVisible(false);
            m_node = scene.getRootSceneNode()->createChildSceneNode();
            m_node->attachObject(m_rectangle);
        }
        catch (...)
        {
            clear();
            throw;
        }
    }

    void setActive(bool active)
    {
        if (m_rectangle) m_rectangle->setVisible(active);
    }

    void clear()
    {
        if (m_node)
        {
            m_node->detachAllObjects();
            m_scene->destroySceneNode(m_node->getName());
            m_node = 0;
        }
        delete m_rectangle;
        m_rectangle = 0;
        // Unlike B's retained cache, a clone created here ends with its owner.
        // A pre-existing material remains registered and is never edited.
        if (m_ownsMaterial && !m_material.isNull())
            Ogre::MaterialManager::getSingleton().remove(m_material->getHandle());
        m_material.setNull();
        m_ownsMaterial = false;
        m_scene = 0;
    }

    Ogre::Rectangle2D* rectangle() const { return m_rectangle; }
    Ogre::SceneNode* node() const { return m_node; }
    const Ogre::MaterialPtr& material() const { return m_material; }
    bool ownsMaterial() const { return m_ownsMaterial; }

private:
    CysUiMeshBackground(const CysUiMeshBackground&);
    CysUiMeshBackground& operator=(const CysUiMeshBackground&);
    Ogre::SceneManager* m_scene;
    Ogre::Rectangle2D* m_rectangle;
    Ogre::SceneNode* m_node;
    Ogre::MaterialPtr m_material;
    bool m_ownsMaterial;
};
