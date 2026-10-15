# 06 — Giao thức, server và đồng bộ dữ liệu client–server

Ngày lập: 2026-09-12. Áp dụng cho đường ray S và G1. Số liệu đo ở chế độ chỉ đọc ngày 12/09; không in mật khẩu nào.

## 1. Sự thật về server đang chạy

| Chủ đề | Dữ kiện | Bằng chứng |
|---|---|---|
| Tiến trình | 4 tiến trình skynet trên một máy: Manager (id 8, cluster 8888), DataCenter (9), Tool (6, web 8000), Game khu 1 (2; cluster 2528; console debug 6002). Chỉ có khu 1 (`ZONE_LIST=(1)`). `thread=64`, `enablecipher=true`. `main.lua` gọi `license_check.check_or_abort()` trước mọi thứ. | `GameServer\start_zone.sh`, `config_maker.lua`, `main.lua` |
| Dịch vụ của Game | 18 service: gamed, logind, world, scene/copyscene/dynamicscene manager, playermanager, guildmanager, activity, ybexchange, gen_serial, agent_poll, clusteragentproxy, clusterd, debug_console, 3 proxy DB | `confs\publish_yu\cluster_db_conf.lua` |
| Cơ sở dữ liệu | MongoDB 4.4.31, chỉ nghe localhost, 3 DB. Mỗi proxy chia tải cho 20 worker. Còn cấu hình MySQL cũ không dùng. | `services\dbproxy.lua` |
| MQTT | Mosquitto 2.0.11, chủ đề `luaserver/#`: bet, channel, resource/update, ban/unban, số người online, phát thanh. Đây là kênh quản trị (suy luận). | `services\mqtt_core.lua` |
| Scene | Mỗi scene đang bật có một service. Danh sách scene lấy từ `SceneInfo.ini` (790 mục). Cổng đăng nhập sẵn sàng sau khoảng 75 giây. | `lualib\scenemanager_core.lua:177-188`, `services\scene\scenecore.lua:107` |
| Định nghĩa giao thức | `services\game\packet_ids.lua` (sinh bởi `split_packet.py`), cộng 8 file `packet_types` và 11 file `packet_domains`. Đăng nhập dùng giao thức riêng: 16 ID trong `services\login\packet.lua`. | |
| Số gói | 482 ID game (208 CG + 8 CGW; 256 GC + 8 WGC) và 16 ID đăng nhập. ID rải từ 0 tới 1772, cộng thêm 2000. Có 518 lớp codec Lua. | |
| Khung gói | Header 3 trường u16 little-endian `{id, size, idx}`, không mã hoá luồng. Phiên bản đăng nhập: chú thích ghi "新版客户端 uVersion 0x705 → 0x785". | `lualib-src\lua-netpack.c:31-35`, `Tools\stress-test\PROTOCOL_SPEC_vi.md` |
| Mã hoá dây | `client_wire_encoding = "utf8"`. `lualib\wire_charset.lua` (68 dòng) là nơi duy nhất mã hoá chuỗi, có 27 file dùng. Tên NPC/quái được thay nguyên chuỗi từ `wire_names_vi`. | `confs\publish_yu\server_conf.lua:35` |
| Script | `Game_2` có 3.855 file Lua (348.261 dòng). `Game_2\Scene` có 378 `.scn`, 2.888 `.ini`, 483 `.path`, 148 `.esd`, 5 `.nav`. | |

**Bẫy:** bản gương `C:\TLBB\085\.codegraph-src\server` cũ hơn server thật. Nó chưa có `wire_charset.lua`, và `packet.lua` trong đó vẫn nạp `"gbk"`. Mọi thứ liên quan mã hoá phải grep bản sống `\\wsl.localhost\TLBB\home\ubuntu\GameServer`.

## 2. So với giao thức 0.85 (mã C++ trong Reference)

| Chỉ số | C++ 0.85 (`Common\PacketDefine.h`) | skynet |
|---|---|---|
| Số ID | 483 (+ NONE, `PACKET_MAX = 753`) | 482 game + 16 đăng nhập |
| CG / GC | 162 / 216 | 208 (+ 8 CGW) / 256 (+ 8 WGC) |
| Gói giữa các server | 91 (World/Login/Billing) | 0 (dùng lời gọi cluster nội bộ) |
| Cách đánh số | Theo khối liền: GC 1–216, login 400–455, CG và gói nội bộ 500–752 | Rải rác 0–1772, cộng 2000 |
| Tên trùng nhau (CG/GC, đã chuẩn hoá) | 271 chung · 107 chỉ có ở C++ · 201 chỉ có ở skynet | |
| Header | `PacketID_t + WORD + UINT`, 8 byte, header bị XOR | 3 × u16 |
| Phiên bản | `CURRENT_VERSION 0x00000005` | 0x785 |

- **24/24 ID mẫu lệch số.** Ví dụ `GC_ENTERSCENE` là 4 ở 0.85 nhưng 1764 ở skynet; `CG_CHARMOVE` 520 và 352; `CG_CHAT` 545 và 753.
- **Bố cục trường:** chỉ khoảng 4/27 gói giống hệt: CGHeartBeat, GCRetChangeScene, GCDelObject, GCLevelUp. Số còn lại bị đảo thứ tự, mở rộng hoặc khác hẳn. Ví dụ:
  - `CGConnect`: tài khoản dài 16 byte ở 0.85, 50 byte ở skynet.
  - `CGChat`/`GCChat`: độ dài 1 byte ở 0.85, 4 byte ở skynet, kèm khối ngoại trang 67 byte.
  - `GCNewMonster`: 5 trường ở 0.85, khoảng 27 trường ở skynet.

**Kết luận:** cùng dòng TLBB (288 tên lớp gói chung), nhưng **không tương thích trên dây** với 0.85. Client mới phải nói giao thức skynet (quyết định D1).

## 3. Đặc tả giao thức máy đọc được (S1, G1)

- **Tệp đặc tả:** `Registry\protocol\packets.yaml`. Mỗi gói ghi:
  - `id`, `name`, chiều (`CG`/`GC`/`CL`/`LC`/`CGW`/`WGC`), `domain`;
  - danh sách trường, mỗi trường có `name`, `type` (`u8`/`u16`/`u32`/`i32`/`f32`/`bytes[N]`/`str8`/`str16`/`str32`/`array<…>`), độ dài hoặc giới hạn, và điều kiện (cờ bit);
  - nguồn (file:dòng của codec Lua), mức chắc chắn, ghi chú.
- **Bộ sinh** `Tools\protocol\specgen.py` đọc codec Lua trong `packet_types` và `packet_domains` của **bản sống** (qua `\\wsl.localhost`, chỉ đọc). Việc đầu tiên là ghi lại cú pháp DSL của các file codec đó.
- **Đặt tên trường `unknow_N`:**
  - Ưu tiên ghép với lớp C++ 0.85 cùng tên khi bố cục khớp nhau (288 lớp chung).
  - Nếu không khớp, lấy từ hàm Read/Write của lớp gói trong Game.exe của B, qua Ghidra (script `DumpPacketById`).
- **Gói định nghĩa hai lần:** kiểm ngày 12/09 thì **không có định nghĩa trùng nào còn hiệu lực**. Bản `CGAskChangeScene` ở `combat.lua:32` nằm trong khối chú thích `--[[ ]]`; chỉ bản ở `misc.lua:2925` chạy. `GUID` và `GCShowFashionDepotData` cũng đã bị chú thích. Nếu sau này có định nghĩa trùng thì đặc tả ghi bản thắng (bản nạp sau theo thứ tự trong `packet.lua`).
- **Kết quả ngày 12/09:**
  - Đặc tả ở `Registry\protocol\packets.yaml` gồm 497 gói và 34 struct, 3.321 trường, trong đó 533 trường tên `unknow*`. Mô tả DSL codec: `Tools\protocol\CODEC_DSL_vi.md`.
  - Kiểm trên bản bắt 27/08 (1.699 khung, 51 ID): giải mã rồi mã hoá lại khớp từng byte. Tuy vậy cổng G1 vẫn cần một bản bắt đầy đủ từ chính `client_GL`.
  - File `split_packet.py` không còn tồn tại ở đâu.
  - Một ID không có codec: `XYID_GC_MONSTER_SPEAK` = 1229.
- **Lỗi tiềm ẩn phía server** (chưa sửa, vì server đang chạy):
  - Gõ nhầm `readuhcar` (3 chỗ trong `ItemInfo.bis`) và `readlfoat` (`GCArrive.bis`, `GCCharSkill_Lead.bis`).
  - `social.lua:938` truyền `self` vào chỗ cần stream.
  - Handler `request:CGShowFashionDepotData` trả về một gói có định nghĩa đã bị chú thích, nên sẽ crash nếu được gọi.
  - ID 1032: server giải mã như `CGShowFashionDepotData`, còn client dùng cho `GCYuanBao`.
  - `GCItemList` (`item.lua:844-867`), **chờ người dùng**:
    - Nhánh thứ ba kiểm `self.type`. Gói không có trường này (luôn nil), nên nhánh không bao giờ chạy.
    - Nhánh `TYPE_ITEM` gọi `stream:write(item.data)` mà không truyền độ dài, nên `bostream:write` báo lỗi.
  - `GCScriptCommand` (`mission.lua:280-285`, `m_nCmdID == 4`), **chờ người dùng**: ghi độ dài `#event[i].str` nhưng lại kiểm `self.event[i].len`. Giá trị này không có trên dây; nếu nil thì Lua báo lỗi.
  - `ItemInfo.bis` (`item_types.lua:152`), **chờ người dùng**: kiểm `self.pet_equip_type ~= 1`, nhưng `bis` không đọc trường này (luôn nil). Vì vậy với trang bị trân thú (`flag == 7`) có `pet_equip_type == 1`, server đọc nhầm nhánh so với `bos`.
- **Lệch trong bot `Tools\stress-test\tlbb_sim`:** `GC_CHARMOVE` ghi 653 (server dùng 564, nên bộ đọc gói di chuyển của bot không bao giờ chạy); `GC_CHAR_MOVE_RESULT` ghi 568 (server dùng 1090); `CG_HEART_BEAT` để `None` (server dùng 3).
- **Phiên bản đặc tả:** mỗi lần sinh ghi hash của các file codec và ngày sinh. Server đổi codec thì phải sinh lại, rồi diff với bản trước.

## 4. Sinh codec từ đặc tả

| Đích | Nơi ghi | Yêu cầu |
|---|---|---|
| C++ (client mới) | `Src\Client\WXNetPackets\gen\` | Lớp `Read`/`Write` theo API `SocketInputStream`/`SocketOutputStream` của 0.85, khung 6 byte. **Kiểm biên mọi độ dài**: vượt giới hạn thì cắt và ghi log, không crash. Chuỗi UTF-8 có giới hạn byte rõ ràng. |
| Python (`Tools\stress-test\tlbb_sim`) | codec của bot | Bot và client dùng chung một nguồn sự thật |
| Lua (server) | **không sinh** (server là chủ) | Có bộ kiểm so codec Lua với đặc tả sau mỗi lần server đổi |

**Kiểm:**
- Khứ hồi đúng từng byte trên các phiên bắt bằng `_capture\sniffer.py` (≥ 1 phiên chơi đầy đủ của `client_GL`).
- Fuzz các trường độ dài.

## 5. Đồng bộ bảng client ↔ server

**Dữ kiện:**
- Bảng server phải GBK: `txtreader.lua` chạy `gbk.toutf8` cho mọi dòng và bỏ các dòng bắt đầu bằng `#`.
- Mức GBK đo được:

  | Bảng | Server | Client (cùng tên) |
  |---|---|---|
  | EquipBase | 20.843/20.844 dòng GBK | chỉ 3/19.895 dòng không phải UTF-8 |
  | MonsterAttrExTable | 18.651/18.824 dòng GBK | |
  | PetAttrTable | 5.000/5.008 dòng GBK | |

- 144 tên file có mặt ở cả `ConfigFolder` của client (419 file) và `configs` của server (221 mục).
- ItemVisualChar, CharModelEx, ItemVisualLocator chỉ có ở client.
- Trùng tên không có nghĩa là cùng bảng: `ShopTable.txt` có 1.227 cột ở server nhưng 11 cột ở client.

**ID đang lệch** (server/client):

| Bảng | Cột | ID chung | Chỉ server | Chỉ client |
|---|---|---|---|---|
| EquipBase | — | 19.892 | 948 | 0 |
| MonsterAttrExTable | 71/71 | 18.512 | 310 | 0 |
| PetAttrTable | 51/51 | 4.804 | 202 | 0 |
| SkillData_V1 | 48/48 | 15.225 | 1.268 | 0 |
| ImpactSEData_V1 | 23/23 | 5.198 | 2 | 65 |
| CharTitleNew / Exterior_Ride | 53/53 · 26/26 | 443 · 179 | 49 · 19 | 0 |
| CharMount | **14/15** | 182 | 19 | 0 |

**Bộ kiểm** `Tests\validators\table_parity.py` (V10). Với mỗi bảng dùng chung, nó kiểm:
- header: số cột và tên cột;
- tập ID;
- các cột khoá phải trùng: Type, Visual, cột model…;
- mã hoá: server GBK thuần, client đúng dạng của S1.

Lệch nào đã biết từ trước thì ghi vào `Registry\parity-known.yaml` để không báo lại.

## 6. Thêm nội dung phía server: ma trận reload/restart

| Thay đổi | File | Áp dụng bằng |
|---|---|---|
| Script gameplay (`Game_2`) | `Game_2\**\*.lua` | reload scripts qua `reload_configs.exp` (console 6002), chạy `clearcache` trước |
| EquipBase | `configs\EquipBase.txt` (GBK) | `reload_equip_base` |
| MonsterAttrEx | | `reload_monster_attr_ex` |
| ShopTable | | `reload_shop_table` |
| StdImpact / drop | | `reload_std_impact` / `reload_drop` |
| PetAttrTable, CommonItem, CharTitleNew, `exterior_*`, `lualib`, codec gói, service, scene mới | | **Restart**: `./start_zone.sh stop && ./start_zone.sh all`, khoảng 75 s (chờ tối đa 900 s) |

**Kiểm sau thay đổi** (`AGENTS.md`):
1. `systemctl is-active mongod mosquitto tlbb-game`
2. `/usr/local/tlbb/status.sh` hoặc `C:\TLBB\085\wsl\Status-TLBB.cmd`
3. Cổng đăng nhập nối được qua IP LAN của Windows
4. Log mới nhất trong `/home/ubuntu/log/YYYYMM` không có lỗi mới

**Thứ tự khi thêm một món (item, quái, pet, tọa kỵ, thời trang):**
1. Registry cấp ID.
2. Ghi dòng vào bảng client (UTF-8, khoá GBK, sắp tăng).
3. Ghi dòng vào bảng server (GBK, cùng ID, cùng cột).
4. Sinh lại `wire_names_vi` nếu có tên mới.
5. Reload hoặc restart.
6. Chạy V09/V10.
7. Người dùng xem trong game.

**Thêm map:** thêm vào `SceneInfo.ini`; thêm `.scn`/`.ini`/`.path`/`.nav` vào `Game_2\Scene`, cùng quái và điểm tuần tra; restart. Scene đích không có service thì người chơi bị đẩy về Đại Lý (xem bẫy trong audit 11/09).

**Thêm hệ thống mới:** thêm ID gói, codec và handler vào `packet_ids.lua` và `packet_domains`; sinh lại đặc tả; restart.

## 7. Giới hạn chuỗi và kích thước gói

| Gói (ID) | Giới hạn | Nguồn |
|---|---|---|
| GCNewPlatform (378) | mô tả 1–31 byte (Game.exe `0x14067b010`) | `packet_domains\misc.lua` ~377–384 |
| GCPrivateInfo (291) | chữ ký ≤ 34 byte; một chuỗi mặc định tiếng Trung 39 byte từng làm crash | `packet_domains\social.lua` ~1068–1073 |
| GCRetSecKillData (1072) | ≤ 12 món (chú thích ghi "error[873]", có lẽ ghi nhầm) | `misc.lua:5496` |
| Trường độ dài cố định | tên 30 B, tài khoản 50 B, IP 24 B | `services\login\packet.lua` |
| Danh hiệu / tên hiển thị | bộ đệm tên 0x1E (< 30 B), danh hiệu 0x22 (< 34 B) | bộ nhớ `tlbb-platform-packet-crash` |
| Shop | ≤ 200 món mỗi gói | bộ nhớ shop |
| `wire_names_vi` | ≤ 29 B mỗi tên | `tlbb-wire-name-translation` |

**Chính sách:**
- Server cắt UTF-8 an toàn (`truncate_utf8_bytes`) cho **mọi** trường độ dài cố định. Hiện chỉ có 2 chỗ gọi, nên rà soát toàn bộ là việc của S1.
- Client mới kiểm biên theo đặc tả và không bao giờ crash vì chuỗi dài.
- Khi client mới đã thay `client_GL` (M5), có thể nới giới hạn ở cả hai phía cùng lúc.

## 8. Vai trò của server C++ 0.85 và của tlbb15

- **Server C++ 0.85:**
  - Làm hộp cát cho pha E1 (tài liệu 04, mục 7).
  - Là tài liệu cho: công thức chiến đấu (`Common\Combat`, `BuffImpactMgr`, `DirectlyImpactMgr`, `SkillDataMgr`, `GameDefine_Attr.h`, `GameStruct_*`); lược đồ DB (`环境_v0-85-9602_Win\tlbbdb.sql`); API script `LuaFn*`; cách thiết kế luồng World/Login/Billing.
  - Có baseline 4.244 script và 244 scene trong `Reference\…\Build\Server\Public`.
- **tlbb15** (trong DataCY):
  - Là server C++ Linux x64 bị hook: `run.sh` tắt ASLR toàn hệ thống và nạp `Serverhook.so` bằng `LD_PRELOAD`. Billing viết bằng Go (`liuguangw/billing_go`, `bill_type: 1` = 怀旧).
  - Bảng theo bố cục HJ; có 5.196 script và 329 `.scn`.
  - **Không dùng làm server.** Chỉ để tham khảo khi cần so bảng HJ (ví dụ CommonItem 26 cột so với 27). Về an toàn, không bao giờ chạy `run.sh` của nó trên máy này.

## 9. Vận hành và an toàn

- Không ghi mật khẩu MongoDB/MQTT/MySQL/hệ thống vào tài liệu, commit hay log.
- MongoDB giữ bản 4.4.31 và chỉ bind 127.0.0.1. Chỉ chạy khu 1.
- Sao lưu cấu hình trước mọi thay đổi lớn, theo quy ước `.bak-<việc>-<ngày>` đang dùng trên server.
- Các lỗi baseline có từ thời VMware không phải do ta gây ra: Tool thử MySQL 3306; thiếu `Game_2/Scene/zijinwai2.scn` cho scene 747; thiếu monster type 15440 và 15433. Muốn sửa thì làm thành thay đổi riêng.
- Không restart server khi người dùng đang chơi mà chưa báo trước, vì token của người dùng sẽ chết.
