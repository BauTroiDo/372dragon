# NPC mở các khung còn lỗi — nửa server (ĐÃ CÀI 20/09)

Người dùng yêu cầu 19/09: *"Cần một NPC để mở các khung còn lỗi."*

**Trạng thái: đã cài lên server riêng, không cần restart.** Vào game, nói chuyện với **bất kỳ NPC
trồng trọt nào ở Đại Lý** — menu 11 khung nằm ngay dưới câu chào.

---

## 1. Tại sao phải có NPC chứ không gọi `OpenWindow()`

`OpenWindow("X")` của Lua chỉ đẩy sự kiện `OPEN_WINDOW` (`CysHostGlobals.cpp:167`). Khung nào **không
tự `RegisterEvent("OPEN_WINDOW")`** và so khớp `arg0 == "X"` thì không bao giờ mở.

- **45 / 2.043** tệp `.lua` của `InterfaceFolder` có đăng ký đó = **2,2 %**.
- Trong danh sách khung đích của bộ sửa: **0 khung** có đường đó.

Đúng hình dạng của lỗi bấm `Q`: khung nằm im vì chưa ai mở được nó.

## 2. Nửa client

`Src/Client/WXClient/DataPool/GMUIDataPool.cpp`, trong `CUIDataPool::SendSelectEvent` — **điểm nghẽn
duy nhất** mà mọi cú bấm menu NPC đi qua. Một mục có chuỗi chứa `@UIEDIT:<TênKhung>` **không được gửi
ra server**; client mở thẳng khung qua export `CysUiEditOpen` của `UI_CEGUI.dll`, gọi bằng
`GetProcAddress` (`Game.exe` **cố ý không** liên kết với `UI_CEGUI.dll` — `wxclient.cmake:9`).

Không có dấu hiệu thì hàm **không đổi một byte nào**: đúng một `strstr` rồi đi tiếp.

**Hệ quả thiết kế: server KHÔNG có một dòng logic nào, nó chỉ cung cấp NHÃN.** Vì client nuốt mục
trước khi gửi nên không cần `OnEventRequest`, không cần `script_id` riêng, và không có đường nào để
một cú bấm sai làm hỏng dữ liệu nhân vật.

## 3. Gắn vào NPC nào — và vì sao KHÔNG phải chỗ đã định ban đầu

Quyết định ban đầu là *"một `greeter` đứng sẵn ở Đại Lý"*. **Đo lại thì nó không tồn tại.**

`Build\Logs\2026-09-19-npc-data\50-npc-84-master.json` (84 NPC × 19 cột):

- **NPC CY4 duy nhất ở Đại Lý là `56007` 杨渐** — và vai trò của nó đúng là
  *"dịch chuyển Đại Lý → bản đồ phái (**CỬA DUY NHẤT**)"*, tức **chính con bị cấm đụng**:
  hỏng nó là mất bốn bản đồ môn phái.
- Cả **30 `greeter`** đều nằm trong bốn bản đồ phái (2220–2223), chỉ tới được **qua** 杨渐.

Nên tôi giữ **tinh thần** của quyết định (*đứng sẵn ở Đại Lý · dễ tìm · không mang chức năng quan
trọng*) và tìm vật chủ ngoài bộ CY4. Đại Lý có **204 chỗ đặt NPC gốc**, 190 con có script.

**Vật chủ đã chọn: script `714057` = `scripts.obj.dali.odali_zhongzhipai1` (NPC trồng trọt), 36 con
đứng khắp Đại Lý.** Ba lý do, cả ba đo được:

1. **36 con** rải khắp Đại Lý ⇒ dễ tìm hơn hẳn một con.
2. **Hiện không làm gì cả trên server này.** Nhánh `icon-audit` chứng minh **không nhân vật nào có
   một kỹ năng đời sống nào** (`human:fix_abilitys` cấp đúng 26 và 51, mà `LifeSkill.lua:202-203`
   loại bỏ cả hai; `SetHumanAbilityLevel` **0 lời gọi**). NPC này mở đầu bằng
   `QueryHumanAbilityLevel(...) == 0` ⇒ **mọi người chơi đều rơi vào đúng nhánh đó** và chỉ nhận một
   câu *"Ngươi hãy đi học kỹ năng trồng trọt trước đi"*. Hỏng nó thì mất một thứ vốn đã không chạy.
3. **Không đụng `cy4_npc.lua`** ⇒ **84 NPC CY4 không bị ảnh hưởng**, kể cả cửa duy nhất vào 4 bản đồ.

Menu được chèn **giữa `AddText` và `EndEvent`** của đúng nhánh đó — tức chỗ mọi người chơi nhìn thấy.

## 4. Cổng GM: KHÔNG có — và đây là quyết định CÓ ĐIỀU KIỆN

Server này là **server riêng của MỘT người**, không có người chơi khác. Thêm một cổng quyền là thêm
một thứ có thể hỏng mà không đổi lại được gì.

> **NẾU SAU NÀY CÓ NGƯỜI CHƠI KHÁC** thì phải thêm cổng, hoặc đặt `M.enabled = false` trong
> `uiedit_menu.lua`. Ghi ở đây để quyết định này không bị đọc như một luật vĩnh viễn.

## 5. Cài / gỡ

Đã cài rồi. Chạy lại là vô hại (script tự phát hiện đã cài).

```powershell
wsl.exe -d TLBB -- bash /mnt/c/TLBB/085/CY-Source/Tools/reapply/ui-editor/server/install.sh
wsl.exe -d TLBB -- bash /mnt/c/TLBB/085/CY-Source/Tools/reapply/ui-editor/server/install.sh --go-ra
```

**Không cần restart server** — `Game_2/Script/**` nạp lười qua `try_load`.

Script cài tự bảo vệ: `luac -p` **trước khi ghi đè** (bản vá sai cú pháp thì **không** ghi), sao lưu
kèm `sha256`, và đòi chèn **đúng một** dòng.

| | |
|---|---|
| module | `Game_2/Script/scripts/obj/uiedit_menu.lua` — `sha256 07f31b83…` |
| NPC chủ | `…/obj/dali/odali_zhongzhipai1.lua` — trước `309d0277…`, sau `f2519e55…`, chèn 1 dòng ở dòng 14 |
| sao lưu | `/home/ubuntu/cys-test-20260913/backups/uiedit-20260920/odali_zhongzhipai1.lua.bak` |

Tắt menu mà không gỡ gì: sửa `M.enabled = false` trong `uiedit_menu.lua` trên server.

## 6. Đã kiểm được gì

- **Cú pháp**: `luac -p` đạt cho cả module lẫn NPC chủ **sau khi vá**.
- **Module chạy thật** trên `lua` của server với một NPC giả: phát **11 mục**, mỗi mục mang
  `@UIEDIT:<TênKhung>`, chỉ số 7002–7012 không trùng. Cộng dòng `AddText` của NPC là **12** mục —
  dưới trần `MAX_EVENT_LIST_ITEM_COUNT = 16` (`Src/Shared/Common/ScriptCommandStruct.h:114`).
- **Chỗ chèn**: dòng 14, nằm giữa `AddText` và `EndEvent` của nhánh `AbilityLevel == 0`.

**CHƯA kiểm live trong game** (khe `Game.exe` bị các nhánh khác giữ liên tục). Việc còn lại: vào Đại
Lý, nói chuyện với một NPC trồng trọt, bấm một mục, xem khung có mở không — và đối chiếu
`Bin64\WXClient.log` tìm dòng `CYS-UIEDIT npc: mo khung "..." rc=1`.

**Lưu ý**: móc `@UIEDIT:` nằm trong `Game.exe`. Stage nào dựng **trước** commit `cfde805c` thì
menu sẽ hiện nhưng bấm vào sẽ **gửi ra server** thay vì mở khung (server không có script đó nên
không có gì xảy ra). Dùng stage dựng sau bản vá.

## 7. Danh sách 11 khung

Lấy từ `Tools/reapply/ui-editor/data/ui_edit_targets.tsv`. Chín widget đầu gánh **toàn bộ** lớp DBC
(~10.000 giá trị tràn; ba dòng đầu là **8.939 = 89,4 %**), hai mục cuối là nhóm *"chỉ nới ô mới sửa
được"*. Danh sách đầy đủ **56 khung** vẫn phải dùng `PgDn`/`PgUp` trong game.
