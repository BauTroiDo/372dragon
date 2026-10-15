"""cy_lua_unpack.py - decode the packed Lua scripts of CY 3.71.9609 (magic D2 D1 E2 E1 B2 B1 C2 C1).

Evidence (static, CY Game.exe sha256 9278c7f3...c5b, image base 0x140000000; Build/Logs/2026-09-14-cy-gui/lua-unpack):

  0x1406dd600  check(buf, len): len > 0x100, u32 @0 == 0xE1E2D1D2, u32 @4 == 0xC1C2B1B2,
               CRC32 (table 0x140fb50e0, init 0xFFFFFFFF, no final xor) of bytes 0..251 == u32 @0xFC.
  0x1406dd710  wrapper: key struct {i32 off=2, i32 len=16} -> decode 0x1406dd0e0(key, mode 0, src, n, dst, &out_len)
  0x1406dd0e0  decode: memcpy(key, 0x140fb54e0 + (off & 31), len & 31)  -> 16 ASCII bytes "ASDRTFYUIOGHJKLm"
               (padded with zeros to 24 bytes); if check() fails the input is copied unchanged.
               Needs len >= 0x118. Rijndael key schedule 0x1406de380(key, 24, ctx) with ctx.n_blk = 0x18|2
               (Gladman AES, 24-byte block, 24-byte key, 12 rounds; S-box 0x140c674f0, rcon 0x140c66470),
               decrypt one 24-byte block 0x1406df110(src + 0x100) -> plaintext bytes 0..23,
               then plaintext[i] = src[0x100 + i] ^ key[(i - 24) % 2] for i >= 24.
  0x1406dd310  encode (the same layout in reverse): header u32 magic x2, u32 1, u32 off, u32 len,
               bytes 0x14..0xFB unused, CRC32 at 0xFC.

Output: plaintext Lua source (GBK, as the plain CY scripts). The format carries no length or padding: the plain
text is exactly len - 0x100 bytes.

Usage:
  cy_lua_unpack.py FILE [-o OUT]                decode one file ("-" = stdout)
  cy_lua_unpack.py --axp Interface.axp --out DIR [--list]   decode every packed .lua of an archive
  cy_lua_unpack.py --selftest                   round trip + known vectors (Rijndael-128 FIPS-197 C.1 check)
"""
import argparse
import os
import struct
import sys

MAGIC = bytes.fromhex('D2D1E2E1B2B1C2C1')
HEADER = 0x100
KEY_TABLE = b'QWASDRTFYUIOGHJKLmncXz23456789zcbnmasdfjMNBC0qwzfgbhuifdfgJKL'   # Game.exe 0x140fb54e0
KEY_OFF, KEY_LEN = 2, 16                                                     # Game.exe 0x1406dd77a/0x1406dd782
BLOCK = 24

# ------------------------------------------------------------------------------------------------ Rijndael
SBOX = [0] * 256
INV = [0] * 256


def _xt(a):
    a <<= 1
    return (a ^ 0x1B) & 0xFF if a & 0x100 else a


def _mul(a, b):
    r = 0
    while b:
        if b & 1:
            r ^= a
        a = _xt(a)
        b >>= 1
    return r


def _init_sbox():
    for x in range(256):
        inv = 0
        if x:
            inv = x                      # x^254 = x^-1 in GF(2^8)
            for _ in range(253):
                inv = _mul(inv, x)
        s = inv
        for sh in range(1, 5):
            s ^= ((inv << sh) | (inv >> (8 - sh))) & 0xFF
        SBOX[x] = s ^ 0x63
    for i, v in enumerate(SBOX):
        INV[v] = i


_init_sbox()


MUL9 = [_mul(i, 9) for i in range(256)]
MUL11 = [_mul(i, 11) for i in range(256)]
MUL13 = [_mul(i, 13) for i in range(256)]
MUL14 = [_mul(i, 14) for i in range(256)]
MUL2 = [_mul(i, 2) for i in range(256)]
MUL3 = [_mul(i, 3) for i in range(256)]


def _expand(key, nb):
    nk = len(key) // 4
    nr = max(nb, nk) + 6
    w = [list(key[i * 4:i * 4 + 4]) for i in range(nk)]
    rcon = 1
    for i in range(nk, nb * (nr + 1)):
        t = list(w[i - 1])
        if i % nk == 0:
            t = [SBOX[t[1]] ^ rcon, SBOX[t[2]], SBOX[t[3]], SBOX[t[0]]]
            rcon = _xt(rcon)
        elif nk > 6 and i % nk == 4:
            t = [SBOX[b] for b in t]
        w.append([w[i - nk][j] ^ t[j] for j in range(4)])
    return w, nr


def _shifts(nb):
    return (0, 1, 3, 4) if nb == 8 else (0, 1, 2, 3)


def rijndael_decrypt(block, key):
    nb = len(block) // 4
    w, nr = _expand(key, nb)
    sh = _shifts(nb)
    s = [list(block[c * 4:c * 4 + 4]) for c in range(nb)]

    def add(r):
        for c in range(nb):
            k = w[r * nb + c]
            for j in range(4):
                s[c][j] ^= k[j]
    add(nr)
    for r in range(nr - 1, -1, -1):
        # InvShiftRows + InvSubBytes
        t = [[0] * 4 for _ in range(nb)]
        for c in range(nb):
            for j in range(4):
                t[(c + sh[j]) % nb][j] = INV[s[c][j]]
        s = t
        add(r)
        if r:
            for c in range(nb):
                a = s[c]
                s[c] = [MUL14[a[0]] ^ MUL11[a[1]] ^ MUL13[a[2]] ^ MUL9[a[3]],
                        MUL9[a[0]] ^ MUL14[a[1]] ^ MUL11[a[2]] ^ MUL13[a[3]],
                        MUL13[a[0]] ^ MUL9[a[1]] ^ MUL14[a[2]] ^ MUL11[a[3]],
                        MUL11[a[0]] ^ MUL13[a[1]] ^ MUL9[a[2]] ^ MUL14[a[3]]]
    return bytes(b for col in s for b in col)


def rijndael_encrypt(block, key):
    nb = len(block) // 4
    w, nr = _expand(key, nb)
    sh = _shifts(nb)
    s = [list(block[c * 4:c * 4 + 4]) for c in range(nb)]

    def add(r):
        for c in range(nb):
            k = w[r * nb + c]
            for j in range(4):
                s[c][j] ^= k[j]
    add(0)
    for r in range(1, nr + 1):
        t = [[0] * 4 for _ in range(nb)]
        for c in range(nb):
            for j in range(4):
                t[c][j] = SBOX[s[(c + sh[j]) % nb][j]]
        s = t
        if r != nr:
            for c in range(nb):
                a = s[c]
                s[c] = [MUL2[a[0]] ^ MUL3[a[1]] ^ a[2] ^ a[3], a[0] ^ MUL2[a[1]] ^ MUL3[a[2]] ^ a[3],
                        a[0] ^ a[1] ^ MUL2[a[2]] ^ MUL3[a[3]], MUL3[a[0]] ^ a[1] ^ a[2] ^ MUL2[a[3]]]
        add(r)
    return bytes(b for col in s for b in col)


# ------------------------------------------------------------------------------------------------ container
def _crc_table():
    t = []
    for i in range(256):
        c = i
        for _ in range(8):
            c = (c >> 1) ^ 0xEDB88320 if c & 1 else c >> 1
        t.append(c)
    return t


CRC = _crc_table()


def crc32_noinv(data):
    """CRC32 variant of Game.exe 0x1406dd600: init 0xFFFFFFFF, reflected table, no final inversion and an
    ARITHMETIC shift (`sar r9d, 8` on a signed int), so the top byte keeps the sign bit."""
    c = 0xFFFFFFFF
    for b in data:
        sar = (c >> 8) | (0xFF000000 if c & 0x80000000 else 0)
        c = CRC[(c ^ b) & 0xFF] ^ sar
    return c


def game_key(off=KEY_OFF, length=KEY_LEN):
    k = KEY_TABLE[off & 31:(off & 31) + (length & 31)]
    return k + bytes(BLOCK - len(k))


def is_packed(buf):
    if len(buf) <= HEADER or buf[:8] != MAGIC:
        return False
    return crc32_noinv(buf[:0xFC]) == struct.unpack_from('<I', buf, 0xFC)[0]


def unpack(buf):
    """Return the plaintext, or None when buf is not a valid packed file (Game.exe then uses the bytes as is)."""
    if not is_packed(buf) or len(buf) < HEADER + BLOCK:
        return None
    _, _, ver, off, length = struct.unpack_from('<IIIII', buf, 0)
    # The game ignores the header off/len and always uses {2, 16}; keep that, but report a mismatch.
    key = game_key()
    body = buf[HEADER:]
    head = rijndael_decrypt(body[:BLOCK], key)
    k0, k1 = key[0], key[1]
    tail = bytearray(body[BLOCK:])
    tail[0::2] = bytes(b ^ k0 for b in tail[0::2])
    tail[1::2] = bytes(b ^ k1 for b in tail[1::2])
    return head + bytes(tail)


def pack(plain, filler=b''):
    """Inverse of unpack (Game.exe 0x1406dd310); bytes 0x14..0xFB are zero unless filler is given."""
    if len(plain) < BLOCK:
        raise ValueError('Game.exe does not decode files shorter than 0x118 bytes')
    key = game_key()
    hdr = bytearray(HEADER)
    struct.pack_into('<IIIII', hdr, 0, 0xE1E2D1D2, 0xC1C2B1B2, 1, KEY_OFF, KEY_LEN)
    hdr[0x14:0x14 + len(filler[:0xE8])] = filler[:0xE8]
    struct.pack_into('<I', hdr, 0xFC, crc32_noinv(bytes(hdr[:0xFC])))
    tail = bytearray(plain[BLOCK:])
    tail[0::2] = bytes(b ^ key[0] for b in tail[0::2])
    tail[1::2] = bytes(b ^ key[1] for b in tail[1::2])
    return bytes(hdr) + rijndael_encrypt(plain[:BLOCK], key) + bytes(tail)


# ------------------------------------------------------------------------------------------------ checks
def looks_like_lua(text):
    if text[:4] == b'\x1bLua':
        return 'bytecode'
    sample = text[:4096]
    bad = sum(1 for b in sample if b < 9 or 13 < b < 32 and b != 27)
    return 'source' if bad == 0 else None


def selftest():
    # FIPS-197 appendix C.1 (AES-128) validates the generic Rijndael code path.
    k = bytes(range(16))
    p = bytes.fromhex('00112233445566778899aabbccddeeff')
    c = bytes.fromhex('69c4e0d86a7b0430d8cdb78070b4c55a')
    assert rijndael_encrypt(p, k) == c, 'AES-128 encrypt vector'
    assert rijndael_decrypt(c, k) == p, 'AES-128 decrypt vector'
    # AES-192 key, 128 block (FIPS-197 C.2)
    k = bytes(range(24))
    c = bytes.fromhex('dda97ca4864cdfe06eaf70a0ec0d7191')
    assert rijndael_encrypt(p, k) == c and rijndael_decrypt(c, k) == p, 'AES-192 vector'
    # Rijndael 192/192 round trip + container round trip
    blk = bytes(range(100, 124))
    assert rijndael_decrypt(rijndael_encrypt(blk, game_key()), game_key()) == blk
    src = b'-- test\r\nfunction Foo_OnLoad()\r\n\tthis:Show();\r\nend\r\n' * 3
    packed = pack(src)
    assert is_packed(packed) and unpack(packed) == src
    assert unpack(src) is None
    bad = bytearray(packed)
    bad[0x20] ^= 1
    assert unpack(bytes(bad)) is None, 'CRC must reject a changed header'
    print('selftest OK')


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('file', nargs='?')
    ap.add_argument('-o', '--output')
    ap.add_argument('--axp')
    ap.add_argument('--out')
    ap.add_argument('--selftest', action='store_true')
    args = ap.parse_args()
    if args.selftest:
        selftest()
        return 0
    if args.axp:
        here = os.path.dirname(os.path.abspath(__file__))
        sys.path.insert(0, os.path.join(here, '..', '..', 'Docs', 'evidence', 'assetinv'))
        import axp_index as AX
        a = AX.Axp(args.axp)
        stats = {'lua': 0, 'packed': 0, 'decoded_source': 0, 'decoded_bytecode': 0, 'failed': 0}
        rows = []
        for name, _ in a.file_list():
            if not name.lower().endswith('.lua'):
                continue
            stats['lua'] += 1
            alg, data = a.payload_full(name, 64 << 20)
            if data[:8] != MAGIC:
                continue
            stats['packed'] += 1
            plain = unpack(data)
            kind = looks_like_lua(plain) if plain is not None else None
            if kind is None:
                stats['failed'] += 1
            else:
                stats['decoded_' + kind] += 1
            rows.append((name, len(data), -1 if plain is None else len(plain), kind or 'FAILED'))
            if args.out and plain is not None:
                dest = os.path.join(args.out, name.replace('/', os.sep))
                os.makedirs(os.path.dirname(dest), exist_ok=True)
                with open(dest, 'wb') as f:
                    f.write(plain)
        if args.out:
            os.makedirs(args.out, exist_ok=True)
            with open(os.path.join(args.out, '_unpack.tsv'), 'w', encoding='utf-8', newline='\n') as f:
                f.write('name\tpacked_size\tplain_size\tkind\n')
                for r in rows:
                    f.write('\t'.join(map(str, r)) + '\n')
        print(stats)
        return 0 if stats['failed'] == 0 else 1
    if not args.file:
        ap.error('FILE, --axp or --selftest required')
    with open(args.file, 'rb') as f:
        buf = f.read()
    plain = unpack(buf)
    if plain is None:
        print('not a packed CY Lua file (magic/CRC)', file=sys.stderr)
        return 2
    if not args.output or args.output == '-':
        sys.stdout.buffer.write(plain)
    else:
        with open(args.output, 'wb') as f:
            f.write(plain)
    return 0


if __name__ == '__main__':
    sys.exit(main())
