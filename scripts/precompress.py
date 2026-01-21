#!/usr/bin/env python3
"""
Precompress files in a directory for production serving.
Generates .gz (gzip) and .br (brotli, if brotli package is installed) alongside original files.
Usage:
  python scripts/precompress.py build/web

The script prints original and compressed sizes in bytes.
"""
import sys
import os
import gzip
import shutil
from pathlib import Path

try:
    import brotli
    HAS_BROTLI = True
except Exception:
    HAS_BROTLI = False

EXTS = ('.js', '.css', '.html', '.json', '.wasm')


def gz_compress(src_path: Path, level: int = 9):
    gz_path = src_path.with_suffix(src_path.suffix + '.gz')
    with src_path.open('rb') as f_in, gzip.open(gz_path, 'wb', compresslevel=level) as f_out:
        shutil.copyfileobj(f_in, f_out)
    return gz_path


def br_compress(src_path: Path, quality: int = 11):
    if not HAS_BROTLI:
        return None
    br_path = src_path.with_suffix(src_path.suffix + '.br')
    data = src_path.read_bytes()
    br_data = brotli.compress(data, quality=quality)
    br_path.write_bytes(br_data)
    return br_path


def human(n):
    for u in ['B','KB','MB','GB']:
        if n < 1024.0:
            return f"{n:.1f}{u}"
        n /= 1024.0
    return f"{n:.1f}TB"


def main():
    if len(sys.argv) < 2:
        print('Usage: python scripts/precompress.py <directory>')
        sys.exit(2)
    base = Path(sys.argv[1])
    if not base.exists() or not base.is_dir():
        print('Directory not found:', base)
        sys.exit(2)

    print('Precompressing files in', base)
    print('Brotli available:', HAS_BROTLI)
    rows = []
    for p in sorted(base.rglob('*')):
        if p.is_file() and p.suffix in EXTS:
            orig = p.stat().st_size
            gz = gz_compress(p)
            gz_size = gz.stat().st_size
            br_path = br_compress(p)
            br_size = br_path.stat().st_size if br_path is not None else None
            rows.append((str(p.relative_to(base)), orig, gz_size, br_size))
            print(f"{p.relative_to(base):60}  {human(orig):>8}  gz: {human(gz_size):>8}" + (f"  br: {human(br_size):>8}" if br_size is not None else ''))

    print('\nDone. To serve precompressed files, configure your web server (nginx/Apache) to prefer .br/.gz responses.')

if __name__ == '__main__':
    main()

