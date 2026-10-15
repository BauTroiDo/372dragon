# -*- coding: utf-8 -*-
"""LogicModel object XML in the all.obj dialect.

The engine parses it with TinyXML in WXLogicModelManager::parseScript / _parseSingleObject
(Src/Engine/WXCore/ModelSystem/WXLogicModelManager.cpp:196-686): a file is either one <Object>
(its object name is then the file name) or <AllObjects> holding many <Object name="...">.  Only the
FIRST <Attributes>, <EntityList>, <MaterialList>, <Locators>, <Effects>, <Skeletons> child of an
object is read (FirstChildElement).

Bytes are bridged through latin-1 so every GBK byte survives unchanged: GBK lead/trail bytes are
0x81-0xFE / 0x40-0xFE and never equal the XML metacharacters " & < > (Docs/08 1.2).  Written files
have no XML declaration, CRLF line ends and 4-space indentation - the shape of ModelFolder/all.obj.
"""
import xml.etree.ElementTree as ET


def L(b):
    """bytes (GBK) -> element text; str passes through."""
    return b.decode('latin-1') if isinstance(b, bytes) else ('' if b is None else b)


def B(s):
    """element text -> bytes (GBK); bytes pass through."""
    return s.encode('latin-1') if isinstance(s, str) else (b'' if s is None else s)


def parse_object(block):
    return ET.fromstring(L(block))


def parse_document(data):
    """File bytes -> ([<Object> elements], root tag)."""
    root = ET.fromstring(L(data))
    if root.tag == 'AllObjects':
        return [c for c in root if c.tag == 'Object'], root.tag
    return [root], root.tag


def name_of(el):
    return B(el.get('name', ''))


def _children(el, tag, child):
    parent = el.find(tag)
    return [] if parent is None else parent.findall(child)


# ------------------------------------------------------------------ attributes
def iter_attrs(el):
    return _children(el, 'Attributes', 'Attribute')


def get_attr(el, name):
    name = L(name)
    for x in iter_attrs(el):
        if x.get('name') == name:
            return x
    return None


def attr_value(el, name, default=None):
    x = get_attr(el, name)
    return default if x is None else B(x.get('value', ''))


def set_attr(el, name, value, hints=None):
    """Set an attribute value (keeps its hints) or append a new <Attribute>."""
    x = get_attr(el, name)
    if x is None:
        a = el.find('Attributes')
        if a is None:
            a = ET.Element('Attributes')
            el.insert(0, a)
        x = ET.SubElement(a, 'Attribute')
        x.set('name', L(name))
        x.set('value', L(value))
        if hints is not None:
            x.set('hints', L(hints))
    else:
        x.set('value', L(value))
    return x


# ------------------------------------------------------------------ entities / material slots
def entities(el):
    return _children(el, 'EntityList', 'Entity')


def get_entity(el, name):
    name = L(name)
    for e in entities(el):
        if e.get('name') == name:
            return e
    return None


def set_entity(el, name, file, material=None):
    e = get_entity(el, name)
    if e is None:
        raise KeyError('entity %r is not declared by the template' % L(name))
    e.set('file', L(file))
    if material is not None:
        e.set('material', L(material))
    return e


def material_slots(el):
    return _children(el, 'MaterialList', 'Material')


def get_material_slot(el, name):
    name = L(name)
    for m in material_slots(el):
        if m.get('name') == name:
            return m
    return None


def set_material_slot(el, name, material):
    m = get_material_slot(el, name)
    if m is None:
        raise KeyError('material slot %r is not declared by the template' % L(name))
    m.set('material', L(material))
    return m


# ------------------------------------------------------------------ locators / slots
def locators(el):
    return _children(el, 'Locators', 'Locator')


def get_locator(el, name):
    name = L(name)
    for loc in locators(el):
        if loc.get('name') == name:
            return loc
    return None


def find_slot(el, slot):
    slot = L(slot)
    for loc in locators(el):
        for s in loc.findall('Slot'):
            if s.get('name') == slot:
                return loc, s
    return None, None


def set_slot(el, slot, obj):
    """Fill an existing slot (and its SlotCreate attribute, as changeAttribute would)."""
    loc, s = find_slot(el, slot)
    if s is None:
        raise KeyError('slot %r is not declared by the template' % L(slot))
    s.set('object', L(obj))
    set_attr(el, slot, obj, 'SlotCreate')
    return loc


def add_slot(el, locator, slot, obj):
    loc = get_locator(el, locator)
    if loc is None:
        raise KeyError('locator %r is not declared by the object' % L(locator))
    s = ET.SubElement(loc, 'Slot')
    s.set('name', L(slot))
    s.set('object', L(obj))
    s.set('attribs', '')
    set_attr(el, slot, obj, 'SlotCreate')
    return loc


# ------------------------------------------------------------------ effects
def effects(el):
    return _children(el, 'Effects', 'Effect')


def add_effect(el, name, effect, locator, translate_all=True):
    eff = el.find('Effects')
    if eff is None:
        eff = ET.SubElement(el, 'Effects')
    x = ET.SubElement(eff, 'Effect')
    x.set('name', L(name))
    x.set('effect', L(effect))
    x.set('locator', L(locator))
    if translate_all:
        x.set('translateAll', 'true')
    return x


def skeleton_links(el):
    """<Skeletons> -> {animation name bytes: skeleton file bytes} (first link wins)."""
    links = {}
    for s in _children(el, 'Skeletons', 'Skeleton'):
        skel = B(s.get('skeleton', ''))
        for a in B(s.get('animations', '')).split():
            links.setdefault(a, skel)
    return links


# ------------------------------------------------------------------ writing
def _esc(v):
    return v.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;').replace('"', '&quot;')


def _lines(el, depth, out):
    ind = '    ' * depth
    attrs = ''.join(' %s="%s"' % (k, _esc(v)) for k, v in el.attrib.items())
    kids = list(el)
    if kids:
        out.append('%s<%s%s>' % (ind, el.tag, attrs))
        for k in kids:
            _lines(k, depth + 1, out)
        out.append('%s</%s>' % (ind, el.tag))
    else:
        out.append('%s<%s%s />' % (ind, el.tag, attrs))


def object_bytes(el):
    out = []
    _lines(el, 0, out)
    return B('\r\n'.join(out))


def document_bytes(objects, comment=None):
    """<AllObjects> document.  The optional comment must be ASCII; it is placed before the root
    element (a comment inside <AllObjects> would reach _parseSingleObject as a non-element)."""
    parts = []
    if comment:
        c = comment.replace('--', '-')
        c.encode('ascii')
        parts.append(B('<!-- %s -->' % c))
    parts.append(b'<AllObjects>')
    for el in objects:
        parts.append(object_bytes(el))
    parts.append(b'</AllObjects>')
    return b'\r\n'.join(parts) + b'\r\n'
