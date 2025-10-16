find_package(NNG QUIET)

#sudo apt update
#sudo apt install libmbedtls-dev
#sudo apt install libnng-dev
#dpkg -l | grep mbedtls
#[[
# 尝试查找 MbedTLS
find_package(MbedTLS QUIET)

# 如果没有找到，尝试安装
if(NOT MbedTLS_FOUND)
    message(STATUS "MbedTLS not found. Attempting to install...")
    
    # 执行安装命令
    execute_process(
        COMMAND sudo apt install -y libmbedtls-dev
        RESULT_VARIABLE INSTALL_RESULT
        OUTPUT_VARIABLE INSTALL_OUTPUT
        ERROR_VARIABLE INSTALL_ERROR
    )
    
    # 检查安装结果
    if(NOT INSTALL_RESULT EQUAL 0)
        message(WARNING "Failed to install libmbedtls-dev: ${INSTALL_ERROR}")
    else()
        message(STATUS "Successfully installed libmbedtls-dev")
        # 重新尝试查找包
        find_package(MbedTLS REQUIRED)
    endif()
else()
    message(STATUS "Found MbedTLS: ${MbedTLS_VERSION}")
endif()
]]
if(NOT NNG_FOUND)
    message(STATUS "NNG not found, will download and build it")
    CPMAddPackage(
        NAME nng
        GITHUB_REPOSITORY nanomsg/nng
        VERSION 1.10.1
        OPTIONS
            "NNG_TESTS OFF"
            "NNG_TOOLS OFF"
            "NNG_ENABLE_NNGCAT OFF"
            "BUILD_SHARED_LIBS OFF"
            "NNG_ENABLE_TLS OFF"
            "NNG_ENABLE_HTTP ON"
    )
    
    message(STATUS "NNG found: ${nng_SOURCE_DIR}")        
    # Create an alias target that matches the expected name
    if(NOT TARGET nng::nng)
        add_library(nng::nng ALIAS nng)
    endif()
else()
    message(STATUS "Found NNG: ${NNG_LIBRARIES}")
endif()

message(STATUS "Using nng ${nng_VERSION}")
#[[
# demo
add_executable(nng_example src/main.c)
target_link_libraries(nng_example PRIVATE nng::nng)

# 如果需要，设置包含目录
target_include_directories(nng_example PRIVATE ${nng_SOURCE_DIR}/include)

# 设置 C 标准
set_target_properties(nng_example PROPERTIES
    C_STANDARD 99
    C_STANDARD_REQUIRED ON
)
]]