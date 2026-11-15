"""Splice the Abyss Corridor client screens into their host class and refresh build pins.

FFDec only replaces existing classes, so the screens in client/src/abyss_ui_104.aspart
are file-private classes appended after the package block of PanelActivityExploration.
Run after editing the aspart or any stage file, then commit both.
"""
from pathlib import Path
import hashlib
import json
import subprocess

ROOT = Path(__file__).resolve().parents[1]
HOST = ROOT / 'client/src/stages/102_PanelActivityExploration.as'
PART = ROOT / 'client/src/abyss_ui_104.aspart'
CONFIG = ROOT / 'client/build.json'
BEGIN = '// BEGIN ABYSS_UI_104\n'
END = '// END ABYSS_UI_104\n'


def splice() -> None:
    text = HOST.read_text('utf-8-sig').replace('\r\n', '\n')
    if BEGIN in text:
        start = text.index(BEGIN)
        stop = text.index(END, start) + len(END)
        text = text[:start] + text[stop:]
    text = text.rstrip() + '\n'
    part = PART.read_text('utf-8-sig').replace('\r\n', '\n').rstrip() + '\n'
    art = ROOT / 'client/src/abyss_relic_art_104.aspart'
    if art.is_file():
        part += art.read_text('utf-8-sig').replace('\r\n', '\n').rstrip() + '\n'
    HOST.write_text(text + BEGIN + part + END, 'utf-8', newline='\n')


def refresh_hashes() -> None:
    config = json.loads(CONFIG.read_text('utf-8'))
    config['stage_count'] = len(config['stages'])
    config['unique_class_count'] = len({stage['class'] for stage in config['stages']})
    for stage in config['stages']:
        source = ROOT / stage['source']
        stage['source_sha256'] = hashlib.sha256(source.read_bytes()).hexdigest()
    raw = CONFIG.read_bytes()
    newline = '\r\n' if b'\r\n' in raw else '\n'
    out = json.dumps(config, ensure_ascii=False, indent=2) + '\n'
    CONFIG.write_bytes(out.replace('\n', newline).encode('utf-8'))


if __name__ == '__main__':
    splice()
    refresh_hashes()
