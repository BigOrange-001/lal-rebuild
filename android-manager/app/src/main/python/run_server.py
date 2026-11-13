"""Chaquopy entry point: hand control to the manager bridge after preparing it.

Kept separate from ``manager_bridge`` so the Chaquopy module the Java side
starts by name stays a one-liner; the bridge itself stays importable without
side effects.
"""
from __future__ import annotations


def main(runtime_dir: str, host: str, port: int, database: str, config: str) -> None:
    import manager_bridge

    manager_bridge.run(runtime_dir, host, port, database, config)
