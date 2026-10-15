local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
-- local packet_def = require "game.packet"
local script_base = require "script_base"
local RemotecontrolPaiPai = class("RemotecontrolPaiPai", script_base)
RemotecontrolPaiPai.script_id = 999973

RemotecontrolPaiPai.world_id1 = ScriptGlobal.WORLD_ID_PAIPAI_1
RemotecontrolPaiPai.world_id2 = ScriptGlobal.WORLD_ID_PAIPAI_2
RemotecontrolPaiPai.world_id3 = ScriptGlobal.WORLD_ID_PAIPAI_3
RemotecontrolPaiPai.open_id = ScriptGlobal.WORLD_ID_PAIPAI_4
RemotecontrolPaiPai.open_id_two = ScriptGlobal.WORLD_ID_PAIPAI_5

function RemotecontrolPaiPai:OnDefaultEvent( selfId,targetId )
	local GmFlag = self:CallScriptFunction(700489,"HavePermission",selfId)
	if GmFlag then
		local msg = ""
		local nTab,nF1 = self:Cameraobscura();
		if nF1 == 0 then
			msg = "Đang là tỷ lệ rút mặc định, bên dưới chỉnh tự do";
		else
			msg = string.format("Vật phẩm 1 xác suất khoảng:%d%%\\nVật phẩm 2 xác suất khoảng:%d%%\\nVật phẩm 3 xác suất khoảng:%d%%\\nVật phẩm 4 xác suất khoảng:%d%%\\nVật phẩm 5 xác suất khoảng:%d%%\\nVật phẩm 6 xác suất khoảng:%d%%\\nVật phẩm 7 xác suất khoảng:%d%%\\nVật phẩm 8 xác suất khoảng:%d%%",
						 math.floor(nTab[1]/nF1*100),
						 math.floor(nTab[2]/nF1*100),
						 math.floor(nTab[3]/nF1*100),
						 math.floor(nTab[4]/nF1*100),
						 math.floor(nTab[5]/nF1*100),
						 math.floor(nTab[6]/nF1*100),
						 math.floor(nTab[7]/nF1*100),
						 math.floor(nTab[8]/nF1*100)
			)
		end
		local curmsg = "#G(hiện: tắt)"
		local curflag = self:LuaFnGetWorldGlobalDataEx(self.open_id_two)
		if curflag ~= 0 then
			curmsg = "#G(hiện: bật)"
		end
		self:BeginEvent()
			self:AddText(msg)
			self:AddNumText( "Đặt xác suất vật phẩm một", 6, 1 )
			self:AddNumText( "Đặt xác suất vật phẩm hai", 6, 2 )
			self:AddNumText( "Đặt xác suất vật phẩm ba", 6, 3 ) 
			self:AddNumText( "Đặt xác suất vật phẩm bốn", 6, 4 )
			self:AddNumText( "Đặt xác suất vật phẩm năm", 6, 5 )
			self:AddNumText( "Đặt xác suất vật phẩm sáu", 6, 6 )
			self:AddNumText( "Đặt xác suất vật phẩm bảy", 6, 7 )
			self:AddNumText( "Đặt xác suất vật phẩm tám", 6, 8 )
			self:AddNumText( "Khôi phục mặc định", 6, 9 )
			self:AddNumText( "Mở Phách Phách", 6, 900 )
			self:AddNumText( "Bật tắt rút thưởng người chơi khác"..curmsg, 6, 999 )
		self:EndEvent(sceneId)
		self:DispatchEventList(selfId,targetId)
	else
		local PlayerName=self:GetName(selfId)	
		local PlayerSex=self:GetSex(selfId)
		if PlayerSex == 0 then
			PlayerSex = "Cô nương"
		else
			PlayerSex = "Thiếu hiệp"
		end
		local msg = "    "..PlayerName..PlayerSex.."Bạn tới tham gia đại rút thưởng Phách Phách à."
		self:BeginEvent(sceneId)
			self:AddText(msg)
			self:AddNumText( "Đúng vậy.", 6, 900 )
			self:AddNumText( "nonono~ ta chỉ tới xem thôi.", 6, 1000 )
		self:EndEvent(sceneId)
		self:DispatchEventList(selfId,targetId)
	end
end
function RemotecontrolPaiPai:OnEventRequest(selfId, targetId, arg, index)
	if index == 1000 then
		self:BeginUICommand( sceneId )
		self:DispatchUICommand(selfId,index)
		return
	elseif index == 900 then
		self:CallScriptFunction(999972,"LuckyDraw",selfId,4)
		return
	end
	local GmFlag = self:CallScriptFunction(700489,"HavePermission",selfId)
	if not GmFlag then
		return
	end
	if index >= 1 and index <= 8 then
		local nF1 = index * 10 + 1;
		local nF2 = nF1 + 1;
		local nF3 = nF2 + 1;
		local nF4 = nF3 + 1;
		local msg = ""
		local nTab,nFs = self:Cameraobscura();
		if nTab[index] == 0 then
			msg = string.format("Vật phẩm %d hiện không thể trúng",index);
		else
			msg = string.format("Xác suất trúng vật phẩm %d khoảng: %d%%",index,math.floor(nTab[index]/nFs*100))
		end
		self:BeginEvent(sceneId)
			self:AddText(msg)
			self:AddNumText( "Tăng xác suất", 6, nF1 )
			self:AddNumText( "Giảm xác suất", 6, nF2 )
			self:AddNumText( "Không ra", 6, nF3 ) 
			self:AddNumText( "Về trang chính", 6, nF4 )
		self:EndEvent(sceneId)
		self:DispatchEventList(selfId,targetId)
	elseif index == 9 then
		local _,nFs = self:Cameraobscura();
		if nFs == 0 then
			self:notify_tips(selfId, "Đang là xác suất mặc định, khỏi khôi phục")
			return
		end
		self:LuaFnSetWorldGlobalDataEx(self.world_id1,0);
		self:LuaFnSetWorldGlobalDataEx(self.world_id2,0);
		self:LuaFnSetWorldGlobalDataEx(self.world_id3,0);
		self:OnDefaultEvent( selfId,targetId );
	elseif index >= 11 and index <= 84 then
		local nF1 = math.floor(index/10);
		local nF2 = (index % 10);
		if nF2 == 1 then
			local nTab,nFs = self:Cameraobscura();
			if nTab[nF1] == 100 then
				self:notify_tips(selfId, "Tăng đã tối đa, có thể về trang chính giảm xác suất món khác để tăng món này")
				return
			else
				nTab[nF1] = nTab[nF1] + 1;
			end
			if nTab[nF1] > 100 then
				nTab[nF1] = 100;
			end
			if nF1 >= 1 and nF1 <= 3 then
				local nF3 = nTab[1] * 10^6 + nTab[2] * 1000 + nTab[3];
				self:LuaFnSetWorldGlobalDataEx(self.world_id1,nF3);
			elseif nF1 >= 4 and nF1 <= 6 then
				local nF3 = nTab[4] * 10^6 + nTab[5] * 1000 + nTab[6];
				self:LuaFnSetWorldGlobalDataEx(self.world_id2,nF3);
			else
				local nF3 = nTab[7] * 1000 + nTab[8];
				self:LuaFnSetWorldGlobalDataEx(self.world_id3,nF3);
			end
			nFs = 0;
			for _,j in ipairs(nTab) do
				nFs = nFs + j;
			end
			if nTab[nF1] == 0 then
				msg = string.format("Vật phẩm %d hiện không thể trúng",nF1);
			else
				msg = string.format("Xác suất trúng vật phẩm %d khoảng: %d%%",nF1,math.floor(nTab[nF1]/nFs*100))
			end
			self:BeginEvent(sceneId)
				self:AddText(msg)
				self:AddNumText( "Tăng xác suất", 6, index )
				self:AddNumText( "Giảm xác suất", 6, index+1 )
				self:AddNumText( "Không ra", 6, index+2 ) 
				self:AddNumText( "Về trang chính", 6, index+3 )
			self:EndEvent(sceneId)
			self:DispatchEventList(selfId,targetId)
		elseif nF2 == 2 then
			local nTab,nFs = self:Cameraobscura();
			if nTab[nF1] == 0 then
				self:notify_tips(selfId, "Vật phẩm hiện không thể xuất hiện nữa, khỏi giảm thêm")
				return
			else
				nTab[nF1] = nTab[nF1] - 1;
			end
			if nTab[nF1] < 0 then
				nTab[nF1] = 0
			end
			if nF1 >= 1 and nF1 <= 3 then
				local nF3 = nTab[1] * 10^6 + nTab[2] * 1000 + nTab[3];
				self:LuaFnSetWorldGlobalDataEx(self.world_id1,nF3);
			elseif nF1 >= 4 and nF1 <= 6 then
				local nF3 = nTab[4] * 10^6 + nTab[5] * 1000 + nTab[6];
				self:LuaFnSetWorldGlobalDataEx(self.world_id2,nF3);
			else
				local nF3 = nTab[7] * 1000 + nTab[8];
				self:LuaFnSetWorldGlobalDataEx(self.world_id3,nF3);
			end
			nFs = 0;
			for _,j in ipairs(nTab) do
				nFs = nFs + j;
			end
			if nTab[nF1] == 0 then
				msg = string.format("Vật phẩm %d hiện không thể trúng",nF1);
			else
				msg = string.format("Xác suất trúng vật phẩm %d khoảng: %d%%",nF1,math.floor(nTab[nF1]/nFs*100))
			end
			self:BeginEvent(sceneId)
				self:AddText(msg)
				self:AddNumText( "Tăng xác suất", 6, index-1 )
				self:AddNumText( "Giảm xác suất", 6, index )
				self:AddNumText( "Không ra", 6, index+1 ) 
				self:AddNumText( "Về trang chính", 6, index+2 )
			self:EndEvent(sceneId)
			self:DispatchEventList(selfId,targetId)
		elseif nF2 == 3 then
			local nTab,nFs = self:Cameraobscura();
			if nTab[nF1] == 0 then return end
			nTab[nF1] = 0;
			if nF1 >= 1 and nF1 <= 3 then
				local nF3 = nTab[1] * 10^6 + nTab[2] * 1000 + nTab[3];
				self:LuaFnSetWorldGlobalDataEx(self.world_id1,nF3);
			elseif nF1 >= 4 and nF1 <= 6 then
				local nF3 = nTab[4] * 10^6 + nTab[5] * 1000 + nTab[6];
				self:LuaFnSetWorldGlobalDataEx(self.world_id2,nF3);
			else
				local nF3 = nTab[7] * 1000 + nTab[8];
				self:LuaFnSetWorldGlobalDataEx(self.world_id3,nF3);
			end
			nFs = 0;
			for _,j in ipairs(nTab) do
				nFs = nFs + j;
			end
			if nTab[nF1] == 0 then
				msg = string.format("Vật phẩm %d hiện không thể trúng",nF1);
			else
				msg = string.format("Xác suất trúng vật phẩm %d khoảng: %d%%",nF1,math.floor(nTab[nF1]/nFs*100))
			end
			self:BeginEvent(sceneId)
				self:AddText(msg)
				self:AddNumText( "Tăng xác suất", 6, index-2 )
				self:AddNumText( "Giảm xác suất", 6, index-1 )
				self:AddNumText( "Không ra", 6, index ) 
				self:AddNumText( "Về trang chính", 6, index+1 )
			self:EndEvent(sceneId)
			self:DispatchEventList(selfId,targetId)
		elseif nF2 == 4 then
			self:OnDefaultEvent(  selfId,targetId );
		end
	elseif index == 999 then
		local curflag = self:LuaFnGetWorldGlobalDataEx(self.open_id_two)
		local msg = ""
		if curflag == 0 then
			curflag = 1
			msg = "Mở rút thưởng người chơi khác thành công"
		else
			curflag = 0
			msg = "Đóng rút thưởng người chơi khác thành công"
		end
		self:LuaFnSetWorldGlobalDataEx(self.open_id_two,curflag)
		self:notify_tips(selfId,msg)
	end
end
function RemotecontrolPaiPai:Cameraobscura()
	local nTab = {};
	local nF1 = self:LuaFnGetWorldGlobalDataEx(self.world_id1);
	nTab[1] = math.floor(nF1/10^6);
	nF1 = (nF1 % 10^6);
	nTab[2] = math.floor(nF1/1000);
	nTab[3] = (nF1 % 1000);
	nF1 = self:LuaFnGetWorldGlobalDataEx(self.world_id2);
	nTab[4] = math.floor(nF1/10^6);
	nF1 = (nF1 % 10^6);
	nTab[5] = math.floor(nF1/1000);
	nTab[6] = (nF1 % 1000);
	nF1 = self:LuaFnGetWorldGlobalDataEx(self.world_id3);
	nTab[7] = math.floor(nF1/1000);
	nTab[8] = (nF1 % 1000);
	nF1 = 0;
	for _,j in ipairs(nTab) do
		nF1 = nF1 + j;
	end
	return nTab,nF1;
end
return RemotecontrolPaiPai
