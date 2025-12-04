# Edit following two lines to set component requirements (see docs)
set(COMPONENT_REQUIRES )
set(COMPONENT_PRIV_REQUIRES )

set(COMPONENT_SRCS "main.c" "../../ESP32-NeoPixel-WS2812-RMT/ws2812_control.c")
set(COMPONENT_ADD_INCLUDEDIRS "../../common/")

register_component()

target_compile_options(${COMPONENT_TARGET} PRIVATE -Wall -Wstrict-prototypes -DRFID_READER=1 -DLOG_LOCAL_LEVEL=ESP_LOG_DEBUG)
