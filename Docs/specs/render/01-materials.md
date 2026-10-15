# 01 — Material system: B templates vs the 0.85 OGRE material/GPU-program system

Status: spec for engine engineers (phase E2 "Hệ material", doc 03). Date 2026-09-12.
Legend: **FACT** = measured in a file/binary (path, offset, RVA or script output given); **INF** = inference.
B = `client_GL` (VS2012 Fairy build); 0.85 = `CY-Source\Src` (OGRE 1.2.5 "Dagon" + WX).
All Render.dll addresses are from the ORIGINAL pre-patch Render.dll (SHA-256 `fda12053…d67901`, the build imported in
`analysis\graphics-overhaul\ghidra\proj\gfx.gpr`); `client_GL\Bin64\Render.dll` is the patched chain end
(`49b2ab1f…`, shadow + HDR + aniso patches, doc 08 §10) — identical except the patched bytes.

Evidence (all regenerable, read-only on sources):

| Script | Output |
|---|---|
| `Tools\re\extract_mtltemplates.py` | `Assets\Staging\materialtemplates\B\` (+`_manifest.tsv`), `…\A085\` (0.85 data zip) |
| `Tools\re\mtl_catalog.py` | `Tools\re\out\mtl_programs.tsv`, `mtl_templates.tsv`, `mtl_template_usage.tsv`, `mtl_keyword_gap.tsv`, `mtl_value_usage.tsv`, `mtl_autoconst_gap.tsv`, `mtl_autoconst_B_dict.txt`, `mtl_hlsl_inventory.tsv`, `mtl_allmat_progrefs.tsv`, `mtl_postfx_blocks.txt`, `mtl_issues.tsv`, `mtl_catalog.json` |
| `Tools\re\ogre_api_gap.py` | `Tools\re\out\ogre_api_gap.tsv` (B OgreMain exports whose identifier does not exist in 0.85 source) |
| Ghidra (`Tools\re\ghidra\CyReDump.java`, `CyReByName.java`) | `Tools\re\out\ghidra\ogre_autoparams2.txt` (B OgreMain `_updateAutoParams*`), `shadow_env.txt` (Render.dll material system) |

## 1. Inventory (FACT)

| | B `client_GL\Data\MaterialTemplates.zip` | 0.85 data zip (`Reference\…\Build\Client\Data\MaterialTemplates.zip`) | 0.85 source (`Src\Engine\WXCore\MaterialTemplates`) |
|---|---|---|---|
| size / SHA-256 | 2,471,212 B / `17a09eb0…2c233fcf` | 85,384 B / `3c837105…d459e9a` | 11 files (+ 5 post-filter `.material`/`.cg` pairs in `WXCore\PostFilter\media`) |
| entries | 114 (112 files + dirs `ShaderLib/`, `Schema/`): 67 `.hlsl`, 20 `.inc` (13 in `ShaderLib/`), 4 `.material`, 2 `.program`, 2 `.overlay`, 1 `.mesh`, 16 textures | 17 files (Cg/HLSL SM1–2) | Cg SM1–2 + `nm_*.png` |
| program declarations | `Character.program` + `Particle.program`: **94** (16 `vs_3_0`, 78 `ps_3_0`), all `hlsl` | 82 declared `hlsl` (64 `vs_1_1`, 16 `vs_2_0`, 1 `ps_2_0`, 1 `ps_1_1`) whose sources are `Character.cg` (34) / `ScorpioHardwareSkinning.cg` (48) | 31 `cg` incl. PostFilter media (`vs_1_1 arbvp1`, `ps_2_0 arbfp1 fp20`…) |
| template materials | 97 (`Mtl_Character.material` 53,970 B, `Mtl_Particle.material`, `loginSplash*.material`) | 31 | 18 (incl. PostFilter media) |

Other B shader sources outside the zip (FACT): `MaterialFolder\*.program` = 25 programs (hdr, std_quad, FixStar, SkySphereLayer [vs_1_1/ps_2_0], WaveGrass, FontTemplate); `all.material` itself declares **94 programs** (22 `vs_3_0` + 72 `ps_3_0`: all post-filters, sky/EnScene, water, SSAO). `mtl_programs.tsv` lists every one (source, entry, target, defines, auto params).

`all.material` (GBK, 17.3 MB): 65,046 materials; **50,857 (78 %) inherit** `material X : Parent` from 50 parents; 73,256 `set_texture_alias` lines. Parent syntax is already supported by the 0.85 parser (`OgreMaterialSerializer.cpp:1835–1880`, "nfz" clone) — FACT.
Parser-style check (FACT, `mtl_issues.tsv` empty for B corpora): no inline `{`/`}`, no trailing `//` comments, no `/* */` in any B script → the 0.85 line-based `MaterialSerializer::parseScript` (`OgreMaterialSerializer.cpp`, lines 2560–2610) can tokenise all B files; the gaps are keywords and semantics only.

Top template usage in all.material (FACT, `mtl_template_usage.tsv`):

| Parent template | uses | aliases set |
|---|---|---|
| Mtl_Particle | 10,367 | baseTexture |
| Mtl_Particle_ColorX2 | 8,389 | baseTexture |
| Mtl_Character_Lit | 5,833 | baseTexture |
| Mtl_Particle_TwoTex_Tex1_ColorX4 / _ColorX4 / _TwoTex_Tex1_ColorX2 / _TwoTex | 5,326 / 5,252 / 3,843 / 2,775 | baseTexture, scrollTex |
| Transparent/AlphaTemplate | 1,769 | baseTexture |
| Mtl_Character_FlowLight / Mtl_OutlineCtrl_FlowLight / Mtl_Char_FLTrans / Mtl_Outline_FlowLight | 1,171 / 1,015 / 890 / 417 | baseTexture, ctlTex, _Reflection, outlineCtrlTexture |
| WeaponTemplate(+Alpha) | 554 + 137 | BaseTexture (+ `reflect.tga` at sampler 3) |
| AlphaBlend/ColourChangable/AlphaTemplate | 536 | baseTexture |
| Mtl_Particle_Dissolve | 359 | baseTexture, dissolveTexure |
| LSSceneN (+/Transparent, _Emissive) | 226 + 119 + 3 | baseTexture, normalTexture, reflectTexture |
| Pbr_Mat / Mtl_Character_PSLit / XingNing_PlannarRim | 6 / 15 / 4 | albedo/metallic/normal; stars/rim |

47 of the 50 parents are defined in the B zip; 3 (`shader_water01`, `shader_water01_DSIntZ`, one buff effect material) are defined in all.material itself (FACT, `mtl_template_usage.tsv` column defined_in).

## 2. Script-keyword gaps (FACT: absent from the 0.85 attribute-parser tables `OgreMaterialSerializer.cpp:2443–2533`; present as strings in B `OgreMain.dll` next to the MaterialSerializer error strings, file offset ≈0x2c0790)

| ctx / keyword | uses (tpl / all.material) | values seen | B API (FACT, `ogre_api_gap.tsv`) | Required behaviour |
|---|---|---|---|---|
| pass `render_queue` | 13 / 15 | `on 69`, `on 77`, `on 70`, `on 73`, `on 41` | `Pass::setRenderQueueEnabled/getRenderQueueID` | per-pass render-queue override (transparent sort order, water at 77…) |
| pass `separate_scene_blend` | 3 / 6 | `src_alpha one_minus_src_alpha one one`, `… zero zero` | `Pass::setSeparateSceneBlending`, `getSourceBlendFactorAlpha` | D3DRS_SEPARATEALPHABLENDENABLE + SRCBLENDALPHA/DESTBLENDALPHA |
| texture_unit `content_type` | 10 / 19 | `compositor SceneRender depth_buffer`, `compositor SceneRender scene_buffer`, `dsintz` (B also knows `named`, `shadow`, `global`) | `TextureUnitState::setContentType/setCompositorReference/getReferencedCompositorName/MRTIndex`; Render.dll imports `setCompositorReference` (called from `FUN_180210420`) | bind a texture produced by another compositor (scene colour, linear depth) or the INTZ hardware depth texture |
| texture_unit `sampler_index` | 42 / 111 | 0, 2, 3, 6, 7, 8, 9, 10, 11 | `setSamplerRegisterIndex/getSamplerRegisterIndex` | TUS → explicit D3D sampler register (0.85 binds unit *i* to sampler *i*) |
| texture_unit `shader_type` | 0 / 104 | `vs` | `setTexUnitShaderType` | vertex-texture fetch (`WaveGrass_RandomTex_VS` samples `<wavenoise>` in the VS) |
| (known, unused) `use_type`, `texture_source` | 0 | — | `setTexUnitUseType` | not needed for data |

Fixed sampler registers in `ShaderLib\ParamNamed.inc:158–169` (FACT): `SphereMappingSampler s3`, `LUTSampler s4`, `ShadowMapSampler s5`, `ssao_buffer s12`. Templates use `sampler_index` 2–11 for stars/rim/detail/terrain layers (`mtl_templates.tsv`, column texture_units).
No other keyword or value gap was found: all enum values used (`scene_blend`, `filtering linear linear none`, `tex_address_mode clamp clamp`, `texture <x> 2d 6`, `texture <x> -1` = MIP_DEFAULT, `param_named` types float…float4) exist in 0.85 (`mtl_value_usage.tsv`, last column).

## 3. GPU-program pipeline gaps

| # | Gap | Evidence | Spec |
|---|---|---|---|
| P1 | **`#include` not supported** | FACT 0.85 `OgreD3D9HLSLProgram.cpp:106–116` passes `NULL //no includes` to `D3DXCompileShader`; 37 of 89 B HLSL/INC files include others (`mtl_hlsl_inventory.tsv`): `ModelDef.inc`×17, `ShaderLib/CalcPos.inc`×8, `ShadingParams`, `CalcUV`, `TexKill`×5, `CalcLight`, `CalcView`, `Diffuse`, `Utility`×4… | Implement `ID3DXInclude` that opens `ShaderLib/x.inc` and bare `x.inc` through `ResourceGroupManager` (zip archive), relative to the including file first, then the group root. Must handle GBK comments (bytes pass-through). |
| P2 | Shader binary cache | FACT B `RenderSystem_Direct3D9.dll` strings `.\ShaderCache\`, `.bin`, `.\ShaderCache\DISABLED` (offset 0x32922); `Game.exe` strings `NewMaterialTemplateMD5`, `NewShaderCacheReset`, `CVariableSystem::SetShaderCache Begin, UpdateType is %d, MaterialTemplateMD5 is %s, HardwareID is %s,%s…` | Cache compiled microcode keyed by (program name, defines, target, zip MD5). Not needed for correctness; needed for load time (hundreds of permutations). |
| P3 | Runtime permutation defines | FACT `Render.dll FUN_180154160` registers 22 macro slots: `USE_SKIN, USE_QUAT_SKIN, USE_TEXCOORD, USE_NORMAL, USE_TANGENT, USE_VERTEXCOLOR, TEX_EFFECT_0/1, TEX_PROJECT, LIGHT_CALC_TYPE, ALPHATEST_ENABLE, BLEND_OP_0/1, DIFFUSE_1/2_ENABLE, SPHEREMAPPING_ENABLE, SHADOWMAP_TYPE, LUT_ENABLE, VS_ANIMATION, USE_MODEL_VS_OUT, PER_ALPHA, DISSOLVE_EFFECT`; B OgreMain exports `GpuProgram::getPreprocessorDefineMap`, `Material::setUseTemplate/hasTemplate`, `Pass::_dirtyShaderHash` | INF: Render.dll's `MaterialSystemManager` (`…\FairyCore\Core\MaterialSystem\MaterialSystemManager.cpp`, "Create Material Desc failed! Duplicate material name") clones template programs with extra defines per model state (skin/DQ skin, shadow type, LUT, dissolve). Implement `ProgramVariantCache: (template program, define set) → HighLevelGpuProgram`. Values: `SHADOWMAP_NONE 0, CSM 1, SIMPLE 2` (`ParamNamed.inc:81–83`). |
| P4 | Auto-binding by uniform name | FACT `FUN_180155ba0` / `FUN_180154d30` hold 45–48 auto-constant names (e.g. `world_matrix_array_3x4[0]`, `light_position_array[0]`, `shadow_csm_param`, `isystem_userdata`); `ParamNamedAuto.inc` declares uniforms named exactly like the auto constants | INF: generated variants get `param_named_auto <name> <name>` implicitly for every uniform whose name is in the dictionary. Implement "auto-bind if uniform name ∈ dictionary". |
| P5 | Vertex texture fetch | FACT no `D3DVERTEXTEXTURESAMPLER` anywhere in 0.85 D3D9 (`grep`); needed by `shader_type vs` (104) | `_setVertexTexture(unit)` → `SetTexture(D3DVERTEXTEXTURESAMPLER0+n)`; caps check (`vs_3_0`). |
| P6 | INTZ depth texture | FACT none in 0.85 D3D9; B D3D9 contains FOURCC `INTZ` (3 hits, e.g. offset 0x11887); B `RenderSystem::checkDSTextureIntz/getDSTextureIntz/msDSTexIntZName` exports; `*_DSIntZ` programs with `USE_DSINTZ=1` (HeightFog, DoF, water, FakePointLight) | Create the main depth-stencil as an INTZ texture when `CheckDeviceFormat(INTZ)` succeeds; expose it to `content_type dsintz`. Fallback = the `SceneDepth` render node (`depth_buffer`, see 02 §4). |
| P7 | Skinning limits | FACT `ParamNamedAuto.inc`: `MAX_SKIN_BONE_NUM 74` (float3x4 → 222 VS regs), `MAX_QUAT_SKIN_BONE_NUM 105` (float2x4 → 210 regs); OgreMain B exports `GpuProgramManager::_checkForHardwareSkinningMaterialSupport` | Enforce ≤74 bones per submesh for LBS and ≤105 for DQ; software fallback otherwise. |
| — | Already OK in 0.85 | FACT `entry_point`, `target`, `preprocessor_defines`, `column_major_matrices` (`OgreD3D9HLSLProgram.cpp:254–265`; B uses `column_major_matrices false` ×28); `vs_3_0/ps_3_0` pushed as syntax codes (`OgreD3D9RenderSystem.cpp:979,1122`); array uniforms mapped as `name[e]` (`OgreD3D9HLSLProgram.cpp:221–226`); `includes_skeletal_animation`. | — |

## 4. Auto-constants

B's dictionary has **124** names; 87 are the 0.85 names (`OgreGpuProgram.cpp:47–146`), **37 are new** (FACT, `mtl_autoconst_B_dict.txt`, strings in B OgreMain at file offset ≈0x2b5870). B scripts use 17 of the new names directly; the rest are bound by Render.dll (P4). Semantics below are FACT from the B OgreMain decompile (`GpuProgramParameters::_updateAutoParamsNoLights` @0x1800a4650, `_updateAutoParamsLightsOnly` @0x1800a3550, getters in `ogre_autoparams2.txt`); enum numbers are B's (note B's dictionary *order* differs from its enum: `dual_quaternion_array_2x4` is string #7 but enum 0x7b) — our engine may renumber freely, only names matter.

| name | B case | value | script uses (tpl/prog/allmat) |
|---|---|---|---|
| `shadow_view_matrix`, `shadow_proj_matrix`, `shadow_viewproj_matrix` | 0x1e–0x20 | light view / ortho proj / product (AutoParamDataSource +0x62f4/+0x6334/+0x6374) | engine |
| `shadow_param` | 0x21 | (strength, PBR strength, map size, 0) from `SceneManager::setShadowParams` | engine |
| `shadow_csm_param` | 0x22 | (cascade count, 1/count, blend band, max shadow distance) | engine |
| `shadow_csm_proj_scale`, `…_offset` | 0x23/0x24 | 4 rows = per-cascade xyz scale / offset of light-view→atlas | engine |
| `fog_type` | 0x26 | float4 fog-mode vector (+0x64e4) consumed by `Fog.inc` | 60 / 1 / 2 |
| `texture_matrix`, `texture_matrix_2x4` | 0x71/0x72 | TUS texture transform (index in extra param), 4 or 2 rows | 0/0/1, 2/0/0 |
| `actor_lightone_params`, `actor_lighttwo_params` | 0x73/0x74 | `SceneManager::setActorLightOne/Two` colours (EnvKey `actor_light_one/two`) | 15 |
| `actor_ambient_params` | 0x75 | surface emissive + actor derived ambient (`getActDerivedSceneColour`) | 16 |
| `derived_pbr_scene_colour` | 0x76 | surface emissive + PBR derived ambient (EnvKey `pbr_ambient`) | 6 |
| `imodel_userdata` | 0x77 | (renderable byte +0x25 = actor/model blend flag, weights-per-bone, alpha-test ref/256, brightness) | 22 / 1 / 0 |
| `isystem_userdata` | 0x78 | (**shadow const bias**, useLinearColorSpace, colorGreaterOneEnable, **shadow normal bias**) — the comment in `ParamNamedAuto.inc:122` ("x: hdr, y: linear") is outdated | 10 |
| `wind_control_params` | 0x79 | (wind dir x, wind dir z, strength, `time_0_x(300)`) | 4 |
| `depth_camera_params` | 0x7a | 4 floats from `SceneManager::setDepthCameraParams` | engine |
| `dual_quaternion_array_2x4` | 0x7b | per-bone dual quaternion, 2 float4 each, count = world-matrix count | 2 |
| `skydome_ambient_color` | 0x7c | `SceneManager::setSkyDomeAmbientColor` (EnvKey `skyDomeAmbientColor × Strength`) | 0/0/1 (`EnScene/skydome_fp`) |
| `light_count`; `light_{diffuse,specular}_colour_array`, `light_attenuation_array`, `light_position(_object/_view)_space_array`, `light_direction(_object/_view)_space_array`, `light_distance_object_space_array`, `light_power_array`, `derived_light_{diffuse,specular}_colour_array` | LightsOnly 49–75 | N-light arrays (`MAX_LIGHT_NUM 3`) | 13–54 |
| `inverse_{world,view,worldview}_matrix_3x4` | — | inverse as 3×4 | 0–2 |

How shaders use them (FACT, grep of the zip): `CalcLight.inc` lerps scene lighting vs actor lighting by `imodel_userdata.x`; `CalcPos.inc` loops `i < imodel_userdata.y` bone weights; `Model_Emissive_ps` uses `step(imodel_userdata.w, 0.4)`; `CalcShadow.inc` uses `isystem_userdata.x/.w` (biases) and `.z` (HDR range).

## 5. Texture aliases (FACT)

Template `texture_alias` vocabulary (count of template TUS): `<baseTexture>` 101, `<normalTexture>` 15, `<scrollTex>` 14, `<_Reflection>` 11, `<albedoTexture>` 11, `<ctlTex>` 10, `<metallicTexture>` 9, `<envTexture>` 9, `<dissolveTexure>` 5, `<starsTexture>/<starsDistortionTexture>/<rimTexure>` 4, `<emissiveTex>` 3, `<MaskTexture>` 3, `<DTexture0–2>/<DNTexture0–2>` 1–2, `<LTexture0–2>/<LNTexture0–2>` 1 (PBRScene_Detail / _More_Detail / _Terrain). all.material sets: `<baseTexture>` 50,156, `<scrollTex>` 13,300, `<ctlTex>` 3,500, `<_Reflection>` 3,499, `<outlineCtrlTexture>` 1,017… DataCY/CY Game additionally set `<envTexture>` 249, `<MaskTexture>` 37, `<DTexture*>/<DNTexture*>` 36 each (doc 01 §7, `Docs\evidence\assetinv\fxkeys.json`). `set_texture_alias` exists in 0.85 (OK).

## 6. Material-instance parameter system (Render.dll, not script-visible)

FACT `FUN_180156ab0` registers 54 named shader constants that Render.dll pushes per LogicModel/particle: `tex0BlendColor, multiBlendColor, flowFactor, D0UV_params…D2UV_params, DN_params, outlinePow, outlineColor, spec_params, dissolveClip, dissolveColorA/B, dissolveUVRepeat, dissolveParams, dissolveSoftEdgeWidth, dissolveEdgeLighting, dissolveFlowSpeed, dissolveEdgeContrast, dissolveEdgeRange, dissolveEdgeColor, dissolveDirection, dissolveReverse, dissolveTime, dissolveMinProj, dissolveMaxProj, rimTintColor, starsTexDistortion_rimPow_rimClampMin_rimClampMax, rimFlowFactor, starsTexScaleFactor, texRotateScale, texDepthFactor, wavesSpeed, FogColorDensity, BigWavesScale, SmallWavesScale, BumpScale, ReflectionAmount, TransparencyRatio, SunShinePow, SunMultiplier, FresnelBias, UVScale, heightParams, L0UV_params…L2UV_params, LN_params, lightParams, useRibbon, widthRatio, useUDirection, blocks, sequenceFrameUVFactor`. Writers: `FUN_1801e9530` (particle dissolve), `FUN_180170170`/`FUN_18016eaf0` (model `@Disslove`/`@Transparent` material clones), `FUN_1801e9bb0` (sequence-frame UV), water objects. C additionally has `dissolveBox` (FACT: only in CY 3.71 `Render.dll` 0x2e9370, 0 uses in S1/S2 data).
Spec: `MaterialInstance` = cloned Ogre material + dictionary of named constants, applied with `hasParamerter()`-guarded `setNamedConstant` (B OgreMain exports `GpuProgramParameters::hasParamerter`, FACT).

## 7. Other OgreMain deltas that materials depend on (FACT, `ogre_api_gap.tsv`, 2,146 methods scanned)

- `Pass` (16 new): separate blending, render-queue override, `setUseLit`, `setVertexProgram2/ShadowCaster…2`, `setSelfIlluminationAndDiffuseAlpha`.
- `TextureUnitState` (21 new): content type, compositor reference, sampler register, shader type, use type, `_setTexturePtr`, `retryTextureLoad`.
- `Technique/Material` (5+9 new): scheme type, `getBestTechniqueByScheme`, template flags.
- `SceneManager` (41 new): actor/PBR ambient, actor lights, sky-dome ambient, `setBrightness`, `setColorGreaterOneEnable`, `setDepthCameraParams`, shadow setters, `setRenderGroupRange`, late material resolving, visibility-mask exclude.
- `AutoParamDataSource` (50 new getters), `RenderConfigManager` (13, material LOD by distance/AABB), `Renderable` (13: queue ID, type, visibility flag, AABB radius LOD), `TangentSpaceCalc` (19, MikkTSpace), `RenderSystem` (INTZ).

## 8. Implementation spec (order) and acceptance

1. **Parser**: add the 5 keywords of §2 (+`use_type` no-op) with B semantics; unknown keywords must log file:line (doc 08 §3.1). Test: parse `all.material` + zip + MaterialFolder → 0 errors (`mtl_catalog.py` corpus counts must match: 65,046 materials, 50,857 parents resolved).
2. **HLSL**: include handler (P1), variant cache (P3), auto-bind by name (P4), binary cache (P2). Test: compile all 94 + 25 + 94 programs and every define permutation used by `FUN_180154160` without error on D3D9 SM3.
3. **Auto constants**: the 37 names with the semantics of §4 (`AutoParamDataSource` fields fed by SceneManager/Render). Test: PIX/RenderDoc-less check = dump constant table per program and compare values with B via a debug overlay (INF).
4. **RenderSystem**: separate alpha blend, per-pass queue, sampler-register mapping, vertex textures (P5), INTZ (P6), compositor texture references.
5. **Material instance system** (§6) + template/scheme selection (`Depth` scheme is required by shadows and SSAO, docs 02/03).

Effort (1 engineer + AI): parser 3–4 d; HLSL pipeline 1.5–2 wk; auto constants 1 wk; render-system items 1–1.5 wk; material instance system 1.5–2 wk → **≈5–7 weeks** for full template parity. Visual acceptance: SSIM ≥ 0.95 vs `client_GL` on 50 models (doc 03 gate E2).
