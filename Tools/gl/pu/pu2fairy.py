#!/usr/bin/env python3
# -*- coding: utf-8 -*-
r"""pu2fairy.py - convert TLBB GL (天龙八部·归来) Particle-Universe effects (*.pu, binary JBPU) into Fairy
(TLBB 0.85 / CY-Source engine) all.particle + all.effect + all.material fragments, DDS textures and static
effect meshes, staged per effect under Assets\Staging\gl\effects\<effect>\ (never into Canonical/client_GL).

  pu2fairy.py convert PU [PU ...] [--out-root DIR] [--prefix gl_]
  pu2fairy.py batch SPEC.json [--out-root DIR]            SPEC: {"effects": [{"pu": path, "note": ...}, ...]}
  pu2fairy.py rank [--top 80] [--tsv OUT] [--workers 4]   score all GL .pu for richness + convertibility
  pu2fairy.py check DIR [DIR ...]                         syntax/schema/reference/name-collision check
  pu2fairy.py mapping                                     print the PU -> Fairy mapping table (markdown)

Output files are ASCII (a subset of GBK), CRLF, TAB indented, no comments (Docs\05 section 6.4 rules).
Semantic assumptions about GL that could not be read from data alone are collected in SEM (see the
decompiled evidence in Build\re\tlgl\out\pu and Tools\gl\pu\README_vi.md).
"""
import sys
sys.dont_write_bytecode = True          # never drop __pycache__ into the read-only tool folders we import from
import argparse
import collections
import hashlib
import io
import json
import math
import os
import posixpath
import re
import shutil
import struct
import subprocess
import time

HERE = os.path.dirname(os.path.abspath(__file__))
if HERE not in sys.path:
    sys.path.insert(0, HERE)
import jbpu  # noqa: E402

GL_ROOT = os.environ.get('TLGL_EXTRACTED', r'C:\TLBB\085\Tools\DATA NEW\TLGL_extracted')
TEXCONV = os.environ.get('TEXCONV', r'C:\TLBB\085\Tools\texture-upscale\texconv.exe')
GLMESH_DIR = r'C:\TLBB\085\Tools\gl-skin\scene3d'
OGRE_IO_DIR = r'C:\TLBB\085\tools\model-convert\lib'
CLIENT_DATA = r'C:\TLBB\085\client_GL\Data'
DEFAULT_OUT = r'C:\TLBB\085\CY-Source\Assets\Staging\gl\effects'
TOOL_VERSION = 'pu2fairy 1.0 (2026-09-12)'

# ----------------------------------------------------------------------------------------------------------
# GL semantics that the data alone does not fix (see README_vi.md for the evidence of every entry)
SEM = dict(
    dims_multiplier=True,      # emitter all_particle_dimensions / particle_width|height multiply the technique size
    default_size=50.0,         # technique default_particle_width|height|depth when absent (PU DEFAULT_WIDTH)
    scale_mode='mult1p',       # Scale affector. GL default set_scale=1 (ctor writes 0x0100 at +0x149):
                               # size = technique default * particle factor * (1 + value)   [decompiled FUN_140746980]
                               # 'rate' = PU size += value*dt (GL only when set_scale false; never in data)
    rot_unit='rad',            # TextureRotator / Vortex / GeometryRotator values are radians (per second)
    emitter_defaults=dict(emission_rate=10.0, time_to_live=3.0, velocity=100.0, angle=20.0, mass=1.0,
                          duration=0.0, repeat_delay=0.0),
    box_default=100.0, radius_default=100.0,
    quota_default=500,
    glow_boost=1.5,            # colour boost used for glow (GL bloom) when glow_value >= 1.5
)
DYN_TYPES = ('dyn_random', 'dyn_curved_linear', 'dyn_curved_spline', 'dyn_oscillate')
FRAME = 1.0 / 30.0             # one update of the B engine (ParticleSystem::setDefaultIterationInterval(0.033))

APPROX = collections.OrderedDict([
    ('A01', 'technique split into one Fairy particle system per visual emitter (exclude_emitter honoured)'),
    ('A02', 'emitted emitter (emits emitter_particle) placed on its spawner shape; spawner particle motion ignored'),
    ('A03', 'emitted technique (emits technique_particle) re-triggered on the spawner cycle at the spawner position'),
    ('A04', 'emits system_particle: nested system not converted'),
    ('A05', 'force_emission burst -> emission_rate x30 during one 1/30 s frame, repeated on duration+repeat_delay'),
    ('A06', 'auto_direction radial emission -> RevoluMove (rotation 0, radius_increment = speed)'),
    ('A07', 'auto_direction together with other velocity affectors -> isotropic 180 degree cone'),
    ('A08', 'emission direction not along the Fairy shape axis -> Movement start_velocity box around the PU cone'),
    ('A09', 'surface emission (Cylinder/Circle) -> Ring with inner 0.98; Circle step sequence -> random angle'),
    ('A10', 'Hemisphere emitter -> HollowEllipsoid (full sphere)'),
    ('A11', 'MeshSurface emitter -> Box of the mesh bounding box'),
    ('A12', 'Line emitter -> thin Box along the line; Position emitter -> one Point per position'),
    ('A13', 'emitter attribute curve / oscillation over system time -> mean value'),
    ('A14', 'Colour affector keys reduced to 6 ColourFading stages; multiply baked with the mean emitter colour'),
    ('A15', 'brightness above 1 (colour_factor, glow) -> ColorX2/ColorX4 template with colours divided'),
    ('A16', 'Scale affector curve integrated over the mean particle life -> ScaleInterpolator stages (per-particle random size replaced by its mean)'),
    ('A17', 'Jet acceleration (v *= 1 + a dt) -> emitter speed scaled to the same mean travel'),
    ('A18', 'ScaleVelocity affector -> emitter speed scaled to the same mean travel'),
    ('A19', 'Vortex -> RevoluMove orbit around the axis; linear forces folded into its velocity curve'),
    ('A20', 'Gravity point attractor -> constant LinearForce towards the attractor'),
    ('A21', 'Randomiser -> DirectionRandomiser'),
    ('A22', 'TextureAnimator / texture_coords -> SequenceFrame + texcoord_billboard (stacks = rows, slices = columns)'),
    ('A23', 'RibbonTrail renderer -> Fairy ribbon renderer (trail length/colour_change approximated)'),
    ('A24', 'Entity/Customize renderer -> Fairy mesh renderer with the GL effect mesh converted to .mesh'),
    ('A25', 'uv_mask -> TwoTex template (mask as the second texture)'),
    ('A26', 'disslove* -> Dissolve affector + Mtl_Particle_Dissolve (clip = 1 - disslove_fector)'),
    ('A27', 'soft particles, distortion, alpha_ref, draw_depth, uv ranges / clamps / flow ignored'),
    ('A28', 'observer / event handler logic dropped (OnTime + DoEnableComponent kept as start delays)'),
    ('A29', 'affector without Fairy equivalent skipped'),
    ('A30', 'renderer without Fairy equivalent: technique skipped'),
    ('A31', 'GL .mtl shader constants ignored; first texture of the .mtl used'),
    ('A32', 'billboard oriented_shape -> oriented_self; common_*_local flags ignored'),
    ('A33', 'BaseSpeed affector -> Movement start velocity box (axis ranges)'),
    ('A34', 'particle orientation quaternion -> element Orientation (mesh particles, local space)'),
    ('A35', 'missing texture -> 8x8 white placeholder'),
])

MAPPING_DOC = r"""
| PU (GL .pu) | Fairy | Exactness |
|---|---|---|
| system (scale, scale_velocity, scale_time, start_delay) | effect `gl_<name>`; lengths x scale.x*100 (cm), speeds x scale_velocity*100 | exact units |
| technique | one particle system per visual emitter (A01) + one `element Particle`; technique `position` -> element `Position` | exact |
| technique visual_particle_quota / default_particle_* | `quota` (per split, capped by estimate) / `particle_width`, `particle_height` | exact |
| technique material (.mtl) + alpha_blend | `material <sys>_m<i> : Mtl_Particle[_ColorX2/X4]`, `set_texture_alias <baseTexture>`; add -> `scene_blend src_alpha one`, alpha_blend/opacity -> `alpha_blend`, modulate -> `modulate`; `depth_write off` | exact blend, A31 |
| technique uv_mask / u_rate,v_rate / u_flip,v_flip / double_render | Mtl_Particle_TwoTex[_Tex1_ColorX2/X4] + `<scrollTex>` (A25) / `scroll_anim` / texture_unit `scale -1` / `cull_hardware none` | approx / exact |
| technique disslove* | Mtl_Particle_Dissolve + affector Dissolve (A26) | approx |
| technique glow/glow_value, colour_factor | ColorX2/ColorX4 template (A15) | approx |
| renderer Billboard (billboard_type/origin/rotation_type, common_direction/up) | `renderer billboard` same keys (A32 for oriented_shape) | exact |
| renderer Billboard + texture_coords_rows/columns | `renderer texcoord_billboard` stacks/slices + SequenceFrame (A22) | exact grid |
| renderer RibbonTrail | `renderer ribbon` (A23) | approx |
| renderer Entity / Customize | `renderer mesh` + converted .mesh (A24) | approx (static mesh) |
| renderer Beam / Decal / Light / PBREntity / Sphere | skipped (A30) | - |
| emitter Point / Box / Cylinder / Circle / SphereSurface / Hemisphere / MeshSurface / Line / Position | Point / Box / Cylinder or Ring / Ring / HollowEllipsoid / HollowEllipsoid (A10) / Box (A11) / Box (A12) / Points (A12) | exact..approx |
| emitter emission_rate, time_to_live, velocity, angle, duration, repeat_delay (fixed or dyn_random) | same keys (`*_min/_max` for ranges); curves -> mean (A13) | exact / A13 |
| emitter direction (PU default +Y; Ogre default +X) | always written; shape axis frame via Ogre AreaEmitter axes; else Movement (A08) | exact / A08 |
| emitter colour, start/end_colour_range | `colour_range_start/end` (or baked into ColourFading) | exact |
| emitter all_particle_dimensions / particle_width,height | size or ScaleInterpolator width/height ranges | exact (SEM) |
| emitter force_emission | burst (A05) | approx |
| emitter emitter_delay, OnTime+DoEnableComponent | element `StartTime` | exact |
| emitter auto_direction | RevoluMove radial (A06) or 180 degree cone (A07) | approx |
| emitter emits emitter/technique/system | A02 / A03 / A04 | approx |
| affector Colour (time_colour, colour_operation, colour_factor) | ColourFading colour0..5/time0..5 (A14) | approx (>6 keys) |
| affector Scale (xyz/x/y/z_scale) | ScaleInterpolator constant_scale (fixed rate) or scale0..5 (A16) | exact / approx |
| affector TextureRotator (rotation, rotation_speed) | Rotator rotation_range_*, rotation_speed_range_* (deg) | exact |
| affector LinearForce | LinearForce force_vector/force_application | exact |
| affector Jet / ScaleVelocity | emitter speed factor (A17 / A18) | approx |
| affector Vortex | RevoluMove (A19) | approx |
| affector Gravity | LinearForce (A20) | approx |
| affector Randomiser | DirectionRandomiser (A21) | approx |
| affector TextureAnimator | SequenceFrame (A22) | exact frames, approx timing |
| affector PlaneCollider | DeflectorPlane | approx |
| affector GeometryRotator | MeshRotator (mesh particles) | approx |
| affector BaseSpeed | Movement start velocity (A33) | approx |
| affector Align / BoxCollider / SphereCollider / PathFollower / SineForce / ForceField / CollisionAvoidance / Line / Polar | skipped (A29) | - |
| observer / handler / behaviour / extern | dropped (A28) except OnTime + DoEnableComponent | - |
"""

# ---------------------------------------------------------------- Fairy schema (engine ParameterDefs, CY-Source)
EMITTER_BASE = {'angle', 'colour', 'colour_range_start', 'colour_range_end', 'direction', 'emission_rate', 'position',
                'velocity', 'velocity_min', 'velocity_max', 'time_to_live', 'time_to_live_min', 'time_to_live_max',
                'duration', 'duration_min', 'duration_max', 'repeat_delay', 'repeat_delay_min', 'repeat_delay_max'}
AREA = {'width', 'height', 'depth'}
STAGES = lambda *names: {'%s%d' % (n, i) for n in names for i in range(6)}
SCHEMA = {
    'system': {'quota', 'material', 'particle_width', 'particle_height', 'cull_each', 'renderer', 'sorted',
               'local_space', 'iteration_interval', 'nonvisible_update_timeout'},
    'renderer:billboard': {'billboard_type', 'billboard_origin', 'billboard_rotation_type', 'common_direction',
                           'common_up_vector', 'point_rendering', 'accurate_facing', 'speed_relatived_size_factor'},
    'renderer:texcoord_billboard': {'billboard_type', 'billboard_origin', 'billboard_rotation_type', 'common_direction',
                                    'common_up_vector', 'point_rendering', 'accurate_facing',
                                    'speed_relatived_size_factor', 'stacks', 'slices', 'repeat_times'},
    'renderer:mesh': {'mesh_name', 'orientation_type', 'common_direction', 'common_up_vector', 'local_rotation',
                      'local_position'},
    'renderer:ribbon': {'head_alpha', 'tail_alpha', 'head_width_scale', 'tail_width_scale', 'element_count'},
    'emitter:Point': EMITTER_BASE,
    'emitter:Box': EMITTER_BASE | AREA,
    'emitter:Ellipsoid': EMITTER_BASE | AREA,
    'emitter:Cylinder': EMITTER_BASE | AREA,
    'emitter:Ring': EMITTER_BASE | AREA | {'inner_width', 'inner_height'},
    'emitter:HollowEllipsoid': EMITTER_BASE | AREA | {'inner_width', 'inner_height', 'inner_depth'},
    'emitter:PolarEmitter': EMITTER_BASE | {'radius_start', 'radius_step', 'radius_end', 'theta_start', 'theta_step',
                                            'theta_end', 'phi_start', 'phi_step', 'phi_end', 'use_polar_step',
                                            'flip_yz_axis', 'reset_radius_count', 'reset_radius'},
    'affector:ColourFading': STAGES('colour', 'time') | {'repeat_times', 'opacity', 'fade_in_time', 'fade_out_time'},
    'affector:ScaleInterpolator': STAGES('scale', 'time') | {'uniform_size', 'width_range_start', 'width_range_end',
                                                            'height_range_start', 'height_range_end',
                                                            'use_constant_scale', 'constant_scale',
                                                            'use_interpolated_scale', 'repeat_times'},
    'affector:Rotator': {'rotation_speed_range_start', 'rotation_speed_range_end', 'rotation_range_start',
                         'rotation_range_end'},
    'affector:Movement': {'use_start_velocity', 'start_velocity_min', 'start_velocity_max', 'acceleration',
                          'velocity_loss_min', 'velocity_loss_max', 'randomness_min', 'randomness_max',
                          'use_speed_factor', 'repeat_times'},
    'affector:Revolution': STAGES('radius_increment_scale', 'time') | {'rotation_speed', 'rotation_axis',
                                                                      'radius_increment', 'center_offset_min',
                                                                      'center_offset_max',
                                                                      'use_radius_increment_scale', 'repeat_times'},
    'affector:RevoluMove': STAGES('radius_increment_scale', 'time', 'move_velocity_point', 'move_time') |
    {'rotation_speed', 'rotation_axis', 'radius_increment', 'center_offset_min', 'center_offset_max',
     'use_radius_increment_scale', 'repeat_times', 'move_velocity', 'move_repeattimes', 'move_usevariablevelocity'},
    'affector:LinearForce': {'force_vector', 'force_application'},
    'affector:DirectionRandomiser': {'randomness', 'scope', 'keep_velocity'},
    'affector:DeflectorPlane': {'plane_point', 'plane_normal', 'bounce'},
    'affector:SequenceFrame': {'play_mode', 'stacks', 'slices', 'repeat_times', 'pingpang', 'start_range', 'loop',
                               'head_and_tail', 'play_times', 'baned_frames'},
    'affector:Dissolve': STAGES('time', 'clip') | {'colora', 'colorb', 'params', 'uv_repeat', 'soft_edge_width'},
    'affector:MeshRotator': {'%s_rotation_%s_%s' % (a, k, e) for a in ('yaw', 'pitch', 'roll')
                             for k in ('speed_range', 'range') for e in ('start', 'end')},
    'element:Particle': {'CreateLevel', 'StartTime', 'LifeTime', 'Position', 'Orientation', 'ParentSpaceLock',
                         'ParticleSystem', 'ParEffectName', 'ColEffectName', 'use_particle_effect',
                         'use_particle_collision', 'use_energy_wave', 'legacy_pos_for_sub_effect',
                         'pass_rotation_to_sub_effect'},
    'effect': {'LifeTime', 'use_scale'},
}
TEMPLATES = {'Mtl_Particle', 'Mtl_Particle_ColorX2', 'Mtl_Particle_ColorX4', 'Mtl_Particle_TwoTex',
             'Mtl_Particle_TwoTex_Tex1_ColorX2', 'Mtl_Particle_TwoTex_Tex1_ColorX4', 'Mtl_Particle_Dissolve',
             'Mtl_Particle_TwoTex_Dissolve'}


# ================================================================================================== helpers
def tlhash(s):
    """64-bit JPAK name hash (same algorithm as DIY tools/tlhash.py)."""
    if isinstance(s, str):
        s = s.encode('utf-8')
    M = 0xffffffff
    lo, hi = 0x4e67c6a7, 0
    for c in s:
        if c >= 128:
            c -= 256
        if 65 <= c <= 90:
            c += 32
        elif c == 0x5c:
            c = 0x2f
        hi = (hi * 0x1003f + c) & M
        lo ^= (((lo << 5) & M) + c + (lo >> 2)) & M
    return (hi << 32) | lo


def fnum(x):
    x = float(x)
    if x != x:
        x = 0.0
    if abs(x) < 5e-7:
        return '0'
    if abs(x) >= 1e7:
        return '%d' % round(x)
    s = ('%.6f' % x).rstrip('0').rstrip('.')
    return '0' if s in ('-0', '') else s


def fvec(v):
    return ' '.join(fnum(x) for x in v)


def vlen(v):
    return math.sqrt(sum(x * x for x in v))


def vnorm(v, default=(0.0, 1.0, 0.0)):
    n = vlen(v)
    return tuple(x / n for x in v) if n > 1e-9 else default


def vcross(a, b):
    return (a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0])


def vdot(a, b):
    return sum(x * y for x, y in zip(a, b))


def vadd(a, b):
    return tuple(x + y for x, y in zip(a, b))


def vmul(a, k):
    return tuple(x * k for x in a)


def ogre_perpendicular(d):
    p = vcross(d, (1.0, 0.0, 0.0))
    if vdot(p, p) < 1e-12:
        p = vcross(d, (0.0, 1.0, 0.0))
    return vnorm(p)


def area_axes(d):
    """Ogre AreaEmitter axes for direction d: (left -> width, up -> height, d -> depth)."""
    d = vnorm(d)
    up = ogre_perpendicular(d)
    return vnorm(vcross(up, d)), up, d


def parallel(a, b, tol=0.999):
    return abs(vdot(vnorm(a), vnorm(b))) >= tol


def sanitize(s):
    s = re.sub(r'[^0-9A-Za-z_]+', '_', s).strip('_').lower()
    return s or 'x'


def short_stem(path):
    st = os.path.splitext(os.path.basename(path))[0]
    st = re.sub(r'^w1351_', '', st, flags=re.I)
    return sanitize(st)


# ---------------------------------------------------------------- PU dynamic attributes
class Dyn:
    __slots__ = ('kind', 'a', 'b', 'pts', 'spline', 'base', 'amp', 'freq', 'phase', 'square')

    def __init__(self, kind):
        self.kind = kind
        self.a = self.b = self.base = self.amp = self.freq = self.phase = 0.0
        self.pts = []
        self.spline = self.square = False

    @staticmethod
    def fixed(v):
        d = Dyn('fixed')
        d.a = d.b = float(v)
        return d

    def lo(self):
        if self.kind in ('fixed', 'random'):
            return min(self.a, self.b)
        if self.kind == 'curve':
            return min(v for _, v in self.pts) if self.pts else 0.0
        return self.base - abs(self.amp)

    def hi(self):
        if self.kind in ('fixed', 'random'):
            return max(self.a, self.b)
        if self.kind == 'curve':
            return max(v for _, v in self.pts) if self.pts else 0.0
        return self.base + abs(self.amp)

    def at(self, t):
        if self.kind in ('fixed', 'random'):
            return (self.a + self.b) * 0.5
        if self.kind == 'osc':
            s = math.sin(2 * math.pi * (self.freq * t + self.phase))
            if self.square:
                s = 1.0 if s >= 0 else -1.0
            return self.base + self.amp * s
        p = self.pts
        if not p:
            return 0.0
        if t <= p[0][0]:
            return p[0][1]
        if t >= p[-1][0]:
            return p[-1][1]
        for i in range(len(p) - 1):
            (x0, y0), (x1, y1) = p[i], p[i + 1]
            if x0 <= t <= x1:
                f = (t - x0) / (x1 - x0) if x1 > x0 else 0.0
                if not self.spline:
                    return y0 + (y1 - y0) * f
                ym = p[i - 1][1] if i > 0 else y0
                yp = p[i + 2][1] if i + 2 < len(p) else y1
                f2, f3 = f * f, f * f * f          # Catmull-Rom (Ogre SimpleSpline equivalent)
                return 0.5 * ((2 * y0) + (-ym + y1) * f + (2 * ym - 5 * y0 + 4 * y1 - yp) * f2 +
                              (-ym + 3 * y0 - 3 * y1 + yp) * f3)
        return p[-1][1]

    def mean(self, t0=0.0, t1=1.0, n=48):
        if self.kind in ('fixed', 'random'):
            return (self.a + self.b) * 0.5
        if self.kind == 'osc':
            return self.base
        if self.kind == 'curve' and self.pts:
            t0, t1 = self.pts[0][0], max(self.pts[-1][0], self.pts[0][0] + 1e-6)
        return sum(self.at(t0 + (t1 - t0) * (i + 0.5) / n) for i in range(n)) / n

    def varies(self):
        return self.kind != 'fixed' and abs(self.hi() - self.lo()) > 1e-6


def dyn_from_node(pu, c):
    d = Dyn('fixed')
    if c.type == 'dyn_random':
        d.kind = 'random'
        mn, mx = c.prop('min'), c.prop('max')
        d.a = mn.val[0] if mn else 0.0
        d.b = mx.val[0] if mx else 0.0
    elif c.type in ('dyn_curved_linear', 'dyn_curved_spline'):
        d.kind = 'curve'
        d.spline = c.type == 'dyn_curved_spline'
        d.pts = sorted((p.val[0], p.val[1]) for p in c.props if p.key == 'control_point')
    elif c.type == 'dyn_oscillate':
        d.kind = 'osc'
        g = lambda k, dv: c.prop(k).val[0] if c.prop(k) else dv
        d.freq, d.phase, d.base, d.amp = g('oscillate_frequency', 1.0), g('oscillate_phase', 0.0), \
            g('oscillate_base', 0.0), g('oscillate_amplitude', 1.0)
        ot = c.prop('oscillate_type')
        d.square = ot is not None and pu.value(ot) == 'square'
    return d


def attr(pu, n, key, default=None):
    p = n.prop(key)
    if p is not None and p.vt in (1, 2, 3, 4):
        return Dyn.fixed(p.val[0])
    for c in n.children:
        if c.cls == key and c.type in DYN_TYPES:
            return dyn_from_node(pu, c)
    return Dyn.fixed(default) if default is not None else None


def pval(pu, n, key, default=None):
    p = n.prop(key)
    return pu.value(p) if p is not None else default


def pbool(pu, n, key, default=False):
    p = n.prop(key)
    return bool(p.val[0]) if p is not None else default


# ================================================================================================== GL assets
class GLAssets:
    def __init__(self, gl_root=GL_ROOT):
        self.gl_root = gl_root
        self.roots = [os.path.join(gl_root, 'new_20260905', 'erlang'), os.path.join(gl_root, 'new_20260905'),
                      os.path.join(gl_root, 'files')]
        self.hash_dirs = [os.path.join(gl_root, 'new_20260905', '_byhash'), os.path.join(gl_root, '_byhash')]
        self._hash = None
        self._base = None
        self._mtl = {}

    def _hash_index(self):
        if self._hash is None:
            self._hash = {}
            for d in self.hash_dirs:
                if os.path.isdir(d):
                    for f in os.listdir(d):
                        self._hash.setdefault(f.split('.')[0].lower(), os.path.join(d, f))
        return self._hash

    def find(self, rel):
        rel = rel.replace('\\', '/').lstrip('/')
        for r in self.roots:
            p = os.path.join(r, *rel.split('/'))
            if os.path.isfile(p):
                return p
        return self._hash_index().get('%016x' % tlhash(rel))

    def _base_index(self):
        if self._base is None:
            self._base = {}
            for r in self.roots:
                top = os.path.join(r, 'convert', 'dxt', 'data', 'effect')
                for dp, _, fs in os.walk(top):
                    for f in fs:
                        self._base.setdefault(f.lower(), os.path.join(dp, f))
        return self._base

    def find_texture(self, rel):
        rel = rel.replace('\\', '/').lstrip('/')
        for cand in ('convert/dxt/' + rel, rel):
            p = self.find(cand)
            if p:
                return p
        return self._base_index().get(posixpath.basename(rel).lower())

    def mtl_textures(self, rel):
        """texture paths referenced by a GL .mtl (JBCF string pool), relative to the data root."""
        if rel in self._mtl:
            return self._mtl[rel]
        out = []
        p = self.find(rel)
        if p:
            pool = jbcf_pool(open(p, 'rb').read()) or []
            base = posixpath.dirname(rel.replace('\\', '/'))
            for s in pool:
                t = s.decode('utf-8', 'replace')
                if t.lower().endswith(('.tga', '.png', '.dds', '.jpg', '.bmp')):
                    out.append(t if '/' in t else posixpath.join(base, t))
        self._mtl[rel] = out
        return out


def jbcf_pool(d):
    """String pool of a JBCF file (layout from DIY tools/jbcf_strings.py)."""
    if d[:4] != b'JBCF' or len(d) < 0x20:
        return None
    sec = struct.unpack_from('<I', d, 0x14)[0] + 0x18
    for adj in (0, 4):
        o = sec + adj
        if o + 16 > len(d):
            return None
        tag, psize, zero, cnt = struct.unpack_from('<IIII', d, o)
        if tag == 0x55 and cnt < 1000000:
            pos = o + 16
            lens = [struct.unpack_from('<I', d, pos + 8 * i)[0] for i in range(cnt)]
            pos += 8 * cnt
            out = []
            for ln in lens:
                out.append(d[pos:pos + ln])
                pos += ln
            return out
    return None


def jmt_header(path):
    with open(path, 'rb') as f:
        h = f.read(28)
    if h[:4] != b'JMT1':
        return None
    w, hh = struct.unpack_from('<HH', h, 16)
    return h[4:8].decode('latin1'), w, hh


def jmt_image(data):
    """JMT1 texture container -> PIL RGBA image (decoder logic of DIY tools/jmt2png.py)."""
    from PIL import Image
    if data[:4] != b'JMT1':
        raise ValueError('not a JMT1 texture')
    fmt = data[4:8]
    glfmt, _ = struct.unpack_from('<II', data, 8)
    w, h = struct.unpack_from('<HH', data, 16)
    _, plen = struct.unpack_from('<II', data, 20)
    payload = data[28:28 + plen]
    if fmt in (b'COLW', b'COLR') and payload[:4] == b'RIFF':
        im = Image.open(io.BytesIO(payload))
        im.load()
    elif fmt == b'COLR':
        if len(payload) == (w + 2) * (h + 2) * 4:
            im = Image.frombytes('RGBA', (w + 2, h + 2), payload).crop((1, 1, w + 1, h + 1))
        else:
            off = len(payload) - w * h * 4 if len(payload) >= w * h * 4 else 0
            im = Image.frombytes('RGBA', (w, h), payload[off:off + w * h * 4])
    elif fmt in (b'DXT1', b'DXT3', b'DXT5'):
        n = {0x83F0: 1, 0x83F1: 1, 0x83F2: 2, 0x83F3: 3}.get(glfmt, {b'DXT1': 1, b'DXT3': 2, b'DXT5': 3}[fmt])
        need = max(1, (w + 3) // 4) * max(1, (h + 3) // 4) * (8 if n == 1 else 16)
        im = Image.frombytes('RGBA', (w, h), payload[:need], 'bcn', n)
    elif fmt == b'RGBA':
        im = Image.frombytes('RGBA', (w, h), payload[:w * h * 4])
    elif fmt == b'ALI8':
        im = Image.frombytes('L', (w, h), payload[:w * h])
    else:
        raise ValueError('unsupported JMT1 format %r' % fmt)
    return im.convert('RGBA')


def dds_a8r8g8b8(im):
    """legacy uncompressed A8R8G8B8 DDS without colour-space metadata (texconv input, as upscale_pack.py)."""
    w, h = im.size
    hdr = struct.pack('<4sIIIIIII44x', b'DDS ', 124, 0x100F, h, w, w * 4, 0, 0)
    pf = struct.pack('<IIIIIIII', 32, 0x41, 0, 32, 0x00FF0000, 0x0000FF00, 0x000000FF, 0xFF000000)
    caps = struct.pack('<IIIII', 0x1000, 0, 0, 0, 0)
    r, g, b, a = im.split()
    from PIL import Image
    bgra = Image.merge('RGBA', (b, g, r, a)).tobytes()
    return hdr + pf + caps + bgra


class TexturePool:
    """GL JMT1 -> DDS (DXT1 without alpha, DXT5 with alpha, full mip chain, texconv x64 -dx9)."""

    def __init__(self, assets, cache_dir):
        self.assets = assets
        self.cache_dir = cache_dir
        os.makedirs(cache_dir, exist_ok=True)
        self.info = {}          # rel -> dict(name, file, src, w, h, fmt) or None

    def get(self, rel):
        if rel in self.info:
            return self.info[rel]
        src = self.assets.find_texture(rel)
        res = None
        if src:
            try:
                res = self._convert(rel, src)
            except Exception as e:           # noqa: BLE001 - recorded in the manifest
                res = None
                sys.stderr.write('texture %s: %s\n' % (rel, e))
        self.info[rel] = res
        return res

    def _convert(self, rel, src):
        from PIL import Image
        name = 'gl_' + sanitize(os.path.splitext(posixpath.basename(rel))[0]) + '.dds'
        out = os.path.join(self.cache_dir, name)
        meta = out + '.json'
        if os.path.isfile(out) and os.path.isfile(meta):
            m = json.load(open(meta, encoding='utf-8'))
            if m.get('src') == src:
                return m
        im = jmt_image(open(src, 'rb').read())
        a_lo, a_hi = im.getchannel('A').getextrema()
        if a_hi == 0:                                   # alpha channel carries nothing -> opaque
            im.putalpha(255)
            a_lo = 255
        w, h = im.size
        w4, h4 = (w + 3) // 4 * 4, (h + 3) // 4 * 4
        if (w4, h4) != (w, h):
            im = im.resize((w4, h4), Image.LANCZOS)
        enc = 'BC3_UNORM' if a_lo < 255 else 'BC1_UNORM'
        tmp = os.path.join(self.cache_dir, '_in')
        os.makedirs(tmp, exist_ok=True)
        tin = os.path.join(tmp, name)
        with open(tin, 'wb') as f:
            f.write(dds_a8r8g8b8(im))
        r = subprocess.run([TEXCONV, '-nologo', '-y', '-nogpu', '--single-proc', '-dx9', '-m', '0', '-f', enc,
                            '-o', self.cache_dir, tin], capture_output=True, text=True)
        os.remove(tin)
        if r.returncode != 0 or not os.path.isfile(out):
            raise RuntimeError('texconv rc=%s %s' % (r.returncode, (r.stdout + r.stderr)[-300:]))
        m = dict(name=name, file=out, src=src, rel=rel, w=w, h=h, fmt='DXT5' if enc == 'BC3_UNORM' else 'DXT1')
        json.dump(m, open(meta, 'w', encoding='utf-8'))
        return m

    def white(self):
        from PIL import Image
        name = 'gl_white.dds'
        out = os.path.join(self.cache_dir, name)
        if not os.path.isfile(out):
            with open(out, 'wb') as f:
                f.write(dds_a8r8g8b8(Image.new('RGBA', (8, 8), (255, 255, 255, 255))))
        return dict(name=name, file=out, src='', rel='(placeholder)', w=8, h=8, fmt='A8R8G8B8')


# ------------------------------------------------------------------------------------------ effect meshes
def convert_gl_mesh(src, out_path, material):
    """GL static effect mesh (glmesh.py formats 274/530/594) -> Fairy .mesh [MeshSerializer_v1.40] (x100, V flip)."""
    if GLMESH_DIR not in sys.path:
        sys.path.insert(0, GLMESH_DIR)
    if OGRE_IO_DIR not in sys.path:
        sys.path.insert(0, OGRE_IO_DIR)
    from glmesh import GLMesh
    from ogre_io import write_mesh
    m = GLMesh(src)
    pos = [(x * 100.0, y * 100.0, z * 100.0) for x, y, z in m.pos]
    nrm = [vnorm(n, (0.0, 1.0, 0.0)) for n in m.nrm]
    uv = [(u, 1.0 - v) for u, v in m.uv0]
    vb = bytearray()
    for i in range(m.nv):
        vb += struct.pack('<8f', *(pos[i] + nrm[i] + uv[i]))
    idx = bytearray()
    for a, b, c in m.tris:
        idx += struct.pack('<3H', a, b, c)
    lo = [min(p[k] for p in pos) for k in range(3)]
    hi = [max(p[k] for p in pos) for k in range(3)]
    radius = max(vlen(p) for p in pos) if pos else 0.0
    geo = dict(verts=m.nv, decl=[(0, 2, 1, 0, 0), (0, 2, 4, 12, 0), (0, 1, 7, 24, 0)], buffers=[[0, 32, bytes(vb)]])
    sub = dict(material=material.encode('ascii'), shared=False, idx32=False, index_count=len(m.tris) * 3,
               indices=bytes(idx), operation=None, geometry=geo, bone_assign=[], alias=[])
    mesh = dict(version=b'[MeshSerializer_v1.40]', skel_anim=False, skeleton=None, shared=None, submeshes=[sub],
                bounds=tuple(lo + hi + [radius]), name_table=[], mesh_ba=[], lod=None, tail=b'')
    data = write_mesh(mesh)
    with open(out_path, 'wb') as f:
        f.write(data)
    return dict(nv=m.nv, nt=m.nt, bbox=[lo, hi], size=len(data))


# ================================================================================================== model
class Block:
    """Fairy script block: head line, ordered (key, value) lines and sub blocks."""

    def __init__(self, kind, typ=None):
        self.kind, self.typ = kind, typ
        self.kv = []
        self.subs = []

    def set(self, k, v):
        for i, (kk, _) in enumerate(self.kv):
            if kk == k:
                self.kv[i] = (k, v)
                return self
        self.kv.append((k, v))
        return self

    def get(self, k):
        for kk, v in self.kv:
            if kk == k:
                return v
        return None


class Effect:
    def __init__(self, name):
        self.name = name
        self.elements = []        # dict(ps, start, pos, orient)
        self.lifetime = 0.0
        self.loop = True


class Converter:
    def __init__(self, assets, out_root=DEFAULT_OUT, prefix='gl_', tex_cache=None):
        self.assets = assets
        self.out_root = out_root
        self.prefix = prefix
        self.tex = TexturePool(assets, tex_cache or os.path.join(out_root, '_texcache'))

    # --------------------------------------------------------------------- per effect
    def convert(self, pu_path):
        pu = jbpu.PUFile.load(pu_path)
        ename = self.prefix + short_stem(pu_path)
        st = State(self, pu, pu_path, ename)
        st.run()
        return st


class State:
    """Conversion of one .pu into one Fairy effect."""

    def __init__(self, conv, pu, path, ename):
        self.c, self.pu, self.path, self.ename = conv, pu, path, ename
        self.notes = []
        self.systems = []         # (name, Block)
        self.materials = []       # (name, parent, lines)
        self.textures = {}        # dds name -> info
        self.meshes = {}          # file -> info
        self.effect = Effect(ename)
        self.stats = collections.Counter()

    def note(self, code, where, detail=''):
        key = (code, where, detail)
        if key not in self.notes:
            self.notes.append(key)

    # --------------------------------------------------------------------------------- driver
    def run(self):
        pu, S = self.pu, self.pu.root
        sc = S.prop('scale')
        self.scl = tuple(sc.val) if sc else (1.0, 1.0, 1.0)
        self.L = self.scl[0] * 100.0                                   # authoring length -> Fairy cm
        sv = S.prop('scale_velocity')
        self.V = (sv.val[0] if sv else 1.0) * 100.0                     # authoring speed -> Fairy cm/s
        self.T = max(1e-3, pval(pu, S, 'scale_time', 1.0))            # simulation speed factor
        self.delay0 = pval(pu, S, 'start_delay', 0.0) or 0.0
        self.local_all = pbool(pu, S, 'keep_local', False)
        techs = S.child('technique')
        self.enable_at = self._events(techs)
        self.byname = {t.name: t for t in techs if t.name}
        spawned_tech, spawned_emit = {}, {}
        for T in techs:
            for E in T.child('emitter'):
                em = E.prop('emits')
                if em is None:
                    continue
                kind, target = pu.value(em)
                if kind == 'technique_particle':
                    spawned_tech.setdefault(target, []).append((T, E))
                elif kind == 'emitter_particle':
                    spawned_emit[(id(T), target)] = E
                else:
                    self.note('A04', self._w(T, E), target)
        self.spawned_emit = spawned_emit
        for ti, T in enumerate(techs):
            if T.name in spawned_tech:
                continue
            self.technique(ti, T, None)
        for tname, spawners in spawned_tech.items():
            T = self.byname.get(tname)
            if T is None:
                self.note('A03', tname, 'emitted technique not found')
                continue
            for k, sp in enumerate(spawners):
                self.technique(techs.index(T), T, sp, k)
        self._finish_effect()

    def _w(self, T, E=None, A=None):
        s = self.ename + '/' + (T.name or 'technique')
        if E is not None:
            s += '/' + (E.name or E.type)
        if A is not None:
            s += '/' + (A.name or A.type)
        return s

    def _events(self, techs):
        """OnTime observers with DoEnableComponent handlers -> {(component kind, name): time}."""
        out = {}
        for T in techs:
            for O in T.child('observer'):
                if O.type != 'OnTime':
                    self.note('A28', self._w(T), 'observer %s' % O.type)
                    continue
                cmp = O.prop('on_time')
                t = self.pu.value(cmp)[1] if cmp is not None else 0.0
                for H in O.child('handler'):
                    ec = H.prop('enable_component')
                    if H.type == 'DoEnableComponent' and ec is not None:
                        kind, name, on = self.pu.value(ec)
                        if on:
                            out[(kind, name)] = max(0.0, float(t))
                    else:
                        self.note('A28', self._w(T), 'handler %s' % H.type)
            for B in T.child('behaviour') + T.child('extern'):
                self.note('A28', self._w(T), '%s %s' % (B.cls, B.type))
        return out

    # ------------------------------------------------------------------------------ technique
    def technique(self, ti, T, spawn, spawn_idx=0):
        pu = self.pu
        where = self._w(T)
        t_en = self.enable_at.get(('technique_component', T.name))
        if not pbool(pu, T, 'enabled', True) and t_en is None:
            self.note('A28', where, 'disabled technique skipped')
            return
        R = (T.child('renderer') or [None])[0]
        rtype = R.type if R is not None else 'Billboard'
        if rtype not in ('Billboard', 'RibbonTrail', 'Entity', 'Customize'):
            self.note('A30', where, 'renderer %s' % rtype)
            return
        emitters = T.child('emitter')
        affectors = T.child('affector')
        visual = []
        for ei, E in enumerate(emitters):
            if E.prop('emits') is not None:
                continue
            e_en = self.enable_at.get(('emitter_component', E.name))
            if not pbool(pu, E, 'enabled', True) and e_en is None:
                self.note('A28', self._w(T, E), 'disabled emitter skipped')
                continue
            if E.type == 'Slave':
                self.note('A29', self._w(T, E), 'Slave emitter')
                continue
            visual.append((ei, E, (e_en or 0.0) + (t_en or 0.0)))
        if not visual:
            self.note('A01', where, 'no visual emitter')
            return
        if len(visual) > 1:
            self.note('A01', where, '%d emitters' % len(visual))
        mesh = None
        if rtype in ('Entity', 'Customize'):
            mesh = self._mesh(T, R)
            if mesh is None:
                return
        plans = []
        for ei, E, t0 in visual:
            affs = [A for A in affectors if self._affects(A, E)]
            plans.append((ei, E, t0, affs, self._colour_plan(T, E, affs)))
        mult = self._brightness(T, [p[4] for p in plans])
        mat = self._material(ti, T, R, mult, mesh is not None)
        for ei, E, t0, affs, cplan in plans:
            self._system(ti, T, R, rtype, ei, E, t0, affs, cplan, mult, mat, mesh, spawn, spawn_idx)

    def _affects(self, A, E):
        ex = A.prop('exclude_emitter')
        if ex is not None and E.name in self.pu.value(ex):
            return False
        a_en = self.enable_at.get(('affector_component', A.name))
        return pbool(self.pu, A, 'enabled', True) or a_en is not None

    # ------------------------------------------------------------------------------- colours
    def _colour_plan(self, T, E, affs):
        pu = self.pu
        c0 = pval(pu, E, 'colour')
        cs, ce = pval(pu, E, 'start_colour_range'), pval(pu, E, 'end_colour_range')
        if cs is not None and ce is not None:
            emit = (list(cs), list(ce))
        elif c0 is not None:
            emit = (list(c0), list(c0))
        else:
            emit = ([1.0, 1.0, 1.0, 1.0], [1.0, 1.0, 1.0, 1.0])
        col = [A for A in affs if A.type == 'Colour']
        if not col:
            return ('emitter', emit)
        A = col[0]
        if len(col) > 1:
            self.note('A14', self._w(T, E), '%d Colour affectors, first used' % len(col))
        keys = [tuple(p.val) for p in A.props if p.key == 'time_colour']
        if not keys:
            return ('emitter', emit)
        op = pval(pu, A, 'colour_operation', 'set')
        fac = attr(pu, A, 'colour_factor')
        f = fac.mean() if fac else 1.0
        mean = [(a + b) * 0.5 for a, b in zip(*emit)]
        out = []
        for t, r, g, b, a in sorted(keys, key=lambda k: k[0]):
            c = [r, g, b, a]
            if op == 'multiply':
                c = [c[i] * mean[i] for i in range(4)]
            c = [c[0] * f, c[1] * f, c[2] * f, c[3]]
            out.append((min(1.0, max(0.0, t)), c))
        if op == 'multiply' and emit[0] != emit[1]:
            self.note('A14', self._w(T, E, A), 'emitter colour range baked as its mean')
        stages = reduce_stages(out, 6)
        if len(stages) < len(out):
            self.note('A14', self._w(T, E, A), '%d keys -> %d stages' % (len(out), len(stages)))
        return ('fading', stages)

    def _brightness(self, T, plans):
        pu = self.pu
        mx = 0.0
        for kind, data in plans:
            if kind == 'fading':
                mx = max([mx] + [max(c[:3]) for _, c in data])
            else:
                mx = max([mx] + [max(c[:3]) for c in data])
        if pbool(pu, T, 'glow') and (pval(pu, T, 'glow_value', 0.0) or 0.0) >= 1.5:
            mx *= SEM['glow_boost']
            self._glow = True
        else:
            self._glow = False
        if mx <= 1.05:
            return 1
        self.note('A15', self._w(T), 'peak colour %.2f' % mx)
        return 2 if mx <= 2.1 else 4

    # ------------------------------------------------------------------------------ material
    def _material(self, ti, T, R, mult, is_mesh):
        pu = self.pu
        name = '%s_m%d' % (self.ename, ti)
        for m in self.materials:
            if m[0] == name:
                return name
        where = self._w(T)
        texs = []
        mtl = pval(pu, T, 'material')
        if mtl:
            texs = self.c.assets.mtl_textures(mtl)
            self.note('A31', where, posixpath.basename(mtl))
        tex_direct = pval(pu, T, 'texture')
        if tex_direct:
            texs = [tex_direct] + texs
        base = self._tex(texs[0]) if texs else None
        if base is None:
            base = self.c.tex.white()
            self.textures[base['name']] = base
            self.note('A35', where, texs[0] if texs else '(no texture)')
        mask_rel = pval(pu, T, 'uv_mask')
        mask = self._tex(self._resolve_rel(mask_rel)) if mask_rel else None
        if mask_rel:
            self.note('A25', where, posixpath.basename(mask_rel) + ('' if mask else ' (missing)'))
        diss_rel = pval(pu, T, 'disslove_texture')
        diss_f = attr(pu, T, 'disslove_fector')
        use_diss = diss_rel is not None and (pbool(pu, T, 'disslove') or (diss_f is not None and diss_f.varies()))
        diss = self._tex(self._resolve_rel(diss_rel)) if use_diss else None
        if use_diss:
            self.note('A26', where, posixpath.basename(diss_rel) + ('' if diss else ' (missing)'))
        if mask and diss:
            parent, mult = 'Mtl_Particle_TwoTex_Dissolve', 1
        elif mask:
            parent = {1: 'Mtl_Particle_TwoTex', 2: 'Mtl_Particle_TwoTex_Tex1_ColorX2',
                      4: 'Mtl_Particle_TwoTex_Tex1_ColorX4'}[mult]
        elif diss:
            parent, mult = 'Mtl_Particle_Dissolve', 1
        else:
            parent = {1: 'Mtl_Particle', 2: 'Mtl_Particle_ColorX2', 4: 'Mtl_Particle_ColorX4'}[mult]
        self._mat_mult = mult
        blend = pval(pu, T, 'alpha_blend', 'add') or 'add'
        sb = {'add': 'src_alpha one', 'alpha_blend': 'alpha_blend', 'opacity': 'alpha_blend',
              'modulate': 'modulate'}.get(blend, 'src_alpha one')
        lines = ['set_texture_alias <baseTexture> %s' % base['name']]
        if mask:
            lines.append('set_texture_alias <scrollTex> %s' % mask['name'])
        if diss:
            lines.append('set_texture_alias <dissolveTexure> %s' % diss['name'])
        pas = ['scene_blend %s' % sb, 'depth_write off']
        if pbool(pu, T, 'double_render') or is_mesh:
            pas.append('cull_hardware none')
        tu = []
        if pbool(pu, T, 'u_flip') or pbool(pu, T, 'v_flip'):
            tu.append('scale %s %s' % ('-1' if pbool(pu, T, 'u_flip') else '1', '-1' if pbool(pu, T, 'v_flip') else '1'))
        ur, vr = attr(pu, T, 'u_rate'), attr(pu, T, 'v_rate')
        if ur is not None or vr is not None:
            u = ur.mean() if ur else 0.0
            v = vr.mean() if vr else 0.0
            if is_mesh:
                v = -v                                    # the mesh V axis was flipped
            if abs(u) > 1e-6 or abs(v) > 1e-6:
                tu.append('scroll_anim %s %s' % (fnum(u), fnum(v)))
            if (ur and ur.varies()) or (vr and vr.varies()):
                self.note('A13', where, 'uv rate curve -> mean')
        for k in ('tech_soft', 'distort', 'draw_depth', 'uv_flow_out'):
            if pbool(pu, T, k):
                self.note('A27', where, k)
        self.materials.append((name, parent, lines, pas, tu))
        return name

    def _resolve_rel(self, rel):
        if rel is None:
            return None
        return rel if '/' in rel else 'data/effect/textures/' + rel

    def _tex(self, rel):
        if rel is None:
            return None
        info = self.c.tex.get(rel)
        if info is None:
            return None
        self.textures[info['name']] = info
        return info

    def _mesh(self, T, R):
        rel = pval(self.pu, R, 'mesh_name')
        where = self._w(T)
        if not rel or not rel.lower().endswith('.mesh'):
            self.note('A30', where, 'mesh renderer with %s' % rel)
            return None
        src = self.c.assets.find(rel)
        if src is None:
            self.note('A30', where, 'mesh not found %s' % rel)
            return None
        name = 'gl_' + sanitize(os.path.splitext(posixpath.basename(rel))[0]) + '.mesh'
        self.meshes[name] = dict(src=src, rel=rel)
        self.note('A24', where, posixpath.basename(rel))
        return name

    # -------------------------------------------------------------------------------- system
    def _system(self, ti, T, R, rtype, ei, E, t_enable, affs, cplan, mult, mat, mesh, spawn, spawn_idx):
        pu = self.pu
        where = self._w(T, E)
        name = '%s_%d_%d' % (self.ename, ti, ei) + ('_s%d' % spawn_idx if spawn else '')
        ps = Block('system')
        em = Block('emitter')
        extra_affs = []
        ED = SEM['emitter_defaults']
        # ---------------- size
        is_mesh = mesh is not None
        unit = (self.scl[0]) if is_mesh else self.L          # mesh renderer: particle size = mesh scale factor
        dsz = [pval(pu, T, k, SEM['default_size']) for k in ('default_particle_width', 'default_particle_height',
                                                             'default_particle_depth')]
        dims = attr(pu, E, 'all_particle_dimensions')
        pw, ph = attr(pu, E, 'particle_width'), attr(pu, E, 'particle_height')
        if SEM['dims_multiplier']:
            wm = dims or pw or Dyn.fixed(1.0)
            hm = dims or ph or Dyn.fixed(1.0)
            w_lo, w_hi = dsz[0] * wm.lo() * unit, dsz[0] * wm.hi() * unit
            h_lo, h_hi = dsz[1] * hm.lo() * unit, dsz[1] * hm.hi() * unit
        else:
            wv = dims or pw
            hv = dims or ph
            w_lo, w_hi = (wv.lo() * unit, wv.hi() * unit) if wv else (dsz[0] * unit,) * 2
            h_lo, h_hi = (hv.lo() * unit, hv.hi() * unit) if hv else (dsz[1] * unit,) * 2
        for d_ in (dims, pw, ph):
            if d_ is not None and d_.kind in ('curve', 'osc'):
                self.note('A13', where, 'particle size curve -> range')
        w_mean, h_mean = (w_lo + w_hi) * 0.5, (h_lo + h_hi) * 0.5
        # ---------------- timing
        rate = attr(pu, E, 'emission_rate', ED['emission_rate'])
        ttl = attr(pu, E, 'time_to_live', ED['time_to_live'])
        vel = attr(pu, E, 'velocity', ED['velocity'])
        ang = attr(pu, E, 'angle', ED['angle'])
        dur = attr(pu, E, 'duration', ED['duration'])
        rep = attr(pu, E, 'repeat_delay', ED['repeat_delay'])
        for key, d_ in (('emission_rate', rate), ('velocity', vel), ('time_to_live', ttl), ('angle', ang)):
            if d_.kind in ('curve', 'osc'):
                self.note('A13', where, key)
        ttl_lo, ttl_hi = max(0.01, ttl.lo()) / self.T, max(0.01, ttl.hi()) / self.T
        ttl_lo, ttl_hi = min(ttl_lo, 99999.0), min(ttl_hi, 99999.0)
        life = (ttl_lo + ttl_hi) * 0.5
        v_lo, v_hi = vel.lo() * self.V * self.T, vel.hi() * self.V * self.T
        force = pbool(pu, E, 'force_emission')
        n_rate = max(0.0, rate.mean()) * self.T
        start = self.delay0 + (pval(pu, E, 'emitter_delay', 0.0) or 0.0) / self.T + t_enable
        d_hi = dur.hi() / self.T
        r_lo, r_hi = rep.lo() / self.T, rep.hi() / self.T
        # spawned technique: re-trigger on the spawner cycle, from the spawner position
        spawn_pos = (0.0, 0.0, 0.0)
        if spawn is not None:
            ST, SE = spawn
            s_dur = attr(pu, SE, 'duration', 0.0).mean() / self.T
            s_rep = attr(pu, SE, 'repeat_delay', 0.0).mean() / self.T
            s_ttl = attr(pu, SE, 'time_to_live', ED['time_to_live']).mean() / self.T
            start += self.delay0 * 0 + (pval(pu, SE, 'emitter_delay', 0.0) or 0.0) / self.T
            spawn_pos = vmul(pval(pu, ST, 'position', (0.0, 0.0, 0.0)), self.L)
            spawn_pos = vadd(spawn_pos, vmul(pval(pu, SE, 'position', (0.0, 0.0, 0.0)), self.L))
            if s_dur > 0 or s_rep > 0:
                cycle = max(FRAME * 2, s_dur + s_rep)
                if force:
                    d_hi, r_lo, r_hi = FRAME, cycle - FRAME, cycle - FRAME
                elif d_hi <= 0:
                    d_hi = min(s_ttl, cycle)
                    r_lo = r_hi = max(0.0, cycle - d_hi)
            self.note('A03', where, 'spawned by %s' % (SE.name or SE.type))
        # ---------------- velocity modifiers (Jet / ScaleVelocity) -> speed factor
        vf = 1.0
        for A in affs:
            if A.type == 'Jet':
                a = attr(pu, A, 'acceleration', 0.0).mean() * self.T
                x = a * life
                k = (math.expm1(x) / x) if abs(x) > 1e-4 else 1.0
                vf *= min(5.0, max(0.02, k))
                self.note('A17', self._w(T, E, A), 'a=%s factor %.2f' % (fnum(a), k))
            elif A.type == 'ScaleVelocity':
                sv_ = attr(pu, A, 'velocity_scale', 0.0).mean() * self.V * self.T * self.T
                v0 = max(1e-3, (abs(v_lo) + abs(v_hi)) * 0.5)
                if sv_ < 0:
                    t_stop = min(life, v0 / -sv_)
                    dist = v0 * t_stop + 0.5 * sv_ * t_stop * t_stop
                else:
                    dist = v0 * life + 0.5 * sv_ * life * life
                k = max(0.02, min(5.0, dist / (v0 * life))) if life > 0 else 1.0
                vf *= k
                self.note('A18', self._w(T, E, A), 'factor %.2f' % k)
        v_lo, v_hi = v_lo * vf, v_hi * vf
        # ---------------- colour
        fading = cplan[0] == 'fading'
        if not fading:
            c0, c1 = cplan[1]
            k = self._glow_scale() / mult
            c0 = [min(1.0, c0[0] * k), min(1.0, c0[1] * k), min(1.0, c0[2] * k), c0[3]]
            c1 = [min(1.0, c1[0] * k), min(1.0, c1[1] * k), min(1.0, c1[2] * k), c1[3]]
            if c0 == c1:
                if c0 != [1.0, 1.0, 1.0, 1.0]:
                    em.set('colour', fvec(c0))
            else:
                em.set('colour_range_start', fvec(c0))
                em.set('colour_range_end', fvec(c1))
        # ---------------- shape and direction
        pu_dir = vnorm(pval(pu, E, 'direction', (0.0, 1.0, 0.0)))
        auto = pbool(pu, E, 'auto_direction')
        other_vel = any(A.type in ('LinearForce', 'Gravity', 'Jet', 'Vortex', 'BaseSpeed', 'Randomiser')
                        for A in affs)
        spawner = self.spawned_emit.get((id(T), E.name))
        shape_src = spawner if (spawner is not None and E.type == 'Point') else E
        if spawner is not None:
            self.note('A02', where, 'spawner %s' % (spawner.name or spawner.type))
        ftype, axis, fdims, extra_pos = self._shape(T, shape_src, where)
        if ftype == 'Position':
            positions = extra_pos
            ftype, axis, fdims, extra_pos = 'Point', None, {}, (0.0, 0.0, 0.0)
        else:
            positions = None
        radial = auto and E.type in ('SphereSurface', 'Hemisphere', 'Circle', 'Cylinder', 'MeshSurface', 'Box')
        use_move = False
        if radial:
            if not other_vel:
                extra_affs.append(('RevoluMove', [('rotation_speed', '0'), ('rotation_axis', '0 1 0'),
                                                  ('radius_increment', fnum((v_lo + v_hi) * 0.5))]))
                self.note('A06', where)
                v_lo = v_hi = 0.0
                fdir = axis or (0.0, 1.0, 0.0)
                ang_deg = 0.0
            else:
                self.note('A07', where)
                fdir = axis or (0.0, 1.0, 0.0)
                ang_deg = 180.0
        else:
            ang_deg = max(0.0, min(180.0, ang.hi()))
            if axis is None:
                if ftype == 'Box' and not self._axis_aligned(pu_dir) and not self._cubic(fdims):
                    fdir, use_move = (0.0, 0.0, 1.0), True
                else:
                    fdir = pu_dir
            elif parallel(axis, pu_dir):
                fdir = pu_dir if vdot(axis, pu_dir) > 0 else axis
                if vdot(axis, pu_dir) < 0 and ftype in ('Ring', 'Cylinder'):
                    fdir = pu_dir               # symmetric shapes: axis sign does not matter
            else:
                fdir, use_move = axis, True
        if use_move and (v_lo != 0.0 or v_hi != 0.0):
            lo_, hi_ = cone_box(pu_dir, ang_deg, v_lo, v_hi)
            extra_affs.append(('Movement', [('use_start_velocity', 'true'), ('start_velocity_min', fvec(lo_)),
                                            ('start_velocity_max', fvec(hi_))]))
            self.note('A08', where, 'direction %s' % fvec(pu_dir))
            v_lo = v_hi = 0.0
        # map PU box half extents on the Fairy area axes of fdir
        if ftype in ('Box', 'Ellipsoid') and 'pu_box' in fdims:
            bx = fdims.pop('pu_box')
            axes = area_axes(fdir)
            ext = [abs(ax[0]) * bx[0] + abs(ax[1]) * bx[1] + abs(ax[2]) * bx[2] for ax in axes]
            fdims.update(width=ext[0], height=ext[1], depth=ext[2])
        em.typ = ftype
        em.set('angle', fnum(ang_deg))
        em.set('direction', fvec(vnorm(fdir)))
        # ---------------- rate / burst / duration
        if force:
            cnt = max(1.0, n_rate)
            em.set('emission_rate', fnum(cnt / FRAME))
            em.set('duration_min', fnum(FRAME))
            em.set('duration_max', fnum(FRAME))
            if spawn is None and (d_hi > 0 or r_hi > 0):
                cycle = max(FRAME * 2, (dur.mean() / self.T) + (rep.mean() / self.T))
                em.set('repeat_delay_min', fnum(cycle - FRAME))
                em.set('repeat_delay_max', fnum(cycle - FRAME))
            elif spawn is not None and r_hi > 0:
                em.set('repeat_delay_min', fnum(r_lo))
                em.set('repeat_delay_max', fnum(r_hi))
            self.note('A05', where, '%d particles' % round(cnt))
        else:
            em.set('emission_rate', fnum(n_rate))
            if d_hi > 0:
                em.set('duration_min', fnum(dur.lo() / self.T if spawn is None else d_hi))
                em.set('duration_max', fnum(d_hi))
            if r_hi > 0:
                em.set('repeat_delay_min', fnum(r_lo))
                em.set('repeat_delay_max', fnum(r_hi))
        em.set('time_to_live_min', fnum(ttl_lo))
        em.set('time_to_live_max', fnum(ttl_hi))
        em.set('velocity_min', fnum(min(v_lo, v_hi)))
        em.set('velocity_max', fnum(max(v_lo, v_hi)))
        for k, v in fdims.items():
            em.set(k, fnum(v))
        # ---------------- quota
        t_quota = pval(pu, T, 'visual_particle_quota', SEM['quota_default'])
        if force:
            alive = max(1.0, n_rate)
        else:
            alive = n_rate * ttl_hi
            if d_hi > 0 and r_hi <= 0:
                alive = min(alive, n_rate * d_hi)
        n_em = len(positions) if positions else 1
        quota = int(max(1, min(t_quota, math.ceil(alive * n_em * 1.25) + 1)))
        # ---------------- system head
        ps.set('quota', str(quota))
        ps.set('material', mat)
        # ---------------- affectors
        affl = []
        if fading:
            k = self._glow_scale() / mult
            stages = [(t, [min(1.0, c[0] * k), min(1.0, c[1] * k), min(1.0, c[2] * k), max(0.0, min(1.0, c[3]))])
                      for t, c in cplan[1]]
            stages = pad_stages(stages, 6)
            kv = []
            for i, (t, c) in enumerate(stages):
                kv.append(('colour%d' % i, fvec(c)))
                kv.append(('time%d' % i, fnum(t)))
            affl.append(('ColourFading', kv))
        sw, sh = self._scale(T, E, affs, w_lo, w_hi, h_lo, h_hi, life, unit, where, affl)
        ps.set('particle_width', fnum(sw))
        ps.set('particle_height', fnum(sh))
        folded_force = self._forces(T, E, affs, where, affl, extra_pos)
        for A in affs:
            wa = self._w(T, E, A)
            if A.type == 'TextureRotator':
                self._rotator(A, wa, affl)
            elif A.type == 'Vortex':
                self._vortex(A, E, wa, affl, v_lo, v_hi, pu_dir, folded_force, life, radial)
            elif A.type == 'Randomiser':
                self._randomiser(A, wa, affl)
            elif A.type == 'PlaneCollider':
                n_ = vnorm(pval(pu, A, 'plane_collider_normal', (0.0, 1.0, 0.0)))
                p_ = vmul(pval(pu, A, 'position', (0.0, 0.0, 0.0)), self.L)
                affl.append(('DeflectorPlane', [('plane_point', fvec(p_)), ('plane_normal', fvec(n_)),
                                                ('bounce', fnum(pval(pu, A, 'bouncyness', 1.0) or 1.0))]))
            elif A.type == 'GeometryRotator':
                if is_mesh:
                    self._mesh_rotator(A, wa, affl)
                else:
                    self.note('A29', wa, 'GeometryRotator on billboards')
            elif A.type == 'BaseSpeed':
                self._base_speed(A, wa, extra_affs)
            elif A.type in ('Colour', 'Scale', 'Jet', 'ScaleVelocity', 'LinearForce', 'Gravity', 'TextureAnimator'):
                pass
            else:
                self.note('A29', wa, A.type)
        # ---------------- renderer
        self._renderer(T, R, rtype, E, affs, ps, affl, mesh, life, where)
        for n_, kv in extra_affs:
            affl.append((n_, kv))
        diss = self._dissolve(T, where)
        if diss:
            affl.append(diss)
        local = self.local_all or pbool(pu, T, 'keep_local') or pbool(pu, E, 'keep_local')
        orient = (1.0, 0.0, 0.0, 0.0)
        q = pval(pu, E, 'orientation')
        if q is not None and is_mesh:
            orient = (q[3], q[0], q[1], q[2])
            local = True
            self.note('A34', where)
        if local:
            ps.set('local_space', 'true')
        # ---------------- emitters (Position emitter -> several points)
        ps.subs = []
        e_pos = vmul(pval(pu, E, 'position', (0.0, 0.0, 0.0)), self.L)
        if positions:
            for p_ in positions:
                e2 = Block('emitter', em.typ)
                e2.kv = list(em.kv)
                e2.set('emission_rate', fnum(n_rate / len(positions) if not force else
                                             max(1.0, n_rate / len(positions)) / FRAME))
                e2.set('position', fvec(p_))
                ps.subs.append(e2)
            self.note('A12', where, '%d positions' % len(positions))
        else:
            if extra_pos != (0.0, 0.0, 0.0):
                em.set('position', fvec(extra_pos))
            ps.subs.append(em)
        for n_, kv in affl:
            b = Block('affector', n_)
            b.kv = kv
            ps.subs.append(b)
        self.systems.append((name, ps))
        tpos = vmul(pval(pu, T, 'position', (0.0, 0.0, 0.0)), self.L)
        self.effect.elements.append(dict(ps=name, start=start, pos=vadd(vadd(tpos, e_pos), spawn_pos),
                                         orient=orient))
        # lifetime bookkeeping (0 = looping)
        if d_hi <= 0 and not force:
            self.effect.loop = True if spawn is None else self.effect.loop
        span = start + (d_hi if d_hi > 0 else 0.0) + ttl_hi
        self.stats['systems'] += 1
        self._span_max = max(getattr(self, '_span_max', 0.0), span)
        self._loops = getattr(self, '_loops', False) or (d_hi <= 0 and not force and ttl_hi < 99999.0) or \
            r_hi > 0 or (spawn is not None) or ttl_hi >= 99999.0

    def _glow_scale(self):
        return SEM['glow_boost'] if getattr(self, '_glow', False) else 1.0

    @staticmethod
    def _axis_aligned(d):
        return max(abs(x) for x in d) > 0.999

    @staticmethod
    def _cubic(fd):
        b = fd.get('pu_box')
        return b is not None and max(b) - min(b) <= 0.05 * max(1e-6, max(b))

    # -------------------------------------------------------------------------------- shapes
    def _shape(self, T, E, where):
        """-> (fairy type, axis or None, dims dict, extra position). dims may hold 'pu_box' half extents."""
        pu, L = self.pu, self.L
        typ = E.type
        if typ == 'Point' or typ == 'Vertex':
            if typ == 'Vertex':
                self.note('A11', where, 'Vertex emitter -> Point')
            return 'Point', None, {}, (0.0, 0.0, 0.0)
        if typ == 'Box':
            g = lambda *ks: next((pval(pu, E, k) for k in ks if E.prop(k) is not None), SEM['box_default'])
            w, h, d = g('box_width', 'box_em_width'), g('box_height', 'box_em_height'), g('box_depth', 'box_em_depth')
            if pbool(pu, E, 'box_em_surface'):
                self.note('A09', where, 'box surface -> volume')
            return 'Box', None, {'pu_box': (abs(w) * L, abs(h) * L, abs(d) * L)}, (0.0, 0.0, 0.0)
        if typ == 'Cylinder':
            r = abs(pval(pu, E, 'cylinder_em_radius', SEM['radius_default'])) * L
            hh = abs(pval(pu, E, 'cylinder_em_height', SEM['radius_default'])) * L
            nrm = vnorm(pval(pu, E, 'cylinder_em_normal', (0.0, 1.0, 0.0)))
            if pbool(pu, E, 'cylinder_em_surface'):
                self.note('A09', where, 'cylinder surface -> Ring tube')
                return 'Ring', nrm, dict(width=2 * r, height=2 * r, depth=hh, inner_width=0.98,
                                         inner_height=0.98), (0.0, 0.0, 0.0)
            return 'Cylinder', nrm, dict(width=2 * r, height=2 * r, depth=hh), (0.0, 0.0, 0.0)
        if typ == 'Circle':
            r = abs(pval(pu, E, 'radius', SEM['radius_default'])) * L
            nrm = vnorm(pval(pu, E, 'normal', (0.0, 1.0, 0.0)))
            if not pbool(pu, E, 'emit_random', True) and E.prop('step') is not None:
                self.note('A09', where, 'sequential circle stepping -> random angle')
            return 'Ring', nrm, dict(width=2 * r, height=2 * r, depth=0.0, inner_width=0.98, inner_height=0.98), \
                (0.0, 0.0, 0.0)
        if typ in ('SphereSurface', 'Hemisphere'):
            r = abs(pval(pu, E, 'radius' if typ == 'SphereSurface' else 'hemisphere_em_radius',
                         SEM['radius_default'])) * L
            if typ == 'Hemisphere':
                self.note('A10', where)
            return 'HollowEllipsoid', None, dict(width=2 * r, height=2 * r, depth=2 * r, inner_width=0.98,
                                                 inner_height=0.98, inner_depth=0.98), (0.0, 0.0, 0.0)
        if typ == 'MeshSurface':
            rel = pval(pu, E, 'mesh_name')
            scale = pval(pu, E, 'mesh_surface_scale', (1.0, 1.0, 1.0))
            src = self.c.assets.find(rel) if rel else None
            half = (50.0 * L, 50.0 * L, 50.0 * L)
            ctr = (0.0, 0.0, 0.0)
            if src:
                try:
                    if GLMESH_DIR not in sys.path:
                        sys.path.insert(0, GLMESH_DIR)
                    from glmesh import GLMesh
                    lo, hi = GLMesh(src).bbox()
                    # GL mesh units are metres; mesh_surface_scale is in the system's authoring units
                    half = tuple(abs(hi[k] - lo[k]) * 0.5 * abs(scale[k]) * L for k in range(3))
                    ctr = tuple((hi[k] + lo[k]) * 0.5 * scale[k] * L for k in range(3))
                except Exception as e:     # noqa: BLE001
                    self.note('A11', where, 'mesh unreadable %s' % e)
            self.note('A11', where, posixpath.basename(rel or '?'))
            return 'Box', None, {'pu_box': tuple(2 * x for x in half)}, ctr
        if typ == 'Line':
            end = vmul(pval(pu, E, 'line_em_end', (0.0, 100.0, 0.0)), L)
            self.note('A12', where, 'Line')
            thick = max(1.0, 0.02 * vlen(end))
            return 'Box', None, {'pu_box': (max(thick, abs(end[0])), max(thick, abs(end[1])),
                                            max(thick, abs(end[2])))}, vmul(end, 0.5)
        if typ == 'Position':
            pts = [vmul(p.val, L) for p in E.props if p.key == 'add_position']
            return 'Position', None, {}, pts or [(0.0, 0.0, 0.0)]
        self.note('A12', where, 'emitter %s -> Point' % typ)
        return 'Point', None, {}, (0.0, 0.0, 0.0)

    # ----------------------------------------------------------------------------- affectors
    def _scale(self, T, E, affs, w_lo, w_hi, h_lo, h_hi, life, unit, where, affl):
        pu = self.pu
        sa = [A for A in affs if A.type == 'Scale']
        w_mean, h_mean = (w_lo + w_hi) * 0.5, (h_lo + h_hi) * 0.5
        uniform = abs(w_lo - h_lo) < 1e-6 and abs(w_hi - h_hi) < 1e-6
        ranged = abs(w_hi - w_lo) > 1e-6 or abs(h_hi - h_lo) > 1e-6
        if not sa:
            if ranged:
                kv = [('uniform_size', 'true' if uniform else 'false'),
                      ('width_range_start', fnum(w_lo)), ('width_range_end', fnum(w_hi)),
                      ('height_range_start', fnum(h_lo)), ('height_range_end', fnum(h_hi))]
                affl.append(('ScaleInterpolator', kv))
            return w_mean, h_mean
        A = sa[0]
        rx = attr(pu, A, 'x_scale') or attr(pu, A, 'xyz_scale')
        ry = attr(pu, A, 'y_scale') or attr(pu, A, 'xyz_scale')
        if rx is None and ry is None:
            return w_mean, h_mean
        rx = rx or Dyn.fixed(0.0 if SEM['scale_mode'] == 'rate' else 1.0)
        ry = ry or Dyn.fixed(0.0 if SEM['scale_mode'] == 'rate' else 1.0)
        if pbool(pu, A, 'since_start_system'):
            self.note('A16', self._w(T, E, A), 'since_start_system ignored')
        mode = SEM['scale_mode']
        if mode != 'rate' and rx.kind in ('fixed', 'random') and ry.kind in ('fixed', 'random'):
            # GL default (set_scale = 1): size = default * particle factor * (1 + value) -> constant multiplier
            fx = (1.0 + rx.mean()) if mode == 'mult1p' else rx.mean()
            fy = (1.0 + ry.mean()) if mode == 'mult1p' else ry.mean()
            fx, fy = max(0.0, fx), max(0.0, fy)
            if ranged:
                affl.append(('ScaleInterpolator', [('uniform_size', 'true' if uniform and abs(fx - fy) < 1e-6 else 'false'),
                                                   ('width_range_start', fnum(w_lo * fx)), ('width_range_end', fnum(w_hi * fx)),
                                                   ('height_range_start', fnum(h_lo * fy)),
                                                   ('height_range_end', fnum(h_hi * fy))]))
            return w_mean * fx, h_mean * fy
        if mode == 'rate' and rx.kind in ('fixed', 'random') and ry.kind in ('fixed', 'random'):
            kv = [('uniform_size', 'true' if uniform else 'false')]
            if ranged:
                kv += [('width_range_start', fnum(w_lo)), ('width_range_end', fnum(w_hi)),
                       ('height_range_start', fnum(h_lo)), ('height_range_end', fnum(h_hi))]
            else:
                kv += [('width_range_start', fnum(w_mean * 1.0001)), ('width_range_end', fnum(w_mean * 1.0001)),
                       ('height_range_start', fnum(h_mean * 1.0001)), ('height_range_end', fnum(h_mean * 1.0001))]
            kv += [('use_constant_scale', 'true'),
                   ('constant_scale', fvec((rx.mean() * unit * self.T, ry.mean() * unit * self.T, 0.0)))]
            affl.append(('ScaleInterpolator', kv))
            return w_mean, h_mean
        # curves (or multiplier modes): sample absolute sizes over the mean life
        times = stage_times([rx, ry])
        sizes = []
        n = 64
        for t in times:
            if mode == 'rate':
                acc_x = acc_y = 0.0
                for i in range(n):
                    tt = t * (i + 0.5) / n
                    acc_x += rx.at(tt) * (t * life / n)
                    acc_y += ry.at(tt) * (t * life / n)
                sw = max(0.0, w_mean + acc_x * unit * self.T)
                sh = max(0.0, h_mean + acc_y * unit * self.T)
            elif mode == 'mult1p':
                sw, sh = max(0.0, w_mean * (1 + rx.at(t))), max(0.0, h_mean * (1 + ry.at(t)))
            else:
                sw, sh = max(0.0, w_mean * rx.at(t)), max(0.0, h_mean * ry.at(t))
            sizes.append((t, sw, sh))
        base_w = max(1e-3, w_mean)
        base_h = max(1e-3, h_mean)
        kv = [('use_interpolated_scale', 'true')]
        for i, (t, c) in enumerate(pad_stages([(t, [sw / base_w, sh / base_h, 1.0]) for t, sw, sh in sizes], 6)):
            kv.append(('scale%d' % i, fvec(c)))
            kv.append(('time%d' % i, fnum(t)))
        affl.append(('ScaleInterpolator', kv))
        self.note('A16', self._w(T, E, A), 'mode %s, life %.2fs' % (mode, life))
        return base_w, base_h

    def _forces(self, T, E, affs, where, affl, centre):
        """LinearForce / Gravity -> LinearForce blocks; returns the summed constant force (for Vortex folding)."""
        pu = self.pu
        total = (0.0, 0.0, 0.0)
        vortex = any(A.type == 'Vortex' for A in affs)
        for A in affs:
            if A.type == 'LinearForce':
                f = vmul(pval(pu, A, 'force_vector', (0.0, -9.81, 0.0)), self.V * self.T * self.T)
                app = pval(pu, A, 'force_application', 'add')
                total = vadd(total, f)
                if not vortex:
                    affl.append(('LinearForce', [('force_vector', fvec(f)),
                                                 ('force_application', 'average' if app == 'average' else 'add')]))
            elif A.type == 'Gravity':
                g = pval(pu, A, 'gravity', 1.0) or 1.0
                p = vmul(pval(pu, A, 'position', (0.0, 0.0, 0.0)), self.L)
                d = vadd(p, vmul(centre, -1.0))
                dist_auth = max(1.0, vlen(d) / max(1e-6, self.L))
                m_a = pval(pu, A, 'mass_affector', 1.0) or 1.0
                sv_w = self.V / 100.0
                a = 100.0 * sv_w * g * m_a / (dist_auth * max(1e-6, self.scl[0])) * self.T * self.T
                a = max(-20000.0, min(20000.0, a))
                f = vmul(vnorm(d, (0.0, 1.0, 0.0)), a)
                total = vadd(total, f)
                if not vortex:
                    affl.append(('LinearForce', [('force_vector', fvec(f)), ('force_application', 'add')]))
                self.note('A20', self._w(T, E, A), '|a|=%s' % fnum(a))
        return total

    def _rotator(self, A, wa, affl):
        pu = self.pu
        k = 180.0 / math.pi if SEM['rot_unit'] == 'rad' else 1.0
        rot = attr(pu, A, 'rotation')
        spd = attr(pu, A, 'rotation_speed')
        kv = []
        if spd is not None:
            if spd.kind in ('curve', 'osc'):
                self.note('A13', wa, 'rotation_speed curve -> range')
            kv += [('rotation_speed_range_start', fnum(spd.lo() * k * self.T)),
                   ('rotation_speed_range_end', fnum(spd.hi() * k * self.T))]
        if rot is not None:
            lo, hi = rot.lo() * k, rot.hi() * k
            if hi - lo >= 359.0:
                lo, hi = 0.0, 360.0
            kv += [('rotation_range_start', fnum(lo)), ('rotation_range_end', fnum(hi))]
        if kv:
            affl.append(('Rotator', kv))

    def _vortex(self, A, E, wa, affl, v_lo, v_hi, pu_dir, force, life, radial):
        pu = self.pu
        k = 180.0 / math.pi if SEM['rot_unit'] == 'rad' else 1.0
        spd = attr(pu, A, 'rotation_speed', 1.0)
        axis = vnorm(pval(pu, A, 'rotation_axis', (0.0, 1.0, 0.0)))
        ctr = vmul(pval(pu, A, 'position', (0.0, 0.0, 0.0)), self.L)
        v_mean = (v_lo + v_hi) * 0.5
        kv = [('rotation_speed', fnum(spd.mean() * k * self.T)), ('rotation_axis', fvec(axis)),
              ('center_offset_min', fvec(ctr)), ('center_offset_max', fvec(ctr))]
        base_v = (0.0, 0.0, 0.0) if radial else vmul(pu_dir, v_mean)
        if vlen(force) > 1e-6:
            kv.append(('move_usevariablevelocity', 'true'))
            for i in range(6):
                t = i / 5.0
                kv.append(('move_velocity_point%d' % i, fvec(vadd(base_v, vmul(force, t * life)))))
                kv.append(('move_time%d' % i, fnum(t)))
        elif vlen(base_v) > 1e-6:
            kv.append(('move_velocity', fvec(base_v)))
        affl.append(('RevoluMove', kv))
        self.note('A19', wa, 'speed %s deg/s' % fnum(spd.mean() * k))

    def _randomiser(self, A, wa, affl):
        pu = self.pu
        typ = pval(pu, A, 'rand_aff_type', 'rand_aff_type_direction')
        if typ != 'rand_aff_type_direction':
            self.note('A29', wa, 'Randomiser %s' % typ)
            return
        dev = [abs(pval(pu, A, 'max_deviation_' + a, 0.0) or 0.0) for a in 'xyz']
        step = max(0.033, pval(pu, A, 'time_step', 0.1) or 0.1)
        rnd = (sum(dev) / 3.0) * self.V / step * self.T
        affl.append(('DirectionRandomiser', [('randomness', fnum(rnd)), ('scope', '1'), ('keep_velocity', 'false')]))
        self.note('A21', wa, 'randomness %s' % fnum(rnd))

    def _mesh_rotator(self, A, wa, affl):
        pu = self.pu
        k = 180.0 / math.pi if SEM['rot_unit'] == 'rad' else 1.0
        spd = attr(pu, A, 'rotation_speed', 1.0)
        ax = vnorm(pval(pu, A, 'rotation_axis', (0.0, 1.0, 0.0)))
        kv = []
        for name, comp in (('yaw', ax[1]), ('pitch', ax[0]), ('roll', ax[2])):
            if abs(comp) > 1e-3:
                kv += [('%s_rotation_speed_range_start' % name, fnum(spd.lo() * comp * k * self.T)),
                       ('%s_rotation_speed_range_end' % name, fnum(spd.hi() * comp * k * self.T))]
        if kv:
            affl.append(('MeshRotator', kv))

    def _base_speed(self, A, wa, extra):
        pu = self.pu
        rng = []
        for a in 'xyz':
            d = attr(pu, A, 'base_speed_aff_' + a)
            rng.append((d.lo(), d.hi()) if d else (0.0, 0.0))
        if all(abs(lo) < 1e-6 and abs(hi) < 1e-6 for lo, hi in rng):
            return
        lo = tuple(r[0] * self.V * self.T for r in rng)
        hi = tuple(r[1] * self.V * self.T for r in rng)
        extra.append(('Movement', [('use_start_velocity', 'true'), ('start_velocity_min', fvec(lo)),
                                   ('start_velocity_max', fvec(hi))]))
        self.note('A33', wa)

    def _dissolve(self, T, where):
        pu = self.pu
        diss_rel = pval(pu, T, 'disslove_texture')
        f = attr(pu, T, 'disslove_fector')
        if diss_rel is None or not (pbool(pu, T, 'disslove') or (f is not None and f.varies())):
            return None
        f = f or Dyn.fixed(1.0)
        kv = []
        times = stage_times([f])
        for i, (t, c) in enumerate(pad_stages([(t, [1.0 - max(0.0, min(1.0, f.at(t)))]) for t in times], 6)):
            kv.append(('time%d' % i, fnum(t)))
            kv.append(('clip%d' % i, fnum(c[0])))
        ec = pval(pu, T, 'disslove_edge_color')
        if ec is not None:
            kv.append(('colora', fvec(ec)))
            kv.append(('colorb', fvec(ec)))
        kv.append(('soft_edge_width', fnum(min(2.0, max(0.0, abs(pval(pu, T, 'disslove_edge', 0.0) or 0.0) * 0.1)))))
        return ('Dissolve', kv)

    # ------------------------------------------------------------------------------ renderer
    def _renderer(self, T, R, rtype, E, affs, ps, affl, mesh, life, where):
        pu = self.pu
        if rtype == 'RibbonTrail':
            ps.set('renderer', 'ribbon')
            n = int(pval(pu, R, 'max_elements', 20) or 20)
            ps.set('element_count', str(max(4, min(100, n))))
            ps.set('head_alpha', '1')
            cc = pval(pu, R, 'colour_change')
            ps.set('tail_alpha', '0' if (cc is not None and cc[3] > 0) or cc is None else '1')
            ps.set('head_width_scale', '1')
            ps.set('tail_width_scale', '1')
            w = pval(pu, R, 'ribbontrail_width', 5.0) or 5.0
            ps.set('particle_width', fnum(abs(w) * self.L))
            ln = pval(pu, R, 'ribbontrail_length', 100.0) or 100.0
            ps.set('particle_height', fnum(abs(ln) * self.L / max(4, min(100, n))))
            self.note('A23', where)
            return
        if mesh is not None:
            ps.set('renderer', 'mesh')
            ps.set('mesh_name', mesh)
            ot = pval(pu, R, 'entity_orientation_type')
            ps.set('orientation_type', {'ent_oriented_face_to_camera': 'oriented_camera',
                                        'ent_oriented_self': 'oriented_self',
                                        'ent_oriented_self_mirrored': 'oriented_self'}.get(ot, 'oriented_origin'))
            return
        rows = int(pval(pu, R, 'texture_coords_rows', 1) or 1) if R is not None else 1
        cols = int(pval(pu, R, 'texture_coords_columns', 1) or 1) if R is not None else 1
        n = max(1, rows) * max(1, cols)
        ta = [A for A in affs if A.type == 'TextureAnimator']
        frame_props = any(E.prop(k) is not None for k in ('texture_coords', 'start_texture_coords_range',
                                                          'end_texture_coords_range'))
        if n > 1 and (ta or frame_props):
            ps.set('renderer', 'texcoord_billboard')
            ps.set('stacks', str(max(1, rows)))
            ps.set('slices', str(max(1, cols)))
            affl.append(('SequenceFrame', self._sequence(ta[0] if ta else None, E, n, life, where)))
            self.note('A22', where, '%dx%d' % (rows, cols))
        else:
            ps.set('renderer', 'billboard')
        if R is None:
            return
        bt = pval(pu, R, 'billboard_type')
        if bt:
            if bt == 'oriented_shape':
                self.note('A32', where, 'oriented_shape')
                bt = 'oriented_self'
            ps.set('billboard_type', bt)
        bo = pval(pu, R, 'billboard_origin')
        if bo:
            ps.set('billboard_origin', bo)
        br = pval(pu, R, 'billboard_rotation_type')
        if br:
            ps.set('billboard_rotation_type', br)
        for k in ('common_direction', 'common_up_vector'):
            v = pval(pu, R, k)
            if v is not None:
                ps.set(k, fvec(vnorm(v)))
        if pbool(pu, R, 'common_direction_local') or pbool(pu, R, 'common_up_vector_local'):
            self.note('A32', where, 'common_*_local')

    def _sequence(self, TA, E, n, life, where):
        pu = self.pu
        kv = []
        src = TA if TA is not None else E
        s = pval(pu, src, 'start_texture_coords_range', pval(pu, src, 'texture_coords_start', 0)) or 0
        e = pval(pu, src, 'end_texture_coords_range', pval(pu, src, 'texture_coords_end', n - 1))
        if TA is None and E.prop('texture_coords') is not None:
            s = e = pval(pu, E, 'texture_coords', 0)
        s, e = max(0, min(n - 1, int(s))), max(0, min(n - 1, int(e if e is not None else n - 1)))
        nframes = abs(e - s) + 1
        mode, rep, loop, ping = 'normal', 1.0, 'true', 'false'
        start_rand = False
        if TA is not None:
            typ = pval(pu, TA, 'texture_animation_type', 'loop')
            step = pval(pu, TA, 'time_step', pval(pu, TA, 'time_step_animation', 0.0)) or 0.0
            start_rand = pbool(pu, TA, 'texture_start_random')
            if step >= 50.0:
                mode = 'single'
            elif typ == 'random':
                mode = 'random'
                rep = max(1.0, life / step / nframes) if step > 0 else 1.0
            else:
                rep = max(0.05, life / (nframes * step)) if step > 0 else 1.0
                ping = 'true' if typ == 'up_down' else 'false'
        else:
            mode = 'single'
        kv += [('play_mode', mode), ('stacks', '1'), ('slices', '1')]
        kv[1] = ('stacks', str(1))
        kv += [('repeat_times', fnum(rep)), ('pingpang', ping), ('loop', loop)]
        kv.append(('start_range', ('1 %d' % nframes) if start_rand else '0 0'))
        kv.append(('head_and_tail', '%d %d' % (s + 1, e + 1) if nframes < n else 'none'))
        kv += [('play_times', 'none'), ('baned_frames', 'none')]
        return kv

    # -------------------------------------------------------------------------------- finish
    def _finish_effect(self):
        loops = getattr(self, '_loops', True)
        self.effect.loop = loops
        self.effect.lifetime = 0.0 if loops else round(min(60.0, getattr(self, '_span_max', 5.0) + 0.2), 2)

    # --------------------------------------------------------------------------------- write
    def texts(self):
        CR = '\r\n'
        P = []
        for name, ps in self.systems:
            P.append(name)
            P.append('{')
            for k, v in ps.kv:
                P.append('\t%s %s' % (k, v))
            for b in ps.subs:
                P.append('')
                P.append('\t%s %s' % (b.kind, b.typ))
                P.append('\t{')
                for k, v in b.kv:
                    P.append('\t\t%s %s' % (k, v))
                P.append('\t}')
            P.append('')
            P.append('}')
            P.append('')
            P.append('')
        E = ['effect %s' % self.effect.name, '{']
        for el in self.effect.elements:
            E += ['\telement Particle', '\t{', '\t\tCreateLevel\t100', '\t\tStartTime\t%s' % fnum(el['start']),
                  '\t\tLifeTime\t0', '\t\tPosition\t%s' % fvec(el['pos']), '\t\tOrientation\t%s' % fvec(el['orient']),
                  '\t\tParentSpaceLock\tfalse', '\t\tParticleSystem\t%s' % el['ps'], '\t\tParEffectName\tNullEffect',
                  '\t\tuse_particle_effect\tfalse', '\t\tlegacy_pos_for_sub_effect\ttrue',
                  '\t\tpass_rotation_to_sub_effect\tfalse', '\t\tColEffectName\tNullEffect',
                  '\t\tuse_particle_collision\tfalse', '\t\tuse_energy_wave\tfalse', '\t}', '']
        E += ['\tLifeTime\t%s' % fnum(self.effect.lifetime), '', '\tuse_scale\ttrue', '}', '', '']
        M = []
        for name, parent, lines, pas, tu in self.materials:
            M.append('material %s : %s' % (name, parent))
            M.append('{')
            for l in lines:
                M.append('\t' + l)
            M += ['\ttechnique', '\t{', '\t\tpass', '\t\t{']
            for l in pas:
                M.append('\t\t\t' + l)
            if tu:
                M += ['\t\t\ttexture_unit', '\t\t\t{']
                for l in tu:
                    M.append('\t\t\t\t' + l)
                M.append('\t\t\t}')
            M += ['\t\t}', '\t}', '}']
        return CR.join(P) + CR, CR.join(E) + CR, CR.join(M) + CR

    def write(self, out_root):
        d = os.path.join(out_root, self.ename)
        if os.path.isdir(d):
            shutil.rmtree(d)
        os.makedirs(os.path.join(d, 'textures'))
        os.makedirs(os.path.join(d, 'source'))
        p_txt, e_txt, m_txt = self.texts()
        for fn, txt in (('all.particle.frag', p_txt), ('all.effect.frag', e_txt), ('all.material.frag', m_txt)):
            with open(os.path.join(d, fn), 'wb') as f:
                f.write(txt.encode('gbk'))
        tex_rows = []
        for name, info in sorted(self.textures.items()):
            shutil.copyfile(info['file'], os.path.join(d, 'textures', name))
            tex_rows.append(dict(file='textures/' + name, source=info.get('rel'), w=info.get('w'), h=info.get('h'),
                                 format=info.get('fmt')))
        mesh_rows = []
        if self.meshes:
            os.makedirs(os.path.join(d, 'meshes'))
            for name, info in sorted(self.meshes.items()):
                mat = next((m for m in [self._mat_for_mesh(name)] if m), name)
                r = convert_gl_mesh(info['src'], os.path.join(d, 'meshes', name), mat)
                mesh_rows.append(dict(file='meshes/' + name, source=info['rel'], **r))
        with open(os.path.join(d, 'source', os.path.basename(self.path) + '.txt'), 'w', encoding='utf-8') as f:
            f.write(self.pu.to_text())
        rows = []
        for dp, _, fs in os.walk(d):
            for f in sorted(fs):
                p = os.path.join(dp, f)
                rel = os.path.relpath(p, d).replace('\\', '/')
                if rel in ('manifest.tsv', 'manifest.json'):
                    continue
                src = ''
                if rel.startswith('textures/'):
                    src = self.textures.get(f, {}).get('rel', '')
                elif rel.startswith('meshes/'):
                    src = self.meshes.get(f, {}).get('rel', '')
                elif rel.startswith('source/') or rel.endswith('.frag'):
                    src = os.path.relpath(self.path, GL_ROOT).replace('\\', '/')
                rows.append((rel, os.path.getsize(p), hashlib.sha256(open(p, 'rb').read()).hexdigest(), src))
        with open(os.path.join(d, 'manifest.tsv'), 'w', encoding='utf-8', newline='\n') as f:
            f.write('path\tsize\tsha256\tsource\n')
            for r in rows:
                f.write('%s\t%d\t%s\t%s\n' % r)
        used = collections.OrderedDict()
        for code, _, _ in self.notes:
            used[code] = APPROX[code]
        man = dict(effect=self.ename, generated_by=TOOL_VERSION, date=time.strftime('%Y-%m-%d %H:%M'),
                   source=dict(pu=os.path.relpath(self.path, GL_ROOT).replace('\\', '/'),
                               sha256=hashlib.sha256(self.pu.data).hexdigest(), size=len(self.pu.data)),
                   units=dict(length_factor=self.L, velocity_factor=self.V, time_scale=self.T),
                   particle_systems=[n for n, _ in self.systems], materials=[m[0] for m in self.materials],
                   textures=tex_rows, meshes=mesh_rows,
                   effect_info=dict(lifetime=self.effect.lifetime, looping=self.effect.loop,
                                    elements=len(self.effect.elements)),
                   semantics=SEM, approximations_used=used,
                   notes=[dict(code=c, where=w, detail=t) for c, w, t in self.notes],
                   merge='append all.particle.frag / all.effect.frag / all.material.frag to the GBK files; copy '
                         'textures/*.dds (Material/Effect texture pack) and meshes/*.mesh (Effect model folder)')
        with open(os.path.join(d, 'manifest.json'), 'w', encoding='utf-8') as f:
            json.dump(man, f, ensure_ascii=False, indent=1)
        return d

    def _mat_for_mesh(self, mesh_name):
        for name, ps in self.systems:
            if ps.get('mesh_name') == mesh_name:
                return ps.get('material')
        return None


# ================================================================================================== stages
def reduce_stages(keys, n):
    """Greedy removal of the key whose removal changes the piecewise-linear curve least, down to n keys."""
    k = []
    for t, c in keys:                       # drop exact duplicates (same time and colour)
        if k and abs(k[-1][0] - t) < 1e-6 and all(abs(a - b) < 1e-6 for a, b in zip(k[-1][1], c)):
            continue
        k.append((t, list(c)))
    while len(k) > n:
        best, bi = None, None
        for i in range(1, len(k) - 1):
            (t0, c0), (t1, c1), (t2, c2) = k[i - 1], k[i], k[i + 1]
            f = (t1 - t0) / (t2 - t0) if t2 > t0 else 0.5
            err = max(abs(c1[j] - (c0[j] + (c2[j] - c0[j]) * f)) for j in range(len(c1)))
            if best is None or err < best:
                best, bi = err, i
        if bi is None:
            k = k[:n]
            break
        del k[bi]
    return k


def pad_stages(stages, n):
    s = list(stages)[:n]
    if not s:
        s = [(0.0, [1.0, 1.0, 1.0, 1.0])]
    while len(s) < n:
        t, c = s[-1]
        s.append((max(t, 1.0) if len(s) == n - 1 else max(t, 1.0), list(c)))
    # non-decreasing times
    out, last = [], 0.0
    for t, c in s:
        t = max(last, min(1.0, t))
        out.append((t, c))
        last = t
    return out


def stage_times(dyns):
    ts = {0.0, 1.0}
    for d in dyns:
        if d is not None and d.kind == 'curve':
            ts.update(min(1.0, max(0.0, x)) for x, _ in d.pts)
    ts = sorted(ts)
    if len(ts) > 6:
        keep = [ts[0], ts[-1]]
        inner = ts[1:-1]
        step = len(inner) / 4.0
        keep += [inner[int(i * step)] for i in range(4)]
        ts = sorted(set(keep))
    while len(ts) < 6 and len(ts) >= 2:
        gaps = [(ts[i + 1] - ts[i], i) for i in range(len(ts) - 1)]
        g, i = max(gaps)
        ts.insert(i + 1, ts[i] + g / 2)
    return ts


def cone_box(d, ang_deg, v_lo, v_hi):
    d = vnorm(d)
    a = math.radians(min(180.0, ang_deg))
    u = ogre_perpendicular(d)
    w = vcross(d, u)
    pts = []
    for sp in (v_lo, v_hi):
        pts.append(vmul(d, sp))
        for i in range(24):
            ph = 2 * math.pi * i / 24
            dirv = vadd(vmul(d, math.cos(a)), vadd(vmul(u, math.sin(a) * math.cos(ph)), vmul(w, math.sin(a) * math.sin(ph))))
            pts.append(vmul(dirv, sp))
    lo = tuple(min(p[k] for p in pts) for k in range(3))
    hi = tuple(max(p[k] for p in pts) for k in range(3))
    return lo, hi


# ================================================================================================== check
def parse_fragment(text):
    """-> list of (head, kv list, subs[(head, kv)]) for all.particle / all.material style blocks (2 levels)."""
    lines = text.split('\r\n')
    blocks, stack, errs = [], [], []
    prev = None
    for no, raw in enumerate(lines, 1):
        s = raw.strip()
        if '//' in raw:
            errs.append('line %d: comment' % no)
        if not s:
            continue
        if s == '{':
            if prev is None:
                errs.append('line %d: { without head' % no)
                continue
            node = dict(head=prev, kv=[], subs=[], line=no)
            (stack[-1]['subs'] if stack else blocks).append(node)
            stack.append(node)
            prev = None
            continue
        if s == '}':
            if not stack:
                errs.append('line %d: unbalanced }' % no)
            else:
                stack.pop()
            prev = None
            continue
        if prev is not None:
            if stack:
                stack[-1]['kv'].append((prev.split(None, 1)[0], prev.split(None, 1)[1] if ' ' in prev or '\t' in prev
                                         else '', no - 1))
            else:
                errs.append('line %d: stray line at level 0: %r' % (no - 1, prev))
        prev = s
    if prev is not None:
        if stack:
            stack[-1]['kv'].append((prev.split(None, 1)[0], prev.split(None, 1)[1] if len(prev.split()) > 1 else '',
                                    len(lines)))
        else:
            errs.append('trailing stray line %r' % prev)
    if stack:
        errs.append('unclosed block %r' % stack[-1]['head'])
    return blocks, errs


def check_dir(d, client_names=None):
    errs = []
    raw = {}
    for fn in ('all.particle.frag', 'all.effect.frag', 'all.material.frag'):
        p = os.path.join(d, fn)
        if not os.path.isfile(p):
            errs.append('missing ' + fn)
            continue
        b = open(p, 'rb').read()
        try:
            b.decode('ascii')
        except UnicodeDecodeError:
            errs.append(fn + ': non-ASCII bytes')
        if b'\n' in b.replace(b'\r\n', b''):
            errs.append(fn + ': bare LF')
        raw[fn] = b.decode('gbk')
    if errs:
        return errs
    P, e1 = parse_fragment(raw['all.particle.frag'])
    E, e2 = parse_fragment(raw['all.effect.frag'])
    M, e3 = parse_fragment(raw['all.material.frag'])
    errs += ['particle ' + x for x in e1] + ['effect ' + x for x in e2] + ['material ' + x for x in e3]
    mats = {b['head'].split()[1]: b for b in M if b['head'].startswith('material ')}
    for b in M:
        h = b['head'].split()
        if len(h) != 4 or h[2] != ':' or h[3] not in TEMPLATES:
            errs.append('material head %r' % b['head'])
        for k, v, _ in b['kv']:
            if k == 'set_texture_alias':
                tex = v.split()[1]
                if not os.path.isfile(os.path.join(d, 'textures', tex)):
                    errs.append('material %s: texture %s missing' % (h[1], tex))
    systems = {}
    for b in P:
        name = b['head']
        systems[name] = b
        kv = {k: v for k, v, _ in b['kv']}
        rend = kv.get('renderer', 'billboard')
        allowed = SCHEMA['system'] | SCHEMA.get('renderer:' + rend, set())
        for k, v, no in b['kv']:
            if k not in allowed:
                errs.append('%s: key %s not accepted by system/%s' % (name, k, rend))
            if k not in ('material', 'renderer', 'mesh_name', 'billboard_type', 'billboard_origin',
                         'billboard_rotation_type', 'orientation_type', 'sorted', 'local_space', 'cull_each'):
                for tok in v.split():
                    try:
                        float(tok)
                    except ValueError:
                        errs.append('%s: %s value %r not numeric' % (name, k, v))
                        break
        if kv.get('material') not in mats:
            errs.append('%s: material %s not defined' % (name, kv.get('material')))
        if rend == 'mesh' and not os.path.isfile(os.path.join(d, 'meshes', kv.get('mesh_name', ''))):
            errs.append('%s: mesh %s missing' % (name, kv.get('mesh_name')))
        for s in b['subs']:
            kind, _, typ = s['head'].partition(' ')
            sch = SCHEMA.get('%s:%s' % (kind, typ))
            if sch is None:
                errs.append('%s: unknown %s %s' % (name, kind, typ))
                continue
            for k, v, no in s['kv']:
                if k not in sch:
                    errs.append('%s/%s: key %s not in ParamDictionary' % (name, typ, k))
    for b in E:
        if not b['head'].startswith('effect '):
            errs.append('effect head %r' % b['head'])
            continue
        for k, v, _ in b['kv']:
            if k not in SCHEMA['effect']:
                errs.append('effect key %s' % k)
        for s in b['subs']:
            if s['head'] != 'element Particle':
                errs.append('element %r' % s['head'])
                continue
            kv = {k: v for k, v, _ in s['kv']}
            for k in kv:
                if k not in SCHEMA['element:Particle']:
                    errs.append('element key %s' % k)
            if kv.get('ParticleSystem') not in systems:
                errs.append('element references missing system %s' % kv.get('ParticleSystem'))
    names = list(systems) + list(mats) + [b['head'].split()[1] for b in E if b['head'].startswith('effect ')]
    for n in names:
        if not re.fullmatch(r'[A-Za-z0-9_]+', n):
            errs.append('name not ASCII-safe: %r' % n)
    if client_names is not None:
        for n in names:
            if n.encode('ascii') in client_names:
                errs.append('name collides with client_GL: %s' % n)
    return errs


def client_name_set():
    names = set()
    pats = {'EffectFolder\\all.particle': rb'(?m)^([^\s{}][^\r\n]*?)\r?\n\{',
            'EffectFolder\\all.effect': rb'(?m)^effect\s+(\S+)',
            'MaterialFolder\\all.material': rb'(?m)^material\s+(\S+)'}
    for fn, pat in pats.items():
        p = os.path.join(CLIENT_DATA, fn)
        if os.path.isfile(p):
            b = open(p, 'rb').read()
            names.update(m.group(1).strip() for m in re.finditer(pat, b))
    return names


# ================================================================================================== rank
def _rank_one(args):
    path, root = args
    try:
        pu = jbpu.PUFile.load(path)
    except Exception as e:     # noqa: BLE001
        return None
    assets = _rank_one.assets
    S = pu.root
    sc = S.prop('scale')
    L = (sc.val[0] if sc else 1.0) * 100.0
    techs = S.child('technique')
    ok = total = mesh = 0
    alive = 0.0
    tex_px = 0
    texs = set()
    n_obs = 0
    for T in techs:
        R = (T.child('renderer') or [None])[0]
        rt = R.type if R is not None else 'Billboard'
        ems = [E for E in T.child('emitter') if E.prop('emits') is None]
        if not ems:
            continue
        total += 1
        n_obs += len(T.child('observer'))
        good_em = all(E.type in ('Point', 'Box', 'Cylinder', 'Circle', 'SphereSurface', 'Hemisphere', 'Line',
                                 'Position', 'MeshSurface') for E in ems)
        if rt in ('Billboard', 'RibbonTrail') and good_em:
            ok += 1
        elif rt in ('Entity', 'Customize'):
            mesh += 1
        q = pval(pu, T, 'visual_particle_quota', 500)
        a_t = 0.0
        for E in ems:
            r = attr(pu, E, 'emission_rate', 10.0).mean()
            t = attr(pu, E, 'time_to_live', 3.0).mean()
            a_t += r if pbool(pu, E, 'force_emission') else r * min(t, 30.0)
        alive += min(q, a_t)
        mtl = pval(pu, T, 'material')
        if mtl:
            for rel in assets.mtl_textures(mtl)[:1]:
                if rel in texs:
                    continue
                texs.add(rel)
                p = assets.find_texture(rel)
                h = jmt_header(p) if p else None
                if h:
                    tex_px += h[1] * h[2]
    frac = ok / total if total else 0.0
    score = frac * math.log2(1 + min(alive, 4000)) * (1 + math.log2(1 + tex_px / 65536.0)) * min(1.0, total / 3.0)
    if n_obs:
        score *= 0.7
    return (os.path.relpath(path, root).replace('\\', '/'), round(score, 3), total, ok, mesh, int(alive), tex_px,
            len(texs), n_obs, pval(pu, S, 'category', ''))


def _rank_init():
    _rank_one.assets = GLAssets()


def rank(top, tsv, workers):
    root = os.path.join(GL_ROOT, 'files')
    files = []
    for dp, _, fs in os.walk(os.path.join(root, 'data', 'effect')):
        for f in fs:
            if f.endswith('.pu'):
                files.append((os.path.join(dp, f), root))
    from concurrent.futures import ProcessPoolExecutor
    with ProcessPoolExecutor(max_workers=workers, initializer=_rank_init) as ex:
        res = [r for r in ex.map(_rank_one, files, chunksize=64) if r]
    res.sort(key=lambda r: -r[1])
    if tsv:
        with open(tsv, 'w', encoding='utf-8', newline='\n') as f:
            f.write('file\tscore\ttechniques\tconvertible\tmesh\test_particles\ttex_px\ttextures\tobservers\tcategory\n')
            for r in res:
                f.write('\t'.join(str(x) for x in r) + '\n')
    for r in res[:top]:
        print('%-86s %7.2f tech=%-2d ok=%-2d mesh=%-2d alive=%-5d px=%-8d obs=%d %s' % (r[0], r[1], r[2], r[3], r[4],
                                                                                    r[5], r[6], r[8], r[9]))
    return 0


# ================================================================================================== main
def convert_many(paths, out_root, prefix):
    assets = GLAssets()
    conv = Converter(assets, out_root, prefix)
    names = client_name_set()
    report = []
    for p in paths:
        st = conv.convert(p)
        d = st.write(out_root)
        errs = check_dir(d, names)
        report.append((st.ename, d, len(st.systems), len(st.effect.elements), len(st.textures), len(st.meshes),
                       len(st.notes), errs))
        print('%-60s systems=%-3d textures=%-3d meshes=%-2d notes=%-3d check=%s' % (
            st.ename, len(st.systems), len(st.textures), len(st.meshes), len(st.notes),
            'OK' if not errs else '%d errors' % len(errs)))
        for e in errs[:12]:
            print('    !', e)
    return report


def main(argv=None):
    ap = argparse.ArgumentParser(description='GL Particle-Universe (.pu) -> Fairy effect converter')
    sub = ap.add_subparsers(dest='cmd')
    a = sub.add_parser('convert')
    a.add_argument('pu', nargs='+')
    a.add_argument('--out-root', default=DEFAULT_OUT)
    a.add_argument('--prefix', default='gl_')
    a = sub.add_parser('batch')
    a.add_argument('spec')
    a.add_argument('--out-root', default=DEFAULT_OUT)
    a.add_argument('--prefix', default='gl_')
    a = sub.add_parser('rank')
    a.add_argument('--top', type=int, default=80)
    a.add_argument('--tsv')
    a.add_argument('--workers', type=int, default=4)
    a = sub.add_parser('check')
    a.add_argument('dirs', nargs='+')
    sub.add_parser('mapping')
    args = ap.parse_args(argv)
    if args.cmd == 'convert':
        rep = convert_many(args.pu, args.out_root, args.prefix)
        return 0 if all(not r[-1] for r in rep) else 2
    if args.cmd == 'batch':
        spec = json.load(open(args.spec, encoding='utf-8'))
        paths = [e['pu'] if os.path.isabs(e['pu']) else os.path.join(GL_ROOT, e['pu']) for e in spec['effects']]
        rep = convert_many(paths, args.out_root, args.prefix)
        idx = os.path.join(args.out_root, '_batch_%s.json' % os.path.splitext(os.path.basename(args.spec))[0])
        json.dump([dict(effect=r[0], dir=r[1], systems=r[2], elements=r[3], textures=r[4], meshes=r[5], notes=r[6],
                        check=r[7]) for r in rep], open(idx, 'w', encoding='utf-8'), indent=1)
        return 0 if all(not r[-1] for r in rep) else 2
    if args.cmd == 'rank':
        return rank(args.top, args.tsv, min(4, max(1, args.workers)))
    if args.cmd == 'check':
        names = client_name_set()
        bad = 0
        for d in args.dirs:
            errs = check_dir(d, names)
            print(d, 'OK' if not errs else '')
            for e in errs:
                print('   !', e)
            bad += bool(errs)
        return 0 if not bad else 2
    if args.cmd == 'mapping':
        print(MAPPING_DOC)
        for k, v in APPROX.items():
            print('- **%s** %s' % (k, v))
        return 0
    ap.print_help()
    return 1


if __name__ == '__main__':
    sys.exit(main())
