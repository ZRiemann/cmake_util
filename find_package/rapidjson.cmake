
# 尝试查找 RapidJSON
find_package(RapidJSON QUIET)

# 检查是否找到
if(RapidJSON_FOUND)
    message(STATUS "RapidJSON found: ${RapidJSON_INCLUDE_DIRS}")
else()
    message(STATUS "RapidJSON not found, will download it")
    # 添加 RapidJSON
    CPMAddPackage(
        NAME rapidjson
        GITHUB_REPOSITORY Tencent/rapidjson
        GIT_TAG v1.1.0
        DOWNLOAD_ONLY YES  # 仅下载，不构建（因为它是仅头文件库）
    )
    find_package(RapidJSON QUIET)
    set(RapidJSON_INCLUDE_DIRS "${rapidjson_SOURCE_DIR}/include")
    message(STATUS "RapidJSON found: ${RapidJSON_INCLUDE_DIRS}")    
endif()

# 创建可执行文件
#add_executable(myapp main.cpp)

# 包含 RapidJSON 头文件
#if(rapidjson_ADDED)
#  target_include_directories(myapp PRIVATE ${rapidjson_SOURCE_DIR}/include)
#endif()

#############################################################
# 查找 RapidJSON
#find_package(RapidJSON REQUIRED)

# 创建可执行文件
#add_executable(myapp main.cpp)

# 链接 RapidJSON (只需包含头文件)
#target_include_directories(myapp PRIVATE ${RAPIDJSON_INCLUDE_DIRS})

# 如果需要，可以添加 RapidJSON 的编译定义
#target_compile_definitions(myapp PRIVATE ${RAPIDJSON_DEFINITIONS})