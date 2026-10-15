"""Verify one external test-data ZIP. Does not download, extract or execute files."""
import argparse
import hashlib
import json
from pathlib import Path
import stat
import zipfile

def verify(archive, manifest, full=False):
    info=json.loads(Path(manifest).read_text(encoding='utf-8'))
    archive=Path(archive)
    if not info.get('sha256') or not info.get('bytes'):raise ValueError('Manifest has no completed archive hash/size')
    if archive.stat().st_size!=info['bytes']:raise ValueError('Archive size mismatch')
    h=hashlib.sha256()
    with archive.open('rb') as f:
        for block in iter(lambda:f.read(4*1024*1024),b''):h.update(block)
    if h.hexdigest()!=info['sha256']:raise ValueError('Archive SHA-256 mismatch')
    with zipfile.ZipFile(archive) as z:
        entries=z.infolist();names=[e.filename for e in entries]
        if len(names)!=len(set(names)):raise ValueError('Duplicate ZIP member')
        for e in entries:
            p=e.filename
            if not p or p.startswith('/') or '\\' in p or ':' in p or any(v in ('..','') for v in p.split('/')):
                raise ValueError('Unsafe ZIP path')
            if stat.S_ISLNK(e.external_attr>>16):raise ValueError('ZIP contains a symlink')
        index=z.getinfo('DATA-FILES.json')
        if index.file_size>128*1024*1024:raise ValueError('Oversized file index')
        files=json.loads(z.read(index));mapping={r['path']:r for r in files}
        if len(files)!=len(mapping):raise ValueError('Duplicate index member')
        if set(names)!=set(mapping)|{'DATA-FILES.json','DATA-NOTICE.txt'}:raise ValueError('Index/archive mismatch')
        if len(files)!=info['files'] or sum(r['bytes'] for r in files)!=info['raw_bytes']:raise ValueError('Index size/count mismatch')
        for e in entries:
            if e.filename in mapping and e.file_size!=mapping[e.filename]['bytes']:raise ValueError('Member size mismatch')
        if full:
            for row in files:
                h=hashlib.sha256()
                with z.open(row['path']) as f:
                    for block in iter(lambda:f.read(4*1024*1024),b''):h.update(block)
                if h.hexdigest()!=row['sha256']:raise ValueError('Member hash mismatch: '+row['path'])
            # Reading each member to EOF also checks its CRC; check the small notice too.
            z.read('DATA-NOTICE.txt')
    return {'status':'PASS','files':len(files),'archive_sha256':info['sha256'],'full_file_hashes_and_crc':full}

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument('--archive',required=True)
    ap.add_argument('--manifest',required=True)
    ap.add_argument('--full',action='store_true')
    args=ap.parse_args()
    print(json.dumps(verify(args.archive,args.manifest,args.full)))

if __name__=='__main__':main()
