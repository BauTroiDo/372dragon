"""Vietnamese display strings; preserve every CY skill ID and numeric field."""
from pathlib import Path
import argparse, collections, datetime, re, shutil, sys
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'Tools/game'))
from dbc_inventory import Table
CY=ROOT.parent/'Tools/DATA NEW/DataCY31-08-26/Config'
DEST=ROOT/'Assets/CanonicalCY/Data/ConfigFolder'
NAMES={1:'Hàn Băng Hóa Kình',2:'Viêm Khí Hóa Kình',3:'Huyền Pháp Hóa Kình',4:'Bách Độc Hóa Kình',
 5:'Liễm Thần Quan Quang',6:'Bằng Hư Ngự Phong',7:'Tứ Tượng Quy Nhất · Băng',8:'Tứ Tượng Quy Nhất · Hỏa',
 9:'Tứ Tượng Quy Nhất · Huyền',10:'Tứ Tượng Quy Nhất · Độc',11:'Khí Định Thần Nhàn',12:'Lực Phá Càn Khôn',
 13:'Cương Khí Hộ Thể',14:'Tán Hồn Trận Thuật',15:'Khí Xung Tiêu Hán',16:'Thập Tam Thái Bảo',17:'Dục Huyết Tàn Thương',
 19:'Vu Cổ Kỳ Thuật',20:'Hoành Hành Vô Kỵ',21:'Hư Bất Thụ Bổ',22:'Mục Huyễn Thần Mê',23:'Tu La Lâm Thế',24:'Hồi Thiên Phạp Thuật'}

def description(group,src):
    def value(pattern):
        match=re.search(pattern,src);assert match,(group,pattern,src)
        return match[1]
    cooldown=value(r'此效果([0-9.-]+)秒')
    duration=value(r'持续(?:时间超过)?([0-9.-]+)秒') if group not in (12,14,19,22) else None
    if group<=4:
        element=['Băng','Hỏa','Huyền','Độc'][group-1]
        body=f"tăng {value(r'增加([0-9.-]+)点')} điểm công {element} cho bản thân trong {duration} giây"
    elif group==5:body=f"giảm {value(r'降低([0-9.%-]+)命中率')} tỷ lệ chính xác của mục tiêu trong {duration} giây"
    elif group==6:body=f"tăng {value(r'增加([0-9.%-]+)闪避率')} tỷ lệ né tránh của bản thân trong {duration} giây"
    elif group<=10:
        element=['Băng','Hỏa','Huyền','Độc'][group-7]
        body=f'chuyển 100% công thuộc tính của ba hệ còn lại thành công {element} trong {duration} giây'
    elif group==11:body=f"tăng {value(r'获得([0-9.-]+)点')} điểm phòng thủ hội tâm trong {duration} giây"
    elif group==12:body=f"gây sát thương lan lên mục tiêu và tối đa {value(r'最多([0-9.-]+)个')} đơn vị trong bán kính 5 mét quanh mục tiêu"
    elif group==13:body=f"tạo hộ thuẫn {value(r'拥有([0-9.-]+)血量')} điểm máu, hấp thụ 100% sát thương; mất khi hết sức chứa hoặc sau {duration} giây"
    elif group==14:body=f"tạo bẫy tại vị trí mục tiêu; sau 5 giây gây tản công 2 giây cho {value(r'对([0-9.-]+)个')} mục tiêu đối địch"
    elif group==15:body=f"tăng {value(r'增加([0-9.%-]+)，')} tốc độ nhận nộ khí trong {duration} giây"
    elif group==16:body=f'ngẫu nhiên miễn dịch một trong sáu loại sát thương: ngoại công, nội công, Băng, Hỏa, Huyền, Độc, trong {duration} giây'
    elif group==17:body=f"khiến mục tiêu mất {value(r'每秒失血([0-9.-]+)点')} máu mỗi giây trong {duration} giây"
    elif group==19:body='biến mục tiêu thành vịt Phiêu Phiêu, không thể tấn công nhưng vẫn có thể bị tấn công'
    elif group==20:body=f'giúp bản thân vô địch trong {duration} giây'
    elif group==21:body=f"giảm {value(r'降低([0-9.%-]+)，')} hiệu quả kỹ năng trị liệu lên mục tiêu trong {duration} giây"
    elif group==22:body='gây choáng mục tiêu 0.5 giây'
    elif group==23:body=f'giúp bản thân có 100% bạo kích; mất sau {duration} giây hoặc 2 lần tấn công'
    elif group==24:body=f'ngăn mục tiêu nhận hiệu quả kỹ năng hồi máu trong {duration} giây'
    else:raise AssertionError(group)
    result=f'{NAMES[group]}: Khi tấn công có cơ hội {body}. Tối đa 1 lần mỗi {cooldown} giây.'
    numbers=lambda s:collections.Counter(re.findall(r'\d+(?:\.\d+)?',s))
    assert numbers(src)==numbers(result),(group,src,result)
    return result

def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--apply',action='store_true');args=p.parse_args()
    rss=Table(CY/'RSSkill.txt');rows=[]
    for source in rss.rows:
        row=list(source);row[12]=NAMES[row[0]]
        for col in range(13,23):row[col]=description(row[0],source[col])
        assert row[:12]==source[:12];rows.append(row)
    dark=Table(CY/'DarkImpackStr.txt')
    original=dict(Table(ROOT.parent/'client/Data/ConfigDecoded/DarkImpackStr.txt').rows)
    living=dict(Table(ROOT.parent/'client_GL/Data/ConfigFolder/DarkImpackStr.txt').rows)
    by_meaning={zh:living[sid] for sid,zh in original.items() if sid in living}
    attributes={'内功攻击':'Nội công','冰属性攻击':'Băng công','外功攻击':'Ngoại công',
                '毒属性攻击':'Độc công','火属性攻击':'Hỏa công','玄属性攻击':'Huyền công','直接伤害':'sát thương trực tiếp'}
    translated=[]
    for sid,zh in dark.rows:
        vi=by_meaning.get(zh)
        if vi is None:
            match=re.fullmatch(r'增加(内功攻击|冰属性攻击|外功攻击|毒属性攻击|火属性攻击|玄属性攻击|直接伤害)([\d.]+)-([\d.]+)点',zh)
            assert match,('Unverified CY meaning',sid,zh)
            vi=f'Tăng {match[2]}-{match[3]} điểm {attributes[match[1]]}'
        assert not re.search(r'[\u4e00-\u9fff]',vi),sid
        assert collections.Counter(re.findall(r'\d+(?:\.\d+)?',zh))==collections.Counter(re.findall(r'\d+(?:\.\d+)?',vi)),sid
        translated.append([sid,vi])
    backup=ROOT/'Build/backups/equipment-skill-text'/datetime.datetime.now().strftime('%Y%m%d-%H%M%S')
    for name,table,content in [('RSSkill',rss,rows),('DarkImpackStr',dark,translated)]:
        raw=('\t'.join(table.types)+'\n'+'\t'.join('field'+str(i) for i in range(len(table.types)))+'\n'+
             '\n'.join('\t'.join(map(str,row)) for row in content)+'\n').encode('utf8')
        target=DEST/(name+'.txt')
        if target.read_bytes()!=raw and args.apply:
            backup.mkdir(parents=True,exist_ok=True);shutil.copy2(target,backup/target.name);target.write_bytes(raw)
        if args.apply:assert Table(target).rows==content
        print('PASS',name,'rows',len(content),'IDs and numbers unchanged','applied' if args.apply else 'checked')
    if args.apply:print('backup',backup)

if __name__=='__main__':main()
