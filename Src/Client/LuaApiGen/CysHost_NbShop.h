


















#pragma once
class tObject_Item;

namespace CysHostNbShop
{
    bool Off(char link);
    const char* OffText();
    // The host body. Returns false when there is no event system to push to.
    bool ToggleYuanbaoShop();
    void RegisterHost();
    // True when currency is handled by the CY confirmation/buy path.
    bool BuyItemOrConfirm(tObject_Item* item);
}
