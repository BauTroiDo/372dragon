#ifndef __CYS_TERRAINEXTRAS_H__
#define __CYS_TERRAINEXTRAS_H__

// CY-Source (scene agent): .Terrain elements of the B/C format that 0.85 does not know (client_GL, 504 files):
//   <useColorMap useColorMap="true"/> (192), <colorMap filename="xColor.tga" [scaleSize="2"]/> (191),
//   <useColorMapAlphaBlend useColorMapAlphaBlend="true"/> (192), <normalSpec enabled="true"/> (1).
// The colour map is the per-terrain colour texture of FairyTerrainColorMap.hlsl (Color.tga = xsize x 2, 32-bit,
// Docs/08 §5.1). Kept in TerrainData::mCYSExtras for the terrain renderer; written back by _saveBaseInfo.

#include "Core/WXPrerequisites.h"

namespace WX
{
    struct CYSTerrainExtras
    {
        bool hasUseColorMap;
        bool useColorMap;
        bool hasColorMap;
        String colorMapFilename;
        String colorMapScaleSize;       ///< raw attribute text ("2"), empty when absent
        bool hasUseColorMapAlphaBlend;
        bool useColorMapAlphaBlend;
        bool hasNormalSpec;
        bool normalSpecEnabled;

        CYSTerrainExtras(void) { reset(); }

        void reset(void)
        {
            hasUseColorMap = useColorMap = false;
            hasColorMap = false;
            colorMapFilename.clear();
            colorMapScaleSize.clear();
            hasUseColorMapAlphaBlend = useColorMapAlphaBlend = false;
            hasNormalSpec = normalSpecEnabled = false;
        }
    };
}

#endif // __CYS_TERRAINEXTRAS_H__
