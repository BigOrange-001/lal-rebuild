"""Skill detail popups show the hero art above the panel, as in the original game."""


def apply_skill_tips(document):
    cfg = document.get('cfg', document)
    # PanelPop draws the avatar from the popup's res/aid only when pop_res is on.
    cfg.setdefault('client_config', {})['pop_res'] = 1
    return document
