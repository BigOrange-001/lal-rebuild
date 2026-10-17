"""Boundary checks for the Android letterbox and native resize contract."""

import unittest
from pathlib import Path


SOURCE = (Path(__file__).resolve().parents[1] / "client/src/stages/136_MainLLOL.as")


def viewport(width, height, insets=(0, 0, 0, 0), logical_height=None):
    left, top, right, bottom = insets
    usable = (left, top, width - left - right, height - top - bottom)
    logical_height = logical_height or round(max(960, min(1138, 640 * height / width)))
    scale = min(usable[2] / 640, usable[3] / logical_height)
    return (
        usable[0] + (usable[2] - 640 * scale) / 2,
        usable[1] + (usable[3] - logical_height * scale) / 2,
        640 * scale,
        logical_height * scale,
        logical_height,
    )


class FullscreenViewportTest(unittest.TestCase):
    def test_phone_ratios_keep_full_unstretched_content(self):
        for width, height in ((720, 1080), (720, 1280), (1080, 2160),
                              (1080, 2340), (1080, 2400)):
            with self.subTest(size=(width, height)):
                x, y, w, h, logical_h = viewport(width, height)
                self.assertGreaterEqual(logical_h, 960)
                self.assertLessEqual(logical_h, 1138)
                self.assertAlmostEqual(w / 640, h / logical_h)
                self.assertAlmostEqual(x, (width - w) / 2)
                self.assertAlmostEqual(y, (height - h) / 2)
                self.assertGreaterEqual(x, 0)
                self.assertGreaterEqual(y, 0)
                self.assertLessEqual(x + w, width)
                self.assertLessEqual(y + h, height)

    def test_cutout_and_resize_are_bounded_and_idempotent(self):
        first = viewport(1080, 2400, (0, 80, 0, 40))
        self.assertAlmostEqual(first[0], 0)
        self.assertGreaterEqual(first[1], 80)
        self.assertLessEqual(first[1] + first[3], 2360)
        self.assertEqual(first, viewport(1080, 2400, (0, 80, 0, 40)))
        rotated = viewport(2400, 1080, (80, 0, 0, 0), logical_height=first[4])
        self.assertGreaterEqual(rotated[0], 80)
        self.assertLessEqual(rotated[0] + rotated[2], 2400)
        self.assertLessEqual(rotated[1] + rotated[3], 1080)
        self.assertEqual(first, viewport(1080, 2400, (0, 80, 0, 40), first[4]))

    def test_native_resize_keeps_logical_stage(self):
        source = SOURCE.read_text(encoding="utf-8-sig")
        resize = source.split("private function stage_resizeHandler", 1)[1].split(
            "private function syncAndroidViewportMetrics", 1)[0]
        self.assertIn("$starlingRec.equals(viewport)", resize)
        self.assertIn("GlobalData.$mStarling.viewPort = viewport", resize)
        self.assertNotIn("stage.stageWidth =", resize)
        self.assertNotIn("stage.stageHeight =", resize)
        self.assertIn("screen.safeArea", source)


if __name__ == "__main__":
    unittest.main()
