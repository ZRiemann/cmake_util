cmake_minimum_required(VERSION 3.15)
# use ALL_PROXY=socks5://xxxxx:9090
# config c++ flags
add_library(cxx_flags INTERFACE)
target_compile_features(cxx_flags INTERFACE cxx_std_20)

set(gcc_like_cxx "$<COMPILE_LANG_AND_ID:CXX,ARMClang,AppleClang,Clang,GNU,LCC>")
set(msvc_cxx "$<COMPILE_LANG_AND_ID:CXX,MSVC>")
target_compile_options(cxx_flags INTERFACE
                       "$<${gcc_like_cxx}:$<BUILD_INTERFACE:-Wall;-Wextra;-Wshadow;-Wformat=2;-Wunused;-Wno-class-memaccess;-Wno-deprecated-declarations>>"
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

# 改进的 CPM.cmake 下载逻辑
set(CPM_DIR "${CMAKE_BINARY_DIR}/cmake/CPM.cmake" CACHE PATH "CPM Path")

# 检查文件是否存在且非空
if(NOT EXISTS ${CPM_DIR} OR NOT CPM_DIR)
    message(STATUS "Downloading CPM.cmake...")
    
    # 确保目录存在
    get_filename_component(CPM_PARENT_DIR ${CPM_DIR} DIRECTORY)
    file(MAKE_DIRECTORY ${CPM_PARENT_DIR})
    
    # 下载文件
    file(DOWNLOAD
        "https://github.com/cpm-cmake/CPM.cmake/releases/download/v0.40.8/CPM.cmake"
        ${CPM_DIR}
        STATUS download_status
        LOG download_log
        SHOW_PROGRESS
        TIMEOUT 30
    )
    
    # 检查下载状态
    list(GET download_status 0 status_code)
    list(GET download_status 1 status_string)
    
    if(NOT status_code EQUAL 0)
        message(FATAL_ERROR "Failed to download CPM.cmake: ${status_string}\nLog: ${download_log}")
    endif()
    
    # 验证文件大小
    file(SIZE ${CPM_DIR} file_size)
    if(file_size LESS 1000)
        message(FATAL_ERROR "Downloaded CPM.cmake appears to be empty or corrupted (size: ${file_size} bytes)")
    endif()
    
    message(STATUS "CPM.cmake downloaded successfully (${file_size} bytes)")
else()
    message(STATUS "CPM.cmake already exists")
endif()

# 验证文件内容
file(READ ${CPM_DIR} CPM_CONTENT LIMIT 100)
if(NOT CPM_CONTENT MATCHES "CPM")
    message(FATAL_ERROR "CPM.cmake file appears to be corrupted")
endif()

include(${CPM_DIR})

