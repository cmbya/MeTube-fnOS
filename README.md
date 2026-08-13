# MeTube-fnOS

MeTube 的 fnOS x86 原生自动构建仓库。

## 自动更新

每天检查一次 `alexta69/metube` 最新 `YYYY.MM.DD` 标签，发现新版后自动构建 x86 原生 FPK 并发布 Pre-release。

## FFmpeg 必须内置

GitHub Actions 构建阶段会取得固定的 FFmpeg 7.0.2-static x86_64，校验 SHA256 后写入 `app/native/vendor/ffmpeg`。生成 FPK 后还会再次解开 `app.tgz` 校验 FFmpeg。

**飞牛安装 MeTube 时不会下载 FFmpeg。**

## 下载目录

当前 `native2` 支持飞牛授权目录：

1. 没有授权目录：下载到应用自动创建的 `metube/downloads`。
2. 在 fnOS「应用设置 → MeTube → 访问权限」授权一个读写目录：下次启动 MeTube 时使用**第一个可写授权目录**作为下载根目录。
3. 如果第一个授权目录不存在或不可写：自动回退到 `metube/downloads`，避免应用启动失败。

MeTube 的 `DOWNLOAD_DIR` 和 `AUDIO_DOWNLOAD_DIR` 都指向这个目录；临时目录为下载目录下的 `.metube-tmp`。应用状态仍保存在应用自己的持久化目录，不会混入视频目录。

**修改授权目录后请在应用中心停止并重新启动 MeTube。**

## 定时

每天北京时间大约 10:47 检查一次，也可以在 Actions 中手动 Run workflow。

## 飞牛封装版本

`PACK_REV` 当前为 `native2`。
