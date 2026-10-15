"""yamlout.py - small dependency-free YAML emitter (block style; short maps and
lists of scalars are written in flow style).  Output is valid YAML 1.2."""
import json
import math
import re

_PLAIN = re.compile(r'^[A-Za-z_][A-Za-z0-9_.\-/]*$')
_RESERVED = frozenset(('true', 'false', 'yes', 'no', 'on', 'off', 'null', 'none', 'y', 'n'))


def is_scalar(v):
    return not isinstance(v, (dict, list, tuple))


def scalar(v):
    if v is None:
        return '~'
    if v is True:
        return 'true'
    if v is False:
        return 'false'
    if isinstance(v, int):
        return str(v)
    if isinstance(v, float):
        if math.isnan(v):
            return '.nan'
        if math.isinf(v):
            return '.inf' if v > 0 else '-.inf'
        return repr(v)
    s = str(v)
    if _PLAIN.match(s) and s.lower() not in _RESERVED:
        return s
    return json.dumps(s, ensure_ascii=False)


def flow(v):
    if isinstance(v, dict):
        return '{' + ', '.join('%s: %s' % (scalar(k), flow(x)) for k, x in v.items()) + '}'
    if isinstance(v, (list, tuple)):
        return '[' + ', '.join(flow(x) for x in v) + ']'
    return scalar(v)


def _small(v, width):
    if isinstance(v, dict):
        if not v:
            return '{}'
        for x in v.values():
            if not is_scalar(x) and not (isinstance(x, (list, tuple)) and len(x) <= 12
                                         and all(is_scalar(y) for y in x)):
                return None
    elif isinstance(v, (list, tuple)):
        if not v:
            return '[]'
        if not all(is_scalar(x) for x in v):
            return None
    else:
        return scalar(v)
    s = flow(v)
    return s if len(s) <= width else None


def _emit_map(d, ind, lines, width):
    pad = ' ' * ind
    for k, v in d.items():
        ks = scalar(k)
        if is_scalar(v):
            lines.append('%s%s: %s' % (pad, ks, scalar(v)))
            continue
        sm = _small(v, width - ind - len(ks) - 2)
        if sm is not None:
            lines.append('%s%s: %s' % (pad, ks, sm))
        elif isinstance(v, dict):
            lines.append('%s%s:' % (pad, ks))
            _emit_map(v, ind + 2, lines, width)
        else:
            lines.append('%s%s:' % (pad, ks))
            _emit_list(v, ind, lines, width)


def _emit_list(lst, ind, lines, width):
    pad = ' ' * ind
    for v in lst:
        if is_scalar(v):
            lines.append('%s- %s' % (pad, scalar(v)))
            continue
        sm = _small(v, width - ind - 2)
        if sm is not None:
            lines.append('%s- %s' % (pad, sm))
        elif isinstance(v, dict):
            sub = []
            _emit_map(v, ind + 2, sub, width)
            sub[0] = pad + '- ' + sub[0][ind + 2:]
            lines.extend(sub)
        else:
            lines.append(pad + '-')
            _emit_list(v, ind + 2, lines, width)


def dump(obj, header=None, width=160):
    lines = []
    if header:
        for h in header.splitlines():
            lines.append(('# ' + h).rstrip())
    if isinstance(obj, dict):
        _emit_map(obj, 0, lines, width)
    elif isinstance(obj, (list, tuple)):
        _emit_list(obj, 0, lines, width)
    else:
        lines.append(scalar(obj))
    return '\n'.join(lines) + '\n'
