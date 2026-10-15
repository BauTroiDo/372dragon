"""Fit Vietnamese equipment skill text in the three owned CY layouts."""
from pathlib import Path
import argparse
import datetime
import shutil
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[2]
UI = ROOT / 'Assets/CanonicalCY/Data/InterfaceFolder'


def pair(x, y, sx=0, sy=0):
    return '{{%.6f,%.6f},{%.6f,%.6f}}' % (sx, x, sy, y)


def patch(name, raw):
    tree = ET.fromstring(raw)
    windows = {w.attrib['Name']: w for w in tree.iter('Window')}

    def prop(suffix, key, value):
        window = windows[name + '_' + suffix]
        # The XML loader applies properties in order; remove older coordinate
        # forms so a later AbsoluteSize/Position cannot undo this placement.
        conflicts = {'UnifiedSize': ('AbsoluteSize', 'Size'),
                     'UnifiedPosition': ('AbsolutePosition', 'Position')}
        for child in list(window):
            if child.tag == 'Property' and child.get('Name') in conflicts.get(key, ()):
                window.remove(child)
        node = window.find("Property[@Name='%s']" % key)
        if node is None:
            node = ET.SubElement(window, 'Property', Name=key)
        node.set('Value', value)

    def rect(suffix, x, y, w, h, sx=0, sy=0, sw=0, sh=0):
        prop(suffix, 'UnifiedPosition', pair(x, y, sx, sy))
        prop(suffix, 'UnifiedSize', pair(w, h, sw, sh))

    if name == 'EquipLingPai_SkillQH':
        rect('Frame', -390, -275, 780, 550, .5, .5)
        rect('Info', 0, 0, 0, 96, sw=1)
        rect('Input', 12, 102, -24, 42, sw=1)
        rect('InputText', 0, 9, -70, 24, sw=1)
        rect('InputIcon', -52, 4, 34, 34, sx=1)
        rect('CurrentSkill', 12, 149, -24, 30, sw=1)
        rect('CurrentSkillText', 0, 3, 190, 24)
        rect('CurrentSkillNameLace', 196, 0, -196, 30, sw=1)
        rect('Attr', 12, 183, -24, 240, sw=1)
        rect('SkillZiKuang', 0, 25, 332, 211)
        rect('NameShuoming', 340, 25, -340, 211, sw=1)
        rect('NameShuomingText', 7, 6, -14, -12, sw=1, sh=1)
        rect('Blank', 10, -29, -200, 20, sy=1, sw=1)
        rect('OK', -184, -29, 86, 22, sx=1, sy=1)
        rect('Cancel', -96, -29, 86, 22, sx=1, sy=1)
    elif name == 'AnqiShuxingNEW':
        rect('Frame', -380, -302, 760, 604, .5, .5)
        rect('Info', 0, 0, 0, 100, sw=1)
        rect('BeforeText', 6, 106, -12, 24, sw=.5)
        rect('AfterText', 6, 106, -12, 24, sx=.5, sw=.5)
        rect('BeforeIcon', -17, 136, 34, 34, sx=.25)
        for suffix in ('AfterIcon', 'AfterIcon_BK'):
            rect(suffix, -17, 136, 34, 34, sx=.75)
        rect('Icon', -50, 143, 100, 20, sx=.5)
        for side, scale in (('Before', 0), ('After', .5)):
            rect(side, 4, 177, -8, 268, sx=scale, sw=.5)
            rect(side + 'Attr', 0, 0, 0, 268, sw=1)
            for index, word in enumerate(('First', 'Second', 'Third')):
                row = index + (1 if side == 'Before' else 4)
                rect('Kuang' + str(row), 3, 24 + index * 80, -6, 80, sw=1)
                rect(side + 'Attr' + word, 38, 0, -44, 80, sw=1)
        rect('Blank', 2, -24, -190, 24, sy=1, sw=1)
        rect('OK', -184, -24, 88, 24, sx=1, sy=1)
        rect('Cancel', -92, -24, 88, 24, sx=1, sy=1)
    else:
        assert name == 'NewWuhunSkillStudy'
        rect('Frame', -380, -310, 760, 620, .5, .5)
        rect('Info', 1, 0, -2, 155, sw=1)
        prop('Info', 'VertFormatting', 'TopAligned')
        rect('Info2', -170, 163, 340, 24, sx=.25)
        rect('Info3', -170, 163, 340, 24, sx=.75)
        rect('Object', -18, 191, 36, 36, sx=.25)
        for suffix in ('Object2', 'Object2_BK'):
            rect(suffix, -18, 191, 36, 36, sx=.75)
        rect('Icon', -50, 198, 100, 20, sx=.5)
        for side, scale in (('Bk1', 0), ('Bk2', .5)):
            rect(side, 10, 236, -20, 205, sx=scale, sw=.5)
            rect(side + '_Text1', 0, 0, 0, 36, sw=1)
            prop(side + '_Text1', 'VertFormatting', 'TopAligned')
            for index, suffix in enumerate(('Frame', 'Frame2', 'Frame3')):
                rect(side + '_' + suffix, 0, 40 + index * 55, 0, 55, sw=1)
        rect('Bk2_Btn', 10, -116, -20, 24, sx=.5, sy=1, sw=.5)
        rect('Blank', 3, -24, -190, 24, sy=1, sw=1)
        rect('OK', -184, -24, 88, 24, sx=1, sy=1)
        rect('Cancel', -92, -24, 88, 24, sx=1, sy=1)
        prop('Blank_QuerenLace', 'UnifiedSize', pair(230, 20))
        prop('Blank_Queren_Text', 'UnifiedSize', pair(200, 20))
    # The widgets and handlers must remain exactly the same.
    assert set(windows) == {w.attrib['Name'] for w in tree.iter('Window')}
    return b'<?xml version="1.0" encoding="UTF-8" ?>\n' + ET.tostring(tree, encoding='utf-8') + b'\n'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--apply', action='store_true')
    args = parser.parse_args()
    changes = []
    for name in ('EquipLingPai_SkillQH', 'AnqiShuxingNEW', 'NewWuhunSkillStudy'):
        path = UI / name / (name + '.layout.xml')
        raw = path.read_bytes()
        new = patch(name, raw)
        assert patch(name, new) == new, name
        print(name, 'CHANGE' if new != raw else 'unchanged')
        if new != raw:
            changes.append((path, new))
    if args.apply and changes:
        backup = ROOT / 'Build/backups/equipment-skill-layout' / datetime.datetime.now().strftime('%Y%m%d-%H%M%S')
        backup.mkdir(parents=True, exist_ok=False)
        for path, raw in changes:
            shutil.copy2(path, backup / path.name)
            path.write_bytes(raw)
        print('backup', backup)


if __name__ == '__main__':
    main()
