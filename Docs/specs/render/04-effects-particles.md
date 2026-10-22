# 04 — Effects & particles: the types B supports and 0.85 lacks

Status: spec for phase E2 item 4. Date 2026-09-12. FACT/INF legend as in `01-materials.md`.


## 1. Summary (FACT, `fx_types.tsv`)

| Block (file) | S1 uses | S2 uses | In 0.85 src | Implemented in B | Class / factory evidence |
|---|---|---|---|---|---|
| `affector RevoluMove` (all.particle) | 3,164 | 3,374 | no | Plugin_ParticleFX2.dll | string `RevoluMoveAffector` (file 0x11790 region) |
| `emitter Cylinder` new keys `curve`, `bend_angle` | 0 | 1 (`curve 4`) | Cylinder yes, keys no | Plugin_ParticleFX.dll | strings `topdown_ratio | curve | BendAngle` (B) / `bend_angle` (C) |
| material param `dissolveBox` | 0 | 0 | no | only CY 3.71 Render.dll (0x2e9370) | material-system constant, see 01 §6 |

Registered but unused by S1/S2 data (FACT strings, Render.dll 0x2b8958…): affectors `UvAnim` (`ParticleUvAnimEffect`, param `offset`), `MeshRotator`, `MeshAnimationAffector`, `CurveAffector` (curve files `../Media/Curve/*.curve`, `CurveSegmentManager`, param `curve_name`); skill blocks `CameraMove`, `RadialBlur`; element `RibbonTrail`, `Beam`, `Mesh`. 0.85 already has elements Particle/Mesh/Beam/Projector/PointLight/BillboardSet and skill AnimEffect/Ribbon/Sound/SceneLight (FACT, `WXCore\EffectSystem` literals) and ParticleFX2 affectors Revolution/Movement/ColourFading/ScaleInterpolator + PolarEmitter.


## 2. Per-type specification

Ranges are S1 min..max per component (FACT `fx_params.tsv`); descriptions in quotes are the B `ParameterDef` strings (FACT).

### 2.1 NewRibbonTrail element (294 uses; wings, weapon/pet trails)
Keys (all present in 294/294 blocks unless noted): `TrailLength` 25..3000 "the length of trail"; `MaxChainElements` 6..200 "the max number of chain elements"; `InitialWidth` 5..300 "the width of initial"; `WidthChange` −30..60 "the width change per second"; `TailWidth` 0..220; `LowWidthCut` 0..120 / `HighWidthCut` 17..550 "the low/high width cut"; `ColourFadingTime0..4` 0..1 + `ColourFadingColour0..4` RGBA "colour change key frame time/colour"; `AlphaColourCut` 0..0.6 "the Alpha cut of colour"; `LiftTime` 0..2.65 "the life time of element"; `Material` (e.g. `兽魂附体_211223金乌拖尾A02`); `BillboardType` camera (283) / follow_bone (11) — accepted values `camera, point, oriented, perpendicular, follow_bone`; `Direction_or_Point` "the billboard Direction" (0 0 0 in data); common element keys `StartTime`, `LifeTime` 0..8, `CreateLevel`, `Position`, `Orientation`, `ParentSpaceLock` (80).
Behaviour (INF from names): a chain of up to MaxChainElements nodes sampled along the attach point path over TrailLength; each node keeps a life of LiftTime, width starts at InitialWidth and changes by WidthChange/s, clamped to [LowWidthCut, HighWidthCut] (tail forced to TailWidth); colour/alpha from a 5-key gradient over node age; nodes with alpha below AlphaColourCut are dropped; billboarded towards camera or following the bone axis. Implement on top of OGRE `BillboardChain`/`RibbonTrail` (FACT: 0.85 ships `OGRE\OgreMain\include\OgreBillboardChain.h` and `OgreRibbonTrail.h`) or a custom dynamic VB; B's own `FairyRibbonTrail.cpp` (`RibbonTrail::addNode`) is separate from OGRE's.

### 2.2 UIParticle element (9 uses, `UI_CBT_2024_*`, `UI_pm_yanwu*`, `UI_PVE_2024_*`)
Same keys as `element Particle` (`ParticleSystem`, `ParEffectName`, `ColEffectName`, `use_particle_*`, `use_energy_wave`, `legacy_pos_for_sub_effect`, `pass_rotation_to_sub_effect`). Semantics (INF): particle system rendered in UI/overlay space with its own shader (`getUIParticleSystemShader`) and screen transform (`UIParticleSystem::SetWorldTransform`) so CEGUI windows can show particle effects. Needs a render hook after CEGUI or into a CEGUI render target.

### 2.3 RevoluMove affector (3,164 uses — the most used new type)
Keys: `rotation_speed` −555..900 "the speed of particle circle rotation" (459); `rotation_axis` (165); `radius_increment` −3000..2000 (1,116); `use_radius_increment_scale` + `radius_increment_scale0..5` −8000..9000 with `time0..5` (curve of radius growth, " RadiusIncrementScale.") (1,082); `center_offset_min/max` (≈180, xyz up to 50000); `move_usevariablevelocity` "Use VariableVelocity movement" (1,865) + `move_velocity_point0..5` (xyz) with `move_time0..5` "The velocity of the movement … velocity" (≈1,700); `move_velocity` (16); `move_repeattimes` 2..10 "repeattimes" (8).
Behaviour (INF): each particle orbits a centre (emitter origin + random offset) around `rotation_axis` at `rotation_speed` deg/s while the orbit radius grows by `radius_increment`·scale(t); in addition the particle translates with a piecewise-linear velocity curve (6 keys over normalised life, optionally repeated). Extends 0.85's `Revolution` affector (same plug-in).

### 2.6 RotationCurve affector (30 uses; mesh particles)
Keys: `init_rot_range_start/end` 3f (yaw/pitch/roll degrees, −120..200); `yaw_speed0..4`, `pitch_speed0..4`, `roll_speed0..4` — each "value time" pairs (value −800..880, time 0..1). Behaviour (INF): initial Euler rotation random in range; angular speed per axis from a 5-key curve over life (3-D version of OGRE `Rotator`, complements 0.85 `MeshRotator`).

### 2.7 PolarMove affector (13 uses)
Keys with B descriptions: `times` "the time breakpoint at which the influencer is in effect"; `radiuses`, `thetas`, `phis` "… at every time breakpoint" (2–3 keys; values up to ±189000 deg for spirals); `disturbance_force` "affects the frequency of disturbance"; `disturbance_scope` "the size of disturbance scope"; `clockwise_probability` "the direction of rotation of each curve"; `disturbance_rotation` / `disturbance_initial_offset` "the angle of rotation/offset of each curve at starting"; `use_polar_step`; `activate_disturbance` "turn on the disturbance or not on"; `use_tilt` "turn on the tilt … while disturbance is activited"; `flip_yz_axis`; `reset_radius_count` "when you use the radius step, this value can control the radius reset by emitting reset_radius_count particles". Behaviour: particle position = spherical (r, θ, φ) interpolated between breakpoints over life, plus optional noise-like disturbance curves.

### 2.8 CameraShake (skill sub-block, 16 uses)
`AttachTime` "the time that shake the camera" 0..0.86; `Duration` 0.4..0.8 (S2 up to 8); `RotAmplitude/RotFrequency` 3f; `LocAmplitude/LocFrequency` 3f (≤150 units); `FovAmplitude/FovFrequency`; `ShakeManner` LinearDecrease 9 / QuadraticDecrease 7 "the way of camera shake"; `IsLocalVisible` "whether or not the camera move is local visible" (only the local player's camera). Behaviour: sinusoidal offset of camera position/rotation/FOV per axis with amplitude decaying linearly or quadratically over Duration, started AttachTime after the skill starts.

### 2.9 ComplexBlur (skill sub-block, 1 use)
`AttachTime` "the time that begin radial blur", `StartTime`, `MidTime`, `EndTime` (ramp), `Strength` 0.08, `Unblured` 0.1, `FinalDistance` 30, `IsLocalVisible`. Drives the `ComplexBlur` post-filter (parameters `fDistance, fStrength, fUnblured`, material `PostFilters/ComplexBlur`, 02 §3) — INF: strength ramps up to MidTime and down to EndTime.

### 2.10 Cylinder emitter `curve` / `bend_angle`
FACT: both keys exist in B `Plugin_ParticleFX.dll` next to `inner_width/inner_height/angle_range/topdown_ratio`; only S2 uses `curve` once (value 4, `all.particle:3015274`). INF: bends the cylinder along an arc. Low priority; accept and store the keys so parsing never fails.

## 3. Implementation spec and order

1. **Parser robustness first**: unknown element/affector types and keys must be skipped with a file:line warning instead of dropping the rest of the file (doc 08 §4.1). This alone removes "red blob" failures.
2. Render.dll-side affectors (Dissolve, SequenceFrame, RotationCurve, PolarMove) as `Ogre::ParticleAffector` subclasses registered through the particle manager; ParticleFX2 gains RevoluMove.
3. NewRibbonTrail element (dynamic chain renderer, 5-key colour gradient, billboard modes).
4. Skill blocks CameraShake/ComplexBlur (camera controller + post-filter trigger); UIParticle (UI render hook).
5. Material hooks: `DISSOLVE_EFFECT` / `sequenceFrameUVFactor` named constants (01 §6).

Acceptance: load S1+S2 effect files with 0 "unknown element/affector" messages; ≥100 effects render within SSIM 0.95 of client_GL in the TLBB Viewer (doc 03 gate E2). Effort ≈3–5 weeks total (RevoluMove/SequenceFrame/Dissolve/NewRibbonTrail cover 99 % of uses: 5,422 of 5,491 S1 blocks).
