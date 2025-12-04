@echo off
if EXIST "csv\heimdall-1.csv" (
  del csv\heimdall-1.csv
)
if EXIST "bin\heimdall-1.bin" (
  del "bin\heimdall-1.bin"
)

if "%IDF_PATH%"=="" (
  echo IDF_PATH is not set: please run export.bat from ESP-IDF.
) else (
  python "%IDF_PATH%\tools\mass_mfg\mfg_gen.py" generate nvs_cfg.csv nvs_data.csv heimdall 0x6000
)