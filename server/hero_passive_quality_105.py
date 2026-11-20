"""Keep standalone hero passives exclusive to six-star forms."""

# These built-in families share passive data or triggers with their active kits.
LOW_STAR_PASSIVE_EXCEPTIONS = frozenset({
    'A_1140', 'A_1201', 'A_1203', 'A_1204', 'A_1206', 'A_1207', 'A_1209',
    'A_1211', 'A_1213', 'A_1214', 'A_1215', 'A_1216', 'A_1218', 'A_1219',
    'A_1228',
})


def restrict_low_star_passives(document):
    for aid, avatar in document['cfg']['avatar'].items():
        if not aid.startswith('A_1') or avatar.get('modUnitType') == 'summon':
            continue
        family, _, quality = aid.rpartition('_')
        if quality not in ('1', '2', '3', '4', '5') or family in LOW_STAR_PASSIVE_EXCEPTIONS:
            continue
        panel = avatar.get('pl', ())
        if len(panel) > 13 and panel[13]:
            panel[13] = None
