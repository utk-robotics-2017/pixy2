cmake_minimum_required(VERSION 3.1)
project(libpixyusb2)
message("Building ${PROJECT_NAME}")

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_SOURCE_DIR}/cmake_modules/")
find_package(LibUSB REQUIRED)
include_directories(${LIBUSB_1_INCLUDE_DIRS})

file(GLOB_RECURSE ${PROJECT_NAME}_SRCS
  "src/host/libpixyusb2/*.cpp"
)
file(GLOB_RECURSE ${PROJECT_NAME}_HEADERS
  "src/common/inc/*.h"
  "src/host/libpixyusb2/include/*.h"
  "src/device/*/inc/*.h"
  "src/host/arduino/libraries/Pixy2/*.h"
)
file(GLOB_RECURSE ${PROJECT_NAME}_INCLUDE_DIRS
  LIST_DIRECTORIES true
  "src/common/inc"
  "src/host/libpixyusb2/include"
  "src/device/*/inc"
  "src/host/arduino/libraries/Pixy2"
)

# message("${${PROJECT_NAME}_HEADERS}")
message("${${PROJECT_NAME}_INCLUDE_DIRS}")

add_library(${PROJECT_NAME}
  ${${PROJECT_NAME}_SRCS}
  ${${PROJECT_NAME}_HEADERS}
)
target_include_directories(
  ${PROJECT_NAME} PUBLIC ${${PROJECT_NAME}_INCLUDE_DIRS}
)
set_property(TARGET ${PROJECT_NAME} PROPERTY CXX_STANDARD 11)
target_include_directories(
  ${PROJECT_NAME} PUBLIC src/common/inc src/host/libpixyusb2/include
)
