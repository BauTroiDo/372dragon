"""Reapply reviewed coordinate edits without overwriting later faction fixes.

Only the private clone is writable. All hashes and Lua syntax are checked before
any write; backups cover every changed file. Undo changes coordinates only.
"""
from pathlib import Path
import datetime,hashlib,json,os,shutil,subprocess,tempfile

ROOT=Path('/home/ubuntu/cys-test-20260913')
HERE=Path(__file__).resolve().parent
def sha(data):return hashlib.sha256(data).hexdigest()

def prepare(data,entry,action):
    if sha(data) not in entry['approved_sha256']:
        raise RuntimeError('Unreviewed file hash: '+entry['path'])
    old,new=entry['old'].encode(),entry['new'].encode()
    if data.count(old)+data.count(new)!=1:
        raise RuntimeError('Unexpected coordinate occurrence: '+entry['path'])
    result=data.replace(old,new) if action=='apply' else data.replace(new,old) if action=='undo' else data
    if sha(result) not in entry['approved_sha256']:
        raise RuntimeError('Unreviewed output hash: '+entry['path'])
    return result

def run(group,action='kiem'):
    if action not in ('kiem','apply','undo'):raise SystemExit('Usage: kiem | apply | undo')
    root=ROOT.resolve(strict=True)
    if root!=ROOT:raise RuntimeError('Clone root must not redirect elsewhere')
    entries=[e for e in json.loads((HERE/'coordinate-manifest.json').read_text())['files'] if e['group']==group]
    if not entries:raise RuntimeError('Unknown coordinate group')
    changes=[]
    compiler=next((shutil.which(x) for x in ('luac5.4','luac5.3','luac') if shutil.which(x)),None)
    for entry in entries:
        target=root/entry['path']
        if target.is_symlink() or root not in target.resolve(strict=True).parents:raise RuntimeError('Unsafe target')
        before=target.read_bytes();after=prepare(before,entry,action)
        print(entry['path'],sha(before),'changed='+str(before!=after))
        if before!=after:changes.append((target,before,after,target.stat()))
    if not changes:return
    if not compiler:raise RuntimeError('luac required before changing server scripts')
    with tempfile.TemporaryDirectory(prefix='cys-coordinate-') as folder:
        for n,(_,_,after,_) in enumerate(changes):
            staged=Path(folder)/(str(n)+'.lua');staged.write_bytes(after)
            subprocess.run([compiler,'-p',str(staged)],check=True,capture_output=True)
    backup=root/'backups'/('teleport-coordinate-'+datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%dT%H%M%S%fZ'))
    backup.mkdir(parents=True,exist_ok=False)
    for target,before,_,_ in changes:
        if target.read_bytes()!=before:raise RuntimeError('File changed during preparation')
        saved=backup/target.relative_to(root);saved.parent.mkdir(parents=True,exist_ok=True);saved.write_bytes(before)
    (backup/'manifest.json').write_text(json.dumps({'action':action,'files':[{'path':str(p.relative_to(root)),'before_sha256':sha(b),'after_sha256':sha(a)} for p,b,a,_ in changes]},indent=2))
    def replace(target,data,st):
        fd,name=tempfile.mkstemp(prefix=target.name+'.',dir=target.parent)
        try:
            with os.fdopen(fd,'wb') as f:f.write(data)
            os.chmod(name,st.st_mode);os.chown(name,st.st_uid,st.st_gid);os.replace(name,target)
        finally:
            if os.path.exists(name):os.unlink(name)
    written=[]
    try:
        for target,before,after,st in changes:
            if target.read_bytes()!=before:raise RuntimeError('File drifted before write')
            written.append((target,before,st));replace(target,after,st)
            if target.read_bytes()!=after:raise RuntimeError('Read-back mismatch')
    except Exception:
        for target,before,st in reversed(written):replace(target,before,st)
        raise
    print('APPLIED coordinate-only change; backup='+str(backup)+'; restart remains coordinator-owned')
