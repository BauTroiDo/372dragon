// TlbbViewer - the viewer application: engine setup, content, camera, frame loop, capture.
#pragma once

#include "ViewerOptions.h"

#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>

#include <string>
#include <vector>

#include <OgreVector3.h>

namespace Ogre
{
    class Camera;
    class Light;
    class LogManager;
    class ManualObject;
    class ParticleSystem; // CYS fx-audit
    class Rectangle2D;
    class RenderWindow;
    class SceneNode;
}

namespace WX
{
    class Effect;
    class LogicModel;
    class System; // CYS fx-audit
}

namespace tlbbv
{
    class ViewerSystem;

    class ViewerApp
    {
    public:
        explicit ViewerApp(const Options& opt);
        ~ViewerApp();

        /// Runs on the given window; returns the process exit code.
        int run(HWND hwnd);

        /// Window message hook; returns true when consumed ('result' is then the WndProc result).
        bool handleMessage(HWND hwnd, UINT msg, WPARAM wp, LPARAM lp, LRESULT& result);

        /// Destroys the viewer objects and the engine (safe to call more than once).
        void shutdown(void);

    private:
        ViewerApp(const ViewerApp&);
        ViewerApp& operator=(const ViewerApp&);

        void destroyContentAndEngine(void);

        // setup
        void initEngine(void);
        void addResourceLocations(void);
        void addFolderTree(const std::string& dir, const std::string& group, size_t& count);
        void logResourceSummary(void);
        bool loadScene(void);
        bool createModel(void);
        bool createEffect(void);
        void destroyEffect(void);
        void restartFinishedEffect(void);
        void createBackground(void);
        void createGrid(void);
        void setupLights(void);
        void configureExtras(void);
        int  listNames(void);
        void dumpContent(void);
        void applyFixedFunctionFallback(void);

        // camera
        Ogre::Vector3 terrainPoint(float x, float z) const;
        Ogre::Vector3 sceneDefaultTarget(void) const;
        void frameContent(void);
        void setCameraFromOptions(void);
        void applyCamera(void);
        void updateKeyboard(float dt);

        // frames
        bool pumpMessages(void);
        void renderFrame(float dt, const std::string* capturePath);
        bool captureBackBuffer(const std::string& path);
        std::string nextScreenshotPath(void);
        int  runShot(void);
        int  runInteractive(void);

        // CYS fx-audit (ViewerFx.cpp): runtime census (--fx-census) and deterministic effect sheets (--fx-sheet)
        struct FxFrameStats;
        WX::System* wxSystem(void) const;
        int  runFxCensus(void);
        int  runFxSheet(void);
        bool fxSheetItem(const std::vector<std::string>& item, void* files);
        bool fxCreate(const std::string& kind, const std::string& name, const std::string& anim);
        void fxDestroy(void);
        Ogre::SceneNode* fxContentNode(const std::string& kind) const;
        void addWideFolderTree(const std::string& dirAcp, const std::string& group, size_t& count); // --wide-names
        void fxFrame(float dt, const std::string* capturePath, FxFrameStats* stats);
        Ogre::ParticleSystem* mFxParticle = NULL;
        Ogre::SceneNode* mFxNode = NULL;
        size_t mFxSerial = 0;

        Options mOpt;
        HWND mHwnd;
        Ogre::LogManager* mLogManager;
        ViewerSystem* mSystem;
        Ogre::RenderWindow* mWindow;
        Ogre::Camera* mCamera;

        WX::LogicModel* mModel;
        WX::Effect* mEffect;
        Ogre::SceneNode* mEffectNode;
        unsigned int mModelEffect;

        Ogre::Rectangle2D* mBackground;
        Ogre::SceneNode* mBackgroundNode;
        Ogre::ManualObject* mGrid;
        Ogre::SceneNode* mGridNode;
        std::vector<Ogre::Light*> mLights;
        Ogre::Light* mCameraLight;

        bool mSceneLoaded;
        std::string mSceneGroup;
        Ogre::Vector3 mContentOrigin;

        // orbit camera
        Ogre::Vector3 mTarget;
        float mYaw;
        float mPitch;
        float mDist;
        float mFov;

        // state
        bool mOrbiting;
        bool mPanning;
        bool mPaused;
        bool mQuit;
        bool mShutdown;
        bool mCaptureRequested;
        bool mCaptureOk;
        double mCysFrameMs = 0.0;   // CYS-WATER: runShot frame timing
        int mCysFrameCount = 0;
        int mCysFrameErrors = 0;    // CYS-PARTICLE: Ogre exceptions that escaped into the frame loop
        bool mAutoFrameEffect;
        bool mAutoFrameModel; // CYS: re-frame --model once its animation, locators and slot models are posed
        int mLastX;
        int mLastY;
        int mCaptureCounter;
        int mMissing;
        double mSimTime;
    };
}
