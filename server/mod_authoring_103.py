"""Shared 1.0.3 hero/skill baseline; no gateway, save or battle execution."""
def apply_mod_authoring_103(document):
    from summon_panel_103 import apply_summon_panel_config
    from skill_books import apply_equipment_calibration
    from hero_skills_103 import apply_hero_skills_103, finalize_hero_skills_103
    from talent_stats_103 import apply_talent_stats_103
    from hero_balance_103 import apply_hero_balance_103
    from dot_rules_103 import apply_dot_rules_103
    from cat_katarina_103 import apply_cat_katarina_103
    from polar_ashe_103 import apply_polar_ashe_103
    from santa_veigar_103 import apply_santa_veigar_103
    from nurse_akali_103 import apply_nurse_akali_103
    from hero_accuracy_103 import apply_hero_accuracy_103
    from hero_iteration_103 import apply_hero_iteration_103
    from gameplay_energy import apply_energy_purchase_103
    for apply in (apply_summon_panel_config,apply_equipment_calibration,apply_hero_skills_103,
                  apply_talent_stats_103,apply_hero_balance_103,finalize_hero_skills_103,
                  apply_dot_rules_103,apply_cat_katarina_103,apply_polar_ashe_103,
                  apply_santa_veigar_103,apply_nurse_akali_103,
                  apply_hero_accuracy_103,apply_hero_iteration_103,apply_energy_purchase_103):
        apply(document)
    return document
