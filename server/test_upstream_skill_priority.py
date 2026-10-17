"""The authored PR skill rows must survive final configuration publication."""
import copy
import json
import subprocess
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from upstream_skill_priority import SKILL_IDS, apply_upstream_skill_priority


ROOT = Path(__file__).resolve().parents[1]
DELTA = json.loads((ROOT / "server/upstream_hero_config_delta.json").read_text(encoding="utf-8"))


class UpstreamSkillPriorityTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        source = subprocess.check_output(
            ["git", "-c", f"safe.directory={ROOT.as_posix()}", "show",
             f"{DELTA['source_commit']}:{DELTA['source_path']}"], cwd=ROOT)
        cls.origin_skills = json.loads(source)["cfg"]["skill"]
        cls.published = json.loads(
            (ROOT / "config/reconstruction/full-config.json").read_text(encoding="utf-8"))

    def test_snapshot_contains_exact_unmodified_upstream_rows(self):
        self.assertEqual(len(SKILL_IDS), 20)
        self.assertEqual(set(DELTA["skill"]), SKILL_IDS)
        for sid in SKILL_IDS:
            self.assertEqual(DELTA["skill"][sid], self.origin_skills[sid], sid)

    def test_priority_clears_balance_fields_and_preserves_all_other_skills(self):
        document = copy.deepcopy(self.published)
        cfg = document["cfg"]
        for sid in SKILL_IDS:
            row = cfg["skill"][sid]
            row["pl"][1] = 0
            row["skill"][0][1] = 999
            row["captainSummonMultiplier"] = 7
            row["manualDamageMultiplier"] = 7
            row["unexpected_balance_field"] = True
        unrelated = {sid: copy.deepcopy(row) for sid, row in cfg["skill"].items()
                     if sid not in SKILL_IDS}
        other_cfg = {key: copy.deepcopy(value) for key, value in cfg.items()
                     if key not in ("skill", "upstream_skill_priority")}

        apply_upstream_skill_priority(document)
        self.assertEqual({sid: cfg["skill"][sid] for sid in SKILL_IDS},
                         {sid: self.origin_skills[sid] for sid in SKILL_IDS})
        self.assertEqual({sid: row for sid, row in cfg["skill"].items()
                          if sid not in SKILL_IDS}, unrelated)
        self.assertEqual({key: value for key, value in cfg.items()
                          if key not in ("skill", "upstream_skill_priority")}, other_cfg)
        marker = cfg["upstream_skill_priority"]
        self.assertEqual(marker["source_commit"], DELTA["source_commit"])
        self.assertEqual(marker["sids"], sorted(SKILL_IDS))

        saved = copy.deepcopy(document)
        apply_upstream_skill_priority(document)
        self.assertEqual(document, saved)
        cfg["skill"]["S_301226_6"]["pl"][1] = 0
        apply_upstream_skill_priority(document)
        self.assertEqual(document, saved)


if __name__ == "__main__":
    unittest.main()
