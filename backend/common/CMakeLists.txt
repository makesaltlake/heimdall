# Edit following two lines to set component requirements (see docs)
set(COMPONENT_REQUIRES "json" "esp_http_client" "esp_websocket_client")
set(COMPONENT_PRIV_REQUIRES )

set(COMPONENT_SRCS "iso14443.c" "mifare_classic.c" "clrc663.c" "network.c" "tag.c" "access.c"
    EMBED_TXTFILES heimdall_makesaltlake_org_root_cert.pem heimdall_dev_root_cert.pem)
set(COMPONENT_ADD_INCLUDEDIRS "")

register_component()

target_compile_options(${COMPONENT_TARGET} PRIVATE -Wall -Wstrict-prototypes -DLOG_LOCAL_LEVEL=ESP_LOG_DEBUG)
