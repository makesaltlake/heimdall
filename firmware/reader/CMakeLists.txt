# The following lines of boilerplate have to be in your project's
# CMakeLists in this exact order for cmake to work correctly
cmake_minimum_required(VERSION 3.10)

set(PROJECT_VER "0.5.0")

set(EXTRA_COMPONENT_DIRS ../common ../esp32-uuid ../ESP32-NeoPixel-WS2812-RMT)

include($ENV{IDF_PATH}/tools/cmake/project.cmake)
project(heimdall)
