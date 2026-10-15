"""Replay the reviewed catalog bytes on the private clone only. Default: verify/dry-run.

Run under WSL with Python 3 and GNU patch. No server restart or database write.
"""
from pathlib import Path
import argparse, base64, datetime, hashlib, json, subprocess, tempfile

HERE = Path(__file__).resolve().parent
ALLOWED = Path('/home/ubuntu/cys-test-20260913')

def sha(data):
    return hashlib.sha256(data).hexdigest()

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, default=ALLOWED)
    parser.add_argument('--apply', action='store_true')
    parser.add_argument('--part', choices=['catalog', 'jiyuan'], default='catalog')
    args = parser.parse_args()
    root = args.root.resolve(strict=True)
    if root != ALLOWED:
        parser.error('Only /home/ubuntu/cys-test-20260913 is authorized; original server is read-only.')
    manifest_name = 'manifest.json' if args.part == 'catalog' else 'jiyuan-manifest.json'
    manifest = json.loads((HERE / manifest_name).read_text(encoding='utf-8'))
    originals, states, patches = {}, [], {}
    for entry in manifest['files']:
        rel = entry['path']
        # Nested unified diffs can lose CR bytes when the outer source patch is applied. The canonical
        # payload is base64 so source-control newline normalization cannot change the GBK/CRLF patch.
        encoded = (HERE / entry['patch_base64']).read_bytes()
        patch_data = base64.b64decode(b''.join(encoded.split()), validate=True)
        if sha(patch_data) != entry['patch_sha256']:
            raise RuntimeError('Patch fingerprint mismatch: ' + entry['patch_base64'])
        patches[rel] = patch_data
        target = (root / rel).resolve(strict=True)
        if root not in target.parents or target.is_symlink():
            raise RuntimeError('Unsafe target: ' + rel)
        data = target.read_bytes()
        digest = sha(data)
        if digest not in (entry['before_sha256'], entry['after_sha256']):
            raise RuntimeError('Unreviewed input hash: ' + rel + ' ' + digest)
        states.append(digest == entry['after_sha256'])
        originals[rel] = data
    if all(states):
        print('ALREADY APPLIED: all files match the reviewed output hashes.')
        return
    if any(states):
        raise RuntimeError('Mixed old/new input; restore a consistent set from backup before replay.')
    proposed = {}
    with tempfile.TemporaryDirectory(prefix='cys-nbshop-') as folder:
        temporary = Path(folder)
        for rel, data in originals.items():
            target = temporary / rel
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(data)
        for entry in manifest['files']:
            patch_data = patches[entry['path']]
            result = subprocess.run(['patch', '--batch', '--fuzz=0', '--no-backup-if-mismatch', '-p1', '-d', str(temporary)], input=patch_data, capture_output=True)
            if result.returncode:
                raise RuntimeError('Patch failed: ' + result.stdout.decode(errors='replace') + result.stderr.decode(errors='replace'))
            data = (temporary / entry['path']).read_bytes()
            if sha(data) != entry['after_sha256']:
                raise RuntimeError('Output hash mismatch: ' + entry['path'])
            # Strict round trip ensures the table remains GBK and the Lua source remains UTF-8.
            if data.decode(entry['encoding']).encode(entry['encoding']) != data:
                raise RuntimeError('Encoding round trip failed: ' + entry['path'])
            proposed[entry['path']] = data
    if not args.apply:
        print('DRY RUN PASS: exact input/output hashes, zero fuzz, encoding round trips; clone unchanged.')
        return
    stamp = datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%dT%H%M%S%fZ')
    backup = root / 'backups' / ('nbshop-' + stamp)
    backup.mkdir(parents=True, exist_ok=False)
    for rel, data in originals.items():
        if (root / rel).read_bytes() != data:
            raise RuntimeError('File changed during preparation: ' + rel)
        target = backup / rel
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(data)
    (backup / 'manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding='utf-8')
    # Both backups precede the first mutation. A failure restores the exact pair.
    try:
        for rel, data in proposed.items():
            (root / rel).write_bytes(data)
        for entry in manifest['files']:
            if sha((root / entry['path']).read_bytes()) != entry['after_sha256']:
                raise RuntimeError('Post-write hash mismatch: ' + entry['path'])
    except Exception:
        for rel, data in originals.items():
            (root / rel).write_bytes(data)
        raise
    print('APPLIED; backup=' + str(backup))
    print('Server restart and runtime checks remain coordinator-owned.')

if __name__ == '__main__':
    main()
