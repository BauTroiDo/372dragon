




#include "LuaApiGen.h"

namespace LuaApiGen
{
    namespace
    {


        int LAG_Auction_AskAuctionBoxList(LuaPlus::LuaState* state) { return Stub(state, "Auction", "AskAuctionBoxList", ""); }


        int LAG_Auction_ChangePrice(LuaPlus::LuaState* state) { return Stub(state, "Auction", "ChangePrice", ""); }

        int LAG_Auction_CloseOnSaleWindow(LuaPlus::LuaState* state) { return Stub(state, "Auction", "CloseOnSaleWindow", ""); }

        int LAG_Auction_CloseUpItemWindow(LuaPlus::LuaState* state) { return Stub(state, "Auction", "CloseUpItemWindow", ""); }

        int LAG_Auction_CloseUpPetWindow(LuaPlus::LuaState* state) { return Stub(state, "Auction", "CloseUpPetWindow", ""); }


        int LAG_Auction_GetBackExpired(LuaPlus::LuaState* state) { return Stub(state, "Auction", "GetBackExpired", ""); }


        int LAG_Auction_GetBackWhatOnSale(LuaPlus::LuaState* state) { return Stub(state, "Auction", "GetBackWhatOnSale", ""); }

        int LAG_Auction_GetItemAuctionInfo(LuaPlus::LuaState* state) { return Stub(state, "Auction", "GetItemAuctionInfo", "sssn"); }


        int LAG_Auction_GetMoney(LuaPlus::LuaState* state) { return Stub(state, "Auction", "GetMoney", ""); }

        int LAG_Auction_GetMySellBoxItemAuctionInfo(LuaPlus::LuaState* state) { return Stub(state, "Auction", "GetMySellBoxItemAuctionInfo", "snn"); }

        int LAG_Auction_GetMySellBoxItemName(LuaPlus::LuaState* state) { return Stub(state, "Auction", "GetMySellBoxItemName", "s"); }

        int LAG_Auction_GetMySellBoxItemNum(LuaPlus::LuaState* state) { return Stub(state, "Auction", "GetMySellBoxItemNum", "n"); }

        int LAG_Auction_GetMySellBoxPetAuctionInfo(LuaPlus::LuaState* state) { return Stub(state, "Auction", "GetMySellBoxPetAuctionInfo", "snn"); }

        int LAG_Auction_GetNeedMoneyForSell(LuaPlus::LuaState* state) { return Stub(state, "Auction", "GetNeedMoneyForSell", "n"); }

        int LAG_Auction_GetNeedMoneyForSellByPetShop(LuaPlus::LuaState* state) { return Stub(state, "Auction", "GetNeedMoneyForSellByPetShop", "n"); }

        int LAG_Auction_GetPetAuctionInfo(LuaPlus::LuaState* state) { return Stub(state, "Auction", "GetPetAuctionInfo", "ssn"); }

        int LAG_Auction_GetPetEraCount(LuaPlus::LuaState* state) { return Stub(state, "Auction", "GetPetEraCount", "n"); }


        int LAG_Auction_GetPetList_Appoint(LuaPlus::LuaState* state) { return Stub(state, "Auction", "GetPetList_Appoint", "s"); }


        int LAG_Auction_GetPetPortraitByIndex(LuaPlus::LuaState* state) { return Stub(state, "Auction", "GetPetPortraitByIndex", "s"); }

        int LAG_Auction_IsYBMarketCanSwitchPage(LuaPlus::LuaState* state) { return Stub(state, "Auction", "IsYBMarketCanSwitchPage", "n"); }

        int LAG_Auction_OpenChangePriceWindow(LuaPlus::LuaState* state) { return Stub(state, "Auction", "OpenChangePriceWindow", ""); }

        int LAG_Auction_OpenOnSaleWindow(LuaPlus::LuaState* state) { return Stub(state, "Auction", "OpenOnSaleWindow", ""); }

        int LAG_Auction_OpenUpItemWindow(LuaPlus::LuaState* state) { return Stub(state, "Auction", "OpenUpItemWindow", ""); }

        int LAG_Auction_OpenUpPetWindow(LuaPlus::LuaState* state) { return Stub(state, "Auction", "OpenUpPetWindow", ""); }


        int LAG_Auction_PacketSend_Buy(LuaPlus::LuaState* state) { return Stub(state, "Auction", "PacketSend_Buy", ""); }


        int LAG_Auction_PacketSend_MultiBuy(LuaPlus::LuaState* state) { return Stub(state, "Auction", "PacketSend_MultiBuy", ""); }


        int LAG_Auction_PacketSend_Search(LuaPlus::LuaState* state) { return Stub(state, "Auction", "PacketSend_Search", ""); }


        int LAG_Auction_PacketSend_SellItem(LuaPlus::LuaState* state) { return Stub(state, "Auction", "PacketSend_SellItem", ""); }


        int LAG_Auction_PacketSend_SellPet(LuaPlus::LuaState* state) { return Stub(state, "Auction", "PacketSend_SellPet", ""); }


        int LAG_Auction_ReUpExpired(LuaPlus::LuaState* state) { return Stub(state, "Auction", "ReUpExpired", ""); }

        int LAG_Auction_SetPageItemSelect(LuaPlus::LuaState* state) { return Stub(state, "Auction", "SetPageItemSelect", ""); }

        int LAG_Auction_ShowMySellBox_PetInfo(LuaPlus::LuaState* state) { return Stub(state, "Auction", "ShowMySellBox_PetInfo", ""); }

        int LAG_Auction_ShowYBMarketCurPage_PetInfo(LuaPlus::LuaState* state) { return Stub(state, "Auction", "ShowYBMarketCurPage_PetInfo", ""); }
    }

    void Register_Auction(LuaPlus::LuaObject& table)
    {
        if (IsMissing(table, "AskAuctionBoxList")) table.Register("AskAuctionBoxList", LAG_Auction_AskAuctionBoxList);
        if (IsMissing(table, "ChangePrice")) table.Register("ChangePrice", LAG_Auction_ChangePrice);
        if (IsMissing(table, "CloseOnSaleWindow")) table.Register("CloseOnSaleWindow", LAG_Auction_CloseOnSaleWindow);
        if (IsMissing(table, "CloseUpItemWindow")) table.Register("CloseUpItemWindow", LAG_Auction_CloseUpItemWindow);
        if (IsMissing(table, "CloseUpPetWindow")) table.Register("CloseUpPetWindow", LAG_Auction_CloseUpPetWindow);
        if (IsMissing(table, "GetBackExpired")) table.Register("GetBackExpired", LAG_Auction_GetBackExpired);
        if (IsMissing(table, "GetBackWhatOnSale")) table.Register("GetBackWhatOnSale", LAG_Auction_GetBackWhatOnSale);
        if (IsMissing(table, "GetItemAuctionInfo")) table.Register("GetItemAuctionInfo", LAG_Auction_GetItemAuctionInfo);
        if (IsMissing(table, "GetMoney")) table.Register("GetMoney", LAG_Auction_GetMoney);
        if (IsMissing(table, "GetMySellBoxItemAuctionInfo")) table.Register("GetMySellBoxItemAuctionInfo", LAG_Auction_GetMySellBoxItemAuctionInfo);
        if (IsMissing(table, "GetMySellBoxItemName")) table.Register("GetMySellBoxItemName", LAG_Auction_GetMySellBoxItemName);
        if (IsMissing(table, "GetMySellBoxItemNum")) table.Register("GetMySellBoxItemNum", LAG_Auction_GetMySellBoxItemNum);
        if (IsMissing(table, "GetMySellBoxPetAuctionInfo")) table.Register("GetMySellBoxPetAuctionInfo", LAG_Auction_GetMySellBoxPetAuctionInfo);
        if (IsMissing(table, "GetNeedMoneyForSell")) table.Register("GetNeedMoneyForSell", LAG_Auction_GetNeedMoneyForSell);
        if (IsMissing(table, "GetNeedMoneyForSellByPetShop")) table.Register("GetNeedMoneyForSellByPetShop", LAG_Auction_GetNeedMoneyForSellByPetShop);
        if (IsMissing(table, "GetPetAuctionInfo")) table.Register("GetPetAuctionInfo", LAG_Auction_GetPetAuctionInfo);
        if (IsMissing(table, "GetPetEraCount")) table.Register("GetPetEraCount", LAG_Auction_GetPetEraCount);
        if (IsMissing(table, "GetPetList_Appoint")) table.Register("GetPetList_Appoint", LAG_Auction_GetPetList_Appoint);
        if (IsMissing(table, "GetPetPortraitByIndex")) table.Register("GetPetPortraitByIndex", LAG_Auction_GetPetPortraitByIndex);
        if (IsMissing(table, "IsYBMarketCanSwitchPage")) table.Register("IsYBMarketCanSwitchPage", LAG_Auction_IsYBMarketCanSwitchPage);
        if (IsMissing(table, "OpenChangePriceWindow")) table.Register("OpenChangePriceWindow", LAG_Auction_OpenChangePriceWindow);
        if (IsMissing(table, "OpenOnSaleWindow")) table.Register("OpenOnSaleWindow", LAG_Auction_OpenOnSaleWindow);
        if (IsMissing(table, "OpenUpItemWindow")) table.Register("OpenUpItemWindow", LAG_Auction_OpenUpItemWindow);
        if (IsMissing(table, "OpenUpPetWindow")) table.Register("OpenUpPetWindow", LAG_Auction_OpenUpPetWindow);
        if (IsMissing(table, "PacketSend_Buy")) table.Register("PacketSend_Buy", LAG_Auction_PacketSend_Buy);
        if (IsMissing(table, "PacketSend_MultiBuy")) table.Register("PacketSend_MultiBuy", LAG_Auction_PacketSend_MultiBuy);
        if (IsMissing(table, "PacketSend_Search")) table.Register("PacketSend_Search", LAG_Auction_PacketSend_Search);
        if (IsMissing(table, "PacketSend_SellItem")) table.Register("PacketSend_SellItem", LAG_Auction_PacketSend_SellItem);
        if (IsMissing(table, "PacketSend_SellPet")) table.Register("PacketSend_SellPet", LAG_Auction_PacketSend_SellPet);
        if (IsMissing(table, "ReUpExpired")) table.Register("ReUpExpired", LAG_Auction_ReUpExpired);
        if (IsMissing(table, "SetPageItemSelect")) table.Register("SetPageItemSelect", LAG_Auction_SetPageItemSelect);
        if (IsMissing(table, "ShowMySellBox_PetInfo")) table.Register("ShowMySellBox_PetInfo", LAG_Auction_ShowMySellBox_PetInfo);
        if (IsMissing(table, "ShowYBMarketCurPage_PetInfo")) table.Register("ShowYBMarketCurPage_PetInfo", LAG_Auction_ShowYBMarketCurPage_PetInfo);
    }
}
