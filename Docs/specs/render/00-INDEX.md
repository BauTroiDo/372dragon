# Render specs — index and priorities ("game must be beautiful")


| File | Content |
|---|---|
| `00b-engine-085_vi.md` | **Read first.** The 0.85 baseline itself: WXRender/WXCore/OgreMain layering, the OGRE 1.2.5 fork and its static plugins, the exact render boot + scene-load order, the `.Scene`/`.Terrain`/lightmap data contract, terrain atlas + shading formula, character material templates, why 0.85 has no shadows, the eight `View_*` quality variables (and which are dead code), 12 root causes of the flat look ranked by impact, and the build/verify loop |
| `01-materials.md` | Template/program catalogue, keyword + HLSL-pipeline + auto-constant gaps vs 0.85, material-instance system, implementation order |
| `02-postfx.md` | Post-filter framework, chain order, every filter's passes/RTs/formats/parameters, config keys, per-scene HDR files |
| `03-shadows.md` | Shadow config object, CSM fitting, auto constants, `CalcShadow.inc` contract |
| `04-effects-particles.md` | NewRibbonTrail, UIParticle, RevoluMove, SequenceFrame, Dissolve, RotationCurve, PolarMove, CameraShake, ComplexBlur, Cylinder `curve`, `dissolveBox` |
| `05-scene-features.md` | `.skysphere`, `.EnScene`/EnvKey, `.hfog`, `.hdr`, `.newhdrbloom`, `.godrays`, TerrainLiquid water, lights/FakeLight, `.dynbone` |

## Priorities by visual impact (impact 1–10; effort = 1 engineer + AI, after E1b x64 port)

| # | Feature | Impact | Effort | Depends on | Spec |
|---|---|---|---|---|---|
| 1 | **SM3 HLSL material parity**: B template zip as data, `#include` handler, 37 new auto constants, 5 new script keywords, runtime define variants, material-instance parameters, INTZ/vertex textures | 10 (every character, pet, mount, weapon, PBR scene) | 5–7 wk | — | 01 |
| 2 | **Compositor/render-node framework + NewHDRBloom** (linear space, FP16 bloom mips, ACES, auto exposure, per-scene `.newhdrbloom`) | 9 | 3–3.5 wk (framework 2 + filter 1–1.5) | 1 | 02 |
| 3 | **Sky + time-of-day lighting**: EnScene (197 scenes) + SkySphere (305 scenes) + EnvKey (actor/PBR ambient, fog, lights) | 9 | 5–6 wk | 1 | 05 |
| 4 | **Shadow maps**: CSM 4 cascades atlas, PCF 3×3, const/normal bias, EnvKey strength | 8.5 | 2–3 wk | 1, 2 (render nodes) | 03 |
| 5 | **Water**: TerrainLiquid new/mirror water, reflection/refraction RTs, depth, ShaderParams, PBR water | 8 | 3 wk | 1, 2 | 05 |
| 6 | **Effect/particle types** (RevoluMove, SequenceFrame, Dissolve, NewRibbonTrail cover 99 % of 5,491 uses; + RotationCurve, PolarMove, UIParticle, CameraShake, ComplexBlur) | 8 (all 2024–2026 skills, wings, pets) | 3–5 wk | 1 (dissolve/sequence shaders) | 04 |
| 7 | **Anti-aliasing** FXAA / FXAAQuality / DLAA | 6 | 3–5 d | 2 | 02 |
| 8 | **Height fog** (`.hfog` + EnvKey) with SceneDepth node or INTZ | 6 | 1 wk | 2 | 02, 05 |
| 9 | **SSAO** (GenSSAO node, `ssao_buffer` at s12 in lighting) | 6 | 1 wk | 1, 2 | 02 |
| 10 | **ColorLUT + GodRays + DoF** | 5 | 1–1.5 wk | 2 | 02 |
| — | FakeLight (4,362 objects), dynamic bones (26 files), gameplay post-filters (blur family, heat haze, drunk, fade, rain, split, energy wave, trans-scene), legacy HDR/Bloom/Floodlighting | 3–5 each | 1–2 wk / 2 wk / 1–2 d each | 1, 2 | 02, 04, 05 |

Total ≈ 6–8 months of E2+E3 work, in line with doc 03 (E2 2–4 months, E3 2–4 months). Items 1 and 2 are on the critical path of everything else.

## Biggest structural gaps 0.85 → B (details in 01/02)

1. HLSL programs cannot compile: 0.85 passes no include handler to `D3DXCompileShader` (`OgreD3D9HLSLProgram.cpp:106–116`); 37 of 89 B shader files use `#include`.
2. 37 auto-constant names missing from `GpuProgramParameters` (shadow_*, actor_*, isystem/imodel_userdata, wind, DQ skinning, light arrays, fog_type, sky-dome ambient, texture matrices).
3. Script keywords missing from the 0.85 serializer: pass `render_queue`, `separate_scene_blend`; texture_unit `content_type` (compositor refs, INTZ), `sampler_index`, `shader_type` — 323 uses in B data (templates + all.material); plus no vertex-texture fetch or INTZ in the 0.85 D3D9 render system.
4. B builds shader permutations at run time (22 injected macros) and pushes 54 named per-instance constants (dissolve, flow light, outline, rim, water) — no equivalent in 0.85.
5. Post-processing: 0.85 has 5 script-defined compositor filters; B has 29 code-built filters on an extended compositor API (RT aliasing/ping-pong, cross-compositor texture references, render-queue passes, scheme/visibility per target) and a render-node pipeline (depth, water depth, shadow, SSAO).
