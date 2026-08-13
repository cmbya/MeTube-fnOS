#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TAG="${1:?用法: scripts/build_fpk.sh 2026.08.04}"
PACK_REV="$(tr -d '[:space:]' < "$ROOT/PACK_REV")"
VERSION="${TAG#v}"
BUILD="$ROOT/.build"; PKG="$BUILD/package"; DIST="$ROOT/dist"
FFMPEG_PYTHON="${FFMPEG_PYTHON:-python3}"
rm -rf "$BUILD"; mkdir -p "$PKG" "$DIST"; cp -a "$ROOT/package-template/." "$PKG/"
python3 - "$PKG" "$VERSION" "$PACK_REV" <<'PY2'
from pathlib import Path
import re,sys
pkg=Path(sys.argv[1]); version=sys.argv[2]; pack_rev=sys.argv[3]
p=pkg/'manifest'; s=p.read_text(encoding='utf-8')
s=re.sub(r'^version=.*$',f'version={version}-{pack_rev}',s,flags=re.M)
s=re.sub(r'^desc=.*$',f'desc=MeTube {version} x86 原生飞牛版。无需 Docker；FPK 内置静态 FFmpeg，自备 Python 3.13、官方 Node.js 22、yt-dlp、Deno 并构建 WebUI。',s,flags=re.M)
s=re.sub(r'^changelog=.*$',f'changelog={pack_rev}：跟随 MeTube 上游 {version}；支持 fnOS 授权目录作为下载根目录（优先第一个可写授权目录，无授权时回退 metube/downloads）；GitHub Actions 构建阶段将经过 SHA256 校验的 FFmpeg 7.0.2-static 直接打入 FPK。',s,flags=re.M)
s=re.sub(r'^checksum=.*$','checksum=PLACEHOLDER',s,flags=re.M); p.write_text(s,encoding='utf-8')
for rel in ('cmd/install_callback','cmd/upgrade_callback'):
    p=pkg/rel; s=p.read_text(encoding='utf-8'); s=re.sub(r'--version\s+"[^"]+"',f'--version "{version}"',s); p.write_text(s,encoding='utf-8')
p=pkg/'cmd/main'; s=p.read_text(encoding='utf-8'); s=re.sub(r'^export METUBE_VERSION="[^"]*"$',f'export METUBE_VERSION="{version}"',s,flags=re.M); p.write_text(s,encoding='utf-8')
PY2
"$FFMPEG_PYTHON" "$ROOT/scripts/prepare_ffmpeg.py" "$PKG/app/native/vendor/ffmpeg"
test -x "$PKG/app/native/vendor/ffmpeg"; "$PKG/app/native/vendor/ffmpeg" -version | head -n1
tar -czf "$PKG/app.tgz" -C "$PKG/app" .; rm -rf "$PKG/app"
MD5="$(md5sum "$PKG/app.tgz" | awk '{print $1}')"
python3 - "$PKG/manifest" "$MD5" <<'PY2'
from pathlib import Path
import re,sys
p=Path(sys.argv[1]); s=p.read_text(encoding='utf-8'); s=re.sub(r'^checksum=.*$',f'checksum={sys.argv[2]}',s,flags=re.M); p.write_text(s,encoding='utf-8')
PY2
OUT="$DIST/MeTube_${VERSION}_${PACK_REV}_fnOS_x86.fpk"
(cd "$PKG" && tar -czf "$OUT" manifest ICON.PNG ICON_256.PNG LICENSE app.tgz config cmd wizard)
VERIFY="$BUILD/verify"; rm -rf "$VERIFY"; mkdir -p "$VERIFY"; tar -xzf "$OUT" -C "$VERIFY"
python3 - "$VERIFY" <<'PY2'
from pathlib import Path
import hashlib,re,sys,tarfile
root=Path(sys.argv[1]); manifest=(root/'manifest').read_text(encoding='utf-8')
def get(k):
    m=re.search(rf'^{re.escape(k)}=(.*)$',manifest,re.M)
    if not m: raise SystemExit(f'manifest 缺少 {k}')
    return m.group(1).strip()
if get('appname')!='metube': raise SystemExit('appname 不是 metube')
if get('platform')!='x86': raise SystemExit('platform 不是 x86')
if get('service_port')!='8081': raise SystemExit('service_port 不是 8081')
if get('disable_authorization_path')!='false': raise SystemExit('未开启 fnOS 授权目录设置')
main_text=(root/'cmd/main').read_text(encoding='utf-8')
if 'TRIM_DATA_ACCESSIBLE_PATHS' not in main_text: raise SystemExit('cmd/main 未读取 TRIM_DATA_ACCESSIBLE_PATHS')
if 'AUTHORIZED_DOWNLOAD_DIR' not in main_text: raise SystemExit('cmd/main 缺少授权下载目录逻辑')
app_tgz=root/'app.tgz'; actual_md5=hashlib.md5(app_tgz.read_bytes()).hexdigest()
if actual_md5!=get('checksum'): raise SystemExit('app.tgz checksum 不一致')
expected='e7e7fb30477f717e6f55f9180a70386c62677ef8a4d4d1a5d948f4098aa3eb99'
with tarfile.open(app_tgz,'r:gz') as tf:
    names={m.name.lstrip('./'):m for m in tf.getmembers()}
    for req in ('native/bootstrap.py','ui/config','native/vendor/ffmpeg'):
        if req not in names: raise SystemExit(f'app.tgz 缺少 {req}')
    f=tf.extractfile(names['native/vendor/ffmpeg']); h=hashlib.sha256()
    for b in iter(lambda:f.read(1024*1024),b''): h.update(b)
    actual=h.hexdigest()
if actual!=expected: raise SystemExit(f'FPK 内 FFmpeg SHA256 不正确: {actual}')
print('FPK 静态校验通过'); print('FPK 内 FFmpeg SHA256:',actual)
PY2
(cd "$DIST" && sha256sum "$(basename "$OUT")" > SHA256SUMS.txt)
echo "构建完成: $OUT"; ls -lh "$OUT"; cat "$DIST/SHA256SUMS.txt"
