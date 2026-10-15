"""Compile the actual legacy dispatcher against test doubles, without editing it."""
import argparse
import hashlib
import json
import re
from pathlib import Path


def extract(source, signature):
    start = source.index(signature)
    opening = source.index('{', start)
    # Ignore braces in comments and strings when locating the complete C++ body.
    tokens = re.finditer(r'//[^\n]*|/\*.*?\*/|"(?:\\.|[^"\\])*"|\'(?:\\.|[^\'\\])*\'|[{}]', source[opening:], re.S)
    depth = 0
    for token in tokens:
        if token.group() == '{':
            depth += 1
        elif token.group() == '}':
            depth -= 1
            if depth == 0:
                return source[start:opening + token.end()]
    raise ValueError('Unterminated body: ' + signature)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--root', type=Path, required=True)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    root = args.root.resolve()
    out = args.out.resolve()
    if not out.is_relative_to(root / 'Build'):
        raise ValueError('Output must be inside Build')
    out.mkdir(parents=True, exist_ok=True)
    jobs = {
        'keyboard.inl': ('Src/Client/WXClient/Procedure/GamePro_Main.cpp', ['VOID CGamePro_Main::ProcessInput_Keybord(VOID)']),
        'action.inl': ('Src/Client/WXClient/Action/GMActionSystem.cpp', ['VOID CActionSystem::MainMenuBar_CancelPrepare(INT nIndex)', 'VOID CActionSystem::MainMenuBar_DoAction(INT nIndex, BOOL bPrepare)']),
        'input.inl': ('Src/Client/WXClient/Input/GMInputSystem.cpp', ['VOID CInputSystem::SetCanUseHotKey(INT value)', 'BOOL CInputSystem::AllowGameHotKey(const InputEvent& event)', 'VOID CInputSystem::Tick(VOID)']),
        'keys.inl': ('Src/Engine/Interface/TDInputSystem.h', ['enum KeyCode', 'enum InputEventID', 'struct InputEvent', 'enum InputCapture']),
    }
    manifest = []
    for target, (relative, signatures) in jobs.items():
        data = (root / relative).read_bytes()
        source = data.decode('utf-8-sig')
        body = '\n\n'.join(extract(source, signature) + (';' if target == 'keys.inl' else '') for signature in signatures) + '\n'
        (out / target).write_bytes(body.encode('utf-8'))
        manifest.append({'source': relative, 'sha256': hashlib.sha256(data).hexdigest(), 'output': target,
                         'output_sha256': hashlib.sha256(body.encode('utf-8')).hexdigest(), 'signatures': signatures})
    (out / 'extracted.json').write_text(json.dumps(manifest, indent=2) + '\n', encoding='utf-8')


if __name__ == '__main__':
    main()
