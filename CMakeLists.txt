# CMakeLists files in this project can
# refer to the root source directory of the project as ${HELLO_SOURCE_DIR} and
# to the root binary directory of the project as ${HELLO_BINARY_DIR}.
cmake_minimum_required (VERSION 2.8.11)
project (HELLO_SECRET)

add_library (SecretStatic STATIC secret.c)
target_include_directories (SecretStatic PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})

add_library (SecretDynamic SHARED secret.c)
target_include_directories (SecretDynamic PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})

add_executable (HelloSecretStatic hello_secret.c)
target_link_libraries (HelloSecretStatic LINK_PUBLIC SecretStatic)

add_executable (HelloSecretDynamic hello_secret.c)
target_link_libraries (HelloSecretDynamic LINK_PUBLIC SecretDynamic)
