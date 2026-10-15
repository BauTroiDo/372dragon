-- Four schools prepared from verified donor identities.
-- Enable only after combat, NPC and client checks succeed; do not bypass check_ready.
-- CS3b (14/09/2026): khoá = số phái CY (11 唐门, 12 鬼谷, 13 桃花岛, 14 绝情谷); skill/xinfa = ID CY tra theo tên từ ID GL cũ.
return {
    [11] = { -- GL 13
        enum = "MATTRIBUTE_TANGMEN", name = "唐门", enabled = true,
        abilities = {70, 71}, compound_ability = 70,
        skills7 = {2921, 2922, 2923}, -- GL {5766, 5767, 5642}: position, position, name
        xinfa7 = 87, xinfa8 = 88,
        qinggong = 2942, reputation = 59,
        attack_traits = 17, quick_skills = {2900, 2901, 2902},
    },
    [12] = { -- GL 14
        enum = "MATTRIBUTE_GUIGU", name = "鬼谷", enabled = true,
        abilities = {72, 73}, compound_ability = 72,
        skills7 = {3451, 3452, 3453}, -- GL {5670, 5671, 5672}: name, name, name
        xinfa7 = 95, xinfa8 = 96,
        qinggong = 3518, reputation = 60,
        attack_traits = 18, quick_skills = {3430, 3431, 3432},
    },
    [13] = { -- GL 15
        enum = "MATTRIBUTE_TAOHUADAO", name = "桃花岛", enabled = true,
        abilities = {74, 75}, compound_ability = 74,
        skills7 = {3821, 3822, 3823}, -- GL {5708, 5709, 5710}: name, name, name
        xinfa7 = 103, xinfa8 = 104,
        qinggong = 3836, reputation = 61,
        attack_traits = 19, quick_skills = {3800, 3801, 3802},
    },
    [14] = { -- GL 16
        enum = "MATTRIBUTE_JUEQINGGU", name = "绝情谷", enabled = true,
        abilities = {76, 77}, compound_ability = 76,
        skills7 = {4542, 4543, 4544}, -- GL {5750, 5751, 5752}: name, name, name
        xinfa7 = 111, xinfa8 = 112,
        qinggong = 4547, reputation = 62,
        attack_traits = 20, quick_skills = {4515, 4516, 4517},
    },
}
