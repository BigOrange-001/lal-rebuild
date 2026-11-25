"""Kai'Sa's missile preview now renders the real effect code with AIR.

The old HTML preview replayed kaisaProjectile104's tween; Icathian Rain is drawn by
client/src/kaisa_rain_fx_106.aspart since 1.0.6, so this entry point forwards to
scripts/kaisa_rain_fx_preview.py.
"""
import sys
from kaisa_rain_fx_preview import main

if __name__ == '__main__':
    sys.exit(main())
