cmake_minimum_required(VERSION 3.15)
# use ALL_PROXY=socks5://xxxxx:9090

option(ENABLE_LTO "Enable Link Time Optimization (IPO)" ON)
option(ENABLE_THIN_LTO "Prefer ThinLTO when supported (Clang/LLVM)" OFF)
option(ENABLE_FAT_LTO_OBJECTS "Build fat LTO objects (for library distribution)" OFF)

include(CheckIPOSupported)

if(ENABLE_LTO)
  check_ipo_supported(RESULT have_ipo OUTPUT ipo_err)
  if(have_ipo)
    set(CMAKE_INTERPROCEDURAL_OPTIMIZATION_RELEASE ON)
    set(CMAKE_INTERPROCEDURAL_OPTIMIZATION_RELWITHDEBINFO ON)
    message(STATUS "LTO/IPO enabled via CMake property")
  else()
    message(WARNING "IPO not supported: ${ipo_err}")
    set(ENABLE_LTO_FALLBACK_FLAGS ON)
  endif()
else()
    message(WARNING "LTO NOT ENABLED")
endif()

# config c++ flags
add_library(cxx_options INTERFACE)
target_compile_features(cxx_options INTERFACE cxx_std_20)

set(gcc_like_cxx $<COMPILE_LANG_AND_ID:CXX,ARMClang,AppleClang,Clang,GNU,LCC>)
set(msvc_cxx $<COMPILE_LANG_AND_ID:CXX,MSVC>)
target_compile_options(cxx_options INTERFACE
                       $<${gcc_like_cxx}:$<BUILD_INTERFACE:-Wall>> #;-Wextra;-Wshadow;-Wformat=2;-Wunused;-Wno-class-memaccess;-Wno-deprecated-declarations>>
                       $<${msvc_cxx}:$<BUILD_INTERFACE:/W3>>
                       $<$<AND:${gcc_like_cxx},$<CONFIG:Debug>>:$<BUILD_INTERFACE:-O0;-g3;-fno-omit-frame-pointer>>
                      )

# config c++ definitions
string(TIMESTAMP COMPILE_TIME %Y-%m-%d_%H:%M:%S)
set(build_time ${COMPILE_TIME})
message(STATUS "COMPILE_TIME: ${COMPILE_TIME}")

find_package(Git QUIET)
set(GIT_VERSION_STRING "unknown")
set(GIT_COMMIT_HASH "unknown")
set(GIT_BRANCH "unknown")
set(GIT_DIRTY "")

if(GIT_FOUND)
    execute_process(
    COMMAND "${GIT_EXECUTABLE}" rev-parse --is-inside-work-tree
    WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
    RESULT_VARIABLE _inside_repo_res
    OUTPUT_VARIABLE _inside_repo_out
    ERROR_QUIET
    OUTPUT_STRIP_TRAILING_WHITESPACE
  )
  if(_inside_repo_res EQUAL 0 AND _inside_repo_out STREQUAL "true")
    # 1) 优先用 git describe（需要 tag 存在），--always 确保无 tag 时也有输出
    execute_process(
      COMMAND "${GIT_EXECUTABLE}" describe --tags --dirty --always --abbrev=7
      WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
      RESULT_VARIABLE _desc_res
      OUTPUT_VARIABLE _desc_out
      ERROR_QUIET
      OUTPUT_STRIP_TRAILING_WHITESPACE
    )
    if(_desc_res EQUAL 0 AND NOT _desc_out STREQUAL "")
      set(GIT_VERSION_STRING "${_desc_out}")
    endif()

    # 2) 获取短哈希
    execute_process(
      COMMAND "${GIT_EXECUTABLE}" rev-parse --short=7 HEAD
      WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
      RESULT_VARIABLE _hash_res
      OUTPUT_VARIABLE _hash_out
      ERROR_QUIET
      OUTPUT_STRIP_TRAILING_WHITESPACE
    )
    if(_hash_res EQUAL 0 AND NOT _hash_out STREQUAL "")
      set(GIT_COMMIT_HASH "${_hash_out}")
    endif()

    # 3) 当前分支名（在某些 CI 上可能是 HEAD 或 detached）
    execute_process(
      COMMAND "${GIT_EXECUTABLE}" rev-parse --abbrev-ref HEAD
      WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
      RESULT_VARIABLE _branch_res
      OUTPUT_VARIABLE _branch_out
      ERROR_QUIET
      OUTPUT_STRIP_TRAILING_WHITESPACE
    )
    if(_branch_res EQUAL 0 AND NOT _branch_out STREQUAL "")
      set(GIT_BRANCH "${_branch_out}")
    endif()

    # 4) 是否有未提交修改（dirty 标记）
    execute_process(
      COMMAND "${GIT_EXECUTABLE}" diff --quiet
      WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
      RESULT_VARIABLE _diff_res
      ERROR_QUIET
    )
    if(NOT _diff_res EQUAL 0)
      set(GIT_DIRTY "-dirty")
    endif()
  endif()
else()
    message(WARNING "Git not found!")
endif()
# 最终的版本字符串，示例：v1.2.3-4-gabc1234-dirty 或 abc1234-dirty
if(GIT_VERSION_STRING STREQUAL "unknown" AND NOT GIT_COMMIT_HASH STREQUAL "unknown")
  set(GIT_VERSION_STRING "${GIT_COMMIT_HASH}")
endif()
if(NOT GIT_DIRTY STREQUAL "")
  set(GIT_VERSION_STRING "${GIT_VERSION_STRING}${GIT_DIRTY}")
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
if(NOT DEFINED ENV{CPM_SOURCE_CACHE})
    set(ENV{CPM_SOURCE_CACHE} "${CMAKE_SOURCE_DIR}/cpm_cache")
endif()
set(CPM_DIR "$ENV{CPM_SOURCE_CACHE}/CPM.cmake" CACHE PATH "CPM Path")

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

