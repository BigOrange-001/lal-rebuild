"""Keep the native and server equipment inventory limit in one config row."""

MIN_EQUIPMENT_CAPACITY = 1000


def apply_equipment_capacity(document):
    cfg = document.get("cfg", document)
    simple = cfg.get("system_simple") if isinstance(cfg, dict) else None
    row = simple.get("equip_config") if isinstance(simple, dict) else None
    if not isinstance(row, list) or len(row) < 11 or type(row[0]) is not int:
        raise ValueError("Equipment capacity configuration is incomplete")
    row[0] = max(MIN_EQUIPMENT_CAPACITY, row[0])
    return document
