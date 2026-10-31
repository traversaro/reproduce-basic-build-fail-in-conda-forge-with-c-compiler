cmake_minimum_required(VERSION 3.16)
project(c_compiler_reproducer LANGUAGES C)

add_library(example_shared SHARED src/example.c)
add_library(example_static STATIC src/example.c)
add_executable(example_executable src/main.c src/example.c)

foreach(tool CMAKE_C_COMPILER CMAKE_AR CMAKE_RANLIB CMAKE_LINKER)
    message(STATUS "${tool}=${${tool}}")
endforeach()
