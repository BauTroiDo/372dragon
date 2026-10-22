# i18n-cy — dịch nốt chữ Trung còn lại trong dữ liệu CY (17/09/2026)

Tài liệu chung của các agent dịch dữ liệu CY (`i18n-cy` 17/09, `i18n-2` 18/09 trở đi — cùng phạm vi, cùng file
`DISPLAY`/`TABLES`, nối tiếp nhau nên dùng chung một tài liệu). Phạm vi: `Assets/CanonicalCY/Data/ConfigFolder/StrDictionary.txt`
và các bảng DBC trong `ConfigFolder`. KHÔNG đụng `Src/`, `InterfaceFolder/**`, `SceneFolder`/`ModelFolder`/`MaterialFolder`.

Bằng chứng: `Build/Logs/2026-09-17-i18n-cy/` (mục 1, 3-6 — StrDictionary + hai bảng Tu luyện, agent `i18n-cy`) và
`Build/Logs/2026-09-18-i18n-2/` (mục 2 — 8 bảng DBC mới + khảo sát 64 bảng, agent `i18n-2`; báo cáo đầy đủ ở
`Timeline/handoff/i18n-2.md`).

---

## 1. Kết luận quan trọng nhất: 88 % "chữ Trung còn lại" trong StrDictionary KHÔNG được dịch

Đo trên `Assets/CanonicalCY/Data/ConfigFolder/StrDictionary.txt` (154.776 dòng, UTF-8, CRLF), trước khi làm gì:

| Nhóm | Số dòng | Bản chất | Xử lý |
|---|---:|---|---|
| A — cả giá trị còn tiếng Trung | 883 | thoại/mục tiêu nhiệm vụ dài (trung vị 454 ký tự, tổng 561.628 ký tự) | dịch được, chưa làm |
| B — chữ Trung **chỉ nằm trong `#{...}`** | 6.738 | tham số của `#{_INFOAIM x,y,scene,<tên NPC>}` và họ hàng | **GIỮ NGUYÊN** |
| C — chữ Trung nằm ngoài `#{...}` mà dòng vẫn tính là "đã dịch" | 57 | nhãn/thông báo ngắn: PK, quan hệ bằng hữu, tiền/kinh nghiệm | **ĐÃ DỊCH 17/09** |

Tổng 7.678 dòng có ký tự Hán = 4,96 %.

**Vì sao nhóm B phải giữ nguyên.** Bản Việt hoá 085 đang chạy thật (`Assets/Canonical/Data/ConfigFolder/StrDictionary.txt`,
client_GL) cũng để nguyên chữ Trung y hệt trong `#{}`: 393 dòng, ví dụ

```
MIS_TAR_ADD_093  Tại #GQuỳnh Châu Di Châu mã đầu#W tìm #RLăng Ức Từ#{_INFOAIM246,151,35,凌忆慈}#W, xin nàng ...
```

Chữ hiển thị là "Lăng Ức Từ" (nằm ngoài dấu ngoặc); `凌忆慈` bên trong là **đối số** của mốc tự tìm đường, không vẽ ra
màn hình. Đếm theo ký tự Hán mà không bóc `#{...}` ra trước sẽ thổi phồng khối lượng việc lên gần 9 lần và dụ người
sau đi dịch đúng thứ không được phép dịch.

Bộ đếm đúng nằm trong `Tools/pipeline/cy_i18n_apply.py` (`han_report`), tách sẵn hai cột.

---

## 2. Bảng phân loại cột — tài sản chính

Nguồn: `Tests/abi/check_dbc_layout.py --columns` (tên thành viên struct) + mẫu ô thật
(`Build/Logs/2026-09-17-i18n-cy/dbc-string-columns.tsv`, sinh bởi `scripts/survey_dbc_strings.py`).

### 2.1 Quy mô thật

* `ConfigFolder` có **723 file**, nhưng Game.exe chỉ mở **64 bảng**: 59 qua `CDataBaseSystem::OpenAllDataBase`
  + 5 loader riêng — cộng 3 bảng nữa mà `CysPowerNet` tự mở (`XiuLianMiJi/Book/Detail`).
* 1.182 cột STRING có ký tự ngoài ASCII, tổng **5.978.987 ký tự Hán**; chỉ **3.952.203** nằm trong bảng mà client
  có tham chiếu. Phần còn lại là bảng dữ liệu server/không dùng — dịch chúng không đổi được gì trên màn hình.

### 2.2 Cột CHỮ HIỂN THỊ (dịch được)

Cột `Trạng thái` "XONG" ghi kèm ngày và agent. Từ 18/09 (agent `i18n-2`), **mọi dòng thêm mới ở bảng này đã được xác
minh bằng cách grep hàm C++ thật sự đọc field đó** (không chỉ suy từ tên cột) — xem mục 2.3 để biết vì sao bước này
bắt buộc.

| Bảng | Cột | Nội dung | Trạng thái |
|---|---:|---|---|
| `XiuLianMiJi.txt` | 2 tên, 4 mô tả | quyển bí kíp Tu luyện | **XONG 17/09** |
| `XiuLianBook.txt` | 1 tên, 3 mô tả | bộ bí điển Tu luyện | **XONG 17/09** |
| `EquipBase/WhiteEquipBase/GreenEquipBase/BlueEquipBase` | xem `DISPLAY` | tên/mô tả trang bị | item-text 15/09 |
| `CommonItem/GemInfo/StoreMapItem/EquipSetAttr/ItemCompound` | xem `DISPLAY` | tên/mô tả vật phẩm | item-text 15/09 |
| `SkillTemplate_V1` 2/79, `XinFa_V1` 2/3, `SkillData_V1` 1/2/4 | | tên + mô tả kỹ năng | skills-ui 15/09 |
| `SceneDefineEx` 1/22 | | tên cảnh | npc-quest 15/09 |
| `MonsterAttrExTable.txt` | 1 | tên quái/NPC (`段誉`, `萧峰`) — 28.848 ô GBK, 125.840 ký tự Hán | **KHÔNG ĐỤNG** — quyết định chốt 17/09: dịch tại wire (`wire_charset.fromutf8`), làm cả hai là dịch hai lần |
| `MonsterPaoPao.txt` | 1 `szPaoPaoTxt` | lời quái nói (bong bóng) — `pObj->Say(...)` trong `GMInterface_Script_Talk.cpp` | **XONG 18/09** (i18n-2) — 2.591→**1.517** ô còn Hán |
| `ImpactSEData_V1.txt` | 16 `m_pszInfo` | nhãn buff/hiệu ứng (`撕裂：持续掉血`) — `BuffImpact_GetToolTips(ByIndex)` | **XONG 18/09** (i18n-2) — 9.359→**651** ô còn Hán |
| `CharTitle.txt` | 2 `szTitle`, 3 `szTitleDesc` | tên + mô tả danh hiệu (bảng 430 dòng, khác `CharTitleNew.txt` đã có pipeline riêng) | **XONG 18/09** (i18n-2) — 859→**239** |
| `Ability.txt` | 1 `szName`, 13 `szExplain`, 15 `szProgressbarName` | tên/mô tả/nhãn thanh tiến trình sinh hoạt (nghề phụ: nấu ăn, khai khoáng...) | **XONG 18/09** (i18n-2) — 198→**12** |
| `ChatMood.txt` | 2/3/4 `szNobody/szMyself/szOther`, 11 `szToolTip` | câu thoại cảm xúc (`$N ngồi xuống`) + tooltip nút cảm xúc | **XONG 18/09** (i18n-2) — 1.232→**235** |
| `CharHairGeo.txt` | 6 `pShowName` | tên kiểu tóc (màn tạo nhân vật / tiệm cắt tóc) | **XONG 18/09** (i18n-2) — 608→**2** (Hán-Việt phủ 606/608) |
| `CharFaceGeo.txt` | 4 `pShowName` | tên kiểu mặt (bảng file `CharFaceGeo.txt`, struct `_DBC_CHAR_HEAD_GEO`) | **XONG 18/09** (i18n-2) — 444→**24** (Hán-Việt phủ 420/444) |
| `ScenePosDefine.txt` | 5 `szAimName` | tên điểm đến trong danh sách điểm truyền tống (`WorldManager.cpp` dựng `m_ScenePoslistObj`) | **XONG 18/09** (i18n-2) — 151→**0** |
| `MissionTrack.txt` | — | ~~dòng theo dõi nhiệm vụ~~ | **KHÔNG ĐỌC ĐƯỢC — xem mục 2.3**, đừng thêm lại |
| `PetAttrTable.txt` | — | ~~tên trân thú~~ | **CỘT CHẾT — xem mục 2.3**, đừng thêm lại |

### 2.3 Cột TƯỞNG ĐỌC ĐƯỢC NHƯNG THỰC RA KHÔNG AI ĐỌC (cột chết) — phát hiện 18/09

Bàn giao 17/09 xếp `MissionTrack.txt` c1 và `PetAttrTable.txt` c1/c43 vào mục 2.2 vì **tên cột đọc như chữ hiển
thị**. Khi agent `i18n-2` grep thẳng vào `Src` để tìm nơi field đó thực sự được đọc (thay vì tin tên cột), **cả hai
đều không có ai đọc**, và khi khảo sát rộng ra hết 64 bảng thì tìm thêm được một loạt cột khác cùng dạng. Đây không
phải khoá tài nguyên (dịch không làm crash) — chỉ đơn giản là **dịch xong không ai nhìn thấy gì thay đổi**, nên vẫn
phải liệt kê để người sau không phí công thêm lại.

| Bảng.cột | Trông như | Bằng chứng "không ai đọc" |
|---|---|---|
| `MissionTrack.txt` (cả bảng) | dòng theo dõi nhiệm vụ | không có `DBC_MISSION_TRACK` id nào trong `Src`; `DataPool:GetLuaMissionTrackInfo` (hàm Lua duy nhất có thể hiện dòng này) vẫn là `Stub()` chưa cài trong `LuaApiGen_DataPool.cpp` |
| `PetAttrTable.txt` c1 `m_Name`, c43 `unk_43` | tên trân thú | `DBC_PET_EX_ATT` chỉ có ĐÚNG MỘT chỗ đọc trong toàn bộ `Src` (`GMDataPool.cpp Pet_GetPetFoodType`), chỉ đụng `m_FoodType`; tên trân thú thật lấy từ `pPet->pName` (`GMGameInterface_Script_Pet.cpp:148`) trỏ về `MonsterAttrExTable` — đã loại khỏi phạm vi |
| `ImpactDirectly.txt` c23 `m_pszInfo` | sinh đôi với `ImpactSEData_V1` c16 (cùng comment "[23] 效果描述" trong `GameStruct_Skill.h`) | grep `m_pszInfo` toàn `Src` chỉ ra các chỗ đọc `_DBC_BUFF_IMPACT`, không có chỗ nào đọc field này của `_DBC_DIRECT_IMPACT`; nơi duy nhất đọc `pDirectlyImpact` (`Obj_Character_Logic.cpp:2610`) chỉ log `effect`/`locator` |
| `CharMount.txt` c1 `m_pszName` | tên thú cưỡi | grep `->m_pszName` toàn `Src` = rỗng; tên thú cưỡi hiện trong game là `EquipBase.szName` (vật phẩm thú cưỡi, DISPLAY từ 15/09) |
| `CodeConvert.txt` c1 `szName` | tên icon cảm xúc | nơi đọc duy nhất (`UIString.cpp`, dựng `m_mapCodeConvertTable`) chỉ dùng `nID`/`szCode` |
| `ReputationTable.txt` c1 `pszName`, c67 `pszDesc` | tên/mô tả phe phái | `Shared/Common/CampDataMgr.cpp` — lớp lẽ ra đọc bảng này — bị comment nguyên khối; chưa tìm được nơi khác đọc |
| `SpecialObjData.txt` c1 `m_lpszName`, c2 `m_lpszToolTips` | tên/tooltip vật thể đặc biệt | `Obj_Special.cpp`/`CysModernHandlers.cpp` chỉ đọc field hiệu ứng/âm thanh/đạn của struct; `m_lpszToolTips` không xuất hiện ở file `.cpp` nào ngoài khai báo struct |
| `CityBuilding.txt` c2 `szName`, `GrowPoint.txt` c1 `szName` | tên công trình/điểm hái thuốc | nơi đọc bảng (`Scene.cpp`) chỉ lấy vị trí/level, không đọc `szName`; không tìm thấy hàm nào đọc `GrowPoint::szName` |
| `ScenePosDefine.txt` c1 `szSceneName` | tên cảnh của điểm đến (cùng bảng với c5 `szAimName` — c5 THÌ có đọc, đã thêm) | `WorldManager.cpp` (2 chỗ) chỉ đọc `nSceneID/nXPos/nZPos/szAimName` khi dựng danh sách điểm truyền tống |
| `CharTitle.txt` c7 `szComment`, c9 `szCol9` | mô tả/ghi chú danh hiệu | chỉ `pTitle->szTitle` và `pTitle->szTitleDesc` được `PushString` tới Lua; không có `pTitle->szComment`/`szCol9` ở đâu |

Nghi ngờ nhưng CHƯA đủ bằng chứng để xếp hẳn vào bảng trên (để nguyên, chưa dịch):
`FullCompareFilter.txt` c2 `szFullTxt` — nạp vào một tập so khớp văn bản nội bộ (`m_fullCompareTable`), không thấy
chỗ nào lấy ra vẽ lên màn hình.

### 2.4 Cột KHOÁ TÀI NGUYÊN — DỊCH LÀ CRASH / HỎNG

| Bảng | Cột | Ví dụ ô | Vì sao |
|---|---:|---|---|
| `CharModelEx.txt` | 1, 2 | `男主角.obj`, `女主角_iv.obj` | tên file model; `resource_like()` chặn được nhờ đuôi `.obj` |
| `ActionSet\ActionSetKV.txt` | 1 | `站立`, `休闲`, `行走` | **tên track/khoá của ActionSet, tra theo TÊN.** KHÔNG có đuôi file ⇒ `resource_like()` **KHÔNG** chặn. Đây là cái bẫy nguy hiểm nhất còn lại. |
| `CharActionSet.txt` | 1-9 `pWeapon_Set[N]` | `空手站立01`, `站立` | cùng loại bẫy với `ActionSetKV` — tên track ActionSet theo vũ khí, tra theo tên |
| `ItemVisualLocator.txt` | các cột `pEffectName[N]`/`pTail[N]` (29-62 v.v.) | `wq_扇子3B_mo`, `武器情人节_内攻` | tên điểm gắn hiệu ứng vũ khí, tra theo tên, không đuôi file |
| `XiuLianMiJi.txt` | 3 | `Xiulian1_14` | tên ảnh icon |
| `XiuLianBook.txt` | 2 | `Xiulian1_1` | tên ảnh icon |
| `SkillData_V1.txt` | 9, và **24-52 bước 2** (`paraPair.szDesc[0..14]`) | `消耗MP`, `\|生效一次的附加效果1`, `相冲突的物品的物品表中的索引` | **chú thích tên cột** lặp lại trên từng dòng, không phải chữ của từng kỹ năng. Phạm vi thật rộng hơn "24-34" bàn giao 17/09 ghi — đủ 15 slot tới c52. |
| `SpecialObjData.txt` | 25,27,29,31,33,35,37 (`m_aParam.szDesc[0..6]`) | `效果1`, `效果3几率`, `脚本` | cùng loại bẫy với `SkillData_V1`: 4 giá trị lặp lại y hệt trên toàn bộ 1.908 dòng (đo được, không phải suy đoán) |
| `SystemColour.txt` | 1 `strDesc` | `名字_主角` | khớp khít với chú thích hằng số `NAME_PLAYER_MYSELF` trong chính struct `_DBC_SYSTEM_COLOR` — rất giống khoá cấu hình tra theo tên, cùng lớp rủi ro với `ActionSetKV`; **chưa chứng minh dứt khoát**, để nguyên cho an toàn |
| `BuildingDefine.txt` | 2-6 `szLevel[N]` | `自建城市/一级县衙.model` | đường dẫn model; `resource_like()` cũ thiếu đuôi `.model` trong danh sách — đã vá `RES_EXT` 18/09 (không đổi byte nào đã ghi trước đó, đã xác nhận 0 ô `.model` trong dữ liệu hiện có) |
| `ImpactSEData_V1.txt` | 3,4,6,7,8,9,15 | `g01_mj_无中生`, `身体受击点` | tên icon/hiệu ứng/âm thanh/điểm gắn — chỉ c16 `m_pszInfo` là chữ hiển thị thật |

### 2.5 Không có gì để dịch

`XiuLianDetail.txt`: 63 cột, **tất cả INT/FLOAT**, không có một ô STRING nào. Agent khác báo bảng này "còn tiếng
Trung" là nhầm — nó chỉ chứa số.

---

### 3.1 Hai bảng Tu luyện — hết ô vuông

`Src/Client/WXClient/Network/CysPowerNet.cpp` tự mở hai bảng này ngoài `OpenAllDataBase` và đưa thẳng ô GBK cho
CEGUI ("GBK exactly as the table stores it"), nên cửa sổ Tu luyện ra ô vuông. Theo quyết định sẵn có của dự án
(**sửa lớp dữ liệu, không sửa loader**) đã thêm hai bảng vào `DISPLAY` của `Tools/pipeline/cy_item_text.py` và
36 chuỗi Việt vào `Registry/i18n/cy_items_vi_override.tsv`.

Thuật ngữ lấy từ chính StrDictionary CY (`XL_XML_03`…`XL_XML_28`) và từ bộ nhớ dịch:
`基础力量` = Cường lực cơ sở, `基础灵气` = Nội lực cơ sở, `基础体力` = Thể lực cơ sở, `基础定力` = Trí lực cơ sở,
`基础身法` = Thân pháp cơ sở, `基础外功攻击` = Ngoại công căn bản, `基础内功攻击` = Nội công căn bản,
`基础外功防御` = Ngoại thủ căn bản, `基础内功防御` = Nội thủ căn bản, `基础命中` = Chính xác cơ bản,
`基础闪避` = Né tránh căn bản.

### 3.2 57 chuỗi StrDictionary nhóm C

Toàn bộ 57 chuỗi **đã có sẵn bản dịch trong bộ nhớ dịch** nhưng bị chặn:

* `cy_gui_dict.build()` bỏ qua TM cho mọi khoá `GMDP_` (`hit = None if (tm is None or key.startswith('GMDP_'))`);
* bảng `exclude` của TM chặn thêm các lý do `gmdp` / `g_custom` / `cmp` (không nằm trong `DROP_DICT`);
* sau đó nhánh `gl-same-zh` lấy giá trị của client_GL — mà client_GL cũng để nguyên tiếng Trung.

Vì `extra.by_key()` được xét **trước** `gl-same-zh`, cách mở khoá đúng và hẹp nhất là override **theo khoá**
(`#KEY`) trong `Registry/i18n/cy_vi_override.tsv`. Đã kiểm: không có script Lua nào so sánh các chuỗi này (mọi lần
`rg` khớp đều là dòng chú thích `--`).

Ba chỗ cố ý lệch TM, có lý do:

| zh | TM | Dùng | Lý do |
|---|---|---|---|
| `精力` | Thể lực | **Tinh lực** | `体力` cũng là "Thể lực" — để nguyên là hai chỉ số khác nhau cùng tên |
| `活力` | Sinh lực | **Hoạt lực** | "Hoạt lực" đang dùng 35 lần trong StrDictionary CY |
| `未知` | Vô danh | **Không rõ** | ngữ cảnh là quan hệ chưa xác định, không phải "không có tên" |

---

## 4. Số đo trước / sau

| Chỉ số | Trước | Sau |
|---|---:|---:|
| StrDictionary: dòng có chữ Trung **hiển thị** | 940 | **883** |
| StrDictionary: dòng có chữ Trung chỉ trong `#{}` (giữ nguyên) | 6.738 | 6.738 |
| StrDictionary: dòng bị đổi giá trị | — | **đúng 57**, cột khoá giống hệt từng byte |
| `XiuLianMiJi.txt`: ô hiển thị còn Hán / GBK | 30 / 30 | **0 / 0** |
| `XiuLianBook.txt`: ô hiển thị còn Hán / GBK | 6 / 6 | **0 / 0** |
| Ô khoá tài nguyên + ô số bị đổi | — | **0** (`verify()` ném lỗi ở ô đầu tiên sai) |

Cổng kiểm: `check_dbc_layout.py --strict` PASS 64 bảng; `cy_item_text.py selftest` OK; client log
`DBC: 59 table(s) checked against the CY 3.71 schema, 0 error(s)`.

### Bằng chứng trong game

* Trước: `Build/Logs/2026-09-17-i18n-cy/truoc-xiulian.png` — khung mô tả là `6戳⊠⊠д⊠⊠⊠戳⊠⊠…`.
* Sau: `gui-after-2/cys-live-163236109-world-1.png` và `…-cam-zoom-far.png` — "Ngũ Hành Bảo Điển, thánh điển võ học
  đời đời truyền lại trong tay người luyện võ…".
* Log client cùng lượt:
  `XiuLianMiJi.txt opened 5x15`, `XiuLianBook.txt opened 4x3` (hình dạng bảng không đổi, `CysPowerNet::Open` không
  loại bảng), `probe miji0: Name=#cfff263Lực Bạt Sơn Hề Quyển`, `probe book0: Name=#cfff263Ngũ Hành Bảo Điển`.
* `CYS Lua failure env=Xiulian_Env … :797: attempt to compare nil with number` **có từ trước** (host-power `live-1`
  lúc 21:56, trước khi sửa) — không phải do lớp này.

---

## 5. Lệnh

```powershell
$py = 'C:\Program Files\Python313\python.exe'; $env:PYTHONUTF8 = 1
cd C:\TLBB\085\CY-Source
& $py -B Tools\pipeline\cy_i18n_apply.py plan      # xem sẽ đổi gì, không ghi
& $py -B Tools\pipeline\cy_i18n_apply.py apply     # ghi GEN + Data, tự sao lưu .bak-i18n-cy-<stamp>, rồi verify
& $py -B Tools\pipeline\cy_i18n_apply.py verify    # đọc lại từ đĩa và đối chiếu với bản dựng lại
```

**Sau mỗi lần ai đó chạy `build_canonical_cy.py --apply`, không cần chạy lại gì cả** nếu nhánh đó đã có commit này:
builder gọi đúng `cy_gui_dict.build()` và `cy_item_text.generate()`, đọc đúng `Registry/i18n/*.tsv`, nên sinh ra
byte y hệt. `cy_i18n_apply.py` chỉ là đường tắt để khỏi dựng lại toàn bộ cây (và để áp lại nếu ai đó dựng từ nhánh
cũ hơn).

Đo lại nhanh:

```powershell
& $py -B Build\Logs\2026-09-17-i18n-cy\scripts\survey_dbc_strings.py   # bảng nào / cột nào còn chữ Trung
```

---

## 6. Bẫy

1. **Đếm ký tự Hán mà không bóc `#{...}`** ⇒ phóng đại 9 lần và dẫn tới dịch nhầm đối số `_INFOAIM`. Xem mục 1.
2. **`ActionSetKV.txt` cột 1** (`站立`, `休闲`, `行走`) là khoá tra theo tên, không có đuôi file nên
   `cy_item_text.resource_like()` **không** chặn. Nếu thêm bảng này vào `DISPLAY` thì animation hỏng.
3. **`SkillData_V1` cột 24–34** là chú thích tên cột lặp lại từng dòng, không phải chữ của kỹ năng.
4. `XiuLianDetail.txt` không có ô STRING nào.
5. `CysPowerNet::Open` loại bảng nếu số cột/dòng nhỏ hơn mong đợi (`5x15`, `4x3`). Ghi lại bảng bằng
   `cy_item_text.write()` giữ nguyên header nên an toàn, nhưng đừng bao giờ bỏ bớt dòng/cột.
6. Bản Việt **dài hơn** bản GBK: mô tả `XiuLianMiJi` từ ~140 byte lên ~300 byte, khung mô tả cửa sổ Tu luyện nay có
   thanh cuộn. Chữ tràn khung là việc của `ui-fit` (cách sửa đúng của dự án là **rút ngắn chuỗi**, không nới khung).
7. Sao lưu: hai file override có `.bak-i18n-cy-20260917-224243` ngay cạnh trong `Registry/i18n/`; bản gốc của ba
   bảng dữ liệu nằm ở `Build/Logs/2026-09-17-i18n-cy/backup/20260917-224414/…`. **Cố ý không để `.bak` trong
   `Assets/CanonicalCY/Data`**: thư mục đó được junction vào mọi stage, một file `StrDictionary.txt.bak` 27 MB sẽ
   đi theo tất cả.
8. `python` không đặt `PYTHONUTF8=1` sẽ chết khi in tiếng Việt/Trung ra console cp1252.
