"""Record source evidence for guild/city gaps without modifying the running game."""
from pathlib import Path
import hashlib
import json
import re

ROOT = Path(__file__).resolve().parents[2]
SERVER = Path('//wsl.localhost/TLBB/home/ubuntu/cys-test-20260913')
OUT = ROOT / 'Build/Logs/2026-09-28-guild-advanced'


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    files = [
        ROOT / 'Src/Client/LuaApiGen/LuaApiGen_City.cpp',
        ROOT / 'Src/Client/LuaApiGen/LuaApiGen_GuildLeague.cpp',
        ROOT / 'Src/Client/WXClient/Network/CysGuildNet.cpp',
        ROOT / 'Src/Client/WXClient/Network/CysModernHandlers.cpp',
        ROOT / 'Build/world-gui/stage-play-21/Bin64/Game.exe',
        SERVER / 'GameServer/services/guild/guildmanager_core.lua',
        SERVER / 'GameServer/msgagent_module/ma_guild.lua',
        SERVER / 'GameServer/lualib/cys_guild.lua',
        SERVER / 'GameServer/lualib/script_base.lua',
        SERVER / 'GameServer/lualib/dynamicscenemanager_core.lua',
        SERVER / 'GameServer/services/msgagent.lua',
        SERVER / 'GameServer/services/scene/scenecore.lua',
        SERVER / 'GameServer/services/game/packet_domains/city.lua',
        SERVER / 'Game_2/Script/scripts/obj/city/pc_guilddirector.lua',
        SERVER / 'configs/CityInfo.txt',
        SERVER / 'configs/CityBuilding.txt',
    ]
    rows = []
    for path in files:
        data = path.read_bytes()
        rows.append({'path': str(path), 'size': len(data),
                     'sha256': hashlib.sha256(data).hexdigest()})
    source = (SERVER / 'GameServer/lualib/script_base.lua').read_text(encoding='utf8')
    definitions = set(re.findall(r'function\s+script_base:([A-Za-z0-9_]+)\(', source))
    result = {
        'scope': 'source audit and isolated Lua reproductions; no live gameplay acceptance test',
        'server_root': str(SERVER),
        'files': rows,
        'generated_stub_functions': {
            receiver: len(re.findall(r'return Stub\(state, "'+receiver+r'",',
                (ROOT/f'Src/Client/LuaApiGen/LuaApiGen_{receiver}.cpp').read_text(encoding='utf8')))
            for receiver in ['City', 'GuildLeague']
        },
        'script_base_defined': {name: name in definitions for name in
            ['CityGetBuildingLevel', 'CityBuildingChange', 'CitySetLevel',
             'CityGetAttr', 'CityChangeAttr', 'SetBagItemParam', 'GetBagItemParam']},
        'city_building_level_constant_one': bool(re.search(
            r'function script_base:CityGetBuildingLevel\(\)\s+return 1\s+end', source)),
    }
    (OUT/'source-audit.json').write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding='utf8')
    print(json.dumps({k: v for k, v in result.items() if k != 'files'}, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()
