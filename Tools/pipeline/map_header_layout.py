"""Keep the CY minimap header controls; give Vietnamese names and coordinates separate rows.

The working GL layout uses a 40px header with the coordinates on its second row.
This uses the existing CY 184px width and preserves every event and control name.
"""
import re

_CHANGES = {
    'MiniMap_Frame': {'AbsoluteSize': 'w:251 h:240'},
    'MiniMap_Background_Title': {'AbsoluteSize': 'w:184.000000 h:40.000000'},
    'MiniMap_Placename': {'UnifiedSize': '{{0,156},{0,18}}', 'UnifiedPosition': '{{0,12},{0,0}}'},
    'MiniMap_Placename2': {'UnifiedSize': '{{0,156},{0,18}}', 'UnifiedPosition': '{{0,12},{0,0}}'},
    'MiniMap_Coordinate': {'UnifiedSize': '{{0,96},{0,18}}', 'UnifiedPosition': '{{0,44},{0,18}}', 'HorzFormatting': 'HorzCentred'},
    # CY draws this sibling after the title: North starts at y21 and the ring at y27.
    # Move the complete map/button group below the second text row (ends at y36).
    'MiniMap_Background_Frame': {'UnifiedPosition': '{{1,-219},{0,16}}'},
    'MiniMap_Help': {'UnifiedPosition': '{{1,-32},{0,83}}'},
    'MiniMap_Luzhi_Button': {'UnifiedPosition': '{{0,213},{0,204}}'},
}

def transform(text):
    if 'Name="MiniMap_Background_Title"' not in text:
        return text, False
    original = text
    for window, properties in _CHANGES.items():
        pattern = r'(<Window\b[^>]*\bName="' + re.escape(window) + r'"[^>]*>)(.*?)(?=<Window\b|</Window>)'
        matches = list(re.finditer(pattern, text, re.S))
        if len(matches) != 1:
            raise ValueError('Expected exactly one minimap control: ' + window)
        match = matches[0]
        prefix = match.group(2)
        for name, value in properties.items():
            prop = r'(<Property\s+Name="' + re.escape(name) + r'"\s+Value=")[^"]*(")'
            prefix, count = re.subn(prop, lambda m: m[1] + value + m[2], prefix)
            if count != 1:
                raise ValueError('Expected one property ' + window + '.' + name)
        text = text[:match.start(2)] + prefix + text[match.end(2):]
    return text, text != original

def generate(data):
    """Stage a transformed copy while preserving the source encoding and bytes elsewhere."""
    bom, encoding = (b'', 'utf-8')
    for prefix, name in ((b'\xef\xbb\xbf', 'utf-8'), (b'\xff\xfe', 'utf-16-le'), (b'\xfe\xff', 'utf-16-be')):
        if data.startswith(prefix):
            bom, encoding = prefix, name
            break
    text, changed = transform(data[len(bom):].decode(encoding))
    return bom + text.encode(encoding), changed
