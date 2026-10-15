local gbk = require "wire_charset"
local class = require "class"
local define = require "define"
local script_base = require "script_base"
local huantongdan_4 = class("huantongdan_4", script_base)
huantongdan_4.script_id = 300100
huantongdan_4.g_itemList = {}
huantongdan_4.g_itemList[30309150] = {
    ["rulerId"] = 2,
    ["minPetLevel"] = 1,
    ["maxPetLevel"] = 45,
    ["petIds"] = {}
}
huantongdan_4.g_itemList[30309150]["petIds"][5] = 7649
huantongdan_4.g_itemList[30309150]["petIds"][45] = 7659
huantongdan_4.g_itemList[30309163] = {
    ["rulerId"] = 2,
    ["minPetLevel"] = 1,
    ["maxPetLevel"] = 85,
    ["petIds"] = {}
}
huantongdan_4.g_itemList[30309163]["petIds"][5] = 7649
huantongdan_4.g_itemList[30309163]["petIds"][45] = 7659
huantongdan_4.g_itemList[30309163]["petIds"][55] = 7669
huantongdan_4.g_itemList[30309163]["petIds"][65] = 7679
huantongdan_4.g_itemList[30309163]["petIds"][75] = 7689
huantongdan_4.g_itemList[30309163]["petIds"][85] = 7699
huantongdan_4.g_itemList[30309151] = {
    ["rulerId"] = 2,
    ["minPetLevel"] = 1,
    ["maxPetLevel"] = 45,
    ["petIds"] = {}
}
huantongdan_4.g_itemList[30309151]["petIds"][5] = 7789
huantongdan_4.g_itemList[30309151]["petIds"][45] = 7799
huantongdan_4.g_itemList[30309164] = {
    ["rulerId"] = 2,
    ["minPetLevel"] = 1,
    ["maxPetLevel"] = 85,
    ["petIds"] = {}
}
huantongdan_4.g_itemList[30309164]["petIds"][5] = 7789
huantongdan_4.g_itemList[30309164]["petIds"][45] = 7799
huantongdan_4.g_itemList[30309164]["petIds"][55] = 7809
huantongdan_4.g_itemList[30309164]["petIds"][65] = 7819
huantongdan_4.g_itemList[30309164]["petIds"][75] = 7829
huantongdan_4.g_itemList[30309164]["petIds"][85] = 7839
huantongdan_4.g_itemList[30309152] = {
    ["rulerId"] = 2,
    ["minPetLevel"] = 1,
    ["maxPetLevel"] = 45,
    ["petIds"] = {}
}
huantongdan_4.g_itemList[30309152]["petIds"][5] = 7929
huantongdan_4.g_itemList[30309152]["petIds"][45] = 7939
huantongdan_4.g_itemList[30309165] = {
    ["rulerId"] = 2,
    ["minPetLevel"] = 1,
    ["maxPetLevel"] = 85,
    ["petIds"] = {}
}
huantongdan_4.g_itemList[30309165]["petIds"][5] = 7929
huantongdan_4.g_itemList[30309165]["petIds"][45] = 7939
huantongdan_4.g_itemList[30309165]["petIds"][55] = 7949
huantongdan_4.g_itemList[30309165]["petIds"][65] = 7959
huantongdan_4.g_itemList[30309165]["petIds"][75] = 7969
huantongdan_4.g_itemList[30309165]["petIds"][85] = 7979
huantongdan_4.g_itemList[30309153] = {
    ["rulerId"] = 2,
    ["minPetLevel"] = 1,
    ["maxPetLevel"] = 45,
    ["petIds"] = {}
}
huantongdan_4.g_itemList[30309153]["petIds"][5] = 7999
huantongdan_4.g_itemList[30309153]["petIds"][45] = 8009
huantongdan_4.g_itemList[30309166] = {
    ["rulerId"] = 2,
    ["minPetLevel"] = 1,
    ["maxPetLevel"] = 85,
    ["petIds"] = {}
}
huantongdan_4.g_itemList[30309166]["petIds"][5] = 7999
huantongdan_4.g_itemList[30309166]["petIds"][45] = 8009
huantongdan_4.g_itemList[30309166]["petIds"][55] = 8019
huantongdan_4.g_itemList[30309166]["petIds"][65] = 8029
huantongdan_4.g_itemList[30309166]["petIds"][75] = 8039
huantongdan_4.g_itemList[30309166]["petIds"][85] = 8049
huantongdan_4.g_itemList[30309154] = {
    ["rulerId"] = 2,
    ["minPetLevel"] = 1,
    ["maxPetLevel"] = 45,
    ["petIds"] = {}
}
huantongdan_4.g_itemList[30309154]["petIds"][5] = 8069
huantongdan_4.g_itemList[30309154]["petIds"][45] = 8079

huantongdan_4.g_itemList[30309167] = {
    ["rulerId"] = 2,
    ["minPetLevel"] = 1,
    ["maxPetLevel"] = 85,
    ["petIds"] = {}

}

huantongdan_4.g_itemList[30309167]["petIds"][5] = 8069

huantongdan_4.g_itemList[30309167]["petIds"][45] = 8079

huantongdan_4.g_itemList[30309167]["petIds"][55] = 8089

huantongdan_4.g_itemList[30309167]["petIds"][65] = 8099

huantongdan_4.g_itemList[30309167]["petIds"][75] = 8109

huantongdan_4.g_itemList[30309167]["petIds"][85] = 8119

huantongdan_4.g_itemList[30309155] = {
    ["rulerId"] = 2,
    ["minPetLevel"] = 1,
    ["maxPetLevel"] = 45,
    ["petIds"] = {}

}

huantongdan_4.g_itemList[30309155]["petIds"][5] = 7859

huantongdan_4.g_itemList[30309155]["petIds"][45] = 7869

huantongdan_4.g_itemList[30309168] = {
    ["rulerId"] = 2,
    ["minPetLevel"] = 1,
    ["maxPetLevel"] = 85,
    ["petIds"] = {}

}

huantongdan_4.g_itemList[30309168]["petIds"][5] = 7859

huantongdan_4.g_itemList[30309168]["petIds"][45] = 7869

huantongdan_4.g_itemList[30309168]["petIds"][55] = 7879

huantongdan_4.g_itemList[30309168]["petIds"][65] = 7889

huantongdan_4.g_itemList[30309168]["petIds"][75] = 7899

huantongdan_4.g_itemList[30309168]["petIds"][85] = 7909

huantongdan_4.g_itemList[30309156] = {
    ["rulerId"] = 2,
    ["minPetLevel"] = 1,
    ["maxPetLevel"] = 45,
    ["petIds"] = {}

}

huantongdan_4.g_itemList[30309156]["petIds"][5] = 7719

huantongdan_4.g_itemList[30309156]["petIds"][45] = 7729

huantongdan_4.g_itemList[30309169] = {
    ["rulerId"] = 2,
    ["minPetLevel"] = 1,
    ["maxPetLevel"] = 85,
    ["petIds"] = {}

}

huantongdan_4.g_itemList[30309169]["petIds"][5] = 7719

huantongdan_4.g_itemList[30309169]["petIds"][45] = 7729

huantongdan_4.g_itemList[30309169]["petIds"][55] = 7739

huantongdan_4.g_itemList[30309169]["petIds"][65] = 7749

huantongdan_4.g_itemList[30309169]["petIds"][75] = 7759

huantongdan_4.g_itemList[30309169]["petIds"][85] = 7769

huantongdan_4.g_itemList[30309157] = {
    ["rulerId"] = 2,
    ["minPetLevel"] = 1,
    ["maxPetLevel"] = 45,
    ["petIds"] = {}

}

huantongdan_4.g_itemList[30309157]["petIds"][5] = 7509

huantongdan_4.g_itemList[30309157]["petIds"][45] = 7519

huantongdan_4.g_itemList[30309170] = {
    ["rulerId"] = 2,
    ["minPetLevel"] = 1,
    ["maxPetLevel"] = 85,
    ["petIds"] = {}

}

huantongdan_4.g_itemList[30309170]["petIds"][5] = 7509

huantongdan_4.g_itemList[30309170]["petIds"][45] = 7519

huantongdan_4.g_itemList[30309170]["petIds"][55] = 7529

huantongdan_4.g_itemList[30309170]["petIds"][65] = 7539

huantongdan_4.g_itemList[30309170]["petIds"][75] = 7549

huantongdan_4.g_itemList[30309170]["petIds"][85] = 7559

huantongdan_4.g_itemList[30309158] = {
    ["rulerId"] = 2,
    ["minPetLevel"] = 1,
    ["maxPetLevel"] = 45,
    ["petIds"] = {}

}

huantongdan_4.g_itemList[30309158]["petIds"][5] = 7579

huantongdan_4.g_itemList[30309158]["petIds"][45] = 7589

huantongdan_4.g_itemList[30309171] = {
    ["rulerId"] = 2,
    ["minPetLevel"] = 1,
    ["maxPetLevel"] = 85,
    ["petIds"] = {}

}

huantongdan_4.g_itemList[30309171]["petIds"][5] = 7579

huantongdan_4.g_itemList[30309171]["petIds"][45] = 7589

huantongdan_4.g_itemList[30309171]["petIds"][55] = 7599

huantongdan_4.g_itemList[30309171]["petIds"][65] = 7609

huantongdan_4.g_itemList[30309171]["petIds"][75] = 7619

huantongdan_4.g_itemList[30309171]["petIds"][85] = 7629

huantongdan_4.g_itemList[30309159] = {
    ["rulerId"] = 2,
    ["minPetLevel"] = 1,
    ["maxPetLevel"] = 45,
    ["petIds"] = {}

}

huantongdan_4.g_itemList[30309159]["petIds"][5] = 8139

huantongdan_4.g_itemList[30309159]["petIds"][45] = 8149

huantongdan_4.g_itemList[30309172] = {
    ["rulerId"] = 2,
    ["minPetLevel"] = 1,
    ["maxPetLevel"] = 85,
    ["petIds"] = {}

}

huantongdan_4.g_itemList[30309172]["petIds"][5] = 8139

huantongdan_4.g_itemList[30309172]["petIds"][45] = 8149

huantongdan_4.g_itemList[30309172]["petIds"][55] = 8159

huantongdan_4.g_itemList[30309172]["petIds"][65] = 8169

huantongdan_4.g_itemList[30309172]["petIds"][75] = 8179

huantongdan_4.g_itemList[30309172]["petIds"][85] = 8189

huantongdan_4.g_itemList[30309160] = {
    ["rulerId"] = 2,
    ["minPetLevel"] = 1,
    ["maxPetLevel"] = 45,
    ["petIds"] = {}

}

huantongdan_4.g_itemList[30309160]["petIds"][5] = 8209

huantongdan_4.g_itemList[30309160]["petIds"][45] = 8219

huantongdan_4.g_itemList[30309173] = {
    ["rulerId"] = 2,
    ["minPetLevel"] = 1,
    ["maxPetLevel"] = 85,
    ["petIds"] = {}

}

huantongdan_4.g_itemList[30309173]["petIds"][5] = 8209

huantongdan_4.g_itemList[30309173]["petIds"][45] = 8219

huantongdan_4.g_itemList[30309173]["petIds"][55] = 8229

huantongdan_4.g_itemList[30309173]["petIds"][65] = 8239

huantongdan_4.g_itemList[30309173]["petIds"][75] = 8249

huantongdan_4.g_itemList[30309173]["petIds"][85] = 8259

huantongdan_4.g_itemList[30309161] = {
    ["rulerId"] = 2,
    ["minPetLevel"] = 1,
    ["maxPetLevel"] = 45,
    ["petIds"] = {}

}

huantongdan_4.g_itemList[30309161]["petIds"][5] = 8279

huantongdan_4.g_itemList[30309161]["petIds"][45] = 8289

huantongdan_4.g_itemList[30309174] = {
    ["rulerId"] = 2,
    ["minPetLevel"] = 1,
    ["maxPetLevel"] = 85,
    ["petIds"] = {}

}

huantongdan_4.g_itemList[30309174]["petIds"][5] = 8279

huantongdan_4.g_itemList[30309174]["petIds"][45] = 8289

huantongdan_4.g_itemList[30309174]["petIds"][55] = 8299

huantongdan_4.g_itemList[30309174]["petIds"][65] = 8309

huantongdan_4.g_itemList[30309174]["petIds"][75] = 8319

huantongdan_4.g_itemList[30309174]["petIds"][85] = 8329

huantongdan_4.g_itemList[30309162] = {
    ["rulerId"] = 2,
    ["minPetLevel"] = 1,
    ["maxPetLevel"] = 45,
    ["petIds"] = {}

}

huantongdan_4.g_itemList[30309162]["petIds"][5] = 8349

huantongdan_4.g_itemList[30309162]["petIds"][45] = 8359

huantongdan_4.g_itemList[30309175] = {
    ["rulerId"] = 2,
    ["minPetLevel"] = 1,
    ["maxPetLevel"] = 85,
    ["petIds"] = {}

}

huantongdan_4.g_itemList[30309175]["petIds"][5] = 8349

huantongdan_4.g_itemList[30309175]["petIds"][45] = 8359

huantongdan_4.g_itemList[30309175]["petIds"][55] = 8369

huantongdan_4.g_itemList[30309175]["petIds"][65] = 8379

huantongdan_4.g_itemList[30309175]["petIds"][75] = 8389

huantongdan_4.g_itemList[30309175]["petIds"][85] = 8399

huantongdan_4.g_itemList[30309176] = {
    ["rulerId"] = 2,
    ["minPetLevel"] = 1,
    ["maxPetLevel"] = 45,
    ["petIds"] = {}

}

huantongdan_4.g_itemList[30309176]["petIds"][5] = 8419

huantongdan_4.g_itemList[30309176]["petIds"][45] = 8429

huantongdan_4.g_itemList[30309177] = {
    ["rulerId"] = 2,
    ["minPetLevel"] = 1,
    ["maxPetLevel"] = 85,
    ["petIds"] = {}

}

huantongdan_4.g_itemList[30309177]["petIds"][5] = 8419

huantongdan_4.g_itemList[30309177]["petIds"][45] = 8429

huantongdan_4.g_itemList[30309177]["petIds"][55] = 8439

huantongdan_4.g_itemList[30309177]["petIds"][65] = 8449

huantongdan_4.g_itemList[30309177]["petIds"][75] = 8459

huantongdan_4.g_itemList[30309177]["petIds"][85] = 8469

huantongdan_4.g_itemList[30309178] = {
    ["rulerId"] = 2,
    ["minPetLevel"] = 1,
    ["maxPetLevel"] = 45,
    ["petIds"] = {}

}

huantongdan_4.g_itemList[30309178]["petIds"][5] = 8489

huantongdan_4.g_itemList[30309178]["petIds"][45] = 8499

huantongdan_4.g_itemList[30309179] = {
    ["rulerId"] = 2,
    ["minPetLevel"] = 1,
    ["maxPetLevel"] = 85,
    ["petIds"] = {}

}

huantongdan_4.g_itemList[30309179]["petIds"][5] = 8489

huantongdan_4.g_itemList[30309179]["petIds"][45] = 8499

huantongdan_4.g_itemList[30309179]["petIds"][55] = 8509

huantongdan_4.g_itemList[30309179]["petIds"][65] = 8519

huantongdan_4.g_itemList[30309179]["petIds"][75] = 8529

huantongdan_4.g_itemList[30309179]["petIds"][85] = 8539

huantongdan_4.g_itemList[30309180] = {
    ["rulerId"] = 2,
    ["minPetLevel"] = 1,
    ["maxPetLevel"] = 45,
    ["petIds"] = {}

}

huantongdan_4.g_itemList[30309180]["petIds"][5] = 8569

huantongdan_4.g_itemList[30309180]["petIds"][45] = 8579

huantongdan_4.g_itemList[30309181] = {
    ["rulerId"] = 2,
    ["minPetLevel"] = 1,
    ["maxPetLevel"] = 85,
    ["petIds"] = {}

}

huantongdan_4.g_itemList[30309181]["petIds"][5] = 8569

huantongdan_4.g_itemList[30309181]["petIds"][45] = 8579

huantongdan_4.g_itemList[30309181]["petIds"][55] = 8589

huantongdan_4.g_itemList[30309181]["petIds"][65] = 8599

huantongdan_4.g_itemList[30309181]["petIds"][75] = 8609

huantongdan_4.g_itemList[30309181]["petIds"][85] = 8619

huantongdan_4.g_itemList[30309182] = {
    ["rulerId"] = 2,
    ["minPetLevel"] = 1,
    ["maxPetLevel"] = 45,
    ["petIds"] = {}

}

huantongdan_4.g_itemList[30309182]["petIds"][5] = 8749

huantongdan_4.g_itemList[30309182]["petIds"][45] = 8759

huantongdan_4.g_itemList[30309183] = {
    ["rulerId"] = 2,
    ["minPetLevel"] = 1,
    ["maxPetLevel"] = 85,
    ["petIds"] = {}

}

huantongdan_4.g_itemList[30309183]["petIds"][5] = 8749

huantongdan_4.g_itemList[30309183]["petIds"][45] = 8759

huantongdan_4.g_itemList[30309183]["petIds"][55] = 8769

huantongdan_4.g_itemList[30309183]["petIds"][65] = 8779

huantongdan_4.g_itemList[30309183]["petIds"][75] = 8789

huantongdan_4.g_itemList[30309183]["petIds"][85] = 8799

huantongdan_4.g_itemList[30309184] = {
    ["rulerId"] = 2,
    ["minPetLevel"] = 1,
    ["maxPetLevel"] = 45,
    ["petIds"] = {}

}

huantongdan_4.g_itemList[30309184]["petIds"][5] = 8819

huantongdan_4.g_itemList[30309184]["petIds"][45] = 8829

huantongdan_4.g_itemList[30309185] = {
    ["rulerId"] = 2,
    ["minPetLevel"] = 1,
    ["maxPetLevel"] = 85,
    ["petIds"] = {}

}

huantongdan_4.g_itemList[30309185]["petIds"][5] = 8819

huantongdan_4.g_itemList[30309185]["petIds"][45] = 8829

huantongdan_4.g_itemList[30309185]["petIds"][55] = 8839

huantongdan_4.g_itemList[30309185]["petIds"][65] = 8849

huantongdan_4.g_itemList[30309185]["petIds"][75] = 8859

huantongdan_4.g_itemList[30309185]["petIds"][85] = 8869

huantongdan_4.g_itemList[30309186] = {
    ["rulerId"] = 2,
    ["minPetLevel"] = 1,
    ["maxPetLevel"] = 45,
    ["petIds"] = {}

}

huantongdan_4.g_itemList[30309186]["petIds"][5] = 8889

huantongdan_4.g_itemList[30309186]["petIds"][45] = 8899

huantongdan_4.g_itemList[30309187] = {
    ["rulerId"] = 2,
    ["minPetLevel"] = 1,
    ["maxPetLevel"] = 85,
    ["petIds"] = {}

}

huantongdan_4.g_itemList[30309187]["petIds"][5] = 8889

huantongdan_4.g_itemList[30309187]["petIds"][45] = 8899

huantongdan_4.g_itemList[30309187]["petIds"][55] = 8909

huantongdan_4.g_itemList[30309187]["petIds"][65] = 8919

huantongdan_4.g_itemList[30309187]["petIds"][75] = 8929

huantongdan_4.g_itemList[30309187]["petIds"][85] = 8939

huantongdan_4.g_itemList[30309188] = {
    ["rulerId"] = 2,
    ["minPetLevel"] = 1,
    ["maxPetLevel"] = 45,
    ["petIds"] = {}

}

huantongdan_4.g_itemList[30309188]["petIds"][5] = 22219

huantongdan_4.g_itemList[30309188]["petIds"][45] = 22229

huantongdan_4.g_itemList[30309189] = {
    ["rulerId"] = 2,
    ["minPetLevel"] = 1,
    ["maxPetLevel"] = 85,
    ["petIds"] = {}

}

huantongdan_4.g_itemList[30309189]["petIds"][5] = 22219

huantongdan_4.g_itemList[30309189]["petIds"][45] = 22229

huantongdan_4.g_itemList[30309189]["petIds"][55] = 22239

huantongdan_4.g_itemList[30309189]["petIds"][65] = 22249

huantongdan_4.g_itemList[30309189]["petIds"][75] = 22259

huantongdan_4.g_itemList[30309189]["petIds"][85] = 22269

huantongdan_4.g_itemList[30309190] = {
    ["rulerId"] = 2,
    ["minPetLevel"] = 1,
    ["maxPetLevel"] = 45,
    ["petIds"] = {}

}

huantongdan_4.g_itemList[30309190]["petIds"][5] = 22289

huantongdan_4.g_itemList[30309190]["petIds"][45] = 22299

huantongdan_4.g_itemList[30309191] = {
    ["rulerId"] = 2,
    ["minPetLevel"] = 1,
    ["maxPetLevel"] = 85,
    ["petIds"] = {}

}

huantongdan_4.g_itemList[30309191]["petIds"][5] = 22289

huantongdan_4.g_itemList[30309191]["petIds"][45] = 22299

huantongdan_4.g_itemList[30309191]["petIds"][55] = 22309

huantongdan_4.g_itemList[30309191]["petIds"][65] = 22319

huantongdan_4.g_itemList[30309191]["petIds"][75] = 22329

huantongdan_4.g_itemList[30309191]["petIds"][85] = 22339

huantongdan_4.g_itemList[30309192] = {
    ["rulerId"] = 2,
    ["minPetLevel"] = 1,
    ["maxPetLevel"] = 45,
    ["petIds"] = {}

}

huantongdan_4.g_itemList[30309192]["petIds"][5] = 22499

huantongdan_4.g_itemList[30309192]["petIds"][45] = 22509

huantongdan_4.g_itemList[30309193] = {
    ["rulerId"] = 2,
    ["minPetLevel"] = 1,
    ["maxPetLevel"] = 85,
    ["petIds"] = {}

}

huantongdan_4.g_itemList[30309193]["petIds"][5] = 22499

huantongdan_4.g_itemList[30309193]["petIds"][45] = 22509

huantongdan_4.g_itemList[30309193]["petIds"][55] = 22519
huantongdan_4.g_itemList[30309193]["petIds"][65] = 22529
huantongdan_4.g_itemList[30309193]["petIds"][75] = 22539
huantongdan_4.g_itemList[30309193]["petIds"][85] = 22549

huantongdan_4.g_itemList[30309201] = {
    ["rulerId"] = 2,
    ["minPetLevel"] = 55,
    ["maxPetLevel"] = 85,
    ["petIds"] = {}

}
huantongdan_4.g_itemList[30309201]["petIds"][55] = 23139
huantongdan_4.g_itemList[30309201]["petIds"][65] = 23149
huantongdan_4.g_itemList[30309201]["petIds"][75] = 23159
huantongdan_4.g_itemList[30309201]["petIds"][85] = 23169

huantongdan_4.g_ItemName = 0

function huantongdan_4:IsSkillLikeScript(selfId) return 1 end

function huantongdan_4:CancelImpacts(selfId) return 0 end

function huantongdan_4:OnConditionCheck(selfId)
    if not self:LuaFnVerifyUsedItem(selfId) then return 0 end
    local check = self:CanOperate(selfId)
    if not check or check ~= 1 then return 0 end
    return 1
end

function huantongdan_4:OnDeplete(selfId)
    local bagpos = self:LuaFnGetBagIndexOfUsedItem(selfId)
    self.g_ItemName = self:GetBagItemTransfer(selfId, bagpos)
    if self:LuaFnDepletingUsedItem(selfId) then return 1 end
    return 0
end

function huantongdan_4:OnActivateOnce(selfId)
    local itemTblIndex = self:LuaFnGetItemIndexOfUsedItem(selfId)
    local petItem = self.g_itemList[itemTblIndex]
    if not petItem then
        self:NotifyFailTips(selfId, "Đạo cụ chưa mở, không thể sử dụng.")
        return 0
    end
    local petGUID_H = self:LuaFnGetHighSectionOfTargetPetGuid(selfId)
    local petGUID_L = self:LuaFnGetLowSectionOfTargetPetGuid(selfId)
    if not petGUID_H or not petGUID_L then
        self:NotifyFailTips(selfId, "Chưa đến tìm Trân thú chỉ định.")
        return 0
    end
    local check = self:CanOperate(selfId)
    if not check or check ~= 1 then return 0 end
    local curPetTemplateId = self:LuaFnGetPetDataIDByGUID(selfId, petGUID_H, petGUID_L)
    local curPetTakeLevel = self:GetPetTakeLevel(curPetTemplateId)
    local needMoney = self:LuaFnGetPetHuanTongCost(curPetTakeLevel)
    needMoney = needMoney / 100
    local costMoneyRet = self:LuaFnCostMoneyWithPriority(selfId, needMoney)
    if not costMoneyRet then
        self:NotifyFailTips(selfId, "Khấu trừ kim tiền thất bại.")
        return 0
    end
    local delRet = self:LuaFnDeletePetByGUID(selfId, petGUID_H, petGUID_L)
    if not delRet then
        self:NotifyFailTips(selfId, "Khấu trừ Trân thú ban đầu thất bại.")
        return 0
    end
    local createRet, PetID_H, PetID_L = self:LuaFnCreatePetToHuman(selfId,  petItem["petIds"][curPetTakeLevel], 1, petItem["rulerId"])
    if not createRet  then
        self:NotifyFailTips(selfId, "Thêm mới Trân thú thất bại.")
        return 0
    end
    local PlayerName = self:GetName(selfId)
    PlayerName = gbk.fromutf8(PlayerName)
    local PetName = self:LuaFnGetPetTransferByGUID(selfId, PetID_H, PetID_L)
    local strText = ""
    if (itemTblIndex == 30309186) or (itemTblIndex == 30309187) then
        strText = string.format(  "#{HT10}#{_INFOUSR%s}#{HT11}#{_INFOMSG%s}#{HT12}#{_INFOMSG%s}#{HT13}", PlayerName, self.g_ItemName, PetName)
    else
        local inforand = math.random(3)
        if inforand == 1 then
            strText = string.format( "#{HT01}#{_INFOMSG%s}#{HT02}#{_INFOMSG%s}#{HT03}#{_INFOUSR%s}#{HT04}", self.g_ItemName, PetName, PlayerName)
        elseif inforand == 2 then
            strText = string.format( "#{HT05}#{_INFOUSR%s}#{HT06}#{_INFOMSG%s}#{HT07}#{_INFOMSG%s}#H#{HSLJJF_2}", PlayerName, self.g_ItemName, PetName)
        else
            strText = string.format( "#{_INFOUSR%s}#{HT08}#{_INFOMSG%s}#{HT09}#{_INFOMSG%s}#H#{HSLJJF_2}", PlayerName, self.g_ItemName, PetName)
        end
    end
    self:BroadMsgByChatPipe(selfId, strText, 4)
    self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 18, 0)
    return 1
end

function huantongdan_4:OnActivateEachTick(selfId) return 1 end

function huantongdan_4:NotifyFailTips(selfId, Tip)
    self:BeginEvent(self.script_id)
    self:AddText(Tip)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

function huantongdan_4:CanOperate(selfId)
    local itemTblIndex = self:LuaFnGetItemIndexOfUsedItem(selfId)
    local petItem = self.g_itemList[itemTblIndex]
    if not petItem then
        self:NotifyFailTips(selfId, "Đạo cụ chưa mở, không thể sử dụng.")
        return 0
    end
    local petGUID_H = self:LuaFnGetHighSectionOfTargetPetGuid(selfId)
    local petGUID_L = self:LuaFnGetLowSectionOfTargetPetGuid(selfId)
    if not petGUID_H or not petGUID_L then
        self:NotifyFailTips(selfId, "Chưa đến tìm Trân thú chỉ định.")
        return 0
    end
    local curPetTemplateId = self:LuaFnGetPetDataIDByGUID(selfId, petGUID_H, petGUID_L)
    if not curPetTemplateId or curPetTemplateId < 0 then
        self:NotifyFailTips(selfId, "Trân thú được chỉ định không thể dùng.")
        return 0
    end
    local checkPetRet = self:LuaFnIsPetAvailableByGUID(selfId, petGUID_H,  petGUID_L)
    if not checkPetRet then
        self:NotifyFailTips(selfId, "Trân thú bị khóa không thể tiến hành Thao tác này.")
        return 0
    end
    local spouseGUID_H, spouseGUID_L = self:LuaFnGetPetSpouseGUIDByGUID(selfId, petGUID_H, petGUID_L)
    if not spouseGUID_H or not spouseGUID_L or spouseGUID_H ~= 0 or spouseGUID_L ~= 0 then
        self:NotifyFailTips(selfId, "Trân thú đã có phối ngẫu không thể tiến hành Thao tác này.")
        return 0
    end
    local petType = self:LuaFnGetPetTypeByGUID(selfId, petGUID_H, petGUID_L)
    if not petType or petType == 1 then
        self:NotifyFailTips(selfId, "Trân thú biến dị và đời hai không thể tiến hành Thao tác này.")
        return 0
    end
    local curPetTakeLevel = self:GetPetTakeLevel(curPetTemplateId)
    if not curPetTakeLevel or petItem["minPetLevel"] > curPetTakeLevel or  curPetTakeLevel > petItem["maxPetLevel"] then
        self:NotifyFailTips(selfId, "Chỉ có thể Thao tác với Trân thú mang Cấp độ" .. petItem["minPetLevel"] ..  "Đến" .. petItem["maxPetLevel"] ..  "của Trân thú.")
        return 0
    end
    if not petItem["petIds"][curPetTakeLevel] then
        self:NotifyFailTips(selfId, "Không thể Thao tác với Trân thú mang Cấp độ là" .. curPetTakeLevel .. "của Trân thú.")
        return 0
    end
    local humanMoney = self:LuaFnGetMoney(selfId) + self:GetMoneyJZ(selfId)
    local needMoney = self:LuaFnGetPetHuanTongCost(curPetTakeLevel)
    needMoney = needMoney / 100
    if not humanMoney or not needMoney or needMoney < 0 or humanMoney < 0 or
        humanMoney < needMoney then
        self:NotifyFailTips(selfId, "Kim tiền không đủ.")
        return 0
    end
    return 1
end

return huantongdan_4
