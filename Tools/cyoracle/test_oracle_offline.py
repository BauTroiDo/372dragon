"""Offline test of cy_oracle_server.py with a fake client (no Game.exe).

Starts the oracle on free loopback ports, walks login -> char list -> char login -> game connect -> enter scene ->
base attrib -> move, and checks every reply against the Read() layouts of CY 3.71 Game.exe (sizes and key fields).
Usage: test_oracle_offline.py [--out DIR]   exit 0 = PASS
"""
import argparse
import os
import socket
import struct
import subprocess
import sys
import tempfile
import time

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from cy_oracle_server import IDS, NAMES  # noqa: E402


def free_port():
    s = socket.socket()
    s.bind(('127.0.0.1', 0))
    p = s.getsockname()[1]
    s.close()
    return p


class Client:
    def __init__(self, port):
        self.s = socket.create_connection(('127.0.0.1', port), timeout=5)
        self.seq = 0x7b
        self.buf = b''

    def send(self, name, body, prefix=True):
        pkt = struct.pack('<HI', IDS[name], (self.seq << 24) | len(body)) + body
        self.seq = (self.seq + 1) & 0xff
        self.s.sendall((b'TLBB01' if prefix else b'') + pkt)

    def expect(self, name):
        # next packet with this name; other packets are kept in order for later expects
        self.stash = getattr(self, 'stash', [])
        for i, (n, b) in enumerate(self.stash):
            if n == name:
                del self.stash[i]
                return n, b
        while True:
            n, b = self.recv()
            if n == name:
                return n, b
            self.stash.append((n, b))

    def recv(self):
        while True:
            if len(self.buf) >= 6:
                pid, packed = struct.unpack_from('<HI', self.buf, 0)
                size = packed & 0xffffff
                if len(self.buf) >= 6 + size:
                    body = self.buf[6:6 + size]
                    self.buf = self.buf[6 + size:]
                    return NAMES.get(pid, str(pid)), body
            d = self.s.recv(65536)
            if not d:
                raise ConnectionError('closed')
            self.buf += d


def check(cond, msg, fails):
    print(('PASS ' if cond else 'FAIL ') + msg)
    if not cond:
        fails.append(msg)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--out', default=None)
    a = ap.parse_args()
    out = a.out or tempfile.mkdtemp(prefix='cyoracle-test-')
    lp, gp = free_port(), free_port()
    import json
    sc = json.load(open(os.path.join(HERE, 'scenarios', 'dali.json'), encoding='utf-8'))
    sc['timeline'] = [{'t': 0.3, 'teleport': [170.0, 160.0], 'tag': 'tp'},
                      {'t': 0.5, 'skill': 493, 'target': 2002, 'damage': 1234, 'tag': 'skill'},
                      {'t': 0.7, 'world_time': {'time': 3, 'counter': 0, 'interval': 0}, 'tag': 'time'}]
    os.makedirs(out, exist_ok=True)
    scp = os.path.join(out, 'scenario-test.json')
    json.dump(sc, open(scp, 'w', encoding='utf-8'), ensure_ascii=False)
    proc = subprocess.Popen([sys.executable, '-B', os.path.join(HERE, 'cy_oracle_server.py'), '--out', out, '--scenario', scp,
                             '--login-port', str(lp), '--game-port', str(gp), '--max-seconds', '60'],
                            stdout=subprocess.DEVNULL, stderr=subprocess.STDOUT)
    fails = []
    try:
        for _ in range(50):
            try:
                c = Client(lp)
                break
            except OSError:
                time.sleep(0.1)
        c.send('CLConnect', b'\0' * 124)
        n, b = c.recv()
        check(n == 'LCRetConnect' and len(b) == 0x4a, f'LCRetConnect 74 B ({n} {len(b)})', fails)
        acct = b'oracletest'.ljust(50, b'\0')
        c.send('CLAskLogin', acct + b'\0' * (927 - 50 + 4))
        n, b = c.recv()
        check(n == 'LCRetLogin' and len(b) == 83 and struct.unpack_from('<i', b, 50)[0] == 0 and b[:10] == b'oracletest',
              f'LCRetLogin 83 B result 0 ({n} {len(b)})', fails)
        n, b = c.recv()
        check(n == 'LCStatus' and len(b) == 6 and struct.unpack_from('<i', b, 2)[0] == 2, f'LCStatus status 2 ({n})', fails)
        c.send('CLAskCharList', acct)
        n, b = c.recv()
        cnt = b[54] if len(b) > 54 else -1
        check(n == 'LCRetCharList' and len(b) == cnt * 0x1a4 + 0x50 and cnt == 1, f'LCRetCharList n*420+80 ({len(b)}, n={cnt})', fails)
        guid = struct.unpack_from('<I', b, 55)[0]
        c.send('CLAskCharLogin', struct.pack('<II', guid, 0) + b'\0' * 19)
        n, b = c.recv()
        k, ln = b[0], struct.unpack_from('<I', b, 1)[0]
        p = bytes((x - k) & 0xff for x in b[5:5 + ln])
        res, port = struct.unpack_from('<ii', p, 0)
        ip = p[8:32].split(b'\0')[0]
        check(n == 'LCRetCharLogin' and ln == 0x3e and len(b) == 5 + ln and res == 0 and port == gp and ip == b'127.0.0.1',
              f'LCRetCharLogin decoded result 0 -> {ip.decode()}:{port}', fails)
        g = Client(gp)
        g.send('CGConnect', b'\0' * 140)
        n, b = g.recv()
        sid, scene, x, z = struct.unpack_from('<hhff', b, 0)
        check(n == 'GCConnect' and len(b) == 18 and scene == 2, f'GCConnect 18 B scene {scene} pos ({x},{z})', fails)
        g.send('CGEnterScene', struct.pack('<HBff', scene, 0, x, z))
        n, b = g.recv()
        check(n == 'GCEnterScene' and len(b) == 52 and b[0] == 0 and struct.unpack_from('<h', b, 1)[0] == 2,
              f'GCEnterScene 52 B ok scene 2 obj {struct.unpack_from("<I", b, 13)[0]}', fails)
        myobj = struct.unpack_from('<I', b, 13)[0]
        mons = []
        for _ in range(5):
            n, b = g.expect('GCNewMonster')
            check(n == 'GCNewMonster' and len(b) == 0x74, f'GCNewMonster 116 B obj {struct.unpack_from("<I", b, 0)[0]}', fails)
            mons.append(struct.unpack_from('<I', b, 0)[0])
        for obj in (myobj, mons[0]):
            g.send('CGCharAskBaseAttrib', struct.pack('<I', obj))
            pk = []
            for _ in range(2):
                n, b = g.expect('GCCharBaseAttrib')
                key, ln = b[1], struct.unpack_from('<I', b, 2)[0]
                pay = bytes((v - key) & 0xff for v in b[6:6 + ln])
                pk.append((b[0], pay))
            (m1, p1), (m2, p2) = pk
            ok1 = m1 == 0x80 and struct.unpack_from('<I', p1, 0)[0] == obj and p1[5:13] == bytes([0, 0, 0, 8, 0, 0, 0, 0]) and len(p1) == 23
            race = struct.unpack_from('<I', p2, 23)[0]
            nl = p2[27]
            name = p2[28:28 + nl].decode('gbk')
            lv, hp = p2[28 + nl], p2[29 + nl]
            ok2 = m2 == 0x80 and p2[5] == 0x1b and p2[8] == 8 and len(p2) == 30 + nl + (24 if obj == myobj else 0)
            check(ok1 and ok2, f'GCCharBaseAttrib sync+race obj {obj} race {race} name {name} lv {lv} hp {hp}', fails)
        g.send('CGCharAskEquipment', struct.pack('<I', myobj))
        n, b = g.expect('GCCharEquipment')
        check(len(b) == 12 + 10 + 6 + 10 + 6 + 6 + 18 and struct.unpack_from('<I', b, 8)[0] == 0x1001f,
              f'GCCharEquipment self parts (no equip_sync) {len(b)} B', fails)
        path = struct.pack('<ff', 165.0, 152.0)
        g.send('CGCharMove', struct.pack('<ii', 1, myobj) + struct.pack('<ff', x, z) + bytes([1, 0]) + path)
        n, b = g.expect('GCCharMove')
        check(n == 'GCCharMove' and len(b) == 10 + 8 * b[5] and b[5] == 1 and b[10 - 0:18] == path,
              f'GCCharMove echo {len(b)} B', fails)
        n, b = g.expect('GCObjTeleport')
        check(len(b) == 24 and struct.unpack_from('<Iff', b, 0) == (myobj, 170.0, 160.0), f'GCObjTeleport 24 B', fails)
        n, b = g.expect('GCCharSkill_Send')
        check(len(b) == 17 and struct.unpack_from('<IIIi', b, 0)[2:] == (493, 2002), f'GCCharSkill_Send 17 B skill 493 -> 2002', fails)
        n, b = g.expect('GCDetailHealsAndDamages')
        check(len(b) == 19 and b[0] == 1 and struct.unpack_from('<i', b, 13)[0] == -1234, 'GCDetailHealsAndDamages hp -1234', fails)
        n, b = g.expect('GCWorldTime')
        check(len(b) == 12, 'GCWorldTime 12 B', fails)
        g.s.close()
        c.s.close()
        time.sleep(0.3)
        log = open(os.path.join(out, 'frames.tsv'), encoding='utf-8').read()
        check('TLBB01' in log, 'prefix TLBB01 stripped and logged', fails)
        redacted = [l for l in log.splitlines() if '\tCLAskLogin\t' in l or '\tCGConnect\t' in l]
        check(all(l.rstrip('\n').split('\t')[8] == '' for l in redacted), 'bodies of CLAskLogin/CGConnect not logged', fails)
    finally:
        open(os.path.join(out, 'stop'), 'w').close()
        try:
            proc.wait(10)
        except subprocess.TimeoutExpired:
            proc.kill()
    print('RESULT', 'PASS' if not fails else f'FAIL ({len(fails)})', 'out', out)
    return 0 if not fails else 1


if __name__ == '__main__':
    sys.exit(main())
