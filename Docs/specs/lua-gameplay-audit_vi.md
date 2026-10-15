# Kiểm tra Lua NPC và sự kiện — 21/09/2026

Đã quét toàn bộ 3.858 file Lua gameplay phía server và 2.043 file Lua giao diện phía client. Cả hai tập đều biên dịch cú pháp được. Điều đó không chứng minh mọi tính năng hoạt động: các lỗi chính tìm được nằm ở cầu nối sự kiện, API chưa triển khai và mã chuyển đổi sai hợp đồng.

## Phạm vi và kết quả đã sửa

- Server riêng `/home/ubuntu/cys-test-20260913`; các cây gốc và dữ liệu CanonicalCY chỉ đọc.
- Client: nhận GCUICommand1205, kiểm đầy đủ tham số, giữ bản sao riêng từng lệnh, nối ba getter số lượng tham số Lua.
- Đăng ký sự kiện có tên của Lua ngoài bảng enum0.85. Có703 tên tìm thấy cả producer và listener Lua; đây là phạm vi được mở đường, không phải703 chức năng đã kiểm thử từng cái.
- Dùng3.236 lệnh trong UICommandIndex của CY để chọn đúng khung trước khi nạp; không đánh thức1.429 file Lua nghe UI_COMMAND cùng lúc.
- Server: thêm SendOResultToPlayer ủy quyền tới hàm thật, cùng tostring/abs/format/getn/random của các Lua đã chuyển đổi.
- Sửa72 phép so sánh sai:53 IsHaveMission và19 IsMissionHaveDone trong23 file. API vẫn trả boolean.
- Sửa10 lựa chọn sư môn của Thiếu Lâm, Thiên Sơn, Võ Đang, Tiêu Dao, Tinh Túc ghi nhầm vào buffer của nhiệm vụ; lựa chọn giờ đi vào menu NPC với đúng ID script.
- Đăng ký5 ID khớp client_GL Script.dat và file hiện có:50200,50201,50202,50203,311000.

## Kiểm chứng và giới hạn

- Native kiểm tham số/định tuyến:33/33. LuaPlus thật của client:2.043/2.043 file; Lua5.4 server:3.858/3.858 file, trước và sau sửa.
- Fixture item3041 dùng module thật: trước sửa7 lỗi/8 kiểm; sau sửa8/8.
- Fixture dùng các hàm human/base thật và module NPC/sư môn thật: trước sửa27 lỗi/35 kiểm; sau sửa35/35. Đo menu khi chưa nhận/đang làm/đã hoàn thành, CheckSubmit khi chưa có nhiệm vụ, default menu5NPC và nhánh131/132 của Lingzhen. Các thao tác mạng/scene dùng fixture; không trao thưởng hoặc mua bán thật.
- Runtime B-final và B-npc:38/38 kiểm;3 lệnh xếp hàng giữ đúng chuỗi,1 sự kiện Lua nội bộ,2 lệnh thực sự đi TCP tới server rồi trở về mở cửa sổ sửa trang bị/tăng số lần sửa. Nhân vật di chuyển tiếp hơn7,9m; world20/20 và thoát sạch.
- B-npc chọn hai Nữ đệ tử Thiên Sơn bằng đường lệnh chuột hiện có; kích hoạt NPC20 và nhận menu sau2.188ms. Probe đi qua MouseCommand_Active nhưng không giả lập tia chuột/nhấp OS. Chưa kiểm từng NPC trên tất cả bản đồ.
- Không phát sinh CYS Lua failure trong các lượt đạt. Ảnh cho thấy các khung mở được; bố cục chữ trong khung tăng số lần sửa vẫn có chỗ chật, nên kết quả này không phải nghiệm thu hình thức của toàn bộ UI.
- Play21 khớp37 binary và81 overlay với stage đã đo. Giới hạn120/30FPS có trong preset; lượt này không phải benchmark FPS toàn game.

## Các phần chưa thể coi là đã hoạt động

Bảng scripts.lua sau sửa có3.594 ID. Có126 ID trỏ tới module không tồn tại, và không tìm thấy cùng file trong cây server gốc. Không tạo module rỗng hoặc trả thành công giả. Một số ID có thể thuộc sự kiện chưa mở; phải đối chiếu lịch mở và nguồn tương ứng trước khi khôi phục.

- GetMenpaiItem, GetMissionParamEx, SetMissionParamByIndexEx chưa có implementation nhưng mỗi tên xuất hiện trong10 file sư môn. Vì vậy chưa nghiệm thu toàn bộ chu trình nhận/làm/trả nhiệm vụ sư môn.
- DispatchAbilityInfo thiếu ở32 file. Chưa có đủ đối chiếu giao thức để bảo đảm các NPC học/nâng nghề hoạt động đầy đủ.
- GetOneMissionNpc đang lấy hàng dữ liệu bằng ID thay vì nhóm index;10 Lua KillMonster_Accept còn làm mất8 giá trị trả về. Nguồn tlbb15 cho thấy phải nhận đủ9 giá trị. Chưa đổi phần này trong bản vá vì còn liên quan tham số nhiệm vụ và dữ liệu đích.
- Log theo giờ trước bản vá còn báo thiếu script808037/808120/890037. Có lỗi baseline tạo monster13565 rồi truyền ID không hợp lệ tới MonsterAI_SetIntParamByIndex. Không gộp hoặc che các lỗi này trong sửa cầu nối Lua.

Các danh sách bên dưới là kết quả quét tĩnh để điều tra tiếp, không đồng nghĩa mọi hàng đều được người chơi gọi. Không dùng số lần grep bằng0 làm bằng chứng tính năng đã chạy.

## Các module đăng ký nhưng thiếu file (126)

| ID | Module |
|---:|---|
| 10 | `scripts.obj.luoyang.oluoyang_fubi` |
| 11 | `scripts.obj.luoyang.oluoyang_hanqi` |
| 38 | `scripts.obj.luoyang.oluoyang_nvpu` |
| 43 | `scripts.obj.luoyang.oluoyang_minzhenghao` |
| 56 | `scripts.obj.luoyang.oluoyang_lisan` |
| 57 | `scripts.obj.luoyang.oluoyang_zhengfu` |
| 58 | `scripts.obj.luoyang.oluoyang_wuping` |
| 62 | `scripts.obj.luoyang.oluoyang_zhoulaoshi` |
| 63 | `scripts.obj.luoyang.oluoyang_zhoulaotai` |
| 69 | `scripts.obj.luoyang.oluoyang_zhizhong` |
| 70 | `scripts.obj.luoyang.oluoyang_zhixian` |
| 71 | `scripts.obj.luoyang.oluoyang_zhizhang` |
| 79 | `scripts.obj.luoyang.oluoyang_jiugui` |
| 86 | `scripts.obj.luoyang.oluoyang_gezi` |
| 130 | `scripts.obj.luoyang.oluoyang_zhuyuanping` |
| 2026 | `scripts.obj.dali.odali_cuifengjiu` |
| 2072 | `scripts.obj.dali.odali_chengxiong` |
| 2074 | `scripts.obj.dali.odali_BossMonster` |
| 2087 | `scripts.obj.dali.odali_huangnafu` |
| 4101 | `scripts.obj.taihu.otaihu_shop` |
| 4111 | `scripts.obj.taihu.otaihu_sign` |
| 7101 | `scripts.obj.jiange.ojiange_shop` |
| 7111 | `scripts.obj.jiange.ojiange_sign` |
| 8101 | `scripts.obj.dunhuang.odunhuang_shop` |
| 8111 | `scripts.obj.dunhuang.odunhuang_sign` |
| 15040 | `scripts.obj.mantuo.mantuo_wangsushang` |
| 18101 | `scripts.obj.yannan.oyannan_shop` |
| 18111 | `scripts.obj.yannan.oyannan_sign` |
| 19101 | `scripts.obj.yanbei.oyanbei_shop` |
| 19111 | `scripts.obj.yanbei.oyanbei_sign` |
| 20101 | `scripts.obj.caoyuan.ocaoyuan_shop` |
| 20111 | `scripts.obj.caoyuan.ocaoyuan_sign` |
| 35101 | `scripts.obj.qiongzhou.oqiongzhou_shop` |
| 35111 | `scripts.obj.qiongzhou.oqiongzhou_sign` |
| 300078 | `scripts.obj.item.MianBu_JingTie_Assistor` |
| 310000 | `scripts.obj.commonitem.310000` |
| 334701 | `scripts.obj.commonitem.item_4701` |
| 334702 | `scripts.obj.commonitem.item_4702` |
| 334703 | `scripts.obj.commonitem.item_4703` |
| 334704 | `scripts.obj.commonitem.item_4704` |
| 334705 | `scripts.obj.commonitem.item_4705` |
| 334706 | `scripts.obj.commonitem.item_4706` |
| 334801 | `scripts.obj.commonitem.item_4801` |
| 334802 | `scripts.obj.commonitem.item_4802` |
| 334803 | `scripts.obj.commonitem.item_4803` |
| 334804 | `scripts.obj.commonitem.item_4804` |
| 334805 | `scripts.obj.commonitem.item_4805` |
| 334806 | `scripts.obj.commonitem.item_4806` |
| 334807 | `scripts.obj.commonitem.item_4807` |
| 334808 | `scripts.obj.commonitem.item_4808` |
| 334809 | `scripts.obj.commonitem.item_4809` |
| 334810 | `scripts.obj.commonitem.item_4810` |
| 334811 | `scripts.obj.commonitem.item_4811` |
| 334812 | `scripts.obj.commonitem.item_4812` |
| 334813 | `scripts.obj.commonitem.item_4813` |
| 334814 | `scripts.obj.commonitem.item_4814` |
| 334815 | `scripts.obj.commonitem.item_4815` |
| 334816 | `scripts.obj.commonitem.item_4816` |
| 334817 | `scripts.obj.commonitem.item_4817` |
| 334818 | `scripts.obj.commonitem.item_4818` |
| 334910 | `scripts.obj.commonitem.item_4910` |
| 334911 | `scripts.obj.commonitem.item_4911` |
| 334912 | `scripts.obj.commonitem.item_4912` |
| 334913 | `scripts.obj.commonitem.item_4913` |
| 334914 | `scripts.obj.commonitem.item_4914` |
| 334919 | `scripts.obj.commonitem.item_4919` |
| 334940 | `scripts.obj.commonitem.item_4940` |
| 334949 | `scripts.obj.commonitem.item_4949` |
| 334950 | `scripts.obj.commonitem.item_4950` |
| 334951 | `scripts.obj.commonitem.item_4951` |
| 334952 | `scripts.obj.commonitem.item_4952` |
| 334953 | `scripts.obj.commonitem.item_4953` |
| 334954 | `scripts.obj.commonitem.item_4954` |
| 334955 | `scripts.obj.commonitem.item_4955` |
| 334957 | `scripts.obj.commonitem.item_4957` |
| 334958 | `scripts.obj.commonitem.item_4958` |
| 334959 | `scripts.obj.commonitem.item_4959` |
| 334960 | `scripts.obj.commonitem.item_4960` |
| 334961 | `scripts.obj.commonitem.item_4961` |
| 334962 | `scripts.obj.commonitem.item_4962` |
| 334963 | `scripts.obj.commonitem.item_4963` |
| 334964 | `scripts.obj.commonitem.item_4964` |
| 334965 | `scripts.obj.commonitem.item_4965` |
| 334966 | `scripts.obj.commonitem.item_4966` |
| 334967 | `scripts.obj.commonitem.item_4967` |
| 334968 | `scripts.obj.commonitem.item_4968` |
| 334969 | `scripts.obj.commonitem.item_4969` |
| 334970 | `scripts.obj.commonitem.item_4970` |
| 334971 | `scripts.obj.commonitem.item_4971` |
| 334972 | `scripts.obj.commonitem.item_4972` |
| 334973 | `scripts.obj.commonitem.item_4973` |
| 334974 | `scripts.obj.commonitem.item_4974` |
| 334975 | `scripts.obj.commonitem.item_4975` |
| 334976 | `scripts.obj.commonitem.item_4976` |
| 334977 | `scripts.obj.commonitem.item_4977` |
| 334978 | `scripts.obj.commonitem.item_4978` |
| 334979 | `scripts.obj.commonitem.item_4979` |
| 334980 | `scripts.obj.commonitem.item_4980` |
| 334981 | `scripts.obj.commonitem.item_4981` |
| 334982 | `scripts.obj.commonitem.item_4982` |
| 334983 | `scripts.obj.commonitem.item_4983` |
| 334984 | `scripts.obj.commonitem.item_4984` |
| 334985 | `scripts.obj.commonitem.item_4985` |
| 334986 | `scripts.obj.commonitem.item_4986` |
| 334987 | `scripts.obj.commonitem.item_4987` |
| 334988 | `scripts.obj.commonitem.item_4988` |
| 334989 | `scripts.obj.commonitem.item_4989` |
| 334990 | `scripts.obj.commonitem.item_4990` |
| 334991 | `scripts.obj.commonitem.item_4991` |
| 334992 | `scripts.obj.commonitem.item_4992` |
| 334993 | `scripts.obj.commonitem.item_4993` |
| 334994 | `scripts.obj.commonitem.item_4994` |
| 334995 | `scripts.obj.commonitem.item_4995` |
| 334996 | `scripts.obj.commonitem.item_4996` |
| 334997 | `scripts.obj.commonitem.item_4997` |
| 334998 | `scripts.obj.commonitem.item_4998` |
| 334999 | `scripts.obj.commonitem.item_4999` |
| 500621 | `scripts.event.InductSeries.eMission_xuexizudui` |
| 500622 | `scripts.event.InductSeries.eMission_luoyangqisheng` |
| 760416 | `scripts.obj.shengsi.416` |
| 760710 | `scripts.obj.shengsi.710` |
| 801803 | `scripts.event.wangrimengjing.ShenBingFB_ChuanSongSystem` |
| 888814 | `scripts.event.newhuodong.gem_mingjing` |
| 892667 | `scripts.event.prize.MonthCard` |
| 899998 | `scripts.obj.commonitem.item_change_buff` |
| 899999 | `scripts.obj.commonitem.lucky_box_draw` |

## API chưa thấy trong lớp hoặc lớp cha — ứng viên quét tĩnh

Có thể có override hoặc đăng ký động; cần đọc đường gọi trước khi kết luận. Top50 theo số file:

| Tên API | Số file | Một vị trí để điều tra |
|---|---:|---|
| `DispatchAbilityInfo` | 32 | `scripts/event/liveabilityevent/elevelup_caibingshu.lua` |
| `GetMenpaiItem` | 10 | `scripts/event/shimen/event_shimen_dali.lua` |
| `GetMissionParamEx` | 10 | `scripts/event/shimen/event_shimen_dali.lua` |
| `SetMissionParamByIndexEx` | 10 | `scripts/event/shimen/event_shimen_dali.lua` |
| `GetItemTransfer` | 9 | `scripts/event/dali/edali_0242.lua` |
| `PrintStr` | 8 | `scripts/event/shimen/event_shimen_emei.lua` |
| `LuaFnGetDRideTargetID` | 7 | `scripts/event/team.lua` |
| `CityBuildingChange` | 6 | `scripts/city0_building0.lua` |
| `NotifyTips` | 6 | `scripts/obj/item/charged_38000082.lua` |
| `UpdateEventList` | 6 | `scripts/obj/DynamicNPC/oDynamicNPC_ThiefSoldier_Generate.lua` |
| `print` | 6 | `scripts/event/shimen/event_shimen_gaibang.lua` |
| `notfiy_tips` | 5 | `scripts/event/petcompound/petsavvyggd.lua` |
| `GetGuildLevel` | 4 | `scripts/city0_building4.lua` |
| `CityGetMaintainStatus` | 3 | `scripts/city0_building5.lua` |
| `LuaFnGetPetMaxLife` | 3 | `scripts/obj/commonitem/item_5002.lua` |
| `LuaFnPetCanReturnToChild` | 3 | `scripts/obj/commonitem/item_4834.lua` |
| `LuaFnPetReturnToChild` | 3 | `scripts/obj/commonitem/item_4834.lua` |
| `AwardGuildContriTitle` | 2 | `scripts/event/huodong/echangeusername.lua` |
| `CityIncProgress` | 2 | `scripts/city0_LevelUp.lua` |
| `DarkBoxItemDropRandom` | 2 | `scripts/obj/commonitem/item_332200.lua` |
| `DeleteTitle` | 2 | `scripts/event/caoyun/ecaoyun.lua` |
| `DispatchPlayerShopSaleOutList` | 2 | `scripts/obj/luoyang/oluoyang_qiaofusheng.lua` |
| `GetDarkBoxItemDropCount` | 2 | `scripts/obj/commonitem/item_332200.lua` |
| `GetFullExp` | 2 | `scripts/city0_building5.lua` |
| `GetTitle` | 2 | `scripts/event/caoyun/ecaoyun.lua` |
| `GetWeekTime` | 2 | `scripts/city0_building5.lua` |
| `IsGuildPosLongEnough` | 2 | `scripts/city0_building5.lua` |
| `LuaFnAuditDarkKeyUsed` | 2 | `scripts/obj/commonitem/item_332200.lua` |
| `LuaFnGetPetProcreateInfo` | 2 | `scripts/obj/luoyang/oluoyang_yunmiaomiao.lua` |
| `LuaFnIsCanWashPiont` | 2 | `scripts/obj/commonitem/item_30008004.lua` |
| `LuaFnTryRecieveItem` | 2 | `scripts/event/xunhuan/shuilao_12.lua` |
| `ResetAreaStandingTime` | 2 | `scripts/event/chuansong/echuansong_mantuofb_mantuoshanzhuang.lua` |
| `SetHonour` | 2 | `scripts/event/fuben/efuben_bangzhan.lua` |
| `TAddText` | 2 | `scripts/event/EventScript/event_enterarea.lua` |
| `WriteDebugLog` | 2 | `scripts/obj/commonitem/item_332104.lua` |
| `AddExpMore` | 1 | `scripts/event/InductSeries/eMission_lixiankuizeng.lua` |
| `AddOutlineGiftLog` | 1 | `scripts/event/InductSeries/eMission_lixiankuizeng.lua` |
| `AuditDrawGuildWelfare` | 1 | `scripts/city0_building5.lua` |
| `AuditExchangeMenpaiSuit` | 1 | `scripts/obj/loulangucheng/oloulan_jinjiuling.lua` |
| `AuditJoinJiaoShiJie` | 1 | `scripts/obj/luoyang/oluoyang_niezheng.lua` |
| `AuditQingRenJieShiZhuang` | 1 | `scripts/obj/luoyang/oluoyang_QiuBiTe.lua` |
| `AuditRelationPoint` | 1 | `scripts/event/EventScript/mod_event.lua` |
| `Audit_FindFriendAD_DelInfo` | 1 | `scripts/event/mail.lua` |
| `AwardTitle` | 1 | `scripts/obj/commonitem/item_4918.lua` |
| `BuyItem_OK` | 1 | `scripts/event/equip/diaowen.lua` |
| `CanCitySetAttr` | 1 | `scripts/city0_building5.lua` |
| `CanErasePlayerShop` | 1 | `scripts/obj/luoyang/oluoyang_qiaofusheng.lua` |
| `CityDelete` | 1 | `scripts/obj/luoyang/oluoyang_suzhe.lua` |
| `CitySetAttr` | 1 | `scripts/city0_building5.lua` |
| `CitySetLevel` | 1 | `scripts/obj/city/pc_guilddirector.lua` |

## Dữ liệu để tái kiểm và khôi phục

- Bàn giao chi tiết: `Timeline/handoff/lua-event-npc-audit_vi.md`.
- Inventory đầy đủ, manifest, A/B, ảnh và log: `Build/Logs/2026-09-21-lua-audit/`.
- Công cụ: `Tools/server/audit_gameplay_lua.py`, `audit_script_registry.lua`, `check_lua_syntax.lua`.
- Áp dụng có backup và giới hạn root: `apply_gameplay_compat.py`, `patch_gameplay_predicates.py`. Patcher mặc định dry-run; chạy lại sau áp dụng đã xác nhận0 thay đổi.
- Backup helper: `/home/ubuntu/cys-test-20260913/backups/gameplay-compat-20260921T112158Z`.
- Backup24 file gameplay/registry: `/home/ubuntu/cys-test-20260913/backups/gameplay-predicates-20260921T115704Z`.
- Play21: `Build/world-gui/stage-play-21/Play.cmd`. Giữ Play20 để đối chiếu.
