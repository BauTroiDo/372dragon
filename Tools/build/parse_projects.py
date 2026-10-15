"""Đọc mọi .vcxproj / .vcproj / .dsp trong Src và tóm tắt: loại, tên output, file nguồn,
define, include, thư viện (cấu hình Release|Win32). Dùng làm đầu vào khi viết CMake.

Chạy:  python parse_projects.py > (in tóm tắt) ; JSON ghi ra Tools/build/projects.json
"""
import json
import os
import re
import sys
import xml.etree.ElementTree as ET

SRC = r'C:\TLBB\085\CY-Source\Src'
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'projects.json')
SRC_EXT = ('.c', '.cc', '.cpp', '.cxx')


def read_text(p):
    b = open(p, 'rb').read()
    for enc in ('utf-8-sig', 'utf-16', 'cp936', 'latin-1'):
        try:
            return b.decode(enc)
        except UnicodeError:
            continue
    return b.decode('latin-1')


def split_list(s):
    return [x.strip() for x in re.split(r'[;,]', s or '') if x.strip() and '%(' not in x]


def parse_vcxproj(p):
    t = read_text(p)
    t = re.sub(r'\sxmlns="[^"]+"', '', t, count=1)
    root = ET.fromstring(t.encode('utf-8'))
    info = {'kind': 'vcxproj', 'sources': [], 'defines': [], 'includes': [], 'libs': [], 'type': '', 'name': ''}
    for cfg in root.iter('PropertyGroup'):
        cond = cfg.get('Condition', '')
        if 'Release|Win32' in cond or not cond:
            for e in cfg:
                if e.tag == 'ConfigurationType' and e.text:
                    info['type'] = e.text
                if e.tag == 'TargetName' and e.text:
                    info['name'] = e.text
                if e.tag == 'CharacterSet' and e.text:
                    info['charset'] = e.text
    for idg in root.iter('ItemDefinitionGroup'):
        if 'Release|Win32' not in idg.get('Condition', ''):
            continue
        for cl in idg.iter('ClCompile'):
            for e in cl:
                if e.tag == 'PreprocessorDefinitions':
                    info['defines'] = split_list(e.text)
                if e.tag == 'AdditionalIncludeDirectories':
                    info['includes'] = split_list(e.text)
                if e.tag == 'PrecompiledHeaderFile':
                    info['pch'] = e.text
                if e.tag == 'RuntimeLibrary':
                    info['crt'] = e.text
        for ln in idg.iter('Link'):
            for e in ln:
                if e.tag == 'AdditionalDependencies':
                    info['libs'] = split_list(e.text)
                if e.tag == 'OutputFile':
                    info['output'] = e.text
                if e.tag == 'ModuleDefinitionFile':
                    info['def'] = e.text
    for cl in root.iter('ClCompile'):
        inc = cl.get('Include')
        if inc and inc.lower().endswith(SRC_EXT):
            excluded = any(e.tag == 'ExcludedFromBuild' and 'Release|Win32' in e.get('Condition', '') and (e.text or '').lower() == 'true' for e in cl)
            if not excluded:
                info['sources'].append(inc)
    return info


def parse_vcproj(p):
    t = read_text(p)
    t = re.sub(r'<\?xml[^>]*\?>', '', t, count=1)
    root = ET.fromstring(t.encode('utf-8'))
    info = {'kind': 'vcproj', 'sources': [], 'defines': [], 'includes': [], 'libs': [], 'type': '', 'name': root.get('Name', '')}
    for cfg in root.iter('Configuration'):
        if not cfg.get('Name', '').startswith('Release|Win32'):
            continue
        info['type'] = {'1': 'Application', '2': 'DynamicLibrary', '4': 'StaticLibrary'}.get(cfg.get('ConfigurationType', ''), cfg.get('ConfigurationType', ''))
        for tool in cfg.iter('Tool'):
            n = tool.get('Name')
            if n == 'VCCLCompilerTool':
                info['defines'] = split_list(tool.get('PreprocessorDefinitions'))
                info['includes'] = split_list(tool.get('AdditionalIncludeDirectories'))
            if n in ('VCLinkerTool', 'VCLibrarianTool'):
                info['libs'] = [x for x in re.split(r'\s+', tool.get('AdditionalDependencies', '') or '') if x]
                info['output'] = tool.get('OutputFile')
                if tool.get('ModuleDefinitionFile'):
                    info['def'] = tool.get('ModuleDefinitionFile')
    for f in root.iter('File'):
        rp = f.get('RelativePath', '')
        if rp.lower().endswith(SRC_EXT):
            excluded = False
            for fc in f.iter('FileConfiguration'):
                if fc.get('Name', '').startswith('Release|Win32') and fc.get('ExcludedFromBuild', '').lower() == 'true':
                    excluded = True
            if not excluded:
                info['sources'].append(rp)
    return info


def parse_dsp(p):
    t = read_text(p)
    info = {'kind': 'dsp', 'sources': [], 'defines': [], 'includes': [], 'libs': [], 'type': '', 'name': os.path.splitext(os.path.basename(p))[0]}
    m = re.search(r'# TARGTYPE "[^"]*\((\w+)\)', t)
    if m:
        info['type'] = m.group(1)
    rel = re.search(r'!IF\s+"\$\(CFG\)"\s*==\s*"[^"]*Release"(.*?)(!ELSEIF|!ENDIF)', t, re.S)
    block = rel.group(1) if rel else t
    for m in re.finditer(r'# ADD CPP (.*)', block):
        info['defines'] += re.findall(r'/D\s+"([^"]+)"', m.group(1))
        info['includes'] += re.findall(r'/I\s+"([^"]+)"', m.group(1))
    for m in re.finditer(r'SOURCE=(.+)', t):
        s = m.group(1).strip().strip('"')
        if s.lower().endswith(SRC_EXT):
            info['sources'].append(s)
    return info


def main():
    res = {}
    for dirpath, _, files in os.walk(SRC):
        for fn in files:
            low = fn.lower()
            p = os.path.join(dirpath, fn)
            try:
                if low.endswith('.vcxproj'):
                    info = parse_vcxproj(p)
                elif low.endswith('.vcproj'):
                    info = parse_vcproj(p)
                elif low.endswith('.dsp'):
                    info = parse_dsp(p)
                else:
                    continue
            except Exception as e:
                print('ERR', p, e)
                continue
            info['dir'] = os.path.relpath(dirpath, SRC)
            existing = sum(os.path.isfile(os.path.normpath(os.path.join(dirpath, s))) for s in info['sources'])
            info['sources_exist'] = existing
            res[os.path.relpath(p, SRC)] = info
    json.dump(res, open(OUT, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    for k in sorted(res):
        v = res[k]
        print('%-78s %-7s %-15s src=%4d/%4d name=%s' % (k[:78], v['kind'], v['type'][:15], v['sources_exist'], len(v['sources']), v.get('name', '')))
    print('JSON:', OUT)


if __name__ == '__main__':
    main()
