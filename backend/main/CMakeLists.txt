# Edit following two lines to set component requirements (see docs)
set(COMPONENT_REQUIRES )
set(COMPONENT_PRIV_REQUIRES )
#set(COMPONENT_PRIV_REQUIRES "fatfs" "json" "nvs_flash" "esp_http_client")

set(COMPONENT_SRCS "main.c" "iso14443.c" "mifare_classic.c" "clrc663.c" "network.c" "card_reader.c"
    EMBED_TXTFILES heimdall_makesaltlake_org_root_cert.pem heimdall_dev_root_cert.pem)
set(COMPONENT_ADD_INCLUDEDIRS "")

register_component()

target_compile_options(${COMPONENT_TARGET} PRIVATE -Wall -Wstrict-prototypes -DLOG_LOCAL_LEVEL=ESP_LOG_DEBUG)
