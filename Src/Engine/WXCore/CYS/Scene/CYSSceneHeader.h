#ifndef __CYS_SCENEHEADER_H__
#define __CYS_SCENEHEADER_H__

// CY-Source (scene agent): .Scene header elements of the B/C scene format that 0.85 does not know (05 §1):
//   <SkySphere enabled="true" filename="x.skysphere" objectname="#FairySkySphere"/>   (343 files)
//   <ModelMaterialScheme scheme="..."/>                                              (6 files)
//   <MovieData filename="x.movie"/>                                                  (19 files)
// Stored in WX::Scene::mCYSHeader by SceneSerializer and written back by SceneSerializer::save.

#include "Core/WXPrerequisites.h"

namespace WX
{
    struct CYSSceneHeader
    {
        bool hasSkySphere;
        bool skySphereEnabled;
        String skySphereFile;
        String skySphereObjectName;

        bool hasMaterialScheme;
        String materialScheme;

        bool hasMovieData;
        String movieData;

        CYSSceneHeader(void) { reset(); }

        void reset(void)
        {
            hasSkySphere = false;
            skySphereEnabled = false;
            skySphereFile.clear();
            skySphereObjectName.clear();
            hasMaterialScheme = false;
            materialScheme.clear();
            hasMovieData = false;
            movieData.clear();
        }
    };
}

#endif // __CYS_SCENEHEADER_H__
