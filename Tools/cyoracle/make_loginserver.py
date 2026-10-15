"""Rewrite Patch/LoginServer.txt of a PRIVATE CY 3.71 copy so its only server points at the local oracle.

LoginServer.txt is "SEPCIAL_FILE_HD" mode 1: 0x60-byte header and payload XOR a 128-byte key from MSVC rand() seeded
0x19830716 (reversed for the 0.85 client, analysis/utf8-baseline/manifest/loginserver_crypt.py; the CY 3.71 file
decrypts with the same key, magic and mode). The CY plaintext is GBK CSV:
  area,server,?,id,status,?,?,welcome,login ip:port,addr2,addr3,addr4,?,?,version,11 x flags
The template row is the real "轻享-轻享大区,桃花源" row (shown under "推荐服务器" in the stock client) with every address
replaced by 127.0.0.1:<port> and the name changed; nothing else is invented.

Usage: make_loginserver.py <CYRoot> <port> [--name NAME]
The original file is kept once as Patch/LoginServer.txt.orig (never overwritten). Refuses paths under Tools/DATA NEW.
"""
import argparse
import os
import struct
import sys

HDR = 0x60
CRLF, LF, TAB = bytes([13, 10]), bytes([10]), bytes([9])
MAGIC = b'SEPCIAL_FILE_HD\x00'


def make_key(seed):
    s = seed & 0xffffffff
    out = bytearray(128)
    for i in range(128):
        s = (s * 214013 + 2531011) & 0xffffffff
        v = (s >> 16) & 0x7fff
        out[i] = (v + v // 255) & 0xff
    return bytes(out)


KEY1 = make_key(0x19830716)


def decrypt(data):
    hdr = bytes(data[k] ^ KEY1[k & 0x7f] for k in range(HDR))
    if hdr[:16] != MAGIC:
        raise SystemExit('bad magic')
    mode = struct.unpack_from('<i', hdr, 0x10)[0]
    if mode != 1:
        raise SystemExit(f'mode {mode} not supported')
    pay = data[HDR:]
    return hdr, bytes(pay[i] ^ KEY1[(i + HDR) & 0x7f] for i in range(len(pay)))


def encrypt(hdr, plain):
    return bytes(hdr[k] ^ KEY1[k & 0x7f] for k in range(HDR)) + bytes(
        plain[i] ^ KEY1[(i + HDR) & 0x7f] for i in range(len(plain)))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('root')
    ap.add_argument('port', type=int)
    ap.add_argument('--name', default='cyoracle')
    ap.add_argument('--area', default='ORACLE', help='ASCII keeps Bin/System.cfg Login_Area byte-exact')
    ap.add_argument('--status', type=int, default=1, help='field 4 (server load colour); the template row has 0')
    a = ap.parse_args()
    root = os.path.abspath(a.root)
    if 'DATA NEW' in root:
        raise SystemExit('refusing the original CY client')
    path = os.path.join(root, 'Patch', 'LoginServer.txt')
    orig = path + '.orig'
    if not os.path.exists(orig):
        with open(path, 'rb') as f, open(orig, 'wb') as g:
            g.write(f.read())
    hdr, plain = decrypt(open(orig, 'rb').read())
    text = plain.decode('gbk')
    template = None
    for line in text.splitlines():
        p = line.split(',')
        if len(p) >= 26 and p[0] == '轻享-轻享大区':
            template = p
            break
    if template is None:
        raise SystemExit('template row not found')
    addr = f'127.0.0.1:{a.port}'
    row = list(template)
    row[0] = a.area
    row[1] = a.name
    row[4] = str(a.status)
    row[8:12] = [addr] * 4
    out = ('VERSION 1\r\n\r\nSERVER_BEGIN\r\n' + ','.join(row) + '\r\nSERVER_END\r\nMIBAODH_BEGIN\r\nMIBAODH_END\r\n'
           'RECOMMENDAREA_BEGIN\r\n' + row[0] + ',1\r\nRECOMMENDAREA_END\r\n')
    if '\r\n' not in text:
        out = out.replace('\r\n', '\n')
    data = encrypt(hdr, out.encode('gbk'))
    with open(path, 'wb') as f:
        f.write(data)
    check = decrypt(data)[1].decode('gbk')
    non_loopback = [x for x in check.replace('\n', ',').split(',') if ':' in x and not x.startswith('127.0.0.1:')]
    print(f'{path}: {len(data)} B, row: {",".join(row)}; non-loopback addresses {len(non_loopback)}')
    if non_loopback:
        raise SystemExit('non-loopback address left')
    # Preselect this server: CY Game.exe FUN_14062a8c0 matches the variables Login_Area / Login_Server against the list and
    # then jumps the login procedure straight to the account page (state 3), so no click on the server list is needed.
    cfg = os.path.join(root, 'Bin', 'System.cfg')
    raw = open(cfg, 'rb').read()
    nl = CRLF if CRLF in raw else LF
    lines = [x for x in raw.split(nl) if not x.lstrip().startswith((b'Login_Area', b'Login_Server'))]
    at = next(i for i, x in enumerate(lines) if x.strip() == b'[Variable]') + 1
    lines[at:at] = [b'Login_Area' + TAB + b'=' + a.area.encode('ascii'), b'Login_Server' + TAB + b'=' + a.name.encode('ascii')]
    open(cfg, 'wb').write(nl.join(lines))
    print(f'{cfg}: Login_Area={a.area} Login_Server={a.name}')


if __name__ == '__main__':
    main()
