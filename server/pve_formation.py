"""Shared native stage-row positioning for authored and generated PVE."""
from __future__ import annotations


def stagger_lane_offsets(team: list[list]) -> int:
    """Set row[11] to balanced fractions of native GameMapConfig.sideOffset."""
    lanes: dict[int, list[int]] = {}
    for index, row in enumerate(team):
        if len(row) < 5:
            raise ValueError("stage enemy row is missing native formation fields")
        lanes.setdefault(int(row[3]), []).append(index)
    changed = 0
    for members in lanes.values():
        members.sort(key=lambda index: (-float(team[index][4]), index))
        count = len(members)
        # The native fallback spaces n units at (i+1)/(n+1)-0.5. Take
        # opposite outside slots first so consecutive depths alternate left
        # and right, keeping every unit inside half of sideOffset.
        slots = [round((i + 1) / (count + 1) - .5, 4) for i in range(count)]
        outside_in = []
        left, right = 0, count - 1
        while left <= right:
            outside_in.append(slots[left])
            if left != right:
                outside_in.append(slots[right])
            left += 1
            right -= 1
        for index, side in zip(members, outside_in):
            row = team[index]
            if len(row) < 12:
                row.extend([None] * (12 - len(row)))
            if row[11] != side:
                row[11] = side
                changed += 1
    return changed
