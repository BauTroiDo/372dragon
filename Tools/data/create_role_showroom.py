"""Stage the settled CY creation/selection camera poses, without changing S2.

Clean-room constants recovered from the CY client C (not from GL coordinates).
See Docs/specs/ui/create-role-reference_vi.md and the original-reference evidence.
The original animated camera transitions are not reproduced by this adapter.
"""
import hashlib
from pathlib import Path

SCENE = 'tl3chuangjian.Scene'
SCENE_SHA256 = '1fb487ee19bed00adc01d811d2554658091b13def544b4d7e9bf0c946f046f17'
RENDER_SHA256 = 'e6e67de45489f90207379419c0eb2e9f4fbdbd1d800cc6f46902c1fe5eb0cec7'
CREATE_Q = (0.9990310072898865, -0.04409569874405861, 0.0037784099113196135, 0.00016679000691510737)
SELECT_Q = (0.9992520213127136, -0.04023699834942818, 0.00030515898833982646, 0.000012777200026903301)
# position XYZ, yaw radians, eye XYZ, orientation WXYZ, vertical FOV degrees.
POSES = {
    'female': ((818., 1064., 3033.), 0., (822.0590209960938, 1307.3800048828125, 3708.2900390625), CREATE_Q, 65.),
    'male': ((818., 1064., 3033.), 0., (822.0590209960938, 1347.219970703125, 3678.52001953125), CREATE_Q, 65.),
    'select0': ((796.5360107421875, 1146., 1059.6800537109375), 0., (797.1099853515625, 1313.3699951171875, 1408.780029296875), SELECT_Q, 65.),
    'select1': ((-289.39801025390625, 1139., 1060.1400146484375), 0., (-289.04901123046875, 1313.3699951171875, 1408.3699951171875), SELECT_Q, 65.),
    'select2': ((1891.1300048828125, 1139., 1063.9599609375), 0., (1890.8599853515625, 1313.3699951171875, 1408.3699951171875), SELECT_Q, 65.),
}


def build_plan(stage, source_root, base_updates=None):
    source_root = Path(source_root)
    scene_bytes = (source_root / 'Scene' / SCENE).read_bytes()
    if hashlib.sha256(scene_bytes).hexdigest() != SCENE_SHA256:
        raise ValueError('CY showroom scene differs from the verified camera/actor presentation')
    lines = ['scene ' + SCENE]
    for label, (position, yaw, eye, orientation, fov) in POSES.items():
        values = (*position, yaw, *eye, *orientation, fov)
        lines.append(label + ' ' + ' '.join(format(value, '.17g') for value in values))
    payload = ('\n'.join(lines) + '\n').encode('ascii')
    target = 'Data/Config/CysLoginShowroom.txt'
    origin = 'CY C native settled cameras/anchors; original scene and model scales'
    report = {
        'valid': True, 'scene': SCENE, 'scene_sha256': SCENE_SHA256,
        'render_sha256': RENDER_SHA256, 'pose_count': len(POSES), 'vertical_fov_degrees': 65,
        'create_scale': 1.5, 'select_scale': 1.0,
        'poses': POSES, 'adaptation': 'Settled original poses; camera transition animations omitted.',
        'evidence': [
            'Build/Logs/2026-09-13-gpt-create-role/original-reference/c-create-ctor-anchors.txt',
            'Build/Logs/2026-09-13-gpt-create-role/original-reference/c-camera-keyframes.json',
            'Build/Logs/2026-09-13-gpt-create-role/original-reference/c-select-ctor.txt',
        ],
        'files': [{'path': target, 'bytes': len(payload), 'sha256': hashlib.sha256(payload).hexdigest(), 'origin': origin}],
    }
    return {target: payload}, {target: origin}, report
