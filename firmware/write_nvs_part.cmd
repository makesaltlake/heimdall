@echo off
if not exist "bin\heimdall-1.bin" (
  echo bin\heimdall-1.bin doesn't exist: please run gen_nvs_part.cmd
) else (
  if "%IDF_PATH%"=="" (
    echo IDF_PATH is not set: please run export.sh from ESP-IDF.
  ) else (
    python %IDF_PATH%\components\partition_table\parttool.py write_partition --partition-name nvs --input bin/heimdall-1.bin
  )
)