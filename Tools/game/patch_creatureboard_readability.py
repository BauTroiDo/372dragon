"""Widen name/title labels and fit their text area; canonical data stays read-only."""
import hashlib,re,xml.etree.ElementTree as ET

SOURCE_SHA='266329ddc1a8af91359e4945c1d84e9051276bb63e4508e491f95b52fade26d9'
NAME='Schema/TLBBLook_CreatureBoard.looknfeel.xml'

def generate(source):
    assert hashlib.sha256(source).hexdigest()==SOURCE_SHA,'Unreviewed CreatureBoard source'
    text=source.decode('utf8')
    changes={'MaxWidth':'600','MinHeight':'32','HorzFormatting':'WordWrapCentred','FitTextArea':'True'}
    for suffix in ['__auto_playername__','__auto_playertitle__']:
        pattern=r'(<Child type="TLBB_SelfWindow" nameSuffix="'+suffix+r'">)(.*?)(</Child>)'
        matches=list(re.finditer(pattern,text,re.S));assert len(matches)==1
        match=matches[0];body=match[2]
        for name,value in changes.items():
            prop=f'<Property name="{name}" value="{value}" />'
            regex=r'<Property name="'+name+r'" value="[^"]*"\s*/>'
            if re.search(regex,body):body=re.sub(regex,prop,body)
            else:body=body.rstrip()+'\r\n      '+prop+'\r\n    '
        text=text[:match.start()]+match[1]+body+match[3]+text[match.end():]
    result=text.encode('utf8')
    before=ET.fromstring(source);after=ET.fromstring(result)
    for root in [before,after]:
        for child in root.find("WidgetLook[@name='TLBB_Look_CreatureBoard']").findall('Child'):
            if child.get('nameSuffix') in ['__auto_playername__','__auto_playertitle__']:
                for p in list(child):
                    if p.tag=='Property' and p.get('name') in changes:child.remove(p)
        for node in root.iter():node.text=None;node.tail=None
    assert ET.tostring(before)==ET.tostring(after),'Unexpected hierarchy/event/property change'
    return result,{'source_sha256':SOURCE_SHA,'sha256':hashlib.sha256(result).hexdigest(),'properties':changes}
