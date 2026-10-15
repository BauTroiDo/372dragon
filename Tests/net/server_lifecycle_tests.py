#!/usr/bin/env python3
"""Private-clone lifecycle tests: mocked processes/signals, no WSL mutation.

Scratch files stay below this checkout's Build/Logs. No real process is started
or stopped, no credential file is read, and no database connection is created.
"""
import contextlib
import importlib.util
import io
from pathlib import Path
import subprocess
import unittest
from unittest.mock import patch, Mock
import uuid

CY = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location('provision', CY/'Tools/server/provision_test_wsl.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
FIXED = '/home/ubuntu/cys-test-20260913'


def identity(role, pid=1234, start=50):
    args = [str(role['exe'])]
    if 'option' in role:
        args.extend([role['option'], str(role['config'])])
    else:
        args.append(str(role['config']))
    return {'pid': pid, 'start_ticks': start, 'exe': str(role['exe'].resolve()),
            'cwd': str(role.get('cwd', Path('/'))), 'args': args}


class RootAndIdentity(unittest.TestCase):
    def test_fixed_root(self):
        module.validate_root_identity('posix', FIXED, '/home/ubuntu', FIXED, '/home/ubuntu')

    def test_root_rejects_other_platform_live_traversal_and_symlink(self):
        for platform, test, resolved in [
                ('nt', FIXED, FIXED), ('posix', '/home/ubuntu', '/home/ubuntu'),
                ('posix', FIXED+'-other', FIXED+'-other'),
                ('posix', FIXED+'/../GameServer', '/home/ubuntu/GameServer'),
                ('posix', FIXED, '/home/ubuntu/GameServer')]:
            with self.subTest(test=test, resolved=resolved), self.assertRaises(RuntimeError):
                module.validate_root_identity(platform, test, '/home/ubuntu', resolved, '/home/ubuntu')

    def test_all_private_ports_and_process_ids(self):
        roles = module.role_specs()
        self.assertEqual([r['name'] for r in roles], ['Mongo','MQTT','Manager','DataCenter','Tool','Game'])
        self.assertEqual([r.get('process_id') for r in roles], [None,None,8,9,6,2])
        self.assertEqual([r['ports'] for r in roles], [[27018],[1884],[18888],[12531],[12532],[15733,15734]])
        self.assertTrue({27017,1883,5733,5734,8888}.isdisjoint(module.PORTS))
        self.assertEqual(len(module.PORTS),len(set(module.PORTS)))

    def test_database_identity_needs_exe_and_private_config(self):
        mongo = module.role_specs()[0]
        current = identity(mongo)
        self.assertTrue(module.process_matches(current,mongo))
        current['args'][-1] = '/etc/mongod.conf'
        self.assertFalse(module.process_matches(current,mongo))
        current = identity(mongo)
        current['exe'] = '/usr/bin/sleep'
        self.assertFalse(module.process_matches(current,mongo))
        current = identity(mongo)
        current['args'].extend(['--config',str(mongo['config'])])
        self.assertFalse(module.process_matches(current,mongo))
        current = identity(mongo)
        current['args'].extend(['--dbpath','/home/ubuntu/live-db'])
        self.assertFalse(module.process_matches(current,mongo))

    def test_mqtt_identity_ignores_missing_or_stale_pidfile(self):
        mqtt = module.role_specs()[1]
        current = identity(mqtt,2222)
        foreign = identity(mqtt,3333)
        foreign['args'][-1] = '/etc/mosquitto/mosquitto.conf'
        self.assertEqual(module.owned_processes(mqtt,[None,foreign,current]),[current])

    def test_skynet_requires_private_binary_config_and_cwd(self):
        game = module.role_specs()[-1]
        current = identity(game)
        self.assertTrue(module.process_matches(current,game))
        for field,value in [('exe','/home/ubuntu/GameServer/framework/Game_tlbb_2'),
                            ('cwd','/home/ubuntu/GameServer'),
                            ('args',[str(game['exe']),'/home/ubuntu/GameServer/config_2'])]:
            with self.subTest(field=field):
                altered = dict(current)
                altered[field] = value
                self.assertFalse(module.process_matches(altered,game))

    def test_start_decision_handles_loading_and_foreign_port(self):
        game = module.role_specs()[-1]
        self.assertFalse(module.needs_start(game,[identity(game)],{15733:False,15734:False}))
        self.assertTrue(module.needs_start(game,[],{15733:False,15734:False}))
        with self.assertRaises(RuntimeError):
            module.needs_start(game,[],{15733:False,15734:True})
        with self.assertRaises(RuntimeError):
            module.needs_start(game,[identity(game),identity(game,4444)],{})

    def test_kernel_listen_ignores_established_and_other_states(self):
        text='header\n 0: 0100007F:3D75 00000000:0000 0A rest\n 1: 0100007F:3D76 0100007F:1234 01 rest\n'
        listeners=module.parse_tcp_listeners(text,4)
        self.assertTrue(module.port_open(15733,listeners))
        self.assertFalse(module.port_open(15734,listeners))

    def test_kernel_wildcard_accepts_ipv4_loopback_but_other_bindings_do_not(self):
        self.assertTrue(module.port_open(15733,{(4,'00000000',15733)}))
        self.assertFalse(module.port_open(15733,{(4,'0200007F',15733)}))
        self.assertFalse(module.port_open(15733,{(4,'0101A8C0',15733)}))
        self.assertFalse(module.port_open(15733,{(6,'00000000000000000000000000000000',15733)}))

    def test_occupied_detects_any_binding_and_ipv6(self):
        with patch.object(module,'tcp_listeners',return_value={(6,'0'*32,15733),(4,'0101A8C0',1884)}):
            self.assertTrue(module.port_occupied(15733))
            self.assertTrue(module.port_occupied(1884))
            self.assertFalse(module.port_occupied(5733))

    def test_kernel_malformed_listen_fails_closed(self):
        for line in ['0: no-address 00000000:0000 0A','0: 00000000:10000 00000000:0000 0A','broken']:
            with self.subTest(line=line),self.assertRaises((RuntimeError,ValueError)):
                module.parse_tcp_listeners('header\n'+line+'\n',4)


class PrivateFilesAndLifecycle(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.scratch = CY/'Build/Logs/2026-09-13-gpt-netbot'/('lifecycle-tests-'+uuid.uuid4().hex)
        cls.scratch.mkdir(parents=True)

    def setUp(self):
        self.root = self.scratch/self._testMethodName
        self.root.mkdir()
        self.root_patch = patch.object(module,'TEST',self.root)
        self.root_patch.start()
        self.addCleanup(self.root_patch.stop)

    def test_private_file_archive_preserves_evidence(self):
        original = self.root/'old.pid'
        original.write_bytes(b'1234\n')
        archived = module.archive_existing(original,'stale-pid')
        self.assertFalse(original.exists())
        self.assertEqual(archived.read_bytes(),b'1234\n')
        self.assertTrue(archived.is_relative_to(self.root/'lifecycle-backups'))
        self.assertIsNone(module.archive_existing(original,'stale-pid'))

    def test_private_path_rejects_outside_and_traversal(self):
        for path in [self.root.parent/'other',self.root/'..'/'other',Path('relative')]:
            with self.subTest(path=str(path)),self.assertRaises(RuntimeError):
                module.private_path(path)

    def test_running_start_is_noop_without_pidfiles(self):
        (self.root/'provision.json').write_text('{}')
        with patch.object(module,'guard'),patch.object(module,'port_open',return_value=True), \
                patch.object(module,'port_occupied',return_value=True), \
                patch.object(module,'owned_processes',side_effect=lambda role:[identity(role)]), \
                patch.object(module,'archive_existing') as archive, \
                patch.object(module.subprocess,'run') as run, \
                patch.object(module.subprocess,'Popen') as popen, \
                patch.object(module,'status',return_value={}),contextlib.redirect_stdout(io.StringIO()):
            module.start()
            archive.assert_not_called()
            run.assert_not_called()
            popen.assert_not_called()

    def test_restart_archives_stale_pid_config_and_output(self):
        (self.root/'provision.json').write_text('{}')
        game = self.root/'GameServer'
        (game/'framework').mkdir(parents=True)
        (game/'framework/Game_tlbb_2').write_bytes(b'private test placeholder')
        originals = {'skynet_2.pid':b'999999\n','config_2':b'old config\n','nohup_2.out':b'old output\n'}
        for name,data in originals.items():
            (game/name).write_bytes(data)
        game_calls = 0
        def owned(role):
            nonlocal game_calls
            if role['name']=='Game':
                game_calls += 1
                return [] if game_calls==1 else [identity(role)]
            return [identity(role)]
        with patch.object(module,'guard'),patch.object(module,'owned_processes',side_effect=owned), \
                patch.object(module,'port_open',side_effect=lambda port:port not in (15733,15734)), \
                patch.object(module,'port_occupied',side_effect=lambda port:port not in (15733,15734)), \
                patch.object(module.subprocess,'run',return_value=subprocess.CompletedProcess([],0,b'thread = 64\n')), \
                patch.object(module.subprocess,'Popen') as popen,patch.object(module.time,'sleep'), \
                patch.object(module,'status',return_value={}),contextlib.redirect_stdout(io.StringIO()):
            module.start()
            self.assertEqual(popen.call_count,1)
            self.assertEqual(popen.call_args.args[0],[str(game/'framework/Game_tlbb_2'),str(game/'config_2')])
        self.assertEqual((game/'config_2').read_bytes(),b'thread = 16\n')
        archives = list((self.root/'lifecycle-backups').iterdir())
        self.assertEqual(len(archives),3)
        self.assertEqual({p.read_bytes() for p in archives},set(originals.values()))

    def test_stop_requires_exact_confirmation(self):
        with patch.object(module,'guard'),patch.object(module,'owned_processes') as scan:
            with self.assertRaises(RuntimeError):
                module.stop('/home/ubuntu')
            scan.assert_not_called()

    def test_stop_reverse_order_owned_only(self):
        order = []
        with patch.object(module,'guard'), \
                patch.object(module,'owned_processes',side_effect=lambda role:[identity(role)]), \
                patch.object(module,'stop_owned',side_effect=lambda role,current:order.append(role['name'])), \
                patch.object(module,'status',return_value={}),contextlib.redirect_stdout(io.StringIO()):
            module.stop(str(self.root))
        self.assertEqual(order,['Game','Tool','DataCenter','Manager','MQTT','Mongo'])


class PidfdSignals(unittest.TestCase):
    def execute(self,change=None,ready=True):
        role = module.role_specs()[0]
        original = identity(role)
        current = dict(original)
        if change:
            current.update(change)
        with patch.object(module.os,'pidfd_open',return_value=91,create=True) as opened, \
                patch.object(module.signal,'pidfd_send_signal',create=True) as sent, \
                patch.object(module,'read_process',return_value=current), \
                patch.object(module.select,'select',return_value=([91] if ready else [],[],[])), \
                patch.object(module.os,'close') as closed:
            if change or not ready:
                with self.assertRaises(RuntimeError):
                    module.stop_owned(role,original)
            else:
                self.assertTrue(module.stop_owned(role,original))
            opened.assert_called_once_with(1234,0)
            closed.assert_called_once_with(91)
            return sent.call_args_list

    def test_pidfd_term_without_numeric_kill(self):
        calls = self.execute()
        self.assertEqual(len(calls),1)
        self.assertEqual(calls[0].args,(91,module.signal.SIGTERM,None,0))

    def test_reused_pid_no_signal(self):
        self.assertEqual(self.execute({'start_ticks':51}),[])

    def test_wrong_executable_no_signal(self):
        self.assertEqual(self.execute({'exe':'/usr/bin/sleep'}),[])

    def test_timeout_does_not_force_kill(self):
        calls = self.execute(ready=False)
        self.assertEqual(len(calls),1)
        self.assertEqual(calls[0].args[1],module.signal.SIGTERM)


if __name__=='__main__':
    unittest.main(verbosity=2)
