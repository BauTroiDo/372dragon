"""Create private configurations in a new server copy. Does not start services."""
import argparse
import json
import os
from pathlib import Path
import secrets

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument('--server-root',required=True)
    args=ap.parse_args()
    root=Path(args.server_root).resolve(strict=True)
    normalized=str(root).replace('\\','/').rstrip('/').lower()
    if normalized in {'/home/ubuntu/cys-test-20260913',
                      '//wsl.localhost/tlbb/home/ubuntu/cys-test-20260913',
                      '//wsl$/tlbb/home/ubuntu/cys-test-20260913'}:
        raise SystemExit('Use a separate new installation; refusing the original private server root.')
    templates=sorted(root.rglob('*.template'))
    if not templates:raise SystemExit('No configuration templates found')
    destinations=[p.with_suffix('') for p in templates]
    if any(p.exists() for p in destinations):raise SystemExit('A destination configuration already exists; nothing written')
    secret=secrets.token_hex(32)
    local=root/'.local'
    local.mkdir(mode=0o700,exist_ok=True)
    record=local/'setup-secrets.json'
    if record.exists():raise SystemExit('Setup secrets already exist; nothing replaced')
    with open(record,'x',encoding='utf-8') as f:
        os.chmod(record,0o600)
        json.dump({'mongo_username':'cys_test','mongo_password':secret},f,indent=2)
    for src,dst in zip(templates,destinations):
        # Preserve legacy encodings and line endings outside the ASCII placeholders.
        data=src.read_bytes().replace(b'CHANGE_ME_GENERATE_LOCALLY',secret.encode('ascii'))
        data=data.replace(b'/home/ubuntu/cys-test-20260913',root.as_posix().encode('utf-8'))
        with open(dst,'xb') as f:
            os.chmod(dst,0o600);f.write(data)
    print(f'Created {len(templates)} configurations. Local secret file: {record}')
    print('No services started. Create the MongoDB user locally and follow INSTALL-NOTES.md.')

if __name__=='__main__':main()
