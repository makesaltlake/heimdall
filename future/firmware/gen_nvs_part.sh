#!/bin/sh
set -e

GEN_CSV_FILE=csv/heimdall-1.csv
GEN_BIN_FILE=bin/heimdall-1.bin
[ -e $GEN_CSV_FILE ] && rm -v $GEN_CSV_FILE
[ -e $GEN_BIN_FILE ] && rm -v $GEN_BIN_FILE
python3 "$IDF_PATH/tools/mass_mfg/mfg_gen.py" generate nvs_cfg.csv nvs_data.csv heimdall 0x6000
