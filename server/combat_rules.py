"""Opt-in offline combat model; candidate values never overwrite live attack[]."""
import copy
import json
from pathlib import Path


PATH = Path(__file__).resolve().parents[1] / 'config/reconstruction/combat-rules-1.0.4.json'


def apply_combat_rules(document):
    # This object already carries recovery and damage-sharing contracts.
    # Add the model controls without replacing those existing rules.
    rules = document['cfg'].setdefault('combat_rules', {})
    for key, value in json.loads(PATH.read_text('utf8')).items():
        rules.setdefault(key, value)


def ratio_enabled(rules):
    return bool(rules and rules.get('model') == 'ratio')


def attack_parameters(config):
    """Return a battle-local copy, leaving serialization and old clients alone."""
    attack = list(config.get('system_simple', {}).get('attack') or [])
    rules = config.get('combat_rules') or {}
    if ratio_enabled(rules):
        if len(attack) < 22:
            raise ValueError('ratio combat requires the complete attack configuration')
        for index, value in rules.get('attack_overrides', {}).items():
            attack[int(index)] = float(value)
    return attack


def candidate_config(config, **parameters):
    """Explicit research-only copy; never changes the loaded default config."""
    result = copy.deepcopy(config)
    rules = json.loads(PATH.read_text('utf8'))
    rules.update(result.get('combat_rules') or {})
    rules['model'] = 'ratio'
    attack = dict(rules['attack_overrides'])
    attack.update(parameters.pop('attack_overrides', {}))
    rules.update(parameters)
    rules['attack_overrides'] = attack
    result['combat_rules'] = rules
    return result
