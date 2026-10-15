"""Run a pinned bounded activity probe on the verified private Game console."""
from pathlib import Path
import hashlib,json,re,socket,time
import provision_test_wsl as p
from give_item import connected
p.guard();assert not connected()
spec=next(s for s in p.role_specs() if s['name']=='Game')
processes=p.owned_processes(spec);assert len(processes)==1
identity=(processes[0]['pid'],processes[0]['start_ticks'])
root=Path('/mnt/c/TLBB/085/CY-Source');script=root/'Tools/server/cangjingge_live.lua'
assert script.is_file() and not script.is_symlink()
command=('run local f=assert(io.open("'+str(script)+'","rb")); local s=f:read(65537); f:close(); assert(#s<=65536); return assert(load(s,"@cangjingge_live","t"))()\n').encode('ascii')
with socket.create_connection(('127.0.0.1',16002),timeout=5) as sock:
 sock.settimeout(.5);greeting=b'';deadline=time.monotonic()+5
 while b'Welcome' not in greeting and time.monotonic()<deadline:
  try:greeting+=sock.recv(4096)
  except socket.timeout:pass
 assert b'Welcome' in greeting
 sock.sendall(command);raw=b'';deadline=time.monotonic()+40
 while time.monotonic()<deadline:
  try:raw+=sock.recv(4096)
  except socket.timeout:pass
  if b'<CMD OK>' in raw or b'<CMD Error>' in raw:break
after=p.owned_processes(spec);assert len(after)==1 and (after[0]['pid'],after[0]['start_ticks'])==identity
found=re.search(rb'CYS-CJG (PASS|FAIL) ([a-zA-Z0-9=,;\-]+)',raw)
result=dict(passed=bool(found and found[1]==b'PASS' and b'<CMD OK>' in raw),
            result=found[0].decode('ascii') if found else 'No bounded result marker',
            script_sha256=hashlib.sha256(script.read_bytes()).hexdigest(),game_pid=identity[0])
(root/'Build/Logs/2026-09-29-cangjingge/live-result.json').write_text(json.dumps(result,indent=2))
print(json.dumps(result));assert result['passed']
