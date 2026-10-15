local gbk = require "wire_charset"
--local crypt = require "skynet.crypt"
local define = require "define"
local iostream = require "iostream"
local bistream = iostream.bistream
local bostream = iostream.bostream

local packet = {}

-- 1. 加载 XYID 常量
local ids = require "game.packet_ids"
for k, v in pairs(ids) do packet[k] = v end

-- 2. 加载公共类型（types 先于 domains，保证跨域引用安全）
require("game.packet_types.guid").bind(packet, bistream, bostream, gbk, define)
require("game.packet_types.item_types").bind(packet, bistream, bostream, gbk, define)
require("game.packet_types.equip_types").bind(packet, bistream, bostream, gbk, define)
require("game.packet_types.team_types").bind(packet, bistream, bostream, gbk, define)
require("game.packet_types.pet_detail_types").bind(packet, bistream, bostream, gbk, define)
require("game.packet_types.cgw_types").bind(packet, bistream, bostream, gbk, define)
require("game.packet_types.playershop_types").bind(packet, bistream, bostream, gbk, define)
require("game.packet_types.wgc_types").bind(packet, bistream, bostream, gbk, define)

-- 3. 加载全部域模块（全量绑定，保证 pairs(packet) 结果完整）
require("game.packet_domains.core").bind(packet, bistream, bostream, gbk, define)
require("game.packet_domains.movement").bind(packet, bistream, bostream, gbk, define)
require("game.packet_domains.combat").bind(packet, bistream, bostream, gbk, define)
require("game.packet_domains.item").bind(packet, bistream, bostream, gbk, define)
require("game.packet_domains.shop").bind(packet, bistream, bostream, gbk, define)
require("game.packet_domains.team").bind(packet, bistream, bostream, gbk, define)
require("game.packet_domains.mission").bind(packet, bistream, bostream, gbk, define)
require("game.packet_domains.social").bind(packet, bistream, bostream, gbk, define)
require("game.packet_domains.pet").bind(packet, bistream, bostream, gbk, define)
require("game.packet_domains.city").bind(packet, bistream, bostream, gbk, define)
require("game.packet_domains.misc").bind(packet, bistream, bostream, gbk, define)

-- skill-logic-5 (17/09/2026): lớp gói CY thêm — GCCharDoAction `xy_id = 786` (hoạt ảnh con rối
-- 离人偶 của 桃花岛, `lualib/cy_four_combat/action_packet.lua`). Trước lượt này `game.packet`
-- không có lớp nào mang 786 (785 = GCStallItemPrice, 787 = CGPetExteriorCollectionRequest)
-- ⇒ `net:send2client` nổ ở `self.packets[786] = nil` trong dịch vụ agent.
require("game.packet_domains.cy_combat").bind(packet, bistream, bostream, gbk, define)

require("game.packet_domains.cys_mount_flight").bind(packet,bistream,bostream)
return packet
