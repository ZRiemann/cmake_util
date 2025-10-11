cmake_minimum_required(VERSION 3.15)

project(ZetaX VERSION 1.0.0)

#set(CMAKE_C_COMPILER "/usr/bin/gcc")
#set(CMAKE_CXX_COMPILER "/usr/bin/g++")

include(./cmake_util/common.cmake)

# Append User define options
#target_compile_options(cxx_options INTERFACE
#    $<${gcc_like_cxx}:$<BUILD_INTERFACE:-Wno-class-memaccess;-Wno-deprecated-declarations>>
#)

# find packages
find_package(Threads REQUIRED)
include(./cmake_util/find_package/rapidjson.cmake)
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

