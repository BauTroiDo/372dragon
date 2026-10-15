"""Extract actual CharSel state/host code; replace only heavy include dependencies."""
import argparse
import hashlib
import json
from pathlib import Path
from extract_hotkey_dispatch import extract


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--root', type=Path, required=True)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    root, out = args.root.resolve(), args.out.resolve()
    if not out.is_relative_to(root / 'Build'):
        raise ValueError('Output must stay inside Build')
    out.mkdir(parents=True, exist_ok=True)
    manifest = []

    def emit(source, target, transform):
        data = (root / source).read_bytes()
        body = transform(data.decode('utf-8-sig')).encode('utf-8')
        (out / target).write_bytes(body)
        manifest.append(dict(source=source, sha256=hashlib.sha256(data).hexdigest(),
                             output=target, output_sha256=hashlib.sha256(body).hexdigest()))

    procedure = 'Src/Client/WXClient/Procedure/'
    emit(procedure + 'GamePro_CharSel.h', 'role_header.inl',
         lambda s: s.replace('#include "GameProcedure.h"', '').replace('#include "LoginDataStructDef.h"', ''))
    signatures = ['CGamePro_CharSel::CGamePro_CharSel()',
                  'int CGamePro_CharSel::GetCurSelectRole() const',
                  'void CGamePro_CharSel::RestoreRoleSelection(int iIndex)',
                  'bool CGamePro_CharSel::SelectRoleIndex(int iIndex)',
                  'bool CGamePro_CharSel::IsValidIndex(int iRoleIndex)',
                  'void CGamePro_CharSel::SetUserName(const char* pUserName)',
                  'int  CGamePro_CharSel::GetCurRoleCount()']
    emit(procedure + 'GamePro_CharSel.cpp', 'role_state.inl',
         lambda s: '\n\n'.join(extract(s, sig) for sig in signatures))
    interface = 'Src/Client/WXClient/Interface/GMGameinterface_Script_GameProduceLogin.cpp'
    emit(interface, 'role_binding.inl', lambda s: 'namespace SCRIPT_SANDBOX {\n' + '\n\n'.join(
        extract(s, 'INT CGameProduce_Login::' + name + '(LuaPlus::LuaState* state)')
        for name in ['GetCurSelectRole', 'GetRoleCount']) + '\n}\n')
    emit('Src/Client/WXClient/Script/GMScriptSystm.cpp', 'role_registration.inl', lambda s: '\n'.join(
        line for line in s.splitlines() if 'CGameProduce_Login::s_pMetaTable->RegisterObjectFunctor(' in line
        and ('"GetCurSelectRole"' in line or '"GetRoleCount"' in line)))
    (out / 'extracted.json').write_text(json.dumps(manifest, indent=2) + '\n', encoding='utf-8')


if __name__ == '__main__':
    main()
