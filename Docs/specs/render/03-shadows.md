# 03 — Shadows: shadow map, CSM, PCF

Status: spec for phase E3. Date 2026-09-12. FACT/INF legend and Render.dll build note as in `01-materials.md`
(addresses = original Render.dll `fda12053…`; `client_GL` runs a byte-patched copy that turns the pipeline on).


## 1. Starting point

- 0.85: OGRE stencil shadows only (`Src\Engine\WXRender\RenderSystem.cpp:1222–1224`, doc 01 §2.4) plus the `ShadowBlob.tga` decal; no `shadow_*` auto constants (0.85 dictionary), no render-node pipeline — FACT.
- B: complete shadow-map pipeline that is **off by default**: every call site passes 0 to `setShadowMapEnabled` (KET-QUA-PHA2 §2). client_GL enables it with `patch_shadowmap.py` (file 0x15B24/0x15B33 `33 D2`→`B2 01`, doc 08 §10) — FACT.

## 5. Spec for CY-Source

1. OgreMain: AutoParamDataSource shadow fields + the 8 SceneManager setters + auto constants `shadow_*`, `isystem_userdata`.
2. Render: `ShadowSystem` (config above, persisted in System.cfg — **enable at start-up, no event dependency**, doc 08 §3.6), light-camera fitting (SIMPLE + CSM with texel snapping), atlas render target (width = size·count), `Depth` scheme generation for every material (variant with `USE_SKIN/USE_QUAT_SKIN/ALPHATEST_ENABLE`).
3. Render-node framework (`SceneRender` post-filter with nodes ShadowMap=4, SceneDepth, SceneDepthForWater, GenSSAO) — shared with 02 §4.
4. Config keys (proposal): `Gfx_Shadow=0/1/2` (off/simple/CSM), `Gfx_ShadowSize=1024…4096`, `Gfx_ShadowCascades=1…4`, `Gfx_ShadowSplits=a,b,c,d`, `Gfx_ShadowBias=const,normal`; defaults = B defaults above.
5. Acceptance: Tô Châu at noon, 4 fixed camera poses, SSIM ≥ 0.95 against client_GL with the shadow patch; no shadow acne on terrain slopes; ≤ 2.5 ms GPU at 1440p on RTX 2060 for 4 cascades (INF budget).

Effort: 2–3 weeks after the material system (Depth scheme, P3/P4 of 01) and the render-node framework exist.
