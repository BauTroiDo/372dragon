#pragma once




namespace CysQuickbarContract {
enum { SlotCount = 50, SettingFirst = 2, LegacyTagFirst = 128, ChatSettingFirst = 52 };
inline bool IsSlot(int n) { return n >= 0 && n < SlotCount; }
inline int TaggedSlot(int slot) { return LegacyTagFirst + slot; }
inline int ChatSetting(int tab) {
    switch (tab) { case 2: return 52; case 3: return 70; case 5: return 112;
    case 6: return 54; case 7: return 56; case 8: return 79; default: return -1; }
}
}
