"""Recompile only changed client classes on top of a previously compiled SWF.

A cold build replays all ~180 FFDec stages (about 50 minutes). When only a few
classes changed, start from the SWF a cold build kept with ``--keep-swf`` and
replay just the stages of changed classes, in build order. A class that fails
because it needs another changed class compiled first is retried after the
rest. The result is saved with a fresh manifest, so builds can chain.

Package the result with ``build_client.py --prebuilt-swf OUT.swf``. Run a cold
build before a release: incremental output is for iteration and review.

Example:
  python scripts/build_swf_incremental.py --base build/base.swf --output build/dev.swf \
      --ffdec ../toolchain/ffdec/ffdec-cli.jar --java ../toolchain/java/bin/java.exe
"""
from __future__ import annotations

import argparse
import json
import shutil
import sys
import tempfile
import time
from pathlib import Path

from build_client import (ROOT, checked_run, cli_command, compile_stage, java_major,
                          read_build_config, save_compiled_swf, sha256_file, source_manifest)

GLOBAL_FUNCTION = 'com.meng52.game.global.GlobalFunction'


def load_base(base: Path) -> dict:
    sidecar = base.with_name(base.name + '.sources.json')
    if not sidecar.is_file():
        raise SystemExit(f'Missing {sidecar.name}: run a cold build with --keep-swf first.')
    data = json.loads(sidecar.read_text('utf-8'))
    if data.get('schema') != 1 or data.get('swf_sha256') != sha256_file(base):
        raise SystemExit(f'{sidecar.name} does not describe {base.name}; run a cold build with --keep-swf.')
    return data['classes']


def changed_classes(stages: list[dict], base: dict) -> list[str]:
    current = source_manifest(stages)
    names = [name for name, row in current.items() if base.get(name, {}).get('digest') != row['digest']]
    first = {name: row['stages'][0] for name, row in current.items()}
    return sorted(names, key=lambda name: first[name])


def needs_scoped_ui_kit_repair(stages: list[dict], baseline: dict) -> bool:
    # Recompiling all of GlobalFunction against a final SWF can disturb startup.
    # Known bases used Flash types for both names, or already fixed Sprite.
    prior = baseline.get(GLOBAL_FUNCTION)
    if prior is None:
        return False
    global_stages = [stage for stage in stages if stage['class'] == GLOBAL_FUNCTION]
    event_only = {}
    sprite_and_event = {}
    for stage in global_stages:
        path = stage['source']
        source = (ROOT / path).read_bytes()
        begin, marker, rest = source.partition(b'// BEGIN UI KIT 105')
        kit, end, tail = rest.partition(b'// END UI KIT 105')
        if not marker or not end:
            return False
        old_event = kit.replace(b'starling.events.Event', b'Event')
        event_only[path] = begin + marker + old_event + end + tail
        sprite_and_event[path] = begin + marker + old_event.replace(
            b'starling.display.Sprite', b'Sprite') + end + tail
    return any(source_manifest(global_stages, source_overrides=overrides).get(GLOBAL_FUNCTION) == prior
               for overrides in (event_only, sprite_and_event))


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--base', type=Path, required=True, help='SWF saved by a previous build (with .sources.json)')
    parser.add_argument('--output', type=Path, required=True, help='Where to write the new SWF and manifest')
    parser.add_argument('--ffdec', type=Path, required=True, help='FFDec CLI jar or wrapper')
    parser.add_argument('--java', required=True, help='Java 17+ executable')
    parser.add_argument('--air-sdk', type=Path, help='AIR SDK for stages using mxmlc')
    parser.add_argument('--dry-run', action='store_true', help='Only list the classes that would be recompiled')
    args = parser.parse_args(argv)

    config = read_build_config()[0]
    stages = config['stages']
    base = args.base.expanduser().absolute()
    snapshot = source_manifest(stages)
    baseline = load_base(base)
    names = changed_classes(stages, baseline)
    scoped_ui_kit = GLOBAL_FUNCTION in names and needs_scoped_ui_kit_repair(stages, baseline)
    replay = {name: row['stages'] for name, row in snapshot.items()}
    by_index = {stage['index']: stage for stage in stages}
    print(f'{len(names)} changed class(es):', ', '.join(name.rsplit('.', 1)[-1] for name in names) or 'none', flush=True)
    if args.dry_run:
        return 0
    if not names:
        if base != args.output.expanduser().absolute():
            save_compiled_swf(base, args.output, stages, snapshot)
        print(f'No changes; copied {base.name}')
        return 0
    if java_major(args.java) < 17:
        raise SystemExit('Java 17 or newer is required')
    ffdec = args.ffdec.expanduser().absolute()
    ffdec_base = cli_command(ffdec, args.java)

    work = Path(tempfile.mkdtemp(prefix='lal-incremental-')).absolute()
    started = time.monotonic()
    try:
        current = work / 'base.swf'
        shutil.copy2(base, current)
        pending, step = list(names), 0
        if scoped_ui_kit:
            if ffdec.suffix.lower() != '.jar':
                raise SystemExit('The scoped UI kit repair requires the FFDec JAR')
            output = work / 'ui-kit.swf'
            print(checked_run([args.java, '-cp', str(ffdec), str(ROOT / 'scripts/FixUiSpriteTypes.java'),
                               str(current), str(output)], label='Scoped UI kit repair').strip(), flush=True)
            current = output
            pending.remove(GLOBAL_FUNCTION)
        while pending:
            failed: list[tuple[str, str]] = []
            for name in pending:
                try:
                    for index in replay[name]:
                        step += 1
                        output = work / f'step-{step:03d}.swf'
                        print(f'[{step}] FFDec stage {index} {name}', flush=True)
                        compile_stage(ffdec_base, ffdec, args.java, current, output, by_index[index], args.air_sdk)
                        current = output
                except RuntimeError as error:
                    failed.append((name, str(error)))
            if len(failed) == len(pending):
                for name, error in failed:
                    print(f'FAILED {name}:\n{error[-4000:]}', file=sys.stderr)
                return 1
            pending = [name for name, _ in failed]
            if pending:
                print('Retrying after dependencies:', ', '.join(n.rsplit('.', 1)[-1] for n in pending), flush=True)
        sidecar = save_compiled_swf(current, args.output, stages, snapshot)
    finally:
        shutil.rmtree(work, ignore_errors=True)
    print(f'Wrote {args.output} ({sha256_file(args.output.expanduser().absolute())[:16]}) and {sidecar.name}')
    print(f'Recompiled {len(names)} class(es) in {time.monotonic() - started:.0f}s')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
