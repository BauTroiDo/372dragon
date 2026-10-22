# 05 — Scene-level beauty data: sky, time-of-day, fog, HDR files, water, lights, dynamic bones

Status: spec for phase E3 ("Các file cảnh"). Date 2026-09-12. FACT/INF legend and Render.dll note as in `01-materials.md`.


## 1. How a scene references its beauty data (FACT)


0.85 has only `SkyDome` (`WXSkyDomeObject.cpp`: material, curvature, tiling, distance, x/y segments, draw first), `Enviroment`, `TerrainLiquid` — FACT; no SkySphere, EnScene, EnvKey, FakeLight, HDR files, height fog or dynamic bones.

## 2. Binary per-scene files


HeightFog is additionally driven per time of day by EnvKey `height_fog_enabled` / `height_fog_param` (10 `|`-separated fields; first two are RGBA colours — INF same order as `.hfog`).

## 4. `.EnScene` (197 files, XML version 1.0, `Fairy::EnSceneObject` `FairyEnSceneObject.cpp`, `FairyEnSky.cpp`)

Tree (FACT): `EnScene(version)` → `EnSky` → `SkyDome(texture, hight, mieAmount, vertexHeightEffect, sunHeightEffect, power)`, `SkyClouds → SkyCloudsLayer(name, layer, turnoverMesh, skyCloudHeight, meshname enskycloud*.mesh, texturename, rotangle, textureTile, scatteringStrength/Power, rimStrength/Power/DetectPower/DetectWidth, TimeNodesInfo → TimeNode(time 0..24, fog, alpha, cloudspeed, ambientBlend))`, `SkyRingClouds → RingCloudsLayer(ringcloud.mesh, CloudHeight/Scale/Offset, TextureRepeat, parallax, TimeNode(fogblend, rollspeed, verticalSpeed, fadeRange))`, `Sun(Enable, layer, scale, sunAngle, sunOrient, sunUpTime/DownTime, sun_tex_name, sunflare_tex_name, useSunFlare, lensFlare_settings_name "LensFlare.lensflare", useLensFlare)`, `Moon(…)`, `Star(StarCount 2000–8192, Size, Radius, FlickerSpeed, Intensity, Start/EndColour, starfix)`, `Ocean(Enable=false)`, EnvKey list (277 keys), `EnRegion(name, maxAffectDistance, Point list)` (INF: region-weighted environment blending).
Rendering (FACT): materials `EnScene/skyDome, cloud, cloudocclusion, ringcloud, ringcloudocclusion, sun, sunocclusion, moon, sunflare1, LensFlare`; programs in all.material from `EnScene.hlsl` (`En_sky_dome_v/p`, `En_cloudv/p`, `En_ringcloudv/p`, `En_sunandmoon_*`, `En_flare_*`, `SkyDome_V/F`) and `LensFlare.hlsl`; meshes `enskydome.mesh`, `enskycloud.mesh`, `ringcloud.mesh`.


## 5. Water — `TerrainLiquid` objects (2,253 in 416 scenes)

|---|---|---|
| material, position, subdivision, texture rotate/scale, depth texture layer.enable/height scale/height adjust, projector name/size | yes | yes |
| mesh name (mesh-shaped water), replaceMaterial (fallback when HW lacks support), orientation, scale, texture scale for mesh water low level, texture depth | no | yes |
| showNewWaterEnabled (57), showMirrorReflectWaterEnabled (80) | no | yes |
| `ShaderParams.*` (≈520 each): Water Fog Color, Water Fog Density, uvScale, Wave Speed, Bump Scale X/Z, Big/Small Waves Scale, Reflection Amount, Transparency Ratio, SunShine Pow, Sun Multiplier, Fresnel Bias | no | yes → constants `FogColorDensity, BigWavesScale, SmallWavesScale, BumpScale, ReflectionAmount, TransparencyRatio, SunShinePow, SunMultiplier, FresnelBias, UVScale, wavesSpeed` (01 §6) |


## 6. Lights

- `Light` objects (7,330; FACT `scene_objects.tsv`): `position, diffuse, specular, range (1000 typical), attenuation.constant/linear/quadric, direction, intensity, end brightness, cast shadows (156 true), type spotlight (10)` → up to `MAX_LIGHT_NUM 3` per object via the light-array auto constants.
- `FakeLight` objects (4,362, **not in 0.85**): `position, orientation, scale, size 1.4–1.7, diffuse, intensity, begin/end brightness` → rendered as screen-space light volumes with `Mtl_FakePointLight(_DSIntZ)` (`FakePointLight_vs.hlsl`, `Model_FakePointLight_ps.hlsl`, needs scene depth) and scaled by EnvKey `fake_point_light_intensity` (INF from names). Big visual win for night/indoor scenes at low cost.

## 8. Spec for CY-Source

1. `SceneInfo` loader for `<SkySphere …/>` and `#FairyEnScene` objects; per-scene file lookup (`#TEMP#` then group `Scene`) with the defaults above.
2. **EnScene** renderer (dome with Mie term, cloud layers with scattering/rim, ring clouds, sun/moon/stars, lens flare) + **EnvKey** interpolation by time of day and region, feeding SceneManager (ambient, PBR ambient, actor lights, sky-dome ambient, fog, brightness), shadows and HeightFog. (≈3–4 weeks)
3. **SkySphere** renderer (5 blended layers, sunshine, moon phases by date, stars, weather sets, thunder). (≈2 weeks)
4. **Water** (reflection/refraction/mirror RTs, depth node, ShaderParams, PBR water templates). (≈3 weeks)
5. **FakeLight** (≈1 week) and **dynamic bones** (Verlet chain + capsule colliders, ≈2 weeks).

Acceptance: 10 reference scenes (doc 03 gate E3) at fixed times of day; sky/cloud/water within SSIM 0.95 of client_GL; no scene file parse warnings.
