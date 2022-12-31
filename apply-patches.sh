#!/bin/bash

SHELL_DIR=$(cd "$(dirname "$0")"; pwd)

echo "Applying patches... "
cd board/pine64/ox64/bl808_linux
git apply ${SHELL_DIR}/patches/*.patch 

