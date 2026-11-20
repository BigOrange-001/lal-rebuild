"""Built-in four-frame texture for Shyvana's dragon form."""

import hashlib
import json
from pathlib import Path


MEDIA = Path(__file__).resolve().parents[1] / 'config/reconstruction/shyvana-dragon-media'


def apply_dragon_media(document):
    cfg = document['cfg']
    media = json.loads((MEDIA / 'manifest.json').read_text('utf-8'))
    cfg['shyvana_dragon_media_105'] = media
    cfg['builtin_assets_104']['assets'].extend(media['assets'])
    cfg.setdefault('mod_runtime', {}).setdefault('assets', []).extend(media['assets'])


def builtin_asset(cfg, digest, path):
    media = cfg.get('shyvana_dragon_media_105', {})
    if digest != media.get('digest'):
        return None
    entry = next((row for row in media['assets'] if row['path'] == path), None)
    if entry is None:
        raise ValueError('Unknown Shyvana dragon asset')
    file = (MEDIA / path).resolve()
    if not file.is_relative_to(MEDIA):
        raise ValueError('Invalid Shyvana dragon asset path')
    data = file.read_bytes()
    if hashlib.sha256(data).hexdigest() != entry['sha256']:
        raise ValueError('Shyvana dragon asset hash mismatch')
    return data, 'image/png'
