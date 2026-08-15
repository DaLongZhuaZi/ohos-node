#!/bin/sh
# ============================================================
# ohos-node build.sh 改造版：--shared 构建 libnode.so
# 变更点：
#   1. CONFIGURE_ARGS 增加 --shared（构建共享库 libnode.so）
#   2. 打包阶段额外产出 libnode-<version>-openharmony-arm64/：
#      lib/libnode.so + include/node 头文件（供嵌入编译使用）
# 用法：./build-shared.sh v26.7.0
# ============================================================
set -e

if [ -z "$1" ]; then
    echo "usage: ./build-shared.sh <branch name or tag name>"
    echo "example: ./build-shared.sh v26.7.0"
    exit 1
fi

version=$1
workdir=$(pwd)

query_component() {
  component=$1
  curl -fsSL 'https://dcp.openharmony.cn/api/daily_build/build/list/component' \
    -H 'Accept: application/json, text/plain, */*' \
    -H 'Content-Type: application/json' \
    --data-raw '{"projectName":"openharmony","branch":"master","pageNum":1,"pageSize":10,"deviceLevel":"","component":"'${component}'","type":1,"startTime":"2025080100000000","endTime":"20990101235959","sortType":"","sortField":"","hardwareBoard":"","buildStatus":"success","buildFailReason":"","withDomain":1}'
}

# clean old files if exist
rm -rf *.tar.gz \
  *.tar.xz \
  ohos-sdk \
  daily_build.log \
  manifest_tag.xml \
  llvm-19 \
  node \
  node-${version}-openharmony-arm64 \
  libnode-${version}-openharmony-arm64

# setup openharmony sdk
sdk_download_url=$(query_component "ohos-sdk-public" | jq -r ".data.list.dataList[0].obsPath")
curl $sdk_download_url -o ohos-sdk-public.tar.gz
tar -zxf ohos-sdk-public.tar.gz
rm -rf daily_build.log manifest_tag.xml ohos-sdk/windows ohos-sdk/ohos
cd ohos-sdk/linux
unzip -q toolchains-*.zip
rm -rf *.zip
cd ../..

# setup LLVM-19
llvm19_download_url=$(query_component "LLVM-19" | jq -r ".data.list.dataList[0].obsPath")
curl $llvm19_download_url -o LLVM-19.tar.gz
mkdir llvm-19
tar -zxf LLVM-19.tar.gz -C llvm-19
cd llvm-19
tar -zxf llvm-linux-x86_64.tar.gz
tar -zxf ohos-sysroot.tar.gz
cd ..

git clone --branch $version --depth 1 https://github.com/nodejs/node.git
cd node

export CC="$workdir/llvm-19/llvm/bin/aarch64-unknown-linux-ohos-clang"
export CXX="$workdir/llvm-19/llvm/bin/aarch64-unknown-linux-ohos-clang++"
export CC_host="gcc"
export CXX_host="g++"

need_patch_0001_versions="v24.2.0 v24.3.0 v24.4.0 v24.4.1 v24.5.0 v24.6.0"
if echo " $need_patch_0001_versions " | grep -q " $version "; then
    patch -p1 < ../0001-fix-argument-list-too-long.patch
fi

need_patch_0002_versions="^v22\\."
if echo "$version" | grep -q "$need_patch_0002_versions"; then
    patch -p1 < ../0002-use-C++20-for-Node.js-core.patch
fi

need_no_error_versions="v24.2.0 v24.3.0 v24.4.0 v24.4.1 v24.5.0 \
                        v24.6.0 v24.7.0 v24.8.0 v22.17.0 v22.17.1 \
                        v22.18.0 v22.19.0"
if echo " $need_no_error_versions " | grep -q " $version "; then
    export CC="$CC -Wno-error=implicit-function-declaration"
    export CXX="$CXX -Wno-error=implicit-function-declaration"
fi

# ★ 变更点 1：--shared 构建 libnode.so
CONFIGURE_ARGS="--dest-cpu=arm64 \
  --dest-os=openharmony \
  --cross-compiling \
  --shared \
  --prefix=$workdir/node-${version}-openharmony-arm64"

if ./configure --help 2>&1 | grep -q -- "--v8-disable-temporal-support"; then
    CONFIGURE_ARGS="$CONFIGURE_ARGS --v8-disable-temporal-support"
fi

./configure $CONFIGURE_ARGS
make -j$(nproc)
make install
cd ..

# code signing（保持原样：bin/node 独立签名）
$workdir/ohos-sdk/linux/toolchains/lib/binary-sign-tool sign \
  -inFile node-${version}-openharmony-arm64/bin/node \
  -outFile node-${version}-openharmony-arm64/bin/node \
  -selfSign 1

cp LICENSE node-${version}-openharmony-arm64
tar -zcf node-${version}-openharmony-arm64.tar.gz node-${version}-openharmony-arm64
tar -Jcf node-${version}-openharmony-arm64.tar.xz node-${version}-openharmony-arm64

# ★ 变更点 2：单独打包 libnode.so + 头文件（嵌入用）
mkdir -p libnode-${version}-openharmony-arm64/lib
cp -r node-${version}-openharmony-arm64/lib/libnode.so libnode-${version}-openharmony-arm64/lib/
cp -r node-${version}-openharmony-arm64/include libnode-${version}-openharmony-arm64/include
tar -zcf libnode-${version}-openharmony-arm64.tar.gz libnode-${version}-openharmony-arm64
echo "=========== SHARED BUILD DONE ==========="
ls -la libnode-${version}-openharmony-arm64/lib/
