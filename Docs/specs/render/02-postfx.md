# 02 — Post-processing: B's post-filters, compositor framework and render nodes

Status: spec for phase E3 ("Khung RenderNode và 30 PostFilter"). Date 2026-09-12. FACT/INF legend and the Render.dll build note
(addresses from the original `fda12053…`; client_GL runs a patched copy) as in `01-materials.md`.


## 1. Framework

**0.85 (FACT):** `Src\Engine\WXCore\PostFilter`: `PostFilterManager` + factories for 5 filters (Bloom, Fade, Floodlighting, HeatVision, MotionBlur; `WXPostFilters.cpp:10–14`). Each filter calls `CompositorManager::addCompositor(vp, name)` on a compositor defined in a script (`WXPostFilter.cpp:56`, `PostFilter\media\*.material`, Cg).


## 2. Filter catalogue (FACT from `pf_digest.txt`, all.material, programs; RT sizes as factor of viewport unless absolute)

| Filter | Passes (material → program:entry) | Render targets | Parameters / constants |
|---|---|---|---|
| Bloom (legacy) | Bloom/Downsample4x4Brightpass (800) → GaussianBloom1 (701) → GaussianBloom0 (700) → ToneMapping | 256² `PF_R8G8B8` | `LimitedLuminance` etc.; file `.bloom` (none in data) |
| Floodlighting | PostFilters/Floodlighting/DownSample → BlurHorizontal → BlurVertical → Blend (`Floodlighting.hlsl`) | blur0/blur1 0.5 `PF_X8R8G8B8` | `brightness, blur_amount, shine_amount` |
| FXAA | PostFilter/AntiAliasing/FXAA_NOLUMA (`AntiAlias.hlsl:FXAA_PS_NOLUMA`, `viewportSize`) | chain | — |
| FXAAQuality | FXAA_LUMA (luma to alpha) → FXAA_Quality | chain | — |
| DLAA | DLAA/EdgeDetection (id 994) → DLAA/BlendingColor | `EdgeRT` 1.0 `PF_A8R8G8B8` | `cTargetSize` |
| (MLAA) | materials EdgeDetectionLuminance/Depth, BlendingWeightCalculation LOD1/2/4 (`MAX_SEARCHSTEPS` 4/8/16), NeighbourhoodBlending exist in all.material | — | **no MLAA factory in Render.dll** (FACT, no "MLAA" string) → unused |
| **GodRays** | PostFilters/GodRays/GenGodRays (800, texture `SunRT`) → PostFilters/GaussianBlurH (802) → GaussianBlurV (803) → GodRays/AddGodRays (801; scene + blurred) | `SunWithGodRays`, `…BlurH`, `…BlurHV` 512² `PF_X8R8G8B8` | `Decay`; constant `sunPos_decay_exposure` = (sun screen xy, decay, exposure); `fStrength`; file `.godrays` |
| **DoF** | PostFilters/DoF/Gaussian3x3 → DepthOfField or DepthOfField_DSIntZ (scene, blur, DepthTex = `content_type compositor SceneRender depth_buffer` or `dsintz`) | blur 0.5 `PF_X8R8G8B8` | `pixelSize, pixelSizeScene, pixelSizeBlur, dofParams` |
| MotionBlur | FrameCopy (only-initial) → PostFilters/MotionBlur/Combine (scene + history) → FrameCopy | history 1.0 `PF_X8R8G8B8` | — |
| ScreenRain | clear pass → ScreenRain/Mix → ScreenRain/CopyBack → ScreenRain (scene + mask) | 2 × 1.0 `PF_X8R8G8B8` + generated rain-mask texture (`_createRainMaskTexture`) | `fTrailWeakness, vTrailColor, vTrailDensity` |
| HeatVision | HeatVision/LightToHeat → HeatVision/Blur | 0.5 `PF_X8R8G8B8` | — |
| Gameplay single-pass filters | GaussianBlurH/V (`fStrength`), RadialBlur (`fStrength, fUnblured`), ComplexBlur (`fDistance, fStrength, fUnblured`), HeatHaze (`fSpeed`), LightMove (`fSpeed`), Drunk (`fStrength`), Fade / FadeColor (`colour_amount, gray_amount`), ColorMask (`maskColor`), ColourControl/Saturation, EnergyWaveMask (generated wave-mask texture), ScreenSplit (`fPlayRatio`), TransSceneEffect (`TransScene_Wave`) | chain | driven by skills (RadialBlur/ComplexBlur, 04 §2.9), scene transitions, death screen |
| FinalPass | FrameCopy → viewport (`FinalConvertToGammaSpace` material exists for the linear path) | — | — |


## 4. Spec for CY-Source (order by beauty/effort)

1. **Compositor extensions + chain manager** (all methods of §1) and the **render-node framework** (SceneRender with nodes ShadowMap, SceneDepth, SceneDepthForWater, GenSSAO, FinalPass). Config-driven enable at start-up; filters toggled at run time by name. (≈2 weeks)
2. **NewHDRBloom** with linear-space conversion, FP16 mip chain, soft-knee threshold, ACES tone map, optional auto exposure from the 1×1 luminance chain; per-scene `.newhdrbloom`. (≈1–1.5 weeks)
3. **FXAA / FXAAQuality / DLAA** (materials exist; 1–2 days each).
4. **HeightFog** (needs SceneDepth or INTZ) + EnvKey time-of-day parameters. (≈1 week)
5. **GenSSAO** node + `ssao_buffer` binding at s12. (≈1 week)
6. **ColorLUT, GodRays, DoF** (≈1 week together); gameplay filters (blur family, heat haze, drunk, fade, rain, split, energy wave, trans-scene) 1–2 days each.
7. Optional beyond B: the EnvKey grading filters (ColdWarmMask/EnhanceConstrast/OverlayImage).

Acceptance: log line per enabled filter; image diff vs client_GL at Tô Châu with FXAA+NewHDRBloom (same `.newhdrbloom`); 1440p ≥ 60 fps on RTX 2060 with FXAA+HDR+HeightFog+SSAO (doc 03 gate E3).
