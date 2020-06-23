#!/bin/sh
set -e

GEN_BIN_FILE=bin/heimdall-1.bin
[ ! -e $GEN_BIN_FILE ] && ./gen_nvs_part.sh
parttool.py write_partition --partition-name nvs --input bin/heimdall-1.bin
