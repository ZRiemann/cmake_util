#!/bin/bash

# 定义颜色变量
RED='\033[0;31m'
BOLD_RED='\033[1;31m'
# 绿色系列变量
GREEN='\033[0;32m'          # 普通绿色
BOLD_GREEN='\033[1;32m'     # 粗体绿色
LIGHT_GREEN='\033[0;92m'    # 亮绿色
DARK_GREEN='\033[2;32m'     # 暗绿色
BG_GREEN='\033[42m'         # 绿色背景
BG_LIGHT_GREEN='\033[102m'  # 亮绿色背景

NC='\033[0m' # No Color (重置颜色)

# Fast compile cmake projects
# 如果 PATH 未设置，使用默认值
if [ -n "${SOCKS5_ADDR}" ]; then
    export ALL_PROXY=${SOCKS5_ADDR}
    echo -e "${BOLD_GREEN}ALL_PROXY=${ALL_PROXY}${NC}"
else
    echo -e "${BOLD_RED}NOT SET ALL_PROXY, may be down resource slowly${NC}"
fi

DIR=build
if [ "$1" == "d" ]; then
    DIR=build_debug
fi

if [ "$2" == "r" ] && [ -d "${DIR}" ]; then
    mv $DIR $DIR.old
    echo "remove $DIR"
    rm -fr $DIR
    mkdir $DIR
    mv $DIR.old/_deps $DIR
    mv $DIR.old/cmake $DIR
    rm -fr $DIR.old
fi

if [ -d "$DIR" ]; then
    echo $DIR is a directory.
else
    mkdir $DIR
fi

cd $DIR

UBTV=$(lsb_release -r)
echo "ubuntu version: ${UBTV:0-5}"

if [ "$1" == "d" ]; then
    echo "build Debug mode"
    cmake -DCMAKE_BUILD_TYPE=Debug ..
elif [ "$1" == "r" ]; then
    echo "build Release mode"
    cmake -DCMAKE_BUILD_TYPE=Release ..
fi

if [ "$3" == "v" ]; then
    # 显示编译选项
    cmake --build . -v -- -j$(nproc)
else
    cmake --build . -- -j$(nproc)
fi

if [ "$?" == "0" ]; then
    echo "buile ok"
else
    echo "Build failed!"
    exit 1
fi

if [[ $1 == run_* ]]; then
    echo "execute target ${1}..."
    cmake --build . --target ${1}
elif [ "$1" == "i" ]; then
    echo "install target..."
else
    echo "parame 1: ${1}"
fi
exit 0