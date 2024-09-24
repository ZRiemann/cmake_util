cmake_minimum_required(VERSION 3.15)

find_package(OpenCV REQUIRED)
message(STATUS "OpenCV ${OpenCV_VERSION}")
message(STATUS "OpenCV ${OpenCV_INCLUDE_DIRS}")
message(STATUS "OpenCV ${OpenCV_LIBS}")

# demo
# include_directories(${OpenCV_INCLUDE_DIRS})
# add_executable(DisplayImage DisplayImage.cpp)
# target_link_libraries(DisplayImage ${OpenCV_LIBS})