"""Tests for cy_lua_unpack.py. Run: python -B Tools/pipeline/test_cy_lua_unpack.py"""
import hashlib
import os
import struct
import sys
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, '..', '..', 'Docs', 'evidence', 'assetinv'))
import cy_lua_unpack as U  # noqa: E402

S4_INTERFACE = r'C:\TLBB\085\Tools\DATA NEW\CY Game\Data\Interface.axp'


class RijndaelVectors(unittest.TestCase):
    def test_fips197_aes128(self):
        k = bytes(range(16))
        p = bytes.fromhex('00112233445566778899aabbccddeeff')
        self.assertEqual(U.rijndael_encrypt(p, k).hex(), '69c4e0d86a7b0430d8cdb78070b4c55a')
        self.assertEqual(U.rijndael_decrypt(bytes.fromhex('69c4e0d86a7b0430d8cdb78070b4c55a'), k), p)

    def test_fips197_aes192(self):
        k = bytes(range(24))
        p = bytes.fromhex('00112233445566778899aabbccddeeff')
        self.assertEqual(U.rijndael_encrypt(p, k).hex(), 'dda97ca4864cdfe06eaf70a0ec0d7191')

    def test_block24_roundtrip(self):
        k = U.game_key()
        for seed in range(8):
            blk = hashlib.sha256(bytes([seed])).digest()[:24]
            self.assertEqual(U.rijndael_decrypt(U.rijndael_encrypt(blk, k), k), blk)

    def test_sbox(self):
        self.assertEqual(U.SBOX[:4], [0x63, 0x7C, 0x77, 0x7B])   # Game.exe 0x140c674f0
        self.assertEqual(U.INV[0x63], 0)


class Container(unittest.TestCase):
    def test_key(self):
        self.assertEqual(U.game_key()[:16], b'ASDRTFYUIOGHJKLm')
        self.assertEqual(len(U.game_key()), 24)

    def test_roundtrip(self):
        src = ('-- ' + 'x' * 300 + '\nfunction A_OnLoad()\nend\n').encode()
        p = U.pack(src)
        self.assertTrue(U.is_packed(p))
        self.assertEqual(struct.unpack_from('<5I', p, 0), (0xE1E2D1D2, 0xC1C2B1B2, 1, 2, 16))
        self.assertEqual(U.unpack(p), src)

    def test_crc_rejects(self):
        p = bytearray(U.pack(b'a' * 64))
        p[0x80] ^= 0x40
        self.assertIsNone(U.unpack(bytes(p)))

    def test_plain_passthrough(self):
        self.assertIsNone(U.unpack(b'local a = 1\n' * 40))

    def test_short(self):
        with self.assertRaises(ValueError):
            U.pack(b'short')


@unittest.skipUnless(os.path.exists(S4_INTERFACE), 'CY 3.71 Interface.axp not present')
class RealArchive(unittest.TestCase):
    def test_all_packed_decode_to_source(self):
        import axp_index as AX
        a = AX.Axp(S4_INTERFACE)
        n = ok = 0
        for name, _ in a.file_list():
            if not name.lower().endswith('.lua'):
                continue
            alg, data = a.payload_full(name, 64 << 20)
            if data[:8] != U.MAGIC:
                continue
            n += 1
            plain = U.unpack(data)
            self.assertIsNotNone(plain, name)
            self.assertEqual(U.looks_like_lua(plain), 'source', name)
            # re-pack with the original filler bytes must reproduce the file byte for byte
            self.assertEqual(U.pack(plain, data[0x14:0xFC]), data, name)
            ok += 1
        self.assertEqual(n, 226)
        self.assertEqual(ok, 226)


if __name__ == '__main__':
    unittest.main(verbosity=2)
