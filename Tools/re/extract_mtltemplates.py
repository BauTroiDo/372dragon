# -*- coding: utf-8 -*-
"""Extract (read-only source) client_GL MaterialTemplates.zip into CY-Source staging.

Usage:  python extract_mtltemplates.py
Source is opened read-only; nothing under client_GL is written.
Writes Assets/Staging/materialtemplates/B/<entries> + _manifest.tsv (name, size, crc32, sha256).
"""
import hashlib
import os
import zipfile

SRC = r'C:\TLBB\085\client_GL\Data\MaterialTemplates.zip'
DST = r'C:\TLBB\085\CY-Source\Assets\Staging\materialtemplates\B'


def main():
    global SRC, DST
    import sys
    if len(sys.argv) >= 3:          # optional: <zip> <dst dir>  (e.g. the 0.85 Reference zip)
        SRC, DST = sys.argv[1], sys.argv[2]
    os.makedirs(DST, exist_ok=True)
    with open(SRC, 'rb') as f:
        zsha = hashlib.sha256(f.read()).hexdigest()
    rows = []
    with zipfile.ZipFile(SRC, 'r') as z:
        for info in z.infolist():
            if info.filename.endswith('/'):
                os.makedirs(os.path.join(DST, info.filename), exist_ok=True)
                continue
            data = z.read(info)
            out = os.path.join(DST, info.filename.replace('/', os.sep))
            os.makedirs(os.path.dirname(out), exist_ok=True)
            with open(out, 'wb') as g:
                g.write(data)
            rows.append((info.filename, len(data), '%08x' % info.CRC,
                         hashlib.sha256(data).hexdigest()))
    with open(os.path.join(DST, '_manifest.tsv'), 'w', encoding='utf-8', newline='\n') as m:
        m.write('# source\t%s\tsha256=%s\n' % (SRC, zsha))
        m.write('name\tsize\tcrc32\tsha256\n')
        for r in rows:
            m.write('%s\t%d\t%s\t%s\n' % r)
    print('zip sha256', zsha, 'files', len(rows))


if __name__ == '__main__':
    main()
