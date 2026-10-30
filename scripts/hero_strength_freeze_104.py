"""Validate an immutable implementation snapshot before reusing battle caches."""
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def freeze_study(output, encoded, root=ROOT):
    output, root = Path(output), Path(root)
    files = {}
    for folder, pattern in (('server', '*.py'), ('scripts', '*.py'), ('scripts', '*.js'),
                            ('client/src/stages', '*.as'), ('client/src', '*.aspart')):
        for path in sorted((root / folder).glob(pattern)):
            files[path.relative_to(root).as_posix()] = path.read_bytes()
    for relative in ('config/reconstruction/hero-balance-iteration-1.0.4.json',
                     'config/reconstruction/hero-strength-study-policy.json'):
        path = root / relative
        if path.exists(): files[relative] = path.read_bytes()
    manifest = {name: hashlib.sha256(data).hexdigest() for name, data in files.items()}
    manifest['frozen-config.json'] = hashlib.sha256(encoded).hexdigest()
    config, saved = output / 'frozen-config.json', output / 'manifest.json'
    if config.exists() and config.read_bytes() != encoded:
        raise RuntimeError('Frozen config changed; choose a new output directory')
    if saved.exists():
        if json.loads(saved.read_text('utf8')) != manifest:
            raise RuntimeError('Frozen source hashes changed; choose a new output directory')
        if not config.exists(): raise RuntimeError('Frozen config is missing')
        for name, data in files.items():
            path = output / 'sources' / name
            if not path.exists() or path.read_bytes() != data:
                raise RuntimeError('Frozen source snapshot is missing or modified: ' + name)
        return config
    if any((output / 'battles').glob('*')):
        raise RuntimeError('Cannot reuse battles without a frozen source manifest')
    output.mkdir(parents=True, exist_ok=True)
    config.write_bytes(encoded)
    for name, data in files.items():
        path = output / 'sources' / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(data)
    saved.write_text(json.dumps(manifest, indent=2), encoding='utf8')
    return config
