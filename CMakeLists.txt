cmake_minimum_required(VERSION 3.15)

project(ZetaX VERSION 1.0.0)

include(./cmake_util/common.cmake)

# Append User define options
#target_compile_options(cxx_options INTERFACE
#    $<${gcc_like_cxx}:$<BUILD_INTERFACE:-Wno-class-memaccess;-Wno-deprecated-declarations>>
#)

# find packages
find_package(Threads REQUIRED)

#set(RAPIDJSON_ROOT "/home/booster/tmp" CACHE PATH "RapidJSON include root") # 指定用户目录，不使用CPM下载
include(./cmake_util/find_package/rapidjson.cmake)

#set(SPDLOG_ROOT "/home/booster/tmp" CACHE PATH "SPDLOG include root")
include(./cmake_util/find_package/spdlog.cmake)

#include(./cmake_util/find_package/CUDA.cmake)
#include(./cmake_util/find_package/grpc.cmake)
#include(./cmake_util/find_package/jmalloc.cmake)
#include(./cmake_util/find_package/modbus.cmake)
#include(./cmake_util/find_package/nng.cmake)
#include(./cmake_util/find_package/OpenCV.cmake)
#include(./cmake_util/find_package/protobuf.cmake)


message(STATUS "Begin building...")


if(WIN32)
    message(STATUS "System: Windows")
elseif(APPLE)
    message(STATUS "System: macOS")
elseif(UNIX)
    #set(CMAKE_BUILD_WITH_INSTALL_RPATH TRUE)
    message(STATUS "System: Unix")
endif()

add_subdirectory(tests)
add_subdirectory(src)

