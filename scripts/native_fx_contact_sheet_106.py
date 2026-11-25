"""Render effectDB armatures (effect/eNNN) from the shipped SWF as contact sheets.

Offline approximation for reviewing native art: bones, slot order, nested
armatures, tweened transforms and alpha are applied; blend modes and colour
offsets are not.  Each row shows one armature at 10%, 35%, 60% and 85% of its
first animation.

    python scripts/native_fx_contact_sheet_106.py OUT.png e504,e602,e521
    python scripts/native_fx_contact_sheet_106.py OUT.png --idle   # every armature no table entry uses
"""
from __future__ import annotations

import argparse
import io
import json
import math
import re
import struct
import sys
import xml.etree.ElementTree as ET
import zlib
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
TEMPLATE = ROOT / "client/resources/template/MainLLOL.swf"


def embedded(path=TEMPLATE):
    """Return (skeleton xml, atlas xml, atlas image) embedded in the SWF."""
    data = path.read_bytes()
    body = zlib.decompress(data[8:]) if data[:3] == b"CWS" else data[8:]
    offset = (5 + 4 * (body[0] >> 3) + 7) // 8 + 4
    binary, bitmaps, symbols = {}, {}, {}
    while offset < len(body):
        header = struct.unpack("<H", body[offset:offset + 2])[0]
        offset += 2
        code, length = header >> 6, header & 0x3F
        if length == 0x3F:
            length = struct.unpack("<I", body[offset:offset + 4])[0]
            offset += 4
        tag = body[offset:offset + length]
        offset += length
        if code == 87:
            binary[struct.unpack("<H", tag[:2])[0]] = tag[6:]
        elif code == 21:
            bitmaps[struct.unpack("<H", tag[:2])[0]] = tag[2:]
        elif code == 76:
            count, pos = struct.unpack("<H", tag[:2])[0], 2
            for _ in range(count):
                cid = struct.unpack("<H", tag[pos:pos + 2])[0]
                end = tag.index(b"\0", pos + 2)
                symbols[tag[pos + 2:end].decode("utf-8")] = cid
                pos = end + 1
        elif code == 0:
            break
    pick = lambda prefix: next(cid for name, cid in symbols.items() if name.startswith(prefix))
    skeleton = ET.fromstring(binary[pick("skeleton_xml")])
    atlas = ET.fromstring(binary[pick("texture_xml")].decode("utf-8"))
    image = Image.open(io.BytesIO(bitmaps[pick("texture_png")])).convert("RGBA")
    return skeleton, atlas, image


class Renderer:
    def __init__(self):
        skeleton, atlas, self.texture = embedded()
        self.armatures = {a.get("name"): a for a in skeleton.iter("armature")}
        self.subtextures = {s.get("name"): s for s in atlas.iter("SubTexture")}

    @staticmethod
    def matrix(t):
        if t is None:
            return np.eye(3)
        get = lambda k, d: float(t.get(k, d))
        kx, ky = math.radians(get("skX", 0)), math.radians(get("skY", 0))
        sx, sy = get("scX", 1), get("scY", 1)
        return np.array([[sx * math.cos(ky), -sy * math.sin(kx), get("x", 0)],
                         [sx * math.sin(ky), sy * math.cos(kx), get("y", 0)], [0, 0, 1]])

    @staticmethod
    def blend(a, b, f):
        out = {}
        for k in ("x", "y", "skX", "skY", "scX", "scY"):
            d = 1 if k.startswith("sc") else 0
            va, vb = float(a.get(k, d)), float(b.get(k, d)) if b is not None else float(a.get(k, d))
            if k.startswith("sk"):
                vb = va + ((vb - va + 180) % 360 - 180)
            out[k] = va + (vb - va) * f
        return out

    def pose(self, animation, frac):
        poses = {}
        if animation is None:
            return poses
        t = frac * float(animation.get("duration", 1))
        for timeline in animation.findall("timeline"):
            frames, start = timeline.findall("frame"), 0.0
            for i, frame in enumerate(frames):
                length = float(frame.get("duration", 1))
                if t < start + length or i == len(frames) - 1:
                    nxt = frames[i + 1] if i + 1 < len(frames) else None
                    f = min(1, max(0, (t - start) / length)) if length else 0
                    if frame.get("tweenEasing") == "NaN" or nxt is None or nxt.find("transform") is None:
                        f = 0
                    tr = frame.find("transform")
                    pose = self.blend(tr, nxt.find("transform") if nxt is not None else None, f) if tr is not None else None
                    alpha = lambda node: float(node.find("colorTransform").get("aM", 100)) / 100 \
                        if node is not None and node.find("colorTransform") is not None else 1
                    a = alpha(frame) + ((alpha(nxt) - alpha(frame)) * f if nxt is not None else 0)
                    poses[timeline.get("name")] = (pose, a, int(frame.get("displayIndex", 0)))
                    break
                start += length
        return poses

    def draw(self, canvas, name, world, frac, alpha=1.0, depth=0):
        armature = self.armatures.get(name)
        if armature is None or depth > 4:
            return
        animation = armature.find("animation")
        poses = self.pose(animation, frac)
        bones = {b.get("name"): b for b in armature.findall("bone")}
        cache = {}

        def bone_world(bone):
            if bone not in cache:
                node = bones[bone]
                pose = poses.get(bone)
                local = self.matrix(pose[0] if pose and pose[0] else None) if pose and pose[0] else self.matrix(node.find("transform"))
                cache[bone] = (bone_world(node.get("parent")) if node.get("parent") else np.eye(3)) @ local
            return cache[bone]

        timelines = {tl.get("name") for tl in animation.findall("timeline")} if animation is not None else set()
        for slot in sorted(armature.find("skin").findall("slot"), key=lambda s: float(s.get("z", 0))):
            bone = slot.get("parent")
            pose = poses.get(bone)
            if pose is None and bone in timelines:
                continue
            a = alpha * (pose[1] if pose else 1)
            index = pose[2] if pose else 0
            displays = slot.findall("display")
            if index < 0 or index >= len(displays) or a <= 0.01:
                continue
            display = displays[index]
            local = display.find("transform")
            transform = world @ bone_world(bone) @ self.matrix(local)
            if display.get("type") == "armature":
                self.draw(canvas, display.get("name"), transform, frac, a, depth + 1)
                continue
            sub = self.subtextures.get(display.get("name"))
            if sub is None:
                continue
            x, y, w, h = (int(float(sub.get(k))) for k in ("x", "y", "width", "height"))
            image = self.texture.crop((x, y, x + w, y + h))
            px = float(local.get("pX", 0)) if local is not None else 0
            py = float(local.get("pY", 0)) if local is not None else 0
            inverse = np.linalg.inv(transform @ np.array([[1, 0, -px], [0, 1, -py], [0, 0, 1]]))
            if a < 1:
                pixels = np.array(image)
                pixels[..., 3] = (pixels[..., 3] * a).astype("uint8")
                image = Image.fromarray(pixels)
            canvas.alpha_composite(image.transform(canvas.size, Image.AFFINE, tuple(inverse[:2].flatten()),
                                                   resample=Image.BILINEAR))

    def sheet(self, names, out, cell=200, scale=0.6, fracs=(0.1, 0.35, 0.6, 0.85)):
        label = 64
        sheet = Image.new("RGBA", (label + cell * len(fracs), cell * len(names)), (28, 30, 40, 255))
        pen = ImageDraw.Draw(sheet)
        for row, name in enumerate(names):
            pen.text((6, row * cell + cell // 2 - 6), name, fill=(255, 220, 0, 255))
            for col, frac in enumerate(fracs):
                canvas = Image.new("RGBA", (cell, cell), (0, 0, 0, 0))
                self.draw(canvas, "effect/" + name, np.array([[scale, 0, cell / 2], [0, scale, cell / 2], [0, 0, 1]]), frac)
                sheet.alpha_composite(canvas, (label + col * cell, row * cell))
                pen.rectangle([label + col * cell, row * cell, label + (col + 1) * cell - 1, (row + 1) * cell - 1],
                              outline=(70, 70, 90, 255))
        sheet.convert("RGB").save(out, optimize=True)


def idle(renderer):
    effects = json.loads((ROOT / "config/reconstruction/full-config.json").read_text("utf-8"))["cfg"]["effect"]
    sys.path.insert(0, str(ROOT / "server"))
    from battle_status_effects import STATUS_EFFECTS
    from native_fx_wiring_106 import DERIVED_FX, MISSING_FX, NATIVE_FX, SELF_FX
    used = set(re.findall(r'"(e\d{3})"', json.dumps([effects, STATUS_EFFECTS, NATIVE_FX, MISSING_FX, DERIVED_FX, SELF_FX])))
    code = "\n".join(p.read_text("utf-8") for p in (ROOT / "client/src").rglob("*.as*"))
    used |= set(re.findall(r'"(e\d{3})"', code))
    return sorted(n.split("/")[1] for n in renderer.armatures if n.startswith("effect/") and n.split("/")[1] not in used)


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("out", type=Path)
    parser.add_argument("names", nargs="?", default="", help="comma separated eNNN ids")
    parser.add_argument("--idle", action="store_true", help="render every armature nothing references")
    parser.add_argument("--cell", type=int, default=200)
    args = parser.parse_args(argv)
    renderer = Renderer()
    names = idle(renderer) if args.idle else [n for n in args.names.split(",") if n]
    renderer.sheet(names, args.out, cell=args.cell)
    print(f"{len(names)} armatures -> {args.out}: {', '.join(names)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
