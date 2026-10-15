"""cy-oracle: minimal fake login + game server so a PRIVATE COPY of CY 3.71 Game.exe reaches the world offline.

Purpose: reference frames of the real CY client (scene, characters, effects) for render comparison. Not a game server:
no account check, no persistence, no Changyou service. Binds 127.0.0.1 only.

Wire (Build/re/cy-oracle, Ghidra read-only on Game.exe sha 9278c7f3; see Docs/specs/render/cy-oracle_vi.md):
  client -> server: ["TLBB01"] u16 id, u32 (seq << 24 | size), body   (prefix when net mode 1 login / 2 game)
  server -> client: u16 id, u32 (seq << 24 | size), body
Packet layouts come from the Read() of each packet class in CY Game.exe (packet vtable slot 1).

Usage:
  cy_oracle_server.py --out DIR [--login-port 15790] [--game-port 15791] [--scenario Tools/cyoracle/scenarios/dali.json]
Stops on Ctrl+C, on --max-seconds, or when the file DIR/stop exists.
"""
import argparse
import json
import os
import socket
import struct
import threading
import time

HERE = os.path.dirname(os.path.abspath(__file__))

# Packet IDs of CY 3.71 (factory GetPacketID, Build/Logs/2026-09-14-cy-switch/pkt_ids_cy.tsv)
NAMES = {}
IDS = {}
for _line in open(os.path.join(HERE, 'cy_pkt_ids.tsv'), encoding='utf-8').read().splitlines()[1:]:
    _n, _i = _line.split('\t')[:2]
    NAMES[int(_i)] = _n
    IDS[_n] = int(_i)

# client packets whose body carries machine identifiers (MAC/CPU/partner SN/password hash): never logged, size only
REDACT = {'CLConnect', 'CLAskLogin', 'CGConnect', 'CGHeartBeat', 'CLAskCharLogin', 'CGClientInfo', 'CGMACNotify',
          'CGLogSubmit', 'CGClientPerformanceLogin', 'CGAskx64Info', 'CGExecuteScript'}


def cstr(s, n, enc='gbk'):
    b = s.encode(enc)[:n - 1]
    return b + b'\0' * (n - len(b))


class Log:
    def __init__(self, out):
        os.makedirs(out, exist_ok=True)
        self.t0 = time.time()
        self.lock = threading.Lock()
        self.tsv = open(os.path.join(out, 'frames.tsv'), 'w', encoding='utf-8', newline='\n')
        self.tsv.write('t_ms\tconn\tdir\tid\tname\tsize\tseq\tprefix\tbody_hex\n')
        self.txt = open(os.path.join(out, 'oracle.log'), 'w', encoding='utf-8', newline='\n')

    def ms(self):
        return int((time.time() - self.t0) * 1000)

    def frame(self, conn, d, pid, body, seq, prefix):
        name = NAMES.get(pid, '?')
        hexs = '' if name in REDACT else body[:512].hex()
        with self.lock:
            self.tsv.write(f'{self.ms()}\t{conn}\t{d}\t{pid}\t{name}\t{len(body)}\t{seq}\t{prefix}\t{hexs}\n')
            self.tsv.flush()

    def note(self, s):
        with self.lock:
            line = f'{self.ms():8d} {s}'
            self.txt.write(line + '\n')
            self.txt.flush()
            print(line, flush=True)


class Conn:
    def __init__(self, oracle, sock, kind, n):
        self.o, self.s, self.kind, self.name = oracle, sock, kind, f'{kind}{n}'
        self.buf = b''
        self.prefix_seen = 0
        self.out_seq = 0
        self.wlock = threading.Lock()

    def send(self, name, body):
        # one lock per connection: the request-handling thread and the timeline thread both send on the same socket,
        # so serialise to avoid interleaved frames.
        pid = IDS[name]
        with self.wlock:
            hdr = struct.pack('<HI', pid, (self.out_seq << 24) | len(body))
            self.out_seq = (self.out_seq + 1) & 0xff
            try:
                self.s.sendall(hdr + body)
            except OSError:
                return
        self.o.log.frame(self.name, 'S>C', pid, body, 0, '')

    def run(self):
        try:
            while not self.o.stopping:
                try:
                    data = self.s.recv(65536)
                except socket.timeout:
                    continue
                if not data:
                    break
                self.buf += data
                while True:
                    prefix = ''
                    b = self.buf
                    if b[:6] == b'TLBB01':
                        prefix = 'TLBB01'
                        b = b[6:]
                    elif len(b) < 6 and b'TLBB01'.startswith(b):
                        break
                    if len(b) < 6:
                        break
                    pid, packed = struct.unpack_from('<HI', b, 0)
                    size, seq = packed & 0xffffff, packed >> 24
                    if size > 0x100000:
                        self.o.log.note(f'{self.name}: bad size {size} id {pid}, closing')
                        return
                    if len(b) < 6 + size:
                        break
                    body = b[6:6 + size]
                    self.buf = b[6 + size:]
                    if prefix:
                        self.prefix_seen += 1
                    self.o.log.frame(self.name, 'C>S', pid, body, seq, prefix)
                    try:
                        self.o.handle(self, pid, body)
                    except Exception as e:  # a decode/handler bug must not silently drop the connection
                        import traceback
                        self.o.log.note(f'{self.name}: handler {NAMES.get(pid, pid)} error: {e!r}')
                        self.o.log.note(traceback.format_exc())
        except (ConnectionError, OSError) as e:
            self.o.log.note(f'{self.name}: {e!r}')
        finally:
            self.o.log.note(f'{self.name}: closed (prefixed frames {self.prefix_seen})')
            try:
                self.s.close()
            except OSError:
                pass


class Oracle:
    def __init__(self, a, sc):
        self.a, self.sc = a, sc
        self.log = Log(a.out)
        self.stopping = False
        self.n = 0
        self.account = sc.get('account', 'oracle')
        self.objid = sc.get('my_obj_id', 1001)
        self.key = 0x1234
        self.moves = 0

    # ---- login server ----------------------------------------------------------------------------------------
    def lc_ret_connect(self, c):
        # Read 140834f70: +0x50 i32, +0x30 i32, +0x18 char[24], +0x4c i32, +0x34 char[24], +0x54 9B, +0x60 i32, +0x64 u8
        body = (struct.pack('<ii', 0, self.a.login_port) + cstr('127.0.0.1', 24) + struct.pack('<i', self.a.login_port)
                + cstr('127.0.0.1', 24) + b'\0' * 9 + struct.pack('<i', 0) + b'\0')
        assert len(body) == 0x4a
        c.send('LCRetConnect', body)

    def lc_ret_login(self, c, body_in):
        acct = body_in[:50]
        self.account = acct.split(b'\0', 1)[0].decode('gbk', 'replace') or self.account
        # Read 14082f7a0: char[50] acct, i32 result, 15B, i32, u8, i32, [i32 if result 0x2f/0x4b], u8, i32 ...
        body = acct + struct.pack('<i', 0) + b'\0' * 15 + struct.pack('<iBi', 0, 0, 0) + struct.pack('<Bi', 0, 0)
        c.send('LCRetLogin', body)
        # LCStatus Read 14084dd60: u16, i32 status; handler 1405b6690 status 2 -> send CLAskCharList
        c.send('LCStatus', struct.pack('<Hi', 0, 2))

    def char_entry(self):
        ch = self.sc['character']
        e = bytearray(0x1a4)
        struct.pack_into('<I', e, 0x00, ch['guid'])
        struct.pack_into('<i', e, 0x08, ch['sex'])
        e[0x0c:0x0c + 30] = cstr(ch['name'], 30)
        struct.pack_into('<i', e, 0x2c, ch['level'])
        struct.pack_into('<i', e, 0x30, ch.get('hair_color', 0))
        struct.pack_into('<i', e, 0x38, ch.get('hair', 0))
        struct.pack_into('<i', e, 0x3c, ch.get('face', 0))
        struct.pack_into('<i', e, 0x40, self.sc['scene']['id'])
        struct.pack_into('<i', e, 0x44, ch.get('menpai', 9))
        for i in range(19):
            struct.pack_into('<I', e, 0x54 + 4 * i, ch.get('equips', [0] * 19)[i] if i < len(ch.get('equips', [])) else 0)
            struct.pack_into('<H', e, 0xa0 + 2 * i, ch.get('visuals', [0] * 19)[i] if i < len(ch.get('visuals', [])) else 0)
            struct.pack_into('<i', e, 0xc8 + 4 * i, -1)
        struct.pack_into('<h', e, 0x188, -1)
        for off, val in ch.get('raw', {}).items():
            struct.pack_into('<i', e, int(off, 16), val)
        return bytes(e)

    def lc_ret_char_list(self, c):
        # Read 14082f500 (peeks the whole stream): i32 result, char[50] acct, u8 n (<=5), n x 0x1a4, u32, u8, u32 x3,
        # then 8 unread bytes (GetPacketSize = n * 0x1a4 + 0x50)
        n = 1
        body = (struct.pack('<i', 0) + cstr(self.account, 50) + bytes([n]) + self.char_entry()
                + struct.pack('<IBIII', 0, 0, 0, 0, 0) + b'\0' * 8)
        assert len(body) == n * 0x1a4 + 0x50
        c.send('LCRetCharList', body)
        self.log.note('char list sent')

    def lc_ret_char_login(self, c):
        # Read 140834c80: u8 key, u32 len, len bytes decoded by b -= key (140765510); payload (62 B):
        # i32 result, i32 game port, char[24] ip, i32 key, u8, i32 (WorldID = i32*1000+u8), u16, u32, u16, u32, i32, i32, u8
        p = (struct.pack('<ii', 0, self.a.game_port) + cstr('127.0.0.1', 24) + struct.pack('<I', self.key)
             + struct.pack('<Bi', 1, 0) + struct.pack('<HIHIiiB', 0, 0, 0, 0, 0, 0, 0))
        assert len(p) == 0x3e
        k = 0x5a
        enc = bytes((x + k) & 0xff for x in p)
        c.send('LCRetCharLogin', bytes([k]) + struct.pack('<I', len(enc)) + enc)

    # ---- game server -------------------------------------------------------------------------------------------
    def gc_connect(self, c):
        s = self.sc['scene']
        # Read 14083ab00: i16 server id, i16 scene, f32 x, f32 z, i16, i32
        c.send('GCConnect', struct.pack('<hhffhi', 0, s['id'], s['x'], s['z'], 0, 0))

    def gc_enter_scene(self, c):
        s = self.sc['scene']
        # Read 14083ae10 (52 B): u8 ret, i16 scene, i16 res, f32 x, f32 z, u32 obj, u8 city, u8, i32, i32 IsKVKServer,
        # i32, u8, i32 IsTServer, i32, u32, i32, i16 server id, i16
        body = (struct.pack('<Bhhff', 0, s['id'], s.get('res', s['id']), s['x'], s['z'])
                + struct.pack('<IBBiiiBiiIihh', self.objid, 0, 0, 0, 0, s.get('server_time', 0), 0, 0,
                              s.get('show_objects', 1), 0, 0, -1, 0))
        # +0x44 i32: handler 1405464e0 sets ObjectManager +0x28/+0x29 = 1 (hide characters, "State_F12") when it is 0 and
        # FUN_1405471d0(scene) fails; run-07 with 0: NPC/MySelf on the minimap but no model drawn [SL]
        assert len(body) == 52, len(body)
        c.send('GCEnterScene', body)

    def gc_new_monsters(self, c):
        # GCNewMonster Read 140849210: 0x74 raw bytes; Execute 140569780 -> FUN_1406e8880 reads +0x00 obj id, +0x14 guid,
        # +0x28/+0x2c x/z, +0x40 dir, +0x54 move speed, +0x68 u16 -> obj+0x171/+0x173 (same offsets as skynet GCNewMonster)
        for i, npc in enumerate(self.sc.get('npcs', [])):
            b = bytearray(0x74)
            struct.pack_into('<I', b, 0x00, npc['obj'])
            struct.pack_into('<i', b, 0x14, -1)
            struct.pack_into('<ff', b, 0x28, npc['x'], npc['z'])
            struct.pack_into('<f', b, 0x40, npc.get('dir', 0.0))
            struct.pack_into('<f', b, 0x54, npc.get('speed', 3.5))
            # +0x68 u16 -> obj +0x171/+0x173; model gate FUN_1405e35a0 needs obj+0x171 == obj+0x170 (set from
            # GCCharBaseAttrib +0x1c) and != 0xff, else no model (run-07/12 with 0xffff: dots on minimap, no mesh)
            struct.pack_into('<H', b, 0x68, npc.get('gate', 0))
            c.send('GCNewMonster', bytes(b))

    def _base_attrib_packet(self, obj, flags, fields, sync=1):
        # ENCRYPTED form of GCCharBaseAttrib (Read 14083cc20, mode bit7=1): payload = [u32 obj, u8 sync, 8 flag bytes
        # (obj+0x1d..+0x24), 8 bytes (+0x25..+0x2c), 2 bytes (+0x2d..+0x2e), fields]; each byte encoded = plain + key.
        payload = struct.pack('<IB', obj, sync) + bytes(flags) + bytes(8) + bytes(2) + fields
        key = 0x33
        return bytes([0x80, key]) + struct.pack('<I', len(payload)) + bytes((b + key) & 0xff for b in payload)

    def gc_char_base_attrib(self, c, obj):
        # Two packets. (1) flag byte 3 bit3 (bit 27) only: execute 14057b150 sets obj+0x2e = obj+0x171 = sync, which ends
        # the CGCharAskBaseAttrib resend loop (FUN_1405d9470) and opens the model gate FUN_1405e35a0 (needs both equal and
        # != 0xff). (2) race + name + level + HP%: flag[0] bit0 race u32 -> FUN_14016abc0 -> OnDataChanged_RaceID (the model
        # is only built when the race changes, so the gate must already be open: run-14 sent both in one packet and the
        # model was never built), bit1 name, bit3 u8 level (FUN_14016b820), bit4 u8 HP% (FUN_14016b930).
        if obj == self.objid:
            ch = self.sc['character']
            race, name, level = ch['sex'], ch['name'], ch['level']
        else:
            npc = next((n for n in self.sc.get('npcs', []) if n['obj'] == obj), None)
            if npc is None:
                return
            race, name, level = npc['id'], npc.get('name', ''), npc.get('level', 1)
        f1 = bytearray(8)
        f1[3] = 0x08
        c.send('GCCharBaseAttrib', self._base_attrib_packet(obj, f1, b''))
        nm = name.encode('gbk')[:0x1c]
        f2 = bytearray(8)
        f2[0] = 0x01 | 0x02 | 0x08 | 0x10
        f2[3] = 0x08
        fields = struct.pack('<I', race) + bytes([len(nm)]) + nm + bytes([min(level, 255), 100])
        if obj == self.objid and 'model_id' in self.sc['character']:
            # flag byte 1 (+0x1e) bit4: u32 -> +0xa0 -> FUN_14016ad10 model id (character data +0x20). Read order puts it
            # after the byte-0 fields and before the byte-2 block. 0.85 UpdateEquip skips body parts unless ModelID == -1.
            f2[1] = 0x10
            fields += struct.pack('<i', self.sc['character']['model_id'])
        if obj == self.objid:
            # flag byte 2 (+0x1f) bit0: 24 B -> +0xb0 face (FUN_140171ce0), +0xb4 hair (FUN_140171520), +0xb8 hair colour
            # (FUN_140171a10), +0x56c/+0x570/+0x574 (FUN_1401728c0) — same setters as the character select entry
            f2[2] = 0x01
            fields += struct.pack('<iiiiii', ch.get('face', 0), ch.get('hair', 0), ch.get('hair_color', 0), 0, 0, 0)
        c.send('GCCharBaseAttrib', self._base_attrib_packet(obj, f2, fields))

    def gc_obj_teleport(self, c, x, z):
        # GCObjTeleport Read 14083bd90: u32 obj, f32 x, f32 z, u32 (+0x2c), u32 (+0x1c), u32 (+0x20); handler 14057ebb0
        c.send('GCObjTeleport', struct.pack('<IffIII', self.objid, x, z, 0, 0, 0))

    def gc_world_time(self, c, wt):
        # GCWorldTime Read 14086a940: i32 -> variable WorldTime, i32 -> counter global, i32 -> NewWorldTime_Interval
        c.send('GCWorldTime', struct.pack('<iii', wt.get('time', 0), wt.get('counter', 0), wt.get('interval', 0)))

    def gc_skill(self, c, skill, target, damage, pos=None, caster=None, impact=None):
        # GCCharSkill_Send Read 140841c10: u32 obj, u32 logic count, u32 skill id, i32 target, [f32 x, f32 z if target -1],
        # u8 flags; handler 140593a60 queues command 0xcc on the object. Hit numbers: GCDetailHealsAndDamages Read
        # 1408463d0: u8 dirty (1 = hp), u32 receiver, u32 sender, u32 logic count, [i32 hp delta], u8 crit, u8.
        self.logic = getattr(self, 'logic', self.sc.get('logic_base', 100)) + 1
        caster = self.objid if caster is None else caster
        body = struct.pack('<IIIi', caster, self.logic, skill, target)
        if target == -1:
            body += struct.pack('<ff', *(pos or (0.0, 0.0)))
        c.send('GCCharSkill_Send', body + b'\0')
        if damage or impact:
            time.sleep(0.6)
        if impact:
            self.gc_direct_impact(c, target, caster, impact)
        if damage:
            c.send('GCDetailHealsAndDamages', struct.pack('<BIIIi', 1, target, self.objid, self.logic, -damage) + b'\0\0')

    def timeline(self, c):
        # scripted stops after GCEnterScene (scenario "timeline": [{"t": s, "teleport": [x, z], "tag": name}, ...])
        t0 = time.time()
        for step in self.sc.get('timeline', []):
            while time.time() - t0 < step['t']:
                if self.stopping:
                    return
                time.sleep(0.1)
            try:
                if 'teleport' in step:
                    self.gc_obj_teleport(c, *step['teleport'])
                if 'skill' in step:
                    threading.Thread(target=self.gc_skill, args=(c, step['skill'], step.get('target', -1), step.get('damage', 0),
                                     step.get('pos'), step.get('caster'), step.get('impact')), daemon=True).start()
                if 'impact_list' in step:
                    self.gc_impact_list(c, step['impact_list'], step.get('ids'))  # CYS-FXBASE: per-step ids
                if 'direct_impact' in step:
                    self.gc_direct_impact(c, step.get('target', -1), step.get('caster', self.objid), step['direct_impact'])
                if 'world_time' in step:
                    self.gc_world_time(c, step['world_time'])
                self.log.note(f'timeline {step.get("tag", "")}: {json.dumps(step, ensure_ascii=False)}')
            except OSError as e:
                self.log.note(f'timeline stopped: {e!r}')
                return

    def gc_impact_list(self, c, obj, ids=None):
        # GCCharImpactListUpdate Read 1408410a0: u32 obj, u32 (+0x1c, init 0xff: impact sync byte [SL]), u16 n (<=40),
        # n x (u16 impact id, u32, u32), u16 (+0x204), u32 (+0x208). Impact ids = ImpactSEData_V1 rows (col 7 effect,
        # col 9 bind point): scenario "impacts": {"<obj>": [ids]}.
        # CYS-FXBASE (fx-cy-baseline 19/09): a timeline step may carry its own "ids" (the list REPLACES the buffs).
        if ids is None:
            ids = self.sc.get('impacts', {}).get(str(obj), [])
        body = struct.pack('<IIH', obj, 0, len(ids))
        for i in ids:
            body += struct.pack('<HiI', i, obj, 0)
        c.send('GCCharImpactListUpdate', body + struct.pack('<Hi', 0xffff, 0))

    def gc_direct_impact(self, c, target, sender, impact):
        # GCCharDirectImpact Read 14084fe60: u32 target, u32 sender, u16 impact id (handler 14057d2f0 -> command 0x12)
        c.send('GCCharDirectImpact', struct.pack('<IIH', target, sender, impact))

    def gc_detail_attrib(self, c):
        # Read 140842010: u32 obj, 35 flag bytes (+0x1c..), fields per flag. character.detail_menpai: flag byte 6 (+0x22)
        # bit7 -> u32 +0x130 -> FUN_14016c0a0 = menpai (CharacterData +0x2bc, read by Lua GetMenPai 1402b8340).
        flags = bytearray(35)
        fields = b''
        mp = self.sc['character'].get('detail_menpai')
        if mp is not None:
            flags[6] |= 0x80
            fields += struct.pack('<i', mp)
        c.send('GCDetailAttrib', struct.pack('<I', self.objid) + bytes(flags) + fields)

    def gc_char_move_echo(self, c, body):
        # CGCharMove Read 14082fdc0: +0x1c i32, +0x18 i32, 8B pos, u8 n, u8, n x 8B path
        if len(body) < 18:
            return
        a1, a0 = struct.unpack_from('<ii', body, 0)
        n = body[16]
        path = body[18:18 + 8 * n]
        # GCCharMove Read 1408416c0: u32 obj, i32 time, u8 flag, u8 n, n x (f32 x, f32 z), [flag&4: 8B, i32, u8]
        out = struct.pack('<IiBB', self.objid, int(self.log.ms()), 0, n) + path
        c.send('GCCharMove', out)
        self.moves += 1

    def handle(self, c, pid, body):
        name = NAMES.get(pid, '?')
        if c.kind == 'login':
            if name == 'CLConnect':
                self.lc_ret_connect(c)
            elif name == 'CLAskLogin':
                self.lc_ret_login(c, body)
            elif name == 'CLAskCharList':
                self.lc_ret_char_list(c)
            elif name == 'CLAskCharLogin':
                self.lc_ret_char_login(c)
                self.log.note('char login granted -> game port')
        else:
            if name == 'CGConnect':
                self.gc_connect(c)
            elif name == 'CGEnterScene':
                self.gc_enter_scene(c)
                self.log.note('GCEnterScene sent: IN WORLD (client side)')
                self.gc_new_monsters(c)
                if 'world_time' in self.sc:
                    self.gc_world_time(c, self.sc['world_time'])
                threading.Thread(target=self.timeline, args=(c,), daemon=True).start()
            elif name == 'CGAskDetailAttrib':
                self.gc_detail_attrib(c)
            elif name == 'CGCharAskImpactList' and len(body) >= 4 and self.sc.get('impacts'):
                self.gc_impact_list(c, struct.unpack_from('<I', body, 0)[0])
            elif name == 'CGCharAskEquipment' and len(body) >= 4:
                # GCCharEquipment Read 140840ca0: u32 obj, u32 (+0x1c low byte = part gate like +0x591), u32 flags
                # parts Read accepts: bit0 weapon (i32 item, i32 gem, u16 visual), bit1 cap (i32, u16), bit2 armour
                # (i32, i32, u16), bit3 cuff (i32, u16), bit4 boot (i32, u16); visual 0 = default body part as on the
                # character select screen (FUN_140173e20 / FUN_1401735a0)
                tobj = struct.unpack_from('<I', body, 0)[0]
                if tobj == self.objid:
                    ch = self.sc['character']
                    # Gate of part apply (PlayerOther 14060e350): obj+0x591 == obj+0x590 and != 0xff. GCCharEquipment Execute
                    # sets both from +0x1c low byte unconditionally only when flags bit31 is set (`(int)flags < 0`), after
                    # it has applied the parts -> first a sync-only packet (bit31, no parts), then the parts. run-16..27
                    # without it: MySelf head + hair only.
                    sync = bool(ch.get('equip_sync'))    # off keeps run-27-hit (skill-fx-parity) byte-identical
                    if sync:
                        c.send('GCCharEquipment', struct.pack('<IIi', tobj, 1, -0x80000000))
                    it = ch.get('equips', [])
                    eq = ch.get('visuals', [])
                    e = [it[i] if i < len(it) else -1 for i in range(5)]
                    v = [eq[i] if i < len(eq) else 0 for i in range(5)]
                    parts = (struct.pack('<iiH', e[0], -1, v[0]) + struct.pack('<iH', e[1], v[1])
                             + struct.pack('<iiH', e[2], -1, v[2]) + struct.pack('<iH', e[3], v[3]) + struct.pack('<iH', e[4], v[4]))
                    # bit 16 (0x10000) = dress slot 16 (-1 = no dress, parts 1..4 are drawn; UpdateEquip 14060dce0)
                    dress = struct.pack('<iHiii', -1, 0xffff, -1, -1, -1)
                    flags = 0x1f | 0x10000 | (0x80000000 if sync else 0)
                    c.send('GCCharEquipment', struct.pack('<IiI', tobj, 1 if sync else 0, flags) + parts + dress)
                else:
                    c.send('GCCharEquipment', struct.pack('<III', tobj, 0, 0))
            elif name == 'CGCharAskBaseAttrib' and len(body) >= 4:
                self.gc_char_base_attrib(c, struct.unpack_from('<I', body, 0)[0])
            elif name == 'CGCharMove' and self.sc.get('echo_move', True):
                self.gc_char_move_echo(c, body)

    def serve(self, port, kind):
        srv = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        srv.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        srv.bind(('127.0.0.1', port))
        srv.listen(4)
        srv.settimeout(0.5)
        self.log.note(f'{kind} listening 127.0.0.1:{port}')
        while not self.stopping:
            try:
                s, addr = srv.accept()
            except socket.timeout:
                continue
            if addr[0] != '127.0.0.1':
                s.close()
                continue
            s.settimeout(0.5)
            self.n += 1
            c = Conn(self, s, kind, self.n)
            self.log.note(f'{c.name}: accepted from {addr[0]}:{addr[1]}')
            threading.Thread(target=c.run, daemon=True).start()
        srv.close()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--out', required=True)
    ap.add_argument('--login-port', type=int, default=15790)
    ap.add_argument('--game-port', type=int, default=15791)
    ap.add_argument('--scenario', default=os.path.join(HERE, 'scenarios', 'dali.json'))
    ap.add_argument('--max-seconds', type=int, default=900)
    a = ap.parse_args()
    sc = json.load(open(a.scenario, encoding='utf-8'))
    o = Oracle(a, sc)
    o.log.note(f'scenario {a.scenario}: {json.dumps(sc, ensure_ascii=False)}')
    o.log.note(f'wallclock t0={o.log.t0:.3f}')  # CYS-FXBASE: absolute clock of this log (ms column = time.time() - t0)
    for port, kind in ((a.login_port, 'login'), (a.game_port, 'game')):
        threading.Thread(target=o.serve, args=(port, kind), daemon=True).start()
    stop = os.path.join(a.out, 'stop')
    t0 = time.time()
    try:
        while time.time() - t0 < a.max_seconds and not os.path.exists(stop):
            time.sleep(0.3)
    except KeyboardInterrupt:
        pass
    o.stopping = True
    time.sleep(1)
    o.log.note('stopped')


if __name__ == '__main__':
    main()
