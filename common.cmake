cmake_minimum_required(VERSION 3.15)
set(ENV{http_proxy} "socks5://192.168.123.45:9090")
set(ENV{https_proxy} "socks5://192.168.123.45:9090")

# config c++ flags
add_library(cxx_flags INTERFACE)
target_compile_features(cxx_flags INTERFACE cxx_std_20)

set(gcc_like_cxx "$<COMPILE_LANG_AND_ID:CXX,ARMClang,AppleClang,Clang,GNU,LCC>")
set(msvc_cxx "$<COMPILE_LANG_AND_ID:CXX,MSVC>")
target_compile_options(cxx_flags INTERFACE
                       "$<${gcc_like_cxx}:$<BUILD_INTERFACE:-Wall;-Wextra;-Wshadow;-Wformat=2;-Wunused;-Wno-class-memaccess>>"
                       "$<${msvc_cxx}:$<BUILD_INTERFACE:-W3>>"
                      )

# config c++ definitions
string(TIMESTAMP COMPILE_TIME %Y-%m-%d_%H:%M:%S)
set(build_time ${COMPILE_TIME})
message(STATUS "COMPILE_TIME: ${COMPILE_TIME}")
find_package(Git)
if(GIT_FOUND)
    message(STATUS "Git found: ${GIT_EXECUTABLE} version:${GIT_VERSION_STRING}")
#[[
    set(GIT_HASH "")
    get_git_hash(GIT_HASH)
    set(GIT_BRANCH "")
    get_git_branch(GIT_BRANCH)
]]
else()
    message(WARNING "Git not found!")
endif()


# 检查文件是否存在
set(CONFIG_TEMPLATE "${CMAKE_CURRENT_SOURCE_DIR}/CMakeConfig.h.in")
if(EXISTS "${CONFIG_TEMPLATE}")
    message(STATUS "Found configuration template: ${CONFIG_TEMPLATE}")
    # 文件存在，使用 configure_file 命令
    configure_file(
        "${CONFIG_TEMPLATE}"
        "${CMAKE_CURRENT_BINARY_DIR}/CMakeConfig.h"
        @ONLY  # 只替换 @VAR@ 格式的变量
    )
    # 可选：将生成的头文件目录添加到包含路径
    include_directories("${CMAKE_CURRENT_BINARY_DIR}")
else()
    message(STATUS "Configuration template not found: ${CONFIG_TEMPLATE}")
    # 可选：处理文件不存在的情况
endif()

#list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

# 首先包含 CPM.cmake
set(CPM_DIR "${CMAKE_BINARY_DIR}/cmake/CPM.cmake" CACHE PATH "CPM Path")
if(NOT EXISTS ${CPM_DIR})
  message(STATUS "Downloading CPM.cmake")
  file(DOWNLOAD
       "https://github.com/cpm-cmake/CPM.cmake/releases/download/v0.40.8/CPM.cmake"
       ${CPM_DIR}
  )
endif()
include(${CPM_DIR})
