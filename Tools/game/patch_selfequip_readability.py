"""Build a scoped CY SelfEquip overlay; never modify CanonicalCY or shared looks."""
from pathlib import Path
import argparse
import hashlib
import json
import re
import xml.etree.ElementTree as ET

LAYOUT_SHA = '50e2f6c100466d68beffcb5acd4944b0e1b37628c5948195f4857b1bc032721a'
LUA_SHA = '872b4d5a6d29a8909387f95676a36ee1534e12658c1be47edfb0c9788f0517db'
TABS = ('SelfEquip', 'SelfData', 'Pet', 'Infant', 'Wuhun', 'Xiulian', 'Miji',
        'ZhenYuan', 'JingMai', 'ShenDing', 'JunXian', 'BaoJian', 'WuYi',
        'ShenQi', 'Armor', 'CangPin', 'OtherInfo')


def sha(data):
    return hashlib.sha256(data).hexdigest()


def generate(layout, lua, portrait=True):
    if sha(layout) != LAYOUT_SHA or sha(lua) != LUA_SHA:
        raise ValueError('Unreviewed SelfEquip input; recheck the live comparison before changing the manifest.')
    root = ET.fromstring(layout)
    nodes = {n.get('Name'): n for n in root.iter('Window')}
    changes = {}

    def prop(name, key, value):
        if name not in nodes:
            raise ValueError('Missing original control: ' + name)
        changes.setdefault(name, {})[key] = str(value)

    def box(name, x, y, w, h):
        props = {p.get('Name') for p in nodes[name].findall('Property')}
        if 'AbsolutePosition' in props:
            prop(name, 'AbsolutePosition', f'x:{x} y:{y}')
            prop(name, 'AbsoluteSize', f'w:{w} h:{h}')
        else:
            prop(name, 'UnifiedPosition', '{{0,%s},{0,%s}}' % (x, y))
            prop(name, 'UnifiedSize', '{{0,%s},{0,%s}}' % (w, h))

    def text(name, x, y, w, h=24, align='LeftAligned'):
        box(name, x, y, w, h)
        prop(name, 'HorzFormatting', align)
        prop(name, 'VertFormatting', 'VertCentred')

    # CY has a different hierarchy and 17 dynamic tabs. Keep every original node.
    box('SelfEquip_Frame', 8, 8, 756, 600)
    # CY's body ends where its tab strip begins. Reserve the full two-row strip.
    prop('SelfEquip_MainFrame', 'UnifiedSize', '{{1,-14},{1,-62}}')
    # Footer ends at client y480; retain it inside the shorter body (4px margin).
    prop('SelfEquip_Frame_Client', 'UnifiedSize', '{{1,-30},{1,-58}}')
    box('SelfEquip_Checkbox_Frame', 22, 548, 712, 52)
    for index, suffix in enumerate(TABS):
        x, y = (index % 9) * 78, (index // 9) * 27
        for ending in ('', '_tips'):
            box('SelfEquip_' + suffix + ending, x, y, 76, 24)
    box('SelfEquip_Ride', 5 * 78, 27, 76, 24)  # Original hidden alias of the Armor slot.

    # Use the left column down to y424 (footer begins at430). Keep the CY
    # controls anchored to the same frame so rotation/resistance buttons follow.
    if portrait:
        box('SelfEquip_FakeObject_Frame', 43, 34, 296, 390)
        box('SelfEquip_FakeObject_BK', 2, 2, 290, 365)
        box('SelfEquip_FakeObject', 23, 12, 246, 331)

    # Compact the unused right margin, preserving room for real comparison deltas.
    for row, suffix in enumerate(('HP', 'MP', 'SP')):
        text('SelfEquip_' + suffix + '_Text', 340, row * 24, 372)
        text('SelfEquip_' + suffix, 484, row * 24, 220, align='RightAligned')
    box('SelfEquip_Bk2', 664, 76, 48, 120)
    for row, suffix in enumerate(('Str', 'Nimbus', 'PhysicalStrength', 'Stability', 'Footwork')):
        y = 76 + row * 24
        text('SelfEquip_' + suffix + '_Text', 340, y, 316)
        text('SelfEquip_' + suffix, 490, y, 100, align='RightAligned')
        text('SelfEquip_' + suffix + '_Plus', 596, y, 60, align='RightAligned')
        box('Equip_Addition_Button' + str(row + 1), 666, y + 2, 20, 20)
        box('Equip_Decrease_Button' + str(row + 1), 690, y + 2, 20, 20)
    text('SelfEquip_Potential_Text', 342, 200, 150)
    text('SelfEquip_Potential', 498, 200, 132, align='RightAligned')
    box('SelfEquip_Accept', 640, 200, 72, 24)
    box('SelfEquip_Bk3', 340, 228, 372, 192)
    labels = ('Ngoại công', 'Nội công', 'Ngoại thủ', 'Nội thủ', 'Chính xác', 'Né tránh', 'Hội công', 'Hội thủ')
    for row, (number, label) in enumerate(zip((1, 2, 3, 4, 7, 6, 5, 9), labels)):
        y = row * 24
        text('SelfEquip_PerportyText_' + str(number), 6, y, 142)
        prop('SelfEquip_PerportyText_' + str(number), 'Text', label + ':')
        text('SelfEquip_Perporty' + str(number), 152, y, 132, align='RightAligned')
        text('SelfEquip_Perporty' + str(number) + '_Plus', 290, y, 74, align='RightAligned')
    # Live row8 and legacy row5 intentionally coincide. Do not delete either.
    text('SelfEquip_Perporty8', 152, 144, 132, align='RightAligned')
    text('SelfEquip_Perporty8_Plus', 290, 144, 74, align='RightAligned')

    for label, value, x, y, width, value_x, value_w, caption in (
        ('Energy1_Text', 'Vigor', 0, 430, 328, 126, 194, 'Sinh lực:'),
        ('Energy2_Text', 'Energy', 0, 456, 328, 126, 194, 'Tinh lực:'),
        ('Exp1_Text', 'Exp1', 340, 430, 286, 150, 128, 'KN tăng cấp:'),
        ('Exp2_Text', 'Exp2', 340, 456, 286, 150, 128, 'KN hiện có:'),
    ):
        text('SelfEquip_' + label, x, y, width)
        prop('SelfEquip_' + label, 'Text', caption)
        text('SelfEquip_' + value, value_x, 0, value_w, align='RightAligned')
    # Preserve the live layout's dedicated right margin for the level-up control.
    # It must not cover either resource/experience row or the two rows of tabs.
    box('SelfEquip_LevelUp_All', 672, 485, 60, 60)
    box('SelfEquip_UpLevel', 9, 0, 51, 60)
    box('SelfEquip_UpLevel_Tip', 9, 0, 51, 60)
    box('SelfEquip_Levelup_Mask', 699, 495, 20, 48)

    content = layout.decode('utf-8')
    for name, node in nodes.items():
        if node.get('Type') == 'TLBB_ActionButton' and re.fullmatch(r'SelfEquip_\d+', name):
            prop(name, 'ShowDurability', 'True')
    for name, properties in changes.items():
        pattern = r'(<Window\b[^>]*\bName="' + re.escape(name) + r'"[^>]*>)(.*?)(?=<Window\b|</Window>)'
        matches = list(re.finditer(pattern, content, re.S))
        if len(matches) != 1:
            raise ValueError('Ambiguous window: ' + name)
        match = matches[0]
        block = match[2]
        for key, value in properties.items():
            pattern_property = r'(<Property\b[^>]*\bName="' + re.escape(key) + r'"[^>]*\bValue=")([^"]*)(")'
            hits = re.findall(pattern_property, block)
            if len(hits) > 1:
                raise ValueError('Duplicate property: ' + name + '/' + key)
            if hits:
                block = re.sub(pattern_property, lambda m: m[1] + value + m[3], block, count=1)
            else:
                block += '\n      <Property Name="' + key + '" Value="' + value + '" />\n'
        content = content[:match.start(2)] + block + content[match.end(2):]
    output = content.encode('utf-8')
    after = ET.fromstring(output)
    # Resolve offsets against the actual parent hierarchy, including Frame_Client.
    # This checks only the edited controls; unchanged CY baseline quirks are separate.
    rectangles = {}
    def resolve_geometry(node, parent=(0, 0, 1280, 720)):
        if node.tag != 'Window':
            for child in node:
                resolve_geometry(child, parent)
            return
        values = {p.get('Name'): p.get('Value') for p in node.findall('Property')}
        def pair(kind, default):
            absolute = values.get('Absolute' + kind)
            if absolute:
                return tuple(map(float, re.findall(r'[-+]?\d+(?:\.\d+)?', absolute)))
            unified = values.get('Unified' + kind)
            if unified:
                a, b, c, d = map(float, re.findall(r'[-+]?\d+(?:\.\d+)?', unified))
                return a * parent[2] + b, c * parent[3] + d
            return default
        x, y = pair('Position', (0, 0))
        w, h = pair('Size', (parent[2], parent[3]))
        name = node.get('Name')
        rectangles[name] = (parent[0] + x, parent[1] + y, w, h)
        if name in changes and (x < 0 or y < 0 or x + w > parent[2] + .01 or y + h > parent[3] + .01):
            raise ValueError('Edited control exceeds its parent: ' + name)
        for child in node.findall('Window'):
            resolve_geometry(child, rectangles[name])
    resolve_geometry(after)
    main_body = rectangles['SelfEquip_MainFrame']
    tab_strip = rectangles['SelfEquip_Checkbox_Frame']
    if main_body[1] + main_body[3] > tab_strip[1] + .01:
        raise ValueError('Main body overlaps the tab strip: %r vs %r' % (main_body, tab_strip))
    level = rectangles['SelfEquip_LevelUp_All']
    for name in ('SelfEquip_Bk3', 'SelfEquip_Energy1_Text', 'SelfEquip_Energy2_Text',
                 'SelfEquip_Exp1_Text', 'SelfEquip_Exp2_Text', 'SelfEquip_Checkbox_Frame'):
        rect = rectangles[name]
        if min(level[0] + level[2], rect[0] + rect[2]) > max(level[0], rect[0]) and min(level[1] + level[3], rect[1] + rect[3]) > max(level[1], rect[1]):
            raise ValueError('Level-up control overlaps %s: %r vs %r' % (name, level, rect))
    # Compare semantic structure after removing only reviewed presentation properties.
    def signature(node):
        attrs = dict(node.attrib)
        children = []
        for child in node:
            if node.tag == 'Window' and child.tag == 'Property' and child.get('Name') in changes.get(node.get('Name'), {}):
                continue
            children.append(signature(child))
        return node.tag, attrs, children
    if signature(root) != signature(after):
        raise ValueError('A control, event, hierarchy or functional property changed.')

    script = lua.decode('utf-8')
    old = 'local newpos = g_PageButtonTipsPos[idx] --28 + g_SelfEquip_PageButton[idx]:GetProperty("UnifiedXPosition");'
    if script.count(old) != 3:
        raise ValueError('Unreviewed tab hint positioning.')
    script = script.replace(old, 'local tab = g_SelfEquip_PageButton[idx]\n\t\t\tlocal newpos = "{0,"..tostring(tonumber(tab:GetProperty("AbsoluteXPosition")) + tonumber(tab:GetProperty("AbsoluteWidth")) - 10).."}"\n\t\t\tlocal newy = tab:GetProperty("UnifiedYPosition")')
    for name in ('SelfEquip_WuYi_Buttontips', 'SelfEquip_OtherInfo_ButtonTips', 'SelfEquip_CangPin_Buttontips'):
        line = name + ':SetProperty("UnifiedXPosition", newpos);'
        if script.count(line) != 1:
            raise ValueError('Unreviewed tab hint: ' + name)
        script = script.replace(line, line + '\n\t\t\t' + name + ':SetProperty("UnifiedYPosition", newy);')
    if portrait:
        attach = 'SelfEquip_FakeObject:AttachWindowEx("Player");\r\n\t\tSetFakeObjDataEx("Player")'
        if script.count(attach) != 1:
            raise ValueError('Unreviewed SelfEquip model attachment sequence.')
        script = script.replace(attach, attach + '\n\t\tCysSelfEquip_FitPortrait()')
        # Per-window camera API used by live CY. Reset first: reopen must not
        # multiply the previous fitted distance, or inherit a rotation.
        script += '''

function CysSelfEquip_FitPortrait()
    SelfEquip_FakeObject:RestPositonEx()
    local height, distance, pitch = SelfEquip_FakeObject:GetCameraEx()
    if distance ~= nil and distance > 0 then
        SelfEquip_FakeObject:SetCameraEx(height * 1.10, distance * 0.48, pitch)
    end
end
'''
    script += '''

-- Comparison deltas keep their own columns only while they contain text.
local CysSelfEquip_OriginalUpdate = Equip_OnUpdateShow
function Equip_OnUpdateShow()
    CysSelfEquip_OriginalUpdate()
    local values = {SelfEquip_Perporty1, SelfEquip_Perporty2, SelfEquip_Perporty3,
        SelfEquip_Perporty4, SelfEquip_Perporty5, SelfEquip_Perporty6,
        SelfEquip_Perporty7, SelfEquip_Perporty8, SelfEquip_Perporty9}
    local deltas = {SelfEquip_Perporty1_Plus, SelfEquip_Perporty2_Plus, SelfEquip_Perporty3_Plus,
        SelfEquip_Perporty4_Plus, SelfEquip_Perporty5_Plus, SelfEquip_Perporty6_Plus,
        SelfEquip_Perporty7_Plus, SelfEquip_Perporty8_Plus, SelfEquip_Perporty9_Plus}
    for i=1,9 do
        local t = deltas[i]:GetText()
        values[i]:SetProperty("AbsoluteWidth", (t == nil or t == "") and "212" or "132")
    end
end
'''
    result_lua = script.encode('utf-8')
    report = {'before_layout_sha256': sha(layout), 'after_layout_sha256': sha(output),
              'before_lua_sha256': sha(lua), 'after_lua_sha256': sha(result_lua),
              'windows_preserved': len(nodes), 'changed_properties': changes,
              'edited_control_parent_bounds': 'PASS', 'levelup_row_separation': 'PASS',
              'main_body_tab_separation': 'PASS',
              'portrait_profile': 'fit' if portrait else 'legacy',
              'scope': 'SelfEquip layout, tab hints and its own portrait camera; live visual/input QA required'}
    return output, result_lua, report


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--input', type=Path, required=True, help='Read-only SelfEquip directory')
    parser.add_argument('--output', type=Path, required=True, help='New proposal directory')
    args = parser.parse_args()
    if args.output.exists():
        parser.error('Output already exists; use a fresh proposal directory.')
    layout, lua, report = generate((args.input / 'SelfEquip.layout.xml').read_bytes(), (args.input / 'SelfEquip.lua').read_bytes())
    args.output.mkdir(parents=True)
    (args.output / 'SelfEquip.layout.xml').write_bytes(layout)
    (args.output / 'SelfEquip.lua').write_bytes(lua)
    (args.output / 'manifest.json').write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(json.dumps({'windows_preserved': report['windows_preserved'], 'changed_windows': len(report['changed_properties']), 'output': str(args.output)}, ensure_ascii=False))
