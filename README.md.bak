# Android sqlite3

这个项目用于从 SQLite 官方源码自动编译 Android 可用的 `sqlite3`
命令行工具。

项目不维护修改版 SQLite 源码。每次构建都会从 SQLite 官方网站下载指定版本的
amalgamation 源码包，校验官方 SHA3-256，再使用 Android NDK 编译生成 Android
ELF 可执行文件。

## 当前版本

| 项目 | 值 |
| --- | --- |
| SQLite | `3.53.1` |
| SQLite version number | `3530100` |
| 官方源码年份目录 | `2026` |
| Android min API | `23` |
| NDK | GitHub Actions 使用 `29.0.14206865` |

版本信息固定在 [sqlite-version.env](sqlite-version.env)。

## 构建产物

默认构建以下 ABI：

| ABI | 适用场景 |
| --- | --- |
| `arm64-v8a` | 大多数现代 Android 手机 |
| `armeabi-v7a` | 旧 32 位 ARM 设备 |
| `x86_64` | Android 模拟器或 x86_64 设备 |

构建完成后会生成：

```text
dist/sqlite3-android-3.53.1.zip
```

压缩包结构：

```text
arm64-v8a/sqlite3
armeabi-v7a/sqlite3
x86_64/sqlite3
```

## 快速使用

大多数手机使用 `arm64-v8a`：

```sh
adb push dist/arm64-v8a/sqlite3 /data/local/tmp/sqlite3
adb shell chmod 755 /data/local/tmp/sqlite3
adb shell /data/local/tmp/sqlite3 --version
```

打开数据库：

```sh
adb shell /data/local/tmp/sqlite3 /sdcard/Download/test.db
```

执行 SQL：

```sh
adb shell '/data/local/tmp/sqlite3 /sdcard/Download/test.db "select sqlite_version();"'
```

## Root 设备用法

如果设备有 root 权限，可以用它查看 App 私有目录下的数据库：

```sh
adb shell su -c '/data/local/tmp/sqlite3 /data/data/<package>/databases/<db-name> ".tables"'
```

执行查询：

```sh
adb shell su -c '/data/local/tmp/sqlite3 /data/data/<package>/databases/<db-name> "select * from sqlite_master;"'
```

建议先复制数据库再分析，避免直接修改 App 正在使用的数据库：

```sh
adb shell su -c 'cp /data/data/<package>/databases/<db-name> /data/local/tmp/app.db'
adb shell su -c 'chmod 644 /data/local/tmp/app.db'
adb pull /data/local/tmp/app.db .
```

## 本地构建

需要安装 Android NDK，并设置 `ANDROID_NDK_HOME` 或 `ANDROID_NDK_ROOT`：

```sh
export ANDROID_NDK_HOME=/path/to/android-ndk
scripts/download_sqlite.sh
scripts/build_android.sh
```

也可以指定 Android API level：

```sh
API_LEVEL=23 scripts/build_android.sh
```

脚本会：

1. 从 `sqlite-version.env` 读取版本信息。
2. 从 SQLite 官方网站下载 `sqlite-amalgamation-<version>.zip`。
3. 使用 `openssl dgst -sha3-256` 校验官方 SHA3-256。
4. 编译 `arm64-v8a`、`armeabi-v7a`、`x86_64` 三个 ABI。
5. 打包为 `dist/sqlite3-android-<version>.zip`。

## GitHub Actions

工作流文件在 [.github/workflows/build-android.yml](.github/workflows/build-android.yml)。

触发方式：

| 触发 | 行为 |
| --- | --- |
| push 到 `main` | 编译并上传 artifact |
| pull request | 编译校验 |
| workflow dispatch | 手动编译 |
| push tag `v*` | 编译并发布 GitHub Release |

发布版本示例：

```sh
git tag v3.53.1
git push origin v3.53.1
```

Action 会把 `dist/sqlite3-android-*.zip` 上传到对应 Release。

## 更新 SQLite

升级到新 SQLite 版本时，只需要改 [sqlite-version.env](sqlite-version.env)：

```sh
SQLITE_VERSION=3.x.y
SQLITE_VERSION_NUMBER=3xxyy00
SQLITE_YEAR=20xx
SQLITE_AMALGAMATION_SHA3_256=<official-sha3-256>
```

然后本地验证：

```sh
scripts/download_sqlite.sh
scripts/build_android.sh
```

确认无误后提交并打 tag。

## 已启用能力

构建脚本启用了常用 SQLite shell 能力：

```text
SQLITE_THREADSAFE=1
SQLITE_ENABLE_COLUMN_METADATA
SQLITE_ENABLE_DBSTAT_VTAB
SQLITE_ENABLE_EXPLAIN_COMMENTS
SQLITE_ENABLE_FTS4
SQLITE_ENABLE_FTS5
SQLITE_ENABLE_MATH_FUNCTIONS
SQLITE_ENABLE_RTREE
SQLITE_ENABLE_UNLOCK_NOTIFY
SQLITE_HAVE_ZLIB=1
```

`HAVE_READLINE=0`，因此 Android 上不依赖 readline。

## 真机测试

当前版本已在一台 `arm64-v8a` Android 设备上测试通过：

```text
sqlite3 --version
3.53.1 2026-05-05 10:34:17 c88b22011a54b4f6fbd149e9f8e4de77658ce58143a1af0e3785e4e6475127e9 (64-bit)
```

测试覆盖：

```text
普通 shell 执行
root shell 执行
建表
插入
查询
FTS5
JSON 函数
zlib
```

## 常见问题

### Android 系统不是自带 sqlite3 吗？

很多 Android 版本和厂商 ROM 不再默认提供 `sqlite3` 命令。这个项目提供的是一个
可以通过 `adb push` 放到设备上直接运行的命令行工具。

### 应该用哪个 ABI？

先查看设备 ABI：

```sh
adb shell getprop ro.product.cpu.abi
```

如果输出是 `arm64-v8a`，就使用：

```text
dist/arm64-v8a/sqlite3
```

### 可以直接修改 App 数据库吗？

技术上可以，但不建议直接修改正在被 App 使用的数据库。更稳妥的方式是先复制出来，
分析确认后再决定是否写回。

### 为什么不把 SQLite 源码直接提交到仓库？

这个项目的目标是保持源码可追溯和可验证。通过固定官方版本和 SHA3-256，构建时
从官方源下载并校验，可以避免手动同步源码导致的偏差。

## 官方来源

- SQLite download page: <https://www.sqlite.org/download.html>
- SQLite source tree: <https://www.sqlite.org/src>

