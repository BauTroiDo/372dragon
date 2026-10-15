"""Nhập mã nguồn 0.85 từ Reference vào Src (CY-Source, pha E0).

- Chỉ ĐỌC Reference; ghi vào Src theo bảng ánh xạ MAP (Docs/04 mục 3.1).
- File C/C++ không phải ASCII:
    * đã là UTF-8 hợp lệ  -> ghi lại UTF-8 có BOM (đánh dấu 'utf8-src');
    * giải mã chặt bằng GBK (cp936) và mã hoá ngược ra ĐÚNG từng byte -> ghi UTF-8 có BOM
      ('gbk'); biên dịch với /source-charset:utf-8 /execution-charset:.936 thì literal
      trở lại đúng byte GBK như bản gốc;
    * còn lại -> chép nguyên byte ('raw', phải xử lý tay).
- File khác (rc, def, cg, hlsl, material, xml, project...) chép nguyên byte.
- Manifest: Registry/import/source-import-<ngày>.csv

Chạy:  python import_source.py [--dry]
"""
import csv
import datetime
import hashlib
import os
import re
import sys

ROOT = r'C:\TLBB\085\CY-Source'
R = os.path.join(ROOT, r'Reference\tlbb085\085\SourceCode')
K = os.path.join(R, r'Client\天龙八部客户端')

MAP = [
    (r'Client\WXClient', r'Client\WXClient', K),
    (r'Client\WXNetPackets', r'Client\WXNetPackets', K),
    (r'Client\CEGUISystem', r'Client\CEGUISystem', K),
    (r'Client\CEGUIFalagardEx', r'Client\CEGUIFalagardEx', K),
    (r'Client\Helper', r'Client\Support\Helper', K),
    (r'Client\Debuger', r'Client\Support\Debuger', K),
    (r'Client\CrashReport', r'Client\Support\CrashReport', K),
    (r'Client\Common', r'Shared\Common', R),
    (r'Client\Common', r'Engine\Interface', K),
    (r'Client\WXEngine', r'Engine\WXEngine', K),
    (r'Client\WXCore', r'Engine\WXCore', K),
    (r'Client\WXRender', r'Engine\WXRender', K),
    (r'OGRE\OgreMain', r'Engine\OGRE\OgreMain', K),
    (r'OGRE\RenderSystems\Direct3D9', r'Engine\OGRE\RenderSystems\Direct3D9', K),
    (r'OGRE\PlugIns', r'Engine\OGRE\PlugIns', K),
    (r'OGRE\PlatformManagers', r'Engine\OGRE\PlatformManagers', K),
    (r'OGRE\Dependencies\include', r'ThirdParty\OgreDeps\include', K),
    (r'OGRE\Dependencies\src', r'ThirdParty\OgreDeps\src', K),
    (r'ParticleFX2', r'Engine\ParticleFX2', K),
    (r'Scorpio', r'Engine\Scorpio', K),
    (r'Client\LuaPlus', r'ThirdParty\LuaPlus', K),
    (r'Client\CEGUI', r'ThirdParty\CEGUI-0.4.1', K),
    (r'Client\zlib', r'ThirdParty\zlib-client', K),
    (r'Client\zziplib', r'ThirdParty\zziplib-client', K),
    (r'FreeType', r'ThirdParty\FreeType', K),
    (r'expat', r'ThirdParty\expat', K),
    (r'tinyxml', r'ThirdParty\tinyxml', K),
    (r'Opcode', r'ThirdParty\Opcode', K),
    (r'zlib', r'ThirdParty\zlib', K),
    (r'zziplib', r'ThirdParty\zziplib', K),
    (r'Devil', r'ThirdParty\Devil', K),
    (r'Xerces\src', r'ThirdParty\Xerces\src', K),
    (r'boost\boost', r'ThirdParty\boost\boost', K),
    (r'boost\libs', r'ThirdParty\boost\libs', K),
]

CXX = {'.c', '.cc', '.cpp', '.cxx', '.h', '.hh', '.hpp', '.hxx', '.inl', '.ipp', '.tcc'}
SKIP_EXT = {'.lib', '.dll', '.exe', '.pdb', '.obj', '.ilk', '.exp', '.ncb', '.suo', '.opt',
            '.plg', '.aps', '.pch', '.idb', '.sbr', '.bsc', '.res', '.tlog', '.lastbuildstate'}
SKIP_DIR = re.compile(r'(?i)^(debug|release|final|debug_stl|.*___win32_debug|\.svn|cvs|extlibs|'
                      r'samples?|tests?|docs?|mac|backup)$')

BOM = b'\xef\xbb\xbf'


def sha(b):
    return hashlib.sha256(b).hexdigest()


def classify(data):
    if data.startswith(BOM):
        try:
            data[3:].decode('utf-8', 'strict')
            return 'utf8-bom', data
        except UnicodeDecodeError:
            return 'raw', data
    if all(b < 0x80 for b in data):
        return 'ascii', data
    try:
        text = data.decode('utf-8', 'strict')
        return 'utf8-src', BOM + text.encode('utf-8')
    except UnicodeDecodeError:
        pass
    try:
        text = data.decode('cp936', 'strict')
        if text.encode('cp936', 'strict') == data:
            return 'gbk', BOM + text.encode('utf-8')
    except (UnicodeDecodeError, UnicodeEncodeError):
        pass
    return 'raw', data


def main():
    dry = '--dry' in sys.argv
    # --missing-only: chỉ ghi file CHƯA có ở đích (không đè file đang được sửa).
    # --only <tiền tố đích>: chỉ xử lý các mục MAP có đích bắt đầu bằng tiền tố này.
    # --noskip: không lọc thư mục (vd. boost có thư mục nguồn thật tên debug/test/doc).
    missing_only = '--missing-only' in sys.argv
    noskip = '--noskip' in sys.argv
    only = None
    if '--only' in sys.argv:
        only = sys.argv[sys.argv.index('--only') + 1].lower()
    stamp = datetime.date.today().isoformat()
    suffix = ''
    if only or missing_only:
        suffix = '-partial-' + datetime.datetime.now().strftime('%H%M%S')
    out_csv = os.path.join(ROOT, r'Registry\import', 'source-import-%s%s.csv' % (stamp, suffix))
    rows = []
    stats = {}
    for src_rel, dst_rel, base in MAP:
        if only and not dst_rel.lower().startswith(only):
            continue
        src_root = os.path.join(base, src_rel)
        dst_root = os.path.join(ROOT, 'Src', dst_rel)
        if not os.path.isdir(src_root):
            print('THIẾU nguồn:', src_root)
            continue
        for dirpath, dirnames, filenames in os.walk(src_root):
            if not noskip:
                dirnames[:] = [d for d in dirnames if not SKIP_DIR.match(d)]
            for fn in filenames:
                ext = os.path.splitext(fn)[1].lower()
                sp = os.path.join(dirpath, fn)
                rel = os.path.relpath(sp, src_root)
                dp = os.path.join(dst_root, rel)
                if ext in SKIP_EXT:
                    action = 'skip'
                    rows.append((os.path.relpath(sp, ROOT), '', os.path.getsize(sp), '', action, ''))
                    stats[action] = stats.get(action, 0) + 1
                    continue
                if missing_only and os.path.exists(dp):
                    stats['exists'] = stats.get('exists', 0) + 1
                    continue
                data = open(sp, 'rb').read()
                if ext in CXX:
                    enc, outb = classify(data)
                else:
                    enc, outb = 'bytes', data
                action = 'convert' if outb != data else 'copy'
                stats[enc] = stats.get(enc, 0) + 1
                if not dry:
                    os.makedirs(os.path.dirname(dp), exist_ok=True)
                    with open(dp, 'wb') as f:
                        f.write(outb)
                rows.append((os.path.relpath(sp, ROOT), os.path.relpath(dp, ROOT), len(data),
                             sha(data), action, enc))
    if not dry:
        os.makedirs(os.path.dirname(out_csv), exist_ok=True)
        with open(out_csv, 'w', newline='', encoding='utf-8') as f:
            w = csv.writer(f)
            w.writerow(['source', 'dest', 'size', 'sha256_source', 'action', 'encoding'])
            w.writerows(rows)
    print('files:', len(rows), 'stats:', stats)
    raw = [r for r in rows if r[5] == 'raw']
    print('raw (cần xử lý tay):', len(raw))
    for r in raw[:40]:
        print('  ', r[0])
    print('manifest:', out_csv if not dry else '(dry)')


if __name__ == '__main__':
    main()
