"""Veigar's captain accuracy is limited to the current cast."""
def apply_hero_accuracy_103(document):
    cfg=document.get('cfg',document)
    suffix='本次队长技能释放期间精准额外提高30000点，释放结束后还原。'
    for aid,hero in cfg['avatar'].items():
        if not aid.startswith('A_1027_'):continue
        skill=cfg['skill'][hero['pl'][11]]
        for key in ('info','info_tw','rankInfoTemplate'):
            if isinstance(skill.get(key),str) and suffix not in skill[key]:skill[key]+=suffix
    return document
