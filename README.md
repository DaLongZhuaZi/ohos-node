<div align="center">
<p>English | <a href="README.zh-CN.md">简体中文</a></p>
</div>

# ohos-node

This project build Node.js for the OpenHarmony platform and releases pre-built packages.

## Get Pre-built Packages

Pre-built packages are available from two sources:

**1. [GitHub Releases](https://github.com/hqzing/ohos-node/releases)**

**2. [Dist source](https://ohos-node.com/dist)** — a self-hosted Node.js dist source compatible with [nodejs.org/dist](https://nodejs.org/dist).

## Usage

**1. Manual install**

Extract the tarball and add the `bin` directory to `PATH`:

```sh
tar -zxf node-v24.2.0-openharmony-arm64.tar.gz
export PATH=$PATH:$(realpath node-v24.2.0-openharmony-arm64/bin)

# You can now use the 'node' command.
```

**2. Install via nvm / fnm** (under adaptation, coming soon)

Support is under adaptation — a few patches are still needed before nvm / fnm can install from the dist source.

The intended usage:

```sh
# nvm
NVM_NODEJS_ORG_MIRROR=https://ohos-node.com/dist nvm install v24.2.0
# or persist it:
nvm set node_mirror https://ohos-node.com/dist

# fnm
FNM_NODE_DIST_MIRROR=https://ohos-node.com/dist fnm install 24
```

## Build from Source

**1. Manual Build**

You need a Linux x64 host to cross-compile Node.js with the supplied `build.sh`.

Example on Ubuntu 24.04 x64:
```sh
sudo apt update && sudo apt install -y build-essential unzip jq
./build.sh v24.2.0
```

**2. CI Build**

If you are familiar with GitHub Actions, reuse the workflow file in this repo to build on GitHub’s runners, and no local environment required.

Steps for your own builds:
1. Fork this repo.
2. Enable workflow under the “Actions” tab.
3. Push commits or create a release to trigger the workflow.
