#!/usr/bin/env python3
import hashlib, pathlib, shutil, subprocess, sys
EXPECTED='e7e7fb30477f717e6f55f9180a70386c62677ef8a4d4d1a5d948f4098aa3eb99'
DEST=pathlib.Path(sys.argv[1])
try: import imageio_ffmpeg
except Exception as e: raise SystemExit('缺少 imageio-ffmpeg==0.6.0') from e
if imageio_ffmpeg.__version__!='0.6.0': raise SystemExit(f'imageio-ffmpeg 版本不正确: {imageio_ffmpeg.__version__}')
src=pathlib.Path(imageio_ffmpeg.get_ffmpeg_exe())
h=hashlib.sha256()
with src.open('rb') as f:
    for b in iter(lambda:f.read(1024*1024),b''): h.update(b)
actual=h.hexdigest()
if actual!=EXPECTED: raise SystemExit(f'FFmpeg SHA256 不匹配: expected={EXPECTED} actual={actual}')
DEST.parent.mkdir(parents=True,exist_ok=True); shutil.copy2(src,DEST); DEST.chmod(0o755)
out=subprocess.check_output([str(DEST),'-version'],text=True).splitlines()[0]
if '7.0.2-static' not in out: raise SystemExit('FFmpeg 版本自检失败: '+out)
print(out); print('FFmpeg SHA256:',actual); print('FFmpeg 已注入:',DEST)
