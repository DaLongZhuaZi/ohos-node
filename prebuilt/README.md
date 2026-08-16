# Prebuilt: Node.js / libnode v26.7.0 for OpenHarmony (arm64-v8a)

本目录存放由 GitHub Actions 交叉编译的 OpenHarmony arm64-v8a 预编译产物，
用于鸿蒙应用内嵌运行时（libnode.so 路线，详见 OHDSH 工作区
`docs/dsh-on-ohos-feasibility.md` 第 7 节）。

## 编译详情

| 项目 | 值 |
|---|---|
| 构建仓库 | DaLongZhuaZi/ohos-node（本仓库） |
| GitHub Actions run | **31876866333**（workflow_dispatch） |
| 触发时间 | 2026-08-15T09:23:25Z |
| 产物上传时间 | 2026-08-15T13:13:57Z |
| 构建耗时 | 3h50m35s（job: build-and-release，ID 94993800515） |
| 结果 | **SUCCESS** |
| 构建分支 | main @ 192a2c0（含 --shared 改造：`build: add --shared libnode.so build`、`ci: upload libnode artifact and release asset`、`ci: add workflow_dispatch with version input`、`build: copy libnode.so from build dir (make install does not install it)`） |
| Node.js 版本 | v26.7.0（官方源码 nodejs/node tag v26.7.0） |
| 目标平台 | OpenHarmony arm64-v8a（`--dest-os=openharmony --dest-cpu=arm64 --cross-compiling`） |
| 工具链 | LLVM-19（`aarch64-unknown-linux-ohos-clang`）+ OHOS SDK（`ohos-sdk-public`，linux toolchains）+ ohos-sysroot，ubuntu-latest runner |
| 关键配置 | `--shared`（构建 libnode.so）；`--v8-disable-temporal-support`（避免 Rust 环境导致的交叉编译失败） |
| 代码签名 | OHOS `binary-sign-tool sign -selfSign 1` |
| 产物来源 | GitHub artifact **9247426678**（`artifact`，保留至 2026-08-22，本目录为归档副本） |

## 产物清单（SHA-256 校验）

| 文件 | 大小 | SHA-256 |
|---|---|---|
| libnode-v26.7.0-openharmony-arm64.tar.gz | 56,183,703 | 8672EB89A2A2E11B738FA437AF1291C72DE69A502594FFFEE943DE2C8F6EF9B9 |
| node-v26.7.0-openharmony-arm64.tar.gz | 59,314,648 | D173F925DBEA848CD5D7CB80D1BA57F64B38C0595664F8C478C8FF2AF84A5E4A |
| node-v26.7.0-openharmony-arm64.tar.xz | 31,413,920 | 87968DA4D764F331C68415EAC62EDA64CC05F6423F85864760B5883EF7947669 |

## 内容说明

- **libnode-v26.7.0-openharmony-arm64.tar.gz**（56MB，3432 个条目）：
  嵌入式共享库包，仅含 `lib/libnode.so` 与 `include/node/` 头文件（含 openssl 头、config.gypi）。
  用途：`libnode.so` 放入应用 `libs/arm64-v8a/`（HAP 安装目录，系统认可的可执行映射位置），
  `include/node` 供 libdsh_host 等嵌入式启动器编译链接。
- **node-v26.7.0-openharmony-arm64.tar.gz / .tar.xz**：完整 Node.js 发行包
  （`bin/node` 127MB + npm/npx + lib/node_modules/npm + 头文件），两份为不同压缩格式。

## 产物验证（2026-08-16 本地复核）

对 `libnode.so`（解压后 148,933,000 字节）的 ELF 检查全部通过：

- ELF magic `\x7FELF`，`e_type=3`（ET_DYN 共享库）
- `e_machine=183` = **AArch64**（与目标真机 arm64-v8a 匹配）
- 关键符号 `_ZN4node5StartEiPPc`（`node::Start`）存在，未被 strip
  —— libdsh_host 可用 `dlsym("_ZN4node5StartEiPPc")` 拉起嵌入式 Node
- SONAME `libnode.so` 存在

## 使用方法（嵌入鸿蒙应用）

1. `libnode.so` → `<app>/libs/arm64-v8a/`（随 HAP 安装）
2. `include/node` → 编译 libdsh_host.cpp（CMake `target_link_libraries` + `target_include_directories`）
3. 启动链：`startNativeChildProcess("libdsh_host.so:Main")` → fork → 子进程
   `dlopen(libnode.so)` → `node::Start` 启动 DSH server（127.0.0.1）→ ArkWeb 渲染

## 注意事项

- 本机沙箱实测：`/dev/ptmx` 全上下文 EACCES（无 PTY）、应用数据目录 exec ELF 被禁（ENOEXEC），
  因此本产物仅用于 `.so` 嵌入路线，不可作为独立可执行文件直接 exec。
- artifact 于 2026-08-22 过期，本目录是长期归档；如需重新构建，注意
  build.sh 依赖 dcp.openharmony.cn 每日构建的 SDK/LLVM 下载地址（曾出现 404，需重试或修复）。
