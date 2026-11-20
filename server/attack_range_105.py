MIN_ATTACK_RANGE = 350

# Form-changing heroes have their own positioning. Graves has short shotgun
# reach, and the two newer skins already have individually tuned ranges.
SPECIAL_RANGES = frozenset({
    'A_1036', 'A_1041', 'A_1053', 'A_1105', 'A_1120', 'A_1123', 'A_1801', 'A_1802',
})


def apply_attack_ranges(document):
    """Adjust built-in normal attack ranges without changing skill reach."""
    for aid, row in document['cfg']['avatar'].items():
        panel = row.get('pl') or []
        if len(panel) <= 9:
            continue
        reach = panel[9]
        if reach <= 0:
            continue
        if row.get('modUnitType') == 'summon':
            panel[9] = max(reach, MIN_ATTACK_RANGE)
        elif aid.startswith('A_1'):
            family = aid.rsplit('_', 1)[0]
            ranged = row.get('ranged_skill', reach >= 500)
            if not ranged or family in SPECIAL_RANGES:
                panel[9] = max(reach, MIN_ATTACK_RANGE)
            elif reach < 600:
                panel[9] = 700
            elif reach < 630:
                panel[9] = 750
            elif reach < 700:
                panel[9] = 800
