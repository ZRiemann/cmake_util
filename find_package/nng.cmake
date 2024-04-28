cmake_minimum_required(VERSION 3.15)

find_package(Threads REQUIRED)

find_package(nng CONFIG REQUIRED)
message(STATUS "Using nng ${nng_VERSION}")

# demo
# add_executable(server server.c)
# target_link_libraries(server nng::nng)
# target_compile_definitions(server PRIVATE NNG_ELIDE_DEPRECATED)