"""CY RSSkill values; native rows identify mechanics, never override CY ranks."""
import re

def rl_specs(rows):
    result = {}
    for ordinal, row in enumerate(rows):
        group = row[0]
        ranks = {}
        for star in range(1, 10):
            desc = row[12 + star]
            def number(pattern):
                match = re.search(pattern, desc)
                assert match, (group, star, pattern, desc)
                value = float(match[1])
                return int(value) if value.is_integer() else value
            spec = dict(source=11832 + ordinal * 9 + star - 1,
                        cooldown=number(r'此效果([\d.]+)秒') * 1000)
            if group != 12 and group != 14 and group != 19:
                spec['duration'] = number(r'持续(?:时间超过)?([\d.]+)秒') * 1000 if group != 22 else 500
            if group <= 4: spec['value'] = number(r'增加(\d+)点')
            elif group == 5: spec['value'] = -number(r'降低(\d+)%')
            elif group == 6: spec['value'] = number(r'增加(\d+)%')
            elif group == 11: spec['value'] = number(r'获得(\d+)点')
            elif group == 12: spec['count'] = number(r'最多(\d+)个')
            elif group == 13: spec['value'] = number(r'拥有(\d+)血量')
            elif group == 14: spec['count'] = number(r'对(\d+)个')
            elif group == 15: spec['value'] = number(r'增加(\d+)%')
            elif group == 17: spec['value'] = number(r'每秒失血(\d+)点')
            elif group == 21: spec['value'] = number(r'降低(\d+)%')
            ranks[star] = spec
        result[group] = ranks
    return result
