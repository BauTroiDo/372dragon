# 03 — Shadows: shadow map, CSM, PCF

Status: spec for phase E3. Date 2026-09-12. FACT/INF legend and Render.dll build note as in `01-materials.md`
(addresses = original Render.dll `fda12053…`; `client_GL` runs a byte-patched copy that turns the pipeline on).

Evidence: `Assets\Staging\materialtemplates\B\ShaderLib\CalcShadow.inc`, `ParamNamed.inc`; Ghidra dumps in
`Tools\re\out\ghidra\` — `shadow_cfg.txt` (constructor `FUN_1800cbef0`), `imp_callers.txt` (`FUN_1800cdc70`),
`shadow_csm.txt` (`FUN_1800cd580`, `FUN_1800cc450`, `FUN_1800cd910`), `shadow_env.txt` (`FUN_1800cd940`, `FUN_180014b40`,
`FUN_180016f70`, `FUN_18015dd90`), `ogre_autoparams2.txt` (B OgreMain); prior RE `analysis\graphics-overhaul\KET-QUA-PHA2_vi.md`,
`…\ghidra\out\render-shadow-xrefs.txt` (`FUN_1802143b0`).

## 1. Starting point

- 0.85: OGRE stencil shadows only (`Src\Engine\WXRender\RenderSystem.cpp:1222–1224`, doc 01 §2.4) plus the `ShadowBlob.tga` decal; no `shadow_*` auto constants (0.85 dictionary), no render-node pipeline — FACT.
- B: complete shadow-map pipeline that is **off by default**: every call site passes 0 to `setShadowMapEnabled` (KET-QUA-PHA2 §2). client_GL enables it with `patch_shadowmap.py` (file 0x15B24/0x15B33 `33 D2`→`B2 01`, doc 08 §10) — FACT.

## 2. Configuration object (FACT, `FUN_1800cbef0` = ctor of the FrameListener stored in `DAT_1803a6a90`)

| offset | meaning | default | writer |
|---|---|---|---|
| +0x30 | shadow camera ready | 0 | `FUN_1800cc450` |
| +0x31 | enabled | 0 | `FUN_1800cd940` = setShadowMapEnabled (also sets `GfxLayer+0x12`, toggles render node 4 via `FUN_18015f1a0(pf,4,on)`) |
| +0x33 | SIMPLE-mode focus variant | — | — |
| +0x38 | light back-off added to cascade far (near = −maxZ − back-off) | 8000.0 | ctor |
| +0x3c | (unknown) | 1000.0 | ctor |
| +0x40 | mode 0 = SIMPLE, 1 = CSM | **1** | ctor |
| +0x44 / +0x48 | shadow strength / PBR shadow strength → `shadow_param.x/.y` | 1.0 / 1.0 | ctor, EnvKey (INF, `FUN_180182550` calls the cfg getter twice) |
| +0x4c | cascade count (clamped ≤ 4) | **4** | `FUN_180014b40(count, float splits[count])` (disables, stores, re-enables) |
| +0x50 + i·0x4c | cascade *i*: split far distance (+0), near/far (+4,+8), custom ortho projection 4×4 (+0xC…+0x48) | split: via `FUN_1800cd910` (+0x50,+0x9c,+0xe8,+0x134) | `FUN_1800cd580` |
| +0x180 | (unknown) | 0.178 | ctor |
| +0x184 | CSM blend band → `shadow_csm_param.z` | 0.005 | ctor |
| +0x1c8 | shadow map size (float) → `shadow_param.z` | set by `FUN_180016f70(int)` (disable/store/re-enable) | — |

Render node (FACT `FUN_1802143b0` `Fairy::defRenderNode_ShadowMap`): node index 4 in the `SceneRender` post-filter; texture def `shadow_buffer` **4096×4096**, format 0x21 = `PF_FLOAT32_R` (OGRE 1.2 enum, INF that B kept the numbering), flag +0x53 = 1, camera name `ShadowMap_Camera`; material scheme `Depth`; render queues 0x28–0x32 and 0x44–0x46 (KET-QUA-PHA2). Doc 08 §3.7 measured at run time "RT 4096² plus 4 cascades 2048²" per scene load.
Shadow camera (FACT `FUN_1800cc450`): created once in the main scene manager as `ShadowMap_Camera`; vtable calls set projection type 0 (INF: `PT_ORTHOGRAPHIC`), aspect 1.0, near 0.01, FOV 90°; attached to its own scene node.

## 3. Per-frame update (FACT `FUN_1800cdc70`, called from the frame listener)

1. If not (camera ready && enabled): notify the registered listeners at +0x1b0…+0x1b8 and return.
2. Light = direction of the scene's main light (object at scene-info +0x138; `Light::getDerivedDirection`, normalised).
3. **SIMPLE** (+0x40 = 0): `FUN_1800cdac0` (ensure `shadow_buffer` in `SceneRender`); focus the shadow camera — `FUN_1800ccef0(dir, 4096.0)` when the main camera flag is off, else `FUN_1800ccb20` (camera-frustum AABB fit) or `FUN_1800cc740` (`AutoGen_Cam_0`, fit around frustum AABB); then `SceneManager::setShadowViewMatrix/ProjMatrix`.
4. **CSM** (+0x40 = 1): `FUN_1800cd580(dir, size)`:
   - camera frustum corners for [near, split[count−1]] (`Camera` vtable 0x318), AABB → place light camera at centre − dir·|halfSize|·1.2;
   - for each cascade *i*: corners of [split[i−1], split[i]] in light view (`FUN_1800cdc00`) → AABB → `FUN_1800cc5a0(size, …)` (INF: texel snapping) → near/far = (−AABB.z₁ − back-off(+0x38), −AABB.z₀) (INF which AABB component is min/max) → `Frustum::calculateCustumPorjectMatrix` (B-only OgreMain API) stored in the cascade record;
   - build per-cascade scale/offset from `bias × proj_i` with bias = scale(0.5, −0.5, 1) · translate(0.5, 0.5, 0.5) and write them as rows of two 4×4 matrices;
   - `setShadowViewMatrix(lightView)`, `setShadowCSMParams(count, 1/count, +0x184, split[count−1])`, `setShadowCSMProjScale`, `setShadowCSMProjOffset`.
5. Always: `setShadowParams(+0x44, +0x48, size, 0)`.

These SceneManager setters are B-only exports (FACT `ogre_api_gap.tsv`) that fill `AutoParamDataSource` fields read by auto constants 0x1e–0x24 (01 §4). `SceneManager::setShadowConstBias/NormalBias` feed `isystem_userdata.x/.w`.

## 4. Shader contract (FACT `CalcShadow.inc`, `ParamNamed.inc`)

- `SHADOWMAP_TYPE` ∈ {`SHADOWMAP_NONE 0`, `SHADOWMAP_CSM 1`, `SHADOWMAP_SIMPLE 2`}; injected per material by Render.dll (`FUN_180154160` slot 0x11, 01 §3 P3). `ShadowMapSampler : register(s5)`.
- VS: SIMPLE → `shadowUV = (0.5,0.5) + (0.5,−0.5)·(proj·view·pw).xy/w`, z, w = −viewZ. CSM → `shadow = shadow_view × (pw + N·sin(∠(N,L0))·isystem_userdata.w)` (normal-offset bias).
- PS: brightness = luma(`light_diffuse_colour_array[0]`); CSM picks the first cascade whose `posInView·scale[i]+offset[i]` ∈ [0,1]³; atlas: `uv.x·(csm.y·border)+csm.y·(i+borderOffset)`, `uv.y·border+borderOffset`, border = (size−2)/size → cascades sit **side by side horizontally** in one texture of width size·count, height size (texel x = 1/(size·count)).
- `ManualPCF`: 3×3 point samples of *linear depth* (`tex2Dlod`) combined into 4 bilinear PCF results and averaged; compare `step(depth + isystem_userdata.x, sceneDepth)`; `lerp(mask·brightness, mask, isystem_userdata.z)`.
- SIMPLE fades out towards the map edge (radial); CSM fades over 0.95…1.0 × `shadow_csm_param.w` (distance to camera) and uses `lerp(1, 1−shadow, cascadeFound)`.
- Strength: non-PBR `shadow_param.x`, PBR (`IS_PBR_MODEL`) `shadow_param.y`; final = (1−s) + shadow·s; shadowed colour = 0.825·`derived_scene_colour`.
- Casters render with the `Depth` scheme programs of `Character.program` (`Depth_VS`, `Depth_Skin_VS`, `Depth_DQSkin_VS`, `*_VsAnimation_*`, `Depth_PS` with `ALPHATEST_ENABLE`). LogicModel per-object flags `ShadowCast`, `ReceiveShadow`, `ShadowUncasts`/`addShadowUncastable` (FACT strings, Render.dll 0x1802e2c18…). Terrain has its own copy of the code in `FairyTerrainColorMap.hlsl:222,288`.
- Scene data that tunes shadows: EnvKey `shadow_strength` (0.2–1.2) and `pbr_shadow_strength` (1.0–1.3) in 269 EnScene keys (`scene_xml_inventory.tsv`).

## 5. Spec for CY-Source

1. OgreMain: AutoParamDataSource shadow fields + the 8 SceneManager setters + auto constants `shadow_*`, `isystem_userdata`.
2. Render: `ShadowSystem` (config above, persisted in System.cfg — **enable at start-up, no event dependency**, doc 08 §3.6), light-camera fitting (SIMPLE + CSM with texel snapping), atlas render target (width = size·count), `Depth` scheme generation for every material (variant with `USE_SKIN/USE_QUAT_SKIN/ALPHATEST_ENABLE`).
3. Render-node framework (`SceneRender` post-filter with nodes ShadowMap=4, SceneDepth, SceneDepthForWater, GenSSAO) — shared with 02 §4.
4. Config keys (proposal): `Gfx_Shadow=0/1/2` (off/simple/CSM), `Gfx_ShadowSize=1024…4096`, `Gfx_ShadowCascades=1…4`, `Gfx_ShadowSplits=a,b,c,d`, `Gfx_ShadowBias=const,normal`; defaults = B defaults above.
5. Acceptance: Tô Châu at noon, 4 fixed camera poses, SSIM ≥ 0.95 against client_GL with the shadow patch; no shadow acne on terrain slopes; ≤ 2.5 ms GPU at 1440p on RTX 2060 for 4 cascades (INF budget).

Effort: 2–3 weeks after the material system (Depth scheme, P3/P4 of 01) and the render-node framework exist.
