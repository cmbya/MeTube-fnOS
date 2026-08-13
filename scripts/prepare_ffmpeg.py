#!/usr/bin/env python3
import hashlib
import pathlib
import shutil
import subprocess
import sys

EXPECTED_SHA256 = "e7e7fb30477f717e6f55f9180a70386c62677ef8a4d4d1a5d948f4098aa3eb99"

def main():
    if len(sys.argv) != 2:
        raise SystemExit("用法: prepare_ffmpeg.py <目标路径>")

    dest = pathlib.Path(sys.argv[1])

    try:
        import imageio_ffmpeg
    except Exception as e:
        raise SystemExit(
            "缺少 imageio-ffmpeg。Workflow 应先安装 imageio-ffmpeg==0.6.0。"
        ) from e

    if imageio_ffmpeg.__version__ != "0.6.0":
        raise SystemExit(
            f"imageio-ffmpeg 版本不正确: {imageio_ffmpeg.__version__}"
        )

    src = pathlib.Path(imageio_ffmpeg.get_ffmpeg_exe())
    if not src.exists():
        raise SystemExit(f"找不到 FFmpeg: {src}")

    h = hashlib.sha256()
    with src.open("rb") as f:
        while True:
            chunk = f.read(1024 * 1024)
            if not chunk:
                break
            h.update(chunk)

    actual = h.hexdigest()

    if actual != EXPECTED_SHA256:
        raise SystemExit(
            "FFmpeg SHA256 不匹配\n"
            f"expected: {EXPECTED_SHA256}\n"
            f"actual:   {actual}"
        )

    dest.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(src, dest)
    dest.chmod(0o755)

    version_line = subprocess.check_output(
        [str(dest), "-version"],
        text=True
    ).splitlines()[0]

    if "7.0.2-static" not in version_line:
        raise SystemExit(
            f"FFmpeg 版本自检失败: {version_line}"
        )

    print(version_line)
    print("FFmpeg SHA256:", actual)
    print("FFmpeg 已写入:", dest)

if __name__ == "__main__":
    main()
