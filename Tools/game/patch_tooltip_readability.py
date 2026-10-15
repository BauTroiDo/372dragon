"""Give CY tooltip header translations room in fresh stages; preserve the live source."""
import re
import xml.etree.ElementTree as ET


def generate(data):
    text = data.decode('utf-8')
    before = ET.fromstring(text)
    changes = {}
    for node in before.iter('Window'):
        name = node.get('Name')
        props = {p.get('Name'): p.get('Value') for p in node.findall('Property')}
        selected = {}
        if name == '_SuperTooltip_':
            selected['AbsoluteSize'] = ('w:300 h:411', 'w:440 h:411')
        elif name == 'SuperTooltip_StaticPart_Item1':
            selected['AbsoluteSize'] = ('w:108.000000 h:16.000000', 'w:138.000000 h:16.000000')
        elif node.get('Type', '').startswith('TLBB_SuperTooltip_ResizeText'):
            for key in ('MinWidth', 'MaxWidth'):
                if props.get(key) in ('296', '436'):
                    selected[key] = ('296', '436')
        if selected:
            changes[name] = selected
    if not all(name in changes for name in ('_SuperTooltip_', 'SuperTooltip_StaticPart_Item1',
                                            'SuperTooltip_Property', 'SuperTooltip_Explain')):
        raise ValueError('Expected CY tooltip layout is missing')
    for name, props in changes.items():
        pattern = r'(<Window\b[^>]*\bName="' + re.escape(name) + r'"[^>]*>)(.*?)(?=<Window\b|</Window>)'
        matches = list(re.finditer(pattern, text, re.S))
        if len(matches) != 1:
            raise ValueError('Expected one tooltip window: ' + name)
        match = matches[0]
        block = match[2]
        for key, (old, new) in props.items():
            prop = r'(<Property\s+Name="' + key + r'"\s+Value=")([^"]*)(")'
            found = list(re.finditer(prop, block))
            if len(found) != 1 or found[0][2] not in (old, new):
                raise ValueError('Unreviewed tooltip geometry: ' + name + '/' + key)
            block = re.sub(prop, lambda m: m[1] + new + m[3], block)
        text = text[:match.start(2)] + block + text[match.end(2):]
    # Only the declared geometry changes; retain every widget, property and event.
    after = ET.fromstring(text)
    old_nodes, new_nodes = list(before.iter()), list(after.iter())
    assert len(old_nodes) == len(new_nodes)
    active = None
    for old, new in zip(old_nodes, new_nodes):
        assert old.tag == new.tag
        if old.tag == 'Window':
            active = old.get('Name')
        if old.attrib != new.attrib:
            assert old.tag == 'Property' and old.get('Name') in changes.get(active, {})
            assert {k: v for k, v in old.attrib.items() if k != 'Value'} == {
                k: v for k, v in new.attrib.items() if k != 'Value'}
    # The translated level row ends before the existing right-anchored upgrade group.
    assert 73 + 138 < (440 - 4) - 112
    result = text.encode('utf-8')
    return result, result != data
