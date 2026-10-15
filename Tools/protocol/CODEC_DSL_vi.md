# DSL codec gói tin của server skynet (bản sống) và cách `specgen.py` đọc nó

Ngày lập: 2026-09-12. Áp dụng cho đường ray S1/G1 (Docs\03, Docs\06 mục 3).
Nguồn: `\\wsl.localhost\TLBB\home\ubuntu\GameServer`, chỉ đọc. Hash và ngày sinh ghi ở đầu `Registry\protocol\packets.yaml`.

## 1. Tệp nguồn và thứ tự nạp

| Vai trò | Tệp |
|---|---|
| Hằng ID | `services/game/packet_ids.lua` (`M.XYID_* = n`, 483 hằng). Chú thích ghi "sinh bởi split_packet.py", nhưng script này **không còn** trên server. |
| Nạp | `services/game/packet.lua`: 8 file `packet_types` trước, rồi 11 file `packet_domains` theo thứ tự core → movement → combat → item → shop → team → mission → social → pet → city → misc |
| Đăng nhập | `services/login/packet.lua`: 16 ID `packet.XYID_*` và 16 bảng gói ở cấp cao nhất |
| Luồng byte | `lualib/iostream.lua` (`bistream`/`bostream`) |
| Khung | `lualib-src/lua-netpack.c`: `struct {u16 id, sz, idx}` LE, 6 byte |
| Phát/nhận | `lualib/net.lua`: `packets[xy_id] = bảng`, lặp bằng `pairs()` |
| Chuỗi | `lualib/wire_charset.lua`: chế độ `utf8` là identity, cộng từ điển `wire_names_vi` cho chuỗi gửi đi |

Mỗi file gọi `M.bind(packet, bistream, bostream, gbk, define)`. **Định nghĩa sau cùng thắng** (gán lại `packet.X`). Hiện không có định nghĩa sống nào bị trùng. `CGAskChangeScene` trong `combat.lua:32` nằm trong khối `--[[ ]]`, nên chỉ bản ở `misc.lua` có hiệu lực. Hai định nghĩa khác cũng đã bị comment: `GUID` và `GCShowFashionDepotData`.

## 2. Hình dạng một bảng gói

```lua
packet.CGCharMove = {
    xy_id = packet.XYID_CG_CHARMOVE,         -- ID trên dây
    MAX_CHAR_PATH_NODE_NUMBER = 16,          -- hằng của bảng (self.X)
    new = function(o) ... end, ctor = function(self) ... end,
    bis = function(self, buffer) ... end,    -- GIẢI MÃ (server nhận: CG/CL/CGW)
    bos = function(self) ... return stream:get() end,  -- MÃ HOÁ (server gửi: GC/LC/WGC)
    read_x = function(self, stream) ... end, -- helper, được inline
}
```

- Chiều gói lấy từ tiền tố tên lớp: `CGW`, `WGC`, `CG`, `GC`, `CL`, `LC`.
- Codec quyết định bố cục trên dây là `bis` với gói C→S, `bos` với gói S→C. Codec còn lại, nếu có, chỉ được so sánh: `other_codec.agrees` nhận `true`, `sign-only` hoặc `false`.
- Bảng có `xy_id` bằng `packet.INVAILD_XYID` (0) hoặc `define.INVAILD_ID` (-1) là **struct**. `bis`/`bos` của struct nhận luồng của bên gọi: `bis(self, stream)`.

## 3. Phép toán luồng → kiểu trong đặc tả

| Lua | Kiểu | Ghi chú |
|---|---|---|
| `readuchar`/`writeuchar` | `u8` | |
| `readchar`/`writechar` | `i8` | |
| `readbool`/`writebool` | `bool` | đọc: `uchar == 1`; ghi: `char 0/1` |
| `readushort`/`writeushort` | `u16` | ghi bị **kẹp** vào [0, 65535] |
| `readshort`/`writeshort` | `i16` | ghi bị kẹp vào [-32768, 32767] |
| `readuint`/`writeuint`, `readint`/`writeint` | `u32`/`i32` | `string.pack` báo lỗi khi tràn |
| `readfloat`/`writefloat` | `f32` | |
| `readulong`/`writeulong` | `u64` | Lua `"L"`, 8 byte |
| `read(n)`/`write(s, n)`, n là hằng | `bytes[n]` | `write` cắt theo biên UTF-8 rồi đệm NUL |
| `read(len)` sau một trường độ dài | `str8`/`str16`/`str32` | `len_name` là tên trường độ dài, `guard` là điều kiện đọc, `min`/`max` rút từ guard |
| `read(len > N and N or len)` | thêm `clamp: N` | server đọc `min(len, N)` byte |
| `writeff(n)` | `bytes[n]`, `fill: 255` | |
| `packet.X.bos(obj, stream)`, `obj:bis(stream)` | `struct X` | |
| `local inner = bostream.new()` … `stream:write(inner:get(), n)` | `kind: blob` | tiền tố độ dài `len_type` |

Các lỗi có thật trong mã server được đánh `error`:
- `readuhcar` (ItemInfo, 3 chỗ) và `readlfoat` (GCArrive, GCCharSkill_Lead) không tồn tại, nên đọc tới đó sẽ ném lỗi.
- `social.lua:938` gọi helper `read_relation_guid_uchar_uchar(self, stream)`, truyền `self` vào vị trí tham số `stream`.

## 4. Cấu trúc điều khiển

- `if/elseif/else` thành `kind: if`, mỗi nhánh có `when`.
- `return` sớm: `if c then …; return end; PHẦN SAU` được viết lại thành `if c … else PHẦN SAU`.
- Mảng:
  - `for i = 1, N` thành `kind: array`. Số lần lặp là `count` (hằng), `count_field` (trường đã đọc hoặc ghi trước đó) hoặc `count_expr`. `count_on_wire: false` nghĩa là số phần tử không có trên dây.
  - `ipairs(t)` lấy `#t` đã ghi trước đó.
  - `local i = 1; while true do …; i = i + 1; if i > N then return end end` được đọc như `for i = 1, N` (GCScriptCommand).
- Tên trường tính **tương đối với phần tử mảng**: `self.list[i].x` thành `x` trong mảng `list`. Mảng song song dùng cùng biến lặp thì giữ tên `ten_mang[i]`.

## 5. Cú pháp điều kiện trong đặc tả

- Cú pháp giống C: `== != < <= > >= && || ! & | ^ ~ << >> + - * / // %`. Toán tử bit luôn có ngoặc.
- Tên:
  - `#x` là độ dài chuỗi hoặc số phần tử của `x`.
  - `ten[i]` là phần tử i của một mảng khác.
  - `$ten` là biến cục bộ phía server, không có trên dây.
  - `__body__` là độ dài thân gói (dùng ở CLAskLogin: `is_new_format = (#__body__ - size) >= 412`).
- Một số điều kiện dựa trên **trạng thái phía server** được mã hoá lại khi đưa lên dây. Bộ giải mã tham chiếu `speccodec.py` dựng lại chúng bằng plugin `derive`:
  - `GCCharBaseAttrib`: `m_uFlags[1..11]` được dựng từ 14 byte `new_flags` (dịch lên 1 bit từ bit 7).
  - `GCDetailAttrib_Pet`: `m_Flags` được dựng từ 12 byte `_nf` (bảng ánh xạ bit). Xem `annotations.py`.

## 6. Mức chắc chắn (`confidence`)

| Mức | Khi nào |
|---|---|
| `high` | Bố cục cố định hoặc mọi độ dài có biên; không có lỗi |
| `medium` | Có độ dài hoặc số phần tử **không có biên trên**, vòng `while`/`pairs`, hoặc `bis`/`bos` lệch cấu trúc |
| `low` | Thiếu codec quyết định; có độ dài hoặc số phần tử không suy ra được từ dây (`len_on_wire: false`); có lời gọi không phân tích được; hoặc có lỗi chạy thật trong codec |

## 7. Chạy lại và kiểm

```powershell
$env:PYTHONUTF8="1"; $py="C:\Program Files\Python313\python.exe"; $d="C:\TLBB\085\CY-Source\Tools\protocol"
& $py "$d\specgen.py"            # packets.yaml/.json, packets_summary.tsv, fields_flat.tsv, unknow_fields.tsv
& $py "$d\validate_capture.py"   # giải mã + khứ hồi từng byte trên _capture\capture.jsonl
& $py "$d\match085.py"           # match_085.tsv (so với lớp C++ 0.85)
& $py "$d\crosscheck_sim.py"     # crosscheck_tlbb_sim.tsv (so với tlbb_sim + PROTOCOL_SPEC_vi.md)
& $py "$d\codegen_cpp.py"        # thư viện C++ -> Src\Shared\ProtocolGen (chỉ ghi file có nội dung đổi)
& $py "C:\TLBB\085\CY-Source\Tests\protocol\run_protocol_tests.py" --asan   # cổng G1
```

Khi server đổi codec: chạy lại, rồi so `packets.yaml` với bản trước. Chỉ dòng `generated:` được phép đổi mà không có lý do.

### Bộ sinh C++ `codegen_cpp.py` (thư viện ProtocolGen)

- **Đầu ra** (sinh lại toàn bộ, tất định, không sửa tay) ở `Src\Shared\ProtocolGen`: `PgRuntime` (Reader/Writer little-endian kiểm biên), `PgIds.h`, `PgStructs`, `PgPackets_<domain>`, `PgFactory` + `PgFactoryTable.cpp`, `ProtocolGen.h`, `PgCoverage.tsv`. Gồm 497 gói và 34 struct (46 lớp; struct có `bis`/`bos` khác nhau thành `X_bis`/`X_bos`). Mẫu nằm ở `cpp_templates\`. Luật tay, mỗi luật dẫn dòng Lua server, nằm ở `codegen_cpp_rules.py`.
- **Ngữ nghĩa** bám `speccodec.py`. Điều kiện dựa trên trạng thái server thành **selector** (`is_new_format`, `present`, `has_extra_data`...). Nhánh có cùng bố cục dây thì gộp.
- **CMake**: thành phần `protocolgen` gồm `cys_protocolgen` và `cys_protocol_tests`; tuỳ chọn ASan `-DCYS_PG_ASAN=ON`.
- **API**: `#include "ProtocolGen.h"`, namespace `pg`, tên lớp như đặc tả (`pg::GCChat`).
  - Mỗi lớp có `bool read(Reader&)` (dữ liệu hỏng thì trả `false`, không đọc tràn), `void write(Writer&) const` (không bao giờ lỗi), `wireSize()`, `packetId()`.
  - Hàm chung: `pg::decodePacket(proto, id, body, size, &res, strict)`, `pg::encodeBody`, `pg::encodeFrame(p, idx, out)`, `pg::findPacket`, `pg::packetTable()`. ID: `pg::id::GCChat`, `pg::xyid::XYID_GC_CHAT`.
  - Chuỗi: `std::string` kèm `<trường>_wirelen` (`pg::kAutoLen` = lấy theo độ dài chuỗi; tiền tố có dấu, kể cả số âm, được giữ nguyên). `set_<trường>()` cắt theo biên UTF-8 như server. Chuỗi cố định là `std::array<uint8_t,N>` với `set_x()`/`x_text()`.
  - Số phần tử ghi ra do trường đếm quyết định.
- **Cổng G1** (`run_protocol_tests.py`): khứ hồi đúng từng byte 1.699 khung bản bắt 27/08; corpus sinh từ `speccodec.py`; fuzz (cắt ngắn, nối dài, đột biến, đổi id, ngẫu nhiên); kiểm ngược bằng `speccodec.py`; tuỳ chọn `--asan`. Kết quả ghi ở `Build\Logs\2026-09-12-protocol\gate_summary.txt`. Lệch được phép chỉ gồm các gói trong `KNOWN_ORACLE_DEVIATIONS` (luật tay).
- **Build**: `cmd /c --% "set CMAKE_BUILD_PARALLEL_LEVEL=4&& C:\TLBB\085\CY-Source\Tools\build\build.cmd x64 protocol-x64 Release protocolgen"`.
- **Bẫy PowerShell `--%`**: mọi thứ sau `--%` được chuyển nguyên văn cho `cmd`, kể cả `; lệnh PowerShell` viết tiếp trên cùng dòng.
  - `cmd /c` bỏ dấu `"` đầu và dấu `"` cuối của cả phần đó, nên phần thừa rơi vào tham số thứ 5 (TARGET) của `build.cmd`.
  - Triệu chứng: configure vẫn chạy, rồi `if "%TARGET%"==""` báo *The syntax of the command is incorrect*.
  - Cách tránh: đặt `cmd /c --% "..."` một mình trên một dòng, hoặc gọi qua một file `.cmd` bọc.
