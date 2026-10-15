"""Original DATA CY control tree, geometry, imagery and event callbacks.

Only namespaces, approved UTF-8 font, display labels and the name limit adapt.
"""
from pathlib import Path
import re
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT.parent / 'Tools/DATA NEW/DataCY31-08-26/Interface'
PREFIX = 'CysCR_'
COUNTS = {'CreateRole': 96, 'SelectRole': 50}
LABELS = {'CreateRole_RandomName': 'Gợi ý', 'CreateRole_Info2_Frame_Back4': 'Nam',
          'CreateRole_Info2_Frame_Back5': 'Nữ', 'Createshow_Info': 'Chọn môn phái',
          'Createshow_Notice': 'Xem trước môn phái'}


def source_layout(screen):
    if screen not in COUNTS:
        raise ValueError('Unknown original CY screen')
    return ET.fromstring((SOURCE / screen / (screen + '.layout.xml')).read_bytes())


def types():
    return {w.attrib['Type'] for screen in COUNTS for w in source_layout(screen).iter('Window')
            if w.attrib['Type'] != 'DefaultWindow'}


def layout(screen):
    document = source_layout(screen)
    windows = list(document.iter('Window'))
    if len(windows) != COUNTS[screen]:
        raise ValueError('Original CY control tree changed')
    for window in windows:
        name = window.attrib['Name']
        if window.attrib['Type'] != 'DefaultWindow':
            window.set('Type', PREFIX + window.attrib['Type'])
        properties = {node.attrib['Name']: node for node in window.findall('Property')}
        if 'Font' in properties:
            properties['Font'].set('Value', PREFIX + 'Control')
        else:
            ET.SubElement(window, 'Property', Name='Font', Value=PREFIX + 'Control')
        if name in LABELS and 'Text' in properties:
            properties['Text'].set('Value', LABELS[name])
        if name == 'CreateRole_Name':
            properties['MaxTextLength'].set('Value', '29')
        for node in window.findall('Property'):
            node.set('Value', re.sub(r'\bset:([^\s]+)', r'set:' + PREFIX + r'\1', node.attrib['Value']))
    ET.indent(document, space='  ')
    return ET.tostring(document, encoding='utf-8', xml_declaration=True) + b'\n'
