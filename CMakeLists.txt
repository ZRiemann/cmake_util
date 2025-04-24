cmake_minimum_required(VERSION 3.15)

project(Zpp VERSION 1.0.0)

set(CMAKE_C_COMPILER "/usr/bin/gcc")
set(CMAKE_CXX_COMPILER "/usr/bin/g++")

include(./cmake_util/common.cmake)
# fand packages
find_package(Threads REQUIRED)
#include(./cmake_util/find_package/nng.cmake)
#include(./cmake_util/find_package/jmalloc.cmake)
#include(./cmake_util/find_package/OpenCV.cmake)
#include(./cmake_util/find_package/rapidjson.cmake)
#include(./cmake_util/find_package/grpc.cmake)

message(STATUS "Begin building...")

#[[
if(WIN32)
    message(STATUS "Windows")
elseif(APPLE)
    #set(CMAKE_INSTALL_RPATH "@executable_path")
    #set(CMAKE_BUILD_WITH_INSTALL_RPATH TRUE)
    message(STATUS "macOS")
elseif(UNIX)
    #set(CMAKE_INSTALL_RPATH "$ORIGIN")
    #set(CMAKE_BUILD_WITH_INSTALL_RPATH TRUE)
    message(STATUS "Unix")
endif()

#add_subdirectory(test_3rd)

# libs

# executables
# add_executable(hello_world main.cpp
# add_executable(cur_test test_3rd/eigen/eigen_basic.cpp)
# add_executable(cur_test test_zpp/test_AI.cpp)

# add_executable(cur_test AI/OpenCV/Tutorials/display_image.cpp)
# add_executable(cur_test AI/OpenCV/Tutorials/Mat_practice.cpp)
# add_executable(cur_test AI/OpenCV/Tutorials/scan_images.cpp)
# add_executable(cur_test AI/OpenCV/Tutorials/mat_mask_operations.cpp)
# add_executable(cur_test AI/OpenCV/Tutorials/adding_images.cpp)
# add_executable(cur_test AI/OpenCV/Tutorials/basic_linear_transforms.cpp)
# add_executable(cur_test AI/OpenCV/Tutorials/discrete_fourier_transform.cpp)
# add_executable(cur_test AI/OpenCV/Tutorials/file_input_output.cpp)
# add_executable(cur_test AI/OpenCV/Tutorials/parallel_for_new.cpp)
# add_executable(cur_test AI/OpenCV/Tutorials/univ_intrin.cpp)
# add_executable(cur_test AI/OpenCV/Tutorials/Drawing_1.cpp)
# add_executable(cur_test AI/OpenCV/Tutorials/Drawing_2.cpp)
# add_executable(cur_test AI/OpenCV/Tutorials/Smoothing.cpp)
# add_executable(cur_test AI/OpenCV/Tutorials/Morphology_1.cpp)
# add_executable(cur_test AI/OpenCV/Tutorials/Morphology_2.cpp)
add_executable(cur_test AI/OpenCV/Tutorials/HitMiss.cpp)

target_link_libraries(cur_test PUBLIC cxx_flags
    ${OpenCV_LIBS}
    Threads::Threads
)

target_include_directories(cur_test PUBLIC
                            "${OpenCV_INCLUDE_DIRS}"
                            "${PROJECT_BINARY_DIR}"
                            "${PROJECT_SOURCE_DIR}/include"
                            "${PROJECT_SOURCE_DIR}/spdlog/include")
# test moddy camels
add_executable(test_moodycamel_siso test_3rd/moodycamel/siso.cpp)

target_link_libraries(test_moodycamel_siso PUBLIC cxx_flags
    Threads::Threads
)
                             
target_include_directories(test_moodycamel_siso PUBLIC
                           "${PROJECT_BINARY_DIR}"
                           "${PROJECT_SOURCE_DIR}/include"
                           "${PROJECT_SOURCE_DIR}/spdlog/include")

# test moddy camels
add_executable(test_jun test_zpp/test_jun.cpp)

target_link_libraries(test_jun PUBLIC cxx_flags
    Threads::Threads
)
                             
target_include_directories(test_jun PUBLIC
                           "${PROJECT_BINARY_DIR}"
                           "${PROJECT_SOURCE_DIR}/include"
                           "${PROJECT_SOURCE_DIR}/spdlog/include")
]]
