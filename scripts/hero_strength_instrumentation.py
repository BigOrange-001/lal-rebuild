"""Instrumentation for offline hero-strength studies, not the AIR runtime."""
from manual_ability_sim import SkillCompleteBattle
from manual_ability_sim import KINDS


def unsupported_manual_skills(cfg, hero_ids):
    """Fail closed before a study rather than silently skip unsupported skills."""
    implemented = KINDS | {'cat_n', 'cat_c', 'polar_n', 'polar_c',
                           'santa_n', 'santa_c', 'nurse_n', 'nurse_c'}
    missing = {}
    for aid in hero_ids:
        hero = cfg['avatar'][aid]
        pl = hero.get('pl', [])
        for slot in (10, 11, 13):
            if slot >= len(pl):
                continue
            for action in cfg.get('skill', {}).get(pl[slot], {}).get('skill', []):
                if (isinstance(action, list) and len(action) > 1
                        and action[0] == 'manual_ability' and action[1] not in implemented):
                    missing.setdefault(aid, []).append(action[1])
    return missing


class MeasuredBattle(SkillCompleteBattle):
    """Attribute health, shield and healing events to their originating hero."""

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.statistics = {}
        for side, roster in ((1, self.a), (2, self.b)):
            for unit in roster:
                token = unit['_owner_token']
                self.statistics[(side, token)] = dict(damage=0, healing=0, taken=0)

    def _stat_key(self, unit):
        if not unit:
            return None
        side = self._team_number(unit)
        token = unit.get('summon_owner_token') or unit.get('_owner_token')
        return (side, token) if (side, token) in self.statistics else None

    def _study_statistics_event(self, source, target, damage, healing):
        actor, victim = self._stat_key(source), self._stat_key(target)
        if actor:
            self.statistics[actor]['healing'] += healing
        if victim:
            self.statistics[victim]['taken'] += damage
        if actor and self._team_number(source) != self._team_number(target):
            self.statistics[actor]['damage'] += damage

    def shares(self, side, token):
        """Per-battle hero share of its team's totals; zero for a zero total."""
        row = self.statistics[(side, token)]
        totals = {key: sum(values[key] for (team, _), values in self.statistics.items()
                           if team == side) for key in row}
        return {key: row[key] / totals[key] if totals[key] else 0.0 for key in row}
