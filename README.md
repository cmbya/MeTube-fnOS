# MeTube-fnOS

MeTube 的 fnOS x86 原生自动构建仓库。

每天检查一次 `alexta69/metube` 的最新 `YYYY.MM.DD` 标签。发现新版后自动生成 FPK 并创建 Pre-release。

## FFmpeg

FFmpeg **不是在 fnOS 安装时下载**。GitHub Actions 构建 FPK 时使用 `imageio-ffmpeg==0.6.0` 取得已验证的 `FFmpeg 7.0.2-static / Linux x86_64`，校验 SHA256 后写入 `app/native/vendor/ffmpeg`，然后才生成 `app.tgz`。构建结束后还会再次解包校验。

预期 SHA256：

`e7e7fb30477f717e6f55f9180a70386c62677ef8a4d4d1a5d948f4098aa3eb99`

仓库里故意不保存 77MB 的 FFmpeg 二进制，避免 GitHub 网页上传限制；最终 Release 里的 `.fpk` 会包含 FFmpeg。

`PACK_REV` 当前为 `native1`，它以已验证的 native6 方案为稳定基线重新编号。
