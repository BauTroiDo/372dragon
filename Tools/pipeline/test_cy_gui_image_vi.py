# -*- coding: utf-8 -*-
"""Tests of cy_gui_image_vi.py (layer cy-gui-image-vi, ui-image-vi 15/09/2026). Run: python -B test_cy_gui_image_vi.py"""
import io
import os
import re
import sys
import tempfile
import unicodedata
import unittest

import numpy as np
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import cy_gui_image_vi as G  # noqa: E402

FONT = next((p for p in (os.path.join(HERE, '..', '..', 'Assets', 'Canonical', 'Data', 'InterfaceFolder', 'Schema',
                                       'NotoSansSC-Regular.ttf'),
                          r'C:\TLBB\085\CY-Source\Assets\Canonical\Data\InterfaceFolder\Schema\NotoSansSC-Regular.ttf')
             if os.path.exists(p)), None)
HAN = re.compile(r'[\u3400-\u9fff]')


def plate(w, h, text=None):
    """CY-like button: vertical red gradient, 2 px gold frame, gold CJK label with a dark outline."""
    px = np.zeros((h, w, 4), np.uint8)
    for y in range(h):
        px[y, :, :3] = (150 - 80 * y // h, 20, 20)
    px[..., 3] = 255
    px[:2, :, :3] = px[-2:, :, :3] = (200, 170, 90)
    px[:, :2, :3] = px[:, -2:, :3] = (200, 170, 90)
    if text:
        im = Image.fromarray(px, 'RGBA')
        f = ImageFont.truetype(FONT, int(h * 0.6))
        ImageDraw.Draw(im).text((w // 2, h // 2), text, font=f, fill=(250, 220, 140, 255), anchor='mm',
                                stroke_width=1, stroke_fill=(40, 10, 0, 255))
        px = np.array(im)
    return px


class FakeReader:
    def __init__(self, files):
        self.files = files

    def resolve(self, rel):
        low = {k.lower(): k for k in self.files}
        return low.get(rel.replace('\\', '/').lower())

    def read(self, rel):
        return self.files[rel]

    def origin(self, rel):
        return 'mem:' + rel


class Tests(unittest.TestCase):
    def test_registry(self):
        rows = G.load_registry()
        self.assertGreater(len(rows), 50)
        for r in rows:
            self.assertTrue(HAN.search(r['zh']), 'zh must hold the Chinese label (line %d)' % r['line'])
            self.assertFalse(HAN.search(r['vi']), 'vi must not hold Chinese (line %d)' % r['line'])
            self.assertEqual(r['vi'], unicodedata.normalize('NFC', r['vi']))
            for k in r['opts']:
                self.assertIn(k, {'box', 'area', 'size', 'squeeze', 'stroke', 'color', 'ink', 'widen', 'dx', 'dy', 'ref',
                                  'grow', 'fill', 'icon', 'r', 'cap', 'bold', 'shadow', 'k', 't', 'tmin', 'keepborder',
                                  'keepframe', 'radius', 'ring', 'vtop', 'vbot', 'stroke_color', 'stroke_alpha',
                                  'stroke_min', 'shadow_alpha', 'round', 'alt', 'core', 'margin', 'minsize', 'readable', 'chan',
                                  'contrast_min'}, 'unknown option %s (line %d)' % (k, r['line']))

    def test_match_images(self):
        names = ['A_Normal', 'A_Hover', 'B_Normal']
        self.assertEqual(G.match_images(['A_*'], names), ['A_Hover', 'A_Normal'])
        with self.assertRaises(KeyError):
            G.match_images(['C_*'], names)

    def test_dds_roundtrip(self):
        px = np.random.RandomState(1).randint(0, 256, (16, 24, 4)).astype(np.uint8)
        back, kind = G.decode_image(G.encode_image(px, 'dds'))
        self.assertEqual(kind, 'dds')
        self.assertTrue(np.array_equal(back, px))

    @unittest.skipUnless(FONT, 'Noto font not found')
    def test_paint_removes_glyph_and_keeps_frame(self):
        src = plate(64, 22, '充值')
        ink, box = G.find_ink(src, {})
        self.assertIsNotNone(box)
        self.assertGreater(box[2] - box[0], 20)
        new, info = G.paint_label(src, 'Nạp', {}, FONT)
        self.assertEqual(info['status'], 'ok')
        self.assertTrue(np.array_equal(new[:2], src[:2]) and np.array_equal(new[:, :2], src[:, :2]),
                        'frame texels must stay')
        # the Vietnamese label differs from the Chinese one where the glyph was
        self.assertGreater(int(np.any(new != src, axis=2).sum()), 40)

    @unittest.skipUnless(FONT, 'Noto font not found')
    def test_generate_changes_only_rectangles(self):
        tex = np.zeros((64, 128, 4), np.uint8)
        tex[..., 0] = 90
        tex[..., 3] = 255
        tex[4:26, 4:68] = plate(64, 22, '充值')
        tex[30:52, 4:68] = plate(64, 22, '充值')
        files = {
            'Schema/WoWLookSkin.scheme.xml': b'<GUIScheme><Imageset Name="T" Filename="Common/T.imageset.xml" /></GUIScheme>',
            'Common/T.imageset.xml': ('<Imageset Name="T" Imagefile="Common/t.dds">'
                                      '<Image Name="B_Normal" XPos="4" YPos="4" Width="64" Height="22" />'
                                      '<Image Name="B_Hover" XPos="4" YPos="30" Width="64" Height="22" />'
                                      '</Imageset>').encode(),
            'Common/t.dds': G.encode_image(tex, 'dds'),
        }
        with tempfile.TemporaryDirectory() as tmp:
            reg = os.path.join(tmp, 'reg.tsv')
            with open(reg, 'w', encoding='utf-8') as f:
                f.write('imageset\timages\tzh\tvi\topts\tnote\nT\tB_*\t充值\tNạp\t\ttest\n')
            out, manifest, problems, stats = G.generate(FakeReader(files), tmp, reg, FONT)
            self.assertEqual(problems, [])
            self.assertEqual(stats['images_painted'], 2)
            self.assertEqual(len(out), 1)
            with open(out[0][1], 'rb') as f:
                new, _ = G.decode_image(f.read())
        outside = np.ones(tex.shape[:2], bool)
        outside[4:26, 4:68] = outside[30:52, 4:68] = False
        self.assertTrue(np.array_equal(new[outside], tex[outside]))
        self.assertEqual(len(manifest), 2)
        self.assertEqual(manifest[0][5], 'Nạp')


if __name__ == '__main__':
    unittest.main(verbosity=1)
