#!/usr/bin/env python3
"""Owned dynamic-loopback creation tests. Synthetic wire fixtures stay in RAM."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import socket
import struct
import subprocess
import threading
import time
from run_netcore_tests import exact, frame, login_reply, receive_frame

CY = Path(__file__).resolve().parents[2]
SCENARIOS = ('success', 'split', 'pause-pump', 'existing', 'manual-retry', 'deny', 'refuse',
             'full-list', 'four-list', 'duplicate-guid', 'bad-permission', 'permission-timeout',
             'idle', 'timeout', 'missing-list', 'trickle', 'short-result', 'unknown-result',
             'wrong-order', 'wrong-list', 'changed-list', 'unsolicited', 'peer-close',
             'cancel-ready', 'cancel-create', 'cancel-inflight', 'destroy-ready', 'command-cap')


def server(listener, scenario, evidence, fixtures):
    try:
        connection, _ = listener.accept()
        with connection:
            connection.settimeout(4)
            def receive(expected_id, expected_index, expected_size):
                packet_id, index, body = receive_frame(connection, evidence)
                assert (packet_id, index, len(body)) == (expected_id, expected_index, expected_size), 'outbound metadata'
                return body
            body = receive(355, 0x7b00, 110)
            assert body[4:54].split(b'\0',1)[0] == b'unit-create', 'synthetic account'
            connection.sendall(frame(311, bytes(64)))
            body = receive(299, 0x7c00, 949)
            assert body[:50].split(b'\0',1)[0] == b'unit-create%unit-value', 'synthetic auth'
            connection.sendall(frame(223,login_reply()) + frame(554,bytes(6)))
            receive(711,0x7d00,50)
            initial = '1' if scenario in ('existing','changed-list') else '0'
            if scenario=='full-list': initial='3'
            if scenario=='four-list': initial='4'
            if scenario=='duplicate-guid': initial='duplicate'
            data = fixtures[initial]
            if scenario=='unsolicited': data += frame(777,struct.pack('<i',1))
            connection.sendall(data)
            early=('full-list','four-list','duplicate-guid','idle','unsolicited','cancel-ready','destroy-ready')
            if scenario not in early:
                receive(776,0x7e00,0)
                if scenario=='command-cap':
                    for i in range(16):
                        if i: receive(776,(0x7e+i)<<8,0)
                        connection.sendall(frame(777,struct.pack('<i',0)))
                    assert connection.recv(1)==b'', 'cap rejects seventeenth command'
                    evidence['closed']=True
                    return
                if scenario != 'permission-timeout':
                    flag=0 if scenario=='deny' else 2 if scenario=='bad-permission' else 1
                    connection.sendall(frame(777,struct.pack('<i',flag)))
                    if flag==1:
                        try:
                            body=receive(522,0x7f00,53)
                        except EOFError:
                            assert scenario=='cancel-create','unexpected cancelled create'
                            evidence['closed']=True
                            return
                        assert body[:30].split(b'\0',1)[0]=='Việt中文'.encode(),'UTF8 name'
                        model,u1,u2,hair,face,portrait,outfit,u7=struct.unpack('<iBBiiBii',body[30:])
                        assert (model,u1,u2,hair,face,portrait,outfit,u7)==(1,0,0,5,100,22,2,0),'appearance mapping'
                        if scenario=='peer-close':
                            evidence['server_closed']=True
                            return
                        if scenario not in ('timeout','cancel-create','cancel-inflight'):
                            result=4 if scenario in ('refuse','manual-retry') else 7 if scenario=='unknown-result' else 0
                            response=frame(440,struct.pack('<i',result))
                            if scenario=='short-result': response=frame(440,bytes(3))
                            elif scenario=='wrong-order': response=fixtures['1']
                            elif scenario not in ('missing-list','trickle','refuse','manual-retry','unknown-result'):
                                refreshed='2' if scenario=='existing' else '0' if scenario=='wrong-list' else 'changed' if scenario=='changed-list' else '1'
                                response += fixtures[refreshed]
                            if scenario=='trickle':
                                for value in response[:3]:
                                    connection.sendall(bytes([value])); time.sleep(0.1)
                            elif scenario=='split':
                                for start,end in ((0,1),(1,5),(5,9),(9,16),(16,len(response))): connection.sendall(response[start:end])
                            else: connection.sendall(response)
                            if scenario=='manual-retry':
                                receive(522,0x8000,53)
                                connection.sendall(frame(440,struct.pack('<i',0))+fixtures['1'])
            assert connection.recv(1)==b'', 'no extra packet or automatic retry'
            evidence['closed']=True
        listener.settimeout(0.05)
        try:
            unexpected,_=listener.accept(); unexpected.close()
            raise AssertionError('unexpected reconnect')
        except socket.timeout:
            pass
    except Exception as error:
        evidence['server_error']=type(error).__name__+': '+str(error)


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--exe',required=True)
    parser.add_argument('--out',required=True)
    args=parser.parse_args()
    executable=(CY/args.exe).resolve()
    output=Path(os.path.abspath(CY/args.out))
    if not output.is_relative_to(CY/'Build'/'Logs') or output.exists(): raise SystemExit('Choose new Build/Logs output')
    for path in [output,*output.parents]:
        if path.exists() and (path.is_symlink() or path.is_junction()): raise SystemExit('No junction output')
    assert executable.is_relative_to(CY/'Build') and executable.is_file(), 'CY executable required'
    output.mkdir(parents=True)
    environment=os.environ.copy();environment.pop('CYS_BOT_PWD',None)
    def run(arguments):
        process=subprocess.run([str(executable),*arguments],cwd=CY,env=environment,capture_output=True,timeout=8)
        assert b'unit-value' not in process.stdout+process.stderr and b'unit-create%' not in process.stdout+process.stderr,'credential output'
        return process
    fixtures={}
    for kind in ('0','1','2','3','4','duplicate','changed'):
        result=run(['--fixture',kind]);assert result.returncode==0 and not result.stderr,'synthetic fixture generation'
        fixtures[kind]=result.stdout
    result=run([])
    (output/'unit.log').write_bytes(result.stdout+result.stderr)
    summary={'scope':'interactive-permission-create-loopback-only','unit_rc':result.returncode,
             'raw_output':False,'executable_sha256':hashlib.sha256(executable.read_bytes()).hexdigest(),'cases':[]}
    assert result.returncode==0,'unit failed'
    for scenario in SCENARIOS:
        evidence={'scenario':scenario,'tx_ids':[],'tx_indices':[]}
        with socket.socket(socket.AF_INET,socket.SOCK_STREAM) as listener:
            listener.bind(('127.0.0.1',0));listener.listen(1);listener.settimeout(5)
            helper=threading.Thread(target=server,args=(listener,scenario,evidence,fixtures))
            helper.start();started=time.monotonic()
            result=run(['--loopback',str(listener.getsockname()[1]),scenario])
            helper.join(timeout=5);assert not helper.is_alive(),'helper exited'
            evidence['elapsed_ms']=round((time.monotonic()-started)*1000)
            evidence['exit_code']=result.returncode
            evidence['passed']=result.returncode==0 and 'server_error' not in evidence
            (output/(scenario+'.log')).write_bytes(result.stdout+result.stderr)
        summary['cases'].append(evidence)
        (output/'summary.json').write_text(json.dumps(summary,indent=2)+'\n',encoding='utf-8')
        assert evidence['passed'], scenario+': see safe metadata'
        print('PASS',scenario,'tx='+str(len(evidence['tx_ids'])))
    print('PASS interactive creation unit and',len(SCENARIOS),'loopback cases; no live auth')


if __name__=='__main__': main()
