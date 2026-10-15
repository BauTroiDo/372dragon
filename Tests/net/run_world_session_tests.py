#!/usr/bin/env python3
"""World-session tests on owned dynamic loopback listeners (login + game).

Checks the charlogin hand-off, CGConnect as first game frame, one CGEnterScene
per socket, idx continuity across every socket, heartbeat, move, transfer,
CGAskQuit and failure paths, then replays the first world session of the
Aug-27 capture through the real GameClient/WorldModel. No WSL, no account, no
password: the fake credential never leaves RAM. Reports hold IDs/counters only.
"""
import argparse
import collections
import hashlib
import json
import os
from pathlib import Path
import random
import socket
import struct
import subprocess
import sys
import threading
import time

from run_netcore_tests import exact, frame, login_reply

CY = Path(__file__).resolve().parents[2]
GUID, KEY1, KEY2, MY1, MY2 = 200001, 0x13572468, 0x2468ACE0, 5001, 6002
SCENARIOS = ('enter-quit', 'transfer', 'transfer-refused', 'refuse-then-grant', 'bad-endpoint', 'bad-port',
             'silent-key', 'enter-timeout', 'peer-close-world', 'unsolicited-transfer', 'decode-failure',
             'quit-timeout', 'cancel-world', 'backpressure', 'rate', 'replay',
             'reply-port', 'unlisted-host',  # CYS: server profile policies (Patch/CysServerProfile.txt)
             'core-combat')  # CYS-CORE: skill list, lock, 3 hits, drop box, open, pick, chat, bag
CORE_KINDS = ('core-skill', 'core-kill', 'core-box', 'core-pick', 'core-bag', 'core-skills', 'core-chat')
TIPS = frame(397, struct.pack('<IH', 5, 11) + b'ERROR0001:x')
CREATE_IDS = {1340, 176, 21, 481, 1216, 395}


class Closed(Exception):
    pass


class Wire:
    """Server side of one client socket; records metadata of every client frame."""

    def __init__(self, connection, evidence, label):
        self.connection, self.evidence, self.label = connection, evidence, label

    def recv(self):
        try:
            packet_id, size, index = struct.unpack('<HHH', exact(self.connection, 6))
            body = bytes(exact(self.connection, size))
        except (EOFError, ConnectionResetError, ConnectionAbortedError):
            raise Closed()
        self.evidence['tx'].append([self.label, packet_id, index, size, round(time.monotonic(), 4)])
        return packet_id, index, body

    def expect(self, wanted, heartbeat=True):
        while True:
            packet_id, index, body = self.recv()
            if packet_id == 3 and heartbeat:
                assert not body, 'heartbeat body must be empty'
                self.evidence['heartbeats'] += 1
                continue
            assert packet_id == wanted, 'client sent %d while %d was expected' % (packet_id, wanted)
            return index, body

    def drain_to_close(self, allowed=(3,)):
        while True:
            try:
                packet_id, _, _ = self.recv()
            except Closed:
                return
            assert packet_id in allowed, 'client sent %d before closing' % packet_id
            if packet_id == 3:
                self.evidence['heartbeats'] += 1

    def send(self, data):
        self.connection.sendall(data)


def raw_frame(packet_id, index, body):
    return struct.pack('<HHH', packet_id, len(body), index) + body


def enter_body(scene, res, x, y, obj):
    return struct.pack('<BHHffIBBIIIH', 0, scene, res, x, y, obj, 0, 0, 0, 0, 0, 10)


def connect_frames(scene, x, y, result=0):
    return frame(67, struct.pack('<H', 8) + bytes(8)) + frame(456, struct.pack('<HHffH', result, scene, x, y, 0))


def notify_frame(source, target):
    return frame(809, struct.pack('<HHffBH', source, target, 100.0, 120.0, 9, target) + bytes(26) + bytes(24))


def transfer_frame(port, key):
    return frame(280, struct.pack('<B24sHI', 1, b'127.0.0.1'.ljust(24, b'\0'), port, key))


def charlogin_frame(ip, port, key):
    return frame(38, struct.pack('<II24sIBIHIII', 0, port, ip.ljust(24, b'\0'), key, 0x33, 0, 0xF, 0, 0, 0))


def login_phase(connection, evidence, scenario, fixtures, game_port):
    wire = Wire(connection, evidence, 'login')
    _, body = wire.expect(355, heartbeat=False)
    assert len(body) == 110 and body[4:54].split(b'\0', 1)[0] == b'unit-world', 'CLConnect'
    wire.send(frame(311, bytes(64)))
    _, body = wire.expect(299, heartbeat=False)
    assert len(body) == 949 and body[:50].split(b'\0', 1)[0] == b'unit-world%unit-value', 'CLAskLogin'
    wire.send(frame(223, login_reply()) + frame(554, bytes(6)))
    _, body = wire.expect(711, heartbeat=False)
    assert len(body) == 50, 'CLAskCharList'
    wire.send(fixtures['list1'])
    _, body = wire.expect(426, heartbeat=False)
    assert struct.unpack('<IH', body) == (GUID, 0), 'CLAskCharLogin carries the listed GUID and PlayerID 0'
    if scenario == 'refuse-then-grant':
        wire.send(TIPS)
        _, body = wire.expect(426, heartbeat=False)
        assert struct.unpack('<IH', body) == (GUID, 0), 'explicit retry'
    ip = b'10.0.0.5' if scenario == 'bad-endpoint' else b'127.0.0.2' if scenario == 'unlisted-host' else b'127.0.0.1'
    port = game_port + 1 if scenario == 'bad-port' else game_port
    wire.send(charlogin_frame(ip, port, KEY1))
    wire.drain_to_close(allowed=())  # the hand-off closes the login socket; nothing else is sent


def game_accept(listener, evidence, key, label):
    connection, _ = listener.accept()
    connection.settimeout(8)
    wire = Wire(connection, evidence, label)
    _, body = wire.expect(49, heartbeat=False)  # gamed.lua asserts CGConnect first
    assert len(body) == 108, 'CGConnect size'
    assert struct.unpack_from('<IIH', body) == (key, GUID, 0), 'CGConnect key and GUID'
    assert body[10:76] == bytes(66) and body[76:80] == b'tlbb' and body[80:108] == bytes(28), 'CGConnect fields'
    return connection, wire, body


def enter(wire, scene, x, y, obj, extra=b'', result=0):
    wire.send(connect_frames(scene, x, y, result))
    _, body = wire.expect(824)
    assert body == struct.pack('<HBff', scene, 0, 0.0, 0.0), 'CGEnterScene echoes the GCConnect scene'
    wire.send(frame(1764, enter_body(scene, scene, x, y, obj)) + extra)


def quit_ack(wire, close=True):
    _, body = wire.expect(1727)
    assert body == struct.pack('<IBII', 0, 0, 0, 0), 'CGAskQuit begins the quit tick'
    assert wire.evidence['heartbeats'] >= 2, 'heartbeats before quit'
    wire.send(frame(128, b'\0'))


def game_script(listener, scenario, evidence, fixtures, game_port, capture):
    if scenario == 'transfer':
        connection, wire, _ = game_accept(listener, evidence, KEY1, 'game1')
        with connection:
            enter(wire, 2, 162.0, 156.0, MY1, fixtures['objects'] + notify_frame(2, 3))
            _, body = wire.expect(414)
            assert struct.unpack('<HHII', body) == (2, 3, 0, 0), 'CGAskChangeScene answers GCNotifyChangeScene'
            wire.send(transfer_frame(game_port, KEY2))
            wire.drain_to_close()
        connection, wire, _ = game_accept(listener, evidence, KEY2, 'game2')
        with connection:
            enter(wire, 3, 100.0, 120.0, MY2, result=3)
            quit_ack(wire)
        return
    connection, wire, connect_body = game_accept(listener, evidence, KEY1, 'game1')
    with connection:
        if scenario in ('enter-quit', 'refuse-then-grant', 'reply-port'):
            enter(wire, 2, 162.0, 156.0, MY1, fixtures['objects'])
            _, body = wire.expect(404)
            assert struct.unpack('<I', body) == (MY1,), 'CGCharAskBaseAttrib for the own object'
            _, body = wire.expect(352)
            handle, obj, _, _, count, unknown = struct.unpack_from('<IIffBb', body)
            assert len(body) == 26 and (handle, obj, count, unknown) == (1, MY1, 1, 0), 'CGCharMove fields'
            target = struct.unpack_from('<ff', body, 18)
            wire.send(frame(564, struct.pack('<IIiBB', MY1, 1000, 1, 0, 1) + struct.pack('<ff', *target)) +
                      frame(1090, struct.pack('<IiI', MY1, 0, 1)))
            quit_ack(wire)
        elif scenario == 'transfer-refused':
            enter(wire, 2, 162.0, 156.0, MY1, notify_frame(2, 3))
            wire.expect(414)
            wire.send(frame(280, struct.pack('<BI', 0, 0)))
            quit_ack(wire)
        elif scenario == 'silent-key':
            wire.drain_to_close(allowed=())
        elif scenario == 'enter-timeout':
            wire.send(connect_frames(2, 162.0, 156.0))
            wire.expect(824)
            wire.drain_to_close()
        elif scenario == 'peer-close-world':
            enter(wire, 2, 162.0, 156.0, MY1)
            time.sleep(0.2)
        elif scenario == 'unsolicited-transfer':
            enter(wire, 2, 162.0, 156.0, MY1, transfer_frame(game_port, KEY2))
            wire.drain_to_close()
        elif scenario == 'decode-failure':
            wire.send(frame(67, struct.pack('<H', 8) + bytes(8)) + frame(456, bytes(13)))
            wire.drain_to_close(allowed=())
        elif scenario == 'quit-timeout':
            enter(wire, 2, 162.0, 156.0, MY1)
            quit_ack(wire)
            wire.drain_to_close(allowed=())  # no close from us; the client bounds the wait
        elif scenario == 'cancel-world':
            enter(wire, 2, 162.0, 156.0, MY1)
            wire.drain_to_close()
        elif scenario == 'backpressure':
            enter(wire, 2, 162.0, 156.0, MY1)
            wire.send(b''.join(frame(582, struct.pack('<IH', 100000 + i, 2)) for i in range(20000)))
            quit_ack(wire)
        elif scenario == 'rate':
            enter(wire, 2, 162.0, 156.0, MY1)
            stamps = []
            for number in range(1, 41):
                _, body = wire.expect(352)
                assert struct.unpack_from('<I', body)[0] == number, 'moves keep their order'
                stamps.append(time.monotonic())
            evidence['rate_span_ms'] = round((stamps[-1] - stamps[0]) * 1000)
            assert stamps[-1] - stamps[0] >= 0.5, 'owner packets are paced by the token bucket'
            quit_ack(wire)
        elif scenario == 'core-combat':
            # CYS-CORE: replies are ProtocolGen-encoded frames generated by the test executable (--fixture core-*).
            enter(wire, 2, 162.0, 156.0, MY1, fixtures['objects'])
            _, body = wire.expect(404)
            assert struct.unpack('<I', body) == (MY1,), 'CGCharAskBaseAttrib for the own object'
            _, body = wire.expect(1252)
            assert struct.unpack('<I', body) == (MY1,), 'CGAskDetailSkillList for the own object'
            wire.send(fixtures['core-skills'])
            _, body = wire.expect(372)
            assert struct.unpack('<i', body) == (7003,), 'CGLockTarget on monster 7003'
            for hit in range(3):
                _, body = wire.expect(83)
                direction, skill, target, obj, target_obj, tx, ty = struct.unpack('<fiiIiff', body)
                assert len(body) == 28 and (skill, target_obj, obj) == (0, 7003, MY1), 'CGCharUseSkill layout (CY: dir, skill, target, obj, target, pos)'
                assert abs(tx - 170.0) < 1e-3 and abs(ty - 151.0) < 1e-3, 'skill target position is the monster position'
                wire.send(fixtures['core-kill' if hit == 2 else 'core-skill'])
            _, body = wire.expect(1266)
            assert struct.unpack('<I', body) == (0x00FF0001,), 'CGOpenItemBox on the drop box'
            wire.send(fixtures['core-box'])
            _, body = wire.expect(1155)
            assert struct.unpack('<IBBHI', body) == (0x00FF0001, 1, 1, 0, 4242), 'CGPickBoxItem carries box id and the full item GUID'
            wire.send(fixtures['core-pick'])
            _, body = wire.expect(753)
            text = b'unit-chat-echo'
            assert body[0] == 0 and struct.unpack_from('<I', body, 1)[0] == len(text) and body[5:5 + len(text)] == text, \
                'CGChat type 0 with a u32 text length (social.lua bis)'
            assert len(body) == 5 + len(text) + 1 + 4 + 1 + 4 + 2 + 3, 'CGChat trailer: str8 unknow_7, u32, u8, u32, u16 branch, uts[3]'
            wire.send(fixtures['core-chat'])
            _, body = wire.expect(170)
            assert body == struct.pack('<IB', 0, 0), 'CGAskMyBagList ASK_ALL'
            wire.send(fixtures['core-bag'])
            quit_ack(wire)
        elif scenario == 'replay':
            c2s, s2c = capture
            assert connect_body[8:] == c2s[0][2][8:], 'CGConnect equals the real client except key/GUID'
            wire.send(b''.join(raw_frame(i, x, b) for i, x, b in s2c[:2]))
            _, body = wire.expect(824)
            real_enter = next(b for i, _, b in c2s if i == 824)
            assert body == real_enter, 'CGEnterScene equals the real client frame'
            blob = b''.join(raw_frame(i, x, b) for i, x, b in s2c[2:])
            rng = random.Random(0x1764)
            position = 0
            while position < len(blob):
                step = rng.randint(1, 2048)
                wire.send(blob[position:position + step])
                position += step
            wire.expect(352)
            quit_ack(wire)
        else:
            raise AssertionError('unknown scenario')


def server(login_listener, game_listener, scenario, evidence, fixtures, capture):
    try:
        game_port = game_listener.getsockname()[1]
        connection, _ = login_listener.accept()
        with connection:
            connection.settimeout(8)
            login_phase(connection, evidence, scenario, fixtures, game_port)
        if scenario in ('bad-endpoint', 'bad-port', 'unlisted-host'):
            game_listener.settimeout(0.7)
            try:
                extra, _ = game_listener.accept()
                extra.close()
                raise AssertionError('game connection despite a rejected hand-off')
            except socket.timeout:
                pass
        else:
            game_listener.settimeout(8)
            game_script(game_listener, scenario, evidence, fixtures, game_port, capture)
        game_listener.settimeout(0.3)
        try:
            extra, _ = game_listener.accept()
            extra.close()
            raise AssertionError('unexpected automatic reconnect')
        except socket.timeout:
            pass
        evidence['closed'] = True
    except Exception as error:
        # Fixed assertion labels only; never wire data.
        evidence['server_error'] = type(error).__name__ + ': ' + str(error)


BOT_SCENARIOS = (('bot-world', 0), ('bot-guid-missing', 6), ('bot-core', 0))  # CYS-CORE


def bot_server(login_listener, game_listener, scenario, evidence, fixtures):
    """Fake clone for CysNetBot --mode world (account policy test00, synthetic password)."""
    try:
        game_port = game_listener.getsockname()[1]
        connection, _ = login_listener.accept()
        with connection:
            connection.settimeout(8)
            wire = Wire(connection, evidence, 'login')
            _, body = wire.expect(355, heartbeat=False)
            assert body[4:54].split(b'\0', 1)[0] == b'test00', 'bot account'
            wire.send(frame(311, bytes(64)))
            _, body = wire.expect(299, heartbeat=False)
            assert len(body) == 949 and body[:50].split(b'\0', 1)[0] == b'test00%unit-value', 'bot credential encoding'
            wire.send(frame(223, login_reply()) + frame(554, bytes(6)))
            wire.expect(711, heartbeat=False)
            wire.send(fixtures['list1'])
            if scenario != 'bot-guid-missing':
                _, body = wire.expect(426, heartbeat=False)
                assert struct.unpack('<IH', body) == (GUID, 0), 'bot character login'
                wire.send(charlogin_frame(b'127.0.0.1', game_port, KEY1))
            wire.drain_to_close(allowed=())
        if scenario == 'bot-guid-missing':
            game_listener.settimeout(0.7)
            try:
                extra, _ = game_listener.accept()
                extra.close()
                raise AssertionError('game connection without a character login')
            except socket.timeout:
                pass
        elif scenario == 'bot-core':
            # CYS-CORE: generic responder; the bot chooses its own order (setup asks, chat, walk, 3 hits, loot, bag, quit).
            game_listener.settimeout(8)
            connection, wire, _ = game_accept(game_listener, evidence, KEY1, 'game1')
            with connection:
                enter(wire, 2, 162.0, 156.0, MY1, fixtures['objects'])
                hits = 0
                seen = evidence.setdefault('core_seen', [])
                while True:
                    packet_id, _, body = wire.recv()
                    if packet_id == 3:
                        evidence['heartbeats'] += 1
                        continue
                    seen.append(packet_id)
                    if packet_id == 1252:
                        wire.send(fixtures['core-skills'])
                    elif packet_id == 352:
                        handle = struct.unpack_from('<I', body)[0]
                        count = body[16]
                        last = struct.unpack_from('<ff', body, 18 + (count - 1) * 8)
                        wire.send(frame(564, struct.pack('<IIiBB', MY1, 1000, handle, 0, 1) + struct.pack('<ff', *last)))
                    elif packet_id == 83:
                        hits += 1
                        assert struct.unpack_from('<i', body, 16)[0] == 7003, 'bot attacks the nearest monster 7003'
                        wire.send(fixtures['core-kill' if hits == 3 else 'core-skill'])
                    elif packet_id == 1266:
                        wire.send(fixtures['core-box'])
                    elif packet_id == 1155:
                        assert struct.unpack('<IBBHI', body) == (0x00FF0001, 1, 1, 0, 4242), 'bot picks the listed GUID'
                        wire.send(fixtures['core-pick'])
                    elif packet_id == 753:
                        wire.send(fixtures['core-chat'])
                    elif packet_id == 170:
                        wire.send(fixtures['core-bag'])
                    elif packet_id == 1727:
                        assert body == struct.pack('<IBII', 0, 0, 0, 0), 'CGAskQuit'
                        wire.send(frame(128, bytes(1)))
                        break
                    elif packet_id in (404, 372):
                        pass
                    else:
                        raise AssertionError('unexpected bot packet %d' % packet_id)
                evidence['core_hits'] = hits
        else:
            game_listener.settimeout(8)
            connection, wire, _ = game_accept(game_listener, evidence, KEY1, 'game1')
            with connection:
                enter(wire, 2, 162.0, 156.0, MY1, fixtures['objects'])
                wire.expect(404)
                _, body = wire.expect(352)
                handle, obj, _, _, count, _ = struct.unpack_from('<IIffBb', body)
                target = struct.unpack_from('<ff', body, 18)
                assert (handle, obj, count) == (1, MY1, 1) and abs(target[0] - 163.0) < 1e-3 and \
                    abs(target[1] - 156.0) < 1e-3, 'one short step out'
                wire.send(frame(564, struct.pack('<IIiBB', MY1, 1000, 1, 0, 1) + struct.pack('<ff', *target)))
                _, body = wire.expect(352)
                handle, obj, _, _, count, _ = struct.unpack_from('<IIffBb', body)
                back = struct.unpack_from('<ff', body, 18)
                assert (handle, obj, count) == (2, MY1, 1) and abs(back[0] - 162.0) < 1e-3 and \
                    abs(back[1] - 156.0) < 1e-3, 'step back to the entry position'
                quit_ack(wire)
        evidence['closed'] = True
    except Exception as error:
        evidence['server_error'] = type(error).__name__ + ': ' + str(error)


def load_world_fixture(path):
    data = path.read_bytes()
    assert data[:8] == b'PGWORLD1', 'fixture format'
    position, c2s, s2c = 8, [], []
    while position < len(data):
        direction, packet_id, index, size = struct.unpack_from('<BHHI', data, position)
        position += 9
        body = data[position:position + size]
        position += size
        (c2s if direction else s2c).append((packet_id, index, body))
    return c2s, s2c


def model(frames):
    """Mirror of WorldModel semantics for the counters compared with the C++ side."""
    objects, stats = {}, collections.Counter()
    my = scene = 0
    in_world = False
    for packet_id, _, body in frames:
        stats['packets'] += 1
        if packet_id == 1764:
            _, scene, _, _, _, my = struct.unpack_from('<BHHffI', body)
            in_world = True
        elif packet_id in CREATE_IDS:
            identifier = struct.unpack_from('<I', body)[0]
            stats['refreshed' if identifier in objects else 'created'] += 1
            objects[identifier] = packet_id
        elif packet_id == 582:
            identifier, target = struct.unpack_from('<IH', body)
            if in_world and target != scene:
                stats['foreign_deletes'] += 1
            elif identifier in objects:
                del objects[identifier]
                stats['deleted'] += 1
            else:
                stats['unknown_deletes'] += 1
        elif packet_id == 564:
            identifier = struct.unpack_from('<I', body)[0]
            stats['moves'] += 1
            if my and identifier == my:
                stats['self_moves'] += 1
            elif identifier not in objects:
                stats['unknown_moves'] += 1
    expected = {'my': my, 'scene': scene, 'objects': len(objects), 'packets': stats['packets']}
    for name in ('created', 'refreshed', 'deleted', 'unknown_deletes', 'foreign_deletes', 'moves', 'self_moves', 'unknown_moves'):
        expected[name] = stats[name]
    return expected


def tokens(text, label):
    for line in text.splitlines():
        if line.startswith(label + ' '):
            return dict(item.split('=', 1) for item in line.split()[1:] if '=' in item)
    return {}


def continuity(evidence):
    indices = [entry[2] for entry in evidence['tx']]
    if not indices or indices[0] != 0x7B00:
        return False
    return all(indices[i + 1] == (indices[i] + 0x100) & 0xFFFF for i in range(len(indices) - 1))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--exe', required=True)
    parser.add_argument('--out', required=True)
    parser.add_argument('--capture', default='Build/cmake/protocol-x64/test-data/capture_frames.bin')
    parser.add_argument('--fixture', default='Build/cmake/world-x64/test-data/world_session_1.bin')
    parser.add_argument('--bot-exe', default='')
    args = parser.parse_args()
    executable = (CY / args.exe).resolve()
    output = Path(os.path.abspath(CY / args.out))
    if not output.is_relative_to(CY / 'Build' / 'Logs') or output.exists():
        raise SystemExit('Choose a new output below CY-Source/Build/Logs')
    for path in [output, *output.parents]:
        if path.exists() and (path.is_symlink() or path.is_junction()):
            raise SystemExit('Output must not traverse a junction')
    assert executable.is_relative_to(CY / 'Build') and executable.is_file(), 'CY test executable required'
    output.mkdir(parents=True)
    fixture = (CY / args.fixture).resolve()
    if not fixture.exists():
        made = subprocess.run([sys.executable, '-B', str(Path(__file__).with_name('make_world_fixture.py')),
                               '--input', args.capture, '--out', args.fixture], cwd=CY, capture_output=True, timeout=60)
        assert made.returncode == 0, 'fixture extraction failed'
    capture = load_world_fixture(fixture)
    environment = os.environ.copy()
    environment.pop('CYS_BOT_PWD', None)

    def run(arguments, timeout=40):
        process = subprocess.run([str(executable), *arguments], cwd=CY, env=environment, capture_output=True, timeout=timeout)
        text = process.stdout + process.stderr
        assert b'unit-value' not in text and b'unit-world%' not in text, 'fake credential leaked into output'
        return process.returncode, text

    fixtures = {}
    for kind in ('list1', 'objects') + CORE_KINDS:
        process = subprocess.run([str(executable), '--fixture', kind], cwd=CY, env=environment, capture_output=True, timeout=10)
        assert process.returncode == 0 and not process.stderr, 'synthetic fixture generation'
        fixtures[kind] = process.stdout
    summary = {'scope': 'world-session-offline-loopback', 'raw_output': False,
               'executable_sha256': hashlib.sha256(executable.read_bytes()).hexdigest(),
               'fixture_sha256': hashlib.sha256(fixture.read_bytes()).hexdigest(),
               'fixture_frames': {'c2s': len(capture[0]), 's2c': len(capture[1])}, 'cases': []}
    rc, text = run([])
    (output / 'unit.log').write_bytes(text)
    summary['unit_rc'] = rc
    assert rc == 0, 'world unit tests failed'
    rc, text = run(['--replay-model', str(fixture)])
    (output / 'replay-model.log').write_bytes(text)
    expected_model = model(capture[1])
    got = tokens(text.decode('utf-8', 'replace'), 'MODEL')
    summary['replay_model'] = {'rc': rc, 'expected': expected_model, 'observed': got}
    assert rc == 0 and all(str(value) == got.get(key) for key, value in expected_model.items()), 'replay model mismatch'
    print('PASS unit + replay-model', json.dumps(expected_model))
    # Offline replay data source (CYS_WORLD_REPLAY): LoginClient + GameClient on the injected streams, no socket.
    rc, text = run(['--replay-source', str(fixture)], timeout=90)
    (output / 'replay-source.log').write_bytes(text)
    decoded = text.decode('utf-8', 'replace')
    state, source = tokens(decoded, 'STATE'), tokens(decoded, 'REPLAYSRC')
    expected_source = dict(expected_model)
    expected_source['packets'] += 2       # move echo + GCRetAskQuit
    expected_source['moves'] += 1
    expected_source['self_moves'] += 1
    mismatch = [key for key, value in expected_source.items() if str(value) != state.get(key)]
    problems = []
    if rc != 0:
        problems.append('driver exit code')
    if mismatch:
        problems.append('replay-source world state differs: ' + ','.join(mismatch))
    if source.get('contiguous') != '1' or source.get('first_idx') != '7f00' or source.get('protocol_errors') != '0':
        problems.append('replay-source sequence/protocol')
    if source.get('world') != '%d/%d' % (len(capture[1]) - 3, len(capture[1]) - 3):
        problems.append('replay-source world frame count')
    summary['replay_source'] = {'rc': rc, 'expected': expected_source, 'observed': state, 'source': source, 'problems': problems}
    assert not problems, 'replay-source: ' + '; '.join(problems)
    print('PASS replay-source', json.dumps(source))
    # CYS-CORE: replay source + synthetic core-loop responder (skill/death/drop/loot/chat/bag on the recorded scene).
    rc, text = run(['--replay-core', str(fixture)], timeout=90)
    (output / 'replay-core.log').write_bytes(text)
    core = tokens(text.decode('utf-8', 'replace'), 'REPLAYCORE')
    summary['replay_core'] = {'rc': rc, 'observed': core}
    assert rc == 0 and core.get('kills') == '1' and core.get('skills') == '3' and core.get('picks') == '1' and \
        core.get('chats') == '1' and core.get('bag') == '1' and core.get('decode_failures') == '0', 'replay-core failed'
    print('PASS replay-core', json.dumps(core))
    for scenario in SCENARIOS:
        evidence = {'scenario': scenario, 'tx': [], 'heartbeats': 0}
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as login_listener, \
                socket.socket(socket.AF_INET, socket.SOCK_STREAM) as game_listener:
            for listener in (login_listener, game_listener):
                listener.bind(('127.0.0.1', 0))
                listener.listen(2)
            login_listener.settimeout(8)
            helper = threading.Thread(target=server, args=(login_listener, game_listener, scenario, evidence, fixtures, capture))
            helper.start()
            started = time.monotonic()
            arguments = ['--loopback', str(login_listener.getsockname()[1]), str(game_listener.getsockname()[1]), scenario]
            if scenario == 'replay':
                arguments.append(str(len(capture[1])))
            rc, text = run(arguments)
            helper.join(timeout=10)
            evidence['elapsed_ms'] = round((time.monotonic() - started) * 1000)
            evidence['exit_code'] = rc
            (output / (scenario + '.log')).write_bytes(text)
            assert not helper.is_alive(), 'loopback helper did not exit'
        decoded = text.decode('utf-8', 'replace')
        world, state = tokens(decoded, 'WORLD'), tokens(decoded, 'STATE')
        evidence['world'], evidence['state'] = world, state
        evidence['idx_contiguous'] = continuity(evidence)
        evidence['tx'] = [[label, pid, '%04x' % idx, size] for label, pid, idx, size, _ in evidence['tx']]
        problems = []
        if rc != 0:
            problems.append('driver exit code')
        if 'server_error' in evidence:
            problems.append('server assertion')
        if not evidence['idx_contiguous']:
            problems.append('idx sequence gap')
        if scenario in ('enter-quit', 'reply-port') and state.get('objects') != '2':
            problems.append('world objects after the synthetic burst')
        if scenario == 'replay':
            expected = model(capture[1])
            mismatch = [key for key, value in expected.items() if key != 'packets' and str(value) != state.get(key)]
            # Every replayed frame plus the fake server's GCRetAskQuit reaches the owner.
            if world.get('driver_packets') != str(len(capture[1]) + 1) or state.get('quit_acks') != '1':
                mismatch.append('driver_packets/quit_acks')
            if mismatch:
                problems.append('replay world state differs: ' + ','.join(mismatch))
            evidence['expected_state'] = expected
        evidence['passed'] = not problems
        evidence['problems'] = problems
        summary['cases'].append(evidence)
        (output / 'summary.json').write_text(json.dumps(summary, indent=2) + '\n', encoding='utf-8')
        assert evidence['passed'], scenario + ': ' + '; '.join(problems) + ' ' + evidence.get('server_error', '')
        print('PASS', scenario, 'tx=%d heartbeats=%d' % (len(evidence['tx']), evidence['heartbeats']))
    if args.bot_exe:
        bot = (CY / args.bot_exe).resolve()
        assert bot.is_relative_to(CY / 'Build') and bot.is_file(), 'CysNetBot executable required'
        summary['bot_sha256'] = hashlib.sha256(bot.read_bytes()).hexdigest()
        summary['bot_cases'] = []
        for scenario, expected_rc in BOT_SCENARIOS:
            evidence = {'scenario': scenario, 'tx': [], 'heartbeats': 0}
            report = output / scenario
            with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as login_listener, \
                    socket.socket(socket.AF_INET, socket.SOCK_STREAM) as game_listener:
                for listener in (login_listener, game_listener):
                    listener.bind(('127.0.0.1', 0))
                    listener.listen(2)
                login_listener.settimeout(8)
                helper = threading.Thread(target=bot_server, args=(login_listener, game_listener, scenario, evidence, fixtures))
                helper.start()
                bot_environment = environment.copy()
                bot_environment['CYS_BOT_PWD'] = 'unit-value'  # synthetic; the fake server holds it in RAM only
                command = [str(bot), '--mode', 'world', '--host', '127.0.0.1', '--port', str(login_listener.getsockname()[1]),
                           '--game-port', str(game_listener.getsockname()[1]),
                           '--guid', '123456' if scenario == 'bot-guid-missing' else '200001', '--account', 'test00',
                           '--out', report.relative_to(CY).as_posix(), '--dwell-ms', '2500', '--heartbeat-ms', '150',
                           '--walk', '0' if scenario == 'bot-core' else '1', '--timeout-ms', '3000']
                if scenario == 'bot-core':
                    command += ['--chat', '1', '--chat-text', 'unit-chat-echo', '--attack', '1', '--pickup', '1', '--bag', '1', '--record', '1']
                process = subprocess.run(command, cwd=CY, env=bot_environment, capture_output=True, timeout=40)
                helper.join(timeout=10)
                assert not helper.is_alive(), 'bot helper did not exit'
            outputs = process.stdout + process.stderr
            for path in report.iterdir():
                outputs += path.read_bytes()
            assert b'unit-value' not in outputs and b'test00%' not in outputs, 'credential leaked into bot output'
            result = json.loads((report / 'result.json').read_text())
            evidence['exit_code'] = process.returncode
            evidence['result'] = {key: result[key] for key in ('terminal', 'quit_flag', 'charlogin', 'login_tx_frames',
                                                               'ticket_next_idx', 'heartbeats', 'moves_sent', 'decode_failures',
                                                               'in_world', 'world')}
            evidence['idx_contiguous'] = continuity(evidence)
            evidence['tx'] = [[label, pid, '%04x' % idx, size] for label, pid, idx, size, _ in evidence['tx']]
            problems = []
            if process.returncode != expected_rc:
                problems.append('bot exit code')
            if 'server_error' in evidence:
                problems.append('server assertion')
            if not evidence['idx_contiguous']:
                problems.append('idx sequence gap')
            if scenario == 'bot-world' and not (result['terminal'] == 'quit_complete' and result['quit_flag'] == 0 and
                                                result['charlogin'] == 'granted' and result['login_tx_frames'] == 4 and
                                                result['ticket_next_idx'] == '7f00' and result['heartbeats'] >= 2 and
                                                result['moves_sent'] == 2 and result['decode_failures'] == 0 and
                                                result['world']['objects'] == 2):
                problems.append('bot world result')
            if scenario == 'bot-guid-missing' and result['charlogin'] != 'not_requested':
                problems.append('bot sent a character login for an unlisted GUID')
            if scenario == 'bot-core':
                core = result.get('core', {})
                evidence['core'] = core
                want = {'chats_sent': 1, 'chat_echoes': 1, 'skills_sent': 3, 'kills': 1, 'picks_ok': 1, 'bag_lists': 1,
                        'bag_items': 1, 'skill_lists': 1, 'damage_dealt': 3, 'item_boxes': 1, 'target_deaths': 1}
                bad = [key for key, value in want.items() if core.get(key) != value]
                if bad or result['terminal'] != 'quit_complete' or result['quit_flag'] != 0 or result['decode_failures'] != 0:
                    problems.append('bot core result: ' + ','.join(bad))
                if core.get('skill_list') != [0, 101] or core.get('skill_used') != 0:
                    problems.append('bot skill choice')
                fixture_path = CY / core.get('fixture', '')
                if not core.get('fixture') or not fixture_path.is_file():
                    problems.append('bot fixture missing: ' + str(core.get('fixture_error')))
                else:
                    fc2s, fs2c = load_world_fixture(fixture_path)
                    ids = [x for x, _, _ in fs2c]
                    key = fc2s[0][2][:4] if fc2s else b'x'
                    if not (fc2s and fc2s[0][0] == 49 and key == bytes(4) and ids[:3] == [67, 456, 1764] and 1694 in ids and
                            790 in ids and 263 in ids and any(x == 83 for x, _, _ in fc2s)):
                        problems.append('bot fixture shape')
                    evidence['fixture'] = {'c2s': len(fc2s), 's2c': len(fs2c), 'sha256': hashlib.sha256(fixture_path.read_bytes()).hexdigest()}
            evidence['passed'] = not problems
            evidence['problems'] = problems
            summary['bot_cases'].append(evidence)
            (output / 'summary.json').write_text(json.dumps(summary, indent=2) + '\n', encoding='utf-8')
            assert evidence['passed'], scenario + ': ' + '; '.join(problems) + ' ' + evidence.get('server_error', '')
            print('PASS', scenario, 'tx=%d heartbeats=%d' % (len(evidence['tx']), evidence['heartbeats']))
    print('PASS world unit + replay-model +', len(SCENARIOS), 'loopback scenarios', '+ bot' if args.bot_exe else '',
          '; no live server or credential')


if __name__ == '__main__':
    main()
